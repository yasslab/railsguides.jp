Active Record で複数のデータベース利用
=====================================

このガイドでは、Active Recordでデータベースを複数利用する方法について説明します。

このガイドの内容:

* アプリケーションで複数のデータベースをセットアップする方法
* コネクションの自動切り替えの仕組み
* サポートされている機能と現在進行中の機能

--------------------------------------------------------------------------------


アプリケーションが人気を得て利用されるようになってくると、新しいユーザーやユーザーのデータをサポートするためにアプリケーションをスケールする必要が生じてきます。アプリケーションをスケールする方法のひとつが、データベースレベルでのスケールでしょう。Railsが複数のデータベースをサポートするようになりましたので（マルチプルデータベース）、すべてのデータを1箇所に保存する必要はありません。

現時点でサポートされている機能は以下のとおりです。

* 複数の「primary」データベースと、それぞれに対応する1つの「replica」
* モデルでのコネクション自動切り替え
* HTTP verbや直近の書き込みに応じたprimaryとreplicaの自動スワップ
* マルチプルデータベースの作成、削除、マイグレーション、やりとりを行うRailsタスク

以下の機能は現時点では（まだ）サポートされていません。

* シャーディング（sharding）
* クラスタを越えるJOIN
* replicaのロードバランシング
* マルチプルデータベースのスキーマキャッシュのダンプ

## アプリケーションのセットアップ

アプリケーションでマルチプルデータベースを利用する場合、大半の機能についてはRailsが代わりに行いますが、一部手動で行う手順があります。

たとえば、primaryデータベースがひとつあるアプリケーションに、新しいテーブルがいくつかあるデータベースを1つ追加するとします。新しいデータベースの名前は「animal」とします。

この場合のdatabase.ymlは以下のような感じになります。

```yaml
production:
  database: my_primary_database
  user: root
  adapter: mysql
```

このprimaryで使うreplicaを1つ追加してみましょう。animalという新しいライター（writer）を1つと、それに対応するreplicaも1つ追加します。これを行うには、database.ymlを以下のように2-tierから3-tier設定に変更する必要があります。

```yaml
production:
  primary:
    database: my_primary_database
    user: root
    adapter: mysql
  primary_replica:
    database: my_primary_database
    user: root_readonly
    adapter: mysql
    replica: true
  animals:
    database: my_animals_database
    user: animals_root
    adapter: mysql
    migrations_paths: db/animals_migrate
  animals_replica:
    database: my_animals_database
    user: animals_readonly
    adapter: mysql
    replica: true
```

マルチプルデータベースを用いる場合に重要な設定がいくつかあります。

第1に、primaryとreplicaのデータベース名は同じにすべきです。理由は、primaryとreplicaが同じデータを持つからです。第2に、primaryとreplicaでは異なるユーザー名を使い、かつreplicaのパーミッションは（writeではなく）readにすべきです。

replicaデータベースを使う場合、`database.yml`のreplicaには`replica: true`というエントリを1つ追加する必要があります。このエントリがないと、どちらがreplicaでどちらがprimaryかをRailsが区別できなくなるためです。

最後に、新しいprimaryデータベースで利用するために、そのデータベースのマイグレーションを置くディレクトリを`migrations_paths`に設定する必要があります。`migrations_paths`については本ガイドで後述します。

新しいデータベースができたら、モデルをセットアップしましょう。新しいデータベースを使うには、抽象クラスを1つ作成してanimalsデータベースに接続する必要があります。

```ruby
class AnimalsBase < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

続いて`ApplicationRecord`を更新し、新しいreplicaを認識させる必要があります。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

Railsはデフォルトで、primaryのデータベースロールは`writing`、replicaのデータベースロールは`reading`であることを期待します。レガシーなシステムでは、既に設定されているロールを変更したくないこともあるでしょう。その場合はアプリケーションで以下のように新しいロール名を設定できます。

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

ここで重要なのは、データベースへの接続を「単一のモデル内」で行うことと、そのモデルを継承してテーブルを利用することです（複数のモデルから同じデータベースに接続するのではなく）。データベースクライアントにはコネクションをオープンできる数に上限があります。Railsはコネクションを指定する名前としてモデル名を用いるので、複数のモデルから同じデータベースに接続するとコネクション数が増加します。

database.ymlと新しいモデルをセットアップできたので、いよいよデータベースを作成しましょう。Rails 6.0にはマルチプルデータベースを使うのに必要なrailsタスクがすべて揃っています。

`rails -T`を実行すると、利用可能なコマンド一覧がすべて表示されます。出力は以下のようになります。

```
$ rails -T
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
```

`rails db:create`などのコマンドを実行すると、primaryとanimalsデータベースの両方が作成されます。ただし（データベースの）ユーザーを作成するコマンドはないので、replicaでreadonlyをサポートするには手動で行う必要があります。animalデータベースだけを作成するには、`rails db:create:animals`を実行します。

## マイグレーション

マルチプルデータベースでのマイグレーションは、設定ファイルにあるデータベースキー名を冒頭に付けた個別のフォルダに配置すべきです。

データベース設定の`migrations_paths`を設定し、マイグレーションファイルを探索する場所をRailsに認識させる必要もあります。

たとえば、`animals`データベースは`db/animals_migrate`ディレクトリに配置、`primary`は`db/migrate`ディレクトリに配置、という具合になります。Railsのジェネレータは、ファイルを正しいディレクトリで生成するための`--database`オプションを受け取るようになりました。このコマンドは次のような感じで実行します。

```
$ rails g migration CreateDogs name:string --database animals
```

## コネクションの自動切り替えを有効にする

最後に、アプリケーションでread-onlyのレプリカを利用するために、自動切り替え用のミドルウェアを有効にする必要があります。

自動切り替え機能によって、アプリケーションはHTTP verbや直近の書き込みの有無に応じてprimaryからreplica、またはreplicaからprimaryへと切り替えます。

アプリケーションがPOST、PUT、DELETE、PATCHのいずれかのリクエストを受け取ると、自動的にprimaryに書き込みます。書き込み後に指定の時間が経過するまでは、アプリケーションはprimaryから読み出します。アプリケーションがGETリクエストやHEADリクエストを受け取ると、直近の書き込みがなければreplicaから読み出します。

コネクション自動切り替えのミドルウェアを有効にするには、アプリケーション設定に以下の行を追加するか、コメントを解除します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
```

Railsは「自分が書き込んだものを読み取る」ことを保証するので、`delay`ウィンドウの期間内であればGETリクエストやHEADリクエストをprimaryに送信します。この`delay`は、デフォルトで2秒に設定されます。この値の変更は、利用するデータベースのインフラストラクチャに基づいて行うべきです。Railsは、`delay`ウィンドウの期間内で他のユーザーが「最近書き込んだものを読み取る」ことについては保証しないので、最近書き込まれたものでなければGETリクエストやHEADリクエストをreplicaに送信します。

Railsのコネクション自動切り替えは、どちらかというと原始的であり、多機能とは言えません。もともとこの機能は、アプリケーションの開発者でも十分カスタマイズ可能な柔軟性を備えたコネクション自動切り替えシステムをデモンストレーションするためのものでした。

Railsでのコネクション自動切り替え方法や、切り替えに使うパラメータはセットアップで簡単に変更できます。たとえば、コネクションをスワップするかどうかを、セッションではなくcookieで行いたいのであれば、以下のように独自のクラスを作成できます。

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

アプリケーションでprimaryやreplicaに接続するときに、コネクションの自動切り替えが適切ではないことがあります。たとえば、特定のリクエストについては、たとえPOSTリクエストパスにいる場合であっても常にreplicaに送信したいとします。

Railsはこのような場合のために、必要なコネクションに切り替える`connected_to`メソッドを提供しています。


```ruby
ActiveRecord::Base.connected_to(role: :reading) do
  # このブロック内のコードはすべてreadingロールで接続される
end
```

```ruby
AnimalsRecord.connected_to(role: :reading) do
  Dog.first # Reads from animals_replica
  Person.first  # Reads from primary
end
```

また、シャードに対して細かく接続をスワップできます。

```ruby
AnimalsRecord.connected_to(role: :reading, shard: :shard_one) do
  Dog.first # Will read from shard_one_replica. If no connection exists for shard_one_replica,
  # a ConnectionNotEstablished error will be raised
  Person.first # Will read from primary writer
end
```

primaryデータベース群のみを切り替えたい場合は`ApplicationRecord`を使用してください:

```ruby
ApplicationRecord.connected_to(role: :reading, shard: :shard_one) do
  Person.first # Reads from primary_shard_one_replica
  Dog.first # Reads from animals_primary
end
```

`ActiveRecord::Base.connected_to`はグローバルに接続を切り替える機能を管理します。

## 注意点

### 水平シャーディングのための自動スワップ

現在Railsはシャードへの接続や、シャードの接続をスワップするAPIをサポートしていますが、
自動スワップ戦略はまだサポートしていません。
ミドルウェアか`around_action`を介して、アプリケーション内で手動でシャードスワップを行う必要があります。

### replicaのロードバランシング

replicaのロードバランシングはインフラストラクチャに強く依存するため、これもRailsではサポート対象外です。今後、基本的かつ原始的なreplicaロードバランシング機能が実装されるかもしれませんが、アプリケーションをスケールさせるためにもRailsの外部でアプリケーションを扱えるものにすべきです。

### データベースをまたがるJOIN

アプリケーションは複数のデータベースにまたがるJOINを行えません。
現時点では、ユーザ自身が手動で2つのセレクト文を書き、joinを分割する必要があります。
将来のバージョンでは、Railsがjoinを分割してくれるようになります。

### スキーマキャッシュ

スキーマキャッシュとマルチプルデータベースを利用する場合、アプリのスキーマキャッシュを読み込むためのイニシャライザを自分で書く必要があります。Rails 6.0には間に合いませんでしたが、いずれ今後のバージョンで解決できればと思います。
