API ドキュメント作成ガイドライン
============================

本ガイドでは、Rails APIドキュメント作成のガイドラインについて解説します。

このガイドの内容:

* 英文APIドキュメントを効果的に書く方法
* ドキュメント作成用のスタイルガイド (Rubyコード開発用のスタイルガイドとは別)

--------------------------------------------------------------------------------


RDoc
----

[Rails API ドキュメント][Rails_API]は[RDoc][]で生成されます。生成するには、Railsのルートディレクトリで`bundle install`を実行してから、以下を実行します。

```bash
$ bundle exec rake rdoc
```

生成されたHTMLファイルは`./doc/rdoc`ディレクトリに置かれます。

NOTE: RDocの記法については[RDocのmarkupリファレンス][RDoc Markup Reference]を参照してください（訳注: 別ページですが[日本語のRDocライブラリ解説][]もあります）。

[Rails_API]: http://api.rubyonrails.org
[RDoc]: https://ruby.github.io/rdoc/
[日本語のRDocライブラリ解説]: https://docs.ruby-lang.org/ja/master/library/rdoc.html

リンクの表記
-----

Rails APIドキュメントはGitHub上での表示を想定していません。たとえばRails APIで相対リンクを書く場合は[RDocの`link`記法][RDoc link markup]を使わなければなりません。

その理由は、GitHub Markdownと、[api.rubyonrails.org][Rails_API]や[edgeapi.rubyonrails.org][edgeapi]で公開されているRDoc生成方法の違いによるものです。

たとえば、RDocで生成された`ActiveRecord::Base`クラスへのリンクを作成するときは`[link:classes/ActiveRecord/Base.html]`と書きます。

`[https://api.rubyonrails.org/classes/ActiveRecord/Base.html]`のような絶対URLを使うとAPIドキュメントの読者が別バージョンのドキュメント（edgeapi.rubyonrails.orgなど）を開いてしまう可能性があるので、上のような表記が推奨されます。

[RDoc Markup Reference]: https://ruby.github.io/rdoc/RDoc/MarkupReference.html
[RDoc link markup]: https://ruby.github.io/rdoc/RDoc/MarkupReference.html#class-RDoc::MarkupReference-label-Links

[edgeapi]: https://edgeapi.rubyonrails.org

語調
-------

簡潔かつ宣言的に書くこと。簡潔さはそれだけで長所になります。

```ruby
# BAD
# Caching may interfere with being able to see the results
# of code changes.
# （キャッシュによってコード変更の結果が現れなくなる場合があります。）

# GOOD
# Caching interferes with seeing the results of code changes.
# （キャッシュによってコード変更の結果が現れなくなります。）
```

現在形で書くこと。

```ruby
# BAD
# Returned a hash that...（過去形）
# Will return a hash that...（未来形）
# Return a hash that...（命令形）

# GOOD
# Returns a hash that...（現在形）
```

コメントの英文は大文字で始めること。句読点や記号の用法は常識に従うこと。

```ruby
# BAD
# declares an attribute reader backed by an internally-named
# instance variable

# GOOD
# Declares an attribute reader backed by an internally-named
# instance variable.
```

現時点の最新の方法が、読者に明示的に（かつ暗黙にも）伝わるように書くこと。推奨されている最新の慣用表現を使うこと。推奨される方法が強調されるようセクションの順序に注意し、必要であれば順序を入れ替えること。作成するドキュメント自身がRailsのベストプラクティスのよいモデルとなるように、そしてRailsの最新かつ模範的な用法になるように書くこと。

```ruby
# BAD（書き方が古い）
# Book.where('name = ?', "Where the Wild Things Are")
# Book.where('year_published < ?', 50.years.ago)

# GOOD（新しい書き方）
# Book.where(name: "Where the Wild Things Are")
# Book.where(year_published: ...50.years.ago)
```

ドキュメントは短く、かつ全体を理解できるものであること。例外的なケースについても調査し、ドキュメントに盛り込むこと（あるモジュールが無名であったらどうなるか。あるコレクションの内容が空であったらどうなるか。引数がnilであったらどうなるか、など）。

### 命名

Railsのコンポーネント名は、語の間にスペースを1つ置く表記が正式です（例: "Active Support"）。なお、`ActiveRecord`はRubyモジュール名ですが、Active RecordはORMを指します。Railsドキュメント内でコンポーネントを指す場合には常に正式名称を使うこと。

```ruby
# GOOD
# Active Record classes can be created by inheriting from
# ActiveRecord::Base.
```

「エンジン」や「プラグイン」ではなく「Railsアプリケーション」に言及する場合は、常に"application"を使うこと。Railsアプリケーションは"service"ではありません（サービス指向アーキテクチャについて議論する場合を除く）。

```ruby
# BAD（この文脈でのserviceやapplicationの使い方は不適切）
# Production services can report their status upstream.
# Devise is a Rails authentication application.

# GOOD
# Production applications can report their status upstream.
# Devise is a Rails authentication enging.
```

正しいスペルを使うこと。大文字小文字にも注意すること。疑わしい場合は、公式ドキュメントなどの信頼できる情報源を参照すること。

```ruby
# GOOD（スペルと大文字小文字が正しい）
# Arel
# ERB
# Hotwire
# HTML
# JavaScript
# minitest
# MySQL
# npm
# PostgreSQL
# RSpec
```

"SQL"（エスキューエル）に不定冠詞を付けるときは"a"ではなく"an"にすること。

```ruby
# BAD
# Creates a SQL statement.
# Starts a SQLite database.

# GOOD
# Creates an SQL statement.
# Starts an SQLite database.
```

### 代名詞

二人称代名詞"you"や"your"を避けた書き方が望ましい。

```ruby
# BAD
# If you need to use +return+ statements in your callbacks, it is
# recommended that you explicitly define them as methods.

# GOOD
# If +return+ is needed, it is recommended to explicitly define a
# method.
```

ただし、説明上何らかの登場人物を仮定して、その人物を代名詞で呼ぶ場合（"a user with a session cookie" など）は、以下のようにheやsheのような性別のある代名詞を避け、they/their/themのような性別に影響されない代名詞を使うこと。

* heまたはshe -> theyに置き換える
* himまたはher -> themに置き換える
* hisまたはher -> theirに置き換える
* hisまたはhers -> theirsに置き換える
* himselfまたはherself -> themselvesに置き換える

英語はアメリカ英語で
-------

アメリカ英語で表記すること（*color*、*center*、*modularize*など）。詳しくは[アメリカ英語とイギリス英語のスペルの違い][wiki us-gb diff]（英語）を参照。

[wiki us-gb diff]: https://en.wikipedia.org/wiki/American_and_British_English_spelling_differences

カンマはオックスフォードカンマで
------------

カンマは、[オックスフォードスタイル][Oxford comma]（カンマなしの"red, white and blue"ではなく、カンマありの"red, white, and blue"で列挙する）で統一すること。

[Oxford comma]: https://en.wikipedia.org/wiki/Serial_comma

サンプルコード
------------

意味のあるサンプルコードを使うこと。概要と基本を端的に示し、かつ興味深い点や落とし穴も示されているのが理想です。

正しく表示するために、左マージンからスペース2文字ずつインデントすること。サンプルコードの例は「[Railsコーディングルールに従う][Rails coding conventions]」を参照。

短いドキュメントでは、単にパラグラフに続けてスニペットを記述すること（"Examples"ラベルでスニペットを明示する必要はありません）。

```ruby
# Converts a collection of elements into a formatted string by
# calling +to_s+ on all elements and joining them.
#
#   Blog.all.to_fs # => "First PostSecond PostThird Post"
```

逆に長文ドキュメントでは"Examples"セクションを設けることもできます。

```ruby
# ==== Examples
#
#   Person.exists?(5)
#   Person.exists?('5')
#   Person.exists?(name: "David")
#   Person.exists?(['name LIKE ?', "%#{query}%"])
```

式の実行結果は式に続けて書き、冒頭に "# => " を追加して縦を揃えること。

```ruby
# For checking if a fixnum is even or odd.
#
#   1.even? # => false
#   1.odd?  # => true
#   2.even? # => true
#   2.odd?  # => false
```

1つの行が長くなりすぎる場合は出力コメントを次の行に置くこともできます。

```ruby
#   label(:article, :title)
#   # => <label for="article_title">Title</label>
#
#   label(:article, :title, "A short title")
#   # => <label for="article_title">A short title</label>
#
#   label(:article, :title, "A short title", class: "title_label")
#   # => <label for="article_title" class="title_label">A short title</label>
```

実行結果を`puts`や`p`などの出力用メソッドで示すことはなるべく避けること。

逆に（実行結果を示さない）通常のコメントには矢印（`=>`）を書かないこと。

```ruby
#   polymorphic_url(record)  # same as comment_url(record)
```

[Rails coding conventions]: contributing_to_ruby_on_rails.html#rails%E3%82%B3%E3%83%BC%E3%83%87%E3%82%A3%E3%83%B3%E3%82%B0%E3%83%AB%E3%83%BC%E3%83%AB%E3%81%AB%E5%BE%93%E3%81%86

### SQL

SQL文をドキュメントに書く場合は、結果の前に`=>`を付けないこと。

For example,

```ruby
#   User.where(name: 'Oscar').to_sql
#   # SELECT "users".* FROM "users"  WHERE "users"."name" = 'Oscar'
```

### IRB

Rubyの対話型REPLであるIRBの動作をドキュメントに書く場合は、以下のようにコマンドの前に必ず`irb>`を付け、出力には`=>`をつけること。

```ruby
# Find the customer with primary key (id) 10.（主キー（id）10のcustomerを検索）
#   irb> customer = Customer.find(10)
#   # => #<Customer id: 10, first_name: "Ryan">
```

### Bash / コマンドライン

コマンドラインのサンプルでは、常にコマンドの冒頭に`$`を追加すること。出力の冒頭には何も追加する必要はありません。

For command-line examples, always prefix the command with `$`, the output doesn't have to be prefixed with anything.

```ruby
# Run the following command:（以下のコマンドを実行する:）
#   $ bin/rails new zomg
#   ...
```

論理値
--------

述語やフラグの記述は、`true`や`false`（実際のリテラル値）よりも平文のtrueやfalseで書くのが望ましい。

trueやfalseをRubyの定義（`nil`と`false`以外はすべてtrue）どおりに使う場合は、trueやfalseをバッククォートで囲まずに平文で表記すること。逆にシングルトンの`true`および`false`が必要な場合は等幅フォントで表記すること。「truthy」のような用語は避けること（Rubyでは言語レベルでtrueとfalseが定義されているので、これらの用語は技術的に厳密な意味が与えられており、他の言語の用語を使う必要はありません）。

原則として、シングルトンの`true`や`false`をAPIドキュメントに書かないこと（やむを得ない場合を除く）。シングルトンの`true`や`false`を避けることで、読者がシングルトンにつられて`!!`や三項演算子のような余分な人工的記法を使うことも避けられ、リファクタリングもしやすくなります。また、実装で呼び出されるメソッドが返す値の表現が少しでも違うとコードが正常に動作しなくなる事態も避けられます。

例:

```ruby
# +config.action_mailer.perform_deliveries+ specifies whether mail
# will actually be delivered and is true by default
# （`config.action_mailer.perform_deliveries`: メールを実際に配信するかどうかを指定します。デフォルト値はtrueです。）
```

上の例では、フラグの実際のデフォルト値が`true`そのものかどうかをユーザーが知る必要はないので、trueで論理値の意味だけをドキュメントに書きます。

述語の例:

```ruby
# Returns true if the collection is empty.（コレクションが空の場合はtrueを返す。）
#
# If the collection has been loaded it is equivalent to（コレクションが読み込まれる場合は）
# +collection.size.zero?+. If the collection has not been loaded,（+collection.size.zero?+と同値、コレクションが読み込まれなかった場合は）
# it is equivalent to +!collection.exists?+. If the collection has（+collection.exists?+と同値。コレクションが読み込まれていない状態で）
# not already been loaded and you are going to fetch the records（レコードを取り出したい場合は）
# anyway, it is better to check +collection.length.zero?+.（+collection.length.zero?+をチェックするとよい）
def empty?
  if loaded?
    size.zero?
  else
    @target.blank? && !scope.exists?
  end
end
```

このAPIが返す値は具体的な`true`や`false`に限定しないよう注意が払われており、`?`で終わることで述語メソッドであることも示されているので、これで十分です。

ファイル名
----------

原則として、ファイル名はRailsアプリケーションのルートディレクトリからの相対パスで記述すること。

`routes.rb`や`RAILS_ROOT/config/routes.rb`ではなく、`config/routes.rb`と書くこと。

フォント
-----

### 等幅フォント

以下の場合は等幅フォントを使うこと。

* 定数名（特にクラス名やモジュール名）
* メソッド名
* 次のようなリテラル: `nil`、`false`、`true`、`self`
* シンボル
* メソッドのパラメータ
* ファイル名
* HTMLのタグや属性
* CSSのセレクタ、属性、値

```ruby
class Array
  # Calls +to_param+ on all its elements and joins the result with
  # slashes. This is used by +url_for+ in Action Pack.
  def to_param
    collect { |e| e.to_param }.join '/'
  end
end
```

WARNING: 等幅フォントを`+...+`というマークアップで表記するのは、通常のメソッド名、シンボル、（通常のスラッシュを用いる）パスのようなシンプルなものだけにすること。これらよりも複雑なものを表記する場合は必ず`<tt>...</tt>`でマークアップすること。

RDocの出力は以下のコマンドで手軽に確認できます。

```bash
$ echo "+:to_param+" | rdoc --pipe
# => <p><code>:to_param</code></p>
```

たとえば、スペースや引用符を含むコードは`<tt>...</tt>`で囲むこと。

### 平文フォント

Rubyのキーワードでない、英語としてのtrueやfalseには平文フォント（等幅でないフォント）を使うこと。

```ruby
# Runs all the validations within the specified context.
# Returns true if no errors are found, false otherwise.
#
# If the argument is false (default is +nil+), the context is
# set to <tt>:create</tt> if <tt>new_record?</tt> is true,
# and to <tt>:update</tt> if it is not.
#
# Validations with no <tt>:on</tt> option will run no
# matter the context. Validations with # some <tt>:on</tt>
# option will only run in the specified context.
def valid?(context = nil)
  # ...
end
```

説明のリスト
-----------------

項目（オプションやパラメータのリストなど）と説明の間にはハイフンを置くこと（コロンはシンボルで使われるのでハイフンの方が読みやすい）。

```ruby
# * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
```

説明文は通常の英語として大文字で始め、ピリオドで終わること。

さらに詳細な情報や事例を提供したい場合は、"Options"セクションを使うスタイルも利用可能。

[`ActiveSupport::MessageEncryptor#encrypt_and_sign`][#encrypt_and_sign]は良い例。

```ruby
# ==== Options
#
# [+:expires_at+]
#   The datetime at which the message expires. After this datetime,
#   verification of the message will fail.
#
#     message = encryptor.encrypt_and_sign("hello", expires_at: Time.now.tomorrow)
#     encryptor.decrypt_and_verify(message) # => "hello"
#     # 24 hours later...
#     encryptor.decrypt_and_verify(message) # => nil
```

[#encrypt_and_sign]: https://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html#method-i-encrypt_and_sign

動的に生成されるメソッド
-----------------------------

`(module|class)_eval(文字列)`メソッドで作成されるメソッドの右側に、コードで生成されるインスタンスをコメントで書くこと。このように作成されたコメントには、スペース2文字分のインデントを与えること。

[![(module|class)_eval(STRING) code comments](images/dynamic_method_class_eval.png)](images/dynamic_method_class_eval.png)

生成された行が多過ぎる（200行を超える）場合は、コメントを呼び出しの上に置くこと。

```ruby
# def self.find_by_login_and_activated(*args)
#   options = args.extract_options!
#   ...
# end
self.class_eval %{
  def self.#{method_id}(*args)
    options = args.extract_options!
    ...
  end
}, __FILE__, __LINE__
```

メソッドの可視性
-----------------

Railsのドキュメントを作成するときは、ユーザー向けに公開するpublic APIと内部APIを区別することが重要です。

Rubyのprivateスコープに置かれたメソッドは、ユーザー向けのAPIから除外されます。しかし、フレームワークの他の場所から呼び出される必要がある内部APIメソッドも、Rubyのpublicスコープに置かれていなければなりません。このようなメソッドをユーザー向けのAPIから除外するには、以下のようにRDocの`:nodoc:`ディレクティブを使います。

`ActiveRecord::Core::ClassMethods#arel_table`の例:

```ruby
module ActiveRecord::Core::ClassMethods
  def arel_table # :nodoc:
    # 何か書く
  end
end
```

このようなメソッドは、publicであっても依存すべきではありません。このメソッド名が変更される可能性や、戻り値が変更される可能性、あるいはこのメソッド自体が削除される可能性があるからです。メソッド定義で`:nodoc:`を指定することで、ユーザー向けのAPIドキュメントから除外されるようになります。


Railsコントリビュータがドキュメントを作成する場合、そのAPIを外部開発者に公開すべきかどうかに常に注意を払うことが重要です。Railsチームは、public APIに対する破壊的な変更は、必ず非推奨サイクルを経てから行なうようにしています。可視性がprivateでない内部メソッドや内部モジュールには、`:nodoc:`オプションを指定すべきです（モジュールやクラスに`:nodoc:`を追加すると、そのメソッドはすべて内部APIであることを示し、ユーザー向けのAPIドキュメントから削除されます）。

Railsスタック
-------------------------

Rails APIの一部をドキュメント化するときは、Railsスタック全体を意識することが重要です。つまり、ドキュメント化するメソッドやクラスは、コンテキストに応じて振る舞いが変化する可能性があるということです。

以下の`ActionView::Helpers::AssetTagHelper#image_tag`は典型的な例です。

```ruby
# image_tag("icon.png")
#   # => <img src="/assets/icon.png" />
```

`#image_tag`を単独で考えれば`/images/icon.png`を返しますが、アセットパイプラインなどを含むRailsのフルスタックでは上のように結果が変わることがあります。

私たちは、メソッド単独の振る舞いだけではなく、**フレームワーク**の振る舞いもドキュメント化したいと考えています。
私たちの関心は、ユーザーがデフォルトの完全なRailsスタックを使ったときに経験する振る舞いを記述することにあります。

Railsチームが特定のAPIをどのように扱っているかを知りたい場合は、Railsリポジトリでお気軽にissueをオープンするか、[issue tracker][issues]にパッチを送ってください。

[issues]: https://github.com/rails/rails/issues