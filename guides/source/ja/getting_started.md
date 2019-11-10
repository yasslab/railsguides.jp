Rails をはじめよう
==========================

このガイドでは、Ruby on Rails (以下 Rails) を初めて設定して実行するまでを解説します。

このガイドの内容:

* Railsのインストール方法、新しいRailsアプリケーションの作成方法、アプリケーションからデータベースへの接続方法
* Railsアプリケーションの一般的なレイアウト
* MVC (モデル・ビュー・コントローラ) およびRESTfulデザインの基礎
* Railsアプリケーションの原型を素早く立ち上げる方法

--------------------------------------------------------------------------------

本ガイドの前提条件
-----------------

本ガイドは、ゼロからRailsアプリケーションを構築したいと考えている初心者を対象にしています。読者にRailsの経験がないことを前提としています。

Railsとは、Rubyプログラミング言語の上で動作するWebアプリケーションフレームワークです。
Rubyの経験がまったくない場合、Railsを学ぶのはかなり大変な作業になるでしょう。Rubyを学ぶための精選されたオンラインリソース一覧はたくさんありますので、その中から以下をご紹介します。

* [Rubyプログラミング言語公式Webサイトの情報](https://www.ruby-lang.org/ja/documentation/)
* [無料のプログラミング学習用書籍一覧 (英語)](https://github.com/vhf/free-programming-books/blob/master/free-programming-books.md#ruby)

これらはいずれもよくできていますが、中にはRubyのバージョンが1.6など古いものもありますのでご注意ください。また、バージョン1.8を対象にしているものが多く、Railsでの日常的な開発に使う新しい文法が含まれていないこともあります。

Railsとは何か
--------------

Railsとは、Rubyプログラミング言語で書かれたWebアプリケーションフレームワークです。
Railsは、あらゆる開発者がWebアプリケーションの開発を始めるうえで必要となる作業やリソースを事前に仮定して準備しておくことで、Webアプリケーションをより簡単にプログラミングできるように設計されています。他の多くの言語によるWebアプリケーションフレームワークと比較して、アプリケーションを作成する際のコード量がより少なくて済むにもかかわらず、より多くの機能を実現できます。
Rails経験の長い多くの開発者から、おかげでWebアプリケーションの開発がとても楽しくなったという意見をいただいています。

Railsは、最善の開発方法というものを1つに定めるという、ある意味大胆な判断に基いて設計されています。Railsは、何かをなすうえで最善の方法というものが1つだけあると仮定し、それに沿った開発を全面的に支援します。言い換えれば、ここで仮定されている理想の開発手法に沿わない別の開発手法は行いにくくなるようにしています。この「The Rails Way」、「Rails流」とでもいうべき手法を学んだ人は、開発の生産性が著しく向上することに気付くでしょう。従って、Rails開発において別の言語環境での従来の開発手法に固執し、他所で学んだパターンを強引に適用しようとすると、せっかくの開発が楽しくなくなってしまうでしょう。

Railsの哲学には、以下の2つの主要な基本理念があります。

* **同じことを繰り返すな (Don't Repeat Yourself: DRY):** DRYはソフトウェア開発上の原則であり、「システムを構成する知識のあらゆる部品は、常に単一であり、明確であり、信頼できる形で表現されていなければならない」というものです。同じコードを繰り返し書くことを徹底的に避けることで、コードが保守しやすくなり、容易に拡張できるようになり、そして何よりバグを減らすことができます。
* **設定より規約が優先される (Convention Over Configuration):** Railsでは、Webアプリケーションで行われるさまざまなことを実現するための最善の方法を明確に思い描いており、Webアプリケーションの各種設定についても従来の経験や慣習を元に、それらのデフォルト値を定めています。このようにある種独断でデフォルト値が決まっているおかげで、開発者の意見をすべて取り入れようとした自由過ぎるWebアプリケーションのように、開発者が延々と設定ファイルを設定して回らずに済みます。

Railsプロジェクトを新規作成する
----------------------------

本ガイドを活用するための最善の方法は、以下の手順を取りこぼさずに1つずつ実行することです。どの手順もサンプルアプリケーションを動かすのに必要なものであり、それ以外のコードや手順は不要です。

本ガイドの手順に従うことで、`blog`という名前の非常にシンプルなブログのRailsプロジェクトを作成できます。Railsアプリケーションを構築する前に、Rails本体がインストールされていることを確認してください。

TIP: 以下の例では、Unix系OSのプロンプトとして`$`記号が使われていますが、これはカスタマイズ可能であり、自分の環境では異なる記号になっていることもあります。Windowsでは`c:\source_code>`のように表示されます。

### Railsのインストール

Railsをインストールする前に、必要な要件が自分のシステムで満たされているかどうかをチェックすべきです。必要なソフトウェアにはRubyやSQLite3も含まれます。

ターミナル (コマンドプロンプトとも言います) ウィンドウを開いてください。macOSの場合、ターミナル (Terminal.app) という名前のアプリケーションを実行します。Windowsの場合は[スタート] メニューから [ファイル名を指定して実行] をクリックして'cmd.exe'と入力します。`$`で始まる記述はコマンド行なので、これらはコマンドラインに入力して実行してください。続いて現在インストールされているRubyのバージョンが最新のものであることを確認してください。

```bash
$ ruby -v
ruby 2.5.0
```

RailsではRubyバージョン2.5.0以降が必須です。これより低いバージョンが表示された場合は、新たにRubyをインストールする必要があります。

TIP: Windowsユーザーは、[Railsインストーラ](http://railsinstaller.org)を用いてRuby on Railsを短時間でインストールできます。さまざまなOS環境でのインストール方法について詳しくは、[ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/)を参照してください。

Windowsで作業する場合は、[Ruby Installer Development Kit](https://rubyinstaller.org/downloads/)もインストールすべきです。

SQLite3データベースのインストールも必要です。

多くのUnix系OSには実用的なバージョンのSQLite3が同梱されています。 Windowsで上述のRails InstalerでRailsをインストールすると、SQLite3もインストールされます。その他の環境の方は[SQLite3](https://www.sqlite.org)のインストール方法を参照してください。

```bash
$ sqlite3 --version
```

上を実行することでバージョンを確認できます。

Railsをインストールするには、`gem install`コマンドを実行します。このコマンドはRubyGemsによって提供されます。

```bash
$ gem install rails
```

以下のコマンドを実行することで、すべて正常にインストールできたかどうかを確認できます。

```bash
$ rails --version
```

"Rails 6.0.0"などと表示されれば、次に進むことができます。

### ブログアプリケーションを作成する

Railsには、ジェネレータという多数のスクリプトが付属しており、これらが特定のタスクを開始するために必要なものを自動的に作り出してくれるので、開発が容易になります。その中から、新規アプリケーション作成用のジェネレータを使ってみましょう。これを実行すればRailsアプリケーションの基本的な部分が提供されるので、開発者が自分でこれらを作成する必要はありません。

ジェネレータを実行するには、ターミナルを開き、Railsファイルを作成したいディレクトリに移動して、以下を入力します。

```bash
$ rails new blog
```

これにより、Blogという名前のRails アプリケーションが`blog`ディレクトリに作成され、`Gemfile`というファイルで指定されているgemファイルが`bundle install`コマンドによってインストールされます。

NOTE: [WSL（Windows Subsystem for Linux）](https://ja.wikipedia.org/wiki/Windows_Subsystem_for_Linux)を使っている場合、現時点ではファイルシステムの通知の一部に制限が生じます。つまり、`rails new blog --skip-spring --skip-listen`を実行して`spring` gemや`listen` gemを無効にする必要があります。

TIP: `rails new -h`を実行すると、Railsアプリケーションビルダで使えるすべてのコマンドラインオプションを確認できます。

ブログアプリケーションを作成したら、そのフォルダ内に移動します。

```bash
$ cd blog
```

`blog`ディレクトリの下には多数のファイルやフォルダが生成されており、これらがRailsアプリケーションを構成しています。このチュートリアルではほとんどの作業を`app`ディレクトリで行いますが、Railsが生成したファイルとフォルダについてここで簡単に説明しておきます。

| ファイル/フォルダ | 目的 |
| ----------- | ------- |
|app/|ここにはアプリケーションのコントローラ、モデル、ビュー、ヘルパー、メイラー、チャンネル、ジョブズ、そしてアセットが置かれます。以後、本ガイドでは基本的にこのディレクトリを中心に説明を行います。|
|bin/|ここにはアプリケーションを起動/アップデート/デプロイするためのRailsスクリプトなどのスクリプトファイルが置かれます。|
|config/|アプリケーションの設定ファイル (ルーティング、データベースなど) がここに置かれます。詳しくは[Rails アプリケーションを設定する](configuring.html) を参照してください。|
|config.ru|アプリケーションの起動に必要となる、Rackベースのサーバー用のRack設定ファイルです。Rackについて詳しくは、[RackのWebサイト](https://rack.github.io/)を参照してください。|
|db/|現時点のデータベーススキーマと、データベースマイグレーションファイルが置かれます。|
|Gemfile<br>Gemfile.lock|これらのファイルは、Railsアプリケーションで必要となるgemの依存関係を記述します。この2つのファイルはBundler gemで使われます。Bundlerについて詳しくは[BundlerのWebサイト](https://bundler.io/)を参照してください。
|lib/|アプリケーションで使う拡張モジュールが置かれます。|
|log/|アプリケーションのログファイルが置かれます。|
|package.json|Railsアプリケーションで必要なnpm依存関係をこのファイルで指定できます。このファイルはYarnで使われます。Yarnについて詳しくは、[YarnのWebサイト](https://yarnpkg.com/lang/en/)を参照してください。|
|public/|このフォルダの下にあるファイルは外部 (インターネット) からそのまま参照できます。静的なファイルやコンパイル済みアセットはここに置きます。|
|Rakefile|このファイルには、コマンドラインから実行できるタスクを記述します。ここでのタスク定義は、Rails全体のコンポーネントに対して定義されます。独自のRakeタスクを定義したい場合は、`Rakefile`に直接書くと権限が強すぎるので、なるべく`lib/tasks`フォルダの下にRake用のファイルを追加するようにしてください。|
|README.md|アプリケーションの概要を説明するマニュアルをここに記入します。このファイルにはアプリケーションの設定方法などを記入し、これさえ読めば誰でもアプリケーションを構築できるようにしておく必要があります。|
|storage/|Diskサービスで用いるActive Storageファイルが置かれます。詳しくは[Active Storageの概要](active_storage_overview.html)を参照してください。|
|test/|Unitテスト、フィクスチャなどのテスト関連ファイルをここに置きます。テストについては[Railsアプリケーションをテストする](testing.html)を参照してください。|
|tmp/|キャッシュ、pidなどの一時ファイルが置かれます。|
|vendor/|サードパーティによって書かれたコードはすべてここに置きます。通常のRailsアプリケーションの場合、外部からのgemファイルをここに置きます。|
|.gitignore| Gitに登録しないファイル（またはパターン）をこのファイルで指定します。ファイルを登録しない方法について詳しくは[GitHub - Ignoring files](https://help.github.com/articles/ignoring-files)を参照してください。|
|.ruby-version|デフォルトのRubyバージョンがこのファイルで指定されます。|

Hello, Rails!
-------------

手始めに、画面に何かテキストを表示してみましょう。そのためには、Railsアプリケーションサーバーを起動しなくてはなりません。

### Webサーバーを起動する

先ほど作成したRailsアプリケーションは、既に実行可能な状態になっています。Webアプリケーションを開発用のPCで実際に動かしてこのことを確かめてみましょう。`blog`ディレクトリに移動し、以下のコマンドを実行します。

```bash
$ rails server
```

TIP: JavaScriptによるアセットの圧縮にはJavaScriptランタイムが必要です。ランタイムが環境にない場合は`execjs`エラーが発生します。macOSやWindowsにはJavaScriptランタイムが同梱されています。Railsが新規アプリケーション用に生成する`Gemfile`には`mini_racer`というgemがコメントアウトされた状態で含まれており、必要であればこのgemのコメントアウトを解除して有効にすることもできます。`therubyrhino`はJRubyユーザー向けに推奨されているランタイムであり、JRuby環境下ではデフォルトでアプリケーションの`Gemfile`に追加されます。サポートされているランタイムについて詳しくは[ExecJS](https://github.com/sstephenson/execjs#readme)で確認できます。

Railsで起動されるWebサーバーは、Railsにデフォルトで付属している[Puma](http://puma.io/)です。Webアプリケーションが実際に動作しているところを確認するには、ブラウザを開いて <http://localhost:3000> を表示してください。以下のようなRailsのデフォルト情報ページが表示されます。

![Welcome画面のスクリーンショット](images/getting_started/rails_welcome.png)

TIP: Webサーバーを停止するには、実行されているターミナルのウィンドウでCtrl + Cキーを押します。コマンドプロンプトのカーソルがふたたび表示されれば、サーバーは停止しています。macOSを含む多くのUnix系OSではプロンプトとしてドル記号`$`が使われます。一般に、Railsの開発モードではファイルに変更を加えた場合でもサーバーを再起動する必要はありません。ファイルの変更は自動的にサーバーに反映されます(訳注: libファイルやapplication.rbなど一部の設定ファイルなどはサーバーを再起動しないと読み込まれません)。

Railsの初期画面である「Welcome aboard」ページは、新しいRailsアプリケーションの「スモークテスト」として使えます。このページが表示されれば、サーバーが正常に動作していることまでは確認できたことになります。

### Railsで「Hello」と表示する

Railsで「Hello」と表示するには、最低でも**コントローラ**と**ビュー**が必要です。

コントローラは、アプリケーションに対する特定のリクエストを受け取って処理するのが役割です。_ルーティング_ は、リクエストをどのコントローラに割り振るかを決定するためのものです。1つのコントローラに対して複数のルーティングがあるのはよくあることです。そしてコントローラにはいくつかの _アクション_ があります。いくつかの異なるルーティングに対して、それぞれ異なるアクションを割り当てることができます。それぞれのアクションは、情報を集めてビューに送り出すのが役割です。

ビューの役割は、この情報をユーザーが読める形式で表示することです。ここで気を付けていただきたい重要な違いは、表示する情報を集めるのは _コントローラ_ であって、ビューではないということです。ビューは、コントローラが作成した情報に対して余計なことをせずに表示する必要があります。ビューテンプレートで使える言語は、デフォルトではeRuby (ERBとも、Embedded Rubyとも呼ばれます) が使われます (訳注: 近年はhamlテンプレートがよく使われます)。ERBで書かれたコードは、ユーザーに表示される前のリクエストサイクルでRailsによって処理されます。

コントローラを新規作成するには、コントローラ用のジェネレータを実行します。ここでは以下のように、Welcomeという名前のコントローラの中にindexというアクションを作成するよう指定します。

```bash
$ rails generate controller Welcome index
```

Railsは指定どおりコントローラを作成し、関連ファイルやルーティングも設定してくれます。

```bash
create  app/controllers/welcome_controller.rb
 route  get 'welcome/index'
invoke  erb
create    app/views/welcome
create    app/views/welcome/index.html.erb
invoke  test_unit
create    test/controllers/welcome_controller_test.rb
invoke  helper
create    app/helpers/welcome_helper.rb
invoke    test_unit
invoke  assets
invoke    scss
create      app/assets/stylesheets/welcome.scss
```

この中でもっとも重要なのはもちろんコントローラです。welcomeコントローラは`app/controllers/welcome_controller.rb`に作成され、対応するindexビューが`app/views/welcome/index.html.erb`に作成されます。

テキストエディタで`app/views/welcome/index.html.erb`を開いてみましょう。ファイルの中身をすべて削除し、以下の1行に置き換えてください。

```html
<h1>Hello, Rails!</h1>
```

### アプリケーションのHomeページを設定する

以上でコントローラとビューが作成されました。Railsで「Hello, Rails!」と表示してみましょう。ここでは、サイトのルートURL <http://localhost:3000> にアクセスしたときにこのメッセージが表示されるようにします。現時点のルートURLでは、デフォルトの「Welcome aboard」が表示されていますので、これを変更します。

Railsで表示させたい実際のホームページの場所を指定します。

エディタで`config/routes.rb`を開いてください。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  # routes.rbで利用できるDSLについて詳しくはhttp://guides.rubyonrails.org/routing.htmlを参照
end
```

上はアプリケーションの**ルーティングファイル**の内容です。外部からのリクエストをコントローラとアクションに振り分ける方法を、[DSL (ドメイン特化言語: domain-specific language)](https://en.wikipedia.org/wiki/Domain-specific_language)という特殊な言語でこのファイル内に記述します。このファイルに`root 'welcome#index'`というコードを追加すると、次のようになります。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  root 'welcome#index'
end
```

`root 'welcome#index'`と記述することで、アプリケーションのルートURLへのアクセスをwelcomeコントローラのindexアクションに割り当てるようRailsに指示が伝わります。同様に、`get 'welcome/index'`は<http://localhost:3000/welcome/index>というリクエストをwelcomeコントローラのindexアクションに割り当てます。後者は先ほどコントローラ用ジェネレータ (`rails generate controller Welcome index`) を実行した時に自動的に作成されています。

ブラウザで<http://localhost:3000>を表示してみましょう (ジェネレータを実行するためにRailsを止めていた場合は`rails server`を再実行してください)。`app/views/welcome/index.html.erb`の中に書いた"Hello, Rails!"という文字がブラウザ上に表示されるはずです。`WelcomeController`の`index`アクションへのルーティングが新たに形成され、ビューが正しく表示されたことがこれで確認できました。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)を参照してください。

アプリケーションの実装と実行
----------------------

以上で、コントローラとアクションとビューの作成方法を説明いたしました。ここからはもう少しブログらしい体裁を整えていきましょう。

今度はBlogアプリケーションに新しく**リソース**を作成します。ここで言う「リソース」とは、記事、人、動物などのよく似たオブジェクト同士が集まったものを指します。
リソースに対して作成 (create)、読み出し (read)、更新 (update)、削除 (destroy) の4つの操作を行なうことができるようになっており、これらの操作の頭文字を取って**CRUD**と呼ばれます。

Railsのルーティングには`resources`メソッドがあり、これを用いてRESTリソースへの標準的なルーティングを宣言できます (訳注: RESTについては[Wikipedia](http://ja.wikipedia.org/wiki/REST)を参照してください)。たとえば`config/routes.rb`で`article`リソースを宣言すると以下のようになります。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  resources :articles

  root 'welcome#index'
end
```

コマンドラインで`rails routes`コマンドを実行すると、標準的なRESTfulアクションへのルーティングがすべて定義されていることが確認できます。以下の出力のprefix列や他の列については後ほど解説しますが、ここでご注目いただきたいのは、Railsは「articles」というリソース名から単数形の「article」を推測し、両者をその意味にそって使い分けているという点です。prefix列で単一の項目には単数形のarticle、複数項目を扱う場合には複数形のarticlesが使われているという具合です。

```bash
$ rails routes
       Prefix Verb   URI Pattern                  Controller#Action
welcome_index GET    /welcome/index(.:format)     welcome#index
     articles GET    /articles(.:format)          articles#index
              POST   /articles(.:format)          articles#create
  new_article GET    /articles/new(.:format)      articles#new
 edit_article GET    /articles/:id/edit(.:format) articles#edit
      article GET    /articles/:id(.:format)      articles#show
              PATCH  /articles/:id(.:format)      articles#update
              PUT    /articles/:id(.:format)      articles#update
              DELETE /articles/:id(.:format)      articles#destroy
         root GET    /                            welcome#index
```

次の節では、アプリケーションで新しい記事を作成してそれを表示する機能を追加しましょう。これはCRUDでいう「C(作成)」と「R(読み出し)」の操作に相当します。作成するフォームは以下のような感じになります。

![新規記事投稿フォーム](images/getting_started/new_article.png)

これだけでは飾り気がなさすぎる感じもしますが、今はこれでよしとします。スタイルの追加はその後に行います。

### 土台を設置する

最初に、新規記事を作成するための場所がアプリケーション内に必要です。置き場所はやはり`/articles/new`でしょう。ルーティングは既に定義されているので、リクエストはアプリケーションの`/articles/new`に送られます。ブラウザで<http://localhost:3000/articles/new>を開くと、今はルーティングエラーが表示されます。

![Another routing error, uninitialized constant ArticlesController](images/getting_started/routing_error_no_controller.png)

このエラーが発生したのは、ルーティングで指定された先に、リクエストを処理するように定義されたコントローラが見つからないためです。この問題を解決するには、それに対応する`ArticlesController`を作成すればよいのです。以下のコマンドを実行して解決します。

```bash
$ rails generate controller Articles
```

今作成された`app/controllers/articles_controller.rb`をエディタで開くと、以下のような空のコントローラが作成されています。

```ruby
class ArticlesController < ApplicationController
end
```

コントローラは、`ApplicationController`を継承する形で定義されるシンプルなクラスです。コントローラの内側で定義されたメソッドは、コントローラのアクションになります。制作中のブログアプリケーションでは、これらのアクションがarticleに対するCRUD操作を担当します。

NOTE: Rubyのメソッドは`public`、`private`、`protected`に分けられますが、コントローラのアクションになれるのは`public`メソッドだけです。詳細については[Programming Ruby](http://www.ruby-doc.org/docs/ProgrammingRuby/)を参照してください。

ブラウザの<http://localhost:3000/articles/new>を再表示すると、今度は別のエラーが表示されます。

![Unknown action new for ArticlesController!](images/getting_started/unknown_action_new_for_articles.png)

生成した`ArticlesController`コントローラに`new`アクションが見つからないというエラーです。これは、Railsでアクションを指定せずに生成したコントローラは中身が空のままになるためです。

コントローラ内にアクションを手作りするには、単にコントローラ内でメソッドを定義すればよいのです。`app/controllers/articles_controller.rb`をエディタで開き、`ArticlesController`クラスの内側に以下のように`new`メソッドを作成します。

```ruby
class ArticlesController < ApplicationController
  def new
  end
end
```

`ArticlesController`コントローラに`new`メソッドを作成してからブラウザで<http://localhost:3000/articles/new>を再表示すると、今度はまた違うエラーが表示されます。

![Template is missing for articles/new](images/getting_started/template_is_missing_articles_new.png)

Railsでは、このシンプルなアクションに関連付けられたビューがあり、そこで情報を表示できることを期待しています。アクションは定義されましたが、これに関連付けられたビューがないのでエラーが表示されます。

以下の完全なメッセージを改めて見てみましょう。

<blockquote>
>ArticlesController#new is missing a template for request formats: text/html

>NOTE!
>Unless told otherwise, Rails expects an action to render a template with the same name, contained in a folder named after its controller. If this controller is an API responding with 204 (No Content), which does not require a template, then this error will occur when trying to access it via browser, since we expect an HTML template to be rendered for such requests. If that's the case, carry on.
</blockquote>

このメッセージでは、見つからないテンプレートを指摘してくれています。ここでは`articles/new`というテンプレートがあるはずだと言っています。Railsは最初にこのテンプレートを探します。見つからない場合は次に`application/new`というテンプレートがあるかどうかを探します。`application/new`にテンプレートがあるかどうかを探しているのは、`ArticlesController`コントローラが`ApplicationController`コントローラを継承しているからです。

メッセージの次の部分にある`request.formats`は、レスポンスで返されるテンプレートのフォーマットを示します。このページのリクエストをブラウザで行ったので`text/html`が設定されており、Railsはこれを用いて該当のHTMLテンプレートを探索します。

この場合、`app/views/articles/new.html.erb`に置かれている最もシンプルなテンプレートが使われます。テンプレートのファイル名に付いている拡張子が重要です。1つ目の拡張子はテンプレートの**フォーマット**を表し、2つ目の拡張子はここで使われる**ハンドラー**を示します。Railsは、`articles/new`というテンプレートをアプリケーションの`app/views`の下で探そうとします。ここではテンプレートのフォーマットは`html`でなければならず、デフォルトのハンドラーは`erb`でなければならないということになります。その他のハンドラーは別のフォーマットで扱われます。`builder`というハンドラーはXMLテンプレートのビルドに使われ、`coffee`というハンドラーはJavaScriptテンプレートのビルドにCoffeeScriptを用います。ここで新しく作成したいのはHTMLフォームなので、HTMLにRubyを埋め込むよう設計された`ERB`言語が使われます。

つまりこのファイルは`articles/new.html.erb`と呼ばれるべきであり、アプリケーションの`app/views`ディレクトリの下に配置される必要があります。

それでは`app/views/articles/new.html.erb`を作成し、その中に以下のように記入しましょう。

```html
<h1>New Article</h1>
```

<http://localhost:3000/articles/new>をブラウザで再表示すると、ページにタイトルが表示されるようになりました。ついに、ルーティングとコントローラとアクションとビューが協調して動作するようになりました。いよいよ新規記事を投稿するフォームを作成することにしましょう。

### 最初のフォーム

このテンプレート内にフォームを作成するために、<em>form builder</em> を使います。Railsには`form_with `というヘルパーメソッドがあり、主にこれを使ってフォームを作成します。以下のコードを`app/views/articles/new.html.erb`に追加して、`form_with`メソッドを使えるようにしましょう。

```html+erb
<%= form_with scope: :article, local: true do |form| %>
  <p>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
  </p>

  <p>
    <%= form.label :text %><br>
    <%= form.text_area :text %>
  </p>

  <p>
    <%= form.submit %>
  </p>
<% end %>
```

ページをブラウザで再表示すると、先に図に示したフォームの例のとおりにフォームが表示されます。Railsのフォーム作成は非常に簡単です。

`form_with`メソッドを呼び出すときには、このフォームを識別するためのスコープを渡してください。ここでは`:article`というシンボルを渡します。`form_with`ヘルパーは、これを見て何のフォームであるかを知ることができます。このメソッドのブロックの内側は`FormBuilder`オブジェクトを置きます(`form`で表すのが通例です)。ここでは2つのラベルと2つのテキストフィールドが置かれ、それぞれタイトルと記事本文になります。最後に、`form`オブジェクトに対して`submit`を実行すると、フォームの送信ボタンが作成されます。

しかし、このフォームには1つ問題があります。このフォームページのソースを表示して、生成されたHTMLをよく調べてみると、フォームの`action`属性の送信先が`/articles/new`になってしまっています。`/articles/new`というルーティングは、このフォームを最初に表示するときに使われるものなので、記入されたフォームの送信先まで同じルーティングにしてしまうのは変です。`/articles/new`はフォームの表示専用にすべきです。

つまり、このフォームの送信先は別のURLにする必要があります。送信先の指定は`form_with`の`:url`オプションで簡単に指定できます。Railsでは、新しいフォームの送信先となるアクションは"create"にするのが普通ですので、それに従って送信先を変更しましょう。

`app/views/articles/new.html.erb`をエディタで開き、`form_with`の行を以下のように変更します。

```html+erb
<%= form_with scope: :article, url: articles_path, local: true do |form| %>
```

この例では、`:url`オプションに`articles_path`ヘルパーが渡されています。
このときRailsの内部で何が行われているのかを知るために、`rails routes`の出力結果をもう一度見てみましょう。

```bash
$ rails routes
      Prefix Verb   URI Pattern                  Controller#Action
welcome_index GET    /welcome/index(.:format)     welcome#index
     articles GET    /articles(.:format)          articles#index
              POST   /articles(.:format)          articles#create
  new_article GET    /articles/new(.:format)      articles#new
 edit_article GET    /articles/:id/edit(.:format) articles#edit
      article GET    /articles/:id(.:format)      articles#show
              PATCH  /articles/:id(.:format)      articles#update
              PUT    /articles/:id(.:format)      articles#update
              DELETE /articles/:id(.:format)      articles#destroy
         root GET    /                            welcome#index
```

`articles_path`ヘルパーは、`articles`という接頭語に関連付けられているURIパターンをフォームの送信先とするようRailsに指示します。そしてこのフォームはデフォルトに従って`POST`リクエストとしてルーティングに送信されます。そしてこのルーティングは、現在のコントローラである`ArticlesController`の`create`アクションに関連付けられます。

このフォームと、それに関連付けられたルーティングが定義されることで、フォームに記入して送信ボタンをクリックすると新しい記事作成プロセスが開始されるようになります。この状態でフォームを送信すると、既にお馴染みの以下のエラーが表示されます。

![Unknown action create for ArticlesController](images/getting_started/unknown_action_create_for_articles.png)

そこで今度は`ArticlesController`コントローラ内に`create`アクションを作成し、フォームが動作する必要があります。

NOTE: `form_with`はデフォルトではAjaxを用いてフォームを送信するため、完全なページリダイレクトはスキップされます。本ガイドでは説明を簡単にするため`local: true`を無効にしてあります。

### 記事を作成する

「Unknown action」エラーを解消するには、`app/controllers/articles_controller.rb`ファイル内の`ArticlesController`クラス内の`new`アクションの下に`create`アクションを追加します。

```ruby
class ArticlesController < ApplicationController
  def new
  end

  def create
  end
end
```

修正後のフォームを再送信すると、おそらくページには何の変更も表示されないでしょう。しかし心配は無用です。Railsのアクションは、レスポンスの種類を指定しない場合は`204 No Content`をデフォルトで返します。ここでは`create`アクションを追加しただけで、レスポンスの振る舞いについて何も指定していませんので、新しい記事は`create`アクションによってデータベースに保存されているはずです。

フォームを送信すると、フォームに含まれるフィールドは**パラメータ**（params）としてRailsに送信されます。これらのパラメータは、受け取ったコントローラ内のアクションで参照可能になっており、これを用いて特定のタスクを実行します。実際のパラメータがどのようになっているかを確認するために、`create`アクションに以下の変更を加えてみましょう。

```ruby
def create
  render plain: params[:article].inspect
end
```

ここで`render`メソッドは非常に単純なハッシュを引数に取ります。ハッシュのキーは`:plain`、ハッシュの値は`params[:article].inspect`です。`params`メソッドは、フォームから送信されてきたパラメータ (つまりフォームのフィールド) を表すオブジェクトです。`params`メソッドは`ActionController::Parameters`オブジェクトを返します。文字列またはシンボルを使って、このオブジェクトのハッシュのキーを指定できます。今回の場合、必要なのはフォームの値のうちの1つだけです。

TIP: `params`メソッドは今後多用することになりますので、しっかり理解しておいてください。**http://www.example.com/?username=dhh&email=dhh@email.com**というURLで説明すると、`params[:username]`の値が「dhh」、`params[:email]`の値が「dhh&#64;email.com」となります。

フォームを再送信してみると、今度は以下が表示されました。

```ruby
<ActionController::Parameters {"title"=>"First Article!", "text"=>"This is my first article."} permitted: false>
```

このアクションは、フォームから送信されたパラメータをそのまま表示するようになりました。しかしこのままでは役に立ちそうにありません。確かにパラメータは表示されるようになりましたが、何の加工もされていません。

### Articleモデルを作成する

Railsのモデルは、単数形の名前を持ち、対応するデータベーステーブル名は複数形で表されるというルールがあります。Railsにはモデル作成用のジェネレータもあり、多くのRails開発者がモデル作成の際に使っています。モデルを作成するにはターミナルで以下のコマンドを実行します。

```bash
$ rails generate model Article title:string text:text
```

このコマンドを実行すると、`Article`モデルが作成されます。その中にはstring型の title属性とtext型のtext属性が作成されています。これらの属性は、データベースの`articles`テーブルに自動的に追加され、`Article`モデルと対応付けられます (訳注: 実際には後述するマイグレーションを行わないとデータベースとの対応付けは完了しません)。

Railsによって多数のファイルが作成されました。ここで必要なのは、`app/models/article.rb`と`db/migrate/20140120191729_create_articles.rb`の2つだけです (後者のファイル名には日付が含まれているのでこれと同じにはなりません)。後者のマイグレーションファイルは、データベース構造を作成するためのものであり、この次に説明します。

TIP: Active Recordは、データベースのカラム名とモデルの属性を自動的に対応付けるインテリジェントな機能を有しています。このおかげで、Railsのモデルで属性をいちいち宣言する必要がありません。そうした作業はActive Recordが自動的にやってくれます。

### マイグレーションを実行する

既に見たように`rails generate model`を実行すると、**データベースマイグレーション**ファイルが`db/migrate`の下に作成されます。マイグレーションはRubyのクラスであり、データベーステーブルの作成や変更を簡単に行うためのしくみです。マイグレーションを実行するにはコマンドを実行します。マイグレーションで行ったデータベース構成の変更は、後から取り消すことができます。マイグレーションファイルの名前にはタイムスタンプが含まれており、これに基いて、マイグレーションは作成された順に実行されます。

ここで`db/migrate/YYYYMMDDHHMMSS_create_articles.rb` ファイルをエディタで開いてみると (タイムスタンプは各自異なることにご注意ください)、以下のようになっています。

```ruby
class CreateArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
```

上のマイグレーションファイルには`change`という名前のメソッドが作成されており、マイグレーションの実行時に呼び出されます。このメソッドで定義されてる操作は取り消しが可能です。つまり、Railsはchangeメソッドで行われたマイグレーションを必要に応じて元に戻すことができます。このマイグレーションを実行すると、`articles`というテーブルが作成され、文字列カラムとテキストカラムが1つずつ作成されます。Railsは、マイグレーション時に作成日と更新日を追跡するためのタイムスタンプフィールドを2つ作成します。これは指定がなくても自動的に行われます。

TIP: マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。

ここでは、以下のようにコマンドでマイグレーションを実行します。

```bash
$ rails db:migrate
```

マイグレーションコマンドによってArticlesテーブルがデータベース上に作成されます。

```bash
==  CreateArticles: migrating ==================================================
-- create_table(:articles)
   -> 0.0019s
==  CreateArticles: migrated (0.0020s) =========================================
```

NOTE: マイグレーションはデフォルトではdevelopment (開発) 環境で実行されます。そのため、`config/database.yml`ファイルの`development`セクションで定義されている開発用データベースに対して実行される点にご注意ください。production (本番) 環境など、development以外の環境に対してもマイグレーションを実行したい場合は、`rails db:migrate RAILS_ENV=production`のように環境変数を明示的に指定する必要があります。

### コントローラでデータを保存する

ふたたび`ArticlesController`に戻りましょう。先ほど作成した`Article`モデルを用いて、`create`アクションを変更する必要があります。`app/controllers/articles_controller.rb`をエディタで開き、`create`アクションを次のように変更します。

```ruby
def create
  @article = Article.new(params[:article])

  @article.save
  redirect_to @article
end
```

変更内容を説明します。Railsのすべてのモデルは初期化時に属性(フィールド)を与えられ、それらはデータベースカラムに自動的に対応付けられます。メソッドの1行目ではまさにそれが行われています (取り出したい属性は`params[:article]`の中にあります)。次の`@article.save`で、このモデルをデータベースに保存します。最後に、ユーザーを`show`アクションにリダイレクトします (`show`アクションはこの後定義します)。訳注: モデルを保持している@articleを指定するだけで、そのモデルを表示するための`show`アクションにリダイレクトされる点にご注目ください。

TIPS: 本ガイドではarticlesが小文字で統一されているのに、`Article.new`の`A`だけなぜ大文字なのか気になる方へ: これは`app/models/article.rb`で定義されている`Article`**クラス**を表します。Rubyのクラス名は大文字で始めなければなりません。

TIP: 後に解説しますが、`@article.save`は保存に成功したかどうかを論理値 (trueまたはfalse) で返します。

この時点でブラウザで<http://localhost:3000/articles/new>を表示すると、記事の作成が *ほぼ* 可能な状態になっています。実際にやってみると、以下のようなエラーが表示されます。

![Forbidden attributes for new article](images/getting_started/forbidden_attributes_for_new_article.png)

Railsにはセキュリティの高いアプリケーションを開発するのに便利な機能が多数あり、ここではその機能に引っかかっています。これは[`strong_parameters`](/action_controller_overview.html#strong-parameters)と呼ばれるもので、コントローラのアクションで本当に使ってよいパラメータだけを厳密に指定することを強制するものです。

なぜそんな面倒なことをしないといけないのでしょうか。コントローラが受け取ったパラメータをノーチェックでまるごと自動的にモデルに渡せるようにする方が確かに開発は楽なのですが、パラメータをこのように安易に渡してしまうと、パラメータがチェックされていない点を攻撃者に悪用される可能性があります。たとえば、サーバーへのリクエストに含まれる新規投稿送信フォームに、もともとフォームになかったフィールドが攻撃者によって密かに追加され、アプリケーションの整合性が損なわれる可能性が考えられます。チェックされていないパラメータをまるごとモデルに保存する行為は、モデルに対する「マスアサインメント」と呼ばれています。これが発生すると、正常なデータの中に悪意のあるデータが含まれてしまう可能性があります。

そこで、コントローラで渡されるパラメータはホワイトリストでチェックし、不正なマスアサインメントを防がなければなりません。この場合、`create`でパラメータを安全に扱うために、`title`と`text`パラメータの利用を「許可」し、かつ「必須」であることを指定したいのです。そのための構文によって、`require`メソッドと`permit`メソッドが導入されます。これに基いて、該当行を以下のように変更します。

```ruby
  @article = Article.new(params.require(:article).permit(:title, :text))
```

この記法を毎回繰り返すのは煩雑なので、たとえば`create`アクションと`update`アクションで共用できるようにこのメソッドをくくりだしておくのが普通です。くくりだしたメソッドは、マスアサインメントを避けるだけでなく、外部から不正に呼び出されることのないように`private`宣言の後に置いてください。
修正結果は以下のようになります。

```ruby
def create
  @article = Article.new(article_params)

  @article.save
  redirect_to @article
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

TIP: 詳細については、上に挙げた参考資料に加えて[Strong Parametersに関する公式ブログの記事](https://weblog.rubyonrails.org/2012/3/21/strong-parameters/) (英語) を参照してください。

### 記事を表示する

現時点の状態でフォームを再度送信すると、`show`アクションがないというメッセージがRailsから返されます。このままでは実用に耐えないので、`show`アクションを追加して先に進むことにしましょう。

`rails routes`の出力結果にもあったように`show`アクションへのルーティングは以下のようになります。

```
article GET    /articles/:id(.:format)      articles#show
```

`:id`は、ここに`:id`パラメータが置かれることを指定するための特殊な文法です。この場合は記事のidを表します。

`new`で既に行ったのと同じ要領で、`app/controllers/articles_controller.rb`に`show`アクションを追加し、対応するビューも追加する必要があります。

NOTE: 各コントローラの標準的なCRUDアクションは、多くの場合`index`、`show`、`new`、`edit`、`create`、`update`、`destroy`の順で配置されます。この順番でなくても構いませんが、これらがいずれもpublicメソッドである点にご注意ください。本ガイドで既に説明したように、コントローラのpublicメソッドは`private`より前に配置しなければなりません。

これらを踏まえて、次のように`show`アクションを追加しましょう。

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
  end

  def new
  end

  # snippet for brevity
```

ここでいくつか注意すべき点があります。ここでは`Article.find`を用いて、取り出したい記事をデータベースから探しています。このとき、リクエストの`:id`パラメータを取り出すために`params[:id]`を引数としてfindに渡しています。そして、取り出した記事オブジェクトへの参照を保持するために、通常の変数ではなく、インスタンス変数 (`@`を冒頭に付けることで示します) が使われている点にもご注目ください。これは、Railsではコントローラのインスタンス変数はすべてビューに渡されるようになっているからです (訳注: Railsはそのために背後でインスタンス変数をコントローラからビューに絶え間なくコピーし続けています)。

それでは、`app/views/articles/show.html.erb`ファイルを作成し、以下のように記入しましょう。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>
```

上のように変更したことで、新しい記事の作成がようやくできるようになりました。
<http://localhost:3000/articles/new>をブラウザで開いて試してみましょう。

![Show action for articles](images/getting_started/show_action_for_articles.png)

### すべての記事を一覧表示する

単独の記事は表示できるようになりましたが、今度は記事の一覧も表示できるようにしてみましょう。
今度も`rails routes`でルーティングを確認すると、以下のようなルーティングが既にあります。

```
articles GET    /articles(.:format)          articles#index
```

以下のように、このルーティングに対応する`index`アクションを、`app/controllers/articles_controller.rb`の`ArticlesController`の中に作成します。`index`アクションはコントローラの最初のメソッドとして配置するのが普通です。それではやってみましょう。

```ruby
 class ArticlesController < ApplicationController
   def index
     @articles = Article.all
   end
 
   def show
     @article = Article.find(params[:id])
   end
 
   def new
   end
 
   # (以下省略)
```

最後に、このアクションに対応するビューを`app/views/articles/index.html.erb`に追加します。

```html+erb
<h1>Listing articles</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th></th>
  </tr>

  <% @articles.each do |article| %>
    <tr>
      <td><%= article.title %></td>
      <td><%= article.text %></td>
      <td><%= link_to 'Show', article_path(article) %></td>
    </tr>
  <% end %>
</table>
```

これで、`http://localhost:3000/articles`をブラウザで開くと、作成された記事の一覧が表示されるようになりました。

### リンクの追加

ここまでで、記事の作成、表示、一覧表示ができるようになりました。今度は、ページ間を移動するためのリンクを追加してみましょう。

`app/views/welcome/index.html.erb`を開いて以下のように変更してください。

```html+erb
<h1>Hello, Rails!</h1>
<%= link_to 'My Blog', controller: 'articles' %>
```

`link_to`メソッドは、Railsのビルトインヘルパーの1つです。このメソッドは、指定されたテキストに基いたリンクを作成し、ジャンプ先を表示します。ここでは各記事へのパスを指定します。

他のビューへのリンクも作成してみましょう。「New Article」リンクを`app/views/articles/index.html.erb`に追加し、`<table>`タグの上に置きます。

```erb
<%= link_to 'New article', new_article_path %>
```

このリンクをクリックするとフォームが表示され、そこで新しい記事を作成することができるようになります。

`app/views/articles/new.html.erb`のフォームの下に、記事を作成せずに元の`index`アクションに戻るリンクも作成しましょう。

```erb
<%= form_with scope: :article, url: articles_path, local: true do |form| %>
  ...
<% end %>

<%= link_to 'Back', articles_path %>
```

最後に、`app/views/articles/show.html.erb`テンプレートに、`index`アクションに戻るためのリンクも追加し、記事単体を見ていたユーザーが元に戻って一覧を参照できるようにします。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<%= link_to 'Back', articles_path %>
```

TIP: 現在と同じコントローラのアクションにリンクする場合は、`:controller`の指定は不要です。コントローラを指定しなければ、デフォルトで現在のコントローラが使われます。

TIP: developmentモード (これはRailsのデフォルトのモードです) では、Railsはリクエストのたびにアプリケーションを再読み込みします。これは開発をやりやすくするためであり、変更を行なうたびにRailsのWebサーバーを再起動する必要はありません。

### バリデーションの追加

モデルファイル`app/models/article.rb`の中身は、以下のように驚くほどシンプルです。

```ruby
class Article < ApplicationRecord
end
```

ファイルにはこれしか書かれていませんが、この`Article`クラスが`ApplicationRecord`クラスを継承していることにご注目ください。その`ApplicationRecord`はさらに`ActiveRecord::Base`を継承しており、これによって基本的なデータベースCRUD (Create、Read、Update、Destroy) 操作やデータのバリデーション（検証: validation）のほか、洗練された検索機能や複数のモデルを互いに関連付ける機能(リレーションシップ) など、きわめて多くの機能をRailsモデルに無償で提供しています。

Railsには、モデルに渡したデータをバリデーションする機能もあります。`app/models/article.rb`ファイルをエディタで開き、以下のように変更します。

```ruby
class Article < ApplicationRecord
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

このように変更されると、すべての記事にタイトルが存在し、その長さが5文字以上であることが保証されます。そうでない場合には記事はデータベースに保存されません。Railsには豊富なバリデーション機能があり、存在確認、カラムでの重複確認、フォーマット確認、関連付けられたオブジェクトがあるかどうかの確認などが行えます。バリデーションについて詳しくは[Active Record バリデーション](active_record_validations.html)を参照してください。

バリデーション機能が追加されたので、バリデーションをパスしない@articleに対して`@article.save`を実行すると`false`が返されるようになりました。さて、`app/controllers/articles_controller.rb`を再度開いてみると、残念なことにまだ`create`アクションで`@article.save`の結果を利用するようになっていません。`@article.save`が失敗したらそのことをユーザーに表示してあげないと不親切です。そのためには、`app/controllers/articles_controller.rb`の`new`アクション`と`create`アクションを以下のように変更してください。

```ruby
def new
  @article = Article.new
end

def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

`new`で`@article`というインスタンス変数が新たに作成されるようになりました。`@article`がここにある理由は間もなくわかります。

`create`アクションも、`save`の結果が`false`の場合には、`redirect_to`ではなく、`new`テンプレートに対する`render`を実行するように変更されました。ここで`render`メソッドを使う理由は、ビューの`new`テンプレートが描画されたときに、`@article`オブジェクトがビューの`new`テンプレートに返されるようにするためです。`render`による描画は、フォームの送信時と同じリクエスト内で行われます。対照的に、`redirect_to`はサーバーに別途リクエストを発行するようブラウザに対して指示するので、やりとりが1往復増えます。

<http://localhost:3000/articles/new>をブラウザで再表示し、わざと記事のタイトルを空にして保存してみましょう。Railsは記事入力フォームを再表示するはずです。しかしこれだけではまだ不親切です。入力のどこに問題があったのかをユーザーに通知する必要があります。そこで、`app/views/articles/new.html.erb`を変更して、エラーメッセージがある場合に表示するようにしてみましょう。

```html+erb
<%= form_with scope: :article, url: articles_path, local: true do |form| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
  </p>

  <p>
    <%= form.label :text %><br>
    <%= form.text_area :text %>
  </p>

  <p>
    <%= form.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
```

何やら目新しいコードが追加されています。ここでは、`@article.errors.any?`でエラーが発生しているかどうかをチェックしています。そしてエラーの場合は`@article.errors.full_messages`でエラーメッセージを全文表示します。

`pluralize`は、数値を受け取ってそれに応じて英語の「単数形/複数形」活用を行ってくれるRailsのヘルパーメソッドです。数値が1より大きい場合は、引数の文字列を自動的に複数形に変更します(訳注:`pluralize`はたいていの不規則活用にも対応しています)。

`ArticlesController`に`@article = Article.new`を追加した理由は、そうしないとビューで受け取る`@article`が`nil`になってしまい、`@article.errors.any?`を呼び出すところでエラーになってしまうためです。Articleのインスタンス作成に成功したときは@articleが`nil`にならないようにしておきたいわけです。

TIP: Railsでは、エラーメッセージを含むフィールドは自動的に`field_with_errors`クラスを持つdivタグで囲まれます。これを利用して、エラーメッセージをもっと目立たせるようにcssルールを定義しても構いません。

これで、<http://localhost:3000/articles/new>のフォームで新しい記事を保存する時にタイトルがなかった場合に、適切なエラーメッセージが表示されるようになりました。

![エラーが表示されているフォーム](images/getting_started/form_with_errors.png)

### 記事を更新する

ここまでで、CRUDのうちCとRを実現しました。今度はUの部分、つまり記事の更新を実装してみましょう。

最初に、`ArticlesController`に`edit`アクションを追加しましょう。

```ruby
def edit
  @article = Article.find(params[:id])
end
```

編集用のビューに含まれるフォームは、記事を作成するときのビューに含まれるフォームと基本的にほとんど同じです。`app/views/articles/edit.html.erb`というファイルを作成し、以下のコードを入力してください。

```html+erb
<h1>Edit article</h1>

<%= form_with(model: @article, local: true) do |form| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
  </p>

  <p>
    <%= form.label :text %><br>
    <%= form.text_area :text %>
  </p>

  <p>
    <%= form.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
```

このフォームの送信先は`update`アクションになります。今の時点では未定義ですが、この後すぐ定義します。

`article`オブジェクトを`form_with`メソッドに渡すと、編集済みの記事を送信するときに使うURLが魔法のように自動作成されます。Railsは`model`オプションに渡された値を読み取り、(今回の場合は) `PATCH`というHTTPメソッドでこのフォームを送信しようとします。`PATCH`メソッドは、RESTプロトコルに基いてリソースを**更新**する場合に使います。

`form_with`メソッドの引数にはモデルオブジェクトを（`model: @article`などのような形で）渡せます。このときヘルパーは`article`オブジェクトに含まれているフィールドでフォームの項目を埋めます。`scope: :article`のようにスコープにシンボルを指定すると、フィールドが空の状態で作成されます。詳しくは[form_withに関するAPIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with) (英語) を参照してください。

続いて、`app/controllers/articles_controller.rb`に`update`アクションを作成しましょう。

```ruby
def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end

def update
  @article = Article.find(params[:id])

  if @article.update(article_params)
    redirect_to @article
  else
    render 'edit'
  end
end
 
private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

既存のレコードを更新したいときには新たに`update`アクションを使います。このアクションには、更新後の属性を含むハッシュを渡すことができます。createのときに既に行ったように、記事の更新に失敗してエラーが発生した場合、そのことをユーザーに伝えるようにしましょう。

createアクションで使った`article_params`メソッドをここでも使うことにします。

TIP: `update`にすべての属性をもれなく渡す必要はありません。たとえば、`@article.update(title: 'A new title')`を実行した場合、Railsは`title`属性のみを更新し、それ以外の属性はそのままにします。

最後に、`edit`アクションへのリンクを全記事の一覧に追加しましょう。`app/views/articles/index.html.erb`に以下のように手を加えて"Show"リンクの隣にEditリンクを追加します。

```html+erb
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="2"></th>
  </tr>

<% @articles.each do |article| %>
  <tr>
    <td><%= article.title %></td>
    <td><%= article.text %></td>
    <td><%= link_to 'Show', article_path(article) %></td>
    <td><%= link_to 'Edit', edit_article_path(article) %></td>
  </tr>
<% end %>
</table>
```

同様に、`app/views/articles/show.html.erb`テンプレートにもEditリンクを追加しましょう。こうしておけば各記事のページから編集を行えるようになります。テンプレートの最下部に以下を追加します。

```html+erb
...

<%= link_to 'Back', articles_path %>
| <%= link_to 'Edit', edit_article_path(@article) %>
```

ここまでの変更で、アプリケーションの外観は以下のような感じになっているはずです。

![Editリンクが追加されたindexアクション](images/getting_started/index_action_with_edit_link.png)

### パーシャルでビューの重複コードを解消する

さて、`edit`ページをよく見ると、`new`ページとほとんど違いがありません。実際、フォームを表示するコードはどちらでもまったく同じになっています。パーシャル(部分テンプレートとも呼ばれます)を使って、このような無駄な重複を取り除きましょう。Rubyの慣例として、パーシャルのファイル名の先頭にはアンダースコアを追加します。

TIP: パーシャルについての詳細は本ガイドの[レイアウトとレンダリング](layouts_and_rendering.html)を参照してください。

`app/views/articles/_form.html.erb`という名前のパーシャルファイルを作成し、以下の内容を入力してください。

```html+erb
<%= form_with model: @article, local: true do |form| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
  </p>

  <p>
    <%= form.label :text %><br>
    <%= form.text_area :text %>
  </p>

  <p>
    <%= form.submit %>
  </p>
<% end %>
```

このコードをよく観察してみると、`form_with`の宣言部分以外には元のコードとの違いがないことがわかります。他のフォーム内のコードを置き換えるパーシャル内での`form_with`宣言がこのように短くて簡潔で済むのは、`@article`がRESTfulルーティングの完全なセットに対応する **リソース** であり、必要なURIとメソッドをRailsがそれに基いて推測できるからです。
`form_with`の利用法について詳しくは、[Rails APIのリソース指向のスタイル](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with-label-Resource-oriented+style) (英語) を参照してください。

今度は`app/views/articles/new.html.erb`ビューを完全に書き直して、今作成したパーシャルをここで使ってみましょう。

```html+erb
<h1>New article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

続いて、`app/views/articles/edit.html.erb`ビューでも同じ作業を行います。

```html+erb
<h1>Edit article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

### 記事を削除する

いよいよCRUDのDまで到達しました。ここでは記事をデータベースから削除します。RESTの慣例に従い、記事の削除に使うルーティングを`rails routes`の出力結果から取り出したのが以下です。

```ruby
DELETE /articles/:id(.:format)      articles#destroy
```

リソースを削除するときには`delete`ルーティングメソッドを使う必要があります。なお、この削除用ルーティングに通常の`get`ルーティングが使われていると、以下のような危険なURLを送信できてしまいます。

```html
<a href='http://example.com/articles/1/destroy'>look at this cat!</a>
```

リソースの削除に`delete`メソッドが使われ、このルーティングが`destroy`アクションに割り当てられる流れになります。この`destroy`アクションはまだ作成してなかったのでここで以下の内容で作成しましょう。

```ruby
def destroy
  @article = Article.find(params[:id])
  @article.destroy

  redirect_to articles_path
end
```

`app/controllers/articles_controller.rb`ファイルの`ArticlesController`全体は以下のようになるはずです。
 
 ```ruby
 class ArticlesController < ApplicationController
   def index
     @articles = Article.all
   end
 
   def show
     @article = Article.find(params[:id])
   end
 
   def new
     @article = Article.new
   end
 
   def edit
     @article = Article.find(params[:id])
   end
 
   def create
     @article = Article.new(article_params)
 
     if @article.save
       redirect_to @article
     else
       render 'new'
     end
   end
 
   def update
     @article = Article.find(params[:id])
 
     if @article.update(article_params)
       redirect_to @article
     else
       render 'edit'
     end
   end
 
   def destroy
     @article = Article.find(params[:id])
     @article.destroy
 
     redirect_to articles_path
   end
 
   private
     def article_params
       params.require(:article).permit(:title, :text)
     end
 end
```

データベースのレコードを削除したい場合には、Active Recordの`destroy`メソッドを呼びます。なお、レコードの削除の場合、それ専用のビューテンプレートは不要です。その代わりに削除後に`index`アクションにリダイレクトします。

最後に、 `index`アクションのテンプレート(`app/views/articles/index.html.erb`)に'Destroy'リンクを追加し、機能を完成させましょう。

```html+erb
<h1>Listing Articles</h1>
<%= link_to 'New article', new_article_path %>
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="3"></th>
  </tr>

<% @articles.each do |article| %>
  <tr>
    <td><%= article.title %></td>
    <td><%= article.text %></td>
    <td><%= link_to 'Show', article_path(article) %></td>
    <td><%= link_to 'Edit', edit_article_path(article) %></td>
    <td><%= link_to 'Destroy', article_path(article),
                    method: :delete, data: { confirm: 'Are you sure?' } %></td>
  </tr>
<% end %>
</table>
```

上で追加したコードでは、`link_to`メソッドの使い方がこれまでと違っていることにご注意ください。2番目の引数で名前付きルートを渡している点はこれまでと同じですが、その後に別の引数があります。この`method: :delete`オプションと`data: { confirm: 'Are you sure?' }`オプションはHTML5の属性です。このリンクをクリックすると、本当に削除してよいかどうかを確認するメッセージを表示し、その後`delete`メソッドとリンクを送信します。このダイアログボックスの表示は`rails-ujs`というJavaScriptファイルによって自動的に行われます。このファイルはアプリケーションの生成時に自動的にアプリケーションレイアウト (`app/views/layouts/application.html.erb`) に含まれます。このJavaScriptファイルがないと、ダイアログボックスは表示されません。

![Confirm Dialog](images/getting_started/confirm_dialog.png)

TIP: Unobtrusive JavaScript（UJS）について詳しくは[Rails で JavaScript を使う](working_with_javascript_in_rails.html)を参照してください。

以上で記事の作成、表示、一覧表示、更新、削除をひととおり実装できました。お疲れさまでした!

TIP: Railsでは、ルーティングを1つずつ手作りするよりもresourcesオブジェクトでルーティングを設定することが推奨されています。
ルーティングについて詳しくは、本ガイドの[Railsのルーティング](routing.html)を参照してください。

2番目のモデルを追加する
---------------------

今度はアプリケーションに第2のモデルを追加しましょう。この第2のモデルでは、記事へのコメントを扱います。

### モデルを生成する

今回のモデルの生成には、`Article`モデルを生成したときと同じジェネレータを使います。作成する`Comment`モデルは、記事への参照を保持します。以下のコマンドをターミナルで実行してください。

```bash
$ rails generate model Comment commenter:string body:text article:references
```

このコマンドを実行すると、4つのファイルが生成されます。

| ファイル                                         | 目的                                                                                                |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| db/migrate/20140120201010_create_comments.rb | データベースにコメント用のテーブルを作成するためのマイグレーションファイル (ファイル名のタイムスタンプはこれとは異なります) |
| app/models/comment.rb                        | Commentモデル                                                                                      |
| test/models/comment_test.rb                  | Commentモデルをテストするためのハーネス                                                                 |
| test/fixtures/comments.yml                   | テストで使うサンプルコメント                                                                     |

最初に`app/models/comment.rb`を見てみましょう。

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

`Comment`モデルの内容は、これまでに見た`Article`モデルと非常によく似ています。違いといえば、Active Recordの**関連付け**（アソシエーション: association）を設定するための`belongs_to :article`という行がある点です。関連付けについて詳しくは、本ガイドの次の節で説明します。

bashコマンドで使われている`:references`キーワードは、モデルの特殊なデータ型を表します。
これは、指定されたモデル名の後ろに`_id`を追加した名前を持つ新しいカラムをデータベーステーブルに作成します。マイグレーションの実行後に`db/schema.rb`ファイルを調べてみると理解しやすくなります。

モデルのファイルの他にマイグレーションファイルも生成されています。マイグレーションファイルは、モデルに対応するデータベーステーブルを生成するために使われます。

 ```ruby
 class CreateComments < ActiveRecord::Migration[6.0]
   def change
     create_table :comments do |t|
       t.string :commenter
       t.text :body
       t.references :article, null: false, foreign_key: true
 
       t.timestamps
     end
   end
 end
 ```

`t.references`という行は、`article_id`という名前のinteger型カラムとそのインデックス、そして`articles`の`id`カラムを指す外部キー制約を設定します。それではマイグレーションを実行しましょう。

```bash
$ rails db:migrate
```

Railsは、これまで実行されていないマイグレーションだけを適切に見分けて実行しますので、以下のようなメッセージだけが表示されるはずです。

```bash
==  CreateComments: migrating =================================================
-- create_table(:comments)
   -> 0.0115s
==  CreateComments: migrated (0.0119s) ========================================
```

### モデル同士を関連付ける

Active Recordの関連付け機能により、2つのモデルの間にリレーションシップを簡単に宣言することができます。今回の記事とコメントというモデルの場合、以下のいずれかの方法で関連付けを設定できます。

* 1つのコメントは1つの記事に属する (Each comment belongs to one article)。
* 1つの記事は複数のコメントを持てる (One article can have many comments)。

そして上の方法(における英語の記述)は、Railsで関連付けを宣言するときの文法と非常に似ています。`Comment` モデル (app/models/comment.rb) 内のコードに既に書かれていたように、各コメントは1つの記事に属しています。

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

そして、Articleモデル`app/models/article.rb`を編集して、他方のモデルを追加する必要があります。

```ruby
class Article < ApplicationRecord
  has_many :comments
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

2つのモデルで行われているこれらの宣言によって、さまざまな動作が自動化されています。たとえば、`@article`というインスタンス変数に記事が1つ含まれていれば、`@article.comments`と書くだけでその記事に関連付けられているコメントをすべて取得できます。

TIP: Active Recordの関連付けについて詳しくは、[Active Recordの関連付け(アソシエーション)](association_basics.html)ガイドを参照してください。

### コメントへのルーティングを追加する

`welcome`コントローラで行ったときと同様、`comments`を参照するためにRailsが知っておくべきルーティングを追加する必要があります。再び`config/routes.rb`ファイルを開き、以下のように変更してください。

```ruby
resources :articles do
  resources :comments
end
```

この設定により、`article`の内側に**ネストされたリソース**として`comments`が作成されます。これは、モデルの記述とは別の視点から、記事とコメントの間のリレーションシップを階層的に捉えたものであると言えます。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)を参照してください。

### コントローラを生成する

モデルを手作りしたのですから、それに合ったコントローラも作ってみたくなります。それでは、再びこれまでと同様にジェネレータを使ってみましょう。

```bash
$ rails generate controller Comments
```

上のコマンドを実行すると、4つのファイルと1つの空ディレクトリが作成されます。

| ファイル/ディレクトリ                               | 目的                                  |
| -------------------------------------------- | ---------------------------------------- |
| app/controllers/comments_controller.rb       | コメント用コントローラ                  |
| app/views/comments/                          | コントローラのビューはここに置かれる  |
| test/controllers/comments_controller_test.rb | コントローラのテスト用ファイル              |
| app/helpers/comments_helper.rb               | ビューヘルパー                       |
| app/assets/stylesheets/comment.scss          | コントローラ用のCSS (カスケーディングスタイルシート) ファイル |

一般的なブログと同様、このブログの記事を読んだ人はそこに直接コメントを追加したくなるでしょう。そしてコメントを追加後に元の記事表示ページに戻り、コメントがそこに反映されていることを確認したいはずです。そこで、`CommentsController`を用いてコメントを作成したり、スパムコメントが書き込まれたら削除できるようにしたいと思います。

そこで最初に、Articleのshowテンプレート (`app/views/articles/show.html.erb`) を改造して新規コメントを作成できるようにしましょう。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Add a comment:</h2>
<%= form_with(model: [ @article, @article.comments.build ], local: true) do |form| %>
  <p>
    <%= form.label :commenter %><br>
    <%= form.text_field :commenter %>
  </p>
  <p>
    <%= form.label :body %><br>
    <%= form.text_area :body %>
  </p>
  <p>
    <%= form.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
| <%= link_to 'Edit', edit_article_path(@article) %>
```

上のコードでは、`Article`のshowページにフォームが1つ追加されています。このフォームは`CommentsController`の`create`アクションを呼び出すことでコメントを新規作成します。`form_with`呼び出しでは配列を1つ渡しています。これは`/articles/1/comments`のような「ネストしたルーティング (nested route)」を生成します。

今度は`app/controllers/comments_controller.rb`の`create`アクションを改造しましょう。

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

上のコードは、Articleコントローラのコードを書いていたときよりも少々複雑に見えます。これはネストを使ったことによって複雑さが増したのです。コメント関連のリクエストでは、コメントが追加される先の記事がどれであったかを追えるようにしておく必要があります。そこで、`Article`モデルの`find`メソッドを最初に呼び出し、リクエストで言及されている記事(のオブジェクト)を取得して@articleに保存しています。

さらにこのコードでは、関連付けによって使えるようになったメソッドをいくつも利用しています。`@article.comments`に対して`create`メソッドを実行することで、コメントの作成と保存を同時に行っています(訳注: `build`メソッドにすれば作成のみで保存は行いません)。この方法でコメントを作成すると、コメントと記事が自動的にリンクされ、指定された記事に対してコメントが従属するようになります。

新しいコメントの作成が完了したら、`article_path(@article)`ヘルパーを用いて元の記事の画面に戻ります。既に説明したように、このヘルパーを呼び出すと`ArticlesController`の`show`アクションが呼び出され、`show.html.erb`テンプレートがレンダリングされます。この画面にコメントを表示できるようにしたいので、`app/views/articles/show.html.erb`に以下のコードを追加しましょう。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<% @article.comments.each do |comment| %>
  <p>
    <strong>Commenter:</strong>
    <%= comment.commenter %>
  </p>

  <p>
    <strong>Comment:</strong>
    <%= comment.body %>
  </p>
<% end %>

<h2>Add a comment:</h2>
<%= form_with(model: [ @article, @article.comments.build ], local: true) do |form| %>
  <p>
    <%= form.label :commenter %><br>
    <%= form.text_field :commenter %>
  </p>
  <p>
    <%= form.label :body %><br>
    <%= form.text_area :body %>
  </p>
  <p>
    <%= form.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

以上で、ブログに記事やコメントを自由に追加して、それらを正しい場所に表示できるようになりました。

![記事にコメントが追加されたところ](images/getting_started/article_with_comments.png)

リファクタリング
-----------

さて、ブログの記事とコメントが動作するようになったので、ここで`app/views/articles/show.html.erb`テンプレートを見てみましょう。何やらコードがたくさん書かれていて読みにくくなっています。ここでもパーシャルを使ってコードをきれいにしましょう。

### パーシャルコレクションをレンダリングする

最初に、特定記事のコメントをすべて表示する部分を切り出してコメントパーシャルを作成しましょう。`app/views/comments/_comment.html.erb`というファイルを作成し、以下のコードを入力します。

```html+erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>
```

続いて、`app/views/articles/show.html.erb`の内容を以下のように変更しましょう。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= form_with(model: [ @article, @article.comments.build ], local: true) do |form| %>
  <p>
    <%= form.label :commenter %><br>
    <%= form.text_field :commenter %>
  </p>
  <p>
    <%= form.label :body %><br>
    <%= form.text_area :body %>
  </p>
  <p>
    <%= form.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

これにより、`app/views/comments/_comment.html.erb`パーシャルが、`@article.comments`コレクションに含まれているコメントをすべてレンダリングするようになりました。`render`メソッドが`@article.comments`コレクションに含まれる要素を1つ1つ列挙するときに、各コメントをパーシャルと同じ名前のローカル変数に自動的に割り当てます。この場合は`comment`というローカル変数が使われ、パーシャルの表示に利用されます。

### パーシャルのフォームをレンダリングする

今度はコメント作成部分もパーシャルに追い出してみましょう。`app/views/comments/_form.html.erb`ファイルを作成し、以下のように入力します。

```html+erb
<%= form_with(model: [ @article, @article.comments.build ], local: true) do |form| %>
  <p>
    <%= form.label :commenter %><br>
    <%= form.text_field :commenter %>
  </p>
  <p>
    <%= form.label :body %><br>
    <%= form.text_area :body %>
  </p>
  <p>
    <%= form.submit %>
  </p>
<% end %>
```

続いて`app/views/articles/show.html.erb`の内容を以下のように変更しましょう。

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= render "comments/form" %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

2番目のrenderは、レンダリングする`comments/form`パーシャルテンプレートを単純に定義しているだけです。`comments/form`と書くだけで、Railsは区切りのスラッシュ文字を認識し、`app/views/comments`ディレクトリの`_form.html.erb`パーシャルをレンダリングすればよいということを理解し、実行してくれます。`app/views/comments/_form.html.erb`などと書く必要はありません。

`@article`オブジェクトはインスタンス変数なので、ビューで出力されるどのパーシャルからもアクセスできます。

コメントを削除する
-----------------

スパムコメントを削除できるようにするのも、このブログでは重要な機能です。そのためのビューを作成し、`CommentsController`に`destroy`アクションを作成する必要があります。

最初に`app/views/comments/_comment.html.erb`パーシャルに削除用のリンクを追加しましょう。

```html+erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>

<p>
  <%= link_to 'Destroy Comment', [comment.article, comment],
               method: :delete,
               data: { confirm: 'Are you sure?' } %>
</p>
```

この新しい「Destroy Comment」リンクをクリックすると、`DELETE /articles/:article_id/comments/:id`というリクエストが`CommentsController`に送信されます。コントローラはそれを受け取って、どのコメントを削除すべきかを検索することになります。それではコントローラ (`app/controllers/comments_controller.rb`) に`destroy`アクションを追加しましょう。

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    @comment.destroy
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

`destroy`アクションでは、まずどの記事が対象であるかを検索して`@article`に保存し、続いて`@article.comments`コレクションの中のどのコメントが対象であるかを特定して`@comment`に保存します。そしてそのコメントをデータベースから削除し、終わったら記事の`show`アクションに戻ります。


### 関連付けられたオブジェクトも削除する

ある記事を削除したら、その記事に関連付けられているコメントも一緒に削除する必要があります。そうしないと、コメントがいつまでもデータベース上に残ってしまいます。Railsでは関連付けに`dependent`オプションを指定することでこれを実現しています。Articleモデル`app/models/article.rb`を以下のように変更しましょう。

```ruby
class Article < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

セキュリティ
--------

### BASIC認証

このブログアプリケーションをオンラインで公開すると、このままでは誰でも記事を追加/編集/削除したり、コメントを削除したりできてしまいます。

Railsではこのような場合に便利な、非常にシンプルなHTTP認証システムが用意されています。

`ArticlesController`では、認証されていない人物がアクションに触れないようにブロックする必要があります。そこで、Railsの`http_basic_authenticate_with`メソッドを使うことで、このメソッドが許可する場合に限って、リクエストされたアクションにアクセスできるようにすることができます。

この認証システムを使うには、`ArticlesController`コントローラの最初の部分で指定します。今回は、`index`アクションと`show`アクションは自由にアクセスできるようにし、それ以外のアクションには認証を要求するようにしたいと思います。そこで、`app/controllers/articles_controller.rb`に次の記述を追加してください。

```ruby
class ArticlesController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", except: [:index, :show]

def index
    @articles = Article.all
  end

  # (以下省略)
```

コメントの削除も認証済みユーザーにだけ許可したいので、`CommentsController` (`app/controllers/comments_controller.rb`) に以下のように追記しましょう。

```ruby
class CommentsController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    ...
  end

  # (以下省略)
```

ここで記事を新規作成しようとすると、以下のようなBASIC http認証ダイアログが表示されます。

![Basic HTTP Authentication Challenge](images/getting_started/challenge.png)

もちろん、Railsでは他の認証方法も使えます。Railsにはさまざまな認証システムがありますが、その中で人気が高い認証システムは[Devise](https://github.com/plataformatec/devise)と[Authlogic](https://github.com/binarylogic/authlogic) gemの2つです。


### その他のセキュリティ対策

セキュリティ、それもWebアプリケーションのセキュリティは非常に幅広く、かつ詳細に渡っています。Railsアプリケーションのセキュリティについて詳しくは、本ガイドの[Railsセキュリティガイド](security.html)を参照してください。

次に学ぶべきこと
------------

以上で、Railsアプリケーションを初めて作るという試みは終わりです。この後は自由に更新したり実験を重ねたりできます。

もちろん、何の助けもなしにWebアプリケーションを作らなければならないなどということはないということを忘れてはなりません。RailsでWebアプリを立ち上げたり実行したりするうえで助けが必要になったら、以下のサポート用リソースを自由に参照できます。

* [Ruby on Railsガイド](index.html) -- 本書です
* [Ruby on Railsチュートリアル](https://railstutorial.jp) -- 日本語版
* [Ruby on Railsメーリングリスト](https://groups.google.com/group/rubyonrails-talk)
* irc.freenode.net上の[#rubyonrails](irc://irc.freenode.net/#rubyonrails)チャンネル

設定の落とし穴
---------------------

Railsでの無用なトラブルを避けるための最も初歩的なコツは、外部データを常にUTF-8で保存しておくことです。このとおりにしないと、RubyライブラリやRailsはネイティブデータをたびたびUTF-8に変換しなければならず、しかも場合によっては失敗します。外部データを常にUTF-8にしておくことをぜひお勧めします。

外部データのエンコードが不統一な場合によく起きる症状としては、たとえば画面に黒い菱型◆や疑問符が表示されるというものがあります。他にも、"ü"という文字のはずが"Ã¼"という文字に変わっている、などの症状もあります。Railsではこうした問題を緩和するため、問題の原因を自動的に検出して修正するために内部で多くの手順を行っています。しかし、UTF-8で保存されていない外部データがあると、Railsによる自動検出/修正が効かずに文字化けが発生することがあります。

UTF-8でないデータの主な原因は以下の2つです。

* テキストエディタ: TextMateを含む多くのテキストエディタは、デフォルトでUTF-8エンコードでテキストを保存します。使っているテキストエディタがこのようになっていない場合、テンプレートを表示する時にéなどの特殊文字が◆?のような感じでブラウザで表示されることがあります。これはi18n(国際化)用の翻訳ファイルで発生することもあります。一部のDreamweaverのようにUTF-8保存がデフォルトでないエディタであっても、デフォルトをUTF-8に変更する方法は用意されているはずです。エンコードはUTF-8に変えてください。
* データベース: Railsはデータベースから読みだしたデータを境界上でUTF-8に変換します。しかし、使っているデータベースの内部エンコード設定がUTF-8になっていない場合、UTF-8の文字の一部をデータベースにそのまま保存できないことがあります。たとえばデータベースの内部エンコードがLatin-1になっていると、ロシア語・ヘブライ語・日本語などの文字をデータベースに保存したときにこれらの情報は永久に失われてしまいます。できるかぎり、データベースの内部エンコードはUTF-8にしておいてください。
