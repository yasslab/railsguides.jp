Rails 3.0 - 2010/08
===============================

Rails 3.0は、晩ご飯も作れば洗濯物も畳んでくれる、夢のような製品です。Rails 3.0なしで今までどうやって暮らしていけたのか、不思議で仕方がなくなるでしょう。Rails 3.0は、これまでのRailsバージョンの中でかつてない高みに到達しました。

冗談はともかく、Rails 3.0は実によい仕上がりとなりました。Merbチームが我らがRailsチームに参加したことでもたらされた素晴らしいアイデアがすべて込められています。Merbチームはフレームワークの謎に満ちた内部をスリムかつ高速化し、素敵なAPIを多数もたらしてくれました。Merb 1.xをご存じの方であれば、Rails 3.0にその成果が多数盛り込まれていることがおわかりいただけるはずです。Rails 2.xをご存じの方もきっとRails 3.0を好きになっていただけるでしょう。

多くの機能や改良APIを搭載したRails 3.0は、内部がきれいになったかどうかに関心のない方も夢中になるでしょう。Railsアプリケーション開発者にとって、かつてないほど素晴らしい時期が到来しました。その中からいくつかご紹介します。

* RESTful宣言を重視する新しいルーター
* Action Controllerの後でモデル化される新しいAction Mailer API（もうマルチパートメッセージの送信で悩むことはありません！）
* リレーショナル代数の上で構築される、Active Recordのチェイン可能なクエリ言語
* Prototype.jsやjQueryなどのドライバを搭載したUnobtrusive JavaScript（UJS）ヘルパー（さようならインラインJS）
* Bundlerによる明示的な依存性管理

そして何よりも、今回私たちは旧APIを非推奨化する際にできるかぎり適切なwarningを表示することを心がけました。つまり、Rails 3に移行するために、既存のアプリケーションの古いコードを今すぐ最新のベストプラクティスにすべて書き換えなくてもよいということです。

これらのリリースノートでは主要なアップグレードを取り扱いますが、細かなバグ修正や変更点については記載しませんのでご注意ください。Rails 3.0は、250人を超える人々による4,000件近いコミットを含みます。すべての変更点をチェックしたい方は、GitHub上のメインRailsリポジトリで[コミットリスト](https://github.com/rails/rails/commits/3-0-stable)をご覧ください。

--------------------------------------------------------------------------------

Rails 3のインストール方法は次のとおりです。

```bash
# セットアップで必要な場合はsudoを使います
$ gem install rails
```


Rails 3へのアップグレード
--------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 2.3.5までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 3にアップデートしてください。終わったら、以下の変更点にご注意ください。

### Rails 3ではRuby 1.8.7以降が必須

Rails 3.0ではRuby 1.8.7以上が必須です。これより前のバージョンのRubyのサポートは公式に廃止されたため、速やかにRubyをアップグレードすべきです。Rails 3.0はRuby 1.9.2とも互換性があります。

TIP: Ruby 1.8.7のp248とp249には、Railsクラッシュの原因となるマーシャリングのバグがあります。なおRuby Enterprise Editionでは1.8.7-2010.02のリリースでこの問題が修正されました。現行のRuby 1.9のうち、Ruby 1.9.1はRails 3.0でセグメンテーションフォールト（segfault）で完全にダウンするため利用できません。Railsをスムーズに動かすため、Rails 3でRuby 1.9.xを使いたい場合は1.9.2をお使いください。

### Railsの「アプリケーションオブジェクト」

Rails 3では、同一プロセス内で複数のRailsアプリケーション実行をサポートするための基礎の一環として、「アプリケーションオブジェクト」という概念が導入されました。1つのアプリケーションオブジェクトには、そのアプリケーション固有の設定がすべて保持されます。しかも、この設定は従来のRailsの`config/environment.rb`と極めて似通っています。

今後、各Railsアプリケーションはそれに対応するアプリケーションオブジェクトを持たなければなりません。このアプリケーションオブジェクトは`config/application.rb`で定義されます。既存のアプリケーションをRails 3にアップグレードする場合、この`config/application.rb`を追加して、`config/environment.rb`内の設定を適宜そこに移動しなければなりません。

### script/*がscript/railsに置き換えられる

従来スクリプトの置き場に使われていた`script`ディレクトリは、新しい`script/rails`に置き換えられます。`script/rails`は直接実行するものではありませんが、Railsアプリケーションのルートディレクトリで呼び出されたことを`rails`コマンドが検知して、代わりにスクリプトを実行します。望ましい用法は以下のとおりです。

```bash
$ rails console                      # script/consoleではない
$ rails g scaffold post title:string # script/generate scaffold post title:stringではない
```

`rails --help`を実行すればすべてのオプションを表示できます。

### 依存関係とconfig.gem

従来の`config.gem`を用いる方式は廃止され、`bundler`と`Gemfile`を用いる方式に置き換えられました。後述の[gemに移行する](#gemに移行する)を参照してください。

### アップグレードプロセス

アップグレードプロセスを支援するために、[Rails Upgrade](https://github.com/rails/rails_upgrade)というプラグインが自動化の一部として作成されました。

このプラグインをインストールして`rake rails:upgrade:check`を実行すれば、アプリ内でアップデートの必要な箇所をチェックできます（アップグレード方法の情報へのリンクも表示されます）。このプラグインは、`config.gem`呼び出しに基づいて`Gemfile`を生成するタスクや、現在のルーティングから新しいルーティングファイルを生成するタスクも提供します。以下を実行すればプラグインを取得できます。

```bash
$ ruby script/plugin install git://github.com/rails/rails_upgrade.git
```

動作例については「[Rails Upgradeプラグインが公式化された] (http://omgbloglol.com/post/364624593/rails-upgrade-is-now-an-official-plugin)
（英語）」で参照できます。

Rails Upgradeツール以外にも、支援が必要な場合はIRCやGoogleグループの[rubyonrails-talk](https://groups.google.com/group/rubyonrails-talk)に自分と同じ問題に遭遇した人がおそらくいるでしょう。ぜひアップグレード作業をブログ記事にして、他の人々も知見を得られるようにしましょう。

Rails 3.0アプリケーションを作成する
--------------------------------

```
# 'rails'というRubyGemがインストールされている必要があります。
$ rails new myapp
$ cd myapp
```

### gemに移行する

今後のRailsでは、アプリケーションのルートディレクトリに置かれる`Gemfile`を使って、アプリケーションの起動に必要なgemを指定するようになりました。この`Gemfile`は[Bundler](https://github.com/carlhuda/bundler)というgemによって処理され、依存関係のある必要なgemをすべてインストールします。依存するgemをそのアプリケーションの中にだけインストールして、OS環境にある既存のgemに影響を与えないようにすることもできます。

詳細情報: [Bundlerホームページ](https://bundler.io/)

### 最新のgemを使う

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使ってアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```
$ ruby /path/to/rails/bin/rails new myapp --dev
```

Railsアーキテクチャの変更
---------------------------

Railsのアーキテクチャで6つの大きな変更点が発生しました。

### Railtiesが一新された

Railtiesが更新され、Railsフレームワーク全体で一貫したプラグインAPIを提供するようになるとともに、ジェネレータやRailsバインディングが完全に書き直されました。これによって、開発者がジェネレータやアプリケーションフレームワークのあらゆる重要なステージに統一的かつ定義済みの方法でフックをかけられるようになりました。

### Railsのあらゆるコアコンポーネントが分離された

MerbとRailsの主要なマージ作業のひとつが、Railsのコアコンポーネントの密結合を切り離すことでした。この作業が完了したことで、Railsのあらゆるコアコンポーネントが同一のAPIを使うようになりました。これらのAPIはプラグイン開発に利用できます。つまり、作成したプラグインやコアコンポーネントを置き換える（DataMapperやSequelなど）際に、Railsコアコンポーネントからアクセスできるあらゆる機能にアクセスして自由自在に拡張できるようになったということです。

詳しくは「[The Great Decoupling](http://yehudakatz.com/2009/07/19/rails-3-the-great-decoupling/)」を参照してください。

### Active Modelを抽象化した

密結合したコアコンポーネントの切り離し作業の一環として、Active Recordへの結合をAction Packから切り出しました。この作業が完了したことで、新しいORMプラグインではActive Modelインターフェイスを実装するだけでAction Packとシームレスに協調動作できるようになりました。

詳しくは「[Make Any Ruby Object Feel Like ActiveRecord](http://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/)」を参照してください。

### コントローラを抽象化した

密結合したコアコンポーネントの切り離し作業として、基底スーパークラスを1つ作成しました。このクラスは、ビューのレンダリングなどを扱うHTTPの記法から分離されています。この`AbstractController`クラスを作成したことで、`ActionController`や`ActionMailer`が極めてシンプルになり、これらのライブラリすべてから共通部分が切り出されてAbstract Controllerに移動しました。

詳しくは「[Rails Edge Architecture](http://yehudakatz.com/2009/06/11/rails-edge-architecture/)」を参照してください。

### Arelを統合した

[Arel](https://github.com/brynary/arel)（Active Relationとも呼ばれます）がActive Recordの下に配置され、Railsで必須のコンポーネントになりました。Arelは、Active Recordを簡潔にするSQL抽象化を提供し、Active Recordのリレーション機能を支えます。

詳しくは「[Why I wrote Arel](http://magicscalingsprinkles.wordpress.com/2010/01/28/why-i-wrote-arel/)」を参照してください。

### メールを切り出した

Action Mailerは最初期からモンキーパッチやプリパーサーだらけで、配信エージェントや受信エージェントまであり、さらにソースツリーでTMailをベンダリングしているというありさまでした。Rails 3では、メールに関連するあらゆる機能を[Mail](https://github.com/mikel/mail) gemで抽象化しました。こちらでもコードの重複が著しく解消され、Action Mailerとメールパーサーの間に定義可能な境界を作成しやすくなりました。

詳しくは「[New Action Mailer API in Rails 3](http://lindsaar.net/2010/1/26/new-actionmailer-api-in-rails-3)」を参照してください。

ドキュメント
-------------

Railsツリーのドキュメントが更新されてAPI変更がすべて反映されました。さらに、[Rails Edgeガイド](https://edgeguides.rubyonrails.org/)にもRails 3.0の変更点を順次反映中です。ただし、[guides.rubyonrails.org](https://guides.rubyonrails.org/)の本ガイドについては、安定版Railsのドキュメントのみを含みます（執筆時点では3.0がリリースされるまで2.3.5となります）。

詳しくは「[Rails Documentation Projects](https://weblog.rubyonrails.org/2009/1/15/rails-documentation-projects.)」を参照してください。

国際化（I18n）
--------------------

Rails 3では国際化（I18n）のサポートに関して、速度改善が著しい最新の[I18n](https://github.com/svenfuchs/i18n) gemなど多くの作業が行われました。

* あらゆるオブジェクトでのI18n: `ActiveModel::Translation`や`ActiveModel::Validations`を含むあらゆるオブジェクトにI18nの振る舞いを追加できます。訳文の`errors.messages`フォールバック機能もあります。
* 属性にデフォルトの訳文を与えられます。
* フォームのsubmitタグが、オブジェクトのステータスに応じて自動的に正しいステータス（CreateまたはUpdate）を取れるようになったことで、正しい訳文も取れるようになりました。
* I18n化されたラベルに属性名を渡すだけで使えるようになりました。

詳しくは「[Rails 3 I18n changes](http://blog.plataformatec.com.br/2010/02/rails-3-i18n-changes/)」を参照してください。

Railties
--------

主要なRailsフレームワークの分離作業に伴って、Railtiesも大規模にオーバーホールされ、フレームワーク/エンジン/プラグインをできるだけ楽に拡張できる形で連結しました。

* アプリケーションごとに独自の名前空間が与えられます。アプリケーションはたとえば`アプリ名.boot`で始まり、他のアプリケーションとのやりとりが今よりもずっと簡単になります。
* `Rails.root/app`以下に置かれるものはすべて読み込みパスに追加されるようになりました。これにより、たとえば`app/observers/user_observer.rb`を作るだけで、設定変更なしでRailsが読み込んでくれます。
* Rails 3.0では`Rails.config`オブジェクトが提供されます。これは、Railsの膨大な設定オプションをすべて集約する中央リポジトリを提供します。

アプリケーション生成時に、test-unit/Active Record/Prototype.js/Gitのインストールをスキップするフラグも渡せるようになりました。また、`--dev`フラグも新たに追加されたことで、Railsを指す`Gemfile`をチェックアウト状態でアプリをセットアップできるようになりました（これは`rails`バイナリへのパスで決定されます）。詳しくは`rails --help`を参照してください。

Rails 3.0のRailtiesジェネレータでは、基本的に以下のようなさまざまな注意点があります。

* ジェネレータが完全に書き直されたことで後方互換性が失われた
* RailsテンプレートAPIとジェネレータAPIがマージされた: 利用上は従来と同じです
* ジェネレータは特殊なパスからの読み込みを行わなくなった: 今後はRubyの読み込みパスのみを探索しますので、`rails generate foo`を呼び出すと`generators/foo_generator`を探索します。
* 新しいジェネレータではフックが提供される: あらゆるテンプレートエンジン/ORM/テストフレームワークを簡単にフックインできます
* 新しいジェネレータでは、`Rails.root/lib/templates`にテンプレートのコピーを置くことでテンプレートをオーバーライドできる
* `Rails::Generators::TestCase`も提供される: これを用いて独自のジェネレータを作成・テストできます

また、Railtiesジェネレータで生成されるビューについてもいくつかオーバーホールが行われました。

* ビューで`p`タグの代わりに`div`タグが使われるようになった
* scaffoldジェネレータで、editビューとnewビューの重複コードの代わりに`_form`パーシャルを使うようになった
* scaffoldフォームで`f.submit`が使われるようになった: これは、渡されるオブジェクトのステートに応じて「Create ModelName」または「Update ModelName」を返します

最後に、rakeタスクもいくつかの点が拡張されました。

* `rake db:forward`が追加された: マイグレーションを個別またはグループにまとめてロールフォワードできます
* `rake routes CONTROLLER=x`が追加された: コントローラを1つ指定してルーティングを表示できます。

Railtiesで以下が非推奨化されました。

* `RAILS_ROOT`が非推奨化: 今後は`Rails.root`を使います
* `RAILS_ENV`が非推奨化: 今後は`Rails.env`を使います
* `RAILS_DEFAULT_LOGGER`が非推奨化: `Rails.logger`を使います

`PLUGIN/rails/tasks`と`PLUGIN/tasks`は今後どのタスクでも読み込まれなくなったので、今後は`PLUGIN/lib/tasks`を使わなければなりません。

詳しくは以下を参照してください。

* [Discovering Rails 3 generators](http://blog.plataformatec.com.br/2010/01/discovering-rails-3-generators)
* [Making Generators for Rails 3 with Thor](http://caffeinedd.com/guides/331-making-generators-for-rails-3-with-thor)
* [The Rails Module (in Rails 3)](http://litanyagainstfear.com/blog/2010/02/03/the-rails-module/)

Action Pack
-----------

Action Packは内部と外部ともに大きく変更されました。

### Abstract Controller

Action Controllerから一般性の高い部分をAbstract Controllerに切り出して再利用可能なモジュールとし、テンプレートやパーシャルのレンダリング、ヘルパー、訳文、ログ出力など「リクエスト-レスポンス」サイクルのあらゆる要素をどのライブラリからでも利用できるようにしました。この抽象化によって、`ActionMailer::Base`は`AbstractController`を継承してRails DSLをMail gemでラップするだけで済むようになりました。

Abstract Controllerを導入したことで、Action Controllerのコードをクリーンアップするよい機会となり、コードをシンプルにする部分が抽象化されました。

ただし、Abstract Controllerはユーザー（開発者）が直接使うAPIではない点にご注意ください。日々のRails開発でAbstract Controllerを使うことはありません。

詳しくは「[Rails Edge Architecture](http://yehudakatz.com/2009/06/11/rails-edge-architecture/)」を参照してください。

### Action Controller

* `application_controller.rb`に`protect_from_forgery`がデフォルトで含まれるようになりました。
* `cookie_verifier_secret`は非推奨化され、今後は`Rails.application.config.cookie_secret`で代入されます。また、これは`config/initializers/cookie_verification_secret.rb`という独自のファイルに移動しました。
* `session_store`は`ActionController::Base.session`で設定されるようになり、`Rails.application.config.session_store`に移動しました。デフォルトは`config/initializers/session_store.rb`で設定されます。
* `cookies.secure`を用いて、暗号化された値を`cookie.secure[:key] => value`でcookieに設定できます。
* `cookies.permanent`を用いて、恒久的な値を`cookie.permanent[:key] => value`でcookieハッシュに設定できます。署名済みの値が検証に失敗すると例外がraiseされます。
* `respond_to`ブロック内の`format`呼び出しに、`:notice => 'This is a flash message'`や`:alert => 'Something went wrong'`を渡せるようになりました。`flash[]`ハッシュの動作は従来と同じです。
* `respond_with`メソッドがコントローラに追加されます。これを用いて、込み入った`format`ブロックをシンプルに書けます。
* `ActionController::Responder`が追加されました。これを用いて、レスポンスを柔軟に生成できます。

以下が非推奨化されました。

* `filter_parameter_logging`が非推奨化されました。今後は`config.filter_parameters << :password`をお使いください。

詳しくは以下を参照してください。

* [Render Options in Rails 3](https://www.engineyard.com/blog/2010/render-options-in-rails-3/)
* [Three reasons to love ActionController::Responder](https://weblog.rubyonrails.org/2009/8/31/three-reasons-love-responder)

### Action Dispatch

Action DispatchはRails 3.0で新しく追加されました。これはルーティングの明快な実装を新たに提供します。

* ルーターが大々的に書き直されてクリーンアップされたことで、RailsのルーターがRails DSLを持つ`rack_mount`となりました。これは単独のソフトウェアです。
* 各アプリケーションで定義されるルーティングは、以下のようにApplicationモジュール内で名前空間化されるようになりました。

    ```ruby
    # 従来

    ActionController::Routing::Routes.draw do |map|
      map.resources :posts
    end

    # 今後はこのように書く

    AppName::Application.routes do
      resources :posts
    end
    ```

* `match`メソッドがルーターに追加され、マッチしたルーティングに任意のRackアプリケーションも渡せるようになりました。
* `constraints`メソッドがルーターに追加され、定義済みの制約を用いてルーターを保護できるようになりました。
* `scope`メソッドがルーターに追加され、以下のようにさまざまな言語（ロケール）やアクションへのルーティングを名前空間化できるようになりました。

    ```ruby
    scope 'es' do
      resources :projects, :path_names => { :edit => 'cambiar' }, :path => 'proyecto'
    end

    # /es/proyecto/1/cambiarでeditアクションにアクセスできる
    ```

* `root`メソッドがルーターに追加され、これで`match '/', :to => path`をショートカットできるようになりました。
* マッチにセグメントをオプションとして渡せるようになりました。たとえば`match "/:controller(/:action(/:id))(.:format)"`の場合、丸かっこで囲まれた各セグメントがオプションになります。
* ルーティングをブロックで表現できるようになりました。`controller :home { match '/:action' }`のように呼び出せます。

NOTE: `map`コマンドの旧来の書式は、後方互換性レイヤがあることで引き続き使えます。ただし、後方互換性レイヤは3.1リリースで削除される予定です。

以下が非推奨化されました。

* 非RESTアプリケーションですべてのルーティングをキャッチする`/:controller/:action/:id`はコメントアウトされるようになりました。
* `:path_prefix`ルーティングは存在しなくなりました。また、`:name_prefix`に渡された値の末尾に自動的に"_"が追加されるようになりました。

詳しくは以下を参照してください。

* [The Rails 3 Router: Rack it Up](http://yehudakatz.com/2009/12/26/the-rails-3-router-rack-it-up/)
* [Revamped Routes in Rails 3](http://rizwanreza.com/2009/12/20/revamped-routes-in-rails-3)
* [Generic Actions in Rails 3](http://yehudakatz.com/2009/12/20/generic-actions-in-rails-3/)

### Action View

#### Unobtrusive JavaScript（UJS）

Action Viewヘルパーで大規模な書き直しが行われ、Unobtrusive JavaScript（UJS）フックが実装され、旧来のインラインAJAXコマンドが削除されました。これによって、RailsでヘルパーでUJSフックを実装するときに任意のUJS準拠ドライバを利用できるようになりました。

具体的には、旧来の`remote_<メソッド名>`ヘルパーはRailsコアからすべて削除され、[Prototype Legacy Helper](https://github.com/rails/prototype_legacy_helper)に移動しました。今後UJSフックをHTML側で取得するには、以下のように`:remote => true`を渡します。


```ruby
form_for @post, :remote => true
```

上のコードから以下のHTMLが生成されます。

```html
<form action="http://host.com" id="create-post" method="post" data-remote="true">
```

#### ヘルパーがブロックを受け取れるようになった

`form_for`や`div_for`などの、ブロック内のコンテンツを挿入するヘルパーが、以下のように`<%=`を使うようになりました。

```html+erb
<%= form_for @post do |f| %>
  ...
<% end %>
```

今後これと同様の自作ヘルパーは、手動で出力バッファにappendするのではなく、文字列を返すことが期待されます。

それ以外のヘルパー（`cache`や`content_for`など）は、この変更の影響を受けないため、従来同様`&lt;%`が必要です。

#### その他の変更

* HTML出力を`h(string)`呼び出しでエスケープする必要はもうありません。`h(string)`はデフォルトであらゆるビューテンプレートで有効になります。エスケープを解除した（unescaped）文字列が欲しい場合は`raw(string)`を呼び出します。
* ヘルパーがデフォルトでHTML 5を出力するようになりました。
* フォームラベルヘルパーが、単一の値を元にI18nの複数の値を取り出せるようになりました。つまり、`f.label :name`とすると`:name`の訳文を取り出します。
* I18nのselectラベルは、今後`:en.support.select`ではなく`:en.helpers.select`と記述すべきです。
* ERBテンプレート内の式展開でHTML出力末尾のCR文字を除去するために置かれていたマイナス記号は、今後不要です。
* Action Viewに`grouped_collection_select`ヘルパーが追加されました。
* `content_for?`が追加されました。これはレンダリング前のビューにコンテンツが存在するかどうかをチェックします。
* `:value => nil`をフォームヘルパーに渡すと、デフォルト値を使わずにフィールドの`value`属性を`nil`に設定できます。
* `:id => nil`をフォームヘルパーに渡すと、フィールドが`id`属性なしでレンダリングされます。
* `image_tag`に`:alt => nil`を渡すと、`img`タグが`alt`属性なしでレンダリングされます。

Active Model
------------

Rails 3.0で新たにActive Modelが導入されました。Active Modelは任意のORMライブラリを抽象化するレイヤを提供し、Active Modelインターフェイスを実装してRailsとやり取りするのに用います。

### ORM抽象化とAction Packインターフェイス

コアコンポーネント分離作業のひとつは、Active Recordへの結合をAction Packからすべて切り出すことでした。この作業が完了したことで、新しいORMプラグインはすべて、Active Modelインターフェイスを実装するだけでAction Packとシームレスにやりとりできるようになりました。

詳しくは[Make Any Ruby Object Feel Like ActiveRecord](http://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/)を参照してください。

### バリデーション

バリデーションがActive RecordからActive Modelに移動し、Rail 3のさまざまなORMライブラリで使えるバリデーションのインターフェイスを提供するようになりました。

* `validates :attribute, options_hash`ショートカットメソッドができました。これによって、あらゆるクラスメソッドのバリデーションに用いるオプションを渡せるようになり、1つのバリデーションメソッドに複数のオプションを渡せるようになりました。

* `validates`メソッドのオプションは以下のとおりです。
    * `:acceptance => Boolean`
    * `:confirmation => Boolean`
    * `:exclusion => { :in => Enumerable }`
    * `:inclusion => { :in => Enumerable }`
    * `:format => { :with => Regexp, :on => :create }`
    * `:length => { :maximum => Fixnum }`
    * `:numericality => Boolean`
    * `:presence => Boolean`
    * `:uniqueness => Boolean`

NOTE: Rails 2.3スタイルのバリデーションメソッドはRails 3.0でも引き続きサポートされます。この新しいバリデーションメソッドの設計はモデルに新たなバリデーションを追加するためのものであり、既存APIを置き換えるものではありません。

バリデータオブジェクトを1つ渡すこともできます。バリデータオブジェクトは、Active Modelを利用するオブジェクト間で再利用できます。

```ruby
class TitleValidator < ActiveModel::EachValidator
  Titles = ['Mr.', 'Mrs.', 'Dr.']
  def validate_each(record, attribute, value)
    unless Titles.include?(value)
      record.errors[attribute] << 'must be a valid title'
    end
  end
end
```

```ruby
class Person
  include ActiveModel::Validations
  attr_accessor :title
  validates :title, :presence => true, :title => true
end

# Active Recordで用いる場合

class Person < ActiveRecord::Base
  validates :title, :presence => true, :title => true
end
```

以下のようなintrospectionもサポートします。

```ruby
User.validators
User.validators_on(:login)
```

詳しくは以下を参照してください。

* [Sexy Validation in Rails 3](http://thelucid.com/2010/01/08/sexy-validation-in-edge-rails-rails-3/)
* [Rails 3 Validations Explained](http://lindsaar.net/2010/1/31/validates_rails_3_awesome_is_true)

Active Record
-------------

Rails 3.0ではActive Recordについて集中的な作業が行われました。Active Modelへの抽象化、Arelによるクエリインターフェイスの全面的な更新、バリデーションの更新を含む多くの拡張や修正が行われました。Rail 2.x APIはすべて互換性レイヤを介して利用可能になっており、この互換性レイヤは3.1までサポートされます。


### クエリインターフェイス

Active Recordのコアメソッド群が、Arelを用いて自身のリレーションを返すようになりました。Rails 2.3.xの既存のAPIは引き続きサポートされ、Rails 3.1までは非推奨化されず、Rails 3.2までは削除されません。ただし新しいAPIでは、以下の新しいメソッド群が提供され、どのメソッドも互いにチェイン可能なリレーションを返します。

* `where`: 何を返すかという条件をリレーションに提供します。
* `select`: モデルのどの属性をデータベースから返したいかを選択します。
* `group`: 提供された属性のリレーションをグループ化します。
* `having`: リレーションのグループ化を制約する式（GROUP BY制約）を提供します。
* `joins`: リレーションを別のテーブルに結合（join）します。
* `clause`: リレーションのjoinを制約する式（JOIN制約）を提供します。
* `includes`: プリロードされた他のリレーションをインクルードします。
* `order`: 提供された式に基づいてリレーションの並び順（order）を指定します。
* `limit`: リレーションのレコード数を、指定の上限値に制限します（limit）。
* `lock`: テーブルから返されたレコードをロックします。
* `readonly`: データのコピーをリードオンリーにしたものを返します。
* `from`: リレーションシップを複数のテーブルのどれから選択するかを指定します。
* `scope`（旧`named_scope`）: リレーションを返し、他のリレーションメソッドと互いにチェインできるようにします。
* `with_scope`と`with_exclusive_scope`もリレーションを返すようになったことでチェイン可能になりました。
* `default_scope`もリレーションで使えるようになりました。

詳しくは以下を参照してください。

* [Active Record Query Interface](http://m.onkey.org/2010/1/22/active-record-query-interface)
* [Let your SQL Growl in Rails 3](http://hasmanyquestions.wordpress.com/2010/01/17/let-your-sql-growl-in-rails-3/)


### 機能追加

* `:destroyed?`がActive Recordオブジェクトに追加されました。
* `:inverse_of`Active Record関連付け（association）に追加され、読み込み済みの関連付けのインスタンスを、データベースにアクセスせずに取れるようになりました。

### 修正と非推奨化

Active Recordブランチでは他にも多数の修正が行われました。

* SQLite2のサポートが終了し、SQLite3がサポート対象になった
* MySQLのカラム順をサポート
* PostgreSQLアダプタの`TIME ZONE`サポートが修正され、誤った値が挿入されないようになった
* PostgreSQLテーブル名で複数のスキーマをサポート
* PostgreSQLでXMLデータ型カラムをサポート
* `table_name`がキャッシュされるようになった
* Oracleアダプタで多くの作業が行われ、バグも多数修正された

以下の非推奨化も行われました。

* Active Recordクラスの`named_scope`が非推奨化され、シンプルな`scope`にリネームされた
* `scope`メソッドでは、従来の`:conditions => {}`ではなく今後リレーションメソッドを使うべき（例: `scope :since, lambda {|time| where("created_at > ?", time) }`）
* `save(false)`が非推奨化され、今後は`save(:validate => false)`に
* Active RecordのI18nエラーメッセージは`:en.activerecord.errors.template`から今後`:en.errors.template`に変更すべき
* `model.errors.on`が非推奨化され、今後は`model.errors[]`に
* `validates_presence_of => validates`は今後`:presence => true`に
* `ActiveRecord::Base.colorize_logging`と`config.active_record.colorize_logging`が非推奨化され、今後はそれぞれ`Rails::LogSubscriber.colorize_logging`や`config.colorize_logging`に

NOTE: 数か月前にActive Recordのedge版にState Machineが実装されていましたが、Rails 3.0リリースからは削除されました。

Active Resource
---------------

Active ResourceもActive Modelに切り出されたことで、Action PackでActive Resourceオブジェクトをシームレスに利用できるようになりました。

* Active Modelで使えるバリデーションを追加
* observer用フックを追加
* HTTPプロキシのサポート
* ダイジェスト認証のサポートを追加
* モデルの命名をActive Modelに移動
* Active Resource属性をHashWithIndifferentAccessに変更
* findスコープと同等なエイリアス`first`、`last`、`all`を追加
* `find_every`で何も返されなかった場合に`ResourceNotFound`を返さないようになった
* `save!`を追加（オブジェクトが`valid?`でなければ`ResourceInvalid`をraiseする）
* `update_attribute`と`update_attributes`をActive Resourceモデルに追加
* `exists?`を追加
* `SchemaDefinition`を`Schema`にリネーム、`define_schema`を`schema`にリネーム
* エラーの読み込みにリモートエラーの`content-type`ではなくActive Resourcesの`format`を用いるようになった
* スキーマブロックには`instance_eval`を用いるようになった
* `ActiveResource::ConnectionError#to_s`を修正（`@response`が#codeや#messageに応答しない場合にRuby 1.9互換になるようにする）
* JSONフォーマットのエラーをサポート
* `load`が数値の配列でも使えるようになった
* リモートリソースの410レスポンスを、リソースが削除されたと認識するようになった
* Active Resource接続にSSLオプションを設定する機能を追加
* 接続のタイムアウト設定が`Net::HTTP` `open_timeout`にも効くようになった

以下は非推奨化されました。

* `save(false)`が非推奨化され、今後は`save(:validate => false)`に
* Ruby 1.9.2: `URI.parse`と`.decode`が非推奨化され、今後はライブラリで使われなくなった

Active Support
--------------

Active Supportの必要な機能だけを利用できるよう、多くの作業が行われました。これにより、Active Supportライブラリの一部の機能だけを使うために全体を`require`する必要がなくなりました。これにより、Railsのさまざまなコアコンポーネントがスリム化できるようになります。

Active Supportの主な変更点は以下のとおりです。

* ライブラリをクリーンアップし、不要なメソッドを徹底的に削除しました。
* Active Supportで[TZInfo](http://tzinfo.rubyforge.org/)や[Memcache Client](http://deveiate.org/projects/RMemCache/)や[Builder](http://builder.rubyforge.org/)のベンダリングバージョンの提供が終了しました。今後これらはすべて依存ライブラリに含まれ、`bundle install`コマンドでインストールされます。
* `ActiveSupport::SafeBuffer`に安全なバッファが実装された
* `Array.uniq_by`と`Array.uniq_by!`を追加
* `Array#rand`を削除し、Ruby 1.9から`Array#sample`をバックポートした
* `TimeZone.seconds_to_utc_offset`が誤った値を返すバグを修正した
* `ActiveSupport::Notifications`ミドルウェアを追加
* `ActiveSupport.use_standard_json_time_format`のデフォルトがtrueになった
* `ActiveSupport.escape_html_entities_in_json`のデフォルトがfalseになった
* `Integer#multiple_of?`がゼロを引数として受け取れるようになり、レシーバーがゼロでない場合にfalseを返すようになった
* `string.chars`が`string.mb_chars`にリネームされた
* `ActiveSupport::OrderedHash`がYAMLでデシリアライズできるようになった
* XmlMini用のSaxベースのパーサーを追加（LibXMLとNokogiriを利用）
* `Object#presence`を追加（`#present?`の場合はオブジェクトを、それ以外の場合は`nil`を返す）
* `String#exclude?`コア拡張を追加（`#include?`と逆の結果を返す）
* `DateTime`属性を持つモデルで`to_yaml`が正しく動作するために、`to_i`を`ActiveSupport`の`DateTime`に追加
* `Enumerable#exclude?`を追加（`if !x.include?`という書き方を避けるため`Enumerable#include?`と逆の結果を返す）
* RailsのXSS（クロスサイトスクリプティング）のエスケープがデフォルトでオンになった
* `ActiveSupport::HashWithIndifferentAccess`のdeepマージをサポート
* `Enumerable#sum`があらゆるenumerableで動作するようになった（`:size`に応答しない場合でも利用可能）
* 長さゼロのdurationを`inspect`すると空文字列ではなく'0 seconds'が返るようになった
* `element`と`collection`を`ModelName`に追加
* `String#to_time`や`String#to_datetime`で分数形式の秒を扱うようになった
* beforeコールバックやafterコールバックで`:before`や`:after`の両方に応答するaroundフィルタオブジェクトのコールバックを新たにサポートした
* `ActiveSupport::OrderedHash#to_a`メソッドが返す配列セットがソート済みになった（Ruby 1.9の`Hash#to_a`と一致）
* `MissingSourceFile`は定数として存在するが`LoadError`と等価になった
* `Class#class_attribute`を追加（値を継承可能でサブクラスから上書きできるクラスレベルの属性を宣言できる）
* `ActiveRecord::Associations`の`DeprecatedCallbacks`がついに削除された
* `Object#metaclass`が`Kernel#singleton_class`になりRubyと一致するようになった

以下のメソッドはRuby 1.8.7と1.9で利用できるようになったため削除されました。

* `Integer#even?`と`Integer#odd?`
* `String#each_char`
* `String#start_with?`と`String#end_with?`（三人称のエイリアスは保持）
* `String#bytesize`
* `Object#tap`
* `Symbol#to_proc`
* `Object#instance_variable_defined?`
* `Enumerable#none?`

REXMLのセキュリティパッチは、初期パッチレベルのRuby 1.8.7で必要なため引き続きActive Supportに置かれています。適用が必要かどうかはActive Supportで認識されます。

以下のメソッドはフレームワークで今後使われないため削除されました。

* `Kernel#daemonize`
* `Object#remove_subclasses_of`、`Object#extend_with_included_modules_from`、`Object#extended_by`
* `Class#remove_class`
* `Regexp#number_of_captures`、`Regexp.unoptionalize`、`Regexp.optionalize`、`Regexp#number_of_captures`

Action Mailer
-------------

Action Mailerで、メールライブラリとしてTMailに代えて新たに[Mail](http://github.com/mikel/mail)に置き換えられた新しいAPIが提供されました。Action Mailer自身はほぼ完全に書き換えられ、多くのコードに手が入れられました。その結果Action MailerはAbstract Controllerをシンプルに継承するようになり、Rails DSLでMail gemをラップするようになりました。これにより、Action Mailer内の他のライブラリとのコード量や重複が著しく削減されました。

* すべてのメイラーがデフォルトで`app/mailers`に置かれるようになった
* 新しいAPIを用いて3とおりの方法（`attachments`、`headers`、`mail`）でメールを送信できるようになった
* Action Mailerが`attachments.inline`メソッドを用いてインライン添付ファイルをネイティブでサポートするようになった
* Action Mailerのメール送信メソッドが`Mail::Message`オブジェクトを返すようになり、`deliver`メッセージを送信することで自分自身を送信できるようになった
* 配信メソッドがすべてMail gemに抽象化された
* `mail`配信メソッドが、有効なメールヘッダーのハッシュ（それらの値ペアを含む）を受け取れるようになった
* `mail`配信メソッドがAction Controllerの`respond_to`と似た振る舞いになり、テンプレートを明示的または暗黙的にレンダリングできるようになった（Action Mailerはメールを必要に応じてマルチパートメールにする）
* `mail`のブロック内で`format.mime_type`呼び出しにprocを1つ渡すことで、特定の種類のテキストを明示的にレンダリングしたり、レイアウトや別のテンプレートを追加したりできるようになった。そのproc内の`render`呼び出しはAbstract Controllerのもので、同じオプションをサポートする。
* メイラーの単体テスト項目が機能テストに移動した
* Action Mailerがヘッダーフィールドや本文（body）の自動エンコーディングをMail gemに委譲した
* Action Mailerがメールの本文やヘッダーを自動エンコードするようになった

以下は非推奨化されました。

* `:charset`、`:content_type`、`:mime_version`、`:implicit_parts_order`はすべて非推奨化され、今後は`ActionMailer.default :key => value`方式の宣言になった
* メイラーの動的な`create_method_name`や`deliver_method_name`が非推奨化された: 今後は単に`method_name`を呼ぶこと（`Mail::Message`オブジェクトが1つ返る）
* `ActionMailer.deliver(message)`が非推奨化された: 今後は単に`message.deliver`を呼ぶこと
* `template_root`が非推奨化された: 今後は`mail`生成ブロック内の`format.mime_type`メソッドからのproc内でrender呼び出しにオプションを渡すこと
* インスタンス変数を定義する`body`メソッド（`body {:ivar => value}`）が非推奨化された: 今後はインスタンス変数をメソッド内で直接宣言するだけでビューで利用できるようになる
* メイラーを`app/models`に配置することが非推奨化された: 今後は`app/mailers`を使うこと

詳しくは以下を参照してください。

* [New Action Mailer API in Rails 3](http://lindsaar.net/2010/1/26/new-actionmailer-api-in-rails-3)
* [New Mail Gem for Ruby](http://lindsaar.net/2010/1/23/mail-gem-version-2-released)


クレジット表記
-------

Rails3を頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に敬意を表明いたします。

Rails 3.0リリースノート編集担当: [Mikel Lindsaar](http://lindsaar.net)