API ドキュメント作成ガイドライン
============================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[API Documentation Guidelines](https://guides.rubyonrails.org/api_documentation_guidelines.html)を日本語に翻訳した文書です。

本ガイドでは、Rails APIドキュメント作成のガイドラインについて解説します。

このガイドの内容:

* 英文APIドキュメントを効果的に書く方法
* ドキュメント作成用のスタイルガイド (Rubyコード開発用のスタイルガイドとは別)

--------------------------------------------------------------------------------


RDoc
----

[Rails API ドキュメント][Rails API doc]は[RDoc][]で生成されます。生成するには、Railsのルートディレクトリで`bundle install`を実行してから、以下を実行します。

```bash
$ bundle exec rake rdoc
```

生成されたHTMLファイルは./doc/rdocディレクトリに置かれます。

RDocの記法については[markup][]を参照してください（訳注: 別ページですが[日本語のRDocライブラリ解説][]があります）。[追加のディレクティブ][directives]にも目を通しておいてください。

[Rails API doc]: http://api.rubyonrails.org
[RDoc]: https://ruby.github.io/rdoc/
[markup]: https://ruby.github.io/rdoc/RDoc/Markup.html
[日本語のRDocライブラリ解説]: https://docs.ruby-lang.org/ja/master/library/rdoc.html
[directives]: https://ruby.github.io/rdoc/RDoc/Parser/Ruby.html

リンクの表記
-----

Rails APIドキュメントはGitHub上での表示を想定していません。例えばRails APIで相対リンクを書く場合はRDocの[`link`][]を使う必要があります。

これは、GitHub Markdownと、[api.rubyonrails.org][Rails API doc]や[edgeapi.rubyonrails.org][edgeapi]で公開されているRDoc生成の違いによるものです。

たとえば、RDocで生成された`ActiveRecord::Base`クラスへのリンクを作成するときは`[link:classes/ActiveRecord/Base.html]`と書きます。

`[https://api.rubyonrails.org/classes/ActiveRecord/Base.html]`のような絶対URLを使うとAPIドキュメントの読者が別バージョンのドキュメント（edgeapi.rubyonrails.orgなど）を開いてしまう可能性があるので、上のような表記が推奨されます。

[`link`]: https://ruby.github.io/rdoc/RDoc/Markup.html#class-RDoc::Markup-label-Links
[edgeapi]: https://edgeapi.rubyonrails.org

語調
-------

簡潔かつ宣言的に書くこと。簡潔さはそれだけで長所になります。

現在形で書くこと（"Returned a hash that..." や "Will return a hash that..." ではなく"Returns a hash that..."のように書く）。

コメントの英語は大文字で始めること。句読点や記号の用法は常識に従うこと。

```ruby
# Declares an attribute reader backed by an internally-named
# instance variable.
def attr_internal_reader(*attrs)
  ...
end
```

現時点の最新の方法が、読者に明示的に（かつ暗黙にも）伝わるように書くこと。先進的な分野で推奨されている慣用表現を使うこと。推奨される方法が強調されるようセクションの順序に注意し、必要であれば順序を入れ替えること。作成するドキュメント自身がRailsのベストプラクティスのよいモデルとなるように、そしてRailsの最新かつ模範的な用法になるように書くこと。

ドキュメントは短く、かつ全体を理解できるものであること。例外的なケースについても調査し、ドキュメントに盛り込むこと（あるモジュールが無名であったらどうなるか。あるコレクションの内容が空であったらどうなるか。引数がnilであったらどうなるか、など）。

Railsのコンポーネント名は語の間にスペースを1つ置く表記が正式（例: "Active Support"）。なお、`ActiveRecord`はRubyモジュール名ですが、Active RecordはORMを指します。Railsドキュメント内でコンポーネントを指す場合には常に正式名称を使うこと。

正しいスペルを使うこと（Arel、Test::Unit、RSpec、HTML、MySQL、JavaScript、ERB、Hotwireなど）。大文字小文字にも注意すること。疑わしい場合は、公式ドキュメントなどの信頼できる情報源を参照すること。

"SQL" という語の前には冠詞 "an" を付けること（例: "an SQL statement"）。同様に、"an SQLite database"のようにすること。

"you"や"your"を含む表現を避けること。

```markdown
If you need to use `return` statements in your callbacks, it is recommended that you explicitly define them as methods.
```

上のようにyouを3度も使うのではなく、以下のスタイルで書くこと。

```markdown
If `return` is needed it is recommended to explicitly define a method.
```

ただし、説明上何らかの登場人物を仮定して、その人物を代名詞で呼ぶ場合（"a user with a session cookie" など）は、以下のようにheやsheのような性別のある代名詞を避け、they/their/themのような性別に影響されない代名詞を使うこと。

* heまたはshe -> theyに置き換える
* himまたはher -> themに置き換える
* hisまたはher -> theirに置き換える
* hisまたはhers -> theirsに置き換える
* himselfまたはherself -> themselvesに置き換える

英語
-------

アメリカ英語で表記すること（*color*、*center*、*modularize*など）。詳しくは[アメリカ英語とイギリス英語のスペルの違い][wiki us-gb diff]（英語）を参照。

[wiki us-gb diff]: https://en.wikipedia.org/wiki/American_and_British_English_spelling_differences

オックスフォードカンマ
------------

カンマは、[オックスフォードスタイル][Oxford comma]（カンマなしの"red, white and blue"ではなく、カンマありの"red, white, and blue"で列挙する）で統一すること。

[Oxford comma]: https://en.wikipedia.org/wiki/Serial_comma

サンプルコード
------------

意味のあるサンプルコードを使うこと。概要と基本を端的に示し、かつ興味深い点や落とし穴も示されているのが理想です。

サンプルコードのインデントにはスペース2文字を使うこと。マークアップ用には左マージンに合わせてスペース2文字を使うこと。サンプルコードの例は「[Railsコーディングルールに従う](contributing_to_ruby_on_rails.html#rails%E3%82%B3%E3%83%BC%E3%83%87%E3%82%A3%E3%83%B3%E3%82%B0%E3%83%AB%E3%83%BC%E3%83%AB%E3%81%AB%E5%BE%93%E3%81%86)」を参照。

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

論理値
--------

述語やフラグの記述は、`true`や`false`（実際のリテラル値）よりも平文のtrueやfalseを優先すること。

trueやfalseをRubyの定義（`nil`と`false`以外はすべてtrue）どおりに使う場合は、trueやfalseを平文で表記すること。逆にシングルトンの`true`および`false`が必要な場合は等幅フォントで表記すること。「truthy」のような用語は避けること（Rubyでは言語レベルでtrueとfalseが定義されているので、これらの用語は技術的に厳密な意味が与えられており、他の言語の用語を使う必要はありません）。

原則として、シングルトンの`true`や`false`をAPIドキュメントに書かないこと（やむを得ない場合を除く）。シングルトンの`true`や`false`を避けることで、読者がシングルトンにつられて`!!`や三項演算子のような余分な人工的記法を使うことも避けられ、リファクタリングもしやすくなります。また、実装で呼び出されるメソッドが返す値の表現が少しでも違うとコードが正常に動作しなくなる事態も避けられます。

例:

```markdown
`config.action_mailer.perform_deliveries` specifies whether mail will actually be delivered and is true by default
`config.action_mailer.perform_deliveries`: メールを実際に配信するかどうかを指定します（デフォルト値はtrue）。
```

上の例では、フラグの実際のデフォルト値が`true`そのものかどうかをユーザーが知る必要はないので、trueで論理値の意味だけをドキュメントに書きます。

述語の例:

```ruby
# Returns true if the collection is empty.（コレクションが空の場合はtrueを返す。）
#
# If the collection has been loaded（コレクションが読み込まれる場合は）
# it is equivalent to <tt>collection.size.zero?</tt>. （<tt>collection.size.zero?</tt>と同値）
# if the collection has not been loaded, it is equivalent to（コレクションが読み込まれなかった場合は）
# <tt>collection.exists?</tt>. <tt>collection.exists?</tt>と同値。）
# If the collection has not already been （コレクションが読み込まれていない状態で）
# loaded and you are going to fetch the records anyway（レコードを取り出したい場合は）
# it is better to check <tt>collection.length.zero?</tt>. （<tt>collection.length.zero?</tt>をチェックするとよい）
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

```
config/routes.rb            # YES
routes.rb                   # NO
RAILS_ROOT/config/routes.rb # NO
```

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

```ruby
class Array
  # Calls +to_param+ on all its elements and joins the result with
  # slashes. This is used by +url_for+ in Action Pack.
  def to_param
    collect { |e| e.to_param }.join '/'
  end
end
```

WARNING: 等幅フォントを`+...+`というマークアップで表記するのは、通常のメソッド名、シンボル、（通常のスラッシュを用いる）パスのようなシンプルなものだけにすること。これらよりも複雑なものを表記する場合は必ず`<tt>...</tt>`でマークアップすること。特に名前空間を使うクラス名やモジュール名では必須（`<tt>ActiveRecord::Base</tt>`など）。

RDocの出力は以下のコマンドで手軽に確認できます。

```bash
$ echo "+:to_param+" | rdoc --pipe
# => <p><code>:to_param</code></p>
```

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

動的に生成されるメソッド
-----------------------------

`(module|class)_eval(文字列)`メソッドで作成されるメソッドの右側に、コードで生成されるインスタンスをコメントで書くこと。このように作成されたコメントには、スペース2文字分のインデントを与えること。

```ruby
for severity in Severity.constants
  class_eval <<-EOT, __FILE__, __LINE__ + 1
    def #{severity.downcase}(message = nil, progname = nil, &block)  # def debug(message = nil, progname = nil, &block)
      add(#{severity}, message, progname, &block)                    #   add(DEBUG, message, progname, &block)
    end                                                              # end
                                                                     #
    def #{severity.downcase}?                                        # def debug?
      #{severity} >= @level                                          #   DEBUG >= @level
    end                                                              # end
  EOT
end
```

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
}
```

メソッドの可視性
-----------------

Railsのドキュメントを作成するときは、ユーザー向けに公開するパブリックなAPIと内部APIの違いを理解しておくことが重要です。

多くのライブラリと同様、Railsでも内部APIの定義にprivateキーワードが使われますが、公開するAPIのルールは若干異なります。内部APIであるメソッドには`:nodoc:`ディレクティブを追加すること。

つまりRailsでは、可視性が`public`のメソッドであっても、ユーザーに公開されているとは限りません。

`ActiveRecord::Core::ClassMethods#arel_table`の例

```ruby
module ActiveRecord::Core::ClassMethods
  def arel_table # :nodoc:
    # 何か書く
  end
end
```

上のメソッドは`ActiveRecord::Core`のpublicなクラスメソッドに見えますし、可視性は実際にpublicです。しかしRailsチームはこの種のメソッドに依存して欲しくないと考えているので、`:nodoc:`を指定してAPIドキュメントに出力されないようにしています。可視性をpublicにする実際の理由は、Railsチームがこの種の内部メソッドの振る舞いを必要に応じてリリースごとに変更可能にするためです。これらのメソッドは名前や戻り値が変更されたり、クラス自体が消滅したりする可能性もあるので、外部に対して何も保証しません。Railsアプリケーションやプラグインは、この種のAPIに依存すべきではありません。これらのAPIに依存してしまうと、Railsを次のリリースでアップグレードしたときにアプリケーションやgemが動かなくなるリスクが生じます。

Railsコントリビュータがドキュメントを作成する場合、そのAPIを外部開発者に公開してよいかどうかに常に注意を払うことが重要です。Railsチームは、パブリックなAPIに対する重大な変更は、必ず非推奨サイクルを経てから行なうようにしています。内部メソッドや内部クラスの可視性がprivateになっていない場合は、`:nodoc:`オプションを指定することが推奨されます（なお可視性がprivateの場合はデフォルトで内部扱いになります）。APIが安定した後は可視性の変更も一応可能ですが、後方互換性を維持しながらパブリックAPIを変更するのはかなり困難です。

`:nodoc:`をクラスやモジュールに対して指定すると、それらの中にあるメソッドはすべて内部APIであり、直接のアクセスは許されていないことを示せます。

まとめ: Railsチームは、可視性がpublicで内部利用限定のメソッドやクラスには`:nodoc:`を指定すること。APIの可視性変更は慎重に行なうべきであり、pull requestでの議論を経てからにすること。

Railsスタック
-------------------------

Rails APIの一部をドキュメント化するときは、そのAPIがRailsスタックの一部に組み込まれることを意識することが重要です。

つまり、ドキュメント化するメソッドやクラスのスコープやコンテキストに応じて、振る舞いが変化する可能性があります。

同じコードでも、スタック全体を考慮するとさまざまな場所で振る舞いが変化することがあります。以下の`ActionView::Helpers::AssetTagHelper#image_tag`は典型的な例です。

```ruby
# image_tag("icon.png")
#   # => <img src="/assets/icon.png" />
```

`#image_tag`はデフォルトでは常に`/images/icon.png`を返しますが、アセットパイプラインなどを含むRailsのフルスタックでは上のように結果が変わることがあります。

通常、私たちがRailsフルスタックを使うときは、デフォルトの振る舞いしか気にしないものです。

しかしこの場合は、特定のメソッドの振る舞いだけではなく、**フレームワーク**の振る舞いもドキュメントに書きたいと思うでしょう。

Railsチームが特定のAPIをどのように扱っているかを知りたい場合は、Railsリポジトリでお気軽にissueをオープンするか、[issue tracker][issues]にパッチを送ってください。

[issues]: https://github.com/rails/rails/issues