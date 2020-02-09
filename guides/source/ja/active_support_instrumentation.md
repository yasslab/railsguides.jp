**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Support の Instrumentation 機能
==============================

Active SupportはRailsのコア機能のひとつであり、Ruby言語の拡張、ユーティリティなどを提供するものです。Active Supportに含まれているInstrumentation APIは、Rubyコードで発生する特定の動作の計測に利用できます。Railsアプリケーション内部やフレームワーク自身も計測できますが、必要であればRails以外のRubyスクリプトなども測定できます。

本ガイドでは、RailsなどのRubyコード内のイベント計測に使う、Active Support内のInstrumentation APIについて解説します。

このガイドの内容:

* Instrumentationでできること
* Railsフレームワーク内のInstrumentationフック
* フックにサブスクライバを追加する
* 独自のInstrumentationを実装する

--------------------------------------------------------------------------------

Instrumentationについて
-------------------------------

Active Supportが提供するInstrumentation APIを使ってフックを開発すると、他の開発者がそこにフックできるようになります。フックの多くは、[Railsフレームワーク](#railsフレームワーク用フック)向けです。このAPIをアプリケーションで実装すると、アプリケーション（またはRubyコード片）内部でイベントが発生したときに通知を受け取れるよう他の開発者が設定できます。

たとえばActive Recordには、データベースへのSQLクエリが発行されるたびに呼び出されるフックが用意されていますこのフックを**サブスクライブ（購読）**すると、特定のアクションでのクエリ実行数を追跡できます。他に、コントローラのアクション実行中に呼び出されるフックもあります。このフックは、たとえば特定のアクション実行に要する時間の測定に利用できます。

もちろん、アプリケーション内に独自のイベントを作成し、後で自分でサブスクライブして測定することもできます。

Railsフレームワーク用フック
---------------------

Ruby on Railsでは、フレームワーク内の主なイベント向けのフックが多数提供されています詳しくは次をご覧ください。

Action Controller
-----------------

### write_fragment.action_controller

| キー    | 値               |
| ------ | ---------------- |
| `:key` | 完全なキー         |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### read_fragment.action_controller

| キー    | 値               |
| ------ | ---------------- |
| `:key` | 完全なキー         |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### expire_fragment.action_controller

| キー    | 値               |
| ------ | ---------------- |
| `:key` | 完全なキー         |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### exist_fragment?.action_controller

| キー    | 値               |
| ------ | ---------------- |
| `:key` | 完全なキー         |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### write_page.action_controller

| キー    | 値                 |
| ------- | ----------------- |
| `:path` | 完全なパス          |

```ruby
{
  path: '/users/1'
}
```

### expire_page.action_controller

| キー    | 値                 |
| ------- | ----------------- |
| `:path` | 完全なパス          |

```ruby
{
  path: '/users/1'
}
```

### start_processing.action_controller

| キー           | 値                                                        |
| ------------- | --------------------------------------------------------- |
| `:controller` | コントローラ名                                               |
| `:action`     | アクション                                                  |
| `:params`     | リクエストパラメータのハッシュ（フィルタされたパラメータは含まない）    |
| `:headers`    | リクエスト ヘッダー                                           |
| `:format`     | html/js/json/xml など                                      |
| `:method`     | HTTP リクエストメソッド（verb）                                |
| `:path`       | リクエスト パス                                              |

```ruby
{
  controller: "PostsController",
  action: "new",
  params: { "action" => "new", "controller" => "posts" },
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts/new"
}
```

### process_action.action_controller

| キー           | 値                                                        |
| ------------- | --------------------------------------------------------- |
| `:controller` | コントローラ名                                               |
| `:action`     | アクション                                                  |
| `:params`     | リクエストパラメータのハッシュ（フィルタされたパラメータは含まない）    |
| `:headers`    | リクエスト ヘッダー                                           |
| `:format`     | html/js/json/xml など                                      |
| `:method`     | HTTP リクエストメソッド（verb）                                |
| `:path`       | リクエスト パス                                              |
| `:status`       | HTTP ステータスコード                                      |
| `:view_runtime` | ビューでかかった合計時間（ms）                                |
| `:db_runtime`   | データベースへのクエリ実行にかかった時間（ms）                   |

```ruby
{
  controller: "PostsController",
  action: "index",
  params: {"action" => "index", "controller" => "posts"},
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts",
  status: 200,
  view_runtime: 46.848,
  db_runtime: 0.157
}
```

### send_file.action_controller

| キー     | 値                        |
| ------- | ------------------------- |
| `:path` | ファイルへの完全なパス         |

INFO. 呼び出し側でキーが追加される可能性があります。

### send_data.action_controller

`ActionController`自身は、ペイロードに情報を持ちません。オプションは、すべてペイロード経由で渡されます。

### redirect_to.action_controller

| キー         | 値                 |
| ----------- | ------------------ |
| `:status`   | HTTP レスポンス コード |
| `:location` | リダイレクト先URL     |

```ruby
{
  status: 302,
  location: "http://localhost:3000/posts/new"
}
```

### halted_callback.action_controller

| キー       | 値                            |
| --------- | ----------------------------- |
| `:filter` | アクションを停止させたフィルタ      |

```ruby
{
  filter: ":halting_filter"
}
```

### unpermitted_parameters.action_controller

| キー     | 値               |
| ------- | ---------------- |
| `:keys` | 許可されていないキー |

Action Dispatch
---------------

### process_middleware.action_dispatch

| キー           | 値                     |
| ------------- | ---------------------- |
| `:middleware` | ミドルウェア名            |

Action View
-----------

### render_template.action_view

| キー           | 値                    |
| ------------- | --------------------- |
| `:identifier` | テンプレートへの完全なパス |
| `:layout`     | 該当のレイアウト         |


```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/index.html.erb",
  layout: "layouts/application"
}
```

### render_partial.action_view

| キー           | 値                    |
| ------------- | --------------------- |
| `:identifier` | テンプレートへの完全なパス |

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_form.html.erb"
}
```

### render_collection.action_view

| キー           | 値                                    |
| ------------- | ------------------------------------- |
| `:identifier` | テンプレートへのフルパス                   |
| `:count`      | コレクションのサイズ                      |
| `:cache_hits` | キャッシュからフェッチしたパーシャルの個数    |

`:cache_hits`は、`cached: true`をオンにしてレンダリングしたときだけ含まれます。

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_post.html.erb",
  count: 3,
  cache_hits: 0
}
```

Active Record
------------

### sql.active_record

| キー                  | 値                                          |
| -------------------- | ------------------------------------------- |
| `:sql`               | SQL文                                       |
| `:name`              | 操作の名前                                    |
| `:connection_id`     | コネクションオブジェクトのオブジェクトid           |
| `:binds`             | バインドするパラメータ                          |
| `:type_casted_binds` | 型キャストされたバインド                         |
| `:statement_name`    | SQL文の名前                                   |
| `:cached`            | キャッシュされたクエリが使われると`true`が追加される |

INFO. アダプタも独自のデータを追加します。

```ruby
{
  sql: "SELECT \"posts\".* FROM \"posts\" ",
  name: "Post Load",
  connection_id: 70307250813140,
  connection: #<ActiveRecord::ConnectionAdapters::SQLite3Adapter:0x00007f9f7a838850>,
  binds: [#<ActiveModel::Attribute::WithCastValue:0x00007fe19d15dc00>],
  type_casted_binds: [11],
  statement_name: nil
}
```

### instantiation.active_record

| キー              | 値                                        |
| ---------------- | ----------------------------------------- |
| `:record_count`  | レコードのインスタンス数                       |
| `:class_name`    | レコードのクラス                             |

```ruby
{
  record_count: 1,
  class_name: "User"
}
```

Action Mailer
-------------

### deliver.action_mailer

| キー                   | 値                                   |
| --------------------- | ------------------------------------ |
| `:mailer`             | メイラークラス名                        |
| `:message_id`         | Mail gemが生成したメッセージID           |
| `:subject`            | メールの件名                           |
| `:to`                 | メールの宛先                           |
| `:from`               | メールの差出人                          |
| `:bcc`                | メールのBCCアドレス                     |
| `:cc`                 | メールのCCアドレス                      |
| `:date`               | メールの日付                           |
| `:mail`               | メールのエンコード形式                   |
| `:perform_deliveries` | このメッセージが配信されたかどうか          |

```ruby
{
  mailer: "Notification",
  message_id: "4f5b5491f1774_181b23fc3d4434d38138e5@mba.local.mail",
  subject: "Rails Guides",
  to: ["users@rails.com", "dhh@rails.com"],
  from: ["me@rails.com"],
  date: Sat, 10 Mar 2012 14:18:09 +0100,
  mail: "...", # 省略
  perform_deliveries: true
}
```

### process.action_mailer

| キー           | 値                       |
| ------------- | ------------------------ |
| `:mailer`     | メイラーのクラス名           |
| `:action`     | アクション                 |
| `:args`       | 引数                      |

```ruby
{
  mailer: "Notification",
  action: "welcome_email",
  args: []
}
```

Active Support
--------------

### cache_read.active_support

| キー                | 値                                                |
| ------------------ | ------------------------------------------------- |
| `:key`             | ストアで使われるキー                                  |
| `:hit`             | ヒットしたかどうか                                    |
| `:super_operation` | 読み出しで`#fetch`が指定されている場合に:fetch を追加     |

### cache_generate.active_support

このイベントは、`#fetch`をブロック付きで使用した場合にのみ使われます。

| キー    | 値               |
| ------ | ---------------- |
| `:key` | ストアで使われるキー |

INFO. fetchに渡されたオプションは、ストアへの書き込み時にペイロードとマージされます。

```ruby
{
  key: 'name-of-complicated-computation'
}
```


### cache_fetch_hit.active_support

このイベントは、`#fetch`をブロック付きで使用した場合にのみ使われます。

| キー         | 値                    |
| ----------- | --------------------- |
| `:key`      | ストアで使われるキー      |

INFO. fetchに渡されたオプションは、ペイロードとマージされます。

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache_write.active_support

| キー         | 値                    |
| ----------- | --------------------- |
| `:key`      | ストアで使われるキー      |

INFO. キャッシュストアが独自のキーを追加することがあります。

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache_delete.active_support

| キー         | 値                    |
| ----------- | --------------------- |
| `:key`      | ストアで使われるキー      |

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache_exist?.active_support

| キー         | 値                    |
| ----------- | --------------------- |
| `:key`      | ストアで使われるキー      |

```ruby
{
  key: 'name-of-complicated-computation'
}
```

Active Job
--------

### enqueue_at.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |

### enqueue.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |

### enqueue_retry.active_job

| Key          | Value                                  |
| ------------ | -------------------------------------- |
| `:job`       | Jobオブジェクト                           |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:error`     | リトライの原因となったエラー                 |
| `:wait`      | リトライの遅延                            |

### perform_start.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |

### perform.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |

### retry_stopped.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |
| `:error`     | リトライの原因となったエラー                 |

### discard.active_job

| キー          | 値                                     |
| ------------ | -------------------------------------- |
| `:adapter`   | ジョブを処理するQueueAdapterオブジェクト     |
| `:job`       | Jobオブジェクト                           |
| `:error`     | リトライの原因となったエラー                 |

Action Cable
------------

### perform_action.action_cable

| キー              | 値                        |
| ---------------- | ------------------------- |
| `:channel_class` | チャネルのクラス名           |
| `:action`        | アクション                  |
| `:data`          | 日付（ハッシュ）             |

### transmit.action_cable

| キー              | 値                        |
| ---------------- | ------------------------- |
| `:channel_class` | チャネルのクラス名           |
| `:data`          | 日付（ハッシュ）             |
| `:via`           | 経由先                     |

### transmit_subscription_confirmation.action_cable

| キー              | 値                        |
| ---------------- | ------------------------- |
| `:channel_class` | チャネルのクラス名           |

### transmit_subscription_rejection.action_cable

| キー              | 値                        |
| ---------------- | ------------------------- |
| `:channel_class` | チャネルのクラス名           |

### broadcast.action_cable

| キー             | 値                   |
| --------------- | -------------------- |
| `:broadcasting` | 名前付きブロードキャスト  |
| `:message`      | メッセージ（ハッシュ）    |
| `:coder`        | コーダー               |

Active Storage
--------------

### service_upload.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |
| `:checksum`  | 完全性を担保するチェックサム    |

### service_streaming_download.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |

### service_download_chunk.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |
| `:range`     | 読み取り試行したバイトのレンジ  |

### service_download.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |

### service_delete.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |

### service_delete_prefixed.active_storage

| キー          | 値                        |
| ------------ | ------------------------- |
| `:key`       | セキュアトークン             |
| `:service`   | サービス名                  |

### service_exist.active_storage

| キー          | 値                         |
| ------------ | -------------------------- |
| `:key`       | セキュアトークン              |
| `:service`   | サービス名                   |
| `:exist`     | ファイルかblogが存在するかどうか |

### service_url.active_storage

| キー          | 値                         |
| ------------ | -------------------------- |
| `:key`       | セキュアトークン              |
| `:service`   | サービス名                   |
| `:url`       | 生成されたURL                |

### service_update_metadata.active_storage

| キー             | 値                                |
| --------------- | --------------------------------- |
| `:key`          | セキュアトークン                     |
| `:service`      | サービス名                          |
| `:content_type` | HTTP Content-Type フィールド        |
| `:disposition`  | HTTP Content-Disposition フィールド |

INFO. このフックを提供しているActiveStorageサービスは現在GCSのみです。

### preview.active_storage

| キー          | 値                         |
| ------------ | -------------------------- |
| `:key`       | セキュアトークン              |

Railties
--------

### load_config_initializer.railties

| キー            | 値                                                    |
| -------------- | ----------------------------------------------------- |
| `:initializer` | `config/initializers`から読み込まれたイニシャライザへのパス  |

Rails
-----

### deprecation.rails

| キー         | 値                               |
| ------------ | ------------------------------- |
| `:message`   | 非推奨機能の警告メッセージ           |
| `:callstack` | 非推奨警告の発生元                  |

イベントのサブスクライブ
-----------------------

イベントは簡単にサブスクライブできます。`ActiveSupport::Notifications.subscribe`をブロック付きで
記述すれば、すべての通知をリッスンできます。

ブロックでは以下の引数を利用できます。

* イベントの名前
* イベントの開始時刻
* イベントの終了時刻
* イベントのユニークID
* ペイロード（上の節を参照）

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, data|
  # 自分のコードをここに書く
  Rails.logger.info "#{name} Received!"
end
```

ブロックの引数を毎回定義しなくても済むよう、次のようなブロック付きの`ActiveSupport::Notifications::Event`を
簡単に定義できます。

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new *args

  event.name      # => "process_action.action_controller"
  event.duration  # => 10 (in milliseconds)
  event.payload   # => {:extra=>information}

  Rails.logger.info "#{event} Received!"
end
```

引数を1つだけ持つブロックを渡すこともできます。この場合そのブロックでイベントオブジェクトが`yield`されます。

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |event|
  event.name      # => "process_action.action_controller"
  event.duration  # => 10 (in milliseconds)
  event.payload   # => {:extra=>information}

  Rails.logger.info "#{event} Received!"
end
```

ほとんどの場合データ自体にしか関心がないものです。以下はデータだけを取り出すショートカットです。

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  data = args.extract_options!
  data # { extra: :information }
end
```

正規表現に一致するイベントだけをサブスクライブすることもできます。
さまざまなイベントを一括でサブスクライブしたい場合に便利です。次は、`ActionController`のイベントをすべて登録する場合の例です。

```ruby
ActiveSupport::Notifications.subscribe /action_controller/ do |*args|
  # ActionControllerの全イベントをチェック
end
```

カスタムイベントの作成
----------------------

独自のイベントを自由に追加できます。イベント追加は、`ActiveSupport::Notifications`メソッドで
すべてまかなえます。`name`、`payload`、ブロックを指定して`instrument`を呼び出すだけで追加完了します。
通知は、ブロックが戻ってから送信されます。`ActiveSupport`では、開始時刻、終了時刻、
ユニークIDが生成されます。`instrument`呼び出しに渡されるすべてのデータがペイロードに含まれます。

以下に例を示します。

```ruby
ActiveSupport::Notifications.instrument "my.custom.event", this: :data do
  # 自分のコードをここに書く
end
```

これで、次のようにイベントをリッスンできるようになります。

```ruby
ActiveSupport::Notifications.subscribe "my.custom.event" do |name, started, finished, unique_id, data|
  puts data.inspect # {:this=>:data}
end
```

次のようにブロックを渡さずにinstrumentを呼び出すこともできます。これはinstrumentationインフラストラクチャを他のメッセージングに使うのに便利です。

```ruby
ActiveSupport::Notifications.instrument "my.custom.event", this: :data

ActiveSupport::Notifications.subscribe "my.custom.event" do |name, started, finished, unique_id, data|
  puts data.inspect # {:this=>:data}
end
```

独自のイベントを作成するときは、Railsの規則に従ってください。形式は「`event.library`」を使います
たとえば、アプリケーションがツイートを送信するのであれば、イベント名は`tweet.twitter`となります。
