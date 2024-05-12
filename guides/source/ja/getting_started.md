Rails をはじめよう
============

このガイドでは、Ruby on Rails（以下 Rails）を初めて設定して実行するまでを解説します。

このガイドの内容:

- Railsのインストール方法、新しいRailsアプリケーションの作成方法、アプリケーションからデータベースへの接続方法
- Railsアプリケーションの一般的なレイアウト
- MVC（モデル・ビュー・コントローラ）およびRESTful設計の基礎
- Railsアプリケーションで使うパーツを手軽に生成する方法

--------------------------------------------------------------------------------

## 本ガイドの前提条件

本ガイドは、Railsアプリケーションを構築したいと考えているRails初心者を対象にしています。読者にRailsの経験があることは前提としていません。

Railsとは、プログラミング言語「Ruby」の上で動作する[Webアプリケーションフレームワーク](https://ja.wikipedia.org/wiki/Webアプリケーションフレームワーク)です。ただしプログラミング経験がまったくない人がいきなりRailsを学ぼうとすると、かなり大変な作業になるでしょう。オンラインで学べる洗練されたコンテンツはたくさんあるので、その中から以下をご紹介します。

- [プログラミング言語Ruby公式Webサイト](https://www.ruby-lang.org/ja/documentation/)
- [プログラミング学習コンテンツまとめ](https://github.com/EbookFoundation/free-programming-books/blob/master/books/free-programming-books-ja.md#ruby)

いずれもよくできていますが中には古いものもあり、たとえば通常のRails開発で見かけるような最新の構文がカバーされていない可能性もあります。

TIP: 訳注：Railsガイドでは開発経験者が早くキャッチアップできるよう、いくつかの用語説明などを省略しています。読んでいて「難しい」と感じた場合は[Railsチュートリアル](https://railstutorial.jp/)からお読みください。

## Railsとは何か

Railsとは、プログラミング言語「Ruby」で書かれたWebアプリケーションフレームワークです。Railsは、あらゆる開発者がWebアプリケーション開発で必要となる作業やリソースを事前に想定することで、Webアプリケーションをより手軽に開発できるように設計されています。他の多くのWebアプリケーションフレームワークと比較して、アプリケーションを開発する際のコード量がより少なくて済むにもかかわらず、より多くの機能を実現できます。ベテラン開発者の多くが「RailsのおかげでWebアプリケーション開発がとても楽しくなった」と述べています。

Railsは「最善の開発方法は1つである」という、ある意味大胆な判断に基いて設計されています。何かを行うための最善の方法を1つ仮定して、それに沿った開発を全面的に支援します。言い換えれば、Railsで仮定されていない別の開発手法は行いにくくなります。この「Rails Way」、すなわち「Railsというレールに乗って開発する」手法を学んだ人は、開発の生産性が驚くほど向上することに気付くでしょう。逆に、レールに乗らずに従来の開発手法にこだわると、開発の楽しさが減ってしまうかもしれません。

Railsの哲学には、以下の2つの主要な基本理念があります。

- **繰り返しを避けよ（Don't Repeat Yourself: DRY）:** DRYはソフトウェア開発上の原則であり、「システムを構成する知識のあらゆる部品は、常に単一であり、明確であり、信頼できる形で表現されていなければならない」というものです。同じコードを繰り返し書くことを徹底的に避けることで、コードが保守しやすくなり、容易に拡張できるようになり、バグも減らせます。
- **設定より規約が優先（Convention Over Configuration）:** Railsでは、Webアプリケーションの機能を実現する最善の方法が明確に示されており、Webアプリケーションの各種設定についても従来の経験や慣習を元に、それらのデフォルト値を定めています。デフォルト値が決まっているおかげで、開発者の意見をすべて取り入れようとした自由過ぎるWebアプリケーションのように、開発者が大量の設定ファイルを設定せずに済みます。

## Railsプロジェクトを新規作成する

本ガイドを最大限に活用するには、以下の手順を1つずつすべて実行するのがベストです。どの手順もサンプルアプリケーションを動かすのに必要なものであり、それ以外のコードや手順は不要です。

本ガイドの手順に沿って作業すれば、`blog`という名前の非常にシンプルなブログのRailsプロジェクトを作成できます。Railsアプリケーションを構築する前に、Rails本体をインストールしておいてください。

TIP: 以下の例では、Unix系OSのプロンプトとして`$`記号が使われていますが、プロンプトはカスタマイズ可能なので環境によって異なることもあります。Windowsでは`c:\source_code>`のように表示されます。

### Railsのインストール

Railsをインストールする前に、必要な要件が自分のシステムで満たされているかどうかをチェックしましょう。少なくとも以下のソフトウェアが必要です。

* Ruby
* SQLite3

TIP: 訳注：GitHubが提供するクラウド開発環境『[Codespaces](https://github.co.jp/features/codespaces)』には、[公式のRuby on Railsテンプレート](https://github.com/codespaces/templates)が用意されています。`Use this template`ボタンから、ワンクリックでRailsを動かせるクラウド開発環境が手に入ります。（参考: [GitHub Codespaces を利用する - Rails Girls](https://railsgirls.jp/install/codespaces)）

#### Rubyをインストールする

ターミナル（コマンドプロンプトとも言います）ウィンドウを開いてください。macOSの場合、ターミナル（Terminal.app）という名前のアプリケーションを実行します。Windowsの場合は[スタート]メニューから[ファイル名を指定して実行]をクリックして'cmd.exe'と入力します。`$`で始まる記述はコマンド行なので、これらをコマンドラインに入力して実行します。次に以下を実行して、現在インストールされているRubyが最新バージョンであることを確認しましょう。

```bash
$ ruby -v
ruby 3.0.1
```

RailsではRubyバージョン2.7.0以降が必須です。これより低いバージョン（2.3.7や1.8.7など）が表示された場合は、新たにRubyをインストールする必要があります。

RailsをWindowsにインストールする場合は、最初に[Ruby Installer](https://rubyinstaller.org/)をインストールしておく必要があります。

OS環境ごとのインストール方法について詳しくは、[ruby-lang.org](https://www.ruby-lang.org/ja/documentation/installation/)を参照してください。

#### SQLite3をインストールする

SQLite3データベースのインストールも必要です。
多くのUnix系OSには実用的なバージョンのSQLite3が同梱されています。Windowsの場合は、上述のRails InstalerでRailsをインストールするとSQLite3もインストールされます。その他の環境については[SQLite3](https://www.sqlite.org)のインストール方法を参照してください。

```bash
$ sqlite3 --version
```

上を実行することでSQLite3のバージョンを確認できます。

#### Railsをインストールする

Railsをインストールするには、`gem install`コマンドを実行します。このコマンドはRubyGemsによって提供されます。

```bash
$ gem install rails
```

以下のコマンドを実行することで、すべて正常にインストールできたかどうかを確認できます。

```bash
$ rails --version
Rails 7.1.0
```

"Rails 7.1.0"などのバージョンが表示されたら、次に進みましょう。

### ブログアプリケーションを作成する

Railsには、ジェネレータというスクリプトが多数付属していて、特定のタスクを開始するために必要なものを自動的に生成してくれるので、楽に開発できます。その中から、新規アプリケーション作成用のジェネレータを使ってみましょう。ジェネレータを実行すればRailsアプリケーションの基本的なパーツが提供されるので、開発者が自分でこれらを作成する必要はありません。

ジェネレータを実行するには、ターミナルを開き、Railsファイルを作成したいディレクトリに移動して、以下を入力します。

```bash
$ rails new blog
```

これにより、Blogという名前のRails アプリケーションが`blog`ディレクトリに作成され、`Gemfile`というファイルで指定されているgemファイルが`bundle install`コマンドによってインストールされます。

TIP: `rails new --help`を実行すると、Railsアプリケーションビルダで使えるすべてのコマンドラインオプションを表示できます。

ブログアプリケーションを作成したら、そのフォルダ内に移動します。

```bash
$ cd blog
```

`blog`ディレクトリの下には多数のファイルやフォルダが生成されており、これらがRailsアプリケーションを構成しています。このガイドではほとんどの作業を`app`ディレクトリで行いますが、Railsが生成したファイルとフォルダについてここで簡単に説明しておきます。

| ファイル/フォルダ | 目的 |
| ----------- | ------- |
|app/|このディレクトリには、アプリケーションのコントローラ、モデル、ビュー、ヘルパー、メーラー、チャンネル、ジョブ、そしてアセットが置かれます。以後、本ガイドでは基本的にこのディレクトリを中心に説明を行います。|
|bin/|このディレクトリには、アプリケーションを起動する`rails`スクリプトが置かれます。セットアップ・アップデート・デプロイに使うスクリプトファイルもここに置けます。
|config/|このディレクトリには、アプリケーションの各種設定ファイル（ルーティング、データベースなど）が置かれます。詳しくは[Rails アプリケーションの設定項目](configuring.html) を参照してください。|
|config.ru|アプリケーションの起動に使われるRackベースのサーバー用のRack設定ファイルです。Rackについて詳しくは、[RackのWebサイト](https://rack.github.io/)を参照してください。|
|db/|このディレクトリには、現在のデータベーススキーマと、データベースマイグレーションファイルが置かれます。|
|Dockerfile|Dockerの設定ファイルです。|
|Gemfile<br>Gemfile.lock|これらのファイルは、Railsアプリケーションで必要となるgemの依存関係を記述します。この2つのファイルはBundler gemで使われます。Bundlerについて詳しくは[BundlerのWebサイト](https://bundler.io/)を参照してください。|
|lib/|このディレクトリには、アプリケーションで使う拡張モジュールが置かれます。|
|log/|このディレクトリには、アプリケーションのログファイルが置かれます。|
|public/|静的なファイルやコンパイル済みアセットはここに置きます。このディレクトリにあるファイルは、外部（インターネット）にそのまま公開されます。|
|Rakefile|このファイルは、コマンドラインから実行できるタスクを探索して読み込みます。このタスク定義は、Rails全体のコンポーネントに対して定義されます。独自のRakeタスクを定義したい場合は、`Rakefile`に直接書くと権限が強すぎるので、なるべく`lib/tasks`フォルダの下にRake用のファイルを追加してください。|
|README.md|アプリケーションの概要を簡潔に説明するマニュアルをここに記入します。このファイルにはアプリケーションの設定方法などを記入し、これさえ読めば誰でもアプリケーションを構築できるようにしておきましょう。|
|storage/|このディレクトリには、Disk Serviceで用いるActive Storageファイルが置かれます。詳しくは[Active Storageの概要](active_storage_overview.html)を参照してください。|
|test/|このディレクトリには、単体テストやフィクスチャなどのテスト関連ファイルを置きます。テストについて詳しくは[Railsアプリケーションをテストする](testing.html)を参照してください。|
|tmp/|このディレクトリには、キャッシュやpidなどの一時ファイルが置かれます。|
|vendor/|サードパーティ製コードはすべてこのディレクトリに置きます。通常のRailsアプリケーションの場合、外部のgemファイルがここに置かれます。|
|.dockerignore|コンテナにコピーすべきでないファイルをDockerに指示するのに使うファイルです。|
|.gitattributes|このファイルは、gitリポジトリ内の特定のパスについてメタデータを定義します。このメタデータは、gitや他のツールで振る舞いを拡張できます。詳しくは[gitattributesドキュメント](https://git-scm.com/docs/gitattributes)を参照してください。|
|.gitignore|Gitに登録しないファイル（またはパターン）をこのファイルで指定します。Gitにファイルを登録しない方法について詳しくは[GitHub - Ignoring files](https://help.github.com/articles/ignoring-files)を参照してください。|
|.ruby-version|このファイルには、デフォルトのRubyバージョンが記述されています。|

## Hello, Rails!

手始めに、画面に何かテキストを表示してみましょう。そのためには、Railsアプリケーションサーバーを起動しなくてはなりません。

### Webサーバーを起動する

先ほど作成したRailsアプリケーションは、既に実行可能な状態になっています。Webアプリケーションを開発用のPCで実際に動かしてこのことを確かめてみましょう。`blog`ディレクトリに移動し、以下のコマンドを実行します。

```bash
$ bin/rails server
```

TIP: Windowsの場合は、`bin`フォルダの下にあるスクリプトをRubyインタープリタに直接渡さなければなりません（例: `ruby bin\rails server`）

TIP: JavaScriptアセットの圧縮にはJavaScriptランタイムが必要です。JavaScriptランタイムが環境にない場合は、起動時に`execjs`エラーが発生します。macOSやWindowsにはJavaScriptランタイムが同梱されています。`therubyrhino`はJRubyユーザー向けに推奨されているランタイムであり、JRuby環境下ではデフォルトでアプリケーションの`Gemfile`に追加されます。サポートされているランタイムについて詳しくは[ExecJS](https://github.com/sstephenson/execjs#readme)を参照してください。

Railsで起動されるWebサーバーは、Railsにデフォルトで付属している[Puma](http://puma.io/)です。Webアプリケーションが実際に動作しているところを確認するには、ブラウザを開いて [http://localhost:3000](http://localhost:3000) を表示してください。以下のようなRailsのデフォルト情報ページが表示されます。

![Rails起動ページのスクリーンショット](images/getting_started/rails_welcome.png)

Webサーバーを停止するには、実行されているターミナルのウィンドウでCtrl + Cキーを押します。なお、development環境ではファイルに変更を加えればサーバーが自動的に変更を反映するので、サーバーの再起動は通常は不要です。

Railsの起動ページは、新しいRailsアプリケーションの「スモークテスト」として使えます。このページが表示されれば、サーバーが正常に動作していることが確認できます。

### Railsで「Hello」と表示する

Railsで「Hello」と表示するには、少なくとも「**ルーティング**」「**コントローラ**」「**ビュー**」が必要です。ルーティングは、リクエストをどのコントローラに振り分けるかを決定します。コントローラは、アプリケーションに対する特定のリクエストを受け取って処理します。コントローラの *アクション* は、リクエストを扱うのに必要な処理を実行します。ビューは、データを好みの書式で表示します。

実装の面から見れば、ルーティングはRubyの[DSL（Domain-Specific Language）](https://ja.wikipedia.org/wiki/ドメイン固有言語) で記述されたルールです。コントローラはRubyのクラスで、そのクラスのpublicメソッドがアクションです。ビューはテンプレートで、多くの場合HTMLの中にRubyコードも含んでいます。

それではルーティングを1個追加してみましょう。`config/routes.rb`を開き、`Rails.application.routes.draw`ブロックの冒頭に以下を書きます。

```ruby
Rails.application.routes.draw do
  get "/articles", to: "articles#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # ...
end
```

上で宣言したルーティングは、`GET /articles`リクエストを`ArticlesController`の`index`アクションに対応付けます。

`ArticlesController`と`index`アクションを作成するには、コントローラ用のジェネレータを実行します（上で既に適切なルーティングを追加したので、ここでは`--skip-routes`オプションでルーティングの追加をスキップします）。


```bash
$ bin/rails generate controller Articles index --skip-routes
```

これで、必要なファイルをRailsが生成します。

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
```

この中で最も重要なのは、`app/controllers/articles_controller.rb`というコントローラファイルです。このファイルを見てみましょう。

```ruby
class ArticlesController < ApplicationController
  def index
  end
end
```

`index`アクションは空です。あるアクションがビューを明示的にレンダリングしない場合（またはHTTPレスポンスをトリガーしない場合）、Railsはその「コントローラ名」と「アクション名」にマッチするビューを自動的にレンダリングします。これは「設定より規約」の例です。ビューは`app/views`の下に配置されるので、`index`アクションはデフォルトで`app/views/articles/index.html.erb`をレンダリングします。

それでは`app/views/articles/index.html.erb`を開き、中身を以下に置き換えましょう。

```html
<h1>Hello, Rails!</h1>
```

コントローラ用のジェネレータを実行するためにWebサーバーを停止していた場合は、再び`bin/rails server`を実行します。ブラウザで<http://localhost:3000/articles>を開くと、「Hello, Rails!」というテキストが表示されます。

### アプリケーションのHomeページを設定する

この時点ではトップページ<http://localhost:3000>にまだRailsのデフォルト起動画面が表示されているので、<http://localhost:3000>を開いたときにも「Hello, Rails!」が表示されるようにしてみましょう。これを行うには、アプリケーションのrootパスをこのコントローラとアクションに対応付けます。

それでは`config/routes.rb`を開き、`Rails.application.routes.draw`ブロックを以下のように書き換えてみましょう。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  get "/articles", to: "articles#index"
end
```

ブラウザで<http://localhost:3000>を開くと、「Hello, Rails!」テキストが表示されるはずです。これで、`root`ルーティングが`ArticlesController`の`index`アクションに対応付けられたことを確認できました。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)を参照してください。

自動読み込み
-----------

Railsアプリケーションでは、アプリケーションコードを読み込むのに`require`を書く必要は**ありません**。

おそらくお気づきかもしれませんが、`ArticlesController`は`ApplicationController`を継承しているにもかかわらず、`app/controllers/articles_controller.rb`には以下のような記述がどこにもありません。

```ruby
require "application_controller" # 実際には書いてはいけません
```

Railsでは、アプリケーションのクラスやモジュールはどこでも利用できるようになっているので、上のように`require`を書く必要はありませんし、`app/`ディレクトリの下で何かを読み込むために`require`を**書いてはいけません**。この機能は「**自動読み込み**（autoloading: オートロード）」と呼ばれています。詳しくはガイドの『[Railsの自動読み込みと再読み込み](/autoloading_and_reloading_constants.html)』を参照してください。

`require`を書く必要があるのは、以下の2つの場合だけです。

* `lib/`ディレクトリの下にあるファイルを読み込む場合
* `Gemfile`で`require: false`が指定されているgem依存を読み込む場合

MVCを理解する
-----------

これまでに、「ルーティング」「コントローラ」「アクション」「ビュー」について解説しました。これらは[MVC（Model-View-Controller）](https://ja.wikipedia.org/wiki/Model_View_Controller)と呼ばれるパターンに沿ったWebアプリケーションの典型的な構成要素です。MVCは、アプリケーションの責務を分割して理解しやすくするデザインパターンです。Railsは、このデザインパターンに従う規約になっています。

コントローラと、それに対応して動作するビューを作成したので、次の構成要素である「モデル」を生成しましょう。

### モデルを生成する

**モデル**（model）とは、データを表現するためのRubyクラスです。モデルは、**Active Record**と呼ばれるRailsの機能を介して、アプリケーションのデータベースとやりとりできます。

モデルを定義するには、以下のようにモデル用のジェネレータを実行します。

```bash
$ bin/rails generate model Article title:string body:text
```

NOTE: モデル名は常に英語の「**単数形**」で表記してください。理由は、インスタンス化されたモデルは1件のデータレコードを表すからです。この規約を覚えるために、モデルのコンストラクタを呼び出すときに`Article.new(...)`と単数形で書くことはあっても、複数形の`Articles.new(...)`は**書かない**ことを考えてみるとよいでしょう。

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

**マイグレーション**（migration）は、アプリケーションのデータベース構造を変更するときに使われる機能です。RailsアプリケーションのマイグレーションはRubyコードで記述するので、データベースの種類を問わずにマイグレーションを実行できます。

`db/migrate/`ディレクトリの下に生成されたマイグレーションファイルを開いてみましょう。

```ruby
class CreateArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body

      t.timestamps
    end
  end
end
```

`create_table`メソッド呼び出しは、`articles`テーブルの構成方法を指定します。`create_table`メソッドは、デフォルトで`id`カラムを「オートインクリメントの主キー」として追加します。つまり、テーブルで最初のレコードの`id`は1、次のレコードの`id`は2、というように自動的に増加します。

`create_table`のブロック内には、`title`と`body`という2つのカラムが定義されています。これらのカラムは、先ほど実行した`bin/rails generate model Article title:string body:text`コマンドで指定したので、ジェネレータによって自動的に追加されました。

ブロックの末尾行は`t.timestamps`メソッドを呼び出しています。これは`created_at`と`updated_at`という2つのカラムを追加で定義します。後述するように、これらのカラムはRailsによって自動で管理されるので、モデルオブジェクトを作成・更新すると、これらのカラムに値が自動で設定されます。

それでは以下のコマンドでマイグレーションを実行しましょう。

```bash
$ bin/rails db:migrate
```

マイグレーションコマンドを実行すると、データベース上にテーブルが作成されます。

```
==  CreateArticles: migrating ===================================
-- create_table(:articles)
   -> 0.0018s
==  CreateArticles: migrated (0.0018s) ==========================
```

TIP: マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。

これで、モデルを介してテーブルとやりとりできるようになりました。

### モデルを用いてデータベースとやりとりする

Railsの**コンソール**機能を使って、モデルで少し遊んでみましょう。Railsコンソールは、Rubyの`irb`と同様の対話的コーディング環境ですが、`irb`と違うのは、Railsとアプリケーションコードも自動的に読み込まれる点です。

以下を実行してRailsコンソールを起動しましょう。

```bash
$ bin/rails console
```

以下のような`irb`プロンプトが表示されるはずです。

```irb
Loading development environment (Rails 7.1.0)
irb(main):001:0>
```

このプロンプトで、先ほど作成した`Article`オブジェクトを以下のように初期化できます。

```irb
irb> article = Article.new(title: "Hello Rails", body: "I am on Rails!")
```

ここで重要なのは、このオブジェクトは単に**初期化された**だけの状態であり、まだデータベースに保存されていないことです。つまり、このオブジェクトはこのコンソールでしか利用できません（コンソールを終了すると消えてしまいます）。オブジェクトをデータベースに保存するには、[`save`](
https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save)メソッドを呼び出さなくてはなりません。

```irb
irb> article.save
(0.1ms)  begin transaction
Article Create (0.4ms)  INSERT INTO "articles" ("title", "body", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["title", "Hello Rails"], ["body", "I am on Rails!"], ["created_at", "2020-01-18 23:47:30.734416"], ["updated_at", "2020-01-18 23:47:30.734416"]]
(0.9ms)  commit transaction
=> true
```

上の出力には、`INSERT INTO "Article" ...`というデータベースクエリも表示されています。これは、その記事がテーブルにINSERT（挿入）されたことを示しています。そして、`article`オブジェクトをもう一度表示すると、先ほどと何かが変わっていることがわかります。

```irb
irb> article
=> #<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">
```

オブジェクトに`id`、`created_at`、`updated_at`という属性（attribute）が設定されています。先ほどオブジェクトを`save`したときにRailsが追加してくれたのです。

この記事をデータベースから取り出したければ、そのモデルで[`find`](
https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find)メソッドを呼び出し、その記事の`id`を引数として渡します。

```irb
irb> Article.find(1)
=> #<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">
```

データベースに保存されているすべての記事を取り出すには、そのモデルで[`all`]( https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-all)メソッドを呼び出します。

```irb
irb> Article.all
=> #<ActiveRecord::Relation [#<Article id: 1, title: "Hello Rails", body: "I am on Rails!", created_at: "2020-01-18 23:47:30", updated_at: "2020-01-18 23:47:30">]>
```

このメソッドが返す[`ActiveRecord::Relation`](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html)オブジェクトは、一種の超強力な配列と考えるとよいでしょう。

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

コントローラ内のインスタンス変数（`@`で始まる変数）は、ビューからも参照できます。つまり、`app/views/articles/index.html.erb`で`@articles`と書くと、このインスタンス変数を参照できるということです。このファイルを開いて、以下のように書き換えます。

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

上記のコードでは、HTMLの中に**ERB**（[Embedded Ruby](https://ja.wikipedia.org/wiki/ERuby)）も書かれています。ERBとは、ドキュメントに埋め込まれたRubyコードを評価するテンプレートシステムのことです。
ここでは、`<% %>`と`<%= %>`という2種類のERBタグが使われています。`<% %>`タグは「この中のRubyコードを評価する」という意味です。`<%= %>`タグは「この中のRubyコードを評価し、返された値を出力する」という意味です。
これらのERBタグの中には、通常のRubyプログラムで書けるコードなら何でも書けますが、読みやすさのため、ERBタグにはなるべく短いコードを書く方がよいでしょう。

上のコードでは、`@articles.each`が返す値は画面に出力したくないので`<% %>` で囲んでいますが、（各記事の）`article.title` が返す値は画面に出力したいので`<%= %>` で囲んでいます。

ブラウザで<http://localhost:3000>を開くと最終的な結果を確認できます（`bin/rails server`を実行しておくことをお忘れなく）。このときの動作は以下のようになります。

1. ブラウザは`GET http://localhost:3000`というリクエストをサーバーに送信する。
2. Railsアプリケーションがこのリクエストを受信する。
3. Railsルーターがrootルーティングを`ArticlesController`の`index`アクションに割り当てる。
4. `index`アクションは、`Article`モデルを用いてデータベースからすべての記事を取り出す。
5. Railsが自動的に`app/views/articles/index.html.erb`ビューをレンダリングする。
6. ビューにあるERBコードが評価されてHTMLを出力する。
7. サーバーは、HTMLを含むレスポンスをブラウザに送信する。

これでMVCのピースがすべてつながり、コントローラに最初のアクションができました。このまま次のアクションを作ってみましょう。

CRUDの重要性
--------------------------

ほぼすべてのWebアプリケーションは、何らかの形で[CRUD（Create、Read、Update、Delete）](
https://ja.wikipedia.org/wiki/CRUD)操作を行います。Webアプリケーションで行われる処理の大半はCRUDです。Railsフレームワークはこの点を認識しており、CRUDを行うコードをシンプルに書ける機能を多数備えています。

それでは、アプリケーションに機能を追加してこれらの機能を探ってみましょう。

### 記事を1件表示する

現在のビューは、データベースにある記事をすべて表示します。今度は、1件の記事のタイトルと本文を表示するビューを追加してみましょう。

手始めに、コントローラの新しいアクションに対応付けられる新しいルーティングを1個追加します（アクションはこの後で追加します）。`config/routes.rb`を開き、ルーティングの末尾に以下のように追加します。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  get "/articles", to: "articles#index"
  get "/articles/:id", to: "articles#show"
end
```

追加したルーティングも`get`ルーティングですが、パスの末尾に`:id`が追加されている点が異なります。これはルーティングの**パラメータ**（parameter）を指定します。ルーティングパラメータは、リクエストのパスに含まれる特定の値をキャプチャして、その値を`params`というハッシュに保存します。`params`はコントローラのアクションでもアクセスできます。たとえば`GET http://localhost:3000/articles/1`というリクエストを扱う場合、`:id`で`1`がキャプチャされ、`ArticlesController`の`show`アクションで`params[:id]`と書くとアクセスできます。

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

この`show`アクションでは、[前述](#モデルを用いてデータベースとやりとりする)の`Article.find`メソッドを呼び出すときに、ルーティングパラメータでキャプチャしたidを渡しています。返された記事は`@article`インスタンス変数に保存されているので、ビューから参照できます。`show`アクションは、デフォルトで`app/views/articles/show.html.erb`をレンダリングします。

今度は`app/views/articles/show.html.erb`を作成し、以下のコードを書きます。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>
```

これで、<http://localhost:3000/articles/1>を開くと記事が1件表示されるようになりました。

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

ここまでにCRUDのR（Read）をやってみました。最終的にCRUDのC（Create）、U（Update）、D（Delete）も行います。既にお気づきかと思いますが、CRUDを追加するときは「ルーティングを追加する」「コントローラにアクションを追加する」「ビューを追加する」という3つの作業を行います。「ルーティング」「コントローラのアクション」「ビュー」がどんな組み合わせになっても、エンティティに対するCRUD操作に落とし込まれます。こうしたエンティティは**リソース**（resource）と呼ばれます。たとえば、このアプリケーションの場合は「1件の記事」が1個のリソースに該当します。

Railsは[`resources`](
https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-resources)というルーティングメソッドを提供しており、メソッド名が複数形であることからわかるように、リソースのコレクション（collection: 集まり）を対応付けるのによく使われるルーティングをすべて対応付けてくれます。C（Create）、U（Update）、D（Delete）に進む前に、`config/routes.rb`でこれまで`get`メソッドで書かれていたルーティングを`resources`で書き換えましょう。

```ruby
Rails.application.routes.draw do
  root "articles#index"

  resources :articles
end
```

ルーティングがどのように対応付けられているかを表示するには、`bin/rails routes`コマンドが使えます（訳注: Rails 7では以下のルーティングの下にTurboやAction MailboxやActive Storageなどのルーティングも表示されますが、ここでは無視して構いません）。

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

`resources`メソッドは、`_url`で終わる「URL」ヘルパーメソッドと、`_path`で終わる「パス」ヘルパーメソッドも自動的に設定します。パスヘルパーを使うことで、コードが特定のルーティング設定に依存することを避けられます。Prefixカラムの値の末尾には、パスヘルパーによって`_url`や`_path`といったサフィックスが追加されます。たとえば、記事を1件渡されると、`article_path`ヘルパーは`"/articles/#{article.id}"`を返します。このパスヘルパーを用いると、`app/views/articles/index.html.erb`のリンクを簡潔な形に書き直せます。

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
https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to)ヘルパーを用いると`<a>`タグが不要になるので、さらに便利です。`link_to`ヘルパーの第1引数はリンクテキスト、第2引数はリンク先です。第2引数にモデルオブジェクトを渡すと、`link_to`が適切なパスヘルパーを呼び出してオブジェクトをパスに変換します。たとえば、`link_to`にarticleを渡すと`article_path`というパスヘルパーが呼び出されます。これを用いると、`app/views/articles/index.html.erb`は以下のように書き換えられます。

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

スッキリしましたね！

TIP: ルーティングについて詳しくは[Railsのルーティング](
routing.html)を参照してください。

### 記事を1件作成する

次はCRUDのC（Create）です。典型的なWebアプリケーションでは、リソースを1個作成するのに複数のステップを要します。最初にユーザーがフォーム画面をリクエストします。次にユーザーがそのフォームに入力して送信します。エラーが発生しなかった場合はリソースが作成され、リソース作成に成功したことを何らかの形で表示します。エラーが発生した場合はフォーム画面をエラーメッセージ付きで再表示し、フォーム送信の手順を繰り返します。

Railsアプリケーションでは、通常これらのステップを実現するときに`new`アクションと`create`アクションを組み合わせて扱います。それでは2つのアクションを`app/controllers/articles_controller.rb`の`show`アクションの下に典型的な実装として追加してみましょう。

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
      render :new, status: :unprocessable_entity
    end
  end
end
```

`new`アクションは、新しい記事を1件インスタンス化しますが、データベースには保存しません。インスタンス化された記事は、ビューでフォームをビルドするときに使われます。`new`アクションを実行すると、`app/views/articles/new.html.erb`（この後作成します）がレンダリングされます。

`create`アクションは、タイトルと本文を持つ新しい記事をインスタンス化し、データベースへの保存を試みます。記事の保存に成功すると、その記事のページ（`"http://localhost:3000/articles/#{@article.id}"`）にリダイレクトします。記事の保存に失敗した場合は、`app/views/articles/new.html.erb`に戻ってフォームを再表示し、[Turbo](https://github.com/hotwired/turbo-rails)が正常に動作するようにステータスコード[422 Unprocessable Entity](https://developer.mozilla.org/ja-JP/docs/Web/HTTP/Status/422)を返します（`unprocessable_entity`）。なお、このときの記事タイトルと本文にはダミーの値が使われます。これらはフォームが作成された後でユーザーが変更することになります。


NOTE: [`redirect_to`](https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_to)メソッドを使うとブラウザで新しいリクエストが発生しますが、[`render`](https://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render)メソッドは指定のビューを現在のリクエストとしてレンダリングします。ここで重要なのは、`redirect_to`メソッドはデータベースやアプリケーションのステートが変更された「後で」呼び出すべきであるという点です。ステートが変更される前に`redirect_to`を呼び出すと、ユーザーがブラウザをリロードしたときに同じリクエストが再送信され、変更が重複してしまいます。

#### フォームビルダーを使う

ここではRailsの**フォームビルダー**（form builder）という機能を使います。フォームビルダーを使えば、最小限のコードを書くだけで設定がすべてできあがったフォームを表示でき、かつRailsの規約に沿うことができます。

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

そこで、さまざまな値を個別に渡すのではなく、それらの値を含む1個のハッシュを渡します。しかしその場合も、ハッシュ内でどのような値が許されているかを厳密に指定しなければなりません。これを怠ると、悪意のあるユーザーがブラウザ側でフィールドをこっそり追加して、機密データを上書きする可能性が生じるので危険です。ただし実際には、`params[:article]`をフィルタなしで`Article.new`に直接渡すと、Railsが`ForbiddenAttributesError`エラーを出してこの問題を警告するようになっています。そこで、Railsの**Strong Parameters**という機能を用いて`params`をフィルタすることにします。ここで言うstrongとは、`params`を[強く型付けする](https://en.wikipedia.org/wiki/Strong_and_weak_typing)（strong typing）とお考えください。

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
      render :new, status: :unprocessable_entity
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

これまで見てきたように、リソースの作成は単独のステップではなく、複数のステップで構成されています。その中には、無効なユーザー入力を適切に処理することも含まれます。Railsには、無効なユーザー入力を処理するために**バリデーション**（validation: 検証）という機能が用意されています。バリデーションとは、モデルオブジェクトを保存する前に自動的にチェックするルールのことです。チェックに失敗した場合は保存を中止し、モデルオブジェクトの `errors` 属性に適切なエラーメッセージが追加されます。

それでは、`app/models/article.rb`モデルにバリデーションをいくつか追加してみましょう。

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

1個目のバリデーションは、「`title`の値が必ず存在しなければならない」ことを宣言しています。`title`は文字列なので、`title`にはホワイトスペース（スペース文字、改行、Tabなど）以外の文字が1個以上含まれていなければならないという意味になります。

2個目のバリデーションも、「`body`の値が必ず存在しなければならない」ことを宣言しています。さらに、`body`の値は10文字以上でなければならないことも宣言しています。

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
      render :new, status: :unprocessable_entity
    end
  end
```

<http://localhost:3000/articles/new>をブラウザで表示すると、`GET /articles/new`リクエストは`new`アクションに対応付けられます。`new`アクションは`@article`を保存しないので、この時点ではバリデーションは実行されず、エラーメッセージも表示されません。

このフォームを送信すると、`POST /articles`リクエストは`create`アクションに対応付けられます。`create`アクションは`@article`を**保存しようとする**ので、バリデーションが**実行されます**。バリデーションのいずれかが失敗すると、`@article`は保存されず、レンダリングされた`app/views/articles/new.html.erb`にエラーメッセージが表示されます。

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

ここまでで、CRUDのうちCとRを実現しました。今度はUの部分、つまり更新を実装してみましょう。リソースの更新は、ステップが複数あるという点でリソースの作成と非常に似ています。最初に、ユーザーはデータを編集するフォームをリクエストします。次に、ユーザーがフォームにデータを入力して送信します。エラーが発生しなければ、リソースは更新されます。エラーが発生した場合はフォームをエラーメッセージ付きで再表示し、同じことを繰り返します。

更新のステップは、コントローラの`edit`アクションと`update`アクションで扱うのが慣例です。それでは、`app/controllers/articles_controller.rb`の`create`アクションの下にこれらのアクションの典型的な実装を追加してみましょう。

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
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
```

更新に用いる`edit`アクションおよび`update`アクションが、作成に用いる`new`アクションおよび`create`とほとんど同じである点にご注目ください。

`edit`アクションはデータベースから記事を取得して`@article`に保存し、フォームを作成するときに使えるようにします。`edit`アクションは、デフォルトで`app/views/articles/edit.html.erb`をレンダリングします。

`update`アクションはデータベースから記事を（再）取得し、
`article_params`でフィルタリングされた送信済みのフォームデータで更新を試みます。
バリデーションが失敗せずに更新が成功した場合、ブラウザを更新後の記事ページにリダイレクトします。更新に失敗した場合は`app/views/articles/edit.html.erb`をレンダリングし、同じフォームをエラーメッセージ付きで再表示します。

#### ビューのコードをパーシャルで共有する

`edit`で使うフォームの表示は、`new`で使うフォームの表示と同じに見えます。さらに、Railsのフォームビルダーとリソースフルルーティングのおかげで、コードも同じになっています。フォームビルダーは、モデルオブジェクトが既に保存されている場合は`edit`用のフォームを、モデルオブジェクトが保存されていない場合は`new`用のフォームを自動的に構成するので、状況に応じて適切なリクエストを行えます。

どちらのフォームにも同じコードが使われているので、**パーシャル**（partial: 部分テンプレートとも呼ばれます）と呼ばれる共有ビューにまとめることにします。以下の内容で `app/views/articles/_form.html.erb` を作成してみましょう。

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

上記のコードは`app/views/articles/new.html.erb`のフォームと同じですが、すべての`@article`を`article`に置き換えてある点にご注目ください。パーシャルのコードは共有されるので、特定のインスタンス変数に依存しないようにするのがベストプラクティスです（コントローラのアクションで設定されるインスタンス変数に依存すると、他で使い回すときに不都合が生じます）。代わりに、記事をローカル変数としてパーシャルに渡します。

[`render`]( https://api.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render) でパーシャルを使うために、`app/views/articles/new.html.erb`を以下の内容で置き換えてみましょう。

```html+erb
<h1>New Article</h1>

<%= render "form", article: @article %>
```

NOTE: パーシャルのファイル名は冒頭にアンダースコア`_`を**必ず**付けなければなりません（例: `_form.html.erb`）。ただし、レンダリングでパーシャルを参照するときはアンダースコアを**付けません**（例: `render "form"`）。

続いて、同じ要領で以下の内容の`app/views/articles/edit.html.erb`も作ってみましょう。

```html+erb
<h1>Edit Article</h1>

<%= render "form", article: @article %>
```

TIP: パーシャルについて詳しくは、[レイアウトとレンダリング § パーシャルを使う](layouts_and_rendering.html#パーシャルを使う)を参照してください。

#### 仕上げ

これで、記事のeditページ（<http://localhost:3000/articles/1/edit>など）にアクセスして記事を更新できるようになりました。最後に、`app/views/articles/show.html.erb` の末尾に以下のようなeditページへのリンクを追加してみましょう。

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
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to root_path, status: :see_other
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end
```

`destroy`アクションは、データベースから記事を取得して[`destroy`]( https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-destroy )メソッドを呼び出しています。次にブラウザをステータスコード[303 See Other](https://developer.mozilla.org/ja/docs/Web/HTTP/Status/303)でrootパスにリダイレクトします。

rootパスにリダイレクトすることに決めたのは、そこが記事へのメインのアクセスポイントだからです。しかし状況によっては、たとえば`articles_path`にリダイレクトすることもあります。

それでは、`app/views/articles/show.html.erb` の下部に削除用ボタンを追加して、ページの記事を削除できるようにしましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
</ul>
```

上のコードでは、`data`オプションを使って"Destroy"リンクのHTML属性`data-turbo-method`と`data-turbo-confirm`を設定しています。どちらの属性も、新しいRailsアプリケーションにデフォルトで含まれている[Turbo](https://turbo.hotwired.dev/)にフックします。
`data-turbo-method="delete"`を指定すると、`GET`リクエストではなく`DELETE`リクエストが送信されます。
`data-turbo-confirm="Are you sure?"` を指定すると、リンクをクリックしたときに「Are you sure?」ダイアログが表示され、ユーザーが「キャンセル」をクリックするとリクエストを中止します。

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

Commentモデルの内容は、これまでに見た`Articleモデル`と非常によく似ています。違いは、Active Recordの**関連付け**（アソシエーション: association）を設定する`belongs_to :article`という行がある点です。関連付けについて詳しくは、本ガイドの次のセクションで解説します。

シェルコマンドで使われている`:references`キーワードは、モデルの特殊なデータ型を表し
、指定されたモデル名の後ろに`_id`を追加した名前を持つ新しいカラムをデータベーステーブルに作成します。マイグレーションの実行後に`db/schema.rb`ファイルを調べてみると理解しやすいでしょう。

モデルファイルの他に、以下のようなマイグレーションファイルも生成されています。マイグレーションファイルは、モデルに対応するデータベーステーブルを生成するのに使います。

```ruby
class CreateComments < ActiveRecord::Migration[7.1]
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
* 1件の記事はコメントを複数持てる（One article can **have many** comments）。

そして上の方法（における英語の記述）は、Railsで関連付けを宣言するときの文法と非常に似ています。`Comment`モデル（app/models/comment.rb）内のコードに既に書かれていたように、各コメントは1つの記事に属しています。

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

今度は、`Article`モデル（`app/models/article.rb`）を編集して、関連付けの他方のモデルをここに追加する必要があります。

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

この設定により、`articles`の内側に**ネストしたリソース**（nested resource）として`comments`が作成されます。これは、モデルの記述とは別の視点から、記事とコメントの間のリレーションシップを階層的に捉えたものです。

TIP: ルーティングについて詳しくは[Railsのルーティング](routing.html)ガイドを参照してください。

### コントローラを生成する

モデルを手作りしたので、モデルに合うコントローラも作ってみたくなります。それでは、再びこれまでと同様にジェネレータを使ってみましょう。

```bash
$ bin/rails generate controller Comments
```

上のコマンドを実行すると、以下の3つのファイルと1つの空ディレクトリが作成されます。

ファイル/ディレクトリ | 目的
--- | ---
app/controllers/comments_controller.rb | コメント用コントローラ
app/views/comments/ | このコントローラのビューはここに置かれる
test/controllers/comments_controller_test.rb | このコントローラのテスト用ファイル
app/helpers/comments_helper.rb | ビューヘルパー

一般的なブログと同様、このブログの記事を読んだ人はそこに直接コメントを追加したくなるでしょう。そしてコメントを追加後に元の記事表示ページに戻り、コメントがそこに反映されていることを確認したいはずです。そこで、`CommentsController`を用いてコメントを作成したり、スパムコメントが書き込まれたら削除できるようにしたいと思います。

そこで最初に、Articleのshowテンプレート（`app/views/articles/show.html.erb`）を改造して新規コメントを作成できるようにしましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
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

上のコードは、`Article`コントローラのコードを書いていたときよりも少しだけ複雑に見えます。これはネストを使ったことによるものです。コメント関連のリクエストでは、コメントがどの記事に追加されるのかを追えるようにしておく必要があります。そこで、`Article`モデルの`find`メソッドを最初に呼び出し、リクエストで言及されている記事（のオブジェクト）を取得して`@article`に保存しています。

さらにこのコードでは、関連付けによって有効になったメソッドをいくつも利用しています。`@article.comments`に対して`create`メソッドを実行することで、コメントの作成と保存を同時に行っています（訳注: `build`メソッドにすれば作成のみで保存は行いません）。この方法でコメントを作成すると、コメントと記事が自動的にリンクされ、指定された記事に対してコメントが従属するようになります。

新しいコメントの作成が完了したら、`article_path(@article)`ヘルパーを用いて元の記事の画面に戻ります。既に説明したように、このヘルパーを呼び出すと`ArticlesController`の`show`アクションが呼び出され、`show.html.erb`テンプレートがレンダリングされます。この画面にコメントを表示したいので、`app/views/articles/show.html.erb`に以下のコードを追加しましょう。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
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

これで、ブログに記事やコメントを自由に追加して、それらを正しい場所に表示できるようになりました。

![記事にコメントが追加された様子](images/getting_started/article_with_comments.png)

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

続いて、`app/views/articles/show.html.erb`の内容を以下に置き換えます。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
</ul>

<h2>Comments</h2>
<%= render @article.comments %>

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

これで、`app/views/comments/_comment.html.erb`パーシャルが、`@article.comments`コレクションに含まれているコメントをすべてレンダリングするようになりました。`render`メソッドが`@article.comments`コレクションに含まれる要素を1つずつ列挙するときに、各コメントをパーシャルと同じ名前のローカル変数に自動的に代入します。この場合は`comment`というローカル変数が使われるので、これをパーシャルの表示に利用できます。

### パーシャルのフォームをレンダリングする

今度はコメント作成部分もパーシャルに追い出してみましょう。`app/views/comments/_form.html.erb`ファイルを作成し、以下のように入力します。

```html+erb
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

続いて`app/views/articles/show.html.erb`の内容を以下で置き換えます。

```html+erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
</ul>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= render 'comments/form' %>
```

2番目の`render`は、レンダリングする`comments/form`パーシャルテンプレートを定義しているだけです。`comments/form`と書くだけで、Railsは区切りのスラッシュ文字を認識し、`app/views/comments`ディレクトリの`_form.html.erb`パーシャルをレンダリングすればよいということを理解し、実行してくれます。`app/views/comments/_form.html.erb`などと書く必要はありません。

`@article`オブジェクトはインスタンス変数なので、ビューでレンダリングされるどのパーシャルからもアクセスできます。

### concernを使う

Railsの「concern（関心事）」とは、大規模なコントローラやモデルの理解や管理を楽にする手法の１つです。複数のモデル（またはコントローラ）が同じ関心を共有していれば、concernを介して再利用できるというメリットもあります。concernはRubyの「モジュール」で実装され、モデルやコントローラが担当する機能のうち明確に定義された部分を表すメソッドをそのモジュールに含めます。なおモジュールは他の言語では「ミックスイン」と呼ばれることもよくあります。

concernは、コントローラやモデルで普通のモジュールと同じように使えます。`rails new blog` でアプリを作成すると、`app/`内に以下の2つのconcernsフォルダも作成されます。

```
app/controllers/concerns
app/models/concerns
```

以下の例ではブログの新機能を実装しますが、この機能にはconcernを利用するのが有益です。そこで、この機能を利用するためにconcernを作成し、コードをリファクタリングすることで、コードをよりDRYでメンテナンスしやすくします。

1件のブログ記事はさまざまなステータスを持つ可能性があります。たとえば記事の可視性について「誰でも見てよい（`public`）」「著者だけに見せる（`private`）」というステータスを持つかもしれませんし、「復旧可能な形で記事を非表示にする（`archived`）」ことも考えられます。コメントについても同様に可視性やアーカイブを設定することもあるでしょう。こうしたステータスを表す方法の１つとして、モデルごとに`status`カラムを持たせるとしましょう。

以下のマイグレーション生成コマンドを実行して`status`カラムを追加した後で、`Article`モデルと`Comments`モデルに`status`カラムを追加します。

```bash
$ bin/rails generate migration AddStatusToArticles status:string
$ bin/rails generate migration AddStatusToComments status:string
```

続いて以下を実行し、生成されたマイグレーションでデータベースを更新します。

```bash
$ bin/rails db:migrate
```

既存の記事やコメントのステータスを一括指定するには、生成されたマイグレーションファイルに`default: "public"`オプションを追加してデフォルト値を追加し、マイグレーションを再度実行する方法が使えます。あるいは、railsコンソールで`Article.update_all(status: "public")`や`Comment.update_all(status: "public")`を呼び出すことでも可能です。

TIP: マイグレーションについて詳しくは、[Active Record マイグレーション](
active_record_migrations.html)ガイドを参照してください。

次に、`app/controllers/articles_controller.rb`のStrong Parametersを以下のように更新して`:status`キーも許可しておく必要があります。

```ruby

  private
    def article_params
      params.require(:article).permit(:title, :body, :status)
    end
```

`app/controllers/comments_controller.rb`でも同様に`:status`キーを許可します。

```ruby

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body, :status)
    end
```

`bin/rails db:migrate`マイグレーションを実行して`status`カラムを追加したら、`Article`モデルを以下で置き換えます。

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

`Comment`モデルも以下で置き換えます。

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

同様に、コメントのパーシャルビュー（`app/views/comments/_comment.html.erb`）にも、アーカイブ済みのコメントが表示されないよう`archived?`メソッドを書きます。

```html+erb
<% unless comment.archived? %>
  <p>
    <strong>Commenter:</strong>
    <%= comment.commenter %>
  </p>

  <p>
    <strong>Comment:</strong>
    <%= comment.body %>
  </p>
<% end %>
```

しかし、2つのモデルのコードを見返してみると、ロジックが重複していることがわかります。このままでは、今後ブログにプライベートメッセージ機能などを追加するとロジックがまた重複してしまうでしょう。concernは、このような重複を避けるのに便利です。

1つのconcernは、モデルの責務の「一部」についてのみ責任を負います。この例の場合、「関心（concern）」の対象となるメソッドはすべてモデルの可視性に関連しているので、新しいconcern（すなわちモジュール）を`Visible`と呼ぶことにしましょう。`app/models/concerns`ディレクトリの下に`visible.rb`という新しいファイルを作成し、複数のモデルで重複していたステータス関連のすべてのメソッドをそこに移動します。

`app/models/concerns/visible.rb`

```ruby
module Visible
  def archived?
    status == 'archived'
  end
end
```

ステータスを検証するメソッドもconcernにまとめられますが、バリデーションメソッドはクラスレベルで呼び出されるので、より複雑になります。APIドキュメントの[`ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)には、以下のようにバリデーションをシンプルに`included`する方法が紹介されています。

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

これで、以下のようにindexビューで任意のクラスメソッドを呼べるようになります。

```html+erb
<h1>Articles</h1>

Our blog has <%= Article.public_count %> articles and counting!

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

仕上げとして、フォームにセレクトボックスを追加して、ユーザーが記事を作成したりコメントを投稿したりするときにステータスを選択できるようにします。

オブジェクトのステータスを選択する（ステータスが未設定の場合は`public`をデフォルトに指定する）ことも可能です。`app/views/articles/_form.html.erb`に以下を追加します。

```html+erb
<div>
  <%= form.label :status %><br>
  <%= form.select :status, Visible::VALID_STATUSES, selected: article.status || 'public' %>
</div>
```

`app/views/comments/_form.html.erb`にも以下を追加します。

```html+erb
<p>
  <%= form.label :status %><br>
  <%= form.select :status, Visible::VALID_STATUSES, selected: 'public' %>
</p>
```

## コメントを削除する

スパムコメントを削除できるようにするのも、このブログでは重要な機能です。そのためのビューを作成し、`CommentsController`に`destroy`アクションを作成する必要があります。

最初に`app/views/comments/_comment.html.erb`パーシャルに削除用のボタンを追加しましょう。

```html+erb
<% unless comment.archived? %>
  <p>
    <strong>Commenter:</strong>
    <%= comment.commenter %>
  </p>

  <p>
    <strong>Comment:</strong>
    <%= comment.body %>
  </p>

  <p>
    <%= link_to "Destroy Comment", [comment.article, comment], data: {
                  turbo_method: :delete,
                  turbo_confirm: "Are you sure?"
                } %>
  </p>
<% end %>
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
    redirect_to article_path(@article), status: :see_other
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body, :status)
    end
end
```

この`destroy`アクションは、まずどの記事が対象であるかを検索して`@article`に保存し、続いて`@article.comments`コレクションの中のどのコメントが対象であるかを特定して`@comment`に保存します。そしてそのコメントをデータベースから削除し、終わったら記事の`show`アクションに戻ります。

### 関連付けられたオブジェクトも削除する

ある記事を削除したら、その記事に関連付けられているコメントも一緒に削除する必要があります（そうしないと、コメントがいつまでもデータベース上に残ってしまいます）。Railsでは関連付けに`dependent`オプションを指定することでこれを実現しています。Articleモデル`app/models/article.rb`を以下のように変更しましょう。

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

`ArticlesController`では、認証されていない人物がアクションにアクセスできないようにブロックする必要があります。そこで、Railsの`http_basic_authenticate_with`メソッドを使うことで、このメソッドが許可する場合に限って、リクエストされたアクションにアクセスできるようにすることができます。

この認証システムを使うには、`ArticlesController`コントローラの冒頭部分で指定します。今回は、`index`アクションと`show`アクションは自由にアクセスできるようにし、それ以外のアクションには認証を要求するようにしたいと思います。そこで、`app/controllers/articles_controller.rb`に次の記述を追加します。

```ruby
class ArticlesController < ApplicationController
  http_basic_authenticate_with name: "dhh", password: "secret", except: [:index, :show]

  def index
    @articles = Article.all
  end

  #（以下省略）
end
```

コメントの削除も認証済みユーザーにだけ許可したいので、`CommentsController`（`app/controllers/comments_controller.rb`）に以下のように追記します。

```ruby
class CommentsController < ApplicationController
  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    # ...
  end

  #（以下省略）
end
```

これで、記事を新規作成しようとすると、以下のようなBASIC http認証ダイアログが表示されます。

![Basic HTTP Authentication Challenge](images/getting_started/challenge.png)

正しいユーザー名とパスワードを入力すると、別のユーザー名とパスワードが要求されるか、ブラウザが閉じられるまで、認証された状態が続きます。

もちろん、Railsでは他の認証方法も使えます。Railsにはさまざまな認証システムがありますが、その中で人気が高い認証システムは[Devise](https://github.com/plataformatec/devise)と[Authlogic](https://github.com/binarylogic/authlogic) gemの2つです。

### その他のセキュリティ対策

セキュリティ、それもWebアプリケーションのセキュリティは非常に幅広く、かつ詳細に渡っています。Railsアプリケーションのセキュリティについて詳しくは、本ガイドの[Railsセキュリティガイド](security.html)を参照してください。

## 次に学ぶべきこと

以上で、Railsアプリケーションを初めて作るという試みは終わりです。この後は自由に更新したり実験を重ねたりできます。

もちろん、何の助けもなしにWebアプリケーションを作らなければならないなどということはないということを忘れてはなりません。RailsでWebアプリを立ち上げたり実行したりするうえで助けが必要になったら、以下のサポート用リソースを自由に参照できます。

- [Ruby on Railsガイド](/) (本サイトです)
- [Ruby on Railsメーリングリスト](https://discuss.rubyonrails.org/c/rubyonrails-talk)（英語）

## 設定の落とし穴

Railsでの無用なトラブルを避けるための最も初歩的なコツは、外部データを常にUTF-8エンコーディングで保存しておくことです。そうしておかないと、RubyライブラリやRailsがネイティブデータをたびたびUTF-8に変換しなければならず、しかも場合によっては失敗します。外部データのエンコーディングは常にUTF-8で統一することをおすすめします。

外部データのエンコードが統一されていないと、たとえば画面に黒い菱型`◆`や疑問符`?`が表示されたり、"ü"という文字のはずが"Ã¼"という文字に化けたりするといった症状がよく発生します。Railsではこうした問題を緩和するため、問題の原因を自動的に検出して修正するために内部で多くの手順を行っています。しかし、UTF-8で保存されていない外部データがあると、Railsによる自動検出・修正が効かないデータで文字化けが発生することがあります。

UTF-8でないデータの主な原因は以下の2つです。

* テキストエディタ: TextMateを含む多くのテキストエディタは、デフォルトでUTF-8エンコードでテキストを保存します。使っているテキストエディタがこのようになっていない場合、テンプレートを表示する時にéなどの特殊文字が`◆?`のようにブラウザ表示が文字化けすることがあります。これはi18n（国際化）用の翻訳ファイルで発生することもあります。DreamweaverのようにUTF-8保存がデフォルトでないエディタであっても、デフォルトをUTF-8に変更する方法は用意されているはずです。エンコードをUTF-8に変更してください。
* データベース: Railsはデータベースから読みだしたデータを境界上でUTF-8に変換します。しかし、使っているデータベースの内部エンコード設定がUTF-8になっていない場合、UTF-8文字の一部をデータベースにそのまま保存できないことがあります。たとえばデータベースの内部エンコードがLatin-1になっていると、ロシア語・ヘブライ語・日本語などの文字をデータベースに保存したときにこれらの情報は永久に失われてしまいます。できるかぎり、データベースの内部エンコードはUTF-8にしておいてください。
