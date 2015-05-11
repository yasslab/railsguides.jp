
Active Record バリデーション
==========================

このガイドでは、Active Recordのバリデーション (検証: validation) 機能を使用して、オブジェクトがデータベースに保存される前にオブジェクトの状態を検証する方法について説明します。

このガイドの内容:

* ビルトインのActive Recordバリデーションヘルパーの使用
* カスタムのバリデーションメソッドの作成
* バリデーションプロセスで生成されたエラーメッセージの取り扱い

-------------------------------------------------------------------------------

バリデーションの概要
---------------------

きわめてシンプルなバリデーションの例を以下に紹介します。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

上からわかるように、このバリデーションでは`Person`に`name`属性がない場合に無効であることを知らせます。2つ目の`Person`はデータベースに保存されません。

バリデーションの詳細を説明する前に、アプリケーション全体においてバリデーションがいかに重要であるかについて説明します。

### バリデーションを行なう理由

バリデーションは、正しいデータだけをデータベースに保存するために行われます。たとえば、自分のアプリケーションで、すべてのユーザーには必ず電子メールアドレスとメーリングリストアドレスが必要だとします。正しいデータだけをデータベースに保存するのであれば、モデルレベルでバリデーションを実行するのが最適です。モデルレベルでのバリデーションは、データベースに依存せず、エンドユーザーがバイパスすることもできず、テストも保守も容易だからです。Railsではバリデーションを簡単に利用できるよう、一般に利用可能なビルトインヘルパーが用意されており、自前のバリデーションメソッドを作成することもできるようになっています。

データをデータベースに保存する前にバリデーションを実行する方法は、他にもデータベースネイティブの制約機能、クライアント側でのバリデーション、コントローラレベルのバリデーションなど、多くの方法があります。それぞれのメリットとデメリットは以下のとおりです。

* データベース制約やストアドプロシージャを使用すると、バリデーションのメカニズムがデータベースに依存してしまい、テストや保守がその分面倒になります。ただし、データベースが (Rails以外の) 他のアプリケーションからも使用されるのであれば、データベースレベルである程度のバリデーションを行なっておくのはよい方法です。また、データベースレベルのバリデーションの中には、使用頻度がきわめて高いテーブルの一意性バリデーションなど、他の方法では実装が困難なものもあります。
* クライアント側でのバリデーションは扱いやすく便利ですが、一般に単独では信頼性が不足します。JavaScriptを使用してバリデーションを実装する場合、ユーザーがJavaScriptをオフにしてしまえばバイパスされてしまいます。ただし、他の方法と併用するのであれば、クライアント側でのバリデーションはユーザーに即座にフィードバックを返すための便利な方法となるでしょう。
* コントローラレベルのバリデーションは一度はやってみたくなるものですが、たいてい手に負えなくなり、テストも保守も困難になりがちです。アプリケーションの寿命を永らえ、保守作業を苦痛なものにしないようにするためには、コントローラのコード量は可能な限り減らすべきです。

上で紹介したその他のバリデーションについては、特定の状況に応じて適宜追加してください。Railsチームは、ほとんどの場合モデルレベルのバリデーションが最も適切であると考えています。

### バリデーション実行時の動作

Active Recordのオブジェクトには2種類あります。オブジェクトがデータベースの行(row)に対応しているものと、そうでないものです。たとえば、`new`メソッドを使用して新しくオブジェクトを作成しただけでは、オブジェクトはデータベースに属していません。`save`メソッドを呼ぶことで、オブジェクトは適切なデータベースのテーブルに保存されます。Active Recordの`new_record?`インスタンスメソッドを使用して、オブジェクトが既にデータベース上にあるかどうかを確認できます。
次の単純はActive Recordクラスを例に取ってみましょう。

```ruby
class Person < ActiveRecord::Base
end
```

`rails console`の出力で様子を観察してみます。

```ruby
$ rails console
>> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>
>> p.new_record?
=> true
>> p.save
=> true
>> p.new_record?
=> false
```

新規レコードを作成して保存すると、SQLの`INSERT`操作がデータベースに送信されます。既存のレコードを更新すると、SQLの`UPDATE`操作が送信されます。バリデーションは、SQLのデータベースへの送信前に行うのが普通です。バリデーションのいずれかが失敗すると、オブジェクトは無効(invalid)とマークされ、Active Recordでの`INSERT`や`UPDATE`操作は行われません。これにより、無効なオブジェクトがデータベースに保存されることを防止します。オブジェクトの作成、保存、更新時に特定のバリデーションを実行することもできます。

CAUTION: データベース上のオブジェクトの状態を変える方法は1つとは限りません。
メソッドには、バリデーションをトリガするものと、しないものがあります。この点に注意しておかないと、バリデーションが設定されているにもかかわらず、データベース上のオブジェクトが無効な状態になってしまう可能性があります。

以下のメソッドではバリデーションがトリガされ、オブジェクトが有効な場合にのみデータベースに保存されます。

* `create`
* `create!`
* `save`
* `save!`
* `update`
* `update!`

破壊的なメソッド(`save!`など)では、レコードが無効な場合に例外が発生します。
非破壊的なメソッドでは無効な場合に例外を発生しません。`save`と`update`は無効な場合に`false`を返し、`create`は無効な場合に単にそのオブジェクトを返します。

### バリデーションのスキップ

以下のメソッドはバリデーションを行わずにスキップします。オブジェクトの保存は、有効無効にかかわらず行われます。これらのメソッドの使用には注意が必要です。

* `decrement!`
* `decrement_counter`
* `increment!`
* `increment_counter`
* `toggle!`
* `touch`
* `update_all`
* `update_attribute`
* `update_column`
* `update_columns`
* `update_counters`

実は、`save`に`validate: false`を引数として与えると、`save`のバリデーションをスキップすることができてしまいます。この手法は注意深く使用する必要があります。

* `save(validate: false)`

### `valid?`と`invalid?`

Railsでオブジェクトが有効(valid)であるかどうかを検証するには、`valid?`メソッドを使用します。
このメソッドは単独で使用できます。`valid?`を実行するとバリデーションがトリガされ、オブジェクトにエラーがない場合はtrueが返され、そうでなければfalseが返されます。
これは以下のように実装できます。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Recordでバリデーションが行われた後は、`errors.messages`インスタンスメソッドを使用すると、発生したエラーにアクセスできます。このメソッドはエラーのコレクションを返します。
定義上は、バリデーション実行後にコレクションが空になった場合は有効です。

`new`を使用してインスタンス化されたオブジェクトは、仮に技術的に無効であってもエラーは報告されないので、注意が必要です。`new`ではバリデーションは実行されません。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> p = Person.new
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {}

>> p.valid?
# => false
>> p.errors.messages
# => {name:["空欄にはできません"]}

>> p = Person.create
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {name:["空欄にはできません"]}

>> p.save
# => false

>> p.save!
# => ActiveRecord::RecordInvalid: Validation failed: 空欄にはできません

>> Person.create!
# => ActiveRecord::RecordInvalid: Validation failed: 空欄にはできません
```

`invalid?`は単なる`valid?`の逆の動作です。このメソッドはバリデーションをトリガし、オブジェクトでエラーが発生した場合はtrueを、そうでなければfalseを返します。

### `errors[]`

`errors[:attribute]`を使用して、特定のオブジェクトの属性が有効であるかどうかを確認できます。このメソッドは、`:attribute`のすべてのエラーの配列を返します。指定された属性でエラーが発生しなかった場合は、空の配列が返されます。

このメソッドが便利なのは、 _after_ で始まるバリデーションを実行する場合だけです。このメソッドはエラーのコレクションを調べるだけで、バリデーションそのものをトリガしないからです。このメソッドは、前述の`ActiveRecord::Base#invalid?`メソッドとは異なります。このメソッドはオブジェクト全体の正当性については確認しないためです。オブジェクトの個別の属性についてエラーがあるかどうかだけを調べます。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

より高度なレベルでのバリデーションエラーについては、[バリデーションエラーの取り扱い](#バリデーションエラーに対応する)セクションを参照してください。それまでは、Railsがデフォルトで提供するビルトインのバリデーションヘルパーを中心に解説します。

バリデーションヘルパー
------------------

Active Recordには、クラス定義の内側で直接使用できる定義済みのバリデーションヘルパーが多数用意されています。これらのヘルパーは、共通のバリデーションルールを提供します。バリデーションが失敗するたびに、オブジェクトの`errors`コレクションにエラーメッセージが追加され、そのメッセージは、バリデーションが行われる属性に関連付けられます。

どのヘルパーも任意の数の属性を受け付けることができるので、1行のコードを書くだけで多くの属性に対して同じバリデーションを実行できます。

`:on`オプションと`:message`オプションはどのヘルパーでも使用できます。これらのオプションはそれぞれ、バリデーションを実行するタイミングと、バリデーション失敗時に`errors`コレクションに追加するメッセージを指定します。`:on`オプションは`:create`または`:update`のいずれかの値を取ります。バリデーションヘルパーには、それぞれデフォルトのエラーメッセージが用意されています。`:message`オプションが使用されていない場合はデフォルトのメッセージが使用されます。利用可能なヘルパーを1つずつ見ていきましょう。

### `acceptance`

このメソッドは、フォームが送信されたときにユーザーインターフェイス上のチェックボックスがオンになっているかどうかを検証します。ユーザーにサービス利用条項への同意、何らかの文書に目を通すことなどを義務付けるのに使用するのが典型的な利用法です。このバリデーションはWebアプリケーション特有のものなので、'acceptance'はデータベースに保存する必要はありません。保存用のフィールドを作成しなかった場合、ヘルパーは単に仮想の属性を作成します。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: true
end
```

このヘルパーのデフォルトエラーメッセージは _"must be accepted"_ です。

このヘルパーでは`:accept`オプションを使用できます。このオプションは、「受付済み」を表す値を指定します。デフォルトは"1"ですが、容易に変更できます。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: { accept: 'yes' }
end
```

### `validates_associated`

モデルが他のモデルに関連付けられていて、両方のモデルに対してバリデーションを実行する必要がある場合はこのヘルパーを使用します。オブジェクトを保存しようとすると、関連付けられているオブジェクトごとに`valid?`が呼び出されます。

```ruby
class Library < ActiveRecord::Base
  has_many :books
  validates_associated :books
end
```

このバリデーションは、あらゆる種類の関連付けに対して使用できます。

CAUTION: `validates_associated`は関連付けの両側のオブジェクトでは実行しないでください。
関連付けの両側でこのヘルパーを使用すると無限ループになります。

`validates_associated`のデフォルトエラーメッセージは _"is invalid"_ です。関連付けられたオブジェクトにも自分の`errors`コレクションが含まれるので、エラーは呼び出し元のモデルまでは伝わりません。

### `confirmation`

このヘルパーは、2つのテキストフィールドが完全に一致する内容を受け取る必要がある場合に使用します。たとえば、メールアドレスやパスワードで、確認フィールドを使用するとします。このバリデーションヘルパーは仮想の属性を作成します。その属性の名前は、確認したい属性名に "_confirmation" を追加したものになります。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
end
```

ビューテンプレートで以下のようなフィールドを用意します。

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

このチェックは、`email_confirmation`が`nil`でない場合のみ実施されます。確認を必須にするには、確認用の属性について存在チェックも追加しておくようにしてください。`presence`を使用した存在チェックについてはこの後解説します。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

このヘルパーのデフォルトメッセージは _"doesn't match confirmation"_ です。

### `exclusion`

このヘルパーは、与えられた集合に属性の値が含まれて「いない」ことを検証します。集合としては任意のenumerableオブジェクトが使用できます。

```ruby
class Account < ActiveRecord::Base
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value}は予約済みです" }
end
```

`exclusion`ヘルパーの`:in`オプションには、バリデーションを行った属性の値に含めたくない値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使用できます。上の例では、`:message`オプションを使用して属性の値を含める方法を示しています。

デフォルトのエラーメッセージは _"is reserved"_ です。

### `format`

このヘルパーは、`with`オプションで与えられた正規表現と属性の値がマッチするかどうかをテストすることによってバリデーションを行います。

```ruby
class Product < ActiveRecord::Base
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "英文字のみが使用できます" }
end
```

デフォルトのエラーメッセージは _"is invalid"_ です。

### `inclusion`

このヘルパーは、与えられた集合に属性の値が含まれているかどうかを検証します。
集合としては任意のenumerableオブジェクトが使用できます。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
message: "%{value} のサイズは無効です" }
end
```

`inclusion`ヘルパーには`:in`オプションがあり、受け付け可能とする値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使用できます。上の例では、属性の値をインクルードする方法を示すために`:message`オプションも使用しています。

このヘルパーのデフォルトのエラーメッセージは _"is not included in the list"_ です。

### `length`

このヘルパーは、属性の値の長さを検証します。多くのオプションがあり、長さ制限をさまざまな方法で指定できます。

```ruby
class Person < ActiveRecord::Base
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

使用可能な長さ制限オプションは以下のとおりです。

* `:minimum` - 属性はこの値より小さな値を取れません。
* `:maximum` - 属性はこの値より大きな値を取れません。
* `:in` または `:within` - 属性の長さは、与えられた区間以内でなければなりません。このオプションの値は範囲でなければなりません。
* `:is` - 属性の長さは与えられた値と等しくなければなりません。

デフォルトのエラーメッセージは、実行されるバリデーションの種類によって異なります。デフォルトのメッセージは`:wrong_length`、`:too_long`、`:too_short`オプションを使用してカスタマイズしたり、`%{count}`を長さ制限に対応する数値のプレースホルダとして使用したりできます。`:message`オプションを使用してエラーメッセージを指定することもできます。

```ruby
class Person < ActiveRecord::Base
  validates :bio, length: { maximum: 1000,
too_long: "最大%{count}文字まで使用できます" }
end
```

このヘルパーはデフォルトでは文字単位で長さをチェックしますが、`:tokenizer`オプションを使用することで他の方法で値を区分することもできます。

```ruby
class Essay < ActiveRecord::Base
  validates :content, length: {
    minimum: 300,
    maximum: 400,
    tokenizer: lambda { |str| str.scan(/\w+/) },
    too_short: "%{count}語以上必要です",
too_long: "使用可能な最大語数は%{count}です"
  }
end
```

デフォルトのエラーメッセージは複数形で表現されていることにご注意ください (例: "is too short (minimum is %{count} characters)")。このため、`:minimum`を1に設定するのであればメッセージをカスタマイズして単数形にするか、代りに`presence: true`を使用します。`:in`または`:within`に1よりも小さい値を指定する場合、メッセージをカスタマイズして複数形にするか、`length`より先に`presence`を呼ぶようにします。

### `numericality`

このヘルパーは、属性に数値のみが使用されていることを検証します。デフォルトでは、整数または浮動小数点にマッチします。これらの冒頭に符号が付いている場合もマッチします。整数のみにマッチさせたい場合は、`:only_integer`をtrueにします。

`:only_integer`を`true`に設定すると、

```ruby
/\A[+-]?\d+\Z/
```

上の正規表現を使用して属性の値に対するバリデーションが行われます。それ以外の場合は、`Float`で値を数値に変換してからバリデーションを行おうとします。

WARNING: 上の正規表現では末尾に改行記号があってもマッチします。

```ruby
class Player < ActiveRecord::Base
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

このヘルパーは、`:only_integer`以外にも以下のオプションを使用して制限を指定できます。

* `:greater_than` - 指定された値よりも大きくなければならないことを指定します。デフォルトのエラーメッセージは _"must be greater than %{count}"_ です。
* `:greater_than_or_equal_to` - 指定された値と等しいか、それよりも大きくなければならないことを指定します。デフォルトのエラーメッセージは _"must be greater than or equal to %{count}"_ です。
* `:equal_to` - 指定された値と等しくなければならないことを示します。デフォルトのエラーメッセージは _"must be equal to %{count}"_ です。
* `:less_than` - 指定された値よりも小さくなければならないことを指定します。デフォルトのエラーメッセージは _"must be less than %{count}"_.です。
* `:less_than_or_equal_to` - 指定された値と等しいか、それよりも小さくなければならないことを指定します。デフォルトのエラーメッセージは _"must be less than or equal to %{count}"_ です。
* `:odd` - trueに設定されている場合は、奇数でなければなりません。デフォルトのエラーメッセージは _"must be odd"_ です。
* `:even` - trueに設定されている場合は、偶数でなければなりません。デフォルトのエラーメッセージは _"must be even"_ です。

デフォルトのエラーメッセージは _"is not a number"_ です。

### `presence`

このヘルパーは、指定された属性が空でないことを確認します。値が`nil`や空文字でない(つまり空欄でもなければホワイトスペースでもない)ことを確認するために、内部では`blank?`メソッドを使用しています。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, presence: true
end
```

関連付けが存在することを確認したい場合は、関連付けられたオブジェクト自体が存在することを確認し、そのオブジェクトが関連付けにマッピングされた外部キーでないことを確認する必要があります。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, presence: true
end
```

関連付けられたレコードの存在が必須である場合、これを検証するには`:inverse_of`オプションでその関連付けを指定する必要があります。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

このヘルパーを使用して、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在することを検証すると、`blank?`でもなく`marked_for_destruction?`(削除するためにマークされている)でもないかどうかがチェックされます。

`false.blank?`は常にtrueなので、真偽値に対してこのメソッドを使用すると正しい結果が得られません。真偽値の存在をチェックしたい場合は、`validates :field_name, inclusion: { in: [true, false] }`を使用する必要があります。

デフォルトのエラーメッセージは _"can't be blank"_ です。

### `absence`

このヘルパーは、指定された属性が空であることを検証します。値が`nil`や空文字である (つまり空欄またはホワイトスペースである) かどうかを確認するために、内部では`present?`メソッドを使用しています。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, absence: true
end
```

関連付けが存在しないことを確認したい場合は、関連付けられたオブジェクト自体が存在しないかどうかを確認し、そのオブジェクトが関連付けにマッピングされた外部キーでないことを確認する必要があります。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, absence: true
end
```

関連付けられたレコードが存在してはならない場合、これを検証するには`:inverse_of`オプションでその関連付けを指定する必要があります。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

このヘルパーを使用して、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在しないことを検証すると、`presence?`でもなく`marked_for_destruction?`(削除するためにマークされている)でもないかどうかがチェックされます。

`false.present?`は常にfalseなので、真偽値に対してこのメソッドを使用すると正しい結果が得られません。真偽値が存在しないことをチェックしたい場合は、`validates :field_name, exclusion: { in: [true, false] }`を使用する必要があります。

デフォルトのエラーメッセージは _"must be blank"_ です。

### `uniqueness`

このヘルパーは、オブジェクトが保存される直前に、属性の値が一意であり重複していないことを検証します。このヘルパーはデータベース自体に一意性の制約を作成するわけではないので、2つのデータベース接続がたまたま、一意であってほしいカラムについて同じ値を持つレコードを2つ作成するようなことが起こり得ます。これを避けるには、データベースの両方のカラムに一意インデックスを作成する必要があります。複合インデックスの詳細については[MySQLのマニュアル](http://dev.mysql.com/doc/refman/5.6/en/multiple-column-indexes.html) (英語) を参照してください。

```ruby
class Account < ActiveRecord::Base
  validates :email, uniqueness: true
end
```

このバリデーションは、モデルのテーブルに対して、その属性と同じ値を持つ既存のレコードがあるかどうかを調べるSQLクエリを実行することによって行われます。

このヘルパーには、一意性チェックを制限するために使用される別の属性を指定するための`:scope`オプションがあります。

```ruby
class Holiday < ActiveRecord::Base
  validates :name, uniqueness: { scope: :year,
    message: "発生は年に1度までである必要があります" }
end
```

このヘルパーには`:case_sensitive`というオプションもあります。これは一意性制約で大文字小文字を区別するかどうかを指定します。このオプションはデフォルトでtrueです。

```ruby
class Person < ActiveRecord::Base
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 一部のデータベースでは、大文字小文字を区別しないように設定されていることがあります。

デフォルトのエラーメッセージは _"has already been taken"_ です。

### `validates_with`

このヘルパーは、バリデーション専用の別のクラスにレコードを渡します。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "これは悪人だ"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator
end
```

NOTE: `record.errors[:base]`に追加されるエラーは、概して特定の属性よりもそのレコード全体の状態に関係しているものです。

`validates_with`は、バリデーションに使用する1つのクラス、またはクラスのリストを引数に取ります。`validates_with`にはデフォルトのエラーメッセージはありません。エラーメッセージが必要であれば、バリデータクラスのレコードのエラーコレクションに手動で追加する必要があります。

バリデーションメソッドを実装するには、定義済みの`record`パラメータを持つ必要があります。このパラメータはバリデーションを行なうレコードです。

他のバリデーションと同様、`validates_with`ヘルパーでも`:if`、`:unless`、`:on`オプションを取ることができます。これら以外のオプションを渡すと、バリデータクラスに`options`として渡されます。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any?{|field| record.send(field) == "Evil" }
      record.errors[:base] << "これは悪人だ"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

このバリデータは、アプリケーションのライフサイクル内で *一度しか初期化されない* 点にご注意ください。バリデーションが実行されるたびに初期化されるようなことはありません。インスタンス変数の扱いには十分ご注意ください。

作成したバリデータが複雑になってインスタンス変数を使いたくなった場合は、旧来のRubyオブジェクトを簡単に使うことができます。

```ruby
class Person < ActiveRecord::Base
  validate do |person|
    GoodnessValidator.new(person).validate
  end
end

class GoodnessValidator
  def initialize(person)
    @person = person
  end

  def validate
    if some_complex_condition_involving_ivars_and_private_methods?
      @person.errors[:base] << "これは悪人だ" 
    end
  end

  # ...
end
```

### `validates_each`

このヘルパーは、1つのブロックに対して属性を検証します。定義済みのバリデーション関数はありません。このため、ブロックを使用するバリデーションを自分で作成し、`validates_each`に渡す属性がすべてブロックに対してテストされるようにする必要があります。以下の例では、苗字と名前が小文字で始まらないようにしたいと考えています。

```ruby
class Person < ActiveRecord::Base
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[a-z]/
  end
end
```

このブロックは、レコードと属性の名前、そして属性の値を受け取ります。ブロック内でこれらを使用してデータが正しいかどうかを自由にチェックできます。バリデーションに失敗した場合にはモデルにエラーメッセージを追加し、バリデーションが無効になるようにしてください。

共通のバリデーションオプション
-------------------------

共通のバリデーションオプションを以下に示します。

### `:allow_nil`

`:allow_nil`オプションは、対象の値が`nil`の場合にバリデーションをスキップします。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value}は有効な値ではありません" }, allow_nil: true
end
```

### `:allow_blank`

`:allow_blank`オプションは`:allow_nil`オプションと似ています。このオプションを指定すると、属性の値が`blank?`に該当する場合にバリデーションがパスします。`blank?`に該当する値には`nil`と空文字も含まれます。

```ruby
class Topic < ActiveRecord::Base
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

### `:message`

既に例示したように、`:message`オプションを使用することで、バリデーション失敗時に`errors`コレクションに追加されるカスタムエラーメッセージを指定できます。このオプションを使用しない場合、Active Recordはバリデーションヘルパーのデフォルトのエラーメッセージを使用します。

### `:on`

`:on`オプションは、バリデーション実行のタイミングを指定します。ビルトインのバリデーションヘルパーは、デフォルトでは保存時に実行されます。これはレコードの作成時および更新時のどちらの場合にも行われます。バリデーションのタイミングを変更したい場合、`on: :create`を指定すればレコード新規作成時にのみ検証が行われ、`on: :update`を指定すればレコードの更新時にのみ検証が行われます。

```ruby
class Person < ActiveRecord::Base
  # 値が重複していてもemailを更新できる
  validates :email, uniqueness: true, on: :create

  # 新規レコード作成時に、数字でない年齢表現を使用できる
  validates :age, numericality: true, on: :update

  # デフォルト (作成時と更新時のどちらの場合にもバリデーションを行なう)
  validates :name, presence: true
end
```

厳密なバリデーション
------------------

バリデーションを厳密にし、オブジェクトが無効だった場合に`ActiveModel::StrictValidationFailed`が発生するようにすることができます。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: 名前は空欄にできません
```

カスタムの例外を`:strict`オプションに追加することもできます。

```ruby
class Person < ActiveRecord::Base
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: トークンは空欄にできません
```

条件付きバリデーション
----------------------

特定の条件を満たす場合にのみバリデーションを実行したい場合があります。`:if`オプションや`:unless`オプションを使用することでこのような条件を指定できます。引数にはシンボル、文字列、`Proc`または`Array`を使用できます。`:if`オプションは、特定の条件でバリデーションを行なう **べきである** 場合に使用します。特定の条件ではバリデーションを行なう **べきでない** 場合は、`:unless`オプションを使用します。

### `:if`や`:unless`でシンボルを使用する

バリデーションの実行直前に呼び出されるメソッド名をシンボル名で`:if`や`:unless`オプションに指定することもできます。
これは最も頻繁に使用されるオプションです。

```ruby
class Order < ActiveRecord::Base
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### `:if`や`:unless`で文字列を使用する

文字列を使用することもできます。この文字列は後で`eval`で評価されるため、実行可能な正しいRubyコードを含んでいる必要があります。この方法は、文字列が十分短い場合にのみ使用するのがよいでしょう。

```ruby
class Person < ActiveRecord::Base
  validates :surname, presence: true, if: "name.nil?"
end
```

### `:if`や`:unless`でProcを使用する

呼び出したい`Proc`オブジェクトを`:if`や`:unless`で使用することもできます。`Proc`オブジェクトを使用すると、個別のメソッドを指定する代りに、その場で条件を書くことができるようになります。ワンライナーに収まる条件を使用したい場合に最適です。

```ruby
class Account < ActiveRecord::Base
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

### 条件付きバリデーションをグループ化する

1つの条件を複数のバリデーションで共用できると便利なことがあります。これは`with_options`を使用することで簡単に実現できます。

```ruby
class User < ActiveRecord::Base
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

`with_options`ブロックの内側にあるすべてのバリデーションには、`if: :is_admin?`という条件が渡されます。

### バリデーションの条件を結合する

逆に、バリデーションを行なう条件を複数定義したい場合、`Array`を使用できます。同じバリデーションに対して、`:if`または`:unless`のどちらでも使用できます。

```ruby
class Computer < ActiveRecord::Base
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?]
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

このバリデーションは、`:if`条件がすべて`true`になり、かつ`:unless`が1つも`true`にならない場合にのみ実行されます。

カスタムバリデーションを実行する
-----------------------------

ビルトインのバリデーションヘルパーだけでは不足の場合、好みのバリデータやバリデーションメソッドを作成して使用できます。

### カスタムバリデータ

カスタムバリデータ (validator) は、`ActiveModel::Validator`を拡張したクラスです。これらのクラスでは、`validate`メソッドが実装されている必要があります。このメソッドはレコードを1つ引数に取り、それに対してバリデーションを実行します。カスタムバリデータは`validates_with`メソッドを使用して呼び出します。

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.starts_with? 'X'
      record.errors[:name] << '名前はXで始まる必要があります' 
    end
  end
end

class Person
  include ActiveModel::Validations
  validates_with MyValidator
end
```

個別の属性を検証するためのカスタムバリデータを追加するには、`ActiveModel::EachValidator`を使用するのが最も簡単で便利です。この場合、このカスタムバリデータクラスは`validate_each`メソッドを実装する必要があります。このメソッドは、そのインスタンスに対応する「レコードと属性と値」、バリデーションを行なう属性、そして渡されたインスタンスの属性の値の3つの引数を取ります。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "は正しいメールアドレスではありません")
    end
  end
end

class Person < ActiveRecord::Base
  validates :email, presence: true, email: true
end
```

上の例に示したように、標準のバリデーションとカスタムバリデーションを組み合わせることもできます。

### カスタムメソッド

モデルの状態を確認し、無効な場合に`errors`コレクションにメッセージを追加するメソッドを作成することができます。これらのメソッドを作成後、バリデーションメソッド名を指すシンボルを渡し、`validate`クラスメソッドを使用して登録する必要があります。

1つのクラスメソッドには複数のシンボルを渡すことができます。バリデーションは、登録されたとおりの順序で実行されます。

```ruby
class Invoice < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, ": 過去の日付は使用できません")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "合計額を上回ることはできません")
    end
  end
end
```

これらのバリデーションは、`valid?`を呼び出すたびに実行されます。カスタムバリデーションが実行されるタイミングは、`:on`オプションを使用して変更できます。`validate`に対して`on: :create`または`on: :update`を指定します。

```ruby
class Invoice < ActiveRecord::Base
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

バリデーションエラーに対応する
------------------------------

既に説明した`valid?`メソッドや`invalid?`メソッドの他に、Railsでは`errors`コレクションに対応し、オブジェクトの正当性を検査するためのメソッドが多数用意されています。

以下は最もよく使用されるメソッドの一覧です。利用可能なすべてのメソッドについては、`ActiveModel::Errors`ドキュメントを参照してください。

### `errors`

すべてのエラーを含む`ActiveModel::Errors`クラスのインスタンスを1つ返します。キーは属性名、値はすべてのエラー文字列の配列です。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.messages
# => {:name=>["空欄にはできません", "短すぎます (最小3文字)"]}

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors.messages # => {}
```

### `errors[]`

`errors[]`は、特定の属性についてエラーメッセージをチェックしたい場合に使用します。指定の属性に関するすべてのエラーメッセージの文字列の配列を返します。1つの文字列が1つのエラーメッセージです。属性に関連するエラーがない場合は空の配列を返します。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors[:name] # => []

person = Person.new(name: "JD")
person.valid? # => false
person.errors[:name] # => ["が短すぎます (最小3文字)"]

person = Person.new
person.valid? # => false
person.errors[:name]
# => ["空欄にはできません", "短すぎます (最小3文字)"]
```

### `errors.add`

`add`メソッドを使用して、特定の属性に関連するメッセージを手動で追加できます。`errors.full_messages`メソッドまたは`errors.to_a`メソッドを使用して、ユーザーが実際に見ることのできるフォーム内のメッセージを表示できます。これら特定のメッセージの前には、大文字で始まる属性名が追加されます。`add`メソッドは、メッセージを追加したい属性名、およびメッセージ自身を受け取ります。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors.add(:name, "以下の文字を含むことはできません !@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
# => ["以下の文字を含むことはできません !@#%*()_-+="]

person.errors.full_messages
# => ["Name cannot contain the characters !@#%*()_-+="]
```

`[]=`セッターを使用して同じことを行えます。

```ruby
class Person < ActiveRecord::Base
    def a_method_used_for_validation_purposes
      errors[:name] = "以下の文字を含むことはできません !@#%*()_-+="
    end
  end

  person = Person.create(name: "!@#")

  person.errors[:name]
   # => ["以下の文字を含むことはできません !@#%*()_-+="]

  person.errors.to_a
   # => ["Nameは以下の文字を含むことはできません !@#%*()_-+="]
```

### `errors[:base]`

個別の属性に関連するエラーメッセージを追加する代りに、オブジェクトの状態全体に関連するエラーメッセージを追加することもできます。属性の値がどのようなものであってもオブジェクトが無効であることを通知したい場合にこのメソッドを使用できます。`errors[:base]`は配列なので、これに文字列を単に追加するだけでエラーメッセージとして使用できるようになります。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors[:base] << "この人物は以下の理由で無効です..."
  end
end
```

### `errors.clear`

`clear`メソッドは、`errors`コレクションに含まれるメッセージをすべてクリアしたい場合に使用できます。無効なオブジェクトに対して`errors.clear`メソッドを呼び出しても、それだけでオブジェクトが有効になるわけではありませんのでご注意ください。`errors`は空になりますが、`valid?`やオブジェクトをデータベースに保存しようとするメソッドが次回呼び出されたときに、バリデーションが再実行されます。そしていずれかのバリデーションが失敗すると、`errors`コレクションに再びメッセージが格納されます。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
# => ["空欄にはできません", "短すぎます (最小3文字)"]

person.errors.clear
person.errors.empty? # => true

p.save # => false

p.errors[:name]
# => ["空欄にはできません", "短すぎます (最小3文字)"]
```

### `errors.size`

`size`メソッドは、そのオブジェクトのエラーメッセージの総数を返します。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.size # => 2

person = Person.new(name: "Andrea", email: "andrea@example.com")
person.valid? # => true
person.errors.size # => 0
```

バリデーションエラーをビューで表示する
-------------------------------------

モデルを作成してバリデーションを追加し、Webのフォーム経由でそのモデルが作成できるようになったら、そのモデルでバリデーションが失敗したときにエラーメッセージを表示したくなります。

エラーメッセージの表示方法はアプリケーションごとに異なるため、Railsではこれらのメッセージを直接生成するビューヘルパーは含まれていません。
しかし、Railsでは一般的なバリデーションメソッドが多数提供されているので、カスタムのメソッドを作成するのは比較的簡単です。また、scaffoldを使用して生成を行なうと、そのモデルのエラーメッセージをすべて表示するERBがRailsによって一部の`_form.html.erb`ファイルに追加されます。

`@post`という名前のインスタンス変数に保存されたモデルがあるとすると、以下のようになります。

```ruby
<% if @post.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@post.errors.count, "error") %> はこの投稿の保存を禁止しています:</h2>

    <ul>
    <% @post.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

また、Railsのフォームヘルパーを使用してフォームを生成した場合、あるフィールドでバリデーションエラーが発生すると、そのエントリの周りに追加の`<div>`が自動的に生成されます。

```
<div class="field_with_errors">
<input id="post_title" name="post[title]" size="30" type="text" value="">
</div>
```

このdivタグに好みのスタイルを与えることができます。Railsが生成するデフォルトのscaffoldによって、以下のCSSルールが追加されます。

```
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

このCSSは、エラーを含むフィールドを赤い枠で囲みます。