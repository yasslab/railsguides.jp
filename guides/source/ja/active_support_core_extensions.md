**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Support コア拡張機能
==============================

Active SupportはRuby on Railsのコンポーネントであり、Ruby言語の拡張、ユーティリティ、その他横断的な作業を担っています。

Active Supportは言語レベルで基本部分を底上げして豊かなものにし、Railsアプリケーションの開発とRuby on Railsそれ自体の開発に役立てるべく作られています。

このガイドの内容:

* コア拡張機能（Core Extensions）について
* すべての拡張機能を読み込む方法
* 必要な拡張機能だけを利用する方法
* Active Supportが提供する拡張機能一覧

--------------------------------------------------------------------------------

コア拡張機能を読み込む方法
---------------------------

### 単体のActive Support

フットプリントをほぼ残さないようにするため、Active Supportはデフォルトでは何も読み込みません。Active Supportは細かく分割され、必要な拡張機能だけが読み込まれるようになっています。また、関連する拡張機能(場合によってはすべての拡張機能)も同時に読み込むのに便利なエントリポイントもあります。

したがって、以下のような`require`文を実行しただけでは、オブジェクトは`blank?`にすら応答してくれません。

```ruby
require 'active_support'
```

この定義がどのように読み込まれるかを見てみましょう。

#### 必要な定義だけを選ぶ

`blank?`メソッドを使えるようにする最も「軽量な」方法は、そのメソッドが定義されているファイルだけを指定して読み込むことです。

本ガイドでは、コア拡張機能として定義されているすべてのメソッドについて、その定義ファイルの置き場所も示してあります。たとえば`blank?`の場合、以下のようなメモを追加してあります。

NOTE: 定義は`active_support/core_ext/object/blank.rb`にあります。

つまり、以下のようにピンポイントでrequireを実行できます。

```ruby
require 'active_support'
require 'active_support/core_ext/object/blank'
```

Active Supportの改訂は注意深く行われていますので、あるファイルを選んだ場合、本当に必要な依存ファイルだけが同時に読み込まれます(依存関係がある場合)。

#### コア拡張機能をグループ化して読み込む

次の段階として、`Object`に対するすべての拡張機能を単に読み込んでみましょう。経験則として、`SomeClass`というクラスがあれば、`active_support/core_ext/some_class`というパスを指定することで一度に読み込めます。

従って、(`blank?`を含む)`Object`に対するすべての拡張機能を読み込む場合には以下のようにします。

```ruby
require 'active_support'
require 'active_support/core_ext/object'
```

#### すべてのコア拡張機能を読み込む

すべてのコア拡張機能を単に読み込みたい場合は、以下のように`require`します。

```ruby
require 'active_support'
require 'active_support/core_ext'
```

#### すべてのActive Supportを読み込む

最後に、利用可能なActive Supportをすべて読み込みたい場合は以下のようにします。

```ruby
require 'active_support/all'
```

ただし、これを実行してもActive Support全体がメモリに読み込まれるわけではないことにご注意ください。一部は`autoload`として設定されており、実際に使うまで読み込まれません。

### Ruby on RailsアプリケーションでActive Supportを使う

Ruby on Railsアプリケーションでは、基本的にすべてのActive Supportを読み込みます。例外は`config.active_support.bare`を`true`に設定した場合です。このオプションを`true`にすると、フレームワーク自体が必要とするまでアプリケーションは拡張機能を読み込みません。また上で解説したように、読み込まれる拡張機能はあらゆる粒度で選択されます。

すべてのオブジェクトで使える拡張機能
-------------------------

### `blank?`と`present?`

Railsアプリケーションは以下の値を空白(blank)とみなします。

* `nil`と`false`

* 空白文字 (whitespace) だけで構成された文字列 (以下の注釈を参照)

* 空欄の配列とハッシュ

* その他、`empty?`メソッドに応答するオブジェクトはすべて空白として扱われます。

INFO: 文字列を判定する述語として、Unicode対応した文字クラスである`[:space:]`が使われています。そのため、たとえばU+2029 (段落区切り文字)は空白文字と判断されます。

WARNING: 数字については空白であるかどうかは判断されません。特に0および0.0は**空白ではありません**のでご注意ください。

たとえば、`ActionController::HttpAuthentication::Token::ControllerMethods`にある以下のメソッドではトークンが存在しているかどうかを`blank?`でチェックしています。

```ruby
def authenticate(controller, &login_procedure)
  token, options = token_and_options(controller.request)
  unless token.blank?
    login_procedure.call(token, options)
  end
end
```

`present?`メソッドは`!blank?`メソッドと同等です。以下の例は`ActionDispatch::Http::Cache::Response`から引用しました。

```ruby
def set_conditional_cache_control!
  return if self["Cache-Control"].present?
  ...
end
```

NOTE: 定義は`active_support/core_ext/object/blank.rb`にあります。

### `presence`

`presence`メソッドは、`present?`が`true`の場合は自身のレシーバを返し、falseの場合は`nil`を返します。このメソッドは以下のような便利な定番の用法があります。

```ruby
host = config[:host].presence || 'localhost'
```

NOTE: 定義は`active_support/core_ext/object/blank.rb`にあります。

### `duplicable?`

Ruby 2.5からは、ほとんどのオブジェクトを`dup`や`clone`で複製できます。

```ruby
"foo".dup           # => "foo"
"".dup              # => ""
Rational(1).dup     # => (1/1)
Complex(0).dup      # => (0+0i)
1.method(:+).dup    # => TypeError (allocator undefined for Method)
```

Active Supportでは、複製可能かどうかをオブジェクトに問い合わせる`duplicable?`が提供されています。

```ruby
"foo".duplicable?           # => true
"".duplicable?              # => true
Rational(1).duplicable?     # => true
Complex(1).duplicable?      # => true
1.method(:+).duplicable?    # => false
```

WARNING: どんなクラスでも、`dup`メソッドと`clone`メソッドを除去することでこれらのメソッドを無効にできます。このとき、これらのメソッドが実行されると例外が発生します。このような状態では、どんなオブジェクトについてもそれが複製可能かどうかを確認するには`rescue`を使う以外に方法はありません。`duplicable?`メソッドは、上のハードコードされたリストに依存しますが、その代わり`rescue`よりずっと高速です。実際のユースケースでハードコードされたリストで十分であることがわかっている場合には、`duplicable?`をお使いください。

NOTE: 定義は`active_support/core_ext/object/duplicable.rb`にあります。

### `deep_dup`

`deep_dup`メソッドは、与えられたオブジェクトの「ディープコピー」を返します。Rubyは通常の場合、他のオブジェクトを含むオブジェクトを`dup`しても、含まれている他のオブジェクトを複製しません。このようなコピーは「浅いコピー (shallow copy)」と呼ばれます。たとえば、以下のように文字列を含む配列があるとします。

```ruby
array     = ['string']
duplicate = array.dup

duplicate.push 'another-string'

# このオブジェクトは複製されたので、複製された方にだけ要素が追加された
array     # => ['string']
duplicate # => ['string', 'another-string']

duplicate.first.gsub!('string', 'foo')

# 1つ目の要素は複製されていないので、一方を変更するとどちらの配列も変更される
array     # => ['foo']
duplicate # => ['foo', 'another-string']
```

上で見たとおり、`Array`のインスタンスを複製して別のオブジェクトができたことにより、一方を変更しても他方は変更されないようになりました。ただし、配列は複製されましたが、配列の要素はそうではありません。`dup`メソッドはディープコピーを行わないので、配列の中にある文字列は複製後も同一オブジェクトのままです。

オブジェクトをディープコピーする必要がある場合は次のように`deep_dup`をお使いください。

```ruby
array     = ['string']
duplicate = array.deep_dup

duplicate.first.gsub!('string', 'foo')

array     # => ['string']
duplicate # => ['foo']
```

オブジェクトが複製可能でない場合、`deep_dup`は単にそのオブジェクトを返します。

```ruby
number = 1
duplicate = number.deep_dup
number.object_id == duplicate.object_id   # => true
```

NOTE: 定義は`active_support/core_ext/object/deep_dup.rb`にあります。

### `try`

`nil`でない場合にのみオブジェクトのメソッドを呼び出したい場合、最も単純な方法は条件文を追加することですが、どこか冗長になってしまいます。そこで`try`メソッドを使うという手があります。`try`は`Object#send`と似ていますが、`nil`に送信された場合には`nil`を返す点が異なります。

例:

```ruby
# tryメソッドを使わない場合
unless @number.nil?
  @number.next
end

# tryメソッドを使った場合
@number.try(:next)
```

`ActiveRecord::ConnectionAdapters::AbstractAdapter`から別の例として以下をご紹介します。ここでは`@logger`が`nil`になることがあります。このコードでは`try`を使ったことで余分なチェックを行わずに済んでいます。

```ruby
def log_info(sql, name, ms)
  if @logger.try(:debug?)
    name = '%s (%.1fms)' % [name || 'SQL', ms]
    @logger.debug(format_log_entry(name, sql.squeeze(' ')))
  end
end
```

`try`メソッドは引数の代りにブロックを与えて呼び出すこともできます。この場合オブジェクトが`nil`でない場合にのみブロックが実行されます。

```ruby
@person.try { |p| "#{p.first_name} #{p.last_name}" }
```

`try`メソッドは、`NoMethodError`を握りつぶして代わりに`nil`を返す点に注意が必要です。メソッド名の誤りを防ぎたい場合は`try!`を使います。

```ruby
@number.try(:nest)  # => nil
@number.try!(:nest) # NoMethodError: undefined method `nest' for 1:Integer
```

NOTE: 定義は`active_support/core_ext/object/try.rb`にあります。

### `class_eval(*args, &block)`

`class_eval`メソッドを使って、あらゆるオブジェクトのsingletonクラスのコンテキストでコードを評価できます。

```ruby
class Proc
  def bind(object)
    block, time = self, Time.current
    object.class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end
```

NOTE: 定義は`active_support/core_ext/kernel/singleton_class.rb`にあります。

### `acts_like?(duck)`

`acts_like?`メソッドは、一部のクラスがその他のクラスと同様に振る舞うかどうかを、ある慣例に沿ってチェックします。`String`クラスと同じインターフェイスを提供するクラスがあり、その中で以下のメソッドを定義しておくとします。

```ruby
def acts_like_string?
end
```

このメソッドは単なる目印であり、メソッドの本体と戻り値の間に関連はありません。これにより、クライアントコードで以下のようなダックタイピングチェックを行えます。

```ruby
some_klass.acts_like?(:string)
```

Railsには`Date`クラスや`Time`クラスと同様に振る舞うクラスがいくつかあり、この手法を使えます。

NOTE: 定義は`active_support/core_ext/object/acts_like.rb`にあります。

### `to_param`

Railsのあらゆるオブジェクトは`to_param`メソッドに応答します。これは、オブジェクトを値として表現するものを返すということです。返された値はクエリ文字列やURLの一部で利用できます。

デフォルトでは、`to_param`メソッドは単に`to_s`メソッドを呼び出します。

```ruby
7.to_param # => "7"
```

`to_param`によって返された値を **エスケープしてはいけません** 。

```ruby
"Tom & Jerry".to_param # => "Tom & Jerry"
```

このメソッドは、Railsの多くのクラスで上書きされています。

たとえば、`nil`、`true`、`false`の場合は自分自身を返します。`Array#to_param`を実行すると、`to_param`が配列内の各要素に対して実行され、結果が「/」でjoinされます。

```ruby
[0, true, String].to_param # => "0/true/String"
```

特に、Railsのルーティングシステムはモデルに対して`to_param`メソッドを実行することで、`:id`プレースホルダの値を取得しています。`ActiveRecord::Base#to_param`はモデルの`id`を返しますが、このメソッドをモデル内で再定義することもできます。以下のコード例があるとします。

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

上のコードから以下の結果を得られます。

```ruby
user_path(@user) # => "/users/357-john-smith"
```

WARNING: コントローラ側では、`to_param`メソッドがモデル側で再定義されている可能性があることに常に注意しておく必要があります。上のようなリクエストを受信した場合、`params[:id]`の値が「357-john-smith」になるからです。

NOTE: 定義は`active_support/core_ext/object/to_param.rb`にあります。

### `to_query`

このメソッドは、エスケープされていない`key`を受け取ると、そのキーを`to_param`が返す値に対応させるクエリ文字列の一部を生成します。ただしハッシュは例外です(後述)。以下のコード例があるとします。

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

上のコードから以下の結果を得られます。

```ruby
current_user.to_query('user') # => "user=357-john-smith"
```

このメソッドは、キーと値のいずれについても、必要な箇所をすべてエスケープします。

```ruby
account.to_query('company[name]')
# => "company%5Bname%5D=Johnson+%26+Johnson"
```

これにより、この結果をそのままクエリ文字列として利用できます。

配列に`to_query`メソッドを適用した場合、`to_query`を配列の各要素に適用して`key[]`をキーとして追加し、それらを「&」で連結したものを返します。

```ruby
[3.4, -45.6].to_query('sample')
# => "sample%5B%5D=3.4&sample%5B%5D=-45.6"
```

ハッシュも`to_query`に応答しますが、使われるシグネチャが異なります。メソッドに引数が渡されない場合、このメソッド呼び出しは、一連のキー/値ペアをソート済みの形で生成し、それぞれの値に対して`to_query(key)`を呼び出し、結果を「&」で連結します。

```ruby
{c: 3, b: 2, a: 1}.to_query # => "a=1&b=2&c=3"
```

`Hash#to_query`メソッドは、それらのキーに対して名前空間をオプションで与えることもできます。

```ruby
{id: 89, name: "John Smith"}.to_query('user')
# => "user%5Bid%5D=89&user%5Bname%5D=John+Smith"
```

NOTE: 定義は`active_support/core_ext/object/to_query.rb`にあります。

### `with_options`

`with_options`メソッドは、連続した複数のメソッド呼び出しに対して共通して与えられるオプションを解釈するための手段を提供します。

デフォルトのオプションがハッシュで与えられると、`with_options`はブロックに対するプロキシオブジェクトを生成します。そのブロック内では、プロキシに対して呼び出されたメソッドにオプションを追加したうえで、そのメソッドをレシーバに転送します。たとえば、以下のように同じオプションを繰り返さないで済むようになります。

```ruby
class Account < ApplicationRecord
  has_many :customers, dependent: :destroy
  has_many :products,  dependent: :destroy
  has_many :invoices,  dependent: :destroy
  has_many :expenses,  dependent: :destroy
end
```

上のコードを以下のように書けます。

```ruby
class Account < ApplicationRecord
  with_options dependent: :destroy do |assoc|
    assoc.has_many :customers
    assoc.has_many :products
    assoc.has_many :invoices
    assoc.has_many :expenses
  end
end
```

この手法を使って、たとえばニュースレターの読者を言語ごとに「グループ化」できます。読者が話す言語に応じて異なるニュースレターを送信したいとします。メール送信用のコードのどこかで、以下のような感じでロケール依存ビットをグループ化できます。

```ruby
I18n.with_options locale: user.locale, scope: "newsletter" do |i18n|
  subject i18n.t :subject
  body    i18n.t :body, user_name: user.name
end
```

TIP: `with_options`はメソッドをレシーバに転送しているので、呼び出しをネストすることもできます。各ネスティングレベルでは、自身の呼び出しに、継承したデフォルト呼び出しをマージします。

NOTE: 定義は`active_support/core_ext/object/with_options.rb`にあります。

### JSONのサポート

Active Supportが提供する`to_json`メソッドの実装は、通常`json` gemがRubyオブジェクトに対して提供している`to_json`よりも優れています。その理由は、`Hash`や`OrderedHash`、`Process::Status`などのクラスでは、正しいJSON表現を提供するために特別な処理が必要になるためです。

NOTE: 定義は`active_support/core_ext/object/json.rb`にあります。

### インスタンス変数

Active Supportは、インスタンス変数に簡単にアクセスするためのメソッドを多数提供しています。

#### `instance_values`

`instance_values`メソッドはハッシュを返します。インスタンス変数名から「@」を除いたものがハッシュのキーに、インスタンス変数の値がハッシュの値にマップされます。キーは文字列です。

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_values # => {"x" => 0, "y" => 1}
```

NOTE: 定義は`active_support/core_ext/object/instance_variables.rb`にあります。

#### `instance_variable_names`

`instance_variable_names`メソッドは配列を返します。配列のインスタンス名には「@」記号が含まれます。

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_variable_names # => ["@x", "@y"]
```

NOTE: 定義は`active_support/core_ext/object/instance_variables.rb`にあります。

### 警告や例外の抑制

`silence_warnings`メソッドと`enable_warnings`メソッドは、ブロックが継続する間`$VERBOSE`の値を変更し、その後リセットします。

```ruby
silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
```

`suppress`メソッドを使って例外の発生を止めることもできます。このメソッドは、例外クラスを表す任意の数値を受け取ります。`suppress`は、あるブロックの実行時に例外が発生し、その例外が(`kind_of?`による判定で)いずれかの引数に一致する場合、それをキャプチャして例外を発生せずに戻ります。一致しない場合、例外はキャプチャされません。

```ruby
# ユーザーがロックされていればインクリメントは失われるが、重要ではない
suppress(ActiveRecord::StaleObjectError) do
  current_user.increment! :visits
end
```

NOTE: 定義は`active_support/core_ext/kernel/reporting.rb`にあります。

### `in?`

述語`in?`は、あるオブジェクトが他のオブジェクトに含まれているかどうかをテストします。渡された引数が`include?`に応答しない場合は`ArgumentError`例外が発生します。

`in?`の例を示します。

```ruby
1.in?([1,2])        # => true
"lo".in?("hello")   # => true
25.in?(30..50)      # => false
1.in?(1)            # => ArgumentError
```

NOTE: 定義は`active_support/core_ext/object/inclusion.rb`にあります。

`Module`の拡張
----------------------

### 属性

#### `alias_attribute`

モデルの属性には、リーダー (reader)、ライター (writer)、述語 (predicate) があります。これらに対応する3つのメソッドを持つ、モデルの属性の別名 (alias) を一度に作成できます。他の別名作成メソッドと同様、1つ目の引数には新しい名前、2つ目の引数には元の名前を指定します (変数に代入するときと同じ順序、と覚えておく手もあります)。

```ruby
class User < ApplicationRecord
  # emailカラムを"login"という名前でも参照したい
  # そうすることで認証のコードがわかりやすくなる
  alias_attribute :login, :email
end
```

NOTE: 定義は`active_support/core_ext/module/aliasing.rb`にあります。

#### 内部属性

あるクラスで属性を定義すると、後でそのクラスのサブクラスが作成されるときに名前が衝突するリスクが生じます。これはライブラリにおいては特に重要な問題です。

Active Supportでは、`attr_internal_reader`、`attr_internal_writer`、`attr_internal_accessor`というマクロが定義されています。これらのマクロは、Rubyにビルトインされている`attr_*`と同様に振る舞いますが、内部のインスタンス変数の名前が衝突しにくいように配慮される点が異なります。

`attr_internal`マクロは`attr_internal_accessor`と同義です。

```ruby
# ライブラリ
class ThirdPartyLibrary::Crawler
  attr_internal :log_level
end

# クライアントコード
class MyCrawler < ThirdPartyLibrary::Crawler
  attr_accessor :log_level
end
```

先の例では、`:log_level`はライブラリのパブリックインターフェイスに属さず、開発中以外は使われません。クライアント側のコードでは衝突の可能性について考慮せずに独自に`:log_level`をサブクラスで定義しています。ライブラリ側で`attr_internal`を使っているおかげで衝突が生じずに済んでいます。

このとき、内部インスタンス変数の名前にはデフォルトで冒頭にアンダースコアが追加されます。上の例であれば`@_log_level`となります。この動作は`Module.attr_internal_naming_format`で変更することもできます。`sprintf`と同様のフォーマット文字列を与え、冒頭に`@`を置き、それ以外の名前を置きたい場所に`%s`を置きます。デフォルト値は`"@_%s"`です。

Railsではこの内部属性を他の場所でも若干使っています。たとえばビューでは以下のように使われています。

```ruby
module ActionView
  class Base
    attr_internal :captures
    attr_internal :request, :layout
    attr_internal :controller, :template
  end
end
```

NOTE: 定義は`active_support/core_ext/module/attr_internal.rb`にあります。

#### モジュール属性

`mattr_reader`、`mattr_writer`、`mattr_accessor`という3つのマクロは、クラス用に定義される`cattr_*`マクロと同じです。実際、`cattr_*`マクロは単なる`mattr_*`マクロの別名です。[クラス属性](#class属性)も参照してください。

たとえば、これらのマクロは以下のDependenciesモジュールで使われています。

```ruby
module ActiveSupport
  module Dependencies
    mattr_accessor :warnings_on_first_load
    mattr_accessor :history
    mattr_accessor :loaded
    mattr_accessor :mechanism
    mattr_accessor :load_paths
    mattr_accessor :load_once_paths
    mattr_accessor :autoloaded_constants
    mattr_accessor :explicitly_unloadable_constants
    mattr_accessor :constant_watch_stack
    mattr_accessor :constant_watch_stack_mutex
  end
end
```

NOTE: 定義は`active_support/core_ext/module/attribute_accessors.rb`にあります。

### 親

#### `module_parent`

`module_parent`メソッドは、名前がネストしたモジュールに対して実行でき、対応する定数を持つモジュールを返します。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent # => X::Y
M.module_parent       # => X::Y
```

モジュールが無名またはトップレベルの場合、`module_parent`は`Object`を返します。

WARNING: `parent_name`は上の場合でも`nil`を返します。

NOTE: 定義は`active_support/core_ext/module/introspection.rb`にあります。

#### `module_parent_name`

名前がネストしたモジュールに対して`module_parent_name`メソッドを実行すると、対応する定数を持つモジュールを返します。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent_name # => "X::Y"
M.module_parent_name       # => "X::Y"
```

モジュールが無名またはトップレベルの場合、`module_parent_name`は`nil`を返します。

WARNING: `module_parent`はこの場合`Object`を返します。

NOTE: 定義は`active_support/core_ext/module/introspection.rb`にあります。

#### `module_parents`

`module_parents`メソッドは、レシーバに対して`module_parent`を呼び出し、`Object`に到着するまでパスをさかのぼります。連鎖したモジュールは、階層の下から上の順に配列として返されます。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parents # => [X::Y, X, Object]
M.module_parents       # => [X::Y, X, Object]
```

NOTE: 定義は`active_support/core_ext/module/introspection.rb`にあります。

### 無名モジュール

モジュールには名前がある場合とない場合があります。

```ruby
module M
end
M.name # => "M"

N = Module.new
N.name # => "N"

Module.new.name # => nil
```

モジュールに名前があるかどうかを述語メソッド`anonymous?`でチェックできます。

```ruby
module M
end
M.anonymous? # => false

Module.new.anonymous? # => true
```

到達不能な（unreachable）モジュールが必ずしも無名（anonymous）とは限りません。

```ruby
module M
end

m = Object.send(:remove_const, :M)

m.anonymous? # => false
```

逆に無名モジュールは、定義上必ず到達不能になります。

NOTE: 定義は`active_support/core_ext/module/anonymous.rb`にあります。

### メソッドの委譲

#### `delegate`

`delegate`マクロを使って、メソッドを簡単に委譲できます。

あるアプリケーションの`User`モデルにログイン情報があり、それに関連する名前などの情報は`Profile`モデルにあるとします。

```ruby
class User < ApplicationRecord
  has_one :profile
end
```

この構成では、`user.profile.name`のようにプロファイル越しにユーザー名を取得することになります。これらの属性に直接アクセスできたらもっと便利になるでしょう。

```ruby
class User < ApplicationRecord
  has_one :profile

  def name
    profile.name
  end
end
```

これは`delegate`でできます。

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate :name, to: :profile
end
```

この方法なら記述が短くて済み、意味も明快です。

委譲するメソッドは対象クラス内でpublicでなければなりません。

`delegate`マクロには複数のメソッドを指定できます。

```ruby
delegate :name, :age, :address, :twitter, to: :profile
```

`:to`オプションが文字列に変換されると、メソッドの委譲先となるオブジェクトに評価される式になります。通常は文字列またはシンボルになります。そのような式は、レシーバのコンテキストで評価されます。

```ruby
# Rails定数を委譲する
delegate :logger, to: :Rails

# レシーバのクラスに委譲する
delegate :table_name, to: :class
```

WARNING: `:prefix`オプションが`true`の場合、一般性が低下します (後述)。

委譲時に`NoMethodError`が発生して対象が`nil`の場合、例外が発生します。`:allow_nil`オプションを使うと、例外の代りに`nil`を返すようにすることができます。

```ruby
delegate :name, to: :profile, allow_nil: true
```

`:allow_nil`を指定すると、ユーザーのプロファイルがない場合に`user.name`呼び出しは`nil`を返します。

`:prefix`オプションをtrueにすると、生成されたメソッドの名前にプレフィックスを追加します。これは、たとえばよりよい名前にしたい場合に便利です。

```ruby
delegate :street, to: :address, prefix: true
```

上の例では、`street`ではなく`address_street`が生成されます。

WARNING: この場合、生成されるメソッドの名前では、対象となるオブジェクト名とメソッド名が使われます。`:to`オプションで指定するのはメソッド名でなければなりません。

プレフィックスをカスタマイズすることもできます。

```ruby
delegate :size, to: :attachment, prefix: :avatar
```

上の例では、マクロによって`size`の代わりに`avatar_size`が生成されます。

`:private`オプションはメソッドのスコープを変更します。

```ruby
delegate :date_of_birth, to: :profile, private: true
```

委譲されたメソッドはデフォルトでpublicになりますが、`private: true`を渡すことで変更できます。

NOTE: 定義は`active_support/core_ext/module/delegation.rb`にあります。

#### `delegate_missing_to`

`User`オブジェクトにないものを`Profile`にあるものにすべて委譲したいとしましょう。`delegate_missing_to`マクロを使えばこれを簡単に実装できます。

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate_missing_to :profile
end
```

オブジェクト内にある呼び出し可能なもの（インスタンス変数、メソッド、定数など）なら何でも対象にできます。対象のうち、publicなメソッドだけが委譲されます。

NOTE: 定義は`active_support/core_ext/module/delegation.rb`にあります。

### メソッドの再定義

メソッドを`define_method`で再定義する必要があるが、その名前が既にあるかどうかがわからないとことがあります。有効な名前が既にあれば警告が表示されます。警告が表示されても大したことはありませんが、邪魔に思えることもあります。

`redefine_method`メソッドを使うと、必要に応じて既存のメソッドが削除されるので、このような警告表示を抑制できます。

（`delegate`を使っているなどの理由で）メソッド自身の置き換えを定義する必要がある場合は、`silence_redefinition_of_method`を使うこともできます。

NOTE: 定義は`active_support/core_ext/module/redefine_method.rb`にあります。

`Class`の拡張
---------------------

### Class属性

#### `class_attribute`

`class_attribute`メソッドは、1つ以上の継承可能なクラスの属性を宣言します。そのクラス属性は、その下のどの階層でも上書き可能です。

```ruby
class A
  class_attribute :x
end

class B < A; end

class C < B; end

A.x = :a
B.x # => :a
C.x # => :a

B.x = :b
A.x # => :a
C.x # => :b

C.x = :c
A.x # => :a
B.x # => :b
```

たとえば、`ActionMailer::Base`に以下の定義があるとします。

```ruby
class_attribute :default_params
self.default_params = {
  mime_version: "1.0",
  charset: "UTF-8",
  content_type: "text/plain",
  parts_order: [ "text/plain", "text/enriched", "text/html" ]
}.freeze
```

これらの属性はインスタンスのレベルでアクセスまたはオーバーライドできます。

```ruby
A.x = 1

a1 = A.new
a2 = A.new
a2.x = 2

a1.x # => 1 (Aが使われる)
a2.x # => 2 (a2でオーバーライドされる)
```

`:instance_writer`を`false`に設定すれば、writerインスタンスメソッドは生成されません。

```ruby
module ActiveRecord
  class Base
    class_attribute :table_name_prefix, instance_writer: false, default: "my"
  end
end
```

上のオプションは、モデルの属性設定時にマスアサインメントを防止するのに便利です。

`:instance_reader`を`false`に設定すれば、readerインスタンスメソッドは生成されません。

```ruby
class A
  class_attribute :x, instance_reader: false
end

A.new.x = 1
A.new.x # NoMethodError
```

利便性のために、`class_attribute`は、インスタンスのreaderが返すものを「二重否定」するインスタンス述語も定義されます。上の例の場合、`x?`となります。

`:instance_reader`が`false`の場合、インスタンス述語はreaderメソッドと同様に`NoMethodError`を返します。

インスタンス述語が不要な場合、`instance_predicate: false`を指定すれば定義されなくなります。

NOTE: 定義は`active_support/core_ext/class/attribute.rb`にあります。

#### `cattr_reader`、`cattr_writer`、`cattr_accessor`

`cattr_reader`、`cattr_writer`、`cattr_accessor`マクロは、`attr_*`と似ていますが、クラス用である点が異なります。これらのメソッドは、クラス変数を`nil`に設定し (クラス変数が既にある場合を除く)、対応するクラスメソッドを生成してアクセスできるようにします。

```ruby
class MysqlAdapter < AbstractAdapter
  # @@emulate_booleansにアクセスできるクラスメソッドを生成する
  cattr_accessor :emulate_booleans
end
```

同様に、`cattr_*`にブロックを渡して属性にデフォルト値を設定することもできます。

```ruby
class MysqlAdapter < AbstractAdapter
  # @@emulate_booleansにアクセスしてデフォルト値をtrueにするクラスメソッドを生成する
  cattr_accessor :emulate_booleans, default: true
end
```

利便性のため、このときインスタンスメソッドも生成されますが、これらは実際にはクラス属性の単なるプロキシです。このため、インスタンスからクラス属性を変更することはできますが、`class_attribute`で行われるように上書きすることはできません(上記参照)。たとえば以下の場合、

```ruby
module ActionView
  class Base
    cattr_accessor :field_error_proc, default: Proc.new { ... }
  end
end
```

ビューで`field_error_proc`にアクセスできます。

`:instance_reader`オプションを`false`に設定することで、readerインスタンスメソッドが生成されないようにできます。同様に、`:instance_writer`オプションを`false`に設定することで、writerインスタンスメソッドが生成されないようにできます。`:instance_accessor`オプションを`false`に設定すれば、どちらのインスタンスメソッドも生成されません。いずれの場合も、指定できる値は`false`のみです。'nil'など他のfalse値は指定できません。

```ruby
module A
  class B
    # first_nameインスタンスreaderは生成されない
    cattr_accessor :first_name, instance_reader: false
    # last_name= インスタンスwriterは生成されない
    cattr_accessor :last_name, instance_writer: false
    # surnameインスタンスreaderもsurname= インスタンスwriterも生成されない
    cattr_accessor :surname, instance_accessor: false
  end
end
```

`:instance_accessor`を`false`に設定すると、モデルの属性設定時にマスアサインメントを防止するのに便利です。

NOTE: 定義は`active_support/core_ext/module/attribute_accessors.rb`にあります。

### サブクラスと子孫

#### `subclasses`

`subclasses`メソッドはレシーバのサブクラスを返します。

```ruby
class C; end
C.subclasses # => []

class B < C; end
C.subclasses # => [B]

class A < B; end
C.subclasses # => [B]

class D < C; end
C.subclasses # => [B, D]
```

返されるクラスの順序は一定ではありません。

NOTE: 定義は`active_support/core_ext/class/subclasses.rb`にあります。

#### `descendants`

`descendants`メソッドは、そのレシーバより下位にあるすべてのクラスを返します。

```ruby
class C; end
C.descendants # => []

class B < C; end
C.descendants # => [B]

class A < B; end
C.descendants # => [B, A]

class D < C; end
C.descendants # => [B, A, D]
```

返されるクラスの順序は一定ではありません。

NOTE: 定義は`active_support/core_ext/class/subclasses.rb`にあります。

`String`の拡張
----------------------

### 安全な出力

#### 開発の動機

HTMLテンプレートにデータを挿入する方法は、きわめて慎重に設計する必要があります。たとえば、`@review.title`を何の工夫もなくそのままHTMLに式展開するようなことは絶対にすべきではありません。もしこのレビューのタイトルが仮に「Flanagan & Matz rules!」だとしたら、出力はwell-formedになりません。well-formedにするには、"&amp;amp;"のようにエスケープしなければなりません。さらに、ユーザーがレビューのタイトルに細工をして、悪意のあるHTMLをタイトルに含めれば、巨大なセキュリティホールになることすらあります。このリスクの詳細については、[セキュリティガイド](security.html#クロスサイトスクリプティング-xss)のクロスサイトスクリプティングの節を参照してください。

#### 安全な文字列

Active Supportには「(html的に) 安全な文字列」という概念があります。安全な文字列とは、HTMLにそのまま挿入しても問題がないというマークが付けられている文字列です。マーキングさえされていれば、「実際にエスケープされているかどうかにかかわらず」その文字列は信頼されます。

文字列はデフォルトでは _unsafe_ とマークされます。

```ruby
"".html_safe? # => false
```

与えられた文字列に`html_safe`メソッドを適用することで、安全な文字列を得ることができます。

```ruby
s = "".html_safe
s.html_safe? # => true
```

ここで注意しなければならないのは、`html_safe`メソッドそれ自体は何らエスケープを行なっていないということです。安全であるとマーキングしているに過ぎません。

```ruby
s = "<script>...</script>".html_safe
s.html_safe? # => true
s            # => "<script>...</script>"
```

すなわち、特定の文字列に対して`html_safe`メソッドを呼び出す際には、その文字列が本当に安全であることを確認する義務があります。

安全であると宣言された文字列に対し、安全でない文字列を`concat`/`<<`や`+`で破壊的に追加すると、結果は安全な文字列になります。安全でない引数は追加時にエスケープされます。

```ruby
"".html_safe + "<" # => "&lt;"
```

安全な引数であれば、(エスケープなしで)直接追加されます。

```ruby
"".html_safe + "<".html_safe # => "<"
```

基本的にこれらのメソッドは、通常のビューでは使わないでください。現在のRailsのビューでは、安全でない値は自動的にエスケープされるためです。

```erb
<%= @review.title %> <%# 必要に応じてエスケープされるので問題なし %>
```

何らかの理由で、エスケープされていない文字列を挿入したい場合は、`html_safe`を呼ぶのではなく、`raw`ヘルパーをお使いください。

```erb
<%= raw @cms.current_template %> <%# @cms.current_templateをそのまま挿入 %>
```

あるいは、`raw`と同等の`<%==`を使います。

```erb
<%== @cms.current_template %> <%# @cms.current_templateをそのまま挿入 %>
```

`raw`ヘルパーは、内部で`html_safe`を呼び出します。

```ruby
def raw(stringish)
  stringish.to_s.html_safe
end
```

NOTE: 定義は`active_support/core_ext/string/output_safety.rb`にあります。

#### 各種変換

経験上、上で説明したような連結 (concatenation) 操作を除き、どんなメソッドでも潜在的には文字列を安全でないものに変換してしまう可能性があることに常に注意を払う必要があります。`downcase`、`gsub`、`strip`、`chomp`、`underscore`などの変換メソッドがこれに該当します。

`gsub!`のような破壊的な変換を行なうメソッドを使うと、レシーバ自体が安全でなくなってしまいます。

INFO: こうしたメソッドを実行すると、実際に変換が行われたかどうかにかかわらず、安全を表すビットは常にオフになります。

#### 変換と強制

安全な文字列に対して`to_s`を実行した場合は、安全な文字列が返されます。しかし、`to_str`による強制的な変換を実行した場合には安全でない文字列が返されます。

#### コピー

安全な文字列に対して`dup`または`clone`を実行した場合は、安全な文字列が生成されます。

### `remove`

`remove`メソッドを実行すると、すべての該当パターンが削除されます。

```ruby
"Hello World".remove(/Hello /) # => "World"
```

このメソッドには破壊的なバージョンの`String#remove!`もあります。

NOTE: 定義は`active_support/core_ext/string/filters.rb`にあります。

### `squish`

`squish`メソッドは、冒頭と末尾のホワイトスペースを除去し、連続したホワイトスペースを1つに減らします。

```ruby
" \n  foo\n\r \t bar \n".squish # => "foo bar"
```

このメソッドには破壊的なバージョンの`String#squish!`もあります。

このメソッドでは、ASCIIとUnicodeのホワイトスペースを扱えます。

NOTE: 定義は`active_support/core_ext/string/filters.rb`にあります。

### `truncate`

`truncate`メソッドは、指定された`length`にまで長さを切り詰めたレシーバのコピーを返します。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20)
# => "Oh dear! Oh dear!..."
```

`:omission`オプションを指定することで、省略文字 (...) をカスタマイズすることもできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20, omission: '&hellip;')
# => "Oh dear! Oh &hellip;"
```

文字列の切り詰めでは、省略文字列の長さも加味されることに特にご注意ください。

`:separator`を指定することで、自然な区切り位置で切り詰めることができます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18)
# => "Oh dear! Oh dea..."
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: ' ')
# => "Oh dear! Oh..."
```

`:separator`オプションでは正規表現も使えます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: /\s/)
# => "Oh dear! Oh..."
```

上の例では、"dear"という文字で切り落とされそうになるところを、`:separator`によって防いでいます。

NOTE: 定義は`active_support/core_ext/string/filters.rb`にあります。

### `truncate_words`

`truncate_words`メソッドは、指定されたワード数から後ろを切り落としたレシーバのコピーを返します。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4)
# => "Oh dear! Oh dear!..."
```

`:omission`オプションを指定することで、省略文字 (...) をカスタマイズすることもできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, omission: '&hellip;')
# => "Oh dear! Oh dear!&hellip;"
```

`:separator`を指定することで、自然な区切り位置で切り詰めることができます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(3, separator: '!')
# => "Oh dear! Oh dear! I shall be late..."
```

`:separator`オプションでは正規表現も使えます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, separator: /\s/)
# => "Oh dear! Oh dear!..."
```

NOTE: 定義は`active_support/core_ext/string/filters.rb`にあります。

### `inquiry`

`inquiry`は、文字列を`StringInquirer`オブジェクトに変換します。このオブジェクトを使うと、等しいかどうかをよりスマートにチェックできます。

```ruby
"production".inquiry.production? # => true
"active".inquiry.inactive?       # => false
```

NOTE: 定義は`active_support/core_ext/string/inquiry.rb`にあります。****

### `starts_with?`と`ends_with?`

Active Supportでは、`String#start_with?`と`String#end_with?`を英語的に自然な三人称(starts、ends)にした別名も定義されています。

```ruby
"foo".starts_with?("f") # => true
"foo".ends_with?("o")   # => true
```

NOTE: 定義は`active_support/core_ext/string/starts_ends_with.rb`にあります。

### `strip_heredoc`

`strip_heredoc`メソッドは、ヒアドキュメントのインデントを除去します。

以下に例を示します。

```ruby
if options[:usage]
  puts <<-USAGE.strip_heredoc
    This command does such and such.

    Supported options are:
      -h         This message
      ...
  USAGE
end
```

このUSAGEメッセージは左寄せで表示されます。

技術的には、インデントが一番浅い行を探して、そのインデント分だけ行頭のホワイトスペースを全体から削除するという操作を行っています。

NOTE: 定義は`active_support/core_ext/string/strip.rb`にあります。

### `indent`

このメソッドは、レシーバの行にインデントを与えます。

```ruby
<<EOS.indent(2)
def some_method
  some_code
end
EOS
# =>
  def some_method
    some_code
  end
```

2つめの引数`indent_string`は、インデントに使う文字列を指定します。デフォルトは`nil`であり、この場合最初にインデントされている行のインデント文字を参照してそこからインデント文字を推測します。インデントがまったくない場合はスペース1つを使います。

```ruby
"  foo".indent(2)        # => "    foo"
"foo\n\t\tbar".indent(2) # => "\t\tfoo\n\t\t\t\tbar"
"foo".indent(2, "\t")    # => "\t\tfoo"
```

`indent_string`には1文字のスペースまたはタブを使うのが普通ですが、どんな文字でも使えます。

3つ目の引数`indent_empty_lines`は、空行もインデントするかどうかを指定するフラグです。デフォルトは`false`です。

```ruby
"foo\n\nbar".indent(2)            # => "  foo\n\n  bar"
"foo\n\nbar".indent(2, nil, true) # => "  foo\n  \n  bar"
```

`indent!`メソッドはインデントをその場で (破壊的に) 行います。

NOTE: 定義は`active_support/core_ext/string/indent.rb`にあります。

### Access

#### `at(position)`

対象となる文字列のうち、`position`で指定された位置にある文字を返します。

```ruby
"hello".at(0)  # => "h"
"hello".at(4)  # => "o"
"hello".at(-1) # => "o"
"hello".at(10) # => nil
```

NOTE: 定義は`active_support/core_ext/string/access.rb`にあります。

#### `from(position)`

文字列のうち、`position`で指定された位置から始まる部分文字列を返します。

```ruby
"hello".from(0)  # => "hello"
"hello".from(2)  # => "llo"
"hello".from(-2) # => "lo"
"hello".from(10) # => nil
```

NOTE: 定義は`active_support/core_ext/string/access.rb`にあります。

#### `to(position)`

文字列のうち、`position`で指定された位置を終端とする部分文字列を返します。

```ruby
"hello".to(0)  # => "h"
"hello".to(2)  # => "hel"
"hello".to(-2) # => "hell"
"hello".to(10) # => "hello"
```

NOTE: 定義は`active_support/core_ext/string/access.rb`にあります。

#### `first(limit = 1)`

`str.first(n)`という呼び出しは、`n` > 0の場合は`str.to(n-1)`と等価です。`n` == 0の場合は空文字列を返します。

NOTE: 定義は`active_support/core_ext/string/access.rb`にあります。

#### `last(limit = 1)`

`str.last(n)` という呼び出しは、`n` > 0の場合は`str.from(-n)`と等価です。`n` == 0の場合は空文字列を返します。

NOTE: 定義は`active_support/core_ext/string/access.rb`にあります。

### 活用形

#### `pluralize`

`pluralize`メソッドは、レシーバを「複数形」にしたものを返します。

```ruby
"table".pluralize     # => "tables"
"ruby".pluralize      # => "rubies"
"equipment".pluralize # => "equipment"
```

上の例でも示したように、Active Supportは不規則な複数形や非可算名詞をある程度扱えます。`config/initializers/inflections.rb`にあるビルトインのルールは拡張可能です。このファイルは`rails new`コマンド実行時にデフォルトで生成され、ファイルのコメントに説明が示されています。

`pluralize`メソッドではオプションで`count`パラメータを使えます。もし`count == 1`を指定すると単数形が返されます。`count`がそれ以外の値の場合は複数形を返します(訳注: 英語では個数がゼロや小数の場合は複数形で表されます)。

```ruby
"dude".pluralize(0) # => "dudes"
"dude".pluralize(1) # => "dude"
"dude".pluralize(2) # => "dudes"
```

Active Recordでは、モデル名に対応するデフォルトのテーブル名を求めるときにこのメソッドを使います。

```ruby
# active_record/model_schema.rb
def undecorated_table_name(class_name = base_class.name)
  table_name = class_name.to_s.demodulize.underscore
  pluralize_table_names ? table_name.pluralize : table_name
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `singularize`

`pluralize`と逆の動作です。

```ruby
"tables".singularize    # => "table"
"rubies".singularize    # => "ruby"
"equipment".singularize # => "equipment"
```

Railsの関連付け (association) では、関連付けられたクラスにデフォルトで対応する名前を求める時にこのメソッドを使います。

```ruby
# active_record/reflection.rb
def derive_class_name
  class_name = name.to_s.camelize
  class_name = class_name.singularize if collection?
  class_name
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `camelize`

`camelize`メソッドは、レシーバをキャメルケース (冒頭を大文字にした単語をスペースなしで連結した語) にしたものを返します。

```ruby
"product".camelize    # => "Product"
"admin_user".camelize # => "AdminUser"
```

このメソッドは、パスをRubyのクラスに変換するときにもよく使われます。スラッシュで区切られているパスは「::」で区切られます。

```ruby
"backoffice/session".camelize # => "Backoffice::Session"
```

たとえばAction Packでは、特定のセッションストアを提供するクラスを読み込むのにこのメソッドを使います。

```ruby
# action_controller/metal/session_management.rb
def session_store=(store)
  @@session_store = store.is_a?(Symbol) ?
    ActionDispatch::Session.const_get(store.to_s.camelize) :
    store
end
```

`camelize`メソッドはオプションの引数を受け付けます。`:upper`（デフォルト）または`:lower`を指定できます。後者を指定すると、冒頭が小文字になります。

```ruby
"visual_effect".camelize(:lower) # => "visualEffect"
```

このメソッドは、そのような命名慣習に沿う言語（JavaScriptなど）で使う名前を求めるのに便利です。

INFO: `camerize`メソッドの動作は、`underscore`メソッドと逆の動作と考えるとわかりやすいでしょう。ただし完全に逆の動作ではありません。たとえば、`"SSLError".underscore.camelize`を実行した結果は`"SslError"`になり、元に戻りません。このような場合をサポートするために、Active Supportでは`config/initializers/inflections.rb`の頭字語（acronym）を次のように指定できます。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'SSL'
end

"SSLError".underscore.camelize # => "SSLError"
```

`camelize`は`camelcase`の別名です。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `underscore`

`underscore`メソッドは上と逆に、キャメルケースをパスに変換します。

```ruby
"Product".underscore   # => "product"
"AdminUser".underscore # => "admin_user"
```

"::"も"/"に逆変換されます。

```ruby
"Backoffice::Session".underscore # => "backoffice/session"
```

小文字で始まる文字列も扱えます。

```ruby
"visualEffect".underscore # => "visual_effect"
```

ただし`underscore`は引数を取りません。

Railsで自動的に読み込まれるクラスとモジュールは、ファイルの拡張子を`underscore`メソッドで除いた相対パスを推測し、指定された定数が失われている場合にそれを定義するのにこのメソッドを利用します。

```ruby
# active_support/dependencies.rb
def load_missing_constant(from_mod, const_name)
  ...
  qualified_name = qualified_name_for from_mod, const_name
  path_suffix = qualified_name.underscore
  ...
end
```

INFO: `underscore`メソッドの動作は、`camelize`メソッドと逆の動作と考えるとわかりやすいでしょう。ただし完全に逆の動作ではありません。たとえば、`"SSLError".underscore.camelize`を実行した結果は`"SslError"`になり、元に戻りません。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `titleize`

`titleize`メソッドは、レシーバの語の1文字目を大文字にします。

```ruby
"alice in wonderland".titleize # => "Alice In Wonderland"
"fermat's enigma".titleize     # => "Fermat's Enigma"
```

`titleize`メソッドは`titlecase`の別名です。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `dasherize`

`dasherize`メソッドは、レシーバのアンダースコア文字をダッシュに置き換えます(訳注: ここで言うダッシュは実際には「ハイフンマイナス文字」(U+002D)です)。

```ruby
"name".dasherize         # => "name"
"contact_data".dasherize # => "contact-data"
```

モデルのXMLシリアライザではノード名をこのメソッドでダッシュ化しています。

```ruby
# active_model/serializers/xml.rb
def reformat_name(name)
  name = name.camelize if camelize?
  dasherize? ? name.dasherize : name
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `demodulize`

`demodulize`メソッドは、フルパスの (qualified) 定数名を与えられると、パス部分を取り除いて右側の定数名だけにしたものを返します。

```ruby
"Product".demodulize                        # => "Product"
"Backoffice::UsersController".demodulize    # => "UsersController"
"Admin::Hotel::ReservationUtils".demodulize # => "ReservationUtils"
"::Inflections".demodulize                  # => "Inflections"
"".demodulize                               # => ""

```

以下のActive Recordの例では、`counter_cache_column `の名前をこのメソッドで求めています。

```ruby
# active_record/reflection.rb
def counter_cache_column
  if options[:counter_cache] == true
    "#{active_record.name.demodulize.underscore.pluralize}_count"
  elsif options[:counter_cache]
    options[:counter_cache]
  end
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `deconstantize`

`deconstantize`メソッドは、フルパスの定数を表す参照表現を与えられると、一番右の部分 (通常は定数名) を取り除きます。

```ruby
"Product".deconstantize                        # => ""
"Backoffice::UsersController".deconstantize    # => "Backoffice"
"Admin::Hotel::ReservationUtils".deconstantize # => "Admin::Hotel"
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `parameterize`

`parameterize`メソッドは、レシーバを正しいURLで利用可能な形式に正規化します。

```ruby
"John Smith".parameterize # => "john-smith"
"Kurt Gödel".parameterize # => "kurt-godel"
```

文字列の大文字小文字が変わらないようにするには、`preserve_case`引数に`true`を指定します。`preserve_case`はデフォルトでは`false`です。

```ruby
"John Smith".parameterize(preserve_case: true) # => "John-Smith"
"Kurt Gödel".parameterize(preserve_case: true) # => "Kurt-Godel"
```

独自のセパレータを使うには、`separator`引数をオーバーライドします。

```ruby
"John Smith".parameterize(separator: "_") # => "john\_smith"
"Kurt Gödel".parameterize(separator: "_") # => "kurt\_godel"
```

実際に得られる文字列は、`ActiveSupport::Multibyte::Chars`のインスタンスでラップされています。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `tableize`

`tableize`メソッドは、`underscore`の次に`pluralize`を実行したものです。

```ruby
"Person".tableize      # => "people"
"Invoice".tableize     # => "invoices"
"InvoiceLine".tableize # => "invoice_lines"
```

単純な場合であれば、モデル名に`tableize`を使うとモデルのテーブル名を得られます。実際のActive Recordの実装は、単に`tableize`を実行する場合よりも複雑です。Active Recordではクラス名に対して`demodulize`も行っており、返される文字列に影響する可能性のあるオプションもいくつかチェックしています。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `classify`

`classify`メソッドは`tableize`と逆の動作で、与えられたテーブル名に対応するクラス名を返します。

```ruby
"people".classify        # => "Person"
"invoices".classify      # => "Invoice"
"invoice_lines".classify # => "InvoiceLine"
```

このメソッドは、フルパスの (qualified) テーブル名も扱えます。

```ruby
"highrise_production.companies".classify # => "Company"
```

`classify`が返すクラス名は文字列であることにご注意ください。得られた文字列に対して`constantize` (後述) を実行することで本当のクラスオブジェクトを得られます。

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `constantize`

`constantize`メソッドは、レシーバの定数参照表現を解決し、実際のオブジェクトを返します。

```ruby
"Fixnum".constantize # => Fixnum

module M
  X = 1
end
"M::X".constantize # => 1
```

与えられた文字列を`constantize`メソッドで評価しても既知の定数とマッチしない、または指定された定数名が正しくない場合は`NameError`が発生します。

`constantize`メソッドによる定数名解決は、常にトップレベルの`Object`から開始されます。これは冒頭に「::」がない場合でも同じです。

```ruby
X = :in_Object
module M
  X = :in_M

  X                 # => :in_M
  "::X".constantize # => :in_Object
  "X".constantize   # => :in_Object (!)
end
```

このため、このメソッドは、同じ場所でRubyが定数を評価したときの値と必ずしも等価ではありません。

メイラー (mailer) のテストケースでは、テストするクラスの名前からテスト対象のメイラーを取得するのに`constantize`メソッドを使います。

```ruby
# action_mailer/test_case.rb
def determine_default_mailer(name)
  name.sub(/Test$/, '').constantize
rescue NameError => e
  raise NonInferrableMailerError.new(name)
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `humanize`

`humanize`メソッドは、属性名を (英語的に) 読みやすい表記に変換します。

具体的には以下の変換を行います。

  * 引数に (英語の) 活用ルールを適用します(inflection)。
  * 冒頭にアンダースコアがある場合は削除します。
  * 末尾に「_id」がある場合は削除します。
  * アンダースコアが他にもある場合はスペースに置き換えます。
  * 略語を除いてすべての単語を小文字にします(downcase)。
  * 最初の単語だけ冒頭の文字を大文字にします(capitalize)。

`:capitalize`オプションをfalseにすると、冒頭の文字は大文字にされません(デフォルトは`true`)。

```ruby
"name".humanize                         # => "Name"
"author_id".humanize                    # => "Author"
"author_id".humanize(capitalize: false) # => "author"
"comments_count".humanize               # => "Comments count"
"_id".humanize                          # => "Id"
```

"SSL"が頭字語と定義されている場合は以下のようになります。

```ruby
'ssl_error'.humanize # => "SSL error"
```

ヘルパーメソッド`full_messages`では、属性名をメッセージに含めるときに`humanize`を使います。


```ruby
def full_messages
  map { |attribute, message| full_message(attribute, message) }
end

def full_message
  ...
  attr_name = attribute.to_s.tr('.', '_').humanize
  attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
  ...
end
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

#### `foreign_key`

`foreign_key`メソッドは、クラス名から外部キーカラム名を求めるのに用いられます。具体的には、`demodulize`、`underscore`を実行し、末尾に「_id」を追加します。

```ruby
"User".foreign_key           # => "user_id"
"InvoiceLine".foreign_key    # => "invoice_line_id"
"Admin::Session".foreign_key # => "session_id"
```

末尾の「_id」のアンダースコアが不要な場合は、引数に`false`を指定します。

```ruby
"User".foreign_key(false) # => "userid"
```

関連付け (association) では、外部キーの名前を推測するときにこのメソッドを使います。たとえば`has_one`と`has_many`では以下を行っています。

```ruby
# active_record/associations.rb
foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

### 各種変換

#### `to_date`、`to_time`、`to_datetime`

`to_date`、`to_time`、`to_datetime`メソッドは、`Date._parse`をラップして使いやすくします。

```ruby
"2010-07-27".to_date              # => Tue, 27 Jul 2010
"2010-07-27 23:37:00".to_time     # => 2010-07-27 23:37:00 +0200
"2010-07-27 23:37:00".to_datetime # => Tue, 27 Jul 2010 23:37:00 +0000
```

`to_time`はオプションで`:utc`や`:local`を引数に取り、タイムゾーンを指定できます。

```ruby
"2010-07-27 23:42:00".to_time(:utc)   # => 2010-07-27 23:42:00 UTC
"2010-07-27 23:42:00".to_time(:local) # => 2010-07-27 23:42:00 +0200
```

デフォルトは`:local`です。

詳しくは`Date._parse`のドキュメントを参照してください。

INFO: 3つのメソッドはいずれも、レシーバが空の場合は`nil`を返します。

NOTE: 定義は`active_support/core_ext/string/conversions.rb`にあります。

`Numeric`の拡張
-----------------------

### バイト

すべての数値は、以下のメソッドに応答します。

```ruby
bytes
kilobytes
megabytes
gigabytes
terabytes
petabytes
exabytes
```

これらのメソッドは、対応するバイト数を返すときに1024の倍数を使います。

```ruby
2.kilobytes   # => 2048
3.megabytes   # => 3145728
3.5.gigabytes # => 3758096384
-4.exabytes   # => -4611686018427387904
```

これらのメソッドには単数形の別名もあります。

```ruby
1.megabyte # => 1048576
```

NOTE: 定義は`active_support/core_ext/numeric/bytes.rb`にあります。

### Time

たとえば`45.minutes + 2.hours + 4.weeks`のように時間の計算や宣言を行なえます。

これらのメソッドでは正確な日付計算のために`Time#advance`を利用しています。`Time#advance`は、`from_now`や`ago`などの他に、`Time`オブジェクトから得た結果の加減算でも使われています。以下に例を示します。

```ruby
# Time.current.advance(months: 1) と等価
1.month.from_now

# Time.current.advance(weeks: 2) と等価
2.weeks.from_now

# Time.current.advance(months: 4, weeks: 5) と等価
(4.months + 5.weeks).from_now
```

WARNING: 上記以外の期間については、`Integer`の`Time`拡張を参照してください。

NOTE: 定義は`active_support/core_ext/numeric/time.rb`にあります。

### 書式設定

数値はさまざまな方法でフォーマットできます。

以下のように、数値を電話番号形式の文字列に変換できます。

```ruby
5551234.to_s(:phone)
# => 555-1234
1235551234.to_s(:phone)
# => 123-555-1234
1235551234.to_s(:phone, area_code: true)
# => (123) 555-1234
1235551234.to_s(:phone, delimiter: " ")
# => 123 555 1234
1235551234.to_s(:phone, area_code: true, extension: 555)
# => (123) 555-1234 x 555
1235551234.to_s(:phone, country_code: 1)
# => +1-123-555-1234
```

以下のように、数値を通貨形式の文字列に変換できます。

```ruby
1234567890.50.to_s(:currency)                 # => $1,234,567,890.50
1234567890.506.to_s(:currency)                # => $1,234,567,890.51
1234567890.506.to_s(:currency, precision: 3)  # => $1,234,567,890.506
```

以下のように、数値を百分率形式の文字列に変換できます。

```ruby
100.to_s(:percentage)
# => 100.000%
100.to_s(:percentage, precision: 0)
# => 100%
1000.to_s(:percentage, delimiter: '.', separator: ',')
# => 1.000,000%
302.24398923423.to_s(:percentage, precision: 5)
# => 302.24399%
```

以下のように、数値の桁区切りを追加して文字列形式にできます。

```ruby
12345678.to_s(:delimited)                     # => 12,345,678
12345678.05.to_s(:delimited)                  # => 12,345,678.05
12345678.to_s(:delimited, delimiter: ".")     # => 12.345.678
12345678.to_s(:delimited, delimiter: ",")     # => 12,345,678
12345678.05.to_s(:delimited, separator: " ")  # => 12,345,678 05
```

以下のように、数字を特定の精度に丸めて文字列形式にできます。

```ruby
111.2345.to_s(:rounded)                     # => 111.235
111.2345.to_s(:rounded, precision: 2)       # => 111.23
13.to_s(:rounded, precision: 5)             # => 13.00000
389.32314.to_s(:rounded, precision: 0)      # => 389
111.2345.to_s(:rounded, significant: true)  # => 111
```

以下のように、数値を人間にとって読みやすいバイト数形式の文字列に変換できます。

```ruby
123.to_s(:human_size)                  # => 123 Bytes
1234.to_s(:human_size)                 # => 1.21 KB
12345.to_s(:human_size)                # => 12.1 KB
1234567.to_s(:human_size)              # => 1.18 MB
1234567890.to_s(:human_size)           # => 1.15 GB
1234567890123.to_s(:human_size)        # => 1.12 TB
1234567890123456.to_s(:human_size)     # => 1.1 PB
1234567890123456789.to_s(:human_size)  # => 1.07 EB
```

以下のように、数値を人間にとって読みやすいバイト数形式で単位が単語の文字列に変換できます。

```ruby
123.to_s(:human)               # => "123"
1234.to_s(:human)              # => "1.23 Thousand"
12345.to_s(:human)             # => "12.3 Thousand"
1234567.to_s(:human)           # => "1.23 Million"
1234567890.to_s(:human)        # => "1.23 Billion"
1234567890123.to_s(:human)     # => "1.23 Trillion"
1234567890123456.to_s(:human)  # => "1.23 Quadrillion"
```

NOTE: 定義は`active_support/core_ext/numeric/conversions.rb`にあります。

`Integer`の拡張
-----------------------

### `multiple_of?`

`multiple_of?`メソッドは、レシーバの整数が引数の倍数であるかどうかをテストします。

```ruby
2.multiple_of?(1) # => true
1.multiple_of?(2) # => false
```

NOTE: 定義は`active_support/core_ext/integer/multiple.rb`にあります。

### `ordinal`

`ordinal`メソッドは、レシーバの整数に対応する序数のサフィックス文字列を返します。

```ruby
1.ordinal    # => "st"
2.ordinal    # => "nd"
53.ordinal   # => "rd"
2009.ordinal # => "th"
-21.ordinal  # => "st"
-134.ordinal # => "th"
```

NOTE: 定義は`active_support/core_ext/integer/inflections.rb`にあります。

### `ordinalize`

`ordinalize`メソッドは、レシーバの整数に、対応する序数文字列を追加したものをかえします。先に紹介した`ordinal`メソッドは、序数文字列**だけ**を返す点が異なることにご注意ください。

```ruby
1.ordinalize    # => "1st"
2.ordinalize    # => "2nd"
53.ordinalize   # => "53rd"
2009.ordinalize # => "2009th"
-21.ordinalize  # => "-21st"
-134.ordinalize # => "-134th"
```

NOTE: 定義は`active_support/core_ext/integer/inflections.rb`にあります。

### Time

`4.months + 5.years`のような形式での時間の計算や宣言を行えるようにします。

これらのメソッドでは正確な日付計算のために`Time#advance`を利用しています。`Time#advance`は、`from_now`や`ago`などの他に、`Time`オブジェクトから得た結果の加減算でも使われています。以下に例を示します。

```ruby
# Time.current.advance(months: 1)と同等
1.month.from_now

# Time.current.advance(years: 2)と同等
2.years.from_now

# Time.current.advance(months: 4, years: 5)と同等
(4.months + 5.years).from_now
```

WARNING: 上記以外の期間については、`Numeric`の`Time`拡張を参照してください。

NOTE: 定義は `active_support/core_ext/integer/time.rb`にあります。

`BigDecimal`の拡張
--------------------------
### `to_s`

`to_s`メソッドは「F」のデフォルトの記法を提供します。これは、`to_s`を単に呼び出すと、エンジニアリング記法ではなく浮動小数点を得られるということです。

```ruby
BigDecimal(5.00, 6).to_s       # => "5.0"
```

また、シンボルによる指定もサポートされます。

```ruby
BigDecimal(5.00, 6).to_s(:db)  # => "5.0"
```

エンジニアリング記法も従来通りサポートされます。

```ruby
BigDecimal(5.00, 6).to_s("e")  # => "0.5E1"
```

`Enumerable`の拡張
--------------------------

### `sum`

`sum`メソッドはenumerableの要素を合計します。

```ruby
[1, 2, 3].sum # => 6
(1..100).sum  # => 5050
```

`+`に応答する要素のみが加算の対象として前提とされます。

```ruby
[[1, 2], [2, 3], [3, 4]].sum    # => [1, 2, 2, 3, 3, 4]
%w(foo bar baz).sum             # => "foobarbaz"
{a: 1, b: 2, c: 3}.sum          # => [:a, 1, :b, 2, :c, 3]
```

空のコレクションはデフォルトではゼロを返しますが、この動作はカスタマイズ可能です。

```ruby
[].sum    # => 0
[].sum(1) # => 1
```

ブロックが与えられると、`sum`はイテレータになってコレクションの要素を`yield`し、そこから返された値を合計します。

```ruby
(1..5).sum {|n| n * 2 } # => 30
[2, 4, 6, 8, 10].sum    # => 30
```

ブロックを与える場合にも、レシーバが空のときのデフォルト値をカスタマイズできます。

```ruby
[].sum(1) {|n| n**3} # => 1
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `index_by`

`index_by`メソッドは、何らかのキーによってインデックス化されたenumerableの要素を持つハッシュを生成します。

このメソッドはコレクションを列挙し、各要素をブロックに渡します。この要素は、ブロックから返された値によってインデックス化されます。

```ruby
invoices.index_by(&:number)
# => {'2009-032' => <Invoice ...>, '2009-008' => <Invoice ...>, ...}
```

WARNING: キーは通常は一意でなければなりません。異なる要素から同じ値が返されると、そのキーのコレクションは作成されません。返された項目のうち、最後の項目だけが使われます。

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `index_with`

`index_with`メソッドは、enumerableの要素をキーとして持つハッシュを生成します。値は渡されたデフォルト値か、ブロックで返されます。

```ruby
%i( title body created_at ).index_with { |attr_name| post.public_send(attr_name) }
# => { title: "hey", body: "what's up?", … }

WEEKDAYS.index_with(Interval.all_day)
# => { monday: [ 0, 1440 ], … }
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `many?`

`many?`メソッドは、`collection.size > 1`の短縮形です。

```erb
<% if pages.many? %>
  <%= pagination_links %>
<% end %>
```

`many?`は、ブロックがオプションとして与えられると、`true`を返す要素だけを扱います。

```ruby
@see_more = videos.many? {|video| video.category == params[:category]}
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `exclude?`

`exclude?`述語メソッドは、与えられたオブジェクトがそのコレクションに属して**いない**かどうかをテストします。`include?`の逆の動作です。

```ruby
to_visit << node if visited.exclude?(node)
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `without`

`without`メソッドは、指定した要素を除外したenumerableのコピーを返します。


```ruby
["David", "Rafael", "Aaron", "Todd"].without("Aaron", "Todd") # => ["David", "Rafael"]
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

### `pluck`

`pluck`メソッドは、指定されたキーに基づく配列を返します。

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pluck(:name) # => ["David", "Rafael", "Aaron"]
```

NOTE: 定義は`active_support/core_ext/enumerable.rb`にあります。

`Array`の拡張
---------------------

### 配列へのアクセス

Active Supportには配列のAPIが多数追加されており、配列に容易にアクセスできるようになっています。たとえば`to`メソッドは、配列の冒頭から、渡されたインデックスが示す箇所までの範囲を返します。

```ruby
%w(a b c d).to(2) # => ["a", "b", "c"]
[].to(7)          # => []
```

同様に`from`メソッドは、配列のうち、インデックスが指す箇所から末尾までの要素を返します。インデックスが配列のサイズより大きい場合は、空の配列を返します。

```ruby
%w(a b c d).from(2)  # => ["c", "d"]
%w(a b c d).from(10) # => []
[].from(0)           # => []
```

`second`、`third`、`fourth`、`fifth`は、`second_to_last`や`third_to_last`と同様に、対応する位置の要素を返します (`first`と`last`は元からビルトインされています)。社会の智慧と建設的な姿勢のおかげで、今では`forty_two`も使えます (訳注: [Rails 2.2 以降](https://github.com/rails/rails/commit/9d8cc60ec3845fa3e6f9292a65b119fe4f619f7e)で使えます。「42」については、Wikipediaの[生命、宇宙、そして万物についての究極の疑問の答え](http://ja.wikipedia.org/wiki/%E7%94%9F%E5%91%BD%E3%80%81%E5%AE%87%E5%AE%99%E3%80%81%E3%81%9D%E3%81%97%E3%81%A6%E4%B8%87%E7%89%A9%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E3%81%AE%E7%A9%B6%E6%A5%B5%E3%81%AE%E7%96%91%E5%95%8F%E3%81%AE%E7%AD%94%E3%81%88)を参照してください)。

```ruby
%w(a b c d).third # => "c"
%w(a b c d).fifth # => nil
```

NOTE: 定義は`active_support/core_ext/array/access.rb`にあります。

### 展開

`extract!`メソッドは、ブロックの返す値がtrueになる要素を削除して返します。ブロックが渡されない場合はEnumeratorを返します。

```ruby
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
odd_numbers = numbers.extract! { |number| number.odd? } # => [1, 3, 5, 7, 9]
numbers # => [0, 2, 4, 6, 8]
```

NOTE: 定義は`active_support/core_ext/array/extract.rb`にあります。

### オプションの展開

Rubyでは、メソッドに与えられた最後の引数がハッシュの場合、ハッシュの波かっこ`{}`を省略できます（引数が`&block`引数である場合を除く）。

```ruby
User.exists?(email: params[:email])
```

このようなシンタックスシュガーは、多数の引数が順序に依存することを避け、名前付きパラメータをエミュレートするインターフェイスを提供するためにRailsで多用されています。特に、末尾にオプションのハッシュを置くというのは定番中の定番です。

しかし、あるメソッドが受け取る引数の数が固定されておらず、メソッド宣言で`*`が使われていると、そのような波かっこなしのオプションハッシュは引数の配列の末尾の要素になってしまい、ハッシュとして認識されなくなってしまいます。

このような場合、`extract_options!`メソッドは、配列の最後の項目の型をチェックします。それがハッシュの場合、そのハッシュを取り出して返し、それ以外の場合は空のハッシュを返します。

`caches_action`コントローラマクロでの定義を例にとって見てみましょう。

```ruby
def caches_action(*actions)
  return unless cache_configured?
  options = actions.extract_options!
  ...
end
```

このメソッドは、任意の数のアクション名を引数に取ることができ、引数の末尾項目でオプションハッシュを使えます。`extract_options!`メソッドを使うと、このオプションハッシュの取得と`actions`からの除去を簡単かつ明示的に行えます。

NOTE: 定義は`active_support/core_ext/array/extract_options.rb`にあります。

### 各種変換

#### `to_sentence`

`to_sentence`メソッドは、配列を変換して、要素を列挙する英文にします。

```ruby
%w().to_sentence                # => ""
%w(Earth).to_sentence           # => "Earth"
%w(Earth Wind).to_sentence      # => "Earth and Wind"
%w(Earth Wind Fire).to_sentence # => "Earth, Wind, and Fire"
```

このメソッドは3つのオプションを受け付けます。

* `:two_words_connector`: 項目数が2つの場合の接続詞を指定します。デフォルトはスペースを含む「 and 」です。
* `:words_connector`: 3つ以上の要素を接続する場合、最後の2つの間以外で使われる接続詞を指定します。デフォルトはスペースを含む「, 」です。
* `:last_word_connector`: 3つ以上の要素を接続する場合、最後の2つの要素で使われる接続詞を指定します。デフォルトはスペースを含む「, and 」です。

これらのオプションは標準の方法でローカライズできます。使えるキーは以下のとおりです。

| オプション                 | I18n キー                            |
| ---------------------- | ----------------------------------- |
| `:two_words_connector` | `support.array.two_words_connector` |
| `:words_connector`     | `support.array.words_connector`     |
| `:last_word_connector` | `support.array.last_word_connector` |

NOTE: 定義は`active_support/core_ext/array/conversions.rb`にあります。

#### `to_formatted_s`

`to_formatted_s`メソッドは、デフォルトでは`to_s`と同様に振る舞います。

ただし、配列の中に`id`に応答する項目がある場合は、`:db`というシンボルを引数として渡すことで対応できる点が異なります。この手法は、Active Recordオブジェクトのコレクションに対してよく使われます。返される文字列は以下のとおりです。

```ruby
[].to_formatted_s(:db)            # => "null"
[user].to_formatted_s(:db)        # => "8456"
invoice.lines.to_formatted_s(:db) # => "23,567,556,12"
```

上の例の整数は、`id`への呼び出しによって取り出されたものとみなされます。

NOTE: 定義は`active_support/core_ext/array/conversions.rb`にあります。

#### `to_xml`

`to_xml`メソッドは、レシーバをXML表現に変換したものを含む文字列を返します。

```ruby
Contributor.limit(2).order(:rank).to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors type="array">
#   <contributor>
#     <id type="integer">4356</id>
#     <name>Jeremy Kemper</name>
#     <rank type="integer">1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id type="integer">4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank type="integer">2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

実際には、`to_xml`をすべての要素に送り、結果をルートノードの下に集めます。すべての要素が`to_xml`に応答する必要があります。そうでない場合は例外が発生します。

デフォルトでは、ルート要素の名前は最初の要素のクラス名を複数形にしてアンダースコア化（underscored）とダッシュ化（dasherize）を行います。残りの要素も最初の要素と同じ型 (`is_a?`でチェックされます) に属し、ハッシュでないことが前提となっています。上の例で言うと「contributors」です。

最初の要素と同じ型に属さない要素が1つでもある場合、ルートノードには`objects`が使われます。

```ruby
[Contributor.first, Commit.first].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <id type="integer">4583</id>
#     <name>Aaron Batalion</name>
#     <rank type="integer">53</rank>
#     <url-id>aaron-batalion</url-id>
#   </object>
#   <object>
#     <author>Joshua Peek</author>
#     <authored-timestamp type="datetime">2009-09-02T16:44:36Z</authored-timestamp>
#     <branch>origin/master</branch>
#     <committed-timestamp type="datetime">2009-09-02T16:44:36Z</committed-timestamp>
#     <committer>Joshua Peek</committer>
#     <git-show nil="true"></git-show>
#     <id type="integer">190316</id>
#     <imported-from-svn type="boolean">false</imported-from-svn>
#     <message>Kill AMo observing wrap_with_notifications since ARes was only using it</message>
#     <sha1>723a47bfb3708f968821bc969a9a3fc873a3ed58</sha1>
#   </object>
# </objects>
```

レシーバがハッシュの配列である場合、ルート要素はデフォルトで`objects`になります。

```ruby
[{a: 1, b: 2}, {c: 3}].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <b type="integer">2</b>
#     <a type="integer">1</a>
#   </object>
#   <object>
#     <c type="integer">3</c>
#   </object>
# </objects>
```

WARNING: コレクションが空の場合、ルート要素はデフォルトで「nilクラス」になります。ここからわかるように、たとえば上の例でのcontributorsのリストのルート要素は、コレクションがもし空であれば「contributors」ではなく「nilクラス」になってしまうということです。`:root`オプションを使って、ルート要素を統一することもできます。

子ノードの名前は、デフォルトではルートノードを単数形にしたものが使われます。上の例で言うと「contributor」や「object」です。`:children`オプションを使うと、これらをノード名として設定できます。

デフォルトのXMLビルダは、`Builder::XmlMarkup`から直接生成されたインスタンスです。`:builder`オブションを使って独自のビルダを構成できます。このメソッドでは`:dasherize`やその同族と同様のオプションが利用でき、指定したオプションはビルダに転送されます。

```ruby
Contributor.limit(2).order(:rank).to_xml(skip_types: true)
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors>
#   <contributor>
#     <id>4356</id>
#     <name>Jeremy Kemper</name>
#     <rank>1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id>4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank>2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

NOTE: 定義は`active_support/core_ext/array/conversions.rb`にあります。

### ラッピング

`Array.wrap`メソッドは、配列の中にある引数が配列 (または配列的なもの) になっていない場合に、それらを配列の中にラップします。

特徴:

* 引数が`nil`の場合、空の配列が返されます。
* 上記以外の場合で、引数が`to_ary`に応答する場合は`to_ary`が呼び出され、`to_ary`の値が`nil`でない場合はその値が返されます。
* 上記以外の場合、引数を内側に含んだ配列 (要素が1つだけの配列) が返されます。

```ruby
Array.wrap(nil)       # => []
Array.wrap([1, 2, 3]) # => [1, 2, 3]
Array.wrap(0)         # => [0]
```

このメソッドの目的は`Kernel#Array`と似ていますが、いくつかの相違点があります。

* 引数が`to_ary`に応答する場合、このメソッドが呼び出されます。`nil`が返された場合、`Kernel#Array`は`to_a`を適用しようと動作を続けますが、`Array.wrap`はその場で、引数を単一の要素として持つ配列を返します。
* `to_ary`から返された値が`nil`でも`Array`オブジェクトでもない場合、`Kernel#Array`は例外を発生しますが、`Array.wrap`は例外を発生せずに単にその値を返します。
* このメソッドは引数に対して`to_a`を呼び出しませんが、この引数が `to_ary` に応答しない場合、引数を単一の要素として持つ配列を返します。

最後の性質は、列挙型同士を比較する場合に特に便利です。

```ruby
Array.wrap(foo: :bar) # => [{:foo=>:bar}]
Array(foo: :bar)      # => [[:foo, :bar]]
```

この動作は、スプラット演算子を用いる手法にも関連します。

```ruby
[*object]
```

NOTE: 定義は`active_support/core_ext/array/wrap.rb`にあります。

### 複製

`Array#deep_dup`メソッドは、自分自身を複製すると同時に、その中のすべてのオブジェクトをActive Supportの`Object#deep_dup`メソッドによって再帰的に複製します。この動作は、`Array#map`を用いて`deep_dup`メソッドを内部の各オブジェクトに適用するのと似ています。

```ruby
array = [1, [2, 3]]
dup = array.deep_dup
dup[1][2] = 4
array[1][2] == nil   # => true
```

NOTE: 定義は`active_support/core_ext/object/deep_dup.rb`にあります。

### グループ化

#### `in_groups_of(number, fill_with = nil)`

`in_groups_of`メソッドは、指定のサイズで配列を連続したグループに分割し、分割されたグループを含む配列を1つ返します。

```ruby
[1, 2, 3].in_groups_of(2) # => [[1, 2], [3, nil]]
```

ブロックが渡された場合は`yield`します。

```html+erb
<% sample.in_groups_of(3) do |a, b, c| %>
  <tr>
    <td><%= a %></td>
    <td><%= b %></td>
    <td><%= c %></td>
  </tr>
<% end %>
```

最初の例では、`in_groups_of`メソッドは最後のグループをなるべく`nil`要素で埋め、指定のサイズを満たすようにしています。空きを埋める値は2番目のオプション引数で指定できます。

```ruby
[1, 2, 3].in_groups_of(2, 0) # => [[1, 2], [3, 0]]
```

2番目のオプション引数に`false`を渡すと、最後のグループの空きは詰められます。

```ruby
[1, 2, 3].in_groups_of(2, false) # => [[1, 2], [3]]
```

このため、`false`は空きを埋める値としては利用できません。

NOTE: 定義は`active_support/core_ext/array/grouping.rb`にあります。

#### `in_groups(number, fill_with = nil)`

`in_groups`は、配列を指定の個数のグループに分割し、分割されたグループを含む配列を1つ返します。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3)
# => [["1", "2", "3"], ["4", "5", nil], ["6", "7", nil]]
```

ブロックが渡された場合は`yield`します。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3) {|group| p group}
["1", "2", "3"]
["4", "5", nil]
["6", "7", nil]
```

この例では、`in_groups`メソッドは一部のグループの後ろを必要に応じて`nil`要素で埋めているのがわかります。1つのグループには、このような余分な要素がグループの一番右側に必要に応じて最大で1つ置かれる可能性があります。また、そのような値を持つグループは、常に全体の中で最後のグループになります。

空きを埋める値は2番目のオプション引数で指定できます。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, "0")
# => [["1", "2", "3"], ["4", "5", "0"], ["6", "7", "0"]]
```

2番目のオプション引数に`false`を渡すと、要素の個数の少ないグループの空きは詰められます。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, false)
# => [["1", "2", "3"], ["4", "5"], ["6", "7"]]
```

このため、`false`は空きを埋める値としては利用できません。

NOTE: 定義は`active_support/core_ext/array/grouping.rb`にあります。

#### `split(value = nil)`

`split`メソッドは、指定のセパレータで配列を分割し、分割されたチャンクを返します。

ブロックを渡した場合、配列の要素のうち「ブロックが`true`を返す要素」がセパレータとして使われます。

```ruby
(-5..5).to_a.split { |i| i.multiple_of?(4) }
# => [[-5], [-3, -2, -1], [1, 2, 3], [5]]
```

ブロックを渡さない場合、引数として受け取った値がセパレータとして使われます。デフォルトのセパレータは`nil`です。

```ruby
[0, 1, -5, 1, 1, "foo", "bar"].split(1)
# => [[0], [-5], [], ["foo", "bar"]]
```

TIP: 上の例からもわかるように、セパレータが連続すると空の配列になります。

NOTE: 定義は`active_support/core_ext/array/grouping.rb`にあります。

`Hash`の拡張
--------------------

### 各種変換

#### `to_xml`

`to_xml`メソッドは、レシーバをXML表現に変換したものを含む文字列を返します。

```ruby
{"foo" => 1, "bar" => 2}.to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <hash>
#   <foo type="integer">1</foo>
#   <bar type="integer">2</bar>
# </hash>
```

具体的には、このメソッドは与えられたペアから**値**に応じてノードを作成します。キーと値のペアが与えられたとき、以下のように動作します。

* 値がハッシュのとき、キーを`:root`として再帰的な呼び出しを行います。

* 値が配列の場合、キーを`:root`に、キーを単数形化（singularize）したものを`:children`に指定して再帰的な呼び出しを行います。

* 値が呼び出し可能な（callable）オブジェクトの場合、引数が1つまたは2つ必要です。引数の数に応じて (arityメソッドで確認)、呼び出し可能オブジェクトを呼び出します。第1引数には`:root`にキーを指定したもの、第2引数にはキーを単数形化したものが使われます。戻り値は新しいノードです。

* `value`が`to_xml`メソッドに応答する場合、`:root`にキーが指定されます。

* その他の場合、`key`を持ち、ノードがタグとして作成されます。そのノードには`value`を文字列形式にしたものがテキストノードとして追加されます。`value`が`nil`の場合、"nil"属性が"true"に設定されたものが追加されます。`:skip_types`オプションが`true`でない (または`:skip_types`オプションがない) 場合、「type」属性も以下のマッピングで追加されます。

```ruby
XML_TYPE_NAMES = {
  "Symbol"     => "symbol",
  "Fixnum"     => "integer",
  "Bignum"     => "integer",
  "BigDecimal" => "decimal",
  "Float"      => "float",
  "TrueClass"  => "boolean",
  "FalseClass" => "boolean",
  "Date"       => "date",
  "DateTime"   => "datetime",
  "Time"       => "datetime"
}
```

ルートノードはデフォルトでは「hash」ですが、`:root`オプションでカスタマイズできます。

デフォルトのXMLビルダは、`Builder::XmlMarkup`から直接生成されたインスタンスです。`:builder`オブションで独自のビルダを構成できます。このメソッドでは`:dasherize`とその同族と同様のオプションが利用でき、指定したオプションはビルダに転送されます。

NOTE: 定義は`active_support/core_ext/hash/conversions.rb`にあります。

### マージ

Rubyには、2つのハッシュをマージするビルトインの`Hash#merge`メソッドがあります。

```ruby
{a: 1, b: 1}.merge(a: 0, c: 2)
# => {:a=>0, :b=>1, :c=>2}
```

Active Supportでは、この他にも便利なハッシュのマージをいくつか提供しています。

#### `reverse_merge`と`reverse_merge!`

`merge`でキーが衝突した場合、引数のハッシュのキーが優先されます。以下のような定形の手法を利用すれば、デフォルト値付きオプションハッシュを簡潔に書けます。

```ruby
options = {length: 30, omission: "..."}.merge(options)
```

Active Supportでは、別の記法を使いたい場合のために`reverse_merge`も定義されています。

```ruby
options = options.reverse_merge(length: 30, omission: "...")
```

マージを対象内で行なう破壊的なバージョンの`reverse_merge!`もあります。

```ruby
options.reverse_merge!(length: 30, omission: "...")
```

WARNING: `reverse_merge!`は呼び出し元のハッシュを変更する可能性があることにご注意ください。それが意図した副作用であるかそうでないかにかかわらず、注意が必要です。

NOTE: 定義は`active_support/core_ext/hash/reverse_merge.rb`にあります。

#### `reverse_update`

`reverse_update`メソッドは、上で説明した`reverse_merge!`の別名です。

WARNING: `reverse_update`には!のついたバージョンはありません。

NOTE: 定義は`active_support/core_ext/hash/reverse_merge.rb`にあります。

#### `deep_merge`と`deep_merge!`

先の例で説明したとおり、キーがレシーバと引数で重複している場合、引数の側の値が優先されます。

Active Supportでは`Hash#deep_merge`が定義されています。ディープマージでは、レシーバと引数の両方に同じキーが出現し、さらにどちらも値がハッシュである場合に、その下位のハッシュを**マージ**したものが、最終的なハッシュの値として使われます。

```ruby
{a: {b: 1}}.deep_merge(a: {c: 2})
# => {:a=>{:b=>1, :c=>2}}
```

`deep_merge!`メソッドはディープマージを破壊的に実行します。

NOTE: 定義は`active_support/core_ext/hash/deep_merge.rb`にあります。

### ディープ複製

`Hash#deep_dup`メソッドは、自分自身の複製に加えて その中のすべてのキーと値を再帰的に複製します。複製にはActive Supportの`Object#deep_dup`メソッドが使われます。この動作は、`Enumerator#each_with_object`を用いて`deep_dup`を内部の各キーバリューペアに送信するのと似ています。

```ruby
hash = { a: 1, b: { c: 2, d: [3, 4] } }

dup = hash.deep_dup
dup[:b][:e] = 5
dup[:b][:d] << 5

hash[:b][:e] == nil      # => true
hash[:b][:d] == [3, 4]   # => true
```

NOTE: 定義は`active_support/core_ext/object/deep_dup.rb`にあります。

### ハッシュキーの操作

#### `except`と`except!`

`except`メソッドは、引数で指定されたキーがあればレシーバのハッシュから取り除きます。

```ruby
{a: 1, b: 2}.except(:a) # => {:b=>2}
```

レシーバが`convert_key`に応答する場合、このメソッドはすべての引数に対して呼び出されます。そのおかげで、たとえばハッシュの`with_indifferent_access`で`except`メソッドが期待どおりに動作します。

```ruby
{a: 1}.with_indifferent_access.except(:a)  # => {}
{a: 1}.with_indifferent_access.except("a") # => {}
```

レシーバーからキーを取り除く破壊的な`except!`もあります。

NOTE: 定義は`active_support/core_ext/hash/except.rb`にあります。

#### `stringify_keys`と`stringify_keys!`

`stringify_keys`メソッドは、レシーバのハッシュキーを文字列に変換したハッシュを返します。具体的には、レシーバのハッシュキーに対して`to_s`を送信しています。

```ruby
{nil => nil, 1 => 1, a: :a}.stringify_keys
# => {"" => nil, "1" => 1, "a" => :a}
```

キーが重複している場合、ハッシュに最も最近挿入された値が使われます。

```ruby
{"a" => 1, a: 2}.stringify_keys
# 値は以下になる
# => {"a"=>2}
```

このメソッドは、シンボルと文字列が両方含まれているハッシュをオプションとして受け取る場合に便利なことがあります。たとえば、`ActionView::Helpers::FormHelper`では以下のように定義されています。

```ruby
def to_check_box_tag(options = {}, checked_value = "1", unchecked_value = "0")
  options = options.stringify_keys
  options["type"] = "checkbox"
  ...
end
```

`stringify_keys`メソッドのおかげで、2行目で「type」キーに安全にアクセスできます。`:type`のようなシンボルでも「"type"」のような文字列でも指定できます。

レシーバーのキーを直接文字列化する破壊的な`stringify_keys!`もあります。

また、`deep_stringify_keys`や`deep_stringify_keys!`を使うと、与えられたハッシュのすべてのキーを文字列化し、その中にネストされているすべてのハッシュのキーを文字列化することもできます。以下に例を示します。

```ruby
{nil => nil, 1 => 1, nested: {a: 3, 5 => 5}}.deep_stringify_keys
# => {""=>nil, "1"=>1, "nested"=>{"a"=>3, "5"=>5}}
```

NOTE: 定義は`active_support/core_ext/hash/keys.rb`にあります。

#### `symbolize_keys`と`symbolize_keys!`

`symbolize_keys`メソッドは、レシーバのハッシュキーをシンボルに変換したハッシュを返します。具体的には、レシーバのハッシュキーに対して`to_sym`を送信しています。

```ruby
{nil => nil, 1 => 1, "a" => "a"}.symbolize_keys
# => {nil=>nil, 1=>1, :a=>"a"}
```

WARNING: 上の例では、3つのキーのうち最後の1つしかシンボルに変換されていないことにご注意ください。数字や`nil`はシンボルに変換されません。

キーが重複している場合、ハッシュに最も最近挿入された値が使われます。

```ruby
{"a" => 1, a: 2}.symbolize_keys
# 値は以下になる
# => {:a=>2}
```

このメソッドは、シンボルと文字列が両方含まれているハッシュをオプションとして受け取る場合に便利なことがあります。たとえば、`ActionController::UrlRewriter`では以下のように定義されています。

```ruby
def rewrite_path(options)
  options = options.symbolize_keys
  options.update(options[:params].symbolize_keys) if options[:params]
  ...
end
```

`symbolize_keys`メソッドのおかげで、2行目で`:params`キーに安全にアクセスできています。`:params`のようなシンボルでも「"params"」のような文字列でも指定できます。

レシーバーのキーを直接シンボルに変換する破壊的な`symbolize_keys!`もあります。

また、`deep_symbolize_keys`や`deep_symbolize_keys!`を使うと、与えられたハッシュのすべてのキーと、その中にネストされているすべてのハッシュのキーをシンボルに変換することもできます。以下に例を示します。

```ruby
{nil => nil, 1 => 1, "nested" => {"a" => 3, 5 => 5}}.deep_symbolize_keys
# => {nil=>nil, 1=>1, nested:{a:3, 5=>5}}
```

NOTE: 定義は`active_support/core_ext/hash/keys.rb`にあります。

#### `to_options`と`to_options!`

`to_options`メソッドと`to_options!`メソッドは、それそれ`symbolize_keys`メソッドと`symbolize_keys!`メソッドの別名です。

NOTE: 定義は`active_support/core_ext/hash/keys.rb`にあります。

#### `assert_valid_keys`

`assert_valid_keys`メソッドは任意の数の引数を取ることができ、ホワイトリストに含まれていないキーがレシーバにあるかどうかをチェックします。そのようなキーが見つかった場合、`ArgumentError`が発生します。

```ruby
{a: 1}.assert_valid_keys(:a)  # パスする
{a: 1}.assert_valid_keys("a") # ArgumentError
```

たとえばActive Recordは、関連付けをビルドするときに未知のオプションを受け付けません。Active Recordは`assert_valid_keys`による制御を実装しています。

NOTE: 定義は`active_support/core_ext/hash/keys.rb`にあります。

### スライス

破壊的なスライス操作を行なう`slice!`メソッドは、指定のキーのみを置き換え、削除されたキー/値ペアを含むハッシュを1つ返します。

```ruby
hash = {a: 1, b: 2}
rest = hash.slice!(:a) # => {:b=>2}
hash                   # => {:a=>1}
```

NOTE: 定義は`active_support/core_ext/hash/slice.rb`にあります。

### 抽出

`extract!`メソッドは、与えられたキーにマッチするキー/値ペアを取り除き、取り除いたペアを返します。

```ruby
hash = {a: 1, b: 2}
rest = hash.extract!(:a) # => {:a=>1}
hash                     # => {:b=>2}
```

`extract!`メソッドは、レシーバのハッシュのサブクラスと同じサブクラスを返します。

```ruby
hash = {a: 1, b: 2}.with_indifferent_access
rest = hash.extract!(:a).class
# => ActiveSupport::HashWithIndifferentAccess
```

NOTE: 定義は`active_support/core_ext/hash/slice.rb`にあります。

### ハッシュキーがシンボルでも文字列でも同様に扱う（indifferent access）

`with_indifferent_access`メソッドは、レシーバに対して`ActiveSupport::HashWithIndifferentAccess`を実行した結果を返します。

```ruby
{a: 1}.with_indifferent_access["a"] # => 1
```

NOTE: 定義は`active_support/core_ext/hash/indifferent_access.rb`にあります。

`Regexp`の拡張
----------------------

### `multiline?`

`multiline?`メソッドは、正規表現に`/m`フラグが設定されているかどうかをチェックします。このフラグが設定されていると、ドット（`.`）が改行にマッチし、複数行を扱えるようになります。

```ruby
%r{.}.multiline?  # => false
%r{.}m.multiline? # => true

Regexp.new('.').multiline?                    # => false
Regexp.new('.', Regexp::MULTILINE).multiline? # => true
```

Railsはこのメソッドをある一箇所、ルーティングコードで利用しています。ルーティングでは正規表現で複数行を扱うことを許していないので、このフラグで制限を加えています。

```ruby
def verify_regexp_requirements(requirements)
  ...
  if requirement.multiline?
    raise ArgumentError, "Regexp multiline option is not allowed in routing requirements: #{requirement.inspect}"
  end
  ...
end
```

NOTE: 定義は`active_support/core_ext/regexp.rb`にあります。

`Range`の拡張
---------------------

### `to_s`

Active Supportは`Range#to_s`メソッドを拡張してフォーマット引数をオプションで受け付けるようにしています。執筆時点では、デフォルトでないフォーマットとしてサポートされているのは`:db`のみです。

```ruby
(Date.today..Date.tomorrow).to_s
# => "2009-10-25..2009-10-26"

(Date.today..Date.tomorrow).to_s(:db)
# => "BETWEEN '2009-10-25' AND '2009-10-26'"
```

上の例でもわかるように、フォーマットに`:db`を指定するとSQLの`BETWEEN`句が生成されます。このフォーマットは、Active Recordで条件の値の範囲をサポートするときに使われます。

NOTE: 定義は`active_support/core_ext/range/conversions.rb`にあります。

### `===`、`include?`、`cover?`

`Range#===`メソッド、`Range#include?`メソッド、`Range#cover?`メソッドは、与えられたインスタンスの範囲内に値が収まっているかどうかをチェックします。

```ruby
(2..3).include?(Math::E) # => true
```

Active Supportではこれらのメソッドを拡張して、他の範囲指定を引数で指定できるようにしています。この場合、引数の範囲がレシーバの範囲の中に収まっているかどうかがチェックされています。

```ruby
(1..10) === (3..7)  # => true
(1..10) === (0..7)  # => false
(1..10) === (3..11) # => false
(1...9) === (3..9)  # => false

(1..10).include?(3..7)  # => true
(1..10).include?(0..7)  # => false
(1..10).include?(3..11) # => false
(1...9).include?(3..9)  # => false

(1..10).cover?(3..7)  # => true
(1..10).cover?(0..7)  # => false
(1..10).cover?(3..11) # => false
(1...9).cover?(3..9)  # => false
```

NOTE: 定義は`active_support/core_ext/range/compare_range.rb`にあります。

### `overlaps?`

`Range#overlaps?`メソッドは、与えられた2つの範囲に（空白でない）重なりがあるかどうかをチェックします。

```ruby
(1..10).overlaps?(7..11)  # => true
(1..10).overlaps?(0..7)   # => true
(1..10).overlaps?(11..27) # => false
```

NOTE: 定義は`active_support/core_ext/range/overlaps.rb`にあります。

`Date`の拡張
--------------------

### 計算

INFO: 以下の計算方法の一部では1582年10月をエッジケースとして用いています。この月にユリウス暦からグレゴリオ暦への切り替えが行われたため、10月5日から10月14日までが存在しません。本ガイドはこの「特殊な月」について長々と解説することはしませんが、メソッドがこの月でも期待どおりに動作することについては説明しておきたいと思います。具体的には、たとえば`Date.new(1582, 10, 4).tomorrow`を実行すると`Date.new(1582, 10, 15)`が返されます。期待どおりに動作することは、Active Supportの`test/core_ext/date_ext_test.rb`用のテストスイートで確認できます。

#### `Date.current`

Active Supportでは、`Date.current`を定義して現在のタイムゾーンにおける「今日」を定めています。このメソッドは`Date.today`と似ていますが、ユーザー定義のタイムゾーンがある場合にそれを考慮する点が異なります。Active Supportでは`Date.yesterday`メソッドと`Date.tomorrow`も定義しています。インスタンスでは`past?`、`today?`、`future?`、`on_weekday?`、`on_weekend?`を利用でき、これらはすべて`Date.current`を起点として導かれます。

ユーザー定義のタイムゾーンを考慮するメソッドを用いて日付を比較したい場合、`Date.today`ではなく必ず`Date.current`を使ってください。将来、ユーザー定義のタイムゾーンがシステムのタイムゾーンと比較されることがありえます。システムのタイムゾーンではデフォルトで`Date.today`が使われます。つまり、`Date.today`が`Date.yesterday`と等しくなることがありえるということです。

NOTE: 定義は`active_support/core_ext/date/calculations.rb`にあります。

#### 名前付き日付

##### `beginning_of_week`、`end_of_week`

`beginning_of_week`メソッドと`end_of_week`メソッドは、それぞれ週の最初の日付と週の最後の日付を返します。週の始まりはデフォルトでは月曜日ですが、引数を渡して変更できます。そのときにスレッドローカルの`Date.beginning_of_week`または`config.beginning_of_week`を設定します。

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.beginning_of_week          # => Mon, 03 May 2010
d.beginning_of_week(:sunday) # => Sun, 02 May 2010
d.end_of_week                # => Sun, 09 May 2010
d.end_of_week(:sunday)       # => Sat, 08 May 2010
```

`beginning_of_week`は`at_beginning_of_week`の別名、`end_of_week`は`at_end_of_week`の別名です。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `monday`、`sunday`

`monday`メソッドはその日の「前の月曜（の日付）」を、`sunday`メソッドはその日の「次の日曜（の日付）」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.monday                     # => Mon, 03 May 2010
d.sunday                     # => Sun, 09 May 2010

d = Date.new(2012, 9, 10)    # => Mon, 10 Sep 2012
d.monday                     # => Mon, 10 Sep 2012

d = Date.new(2012, 9, 16)    # => Sun, 16 Sep 2012
d.sunday                     # => Sun, 16 Sep 2012
```

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `prev_week`、`next_week`

`next_week`メソッドは、英語表記 (デフォルトではスレッドローカルの`Date.beginning_of_week`または`config.beginning_of_week`または`:monday`) の日付名のシンボルを受け取り、それに対応する日付を返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.next_week              # => Mon, 10 May 2010
d.next_week(:saturday)   # => Sat, 15 May 2010
```

`prev_week`も同様です。

```ruby
d.prev_week              # => Mon, 26 Apr 2010
d.prev_week(:saturday)   # => Sat, 01 May 2010
d.prev_week(:friday)     # => Fri, 30 Apr 2010
```

`prev_week`は`last_week`の別名です。

`Date.beginning_of_week`または`config.beginning_of_week`が設定されていれば、`next_week`と`prev_week`はどちらも正常に動作します。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `beginning_of_month`、`end_of_month`

`beginning_of_month`メソッドはその月の「最初の日」、`end_of_month`メソッドはその月の「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_month     # => Sat, 01 May 2010
d.end_of_month           # => Mon, 31 May 2010
```

`beginning_of_month`は`at_beginning_of_month`の別名、`end_of_month`は`at_end_of_month`の別名です。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `beginning_of_quarter`、`end_of_quarter`

`beginning_of_quarter`メソッドと`end_of_quarter`メソッドは、レシーバのカレンダーの年における四半期の「最初の日」と「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_quarter   # => Thu, 01 Apr 2010
d.end_of_quarter         # => Wed, 30 Jun 2010
```

`beginning_of_quarter`は`at_beginning_of_quarter`の別名、`end_of_quarter`は`at_end_of_quarter`の別名です。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `beginning_of_year`、`end_of_year`

`beginning_of_year`メソッドと`end_of_year`メソッドは、その年の「最初の日」と「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_year      # => Fri, 01 Jan 2010
d.end_of_year            # => Fri, 31 Dec 2010
```

`beginning_of_year`は`at_beginning_of_year`の別名、`end_of_year`は`at_end_of_year`の別名です。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

#### その他の日付計算メソッド

##### `years_ago`、`years_since`

`years_ago`メソッドは、年数を受け取り、その年数前の同じ日付を返します。

```ruby
date = Date.new(2010, 6, 7)
date.years_ago(10) # => Wed, 07 Jun 2000
```

`years_since`も同じ要領で、その年数後の同じ日付を返します。

```ruby
date = Date.new(2010, 6, 7)
date.years_since(10) # => Sun, 07 Jun 2020
```

同じ日が行き先の月にない場合、その月の最後の日が返されます。

```ruby
Date.new(2012, 2, 29).years_ago(3)     # => Sat, 28 Feb 2009
Date.new(2012, 2, 29).years_since(3)   # => Sat, 28 Feb 2015
```

`last_year`は`#years_ago(1)`のショートハンドです。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `months_ago`、`months_since`

`months_ago`メソッドと`months_since`メソッドは、上と同じ要領で月に対して行います。

```ruby
Date.new(2010, 4, 30).months_ago(2)   # => Sun, 28 Feb 2010
Date.new(2010, 4, 30).months_since(2) # => Wed, 30 Jun 2010
```

対象の月に同じ日がない場合は、その月の最後の日が返されます。

```ruby
Date.new(2010, 4, 30).months_ago(2)    # => Sun, 28 Feb 2010
Date.new(2009, 12, 31).months_since(2) # => Sun, 28 Feb 2010
```

`last_month`は`#months_ago(1)`のショートハンドです。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `weeks_ago`

`weeks_ago`メソッドは、同じ要領で週に対して行います。

```ruby
Date.new(2010, 5, 24).weeks_ago(1)    # => Mon, 17 May 2010
Date.new(2010, 5, 24).weeks_ago(2)    # => Mon, 10 May 2010
```

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `advance`

`advance`メソッドは、日付を移動する最も一般的な方法です。このメソッドは`:years`、`:months`、`:weeks`、`:days`をキーに持つハッシュを受け取り、日付をできるだけ詳細な形式で、現在のキーで示されるとおりに返します。

```ruby
date = Date.new(2010, 6, 6)
date.advance(years: 1, weeks: 2)  # => Mon, 20 Jun 2011
date.advance(months: 2, days: -2) # => Wed, 04 Aug 2010
```

上の例にも示されているように、増分値には負の数も指定できます。

計算の順序は、最初に年を増減し、次に月、最後に日を増減します。この順序で計算していることは、特に月を計算する時に重要です。たとえば、現在が2010年2月の最後の日で、そこから1か月と1日先に進めたいとします。

`advance`メソッドは最初に月を進め、それから日を進めます。それにより以下の結果を得ます。

```ruby
Date.new(2010, 2, 28).advance(months: 1, days: 1)
# => Sun, 29 Mar 2010
```

計算の順序が異なる場合、同じ結果が得られない可能性があります。

```ruby
Date.new(2010, 2, 28).advance(days: 1).advance(months: 1)
# => Thu, 01 Apr 2010
```

NOTE: 定義は`active_support/core_ext/date/calculations.rb`にあります。

#### 要素の変更

`change`メソッドは、与えられた年、月、日に応じてレシーバの日付を変更し、与えられなかった部分はそのままにしてその日付を返します。

```ruby
Date.new(2010, 12, 23).change(year: 2011, month: 11)
# => Wed, 23 Nov 2011
```

存在しない日付が指定されると`ArgumentError`が発生します。

```ruby
Date.new(2010, 1, 31).change(month: 2)
# => ArgumentError: invalid date
```

NOTE: 定義は`active_support/core_ext/date/calculations.rb`にあります。

#### 期間（duration）

日付に対して期間を加減算できます。

```ruby
d = Date.current
# => Mon, 09 Aug 2010
d + 1.year
# => Tue, 09 Aug 2011
d - 3.hours
# => Sun, 08 Aug 2010 21:00:00 UTC +00:00
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
Date.new(1582, 10, 4) + 1.day
# => Fri, 15 Oct 1582
```

#### タイムスタンプ

INFO: 以下のメソッドは可能であれば`Time`オブジェクトを返し、それ以外の場合は`DateTime`を返します。ユーザーのタイムゾーンが設定されていればそれも加味されます。

##### `beginning_of_day`、`end_of_day`

`beginning_of_day`メソッドは、その日の開始時点 (00:00:00) のタイムスタンプを返します。

```ruby
date = Date.new(2010, 6, 7)
date.beginning_of_day # => Mon Jun 07 00:00:00 +0200 2010
```

`end_of_day`メソッドは、その日の最後の時点 (23:59:59) のタイムスタンプを返します。

```ruby
date = Date.new(2010, 6, 7)
date.end_of_day # => Mon Jun 07 23:59:59 +0200 2010
```

`at_beginning_of_day`と`midnight`と`at_midnight`は、`beginning_of_day`の別名です。

NOTE: 定義は`active_support/core_ext/date/calculations.rb`にあります。

##### `beginning_of_hour`、`end_of_hour`

`beginning_of_hour`メソッドは、その時の最初の時点 (hh:00:00) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_hour # => Mon Jun 07 19:00:00 +0200 2010
```

`end_of_hour`メソッドは、その時の最後の時点 (hh:59:59) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_hour # => Mon Jun 07 19:59:59 +0200 2010
```

`beginning_of_hour`は`at_beginning_of_hour`の別名です。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `beginning_of_minute`、`end_of_minute`

`beginning_of_minute`は、その分の最初の時点 (hh:mm:00) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_minute # => Mon Jun 07 19:55:00 +0200 2010
```

`end_of_minute`メソッドは、その分の最後の時点 (hh:mm:59) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_minute # => Mon Jun 07 19:55:59 +0200 2010
```

`beginning_of_minute`は`at_beginning_of_minute`の別名です。

INFO: `beginning_of_hour`、`end_of_hour`、`beginning_of_minute`、`end_of_minute`は`Time`および`DateTime`への実装ですが、`Date`への実装では **ありません** 。`Date`インスタンスに対して時間や分の最初や最後を問い合わせる意味はありません。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

##### `ago`、`since`

`ago`メソッドは秒数を引数として受け取り、真夜中の時点からその秒数だけさかのぼった時点のタイムスタンプを返します。

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.ago(1)         # => Thu, 10 Jun 2010 23:59:59 EDT -04:00
```

`since`メソッドは、同様にその秒数だけ先に進みます。

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.since(1)       # => Fri, 11 Jun 2010 00:00:01 EDT -04:00
```

NOTE: 定義は`active_support/core_ext/date/calculations.rb`にあります。

#### その他の時間計算

### 各種変換

`DateTime`の拡張
------------------------

WARNING: `DateTime`は夏時間 (DST) ルールについては関知しません。夏時間の変更が行われた場合、メソッドの一部がこのとおりに動作しないことがあります。たとえば、`seconds_since_midnight`メソッドが返す秒数が実際の総量と合わない可能性があります。

### 計算

`DateTime`クラスは`Date`のサブクラスであり、`active_support/core_ext/date/calculations.rb`を読み込むことでこれらのメソッドと別名を継承することができます。ただしこれらは常にdatetimesを返す点が異なります。

以下のメソッドはすべて再実装されるため、これらを用いるために`active_support/core_ext/date/calculations.rb`を読み込む必要は **ありません** 。

```ruby
beginning_of_day (midnight, at_midnight, at_beginning_of_day)
end_of_day
ago
since (in)
```

他方、`advance`と`change`も定義されていて、さらに多くのオプションをサポートしています。これらについては後述します。

以下のメソッドは`active_support/core_ext/date_time/calculations.rb`にのみ実装されています。これらは`DateTime`インスタンスに対して使わないと意味がないためです。

```ruby
beginning_of_hour (at_beginning_of_hour)
end_of_hour
```

#### 名前付き日付時刻

##### `DateTime.current`

Active Supportでは、`DateTime.current`を`Time.now.to_datetime`と同様に定義しています。ただし、`DateTime.current`はユーザータイムゾーンが定義されている場合に対応する点が異なります。Active Supportでは`Date.yesterday`メソッドと`Date.tomorrow`も定義しています。インスタンスでは`past?`と`future?`を利用でき、これらは`Date.current`を起点として導かれます。

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

#### その他の拡張

##### `seconds_since_midnight`

`seconds_since_midnight`メソッドは、真夜中からの経過秒数を返します。

```ruby
now = DateTime.current     # => Mon, 07 Jun 2010 20:26:36 +0000
now.seconds_since_midnight # => 73596
```

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

##### `utc`

`utc`メソッドは、レシーバの日付時刻をUTCで返します。

```ruby
now = DateTime.current # => Mon, 07 Jun 2010 19:27:52 -0400
now.utc                # => Mon, 07 Jun 2010 23:27:52 +0000
```

`getutc`はこのメソッドの別名です。

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

##### `utc?`

`utc?`述語メソッドは、レシーバがそのタイムゾーンに合ったUTC時刻を持っているかどうかをチェックします。

```ruby
now = DateTime.now # => Mon, 07 Jun 2010 19:30:47 -0400
now.utc?          # => false
now.utc.utc?      # => true
```

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

##### `advance`

`advance`メソッドは、日時を移動する最も一般的な方法です。このメソッドは`:years`、`:months`、`:weeks`、`:days`、`:hours`、`:minutes`および`:seconds`をキーに持つハッシュを受け取り、日時をできるだけ詳細な形式で、現在のキーで示されるとおりに返します。

```ruby
d = DateTime.current
# => Thu, 05 Aug 2010 11:33:31 +0000
d.advance(years: 1, months: 1, days: 1, hours: 1, minutes: 1, seconds: 1)
# => Tue, 06 Sep 2011 12:34:32 +0000
```

このメソッドはまず、上で説明されている`Date#advance`に対する経過年(`:years`)、経過月 (`:months`)、経過週 (`:weeks`)、経過日 (`:days`) を元に移動先の日付を算出します。続いて、算出された時点までの経過秒数を元に`since`メソッドを呼び出し、時間を補正します。この実行順序には意味があります。極端なケースでは、順序が変わると計算結果も異なる場合があります。これは上の`Date#advance`で示した例で適用されます。相対的な時間の計算においても計算の順序は同様に重要です。

もし仮に日付部分を先に進め (前述したとおり、相対的な計算順序があります)、続いて時間の部分も先に進めると、以下のような計算結果が得られます。

```ruby
d = DateTime.new(2010, 2, 28, 23, 59, 59)
# => Sun, 28 Feb 2010 23:59:59 +0000
d.advance(months: 1, seconds: 1)
# => Mon, 29 Mar 2010 00:00:00 +0000
```

今度は順序を変えて計算すると、結果が異なります。

```ruby
d.advance(seconds: 1).advance(months: 1)
# => Thu, 01 Apr 2010 00:00:00 +0000
```

WARNING: `DateTime`は夏時間 (DST) を考慮しません。算出された時間が最終的に存在しない時間になっても警告やエラーは発生しません。

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

#### 要素の変更

`change`メソッドを使うと、レシーバの日時の一部の要素だけを更新した新しい日時を得られます。変更する要素として、`:year`、`:month`、`:day`、`:hour`、`:min`、`:sec`、`:offset`、`:start`などを指定できます。

```ruby
now = DateTime.current
# => Tue, 08 Jun 2010 01:56:22 +0000
now.change(year: 2011, offset: Rational(-6, 24))
# => Wed, 08 Jun 2011 01:56:22 -0600
```

時 (hour) がゼロの場合、分と秒も値を与えられない限り同様にゼロになります。

```ruby
now.change(hour: 0)
# => Tue, 08 Jun 2010 00:00:00 +0000
```

同様に、分がゼロの場合、秒も値を与えられない限りゼロになります。

```ruby
now.change(min: 0)
# => Tue, 08 Jun 2010 01:00:00 +0000
```

存在しない日付が指定されると`ArgumentError`が発生します。

```ruby
DateTime.current.change(month: 2, day: 30)
# => ArgumentError: invalid date
```

NOTE: 定義は`active_support/core_ext/date_time/calculations.rb`にあります。

#### 期間（duration）

日時に対して期間を加減算できます。

```ruby
now = DateTime.current
# => Mon, 09 Aug 2010 23:15:17 +0000
now + 1.year
# => Tue, 09 Aug 2011 23:15:17 +0000
now - 1.week
# => Mon, 02 Aug 2010 23:15:17 +0000
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
DateTime.new(1582, 10, 4, 23) + 1.hour
# => Fri, 15 Oct 1582 00:00:00 +0000
```

`Time`の拡張
--------------------

### 計算

これらは同様に動作します。関連するドキュメントを参照し、以下の相違点についても把握しておいてください。

* `change`メソッドは追加の`:usec`も受け付けます。
* `Time`は夏時間 (DST) を理解します。以下のように夏時間を正しく算出できます。

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>

# バルセロナでは夏時間により2010/03/28 02:00 +0100が2010/03/28 03:00 +0200になる
t = Time.local(2010, 3, 28, 1, 59, 59)
# => Sun Mar 28 01:59:59 +0100 2010
t.advance(seconds: 1)
# => Sun Mar 28 03:00:00 +0200 2010
```

* `since`や`ago`の移動先の時間が`Time`で表現できない場合、`DateTime`オブジェクトが代わりに返されます。

#### `Time.current`

Active Supportでは、`Time.current`を定義して現在のタイムゾーンにおける「今日」を定めています。このメソッドは`Time.now`と似ていますが、ユーザー定義のタイムゾーンがある場合にそれを考慮する点が異なります。Active Supportでは`past?`、`today?`、`future?`を示すインスタンス述語も定義されており、これらはすべてこの`Time.current`を起点にしています。

ユーザー定義のタイムゾーンを考慮するメソッドを用いて日付を比較したい場合、`Time.now`ではなく必ず`Time.current`を使ってください。将来、ユーザー定義のタイムゾーンがシステムのタイムゾーンと比較されることがありえます。システムのタイムゾーンではデフォルトで`Time#now`が使われます。つまり、`Time.now`が`Time.currentyesterday`と等しくなることがありえるということです。

NOTE: 定義は`active_support/core_ext/time/calculations.rb`にあります。

#### `all_day`、`all_week`、`all_month`、`all_quarter`、`all_year`

`all_day`メソッドは、現在時刻を含む「その日一日」を表す範囲を返します。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_day
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Mon, 09 Aug 2010 23:59:59 UTC +00:00
```

同様に、`all_week`、`all_month`、`all_quarter`、`all_year`も時間の範囲を生成できます。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_week
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Sun, 15 Aug 2010 23:59:59 UTC +00:00
now.all_week(:sunday)
# => Sun, 16 Sep 2012 00:00:00 UTC +00:00..Sat, 22 Sep 2012 23:59:59 UTC +00:00
now.all_month
# => Sat, 01 Aug 2010 00:00:00 UTC +00:00..Tue, 31 Aug 2010 23:59:59 UTC +00:00
now.all_quarter
# => Thu, 01 Jul 2010 00:00:00 UTC +00:00..Thu, 30 Sep 2010 23:59:59 UTC +00:00
now.all_year
# => Fri, 01 Jan 2010 00:00:00 UTC +00:00..Fri, 31 Dec 2010 23:59:59 UTC +00:00
```

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

#### `prev_day`、`next_day`

`prev_day`や`next_day`は、その日の「前日」または「翌日」の日時をそれぞれ返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_day               # => 2010-05-07 00:00:00 +0900
t.next_day               # => 2010-05-09 00:00:00 +0900
```

NOTE: 定義は`active_support/core_ext/time/calculations.rb`にあります。

#### `prev_month`、`next_month`

`prev_month`や`next_month`は、「前月」または「翌月」の同じ日の日時をそれぞれ返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_month             # => 2010-04-08 00:00:00 +0900
t.next_month             # => 2010-06-08 00:00:00 +0900
```

該当する日付が存在しない場合、対応する月の最終日が返されます。

```ruby
Time.new(2000, 5, 31).prev_month # => 2000-04-30 00:00:00 +0900
Time.new(2000, 3, 31).prev_month # => 2000-02-29 00:00:00 +0900
Time.new(2000, 5, 31).next_month # => 2000-06-30 00:00:00 +0900
Time.new(2000, 1, 31).next_month # => 2000-02-29 00:00:00 +0900
```

NOTE: 定義は`active_support/core_ext/time/calculations.rb`にあります。

#### `prev_year`、`next_year`

`prev_year`や`next_year`は、「前年」または「翌年」の同じ月日の日時をそれぞれ返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_year              # => 2009-05-08 00:00:00 +0900
t.next_year              # => 2011-05-08 00:00:00 +0900
```

うるう年の2月29日の場合、28日の日付が返されます。

```ruby
t = Time.new(2000, 2, 29) # => 2000-02-29 00:00:00 +0900
t.prev_year               # => 1999-02-28 00:00:00 +0900
t.next_year               # => 2001-02-28 00:00:00 +0900
```

NOTE: 定義は`active_support/core_ext/time/calculations.rb`にあります。

#### `prev_quarter`、`next_quarter`

`prev_quarter`や`next_quarter`は、「前四半期」または「翌四半期」の同じ日の日付をそれぞれ返します。

```ruby
t = Time.local(2010, 5, 8) # => 2010-05-08 00:00:00 +0300
t.prev_quarter             # => 2010-02-08 00:00:00 +0200
t.next_quarter             # => 2010-08-08 00:00:00 +0300
```

該当する日付が存在しない場合、対応する月の最終日が返されます。

```ruby
Time.local(2000, 7, 31).prev_quarter  # => 2000-04-30 00:00:00 +0300
Time.local(2000, 5, 31).prev_quarter  # => 2000-02-29 00:00:00 +0200
Time.local(2000, 10, 31).prev_quarter # => 2000-07-31 00:00:00 +0300
Time.local(2000, 11, 31).next_quarter # => 2001-03-01 00:00:00 +0200
```

`prev_quarter`は`last_quarter`のエイリアスです。

NOTE: 定義は`active_support/core_ext/date_and_time/calculations.rb`にあります。

### 時間コンストラクタ

ユーザータイムゾーンが定義されている場合、Active Supportが定義する`Time.current`の値は`Time.zone.now`の値と同じになります。ユーザータイムゾーンが定義されていない場合は、`Time.now`と同じになります。

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>
Time.current
# => Fri, 06 Aug 2010 17:11:58 CEST +02:00
```

`DateTime`と同様、述語`past?`と`future?`は`Time.current`を起点とします。

構成される時間が、実行プラットフォームの`Time`でサポートされる範囲を超えている場合は、usecは破棄され、`DateTime`オブジェクトが代りに返されます。

#### 期間（duration）

Timeオブジェクトに対して期間を加減算できます。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now + 1.year
# => Tue, 09 Aug 2011 23:21:11 UTC +00:00
now - 1.week
# => Mon, 02 Aug 2010 23:21:11 UTC +00:00
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
Time.utc(1582, 10, 3) + 5.days
# => Mon Oct 18 00:00:00 UTC 1582
```

`File`の拡張
--------------------

### `atomic_write`

`File.atomic_write`クラスメソッドを使うと、書きかけの文章を誰にも読まれないようにファイルを保存できます。

このメソッドにファイル名を引数として渡すと、書き込み用にオープンされたファイルハンドルを生成します。ブロックが完了すると、`atomic_write`はファイルハンドルをクローズして処理を完了します。

Action Packは、このメソッドを利用して`all.css`などのキャッシュファイルへの書き込みを行ないます。

```ruby
File.atomic_write(joined_asset_path) do |cache|
  cache.write(join_asset_file_contents(asset_paths))
end
```

`atomic_write`は、処理を完了するために一時的なファイルを作成します。ブロック内のコードが実際に書き込むのはこのファイルです。この一時ファイルは完了時にリネームされます。リネームは、POSIXシステムのアトミック操作に基いて行われます。書き込み対象ファイルが既に存在する場合、`atomic_write`はそれを上書きしてオーナーとパーミッションを保持します。ただし、`atomic_write`メソッドがファイルのオーナーシップとパーミッションを変更できないケースがまれにあります。このエラーはキャッチされ、そのファイルがそれを必要とするプロセスからアクセスできるようにするために、ユーザーのファイルシステムへの信頼をスキップします。

NOTE: `atomic_write`が行なうchmod操作が原因で、書き込み対象ファイルがACLセットを持っているときにそのACLが再計算/変更されます。

WARNING: `atomic_write`で追記を行なうことはできません。

この補助ファイルは標準の一時ファイル用ディレクトリに書き込まれますが、2番目の引数でディレクトリを直接指定することもできます。

NOTE: 定義は`active_support/core_ext/file/atomic.rb`にあります。

`Marshal`の拡張
-----------------------

### `load`

Active Supportは、`load`に一定の自動読み込みサポートを追加します。

たとえば、ファイルキャッシュストアでは以下のようにデシリアライズ (deserialize) します。

```ruby
File.open(file_name) { |f| Marshal.load(f) }
```

キャッシュデータが不明な定数を参照している場合、自動読み込みがトリガされます。読み込みに成功した場合はシリアライズを透過的に再試行します。

WARNING: 引数が`IO`の場合、再試行を可能にするために`rewind`に応答する必要があります。通常のファイルは`rewind`に応答します。

NOTE: 定義は`active_support/core_ext/marshal.rb`にあります。

`NameError`の拡張
-------------------------

Active Supportは`NameError`に`missing_name?`メソッドを追加します。このメソッドは、引数として渡された名前が原因で例外が発生するかどうかをテストします。

渡される名前はシンボルまたは文字列です。シンボルを渡した場合は単なる定数名をテストし、文字列を渡した場合はフルパス (fully-qualified) の定数名をテストします。

TIP: シンボルは、`:"ActiveRecord::Base"`で行なっているのと同じようにフルパスの定数として表せます。シンボルがそのように動作するのはそれが便利だからであり、技術的にそうしなければならないというものではありません。

たとえば、`ArticlesController`のアクションが呼び出されると、Railsはその名前からすぐに推測できる`ArticleHelper`を使おうとします。ここではこのヘルパーモジュールが存在していなくても問題はないので、この定数名で例外が発生しても例外として扱わずに黙殺する必要があります。しかし、実際に不明な定数が原因で`articles_helper.rb`が`NameError`エラーを発生するという場合が考えられます。そのような場合は、改めて例外を発生させなくてはなりません。`missing_name?`メソッドは、この2つの場合を区別するために使われます。

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 定義は`active_support/core_ext/name_error.rb`にあります。

`LoadError`の拡張
-------------------------

Active Supportは`is_missing?`を`LoadError`に追加します。

`is_missing?`は、パス名を引数に取り、特定のファイルが原因で例外が発生するかどうかをテストします (".rb"拡張子が原因と思われる場合を除きます)。

たとえば、`ArticlesController`のアクションが呼び出されると、Railsは`articles_helper.rb`を読み込もうとしますが、このファイルは存在しないことがあります。ヘルパーモジュールは必須ではないので、Railsは読み込みエラーを例外扱いせずに黙殺します。しかし、ヘルパーモジュールが存在しないために別のライブラリが必要になり、それがさらに見つからないという場合が考えられます。Railsはそのような場合には例外を再発生させなければなりません。`is_missing?`メソッドは、この2つの場合を区別するために使われます。

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 定義は`active_support/core_ext/load_error.rb`にあります。
