
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
* `rake`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

どのコマンドも```-h もしくは --help```オプションを使用することで、詳細な情報をみることができます。

簡単なRailsアプリケーションをつくりながら、一つずつコマンドを実行していきましょう。

### `rails new`

Railsをインストールしたあと、最初にやりたいことは`rails new`コマンドを実行して、新しいRailsアプリケーションを作成することです。

INFO: まだRailsをインストールしていない場合、`gem install rails`を実行してRailsをインストールできます。

```bash
$ rails new commandsapp
    create
    create README.rdoc
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

`rails server`コマンドを実行すると、WEBrickという小規模のwebサーバーが起動します(WEBrickはRubyに標準添付されています)。Webブラウザからアプリケーションにアクセスしたいときは、このコマンドを使用します。

`rails server`を実行することで、新しいRailsアプリケーションを作成後すぐにRailsアプリケーションを起動することができます。

```bash
$ cd commandsapp
$ bin/rails server
=> Booting WEBrick
=> Rails 4.2.0 application starting in development on http://0.0.0.0:3000
=> Call with -d to detach
=> Ctrl-C to shutdown server
[2013-08-07 02:00:01] INFO  WEBrick 1.3.1
[2013-08-07 02:00:01] INFO  ruby 2.0.0 (2013-06-27) [x86_64-darwin11.2.0]
[2013-08-07 02:00:01] INFO  WEBrick::HTTPServer#start: pid=69680 port=3000
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
     create      app/assets/javascripts/greetings.js.coffee
     invoke    scss
     create      app/assets/stylesheets/greetings.css.scss
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
=> Booting WEBrick...
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

NOTE: 利用可能なフィールドタイプ(field types)については[API documentation](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html#method-i-column)に記載されている、`TableDefinition`のcolumnメソッドの説明を参照してください。

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
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.js.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.css.scss
    invoke    scss
   identical    app/assets/stylesheets/scaffolds.css.scss
```

ジェネレータはモデル、コントローラ、ヘルパー、レイアウト、機能テスト、ユニットテスト、スタイルシート用のディレクトリが存在することをチェックし、ビュー、コントローラ、モデル、マイグレーション(`high_scores`テーブルとフィールドを作成する)を生成し、この**resource**のためのルーティングを用意します。またこれらのためのテストも作成します。

**migrate**を実行してマイグレーションを走らせる必要があります。つまりデータベースのスキーマを変更するためにRubyのコード(コードとは`20130717151933_create_high_scores.rb`に書かれたコードのことです)を実行する必要があります。データベースとはどのデータベースでしょうか？`rake db:migrate`コマンドを実行すると、RailsはSQLite3に新しいデータベースを作ります。Rakeについては後ほど詳しく説明します。

```bash
$ bin/rake db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: 単体テストについて説明します。単体テストとは、コードをテストし、アサーションを行うコードです。ユニットテストでは、モデルのメソッドといったコードの一部分を取り出して、その引数と戻り値をテストします。単体テストはあなたの友人です。単体テストを書くことで幸せな人生が送れるということに、早く気がついたほうがいいでしょう。本当です。すぐにでも気がつけるはずです。

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
$ bin/rails console staging
```

データを変更することなくコードをテストしたいときは、`rails console --sandbox`を実行します。

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 4.2.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

#### appオブジェクトとhelperオブジェクト

`rails console`の実行中、`app`オブジェクトと`helper`オブジェクトにアクセスできます。

`app`メソッドを使用すると、URLヘルパーとpathヘルパーにアクセスできます。またrequest投げることもできます。

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

`rails dbconsole`コマンドは使用しているデータベースを探し出し、適切なデータベースコマンドラインツールを起動します(また、コマンドラインツールに必要な引数を探し出します)。MySQL、PostgreSQL、SQLite、そしてSQLite3をサポートしています。

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

Rake
----

RakeはRuby版のMakeです。Unixの 'make' に代わるような独立したRubyのユーティリティで、'Rakefile'と`.rake`ファイルでタスクを定義・管理します。 Railsでは、管理系のタスクはRakeタスクで書かれています。Railsのタスクは洗練されていて、タスク同士が協調して動くようになっています。

`rake --tasks`とタイプすると、実行可能なRakeタスクの一覧が表示されます。カレントディレクトリによって、表示される内容が変化します。各タスクには説明がついているので、必要なタスクを見つけるのに役立つはずです。

```--trace```を使うことで、タスクを実行する際のバックトレースをすべて表示することができます (訳注: バックトレースには、依存するタスクの呼び出しと実行順序が表示されます)。
例えば ```rake db:create --trace``` のようにしてタスクを実行します。

```bash
$ bin/rake --tasks
rake about              # List versions of all Rails frameworks and the environment
rake assets:clean       # Remove old compiled assets
rake assets:clobber     # Remove compiled assets
rake assets:precompile  # Compile all the assets named in config.assets.precompile
rake db:create          # Create the database from config/database.yml for the current Rails.env
...
rake log:clear          # Truncates all *.log files in log/ to zero bytes (specify which logs with LOGS=test,development)
rake middleware         # Prints out your Rack middleware stack
...
rake tmp:clear          # Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)
rake tmp:create         # Creates tmp directories for sessions, cache, sockets, and pids
```
INFO: ```rake -T```でもタスクの一覧を表示することができます。

### `about`

`rake about`を実行すると、Ruby、RubyGems、Rails、Railsのサブコンポーネント (訳注: Active RecordやAction Packなど) のバージョン、Railsアプリケーションのフォルダー名、現在のRailsの環境名とデータベースアダプター、そして、スキーマのバージョンが表示されます。誰かに質問をしたいときや、セキュリティパッチが自分のアプリケーションに影響するか確認したいときなど、現在使用しているRailsに関する情報が必要なときに役立ちます。

```bash
$ bin/rake about
About your application's environment
Ruby version              1.9.3 (x86_64-linux)
RubyGems version          1.3.6
Rack version              1.3
Rails version             4.2.0
JavaScript Runtime        Node.js (V8)
Active Record version     4.2.0
Action Pack version       4.2.0
Action View version       4.2.0
Action Mailer version     4.2.0
Active Support version    4.2.0
Middleware                Rack::Sendfile, ActionDispatch::Static, Rack::Lock, #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007ffd131a7c88>, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, Rails::Rack::Logger, ActionDispatch::ShowExceptions, ActionDispatch::DebugExceptions, ActionDispatch::RemoteIp, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::QueryCache, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ParamsParser, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20110805173523
```

### `assets`

`rake assets:precompile`を実行すると、`app/assets`配下のファイルをプレコンパイルすることができます。また`rake assets:clean`を実行すると、古くなったコンパイル済みのファイルを削除できます。`assets:clean`は、新しいassetsのビルドをしながらも古いassetsへのリンクを残す「ローリングデプロイ (rolling deploy)」というやり方を実現しています。

`public/assets`配下を完全に消去するには`rake assets:clobber`を実行します。

### `db`

Rakeの`db:`という名前空間に属するタスクのうち、最もよく使われるのは`migrate`と`create`です。マイグレーションに関するタスク(`up`, `down`, `redo`, `reset`)はいずれも一度試してみることをおすすめします。`rake db:version`を使えばデータベースの状況が分かるので、トラブルシューティングの際に役立ちます。

マイグレーションについては、[Migrations](active_record_migrations.html)でより詳しく扱っています。

### `doc`

`doc:`という名前空間にはアプリケーションやAPI、Railsガイドのドキュメントをつくるためのタスクが入っています。ドキュメントを別で管理することができるので、コードベースの肥大化を防ぐことができます (まるで組込み系の開発をしているかのようです)。

* `rake doc:app`で、`doc/app`配下に開発しているアプリケーションのドキュメントを作成します。
* `rake doc:guides`で、`doc/guides`配下にRailsガイドを作成します。
* `rake doc:rails`で、`doc/api`配下にRailsのAPIドキュメントを作成します。

### `notes`

`rake notes`は、コードのコメントからFIXME、OPTIMIZE、TODOで始まる行を探し出して表示します (訳注: [FIXME]のように[から始まるものはヒットしません)。検索対象となるファイルの拡張子は`.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js`、`.erb`で、デフォルトのアノテーション以外に独自のアノテーションも使用できます。

```bash
$ bin/rake notes
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

特定のアノテーションのみを表示したいとき(例えばFIXMEのみを表示したいとき)は`rake notes:fixme`のように実行します。このとき、アノテーションは小文字で書くことに注意してください。

```bash
$ bin/rake notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

独自のアノテーションを使う際には、`rake notes:custom`と書いて、`ANNOTATION`環境変数を使ってアノテーション名を指定します。

```bash
$ bin/rake notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/article.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE. 特定のアノテーションのみを表示するときや、独自のアノテーションを表示する際には、FIXMEやBUGといったアノテーション名は表示されません。

`rake notes`タスクはデフォルトでは`app`、`config`、`lib`、`bin`、`test`ディレクトリを対象とします。他のディレクトリも対象にしたい場合は、`SOURCE_ANNOTATION_DIRECTORIES`環境変数にディレクトリ名をカンマ区切りで与えてください。

```bash
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ bin/rake notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

### `routes`

`rake routes`を使うと、定義されている全ルーティングをみることができます。これはルーティングの問題を解くときや、アプリケーションのルーティング全体を理解するのに役立ちます。

### `test`

INFO: Railsでの単体テストについては[Railsアプリケーションをテストする](testing.html)を参照してください。

RailsにはMinitestと呼ばれるテストスイートが付属しています。Railsではテストを書くことで、安定したアプリケーションを開発します。`test:`という名前空間の中で定義されたタスクは、あなたがこれから(期待を持って)書く様々なテストを実行するときに役立ちます。

### `tmp`

`Rails.root/tmp`ディレクトリは、(*nix系でいう/tmpディレクトリのような) 一時ファイルを保存するためのディレクトリです。一時ファイルには、(ファイルを利用してセッションの管理を行っている場合) セッションのためのファイルやプロセスIDのファイル、アクションキャッシュのためのファイルなどがあります (訳注: 最近のRailsではセッションをファイルで管理することは稀です)。

`tmp:`という名前空間には、`Rails.root/tmp`ディレクトリを作成、削除するためのタスクが入っています。

* `rake tmp:cache:clear`で、`tmp/cache`を空にします。
* `rake tmp:sessions:clear`で、`tmp/sessions`を空にします。
* `rake tmp:sockets:clear`で、`tmp/sockets`を空にします。
* `rake tmp:clear`で、cache、sessions、socketsディレクトリを空にします。
* `rake tmp:create`で、sessions、cache、sockets、pidsのtmpディレクトリを作成します。

### その他のタスク

* `rake stats`で、コードに対するテストの比率やKLOCs(コードの行数)といった、コードに関する統計値を表示します。
* `rake secret`で、セッションシークレット用に擬似乱数を生成します。
* `rake time:zones:all`で、Railsが扱える全タイムゾーンを表示します。

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
task :task_name, [:arg_1] => [:pre_1, :pre_2] do |t, args|
  # You can use args from here
end 
```

名前空間内でタスクを定義することで、タスクをグルーピングできます。

  ```ruby
namespace :db do 
  desc "This task does nothing"
  task :nothing do
    # Seriously, nothing
  end 
end 
```

そして、以下のようにしてタスクを呼び出します。

```bash
$ bin/rake task_name
$ bin/rake "task_name[value 1]" # entire argument string should be quoted
$ bin/rake db:nothing
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
      create README.rdoc
      add 'README.rdoc'
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
# PostgreSQL. Versions 8.2 and up are supported.
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
development:
  adapter: postgresql
  encoding: unicode
  database: gitapp_development
  pool: 5
  username: gitapp
  password:
...
...
```

選択したデータベース(PostgreSQL)に対応するように、Railsはdatabase.ymlを作成します。

NOTE. ソースコード管理システムに関するオプションを使う際には、まずアプリケーション用のディレクトリを作り、ソースコード管理システムの初期化を行ってから、`rails new`コマンドを実行する点に注意してください。