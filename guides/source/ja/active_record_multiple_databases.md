Active Record で複数のデータベース利用
=====================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Multiple Databases with Active Record](https://guides.rubyonrails.org/active_record_multiple_databases.html)を日本語に翻訳した文書です。

本ガイドでは、Active Recordで複数のデータベースを利用する方法について説明します。

このガイドの内容:

* アプリケーションで複数のデータベースをセットアップする方法
* コネクションの自動切り替えの仕組み
* 複数のデータベースにおける水平シャーディングの利用方法
* `legacy_connection_handling`から新しいコネクションハンドリングに移行する方法
* サポートされている機能と現在進行中の機能

--------------------------------------------------------------------------------


アプリケーションが人気を得て利用されるようになってくると、新しいユーザーやユーザーのデータをサポートするためにアプリケーションをスケールする必要が生じてきます。アプリケーションをスケールする方法の１つが、データベースレベルでのスケールでしょう。Railsが複数のデータベース（Multiple Databases）をサポートするようになったので、すべてのデータを1箇所に保存する必要はありません。

現時点でサポートされている機能は以下のとおりです。

* 複数の「writer」データベースと、それぞれに対応する「replica」データベース
* 作業中のモデルでのコネクション自動切り替え
* HTTP verbや直近の書き込みに応じたwriterとreplicaの自動スワップ
* 複数のデータベースの作成、削除、マイグレーション、各種操作を行うRailsタスク

以下の機能は現時点では（まだ）サポートされていません。

* replicaのロードバランシング

## アプリケーションのセットアップ

アプリケーションで複数のデータベースを利用する場合、大半の機能についてはRailsが代わりに行いますが、一部の手順は手動で行う必要があります。

たとえばwriterデータベースが１つあるアプリケーションに、新しいテーブルがいくつかあるデータベースを１つ追加するとします。新しいデータベースの名前は「animal」とします。

この場合のdatabase.ymlは以下のような感じになります。

```yaml
production:
  database: my_primary_database
  adapter: mysql2
  username: root
  password: <%= ENV['ROOT_PASSWORD'] %>
```

最初の設定に対するreplicaを追加し、さらにanimalという2個目のデータベースとそれのreplicaも追加してみましょう。これを行うには、database.ymlを以下のように2層（2-tier）設定から3層（3-tier）設定に変更する必要があります。

primary設定がある場合、これが「デフォルト」の設定として使われます。「primary」と名付けられた設定がない場合、Railsは最初の設定を各環境で使います。
デフォルトの設定ではデフォルトのRailsのファイル名が使われます。たとえば、primary設定のスキーマファイル名には`schema.rb`が使われ、その他のエントリではファイル名に`設定の名前空間_schema.rb`が使われます。

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

replicaデータベースを使う場合、`database.yml`のreplicaには`replica: true`というエントリを1つ追加する必要があります。このエントリがないと、どちらがreplicaでどちらがwriterかをRailsが区別できなくなるためです。Railsは、マイグレーションなどの特定のタスクについてはreplicaに対して実行しません。

最後に、新しいwriterデータベースで利用するために、そのデータベースのマイグレーションを置くディレクトリを`migrations_paths`に設定する必要があります。`migrations_paths`については本ガイドで後述します。

新しいデータベースができたら、コネクションモデルをセットアップしましょう。新しいデータベースを使うには、抽象クラスを1つ作成してanimalsデータベースに接続する必要があります。

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

続いて`ApplicationRecord`クラスを以下のように更新し、新しいreplicaを認識させる必要があります。

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
end
```

primary/primary_replicaに接続するクラスは、通常のRailsアプリケーションと同様に`ApplicationRecord`を継承できます。

```ruby
class Person < ApplicationRecord
end
```

Railsはデフォルトで、primaryのデータベースロールは`writing`、replicaのデータベースロールは`reading`であることを期待します。レガシーなシステムでは、既に設定されているロールを変更したくないこともあるでしょう。その場合はアプリケーションで以下のように新しいロール名を設定できます。

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

ここで重要なのは、データベースへの接続を「単一のモデル内」で行うことと、そのモデルを継承してテーブルを利用することです（複数のモデルから同じデータベースに接続するのではなく）。データベースクライアントがコネクションをオープンできる数には上限があります。Railsはコネクションを指定する名前にモデル名を用いるので、同じデータベースに複数のモデルから接続するとコネクション数が増加します。

`database.yml`と新しいモデルをセットアップできたので、いよいよデータベースを作成しましょう。Rails 6.0には複数のデータベースを使うのに必要なrailsタスクがすべて揃っています。

`bin/rails -T`を実行すると、利用可能なコマンド一覧がすべて表示されます。出力は以下のようになります。

```bash
$ bin/rails -T
rails db:create                          # Creates the database from DATABASE_URL or config/database.yml for the ...
rails db:create:animals                  # Create animals database for current environment
rails db:create:primary                  # Create primary database for current environment
rails db:drop                            # Drops the database from DATABASE_URL or config/database.yml for the cu...
rails db:drop:animals                    # Drop animals database for current environment
rails db:drop:primary                    # Drop primary database for current environment
rails db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
rails db:migrate:animals                 # Migrate animals database for current environment
rails db:migrate:primary                 # Migrate primary database for current environment
rails db:migrate:status                  # Display status of migrations
rails db:migrate:status:animals          # Display status of migrations for animals database
rails db:migrate:status:primary          # Display status of migrations for primary database
rails db:reset                           # Drops and recreates all databases from their schema for the current environment and loads the seeds
rails db:reset:animals                   # Drops and recreates the animals database from its schema for the current environment and loads the seeds
rails db:reset:primary                   # Drops and recreates the primary database from its schema for the current environment and loads the seeds
rails db:rollback                        # Rolls the schema back to the previous version (specify steps w/ STEP=n)
rails db:rollback:animals                # Rollback animals database for current environment (specify steps w/ STEP=n)
rails db:rollback:primary                # Rollback primary database for current environment (specify steps w/ STEP=n)
rails db:schema:dump                     # Creates a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:dump:animals             # Creates a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:dump:primary             # Creates a db/schema.rb file that is portable against any DB supported  ...
rails db:schema:load                     # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:load:animals             # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:load:primary             # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:setup                           # Creates all databases, loads all schemas, and initializes with the seed data (use db:reset to also drop all databases first)
rails db:setup:animals                   # Creates the animals database, loads the schema, and initializes with the seed data (use db:reset:animals to also drop the database first)
rails db:setup:primary                   # Creates the primary database, loads the schema, and initializes with the seed data (use db:reset:primary to also drop the database first)
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

データベース名の末尾に`Record`を加えた抽象クラスが作成されます。この例ではデータベースが`Animals`なので、`AnimalsRecord`が作成されます。

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

Railsは新しいクラスを一度だけ生成します。新しいscaffoldによって上書きされることはなく、scaffoldが削除されると削除されます。

`AnimalsRecord`と異なる既存の抽象クラスがある場合、`--parent`オプションで別の抽象クラスを指定できます。

```bash
$ bin/rails generate scaffold Dog name:string --database animals --parent Animals::Record
```

上では別の親クラスの利用を指定しているため、`AnimalsRecord`の生成をスキップします。

## ロールの自動切り替えを有効にする

最後に、アプリケーションでread-onlyのreplicaを利用するために、自動切り替え用のミドルウェアを有効にする必要があります。

自動切り替え機能によって、アプリケーションはHTTP verbや、リクエストしたユーザーによる直近の書き込みの有無に応じてwriterからreplica、またはreplicaからwriterへと切り替えます。

アプリケーションがPOST、PUT、DELETE、PATCHのいずれかのリクエストを受け取ると、自動的にwriterデータベースに書き込みます。書き込み後に指定の時間が経過するまでは、アプリケーションはwriterから読み出します。アプリケーションがGETリクエストやHEADリクエストを受け取ると、直近の書き込みがなければreplicaから読み出します。

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
class MyCookieResolver
  # cookieクラスで使うコードをここに書く
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
  primary_shard_one_replica:
    database: my_primary_shard_one
    adapter: mysql2
    replica: true
```

次に、モデルは `shards`キーを介して`connects_to`APIに接続されます。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to shards: {
    default: { writing: :primary, reading: :primary_replica },
    shard_one: { writing: :primary_shard_one, reading: :primary_shard_one_replica }
  }
end
```

これで、モデルは`connected_to`APIを用いて手動でコネクションを切り替えられるようになります。シャーディングを使う場合は、`role`と`shard`の両方を渡す必要があります。

```ruby
ActiveRecord::Base.connected_to(role: :writing, shard: :default) do
  @id = Person.create! # Creates a record in shard default
end

ActiveRecord::Base.connected_to(role: :writing, shard: :shard_one) do
  Person.find(@id) # Can't find record, doesn't exist because it was created
                   # in the default shard
end
```

水平シャーディングAPIはread replicaもサポートしています。以下のように`connected_to`APIでロールとシャードを切り替えられます。

```ruby
ActiveRecord::Base.connected_to(role: :reading, shard: :shard_one) do
  Person.first # Lookup record from read replica of shard one
end
```

## 自動シャード切り替えを有効にする

アプリケーションで提供されているミドルウェアを使うと、リクエスト単位でシャードを自動切り替えできるようになります。

ShardSelectorミドルウェアは、シャードを自動スワップするフレームワークを提供します。Railsは、どのシャードに切り替えるかを判断する基本的なフレームワークを提供し、必要に応じてアプリケーションでスワップのカスタム戦略を記述できます。

ShardSelectorには、ミドルウェアの動作を変更できるオプションのセットを渡せます（現在は`lock`のみをサポート）。`lock`はデフォルトでは`true`で、ブロック内でのシャード切り替えを禁止します。`lock`が`false`の場合はシャードのスワップが許可されます。
テナントベースのシャーディングでは、アプリケーションコードが誤ってテナントを切り替えることのないよう、`lock`は常に`true`にする必要があります。

以下のようにデータベースセレクタと同じジェネレータを用いて、シャードの自動スワップ用ファイルを生成できます。

```bash
$ bin/rails g active_record:multi_db
```

次に、設定ファイルの以下の行をコメント解除して有効にします。

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

## 新しいコネクションハンドリングに移行する

Rails 6.1以降のActive Recordでは、コネクション管理用の新しい内部APIが提供されています。
ほとんどの場合、アプリケーションで[`config.active_record.legacy_connection_handling`][]を設定して新しい振る舞いを有効にするだけでよく、それ以外の変更は不要です（Rails 6.0以前からアップグレードする場合）。データベースが１つしかないアプリケーションの場合は、その他の変更は不要です。複数のデータベースを利用しているアプリケーションで以下のメソッドを利用している場合は、以下の変更が必要です。

* `connection_handlers`および`connection_handlers=`は新しいコネクションハンドリングでは動作しなくなります。いずれかのコネクションハンドラでメソッドを呼び出している場合（`connection_handlers[:reading].retrieve_connection_pool("ActiveRecord::Base")`など）は、そのメソッド呼び出しを`connection_handlers.retrieve_connection_pool("ActiveRecord::Base", role: :reading)`のように更新する必要があります。

* `ActiveRecord::Base.connection_handler.prevent_writes`呼び出しは、`ActiveRecord::Base.connection.preventing_writes?`に更新する必要があります。

* 書き込みと読み出しを含むすべてのプールが必要な場合は、ハンドラで新しいメソッドが提供されます。これを使うには`connection_handler.all_connection_pools`を呼び出します。しかしほとんどの場合、`connection_handler.connection_pool_list(:writing)`または`connection_handler.connection_pool_list(:reading)`を用いるプールへの書き込みや読み出しが必要になるでしょう。

* アプリケーションで`legacy_connection_handling`をオフにすると、サポートされていないメソッド（ `connection_handlers=`など）でエラーが生じます。

[`config.active_record.legacy_connection_handling`]: configuring.html#config-active-record-legacy-connection-handling

## 粒度の細かいデータベース接続切り替え

Rails 6.1では、すべてのデータベースに対してグローバルにコネクションを切り替えるのではなく、1つのデータベースでコネクションを切り替えることが可能です。この機能を使うには、まずアプリケーションの設定で[`config.active_record.legacy_connection_handling`][]を`false`に設定する必要があります。パブリックAPIの振る舞いは変わらないため、ほとんどのアプリケーションではそれ以外の変更は不要です。`legacy_connection_handling`を有効にして移行する方法については上のセクションを参照してください。

`legacy_connection_handling`を`false`に設定すると、任意の抽象コネクションクラスで、他のコネクションに影響を与えずにコネクションを切り替えられます。これは`ApplicationRecord`のクエリがプライマリに送信されることを保証しつつ、`AnimalsRecord`のクエリをレプリカから読み込むように切り替えるときに便利です。

```ruby
AnimalsRecord.connected_to(role: :reading) do
  Dog.first     # animals_replicaから読み出す
  Person.first  # プライマリから読み出す
end
```

以下のようにシャードへの接続をより細かい粒度で切り替えることも可能です。

```ruby
AnimalsRecord.connected_to(role: :reading, shard: :shard_one) do
  Dog.first # shard_one_replicaから読み出す。
            # shard_one_replicaのコネクションが存在しない場合は
            # ConnectionNotEstablishedエラーが発生する
  Person.first # プライマリライターから読み出す
end
```

primaryデータベースクラスタのみを切り替えたい場合は、以下のように`ApplicationRecord`を使います。

```ruby
ApplicationRecord.connected_to(role: :reading, shard: :shard_one) do
  Person.first # Reads from primary_shard_one_replica
  Dog.first # Reads from animals_primary
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

### replicaのロードバランシング

replicaのロードバランシングはインフラストラクチャに強く依存するため、これもRailsではサポート対象外です。今後、基本的かつプリミティブなreplicaロードバランシング機能が実装されるかもしれませんが、アプリケーションをスケールさせるためにも、Railsの外部でアプリケーションを扱えるものにすべきです。
