Ruby on Rails 5.0 リリースノート
===============================

Rails 5.0の注目ポイント

* Action Cable
* Rails API
* Active Record属性API
* テストランナー
* Rakeコマンドを`rails`コマンドに統一
* Sprockets 3
* Turbolinks 5
* Ruby 2.2.2以上が必須

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/5-0-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 5.0へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 4.2までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 5.0にアップデートしてください。アップグレードの注意点などについては[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-4-2%E3%81%8B%E3%82%89rails-5-0%E3%81%B8%E3%81%AE%E3%82%A2%E3%83%83%E3%83%97%E3%82%B0%E3%83%AC%E3%83%BC%E3%83%89) を参照してください。


主要な変更
--------------

### Action Cable

Action CableはRails 5に新しく導入されたフレームワークであり、Railsアプリケーションで [WebSockets](https://ja.wikipedia.org/wiki/WebSocket) とその他の部分をシームレスに統合します。

Action Cableが導入されたことで、Railsアプリケーションの効率の良さとスケーラビリティを損なわずに、通常のRailsアプリケーションと同じスタイル・方法でリアルタイム機能をRubyで書くことができます。クライアント側のJavaScriptフレームワークとサーバー側のRubyフレームワークを同時に提供する、フルスタックのフレームワークです。Active RecordなどのORMで書かれたすべてのドメインモデルにアクセスできます。

詳しくは [Action Cableの概要](action_cable_overview.html) をご覧ください。

### API アプリケーション

APIのみを提供するシンプルなアプリケーションをRailsで簡単に作成できるようになりました。
[Twitter](https://dev.twitter.com) APIや [GitHub](http://developer.github.com) APIのような一般公開APIサーバーはもちろん、カスタムアプリケーション用APIサーバーの作成・公開にも便利です。

API Railsアプリケーションの生成には次のコマンドを使います。

```bash
$ rails new my_api --api
```

上のコマンドでは次の3つの重要な動作を実行します。

- 利用するミドルウェアを通常よりも絞り込んでアプリケーションを起動するよう設定します。特に、ブラウザ向けアプリケーションで有用なミドルウェア（cookiesのサポートなど）を一切利用しなくなります。
- `ApplicationController`を、通常の`ActionController::Base`の代わりに`ActionController::API`から継承します。ミドルウェアと同様、Action Controllerモジュールのうち、ブラウザ向けアプリケーションでしか使われないモジュールをすべて除外します。
- ビュー、ヘルパー、アセットを生成しないようジェネレーターを設定します。

生成されたAPIアプリケーションはAPI提供の基礎となり、必要に応じて[機能を追加](api_app.html)できるようになります。

詳しくは [RailsによるAPI専用アプリケーション](api_app.html) をご覧ください。

### Active Record属性API

モデルでtypeの属性を定義します。必要であれば、既存の属性をオーバーライドすることもできます。
これを使って、モデルに割り当てられたSQLとの値の変換方法を制御できます。
また、`ActiveRecord::Base.where`に渡された値の動作を変更することもできます。これによって、実装の詳細やモンキーパッチに頼ることなく、Active Recordの多くをサポートするドメインオブジェクトを使えるようになります。

以下を行うこともできます。

* Active Recordで検出されたtypeはオーバーライドできます。
* デフォルトの動作も指定できます。
* 属性にはデータベースのカラムは不要です。

```ruby

# db/schema.rb
create_table :store_listings, force: true do |t|
  t.decimal :price_in_cents
  t.string :my_string, default: "original default"
end

# app/models/store_listing.rb
class StoreListing < ActiveRecord::Base
end 

store_listing = StoreListing.new(price_in_cents: '10.1')

# 変更前
store_listing.price_in_cents # => BigDecimal.new(10.1)
StoreListing.new.my_string # => "original default"

class StoreListing < ActiveRecord::Base
  attribute :price_in_cents, :integer # カスタムのtype
  attribute :my_string, :string, default: "new default" # デフォルト値
  attribute :my_default_proc, :datetime, default: -> { Time.now } # デフォルト値
  attribute :field_without_db_column, :integer, array: true
end 

# 変更後
store_listing.price_in_cents # => 10
StoreListing.new.my_string # => "new default"
StoreListing.new.my_default_proc # => 2015-05-30 11:04:48 -0600
model = StoreListing.new(field_without_db_column: ["1", "2", "3"])
model.attributes # => {field_without_db_column: [1, 2, 3]}
```

**カスタムTypeの作成:**

独自のtypeを定義できます。独自のtype定義は、値のtypeで定義されたメソッドに応答する場合に限り行えます。`deserialize`メソッドや`cast`メソッドは、作成したtypeオブジェクトで呼び出され、データベースやコントローラからのraw入力を引数に取ります。これは、お金のデータで通貨をカスタム換算する場合などに便利です。

**クエリ:**

`ActiveRecord::Base.where`が呼び出されると、モデルのクラスで定義されたtypeを使って値をSQLに変換し、そのtypeオブジェクトで`serialize`を呼び出します。

これにより、SQLクエリの発行時に行う値の変換方法を、オブジェクトで指定できるようになります。

**ダーティトラッキング:**

このtypeの属性は、「ダーティトラッキング」の実行方法を変更できるようになります。

詳しくは [ドキュメント](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html) をご覧ください。


### テストランナー

新しいテストランナーが導入され、Railsからのテスト実行機能が強化されました。
`bin/rails test`と入力するだけでテストランナーを使えます。

テストランナーは、`RSpec`、`minitest-reporters`、`maxitest`などから着想を得ています。
次のような多数の改良が施されています。

- テストの行番号を指定して単体テストを実行。
- テストの行番号を指定して複数テストを実行。
- 失敗の場合のメッセージが改良され、失敗したテストをすぐに再実行できるようになった。
- `-f`オプションを付けると失敗時に即座にテストを停止できるようになり、全テストの完了を待たなくて済む
- `-d`オプションを付けるとテストが完了するまでメッセージ出力を待たせることができる。
- `-b`オプションを付けると完全な例外バックトレースを出力できる。
- `minitest`と統合されてさまざまなオプションが利用できるようになった: `-s`でシードデータを指定、`-n`で特定のテスト名を指定して実行、`-v`で詳細出力をオン、など。
- テスト出力に色が追加された。

Railties
--------

変更の詳細については[Changelog][railties]を参照してください。

### 削除されたもの

*  デバッガのサポートを削除。`debugger`はRuby 2.2でサポートされないため、今後はbyebugを利用すること。
    ([commit](https://github.com/rails/rails/commit/93559da4826546d07014f8cfa399b64b4a143127))

*   非推奨の`test:all`タスクと`test:all:db`タスクを削除。
    ([commit](https://github.com/rails/rails/commit/f663132eef0e5d96bf2a58cec9f7c856db20be7c))

*  非推奨の`Rails::Rack::LogTailer`を削除。
    ([commit](https://github.com/rails/rails/commit/c564dcb75c191ab3d21cc6f920998b0d6fbca623))

*   非推奨の`RAILS_CACHE`定数を削除。
    ([commit](https://github.com/rails/rails/commit/b7f856ce488ef8f6bf4c12bb549f462cb7671c08))

*   非推奨の`serve_static_assets`設定を削除。
    ([commit](https://github.com/rails/rails/commit/463b5d7581ee16bfaddf34ca349b7d1b5878097c))

*   ドキュメント作成タスク`doc:app`、`doc:rails`、`doc:guides`を削除。
    ([commit](https://github.com/rails/rails/commit/cd7cc5254b090ccbb84dcee4408a5acede25ef2a))

*   `Rack::ContentLength`ミドルウェアをデフォルトから削除。([Commit](https://github.com/rails/rails/commit/56903585a099ab67a7acfaaef0a02db8fe80c450))

### 非推奨

*   `config.static_cache_control`を廃止。今後は`config.public_file_server.headers`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/22173))

*  `config.serve_static_files`を廃止。今後は`config.public_file_server.enabled`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/22173))

*   `rails`タスク名前空間のタスクを削除。今後は`app`名前空間が使われる。
   （例: `rails:update`タスクや`rails:template`タスクは`app:update`や`app:template`に変更された）
    ([Pull Request](https://github.com/rails/rails/pull/23439))

### 主な変更点

*   Railsテストランナー`bin/rails test`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/19216))

*  新規アプリケーションやプラグインのREADMEがマークダウン形式の`README.md`になった。
    ([commit](https://github.com/rails/rails/commit/89a12c931b1f00b90e74afffcdc2fc21f14ca663),
     [Pull Request](https://github.com/rails/rails/pull/22068))

*   Railsアプリケーションをtouch `tmp/restart.txt`で再起動する`bin/rails restart`タスクを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18965))

*  すべての定義済みイニシャライザをRailsでの起動順に出力する`bin/rails initializers`タスクを追加。
    ([Pull Request](https://github.com/rails/rails/pull/19323))

*   developmentモードでのキャッシュのオンとオフを指定する`bin/rails dev:cache`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/20961))

*   development環境を自動でアップデートする`bin/update`スクリプトを追加。
    ([Pull Request](https://github.com/rails/rails/pull/20972))

*   rakeタスクを`bin/rails`で置き換え。
    ([Pull Request](https://github.com/rails/rails/pull/22457),
     [Pull Request](https://github.com/rails/rails/pull/22288))

*   生成されるアプリケーションはLinuxやMac OS X上で「ファイルシステムのイベント監視」（evented file system monitor）が有効になる。`--skip-listen`オプションを追加するとこの機能を無効にできる。
    ([commit](https://github.com/rails/rails/commit/de6ad5665d2679944a9ee9407826ba88395a1003)、[commit](https://github.com/rails/rails/commit/94dbc48887bf39c241ee2ce1741ee680d773f202))

*   生成したアプリケーションは、`RAILS_LOG_TO_STDOUT`環境変数を使ってproduction環境でSTDOUTへのログ出力を指定できる。
    ([Pull Request](https://github.com/rails/rails/pull/23734))

*   新しいアプリケーションでは、IncludeSudomainsヘッダのHSTS（HTTP Strict Transport Security）がデフォルトで有効になる。
    ([Pull Request](https://github.com/rails/rails/pull/23852))

*   アプリケーション ジェネレータから、新しく`config/spring.rb`ファイルが出力される。これを使用してSpringの監視対象となる共通ファイルを追加できる。
    ([commit](https://github.com/rails/rails/commit/b04d07337fd7bc17e88500e9d6bcd361885a45f8))

*  新規アプリケーション生成時にAction Mailerをスキップする`--skip-action-mailer` を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18288))

*   `tmp/sessions`ディレクトリと、これに関連するclear rakeタスクを削除。
    ([Pull Request](https://github.com/rails/rails/pull/18314))

*   scaffoldジェネレータで生成する`_form.html.erb`を、ローカル変数を使用するように変更。
    ([Pull Request](https://github.com/rails/rails/pull/13434))

*   production環境でクラスの自動読み込みを無効化。
    ([commit](https://github.com/rails/rails/commit/a71350cae0082193ad8c66d65ab62e8bb0b7853b))

Action Pack
-----------

変更の詳細については[Changelog][action-pack]を参照してください。

### 削除されたもの

*   `ActionDispatch::Request::Utils.deep_munge`を削除。
    ([commit](https://github.com/rails/rails/commit/52cf1a71b393486435fab4386a8663b146608996))

*   `ActionController::HideActions`を削除。
    ([Pull Request](https://github.com/rails/rails/pull/18371))

*  プレースホルダメソッドである`respond_to`と`respond_with`を削除し、[responders](https://github.com/plataformatec/responders) gemに移動。
    ([commit](https://github.com/rails/rails/commit/afd5e9a7ff0072e482b0b0e8e238d21b070b6280))

*   非推奨のアサーションファイルを削除。
    ([commit](https://github.com/rails/rails/commit/92e27d30d8112962ee068f7b14aa7b10daf0c976))

*   URLヘルパーで使われていた非推奨の文字列キーを削除。
    ([commit](https://github.com/rails/rails/commit/34e380764edede47f7ebe0c7671d6f9c9dc7e809))

*   非推奨の`only_path`オプションを`*_path`ヘルパーから削除。
    ([commit](https://github.com/rails/rails/commit/e4e1fd7ade47771067177254cb133564a3422b8a))

*  非推奨の`NamedRouteCollection#helpers`を削除。
    ([commit](https://github.com/rails/rails/commit/2cc91c37bc2e32b7a04b2d782fb8f4a69a14503f))

*  `#`を含まない`:to`オプション（非推奨）のルーティング定義サポートを削除。
    ([commit](https://github.com/rails/rails/commit/1f3b0a8609c00278b9a10076040ac9c90a9cc4a6))

*   非推奨の`ActionDispatch::Response#to_ary`を削除。
    ([commit](https://github.com/rails/rails/commit/4b19d5b7bcdf4f11bd1e2e9ed2149a958e338c01))

*   非推奨の`ActionDispatch::Request#deep_munge`を削除。
    ([commit](https://github.com/rails/rails/commit/7676659633057dacd97b8da66e0d9119809b343e))

*   非推奨の`ActionDispatch::Http::Parameters#symbolized_path_parameters`を削除。
    ([commit](https://github.com/rails/rails/commit/7fe7973cd8bd119b724d72c5f617cf94c18edf9e))

*  コントローラのテストから非推奨の`use_route`を削除。
    ([commit](https://github.com/rails/rails/commit/e4cfd353a47369dd32198b0e67b8cbb2f9a1c548))

*   `assigns`と`assert_template`を削除。これらのメソッドは[rails-controller-testing](https://github.com/rails/rails-controller-testing) gemに移動された。
    ([Pull Request](https://github.com/rails/rails/pull/20138))

### 非推奨

*   `*_filter`コールバックをすべて非推奨に指定。今後は`*_action`コールバックを使用。
    ([Pull Request](https://github.com/rails/rails/pull/18410))

*   結合テストメソッド`*_via_redirect`を非推奨に指定。今後同じ動作が必要な場合は、はリクエストの呼出し後に `follow_redirect!`を手動で実行すること。
    ([Pull Request](https://github.com/rails/rails/pull/18693))

*  `AbstractController#skip_action_callback`を非推奨に指定。今後は個別のskip_callbackメソッドを使用。
    ([Pull Request](https://github.com/rails/rails/pull/19060))

*  `render`メソッドの`:nothing`オプションを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/20336))

*  `head`メソッドの最初のパラメータを`Hash`として渡すことと、デフォルトのステータスコードの利用を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/20407))

*  ミドルウェアのクラス名を文字列やシンボルで表すことを非推奨に指定。今後はクラス名をそのまま使うこと。
    ([commit](https://github.com/rails/rails/commit/83b767ce))

*  MIMEタイプを定数として利用することを非推奨に指定（`Mime::HTML`など）。今後は「`Mime[:html]`」のように添字演算子内でシンボルを使うこと。
    ([Pull Request](https://github.com/rails/rails/pull/21869))

*  `redirect_to :back`を非推奨に指定。今後は`RedirectBackError`を避けるために、`redirect_back`を使用して必須の`fallback_location`引数を受け取ること。
    ([Pull Request](https://github.com/rails/rails/pull/22506))

*   `ActionDispatch::IntegrationTest`と`ActionController::TestCase`で位置引数（positional argument）を非推奨に指定。今後はキーワード引数を使用。([Pull Request](https://github.com/rails/rails/pull/18323))

*  パスパラメータ`:controller`と`:action`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/23980))

*   コントローラのインスタンスでのenvメソッドを非推奨に指定。
    ([commit](https://github.com/rails/rails/commit/05934d24aff62d66fc62621aa38dae6456e276be))

*   `ActionDispatch::ParamsParser`を非推奨に指定し、ミドルウェアスタックから削除。今後パラメーターパーサーの構成が必要な場合は`ActionDispatch::Request.parameter_parsers=`を使用。
    ([commit](https://github.com/rails/rails/commit/38d2bf5fd1f3e014f2397898d371c339baa627b1), [commit](https://github.com/rails/rails/commit/5ed38014811d4ce6d6f957510b9153938370173b))

### 主な変更点

*  コントローラのアクションの外部で任意のテンプレートでレンダリングする`ActionController::Renderer`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18546))

*   `ActionController::TestCase`と`ActionDispatch::Integration`のHTTPリクエストメソッドにキーワード引数構文を統合。
    ([Pull Request](https://github.com/rails/rails/pull/18323))

*   期限切れのないレスポンスをキャッシュする`http_cache_forever`をAction Controllerに追加。
    ([Pull Request](https://github.com/rails/rails/pull/18394))

*   リクエストのvariantのわかりやすい指定方法を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18939))

*   対応するテンプレートがない場合にはエラーの代わりに`head :no_content`でレンダリングする
    ([Pull Request](https://github.com/rails/rails/pull/19377))

*   コントローラのデフォルトのフォームビルダーをオーバーライドする機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/19736))

*   API専用アプリケーション向けのサポートを追加。API専用アプリケーションでは`ActionController::Base`の代わりに`ActionController::API`が追加される。
    ([Pull Request](https://github.com/rails/rails/pull/19832))

*   `ActionController::Parameters` は今後 `HashWithIndifferentAccess` を継承しない。
    ([Pull Request](https://github.com/rails/rails/pull/20868))

*  より安全にSSLを試したりオフにしたりできるよう、`config.force_ssl`と`config.ssl_options`を簡単に導入できるようにした。
    ([Pull Request](https://github.com/rails/rails/pull/21520))

*   `ActionDispatch::Static`に任意のヘッダーを返す機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/19135))

*   `protect_from_forgery`のprependのデフォルトを`false`に変更。
    ([commit](https://github.com/rails/rails/commit/39794037817703575c35a75f1961b01b83791191))

*   `ActionController::TestCase`はRails 5.1で専用gemに移行する予定。今後は`ActionDispatch::IntegrationTest`を使用。
    ([commit](https://github.com/rails/rails/commit/4414c5d1795e815b102571425974a8b1d46d932d))

*   Railsで生成するETagを「強い」ものから「弱い」ものに変更。
    ([Pull Request](https://github.com/rails/rails/pull/17573))

*   コントローラのアクションで`render`が明示的に呼び出されず、対応するテンプレートもない場合、エラーの代わりに`head :no_content`を暗黙に出力する。
    (Pull Request [1](https://github.com/rails/rails/pull/19377), [2](https://github.com/rails/rails/pull/23827))

*   フォームごとのCSRFトークン用オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/22275))

*   リクエストのエンコーディングとレスポンスの解析（parse）を結合テストに追加。
    ([Pull Request](https://github.com/rails/rails/pull/21671))

*  コントローラのアクションでレスポンスが明示的に定められていない場合の、デフォルトのレンダリングポリシーを更新。
    ([Pull Request](https://github.com/rails/rails/pull/23827))


*  コントローラレベルでビューコンテキストにアクセスする`ActionController#helpers`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/24866))

*   破棄されたフラッシュメッセージをセッションに保存せずに除去。
    ([Pull Request](https://github.com/rails/rails/pull/18721))

*  `fresh_when`や`stale?`にレコードのコレクションを渡す機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18374))

*   `ActionController::Live`を`ActiveSupport::Concern`に変更。`ActiveSupport::Concern`でextendしていない他のモジュールにはincludeされない。また、`ActionController::Live`はproduction環境では有効にならない。`ActionController::Live`が使われていると、生成されたスレッドから投げられた`:warden`をミドルウェアでキャッチできない問題があった。これに対応するため、`Warden`/`Devise`の認証エラーを扱える特殊なコードをincludeする別のモジュールを使っている開発者を見かける。
    ([詳細](https://github.com/rails/rails/issues/25581))


Action View
-------------

変更の詳細については[Changelog][action-view]を参照してください。

### 削除されたもの

*  非推奨の`AbstractController::Base::parent_prefixes`を削除。
    ([commit](https://github.com/rails/rails/commit/34bcbcf35701ca44be559ff391535c0dd865c333))

*  `ActionView::Helpers::RecordTagHelper`を削除。この機能は[record_tag_helper](https://github.com/rails/record_tag_helper) gemに移行済み。
    ([Pull Request](https://github.com/rails/rails/pull/18411))

*  i18nでのサポート廃止に伴い、`translate`の`:rescue_format`オプションを削除。
    ([Pull Request](https://github.com/rails/rails/pull/20019))

### 主な変更点

*  デフォルトのテンプレートハンドラを`ERB`から`Raw`に変更。
    ([commit](https://github.com/rails/rails/commit/4be859f0fdf7b3059a28d03c279f03f5938efc80))

*   コレクションのレンダリングで、複数の部分テンプレート（パーシャル）のキャッシュと取得を一度に行えるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/18948), [commit](https://github.com/rails/rails/commit/e93f0f0f133717f9b06b1eaefd3442bd0ff43985))

*  明示的な依存関係指定にワイルドカードによるマッチングを追加。
    ([Pull Request](https://github.com/rails/rails/pull/20904))

*  `disable_with`をsubmitタグのデフォルトの動作に設定。これにより送信時にボタンを無効にし、二重送信を防止する。
    ([Pull Request](https://github.com/rails/rails/pull/21135))

*   部分テンプレート（パーシャル）名はRubyの有効な識別子ではなくなった。
    ([commit](https://github.com/rails/rails/commit/da9038e))

*   `datetime_tag`ヘルパーで`datetime-local`を指定したinputタグが生成されるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/25469))

Action Mailer
-------------

変更の詳細については[Changelog][action-mailer]を参照してください。

### 削除されたもの

*  非推奨の`*_path`ヘルパーをemailビューから削除。
    ([commit](https://github.com/rails/rails/commit/d282125a18c1697a9b5bb775628a2db239142ac7))

*  非推奨の`deliver`メソッドと`deliver!`メソッドを削除。
    ([commit](https://github.com/rails/rails/commit/755dcd0691f74079c24196135f89b917062b0715))

### 主な変更点

*   テンプレートを検索するときにデフォルトのロケールとi18nにフォールバックするようになった。
    ([commit](https://github.com/rails/rails/commit/ecb1981b))

*  ジェネレーターで生成されたメーラーに`_mailer`サフィックスを追加。コントローラやジョブと同様の命名規則に従う。
    ([Pull Request](https://github.com/rails/rails/pull/18074))

*   `assert_enqueued_emails`と`assert_no_enqueued_emails`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18403))

*  メーラーキュー名を設定する`config.action_mailer.deliver_later_queue_name`設定を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18587))

*  Action Mailerビューでフラグメントキャッシュをサポート。
テンプレートでキャッシュが有効かどうかを検出する`config.action_mailer.perform_caching`設定オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/22825))


Active Record
-------------

変更の詳細については、[Changelog][active-record]を参照してください。

### 削除されたもの

*  ネストした配列をクエリ値として渡す機能（非推奨）を削除。([Pull Request](https://github.com/rails/rails/pull/17919))

*  非推奨の`ActiveRecord::Tasks::DatabaseTasks#load_schema`を削除。このメソッドは`ActiveRecord::Tasks::DatabaseTasks#load_schema_for`で置き換え済み。
    ([commit](https://github.com/rails/rails/commit/ad783136d747f73329350b9bb5a5e17c8f8800da))

*  非推奨の`serialized_attributes`を削除。
    ([commit](https://github.com/rails/rails/commit/82043ab53cb186d59b1b3be06122861758f814b2))

*   `has_many :through`の自動カウンタのキャッシュ（非推奨）を削除。
    ([commit](https://github.com/rails/rails/commit/87c8ce340c6c83342df988df247e9035393ed7a0))

*  非推奨の`sanitize_sql_hash_for_conditions`を削除。
    ([commit](https://github.com/rails/rails/commit/3a59dd212315ebb9bae8338b98af259ac00bbef3))

*  非推奨の`Reflection#source_macro`を削除。
    ([commit](https://github.com/rails/rails/commit/ede8c199a85cfbb6457d5630ec1e285e5ec49313))

*  非推奨の`symbolized_base_class`と`symbolized_sti_name`を削除。
    ([commit](https://github.com/rails/rails/commit/9013e28e52eba3a6ffcede26f85df48d264b8951))

*  非推奨の`ActiveRecord::Base.disable_implicit_join_references=`を削除。
    ([commit](https://github.com/rails/rails/commit/0fbd1fc888ffb8cbe1191193bf86933110693dfc))

*  文字列アクセサによる接続使用へのアクセス（非推奨）を削除。
    ([commit](https://github.com/rails/rails/commit/efdc20f36ccc37afbb2705eb9acca76dd8aabd4f))

*  インスタンスに依存するプリロード（非推奨）のサポートを削除。
    ([commit](https://github.com/rails/rails/commit/4ed97979d14c5e92eb212b1a629da0a214084078))

*   PostgreSQLでしか使われない値の範囲の下限値（非推奨）を削除。
    ([commit](https://github.com/rails/rails/commit/a076256d63f64d194b8f634890527a5ed2651115))

*  キャッシュされたArelとのリレーションを変更したときの動作（非推奨）を削除。
今後は`ImmutableRelation`エラーが出力される。
    ([commit](https://github.com/rails/rails/commit/3ae98181433dda1b5e19910e107494762512a86c))

*  `ActiveRecord::Serialization::XmlSerializer`をコアから削除。この機能は[activemodel-serializers-xml](https://github.com/rails/activemodel-serializers-xml) gemに移行済み。([Pull Request](https://github.com/rails/rails/pull/21161))

*  古い`mysql`データベースアダプタのサポートをコアから削除。今後は原則として`mysql2`を使用。今後古いアダプタのメンテナンス担当者が決まった場合、アダプタは別のgemに切り出される予定。([Pull Request 1](https://github.com/rails/rails/pull/22642)], [Pull Request 2](https://github.com/rails/rails/pull/22715))

* `protected_attributes` gem のサポートを終了。
    ([commit](https://github.com/rails/rails/commit/f4fbc0301021f13ae05c8e941c8efc4ae351fdf9))

*  PostgreSQL 9.1以前のサポートを削除。
    ([Pull Request](https://github.com/rails/rails/pull/23434))

*   `activerecord-deprecated_finders` gem のサポートを終了。
    ([commit](https://github.com/rails/rails/commit/78dab2a8569408658542e462a957ea5a35aa4679))

### 非推奨

*   クエリでクラスを値として渡すことを非推奨に指定。ユーザーは文字列を渡すこと。([Pull Request](https://github.com/rails/rails/pull/17916))

*   Active Recordのコールバックチェーンを止めるために`false`を返すことを非推奨に指定。代わりに`throw(:abort)`の利用を推奨。([Pull Request](https://github.com/rails/rails/pull/17227))

*  `ActiveRecord::Base.errors_in_transactional_callbacks=`を非推奨に指定。
    ([commit](https://github.com/rails/rails/commit/07d3d402341e81ada0214f2cb2be1da69eadfe72))

*   `Relation#uniq`を非推奨に指定。今後は`Relation#distinct`を使用。
    ([commit](https://github.com/rails/rails/commit/adfab2dcf4003ca564d78d4425566dd2d9cd8b4f))

*   PostgreSQLの`:point` typeを非推奨に指定。今後は`Array`ではなく`Point`オブジェクトを返す新しいtypeを使用。
    ([Pull Request](https://github.com/rails/rails/pull/20448))

*   trueになる引数を関連付け用メソッドに渡して関連付けを強制的に再読み込みする手法を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/20888))

*   関連付け`restrict_dependent_destroy`エラーのキーを非推奨に指定。今後は新しいキー名を使用。
    ([Pull Request](https://github.com/rails/rails/pull/20668))

*   `#tables`の動作を統一。
    ([Pull Request](https://github.com/rails/rails/pull/21601))

*   `SchemaCache#tables`、`SchemaCache#table_exists?`、`SchemaCache#clear_table_cache!`を非推奨に指定。今後は新しい同等のデータソースを使用。
    ([Pull Request](https://github.com/rails/rails/pull/21715))

*   SQLite3アダプタとMySQLアダプタの`connection.tables`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/21601))

*   `#tables`に引数を渡すことを非推奨に指定。一部のアダプタ（mysql2、sqlite3）の`#tables`メソッドはテーブルとビューを両方返すが、他のアダプタはテーブルのみを返す。動作を統一するため、今後は`#tables`はテーブルのみを返すようになる予定。
    ([Pull Request](https://github.com/rails/rails/pull/21601))

*   `table_exists?`を非推奨に指定。`#table_exists?`メソッドでテーブルとビューが両方チェックされていることがあるため。`#tables`の動作を統一するため、今後`#table_exists?`はテーブルのみをチェックするようになる予定。
    ([Pull Request](https://github.com/rails/rails/pull/21601))

*   `find_nth`に`offset`を引数として渡すことを非推奨に指定。今後リレーションでは`offset`メソッドを使用。
    ([Pull Request](https://github.com/rails/rails/pull/22053))

*   `DatabaseStatements`の`{insert|update|delete}_sql`を非推奨に指定。
   今後は`{insert|update|delete}`パブリックメソッドを使用。
    ([Pull Request](https://github.com/rails/rails/pull/23086))

*   `use_transactional_fixtures`を非推奨に指定。今後はより明瞭な`use_transactional_tests`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/19282))

*  `ActiveRecord::Connection#quote`にカラムを渡すことを非推奨に指定。
    ([commit](https://github.com/rails/rails/commit/7bb620869725ad6de603f6a5393ee17df13aa96c))

*  `start`パラメータを補完する`end`オプション（バッチ処理の停止位置を指定）を`find_in_batches`に追加。
    ([Pull Request](https://github.com/rails/rails/pull/12257))


### 主な変更点

*  テーブルの作成中に`foreign_key`オプションを`references`に追加。
    ([commit](https://github.com/rails/rails/commit/99a6f9e60ea55924b44f894a16f8de0162cf2702))

*  新しい属性API。([commit](https://github.com/rails/rails/commit/8c752c7ac739d5a86d4136ab1e9d0142c4041e58))

*  `enum`の定義に`:_prefix`/`:_suffix`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/19813),
     [Pull Request](https://github.com/rails/rails/pull/20999))

*  `ActiveRecord::Relation`に`#cache_key`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/20884))

*  `timestamps`のデフォルトの`null`値を`false`に変更。
    ([commit](https://github.com/rails/rails/commit/a939506f297b667291480f26fa32a373a18ae06a))

*   `ActiveRecord::SecureToken`を追加。`SecureRandom`を使うモデル内の属性で一意のトークン生成をカプセル化するメソッド。
    ([Pull Request](https://github.com/rails/rails/pull/18217))

*   `drop_table`に`:if_exists`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18597))

*   `ActiveRecord::Base#accessed_fields`を追加。データベース内の必要なデータだけをselectしたい場合に、参照したモデルでどのフィールドが読み出されたかをこのメソッドで簡単に調べられる。
    ([commit](https://github.com/rails/rails/commit/be9b68038e83a617eb38c26147659162e4ac3d2c))

*   `ActiveRecord::Relation`に`#or`メソッドを追加。WHERE句やHAVING句を結合するOR演算子。
    ([commit](https://github.com/rails/rails/commit/b0b37942d729b6bdcd2e3178eda7fa1de203b3d0))

*   `#touch`に`:time`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18956))

*   `ActiveRecord::Base.suppress`を追加。指定のブロックを実行中にレシーバーが保存されないようにする。
    ([Pull Request](https://github.com/rails/rails/pull/18910))

*   関連付けが存在しない場合、`belongs_to`でバリデーションエラーが発生するようになった。この機能は関連付けごとに`optional: true`でオフにできる。また、`belongs_to`の`required`オプションも非推奨に指定。今後は`optional`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/18937))

*  `db:structure:dump`の動作を設定する`config.active_record.dump_schemas`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/19347))

*  `config.active_record.warn_on_records_fetched_greater_than`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18846))

*   MySQLでネイティブJSONデータタイプをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/21110))

*  PostgreSQLでのインデックス削除の並列実行をサポート。
    ([Pull Request](https://github.com/rails/rails/pull/21317))

*  接続アダプタに`#views`メソッドと`#view_exists?`メソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/21609))

*  `ActiveRecord::Base.ignored_columns`を追加。カラムの一部をActive Recordに対して隠蔽する。
    ([Pull Request](https://github.com/rails/rails/pull/21720))

*   `connection.data_sources`と`connection.data_source_exists?`を追加。
Active Recordモデル（通常はテーブルやビュー）を支えるリレーションを特定するのに利用できる。
    ([Pull Request](https://github.com/rails/rails/pull/21715))

*  フィクスチャファイルを使って、モデルのクラスをYAMLファイルそのものの中に設定できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/20574))

*   データベースマイグレーションの生成時に`uuid`をデフォルトの主キーに設定できる機能を追加。([Pull Request](https://github.com/rails/rails/pull/21762))

*  `ActiveRecord::Relation#left_joins`と`ActiveRecord::Relation#left_outer_joins`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/12071))

*  `after_{create,update,delete}_commit`コールバックを追加。
    ([Pull Request](https://github.com/rails/rails/pull/22516))

*  クラスのマイグレーションに出現するAPIのバージョンを管理し、既存のマイグレーションを損なわずにパラメータを変更したり、非推奨サイクルの間に書き換えるためにバージョンを強制適用したりできるようにした。
    ([Pull Request](https://github.com/rails/rails/pull/21538))

* `ActionController::Base`に代わって`ApplicationController`を継承するように、`ApplicationRecord`がアプリケーションのすべてのモデルのスーパークラスとして新設される。この変更により、アプリケーション全体のモデルの動作を1か所で変更できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/22567))

*  ActiveRecordに`#second_to_last`メソッドと`#third_to_last`メソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/23583))

*  データベースオブジェクト（テーブル、カラム、インデックス）にコメントを追加して、PostgreSQLやMySQLのデータベースメタデータに保存する機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/22911))

*  プリペアドステートメントを`mysql2`アダプタに追加（mysql2 0.4.4以降向け）。
従来は古い`mysql`アダプタでしかサポートされていなかった。
config/database.ymlに`prepared_statements: true`と記述することでプリペアドステートメントが有効になる。
    ([Pull Request](https://github.com/rails/rails/pull/23461))

*  `ActionRecord::Relation#update`を追加。リレーションオブジェクトに対して、そのリレーションにあるすべてのオブジェクトのコールバックでバリデーション（検証）を実行できる。
    ([Pull Request](https://github.com/rails/rails/pull/11898))

*  `save`メソッドに`:touch`オプションを追加。タイムスタンプを変更せずにレコードを保存する場合に使用。
    ([Pull Request](https://github.com/rails/rails/pull/18225))

*  PostgreSQL向けに式インデックスと演算子クラスのサポートを追加。
    ([commit](https://github.com/rails/rails/commit/edc2b7718725016e988089b5fb6d6fb9d6e16882))

*  ネストした属性のエラーにインデックスを追加する`:index_errors`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/19686))

*  依存関係の削除（destroy）を双方向に行える機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18548))

*  トランザクションテストでの`after_commit`コールバックのサポートを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18458))

*  `foreign_key_exists?`メソッドを追加。テーブルに外部キーが存在するかどうかを確認できる。
    ([Pull Request](https://github.com/rails/rails/pull/18662))

*  `touch`メソッドに`:time`オプションを追加。レコードに現在時刻以外の時刻を指定する場合に使用。
    ([Pull Request](https://github.com/rails/rails/pull/18956))

Active Model
------------

変更の詳細については[Changelog][active-model]を参照してください。

### 削除されたもの

*  非推奨の`ActiveModel::Dirty#reset_#{attribute}`と`ActiveModel::Dirty#reset_changes`を削除
    ([Pull Request](https://github.com/rails/rails/commit/37175a24bd508e2983247ec5d011d57df836c743))

*  XMLシリアライズを削除。この機能は[activemodel-serializers-xml](https://github.com/rails/activemodel-serializers-xml) gemに移行済み。
    ([Pull Request](https://github.com/rails/rails/pull/21161))

*  `ActionController::ModelNaming`モジュールを削除。
    ([Pull Request](https://github.com/rails/rails/pull/18194))

### 非推奨

*   Active Modelのコールバックチェーンを止めるために`false`を返すことを非推奨に指定。代わりに`throw(:abort)`の利用を推奨。([Pull Request](https://github.com/rails/rails/pull/17227))

*  `ActiveModel::Errors#get`、`ActiveModel::Errors#set`、`ActiveModel::Errors#[]=`メソッドの動作が一貫していないため、非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/18634))

*  `validates_length_of`の`:tokenizer`オプションを非推奨に指定。今後はRubyの純粋な機能を使用。
    ([Pull Request](https://github.com/rails/rails/pull/19585))

*  `ActiveModel::Errors#add_on_empty`と`ActiveModel::Errors#add_on_blank`を非推奨に指定。置き換え先の機能はなし。
    ([Pull Request](https://github.com/rails/rails/pull/18996))

### 主な変更点

*  どのバリデータで失敗したかを調べる`ActiveModel::Errors#details`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18322))

*  `ActiveRecord::AttributeAssignment`を`ActiveModel::AttributeAssignment`にも展開。これにより、include可能なモジュールとしてすべてのオブジェクトで使えるようになる。
    ([Pull Request](https://github.com/rails/rails/pull/10776))

*   `ActiveModel::Dirty#[attr_name]_previously_changed?`と`ActiveModel::Dirty#[attr_name]_previous_change`を追加。モデルの保存後に一時記録された変更に簡単にアクセスできる。
    ([Pull Request](https://github.com/rails/rails/pull/19847))

*  `valid?`と`invalid?`でさまざまなコンテキストを一度にバリデーションする機能。
    ([Pull Request](https://github.com/rails/rails/pull/21069))

*  `validates_acceptance_of`のデフォルト値として`1`の他に`true`も指定できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/18439))

Active Job
-----------

変更の詳細については[Changelog][active-job]を参照してください。

### 主な変更点

*   `ActiveJob::Base.deserialize`をジョブクラスに委譲（delegate）。これにより、ジョブがシリアライズされたときやジョブ実行時に再度読み込まれたときに、任意のメタデータをジョブに渡せるようになる。
    ([Pull Request](https://github.com/rails/rails/pull/18260))

*  キューアダプタをジョブ単位で構成する機能を追加。ジョブ同士が影響しないように構成できる。
    ([Pull Request](https://github.com/rails/rails/pull/16992))

*  ジェネレータのジョブがデフォルトで`app/jobs/application_job.rb`を継承するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/19034))

*  `DelayedJob`、`Sidekiq`、`qu`、`que`、`queue_classic`で、ジョブIDを`provider_job_id`として`ActiveJob::Base`に返す機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/20064)、[Pull Request](https://github.com/rails/rails/pull/20056)、[commit](https://github.com/rails/rails/commit/68e3279163d06e6b04e043f91c9470e9259bbbe0))

*  ジョブを`concurrent-ruby`スレッドプールにキューイングする簡単な`AsyncJob`プロセッサと、関連する`AsyncAdapter`を実装。
    ([Pull Request](https://github.com/rails/rails/pull/21257))

*   デフォルトのアダプタをinlineからasyncに変更。デフォルトをasyncにすることで、テストを同期的な振る舞いに依存せずに行える。
    ([commit](https://github.com/rails/rails/commit/625baa69d14881ac49ba2e5c7d9cac4b222d7022))

Active Support
--------------

変更の詳細については[Changelog][active-support]を参照してください。

### 削除されたもの

*  非推奨の`ActiveSupport::JSON::Encoding::CircularReferenceError`を削除。
    ([commit](https://github.com/rails/rails/commit/d6e06ea8275cdc3f126f926ed9b5349fde374b10))

*  非推奨の`ActiveSupport::JSON::Encoding.encode_big_decimal_as_string=`メソッドと`ActiveSupport::JSON::Encoding.encode_big_decimal_as_string`メソッドを削除。
    ([commit](https://github.com/rails/rails/commit/c8019c0611791b2716c6bed48ef8dcb177b7869c))

*  非推奨の`ActiveSupport::SafeBuffer#prepend`を削除。
    ([commit](https://github.com/rails/rails/commit/e1c8b9f688c56aaedac9466a4343df955b4a67ec))

*   `Kernel`、`silence_stderr`、`silence_stream`、`capture`、`quietly`から非推奨メソッドを多数削除。
    ([commit](https://github.com/rails/rails/commit/481e49c64f790e46f4aff3ed539ed227d2eb46cb))

*  非推奨の`active_support/core_ext/big_decimal/yaml_conversions`ファイルを削除。
    ([commit](https://github.com/rails/rails/commit/98ea19925d6db642731741c3b91bd085fac92241))

*  非推奨の`ActiveSupport::Cache::Store.instrument`メソッドと`ActiveSupport::Cache::Store.instrument=`メソッドを削除。
    ([commit](https://github.com/rails/rails/commit/a3ce6ca30ed0e77496c63781af596b149687b6d7))

*  非推奨の`Class#superclass_delegating_accessor`を削除。
   今後は`Class#class_attribute`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/16938))

*  非推奨の`ThreadSafe::Cache`を削除。今後は`Concurrent::Map`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/21679))

*  Ruby 2.2 で既に実装されている`Object#itself`を削除。
    ([Pull Request](https://github.com/rails/rails/pull/18244))

### 非推奨

*  `MissingSourceFile`を非推奨に指定。今後は`LoadError`を使用。
    ([commit](https://github.com/rails/rails/commit/734d97d2))

*  `alias_method_chain`を非推奨に指定。今後はRuby 2.0 で導入された`Module#prepend`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/19434))

*  `ActiveSupport::Concurrency::Latch`を非推奨に指定。今後はconcurrent-rubyの`Concurrent::CountDownLatch`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/20866))

*  `number_to_human_size`の`:prefix`オプションを非推奨に指定。置き換え先はなし。
    ([Pull Request](https://github.com/rails/rails/pull/21191))

*  `Module#qualified_const_`を非推奨に指定。今後はビルトインの`Module#const_`メソッドを使用。
    ([Pull Request](https://github.com/rails/rails/pull/17845))

*  コールバック定義に文字列を渡すことを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/22598))

*  `ActiveSupport::Cache::Store#namespaced_key`、`ActiveSupport::Cache::MemCachedStore#escape_key`、`ActiveSupport::Cache::FileStore#key_file_path`を非推奨に指定。
   今後は`normalize_key`を使用。([Pull Request](https://github.com/rails/rails/pull/22215)、[commit](https://github.com/rails/rails/commit/a8f773b0))

*   `ActiveSupport::Cache::LocaleCache#set_cache_value`を非推奨に指定。今後は`write_cache_value`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/22215))

*  `assert_nothing_raised`に引数を渡すことを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/23789))

*  `Module.local_constants`を非推奨に指定。今後は`Module.constants(false)`を使用。
    ([Pull Request](https://github.com/rails/rails/pull/23936))


### 主な変更点

*  `ActiveSupport::MessageVerifier`に`#verified`メソッドと`#valid_message?`メソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/17727))

*  コールバックチェーンの停止方法を変更。今後は明示的に`throw(:abort)`で停止することを推奨。
    ([Pull Request](https://github.com/rails/rails/pull/17227))

*  新しい設定オプション`config.active_support.halt_callback_chains_on_return_false`を追加。ActiveRecord、ActiveModel、ActiveModel::Validationsのコールバックチェーンを、'before'コールバックで`false`を返したときに停止するかどうかを指定する。
    ([Pull Request](https://github.com/rails/rails/pull/17227))

*  デフォルトのテスト実行順を`:sorted`から`:random`に変更。
    ([commit](https://github.com/rails/rails/commit/5f777e4b5ee2e3e8e6fd0e2a208ec2a4d25a960d))

*   `#on_weekend?`メソッド、`#on_weekday?`メソッド、`#next_weekday`メソッド、`#prev_weekday`メソッドを`Date`、`Time`、`DateTime`に追加。
    ([Pull Request](https://github.com/rails/rails/pull/18335))

*  `Date`、`Time`、`DateTime`の`#next_week`と`#prev_week`に`same_time`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18335))

*  `Date`、`Time`、`DateTime`の`#yesterday`と`#tomorrow`に、`#prev_day`と`#next_day`に対応するメソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/18335))

*  ランダムなbase58文字列を生成する`SecureRandom.base58`を追加。
    ([commit](https://github.com/rails/rails/commit/b1093977110f18ae0cafe56c3d99fc22a7d54d1b))

*  `file_fixture`を`ActiveSupport::TestCase`に追加。
   テストケースからサンプルファイルにアクセスするシンプルな機能を提供する。
    ([Pull Request](https://github.com/rails/rails/pull/18658))

*  `Enumerable`と`Array`に`#without`を追加。指定の要素を除外して、列挙のコピーを返す。
    ([Pull Request](https://github.com/rails/rails/pull/19157))

*  `ActiveSupport::ArrayInquirer`と`Array#inquiry`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/18939))

*  指定のタイムゾーンで時刻を解析する`ActiveSupport::TimeZone#strptime`を追加。
    ([commit](https://github.com/rails/rails/commit/a5e507fa0b8180c3d97458a9b86c195e9857d8f6))

*  `Integer#zero?`に加えて`Integer#positive?`と`Integer#negative?`クエリメソッドを追加。
    ([commit](https://github.com/rails/rails/commit/e54277a45da3c86fecdfa930663d7692fd083daa))

*  `ActiveSupport::OrderedOptions`に破壊的なgetメソッドを追加。値が`.blank?`の場合は`KeyError`が発生。
    ([Pull Request](https://github.com/rails/rails/pull/20208))

*  指定の年の日数を返す`Time.days_in_year`を追加。引数がない場合は現在の年の日数を返す。
    ([commit](https://github.com/rails/rails/commit/2f4f4d2cf1e4c5a442459fc250daf66186d110fa))

*  ファイルのイベント監視機能を追加。アプリケーションのソースコード、ルーティング、ロケールなどの変更を非同期的に検出する。
    ([Pull Request](https://github.com/rails/rails/pull/22254))

*  スレッドごとのクラス変数やモジュール変数を宣言するメソッド群 thread_m/cattr_accessor/reader/writer を追加。
    ([Pull Request](https://github.com/rails/rails/pull/22630))

*   `Array#second_to_last`メソッドと`Array#third_to_last`メソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/23583))

*  `Date`、`Time`、`DateTime`に`#on_weekday?`メソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/23687))

* `ActiveSupport::Executor` APIと`ActiveSupport::Reloader` APIを公開。アプリケーションコードの実行やアプリケーションの再読み込みプロセスを、コンポーネントやライブラリから管理したり参加したりできる。
    ([Pull Request](https://github.com/rails/rails/pull/23807))

*  `ActiveSupport::Duration`でISO8601形式のフォーマットや解析をサポート。
    ([Pull Request](https://github.com/rails/rails/pull/16917))

*  `ActiveSupport::JSON.decode`でISO8601形式のローカル時刻をサポート（`parse_json_times`を有効にした場合）。
    ([Pull Request](https://github.com/rails/rails/pull/23011))

*  `ActiveSupport::JSON.decode`が日付の文字列ではなく`Date`オブジェクトを返すようになった。
    ([Pull Request](https://github.com/rails/rails/pull/23011))

*  `TaggedLogging`をロガーに追加。ロガーのインスタンスを複数作成して、タグがロガー同士で共有されないようにする。
    ([Pull Request](https://github.com/rails/rails/pull/9065))

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。
[railties]:       https://github.com/rails/rails/blob/5-0-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/5-0-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/5-0-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/5-0-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/5-0-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/5-0-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/5-0-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/5-0-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/5-0-stable/activejob/CHANGELOG.md
