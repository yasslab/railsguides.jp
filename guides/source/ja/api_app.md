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

従来、Railsの「API」というと、プログラムからアクセスできるAPIをWebアプリケーションに追加することを指すのが通例でした。たとえば、GitHubが提供する[API](https://developer.github.com)はカスタムクライアントから利用できます。

近年、さまざまなクライアント側フレームワークが登場したことによって、Railsで構築したバックエンドサーバーを他のWebアプリケーションとネイティブアプリケーションの間で共有する手法が増えてきました。

たとえば、X.comは自社のWebアプリケーションで[パブリックAPI](https://developer.x.com/)を利用しています。このWebアプリケーションは、JSONリソースを消費するだけの静的サイトとして構築されています。

多くの開発者が、Railsで生成したHTMLフォームやリンクをサーバー間のやりとりに使うのではなく、Webアプリケーションを単なるAPIクライアントにとどめて、JSON APIを利用するHTMLとJavaScriptの提供に専念するようになってきました。

本ガイドでは、JSONリソースをAPIクライアントに提供するRailsアプリケーションの構築方法を解説します。クライアント側フレームワークについても言及します。

JSON APIにRailsを使う理由
----------------------------

RailsでJSON APIを構築することについて、多くの開発者から受ける質問の筆頭は「RailsでJSONを出力するのは大げさすぎませんか？Sinatraじゃダメなんですか？」です。

単なるAPIサーバーであれば、それでもよいでしょう。しかし、フロントHTMLの比重が非常に大きいアプリケーションであっても、アプリケーションロジックのほとんどはビューレイヤ以外の部分にあるものです。

Railsが多くの開発者に採用されている理由は、細かな設定をいちいち決めなくても、すばやくアプリケーションを立ち上げられるからこそです。

APIアプリケーションの開発にすぐ役立つRailsの機能をいくつかご紹介します。

ミドルウェア層で提供される機能

- **再読み込み**: Railsアプリケーションでは「透過的な再読み込み」がサポートされます。たとえアプリケーションが巨大化し、リクエストごとにサーバーを再起動する方法が使えなくなっても、透過的な再読み込みは有効です。
- **developmentモード**: Railsアプリケーションのdevelopmentモードには開発に最適なデフォルト値が設定されているので、productionモードのパフォーマンスを損なわずに快適な開発環境を利用できます。
- **testモード**: developmentモードと同様です。
- **ログ出力**: Railsアプリケーションはすべてのリクエストをログに出力します。また、現在のモードに応じてログの詳細レベルが調整されます。developmentモードのログには、リクエスト環境、データベースクエリ、基本的なパフォーマンス情報などが出力されます。
- **セキュリティ**: [IPスプーフィング攻撃](https://ja.wikipedia.org/wiki/IP%E3%82%B9%E3%83%97%E3%83%BC%E3%83%95%E3%82%A3%E3%83%B3%E3%82%B0)を検出・防御します。また、[タイミング攻撃](https://ja.wikipedia.org/wiki/%E3%82%BF%E3%82%A4%E3%83%9F%E3%83%B3%E3%82%B0%E6%94%BB%E6%92%83)に対応できる暗号化署名を扱います。皆さんはIPスプーフィング攻撃やタイミング攻撃がどんなものかご存知ですか？
- **パラメータ解析**: URLエンコード文字列の代わりにJSONでパラメータを指定できます。JSONはRailsでデコードされ、`params`でアクセスできます。もちろん、ネストしたURLエンコードパラメータも扱えます。
- **条件付きGET**: Railsでは、`ETag`や`Last-Modified`を使った条件付き`GET`を扱えます。条件付き`GET`はリクエストヘッダを処理し、正しいレスポンスヘッダとステータスコードを返します。コントローラに
  [**`stale?`**](https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F)チェックを追加するだけで、HTTPの細かなやりとりはRailsが代行してくれます。
- **HEADリクエスト**: Railsは`HEAD`リクエストを透過的に`GET`リクエストに変換し、ヘッダだけを返します。これによって、すべてのRails APIで`HEAD`リクエストを確実に利用できます。

Rackミドルウェアのこうした既存の機能を自前で構築する方法も考えられますが、Railsのデフォルトのミドルウェアを「JSON生成専用」に使うだけでも多数のメリットが得られます。

Action Pack層で提供される機能

- **リソースベースのルーティング**: RESTful JSON APIを開発するなら、Railsのルーターも使いたいでしょう。RailsでおなじみのHTTPからコントローラへの明確なマッピングを利用できるので、APIモデルをHTTPベースでゼロから設計せずに済みます。
- **URL生成**: ルーティングはURL生成にも便利です。よくできたHTTPベースのAPIにはURLも含まれています（[GitHub Gist API](https://developer.github.com/v3/gists/)を参照）。
- **ヘッダレスポンスやリダイレクトレスポンス**: `head :no_content`や`redirect_to user_url(current_user)`などをすぐ利用できるので、ヘッダレスポンスを自分で書かずに済みます。
- **キャッシュ**: Railsでは「ページキャッシュ」「アクションキャッシュ（gem）」「フラグメントキャッシュを利用できます。特に、フラグメントキャッシュはネストJSONオブジェクトを構成するときに便利です。
- **認証**: 「BASIC認証」「ダイジェスト認証」「トークン認証」という3種類のHTTP認証を簡単に導入できます。
- **Instrumentation（計測）**: Railsのinstrumentation APIは、登録したさまざまなイベントハンドラをトリガーでき、アクションの処理、ファイルやデータの送信、リダイレクト、データベースクエリなどを扱えます。各イベントのペイロードにはさまざまな関連情報が含まれます。たとえば、イベントを処理するアクションの場合、ペイロードにはコントローラ、アクション、パラメータ、リクエスト形式、リクエストHTTPメソッド、リクエストの完全なパスなどが含まれます。
- **ジェネレータ**: コマンド1つでリソースを手軽に生成して「モデル」「コントローラ」「テストスタブ」「ルーティング」を微調整できるので便利です。マイグレーションなども同様にコマンドで実行できます。
- **プラグイン**: Rails用のサードパーティライブラリを多数利用できます。ライブラリの設定やWebフレームワークとの連携も簡単なので、コストを削減できます。プラグインによっては、デフォルトのジェネレータをオーバーライドしたり、Rakeタスクを追加したり、ロガーやキャッシュのバックエンドなどのRails標準機能を活用したりするものもあります。

もちろん、Railsの起動プロセスでは、登録済みのコンポーネントをすべて読み込んで連携します。たとえば、起動中に`config/database.yml`ファイルを使ってActive Recordを設定します。

**要約**: ビュー層を取り除いたRailsでは、どんな機能を引き続き利用できるのでしょう。手短に言うと「ほとんどの機能」です。

基本設定
-----------------------

APIサーバーにするRailsアプリケーションをすぐにでも構築したいのであれば、機能を限定したRailsサブセットを作って、必要な機能を順次追加するのがよいでしょう。

### アプリケーションを新規作成する

API専用Railsアプリケーションの生成には次のコマンドを使います。

```bash
$ rails new my_api --api
```

上のコマンドを実行すると、以下の3つが行われます。

- 利用するミドルウェアを通常よりも絞り込んでアプリケーションを起動するよう設定します。特に、ブラウザ向けアプリケーションで有用なミドルウェア（cookiesのサポートなど）はデフォルトでは利用しません。
- `ApplicationController`が通常の`ActionController::Base`ではなく`ActionController::API`を継承します。ミドルウェアと同様、Action Controllerモジュールのうち、ブラウザ向けアプリケーションでしか使われないモジュールをすべて除外します。
- ビュー、ヘルパー、アセットを生成しないようジェネレーターを設定します。

### 新しいリソースを生成する

新しく作成したAPIで新しいリソースを生成する方法を確認するために、新しいGroupリソースを作成してみましょう。各グループごとに名前を付けます。

```bash
$ bin/rails g scaffold Group name:string
```

scaffoldで生成したコードを使えるようにするには、データベーススキーマを更新する必要があります。

```bash
$ bin/rails db:migrate
```

ここで`GroupsController`を開いてみると、API RailsアプリではJSONデータのみをレンダリングしていることがわかります。`index`アクションでは`Group.all`をクエリしてインスタンス変数`@groups`に代入しています。これを、`render`に`:json`オプションを指定して渡すと、自動的にグループをJSONとしてレンダリングします。

```ruby
# app/controllers/groups_controller.rb
class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show update destroy ]

  # GET /groups
  def index
    @groups = Group.all

    render json: @groups
  end

  # GET /groups/1
  def show
    render json: @group
  end

  # POST /groups
  def create
    @group = Group.new(group_params)

    if @group.save
      render json: @group, status: :created, location: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /groups/1
  def update
    if @group.update(group_params)
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /groups/1
  def destroy
    @group.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.expect(group: [:name])
    end
end
```

最後に、Railsコンソールでデータベースにグループを追加してみましょう。

```irb
irb> Group.create(name: "Rails Founders")
irb> Group.create(name: "Rails Contributors")
```

ある程度のデータがアプリにあれば、サーバーを起動して<http://localhost:3000/groups.json>にアクセスするとJSONデータを表示できます。


```json
[
{"id":1, "name":"Rails Founders", "created_at": ...},
{"id":2, "name":"Rails Contributors", "created_at": ...}
]
```

### 既存アプリケーションを変更する

既存のアプリケーションをAPI専用に変えるには、以下の手順をお読みください。

`config/application.rb`の`Application`クラス定義の冒頭に以下の設定を追加します。

```ruby
config.api_only = true
```

developmentモードでのエラー発生時に使われるレスポンス形式を設定するには、`config/environments/development.rb`ファイルで[`config.debug_exception_response_format`][]を設定します。

値を`:default`にすると、デバッグ情報をHTMLページに表示します。

```ruby
config.debug_exception_response_format = :default
```

値を`:api`にすると、レスポンス形式を変更せずにデバッグ情報を表示します。

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

[`config.debug_exception_response_format`]: configuring.html#config-debug-exception-response-format

ミドルウェアの選択
--------------------

APIアプリケーションでは、デフォルトで以下のミドルウェアを利用できます。

- `ActionDispatch::HostAuthorization`
- `Rack::Sendfile`
- `ActionDispatch::Static`
- `ActionDispatch::Executor`
- `ActionDispatch::ServerTiming`
- `ActiveSupport::Cache::Strategy::LocalCache::Middleware`
- `Rack::Runtime`
- `ActionDispatch::RequestId`
- `ActionDispatch::RemoteIp`
- `Rails::Rack::Logger`
- `ActionDispatch::ShowExceptions`
- `ActionDispatch::DebugExceptions`
- `ActionDispatch::ActionableExceptions`
- `ActionDispatch::Reloader`
- `ActionDispatch::Callbacks`
- `ActiveRecord::Migration::CheckPending`
- `Rack::Head`
- `Rack::ConditionalGet`
- `Rack::ETag`

詳しくは、Rackガイドの「[Rails と Rack - ミドルウェアスタックの内容](rails_on_rack.html#ミドルウェアスタックの内部)」を参照してください。

ミドルウェアは、Active Recordなど他のプラグインによって追加されることもあります。一般に、ミドルウェアは構築するアプリケーションの種類を問いませんが、API専用Railsアプリケーションでも意味があります。

アプリケーションの全ミドルウェアを表示するには次のコマンドを使います。

```bash
$ bin/rails middleware
```

### Rack::Cacheを使う

`Rack::Cache`は、Railsで利用する場合はRailsのキャッシュストアをエンティティストアとメタストアに使います。つまり、たとえばRailsアプリでmemcacheを使うと、組み込みのHTTPキャッシュがmemcacheを使うようになります。

`Rack::Cache`を利用するには、最初に`rack-cache` gemを`Gemfile`に追加し、`config.action_dispatch.rack_cache`に`true`を設定する必要があります。この機能を有効にするには、コントローラで`stale?`を使う必要があります。以下は、`stale?`の利用例です。


```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at)
    render json: @post
  end
end
```

`stale?`呼び出しは、リクエストにある`If-Modified-Since`ヘッダと`@post.updated_at`を比較します。ヘッダが最終更新時より新しい場合、「304 Not Modified」を返すか、レスポンスをレンダリングして`Last-Modified`ヘッダをそこに表示します。

通常、この動作はクライアントごとに行われますが、`Rack::Cache`があるとクライアント間でこのキャッシュを共有できるようになります。以下のように、`stale?`の呼び出しを使ってクロスクライアントキャッシュを有効にできます。

```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at, public: true)
    render json: @post
  end
end
```

`Rack::Cache`は上のコードによって、URLに対応する`Last-Modified`値をRailsキャッシュに保存し、以後同じURLへのリクエストを受信したときに`If-Modified-Since`ヘッダを追加するようになります。

これは、HTTPセマンティクスを利用したページキャッシュと考えることができます。

### Rack::Sendfileを使う

Railsコントローラ内部で`send_file`メソッドを実行すると、`X-Sendfile`ヘッダが設定されます。実際のファイル送信を担当するのは`Rack::Sendfile`です。

ファイル送信アクセラレーションをサポートするフロントエンドサーバーでは、`Rack::Sendfile`の代わりにフロントエンドサーバーがファイルを送信します。これにより、Railsはリクエスト処理を早期に完了してリソースを解放できるようになります。

フロントエンドサーバーでのファイル送信に使うヘッダ名は、該当する環境設定ファイルの[`config.action_dispatch.x_sendfile_header`][]で設定できます。

主要なフロントエンドで`Rack::Sendfile`を使う方法について詳しくは、[`Rack::Sendfile`ドキュメント](https://www.rubydoc.info/gems/rack/Rack/Sendfile)を参照してください。

主要なサーバーでファイル送信アクセラレーションを有効にするには、ヘッダに次のような値を設定します。

```ruby
# Apacheやlighttpd
config.action_dispatch.x_sendfile_header = "X-Sendfile"

# Nginx
config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
```

これらのオプションを有効にするには、`Rack::Sendfile`ドキュメントに従ってサーバーを設定してください。

[`config.action_dispatch.x_sendfile_header`]: configuring.html#config-action-dispatch-x-sendfile-header

### ActionDispatch::Requestを使う

`ActionDispatch::Request#params`は、クライアントからのパラメータをJSON形式で受け取り、コントローラ内部の`params`でアクセスできるようにします。

この機能を使うには、JSONエンコード化したパラメータをクライアントから送信し、`Content-Type`に`application/json`を指定する必要があります。

以下はサンプルコードです。

```js
fetch('/people', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ person: { firstName: 'Yehuda', lastName: 'Katz' } })
}).then(response => response.json())
```

`ActionDispatch::Request`はこの`Content-Type`を認識し、パラメータは以下のようになります。

```ruby
{ person: { firstName: "Yehuda", lastName: "Katz" } }
```

### セッションミドルウェアを利用する

通常は以下のセッション管理用ミドルウェアは不要なので、APIから除外されています。ブラウザもAPIクライアントとして使われる場合は、以下のいずれかを追加するとよいでしょう。

- `ActionDispatch::Session::CacheStore`
- `ActionDispatch::Session::CookieStore`
- `ActionDispatch::Session::MemCacheStore`

ここで注意が必要なのは、これらのミドルウェア（およびセッションキー）はデフォルトでは`session_options`に渡されることです。つまり、通常どおりに`session_store.rb`イニシャライザを追加して`use ActionDispatch::Session::CookieStore`を指定しただけではセッションは機能しません（補足: セッションは動作しますがセッションオプションが無視されるので、セッションキーがデフォルトで`_session_id`になります）。

そのため、セッション関連のオプションはイニシャライザで設定するのではなく、以下のように自分が使うミドルウェアが構築されるより前の場所（`config/application.rb`など）に配置して、使いたいオプションをミドルウェアに渡さなければなりません。

```ruby
# 以下のsession_optionsも利用可能
config.session_store :cookie_store, key: "_your_app_session"

# このミドルウェアはすべてのセッション管理で必須（session_storeに関わらず）
config.middleware.use ActionDispatch::Cookies

config.middleware.use config.session_store, config.session_options
```

### その他のミドルウェア

Railsではこの他にも、APIアプリケーション向けのミドルウェアを多数利用できます。特に、ブラウザもAPIクライアントとして使う場合は以下のミドルウェアが便利です。

- `Rack::MethodOverride`
- `ActionDispatch::Cookies`
- `ActionDispatch::Flash`

これらのミドルウェアは、以下の方法で追加できます。

```ruby
config.middleware.use Rack::MethodOverride
```

### ミドルウェアを削除する

API専用ミドルウェアに含めたくないミドルウェアは、以下の方法で削除できます。

```ruby
config.middleware.delete ::Rack::Sendfile
```

これらのミドルウェアを削除すると、Action Controllerの一部の機能が利用できなくなりますので、ご注意ください。

コントローラモジュールを選択する
---------------------------

APIアプリケーション（`ActionController::API`を利用）には、デフォルトで次のコントローラモジュールが含まれます。

<!-- epubなどでのレイアウト崩れ防止のため、念のためリスト形式を維持します -->

- `ActionController::UrlFor`: `url_for`などのヘルパーを提供
- `ActionController::Redirecting`: `redirect_to`をサポート
- `AbstractController::Rendering`と`ActionController::ApiRendering`: 基本的なレンダリングのサポート
- `ActionController::Renderers::All`: `render :json`などのサポート
- `ActionController::ConditionalGet`: `stale?`のサポート
- `ActionController::BasicImplicitRender`: 指定がない限り空のレスポンスを返す
- `ActionController::StrongParameters`: パラメータのフィルタリングをサポート（Active Modelのマスアサインメントと連携）
- `ActionController::DataStreaming`: `send_file`や`send_data`のサポート
- `AbstractController::Callbacks`: `before_action`などのヘルパーをサポート
- `ActionController::Rescue`: `rescue_from`をサポート
- `ActionController::Instrumentation`: Action Controllerで定義するinstrumentationフックをサポート（詳しくは[instrumentationガイド][]を参照）
- `ActionController::ParamsWrapper`: パラメータハッシュをラップしてネステッドハッシュにする（たとえばPOSTリクエスト送信時のroot要素が必須でなくなる）
- `ActionController::Head`: コンテンツのないヘッダのみのレスポンスを返すのに用いる

他のプラグインによってモジュールが追加されることもあります。`ActionController::API`の全モジュールのリストは以下のコマンドで表示できます。

```irb
irb> ActionController::API.ancestors - ActionController::Metal.ancestors
=> [ActionController::API,
    ActiveRecord::Railties::ControllerRuntime,
    ActionDispatch::Routing::RouteSet::MountedHelpers,
    ActionController::ParamsWrapper,
    ... ,
    AbstractController::Rendering,
    ActionView::ViewPaths]
```

[instrumentationガイド]: active_support_instrumentation.html#action-controller

### その他のモジュールを追加する

Action Controllerのどのモジュールも、自身が依存するモジュールを認識しているので、コントローラにモジュールを含めるだけで、必要な依存モジュールも同様に設定できます。

よく追加されるのは、次のようなモジュールです。

- `AbstractController::Translation`: ローカライズ用の`l`メソッドや翻訳用の`t`メソッド
- HTTPのBasic認証、ダイジェスト認証、トークン認証:
  * `ActionController::HttpAuthentication::Basic::ControllerMethods`
  * `ActionController::HttpAuthentication::Digest::ControllerMethods`
  * `ActionController::HttpAuthentication::Token::ControllerMethods`
- `ActionView::Layouts`: レンダリングでレイアウトをサポート
- `ActionController::MimeResponds`: `respond_to`をサポート
- `ActionController::Cookies`: `cookies`のサポート（署名や暗号化も含む）。cookiesミドルウェアが必要。
- `ActionController::Caching`: APIコントローラでビューのキャッシュをサポート（ただし以下のようにコントローラ内でキャッシュストアを手動で指定する必要がある）

    ```ruby
    class ApplicationController < ActionController::API
      include ::ActionController::Caching
      self.cache_store = :mem_cache_store
    end
    ```

    Railsはこの設定を「自動的には渡しません」。

モジュールは`ApplicationController`に追加するのが最適ですが、個別のコントローラに追加することも可能です。
