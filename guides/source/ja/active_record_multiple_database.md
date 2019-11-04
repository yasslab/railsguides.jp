**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Active Record で複数のデータベースを使う
=====================================

このガイドでは、Railsアプリケーションでマルチプルデータベースを使う方法について説明します。

このガイドの内容:

* アプリケーションでマルチプルデータベースをセットアップする方法
* 自動接続切り替えのしくみ
* サポートされる機能と進行中の機能

--------------------------------------------------------------------------------

アプリケーションの人気と利用が増加するにつれて、アプリケーションをスケールして新しいユーザーとユーザーのデータを支える必要が生じます。アプリケーションをスケールする必要が生じた場合の方法のひとつは、データベースレベルでのスケールです。Railsでマルチプルデータベースがサポートされたことで、すべてのデータを1箇所に集約しなくてもよいようになりました。

現時点でサポートされている機能は以下のとおりです。

* 複数のprimaryデータベースとそれぞれに対応するreplicaデータベース
* 現在動かしているモデルでの自動接続切り替え
* HTTP動詞や直近の書き込みに応じたprimaryとreplicaの自動切り替え
* マルチプルデータベースの作成・削除・マイグレーション・操作を行うRailsタスク

以下の機能は現時点ではまだサポートされていません。

* シャーディング（Sharding）
* クラスタをまたがるJOIN
* replicaのロードバランシング

## アプリケーションのセットアップ

ほとんどの作業についてはRailsが作業を代行しますが、アプリケーションでマルチプルデータベースを使うにはいくつかのステップを手動で行う必要があります。

たとえば、アプリケーションにprimaryデータベースが1つあり、テーブルをいくつか追加するために新しいデータベースを追加する必要が生じたとしましょう。新しいデータベースの名前は「animals」とします。

このdatabase.ymlは以下のような感じになります。

```yaml
production:
  database: my_primary_database
  user: root
  adapter: mysql
```

このprimaryにreplicaを1つ追加し、さらにanimalsというライター（writer）を1つとそのreplicaも追加してみましょう。そのためには、database.ymlの設定を以下のように2-tierから3-tierに変更する必要があります。

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

マルチプルデータベースを使う場合、いくつか重要な設定があります。

第1に、primaryとreplicaは同じデータを持つので、データベース名はどちらも同じにすべきです。第2に、primaryとreplicaのusernameは別々にし、かつreplicaユーザーのパーミッションは読み出し専用にして書き込みできないようにすべきです。

replicaデータベースを使う場合、`database.yml`のreplicaに`replica: true`というエントリを追加する必要があります。これを行わないと、Railsはどちらがreplicaでどちらがprimaryかを認識する手段がなくなってしまいます。

最後に、新しいprimaryデータベースの`migrations_paths`に、そのデータベースのマイグレーションファイルの保存場所を指定する必要があります。`migrations_paths`について詳しくは本ガイドで後述します。

以上で新しいデータベースが1つできましたので、続いてモデルをセットアップしましょう。新しいデータベースを使うには、抽象クラス（abstract class）を1つ作成してanimalsデータベースに接続する必要があります。

```ruby
class AnimalsBase < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

新しいreplicaを認識できるよう、`ApplicationRecord`を更新します。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

デフォルトのRailsでは、データベースのロールがprimaryでは`writing`、replicaでは`reading`になっていることが期待されます。既にレガシーシステムに設定されているロールを変更したくない場合は、アプリケーションの設定ファイルで新しいロール名を設定できます。

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

以上でdatabase.ymlと新しいモデルをセットアップできましたので、いよいよデータベースを作成しましょう。Rails 6.0には、Railsでマルチプルデータベースを利用するのに必要なrailsタスクがひととおり揃っています。

`rails -T`を実行すると、利用可能なコマンドのリストが以下のように表示されるはずです。


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

`rails db:create`などのコマンドを実行すると、primaryデータベースとanimalデータベースの両方が作成されます。なおユーザー作成用のコマンドはありませんので、replicaの読み取り専用ユーザーをサポートするには手動で作成する必要があります。animalsデータベースを作成したいだけなら、`rails db:create:animals`でできます。

## マイグレーション

マルチプルデータベースのマイグレーションは、データベースキーの名前をプレフィックスとして持つフォルダをデータベースごとに作成して設定の下に置き、そこに保存すべきです。

Railsがマイグレーションファイルを探索する場所を認識できるよう、データベース設定の`migrations_paths`も設定する必要があります。

たとえば、`animails`データベースは`db/animals_migrate`ディレクトリ以下を探索し、`primary`は`db/migrate`を探索する、という感じになります。Railsのジェネレータで利用できるようになった`--database`オプションを指定すると、ファイルが正しいディレクトリ内に作成されます。コマンドは以下のような感じで実行します。

```
$ rails g migration CreateDogs name:string --database animals
```

## 接続の自動切り替えを有効にする

最後に、読み取り専用のreplicaをアプリケーションで使うには、自動切り替えミドルウェアを有効にする必要があります。

自動切り替えによって、アプリケーションはHTTP動詞（verb）や直近の書き込みの有無に基づいて、primaryからreplica、またはreplicaからprimaryへと切り替わります。

アプリケーションがPOSTやPUTやDELETEやPATCHのいずれかのリクエストを受け取ると、自動的にprimaryに書き込まれます。書き込み以後、アプリケーションは指定の回数replicaから読み出すようになります。アプリケーションがGETやHEADのいずれかのリクエストを受け取ると、直近の書き込みがない場合を除いてreplicaから読み出します。

自動接続切り替え用のミドルウェアを有効にするには、アプリケーション設定に以下の行を追加（またはコメントを解除）します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
```

Railsは「自分が書き込んだものは読み出せる」ことを保証するので、`delay`ウィンドウの時間内であればGETリクエストやHEADリクエストをprimaryに送信します。`delay`はデフォルトで2秒に設定されます。この設定は、利用しているデータベースインフラストラクチャに応じて変更すべきです。Railsは、他のユーザーについては`delay`ウィンドウの時間内に「最新の書き込み結果を読み出せる」ことを保証しませんので、GETリクエストやHEADリクエストは、直近の書き込みが生じていた場合を除いてreplicaに送信します。

Railsの自動接続切り替え機能は比較的原始的なつくりなので、何でもきめ細かくやってくれるというものではありません。目的は、自動接続切り替え機能がアプリ開発者にとってカスタマイズを十分行えるだけの柔軟性を備えていることをデモンストレーションすることです。

切替方法や自動切り替えのパラメータは、Railsのセットアップで簡単に変更できます。たとえば接続の入れ替えをセッションではなくcookieで行いたい場合、以下のように独自のクラスを書けます。

```ruby
class MyCookieResolver
  # cookie用クラスのコードをここに書く
end
```

続いて、このクラスをミドルウェアに渡します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = MyCookieResolver
```

## 接続を手動で切り替える

アプリケーションによっては、primaryやreplicaへの接続を自動切り替えするのが適切ではないこともあります。たとえば、（POSTリクエストパスであっても）特定のリクエストを常にreplicaに送信したい場合です。

Railsでは、必要な接続に切り替えるための`connected_to`メソッドが提供されています。

```ruby
ActiveRecord::Base.connected_to(role: :reading) do
  # このブロック内のコードはすべてreadingロールに接続される
end
```

`connected_to`呼び出しの「role」は、そのコネクションハンドラ（またはロール）に接続されているコネクションを探索します。この`reading`コネクションハンドラは、`connects_to`で接続された`reading`というロール名のコネクションをすべて維持します。

別のケースとして、クエリが遅い場合や分析のために必要なデータベースが1つあるが、アプリケーションの起動時に常に接続したいわけではない場合を考えます。database.ymlで定義されていれば、`connected_to`にデータベース引数を渡すことで接続できます。

```ruby
ActiveRecord::Base.connected_to(database: { reading_slow: :animals_slow_replica }) do
  # 遅いreplicaに接続中に何かする
end
```

`connected_to`の`database`引数は、シンボルを1つ、または設定ハッシュを1つ受け取ります。

なお、`connected_to`でロールを指定すると、既存の接続の探索や切り替えにその接続仕様名（connection specification name）が用いられることにご注意ください。つまり、`connected_to(role: :nonexistent)`のように存在しないロールを渡すと、`ActiveRecord::ConnectionNotEstablished (No connection pool with 'AnimalsBase' found for the 'nonexistent' role.)`エラーが生じます。

## 注意点

冒頭で延べたように、Railsではシャーディングが（まだ）サポートされていません。Rails 6.0でマルチプルデータベースをサポートするために多くの作業を行わなければならなかったのですが、決してシャーディングを忘れていたのではなく、6.0では間に合わなかった追加作業が必要だからです。現時点でシャーディングを使いたい場合は、シャーディングをサポートするさまざまなgemがありますので、そちらを引き続き利用してみてはいかがでしょう。

Railsでは、replicaの自動ロードバランシングのサポートもありません。自動ロードバランシングはインフラストラクチャに強く依存しますので、いつか基本的かつ原始的なロードバランシングを実装することがあるかもしれませんが、アプリケーションをスケールする場合はRailsの外部で自動ロードバランシングすべきでしょう。

最後に、データベースをまたがるJOINは利用できません。Rails 6.1では`has_many`リレーションシップの利用と、JOINではなく「2つのクエリ作成」をサポートする予定ですが、Rails 6.0ではJOINを手動で2つのSELECTに分ける必要があります。
