コマンドラインツール
======================

このガイドの内容:

* Railsアプリケーションを作成する方法
* モデル、コントローラ、データベースのマイグレーションファイル、および単体テストを作成する方法
* 開発用サーバーを起動する方法
* インタラクティブシェルを利用して、オブジェクトを実験する方法

--------------------------------------------------------------------------------


NOTE: このチュートリアルは、[Railsをはじめよう](getting_started.html)で基本的なRailsの知識を身につけていることを前提としています。

Railsアプリを作成する
--------------------

最初に、`rails new`コマンドで簡単なRailsアプリケーションを作成してみましょう。

このアプリケーションを使って、このガイドで説明されているすべてのコマンドを動かしながら発見していくことにします。

INFO: rails gemがインストールされていない場合は、`gem install rails`を実行することでインストールできます。

### `rails new`

`rails new`コマンドに渡す第1引数は、アプリケーションの名前です。

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

こんな短いコマンドを入力するだけで、Railsが膨大なファイルをセットアップします。これでRailsのディレクトリ構造全体と、このシンプルなアプリケーションをすぐに実行するのに必要なすべてのコードが揃います。

生成をスキップしたいファイルやライブラリがある場合は、`rails new`コマンドに以下の引数のいずれかを追加します。

| 引数                     | 説明                                               |
| ----------------------- | -------------------------------------------------- |
| `--skip-git`            | git init、.gitignore、.gitattributesをスキップ        |
| `--skip-docker`         | Dockerfile、.dockerignore、bin/docker-entrypointをスキップ |
| `--skip-keeps`          | バージョン管理用の.keepファイルをスキップ                 |
| `--skip-action-mailer`  | Action Mailerのファイルをスキップ                      |
| `--skip-action-mailbox` | Action Mailbox gemをスキップ                         |
| `--skip-action-text`    | Action Text gemをスキップ                            |
| `--skip-active-record`  | Active Recordファイルをスキップ                       |
| `--skip-active-job`     | Active Jobをスキップ                                 |
| `--skip-active-storage` | Active Storageのファイルをスキップ                     |
| `--skip-action-cable`   | Action Cableのファイルをスキップ                       |
| `--skip-asset-pipeline` | アセットパイプラインをスキップ                           |
| `--skip-javascript`     | JavaScriptファイルをスキップ                           |
| `--skip-hotwire`        | Hotwire統合をスキップ                                 |
| `--skip-jbuilder`       | jbuilder gemをスキップ                               |
| `--skip-test`           | テストファイルをスキップ                                |
| `--skip-system-test`    | システムテストのファイルをスキップ                        |
| `--skip-bootsnap`       | bootsnap gemをスキップ                               |
| `--skip-dev-gems`       | development用gemの追加をスキップ                      |
| `--skip-thruster`       | Thrusterのセットアップをスキップ                       |
| `--skip-rubocop`        | RuboCopのセットアップをスキップ                       |
| `--skip-brakeman`       | Brakemanのセットアップをスキップ                       |
| `--skip-ci`             | GitHub CIファイルのセットアップをスキップ                 |
| `--skip-kamal`          | Kamalのセットアップをスキップ                       |
| `--skip-solid`          | Solid Cache、Solid Queue、Solid Cableのセットアップをスキップ |

`rails new`には他にも多くのオプションを渡せます。すべてのオプションを表示するには`rails new --help`を実行してください。

### さまざまなデータベースを事前に指定する

新しいRailsアプリケーションを作成するとき、アプリケーションで使うデータベースの種類を指定するオプションがあります。これにより、数分の時間と、確実に多くの入力を節約できます。

`--database=postgresql`オプションを指定した場合の動作を見てみましょう。

```bash
$ rails new petstore --database=postgresql
      create
      create  app/controllers
      create  app/helpers
...
```

それに応じて、`config/database.yml`に書き込まれる内容は以下のようになります。

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
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: petstore_development
...
```

PostgreSQLを選択したことに対応するデータベース設定が生成されたことがわかります。

### デフォルトをスキップする

一部のファイルの生成をスキップしたい場合や、一部のライブラリを完全にスキップしたい場合は、以下のように`rails new`コマンドに`--skip`で始まるオプション引数の1つを渡せます。

```bash
$ rails new sas --skip-active-storage
Based on the specified options, the following options will also be activated:

  --skip-action-mailbox [due to --skip-active-storage]
  --skip-action-text [due to --skip-active-storage]

      create
      create  README.md
      ...
```

上の例では、Active Storageがスキップされるのに加えて、Active Storage機能に依存しているAction MailboxとAction Textもスキップされます。

オプションの完全なリスト (スキップ可能なものを含む) については、`--help`で確認してください。

```bash
$ rails new --help
```

コマンドラインの基礎
-------------------

Railsを利用するうえで、きわめて重要なコマンドがいくつかあります。それらを利用頻度順に並べると以下のとおりです。

* `bin/rails console`
* `bin/rails server`
* `bin/rails test`
* `bin/rails generate`
* `bin/rails db:migrate`
* `bin/rails db:create`
* `bin/rails routes`
* `bin/rails dbconsole`
* `rails new app_name`

利用可能なrailsコマンドのリストは、`rails --help`で表示できます。利用できるコマンドは現在のディレクトリに応じて変わることがよくあります。各コマンドには説明があるので、必要なものを探せます。

```bash
$ rails --help
Usage:
  bin/rails COMMAND [options]

You must specify a command. The most common commands are:

  generate     Generate new code (short-cut alias: "g")
  console      Start the Rails console (short-cut alias: "c")
  server       Start the Rails server (short-cut alias: "s")
  ...

All commands can be run with -h (or --help) for more information.

In addition to those commands, there are:
about                               List versions of all Rails ...
assets:clean[keep]                  Remove old compiled assets
assets:clobber                      Remove compiled assets
assets:environment                  Load asset compile environment
assets:precompile                   Compile all the assets ...
...
db:fixtures:load                    Load fixtures into the ...
db:migrate                          Migrate the database ...
db:migrate:status                   Display status of migrations
db:rollback                         Roll the schema back to ...
db:schema:cache:clear               Clears a db/schema_cache.yml file
db:schema:cache:dump                Create a db/schema_cache.yml file
db:schema:dump                      Create a database schema file (either db/schema.rb or db/structure.sql ...
db:schema:load                      Load a database schema file (either db/schema.rb or db/structure.sql ...
db:seed                             Load the seed data ...
db:version                          Retrieve the current schema ...
...
restart                             Restart app by touching ...
tmp:create                          Create tmp directories ...
```

### `bin/rails server`

`bin/rails server`コマンドを実行すると、PumaというWebサーバーが起動します（PumaはRailsに標準でバンドルされます）。Webブラウザからアプリケーションにアクセスしたいときは、このコマンドを使います。

`bin/rails server`を実行することで、新しいRailsアプリケーションを作成後すぐにRailsアプリケーションを起動できます。

```bash
$ cd my_app
$ bin/rails server
=> Booting Puma
=> Rails 8.0.0 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.0 (ruby 3.1.3-p185) ("The Eagle of Durango")
*  Min threads: 5
*  Max threads: 5
*  Environment: development
*          PID: 5295
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl-C to stop
```

わずか3つのコマンドを実行しただけで、Railsサーバーを3000番ポートで起動できるようになりました。ブラウザを立ち上げて、[http://localhost:3000](http://localhost:3000)を開いてみてください。Railsアプリケーションが動作していることが分かります。

INFO: サーバーを起動する際には`bin/rails s`のように"s"というエイリアスが使えます。

リッスンするポートは`-p`オプションで指定できます。`-e`オプションでサーバーの環境を変更できます。デフォルトではdevelopment（開発）環境で実行されます。

```bash
$ bin/rails server -e production -p 4000
```

`-b`オプションを使うと、Railsを特定のIPにバインドできます。デフォルトはlocalhostです。`-d`オプションを使うと、サーバーをデーモンとして起動できます。

### `bin/rails generate`

`bin/rails generate`コマンドは、テンプレートを用いてさまざまなものを作成します。`bin/rails generate`を実行すると、利用可能なジェネレータの一覧が表示されます。

INFO: ジェネレータコマンドを実行する際には`bin/rails g`のように「g」というエイリアスが使えます。

```bash
$ bin/rails generate
Usage:
  bin/rails generate GENERATOR [args] [options]

...
...

Please choose a generator below.

Rails:
  assets
  channel
  controller
  generator
  ...
  ...
```

NOTE: ジェネレータgemをインストールしたり、プラグインに付属しているジェネレータをインストールしたりすることで、ジェネレータを追加できます。自分でジェネレータを作成することも可能です。

ジェネレータを使うと、アプリケーションを動かすのに必要な[**ボイラープレートコード**](https://ja.wikipedia.org/wiki/%E3%83%9C%E3%82%A4%E3%83%A9%E3%83%BC%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%82%B3%E3%83%BC%E3%83%89)（定形コード）を書かなくて済むため、多くの時間を節約できます。

それではコントローラジェネレータを使って、コントローラを作ってみましょう。どんなコマンドを使えばよいかをジェネレータに聞いてみましょう。

INFO: Railsのすべてのコマンドにはヘルプがついています。多くの *nix（LinuxなどのUnixライクなOS）のユーティリティと同じようにコマンドの末尾に`--help`もしくは`-h`オプションを追加します（例: `rails server --help`）。

```bash
$ bin/rails generate controller
Usage:
  bin/rails generate controller NAME [action action] [options]

...
...

Description:
    ...

    To create a controller within a module, specify the controller name as a path like 'parent_module/controller_name'.

    ...

Example:
    `bin/rails generate controller CreditCards open debit credit close`

    Credit card controller with URLs like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb
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

どんなファイルが生成されたのでしょうか？アプリケーションの中にさまざまなディレクトリが作成され、コントローラファイル、ビューファイル、機能テストのファイル、ビューヘルパー、JavaScriptファイル、スタイルシートファイルが作成されました。

生成されたコントローラ（`app/controllers/greetings_controller.rb`）をエディタで開いて以下のように変更してみましょう。

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "こんにちは、ご機嫌いかがですか？"
  end
end
```

次はビュー（`app/views/greetings/hello.html.erb`）を編集して、メッセージを表示できるようにします。

```erb
<h1>ごあいさつ</h1>
<p><%= @message %></p>
```

`bin/rails server`でサーバーを起動します。

```bash
$ bin/rails server
=> Booting Puma...
```

アクセスするURLは[http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)です。

INFO: 通常のRailsアプリケーションでは、URLは`http://ホスト名/コントローラ名/アクション名`というパターンになります。アクション名を指定しない`http://ホスト名/コントローラ名`というパターンのURLは、コントローラの**`index`**アクションにアクセスします。

Railsにはデータモデルを生成するジェネレータもあります。

```bash
$ bin/rails generate model
Usage:
  bin/rails generate model NAME [field[:type][:index] field[:type][:index]] [options]

...

ActiveRecord options:
      [--migration], [--no-migration]        # Indicates when to generate migration
                                             # Default: true

...

Description:
    Generates a new model. Pass the model name, either CamelCased or
    under_scored, and an optional list of attribute pairs as arguments.

...
```

NOTE: `type`パラメータで指定できるフィールド型については、[APIドキュメント][API docs]に記載されている、[`SchemaStatements`][]モジュールの[`add_column`][]メソッドの説明を参照してください。`index`パラメータを指定すると、カラムに対応するインデックスも生成されます。

ここでは直接モデルを作成する代わりに（モデルの作成は後ほど行います）、scaffoldをセットアップしましょう。Railsにおける**scaffold**（足場）とは、「モデル」「モデルのマイグレーションファイル「モデルを操作するコントローラ」「データを操作・表示するビュー」「それぞれのテストファイル」一式をさします。

"HighScore"という名前の単体リソースを準備してみましょう。このリソースの役割はビデオゲームでの最高得点を記録することです。

```bash
$ bin/rails generate scaffold HighScore game:string score:integer
    invoke  active_record
    create    db/migrate/20190416145729_create_high_scores.rb
    create    app/models/high_score.rb
    invoke    test_unit
    create      test/models/high_score_test.rb
    create      test/fixtures/high_scores.yml
    invoke  resource_route
     route    resources :high_scores
    invoke  scaffold_controller
    create    app/controllers/high_scores_controller.rb
    invoke    erb
    create      app/views/high_scores
    create      app/views/high_scores/index.html.erb
    create      app/views/high_scores/edit.html.erb
    create      app/views/high_scores/show.html.erb
    create      app/views/high_scores/new.html.erb
    create      app/views/high_scores/_form.html.erb
    invoke    test_unit
    create      test/controllers/high_scores_controller_test.rb
    create      test/system/high_scores_test.rb
    invoke    helper
    create      app/helpers/high_scores_helper.rb
    invoke      test_unit
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    create      app/views/high_scores/_high_score.json.jbuilder
```

ジェネレータは、モデル、ビュー、コントローラ、マイグレーション（`high_scores`テーブルとフィールドを作成します）を生成し、この**リソース**用のルーティングを追加します。また、これらのテストも作成します。

scaffold生成の次は、**マイグレーション**（migration: 移行）を実行する必要があります。マイグレーションを実行するには、データベースのスキーマを変更するRubyのコード（上で出力された`20190416145729_create_high_scores.rb`にあるコードのことです）を実行する必要があります。
データベースとはどのデータベースでしょうか？`bin/rails db:migrate`コマンドを実行すると、RailsはSQLite3に新しいデータベースを作ります。このコマンドについて詳しくは後述します。

```bash
$ bin/rails db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: 単体テスト（unit test）について説明します。単体テストとは、コードをテストしてアサーション（assertion: コードが期待どおりに動作するかどうかを確認すること）を行うコードです。単体テストでは、モデルのメソッドなどのコードの一部分を取り出して、入力と出力をテストします。単体テストはあなたにとって友人と同じぐらい大切なものです。単体テストをきちんと書いておくと幸せになれるという事実に早いうちに気づいた人は、間違いなく他の人より先に幸せになれるでしょう。単体テストについて詳しくは[テスティングガイド](testing.html)を参照してください。

Railsが作ってくれたインターフェースを見てみましょう。

```bash
$ bin/rails server
```

ブラウザで[http://localhost:3000/high_scores](http://localhost:3000/high_scores)を開いてみましょう。それではハイスコアを更新するとしましょう（スペースインベーダーで55,160点とかね！）（訳注: 2003年にDonald Hayesがたたき出したスコアです）。

[API docs]: http://api.rubyonrails.org/
[`SchemaStatements`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html
[`add_column`]: http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column

### `bin/rails console`

`console`コマンドを使うと、コマンドラインでRailsアプリケーションと対話的操作を実行できるようになります。`bin/rails console`は内部でRubyのIRBを使っているので、IRBを使ったことがあれば簡単に扱えます。IRBは、思いついたアイデアを試してみたり、ウェブサイトにアクセスすることなくサーバのデータを変更したりするときに便利です。

INFO: コンソールコマンドを実行するときに`bin/rails c`のように"c"というエイリアスが使えます。

以下のように`console`コマンドを実行する環境も指定できます。

```bash
$ bin/rails console -e staging
```

コードを動かしたときにデータが変更されないようにするには、以下のように`bin/rails console --sandbox`を実行します。

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 8.0.0)
Any modifications you make will be rolled back on exit
app(dev)>
```

#### `app`オブジェクトと`helper`オブジェクト

`bin/rails console`の実行中、`app`オブジェクトと`helper`オブジェクトにアクセスできます。

`app`メソッドを使うと、名前付きルーティングヘルパーにアクセスできます。リクエストを投げることもできます。

```irb
irb> app.root_path
=> "/"

irb> app.get _
Started GET "/" for 127.0.0.1 at 2014-06-19 10:41:57 -0300
...
```

`helper`メソッドを使うと、Railsのアプリケーションヘルパーと自分が実装したヘルパーにアクセスできます。

```irb
irb> helper.time_ago_in_words 30.days.ago
=> "about 1 month"

irb> helper.my_custom_helper
=> "my custom helper"
```

### `bin/rails dbconsole`

`bin/rails dbconsole`コマンドは使っているデータベースを見つけて、適切なデータベースコマンドラインツールを起動します（コマンドラインツールに必要な引数も与えられます）。MySQL（MariaDBも含む）、PostgreSQL、SQLite、そしてSQLite3をサポートしています。

INFO: DBコンソールコマンドを実行するときに`bin/rails db`のように「db」というエイリアスが使えます。

データベースを複数使っている場合（マルチプルデータベース）、`bin/rails dbconsole`はデフォルトでprimaryデータベースに接続します。接続するデータベースは、`--database`または`--db`で指定できます。

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

`rails runner`スクリプトは、デフォルトではRails Executorで自動的にラップされ、cronジョブなどのタスクのキャッチされていない例外を報告するのに便利です。

つまり、`rails runner lib/long_running_scripts.rb`を実行することは、機能的に以下と同等です。

```ruby
Rails.application.executor.wrap do
  # lib/long_running_scripts.rb内のコードをここで実行する
end
```

`--skip-executor`オプションを渡すことで、この振る舞いをスキップできます。

```bash
$ bin/rails runner --skip-executor lib/long_running_script.rb
```

### `bin/rails destroy`

`destroy`は`generate`の逆の操作です。ジェネレータコマンドで生成された内容を調べて、それを取り消します。

INFO: `bin/rails d`のように、「d」というエイリアスで`destroy`コマンドを実行することもできます。

```bash
$ bin/rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke    test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```

```bash
$ bin/rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke    test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

### `bin/rails about`

`bin/rails about`を実行すると、Ruby、RubyGems、Rails、Railsのサブコンポーネントのバージョン、Railsアプリケーションのフォルダー名、現在のRailsの環境名とデータベースアダプタ、スキーマのバージョンが表示されます。
チーム内やフォーラムで質問するときや、セキュリティパッチが自分のアプリケーションに影響するかどうかを確認したいときなど、現在使っているRailsに関する情報が必要なときに便利です。

```bash
$ bin/rails about
About your application's environment
Rails version             8.0.0
Ruby version              3.2.0 (x86_64-linux)
RubyGems version          3.3.7
Rack version              3.0.8
JavaScript Runtime        Node.js (V8)
Middleware:               ActionDispatch::HostAuthorization, Rack::Sendfile, ActionDispatch::Static, ActionDispatch::Executor, ActionDispatch::ServerTiming, ActiveSupport::Cache::Strategy::LocalCache::Middleware, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, ActionDispatch::RemoteIp, Sprockets::Rails::QuietAssets, Rails::Rack::Logger, ActionDispatch::ShowExceptions, WebConsole::Middleware, ActionDispatch::DebugExceptions, ActionDispatch::ActionableExceptions, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ContentSecurityPolicy::Middleware, ActionDispatch::PermissionsPolicy::Middleware, Rack::Head, Rack::ConditionalGet, Rack::ETag, Rack::TempfileReaper
Application root          /home/foobar/my_app
Environment               development
Database adapter          sqlite3
Database schema version   20180205173523
```

### `bin/rails assets`

`bin/rails assets:precompile`を実行すると、`app/assets`配下のファイルをプリコンパイルできます。`bin/rails assets:clean`を実行すると、古くなったコンパイル済みのファイルを削除できます。`assets:clean`は、古いアセットへのリンクを維持しながら新しいアセットをビルドして最新の状態にするので、「ローリングデプロイ（rolling deploy）」にも使えます。

`public/assets`ディレクトリのアセットを完全に削除するには`bin/rails assets:clobber`を実行します。

### `bin/rails db`

`bin/rails`コマンドの`db:`名前空間に属するタスクのうち、最もよく使われるのは`migrate`と`create`です。マイグレーションに関するタスク（`up`, `down`, `redo`, `reset`）は一度ひととおり試してみることをおすすめします。`bin/rails db:version`は、トラブルシューティングで現在のデータベースの状況を調べるときに便利です。

マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。

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
  * [ 17] [FIXME]
```

#### アノテーション

`--annotations`引数で特定のアノテーションを指定できます。デフォルトでは「FIXME」「OPTIMIZE」「TODO」を検索します。アノテーションは大文字小文字を区別する点にご注意ください。

```bash
$ bin/rails notes --annotations FIXME RELEASE
app/controllers/admin/users_controller.rb:
  * [101] [RELEASE] We need to look at this before next release
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 17] [FIXME]
```

#### タグ

`config.annotations.register_tags`設定でデフォルトのタグを追加できます。このオプションにはタグのリストを渡せます。

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

#### ディレクトリ

`config.annotations.register_directories`設定にデフォルトディレクトリを追加できます。このオプションにはディレクトリ名のリストを渡せます。

```ruby
config.annotations.register_directories("spec", "vendor")
```

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 13] [OPTIMIZE] Refactor this code to make it faster
  * [ 17] [FIXME]

spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works

vendor/tools.rb:
  * [ 56] [TODO] Get rid of this dependency
```

#### 拡張子

`config.annotations.register_extensions`設定にデフォルトのファイル拡張子を追加できます。このオプションにはファイル拡張子のリストと、対応する正規表現を渡せます。

```ruby
config.annotations.register_extensions("scss", "sass") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

```bash
$ bin/rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/assets/stylesheets/application.css.sass:
  * [ 34] [TODO] Use pseudo element for this class

app/assets/stylesheets/application.css.scss:
  * [  1] [TODO] Split into multiple components

lib/school.rb:
  * [ 13] [OPTIMIZE] Refactor this code to make it faster
  * [ 17] [FIXME]

spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works

vendor/tools.rb:
  * [ 56] [TODO] Get rid of this dependency
```

### `bin/rails routes`

`bin/rails routes`で、すべての定義済みルーティングテーブルを表示できます。ルーティングの問題を解決するときや、アプリケーションのルーティング全体を理解するときに便利です。

### `bin/rails test`

INFO: Railsでの単体テストについて詳しくは、ガイドの[Railsアプリケーションをテストする](testing.html)を参照してください。

Railsにはminitestと呼ばれるテストフレームワークが付属しています。Railsを安定させるには、テストをひととおり書きましょう。`test:`名前空間で定義されているタスクは、さまざまなテストを書いて実行するときに役立ちます（皆さんがテストを書いてくれますように！）。

### `bin/rails tmp`

`Rails.root/tmp`ディレクトリには一時ファイルが保存されます（*nix系でいう`/tmp`ディレクトリと同様です）。一時ファイルには、プロセスIDのファイル、アクションキャッシュのファイルなどがあります。

`tmp:`名前空間には、`Rails.root/tmp`ディレクトリを作成・削除する以下のタスクがあります。

* `bin/rails tmp:cache:clear`: `tmp/cache/`以下を削除します。
* `bin/rails tmp:sockets:clear`: `tmp/sockets/`以下を削除します。
* `bin/rails tmp:screenshots:clear`: `tmp/screenshots/`以下を削除します。
* `bin/rails tmp:clear`: キャッシュ、ソケット、スクリーンショットをすべて削除します。
* `bin/rails tmp:create`: キャッシュ、ソケット、スクリーンショットを置くための`tmp/`ディレクトリを作成します。

### その他のタスク

* `bin/rails initializers`: Railsで呼び出されるすべてのイニシャライザを、実際の呼び出し順で表示します。
* `bin/rails middleware`: アプリで有効になっているRackミドルウェアスタックのリストを表示します。
* `bin/rails stats`: コード量とテスト量の比率やKLOCs（1000を単位とするコード行数）などのコードに関する統計値を表示します。
* `bin/rails secret`: セッションのsecretに用いる擬似乱数を生成します。
* `bin/rails time:zones:all`: Railsが扱えるすべてのタイムゾーンを表示します。
* `bin/rails boot`: アプリケーションを起動し、その後終了します。

### カスタムRakeタスク

独自のRakeタスクの拡張子は`.rake`で、
`Rails.root/lib/tasks`配下に保存します。また、独自のタスクを作成できる
`bin/rails generate task`というコマンドもあります。

```ruby
desc "手短でクールなタスクの概要"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # マジックをここに書く
  # 有効なRubyコードなら何でも書ける
end
```

タスクには以下のように引数を渡します。

```ruby
task :task_name, [:arg_1] => [:prerequisite_1, :prerequisite_2] do |task, args|
  argument_1 = args.arg_1
end
```

タスクを名前空間内で定義することで、タスクをグルーピングできます。

```ruby
namespace :db do
  desc "何もしないタスク"
  task :nothing do
    # 本当に何もしない
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

アプリケーションモデルの操作やデータベースクエリの実行などが必要なタスクは、以下のようにアプリケーションコードを読み込む`environment`タスクに依存する必要があります。

```ruby
task task_that_requires_app_code: [:environment] do
  User.create!
end
```
