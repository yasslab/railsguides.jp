Rails テスティングガイド
=====================================

本ガイドは、アプリケーションをテストするためにRailsに組み込まれているメカニズムについて解説します。

このガイドの内容:

* Railsテスティング用語
* アプリケーションに対する単体テスト、機能テスト、結合テスト、システムテスト（system test）の実施
* その他の著名なテスティング方法とプラグインの紹介

--------------------------------------------------------------------------------

Railsアプリケーションでテストを作成しなければならない理由
--------------------------------------------

Railsでは、テストをきわめて簡単に作成できます。テストの作成は、モデルやコントローラを作成する時点でテストコードのスケルトンを作成することから始まります。

Railsのテストが作成されていれば、後はそれを実行するだけで、特に大規模なリファクタリングを行なう際にコードが期待どおりに動作していることを即座に確認できます。

Railsのテストはブラウザのリクエストをシミュレートできるので、ブラウザを手動で操作せずにアプリケーションのレスポンスをテストできます。

テストを導入する
-----------------------

テスティングのサポートは最初期からRailsに組み込まれています。決して、最近テスティングが流行っていてクールだから導入してみた、というようなその場の思い付きで導入されたものではありません。

### Railsを即座にテスト用に設定する

`rails new` _application_name_でRailsアプリケーションを作成すると、その場で`test`ディレクトリが作成されます。このディレクトリの内容は次のようになっています。

```bash
$ ls -F test
controllers/           helpers/               mailers/               system/                test_helper.rb
fixtures/              integration/           models/                application_system_test_case.rb
```

`helpers`ディレクトリにはビューヘルパーのテスト、`mailers`ディレクトリにはメイラーのテスト、`models`ディレクトリにはモデル用のテストをそれぞれ保存します。`controllers`ディレクトリはコントローラ/ルーティング/ビューをまとめたテストの置き場所です。`integration`ディレクトリはコントローラ同士のやりとりのテストを置く場所です。

システムテストのディレクトリ（`system`）にはシステムテストを保存します。システムテストは、ユーザーエクスペリエンスに沿ったアプリケーションのテストを行うためのもので、JavaScriptのテストにも有用です。
システムテストはCapybaraから継承した機能で、アプリケーションのブラウザテストを実行します。

フィクスチャはテストデータを編成する方法の1つであり、`fixtures`フォルダに置かれます。

ジョブに関連するテストが最初に作成されると、`jobs`ディレクトリも作成されます。

`test_helper.rb`にはテスティングのデフォルト設定を記入します。

システムテストのデフォルトの設定は`application_system_test_case.rb`に保存されます。

### test環境

デフォルトでは、すべてのRailsアプリケーションにはdevelopment、test、productionの3つの環境があります。

それぞれの環境の設定はいずれも同様の方法で変更できます。テストの場合は、`config/environments/test.rb`にあるオプションを変更することでtest環境を変更できます。

NOTE: テストは`RAILS_ENV=test`環境で実行されます。

### RailsとMinitestの出会い

ガイドの[Rails をはじめよう](getting_started.html)で`rails generate model`コマンドを実行したのを覚えていますか。最初のモデルを作成すると、`test`ディレクトリにはテストのスタブ（stub）が生成されます。

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
require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
```

Railsにおけるテスティングコードと用語に親しんでいただくために、このファイルに含まれている内容を順にご紹介します。

```ruby
require 'test_helper'
```

このファイルを`require`すると、テストで使うデフォルト設定として`test_helper.rb`が読み込まれます。今後書くすべてのテストにもこれを記述しますので、このファイルに追加したメソッドはテスト全体で使えるようになります。

```ruby
class ArticleTest < ActiveSupport::TestCase
```

`ArticleTest`クラスは`ActiveSupport::TestCase`を継承することによって、**テストケース**をひとつ定義しています。これにより、`ActiveSupport::TestCase`のすべてのメソッドを`ArticleTest`で利用できます。これらのメソッドのいくつかについては後述します。

`ActiveSupport::TestCase`のスーパークラスは`Minitest::Test`です。この`Minitest::Test`を継承したクラスで定義される、`test_`で始まるすべてのメソッドは単に「テスト」と呼ばれます。この`test_`は小文字でなければなりません。従って、`test_password`および`test_valid_password`と定義されたメソッド名は正式なテスト名となり、テストケースの実行時に自動的に実行されます。

Railsは、ブロックとテスト名をそれぞれ1つずつ持つ`test`メソッドを1つ追加します。この時生成されるのは通常の`Minitest::Unit`テストであり、メソッド名の先頭に`test_`が付きます。これにより、メソッドの命名に気を遣わずに済み、次のような感じで書けます。

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

NOTE: テスト名からのメソッド名生成は、スペースをアンダースコアに置き換えることによって行われます。生成されたメソッド名はRubyの正規な識別子である必要はありません。テスト名にパンクチュエーション（句読点）などの文字が含まれていても大丈夫です。これが可能なのは、Rubyではメソッド名にどんな文字列でも使えるようになっているからです。普通でない文字を使おうとすると`define_method`呼び出しや`send`呼び出しが必要になりますが、名前の付け方そのものには公式な制限はありません。

次に、最初のアサーションを見てみましょう。

```ruby
assert true
```

アサーション（assertion）とは、オブジェクトまたは式を評価して、期待された結果が得られるかどうかをチェックするコードです。アサーションでは以下のようなチェックを行なうことができます。

* ある値が別の値と等しいかどうか
* このオブジェクトはnilかどうか
* コードのこの行で例外が発生するかどうか
* ユーザーのパスワードが5文字より多いかどうか

1つのテストにはアサーションが1つ以上含まれることがあります。すべてのアサーションに成功してはじめてテストがパスします。

### 最初の「失敗するテスト」

今度はテストが失敗した場合の結果を見てみましょう。そのためには、`article_test.rb`テストケースに、確実に失敗するテストを以下のように追加してみます。

```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save
end
```

それでは、新しく追加したテストを実行してみましょう（`6`はテストが定義されている行番号です）。

```bash
$ bin/rails test test/models/article_test.rb:6
Run options: --seed 44656

# Running:

F

Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:6]:
Expected true to be nil or false


bin/rails test test/models/article_test.rb:6



Finished in 0.023918s, 41.8090 runs/s, 41.8090 assertions/s.

1 runs, 1 assertions, 1 failures, 0 errors, 0 skips

```

出力に含まれている単独の文字`F`は失敗を表します。`Failure`の後にこの失敗に対応するトレースが、失敗したテスト名とともに表示されています。次の数行はスタックトレースで、アサーションの実際の値と期待されていた値がその後に表示されています。デフォルトのアサーションメッセージには、エラー箇所を特定するのに十分な情報が含まれています。すべてのアサーションは失敗時のメッセージをさらに読みやすくするために、以下のようにメッセージをオプションパラメータとして渡せます。

```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save, "Saved the article without a title"
end
```

テストを実行すると、以下のようにさらに読みやすいメッセージが表示されます。

```bash
Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:6]:
Saved the article without a title
```

今度はtitleフィールドに対してモデルのレベルでバリデーションを行い、テストがパスするようにしてみましょう。

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
end
```

このテストはパスするはずです。もう一度テストを実行してみましょう。

```bash
$ bin/rails test test/models/article_test.rb:6
Run options: --seed 31252

# Running:

 .

Finished in 0.027476s, 36.3952 runs/s, 36.3952 assertions/s.

1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

お気付きになった方もいるかと思いますが、私たちは欲しい機能が未実装であるために失敗するテストをあえて最初に作成していることにご注目ください。続いてその機能を実装し、それからもう一度実行してテストがパスすることを確認しました。ソフトウェア開発の世界ではこのようなアプローチをテスト駆動開発 ( [Test-Driven Development (TDD)](http://c2.com/cgi/wiki?TestDrivenDevelopment) : TDD) と呼んでいます。

### エラーの表示内容

エラーがどのように表示されるかを確認するために、以下のようなエラーを含んだテストを作ってみましょう。

```ruby
test "should report error" do
  # some_undefined_variableはテストケースのどこにも定義されていない
  some_undefined_variable
  assert true
end
```

これで、このテストを実行するとさらに多くのメッセージがコンソールに表示されるようになりました。

```bash
$ bin/rails test test/models/article_test.rb
Run options: --seed 1808

# Running:

.E

Error:
ArticleTest#test_should_report_error:
NameError: undefined local variable or method 'some_undefined_variable' for #<ArticleTest:0x007fee3aa71798>
    test/models/article_test.rb:11:in 'block in <class:ArticleTest>'


bin/rails test test/models/article_test.rb:9


Finished in 0.040609s, 49.2500 runs/s, 24.6250 assertions/s.

2 runs, 1 assertions, 0 failures, 1 errors, 0 skips
```

今度は'E'が出力されます。これはエラーが発生したテストが1つあることを示しています。

NOTE: テストスイートに含まれる各テストメソッドは、エラーまたはアサーション失敗が発生するとそこで実行を中止し、次のメソッドに進みます。テストメソッドの実行順序はすべてランダムです。テストの実行順序は[`config.active_support.test_order`オプション](configuring.html#active-supportを設定する)で設定できます。

テストが失敗すると、それに応じたバックトレースが出力されます。Railsはデフォルトでバックトレースをフィルタし、アプリケーションに関連するバックトレースのみを出力します。これによって、フレームワークから発生する不要な情報を排除して作成中のコードに集中できます。完全なバックトレースを参照しなければならなくなった場合は、`-b`（または`--backtrace`）引数を設定するだけで動作を変更できます。

```bash
$ bin/rails test -b test/models/article_test.rb
```

このテストをパスさせるには、`assert_raises`を用いて以下のようにテストを変更します。

```ruby
test "should report error" do
  # some_undefined_variableはテストケースのどこにも定義されていない
  assert_raises(NameError) do
    some_undefined_variable
  end
end
```

これでテストはパスするはずです。

### 利用可能なアサーション

ここまでにいくつかのアサーションをご紹介しましたが、これらはごく一部に過ぎません。アサーションこそは、テストの中心を担う重要な存在です。システムが計画通りに動作していることを実際に確認しているのはアサーションです。

アサーションは非常に多くの種類が使えるようになっています。
以下で紹介するのは、[`Minitest`](https://github.com/seattlerb/minitest)で使えるアサーションからの抜粋です。MinitestはRailsにデフォルトで組み込まれているテスティングライブラリです。`[msg]`パラメータは1つのオプション文字列メッセージであり、テストが失敗したときのメッセージをわかりやすくするにはここで指定します。これは必須ではありません。

| アサーション                                                        | 目的 |
| ---------------------------------------------------------------- | ------- |
| `assert( test, [msg] )`                                          | `test`はtrueであると主張する。|
| `assert_not( test, [msg] )`                                      | `test`はfalseであると主張する。|
| `assert_equal( expected, actual, [msg] )`                        | `expected == actual`はtrueであると主張する。|
| `assert_not_equal( expected, actual, [msg] )`                    | `expected != actual`はtrueであると主張する。|
| `assert_same( expected, actual, [msg] )`                         | `expected.equal?(actual)`はtrueであると主張する。|
| `assert_not_same( expected, actual, [msg] )`                     | `expected.equal?(actual)`はfalseであると主張する。|
| `assert_nil( obj, [msg] )`                                       | `obj.nil?`はtrueであると主張する。|
| `assert_not_nil( obj, [msg] )`                                   | `obj.nil?`はfalseであると主張する。|
| `assert_empty( obj, [msg] )`                                     | `obj`は`empty?`であると主張する。|
| `assert_not_empty( obj, [msg] )`                                 | `obj`は`empty?`ではないと主張する。|
| `assert_match( regexp, string, [msg] )`                          | stringは正規表現 (regexp) にマッチすると主張する。|
| `assert_no_match( regexp, string, [msg] )`                       | stringは正規表現 (regexp) にマッチしないと主張する。|
| `assert_includes( collection, obj, [msg] )`                      | `obj`は`collection`に含まれると主張する。|
| `assert_not_includes( collection, obj, [msg] )`                  | `obj`は`collection`に含まれないと主張する。|
| `assert_in_delta( expected, actual, [delta], [msg] )`            | `expected`と`actual`の個数の差は`delta`以内であると主張する。|
| `assert_in_epsilon ( expected, actual, [epsilon], [msg] )`       | `expected`と`actual`の数値の相対誤差が`epsilon`より小さいと主張する。|
| `assert_not_in_epsilon ( expected, actual, [epsilon], [msg] )`   |  `expected`と`actual`の数値には`epsilon`より小さい相対誤差がないと主張する。|
| `assert_not_in_delta( expected, actual, [delta], [msg] )`        | `expected`と`actual`の個数の差は`delta`以内にはないと主張する。|
| `assert_throws( symbol, [msg] ) { block }`                       | 与えられたブロックはシンボルをスローすると主張する。|
| `assert_raises( exception1, exception2, ... ) { block }`         | 渡されたブロックから、渡された例外のいずれかが発生すると主張する。|
| `assert_instance_of( class, obj, [msg] )`                        | `obj`は`class`のインスタンスであると主張する。|
| `assert_not_instance_of( class, obj, [msg] )`                    | `obj`は`class`のインスタンスではないと主張する。|
| `assert_kind_of( class, obj, [msg] )`                            | `obj`は`class`またはそのサブクラスのインスタンスであると主張する。|
| `assert_not_kind_of( class, obj, [msg] )`                        | `obj`は`class`またはそのサブクラスのインスタンスではないと主張する。|
| `assert_respond_to( obj, symbol, [msg] )`                        | `obj`は`symbol`に応答すると主張する。|
| `assert_not_respond_to( obj, symbol, [msg] )`                    | `obj`は`symbol`に応答しないと主張する。|
| `assert_operator( obj1, operator, [obj2], [msg] )`               | `obj1.operator(obj2)`はtrueであると主張する。|
| `assert_not_operator( obj1, operator, [obj2], [msg] )`           | `obj1.operator(obj2)`はfalseであると主張する。|
| `assert_predicate ( obj, predicate, [msg] )`                     | `obj.predicate`はtrueであると主張する (例:`assert_predicate str, :empty?`)。|
| `assert_not_predicate ( obj, predicate, [msg] )`                 | `obj.predicate`はfalseであると主張する(例:`assert_not_predicate str, :empty?`)。|
| `flunk( [msg] )`                                                 | 必ず失敗すると主張する。これはテストが未完成であることを示すのに便利。|

これらはMinitestがサポートするアサーションの一部に過ぎません。最新の完全なアサーションのリストについては[Minitest APIドキュメント](http://docs.seattlerb.org/minitest/)、特に[`Minitest::Assertions`](http://docs.seattlerb.org/minitest/Minitest/Assertions.html)を参照してください。

テスティングフレームワークはモジュール化されているので、アサーションを自作して利用することもできます。実際、Railsはまさにそれを行っているのです。Railsには開発を楽にしてくれる特殊なアサーションがいくつも追加されています。

NOTE: アサーションの自作は高度なトピックなので、このチュートリアルでは扱いません。

### Rails固有のアサーション

Railsは`minitest`フレームワークに以下のような独自のカスタムアサーションを追加しています。

| アサーション                                                                         | 目的 |
| --------------------------------------------------------------------------------- | ------- |
| [`assert_difference(expressions, difference = 1, message = nil) {...}`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_difference) | yieldされたブロックで評価された結果である式の戻り値における数値の違いをテストする。|
| [`assert_no_difference(expressions, message = nil, &block)`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_difference) | 式を評価した結果の数値は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがないと主張する。|
| [`assert_changes(expressions, message = nil, from:, to:, &block)`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_changes) | 式を評価した結果は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがあると主張する。|
| [`assert_no_changes(expressions, message = nil, &block)`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_changes) | 式を評価した結果は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがないと主張する。|
| [`assert_nothing_raised { block }`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_nothing_raised) | 渡されたブロックで例外が発生しないことを確認する。|
| [`assert_recognizes(expected_options, path, extras={}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_recognizes) | 渡されたパスのルーティングが正しく扱われ、(expected_optionsハッシュで渡された) 解析オプションがパスと一致したことを主張する。基本的にこのアサーションでは、Railsはexpected_optionsで渡されたルーティングを認識すると主張する。|
| [`assert_generates(expected_path, options, defaults={}, extras = {}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_generates) | 渡されたオプションは、渡されたパスの生成に使えるものであると主張する。assert_recognizesと逆の動作。extrasパラメータは、クエリ文字列に追加リクエストがある場合にそのパラメータの名前と値をリクエストに渡すのに使われる。messageパラメータはアサーションが失敗した場合のカスタムエラーメッセージを渡すことができる。|
| [`assert_response(type, message = nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_response) | レスポンスが特定のステータスコードを持っていることを主張する。`:success`を指定するとステータスコード200-299を指定したことになり、同様に`:redirect`は300-399、`:missing`は404、`:error`は500-599にそれぞれマッチする。ステータスコードの数字や同等のシンボルを直接渡すこともできる。詳細については[ステータスコードの完全なリスト](http://rubydoc.info/github/rack/rack/master/Rack/Utils#HTTP_STATUS_CODES-constant)および[シンボルとステータスコードの対応リスト](http://rubydoc.info/github/rack/rack/master/Rack/Utils#SYMBOL_TO_STATUS_CODE-constant)を参照のこと。|
| [`assert_redirected_to(options = {}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_redirected_to) | 渡されたリダイレクトオプションが、最後に実行されたアクションで呼び出されたリダイレクトのオプションと一致することを主張する。このアサーションは部分マッチ可能。たとえば`assert_redirected_to(controller: "weblog")`は`redirect_to(controller: "weblog", action: "show")`というリダイレクトなどにもマッチする。`assert_redirected_to root_path`などの名前付きルートを渡したり、`assert_redirected_to @article`などのActive Recordオブジェクトを渡すこともできる。|

これらのアサーションのいくつかについては次の章でご説明します。

### テストケースに関する補足事項

`Minitest::Assertions`に定義されている`assert_equal`などの基本的なアサーションは、あらゆるテストケース内で用いられているクラスで利用できます。実際には、以下から継承したクラスもRailsで利用できます。

* [`ActiveSupport::TestCase`](http://api.rubyonrails.org/classes/ActiveSupport/TestCase.html)
* [`ActionMailer::TestCase`](http://api.rubyonrails.org/classes/ActionMailer/TestCase.html)
* [`ActionView::TestCase`](http://api.rubyonrails.org/classes/ActionView/TestCase.html)
* [`ActiveJob::TestCase`](http://api.rubyonrails.org/classes/ActiveJob/TestCase.html)
* [`ActionDispatch::IntegrationTest`](http://api.rubyonrails.org/classes/ActionDispatch/IntegrationTest.html)
* [`ActionDispatch::SystemTestCase`](http://api.rubyonrails.org/classes/ActionDispatch/SystemTestCase.html)
* [`Rails::Generators::TestCase`](http://api.rubyonrails.org/classes/Rails/Generators/TestCase.html)

各クラスには`Minitest::Assertions`が含まれているので、どのテストでも基本的なアサーションを利用できます。

NOTE: `Minitest`について詳しくは、[Minitestのドキュメント](http://docs.seattlerb.org/minitest)を参照してください。

### Railsのテストランナー

`bin/rails test`コマンドを使ってすべてのテストを一括実行できます。

個別のテストファイルを実行するには、`bin/rails test`コマンドにそのテストケースを含むファイル名を渡します。

```bash
$ bin/rails test test/models/article_test.rb
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
Run options: -n test_the_truth --seed 43583

# Running:

.

Finished tests in 0.009064s, 110.3266 tests/s, 110.3266 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
```

行番号を指定すると、特定の行だけをテストできます。


```bash
$ bin/rails test test/models/article_test.rb:6 # run specific test and line
```

ディレクトリを指定すると、そのディレクトリ内のすべてのテストを実行できます。

```bash
$ bin/rails test test/controllers # run all tests from specific directory
```

テストランナーではこの他にも、「failing fast」やテスト終了時に必ずテストを出力するといったさまざまな機能が使えます。次を実行してテストランナーのドキュメントをチェックしてみましょう。

```bash
$ bin/rails test -h
minitest options:
    -h, --help                       Display this help.
    -s, --seed SEED                  Sets random seed. Also via env. Eg: SEED=n rake
    -v, --verbose                    Verbose. Show progress processing files.
    -n, --name PATTERN               Filter run on /regexp/ or string.
        --exclude PATTERN            Exclude /regexp/ or string from run.

Known extensions: rails, pride

Usage: bin/rails test [options] [files or directories]
You can run a single test by appending a line number to a filename:

    bin/rails test test/models/user_test.rb:27

You can run multiple files and directories at the same time:

    bin/rails test test/controllers test/integration/login_test.rb

By default test failures and errors are reported inline during a run.

Rails options:
    -w, --warnings                   Run with Ruby warnings enabled
    -e, --environment                Run tests in the ENV environment
    -b, --backtrace                  Show the complete backtrace
    -d, --defer-output               Output test failures and errors after the test run
    -f, --fail-fast                  Abort test run on first failure or error
    -c, --[no-]color                 Enable color in the output
```

テスト用データベース
-----------------------

Railsアプリケーションは、ほぼ間違いなくデータベースと密接なやりとりを行いますので、テスティングにもデータベースが必要となります。効率のよいテストを作成するには、データベースの設定方法とサンプルデータの導入方法を理解しておく必要があります。

デフォルトでは、すべてのRailsアプリケーションにはdevelopment、test、productionの3つの環境があります。それぞれの環境におけるデータベース設定は`config/database.yml`で行います。

テスティング専用のデータベースを用いることで、それを設定して他の環境から切り離された専用のテストデータにアクセスできます。これにより、development環境やproduction環境のデータベースにあるデータを気にすることなく確実なテストを実行できます。

### テストデータベースのスキーマを管理する

テストを実行するには、テストデータベースが最新の状態で構成されている必要があります。テストヘルパーは、テストデータベースに未完了のマイグレーションが残っていないかどうかをチェックします。マイグレーションがすべて終わっている場合、`db/schema.rb`や`db/structure.sql`をテストデータベースに読み込みます。ペンディングされたマイグレーションがある場合、エラーが発生します。このエラーが発生するということは、スキーマのマイグレーションが不完全であることを意味します。developmentデータベースに対してマイグレーション（`bin/rails db:migrate`）を実行することで、スキーマが最新の状態になります。

NOTE: 既存のマイグレーションに変更が加えられていると、テストデータベースを再構築する必要があります。`bin/rails db:test:prepare`を実行することで再構築できます。

### フィクスチャのしくみ

よいテストを作成するにはよいテストデータを準備する必要があることを理解しておく必要があります。
Railsでは、テストデータの定義とカスタマイズはフィクスチャで行うことができます。
網羅的なドキュメントについては、[フィクスチャAPIドキュメント](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)を参照してください。

#### フィクスチャとは何か

**フィクスチャ (fixture)**とは、いわゆるサンプルデータを言い換えたものです。フィクスチャを使うことで、事前に定義したデータをテスト実行直前にtestデータベースに導入することができます。フィクスチャはYAMLで記述され、特定のデータベースに依存しません。1つのモデルにつき1つのフィクスチャファイルが作成されます。

NOTE: フィクスチャは、テストで必要なありとあらゆるオブジェクトを作成できる設計ではありません。フィクスチャを最適に管理するには、よくあるテストケースに適用可能なデフォルトデータのみを用いることです。

フィクスチャファイルは`test/fixtures`の下に置かれます。`rails generate model`を実行してモデルを新規作成すると、モデルのフィクスチャスタブが自動的に作成され、このディレクトリに置かれます。

#### YAML

YAML形式のフィクスチャは人間にとってとても読みやすく、サンプルデータを容易に記述できます。この形式のフィクスチャには**.yml**というファイル拡張子が与えられます (`users.yml`など)。

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

各フィクスチャは名前とコロンで始まり、その後にコロンで区切られたキー/値ペアのリストがインデント付きで置かれます。通常、レコード間は空行で区切られます。行の先頭に#文字を置くことで、フィクスチャファイルにコメントを追加できます。'yes'や'no'などのYAMLキーワードに似たキーについては、引用符で囲むことでYAMLパーサーが正常に動作できます。

[関連付け](/association_basics.html)を使っている場合は、2つの異なるフィクスチャの間に参照ノードを1つ定義すれば済みます。belongs_to/has_many関連付けの例を以下に示します。

```yaml
# fixtures/categories.ymlの内容:
about:
  name: About

# fixtures/articles.ymlの内容
first:
  title: Welcome to Rails!
  body: Hello world!
  category: about
```

`fixtures/articles.yml`ファイル内の`first`の記事にある`category`キーの値が`about`になっていることにご注目ください。これは`fixtures/categories.yml`内の`about`カテゴリを読み込むようRailsに指示するためのものです。

NOTE: 関連付けが名前で互いを参照している場合、関連付けられたフィクスチャにある`id:`属性を指定する代わりに、フィクスチャ名を使えます。Railsはテストの実行中に、自動的に主キーを割り当てて一貫性を保ちます。関連付けの詳しい動作については、[フィクスチャAPIドキュメント](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)を参照してください。

#### ERB

ERBは、テンプレート内にRubyコードを埋め込むのに使われます。YAMLフィクスチャ形式のファイルは、Railsに読み込まれたときにERBによる事前処理が行われます。ERBを活用すれば、Rubyで一部のサンプルデータを生成できます。たとえば、以下のコードを使えば1000人のユーザーを生成できます。

```erb
<% 1000.times do |n| %>
user_<%= n %>:
  username: <%= "user#{n}" %>
  email: <%= "user#{n}@example.com" %>
<% end %>
```

#### フィクスチャの動作

Railsはデフォルトで、`test/fixtures`フォルダにあるすべてのフィクスチャを自動的に読み込み、モデルやコントローラのテストで利用します。フィクスチャの読み込みは主に以下の3つの手順からなります。

1. フィクスチャに対応するテーブルに含まれている既存のデータをすべて削除する
2. フィクスチャのデータをテーブルに読み込む
3. フィクスチャに直接アクセスしたい場合はフィクスチャのデータをメソッドにダンプする

TIP: Railsでは、データベースから既存のデータベースを削除するために外部キーやチェック制約といった参照整合性（referential integrity）トリガを無効にしようとします。テスト実行時のパーミッションエラーが発生して困っている場合は、test環境のデータベースユーザーがこれらのトリガを無効にする特権を持っていることをご確認ください（PostgreSQLの場合、すべてのトリガを無効にできるのはsuperuserのみです。PostgreSQLのパーミッションについて詳しくは[こちらの記事](http://blog.endpoint.com/2012/10/postgres-system-triggers-error.html)を参照してください）。

#### フィクスチャはActive Recordオブジェクト

フィクスチャは、実はActive Recordのインスタンスです。前述の3番目の手順にもあるように、フィクスチャはスコープがテストケースのローカルになっているメソッドを自動的に利用可能にしてくれるので、フィクスチャのオブジェクトに直接アクセスできます。以下に例を示します。

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
# this will return an array containing the fixtures david and steve
users(:david, :steve)
```

モデルテスト
-------------

モデルのテストは、アプリケーションのさまざまなモデルをテストするのに使われます。

Railsのモデルテストは`test/models`ディレクトリの下に保存されます。Railsではモデルテストのスケルトンを生成するジェネレータが提供されています。

```bash
$ bin/rails generate test_unit:model article title:string body:text
create  test/models/article_test.rb
create  test/fixtures/articles.yml
```

モデルテストには`ActionMailer::TestCase`のような独自のスーパークラスがなく、代わりに[`ActiveSupport::TestCase`](http://api.rubyonrails.org/classes/ActiveSupport/TestCase.html)を継承します。

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

### デフォルト設定の変更

Railsのシステムテストのデフォルト設定変更方法は非常にシンプルです。すべての設定が抽象化されているので、テストの作成に集中できます。

新しいアプリケーションやscaffoldを生成すると、そのテストのディレクトリに`application_system_test_case.rb`ファイルが作成されます。システムテストの設定はすべてここで行います。

デフォルト設定を変更したい場合は、システムテストの`driven_by`項目を変更できます。たとえばドライバをSeleniumからPoltergeistに変更する場合は、まず`poltergeist` gemをGemfileに追加し、続いて`application_system_test_case.rb`を以下のように変更します。


```ruby
require "test_helper"
require "capybara/poltergeist"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :poltergeist
end
```

このドライバ名は`driven_by`で必要な引数です。`driven_by`に渡せるオプション引数としては、他に`:using`（ブラウザを指定する、Seleniumでのみ有効）や`:screen_size`（スクリーンショットのサイズ変更）、`:options`（ドライバでサポートされるオプションの指定）があります。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :firefox
end
```

ヘッドレスブラウザを使いたい場合は、`:using`引数に`headless_chrome`を追加します。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome
end
```

Railsで提供されていないCapybara設定が必要な場合は、`application_system_test_case.rb`ファイルに設定を追加できます。

追加設定については[Capybaraのドキュメント](https://github.com/teamcapybara/capybara#setup)を参照してください。

### スクリーンショットヘルパー

`ScreenshotHelper`は、テスト中のスクリーンショットをキャプチャするよう設計されたヘルパーで、テストが失敗した時点のブラウザ画面を確認するときや、デバッグでスクリーンショットを確認するときに有用です。

`take_screenshot`メソッドおよび`take_failed_screenshot`メソッドが提供されており、`take_failed_screenshot`はRails内部の`after_teardown`に自動的に含まれます。

`take_screenshot`ヘルパーメソッドはテストのどこにでも書くことができ、ブラウザのスクリーンショット撮影に使えます。

### システムテストを実装する

それではブログアプリケーションにシステムテストを追加することにしましょう。システムテストで最初にindexページを表示し、新しいブログ記事を1件作成します。

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

このテストは記事のindexページに`h1`が存在していればパスします。

システムテストを実行します。

```bash
bin/rails test:system
```

NOTE: デフォルトでは`bin/rails test`を実行してもシステムテストが実行されません。実際にシステムテストを実行するには`bin/rails test:system`を実行してください。

#### 記事のシステムテストを作成する

それではブログで新しい記事を作成するフローをテストしましょう。

```ruby
test "creating an article" do
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

次に記事のタイトルと本文に指定のテキストを入力しています。フィールドへの入力が終わったら「Create Article」をクリックして、データベースに新しい記事を作成するPOSTリクエストを送信しています。

そして記事の元のindexページにリダイレクトされ、新しい記事のタイトルがその記事のindexページに表示されます。

#### システムテストの利用法

システムテストの長所は、ユーザーによるやり取りをコントローラやモデルやビューを用いてテストできるという点で結合テストに似ていますが、本物のユーザーが操作しているかのようにテストを実際に実行できるため、ずっと頑丈です。ユーザーがアプリケーションで行える操作であれば、コメント入力や記事の削除、ドラフト記事の公開など何でも行えます。

結合テスト
-------------------

結合テスト (integration test) は、複数のコントローラ同士のやりとりをテストします。一般に、アプリケーション内の重要なワークフローのテストに使われます。

Railsの結合テストは、アプリケーションの`test/integration`ディレクトリに作成します。Railsでは結合テストのスケルトンを生成するジェネレータが提供されています。

```bash
$ bin/rails generate integration_test user_flows
      exists  test/integration/
      create  test/integration/user_flows_test.rb
```

生成直後の結合テストは以下のような内容になっています。

```ruby
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
```

結合テストは`ActionDispatch::IntegrationTest`から継承されます。これにより、結合テスト内でさまざまなヘルパーが利用できます。

### 結合テストで利用できるヘルパー

システムテストでは、標準のテストヘルパー以外にも`ActionDispatch::IntegrationTest`から継承されるいくつかのヘルパーを利用できます。その中から3つのカテゴリについて簡単にご紹介します。

結合テストランナーについては[`ActionDispatch::Integration::Runner`](http://api.rubyonrails.org/classes/ActionDispatch/Integration/Runner.html)を参照してください。

リクエストの実行については[`ActionDispatch::Integration::RequestHelpers`](http://api.rubyonrails.org/classes/ActionDispatch/Integration/RequestHelpers.html)にあるヘルパーを用いることにします。

セッションを改変する必要がある場合や、結合テストのステートを変更する必要がある場合は、[`ActionDispatch::Integration::Session`](http://api.rubyonrails.org/classes/ActionDispatch/Integration/Session.html)を参照してください。

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
require 'test_helper'

class BlogFlowTest < ActionDispatch::IntegrationTest
  test "can see the welcome page" do
    get "/"
    assert_select "h1", "Welcome#index"
  end
end
```

リクエストで生成されるHTMLをテストする`assert_select`についてはこの後の「ビューをテストする」で言及します。これはリクエストに対するレスポンスのテストに用いるもので、重要なHTML要素がコンテンツに存在するというアサーションを行います。

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

次に`Articles`コントローラの`:create`アクションを呼びます。


```ruby
post "/articles",
  params: { article: { title: "can create", body: "article successfully." } }
assert_response :redirect
follow_redirect!
```

その次の2行では、記事が1件作成されるときのリクエストのリダイレクトを扱います。

NOTE: リダイレクト実行後に続いて別のリクエストを行う予定があるのであれば、`follow_redirect!`を呼び出すことを忘れずに。

最後は、レスポンスが成功して記事がページ上で読める状態になっているというアサーションです。

#### 結合テストの利用法

ブログを表示して記事を1件作成するという、きわめて小規模なワークフローを無事テストできました。このテストにコメントを追加するもよし、記事の削除や編集のテストを行うもよしです。結合テストは、アプリケーションのあらゆるユースケースに伴うエクスペリエンスのテストに向いています。

コントローラの機能テスト
-------------------------------------

Railsで1つのコントローラに含まれる複数のアクションをテストを作成することを、「コントローラに対する機能テスト (functional test) を作成する」と呼んでいます。コントローラはアプリケーションが受け付けたWebリクエストを処理し、レンダリングされたビューの形で最終的なレスポンスを返すことを思い出しましょう。機能テストでは、アクションがリクエストや期待される結果（レスポンス、場合によってはHTMLビュー）をどう扱っているかをテストします。

### 機能テストに含める項目

機能テストでは以下のようなテスト項目を実施する必要があります。

* Webリクエストが成功したか
* 正しいページにリダイレクトされたか
* ユーザー認証が成功したか
* レスポンスのテンプレートに正しいオブジェクトが保存されたか
* ビューに表示されたメッセージは適切か

実際の機能テストを最も簡単に見る方法は、scaffoldジェネレータでコントローラを生成することです。

```bash
$ bin/rails generate scaffold_controller article title:string body:text
...
create  app/controllers/articles_controller.rb
...
invoke  test_unit
create    test/controllers/articles_controller_test.rb
...
```

`Article`リソースのコントローラコードとテストが生成され、`test/controllers`にある`articles_controller_test.rb`ファイルを開けるようになります。

既にコントローラがあり、7つのデフォルトのアクションごとにテスト用のscaffoldコードだけを生成したい場合は、以下のコマンドを実行します。

```bash
$ bin/rails generate test_unit:scaffold article
...
invoke  test_unit
create    test/controllers/articles_controller_test.rb
...
```

`articles_controller_test.rb`ファイルの`test_should_get_index`というテストについて見てみます。

```ruby
# articles_controller_test.rb
class ArticlesControllerTest < ActionDispatch::IntegrationTest
   test "should get index" do
     get articles_url
     assert_response :success
  end
end
```

`test_should_get_index`というテストでは、Railsが`index`という名前のアクションに対するリクエストをシミュレートします。同時に、有効な`articles`インスタンス変数がコントローラに割り当てられます。

`get`メソッドはWebリクエストを開始し、結果を`@response`として返します。このメソッドには以下の6つの引数を渡すことができます。

* リクエストするコントローラアクションのURI。
  これは文字列ヘルパーかルーティングヘルパーの形を取る（`articles_url`など）。
* `params`: アクションに渡すリクエストパラメータのハッシュ（クエリの文字列パラメータまたはarticle変数など）。
* `headers`: リクエストで渡されるヘッダーの設定に用いる。
* `env`: リクエストの環境を必要に応じてカスタマイズするのに用いる。
* `xhr`: リクエストがAjaxかどうかを指定する。Ajaxの場合は`tue`を設定。
* `as`: 別のcontent typeでエンコードされているリクエストに用いる。デフォルトで`:json`をサポート。

上のキーワード引数はすべてオプションです。

例: `:show`アクションを呼び出し、`id`に12を指定して`params`として渡し、`HTTP_REFERER`ヘッダを設定する。

```ruby
get article_url, params: { id: 12 }, headers: { "HTTP_REFERER" => "http://example.com/home" }
```

別の例: `:update`アクションを呼び出し、`id`に12を指定し、Ajaxのリクエストの`params`として渡す。

```ruby
patch article_url, params: { id: 12 }, xhr: true
```

NOTE: `articles_controller_test.rb`ファイルにある`test_should_create_article`テストを実行してみると、モデルレベルのバリデーションが新たに追加されることによってテストは失敗します。

`articles_controller_test.rb`ファイルの`test_should_create_article`テストを変更して、テストがパスするようにしてみましょう。

```ruby
test "should create article" do
  assert_difference('Article.count') do
    post articles_url, params: { article: { body: 'Rails is awesome!', title: 'Hello Rails' } }
  end

  assert_redirected_to article_path(Article.last)
end
```

これで、すべてのテストを実行するとパスするようになったはずです。

NOTE: 「BASIC認証」セクションの手順に沿う場合は、すべてのテストをパスさせるために`setup`ブロックに以下を追加する必要があります。

```ruby
request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.
  encode_credentials('dhh', 'secret')
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

NOTE: 機能テストによる検証では、そのリクエストがアクションで受け付けられるかどうかよりも結果を重視します。アクションが受け付けられるかどうかについては、リクエストテストの方が適切です。

### XHR（AJAX）リクエストをテストする

`get`、`post`、`patch`、`put`、 `delete`メソッドで次のように`xhr: true`を指定することで、AJAXリクエストをテストできます。

```ruby
test "ajax request" do
  article = articles(:one)
  get article_url(article), xhr: true

  assert_equal 'hello world', @response.body
  assert_equal "text/javascript", @response.content_type
end
```

### 「暗黙の」3つのハッシュ

リクエストが完了して処理されると、以下の3つのハッシュオブジェクトが利用可能になります。

* `cookies` - 設定されているすべてのcookies。
* `flash` - flash内のすべてのオブジェクト。
* `session` - セッション変数に含まれるすべてのオブジェクト。

これらのハッシュは、通常のHashオブジェクトと同様に文字列をキーとして値を参照できます。たとえば次のようにシンボル名による参照も可能です。

```ruby
flash["gordon"]               flash[:gordon]
session["shmession"]          session[:shmession]
cookies["are_good_for_u"]     cookies[:are_good_for_u]
```

### 利用可能なインスタンス変数

機能テストでは、1つのリクエストの完了ごとに以下の3つの専用インスタンス変数を使えます。

* `@controller` - リクエストを処理するコントローラ
* `@request` - リクエストオブジェクト
* `@response` - レスポンスオブジェクト

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

[HTTPヘッダー](http://tools.ietf.org/search/rfc2616#section-5.3)と[CGI変数](http://tools.ietf.org/search/rfc3875#section-4.1)はヘッダーとして渡されます。

```ruby
# HTTPヘッダーを設定する
get articles_url, headers: { "Content-Type": "text/plain" } # simulate the request with custom header

# CGI変数を設定する
get articles_url, headers: { "HTTP_REFERER": "http://example.com/home" } # simulate the request with custom env variable
```

### `flash`通知をテストする

`flash`は、上述の「暗黙の」3つのヘッダーの1つです。

誰かがこのブログアプリケーションで記事を1件作成するのに成功したら`flash`メッセージを追加したいと思います。

このアサーションを`test_should_create_article`テストに追加してみましょう。

```ruby
test "should create article" do
  assert_difference('Article.count') do
    post article_url, params: { article: { title: 'Some title' } }
  end

  assert_redirected_to article_path(Article.last)
  assert_equal 'Article was successfully created.', flash[:notice]
end
```

この時点でテストを実行すると、以下のように失敗するはずです。

```bash
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
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
    flash[:notice] = 'Article was successfully created.'
    redirect_to @article
  else
    render 'new'
  end
end
```

テストを実行すると、今度はパスするはずです。

```bash
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Run options: -n test_should_create_article --seed 18981

# Running:

.

Finished in 0.081972s, 12.1993 runs/s, 48.7972 assertions/s.

1 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

### テストをまとめて行う

この時点での`Articles`コントローラの`:index`アクションは`:new`や`:create`と同様にテストされるようになりました。既存のデータの扱いはどう書くのでしょうか？

`:show`アクションのテストを書いてみましょう。

```ruby
test "should show article" do
  article = articles(:one)
  get article_url(article)
  assert_response :success
end
```

記事の削除は次のようにテストします。

```ruby
test "should destroy article" do
  article = articles(:one)
  assert_difference('Article.count', -1) do
    delete article_url(article)
  end
  assert_redirected_to articles_path
end
```

既存の記事の更新も次のように書けます。

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

3つのテストは、どれも同じArticleフィクスチャデータへのアクセスを行っており、少々重複していますので、DRYにしましょう。これは`ActiveSupport::Callbacks`が提供する`setup`メソッドと`teardown`メソッドで行います。

ここまでで、テストは次のようになっているはずです。残りのテストはとりあえずこのままにしておくことにします。

```ruby
require 'test_helper'
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
    assert_difference('Article.count', -1) do
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

Railsの他のコールバックと同様、`setup`メソッドと`teardown`メソッドにブロックやlambdaを渡したりメソッド名のシンボルで呼び出すこともできます。

### テストヘルパー

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
require 'test_helper'
class ProfileControllerTest < ActionDispatch::IntegrationTest

  test "should show profile" do
    # ヘルパーがどのコントローラテストケースでも再利用可能になっている
    sign_in_as users(:david)

    get profile_url
    assert_response :success
  end
end		
```

ルーティングをテストする
--------------

Railsアプリケーションの他のあらゆる部分と同様、ルーティングもテストできます。ルーティングのテストは`test/controllers/`に配置するか、コントローラテストの一部として書きます。

NOTE: アプリケーションのルーティングが複雑な場合は、Railsが提供する多くの便利なルーティングヘルパーを使えます。

Railsで使えるルーティングアサーションについて詳しくは、[`ActionDispatch::Assertions::RoutingAssertions`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html)のAPIドキュメントを参照してください。

ビューをテストする
-------------

リクエストに対するレスポンスをテストするために、あるページで重要なHTML要素とその内容がレスポンスに含まれているアサーションを書くのはアプリケーションのビューのテストでよく行われることです。`assert_select`というアサーションを使うと、こうしたテストで簡潔かつ強力な文法を利用できるようになります。

`assert_select`には2つの書式があります。

`assert_select(セレクタ, [条件], [メッセージ])`という書式は、セレクタで指定された要素が条件に一致することを主張します。セレクタにはCSSセレクタの式 (文字列) や代入値を持つ式を使えます。

`assert_select(要素, セレクタ, [条件], [メッセージ])` は、選択されたすべての要素が条件に一致することを主張します。選択される要素は、_element_ (`Nokogiri::XML::Node` or `Nokogiri::XML::NodeSet`のインスタンス) からその子孫要素までの範囲から選択されます。

たとえば、レスポンスに含まれるtitle要素の内容を検証するには、以下のアサーションを使います。

```ruby
assert_select 'title', "Welcome to Rails Testing Guide"
```

より詳しくテストするために、ネストした`assert_select`ブロックを用いることもできます。

以下の例の場合、外側の`assert_select`で選択されたすべての要素の完全なコレクションに対して、内側の`assert_select`がアサーションを実行します。

```ruby
assert_select 'ul.navigation' do
  assert_select 'li.menu_item'
end
```

選択された要素のコレクションをイテレート (列挙) し、`assert_select`が要素ごとに呼び出されるようにすることもできます。

たとえば、レスポンスに2つの順序付きリストがあり、1つの順序付きリストにつき要素が4つあれば、以下のテストはどちらもパスします。

```ruby
assert_select "ol" do |elements|
  elements.each do |element|
    assert_select element, "li", 4
  end
end

assert_select "ol" do
  assert_select "li", 8
end
```

`assert_select`はきわめて強力なアサーションです。このアサーションの高度な利用法については[ドキュメント](https://github.com/rails/rails-dom-testing/blob/master/lib/rails/dom/testing/assertions/selector_assertions.rb)を参照してください。

#### その他のビューベースのアサーション

主にビューをテストするためのアサーションは他にもあります。

| アサーション                                                 | 目的 |
| --------------------------------------------------------- | ------- |
| `assert_select_email`                                     | メールの本文に対するアサーションを行なう。 |
| `assert_select_encoded`                                   | エンコードされたHTMLに対するアサーションを行なう。各要素の内容はデコードされた後にそれらをブロックとして呼び出す。|
| `css_select(selector)`または`css_select(element, selector)` | _selector_で選択されたすべての要素を1つの配列にしたものを返す。2番目の書式については、最初に_element_がベース要素としてマッチし、続いてそのすべての子孫に対して_selector_のマッチを試みる。どちらの場合も、何も一致しなかった場合には空の配列を1つ返す。|

`assert_select_email`の利用例を以下に示します。

```ruby
assert_select_email do
  assert_select 'small', 'オプトアウトしたい場合は "購読停止" をクリックしてください。'
end
```

ヘルパーをテストする
---------------

ヘルパー自体は単なるシンプルなモジュールであり、ビューから利用するヘルパーメソッドをこの中に定義します。

ヘルパーのテストについては、ヘルパーメソッドの出力が期待どおりであるかどうかをチェックするだけで十分です。ヘルパー関連のテストは`test/helpers`ディレクトリに置かれます。

以下のようなヘルパーがあるとします。

```ruby
module UserHelper
  def link_to_user(user)
    link_to "#{user.first_name} #{user.last_name}", user
  end
end
```

このメソッドの出力は次のようにしてテストできます。

```ruby
class UserHelperTest < ActionView::TestCase
  test "should return the user's full name" do
    user = users(:david)

    assert_dom_equal %{<a href="/user/#{user.id}">David Heinemeier Hansson</a>}, link_to_user(user)
  end
end
```

さらに、テストクラスは`ActionView::TestCase`をextendしたものなので、`link_to`や`pluralize`などのRailsヘルパーメソッドにアクセスできます。


メイラーをテストする
--------------------

メイラークラスを十分にテストするためには特殊なツールが若干必要になります。

### メイラーのテストについて

Railsアプリケーションの他の部分と同様、メイラークラスについても期待どおり動作するかどうかをテストする必要があります。

メイラークラスをテストする目的は以下を確認することです。

* メールが処理 (作成および送信) されていること
* メールの内容 (subject、sender、bodyなど) が正しいこと
* 適切なメールが適切なタイミングで送信されていること

#### あらゆる側面からのチェック

メイラーのテストには単体テストと機能テストの2つの側面があります。単体テストでは、完全に制御された入力を与えた結果の出力と、期待される既知の値 (フィクスチャー) とを比較します。機能テストではメイラーによって作成される詳細部分についてのテストはほとんど行わず、コントローラとモデルがメイラーを正しく利用しているかどうかをテストするのが普通です。メイラーのテストは、最終的に適切なメールが適切なタイミングで送信されたことを立証するために行います。

### 単体テスト

メイラーが期待どおりに動作しているかどうかをテストするために、事前に作成しておいた出力例と、メイラーの実際の出力を比較するという単体テストを行なうことができます。

#### フィクスチャーの逆襲

メイラーの単体テストを行なうために、フィクスチャーを利用してメイラーが最終的に出力すべき外見の例を与えます。これらのフィクスチャーはメールの出力例であって、通常のフィクスチャーのようなActive Recordデータではないので、通常のフィクスチャーとは別の専用のサブディレクトリに保存します。`test/fixtures`ディレクトリの下のディレクトリ名は、メイラーの名前に対応させてください。たとえば`UserMailer`という名前のメイラーであれば、`test/fixtures/user_mailer`というスネークケースのディレクトリ名にします。

メイラーを生成しても、メイラーのアクションに対応するスタブフィクスチャーは生成されません。これらのファイルは上述の方法で手動作成する必要があります。

#### 基本的なテストケース

`invite`というアクションで知人に招待状を送信する`UserMailer`という名前のメイラーに対する単体テストを以下に示します。これは、`invite`アクションをジェネレータで生成したときに作成される基本的なテストに手を加えたものです。

```ruby
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # さらにアサーションを行うためにメールを作成して保存
    email = UserMailer.create_invite('me@example.com',
                                     'friend@example.com', Time.now)

    # メールを送信後キューに追加されるかどうかをテスト
    assert_emails 1 do
      email.deliver_now
    end

    # 送信されたメールの本文が期待どおりの内容であるかどうかをテスト
    assert_equal ['me@example.com'], email.from
    assert_equal ['friend@example.com'], email.to
    assert_equal 'You have been invited by me@example.com', email.subject
    assert_equal read_fixture('invite').join, email.body.to_s
  end
end
```

このテストでは、メールを送信し、その結果返されたオブジェクトを`email`変数に保存します。続いて、このメールが送信されたことを主張します (最初のアサーション)。次のアサーションでは、メールの内容が期待どおりであることを主張します。このファイルの内容を`read_fixture`ヘルパーで読み出しています。

NOTE: `email.body.to_s`は、HTMLまたはテキストで1回出現した場合にのみ存在するとみなされます。メイラーがどちらも提供している場合は、 `email.text_part.body.to_s`や`email.html_part.body.to_s`を用いてそれぞれの一部に対するフィクスチャをテストできます。

`invite`フィクスチャーは以下のような内容にしておきます。

```
friend@example.comさん、こんにちは。

招待状を送付いたします。

どうぞよろしく!
```

ここでメイラーのテスト作成方法の詳細部分についてご説明したいと思います。`config/environments/test.rb`の`ActionMailer::Base.delivery_method = :test`という行で送信モードをtestに設定しています。これにより、送信したメールが実際に配信されないようにできます。そうしないと、テスト中にユーザーにスパムメールを送りつけてしまうことになります。この設定で送信したメールは、`ActionMailer::Base.deliveries`という配列に追加されます。

NOTE: この`ActionMailer::Base.deliveries`という配列は、`ActionMailer::TestCase`と`ActionDispatch::IntegrationTest`でのテストを除き、自動的にはリセットされません。それらのテストの外で配列をクリアしたい場合は、`ActionMailer::Base.deliveries.clear`で手動リセットできます。

### 機能テスト

メイラーの機能テストでは、メール本文や受取人が正しいことを確認するなど、単体テストでカバーされているようなことは扱いません。メールの機能テストでは、メール配信メソッドを呼び出し、その結果適切なメールが配信リストに追加されるかどうかをチェックします。機能テストでは配信メソッド自体は正常に動作すると仮定することになりますが、これでまず問題ありません。機能テストでは、期待されたタイミングでアプリケーションのビジネスロジックからメールが送信されるかどうかをテストすることがメインになるのが普通だからです。たとえば、友人を招待するという操作によってメールが適切に送信されるかどうかをチェックするには以下のような機能テストを使います。

```ruby
require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  test "invite friend" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post invite_friend_url, params: { email: 'friend@example.com' }
    end
    invite_email = ActionMailer::Base.deliveries.last

    assert_equal "You have been invited by me@example.com", invite_email.subject
    assert_equal 'friend@example.com', invite_email.to[0]
    assert_match(/Hi friend@example\.com/, invite_email.body.to_s)
  end
end
```


ジョブをテストする
------------

カスタムジョブはアプリケーション内部のさまざまなレベルでキューイングされるため、ジョブそのもの（キューイングされるときの振る舞い）と、その他のエンティティが正常にキューイングされるかどうかを両方テストする必要があります。

### 基本のテストケース

デフォルトではジョブを1つ作成すると、ジョブに関連するテストが`test/jobs`ディレクトリの下にも生成されます。以下は請求ジョブの例です。

```ruby
require 'test_helper'

class BillingJobTest < ActiveJob::TestCase
  test 'that account is charged' do
    BillingJob.perform_now(account, product)
    assert account.reload.charged_for?(product)
  end
end
```

このテストは、ジョブが期待どおり動作したというアサーションのみを行うかなりシンプルなものです。

デフォルトでは`ActiveJob::TestCase`がキューアダプタを`:test`に設定してジョブがインラインで実行されるようにします。また、それまでに実行されキューイングされたジョブを各テスト前にすべてクリアして、各テストのスコープ内で既に実行されたジョブが存在しないというアサーションを安全に行えるようにします。

### カスタムアサーションと他のコンポーネント内のジョブのテスト

Active Jobには、テストをシンプルに書くためのカスタムアサーションが多数付属しています。利用できるアサーションの全リストについては、[`ActiveJob::TestHelper`](http://api.rubyonrails.org/classes/ActiveJob/TestHelper.html)のAPIドキュメントを参照してください。

（コントローラなどでの）呼び出しのたびにジョブが正しくキューイングまたは実行されているかをテストするのはよい練習になります。これこそActive Jobが提供するカスタムアサーションの出番です。次のモデルはその一例です。

```ruby
require 'test_helper'

class ProductTest < ActiveJob::TestCase
  test 'billing job scheduling' do
    assert_enqueued_with(job: BillingJob) do
      product.charge(account)
    end
  end
end
```

その他のテスティング関連リソース
------------------------

### 時間に依存するコードをテストする

Railsには、時間の影響を受けやすいコードが期待どおりに動作しているというアサーションに役立つ組み込みのヘルパーメソッドを提供しています。

以下の例では[`travel_to`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html#method-i-travel_to)ヘルパーを使っています。

```ruby
# 登録後のユーザーは1か月分の特典が有効だとする
user = User.create(name: 'Gaurish', activation_date: Date.new(2004, 10, 24))
assert_not user.applicable_for_gifting?
travel_to Date.new(2004, 11, 24) do
  assert_equal Date.new(2004, 10, 24), user.activation_date # inside the `travel_to` block `Date.current` is mocked
  assert user.applicable_for_gifting?
end
assert_equal Date.new(2004, 10, 24), user.activation_date # The change was visible only inside the `travel_to` block.
```

時間関連のヘルパーについて詳しくは、[`ActiveSupport::Testing::TimeHelpers` API Documentation](http://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)を参照してください。
