**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

# Rails をはじめよう

このガイドでは、Ruby on Rails（以下 Rails）を初めて設定して実行するまでを解説します。

このガイドの内容:

- Railsのインストール方法、新しいRailsアプリケーションの作成方法、アプリケーションからデータベースへの接続方法
- Railsアプリケーションの一般的なレイアウト
- MVC（モデル・ビュー・コントローラ）およびRESTfulデザインの基礎
- Railsアプリケーションの原型を素早く立ち上げる方法

--------------------------------------------------------------------------------

## 本ガイドの前提条件

本ガイドは、ゼロからRailsアプリケーションを構築したいと考えている初心者を対象にしています。読者にRailsの経験がないことを前提としています。

Railsとは、プログラミング言語「Ruby」の上で動作するWebアプリケーションフレームワークです。Rubyの経験がまったくない場合、Railsを学ぶのはかなり大変な作業になるでしょう。Rubyを学ぶための精選されたオンラインリソース一覧はたくさんあるので、その中から以下をご紹介します。

- [プログラミング言語Ruby公式Webサイト](https://www.ruby-lang.org/ja/documentation/)
- [プログラミング学習コンテンツまとめ](https://github.com/EbookFoundation/free-programming-books/blob/master/books/free-programming-books-ja.md#ruby)

いずれもよくできていますが中には古いものもあり、例えばRailsの最新の文法が含まれていない場合もあります。

## Railsとは何か

Railsとは、プログラミング言語「Ruby」で書かれたWebアプリケーションフレームワークです。Railsは、あらゆる開発者がWebアプリケーション開発で必要となる作業やリソースを事前に仮定して準備することで、Webアプリケーションをより簡単に開発できるように設計されています。他の多くのWebアプリケーションフレームワークと比較して、アプリケーションを開発する際のコード量がより少なくて済むにもかかわらず、より多くの機能を実現できます。経験のある多くの開発者から「RailsのおかげでWebアプリケーション開発がとても楽しくなった」という意見もいただいています。

Railsは「最善の開発方法というものを1つに定める」という、ある意味大胆な判断に基いて設計されています。何かを成すうえで最善の方法というものを1つ仮定し、それに沿った開発を全面的に支援します。言い換えれば、ここで仮定されている理想の開発手法に沿わない別の開発手法は行いにくくなるようにしています。この「The Rails Way」、「Rails流」とでもいうべき手法を学んだ人は、開発の生産性が著しく向上することに気付くでしょう。言い換えると、Rails開発において従来の開発手法に固執し、他所で学んだパターンを強引に適用しようとすると、せっかくの開発が楽しくなくなってしまう可能性があります。

Railsの哲学には、以下の2つの主要な基本理念があります。

- **同じことを繰り返すな（Don't Repeat Yourself: DRY）:** DRYはソフトウェア開発上の原則であり、「システムを構成する知識のあらゆる部品は、常に単一であり、明確であり、信頼できる形で表現されていなければならない」というものです。同じコードを繰り返し書くことを徹底的に避けることで、コードが保守しやすくなり、容易に拡張できるようになり、そして何よりバグを減らすことができます。
- **設定より規約が優先される（Convention Over Configuration）:** Railsでは、Webアプリケーションで行われるさまざまなことを実現するための最善の方法を明確に思い描いており、Webアプリケーションの各種設定についても従来の経験や慣習を元に、それらのデフォルト値を定めています。このようにある種独断でデフォルト値が決まっているおかげで、開発者の意見をすべて取り入れようとした自由過ぎるWebアプリケーションのように、開発者が延々と設定ファイルを設定して回らずに済みます。

## Railsプロジェクトを新規作成する

本ガイドを活用するための最善の方法は、以下の手順を取りこぼさずに1つずつ実行することです。どの手順もサンプルアプリケーションを動かすのに必要なものであり、それ以外のコードや手順は不要です。

本ガイドの手順に従うことで、`blog`という名前の非常にシンプルなブログのRailsプロジェクトを作成できます。Railsアプリケーションを構築する前に、Rails本体がインストールされていることを確認してください。

TIP: 以下の例では、Unix系OSのプロンプトとして`$`記号が使われていますが、これはカスタマイズ可能であり、自分の環境では異なる記号になっていることもあります。Windowsでは`c:\source_code>`のように表示されます。

### Railsのインストール

Railsをインストールする前に、必要な要件が自分のシステムで満たされているかどうかをチェックすべきです。少なくとも以下のソフトウェアが必要です。

* Ruby
* SQLite3
* Node.js
* Yarn

#### Rubyをインストールする

ターミナル（コマンドプロンプトとも言います）ウィンドウを開いてください。macOSの場合、ターミナル（Terminal.app）という名前のアプリケーションを実行します。Windowsの場合は[スタート] メニューから [ファイル名を指定して実行] をクリックして'cmd.exe'と入力します。`$`で始まる記述はコマンド行なので、これらはコマンドラインに入力して実行してください。続いて現在インストールされているRubyのバージョンが最新のものであることを確認してください。

```bash
$ ruby -v
ruby 2.5.0
```

RailsではRubyバージョン2.5.0以降が必須です。これより低いバージョンが表示された場合は、新たにRubyをインストールする必要があります。

TIP: Windowsユーザーは、[Railsインストーラ](http://railsinstaller.org)を用いてRuby on Railsを短時間でインストールできます。さまざまなOS環境でのインストール方法について詳しくは、[ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/)を参照してください。

Windowsで作業する場合は、[Ruby Installer Development Kit](https://rubyinstaller.org/downloads/)もインストールすべきです。

OSごとのRubyインストール方法について詳しくは、[ruby-lang.org](https://www.ruby-lang.org/ja/documentation/installation/)をご覧ください。

#### SQLite3をインストールする

SQLite3データベースのインストールも必要です。
多くのUnix系OSには実用的なバージョンのSQLite3が同梱されています。 Windowsで上述のRails InstalerでRailsをインストールすると、SQLite3もインストールされます。その他の環境の方は[SQLite3](https://www.sqlite.org)のインストール方法を参照してください。

```bash
$ sqlite3 --version
```

上を実行することでバージョンを確認できます。

#### Node.jsとYarnをインストールする

最後に、アプリケーションのJavaScriptを管理するNode.jsとYarnのインストールが必要です。

[Node.jsのWebサイト](https://nodejs.org/ja/download/)のインストール方法に沿ってNode.jsをインストールします。次に以下のコマンドを実行して、正しくインストールできたかどうかを確認します。

```bash
$ node --version
```

Node.jsのバージョン番号が出力されるはずです。バージョンが8.16.0より大きいことを確認してください。

Yarnをインストールするには、[YarnのWebサイト](https://classic.yarnpkg.com/en/docs/install)のインストール方法に沿って進めます。

インストール後、以下のコマンドを実行するとYarnのバージョン番号が出力されるはずです。

```bash
$ yarn --version
```

"1.22.0"のようなバージョン番号が表示されれば、Yarnは正しくインストールされています。

#### Railsをインストールする

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

`blog`ディレクトリの下には多数のファイルやフォルダが生成されており、これらがRailsアプリケーションを構成しています。このガイドではほとんどの作業を`app`ディレクトリで行いますが、Railsが生成したファイルとフォルダについてここで簡単に説明しておきます。

**`app/`**

* ここにはアプリケーションのコントローラ、モデル、ビュー、ヘルパー、メーラー、チャンネル、ジョブズ、そしてアセットが置かれます。以後、本ガイドでは基本的にこのディレクトリを中心に説明を行います。

**`bin/`**

* ここにはアプリケーションを起動/アップデート/デプロイするためのRailsスクリプトなどのスクリプトファイルが置かれます。

**`config/`**

* アプリケーションの設定ファイル（ルーティング、データベースなど）がここに置かれます。詳しくは[Rails アプリケーションを設定する](configuring.html) を参照してください。

**`config.ru`**

* アプリケーションの起動に必要となる、Rackベースのサーバー用のRack設定ファイルです。Rackについて詳しくは、[RackのWebサイト](https://rack.github.io/)を参照してください。

**`db/`**

* 現時点のデータベーススキーマと、データベースマイグレーションファイルが置かれます。

**`Gemfile`、`Gemfile.lock`**

* これらのファイルは、Railsアプリケーションで必要となるgemの依存関係を記述します。この2つのファイルはBundler gemで使われます。Bundlerについて詳しくは[BundlerのWebサイト](https://bundler.io/)を参照してください。

**`lib/`**

* アプリケーションで使う拡張モジュールが置かれます。

**`log/`**

* アプリケーションのログファイルが置かれます。

**`package.json`**

* Railsアプリケーションで必要なnpm依存関係をこのファイルで指定できます。このファイルはYarnで使われます。Yarnについて詳しくは、[YarnのWebサイト](https://yarnpkg.com/lang/en/)を参照してください。

**`public/`**

* このフォルダの下にあるファイルは外部（インターネット）からそのまま参照できます。静的なファイルやコンパイル済みアセットはここに置きます。

**`Rakefile`**

* このファイルには、コマンドラインから実行できるタスクを記述します。ここでのタスク定義は、Rails全体のコンポーネントに対して定義されます。独自のRakeタスクを定義したい場合は、`Rakefile`に直接書くと権限が強すぎるので、なるべく`lib/tasks`フォルダの下にRake用のファイルを追加するようにしてください。

**`README.md`**

* アプリケーションの概要を説明するマニュアルをここに記入します。このファイルにはアプリケーションの設定方法などを記入し、これさえ読めば誰でもアプリケーションを構築できるようにしておく必要があります。

**`storage/`**

* Diskサービスで用いるActive Storageファイルが置かれます。詳しくは[Active Storageの概要](active_storage_overview.html)を参照してください。

**`test/`**

* Unitテスト、フィクスチャなどのテスト関連ファイルをここに置きます。テストについては[Railsアプリケーションをテストする](testing.html)を参照してください。

**`tmp/`**

* キャッシュ、pidなどの一時ファイルが置かれます。

**`vendor/`**

* サードパーティによって書かれたコードはすべてここに置きます。通常のRailsアプリケーションの場合、外部からのgemファイルをここに置きます。

**`.gitignore`**

* Gitに登録しないファイル（またはパターン）をこのファイルで指定します。ファイルを登録しない方法について詳しくは[GitHub - Ignoring files](https://help.github.com/articles/ignoring-files)を参照してください。

**`.ruby-version`**

* デフォルトのRubyバージョンがこのファイルで指定されます。

## Hello, Rails!

手始めに、画面に何かテキストを表示してみましょう。そのためには、Railsアプリケーションサーバーを起動しなくてはなりません。

### Webサーバーを起動する

先ほど作成したRailsアプリケーションは、既に実行可能な状態になっています。Webアプリケーションを開発用のPCで実際に動かしてこのことを確かめてみましょう。`blog`ディレクトリに移動し、以下のコマンドを実行します。

```bash
$ bin/rails server
```

TIP: Windowsをお使いの場合は、`bin`フォルダの下にあるスクリプトをRubyインタープリタに直接渡さなければなりません（例: `ruby bin\rails server`）

TIP: JavaScriptアセットの圧縮にはJavaScriptランタイムが必要です。ランタイムが環境にない場合は`execjs`エラーが発生します。macOSやWindowsにはJavaScriptランタイムが同梱されています。`therubyrhino`はJRubyユーザー向けに推奨されているランタイムであり、JRuby環境下ではデフォルトでアプリケーションの`Gemfile`に追加されます。サポートされているランタイムについて詳しくは[ExecJS](https://github.com/sstephenson/execjs#readme)で確認できます。

Railsで起動されるWebサーバーは、Railsにデフォルトで付属している[Puma](http://puma.io/)です。Webアプリケーションが実際に動作しているところを確認するには、ブラウザを開いて [http://localhost:3000](http://localhost:3000) を表示してください。以下のようなRailsのデフォルト情報ページが表示されます。

![Welcome画面のスクリーンショット](images/getting_started/rails_welcome.png)

Webサーバーを停止するには、実行されているターミナルのウィンドウでCtrl + Cキーを押します。一般に、development環境のRailsはサーバーの再起動を必要としません。ファイルに変更を加えれば、サーバーが自動的に変更を反映します。

Railsの初期画面である「Welcome aboard」ページは、新しいRailsアプリケーションの「スモークテスト」として使えます。このページが表示されれば、サーバーが正常に動作していることまでは確認できたことになります。

### Railsで「Hello」と表示する

Railsで「Hello」と表示するには、最低でも**コントローラ**と**ビュー**が必要です。コントローラは、アプリケーションに対する特定のリクエストを受け取って処理するのが役割です。*ルーティング* は、リクエストをどのコントローラに割り振るかを決定します。コントローラの *アクション* は、リクエストを扱うのに必要な処理を実行します。ビューは、データを好みの書式で表示します。

実装の面から見れば、ルーティングはRubyの[DSL（Domain-Specific Language）](https://en.wikipedia.org/wiki/Domain-specific_language) で書かれたルールです。コントローラはRubyのクラスで、そのクラスのpublicメソッドがアクションです。ビュー
はテンプレートで、多くの場合HTMLの中にRubyコードが含まれます。

それではルーティングを1個追加してみましょう。 `config/routes.rb`を開き、`Rails.application.routes.draw`ブロックの冒頭に以下を書きます。

```ruby
Rails.application.routes.draw do
  get "/articles", to: "articles#index"

  # routes.rbで利用できるDSLについて詳しくはhttp://guides.rubyonrails.org/routing.htmlを参照
end
```

上で宣言したルーティングは、`GET /articles`リクエストを`ArticlesController`の`index`アクションに割り当てます。

`ArticlesController`と`index`アクションを作成するには、コントローラ用のジェネレータを実行します（上で既に適切なルーティングを追加したので、 `--skip-routes`オプションでルーティングの追加をスキップします）。


```bash
$ bin/rails generate controller Articles index --skip-routes
```

Railsは指定どおりコントローラを作成し、関連ファイルやルーティングも設定してくれます。

```bash
create  app/controllers/articles_controller.rb
invoke  erb
create    app/views/articles
create    app/views/articles/index.html.erb
invoke  test_unit
create    test/controllers/articles_controller_test.rb
invoke  helper
create    app/helpers/articles_helper.rb
invoke    test_unit
invoke  assets
invoke    scss
create      app/assets/stylesheets/articles.scss
```

この中で最も重要なのは、`app/controllers/articles_controller.rb`というコントローラファイルです。このファイルを見てみましょう。

```ruby
class ArticlesController < ApplicationController
  def index
  end
end
```

`index`アクションは空です。あるアクションがビューを明示的にレンダリングしない場合（あるいはHTTPレスポンスをトリガーしない場合）、Railsはその「コントローラ名」と「アクション名」にマッチするビューを自動的にレンダリングします。これは「設定より規約」の例です。ビューは`app/views`の下に配置されるので、`index`アクションはデフォルトで`app/views/articles/index.html.erb`をレンダリングします。

それでは`app/views/articles/index.html.erb`を開き、中身を以下に置き換えましょう。

```html
<h1>Hello, Rails!</h1>
```

コントローラ用のジェネレータを実行するためにWebサーバーを停止していた場合は、`bin/rails server`で再実行します。 <http://localhost:3000/articles> にアクセスするとテキストが表示されます。

### アプリケーションのHomeページを設定する

この時点ではトップページ <http://localhost:3000> にまだ「Yay! You're on Rails!」が表示されていますので、 <http://localhost:3000> を開いたときにも「Hello, Rails!」が表示されるようにしてみましょう。これを行うには、アプリケーションの*ルートパス*（root path）をこのコントローラとアクションに対応付けます。

それでは`config/routes.rb`を開き、`Rails.application.routes.draw`ブロックの冒頭に以下のように`root`を書いてみましょう。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  get "/articles", to: "articles#index"
end
```

<http://localhost:3000> を開くと、"Hello, Rails!"という文字がブラウザ上に表示されるはずです。これで、`root`ルーティングが`ArticlesController`の`index`アクションに対応付けられたことを確認できました。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)を参照してください。

MVCを理解する
-----------

これまでに、「ルーティング」「コントローラ」「アクション」「ビュー」について解説しました。これらは[MVC（Model-View-Controller）](https://ja.wikipedia.org/wiki/Model_View_Controller)と呼ばれるパターンに沿ったWebアプリケーションの典型的な構成要素です。MVCは、アプリケーションの責務を分割して理解しやすくするデザインパターンです。Railsはこのデザインパターンに従う規約となっています。

コントローラと、それに対応して動作するビューを作成したので、次の構成要素である「モデル」を生成しましょう。

### モデルを生成する

*モデル*（model）とは、データを表現するためのRubyクラスです。モデルは、*Active Record*と呼ばれるRailsの機能を介して、アプリケーションのデータベースとやりとりできます。

モデルを定義するには、以下のようにモデル用のジェネレータを用います。

```bash
$ bin/rails generate model Article title:string body:text
```

NOTE: モデル名は常に英語の「**単数形**」で表記されます。理由は、インスタンス化されたモデルは1件のデータレコードを表すからです。この規約を覚えるために、モデルのコンストラクタを呼び出すときを考えてみましょう。`Article.new(...)`と単数形で書くことはあっても、複数形の`Articles.new(...)`では**書きません**。

ジェネレータを実行すると、以下のようにいくつものファイルが作成されます。

```
invoke  active_record
create    db/migrate/<タイムスタンプ>_create_articles.rb
create    app/models/article.rb
invoke    test_unit
create      test/models/article_test.rb
create      test/fixtures/articles.yml
```

生成されたファイルのうち、マイグレーションファイル（`db/migrate/<タイムスタンプ>_create_articles.rb`）とモデルファイル（`app/models/article.rb`）の2つを中心に解説します。

### データベースマイグレーション

*マイグレーション*（migration）は、アプリケーションのデータベース構造を変更するときに使います。Railsアプリケーションのマイグレーションは、データベースの種類を問わずにマイグレーションを実行するために、Rubyコードで記述されます。

生成されたマイグレーションファイルを開いてみましょう。

```ruby
class CreateArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body

      t.timestamps
    end
  end
end
```

`create_table`メソッドの呼び出しでは、`articles`テーブルの構成方法を指定します。`create_table`メソッドは、デフォルトで`id`カラムを「オートインクリメントの主キー」として追加します。つまり、テーブルで最初のレコードの`id`は1、次のレコードの`id`は2、というように自動的に増加します。

`create_table`のブロック内には、`title`と`body`という2つのカラムが定義されています。先ほど実行した`bin/rails generate model Article title:string body:text`コマンドでこれらのカラムを指定したことによって、ジェネレータによって自動的に追加されます。

ブロックの末尾行は`t.timestamps`メソッドを呼び出しています。これは`created_at`と`updated_at`という2つのカラムを追加で定義します。後述するように、これらのカラムはRailsによって自動で管理されるので、モデルオブジェクトを作成したり更新したりすると、これらのカラムに値が自動で設定されます。

それでは以下のコマンドでマイグレーションを実行しましょう。

```bash
$ bin/rails db:migrate
```

マイグレーションコマンドを実行すると、そのテーブルがデータベース上に作成されます。

```
==  CreateArticles: migrating ===================================
-- create_table(:articles)
   -> 0.0018s
==  CreateArticles: migrated (0.0018s) ==========================
```

TIP: マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。

### モデルを用いてデータベースとやりとりする

モデルで少し遊んでみましょう。そのために、Railsの*コンソール*と呼ばれる機能を用いることにします。Railsコンソールは、Rubyの`irb`と同様の対話的コーディング環境ですが、`irb`と違うのは、Railsとアプリケーションコードも自動的に読み込まれる点です。

以下を実行してRailsコンソールを起動しましょう。

```bash
$ bin/rails console
```

以下のような`irb`プロンプトが表示されるはずです。

```
Loading development environment (Rails 6.0.2.1)
irb(main):001:0>
```

このプロンプトで、先ほど作成した`Article`オブジェクトを以下のように初期化できます。

```
irb> article = Article.new(title: "Hello Rails", body: "I am on Rails!")
```

ここが重要です。このオブジェクトは単に*初期化された*だけの状態であり、まだデータベースに保存されていないことにご注目ください。つまりこのオブジェクトはこのコンソールでしか利用できません（コンソールを終了すると消えてしまいます）。オブジェクトをデータベースに保存するには、[`save`](
https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save)メソッドを呼び出さなくてはなりません。

```
irb> article.save
(0.1ms)  begin transaction
Article Create (0.4ms)  INSERT INTO "articles" ("title", "body", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["title", "Hello Rails"], ["body", "I am on Rails!"], ["created_at", "2020-01-18 23:47:30.734416"], ["updated_at", "2020-01-18 23:47:30.734416"]]
(0.9ms)  commit transaction
=> true
```

上の出力には、`INSERT INTO "Article" ...`というデータベースクエリも表示されています。これは、その記事がテーブルにINSERT（挿入）されたことを示しています。そして、`article`オブジェクトをもう一度表示すると、先ほどと何かが違っていることがわかります。


```
irb> article
=> #<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">
```

オブジェクトに`id`、`created_at`、`updated_at`という属性（attribute）が設定されています。先ほどオブジェクトを`save`したときにRailsが追加してくれたのです。

この記事をデータベースから取り出したいのであれば、そのモデルで[`find`](
https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find)メソッドを呼び出し、その記事の`id`を引数として渡します。

```
irb> Article.find(1)
=> #<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">
```

データベースに保存されている記事をすべて取り出したいのであれば、そのモデルで[`all`]( https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-all)メソッドを呼び出せます。

```
irb> Article.all
=> #<ActiveRecord::Relation [#<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">]>
```

このメソッドが返すのは[`ActiveRecord::Relation`](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html)オブジェクトです。これは一種の超強力な配列と考えるとよいでしょう。

TIP: モデルについて詳しくは、[Active Record の基礎](
active_record_basics.html)と[Active Record クエリインターフェイス](
active_record_querying.html)を参照してください。

モデルは、MVCというパズルの最後のピースです。次は、これらのピースをつなぎ合わせてみましょう。

### 記事のリストを表示する

`app/controllers/articles_controller.rb`コントローラを再度開いて、データベースからすべての記事を取り出せるよう`index`アクションを変更します。

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end
end
```

コントローラ内のインスタンス変数（`@`で始まる変数）は、ビューからも参照できます。つまり、`app/views/articles/index.html.erb`で`@articles`を記述するとこのインスタンス変数を参照できるということです。このファイルを開いて、以下のように書き換えます。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <%= article.title %>
    </li>
  <% end %>
</ul>
```

上記のコードでは、HTMLの中に*ERB*も書かれています。ERBとは、ドキュメントに埋め込まれたRubyコードを評価するテンプレートシステムのことです。
ここでは、`<% %>`と`<%= %>`という2種類のERBタグが使われています。`<% %>`タグは「この中のRubyコードを評価する」という意味です。`<%= %>`タグは「この中のRubyコードを評価し、返された値を出力する」という意味です。
これらのERBタグの中には、通常のRubyプログラムで書けるコードなら何でも書けますが、読みやすさのため、ERBタグに書くコードは短くする方がよいでしょう。

上のコードでは、`@articles.each`が返す値は出力したくないので`<% %>` で囲んでいますが、（各記事の）`article.title` が返す値は出力したいので`<%= %>` で囲んでいます。


ブラウザで <http://localhost:3000> を開くと最終的な結果を見られます（`bin/rails server`を実行しておくことをお忘れなく）。このときの動作は以下のようになります。

1. ブラウザは`GET http://localhost:3000`というリクエストをサーバーに送信する。
2. Railsアプリケーションがこのリクエストを受信する。
3. Railsルーターがrootルーティングを`ArticlesController`の`index`アクションに割り当てる。
4. `index`アクションは、`Article`モデルを用いてデータベースからすべての記事を取り出す。
5. Railsが`app/views/articles/index.html.erb`ビューを自動的にレンダリングする。
6. ビューにあるERBコードが評価されてHTMLを出力する。
7. サーバーは、HTMLを含むレスポンスをブラウザに送信する。

これでMVCのピースがすべてつながり、コントローラに最初のアクションができました。このまま次のアクションに進みます。

CRUDの重要性
--------------------------

ほぼすべてのWebアプリケーションは、[CRUD（Create、Read、Update、Delete)](
https://ja.wikipedia.org/wiki/CRUD)という操作を何らかの形で行います。Webアプリケーションで行われる処理の大半もCRUDが占めています。Railsフレームワークはこの点を認識しており、CRUDを行うコードをシンプルにする機能を多数備えています。

それでは、アプリケーションに機能を追加してこれらの機能を探ってみましょう。

### 記事を1件表示する

現在あるビューは、データベースにある記事をすべて表示します。今度は、1件の記事のタイトルと本文を表示するビューを追加してみましょう。

手始めに、コントローラの新しいアクションに対応付けられる新しいルーティングを1個追加します（アクションはこの後で追加します）。`config/routes.rb`を開き、ルーティングの末尾に以下のように追加します。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  get "/articles", to: "articles#index"
  get "/articles/:id", to: "articles#show"
end
```

追加したルーティングも`get`ルーティングですが、パスの末尾に`:id`が追加されている点が異なります。これはルーティングの*パラメータ*（parameter）を指定します。ルーティングパラメータは、リクエストのパスに含まれる特定の値をキャプチャして、その値を`params`というハッシュに保存します。`params`はコントローラのアクションでもアクセスできます。たとえば`GET http://localhost:3000/articles/1`というリクエストを扱う場合、`:id`の部分として`1`がキャプチャされ、`ArticlesController`の`show`アクションで`params[:id]`と書くことでアクセスできます。

それでは、`show`アクションを`app/controllers/articles_controller.rb`の`index`アクションの下に追加しましょう。

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end
end
```

`show`アクションは`Article.find`メソッドを呼び出す（[前述](#モデルを用いてデータベースとやりとりする)）ときに、ルーティングパラメータでキャプチャしたidを渡しています。返された記事は`@article`インスタンス変数に保存しているので、ビューから参照できます。`show`アクションは、デフォルトでは、`app/views/articles/show.html.erb`をレンダリングします。

今度は`app/views/articles/show.html.erb`を作成し、以下のコードを書きます。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>
```

これで、 <http://localhost:3000/articles/1> を開くと記事が1件表示されるようになりました。

仕上げとして、記事ページを開くときによく使われる方法を追加しましょう。`app/views/articles/index.html.erb`にリスト表示される記事タイトルに、その記事へのリンクを追加します。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <a href="/articles/<%= article.id %>">
        <%= article.title %>
      </a>
    </li>
  <% end %>
</ul>
```

### リソースフルルーティング

ここまでにCRUDのR（Read）をやってみました。最終的にCRUDのC（Create）、U（Update）、D（Delete）も行います。既にお気づきかと思いますが、CRUDを追加するということは「ルーティングを追加する」「コントローラにアクションを追加する」「ビューを追加する」という3つを行います。「ルーティング」「コントローラのアクション」「ビュー」がどんな組み合わせになっても、エンティティに対するCRUD操作に落とし込まれます。こうしたエンティティは*リソース*（resource）と呼ばれます。たとえば、このアプリケーションの場合は「1件の記事」が1個のリソースに該当します。

Railsは[`resources`](
https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-resources)というメソッドを提供しており、メソッド名が複数形であることからわかるように、リソースのコレクション（collection: 集まり）を対応付けるのによく使われるルーティングをすべて対応付けてくれます。C（Create）、U（Update）、D（Delete）に進む前に、 `config/routes.rb`でこれまで`get`メソッドで書かれていたルーティングを`resources`で書き換えましょう。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  resources :articles
end
```

ルーティングがどのように対応付けられているかを表示するには、`bin/rails routes`コマンドが使えます。

```bash
$ bin/rails routes
      Prefix Verb   URI Pattern                  Controller#Action
        root GET    /                            articles#index
    articles GET    /articles(.:format)          articles#index
 new_article GET    /articles/new(.:format)      articles#new
     article GET    /articles/:id(.:format)      articles#show
             POST   /articles(.:format)          articles#create
edit_article GET    /articles/:id/edit(.:format) articles#edit
             PATCH  /articles/:id(.:format)      articles#update
             DELETE /articles/:id(.:format)      articles#destroy
```

`resources`メソッドは、「URL」と「パスヘルパーメソッド」も設定します。パスヘルパーを使うことで、コードが特定のルーティング設定に依存することを避けられます。Prefix列の値の末尾には、パスヘルパーによって`_url`や`_path`といったサフィックスが追加されます。たとえば、記事を1件渡されると、`article_path`ヘルパーは`"/articles/#{article.id}"`を返します。このパスヘルパーを用いると、`app/views/articles/index.html.erb`のリンクを簡潔な形に書き直せます。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <a href="<%= article_path(article) %>">
        <%= article.title %>
      </a>
    </li>
  <% end %>
</ul>
```

しかし、[`link_to`](
https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to)ヘルパーを用いるとさらに便利になります。`link_to`ヘルパーの第1引数はリンクテキスト、第2引数はリンク先です。第2引数にモデルオブジェクトを渡すと、`link_to`が適切なパスヘルパーを呼び出してオブジェクトをパスに変換します。たとえば、`link_to`にarticleを渡すと`article_path`というパスヘルパーが呼び出されます。これを用いると、 `app/views/articles/index.html.erb`は以下のように書き換えられます。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <%= link_to article.title, article %>
    </li>
  <% end %>
</ul>
```

すっきりしましたね！

TIP: ルーティングについて詳しくは[Railsのルーティング](
routing.html)を参照してください。

### 記事を1件作成する

次はCRUDのC（Create）です。典型的なWebアプリケーションでは、リソースを1個作成するのに複数のステップを要します。最初にユーザーがフォーム画面をリクエストします。次にユーザーがそのフォームに入力して送信します。エラーが発生しなかった場合はリソースが作成され、リソース作成に成功したことを何らかの形で表示します。エラーが発生した場合はフォーム画面をエラーメッセージ付きで再表示し、フォーム送信の手順を繰り返すことになります。

Railsアプリケーションでは、これらのステップを実現するときに`new`アクションと`create`アクションを組み合わせて扱うのが慣例です。それでは2つのアクションを`app/controllers/articles_controller.rb`の`show`アクションの下に典型的な実装として追加してみましょう。

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

  def create
    @article = Article.new(title: "...", body: "...")

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end
end
```

`new`アクションは、新しい記事を1件インスタンス化しますが、データベースには保存しません。インスタンス化された記事は、ビューでフォームをビルドするときに使われます。`new`アクションを実行すると、`app/views/articles/new.html.erb`（この後作成します）がレンダリングされます。

`create`アクションは、タイトルと本文を持つ新しい記事をインスタンス化し、データベースへの保存を試みます。記事の保存に成功すると、その記事のページ（`"http://localhost:3000/articles/#{@article.id}"`）にリダイレクトします。記事の保存に失敗した場合は、`app/views/articles/new.html.erb`に戻ってフォームを再表示します。なお、このときの記事タイトルと本文にはダミーの値が使われます。これらはフォームが作成された後でユーザーが変更することになります。


NOTE: [`redirect_to`](https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_to)メソッドを使うとブラウザで新しいリクエストが発生しますが、[`render`](https://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render)メソッドは指定のビューを現在のリクエストとしてレンダリングします。ここで重要なのは、`redirect_to`メソッドはデータベースやアプリケーションのステートが変更された後で使うべきであるという点です。それ以外の場合に使うと、ユーザーがブラウザをリロードしたときに同じリクエストが再送信され、変更が重複してしまいます。

#### フォームビルダーを使う

ここではRailsの*フォームビルダー*（form builder）という機能を使います。フォームビルダーを使えば、最小限のコードを書くだけで設定がすべてできあがったフォームを表示でき、かつRailsの規約に沿うことができます。

それでは`app/views/articles/new.html.erb`を作成して以下のコードを書き込みましょう。

```html+erb
<h1>New Article</h1>

<%= form_with model: @article do |form| %>
  <div>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
  </div>

  <div>
    <%= form.label :body %><br>
    <%= form.text_area :body %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

[`form_with`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with)ヘルパーメソッドは、フォームビルダー（ここでは`form`）をインスタンス化します。`form_with`のブロック内でフォームビルダーの[`label`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-label)や[`text_field`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-text_field)といったメソッドを呼び出すと、適切なフォーム要素が出力されます。

`form_with`を呼び出したときの出力結果は以下のようになります。

```html
<form action="/articles" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="...">

  <div>
    <label for="article_title">Title</label><br>
    <input type="text" name="article[title]" id="article_title">
  </div>

  <div>
    <label for="article_body">Body</label><br>
    <textarea name="article[body]" id="article_body"></textarea>
  </div>

  <div>
    <input type="submit" name="commit" value="Create Article" data-disable-with="Create Article">
  </div>
</form>
```

TIP: フォームビルダーについて詳しくは、[Action View フォームヘルパー](
form_helpers.html)を参照してください。

#### Strong Parametersを使う

送信されたフォームのデータは`params`ハッシュに保存され、ルーティングパラメータも同様にキャプチャされます。つまり`create`アクションでは、`params[:article][:title]`を用いると送信された記事タイトルにアクセスでき、`params[:article][:body]`を用いると送信された記事本文にアクセスできます。こうした値を個別に`Article.new`に渡すことも一応可能ですが、値の数が増えれば増えるほどコードが煩雑になり、コーディング中のミスも増えます。

そこで、さまざまな値を個別に渡すのではなく、それらの値を含む1個のハッシュを渡すことにします。しかしその場合も、ハッシュ内にどのような値が許されているかを厳密に指定しなければなりません。これを怠ると、悪意のあるユーザーがブラウザ側でフィールドをこっそり追加して、機密データを上書きする可能性が生じるので危険です。ただし実際には、`params[:article]`をフィルタなしで`Article.new`に直接渡すと、Railsが`ForbiddenAttributesError`エラーを出してこの問題を警告するようになっています。そこで、Railsの*Strong Parameters*という機能を用いて`params`をフィルタすることにします。ここで言うstrongとは、`params`を[強く型付けする](https://en.wikipedia.org/wiki/Strong_and_weak_typing)（strong typing）とお考えください。

それでは、`app/controllers/articles_controller.rb`の末尾に `article_params`というprivateメソッドを追加し、`params`をフィルタしましょう。さらに、`create`アクションでこのメソッドを使うように変更します。

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

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
```

TIP: Strong Parametersについて詳しくは、[Action Controller の概要 §
Strong Parameters](action_controller_overview.html#strong-parameters)を参照してください。

#### バリデーションとエラーメッセージの表示

これまで見てきたように、リソースの作成は単独のステップではなく、複数のステップで構成されています。その中には、無効なユーザー入力を適切に処理することも含まれます。Railsには、無効なユーザー入力を処理するために*バリデーション*（validation: 検証）という機能が用意されています。バリデーションとは、モデルオブジェクトを保存する前に自動的にチェックするルールのことです。チェックに失敗した場合は保存を中止し、モデルオブジェクトの `errors` 属性に適切なエラーメッセージが追加されます。

それでは、`app/models/article.rb`モデルにバリデーションをいくつか追加してみましょう。

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

1個目のバリデーションは、「`title`の値が存在しなければならない」ことを宣言しています。`title`は文字列なので、`title`にはホワイトスペース（スペース文字、改行、Tabなど）以外の文字が1個以上含まれていなければならないという意味になります。

2個目のバリデーションも、「`body`の値が存在しなければならない」ことを宣言しています。さらに、`body`の値には文字が10個以上含まれていなければならないことも宣言しています。

NOTE: `title`属性や`body`属性がどこで定義されているかが気になる方へ: Active Recordは、テーブルのあらゆるカラムごとにモデル属性を自動的に定義するので、モデルファイル内でこれらの属性を宣言する必要はありません。

バリデーションを追加したので、今度は`app/views/articles/new.html.erb`を変更して`title`や`body`のエラーメッセージが表示されるようにしましょう。

```html+erb
<h1>New Article</h1>

<%= form_with model: @article do |form| %>
  <div>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
    <% @article.errors.full_messages_for(:title).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.label :body %><br>
    <%= form.text_area :body %><br>
    <% @article.errors.full_messages_for(:body).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

[`full_messages_for`](https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-full_messages_for)メソッドは、指定の属性に対応するわかりやすいエラーメッセージを含む配列を1個返します。その属性でエラーが発生していない場合、配列は空になります。

以上の追加がバリデーションでどのように動くかを理解するために、コントローラの`new`アクションと`create`アクションをもう一度見てみましょう。

```ruby
  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end
```

<http://localhost:3000/articles/new> をブラウザで表示すると、`GET /articles/new`リクエストは`new`アクションに対応付けられます。`new`アクションは`@article`を保存しないのでバリデーションは実行されず、エラーメッセージも表示されません。

このフォームを送信すると、`POST /articles`リクエストは`create`アクションに対応付けられます。`create`アクションは`@article`を*保存しようとする*ので、バリデーションは*実行されます*。バリデーションのいずれかが失敗すると、`@article`は保存されず、レンダリングされた`app/views/articles/new.html.erb`にエラーメッセージが表示されます。

TIP: バリデーションについて詳しくは、[Active Record バリデーション](
active_record_validations.html)を参照してください。バリデーションのエラーメッセージについては[Active Record バリデーション § バリデーションエラーに対応する](
active_record_validations.html#バリデーションエラーに対応する)を参照してください。

#### 仕上げ

これで、ブラウザで <http://localhost:3000/articles/new> を表示すると記事を1件作成できるようになりました。仕上げに、`app/views/articles/index.html.erb`ページの末尾からこの作成ページへのリンクを追加しましょう。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <%= link_to article.title, article %>
    </li>
  <% end %>
</ul>

<%= link_to "New Article", new_article_path %>
```

### 記事を更新する

ここまでで、CRUDのうちCとRを実現しました。今度はUの部分、つまり更新を実装してみましょう。リソースの更新は、ステップが複数あるという点でリソースの作成と非常に似ています。最初に、ユーザーはデータを編集するフォームをリクエストします。次に、ユーザーがフォームにデータを入力して送信します。エラーが発生しなければ、リソースは更新されます。エラーが発生した場合はフォームをエラーメッセージ付きで再表示し、再び同じことを繰り返します。

更新のステップは、コントローラの`edit`アクションと`update`アクションで扱う慣習になっています。それでは、`app/controllers/articles_controller.rb`の`create`アクションの下にこれらのアクションの典型的な実装を追加してみましょう。

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

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
```

更新に用いる`edit`アクションと`update`アクションが、作成に用いる`new`アクションと`create`に似ていることにご注目ください。

`edit`アクションはデータベースから記事を取得して`@article`に保存し、フォームを作成するときに使えるようにします。`edit`アクションは、デフォルトで`app/views/articles/edit.html.erb`をレンダリングします。

`update`アクションはデータベースから記事を（再）取得し、
`article_params`でフィルタリングされた送信済みのフォームデータで更新を試みます。
バリデーションが失敗せずに更新が成功した場合、ブラウザを更新後の記事ページにリダイレクトします。更新に失敗した場合は`app/views/articles/edit.html.erb`をレンダリングし、同じフォームをエラーメッセージ付きで再表示します。

#### ビューのコードをパーシャル共有する

`edit`で使うフォームは、`new`で使うフォームと同じように見えます。実は、Railsのフォームビルダーとリソースフルルーティングを活用すれば、フォームのコードも共通化できます。フォームビルダーは、モデルオブジェクトが既に保存されている場合は`edit`用のフォームを、モデルオブジェクトが保存されていない場合は`new`用のフォームを自動的に構成するので、状況に応じて適切なリクエストを行えます。

どちらのフォームにも同じコードが使われているので、*パーシャル*（partial: 部分テンプレートとも呼ばれます）と呼ばれる共有ビューにまとめることにします。以下の内容で `app/views/articles/_form.html.erb` を作成してみましょう。

```html+erb
<%= form_with model: article do |form| %>
  <div>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
    <% article.errors.full_messages_for(:title).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.label :body %><br>
    <%= form.text_area :body %><br>
    <% article.errors.full_messages_for(:body).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

上記のコードは`app/views/articles/new.html.erb`のフォームと同じですが、すべての`@article` が `article`に置き換えられている点にご注目ください。パーシャルのコードは共有されるので、特定のインスタンス変数に依存しないことがベストプラクティスです。コントローラのアクションで設定されるインスタンス変数に依存すると、他で使い回すときに不都合が生じます。そのため、記事をローカル変数としてパーシャルに渡しているのです。

`app/views/articles/new.html.erb` を更新して、[`render`]( https://api.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render) でパーシャルを使ってみましょう。

```html+erb
<h1>New Article</h1>

<%= render "form", article: @article %>
```

NOTE: パーシャルのファイル名の冒頭にはアンダースコア`_`を**必ず**付けなければなりません（例: `_form.html.erb`）。ただし、パーシャルを参照するときはアンダースコアを**付けません**（例: `render "form"`）。

続いて、`app/views/articles/edit.html.erb`も同じ要領で作ってみましょう。

```html+erb
<h1>Edit Article</h1>

<%= render "form", article: @article %>
```

TIP: パーシャルについて詳しくは、[レイアウトとレンダリング § パーシャルを使用する](layouts_and_rendering.html#パーシャルを使用する)を参照してください。

#### 仕上げ

これで、記事のeditページ（ <http://localhost:3000/articles/1/edit> など）にアクセスして記事を更新できるようになりました。最後に、`app/views/articles/show.html.erb` の下にeditページへのリンクを追加してみましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
</ul>
```

### 記事を削除する

いよいよCRUDのDまで到達しました。リソースの削除はリソースの作成や更新よりもシンプルなので、必要なのは削除用のルーティングとコントローラのアクションだけです。削除用のルーティングは、`DELETE /articles/:id`リクエストを`ArticlesController`の `destroy`アクションに対応付けます。

それでは、`app/controllers/articles_controller.rb`の`update`アクションの下に典型的な`destroy`アクションを追加してみましょう。

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

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to root_path
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
```

`destroy`アクションは、データベースから記事を取得して[`destroy`]( https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-destroy )メソッドを呼び出しています。続いてブラウザをrootパスにリダイレクトします。rootパスにリダイレクトすることに決めたのは、そこが記事へのメインのアクセスポイントだからです。しかし状況によっては、たとえば`articles_path`にリダイレクトするのもありです。

それでは、`app/views/articles/show.html.erb` の下部に削除用リンクを追加して、ページの記事を削除できるようにしましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article),
                  method: :delete,
                  data: { confirm: "Are you sure?" } %></li>
</ul>
```

上のコードでは、`link_to` にいくつか追加オプションを渡しています。`method: :delete`オプションを指定すると、リンクは`GET`リクエストではなく`DELETE`リクエストを送信します。`data: { confirm: "Are you sure?" }`オプションを指定すると、リンクをクリックしたときに「本当に削除して良いですか？」と確認するダイアログが表示されます。ユーザーがこのダイアログをキャンセルすると、リクエストは中止されます。これらのオプションはいずれも、*Unobtrusive JavaScript*（UJS: 控えめなJavaScript）と呼ばれるRailsの機能を利用しています。これらの振る舞いを実装したJavaScriptファイルは、最近のRailsアプリケーションにデフォルトで含まれています。

TIP: 控えめなJavaScriptについて詳しくは、[Rails で JavaScript を使用する](working_with_javascript_in_rails.html)を参照してください。

以上でできあがりです！記事のリスト表示も、作成も、更新も思いのままです。CRUDバンザイ！

モデルを追加する
---------------------

今度はアプリケーションに第2のモデルを追加しましょう。第2のモデルは記事へのコメントを扱います。

### 第2のモデルを追加する

先ほど`Article`モデルの作成に使ったのと同じジェネレーターを見てみましょう。今回は、`Article`モデルへの参照を保持する`Comment` モデルを作成します。ターミナルで以下のコマンドを実行します。

```bash
$ bin/rails generate model Comment commenter:string body:text article:references
```

コマンドを実行すると、以下の4つのファイルが作成されます。

| ファイル                                         | 目的                                                                                                |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| db/migrate/20140120201010_create_comments.rb | データベースにコメント用のテーブルを作成するためのマイグレーションファイル（ファイル名のタイムスタンプはこれとは異なります）|
| app/models/comment.rb                        | Commentモデル                                                                                      |
| test/models/comment_test.rb                  | Commentモデルをテストするためのハーネス                                                                 |
| test/fixtures/comments.yml                   |  テストで使うサンプルコメント                                                                     |

手始めに`app/models/comment.rb`を開いてみましょう。

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

Commentモデルの内容は、これまでに見た`Articleモデル`と非常によく似ています。違いは、Active Recordの*関連付け*（アソシエーション: association）を設定するための`belongs_to :article`という行がある点です。関連付けについて詳しくは、本ガイドの次のセクションで説明します。

bashコマンドで使われている`:references`キーワードは、モデルの特殊なデータ型を表します。 これは、指定されたモデル名の後ろに`_id`を追加した名前を持つ新しいカラムをデータベーステーブルに作成します。マイグレーションの実行後に`db/schema.rb`ファイルを調べてみると理解しやすいでしょう。

モデルのファイルの他に以下のようなマイグレーションファイルも生成されています。マイグレーションファイルは、モデルに対応するデータベーステーブルを生成するのに使います。

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
$ bin/rails db:migrate
```

Railsは、これまで実行されていないマイグレーションだけを適切に判定して実行するので、以下のようなメッセージだけが表示されるはずです。

```
==  CreateComments: migrating =================================================
-- create_table(:comments)
   -> 0.0115s
==  CreateComments: migrated (0.0119s) ========================================
```

### モデル同士を関連付ける

Active Recordの関連付け機能により、2つのモデルの間にリレーションシップを簡単に宣言することができます。今回の記事とコメントというモデルの場合、以下のいずれかの方法で関連付けを設定できます。

* 1件のコメントは1件の記事に属する（Each comment **belongs to** one article）。
* 1件の記事は複数のコメントを持てる（One article can **have many** comments）。

そして上の方法（における英語の記述）は、Railsで関連付けを宣言するときの文法と非常に似ています。`Comment`モデル（app/models/comment.rb）内のコードに既に書かれていたように、各コメントは1つの記事に属しています。

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

今度は、`Article`モデル（`app/models/article.rb`）を編集して、関連付けの他方にあるモデルを追加する必要があります。

```ruby
class Article < ApplicationRecord
  has_many :comments

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

2つのモデルで行われているこれらの宣言によって、さまざまな動作が自動化されます。たとえば、`@article`というインスタンス変数に記事が1件含まれていれば、`@article.comments`と書くだけでその記事に関連付けられているコメントをすべて取得できます。

TIP: Active Recordの関連付けについて詳しくは、[Active Recordの関連付け](association_basics.html)ガイドを参照してください。

### コメントへのルーティングを追加する

articlesコントローラで行ったときと同様、`comments`を参照するためにRailsが認識すべきルーティングを追加する必要があります。再び`config/routes.rb`ファイルを開き、以下のように変更してください。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  resources :articles do
    resources :comments
  end
end
```

この設定により、`articles`の内側に*ネストされたリソース*（nested resouce）として`comments`が作成されます。これは、モデルの記述とは別の視点から、記事とコメントの間のリレーションシップを階層的に捉えたものです。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)ガイドを参照してください。

### コントローラを生成する

モデルを手作りしたのですから、それに合ったコントローラも作ってみたくなります。それでは、再びこれまでと同様にジェネレータを使ってみましょう。

```bash
$ bin/rails generate controller Comments
```

上のコマンドを実行すると、4つのファイルと1つの空ディレクトリが作成されます。

ファイル/ディレクトリ | 目的
--- | ---
app/controllers/comments_controller.rb | コメント用コントローラ
app/views/comments/ | このコントローラのビューはここに置かれる
test/controllers/comments_controller_test.rb | このコントローラのテスト用ファイル
app/helpers/comments_helper.rb | ビューヘルパー
app/assets/stylesheets/comment.scss | このコントローラ用のCSS（カスケーディングスタイルシート）ファイル

一般的なブログと同様、このブログの記事を読んだ人はそこに直接コメントを追加したくなるでしょう。そしてコメントを追加後に元の記事表示ページに戻り、コメントがそこに反映されていることを確認したいはずです。そこで、`CommentsController`を用いてコメントを作成したり、スパムコメントが書き込まれたら削除できるようにしたいと思います。

そこで最初に、Articleのshowテンプレート（`app/views/articles/show.html.erb`）を改造して新規コメントを作成できるようにしましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article),
                  method: :delete,
                  data: { confirm: "Are you sure?" } %></li>
</ul>

<h2>Add a comment:</h2>
<%= form_with model: [ @article, @article.comments.build ] do |form| %>
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

上のコードでは、`Article`のshowページにフォームが1つ追加されています。このフォームは`CommentsController`の`create`アクションを呼び出すことでコメントを新規作成します。`form_with`呼び出しでは配列を1つ渡しています。これは`/articles/1/comments`のような「ネストしたルーティング（nested route）」を生成します。

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

上のコードは、Articleコントローラのコードを書いていたときよりも少々複雑に見えます。これはネストを使ったことによって複雑さが増したのです。コメント関連のリクエストでは、コメントが追加される先の記事がどれであったかを追えるようにしておく必要があります。そこで、`Article`モデルの`find`メソッドを最初に呼び出し、リクエストで言及されている記事（のオブジェクト）を取得して`@article`に保存しています。

さらにこのコードでは、関連付けによって使えるようになったメソッドをいくつも利用しています。`@article.comments`に対して`create`メソッドを実行することで、コメントの作成と保存を同時に行っています（訳注: `build`メソッドにすれば作成のみで保存は行いません）。この方法でコメントを作成すると、コメントと記事が自動的にリンクされ、指定された記事に対してコメントが従属するようになります。

新しいコメントの作成が完了したら、`article_path(@article)`ヘルパーを用いて元の記事の画面に戻ります。既に説明したように、このヘルパーを呼び出すと`ArticlesController`の`show`アクションが呼び出され、`show.html.erb`テンプレートがレンダリングされます。この画面にコメントを表示できるようにしたいので、`app/views/articles/show.html.erb`に以下のコードを追加しましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article),
                  method: :delete,
                  data: { confirm: "Are you sure?" } %></li>
</ul>

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
<%= form_with model: [ @article, @article.comments.build ] do |form| %>
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

以上で、ブログに記事やコメントを自由に追加して、それらを正しい場所に表示できるようになりました。

![記事にコメントが追加されたところ](images/getting_started/article_with_comments.png)

## リファクタリング

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
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article),
                  method: :delete,
                  data: { confirm: "Are you sure?" } %></li>
</ul>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= render 'comments/form' %>
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
  <strong>Body:</strong>
  <%= @article.body %>
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

### concernを使う

Railsの「concern（関心事）」とは、大規模なコントローラやモデルの理解や管理を容易にする手法のひとつです。複数のモデル（またはコントローラ）が同じ関心を共有していれば、concernを介して再利用できるというメリットもあります。concernはRubyの「モジュール」で実装され、モデルやコントローラが担当する機能のうち明確に定義された部分を表すメソッドをそのモジュールに含めます。なおモジュールは他の言語では「ミックスイン」と呼ばれることもよくあります。

concernは、コントローラやモデルで普通のモジュールと同じように使えます。`rails new blog` でアプリを作成すると、`app/`内に以下の2つのconcernsフォルダも作成されます。

```
app/controllers/concerns
app/models/concerns
```

1件のブログ記事はさまざまなステータスを持つ可能性があります。たとえば記事の可視性について「誰でも見てよい（`public`）」「著者だけに見せる（`private`）」というステータスを持つかもしれませんし、「復旧可能な形で記事を非表示にする（`archived`）」ことも考えられます。コメントについても同様に可視性やアーカイブを設定することもあるでしょう。こうしたステータスを表す方法のひとつとして、モデルごとに`status`カラムを持たせるとしましょう。

マイグレーションを実行して`status`カラムを追加した後で、`Article`モデルに以下を追加します。

```ruby
class Article < ApplicationRecord
  has_many :comments

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }

  VALID_STATUSES = ['public', 'private', 'archived']

  validates :status, inclusion: { in: VALID_STATUSES }

  def archived?
    status == 'archived'
  end
end
```

`Comment`モデルにも以下を追加します。

```ruby
class Comment < ApplicationRecord
  belongs_to :article

  VALID_STATUSES = ['public', 'private', 'archived']

  validates :status, inclusion: { in: VALID_STATUSES }

  def archived?
    status == 'archived'
  end
end
```

次に`index`アクションに対応する`app/views/articles/index.html.erb`テンプレートで以下のように`archived?`メソッドを追加し、アーカイブ済みの記事を表示しないようにします。

```html+erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <% unless article.archived? %>
      <li>
        <%= link_to article.title, article %>
      </li>
    <% end %>
  <% end %>
</ul>

<%= link_to "New Article", new_article_path %>
```

しかし、2つのモデルのコードを見返してみると、ロジックが重複していることがわかります。このままでは、今後ブログにプライベートメッセージ機能などを追加するとロジックがまたしても重複してしまうでしょう。concernは、このような重複を避けるのに便利です。

1つのconcernは、モデルの責務の「一部」についてのみ責任を負います。この例の場合、「関心」の対象となるメソッドはすべてモデルの可視性に関連しているので。新しいconcern（すなわちモジュール）を`Visible`と呼ぶことにしましょう。`app/models/concerns`ディレクトリの下に`visible.rb`という新しいファイルを作成し、複数のモデルで重複していたステータス関連のすべてのメソッドをそこに移動させます。

`app/models/concerns/visible.rb`

```ruby
module Visible
  def archived?
    status == 'archived'
  end
end
```

ステータスをバリデーションするメソッドもconcernにまとめられますが、バリデーションメソッドはクラスレベルで呼び出されるので少々複雑になります。APIドキュメントの[`ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)には、以下のようにバリデーションをシンプルに`include`する方法が紹介されています。

```ruby
module Visible
  extend ActiveSupport::Concern

  VALID_STATUSES = ['public', 'private', 'archived']

  included do
    validates :status, inclusion: { in: VALID_STATUSES }
  end

  def archived?
    status == 'archived'
  end
end
```

これで各モデルで重複しているロジックを取り除けるようになったので、新たに`Visible`モジュールを`include`しましょう。


`app/models/article.rb`を以下のように変更します。

```ruby
class Article < ApplicationRecord
  include Visible
  has_many :comments

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

`app/models/comment.rb`も以下のように変更します。

```ruby
class Comment < ApplicationRecord
  include Visible
  belongs_to :article
end
```

concernにはクラスメソッドも追加できます。たとえば、ステータスがpublicの記事（またはコメント）の件数をメインページに表示したい場合は、`Visible`モジュールに以下の要領でクラスメソッドを追加します。

```ruby
module Visible
  extend ActiveSupport::Concern

  VALID_STATUSES = ['public', 'private', 'archived']

  included do
    validates :status, inclusion: { in: VALID_STATUSES }
  end

  class_methods do
    def public_count
      where(status: 'public').count
    end
  end

  def archived?
    status == 'archived'
  end
end
```

これで、以下のようにビューで任意のクラスメソッドを呼べるようになります。

```html+erb
<h1>Articles</h1>

Our blog has <%= Article.public_count %> articles and counting!

<ul>
  <% @articles.each do |article| %>
    <li>
      <%= link_to article.title, article %>
    </li>
  <% end %>
</ul>

<%= link_to "New Article", new_article_path %>
```

アプリケーションに追加した`status`カラムを使うには、もう少し手を加える必要があります。最初に、以下のマイグレーションを実行して`Articles`モデルと`Comments`モデルに`status`カラムを追加します。

```bash
$ bin/rails generate migration AddStatusToArticles status:string
$ bin/rails generate migration AddStatusToComments status:string
```

TIP: マイグレーションについて詳しくは、[Active Record マイグレーション](
active_record_migrations.html)を参照してください。

次に、Strong Parametersで`:status`キーの許可も追加しておく必要もあります。`app/controllers/articles_controller.rb`を以下のように変更します。

```ruby
private
    def article_params
      params.require(:article).permit(:title, :body, :status)
    end
```

`app/controllers/comments_controller.rb`も以下のように変更します。

```ruby
private
    def comment_params
      params.require(:comment).permit(:commenter, :body, :status)
    end
```

最後に、フォームにセレクトボックスを追加して、ユーザーが記事を作成したりコメントを投稿したりするときにステータスを選択できるようにします。デフォルトのステータスを`public`と指定することもできます。`app/views/articles/_form.html.erb`に以下を追加します。

```html+erb
<div>
  <%= form.label :status %><br>
  <%= form.select :status, ['public', 'private', 'archived'], selected: 'public' %>
</div>
```

`app/views/comments/_form.html.erb`にも以下を追加します。

```html+erb
<p>
  <%= form.label :status %><br>
  <%= form.select :status, ['public', 'private', 'archived'], selected: 'public' %>
</p>
```

## コメントを削除する

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
              data: { confirm: "Are you sure?" } %>
</p>
```

この新しい「Destroy Comment」リンクをクリックすると、`DELETE /articles/:article_id/comments/:id`というリクエストが`CommentsController`に送信されます。コントローラはそれを受け取って、どのコメントを削除すべきかを検索することになります。それではコントローラ（`app/controllers/comments_controller.rb`）に`destroy`アクションを追加しましょう。

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
      params.require(:comment).permit(:commenter, :body, :status)
    end
end
```

`destroy`アクションでは、まずどの記事が対象であるかを検索して`@article`に保存し、続いて`@article.comments`コレクションの中のどのコメントが対象であるかを特定して`@comment`に保存します。そしてそのコメントをデータベースから削除し、終わったら記事の`show`アクションに戻ります。

### 関連付けられたオブジェクトも削除する

ある記事を削除したら、その記事に関連付けられているコメントも一緒に削除する必要があります。そうしないと、コメントがいつまでもデータベース上に残ってしまいます。Railsでは関連付けに`dependent`オプションを指定することでこれを実現しています。Articleモデル`app/models/article.rb`を以下のように変更しましょう。

```ruby
class Article < ApplicationRecord
  include Visible

  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

## セキュリティ

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

  #（以下省略）
```

コメントの削除も認証済みユーザーにだけ許可したいので、`CommentsController`（`app/controllers/comments_controller.rb`）に以下のように追記しましょう。

```ruby
class CommentsController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    # ...
  end

  #（以下省略）
```

ここで記事を新規作成しようとすると、以下のようなBASIC http認証ダイアログが表示されます。

![Basic HTTP Authentication Challenge](images/getting_started/challenge.png)

もちろん、Railsでは他の認証方法も使えます。Railsにはさまざまな認証システムがありますが、その中で人気が高い認証システムは[Devise](https://github.com/plataformatec/devise)と[Authlogic](https://github.com/binarylogic/authlogic) gemの2つです。

### その他のセキュリティ対策

セキュリティ、それもWebアプリケーションのセキュリティは非常に幅広く、かつ詳細に渡っています。Railsアプリケーションのセキュリティについて詳しくは、本ガイドの[Railsセキュリティガイド](security.html)を参照してください。

## 次に学ぶべきこと

以上で、Railsアプリケーションを初めて作るという試みは終わりです。この後は自由に更新したり実験を重ねたりできます。

もちろん、何の助けもなしにWebアプリケーションを作らなければならないなどということはないということを忘れてはなりません。RailsでWebアプリを立ち上げたり実行したりするうえで助けが必要になったら、以下のサポート用リソースを自由に参照できます。

- [Ruby on Railsガイド](/) (本サイトです)
- [Ruby on Railsメーリングリスト](https://discuss.rubyonrails.org/c/rubyonrails-talk) (英語)
- [freenode](https://freenode.net/)上にある[#rubyonrails](irc://irc.freenode.net/#rubyonrails)チャンネル (英語)

## 設定の落とし穴

Railsでの無用なトラブルを避けるための最も初歩的なコツは、外部データを常にUTF-8で保存しておくことです。このとおりにしないと、RubyライブラリやRailsはネイティブデータをたびたびUTF-8に変換しなければならず、しかも場合によっては失敗します。外部データを常にUTF-8にしておくことをぜひお勧めします。

外部データのエンコードが不統一な場合によく起きる症状としては、たとえば画面に黒い菱型◆や疑問符が表示されるというものがあります。他にも、"ü"という文字のはずが"Ã¼"という文字に変わっている、などの症状もあります。Railsではこうした問題を緩和するため、問題の原因を自動的に検出して修正するために内部で多くの手順を行っています。しかし、UTF-8で保存されていない外部データがあると、Railsによる自動検出/修正が効かずに文字化けが発生することがあります。

UTF-8でないデータの主な原因は以下の2つです。

- テキストエディタ: TextMateを含む多くのテキストエディタは、デフォルトでUTF-8エンコードでテキストを保存します。使っているテキストエディタがこのようになっていない場合、テンプレートを表示する時にéなどの特殊文字が◆?のような感じでブラウザで表示されることがあります。これはi18n（国際化）用の翻訳ファイルで発生することもあります。一部のDreamweaverのようにUTF-8保存がデフォルトでないエディタであっても、デフォルトをUTF-8に変更する方法は用意されているはずです。エンコードはUTF-8に変えてください。
- データベース: Railsはデータベースから読みだしたデータを境界上でUTF-8に変換します。しかし、使っているデータベースの内部エンコード設定がUTF-8になっていない場合、UTF-8の文字の一部をデータベースにそのまま保存できないことがあります。たとえばデータベースの内部エンコードがLatin-1になっていると、ロシア語・ヘブライ語・日本語などの文字をデータベースに保存したときにこれらの情報は永久に失われてしまいます。できるかぎり、データベースの内部エンコードはUTF-8にしておいてください。
