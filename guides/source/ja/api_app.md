**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Rails による API 専用アプリケーション
=====================================

このガイドの内容:

* API専用アプリケーションを支援するRailsの機能
* Railsの起動時にブラウザ向け機能をオフにする方法
* ミドルウェアの選定
* コントローラで使うモジュールの選定

--------------------------------------------------------------------------------

APIアプリケーションについて
---------------------------

従来、Railsの「API」というと、プログラムからアクセスできるAPIをWebアプリケーションに追加することを指すのが通例でした。たとえば、GitHubが提供する[API](https://developer.github.com) をカスタムクライアントから利用できます。

近年、さまざまなクライアント側フレームワークが登場したことによって、Railsで作ったバックエンドサーバ―を、他のWebアプリケーションとネイティブアプリケーションの間で共有する手法が増えてきました。

たとえば、Twitterは自社のWebアプリケーションで [パブリックAPI](https://dev.twitter.com) を利用しています。このWebアプリケーションは、JSONリソースを消費するだけの静的サイトとして構築されています。

多くの開発者が、Railsで生成したHTMLフォームやリンクをサーバー間のやりとりに使うではなく、Webアプリケーションを単なるAPIクライアントにとどめて、JSON APIを利用するHTMLとJavaScriptの提供に徹するようになってきました。

本ガイドでは、JSONリソースをAPIクライアントに提供するRailsアプリケーションの構築方法を解説します。クライアント側フレームワークについても言及します。

JSON APIにRailsを使う理由
----------------------------

RailsでJSON APIを構築することについて、多くの開発者から真っ先に受ける質問といえば「RailsでJSONを出力するのは大げさすぎませんか？Sinatraじゃだめなんですか？」です。

単なるAPIサーバーであれば、おそらくそうでしょう。しかし、フロントのHTMLの比重が非常に大きいアプリケーションであっても、ロジックのほとんどはビューレイヤ以外の部分にあるのです。

Railsが多くの開発者に採用されている理由は、細かな設定をいちいち決めなくても、すばやくアプリケーションを立ち上げられるからこそです。

APIアプリケーションの開発にすぐ役立つRailsの機能をいくつかご紹介します。

ミドルウェア層で提供される機能

- 再読み込み: Railsアプリケーションでは「透過的な再読み込み」がサポートされます。たとえアプリケーションが巨大化し、リクエストごとにサーバーを再起動する方法が使えなくなっても、透過的な再読み込みは有効です。
- developmentモード: Railsアプリケーションのdevelopmentモードには洗練されたデフォルト値が設定されているので、本番のパフォーマンスなどの問題にわずらわされません。
- test モード: developmentと同様です。
- ログ出力: Railsアプリケーションはリクエストごとにログを出力します。また、現在のモードに応じてログの詳細レベルが調整されます。developmentモードのログには、リクエスト環境、データベースクエリ、基本的なパフォーマンス情報などが出力されます。
- セキュリティ: [IPスプーフィング攻撃](https://ja.wikipedia.org/wiki/IP%E3%82%B9%E3%83%97%E3%83%BC%E3%83%95%E3%82%A3%E3%83%B3%E3%82%B0) を検出・防御します。また、[タイミング攻撃](https://en.wikipedia.org/wiki/Timing_attack) に対応できる暗号化署名を扱います。ところでIPスプーフィング攻撃やタイミング攻撃って何でしょうね。
- パラメータ解析: URLエンコード文字列の代わりにJSONでパラメータを指定できます。JSONはRailsでデコードされ、`params`でアクセスできます。もちろん、ネストしたURLエンコードパラメータも扱えます。
- 条件付きGET: Railsでは、`ETag`や`Last-Modified`を使った条件付き`GET`を扱えます。条件付き`GET`はリクエストヘッダを処理し、正しいレスポンスヘッダとステータスコードを返します。コントローラに
  [`stale?`](https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F) チェックを追加するだけで、HTTPの細かなやりとりはRailsが代行してくれます。
- HEADリクエスト: Railsでは、`HEAD`リクエストを透過的に`GET`リクエストに変換し、ヘッダだけを返します。これによって、すべてのRails APIで`HEAD`リクエストを確実に利用できます。

Rackミドルウェアのこうした既存の機能を自前で構築することもできますが、Railsのデフォルトのミドルウェアを「JSON生成専用」に使うだけでも多数のメリットが得られます。

Action Pack層で提供される機能

- リソースベースのルーティング: RESTful JSON APIを開発するなら、Railsのルーターも使いたいところです。RailsでおなじみのHTTPからコントローラへの明確なマッピングを利用できるので、生のHTTPに沿ってAPIモデルをゼロから設計する必要がありません。
- URL生成: ルーティングは、URL生成にも便利です。よくできたHTTPベースのAPIにはURLも含まれています（[GitHub Gist API](https://developer.github.com/v3/gists/) がよい例）。
- ヘッダレスポンスやリダイレクトレスポンス: `head :no_content`や`redirect_to user_url(current_user)`などをすぐ利用できます。ヘッダレスポンスを自分で書かずに済みます。
- キャッシュ: Railsでは、ページキャッシュ、アクションキャッシュ、フラグメントキャッシュを利用できます。特に、フラグメントキャッシュはネストJSONオブジェクトを構成するときに便利です。
- BASIC認証、ダイジェスト認証、トークン認証: 3種類のHTTP認証を簡単に導入できます。
- Instrumentation（計測）: Railsのinstrumentation APIは、登録したさまざまなイベントハンドラをトリガーできます。アクションの処理、ファイルやデータの送信、リダイレクト、データベースクエリなどを扱えます。各イベントのペイロードにはさまざまな関連情報が含まれます。たとえば、イベントを処理するアクションの場合、ペイロードにはコントローラ、アクション、パラメータ、リクエスト形式、リクエストの完全なパスなどが含まれます。
- ジェネレータ: コマンド1つでリソースを手軽に生成して、APIに合うモデル、コントローラ、テストスタブ、ルーティングをすぐに利用できます。マイグレーションなども同じコマンドで行えます。
- プラグイン: サードパーティのライブラリを多数利用できます。ライブラリの設定やwebフレームワークとの連携も簡単なので、コストを削減できます。プラグインによっては、デフォルトのジェネレータをオーバーライドするものがあります。追加されるRakeタスクは、Rails標準に沿ったものになります（ロガーやキャッシュのバックエンドなど）。

もちろん、Railsのブートプロセスでは、登録済みのコンポーネントをすべて読み込んで連携します。たとえば、ブート中に`config/database.yml`ファイルを使ってActive Recordを設定します。

**忙しい方へ**: Railsからビュー層を取り除いた後で、どんな機能を引き続き利用できるのでしょう。手短に言うと「ほとんどの機能」です。

基本設定
-----------------------

APIサーバーにするRailsアプリケーションをすぐにでも構築したいのであれば、機能を限定したRailsサブセットを作って、必要な機能を順次追加するのがよいでしょう。

### アプリケーションを新規作成する

API専用Railsアプリケーションの生成には次のコマンドを使います。

```bash
$ rails new my_api --api
```

上のコマンドを実行すると、次の3つの操作を行います。

- 利用するミドルウェアを通常よりも絞り込んでアプリケーションを起動するよう設定します。特に、ブラウザ向けアプリケーションで有用なミドルウェア（cookiesのサポートなど）を一切利用しなくなります。
- `ApplicationController`を、通常の`ActionController::Base`の代わりに`ActionController::API`から継承します。ミドルウェアと同様、Action Controllerモジュールのうち、ブラウザ向けアプリケーションでしか使われないモジュールをすべて除外します。
- ビュー、ヘルパー、アセットを生成しないようジェネレーターを設定します。

### 既存アプリケーションを変更する

既存のアプリケーションをAPI専用に変えるには、次の手順をお読みください。

`config/application.rb`の`Application`クラス定義の冒頭に、次を追加します。

```ruby
config.api_only = true
```

developmentモードでのエラー発生時にレスポンスで使う形式を設定するには、`config/environments/development.rb`ファイルで`config.debug_exception_response_format`を設定します。

値を`:default`にすると、HTMLページにデバッグ情報を表示します。

```ruby
config.debug_exception_response_format = :default
```

値を`:api`にすると、レスポンスの形式を保ったままデバッグ情報を表示します。

```ruby
config.debug_exception_response_format = :api
```

`config.api_only`をtrueに設定すると、`config.debug_exception_response_format`がデフォルトで`:api`に設定されます。

最後に、`app/controllers/application_controller.rb`の以下のコードを置き換えます。

```ruby
class ApplicationController < ActionController::Base
end
```

上を以下に変更します。

```ruby
class ApplicationController < ActionController::API
end
```

ミドルウェアの選択
--------------------

APIアプリケーションでは、デフォルトで以下のミドルウェアを利用できます。

- `Rack::Sendfile`
- `ActionDispatch::Static`
- `ActionDispatch::Executor`
- `ActiveSupport::Cache::Strategy::LocalCache::Middleware`
- `Rack::Runtime`
- `ActionDispatch::RequestId`
- `ActionDispatch::RemoteIp`
- `Rails::Rack::Logger`
- `ActionDispatch::ShowExceptions`
- `ActionDispatch::DebugExceptions`
- `ActionDispatch::Reloader`
- `ActionDispatch::Callbacks`
- `ActiveRecord::Migration::CheckPending`
- `Rack::Head`
- `Rack::ConditionalGet`
- `Rack::ETag`
- `MyApi::Application::Routes`

詳しくは、Rackガイドの「[Rails と Rack - ミドルウェアスタックの内容](rails_on_rack.html#ミドルウェアスタックの内部)」をご覧ください。

ミドルウェアは、Active Recordなど他のプラグインによって追加されることがあります。一般に、構築するアプリケーションの種類とミドルウェアは関係ありませんが、API専用Railsアプリケーションでは意味があります。

アプリケーションの全ミドルウェアを表示するには次のコマンドを使います。

```bash
$ rails middleware
```

### キャッシュミドルウェアを使う

Railsにデフォルトで追加されるミドルウェアは、アプリケーションの設定に基づくキャッシュストア（デフォルトはmemcache）を提供します。このため、Railsに組み込まれているHTTPキャッシュはこのキャッシュストアに依存します。

たとえば、次のように`stale?`メソッドを呼び出すとします。

```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at)
    render json: @post
  end
end
```

`stale?`呼び出しは、リクエストにある`If-Modified-Since`ヘッダと`@post.updated_at`を比較します。ヘッダが最終更新時より新しい場合、「304 Not Modified」を返すか、レスポンスをレンダリングして`Last-Modified`ヘッダをそこに表示します。

通常、この動作はクライアントごとに行われますが、キャッシュミドルウェアがあるとクライアント間でこのキャッシュを共有できるようになります。クロスクライアントキャッシュは、`stale?`の呼び出し時に有効にできます。

```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at, public: true)
    render json: @post
  end
end
```

キャッシュミドルウェアは、URLに対応する`Last-Modified`値をRailsキャッシュに保存し、以後同じURLへのリクエストを受信したときに`If-Modified-Since`ヘッダを追加します。

これは、HTTPセマンティクスを利用したページキャッシュと考えることができます。

### Rack::Sendfileを使う

Railsコントローラ内部で`send_file`メソッドを実行すると、`X-Sendfile`ヘッダが設定されます。実際のファイル送信を担当するのは`Rack::Sendfile`です。

ファイル送信のアクセラレーションをサポートするフロントエンドサーバーでは、`Rack::Sendfile`の代わりにフロントエンドサーバーがファイルを送信します。

フロントエンドサーバーでのファイル送信に使うヘッダの名前は、該当する環境設定ファイルの`config.action_dispatch.x_sendfile_header`で設定できます。

著名なフロントエンドで`Rack::Sendfile`を使う方法について、詳しくは [the Rack::Sendfile documentation](http://rubydoc.info/github/rack/rack/master/Rack/Sendfile) をご覧ください。

定番のサーバーでファイル送信アクセラレーションを有効にするには、ヘッダに次のような値を設定します。

```ruby
# Apacheやlighttpd
config.action_dispatch.x_sendfile_header = "X-Sendfile"

# Nginx
config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
```

これらのオプションを有効にするには、`Rack::Sendfile`ドキュメントに従ってサーバーを設定してください。

### ActionDispatch::Requestを使う

`ActionDispatch::Request#params`は、クライアントからのパラメータをJSON形式で受け取り、コントローラ内部の`params`でアクセスできるようにします。

この機能を使うには、JSONエンコード化したパラメータをクライアントから送信し、`Content-Type`に`application/json`を指定する必要があります。

jQueryでは次のように行います。

```javascript
jQuery.ajax({
  type: 'POST',
  url: '/people',
  dataType: 'json',
  contentType: 'application/json',
  data: JSON.stringify({ person: { firstName: "Yehuda", lastName: "Katz" } }),
  success: function(json) { }
});
```

`ActionDispatch::Request`では、この`Content-Type`で
次のパラメータを受け取ります。

```ruby
{ :person => { :firstName => "Yehuda", :lastName => "Katz" } }
```

### その他のミドルウェア

Railsではこの他にも、APIアプリケーション向けのミドルウェアを多数利用できます。特に、ブラウザがAPIクライアントになる場合は、次のミドルウェアが便利です。

- `Rack::MethodOverride`
- `ActionDispatch::Cookies`
- `ActionDispatch::Flash`
- セッション管理向け
    * `ActionDispatch::Session::CacheStore`
    * `ActionDispatch::Session::CookieStore`
    * `ActionDispatch::Session::MemCacheStore`

これらのミドルウェアは、次の方法で追加できます。

```ruby
config.middleware.use Rack::MethodOverride
```

### ミドルウェアを削除する

API専用ミドルウェアに含めたくないミドルウェアは、次の方法で削除できます。

```ruby
config.middleware.delete ::Rack::Sendfile
```

これらのミドルウェアを削除すると、Action Controllerの一部の機能が利用できなくなりますので、ご注意ください。

コントローラモジュールを選択する
---------------------------

APIアプリケーション（`ActionController::API`を利用）には、デフォルトで次のコントローラモジュールが含まれます。

- `ActionController::UrlFor`: `url_for`などのヘルパーを提供
- `ActionController::Redirecting`: `redirect_to`をサポート
- `AbstractController::Rendering`と`ActionController::ApiRendering`: 基本的なレンダリングのサポート
- `ActionController::Renderers::All`: `render :json`などのサポート
- `ActionController::ConditionalGet`: `stale?`のサポート
- `ActionController::BasicImplicitRender`: 指定がない限り、空のレスポンスを返す
- `ActionController::StrongParameters`: パラメータのホワイトリストをサポート（Active Modelのマスアサインメントと連携）
- `ActionController::ForceSSL`: `force_ssl`のサポート
- `ActionController::DataStreaming`: `send_file`や`send_data`のサポート
- `AbstractController::Callbacks`: `before_action`などのヘルパーをサポート
- `ActionController::Rescue`: `rescue_from`をサポート
- `ActionController::Instrumentation`: Action Controllerで定義するinstrumentationフックをサポート（詳しくは[the instrumentation guide](active_support_instrumentation.html#action-controller) を参照）
- `ActionController::ParamsWrapper`: パラメータハッシュをラップしてネスト化ハッシュにし、POSTリクエスト送信時のルート要素指定などを不要にする
- `ActionController::Head`: コンテンツのないヘッダのみのレスポンスを返すのに用いる

他のプラグインによってモジュールが追加されることもあります。`ActionController::API`の全モジュールのリストは、次のコマンドで表示できます。

```bash
$ bin/rails c
>> ActionController::API.ancestors - ActionController::Metal.ancestors
=> [ActionController::API,
    ActiveRecord::Railties::ControllerRuntime,
    ActionDispatch::Routing::RouteSet::MountedHelpers,
    ActionController::ParamsWrapper,
    ... ,
    AbstractController::Rendering,
    ActionView::ViewPaths]
```

### その他のモジュールを追加する

Action Controllerのどのモジュールも、自身が依存するモジュールを把握しているので、コントローラにモジュールを含めるだけで、必要な依存モジュールも同様に設定できます。

よく追加されるのは、次のようなモジュールです。

- `AbstractController::Translation`: ローカライズ用の`l`メソッドや、翻訳用の`t`メソッド
- HTTPのBasic認証、ダイジェスト認証、トークン認証:
  * `ActionController::HttpAuthentication::Basic::ControllerMethods`
  * `ActionController::HttpAuthentication::Digest::ControllerMethods`
  * `ActionController::HttpAuthentication::Token::ControllerMethods`
- `ActionView::Layouts`: レンダリングのレイアウトをサポート
- `ActionController::MimeResponds`: `respond_to`をサポート
- `ActionController::Cookies`: `cookies`のサポート（署名や暗号化も含む）。cookiesミドルウェアが必要。

モジュールは`ApplicationController`に追加するのが最適ですが、個別のコントローラに追加しても構いません。
