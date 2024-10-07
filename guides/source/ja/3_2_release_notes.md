Ruby on Rails 3.2 リリースノート
===============================

Rails 3.2の注目ポイント

* developmentモードの高速化
* 新しいルーティングエンジン
* クエリの自動explain
* ログ出力へのタグ付け

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/3-2-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------


Rails 3.2へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 3.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 3.2にアップデートしてください。以下の注意点を参照してからアップデートしてください。

### Rails 3.2ではRuby 1.8.7以上が必要

Rails 3.2ではRuby 1.8.7以上が必須です。これより前のバージョンのRubyのサポートは公式に廃止されたため、速やかにRubyをアップグレードすべきです。Rails 3.2はRuby 1.9.2とも互換性があります。

TIP: Ruby 1.8.7のp248とp249には、Railsクラッシュの原因となるマーシャリングのバグがあります。なおRuby Enterprise Editionでは1.8.7-2010.02のリリースでこの問題が修正されました。現行のRuby 1.9のうち、Ruby 1.9.1はセグメンテーションフォールト（segfault）で完全にダウンするため利用できません。Railsをスムーズに動かすため、Ruby 1.9.xを使いたい場合は1.9.2 または1.9.3をお使いください。

### Railsのアップグレード方法

* Gemfileを以下の依存関係に更新します。
    * `rails = 3.2.0`
    * `sass-rails ~> 3.2.3`
    * `coffee-rails ~> 3.2.1`
    * `uglifier >= 1.0.3`

* Rails 3.2では`vendor/plugins`が非推奨化されました（Rails 4.0で完全に廃止される予定です）。プラグインをgemに切り出してGemfileに追加することで、プラグインを置き換えられます。プラグインをgem化しないのであれば、プラグインを`lib/my_plugin/*`などに移動し、`config/initializers/my_plugin.rb`などの適切なイニシャライザを追加してください。

* Railsの設定項目で多数の変更が行われました。`config/environments/development.rb`で追加しておきたいであろう項目は以下のとおりです。

    ```ruby
    # Active Recordモデルのmass assignment保護で例外を発生する
    config.active_record.mass_assignment_sanitizer = :strict

    # クエリ送信時のクエリプランのログ出力をより詳細にする
    # （SQLite、MySQL、PostgreSQLで利用可能）
    config.active_record.auto_explain_threshold_in_seconds = 0.5
    ```

    `config/environments/test.rb`にも以下のように`mass_assignment_sanitizer`を追加する必要があります。

    ```ruby
    # Active Recordモデルのmass assignment保護で例外を発生する
    config.active_record.mass_assignment_sanitizer = :strict
    ```

### エンジンのアップグレード方法

`script/rails`のコメントより下の行にあるコードを以下に置き換えます。

```ruby
ENGINE_ROOT = File.expand_path('../..', __FILE__)
ENGINE_PATH = File.expand_path('../../lib/your_engine_name/engine', __FILE__)

require 'rails/all'
require 'rails/engine/commands'
```

Rails 3.2アプリケーションを作成する
--------------------------------

```bash
# 'rails' RubyGemがインストールされている状態で行うこと
$ rails new myapp
$ cd myapp
```

### gemに移行する

現在のRailsでは、アプリケーションのルートディレクトリに置かれる`Gemfile`を使って、アプリケーションの起動に必要なgemを指定します。アプリケーション起動時に必要なgemは今後ここで決定されます。`Gemfile`の処理は[Bundler](https://github.com/carlhuda/bundler)というgemで行われます。今後はBundlerがすべての依存gemをインストールします。依存gemをアプリケーションディレクトリにローカルインストールして、システムのgem（OS環境にあるgem）に依存しないようにすることも可能です（訳注: Rails開発ではこの方法が主流です）。

詳細情報: [Bundlerホームページ](https://bundler.io/)

### 最新のgemを使う

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```bash
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使ってアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```bash
$ ruby /path/to/rails/railties/bin/rails new m
```

主要な機能
--------------

### developmentモードやルーティングの高速化

Rails 3.2のdevelopmentモードが著しく高速になりました。[Active Reload](https://github.com/paneq/active_reload)からヒントを得て、ファイルが実際に変更された場合のみクラスを再読み込みするようになりました。アプリが大規模になればなるほど、劇的に高速化します。ルーティングの認識も、新しい[Journey](https://github.com/rails/journey)エンジンによって大きく高速化されました。

### クエリの自動explain

Rails 3.2では便利なクエリexplain機能が導入されました。explainは`ActiveRecord::Relation`の`explain`メソッドで定義され、Arelで生成されます。たとえば、`puts Person.active.limit(5).explain`のようなコードを実行すると、Arelで生成されるクエリでexplainが行われます。explainは、インデックス化が正しいかどうかをチェックしたり、最適化をさらに進めたりするのに役立ちます。

developmentモードでは、実行完了に1秒以上かかるクエリで**自動的に**explainが走るようになります。閾値はもちろん変更可能です。


### ログ出力へのタグ付け

マルチユーザーのアプリケーションやマルチアカウントのアプリケーションを実行する場合、誰が何を行ったかをログでフィルタできると非常に助かります。Active SupportのTaggedLogging機能はまさにこのためのものであり、ログ出力にサブドメインやリクエストidなど任意の項目を追加してアプリケーションのデバッグを支援します。

ドキュメント
-------------

Rails 3.2以降、iPad/iPhone/Mac/AndroidなどのKindleまたは無料のKindleリーダーアプリで本Railsガイド（英語版）を読めるようになりました。

Railties
--------

* 依存ファイル変更時にのみクラスを再読み込みすることで高速化されました。`config.reload_classes_only_on_change`を`false`に設定することでオフにできます。

* 新しいアプリケーションでは環境構築ファイルに`config.active_record.auto_explain_threshold_in_seconds`というフラグが置かれます。`development.rb`では値が`0.5`に設定され、`production.rb`ではコメントアウトされています。`test.rb`では特に記載はありません。

* `config.exceptions_app`が追加されました。これは例外発生時に`ShowException`ミドルウェアで呼び出される例外時のアプリケーションを設定します。デフォルトは`ActionDispatch::PublicExceptions.new(Rails.public_path)`です。

* `DebugExceptions`ミドルウェアが追加されました。ここには`ShowExceptions`ミドルウェアから切り出された機能を含みます。

* `rake routes`の実行結果にマウント中のエンジンのルーティングも表示されるようになりました。

* `config.railties_order`でrailtiesの読み込み順を以下のように変更できるようになりました。

    ```ruby
    config.railties_order = [Blog::Engine, :main_app, :all]
    ```

* scaffoldがコンテンツのない場合に「204 No Content for API requests」を返すようになりました。これでjQueryでscaffoldをすぐ使えるようになります。

* `Rails::Rack::Logger`ミドルウェアが更新され、`config.log_tags`で設定した任意のタグを`ActiveSupport::TaggedLogging`に適用するようになりました。これにより、サブドメインやリクエストidといったマルチユーザーのproductionアプリケーションで有用なデバッグ情報をログにタグ付けするのが簡単になります。

* `rails new`のデフォルトオプションを`~/.railsrc`で設定できるようになりました。`rails new`を実行するたびに利用するコマンドラインオプションをホームディレクトリの`.railsrc`設定ファイルで指定できます。

* `destroy`のエイリアス`d`が追加されました。これはエンジンでも利用できます。

* scaffoldジェネレータやモデルジェネレータのデフォルトの属性が`string`になりました。これにより、`rails g scaffold Post title body:text author`のように実行できます。

* caffoldジェネレータ/モデルジェネレータ/マイグレーションジェネレータで「index」や「uniq」を指定できるようになりました。例:

    ```bash
    $ bin/rails g scaffold Post title:string:index author:uniq price:decimal{7,2}
    ```

    上の前者は`title`と`author`でインデックスを作成し、後者はuniqueインデックスを作成します。「decimal」などの型ではカスタムオプションも指定できます。上の例では`price`でdecimalカラムの精度（全体の桁）を7、桁（小数点以下の桁）を2に指定しています。

* デフォルトのGemfileからturn gemが削除されました。

* 旧来の`rails generate plugin` プラグインジェネレータが削除されました。今後は`rails plugin new`をお使いください。

* 旧来の`config.paths.app.controller` APIが削除されました。今後は`config.paths["app/controller"]`をお使いください。

#### 非推奨

* `Rails::Plugin`が非推奨化され、Rails 4.0で削除されます。今後は`vendor/plugins`にプラグインを追加するのではなく、gemやbundlerでパスやgit dependencyを指定してください。

Action Mailer
-------------

* `mail`のバージョンが2.4.0にアップグレードされました。

* Rails 3.0で非推奨化されたAction Mailer APIが削除されました。

Action Pack
-----------

### Action Controller

* `ActionController::Base`のデフォルトモジュールが`ActiveSupport::Benchmarkable`になりました。これにより、以前のようにコントローラのコンテキストで`#benchmark`メソッドを利用できるようになりました。

* `caches_page`に`:gzip`オプションが追加されました。`page_cache_compression`を使ってこのオプションのデフォルト値をグローバルに設定できます。

* レイアウトの指定に`:only`条件や`:except`条件を用いてそれらの条件が失敗した場合にデフォルトのレイアウト（layouts/applicationなど）が使われるようになりました。

    ```ruby
    class CarsController
      layout 'single_car', :only => :show
    end
    ```

    上の例では、`:show`アクションの場合に`layouts/single_car`が使われ、それ以外のアクションでは`layouts/application`（`layouts/cars`がある場合はそちら）が使われます。

* `form_for`が変更され、`:as`オプションが指定されると`#{action}_#{as}`をCSSのクラスやidとして用いるようになりました。なお、従来は`#{as}_#{action}`でした。

* `attr_accessible`属性が設定されている場合に、Active Recordモデルの`ActionController::ParamsWrapper`で`attr_accessible`属性のみをラップするようになりました。設定されてない場合は、`attribute_names`クラスメソッドが返す属性のみをラップします。これにより、ネストした属性を`attr_accessible`に追加した場合のネスト属性のラップ方法が修正されます。

* コールバックが停止するたびに「Filter chain halted as コールバック名 rendered or redirected」がログに出力されるようになりました。

* `ActionDispatch::ShowExceptions`がリファクタリングされました。このコントローラは例外を表示するかどうかの選択を受け持ちます。コントローラで`show_detailed_exceptions?`を上書きすれば、リクエストのエラー時にデバッグ情報を返すべきかどうかを指定できます。

* レスポンスのbodyが空の場合にレスポンダが「204 No Content for API requests」を返すようになりました（新しいscaffoldと同様です）。

* `ActionController::TestCase`のcookieがリファクタリングされました。今後、テストケースでのcookieの代入には以下のように`cookies[]`をお使いください。


    ```ruby
    cookies[:email] = 'user@example.com'
    get :index
    assert_equal 'user@example.com', cookies[:email]
    ```

    cookieをクリアするには`clear`を使います。

    ```ruby
    cookies.clear
    get :index
    assert_nil cookies[:email]
    ```

    今後`HTTP_COOKIE`は出力されません。cookie jarはリクエスト間で保たれるため、テスト時に環境を人為的に操作する場合は、cookie jarの作成前に行う必要があります。

* `send_file`で`:type`が指定されていない場合にファイル拡張子からMIMEタイプを推測するようになりました。

* PDFやZIPなどのMIMEタイプが追加されました。

* `fresh_when/stale?`がオプションハッシュの代わりにレコードを1件取るようになりました。

* CSRFトークンが見当たらない場合のwarningログレベルが`:debug`から`:warn`に変更されました。

* アセットはリクエストプロトコルをデフォルトで使います。リクエストが利用できない場合はデフォルトで相対を使います。

#### 非推奨

* 親のレイアウトが明示的に設定されているコントローラでの暗黙のレイアウト探索が非推奨になりました。

    ```ruby
    class ApplicationController
      layout "application"
    end

    class PostsController < ApplicationController
    end
    ```

    上の例では、`PostsController`は今後postレイアウトを自動で探索しなくなります。自動探索が必要な場合は、`ApplicationController`の`layout "application"`を削除するか、`PostsController`で明示的にレイアウトを`nil`に設定してください。

* `ActionController::UnknownAction`が非推奨化されました。今後は`AbstractController::ActionNotFound`をお使いください。

* `ActionController::DoubleRenderError`が非推奨化されました。今後は`AbstractController::DoubleRenderError`をお使いください。

* アクションが見当たらない場合の`method_missing`が非推奨化されました。今後は`action_missing`をお使いください。

* `ActionController#rescue_action`、`ActionController#initialize_template_class`、`ActionController#assign_shortcuts`が非推奨化されました。

### Action Dispatch

* `ActionDispatch::Response`のデフォルト文字セットを設定する`config.action_dispatch.default_charset`が追加されました。

* `ActionDispatch::RequestId`ミドルウェアが追加されました。これはレスポンスで一意のX-Request-Idヘッダーを有効にして`ActionDispatch::Request#uuid`メソッドを使えるようにします。これにより、スタック内のエンドツーエンドでのリクエストの追跡や、Syslogのようにさまざまなログが混在しているログで個別のリクエストを特定するのが容易になります。

* `ShowExceptions`ミドルウェアで、アプリケーションが失敗した場合の例外レンダリングを受け持つ「例外アプリケーション」を受け取れるようになりました。この例外アプリケーションは起動時に`env["action_dispatch.exception"]`の例外のコピーを取り、ステータスコードに書き換えられた`PATH_INFO`を取ります。

* rescueのレスポンスを、railtie経由で`config.action_dispatch.rescue_responses`の指定に沿って設定できるようになりました。

#### 非推奨

* コントローラレベルでのデフォルト文字セットをせってする機能が非推奨になりました。今後は`config.action_dispatch.default_charset`をお使いください。

### Action View

* `ActionView::Helpers::FormBuilder`に`button_tag`のサポートが追加されました。このサポートは、`submit_tag`のデフォルトの振る舞いを模倣します。

    ```erb
    <%= form_for @post do |f| %>
      <%= f.button %>
    <% end %>
    ```

* dateヘルパーが新しく`:use_two_digit_numbers => true`オプションを取れるようになりました。これは月や日のselectボックスの数字の頭にゼロを表示します（それぞれの値は変わりません）。たとえば、ISO 8601形式の「2011-08-01」といった日付を表示するのに便利です。

* フォームで名前空間を指定して、フォーム要素のid属性を一意にできるようになりました。この名前空間属性の名前は、生成されたHTML idの冒頭にアンダースコア付きで追加されます。

    ```erb
    <%= form_for(@offer, :namespace => 'namespace') do |f| %>
      <%= f.label :version, 'Version' %>:
      <%= f.text_field :version %>
    <% end %>
    ```

* `select_year`のオプション数の上限が1000になりました。`:max_years_allowed`オプションで上限を独自に設定できます。

* `content_tag_for`と`div_for`がレコードのコレクションを受け取れるようになりました。受け取る引数をブロックで設定すると、そのレコードを最初の引数としてyieldすることもできるようになりました。x

    ```ruby
    @items.each do |item|
      content_tag_for(:li, item) do
         Title: <%= item.title %>
      end
    end
    ```

つまり、上のように書く代わりに、今後は以下のように書けます。

    ```ruby
    content_tag_for(:li, @items) do |item|
      Title: <%= item.title %>
    end
    ```

* `font_path`ヘルパーメソッドが追加されました。これは`public/fonts`にあるフォントアセットへのパスを算出します。

#### 非推奨

* フォーマットやハンドラを`render :template`などに渡すこと（例: `render :template => "foo.html.erb"`）は非推奨になりました。今後はオプションで直接`:handlers`や`:formats`を指定できるようになりました（例: ` render :template => "foo", :formats => [:html, :js], :handlers => :erb`）。

### Sprockets

* Sprocketsのログ出力を制御する`config.assets.logger`オプションが設定に追加されました。`false`にするとログ出力が止まり、`nil`にするとデフォルトの`Rails.logger`が使われます。

Active Record
-------------

* 値が「on」や「ON」のbooleanカラムは`true`に型キャストされます。

* `timestamps`メソッドで`created_at`カラムや`updated_at`カラムが作成されると、デフォルトでnullが許容されなくなります。

* `ActiveRecord::Relation#explain`が実装されました。

* `ActiveRecord::Base.silence_auto_explain`が実装されました。これを用いると、ブロック内の自動EXPLAINを選択的に無効にできます。

* 実行の遅いクエリの自動EXPLAINログ出力を実装しました。遅いクエリの判定基準は、新しく追加された`config.active_record.auto_explain_threshold_in_seconds`パラメータで設定します。パラメータを`nil`にするとこの機能を無効にできます。デフォルトはdevelopmentモードで`0.5`、testモードやproductionモードでは`nil`です。Rails 3.2でこの機能をサポートするのは、SQLite、MySQL（mysql2アダプタ）、PostgreSQLです。

* 単一カラムのキーバリューストアを宣言する`ActiveRecord::Base.store`が追加されました。

```ruby
class User < ActiveRecord::Base
  store :settings, accessors: [ :color, :homepage ]
end

u = User.new(color: 'black', homepage: '37signals.com')
u.color                          # アクセサに保存されている属性
u.settings[:country] = 'Denmark' # アクセサで指定されていない属性でも使える
```

* マイグレーションを特定のスコープ（対象）に対してのみ実行する機能が追加されました。これを用いて、特定のエンジンのマイグレーションのみを実行できます（取り外す必要のあるエンジンでの変更を元に戻すなど）。

```bash
$ rake db:migrate SCOPE=blog
```

* エンジンからコピーしたマイグレーションファイルのスコープが、エンジンの名前で指定されるようになりました（例: `01_create_posts.blog.rb`）。

* `ActiveRecord::Relation#pluck`メソッドが実装されました。これは背後のテーブルのカラム値を直接配列として返します。シリアライズされた属性でも使えます

```ruby
Client.where(:active => true).pluck(:id)
# SELECT id from clients where active = 1
```

* 関連付けメソッドの生成は、独立した1つのモジュール内で作成されるようになりました。これはオーバーライドやコンポジションできるようにするためです。たとえば`MyModel`というクラスがあり、そのモジュールが`MyModel::GeneratedFeatureMethods`だとします。Active Modelで定義された`generated_attributes_methods`が実行されると、このモジュールはただちにそのモデルクラスにincludeされるので、関連付けメソッドは同じ名前の属性メソッドをオーバーライドします。

* 一意のクエリを生成する`ActiveRecord::Relation#uniq`が追加されました。

    ```ruby
    Client.select('DISTINCT name')
    ```

    上は以下のように書けます。

    ```ruby
    Client.select(:name).uniq
    ```


    リレーションでクエリの一意性を解除することもできます。

    ```ruby
    Client.select(:name).uniq.uniq(false)
    ```

* SQLite、MySQL、PostgreSQLでインデックスのソート順をサポートしました。

* `:class_name`オプションで文字列の他にシンボルも取れるようになりました。Railsに慣れていない人の混乱を避けるのと、既に文字列とシンボルのどちらも取れる`:foreign_key`などとの一貫性を保つのが目的です。

```ruby
has_many :clients, :class_name => :Client # シンボルの最初は大文字にする必要があることに注意
```

* developmentモードで`db:drop`を実行するとtestデータベースも削除されるようになりました。`db:create`と動作を対称的にするのが目的です。

* カラムの照合順序（collation）が既に大文字小文字を区別しないようになっている場合、大文字小文字を区別する一意性のバリデーションでMySQLのLOWERの呼び出しを回避するようになりました。

* transactional fixture（トランザクションを用いるフィクスチャ）で、有効なデータベース接続がすべてリストされるようになりました。これにより、transactional fixtureを無効にしなくても異なる接続でモデルをテストできます。

* Active Recordに3つのメソッド`first_or_create`、`first_or_create!`、`first_or_initialize`が追加されました。これはレコードのfindに使われる引数とcreateに使われる引数が明確なので、従来の動的な`find_or_create_by`メソッドより優れたアプローチです。

    ```ruby
    User.where(:first_name => "Scarlett").first_or_create!(:last_name => "Johansson")
    ```

* Active Recordオブジェクトに`with_lock`メソッドが追加されました。これはトランザクションを開始してオブジェクトを（悲観的に）ロックし、ブロックをyieldします。このメソッドはオプションパラメータを1つ取って`lock!`に渡します。

    これを用いて以下のように書けるようになりました。

    ```ruby
    class Order < ActiveRecord::Base
      def cancel!
        transaction do
          lock!
          # ... ロジックのキャンセル
        end
      end
    end
    ```

    上は以下のように書けます。

    ```ruby
    class Order < ActiveRecord::Base
      def cancel!
        with_lock do
          # ... ロジックのキャンセル
        end
      end
    end
    ```

### 非推奨

* スレッド内での接続の自動切断が非推奨になりました。以下のようなコードは推奨されません。

    ```ruby
    Thread.new { Post.find(1) }.join
    ```

    以下のようにスレッドの末尾ではデータベース接続を明示的に切断すべきです。

    ```ruby
    Thread.new {
      Post.find(1)
      Post.connection.close
    }.join
    ```

    この変更が必要になるのは、アプリケーションのコード内でスレッドを生成している場合だけです。

* 5つのメソッド: `set_table_name`、`set_inheritance_column`、`set_sequence_name`、`set_primary_key`、`set_locking_column`が非推奨になりました。今後は代入メソッド（セッターメソッド）をお使いください。たとえば`set_table_name`ではなく、`self.table_name=`を使います。

    ```ruby
    class Project < ActiveRecord::Base
      self.table_name = "project"
    end
    ```

    あるいは以下のように独自の`self.table_name`メソッドを定義します。

    ```ruby
    class Post < ActiveRecord::Base
      def self.table_name
        "special_" + super
      end
    end

    Post.table_name # => "special_posts"

    ```

Active Model
------------

* 特定のエラーが1件追加されたかどうかをチェックする`ActiveModel::Errors#added?`が追加されました。

* `strict => true`を指定することで、失敗すると常に例外をraiseする厳密なバリデーションを定義できるようになりました。

* サニタイザーの振る舞いを置き換える簡易APIとして`mass_assignment_sanitizer`オプションが提供されました。サニタイザーの`:logger`（デフォルト）の振る舞いや`:strict`の振る舞いもサポートされます。

### 非推奨

* `ActiveModel::AttributeMethods`の`define_attr_method`が非推奨になりました。このメソッドは、Active Recordで非推奨になる`set_table_name`などのメソッドでしかサポートされていないためです。

* `Model.model_name.partial_path`が非推奨になりました。今後は`model.to_partial_path`をお使いください。

Active Resource
---------------

* リダイレクトレスポンスの「303 See Other」「307 Temporary Redirect」の振る舞いは、「301 Moved Permanently」「302 Found」のように変わりました。

Active Support
--------------

* `ActiveSupport:TaggedLogging`が追加されました。これは任意の標準`Logger`クラスをラップしてタグ付け機能を提供します。

    ```ruby
    Logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

    Logger.tagged("BCX") { Logger.info "Stuff" }
    # Logs "[BCX] Stuff"

    Logger.tagged("BCX", "Jason") { Logger.info "Stuff" }
    # Logs "[BCX] [Jason] Stuff"

    Logger.tagged("BCX") { Logger.tagged("Jason") { Logger.info "Stuff" } }
    # Logs "[BCX] [Jason] Stuff"
    ```

* `Date`や`Time`や`DateTime`の`beginning_of_week`メソッドで、その週の開始日と仮定される日を表すオプション引数を渡せるようになりました。

* ブロックの実行中にイベントのサブスクリプションを提供する`ActiveSupport::Notifications.subscribed`が追加されました。

* 新しい3つのメソッド`Module#qualified_const_defined?`、`Module#qualified_const_get`、`Module#qualified_const_set`が定義されました。これらは標準APIで対応するメソッドと似ていますが、省略なしの定数名（qualified constant name）を取れます。

* 活用形の`#demodulize`を補完する`#deconstantize`メソッドが追加されました。これは省略なしの定数名から最も右のセグメントを除去します。

* `safe_constantize`が追加されました。これは文字列を定数化しますが、定数（またはその一部）が存在しない場合に例外をraiseするのではなく`nil`を返す点が異なります。

* `ActiveSupport::OrderedHash`は、`Array#extract_options!`を利用するとextract可能とマーキングされるようになりました。

* `Array#prepend`（`Array#unshift`のエイリアス）と`Array#append`（`Array#<<`のエイリアス）が追加されました。

* Ruby 1.9での空文字の定義がUnicodeホワイトスペースに拡張されました。また、Ruby 1.8では「全角スペース（ideographic space: U`3000）」がホワイトスペースとみなされるようになりました。

* 活用形を解釈するinflectorが頭字語を扱えるようになりました。

* 期間を生成する`Time#all_day`、`Time#all_week`、`Time#all_quarter`、`Time#all_year`が追加されました。

    ```ruby
    Event.where(:created_at => Time.now.all_week)
    Event.where(:created_at => Time.now.all_day)
    ```

* `instance_accessor: false`オプションが`Class#cattr_accessor`および類似のメソッドに追加されました。

* `ActiveSupport::OrderedHash`で、`#each`や`#each_pair`に渡すブロックがパラメータをsplatで受け取る場合の振る舞いが変わりました。

* developmentモードやtestingモードで使う`ActiveSupport::Cache::NullStore`が追加されました。

* `ActiveSupport::SecureRandom`が削除され、標準ライブラリの`SecureRandom`に置き換えられました。

### 非推奨

* `ActiveSupport::Base64`が非推奨になりました。今後は`Base64`をお使いください。

* `ActiveSupport::Memoizable`が非推奨になりました。今後はRuby標準のメモ化パターンをお使いください。

* `Module#synchronize`が非推奨になりました。代替機能はありません。Ruby標準ライブラリのMonitorをお使いください。

* `ActiveSupport::MessageEncryptor#encrypt`と`ActiveSupport::MessageEncryptor#decrypt`が非推奨になりました。

* `ActiveSupport::BufferedLogger#silence`が非推奨になりました。特定のログを抑制したい場合は、ログレベルを適切なものに変更してください。

* `ActiveSupport::BufferedLogger#open_log`は非推奨になりました。これはそもそもpublicにすべきではありませんでした。

* `ActiveSupport::BufferedLogger`で、ログファイル用のディレクトリを自動作成する振る舞いが非推奨になりました。利用する前にログファイルを置くディレクトリがあることをご確認ください。

* `ActiveSupport::BufferedLogger#auto_flushing`が非推奨になりました。今後は背後のファイルハンドルのsyncレベルを設定するか、ファイルシステムを調整してください。今後はFSのキャッシュがflushを制御するようになりました。

    ```ruby
    f = File.open('foo.log', 'w')
    f.sync = true
    ActiveSupport::BufferedLogger.new f
    ```

* `ActiveSupport::BufferedLogger#flush`が非推奨になりました。ファイルハンドルでsyncを設定するか、ファイルシステムを調整してください。

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](http://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

Rails 3.2リリースノートの編集担当は[Vijay Dev](https://github.com/vijaydev)でした。
