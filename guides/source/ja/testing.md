
Rails テスティングガイド
=====================================

本ガイドは、アプリケーションをテストするためにRailsに組み込まれているメカニズムについて解説します。

このガイドの内容:

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177143
-->
* Railsテスティング用語
* アプリケーションに対する単体テスト、機能テスト、結合テストの実施
* その他の著名なテスティング方法とプラグインの紹介

--------------------------------------------------------------------------------

Railsアプリケーションでテストを作成しなければならない理由
--------------------------------------------

Railsを使用すれば、テストをきわめて簡単に作成できます。テストの作成は、モデルやコントローラを作成する時点でテストコードのスケルトンを作成することから始まります。

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177502
-->
`models`ディレクトリはモデル用のテストの置き場所であり、`controllers`ディレクトリはコントローラ用のテストの置き場所です。`integration`ディレクトリは任意の数のコントローラとやりとりするテストを置く場所です。

<!--
TODO:https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177338
-->

フィクスチャはテストデータを編成する方法の1つであり、`fixtures`フォルダに置かれます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177351
-->

`test_helper.rb`にはテスティングのデフォルト設定を記入します。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177382
-->

### test環境

デフォルトでは、すべてのRailsアプリケーションにはdevelopment、test、productionの3つの環境があります。それぞれの環境におけるデータベース設定は`config/database.yml`で行います。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27177423
-->
テスティング専用のデータベースがあれば、それを設定して他の環境から切り離された専用のテストデータにアクセスすることができます。テストを実行すればテストデータは確実に元の状態から変わってしまうので、development環境やproduction環境のデータベースにあるデータには決してアクセスしません。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27198895
-->
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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27199410
-->
既にご存じかと思いますが、`test_helper.rb`はテストを実行するためのデフォルト設定を行なうためのファイルです。このファイルはどのテストにも必ずインクルードされるので、このファイルに追加したメソッドはすべてのテストで利用できます。

```ruby
class ArticleTest < ActiveSupport::TestCase
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200155
-->
`ArticleTest`クラスは`ActiveSupport::TestCase`を継承することによって、_テストケース_ をひとつ定義しています。これにより、`ActiveSupport::TestCase`のすべてのメソッドを`ArticleTest`で利用できます。これらのメソッドのいくつかについてはこの後ご紹介します。

`ActiveSupport::TestCase`のスーパークラスは`Minitest::Test`です。この`Minitest::Test`を継承したクラスで定義される、`test_`で始まるすべてのメソッドは単に「テスト」と呼ばれます。この`test_`は小文字でなければなりません。従って、`test_password`および`test_valid_password`というメソッド名は正式なテスト名となり、テストケースの実行時に自動的に実行されます。

Railsは、ブロックとテスト名をそれぞれ1つずつ持つ`test`メソッドを1つ追加します。この時生成されるのは通常の`Minitest::Unit`テストであり、メソッド名の先頭に`test_`が付きます。次のようになります。

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200189
-->
`test`マクロが適用されることによって、引用符で囲んだ読みやすいテスト名がテストメソッドの定義に変換されます。もちろん、後者のような通常のメソッド定義を使用することもできます。

NOTE: テスト名からのメソッド名生成は、スペースをアンダースコアに置き換えることによって行われます。生成されたメソッド名はRubyの正規な識別子である必要はありません。テスト名にパンクチュエーション（句読点）などの文字が含まれていても大丈夫です。これが可能なのは、Rubyではメソッド名にどんな文字列でも使用できるようになっているからです。普通でない文字を使おうとすると`define_method`呼び出しや`send`呼び出しが必要になりますが、名前の付け方そのものには公式な制限はありません。

```ruby
assert true
```

アサーションとは、オブジェクトまたは式を評価して、期待された結果が得られるかどうかをチェックするコードです。アサーションでは以下のようなチェックを行なうことができます。

* ある値が別の値と等しいかどうか
* このオブジェクトはnilかどうか
* コードのこの行で例外が発生するかどうか
* ユーザーのパスワードが5文字より多いかどうか

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200418
-->
1つのテストには必ず1つ以上のアサーションが含まれます。すべてのアサーションに成功してはじめてテストがパスします。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200430
-->

今度はテストが失敗した場合の結果を見てみましょう。そのためには、`article_test.rb`テストケースに、確実に失敗するテストを以下のように追加してみます。

```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200431
-->
それでは、新しく追加したテストを実行してみましょう。

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

出力に含まれている単独の文字`F`は失敗を表します。`1)`の後にこの失敗に対応するトレースが、失敗したテスト名とともに表示されています。次の数行はスタックトレースで、アサーションの実際の値と期待されていた値がその後に表示されています。デフォルトのアサーションメッセージには、エラー箇所を特定するのに十分な情報が含まれています。アサーションメッセージをさらに読みやすくするために、すべてのアサーションに以下のようにメッセージをオプションパラメータを渡すことができます。

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

今度は _title_ フィールドに対してモデルのレベルでバリデーションを行い、テストがパスするようにしてみましょう。

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

お気付きになった方もいるかと思いますが、私たちは欲しい機能が未実装であるために失敗するテストをあえて最初に作成していることにご注目ください。続いてその機能を実装し、それからもう一度実行してテストがパスすることを確認しました。ソフトウェア開発の世界ではこのようなアプローチをテスト駆動開発 ( [_Test-Driven Development_ (TDD)](http://c2.com/cgi/wiki?TestDrivenDevelopment) : TDD) と呼んでいます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200588
-->
エラーがどのように表示されるかを確認するために、以下のようなエラーを含んだテストを作ってみましょう。

```ruby
test "should report error" do
  # some_undefined_variable is not defined elsewhere in the test case
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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200746
-->
NOTE: テストスイートに含まれる各テストメソッドは、エラーまたはアサーション失敗が発生するとそこで実行を中止し、次のメソッドに進みます。すべてのテストメソッドはアルファベット順に実行されます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200807
-->
テストが失敗すると、それに応じたバックトレースが出力されます。Railsはデフォルトでバックトレースをフィルタし、アプリケーションに関連するバックトレースのみを出力します。これによって、フレームワークから発生する不要な情報を排除して作成中のコードに集中できます。完全なバックトレースを参照しなければならなくなった場合は、`BACKTRACE`環境変数を設定するだけで動作を変更できます。

```bash
$ bin/rails test -b test/models/article_test.rb
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27200848
-->

### 利用可能なアサーション

ここまでにいくつかのアサーションをご紹介しましたが、これらはごく一部に過ぎません。アサーションこそは、テストの中心を担う重要な存在です。システムが計画通りに動作していることを実際に確認しているのはアサーションです。

アサーションは非常に多くの種類が使用できるようになっています。
以下で紹介するのは、[`Minitest`](https://github.com/seattlerb/minitest)で使用できるアサーションからの抜粋です。MinitestはRailsにデフォルトで組み込まれているテスティングライブラリです。`[msg]`パラメータは1つのオプション文字列メッセージであり、テストが失敗したときのメッセージをわかりやすくするにはここで指定します。これは必須ではありません。

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
| `assert_in_delta( expected, actual, [delta], [msg] )`            | `expected`の個数と`actual`の個数の差分は`delta`以内であると主張する。|
| `assert_not_in_delta( expected, actual, [delta], [msg] )`        | `expected`の個数と`actual`の個数の差分は`delta`以内にはないと主張する。|
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
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201052
-->

| アサーション                                                                         | 目的 |
| --------------------------------------------------------------------------------- | ------- |
| [`assert_difference(expressions, difference = 1, message = nil) {...}`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_difference) | yieldされたブロックで評価された結果である式の戻り値における数値の違いをテストする。|
| [`assert_no_difference(expressions, message = nil, &block)`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_difference) | 式を評価した結果の数値は、ブロックで渡されたものを呼び出す前と呼び出した後で違いがないと主張する。|
| [`assert_no_changes(expressions, message = nil, &block)`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_no_changes) | Test the result of evaluating an expression is not changed after invoking the passed in block.|
| [`assert_nothing_raised { block }`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_nothing_raised) | Ensures that the given block doesn't raise any exceptions.|
| [`assert_recognizes(expected_options, path, extras={}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_recognizes) | 渡されたパスのルーティングが正しく扱われ、(expected_optionsハッシュで渡された) 解析オプションがパスと一致したことを主張する。基本的にこのアサーションでは、Railsはexpected_optionsで渡されたルーティングを認識すると主張する。|
| [`assert_generates(expected_path, options, defaults={}, extras = {}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_generates) | 渡されたオプションは、渡されたパスの生成に使用できるものであると主張する。assert_recognizesと逆の動作。extrasパラメータは、クエリ文字列に追加リクエストがある場合にそのパラメータの名前と値をリクエストに渡すのに使用される。messageパラメータはアサーションが失敗した場合のカスタムエラーメッセージを渡すことができる。|
| [`assert_response(type, message = nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_response) | レスポンスが特定のステータスコードを持っていることを主張する。`:success`を指定するとステータスコード200-299を指定したことになり、同様に`:redirect`は300-399、`:missing`は404、`:error`は500-599にそれぞれマッチする。ステータスコードの数字や同等のシンボルを直接渡すこともできる。詳細については[ステータスコードの完全なリスト](http://rubydoc.info/github/rack/rack/master/Rack/Utils#HTTP_STATUS_CODES-constant)および[シンボルとステータスコードの対応リスト](http://rubydoc.info/github/rack/rack/master/Rack/Utils#SYMBOL_TO_STATUS_CODE-constant)を参照のこと。|
| [`assert_redirected_to(options = {}, message=nil)`](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_redirected_to) | 渡されたリダイレクトオプションが、最後に実行されたアクションで呼び出されたリダイレクトのオプションと一致することを主張する。このアサーションは部分マッチ可能。たとえば`assert_redirected_to(controller: "weblog")`は`redirect_to(controller: "weblog", action: "show")`というリダイレクトなどにもマッチする。`assert_redirected_to root_path`などの名前付きルートを渡したり、`assert_redirected_to @article`などのActive Recordオブジェクトを渡すこともできる。|

これらのアサーションのいくつかについては次の章でご説明します。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201536
-->
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201749
-->

テストデータベース
-----------------------

Railsアプリケーションは、ほぼ間違いなくデータベースと密接なやりとりを行いますので、テスティングにもデータベースが必要となります。効率のよいテストを作成するには、データベースの設定方法とサンプルデータの導入方法を理解しておく必要があります。

デフォルトでは、すべてのRailsアプリケーションにはdevelopment、test、productionの3つの環境があります。それぞれの環境におけるデータベース設定は`config/database.yml`で行います。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201848
-->
テスティング専用のデータベースがあれば、それを設定して他の環境から切り離された専用のテストデータにアクセスすることができます。テストを実行すればテストデータは確実に元の状態から変わってしまうので、development環境やproduction環境のデータベースにあるデータには決してアクセスしません。

### テストデータベースのスキーマを管理する

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201579
-->
テストを実行するには、テストデータベースが最新の状態で構成されている必要があります。テストヘルパーは、テストデータベースに未完了のマイグレーションが残っていないかどうかをチェックします。マイグレーションがすべて終わっている場合、`db/schema.rb`や`db/structure.sql`をテストデータベースに読み込みます。ペンディングされたマイグレーションがある場合、エラーが発生します。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27201605
-->

### フィクスチャのしくみ

よいテストを作成するにはよいテストデータを準備する必要があることを理解しておく必要があります。
Railsでは、テストデータの定義とカスタマイズはフィクスチャで行うことができます。
網羅的なドキュメントについては、[フィクスチャAPIドキュメント](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)を参照してください。

#### フィクスチャとは何か

_フィクスチャ (fixture)_とは、いわゆるサンプルデータを言い換えたものです。フィクスチャを使用することで、事前に定義したデータをテスト実行直前にtestデータベースに導入することができます。フィクスチャはYAMLで記述され、特定のデータベースに依存しません。1つのモデルにつき1つのフィクスチャファイルが作成されます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202039
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202051
-->
フィクスチャファイルは`test/fixtures`の下に置かれます。`rails generate model`を実行すると、モデルのフィクスチャスタブが自動的に作成され、このディレクトリに置かれます。

#### YAML

YAML形式のフィクスチャは人間にとってとても読みやすく、サンプルデータを容易に記述することができます。この形式のフィクスチャには**.yml**というファイル拡張子が与えられます (`users.yml`など)。

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

[関連付け](/association_basics.html)を使用している場合は、2つの異なるフィクスチャの間に参照ノードを1つ定義すれば済みます。belongs_to/has_many関連付けの例を以下に示します。

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202127
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202161
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202171
-->
NOTE: 名前で互いを参照する関連付けの場合、フィクスチャで`id:`属性を指定することはできません。Railsはテストの実行中に、一貫性を保つために自動的に主キーを割り当てます。フィクスチャで`id:`属性を指定するとこの自動割り当てがしなくなります。関連付けの詳細な動作については、[フィクスチャAPIドキュメント](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)を参照してください。

#### ERB

ERBは、テンプレート内にRubyコードを埋め込むのに使用されます。YAMLフィクスチャ形式のファイルは、Railsに読み込まれたときにERBによる事前処理が行われます。ERBを活用すれば、Rubyで一部のサンプルデータを生成できます。たとえば、以下のコードを使用すれば1000人のユーザーを生成できます。

```erb
<% 1000.times do |n| %>
user_<%= n %>:
  username: <%= "user#{n}" %>
  email: <%= "user#{n}@example.com" %>
<% end %>
```

#### フィクスチャの動作

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202233
-->
Railsはデフォルトで、`test/fixtures`フォルダにあるすべてのフィクスチャを自動的に読み込み、モデルやコントローラのテストで使用します。フィクスチャの読み込みは主に以下の3つの手順からなります。

1. フィクスチャに対応するテーブルに含まれている既存のデータをすべて削除する
2. フィクスチャのデータをテーブルに読み込む
3. フィクスチャに直接アクセスしたい場合はフィクスチャのデータをメソッドにダンプする

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202260
-->

#### フィクスチャはActive Recordオブジェクト

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202280
-->
フィクスチャは、実はActive Recordのインスタンスです。前述の3番目の手順で示したように、フィクスチャはテストケースのローカル変数を自動的に設定してくれるので、フィクスチャのオブジェクトに直接アクセスできます。以下に例を示します。

```ruby
# davidという名前のフィクスチャに対応するUserオブジェクトを返す
users(:david)

# idで呼び出されたdavidのプロパティを返す
users(:david).id

# Userクラスで利用可能なメソッドにアクセスすることもできる
david = users(:david)
david.call(david.partner)
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202305
-->

```ruby
# this will return an array containing the fixtures david and steve
users(:david, :steve)
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202402

次のコメントを5.1に対応してください。
https://github.com/nanophate/railsguides.jp/pull/4#discussion_r165903264
https://github.com/nanophate/railsguides.jp/pull/4#discussion_r165903297
-->

結合テスト
-------------------

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202908
-->
結合テスト (integration test) は、複数のコントローラ同士のやりとりをテストします。一般に、アプリケーション内の重要なワークフローのテストに使用されます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202914
-->

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202961
-->
結合テストは`ActionDispatch::IntegrationTest`から継承されます。これにより、結合テスト内でさまざまなヘルパーが利用できます。テストで使用するフィクスチャーも明示的に作成しておく必要があります。

### 結合テストで使用できるヘルパー

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202844
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202969
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202978
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27202996
-->

コントローラの機能テスト
-------------------------------------

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27203004
-->
Railsで1つのコントローラに含まれる複数のアクションをテストするには、コントローラに対する機能テスト (functional test) を作成します。コントローラはアプリケーションへのWebリクエストを受信し、最終的にビューをレンダリングしたものをレスポンスとして返します。

### 機能テストに含める項目

機能テストでは以下のようなテスト項目を実施する必要があります。

* Webリクエストが成功したか
* 正しいページにリダイレクトされたか
* ユーザー認証が成功したか
* レスポンスのテンプレートに正しいオブジェクトが保存されたか
* ビューに表示されたメッセージは適切か

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27203039
-->
`test/controllers`ディレクトリに`articles_controller_test.rb`ファイルができているはずなので、中がどのようになっているか見てみましょう。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27203055
-->

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27203392
-->
`test_should_get_index`というテストでは、Railsが`index`という名前のアクションに対するリクエストをシミュレートします。同時に、有効な`articles`インスタンス変数がコントローラに割り当てられます。

`get`メソッドはWebリクエストを開始し、結果をレスポンスとして返します。このメソッドには以下の4つの引数を渡すことができます。

* リクエストの対象となる、コントローラ内のアクション。アクション名は文字列またはシンボルで指定できます。
* アクションに渡すリクエストパラメータに含まれるオプションハッシュ1つ (クエリ文字列パラメータや記事の変数など)。
* リクエストで渡されるセッション変数のオプションハッシュ1つ。
* flashメッセージの値のオプションハッシュ1つ。

例: `:show`アクションを呼び出し、`id`に12を指定して`params`として渡し、セッションの`user_id`に5を設定する。

```ruby
get article_url, params: { id: 12 }, headers: { "HTTP_REFERER" => "http://example.com/home" }
```

別の例: `:update`アクションを呼び出し、`id`に12を指定し、Ajaxのリクエストの`params`として渡す

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27203502
--->

### 機能テストで利用できるHTTPリクエストの種類

HTTPリクエストに精通していれば、`get`がHTTPリクエストの一種であることも既に理解していることでしょう。Railsの機能テストでは以下の6種類のHTTPリクエストがサポートされています。

* `get`
* `post`
* `patch`
* `put`
* `head`
* `delete`

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27225975
-->
これらはすべてメソッドとして利用できますが、実際には最初の2つでほとんどの用が足りるはずです。

NOTE: 機能テストは、そのリクエストがアクションで受け付けられるかどうかについては検証するものではありません。機能テストでこれらのリクエストの名前が使用されているのは、リクエストの種類を明示してテストを読みやすくするためです。


<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27225994
-->

```ruby
test "ajax request" do
  article = articles(:one)
  get article_url(article), xhr: true

  assert_equal 'hello world', @response.body
  assert_equal "text/javascript", @response.content_type
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27225994
-->
### 4つのハッシュ

6種類のメソッドのうち、`get`や`post`などいずれかのリクエストが行われて処理されると、以下の4種類のハッシュオブジェクトが使用できるようになります。

* `cookies` - 設定されているすべてのcookies。
* `flash` - flash内のすべてのオブジェクト。
* `session` - セッション変数に含まれるすべてのオブジェクト。

これらのハッシュは、通常のHashオブジェクトと同様に文字列をキーとして値を参照できます。シンボル名による参照も可能です。たとえば次のようになります。

```ruby
flash["gordon"]               flash[:gordon]
session["shmession"]          session[:shmession]
cookies["are_good_for_u"]     cookies[:are_good_for_u]
```

### 利用可能なインスタンス変数

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226080
-->
機能テストでは以下の3つの専用インスタンス変数を使用できます。

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226361
-->
[HTTPヘッダー](http://tools.ietf.org/search/rfc2616#section-5.3)と[CGI変数](http://tools.ietf.org/search/rfc3875#section-4.1)は`@request`インスタンス変数で直接設定できます。

```ruby
# HTTPヘッダーを設定する
get articles_url, headers: { "Content-Type": "text/plain" } # simulate the request with custom header

# CGI変数を設定する
get articles_url, headers: { "HTTP_REFERER": "http://example.com/home" } # simulate the request with custom env variable
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226549
-->

```ruby
test "should create article" do
  assert_difference('Article.count') do
    post article_url, params: { article: { title: 'Some title' } }
  end

  assert_redirected_to article_path(Article.last)
  assert_equal 'Article was successfully created.', flash[:notice]
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226572
-->

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226635
-->

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226647
-->

```bash
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Run options: -n test_should_create_article --seed 18981

# Running:

.

Finished in 0.081972s, 12.1993 runs/s, 48.7972 assertions/s.

1 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226682
-->

```ruby
test "should show article" do
  article = articles(:one)
  get article_url(article)
  assert_response :success
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226705
-->

```ruby
test "should destroy article" do
  article = articles(:one)
  assert_difference('Article.count', -1) do
    delete article_url(article)
  end
  assert_redirected_to articles_path
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226724
-->

```ruby
test "should update article" do
  article = articles(:one)

  patch article_url(article), params: { article: { title: "updated" } }

  assert_redirected_to article_path(article)
  # Reload association to fetch updated data and assert that title is updated.
  article.reload
  assert_equal "updated", article.title
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226758
-->

```ruby
require 'test_helper'
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  # called before every single test
  setup do
    @article = articles(:one)
  end  

  # called after every single test
  teardown do
    # when controller is using cache it may be a good idea to reset it afterwards
    Rails.cache.clear
  end

  test "should show article" do
    # Reuse the @article instance variable from setup
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
    # Reload association to fetch updated data and assert that title is updated.
    @article.reload
    assert_equal "updated", @article.title
  end
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226855
-->

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27226870
-->

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

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227396
-->
```ruby
require 'test_helper'
class ProfileControllerTest < ActionDispatch::IntegrationTest

  test "should show profile" do
    # helper is now reusable from any controller test case
    sign_in_as users(:david)

    get profile_url
    assert_response :success
  end
end		
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227440
-->

ビューをテストする
-------------

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227469
-->
アプリケーションのビューのテストで、あるページで重要なHTML要素とその内容がレスポンスに含まれていることを主張する (アサーションを行なう) のは、リクエストに対するレスポンスをテストする方法として便利です。`assert_select`というアサーションを使用すると、こうしたテストで簡潔かつ強力な文法を利用できるようになります。

`assert_select`には2つの書式があります。

`assert_select(セレクタ, [条件], [メッセージ])`という書式は、セレクタで指定された要素が条件に一致することを主張します。セレクタにはCSSセレクタの式 (文字列) や代入値を持つ式を使用できます。

`assert_select(要素, セレクタ, [条件], [メッセージ])` は、選択されたすべての要素が条件に一致することを主張します。選択される要素は、_element_ (`Nokogiri::XML::Node` or `Nokogiri::XML::NodeSet`のインスタンス) からその子孫要素までの範囲から選択されます。

たとえば、レスポンスに含まれるtitle要素の内容を検証するには、以下のアサーションを使用します。

```ruby
assert_select 'title', "Welcome to Rails Testing Guide"
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227530
-->
ネストした`assert_select`ブロックを使用することもできます。以下の例の場合、外側の`assert_select`で選択されたすべての要素の完全なコレクションに対して、内側の`assert_select`がアサーションを実行します。

```ruby
assert_select 'ul.navigation' do
  assert_select 'li.menu_item'
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227556
-->
あるいは、外側の`assert_select`で選択された要素のコレクションをイテレート (列挙) し、`assert_select`が要素ごとに呼び出されるようにすることもできます。たとえば、レスポンスに2つの順序付きリストがあり、1つの順序付きリストにつき要素が4つあれば、以下のテストはどちらもパスします。

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
ヘルパー自体は単なるモジュールであり、ビューから利用するヘルパーメソッドをこの中に定義します。

ヘルパーのテストについては、ヘルパーメソッドの出力が期待どおりであるかどうかをチェックするだけで十分です。ヘルパー関連のテストは`test/helpers`ディレクトリに置かれます。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227719
-->
ヘルパーテストの外枠は以下のような感じです。

```ruby
module UserHelper
  def link_to_user(user)
    link_to "#{user.first_name} #{user.last_name}", user
  end
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227745
-->

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

メイラーを生成すると、メイラーの各アクションに対応するスタブフィクスチャーが生成されます。Railsのジェネレータを使用しない場合は、自分でこれらのファイルを作成する必要があります。

#### 基本的なテストケース

`invite`というアクションで知人に招待状を送信する`UserMailer`という名前のメイラーに対する単体テストを以下に示します。これは、`invite`アクションをジェネレータで生成したときに作成される基本的なテストに手を加えたものです。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227849
-->
```ruby
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # Create the email and store it for further assertions
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

このテストでは、メールを送信し、その結果返されたオブジェクトを`email`変数に保存します。続いて、このメールが送信されたことを主張します (最初のアサーション)。次のアサーションでは、メールの内容が期待どおりであることを主張します。`read_fixture`ヘルパーを使用してこのファイルの内容を読みだしています。

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27227874
-->

`invite`フィクスチャーは以下のような内容にしておきます。

```
friend@example.comさん、こんにちは。

招待状を送付いたします。

どうぞよろしく!
```

ここでメイラーのテスト作成方法の詳細部分についてご説明したいと思います。`config/environments/test.rb`の`ActionMailer::Base.delivery_method = :test`という行で送信モードをtestに設定しています。これにより、送信したメールが実際に配信されないようにできます。そうしないと、テスト中にユーザーにスパムメールを送りつけてしまうことになります。この設定で送信したメールは、`ActionMailer::Base.deliveries`という配列に追加されます。

NOTE: この`ActionMailer::Base.deliveries`という配列は、`ActionMailer::TestCase`と`ActionDispatch::IntegrationTest`でのテストを除き、自動的にはリセットされません。それらのテストの外で配列をクリアしたい場合は、`ActionMailer::Base.deliveries.clear`で手動リセットできます。

### 機能テスト

メイラーの機能テストでは、メール本文や受取人が正しいことを確認するなど、単体テストでカバーされているようなことは扱いません。メールの機能テストでは、メール配信メソッドを呼び出し、その結果適切なメールが配信リストに追加されるかどうかをチェックします。機能テストでは配信メソッド自体は正常に動作すると仮定することになりますが、これでまず問題ありません。機能テストでは、期待されたタイミングでアプリケーションのビジネスロジックからメールが送信されるかどうかをテストすることがメインになるのが普通だからです。たとえば、友人を招待するという操作によってメールが適切に送信されるかどうかをチェックするには以下のような機能テストを使用します。

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

ヘルパーをテストする
---------------

ヘルパーのテストについては、ヘルパーメソッドの出力が期待どおりであるかどうかをチェックするだけで十分です。ヘルパー関連のテストは`test/helpers`ディレクトリに置かれます。

ヘルパーテストの外枠は以下のような感じです。

```ruby
require 'test_helper'

class UserHelperTest < ActionView::TestCase
end
```

ヘルパー自体は単なるモジュールであり、ビューから利用するヘルパーメソッドをこの中に定義します。ヘルパーメソッドの出力をテストするには、以下のようなミックスインを使用する必要があるでしょう。

```ruby
class UserHelperTest < ActionView::TestCase
  include UserHelper

  test "should return the user name" do
    # ...
  end
end
```

さらに、テストクラスは`ActionView::TestCase`をextendしたものなので、`link_to`や`pluralize`などのRailsヘルパーメソッドにアクセスできます。

その他のテスティングアプローチ
------------------------

Railsアプリケーションではビルトインの`minitest`ベースのテスティング以外のテストしか利用できないわけではありません。Rails開発者は以下のような実にさまざまなアプローチでテストの実行や支援を行っています。

* [NullDB](http://avdi.org/projects/nulldb/)はデータベースの利用を避けてテスティングを高速化する方法です。
* [Factory Bot](https://github.com/thoughtbot/factory_bot/tree/master)はフィクスチャーに代わるテストデータ提供/生成ツールです。
* [Fixture Builder](https://github.com/rdy/fixture_builder)はテスト実行直前にRubyのファクトリーをコンパイルしてフィクスチャーに変換するツールです。
* [MiniTest::Spec Rails](https://github.com/metaskills/minitest-spec-rails)、RailsのテストではMiniTest::Spec DSLを利用します。
* [Shoulda](http://www.thoughtbot.com/projects/shoulda)`test/unit`を拡張してさまざまなヘルパー/マクロ/アサーションを追加します。
* [RSpec](http://relishapp.com/rspec)はビヘイビア駆動開発用のフレームワークです。
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/4ea09d8c1decf178d4135042d30cf9824000df76#r27228097
-->
