
Rails と Rack
=============

このガイドでは、RailsとRackの関係、Railsと他のRackコンポーネントとの関係について説明します。

このガイドの内容:

* RackのミドルウェアをRailsで使う方法
* Action Pack内のミドルウェアスタックについて
* 独自のミドルウェアスタックを定義する方法

--------------------------------------------------------------------------------

WARNING: このガイドはRackのミドルウェア、urlマップ、`Rack::Builder`といったRackのプロトコルや概念に関する実用的な知識があることを前提にしています。

Rack入門
--------------------

Rackは、Rubyのウェブアプリケーションに対して、最小限でモジュール化されていて、応用の効くインターフェイスを提供します。RackはHTTPリクエストとレスポンスを可能なかぎり簡単な方法でラッピングすることで、ウェブサーバー、ウェブフレームワーク、その間に位置するソフトウェア (ミドルウェアと呼ばれています) のAPIを一つのメソッド呼び出しの形にまとめます。

Rackに関する解説はこのガイドの範疇を超えてしまいます。Rackに関する基本的な知識が足らない場合、下記の[リソース](#参考資料) を参照してください。

RailsとRack
-------------

### RackアプリケーションとしてのRailsアプリケーション

`Rails.application`はRailsアプリケーションをRackアプリケーションとして実装したものです。Rackに準拠したWebサーバーで、Railsアプリケーションを提供するには、`Rails.application`オブジェクトを使用する必要があります。

### `rails server`コマンド

`rails server`コマンドは`Rack::Server`のオブジェクトを作成し、ウェブサーバーを起動します。

`rails server`コマンドは以下のようにして、`Rack::Server`のオブジェクトを作成します。

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server`クラスは`Rack::Server`クラスを継承しており、以下のようにして`Rack::Server#start`を呼び出します。

```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

### `rackup`コマンド

Railsの`rails server`コマンドの代わりに`rackup`コマンドを使用するときは、下記の内容を`config.ru`に記述して、Railsアプリケーションのルートディレクトリに保存します。

```ruby
# Rails.root/config.ru
require_relative 'config/environment'
run Rails.application
```

サーバーを起動します。

```bash
$ rackup config.ru
```

`rackup`のオプションについて詳しく知りたいときは下記のようにします。

```bash
$ rackup --help
```

Action Dispatcherのミドルウェアスタック
----------------------------------

Action Dispatcher内部のコンポーネントの多くは、Rackのミドルウェアとして実装されています。Rails内外の様々なミドルウェアを結合して、完全なRailsのRackアプリケーションを作るために、`Rails::Application`は`ActionDispatch::MiddlewareStack`を使用しています。

NOTE: `ActionDispatch::MiddlewareStack`は`Rack::Builder`のRails版ですが、Railsアプリケーションの要求を満たすために、より柔軟性があり、多機能なクラスになっています。

### ミドルウェアスタックを調べる

Railsにはミドルウェアスタックを調べるための便利なタスクがあります。

```bash
$ bin/rails middleware
```

作成したばかりのRailsアプリケーションでは、以下のように出力されるはずです。

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
run Rails.application.routes
```

デフォルトのミドルウェア(とその他のうちいくつか)については[ミドルウェアスタックの内容](#ミドルウェアスタックの内容) を参照してください。

### ミドルウェアスタックを設定する

ミドルウェアスタックにミドルウェアを追加したり、削除したり、変更したりするには`application.rb`もしくは環境ごとの`environments/<environment>.rb`ファイル内で`config.middleware`をいじります。

#### ミドルウェアを追加する

次のメソッドを使用すると、ミドルウェアスタックに新しいミドルウェアを追加することができます。

* `config.middleware.use(new_middleware, args)` - ミドルウェアスタックの一番下に新しいミドルウェアを追加します。

* `config.middleware.insert_before(existing_middleware, new_middleware, args)` - (第一引数で)指定されたミドルウェアの前に新しいミドルウェアを追加します。

* `config.middleware.insert_after(existing_middleware, new_middleware, args)` - (第一引数で)指定されたミドルウェアの後に新しいミドルウェアを追加します。

```ruby
# config/application.rb

# Rack::BounceFaviconを一番最後に追加する
config.middleware.use Rack::BounceFavicon

# ActionDispatch::Executorの後にLifo::Cacheを追加する
# またLifo::Cacheに{ page_cache: false }を渡す
config.middleware.insert_after ActionDispatch::Executor, Lifo::Cache, page_cache: false
```

#### ミドルウェアを交換する

`config.middleware.swap`を使用することで、ミドルウェアスタック内のミドルウェアを交換できます。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsで置き換える
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### ミドルウェアを削除する

アプリケーションの設定に、下記のコードを追加してください。

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

セッション関連のミドルウェアを削除したいときは次のように書きます。

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

### ミドルウェアスタックの内容

Action Controllerの機能の多くはミドルウェアとして実装されています。以下のリストでそれぞれの役割を説明します。

**`Rack::Sendfile`**

* X-Sendfile headerを設定します。`config.action_dispatch.x_sendfile_header`オプション経由で設定を変更できます。

**`ActionDispatch::Static`**

* 静的ファイルを配信する際に使用します。`config.public_file_server.enabled`を`false`にするとオフになります。

**`Rack::Lock`**

* `env["rack.multithread"]`を`false`に設定し、アプリケーションをMutexで包みます。

**`ActionDispatch::Executor`**

* 開発中にスレッドセーフのコードをリロードするのに使います。

**`ActiveSupport::Cache::Strategy::LocalCache::Middleware`**

* メモリによるキャッシュを行うために使用します。このキャッシュはスレッドセーフではありません。

**`Rack::Runtime`**

* X-Runtimeヘッダーを生成します。このヘッダーにはリクエストの処理にかかった時間が秒単位で表示されます。

**`Rack::MethodOverride`**

* `params[:_method]`が存在するときに、(HTTPの)メソッドを上書きます。HTTPのPUTメソッド、DELETEメソッドを実現するためのミドルウェアです。

**`ActionDispatch::RequestId`**

* ユニークなidを生成して`X-Request-Id`ヘッダーに設定します。`ActionDispatch::Request#request_id`メソッドも同一のidを利用しています。

**`ActionDispatch::RemoteIp`**

* IPスプーフィング攻撃をチェックします。

**`Sprockets::Rails::QuietAssets`**

* アセットリクエストでのログ書き出しを抑制します。

**`ActionDispatch::RemoteIp`**

* IPスプーフィング攻撃をチェックします。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/191714ea977bb6c5c6f19fb2f4da93be616df2b3#r27174670
-->

**`Rails::Rack::Logger`**

* リクエストの処理を開始したことを、ログに書き出します。リクエストが完了すると、すべてのログをフラッシュします。

**`ActionDispatch::ShowExceptions`**

* アプリケーションが返してくる例外を捕え、例外処理用のアプリケーションを起動します。例外処理用のアプリケーションは、エンドユーザー向けに例外を整形します。

**`ActionDispatch::DebugExceptions`**

* 例外をログに残し、ローカルからのリクエストの場合は、デバッグ用のページを表示します。

**`ActionDispatch::Reloader`**

* development環境でコードの再読み込みを行うために、prepareコールバックとcleanupコールバックを提供します。

**`ActionDispatch::Callbacks`**

* リクエストの処理を開始する前に、prepareコールバックを起動します(訳注: この説明は原文レベルで間違っており、現在原文の修正を行っています)。

**`ActiveRecord::Migration::CheckPending`**

* 未実行のマイグレーションがないか確認します。未実行のものがあった場合は、`ActiveRecord::PendingMigrationError`を発生さます。

**`ActionDispatch::Cookies`**

* クッキー機能を提供します。

**`ActionDispatch::Session::CookieStore`**

* クッキーにセッションを保存するようにします。

**`ActionDispatch::Flash`**

* flash機能を提供します(flashとは連続するリクエスト間で値を共有する機能です)。これは、`config.action_controller.session_store`に値が設定されている場合にのみ有効です。

**`ActionDispatch::Head`**

* HEADリクエストを`GET`に変換して処理します。その上でbodyを空にしたレスポンスを返します(訳注: Rails4.0からはRack::Headを使うように変更されています)。

**`Rack::ConditionalGet`**

* "条件付き `GET`" (Conditional `GET`) 機能を提供します。"条件付き `GET`"が有効になっていると、リクエストされたページに変更がないときに空のbodyを返すようになります。

**`Rack::ETag`**

* bodyが文字列のみのレスポンスに対して、ETagヘッダを追加します。 ETagはキャッシュの有効性を検証するのに使用されます。

TIP: これらのミドルウェアはいずれも、Rackのミドルウェアスタックに利用できます。

参考資料
---------

### Rackについて詳しく学ぶ

* [Rack公式サイト](https://rack.github.io)
* [Rack入門](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)

### ミドルウェアを理解する

* [Railscast on Rack Middlewares](http://railscasts.com/episodes/151-rack-middleware)
