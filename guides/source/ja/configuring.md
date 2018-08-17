Railsアプリを設定する
==============================

このガイドではRailsアプリケーション（アプリ）で利用可能な設定と初期化機能について説明いたします。

このガイドの内容:

* Railsアプリの動作を調整する方法
* アプリ開始時に実行したいコードを追加する方法

--------------------------------------------------------------------------------

初期化コードの置き場所
---------------------------------

Railsには初期化コードの置き場所が4箇所あります。

* `config/application.rb`
* 環境に応じた設定ファイル
* イニシャライザ
* アフターイニシャライザ

Rails実行前にコードを実行する
-------------------------

アプリでRails自体が読み込まれる前に何らかのコードを実行する必要が生じることがまれにあります。その場合は、実行したいコードを`config/application.rb`ファイルの`require 'rails/all'`行より前に書いてください。

Railsコンポーネントを構成する
----------------------------

一般に、Railsの設定作業とはRails自身を設定することでもあると同時に、Railsのコンポーネントを設定することでもあります。`config/application.rb`および環境固有の設定ファイル(`config/environments/production.rb`など)に設定を記入することで、Railsのすべてのコンポーネントにそれらの設定を渡すことができます。

たとえば、`config/application.rb`ファイルには以下の設定が含まれています。

```ruby
config.autoload_paths += %W(#{config.root}/extras)
```

これはRails自身のための設定です。設定をすべてのRailsコンポーネントに渡したい場合は、`config/application.rb`内の同じ`config`オブジェクトを使用して行なうことができます。

```ruby
config.active_record.schema_format = :ruby
```

この設定は、特にActive Recordの設定に使用されます。

### Rails全般の設定

Rails全般に対する設定を行うには、`Rails::Railtie`オブジェクトを呼び出すか、`Rails::Engine`や`Rails::Application`のサブクラスを呼び出します。

* `config.after_initialize`にはブロックを渡すことができます。このブロックは、Railsによるアプリの初期化が完了した _直後_ に実行されます。アプリの初期化作業には、フレームワーク自体の初期化、エンジンの初期化、そして`config/initializers`に記述されたすべてのアプリイニシャライザの実行が含まれます。ここで渡すブロックはタスクとして_実行される_ ことにご注意ください。このブロックは、他のイニシャライザによって設定される値を設定するのに便利です。

    ```ruby
    config.after_initialize do
      ActionView::Base.sanitized_allowed_tags.delete 'div'
    end
    ```

* `config.asset_host`はアセットを置くホストを設定します。この設定は、アセットの置き場所がCDN (Contents Delivery Network) の場合や、別のドメインエイリアスを使用するとブラウザの同時実行制限にひっかかるのを避けたい場合に便利です。このメソッドは`config.action_controller.asset_host`を短縮したものです。

* `config.autoload_once_paths`は、サーバーへのリクエストごとにクリアされない定数を自動読込するパスの配列を引数に取ります。この設定は`config.cache_classes`が`false`の場合に影響を受けます。`config.cache_classes`はdevelopmentモードではデフォルトでオフです。`config.cache_classes`がtrueの場合、すべての`config.autoload_once_paths`自動読み込みは一度しか行われません。`config.autoload_once_paths`の配列に含まれる要素は、次で説明する`autoload_paths`にもまったく同じように含めておく必要があります。`config.autoload_once_paths`のデフォルト値は、空の配列です。

* `config.autoload_paths`はRailsが定数を自動読込するパスを含む配列を引数に取ります。`config.autoload_paths`のデフォルト値は、`app`以下のすべてのディレクトリです(訳注: Rails3からはautoload_pathの設定はデフォルトでは無効です)。

* `config.cache_classes`は、アプリのクラスやモジュールをリクエストごとに再読み込みするか(=キャッシュしないかどうか)どうかを指定します。`config.cache_classes`のデフォルト値は、developmentモードでは`false`なのでコードの更新がすぐ反映され、testモードとproductionモードでは`true`なので動作が高速になります。同時に`threadsafe!`をオンにすることもできます。

* `config.action_view.cache_template_loading`は、リクエストのたびにビューテンプレートを再読み込みするか(=キャッシュしないか)を指定します。`config.action_view.cache_template_loading`のデフォルト値は`config.cache_classes`がtrueならtrue、falseならfalseとして設定されます。

* `config.beginning_of_week`は、アプリにおける週の初日を設定します。引数には、曜日を表す正しいシンボルを渡します(`:monday`など)。

* `config.cache_store`はRailsでのキャッシュ処理に使用されるキャッシュストアを設定します。指定できるオプションは次のシンボル`:memory_store`、`:file_store`、`:mem_cache_store`、`:null_store`のいずれか、またはキャッシュAPIを実装するオブジェクトです。`tmp/cache`ディレクトリが存在する場合のデフォルトは`:file_store`に設定され、それ以外の場合のデフォルトは`:memory_store`に設定されます。

* `config.colorize_logging`は、出力するログ情報にANSI色情報を与えるかどうかを指定します。デフォルトは`true`です。

* `config.consider_all_requests_local`はフラグです。このフラグが`true`の場合、どのような種類のエラーが発生した場合にも詳細なデバッグ情報がHTTPレスポンスに出力され、アプリの実行時コンテキストが`Rails::Info`コントローラによって`/rails/info/properties`に出力されます。このフラグはdevelopmentモードとtestモードでは`true`、productionモードでは`false`に設定されます。もっと細かく制御したい場合は、このフラグを`false`に設定してから、コントローラで`local_request?`メソッドを実装し、エラー時にどのデバッグ情報を出力するかをそこで指定してください。

* `config.console`を使用すると、コンソールで`rails console`を実行する時に使用されるクラスをカスタマイズできます。このメソッドは`console`ブロックで使用するのが最適です。

    ```ruby
    console do
      # このブロックはコンソールで実行されるときしか呼び出されない
      # 従ってここでpryを呼び出しても問題ない
      require "pry"
      config.console = Pry
    end
    ```

* `config.eager_load`を`true`にすると、`config.eager_load_namespaces`に登録された事前一括読み込み(eager loading)用の名前空間をすべて読み込みます。ここにはアプリ、エンジン、Railsフレームワークを含むあらゆる登録済み名前空間が含まれます。

* `config.eager_load_namespaces`を使用して登録した名前は、`config.eager_load`が`true`のときに読み込まれます。登録された名前空間は、必ず`eager_load!`メソッドに応答しなければなりません。

* `config.eager_load_paths`は、パスの配列を引数に取ります。Railsは、cache_classesがオンの場合にこのパスから事前一括読み込み(eager load)します。デフォルトではアプリの`app`ディレクトリ以下のすべてのディレクトリが対象です。

* `config.enable_dependency_loading`：`true`の場合、アプリが事前に読み込まれ、`config.cache_classes`がtrueに設定されていても、自動読み込みを有効にします。 デフォルトは`false`です。

* `config.encoding`はアプリ全体のエンコーディングを指定します。デフォルトはUTF-8です。

* `config.exceptions_app`は、例外が発生したときにShowExceptionミドルウェアによって呼び出されるアプリ例外を設定します。デフォルトは`ActionDispatch::PublicExceptions.new(Rails.public_path)`です。

* `config.debug_exception_response_format`は、developmentモードで発生したエラーのレスポンスで用いられるフォーマットを設定します。通常のアプリの場合は`:default`が、APIのみの場合は`:api`がデフォルトで設定されます。

* `config.file_watcher`は、`config.reload_classes_only_on_change`が`true`の場合にファイルシステム上のファイル更新検出に使用されるクラスを指定します。デフォルトのRailsでは`ActiveSupport::FileUpdateChecker`、および`ActiveSupport::EventedFileUpdateChecker`（これは[listen](https://github.com/guard/listen)に依存します）が指定されます。カスタムクラスはこの`ActiveSupport::FileUpdateChecker` APIに従わなければなりません。

* `config.filter_parameters`は、パスワードやクレジットカード番号など、ログに出力したくないパラメータをフィルタで除外するのに用います。デフォルトのRailsでは`config/initializers/filter_parameter_logging.rb`に`Rails.application.config.filter_parameters += [:password]`を追加することでパスワードをフィルタで除外します。パラメータのフィルタは正規表現の部分一致によって行われます。

* `config.force_ssl`は、`ActionDispatch::SSL`ミドルウェアを使用して、すべてのリクエストをHTTPSプロトコル下で実行するよう強制し、かつ`config.action_mailer.default_url_options`を`{ protocol: 'https' }`に設定します。詳しくは[ActionDispatch::SSL documentation](http://api.rubyonrails.org/classes/ActionDispatch/SSL.html)を参照してください。

* `config.log_formatter`はRailsロガーのフォーマットを定義します。このオプションは、デフォルトではすべてのモードで`ActiveSupport::Logger::SimpleFormatter`のインスタンスを使用します。`config.logger`を設定する場合は、この設定が`ActiveSupport::TaggedLogging`インスタンスでラップされるより前に、フォーマッターの値を手動で渡さなければなりません。Railsはこの処理を自動では行いません。

* `config.log_level`は、Railsのログ出力をどのぐらい詳細にするかを指定します。デフォルトではすべての環境で`:debug`が指定されます。指定可能な出力レベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`です。

* `config.log_tags`は、次のリストを引数に取ります（`request`オブジェクトが応答するメソッド、`request`オブジェクトを受け取る`Proc`、または`to_s`に応答できるオブジェクト）。これは、ログの行にデバッグ情報をタグ付けする場合に便利です。たとえばサブドメインやリクエストidを指定することができ、これらはマルチユーザーのproductionモードアプリをデバッグするのに便利です。

* `config.logger`は、`Rails.logger`で使われるロガーやRails関連のあらゆるログ出力（`ActiveRecord::Base.logger`など）を指定します。デフォルトでは、`ActiveSupport::Logger`のインスタンスをラップする`ActiveSupport::TaggedLogging`のインスタンスが指定されます。なお`ActiveSupport::Logger`はログを`log/`ディレクトリに出力します。ここにカスタムロガーを指定できますが、互換性を完全にするには以下のガイドラインに従わなければなりません。

* フォーマッターをサポートするため、`config.log_formatter`の値を手動でロガーに代入しなければなりません。
* タグ付きログをサポートするため、そのログのインスタンスを`ActiveSupport::TaggedLogging`でラップしなければなりません。
* ログ出力の抑制をサポートするため、`LoggerSilence`モジュールと`ActiveSupport::LoggerThreadSafeLevel`を`include`しなければなりません。`ActiveSupport::Logger`クラスは既にこれらのモジュールに`include`されています。

```ruby
class MyLogger < ::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include LoggerSilence
end
mylogger           = MyLogger.new(STDOUT)
mylogger.formatter = config.log_formatter
config.logger      = ActiveSupport::TaggedLogging.new(mylogger)
```

* `config.middleware`は、アプリで使用するミドルウェアをカスタマイズできます。詳細については[ミドルウェアを設定する](#ミドルウェアを設定する)の節を参照してください。

* `config.reload_classes_only_on_change`は、監視しているファイルが変更された場合にのみクラスを再読み込みするかどうかを指定します。デフォルトでは、autoload_pathで指定されたすべてのファイルが監視対象となり、デフォルトで`true`が設定されます。`config.cache_classes`が`true`の場合はこのオプションは無視されます。

* `secret.secret_key_base`メソッドは、改竄防止のために、アプリのセッションを既知の秘密キーと照合するためのキーを指定するときに使います。test環境とdevelopment環境の場合、`secrets.secret_key_base`でランダムに生成されたキーが使われます。その他の環境ではキーを`config/credentials.yml.enc`に設定すべきです。

* `config.serve_static_assets`は、publicなディレクトリ内の静的アセットを扱うかどうかを指定します。デフォルトでは`true`が設定されますが、production環境ではアプリを実行するNginxやApacheなどのサーバーが静的アセットを扱う必要があるので、`false`になります。デフォルトの設定とは異なり、WEBrickを使用してアプリをproductionモードで実行したり(WEBrickをproductionで使うことは推奨されません)テストしたりする場合は`true`に設定します。そうしないとページキャッシュが利用できなくなり、publicディレクトリ以下に常駐する静的ファイルへのリクエストも有効になりません。

* `config.session_store`は、セッションの保存に使うクラスを指定します。指定できる値は`:cookie_store`(デフォルト)、`:mem_cache_store`、`:disabled`です。`:disabled`を指定すると、Railsでセッションが扱われなくなります。デフォルトでは、アプリ名と同じ名前のcookieストアがセッションキーとして使われます。カスタムセッションストアを指定することもできます。

    ```ruby
    config.session_store :my_custom_store
    ```

カスタムストアは`ActionDispatch::Session::MyCustomStore`として定義する必要があります。

* `config.time_zone`はアプリのデフォルトタイムゾーンを設定し、Active Recordで認識できるようにします。

### アセットを設定する

* `config.assets.enabled`は、アセットパイプラインを有効にするかどうかを指定します。デフォルトは`true`です。

* `config.assets.compress`は、コンパイル済みアセットを圧縮するかどうかを指定するフラグです。`config/environments/production.rb`では明示的にtrueに設定されています。

* `config.assets.css_compressor`は、CSSの圧縮に使用するプログラムを定義します。このオプションは、`sass-rails`を使用するとデフォルトで設定されます。このオプションでは`:yui`という一風変わったオプションを指定できます。これは`yui-compressor` gemのことです。

* `config.assets.js_compressor`は、JavaScriptの圧縮に使用するプログラムを定義します。指定できる値は`:closure`、`:uglifier`、`:yui`です。それぞれ`closure-compiler`、`uglifier`、`yui-compressor` gemに対応します。

* `config.assets.gzip`は、コンパイル済みアセットのgzip版作成をgzipされていない版の作成とともに有効にするかどうかを指定するフラグです。デフォルトは`true`です。

* `config.assets.paths`には、アセット探索用のパスを指定します。この設定オプションにパスを追加すると、アセットの検索先として追加されます。

* `config.assets.precompile`は、`application.css`と`application.js`以外に追加したいアセットがある場合に指定します。これらは`bin/rails assets:precompile`を実行するときに一緒にプリコンパイルされます。

* `config.assets.unknown_asset_fallback`は、アセットがパイプラインにない場合のアセットパイプラインの挙動の変更に使います（sprockets-rails 3.2.0以降を使う場合）。デフォルトは`true`です。

* `config.assets.prefix`はアセットを置くディレクトリを指定します。デフォルトは`/assets`です。

* `config.assets.digest`は、アセット名に使用するSHA256フィンガープリントを有効にするかどうかを指定します。デフォルトで`true`に設定されます。

* `config.assets.debug`は、デバッグ用にアセットの連結と圧縮をやめるかどうかを指定します。`development.rb`ではデフォルトで`true`に設定されます。

* `config.assets.version`はSHA256ハッシュ生成に使用されるオプション文字列です。この値を変更すると、すべてのアセットファイルが強制的にリコンパイルされます。

* `config.assets.compile`は、production環境での動的なSprocketsコンパイルをオンにするかどうかをtrue/falseで指定します。

* `config.assets.logger`はロガーを引数に取ります。このロガーは、Log4のインターフェイスか、Rubyの`Logger`クラスに従います。デフォルトでは、`config.logger`と同じ設定が使用されます。`config.assets.logger`を`false`に設定すると、アセットのログ出力がオフになります

* `config.assets.quiet`はアセットへのリクエストのログ出力を無効にします。デフォルトでは`development.rb`で`true`に設定されます。

### ジェネレータの設定

`config.generators`メソッドを使用して、Railsで使用されるジェネレータを変更できます。このメソッドはブロックを1つ取ります。

```ruby
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
```

ブロックで使用可能なメソッドの完全なリストは以下のとおりです。

* `assets`は、scaffoldを生成するかどうかを指定します。デフォルトは`true`です。
* `force_plural`は、モデル名を複数形にするかどうかを指定します。デフォルトは`false`です。
* `helper`はヘルパーを生成するかどうかを指定します。デフォルトは`true`です。

* `integration_tool`は、結合テストの生成に使う統合ツールを定義します。デフォルトは`:test_unit`です。
* `javascripts`は、生成時にJavaScriptファイルへのフックをオンにするかどうかを指定します。この設定は`scaffold`ジェネレータの実行中に使用されます。デフォルトは`true`です。
* `javascript_engine`は、アセット生成時に(coffeeなどで)使用するエンジンを設定します。デフォルトは`:js`です。
* `orm`は、使用するORM (オブジェクトリレーショナルマッピング) を指定します。デフォルトは`false`であり、この場合はActive Recordが使用されます。
* `resource_controller`は、`rails generate resource`の実行時にどのジェネレータを使用してコントローラを生成するかを指定します。デフォルトは`:controller`です。
* `resource_route`は、リソースのルーティング定義を生成すべきかどうかを定義します。デフォルトは`true`です。
* `scaffold_controller`は`resource_controller`と同じではありません。`scaffold_controller`は _scaffold_ でどのジェネレータを使用してコントローラを生成するか(`rails generate scaffold`の実行時)を指定します。デフォルトは`:scaffold_controller`です。
* `stylesheets`は、ジェネレータでスタイルシートのフックを行なうかどうかを指定します。この設定は`scaffold`ジェネレータの実行時に使用されますが、このフックは他のジェネレータでも使用されます。デフォルトは`true`です。
* `stylesheet_engine`は、アセット生成時に使用される、sassなどのスタイルシートエンジンを指定します。デフォルトは`:css`です。
* `scaffold_stylesheet`は、scaffoldされたリソースを生成するときに`scaffold.css`を作成するかどうかを指定します。デフォルトは`true`です。
* `test_framework`は、使用するテストフレームワークを指定します。デフォルトは`false`であり、この場合Minitestが使われます。
* `template_engine`はビューのテンプレートエンジン(ERBやHamlなど)を指定します。デフォルトは`:erb`です。

### ミドルウェアを設定する

どのRailsアプリの背後にも、いくつかの標準的なミドルウェアが配置されています。development環境では、以下の順序でミドルウェアを使用します。

* `ActionDispatch::SSL`はすべてのリクエストにHTTPSプロトコルを強制します。これは`config.force_ssl`を`true`にすると有効になります。渡すオプションは`config.ssl_options`で設定できます。
* `ActionDispatch::Static`は静的アセットを扱うために使います。`config.public_file_server.enabled`が`false`の場合は無効に設定されます。静的ディレクトリのインデックスファイルが`index`でない場合には、`config.public_file_server.index_name`を設定します。たとえば、ディレクトリへのリクエストを`index.html`ではなく`main.html`と扱うには、`config.public_file_server.index_name`を`"main"`に設定します。
* `ActionDispatch::Executor`はスレッドセーフなコード再読み込みに使います。これは`config.allow_concurrency`が`false`の場合に無効になり、`Rack::Lock`が読み込まれるようになります。`Rack::Lock`はアプリのミューテックスをラップするので、同時に1つのスレッドでしか呼び出されなくなります。
* `ActionDispatch::Static`は静的アセットで使用されます。`config.serve_static_assets`を`false`にするとオフになります。
* `Rack::Lock`は、アプリをミューテックスでラップし、1度に1つのスレッドでしか呼び出されないようにします。このミドルウェアは、`config.cache_classes`が`false`に設定されている場合のみ有効になります。
* `ActiveSupport::Cache::Strategy::LocalCache`は基本的なメモリバックアップ式キャッシュとして機能します。このキャッシュはスレッドセーフではなく、単一スレッド用の一時メモリキャッシュとして機能することのみを意図していることにご注意ください。
* `Rack::Runtime`は`X-Runtime`ヘッダーを設定します。このヘッダーには、リクエストの実行にかかる時間(秒)が含まれます。
* `Rails::Rack::Logger`は、リクエストが開始されたことをログに通知します。リクエストが完了すると、すべてのログをフラッシュします。
* `ActionDispatch::ShowExceptions`は、アプリから返されるすべての例外をrescueし、リクエストがローカルであるか`config.consider_all_requests_local`が`true`に設定されている場合に適切な例外ページを出力します。`config.action_dispatch.show_exceptions`が`false`に設定されていると、常に例外が出力されます。
* `ActionDispatch::RequestId`は、レスポンスで使用できる独自のX-Request-Idヘッダーを作成し、`ActionDispatch::Request#uuid`メソッドを有効にします。
* `ActionDispatch::RemoteIp`はIPスプーフィング攻撃が行われていないかどうかをチェックし、リクエストヘッダーから正しい`client_ip`を取得します。この設定は`config.action_dispatch.ip_spoofing_check`オプションと`config.action_dispatch.trusted_proxies`オプションで変更可能です。
* `Rack::Sendfile`は、bodyが1つのファイルから作成されているレスポンスをキャッチし、サーバー固有のX-Sendfileヘッダーに差し替えてから送信します。この動作は`config.action_dispatch.x_sendfile_header`で設定可能です。
* `ActionDispatch::Callbacks`は、リクエストに応答する前に、事前コールバックを実行します。
* `ActionDispatch::Cookies`はリクエストに対応するcookieを設定します。
* `ActionDispatch::Session::CookieStore`は、セッションをcookieに保存する役割を担います。`config.action_controller.session_store`の値を変更すると別のミドルウェアを使用できます。これに渡されるオプションは`config.action_controller.session_options`を使用して設定できます。
* `ActionDispatch::Flash`は`flash`キーを設定します。これは、`config.action_controller.session_store`に値が設定されている場合にのみ有効です。
* `Rack::MethodOverride`は、`params[:_method]`が設定されている場合にメソッドを上書きできるようにします。これは、HTTPでPATCH、PUT、DELETEメソッドを使用できるようにするミドルウェアです。
* `ActionDispatch::Head`は、HEADリクエストをGETリクエストに変換し、HEADリクエストが機能するようにします。

`config.middleware.use`メソッドを使用すると、上記以外に独自のミドルウェアを追加することもできます。

```ruby
config.middleware.use Magical::Unicorns
```

上の指定により、`Magical::Unicorns`ミドルウェアがスタックの最後に追加されます。あるミドルウェアの前に別のミドルウェアを追加したい場合は`insert_before`を使用します。

```ruby
config.middleware.insert_before ActionDispatch::Head, Magical::Unicorns
```

ミドルウェアはインデックスを用いて該当箇所に正確に挿入することもできます。たとえば、`Magical::Unicorns`ミドルウェアをスタックの最上位に挿入するには次のように設定します。

```ruby
config.middleware.insert_before 0, Magical::Unicorns
```

あるミドルウェアの後に別のミドルウェアを追加したい場合は`insert_after`を使用します。

```ruby
config.middleware.insert_after ActionDispatch::Head, Magical::Unicorns
```

これらのミドルウェアは、まったく別のものに差し替えることもできます。

```ruby
config.middleware.swap ActionController::Failsafe, Lifo::Failsafe
```

同様に、ミドルウェアをスタックから完全に取り除くこともできます。

```ruby
config.middleware.delete Rack::MethodOverride
```

### i18nを設定する

以下のオプションはすべて`i18n`(internationalization: 国際化)ライブラリ用のオプションです。

* `config.i18n.available_locales`は、アプリで利用できるロケールをホワイトリスト化します。デフォルトでは、ロケールファイルにあるロケールキーはすべて有効になりますが、新しいアプリの場合、通常は`:en`だけです。

* `config.i18n.default_locale`は、アプリのi18nで使用するデフォルトのロケールを設定します。デフォルトは`:en`です。

* `config.i18n.enforce_available_locales`がオンになっていると、`available_locales`リストで宣言されていないロケールはi18nに渡せなくなります。利用できないロケールがある場合は`i18n::InvalidLocale`例外が発生します。デフォルトは`true`です。このオプションは、ユーザー入力のロケールが不正である場合のセキュリティ対策であるため、特別な理由がない限り無効にしないでください。

* `config.i18n.load_path`は、ロケールファイルの探索パスを設定します。デフォルトは`config/locales/*.{yml,rb}`です。

* `config.i18n.fallbacks`は訳文がない場合のフォールバック動作を設定します。ここではオプションの3つの使い方を説明します。

     * デフォルトのロケールをフォールバック先として使う場合は次のように`true`を設定します。

     ```ruby
     config.i18n.fallbacks = true
     ```

     * ロケールの配列をフォールバック先に使う場合は次のようにします。

     ```ruby
     config.i18n.fallbacks = [:tr, :en]
     ```

     * ロケールごとに個別のフォールバックを設定することもできます。たとえば`:az`と`:de`に`:tr`を、`:da`に`:en`をそれぞれフォールバック先として指定する場合は、次のようにします。

     ```ruby
     config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
     #or
     config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }
     ```

### Active Recordを設定する

`config.active_record`には多くのオプションが含まれています。

* `config.active_record.logger`は、Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは以後作成されるすべての新しいデータベース接続に渡されます。Active Recordのモデルクラスまたはモデルインスタンスに対して`logger`メソッドを呼び出すと、このロガーを取り出せます。ログ出力を無効にするには`nil`を設定します。

* `config.active_record.primary_key_prefix_type`は、主キーカラムの命名法を変更するのに使用します。Railsのデフォルトでは、主キーカラムの名前に`id`が使用されます (なお`id`にしたい場合は値を設定する必要はありません)。`id`以外に以下の2つを指定できます。
    * `:table_name`を指定すると、たとえばCustomerクラスの主キーは`customerid`になります
    * `:table_name_with_underscore`を指定すると、たとえばCustomerクラスの主キーは`customer_id`になります

* `config.active_record.table_name_prefix`は、テーブル名の冒頭にグローバルに追加したい文字列を指定します。たとえば`northwest_`を指定すると、Customerクラスは`northwest_customers`をテーブルとして探します。デフォルトは空文字列です。

* `config.active_record.table_name_suffix`はテーブル名の後ろにグローバルに追加したい文字列を指定します。たとえば`_northwest`を指定すると、Customerは`customers_northwest`をテーブルとして探します。デフォルトは空文字列です。

* `config.active_record.schema_migrations_table_name`は、スキーママイグレーションテーブルの名前として使用する文字列を指定します。

* `config.active_record.pluralize_table_names`は、Railsが探すデータベースのテーブル名を単数形にするか複数形にするかを指定します。`true`に設定すると、Customerクラスが使用するテーブル名は複数形の`customers`になります(デフォルト)。`false`に設定すると、Customerクラスが使用するテーブル名は単数形の`customer`になります。

* `config.active_record.default_timezone`は、データベースから日付・時刻を取り出した際のタイムゾーンを`Time.local` (`:local`を指定した場合)と`Time.utc` (`:utc`を指定した場合)のどちらにするかを指定します。デフォルトは`:utc`です。

* `config.active_record.schema_format`は、データベーススキーマをファイルに書き出す際のフォーマットを指定します。デフォルトは`:ruby`で、データベースには依存せず、マイグレーションに依存します。`:sql`を指定するとSQL文で書き出されますが、この場合潜在的にデータベースに依存する可能性があります。

* `config.active_record.error_on_ignored_order`は、バッチクエリの実行中にクエリの順序が無視された場合にエラーをraiseすべきかどうかを指定します。オプションは`true`（エラーをraise）または`false`（警告）で、デフォルトは`false`です。

* `config.active_record.timestamped_migrations`は、マイグレーションファイル名にシリアル番号とタイムスタンプのどちらを与えるかを指定します。デフォルトはtrueで、タイムスタンプが使用されます。開発者が複数の場合は、タイムスタンプの使用をお勧めします。

* `config.active_record.lock_optimistically`は、Active Recordで楽観的ロック(optimistic locking)を使用するかどうかを指定します。デフォルトは`true`(使用する)です。

* `config.active_record.cache_timestamp_format`は、キャッシュキーに含まれるタイムスタンプ値の形式を指定します。デフォルトは`:nsec`です。

* `config.active_record.record_timestamps`は、モデルで発生する`create`操作や`update`操作にタイムスタンプを付けるかどうかを指定する論理値です。デフォルト値は`true`です。

* `config.active_record.partial_writes`は、部分書き込みを行なうかどうか(「dirty」とマークされた属性だけを更新するか)を指定する論理値です。データベースで部分書き込みを使用する場合は、`config.active_record.lock_optimistically`で楽観的ロックも使用する必要があります。これは、同時更新が行われた場合に、読み出しの状態が古い情報に基づいて属性に書き込まれる可能性があるためです。デフォルト値は`true`です。

* `config.active_record.attribute_types_cached_by_default`は、`ActiveRecord::AttributeMethods`が読み出し時にデフォルトでキャッシュする属性の種類を指定します。デフォルトは`[:datetime, :timestamp, :time, :date]`です。

* `config.active_record.maintain_test_schema`は、テスト実行時にActive Recordがテスト用データベーススキーマを`db/schema.rb`(または`db/structure.sql`)に基いて最新の状態にするかどうかを指定します。デフォルト値は`true`です。

* `config.active_record.dump_schema_after_migration`は、マイグレーション実行時にスキーマダンプ(`db/schema.rb`または`db/structure.sql`)を行なうかどうかを指定します。このオプションは、Railsが生成する`config/environments/production.rb`では`false`に設定されます。このオプションが無指定の場合は、デフォルトの`true`が指定されます。

* `config.active_record.dump_schemas`は、`db:structure:dump`の呼び出し時にデータベーススキーマをダンプするかどうかを指定します。使えるオプションは、`:schema_search_path`（デフォルト、`schema_search_path`内のすべてのスキーマをダンプ）、`:all`（`schema_search_path`と無関係にすべてのスキーマをダンプ）、またはカンマ区切りのスキーマの文字列です。

* `config.active_record.belongs_to_required_by_default`は、`belongs_to`関連付けが存在しない場合にレコードのバリデーションを失敗させるかどうかをbooleanで指定します。

* `config.active_record.warn_on_records_fetched_greater_than`は、クエリ結果のサイズで警告を出す場合のスレッショルドを設定します。あるクエリから返されるレコード数がこのスレッショルドを超えると、警告がログに出力されます。これは、メモリ肥大化の原因となっている可能性のあるクエリを特定するのに利用できます。

* `config.active_record.index_nested_attribute_errors`は、ネストした`has_many`関連付けのエラーをインデックス付きでエラー表示するかどうかを指定します。デフォルトは`false`です。

* `config.active_record.use_schema_cache_dump`は、（`bin/rails db:schema:cache:dump`で生成された）`db/schema_cache.yml`のスキーマ情報を、データベースにクエリを送信しなくてもユーザーが取得できるようにするかどうかを指定します。デフォルトは`true`です。

MySQLアダプターを使用すると、以下の設定オプションが1つ追加されます。


* `ActiveRecord::ConnectionAdapters::MysqlAdapter.emulate_booleans`は、Active Recordがすべての`tinyint(1)`カラムをデフォルトでbooleanと認識するかどうかを指定します。デフォルトは`true`です。

* `ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer`は、SQLite3データベースのboolean値を1と0または`t`と`f`のどちらで保存するかどうかを指定します。`ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer`を`false`に設定するのは非推奨です。以前のSQLiteデータベースはboolean値のシリアライズに`t`と`f`を用いていたので、このフラグを`true`にする場合は、その前に古いデータを1と0（ネイティブのbooleanシリアライズ）に変換しておかなければなりません。以下のようなコードを実行するrakeタスクをセットアップすることですべてのモデルやbooleanカラムを変換できます。

```ruby
ExampleModel.where("boolean_column = 't'").update_all(boolean_column: 1)
ExampleModel.where("boolean_column = 'f'").update_all(boolean_column: 0)
```

その後`application.rb`に以下を追加してこのフラグを`true`に設定しなければなりません。

```ruby
    Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true
```

スキーマダンパーは以下のオプションを追加します。

* `ActiveRecord::SchemaDumper.ignore_tables`はテーブル名の配列を1つ引数に取ります。どのスキーマファイルにも _含めたくない_ テーブル名がある場合はこの配列にテーブル名を含めます。この設定は、`config.active_record.schema_format == :ruby`で「ない」場合は無視されます。

### Action Controllerを設定する

`config.action_controller`には多数の設定が含まれています。

* `config.action_controller.asset_host`はアセットを置くためのホストを設定します。これは、アセットをホストする場所としてアプリサーバーの代りにCDN(コンテンツ配信ネットワーク)を使用したい場合に便利です。

* `config.action_controller.perform_caching`は、Action Controllerコンポーネントが提供するキャッシュ機能をアプリで使うかどうかを指定します。developmentモードでは`false`、productionモードでは`true`に設定します。

* `config.action_controller.default_static_extension`は、キャッシュされたページに与える拡張子を指定します。デフォルトは`.html`です。

* `config.action_controller.include_all_helpers`は、すべてのビューヘルパーをあらゆる場所で使えるようにするか、対応するコントローラのスコープに限定するかを設定します。`false`に設定すると、たとえば`UsersHelper`は`UsersController`のいち部としてレンダリングされるビューでしか使えなくなります。`true`に設定すると、この`UsersHelper`はどこからでも使えるようになります。デフォルト設定の振る舞い（このオプションに`true`や`false`が明示的に設定されていない場合）は、どのコントローラでもあらゆるビューヘルパーが使えるようになります。

* `config.action_controller.logger`は、Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Controllerからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_controller.request_forgery_protection_token`は、RequestForgery対策用のトークンパラメータ名を設定します。`protect_from_forgery`を呼び出すと、デフォルトで`:authenticity_token`が設定されます。

* `config.action_controller.allow_forgery_protection`は、CSRF保護をオンにするかどうかを指定します。testモードではデフォルトで`false`に設定され、それ以外では`true`に設定されます。

* `config.action_controller.forgery_protection_origin_check`は、CSRFの追加対策としてHTTPの`Origin`ヘッダーがサイトのoriginと合っていることをチェックすべきかどうかを設定します。

* `config.action_controller.per_form_csrf_tokens`は、CSRFトークンの正当性をそれらが生成されたメソッドやアクションに対してのみ認めるかどうかを設定します。

* `config.action_controller.default_protect_from_forgery`は、フォージェリ対策を`ActionController:Base`に追加するかどうかを指定します。これはデフォルトでは`false`ですが、Rails 5.2でデフォルト設定を読み込むと有効になります。

* `config.action_controller.relative_url_root`は、[サブディレクトリへのデプロイ](configuring.html#サブディレクトリにデプロイする-相対urlルートの使用)を行うことをRailsに伝えるために使用できます。デフォルトは`ENV['RAILS_RELATIVE_URL_ROOT']`です。

* `config.action_controller.permit_all_parameters`は、マスアサインメントされるすべてのパラメータをデフォルトで許可することを設定します。デフォルト値は`false`です。

* `config.action_controller.action_on_unpermitted_parameters`は、明示的に許可されていないパラメータが見つかった場合にログ出力または例外発生を行なうかどうかを指定します。このオプションは、`:log`または`:raise`を指定すると有効になります。test環境とdevelopment環境でのデフォルトは`:log`であり、それ以外の環境では`false`が設定されます。

* `config.action_controller.always_permitted_parameters`は、デフォルトで許可されるホワイトリストパラメータのリストを設定します。デフォルト値は `['controller', 'action']`です。
 
* `config.action_controller.enable_fragment_cache_logging`は、フラグメントキャッシュの読み書きのログを次のようにverbose形式で出力するかどうかを指定します。

```
Read fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/d0bdf2974e1ef6d31685c3b392ad0b74 (0.6ms)
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Write fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/3b4e249ac9d168c617e32e84b99218b5 (1.1ms)
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```

デフォルトは`false`で、以下のように出力されます。

```
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```
    
### Action Dispatchを設定する

* `config.action_dispatch.session_store`はセッションデータのストア名を設定します。デフォルトのストア名は`:cookie_store`です。この他に`:active_record_store`、`:mem_cache_store`、またはカスタムクラスの名前を指定できます。

* `config.action_dispatch.default_headers`は、HTTPヘッダーで使用されるハッシュです。このヘッダーはデフォルトですべてのレスポンスに設定されます。このオプションは、デフォルトでは以下のように設定されます。

    ```ruby
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff'
    }
    ```

* `config.action_dispatch.default_charset`はすべてのレンダリングで使うデフォルトの文字セットを指定します。デフォルトは`nil`です。

* `config.action_dispatch.tld_length`は、アプリで使用するトップレベルドメイン(TLD) の長さを指定します。デフォルトは`1`です。

* `config.action_dispatch.ignore_accept_header`は、リクエストのヘッダーを受け付けるかどうかを指定します。デフォルトは`false`です。

* `config.action_dispatch.x_sendfile_header`は、サーバー固有のX-Sendfileヘッダーを指定します。これは、サーバーからの送信を加速するのに有用です。たとえば、'X-Sendfile'をApache向けに設定できます。

* `config.action_dispatch.http_auth_salt`は、HTTP Authのsalt値(訳注: ハッシュの安全性を強化するために加えられるランダムな値)を設定します。デフォルトは`'http authentication'`です。

* `config.action_dispatch.signed_cookie_salt`は、署名済みcookie用のsalt値を設定します。デフォルトは`'signed cookie'`です。

* `config.action_dispatch.encrypted_cookie_salt`は、暗号化済みcookie用のsalt値を設定します。デフォルトは`'encrypted cookie'`です。

* `config.action_dispatch.encrypted_signed_cookie_salt`は、署名暗号化済みcookie用のsalt値を設定します。デフォルトは`'signed encrypted cookie'`です。

* `config.action_dispatch.authenticated_encrypted_cookie_salt`は、認証された暗号化済みcookieのsalt値を設定します。デフォルトは`'authenticated encrypted cookie'`です。

* `config.action_dispatch.encrypted_cookie_cipher`は、暗号化済みcookieに使う暗号化方式を設定します。デフォルトは`"aes-256-gcm"`です。

* `config.action_dispatch.signed_cookie_digest`は、署名済みcookieに使うダイジェスト方式を設定します。デフォルトは`"SHA1"`です。

* `config.action_dispatch.cookies_rotations`は、署名暗号化済みcookieの秘密情報、暗号化方式、ダイジェスト方式のローテーションを行います。

* `config.action_dispatch.perform_deep_munge`は、パラメータに対して`deep_munge`メソッドを実行すべきかどうかを指定します。詳細については[セキュリティガイド](security.html#安全でないクエリ生成)を参照してください。デフォルトは`true`です。

* `config.action_dispatch.rescue_responses`は、HTTPステータスに割り当てる例外を設定します。ここには、例外とステータスのさまざまなペアを指定したハッシュを1つ指定可能です。デフォルトの定義は次のようになっています。

   ```ruby
   config.action_dispatch.rescue_responses = {
    'ActionController::RoutingError'               => :not_found,
    'AbstractController::ActionNotFound'           => :not_found,
    'ActionController::MethodNotAllowed'           => :method_not_allowed,
    'ActionController::UnknownHttpMethod'          => :method_not_allowed,
    'ActionController::NotImplemented'             => :not_implemented,
    'ActionController::UnknownFormat'              => :not_acceptable,
    'ActionController::InvalidAuthenticityToken'   => :unprocessable_entity,
    'ActionController::InvalidCrossOriginRequest'  => :unprocessable_entity,
    'ActionDispatch::Http::Parameters::ParseError' => :bad_request,
    'ActionController::BadRequest'                 => :bad_request,
    'ActionController::ParameterMissing'           => :bad_request,
    'Rack::QueryParser::ParameterTypeError'        => :bad_request,
    'Rack::QueryParser::InvalidParameterError'     => :bad_request,
    'ActiveRecord::RecordNotFound'                 => :not_found,
    'ActiveRecord::StaleObjectError'               => :conflict,
    'ActiveRecord::RecordInvalid'                  => :unprocessable_entity,
    'ActiveRecord::RecordNotSaved'                 => :unprocessable_entity
   }
   ```

設定されていない例外はすべて500 Internel Server Errorに割り当てられます。
      
* `ActionDispatch::Callbacks.before`には、リクエストより前に実行したいコードブロックを1つ引数として与えます。

* `ActionDispatch::Callbacks.after`には、リクエストの後に実行したいコードブロックを1つ引数として与えます。

### Action Viewを設定する

`config.action_view`にもわずかながら設定があります。

* `config.action_view.field_error_proc`は、Active Modelで発生したエラーの表示に使用するHTMLジェネレータを指定します。デフォルトは以下のとおりです。

    ```ruby
    Proc.new do |html_tag, instance|
      %Q(<div class="field_with_errors">#{html_tag}</div>).html_safe
    end
    ```

* `config.action_view.default_form_builder`は、Railsでデフォルトで使用するフォームビルダーを指定します。デフォルトは、`ActionView::Helpers::FormBuilder`です。フォームビルダーを初期化処理の後に読み込みたい場合(こうすることでdevelopmentモードではフォームビルダーがリクエストのたびに再読込されます)、`String`として渡すこともできます。

* `config.action_view.logger`は、Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数としてとります。このロガーは、Action Viewからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_view.erb_trim_mode`は、ERBで使用するトリムモードを指定します。デフォルトは`'-'`で、`<%= -%>`または`<%= =%>`の場合に末尾スペースを削除して改行します。詳細については[Erubisドキュメント](http://www.kuwata-lab.com/erubis/users-guide.06.html#topics-trimspaces)を参照してください。

* `config.action_view.embed_authenticity_token_in_remote_forms`は、フォームで`remote: true`を使用した場合の`authenticity_token`のデフォルトの動作を設定します。デフォルトではfalseであり、この場合リモートフォームには`authenticity_token`フォームが含まれません。これはフォームでフラグメントキャッシュを使用している場合に便利です。リモートフォームは`meta`タグから認証を受け取るので、JavaScriptの動作しないブラウザをサポートしなければならないのでなければトークンの埋め込みは不要です。JavaScriptが動かないブラウザのサポートが必要な場合は、`authenticity_token: true`をフォームオプションとして渡すか、この設定を`true`にします。

* `config.action_view.prefix_partial_path_with_controller_namespace`は、名前空間化されたコントローラから出力されたテンプレートにあるサブディレクトリから、パーシャル(部分テンプレート)を探索するかどうかを指定します。たとえば、`Admin::PostsController`というコントローラがあり、以下のテンプレートを出力するとします。

    ```erb
    <%= render @post %>
    ```

このデフォルト設定は`true`であり、`/admin/posts/_post.erb`にあるパーシャルを使用しています。この値を`false`にすると、`/posts/_post.erb`が描画されます。この動作は、`PostsController`などの名前空間化されていないコントローラで描画した場合と同じです。

* `config.action_view.raise_on_missing_translations`は、i18nで訳文が失われている場合にエラーを発生するかどうかを指定します。

* `config.action_view.automatically_disable_submit_tag`は、クリック時に`submit_tag`を自動的に無効にするべきかどうかを指定します。デフォルトは`true`です。

* `config.action_view.debug_missing_translation`は、訳文の存在しないキーを`<span>`タグで囲むかどうかを指定します。デフォルトは`true`です。

* `config.action_view.form_with_generates_remote_forms`は、`form_with`でリモートフォームを生成するかどうかを指定します。デフォルトは`true`です。

* `config.action_view.form_with_generates_ids`は、`form_with`でidを生成するかどうかを指定します。デフォルトは`true`です。

### Action Mailerを設定する

`config.action_mailer`には多数の設定オプションがあります。

* `config.action_mailer.logger`は、Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Mailerからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_mailer.smtp_settings`は、`:smtp`配信方法を詳細に設定するのに使用できます。これはオプションのハッシュを引数に取り、以下のどのオプションでも含めることができます。
    * `:address` - リモートのメールサーバーを指定します。デフォルトの"localhost"設定から変更します。
    * `:port` - 使用するメールサーバーのポートが25番でないのであれば(めったにないと思いますが)、ここで対応できます。
    * `:domain` - HELOドメインの指定が必要な場合に使用します。
    * `:user_name` - メールサーバーで認証が要求される場合は、ここでユーザー名を設定します。
    * `:password` - メールサーバーで認証が要求される場合は、ここでパスワードを設定します。
    * `:authentication` - メールサーバーで認証が要求される場合は、ここで認証の種類を指定します。`:plain`、`:login`、`:cram_md5`のいずれかのシンボルを指定できます。
    * `:enable_starttls_auto` - 利用するSMTPサーバーでSTARTTLSが有効かどうかを検出し、可能な場合は使います。デフォルトは`true`です。
    * `:openssl_verify_mode` - TLSを使う場合、OpenSSLの認証方法を設定できます。これは、自己署名証明書やワイルドカード証明書が必要な場合に便利です。OpenSSLの検証定数である`:none`や`:peer`を指定することも、`OpenSSL::SSL::VERIFY_NONE`定数や`OpenSSL::SSL::VERIFY_PEER`定数を直接指定することもできます。
    * `:ssl/:tls` - SMTP接続でSMTP/TLS（SMTPS: SMTP over direct TLS connection）を有効にします。
    
* `config.action_mailer.sendmail_settings`は、`:sendmail`配信方法を詳細に設定するのに使用できます。これはオプションのハッシュを引数に取り、以下のどのオプションでも含めることができます。
    * `:location` - sendmail実行ファイルの場所。デフォルトは`/usr/sbin/sendmail`です。
    * `:arguments` - コマンドラインに与える引数。デフォルトは`-i`です。

* `config.action_mailer.raise_delivery_errors`は、メールの配信が完了しなかった場合にエラーを発生させるかどうかを指定します。デフォルトは`true`です。

* `config.action_mailer.delivery_method`は、配信方法を指定します。デフォルトは`:smtp`です。詳細については、[Action Mailerガイド](action_mailer_basics.html#action-mailerを設定する)を参照してください。

* `config.action_mailer.perform_deliveries`は、メールを実際に配信するかどうかを指定します。デフォルトは`true`です。テスト時にメール送信を抑制するのに便利です。

* `config.action_mailer.default_options`は、Action Mailerのデフォルトを設定します。これは、メイラーごとに`from`や`reply_to`などを設定します。デフォルトは以下のとおりです。

    ```ruby
    mime_version:  "1.0",
    charset:       "UTF-8",
    content_type: "text/plain",
    parts_order:  ["text/plain", "text/enriched", "text/html"]
    ```

    ハッシュを1つ指定してオプションを追加することもできます。

    ```ruby
    config.action_mailer.default_options = {
      from: "noreply@example.com"
    }
    ```

* `config.action_mailer.observers`は、メールを配信したときに通知を受けるオブザーバーを指定します。

    ```ruby
    config.action_mailer.observers = ["MailObserver"]
    ```

* `config.action_mailer.interceptors`は、メールを送信する前に呼び出すインターセプタを登録します。

    ```ruby
    config.action_mailer.interceptors = ["MailInterceptor"]
    ```

* `config.action_mailer.preview_path`は、メイラーのプレビュー場所を指定します
 
    ```ruby
    config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
    ```
 
* `config.action_mailer.show_previews`は、メイラーのプレビューを有効または無効にします。デフォルトではdevelopment環境で`true`です。
 
    ```ruby
    config.action_mailer.show_previews = false
    ```
 
* `config.action_mailer.deliver_later_queue_name`は、メイラーで使うキュー名を指定します。デフォルトは`mailers`です。

* `config.action_mailer.perform_caching`は、メイラーのテンプレートでフラグメントキャッシュを有効にするべきかどうかを指定します。デフォルトではすべての環境で`false`です。

### Active Supportを設定する

Active Supportにもいくつかの設定オプションがあります。

* `config.active_support.bare`は、Rails起動時に`active_support/all`の読み込みを行なうかどうかを指定します。デフォルトは`nil`であり、この場合`active_support/all`は読み込まれます。

* `config.active_support.test_order`は、テストケースの実行順序を指定します。`:random`か`:sorted`を指定可能で、デフォルトは`:random`です。

* `config.active_support.escape_html_entities_in_json`は、JSONシリアライズに含まれるHTMLエンティティをエスケープするかどうかを指定します。デフォルトは`true`です。

* `config.active_support.use_standard_json_time_format`は、ISO 8601フォーマットに従った日付のシリアライズを行なうかどうかを指定します。デフォルトは`true`です。

* `config.active_support.time_precision`は、JSONエンコードされた時間値の精度を指定します。デフォルトは`3`です。

* `ActiveSupport::Logger.silencer`を`false`に設定すると、ブロック内でのログ出力を抑制する機能がオフになります。デフォルト値は`true`です。

* `ActiveSupport::Cache::Store.logger`は、キャッシュストア操作で使用するロガーを指定します。

* `ActiveSupport::Deprecation.behavior`は、`config.active_support.deprecation`に対するもう一つのセッターであり、Railsの非推奨警告メッセージの表示方法を設定します。

* `ActiveSupport::Deprecation.silence`はブロックを1つ引数に取り、すべての非推奨警告メッセージを抑制します。

* `ActiveSupport::Deprecation.silenced`は、非推奨警告メッセージを表示するかどうかを指定します。

### Active Jobを設定する

`config.active_job`では以下の設定オプションが利用できます。

* `config.active_job.queue_adapter`は、キューのバックエンドに用いるアダプタを設定します。デフォルトのアダプタは`:async`です。最新の組み込みアダプタについては[ActiveJob::QueueAdapters API documentation](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html)を参照してください。

    ```ruby
    # 必ずGemfileにアダプタのgemを追加し、
    # アダプタ固有のインストール/デプロイ方法に従うこと
    config.active_job.queue_adapter = :sidekiq
    ```

* `config.active_job.default_queue_name`はデフォルトのキュー名を変更できます。デフォルトは`"default"`です。

    ```ruby
    config.active_job.default_queue_name = :medium_priority
    ```

* `config.active_job.queue_name_prefix`は、すべてのジョブ名の前に付けられるプレフィックスを設定します（スペースは含めません）。デフォルトは空欄なので何も追加されません。

以下の設定では、production実行時に指定のジョブが`production_high_priority`キューに送信されます。

    ```ruby
    config.active_job.queue_name_prefix = Rails.env
    ```

    ```ruby
    class GuestsCleanupJob < ActiveJob::Base
      queue_as :high_priority
      #....
    end
    ```

* `config.active_job.queue_name_delimiter`のデフォルト値は`'_'`です。`queue_name_prefix`が設定されている場合は、キュー名とプレフィックスの結合に`queue_name_delimiter`が使われます。

以下の設定では、指定のジョブが`video_server.low_priority`キューに送信されます。

    ```ruby
    # この区切り文字を使うにはprefixを設定しなければならない
    config.active_job.queue_name_prefix = 'video_server'
    config.active_job.queue_name_delimiter = '.'
    ```

    ```ruby
    class EncoderJob < ActiveJob::Base
      queue_as :low_priority
      #....
    end
    ```

* `config.active_job.logger`は、Active Jobのログ情報に使うロガーとして、Log4rのインターフェイスに準拠したロガーか、デフォルトのRubyロガーを指定できます。このロガーは、Active JobのクラスかActive Jobのインスタンスで`logger`を呼び出すことで取り出せます。ログ出力を無効にするには`nil`を設定します。

### Action Cableを設定する

* `config.action_cable.url`は、Action CableサーバーがホストされているURLの文字列を指定します。Action Cableサーバーがメインのアプリと別になっている場合に使う可能性があります。
* `config.action_cable.mount_path`は、Action Cableをメインサーバープロセスのいち部としてマウントする場所を文字列で指定します。デフォルトは`/cable`です。`nil`を設定すると、Action Cableは通常のRailsサーバーの一部としてマウントされなくなります。

### データベースを設定する

ほぼすべてのRailsアプリは、何らかの形でデータベースにアクセスします。データベースへの接続は、環境変数`ENV['DATABASE_URL']`を設定するか、`config/database.yml`というファイルを設定することで行えます。

`config/database.yml`ファイルを使用することで、データベース接続に必要なすべての情報を指定できます。

```yaml
development:
  adapter: postgresql
  database: blog_development
  pool: 5
```

この設定を使用すると、`postgresql`を使用して、`blog_development`という名前のデータベースに接続します。同じ接続情報をURL化して、以下のように環境変数に保存することもできます。

```ruby
> puts ENV['DATABASE_URL']
postgresql://localhost/blog_development?pool=5
```

`config/database.yml`ファイルには、Railsがデフォルトで実行できる3つの異なる環境を記述するセクションが含まれています。

* `development`環境は、ローカルの開発環境でアプリと手動でやりとりを行うために使用されます。
* `test`環境は、自動化されたテストを実行するために使用されます。
* `production`環境は、アプリを世界中に公開する本番で使用されます。

必要であれば、`config/database.yml`の内部でURLを直接指定することもできます。

```
development:
  url: postgresql://localhost/blog_development?pool=5
```

`config/database.yml`ファイルにはERBタグ`<%= %>`を含めることができます。タグ内に記載されたものはすべてRubyのコードとして評価されます。このタグを使用して、環境変数から接続情報を取り出したり、接続情報の生成に必要な計算を行なうこともできます。


TIP: データベースの接続設定を手動で更新する必要はありません。アプリのジェネレータのオプションを表示してみると、`--database`というオプションがあるのがわかります。このオプションでは、リレーショナルデータベースで最もよく使用されるアダプタをリストから選択できます。さらに、`cd .. && rails new blog --database=mysql`のようにするとジェネレータを繰り返し実行することもできます。`config/database.yml`ファイルが上書きされることを確認すると、アプリの設定はSQLite用からMySQL用に変更されます。よく使用されるデータベース接続方法の詳細な例については、次で説明します。


### 接続設定

データベース接続の設定方法は`config/database.yml`による方法と環境変数による方法の2とおりあるので、この2つがどのように相互作用するかを理解しておくことが重要です。

`config/database.yml`ファイルの内容が空で、かつ環境変数`ENV['DATABASE_URL']`が設定されている場合、データベースへの接続には環境変数が使用されます。

```
$ cat config/database.yml

$ echo $DATABASE_URL
postgresql://localhost/my_database
```

`config/database.yml`ファイルがあり、環境変数`ENV['DATABASE_URL']`が設定されていない場合は、`config/database.yml`ファイルを使用してデータベース接続が行われます。

```
$ cat config/database.yml
development:
  adapter: postgresql
  database: my_database
  host: localhost

$ echo $DATABASE_URL
```

`config/database.yml`ファイルと環境変数`ENV['DATABASE_URL']`が両方存在する場合、両者の設定はマージして使用されます。以下のいくつかの例を参照して理解を深めてください。

提供された接続情報が重複している場合、環境変数が優先されます。

```
$ cat config/database.yml
development:
  adapter: sqlite3
  database: NOT_my_database
  host: localhost

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database"}}
```

上の実行結果で使用されている接続情報は、`ENV['DATABASE_URL']`の内容と一致しています。

提供された複数の情報が重複しておらず、競合している場合も、常に環境変数の接続設定が優先されます。

```
$ cat config/database.yml
development:
  adapter: sqlite3
  pool: 5

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database", "pool"=>5}}
```

poolは`ENV['DATABASE_URL']`で提供される情報に含まれていないので、マージされています。adapterは重複しているので、`ENV['DATABASE_URL']`の接続情報が優先されています。

`ENV['DATABASE_URL']`の情報よりもdatabase.ymlの情報を優先する唯一の方法は、database.ymlで`"url"`サブキーを使用して明示的にURL接続を指定することです。

```
$ cat config/database.yml
development:
  url: sqlite3:NOT_my_database

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"sqlite3", "database"=>"NOT_my_database"}}
```

今度は`ENV['DATABASE_URL']`の接続情報は無視されました。アダプタとデータベース名が異なります。

`config/database.yml`にはERBを記述できるので、database.yml内で明示的に`ENV['DATABASE_URL']`を使用するのが最善の方法です。これは特にproduction環境で有用です。データベース接続のパスワードのような秘密情報をGitなどのソースコントロールに直接登録することは避けなければならないからです。

```
$ cat config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
```

以上の説明で動作が明らかになりました。接続情報は絶対にdatabase.ymlに直接書かず、常に`ENV['DATABASE_URL']`に保存したものを利用してください。

#### SQLite3データベースを設定する

Railsには[SQLite3](http://www.sqlite.org)のサポートがビルトインされています。SQLiteは軽量かつ専用サーバーの不要なデータベースアプリです。SQLiteは開発用・テスト用であれば問題なく使用できますが、本番での使用には耐えられない可能性があります。Railsで新規プロジェクトを作成するとデフォルトでSQLiteが指定されますが、これはいつでも後から変更できます。

以下はデフォルトの接続設定ファイル(`config/database.yml`)に含まれる、開発環境用の接続設定です。

```yaml
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
```

NOTE: Railsでデータ保存用にSQLite3データベースが採用されているのは、設定なしですぐに使用できるからです。RailsではSQLiteに代えてMySQL（MariaDB含む）やPostgreSQLなども使えます。また、データベース接続用のプラグインが多数あります。production環境で何らかのデータベースを使用する場合、そのためのアダプタはたいていの場合探せば見つかります。

#### MySQLやMariaDBデータベースを設定する

Rails同梱のSQLite3に代えてMySQLやMariaDBなどを採用した場合、`config/database.yml`の記述方法を少し変更します。developmentセクションの記述は以下のようになります。

```yaml
development:
  adapter: mysql2
  encoding: utf8
  database: blog_development
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
```

ユーザー名root、パスワードなしでdevelopment環境のデータベースに接続できれば、上の設定で接続できるはずです。接続できない場合は、`development`セクションのユーザー名またはパスワードを適切なものに変更してください。

#### PostgreSQLデータベースを設定する

PostgreSQLを採用した場合は、`config/database.yml`の記述は以下のようになります。

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: blog_development
  pool: 5
```

PostgreSQLのPrepared Statementsはデフォルトでオンになります。`prepared_statements`を`false`に設定することでPrepared Statementsをオフにできます。

```yaml
production:
  adapter: postgresql
  prepared_statements: false
```

Prepared Statementsをオンにすると、Active Recordはデフォルトでデータベース接続ごとに最大`1000`までのPrepared Statementsを作成します。この数値を変更したい場合は`statement_limit`に別の数値を指定します。

```
production:
  adapter: postgresql
  statement_limit: 200
```

Prepared Statementsの使用量の増大は、そのままデータベースで必要なメモリー量の増大につながります。PostgreSQLデータベースのメモリー使用量が上限に達した場合は、`statement_limit`の値を小さくするかPrepared Statementsをオフにしてください。

#### JRubyプラットフォームでSQLite3データベースを設定する

JRuby環境でSQLite3を採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcsqlite3
  database: db/development.sqlite3
```

#### JRubyプラットフォームでMySQLやMariaDBのデータベースを使う

JRuby環境でMySQLやMariaDBなどを採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcmysql
  database: blog_development
  username: root
  password:
```

#### JRubyプラットフォームでPostgreSQLデータベースを使う

JRuby環境でPostgreSQLを採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcpostgresql
  encoding: unicode
  database: blog_development
  username: blog
  password:
```

`development`セクションのユーザー名とパスワードは適切なものに置き換えてください。

### Rails環境を作成する

Railsにデフォルトで備わっている環境は、"development"、"test"、"production"の3つです。通常はこの3つの環境で事足りますが、場合によっては環境を追加したくなることもあると思います。

たとえば、production環境をミラーコピーしたサーバーがあるが、テスト目的でのみ使用したいという場合を想定してみましょう。このようなサーバーは通常「ステージングサーバー(staging server)」と呼ばれます。"staging"環境をサーバーに追加したいのであれば、`config/environments/staging.rb`というファイルを作成するだけで済みます。その際にはなるべく`config/environments`にある既存のファイルを流用し、必要な部分のみを変更するようにしてください。

このようにして追加された環境は、デフォルトの3つの環境と同じように利用できます。`rails server -e staging`を実行すればステージング環境でサーバーを起動でき、`rails console -e staging`や`Rails.env.staging?`なども動作するようになります。


### サブディレクトリにデプロイする (相対URLルートの使用)

Railsアプリの実行は、アプリのルートディレクトリ(`/`など)で行なうことが前提となっています。この節では、アプリをディレクトリの下で実行する方法について説明します。

ここでは、アプリを"/app1"ディレクトリにデプロイしたいとします。これを行なうには、適切なルーティングを生成できるディレクトリをRailsに指示する必要があります。

```ruby
config.relative_url_root = "/app1"
```

あるいは、`RAILS_RELATIVE_URL_ROOT`環境変数に設定することもできます。

これで、リンクが生成される時に"/app1"がディレクトリ名の前に追加されます。

#### Passengerを使う

Passengerを使用すると、アプリをサブディレクトリで実行するのが容易になります。設定方法の詳細については、[passengerマニュアル](https://www.phusionpassenger.com/library/deploy/apache/deploy/ruby/#deploying-an-app-to-a-sub-uri-or-subdirectory)を参照してください。

#### リバースプロキシを使う

リバースプロキシを用いるアプリをデプロイすることで、従来のデプロイと比べて確実なメリットが得られます。アプリで必要なコンポーネントの層が追加され、サーバーを制御しやすくなります。

現代的なWebサーバーの多くは、キャッシュサーバーやアプリケーションサーバーなどのバランシングにプロキシサーバーを用いています。

[Unicorn](http://unicorn.bogomips.org/)は、リバースプロキシの背後で実行されるそうしたアプリケーションサーバーの1つです。

この場合、NGINXやApacheなどのプロキシサーバーを設定して、アプリケーションサーバー（ここではUnicorn）からの接続を受け付けるようにする必要があります。Unicornは、デフォルトでTCP接続のポート8000をリッスンしますが、このポート番号を変更したりソケットを用いるように設定することもできます。

詳しくは[Unicorn readme](http://unicorn.bogomips.org/README.html)を参照し、背後の[哲学](http://unicorn.bogomips.org/PHILOSOPHY.html)を理解してください。

アプリケーションサーバーの設定が終わったら、Webサーバーも適切に設定してリクエストのプロキシを行わなければなりません。以下の設定はNGINXの設定に含まれることがあります。


```
upstream application_server {
  server 0.0.0.0:8080;
}

server {
  listen 80;
  server_name localhost;

  root /root/path/to/your_app/public;

  try_files $uri/index.html $uri.html @app;

  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://application_server;
  }

  # some other configuration
}
```

最新情報については、必ず[NGINXのドキュメント](http://nginx.org/en/docs/)を参照してください。

Rails環境の設定
--------------------------

一部の設定については、Railsの外部から環境変数を与えることで行なうこともできます。以下の環境変数は、Railsの多くの部分で認識されます。

* `ENV["RAILS_ENV"]`は、Railsが実行される環境 (production、development、testなど) を定義します。

* `ENV["RAILS_RELATIVE_URL_ROOT"]`は、[アプリをサブディレクトリにデプロイする](configuring.html#サブディレクトリにデプロイする-相対urlルートの使用)ときにルーティングシステムがURLを認識するために使用されます。

* `ENV["RAILS_CACHE_ID"]`と`ENV["RAILS_APP_VERSION"]`は、Railsのキャッシュを扱うコードで拡張キャッシュを生成するために使用されます。これにより、ひとつのアプリの中で複数の独立したキャッシュを扱うことができるようになります。

イニシャライザファイルを使用する
-----------------------

Railsは、フレームワークの読み込みとすべてのgemの読み込みが終わってから、イニシャライザの読み込みを開始します。イニシャライザとは、アプリの`config/initializers`ディレクトリに保存されるRubyファイルのことです。たとえば各部分のオプション設定をイニシャライザに保存しておき、フレームワークとgemがすべて読み込まれた後に適用することができます。

NOTE: イニシャライザを置くディレクトリにサブフォルダを作ってイニシャライザを整理することもできます。Railsはイニシャライザ用のディレクトリの下のすべての階層を探して実行してくれます。

TIP: Railsではイニシャライザの複数のファイル名に番号を付けて読み込み順を制御するサポートがありますが、よりよい方法は同一ファイル内に記述するコードの順序で読み込み順を制御することです。この方がファイル名が散らからずに済みますし、依存関係も明確になり、アプリ内の新しい概念が見えやすくなります。

初期化イベント
---------------------

Railsにはフック可能な初期化イベントが5つあります。以下に紹介するこれらのイベントは、実際に実行される順序で掲載しています。

* `before_configuration`: これは`Rails::Application`からアプリのアプリ定数を継承した直後に実行されます。`config`呼び出しは、このイベントより前に評価されますので注意してください。

* `before_initialize`: これは、`:bootstrap_hook`イニシャライザを含む初期化プロセスの直前に、直接実行されます。`:bootstrap_hook`は、Railsアプリ初期化プロセスのうち比較的最初の方にあります。

* `to_prepare`: これは、Railties用のイニシャライザとアプリ自身用のイニシャライザがすべて実行された後、かつ事前一括読み込み(eager loading)の実行とミドルウェアスタックの構築が行われる前に実行されます(訳注: RailtiesはRailsのコアライブラリの1つで、Rails Utilitiesのもじりです)。さらに重要な点は、これは`development`モードではサーバーへのリクエストのたびに必ず実行されますが、`production`モードと`test`モードでは起動時に1度だけしか実行されないことです。

* `before_eager_load`: これは、事前一括読み込みが行われる前に直接実行されます。これは`production`環境ではデフォルトの動作ですが、`development`環境では異なります。

* `after_initialize`: これは、アプリの初期化が終わり、かつ`config/initializers`以下のイニシャライザが実行された後に実行されます。

これらのフックのイベントを定義するには、`Rails::Application`、`Rails::Railtie`、または`Rails::Engine`サブクラス内でブロック記法を使用します。

```ruby
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # initialization code goes here
    end
  end
end
```

あるいは、`Rails.application`オブジェクトに対して`config`メソッドを実行することで行なうこともできます。

```ruby
Rails.application.config.before_initialize do
  # initialization code goes here
end
```

WARNING: アプリの一部、特にルーティング周りでは、`after_initialize`ブロックが呼び出された時点では設定が完了していないものがあります。

### `Rails::Railtie#initializer`

Railsでは、`Rails::Railtie`に含まれる`initializer`メソッドを使用してすべて定義され、起動時に実行されるイニシャライザがいくつもあります。以下はAction Controllerの`set_helpers_path`イニシャライザから取った例です。

```ruby
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
```

この`initializer`メソッドは3つの引数を取ります。1番目はイニシャライザの名前、2番目はオプションハッシュ(上の例では使ってません)、そして3番目はブロックです。オプションハッシュに含まれる`:before`キーを使用して、新しいイニシャライザより前に実行したいイニシャライザを指定することができます。同様に、`:after`キーを使用して、新しいイニシャライザより _後_ に実行したいイニシャライザを指定できます。

`initializer`メソッドを使用して定義されたイニシャライザは、定義された順序で実行されます。ただし`:before`や`:after`を使用した場合を除きます。

WARNING: イニシャライザが起動される順序は、論理的に矛盾が生じない限りにおいて、beforeやafterを使用していかなる順序に変更することもできます。たとえば、"one"から"four"までの4つのイニシャライザがあり、かつこの順序で定義されたとします。ここで"four"を"four"より _前_ かつ"three"よりも _後_ になるように定義すると論理矛盾が発生し、イニシャライザの実行順を決定できなくなってしまいます。

`initializer`メソッドのブロック引数は、アプリ自身のインスタンスです。そのおかげで、上の例で示したように、`config`メソッドを使用してアプリの設定にアクセスできます。

実は`Rails::Application`は`Rails::Railtie`を間接的に継承しています。そのおかげで、`config/application.rb`で`initializer`メソッドを使用してアプリ用のイニシャライザを定義できるのです。

### イニシャライザ

Railsにあるイニシャライザのリストを以下にまとめました。これらは定義された順序で並んでおり、特記事項のない限り実行されます。

* `load_environment_hook`: これはプレースホルダとして使用されます。具体的には、`:load_environment_config`を定義してこのイニシャライザより前に実行したい場合に使用します。

* `load_active_support`: Active Supportの基本部分を設定する`active_support/dependencies`が必要です。デフォルトの`config.active_support.bare`が信用できない場合には`active_support/all`も必要です。

* `initialize_logger`: ここより前の位置で`Rails.logger`を定義するイニシャライザがない場合、アプリのロガー(`ActiveSupport::Logger`オブジェクト)を初期化し、`Rails.logger`にアクセスできるようにします。

* `initialize_cache`: `Rails.cache`が未設定の場合、`config.cache_store`の値を参照してキャッシュを初期化し、その結果を`Rails.cache`として保存します。そのオブジェクトが`middleware`メソッドに応答する場合、そのミドルウェアをミドルウェアスタックの`Rack::Runtime`の前に挿入します。

* `set_clear_dependencies_hook`: このイニシャライザは、`cache_classes`が`false`の場合にのみ実行されます。そして、このイニシャライザは、オブジェクト空間からのリクエスト中に参照された定数を`ActionDispatch::Callbacks.after`を使って削除します。これにより、これらの定数は以後のリクエストで再度読み込まれるようになります。

* `initialize_dependency_mechanism`: `config.cache_classes`がtrueの場合、`ActiveSupport::Dependencies.mechanism`で依存性を(`load`ではなく)`require`に設定します。

* `bootstrap_hook`: このフックはすべての設定済み`before_initialize`ブロックを実行します。

* `i18n.callbacks`: development環境の場合、`to_prepare`コールバックを設定します。このコールバックは、最後にリクエストが発生した後にロケールが変更されると`I18n.reload!`を呼び出します。productionモードの場合、このコールバックは最初のリクエストでのみ実行されます。

* `active_support.deprecation_behavior`: 環境に対する非推奨レポート出力を設定します。development環境ではデフォルトで`:log`、production環境ではデフォルトで`:notify`、test環境ではデフォルトで`:stderr`が指定されます。`config.active_support.deprecation`に値が設定されていない場合、このイニシャライザは、現在の環境に対応する`config/environments`ファイルに値を設定するよう促すメッセージを出力します。値の配列を設定することもできます。

* `active_support.initialize_time_zone`: `config.time_zone`の設定に基いてアプリのデフォルトタイムゾーンを設定します。デフォルト値は"UTC"です。

* `active_support.initialize_beginning_of_week`: `config.beginning_of_week`の設定に基づいてアプリのデフォルトの週開始日を設定します。デフォルト値は`:monday`です。

* `active_support.set_configs`: Active Supportをセットアップします。`config.active_support`内の設定を用い、メソッド名を`ActiveSupport`のセッターに`send`し、値を渡します。

* `action_dispatch.configure`: `ActionDispatch::Http::URL.tld_length`を構成して、`config.action_dispatch.tld_length`の値(トップレベルドメイン名の長さ)が設定されるようにします。

* `action_dispatch.configure`: `ActionDispatch::Http::URL.tld_length`に`config.action_dispatch.tld_length`の値を設定します。

* `action_view.set_configs`: Action Viewをセットアップします。`config.action_view`内の設定を用い、メソッド名を`ActionView::Base`のセッターに`send`し、値を渡します。

* `action_controller.assets_config`: 明示的に設定されていない場合は、`config.actions_controller.assets_dir`をアプリのpublicディレクトリに設定されます。

* `action_controller.set_helpers_path`: Action Controllerの`helpers_path`をアプリの`helpers_path`に設定します。

* `action_controller.parameters_config`: `ActionController::Parameters`で使うstrong parametersオプションを設定します。

* `action_controller.set_configs`: Action Controllerをセットアップします。`config.action_controller`内の設定を用い、メソッド名を`ActionController::Base`のセッターに`send`し、値を渡します。

* `action_controller.compile_config_methods`: 指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

* `active_record.initialize_timezone`: `ActiveRecord::Base.time_zone_aware_attributes`をtrueに設定し、`ActiveRecord::Base.default_timezone`をUTCに設定します。属性がデータベースから読み込まれた場合、それらの属性は`Time.zone`で指定されたタイムゾーンに変換されます。

* `active_record.logger`: `ActiveRecord::Base.logger`に`Rails.logger`を設定します（設定が行われていない場合）。

* `active_record.migration_error`: マイグレーションがペンディングされているかどうかをチェックするミドルウェアを設定します。

* `active_record.check_schema_cache_dump`: 設定が見当たらない場合にスキーマキャッシュダンプを読み込みます。

* `active_record.warn_on_records_fetched_greater_than`: クエリから戻ったレコード数が非常に多い場合の警告を有効にします。

* `active_record.set_configs`: Active Recordをセットアップします。`config.active_record`内の設定を用い、メソッド名を`ActiveRecord::Base`のセッターに`send`し、値を渡します。

* `active_record.initialize_database`: データベース設定を`config/database.yml`(デフォルトの読み込み元)から読み込み、現在の環境で接続を確立します。

* `active_record.log_runtime`: `ActiveRecord::Railties::ControllerRuntime`をインクルードします。これは、リクエストでActive Record呼び出しにかかった時間をロガーにレポートする役割を担います。

* `active_record.set_reloader_hooks`: `config.cache_classes`が`false`の場合、再読み込み可能なデータベース接続をすべてリセットします。

* `active_record.add_watchable_files`: 監視対象ファイルに`schema.rb`ファイルと`structure.sql`ファイルを追加します。

* `active_job.logger`: `ActiveJob::Base.logger`に`Rails.logger`を設定します（設定が行われていない場合）。

* `active_job.set_configs`: Active Jobをセットアップします。`config.active_job`内の設定を用い、メソッド名を`ActiveJob::Base`のセッターに`send`し、値を渡します。

* `action_mailer.logger`: `ActionMailer::Base.logger`に`Rails.logger`を設定します（設定が行われていない場合）。

* `action_mailer.set_configs`: Active Jobをセットアップします。`config.action_mailer`内の設定を用い、メソッド名を`ActionMailer::Base`のセッターに`send`し、値を渡します。

* `action_mailer.compile_config_methods`: 指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

* `set_load_path`: このイニシャライザは`bootstrap_hook`より前に実行されます。`config.load_paths`およびすべての自動読み込みパスが`$LOAD_PATH`に追加されます。

* `set_autoload_paths`: このイニシャライザは`bootstrap_hook`より前に実行されます。`app`以下のすべてのサブディレクトリと、`config.autoload_paths`、`config.eager_load_paths`、`config.autoload_once_paths`で指定したすべてのパスが`ActiveSupport::Dependencies.autoload_paths`に追加されます。

* `add_routing_paths`: デフォルトですべての`config/routes.rb`ファイルを読み込み、アプリのルーティングを設定します。この`config/routes.rb`ファイルはアプリの他に、エンジンなどのrailtiesにもあります。

* `add_locales`: `config/locales`にあるファイルを`I18n.load_path`に追加し、そのパスで指定された場所にある訳文にアクセスできるようにします。この`config/locales`は、アプリだけではなく、railtiesやエンジンにもあります。

* `add_view_paths`: アプリやrailtiesやエンジンにある`app/views`へのパスをビューファイルへの探索パスに追加します。

* `load_environment_config`: 現在の環境に`config/environments`を読み込みます。

* `prepend_helpers_path`: アプリやrailtiesやエンジンに含まれる`app/helpers`ディレクトリをヘルパーへの探索パスに追加します。

* `load_config_initializers`: アプリやrailtiesやエンジンに含まれる`config/initializers`にあるRubyファイルをすべて読み込みます。このディレクトリに置かれているファイルは、フレームワークの読み込みがすべて読み終わった後に行うべき設定の保存にも使えます。

* `engines_blank_point`: エンジンの読み込みが完了する前に行いたい処理に使う初期化ポイントへのフックを提供します。初期化処理がここまで進むと、railtiesやエンジンイニシャライザはすべて起動しています。

* `add_generator_templates`: アプリやrailtiesやエンジンにある`lib/templates`ディレクトリにあるジェネレータ用のテンプレートを探し、それらを`config.generators.templates`設定に追加します。この設定によって、すべてのジェネレータからテンプレートを参照できるようになります。

* `ensure_autoload_once_paths_as_subset`: `config.autoload_once_paths`に、`config.autoload_paths`以外のパスが含まれないようにします。それ以外のパスが含まれている場合は例外が発生します。

* `add_to_prepare_blocks`: アプリやrailtiesやエンジンにあるすべての`config.to_prepare`呼び出しのブロックが、Action Dispatchの`to_prepare`に追加されます。Action Dispatchはdevelopmentモードではリクエストごとに実行され、productionモードでは最初のリクエストより前に実行されます。

* `add_builtin_route`: アプリがdevelopment環境で動作している場合、`rails/info/properties`へのルーティングをアプリのルーティングに追加します。このルーティングにアクセスすると、デフォルトのRailsアプリで`public/index.html`に表示されるのと同様の詳細情報(RailsやRubyのバージョンなど)を取り出せます。

* `build_middleware_stack`: アプリのミドルウェアスタックを構成し、`call`メソッドを持つオブジェクトを返します。この`call`メソッドは、リクエストに対するRack環境の1つのオブジェクトを引数に取ります。

* `eager_load!`: `config.eager_load`がtrueに設定されている場合、`config.before_eager_load`フックを実行し、続いて`eager_load!`を呼び出します。この呼び出しにより、すべての`config.eager_load_namespaces`が呼び出されます。

* `finisher_hook`: アプリの初期化プロセス完了後に実行されるフックを提供し、アプリやrailtiesやエンジンの`config.after_initialize`ブロックもすべて実行します。

* `set_routes_reloader_hook`: ルーティングファイルを`ActiveSupport::Callbacks.to_run`で再読み込みするようAction Dispatchを構成します。

* `disable_dependency_loading`: `config.eager_load`が`true`の場合は自動依存関係読み込み(automatic dependency loading)を無効にします。

データベース接続をプールする
----------------

Active Recordのデータベース接続は`ActiveRecord::ConnectionAdapters::ConnectionPool`によって管理されます。これは、接続数に限りのあるデータベース接続にアクセスする際のスレッド数と接続プールが同期するようにするものです。最大接続数はデフォルトで5ですが、`database.yml`でカスタマイズ可能です。

```ruby
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
```

接続プールはデフォルトではActive Recordで取り扱われるため、ThinやPumaやUnicornなどのアプリケーションサーバーの動作はどれも同じ振る舞いになります。最初はデータベース接続のプールは空で、必要に応じて追加接続が作成され、接続プールの上限に達するまで接続が追加されます。

1つのリクエストの中では、データベースアクセスが最初に必要になったときに接続をチェックアウト（貸出）し、リクエストの終わりではその接続をチェックイン（返却）します。つまり、キューで待機する次以降のリクエストで追加の接続スロットが再び利用できるようになります。

利用可能な数よりも多くの接続を使おうとすると、Active Recordは接続をブロックし、プールからの接続を待ちます。接続を取得できない場合は以下のようなタイムアウトエラーがスローされます。

```ruby
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5.000 seconds (waited 5.000 seconds)
```

上のエラーが発生するような場合は、`database.yml`の`pool`オプションの数値を増やして接続プールのサイズを増やすことで対応できます。

NOTE: アプリをマルチスレッド環境で実行している場合、多くのスレッドが多くの接続に同時アクセスする可能性があります。その時点のリクエストの負荷によっては、限られた接続数を多数のスレッドが奪い合うことになるかもしれません。

カスタム設定
--------------------

Railsの設定オブジェクトをカスタマイズして独自のコードを設定するには、`config.x`名前空間か`config`ディレクトリの下にコードを配置します。両者の大きな違いは、**ネストした**設定（`config.x.nested.nested.hi`など）の場合は`config.x`を利用すべきであるという点です。**単一レベル**の設定（`config.hello`など）は単に`config`で行います。

  ```ruby
  config.x.payment_processing.schedule = :daily
  config.x.payment_processing.retries  = 3
  config.super_debugger = true
  ```

これにより、設定オブジェクトを介してこれらの設定場所にアクセスできるようになります。

  ```ruby
  Rails.configuration.x.payment_processing.schedule # => :daily
  Rails.configuration.x.payment_processing.retries  # => 3
  Rails.configuration.x.payment_processing.not_set  # => nil
  Rails.configuration.super_debugger                # => true
  ```

`Rails::Application.config_for`を使うと、設定ファイル全体を読み込むこともできます。

  ```ruby
  # config/payment.yml:
  production:
    environment: production
    merchant_id: production_merchant_id
    public_key:  production_public_key
    private_key: production_private_key
  development:
    environment: sandbox
    merchant_id: development_merchant_id
    public_key:  development_public_key
    private_key: development_private_key

  # config/application.rb
  module MyApp
    class Application < Rails::Application
      config.payment = config_for(:payment)
    end
  end
  ```

  ```ruby
  Rails.configuration.payment['merchant_id'] # => production_merchant_id or development_merchant_id
  ```

検索エンジンのインデックス作成
-----------------------

場合によっては、アプリの一部のページをGoogleやBingやYahooやDuck Duck Goなどの検索サイトに知られないようにしたいことがあります。サイトのインデックスを作成するロボットは最初に`http://your-site.com/robots.txt`ファイルの内容を分析して、インデックス作成を許可されているページを調べます。

Railsはこのファイルを`/public`の下に作成します。デフォルトでは、検索エンジンにアプリのすべてのページのインデックス作成を許可する設定になります。アプリのすべてのページについてインデックス作成をブロックするには以下を使います。

```
User-agent: *
Disallow: /
```

特定のページのみをブロックする場合は、もう少し複雑な構文が必要です。robot.textの[公式ドキュメント](http://www.robotstxt.org/robotstxt.html)を参照してください。

イベントベースのファイルシステム監視
---------------------------

Railsで[listen gem](https://github.com/guard/listen)を使うと、イベントベースのファイルシステム監視を使ってファイルの変更を検出できます（`config.cache_classes`が`false`の場合）。

```ruby
group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
```

それ以外の場合、Railsはすべてのリクエストについてファイルの変更があるかをアプリのツリーを調べます。

LinuxやmacOSでは追加のgemは不要ですが、[*BSD](https://github.com/guard/listen#on-bsd)や[Windows](https://github.com/guard/listen#on-windows)では追加のソフトウェアが必要になることがあります。

[一部の設定がサポート対象外](https://github.com/guard/listen#issues--limitations)である点にご注意ください。
