
Rails と Rack
=============

このガイドでは、RailsとRackの関係、Railsと他のRackコンポーネントとの関係について説明します。

このガイドの内容:

* RackのミドルウェアをRailsで使う方法
* Action Pack内のミドルウェアスタックについて
* 独自のミドルウェアスタックを定義する方法

--------------------------------------------------------------------------------

WARNING: このガイドはRackのミドルウェア、urlマップ、`Rack::Builder`といったRackのプロトコルや概念に関する実用的な知識を身につけていることを前提にしています。

Rack入門
--------------------

Rackは、RubyのWebアプリケーションに対して、モジュール化された最小限のインターフェイスを提供して、インターフェイスを広範囲に使えるようにします。RackはHTTPリクエストとレスポンスを可能なかぎり簡単な方法でラッピングすることで、Webサーバー、Webフレームワーク、その間に位置するソフトウェア (ミドルウェアと呼ばれています) のAPIを1つのメソッド呼び出しの形にまとめます。

Rackに関する解説はこのガイドの範疇を超えてしまいます。Rackに関する基本的な知識が不足している場合は、下記の[リソース](#参考資料) を参照してください。

RailsとRack
-------------

### RailsアプリケーションのRackオブジェクト

`Rails.application`は、Railsアプリケーションにおける主要なRackアプリケーションです。Rackに準拠したWebサーバーで、Railsアプリケーションを提供するには、`Rails.application`オブジェクトを使う必要があります。

### `rails server`コマンド

`rails server`コマンドは、`Rack::Server`のオブジェクトを作成し、Webサーバーを起動します。

`rails server`コマンドは、以下のように`Rack::Server`のオブジェクトを作成します。

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server`クラスは`Rack::Server`クラスを継承しており、以下のように`Rack::Server#start`を呼び出します。

```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

### `rackup`コマンド

Railsの`rails server`コマンドの代わりに`rackup`コマンドを使うときは、以下の内容を`config.ru`に記述して、Railsアプリケーションのルートディレクトリに保存します。

```ruby
# Rails.root/config.ru
require_relative 'config/environment'
run Rails.application
```

続いて、サーバーを起動します。

```bash
$ rackup config.ru
```

`rackup`の他のオプションについて詳しく知りたいときは、以下を実行します。

```bash
$ rackup --help
```

### 開発中の自動再読み込みについて

一度読み込まれたミドルウェアは、変更が発生しても検出されません。現在実行中のアプリケーションでミドルウェアの変更を反映するには、サーバーの再起動が必要です。

Action Dispatcherのミドルウェアスタック
----------------------------------

Action Dispatcher内部のコンポーネントの多くは、「Rackミドルウェア」として実装されています。`Rails::Application`は、`ActionDispatch::MiddlewareStack`を用いて内部ミドルウェアや外部ミドルウェアを組み合わせることで、完全なRailsのRackアプリケーションを構築します。

NOTE: Railsの`ActionDispatch::MiddlewareStack`クラスは`Rack::Builder`クラスと同等ですが、Railsアプリケーションの要求を満たすために柔軟性が高く多機能です。

### ミドルウェアスタックを調べる

Railsには、ミドルウェアスタックを調べるための便利なタスクがあります。

```bash
$ bin/rails middleware
```

作成直後のRailsアプリケーションでは、以下のように出力されるはずです。

  ```ruby
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use ActionDispatch::RemoteIp
use Sprockets::Rails::QuietAssets
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use WebConsole::Middleware
use ActionDispatch::DebugExceptions
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ContentSecurityPolicy::Middleware
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
use Rack::TempfileReaper
run MyApp::Application.routes
```

デフォルトのミドルウェアを含むいくつかのミドルウェアの概要については、[ミドルウェアスタックの内容](#ミドルウェアスタックの内容)を参照してください。

### ミドルウェアスタックを設定する

Railsが提供するシンプルな`config.middleware`を用いることで、ミドルウェアスタックにミドルウェアを追加・削除・変更できます。これは`application.rb`設定ファイルで行うことも、環境ごとの`environments/<環境名>.rb`設定ファイルで行うこともできます。

#### ミドルウェアを追加する

次のメソッドを使うと、ミドルウェアスタックに新しいミドルウェアを追加できます。

* `config.middleware.use(new_middleware, args)`: ミドルウェアスタックの末尾に新しいミドルウェアを追加します。

* `config.middleware.insert_before(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、(第1引数で)指定された既存のミドルウェアの直前に追加します。

* `config.middleware.insert_after(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、(第1引数で)指定された既存のミドルウェアの直後に追加します。

```ruby
# config/application.rb

# Rack::BounceFaviconを末尾に追加する
config.middleware.use Rack::BounceFavicon

# ActionDispatch::Executorの直後にLifo::Cacheを追加する
# Lifo::Cacheに引数{ page_cache: false }を渡す
config.middleware.insert_after ActionDispatch::Executor, Lifo::Cache, page_cache: false
```

#### ミドルウェアを置き換える

`config.middleware.swap`を使って、ミドルウェアスタック内にあるミドルウェアを置き換えられます。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsで置き換える
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### ミドルウェアを削除する

アプリの設定に下記のコードを追加します。

```ruby
# config/application.rb
config.middleware.delete Rack::Runtime
```

ミドルウェアスタックを調べると、`Rack::Runtime`が消えていることが分かります。

```bash
$ bin/rails middleware
(in /Users/lifo/Rails/blog)
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000001c304c8>
...
run Rails.application.routes
```

セッション関連のミドルウェアを削除するには、次のように書きます。

```ruby
# config/application.rb
config.middleware.delete ActionDispatch::Cookies
config.middleware.delete ActionDispatch::Session::CookieStore
config.middleware.delete ActionDispatch::Flash
```

ブラウザ関連のミドルウェアを削除するには次のように書きます。

```ruby
# config/application.rb
config.middleware.delete Rack::MethodOverride
```

### ミドルウェアスタックの内部

Action Controllerの機能の多くはミドルウェアとして実装されています。それぞれの役割について以下のリストで説明します。

**`Rack::Sendfile`**

* X-Sendfile headerを設定します。`config.action_dispatch.x_sendfile_header`オプション経由で設定を変更できます。

**`ActionDispatch::Static`**

* 静的ファイルの配信に使います。`config.public_file_server.enabled`を`false`にするとオフになります。

**`Rack::Lock`**

* `env["rack.multithread"]`を`false`に設定し、アプリケーションをMutexでラップします。

**`ActionDispatch::Executor`**

* スレッドセーフのコードを開発中にリロードするときに使います。

**`ActiveSupport::Cache::Strategy::LocalCache::Middleware`**

* メモリキャッシュで用います。このキャッシュはスレッドセーフではありません。

**`Rack::Runtime`**

* X-Runtimeヘッダーを生成します。このヘッダーにはリクエストの処理にかかった時間が秒単位で表示されます。

**`Rack::MethodOverride`**

* `params[:_method]`が設定されている場合に（HTTP）メソッドが上書きされるようになります。HTTPのPUTメソッド、DELETEメソッドを実現するためのミドルウェアです。

**`ActionDispatch::RequestId`**

* レスポンスで`X-Request-Id`ヘッダーを有効にして`ActionDispatch::Request#request_id`メソッドが使えるようにします。

**`ActionDispatch::RemoteIp`**

* IPスプーフィング攻撃をチェックします。

**`Sprockets::Rails::QuietAssets`**

* アセットリクエストでのログ書き出しを抑制します。

**`ActionDispatch::RemoteIp`**

* IPスプーフィング攻撃をチェックします。

**`Rails::Rack::Logger`**

* リクエストの処理が開始されたことをログに出力します。リクエストが完了すると、すべてのログをフラッシュします。

**`ActionDispatch::ShowExceptions`**

* アプリケーションが返すすべての例外をrescueし、例外処理用アプリケーション （エンドユーザー向けに例外を整形するアプリケーション） を起動します。

**`ActionDispatch::DebugExceptions`**

* 例外をログに出力します。ローカルからのリクエストの場合は、デバッグ用ページも表示します。

**`ActionDispatch::Reloader`**

* development環境でコードの再読み込みを行うために、prepareコールバックとcleanupコールバックを提供します。

**`ActionDispatch::Callbacks`**

* リクエストをディスパッチする直前および直後に実行されるコールバックを提供します。

**`ActiveRecord::Migration::CheckPending`**

* 未実行のマイグレーションがないか確認します。未実行のものがあった場合は、`ActiveRecord::PendingMigrationError`を発生させます。

**`ActionDispatch::Cookies`**

* cookie機能を提供します。

**`ActionDispatch::Session::CookieStore`**

* セッションをcookieに保存する役割を担当します。

**`ActionDispatch::Flash`**

* flashのキーをセットアップします(訳注: flashは連続するリクエスト間でメッセージを共有表示する機能です)。これは、`config.action_controller.session_store`に値が設定されている場合にのみ有効です。

**`ActionDispatch::ContentSecurityPolicy::Middleware`**

* Content-Security-Policyヘッダー設定用のDSLを提供します。

**`ActionDispatch::Head`**

* HEADリクエストを`GET`に変換して処理します。その上でbodyを空にしたレスポンスを返します(訳注: Rails4.0からはRack::Headを使うように変更されています)。

**`Rack::Head`**

* `HEAD`リクエストを`GET`に変換し、`GET`として処理します。

**`Rack::ConditionalGet`**

* 「条件付き`GET`（Conditional `GET`）」機能を提供します。"条件付き `GET`"が有効になっていると、リクエストされたページで変更が発生していない場合に空のbodyを返します。

**`Rack::ETag`**

* bodyが文字列のみのレスポンスにETagヘッダを追加します。ETagはキャッシュのバリデーションに使われます。

**`Rack::TempfileReaper`**

* マルチパートリクエストをバッファするのに使われる一時ファイルをクリーンアップします。

TIP: これらのミドルウェアはいずれも、独自のRackスタックに利用することもできます。

参考資料
---------

### Rackについて詳しく学ぶ

* [Rack公式サイト](https://rack.github.io)
* [Rack入門](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)

### ミドルウェアを理解する

* [Railscast on Rack Middlewares](http://railscasts.com/episodes/151-rack-middleware)
