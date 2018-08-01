
Rails のコマンドラインツール
======================

このガイドの内容:

* Railsアプリケーションを作成する方法
* モデル、コントローラ、データベースのマイグレーションファイル、および単体テストを作成する方法
* 開発用サーバーを起動する方法
* インタラクティブシェルを利用して、オブジェクトを実験する方法

--------------------------------------------------------------------------------

NOTE: このチュートリアルは、[Railsをはじめよう](getting_started.html)を読んで、基本的なRailsの知識があることを前提としています。

コマンドラインの基礎
-------------------

Railsを使用する際に、きわめて重要なコマンドがいくつかあります。それらを使用頻度順に並べると以下のとおりです。

* `rails console`
* `rails server`
* `bin/rails`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

どのコマンドも`-h` もしくは `--help`オプションを使用することで、詳細な情報をみることができます。

簡単なRailsアプリケーションをつくりながら、一つずつコマンドを実行していきましょう。

### `rails new`

Railsをインストールしたあと、最初にやりたいことは`rails new`コマンドを実行して、新しいRailsアプリケーションを作成することです。

INFO: まだRailsをインストールしていない場合、`gem install rails`を実行してRailsをインストールできます。

```bash
$ rails new commandsapp
    create
    create README.md
    create Rakefile
    create config.ru
    create .gitignore
    create Gemfile
    create app
    ...
    create  tmp/cache
    ...
        run bundle install
```

このような短いコマンドをうつだけで、Railsは非常に多くのものを用意してくれます。たったこれだけで、完璧なRailsのディレクトリ構成と、アプリケーションに必要なコードがすべて手に入りました。

### `rails server`

`rails server`コマンドを実行すると、Pumaというwebサーバーが起動します(PumaはRailsに標準添付されています)。Webブラウザからアプリケーションにアクセスしたいときは、このコマンドを使用します。

`rails server`を実行することで、新しいRailsアプリケーションを作成後すぐにRailsアプリケーションを起動することができます。

```bash
$ cd commandsapp
$ bin/rails server
=> Booting Puma
=> Rails 5.1.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
Puma starting in single mode...
* Version 3.0.2 (ruby 2.3.0-p0), codename: Plethora of Penguin Pinatas
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

ちょうど3つのコマンドで、Railsサーバーを3000番ポートで起動しました。ブラウザを立ち上げて、[http://localhost:3000](http://localhost:3000)を開いてみてください。Railsアプリケーションが動作していることが分かります。

INFO: サーバーを起動する際には`rails s`のように"s"というエイリアスが使用できます。

`-p` オプションを使用することで、待ち受けるポートを指定できます。サーバーの環境は `-e` オプションで変更することができ、デフォルトではdevelopment (開発) 環境で実行されます。

```bash
$ bin/rails server -e production -p 4000
```

`-b`オプションを使用するとRailsを特定のIPにバインドできます。デフォルトでは0.0.0.0です。`-d`オプションを使用することで、デーモンとしてサーバーを起動することができます。

### `rails generate`

`rails generate`コマンドでは、テンプレートを使用して様々なものを作成します。`rails generate`を実行すると、利用可能なジェネレータの一覧が表示されます。

INFO: ジェネレータコマンドを実行する際には`rails g`のように"g"というエイリアスが使用できます。

```bash
$ bin/rails generate
Usage: rails generate GENERATOR [args] [options]

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

NOTE: ジェネレータgemをインストールしたり、プラグインに付属しているジェネレータをインストールすることで、ジェネレータを増やせます。また、自分でジェネレータを開発することもできます。

ジェネレータを使用すると、アプリケーションを動かすのに必要な [**Boilerplate Code**](http://en.wikipedia.org/wiki/Boilerplate_code) (訳注: 多くの箇所で使われている、ほとんどor全く変更がないコード) を書かなくて済むため、時間を節約できます。

それではコントローラジェネレータを使って、コントローラを作ってみましょう。どのようなコマンドを使用すればよいのでしょうか？ジェネレータに聞いてみましょう。

INFO: Railsのすべてのコマンドにはヘルプがついています。多くの *nix (訳注: LinuxやUnix、UnixライクなOSなど) のユーティリティと同じようにコマンドの最後に`--help`もしくは`-h`オプションを与えてください (例: `rails server --help`)。

```bash
$ bin/rails generate controller
Usage: rails generate controller NAME [action action] [options]

    ...
    ...

    Description:
    ...

    To create a controller within a module, specify the controller name as a path like 'parent_module/controller_name'.

    ...

Example:
    `rails generate controller CreditCards open debit credit close`

    Credit card controller with URLs like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb
```

コントローラジェネレータには`generate controller ControllerName action1 action2`という形式でパラメータを渡します。**hello**アクションを実行すると、すてきなメッセージを返してくれる`Greetings`コントローラを作ってみましょう。

```bash
$ bin/rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get "greetings/hello"
     invoke    erb 
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke  assets
     invoke    coffee
     create      app/assets/javascripts/greetings.coffee
     invoke    scss
     create      app/assets/stylesheets/greetings.scss
```

どのようなものが作成されたのでしょう？いくつかのディレクトリがアプリケーションに存在することを確認し、コントローラファイル、ビューファイル、機能テストのファイル、ビューのヘルパー、JavaScriptファイルそしてスタイルシートファイルを作成しました。

コントローラ(`app/controllers/greetings_controller.rb`)を確認し、少し編集してみましょう。

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "Hello, how are you today?"
  end 
end 
```

メッセージを表示するためにビュー(`app/views/greetings/hello.html.erb`)を編集します。

```erb
<h1>A Greeting for You!</h1>
<p><%= @message %></p>
```

`rails server`でサーバーを起動します。

```bash
$ bin/rails server
=> Booting Puma...
```

URLは[http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)です。

INFO: 通常のRailsアプリケーションでは、URLはhttp://(host)/(controller)/(action)というパターンになります。またhttp://(host)/(controller)というパターンのURLはコントローラの**index**アクションへのURLとなります。

Railsにはデータモデルのためのジェネレータもついています。

```bash
$ bin/rails generate model
Usage:
  rails generate model NAME [field[:type][:index] field[:type][:index]] [options]

...

Active Record options:
      [--migration]            # Indicates when to generate migration
                               # Default: true

...

Description:
    Create rails files for model generator.
```

NOTE: `type`パラメータで利用可能なフィールドの種類については[API documentation](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column)に記載されている、`SchemaStatements`モジュールの`add_column`メソッドの説明を参照してください。`index`パラメータを指定すると、カラムに対応するインデックスが生成されます。

ここでは直接モデルを作成する代わりに(モデルの作成は後ほど行います)、scaffoldを生成しましょう。Railsにおいて**scaffold**とは、モデル、モデルのためのマイグレーション、モデルを操作するためのコントローラ、モデルを操作・表示するためのビュー、それらのためのテスト一式のことをさします。

"HighScore"という名のリソースを準備してみましょう。このリソースの役割はビデオゲームでの最高得点を記録することです。

```bash
$ bin/rails generate scaffold HighScore game:string score:integer
    invoke  active_record
    create    db/migrate/20130717151933_create_high_scores.rb
    create    app/models/high_score.rb
    invoke  test_unit
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
    invoke  test_unit
    create      test/controllers/high_scores_controller_test.rb
    invoke  helper
    create      app/helpers/high_scores_helper.rb
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    invoke    test_unit
    create      test/system/high_scores_test.rb
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.scss
    invoke    scss
   identical    app/assets/stylesheets/scaffolds.scss
```

ジェネレータはモデル、コントローラ、ヘルパー、レイアウト、機能テスト、ユニットテスト、スタイルシート用のディレクトリが存在することをチェックし、ビュー、コントローラ、モデル、マイグレーション(`high_scores`テーブルとフィールドを作成する)を生成し、この**resource**のためのルーティングを用意します。またこれらのためのテストも作成します。

**migrate**を実行してマイグレーションを走らせる必要があります。つまりデータベースのスキーマを変更するためにRubyのコード(コードとは`20130717151933_create_high_scores.rb`に書かれたコードのことです)を実行する必要があります。データベースとはどのデータベースでしょうか？`bin/rails db:migrate`コマンドを実行すると、RailsはSQLite3に新しいデータベースを作ります。bin/railsについては後ほど詳しく説明します。

```bash
$ bin/rails db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: 単体テストについて説明します。単体テストとは、コードをテストし、アサーションを行うコードです。ユニットテストでは、モデルのメソッドといったコードの一部分を取り出して、入力と出力をテストします。単体テストはあなたの友人も同然です。単体テストを書くことで幸せな人生が送れることに気づくのが早ければ早いほど、確実によい結果を得られます。このことは間違いありません。単体テストについて詳しくは、[the testing guide](https://railsguides.jp/testing.html)を参照してください。


Railsが作ったインターフェースをみてみましょう。

```bash
$ bin/rails server
```

ブラウザで[http://localhost:3000/high_scores](http://localhost:3000/high_scores)を開いてみましょう。新しいハイスコアを作ることができます(スペースインベーダーで55,160点とかね!) (訳注: 2003年にDonald Hayesがたたき出したスコアです)。

### `rails console`

`console`コマンドを使うと、コマンドラインでRailsアプリケーションとやり取りすることができます。`rails console`は内部的にIRBを使用しているので、IRBを使ったことがあれば、扱うのは簡単です。ひらめいたアイデアを試してみたり、ウェブサイトにアクセスすることなくサーバのデータを変更するのに役立ちます。

INFO: コンソールコマンドを実行する際には`rails c`のように"c"というエイリアスが使用できます。

`console`コマンドを実行する環境を指定することができます。

```bash
$ bin/rails console -e staging
```

データを変更することなくコードをテストしたいときは、`rails console --sandbox`を実行します。

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 5.1.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

#### appオブジェクトとhelperオブジェクト

`rails console`の実行中、`app`オブジェクトと`helper`オブジェクトにアクセスできます。

`app`メソッドを使用すると、URLヘルパーとpathヘルパーにアクセスできます。またリクエストを投げることもできます。

```bash
>> app.root_path
=> "/"

>> app.get _
Started GET "/" for 127.0.0.1 at 2014-06-19 10:41:57 -0300
...
```

`helper`メソッドを使用すると、Railsのアプリケーションヘルパーと自分が実装したヘルパーにアクセスすることができます。

```bash
>> helper.time_ago_in_words 30.days.ago
=> "about 1 month"

>> helper.my_custom_helper
=> "my custom helper"
```

### `rails dbconsole`

`rails dbconsole`コマンドは使用しているデータベースを探し出し、適切なデータベースコマンドラインツールを起動します(また、コマンドラインツールに必要な引数を探し出します)。MySQL (MariaDB含む)、PostgreSQL、SQLite、そしてSQLite3をサポートしています。

INFO: DBコンソールコマンドを実行する際には`rails db`のように"db"というエイリアスが使用できます。

### `rails runner`

`runner`コマンドを使うと、非対話的にRailsの文脈でRubyのコードを実行することができます。たとえば次のようになります。

```bash
$ bin/rails runner "Model.long_running_method"
```

INFO: ランナーコマンドを実行する際には`rails r`のように"r"というエイリアスが使用できます。

`-e`を使用することで`runner`コマンドを実行する環境を指定することができます。

```bash
$ bin/rails runner -e staging "Model.long_running_method"
```

ファイル内のRubyコードを`runner`で実行することもできます。

```bash
$ bin/rails runner lib/code_to_be_run.rb
```

### `rails destroy`

`destroy`は`generate`の反対と言えます。ジェネレータコマンドが何をしたか把握し、それを取り消します。

INFO: `rails d`のように、"d"というエイリアスを使ってdestroyコマンドを実行することもできます。

```bash
$ bin/rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke  test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```

```bash
$ bin/rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke  test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

bin/rails
---------

`rake`コマンドは、Rails 5.0以降Railsの実行ファイルに組み込まれました。コマンドを実行する新しいデフォルトは`bin/rails`です。


`bin/rails --tasks`とタイプすると、実行可能な`rails`コマンドの一覧が表示されます。各タスクには説明がついているので、必要なタスクを見つけるのに役立つはずです。

```bash
$ bin/rails --help
Usage: rails COMMAND [ARGS]

The most common rails commands are:
generate    Generate new code (short-cut alias: "g")
console     Start the Rails console (short-cut alias: "c")
server      Start the Rails server (short-cut alias: "s")
...

All commands can be run with -h (or --help) for more information.

In addition to those commands, there are:
about                               List versions of all Rails ...
assets:clean[keep]                  Remove old compiled assets
assets:clobber                      Remove compiled assets
assets:environment                  Load asset compile environment
assets:precompile                   Compile all the assets ...
...
db:fixtures:load                    Loads fixtures into the ...
db:migrate                          Migrate the database ...
db:migrate:status                   Display status of migrations
db:rollback                         Rolls the schema back to ...
db:schema:cache:clear               Clears a db/schema_cache.yml file
db:schema:cache:dump                Creates a db/schema_cache.yml file
db:schema:dump                      Creates a db/schema.rb file ...
db:schema:load                      Loads a schema.rb file ...
db:seed                             Loads the seed data ...
db:structure:dump                   Dumps the database structure ...
db:structure:load                   Recreates the databases ...
db:version                          Retrieves the current schema ...
...
restart                             Restart app by touching ...
tmp:create                          Creates tmp directories ...
```
INFO: `bin/rails -T`でもタスクの一覧を表示することができます。

### `about`

`bin/rails about`を実行すると、Ruby、RubyGems、Rails、Railsのサブコンポーネント (訳注: Active RecordやAction Packなど) のバージョン、Railsアプリケーションのフォルダー名、現在のRailsの環境名とデータベースアダプター、そして、スキーマのバージョンが表示されます。誰かに質問をしたいときや、セキュリティパッチが自分のアプリケーションに影響するか確認したいときなど、現在使用しているRailsに関する情報が必要なときに役立ちます。

```bash
$ bin/rails about
About your application's environment
Rails version             5.1.0
Ruby version              2.2.2 (x86_64-linux)
RubyGems version          2.4.6
Rack version              2.0.1
JavaScript Runtime        Node.js (V8)
Middleware:               Rack::Sendfile, ActionDispatch::Static, ActionDispatch::Executor, ActiveSupport::Cache::Strategy::LocalCache::Middleware, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, ActionDispatch::RemoteIp, Sprockets::Rails::QuietAssets, Rails::Rack::Logger, ActionDispatch::ShowExceptions, WebConsole::Middleware, ActionDispatch::DebugExceptions, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20110805173523
```

### `assets`

`bin/rails assets:precompile`を実行すると、`app/assets`配下のファイルをプレコンパイルすることができます。また`bin/rails assets:clean`を実行すると、古くなったコンパイル済みのファイルを削除できます。`assets:clean`は、新しいassetsのビルドをしながらも古いassetsへのリンクを残す「ローリングデプロイ (rolling deploy)」というやり方を実現しています。

`public/assets`配下を完全に消去するには`bin/rails assets:clobber`を実行します。

### `db`

bin/railsの`db:`という名前空間に属するタスクのうち、最もよく使われるのは`migrate`と`create`です。マイグレーションに関するタスク(`up`, `down`, `redo`, `reset`)はいずれも一度試してみることをおすすめします。`bin/rails db:version`を使えばデータベースの状況が分かるので、トラブルシューティングの際に役立ちます。

マイグレーションについては、[Active Recordマイグレーション](active_record_migrations.html)でより詳しく扱っています。

### `notes`

`bin/rails notes`は、コードのコメントからFIXME、OPTIMIZE、TODOで始まる行を探し出して表示します (訳注: [FIXME]のように[から始まるものはヒットしません)。検索対象となるファイルの拡張子は`.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js`、`.erb`で、デフォルトのアノテーション以外に独自のアノテーションも使用できます。

```bash
$ bin/rails notes
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/models/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

検索するファイルの拡張子を追加するには、`config.annotations.register_extensions`オプションを使います。このオプションは拡張子の一覧と、マッチするべき行 を表す正規表現を引数にとります。

```ruby
config.annotations.register_extensions("scss", "sass", "less") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

特定のアノテーションのみを表示したいとき(例えばFIXMEのみを表示したいとき)は`bin/rails notes:fixme`のように実行します。このとき、アノテーションは小文字で書くことに注意してください。

```bash
$ bin/rails notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

独自のアノテーションを使う際には、`bin/rails notes:custom`と書いて、`ANNOTATION`環境変数を使ってアノテーション名を指定します。

```bash
$ bin/rails notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/article.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE: 特定のアノテーションのみを表示するときや、独自のアノテーションを表示する際には、FIXMEやBUGといったアノテーション名は表示されません。

`rails notes`タスクはデフォルトでは`app`、`config`、`lib`、`bin`、`test`ディレクトリを対象とします。他のディレクトリも対象にしたい場合は、`SOURCE_ANNOTATION_DIRECTORIES`環境変数にディレクトリ名をカンマ区切りで指定します。

```ruby
config.annotations.register_directories("spec", "vendor")
```

`SOURCE_ANNOTATION_DIRECTORIES`環境変数でカンマ区切りのディレクトリ名を指定することもできます。

```bash
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ bin/rails notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

### `routes`

`rails routes`を使うと、定義されている全ルーティングをみることができます。これはルーティングの問題を解くときや、アプリケーションのルーティング全体を理解するのに役立ちます。

### `test`

INFO: Railsでの単体テストについては[Railsアプリケーションをテストする](testing.html)を参照してください。

RailsにはMinitestと呼ばれるテストスイートが付属しています。Railsではテストを書くことで、安定したアプリケーションを開発します。`test:`という名前空間の中で定義されたタスクは、あなたがこれから(期待を持って)書く様々なテストを実行するときに役立ちます。

### `tmp`

`Rails.root/tmp`ディレクトリは、(*nix系でいう`/tmp`ディレクトリのような) 一時ファイルを保存するためのディレクトリです。一時ファイルには、プロセスIDのファイル、アクションキャッシュのためのファイルなどがあります。

`tmp:`という名前空間には、`Rails.root/tmp`ディレクトリを作成、削除するためのタスクが入っています。

* `rails tmp:cache:clear`で、`tmp/cache`を空にします。
* `rails tmp:sockets:clear`で、`tmp/sockets`を空にします。
* `rails tmp:screenshots:clear`で、`tmp/screenshots`を空にします。
* `rails tmp:clear`で、cache、sockets、screenshotディレクトリを空にします。
* `rails tmp:create`で、cache、sockets、pidsのtmpディレクトリを作成します。

### その他のタスク

* `rails stats`で、コードに対するテストの比率やKLOCs(コードの行数)といった、コードに関する統計値を表示します。
* `rails secret`で、セッションシークレット用に擬似乱数を生成します。
* `rails time:zones:all`で、Railsが扱える全タイムゾーンを表示します。

### カスタムRakeタスク

独自のRakeタスクの拡張子は`.rake`で
`Rails.root/lib/tasks`配下に保存します。また、独自のタスクを作成することができる
`bin/rails generate task`というコマンドもあります。

```ruby
desc "I am short, but comprehensive description for my cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # All your magic here
  # Any valid Ruby code is allowed
end 
```

タスクに引数を渡すには以下のようにします。

```ruby
task :task_name, [:arg_1] => [:prerequisite_1, :prerequisite_2] do |task, args|
  argument_1 = args.arg_1
end
```

名前空間内でタスクを定義することで、タスクをグルーピングできます。

```ruby
namespace :db do 
  desc "何もしないたすく"
  task :nothing do
    # マジ何もしない
  end 
end 
```

そして、以下のようにしてタスクを呼び出します。

```bash
$ bin/rails task_name
$ bin/rails "task_name[value 1]" # entire argument string should be quoted
$ bin/rails db:nothing
```

NOTE: アプリケーション内のモデルを使用したり、データベースに対してクエリを投げたりしたいときは、タスクから`environment`タスクへの依存関係を定義する必要があります。`environment`タスクはアプリケーションのコードを読み込むタスクです。

Railsの高度なコマンドライン
-------------------------------

コマンドラインのより高度な使い方として、便利な(時に驚くような)オプションを見つけて、オプションを使いこなすことがあります。ここでは、Railsのもつ妙技を少しだけ紹介します。

### データベースとソースコード管理システムとRails

新しいRailsアプリケーションを作成するときに、データベースの種類とソースコード管理システムの種類を指定することができます。このオプションを使うことで、ちょっとした時間と多くのタイピングを節約できます。

それでは`--database = postgresql`オプションと`--git`オプションの動きを見てみましょう。

```bash
$ mkdir gitapp
$ cd gitapp
$ git init 
Initialized empty Git repository in .git/
$ rails new . --git --database=postgresql
      exists
      create  app/controllers
      create  app/helpers
      ...
      ...
      create  tmp/cache
      create  tmp/pids
      create Rakefile
      add 'Rakefile'
      create README.md
      add 'README.md'
      create app/controllers/application_controller.rb
      add 'app/controllers/application_controller.rb'
      create app/helpers/application_helper.rb
      ...
      create  log/test.log
      add 'log/test.log'
```

Railsがgitのリポジトリ内にファイルを作成する前に、**gitapp**ディレクトリを作成し、空のgitリポジトリを初期化する必要があります。Railsがどのようなデータベースの設定ファイルを作ったか見てみましょう。

```bash
$ cat config/database.yml
# PostgreSQL. Versions 9.1 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On OS X with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On OS X with MacPorts:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: gitapp_development
...
...
```

選択したデータベース(PostgreSQL)に対応するように、Railsは`database.yml`を作成します。

NOTE: ソースコード管理システムに関するオプションを使う際には、まずアプリケーション用のディレクトリを作り、ソースコード管理システムの初期化を行ってから、`rails new`コマンドを実行する点に注意してください。
