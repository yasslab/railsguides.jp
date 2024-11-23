Active Record バリデーション
==========================

このガイドでは、Active Recordのバリデーション（検証: validation）機能を使って、オブジェクトがデータベースに保存される前にオブジェクトの状態を検証する方法について説明します。

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
```

```irb
irb> Person.create(name: "John Doe").valid?
=> true
irb> Person.create(name: nil).valid?
=> false
```

上でわかるように、このバリデーションは`Person`に`name`属性がない場合に無効であることを知らせます。2つ目の`Person`はデータベースに保存されません。

バリデーションの詳細を説明する前に、アプリケーション全体においてバリデーションがいかに重要であるかについて説明します。

### バリデーションを行なう理由

バリデーションは、正しいデータだけをデータベースに保存するために行われます。たとえば、自分のアプリケーションで、すべてのユーザーには必ず電子メールアドレスと住所が必要だとします。正しいデータだけをデータベースに保存するのであれば、モデルレベルでバリデーションを実行するのが最適です。モデルレベルでのバリデーションは、データベースに依存せず、エンドユーザーがバイパスすることもできず、テストもメンテナンスもやりやすいためです。Railsではバリデーションを簡単に利用できるよう、一般に利用可能なビルトインヘルパーが用意されており、独自のバリデーションメソッドも作成できるようになっています。

データをデータベースに保存する前にバリデーションを実行する方法は、他にもデータベースネイティブの制約機能、クライアント側でのバリデーション、コントローラレベルのバリデーションなど、さまざまです。それぞれのメリットとデメリットは以下のとおりです。

* 「データベース制約」や「ストアドプロシージャ」を使うと、バリデーションのメカニズムがデータベースに依存してしまい、テストや保守がその分面倒になります。ただし、データベースが（Rails以外の）他のアプリケーションからも使われるのであれば、データベースレベルである程度のバリデーションを行なっておくのはよい方法です。また、データベースレベルのバリデーションの中には、利用頻度がきわめて高いテーブルの一意性バリデーションなど、他の方法では実装が困難なものもあります。
* 「クライアント側でのバリデーション」は扱いやすく便利ですが、一般に単独では信頼性が不足します。JavaScriptを使ってバリデーションを実装する場合、ユーザーがJavaScriptをオフにするとバイパスされてしまいます。ただし、他の方法と併用するのであれば、クライアント側でのバリデーションはユーザーに即座にフィードバックを返すための便利な方法となるでしょう。
* 「コントローラレベルのバリデーション」は一度はやってみたくなるものですが、たいてい手に負えなくなり、テストも保守も困難になりがちです。アプリケーションの寿命をのばし、保守作業を苦痛なものにしないためには、コントローラのコード量は可能な限り減らすべきです。

上で紹介したその他のバリデーションについては、特定の状況に応じて適宜追加してください。Railsチームは、ほとんどの場合モデルレベルのバリデーションが最も適切であると考えています。

### バリデーション実行時の動作

Active Recordのオブジェクトには2つの種類があります。オブジェクトがデータベースの行（row）に対応しているものと、そうでないものです。たとえば、`new`メソッドで新しくオブジェクトを作成しただけでは、オブジェクトはデータベースに属していません。`save`メソッドを呼ぶことで、オブジェクトは適切なデータベースのテーブルに保存されます。Active Recordの`new_record?`インスタンスメソッドを使うと、オブジェクトが既にデータベース上にあるかどうかを確認できます。
次の単純なActive Recordクラスを例に取ってみましょう。

```ruby
class Person < ApplicationRecord
end
```

`bin/rails console`の出力で様子を観察してみます。

```irb
irb> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>

irb> p.new_record?
=> true

irb> p.save
=> true

irb> p.new_record?
=> false
```

新規レコードを作成して保存すると、SQLの`INSERT`操作がデータベースに送信されます。既存のレコードを更新すると、SQLの`UPDATE`操作が送信されます。バリデーションは、SQLのデータベースへの送信前に行うのが普通です。バリデーションのいずれかが失敗すると、オブジェクトは無効（invalid）とマークされ、Active Recordでの`INSERT`や`UPDATE`操作は行われません。これにより、無効なオブジェクトがデータベースに保存されないようにします。オブジェクトの作成、保存、更新時に特定のバリデーションを実行することもできます。

CAUTION: データベース上のオブジェクトの状態を変える方法が多数あることにご注意ください。
メソッドには、バリデーションをトリガするものと、しないものがあります。この点に注意しておかないと、バリデーションが設定されているにもかかわらず、データベース上のオブジェクトが無効な状態になってしまう可能性があります。

以下のメソッドではバリデーションがトリガされ、オブジェクトが有効な場合にのみデータベースに保存されます。

* [`create`][]
* [`create!`][]
* [`save`][]
* [`save!`][]
* [`update`][]
* [`update!`][]

`!`が末尾に付く破壊的メソッド（`save!`など）では、レコードが無効な場合に例外が発生します。
非破壊的なメソッドは、無効な場合に例外を発生しません。`save`と`update`は無効な場合に`false`を返し、`create`は無効な場合に単にそのオブジェクトを返します。

[`create`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-create
[`create!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-create-21
[`save`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save
[`save!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save-21
[`update`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update
[`update!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update-21

### バリデーションのスキップ

以下のメソッドはバリデーションを行わずにスキップします。オブジェクトの保存は、有効無効にかかわらず行われます。これらのメソッドの利用には注意が必要です。詳しくは個別のAPIドキュメントを参照してください。

* [`decrement!`][]
* [`decrement_counter`][]
* [`increment!`][]
* [`increment_counter`][]
* [`insert`][]
* [`insert!`][]
* [`insert_all`][]
* [`insert_all!`][]
* [`toggle!`][]
* [`touch`][]
* [`touch_all`][]
* [`update_all`][]
* [`update_attribute`][]
* [`update_attribute!`][]
* [`update_column`][]
* [`update_columns`][]
* [`update_counters`][]
* [`upsert`][]
* [`upsert_all`][]

実は、`save`に`validate: false`を引数として与えると、`save`のバリデーションをスキップすることが可能です。この手法は十分注意して使う必要があります。

* `save(validate: false)`

[`decrement!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-decrement-21
[`decrement_counter`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-decrement_counter
[`increment!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-increment-21
[`increment_counter`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-increment_counter
[`insert`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert
[`insert!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert-21
[`insert_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all
[`insert_all!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all-21
[`toggle!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-toggle-21
[`touch`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-touch
[`touch_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-touch_all
[`update_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_all
[`update_attribute`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_attribute
[`update_attribute!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_attribute-21
[`update_column`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_column
[`update_columns`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_columns
[`update_counters`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_counters
[`upsert`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert
[`upsert_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all

### `valid?`と`invalid?`

Railsは、Active Recordオブジェクトを保存する直前にバリデーションを実行します。バリデーションで何らかのエラーが発生すると、オブジェクトを保存しません。

[`valid?`][]メソッドを使って、バリデーションを手動でトリガすることもできます。`valid?`を実行するとバリデーションがトリガされ、オブジェクトにエラーがない場合は`true`を返し、エラーの場合は`false`を返します。
これは以下のように実装できます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> Person.create(name: "John Doe").valid?
=> true
irb> Person.create(name: nil).valid?
=> false
```

Active Recordでバリデーションが行われた後で[`errors`][]インスタンスメソッドを使うと、失敗したバリデーションにアクセスできます。このメソッドはエラーのコレクションを返します。
その名の通り、バリデーション実行後にコレクションが空である場合はオブジェクトは有効です。

ただし、`new`でインスタンス化されたオブジェクトは、それが厳密には無効であってもエラーは出力されないので、注意が必要です。これは、`create`や`save`メソッドなどによってオブジェクトが保存されるときのみ、バリデーションが自動的に実行されるためです。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> p = Person.new
=> #<Person id: nil, name: nil>
irb> p.errors.size
=> 0

irb> p.valid?
=> false
irb> p.errors.objects.first.full_message
=> "Name can't be blank"

irb> p = Person.create
=> #<Person id: nil, name: nil>
irb> p.errors.objects.first.full_message
=> "Name can't be blank"

irb> p.save
=> false

irb> p.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

irb> Person.create!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

[`invalid?`][]は`valid?`と逆のチェックを行います。このメソッドはバリデーションをトリガし、オブジェクトでエラーが発生した場合は`true`を返し、エラーがない場合は`false`を返します。

[`errors`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-errors
[`invalid?`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-invalid-3F
[`valid?`]: https://api.rubyonrails.org/classes/ActiveRecord/Validations.html#method-i-valid-3F

### `errors[]`

[`errors[:attribute]`][Errors#squarebrackets]を使うと、特定のオブジェクトの属性が有効かどうかを確認できます。このメソッドは、`:attribute`のすべてのエラーの配列を返します。指定された属性でエラーが発生しなかった場合は、空の配列が返されます。

このメソッドが役に立つのは、バリデーションを実行した**後**だけです。このメソッドはエラーのコレクションを調べるだけで、バリデーションそのものをトリガしないからです。このメソッドは、前述の`ActiveRecord::Base#invalid?`メソッドとは異なります。このメソッドはオブジェクト全体の正当性については確認せず、オブジェクトの個別の属性についてエラーがあるかどうかだけを調べます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> Person.new.errors[:name].any?
=> false
irb> Person.create.errors[:name].any?
=> true
```

より高レベルなバリデーションエラーについては、[バリデーションエラーの取り扱い](#バリデーションエラーに対応する)セクションを参照してください。

[Errors#squarebrackets]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-5B-5D

バリデーションヘルパー
------------------

Active Recordには、クラス定義の内側で直接使える定義済みのバリデーションヘルパーが多数用意されています。これらのヘルパーは、共通のバリデーションルールを提供します。バリデーションが失敗するたびに、オブジェクトの`errors`コレクションにエラーメッセージが追加され、そのメッセージは、バリデーションが行われる属性に関連付けられます。

どのヘルパーも任意の数の属性を受け付けることができるので、1行のコードを書くだけで多くの属性に対して同じバリデーションを実行できます。

`:on`オプションと`:message`オプションはどのヘルパーでも使えます。`:on`オプションはバリデーションを実行するタイミングを指定し、`:message`オプションはバリデーション失敗時に`errors`コレクションに追加するメッセージを指定します。`:on`オプションは`:create`または`:update`のいずれかの値を取ります。バリデーションヘルパーには、それぞれデフォルトのエラーメッセージが用意されています。`:message`オプションが使われていない場合はデフォルトのメッセージが使われます。利用可能なヘルパーを1つずつ見ていきましょう。

INFO: 利用可能なデフォルトヘルパーのリストについては、[`ActiveModel::Validations::HelperMethods`][]を参照してください。

[`ActiveModel::Validations::HelperMethods`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html

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
  validates :terms_of_service, acceptance: { message: "must be abided" }
end
```

このヘルパーでは`:accept`オプションも渡せます。このオプションは、「同意可能（acceptable）」とみなす値を指定します。デフォルトは`['1', true]`ですが、変更は簡単です。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { accept: "yes" }
  validates :eula, acceptance: { accept: ["TRUE", "accepted"] }
end
```

これはWebアプリケーション特有のバリデーションであり、データベースに保存する必要はありません。これに対応するフィールドがなくても、単にヘルパーが仮想の属性を作成してくれます。このフィールドがデータベースに存在すると、`accept`オプションを設定するか`true`を指定しなければならず、そうでない場合はバリデーションが実行されなくなります。

### `confirmation`

このヘルパーは、2つのテキストフィールドで受け取る内容が完全に一致する必要がある場合に使います。たとえば、メールアドレスやパスワードで、確認フィールドを使うとします。このバリデーションヘルパーは仮想の属性を作成します。属性の名前は、確認したい属性名に「`_confirmation`」を追加したものになります。

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

NOTE: このチェックは、`email_confirmation`が`nil`でない場合のみ行われます。確認を必須にするには、以下のように確認用の属性について存在チェックも追加してください。`presence`を利用する存在チェックについては[この後](#presence)解説します。

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
`message`オプションでカスタムメッセージを渡すことも可能です。

このバリデーターを使う場合は、`:if`オプションと組み合わせて、レコードを保存するたびに「`_confirmation`」フィールドをバリデーションするのではなく、初期フィールドが変更されたときのみバリデーションするのが一般的です。詳しくは[条件付きバリデーション](#条件付きバリデーション)で後述します。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true, if: :email_changed?
end
```

### `comparison`

このチェックは、比較可能な2つの値の比較を検証します。

```ruby
class Promotion < ApplicationRecord
  validates :end_date, comparison: { greater_than: :start_date }
end
```

このヘルパーのデフォルトのエラーメッセージは**"failed comparison"**です。
`message`オプションでカスタムメッセージを渡すことも可能です。

サポートされているオプションは以下のとおりです。

* `:greater_than`: 渡された値よりも大きい値でなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than %{count}」です。
* `:greater_than_or_equal_to`: 渡された値と等しいか、それよりも大きい値でなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than or equal to %{count}」です。
* `:equal_to`: 渡された値と等しくなければならないことを指定します。デフォルトのエラーメッセージは「must be equal to %{count}」です。
* `:less_than`: 渡された値よりも小さい値でなければならないことを指定します。デフォルトのエラーメッセージは「must be less than %{count}」です。
* `:less_than_or_equal_to`: 渡された値と等しいか、それよりも小さい値でなければならないことを指定します。デフォルトのエラーメッセージは「must be less than or equal to %{count}」です。
* `:other_than`: 渡された値と異なる値でなければならないことを指定します。デフォルトのエラーメッセージは「must be other than %{count}」です。

### `format`

このヘルパーは、`with`オプションで与えられた正規表現と属性の値がマッチするかどうかを検証します。

```ruby
class Product < ApplicationRecord
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "英文字のみが使えます" }
end
```

逆に、`:without`オプションを使うと、指定の属性が正規表現に**マッチしない**ことを要求できます。

どちらの場合も、指定する`:with`や`:without`オプションは、正規表現か、正規表現を返すprocまたはlambdaでなければなりません。

デフォルトのエラーメッセージは「is invalid」です。

WARNING: **文字列**の冒頭や末尾にマッチさせるためには`A`と`\z`を使い、`^`と`$`は、**1行**の冒頭や末尾にマッチさせる場合に使うこと。`A`や`\z`を使うべき場合に`^`や`$`を使う誤用が頻発しているため、`^`や`$`を使う場合は`multiline: true`オプションを渡す必要があります。ほとんどの場合、必要なのは`\A`と`\z`です。

### `inclusion`

このヘルパーは、指定の集合に属性の値が含まれているかどうかを検証します。集合には任意のenumerableオブジェクトが使えます。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
message: "%{value} のサイズは無効です" }
end
```

`inclusion`ヘルパーには`:in`オプションがあり、受け付ける値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使えます。上の例では、属性の値をインクルードする方法を示すために`:message`オプションも使っています。完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。

このヘルパーのデフォルトのエラーメッセージは「is not included in the list」です。

### `exclusion`

`inclusion`の逆は、`exclusion`です！

このヘルパーは、指定の集合に属性の値が「含まれていない」ことをバリデーションします。集合には任意のenumerableオブジェクトが使えます。

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value}は予約済みです" }
end
```

`exclusion`ヘルパーの`:in`オプションには、バリデーションを行った属性の値に含めたくない値の集合を指定します。`:in`オプションには`:within`というエイリアスもあり、好みに応じてどちらでも使えます。上の例では、`:message`オプションを使って属性の値を含める方法を示しています。`message`引数の完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。

デフォルトのエラーメッセージは「is reserved」です。

または、伝統的なenumerable（`Array`など）の代わりに、enumerableを返すproc、lambda、またはシンボルを指定することも可能です。
このバリデーションは、enumerableが数値や時間や日付の「範囲」である場合は`Range#cover?`で行われ、それ以外の場合は`include?`で行われます。procやlambdaを使う場合は、そのインスタンスがバリデーション時に引数として渡されます。

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

利用できる長さ制限オプションは以下のとおりです。

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

デフォルトのエラーメッセージは英語が複数形で表現されていることにご注意ください（例: "is too short (minimum is %{count} characters)"）。このため、`:minimum`を1に設定するのであれば、メッセージをカスタマイズして単数形にするか、代わりに`presence: true`を使います。`:in`または`:within`の下限に1を指定する場合、メッセージをカスタマイズして単数形にするか、`length`より先に`presence`を呼ぶようにします。

NOTE: 制約オプションは一度に1つしか利用できませんが、`:minimum`と`:maximum`オプションは組み合わせて使えます。

### `numericality`

このヘルパーは、属性に数値のみが使われていることをバリデーションします。デフォルトでは、整数値または浮動小数点数値にマッチします。これらの冒頭に符号がある場合もマッチします。

値として整数のみを許すことを指定するには、`:only_integer`を`true`に設定します。これにより、属性の値に対するバリデーションで以下の正規表現が使われます。

```ruby
/\A[+-]?\d+\z/
```

それ以外の場合は、`Float`を用いる数値への変換を試みます。`Float`は、カラムの精度または最大15桁を用いて`BigDecimal`にキャストされます。

```ruby
class Player < ApplicationRecord
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

`:only_integer`のデフォルトのエラーメッセージは「must be an integer」です。

このヘルパーには、`:only_integer`の他に`:only_numeric`オプションも渡せます。これは、値が`Numeric`のインスタンスでなければならないことを指定し、値が`String`の場合は値の解析を試みます。

NOTE: デフォルトでは、`numericality`オプションで`nil`値は許容されません。`nil`値を許可するには`allow_nil: true`オプションを使ってください。`Integer`カラムや`Float`カラムでは、空の文字列が`nil`に変換される点にご注意ください。

オプションが指定されていない場合のデフォルトのエラーメッセージは「is not a number」です。

このヘルパーでは、`:only_integer`以外にも以下のオプションで値の制約を指定できます。

* `:greater_than`: 指定の値よりも大きくなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than %{count}」です。
* `:greater_than_or_equal_to`: 指定の値と等しいか、それよりも大きくなければならないことを指定します。デフォルトのエラーメッセージは「must be greater than or equal to %{count}」です。
* `:equal_to`: 指定の値と等しくなければならないことを示します。デフォルトのエラーメッセージは「must be equal to %{count}」です。
* `:less_than`: 指定の値よりも小さくなければならないことを指定します。デフォルトのエラーメッセージは「must be less than %{count}」です。
* `:less_than_or_equal_to`: 指定の値と等しいか、それよりも小さくなければならないことを指定します。デフォルトのエラーメッセージは「must be less than or equal to %{count}」です。
* `:other_than`: 指定の値以外の値でなければならないことを指定します。デフォルトのエラーメッセージは「must be other than %{count}」です。
* `:in`: 渡された範囲に値が含まれていなければならないことを指定します。デフォルトのエラーメッセージは「must be in %{count}」です。
* `:odd`: `true`の場合は奇数でなければなりません。デフォルトのエラーメッセージは「must be odd」です。
* `:even`: `true`の場合は偶数でなければなりません。デフォルトのエラーメッセージは「must be even」です。

### `presence`

このヘルパーは、指定された属性が空（empty）でないことを確認します。値が`nil`や空文字でない、つまり空でもなければ[ホワイトスペース](https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9#%E3%82%B3%E3%83%B3%E3%83%94%E3%83%A5%E3%83%BC%E3%82%BF%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9)でもないことを確認するために、内部で[`Object#blank?`][]メソッドを使っています。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, presence: true
end
```

関連付けが存在することを確認したい場合、関連をマッピングするために使われる外部キーではなく、関連するオブジェクト自体が存在するかどうかをバリデーションする必要があります。以下の例では、外部キーが空ではないことと、関連付けられたオブジェクトが存在することをチェックしています。

```ruby
class Supplier < ApplicationRecord
  has_one :account
  validates :account, presence: true
end
```

複数の関連付けられたオブジェクトが存在することを検証したい場合は、`:inverse_of`オプションを指定してください。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

NOTE: 関連付けが存在し、かつ有効であることを確認したい場合は、`validates_associated`も使う必要があります。詳しくは[後述します](#validates-associated)。

このヘルパーを使って、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在することを検証すると、`blank?`でもなく`marked_for_destruction?`（削除用マーク済み）でもないかどうかがチェックされます。

`false.blank?`は常に`true`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値の存在をチェックしたい場合は、以下のいずれかを使う必要があります。

```ruby
# 値はtrueかfalseでなければならない
validates :boolean_field_name, inclusion: [true, false]
# 値はnilであってはならない、すなわちtrueかfalseでなければならない
validates :boolean_field_name, exclusion: [nil]
```

これらのバリデーションのいずれかを使うことで、値が**決して**`nil`にならないようにできます。`nil`があると、ほとんどの場合`NULL`値になります。

デフォルトのエラーメッセージは「can't be blank」です。

[`Object#blank?`]: https://api.rubyonrails.org/classes/Object.html#method-i-blank-3F

### `absence`

このヘルパーは、指定された属性が空（empty）であることを検証します。値が`nil`または空文字である、つまり空または[ホワイトスペース](https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9#%E3%82%B3%E3%83%B3%E3%83%94%E3%83%A5%E3%83%BC%E3%82%BF%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9)であることを確認するために、内部で[`Object#present?`][]メソッドを使っています。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, absence: true
end
```

関連付けが存在しないことを確認したい場合、関連をマッピングするのに使われる外部キーではなく、関連するオブジェクト自体が存在しないかどうかを検証する必要があります。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order
  validates :order, absence: true
end
```

複数の関連付けられたオブジェクトが存在しないことを検証したい場合は、`:inverse_of`オプションを指定してください。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

NOTE: 関連付けが存在し、かつ有効であることを確認したい場合は、`validates_associated`も使う必要があります。詳しくは[後述します](#validates-associated)。

このヘルパーを使って、`has_one`または`has_many`リレーションシップを経由して関連付けられたオブジェクトが存在しないことを検証すると、`presence?`でもなく`marked_for_destruction?`（削除用マーク済み）でもないかどうかがチェックされます。

`false.present?`は常に`false`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値が存在しないことをチェックしたい場合は、`validates :field_name, exclusion: { in: [true, false] }`を使う必要があります。

デフォルトのエラーメッセージは「must be blank」です。

[`Object#present?`]: https://api.rubyonrails.org/classes/Object.html#method-i-present-3F

### `uniqueness`

このヘルパーは、オブジェクトが保存される直前に、属性の値が一意（unique）であり重複していないことを検証します。

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
    message: "発生は年に1度である必要があります" }
end
```

WARNING: このバリデーションはデータベースに一意性制約（uniqueness constraint）を作成しないので、異なる2つのデータベース接続で、一意であることを意図したカラムに同じ値を持つレコードが2つ作成される可能性があります。これを避けるには、データベースでそのカラムにuniqueインデックスを作成する必要があります。

データベースに一意性データベース制約を追加するには、マイグレーションで[`add_index`][]ステートメントを使って`unique: true`オプションを指定します。

`:scope`を用いる一意性バリデーション違反を防止する目的でデータベース側に制約を作成したい場合は、データベース側で両方のカラムにuniqueインデックスを作成しなければなりません。[MySQLのマニュアル][]や[MariaDBのマニュアル][]でマルチカラムインデックスについての情報を参照するか、[PostgreSQLのマニュアル][]などでカラムのグループを参照する一意性制約についての例を参照してください。

このヘルパーには`:case_sensitive`というオプションもあります。これは一意性制約で大文字小文字を区別するか、またはデータベースのデフォルトの照合順序（collation）を尊重すべきかどうかを定義できます。このオプションはデフォルトで、データベースのデフォルト照合順序を尊重します。

```ruby
class Person < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 一部のデータベースでは検索で常に大文字小文字を区別しない設定になっているものがあります。

`:conditions`オプションを使うと、一意性制約の探索を制限するための追加条件をSQLの`WHERE`フラグメントとして指定可能です（例: `conditions: -> { where(status: 'active') }`）。

デフォルトのエラーメッセージは「has already been taken」です。

[`validates_uniqueness_of`]: https://api.rubyonrails.org/classes/ActiveRecord/Validations/ClassMethods.html#method-i-validates_uniqueness_of
[`add_index`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index
[MySQLのマニュアル]: https://dev.mysql.com/doc/refman/8.0/ja/multiple-column-indexes.html
[MariaDBのマニュアル]: https://mariadb.com/kb/en/compound-composite-indexes/
[PostgreSQLのマニュアル]: https://www.postgresql.jp/document/current/html/ddl-constraints.html

### `validates_associated`

常に有効でなければならない関連付けがモデルにある場合は、このヘルパーを使う必要があります。オブジェクトを保存しようとするたびに、関連するオブジェクトごとに`valid?`が呼び出されます。

```ruby
class Library < ApplicationRecord
  has_many :books
  validates_associated :books
end
```

このバリデーションは、すべての種類の関連付けで機能します。

CAUTION: `validates_associated`を関連付けの両側で使ってはいけません。互いを呼び出して無限ループになります。

[`validates_associated`][]のデフォルトのエラーメッセージは「is invalid」です。各関連付けオブジェクトには、それ自身の`errors`コレクションも含まれることに注意してください。エラーは呼び出し元のモデルには達しません。

NOTE: [`validates_associated`][]はActive Recordオブジェクトでしか利用できませんが、従来のバリデーションは[`ActiveModel::Validations`][]を含む任意のオブジェクトでも利用できます。

[`validates_associated`]: https://api.rubyonrails.org/classes/ActiveRecord/Validations/ClassMethods.html#method-i-validates_associated

### `validates_each`

このヘルパーは、ブロックに対して属性をバリデーションします。このヘルパーは、事前定義されたバリデーション関数を持っていません。ブロックで作成されて[`validates_each`][]に渡されたすべての属性は、そのブロックに対してテストされます。

以下の例は、小文字で始まる名前と姓を却下します。

```ruby
class Person < ApplicationRecord
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, "大文字で始まる必要があります") if /\A[[:lower:]]/.match?(value)
  end
end
```

このブロックは、レコード、属性名、属性の値を受け取ります。

ブロック内のデータが有効かどうかのチェックには任意のコードを書けます。バリデーションに失敗した場合は、モデルにエラーを追加して無効とする必要があります。

[`validates_each`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_each

### `validates_with`

このヘルパーは、バリデーション専用の別クラスにレコードを渡します。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors.add :base, "これは悪人だ"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator
end
```

`validates_with`にはデフォルトのエラーメッセージがありません。バリデータークラスのレコードのエラーコレクションに、手動でエラーを追加する必要があります。

NOTE: `record.errors[:base]`には、そのレコード全体のステートに関連するエラーメッセージを追加するのが一般的です。

バリデーションメソッドを実装するには、メソッド定義内に`record`パラメータが必要です。このパラメータはバリデーションを行なうレコードを表します。

特定の属性に関するエラーを追加したい場合は、`record.errors.add(:first_name, "please choose another name")`のように第1引数にその属性を渡します。詳しくは[バリデーションエラー](#バリデーションエラーに対応する)で後述します。

```ruby
def validate(record)
  if record.some_field != "acceptable"
    record.errors.add :some_field, "this field is unacceptable"
  end
end
```

[`validates_with`][]ヘルパーは、バリデーションに使うクラス（またはクラスのリスト）を引数に取ります。

```ruby
class Person < ApplicationRecord
  validates_with MyValidator, MyOtherValidator, on: :create
end
```

他のバリデーションと同様、`validates_with`ヘルパーでも`:if`、`:unless`、`:on`オプションが使えます。その他のオプションは、バリデータクラスに`options`として渡されます。


```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any? { |field| record.send(field) == "Evil" }
      record.errors.add :base, "これは悪人だ"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

このバリデータは、アプリケーションのライフサイクル内で**一度しか初期化されない**点にご注意ください。バリデーションが実行されるたびに初期化されることはありません。インスタンス変数を使う場合は十分な注意が必要です。

作成したバリデータが複雑になってインスタンス変数を使いたくなった場合は、代わりに素のRubyオブジェクトを使う方がやりやすいでしょう。

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
      @person.errors.add :base, "これは悪人だ"
    end
  end

  # ...
end
```

詳しくは[カスタムバリデーション](#カスタムバリデーションを実行する)で後述します。

[`validates_with`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_with

バリデーションの共通オプション
-------------------------

これまで見てきたバリデータにはさまざまな共通オプションがあるので、そのいくつかを以下に示します。

NOTE: これらのオプションは、すべてのバリデータでサポートされているとは限りません。詳しくは[`ActiveModel::Validations`][]のAPIドキュメントを参照してください。

上述のバリデーションの方法を使う場合、バリデータ間で共通して使えるオプションのリストも存在します。

* [`:allow_nil`](#allow-nil): 属性が`nil`の場合にバリデーションをスキップする。
* [`:allow_blank`](#allow-blank): 属性がblankの場合にバリデーションをスキップする。
* [`:message`](#message): カスタムのエラーメッセージを指定する。
* [`:on`](#on): このバリデーションを有効にするコンテキストを指定する。
* [`:strict`](#厳密なバリデーション): バリデーション失敗時にraiseする。
* [`:if`と`:unless`](#条件付きバリデーション): バリデーションする場合やしない場合の条件を指定する。

[`ActiveModel::Validations`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html

### `:allow_nil`

`:allow_nil`オプションは、対象の値が`nil`の場合にバリデーションをスキップします。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value}は有効な値ではありません" }, allow_nil: true
end
```

```irb
irb> Coffee.create(size: nil).valid?
=> true
irb> Coffee.create(size: "mega").valid?
=> false
```

`message:`引数の完全なオプションについては、[`:message`のドキュメント](#message)を参照してください。

### `:allow_blank`

`:allow_blank`オプションは`:allow_nil`オプションと似ています。このオプションを指定すると、属性の値が`blank?`に該当する場合（`nil`や空文字列など）にバリデーションがパスします。

```ruby
class Topic < ApplicationRecord
  validates :title, length: { is: 5 }, allow_blank: true
end
```

```irb
irb> Topic.create(title: "").valid?
=> true
irb> Topic.create(title: nil).valid?
=> true
```

### `:message`

既に例示したように、`:message`オプションを使うことで、バリデーション失敗時に`errors`コレクションに追加されるカスタムエラーメッセージを指定できます。このオプションを使わない場合、Active Recordはバリデーションヘルパーごとにデフォルトのエラーメッセージを使います。

`:message`オプションは`String`または`Proc`を値として受け取ります。

`String`の`:message`値には、`%{value}`や`%{attribute}`や`%{model}`をオプションで含められます。これらはバリデーション失敗時に動的に置き換えられます。置き換えはi18n gemで行われます。プレースホルダは正確にマッチしなければならず、スペースは許されません。

```ruby
class Person < ApplicationRecord
  # メッセージを直書きする場合
  validates :name, presence: { message: "省略できません" }

  # 動的な属性値を含むメッセージの場合。%{value}は実際の属性値に
  # 置き換えられる。%{attribute}や%{model}も利用可能。
  validates :age, numericality: { message: "%{value}は誤りかもしれません" }
end
```

`Proc`の`:message`値は引数を2つ受け取ります。バリデーションの対象となるオブジェクトと、`:model`と`:attribute`と`:value`のキーバリューペアを含むハッシュです。

```ruby
class Person < ApplicationRecord
  validates :username,
    uniqueness: {
      # object = バリデーションされる人物のオブジェクト
      # data = { model: "Person", attribute: "Username", value: <username> }
      message: ->(object, data) do
        "#{object.name}さま、#{data[:value]}は既に入力済みです"
      end
    }
end
```

### `:on`

`:on`オプションは、バリデーション実行のタイミングを指定します。ビルトインのバリデーションヘルパーは、デフォルトでは保存時（レコードの作成時および更新時の両方）に実行されます。バリデーションのタイミングを変更したい場合、`on: :create`を指定すればレコード新規作成時にのみバリデーションが行われ、`on: :update`を指定すればレコードの更新時にのみバリデーションが行われます。

```ruby
class Person < ApplicationRecord
  # 値が重複していてもemailを更新できる
  validates :email, uniqueness: true, on: :create

  # 新規レコード作成時に、数字でない年齢表現を使える
  validates :age, numericality: true, on: :update

  # デフォルト（作成時と更新時の両方でバリデーションを行なう）
  validates :name, presence: true
end
```

`on:`にはカスタムコンテキストも定義できます。カスタムコンテキストは、`valid?`や`invalid?`や`save`にコンテキスト名を渡して明示的にトリガーする必要があります。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
end
```

```irb
irb> person = Person.new(age: 'thirty-three')
irb> person.valid?
=> true
irb> person.valid?(:account_setup)
=> false
irb> person.errors.messages
=> {:email=>["has already been taken"], :age=>["is not a number"]}
```

`person.valid?(:account_setup)`は、モデルを保存せずにバリデーションを2つとも実行します。`person.save(context: :account_setup)`は、保存の前に`account_setup`コンテキストで`person`をバリデーションします。

以下のようにシンボルの配列も渡せます。

```ruby
class Book
  include ActiveModel::Validations

  validates :title, presence: true, on: [:update, :ensure_title]
end
```

```irb
irb> book = Book.new(title: nil)
irb> book.valid?
=> true
irb> book.valid?(:ensure_title)
=> false
irb> book.errors.messages
=> {:title=>["can't be blank"]}
```

明示的なトリガーによるモデルのバリデーションでは、そのコンテキストのみのバリデーションと、「コンテキストなし」のバリデーションが行われます。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
  validates :name, presence: true
end
```

```irb
irb> person = Person.new
irb> person.valid?(:account_setup)
=> false
irb> person.errors.messages
=> {:email=>["has already been taken"], :age=>["is not a number"], :name=>["can't be blank"]}
```

`on:`のユースケースについて詳しくは、[コールバックガイド](active_record_callbacks.html)で解説します。

厳密なバリデーション
------------------

バリデーションを厳密にし、オブジェクトが無効だった場合に`ActiveModel::StrictValidationFailed`が発生するようにすることもできます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: { strict: true }
end
```

```irb
irb> Person.new.valid?
ActiveModel::StrictValidationFailed: Name can't be blank
```

カスタム例外を`:strict`オプションに追加することもできます。

```ruby
class Person < ApplicationRecord
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end
```

```irb
irb> Person.new.valid?
TokenGenerationException: Token can't be blank
```

条件付きバリデーション
----------------------

特定の条件を満たす場合にのみバリデーションを実行したい場合があります。`:if`オプションや`:unless`オプションを使うことでこのような条件を指定できます。引数にはシンボル、`Proc`または`Array`を使えます。`:if`オプションは、特定の条件でバリデーションを行なう**べきである**場合に使います。特定の条件でバリデーションを行なう**べきでない**場合は、`:unless`オプションを使います。

### `:if`や`:unless`でシンボルを使う

バリデーションの実行直前に呼び出されるメソッド名を、`:if`や`:unless`オプションにシンボルで指定することもできます。
これは最もよく使われるオプションです。

```ruby
class Order < ApplicationRecord
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### `:if`や`:unless`で`Proc`を使う

呼び出したい`Proc`オブジェクトを`:if`や`:unless`で使うこともできます。`Proc`オブジェクトを使うと、個別のメソッドを指定する代わりに、その場で条件を書けるようになります。ワンライナーに収まる条件を使いたい場合に最適です。

```ruby
class Account < ApplicationRecord
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

lambdaは`Proc`の一種なので、lambda記法（`-> `）を用いて以下のようにインライン条件をさらに短く書くこともできます。

```ruby
validates :password, confirmation: true, unless: -> { password.blank? }
```

### 条件付きバリデーションをグループ化する

1つの条件を複数のバリデーションで共用できると便利なことがあります。これは[`with_options`][]で簡単に実現できます。

```ruby
class User < ApplicationRecord
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

`with_options`ブロックの内側にあるすべてのバリデーションに`if: :is_admin?`という条件が渡されます。

[`with_options`]: https://api.rubyonrails.org/classes/Object.html#method-i-with_options

### バリデーションの条件を組み合わせる

逆に、バリデーションを行なう条件を複数定義したい場合は`Array`を使えます。さらに、1つのバリデーションに`:if`と`:unless`を両方使うこともできます。

```ruby
class Computer < ApplicationRecord
  validates :mouse, presence: true,
                    if: [Proc.new { |c| c.market.retail? }, :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

このバリデーションは、`:if`条件がすべて`true`で、かつ`:unless`が1つも`true`にならない場合にのみ実行されます。

カスタムバリデーションを実行する
-----------------------------

ビルトインのバリデーションヘルパーだけでは不足の場合、好みのバリデータやバリデーションメソッドを作成して使えます。

### カスタムバリデータ

カスタムバリデータは、[`ActiveModel::Validator`][]を継承するクラスです。
これらのクラスでは、`validate`メソッドを実装する必要があります。このメソッドはレコードを1つ引数に取り、それに対してバリデーションを実行します。カスタムバリデータは`validates_with`メソッドで呼び出します。

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.start_with? "X"
      record.errors.add :name, "名前はXで始まる必要があります"
    end
  end
end

class Person
  validates_with MyValidator
end
```

個別の属性を検証するためのカスタムバリデータを追加するには、[`ActiveModel::EachValidator`][]を使うのが最も手軽で便利です。この場合、このカスタムバリデータクラスは`validate_each`メソッドを実装する必要があります。このメソッドは、そのインスタンスに対応するレコード、バリデーションを行う属性、そして渡されたインスタンスの属性の値の3つの引数を取ります。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless URI::MailTo::EMAIL_REGEXP.match?(value)
      record.errors.add attribute, (options[:message] || "はメールアドレスではありません")
    end
  end
end

class Person < ApplicationRecord
  validates :email, presence: true, email: true
end
```

上の例に示したように、標準のバリデーションとカスタムバリデーションを組み合わせることもできます。

[`ActiveModel::EachValidator`]: https://api.rubyonrails.org/classes/ActiveModel/EachValidator.html
[`ActiveModel::Validator`]: https://api.rubyonrails.org/classes/ActiveModel/Validator.html

### カスタムメソッド

モデルのステートを確認して、無効な場合に`errors`コレクションにメッセージを追加するメソッドを作成できます。これらのメソッドを作成後、[`validate`][]クラスメソッドを使って登録し、バリデーションメソッド名を指すシンボルを渡す必要があります。

クラスメソッドごとに複数のシンボルを渡せます。バリデーションは登録されたとおりの順序で実行されます。

`valid?`メソッドは`errors`コレクションが空であることを検証するので、カスタムバリデーションはバリデーションが失敗したときにエラーを追加すべきです。

```ruby
class Invoice < ApplicationRecord
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, "過去の日付は使えません")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "合計額を上回ることはできません")
    end
  end
end
```

これらのバリデーションは、デフォルトでは`valid?`を呼び出したりオブジェクトを保存したりするたびに実行されます。しかし`:on`オプションを使えば、カスタムバリデーションが実行されるタイミングを変更できます。`validate`に対して`on: :create`または`on: :update`を指定します。

```ruby
class Invoice < ApplicationRecord
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "はアクティブではありません") unless customer.active?
  end
end
```

[`:on`](#on)について詳しくは上述のセクションを参照してください。

### バリデータを一覧表示する

指定したオブジェクトのバリデータをすべて調べたい場合は、`validators`を調べるだけで十分です。

たとえば、カスタムバリデータとビルトインバリデータを使った次のようなモデルがあるとします。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, on: :create
  validates :email, format: URI::MailTo::EMAIL_REGEXP
  validates_with MyOtherValidator, strict: true
end
```

これで、以下のように`validators`でPersonモデルのすべてのバリデータを一覧表示することも、`validators_on`で特定のフィールドをチェックすることも可能になります。

```irb
irb> Person.validators
#=> [#<ActiveRecord::Validations::PresenceValidator:0x10b2f2158
      @attributes=[:name], @options={:on=>:create}>,
     #<MyOtherValidatorValidator:0x10b2f17d0
      @attributes=[:name], @options={:strict=>true}>,
     #<ActiveModel::Validations::FormatValidator:0x10b2f0f10
      @attributes=[:email],
      @options={:with=>URI::MailTo::EMAIL_REGEXP}>]
     #<MyOtherValidator:0x10b2f0948 @options={:strict=>true}>]

irb> Person.validators_on(:name)
#=> [#<ActiveModel::Validations::PresenceValidator:0x10b2f2158
      @attributes=[:name], @options={on: :create}>]
```

[`validate`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validate

バリデーションエラーに対応する
------------------------------

[`valid?`][]メソッドや[`invalid?`][]メソッドでは、有効かどうかという概要しかわかりません。しかし[`errors`][]コレクションにあるさまざまなメソッドを使えば、個別のエラーをさらに詳しく調べられます。

以下は最もよく使われるメソッドの一覧です。利用可能なすべてのメソッドについては、[`ActiveModel::Errors`][]ドキュメントを参照してください。

[`ActiveModel::Errors`]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html

### `errors`

個別のエラーのさまざまな詳細を調べるときの入り口となります。

すべてのエラーを含む`ActiveModel::Error`クラスのインスタンスを1つ返します。個別のエラーは、[`ActiveModel::Error`][]オブジェクトによって表現されます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.full_messages
=> ["名前は空欄にできません", "名前が短すぎます（最小で3文字以上）"]

irb> person = Person.new(name: "John Doe")
irb> person.valid?
=> true
irb> person.errors.full_messages
=> []


irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.first.details
=> {:error=>:too_short, :count=>3}
```

[`ActiveModel::Error`]: https://api.rubyonrails.org/classes/ActiveModel/Error.html

### `errors[]`

[`errors[]`][Errors#squarebrackets]は、特定の属性についてエラーメッセージをチェックしたい場合に使います。指定の属性に関するすべてのエラーメッセージの文字列の配列を返します（1つの文字列に1つのエラーメッセージが対応します）。属性に関連するエラーがない場合は空の配列を返します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new(name: "John Doe")
irb> person.valid?
=> true
irb> person.errors[:name]
=> []

irb> person = Person.new(name: "JD")
irb> person.valid?
=> false
irb> person.errors[:name]
=> ["短すぎます（最小で3文字以上）"]

irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors[:name]
=> ["空欄にはできません", "短すぎます（最小で3文字以上）"]
```

### `errors.where`とエラーオブジェクト

エラーごとに、そのエラーメッセージ以外の情報が必要になることがあります。各エラーは`ActiveModel::Error`オブジェクトとしてカプセル化されており、それらへのアクセスに最もよく用いられるのが[`where`][]メソッドです。

`where`は、さまざまな度合いの条件でフィルタされたエラーオブジェクトの配列を返します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

これを`errors.where(:attr)`の第1パラメータとして渡すことで、`attribute`だけをフィルタリングできます。
第2パラメータは、`errors.where(:attr, :type)`を呼び出して、エラーの`type`をフィルタリングするのに使われます。

```irb
irb> person = Person.new
irb> person.valid?
=> false

irb> person.errors.where(:name)
=> [ ... ] # :name属性のすべてのエラー

irb> person.errors.where(:name, :too_short)
=> [ ... ] # :name属性の:too_shortエラー
```

最後に、指定の型のエラーオブジェクトに存在する可能性のある任意の`options`でフィルタリングできます。

```irb
irb> person = Person.new
irb> person.valid?
=> false

irb> person.errors.where(:name, :too_short, minimum: 3)
=> [ ... ] # 最小が3で短すぎるすべてのnameのエラー
```

これらのエラーオブジェクトから、さまざまな情報を読み出せます。

```irb
irb> error = person.errors.where(:name).last

irb> error.attribute
=> :name
irb> error.type
=> :too_short
irb> error.options[:count]
=> 3
```

エラーメッセージを生成することも可能です。

```irb
irb> error.message
=> "is too short (minimum is 3 characters)"
irb> error.full_message
=> "Name is too short (minimum is 3 characters)"
```

[`full_message`][]メソッドは、属性名の冒頭を大文字にした読みやすいメッセージを生成します（`full_message`で使うフォーマットをカスタマイズする方法については、[国際化（i18n）ガイド](i18n.html#active-modelのメソッド)を参照してください）。

[`full_message`]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-full_message
[`where`]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-where

### `errors.add`

[`add`][]メソッドを使って、特定の属性に関連するエラーメッセージを手動で追加できます。このメソッドは、属性とエラーメッセージを引数として受け取ります。

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :name, :too_plain, message: "はあまりクールじゃない"
  end
end
```

```irb
irb> person = Person.create
irb> person.errors.where(:name).first.type
=> :too_plain
irb> person.errors.where(:name).first.full_message
=> "Nameはあまりクールじゃない"
```

[`add`]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add

### `errors[:base]`

個別の属性に関連するエラーメッセージを追加する代わりに、オブジェクトのステート全体に関連するエラーメッセージを追加することもできます。このメソッドは、属性の値にかかわらずオブジェクトが無効であることを通知したい場合に使えます。`errors[:base]`は配列なので、これに文字列を単に追加するだけでエラーメッセージとして使えるようになります。

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :base, :invalid, message: "この人物は以下の理由で無効です: "
  end
end
```

```irb
irb> person = Person.create
irb> person.errors.where(:base).first.full_message
=> "この人物は以下の理由で無効です: "
```

### `errors.size`

`size`メソッドは、オブジェクトのエラーの総数を返します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.size
=> 2

irb> person = Person.new(name: "Andrea", email: "andrea@example.com")
irb> person.valid?
=> true
irb> person.errors.size
=> 0
```

### `errors.clear`

`clear`メソッドは、`errors`コレクションに含まれるメッセージをすべてクリアしたい場合に使えます。無効なオブジェクトに対して`errors.clear`メソッドを呼び出しても、オブジェクトが実際に有効になるわけではありませんのでご注意ください。`errors`は空になりますが、`valid?`やオブジェクトをデータベースに保存しようとするメソッドが次回呼び出されたときに、バリデーションが再実行されます。そしていずれかのバリデーションが失敗すると、`errors`コレクションに再びメッセージが保存されます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
=> false
irb> person.errors.empty?
=> false

irb> person.errors.clear
irb> person.errors.empty?
=> true

irb> person.save
=> false

irb> person.errors.empty?
=> false
```

バリデーションエラーをビューで表示する
-------------------------------------

モデルを作成してバリデーションを追加し、Webのフォーム経由でそのモデルが作成できるようになったら、そのモデルでバリデーションが失敗したときにエラーメッセージを表示したくなります。

エラーメッセージの表示方法はアプリケーションごとに異なるため、そうしたメッセージを直接生成するビューヘルパーはRailsに含まれていません。
しかし、Railsでは一般的なバリデーションメソッドが多数提供されているので、カスタムのメソッドを作成するのは比較的簡単です。また、生成をscaffoldで行なうと、そのモデルのエラーメッセージをすべて表示するERBがRailsによって一部の`_form.html.erb`ファイルに追加されます。

`@article`という名前のインスタンス変数に保存されたモデルがあるとすると、ビューは以下のようになります。

```html+erb
<% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %>が原因でこの記事を保存できませんでした</h2>

    <ul>
      <% @article.errors.each do |error| %>
        <li><%= error.full_message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

また、フォームをRailsのフォームヘルパーで生成した場合、あるフィールドでバリデーションエラーが発生すると、そのエントリの周りに追加の`<div>`が自動的に生成されます。

```html
<div class="field_with_errors">
  <input id="article_title" name="article[title]" size="30" type="text" value="">
</div>
```

この`<div>`タグに好みのスタイルを追加できます。Railsが生成するデフォルトのscaffoldによって、以下のCSSルールが追加されます。

```css
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

このCSSは、エラーを含むフィールドを太さ2ピクセルの赤い枠で囲みます。
