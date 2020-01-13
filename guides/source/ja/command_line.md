**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Rails のコマンドラインツール
======================

このガイドの内容:

* Railsアプリケーションを作成する方法
* モデル、コントローラ、データベースのマイグレーションファイル、および単体テストを作成する方法
* 開発用サーバーを起動する方法
* インタラクティブシェルを利用して、オブジェクトを実験する方法

--------------------------------------------------------------------------------

NOTE: このチュートリアルは、[Railsをはじめよう](getting_started.html)で基本的なRailsの知識を身につけていることを前提としています。

コマンドラインの基礎
-------------------

Railsを利用するうえで、きわめて重要なコマンドがいくつかあります。それらを利用頻度順に並べると以下のとおりです。

* `rails console`
* `rails server`
* `rails test`
* `rails generate`
* `rails db:migrate`
* `rails db:create`
* `rails routes`
* `rails dbconsole`
* `rails new app_name`

利用可能なrailsコマンドのリストは、`rails --help`で表示できます。利用できるコマンドはカレントディレクトリによって変わることがよくあります。各コマンドの説明で必要なものを探せるでしょう。

```bash
$ rails --help
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

このような短いコマンドを入力するだけで、Railsは非常に多くのものを用意してくれます。たったこれだけで、完璧なRailsのディレクトリ構成と、アプリケーションに必要なコードがすべて手に入ります。

### `rails server`

`rails server`コマンドを実行すると、Pumaというwebサーバーが起動します(PumaはRailsに標準添付されています)。Webブラウザからアプリケーションにアクセスしたいときは、このコマンドを使います。

`rails server`を実行することで、新しいRailsアプリケーションを作成後すぐにRailsアプリケーションを起動することができます。

```bash
$ cd commandsapp
$ rails server
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

わずか3つのコマンドで、Railsサーバーを3000番ポートで起動しました。ブラウザを立ち上げて、[http://localhost:3000](http://localhost:3000)を開いてみてください。Railsアプリケーションが動作していることが分かります。

INFO: サーバーを起動する際には`rails s`のように"s"というエイリアスが使えます。

`-p` オプションを使うことで、待ち受けるポートを指定できます。サーバーの環境は `-e` オプションで変更することができ、デフォルトではdevelopment (開発) 環境で実行されます。

```bash
$ rails server -e production -p 4000
```

`-b`オプションを使うと、Railsを特定のIPにバインドできます。デフォルトはlocalhostです。`-d`オプションを使うと、デーモンとしてサーバーを起動することができます。

### `rails generate`

`rails generate`コマンドでは、テンプレートを用いてさまざまなものを作成します。`rails generate`を実行すると、利用可能なジェネレータの一覧が表示されます。

INFO: ジェネレータコマンドを実行する際には`rails g`のように「g」というエイリアスが使えます。

```bash
$ rails generate
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

NOTE: ジェネレータgemをインストールしたり、プラグインに付属しているジェネレータをインストールすることで、ジェネレータを追加できます。自分でジェネレータを開発することもできます。

ジェネレータを使うと、アプリケーションを動かすのに必要な [**Boilerplate Code**](http://en.wikipedia.org/wiki/Boilerplate_code) (訳注: 多くの箇所で繰り返し使われる定形コード: 俗に「テンプレ」とも呼ばれます) を書かなくて済むため、時間を節約できます。

それではコントローラジェネレータを使って、コントローラを作ってみましょう。どのようなコマンドを使えばよいのでしょうか？ジェネレータに聞いてみましょう。

INFO: Railsのすべてのコマンドにはヘルプがついています。多くの *nix (訳注: LinuxやUnix、UnixライクなOSなど) のユーティリティと同じようにコマンドの最後に`--help`もしくは`-h`オプションを与えてください (例: `rails server --help`)。

```bash
$ rails generate controller
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

コントローラジェネレータには`generate controller ControllerName action1 action2`という形式でパラメータを渡します。**hello**アクションを実行すると、ちょっとしたメッセージを表示する`Greetings`コントローラを作ってみましょう。

```bash
$ rails generate controller Greetings hello
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
     invoke  assets
     invoke    scss
     create      app/assets/stylesheets/greetings.scss
```

どんなファイルが生成されたのでしょうか？いくつかのディレクトリがアプリケーションに存在することを確認し、コントローラファイル、ビューファイル、機能テストのファイル、ビューのヘルパー、JavaScriptファイルそしてスタイルシートファイルを作成しました。

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
$ rails server
=> Booting Puma...
```

URLは[http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)です。

INFO: 通常のRailsアプリケーションでは、URLは`http://ホスト名/コントローラ名/アクション名`というパターンになります。アクション名を指定しない`http://ホスト名/コントローラ名`というパターンのURLは、コントローラの**index**アクションへのURLとなります。

Railsにはデータモデルのためのジェネレータもついています。

```bash
$ rails generate model
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

ここでは直接モデルを作成する代わりに(モデルの作成は後ほど行います)、scaffoldをセットアップしましょう。Railsにおける**scaffold**とは、モデル、モデルのためのマイグレーション、モデルを操作するためのコントローラ、モデルを操作・表示するためのビュー、それらのためのテスト一式をさします。

"HighScore"という名のリソースを準備してみましょう。このリソースの役割はビデオゲームでの最高得点を記録することです。

```bash
$ rails generate scaffold HighScore game:string score:integer
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
    invoke  assets
    invoke    scss
    create      app/assets/stylesheets/high_scores.scss
    invoke  scss
    create    app/assets/stylesheets/scaffolds.scss
```

ジェネレータはモデル、コントローラ、ヘルパー、レイアウト、機能テスト、ユニットテスト、スタイルシート用のディレクトリが存在することをチェックし、ビュー、コントローラ、モデル、マイグレーション(`high_scores`テーブルとフィールドを作成する)を生成し、この**resource**用のルーティングを用意します。またこれらのためのテストも作成します。

**migrate**を実行してマイグレーションを走らせる必要があります。つまりデータベースのスキーマを変更するためにRubyのコード(コードとは`20130717151933_create_high_scores.rb`に書かれたコードのことです)を実行する必要があります。データベースとはどのデータベースでしょうか？`rails db:migrate`コマンドを実行すると、RailsはSQLite3に新しいデータベースを作ります。bin/railsについては後ほど詳しく説明します。

```bash
$ rails db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: 単体テスト（unit test）について説明します。単体テストとは、コードをテストしてアサーション（コードが期待どおりに動作するかどうかを確認すること）を行うコードです。単体テストでは、モデルのメソッドといったコードの一部分を取り出して、入力と出力をテストします。単体テストはあなたにとって友人と同じぐらい大事なものです。単体テストを書けば人生が幸福で満たされるという事実に早いうちから気づいた人は、間違いなく他人より先に幸せになれるでしょう。単体テストについて詳しくは、[the testing guide](https://railsguides.jp/testing.html)を参照してください。


Railsが作ったインターフェースをみてみましょう。

```bash
$ rails server
```

ブラウザで[http://localhost:3000/high_scores](http://localhost:3000/high_scores)を開いてみましょう。それではハイスコアを更新するとしましょう(スペースインベーダーで55,160点とかね!) (訳注: 2003年にDonald Hayesがたたき出したスコアです)。

### `rails console`

`console`コマンドを使うと、コマンドラインでRailsアプリケーションとやり取りすることができます。`rails console`は内部的にIRBを使っているので、IRBを使ったことがあれば簡単に扱えます。IRBは、思いついたアイデアを試してみたり、ウェブサイトにアクセスすることなくサーバのデータを変更したりするのに役立ちます。

INFO: コンソールコマンドを実行する際には`rails c`のように"c"というエイリアスが使えます。

`console`コマンドを実行する環境を指定することができます。

```bash
$ rails console -e staging
```

データを変更することなくコードをテストしたいときは、`rails console --sandbox`を実行します。

```bash
$ rails console --sandbox
Loading development environment in sandbox (Rails 5.1.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

#### appオブジェクトとhelperオブジェクト

`rails console`の実行中、`app`オブジェクトと`helper`オブジェクトにアクセスできます。

`app`メソッドを使うと、名前付きルーティングヘルパーにアクセスできます。リクエストを投げることもできます。

```bash
>> app.root_path
=> "/"

>> app.get _
Started GET "/" for 127.0.0.1 at 2014-06-19 10:41:57 -0300
...
```

`helper`メソッドを使うと、Railsのアプリケーションヘルパーと自分が実装したヘルパーにアクセスすることができます。

```bash
>> helper.time_ago_in_words 30.days.ago
=> "about 1 month"

>> helper.my_custom_helper
=> "my custom helper"
```

### `rails dbconsole`

`rails dbconsole`コマンドは使っているデータベースを探し出し、適切なデータベースコマンドラインツールを起動します(また、コマンドラインツールに必要な引数を探し出します)。MySQL (MariaDB含む)、PostgreSQL、SQLite、そしてSQLite3をサポートしています。

INFO: DBコンソールコマンドを実行する際には`rails db`のように「db」というエイリアスが使えます。

### `rails runner`

`runner`コマンドを使うと、非対話的にRailsの文脈でRubyのコードを実行することができます。たとえば次のようになります。

```bash
$ rails runner "Model.long_running_method"
```

INFO: ランナーコマンドを実行する際には`rails r`のように"r"というエイリアスが使えます。

`-e`を使うことで`runner`コマンドを実行する環境を指定することができます。

```bash
$ rails runner -e staging "Model.long_running_method"
```

ファイル内のRubyコードを`runner`で実行することもできます。

```bash
$ rails runner lib/code_to_be_run.rb
```

### `rails destroy`

`destroy`は`generate`のちょうど反対と言えます。ジェネレータコマンドで生成された内容を調べて、それを取り消します。

INFO: `rails d`のように、「d」というエイリアスを使ってdestroyコマンドを実行することもできます。

```bash
$ rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke  test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```

```bash
$ rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke  test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

### `rails about`

`rails about`を実行すると、Ruby、RubyGems、Rails、Railsのサブコンポーネント (訳注: Active RecordやAction Packなど) のバージョン、Railsアプリケーションのフォルダー名、現在のRailsの環境名とデータベースアダプター、そして、スキーマのバージョンが表示されます。誰かに質問したいときや、セキュリティパッチが自分のアプリケーションに影響するか確認したいときなど、現在使っているRailsに関する情報が必要なときに便利です。

```bash
$ rails about
About your application's environment
Rails version             6.0.0
Ruby version              2.5.0 (x86_64-linux)
RubyGems version          2.7.3
Rack version              2.0.4
JavaScript Runtime        Node.js (V8)
Middleware:               Rack::Sendfile, ActionDispatch::Static, ActionDispatch::Executor, ActiveSupport::Cache::Strategy::LocalCache::Middleware, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, ActionDispatch::RemoteIp, Sprockets::Rails::QuietAssets, Rails::Rack::Logger, ActionDispatch::ShowExceptions, WebConsole::Middleware, ActionDispatch::DebugExceptions, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20180205173523
```

### `rails assets`

`rails assets:precompile`を実行すると、`app/assets`配下のファイルをプリコンパイルできます。また`rails assets:clean`を実行すると、古くなったコンパイル済みのファイルを削除できます。`assets:clean`は、新しいassetsがビルドされるときにも古いassetsにリンクする「ローリングデプロイ (rolling deploy)」を実現しています。

`public/assets`配下を完全に消去するには`rails assets:clobber`を実行します。

### `rails db`

bin/railsの`db:`という名前空間に属するタスクのうち、最もよく使われるのは`migrate`と`create`です。マイグレーションに関するタスク(`up`, `down`, `redo`, `reset`)はいずれも一度試してみることをおすすめします。`rails db:version`を使えばデータベースの状況が分かるので、トラブルシューティングの際に役立ちます。

マイグレーションについては、[Active Recordマイグレーション](active_record_migrations.html)でより詳しく扱っています。

### `rails notes`

`rails notes`は、特定のキーワードで始まる行を探し出して表示します。利用法については`rails notes --help`で参照できます。

デフォルトでは、探索対象ディレクトリが`app`、`config`、`db`、`lib`、`test`で、FIXME、OPTIMIZE、TODOというアノテーションのあるファイルを検索します。デフォルトで探索対象となるファイルの拡張子は`.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js`、`.erb`です。

```bash
$ rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

#### アノテーション

`--annotations`引数を用いて、特定のアノテーションを渡せます。デフォルトでは、FIXME、OPTIMIZE、TODOを検索します。アノテーションは大文字小文字を区別する点にご注意ください。

```bash
$ rails notes --annotations FIXME RELEASE
app/controllers/admin/users_controller.rb:
  * [101] [RELEASE] We need to look at this before next release
  * [132] [FIXME] high priority for next deploy

lib/school.rb:
  * [ 17] [FIXME]
```

#### タグ

`config.annotations.register_tags`を用いて、デフォルトタグを追加できます。このオプションにはタグのリストを渡せます。

```ruby
config.annotations.register_tags("DEPRECATEME", "TESTME")
```

```bash
$ rails notes
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] do A/B testing on this
  * [ 42] [TESTME] this needs more functional tests
  * [132] [DEPRECATEME] ensure this method is deprecated in next release
```

#### ディレクトリ

`config.annotations.register_directories`を用いて、デフォルトディレクトリを追加できます。このオプションにはディレクトリ名のリストを渡せます。

```ruby
config.annotations.register_directories("spec", "vendor")
```

```bash
$ rails notes
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

`config.annotations.register_extensions`を用いて、デフォルトファイル拡張子を追加できます。このオプションにはファイル拡張子のリストと、対応する正規表現を渡せます。

```ruby
config.annotations.register_extensions("scss", "sass") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

```bash
$ rails notes
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

### `rails routes`

`rails routes`を使うと、定義されている全ルーティングをみることができます。これはルーティングの問題を解くときや、アプリケーションのルーティング全体を理解するのに役立ちます。

### `rails test`

INFO: Railsでの単体テストについては[Railsアプリケーションをテストする](testing.html)を参照してください。

RailsにはMinitestと呼ばれるテストスイートが付属しています。Railsではテストを書くことで、安定したアプリケーションを開発します。`test:`という名前空間の中で定義されたタスクは、あなたがこれから(期待を持って)書くさまざまなテストを実行するときに役立ちます。

### `rails tmp`

`Rails.root/tmp`ディレクトリは、(*nix系でいう`/tmp`ディレクトリのような) 一時ファイルを保存するためのディレクトリです。一時ファイルには、プロセスIDのファイル、アクションキャッシュのためのファイルなどがあります。

`tmp:`という名前空間には、`Rails.root/tmp`ディレクトリを作成、削除するためのタスクが入っています。

* `rails tmp:cache:clear`で、`tmp/cache`を空にします。
* `rails tmp:sockets:clear`で、`tmp/sockets`を空にします。
* `rails tmp:screenshots:clear`で、`tmp/screenshots`を空にします。
* `rails tmp:clear`で、cache、sockets、screenshotディレクトリを空にします。
* `rails tmp:create`で、cache、sockets、pidsのtmpディレクトリを作成します。

### その他のタスク

* `rails stats`: コードに対するテストの比率やKLOCs(コードの行数)といった、コードに関する統計値を表示します。
* `rails secret`: セッションシークレット用に擬似乱数を生成します。
* `rails time:zones:all`: Railsが扱える全タイムゾーンを表示します。

### カスタムRakeタスク

独自のRakeタスクの拡張子は`.rake`で
`Rails.root/lib/tasks`配下に保存します。また、独自のタスクを作成することができる
`rails generate task`というコマンドもあります。

```ruby
desc "I am short, but comprehensive description for my cool task"
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
  desc "何もしないたすく"
  task :nothing do
    # マジ何もしない
  end
end
```

タスクの呼び出しは以下のように行います。

```bash
$ rails task_name
$ rails "task_name[value 1]" # entire argument string should be quoted
$ rails db:nothing
```

NOTE: アプリケーション内のモデルを使ったり、データベースに対してクエリを投げたりしたいときは、タスクから`environment`タスクへの依存関係を定義する必要があります。`environment`タスクはアプリケーションのコードを読み込むタスクです。

Railsの高度なコマンドライン
-------------------------------

コマンドラインのより高度な使い方として、便利な(時に驚くような)オプションを見つけて、オプションを使いこなすことがあります。ここでは、Railsのもつ妙技を少しだけ紹介します。

### データベースとソースコード管理システムとRails

新しいRailsアプリケーションを作成するときに、データベースの種類とソースコード管理システムの種類を指定することができます。このオプションを使うことで、ちょっとした時間と多くのタイピングを節約できます。

それでは`--database=postgresql`オプションと`--git`オプションの動きを見てみましょう。

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
      create  Rakefile
add 'Rakefile'
      create  README.md
add 'README.md'
      create  app/controllers/application_controller.rb
add 'app/controllers/application_controller.rb'
      create  app/helpers/application_helper.rb
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
# On macOS with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On macOS with MacPorts:
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
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: gitapp_development
...
...
```

選択したデータベース(PostgreSQL)に対応するように、Railsは`database.yml`を作成します。

NOTE: ソースコード管理システムに関するオプションを使う際には、まずアプリケーション用のディレクトリを作り、ソースコード管理システムの初期化を行ってから、`rails new`コマンドを実行するようご注意ください。
