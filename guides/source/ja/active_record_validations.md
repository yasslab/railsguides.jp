**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Active Record バリデーション
==========================

このガイドでは、Active Recordのバリデーション (検証: validation) 機能を使って、オブジェクトがデータベースに保存される前にオブジェクトの状態を検証する方法について説明します。

このガイドの内容:

* ビルトインのActive Recordバリデーションヘルパーの利用法
* カスタムのバリデーションメソッドの作成
* バリデーションプロセスで生成されたエラーメッセージの取り扱い

-------------------------------------------------------------------------------

バリデーションの概要
---------------------

きわめてシンプルなバリデーションの例を以下に紹介します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

上からわかるように、このバリデーションは`Person`に`name`属性がない場合に無効であることを知らせます。2つ目の`Person`はデータベースに保存されません。

バリデーションの詳細を説明する前に、アプリケーション全体においてバリデーションがいかに重要であるかについて説明します。

### バリデーションを行なう理由

バリデーションは、正しいデータだけをデータベースに保存するために行われます。たとえば、自分のアプリケーションで、すべてのユーザーには必ず電子メールアドレスとメーリングリストアドレスが必要だとします。正しいデータだけをデータベースに保存するのであれば、モデルレベルでバリデーションを実行するのが最適です。モデルレベルでのバリデーションは、データベースに依存せず、エンドユーザーがバイパスすることもできず、テストもメンテナンスもやりやすいためです。Railsではバリデーションを簡単に利用できるよう、一般に利用可能なビルトインヘルパーが用意されており、独自のバリデーションメソッドも作成できるようになっています。

データをデータベースに保存する前にバリデーションを実行する方法は、他にもデータベースネイティブの制約機能、クライアント側でのバリデーション、コントローラレベルのバリデーションなど、さまざまです。それぞれのメリットとデメリットは以下のとおりです。

* 「データベース制約」や「ストアドプロシージャ」を使うと、バリデーションのメカニズムがデータベースに依存してしまい、テストや保守がその分面倒になります。ただし、データベースが (Rails以外の) 他のアプリケーションからも使われるのであれば、データベースレベルである程度のバリデーションを行なっておくのはよい方法です。また、データベースレベルのバリデーションの中には、使用頻度がきわめて高いテーブルの一意性バリデーションなど、他の方法では実装が困難なものもあります。
* 「クライアント側でのバリデーション」は扱いやすく便利ですが、一般に単独では信頼性が不足します。JavaScriptを使ってバリデーションを実装する場合、ユーザーがJavaScriptをオフにしてしまえばバイパスされてしまいます。ただし、他の方法と併用するのであれば、クライアント側でのバリデーションはユーザーに即座にフィードバックを返すための便利な方法となるでしょう。
* 「コントローラレベルのバリデーション」は一度はやってみたくなるものですが、たいてい手に負えなくなり、テストも保守も困難になりがちです。アプリケーションの寿命を永らえ、保守作業を苦痛なものにしないようにするためには、コントローラのコード量は可能な限り減らすべきです。

上で紹介したその他のバリデーションについては、特定の状況に応じて適宜追加してください。Railsチームは、ほとんどの場合モデルレベルのバリデーションが最も適切であると考えています。

### バリデーション実行時の動作

Active Recordのオブジェクトには2つの種類があります。オブジェクトがデータベースの行(row)に対応しているものと、そうでないものです。たとえば、`new`メソッドで新しくオブジェクトを作成しただけでは、オブジェクトはデータベースに属していません。`save`メソッドを呼ぶことで、オブジェクトは適切なデータベースのテーブルに保存されます。Active Recordの`new_record?`インスタンスメソッドを使うと、オブジェクトが既にデータベース上にあるかどうかを確認できます。
次の単純なActive Recordクラスを例に取ってみましょう。

```ruby
class Person < ApplicationRecord
end
```

`rails console`の出力で様子を観察してみます。

```ruby
$ bin/rails console
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

CAUTION: データベース上のオブジェクトの状態を変える方法が多数あることにご注意ください。
メソッドには、バリデーションをトリガするものと、しないものがあります。この点に注意しておかないと、バリデーションが設定されているにもかかわらず、データベース上のオブジェクトが無効な状態になってしまう可能性があります。

以下のメソッドではバリデーションがトリガされ、オブジェクトが有効な場合にのみデータベースに保存されます。

* `create`
* `create!`
* `save`
* `save!`
* `update`
* `update!`

`!`が末尾に付く破壊的メソッド(`save!`など)では、レコードが無効な場合に例外が発生します。
非破壊的なメソッドは、無効な場合に例外を発生しません。`save`と`update`は無効な場合に`false`を返し、`create`は無効な場合に単にそのオブジェクトを返します。

### バリデーションのスキップ

以下のメソッドはバリデーションを行わずにスキップします。オブジェクトの保存は、有効無効にかかわらず行われます。これらのメソッドの利用には注意が必要です。

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

実は、`save`に`validate: false`を引数として与えると、`save`のバリデーションをスキップできてしまいます。この手法は十分注意して使う必要があります。

* `save(validate: false)`

### `valid?`と`invalid?`

Railsは、Active Recordオブジェクトを保存する直前にバリデーションを実行します。バリデーションで何らかのエラーが発生すると、オブジェクトを保存しません。

`valid?`メソッドを使って、バリデーションを手動でトリガすることもできます。`valid?`を実行するとバリデーションがトリガされ、オブジェクトにエラーがない場合は`true`が返され、そうでなければ`false`が返されます。
これは以下のように実装できます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Recordでバリデーションが行われた後は、`errors.messages`インスタンスメソッドを使うと、発生したエラーにアクセスできます。このメソッドはエラーのコレクションを返します。
定義上は、バリデーション実行後にコレクションが空になった場合は有効です。

ただし、`new`でインスタンス化されたオブジェクトは、それが厳密には無効であってもエラーは出力されないので、注意が必要です。これは、`create`や`save`メソッドなどによってオブジェクトが保存されるときのみ、バリデーションが自動的に実行されるためです。

```ruby
class Person < ApplicationRecord
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

`invalid?`は単なる`valid?`と逆のチェックです。このメソッドはバリデーションをトリガし、オブジェクトでエラーが発生した場合は`true`を、そうでなければ`false`を返します。

### `errors[]`

`errors[:attribute]`を使うと、特定のオブジェクトの属性が有効かどうかを確認できます。このメソッドは、`:attribute`のすべてのエラーの配列を返します。指定された属性でエラーが発生しなかった場合は、空の配列が返されます。

このメソッドが便利なのは、バリデーションを実行した後だけです。このメソッドはエラーのコレクションを調べるだけで、バリデーションそのものをトリガしないからです。このメソッドは、前述の`ActiveRecord::Base#invalid?`メソッドとは異なります。このメソッドはオブジェクト全体の正当性については確認しないためです。オブジェクトの個別の属性についてエラーがあるかどうかだけを調べます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

より高レベルなバリデーションエラーについては、[バリデーションエラーの取り扱い](#バリデーションエラーに対応する)セクションを参照してください。

### `errors.details`

 無効(invalid)な属性において、どのバリデーションが失敗したのか調べるのに`errors.details[:attribute]`が利用できます。これは`:error`がキーで、失敗したバリデーターのシンボルが値となるハッシュの配列を返します。
 
 ```ruby
 class Person < ApplicationRecord
 validates :name, presence: true
 end
 
 >> person = Person.new
 >> person.valid?
 >> person.errors.details[:name] # => [{error: :blank}]
 ```
 
カスタムバリデータで`details`を使う方法については、[バリデーションエラーの取り扱い](#バリデーションエラーに対応する)セクションを参照してください。

バリデーションヘルパー
------------------

Active Recordには、クラス定義の内側で直接使える定義済みのバリデーションヘルパーが多数用意されています。これらのヘルパーは、共通のバリデーションルールを提供します。バリデーションが失敗するたびに、オブジェクトの`errors`コレクションにエラーメッセージが追加され、そのメッセージは、バリデーションが行われる属性に関連付けられます。

どのヘルパーも任意の数の属性を受け付けることができるので、1行のコードを書くだけで多くの属性に対して同じバリデーションを実行できます。

`:on`オプションと`:message`オプションはどのヘルパーでも使えます。`:on`オプションはバリデーションを実行するタイミングを指定し、`:message`オプションバリデーション失敗時に`errors`コレクションに追加するメッセージを指定します。`:on`オプションは`:create`または`:update`のいずれかの値を取ります。バリデーションヘルパーには、それぞれデフォルトのエラーメッセージが用意されています。`:message`オプションが使われていない場合はデフォルトのメッセージが使われます。利用可能なヘルパーを1つずつ見ていきましょう。

### `acceptance`

このメソッドは、フォームが送信されたときにユーザーインターフェイス上のチェックボックスがオンになっているかどうかを検証します。ユーザーによるサービス利用条項への同意が必要な場合や、ユーザーが何らかの文書に目を通したことを確認させる場合によく使われます。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: true
end
```

このチェックは、`terms_of_service`が`nil`でない場合にのみ実行されます。
このヘルパーのデフォルトエラーメッセージは「must be accepted」です。
次のようにカスタムメッセージを`message`オプションで渡すこともできます。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { message: 'must be abided' }
end
```

このヘルパーでは`:accept`オプションも渡せます。このオプションは、「同意済み（accepted）」とみなす値を指定します。デフォルトは"1"ですが、変更は簡単です。

```ruby
class Person < ApplicationRecord
  validates :eula, acceptance: { accept: ['TRUE', 'accepted'] }
end
```

この`acceptance`はWebアプリケーション特有のバリデーションであり、データベースに保存する必要はありません。保存用の`acceptance`フィールドがなければ、単にヘルパーが仮想の属性を作成してくれます。データベースに`acceptance`フィールドがある場合は、`accept`オプションを設定するか`true`を指定しなければならず、それ以外の場合はバリデーションが実行されません。

### `validates_associated`

このヘルパーは、モデルが他のモデルに関連付けられていて、両方のモデルに対してバリデーションを実行する必要がある場合に使います。オブジェクトを保存しようとすると、関連付けられているオブジェクトごとに`valid?`が呼び出されます。

```ruby
class Library < ApplicationRecord
  has_many :books
  validates_associated :books
end
```

このバリデーションは、あらゆる種類の関連付けに対して利用できます。

CAUTION: `validates_associated`を関連付けの両側のオブジェクトで実行しないでください。
関連付けの両側でこのヘルパーを使うと無限ループになります。

`validates_associated`のデフォルトエラーメッセージは「is invalid」です。関連付けられたオブジェクトにも自分の`errors`コレクションが含まれるので、エラーは呼び出し元のモデルに伝わりません。

### `confirmation`

このヘルパーは、2つのテキストフィールドで受け取る内容が完全に一致する必要がある場合に使います。たとえば、メールアドレスやパスワードで、確認フィールドを使うとします。このバリデーションヘルパーは仮想の属性を作成します。属性の名前は、確認したい属性名に「_confirmation」を追加したものになります。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
end
```

ビューテンプレートで以下のようなフィールドを用意します。

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

このチェックは、`email_confirmation`が`nil`でない場合のみ行われます。確認を必須にするには、確認用の属性について存在チェックも追加してください。`presence`を利用する存在チェックについてはこの後解説します。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

`:case_sensitive`オプションを用いて、大文字小文字の違いを確認する制約をかけるかどうかも定義できます。デフォルトでは、このオプションは`true`になります。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: { case_sensitive: false }
end
```

このヘルパーのデフォルトメッセージは「doesn't match confirmation」です。

### `exclusion`

このヘルパーは、与えられた集合に属性の値が「含まれていない」ことを検証します。集合には任意のenumerableオブジェクトが使えます。

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value}は予約済みです" }
end
```

`exclusion`ヘルパーの`:in`オプションには、バリデーションを行った属性の値に含めたくない値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使えます。上の例では、`:message`オプションを使って属性の値を含める方法を示しています。`message`引数の完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。


デフォルトのエラーメッセージは「is reserved」です。

### `format`

このヘルパーは、`with`オプションで与えられた正規表現と属性の値がマッチするかどうかのテストによる検証を行います。

```ruby
class Product < ApplicationRecord
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "英文字のみが使えます" }
end
```

または、`:without`オプションを用いて指定の属性が正規表現に一致**しない**ことを必須にすることもできます。

デフォルトのエラーメッセージは「is invalid」です。

### `inclusion`

このヘルパーは、与えられた集合に属性の値が含まれているかどうかを検証します。集合には任意のenumerableオブジェクトが使えます。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
message: "%{value} のサイズは無効です" }
end
```

`inclusion`ヘルパーには`:in`オプションがあり、受け付ける値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使えます。上の例では、属性の値をインクルードする方法を示すために`:message`オプションも使っています。完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。

このヘルパーのデフォルトのエラーメッセージは「is not included in the list」です。

### `length`

このヘルパーは、属性の値の長さを検証します。多くのオプションがあり、さまざまな長さ制限を指定できます。

```ruby
class Person < ApplicationRecord
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

使用可能な長さ制限オプションは以下のとおりです。

* `:minimum`: 属性はこの値より小さな値を取れません。
* `:maximum`: 属性はこの値より大きな値を取れません。
* `:in`または`:within`: 属性の長さは、与えられた区間以内でなければなりません。このオプションの値は範囲でなければなりません。
* `:is`: 属性の長さは与えられた値と等しくなければなりません。

デフォルトのエラーメッセージは、実行されるバリデーションの種類によって異なります。デフォルトのメッセージは`:wrong_length`、`:too_long`、`:too_short`オプションを使ってカスタマイズすることも、`%{count}`を長さ制限に対応する数値のプレースホルダにも使えます。`:message`オプションを使ってエラーメッセージを指定することもできます。

```ruby
class Person < ApplicationRecord
  validates :bio, length: { maximum: 1000,
    too_long: "最大%{count}文字まで使えます" }
end
```

デフォルトのエラーメッセージは複数形で表現されていることにご注意ください (例: "is too short (minimum is %{count} characters)")。このため、`:minimum`を1に設定するのであればメッセージをカスタマイズして単数形にするか、代りに`presence: true`を使います。`:in`または`:within`の下限に1を指定する場合、メッセージをカスタマイズして単数形にするか、`length`より先に`presence`を呼ぶようにします。

### `numericality`

このヘルパーは、属性に数値のみが使われていることを検証します。デフォルトでは、整数または浮動小数点にマッチします。これらの冒頭に符号がある場合もマッチします。整数のみにマッチさせたい場合は、`:only_integer`を`true`にします。

`:only_integer`を`true`に設定すると、属性の値に対するバリデーションで以下の正規表現が使われます。

```ruby
/\A[+-]?\d+\z/
```

それ以外の場合は、値を`Float`で数値に変換しようとします。

```ruby
class Player < ApplicationRecord
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

このヘルパーは、`:only_integer`以外にも以下のオプションで制約を指定できます。

* `:greater_than`: 指定された値よりも大きくなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than %{count}」です。
* `:greater_than_or_equal_to`: 指定された値と等しいか、それよりも大きくなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than or equal to %{count}」です。
* `:equal_to`: 指定された値と等しくなければならないことを示します。デフォルトのエラーメッセージは「must be equal to %{count}」です。
* `:less_than`: 指定された値よりも小さくなければならないことを指定します。デフォルトのエラーメッセージは「must be less than %{count}」です。
* `:less_than_or_equal_to`: 指定された値と等しいか、それよりも小さくなければならないことを指定します。デフォルトのエラーメッセージは「must be less than or equal to %{count}」です。
* `:other_than`: 渡した値以外の値でなければならないことを指定します。デフォルトのエラーメッセージは「must be other than %{count}」です。
* `:odd`: `true`の場合は奇数でなければなりません。デフォルトのエラーメッセージは「must be odd」です。
* `:even`: `true`の場合は偶数でなければなりません。デフォルトのエラーメッセージは「must be even」です。

NOTE: デフォルトでは、`numericality`の`nil`値は許容されません。`allow_nil: true`オプションで`nil`値を許可できます。

デフォルトのエラーメッセージは「is not a number」です。

### `presence`

このヘルパーは、指定された属性が「空でない」ことを確認します。値が`nil`や空文字でない(つまり空欄でもなければホワイトスペースでもない)ことを確認するために、内部で`blank?`メソッドを使っています。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, presence: true
end
```

関連付けが存在することを確認したい場合は、関連付けられたオブジェクト自体が存在することを確認し、そのオブジェクトが関連付けにマッピングされた外部キーでないことを確認する必要があります。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order
  validates :order, presence: true
end
```

関連付けられたレコードの存在が必須の場合、これを検証するには`:inverse_of`オプションでその関連付けを指定する必要があります。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

このヘルパーを使って、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在することを検証すると、`blank?`でもなく`marked_for_destruction?`(削除用マーク済み)でもないかどうかがチェックされます。

`false.blank?`は常に`true`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値の存在をチェックしたい場合は、`validates :field_name, inclusion: { in: [true, false] }`を使う必要があります。

```ruby
validates :boolean_field_name, inclusion: { in: [true, false] }
validates :boolean_field_name, exclusion: { in: [nil] }
```

これらのバリデーションのいずれかを使うことで、値が**決して**`nil`にならないようにできます。`nil`があると、ほとんどの場合`NULL`値になります。

### `absence`

このヘルパーは、指定された属性が「空」であることを検証します。値が`nil`や空文字である (つまり空欄またはホワイトスペースである) かどうかを確認するために、内部では`present?`メソッドを使っています。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, absence: true
end
```

関連付けが存在しないことを確認したい場合は、関連付けられたオブジェクト自体が存在しないかどうかを確認し、そのオブジェクトが関連付けにマッピングされた外部キーでないことを確認する必要があります。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order
  validates :order, absence: true
end
```

関連付けられたレコードが存在してはならない場合、これを検証するには`:inverse_of`オプションでその関連付けを指定する必要があります。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

このヘルパーを使って、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在しないことを検証すると、`presence?`でもなく`marked_for_destruction?`(削除するためにマークされている)でもないかどうかがチェックされます。

`false.present?`は常に`false`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値が存在しないことをチェックしたい場合は、`validates :field_name, exclusion: { in: [true, false] }`を使う必要があります。

デフォルトのエラーメッセージは「must be blank」です。

### `uniqueness`

このヘルパーは、オブジェクトが保存される直前に、属性の値が一意（unique）であり重複していないことを検証します。このヘルパーは一意性の制約をデータベース自体には作成しないので、本来一意にすべきカラムに、たまたま2つのデータベース接続によって同じ値を持つレコードが2つ作成される可能性が残ります。これを避けるには、データベースの両方のカラムに一意インデックスを作成する必要があります。

```ruby
class Account < ApplicationRecord
  validates :email, uniqueness: true
end
```

このバリデーションは、その属性と同じ値を持つ既存のレコードがモデルのテーブルにあるかどうかを調べるSQLクエリを実行することで行われます。

このヘルパーには、一意性チェックの範囲を限定する別の属性を指定する`:scope`オプションがあります。

```ruby
class Holiday < ApplicationRecord
  validates :name, uniqueness: { scope: :year,
    message: "発生は年に1度までである必要があります" }
end
```

`:scope`を用いる一意性バリデーションの違反を防止する目的でデータベース側に制約を作成したい場合は、データベース側で両方のカラムにuniqueインデックスを作成しなければなりません。[MySQLのマニュアル](https://dev.mysql.com/doc/refman/5.6/ja/multiple-column-indexes.html)でマルチカラムインデックスについての情報を参照するか、[PostgreSQLのマニュアル](https://www.postgresql.jp/document/current/html/ddl-constraints.html)でカラムのグループを参照する一意性制約についての例を参照してください。

このヘルパーには`:case_sensitive`というオプションもあります。これは一意性制約で大文字小文字を区別するかどうかを指定します。このオプションはデフォルトでtrueです。

```ruby
class Person < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 一部のデータベースでは大文字小文字を区別しない設定になっていることがあります。

デフォルトのエラーメッセージは「has already been taken」です。

### `validates_with`

このヘルパーは、バリデーション専用の別クラスにレコードを渡します。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "これは悪人だ"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator
end
```

NOTE: `record.errors[:base]`には、特定の属性よりもそのレコード全体の状態に関連するエラーメッセージを追加するのが普通です。

`validates_with`は、バリデーションに使う1つのクラス（またはクラスのリスト）を引数に取ります。`validates_with`にはデフォルトのエラーメッセージはありません。エラーメッセージが必要な場合は、バリデータクラスのレコードのエラーコレクションに手動で追加する必要があります。

バリデーションメソッドを実装するには、定義済みの`record`パラメータが必要です。このパラメータはバリデーションを行なうレコードを表します。

他のバリデーションと同様、`validates_with`ヘルパーでも`:if`、`:unless`、`:on`オプションが使えます。その他のオプションは、バリデータクラスに`options`として渡されます。


```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any?{|field| record.send(field) == "Evil" }
      record.errors[:base] << "これは悪人だ"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

このバリデータは、アプリケーションのライフサイクル内で**一度しか初期化されない**点にご注意ください。バリデーションが実行されるたびに初期化されることはありません。インスタンス変数の扱いには十分ご注意ください。

作成したバリデータが複雑になってインスタンス変数を使いたくなった場合は、代わりに素のRubyオブジェクトを使うこともできます。

```ruby
class Person < ApplicationRecord
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

このヘルパーは、1つのブロックに対して属性を検証します。定義済みのバリデーション関数はありません。このため、ブロックを使うバリデーションを自分で作成し、`validates_each`に渡す属性がすべてブロックに対してテストされるようにする必要があります。以下の例では、苗字と名前が小文字で始まらないようにしたいと考えています。

```ruby
class Person < ApplicationRecord
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[a-z]/
  end
end
```

このブロックは、レコードと属性の名前、そして属性の値を受け取ります。ブロック内でこれらを使ってデータが正しいかどうかを自由にチェックできます。バリデーションに失敗した場合にはモデルにエラーメッセージを追加し、バリデーションが無効になるようにしてください。

共通のバリデーションオプション
-------------------------

共通で使えるバリデーションオプションを以下に示します。

### `:allow_nil`

`:allow_nil`オプションは、対象の値が`nil`の場合にバリデーションをスキップします。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value}は有効な値ではありません" }, allow_nil: true
end
```

`message:`引数の完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。

### `:allow_blank`

`:allow_blank`オプションは`:allow_nil`オプションと似ています。このオプションを指定すると、属性の値が`blank?`に該当する場合（`nil`や空文字など）にバリデーションがパスします。

```ruby
class Topic < ApplicationRecord
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

### `:message`

既に例示したように、`:message`オプションを使うことで、バリデーション失敗時に`errors`コレクションに追加されるカスタムエラーメッセージを指定できます。このオプションを使わない場合、Active Recordはバリデーションヘルパーごとにデフォルトのエラーメッセージを使います。`:message`オプションは`String`か`Proc`を受け取ります。

`String`の`:message`値には、`%{value}`や`%{attribute}`や`%{model}`をオプションで含められます。これらはバリデーション失敗時に動的に置き換えられます。置き換えにはI18n gemが用いられており、プレースホルダーはこのとおりでなければならず、スペース文字を含めることはできません。

`Proc`の`:message`値には引数が2つ与えられます。バリデーションの対象となるオブジェクトと、`:model`と`:attribute`と`:value`のキー/値ペアを含むハッシュです。

```ruby
class Person < ApplicationRecord
  # メッセージを直書きした場合
  validates :name, presence: { message: "must be given please" }

  # 動的な属性値を含むメッセージの場合。%{value}は実際の属性値に
  # 置き換えられる。%{attribute}や%{model}も利用可能。
  validates :age, numericality: { message: "%{value} seems wrong" }

  # Procの場合
  validates :username,
    uniqueness: {
      # object = バリデーションされる人物のオブジェクト
      # data = { model: "Person", attribute: "Username", value: <username> }
      message: ->(object, data) do
        "Hey #{object.name}!, #{data[:value]} is taken already! Try again #{Time.zone.tomorrow}"
      end
    }
end
```

### `:on`

`:on`オプションは、バリデーション実行のタイミングを指定します。ビルトインのバリデーションヘルパーは、デフォルトでは保存時（レコードの作成時および更新時の両方）に実行されます。バリデーションのタイミングを変更したい場合、`on: :create`を指定すればレコード新規作成時にのみ検証が行われ、`on: :update`を指定すればレコードの更新時にのみ検証が行われます。

```ruby
class Person < ApplicationRecord
  # 値が重複していてもemailを更新できる
  validates :email, uniqueness: true, on: :create

  # 新規レコード作成時に、数字でない年齢表現を使える
  validates :age, numericality: true, on: :update

  # デフォルト (作成時と更新時の両方でバリデーションを行なう)
  validates :name, presence: true
end
```

`on:`ではカスタムコンテキストも定義できます。カスタムコンテキストは、`valid?`や`invalid?`や`save`に`context: コンテキスト名`を渡して明示的にトリガーする必要があります。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
end

person = Person.new(age: 'thirty-three')
person.valid? # => true
person.valid?(:account_setup) # => false
person.errors.messages
# => {:email=>["has already been taken"], :age=>["is not a number"]}
```

`person.valid?(:account_setup)`は、モデルを保存せずにバリデーションを2つとも実行します。`person.save(context: :account_setup)`は、`account_setup`コンテキストで`person`をバリデーションしてから保存します。

明示的なトリガーによるモデルのバリデーションでは、そのコンテキストのみのバリデーションと、コンテキストなしのバリデーションが行われます。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
  validates :name, presence: true
end

person = Person.new
person.valid?(:account_setup) # => false
person.errors.messages
 # => {:email=>["has already been taken"], :age=>["is not a number"], :name=>["can't be blank"]}
```

厳密なバリデーション
------------------

バリデーションを厳密にし、オブジェクトが無効だった場合に`ActiveModel::StrictValidationFailed`が発生するようにすることもできます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: Name can't be blank
```

カスタム例外を`:strict`オプションに追加することもできます。

```ruby
class Person < ApplicationRecord
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: トークンは空欄にできません
```

条件付きバリデーション
----------------------

特定の条件を満たす場合にのみバリデーションを実行したい場合があります。`:if`オプションや`:unless`オプションを使うことでこのような条件を指定できます。引数にはシンボル、`Proc`または`Array`を使えます。`:if`オプションは、特定の条件でバリデーションを行なう**べきである**場合に使います。特定の条件でバリデーションを行なう**べきでない**場合は、`:unless`オプションを使います。

### `:if`や`:unless`でシンボルを使う

バリデーションの実行直前に呼び出されるメソッド名をシンボルで`:if`や`:unless`オプションに指定することもできます。
これは最も頻繁に使われるオプションです。

```ruby
class Order < ApplicationRecord
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### `:if`や`:unless`で`Proc`を使う

呼び出したい`Proc`オブジェクトを`:if`や`:unless`で使うこともできます。`Proc`オブジェクトを使うと、個別のメソッドを指定する代りに、その場で条件を書けるようになります。ワンライナーに収まる条件を使いたい場合に最適です。

```ruby
class Account < ApplicationRecord
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

`Lambdas`は`Proc`の一種なので、これもインライン条件に短く書けます。

```ruby
validates :password, confirmation: true, unless: -> { password.blank? }
```

### 条件付きバリデーションをグループ化する

1つの条件を複数のバリデーションで共用できると便利なことがあります。これは`with_options`を使うことで簡単に実現できます。

```ruby
class User < ApplicationRecord
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

`with_options`ブロックの内側にあるすべてのバリデーションには、`if: :is_admin?`という条件が渡されます。

### バリデーションの条件を組み合わせる

逆に、バリデーションを行なう条件を複数定義したい場合、`Array`を使えます。さらに、1つのバリデーションに`:if`と`:unless`を両方使うこともできます。

```ruby
class Computer < ApplicationRecord
  validates :mouse, presence: true,
                    if: [Proc.new  { |c| c.market.retail? }, :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

このバリデーションは、`:if`条件がすべて`true`で、かつ`:unless`が1つも`true`にならない場合にのみ実行されます。

カスタムバリデーションを実行する
-----------------------------

ビルトインのバリデーションヘルパーだけでは不足の場合、好みのバリデータやバリデーションメソッドを作成して使えます。

### カスタムバリデータ

カスタムバリデータ (validator) は、`ActiveModel::Validator`を継承するクラスです。これらのクラスでは、`validate`メソッドを実装する必要があります。このメソッドはレコードを1つ引数に取り、それに対してバリデーションを実行します。カスタムバリデータは`validates_with`メソッドを使って呼び出します。

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

個別の属性を検証するためのカスタムバリデータを追加するには、`ActiveModel::EachValidator`を使用するのが最も簡単で便利です。この場合、このカスタムバリデータクラスは`validate_each`メソッドを実装する必要があります。このメソッドは、そのインスタンスに対応するレコード、バリデーションを行う属性、そして渡されたインスタンスの属性の値の3つの引数を取ります。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "はメールアドレスではありません")
    end
  end
end

class Person < ApplicationRecord
  validates :email, presence: true, email: true
end
```

上の例に示したように、標準のバリデーションとカスタムバリデーションを組み合わせることもできます。

### カスタムメソッド

モデルの状態を確認し、無効な場合に`errors`コレクションにメッセージを追加するメソッドを作成できます。これらのメソッドを作成後、バリデーションメソッド名を指すシンボルを渡し、`validate`クラスメソッドを使って登録する必要があります。

1つのクラスメソッドには複数のシンボルを渡せます。バリデーションは登録されたとおりの順序で実行されます。

`valid?`メソッドは`errors`コレクションが空であることを検証するので、カスタムバリデーションはバリデーションが失敗したときにエラーを追加すべきです。

```ruby
class Invoice < ApplicationRecord
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, ": 過去の日付は使えません")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "合計額を上回ることはできません")
    end
  end
end
```

これらのバリデーションは、デフォルトでは`valid?`を呼び出すかオブジェクトを保存するたびに実行されます。しかし`:on`オプションを使えば、カスタムバリデーションが実行されるタイミングを変更できます。`validate`に対して`on: :create`または`on: :update`を指定します。

```ruby
class Invoice < ApplicationRecord
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

バリデーションエラーに対応する
------------------------------

既に説明した`valid?`メソッドや`invalid?`メソッドの他に、Railsでは`errors`コレクションに対応し、オブジェクトの正当性を検査するメソッドが多数用意されています。

以下は最もよく使われるメソッドの一覧です。利用可能なすべてのメソッドについては、`ActiveModel::Errors`ドキュメントを参照してください。

### `errors`

すべてのエラーを含む`ActiveModel::Errors`クラスのインスタンスを1つ返します。キーは属性名、値はすべてのエラー文字列の配列です。

```ruby
class Person < ApplicationRecord
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

`errors[]`は、特定の属性についてエラーメッセージをチェックしたい場合に使います。指定の属性に関するすべてのエラーメッセージの文字列の配列を返します。1つの文字列が1つのエラーメッセージに対応します。属性に関連するエラーがない場合は空の配列を返します。

```ruby
class Person < ApplicationRecord
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

`add`メソッドを使って、特定の属性に関連するエラーメッセージを手動で追加できます。このメソッドは属性とエラーメッセージを引数として受け取ります。

`errors.full_messages`（または同等の`errors.to_a`）メソッドは、エラーメッセージをユーザーが読みやすい形式で返します。以下のように、メッセージごとに頭が大文字の属性名を冒頭に追加します。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.add(:name, "は以下の文字を含むことができません !@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
# => ["は以下の文字を含むことができません !@#%*()_-+="]

person.errors.full_messages
# => ["Name は以下の文字を含むことができません !@#%*()_-+="]
```

### `errors.details`

`errors.add`メソッドを使って、返されたエラーの`details`ハッシュにバリデータの種類を指定できます。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.add(:name, :invalid_characters)
  end
end

person = Person.create(name: "!@#")

person.errors.details[:name]
# => [{error: :invalid_characters}]
```

たとえば、使ってはならない文字セットをエラーの`details`に追加するには、`errors.add`で追加のキーを渡します。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.add(:name, :invalid_characters, not_allowed: "!@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors.details[:name]
# => [{error: :invalid_characters, not_allowed: "!@#%*()_-+="}]
```

対応するバリデータの種類を持つ`details`ハッシュは、すべての組み込みRailsバリデータに含まれます。

### `errors[:base]`

個別の属性に関連するエラーメッセージを追加する代りに、オブジェクトの状態全体に関連するエラーメッセージを追加することもできます。このメソッドは、属性がどんな値であってもオブジェクトが無効であることを通知したい場合に使えます。`errors[:base]`は配列なので、これに文字列を単に追加するだけでエラーメッセージとして使えるようになります。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors[:base] << "この人物は以下の理由で無効です..."
  end
end
```

### `errors.clear`

`clear`メソッドは、`errors`コレクションに含まれるメッセージをすべてクリアしたい場合に使えます。無効なオブジェクトに対して`errors.clear`メソッドを呼び出しても、それだけでオブジェクトが有効になるわけではありませんのでご注意ください。`errors`は空になりますが、`valid?`やオブジェクトをデータベースに保存しようとするメソッドが次回呼び出されたときに、バリデーションが再実行されます。そしていずれかのバリデーションが失敗すると、`errors`コレクションに再びメッセージが格納されます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
# => ["空欄にはできません", "短すぎます (最小3文字)"]

person.errors.clear
person.errors.empty? # => true

person.save # => false

person.errors[:name]
# => ["空欄にはできません", "短すぎます (最小3文字)"]
```

### `errors.size`

`size`メソッドは、そのオブジェクトのエラーメッセージの総数を返します。

```ruby
class Person < ApplicationRecord
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

エラーメッセージの表示方法はアプリケーションごとに異なるため、そうしたメッセージを直接生成するビューヘルパーはRailsに含まれていません。
しかし、Railsでは一般的なバリデーションメソッドが多数提供されているので、カスタムのメソッドを作成するのは比較的簡単です。また、生成をscaffoldで行なうと、そのモデルのエラーメッセージをすべて表示するERBがRailsによって一部の`_form.html.erb`ファイルに追加されます。

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

また、フォームをRailsのフォームヘルパーで生成した場合、あるフィールドでバリデーションエラーが発生すると、そのエントリの周りに追加の`<div>`が自動的に生成されます。

```
<div class="field_with_errors">
<input id="post_title" name="post[title]" size="30" type="text" value="">
</div>
```

この`<div>`タグに好みのスタイルを追加できます。Railsが生成するデフォルトのscaffoldによって、以下のCSSルールが追加されます。

```
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

このCSSは、エラーを含むフィールドを赤い枠で囲みます。
