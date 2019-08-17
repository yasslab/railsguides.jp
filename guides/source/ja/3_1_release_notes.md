Rails 3.1 - 2011/08
===============================

Rails 3.1の注目ポイント

* ストリーミング
* 逆進可能なマイグレーション
* アセットパイプラリン
* jQueryがデフォルトのJavaScriptライブラリになった

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/3-1-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 3.1へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 3までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 3.1にアップデートしてください。以下の注意点を参照してからアップデートしてください。

### Rails 3.1ではRuby 1.8.7以上が必要

Rails 3.1ではRuby 1.8.7以上が必須です。これより前のバージョンのRubyのサポートは公式に廃止されたため、速やかにRubyをアップグレードすべきです。Rails 3.1はRuby 1.9.2とも互換性があります。

TIP: Ruby 1.8.7のp248とp249には、Railsクラッシュの原因となるマーシャリングのバグがあります。なおRuby Enterprise Editionでは1.8.7-2010.02のリリースでこの問題が修正されました。現行のRuby 1.9のうち、Ruby 1.9.1はセグメンテーションフォールト（segfault）で完全にダウンするため利用できません。Railsをスムーズに動かすため、Ruby 1.9.xを使いたい場合は1.9.2をお使いください。

### Railsのアップグレード方法

以下の変更点は、アプリケーションをRail 3.1.x系の中で最新のRails 3.1.3にアップグレードする場合を想定しています。

#### Gemfile

`Gemfile`を以下のように変更します。

```ruby
gem 'rails', '= 3.1.3'
gem 'mysql2'

# 新しいアセットパイプラインで必要
group :assets do
  gem 'sass-rails',   "~> 3.1.5"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier',     ">= 1.0.3"
end

# Rails 3.1ではjQueryがデフォルトのJavaScriptライブラリとなる
gem 'jquery-rails'
```

#### config/application.rb

* アセットパイプラインのために以下の追加が必要です。

    ```ruby
    config.assets.enabled = true
    config.assets.version = '1.0'
    ```

* アプリケーションで、リソースへのルーティングに"/assets"を使っている場合、必要に応じてプレフィックスを変更してアセットのコンフリクトを避けてください。

    ```ruby
    # デフォルトは'/assets'
    config.assets.prefix = '/asset-files'
    ```

#### config/environments/development.rb

* RJSの設定`config.action_view.debug_rjs = true`を削除します。

* アセットパイプラインを有効にする場合は以下を追加します。

    ```ruby
    # アセットを圧縮しない
    config.assets.compress = false

    # アセットを読み込む行を拡大する
    config.assets.debug = true
    ```

#### config/environments/production.rb

* 以下の変更のほとんどもアセットパイプライン用です。詳しくは[アセットパイプライン](asset_pipeline.html)ガイドを参照してください。

    ```ruby
    # JavaScriptsとCSSの圧縮
    config.assets.compress = true

    # プリコンパイル済みアセットがない場合はアセットパイプラインにフォールバックしない
    config.assets.compile = false

    # アセットURL用のダイジェストを生成する
    config.assets.digest = true

    # デフォルトはRails.root.join("public/assets")
    # config.assets.manifest = YOUR_PATH

    # 追加のアセットをプリコンパイルする（application.js、application.css、およびすべてのnon-JS/CSSは既に追加済み）
    # config.assets.precompile `= %w( search.js )


    # アプリへの全アクセスのSSL、Strict-Transport-Security、secure cookieを強制する
    # config.force_ssl = true
    ```

#### config/environments/test.rb

```ruby
# テストの静的アセットサーバーをCache-Controlで構成（パフォーマンス向上用）
config.serve_static_assets = true
config.static_cache_control = "public, max-age=3600"
```

#### config/initializers/wrap_parameters.rb

* パラメータをラップしてネスト済みハッシュにしたい場合は、以下の内容のファイルを追加します。新規アプリケーションでは今後これがデフォルトになります。

    ```ruby
    # このファイルを変更したら必ずサーバーをリスタートすること
    # このファイルに含まれるActionController::ParamsWrapperの設定は
    # デフォルトで有効になる

    # JSONパラメーターのラップを有効にする
    # 空配列に:formatを設定すると無効にできる
    ActiveSupport.on_load(:action_controller) do
      wrap_parameters :format => [:json]
    end

    # JSONのroot要素を無効にする（デフォルト）
    ActiveSupport.on_load(:active_record) do
      self.include_root_in_json = false
    end
    ```

#### ビューのアセットヘルパー参照から`:cache`と`:concat`オプションを削除する

* アセットパイプラインの`:cache`と`:concat`オプションは今後使われないので、このオプションをビューから削除します。

Rails 3.1アプリケーションを作成する
--------------------------------

```bash
# 以下を実行する前に'rails RubyGemをインストールしておくこと
$ rails new myapp
$ cd myapp
```

### gemに移行する

現在のRailsでは、アプリケーションのルートディレクトリに置かれる`Gemfile`を使って、アプリケーションの起動に必要なgemを指定します。この`Gemfile`は[Bundler](https://github.com/carlhuda/bundler)というgemによって処理され、依存関係のある必要なgemをすべてインストールします。依存するgemをそのアプリケーションの中にだけインストールして、OS環境にある既存のgemに影響を与えないようにすることもできます。

詳細情報: [Bundlerホームページ](https://bundler.io/)

### 最新のgemを使う

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使ってアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```
$ ruby /path/to/rails/railties/bin/rails new myapp --dev
```

Railsアーキテクチャの変更点
---------------------------

### アセットパイプライン

アセットパイプライン（Assets Pipeline）はRails 3.1の大きな変更点です。アセットパイプラインは、CSSやJavaScriptのコードを第一級市民として扱い、プラグインやエンジンの利用を含めて正式に編成できるようにします。

アセットパイプラインは[Sprockets](https://github.com/sstephenson/sprockets)によって強化されています。また、[アセットパイプライン](asset_pipeline.html)ガイドに解説があります。

### HTTPストリーミング

HTTPストリーミングもRails 3.1の変更点のひとつです。これにより、サーバーがレスポンス生成の途中でもスタイルシートやJavaScriptファイルをブラウザからダウンロードできるようになります。利用にはRuby 1.9.2の他に、Webサーバーでのサポートも必要ですが、よく使われているNginxとUnicornの組み合わせで利用可能です。

### デフォルトのJSライブラリがjQueryになった

Rails 3.1で同梱されるデフォルトのJavaScriptがjQueryになりました。Prototype.jsを使いたい場合は以下のように簡単に切り替えられます。

```bash
$ rails new myapp -j prototype
```

### Identity Map

Rails 3.1のActive RecordにIdentity Mapが搭載されました。Identity Mapは直前にインスタンス化された複数のレコードを保持し、次のアクセス時にそのレコードに関連付けられたオブジェクトを返します。Identity Mapはリクエストごとに作成され、リクエストの完了時に破棄されます。

Rails 3.1のIdentity Mapはデフォルトでオフになっています（訳注: Identity Mapはその後Rails 4.0で削除されました）。

Railties
--------

* jQueryが新たにデフォルトのJavaScriptライブラリになりました。

* jQueryやPrototype.jsは今後ベンダリングされません。代わりにjquery-rails gemやprototype-rails gemで提供されます。

* アプリケーションジェネレータで、任意の文字列を取れる`-j`オプションを使えるようになりました。"foo"を渡すと`Gemfile`に"foo-rails" gemが追加され、アプリケーションのJavaScriptマニフェストで"foo"と"foo_ujs"がrequireされます。現時点では"prototype-rails"と"jquery-rails"のみが存在し、それらのファイルはアセットパイプライン経由で提供されます。

* アプリやプラグインの生成時に`--skip-gemfile`や`--skip-bundle`を指定しない場合、`bundle install`を実行します。

* コントローラやリソースをジェネレータで生成すると、アセットのスタブが自動で作成されるようになりました（`--skip-assets`でオフにできます）。CoffeeScriptやSassのライブラリが利用可能な場合、生成されたスタブでCoffeeScriptやSassが使われます。

* scaffoldやアプリをRuby 1.9で生成すると、ハッシュのスタイルがRuby 1.9のスタイルになります。`--old-style-hash`を渡すと従来のハッシュスタイルで生成できます。

* scaffoldのコントローラジェネレータが、XMLフォーマットブロックに代えてJSONフォーマットブロックを生成するようになりました。

* コンソールでActive RecordログがSTDOUTにインライン出力されるようになりました。

* 設定に`config.force_ssl`が追加されました。これは`Rack::SSL`ミドルウェアを読み込んであらゆるリクエストを強制的にHTTPSプロトコルにします。

* Railsプラグインを生成する`rails plugin new`コマンドが追加されました。生成されるプラグインにはgemspec、テスト、テスト用ダミーアプリケーションが含まれます。

* `Rack::Etag`と`Rack::ConditionalGet`がデフォルトのミドルウェアスタックに追加されました。

* `Rack::Cache`がデフォルトのミドルウェアスタックに追加されます。

* エンジンでメジャーアップデートが行われました。任意のパスをマウントする、アセットの有効化、ジェネレータの実行などを含みます。

Action Pack
-----------

### Action Controller

* CSRFトークンの認証を照合できない場合にwarningが出力されるようになりました。

* 特定のコントローラで`force_ssl`を指定すると、そのコントローラからブラウザにHTTPSプロトコルによるデータ通信を強制できるようになりました。HTTPSを特定のアクションに限定する`:only`や`:except`も利用できます。

* （個人情報などの）重要な情報を含むクエリ文字列パラメータを`config.filter_parameters`で指定すると、そのリクエストパスをクエリのログから除外できるようになりました。

* `to_param`すると`nil`を返すURLパラメータは、クエリ文字列から削除されるようになりました。

* パラメータをラップしてnestedハッシュにする`ActionController::ParamsWrapper`が追加されました。かつ、新しいアプリのJSONリクエストではこの機能がデフォルトでオンになります。`config/initializers/wrap_parameters.rb`でカスタマイズできます。

* `config.action_controller.include_all_helpers`が追加されました。デフォルトでは、`ActionController::Base`で`helper :all`が適用されます（デフォルトですべてのヘルパーを含む）。`include_all_helpers`設定を`false`にすると、`application_helper`と、コントローラ名に対応するヘルパー（例: foo_controllerの場合はfoo_helper）だけが含まれます。

* `url_for`や名前付きURLヘルパーで`:subdomain`オプションや`:domain`オプションを指定できるようになりました。

* `Base.http_basic_authenticate_with`が追加されました。このクラスメソッドを1度呼び出すだけでシンプルなHTTP BASIC認証を行えます。

    ```ruby
    class PostsController < ApplicationController
      USER_NAME, PASSWORD = "dhh", "secret"

      before_filter :authenticate, :except => [ :index ]

      def index
        render :text => "ここは誰でも見える！"
      end

      def edit
        render :text => "ここはパスワードを知らないと見えない"
      end

      private
        def authenticate
          authenticate_or_request_with_http_basic do |user_name, password|
            user_name == USER_NAME && password == PASSWORD
          end
        end
    end
    ```

    上のコードは以下のように書けます。

    ```ruby
    class PostsController < ApplicationController
      http_basic_authenticate_with :name => "dhh", :password => "secret", :except => :index

      def index
        render :text => "ここは誰でも見える！"
      end

      def edit
        render :text => "ここはパスワードを知らないと見えない"
      end
    end
    ```

* ストリーミングのサポートが追加されました。有効にするには以下のようにします。

    ```ruby
    class PostsController < ActionController::Base
      stream
    end
    ```

    `:only`や`:except`を用いてストリーミングを特定のアクションに限定できます。詳しくは[`ActionController::Streaming`](https://api.rubyonrails.org/v3.1.0/classes/ActionController/Streaming.html)を参照してください。

* ルーティングの`redirect`メソッドが、対象URLの一部のみを変更するオプションハッシュを1つ受け取ることも、呼び出しに応答できるオブジェクト（リダイレクトで再利用できる）を1つ受け取ることもできるようになりました。

### Action Dispatch

* `config.action_dispatch.x_sendfile_header`がデフォルトで`nil`になりました。なおこの設定は`config/environments/production.rb`にはデフォルトで値が設定されません。サーバーは`X-Sendfile-Type`で値を設定できます。

* `ActionDispatch::MiddlewareStack`が「継承よりコンポジション」を採用し、配列を使わなくなりました。

* acceptヘッダーを無視できる`ActionDispatch::Request.ignore_accept_header`が追加されました。

* `Rack::Cache`がデフォルトスタックに追加されました。

* etagの責務が`ActionDispatch::Response`ミドルウェアスタックに移動しました。

* Ruby世界全体との互換性を高めるAPIを含む`Rack::Session`依存するようになりました。これにより後方互換性が失われます。理由は`Rack::Session`が`#get_session`で引数を4つ受け取ることを期待するのと、単なる`#destroy`ではなく`#destroy_session`が必須であるためです。

* テンプレートが継承チェインまで深く探索するようになりました。

### Action View

* `:authenticity_token`オプションが`form_tag`に追加されました。これはカスタムハンドリングに使ったり、`:authenticity_token => false`を渡してトークンを省略したりできます。

* `ActionView::Renderer`を作成し、`ActionView::Context`のAPIを指定しました。

* `SafeBuffer`をインプレースで改変することはRuby 3.1で禁止されました。

* HTML5の`button_tag`ヘルパーが追加されました。

* `file_field`に、`:multipart => true`が自動的に同封フォームに追加されるようになりました。

* オプションの`:data`ハッシュでHTML5の`data-*`属性を追加するのに便利なイディオムがタグヘルパーに追加されました。

    ```ruby
    tag("div", :data => {:name => 'Stephen', :city_state => %w(Chicago IL)})
    # => <div data-name="Stephen" data-city-state="[&quot;Chicago&quot;,&quot;IL&quot;]" />
    ```

キーはハイフンつなぎに変換され、値は文字列とシンボルを除いてJSONエンコードされます。

* `csrf_meta_tag`が`csrf_meta_tags`にリネームされ、後方互換性のために`csrf_meta_tag`エイリアスが置かれました。

* 旧来のテンプレートハンドラAPIは非推奨となり、新しいAPIでは単にcallに応答するテンプレートハンドラが要求されるようになりました。

* テンプレートハンドラのrhtmlやrxmlが最終的に削除されました。

* テンプレートをキャッシュすべきかどうかを指定する`config.action_view.cache_template_loading`が復活しました。

* submitフォームヘルパーで"object_name_id"というidは今後生成されません。

* `FormHelper#form_for`で、`:method`を`:html`ハッシュではなく直接のオプションとして指定できるようになりました。`form_for(@post, remote: true, html: { method: :delete })`ではなく、`form_for(@post, remote: true, method: :delete)`のように指定します。

* `JavaScriptHelper#escape_javascript()`のエイリアス`JavaScriptHelper#j()`が提供されました。これは、JSON gemがJavaScriptHelperを用いるテンプレート内に追加する`Object#j()`メソッドに代わる後継メソッドとなります。

* 日時セレクタでAM/PM形式が利用できるようになりました。

* `auto_link`がRailsから削除され、[rails_autolink](https://github.com/tenderlove/rails_autolink) gemに切り出されました。

Active Record
-------------

* 個別のモデルのテーブル名を単数形や複数形にする`pluralize_table_names`というクラスメソッドが追加されました。従来は`ActiveRecord::Base.pluralize_table_names`を用いて全モデルでグローバルにしか設定できませんでした。

    ```ruby
    class User < ActiveRecord::Base
      self.pluralize_table_names = false
    end
    ```

* 単一の関連付け（`has_one`や`belongs_to`）に属性を設定するブロックが追加されました。このブロックはインスタンスが初期化された後に呼び出されます。

    ```ruby
    class User < ActiveRecord::Base
      has_one :account
    end

    user.build_account{ |a| a.credit_limit = 100.0 }
    ```

* 属性名のリストを返す`ActiveRecord::Base.attribute_names`が追加されました。抽象モデルの場合やモデルにテーブルがない場合は空の配列を返します。

* CSVフィクスチャーが非推奨になりました。同サポートはRails 3.2.0で削除される予定です。

* `ActiveRecord#new`、`ActiveRecord#create`、`ActiveRecord#update_attributes`がすべてオプションハッシュをもうひとつ取れるようになりました。この第2ハッシュを用いて、属性への代入時に考慮されるロールを指定できます。この機能は、Active Modelの新しいマスアサインメント機能の上に構築されます。

    ```ruby
    class Post < ActiveRecord::Base
      attr_accessible :title
      attr_accessible :title, :published_at, :as => :admin
    end

    Post.new(params[:post], :as => :admin)
    ```

* `default_scope`がブロックやlambdaや（遅延評価の呼び出しに応答する）任意のオブジェクトを1つ取れるようになりました。

* デフォルトスコープが、可能な限り最新のタイミングで評価されるようになりました。これは、デフォルトスコープを含むスコープが暗黙で作成されると`Model.unscoped`を用いてスコープが削除できなくなることがある問題を回避するためのものです。

* PostgreSQLアダプタでサポートされるPostgreSQLバージョンが8.2以降のみとなりました。

* `ConnectionManagement`ミドルウェアが変更され、rackの本体が破棄された後でコネクションプールをクリーンアップするようになりました。

* Active Recordに`update_column`メソッドが新たに追加されました。これはオブジェクト上で指定の属性を更新し、バリデーションやコールバックをスキップしますが、（`updated_at`カラムの変更を含む）コールバックを一切実行したくない事情があるのでなければ、この`update_column`ではなく`update_attributes`か`update_attribute`をおすすめします。新規レコードに対して`update_column`メソッドを呼び出すべきではありません。

* `:through`オプションを用いる関連付けで、（`:through`オプションと`has_and_belongs_to_many`関連付けの両方を持つ関連付けなどを含む）任意の関連付けをthrough関連付けやsource関連付けとして利用できるようになりました。

* `ActiveRecord::Base.connection_config`で現在のデータベース接続の設定にアクセスできるようになりました。

* COUNTクエリで`limit`と`offset`を両方指定しない限り、LIMITとOFFSETが削除されるようになりました。

    ```ruby
    People.limit(1).count           # => 'SELECT COUNT(*) FROM people'
    People.offset(1).count          # => 'SELECT COUNT(*) FROM people'
    People.limit(1).offset(1).count # => 'SELECT COUNT(*) FROM people LIMIT 1 OFFSET 1'
    ```

* `ActiveRecord::Associations::AssociationProxy`が分割されました。`Association`クラス（およびサブクラス）は関連付けへの操作を担当し、それとは別の`CollectionProxy`というラッパーはコレクション関連付けをプロキシします。これによって名前空間の汚染を防止し、concernsが分離されるので、リファクタリングをさらに進められるようになります。

* 単一の関連付け（`has_one`や`belongs_to`）にプロキシが含まれなくなり、関連付けられたレコードか`nil`のいずれかを単に返すようになりました。これは、`bob.mother.create`のようなドキュメントのないメソッドを使うべきではないという意図を表しています。今後は`bob.create_mother`などをお使いください。

* `has_many :through`関連付けで`:dependent`オプションがサポートされるようになりました。通常のhas_many関連付けでは`:nullify`がデフォルトの削除ストラテジーですが、歴史的な理由と実用上の理由によって、`association.delete(*records)`の`:delete_all`がデフォルトの削除ストラテジーとなっています。また、この機能をすべて使えるのは、ソースリフレクションがbelongs_toの場合に限られます。それ以外の場合は、through関連付けを直接変更すべきです。

* `has_and_belongs_to_many`や`has_many :through`における`association.destroy`の振る舞いが変更されました。今後、ある関連付けにおけるdestroyやdeleteは、「関連付けられたそのレコードを必ず削除する」ではなく、「そのリンクを削除する」と認識されます。

* 従来の`has_and_belongs_to_many.destroy(*records)`はレコードそのものをdestroyし、joinテーブルのレコードは削除しませんでした。今後はjoinテーブルのレコードを削除します。

* 従来の`has_many_through.destroy(*records)`はレコードそのものをdestroyし、joinテーブルのレコードは削除しませんでした[メモ: これは常にそうとは限りませんでした。従来バージョンのRailsではレコードそのものだけが削除されました]。今後はjoinテーブルのレコードだけを削除します。

* この変更によって後方互換性がある程度失われますが、残念ながら、この変更を実施する前に「非推奨化する」方法がありません。この変更は、さまざまな関連付けの種類全体でdestroyやdeleteの意味を統一するために実施中です。レコードそのものをdestroyしたい場合は`records.association.each(&:destroy)`が使えます。

* `:bulk => true`オプションが`change_table`に追加されました。これはあらゆるスキーマ変更を、ブロック内で1つのALTERステートメントを用いて定義します。

    ```ruby
    change_table(:users, :bulk => true) do |t|
      t.string :company_name
      t.change :birthdate, :datetime
    end
    ```

* `has_and_belongs_to_many`のjoinテーブルで属性にアクセスするためのサポートが削除されました。`has_many :through`を利用する必要があります。

* `create_association!`メソッドが追加されました。`has_one`関連付けや`belongs_to`関連付けで利用できます。

* マイグレーションがリバース（巻き戻し）可能になりました。つまりRailsがマイグレーションをリバースする方法を認識できるということです。リバース可能なマイグレーションを利用するには、以下のように単に`change`メソッドを定義します。

    ```ruby
    class MyMigration < ActiveRecord::Migration
      def change
        create_table(:horses) do |t|
          t.column :content, :text
          t.column :remind_at, :datetime
        end
      end
    end
    ```

* 自動的にはリバース可能にならないものもあります。リバースする方法を自分が知っているのであれば、マイグレーションで`up`や`down`を定義すべきです。`change`の中にリバースできないものがあると、リバース中に`IrreversibleMigration`例外が発生します。

* マイグレーションで、クラスメソッドではなくインスタンスメソッドが使われるようになりました。

    ```ruby
    class FooMigration < ActiveRecord::Migration
      def up # self.upではなくなった
        ...
      end
    end
    ```

* モデルから生成したマイグレーションファイルや、構成可能なマイグレーションジェネレータで生成したマイグレーションファイル（add_name_to_usersなど）で、通常の`up`メソッドや`down`メソッドではなく、リバース可能な`change`メソッドが使われるようになりました。

* 関連付けで文字列のSQL条件を展開する機能のサポートが削除されました。今後は`proc`を使うべきです。

    ```ruby
    has_many :things, :conditions => 'foo = #{bar}'          # 従来
    has_many :things, :conditions => proc { "foo = #{bar}" } # 今後
    ```

    `proc`の内部では、関連付けをeager loadingしない限り、関連付けのオーナーは`self`というオブジェクトになります。ここで`self`は、関連付けを含んでいるクラスを表します。

    `proc`の内部では「通常の」条件を何でも使えるので、以下も機能します。

    ```ruby
    has_many :things, :conditions => proc { ["foo = ?", bar] }
    ```

* 従来は`has_and_belongs_to_many`関連付けの`:insert_sql`メソッドや`:delete_sql`メソッドで「レコード」を呼び出すことで、挿入されるレコードや削除されるレコードを取得できました。今後これらのレコードは引数としてそのprocに渡されるようになりました。

* `ActiveRecord::Base#has_secure_password`（`ActiveModel::SecurePassword`を利用）が追加されました。BCrypt暗号化やsalt追加が使える極めてシンプルなパスワード利用機能がこのメソッドにカプセル化されています。

    ```ruby
    # Schema: User(name:string, password_digest:string, password_salt:string)
    class User < ActiveRecord::Base
      has_secure_password
    end
    ```

* モデルを生成するときに、`belongs_to`や`references`カラムにデフォルトで`add_index`が追加されるようになりました。

* `belongs_to`オブジェクトのidを設定すると、そのオブジェクトの参照が更新されるようになりました。

* `ActiveRecord::Base#dup`や`ActiveRecord::Base#clone`のセマンティクス（意味付け）が変更され、Rubyの通常の`dup`や`clone`のセマンティクスに近くなりました。

* `ActiveRecord::Base#clone`を呼ぶと、frozenされたステートのコピーを含むレコードの浅い（shallow）コピーが返されます。コールバックは呼ばれません。

* `ActiveRecord::Base#dup`を呼ぶとレコードが複製され、after_initializeフックも呼び出されます。frozenなステートはコピーされず、関連付けはすべてクリアされます。`dup`されたレコードは`new_record?`で`true`を返し、idフィールドは`nil`に設定され、かつ保存可能になります。

* クエリキャッシュがprepared statmentで使えるようになりました。アプリケーションの変更は不要です。

Active Model
------------

* `attr_accessible`で`:as`オプションを用いてロールを指定できるようになりました。

* `InclusionValidator`、`ExclusionValidator`、`FormatValidator`が、ブロックやlambda、または`call`に応答する任意のオブジェクトをオプションとして1つ取れるようになりました。このオプションは現在のレコードを引数として呼び出され、`InclusionValidator`や`ExclusionValidator`の場合は`include?`に応答するオブジェクトを1つ返し、`FormatValidator`の場合は正規表現オブジェクトを1つ返します。

* `ActiveModel::SecurePassword`が追加されました。BCrypt暗号化やsalt追加が使える極めてシンプルなパスワード利用機能がこのメソッドにカプセル化されています。

* `ActiveModel::AttributeMethods`で属性を必要に応じて定義できるようになりました。

* オブザーバー（observer）を選択的に有効にしたり無効にしたりする機能が追加されました。

* `I18n`名前空間を交互に探索する機能はサポートされなくなりました。

Active Resource
---------------

* すべてのリクエストでデフォルトのフォーマットがJSONに変更されました。XMLを使い続けたい場合は、次のようにこのクラスで`self.format = :xml`を設定する必要があります。

    ```ruby
    class User < ActiveResource::Base
      self.format = :xml
    end
    ```

Active Support
--------------

* `ActiveSupport::Dependencies`で既存の定数が`load_missing_constant`にある場合に`NameError`をraiseするようになりました。

* レポート用メソッド`Kernel#quietly`が新たに追加されました。これは`STDOUT`と`STDERR`を両方とも抑制します。

* `String#inquiry`が追加されました。これは文字列を`StringInquirer`オブジェクトに変換するのに便利です。

* `Object#in?`が追加されました。これはオブジェクトが別のオブジェクトに含まれているかどうかをテストします。

* `LocalCache`ストラテジーが、無名クラスではなくミドルウェアに実在するクラスになりました。

* `ActiveSupport::Dependencies::ClassCache`クラスが導入されました。再読み込み可能なクラスへの参照がこのクラスに保持されます。

* `ActiveSupport::Dependencies::Reference`がリファクタリングされ、新しい`ClassCache`を直接利用するようになりました。

* `Range#cover?`がRuby 1.8の`Range#include?`のエイリアスとしてバックポートされました。

* Date/DateTime/Timeに`weeks_ago`と`prev_week`が追加されました。

* `before_remove_const`コールバックが`ActiveSupport::Dependencies.remove_unloadable_constants!`に追加されました。

非推奨化:

* `ActiveSupport::SecureRandom`が非推奨化されました。今後はRuby標準ライブラリの`SecureRandom`が推奨されます。

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に敬意を表明いたします。

Rails 3.1リリースノートの編集は[Vijay Dev](https://github.com/vijaydev)が担当しました。