
API ドキュメント作成ガイドライン
============================

本ガイドでは、Rails APIドキュメント作成のガイドラインについて解説します(訳注: APIドキュメントが英語で書かれることを前提とします。また、サンプルのコメントは基本的に英語のままにしています)。

このガイドの内容:

* APIドキュメントを効果的に書く方法
* ドキュメント作成用のスタイルガイド (Rubyコード開発用のスタイルガイドとは別)

--------------------------------------------------------------------------------

RDoc
----

[Rails API ドキュメント](http://api.rubyonrails.org)は[RDoc](http://docs.seattlerb.org/rdoc/)を使用して生成されます。

```bash
  bundle exec rake rdoc
```

生成されたHTMLファイルは./doc/rdocディレクトリに置かれます。

RDocの記法に関しては、[markup](http://docs.seattlerb.org/rdoc/RDoc/Markup.html)を参照してください(訳注: 別ページですが[日本語のRDocライブラリ解説](http://docs.ruby-lang.org/ja/2.1.0/library/rdoc.html)があります)。[追加のディレクティブ](http://docs.seattlerb.org/rdoc/RDoc/Parser/Ruby.html)にも目を通しておいてください。

語調
-------

簡潔かつ宣言的に書くこと。簡潔さはそれだけで長所になります。

現在形で書くこと。"Returned a hash that..." や "Will return a hash that..." ではなく"Returns a hash that..."のように書く。

コメントの英語は大文字で始めること。句読点や記号の用法は常識に従うこと。

```ruby
# Declares an attribute reader backed by an internally-named
# instance variable.
def attr_internal_reader(*attrs)
  ...
end
```

読者に現時点の最新の方法が伝わるように書くこと、それも明示的かつ暗黙に。先進的な分野で推奨されている慣用表現を使用すること。推奨される方法が強調されるようセクションの順序に注意し、必要であれば順序を入れ替えること。作成するドキュメント自身がRailsのベストプラクティスのよいモデルとなるように、そしてRailsの最新かつ模範的な使用法になるように書くこと。

ドキュメントは簡潔であり、かつ全体を理解できるものであること。例外的なケースについても調査し、ドキュメントに盛り込むこと。あるモジュールが無名であったらどうなるか。あるコレクションの内容が空であったらどうなるか。引数がnilであったらどうなるか。

Railsのコンポーネント名は語の間にスペースを1つ置く表記を正式なものとする (例: "Active Support")。なお、`ActiveRecord`はRubyモジュール名だが、Active RecordはORMを指す。Railsドキュメント内でコンポーネントを指す場合には常に正式名称を使用すること。ブログ投稿やプレゼンテーションなどでもこの点に留意し、異なる名称で読者などを驚かせないようにすること。

正しいスペルを使用すること (Arel、Test::Unit、RSpec、HTML、 MySQL、JavaScript、ERBなど)。大文字小文字にも注意すること。疑わしい場合には公式ドキュメントなど、信頼できる情報源を参照すること。

"SQL" という語の前には冠詞 "an" を付けること (例: "an SQL statement")。同様に、"an SQLite database"のようにすること。

"you"や"your"を使用する表現を避けること。以下の例文ではyouが3度も使用されている。

```markdown
If you need to use `return` statements in your callbacks, it is recommended that you explicitly define them as methods.
```

以下のスタイルで書くこと。

```markdown
If `return` is needed it is recommended to explicitly define a method.
```

同様に、説明上何らかの人物を仮定して、その人物を代名詞で呼ぶ場合 ("a user with a session cookie" など)、heやsheのような性別のある代名詞を避け、they/their/themのような性別に影響されない代名詞を使用すること。以下のように言い換える。

* heまたはshe -> theyに置き換える
* himまたはher -> themに置き換える
* hisまたはher -> theirに置き換える
* hisまたはhers -> theirsに置き換える
* himselfまたはherself -> themselvesに置き換える

英語
-------

アメリカ英語を使用すること ( *color* 、 *center* 、 *modularize* など)。詳細は[アメリカ英語とイギリス英語のスペルの違い](http://en.wikipedia.org/wiki/American_and_British_English_spelling_differences) (英語) を参照してください。

サンプルコード
------------

意味のあるサンプルコードを選ぶこと。概要と基本を端的に示し、かつ興味深い点や落とし穴も示されているのが理想です。

サンプルコードのインデントにはスペース2文字を使用すること。マークアップ用には左マージンに合わせてスペース2文字を使用します。サンプルコードの例は[Railsコーディングルールに従う](contributing_to_ruby_on_rails.html#rails%E3%82%B3%E3%83%BC%E3%83%87%E3%82%A3%E3%83%B3%E3%82%B0%E3%83%AB%E3%83%BC%E3%83%AB%E3%81%AB%E5%BE%93%E3%81%86)を参照してください。

短いドキュメントでは、スニペットを紹介する際に"Examples"と明示的にラベルを付ける必要はない。単にパラグラフに従うようにします。

```ruby
# Converts a collection of elements into a formatted string by
# calling +to_s+ on all elements and joining them.
#
#   Blog.all.to_formatted_s # => "First PostSecond PostThird Post"
```

逆に大きな章で構成されているドキュメントであれば、"Examples"セクションを設けてもよい。

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

1つの行が長くなりすぎる場合はコメントを次の行に置いてもよい

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

実行結果を示すために`puts`や`p`などの印字用メソッドを使用することはなるべく避ける。

逆に、(実行結果を示さない) 通常のコメントでは矢印を使用しないこと。

```ruby
#   polymorphic_url(record)  # same as comment_url(record)
```

論理値
--------

述語やフラグでの論理値の表記は、正確な値表現よりも、論理値の意味を優先すること。

"true"および"false"をRubyの定義どおりに使用する場合は、通常のフォントで表記すること。シングルトンの`true`および`false`は等幅フォントで表記すること(訳注: シングルトンの`true`および`false`とは、`TrueClass`および`FalseClass`の唯一のインスタンスのことです)。"truthy"のような用語は避けてください。Rubyでは言語レベルでtrueとfalseが定義されているので、これらの用語は技術的に厳密な意味が与えられており、言い方を変える必要はありません。

経験から申し上げると、どうしても必要な場合を除いて、ドキュメントでシングルトンを使用すべきではありません。シングルトンを避けることで、`!!`や三項演算子のような人工的な表現を避けることができ、リファクタリングもしやすくなります。さらに、実装で呼び出されるメソッドが返す値の表現が少しでも違うとコードが正常に動作しないという事態も避けられます。

以下の例で説明します。

```markdown
`config.action_mailer.perform_deliveries` specifies whether mail will actually be delivered and is true by default (訳: `config.action_mailer.perform_deliveries`は、メールを実際に配信するかどうかを指定します。デフォルト値はtrueです。)
```

上の例では、フラグのデフォルト値の実際の表現がどれであるか (訳注: シングルトンのtrueなのか、trueと評価されるオブジェクトなのか) を知る必要はありません。従って、論理値の意味だけをドキュメントに書くべきです。

以下は述語の例です。

```ruby
# Returns true if the collection is empty. (訳:コレクションが空ならtrueを返す)
#
# If the collection has been loaded (コレクションが読み込まれると)
# it is equivalent to <tt>collection.size.zero?</tt>. if the (<tt>collection.size.zero?</tt>と同値)
# collection has not been loaded, it is equivalent to (コレクションが読み込まれなかった場合は)
# <tt>collection.exists?</tt>. If the collection has not already been (<tt>collection.exists?</tt>と同値。コレクションが読み込まれておらず、)
# loaded and you are going to fetch the records anyway it is better to (どうしてもレコードを取り出したい場合は)
# check <tt>collection.length.zero?</tt>. (<tt>collection.length.zero?</tt>をチェックすること)
def empty?
  if loaded?
    size.zero?
  else
    @target.blank? && !scope.exists?
  end
end
```

このAPIは特定の値にコミットしないように注意が払われており、メソッドには述語と意味が示されています。これで十分です。

ファイル名
----------

経験則からも、ファイル名はRailsアプリケーションのルート・ディレクトリからの相対パスで記述すること。

```
config/routes.rb            # YES
routes.rb                   # NO
RAILS_ROOT/config/routes.rb # NO
```

フォント
-----

### 等幅フォント

以下の場合は等幅フォントを使用すること。

* 定数、特にクラス名およびモジュール名
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

WARNING: 等幅フォントを`+...+`というマークアップで表記できるのは、通常のメソッド名、シンボル、パス (通常のスラッシュを使用しているもの) のようなシンプルなものに限られます。これらよりも複雑なものを表記するときには必ず`<tt>...</tt>`でマークアップしてください。特に名前空間を使用しているクラス名やモジュール名では必須です (`<tt>ActiveRecord::Base</tt>`など)。

以下のコマンドで、RDocの出力を手軽に確認できます。

```
$ echo "+:to_param+" | rdoc --pipe
#=> <p><code>:to_param</code></p>
```

### Regularフォント

Rubyのキーワードでない、英語としての"true"と"false"にはregularフォント (ItalicやBoldでないフォント) を使用すること。

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
  ...
end
```

説明のリスト
-----------------

項目 (オプションやパラメータのリストなど) とその説明はハイフンでつなぐこと。コロンはシンボルで使用されるので、ハイフンの方が読みやすくなります。

```ruby
# * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
```

説明文は通常の英語として大文字で始め、ピリオドで終わること。

動的に生成されるメソッド
-----------------------------

`(module|class)_eval(文字列)`メソッドで作成されるメソッドには、生成されたコードのインスタンスのそばにコメントが置かれます。このように作成されたコメントには、スペース2文字分のインデントが与えられます。

```ruby
for severity in Severity.constants
  class_eval <<-EOT, __FILE__, __LINE__
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

生成された行が多過ぎる (200行を超える) 場合、コメントを呼び出しの上に置いてください。

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

Railsのドキュメントを作成するにあたり、ユーザー向けのパブリックなAPIと内部APIの違いを理解しておくことが重要です。

多くのライブラリと同様、Railsでも内部APIの定義にprivateキーワードが使用されます。しかし、パブリックなAPIのルールは若干異なります。Railsでは、すべてのpublicなメソッドがユーザーに公開されて使用されるということを前提にしていません。代りに、そのメソッドが内部APIであることを示すために`:nodoc:`ディレクティブを使用します。

つまり、Railsでは可視性が`public`のメソッドであっても、ユーザーに公開されているとは限らないのです。

`ActiveRecord::Core::ClassMethods#arel_table`を例に説明します。

```ruby
module ActiveRecord::Core::ClassMethods
  def arel_table #:nodoc:
    # 何か書く
  end
end
```

このメソッドは一見して`ActiveRecord::Core`のパブリックなクラスメソッドであり、実際それ自体は間違いではありません。しかしRailsチームはこの種のメソッドに依存して欲しくないと考えています。そのために`:nodoc:`を指定して、ドキュメントに含まれないようにしています。実際の理由は、Railsチームはこの種の内部メソッドの動作を必要に応じてリリースごとに変更できるようにしたいからです。これらのメソッドは名前や戻り値が変更されたり、クラス自体が消滅したりすることもありえます。従ってこれらは外部に対して何も保証されておらず、Railsアプリケーションやプラグインがこの種のAPIに依存すべきではありません。これらのAPIに依存してしまうと、Railsを次のリリースにアップグレードしたときにアプリケーションやGemが壊れる危険性があります。

Rails貢献者がドキュメントを作成する場合、そのAPIを外部開発者に公開してよいかどうかに常に注意を払う必要があります。Railsチームは、パブリックなAPIに対して重大な変更を行なう際は、必ず非推奨サイクルを経てから行なうことにしています。内部メソッドや内部クラスの可視性がprivateになっていない場合は、`:nodoc:`オプションを指定することを推奨します (なお可視性がprivateの場合はデフォルトで内部扱いになります)。APIが安定したら可視性を変更できますが、後方互換性を保ちながらパブリックなAPIを変更することは簡単ではありません。

クラスやモジュールに対して`:nodoc:`を指定した場合、その中のすべてのメソッドは内部APIであり、直接アクセスすることは許されないことが示されます。

既存の`:nodoc:`指定はむやみに変更しないでください。この指定を外す際は、必ずコアチームの誰かかコードの著者に相談してからにしてください。`:nodoc:`が外されてしまうエラーは、docrailsプロジェクトよりもほとんどの場合pull requestで発生します。

`:nodoc:`の追加は、絶対に無断で行わないでください。ドキュメントからそのメソッドやクラスの記述が失われてしまいます。たとえば、あるメソッドの可視性をprivateからpublicに切り替えた際に、内部のパブリックメソッドに`:nodoc:`が指定されていなかったという事例がありえます。そのようなケースを見つけたら、必要に応じてpull requestで議論してください。直接docrailsを変更することはくれぐれも行わないでください。

まとめ: Railsチームは可視性がpublicで内部でのみ使用するメソッドやクラスには`:nodoc:`を指定します。APIの可視性の変更は慎重に行なわれるべきであり、pull requestでの議論を経てから行なうこと。

Railsスタック
-------------------------

Rails APIの一部をドキュメント化する際には、それがRailsスタックのひとつとなることを意識しておくことが重要です。

つまり、ドキュメント化しようとしているメソッドやクラスのスコープやコンテキストに応じて振る舞いが変化することがあるということです。

スタック全体を考慮に入れれば、振る舞いの変化するはあちこちに見つかります。`ActionView::Helpers::AssetTagHelper#image_tag`などが典型です。

```ruby
# image_tag("icon.png")
#   # => <img alt="Icon" src="/assets/icon.png" />
```

`#image_tag`はデフォルトでは常に`/images/icon.png`を返しますが、アセットパイプラインなどを含むRailsのフルスタックで見ると、上のような結果が返されるところもあります。

デフォルトのRailsフルスタックを使用している場合、実際に経験する振る舞いに対してしか関心が持てないものです。

このような場合、特定のメソッドの振る舞いだけではなく、 _フレームワーク_ の振る舞いもドキュメント化するようにしたいと思います。

Railsチームが特定のAPIをどのように扱っているかを知りたい場合は、お気軽にチケットを発行して[issue tracker](https://github.com/rails/rails/issues)にパッチを送ってください。