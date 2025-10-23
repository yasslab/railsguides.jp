コマンドラインツール
======================

本ガイドでは、コマンドラインで以下を行う方法を解説します。

* Railsアプリケーションを作成する方法
* モデル、コントローラ、データベースのマイグレーションファイル、および単体テストを作成する方法
* 開発用サーバーを起動する方法
* インタラクティブシェルを利用して、オブジェクトを実験する方法
* credentials（認証情報）の追加・編集方法

--------------------------------------------------------------------------------

概要
--------

Railsのコマンドラインは、Ruby on Railsフレームワークの強力な機能の一部です。Railsの規約に沿った定型コードを生成することで、新しいアプリケーションを短時間で構築できます。本ガイドでは、データベースを含むWebアプリケーションのあらゆる側面を管理できるさまざまなRailsコマンドの概要を説明します。

`bin/rails --help`と入力すると、利用可能なコマンドの一覧が表示されます。表示されるコマンドは、現在のディレクトリに応じて変わります。コマンドごとに、その機能の説明が表示されます。

```bash
$ bin/rails --help
Usage:
  bin/rails COMMAND [options]

You must specify a command. The most common commands are:

  generate     Generate new code (short-cut alias: "g")
  console      Start the Rails console (short-cut alias: "c")
  server       Start the Rails server (short-cut alias: "s")
  test         Run tests except system tests (short-cut alias: "t")
  test:system  Run system tests
  dbconsole    Start a console for the database specified in config/database.yml
               (short-cut alias: "db")
  plugin new   Create a new Rails railtie or engine

All commands can be run with -h (or --help) for more information.
```

`bin/rails --help`の出力では、上に続いてすべてのコマンドがアルファベット順に表示され、それぞれのコマンドに簡単な説明が表示されます。

```bash
In addition to those commands, there are:
about                              List versions of all Rails frameworks ...
action_mailbox:ingress:exim        Relay an inbound email from Exim to ...
action_mailbox:ingress:postfix     Relay an inbound email from Postfix ...
action_mailbox:ingress:qmail       Relay an inbound email from Qmail to ...
action_mailbox:install             Install Action Mailbox and its ...
...
db:fixtures:load                   Load fixtures into the ...
db:migrate                         Migrate the database ...
db:migrate:status                  Display status of migrations
db:rollback                        Roll the schema back to ...
...
turbo:install                      Install Turbo into the app
turbo:install:bun                  Install Turbo into the app with bun
turbo:install:importmap            Install Turbo into the app with asset ...
turbo:install:node                 Install Turbo into the app with webpacker
turbo:install:redis                Switch on Redis and use it in development
version                            Show the Rails version
yarn:install                       Install all JavaScript dependencies as ...
zeitwerk:check                     Check project structure for Zeitwerk ...
```

`bin/rails --help` に加えて、上記のリストにあるコマンドに`--help`フラグを追加して実行するのも便利です。たとえば、`bin/rails routes`コマンドでどんなオプションが使えるかを知りたいときは、以下のように`bin/rails routes --help`を実行します。

```bash
$ bin/rails routes --help
Usage:
  bin/rails routes

Options:
  -c, [--controller=CONTROLLER]      # Filter by a specific controller, e.g. PostsController or Admin::PostsController.
  -g, [--grep=GREP]                  # Grep routes by a specific pattern.
  -E, [--expanded], [--no-expanded]  # Print routes expanded vertically with parts explained.
  -u, [--unused], [--no-unused]      # Print unused routes.

List all the defined routes
```

Railsのコマンドラインのほとんどのサブコマンドは`--help`（または `-h`）フラグ付きで実行可能で、サブコマンドの利用方法が非常に詳しく表示されます。たとえば`bin/rails generate model --help`を実行すると、利用方法とオプションに加えて、2ページにわたる詳しい説明が出力されます。

```bash
$ bin/rails generate model --help
Usage:
  bin/rails generate model NAME [field[:type][:index] field[:type][:index]] [options]
Options:
...
Description:
    Generates a new model. Pass the model name, either CamelCased or
    under_scored, and an optional list of attribute pairs as arguments.

    Attribute pairs are field:type arguments specifying the
    model's attributes. Timestamps are added by default, so you don't have to
    specify them by hand as 'created_at:datetime updated_at:datetime'.

    As a special case, specifying 'password:digest' will generate a
    password_digest field of string type, and configure your generated model and
    tests for use with Active Model has_secure_password (assuming the default ORM and test framework are being used).
    ...
```

以下は、利用頻度の高いRailsコマンドです。

* `bin/rails console`
* `bin/rails server`
* `bin/rails test`
* `bin/rails generate`
* `bin/rails db:migrate`
* `bin/rails db:create`
* `bin/rails routes`
* `bin/rails dbconsole`
* `rails new app_name`

以下のセクションでは、上を含むさまざまなコマンドについて説明します。
最初は、新しいアプリケーションを作成するためのコマンドです。

Railsアプリを作成する
--------------------

`rails new`コマンドを実行すると、新しいRailsアプリケーションが作成されます。

INFO: `rails new`コマンドを実行するには、事前にrails gemをインストールしておく必要があります。Rubyの使える環境であれば`gem install rails`を実行することでインストールできます。詳しい手順については、[Ruby on Railsインストールガイド](install_ruby_on_rails.html)ガイドを参照してください。

`new`コマンドを実行すると、Railsで必要なデフォルトのディレクトリ構造全体と、サンプルアプリケーションをすぐに実行するために必要なすべてのコードがセットアップされます。`rails new`の第1引数にはアプリケーション名を指定します。

```bash
$ rails new my_app
     create
     create  README.md
     create  Rakefile
     create  config.ru
     create  .gitignore
     create  Gemfile
     create  app
     ...
     create  tmp/cache
     ...
        run  bundle install
```

`new`コマンドにさまざまなオプションを渡すことで、デフォルトの動作を変更できます。
また、独自の[アプリケーションテンプレート](generators.html#アプリケーションテンプレート)を作成しておいて`new`コマンドで利用することも可能です。

### さまざまなデータベースを事前に指定する

`rails new`コマンドで新しいRailsアプリケーションを作成するときに、アプリケーションで使うデータベースを`--database`（または`-d`）オプションで指定できます。`rails new`のデフォルトデータベースはSQLiteです。たとえば、PostgreSQLデータベースは次のように設定できます。

```bash
$ rails new booknotes --database=postgresql
      create
      create  app/controllers
      create  app/helpers
...
```

このオプションを指定したときの主な違いは、`config/database.yml`ファイルの内容です。PostgreSQLオプションを指定した場合、`config/database.yml`ファイルは以下のようになります。

```yaml
# PostgreSQL. Versions 9.3 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On macOS with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem "pg"
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 3 } %>


development:
  <<: *default
  database: booknotes_development
  ...
```

`--database=postgresql`オプションを指定すると、新しいRailsアプリケーションで生成される他のファイルもそれに応じて適切に変更されます（`Gemfile`に`pg` gemを追加するなど）。

### デフォルトをスキップする

`rails new`コマンドを実行すると、多数のファイルが生成されます。
生成したくないファイルがある場合は、以下のように`rails new`コマンドに`--skip`オプションを追加することで生成をスキップできます。

```bash
$ rails new no_storage --skip-active-storage
Based on the specified options, the following options will also be activated:

  --skip-action-mailbox [due to --skip-active-storage]
  --skip-action-text [due to --skip-active-storage]

      create
      create  README.md
      ...
```

上の例では、Active Storageがスキップされるのに加えて、Active Storage機能に依存しているAction MailboxとAction Textもスキップされます。

TIP: `--skip`オプションでスキップできる機能の完全なリストは、`rails new --help`コマンドで確認できます。

### Railsアプリケーションサーバーを起動する

`bin/rails server`コマンドを実行すると、[Puma][]というWebサーバーが起動します（PumaはRailsに標準でバンドルされます）。Webブラウザでアプリケーションにアクセスしたいときは、このコマンドを使います。

```bash
$ cd my_app
$ bin/rails server
=> Booting Puma
=> Rails 8.1.0 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.0 (ruby 3.1.3-p185) ("The Eagle of Durango")
*  Min threads: 3
*  Max threads: 3
*  Environment: development
*          PID: 5295
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

わずか2つのコマンドを実行しただけで、Railsサーバーを3000番ポートで起動できるようになりました。ブラウザを立ち上げて、[http://localhost:3000](http://localhost:3000)を開いてみてください。Railsアプリケーションが動作していることが分かります。

INFO: ほとんどのRailsコマンドには短縮形のエイリアスがあります。サーバーを起動する際には`bin/rails s`のように"s"というエイリアスが使えます。

- `-p`オプションでリッスンするポートを変更できます。
- `-e`オプションでサーバーの環境を変更できます。デフォルトではdevelopment（開発）環境で実行されます。

```bash
$ bin/rails server -e production -p 4000
```

- `-b`オプションで、Railsを特定のIPアドレスにバインドできます。デフォルトはlocalhostです。
- `-d`オプションを指定すると、起動したサーバーがデーモンとして常駐します。

[Puma]: https://github.com/puma/puma

### テンプレートコードを生成する

`bin/rails generate`コマンドを実行すると、さまざまなファイルを生成してアプリケーションに機能を追加できます。モデルのファイルやコントローラのファイルを生成したり、scaffoldですべてのファイルを一括生成したりできます。

Rails組み込みのジェネレータの一覧を見るには、引数なしで`bin/rails generate`（または短縮形の`bin/rails g`）を実行します。利用法に続けて、利用可能なジェネレータがすべて表示されます。特定のジェネレータを実行せずにどんなファイルが生成されるかだけを知りたい場合は、`--pretend`オプションを指定できます。

```bash
$ bin/rails generate
Usage:
  bin/rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  -p, [--pretend]  # Run but do not make any changes
  -f, [--force]    # Overwrite files that already exist
  -s, [--skip]     # Skip files that already exist
  -q, [--quiet]    # Suppress status output

Please choose a generator below.
Rails:
  application_record
  benchmark
  channel
  controller
  generator
  helper
...
```

NOTE: Railsアプリケーションにgemを追加すると、ジェネレータが追加される場合があります。また、ジェネレータを自作することも可能です。詳しくは[ジェネレータのガイド](generators.html)を参照してください。

ジェネレータを使うと、アプリケーションを動かすのに必要な[**ボイラープレートコード**](https://ja.wikipedia.org/wiki/ボイラープレートコード)（定形コード）を書かなくて済むため、多くの時間を節約できます。

それでは`controller`ジェネレータを使って、コントローラを作ってみましょう。

### コントローラを生成する

`bin/rails generate controller`コマンドだけを実行すれば、`--help`オプションを付けて実行したときと同じように、`controller`ジェネレータの詳しい利用法を表示できます。"Usage"セクションとコマンド例が表示されます。

```bash
$ bin/rails generate controller
Usage:
  bin/rails generate controller NAME [action action] [options]
...
Examples:
    `bin/rails generate controller credit_cards open debit credit close`

    This generates a `CreditCardsController` with routes like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb

    `bin/rails generate controller users index --skip-routes`

    This generates a `UsersController` with an index action and no routes.

    `bin/rails generate controller admin/dashboard --parent=admin_controller`

    This generates a `Admin::DashboardController` with an `AdminController` parent class.
```

コントローラのジェネレータには`generate controller コントローラ名 アクション1 アクション2`という形式でパラメータを渡します。**hello**アクションを実行すると、ちょっとしたメッセージを表示する`Greetings`コントローラを作ってみましょう。

```bash
$ bin/rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get 'greetings/hello'
     invoke  erb
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke    test_unit
```

コマンドを実行すると、アプリケーションでさまざまなディレクトリが作成され、コントローラファイル、ビューファイル、機能テストのファイル、ビューヘルパーファイルなどが生成され、ルーティングも追加されます。

生成されたコントローラ（`app/controllers/greetings_controller.rb`）とビュー（`app/views/greetings/hello.html.erb`）をエディタで開いて、`hello`アクションを以下のように変更してみましょう。

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "こんにちは、ご機嫌いかがですか？"
  end
end
```

```erb
<h1>ごあいさつ</h1>
<p><%= @message %></p>
```

`bin/rails server`でサーバーを起動します。

```bash
$ bin/rails server
=> Booting Puma...
```

`bin/rails server`コマンドを実行してRailsサーバーを起動し、追加したルーティングをブラウザで[http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)にアクセスすると、先ほど追加したメッセージが表示されます。

次は、ジェネレータを使ってアプリケーションにモデルを追加してみましょう。

### モデルを生成する

Railsのモデルジェネレータコマンドにも、非常に詳細な「Descriptiom（説明）」セクションが用意されています（以下は冒頭のみを表示しています）。

```bash
$ bin/rails generate model
Usage:
  bin/rails generate model NAME [field[:type][:index] field[:type][:index]] [options]
...
```

たとえば、`post`モデルを生成するには以下のようにコマンドを実行します。

```bash
$ bin/rails generate model post title:string body:text
    invoke  active_record
    create    db/migrate/20250807202154_create_posts.rb
    create    app/models/post.rb
    invoke    test_unit
    create      test/models/post_test.rb
    create      test/fixtures/posts.yml
```

モデルのジェネレータを実行すると、テストファイルやマイグレーションファイルも生成されます。生成後に`bin/rails db:migrate`コマンドでマイグレーションを実行する必要があります。

NOTE: `type`パラメータで指定できるフィールド型については、[APIドキュメント][API docs]に記載されている、[`SchemaStatements`][]モジュールの[`add_column`][]メソッドの説明を参照してください。`index`パラメータを指定すると、カラムに対応するインデックスも生成されます。フィールドの型を指定しない場合は、デフォルトで`string`型になります。

Railでは、コントローラやモデルを個別に生成するジェネレータの他に、標準的なCRUDリソースに必要な他のファイルとともに両方のコードを一度に追加するジェネレータも提供しています。これを行うジェネレータコマンドは、`resource`コマンドと`scaffold`コマンドの2つです。

`resource`コマンドは、後述する`scaffold`コマンドよりも軽量で、生成されるコードが少なくなります。

### リソースを生成する

`bin/rails generate resource`コマンドを実行すると、「モデル」「マイグレーション」「空のコントローラ」「テスト」ファイルが生成され、ルーティングが追加されます。ビューは生成されず、コントローラにCRUDメソッドも追加されません。

以下は、`resource`コマンドで`post`リソースを生成したときの全ファイルです。

```bash
$ bin/rails generate resource post title:string body:text
      invoke  active_record
      create    db/migrate/20250919150856_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
      invoke  resource_route
       route    resources :posts
```

`resource`コマンドは、ビューが不要な場合（APIを書く場合など）や、コントローラのアクションを手動で追加したい場合に使います。

### scaffoldを生成する

Railsのscaffold（足場）は、リソースのための完全なファイルセットを生成します。これには、「モデル」「コントローラ」「ビュー（HTMLおよびJSON）」「マイグレーション」「テスト」「ヘルパー」のファイルが含まれ、ルーティングも追加されます。
scaffoldは、CRUDインターフェイスのプロトタイピングを迅速に実行したいときや、カスタマイズ可能なリソースの基本構造を生成するための出発点として利用できます。

`post`リソースを`scaffold`コマンドで生成すると、上記のすべてのファイルが生成されることを確認できます。

```bash
$ bin/rails generate scaffold post title:string body:text
      invoke  active_record
      create    db/migrate/20250919150748_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  resource_route
       route    resources :posts
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      create      app/views/posts/index.html.erb
      create      app/views/posts/edit.html.erb
      create      app/views/posts/show.html.erb
      create      app/views/posts/new.html.erb
      create      app/views/posts/_form.html.erb
      create      app/views/posts/_post.html.erb
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      create      test/system/posts_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
      invoke    jbuilder
      create      app/views/posts/index.json.jbuilder
      create      app/views/posts/show.json.jbuilder
      create      app/views/posts/_post.json.jbuilder
```

<!-- このNOTEは8.0のものですが、意図的に残します -->
NOTE: Rails 8.1から、scaffoldはデフォルトでシステムテストを生成しなくなりました。システムテストは実行に時間がかかり、メンテナンスコストも高いため、利用は重要なユーザーパスに限定すべきです。scaffoldでシステムテストを含めるには、`--system-tests=true`オプションを指定します。

この時点で、`bin/rails db:migrate`を実行して`post`テーブルを作成できます（このコマンドについて詳しくは[データベースを管理する](#データベースを管理する)を参照してください）。
終わったら`bin/rails server`コマンドでRailsサーバーを起動し、[http://localhost:3000/posts](http://localhost:3000/posts)にアクセスすると、`post`リソースで投稿の一覧表示、新規投稿の作成、編集および削除が可能になります。

INFO: scaffoldで生成されるテストファイルにはテストケースが含まれていないため、コードを修正して実際にテストケースを追加する必要があります。コードのテストの作成と実行について詳しくは、[テスティングガイド](testing.html)を参照してください。

[API docs]: http://api.rubyonrails.org/
[`SchemaStatements`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html
[`add_column`]: http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column

### `bin/rails destroy`で生成を取り消す

`generator`コマンドでモデルやコントローラやscaffoldなどを生成するときに入力を間違えると、ジェネレータで作成された各ファイルを手動で削除するのは面倒です。Railsにはそのための`destroy`コマンドが用意されています。`destroy`は`generate`の逆の操作とみなすことが可能で、`generate`が行ったことを調べて、それを取り消します。

INFO: `destroy`コマンドを実行するときに`bin/rails d`のように"d"というエイリアスも使えます。

たとえば、`article`モデルを生成するときに間違えて`artcle`と入力してしまった場合を考えてみましょう。

```bash
$ bin/rails generate model Artcle title:string body:text
      invoke  active_record
      create    db/migrate/20250808142940_create_artcles.rb
      create    app/models/artcle.rb
      invoke    test_unit
      create      test/models/artcle_test.rb
      create      test/fixtures/artcles.yml
```

こんなときは、`generate`コマンドで生成された内容を`destroy`コマンドで取り消せます。

```bash
$ bin/rails destroy model Artcle title:string body:text
      invoke  active_record
      remove    db/migrate/20250808142940_create_artcles.rb
      remove    app/models/artcle.rb
      invoke    test_unit
      remove      test/models/artcle_test.rb
      remove      test/fixtures/artcles.yml
```

Railsアプリケーションをコマンドで操作する
------------------------------------

### `bin/rails console`

`bin/rails console`コマンドを実行すると、Railsの完全な環境（モデル、データベースなど）を読み込んで、対話型のIRBスタイルのシェルが起動します。Railsコンソールは、Ruby on Railsフレームワークの強力な機能であり、コマンドラインでアプリケーション全体を対話的に操作して、デバッグや調査を行えます。

Railsコンソールは、コードをプロトタイピングしてアイデアを試したり、ブラウザを使わずにデータベース内のレコードを作成・更新するのに便利です。

```bash
$ bin/rails console
my-app(dev):001:0> Post.create(title: 'First!')
```

Railsコンソールには、さまざまな便利機能が備わっています。
たとえば、データを変更せずにコードを試したい場合は、`bin/rails console --sandbox`で`sandbox`モードを利用できます。`sandbox`モードでは、すべてのデータベース操作がトランザクションでラップされ、コンソールを終了するとロールバックします。

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 8.1.0)
Any modifications you make will be rolled back on exit
my-app(dev):001:0>
```

`sandbox`オプションは、データベースに影響を与えずに破壊的な変更を安全にテストしたい場合に最適です。

`-e`オプションを使って、`console`コマンドのRails環境を指定することも可能です。

```bash
$ bin/rails console -e test
Loading test environment (Rails 8.1.0)
```

#### `app`オブジェクト

Railsコンソールでは、`app`と`helper`のインスタンスにアクセスできます。

`app`メソッドを使うと、以下のように名前付きルーティングヘルパーにアクセスできます。

```irb
my-app(dev)> app.root_path
=> "/"
my-app(dev)> app.edit_user_path
=> "profile/edit"
```

`app`オブジェクトを使うと、実際のサーバーを起動せずにアプリケーションにリクエストを送信することも可能です。

```irb
my-app(dev)> app.get "/", headers: { "Host" => "localhost" }
Started GET "/" for 127.0.0.1 at 2025-08-11 11:11:34 -0500
...

my-app(dev)> app.response.status
=> 200
```

NOTE: `app.get`メソッドでは、第2引数にヘッダーを渡す必要があります（"Host"が無指定の場合はRackクライアントがデフォルトで"www.example.com"を使うため）。アプリケーションを変更して、常に`localhost`を使うように設定やイニシャライザで指定することも可能です。

上述したような「リクエスト送信」が可能な理由は、`app`オブジェクトがRailsが統合テストで使うものと同じだからです。

```irb
my-app(dev)> app.class
=> ActionDispatch::Integration::Session
```

`app`オブジェクトは、`app.cookies`、`app.session`、`app.post`、および`app.response`などのメソッドを公開しています。このようにして、Railsコンソールで統合テストをシミュレートしてデバッグできます。

#### `helper`オブジェクト

`helper`オブジェクトは、RailsコンソールにおけるRailsのビュー層への直接的な入口です。このオブジェクトを使えば、コンソール内でビュー関連のフォーマットやユーティリティメソッドをテストすることも、アプリケーション内で定義されたカスタムヘルパー（`app/helpers`内）を利用することも可能になります。

```irb
my-app(dev)> helper.time_ago_in_words 3.days.ago
=> "3 days"

my-app(dev)> helper.l(Date.today)
=> "2025-08-11"

my-app(dev)> helper.pluralize(3, "child")
=> "3 children"

my-app(dev)> helper.truncate("This is a very long sentence", length: 22)
=> "This is a very long..."

my-app(dev)> helper.link_to("Home", "/")
=> "<a href=\"/\">Home</a>"
```

`custom_helper`メソッドが`app/helpers/*_helper.rb`ファイル内で定義されていれば、以下のように利用できます。

```irb
my-app(dev)> helper.custom_helper
"testing custom_helper"
```

### `bin/rails dbconsole`

`bin/rails dbconsole`コマンドを実行すると、利用中のデータベースの種類を自動的に識別して、そのデータベースに適したコマンドラインインターフェースに接続します。また、`config/database.yml`ファイルと現在のRails環境に基づいて、セッションを開始するためのコマンドラインパラメータも自動的に設定されます。

`dbconsole`セッションに入ると、通常の方法でデータベースと直接対話できます。たとえば、PostgreSQLを利用している場合、`bin/rails dbconsole`を実行すると次のようになります。

```bash
$ bin/rails dbconsole
psql (17.5 (Homebrew))
Type "help" for help.

booknotes_development=# help
You are using psql, the command-line interface to PostgreSQL.
Type:  \copyright for distribution terms
       \h for help with SQL commands
       \? for help with psql commands
       \g or terminate with semicolon to execute query
       \q to quit
booknotes_development=# \dt
                    List of relations
 Schema |              Name              | Type  | Owner
--------+--------------------------------+-------+-------
 public | action_text_rich_texts         | table | bhumi
 ...
```

`dbconsole`コマンドは、個別のデータベースコマンドを実行するよりもずっと便利です。このコマンドは、`database.yml`ファイルに基づく適切な引数を手動で指定して`psql`（または`mysql`や`sqlite`）コマンドを実行するのと同等です。

```bash
psql -h <host> -p <port> -U <username> <database_name>
```

`database.yml`ファイルで以下のようにPostgreSQLデータベースが設定されているとします。

```yml
development:
  adapter: postgresql
  database: myapp_development
  username: myuser
  password:
  host: localhost
```

この場合、`bin/rails dbconsole`コマンドを実行することは、以下を実行するのと同等です。

```bash
psql -h localhost -U myuser myapp_development
```

NOTE: `dbconsole`コマンドでサポートされているのは、MySQL（MariaDBを含む）、PostgreSQL、およびSQLite3です。`dbconsole`のエイリアスとして"db"も利用できます（`bin/rails db`）。

複数のデータベースを利用している場合、`bin/rails dbconsole`はデフォルトで`primary`データベースに接続します。接続するデータベースを指定するには、`--database`（または`--db`）オプションを使います。

```bash
$ bin/rails dbconsole --database=animals
```

### `bin/rails runner`

`bin/rails runner`コマンドを使うと、`bin/rails console`を必要とせずに、RubyのコードをRailsのコンテキストで非対話的に実行できます。たとえば次のようになります。

```bash
$ bin/rails runner "Model.long_running_method"
```

INFO: ランナーコマンドを実行するときに`bin/rails r`のように"r"というエイリアスが使えます。

`-e`で`runner`コマンドを実行する環境を指定できます。

```bash
$ bin/rails runner -e staging "Model.long_running_method"
```

ファイル内のRubyコードを`runner`で実行することもできます。

```bash
$ bin/rails runner lib/code_to_be_run.rb
```

`bin/rails runner`スクリプトは、デフォルトではRails Executorで自動的にラップされ、cronジョブなどのタスクのキャッチされていない例外を報告するのに便利です。

つまり、`bin/rails runner lib/long_running_scripts.rb`を実行することは、機能的に以下と同等です。

```ruby
Rails.application.executor.wrap do
  # lib/long_running_scripts.rb内のコードをここで実行する
end
```

`--skip-executor`オプションを渡すことで、この振る舞いをスキップできます。

```bash
$ bin/rails runner --skip-executor lib/long_running_script.rb
```

### `bin/rails boot`

`bin/rails boot`コマンドは、Railsアプリケーションを起動するための低レベルのRailsコマンドであり、Railsアプリケーションを起動することだけが目的です。具体的には、`config/boot.rb`および`config/application.rb`ファイルを読み込んで、アプリケーション環境が実行可能な状態になるようにします。

`boot`コマンドはアプリケーションを起動して終了するだけで、他には何もしないので、起動の問題をデバッグするときに便利です。アプリケーションの起動に失敗し、マイグレーションの実行やサーバーの起動などを行わずに起動フェーズを分離したい場合は、`bin/rails boot`で手軽にテストできます。

`boot`コマンドは、アプリケーションの初期化のタイミングを調査するのにも便利です。`bin/rails boot`をプロファイラでラップすることで、アプリケーションの起動に要する時間をプロファイリングできます。

アプリケーションをコマンドで調べる
-------------------------

### `bin/rails routes`

`bin/rails routes`コマンドは、アプリケーションで定義されているすべてのルーティングを一覧表示します。URIパターンやHTTP verb、対応するコントローラアクションも表示されます。

```bash
$ bin/rails routes
  Prefix  Verb  URI Pattern     Controller#Action
  books   GET   /books(:format) books#index
  books   POST  /books(:format) books#create
  ...
  ...
```

このコマンドは、ルーティングの問題を追跡したり、Railsアプリケーションのリソースとルートの概要を把握したりするのに役立ちます。`routes`コマンドの出力を`--controller(-c)`や`--grep(-g)`などのオプションで絞り込むことも可能です。

```bash
# 名前に"users"を含むコントローラのルーティングだけを表示する
$ bin/rails routes --controller users

# Admin::UsersController名前空間で処理されるルーティングだけを表示する
$ bin/rails routes -c admin/users

# -g（または--grep）で名前、パス、またはコントローラ/アクションで検索する
$ bin/rails routes -g users
```

`bin/rails routes --expanded`オプションを使うと、個別のルーティング情報がさらに詳しく表示されます。たとえば、ルーティングが`config/routes.rb`ファイルのどの行で定義されているかも確認できます。

```bash
$ bin/rails routes --expanded
--[ Route 1 ]--------------------------------------------------------------------------------
Prefix            |
Verb              |
URI               | /assets
Controller#Action | Propshaft::Server
Source Location   | propshaft (1.2.1) lib/propshaft/railtie.rb:49
--[ Route 2 ]--------------------------------------------------------------------------------
Prefix            | about
Verb              | GET
URI               | /about(.:format)
Controller#Action | posts#about
Source Location   | /Users/bhumi/Code/try_markdown/config/routes.rb:2
--[ Route 3 ]--------------------------------------------------------------------------------
Prefix            | posts
Verb              | GET
URI               | /posts(.:format)
Controller#Action | posts#index
Source Location   | /Users/bhumi/Code/try_markdown/config/routes.rb:4
```

TIP: developmentモードでは、ブラウザで`http://localhost:3000/rails/info/routes`にアクセスすることでも同じルーティング情報を確認できます。

### `bin/rails about`

`bin/rails about`を実行すると、Ruby、RubyGems、Rails、Railsのサブコンポーネントのバージョン、Railsアプリケーションのフォルダー名、現在のRailsの環境名とデータベースアダプタ、スキーマのバージョンが表示されます。
チーム内やフォーラムで質問するときや、セキュリティパッチが自分のアプリケーションに影響するかどうかを確認したいときなど、現在使っているRailsに関する情報が必要なときに便利です。

```bash
$ bin/rails about
About your application's environment
Rails version             8.1.0
Ruby version              3.2.0 (x86_64-linux)
RubyGems version          3.3.7
Rack version              3.0.8
JavaScript Runtime        Node.js (V8)
Middleware:               ActionDispatch::HostAuthorization, Rack::Sendfile, ...
Application root          /home/code/my_app
Environment               development
Database adapter          sqlite3
Database schema version   20250205173523
```

### `bin/rails initializers`

`bin/rails initializers`コマンドは、Railsで定義されているすべてのイニシャライザを、Railsが呼び出す順序で出力します。

```bash
$ bin/rails initializers
ActiveSupport::Railtie.active_support.deprecator
ActionDispatch::Railtie.action_dispatch.deprecator
ActiveModel::Railtie.active_model.deprecator
...
Booknotes::Application.set_routes_reloader_hook
Booknotes::Application.set_clear_dependencies_hook
Booknotes::Application.enable_yjit
```

このコマンドは、イニシャライザ同士の依存関係が存在していて、実行順序が重要な場合に便利です。イニシャライザの前後でどんなイニシャライザが実行されるかをこのコマンドで確認し、イニシャライザ間の関係を把握できます。Railsは、最初にフレームワークのイニシャライザを実行し、その後に`config/initializers/`ディレクトリで定義されたアプリケーションのイニシャライザを実行します。

### `bin/rails middleware`

`bin/rails middleware`コマンドは、Railsアプリケーションの全Rackミドルウェアスタックを、各リクエストに対してミドルウェアが実行される正確な順序で表示します。

```bash
$ bin/rails middleware
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActionDispatch::ServerTiming
...
```

このコマンドは、Railsアプリケーションのミドルウェアスタックを確認して、どれがgemによって追加されたかを把握したり（例: Devise gemで追加される`Warden::Manager`）、デバッグやプロファイリングを行ったりするのに便利です。

### `bin/rails stats`

`bin/rails stats`コマンドは、アプリケーション内のさまざまなコンポーネントのコード行数（LOC）やクラス数、メソッド数などを表示します。

```bash
$ bin/rails stats
+----------------------+--------+--------+---------+---------+-----+-------+
| Name                 |  Lines |    LOC | Classes | Methods | M/C | LOC/M |
+----------------------+--------+--------+---------+---------+-----+-------+
| Controllers          |    309 |    247 |       7 |      37 |   5 |     4 |
| Helpers              |     10 |     10 |       0 |       0 |   0 |     0 |
| Jobs                 |      7 |      2 |       1 |       0 |   0 |     0 |
| Models               |     89 |     70 |       6 |       3 |   0 |    21 |
| Mailers              |     10 |     10 |       2 |       1 |   0 |     8 |
| Channels             |     16 |     14 |       1 |       2 |   2 |     5 |
| Views                |    622 |    501 |       0 |       1 |   0 |   499 |
| Stylesheets          |    584 |    495 |       0 |       0 |   0 |     0 |
| JavaScript           |     81 |     62 |       0 |       0 |   0 |     0 |
| Libraries            |      0 |      0 |       0 |       0 |   0 |     0 |
| Controller tests     |    117 |     75 |       4 |       9 |   2 |     6 |
| Helper tests         |      0 |      0 |       0 |       0 |   0 |     0 |
| Model tests          |     21 |      9 |       3 |       0 |   0 |     0 |
| Mailer tests         |      7 |      5 |       1 |       1 |   1 |     3 |
| Integration tests    |      0 |      0 |       0 |       0 |   0 |     0 |
| System tests         |     51 |     41 |       1 |       4 |   4 |     8 |
+----------------------+--------+--------+---------+---------+-----+-------+
| Total                |   1924 |   1541 |      26 |      58 |   2 |    24 |
+----------------------+--------+--------+---------+---------+-----+-------+
  Code LOC: 1411     Test LOC: 130     Code to Test Ratio: 1:0.1
```

### `bin/rails time:zones:all`

`bin/rails time:zones:all`コマンドは、Active Supportが認識しているすべてのタイムゾーンの完全なリストを、UTCオフセットとRailsのタイムゾーン識別子とともに表示します。

たとえば、`bin/rails time:zones:local`コマンドを使うと、システムのタイムゾーンを確認できます。

```bash
$ bin/rails time:zones:local

* UTC -06:00 *
Central America
Central Time (US & Canada)
Chihuahua
Guadalajara
Mexico City
Monterrey
Saskatchewan
```

このコマンドは、`config/application.rb`で`config.time_zone`を設定するときに、正確なRailsのタイムゾーン名とスペル（例: "Pacific Time (US & Canada)"）が必要な場合や、ユーザー入力のバリデーションやデバッグ時に役立ちます。

アセットを管理する
---------------

`bin/rails assets:*`コマンドを使って、`app/assets/`ディレクトリ内のアセットを管理できます。

`assets:`名前空間に属する利用可能なすべてのコマンドの一覧は、以下のように表示できます。

```bash
$ bin/rails -T assets
bin/rails assets:clean[count]  # Removes old files in config.assets.output_path
bin/rails assets:clobber       # Remove config.assets.output_path
bin/rails assets:precompile    # Compile all the assets from config.assets.paths
bin/rails assets:reveal        # Print all the assets available in config.assets.paths
bin/rails assets:reveal:full   # Print the full path of assets available in config.assets.paths
```

`bin/rails assets:precompile`コマンドを使って`app/assets/`ディレクトリ内のアセットをプリコンパイルできます。プリコンパイルについて詳しくは、[アセットパイプラインガイド](asset_pipeline.html#アセットのプリコンパイル)を参照してください。

`bin/rails assets:clean`コマンドを使って、古いコンパイル済みアセットを削除できます。`assets:clean`コマンドは、新しいアセットがビルドされている間にまだ古いアセットにリンクしている可能性のある状態でのローリングデプロイが可能になります。

`public/assets/`ディレクトリ内のアセットを完全に削除したい場合は、`bin/rails assets:clobber`コマンドを使えます。

データベースを管理する
---------------------

このセクションのコマンドである`bin/rails db:*`は、すべてデータベースのセットアップやマイグレーションの管理などに関するものです。

以下のように`db:`名前空間を指定すると、`db:*`のすべてのコマンドの一覧を表示できます。

```bash
$ bin/rails -T db
bin/rails db:create              # Create the database from DATABASE_URL or
bin/rails db:drop                # Drop the database from DATABASE_URL or
bin/rails db:encryption:init     # Generate a set of keys for configuring
bin/rails db:environment:set     # Set the environment value for the database
bin/rails db:fixtures:load       # Load fixtures into the current environments
bin/rails db:migrate             # Migrate the database (options: VERSION=x,
bin/rails db:migrate:down        # Run the "down" for a given migration VERSION
bin/rails db:migrate:redo        # Roll back the database one migration and
bin/rails db:migrate:status      # Display status of migrations
bin/rails db:migrate:up          # Run the "up" for a given migration VERSION
bin/rails db:prepare             # Run setup if database does not exist, or run
bin/rails db:reset               # Drop and recreate all databases from their
bin/rails db:rollback            # Roll the schema back to the previous version
bin/rails db:schema:cache:clear  # Clear a db/schema_cache.yml file
bin/rails db:schema:cache:dump   # Create a db/schema_cache.yml file
bin/rails db:schema:dump         # Create a database schema file (either db/
bin/rails db:schema:load         # Load a database schema file (either db/
bin/rails db:seed                # Load the seed data from db/seeds.rb
bin/rails db:seed:replant        # Truncate tables of each database for current
bin/rails db:setup               # Create all databases, load all schemas, and
bin/rails db:version             # Retrieve the current schema version number
bin/rails test:db                # Reset the database and run `bin/rails test`
```

### データベースを作成する

`db:create`と`db:drop`コマンドは、現在の環境のデータベースを作成または削除します（`db:create:all`、`db:drop:all`で全環境のデータベースを対象にできます）。

`db:seed`コマンドは、`db/seeds.rb`からサンプルデータを読み込みます。
`db:seed:replant`コマンドは、現在の環境の各データベースのテーブルの内容を空にしてからseedデータを読み込みます。

`db:setup`コマンドは、すべてのデータベースを作成し、すべてのスキーマを読み込み、seedデータで初期化します（次のの`db:reset`コマンドのように最初にデータベースを削除することはありません）。

`db:reset`コマンドは、現在の環境のすべてのデータベースを削除して再作成し、スキーマから読み込み、seedデータを読み込みます（上記のコマンドの組み合わせです）。

NOTE: seedデータについて詳しくは、[Active Record Migrationsガイド](active_record_migrations.html#マイグレーションとseedデータ)を参照してください。

### マイグレーションを実行する

`db:migrate`コマンドは、Railsアプリケーションでよく使われるコマンドです。このコマンドは、すべての新しい（つまり未実行の）マイグレーションを実行することで、データベースをマイグレーションします。

`db:migrate:up`コマンドを実行すると、VERSION引数で指定したマイグレーションの`up`メソッドを実行します。
`db:migrate:down`コマンドを実行すると、同様に`down`メソッドを実行します。

```bash
$ bin/rails db:migrate:down VERSION=20250812120000
```

`db:rollback`コマンドは、スキーマを直前のバージョンにロールバックします（`STEP=n`引数でステップ数を指定することも可能です）。

`db:migrate:redo`コマンドは、データベースをマイグレーション1つ分ロールバックしてから、再度マイグレーションを実行します。これは、上記の2つのコマンドの組み合わせです。

`db:migrate:status`コマンドも利用できます。これは、どのマイグレーションが実行済みで、どのマイグレーションが保留中であるかを表示します。

```bash
$ bin/rails db:migrate:status
database: db/development.sqlite3

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20250101010101  Create users
   up     20250102020202  Add email to users
  down    20250812120000  Add age to users
```

NOTE: データベースのマイグレーションに関する概念やその他のマイグレーションコマンドについて詳しくは、[Active Recordマイグレーションガイド](active_record_migrations.html)を参照してください。

### スキーマを管理する

Railsアプリケーションのデータベーススキーマを管理するための主なコマンドは、`db:schema:dump`と`db:schema:load`の2つです。

`db:schema:dump`コマンドは、データベースの現在のスキーマを読み取り、`db/schema.rb`ファイル（スキーマ形式を`sql`に設定している場合は`db/structure.sql`）に書き出します。マイグレーションを実行した後、Railsは自動的に`sсhema:dump`を呼び出すため、スキーマファイルは常に最新の状態に保たれます（手動で変更する必要はありません）。

このスキーマファイルは、データベースの設計図であり、テストや開発のための新しい環境をセットアップするのに役立ちます。スキーマはバージョン管理されているため、時間の経過に伴うスキーマの変更を確認できます。

`db:schema:load`コマンドは、`db/schema.rb`（または`db/structure.sql`）のデータベーススキーマを削除して再作成します。これは、各マイグレーションを1つずつ再実行せずに、直接行われます。

このコマンドは、長年に渡る多数のマイグレーションを1つずつ実行せずに、データベースを現在のスキーマに短時間でリセットしたいときに便利です。たとえば、`db:setup`コマンドをを実行すると、データベースを作成した後、シードデータを読み込む前に`db:schema:load`コマンドも呼び出されます。

`db:schema:dump`は`schema.rb`ファイルを書き込むコマンドであり、`db:schema:load`はそのファイルを読み込むコマンドだと考えるとよいでしょう。

### その他のユーティリティコマンド

#### `bin/rails db:version`

`bin/rails db:version`コマンドは、データベースの現在のバージョンを表示します。トラブルシューティングで便利です。

```bash
$ bin/rails db:version

database: storage/development.sqlite3
Current version: 20250806173936
```

#### `db:fixtures:load`

`db:fixtures:load`コマンドは、フィクスチャを現在の環境のデータベースに読み込みます。特定のフィクスチャを読み込むには、`FIXTURES=x,y`を指定します。`test/fixtures/`内のサブディレクトリから読み込むには、`FIXTURES_DIR=z`を指定します。

```bash
$ bin/rails db:fixtures:load
   -> Loading fixtures from test/fixtures/users.yml
   -> Loading fixtures from test/fixtures/books.yml
```

#### `db:system:change`

`db:system:change`コマンドは、`config/database.yml`ファイルとデータベースgemを指定のデータベースに変更できます。これにより、既存のアプリケーションでデータベースを切り替えられるようになります。

```bash
$ bin/rails db:system:change --to=postgresql
    conflict  config/database.yml
Overwrite config/database.yml? (enter "h" for help) [Ynaqdhm] Y
       force  config/database.yml
        gsub  Gemfile
        gsub  Gemfile
...
```

#### `db:encryption:init`

`db:encryption:init`コマンドは、指定の環境でActive Record暗号化を設定するためのキーセットを生成します。

テストを実行する
-------------

`bin/rails test`コマンドは、アプリケーション内のさまざまな種類のテストを実行できます。
`bin/rails test --help`を実行すると、このコマンドのさまざまなオプションの良い例を参照できます。

以下のようにファイル名と行番号を指定して、特定のテストを実行できます。

```bash
  bin/rails test test/models/user_test.rb:27
```

行番号の範囲を指定して複数のテストを実行することも可能です。

```bash
  bin/rails test test/models/user_test.rb:10-20
```

テストファイルやディレクトリを同時に複数指定することも可能です。

```bash
  bin/rails test test/controllers test/integration/login_test.rb
```

RailsにはMinitestというテストフレームワークが付属しており、`test`コマンドで利用できるMinitestオプションもあります。

```bash
# /validation/という正規表現にマッチする名前のテストだけを実行する
$ bin/rails test -n /validation/
```

INFO: Railsで実行できるテストの種類や解説については、[テスティングガイド](testing.html)を参照してください。

その他の便利なコマンド
---------------------

### `bin/rails notes`

`bin/rails notes`は、特定のキーワードで始まるコードコメントを検索して表示します。`bin/rails notes --help`で利用法を表示できます。

デフォルトでは、`app`、`config`、`db`、`lib`、`test`ディレクトリにある、拡張子が`.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js`、`.erb`のファイルの中から、「FIXME」「OPTIMIZE」「TODO」キーワードで始まるコメントを検索します（訳注: コメントのキーワードが`[FIXME]`のように`[]`で囲まれていると検索されません）。

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
```

#### アノテーションを指定する

`--annotations`（または`-a`）引数で特定のアノテーションを指定できます。アノテーションは大文字小文字を区別する点にご注意ください。

```bash
$ bin/rails notes --annotations FIXME RELEASE
app/controllers/admin/users_controller.rb:
  * [101] [RELEASE] We need to look at this before next release
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 17] [FIXME]
```

#### タグを追加する

`config.annotations.register_tags`設定でデフォルトのタグを追加できます。

```ruby
config.annotations.register_tags("DEPRECATEME", "TESTME")
```

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] do A/B testing on this
  * [ 42] [TESTME] this needs more functional tests
  * [132] [DEPRECATEME] ensure this method is deprecated in next release
```

#### ディレクトリを追加する

`config.annotations.register_directories`設定でデフォルトのディレクトリを追加できます。

```ruby
config.annotations.register_directories("spec", "vendor")
```

#### ファイル拡張子を追加する

`config.annotations.register_extensions`設定でデフォルトのファイル拡張子を追加できます。

```ruby
config.annotations.register_extensions("scss", "sass") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

### `bin/rails tmp:`

`Rails.root/tmp`ディレクトリには一時ファイルが保存されます（*nix系でいう`/tmp`ディレクトリと同様です）。一時ファイルには、プロセスIDのファイル、アクションキャッシュのファイルなどがあります。

`tmp:`名前空間には、`Rails.root/tmp`ディレクトリを作成・削除する以下のタスクがあります。

```bash
$ bin/rails tmp:cache:clear        # `tmp/cache`をクリアする
$ bin/rails tmp:sockets:clear      # `tmp/sockets`をクリアする
$ bin/rails tmp:screenshots:clear  # `tmp/screenshots`をクリアする
$ bin/rails tmp:clear              # すべてのキャッシュ、ソケット、スクリーンショットをクリアする
$ bin/rails tmp:create             # キャッシュ、ソケット、PID用の`tmp`ディレクトリを作成する
```

### `bin/rails secret`

`bin/rails secret`コマンドは、Railsアプリケーションでシークレットキーとして使うための、暗号学的に安全なランダム文字列を生成します。

```bash
$ bin/rails secret
4d39f92a661b5afea8c201b0b5d797cdd3dcf8ae41a875add6ca51489b1fbbf2852a666660d32c0a09f8df863b71073ccbf7f6534162b0a690c45fd278620a63
```

このコマンドは、アプリケーションの`config/credentials.yml.enc`ファイルにシークレットキーを設定する場合に便利です。

### `bin/rails credentials`

`bin/rails credentials`コマンドは、暗号化されたcredential（資格情報）へのアクセスを提供します。これにより、アクセストークンやデータベースのパスワードなどをアプリ内に安全に保存でき、多数の環境変数に依存する必要がなくなります。

暗号化されたYMLファイル`config/credentials.yml.enc`に値を追加するには、`credentials:edit`コマンドを実行します。

```bash
$ bin/rails credentials:edit
```

実行すると、復号したcredentialファイルがエディタで開かれます（エディタは`$VISUAL`または`$EDITOR`で設定します）。変更を保存すると、ファイルの内容は自動的に暗号化されます。

`:show`コマンドを使って、復号したcredentialファイルを表示することも可能です。表示内容は以下のようになります（これはサンプルアプリケーションのものであり、機密データではありません）。

```bash
$ bin/rails credentials:show
# aws:
#   access_key_id: 123
#   secret_access_key: 345
active_record_encryption:
  primary_key: 99eYu7ZO0JEwXUcpxmja5PnoRJMaazVZ
  deterministic_key: lGRKzINTrMTDSuuOIr6r5kdq2sH6S6Ii
  key_derivation_salt: aoOUutSgvw788fvO3z0hSgv0Bwrm76P0

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 6013280bda2fcbdbeda1732859df557a067ac81c423855aedba057f7a9b14161442d9cadfc7e48109c79143c5948de848ab5909ee54d04c34f572153466fc589
```

credentialsについて詳しくは、[Railsセキュリティガイド](security.html#独自のcredential)を参照してください。

TIP: このコマンドの詳しい説明は、`bin/rails credentials --help`で参照できます。

### カスタムRakeタスク

アプリケーションで独自のrakeタスクを作成したい場合があります（古いレコードをデータベースから削除するなど）。これは、`bin/rails generate task`コマンドで行えます。
カスタムrakeタスクファイルの拡張子は`.rake`で、Railsアプリケーションの`lib/tasks/`フォルダに配置されます。
たとえば以下のようにコマンドを実行します。

```bash
$ bin/rails generate task cool
create  lib/tasks/cool.rake
```

この`cool.rake`ファイルで、以下のようにタスクを定義できます。

```ruby
desc "手短でクールなタスクの概要"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # 任意の有効なRubyコードを書ける
end
```

カスタムrakeタスクに引数を渡せるようにするには、以下のようにします。

```ruby
task :task_name, [:arg_1] => [:prerequisite_1, :prerequisite_2] do |task, args|
  argument_1 = args.arg_1
end
```

タスクを名前空間内で定義することで、タスクをグループ化できます。

```ruby
namespace :db do
  desc "データベース関連の作業を行うタスク"
  task :my_db_task do
    # ...
  end
end
```

タスクの呼び出しは以下のように行います。

```bash
$ bin/rails task_name
$ bin/rails "task_name[value 1]"                 # 引数の文字列全体を引用符で囲むこと
$ bin/rails "task_name[value 1, value2, value3]" # 複数の引数はカンマで区切る
$ bin/rails db:nothing
```

アプリケーションモデルの操作やデータベースクエリの実行などが必要なタスクは、以下のように`environment`タスクを使ってRailsアプリケーションを読み込めます。

```ruby
task task_that_requires_app_code: [:environment] do
  puts User.count
end
```
