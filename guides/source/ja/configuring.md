
Rails アプリケーションを設定する
==============================

このガイドではRailsアプリケーション（アプリ）で利用可能な設定と初期化機能について説明いたします。

このガイドの内容:

* Railsアプリの動作を調整する方法
* アプリ開始時に実行したいコードを追加する方法

--------------------------------------------------------------------------------

初期化コードの置き場所
---------------------------------

Railsには初期化コードの標準的な置き場所が4箇所あります。

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

たとえば、`config/application.rb`ファイルに以下を設定できます。

```ruby
config.time_zone = 'Central Time (US & Canada)'
```

これはRails自身のための設定です。設定をすべてのRailsコンポーネントに渡したい場合は、`config/application.rb`内の同じ`config`オブジェクトを使用して行なうことができます。

```ruby
config.active_record.schema_format = :ruby
```

この設定は、特にActive Recordの設定に使用されます。

### Rails全般の設定

Rails全般に対する設定を行うには、`Rails::Railtie`オブジェクトを呼び出すか、`Rails::Engine`や`Rails::Application`のサブクラスを呼び出します。

* `config.after_initialize`にはブロックを渡せます。このブロックは、Railsアプリの初期化が完了した_直後_に実行されます。アプリの初期化作業には、フレームワーク自体の初期化、エンジンの初期化、そして`config/initializers`に記述されたすべてのアプリケーションイニシャライザの実行が含まれます。ここで渡すブロックはタスクとして_実行される_ ことにご注意ください。このブロックは、他のイニシャライザによって設定される値を設定するのに便利です。

    ```ruby
    config.after_initialize do
      ActionView::Base.sanitized_allowed_tags.delete 'div'
    end
    ```

* `config.asset_host`: アセットを置くホストを設定します。この設定は、アセットの置き場所がCDN (Contents Delivery Network) の場合や、別のドメインエイリアスを使用するとブラウザの同時実行制限にひっかかるのを避けたい場合に便利です。このメソッドは`config.action_controller.asset_host`を短縮したものです。

* `config.autoload_once_paths`: サーバーへのリクエストごとにクリアされない定数を自動読込するパスの配列を引数に取ります。この設定は`config.cache_classes`が`false`の場合に影響を受けます。developmentモードの`config.cache_classes`はデフォルトでオフです。それ以外の場合、すべての`config.autoload_once_paths`自動読み込みは一度だけ行われます。`config.autoload_once_paths`の配列に含まれる要素は、次で説明する`autoload_paths`にもまったく同じように含めておく必要があります。`autoload_once_paths`のデフォルト値は、空の配列です。

* `config.autoload_paths`はRailsが定数を自動読込するパスを含む配列を引数に取ります。`config.autoload_paths`のデフォルト値は、`app`以下のすべてのディレクトリです。現在、この設定の変更は非推奨です。詳しくは[autoload_pathsとeagautoload_paths](autoloading_and_reloading_constants.html#autoload_pathsとeagautoload_paths)を参照してください

* `config.cache_classes`: アプリのクラスやモジュールをリクエストごとに再読み込みするか(=キャッシュしないかどうか)どうかを指定します。`config.cache_classes`のデフォルト値は、developmentモードではfalseなのでコードの更新がすぐ反映され、testモードとproductionモードではtrueなので動作が高速になります。同時に`threadsafe!`をオンにすることもできます。

* `config.beginning_of_week`: アプリにおける週の初日を設定します。引数には、曜日を表す正しいシンボルを渡します(`:monday`など)。

* `config.cache_store`はRailsでのキャッシュ処理に使用されるキャッシュストアを設定します。指定できるオプションは次のシンボル`:memory_store`、`:file_store`、`:mem_cache_store`、`:null_store`のいずれか、またはキャッシュAPIを実装するオブジェクトです。`tmp/cache`ディレクトリが存在する場合のデフォルトは`:file_store`に設定され、それ以外の場合のデフォルトは`:memory_store`に設定されます。

* `config.colorize_logging`: 出力するログ情報にANSI色情報を与えるかどうかを指定します。デフォルトはtrueです。

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

* `config.eager_load_paths`: パスの配列を引数に取ります。Railsは、cache_classesがオンの場合にこのパスから事前一括読み込み(eager load)します。デフォルトではアプリの`app`ディレクトリ以下のすべてのディレクトリが対象です。

* `config.enable_dependency_loading`：trueの場合、アプリが事前に読み込まれ、`config.cache_classes`がtrueに設定されていても、自動読み込みを有効にします。 デフォルトはfalseです。

* `config.encoding`はアプリ全体のエンコーディングを指定します。デフォルトはUTF-8です。

* `config.exceptions_app`: 例外が発生したときにShowExceptionミドルウェアによって呼び出されるアプリ例外を設定します。デフォルトは`ActionDispatch::PublicExceptions.new(Rails.public_path)`です。

 * `config.debug_exception_response_format`: developmentモードで発生するエラーで使う書式を設定します。デフォルト値は、API専用アプリでは`:api`、通常のアプリでは`:default`です。

* `config.file_watcher`: `config.reload_classes_only_on_change`が`true`の場合にファイルシステム上のファイル更新検出に使うクラスを指定します。Railsにはデフォルトで`ActiveSupport::FileUpdateChecker`と`ActiveSupport::EventedFileUpdateChecker`が含まれます（後者は[listen](https://github.com/guard/listen) gemに依存します）。カスタムクラスは`ActiveSupport::FileUpdateChecker` APIの制約に従う必要があります。

* `config.filter_parameters`: パスワードやクレジットカード番号など、ログに出力したくないパラメータをフィルタで除外するために使用します。Railsの`config/initializers/filter_parameter_logging.rb`には、パスワード除外用の`Rails.application.config.filter_parameters += [:password]`がデフォルトで追加されます。パラメータは、正規表現の部分一致によってフィルタされます（訳注: 追加の際は部分一致で他のパラメータまでフィルタされないよう注意が必要です）。

* `config.force_ssl`: `ActionDispatch::SSL`ミドルウェアを用いて、すべてのリクエストをHTTPSプロトコル下で実行するよう強制し、かつ`config.action_mailer.default_url_options`に`{ protocol: 'https' }`を設定します。これは`config.ssl_options`で設定できます。詳しくは[ActionDispatch::SSL](http://api.rubyonrails.org/classes/ActionDispatch/SSL.html)ドキュメントを参照してください。

* `config.log_formatter`はRailsロガーのフォーマットを定義します。このオプションは、デフォルトではすべてのモードで`ActiveSupport::Logger::SimpleFormatter`のインスタンスを使い舞います。値を`config.logger`で設定する場合は、`ActiveSupport::TaggedLogging`インスタンスにラップされる前にロガーにフォーマッタの値を手動で渡さなければなりません。Railsはこの作業を自動では行いません。

* `config.log_level`: Railsのログをどのぐらい詳細に出力するかを指定します。デフォルトではすべての環境で`:debug`が指定されます。指定できるログレベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`です。

* `config.log_tags`: `request`オブジェクトが応答するHTTPメソッドか、`request`オブジェクトに応答する`Proc`か、`to_s`に応答する何らかのオブジェクトのリストを引数に取ります。これは、ログの行にデバッグ情報をタグ付けする場合に便利です。たとえばサブドメインやリクエストidを指定することができ、これらはマルチユーザーのproductionモードアプリをデバッグするうえで非常に有用です。

* `config.logger`: `Rails.logger`で使われるロガー、およびRailsのログ出力に関連するもの（`ActiveRecord::Base.logger`など）です。デフォルトは`ActiveSupport::TaggedLogging`のインスタンスで、これはログを`log/`ディレクトリに出力する`ActiveSupport::Logger`のインスタンスをラップします。カスタムロガーを指定する場合、完全な互換性を維持するために次のガイドラインに従わなければなりません。

   * ロガーには`config.log_formatter`の値を手動で代入しなければならない（フォーマッタのサポート用）
   * ログのインスタンスは`ActiveSupport::TaggedLogging`でラップされなければならない（タグ付きログのサポート用）。
   * ロガーは`LoggerSilence`モジュールと`ActiveSupport::LoggerThreadSafeLevel`モジュールをインクルードしなければならない（ログ出力抑制用）。`ActiveSupport::Logger`クラスはこれらのモジュールで既にインクルードされています。
 
     ```ruby
     class MyLogger < ::Logger
       include ActiveSupport::LoggerThreadSafeLevel
       include LoggerSilence
     end
      
     mylogger           = MyLogger.new(STDOUT)
     mylogger.formatter = config.log_formatter
     config.logger      = ActiveSupport::TaggedLogging.new(mylogger)
     ```

* `config.middleware`: アプリで使うミドルウェアをカスタマイズできます。詳しくは[ミドルウェアを設定する](#ミドルウェアを設定する)の節を参照してください。

* `config.reload_classes_only_on_change`: 監視しているファイルが変更された場合にのみクラスを再読み込みするかどうかを指定します。デフォルトでは、autoload_pathで指定されたすべてのファイルが監視対象となり、デフォルトで`true`が設定されます。`config.cache_classes`がオンの場合、このオプションは無視されます。

* `secrets.secret_key_base`: 改竄防止のために、アプリのセッションを既知の秘密キーと照合するキーを指定するときに使うメソッドです。アプリは、test環境とdevelopment環境ではランダムに生成されたキーを用いますが、その他の環境では`config/credentials.yml.enc`にキーを設定すべきです。

* `config.serve_static_assets`: `public/`ディレクトリ下の静的アセットを扱うかどうかを指定します。デフォルトでは`true`が設定されますが、production環境では`false`になります。静的アセットは、（`public/`ではなく）アプリを実行するNginxやApacheなどのサーバーソフトウェアで扱うべきだからです。WEBrickを使うアプリをproductionモードで実行したりテストしたりする場合は、このオプションを`true`に設定してください（WEBRickをproduction環境で使うことはおすすめできません）。`true`に設定しないと、ページキャッシュも`public/`ディレクトリの下にあるファイルへのリクエストも利用できなくなります。

* `config.session_store`: セッションの保存に使うクラスを指定します。指定できる値は`:cookie_store`(デフォルト)、`:mem_cache_store`、`:disabled`です。`:disabled`を指定すると、Railsでセッションが扱われなくなります。デフォルトでは、アプリ名をセッションキーとして用いるcookieストアが使われますが、カスタムセッションストアを指定することもできます。

    ```ruby
    config.session_store :my_custom_store
    ```

カスタムストアは`ActionDispatch::Session::MyCustomStore`として定義する必要があります。

* `config.time_zone`はアプリのデフォルトタイムゾーンを設定し、Active Recordで認識できるようにします。

### アセットを設定する

* `config.assets.enabled`: アセットパイプラインを有効にするかどうかを指定します。デフォルトは`true`です。

* `config.assets.css_compressor`: CSSを圧縮するプログラムを定義します。このオプションは、`sass-rails`を使用するとデフォルトで設定されます。このオプションで他に指定できるのは`:yui`のみです（`yui-compressor` gemを使う）。

* `config.assets.js_compressor`: JavaScriptを圧縮するプログラムを定義します。指定できる値は`:closure`、`:uglifier`、`:yui`で、それぞれ`closure-compiler`、`uglifier`、`yui-compressor` gemに対応します。

* `config.assets.gzip`: コンパイル済みアセットのgzip版も非圧縮版と別に作成するフラグです。デフォルトは`true`です。

* `config.assets.paths`: アセットを探索するパスを指定します。この設定オプションにパスを追加すると、アセットの検索先として追加されます。

* `config.assets.paths`には、アセット探索用のパスを指定します。この設定オプションにパスを追加すると、アセットの検索先として追加されます。

* `config.assets.unknown_asset_fallback`: アセットパイプラインのパイプラインにアセットがない場合の振る舞いを変更できます（sprockets-rails 3.2.0以降を利用している場合）。デフォルトは`true`です。

* `config.assets.prefix`はアセットを置くディレクトリを指定します。デフォルトは`/assets`です。

* `config.assets.digest`: アセット名に使用するMD5フィンガープリントを有効にするかどうかを指定します。`production.rb`ではデフォルトで`true`に設定されます。

* `config.assets.manifest`: アセットプリコンパイラのマニフェストファイルを指すフルパスを定義します。デフォルトは、`public/`フォルダの下にある`config.assets.prefix`ディレクトリの`manifest-<random>.json`です。

* `config.assets.digest`: アセット名にSHA256フィンガープリントが使われるようにします。デフォルトは`true`です。

* `config.assets.debug`: デバッグ用にアセットの連結と圧縮をやめるかどうかを指定します。`development.rb`ではデフォルトで`true`に設定されます。

* `config.assets.version`: SHA256ハッシュ生成に用いるオプション文字列です。この値を変更すると、すべての（アセット）ファイルが強制的にリコンパイルされます。

* `config.assets.compile`: production環境での動的なSprocketsコンパイルをオンにするかどうかを`true`/`false`で指定します。

* `config.assets.logger`: Log4rのインターフェイスかRubyの`Logger`クラスに適合するロガーを引数に取ります。デフォルトでは、`config.logger`と同じ設定が使われます。`config.assets.logger`を`false`に設定すると、アセットのログ出力がオフになります。

* `config.assets.quiet`: アセットへのリクエストのログ出力を止めます。`development.rb`ではデフォルトで`true`に設定されます。

### ジェネレータの設定

`config.generators`メソッドを使用して、Railsで使用されるジェネレータを変更できます。このメソッドはブロックを1つ取ります。

```ruby
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
```

ブロックで使用可能なメソッドの完全なリストは以下のとおりです。

* `assets`: scaffoldを生成するかどうかを指定します（デフォルト値は`true`）。
* `force_plural`: モデル名を複数形にするかどうかを指定します（デフォルト値は`false`）。
* `helper`: ヘルパーを生成するかどうかを指定します（デフォルト値は`true`）。
* `integration_tool`: 使用する統合ツールを定義します（デフォルト値は`:test_unit`）。
* `system_tests`: システムテストの生成に使う統合ツールを定義します（デフォルト値は`:test_unit`）。
* `javascripts`: 生成時にJavaScriptファイルへのフックをオンにするかどうかを指定します。この設定は`scaffold`ジェネレータの実行中に使用されます。デフォルトは`true`です。
* `javascript_engine`: アセット生成時に(coffeeなどで)使用するエンジンを設定します（デフォルト値は`:js`）。
* `orm`: 使用するORM (オブジェクトリレーショナルマッピング) を指定します。デフォルトは`false`で、この場合Active Recordが使用されます。
* `resource_controller`: `rails generate resource`の実行時にコントローラを生成するジェネレータを指定します（デフォルト値は`:controller`）。
* `resource_route`: リソースのルーティング定義を生成するかどうかを指定します（デフォルト値は`true`）。
* `scaffold_controller`: `resource_controller`とは異なるメソッドです。`scaffold_controller`は _scaffold_ でコントローラを生成するのに使うジェネレータ(`rails generate scaffold`の実行時)を指定します（デフォルト値は`:scaffold_controller`）。
* `stylesheets`: ジェネレータでスタイルシートのフックを行なうかどうかを指定します。この設定は`scaffold`ジェネレータの実行時に使用されますが、このフックは他のジェネレータでも使用されます（デフォルト値は`true`）。
* `stylesheet_engine`: アセット生成に使うsassなどのスタイルシートエンジンを指定します（デフォルト値は`:css`）。
* `test_framework`: 使用するテストフレームワークを指定します。デフォルトは`false`であり、この場合はMinitestが使用されます。
* `template_engine`はビューのテンプレートエンジン(ERBやHamlなど)を指定します（デフォルト値は`:erb`）。

### ミドルウェアを設定する

どのRailsアプリの背後にも、いくつかの標準的なミドルウェアが配置されています。development環境では、以下の順序でミドルウェアを使用します。

* `ActionDispatch::SSL`: すべてのリクエストにHTTPSプロトコルを強制します。これは`config.force_ssl`を`true`にすると有効になります。渡すオプションは`config.ssl_options`で設定できます。
* `ActionDispatch::Static`: 静的アセットの表示に使います。`config.serve_static_assets`を`false`にするとオフになります。静的ディレクトリで名前が`index`でないインデックスファイルを表示する必要がある場合、`config.public_file_server.index_name`を設定します。たとえば、ディレクトリのrクエストで`index.html`ではなく`main.html`を返すには、`config.public_file_server.index_name`に`"main"`を設定します。
 * `ActionDispatch::Executor`: スレッドセーフなコード再読み込みを有効にします。これは`config.allow_concurrency`を`false`に設定すると無効になり、`Rack::Lock`が読み込まれるようになります。`Rack::Lock`は、アプリをミューテックスでラップし、1度に1つのスレッドでしか呼び出されないようにします。
* `ActiveSupport::Cache::Strategy::LocalCache`: 基本的なメモリキャッシュとして機能します。このキャッシュはスレッドセーフではなく、シングルスレッド用の一時メモリキャッシュとしての利用のみを意図していることにご注意ください。
* `Rack::Runtime`: `X-Runtime`ヘッダーを設定します。このヘッダーには、リクエストの実行にかかる時間(秒)が含まれます。
* `Rails::Rack::Logger`: リクエストが開始されたことをログに通知します。リクエストが完了すると、すべてのログをフラッシュします。
* `ActionDispatch::ShowExceptions`: アプリから返されるすべての例外をrescueし、リクエストがローカルであるか`config.consider_all_requests_local`が`true`に設定されている場合に適切な例外ページを出力します。`config.action_dispatch.show_exceptions`が`false`に設定されていると、常に例外が出力されます。
* `ActionDispatch::RequestId`: レスポンスで使用できる独自のX-Request-Idヘッダーを作成し、`ActionDispatch::Request#uuid`メソッドを利用できるようにします。
* `ActionDispatch::RemoteIp`: IPスプーフィング攻撃が行われていないかどうかをチェックし、リクエストヘッダーから正しい`client_ip`を取得します。この設定は`config.action_dispatch.ip_spoofing_check`オプションと`config.action_dispatch.trusted_proxies`オプションで変更可能です。
* `Rack::Sendfile`: bodyが1つのファイルから作成されているレスポンスをキャッチし、サーバー固有のX-Sendfileヘッダーに差し替えてから送信します。この動作は`config.action_dispatch.x_sendfile_header`で設定可能です。
* `ActionDispatch::Callbacks`: リクエストに応答する前に`:prepare`コールバックを実行します。
* `ActionDispatch::Cookies`: リクエストに対応するcookieを設定します。
* `ActionDispatch::Session::CookieStore`: セッションをcookieに保存する役割を担います。`config.action_controller.session_store`の値を変更すると別のミドルウェアを使えます。これに渡されるオプションは`config.action_controller.session_options`で設定できます。
* `ActionDispatch::Flash`: `flash`キーを設定します。これは、`config.action_controller.session_store`に値が設定されている場合にのみ有効です。
* `Rack::MethodOverride`: `params[:_method]`が設定されている場合にメソッドを上書きできるようにします。これは、HTTPでPATCH、PUT、DELETEメソッドを使用できるようにするミドルウェアです。
* `ActionDispatch::Head`: HEADリクエストをGETリクエストに変換し、HEADリクエストが機能するようにします。

`config.middleware.use`メソッドを使うと、独自のミドルウェアをスタックの末尾に追加することもできます。

```ruby
config.middleware.use Magical::Unicorns
```

上は`Magical::Unicorns`をスタックの末尾に追加します。あるミドルウェアの直前に別のミドルウェアを追加したい場合は`insert_before`を使います。

 ```ruby
 config.middleware.insert_before Rack::Head, Magical::Unicorns
 ```

ミドルウェア挿入時にインデックスを渡すことで正確な挿入位置を指定することもできます。`Magical::Unicorns`ミドルウェアをスタックの最初に挿入したい場合は`次のようにします

```ruby
config.middleware.insert_before 0, Magical::Unicorns
```

あるミドルウェアの後に別のミドルウェアを追加したい場合は`insert_after`を使用します。

```ruby
config.middleware.insert_after Rack::Head, Magical::Unicorns
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

* `config.i18n.available_locales`: アプリで利用できるロケールをホワイトリスト化します。デフォルトでは、ロケールファイルにあるロケールキーがすべて有効になりますが、新しいアプリの場合、通常は`:en`しかありません。

* `config.i18n.default_locale`: アプリのi18nで使用するデフォルトのロケールを設定します（デフォルト値は`:en`)。

* `config.i18n.enforce_available_locales`: これを有効にすると、`available_locales`リストで宣言されていないロケールはi18nに渡せなくなります。利用できないロケールがある場合は`i18n::InvalidLocale`例外が発生します。デフォルトは`true`です。このオプションは、ユーザー入力のロケールが不正である場合のセキュリティ対策であるため、特別な理由がない限り無効にしないことをおすすめします。

* `config.i18n.load_path`: ロケールファイルの探索パスを設定します（デフォルト値は`config/locales/*.{yml,rb}`）。

* `config.i18n.fallbacks`: 訳文が見つからない場合のフォールバック動作を設定します。利用法の3つの例を示します。
 
  * デフォルトロケールをフォールバック先として使う場合は以下のようにオプションを`true`に設定します。
 
    ```ruby
    config.i18n.fallbacks = true
    ```
 
  * フォールバック先ロケールの配列を次のように設定することもできます。
 
    ```ruby
    config.i18n.fallbacks = [:tr, :en]
    ```
 
  * フォールバック先をロケールごとに個別設定することもできます。たとえば、`:az`のフォールバック先を`:tr`、`:da`のフォールバック先を`:de`や`:en`に設定する場合は、次のようにします。
 
    ```ruby
    config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
    #or
    config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }
    ```

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

* `config.active_record.logger`: Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは以後作成されるすべての新しいデータベース接続に渡されます。Active Recordのモデルクラスまたはモデルインスタンスに対して`logger`メソッドを呼び出すと、このロガーを取り出せます。ログ出力を無効にするには`nil`を設定します。

* `config.active_record. primary_key_prefix_type`: 主キーカラムの命名法の変更に使います。Railsのでは、主キーカラムの名前にデフォルトで`id`を使います (なお`id`にしたい場合は値の設定は不要です)。`id`以外に以下の2つを指定できます。
    * `:table_name`を指定すると、たとえばCustomerクラスの主キーは`customerid`になります
    * `:table_name_with_underscore`を指定すると、たとえばCustomerクラスの主キーは`customer_id`になります

* `config.active_record.table_name_prefix`: テーブル名の冒頭にグローバルに追加する文字列を指定します。たとえば`northwest_`を指定すると、Customerクラスは`northwest_customers`をテーブルとして探します。デフォルトは空文字列です。

* `config.active_record.table_name_suffix`: テーブル名の末尾にグローバルに追加する文字列を指定します。たとえば`_northwest`を指定すると、Customerは`customers_northwest`をテーブルとして探します。デフォルトは空文字列です。

* `config.active_record.schema_migrations_table_name`: スキーママイグレーションテーブル名に使う文字列を指定します。


* `config.active_record.internal_metadata_table_name`: 内部のメタデータテーブルの名前に使う文字列を指定します。

* `config.active_record.protected_environments`: 破壊的操作を禁止すべき環境名を配列で指定します。

* `config.active_record.pluralize_table_names`: Railsが探索するデータベースのテーブル名を単数形にするか複数形にするかを指定します。trueに設定すると、Customerクラスが使用するテーブル名は複数形の`customers`になります(デフォルト)。falseに設定すると、Customerクラスが使用するテーブル名は単数形の`customer`になります。

* `config.active_record.default_timezone`: データベースから日付・時刻を取り出した際のタイムゾーンを`Time.local` (`:local`を指定した場合)と`Time.utc` (`:utc`を指定した場合)のどちらにするかを指定します（デフォルト値は`:utc`）。

* `config.active_record.schema_format`: データベーススキーマをファイルに書き出す際のフォーマットを指定します。デフォルトは`:ruby`で、マイグレーションで使われるデータベースの種類に依存しません。`:sql`を指定するとSQL文で書き出されますが、この場合は潜在的にデータベースに依存する可能性があります。

* `config.active_record.error_on_ignored_order`: バッチクエリの実行中にクエリの実行順序が無視されたときにエラーをraiseするべきかどうかを指定します。指定可能なオプションは`true`（エラーをraise）または`false`（warning）です（デフォルト値は`false`）。

* `config.active_record.timestamped_migrations`: マイグレーションファイル名にシリアル番号とタイムスタンプのどちらを与えるかを指定します。デフォルトは`true`で、タイムスタンプが使われます。複数の開発者が同じアプリを開発する場合は、タイムスタンプの使用をおすすめします。

* `config.active_record.lock_optimistically`: Active Recordで楽観的ロック(optimistic locking)を使用するかどうかを指定します（デフォルト値は`true`）。

* `config.active_record.cache_timestamp_format`: キャッシュキーに含まれるタイムスタンプ値の形式を指定します（デフォルト値は`:number`）。

* `config.active_record.record_timestamps`: モデルで発生する`create`操作や`update`操作にタイムスタンプを付けるかどうかを論理値で指定します（デフォルト値は`true`）。

* `config.active_record.partial_writes`: 部分書き込みを行なうかどうか(「dirty」とマークされた属性だけを更新するか)を論理値で指定します。データベースで部分書き込みを使用する場合は、`config.active_record.lock_optimistically`で楽観的ロックも使用する必要があります。これは、同時更新が行われた場合に、読み出したときの状態が古い情報に基づいて属性に書き込まれる可能性があるためです（デフォルト値は`true`）。

* `config.active_record.maintain_test_schema`: テスト実行時にActive Recordがテスト用データベーススキーマを`db/schema.rb`(または`db/structure.sql`)に基いて最新の状態にするかどうかを論理値で指定します（デフォルト値は`true`）。

* `config.active_record.dump_schema_after_migration`: マイグレーション実行時にスキーマダンプ(`db/schema.rb`または`db/structure.sql`)を行なうかどうかを指定します。このオプションは、Railsが生成する`config/environments/production.rb`ではfalseに設定されます。このオプションが無指定の場合は、デフォルトの`true`が指定されます。

* `config.active_record.dump_schemas`: `db:structure:dump`の呼び出し時にダンプするデータベーススキーマを指定します。指定可能なオプションは次のとおりです。`:schema_search_path`（デフォルト）は、`schema_search_path`にあるすべてのスキーマをダンプします。`:all`は、`schema_search_path`にあるかどうか、スキーマがカンマ区切り文字列であるかどうかにかかわらず、すべてのスキーマをダンプします。

* `config.active_record.belongs_to_required_by_default`: `belongs_to`関連付けが使われていない場合にレコードのバリデーションでエラーにするかどうかを論理値で指定します。
 
* `config.active_record.warn_on_records_fetched_greater_than`: 生成されるクエリサイズのwarning上限値を設定できます。クエリから返されるレコード数がこの上限値を超えるとwarningがログ出力されます。このオプションは、メモリ肥大化の原因となる可能性のあるクエリを特定するときに使えます。
 
* `config.active_record.index_nested_attribute_errors`: エラー出力時に、ネストした`has_many`関連付けにインデックス値を表示します（デフォルト値は`false`）。
 
* `config.active_record.use_schema_cache_dump`: スキーマキャッシュ情報をデータベースからではなく、`db/schema_cache.yml`（`bin/rails db:schema:cache:dump`で生成される）から取得します（デフォルト値は`true`）。

MySQLアダプタを使うと、以下の設定オプションが1つ追加されます。

* `ActiveRecord::ConnectionAdapters::MysqlAdapter.emulate_booleans`: Active Recordで、MySQLデータベース内のすべての`tinyint(1)`カラムをデフォルトで`boolean`にするかどうかを指定します（デフォルト値は`true`）。

SQLite3Adapterアダプタを使うと、以下の設定オプションが1つ追加されます。

* `ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer`: SQLite3データベースでのboolean値保存を「1と0」にするか「't'と'f'」にするかを指定します。この`ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer`を`false`のまま使い続けることは推奨されません。従来のSQLiteデータベースではboolean値のシリアライズに「't'と'f'」が使われていたため、このフラグを`true`にする前に、古いデータをネイティブのbooleanシリアライズ化である「1と0」に変換しておかなければなりません。この変換は、すべてのモデルとbooloanカラムに対して以下を実行するRakeタスクをセットアップすることでできます。

   ```ruby
   ExampleModel.where("boolean_column = 't'").update_all(boolean_column: 1)
   ExampleModel.where("boolean_column = 'f'").update_all(boolean_column: 0)
   ```

その後、`application.rb`ファイルに以下を追加して、このフラグを`true`に設定しなければなりません。

   ```ruby
   Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true
   ```

スキーマダンパーは以下のオプションを追加します。

* `ActiveRecord::SchemaDumper.ignore_tables`はテーブル名の配列を1つ引数に取ります。どのスキーマファイルにも _含めたくない_ テーブル名がある場合はこの配列にテーブル名を含めます。

### Action Controllerを設定する

`config.action_controller`には多数の設定が含まれています。

* `config.action_controller.asset_host`: アセットの置き場所を設定します。これは、アプリケーションサーバーの代りにCDN(コンテンツ配信ネットワーク)にアセットを置きたい場合に便利です。

* `config.action_controller.perform_caching`: Action Controllerコンポーネントのキャッシュ機能をアプリで使うかどうかを指定します。developmentモードでは`false`、productionモードでは`true`に設定してください。

* `config.action_controller.default_static_extension`: キャッシュされたページに与える拡張子を指定します（デフォルト値は`.html`）。

* `config.action_controller.include_all_helpers`: ビューヘルパーをあらゆる場所で使えるようにするか、対応するコントローラでの使用に限定するかを指定します。`false`に設定すると、たとえば`UsersHelper`メソッドは`UsersController`でレンダリングされるビューでしか利用できなくなります。`true`に設定すると、`UsersHelper`はどこからでも使えるようになります。デフォルトの設定（`true`や`false`を明示的に設定しない場合）は、どのコントローラでもあらゆるビューヘルパーを使えます。

* `config.action_controller.logger`: Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Controllerからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_controller.request_forgery_protection_token`: RequestForgery対策用のトークンパラメータ名を設定します。`protect_from_forgery`を呼び出すと、デフォルトで`:authenticity_token`が設定されます。

* `config.action_controller.allow_forgery_protection`: CSRF保護をオンにするかどうかを指定します。testモードではデフォルトで`false`に設定され、それ以外では`true`に設定されます。

* `config.action_controller.forgery_protection_origin_check`: CSRFの追加保護として、HTTP `Origin`ヘッダーをサイトのoriginと照合すべきかどうかを指定します。

* `config.action_controller.per_form_csrf_tokens`: CSRFトークンの有効範囲を、それらが生成されたメソッドやアクションに限定するかどうかを指定します。

* `config.action_controller.default_protect_from_forgery`: フォージェリ保護を`ActionController:Base`に追加するかどうかを指定します。デフォルトでは`false`ですが、Rails 5.2のデフォルト設定を読み込むと有効になります。

* `config.action_controller.relative_url_root`: [サブディレクトリへのデプロイ](configuring.html#サブディレクトリにデプロイする-相対urlルートの使用)を行うことをRailsに認識させます（デフォルト値は`ENV['RAILS_RELATIVE_URL_ROOT']`）。

* `config.action_controller.permit_all_parameters`: マスアサインメントされるすべてのパラメータをデフォルトで許可します（デフォルト値は`false`）。

* `config.action_controller.action_on_unpermitted_parameters`: 明示的に許可されていないパラメータが見つかった場合にログ出力または例外発生を行なうかどうかを指定します。このオプションを有効にするには、`:log`または`:raise`を指定します。test環境とdevelopment環境でのデフォルトは`:log`であり、それ以外の環境では`false`が設定されます。

* `config.action_controller.always_permitted_parameters`: デフォルトで許可したいホワイトリストパラメータのリストを指定します（デフォルト値は`['controller', 'action']`）。
 
* `config.action_controller.enable_fragment_cache_logging`: フラグメントキャッシュの読み書きを以下のようにフルでログ出力するかどうかを指定します。
 
    ```
    Read fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/d0bdf2974e1ef6d31685c3b392ad0b74 (0.6ms)
    Rendered messages/_message.html.erb in 1.2 ms [cache hit]
    Write fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/3b4e249ac9d168c617e32e84b99218b5 (1.1ms)
    Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
    ```

デフォルト値は`false`で、この場合以下のように出力されます。
 
    ```
    Rendered messages/_message.html.erb in 1.2 ms [cache hit]
    Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
    ```

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

* `config.action_dispatch.session_store`: セッションデータのストア名を設定します。デフォルトのストア名は`:cookie_store`です。この他に`:active_record_store`、`:mem_cache_store`、またはカスタムクラスの名前を指定できます。

* `config.action_dispatch.default_headers`: HTTPヘッダーで使用されるハッシュです。このヘッダーはデフォルトですべてのレスポンスに設定されます。このオプションは、デフォルトでは以下のように設定されます。

    ```ruby
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'X-Download-Options' => 'noopen',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Referrer-Policy' => 'strict-origin-when-cross-origin'
    }
    ```

* `config.action_dispatch.default_charset`: レンダリングで常に使うデフォルト文字セットを指定します（デフォルト値は`nil`）。

* `config.action_dispatch.tld_length`: アプリで使用するトップレベルドメイン(TLD) の長さを指定します（デフォルト値は`1`）。

* `config.action_dispatch.ignore_accept_header`: リクエストのAcceptヘッダーを無視するかどうかを指定します（デフォルト値は`false`）。
 
* `config.action_dispatch.x_sendfile_header`: サーバー固有のX-Sendfileヘッダーを指定します。これは、サーバーからのファイル送信を高速化するのに有用です。たとえば、Apache向けのヘッダーを`X-Sendfile`に設定できます。

* `config.action_dispatch.http_auth_salt`: HTTP Authのsalt値(訳注: ハッシュの安全性を強化するために加えられるランダムな値)を設定します（デフォルト値は`'http authentication'`）。

* `config.action_dispatch.signed_cookie_salt`: 署名済みcookie用のsalt値を設定します（デフォルト値は`'signed cookie'`）。

* `config.action_dispatch.encrypted_cookie_salt`: 暗号化済みcookie用のsalt値を設定します（デフォルト値は`'encrypted cookie'`）。

* `config.action_dispatch.encrypted_signed_cookie_salt`: 署名暗号化済みcookie用のsalt値を設定します（デフォルト値は`'signed encrypted cookie'`）。

* `config.action_dispatch.authenticated_encrypted_cookie_salt`: 認証済み暗号化cookieのsalt値を設定します（デフォルト値は`'authenticated encrypted cookie'`）。

* `config.action_dispatch.encrypted_cookie_cipher`: 暗号化済みcookieで使う暗号化方式を設定します（デフォルト値は`"aes-256-gcm"`）。

* `config.action_dispatch.signed_cookie_digest`: 署名済みcookieで使うダイジェスト方式を設定します（デフォルト値は`"SHA1"`）。

* `config.action_dispatch.cookies_rotations`: 暗号化署名済みcookieで使う秘密情報（secret）、暗号化方式、ダイジェストをローテーションします。

* `config.action_dispatch.use_authenticated_cookie_encryption`: 暗号化済みcookieでAES-256-GC認証済み暗号化を使うようにし、署名済み・暗号化済みcookieが埋め込まれる場合はその期限切れ情報を値に埋め込みます（デフォルト値は`false`）。

* `config.action_dispatch.perform_deep_munge`: パラメータに対して`deep_munge`メソッドを実行すべきかどうかを指定します（デフォルト値は`true`）。詳しくは[セキュリティガイド](security.html#安全でないクエリ生成)を参照してください。

* `config.action_dispatch.rescue_responses`: HTTPステータスごとに割り当てる例外を設定します。設定は、例外とステータスのペアを含むハッシュで指定できます。デフォルトでは以下のように定義されます。
 
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
 
ここで設定されていない例外はすべて「500 Internal Server Error」に割り当てられます。

* `ActionDispatch::Callbacks.before`: リクエストより前に実行したいコードブロックを1つ与えます。

* `ActionDispatch::Callbacks.after`: リクエストの後に実行したいコードブロックを1つ与えます。

### Action Viewを設定する

`config.action_view`にもわずかながら設定があります。

* `config.action_view.cache_template_loading`: リクエストごとにテンプレートを再読み込みするかどうかを指定します。デフォルトでは`config.cache_classes`の設定内容が使われます。

* `config.action_view.field_error_proc`: Active Recordで発生したエラーの表示に使うHTMLジェネレータを指定します。デフォルトは以下のとおりです。

    ```ruby
    Proc.new do |html_tag, instance|
      %Q(<div class="field_with_errors">#{html_tag}</div>).html_safe
    end
    ```

* `config.action_view.default_form_builder`: Railsでデフォルトで使用するフォームビルダーを指定します。デフォルトは、`ActionView::Helpers::FormBuilder`です。フォームビルダーを初期化処理の後に読み込みたい場合(こうすることでdevelopmentモードではフォームビルダーがリクエストのたびに再読込されます)、`String`として渡すこともできます。

* `config.action_view.logger`: Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数としてとります。このロガーは、Action Viewからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_view.erb_trim_mode`: ERBで使用するトリムモードを指定します。デフォルトは`'-'`で、`<%= -%>`または`<%= =%>`の場合に末尾スペースを削除して改行します。詳しくは[Erubisドキュメント](http://www.kuwata-lab.com/erubis/users-guide.06.html#topics-trimspaces)を参照してください。

* `config.action_view.embed_authenticity_token_in_remote_forms`: フォームで`:remote => true`を使用した場合の`authenticity_token`のデフォルトの動作を設定します。デフォルトでは`false`であり、この場合リモートフォームには`authenticity_token`フォームが含まれません。これはフォームでフラグメントキャッシュを使用している場合に便利です。リモートフォームは`meta`タグから認証を受け取るので、JavaScriptの動作しないブラウザのサポートが不要であればトークンの埋め込みは不要です。JavaScriptが動かないブラウザのサポートが必要な場合は、`:authenticity_token => true`をフォームオプションとして渡すか、この設定を`true`にします。

* `config.action_view.prefix_partial_path_with_controller_namespace`: 名前空間化されたコントローラから出力されたテンプレートにあるサブディレクトリから、パーシャル(部分テンプレート)を探索するかどうかを指定します。たとえば、`Admin::PostsController`というコントローラがあり、以下のテンプレートを出力するとします。

    ```erb
    <%= render @post %>
    ```

このデフォルト設定は`true`であり、`/admin/posts/_post.erb`にあるパーシャルを使用しています。この値を`false`にすると、`/posts/_post.erb`が描画されます。この動作は、`PostsController`などの名前空間化されていないコントローラでレンダリングした場合と同じです。

* `config.action_view.raise_on_missing_translations`: i18nで訳文が失われている場合にエラーを発生させるかどうかを指定します。

* `config.action_view.automatically_disable_submit_tag`: クリック時に`submit_tag`を自動的に無効にするかどうかを指定します（デフォルト値は`true`）。

* `config.action_view.debug_missing_translation`: 見つからない訳文のキーを`<span>`タグで囲むかどうかを指定します（デフォルト値は`true`）。

* `config.action_view.form_with_generates_remote_forms`: `form_with`でリモートフォームを生成するかどうかを指定します（デフォルト値は`true`）。

* `config.action_view.form_with_generates_ids`: `form_with`の入力にidを生成するかどうかを指定します（デフォルト値は`true`）。

### Action Mailerを設定する

`config.action_mailer`には多数の設定オプションがあります。

* `config.action_mailer.logger`: Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Mailerからの情報をログ出力するために使用されます。ログ出力を無効にするには`nil`を設定します。

* `config.action_mailer.smtp_settings`: `:smtp`の詳細な配信方法を設定できます。これはオプションのハッシュを引数に取り、以下のどのオプションでも含めることができます。
    * `:address` - リモートのメールサーバーを指定します。デフォルトの"localhost"設定から変更します。
    * `:port` - 使用するメールサーバーのポートが25番でないのであれば(めったにないと思いますが)、ここで対応できます。
    * `:domain` - HELOドメインの指定が必要な場合に使用します。
    * `:user_name` - メールサーバーで認証が要求される場合は、ここでユーザー名を設定します。
    * `:password` - メールサーバーで認証が要求される場合は、ここでパスワードを設定します。
    * `:authentication` - メールサーバーで認証が要求される場合は、ここで認証の種類を指定します。`:plain`、`:login`、`:cram_md5`のいずれかのシンボルを指定できます。
    * `:enable_starttls_auto` - SMTPサーバーで`STARTTLS`が有効かどうかを検出して`STARTTLS`を使います（デフォルト値は`true`）。
    * `:openssl_verify_mode` - TLS使用時にOpenSSLで証明書をチェックする方法を指定できます。これは、自己署名証明書やワイルドカード証明書を検証する必要がある場合に有用です。指定できる値は、OpenSSLの検証用定数か`:none`か`:peer`です。後者の2つについては、`OpenSSL::SSL::VERIFY_NONE`定数や`OpenSSL::SSL::VERIFY_PEER`定数を直接指定することもできます。
    * `:ssl/:tls` - SMTP接続でSMTP/TLS（SMTPS: SMTP over direct TLS connection）を有効にします。

* `config.action_mailer.sendmail_settings`: `:sendmail`の詳細な配信方法を設定できます。これはオプションのハッシュを引数に取り、以下のどのオプションでも含めることができます。
    * `:location` - sendmail実行ファイルの場所。デフォルトは`/usr/sbin/sendmail`です。
    * `:arguments` - コマンドラインに与える引数。デフォルトは`-i -t`です。

* `config.action_mailer.raise_delivery_errors`: メールの配信が完了しなかった場合にエラーを発生させるかどうかを指定します（デフォルト値は`true`）。

* `config.action_mailer.delivery_method`: 配信方法を指定します(デフォルトは`:smtp`）。詳しくは、[Action Mailerガイド](action_mailer_basics.html#action-mailerを設定する)を参照してください。

* `config.action_mailer.perform_deliveries`: メールを実際に配信するかどうかを指定します（デフォルト値は`true`）。テスト中のメール送信を抑制するのに便利です。

* `config.action_mailer.default_options`: Action Mailerのデフォルトを設定します。これは、メイラーごとに`from`や`reply_to`などを設定します。デフォルトは以下のとおりです。

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

* `config.action_mailer.observers`: メールを配信したときに通知を受けるオブザーバーを指定します。

    ```ruby
    config.action_mailer.observers = ["MailObserver"]
    ```

* `config.action_mailer.interceptors`: メールを送信する前に呼び出すインターセプタを登録します。

    ```ruby
    config.action_mailer.interceptors = ["MailInterceptor"]
    ```

* `config.action_mailer.preview_path`: メイラープレビューの場所を指定します。
 
    ```ruby
    config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
    ```
 
* `config.action_mailer.show_previews`: メイラープレビューのオンオフを指定します。development環境ではデフォルトで`true`です。
 
    ```ruby
    config.action_mailer.show_previews = false
    ```
 
* `config.action_mailer.deliver_later_queue_name`: メイラーで使うキュー名を指定します（デフォルト値は`mailers`）。
   mailers. By default this is `mailers`.
 
* `config.action_mailer.perform_caching`: メイラーのテンプレートでフラグメントキャッシュを行うかどうかを指定します。デフォルトではすべての環境で`false`です。
 
### Active Supportを設定する

Active Supportにもいくつかの設定オプションがあります。

* `config.active_support.bare`: Rails起動時に`active_support/all`の読み込みを行なうかどうかを指定します。デフォルトは`nil`であり、この場合`active_support/all`は読み込まれます。

* `config.active_support.test_order`: テストの各ケースの実行順序を設定します。指定可能な値は`:random`または`:sorted`です（デフォルト値は`:random`）。

* `config.active_support.escape_html_entities_in_json`: JSONシリアライズに含まれるHTMLエンティティをエスケープするかどうかを指定します（デフォルト値は`true`）。

* `config.active_support.use_standard_json_time_format`: ISO 8601フォーマットに従った日付のシリアライズを行なうかどうかを指定します。デフォルトは`true`です。

* `config.active_support.time_precision`: JSONエンコードされた時間値の精度（小数点以下の桁数）を指定します（デフォルト値は`3`）。

* `config.active_support.use_sha1_digests`: セキュリティ上重要でないダイジェスト（ETagヘッダーなど）の生成にMD5ではなくSHA-1を使うかどうかを指定します（デフォルト値は`false`）。

* `ActiveSupport::Logger.silencer`: `false`に設定すると、ブロック内でのログ出力を抑制する機能がオフになります（デフォルト値は`true`）。

* `ActiveSupport::Cache::Store.logger`: キャッシュストアの操作中に使うロガーを指定します。

* `ActiveSupport::Deprecation.behavior`: `config.active_support.deprecation`に対するもうひとつのセッターであり、Railsの非推奨警告メッセージの表示方法を設定します。

* `ActiveSupport::Deprecation.silence`: ブロックを1つ引数に取り、すべての非推奨警告メッセージを抑制します。

* `ActiveSupport::Deprecation.silenced`: 非推奨警告メッセージを表示するかどうかを指定します。

### Active Jobを設定する

`config.active_job`には以下の設定オプションがあります。

* `config.active_job.queue_adapter`: キューイングのバックエンドで使うアダプタを設定します（デフォルト値は`:async`）。Railsにビルトインされているアダプタの最新リストについては[ActiveJob::QueueAdapters APIドキュメント](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html)を参照してください。

    ```ruby
    # Be sure to have the adapter's gem in your Gemfile
    # and follow the adapter's specific installation
    # and deployment instructions.
    config.active_job.queue_adapter = :sidekiq
    ```

* `config.active_job.default_queue_name`: デフォルトのキュー名を変更できます（デフォルト値は`"default"`）。

    ```ruby
    config.active_job.default_queue_name = :medium_priority
    ```

* `config.active_job.queue_name_prefix`: すべてのジョブで使われるキュー名のプレフィックス（空白以外）をオプションで設定できます。デフォルトは空白であり、プレフィックスは追加されません。

    以下の設定は、渡されたジョブをproduction環境で実行するときに`production_high_priority`キューに置きます。

    ```ruby
    config.active_job.queue_name_prefix = Rails.env
    ```

    ```ruby
    class GuestsCleanupJob < ActiveJob::Base
      queue_as :high_priority
      #....
    end
    ```

* `config.active_job.queue_name_delimiter`: デフォルト値は`'_'`です。`queue_name_prefix`が設定されている場合、`queue_name_delimiter`によってプレフィックス前のキュー名にプレフィックスが追加されます。

    以下の設定は、渡されたジョブを`video_server.low_priority`キューに置きます。

    ```ruby
    # prefix must be set for delimiter to be used
    config.active_job.queue_name_prefix = 'video_server'
    config.active_job.queue_name_delimiter = '.'
    ```

    ```ruby
    class EncoderJob < ActiveJob::Base
      queue_as :low_priority
      #....
    end
    ```

* `config.active_job.logger`: Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Active Jobからの情報をログ出力するために使用されます。`logger`をActive JobクラスかActive Jobインスタンスで呼ぶと、このログを読み出せます。ログ出力を無効にするには`nil`を設定します。

### Action Cableを設定する

* `config.action_cable.url`: Action CableサーバーがホスティングされているURLの文字列を受け取ります。Action Cableサーバーがメインのアプリと別の場所で動いている場合にこのオプションが使えます。

* `config.action_cable.mount_path`: メインサーバー処理の一環としてAction Cableをマウントする場所を文字列で指定します（デフォルト値は`/cable`）。通常のRailsサーバーとして使う場合は、`nil`を設定することでAction Cableをマウントしなくなります。

### Active Storageを設定する

`config.active_storage`には以下の設定オプションがあります。

* `config.active_storage.analyzers`: Active Storage blobで利用できるアナライザをクラスの配列で指定します（デフォルト値は`[ActiveStorage::Analyzer::ImageAnalyzer, ActiveStorage::Analyzer::VideoAnalyzer]`）。前者は画像のblobから幅（width）と高さ（height）を取得でき、後者は動画のblobから幅（width）、高さ（height）、長さ（duration）、角度（angle）、アスペクト比（aspect ratio）を取り出せます。

* `config.active_storage.previewers`: Active Storage blobで利用できる画像プレビューアをクラスの配列で指定します（デフォルト値は`[ActiveStorage::Previewer::PDFPreviewer, ActiveStorage::Previewer::VideoPreviewer]`）。前者はPDF blobの最初のページからサムネイルを取得でき、後者は動画blogから動画を代表するフレームを取り出せます。

* `config.active_storage.paths`: プレビューアやアナライザのコマンドの場所をハッシュのオプションで指定します。デフォルト値は`{}`で、この場合コマンドをデフォルトのパスで探索します。以下のいずれのオプションもハッシュに含められます。
   * `:ffprobe` - ffprobe実行ファイルの場所
   * `:mutool` - mutool実行ファイルの場所
   * `:ffmpeg` - ffmpeg実行ファイルの場所

  ```ruby
  config.active_storage.paths[:ffprobe] = '/usr/local/bin/ffprobe'
  ```

* `config.active_storage.variable_content_types`: Active StorageでImageMagickを用いて変換するcontent typeを文字列の配列で指定します（デフォルト値は`%w(image/png image/gif image/jpg image/jpeg image/vnd.adobe.photoshop)`）。

* `config.active_storage.content_types_to_serve_as_binary`: Active Storageで添付ファイルとして扱うcontent typeを文字列の配列で指定します（デフォルト値は`%w(text/html
text/javascript image/svg+xml application/postscript application/x-shockwave-flash text/xml application/xml application/xhtml+xml)`）。

* `config.active_storage.queue`: blobコンテンツの解析やblog破棄などのジョブ実行に使うActive Jobキュー名を指定します。

  ```ruby
 config.active_job.queue = :low_priority
 ```

* `config.active_storage.logger`: Active Storageで使うロガーを指定します。Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。

  ```ruby
  config.active_job.logger = ActiveSupport::Logger.new(STDOUT)
  ```

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

環境変数を経由してデータベース接続を設定する方法が、`config/database.yml`を使う方法と環境変数による方法の2とおりあるので、この2つがどのように相互作用するかを理解しておくことが重要です。

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

今度は`ENV['DATABASE_URL']`の接続情報は無視されました。アダプタとデータベース名が変わっていることにご注目ください。

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

NOTE: Railsでデータ保存用にSQLite3データベースが採用されているのは、設定なしですぐに使えるようにするためです。RailsではSQLiteに代えてMySQLやPostgreSQLなどを使うこともできますし、データベース接続用のプラグインも多数あります。production環境で何らかのデータベースを使用する場合、そのためのアダプタはたいていの場合Railsに含まれています。

#### MySQLデータベースを設定する

Rails同梱のSQLite3に代えてMySQLを採用した場合、`config/database.yml`の記述方法を少し変更します。developmentセクションの記述は以下のようになります。

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

開発環境のコンピュータにMySQLがインストールされており、ユーザー名root、パスワードなしで接続できるのであれば、上の設定で接続できるようになるはずです。接続できない場合は、`development`セクションのユーザー名またはパスワードを適切なものに変更してください。

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

```yaml
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

Railsにデフォルトで備わっている環境は、「development」「test」「production」の3つです。通常はこの3つの環境で事足りますが、場合によっては環境を追加したいこともあります。

たとえば、production環境をミラーコピーしたサーバーがあるが、テスト目的でのみ使用したいという場合を想定してみましょう。このようなサーバーは通常「stagingサーバー(staging server)」と呼ばれます。staging環境をサーバーに追加したいのであれば、`config/environments/staging.rb`というファイルを作成するだけで済みます。その際にはなるべく`config/environments`にある既存のファイルを流用し、必要な部分のみを変更するようにしてください。

このようにして追加された環境は、デフォルトの3つの環境と同じように利用できます。`rails server -e staging`を実行すればステージング環境でサーバーを起動でき、`rails console -e staging`や`Rails.env.staging?`なども動作するようになります。


### サブディレクトリにデプロイする (相対URLルートの使用)

Railsアプリの実行は、アプリのルートディレクトリ(`/`など)で行なうことが前提となっています。この節では、アプリを下のディレクトリで実行する方法について説明します。

ここでは、アプリを"/app1"ディレクトリにデプロイしたいとします。これを行なうには、適切なルーティングを生成できるディレクトリをRailsに指示する必要があります。

```ruby
config.relative_url_root = "/app1"
```

ディレクトリは`RAILS_RELATIVE_URL_ROOT`環境変数でも設定できます。

これで、リンクが生成される時に「/app1」がディレクトリ名の前に追加されます。

#### Passengerを使う

Passengerを使用すると、アプリを簡単にサブディレクトリで実行できます。設定方法について詳しくは、[passengerマニュアル](https://www.phusionpassenger.com/library/deploy/apache/deploy/ruby/#deploying-an-app-to-a-sub-uri-or-subdirectory)を参照してください。

#### リバースプロキシを使う

リバースプロキシでアプリを配信すると、通常の配信方法に比べて確実に多くのメリットを得られます。アプリで必要とされるコンポーネントを層として追加することで、サーバーをよりきめ細かく制御できます。

現代的なWebサーバーの多くは、キャッシュサーバーやアプリサーバーなどの付随的要素をバランシングするプロキシサーバーとして使うことができます。

そうしたアプリサーバーのひとつに、リバースプロキシの背後で実行する[Unicorn](https://bogomips.org/unicorn/)があります。
 
この場合、アプリケーションサーバー（Unicorn）からの接続を受け付けられるようプロキシサーバー（NGINXやApacheなど）を設定する必要があるでしょう。Unicornは、デフォルトでは8080番ポートのTCP接続をリッスンしますが、設定を変えることで、ポート番号を変更することもソケットを使えるようにすることもできます。

Unicornについては、[README](https://bogomips.org/unicorn/README.html)で詳しい情報を得たり、Unicornを支える[哲学](https://bogomips.org/unicorn/PHILOSOPHY.html)を理解することができます。

アプリケーションサーバーの設定が完了したら、Webサーバーを適切に設定して、アプリケーションサーバーへのリクエストをプロキシしなければなりません。NGINXの設定はたとえば以下のようになります。

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

最新情報については必ず[NGINX documentation](https://nginx.org/en/docs/)を参照してください。

Rails環境の設定
--------------------------

一部の設定については、Railsの外部から環境変数として与えることもできます。以下の環境変数は、Railsのさまざまな部分で認識されます。

* `ENV["RAILS_ENV"]`: Railsが実行される環境 (production、development、testなど) を定義します。

* `ENV["RAILS_RELATIVE_URL_ROOT"]`: [アプリケーションをサブディレクトリにデプロイする](configuring.html#サブディレクトリにデプロイする-相対urlルートの使用)ときにルーティングシステムがURLを認識するために使用されます。

* `ENV["RAILS_CACHE_ID"]`と`ENV["RAILS_APP_VERSION"]`: Railsのキャッシュを扱うコードで拡張キャッシュを生成するために使用されます。これにより、ひとつのの中で複数の独立したキャッシュを扱うことができるようになります。


イニシャライザファイルを使用する
-----------------------

Railsは、フレームワークの読み込みとすべてのgemの読み込みが終わってから、イニシャライザの読み込みを開始します。イニシャライザとは、の`config/initializers`ディレクトリに保存されるRubyファイルのことです。たとえば各部分のオプション設定をイニシャライザに保存しておき、フレームワークとgemがすべて読み込まれた後に適用することができます。

NOTE: イニシャライザを置くディレクトリにサブフォルダを作ってイニシャライザを整理することもできます。Railsはイニシャライザ用のディレクトリの下のすべての階層を探して実行してくれます。

TIP: Railsではイニシャライザのファイル名に番号を付けて読み込み順を制御することをサポートしていますが、特定の順序で読み込む必要のあるコードを1つのファイル内にすべて記述するのがよりよい方法です。この方がファイル名がすっきりしますし、依存関係も明確になり、アプリに新しい概念をかぶせるときにも有用です。

イニシャライザの実行順序を指定したい場合は、イニシャライザのファイル名を使用して実行順序を制御できます。各フォルダのイニシャライザはアルファベット順に読み込まれます。たとえば`01_critical.rb`は最初に読み込まれ、`02_normal.rb`は次に読み込まれます。

初期化イベント
---------------------

Railsにはフック可能な初期化イベントが5つあります。以下に紹介するこれらのイベントは、実際に実行される順序で掲載しています。

* `before_configuration`: これは`Rails::Application`からアプリケーション定数を継承した直後に実行されます。`config`呼び出しは、このイベントより前に評価されますので注意してください。

* `before_initialize`: これは、`:bootstrap_hook`イニシャライザを含む初期化プロセスの直前に、直接実行されます。`:bootstrap_hook`は、Railsアプリケーション初期化プロセスの冒頭近くにあります。

* `to_prepare`: これは、Railties（Railsのコアライブラリの1つ）用のイニシャライザと自身用のイニシャライザがすべて実行された後、かつ事前一括読み込み(eager loading)の実行とミドルウェアスタックの構築が行われる前に実行されます。さらに重要な点は、これは`development`モードではサーバーへのリクエストのたびに必ず実行されますが、`production`モードと`test`モードでは起動時に1度だけしか実行されないことです。

* `before_eager_load`: これは、事前一括読み込みが行われる前に直接実行されます。これは`production`環境ではデフォルトの動作ですが、`development`環境では異なります。

* `after_initialize`: これは、の初期化が終わり、かつ`config/initializers`以下のイニシャライザが実行された後に実行されます。

これらのフックのイベントを定義するには、`Rails::Application`、`Rails::Railtie`、または`Rails::Engine`サブクラス内でブロック記法を使用します。

```ruby
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # 初期化コードをここに書く
    end
  end
end
```

あるいは、`Rails.application`オブジェクトに対して`config`メソッドを実行することで行なうこともできます。

```ruby
Rails.application.config.before_initialize do
  # 初期化コードをここに書く
end
```

WARNING: アプリの一部、特にルーティング周りでは、`after_initialize`ブロックが呼び出された時点では設定が完了していないものがあります。

### `Rails::Railtie#initializer`

Railsでは、`Rails::Railtie`に含まれる`initializer`メソッドですべて定義され、起動時に実行されるイニシャライザがいくつもあります。以下はAction Controllerの`set_helpers_path`イニシャライザから取った例です。

```ruby
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
```

この`initializer`メソッドは3つの引数を取ります。1番目はイニシャライザの名前、2番目はオプションハッシュ(上の例では使ってません)、そして3番目はブロックです。オプションハッシュに含まれる`:before`キーを使って、新しいイニシャライザより前に実行したいイニシャライザを指定することができます。同様に、`:after`キーを使って、新しいイニシャライザより _後_ に実行したいイニシャライザを指定できます。

`initializer`メソッドを使用して定義されたイニシャライザは、定義された順序で実行されます。ただし`:before`や`:after`を使用した場合はこの限りではありません。

WARNING: イニシャライザが起動される順序は、論理的に矛盾が生じない限りにおいて、beforeやafterを使用していかなる順序に変更することもできます。たとえば、"one"から"four"までの4つのイニシャライザがあり、かつこの順序で定義されたとします。ここで"four"を"four"より _前_ かつ"three"よりも _後_ になるように定義すると論理矛盾が発生し、イニシャライザの実行順を決定できなくなってしまいます。

`initializer`メソッドのブロック引数は、アプリ自身のインスタンスです。そのおかげで、上の例で示したように、`config`メソッドを使用してアプリの設定にアクセスできます。

実は`Rails::Application`は`Rails::Railtie`を間接的に継承しています。そのおかげで、`config/application.rb`で`initializer`メソッドを使用して用のイニシャライザを定義できます。

### イニシャライザ

Railsにあるイニシャライザのリストを以下にまとめました。これらは定義された順序で並んでおり、特記事項のない限り実行されます。

* `load_environment_hook`: これはプレースホルダとして使用されます。具体的には、`:load_environment_config`を定義してこのイニシャライザより前に実行したい場合に使用します。

* `load_active_support`: Active Supportの基本部分を設定する`active_support/dependencies`が必要です。デフォルトの`config.active_support.bare`が信用できない場合には`active_support/all`も必要です。

* `initialize_logger`: ここより前の位置で`Rails.logger`を定義するイニシャライザがない場合、のロガー(`ActiveSupport::Logger`オブジェクト)を初期化し、`Rails.logger`にアクセスできるようにします。

* `initialize_cache`: `Rails.cache`が未設定の場合、`config.cache_store`の値を参照してキャッシュを初期化し、その結果を`Rails.cache`として保存します。そのオブジェクトが`middleware`メソッドに応答する場合、そのミドルウェアをミドルウェアスタックの`Rack::Runtime`の前に挿入します。

* `set_clear_dependencies_hook`: `active_record.set_dispatch_hooks`へのフックを提供します。このイニシャライザより前に実行されます。このイニシャライザは、`cache_classes`が`false`の場合にのみ実行されます。そして、このイニシャライザは`ActionDispatch::Callbacks.after`を使用して、オブジェクト空間からのリクエスト中に参照された定数を削除します。これにより、これらの定数は以後のリクエストで再度読み込まれるようになります。

* `initialize_dependency_mechanism`: `config.cache_classes`がtrueの場合、`ActiveSupport::Dependencies.mechanism`で依存性を(`load`ではなく)`require`に設定します。

* `bootstrap_hook`: このフックはすべての設定済み`before_initialize`ブロックを実行します。

* `i18n.callbacks`: development環境の場合、`to_prepare`コールバックを設定します。このコールバックは、最後にリクエストが発生した後にロケールが変更されると`I18n.reload!`を呼び出します。productionモードの場合、このコールバックは最初のリクエストでのみ実行されます。

* `active_support.deprecation_behavior`: 環境に対する非推奨レポート出力を設定します。development環境ではデフォルトで`:log`、production環境ではデフォルトで`:notify`、test環境ではデフォルトで`:stderr`が指定されます。`config.active_support.deprecation`に値が設定されていない場合、このイニシャライザは、現在の環境に対応する`config/environments`ファイルに値を設定するよう促すメッセージを出力します。値は配列で設定することもできます。

* `active_support.initialize_time_zone`: `config.time_zone`の設定に基いてのデフォルトタイムゾーンを設定します（デフォルト値は"UTC"）。

* `active_support.initialize_beginning_of_week`: `config.beginning_of_week`の設定に基づいてのデフォルトの週開始日を設定します（デフォルト値は`:monday`）。

* `action_dispatch.configure`: `ActionDispatch::Http::URL.tld_length`を構成して、`config.action_dispatch.tld_length`の値(トップレベルドメイン名の長さ)が設定されるようにします。

* `active_support.set_configs`: Sets up Active Support by using the settings in `config.active_support` by `send`'ing the method names as setters to `ActiveSupport` and passing the values through.

* `action_dispatch.configure`: Configures the `ActionDispatch::Http::URL.tld_length` to be set to the value of `config.action_dispatch.tld_length`.

* `action_view.set_configs`: `config.action_view`の設定を使ってAction Viewを設定します。使われる`config.action_view`の設定は、メソッド名が`ActionView::Base`に対するセッターとして`send`され、それを経由して値を渡すことによって行われます。

* `action_controller.assets_config`: 明示的な設定がない場合、`config.actions_controller.assets_dir`を初期化してアプリのpublicディレクトリに設定します。
 
* `action_controller.set_helpers_path`: Action Controllerの`helpers_path`をアプリの`helpers_path`に設定します。
 
* `action_controller.parameters_config`: `ActionController::Parameters`のstrong parametersオプションを設定します。
 
* `action_controller.set_configs`: `config.action_controller`の設定を使用してAction Controllerを設定します。使用される`config.action_controller`の設定は、メソッド名が`ActionController::Base`に対するセッターとして`send`され、それを経由して値が渡されることによって行われます。
 
* `action_controller.compile_config_methods`: 指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

* `active_record.initialize_timezone`: `ActiveRecord::Base.time_zone_aware_attributes`をtrueに設定し、`ActiveRecord::Base.default_timezone`をUTCに設定します。属性がデータベースから読み込まれた場合、それらの属性は`Time.zone`で指定されたタイムゾーンに変換されます。

* `active_record.logger`: `Rails.logger`に対する設定が行われていない場合に`ActiveRecord::Base.logger`を設定します。

* `active_record.set_configs`: `config.active_record`の設定を使ってActive Recordを設定します。使われる`config.active_record`の設定は、メソッド名が`ActiveRecord::Base`に対するセッターとして`send`され、それを経由して値を渡すことによって行われます。

* `active_record.initialize_database`: データベース設定を`config/database.yml`(デフォルトの読み込み元)から読み込み、現在の環境で接続を確立します。

* `active_record.log_runtime`: `ActiveRecord::Railties::ControllerRuntime`をインクルードします。これは、リクエストでActive Record呼び出しにかかった時間をロガーにレポートする役割を担います。

* `active_record.set_reloader_hooks`: `config.cache_classes`が`false`に設定されている場合に、再読み込み可能なデータベース接続をすべてリセットします。
 
* `active_record.add_watchable_files`: ウォッチ対象ファイルに`schema.rb`と`structure.sql`を追加します。
 
* `active_job.logger`: 設定されていない場合、`ActiveJob::Base.logger`を`Rails.logger`に設定します。
 
* `active_job.set_configs`: `config.active_job `の設定を使用してActive Jobを設定します。メソッド名を`ActiveJob::Base`に対するセッターとして`send`し、それを経由して値を渡すことで設定します。

* `action_mailer.logger`: 設定されていない場合、`ActionMailer::Base.logger`を`Rails.logger`に設定します。

* `action_mailer.set_configs`: `config.action_mailer`の設定を使用してAction Mailerを設定します。メソッド名を`ActionMailer::Base`に対するセッターとして`send`し、それを経由して値を渡すことで設定します。

* `action_mailer.compile_config_methods`: 指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

* `set_load_path`: このイニシャライザは`bootstrap_hook`より前に実行されます。`vendor`、`lib`、`app`以下のすべてのディレクトリ、`config.load_paths`で指定されるすべてのパスが`$LOAD_PATH`に追加されます。

* `set_autoload_paths`: このイニシャライザは`bootstrap_hook`より前に実行されます。`app`以下のすべてのサブディレクトリと、`config.autoload_paths`と`config.eager_load_paths`と`config.autoload_once_paths`で指定したすべてのパスが`ActiveSupport::Dependencies.autoload_paths`に追加されます。

* `add_routing_paths`: デフォルトですべての`config/routes.rb`ファイルを読み込み、のルーティングを設定します。この`config/routes.rb`ファイルは、アプリやRailtiesやエンジンにあります。

* `add_locales`: `config/locales`にあるファイルを`I18n.load_path`に追加し、そのパスで指定された場所にある訳文にアクセスできるようにします。この`config/locales`ファイルは、アプリやRailtiesやエンジンにあります。

* `add_view_paths`: アプリやrailtiesやエンジンにある`app/views`へのパスを、アプリのビューファイルへの探索パスに追加します。

* `load_environment_config`: 現在の環境に`config/environments`を読み込みます。

* `prepend_helpers_path`: アプリやrailtiesやエンジンに含まれる`app/helpers`ディレクトリをヘルパーへの参照パスに追加します。

* `load_config_initializers`: アプリやrailtiesやエンジンに含まれる`config/initializers`にあるRubyファイルをすべて読み込みます。このディレクトリに置かれているファイルは、フレームワークの読み込みがすべて読み終わってから行いたい設定を保存しておくのにも使用できます。

* `engines_blank_point`: エンジンの読み込みが完了する前に行いたい処理がある場合に使用できる初期化ポイントへのフックを提供します。初期化処理がここまで進んだ後は、railtiesやエンジンのイニシャライザがすべて起動します。

* `add_generator_templates`: アプリやrailtiesやエンジンにある`lib/templates`ディレクトリにあるジェネレータ用のテンプレートを探索し、それらを`config.generators.templates`設定に追加します。この設定によって、すべてのジェネレータからテンプレートを参照できるようになります。

* `ensure_autoload_once_paths_as_subset`: `config.autoload_once_paths`に、`config.autoload_paths`以外のパスが含まれないようにします。それ以外のパスが含まれている場合は例外が発生します。

* `add_to_prepare_blocks`: アプリやrailtiesやエンジンのすべての`config.to_prepare`呼び出しにおけるブロックが、Action Dispatchの`to_prepare`に追加されます。Action Dispatchはdevelopmentモードではリクエストごとに実行され、productionモードでは最初のリクエストより前に実行されます。

* `add_builtin_route`: アプリがdevelopment環境で動作している場合、`rails/info/properties`へのルーティングをアプリのルーティングに追加します。このルーティングにアクセスすると、デフォルトのRailsアプリで`public/index.html`に表示されるのと同様の詳細情報(RailsやRubyのバージョンなど)が表示されます。

* `build_middleware_stack`: アプリのミドルウェアスタックを構成し、`call`メソッドを持つオブジェクトを返します。この`call`メソッドは、リクエストに対するRack環境のオブジェクトを引数に取ります。

* `eager_load!`: `config.eager_load`が`true`に設定されている場合、`config.before_eager_load`フックを実行し、続いて`eager_load!`を呼び出します。この呼び出しにより、すべての`config.eager_load_namespaces`が呼び出されます。

* `finisher_hook`: アプリの初期化プロセス完了後に実行されるフックを提供します。フックより後は、アプリやrailtiesやエンジンの`config.after_initialize`ブロックがすべて読み込まれます。

* `set_routes_reloader`: `ActiveSupport::Callbacks.to_run`を使ってルーティングを再読み込みするようAction Dispatchを構成します。

* `disable_dependency_loading`: `config.eager_load`が`true`の場合は自動依存性読み込み(automatic dependency loading)を無効にします。

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

接続プールはデフォルトではActive Recordで取り扱われるため、アプリケーションサーバーの動作は、ThinやmongrelやUnicornなどどれであっても同じ振る舞いになります。最初はデータベース接続のプールは空で、必要に応じて追加接続が作成され、接続プールの上限に達するまで接続が追加されます。

1つのリクエストの中での接続は常に次のような流れになります: 初回はデータベースアクセスの必要な接続を確保し、以後はその接続があることを再確認します。リクエストの終わりでは、キューで待機する今後のリクエストに備えて接続スロットを追加で利用できるようになります。

利用可能な数よりも多くの接続を使おうとすると、Active Recordは接続をブロックし、プールからの接続を待ちます。接続が行えなくなると、以下のようなタイムアウトエラーがスローされます。

```ruby
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5 seconds. The max pool size is currently 5; consider increasing it:
```

上のエラーが発生するような場合は、`database.yml`の`pool`オプションの数値を増やして接続プールのサイズを増やすことで対応できます。

NOTE: をマルチスレッド環境で実行している場合、多くのスレッドが多くの接続に同時アクセスする可能性があります。現時点のリクエストの負荷によっては、限られた接続数を多数のスレッドが奪い合うようなことになるかもしれません。

カスタム設定
--------------------

Railsでは、カスタム設定されたRails設定オブジェクトを`config.x`名前空間の下か直接`config`の下に配置することで、自分のコードを設定できます。2つの設定ポイントの大きな違いは、 _ネストした設定_ （`config.x.nested.nested.hi`など）の場合は`config.x`名前空間を使うべきであり、 _単一レベル_（`config.hello`など）の場合は`config`でよいという点です。

  ```ruby
  config.x.payment_processing.schedule = :daily
  config.x.payment_processing.retries  = 3
  config.super_debugger = true
  ```

上の設定ポイントで設定した内容は、その設定オブジェクトを経由して利用できるようになります。

  ```ruby
  Rails.configuration.x.payment_processing.schedule # => :daily
  Rails.configuration.x.payment_processing.retries  # => 3
  Rails.configuration.x.payment_processing.not_set  # => nil
  Rails.configuration.super_debugger                # => true
  ```

`Rails::Application.config_for`を用いて、設定ファイルをまとめて読み込むこともできます。

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

検索エンジンのインデックス登録
-----------------------

自分のアプリの一部のページについて、GoogleやBingやYahooやDuck Duck Goといった検索サイトに見つからないようにしたい場合があります。検索エンジンのロボットは、サイトを自分たちのインデックスに登録するときに、真っ先に`http://your-site.com/robots.txt`ファイルをチェックして、インデックス登録を許可されているページを認識します。
Railsではこのファイルを`/public`フォルダの下に置けます。デフォルトではアプリのすべてのページについて検索エンジンによるインデックス登録を許可します。アプリのすべてのページについてインデックス登録を不許可にしたい場合は、次のように書きます。

```
User-agent: *
Disallow: /
```

特定のページのみをブロックする場合は、より複雑な構文が必要です。詳しくは[robotstxt.orgの公式ドキュメント](http://www.robotstxt.org/robotstxt.html)を参照してください。

イベントベースのファイルシステム監視
---------------------------

Railsで[listen gem](https://github.com/guard/listen)を読み込んで`config.cache_classes`を`false`に設定すると、イベントベースのファイルシステム監視でファイルの変更を検出できるようになります。

```ruby
group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
```

それ以外の場合、Railsは変更の有無を検出するためにアプリのツリーをフルスキャンします。

LinuxやmacOSでは追加のgemは不要ですが、[*BSD](https://github.com/guard/listen#on-bsd)や
[Windows](https://github.com/guard/listen#on-windows)では追加gemがいくつか必要になります。

[一部の設定はサポートされていない](https://github.com/guard/listen#issues--limitations)点にご注意ください。
