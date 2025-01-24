Rails テスティングガイド
=====================================

本ガイドは、Railsでテストを書く方法について解説します。

このガイドの内容:

* Railsテスティング用語
* アプリケーションに対する単体テスト、機能テスト、結合テスト、システムテスト（system test）の実施
* その他の著名なテスティング方法とプラグインの紹介

--------------------------------------------------------------------------------


Railsアプリケーションでテストを作成する理由
--------------------------------------------

自動実行されるテストを書いておけば、ブラウザやコンソールでの手動テストよりも、コードが期待どおりに動作していることをより短時間で確認できます。テストが失敗すれば問題がすぐに明らかになり、開発プロセスの早い段階でバグを特定して修正できるようになります。テストの自動化によって、コードの信頼性が向上するだけでなく、変更に対する信頼性も向上します。

Railsでは、テストを簡単に記述できます。Railsに組み込まれているテストのサポートについては、次のセクションで詳しく説明します。

テストを導入する
-----------------------

Railsでは、新しいアプリケーションの作成時からテストが開発プロセスの中心になります。

### テストをセットアップする

`rails new アプリケーション名`コマンドでRailsアプリケーションを作成すると、その場で`test/`ディレクトリが作成されます。このディレクトリの内容を一覧表示すると、次のようになります。

```bash
$ ls -F test
application_system_test_case.rb  controllers/                     helpers/                         mailers/                         system/                          fixtures/                        integration/                     models/                          test_helper.rb
```

### `test`ディレクトリの構造

`helpers/`ディレクトリには[ビューヘルパーのテスト](#ビューヘルパーをテストする)、`mailers/`ディレクトリには[メーラーのテスト](#メーラーをテストする)、`models/`ディレクトリには[モデル用のテスト](#モデルのテスト)をそれぞれ保存します。

`controllers/`ディレクトリは、[コントローラに関連するテスト](#コントローラの機能テスト)の置き場所で、ルーティングやビューに関連するテストもここに置きます。ここで行うテストではHTTPリクエストをシミュレートして、その結果に対してアサーションを行います。

`integration`ディレクトリは、[コントローラ同士のやりとりのテスト](#結合テスト)を置く場所として予約されています。

`system/`ディレクトリには、アプリケーションをブラウザから操作してテストする[システムテスト](#システムテスト)が保存されます。システムテストを使うと、ユーザーが実際に体験する方法でアプリケーションをテストできるほか、JavaScriptのテストにも役立ちます。システムテストは、アプリケーションのブラウザ内テストを実行する[Capybara](https://github.com/teamcapybara/capybara)から継承した機能です。

フィクスチャはテストデータを編成する方法の1つであり、`fixtures`フォルダに置かれます。

[フィクスチャ][`Fixtures`]は、テストで使うデータをモックアップする方法の一種です。フィクスチャを使うと、「実際の」データを使わずに済むようになります。これらは`fixtures`ディレクトリに保存されます。詳しくは[フィクスチャ](#フィクスチャ)セクションで後述します。

ジョブテスト用の`jobs/`ディレクトリは、[ジョブを最初に生成](active_job_basics.html#ジョブを作成する)したときに作成されます。

`test_helper.rb`にはテスティングのデフォルト設定を記述します。

`application_system_test_case.rb`には、システムテストのデフォルトの設定を記述します。

[`Fixtures`]:
  https://api.rubyonrails.org/v3.1/classes/ActiveRecord/Fixtures.html

### test環境

デフォルトでは、すべてのRailsアプリケーションにはdevelopment環境、test環境、production環境の3つの環境があります。

それぞれの環境の設定はいずれも同様の方法で変更できます。テストの場合は、`config/environments/test.rb`にあるオプションを変更することでtest環境の設定を変更できます。

NOTE: テストは`RAILS_ENV=test`環境で実行されます。これはRailsによって自動的に設定されます。

### 最初のテストを書く

ガイドの[Rails をはじめよう](getting_started.html)では、`rails generate model`コマンドを紹介しました。ジェネレータでモデルを作成すると、`test/`ディレクトリの下にテストのスタブ（stub）が生成されます。

```bash
$ bin/rails generate model article title:string body:text
...
create  app/models/article.rb
create  test/models/article_test.rb
create  test/fixtures/articles.yml
...
```

`test/models/article_test.rb`に含まれるデフォルトのテストスタブの内容は以下のような感じになります。

```ruby
require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
```

Railsにおけるテスティングコードや用語の理解に役立てるため、このファイルの内容を上から順に見ていきましょう。

```ruby
require "test_helper"
```

`test_helper.rb`ファイルを`require`すると、テストで使うデフォルト設定として`test_helper.rb`が読み込まれます。このファイルに追加したメソッドは、`require "test_helper"`を追加したどのテストでも使えるようになります。

```ruby
class ArticleTest < ActiveSupport::TestCase
  # ...
end
```

上の`ArticleTest`クラスは、**テストケース**（test case）と呼ばれます。
このクラスは`ActiveSupport::TestCase`を継承しているので、`ActiveSupport::TestCase`にあるすべてのメソッドを`ArticleTest`で利用できます。利用できるメソッドのいくつかについては[後述します](#テストケースのアサーション)。

`Minitest::Test`（`ActiveSupport::TestCase`のスーパークラス）を継承したクラス（テストケース）で定義される、`test_`で始まる個別のメソッドは、単に**テスト**（test）と呼ばれます（この`test_`は小文字でなければなりません）。
従って、`test_password`および`test_valid_password`と定義されたメソッド名は正式なテスト名となり、テストケースの実行時に自動的に実行されます。

Railsでは、テスト名を表す文字列とブロックを受け取る`test`メソッドも利用できます。`test`メソッドを使うと、メソッド名の冒頭に`test_`を追加した標準の`Minitest::Unit`テストが生成されます。これにより、メソッドの命名に気を遣わずに済み、次のような感じで書けます。

```ruby
test "the truth" do
  assert true
end
```

上のコードは、以下のように書いた場合と同等に振る舞います。

```ruby
def test_the_truth
  assert true
end
```

通常のメソッド定義を使ってもよいのですが、`test`マクロを適用することで、引用符で囲まれた読みやすいテスト名がテストメソッドの定義に変換されます。

NOTE: テスト名からのメソッド名生成は、スペース` `をアンダースコア`_`に置き換えることによって行われます。Rubyではメソッド名にどんな文字列でも使えるので、生成されたメソッド名はRubyの正規な識別子である必要はなく、テスト名にパンクチュエーション（句読点）などの文字が含まれていても大丈夫です。メソッド名で普通でない文字を使おうとすると`define_method`呼び出しや`send`呼び出しが必要になりますが、名前の付け方そのものには公式な制限はほとんどありません。

テストの以下の部分は、**アサーション**（assertion: 主張、表明）と呼ばれます。

```ruby
assert true
```

アサーションとは、オブジェクトまたは式を評価して、期待された結果が得られるかどうかをチェックするコード行です。アサーションでは以下のようなチェックを行えます。

* ある値が別の値と等しいかどうか
* このオブジェクトは`nil`かどうか
* コードのこの行で例外が発生するかどうか
* ユーザーのパスワードが5文字より多いかどうか

1つのテストにアサーションを複数書くことも可能です。この場合、すべてのアサーションが成功しないとテストがパスしません。

### 最初の「失敗するテスト」

今度はテストが失敗した場合の結果を見てみましょう。そのためには、`article_test.rb`テストケースに、確実に失敗するテストを以下のように追加します。

この例では、特定の基準を満たさなければ記事は保存されないというアサーションが使われています。したがって、記事が正常に保存されると、テストは失敗し、テストの失敗が示されます。

```ruby
require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "should not save article without title" do
    article = Article.new
    assert_not article.save
  end
end
```

以下は、新しく追加したテストの実行結果です。

```bash
$ bin/rails test test/models/article_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 44656

# Running:

F

Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:4]:
Expected true to be nil or false


bin/rails test test/models/article_test.rb:4



Finished in 0.023918s, 41.8090 runs/s, 41.8090 assertions/s.

1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
```

- 出力に含まれている`F`は失敗を表します。
- `Failure`の下には、この失敗に対応するトレースと、失敗したテスト名が表示されています。
- 次の数行はスタックトレースで、アサーションの実際の値と期待されていた値がその後に表示されています。
- デフォルトのアサーションメッセージには、エラー箇所を特定するのに十分な情報が含まれています。

どのアサーションでも、以下のように失敗時のメッセージをオプションパラメータとして渡すことで、失敗時のメッセージをさらに読みやすくできます。


```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save, "Saved the article without a title"
end
```

テストを実行すると、以下のようにさらに読みやすいメッセージが表示されます。

```
Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:6]:
Saved the article without a title
```

このテストがパスするように、titleフィールドでモデルレベルのバリデーションを追加します。

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
end
```

このテストはパスするはずです。
テスト内の記事は`title`で初期化されていないため、モデルのバリデーションによって保存が阻止されます。テストを再度実行してみると、このことを確認できます。

```bash
$ bin/rails test test/models/article_test.rb:6
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 31252

# Running:

.

Finished in 0.027476s, 36.3952 runs/s, 36.3952 assertions/s.

1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

`F`ではなく小さな緑の点`.`が表示されているのは、テストが正常にパスしたことを表します。

TIP: ここでは、目的の機能で失敗するテストを最初に書いてから、機能を追加するコードを書く、という手順で進め、最後にテストが再度を実行するとパスすることを確認しました。ソフトウェア開発の世界では、このような「失敗するテストを最初に書いてからコードを修正する」アプローチをテスト駆動開発（[Test-Driven Development](http://wiki.c2.com/?TestDrivenDevelopment) : TDD）と呼んでいます。

### エラーの表示内容

以下は、テスト中にエラーが発生すると、どのように表示されるかを確認するための、わざと誤りを含んだテストです。

```ruby
test "should report error" do
  # このsome_undefined_variableはテストケースのどこにも定義されていない
  some_undefined_variable
  assert true
end
```

このテストを実行すると、通常よりも多くのメッセージがコンソールに表示されます。

```bash
$ bin/rails test test/models/article_test.rb
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 1808

# Running:

E

Error:
ArticleTest#test_should_report_error:
NameError: undefined local variable or method 'some_undefined_variable' for #<ArticleTest:0x007fee3aa71798>
    test/models/article_test.rb:11:in 'block in <class:ArticleTest>'


bin/rails test test/models/article_test.rb:9

.

Finished in 0.040609s, 49.2500 runs/s, 24.6250 assertions/s.

2 runs, 1 assertions, 0 failures, 1 errors, 0 skips
```

今度は`E`が出力されます。これはエラーが発生したテストが1件あることを示しています。

NOTE: テストスイートに含まれる各テストメソッドは、エラーまたはアサーション失敗が発生するとそこで実行を中止し、次のテストメソッドに進みます。Railsのテストメソッドは、デフォルトではすべてランダムな順序で実行されるようになっています（テストの実行順序は[`config.active_support.test_order`][]オプションで設定できます）。

テストが失敗すると、それに応じたバックトレースが出力されます。Railsはデフォルトでバックトレースをフィルタし、アプリケーションに関連するバックトレースのみを出力します。これによって、フレームワークから発生する不要な情報を排除して作成中のコードに集中できます。完全なバックトレースを参照しなければならない場合は、`-b`（または`--backtrace`）オプションを追加することでこの振る舞いを変更できます。

```bash
$ bin/rails test -b test/models/article_test.rb
```

このテストがエラーを発生せずにパスするには、`assert_raises`を用いて以下のようにテストを変更します。

```ruby
test "should report error" do
  # このsome_undefined_variableはテストケースのどこにも定義されていない
  assert_raises(NameError) do
    some_undefined_variable
  end
end
```

これでテストはパスするはずです。

[`config.active_support.test_order`]:
  configuring.html#config-active-support-test-order

### minitestのアサーション

ここまでにいくつかのアサーションを紹介しました。アサーションは、テストの中心を担う重要な存在です。システムが計画通りに動作していることを実際に確認しているのはアサーションです。

以下は、Railsにデフォルトで組み込まれているテスティングライブラリである[`minitest`](https://github.com/minitest/minitest)で使えるアサーションの抜粋です。
なお、`[msg]`パラメータは1個のオプション文字列メッセージであり、テストが失敗したときのメッセージをわかりやすくしたいときに指定できます。

<!-- PDFの表示崩れを防ぐため、ここは表形式にしない -->

#### `assert( test, [msg] )`

* `test`はtrueであると主張する。

#### `assert_not( test, [msg] )`

* `test`はfalseであると主張する。

#### `assert_equal( expected, actual, [msg] )`

* `expected == actual`はtrueであると主張する。

#### `assert_not_equal( expected, actual, [msg] )`

* `expected != actual`はtrueであると主張する。

#### `assert_same( expected, actual, [msg] )`

* `expected.equal?(actual)`はtrueであると主張する。

#### `assert_not_same( expected, actual, [msg] )`

* `expected.equal?(actual)`はfalseであると主張する。

#### `assert_nil( obj, [msg] )`

* `obj.nil?`はtrueであると主張する。

#### `assert_not_nil( obj, [msg] )`

* `obj.nil?`はfalseであると主張する。

#### `assert_empty( obj, [msg] )`

* `obj`は`empty?`であると主張する。

#### `assert_not_empty( obj, [msg] )`

* `obj`は`empty?`ではないと主張する。

#### `assert_match( regexp, string, [msg] )`

* stringは正規表現（regexp）にマッチすると主張する。

#### `assert_no_match( regexp, string, [msg] )`

* stringは正規表現（regexp）にマッチしないと主張する。

#### `assert_includes( collection, obj, [msg] )`

* `obj`は`collection`に含まれると主張する。

#### `assert_not_includes( collection, obj, [msg] )`

* `obj`は`collection`に含まれないと主張する。

#### `assert_in_delta( expected, actual, [delta], [msg] )`

* `expected`と`actual`の個数の差は`delta`以内であると主張する。

#### `assert_not_in_delta( expected, actual, [delta], [msg] )`

* `expected`と`actual`の個数の差は`delta`以内にはないと主張する。

#### `assert_in_epsilon ( expected, actual, [epsilon], [msg] )`

* `expected`と`actual`の個数の差が`epsilon`より小さいと主張する。

#### `assert_not_in_epsilon ( expected, actual, [epsilon], [msg] )`

* `expected`と`actual`の数値には`epsilon`より小さい相対誤差がないと主張する。

#### `assert_throws( symbol, [msg] ) { block }`

* 与えられたブロックはシンボルをスローすると主張する。

#### `assert_raises( exception1, exception2, ... ) { block }`

* 渡されたブロックから、渡された例外のいずれかが発生すると主張する。

#### `assert_instance_of( class, obj, [msg] )`

* `obj`は`class`のインスタンスであると主張する。

#### `assert_not_instance_of( class, obj, [msg] )`

* `obj`は`class`のインスタンスではないと主張する。

#### `assert_kind_of( class, obj, [msg] )`

* `obj`は`class`またはそのサブクラスのインスタンスであると主張する。

#### `assert_not_kind_of( class, obj, [msg] )`

* `obj`は`class`またはそのサブクラスのインスタンスではないと主張する。

#### `assert_respond_to( obj, symbol, [msg] )`

* `obj`は`symbol`に応答すると主張する。

#### `assert_not_respond_to( obj, symbol, [msg] )`

* `obj`は`symbol`に応答しないと主張する。

#### `assert_operator( obj1, operator, [obj2], [msg] )`

* `obj1.operator(obj2)`はtrueであると主張する。

#### `assert_not_operator( obj1, operator, [obj2], [msg] )`

* `obj1.operator(obj2)`はfalseであると主張する。

#### `assert_predicate ( obj, predicate, [msg] )`

* `obj.predicate`はtrueであると主張する（例:`assert_predicate str, :empty?`）。

#### `assert_not_predicate ( obj, predicate, [msg] )`

* `obj.predicate`はfalseであると主張する（例:`assert_not_predicate str, :empty?`）。

#### `assert_error_reported(class) { block }`

* 指定のエラークラスがブロック内で報告されたことを主張する（例: `assert_error_reported IOError { Rails.error.report(IOError.new("Oops")) }`）。

#### `assert_no_error_reported { block }`

* ブロック内でエラーが報告されないことを主張する（例: `assert_no_error_reported { perform_service }`）

#### `flunk( [msg] )`

* 必ず失敗すると主張する。これはテストが未完成であることを示すのに便利。

---------

これらはminitestがサポートするアサーションの一部に過ぎません。最新の完全なアサーションのリストについては[minitest APIドキュメント](https://docs.seattlerb.org/minitest/)、特に[`Minitest::Assertions`](https://docs.seattlerb.org/minitest/Minitest/Assertions.html)を参照してください。

独自のアサーションを自作して利用することもできます。実際、Railsはまさにそれを行っているのです。Railsには開発を楽にしてくれる特殊なアサーションがいくつも追加されています。

NOTE: アサーションの自作は高度なトピックなので、本ガイドでは扱いません。

### Rails固有のアサーション

Railsは`minitest`フレームワークに以下のような独自のカスタムアサーションを追加しています。

<!-- 製版の都合上ここはリスト形式とする -->

#### [`assert_difference(expressions, difference = 1, message = nil)`][assert_difference]

* `yield`されたブロックで評価された結果である式の戻り値における数値の違いをテストする。

#### [`assert_no_difference(expressions, message = nil, &block)`][assert_no_difference]

* 式を評価した結果の数値は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがないと主張する。

#### [`assert_changes(expressions, message = nil, from:, to:, &block)`][assert_changes]

* 式を評価した結果は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがあると主張する。

#### [`assert_no_changes(expressions, message = nil, &block)`][assert_no_changes]

* 式を評価した結果は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがないと主張する。

#### [`assert_nothing_raised { block }`][assert_nothing_raised]

* 渡されたブロックで例外が発生しないことを確認する。

#### [`assert_recognizes(expected_options, path, extras = {}, message = nil)`][assert_recognizes]

* 渡されたパスのルーティングが正しく扱われ、（`expected_options`ハッシュで渡された（解析オプションがパスと一致したことを主張する。
  基本的にこのアサーションでは、Railsが`expected_options`で渡されたルーティングを認識していると主張する。

#### [`assert_generates(expected_path, options, defaults = {}, extras = {}, message = nil)`][assert_generates]

* 渡されたオプションは、渡されたパスの生成に使えるものであると主張する（`assert_recognizes`と逆の動作）。
  `extras`パラメータは、クエリ文字列に追加リクエストがある場合にそのパラメータの名前と値をリクエストに渡すのに使われる。
  `message`パラメータにはアサーションが失敗した場合のカスタムエラーメッセージを渡せる。

#### [`assert_routing(expected_path, options, defaults = {}, extras = {}, message = nil)`][assert_routing]

* `path`と`options`が両方向に一致すると主張する。
  つまり、`path`が`options`を生成し、次に`options`が`path`を生成することを検証する。
  これは基本的に`assert_recognizes`と`assert_generates`を1ステップに組み合わせたものである。
  `extras`ハッシュを渡すと、アクションにクエリ文字列として提供されるオプションを指定できる。
  `message`パラメータを渡すと、失敗時に表示するカスタムエラーメッセージを指定できる。

#### [`assert_response(type, message = nil)`][assert_response]

* レスポンスが特定のステータスコードを持っていることを主張する。
  `:success`を指定するとステータスコード200〜299を指定したことになり、同様に`:redirect`は300〜399、`:missing`は404、`:error`は500〜599にそれぞれマッチする。
  ステータスコードの数字や同等のシンボルを直接渡すこともできる。
  詳しくは[ステータスコードの完全なリスト](https://rubydoc.info/github/rack/rack/master/Rack/Utils#HTTP_STATUS_CODES-constant)および[シンボルとステータスコードの対応リスト](https://rubydoc.info/github/rack/rack/master/Rack/Utils#SYMBOL_TO_STATUS_CODE-constant)を参照。

#### [`assert_redirected_to(options = {}, message = nil)`][assert_redirected_to]

* 渡されたリダイレクトオプションが、最後に実行されたアクションで呼び出されたリダイレクトのオプションと一致することを主張する。
  `assert_redirected_to root_path`などの名前付きルートを渡すことも、`assert_redirected_to @article`などのActive Recordオブジェクトを渡すことも可能。

#### [`assert_queries_count(count = nil, include_schema: false, &block)`][assert_queries_count]

* `&block`がSQLクエリの`int`数値を生成することを主張する。

#### [`assert_no_queries(include_schema: false, &block)`][assert_no_queries]

* `&block`がSQLクエリを生成しないことを主張する。

#### [`assert_queries_match(pattern, count: nil, include_schema: false, &block)`][assert_queries_match]

* `&block`が指定のパターンにマッチするSQLクエリを生成することを主張する。

#### [`assert_no_queries_match(pattern, &block)`][assert_no_queries_match]

* `&block`が指定のパターンにマッチするSQLクエリを生成しないことを主張する。

[assert_difference]:
  https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_difference
[assert_no_difference]:
  https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_difference
[assert_changes]:
  https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_changes
[assert_no_changes]:
  https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_changes
[assert_nothing_raised]:
  https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_nothing_raised
[assert_recognizes]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_recognizes
[assert_generates]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_generates
[assert_routing]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_routing
[assert_response]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_response
[assert_redirected_to]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_redirected_to
[assert_queries_count]:
  https://api.rubyonrails.org/classes/ActiveRecord/Assertions/QueryAssertions.html#method-i-assert_queries_count
[assert_no_queries]:
  https://api.rubyonrails.org/classes/ActiveRecord/Assertions/QueryAssertions.html#method-i-assert_no_queries
[assert_queries_match]:
  https://api.rubyonrails.org/classes/ActiveRecord/Assertions/QueryAssertions.html#method-i-assert_queries_match
[assert_no_queries_match]:
  https://api.rubyonrails.org/classes/ActiveRecord/Assertions/QueryAssertions.html#method-i-assert_no_queries_match

これらのアサーションのいくつかについては次の章で説明します。

### テストケースのアサーション

`Minitest::Assertions`に定義されている`assert_equal`などの基本的なアサーションは、あらゆるテストケース内で用いられているクラスで利用できます。実際には、以下から継承したクラスもRailsで利用できます。

* [`ActiveSupport::TestCase`][]
* [`ActionMailer::TestCase`][]
* [`ActionView::TestCase`][]
* [`ActiveJob::TestCase`][]
* [`ActionDispatch::Integration::Session`][]
* [`ActionDispatch::SystemTestCase`][]
* [`Rails::Generators::TestCase`][]

各クラスには`Minitest::Assertions`が含まれているので、どのテストでも基本的なアサーションを利用できます。

NOTE: `minitest`について詳しくは、[minitestのドキュメント](https://docs.seattlerb.org/minitest)を参照してください。

[`ActiveSupport::TestCase`]:
  https://api.rubyonrails.org/classes/ActiveSupport/TestCase.html
[`ActionMailer::TestCase`]:
  https://api.rubyonrails.org/classes/ActionMailer/TestCase.html
[`ActionView::TestCase`]:
  https://api.rubyonrails.org/classes/ActionView/TestCase.html
[`ActiveJob::TestCase`]:
  https://api.rubyonrails.org/classes/ActiveJob/TestCase.html
[`ActionDispatch::Integration::Session`]:
  https://api.rubyonrails.org/classes/ActionDispatch/IntegrationTest.html
[`ActionDispatch::SystemTestCase`]:
  https://api.rubyonrails.org/classes/ActionDispatch/SystemTestCase.html
[`Rails::Generators::TestCase`]:
  https://api.rubyonrails.org/classes/Rails/Generators/TestCase.html

### Railsのテストランナー

`bin/rails test`コマンドを使ってすべてのテストを一括実行できます。

個別のテストファイルを実行するには、`bin/rails test`コマンドにそのテストケースを含むファイル名を渡します。

```bash
$ bin/rails test test/models/article_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 1559

# Running:

..

Finished in 0.027034s, 73.9810 runs/s, 110.9715 assertions/s.

2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

上を実行すると、そのテストケースに含まれるメソッドがすべて実行されます。

あるテストケースの特定のテストメソッドだけを実行するには、`-n`（または`--name`）フラグでテストのメソッド名を指定します。

```bash
$ bin/rails test test/models/article_test.rb -n test_the_truth
Running 1 tests in a single process (parallelization threshold is 50)
Run options: -n test_the_truth --seed 43583

# Running:

.

Finished tests in 0.009064s, 110.3266 tests/s, 110.3266 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
```

行番号を指定すると、特定の行だけをテストできます。


```bash
$ bin/rails test test/models/article_test.rb:6 # 特定のテストの特定行のみをテスト
```

行を範囲指定することで、特定の範囲のテストを実行することも可能です。

```bash
$ bin/rails test test/models/article_test.rb:6-20 # 6行目から20行目までテストを実行
```

ディレクトリを指定すると、そのディレクトリ内のすべてのテストを実行できます。

```bash
$ bin/rails test test/controllers # 指定ディレクトリのテストをすべて実行
```

テストランナーではこの他にも、「failing fast」やテスト終了時に必ずテストを出力するといったさまざまな機能が使えます。次を実行してテストランナーのドキュメントをチェックしてみましょう。

```bash
$ bin/rails test -h
Usage:
  bin/rails test [PATHS...]

Run tests except system tests

Examples:
    You can run a single test by appending a line number to a filename:

        bin/rails test test/models/user_test.rb:27

    You can run multiple tests with in a line range by appending the line range to a filename:

        bin/rails test test/models/user_test.rb:10-20

    You can run multiple files and directories at the same time:

        bin/rails test test/controllers test/integration/login_test.rb

    By default test failures and errors are reported inline during a run.

minitest options:
    -h, --help                       Display this help.
        --no-plugins                 Bypass minitest plugin auto-loading (or set $MT_NO_PLUGINS).
    -s, --seed SEED                  Sets random seed. Also via env. Eg: SEED=n rake
    -v, --verbose                    Verbose. Show progress processing files.
        --show-skips                 Show skipped at the end of run.
    -n, --name PATTERN               Filter run on /regexp/ or string.
        --exclude PATTERN            Exclude /regexp/ or string from run.
    -S, --skip CODES                 Skip reporting of certain types of results (eg E).

Known extensions: rails, pride
    -w, --warnings                   Run with Ruby warnings enabled
    -e, --environment ENV            Run tests in the ENV environment
    -b, --backtrace                  Show the complete backtrace
    -d, --defer-output               Output test failures and errors after the test run
    -f, --fail-fast                  Abort test run on first failure or error
    -c, --[no-]color                 Enable color in the output
        --profile [COUNT]            Enable profiling of tests and list the slowest test cases (default: 10)
    -p, --pride                      Pride. Show your testing pride!
```

テスト用データベース
-----------------------

Railsアプリケーションのほとんどは、データベースと密接なやりとりを行うので、テストでもデータベースが必要となります。このセクションでは、このテストデータベースをセットアップしてサンプルデータを入力する方法について解説します。

[test環境](#test環境)セクションで説明したように、すべてのRailsアプリケーションにはdevelopment環境、test環境、production環境の3つの環境があります。それぞれの環境におけるデータベース設定は`config/database.yml`で行います。

テスティング専用のデータベースを用いることで、他の環境から切り離された専用のテストデータをセットアップしてアクセスできるようになります。これにより、development環境やproduction環境のデータベースにあるデータを気にすることなく、確実にテストを実行できます。

### テストデータベースのスキーマを管理する

テストを実行するには、テスト用データベースで最新のスキーマが必要です。

テストヘルパーは、テストデータベースに未完了のマイグレーションが残っていないかどうかをチェックします。マイグレーションがすべて終わっている場合、`db/schema.rb`や`db/structure.sql`をテストデータベースに読み込みます。ペンディングされたマイグレーションがある場合、エラーが発生します。

このエラーが発生するということは、スキーマのマイグレーションが不完全であることを意味します。`bin/rails db:migrate RAILS_ENV=test`コマンドでテスト用データベースのマイグレーションを実行することで、スキーマが最新の状態になります。

NOTE: 既存のマイグレーションに変更が加えられていると、テストデータベースを再構築する必要があります。`bin/rails test:db`を実行することで再構築できます。

### フィクスチャ

よいテストを作成するにはよいテストデータを準備する必要があることを理解しておく必要があります。
Railsでは、フィクスチャを使ってテストデータの定義やカスタマイズを行えます。
網羅的なドキュメントについては、[フィクスチャAPIドキュメント][`FixtureSet`]を参照してください。

[`FixtureSet`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

#### フィクスチャとは何か

**フィクスチャ（fixture）**とは、一貫したデータセットを表す専門用語です。フィクスチャを使うことで、事前に定義したデータをテスト実行直前にtestデータベースに導入できます。フィクスチャはYAMLで記述するので、特定のデータベースに依存しません。1つのモデルにつき1つのフィクスチャファイルが作成されます。

NOTE: フィクスチャは、テストで必要なあらゆるオブジェクトを作成できるように設計されているわけではありません。一般的なテストケースに適用可能なデフォルトデータのみを用いるようにすることで、フィクスチャを最も効果的に管理できます。

フィクスチャファイルは`test/fixtures/`ディレクトリの下に置かれます。

#### YAML

YAML形式のフィクスチャは人間にとってとても読みやすく、サンプルデータを容易に記述できます。この形式のフィクスチャには**.yml**というファイル拡張子が与えられます（`users.yml`など）。

YAMLフィクスチャファイルのサンプルを以下に示します。

```yaml
# この行はYAMLのコメントである
david:
  name: David Heinemeier Hansson
  birthday: 1979-10-15
  profession: Systems development

steve:
  name: Steve Ross Kellock
  birthday: 1974-09-27
  profession: guy with keyboard
```

- 各フィクスチャはフィクスチャ名とコロンで始まり、その下にインデントを追加して、コロン区切りのキーバリューペアのリストを配置します。
- 通常、レコード間は空行で区切ります。
- 行の先頭に`#`文字を置くことで、フィクスチャファイルにコメントを追加できます。

[関連付け](/association_basics.html)を使っている場合は、2つの異なるフィクスチャの間に参照ノードを定義できます。`belongs_to`と`has_many`関連付けの例を以下に示します。

```yaml
# test/fixtures/categories.yml
web_frameworks:
  name: Web Frameworks
```

```yaml
# test/fixtures/articles.yml
first:
  title: Welcome to Rails!
  category: web_frameworks
```

```yaml
# test/fixtures/action_text/rich_texts.yml
first_content:
  record: first (Article)
  name: content
  body: <div>Hello, from <strong>a fixture</strong></div>
```

`fixtures/articles.yml`にある記事`first`の`category`キーの値が`about`になり、`fixtures/action_text/rich_texts.yml`にある`first_content`エントリの`record`キーの値が`first (Article)`になっている点にもご注目ください。
これは、前者についてはActive Recordが`fixtures/categories.yml`にあるカテゴリ`about`を読み込むように、後者についてはAction Textが`fixtures/articles.yml`にある記事`first`を読み込むように指示しています。

NOTE: 関連付けを名前で相互参照するには、関連付けられたフィクスチャにある`id:`属性を指定する代わりに、フィクスチャ名を使えます。Railsはテストの実行中に、自動的に主キーを割り当てて一貫性を保ちます。関連付けの場合の振る舞いについて詳しくは、[フィクスチャAPIドキュメント](https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)を参照してください。

#### ファイル添付のフィクスチャ

Active Storageの添付ファイルレコードは`ActiveRecord::Base`インスタンスを継承しているので、Active Recordの他のモデルと同様にフィクスチャで設定できます。

`thumbnail`添付画像に関連付けられている`Article`モデルのフィクスチャデータYAMLを考えてみましょう。

```ruby
class Article < ApplicationRecord
  has_one_attached :thumbnail
end
```

```yaml
# test/fixtures/articles.yml
first:
  title: An Article
```

[`image/png`]エンコードされたファイルが`test/fixtures/files/first.png`に置かれているとすると、以下のYAMLフィクスチャエントリは、関連する`ActiveStorage::Blob`と`ActiveStorage::Attachment`レコードを生成します。

```yaml
# test/fixtures/active_storage/blobs.yml
first_thumbnail_blob: <%= ActiveStorage::FixtureSet.blob filename: "first.png" %>
```

```yaml
# test/fixtures/active_storage/attachments.yml
first_thumbnail_attachment:
  name: thumbnail
  record: first (Article)
  blob: first_thumbnail_blob
```

[`image/png`]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Basics_of_HTTP/MIME_types#画像タイプ

#### ERBでフィクスチャにコードを埋め込む

ERBは、テンプレート内にRubyコードを埋め込むのに使われます。YAMLフィクスチャ形式のファイルは、Railsに読み込まれたときにERBによる事前処理が行われます。ERBを活用すれば、Rubyコードでサンプルデータを生成できます。たとえば、以下のコードを使えば1000人のユーザーを生成できます。

```erb
<% 1000.times do |n| %>
  user_<%= n %>:
    username: <%= "user#{n}" %>
    email: <%= "user#{n}@example.com" %>
<% end %>
```

#### フィクスチャの動作

Railsはデフォルトで、`test/fixtures`フォルダにあるすべてのフィクスチャを自動的に読み込みます。フィクスチャの読み込みは主に以下の3つの手順で行われます。

1. フィクスチャに対応するテーブルに含まれている既存のデータをすべて削除する
2. フィクスチャのデータをテーブルに読み込む
3. フィクスチャに直接アクセスしたい場合はフィクスチャのデータをメソッドにダンプする

TIP: Railsでは、データベースから既存のデータベースを削除するために外部キーやチェック制約といった参照整合性（referential integrity）トリガーを無効にしようとします。テスト実行時のパーミッションエラーが発生して困っている場合は、test環境のデータベースユーザーがこれらのトリガーを無効にする特権を持っていることを確認してください（PostgreSQLの場合、すべてのトリガーを無効にできるのはsuperuserのみです。PostgreSQLのパーミッションについて詳しくは[こちらの記事](https://www.postgresql.jp/document/current/html/sql-altertable.html)を参照してください）。

#### フィクスチャはActive Recordオブジェクトである

フィクスチャは、実はActive Recordのインスタンスです。前述の手順3にもあるように、フィクスチャはスコープがテストケースのローカルになっているメソッドを自動的に利用可能にしてくれるので、フィクスチャのオブジェクトに直接アクセスできます。以下に例を示します。

```ruby
# davidという名前のフィクスチャに対応するUserオブジェクトを返す
users(:david)

# idで呼び出されたdavidのプロパティを返す
users(:david).id

# Userクラスで利用可能なメソッドにアクセスすることもできる
david = users(:david)
david.call(david.partner)
```

複数のフィクスチャを一括で取得するには、次のようにフィクスチャ名をリストで渡します。

```ruby
# davidとsteveというフィクスチャを含む配列を返す
users(:david, :steve)
```

### トランザクション

デフォルトのRailsは、テストをデータベーストランザクションに自動的にラップし、テスト完了後にロールバックします。これにより、テストは互いに独立し、データベースへの変更は1つのテスト内でのみ観測されるようになります。

```ruby
class MyTest < ActiveSupport::TestCase
  test "newly created users are active by default" do
    # このテストは暗黙でデータベーストランザクションにラップされるので、
    # ここで作成したユーザーは他のテストからは見えない
    assert User.create.active?
  end
end
```

ただし、[`ActiveRecord::Base.current_transaction`][]は引き続き意図したとおりに動作します。

```ruby
class MyTest < ActiveSupport::TestCase
  test "current_transaction" do
    # テストを暗黙のトランザクションが囲んでいても、
    # current_transactionのアプリケーションレベルの意味論に影響しない
    assert User.current_transaction.blank?
  end
end
```

[複数の書き込みデータベース](active_record_multiple_databases.html)が存在する場合、テストはそれらに対応する多数のトランザクションにラップされ、すべてがロールバックします。

[`ActiveRecord::Base.current_transaction`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-current_transaction

#### テストのトランザクションをオプトアウトする

以下のようにすることで、個別のテストケースでトランザクションを無効にできます。

```ruby
class MyTest < ActiveSupport::TestCase
  # このテストケースではテストをデータベーストランザクションで暗黙にラップしなくなる
  self.use_transactional_tests = false
end
```

モデルのテスト
-------------

モデルのテストは、アプリケーションのモデルとそれに関連するロジックをテストするときに使います。このロジックは、前述のセクションで説明したアサーションとフィクスチャでテストできます。

Railsのモデルのテストは、`test/models/`ディレクトリに保存します。 Railsには、モデルテストのスケルトンを作成するためのジェネレータも用意されています。

```bash
$ bin/rails generate test_unit:model article
create  test/models/article_test.rb
```

上のコマンドを実行すると、以下のスケルトンファイルが生成されます。

```ruby
# article_test.rb
require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
```

モデルのテストには、`ActionMailer::TestCase`のような独自のスーパークラスはありません。代わりに、[`ActiveSupport::TestCase`][]を継承します。

コントローラの機能テスト
-------------------------------------

**機能テスト**（functional test）を作成するときは、コントローラのアクションがリクエストと期待される結果（レスポンス）をどのように処理するかをテストすることに重点を置きます。
コントローラの機能テストは、システムテストが適していない場合（APIのレスポンスを確認する場合など）に使われることがあります。

### 機能テストに含める項目

機能テストでは以下のような項目をテストします。

* Webリクエストが成功したか
* ユーザーが正しいページにリダイレクトされたか
* ユーザー認証が成功したか
* レスポンスのテンプレートに正しいオブジェクトが保存されたか

機能テストの振る舞いを最も手軽に見る方法は、scaffoldジェネレータでコントローラを生成することです。

```bash
$ bin/rails generate scaffold_controller article
...
create  app/controllers/articles_controller.rb
...
invoke  test_unit
create    test/controllers/articles_controller_test.rb
...
```

これによって`Article`リソースのコントローラコードとテストが生成されるので、`test/controllers`にある`articles_controller_test.rb`ファイルを開いてテストコードを見ることができます。

既にコントローラがあり、デフォルトの7つのアクションに対応するテストコードだけをscaffoldで生成したい場合は、以下のコマンドを実行します。

```bash
$ bin/rails generate test_unit:scaffold article
...
invoke  test_unit
create    test/controllers/articles_controller_test.rb
...
```

NOTE: テストコードをscaffoldで生成すると、`@article`値が設定されて、テストファイル全体で使われるようになります。この`article`のインスタンスは、`test/fixtures/articles.yml`ファイルの`:one`キーでネステッド属性を使います。テストを実行する前に、このフィクスチャファイルでこのキーと関連する値が設定されていることを確認してください。

`articles_controller_test.rb`ファイルの`test_should_get_index`というテストについて見てみましょう。

```ruby
# articles_controller_test.rb
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url
    assert_response :success
  end
end
```

`test_should_get_index`というテストでは、`index`という名前のアクションに対するリクエストをシミュレートします。同時に、有効な`articles`インスタンス変数がコントローラに割り当てられます。

`get`メソッドはWebリクエストを開始し、結果を`@response`として返します。このメソッドには以下の6つの引数を渡せます。

* リクエストするコントローラアクションのURI。
  これは文字列ヘルパーかルーティングヘルパーの形を取る（`articles_url`など）。
* `params`: アクションに渡すリクエストパラメータのハッシュ（クエリの文字列パラメータまたはarticle変数など）。
* `headers`: リクエストで渡されるヘッダーの設定に用いる。
* `env`: リクエストの環境を必要に応じてカスタマイズするのに用いる。
* `xhr`: リクエストがAjaxかどうかを指定する。
  Ajaxの場合は`true`を設定。
* `as`: 別のContent-Typeでエンコードされているリクエストに用いる。
  デフォルトで`:json`をサポート。

上のキーワード引数はすべてオプションです。

例: 1件目の`Article`で`:show`アクションを呼び出し、`HTTP_REFERER`ヘッダを設定する。

```ruby
get article_url(Article.first), headers: { "HTTP_REFERER" => "http://example.com/home" }
```

別の例: 最後の`Article`で`:update`アクションをAjaxリクエストとして呼び出し、`params`の`title`に新しいテキストを渡す。

```ruby
patch article_url(Article.last), params: { article: { title: "updated" } }, xhr: true
```

さらに別の例: `:create`アクションを呼び出して新規記事を1件作成し、タイトルに使うテキストをJSONリクエストとしてparamsに渡す。

```ruby
post articles_path, params: { article: { title: "Ahoy!" } }, as: :json
```

NOTE: `articles_controller_test.rb`ファイルにある`test_should_create_article`テストを実行してみると、モデルレベルのバリデーションが新たに追加されることによってテストは失敗します。

`articles_controller_test.rb`ファイルの`test_should_create_article`テストを変更して、テストがパスするようにしてみましょう。

```ruby
test "should create article" do
  assert_difference("Article.count") do
    post articles_url, params: { article: { body: "Rails is awesome!", title: "Hello Rails" } }
  end

  assert_redirected_to article_path(Article.last)
end
```

これで、すべてのテストを実行するとパスするようになったはずです。

NOTE: [BASIC認証](getting_started.html#認証機能を追加する)セクションの手順に沿う場合は、すべてのテストをパスさせるためにテストの`setup`ブロックに以下を追加する必要があります。

```ruby
post articles_url, params: { article: { body: "Rails is awesome!", title: "Hello Rails" } }, headers: { Authorization: ActionController::HttpAuthentication::Basic.encode_credentials("dhh", "secret") }
```

### 機能テストで利用できるHTTPリクエストの種類

HTTPリクエストに精通していれば、`get`がHTTPリクエストの一種であることも既に理解していることでしょう。Railsの機能テストでは以下の6種類のHTTPリクエストがサポートされています。

* `get`
* `post`
* `patch`
* `put`
* `head`
* `delete`

これらはすべてメソッドとして利用できます。典型的なCRUDアプリケーションでよく使われるのは`get`、`post`、`put`、`delete`です。

NOTE: 機能テストでは、そのリクエストがアクションで受け付けられるかどうかを検証せず、代わりに結果を重視します。アクションが受け付けられるかどうかをテストするのであれば、リクエストテストの方が目的に合っています。

### XHR（Ajax）リクエストをテストする

AJAX（Asynchronous JavaScript and XML）リクエストは、非同期HTTPリクエストを用いてサーバーからコンテンツを取得し、ページ全体を読み込まずにページの関連部分だけを更新する手法です。

`get`、`post`、`patch`、`put`、`delete`メソッドで、以下のように`xhr: true`を指定することでAjaxリクエストをテストできます。

```ruby
test "AJAX request" do
  article = articles(:one)
  get article_url(article), xhr: true

  assert_equal "hello world", @response.body
  assert_equal "text/javascript", @response.media_type
end
```

### その他のリクエストオブジェクトをテストする

リクエストが完了して処理されると、以下の3つのハッシュオブジェクトが利用可能になります。

* `cookies`: 設定されているすべてのcookies。
* `flash`: flash内のすべてのオブジェクト。
* `session`: セッション変数に含まれるすべてのオブジェクト。

これらのハッシュは、通常のHashオブジェクトと同様に文字列をキーとして値を参照できます。たとえば以下のようにシンボル名による参照も可能です。

```ruby
flash["gordon"]                # flash[:gordon]も可
session["shmession"]          # session[:shmession]も可
cookies["are_good_for_u"]     # cookies[:are_good_for_u]も可
```

### 利用可能なインスタンス変数

機能テストでは、リクエストが行われた後で以下の3つの専用インスタンス変数を使えるようになります。

* `@controller`: リクエストを処理するコントローラ
* `@request`: リクエストオブジェクト
* `@response`: レスポンスオブジェクト

```ruby
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url

    assert_equal "index", @controller.action_name
    assert_equal "application/x-www-form-urlencoded", @request.media_type
    assert_match "Articles", @response.body
  end
end
```

### HTTPとヘッダーとCGI変数を設定する

HTTPヘッダーは、重要なメタデータを提供するためにHTTPリクエストとともに送信される情報です。

CGI変数は、Webサーバーとアプリケーション間で情報を交換するために使われる環境変数です。

[HTTPヘッダー][HTTPheaders]や[CGI変数][CGIvariables]は、以下のようにヘッダーとして渡すことでテストできるようになります。

```ruby
# HTTPヘッダーを設定する
get articles_url, headers: { "Content-Type": "text/plain" } # カスタムヘッダーでリクエストをシミュレートする

# CGI変数を設定する
get articles_url, headers: { "HTTP_REFERER": "http://example.com/home" } # カスタム環境変数でリクエストをシミュレートする
```

[HTTPheaders]:
  https://datatracker.ietf.org/doc/html/rfc2616#section-5.3
[CGIvariables]:
  https://datatracker.ietf.org/doc/html/rfc3875#section-4.1

### `flash`通知をテストする

[その他のリクエストオブジェクトをテストする](#その他のリクエストオブジェクトをテストする) セクションで説明したように、テストでアクセスできる3つのハッシュ オブジェクトの1つに`flash`があります。本セクションでは、ユーザーが新しい記事の作成に成功するたびに、ブログアプリケーションで`flash`メッセージが表示されるかどうかをテストする方法について説明します。

まず、`test_should_create_article`テストにアサーションを追加する必要があります。

```ruby
test "should create article" do
  assert_difference("Article.count") do
    post articles_url, params: { article: { title: "Some title" } }
  end

  assert_redirected_to article_path(Article.last)
  assert_equal "Article was successfully created.", flash[:notice]
end
```

この時点でテストを実行すると、以下のように失敗するはずです。

```bash
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Running 1 tests in a single process (parallelization threshold is 50)
Run options: -n test_should_create_article --seed 32266

# Running:

F

Finished in 0.114870s, 8.7055 runs/s, 34.8220 assertions/s.

  1) Failure:
ArticlesControllerTest#test_should_create_article [/test/controllers/articles_controller_test.rb:16]:
--- expected
+++ actual
@@ -1 +1 @@
-"Article was successfully created."
+nil

1 runs, 4 assertions, 1 failures, 0 errors, 0 skips
```

今度はコントローラにflashメッセージを実装してみましょう。`:create`アクションは次のようになります。

```ruby
def create
  @article = Article.new(article_params)

  if @article.save
    flash[:notice] = "Article was successfully created."
    redirect_to @article
  else
    render "new"
  end
end
```

テストを実行すると、今度はパスするはずです。

```bash
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Running 1 tests in a single process (parallelization threshold is 50)
Run options: -n test_should_create_article --seed 18981

# Running:

.

Finished in 0.081972s, 12.1993 runs/s, 48.7972 assertions/s.

1 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

NOTE: scaffoldジェネレーターでコントローラを生成した場合、flashメッセージは既に`create`アクションに実装されています。

### `show`、`update`、`destroy`アクションをテストする

ここまでは、`:index`アクションと`:create`アクションのテストについて説明しました。その他のアクションについてはどうでしょうか？

`:show`アクションのテストは次のように書けます。

```ruby
test "should show article" do
  article = articles(:one)
  get article_url(article)
  assert_response :success
end
```

前述の[フィクスチャ](#フィクスチャ)で説明したように、`articles()`メソッドを使うと記事のフィクスチャにアクセスできることを思い出しましょう。

既存の記事の削除は次のようにテストします。

```ruby
test "should delete article" do
  article = articles(:one)
  assert_difference("Article.count", -1) do
    delete article_url(article)
  end

  assert_redirected_to articles_path
end
```

既存の記事の更新テストも次のように書けます。

```ruby
test "should update article" do
  article = articles(:one)

  patch article_url(article), params: { article: { title: "updated" } }

  assert_redirected_to article_path(article)
  # 更新されたデータをフェッチするために関連付けをリロードし、タイトルが更新されたというアサーションを行う
  article.reload
  assert_equal "updated", article.title
end
```

これら3つのテストは、どれも同じArticleフィクスチャデータへのアクセスを行っており、少々重複していますので、DRY（Don't Repeat Yourself）に書き換えましょう。これは`ActiveSupport::Callbacks`が提供する`setup`メソッドと`teardown`メソッドで行います。

書き換え後のテストは以下のようになるでしょう。

```ruby
require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  # 各テストの実行前に呼ばれる
  setup do
    @article = articles(:one)
  end

  # 各テストの実行後に呼ばれる
  teardown do
    # コントローラがキャッシュを使っている場合、テスト後にリセットしておくとよい
    Rails.cache.clear
  end

  test "should show article" do
    # セットアップ時の@articleインスタンス変数を再利用
    get article_url(@article)
    assert_response :success
  end

  test "should destroy article" do
    assert_difference("Article.count", -1) do
      delete article_url(@article)
    end

    assert_redirected_to articles_path
  end

  test "should update article" do
    patch article_url(@article), params: { article: { title: "updated" } }

    assert_redirected_to article_path(@article)
    # 更新されたデータをフェッチするために関連付けをリロードし、タイトルが更新されたというアサーションを行う
    @article.reload
    assert_equal "updated", @article.title
  end
end
```

NOTE: `setup`メソッドと`teardown`メソッドでも、Railsの他のコールバックと同様にブロックやlambdaを渡したり、メソッド名のシンボルを渡して呼び出したりできます。

結合テスト
-------------------

**結合テスト**（integration test、統合テストとも）は、[コントローラの機能テスト](#コントローラの機能テスト)をさらに一歩進めたもので、アプリケーションの複数の部分がどのようにやりとりするかをテストすることに重点を置いています。結合テストは、一般にアプリケーション内の重要なワークフローのテストに使われます。

Railsの結合テストは、`test/integration/`ディレクトリに保存されます。

Railsは、以下のような結合テスト用のスケルトンを作成するジェネレータを提供しています。

```bash
$ bin/rails generate integration_test user_flows
      exists  test/integration/
      create  test/integration/user_flows_test.rb
```

生成直後の結合テストは以下のような内容になっています。

```ruby
require "test_helper"

class UserFlowsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
```

結合テストは[`ActionDispatch::IntegrationTest`][]を継承しています。これにより、結合テスト内では標準のテストヘルパー以外にも[さまざまなヘルパー](#結合テストで利用できるヘルパー)を利用できます。

[`ActionDispatch::IntegrationTest`]:
  https://api.rubyonrails.org/classes/ActionDispatch/IntegrationTest.html

### 結合テストで利用できるヘルパー

システムテストでは、標準のテストヘルパー以外にも`ActionDispatch::IntegrationTest`から継承されるいくつかのヘルパーを利用できます。その中から3つのカテゴリについて簡単にご紹介します。

結合テストランナーについては[`ActionDispatch::Integration::Runner`](https://api.rubyonrails.org/classes/ActionDispatch/Integration/Runner.html)を参照してください。

リクエストの実行については[`ActionDispatch::Integration::RequestHelpers`](https://api.rubyonrails.org/classes/ActionDispatch/Integration/RequestHelpers.html)にあるヘルパーを用いることにします。

ファイルをアップロードする必要がある場合は、[`ActionDispatch::TestProcess::FixtureFile`](https://api.rubyonrails.org/classes/ActionDispatch/TestProcess/FixtureFile.html)を参照してください。

セッションを改変する必要がある場合や、結合テストのステートを変更する必要がある場合は、[`ActionDispatch::Integration::Session`](https://api.rubyonrails.org/classes/ActionDispatch/Integration/Session.html)を参照してください。

### 結合テストを実装する

それではブログアプリケーションに結合テストを追加することにしましょう。最初に基本的なワークフローととして新しいブログ記事を1件作成し、すべて問題なく動作することを確認します。

まずは結合テストのスケルトンを生成します。

```bash
$ bin/rails generate integration_test blog_flow
```

上のコマンドを実行するとテストファイルのプレースホルダが作成され、次のように表示されるはずです。

```bash
      invoke  test_unit
      create    test/integration/blog_flow_test.rb
```

それではこのファイルを開いて最初のアサーションを書きましょう。

```ruby
require "test_helper"

class BlogFlowTest < ActionDispatch::IntegrationTest
  test "can see the welcome page" do
    get "/"
    assert_select "h1", "Welcome#index"
  end
end
```

リクエストで生成されるHTMLをテストする`assert_select`についてはこの後の[ビューをテストする](#ビューをテストする)で言及します。これはリクエストに対するレスポンスのテストに用いるもので、重要なHTML要素がコンテンツに存在するというアサーションを行います。

rootパスを表示すると、そのビューで`welcome/index.html.erb`が表示されるはずなので、このアサーションはパスするはずです。

#### 記事の結合テストを作成する

ブログに新しい記事を1件作成して、生成された記事が表示できていることをテストしましょう。

```ruby
test "can create an article" do
  get "/articles/new"
  assert_response :success

  post "/articles",
    params: { article: { title: "can create", body: "article successfully." } }
  assert_response :redirect
  follow_redirect!
  assert_response :success
  assert_select "p", "Title:\n  can create"
end
```

理解のため、このテストを細かく分けてみましょう。

最初に`Articles`コントローラの`:new`アクションを呼びます。このレスポンスは成功するはずです。

次に`Articles`コントローラの`:create`アクションにPOSTリクエストを送信します。

```ruby
post "/articles",
  params: { article: { title: "can create", body: "article successfully." } }
assert_response :redirect
follow_redirect!
```

その次の2行では、記事が1件作成されるときのリクエストのリダイレクトを扱います。

NOTE: リダイレクト実行後に続いて別のリクエストを行う予定がある場合は、`follow_redirect!`を必ず呼び出してください。

最後は、レスポンスが成功して記事がページ上で読める状態になっているというアサーションです。

#### 結合テストの利用法

ブログを表示して記事を1件作成するという、きわめて小規模なワークフローを無事テストできました。このテストにコメントを追加することも、記事の削除や編集のテストを行うこともできます。結合テストは、アプリケーションのあらゆるユースケースに伴うエクスペリエンスのテストに向いています。

システムテスト
--------------

システムテストはアプリケーションのユーザー操作のテストに使えます。テストは、実際のブラウザまたはヘッドレスブラウザに対して実行されます。システムテストではそのために背後でCapybaraを使います。

アプリケーションの`test/system`ディレクトリは、Railsのシステムテストを作成するために使います。Railsではシステムテストのスケルトンを生成するジェネレータが提供されています。

```bash
$ bin/rails generate system_test users
      invoke test_unit
      create test/system/users_test.rb
```

生成直後のシステムテストは次のようになっています。

```ruby
require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  # test "visiting the index" do
  #   visit users_url
  #
  #   assert_selector "h1", text: "Users"
  # end
end
```

システムテストでは、デフォルトでSeleniumドライバと画面サイズ1400x1400のChromeブラウザを用いて実行されます。次のセクションで、デフォルト設定の変更方法について説明します。

### デフォルト設定を変更する

Railsのシステムテストでは、デフォルト設定を非常にシンプルな方法で変更できます。すべての設定が抽象化されているので、テストの作成に集中できます。

新しいアプリケーションやscaffoldを生成すると、`test/`ディレクトリに`application_system_test_case.rb`ファイルが作成されます。システムテストの設定はすべてここで行います。

デフォルト設定を変更したい場合は、システムテストの`driven_by`項目を変更できます。たとえばドライバをSeleniumからCupriteに変更する場合は、まず[`cuprite`](https://github.com/rubycdp/cuprite) gemをGemfileに追加して`bundle install`を実行し、次に`application_system_test_case.rb`を以下のように変更します。

```ruby
require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite
end
```

このドライバ名は`driven_by`の必須引数です。`driven_by`には、他に以下のオプション引数も渡せます。

- `:using`: ブラウザを指定する（Seleniumでのみ有効）
- `:screen_size`: スクリーンショットのサイズを変更する
- `:options`: ドライバでサポートされるオプションを指定する

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :firefox
end
```

ヘッドレスブラウザを使いたい場合は、以下のように`:using`引数に`headless_chrome`または`headless_firefox`を渡すことで、ヘッドレスChromeやヘッドレスFirefoxを利用できます。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome
end
```

[DockerのヘッドレスChrome][docker-selenium]などのリモートブラウザを使いたい場合は、以下のように`options`で`browser`にリモート`url`を追加する必要があります。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  url = ENV.fetch("SELENIUM_REMOTE_URL", nil)
  options = if url
    { browser: :remote, url: url }
  else
    { browser: :chrome }
  end
  driven_by :selenium, using: :headless_chrome, options: options
end
```

これで、以下を実行すればリモートブラウザに接続されるはずです。

```bash
$ SELENIUM_REMOTE_URL=http://localhost:4444/wd/hub bin/rails test:system
```

テスト対象のアプリケーションがリモートでも動作している場合（Dockerコンテナなど）は、[リモートサーバーの呼び出し方法][call-remote-servers]に関する追加情報もCapybaraに渡す必要があります。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  def setup
    Capybara.server_host = "0.0.0.0" # すべてのインターフェイスにバインドする
    Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}" if ENV["SELENIUM_REMOTE_URL"].present?
    super
  end
  # ...
end
```

これで、DockerコンテナとCIのどちらで動作していても、リモートブラウザとサーバに接続できるようになります。

Railsで提供されていないCapybara設定が必要な場合は、`application_system_test_case.rb`ファイルに設定を追加できます。

追加設定については[Capybaraのドキュメント][capybara#setup]を参照してください。

[docker-selenium]:
  https://github.com/SeleniumHQ/docker-selenium
[call-remote-servers]:
  https://github.com/teamcapybara/capybara#calling-remote-servers
[capybara#setup]:
  https://github.com/teamcapybara/capybara#setup

### システムテストを実装する

それではアプリケーションにシステムテストを追加することにしましょう。システムテストで最初にindexページを表示し、新しいブログ記事を1件作成します。

scaffoldジェネレータを使った場合はシステムテストのスケルトンが自動で作成されています。scaffoldジェネレータを使わなかった場合はシステムテストのスケルトンを自分で作成しておきましょう。

```bash
$ bin/rails generate system_test articles
```

上のコマンドを実行するとテストファイルのプレースホルダが作成され、次のように表示されるはずです。

```bash
      invoke  test_unit
      create    test/system/articles_test.rb
```

それではこのファイルを開いて最初のアサーションを書きましょう。

```ruby
require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  test "viewing the index" do
    visit articles_path
    assert_selector "h1", text: "Articles"
  end
end
```

このテストは記事のindexページに`h1`要素が存在していればパスします。

システムテストを実行します。

```bash
bin/rails test:system
```

NOTE: デフォルトでは`bin/rails test`を実行してもシステムテストは実行されません。実際にシステムテストを実行するには`bin/rails test:system`を実行してください。

#### 記事のシステムテストを作成する

それでは、新しい記事を作成するフローをテストしましょう。

```ruby
test "should create Article" do
  visit articles_path

  click_on "New Article"

  fill_in "Title", with: "Creating an Article"
  fill_in "Body", with: "Created this article successfully!"

  click_on "Create Article"

  assert_text "Creating an Article"
end
```

最初の手順では`visit articles_path`を呼び出し、記事のindexページの表示をテストします。

続いて`click_on "New Article"`でindexページの「New Article」ボタンを検索します。するとブラウザが`/articles/new`にリダイレクトされます。

次に記事のタイトルと本文に指定のテキストを入力します。フィールドへの入力が終わったら「Create Article」をクリックして、データベースに新しい記事を作成するPOSTリクエストを`/articles/create`に送信します。

そして記事の元のindexページにリダイレクトされ、新しい記事のタイトルがその記事のindexページに表示されます。

#### さまざまな画面サイズでテストする

デスクトップのテストに加えてモバイルのサイズもテストしたい場合は、`ActionDispatch::SystemTestCase` から継承する別のクラスを作成し、テスト スイートで使用できます。この例では、`mobile_system_test_case.rb` というファイルが次の構成で `/test` ディレクトリに作成されます。

```ruby
require "test_helper"

class MobileSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [375, 667]
end
```

この設定を使うには、`test/system`ディレクトリの下に`MobileSystemTestCase`を継承したテストを作成します。
これで、さまざまな構成を使ってアプリをテストできるようになります。

```ruby
require "mobile_system_test_case"

class PostsTest < MobileSystemTestCase
  test "visiting the index" do
    visit posts_url
    assert_selector "h1", text: "Posts"
  end
end
```

#### Capybaraのアサーション

以下は、[`Capybara`][]が提供している、システムテストで利用可能なアサーションの抜粋です。

##### `assert_button(locator = nil, **options, &optional_filter_block)`

* 指定のテキスト、値、またはidを持つボタンがページに存在するかどうかをチェックする。

##### `assert_current_path(string, **options)`

* ページが指定通りのパスに存在していることを主張する。

##### `assert_field(locator = nil, **options, &optional_filter_block)`

* 指定のラベル、名前、またはidを持つフィールドがページのフォームに存在するかどうかをチェックする。

##### `assert_link(locator = nil, **options, &optional_filter_block)`

* 指定のテキストまたはidを持つリンクがページに存在するかどうかをチェックする。

##### `assert_selector(*args, &optional_filter_block)`

* セレクタで指定した要素（`h1`など）がページに存在することを主張する。

##### `assert_table(locator = nil, **options, &optional_filter_block`

* 指定のidまたはキャプションを持つテーブルがページに存在するかどうかをチェックする。

##### `assert_text(type, text, **options)`

* 指定のテキストコンテンツがページに存在することを主張する。

[`Capybara`]:
  https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Minitest/Assertions

#### スクリーンショットヘルパー

[`ScreenshotHelper`][]は、テスト中のスクリーンショットをキャプチャするよう設計されたヘルパーで、テストが失敗した時点のブラウザ画面を確認するときや、デバッグでスクリーンショットを確認するときに有用です。

`take_screenshot`メソッドおよび`take_failed_screenshot`メソッドが提供されており、`take_failed_screenshot`はRails内部の`after_teardown`に自動的に含まれます。

`take_screenshot`ヘルパーメソッドはテストのどこにでも書くことができ、ブラウザのスクリーンショット撮影に使えます。

[`ScreenshotHelper`]:
  https://api.rubyonrails.org/v5.1.7/classes/ActionDispatch/SystemTesting/TestHelpers/ScreenshotHelper.html

#### システムテストの利用法

システムテストの長所は、ユーザーによるやり取りをコントローラやモデルやビューを用いてテストできるという点で結合テストに似ていますが、本物のユーザーが操作しているかのようにテストを実際に実行できます。コメント入力や記事の削除、ドラフト記事の公開など、ユーザーがアプリケーションで行えるあらゆる操作をテストできます。

テストヘルパー
------------

コードの重複を回避するために独自のテストヘルパーを追加できます。サインインヘルパーはその良い例です。

```ruby
# test/test_helper.rb

module SignInHelper
  def sign_in_as(user)
    post sign_in_url(email: user.email, password: user.password)
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
```

```ruby
require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  test "should show profile" do
    # helper is now reusable from any controller test case
    sign_in_as users(:david)

    get profile_url
    assert_response :success
  end
end
```

#### ヘルパーを別ファイルに切り出す

ヘルパーが増えて`test_helper.rb`が散らかってきたことに気づいたら、別のファイルに切り出せます。切り出したファイルの置き場所は`test/lib`や`test/test_helpers`がよいでしょう。

```ruby
# test/test_helpers/multiple_assertions.rb
module MultipleAssertions
  def assert_multiple_of_forty_two(number)
    assert (number % 42 == 0), "expected #{number} to be a multiple of 42"
  end
end
```

これらのヘルパーは、必要に応じて明示的に`require`および`include`できます。

```ruby
require "test_helper"
require "test_helpers/multiple_assertions"

class NumberTest < ActiveSupport::TestCase
  include MultipleAssertions

  test "420 is a multiple of 42" do
    assert_multiple_of_forty_two 420
  end
end
```

または、関連する親クラス内で直接`include`することもできます。

```ruby
# test/test_helper.rb
require "test_helpers/sign_in_helper"

class ActionDispatch::IntegrationTest
  include SignInHelper
end
```

#### ヘルパーをeager requireする

ヘルパーを`test_helper.rb`内でeagerに`require`できると、テストファイルが暗黙でヘルパーにアクセスできるので便利です。これは以下のようなglob記法（`*`）で実現できます。

```ruby
# test/test_helper.rb
Dir[Rails.root.join("test", "test_helpers", "**", "*.rb")].each { |file| require file }
```

この方法のデメリットは、個別のテストで必要なファイルだけを`require`するよりも起動時間が長くなることです。

ルーティングをテストする
--------------

Railsアプリケーションの他のあらゆる部分と同様、ルーティングもテストできます。ルーティングのテストは、コントローラテストの一部として`test/controllers/`に配置します。

Railsで利用可能なルーティングアサーションについて詳しくは、[`ActionDispatch::Assertions::RoutingAssertions`][]のAPIドキュメントを参照してください。

[`ActionDispatch::Assertions::RoutingAssertions`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html

ビューをテストする
-------------

アプリケーションのビューをテストする方法の1つは、リクエストに対するレスポンスをテストするために、あるページで重要なHTML要素とその内容がレスポンスに含まれているというアサーションを書くことです。ビューのテストも、ルーティングのテストと同様に、コントローラテストの一環として`test/controllers/`に配置します。

### DOMによるHTML要素のアサーション

NOTE: 訳注: Rails 8のガイドでは、従来の`assert_select`や`assert_select_*`などによるアサーションが、`assert_dom`や`assert_dom_*`などに置き換えられました。

[rails-dom-testing][] gemの`assert_dom`や`assert_dom_equal`などのメソッドを使うと、レスポンスに含まれるHTML要素をシンプルかつ強力な構文でクエリできます。

`assert_dom`は、一致する要素が見つかった場合に`true`を返すアサーションです。
たとえば、次のようにして、ページタイトルが「Welcome to the Rails Testing Guide」であることを確認できます。

```ruby
assert_dom "title", "Welcome to the Rails Testing Guide"
```

より詳しくテストするために、`assert_dom`ブロックをネストすることも可能です。

以下の例の場合、外側の`assert_dom`で選択されたすべての要素の完全なコレクションに対して、内側の`assert_dom`がアサーションを実行します。

```ruby
assert_dom "ul.navigation" do
  assert_dom "li.menu_item"
end
```

選択した要素のコレクションをイテレートし、各要素に対して`assert_dom`を個別に呼び出すことも可能です。

たとえば、2つの順序付きリスト（`ol`）がレスポンスに含まれており、ネストされたリスト要素（`li`）がそれぞれのリストに4個ずつある場合、以下のテストは両方ともパスします。

```ruby
assert_dom "ol" do |elements|
  elements.each do |element|
    assert_dom element, "li", 4
  end
end

assert_dom "ol" do
  assert_dom "li", 8
end
```

`assert_dom_equal` メソッドは、2つのHTML文字列を比較して、それらが等しいかどうかをチェックします。

```ruby
assert_dom_equal '<a href="http://www.further-reading.com">Read more</a>',
  link_to("Read more", "http://www.further-reading.com")
```

さらに高度な利用法については、[rails-dom-testing][] gemのドキュメントを参照してください。

[rails-dom-testing][]と統合するため、[`ActionView::TestCase`][]を継承するテストは、レンダリングされたコンテンツを[`Nokogiri::XML::Node`][]のインスタンスとして返す`document_root_element`メソッドを宣言します。

```ruby
test "renders a link to itself" do
  article = Article.create! title: "Hello, world"

  render "articles/article", article: article
  anchor = document_root_element.at("a")

  assert_equal article.name, anchor.text
  assert_equal article_url(article), anchor["href"]
end
```

アプリケーションが[Nokogiri（1.14.0以上）][Nokogiri1.14.0]と[Minitest（5.18.0以上）][Minitest5.18.0]に依存している場合、この`document_root_element`はRubyの[パターンマッチング][pattern-matching]をサポートします。

```ruby
test "renders a link to itself" do
  article = Article.create! title: "Hello, world"

  render "articles/article", article: article
  anchor = document_root_element.at("a")
  url = article_url(article)

  assert_pattern do
    anchor => { content: "Hello, world", attributes: [{ name: "href", value: url }] }
  end
end
```

[rails-dom-testing]:
  https://github.com/rails/rails-dom-testing
[pattern-matching]:
  https://docs.ruby-lang.org/en/master/syntax/pattern_matching_rdoc.html
[Nokogiri1.14.0]:
  https://github.com/sparklemotion/nokogiri/releases/tag/v1.14.0
[Minitest5.18.0]:
  https://github.com/minitest/minitest/blob/v5.18.0/History.rdoc#5180--2023-03-04-

[システムテスト](#システムテスト)で使うのと同じ[Capybaraベースのアサーション][Capybara-assertions]を使いたい場合は、[`ActionView::TestCase`]を継承するベースクラスを以下のように定義することで`document_root_element`を`page`メソッドに変換できます。

[Capybara-assertions]:
  https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Minitest/Assertions

```ruby
# test/view_partial_test_case.rb

require "test_helper"
require "capybara/minitest"

class ViewPartialTestCase < ActionView::TestCase
  include Capybara::Minitest::Assertions

  def page
    Capybara.string(rendered)
  end
end
```

```ruby
# test/views/article_partial_test.rb

require "view_partial_test_case"

class ArticlePartialTest < ViewPartialTestCase
  test "renders a link to itself" do
    article = Article.create! title: "Hello, world"

    render "articles/article", article: article

    assert_link article.title, href: article_url(article)
  end
end
```

Capybaraに含まれるアサーションについて詳しくは、[Capybaraベースのアサーション][Capybara-assertions]セクションを参照してください。

### ビューのコンテンツを解析する

Action View 7.1以降の`#rendered`ヘルパーメソッドは、ビューのパーシャルでレンダリングされたコンテンツを解析できるオブジェクトを返します。

`#rendered`メソッドが返す`String`コンテンツをオブジェクトに変換するには、[`register_parser`][]を呼び出してパーサーを定義します。`.register_parser :rss`を呼び出すと`#rendered.rss`ヘルパーメソッドが定義されます。

たとえば、レンダリングした[RSSコンテンツ][RSS contents]を`#rendered.rss`で解析してオブジェクトにする場合は、以下のように`RSS::Parser.parse`呼び出しを登録します。

```ruby
register_parser :rss, -> rendered { RSS::Parser.parse(rendered) }

test "renders RSS" do
  article = Article.create!(title: "Hello, world")

  render formats: :rss, partial: article

  assert_equal "Hello, world", rendered.rss.items.last.title
end
```

`ActionView::TestCase`には、デフォルトで以下のパーサーが定義されています。

* `:html`: [`Nokogiri::XML::Node`][]のインスタンスを返します
* `:json`: [`ActiveSupport::HashWithIndifferentAccess`][]のインスタンスを返します

```ruby
test "renders HTML" do
  article = Article.create!(title: "Hello, world")

  render partial: "articles/article", locals: { article: article }

  assert_pattern { rendered.html.at("main h1") => { content: "Hello, world" } }
end
```

```ruby
test "renders JSON" do
  article = Article.create!(title: "Hello, world")

  render formats: :json, partial: "articles/article", locals: { article: article }

  assert_pattern { rendered.json => { title: "Hello, world" } }
end
```

[`register_parser`]:
  https://api.rubyonrails.org/classes/ActionView/TestCase/Behavior/ClassMethods.html#method-i-register_parser
[RSS-contents]:
  https://www.rssboard.org/rss-specification
[`Nokogiri::XML::Node`]:
  https://nokogiri.org/rdoc/Nokogiri/XML/Node.html
[`ActiveSupport::HashWithIndifferentAccess`]:
  https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html

### ビューで使えるその他のアサーション

以下は、ビューのテストで利用できるその他ののアサーションです。

- `assert_dom_email`:
  メールの本文に対するアサーションを行う。

- `assert_dom_encoded`:
  エンコードされたHTMLに対するアサーションを行う。各要素のコンテンツをデコードしてから、すべての要素をブロックを呼び出す形で行われる。

- `css_select(selector)`または`css_select(element, selector)`:
  `selector`引数で選択されたすべての要素を1つの配列にしたものを返す。2番目の書式については、最初に`element`引数がベース要素としてマッチし、続いてそのすべての子孫に対して`selector`引数のマッチを試みる。どちらの場合も、何も一致しなかった場合には空の配列を1つ返す。

`assert_dom_email`の利用例を以下に示します。

```ruby
assert_dom_email do
  assert_dom "small", "Please click the 'Unsubscribe' link if you want to opt-out."
end
```

ビューのパーシャルをテストする
---------------------

 [パーシャルテンプレート](layouts_and_rendering.html#パーシャルを使う)（partial template: 部分テンプレートとも）は単にパーシャルとも呼ばれ、レンダリングプロセスを分割して管理しやすくできます。パーシャルを利用することで、コードの一部をテンプレートから別のファイルに切り出してさまざまな場所で再利用できるようになります。

ビューのテストでは、パーシャルが期待通りにコンテンツをレンダリングするかどうかをテストできます。ビューのパーシャルのテストは`test/views/`に配置し、`ActionView::TestCase`を継承します。

パーシャルをレンダリングするには、テンプレート内で行うのと同様に`render`メソッドを呼び出します。レンダリングしたコンテンツは、test環境やローカル環境の`#rendered`メソッドを通じて利用できます。

```ruby
class ArticlePartialTest < ActionView::TestCase
  test "renders a link to itself" do
    article = Article.create! title: "Hello, world"

    render "articles/article", article: article

    assert_includes rendered, article.title
  end
end
```

`ActionView::TestCase`を継承するテストでは、[`assert_dom`](#ビューをテストする)や、[rails-dom-testing][] gemが提供する[ビューの追加アサーション](#ビューで使えるその他のアサーション)も利用できるようになります。

```ruby
test "renders a link to itself" do
  article = Article.create! title: "Hello, world"

  render "articles/article", article: article

  assert_dom "a[href=?]", article_url(article), text: article.title
end
```

### ビューヘルパーをテストする

ヘルパー自体は単なるシンプルなモジュールであり、ビューから利用するヘルパーメソッドをこの中に定義します。

ヘルパーのテストについては、ヘルパーメソッドの出力が期待どおりであるかどうかをチェックするだけで十分です。ヘルパー関連のテストは`test/helpers`ディレクトリに置かれます。

以下のようなヘルパーがあるとします。

```ruby
module UsersHelper
  def link_to_user(user)
    link_to "#{user.first_name} #{user.last_name}", user
  end
end
```

このメソッドの出力は次のようにしてテストできます。

```ruby
class UsersHelperTest < ActionView::TestCase
  test "should return the user's full name" do
    user = users(:david)

    assert_dom_equal %{<a href="/user/#{user.id}">David Heinemeier Hansson</a>}, link_to_user(user)
  end
end
```

さらに、このテストクラスは[`ActionView::TestCase`][]を継承しているので、`link_to`や`pluralize`などのRailsヘルパーメソッドにもアクセスできます。

メーラーをテストする
--------------------

メーラークラスを十分にテストするためには特殊なツールが若干必要になります。

### メーラーのテストについて

Railsアプリケーションの他の部分と同様、メーラークラスについても期待どおり動作するかどうかをテストする必要があります。

メーラークラスをテストする目的は以下を確認することです。

* メールが処理（作成および送信）されていること
* メールの内容（subject、sender、bodyなど）が正しいこと
* 適切なメールが適切なタイミングで送信されていること

メーラーのテストには単体テストと機能テストの2つの側面があります。

単体テストでは、完全に制御された入力を与えた結果の出力と、期待される既知の値（[フィクスチャ](#フィクスチャ)）を比較します。

機能テストではメーラーによって作成される詳細部分についてのテストはほとんど行わず、コントローラとモデルがメーラーを正しく利用しているかどうかをテストするのが普通です。

メーラーのテストは、最終的に適切なメールが適切なタイミングで送信されたことを立証するために行います。

### 単体テスト

メーラーが期待どおりに動作しているかどうかをテストするために、事前に作成しておいた出力例と、メーラーの実際の出力を比較する形で単体テストを実行できます。

#### メーラーのフィクスチャ

メーラーの単体テストを行なうには、フィクスチャを利用してメーラーが最終的に出力すべき外見の例を与えます。
これらのフィクスチャはメールのサンプル出力であり、通常のフィクスチャのようなActive Recordデータではないので、通常のフィクスチャとは別の専用のサブディレクトリに保存します。

`test/fixtures/`ディレクトリの下のディレクトリ名は、メーラーの名前に対応させます。たとえば`UserMailer`という名前のメーラーであれば、`test/fixtures/user_mailer`というスネークケースのディレクトリ名にします。

メーラーを生成しても、メーラーのアクションに対応するスタブフィクスチャは生成されません。これらのファイルは上述の方法で手動作成する必要があります。

#### 基本的なテストケース

`invite`というアクションで知人に招待状を送信する`UserMailer`という名前のメーラーに対する単体テストを以下に示します。これは、`invite`アクションをジェネレータで生成したときに作成される基本的なテストに手を加えたものです。

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # さらにアサーションを行うためにメールを作成して保存
    email = UserMailer.create_invite("me@example.com",
                                     "friend@example.com", Time.now)

    # メールを送信後キューに追加されるかどうかをテスト
    assert_emails 1 do
      email.deliver_now
    end

    # 送信されたメールの本文が期待どおりの内容であるかどうかをテスト
    assert_equal ["me@example.com"], email.from
    assert_equal ["friend@example.com"], email.to
    assert_equal "You have been invited by me@example.com", email.subject
    assert_equal read_fixture("invite").join, email.body.to_s
  end
end
```

このテストでは、メールを作成して、その結果返されたオブジェクトを`email`変数に保存します。
次に、このメールが送信されたことを主張します（最初のアサーション）。
次のアサーションでは、メールの内容が期待どおりであることを主張します。なお、`read_fixture`ヘルパーはこのファイルからコンテンツを読み込むのに使います。

NOTE: `email.body.to_s`は、HTMLまたはテキストで1回出現した場合にのみ存在するとみなされます。メーラーがHTMLとテキストの両方を提供している場合は、`email.text_part.body.to_s`や`email.html_part.body.to_s`を用いてそれぞれの一部に対するフィクスチャをテストできます。

`invite`フィクスチャは以下のような内容にしておきます。

```
friend@example.comさん、こんにちは。

招待状を送付いたします。

どうぞよろしく!
```

#### テスト時の配信方法を設定する

テスト時の送信モードは、`config/environments/test.rb`の`ActionMailer::Base.delivery_method = :test`という行で`:test`に設定されています。これにより、送信したメールが実際に配信されないようにできます。そうしないと、テスト中にユーザーにスパムメールを送りつけてしまうことになります。この設定で送信したメールは、実際には`ActionMailer::Base.deliveries`という配列に追加されます。

NOTE: この`ActionMailer::Base.deliveries`という配列は、`ActionMailer::TestCase`と`ActionDispatch::IntegrationTest`でのテストを除き、自動的にはリセットされません。それら以外のテストで配列をクリアしたい場合は、`ActionMailer::Base.deliveries.clear`で手動リセットできます。

#### キューに登録されたメールをテストする

`assert_enqueued_email_with`アサーションを使うと、期待されるメーラーメソッドの引数やパラメータをすべて利用してメールがエンキュー（enqueue: キューへの登録）されたことを確認できます。これにより、`deliver_later`メソッドでエンキューされたすべてのメールと照合できるようになります。

基本的なテストケースと同様に、メールを作成し、返されたオブジェクトを`email`変数に保存します。引数やパラメータを渡すテスト例をいくつか紹介します。

以下の例は、メールが正しい引数でエンキューされたことを主張します。

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # メールを作成し、今後アサーションするために保存する
    email = UserMailer.create_invite("me@example.com", "friend@example.com")

    # 正しい引数でメールがエンキューされたことをテストする
    assert_enqueued_email_with UserMailer, :create_invite, args: ["me@example.com", "friend@example.com"] do
      email.deliver_later
    end
  end
end
```

以下の例は、引数のハッシュを`args`として渡すことで、メーラーメソッドの正しい名前付き引数でメールがエンキューされたことを主張します。

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # メールを作成し、今後アサーションするために保存する
    email = UserMailer.create_invite(from: "me@example.com", to: "friend@example.com")

    # 正しい名前付き引数でメールがエンキューされたことをテストする
    assert_enqueued_email_with UserMailer, :create_invite,
    args: [{ from: "me@example.com", to: "friend@example.com" }] do
      email.deliver_later
    end
  end
end
```

以下の例は、パラメータ化されたメーラーが正しいパラメータと引数でエンキューされたことを主張します。メーラーのパラメータは`params`として、メーラーメソッドの引数は`args`として渡されます：

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # メールを作成し、今後アサーションするために保存する
    email = UserMailer.with(all: "good").create_invite("me@example.com", "friend@example.com")

    # パラメータと引数の正しいメーラーでメールがエンキューされたことをテストする
    assert_enqueued_email_with UserMailer, :create_invite,
    params: { all: "good" }, args: ["me@example.com", "friend@example.com"] do
      email.deliver_later
    end
  end
end
```

以下の例は、パラメータ化されたメーラーが正しいパラメータでエンキューされたかどうかをテストする別の方法です。

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # メールを作成し、今後アサーションするために保存する
    email = UserMailer.with(to: "friend@example.com").create_invite

    # パラメータの正しいメーラーでメールがエンキューされたことをテストする
    assert_enqueued_email_with UserMailer.with(to: "friend@example.com"), :create_invite do
      email.deliver_later
    end
  end
end
```

### 機能テストとシステムテスト

単体テストはメールの属性をテストできますが、機能テストとシステムテストを使えば、配信するメールがユーザー操作によって適切にトリガーされているかどうかをテストできます。

たとえば、友人を招待する操作によってメールが適切に送信されたかどうかを以下のようにチェックできます。

```ruby
# 結合テスト
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "invite friend" do
    # ActionMailer::Base.deliveriesの件数が変わるというアサーション
    assert_emails 1 do
      post invite_friend_url, params: { email: "friend@example.com" }
    end
  end
end
```

```ruby
# システムテスト
require "test_helper"

class UsersTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  test "inviting a friend" do
    visit invite_users_url
    fill_in "Email", with: "friend@example.com"
    assert_emails 1 do
      click_on "Invite"
    end
  end
end
```

NOTE: `assert_emails`メソッドは特定の配信方法に紐付けられていないので、`deliver_now`メソッドと`deliver_later`メソッドのどちらでメールを配信する場合にも利用できます。メールがキューに登録されたことを明示的なアサーションにしたい場合は、`assert_enqueued_email_with`メソッド（[上述の例を参照](#キューに登録されたメールをテストする)）か、`assert_enqueued_emails`メソッドを利用できます。詳しくは[`ActionMailer::TestHelper`][] APIドキュメントを参照してください。

[`ActionMailer::TestHelper`]:
  https://api.rubyonrails.org/classes/ActionMailer/TestHelper.html

ジョブをテストする
------------

複数のジョブを分離してテストする（ジョブの振る舞いに注目する）ことも、コンテキスト内でテストする（呼び出し元のコードの振る舞いに注目する）ことも可能です。

### ジョブを分離してテストする

ジョブを生成すると、ジョブに関連するテストも`test/jobs/`ディレクトリの下に生成されます。

以下は請求（billing）ジョブの例です。

```ruby
require "test_helper"

class BillingJobTest < ActiveJob::TestCase
  test "account is charged" do
    perform_enqueued_jobs do
      BillingJob.perform_later(account, product)
    end
    assert account.reload.charged_for?(product)
  end
end
```

テスト用のデフォルトキューアダプタは、[`perform_enqueued_jobs`][]が呼び出されるまでジョブを実行しません。さらに、テスト同士が干渉しないようにするため、個別のテストを実行する前にすべてのジョブをクリアします。

このテストでは、[`perform_now`][]ではなく、`perform_enqueued_jobs`と[`perform_later`][]を使っています。こうすることで、リトライが設定されている場合には失敗したリトライが（再度エンキューされて無視されずに）テストでキャッチされるようになります。

[`perform_enqueued_jobs`]:
    https://api.rubyonrails.org/classes/ActiveJob/TestHelper.html#method-i-perform_enqueued_jobs
[`perform_later`]:
    https://api.rubyonrails.org/classes/ActiveJob/Enqueuing/ClassMethods.html#method-i-perform_later
[`perform_now`]:
    https://api.rubyonrails.org/classes/ActiveJob/Execution/ClassMethods.html#method-i-perform_now

### ジョブをコンテキストでテストする

コントローラなどで、呼び出しのたびにジョブが正しくエンキューされているかどうかをテストするのはよい方法です。[`ActiveJob::TestHelper`][]モジュールは、そのために役立つ[`assert_enqueued_with`][]などのメソッドを提供しています。

以下はAccountモデルのメソッドをテストする例です。

```ruby
require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#charge_for enqueues billing job" do
    assert_enqueued_with(job: BillingJob) do
      account.charge_for(product)
    end

    assert_not account.reload.charged_for?(product)

    perform_enqueued_jobs

    assert account.reload.charged_for?(product)
  end
end
```

[`ActiveJob::TestHelper`]:
    https://api.rubyonrails.org/classes/ActiveJob/TestHelper.html
[`assert_enqueued_with`]:
    https://api.rubyonrails.org/classes/ActiveJob/TestHelper.html#method-i-assert_enqueued_with

### 例外が発生することをテストする

特にリトライが設定されている場合は、特定のケースでジョブが例外を発生することをテストするのが難しくなることもあります。

`perform_enqueued_jobs`ヘルパーは、ジョブが例外を発生するとテストが失敗するので、例外の発生時にテストを成功させるには、以下のようにジョブの`perform`メソッドを直接呼び出す必要があります。

```ruby
require "test_helper"

class BillingJobTest < ActiveJob::TestCase
  test "does not charge accounts with insufficient funds" do
    assert_raises(InsufficientFundsError) do
      BillingJob.new(empty_account, product).perform
    end
    assert_not account.reload.charged_for?(product)
  end
end
```

この方法はフレームワークの一部（引数のシリアライズなど）を回避するため、一般には推奨されていません。

Action Cableをテストする
--------------------

Action Cableはアプリケーション内部の異なるレベルで用いられるため、チャネル、コネクションのクラス自身、および他のエンティティがいずれも正しいメッセージをブロードキャストすることをテストする必要があります。

### コネクションのテストケース

デフォルトでは、Action Cableを用いる新しいRailsアプリを生成すると、基本のコネクションクラス（`ApplicationCable::Connection`）のテストも`test/channels/application_cable/`ディレクトリの下に生成されます。

コネクションテストの目的は、コネクションのidが正しく代入されているか、正しくないコネクションリクエストを却下できるかどうかをチェックすることです。以下はテスト例です。

```ruby
class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects with params" do
    # `connect`メソッドを呼ぶことでコネクションのオープンをシミュレートする
    connect params: { user_id: 42 }

    # テストでは`connection`でConnectionオブジェクトにアクセスできる
    assert_equal connection.user_id, "42"
  end

  test "rejects connection without params" do
    # コネクションが却下されたことを
    # `assert_reject_connection`マッチャーで検証する
    assert_reject_connection { connect }
  end
end
```

リクエストのcookieも、結合テストの場合と同様の方法で指定できます。

```ruby
test "connects with cookies" do
  cookies.signed[:user_id] = "42"

  connect

  assert_equal connection.user_id, "42"
end
```

詳しくは[`ActionCable::Connection::TestCase`][] APIドキュメントを参照してください。

[`ActionCable::Connection::TestCase`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/TestCase.html

### チャネルのテストケース

デフォルトでは、チャネルをジェネレータで生成するときに`test/channels/`ディレクトリの下に関連するテストも生成されます。以下はチャット用チャネルのテスト例です。

```ruby
require "test_helper"

class ChatChannelTest < ActionCable::Channel::TestCase
  test "subscribes and stream for room" do
    # `subscribe`を呼ぶことでサブスクリプション作成をシミュレートする
    subscribe room: "15"

    # テストでは`subscription`でChannelオブジェクトにアクセスできる
    assert subscription.confirmed?
    assert_has_stream "chat_15"
  end
end
```

このテストはかなりシンプルであり、チャネルが特定のストリームへのコネクションをサブスクライブするアサーションしかありません。

背後のコネクションidも指定できます。以下はWeb通知チャネルのテスト例です。

```ruby
require "test_helper"

class WebNotificationsChannelTest < ActionCable::Channel::TestCase
  test "subscribes and stream for user" do
    stub_connection current_user: users(:john)

    subscribe

    assert_has_stream_for users(:john)
  end
end
```

詳しくは[`ActionCable::Channel::TestCase`][] APIドキュメントを参照してください。

[`ActionCable::Channel::TestCase`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/TestCase.html

### 他のコンポーネント内でのカスタムアサーションとブロードキャストテスト

Action Cableには、冗長なテストを削減するのに使えるカスタムアサーションが多数用意されています。利用できる全アサーションのリストについては、[`ActionCable::TestHelper`][] APIドキュメントを参照してください。

正しいメッセージがブロードキャストされたことを（コントローラ内部などの）他のコンポーネント内で確認するのはよい方法です。Action Cableが提供するカスタムアサーションの有用さは、まさにここで発揮されます。たとえばモデル内では以下のように書けます。

```ruby
require "test_helper"

class ProductTest < ActionCable::TestCase
  test "broadcast status after charge" do
    assert_broadcast_on("products:#{product.id}", type: "charged") do
      product.charge(account)
    end
  end
end
```

`Channel.broadcast_to`によるブロードキャストをテストしたい場合は、`Channel.broadcasting_for`で背後のストリーム名を生成します。

```ruby
# app/jobs/chat_relay_job.rb
class ChatRelayJob < ApplicationJob
  def perform(room, message)
    ChatChannel.broadcast_to room, text: message
  end
end
```

```ruby
# test/jobs/chat_relay_job_test.rb
require "test_helper"

class ChatRelayJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "broadcast message to room" do
    room = rooms(:all)

    assert_broadcast_on(ChatChannel.broadcasting_for(room), text: "Hi!") do
      ChatRelayJob.perform_now(room, "Hi!")
    end
  end
end
```

[`ActionCable::TestHelper`]:
  https://api.rubyonrails.org/classes/ActionCable/TestHelper.html

### テストをCIで実行する

CI (Continuous Integration: 継続的インテグレーション) は開発手法の一種で、変更をこまめにメインのコードベースに統合し、マージ前に自動テストを実行します。

CI環境ですべてのテストを実行するのに必要なコマンドは、以下の1つだけです。

```bash
$ bin/rails test
```

[システムテスト](#システムテスト)は通常のテストよりもかなり遅いため、`bin/rails test`コマンドはシステムテストを実行しません。
システムテストを実行するには、CIステップに`bin/rails test:system`の実行を追加するか、最初のステップを`bin/rails test:all`に変更して、システムテストを含むすべてのテストを実行するようにします。

並列テスト
----------------

並列テスト（parallel testing）を用いることで、テストスイート全体の実行に要する時間を削減できます。デフォルトの手法はプロセスのforkですが、スレッドもサポートされています。

### プロセスを用いた並列テスト

デフォルトの並列化手法は、RubyのDRbシステムを用いるプロセスのforkです。プロセスは、提供されるワーカー数に基づいてforkされます。デフォルトのワーカー数は、実行されるマシンの実際のコア数ですが、`parallelize`メソッドに数値を渡すことで変更できます。

並列化を有効にするには、`test_helper.rb`に以下を記述します。

```ruby
class ActiveSupport::TestCase
  parallelize(workers: 2)
end
```

渡されたワーカー数は、プロセスが`fork`される回数です。
ローカルテストスイートをCIとは別の方法で並列化したい場合は、以下の環境変数を用いてテスト実行時に指定するワーカー数を手軽に変更できます。

```bash
$ PARALLEL_WORKERS=15 bin/rails test
```

テストを並列化すると、Active Recordはデータベースの作成やスキーマのデータベースへの読み込みを自動的にプロセスごとに扱います。データベース名の末尾には、ワーカー数に応じた数値が追加されます。たとえば、ワーカーが2つの場合は`test-database-0`と`test-database-1`がそれぞれ作成されます。

渡されたワーカー数が1以下の場合はプロセスはforkされず、テストは並列化しません。テストのデータベースもオリジナルの`test-database`のままになります。

並列テスト用に2つのフックが提供されます。これらのフックは、データベースを複数使っている場合や、ワーカー数に応じた他のタスクを実行する場合に便利です。

- `parallelize_setup`メソッド: プロセスがforkした直後に呼び出されます。
- `parallelize_teardown`メソッド: プロセスがcloseする直前に呼び出されます。

```ruby
class ActiveSupport::TestCase
  parallelize_setup do |worker|
    # データベースをセットアップする
  end

  parallelize_teardown do |worker|
    # データベースをクリーンアップする
  end

  parallelize(workers: :number_of_processors)
end
```

これらのメソッドは、スレッドを用いる並列テストでは不要であり、利用できません。

### スレッドを用いる並列テスト

スレッドを使いたい場合やJRubyを利用する場合のために、スレッドによる並列化オプションも提供されています。スレッドによる並列化では、minitestの`Parallel::Executor`が使われます。

並列化手法をforkからスレッドに変更するには、`test_helper.rb`に以下を記述します。

```ruby
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors, with: :threads)
end
```

JRubyで生成されたRailsアプリケーションには、自動的に`with: :threads`オプションが含まれます。

NOTE: プロセスの場合と同様に、スレッドベースの並列テストでも`PARALLEL_WORKERS`環境変数を使ってテスト実行ワーカー数を変更できます。

### 並列トランザクションをテストする

並列トランザクションをスレッドで実行するコードをテストしたい場合、テスト用トランザクションの下ですでにネストされているため、トランザクションが互いにブロックしてしまう可能性があります。

これを回避するには、以下のように`self.use_transactional_tests = false`を設定することで、テストケースのクラスでトランザクションを無効にできます。

```ruby
class WorkerTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "parallel transactions" do
    # トランザクションを作成するスレッドがいくつか起動される
  end
end
```

NOTE: トランザクションを無効にしたテストでは、テストが完了しても変更が自動でロールバックされなくなります。そのため、テストで作成したデータをテスト実行後にすべてクリーンアップする必要があります。

### テストを並列化するスレッショルドの指定

テストを並列実行すると、データベースのセットアップやフィクスチャの読み込みなどでオーバーヘッドが発生します。そのため、Railsはテスト件数が50未満の場合は並列化を行いません。

このスレッショルド（閾値）は`test.rb`で以下のように設定できます。

```ruby
config.active_support.test_parallelization_threshold = 100
```

以下のようにテストケースレベルでも並列化のスレッショルドを設定可能です。

```ruby
class ActiveSupport::TestCase
  parallelize threshold: 100
end
```

eager loadingをテストする
---------------------

通常、`development`環境や`test`環境のアプリケーションは、高速化のためにeager loading（読み込みを遅延させずに一括で読み込むこと）を行うことはありませんが、`production`環境のアプリケーションはeager loadingを行います。

プロジェクトのファイルの一部が何らかの理由で読み込めない場合、`production`環境にデプロイする前にそのことを検出することが重要です。

### CIの場合

プロジェクトでCI（Continuous Integration: 継続的インテグレーション）を利用している場合、アプリケーションでeager loadingを確実に行う手軽な方法の１つは、CIでeager loadingすることです。

CIでは、テストスイートがそこで実行されていることを示すために、以下のように何らかの環境変数（`CI`など）を設定するのが普通です。

```ruby
# config/environments/test.rb
config.eager_load = ENV["CI"].present?
```

Rails 7からは、新規生成されたアプリケーションでこの設定がデフォルトで行われます。

プロジェクトでCIを利用していない場合でも、以下のようにテストスイートで`Rails.application.eager_load!`を呼び出すことでeager loadingを実行できます。

```ruby
require "test_helper"

class ZeitwerkComplianceTest < ActiveSupport::TestCase
  test "eager loads all files without errors" do
    assert_nothing_raised { Rails.application.eager_load! }
  end
end
```

その他のテスティング関連リソース
------------------------

### エラー処理

Railsのシステムテスト、結合テスト、コントローラの機能テストでは、テスト中に発生した例外の`rescue`を試み、HTMLエラーページで応答します。この振る舞いは[`config.action_dispatch.show_exceptions`][]設定で制御できます。

[`config.action_dispatch.show_exceptions`]:
  configuring.html#config-action-dispatch-show-exceptions

### 時間に依存するコードをテストする

Railsには、時間の影響を受けやすいコードが期待どおりに動作しているというアサーションに役立つ組み込みのヘルパーメソッドを提供しています。

以下の例では[`travel_to`][travel_to]ヘルパーを使っています。

```ruby
# 登録後のユーザーは1か月分の特典が有効だとする
user = User.create(name: "Gaurish", activation_date: Date.new(2004, 10, 24))
assert_not user.applicable_for_gifting?
travel_to Date.new(2004, 11, 24) do
  assert_equal Date.new(2004, 10, 24), user.activation_date #`travel_to`ブロック内では`Date.current`がモック化される
  assert user.applicable_for_gifting?
end
assert_equal Date.new(2004, 10, 24), user.activation_date # この変更は`travel_to`ブロック内からしか見えない
```

時間関連のヘルパーについて詳しくは、[`ActiveSupport::Testing::TimeHelpers`][time_helpers_api] APIドキュメントを参照してください。

[travel_to]:
    https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html#method-i-travel_to
[time_helpers_api]:
    https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html
