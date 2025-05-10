Rails をはじめよう
============

このガイドでは、Ruby on Rails（以下、Rails）を初めて設定して実行するまでを解説します。

このガイドの内容:

- Railsのインストール方法、新しいRailsアプリケーションの作成方法、アプリケーションからデータベースへの接続方法
- Railsアプリケーションの一般的なレイアウト
- MVC（モデル・ビュー・コントローラ）およびRESTful設計の基礎
- Railsアプリケーションで使うパーツを手軽に生成する方法
- 作成したアプリケーションをKamalでデプロイする方法

--------------------------------------------------------------------------------

はじめに
------------

Railsの世界へようこそ! 本ガイド「Railsをはじめよう」では、Railsを活用してWebアプリケーションを構築するときの中核となる概念について解説します。本ガイドを理解するために、Railsの経験は必要ありません。

Railsは、Rubyプログラミング言語用に構築されたWebフレームワークです。RailsはRuby独自のさまざまな機能を活用しているため、このチュートリアルで紹介する基本的な用語や語彙を理解できるように、事前にRubyの基礎を学習しておくことを**強く**オススメします。

- [プログラミング言語Ruby公式Webサイト](https://www.ruby-lang.org/ja/documentation/)
- [プログラミング学習コンテンツまとめ](https://github.com/EbookFoundation/free-programming-books/blob/master/books/free-programming-books-ja.md#ruby)

TIP: 訳注：Railsガイドでは開発経験者が早くキャッチアップできるよう、多くの用語説明を省略しています。読んでいて「難しい」と感じた場合は[Railsチュートリアル](https://railstutorial.jp/)からお読みください。

## Railsとは何か

Railsとは、プログラミング言語「Ruby」で書かれたWebアプリケーションフレームワークです。Railsは、あらゆる開発者がWebアプリケーション開発で必要となる作業やリソースを事前に想定することで、Webアプリケーションをより手軽に開発できるように設計されています。

Railsは、他の多くのWebアプリケーションフレームワークと比較して、アプリケーションを開発する際のコード量がより少なくて済むにもかかわらず、より多くの機能を実現できます。ベテラン開発者の多くが「RailsのおかげでWebアプリケーション開発がとても楽しくなった」と述べています。

Railsは「最善の開発方法は1つである」という、ある意味大胆な判断に基いて設計されています。何かを行うための最善の方法を1つ仮定して、それに沿った開発を全面的に支援します。言い換えれば、Railsで仮定されていない別の開発手法は行いにくくなります。

この「Rails Way」、すなわち「Railsというレールに乗って開発する」手法を学んだ人は、開発の生産性が驚くほど向上することに気付くでしょう。逆に、レールに乗らずに従来の開発手法にこだわると、開発の楽しさが減ってしまうかもしれません。

Railsの哲学には、以下の2つの主要な基本理念があります。

- **繰り返しを避けよ（Don't Repeat Yourself: DRY）:**
  DRYはソフトウェア開発上の原則であり、「システムを構成する知識のあらゆる部品は、常に単一であり、明確であり、信頼できる形で表現されていなければならない」というものです。同じコードを繰り返し書くことを徹底的に避けることで、コードが保守しやすくなり、容易に拡張できるようになり、バグも減らせます。
- **設定より規約が優先（Convention Over Configuration）:**
  Railsでは、Webアプリケーションの機能を実現する最善の方法が明確に示されており、Webアプリケーションの各種設定についても従来の経験や慣習を元に、それらのデフォルト値を定めています。デフォルト値が決まっているおかげで、開発者の意見をすべて取り入れようとした自由過ぎるWebアプリケーションのように、開発者が大量の設定ファイルを設定せずに済みます。

## Railsアプリを新規作成する

ここでは、Railsの組み込み機能のいくつかをデモンストレーションするシンプルなeコマースアプリを`store`というプロジェクト名で構築します。

TIP: ドル記号`$`で始まるコマンドは、ターミナルで実行する必要があります。

### 前提条件

このプロジェクトでは以下のものが必要です。

* Ruby 3.2以降
* Rails 8.0.0以降
* コードエディタ

RubyやRailsをインストールする必要がある場合は、[Ruby on Rails インストールガイド](install_ruby_on_rails.html)に記載されている手順に従ってください。

TIP: 訳注：GitHubが提供するクラウド開発環境『[Codespaces](https://github.co.jp/features/codespaces)』には、[公式のRuby on Railsテンプレート](https://github.com/codespaces/templates)が用意されています。`Use this template`ボタンから、ワンクリックでRailsを動かせるクラウド開発環境が手に入ります。（参考: [GitHub Codespacesを利用する - Rails Girls](https://railsgirls.jp/install/codespaces)）

正しいバージョンのRailsがインストールされていることを確認しておきましょう。現在のバージョンを表示するには、ターミナルを開いて以下のコマンドを実行すると、バージョン番号が出力されます。

```bash
$ rails --version
Rails 8.0.0
```

バージョン番号はRails 8.0.0以降になるはずです。

### 最初のRailsアプリケーションを作成する

Railsには、作業を楽にするためのさまざまなコマンドが付属しています。
利用可能なコマンドをすべて表示するには、`rails --help`を実行します。

`rails new`コマンドは、新しいRailsアプリケーションの基盤を生成するので、まずこのコマンドを実行することから始めましょう。

`store`アプリケーションを作成するには、ターミナルで以下のコマンドを実行します。

```bash
$ rails new store
```

NOTE: `rails new`コマンドにフラグを追加すると、Railsが生成するアプリケーションをカスタマイズできます。利用可能なオプションをすべて表示するには、`rails new --help`を実行します。

新しいアプリケーションを作成したら、そのディレクトリに移動します。

```bash
$ cd store
```

### ディレクトリ構造

新しいRailsアプリケーションに含まれるファイルとディレクトリを少し見てみましょう。このフォルダをコードエディタで開くか、ターミナルで`ls -la`を実行してファイルとディレクトリを確認できます。

| ファイル/フォルダ | 目的 |
| ----------- | ------- |
|app/|このディレクトリには、アプリケーションのコントローラ、モデル、ビュー、ヘルパー、メーラー、ジョブ、そしてアセットが置かれます。以後、本ガイドでは基本的にこのディレクトリを中心に説明を行います。|
|bin/|このディレクトリには、アプリケーションを起動する`rails`スクリプトが置かれます。セットアップ・アップデート・デプロイに使うスクリプトファイルもここに置けます。
|config/|このディレクトリには、アプリケーションの各種設定ファイル（ルーティング、データベースなど）が置かれます。詳しくは[Rails アプリケーションの設定項目](configuring.html)を参照してください。|
|config.ru|Rackベースのサーバーでアプリケーションの起動に使われる[Rack](https://rack.github.io)設定ファイルです。|
|db/|このディレクトリには、現在のデータベーススキーマと、データベースマイグレーションファイルが置かれます。|
|Dockerfile|Dockerの設定ファイルです。|
|Gemfile<br>Gemfile.lock|これらのファイルは、Railsアプリケーションで必要となるgemの依存関係を記述します。この2つのファイルは[Bundler](https://bundler.io) gemで使われます。|
|lib/|このディレクトリには、アプリケーションで使う拡張モジュールが置かれます。|
|log/|このディレクトリには、アプリケーションのログファイルが置かれます。|
|public/|静的なファイルやコンパイル済みアセットはここに置きます。このディレクトリにあるファイルは、外部（インターネット）にそのまま公開されます。|
|Rakefile|このファイルは、コマンドラインから実行できるタスクを探索して読み込みます。このタスク定義は、Rails全体のコンポーネントに対して定義されます。独自のRakeタスクを定義したい場合は、`Rakefile`に直接書くと権限が強すぎるので、なるべく`lib/tasks`フォルダの下にRake用のファイルを追加してください。|
|README.md|アプリケーションの概要を簡潔に説明するマニュアルをここに記入します。このファイルにはアプリケーションの設定方法などを記入し、これさえ読めば誰でもアプリケーションを構築できるようにしておきましょう。|
|script/|使い捨ての、または汎用の[スクリプト](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/script/USAGE)や[ベンチマーク](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/benchmark/USAGE)をここに置きます。|
|storage/|このディレクトリには、ディスクサービス用のSQLiteデータベースファイルやActive Storageファイルが置かれます。詳しくは[Active Storageの概要](active_storage_overview.html)を参照してください。|
|test/|このディレクトリには、単体テストやフィクスチャなどのテスト関連ファイルを置きます。テストについて詳しくは[Railsアプリケーションをテストする](testing.html)を参照してください。|
|tmp/|このディレクトリには、キャッシュやpidなどの一時ファイルが置かれます。|
|vendor/|サードパーティ製コードはすべてこのディレクトリに置きます。通常のRailsアプリケーションの場合、外部のgemファイルがここに置かれます。|
|.dockerignore|コンテナにコピーすべきでないファイルをDockerに指示するのに使うファイルです。|
|.gitattributes|このファイルは、gitリポジトリ内の特定のパスについてメタデータを定義します。このメタデータは、gitや他のツールで振る舞いを拡張できます。詳しくは[gitattributesドキュメント](https://git-scm.com/docs/gitattributes)を参照してください。|
|.github/|GitHub固有のファイルが置かれます。|
|.gitignore|Gitに登録しないファイル（またはパターン）をこのファイルで指定します。Gitにファイルを登録しない方法について詳しくは[GitHub - Ignoring files](https://help.github.com/articles/ignoring-files)を参照してください。|
|.kamal/|Kamalの秘密鍵とデプロイ用フックが含まれます。|
|.rubocop.yml|このファイルにはRuboCop用の設定が含まれます。|
|.ruby-version|このファイルには、デフォルトのRubyバージョンが記述されています。|

### MVCの基礎

Railsのコードは、[MVC（Model-View-Controller）](https://ja.wikipedia.org/wiki/Model_View_Controller)アーキテクチャに基づいて編成されています。MVCでは、コードの大部分が以下の3つの主要な概念に基づいて配置されます。

* **モデル**: アプリケーション内のデータ（通常はデータベースのテーブル）を管理します。
* **ビュー**: レスポンスをHTML、JSON、XMLなどのさまざまな形式でレンダリングします。
* **コントローラ**: ユーザー操作や各リクエストのロジックを処理します。

![MVCアーキテクチャの図](images/getting_started/mvc_architecture_light.jpg)


MVCの基本部分を理解したので、MVCがどのようにRailsで使われるかを見てみましょう。

## Hello, Rails!

それでは、Railsサーバーを初めて起動してみましょう。

ターミナルで`store`ディレクトリに移動し、以下のコマンドを実行します。

```bash
$ bin/rails server
```

すると、PumaというWebサーバーが起動します。Pumaサーバーは、静的ファイルやRailsアプリケーションの配信を担当します。

```bash
=> Booting Puma
=> Rails 8.0.0 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.3 (ruby 3.3.5-p100) ("The Eagle of Durango")
*  Min threads: 3
*  Max threads: 3
*  Environment: development
*          PID: 12345
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

Railsアプリケーションを表示してみましょう。
ブラウザで`http://localhost:3000`を開くと、デフォルトのRailsウェルカムページが表示されます。

![Rails起動ページのスクリーンショット](images/getting_started/rails_welcome.png)

動きました！

Railsの起動ページは、新しいRailsアプリケーションの「スモークテスト」として使えます。このページが表示されれば、サーバーが正常に動作していることが確認できます。

実行されているターミナルのウィンドウでCtrl + Cキーを押せば、いつでもWebサーバーを停止できます。

### 開発中の自動コード読み込み

開発者の幸福はRailsの基本的な哲学であり、開発中にコードを自動で再読み込みする機能は、これを実現する方法の1つです。

Railsサーバーを起動すると、新しいファイルや既存のファイルへの変更が検出され、実行中も必要に応じてコードの読み込みや再読み込みが自動的に行われます。これにより、コード変更のたびにRailsサーバーを再起動しなくても済むので、アプリの構築に集中できます。

また、Railsアプリケーションでは、他のプログラミング言語で見られるような`require`ステートメントがほとんど使われていないことにも気付くでしょう。 Railsでは命名規則に基づいてファイルを自動的に`require`するので、アプリケーションコードの記述に集中できます。

詳しくは別ガイド『[Railsの自動読み込みと再読み込み](autoloading_and_reloading_constants.html)』を参照してください。

データベースモデルを作成する
-------------------------

Railsの[Active Record](active_record_basics.html)は、リレーショナルデータベースをRubyコードにマッピングする機能であり、テーブルやレコードの作成、更新、削除など、データベースを操作するための構造化クエリ言語（SQL）を生成するのに役立ちます。

このstoreアプリケーションでは、RailsのデフォルトであるSQLiteをリレーショナルデータベースとして使っています。

それでは、このRailsアプリケーションにデータベーステーブルを追加して、シンプルな eコマースストアに製品を追加できるようにしてみましょう。

```bash
$ bin/rails generate model Product name:string
```

このコマンドは、`string`型の`name`カラムを持つ`Product`という名前のモデルをデータベースで生成するようにRailsに指示します。他のカラム型を追加する方法についてはこの後で学習します。

コマンドを実行すると、ターミナルに次の内容が表示されます。

```bash
      invoke  active_record
      create    db/migrate/20240426151900_create_products.rb
      create    app/models/product.rb
      invoke    test_unit
      create      test/models/product_test.rb
      create      test/fixtures/products.yml
```

このコマンドは以下を行います。

1. `db/migrate`フォルダの下にマイグレーションファイルを作成。
2. `app/models/product.rb`というActive Recordモデルを作成。
3. このモデルで使うテストファイルとフィクスチャ（fixture）ファイルを作成。

NOTE: Railsのモデル名には英語の**単数形**を使います。これは、インスタンス化されたモデルはデータベース内の1件のレコードを表す（データベースに1個の製品（a product）を追加する）という考えに基づいています。

### データベースのマイグレーション

**マイグレーション**（migration）とは、データベースに対して行う一連の変更のことです。

マイグレーションを定義することで、データベースのテーブルやカラム、およびその他の属性を追加・変更・削除するためにデータベースを変更する方法を統一された形でRailsに指示します。
これにより、自分のコンピュータ上での開発中に行ったデータベース変更をトラッキングして、production環境に安全にデプロイできるようにします。

Railsが作成したマイグレーションをコードエディタで開いて、マイグレーションで何が行われるかを確認してみましょう。マイグレーションファイルは`db/migrate/<タイムスタンプ>_create_products.rb`に配置されます。

```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name

      t.timestamps
    end
  end
end
```

このマイグレーションは、Railsに`products`という新しいデータベーステーブルを作成するよう指示しています。

NOTE: モデル名は`Product`のように**単数形**を使いますが、データベーステーブル名は`products`のように**複数形**を使っている点にご注目ください。これは、データベースは各モデルの「すべての」インスタンスを保持する（つまり、製品の集まり（products）のデータベースを作成している）という考え方に基づいています。

次の`create_table`ブロックは、このデータベーステーブルで定義するカラムと型を定義します。

- `t.string :name`: `products`テーブルに`name`というカラムを作成し、型を`string`に設定するようRailsに指示します。

- `t.timestamps`: モデルに`created_at:datetime`と`updated_at:datetime`の2つのカラムを一度に定義するショートカットです。
  これらのカラムは、RailsのほとんどのActive Recordモデルで表示され、レコードの作成時や更新時にActive Recordによって自動的に値が設定されます。

### マイグレーションを実行する

データベースに対して行う変更を定義したら、以下のコマンドを使ってマイグレーションを実行します。

```bash
$ bin/rails db:migrate
```

この`bin/rails db:migrate`コマンドは、新しいマイグレーションをチェックしてデータベースに適用します。

実行結果は以下のような感じになります。

```bash
== 20240426151900 CreateProducts: migrating ===================================
-- create_table(:products)
   -> 0.0030s
== 20240426151900 CreateProducts: migrated (0.0031s) ==========================
```

TIP: 実行したマイグレーションに誤りがあった場合は、`bin/rails db:rollback`を実行することで直前のマイグレーションに戻せます。

Railsコンソール
-------------

`products`テーブルが作成されたので、Railsで操作できるようになりました。
さっそく試してみましょう。

ここでは、**Railsコンソール**と呼ばれる機能を使います。Railsコンソールは、Railsアプリケーションでコードを試すときに便利な対話型ツールです。

```bash
$ bin/rails console
```

上のRailsコンソールコマンドを実行すると、以下のようなプロンプトが表示されます。

```irb
Loading development environment (Rails 8.0.0)
store(dev)>
```

ここで入力した内容は、`Enter`を押すと実行されます。
それではRailsバージョンを出力してみましょう。

```irb
store(dev)> Rails.version
=> "8.0.0"
```

たしかに動きました！

Active Recordモデルの基礎
--------------------------

Railsのモデルジェネレーターを実行して`Product`モデルを作成すると、`app/models/product.rb`にファイルが作成されました。作成したファイルにある以下のクラスは、Active Recordを使ってデータベースの`products`テーブルとやり取りします。

```ruby
class Product < ApplicationRecord
end
```

この`Product`クラスにコードがないことに驚くかもしれません。Railsはこのモデルの定義をどうやって知るのでしょうか？

この`Product`モデルが使われると、Railsはデータベーステーブルでカラム名と型を照会し、これらの属性のコードを自動的に生成します。Railsは、定型コードを記述する手間を省いて、代わりにバックグラウンドで処理してくれるので、開発者はアプリケーションロジックに集中できます。

この`Product`モデルでどんなカラムを検出されるかを、Railsコンソールで確認しましょう。

Railsコンソールで以下のコマンドを実行します。

```irb
store(dev)> Product.column_names
```

すると、以下のように表示されるはずです。

```irb
=> ["id", "name", "created_at", "updated_at"]
```

Railsは上記のカラム情報をデータベースに要求し、その情報を用いて`Product`クラスの属性を動的に定義するので、開発者が個別の属性を手動で定義する必要はありません。これは、Railsを使うことで開発がいかに簡単になるかを示す一例です。

### レコードを作成する

Railsコンソールで以下のコードを実行すると、`Product`モデルの新しいレコードを作成できます。

```irb
store(dev)> product = Product.new(name: "T-Shirt")
=> #<Product:0x000000012e616c30 id: nil, name: "T-Shirt", created_at: nil, updated_at: nil>
```

この`product`変数は、`Product`モデルのインスタンスです。この時点ではまだデータベースに保存されていないため、`id`、`created_at`と`updated_at`のタイムスタンプはありません。

レコードをデータベースに保存するには、`save`を呼び出します。

```irb
store(dev)> product.save
  TRANSACTION (0.1ms)  BEGIN immediate TRANSACTION /*application='Store'*/
  Product Create (0.9ms)  INSERT INTO "products" ("name", "created_at", "updated_at") VALUES ('T-Shirt', '2024-11-09 16:35:01.117836', '2024-11-09 16:35:01.117836') RETURNING "id" /*application='Store'*/
  TRANSACTION (0.9ms)  COMMIT TRANSACTION /*application='Store'*/
=> true
```

`save`が呼び出されると、Railsはメモリ上にある属性を取得し、SQLの`INSERT`クエリを生成してこのレコードをデータベースに挿入します。

このとき、データベースレコードの`id`と、`created_at`タイムスタンプおよび`updated_at`タイムスタンプを用いて、メモリ上のオブジェクトも更新します。`product`変数の内容を表示してみれば、このことが確認できます。

```irb
store(dev)> product
=> #<Product:0x00000001221f6260 id: 1, name: "T-Shirt", created_at: "2024-11-09 16:35:01.117836000 +0000", updated_at: "2024-11-09 16:35:01.117836000 +0000">
```

`create`を使えば、1回の呼び出しでActive Recordオブジェクトのインスタンス化と保存を同時に実行できます。

```irb
store(dev)> Product.create(name: "Pants")
  TRANSACTION (0.1ms)  BEGIN immediate TRANSACTION /*application='Store'*/
  Product Create (0.4ms)  INSERT INTO "products" ("name", "created_at", "updated_at") VALUES ('Pants', '2024-11-09 16:36:01.856751', '2024-11-09 16:36:01.856751') RETURNING "id" /*application='Store'*/
  TRANSACTION (0.1ms)  COMMIT TRANSACTION /*application='Store'*/
=> #<Product:0x0000000120485c80 id: 2, name: "Pants", created_at: "2024-11-09 16:36:01.856751000 +0000", updated_at: "2024-11-09 16:36:01.856751000 +0000">
```

### レコードをクエリで取り出す

Active Recordモデルを使って、データベース内のレコードを検索することも可能です。

データベース内にある`Product`の全レコードを検索するには、`all`メソッドを使います。
これは**クラスメソッド**なので、以下のように`Product`クラスで直接呼び出せます（上記の`save`など、`Product`のインスタンスで呼び出すインスタンスメソッドとは異なります）。

```irb
store(dev)> Product.all
  Product Load (0.1ms)  SELECT "products".* FROM "products" /* loading for pp */ LIMIT 11 /*application='Store'*/
=> [#<Product:0x0000000121845158 id: 1, name: "T-Shirt", created_at: "2024-11-09 16:35:01.117836000 +0000", updated_at: "2024-11-09 16:35:01.117836000 +0000">,
 #<Product:0x0000000121845018 id: 2, name: "Pants", created_at: "2024-11-09 16:36:01.856751000 +0000", updated_at: "2024-11-09 16:36:01.856751000 +0000">]
```

これにより`SELECT` SQLクエリが生成され、`products`テーブルからすべてのレコードを読み込まれます。各レコードは自動的にActive Recordの`Product`モデルのインスタンスに変換されるため、Rubyから手軽に操作できます。

TIP: `all`メソッドが返す`ActiveRecord::Relation`オブジェクトは、配列に似たデータベースレコードのコレクションで、フィルタリングや並べ替えなどのデータベース操作を実行する機能を備えています。

### レコードのフィルタリングと並べ替え

データベースから受け取った結果をフィルタで絞り込みたい場合は、以下のように`where`メソッドでカラムごとにレコードをフィルタリングできます。

```irb
store(dev)> Product.where(name: "Pants")
  Product Load (1.5ms)  SELECT "products".* FROM "products" WHERE "products"."name" = 'Pants' /* loading for pp */ LIMIT 11 /*application='Store'*/
=> [#<Product:0x000000012184d858 id: 2, name: "Pants", created_at: "2024-11-09 16:36:01.856751000 +0000", updated_at: "2024-11-09 16:36:01.856751000 +0000">]
```

これにより、生成された`SELECT` SQLクエリに`WHERE`句も追加され、`"Pants"`にマッチする`name`を持つレコードがフィルタで絞り込まれます。同じ名前を持つレコードが複数返される可能性があるため、ここでも`ActiveRecord::Relation`が返されます。

`order(name: :asc)`メソッドを使うと、レコードを以下のように名前のアルファベット昇順で並べ替えられます。

```irb
store(dev)> Product.order(name: :asc)
  Product Load (0.3ms)  SELECT "products".* FROM "products" /* loading for pp */ ORDER BY "products"."name" ASC LIMIT 11 /*application='Store'*/
=> [#<Product:0x0000000120e02a88 id: 2, name: "Pants", created_at: "2024-11-09 16:36:01.856751000 +0000", updated_at: "2024-11-09 16:36:01.856751000 +0000">,
 #<Product:0x0000000120e02948 id: 1, name: "T-Shirt", created_at: "2024-11-09 16:35:01.117836000 +0000", updated_at: "2024-11-09 16:35:01.117836000 +0000">]
```

### レコードを検索する

特定のレコードを1件検索したい場合はどうすればよいでしょうか？

これを行うには、`find`クラスメソッドでIDを指定する形で、1件のレコードを検索します。以下のコードは、`find`メソッドにID`1`を指定して呼び出しています。

```irb
store(dev)> Product.find(1)
  Product Load (0.2ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 1 LIMIT 1 /*application='Store'*/
=> #<Product:0x000000012054af08 id: 1, name: "T-Shirt", created_at: "2024-11-09 16:35:01.117836000 +0000", updated_at: "2024-11-09 16:35:01.117836000 +0000">
```

これにより、`SELECT`クエリが生成されますが、渡されたID `1`にマッチする`id`カラムを`WHERE`で指定しています。また、返すレコードを1件のみに絞るため、`LIMIT 1`も追加されています。

ここでは、データベースからレコードを1件だけ取得したいので、`ActiveRecord::Relation`ではなく`Product`モデルのインスタンスを取得します。

### レコードを更新する

レコードを更新するには、「`update`を使う」「属性を割り当ててから`save`を呼び出す」という2つの方法が使えます。

`Product`モデルのインスタンスで`update`を呼び出し、新しい属性のハッシュを渡してデータベースに保存できます。これにより、「属性の割り当て」「バリデーションの実行」「変更のデータベースへの保存」を1回のメソッド呼び出しでまとめて実行できます。

```irb
store(dev)> product = Product.find(1)
store(dev)> product.update(name: "Shoes")
  TRANSACTION (0.1ms)  BEGIN immediate TRANSACTION /*application='Store'*/
  Product Update (0.3ms)  UPDATE "products" SET "name" = 'Shoes', "updated_at" = '2024-11-09 22:38:19.638912' WHERE "products"."id" = 1 /*application='Store'*/
  TRANSACTION (0.4ms)  COMMIT TRANSACTION /*application='Store'*/
=> true
```

これにより、データベース内の製品名が`"T-Shirt"`から`"Shoes"`に更新されます。
`Product.all`を再度実行してこれを確認してみましょう。

```irb
store(dev)> Product.all
```

製品名はShoesとPantsの2つになっていることがわかります。

```irb
  Product Load (0.3ms)  SELECT "products".* FROM "products" /* loading for pp */ LIMIT 11 /*application='Store'*/
=>
[#<Product:0x000000012c0f7300
  id: 1,
  name: "Shoes",
  created_at: "2024-12-02 20:29:56.303546000 +0000",
  updated_at: "2024-12-02 20:30:14.127456000 +0000">,
 #<Product:0x000000012c0f71c0
  id: 2,
  name: "Pants",
  created_at: "2024-12-02 20:30:02.997261000 +0000",
  updated_at: "2024-12-02 20:30:02.997261000 +0000">]
```

2番目の方法として、属性を割り当て、変更をバリデーションしてデータベースに保存する準備を終えてから、`save`を呼び出す方法も使えます。

今度は、`"Shoes"`という製品名を`"T-Shirt"`に戻してみましょう。

```irb
store(dev)> product = Product.find(1)
store(dev)> product.name = "T-Shirt"
=> "T-Shirt"
store(dev)> product.save
  TRANSACTION (0.1ms)  BEGIN immediate TRANSACTION /*application='Store'*/
  Product Update (0.2ms)  UPDATE "products" SET "name" = 'T-Shirt', "updated_at" = '2024-11-09 22:39:09.693548' WHERE "products"."id" = 1 /*application='Store'*/
  TRANSACTION (0.0ms)  COMMIT TRANSACTION /*application='Store'*/
=> true
```

### レコードを削除する

データベースからレコードを削除するには、`destroy`メソッドを使います。

```irb
store(dev)> product.destroy
  TRANSACTION (0.1ms)  BEGIN immediate TRANSACTION /*application='Store'*/
  Product Destroy (0.4ms)  DELETE FROM "products" WHERE "products"."id" = 1 /*application='Store'*/
  TRANSACTION (0.1ms)  COMMIT TRANSACTION /*application='Store'*/
=> #<Product:0x0000000125813d48 id: 1, name: "T-Shirt", created_at: "2024-11-09 22:39:38.498730000 +0000", updated_at: "2024-11-09 22:39:38.498730000 +0000">
```

これにより、データベースから`"T-Shirt"`製品が削除されました。`Product.all`でこれを確認すると、パンツのみが返されることが分かります。

```irb
store(dev)> Product.all
  Product Load (1.9ms)  SELECT "products".* FROM "products" /* loading for pp */ LIMIT 11 /*application='Store'*/
=>
[#<Product:0x000000012abde4c8
  id: 2,
  name: "Pants",
  created_at: "2024-11-09 22:33:19.638912000 +0000",
  updated_at: "2024-11-09 22:33:19.638912000 +0000">]
```

### バリデーション

Active Recordは、データベースに挿入したデータが特定のルールに準拠していることを保証するための**バリデーション**（validation: 検証）機能を提供しています。

すべての製品に`name`カラムが存在することを保証するために、`Product`モデルに`presence`バリデーションを追加してみましょう。

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  validates :name, presence: true
end
```

Railsは開発中にコードの変更を自動的に再読み込みすると冒頭で説明したことを思い出すかもしれません。
ただし、コードを更新したときにコンソールが実行中の場合は、コンソールから手動で更新する必要があります。それでは、`reload!`を実行して更新を反映してみましょう。

```irb
store(dev)> reload!
Reloading...
```

今度は、Railsコンソールでわざと`name`を指定せずに`Product`インスタンスを作成してみましょう。

```irb
store(dev)> product = Product.new
store(dev)> product.save
=> false
```

今回は、`name`属性が指定されていないため、`save`は`false`を返します。

Railsは、作成・更新・保存の操作中にバリデーションを自動的に実行して、有効な入力であることを保証します。

バリデーションによって生成されたエラーのリストを表示するには、以下のようにインスタンスで`errors`を呼び出します。

```irb
store(dev)> product.errors
=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=name, type=blank, options={}>]>
```

これは、存在チェックのエラーを詳しく知らせてくれる`ActiveModel::Errors`オブジェクトを返します。

また、ユーザーインターフェイスに表示できるわかりやすいエラーメッセージを生成することも可能です。

```irb
store(dev)> product.errors.full_messages
=> ["Name can't be blank"]
```

次は、この製品をブラウザで表示するためのWebインターフェースを構築しましょう。

Railsコンソールはひとまずおしまいにします。`exit`を実行してコンソールを終了できます。

Railsのリクエストの流れ
---------------------------------

Railsで「Hello」を表示するには、、少なくとも「**ルーティング**」と「**コントローラ**」、そしてコントローラに付随する「**アクション**」と「**ビュー**」を作成する必要があります。

- ルーティング（route）: 受け取ったリクエストを、適切なコントローラのアクションに対応付けます。
- コントローラアクション（controller action）: リクエストを処理し、ビューに表示するデータを準備します。
- ビュー（view）: データを表示するためのテンプレートです。

これらは、実装の観点では以下のようになります。

ルーティングはRubyの[DSL（ドメイン固有言語）](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)で記述されたルールです。
コントローラは普通のRubyクラスであり、そのpublicメソッドがアクションになります。
ビューはテンプレートであり、通常はHTMLとRubyを組み合わせて記述されます。

以上はごく簡単な説明ですが、次にこれらの各ステップについてさらに詳しく説明します

ルーティング
------

Railsのルーティング（route、routing）はURLを構成する要素の1つであり、受信したHTTPリクエストを適切なコントローラとアクションに転送することでリクエストの処理方法を決定します。

まず、URLとHTTPリクエストメソッドについて簡単に復習しましょう。

### URLの構成要素

URLがどのような要素から構成されているかを詳しく見てみましょう。

```
http://example.org/products?sale=true&sort=asc
```

上のURLの各要素には、以下のような名前があります。

- `https`の部分は**プロトコル**（protocol）と呼ばれます
- `example.org`の部分は**ホスト**（host）と呼ばれます
- `/products`の部分は**パス**（path）と呼ばれます
- `?sale=true&sort=asc`の部分は**クエリパラメータ**（query parameters）と呼ばれます

### HTTPメソッドとその目的

HTTPリクエストは、特定のURLに対してサーバーが実行すべきアクションを指示するときにHTTPメソッド（HTTP verb: HTTP動詞とも呼ばれます）を利用します。

最も一般的なHTTPメソッドは次のとおりです。

- `GET`リクエスト:
  特定のURLのデータを取得するようサーバーに指示します（ページの読み込みやレコードの取得など）。
- `POST`リクエスト:
  処理を実行するためのデータをURLに送信します（通常は新しいレコードを作成します）。
- `PUT`または`PATCH`リクエスト:
  既存のレコードを更新するためのデータをURLに送信します。
- `DELETE`リクエスト:
  URLに送信されると、レコードを削除するようサーバーに指示します。

### Railsのルーティング

Railsにおけるルーティングは、HTTPメソッドとURLパスをペアにしたコード行を指します。
ルーティングは、どの`controller`と`action`でリクエストに応答すべきかをRailsに指示します。

Railsでルーティングを定義するには、コードエディタを再び開いて、`config/routes.rb`ファイル内のルーティングに、以下の`get`で始まる行を追加します。

```ruby
Rails.application.routes.draw do
  # （省略）
  get "/products", to: "products#index"  # この行を追加
end
```

このルーティングは、`/products`パスへの`GET`リクエストを探索するようRailsに指示します。この例では、リクエストのルーティング先として`"products#index"`を指定しています。

マッチするリクエストが見つかると、Railsはそのリクエストを`ProductsController`というコントローラ内の`index`アクションに送信します。Railsはこのようにしてリクエストを処理し、ブラウザにレスポンスを返します。

上のルーティングでは、「プロトコル」「ドメイン」「クエリパラメータ」の指定が不要であることに気付くでしょう。その理由は、リクエストは基本的にプロトコルとドメインによってサーバーに確実に届くためです。Railsはリクエストを取得すると、定義済みのルーティング基づいて、リクエストに応答するためのパスを認識します。

なお、クエリパラメータは、Railsがリクエストに適用できるオプションのようなもので必須ではなく、通常はコントローラでデータをフィルタリングするときに使われます。

![Railsのルーティングの流れ](images/getting_started/routing_light.jpg)

別の例も見てみましょう。
前述のルーティングの下に、以下の行を追加します。

```ruby
post "/products", to: "products#create"
```

ここでは、`/products`パスへの`POST`リクエストを受け取ったら、`ProductsController`の`create`アクションでリクエストを処理するようRailsに指示しています。

ルーティングでは、特定のパターンを持つURLにマッチさせる必要が生じる場合もあります。
では以下のルーティングは、どのように機能するかおわかりでしょうか？

```ruby
get "/products/:id", to: "products#show"
```

このルーティングのパスには`:id`が含まれています。これは**パラメータ**（parameter、paramsとも）と呼ばれ、後でリクエストを処理するときに使うURLの一部がここにキャプチャされます。

たとえばユーザーが`/products/1`というパスにアクセスすると、`:id`パラメータが`1`に設定され、コントローラアクションでIDが1の製品レコードを検索して表示できるようになります。
`/products/2`は同様に、IDが2の製品を表示するのに使えます。

ルーティングのパラメータには、整数以外のものも使えます。

たとえば、さまざまな記事を含むブログサービスでは、以下のルーティングで`/blog/hello-world`とマッチするようになります。

```ruby
get "/blog/:title", to: "blog#show"
```

以下のルーティングでは、`/blog/hello-world`から`hello-world`というパラメータを`slug`としてキャプチャし、このパラメータにマッチするタイトルのブログ投稿を検索できるようになります。

```ruby
get "/blog/:slug", to: "blog#show"
```

#### CRUDのルーティング

[リソース](https://ja.wikipedia.org/wiki/Representational_State_Transfer#%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9)への操作で通常必要となる一般的な操作は、「作成」「読み取り」「更新」「削除」の4つであり、[CRUD](https://ja.wikipedia.org/wiki/CRUD)と呼ばれます。

これは、7つの一般的なコントローラアクションに相当します。

* `index`: すべてのレコードを表示します
* `new`: 新しいレコード1件を作成するためのフォームをレンダリングします
* `create`: `new`のフォーム送信を処理し、エラーを処理してレコードを1件作成します
* `show`: 指定のレコード1件をレンダリングして表示します
* `edit`: 指定のレコード1件を更新するためのフォームをレンダリングします
* `update`: `edit`のフォーム送信を処理し、エラーを処理してレコードを1件更新します
* `destroy`: 指定のレコード1件を削除します

これらのCRUDアクションのルーティングは、以下のように書くことで追加することも一応可能です。

```ruby
get "/products", to: "products#index"

get "/products/new", to: "products#new"
post "/products", to: "products#create"

get "/products/:id", to: "products#show"

get "/products/:id/edit", to: "products#edit"
patch "/products/:id", to: "products#update"
put "/products/:id", to: "products#update"

delete "/products/:id", to: "products#destroy"
```

#### リソースルーティング

これら8つのルーティングを毎回入力するのは冗長なので、Railsではルーティングを1行で定義できるショートカットを提供しています。

上記のルーティングを以下の1行に置き換えて、上と同じCRUDアクションをすべて作成できるようにしましょう。

```ruby
resources :products
```

TIP: CRUDアクションの一部しか使わない場合は、必要なアクションだけを正確に指定し、使わないアクションは無効にしておきましょう。詳しくは[ルーティングガイド][]を参照してください。

[ルーティングガイド]:
  https://railsguides.jp/routing.html#%E4%BD%9C%E6%88%90%E3%81%95%E3%82%8C%E3%82%8B%E3%83%AB%E3%83%BC%E3%83%86%E3%82%A3%E3%83%B3%E3%82%B0%E3%82%92%E5%88%B6%E9%99%90%E3%81%99%E3%82%8B

### ルーティングコマンド

Railsには、アプリケーションが応答するルーティングをすべて表示するコマンドが用意されています。

ターミナルを開いて以下のコマンドを実行します。

```bash
$ bin/rails routes
```

`resources :products`で生成されたルーティングが以下のように表示されます。

```
                                  Prefix Verb   URI Pattern                                                                                       Controller#Action
                                products GET    /products(.:format)                                                                               products#index
                                         POST   /products(.:format)                                                                               products#create
                             new_product GET    /products/new(.:format)                                                                           products#new
                            edit_product GET    /products/:id/edit(.:format)                                                                      products#edit
                                 product GET    /products/:id(.:format)                                                                           products#show
                                         PATCH  /products/:id(.:format)                                                                           products#update
                                         PUT    /products/:id(.:format)                                                                           products#update
                                         DELETE /products/:id(.:format)                                                                           products#destroy
```

表示されるルーティングには、上の他にもヘルスチェックなどの他の組み込みのRails機能によるルーティングが含まれているのがわかります。

TIP: 訳注: 開発中のRailsサーバーでは、`http://localhost:3000/rails/info/routes`にブラウザでアクセスすることでルーティング情報を表示できます。

コントローラとアクション
---------------------

製品のルーティングを定義したので、次はコントローラとアクションを実装して、これらのURLへのリクエストを処理できるようにしましょう。

以下の`bin/rails generate`コマンドは、`index`アクションを含む`ProductsController`を生成します。ルーティングは既に設定したので、`--skip-routes`フラグでジェネレータでのルーティング生成部分をスキップできます。

```bash
$ bin/rails generate controller Products index --skip-routes
      create  app/controllers/products_controller.rb
      invoke  erb
      create    app/views/products
      create    app/views/products/index.html.erb
      invoke  test_unit
      create    test/controllers/products_controller_test.rb
      invoke  helper
      create    app/helpers/products_helper.rb
      invoke    test_unit
```

このコマンドを実行すると、コントローラ用に以下のさまざまなファイルが生成されます。

* コントローラファイル自身（`products_controller.rb`）
* 生成したコントローラで利用するビューを保存するフォルダ（`app/views/products/`）
* コントローラ生成時に指定したアクションに対応するビューファイル（`index.html.erb`）
* このコントローラ用のテストファイル（`products_controller_test.rb`）
* ビューのロジックを切り出して配置するためのヘルパーファイル（`products_helper.rb`）

`app/controllers/products_controller.rb`で定義されている`ProductsController`をエディタで開くと、以下のような感じになっているはずです。

```ruby
class ProductsController < ApplicationController
  def index
  end
end
```

NOTE: `products_controller.rb`というファイル名は、このファイルで定義されている`ProductsController`というクラス名を小文字に変えてアンダースコア区切りに変更したものであることに気付くかもしれません。この命名パターンを守ることで、他の言語で見られるような`require`を使わなくても、Railsがコードを自動的に読み込めるようになります。

ここでの`index`メソッドはアクションです。メソッドの中身は空ですが、メソッドが空の場合は、デフォルトでアクション名と一致する名前のテンプレートをレンダリングするようになっているので問題ありません。

`index`アクションを実行すると、`app/views/products/index.html.erb`をレンダリングします。このファイルをコードエディタで開くと、レンダリングされるHTMLが以下のように表示されます。

```erb
<h1>Products#index</h1>
<p>Find me in app/views/products/index.html.erb</p>
```

### リクエストを作成する

作成した結果をブラウザで確認してみましょう。

まず、ターミナルで`bin/rails server`を実行してRailsサーバーを起動します。
次に、ブラウザで`http://localhost:3000`を開くと、Railsのウェルカムページが表示されます。

ブラウザで`http://localhost:3000/products`を開くと、Railsは製品の`index`ページのHTMLをレンダリングします。

このときの処理の流れは以下のようになります。

1. ブラウザが`/products`パスへのリクエストを送信すると、ルーティングは`products#index`にマッチします。
2. 次にRailsは、このリクエストを`ProductsController`に送信して`index`アクションを呼び出します。
3. `index`アクションは空なので、Railsはこのコントローラアクションに一致する`app/views/products/index.html.erb`テンプレートをレンダリングして、ブラウザにレスポンスを返します。

なお、`config/routes.rb`ファイルに以下の行を追加すると、rootパスにアクセスしたときのルーティングで`Products`の`index`アクションをレンダリングするようにRailsに指示できます。

```ruby
root "products#index"
```

これで、`http://localhost:3000`にアクセスすると、Railsが`Products#index`をレンダリングするようになります。

### インスタンス変数

さらに先に進んで、データベースにあるレコードをいくつかレンダリングしてみましょう。

`index`アクションを更新して以下のようにデータベースクエリを追加し、それをインスタンス変数に割り当ててみましょう。Railsのコントローラでは、ビューにデータを渡すときにインスタンス変数（`@`で始まる変数）が使われます。

```ruby
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end
end
```

次に、`app/views/products/index.html.erb`のビューテンプレートファイル内にあるHTMLを以下のERBコードに置き換えます。

```erb
<%= debug @products %>
```

[ERB](https://docs.ruby-lang.org/ja/latest/class/ERB.html)はEmbedded Rubyの略で、Rubyコードを実行してRailsでHTMLを動的に生成できるようにします。

`<%= %>`タグは、その内側に書いたRubyコードを実行して戻り値をブラウザで出力するようERBに指示します。この場合、`@products`を受け取ったものが`debug`でYAMLに変換され、YAMLが出力されます。

ブラウザで`http://localhost:3000/`を更新すると、出力結果が変更されたことがわかります。表示されているのは、データベース内のレコードがYAML形式に変換されたものです。

`debug`ヘルパーは、デバッグで役立つように変数をYAML形式で出力します。
たとえば、コントローラで複数形の`@products`のつもりでうっかり単数形の`@product`を書いてしまった場合、変数がコントローラで正しく設定されていないことを突き止めるのに可能性があります。

TIP: その他に利用可能なヘルパーについて詳しくは[Action Viewヘルパーガイド](action_view_helpers.html)を参照してください。

次は、ビューにすべての製品名がリスト表示されるようにしてみましょう。
`app/views/products/index.html.erb`を以下のように更新します。

```erb
<h1>Products</h1>

<div id="products">
  <% @products.each do |product| %>
    <div>
      <%= product.name %>
    </div>
  <% end %>
</div>
```

ERB内のコードは、`ActiveRecord::Relation`オブジェクトである`@products`内の各製品をループし、製品名を含む`<div>`タグをレンダリングします。

ここでも新しいERBタグが使われています。
`<% %>`の中に書いたRubyコードは実行時に評価されますが、戻り値をブラウザに出力しない点が`<%= %>`と異なります。これにより、そのままだとHTMLに不要な配列を出力する`@products.each`の出力が無視されるようになります。

### CRUDアクション

次は、個別の製品を1件ずつ表示できるようにする必要があります。これは、リソースを読み取るためのCRUDのR（Read）に相当します。

製品へのルーティングは、既に`resources :products`ルーティングでまとめて定義してあるので、`products#show`を指すルーティングとして`/products/:id` が生成されるようになっています。

次に、これに対応する`show`アクションを`ProductsController`に追加して、呼び出されたときの振る舞いを定義する必要があります。

### 個別の製品を表示する

`ProductsController`をエディタで開いて、以下のように`show`アクションを追加します。

```ruby
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end
end
```

`index`アクションのときは、複数の製品を読み込むために複数形の`@products`を使いましたが 、この`show`アクションは、データベースから1件のレコードを読み込む（つまり1件の製品（one product）を表示する）ので、**単数形の**`@product`を定義します。

データベースにクエリをかけるのに使うリクエストパラメータには、`params`でアクセスします。
この場合、`/products/:id`ルーティングの`:id`が使われます。
ユーザーがブラウザで`/products/1`にアクセスすると、`params`ハッシュに`{id: 1}`が含まれるので、`show`アクションで`Product.find(1)`を呼び出すと、IDが`1`の製品がデータベースから読み込まれます。

次に、`show`アクションに対応したビューが必要です。`ProductsController`はRailsの命名規則に沿って、`app/views/`フォルダの下の`products/`という名前のサブフォルダにビューファイルが置かれていることを想定しています。

`show`アクションが必要としている`app/views/products/show.html.erb`ファイルをエディタで作成して、以下の内容を追加します。

```erb
<h1><%= @product.name %></h1>

<%= link_to "Back", products_path %>
```

indexページに個別のshowページへのリンクを追加して、クリックして個別の製品ページに移動できるようにしておくと便利です。

そこで、`app/views/products/index.html.erb`ビューを以下のように更新して、新しく作ったshowページへのリンクを追加しましょう。`show`アクションへのパスには`<a>`タグを利用できます。

```erb
<h1>Products</h1>

<div id="products">
  <% @products.each do |product| %>
    <div>
      <a href="/products/<%= product.id %>">
        <%= product.name %>
      </a>
    </div>
  <% end %>
</div>
```

ブラウザでindexページを再読み込みすると、期待通りにリンクが表示されたことがわかります。
しかしこれはさらに改善できます。

Railsは、パスとURLを生成するためのヘルパーメソッドを提供します。
`bin/rails routes`を実行すると以下のように表示されるPrefix列の`products`や`product`は、RubyコードでURLを生成できるヘルパーメソッド名に対応します。

```
                                  Prefix Verb   URI Pattern                                                                                       Controller#Action
                                products GET    /products(.:format)                                                                               products#index
                                 product GET    /products/:id(.:format)                                                                           products#show
```

これらのルーティングプレフィックスに対応するヘルパーメソッドは、以下のようになります。

* `products_path`: `"/products"`というパスを生成する
* `products_url`: `"http://localhost:3000/products"`というURLを生成する
* `product_path(1)`: `"/products/1"`というパスを生成する
* `product_url(1)`: `"http://localhost:3000/products/1"`というURLを生成する

`プレフィックス名_path`は、ブラウザが現在のドメインであると理解する相対パスを返します。

`プレフィックス名_url`は、「プロトコル」「ホスト」「ポート番号」を含む完全なURLを返します。

URLヘルパーは、ブラウザの外部で表示されるメールをレンダリングする場合に便利です。

URLヘルパーを`link_to`ヘルパーによる`<a>`タグ生成と組み合わせると、タグを直接書かずにRubyだけできれいにリンクを生成できるようになります。`link_to`には、リンクの表示名（ここでは`product.name`）と、`href`属性で使うリンク先のパスまたはURL（ここでは`product`）を渡せます。

これらのヘルパーを使って`app/views/products/index.html.erb`をリファクタリングすると、以下のように簡潔なビューコードになります。

```erb
<h1>Products</h1>

<div id="products">
  <% @products.each do |product| %>
    <div>
      <%= link_to product.name, product %>
    </div>
  <% end %>
</div>
```

### 製品を作成する

これまでは製品をRailsコンソールで作成するしかありませんでしたが、今度はブラウザで製品を作成できるようにしましょう。

製品を作成するには、以下の2つのアクションを作成する必要があります。

1. `new`アクション: 製品情報を収集するためのフォームを作成する
2. `create`アクション: 製品を保存してエラーをチェックする

まずはコントローラで`new`アクションを作成しましょう。

```ruby
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end
end
```

`new`アクションは、フォームフィールドの表示で使う新しい`Product`をインスタンス化します。

次は`app/views/products/index.html.erb`を以下のように更新して、`new`アクションにリンクできるようにします。

```erb
<h1>Products</h1>

<%= link_to "New product", new_product_path %>

<div id="products">
  <% @products.each do |product| %>
    <div>
      <%= link_to product.name, product %>
    </div>
  <% end %>
</div>
```

`new`アクションに対応する`app/views/products/new.html.erb`ビューテンプレートを以下の内容で作成して、新しい`Product`のフォームをレンダリングできるようにします。

```erb
<h1>New product</h1>

<%= form_with model: @product do |form| %>
  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

この`new.html.erb`ビューでは、Railsの`form_with`ヘルパーを製品作成用のHTMLフォーム生成に利用しています。この`form_with`ヘルパーは、**フォームビルダー**を用いてCSRFトークン生成などの処理を行い、`model:`で指定されたものに基づいてURLを生成するとともに、送信ボタンのテキストにモデル名を反映することまで行います。

このページをブラウザで開いてソースを表示すると、フォームのHTMLは以下のようになります。

```html
<form action="/products" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="UHQSKXCaFqy_aoK760zpSMUPy6TMnsLNgbPMABwN1zpW-Jx6k-2mISiF0ulZOINmfxPdg5xMyZqdxSW1UK-H-Q" autocomplete="off">

  <div>
    <label for="product_name">Name</label>
    <input type="text" name="product[name]" id="product_name">
  </div>

  <div>
    <input type="submit" name="commit" value="Create Product" data-disable-with="Create Product">
  </div>
</form>
```

Railsのフォームビルダーによって、セキュリティ用のCSRFトークンやUTF-8サポート用の`accept-charset="UTF-8"`属性がフォームに組み込まれ、個別の入力フィールド名が設定され、`Create Product`送信ボタンも無効な状態で追加されています。

フォームビルダーに新しい`Product`インスタンスを渡したので、新規レコード作成用のデフォルトルーティングである`/products`パスに`POST`リクエストを送信するように構成されたフォームが、自動的に生成されました。

ここから送信されるフォームを処理するには、まずコントローラに`create`アクションを以下のように実装する必要があります。

```ruby
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def product_params
      params.expect(product: [ :name ])
    end
end
```

#### Strong Parameters

`create`アクションはフォームから送信されたデータを処理しますが、セキュリティのためにパラメータをフィルタリングしておかなければなりません。ここで役に立つのが、privateメソッドとして追加した`product_params`メソッドです。

TIP: 訳注: メソッド名の`product`の部分はモデル名と同じ単数形にするのが慣例です）。

`product_params`メソッドは、リクエストで受け取ったパラメータを検査して、パラメータの配列を値として持つ`:product`というキーが必ず存在することを保証します。ここでは、製品に許可されているパラメータは`:name`のみなので、これ以外のどんなパラメータをRailsに渡しても無視されます（エラーにはなりません）。これにより、アプリケーションをハッキングしようとする悪意のあるユーザーからアプリケーションが保護されます。

詳しくは[Strong Parameter](action_controller_overview.html#strong-parameters)を参照してください。

#### エラー処理

`product_params`を使ってこれらのパラメータを新しい`Product`に割り当てたら、データベースへの保存を試みる準備が整います。`@product.save`は、バリデーションを実行してレコードをデータベースに保存するようActive Recordに指示します。

`save`が成功すると、新しい製品のshowページにリダイレクトします。`redirect_to`に Active Recordオブジェクトを渡すと、そのレコードの`show`アクションへのパスが生成されます。

```ruby
redirect_to @product
```

上を実行すると、`@product`は`Product`モデルのインスタンスなので、リダイレクト用に`"/products/2"`パスを生成します。このとき、パス内ではモデル名`Product`を複数形の`products`にしたうえで、オブジェクトID `2`を末尾に追加します。

`save`が失敗して、レコードが有効にならなかった場合、同じフォームを再レンダリングして、ユーザーが無効なデータを修正できるようにします。`create`アクションの`else`では`render :new`をレンダリングするように指示しています。

Railsは`Products`コントローラにいることを認識しているので、`app/views/products/new.html.erb`ビューテンプレートをレンダリングする必要があります。

`create`アクションでは`@product`変数が設定済みなので、`@product`をデータベースに保存できなかった場合でも、このビューテンプレートを再度レンダリングするとフォームに`Product`データが自動的に入力されます。

また、HTTPステータスを[422 Unprocessable Entity][422]に設定して、ブラウザにこの`POST`リクエストが失敗したことを伝えて、それに応じた処理に備えます。

[422]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Status/422

### 製品を編集する

レコードを編集する処理は、レコードを作成する処理と非常に似ています。レコード作成では`new`アクションと`create`アクションを使いましたが、レコード編集では代わりに`edit`アクションと`update`アクションを使います。

コントローラで以下のコードを実装してみましょう。

```ruby
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to @product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def product_params
      params.expect(product: [ :name ])
    end
end
```

次に、`app/views/products/show.html.erb`ビューテンプレートにEditページへのリンクを追加します。

```erb
<h1><%= @product.name %></h1>

<%= link_to "Back", products_path %>
<%= link_to "Edit", edit_product_path(@product) %>
```

#### `before_action`コールバックでコードをDRYにする

`edit`アクションと`update`アクションは、`show`と同様に既存のデータベースレコードが存在している必要があります。`before_action`を使うことで、そのための同じコードの重複を排除できます。

`before_action`を使うと、アクション間で共有されているコードを抽出して、アクションの**直前**に実行できます。

上のコントローラでは、`@product = Product.find(params[:id])`という同じコードが`show`、`edit`、`update`という3つの異なるメソッドで定義されています。このクエリを`set_product`というbeforeアクションに抽出しておけば、3つのアクションで同じコードを書かずに済むのでコードが簡潔になります。

これは、DRY（Don't Repeat Yourself: 繰り返しを避けよ）原則が実際に機能している良い例です。

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update ]

  def index
    @products = Product.all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.expect(product: [ :name ])
    end
end
```

#### ビューをパーシャルに切り出す

新しい製品を作成するためのフォームは既に作成しましたが、このフォームを編集や更新のフォームでも再利用できたら便利だと思いませんか？これは、複数の場所でビューを再利用できるようにする**パーシャル**（partial）という機能を使ってフォームを`app/views/products/_form.html.erb`というパーシャルファイルに切り出すことで実現できます。

パーシャルのファイル名は、これがパーシャルであることを示すためにアンダースコア`_`で始まります。

それと同時に、ビューで使われているインスタンス変数をすべてローカル変数に置き換えたいと思います。ローカル変数は、パーシャルをレンダリングするときに定義できます。これを行うには、パーシャル内の`@product`を以下のように`product`に置き換えます。

```erb
<%= form_with model: product do |form| %>
  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

TIP: ローカル変数を使うと、値だけが異なるパーシャルを同じページで繰り返し再利用できるようになります。これは、indexページのように多数のアイテムのリストをレンダリングするときに便利です。

作成したこのパーシャルを`app/views/products/new.html.erb`ビューで使うには、フォームの部分を以下のようにパーシャルの`render`呼び出しに置き換えます。

```erb
<h1>New product</h1>

<%= render "form", product: @product %>
<%= link_to "Cancel", products_path %>
```

Editビューも、フォームの`_form.html.erb`パーシャルのおかげで、Newビューとほぼ同じように書けます。

以下の内容で`app/views/products/edit.html.erb`を作成しましょう。

```erb
<h1>Edit product</h1>

<%= render "form", product: @product %>
<%= link_to "Cancel", @product %>
```

ビューのパーシャルについて詳しくは、[Action Viewガイド](action_view_overview.html#パーシャル)を参照してください。

### 製品を削除する

実装が必要な最後の機能は、製品の削除です。
`DELETE /products/:id`リクエストを処理するために、`ProductsController`に`destroy`アクションを追加しましょう。

`before_action :set_product`コールバックに`destroy`を追加すると、他のアクションと同じ方法で`@product`インスタンス変数を設定できるようになります。

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = Product.all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path
  end

  private
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.expect(product: [ :name ])
    end
end
```

製品を削除できるようにするには、`app/views/products/show.html.erb`で以下のようにDeleteボタンを追加する必要があります。

```erb
<h1><%= @product.name %></h1>

<%= link_to "Back", products_path %>
<%= link_to "Edit", edit_product_path(@product) %>
<%= button_to "Delete", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
```

`button_to`は、Deleteというテキストが表示されたボタンを1つ持つフォームを生成します。このボタンをクリックすると、フォームが`/products/:id`に`DELETE`リクエストとして送信され、コントローラの`destroy`アクションがトリガーされます。

なお、`turbo_confirm`データ属性は、フォームを送信する前にユーザーに確認ダイアログを表示するようにTurboというJavaScriptライブラリに指示します。これについては、後ほど詳しく説明します。

認証機能を追加する
---------------------

今のままでは誰でも製品を編集・削除できてしまうので、安全ではありません。製品管理でユーザー認証を必須にすることで、セキュリティを強化しましょう。

ここでは、Railsに付属している認証機能ジェネレータが利用できます。この認証機能ジェネレータを使って、`User`モデルと`Session`モデル、アプリケーションにログインするために必要なコントローラとビューを作成できます。

再びターミナルを開いて、以下の認証機能ジェネレータコマンドを実行します。

```bash
$ bin/rails generate authentication
```

続いて以下のマイグレーションを実行し、`User`モデル用の`users`テーブルと、`Session`モデル用の`sessions`テーブルをデータベースに追加します。

```bash
$ bin/rails db:migrate
```

ユーザーを作成するために、Railsコンソールを開きます。

```bash
$ bin/rails console
```

Railsコンソールでユーザーを作成するには、`User.create!`メソッドを実行します。以下の例の通りでなくても構わないので、独自のメールアドレスやパスワードを自由に使えます。

```irb
store(dev)> User.create! email_address: "you@example.org", password: "s3cr3t", password_confirmation: "s3cr3t"
```

Railsコンソールを終了し、ジェネレータが追加した`bcrypt` gemを反映するために以下のコマンドを実行してRailsサーバーを再起動します（BCryptは認証用のパスワードを安全にハッシュ化するのに使われます）。

```bash
$ bin/rails server
```

ブラウザでRailsアプリを開くと、どのページにアクセスしてもユーザー名とパスワードの入力を求められるようになります。

`http://localhost:3000/products/new`をブラウザで開いて、`User`レコードの作成時に入力したメールアドレスとパスワードを入力してみましょう。

正しいユーザー名とパスワードを入力するとページにアクセスできるようになります。また、ブラウザは今後のリクエストに備えてこうしたcredential（認証情報）を保存するので、ページビューを移動するたびに入力する必要はありません。

### ログアウト機能を追加する

アプリケーションからログアウトするためのボタンを`app/views/layouts/application.html.erb`レイアウトファイルの冒頭に追加しましょう。このレイアウトには、ヘッダーやフッターなど、すべてのページで使うHTMLを配置します。

以下のように、`<body>`タグ内にホームへのリンクとログアウトボタンを含む小さな`<nav>`セクションを追加し、Rubyの`yield`メソッドを`<main>`タグで囲みます。

```erb
<!DOCTYPE html>
<html>
  <!-- （省略） -->
  <body>
    <nav>
      <%= link_to "Home", root_path %>
      <%= button_to "Log out", session_path, method: :delete if authenticated? %>
    </nav>

    <main>
      <%= yield %>
    </main>
  </body>
</html>
```

ユーザーが認証済みの場合にのみ、Log outボタンが表示されます。
Log outボタンをクリックすると、`session_path`に`DELETE`リクエストが送信されて、ユーザーがログアウトします。

### 認証なしのアクセスも許可する

ただし、ストアの製品indexページとshowページは誰でもアクセスできるようにしておく必要があります。Railsの認証ジェネレータは、デフォルトではすべてのページへのアクセスを認証済みユーザーのみに制限します。

ゲストが製品を表示できるようにするには、コントローラで以下のように認証なしのアクセスを許可します。

```ruby
class ProductsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  # （省略）
end
```

ログアウトしてから再び製品のindexページとshowページにアクセスし、認証なしでアクセスできるかどうかを確認してみてください。

### 認証済みユーザーにだけリンクを表示する

製品を作成してよいのはログイン済みのユーザーだけにしておきたいので、`app/views/products/index.html.erb`ビューの`link_to`行を以下のように変更して、ユーザーが認証済みの場合にのみNew productリンクを表示するようにしましょう。

```erb
<%= link_to "New product", new_product_path if authenticated? %>
```

Log outボタンをクリックすると、indexページのNew productリンクが非表示になります。`http://localhost:3000/session/new`をブラウザで開いてログインすると、indexページにNew productリンクが表示されます。

オプションとして、先ほどの`app/views/layouts/application.html.erb`レイアウトの`<nav>`セクションに以下のルーティングへのリンクも追加して、認証されていない場合はLoginリンクを表示するようにしてもよいでしょう。

```erb
<%= link_to "Login", new_session_path unless authenticated? %>
```

また、`app/views/products/show.html.erb`ビューのEditリンクとDestroyリンクを以下のように更新して、認証済みの場合にのみEditリンクとDestroyリンクを表示するようにしてもよいでしょう。

```erb
<h1><%= @product.name %></h1>

<%= link_to "Back", products_path %>
<% if authenticated? %>
  <%= link_to "Edit", edit_product_path(@product) %>
  <%= button_to "Destroy", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>
```

製品をキャッシュに乗せる
----------------

ページの特定の部分をキャッシュすると、パフォーマンスが向上する場合があります。
Railsは、データベース上に構築されるキャッシュストアであるSolid Cacheをデフォルトで組み込むことで、このプロセスを簡素化しています。

`cache`メソッドを使うと、HTMLをキャッシュに保存できます。`app/views/products/show.html.erb`の`<h1>`見出しを以下のように囲んで、キャッシュを有効にしてみましょう。

```erb
<% cache @product do %>
  <h1><%= @product.name %></h1>
<% end %>
```

`@product`を`cache`メソッドに渡すと、製品に固有のキャッシュキーを生成します。Active Recordオブジェクトにある`cache_key`メソッドは、`"products/1"`のような文字列を返します。ビューの`cache`ヘルパーは、これをテンプレートダイジェストと組み合わせて、このHTMLに固有のキーを作成します。

developmentモードでキャッシュを有効にするには、ターミナルで次のコマンドを実行します。

```bash
$ bin/rails dev:cache
```

製品の`show`アクション（`/products/2`など）にアクセスすると、Railsのサーバーログに新しいキャッシュ行が表示されます。

```bash
Read fragment views/products/show:a5a585f985894cd27c8b3d49bb81de3a/products/1-20240918154439539125 (1.6ms)
Write fragment views/products/show:a5a585f985894cd27c8b3d49bb81de3a/products/1-20240918154439539125 (4.0ms)
```

キャッシュを有効にしてからこのページを初めて開くと、Railsはキャッシュキーを生成して、キャッシュストアが存在するかどうかを問い合わせます。これがログの`Read fragment`行です。

これは初めて表示したページビューなのでキャッシュは存在せず、HTMLが生成されてキャッシュに書き込まれます。これはログの`Write fragment`行として確認できます。

ページを更新すると、ログに`Write fragment`が出力されなくなることがわかります。

```bash
Read fragment views/products/show:a5a585f985894cd27c8b3d49bb81de3a/products/1-20240918154439539125 (1.3ms)
```

キャッシュエントリは最後のリクエストによって書き込まれたため、Railsは2回目のリクエストでキャッシュエントリを見つけます。また、Railsはレコードが更新されるとキャッシュキーを変更して、古いキャッシュデータが誤ってレンダリングされないようにします。

詳しくは、[Rails のキャッシュ](caching_with_rails.html)ガイドを参照してください。

フィールドをAction Textでリッチテキストにする
---------------------------------

リッチテキスト機能やマルチメディア要素の埋め込み機能は、多くのアプリケーションで求められています。RailsのAction Textを使えば、こうした機能をすぐに使えるようになります。

Action Textの利用を開始するには、まずインストーラーを実行します。

```bash
$ bin/rails action_text:install
$ bundle install
$ bin/rails db:migrate
```

すべての新機能が読み込まれていることを確認するために、Railsサーバーを再起動します。

次に、リッチテキストのdescription（説明）フィールドを製品に追加してみましょう。

まず、`Product`モデルに以下のコードを追加します。

```ruby
class Product < ApplicationRecord
  has_rich_text :description
  validates :name, presence: true
end
```

これで、`app/views/products/_form.html.erb`のフォームを以下のように更新して、送信ボタンの上に説明の編集用リッチテキストフィールドを追加できるようになります。

```erb
<%= form_with model: product do |form| %>
  <%# （省略） %>

  <div>
    <%= form.label :description, style: "display: block" %>
    <%= form.rich_textarea :description %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

この新しいパラメータをフォームで送信するには、`app/controllers/products_controller.rb`コントローラ側で許可する必要があるので、`expect`で許可するパラメータを以下のように更新して、`description`を追加します。

```ruby
    # 信頼できるパラメータリストのみを許可する
    def product_params
      params.expect(product: [ :name, :description ])
    end
```

さらに、showビュー（`app/views/products/show.html.erb`）の`cache`ブロックも以下のように更新して、説明フィールドを表示する必要があります。

```erb
<% cache @product do %>
  <h1><%= @product.name %></h1>
  <%= @product.description %>
<% end %>
```

ビューが変更されると、Railsによって生成されるキャッシュキーも変更されるので、キャッシュがビューテンプレートの最新バージョンと同期した状態が維持されます。

それでは、新しい製品を作成して、descriptionフィールドに太字や斜体のテキストを追加してみましょう。製品を作成すると、書式付きテキストがShowページに表示されるようになり、製品を編集すると、このリッチテキストがテキスト領域に保持されるようになります。

詳しくは、[Action Textの概要](action_text_overview.html)を参照してください。

Active Storageでファイルアップロード機能を追加する
--------------------------------

Action Textは、ファイルのアップロードを手軽に行えるActive StorageというRailsの別の機能の上に構築されています。

製品のEditページを開いて、適当な画像をリッチテキストエディタにドラッグしてから、レコードを更新してみてください。画像がアップロードされて、リッチテキストエディタ内で表示されていることがわかります。素晴らしいですね！

Active Storageは、Action Textと別に直接利用することも可能です。

`Product`モデルに製品画像を添付する機能も追加してみましょう。

```ruby
class Product < ApplicationRecord
  has_one_attached :featured_image
  has_rich_text :description
  validates :name, presence: true
end
```

続いて、`app/views/products/_form.html.erb`フォームのSubmitボタンの上に、以下のようにファイルアップロード用フィールドを追加します。

```erb
<%= form_with model: product do |form| %>
  <%# （省略） %>

  <div>
    <%= form.label :featured_image, style: "display: block" %>
    <%= form.file_field :featured_image, accept: "image/*" %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

これまでと同様に、`:featured_image`も許可済みパラメータとして`app/controllers/products_controller.rb`に追加します。

```ruby
    # 信頼できるパラメータリストのみを許可する
    def product_params
      params.expect(product: [ :name, :description, :featured_image ])
    end
```

最後に、`app/views/products/show.html.erb`の冒頭に以下のコードを追加して、製品画像を表示できるようにしましょう。

```erb
<%= image_tag @product.featured_image if @product.featured_image.attached? %>
```

`http://localhost:3000/products/new`をブラウザで開いて、Featured imageの「ファイルを選択」ボタンをクリックして製品画像をアップロードしてみると、保存後にshowページに画像が表示されるようになります。

詳しくは、[Active Storage の概要](active_storage_overview.html)を参照してください。

国際化（I18n）
---------------------------

Railsを使えば、アプリを他の言語に翻訳しやすくなります。

ビューの`translate`ヘルパー（短縮形は`t`）は、名前で訳文を検索して、現在のロケール設定に合うテキストを返します。

`app/products/index.html.erb`の`<h1>`見出しタグを以下のように更新して、見出しに訳文が使われるようにしてみましょう。

```erb
<h1><%= t "hello" %></h1>
```

ページを更新すると、見出しテキストが`Products`から`Hello world`に変わっていることがわかります。このテキストはどこから来たのでしょうか?

デフォルトの言語は英語（`en`）なので、Railsは`config/locales/en.yml`（これは`rails new`で自動作成されます）を探索し、この`en`ロケールの中にある以下のキー（訳文サンプル）にマッチします。

```yaml
en:
  hello: "Hello world"
```

それでは、日本語用の新しいロケールファイルを作成してみましょう。エディタで`config/locales/ja.yml`ファイルを作成し、以下の訳文を追加します。

```yaml
ja:
  hello: "こんにちは、世界"
```

次に、どのロケールを利用するかをRailsに伝える必要があります。

最も手軽な方法は、ロケールパラメータをURLから探すことです。`app/controllers/application_controller.rb`で以下のコードを追加することで、これを実現できます。

```ruby
class ApplicationController < ActionController::Base
  # （省略）

  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
```

このコードはすべてのリクエストで実行され、パラメータ内の`locale`を探索して、見つからない場合はデフォルトのロケール（通常は`en`）にフォールバックします。これに基づいてリクエストのロケールを設定し、完了後にリセットします。

* `http://localhost:3000/products?locale=en`をブラウザで開くと、英文が表示されます。
* `http://localhost:3000/products?locale=ja`をブラウザで開くと、日本語の訳文が表示されます。
* ロケールを指定しない`http://localhost:3000/products`をブラウザで開くと、英語にフォールバックします。

次は、indexページの`<h1>`見出しのサンプル訳文を、実際の訳文に差し替えてみましょう。`app/views/products/index.html.erb`の見出しを以下のように更新します

```erb
<h1><%= t ".title" %></h1>
```

TIP: `title`の直前の`.`は、ロケールを**相対検索**することを表す指示です。相対検索では、キーにコントローラ名とアクション名が自動的に含まれるため、コントローラ名やアクション名を毎回入力せずに済みます。英語ロケールで`.title`を指定すると、実際には`en.products.index.title`が検索されます。

`config/locales/en.yml`では、以下のように`products`と`index`を追加し、その下に`title`キーを追加することで、`コントローラ名.ビュー名.訳文名`と一致するようにします。

```yaml
en:
  hello: "Hello world"
  products:
    index:
      title: "Products"
```

日本語のロケールファイルにも、以下のように英語ロケールファイルと対応する形で訳文を追加します。

```yaml
ja:
  hello: "こんにちは、世界"
  products:
    index:
      title: "製品"
```

これで、`http://localhost:3000/?locale=en`で英語ロケールを表示すると「Products」が表示され、`http://localhost:3000/?locale=ja`で日本語ロケールを表示すると「製品」が表示されるようになります。

詳しくは[Rails 国際化（I18n）API](i18n.html)ガイドを参照してください。

在庫の通知機能を追加する
-----------------------------

製品の在庫が復活したときに通知を受け取るための電子メールを登録する機能は、eコマースストアでよく使われる機能です。Railsの基本についてひととおり確認したので、今度はこの機能をストアに追加してみましょう。

### 基本的な在庫トラッキング機能

まず、Productモデルに`inventory_count`（在庫数）を追加して、在庫数をトラッキングできるようにしましょう。以下のコマンドを実行してマイグレーションを生成します。

```bash
$ bin/rails generate migration AddInventoryCountToProducts inventory_count:integer
```

続いて以下のコマンドでマイグレーションを実行します。

```bash
$ bin/rails db:migrate
```

製品の`app/views/products/_form.html.erb`フォームにも、以下のように在庫数のフィールドを追加する必要があります。

```erb
<%= form_with model: product do |form| %>
  <%# （省略） %>

  <div>
    <%= form.label :inventory_count, style: "display: block" %>
    <%= form.number_field :inventory_count %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

`app/controllers/products_controller.rb`コントローラでも、`expect`で許可するパラメータに`:inventory_count`を追加する必要があります。

```ruby
    def product_params
      params.expect(product: [ :name, :description, :featured_image, :inventory_count ])
    end
```

在庫数が決して負の数にならないようにしておくと便利なので、`app/models/product.rb`モデルにそのためのバリデーションも追加します。

```ruby
class Product < ApplicationRecord
  has_one_attached :featured_image
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
end
```

以上の変更により、ストア内の製品の在庫数を更新できるようになりました。

### 通知の購読者を製品に追加する

商品の在庫が復活したことをユーザーに通知するには、在庫情報の購読者（subscriber）をトラッキングする機能が必要です。

購読希望者のメールアドレスを保存して個別の商品に関連付けるための`Subscriber`というモデルを生成しましょう。

```bash
$ bin/rails generate model Subscriber product:belongs_to email
```

続いて新しいマイグレーションを実行します。

```bash
$ bin/rails db:migrate
```

上のコマンドで`product:belongs_to`オプションを指定したことで、購読者と製品が**1対多**リレーションを持つことを表す`belongs_to :product`という宣言が`Subscriber`モデルに含まれるようになります。つまり、`Subscriber`モデルのインスタンスは1つの`Product`インスタンスに「属する（belongs to）」ということです。

ただし、1つの製品に購読者が複数存在する可能性もあるため、`Product`モデルにも`has_many :subscribers, dependent: :destroy`を手動で追加することで、2つのモデル同士の関連付けの残りの部分も指定します。これにより、2つのデータベーステーブル間のクエリをjoin（結合）する方法が Railsで認識されます。

```ruby
class Product < ApplicationRecord
  has_many :subscribers, dependent: :destroy
  has_one_attached :featured_image
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
end
```

次は、購読者を作成するためのコントローラが必要です。`app/controllers/subscribers_controller.rb`コントローラを以下の内容で作成しましょう。

```ruby
class SubscribersController < ApplicationController
  allow_unauthenticated_access
  before_action :set_product

  def create
    @product.subscribers.where(subscriber_params).first_or_create
    redirect_to @product, notice: "You are now subscribed."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def subscriber_params
    params.expect(subscriber: [ :email ])
  end
end
```

上の`create`アクションでは、作成後リダイレクトしたときにflashで通知メッセージを設定しています。Railsのflashは、リダイレクト後のページに表示するメッセージを保存するのに使われます。

このflashメッセージを表示するには、`app/views/layouts/application.html.erb`レイアウトの`<body>`タグで以下のように通知を追加します。

```erb
<html>
  <!-- （省略） -->
  <body>
    <div class="notice"><%= notice %></div>
    <!-- （省略） -->
  </body>
</html>
```

ユーザーが特定の製品を指定して通知を購読できるようにするため、`Subscriber`がどの`Product`に属しているかをネステッドルーティングで指定しましょう。

`config/routes.rb`ファイルの`resources :products`を以下のように変更します。

```ruby
  resources :products do
    resources :subscribers, only: [ :create ]
  end
```

製品のShowページに在庫数を表示して、在庫があるかどうかをチェックできるようにしましょう。在庫がない場合は、在庫切れのメッセージと購読用のフォームを表示して、在庫が復活したときにユーザーが通知をメールで受け取れるようにします。

在庫表示用の`app/views/products/_inventory.html.erb`パーシャルを以下の内容で作成します。

```erb
<% if product.inventory_count? %>
  <p><%= product.inventory_count %> in stock</p>
<% else %>
  <p>Out of stock</p>
  <p>Email me when available.</p>

  <%= form_with model: [product, Subscriber.new] do |form| %>
    <%= form.email_field :email, placeholder: "you@example.com", required: true %>
    <%= form.submit "Submit" %>
  <% end %>
<% end %>
```

次に、`app/views/products/show.html.erb`の`cache`ブロックの下に以下のコードを追加して、上のパーシャルをレンダリングします。

```erb
<%= render "inventory", product: @product %>
```

### 「在庫あり」メールによる通知機能を追加する

商品の在庫が復活したときに購読者に通知する機能には、Railsのメール送信機能である[Action Mailer](action_mailer_basics.html)を使うことにします。

以下のコマンドを実行することでメーラーを生成できます。

```bash
$ bin/rails g mailer Product in_stock
```

これにより、`app/mailers/product_mailer.rb`に`in_stock`メソッドを持つクラスが生成されます。

購読者のメールアドレスにメールを送信できるようにするには、この`in_stock`メソッドを以下のように更新します。

```ruby
class ProductMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.product_mailer.in_stock.subject
  #
  def in_stock
    @product = params[:product]
    mail to: params[:subscriber].email
  end
end
```

Action Mailerのジェネレータを実行すると、`app/views/`フォルダの下にもメールテンプレートが2つ生成されます。1つはHTMLメールの送信用、もう1つはテキストメールの送信用です。
これらのテンプレートを更新することで、「在庫あり」メッセージや製品へのリンクをメールに含められるようになります。

`app/views/product_mailer/in_stock.html.erb`を以下のように変更します。

```erb
<h1>Good news!</h1>

<p><%= link_to @product.name, product_url(@product) %> is back in stock.</p>
```

`app/views/product_mailer/in_stock.text.erb`を以下のように変更します。

```erb
Good news!

<%= @product.name %> is back in stock.
<%= product_url(@product) %>
```

メールクライアントでユーザーがリンクをクリックしたときにブラウザで開くようにするには、相対パスではなく完全なURLが必要なので、メーラーでは`product_path`ではなく`product_url`を使います。

`bin/rails console`でRailsコンソールを開いて、以下のように送信先の製品とサブスクライバを読み込むことで、メールをテストできます。

```irb
store(dev)> product = Product.first
store(dev)> subscriber = product.subscribers.find_or_create_by(email: "subscriber@example.org")
store(dev)> ProductMailer.with(product: product, subscriber: subscriber).in_stock.deliver_later
```

メールが送信されたことがRailsの`log/development.log`で以下のように確認できます。

```
ProductMailer#in_stock: processed outbound mail in 63.0ms
Delivered mail 66a3a9afd5d4a_108b04a4c41443@local.mail (33.1ms)
Date: Fri, 26 Jul 2024 08:50:39 -0500
From: from@example.com
To: subscriber@example.com
Message-ID: <66a3a9afd5d4a_108b04a4c41443@local.mail>
Subject: In stock
Mime-Version: 1.0
Content-Type: multipart/alternative;
 boundary="--==_mimepart_66a3a9afd235e_108b04a4c4136f";
 charset=UTF-8
Content-Transfer-Encoding: 7bit


----==_mimepart_66a3a9afd235e_108b04a4c4136f
Content-Type: text/plain;
 charset=UTF-8
Content-Transfer-Encoding: 7bit

Good news!

T-Shirt is back in stock.
http://localhost:3000/products/1


----==_mimepart_66a3a9afd235e_108b04a4c4136f
Content-Type: text/html;
 charset=UTF-8
Content-Transfer-Encoding: 7bit

<!-- BEGIN app/views/layouts/mailer.html.erb --><!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <!-- BEGIN app/views/product_mailer/in_stock.html.erb --><h1>Good news!</h1>

<p><a href="http://localhost:3000/products/1">T-Shirt</a> is back in stock.</p>
<!-- END app/views/product_mailer/in_stock.html.erb -->
  </body>
</html>
<!-- END app/views/layouts/mailer.html.erb -->
----==_mimepart_66a3a9afd235e_108b04a4c4136f--

Performed ActionMailer::MailDeliveryJob (Job ID: 5e2bd5f2-f54f-4088-ace3-3f6eb15aaf46) from Async(default) in 111.34ms
```

これらのメールをトリガーするには、在庫数が0から正の数に変わるたびにメールを送信するコールバックを`Product`モデルに追加します。

```ruby
class Product < ApplicationRecord
  has_one_attached :featured_image
  has_rich_text :description
  has_many :subscribers, dependent: :destroy

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }

  after_update_commit :notify_subscribers, if: :back_in_stock?

  def back_in_stock?
    inventory_count_previously_was.zero? && inventory_count > 0
  end

  def notify_subscribers
    subscribers.each do |subscriber|
      ProductMailer.with(product: self, subscriber: subscriber).in_stock.deliver_later
    end
  end
end
```

上で追加した[`after_update_commit`][]は、変更がデータベースに保存された直後に実行されるActive Recordコールバックです。
`if: :back_in_stock?`は、`back_in_stock?`メソッドが`true`を返す場合にのみコールバックを実行するように指示します。

Active Recordで属性の変更をトラッキングできるようにするために、`back_in_stock?`メソッドでは`inventory_count`の直前の値を確認するのに`inventory_count_previously_was`（`inventory_count`属性から自動生成された[`属性名_previously_was`][`attribute_previously_was`]メソッド）を使っています。続いて、その値を現在の在庫数と比較して、製品の在庫が復活したかどうかを判断します。

`notify_subscribers`は、特定の製品のすべての購読者のリストを得るためにActive Record関連付けを利用して`subscribers`テーブルを照会してから、個別の購読者に送信する`in_stock`メールをキューに登録します。

[`attribute_previously_was`]:
  https://api.rubyonrails.org/classes/ActiveModel/Dirty.html#method-i-attribute_previously_was
[`after_update_commit`]:
  https://railsguides.jp/active_record_callbacks.html#after-commit%E3%82%B3%E3%83%BC%E3%83%AB%E3%83%90%E3%83%83%E3%82%AF%E3%81%AE%E3%82%A8%E3%82%A4%E3%83%AA%E3%82%A2%E3%82%B9

### 共通コードをconcernに抽出する

この`Product`モデルには、通知を処理するためのコードがかなり多く含まれています。Railsでは、これを[`ActiveSupport::Concern`][]に切り出すことでコードを整理できます。concernは通常のRubyモジュールですが、使いやすくするためのシンタックスシュガーが追加されています。

最初に、`Notifications`モジュールを作成してみましょう。

`app/models/product/`ディレクトリを作成してから、`app/models/product/notifications.rb`ファイルを以下の内容で作成します。

```ruby
module Product::Notifications
  extend ActiveSupport::Concern

  included do
    has_many :subscribers, dependent: :destroy
    after_update_commit :notify_subscribers, if: :back_in_stock?
  end

  def back_in_stock?
    inventory_count_previously_was == 0 && inventory_count > 0
  end

  def notify_subscribers
    subscribers.each do |subscriber|
      ProductMailer.with(product: self, subscriber: subscriber).in_stock.deliver_later
    end
  end
end
```

このモジュールがクラスに`include`されると、[`included`](https://railsguides.jp/association_basics.html#entryable%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB%E3%82%92%E5%AE%9A%E7%BE%A9%E3%81%99%E3%82%8B)ブロック内に記述したコードは、最初からそのクラスの一部であるかのように実行されます。また、このモジュール内で定義したメソッドは、そのクラスのオブジェクト（インスタンス）で呼び出せる通常のインスタンスメソッドになります。

通知をトリガーするコードを`Notification`モジュールに切り出したので、`app/models/product.rb`モデルで以下のように`Notifications`モジュールを`include`してコードを簡潔にできます。

```ruby
class Product < ApplicationRecord
  include Notifications

  has_many :subscribers, dependent: :destroy
  has_one_attached :featured_image
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }

  # （省略）
end
```

concernは、Railsアプリケーションの機能を整理するための優れた手法のひとつです。製品に機能を繰り返し追加していると、やがてクラスが乱雑になります。代わりに、concernを使って各機能を`Product::Notifications`などの自己完結型モジュールに抽出できます。このモジュールには、サブスクライバの処理と通知の送信方法に関する機能がすべて含まれています。

コードをconcernに抽出すると、機能の再利用性も高まります。たとえば、サブスクライバ通知も必要とする新しいモデルを手軽に導入できるようになります。このモジュールを利用する複数のモデルで同じ機能を提供できます。

[`ActiveSupport::Concern`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Concern.html

[`included`]:
  https://railsguides.jp/association_basics.html#entryable%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB%E3%82%92%E5%AE%9A%E7%BE%A9%E3%81%99%E3%82%8B

### 通知購読の解除リンクをメールに追加する

通知を購読したユーザーが購読を解除できるようにしておきたいので、次は購読の解除機能を構築することにしましょう。

最初に、`config/routes.rb`のルーティングに購読解除用のルーティングを追加する必要があります。これは解除用メールに含めるURLとして使われます。

```ruby
  resource :unsubscribe, only: [ :show ]
```

Active Recordには、さまざまな目的でデータベースレコードを検索するための一意のトークンを生成できる[`generates_token_for`](https://api.rubyonrails.org/classes/ActiveRecord/TokenFor/ClassMethods.html#method-i-generates_token_for)という機能があります。これを使って、電子メールの登録解除用URLに含める一意の登録解除用トークンを`Subscriber`モデルで生成できます。

```ruby
class Subscriber < ApplicationRecord
  belongs_to :product
  generates_token_for :unsubscribe
end
```

コントローラは最初に、URLに含まれるトークンを用いて`Subscriber`のレコードを検索し、対応する購読者が見つかったら、レコードを破棄（`destroy`）してホームページにリダイレクトします。

`app/controllers/unsubscribes_controller.rb`を以下の内容で作成します。

```ruby
class UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_subscriber

  def show
    @subscriber&.destroy
    redirect_to root_path, notice: "Unsubscribed successfully."
  end

  private

  def set_subscriber
    @subscriber = Subscriber.find_by_token_for(:unsubscribe, params[:token])
  end
end
```

仕上げに、登録解除用リンクをメールテンプレートに追加しましょう。

`app/views/product_mailer/in_stock.html.erb`で以下のように`link_to`を追加します。

```erb
<h1>Good news!</h1>

<p><%= link_to @product.name, product_url(@product) %> is back in stock.</p>

<%= link_to "Unsubscribe", unsubscribe_url(token: params[:subscriber].generate_token_for(:unsubscribe)) %>
```

`app/views/product_mailer/in_stock.text.erb`にも以下のように平文でURLを追加します。

```erb
Good news!

<%= @product.name %> is back in stock.
<%= product_url(@product) %>

Unsubscribe: <%= unsubscribe_url(token: params[:subscriber].generate_token_for(:unsubscribe)) %>
```

ユーザーがこの登録解除用リンクをクリックすると、データベースから`Subscriber`のレコードが削除されます。追加したコントローラは、無効なトークンや期限切れのトークンをエラーなしで安全に処理します。

Railsコンソールを起動してメールをもう1件送信し、ログに表示される登録解除リンク（`Unsubscribe: `で始まります）のURLを見つけてブラウザで開き、正常に登録解除できることをテストしてみてください。成功するとstoreのトップページが開いて「Unsubscribed successfully.」と表示されます。

[`generates_token_for`]:
  https://api.rubyonrails.org/classes/ActiveRecord/TokenFor/ClassMethods.html#method-i-generates_token_for

CSSとJavaScriptを追加する
-----------------------

CSSやJavaScriptはWebアプリケーション構築の中心となるため、Railsでの利用方法を学びましょう。

### Propshaft

Railsで、「CSS」「JavaScript」「画像」などのアセットを取得してブラウザに配信する**アセットパイプライン**（asset pipeline）には、[Propshaft][]が使われています。

production環境のPropshaftは、アセットの各バージョンをトラッキングしてキャッシュすることで、ページを高速化します。アセットパイプラインの仕組みについて詳しくは、[アセット パイプライン ガイド](asset_pipeline.html)を参照してください。

NOTE: 訳注: Rails 8.0からは、従来の[Sprockets][]に代わってPropshaftがデフォルトのアセットパイプラインになりました。

`app/assets/stylesheets/application.css`ファイルを以下のように更新して、フォントをsans-serifに変更してみましょう。

```css
body {
  font-family: Arial, Helvetica, sans-serif;
  padding: 1rem;
}

nav {
  justify-content: flex-end;
  display: flex;
  font-size: 0.875em;
  gap: 0.5rem;
  max-width: 1024px;
  margin: 0 auto;
  padding: 1rem;
}

nav a {
  display: inline-block;
}

main {
  max-width: 1024px;
  margin: 0 auto;
}

.notice {
  color: green;
}

section.product {
  display: flex;
  gap: 1rem;
  flex-direction: row;
}

section.product img {
  border-radius: 8px;
  flex-basis: 50%;
  max-width: 50%;
}
```

続いて、`app/views/products/show.html.erb`ファイルを以下のように更新して、新しいスタイルを反映します。

```erb
<p><%= link_to "Back", products_path %></p>

<section class="product">
  <%= image_tag @product.featured_image if @product.featured_image.attached? %>

  <section class="product-info">
    <% cache @product do %>
      <h1><%= @product.name %></h1>
      <%= @product.description %>
    <% end %>

    <%= render "inventory", product: @product %>

    <% if authenticated? %>
      <%= link_to "Edit", edit_product_path(@product) %>
      <%= button_to "Delete", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
    <% end %>
  </section>
</section>
```

ブラウザでページを再読み込みすると、CSSが反映されたことを確認できます。

[Propshaft]:
  https://github.com/rails/propshaft
[Sprockets]:
  https://github.com/rails/sprockets

### importmap

RailsのJavaScriptでは、デフォルトで[importmap][]を経由する形で利用します。これにより、ビルドステップを必要とせずに現代のJavaScriptモジュールを書けるようになります。

利用するJavaScriptパッケージ名は、`config/importmap.rb`に記述されます。このファイルは、利用するJavaScriptパッケージ名を、ブラウザでimportmapタグを生成するためのソースファイルと`pin`で対応付けます。

```ruby
# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

TIP: 上の`pin`は、それぞれJavaScriptパッケージ名（例: `"@hotwired/turbo-rails"`）を特定のファイルやURL（例: `"turbo.min.js"`）に対応付けます。`pin_all_from`は、ディレクトリ内のすべてのファイル（例: `app/javascript/controllers`）を名前空間（例: `"controllers"`）に一括で対応付けます。

importmapは、最新のJavaScript機能をサポートすると同時に、JavaScriptのセットアップをクリーンかつ最小限に保ちます。

Railsの`config/importmap.rb`ファイルには、既にいくつかのJavaScriptファイルが存在しています。これらは、Hotwireと呼ばれるRailsのデフォルトのフロントエンドフレームワークです。

[importmap]:
  https://developer.mozilla.org/ja/docs/Web/HTML/Element/script/type/importmap

### Hotwire

[Hotwire](https://hotwired.dev/)は、サーバー側で生成されるHTMLを最大限に活用するように設計されたJavaScriptフレームワークで、以下の3つのコアコンポーネントで構成されています。

1. [**Turbo**](https://turbo.hotwired.dev/): カスタムJavaScriptを記述せずに、ナビゲーションやフォーム送信、ページコンポーネント、更新を処理します。

2. [**Stimulus**](https://stimulus.hotwired.dev/): ページに機能を追加するカスタムJavaScriptが必要な場合のフレームワークを提供します。

3. [**Native**](https://native.hotwired.dev/): Web アプリを埋め込み、ネイティブ モバイル機能で段階的に拡張することで、ハイブリッドモバイル アプリを作成できます。

storeアプリではまだJavaScriptを記述していませんが、storeアプリのフロントエンドでは既にHotwireが動いています。たとえば、製品を追加・編集するために作成したフォームを動かすのに暗黙でTurboが使われています。

詳しくは、[アセットパイプライン](asset_pipeline.html)ガイドや[RailsでのJavaScript利用](working_with_javascript_in_rails.html)ガイドを参照してください。

Railsでテストを書く
-------

Railsには堅牢なテストスイートが付属しています。製品の在庫が復活したときに正しい件数のメールが送信されることを確認するテストを記述してみましょう。

### フィクスチャ

Railsでモデルを生成すると、モデルに対応するフィクスチャファイルが`test/fixtures/`ディレクトリに自動的に作成されます。

**フィクスチャ**（fixture）は、テストを実行する前にテストデータベースに取り込まれる定義済みのデータセットです。フィクスチャは、レコードを覚えやすい名前で定義できるため、テストで手軽にアクセスできます。

フィクスチャファイルは、デフォルトでは空なので、テスト用のフィクスチャを取り込む必要があります。

`Product`モデルのテスト用に、`test/fixtures/products.yml`フィクスチャファイルを以下のように更新しましょう。

```yaml
tshirt:
  name: T-Shirt
  inventory_count: 15
```

`Subscriber`モデルのテスト用に、以下の2つのフィクスチャを`test/fixtures/subscribers.yml`に追加します。

```yaml
david:
  product: tshirt
  email: david@example.org

chris:
  product: tshirt
  email: chris@example.org
```

この`subscribers.yml`フィクスチャを見ると、`tshirt`という名前で`Product`用フィクスチャを参照できていることがわかります。Railsはこれらをデータベース内で自動的に関連付けるので、レコードIDや関連付けをテストコード内で手動で管理する必要はありません。

これらのフィクスチャは、テストスイートを実行するとき自動でデータベースに挿入されます。

### メール送信をテストする

`test/models/product_test.rb`に以下のテストを追加してみましょう。

```ruby
require "test_helper"

class ProductTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email notifications when back in stock" do
    product = products(:tshirt)

    # 製品を在庫切れにする
    product.update(inventory_count: 0)

    assert_emails 2 do
      product.update(inventory_count: 99)
    end
  end
end
```

このテストで行っていることを1つずつ詳しく見てみましょう。

最初に、Action Mailer用のテストヘルパーを`include`して、テスト中に送信されたメールを監視できるようにします。

`tshirt`フィクスチャは フィクスチャが生成する`products()`ヘルパーメソッドで読み込まれ、そのレコードのActive Recordオブジェクトを返します。各フィクスチャはテストスイートでこのようなヘルパーを生成します（データベースIDは実行ごとに異なる可能性があるため、フィクスチャを名前で簡単に参照できるようにします）。

次に、在庫を0に更新して、Tシャツを在庫切れの状態にします。

次に、ブロック内のコードによって2件のメールが生成されたことを[`assert_emails`][]アサーションで確認します。

メールをトリガーするには、ブロック内で製品の在庫数を更新して0にします。これにより、`Product`モデルの`notify_subscribers`コールバックがトリガーされ、メールが送信されます。

実行が完了すると、`assert_emails`はメールの件数をカウントし、期待される件数と一致することを確認します。

以下のようにファイル名を指定して個別のテストファイルを実行してみましょう。なお、単に`bin/rails test`コマンドを実行すると、すべてのテストスイートを実行することも可能です。

```bash
$ bin/rails test test/models/product_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 3556

# Running:

.

Finished in 0.343842s, 2.9083 runs/s, 5.8166 assertions/s.
1 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

`product_test.rb`のテストはパスしました１

`ProductMailer`を生成したときにも、`test/mailers/product_mailer_test.rb`にサンプルテストが生成されていますので、こちらも以下のように更新してパスするようにしましょう。

```ruby
require "test_helper"

class ProductMailerTest < ActionMailer::TestCase
  test "in_stock" do
    mail = ProductMailer.with(product: products(:tshirt), subscriber: subscribers(:david)).in_stock
    assert_equal "In stock", mail.subject
    assert_equal [ "david@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Good news!", mail.body.encoded
  end
end
```

今度は以下のように全テストスイートを実行してみると、すべてのテストがパスすることが確認できます。

```bash
$ bin/rails test
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 16302

# Running:

..

Finished in 0.665856s, 3.0037 runs/s, 10.5128 assertions/s.
2 runs, 7 assertions, 0 failures, 0 errors, 0 skips
```

これらのテストを出発点として、アプリケーション機能を完全にカバーするテストスイートを今後も構築できます。

詳しくは、[Railsアプリケーションのテスト](testing.html)ガイドを参照してください。

[`assert_emails`]:
  https://api.rubyonrails.org/classes/ActionMailer/TestHelper.html#method-i-assert_emails

RuboCopでコードの形式を統一する
----------------------------------------

コードを書くときのフォーマットが、人や場所によってばらついてしまうことがあります。Railsには、コードのフォーマットを統一するうえで役に立つRuboCopという[linter][]が付属しています。

以下のコマンドを実行することで、コードが一貫しているかどうかをチェックできます。

```bash
$ bin/rubocop
```

実行すると、違反とその内容が出力されます。
なお、以下は違反が発生していない場合の出力です。

```bash
Inspecting 53 files
.....................................................

53 files inspected, no offenses detected
```

RuboCopのコマンドで以下のように`--autocorrect`（または短縮形の`-a`）フラグを追加すると、修正可能な違反が自動修正されます。

```bash
$ bin/rubocop -a
```

[linter]:
  https://ja.wikipedia.org/wiki/Lint#%E3%80%8Clint%E3%80%8D%E3%81%AE%E6%B4%BE%E7%94%9F%E7%94%A8%E6%B3%95

セキュリティチェック
--------

Railsには、アプリケーションのセキュリティ問題（セッションハイジャック、セッション固定、リダイレクトなどの、攻撃につながる可能性のある脆弱性）をチェックするためのBrakeman gemが含まれています。

`bin/brakeman`コマンドを実行すると、アプリケーションの脆弱性を分析してレポートを出力します。

```bash
$ bin/brakeman
Loading scanner...
...

== Overview ==

Controllers: 6
Models: 6
Templates: 15
Errors: 0
Security Warnings: 0

== Warning Types ==


No warnings found
```

セキュリティについて詳しくは、[Railsアプリケーションのセキュリティ](security.html)ガイドを参照してください。

GitHub ActionsでCIを実行する
------------------------------------------

Railsアプリを生成すると、`.github/`フォルダも生成されます。ここには、rubocopやbrakemanやテストスイートを自動実行するよう事前構成済みの[GitHub Actions](https://github.co.jp/features/actions)設定が含まれています。

GitHub Actionsが有効になっているGitHubリポジトリにRailsアプリのコードをプッシュすれば、それだけでGitHub Actionsでこれらの手順が自動的に実行され、項目ごとに成功や失敗を報告してくれます。

これにより、コードの変更を監視して欠陥や問題を検出し、作業の品質を統一的に担保できるようになります。

Kamalでproduction環境にデプロイする
-----------------------

いよいよお楽しみが始まります。アプリをデプロイしてみましょう。

Railsに付属している[Kamal](https://kamal-deploy.org)というデプロイツールを使えば、アプリケーションをサーバーに直接デプロイできます。KamalはアプリケーションをDockerコンテナで実行し、ダウンタイムなしでデプロイします。

Railsには、デフォルトでproduction環境に対応したDockerfileが付属しており、Kamalはこれを使ってDockerイメージをビルドし、コンテナ化されたアプリケーションとそのすべての依存関係と設定を作成します。

なお、このDockerfileでは、production環境でアセットを効果的に圧縮して配信するために、[Thruster](https://github.com/basecamp/thruster)を使っています。

Kamalでデプロイを行うには、以下のものが必要です。

- 1GB以上のRAMを搭載したUbuntu LTSを実行するサーバー。
  デプロイ先のサーバーは、定期的なセキュリティとバグ修正を受けられるように、LTS（長期サポート）版のUbuntu OSを実行している必要があります。HetznerやDigitalOceanなどのホスティングサービスでは、Kamalの利用をすぐ開始できるサーバーを提供しています。
- [Docker Hub](https://hub.docker.com)のアカウントとアクセストークン。
  Docker Hubは、アプリケーションのイメージを保存し、サーバーにダウンロードして実行できるようにします。

Docker Hubで、アプリケーションイメージの[リポジトリを作成](https://hub.docker.com/repository/create)します。リポジトリの名前は「store」にしておきます。

`config/deploy.yml`ファイルをエディタで開いて、サーバーのIPアドレスを`192.168.0.1`に置き換え、`your-user`をDocker Hubのユーザー名に置き換えます。

```yaml
# Name of your application. Used to uniquely configure containers.
service: store

# Name of the container image.
image: your-user/store

# Deploy to these servers.
servers:
  web:
    - 192.168.0.1

# Credentials for your image host.
registry:
  # Specify the registry server, if you're not using Docker Hub
  # server: registry.digitalocean.com / ghcr.io / ...
  username: your-user
```

`proxy:`セクションでは、アプリケーションでSSLを有効にするためのドメインも追加できます。DNSレコードがサーバーを確実に指していることを確認してください。Kamalは、[LetsEncrypt](https://letsencrypt.org/)を用いてドメインのSSL証明書を発行します。

```yaml
proxy:
  ssl: true
  host: app.example.com
```

KamalがアプリケーションのDockerイメージをプッシュできるように、DockerのWebサイトで読み取りと書き込みの権限を持つ[アクセストークンを作成](https://app.docker.com/settings/personal-access-tokens/create)します。

次に、ターミナルでアクセストークンを`KAMAL_REGISTRY_PASSWORD`環境変数に`export`して、Kamalがアクセストークンを利用できるようにします。

```bash
export KAMAL_REGISTRY_PASSWORD=your-access-token
```

サーバーのセットアップとアプリケーションのデプロイを初めて行うときは、以下のコマンドを実行します。

```bash
$ bin/kamal setup
```

おめでとうございます! 新しいRailsアプリケーションがproduction環境で動くようになりました！

新しいRailsアプリケーションが動いていることを確認してみましょう。ブラウザでサーバーのIPアドレスを入力すると、ストアが動いていることが確認できるはずです。

以後、アプリに変更を加えたら、以下のコマンドを実行するだけでproduction環境にプッシュできます。

```bash
$ bin/kamal deploy
```

### production環境でユーザーを作成する

production環境で製品の作成・編集を行うには、production環境のデータベースに`User`のレコードが必要です。

以下のKamalコマンドを使えば、production環境に接続してRailsコンソールを開けます。

```bash
$ bin/kamal console
```

```ruby
store(prod)> User.create!(email_address: "you@example.org", password: "s3cr3t", password_confirmation: "s3cr3t")
```

これで、入力したメールアドレスとパスワードでproduction環境にログインして、製品を管理できるようになります。

### Solid Queueでバックグラウンドジョブを処理する

バックグラウンドジョブを使うと、タスクをバックグラウンドで非同期的に別プロセスで実行できるため、ユーザーエクスペリエンスを損なわずに済みます。

10,000人の受信者に在庫メールを送信することを想像してみましょう。大量のメール送信には時間がかかる可能性があるため、そのタスクをバックグラウンドジョブに乗せ換えることで、Railsアプリの応答性を維持できるようになります。

development環境のRailsでは、`:async`キューアダプタでActiveJobのバックグラウンドジョブを処理します。asyncアダプタは保留中のジョブをメモリに保存しますが、再起動すると保留中のジョブは失われます。これはdevelopment環境には最適ですが、production環境には適していません。

Railsのproduction環境では、バックグラウンドジョブをより堅牢にするために`solid_queue`を利用します。Solid Queueは、ジョブをデータベースに保存して、別プロセスで実行します。

Solid Queueは、`config/deploy.yml`の`SOLID_QUEUE_IN_PUMA: true`環境変数によって、production環境でのKamalデプロイで有効になっています。これにより、[Puma](https://github.com/puma/puma) WebサーバーはSolid Queueプロセスの開始と停止を自動的に行います。

メールがAction Mailerの`deliver_later`メソッドによって送信されると、これらのメールはバックグラウンド送信のためにActive Jobに送信されるので、HTTPリクエストが遅延せずに済みます。production環境でSolid Queueを使うと、メールはバックグラウンドで送信され、送信に失敗した場合に自動的に再試行され、ジョブは再起動中でもデータベースに安全に保持されます。

![バックグラウンドジョブの流れ](images/getting_started/background_jobs_light.jpg)

今後のステップ
------------

初めてのRailsアプリケーションの構築、お疲れ様でした。デプロイの完了おめでとうございます!

学習を続けるために、機能を追加してアップデートのデプロイを繰り返してみることをオススメします。アプリケーションの改善案の例を以下に示します。

* CSSでデザインを改善する
* 製品レビュー機能を追加する
* アプリを別の言語に翻訳する
* 支払い用のチェックアウトフローを追加する
* ユーザーが製品を保存できるウィッシュリストを追加する
* 製品画像のカルーセルを追加する

Railsの学習を続けるために、Ruby on Railsの以下のガイドもぜひ参照してみてください。

* [Active Recordの基礎](active_record_basics.html)
* [レイアウトとレンダリング](layouts_and_rendering.html)
* [Railsテスティングガイド](testing.html)
* [Railsアプリケーションのデバッグ](debugging_rails_applications.html)
* [Railsセキュリティガイド](security.html)

アプリは楽しく作りましょう！
