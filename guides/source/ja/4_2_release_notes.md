
Ruby on Rails 4.2 リリースノート
===============================

Rails 4.2の注目ポイント

* Active Job
* メールの非同期処理
* Adequate Record
* Web Console
* 外部キーのサポート

本リリースノートでは、主要な変更についてのみ説明します。ここに紹介されていない機能、バグ修正、変更の詳細についてはGitHubにあるRailsメインリポジトリの [コミットリスト](https://github.com/rails/rails/commits/4-2-stable) を参照してください。

--------------------------------------------------------------------------------

Rails 4.2へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。Railのバージョンが4.1に達していない場合は、まずアプリケーションをRails 4.1にアップグレードし、アプリケーションが期待どおりに動作することを確認してからRails 4.2にアップグレードしてください。アップグレードの際に注意すべき点のリストについては、[Ruby on Rails アップグレードガイド](upgrading_ruby_on_rails.html#rails-4-1%E3%81%8B%E3%82%89rails-4-2%E3%81%B8%E3%81%AE%E3%82%A2%E3%83%83%E3%83%97%E3%82%B0%E3%83%AC%E3%83%BC%E3%83%89)を参照してください。


主要な変更
--------------

### Active Job

Active Jobとは、Rails 4.2から採用された新しいフレームワークです。Active Jobは、[Resque](https://github.com/resque/resque)、[Delayed Job](https://github.com/collectiveidea/delayed_job)、[Sidekiq](https://github.com/mperham/sidekiq)など、さまざまなクエリシステムの最上位に位置するものです。

Active Job APIを使用して記述されたジョブは、Active Jobがサポートするどのクエリシステムでもアダプタを介して実行できます。Active Jobは、ジョブを直ちに実行できるインラインランナー (inline runner) として最初から構成済みです。

ジョブの引数にActive Recordオブジェクトを与えたくなることはよくあります。Active Jobでは、オブジェクト参照をURI (uniform resource identifiers) として渡します。オブジェクト自身をマーシャリングしません。このURIは、Railsに新しく導入された[Global ID](https://github.com/rails/globalid)ライブラリによって生成され、ジョブはこれを元にオブジェクトを参照します。Active Recordオブジェクトをジョブの引数として渡すと、内部的には単にGlobal IDが渡されます。

たとえば、`trashable`というActive Recordオブジェクトがあるとすると、以下のようにシリアライズをまったく行わずにジョブに引き渡すことができます。

```ruby
class TrashableCleanupJob < ActiveJob::Base
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

詳細については、[Active Jobの基礎](active_job_basics.html)を参照してください。

### メールの非同期処理

今回のリリースで、Action MailerはActive Jobの最上位に配置され、`deliver_later`メソッドを使用してジョブキューからメールを送信できるようになりました。これにより、キューを非同期 (asynchronous) に設定すればコントローラやモデルの動作がキューによってブロックされなくなりました (ただしデフォルトのインラインキューではコントローラやモデルの動作はブロックされます)。

`deliver_now`メソッドを使用すれば、メールを直ちに送信できます。

### Adequate Record

Adequate Recordとは、Active Recordの性能を向上させるさまざまな改良の総称であり、いわゆる`find`や`find_by`呼び出し、および一部の関連付けクエリの動作速度を最大2倍に向上させます。

この改善は、よく用いられるSQLクエリを準備済みのSQL文 (prepared statement) としてキャッシュし、同様の呼び出しが発生した場合にそれを使い回すことによって行っています。これにより、以後の呼び出しでのクエリ生成作業の大半がスキップされるようになります。詳細については、[Aaron Pattersonのブログ記事](http://tenderlovemaking.com/2014/02/19/adequaterecord-pro-like-activerecord.html)を参照してください。

Active Recordは、サポートされている動作に対してこのAdequate Recordを自動的に適用するので、コードや設定の変更など開発者が何かを行う必要はありません。Adequate Recordでサポートされている動作の例を以下に示します。

```ruby
Post.find(1)  # 最初の呼び出しで準備済みSQL文が生成およびキャッシュされる
Post.find(2)  # キャッシュされた準備済みSQL文は以後の呼び出しで再利用される

Post.find_by_title('first post')
Post.find_by_title('second post')

post.comments
post.comments(true)
```

上の例で、メソッド呼び出しで渡された値そのものは準備済みSQL文のキャッシュに含まれていない点にご注目ください。全体をキャッシュしているのではなく、キャッシュされたSQL文が値のプレースホルダーとなっており、値だけ差し替えられている点が重要です。

以下のような場合にはキャッシュは使用されません。

- モデルにデフォルトスコープが設定されている
- モデルで単一テーブル継承 (STI) が使用されている
- `find`で (単一のidではなく) idのリストを検索する。例:

```ruby
  # キャッシュされない
  Post.find(1, 2, 3)
  Post.find([1,2])
  ```

- `find_by`でSQLフラグメントを使用している

```ruby
  Post.find_by('published_at < ?', 2.weeks.ago)
  ```

### Web Console gem

Rails 4.2で新規生成したアプリケーションにはデフォルトで[Web Console](https://github.com/rails/web-console) gemが含まれるようになりました。Web Console gemはすべてのエラーページに対話操作可能なRubyコンソールを追加し、`console`ビューとコントローラヘルパーメソッドを提供します。

エラーページで対話的コンソールが利用できるようになったことで、例外が発生したコンテキストで自由にコードを実行できるようになりました。`console`ヘルパーは、画面出力が完了した最終的な状態のコンテキストで対話的コンソールを起動します。このヘルパーは、どのビューやコントローラからでも自由に呼び出すことができます。

### 外部キーのサポート

マイグレーション用DSLで外部キーの追加・削除がサポートされました。今後は外部キーも`schema.rb`にダンプされます。現時点では、外部キーがサポートされるのは`mysql`、`mysql2`、および`postgresql`アダプタのみです。

```ruby
# `authors.id`を参照する`articles.author_id`への外部キーを追加する
add_foreign_key :articles, :authors

# `users.lng_id`を参照する`articles.author_id`への外部キーを追加する
add_foreign_key :articles, :users, column: :author_id, primary_key: "lng_id"

# `accounts.branch_id`の外部キーを削除する
remove_foreign_key :accounts, :branches

# `accounts.owner_id`の外部キーを削除する
remove_foreign_key :accounts, column: :owner_id
```

完全な説明については、APIドキュメントの [add_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_foreign_key)
および [remove_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_foreign_key) を参照してください。


非互換性
-----------------

前のバージョンで非推奨に指定されていた機能が削除されました。今回のリリースで新たに非推奨指定された機能については個別のコンポーネントの情報を参照してください。

以下の変更については、アップグレード時に対応が必要となることがあります。

### `render`に文字列の引数を与えた場合の挙動の変更

以前は、コントローラのアクションで`render "foo/bar"`を呼び出すことは`render file: "foo/bar"`を呼び出すことと同等でした。この動作はRails 4.2から変更され、`render template: "foo/bar"`と同等になりました。ファイルを指定したい場合は明示的に(`render file: "foo/bar"`)と書いてください。

### `respond_with`とクラスレベルの`respond_to`の扱いについて

`respond_with`と、これに対応するクラスレベルの`respond_to`は[responders](https://github.com/plataformatec/responders) gemに移動されましたこの機能を使用したい場合は、Gemfileに`gem 'responders', '~> 2.0'`を追記してください。

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  respond_to :html, :json

  def show
    @user = User.find(params[:id])
    respond_with @user
  end
end
```

インスタンスレベルでの`respond_to`は影響を受けません。

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end
end
```

### `rails server`のデフォルトホスト

[Rackの変更](https://github.com/rack/rack/commit/28b014484a8ac0bbb388e7eaeeef159598ec64fc) により、`rails server`コマンドを実行した際のデフォルトのホストが`0.0.0.0`から`localhost`に変更されました。この変更は標準的なローカルでの開発ワークフローにほとんど影響を与えないはずです。http://127.0.0.1:3000 および http://localhost:3000 の動作はどちらも以前と同じであるからです。

ただし、今回の変更により、別のPCからRailsサーバーへのアクセスは以前と同じようにはできなくなります。たとえば、development環境が仮想マシン上にあり、ホストマシンからこのdevelopment環境にアクセスする場合などがこれに該当します。
このような場合、サーバーを起動する際に`rails server -b 0.0.0.0`とすることで、以前と同じ動作を再現できます。

以前の動作に戻す場合は、必ずファイアウォールを適切に設定し、自社ネットワーク内の信頼できるPCだけが開発用サーバーにアクセスできるようにしてください。

### HTMLサニタイザ

HTMLサニタイザは[Loofah](https://github.com/flavorjones/loofah)と
[Nokogiri](https://github.com/sparklemotion/nokogiri)をベースにした、より新しく堅固な実装に置き換えられました。新しいサニタイザはより安全で、かつ強力で柔軟性に富んでいます。

新しいアルゴリズムが採用されたことにより、特定の汚染された入力をサニタイズした結果が従来と異なる場合があります。

従来のサニタイザと完全に同じ結果を得たい場合は、[rails-deprecated_sanitizer](https://github.com/kaspth/rails-deprecated_sanitizer) gemを
`Gemfile`に追加することで従来と同じ結果を得られます。このgemはオプトイン (opt-in: 自らの責任で選ぶこと) であるため、非推奨の警告を表示しません。

`rails-deprecated_sanitizer`のサポートはRails 4.2でしか行われないことにご注意ください。Rails 5.0ではメンテナンスされません。

新しいサニタイザの変更点の詳細については、[このブログ記事](http://blog.plataformatec.com.br/2014/07/the-new-html-sanitizer-in-rails-4-2/)を参照してください。

### `assert_select`

`assert_select`は[Nokogiri](https://github.com/sparklemotion/nokogiri)ベースで実装されました。
これにより、以前は有効であったセレクタの一部がサポートされなくなりました。アプリケーションでこれらを使用している場合は、アプリケーションを変更する必要があります。

*   属性セレクタの値に英文字以外の文字が含まれる場合は、値を引用符で囲む必要が生じることがあります

    ```
    # 以前の動作
    a[href=/]
    a[href$=/]

    # 現在の動作
    a[href="/"]
    a[href$="/"]
    ```

*   要素のネストが正しくないHTMLを含むHTMLソースから生成されたDOMでは結果が異なることがあります。

    例: 

    ``` ruby
    # content: <div><i><p></i></div>

    # 以前の動作
    assert_select('div > i')  # => true
    assert_select('div > p')  # => false
    assert_select('i > p')    # => true

    # 現在の動作
    assert_select('div > i')  # => true
    assert_select('div > p')  # => true
    assert_select('i > p')    # => false
    ```

*   選択したデータに実体参照文字が含まれている場合、比較のために選択された値は以前は実体参照文字のまま (`AT&amp;T`など)でしたが、現在は
実体参照を評価してから比較するようになりました(`AT&T`など)。

    ``` ruby
    # <p>AT&amp;T</p>の内容の扱い

    # 以前の動作
    assert_select('p', 'AT&amp;T')  # => true
    assert_select('p', 'AT&T')      # => false

    # 現在の動作
    assert_select('p', 'AT&T')      # => true
    assert_select('p', 'AT&amp;T')  # => false
    ```


Railties
--------

変更の詳細については[Changelog][railties]を参照してください。

### 削除されたもの

*   アプリケーションのジェネレータから`--skip-action-view`オプションが削除されました。
    ([Pull Request](https://github.com/rails/rails/pull/17042))

*   `rails application`コマンドは削除されました。他のコマンドへの置き換えは行われていません。
    ([Pull Request](https://github.com/rails/rails/pull/11616))

### 非推奨

*   production環境で`config.log_level`を未設定のままにすることが非推奨になりました。
    ([Pull Request](https://github.com/rails/rails/pull/16622))

*   `rake test:all`が非推奨になりました。現在は`rake test`の方が推奨されます(これにより`test`フォルダ以下のテストがすべて実行されます)。
    ([Pull Request](https://github.com/rails/rails/pull/17348))

*   `rake test:all:db`が非推奨になりました。現在は`rake test:db`が推奨されます。
    ([Pull Request](https://github.com/rails/rails/pull/17348))

*   `Rails::Rack::LogTailer`は非推奨になりました。代替はありません。
    ([Commit](https://github.com/rails/rails/commit/84a13e019e93efaa8994b3f8303d635a7702dbce))

### 主な変更点

*   `web-console`がデフォルトのアプリケーションGemfileに導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/11667))

*   モデル関連付けをおこなうジェネレータに`required`オプションが追加されました。
    ([Pull Request](https://github.com/rails/rails/pull/16062))

*   カスタム設定オプションを定義する時に使用する`x`名前空間が導入されました。

    ```ruby
    # config/environments/production.rb
    config.x.payment_processing.schedule = :daily
    config.x.payment_processing.retries  = 3
    config.x.super_debugger              = true
    ```

    これらのオプションは、以下のようにconfigurationオブジェクト全体で使用できます。

    ```ruby
    Rails.configuration.x.payment_processing.schedule # => :daily
    Rails.configuration.x.payment_processing.retries  # => 3
    Rails.configuration.x.super_debugger              # => true
    ```

    ([Commit](https://github.com/rails/rails/commit/611849772dd66c2e4d005dcfe153f7ce79a8a7db))

*   現在の環境設定を読み込むための`Rails::Application.config_for`が導入されました。

    ```ruby
    # config/exception_notification.yml:
    production:
      url: http://127.0.0.1:8080
      namespace: my_app_production
development:
      url: http://localhost:3001
      namespace: my_app_development

    # config/production.rb
    Rails.application.configure do
      config.middleware.use ExceptionNotifier, config_for(:exception_notification)
    end
    ```

    ([Pull Request](https://github.com/rails/rails/pull/16129))

*   アプリケーションのジェネレータに`--skip-turbolinks`オプションが導入されました。これは生成時にTurbolinksを統合しないためのオプションです。
    ([Commit](https://github.com/rails/rails/commit/bf17c8a531bc8059d50ad731398002a3e7162a7d))

*   `bin/setup`スクリプトが導入されました。これはアプリケーションの初期設定時に設定を自動化するためのコードの置き場所となります。
    ([Pull Request](https://github.com/rails/rails/pull/15189))

*   development環境において、`config.assets.digest`のデフォルト値が`true`に変更されました。
    ([Pull Request](https://github.com/rails/rails/pull/15155))

*   `rake notes`に新しい拡張子を登録するためのAPIが導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/14379))

*   Railsテンプレートで使用する`after_bundle`コールバックが導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/16359))

*   `Rails.gem_version`メソッドが導入されました。これは`Gem::Version.new(Rails.version)`を簡単に得るためのものです。
    ([Pull Request](https://github.com/rails/rails/pull/14101))


Action Pack
-----------

変更の詳細については[Changelog][action-pack]を参照してください。

### 削除されたもの

*   `respond_with` とクラスレベルでの`respond_to`がRailsから外され、`responders` gem (version 2.0) に移されました。引き続きこの機能を使う場合は、
Gemfileに`gem 'responders', '~> 2.0'`を追加してください。
    ([Pull Request](https://github.com/rails/rails/pull/16526)、[詳細](http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#responders))

*   非推奨の`AbstractController::Helpers::ClassMethods::MissingHelperError`が削除されました。今後は`AbstractController::Helpers::MissingHelperError`を使用してください。
    ([Commit](https://github.com/rails/rails/commit/a1ddde15ae0d612ff2973de9cf768ed701b594e8))

### 非推奨

*   `*_path`ヘルパーで`only_path`オプションを使用することが非推奨になりました。
    ([Commit](https://github.com/rails/rails/commit/aa1fadd48fb40dd9396a383696134a259aa59db9))

*   `assert_tag`、`assert_no_tag`、`find_tag`、`find_all_tag`が非推奨になりました。今後は`assert_select`を使用してください。
    ([Commit](https://github.com/rails/rails-dom-testing/commit/b12850bc5ff23ba4b599bf2770874dd4f11bf750))

*   ルーティングの`:to`オプションで、`#`という文字を含まないシンボルや文字列のサポートが非推奨になりました。

    ```ruby
    get '/posts', to: MyRackApp    => (変更不要)
    get '/posts', to: 'post#index' => (変更不要)
    get '/posts', to: 'posts'      => get '/posts', controller: :posts
    get '/posts', to: :index       => get '/posts', action: :index
    ```

    ([Commit](https://github.com/rails/rails/commit/cc26b6b7bccf0eea2e2c1a9ebdcc9d30ca7390d9))

*   URLヘルパー内において、ハッシュのキーに文字列を使用することが非推奨になりました。例:

    ```ruby
    # 良くない例
    root_path('controller' => 'posts', 'action' => 'index')

    # 良い例
    root_path(controller: 'posts', action: 'index')
    ```

    ([Pull Request](https://github.com/rails/rails/pull/17743))

### 主な変更点

*   `*_filter`に関するメソッド群をドキュメントから削除しました。これらのメソッドの使用は推奨されていません。今後は`*_action`を使用するようにしてください。

    ```
    after_filter          => after_action
    append_after_filter   => append_after_action
    append_around_filter  => append_around_action
    append_before_filter  => append_before_action
    around_filter         => around_action
    before_filter         => before_action
    prepend_after_filter  => prepend_after_action
    prepend_around_filter => prepend_around_action
    prepend_before_filter => prepend_before_action
    skip_after_filter     => skip_after_action
    skip_around_filter    => skip_around_action
    skip_before_filter    => skip_before_action
    skip_filter           => skip_action_callback
    ```

    アプリケーションがこれらのメソッドに依存している場合は、`*_action`に置き換える必要があります。これらのメソッドは今後非推奨になり、最終的にはRailsから削除される予定です。

    (Commit [1](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de)、
    [2](https://github.com/rails/rails/commit/489a8f2a44dc9cea09154ee1ee2557d1f037c7d4))

*   `render nothing: true`、およびbodyを`nil`にしたレンダリングを行った場合にレスポンスのbodyを埋めていたスペース文字1つが追加されなくなりました。
    ([Pull Request](https://github.com/rails/rails/pull/14883))

*   テンプレートのダイジェストを自動的にETagsに含めるようになりました。 ([Pull Request](https://github.com/rails/rails/pull/15819))

*   URLヘルパーに渡されるセグメントが自動的にエスケープされるようになりました。([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

*   グローバルに使用してよいパラメータを指定するための`always_permitted_parameters`が導入されました。この設定のデフォルト値は`['controller', 'action']`です。
    ([Pull Request](https://github.com/rails/rails/pull/15933))

*   [RFC 4791](https://tools.ietf.org/html/rfc4791)に基づいた`MKCALENDAR`というHTTPメソッドを追加しました。
    ([Pull Request](https://github.com/rails/rails/pull/15121))

*   `*_fragment.action_controller`通知にペイロード上のコントローラ名とアクション名が含まれるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/14137))

*   ルーティング探索があいまい一致した場合のRouting Errorページの表示が改良されました。
    ([Pull Request](https://github.com/rails/rails/pull/14619))

*   CSRFによる失敗のログ出力を無効にするオプションが追加されました。
    ([Pull Request](https://github.com/rails/rails/pull/14280))

*   Railsが静的なアセットを送信するように設定されている場合、ブラウザがgzip圧縮ファイルをサポートし、かつgzipファイル (.gz) がサーバーのディスク上にあれば、アセットのgzip圧縮がサポートされるようになりました。
   アセットパイプラインは、圧縮可能なすべてのアセットから`.gz`ファイルをデフォルトで生成するようになりました。gzip圧縮されたファイルを送信することで、通信量が最小化され、アセットへのリクエストが高速化されます。Railsがproduction環境でアセットを提供する場合は、必ず[CDN](http://guides.rubyonrails.org/asset_pipeline.html#cdns) を有効にしてください。
    ([Pull Request](https://github.com/rails/rails/pull/16466))

*   結合テストの中で`process`ヘルパーを呼び出すとき、パスの冒頭にスラッシュ ('/') が必要になりました。以前は省略することができましたが、これは内部実装による副作用であり、意図的な機能ではありません。例:

    ```ruby
    test "list all posts" do
      get "/posts"
      assert_response :success
    end 
    ```

Action View
-----------

変更の詳細については[Changelog][action-view]を参照してください。

### 非推奨

*   `AbstractController::Base.parent_prefixes`は非推奨になりました。ビューの検索対象を変更したい場合は`AbstractController::Base.local_prefixes`をオーバーライドしてください。
    ([Pull Request](https://github.com/rails/rails/pull/15026))

*   `ActionView::Digestor#digest(name, format, finder, options = {})`は非推奨になりました。
   今後、引数は1つのハッシュとして渡す必要があります。
    ([Pull Request](https://github.com/rails/rails/pull/14243))

### 主な変更点

*   `render "foo/bar"`が拡張され、`render file: "foo/bar"`ではなく`render template: "foo/bar"`を実行するようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/16888))

*   フォームヘルパーが変更され、インラインCSSを持つ`<div>`要素が隠しフィールドの周辺で生成されなくなりました。
    ([Pull Request](https://github.com/rails/rails/pull/14738))

*   `#{partial_name}_iteration`という特殊なローカル変数が導入されました。このローカル変数は、コレクションのレンダリング時にパーシャルを使用します。これにより、`#index`や`#size`、`#first?`や`last?`メソッドを使って現在のイテレート中の状態にアクセスできるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/7698))

*   プレースホルダの国際化 (I18n) が`label`の国際化と同じルールに従うようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/16438))


Action Mailer
-------------

変更の詳細については[Changelog][action-mailer]を参照してください。

### 非推奨

*   Action Mailerの`*_path`ヘルパーが非推奨になりました。今後は必ず`*_url`ヘルパーを使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/15840))

*   `deliver` や`deliver!`が非推奨になりました。今後は`deliver_now`や`deliver_now!`を使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/16582))

### 主な変更点

*   `link_to`や`url_for`を使って絶対パスのURLを生成するとき、`only_path: false`を渡す必要がなくなりました。
    ([Commit](https://github.com/rails/rails/commit/9685080a7677abfa5d288a81c3e078368c6bb67c))

*   `deliver_later`が導入されました。これは、アプリケーション内キューにジョブを流し込み、メールを非同期配信します。
    ([Pull Request](https://github.com/rails/rails/pull/16485))

*   `show_previews`設定オプションが追加されました。これはdevelopment環境の外でメイラーをプレビューできるようにするためのものです。
    ([Pull Request](https://github.com/rails/rails/pull/15970))


Active Record
-------------

変更の詳細については、[Changelog][active-record]を参照してください。

### 削除されたもの

*   `cache_attributes`およびその同類が削除されました。すべての属性は常にキャッシュされるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/15429))

*   非推奨の`ActiveRecord::Base.quoted_locking_column`メソッドが削除されました。
    ([Pull Request](https://github.com/rails/rails/pull/15612))

*   非推奨の`ActiveRecord::Migrator.proper_table_name`が削除されました。今後は`ActiveRecord::Migration`の`proper_table_name`インスタンスメソッドを代りに使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/15512))

*   未使用の`:timestamp`タイプが削除されました。今後は常に透過的に`:datetime`にエイリアスされるようになります。これにより、XMLシリアライズなどでカラムの種類がActive Recordの外に送信された場合の不整合が修正されます。
    ([Pull Request](https://github.com/rails/rails/pull/15184))

### 非推奨

*   `after_commit`と`after_rollback`内でのエラーの抑制が非推奨になりました。
    ([Pull Request](https://github.com/rails/rails/pull/16537))

*   `has_many :through` アソシエーションにおけるカウンタキャッシュの自動検知サポートが非推奨になりました (元々壊れていました)。今後は、`has_many`関連付けや`belongs_to`関連付けでレコード全体を手動でカウンタキャッシュする必要があります。
    ([Pull Request](https://github.com/rails/rails/pull/15754))

*   `.find`や`.exists?`にActive Recordオブジェクトを渡すことは非推奨になりました。最初にオブジェクトの`id`を呼び出すべきです。
    (Commit [1](https://github.com/rails/rails/commit/d92ae6ccca3bcfd73546d612efaea011270bd270)、[2](https://github.com/rails/rails/commit/d35f0033c7dec2b8d8b52058fb8db495d49596f7))

*   PostgreSQLで開始値を除外する範囲値に対する (不十分な) サポートが非推奨になりました。現在はPostgreSQLのRangeをRubyのRangeクラスにマップしています。ただし、RubyのRangeクラスでは開始値が外せないため、この方法は完全には実現できません。

    現時点における、開始値を増分 (increment) する解決方法は正しくないため、非推奨になりました。増分の方法が不明なサブタイプ (例: `#succ`は増分方法が未定義) については、開始値を除外する範囲指定によって`ArgumentError`が発生します。
    ([Commit](https://github.com/rails/rails/commit/91949e48cf41af9f3e4ffba3e5eecf9b0a08bfc3))

*   接続が行われていない状態での`DatabaseTasks.load_schema`の呼び出しが非推奨になりました。今後は`DatabaseTasks.load_schema_current`を使用してください。
    ([Commit](https://github.com/rails/rails/commit/f15cef67f75e4b52fd45655d7c6ab6b35623c608))

*   Replacementを使わずに`sanitize_sql_hash_for_conditions`を使用することが非推奨になりました。クエリを発行したり更新する際には`Relation`を使用することが、推奨APIとなります。
    ([Commit](https://github.com/rails/rails/commit/d5902c9e))

*   `:null`オプションを渡さずに`add_timestamps`や`t.timestamps`を使用することが非推奨になりました。現在の初期値は`null: true`ですが、 Rails 5では`null: false`に変更される予定です。
    ([Pull Request](https://github.com/rails/rails/pull/16481))

*   `Reflection#source_macro`が非推奨になりました。今後Active Recordでの必要性がなくなったため、代替はありません。
    ([Pull Request](https://github.com/rails/rails/pull/16373))

*   `serialized_attributes`は非推奨になりました。代替はありません。
    ([Pull Request](https://github.com/rails/rails/pull/15704))

*   カラムがない場合に`column_for_attribute`が`nil`を返す動作が非推奨になりました。Rails 5.0ではnullオブジェクトが返されるようになる予定です。
    ([Pull Request](https://github.com/rails/rails/pull/15878))

*   Replacementを使わずに、インスタンスの状態に依存するアソシエーション (例: 引数をとるスコープと共に定義される場合) において、`.joins`や`.preload`、`.eager_load`を使うことが非推奨になりました。
    ([Commit](https://github.com/rails/rails/commit/ed56e596a0467390011bc9d56d462539776adac1))

### 主な変更点

*   `create_table`が実行されるとき、`SchemaDumper`が`force: :cascade`を使うようになりました。これにより、外部キーが適切であればスキーマが再読み込みできるようになります。

*   単独の関連付けに対する`:required`オプションが追加されました。これは関連付けの存在確認の検証 (validation) を定義します。
    ([Pull Request](https://github.com/rails/rails/pull/16056))

*   `ActiveRecord::Dirty`の動作が変更され、変更可能な値 (mutable value)に対する適切な変更を検出するようになりました。
    何も変更がないときは、Active Recordモデル内のシリアライズされた要素は保存されなくなります。これらの変更は、PostgreSQLのstringカラムやjsonカラムでも同様に機能します。
    (Pull Requests [1](https://github.com/rails/rails/pull/15674), [2](https://github.com/rails/rails/pull/15786), [3](https://github.com/rails/rails/pull/15788))

*   現在の環境のデータベースを空にする`db:purge`というRakeタスクが導入されました。
    ([Commit](https://github.com/rails/rails/commit/e2f232aba15937a4b9d14bd91e0392c6d55be58d))

*   レコードが正しくないときに`ActiveRecord::RecordInvalid`を返す`ActiveRecord::Base#validate!`が導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/8639))

*   `valid?`のエイリアスとして`validate`が導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/14456))

*   `touch`が複数の属性を一度に扱えるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/14423))

*   PostgreSQLアダプターでPostgreSQL 9.4+の`jsonb`データタイプがサポートされました。
    ([Pull Request](https://github.com/rails/rails/pull/16220))

*   PostgreSQLとSQLiteアダプターで、String型の初期値から255文字制限が外れました。
    ([Pull Request](https://github.com/rails/rails/pull/14579))

*   PostgreSQLアダプターのカラム型で`citext`がサポートされました。
    ([Pull Request](https://github.com/rails/rails/pull/12523))

*   PostgreSQLアダプターでユーザ定義のRangeタイプがサポートされました。
    ([Commit](https://github.com/rails/rails/commit/4cb47167e747e8f9dc12b0ddaf82bdb68c03e032))

*   `sqlite3:///some/path`のようなパスは今後絶対システムパスで解決されるようになりました。相対パスが必要な場合は、代りに`sqlite3:some/path`のような表記を使用してください
(従来`sqlite3:///some/path`は`some/path`のような相対パスで解決されていましたが、これはRails 4.1で非推奨となっていました)。
    ([Pull Request](https://github.com/rails/rails/pull/14569))

*   MySQL 5.6以上で小数点以下の秒数サポートが追加されました。
    (Pull Request [1](https://github.com/rails/rails/pull/8240)、[2](https://github.com/rails/rails/pull/14359))

*   モデルを整えた形式で出力する`ActiveRecord::Base#pretty_print`が追加されました。
    ([Pull Request](https://github.com/rails/rails/pull/15172))

*   `ActiveRecord::Base#reload`の動作が`m = Model.find(m.id)`と同等になりました。これは、カスタマイズされた`SELECT`に含まれていた余分な属性が今後は保持されないということを意味しています。
    ([Pull Request](https://github.com/rails/rails/pull/15866))

*   `ActiveRecord::Base#reflections`が返すハッシュのキーが、シンボルから文字列になりました。([Pull Request](https://github.com/rails/rails/pull/17718))

*   マイグレーションの`references`メソッドで`type`オプションがサポートされました。外部キーの種類 (`:uuid`など) を指定できます。
    ([Pull Request](https://github.com/rails/rails/pull/16231))

Active Model
------------

変更の詳細については[Changelog][active-model]を参照してください。

### 削除されたもの

*   非推奨の`Validator#setup`が削除されました。代替はありません。
    ([Pull Request](https://github.com/rails/rails/pull/10716))

### 非推奨

*   `reset_#{attribute}`が非推奨になりました。今後は`restore_#{attribute}`を使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

*   `ActiveModel::Dirty#reset_changes`が非推奨になりました。今後は`clear_changes_information`を使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

### 主な変更点

*   `valid?`のエイリアスとして`#validate`が導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/14456))

*   `ActiveModel::Dirty`に`restore_attributes`メソッドが導入されました。これは、変更されたが保存されていない (dirty) 属性を以前の値に戻すためのものです。
    (Pull Request [1](https://github.com/rails/rails/pull/14861), [2](https://github.com/rails/rails/pull/16180))

*   `has_secure_password` がデフォルトで空白のパスワードを許容するようになりました (例: 空白スペースのみのパスワード)。
    ([Pull Request](https://github.com/rails/rails/pull/16412))

*   `has_secure_password`で検証が有効になっている場合は、与えられたパスワードが72文字より少ないかどうかが検証されるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/15708))

Active Support
--------------

変更の詳細については[Changelog][active-support]を参照してください。

### 削除されたもの

*   非推奨の`Numeric#ago`、`Numeric#until`、`Numeric#since`、`Numeric#from_now`が削除されました。
    ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

*   `ActiveSupport::Callbacks`での文字列ベースの終端指定子 (terminator) がこれまで非推奨になっていたのが削除されました。
    ([Pull Request](https://github.com/rails/rails/pull/15100))

### 非推奨

*   `Kernel#silence_stderr`、`Kernel#capture`、`Kernel#quietly`が非推奨になりました。代替はありません。
    ([Pull Request](https://github.com/rails/rails/pull/13392))

*   `Class#superclass_delegating_accessor`が非推奨になりました。今後は`Class#class_attribute`を使用してください。
    ([Pull Request](https://github.com/rails/rails/pull/14271))

*   `ActiveSupport::SafeBuffer#prepend!` が非推奨となりました。現在は `ActiveSupport::SafeBuffer#prepend` が同様の振る舞いをします。
    ([Pull Request](https://github.com/rails/rails/pull/14529))

### 主な変更点

*   順序に依存するテストを明記するための`active_support.test_order`オプションが導入されました。現在、このオプションの初期値は
`:sorted`で設定されていますが、Rails 5.0から`:random`に変更される予定です。
    ([Commit](https://github.com/rails/rails/commit/53e877f7d9291b2bf0b8c425f9e32ef35829f35b))

*   ブロック中で明示的にレシーバーを示さなくても`Object#try`や`Object#try!`が使えるようになりました。
    ([Commit](https://github.com/rails/rails/commit/5e51bdda59c9ba8e5faf86294e3e431bd45f1830), [Pull Request](https://github.com/rails/rails/pull/17361))

*   `travel_to`テストヘルパーが`usec`コンポーネントをゼロに切り詰めるように変更されました。
    ([Commit](https://github.com/rails/rails/commit/9f6e82ee4783e491c20f5244a613fdeb4024beb5))

*   オブジェクト自身を返す恒等関数として`Object#itself`が導入されました。
    (Commit [1](https://github.com/rails/rails/commit/702ad710b57bef45b081ebf42e6fa70820fdd810), [2](https://github.com/rails/rails/commit/64d91122222c11ad3918cc8e2e3ebc4b0a03448a))

*   ブロック中で明示的にレシーバーを示さなくても`Object#with_options`が使えるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/16339))

*   単語数を指定して文字列を切り詰める`String#truncate_words`が導入されました。
    ([Pull Request](https://github.com/rails/rails/pull/16190))

*   ハッシュの値を変更するときの共通のパターンを簡潔にするため、`Hash#transform_values`と`Hash#transform_values!`が追加されました。ただし、ハッシュのキーは変更されません。
    ([Pull Request](https://github.com/rails/rails/pull/15819))

*   アンダースコアなどを含むメソッド名などを英語らしくする`humanize`ヘルパーメソッドが、冒頭のアンダースコアを除去するようになりました。
    ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

*   `Concern#class_methods`が導入されました。`Kernel#concern`と同様、これは`module ClassMethods`を置き換えるためのものであり、`module Foo; extend ActiveSupport::Concern; end`のような冗長な定形コードを避けるためのものです。
    ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

*   自動読み込みやリロードに関する[新しいガイド](constant_autoloading_and_reloading.html)が追加されました。

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](http://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/4-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/4-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/4-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/4-2-stable/actionmailer/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/4-2-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/4-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/4-2-stable/activesupport/CHANGELOG.md