Rails アプリケーションのデバッグ
============================

本ガイドでは、Ruby on Rails アプリケーションのさまざまなデバッグ技法をご紹介します。

このガイドの内容:

* デバッグの目的
* テストで特定できない問題がアプリケーションで発生したときの追跡方法
* さまざまなデバッグ方法
* スタックトレースの解析方法

--------------------------------------------------------------------------------

デバッグに利用できるビューヘルパー
--------------------------

変数にどんな値が入っているかを確認する作業は何かと必要になります。Railsでは以下の3つのメソッドを利用できます。

* `debug`
* `to_yaml`
* `inspect`

### `debug`

`debug`ヘルパーは`<pre>`タグを返します。このタグの中にYAML形式でオブジェクトが出力されます。これにより、あらゆるオブジェクトを人間が読めるデータに変換できます。たとえば、以下のコードがビューにあるとします。

```html+erb
<%= debug @article %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

ここから以下のような出力を得られます。

```yaml
--- !ruby/object Article
attributes:
  updated_at: 2008-09-05 22:55:47
  body: It's a very helpful guide for debugging your Rails app.
  title: Rails debugging guide
  published: t
  id: "1"
  created_at: 2008-09-05 22:55:47
attributes_cache: {}


Title: Rails debugging guide
```

### `to_yaml`

他の方法として、任意のオブジェクトに対して`to_yaml`を呼び出すことでYAMLに変換できます。変換したこのオブジェクトは、`simple_format`ヘルパーメソッドに渡して出力を整形できます。これは`debug`のマジックです。

インスタンス変数や、その他のあらゆるオブジェクトやメソッドをYAML形式で表示します。以下のような感じで使います。

```html+erb
<%= simple_format @article.to_yaml %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

これにより、以下のような結果がビューに表示されます。

```yaml
--- !ruby/object Article
attributes:
updated_at: 2008-09-05 22:55:47
body: It's a very helpful guide for debugging your Rails app.
title: Rails debugging guide
published: t
id: "1"
created_at: 2008-09-05 22:55:47
attributes_cache: {}

Title: Rails debugging guide
```

### `inspect`

オブジェクトの値を表示するのに便利なメソッドとして`inspect`も利用できます。特に、配列やハッシュを扱うときに便利です。このメソッドはオブジェクトの値を文字列として出力します。以下に例を示します。

```html+erb
<%= [1, 2, 3, 4, 5].inspect %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

上のコードから以下の出力を得られます。

```
[1, 2, 3, 4, 5]

Title: Rails debugging guide
```

ロガー
----------

実行時に情報をログに保存できるとさらに便利です。Railsは実行環境ごとに異なるログファイルを出力するようになっています。

### ロガーについて

Railsは`ActiveSupport::Logger`クラスを利用してログ情報を出力します。必要に応じて、`Log4r`など別のロガーに差し替えることもできます。

別のロガーの指定は、`config/application.rb`または環境ごとの設定ファイルで行います。

```ruby
config.logger = Logger.new(STDOUT)
config.logger = Log4r::Logger.new("Application Log")
```

あるいは、`Initializer`セクションに以下の**いずれか**を追加します。

```ruby
Rails.logger = Logger.new(STDOUT)
Rails.logger = Log4r::Logger.new("Application Log")
```

TIP: ログの保存場所は、デフォルトでは`Rails.root/log/`になります。ログのファイル名は、アプリケーションが実行されるときの環境 (development/test/productionなど) が使われます。

### ログの出力レベル

ログに出力されるメッセージのログレベルが、設定済みのログレベル以上になった場合に、対応するログファイルにそのメッセージが出力されます。現在のログレベルを知りたい場合は、`Rails.logger.level`メソッドを呼び出します。

指定可能なログレベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`の6つであり、それぞれ0から5までの数字に対応します。デフォルトのログレベルを変更するには以下のようにします。

```ruby
config.log_level = :warn # 環境ごとのイニシャライザで利用可能
Rails.logger.level = 0 # いつでも利用可能
```

これは、development環境やstaging環境ではログを出力し、production環境では不要な情報をログに出力したくない場合などに便利です。

TIP: Railsのデフォルトログレベルは全環境で`debug`です。

### メッセージ送信

コントローラ、モデル、メーラーから現在のログに書き込みたい場合は、`logger.(debug|info|warn|error|fatal)`を使います。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
logger.info "Processing the request..."
logger.fatal "Terminating application, raised unrecoverable error!!!"
```

例として、ログに別の情報を追加する機能を装備したメソッドを以下に示します。

```ruby
  class ArticlesController < ApplicationController
  # ...

  def create
    @article = Article.new(article_params)
    logger.debug "新しい記事: #{@article.attributes.inspect}"
    logger.debug "記事が正しいかどうか: #{@article.valid?}"

    if @article.save
      flash[:notice] =  'Article was successfully created.'
      logger.debug "記事は正常に保存され、ユーザーをリダイレクト中..."
      redirect_to @article, notice: '記事は正常に作成されました。'
    else
      render :new
    end
  end

  # ...
  
  private
    def article_params
      params.require(:article).permit(:title, :body, :published)
    end
end
```

上のコントローラのアクションを実行すると、以下のようなログが生成されます。

``` 
Started POST "/articles" for 127.0.0.1 at 2017-08-20 20:53:10 +0900
Processing by ArticlesController#create as HTML
  Parameters: {"utf8"=>"✓", "authenticity_token"=>"xhuIbSBFytHCE1agHgvrlKnSVIOGD6jltW2tO+P6a/ACjQ3igjpV4OdbsZjIhC98QizWH9YdKokrqxBCJrtoqQ==", "article"=>{"title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!", "published"=>"0"}, "commit"=>"Create Article"}
New article: {"id"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!", "published"=>false, "created_at"=>nil, "updated_at"=>nil}
記事が正しいかどうか: true
   (0.1ms)  BEGIN
 SQL (0.4ms)  INSERT INTO "articles" ("title", "body", "published", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5) RETURNING "id"  [["title", "Debugging Rails"], ["body", "I'm learning how to print in logs!!!"], ["published", "f"], ["created_at", "2017-08-20 11:53:10.010435"], ["updated_at", "2017-08-20 11:53:10.010435"]]
   (0.3ms)  COMMIT
記事は正常に保存され、ユーザーをリダイレクト中...
Redirected to http://localhost:3000/articles/1
Completed 302 Found in 4ms (ActiveRecord: 0.8ms)
```

このようにログに独自の情報を追加すると、予想外の異常な動作をログで見つけやすくなります。ログに独自の情報を追加する場合は、productionログが意味のない大量のメッセージでうずまることのないよう、適切なログレベルを使うようにしてください。

### タグ付きログの出力

ユーザーとアカウントを多数使うアプリケーションを実行するときに、何らかのカスタムルールを設定してログをフィルタできると便利です。Active Supportの`TaggedLogging`を使えば、サブドメインやリクエストIDなどを指定してログを絞り込むことができ、このようなアプリケーションのデバッグがはかどります。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # Logs "[BCX] [Jason] Stuff"
```

### ログがパフォーマンスに与える影響

ログ出力がRailsアプリケーションのパフォーマンスに与える影響は常にわずかです。ログをディスクに保存する場合は特にそうです。さらに、場合によってはそうとは言い切れないことがあります。

ログレベル`:debug`は、`:fatal`と比べてはるかに多くの文字列が評価および(ディスクなどに)出力されるため、パフォーマンスに与える影響がずっと大きくなります。

他にも、以下のように`Logger`の呼び出しを多数実行した場合には落とし穴に注意する必要があります。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

上の例では、たとえログ出力レベルをdebugにしなかった場合でもパフォーマンスが低下します。その理由は、上のコードでは文字列を評価する必要があり、その際に比較的動作が重い`String`オブジェクトのインスタンス化と、実行に時間のかかる変数の式展開 (interpolation) が行われているからです。
したがって、ロガーメソッドに渡すものはブロックの形にしておくことをお勧めします。ブロックとして渡しておけば、ブロックの評価は出力レベルが設定レベル以上になった場合にしか行われない (遅延読み込みなど) ためです。これに従って上のコードを書き直すと以下のようになります。

```ruby
logger.debug {"Person attributes hash: #{@person.attributes.inspect}"}
```

渡したブロックの内容 (ここでは文字列の式展開) は、debug が有効になっている場合にしか評価されません。この方法によるパフォーマンスの改善は、大量のログを出力しているときでないとそれほど実感できないかもしれませんが、それでも採用する価値があります。

`byebug` gemでデバッグする
---------------------------------

コードが期待どおりに動作しない場合は、ログやコンソールに出力して問題を診断することができます。ただし、この方法ではエラー追跡を何度も繰り返さねばならず、根本的な原因を突き止めるには能率がよいとは言えません。
実行中のコードに探りを入れる必要があるのであれば、最も頼りになるのはやはりデバッガーです。

デバッガーは、Railsのソースコードを追うときに、そのコードをどこで開始するのかがを知りたいときにも有用です。アプリケーションへのリクエストをすべてデバッグし、自分が書いたコードからRailsのもっと深いところへダイブする方法を本ガイドから学びましょう。

### セットアップ

`byebug` gemを使うと、Railsコードにブレークポイントを設定してステップ実行できます。次を実行するだけでインストールできます。

```bash
$ gem install byebug
```

後はRailsアプリケーション内で`byebug`メソッドを呼び出せばいつでもデバッガーを起動できます。

以下に例を示します。

```ruby
class PeopleController < ApplicationController
  def new
    byebug
    @person = Person.new
  end
end
``` 

### シェル

アプリケーションで`byebug`を呼び出すと、アプリケーションサーバーを実行しているターミナルウィンドウ内のデバッガーシェルで即座にデバッガーが起動し、`(byebug)`というプロンプトが表示されます。
実行しようとしている行の前後のコードがプロンプトの前に表示され、'=>'で現在の行が示されます。以下に例を示します。

``` 
[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

ブラウザからのリクエストによってデバッグ行に到達した場合、リクエストしたブラウザのタブ上の処理は、デバッガが終了してリクエストの処理が完全に終了するまで中断します。

以下に例を示します。

```bash
=> Booting Puma
=> Rails 5.1.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
Puma starting in single mode...
* Version 3.4.0 (ruby 2.3.1-p112), codename: Owl Bowl Brawl
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
Started GET "/" for 127.0.0.1 at 2014-04-11 13:11:48 +0200
  ActiveRecord::SchemaMigration Load (0.2ms)  SELECT "schema_migrations".* FROM "schema_migrations"
Processing by ArticlesController#index as HTML

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

それではアプリケーションをもっと詳しく見てみましょう。まずはデバッガーのヘルプを表示してみるのがよいでしょう。`help`と入力します。

``` 
(byebug) help
  break      -- Sets breakpoints in the source code
  catch      -- Handles exception catchpoints
  condition  -- Sets conditions on breakpoints
  continue   -- Runs until program ends, hits a breakpoint or reaches a line
  debug      -- Spawns a subdebugger
  delete     -- Deletes breakpoints
  disable    -- Disables breakpoints or displays
  display    -- Evaluates expressions every time the debugger stops
  down       -- Moves to a lower frame in the stack trace
  edit       -- Edits source files
  enable     -- Enables breakpoints or displays
  finish     -- Runs the program until frame returns
  frame      -- Moves to a frame in the call stack
  help       -- Helps you using byebug
  history    -- Shows byebug's history of commands
  info       -- Shows several informations about the program being debugged
  interrupt  -- Interrupts the program
  irb        -- Starts an IRB session
  kill       -- Sends a signal to the current process
  list       -- Lists lines of source code
  method     -- Shows methods of an object, class or module
  next       -- Runs one or more lines of code
  pry        -- Starts a Pry session
  quit       -- Exits byebug
  restart    -- Restarts the debugged program
  save       -- Saves current byebug session to a file
  set        -- Modifies byebug settings
  show       -- Shows byebug settings
  source     -- Restores a previously saved byebug session
  step       -- Steps into blocks or methods one or more times
  thread     -- Commands to manipulate threads
  tracevar   -- Enables tracing of a global variable
  undisplay  -- Stops displaying all or some expressions when program stops
  untracevar -- Stops tracing a global variable
  up         -- Moves to a higher frame in the stack trace
  var        -- Shows variables and its values
  where      -- Displays the backtrace

(byebug)
```

前の10行を表示するには、`list-` (または `l-`) と入力します。

```
(byebug) l-

[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
   1  class ArticlesController < ApplicationController
   2    before_action :set_article, only: [:show, :edit, :update, :destroy]
   3
   4    # GET /articles
   5    # GET /articles.json
   6    def index
   7      byebug
   8      @articles = Article.find_recent
   9
   10     respond_to do |format|
```

上に示したように、該当のファイルに移動して、`byebug`呼び出しを追加した行の前を表示できます。最後に、`list=`と入力して現在の位置を再び表示してみましょう。

```
(byebug) list=

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }
(byebug)
```

### コンテキスト

アプリケーションのデバッグ中は、通常と異なる「コンテキスト」に置かれます。具体的には、スタックの別の部分を通って進むコンテキストです。

デバッガーは、停止位置やイベントに到達するときに「コンテキスト」を作成します。作成されたコンテキストには、中断しているプログラムに関する情報が含まれており、デバッガーはこの情報を用いて、フレームスタックの検査やデバッグ中のプログラムにおける変数の評価を行い、デバッグ中のプログラムが停止している位置の情報を認識します。

`backtrace`コマンド (またはそのエイリアスである`where`コマンド) を使えば、いつでもアプリケーションのバックトレースを出力できます。これは、コードのその位置に至るまでの経過を知るうえで非常に便利です。コードのある行にたどりついたとき、その経緯を知りたければ`backtrace`でわかります。

```
(byebug) where
--> #0  ArticlesController.index
      at /PathToProject/app/controllers/articles_controller.rb:8
    #1  ActionController::BasicImplicitRender.send_action(method#String, *args#Array)
      at /PathToGems/actionpack-5.1.0/lib/action_controller/metal/basic_implicit_render.rb:4
    #2  AbstractController::Base.process_action(action#NilClass, *args#Array)
      at /PathToGems/actionpack-5.1.0/lib/abstract_controller/base.rb:181
    #3  ActionController::Rendering.process_action(action, *args)
      at /PathToGems/actionpack-5.1.0/lib/action_controller/metal/rendering.rb:30
...
```

現在のフレームは`-->`で示されます。`frame n`コマンド (**n**はフレーム番号) を使えば、トレース内のどのコンテキストにも自由に移動できます。このコマンドを実行すると、`byebug`は新しいコンテキストを表示します。

```
(byebug) frame 2

[176, 185] in /PathToGems/actionpack-5.1.0/lib/abstract_controller/base.rb
   176:       # is the intended way to override action dispatching.
   177:       #
   178:       # Notice that the first argument is the method to be dispatched
   179:       # which is *not* necessarily the same as the action name.
   180:       def process_action(method_name, *args)
=> 181:         send_action(method_name, *args)
   182:       end
   183:
   184:       # Actually call the method associated with the action. Override
   185:       # this method if you wish to change how action methods are called,
(byebug)
```

コードを1行ずつ実行していた場合、利用できる変数は同一です。つまり、これこそがデバッグという作業です。

`up [n]` (短縮形の`u`も可) コマンドや`down [n]`コマンドを使って、スタックを **n**フレーム上または下に移動し、コンテキストを切り替えることもできます。upはスタックフレーム番号の大きい方に進み、downは小さい方に進みます。

### スレッド

デバッガーで`thread`(短縮形は`th`) コマンドを使うと、スレッド実行中にスレッドのリスト表示/停止/再開/切り替えを行えます。このコマンドには以下のささやかなオプションがあります。

* `thread`は現在のスレッドを表示します。
* `thread list`はすべてのスレッドのリストをステータス付きで表示します。現在実行中のスレッドは「+」記号と数字で示されます。
* `thread stop n`はスレッド**n_を停止します。
* `thread resume n`はスレッド**n**を再開します。
* `thread switch n`は現在のスレッドコンテキストを**n**に切り替えます。

このコマンドは、同時実行（コンカレント）スレッドのデバッグ中に、コードで競合状態が発生していないかどうかの確認が必要な場合にも非常に便利です。

### 変数の検査

すべての式は、現在のコンテキストで評価されます。式を評価するには、単にその式を入力します。

次の例では、現在のコンテキスト内で定義されたインスタンス変数を出力する方法を示しています。

```
[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug) instance_variables
[:@_action_has_layout, :@_routes, :@_request, :@_response, :@_lookup_context,
 :@_action_name, :@_response_body, :@marked_for_same_origin_verification,
 :@_config]
```

見ての通り、コントローラからアクセスできるすべての変数が表示されています。表示される変数リストは、コードの実行に伴って動的に更新されます。
たとえば、`next`コマンドで次の行に進んだとします (このコマンドの詳細については後述します)。

```
(byebug) next

[5, 14] in /PathTo/project/app/controllers/articles_controller.rb
   5     # GET /articles.json
   6     def index
   7       byebug
   8       @articles = Article.find_recent
   9
=> 10      respond_to do |format|
   11        format.html # index.html.erb
   12        format.json { render json: @articles }
   13      end
   14    end
   15
(byebug)
```

それではinstance_variablesをもう一度調べてみましょう。

```
(byebug) instance_variables
[:@_action_has_layout, :@_routes, :@_request, :@_response, :@_lookup_context,
 :@_action_name, :@_response_body, :@marked_for_same_origin_verification,
 :@_config, :@articles]
```

定義行が実行されたことによって、今度は`@articles`もインスタンス変数に表示されます。

TIP: `irb`コマンドを使うことで、**irb**モードで実行できます。
これにより、呼び出し中のコンテキスト内でirbセッションが開始されます。

変数と値のリストを表示するのに便利なのは何と言っても`var`メソッドでしょう。
`byebug`でこのメソッドを使ってみましょう。

```
(byebug) help var

  [v]ar <subcommand>
 
  Shows variables and its values


  var all      -- Shows local, global and instance variables of self.
  var args     -- Information about arguments of the current scope
  var const    -- Shows constants of an object.
  var global   -- Shows global variables.
  var instance -- Shows instance variables of self or a specific object.
  var local    -- Shows local variables in current scope.
```

このメソッドは、現在のコンテキストでの変数の値を検査するのにうってつけの方法です。たとえば、現時点でローカル変数が何も定義されていないことを確認してみましょう。

```
(byebug) var local
(byebug)
```

以下の方法でオブジェクトのメソッドを検査することもできます。

```
(byebug) var instance Article.new
@_start_transaction_state = {}
@aggregation_cache = {}
@association_cache = {}
@attributes = #<ActiveRecord::AttributeSet:0x007fd0682a9b18 @attributes={"id"=>#<ActiveRecord::Attribute::FromDatabase:0x007fd0682a9a00 @name="id", @value_be...
@destroyed = false
@destroyed_by_association = nil
@marked_for_destruction = false
@new_record = true
@readonly = false
@transaction_state = nil
```

`display`コマンドを使って変数をウォッチすることもできます。これは、デバッガーで実行を進めながら変数の値の移り変わりを追跡するのに大変便利です。

```
(byebug) display @articles
1: @articles = nil
```

スタック内で移動するたびに、そのときの変数と値のリストが出力されます。変数の表示を止めるには、`undisplay n`(_n_ は変数番号) を実行します。上の例では変数番号は 1 になっています。

### ステップ実行

これで、トレース実行中に現在の実行位置を確認し、利用可能な変数をいつでも確認できるようになりました。アプリケーションの実行について引き続き学んでみましょう。

`step`コマンド (短縮形は`s`) を使うと、プログラムの実行を継続し、次の論理的な停止行まで進んだらデバッガーに制御を返します。`next`は`step`と似ていますが、`step`がコードを1ステップだけ実行して次の行で停止するのに対し、`next`は次の行に進む際にメソッド内の呼び出し先に移動しない点が異なります。

たとえば、次のような状況を考えてみましょう

```
Started GET "/" for 127.0.0.1 at 2014-04-11 13:39:23 +0200
Processing by ArticlesController#index as HTML

[1, 6] in /PathToProject/app/models/article.rb
   1: class Article < ApplicationRecord
   2:   def self.find_recent(limit = 10)
   3:     byebug
=> 4:     where('created_at > ?', 1.week.ago).limit(limit)
   5:   end
   6: end

(byebug)
```

`next`を使うと、メソッドの呼び出し先は表示されません。byebugはその代わりに、単に同じコンテキストの次の行に進みます。この例の場合、次の行とは現在のメソッドの最終行になります。つまり、`byebug`は呼び出し元メソッドの次の行に戻ります。

```
(byebug) next
[4, 13] in /PathToProject/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug)
```

同じ状況で`step`を使うと、`byebug`は文字通り「Rubyコードの、次に実行すべき行」に進みます。ここではActive Supportの`week`メソッドにジャンプして進むことになります。

```
(byebug) step

[49, 58] in /PathToGems/activesupport-5.1.0/lib/active_support/core_ext/numeric/time.rb
   49:
   50:   # Returns a Duration instance matching the number of weeks provided.
   51:   #
   52:   #   2.weeks # => 14 days
   53:   def weeks
=> 54:     ActiveSupport::Duration.weeks(self)
   55:   end
   56:   alias :week :weeks
   57:
   58:   # Returns a Duration instance matching the number of fortnights provided.
(byebug)
```

これは自分のコードのバグを見つけ出す方法として非常に優れています。

TIP: `n`ステップ進めたい場合は、`step n`や`next n`でステップ数を指定できます。

### ブレークポイント

ブレークポイントとは、アプリケーションの実行がプログラムの特定の場所に達した時に停止する位置を指します。そしてその場所でデバッガーシェルが起動します。

`break` (または`b`) コマンドを使ってブレークポイントを動的に追加できます。
手動でブレークポイントを追加する方法は次の3とおりです。

* `break n`: 現在のソースファイルの**n**行目に示された行にブレークポイントを設定します。
* `break ファイル名:n [if 式]`: **ファイル名**の**n**行目にブレークポイントを設定します。**式**を指定すると、この式が**true**と評価された場合にのみデバッガが起動します。
* `break class(.|\#)method [if 式]`: **class**に定義されている**method**にブレークポイントを設定します (「.」と「\#」はそれぞれクラスとインスタンスメソッドを指す)。**式**の動作は`ファイル名:n`の場合と同じです。


さっきと同じ状況を例に説明します。

```
[4, 13] in /PathToProject/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug) break 11
Successfully created breakpoint with id 1

```

ブレークポイントをリスト表示するには、`info breakpoints`を使います。番号を指定すると、その番号のブレークポイントをリスト表示します。番号を指定しない場合は、すべてのブレークポイントをリスト表示します。

```
(byebug) info breakpoints
Num Enb What
1   y   at /PathToProject/app/controllers/articles_controller.rb:11
```

`delete n`コマンドを使うと**n**番のブレークポイントを削除できます。番号を指定しない場合、現在有効なブレークポイントをすべて削除します。

```
(byebug) delete 1
(byebug) info breakpoints
No breakpoints.
```

ブレークポイントを有効にしたり、無効にしたりすることもできます。

* `enable ブレークポイント [n [m [...]]]`: 指定したブレークポイントのリスト (無指定の場合はすべてのブレークポイント) でのプログラムの停止を有効にします。ブレークポイントを作成するとデフォルトでこの状態になります。
* `disable breakpoints [n [m [...]]]`: 指定した（指定しない場合はすべての）ブレークポイントのリストで停止しなくなります。

### 例外のキャッチ

`catch exception-name` (省略形は `cat exception-name`) を使うと、例外を受けるハンドラが他にないと考えられる場合に、**exception-name**で例外の種類を指定してインターセプトできます。

例外のキャッチポイントをすべてリスト表示するには単に`catch`と入力します。

### 実行再開

デバッガーで停止したアプリケーションの再開方法は2種類あります。

* `continue [n]`: スクリプトが直前に停止していたアドレスからプログラムの実行を再開します。このとき、そのアドレスに設定されていたブレークポイントはすべて無視されます。オプションとして、特定の行番号`n`をワンタイムブレークポイントとして指定できます。このブレークポイントは、ワンタイムブレークポイントに達すると削除されます。
* `finish [n]`: 指定のスタックフレームが返るまで実行を続けます。フレーム番号が指定されていない場合は、現在選択しているフレームが返るまで実行を続けます。現在選択しているフレームは直近のフレームから開始され、フレーム位置の指定操作(upやdownやフレーム番号指定など)が行われていない場合は0から開始されます。フレーム番号を指定すると、そのフレームが返るまで実行を続けます。

### 編集

デバッガー上のコードをエディタで開くためのコマンドは2種類あります。

* `edit [file:n]`: ファイル名**file**をエディタで開きます。エディタはEDITOR環境変数で指定します。n行で行数を指定することもできます。

### 終了

デバッガーを終了するには、`quit`コマンド (短縮形は `q`) を使います。`q!`と入力すると、「Really quit? (y/n)」というプロンプトをスキップして無条件に終了します。

単にquitを実行すると、事実上すべてのスレッドを終了しようとします。これによりサーバーが停止するので、サーバーを再起動する必要があります。

### 設定

`byebug`の振る舞いを変更するためのオプションがいくつかあります。

```
(byebug) help set

  set <setting> <value>

  Modifies byebug settings

  Boolean values take "on", "off", "true", "false", "1" or "0". If you
  don't specify a value, the boolean setting will be enabled. Conversely,
  you can use "set no<setting>" to disable them.

  You can see these environment settings with the "show" command.
  List of supported settings:

  autosave       -- Automatically save command history record on exit
  autolist       -- Invoke list command on every stop
  width          -- Number of characters per line in byebug's output
  autoirb        -- Invoke IRB on every stop
  basename       -- <file>:<line> information after every stop uses short paths
  linetrace      -- Enable line execution tracing
  autopry        -- Invoke Pry on every stop
  stack_on_error -- Display stack trace when `eval` raises an exception
  fullpath       -- Display full file names in backtraces
  histfile       -- File where cmd history is saved to. Default: ./.byebug_history
  listsize       -- Set number of source lines to list by default
  post_mortem    -- Enable/disable post-mortem mode
  callstyle      -- Set how you want method call parameters to be displayed
  histsize       -- Maximum number of commands that can be stored in byebug history
  savefile       -- File where settings are saved to. Default: ~/.byebug_save
```

TIP: これらの設定は、ホームディレクトリの`.byebugrc`ファイルに保存しておくことができます。
デバッガーが起動すると、この設定がグローバルに適用されます。以下に例を示します。

```bash
set callstyle short
set listsize 25
```

`web-console` gemによるデバッグ
------------------------------------

Web Consoleは`byebug`と似ていますが、ブラウザ上で動作する点が異なります。開発中のどのページでも、ビューやコントローラのコンテキストでコンソールをリクエストできます。コンソールは、HTMLコンテンツの隣に表示されます。

### Console

`console`メソッドを呼び出すことで、任意のコントローラのアクションやビューでいつでもコンソールを呼び出せます。

たとえば、コントローラで以下のように呼び出せます。

```ruby
class PostsController < ApplicationController
  def new
    console
    @post = Post.new
  end
end
```

ビューでも以下のように呼び出せます。

```html+erb
<% console %>

<h2>New Post</h2>
```

上のコードは、ビューの内部でコンソールを出力します。`console`を呼び出す位置を気にする必要はありません。コンソールは、呼び出し位置にかかわらず、HTMLコンテンツの隣りに出力されます。

コンソールでは純粋なRubyコードを実行できます。ここでカスタムクラスの定義やインスタンス化を行ったり、新しいモデルを作成したり、変数を検査したりすることができます。

NOTE: 一回のリクエストで出力できるコンソールは1つだけです。`console`呼び出しを2回以上行うと`web-console`でエラーが発生します。

### 変数の検査

`instance_variables`を呼び出すと、コンテキストで利用可能なインスタンス変数をすべてリスト表示できます。すべてのローカル変数をリスト表示したい場合は、`local_variables`を使います。

### 設定

* `config.web_console.whitelisted_ips`: 認証済みの IPv4/IPv6アドレスとネットワークのリストです (デフォルト値: `127.0.0.1/8、::1`).
* `config.web_console.whiny_requests`: コンソール出力が抑制されている場合にメッセージをログ出力します (デフォルト値: `true`).

`web-console`はサーバー上の純粋なRubyコードをリモート評価できるので、production環境では絶対に使わないください。

メモリーリークのデバッグ
----------------------

Railsに限らず、Rubyアプリケーションではメモリーリークが発生することがあります。リークはRubyコードレベルのこともあれば、Cコードレベルであることもあります。

このセクションでは、Valgrindなどのツールを使ってこうしたメモリーリークの検出と修正を行う方法をご紹介します。

### Valgrind

[Valgrind](http://valgrind.org/)はアプリケーションであり、Cコードベースのメモリーリークや競合状態の検出を行います。

Valgrindには、さまざまなメモリー管理上のバグやスレッドバグなどを自動検出し、プログラムの詳細なプロファイリングを行うための各種ツールがあります。たとえば、インタプリタ内にあるC拡張機能が`malloc()`を呼び出した後`free()`を正しく呼び出さなかった場合、このメモリーはアプリケーションが終了するまで利用できなくなります。

Valgrindのインストール方法とRuby内での利用方法については、[ValgrindとRuby](http://blog.evanweaver.com/articles/2008/02/05/valgrind-and-ruby/)(Evan Weaver著、英語) を参照してください。

デバッグ用プラグイン
---------------------

アプリケーションのエラーを検出し、デバッグするためのRailsプラグインがあります。デバッグ用に便利なプラグインのリストを以下にご紹介します。

* [Footnotes](https://github.com/josevalim/rails-footnotes): すべてのRailsページに脚注を追加し、リクエスト情報を表示したり、TextMateでソースを開くためのリンクを表示したりします。
* [Query Trace](https://github.com/ruckus/active-record-query-trace/tree/master): ログにクエリ元のトレースを追加します。
* [Query Reviewer](https://github.com/nesquena/query_reviewer): このRailsプラグインは、開発中のselectクエリの前に"EXPLAIN"を実行します。また、ページごとにDIVセクションを追加して、分析対象のクエリごとの警告の概要をそこに表示します。
* [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master): Railsアプリケーションでのエラー発生時用の、メーラーオブジェクトとメール通知送信テンプレートのデフォルトセットを提供します。
* [Better Errors](https://github.com/charliesome/better_errors): Rails標準のエラーページを新しい表示に置き換えて、ソースコードや変数検査などのコンテキスト情報を見やすくしてくれます。
* [RailsPanel](https://github.com/dejan/rails_panel): Rails開発用のChrome機能拡張です。これがあればdevelopment.logでtailコマンドを実行する必要がなくなります。Railsアプリケーションのリクエストに関するすべての情報をブラウザ上 (Developer Toolsパネル) に表示できます。
db時間、レンダリング時間、トータル時間、パラメータリスト、出力したビューなども表示されます。
* [Pry](https://github.com/pry/pry): もうひとつのIRBであり、開発用の実行時コンソールです。

参考資料
----------

* [byebugホームページ](https://github.com/deivid-rodriguez/byebug)(英語)
* [web-consoleホームページ](https://github.com/rails/web-console)(英語)
