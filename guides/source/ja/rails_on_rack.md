Rails と Rack
=============

本ガイドでは、Railsと[Rack][]の統合について説明します。

このガイドの内容:

* Rackとは何か、RailsでRackが使われている理由
* RailsがRackミドルウェアでアプリケーションスタックを構築するしくみ
* Action Packの内部ミドルウェアスタック
* ミドルウェアスタックの設定と変更方法
* Railsコントローラから利用できる、基盤となるRack API

--------------------------------------------------------------------------------

Rackについて
--------------------

Rackは、RubyでWebアプリケーションを開発するためのモジュール式インターフェイスを提供します。
HTTPリクエストとレスポンスをRackの規約に沿った構造でラップすることで、Webサーバー、Webフレームワーク、およびその間のソフトウェア（ミドルウェアと呼ばれます）のAPIを単一のメソッド呼び出しに統合します。

このしくみにより、[Puma][]や[Falcon][]などのRack準拠のWebサーバーを、RailsなどのRackベースのWebフレームワークで自由に差し替えられます。

RailsとRackの統合について詳しく知る前に、Rack自体について見てみましょう。

### 基本的なRackアプリケーション

Rackアプリケーションは、`call`メソッドを実装するオブジェクトです。`call`メソッドには、Rack環境として知られる[`env`][]ハッシュを渡します。

以下は、最小限のRackアプリケーションの例です。

```ruby
class App
  def call(env)
    [200, { "content-type" => "text/plain" }, ["Hello World"]]
  end
end

run App.new
```

HTTPリクエストを受け取ると、Rack準拠のWebサーバーがリクエストを解析して`env`ハッシュを作成し、この`env`を渡してRackアプリケーションを呼び出します。
`call`メソッドが返す配列は、HTTPレスポンスを表す以下の3つの要素のみを含んでいなければなりません。

1. HTTPレスポンスコード（上の例では`200`）
2. 送信するHTTPレスポンスヘッダを含むハッシュ
3. enumerableオブジェクト（レスポンスのbodyを表す文字列を返す）

Rackアプリケーションは、一般的にWebサーバーのコマンドラインプログラムで実行されます。
また、Rackアプリケーションのエントリポイントは`config.ru`ファイルに格納されます。

```bash
$ cat > config.ru << APP
rack_app = lambda do |env|
  [200, { "content-type" => "text/plain" }, ["Hello World"]]
end
run rack_app
APP
$ gem install puma
$ puma
```

上のシェルコマンドを実行すると、Rackアプリが作成されて`http://localhost:9292`で起動します。
以下のコマンドで動作を確認できます。

```bash
$ curl localhost:9292
Hello World
```

[Rack]:
  https://en.wikipedia.org/wiki/Rack_(web_server_interface)
[Puma]:
  https://puma.io
[Falcon]:
  https://socketry.github.io/falcon/
[`env`]:
  https://github.com/rack/rack/blob/main/SPEC.rdoc#the-request-environment

### Rackミドルウェア

Rackアプリケーションは、**ミドルウェア**（middleware）でラップできます。ミドルウェアは、リクエストがメインのアプリケーションに到達する直前と、メインのアプリケーションがリクエストに対してレスポンスを返した直後のどちらでも操作を実行できます。

ミドルウェアは通常、ログ出力、キャッシュ、認証、パフォーマンス計測などのタスクに利用されます。

Rackミドルウェアは、Rackアプリケーションと、ミドルウェアを設定するための任意の引数を受け取る`new`メソッドを必ず持つ必要があります。`new`メソッドは、`call`に応答するRackアプリケーションを返す必要があります。

Rackミドルウェアはクラスとして書かれるのが普通で、ミドルウェアの各インスタンスは関連するアプリケーションへのアクセスをラップします。

```ruby
class MyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # リクエストがメインのアプリケーションに到達する直前の操作はここで行う
    # -------------------------------------------------------

    # ミドルウェアスタックの下流にリクエストを伝播させる
    status, headers, body = @app.call(env)

    # ---------------------------------------
    # リクエストがアプリケーションから返された後の操作はここで行う

    # ミドルウェアスタックの上流にレスポンスを伝播させる
    [status, headers, body]
  end
end
```

ミドルウェアは、必要に応じて`@app.call`を完全にスキップして自分自身でレスポンスを返すことで、ミドルウェアスタックの処理を打ち切る（ショートサーキット）ことが可能です。この場合、リクエストはメインのアプリケーションやスタック内の残りのミドルウェアに到達しなくなります。

リクエスト認証用のミドルウェアは、ショートサーキットを利用する場合があります。

```ruby
class AuthenticateRequest
  def initialize(app)
    @app = app
  end

  def call(env)
    if authenticated?(env["HTTP_AUTHORIZATION"])
      @app.call(env)
    else
      [401, { "content-type" => "text/plain" }, ["Authentication failed"]]
    end
  end

  def authenticated?(token)
    # ...
  end
end
```

Rackアプリにミドルウェアを追加するには、`use`を使います。

```ruby
class AuthenticateRequest
  # ...
end

class App
  def call(env)
    [200, { "content-type" => "text/plain" }, ["Hello World"]]
  end
end

use AuthenticateRequest
run App.new
```

Rackアプリケーションを構築するためのこのようなDSLは、[`Rack::Builder`][]によって提供されます。Rackについて詳しくは、[Rackの仕様][rack_spec]および[RackのWebサイト][rack_website]を参照してください。

[`Rack::Builder`]:
  https://rack.github.io/rack/3.2/Rack/Builder.html
[rack_spec]:
  https://rack.github.io/rack/main/SPEC_rdoc.html
[rack_website]:
  https://rack.github.io/rack/

RailsとRack
-------------

### Railsの主要なRackオブジェクト

`Rails.application`は、Railsアプリケーションにおける**主要なRackアプリケーションオブジェクト**です。
Rack準拠のWebサーバーは、Railsアプリケーションを提供するために`Rails.application`オブジェクトを使う必要があります。

### Railsサーバーを起動する

Railsは、`Rackup::Server`をサブクラス化する形で`Rails::Server`を作成します。
`bin/rails server`コマンドを実行すると、`Rails::Server`オブジェクトがインスタンス化されてWebサーバーが起動します。

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

サーバーの起動方法について詳しくは、[Railsの初期化プロセスガイド](initialization.html#rails-server-start)を参照してください。

Action Dispatchのミドルウェアスタック
--------------------------------

`ActionDispatch::MiddlewareStack`は、Railsの[`Rack::Builder`][]に相当します。Railsの要件を満たすために、より柔軟で多くの機能を備えています。

`Rails::Application`オブジェクトは、この`ActionDispatch::MiddlewareStack`を使って内部ミドルウェアと外部ミドルウェアを組み合わせ、Railsを使った完全なRackアプリケーションを構築します。

### ミドルウェアスタックを調べる

ミドルウェアスタックを表示するには、以下のコマンドを実行します。

```bash
$ bin/rails middleware
```

以下は、作成直後のRailsアプリケーションで表示されたミドルウェアスタックの例です。

```ruby
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use Propshaft::Server
use ActionDispatch::Executor
use ActionDispatch::ServerTiming
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use ActionDispatch::RemoteIp
use Propshaft::QuietAssets
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use WebConsole::Middleware
use ActionDispatch::DebugExceptions
use ActionDispatch::ActionableExceptions
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

上に示したデフォルトのミドルウェアの概要については、後述の[内部ミドルウェアスタック](#内部ミドルウェアスタック)を参照してください。

### ミドルウェアスタックを設定する

Railsが提供する[`config.middleware`][]設定インターフェイスを用いることで、ミドルウェアスタックのミドルウェアを追加・削除・変更できます。これは`application.rb`設定ファイルで行うことも、環境ごとの`environments/<環境名>.rb`設定ファイルで行うことも可能です。

[`config.middleware`]:
  https://api.rubyonrails.org/classes/Rails/Configuration/MiddlewareStackProxy.html

#### ミドルウェアを追加する

ミドルウェアスタックに新しいミドルウェアを追加するには、以下の3つのメソッドが利用できます。

* `config.middleware.use(new_middleware, args)`: ミドルウェアスタックの末尾に新しいミドルウェアを追加します。

* `config.middleware.insert_before(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、（第1引数で）指定された既存のミドルウェアの直前に追加します。

* `config.middleware.insert_after(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、（第1引数で）指定された既存のミドルウェアの直後に追加します。

利用例:

```ruby
# config/application.rb

# `Rack::BounceFavicon`を末尾に追加する
config.middleware.use Rack::BounceFavicon

# `ActionDispatch::Executor`の直後に`Lifo::Cache`を追加する。
# `Lifo::Cache`に`{ page_cache: false }`引数を渡す。
config.middleware.insert_after ActionDispatch::Executor, Lifo::Cache, page_cache: false
```

#### ミドルウェアを差し替える

`config.middleware.swap`を使って、ミドルウェアスタック内にあるミドルウェアを置き換えられます。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsで置き換える
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### ミドルウェアを移動する

ミドルウェアスタック内の既存のミドルウェアを移動して順序を変更するには、`config.middleware.move_before`や`config.middleware.move_after`を使います。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsの直前に移動する
config.middleware.move_before Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsの直後に移動する
config.middleware.move_after Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

#### ミドルウェアを削除する

`config.middleware.delete`を使ってミドルウェアを削除します。

```ruby
# config/application.rb
config.middleware.delete Rack::Runtime
```

`delete!`を使うと、指定したミドルウェアが存在しない場合にエラーが発生します。

```ruby
# config/application.rb

config.middleware.delete! Some::NonExistentMiddleware
```

### ミドルウェアスタックを再読み込みする

ミドルウェアスタックが一度読み込まれると、以後の変更は監視されません。
ミドルウェアスタックに変更を加えた場合は、サーバーを再起動してください。

### 内部ミドルウェアスタック

Action Controllerの機能の多くはミドルウェアとして実装されています。

それぞれのミドルウェアの目的について以下で説明します。

#### `ActionDispatch::ActionableExceptions`

[`ActionDispatch::ActionableExceptions`][]ミドルウェアは、リクエストがローカルの場合に、Railsのエラーページからアクションをディスパッチする方法を提供します。

[`ActionDispatch::ActionableExceptions`]:
  https://api.rubyonrails.org/files/actionpack/lib/action_dispatch/middleware/actionable_exceptions_rb.html

#### `ActionDispatch::Callbacks`

[`ActionDispatch::Callbacks`][]ミドルウェアは、リクエストのディスパッチ前後に実行されるコールバックを提供します。

[`ActionDispatch::Callbacks`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Callbacks.html

#### `ActionDispatch::ContentSecurityPolicy::Middleware`

[`ActionDispatch::ContentSecurityPolicy::Middleware`][]ミドルウェアは、`Content-Security-Policy`ヘッダを設定するためのDSLを提供します。詳しくは[セキュリティガイド](security.html#content-security-policy-header)を参照してください。

[`ActionDispatch::ContentSecurityPolicy::Middleware`]:
  https://api.rubyonrails.org/classes/ActionDispatch/ContentSecurityPolicy/Middleware.html

#### `ActionDispatch::Cookies`

[`ActionDispatch::Cookies`][]ミドルウェアは、リクエストからCookieデータを読み取り、レスポンスにCookieデータを書き込みます。

[`ActionDispatch::Cookies`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html

#### `ActionDispatch::DebugExceptions`

[`ActionDispatch::DebugExceptions`][]ミドルウェアは、例外をログに記録し、リクエストがローカルの場合にデバッグ用のページを表示します。

[`ActionDispatch::DebugExceptions`]:
  https://api.rubyonrails.org/classes/ActionDispatch/DebugExceptions.html

#### `ActionDispatch::Executor`

[`ActionDispatch::Executor`][]ミドルウェアは、development環境でコードがスレッドセーフで再読み込みされることを保証します。

[`ActionDispatch::Executor`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Executor.html

#### `ActionDispatch::Flash`

[`ActionDispatch::Flash`][]ミドルウェアは、flashのキーを設定します。[`config.session_store`][]に何らかの値が設定されている場合にのみ利用可能です。

[`ActionDispatch::Flash`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Flash.html
[`config.session_store`]:
  configuring.html#config-session-store

#### `ActionDispatch::HostAuthorization`

[`ActionDispatch::HostAuthorization`][]ミドルウェアは、DNSリバインディング攻撃を防ぐために、リクエストの送信先として許可されるホストを制限します。設定方法については[設定ガイド](configuring.html#actiondispatch-hostauthorization)を参照してください。

[`ActionDispatch::HostAuthorization`]:
  https://api.rubyonrails.org/classes/ActionDispatch/HostAuthorization.html

#### `ActionDispatch::Reloader`

[`ActionDispatch::Reloader`][]ミドルウェアは、development環境でのコード自動再読み込みを支援するために、prepareコールバックとcleanupコールバックを提供します。

[`ActionDispatch::Reloader`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Reloader.html

#### `ActionDispatch::RemoteIp`

[`ActionDispatch::RemoteIp`][]ミドルウェアは、IPスプーフィング攻撃をチェックします。

[`ActionDispatch::RemoteIp`]:
  https://api.rubyonrails.org/classes/ActionDispatch/RemoteIp.html

#### `ActionDispatch::RequestId`

[`ActionDispatch::RequestId`][]ミドルウェアは、リクエストに一意の`X-Request-Id`ヘッダを設定し、`ActionDispatch::Request#request_id`メソッドを利用可能にします。

一意のリクエストIDは、リクエストのエンドツーエンドのトラッキングに利用できます。
通常は、スタックを構成する複数のコンポーネントのログファイルに記録されます。

[`ActionDispatch::RequestId`]:
  https://api.rubyonrails.org/classes/ActionDispatch/RequestId.html

#### `ActionDispatch::ServerTiming`

[`ActionDispatch::ServerTiming`][]ミドルウェアは、リクエストのパフォーマンス指標を含む[`Server-Timing`][]ヘッダを設定します。

[`Server-Timing`]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Reference/Headers/Server-Timing
[`ActionDispatch::ServerTiming`]:
  https://api.rubyonrails.org/classes/ActionDispatch/ServerTiming.html

#### `ActionDispatch::Session::CookieStore`

[`ActionDispatch::Session::CookieStore`][]ミドルウェアは、セッションをCookieに保存する役割を担当します。

[`ActionDispatch::Session::CookieStore`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html

#### `ActionDispatch::ShowExceptions`

[`ActionDispatch::ShowExceptions`][]ミドルウェアは、アプリケーションから返された例外をキャッチし、エンドユーザー向けの形式でラップする例外アプリを呼び出します。

[`ActionDispatch::ShowExceptions`]:
  https://api.rubyonrails.org/classes/ActionDispatch/ShowExceptions.html

#### `ActionDispatch::Static`

[`ActionDispatch::Static`][]ミドルウェアは、`public`フォルダの静的ファイルを配信します。
[`config.public_file_server.enabled`][]が`false`の場合は無効化されます。

[`ActionDispatch::Static`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Static.html
[`config.public_file_server.enabled`]:
  configuring.html#config-public-file-server-enabled

#### `ActiveRecord::Migration::CheckPending`

<!-- 以下は原文エラー https://github.com/rails/rails/pull/58969 先行修正。-->

[`ActiveRecord::Migration::CheckPending`][]ミドルウェアは、保留中のマイグレーションをチェックし、保留中のマイグレーションがある場合は`ActiveRecord::PendingMigrationError`を発生させます。
[`config.active_record.migration_error`][]が`:page_load`に設定されている場合にのみ有効です。

[`config.active_record.migration_error`]:
  configuring.html#active-record-migration-error

[`ActiveRecord::Migration::CheckPending`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Migration/CheckPending.html

#### `ActiveSupport::Cache::Strategy::LocalCache::Middleware`

[`ActiveSupport::Cache::Strategy::LocalCache::Middleware`][]ミドルウェアは、インメモリのローカルキャッシュ用のミドルウェアです。このキャッシュはスレッドセーフではなく、単一のスレッドの一時的なメモリキャッシュとしてのみ使われます。

[`ActiveSupport::Cache::Strategy::LocalCache::Middleware`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Cache/Strategy/LocalCache.html

#### `Propshaft::QuietAssets`

[`Propshaft::QuietAssets`][]ミドルウェアは、アセットリクエストのログ出力を抑制します。

[`Propshaft::QuietAssets`]:
  https://github.com/rails/propshaft/blob/main/lib/propshaft/quiet_assets.rb

#### `Rack::ConditionalGet`

[`Rack::ConditionalGet`][]ミドルウェアは、if-none-matchおよびif-modified-sinceによる「条件付き`GET`」リクエストを処理します。
リクエストされたページが変更されていない場合、`304 Not Modified`を返し、bodyは空になります。

[`Rack::ConditionalGet`]:
  https://rack.github.io/rack/3.2/Rack/ConditionalGet.html

#### `Rack::ETag`

[`Rack::ETag`][]ミドルウェアは、すべての文字列bodyに`ETag`ヘッダを追加します。ETagはキャッシュのバリデーションに使われ、上記の「条件付き`GET`」リクエストで利用されます。
詳しくは[キャッシュのガイド](caching_with_rails.html#条件付きget)を参照してください。

[`Rack::ETag`]:
  https://rack.github.io/rack/3.2/Rack/ETag.html

#### `Rack::Head`

[`Rack::Head`][]ミドルウェアは、すべての`HEAD`リクエストに対して空のbodyを返します。それ以外のリクエストは変更されません。

[`Rack::Head`]:
  https://rack.github.io/rack/3.2/Rack/Head.html

#### `Rack::Lock`

[`Rack::Lock`][]ミドルウェアは、すべてのリクエストをミューテックス内でロックするため、すべてのリクエストは実質的に同期的に実行されます。

[`Rack::Lock`]:
  https://rack.github.io/rack/3.2/Rack/Lock.html

#### `Rack::MethodOverride`

[`Rack::MethodOverride`][]ミドルウェアは、`params[:_method]`が設定されている場合にHTTPメソッドをオーバーライドできるようにします。これは、ブラウザがネイティブにサポートしていない`PUT`、`PATCH`、`DELETE` HTTPメソッドをRailsでサポートする方法です。

[`Rack::MethodOverride`]:
  https://rack.github.io/rack/3.2/Rack/MethodOverride.html

#### `Rack::Runtime`

[`Rack::Runtime`][]ミドルウェアは、`X-Runtime`ヘッダを設定します。このヘッダには、リクエストの実行にかかった時間（秒単位）が含まれます。

[`Rack::Runtime`]:
  https://rack.github.io/rack/3.2/Rack/Runtime.html

#### `Rack::Sendfile`

[`Rack::Sendfile`][]ミドルウェアは、サーバー固有の`X-Sendfile`ヘッダを設定します。

これは、ApacheやNginxのようなリバースプロキシサーバーを利用している場合に、ファイル送信を高速化するのに役立ちます。たとえば、Apacheの場合は`X-Sendfile`に設定できます。これは[`config.action_dispatch.x_sendfile_header`][]オプションで設定します。

[`Rack::Sendfile`]:
  https://rack.github.io/rack/3.2/Rack/Sendfile.html
[`config.action_dispatch.x_sendfile_header`]:
  configuring.html#config-action-dispatch-x-sendfile-header

#### `Rack::TempfileReaper`

[`Rack::TempfileReaper`][]ミドルウェアは、マルチパートリクエストをバッファリングするための一時ファイルをクリーンアップします。

[`Rack::TempfileReaper`]:
  https://rack.github.io/rack/3.2/Rack/TempfileReaper.html

#### `Rails::Rack::Logger`

[`Rails::Rack::Logger`][]ミドルウェアは、リクエストの開始をログに通知します。リクエストが完了すると、すべてのログをフラッシュします。

[`Rails::Rack::Logger`]:
  https://api.rubyonrails.org/classes/Rails/Rack/Logger.html

TIP: これらのミドルウェアはいずれも、カスタムRackスタックで利用することも可能です。

カスタムミドルウェア
-----------------

独自のミドルウェアを作成してRailsアプリに組み込むことも可能です。

### ミドルウェアを作成する

カスタムミドルウェアは、`lib/`フォルダに配置したうえで、手動で`require`する必要があります（ミドルウェアは自動再読み込みされないため）。

以下の例では、URLパラメータから`locale`の値を読み取り、Rackの`env`に保存してから、`locale`をクエリパラメータから削除します。
これにより、リクエストがRailsコントローラに到達したときに`params`ハッシュに`locale`が含まれなくなり、パラメータをシンプルに保てます。

```ruby
# lib/middleware/extract_locale.rb

module RackMiddleware
  class ExtractLocale
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      if request.params["locale"].present?
        env["myapp.locale"] = env["action_dispatch.request.query_parameters"]["locale"]

        env["action_dispatch.request.query_parameters"].delete("locale")
        env["action_dispatch.request.parameters"].delete("locale")
      end

      @app.call(env)
    end
  end
end
```

Railsは、`lib/middleware/`フォルダをデフォルトで作成しないため、自分で作成する必要があります。
自動読み込みの問題を避けるため、このフォルダはautoloadパスに含めないことが推奨されます。

```ruby
# config/application.rb

module MyApp
  class Application < Rails::Application
    # ...

    config.autoload_lib(ignore: %w[assets tasks middleware])

    # ...
  end
end
```

### カスタムミドルウェアをスタックに追加する

カスタムミドルウェアは、以下のように`config/application.rb`ファイルに追加できます。

```ruby
# config/application.rb

# ...

require_relative "../lib/middleware/extract_locale"

module MyApp
  class Application < Rails::Application
    # ...

    config.middleware.use RackMiddleware::ExtractLocale

    # ...
  end
end
```

または、以下のように単独のイニシャライザにも追加できます。

```ruby
# config/initializers/extract_locale.rb

require "#{Rails.root.join("lib", "middleware", "extract_locale")}"

Rails.application.config.middleware.use RackMiddleware::ExtractLocale
```

RailsでRackの内部にアクセスする
-----------------------------

基盤となるRack APIは、Railsコントローラ内で利用できます。

### Rackの`env`にアクセスする

Railsのコントローラ内では、`request.env`でRackの`env`ハッシュにアクセスできます。

```ruby
class HomeController
  def index
    user_agent = request.env["HTTP_USER_AGENT"]

    # ...
  end
end
```

### Rackのレスポンスを書き込む

Railsのコントローラ内では、以下の方法でRackのレスポンスを直接書き込めます。

```ruby
class HomeController
  def index
    self.response = Rack::Response[200, {}, ["I'm Home!"]]
  end
end
```

### Rackアプリへのルーティング

`config/routes.rb`ファイルでリクエストをRackアプリにルーティングできます。
詳しくは[ルーティングガイド](routing.html#rackアプリケーションにルーティングする)を参照してください。
