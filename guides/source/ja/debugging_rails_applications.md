Rails アプリケーションのデバッグ
============================

本ガイドでは、Ruby on Railsアプリケーションのさまざまなデバッグ技法をご紹介します。

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

別の方法として、任意のオブジェクトに対して`to_yaml`を呼び出すことでYAMLに変換できます。変換したこのオブジェクトは、`simple_format`ヘルパーメソッドに渡して出力を整形できます。これは`debug`のマジックです。

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

TIP: ログの保存場所は、デフォルトでは`Rails.root/log/`になります。ログのファイル名は、アプリケーションが実行されるときの環境（development、test、productionなど）が使われます。

### ログの出力レベル

ログに出力されるメッセージのログレベルが、設定済みのログレベル以上になった場合に、対応するログファイルにそのメッセージが出力されます。現在のログレベルを知りたい場合は、`Rails.logger.level`メソッドを呼び出します。

指定可能なログレベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`の6つであり、それぞれ0から5までの数字に対応します。デフォルトのログレベルを変更するには以下のようにします。

```ruby
config.log_level = :warn # 環境ごとのイニシャライザで利用可能
Rails.logger.level = 0 # いつでも利用可能
```

これは、development環境やstaging環境ではログを出力し、production環境では不要な情報をログに出力したくない場合などに便利です。

TIP: Railsのデフォルトログレベルは全環境で`debug`です。ただし、デフォルトで生成される`config/environments/production.rb`では、`production`環境のデフォルトログレベルを`:info`に設定しています。

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
      logger.debug "記事は正常に保存され、ユーザーをリダイレクト中..."
      redirect_to @article, notice: '記事は正常に作成されました。'
    else
      render :new
    end
  end

  # ...

  private
    def article_params
      params.expect(article: [:title, :body, :published])
    end
end
```

上のコントローラのアクションを実行すると、以下のようなログが生成されます。

```
Started POST "/articles" for 127.0.0.1 at 2018-10-18 20:09:23 -0400
Processing by ArticlesController#create as HTML
  Parameters: {"utf8"=>"✓", "authenticity_token"=>"XLveDrKzF1SwaiNRPTaMtkrsTzedtebPPkmxEFIU0ordLjICSnXsSNfrdMa4ccyBjuGwnnEiQhEoMN6H1Gtz3A==", "article"=>{"title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs.", "published"=>"0"}, "commit"=>"Create Article"}
新しい記事: {"id"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs.", "published"=>false, "created_at"=>nil, "updated_at"=>nil}
記事が正しいかどうか: true
   (0.0ms)  begin transaction
  ↳ app/controllers/articles_controller.rb:31
  Article Create (0.5ms)  INSERT INTO "articles" ("title", "body", "published", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?)  [["title", "Debugging Rails"], ["body", "I'm learning how to print in logs."], ["published", 0], ["created_at", "2018-10-19 00:09:23.216549"], ["updated_at", "2018-10-19 00:09:23.216549"]]
  ↳ app/controllers/articles_controller.rb:31
   (2.3ms)  commit transaction
  ↳ app/controllers/articles_controller.rb:31
記事は正常に保存され、ユーザーをリダイレクト中...
Redirected to http://localhost:3000/articles/1
Completed 302 Found in 4ms (ActiveRecord: 0.8ms)
```

このようにログに独自の情報を追加すると、予想外の異常な動作をログで見つけやすくなります。ログに独自の情報を追加する場合は、productionログが無意味な大量のメッセージでうずまらないよう、適切なログレベルを使うようにしてください。

### 詳細なクエリログ

データベースクエリのログを見ただけでは、1個のメソッドを呼び出したときに大量のデータベースクエリがトリガーされる理由がすぐにわからないこともあります。

```irb
irb(main):001:0> Article.pamplemousse
  Article Load (0.4ms)  SELECT "articles".* FROM "articles"
  Comment Load (0.2ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 1]]
  Comment Load (0.1ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 2]]
  Comment Load (0.1ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 3]]
=> #<Comment id: 2, author: "1", body: "Well, actually...", article_id: 1, created_at: "2018-10-19 00:56:10", updated_at: "2018-10-19 00:56:10">
```

`bin/rails console`セッションで`ActiveRecord.verbose_query_logs = true`を実行すると詳細クエリログモードが有効になります。同じメソッドをもう一度実行すると、大量のデータベース呼び出しを生成しているコード行がどこにあるかががわかるようになります。

```irb
irb(main):003:0> Article.pamplemousse
  Article Load (0.2ms)  SELECT "articles".* FROM "articles"
  ↳ app/models/article.rb:5
  Comment Load (0.1ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 1]]
  ↳ app/models/article.rb:6
  Comment Load (0.1ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 2]]
  ↳ app/models/article.rb:6
  Comment Load (0.1ms)  SELECT "comments".* FROM "comments" WHERE "comments"."article_id" = ?  [["article_id", 3]]
  ↳ app/models/article.rb:6
=> #<Comment id: 2, author: "1", body: "Well, actually...", article_id: 1, created_at: "2018-10-19 00:56:10", updated_at: "2018-10-19 00:56:10">
```

各データベースステートメントの下には、データベースを呼び出したメソッドがあるソースファイル名と行番号が`app/models/article.rb:6`のように表示されています。これはN+1クエリ（1個のデータベースクエリが多数の追加クエリを生成する問題）が原因となるパフォーマンス問題を突き止めて対処するときに有用です。

Rails 5.2以降は、developmentモードで詳細クエリモードがデフォルトで有効になります。

WARNING: production環境では詳細クエリモードを有効にしないことをおすすめします。この設定はRubyの`Kernel#caller`メソッドに依存しており、メソッド呼び出しのスタックトレース生成で大量のメモリをアロケーションする傾向があります。

### 詳細なエンキューログ

上述の「詳細なクエリログ」と同様に、バックグラウンドジョブをエンキューするメソッドのソースの場所を表示できます。

development環境ではデフォルトで有効になっています。他の環境で有効にするには、`application.rb`または任意の環境イニシャライザに以下を追加します。

```rb
config.active_job.verbose_enqueue_logs = true
```

詳細なクエリログと同様に、production環境での利用は推奨されていません。

SQLクエリコメント
------------------

SQLステートメントに実行時情報（コントローラやジョブの名前など）を含むタグをコメントすることで、問題のあるクエリを、ステートメントを生成したアプリケーションの領域までさかのぼってトレースできます。
この機能は、遅いクエリをログ出力するとき（例：[MySQL][slow_query_log]、[PostgreSQL][runtime_config_logging]）や、現在実行中のクエリを表示するとき、エンドツーエンドのトレースツールで利用するときに便利です。

この機能を有効にするには、`application.rb`または任意の環境イニシャライザに以下を追加します。

```rb
config.active_record.query_log_tags_enabled = true
```

デフォルトでは、「アプリケーション名」「コントローラ名とアクション」または「ジョブ名」がログ出力されます。デフォルトの形式は[SQLCommenter][]です。たとえば、以下のような形式でログが出力されます。

```
Article Load (0.2ms)  SELECT "articles".* FROM "articles" /*application='Blog',controller='articles',action='index'*/

Article Update (0.3ms)  UPDATE "articles" SET "title" = ?, "updated_at" = ? WHERE "posts"."id" = ? /*application='Blog',job='ImproveTitleJob'*/  [["title", "Improved Rails debugging guide"], ["updated_at", "2022-10-16 20:25:40.091371"], ["id", 1]]
```

[`ActiveRecord::QueryLogs`][]の振る舞いを変更して、SQLクエリの全体像を把握するのに有用な情報（アプリケーションログのリクエストやジョブのID、アカウントやテナントの識別子など）を含めることも可能です。

[slow_query_log]: https://dev.mysql.com/doc/refman/en/slow-query-log.html
[runtime_config_logging]: https://www.postgresql.org/docs/current/runtime-config-logging.html#GUC-LOG-MIN-DURATION-STATEMENT
[SQLCommenter]: https://open-telemetry.github.io/opentelemetry-sqlcommenter/
[`ActiveRecord::QueryLogs`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html

### タグ付きログの出力

ユーザーとアカウントを多数使うアプリケーションを実行するときに、何らかのカスタムルールを設定してログをフィルタできると便利です。Active Supportの`TaggedLogging`を使えば、サブドメインやリクエストIDなどを指定してログを絞り込むことができ、このようなアプリケーションのデバッグがはかどります。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # "[BCX] Stuff"を出力
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # "[BCX] [Jason] Stuff"を出力
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # "[BCX] [Jason] Stuff"を出力
```

### ログがパフォーマンスに与える影響

ログ出力は、Railsアプリケーションのパフォーマンスに常に小さな影響を与えます。ログをディスクに保存する場合は特にそうです。さらに、場合によっては小さな影響とは言い切れないこともあります。

ログレベル`:debug`は、`:fatal`と比べてはるかに多くの文字列が評価（およびディスクなどに出力）されるため、パフォーマンスに与える影響がずっと大きくなります。

他にも、以下のように`Logger`の呼び出しを多数実行した場合には落とし穴に注意する必要があります。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

上の例では、たとえログ出力レベルをdebugにしなかった場合でもパフォーマンスが低下します。その理由は、上のコードでは文字列を評価する必要があり、その際に比較的動作が重い`String`オブジェクトのインスタンス化や変数の式展開（interpolation）が行われているからです。

したがって、ロガーメソッドに渡すものはブロック形式にすることをおすすめします。ブロックとして渡しておけば、ブロックの評価は出力レベルが設定レベル以上になった場合にしか行われないようになる（遅延読み込みされる）ためです。これに従って上のコードを書き直すと以下のようになります。

```ruby
logger.debug { "Person attributes hash: #{@person.attributes.inspect}" }
```

渡したブロックの内容（ここでは文字列の式展開）は、debugが有効になっている場合にしか評価されません。この方法によるパフォーマンスの改善は、大量のログを出力しているときでないとそれほど実感できないかもしれませんが、それでも採用する価値があります。

INFO: 本セクションは[Stack OverflowでのJon Cairnsによる回答](https://stackoverflow.com/questions/16546730/logging-in-rails-is-there-any-performance-hit/16546935#16546935)として書かれたものであり、[cc by-sa 4.0](https://creativecommons.org/licenses/by-sa/4.0/)ライセンスに基づいています。

`debug` gemでデバッグする
---------------------------------

コードが期待どおりに動作しない場合は、ログやコンソールに出力して問題を診断できます。ただし、この方法ではエラー追跡を何度も繰り返さねばならず、根本的な原因を突き止めるには能率がよいとは言えません。
実行中のコードを調査するときに最も頼りになるのは、やはりデバッガーです。

デバッガーは、Railsのソースコードについて学びたいけれども始め方が分からないという場合にも助けになります。とにかくアプリケーションへのリクエストのどれか1つでデバッグを開始して、自分が書いたコードからRailsのもっと深いところへダイブする方法は本ガイドを使って学びましょう。

Rails 7では、CRubyで生成した新しいアプリケーションの`Gemfile`に`debug` gemが含まれるようになりました。デフォルトでは、`development`環境と`test`環境でこのgemをすぐに利用できます。使い方について詳しくは`debug` gemの[ドキュメント](https://github.com/ruby/debug)を参照してください。

### デバッグセッションに入る

デフォルトでは、デバッグセッションが開始されるのは`debug`ライブラリが`require`された後です。これはアプリの起動中に行われます。しかしデバッグセッションがあなたのプログラムを邪魔することはないので心配は無用です。

デバッグセッションに入るには、`binding.break`（またはエイリアスの`binding.b`や`debugger`）を利用できます。以下の例では`debugger`を使います。

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts or /posts.json
  def index
    @posts = Post.all
    debugger
  end
  # ...
end
```

`debugger`ステートメントがアプリで評価されると、デバッグセッションが開始されます。

```ruby
Processing by PostsController#index as HTML
[2, 11] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
     2|   before_action :set_post, only: %i[ show edit update destroy ]
     3|
     4|   # GET /posts or /posts.json
     5|   def index
     6|     @posts = Post.all
=>   7|     debugger
     8|   end
     9|
    10|   # GET /posts/1 or /posts/1.json
    11|   def show
=>#0    PostsController#index at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:7
  #1    ActionController::BasicImplicitRender#send_action(method="index", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-8.0.0.alpha/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg)
```

デバッグセッションはいつでも終了可能です。アプリケーションの実行は`continue`（または`c`）コマンドで継続可能です。また、デバッグセッションとアプリケーションの両方を終了させたい場合は、`quit`（または`q`）コマンドを使います。

### コンテキスト

デバッグセッションに入ると、RailsコンソールやIRBと同様にRubyコードを入力できます。

```ruby
(rdbg) @posts    # ruby
[]
(rdbg) self
#<PostsController:0x0000000000aeb0>
(rdbg)
```

`p`コマンドや`pp`コマンドでRubyの式を評価できます（変数名がデバッガのコマンドと衝突しているときなど）。

```ruby
(rdbg) p headers    # コマンド
=> {"X-Frame-Options"=>"SAMEORIGIN", "X-XSS-Protection"=>"1; mode=block", "X-Content-Type-Options"=>"nosniff", "X-Download-Options"=>"noopen", "X-Permitted-Cross-Domain-Policies"=>"none", "Referrer-Policy"=>"strict-origin-when-cross-origin"}
(rdbg) pp headers    # コマンド
{"X-Frame-Options"=>"SAMEORIGIN",
 "X-XSS-Protection"=>"1; mode=block",
 "X-Content-Type-Options"=>"nosniff",
 "X-Download-Options"=>"noopen",
 "X-Permitted-Cross-Domain-Policies"=>"none",
 "Referrer-Policy"=>"strict-origin-when-cross-origin"}
(rdbg)
```

デバッガでは、直接の評価に加えて、さまざまなコマンドで豊富な情報を取り出せます。ここではそのいくつかについてのみご紹介します。

- `info`（`i`）: 現在のフレームに関する情報を表示する
- `backtrace`（`bt`）: バックトレースと付加情報を表示する
- `outline`（または`o`、`ls`）: 現在のスコープで利用可能なメソッド、定数、ローカル変数、インスタンス変数を表示する

#### `info`コマンド

`info`は、現在のフレームで参照可能なローカル変数やインスタンス変数の値に関する概要を表示します。

```ruby
(rdbg) info    # command
%self = #<PostsController:0x0000000000af78>
@_action_has_layout = true
@_action_name = "index"
@_config = {}
@_lookup_context = #<ActionView::LookupContext:0x00007fd91a037e38 @details_key=nil, @digest_cache=...
@_request = #<ActionDispatch::Request GET "http://localhost:3000/posts" for 127.0.0.1>
@_response = #<ActionDispatch::Response:0x00007fd91a03ea08 @mon_data=#<Monitor:0x00007fd91a03e8c8>...
@_response_body = nil
@_routes = nil
@marked_for_same_origin_verification = true
@posts = []
@rendered_format = nil
```

#### `backtrace`コマンド

オプションなしで実行すると、`backtrace`が以下のようにスタックのフレームをすべて表示します。

```rb
=>#0    PostsController#index at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:7
  #1    ActionController::BasicImplicitRender#send_action(method="index", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-2.0.alpha/lib/action_controller/metal/basic_implicit_render.rb:6
  #2    AbstractController::Base#process_action(method_name="index", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-8.0.0.alpha/lib/abstract_controller/base.rb:214
  #3    ActionController::Rendering#process_action(#arg_rest=nil) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-8.0.0.alpha/lib/action_controller/metal/rendering.rb:53
  #4    block in process_action at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-8.0.0.alpha/lib/abstract_controller/callbacks.rb:221
  #5    block in run_callbacks at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activesupport-8.0.0.alpha/lib/active_support/callbacks.rb:118
  #6    ActionText::Rendering::ClassMethods#with_renderer(renderer=#<PostsController:0x0000000000af78>) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actiontext-8.0.0.alpha/lib/action_text/rendering.rb:20
  #7    block {|controller=#<PostsController:0x0000000000af78>, action=#<Proc:0x00007fd91985f1c0 /Users/st0012/...|} in <class:Engine> (4 levels) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actiontext-8.0.0.alpha/lib/action_text/engine.rb:69
  #8    [C] BasicObject#instance_exec at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activesupport-8.0.0.alpha/lib/active_support/callbacks.rb:127
  ..... and more
```

すべてのフレームには以下の情報が付加されます。

- フレームID
- 呼び出しの場所
- 付加情報（ブロックかメソッド引数か、など）

これらの情報で、アプリ内で起こっていることが手に取るようにわかります。しかし、やがて以下のことに気づくでしょう。

- フレーム数が多すぎる（Railsアプリでは50を超えることが多い）
- フレームのほとんどはRails由来または別のライブラリ由来

ご心配なく。`backtrace`コマンドはフレームを絞り込む2つのフィルタオプションを提供しています。

- `backtrace [num]`: `num`でフレーム番号を指定する（`backtrace 10`など）
- `backtrace /pattern/`: 識別子やファイルパスがパターンにマッチするフレームだけを表示する（`backtrace /MyModel/`など）

`backtrace [num] /pattern/`のように、2つのオプションを同時に指定することも可能です。

#### `outline`コマンド

このコマンドは、`pry`や`irb`の`ls`コマンドに似ています。以下のような、現在のスコープでアクセス可能なものを表示します。

- ローカル変数
- インスタンス変数
- クラス変数
- メソッド名とそのソースコード

```ruby
ActiveSupport::Configurable#methods: config
AbstractController::Base#methods:
  action_methods  action_name  action_name=  available_action?  controller_path  inspect
  response_body
ActionController::Metal#methods:
  content_type       content_type=  controller_name  dispatch          headers
  location           location=      media_type       middleware_stack  middleware_stack=
  middleware_stack?  performed?     request          request=          reset_session
  response           response=      response_body=   response_code     session
  set_request!       set_response!  status           status=           to_a
ActionView::ViewPaths#methods:
  _prefixes  any_templates?  append_view_path   details_for_lookup  formats     formats=  locale
  locale=    lookup_context  prepend_view_path  template_exists?    view_paths
AbstractController::Rendering#methods: view_assigns

# .....

PostsController#methods: create  destroy  edit  index  new  show  update
instance variables:
  @_action_has_layout  @_action_name    @_config  @_lookup_context                      @_request
  @_response           @_response_body  @_routes  @marked_for_same_origin_verification  @posts
  @rendered_format
class variables: @@raise_on_open_redirects
```

### ブレークポイント

デバッガでは、さまざまな方法でブレークポイントを挿入・トリガーできます。`debugger`をコードに直接追加する以外に、以下のコマンドでもブレークポイントを挿入できます。

- `break`（または`b`）
  - `break`: すべてのブレークポイントを表示する
  - `break <num>`: 現在のファイルの`num`行目にブレークポイントを設定する
  - `break <file:num>`: `file`の`num`行目にブレークポイントを設定する
  - `break <Class#method>`または`break <Class.method>`: `Class#method`や`Class.method`にブレークポイントを設定する
  - `break <expr>.<method>`: `<expr>`の結果の`<method>`にブレークポイントを設定する
- `catch <Exception>`: `Exception`が発生すると停止するブレークポイントを設定する
- `watch <@ivar>`: 現在のオブジェクトの`@ivar`の結果が変更されると停止するブレークポイントを設定する（ただし低速）

ブレークポイントを削除するには以下のコマンドが使えます。

- `delete`（または`del`）
  - `delete`: すべてのブレークポイントを削除する
  - `delete <num>`:  id `num`のブレークポイントを削除する

#### `break`コマンド

指定の行番号にブレークポイントを設定します（例: `b 28`）。

```rb
[20, 29] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
    20|   end
    21|
    22|   # POST /posts or /posts.json
    23|   def create
    24|     @post = Post.new(post_params)
=>  25|     debugger
    26|
    27|     respond_to do |format|
    28|       if @post.save
    29|         format.html { redirect_to @post, notice: "Post was successfully created." }
=>#0    PostsController#create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:25
  #1    ActionController::BasicImplicitRender#send_action(method="create", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg) b 28    # breakコマンド
#0  BP - Line  /Users/st0012/projects/rails-guide-example/app/controllers/posts_controller.rb:28 (line)
```

```rb
(rdbg) c    # 続行コマンド
[23, 32] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
    23|   def create
    24|     @post = Post.new(post_params)
    25|     debugger
    26|
    27|     respond_to do |format|
=>  28|       if @post.save
    29|         format.html { redirect_to @post, notice: "Post was successfully created." }
    30|         format.json { render :show, status: :created, location: @post }
    31|       else
    32|         format.html { render :new, status: :unprocessable_entity }
=>#0    block {|format=#<ActionController::MimeResponds::Collec...|} in create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:28
  #1    ActionController::MimeResponds#respond_to(mimes=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/mime_responds.rb:205
  # and 74 frames (use `bt' command for all frames)

Stop by #0  BP - Line  /Users/st0012/projects/rails-guide-example/app/controllers/posts_controller.rb:28 (line)
```

以下は指定のメソッド呼び出しにブレークポイントを設定します（例: `b @post.save`）。

```rb
[20, 29] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
    20|   end
    21|
    22|   # POST /posts or /posts.json
    23|   def create
    24|     @post = Post.new(post_params)
=>  25|     debugger
    26|
    27|     respond_to do |format|
    28|       if @post.save
    29|         format.html { redirect_to @post, notice: "Post was successfully created." }
=>#0    PostsController#create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:25
  #1    ActionController::BasicImplicitRender#send_action(method="create", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg) b @post.save    # breakコマンド
#0  BP - Method  @post.save at /Users/st0012/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/suppressor.rb:43

```

```rb
(rdbg) c    # 続行コマンド
[39, 48] in ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/suppressor.rb
    39|         SuppressorRegistry.suppressed[name] = previous_state
    40|       end
    41|     end
    42|
    43|     def save(**) # :nodoc:
=>  44|       SuppressorRegistry.suppressed[self.class.name] ? true : super
    45|     end
    46|
    47|     def save!(**) # :nodoc:
    48|       SuppressorRegistry.suppressed[self.class.name] ? true : super
=>#0    ActiveRecord::Suppressor#save(#arg_rest=nil) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/suppressor.rb:44
  #1    block {|format=#<ActionController::MimeResponds::Collec...|} in create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:28
  # and 75 frames (use `bt' command for all frames)

Stop by #0  BP - Method  @post.save at /Users/st0012/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/suppressor.rb:43
```

#### `catch`コマンド

例外発生時に停止します（例: `catch ActiveRecord::RecordInvalid`）。

```rb
[20, 29] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
    20|   end
    21|
    22|   # POST /posts or /posts.json
    23|   def create
    24|     @post = Post.new(post_params)
=>  25|     debugger
    26|
    27|     respond_to do |format|
    28|       if @post.save!
    29|         format.html { redirect_to @post, notice: "Post was successfully created." }
=>#0    PostsController#create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:25
  #1    ActionController::BasicImplicitRender#send_action(method="create", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg) catch ActiveRecord::RecordInvalid    # catchコマンド
#1  BP - Catch  "ActiveRecord::RecordInvalid"
```

```rb
(rdbg) c    # 続行コマンド
[75, 84] in ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb
    75|     def default_validation_context
    76|       new_record? ? :create : :update
    77|     end
    78|
    79|     def raise_validation_error
=>  80|       raise(RecordInvalid.new(self))
    81|     end
    82|
    83|     def perform_validations(options = {})
    84|       options[:validate] == false || valid?(options[:context])
=>#0    ActiveRecord::Validations#raise_validation_error at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:80
  #1    ActiveRecord::Validations#save!(options={}) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:53
  # and 88 frames (use `bt' command for all frames)

Stop by #1  BP - Catch  "ActiveRecord::RecordInvalid"
```

#### `watch`コマンド

インスタンス変数の変更時に停止します（例: `watch @_response_body`）。

```rb
[20, 29] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
    20|   end
    21|
    22|   # POST /posts or /posts.json
    23|   def create
    24|     @post = Post.new(post_params)
=>  25|     debugger
    26|
    27|     respond_to do |format|
    28|       if @post.save!
    29|         format.html { redirect_to @post, notice: "Post was successfully created." }
=>#0    PostsController#create at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:25
  #1    ActionController::BasicImplicitRender#send_action(method="create", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg) watch @_response_body    # watchコマンド
#0  BP - Watch  #<PostsController:0x00007fce69ca5320> @_response_body =
```

```rb
(rdbg) c    # 続行コマンド
[173, 182] in ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal.rb
   173|       body = [body] unless body.nil? || body.respond_to?(:each)
   174|       response.reset_body!
   175|       return unless body
   176|       response.body = body
   177|       super
=> 178|     end
   179|
   180|     # renderかredirectが既に実行されたかどうかをテストする
   181|     def performed?
   182|       response_body || response.committed?
=>#0    ActionController::Metal#response_body=(body=["<html><body>You are being <a href=\"ht...) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal.rb:178 #=> ["<html><body>You are being <a href=\"ht...
  #1    ActionController::Redirecting#redirect_to(options=#<Post id: 13, title: "qweqwe", content:..., response_options={:allow_other_host=>false}) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/redirecting.rb:74
  # and 82 frames (use `bt' command for all frames)

Stop by #0  BP - Watch  #<PostsController:0x00007fce69ca5320> @_response_body =  -> ["<html><body>You are being <a href=\"http://localhost:3000/posts/13\">redirected</a>.</body></html>"]
(rdbg)
```

#### ブレークポイントのオプション

さまざまな種類のブレークポイントに加えて、より高度なデバッグフローを実現するオプションも指定できます。現在は以下の4種類のオプションがサポートされています。

- `do: <cmdまたはexpr>`: ブレークポイントがトリガーされると、指定のコマンドや式を実行してプログラムを続行する
  - `break Foo#bar do: bt`: `Foo#bar`が呼び出されたときにスタックフレームを出力する
- `pre: <cmdまたはexpr>`: ブレークポイントがトリガーされると、指定のコマンドや式を実行してから停止する
  - `break Foo#bar pre: info`: `Foo#bar`が呼び出されると、周辺の変数を出力してから停止する
- `if: <expr>`: `<expr`>の結果がtrueの場合にのみブレークポイントを停止する
  - `break Post#save if: params[:debug]`: `params[:debug]`もtrueの場合に`Post#save`で停止する
- `path: <path_regexp>`: トリガーとなるイベント（メソッド呼び出しなど）が指定のパスで発生した場合にのみブレークポイントを停止する
  - `break Post#save path: app/services/a_service`: メソッド呼び出しが`/app\/services\/a_service/`を含むパスで発生したら`Post#save`で停止する

最初の3つのオプション「`do:`」「`pre:`」「`if:`」については、以下のように前述の`debugger`ステートメントのオプションとしても利用できます。

```rb
[2, 11] in ~/projects/rails-guide-example/app/controllers/posts_controller.rb
     2|   before_action :set_post, only: %i[ show edit update destroy ]
     3|
     4|   # GET /posts or /posts.json
     5|   def index
     6|     @posts = Post.all
=>   7|     debugger(do: "info")
     8|   end
     9|
    10|   # GET /posts/1 or /posts/1.json
    11|   def show
=>#0    PostsController#index at ~/projects/rails-guide-example/app/controllers/posts_controller.rb:7
  #1    ActionController::BasicImplicitRender#send_action(method="index", args=[]) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/actionpack-7.0.0.alpha2/lib/action_controller/metal/basic_implicit_render.rb:6
  # and 72 frames (use `bt' command for all frames)
(rdbg:binding.break) info
%self = #<PostsController:0x00000000017480>
@_action_has_layout = true
@_action_name = "index"
@_config = {}
@_lookup_context = #<ActionView::LookupContext:0x00007fce3ad336b8 @details_key=nil, @digest_cache=...
@_request = #<ActionDispatch::Request GET "http://localhost:3000/posts" for 127.0.0.1>
@_response = #<ActionDispatch::Response:0x00007fce3ad397e8 @mon_data=#<Monitor:0x00007fce3ad396a8>...
@_response_body = nil
@_routes = nil
@marked_for_same_origin_verification = true
@posts = #<ActiveRecord::Relation [#<Post id: 2, title: "qweqwe", content: "qweqwe", created_at: "...
@rendered_format = nil
```

#### デバッグのワークフローをスクリプト化する

上述のオプションを利用すると、以下のようにデバッグのワークフローをスクリプト化できます。

```rb
def create
  debugger(do: "catch ActiveRecord::RecordInvalid do: bt 10")
  # ...
end
```

これで、スクリプト化されたコマンドをデバッガーが実行して`catch`ブレークポイントを挿入します。

```rb
(rdbg:binding.break) catch ActiveRecord::RecordInvalid do: bt 10
#0  BP - Catch  "ActiveRecord::RecordInvalid"
[75, 84] in ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb
    75|     def default_validation_context
    76|       new_record? ? :create : :update
    77|     end
    78|
    79|     def raise_validation_error
=>  80|       raise(RecordInvalid.new(self))
    81|     end
    82|
    83|     def perform_validations(options = {})
    84|       options[:validate] == false || valid?(options[:context])
=>#0    ActiveRecord::Validations#raise_validation_error at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:80
  #1    ActiveRecord::Validations#save!(options={}) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:53
  # and 88 frames (use `bt' command for all frames)
```

`catch`ブレークポイントがトリガーされると、スタックフレームが出力されます。

```rb
Stop by #0  BP - Catch  "ActiveRecord::RecordInvalid"

(rdbg:catch) bt 10
=>#0    ActiveRecord::Validations#raise_validation_error at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:80
  #1    ActiveRecord::Validations#save!(options={}) at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/validations.rb:53
  #2    block in save! at ~/.rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-7.0.0.alpha2/lib/active_record/transactions.rb:302
```

この手法を活用することで、同じデバッグフローを繰り返し入力する手間を省いてスムーズにデバッグできるようになります。

その他のコマンドや設定オプションについて詳しくは`debug` gemの[ドキュメント](https://github.com/ruby/debug)を参照してください。

`web-console` gemによるデバッグ
------------------------------------

Web Consoleは`debug`と似ていますが、ブラウザ上で動作する点が異なります。開発中の任意のページで、ビューやコントローラのコンテキストでコンソールをリクエストできます。コンソールは、HTMLコンテンツの下に表示されます。

### console

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

コンソールでは純粋なRubyコードを実行できます。ここでカスタムクラスの定義やインスタンス化を行うことも、新しいモデルを作成することも、変数を検査したりすることもできます。

NOTE: 1回のリクエストで出力できるコンソールは1つだけです。`console`を2回以上呼び出すと、`web-console`でエラーが発生します。

### 変数の検査

`instance_variables`を呼び出すと、コンテキストで利用可能なインスタンス変数をすべてリスト表示できます。すべてのローカル変数をリスト表示したい場合は、`local_variables`を使います。

### 設定

* `config.web_console.allowed_ips`: 認証済みのIPv4/IPv6アドレスとネットワークのリストです（デフォルト値: `127.0.0.1/8、::1`）。
* `config.web_console.whiny_requests`: コンソール出力が抑制されている場合にメッセージをログ出力します（デフォルト値: `true`）。

`web-console`はサーバー上の純粋なRubyコードをリモート評価できるので、production環境では絶対に使わないください。

メモリーリークのデバッグ
----------------------

Railsに限らず、Rubyアプリケーションではメモリーリークが発生することがあります。リークはRubyコードレベルのこともあれば、Cコードレベルのこともあります。

このセクションでは、Valgrindなどのツールを使ってこうしたメモリーリークの検出と修正を行う方法をご紹介します。

### Valgrind

[Valgrind](http://valgrind.org/)は、メモリーリークや競合状態の検出を行うCコードベースのアプリケーションです。

Valgrindには、さまざまなメモリー管理上のバグやスレッドバグなどを自動検出し、プログラムの詳細なプロファイリングを行うための各種ツールがあります。たとえば、インタプリタ内にあるC拡張機能が`malloc()`を呼び出した後`free()`を正しく呼び出さなかった場合、このメモリーはアプリケーションが終了するまで利用できなくなります。

Valgrindのインストール方法とRuby内での利用方法について詳しくは、[ValgrindとRuby](https://web.archive.org/web/20230518081626/https://blog.evanweaver.com/2008/02/05/valgrind-and-ruby/)（Evan Weaver著、英語）を参照してください。

### メモリーリークを探す

derailed_benchmark gemの[README](https://github.com/schneems/derailed_benchmarks#is-my-app-leaking-memory)には、メモリーリークを検出および修正する優れた記事があります。

デバッグ用プラグイン
---------------------

アプリケーションのエラーを検出し、デバッグするためのRailsプラグインがあります。デバッグ用に便利なプラグインのリストを以下にご紹介します。

* [Query Trace](https://github.com/ruckus/active-record-query-trace/tree/master): ログにクエリ元のトレースを追加します。
* [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master): Railsアプリケーションでのエラー発生時用の、メーラーオブジェクトとメール通知送信テンプレートのデフォルトセットを提供します。
* [Better Errors](https://github.com/charliesome/better_errors): Rails標準のエラーページを新しい表示に置き換えて、ソースコードや変数検査などのコンテキスト情報を見やすくしてくれます。
* [RailsPanel](https://github.com/dejan/rails_panel): Rails開発用のChrome機能拡張です。これがあればdevelopment.logでtailコマンドを実行する必要がなくなります。Railsアプリケーションのリクエストに関するすべての情報をブラウザ上のDeveloper Toolsパネルに表示できます。
db時間、レンダリング時間、トータル時間、パラメータリスト、出力したビューなども表示されます。
* [Pry](https://github.com/pry/pry): もう1つのIRBであり、開発用の実行時コンソールです。

参考資料
----------

* [web-consoleホームページ](https://github.com/rails/web-console)（英語）
* [debugホームページ](https://github.com/ruby/debug)（英語）
