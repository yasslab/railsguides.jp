Active Record の複数データベース対応
=====================================

このガイドでは、Active Recordで複数のデータベースを利用する方法について説明します。

このガイドの内容:

* アプリケーションで複数のデータベースをセットアップする方法
* コネクションの自動切り替えの仕組み
* 複数のデータベースにおける水平シャーディングの利用方法
* サポートされている機能と現在進行中の機能

--------------------------------------------------------------------------------


アプリケーションが人気を得て利用されるようになってくると、新しいユーザーやユーザーのデータをサポートするためにアプリケーションをスケールする必要が生じてきます。アプリケーションをスケールする方法の1つが、データベースレベルでのスケールでしょう。Railsが複数のデータベース（Multiple Databases）をサポートするようになったので、すべてのデータを1箇所に保存する必要はありません。

現時点でサポートされている機能は以下のとおりです。

* 複数の「writer」データベースと、それぞれに対応する「replica」データベース
* 作業中のモデルでのコネクション自動切り替え
* HTTP verbや直近の書き込みに応じたwriterとreplicaの自動スワップ
* 複数のデータベースの作成、削除、マイグレーション、各種操作を行うRailsタスク

以下の機能は現時点では（まだ）サポートされていません。

* replicaのロードバランシング

## アプリケーションのセットアップ

アプリケーションで複数のデータベースを利用する場合、大半の機能についてはRailsが代わりに行いますが、一部の手順は手動で行う必要があります。

たとえばwriterデータベースが1つあるアプリケーションに、新しいテーブルがいくつかあるデータベースを1つ追加するとします。新しいデータベースの名前は「animal」とします。

この場合の`config/database.yml`は以下のような感じになります。

```yaml
production:
  database: my_primary_database
  adapter: mysql2
  username: root
  password: <%= ENV['ROOT_PASSWORD'] %>
```

animalという名前の第2のデータベースを追加して、両方のデータベースにそれぞれreplicaを追加してみましょう。これを行うには、`config/database.yml`を以下のように2層（2-tier）設定から3層（3-tier）設定に変更する必要があります。

`primary`設定キーが指定されている場合、これが「デフォルト」の設定として使われます。`primary`という名前の設定キーがない場合、Railsは最初の設定を各環境で使います。
デフォルトの設定では、デフォルトのRailsのファイル名が使われます。たとえば、`primary`設定のスキーマファイル名には`db/schema.rb`が使われ、その他のエントリではファイル名に`db/設定の名前空間_schema.rb`が使われます。

```yaml
production:
  primary:
    database: my_primary_database
    username: root
    password: <%= ENV['ROOT_PASSWORD'] %>
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    username: root_readonly
    password: <%= ENV['ROOT_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
  animals:
    database: my_animals_database
    username: animals_root
    password: <%= ENV['ANIMALS_ROOT_PASSWORD'] %>
    adapter: mysql2
    migrations_paths: db/animals_migrate
  animals_replica:
    database: my_animals_database
    username: animals_readonly
    password: <%= ENV['ANIMALS_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
```

複数のデータベースを用いる場合に重要な設定がいくつかあります。

第1に、`primary`と`primary_replica`のデータベース名は同じにすべきです。理由は、primaryとreplicaが同じデータを持つからです。`animals`と`animals_replica`についても同様です。

第2に、writerとreplicaでは異なるデータベースユーザー名を使い、かつreplicaのパーミッションは（writeではなく）readのみにすべきです。

replicaデータベースを使う場合、`config/database.yml`のreplicaには`replica: true`というエントリを1つ追加する必要があります。このエントリがないと、どちらがreplicaでどちらがwriterかをRailsが区別できなくなるためです。Railsは、マイグレーションなどの特定のタスクについてはreplicaに対して実行しません。

最後に、新しいwriterデータベースで利用するために、そのデータベースのマイグレーションを置くディレクトリを`migrations_paths`キーに設定する必要があります。`migrations_paths`については本ガイドで後述します。

また、`schema_dump`をカスタムスキーマファイル名に設定する形でスキーマダンプファイルを構成することも、`schema_dump: false`オプションを設定してスキーマのダンプを完全にスキップすることも可能です。

新しいデータベースができたら、コネクションモデルをセットアップしましょう。
primaryデータベースのreplicaは、以下のように`ApplicationRecord`で構成できます。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

`ApplicationRecord`を別のクラス名に変えている場合は、`primary_abstract_class`を設定する必要があります。これにより、Railsはコネクションをどのクラスの`ActiveRecord::Base`と共有すべきかを認識できるようになります。

```ruby
class PrimaryApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

この場合、`primary`や`primary_replica`に接続するクラスは、標準のRailsアプリケーションが`ApplicationRecord`で行っているのと同じように、プライマリの抽象クラスから継承できます。

```ruby
class Person < PrimaryApplicationRecord
end
```

一方、`animals`データベースには永続化されたモデルを設定する必要があります。

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

これらのモデルは、共通の抽象クラスから継承する必要があります。

```ruby
class Car < AnimalsRecord
  # animalsデータベースに自動的に話しかける
end
```

Railsはデフォルトで、primaryのデータベースロールは`writing`、replicaのデータベースロールは`reading`であることを期待します。レガシーなシステムでは、既に設定されているロールを変更したくないこともあるでしょう。その場合はアプリケーションで以下のように新しいロール名を設定できます。

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

ここで重要なのは、データベースへの接続を「単一のモデル内」で行うことと、そのモデルを継承してテーブルを利用することです（複数のモデルから同じデータベースに接続するのではなく）。データベースクライアントがオープンできるコネクション数には上限があります。Railsはコネクションを指定する名前にモデル名を用いるので、同じデータベースに複数のモデルから接続するとコネクション数が増加します。

`config/database.yml`と新しいモデルをセットアップできたので、いよいよデータベースを作成しましょう。Railsには複数のデータベースを使うのに必要なrailsタスクがすべて揃っています。

`bin/rails --help`を実行すると、利用可能なコマンド一覧がすべて表示されます。出力は以下のようになります。

```bash
$ bin/rails --help
...
db:create                          # Create the database from DATABASE_URL or config/database.yml for the ...
db:create:animals                  # Create animals database for current environment
db:create:primary                  # Create primary database for current environment
db:drop                            # Drop the database from DATABASE_URL or config/database.yml for the cu...
db:drop:animals                    # Drop animals database for current environment
db:drop:primary                    # Drop primary database for current environment
db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
db:migrate:animals                 # Migrate animals database for current environment
db:migrate:primary                 # Migrate primary database for current environment
db:migrate:status                  # Display status of migrations
db:migrate:status:animals          # Display status of migrations for animals database
db:migrate:status:primary          # Display status of migrations for primary database
db:reset                           # Drop and recreates all databases from their schema for the current environment and loads the seeds
db:reset:animals                   # Drop and recreates the animals database from its schema for the current environment and loads the seeds
db:reset:primary                   # Drop and recreates the primary database from its schema for the current environment and loads the seeds
db:rollback                        # Roll the schema back to the previous version (specify steps w/ STEP=n)
db:rollback:animals                # Rollback animals database for current environment (specify steps w/ STEP=n)
db:rollback:primary                # Rollback primary database for current environment (specify steps w/ STEP=n)
db:schema:dump                     # Create a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:dump:animals             # Create a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:dump:primary             # Create a db/schema.rb file that is portable against any DB supported  ...
db:schema:load                     # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:load:animals             # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:schema:load:primary             # Load a database schema file (either db/schema.rb or db/structure.sql  ...
db:setup                           # Create all databases, loads all schemas, and initializes with the seed data (use db:reset to also drop all databases first)
db:setup:animals                   # Create the animals database, loads the schema, and initializes with the seed data (use db:reset:animals to also drop the database first)
db:setup:primary                   # Create the primary database, loads the schema, and initializes with the seed data (use db:reset:primary to also drop the database first)
...
```

`bin/rails db:create`などのコマンドを実行すると、primaryとanimalsデータベースの両方が作成されます。ただしデータベースユーザーを作成するコマンドはないので、replicaでreadonlyをサポートするには手動でユーザーを作成する必要があります。animalデータベースだけを作成するには、`bin/rails db:create:animals`を実行します。

## スキーマ・マイグレーション管理を外してデータベースに接続する

スキーマ管理、マイグレーション、シードなどのデータベース管理作業を一切行わずに外部のデータベースに接続したい場合は、データベースごとに設定オプション`database_tasks: false`を設定できます。これはデフォルトでは`true`に設定されます。

```yaml
production:
  primary:
    database: my_database
    adapter: mysql2
  animals:
    database: my_animals_database
    adapter: mysql2
    database_tasks: false
```

## ジェネレータとマイグレーション

複数のデータベースのマイグレーションファイルは、設定ファイルにあるデータベースキー名を冒頭に付けた個別のフォルダに配置してください。

また、データベース設定の`migrations_paths`を設定し、マイグレーションファイルを探索する場所をRailsに認識させる必要もあります。

たとえば、`animals`データベースのマイグレーションファイルは`db/animals_migrate`ディレクトリに配置し、`primary`のマイグレーションファイルは`db/migrate`ディレクトリに配置する、という具合になります。Railsのジェネレータには、ファイルを正しいディレクトリで生成するための`--database`オプションを渡せます。このコマンドは以下のように実行します。

```bash
$ bin/rails generate migration CreateDogs name:string --database animals
```

ジェネレータを使う場合は、scaffoldとモデルジェネレータが抽象クラスを自動的に作成します。これは、以下のようにコマンドラインにデータベースのキーを渡すだけでできます。

```bash
$ bin/rails generate scaffold Dog name:string --database animals
```

データベース名の末尾に`Record`を加えた抽象クラスが作成されます。この例ではデータベースが"animals"なので、`AnimalsRecord`が作成されます。

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals }
end
```

生成されたモデルは自動的に`AnimalsRecord`クラスを継承します。

```ruby
class Dog < AnimalsRecord
end
```

NOTE: Railsはどのデータベースがreplicaなのかを認識しないので、完了したら抽象クラスにreplicaを追加する必要があります。

Railsは`AnimalsRecord`クラスを一度だけ生成します。新しいscaffoldによって上書きされることはなく、scaffoldが削除されると削除されます。

`AnimalsRecord`と異なる既存の抽象クラスがある場合、`--parent`オプションで別の抽象クラスを指定できます。

```bash
$ bin/rails generate scaffold Dog name:string --database animals --parent Animals::Record
```

上では別の親クラスの利用を指定しているため、`AnimalsRecord`の生成をスキップします。

## ロールの自動切り替えを有効にする

最後に、アプリケーションでread-onlyのreplicaを利用するために、自動切り替え用のミドルウェアを有効にする必要があります。

自動切り替え機能によって、アプリケーションはHTTP verbや、リクエストしたユーザーによる直近の書き込みの有無に応じてwriterからreplica、またはreplicaからwriterへと切り替えます。

アプリケーションがPOST、PUT、DELETE、PATCHのいずれかのリクエストを受け取ると、自動的にwriterデータベースに書き込みます。リクエストがそれ以外のメソッドであっても、直近の書き込みがあった場合にはやはりwriterデータベースが利用されます。それ以外のリクエストではreplicaデータベースを使います。

コネクション自動切り替えのミドルウェアを有効にするには、以下のように自動スワップジェネレータを実行します。

```bash
$ bin/rails g active_record:multi_db
```

続いて設定ファイルの以下の行のコメントを解除して有効にします。

```ruby
Rails.application.configure do
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
```

Railsは「自分が書き込んだものを読み取る」ことを保証するので、`delay`ウィンドウの期間内であればGETリクエストやHEADリクエストをwriterに送信します。この`delay`は、デフォルトで2秒に設定されます。
この値を変更する場合は、利用するデータベースインフラストラクチャに基づいて行うべきです。Railsは、`delay`ウィンドウの期間内で「他のユーザーが最近書き込んだものを読み取る」ことについては保証しないので、最近書き込まれたものでなければGETリクエストやHEADリクエストをreplicaに送信します。

Railsのコネクション自動切り替えは、どちらかというとプリミティブであり、多機能とは言えません。この機能は、アプリケーションの開発者でも十分カスタマイズ可能な柔軟性を備えたコネクション自動切り替えシステムをデモンストレーションするためのものです。

Railsでのコネクション自動切り替え方法や、切り替えに使うパラメータは、セットアップで簡単に変更できます。たとえば、コネクションをスワップするかどうかを、セッションではなくcookieで行いたいのであれば、以下のように独自のクラスを作成できます。

```ruby
class MyCookieResolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
  def self.call(request)
    new(request.cookies)
  end

  def initialize(cookies)
    @cookies = cookies
  end

  attr_reader :cookies

  def last_write_timestamp
    self.class.convert_timestamp_to_time(cookies[:last_write])
  end

  def update_last_write_timestamp
    cookies[:last_write] = self.class.convert_time_to_timestamp(Time.now)
  end

  def save(response)
  end
end
```

続いて、これをミドルウェアに渡します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = MyCookieResolver
```

## コネクションを手動で切り替える

アプリケーションでwriterやreplicaに接続するときに、コネクションの自動切り替えを使うのは適切ではないことがあります。たとえば、特定のリクエストについては、たとえPOSTリクエストパスにいる場合であっても常にreplicaに送信したいとします。

Railsはこのような場合のために、必要なコネクションに切り替える`connected_to`メソッドを提供しています。

```ruby
ActiveRecord::Base.connected_to(role: :reading) do
  # このブロック内のコードはすべてreadingロールで接続される
end
```

`connected_to`呼び出しで「ロール（role）」を指定すると、そのコネクションハンドラ（またはロール）で接続されたコネクションを探索します。`reading`コネクションハンドラは、`reading`というロール名を持つ`connects_to`を介して接続されたすべてのコネクションを維持します。

ここで注意したいのは、ロールを設定した`connected_to`では、既存のコネクションの探索や切り替えにそのコネクションのspecification名が用いられることです。つまり、`connected_to(role: :nonexistent)`のように不明なロールを渡すと、`ActiveRecord::ConnectionNotEstablished (No connection pool with 'ActiveRecord::Base' found for the 'nonexistent' role.)`エラーが発生します。

Railsが実行するクエリを確実に読み取り専用にするには、`prevent_writes: true`を渡します。
これは単に、書き込みと思われるクエリがデータベースに送信されるのを防ぐだけです。
また、replicaデータベースも読み取り専用モードで実行されるよう設定する必要があります。

```ruby
ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
  # Railsは読み取りクエリであることをクエリごとに確認する
end
```

## 水平シャーディング

水平シャーディングとは、データベースを分割して各データベースサーバーの行数を減らしながら「シャード（shard）」全体で同じスキーマを維持することです。これは一般に「マルチテナント」シャーディングと呼ばれます。

Railsで水平シャーディングをサポートするAPIは、Rails6.0以降の複数のデータベースや垂直シャーディングAPIに似ています。

シャードは次のように3層（3-tier）構成で宣言されます。


```yaml
production:
  primary:
    database: my_primary_database
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    adapter: mysql2
    replica: true
  primary_shard_one:
    database: my_primary_shard_one
    adapter: mysql2
    migrations_paths: db/migrate_shards
  primary_shard_one_replica:
    database: my_primary_shard_one
    adapter: mysql2
    replica: true
  primary_shard_two:
    database: my_primary_shard_two
    adapter: mysql2
    migrations_paths: db/migrate_shards
  primary_shard_two_replica:
    database: my_primary_shard_two
    adapter: mysql2
    replica: true
```

次に、モデルは`shards`キーを介して`connects_to`APIに接続されます。

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: { writing: :primary, reading: :primary_replica }
end

class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    shard_one: { writing: :primary_shard_one, reading: :primary_shard_one_replica },
    shard_two: { writing: :primary_shard_two, reading: :primary_shard_two_replica }
  }
end
```

シャードを利用する場合は、必ずすべてのシャードで`migrations_paths`に同じパスを設定してください。マイグレーションを生成するときに`--database`オプションを渡すことで、シャード名のいずれか1つを指定できます。これらはすべて同じパスを設定するため、どのシャード名を指定しても問題ありません。

```bash
$ bin/rails g scaffold Dog name:string --database primary_shard_one
```

これで、モデルは`connected_to`APIを用いて手動でシャードを切り替えられるようになります。シャーディングを使う場合は、`role`と`shard`の両方を渡す必要があります。

```ruby
ActiveRecord::Base.connected_to(role: :writing, shard: :default) do
  @id = Person.create! # "default"という名前のシャードにレコードを作成する
end

ActiveRecord::Base.connected_to(role: :writing, shard: :shard_one) do
  Person.find(@id) # レコードは見つからない: "default"という名前のシャードに作成されたためレコードが存在しない
end
```

水平シャーディングAPIはread replicaもサポートしています。以下のように`connected_to`APIでロールとシャードを切り替えられます。

```ruby
ActiveRecord::Base.connected_to(role: :reading, shard: :shard_one) do
  Person.first # shard_oneのread replicaでレコードを探索する
end
```

## 自動シャード切り替えを有効にする

アプリケーションで提供されているミドルウェアを使うと、リクエスト単位でシャードを自動切り替えできるようになります。

`ShardSelector`ミドルウェアは、シャードを自動スワップするフレームワークを提供します。Railsは、どのシャードに切り替えるかを判断する基本的なフレームワークを提供し、必要に応じてアプリケーションでスワップのカスタム戦略を記述できます。

`ShardSelector`には、ミドルウェアの動作を変更できるオプションのセットを渡せます（現在は`lock`のみをサポート）。`lock`はデフォルトでは`true`で、ブロック内でのシャード切り替えを禁止します。`lock`が`false`の場合はシャードのスワップが許可されます。
テナントベースのシャーディングでは、アプリケーションコードが誤ってテナントを切り替えることのないよう、`lock`は常に`true`にする必要があります。

以下のようにデータベースセレクタと同じジェネレータを用いて、シャードの自動スワップ用ファイルを生成できます。

```bash
$ bin/rails g active_record:multi_db
```

次に、生成した`config/initializers/multi_db.rb`設定ファイルの以下の行をコメント解除して有効にします。

```ruby
Rails.application.configure do
  config.active_record.shard_selector = { lock: true }
  config.active_record.shard_resolver = ->(request) { Tenant.find_by!(host: request.host).shard }
end
```

アプリケーションは、リゾルバにコードを提供しなければなりません（リゾルバはアプリケーション固有のモデルに依存するため）。以下はリゾルバの例です。

```ruby
config.active_record.shard_resolver = ->(request) {
  subdomain = request.subdomain
  tenant = Tenant.find_by_subdomain!(subdomain)
  tenant.shard
}
```

## 粒度の細かいデータベース接続切り替え

Rails 6.1以後は、すべてのデータベースに対してグローバルにコネクションを切り替えるのではなく、1つのデータベースごとにコネクションを切り替えることが可能です。

データベース接続が細かなレベルで切り替わることで、任意の抽象コネクションクラスで、他のコネクションに影響を与えずにコネクションを切り替えられます。これは`ApplicationRecord`のクエリがprimaryに送信されることを保証しつつ、`AnimalsRecord`のクエリをreplicaから読み込むように切り替えるときに便利です。

```ruby
AnimalsRecord.connected_to(role: :reading) do
  Dog.first     # animals_replicaから読み出す
  Person.first  # primaryから読み出す
end
```

以下のようにシャードへの接続をより細かい粒度で切り替えることも可能です。

```ruby
AnimalsRecord.connected_to(role: :reading, shard: :shard_one) do
  # shard_one_replicaから読み出す。shard_one_replicaのコネクションが存在しない場合は
  # ConnectionNotEstablishedエラーが発生する
  Dog.first

  # primaryのライターから読み出す
  Person.first
end
```

primaryデータベースクラスタのみを切り替えたい場合は、以下のように`ApplicationRecord`を使います。

```ruby
ApplicationRecord.connected_to(role: :reading, shard: :shard_one) do
  Person.first # primary_shard_one_replicaから読み出す
  Dog.first    # animals_primaryから読み出す
end
```

`ActiveRecord::Base.connected_to`は、グローバルに接続を切り替える機能を管理します。

### データベース間でJOINする関連付けを扱う

Rails 7.0以降のActive Recordには、複数のデータベースにまたがってJOINを実行する関連付けを扱うオプションが提供されています。has many through関連付けやhas one through関連付けでJOINを無効にして複数のクエリを実行したい場合は、以下のように`disable_joins: true`オプションを渡します。

```ruby
class Dog < AnimalsRecord
  has_many :treats, through: :humans, disable_joins: true
  has_many :humans

  has_one :home
  has_one :yard, through: :home, disable_joins: true
end

class Home
  belongs_to :dog
  has_one :yard
end

class Yard
  belongs_to :home
end
```

従来は、`disable_joins`を指定しない`@dog.treats`や、`disable_joins`を指定しない`@dog.yard`を呼び出すと、データベースがクラスタ間のJOINを処理できないためエラーが発生しました。`disable_joins`オプションを指定することで、複数のSELECTクエリを生成してクラスタ間のJOIN回避を試みるようになります。上述の関連付けの場合、`@dog.treats`は以下のSQLを生成します。

```sql
SELECT "humans"."id" FROM "humans" WHERE "humans"."dog_id" = ?  [["dog_id", 1]]
SELECT "treats".* FROM "treats" WHERE "treats"."human_id" IN (?, ?, ?)  [["human_id", 1], ["human_id", 2], ["human_id", 3]]
```

`@dog.yard`は以下のSQLを生成します。

```sql
SELECT "home"."id" FROM "homes" WHERE "homes"."dog_id" = ? [["dog_id", 1]]
SELECT "yards".* FROM "yards" WHERE "yards"."home_id" = ? [["home_id", 1]]
```

このオプションには以下の注意点があります。

1. JOINの代わりに2つ以上のクエリが実行されるので、関連付けによってはパフォーマンスに影響が生じる可能性があります。`humans`をSELECTしたときに多数のIDが返されると、`treats`のSELECTによって多数のIDが送信される可能性があります。

2. JOINが実行されなくなるので、クエリのORDERやLIMITはメモリ上でソートされます（あるテーブルのORDERを別のテーブルに適用できないため）。

3. この設定は、JOINを無効にしたいすべての関連付けに追加しなければなりません。
Railsはこれを自動で推測できません（関連付けはlazyに読み込まれるので、`@dog.treats`で`treats`を読み込むには、どんなSQLを生成すべきかをRailsが事前に認識しておく必要があります）。

### スキーマのキャッシュ

スキーマキャッシュをデータベースごとに読み込みたい場合は、データベースごとに`schema_cache_path`を設定し、かつアプリケーション設定で`config.active_record.lazily_load_schema_cache = true`を設定しなければなりません。この場合、データベース接続が確立されたときにキャッシュがlazyに読み込まれる点にご注意ください。

## 注意点

### replicaの負荷分散

Railsはreplicaの自動負荷分散（ロードバランシング）をサポートしていません。これはインフラストラクチャに大きく依存します。将来的には基本的なプリミティブ負荷分散を実装する可能性もありますが、大規模なアプリケーションの場合はRailsの外部で処理する必要があります。
