Active Record バリデーション
==========================

このガイドでは、Active Recordのバリデーション（検証: validation）機能を使って、オブジェクトがデータベースに保存される前にオブジェクトの状態を検証する方法について説明します。

このガイドの内容:

* Active Record組み込みのバリデーション機能とオプション
* オブジェクトの有効性（validity）をチェックする方法
* 条件付きバリデーションや厳密なバリデーションの作成方法
* カスタムのバリデーションメソッドの作成方法
* バリデーションのエラーメッセージの処理とビューに表示する方法

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
irb> Person.new(name: "John Doe").valid?
#=> true
irb> Person.new(name: nil).valid?
#=> false
```

上でわかるように、このバリデーションは`Person`に`name`属性が存在しない場合に無効であることを知らせます。2つ目の`Person`はデータベースに保存されません。

バリデーションについて詳しく説明する前に、アプリケーション全体においてバリデーションがいかに重要であるかについて説明します。

### バリデーションを行なう理由

バリデーションの目的は、有効なデータだけをデータベースに保存し、無効なデータがデータベースに紛れ込まないようにすることです。
たとえば、すべてのユーザーが有効なメールアドレスと郵送先住所を提供していることを保証することがアプリケーションにとって重要な場合があります。

正しいデータだけをデータベースに保存するのであれば、モデルレベルでバリデーションを実行するのが最適です。モデルレベルでのバリデーションは、データベースの種類やバージョンに依存せず、エンドユーザーがバイパスすることもできず、テストもメンテナンスもやりやすいためです。

Railsではバリデーションを簡単に利用できるよう、一般に利用可能なバリデーションヘルパーが組み込まれており、独自のバリデーションメソッドも作成できるようになっています。

### Railsバリデーション以外の検証方法について

データをデータベースに保存する前に検証を自動実行する方法は、他にも「データベースネイティブの制約機能」「クライアント（ブラウザ）側でのバリデーション」「コントローラレベルのバリデーション」など、さまざまな方法があります。

それぞれのメリットとデメリットは以下のとおりです。

* データベースレベルの制約やストアドプロシージャを使うと、バリデーションのメカニズムがデータベースに依存してしまい、テストや保守がその分面倒になる可能性があります。
  ただし、データベースが（Rails以外の）他のアプリケーションからも使われるのであれば、データベースレベルである程度のバリデーションを行なっておくのはよい方法です。
  また、データベースレベルのバリデーションの中には、利用頻度がきわめて高いテーブルの一意性バリデーションのように、他の方法では実装が困難なものもあります。

* クライアント（ブラウザ）側でのバリデーションは扱いやすく便利ですが、一般に単独では信頼性が不足します。
  JavaScriptを使ってバリデーションを実装する場合、ユーザーがJavaScriptをオフにすればバイパスされてしまいます。
  ただし、他の方法と併用するのであれば、クライアント側でのバリデーションはユーザーに入力ミスを即座に通知する便利な方法として利用できます。

* コントローラレベルのバリデーションは一度はやってみたくなるものですが、たいてい手に負えなくなり、テストも保守も困難になりがちなので良くありません。
  アプリケーションの寿命を延ばし、メンテナンス作業を苦痛にしないためにも、コントローラのコード量は可能な限り減らすべきです。

Railsチームは、ほとんどの場合モデルレベルのバリデーションが最も適切であると考えていますが、場合によっては上述の別の検証方法を併用することもあります。

### バリデーションが実行されるタイミング

Active Recordのオブジェクトには2つの種類があります。データベースの行（row）に対応しているオブジェクトと、そうでないオブジェクトです。

たとえば、`new`メソッドで新しくオブジェクトを作成しただけでは、オブジェクトはデータベースに属していません。`save`メソッドを呼ぶことで、オブジェクトは適切なデータベースのテーブルに保存されます。

Active Recordの`persisted?`インスタンスメソッド（またはその逆の`new_record?`）を使うと、オブジェクトが既にデータベース上にあるかどうかを確認できます。

以下のActive Recordクラスを例として考えてみましょう。

```ruby
class Person < ApplicationRecord
end
```

`bin/rails console`の出力で様子を観察してみます。

```irb
irb> p = Person.new(name: "Jane Doe")
#=> #<Person id: nil, name: "Jane Doe", created_at: nil, updated_at: nil>

irb> p.new_record?
#=> true

irb> p.persisted?
#=> false

irb> p.save
#=> true

irb> p.new_record?
#=> false

irb> p.persisted?
#=> true
```

新規レコードを保存すると、SQLの`INSERT`操作がデータベースに送信され、既存のレコードを更新すると、SQLの`UPDATE`操作が送信されます。バリデーションは、これらのコマンドがデータベースに送信される前に実行されるのが普通です。

バリデーションが失敗すると、オブジェクトは無効（invalid）とマーキングされ、Active Recordによる`INSERT`や`UPDATE`操作は実行されません。このようにして、無効なオブジェクトがデータベースに保存されるのを防ぎます。

オブジェクトの作成、保存、更新時に特定のバリデーションを実行することも可能です。

WARNING: Railsのバリデーション機能は、無効なデータがデータベースに保存されるのを基本的に防ぎますが、Railsのメソッドの中にはバリデーションをトリガーしないものもある点に注意することが重要です。[バリデーションをバイパスする一部のメソッド](#バリデーションのスキップ)を使うと、バリデーションをトリガーせずにデータベースに直接変更を加えることが可能になるため、注意しておかないとオブジェクトを無効な状態で保存してしまう可能性があります。

以下のメソッドを実行するとバリデーションがトリガーされ、オブジェクトが有効な場合にのみデータベースに保存されます。

* [`create`][]
* [`create!`][]
* [`save`][]
* [`save!`][]
* [`update`][]
* [`update!`][]

`!`が末尾に付く破壊的メソッド（`save!`など）では、レコードが無効な場合に例外が発生します。

逆に`!`なしの非破壊的なメソッドは、無効な場合に例外を発生しません。
`save`と`update`は無効な場合に`false`を返し、`create`は無効な場合に単にそのオブジェクトを返します。

[`create`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-create
[`create!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-create-21
[`save`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save
[`save!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-save-21
[`update`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update
[`update!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update-21

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
* `save(validate: false)`

NOTE: 実は、`save`に`validate: false`を引数として与えると、`save`のバリデーションをスキップすることが可能です。この手法は十分注意して使う必要があります。

[`decrement!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-decrement-21
[`decrement_counter`]:
    https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-decrement_counter
[`increment!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-increment-21
[`increment_counter`]:
    https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-increment_counter
[`insert`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert
[`insert!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert-21
[`insert_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all
[`insert_all!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all-21
[`toggle!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-toggle-21
[`touch`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-touch
[`touch_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-touch_all
[`update_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_all
[`update_attribute`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_attribute
[`update_attribute!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_attribute-21
[`update_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_column
[`update_columns`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_columns
[`update_counters`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_counters
[`upsert`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert
[`upsert_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all

### 有効性をチェックする

Railsは、Active Recordオブジェクトを保存する直前にバリデーションを実行します。バリデーションで何らかのエラーが発生すると、オブジェクトを保存しません。

[`valid?`][]メソッドを使って、バリデーションを手動でトリガーすることもできます。`valid?`を実行するとバリデーションがトリガーされ、オブジェクトにエラーがない場合は`true`を返し、エラーの場合は`false`を返します。

これは以下のように実装できます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> Person.new(name: "John Doe").valid?
#=> true
irb> Person.new(name: nil).valid?
#=> false
```

Active Recordでバリデーションが行われた後で[`errors`][]インスタンスメソッドを使うと、失敗したバリデーションにアクセスできます。このメソッドはエラーのコレクションを返します。

定義により、バリデーション実行後にコレクションが空である場合は、オブジェクトが**有効**になる点にご注意ください。

NOTE: ただし、`new`でインスタンス化した保存前のオブジェクトは、たとえ技術的には無効であってもエラーは出力されないので、注意が必要です。バリデーションが自動的に実行されるのは、`create`や`save`メソッドなどでオブジェクトが保存されたときだけです。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> person = Person.new
#=> #<Person id: nil, name: nil, created_at: nil, updated_at: nil>
irb> person.errors.size
#=> 0

irb> person.valid?
#=> false
irb> person.errors.objects.first.full_message
#=> "Name can't be blank"

irb> person.save
#=> false

irb> person.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

irb> Person.create!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

[`invalid?`][]は`valid?`と逆のチェックを行います。このメソッドはバリデーションをトリガーし、オブジェクトでエラーが発生した場合は`true`を返し、エラーがない場合は`false`を返します。

[`errors`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-errors
[`invalid?`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-invalid-3F
[`valid?`]: https://api.rubyonrails.org/classes/ActiveRecord/Validations.html#method-i-valid-3F

### エラーを調べて処理する

[`errors[:attribute]`][Errors_squarebrackets]を使うと、特定のオブジェクトの属性が有効かどうかを確認できます。このメソッドは、`:attribute`のすべてのエラーの配列を返します。指定された属性でエラーが発生しなかった場合は、空の配列が返されます。これを用いて、特定の属性でバリデーションに問題があるかどうかを手軽に判断できます。

属性が正しいかどうかをチェックする例を以下に示します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> new_person = Person.new
irb> new_person.errors[:name]
#=> [] # saveするまではバリデーションされないのでエラーにならない
irb> new_person.errors[:name].any?
#=> false

irb> create_person = Person.create
irb> create_person.errors[:name]
#=> ["can't be blank"] # `name`は必須なのでバリデーションエラーになる
irb> create_person.errors[:name].any?
#=> true
```

さらに、[`errors.add`][]メソッドを使えば、特定の属性のエラーメッセージを手動で追加することも可能です。これは、特にバリデーションシナリオをカスタム定義する場合に便利です。

```ruby
class Person < ApplicationRecord
  validate do |person|
    errors.add :name, :too_short, message: "長さが足りません"
  end
end
```

NOTE: より高レベルなバリデーションエラーについては、[バリデーションエラーの取り扱い](#バリデーションエラーに対応する)セクションを参照してください。

[Errors_squarebrackets]:
    https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-5B-5D
[`errors.add`]:
  https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add

バリデーションの使い方
------------------

Active Recordには、クラス定義の内側で直接使える定義済みのバリデーションが多数用意されています。これらの定義済みバリデーションは、共通のバリデーションルールを提供します。
バリデーションが失敗するたびに、オブジェクトの`errors`コレクションにエラーメッセージが追加され、このメッセージはバリデーションが行われる属性に関連付けられます。

バリデーションが失敗すると、バリデーションをトリガーした属性名の下の`errors`コレクションにエラーメッセージを保存します。これにより、特定の属性に関連するエラーに手軽にアクセスできます。たとえば、`:name`属性のバリデーションが失敗すると、`errors[:name]`の下にエラーメッセージが保存されるのがわかります。。

最近のRailsアプリケーションでは、以下のように従来よりも簡潔な`validates`構文を使うのが一般的です。

```ruby
validates :name, presence: true
```

しかし、古いバージョンのRailsでは以下の`validates_presence_of`のような「ヘルパー形式の」メソッドが使われていました。

```ruby
validates_presence_of :name
```

どちらの記法でも機能は同じですが、読みやすさとRailsの規約との整合性を考えると、`validate`による新しい記法が推奨されます。

`:on`オプションと`:message`オプションは新旧両方のバリデーションで使えます。

- `:on`オプションは、バリデーションを実行するタイミングを指定します。
  `:on`オプションには、`:create`または`:update`のいずれかを指定できます。

- `:message`オプションは、バリデーション失敗時に`errors`コレクションに追加するメッセージを指定します。
  バリデーションにはそれぞれデフォルトのエラーメッセージが用意されていて、`:message`オプションを指定しない場合はデフォルトのメッセージが使われます。

INFO: 利用可能なデフォルトヘルパーのリストについては、[`ActiveModel::Validations::HelperMethods`][] APIドキュメントを参照してください。ただしこのAPIドキュメントでは、上述の古い記法が使われています。

[`ActiveModel::Validations::HelperMethods`]:
    https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html

以下で、最もよく使われるバリデーションを紹介します。

### `absence`

このバリデータは、指定された属性が「存在してはならない」ことをバリデーションします。

NOTE: このバリデータの内部では、属性の値が`nil`や空白（blank: つまり空文字列`""`または[ホワイトスペース][whitespace]のみで構成される文字列）ではないことのチェックに[`Object#present?`][]メソッドが使われています。

`#absence`は、`if`オプションと組み合わせた条件付きバリデーションでよく使われます。

```ruby
class Person < ApplicationRecord
  validates :phone_number, :address, absence: true, if: :invited?
end
```

```irb
irb> person = Person.new(name: "Jane Doe", invitation_sent_at: Time.current)
irb> person.valid?
#=> true # absenceバリデーションがパスしたことを表す
```

関連付けが存在しないことを確認したい場合、関連付けをマッピングするのに使われる外部キーが存在しないかどうかをバリデーションするのではなく、関連付け先のオブジェクト自体が存在しないかどうかをバリデーションする必要があります。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order, optional: true
  validates :order, absence: true
end
```

```irb
irb> line_item = LineItem.new
irb> line_item.valid?
#=> true # absenceバリデーションがパスしたことを表す

order = Order.create
irb> line_item_with_order = LineItem.new(order: order)
irb> line_item_with_order.valid?
#=> false # absenceバリデーションが失敗したことを表す
```

NOTE: `belongs_to`関連付けの場合、関連付けが存在することはデフォルトでバリデーションされます。関連付けの存在をバリデーションしたくない場合は、`optional: true`を指定してください。

Railsは通常、逆方向の関連付けを自動的に推測します。
カスタムの`:foreign_key`や`:through`関連付けを使う場合は、関連付けの探索を最適化するために`:inverse_of`オプションを明示的に指定することが重要です。これにより、バリデーション中に不要なデータベースクエリが発生することを回避できます。

詳しくは、関連付けガイドの[双方向関連付け](association_basics.html#双方向関連付け)を参照してください。

NOTE: 関連付けが存在することと、関連付けが有効であることを同時に確認したい場合は、`validates_associated`も使う必要があります。詳しくは[`validates_associated`](#validates-associated)で後述します。

[`has_one`](association_basics.html#has-one関連付け)や[`has_many`](association_basics.html#has-many関連付け)リレーションシップを経由して関連付けられたオブジェクトが存在しないことを`absence`でバリデーションすると、「`presence?`でもなく`marked_for_destruction?`（削除用マーク済み）でもない」かどうかをチェックできます。

`false.present?`は常に`false`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値が存在しないことをチェックしたい場合は、以下のように書く必要があります。

```ruby
validates :field_name, exclusion: { in: [true, false] }
```

デフォルトのエラーメッセージは「must be blank」です。

[`Object#present?`]:
    https://api.rubyonrails.org/classes/Object.html#method-i-present-3F

### `acceptance`

このバリデータは、フォームが送信されたときにユーザーインターフェイス上のチェックボックスがオンになっているかどうかをチェックします。

ユーザーによるサービス利用条項への同意が必要な場合や、ユーザーが何らかの文書に目を通したことを確認させる場合によく使われます。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: true
end
```

上のチェックは、`terms_of_service`が`nil`でない場合にのみ実行されます。
このヘルパーのデフォルトエラーメッセージは「must be accepted」です。

以下のように、バリデーション失敗時のカスタムメッセージを`message`オプションで渡すこともできます。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { message: "must be agreed to" }
end
```

`acceptance`には`:accept`オプションも渡せます。このオプションは、「同意可能（acceptable）」とみなす値を指定します。デフォルトは`['1', true]`ですが、以下のように手軽に変更できます。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { accept: "yes" }
  validates :eula, acceptance: { accept: ["TRUE", "accepted"] }
end
```

これはWebアプリケーション特有のバリデーションであり、データベースに保存する必要はありません。これに対応するフィールドがなくても、単にヘルパーが仮想の属性を作成してくれます。
このフィールドがデータベースに存在すると、`accept`オプションを設定するか`true`を指定しなければならず、そうでない場合はバリデーションが実行されなくなります。

### `confirmation`

このバリデータは、2つのテキストフィールドの入力内容が完全に一致する必要がある場合に使います。

たとえば、メールアドレスやパスワードの確認フィールドも追加するとします。このバリデーションは仮想の属性を作成します。属性の名前は、確認したい属性名に「`_confirmation`」を追加したものを使います。

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

NOTE: このチェックは、`email_confirmation`が`nil`でない場合のみ行われます。確認を必須にするには、以下のように確認用の属性について存在チェックも追加してください。`presence`を利用する存在チェックについては[`presence`](#presence)の項で解説します。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

`:case_sensitive`オプションを用いて、大文字小文字の違いを区別する制約をかけるかどうかも定義できます。デフォルトでは、このオプションは`true`です。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: { case_sensitive: false }
end
```

このバリデータのデフォルトメッセージは「doesn't match confirmation」です。
`message`オプションでカスタムメッセージを渡すことも可能です。

このバリデータを使う場合は、`:if`オプションと組み合わせて、レコードを保存するたびに「`_confirmation`」フィールドをバリデーションするのではなく、初期フィールドが変更されたときのみバリデーションするのが一般的です。
詳しくは[条件付きバリデーション](#条件付きバリデーション)で後述します。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true, if: :email_changed?
end
```

### `comparison`

このバリデーションは、比較可能な2つの値を比較します。

```ruby
class Promotion < ApplicationRecord
  validates :end_date, comparison: { greater_than: :start_date }
end
```

このバリデータのデフォルトのエラーメッセージは「failed comparison」です。
`message`オプションでカスタムメッセージを渡すことも可能です。

サポートされているオプションは以下のとおりです。

* `:greater_than`: 渡された値よりも大きい値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be greater than %{count}」です。
* `:greater_than_or_equal_to`: 渡された値と等しいか、それよりも大きい値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be greater than or equal to %{count}」です。
* `:equal_to`: 渡された値と等しくなければならないことを指定します。
  デフォルトのエラーメッセージは「must be equal to %{count}」です。
* `:less_than`: 渡された値よりも小さい値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be less than %{count}」です。
* `:less_than_or_equal_to`: 渡された値と等しいか、それよりも小さい値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be less than or equal to %{count}」です。
* `:other_than`: 渡された値と異なる値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be other than %{count}」です。

NOTE: このバリデータには比較オプションを指定する必要があります。各オプションには値、proc、シンボルを渡せます。Rubyの[`Comparable`][]を含む任意のクラスを比較可能です。

[`Comparable`]:
  https://docs.ruby-lang.org/ja/latest/class/Comparable.html

### `format`

このバリデータは、`with`オプションで与えられた正規表現と属性の値がマッチするかどうかをチェックします。

```ruby
class Product < ApplicationRecord
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "英文字のみが使えます" }
end
```

逆に、`:without`オプションを使うと、指定の属性が正規表現に**マッチしない**ことを必須化できます。

どちらの場合も、指定する`:with`や`:without`オプションは、正規表現か、正規表現を返すprocまたはlambdaでなければなりません。

デフォルトのエラーメッセージは「is invalid」です。

WARNING: **文字列**の冒頭や末尾にマッチさせるときは必ず`\A`と`\z`を使い、`^`と`$`は、**1行**の冒頭や末尾にマッチさせる場合に使うこと。`\A`や`\z`を使うべき場合に`^`や`$`を使う誤用が頻発しているため、`^`や`$`を使う場合は`multiline: true`オプションを渡す必要があります。ほとんどの場合、本当に必要なのは`\A`と`\z`です。

### `inclusion`と`exclusion`

これらのバリデータは、属性の値が特定のセットに「含まれているか」「含まれていないか」をチェックします。

指定するセットには、任意のenumerableオブジェクト（配列やrange、procやlambdaやシンボルで動的に生成されたコレクションなど）を利用できます。

- **`inclusion`**: 値がセット内に存在することをチェックする。
- **`exclusion`**: 値がセット内に**存在しない**ことをチェックする

どちらの場合も、`:in`オプションで値のセットを渡せます（エイリアス`:within`も利用可能）。

エラーメッセージをカスタマイズするための全オプションについては、[`message`](#message)セクションを参照してください。

enumerableオブジェクトが「数値」や「時間」「日時」のrangeの場合は、バリデーションに`Range#cover?`メソッドを使い、それ以外の場合は`include?`を使います。
procやlambdaを使うと、バリデーション対象のインスタンスが引数として渡され、動的なバリデーションが可能になります。

#### 例

`inclusion`の場合:

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
message: "%{value} のサイズは無効です" }
end
```

`exclusion`の場合:

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value}は予約済みです" }
end
```

どちらのバリデーションでも、enumerableを返すメソッドを渡すことで動的なバリデーションを実行可能です。

以下は`inclusion`でprocを渡した場合の例です。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: ->(coffee) { coffee.available_sizes } }

  def available_sizes
    %w(small medium large extra_large)
  end
end
```

以下は`exclusion`でprocを渡した場合の例です。

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: ->(account) { account.reserved_subdomains } }

  def reserved_subdomains
    %w(www us ca jp admin)
  end
end
```

### `length`

このバリデータは、属性の値の長さを検証します。多くのオプションがあり、さまざまな長さ制限を指定できます。

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
* `:in`または`:within`: 属性の長さは、与えられた区間以内でなければなりません。
  このオプションの値はrangeでなければなりません。
* `:is`: 属性の長さは与えられた値と等しくなければなりません。

デフォルトのエラーメッセージは、実行されるバリデーションの種類によって異なります。デフォルトのメッセージは以下のように`:wrong_length`、`:too_long`、`:too_short`オプションを使ってカスタマイズすることも、`%{count}`を長さ制限に対応する数値のプレースホルダに使うことも可能です。`:message`オプションを使ってエラーメッセージを指定することもできます。

```ruby
class Person < ApplicationRecord
  validates :bio, length: { maximum: 1000,
    too_long: "最大%{count}文字まで使えます" }
end
```

NOTE: デフォルトのエラーメッセージは英語が複数形で表現されていることにご注意ください（例: "is too short (minimum is %{count} characters)"）。このため、`:minimum`を1に設定するのであれば、メッセージをカスタマイズして単数形にするか、代わりに`presence: true`を使います。同様に、`:in`または`:within`の下限に1を指定する場合、メッセージをカスタマイズして単数形にするか、`length`より先に`presence`を呼ぶようにします。

NOTE: 制約オプションは一度に1つしか利用できませんが、`:minimum`と`:maximum`オプションは組み合わせて使えます。

### `numericality`

このバリデータは、属性に数値のみが使われていることをバリデーションします。デフォルトでは、整数値または浮動小数点数値にマッチします。これらの冒頭に正負の符号がある場合もマッチします。

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

このバリデータには、`:only_integer`の他に`:only_numeric`オプションも渡せます。これは、値が`Numeric`のインスタンスでなければならないことを指定し、値が`String`の場合は値の解析を試みます。

NOTE: デフォルトでは、`numericality`オプションで`nil`値は許容されません。`nil`値を許可するには`allow_nil: true`オプションを指定してください。`Integer`カラムや`Float`カラムでは、空の文字列が`nil`に変換される点にご注意ください。

オプションが指定されていない場合のデフォルトのエラーメッセージは「is not a number」です。

`:only_integer`以外にも以下のような多くのオプションで値の制約を指定できます。

* `:greater_than`: 指定の値よりも大きくなければならないことを指定します。
  デフォルトのエラーメッセージは「must be greater than %{count}」です。
* `:greater_than_or_equal_to`: 指定の値と等しいか、それよりも大きくなければならないことを指定します。
  デフォルトのエラーメッセージは「must be greater than or equal to %{count}」です。
* `:equal_to`: 指定の値と等しくなければならないことを示します。
  デフォルトのエラーメッセージは「must be equal to %{count}」です。
* `:less_than`: 指定の値よりも小さくなければならないことを指定します。
  デフォルトのエラーメッセージは「must be less than %{count}」です。
* `:less_than_or_equal_to`: 指定の値と等しいか、それよりも小さくなければならないことを指定します。
  デフォルトのエラーメッセージは「must be less than or equal to %{count}」です。
* `:other_than`: 指定の値以外の値でなければならないことを指定します。
  デフォルトのエラーメッセージは「must be other than %{count}」です。
* `:in`: 渡された範囲に値が含まれていなければならないことを指定します。
  デフォルトのエラーメッセージは「must be in %{count}」です。
* `:odd`: `true`の場合は奇数でなければなりません。
  デフォルトのエラーメッセージは「must be odd」です。
* `:even`: `true`の場合は偶数でなければなりません。
  デフォルトのエラーメッセージは「must be even」です。

### `presence`

このバリデータは、指定された属性が空（empty）でないことをチェックします。

NOTE: このバリデータの内部では、属性の値が`nil`や空白（blank: つまり空文字列`""`または[ホワイトスペース][whitespace]のみで構成される文字列）であることのチェックに[`Object#blank?`][]メソッドが使われています。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, presence: true
end
```

```irb
person = Person.new(name: "Alice", login: "alice123", email: "alice@example.com")
person.valid?
#=> true # presenceバリデーションがパスしたことを示す

invalid_person = Person.new(name: "", login: nil, email: "bob@example.com")
invalid_person.valid?
#=> false # presenceバリデーションが失敗したことを示す
```

関連付けが存在していることを確認したい場合、関連付けをマッピングするのに使われる外部キーが存在するかどうかをバリデーションするのではなく、関連付け先のオブジェクト自体が存在するかどうかをバリデーションする必要があります。

以下の例では、外部キーが空ではないことと、関連付けられたオブジェクトが存在することをチェックしています。

```ruby
class Supplier < ApplicationRecord
  has_one :account
  validates :account, presence: true
end
```

```irb
irb> account = Account.create(name: "Account A")

irb> supplier = Supplier.new(account: account)
irb> supplier.valid?
#=> true # presenceバリデーションがパスしたことを示す

irb> invalid_supplier = Supplier.new
irb> invalid_supplier.valid?
#=> false # presenceバリデーションが失敗したことを示す
```

カスタムの`:foreign_key`や`:through`関連付けを使う場合は、関連付けの探索を最適化するために`:inverse_of`オプションを明示的に指定することが重要です。これにより、バリデーション中に不要なデータベースクエリが発生することを回避できます。

詳しくは、関連付けガイドの[双方向関連付け](association_basics.html#双方向関連付け)を参照してください。

NOTE: 関連付けが存在することと、関連付けが有効であることを同時に確認したい場合は、`validates_associated`も使う必要があります。詳しくは[`validates_associated`](#validates-associated)で後述します。

[`has_one`](association_basics.html#has-one関連付け)や[`has_many`](association_basics.html#has-many関連付け)リレーションシップを経由して関連付けられたオブジェクトが存在することを`presence`でバリデーションすると、「`blank?`でもなく`marked_for_destruction?`（削除用マーク済み）でもない」かどうかをチェックできます。

`false.blank?`は常に`true`なので、真偽値に対してこのメソッドを使うと正しい結果が得られません。真偽値が存在することをチェックしたい場合は、以下のように書く必要があります。

```ruby
# 値はtrueかfalseでなければならない
validates :boolean_field_name, inclusion: [true, false]
# 値はnilであってはならない、すなわちtrueかfalseでなければならない
validates :boolean_field_name, exclusion: [nil]
```

これらのバリデーションのいずれかを使うことで、値が**決して**`nil`にならないようにできます。`nil`があると、ほとんどの場合`NULL`値になります。

デフォルトのエラーメッセージは「can't be blank」です。

[whitespace]:
  https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9#%E3%82%B3%E3%83%B3%E3%83%94%E3%83%A5%E3%83%BC%E3%82%BF%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E3%82%B9%E3%83%9A%E3%83%BC%E3%82%B9

[`Object#blank?`]:
  https://api.rubyonrails.org/classes/Object.html#method-i-blank-3F

### `uniqueness`

このバリデータは、オブジェクトが保存される直前に、属性の値が一意（unique）であり重複していないことをチェックします。

```ruby
class Account < ApplicationRecord
  validates :email, uniqueness: true
end
```

このバリデーションは、その属性と同じ値を持つ既存のレコードがモデルのテーブルにあるかどうかを調べるSQLクエリを実行することで行われます。

一意性チェックの範囲を限定する別の属性を指定する`:scope`オプションも利用できます。

```ruby
class Holiday < ApplicationRecord
  validates :name, uniqueness: { scope: :year,
    message: "発生は年に1度である必要があります" }
end
```

WARNING: このバリデーションはデータベースに一意性制約（uniqueness constraint）を作成しないので、異なる2つのデータベース接続が使われていると、一意であるべきカラムに同じ値を持つレコードが2つ作成される可能性があります。これを避けるには、データベース側でそのカラムにuniqueインデックスを作成する必要があります。

データベースに一意性データベース制約を追加するには、マイグレーションで[`add_index`][]ステートメントを使って`unique: true`オプションを指定します。

一意性バリデーションで`:scope`オプションを指定し、かつ一意性バリデーション違反を防ぐデータベース制約を作成したい場合は、データベース側で両方のカラムにuniqueインデックスを作成しなければなりません。
詳しくは、[MySQLのマニュアル][]や[MariaDBのマニュアル][]でマルチカラムインデックスについての情報を参照するか、[PostgreSQLのマニュアル][]などでカラムのグループを参照する一意性制約についての例を参照してください。

`:case_sensitive`オプションを指定することで、一意性制約で大文字小文字を区別するかどうか、またはデータベースのデフォルトの照合順序（collation）を尊重すべきかどうかを定義できます。このオプションは、データベースのデフォルト照合順序をデフォルトで尊重します。

```ruby
class Person < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 一部のデータベースでは検索で常に大文字小文字を区別しない設定になっているものがあります。

`:conditions`オプションを使うと、一意性制約の探索を制限するための追加条件を以下のようにSQLの`WHERE`フラグメントとして指定できます。

```ruby
validates :name, uniqueness: { conditions: -> { where(status: "active") } }
```

デフォルトのエラーメッセージは「has already been taken」です。

詳しくはAPIドキュメントの[`validates_uniqueness_of`][]を参照してください。

[`validates_uniqueness_of`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Validations/ClassMethods.html#method-i-validates_uniqueness_of
[`add_index`]:
  https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index
[MySQLのマニュアル]:
  https://dev.mysql.com/doc/refman/8.0/ja/multiple-column-indexes.html
[MariaDBのマニュアル]:
  https://mariadb.com/kb/en/compound-composite-indexes/
[PostgreSQLのマニュアル]:
  https://www.postgresql.jp/document/current/html/ddl-constraints.html

### `validates_associated`

常に有効でなければならない関連付けがモデルにある場合は、このバリデータを使う必要があります。オブジェクトを保存しようとするたびに、関連付けられているオブジェクトごとに`valid?`が呼び出されます。

```ruby
class Library < ApplicationRecord
  has_many :books
  validates_associated :books
end
```

このバリデーションは、すべての種類の関連付けで機能します。

WARNING: `validates_associated`を関連付けの両側で使ってはいけません。互いを呼び出して無限ループになります。

[`validates_associated`][]のデフォルトのエラーメッセージは「is invalid」です。

各関連付けオブジェクトには、それ自身の`errors`コレクションも含まれることに注意してください。エラーは呼び出し元のモデルには達しません。

NOTE: [`validates_associated`][]はActive Recordオブジェクトでしか利用できませんが、従来のバリデーションは[`ActiveModel::Validations`][]を含む任意のオブジェクトでも利用できます。

[`validates_associated`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Validations/ClassMethods.html#method-i-validates_associated

### `validates_each`

このバリデータは、属性をブロックでバリデーションします。
事前定義されたバリデーション関数を持っていないため、ブロックを扱うバリデーション関数を独自に作成する必要があります。[`validates_each`][]に渡されたすべての属性は、そのブロックに対してテストされます。

以下の例は、小文字で始まる名前と姓を却下します。

```ruby
class Person < ApplicationRecord
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, "大文字で始まる必要があります") if /\A[[:lower:]]/.match?(value)
  end
end
```

このブロックは、レコード（`record`）、属性名（`attr`）、属性の値（`value`）を受け取ります。

任意のコードを書いてブロック内のデータが有効かどうかをチェックできます。バリデーションに失敗した場合は、モデルにエラーを追加することで無効とマーキングする必要があります。

[`validates_each`]:
  https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_each

### `validates_with`

このバリデータは、バリデーション専用の別クラスにレコードを渡します。

```ruby
class AddressValidator < ActiveModel::Validator
  def validate(record)
    if record.house_number.blank?
      record.errors.add :house_number, "省略できません"
    end

    if record.street.blank?
      record.errors.add :street, "省略できません"
    end

    if record.postcode.blank?
      record.errors.add :postcode, "省略できません"
    end
  end
end

class Invoice < ApplicationRecord
  validates_with AddressValidator
end
```

`validates_with`にはデフォルトのエラーメッセージがないので、バリデータクラスのレコードのエラーコレクションに、手動でエラーを追加する必要があります。

NOTE: `record.errors[:base]`には、そのレコード全体のステートに関連するエラーメッセージを追加するのが一般的です。

バリデーションメソッドを実装するには、メソッド定義内に`record`パラメータが必要です。このパラメータはバリデーションを行なうレコードを表します。

特定の属性に関するエラーを追加したい場合は、以下のように`add`メソッドの第1引数にその属性を渡します。

```ruby
def validate(record)
  if record.some_field != "承認可"
    record.errors.add :some_field, "このフィールドは承認不可です"
  end
end
```

詳しくは[バリデーションエラー](#バリデーションエラーに対応する)で後述します。

[`validates_with`][]バリデータは、バリデーションに使うクラス（またはクラスのリスト）を引数に取ります。

```ruby
class Person < ApplicationRecord
  validates_with MyValidator, MyOtherValidator, on: :create
end
```

`validates_with`でも他のバリデーションと同様に`:if`、`:unless`、`:on`オプションが使えます。その他のオプションは、バリデータクラスに`options`として渡されます。

```ruby
class AddressValidator < ActiveModel::Validator
  def validate(record)
    options[:fields].each do |field|
      if record.send(field).blank?
        record.errors.add field, "省略できません"
      end
    end
  end
end

class Invoice < ApplicationRecord
  validates_with AddressValidator, fields: [:house_number, :street, :postcode, :country]
end
```

NOTE: このバリデータは、アプリケーションのライフサイクル内で**一度しか初期化されない**点にご注意ください。バリデーションが実行されるたびに初期化されることはないため、バリデータ内でインスタンス変数を使う場合は十分な注意が必要です。

作成したバリデータが複雑になってインスタンス変数を使いたくなった場合は、代わりに素のRubyオブジェクトを使う方がやりやすいでしょう。

```ruby
class Invoice < ApplicationRecord
  validate do |invoice|
    AddressValidator.new(invoice).validate
  end
end

class AddressValidator
  def initialize(invoice)
    @invoice = invoice
  end

  def validate
    validate_field(:house_number)
    validate_field(:street)
    validate_field(:postcode)
  end

  private
    def validate_field(field)
      if @invoice.send(field).blank?
        @invoice.errors.add field, "#{field.to_s.humanize}は省略できません"
      end
    end
end
```

詳しくは[カスタムバリデーション](#カスタムバリデーションを実行する)で後述します。

[`validates_with`]:
  https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_with

バリデーションの共通オプション
-------------------------

これまで見てきたバリデータにはさまざまな共通オプションがあるので、主なオプションを以下に示します。

* [`:allow_nil`](#allow-nil): 属性が`nil`の場合にバリデーションをスキップする。
* [`:allow_blank`](#allow-blank): 属性がblankの場合にバリデーションをスキップする。
* [`:message`](#message): カスタムのエラーメッセージを指定する。
* [`:on`](#on): このバリデーションを有効にするコンテキストを指定する。
* [`:strict`](#厳密なバリデーション): バリデーション失敗時にraiseする。
* [`:if`と`:unless`](#条件付きバリデーション): バリデーションする場合やしない場合の条件を指定する。

NOTE: 一部のバリデータは、これらのオプションをサポートしていません。詳しくは[`ActiveModel::Validations`][] APIドキュメントを参照してください。

[`ActiveModel::Validations`]:
  https://api.rubyonrails.org/classes/ActiveModel/Validations.html

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
#=> true
irb> Coffee.create(size: "mega").valid?
#=> false
```

`message:`引数の完全なオプションについては、[`:message`](#message)の項を参照してください。

### `:allow_blank`

`:allow_blank`オプションは`:allow_nil`オプションと似ています。このオプションを指定すると、属性の値が`blank?`に該当する場合（`nil`や空文字列`""`など）はバリデーションがパスします。

```ruby
class Topic < ApplicationRecord
  validates :title, length: { is: 6 }, allow_blank: true
end
```

```irb
irb> Topic.create(title: "").valid?
#=> true
irb> Topic.create(title: nil).valid?
#=> true
irb> Topic.create(title: "short").valid?
#=> false # 'short'は長さ6ではないので、blankでなくてもバリデーションは失敗する
```

### `:message`

既に例示したように、`:message`オプションを使うことで、バリデーション失敗時に`errors`コレクションに追加されるカスタムエラーメッセージを指定できます。
このオプションを使わない場合、Active Recordはバリデーションヘルパーごとにデフォルトのエラーメッセージを使います。

`:message`オプションは`String`または`Proc`を値として受け取ります。

`String`の`:message`値には、オプションで`%{value}`、`%{attribute}`、`%{model}`のいずれか、またはすべてを含められます。
これらのプレースホルダは、バリデーションが失敗した場合に動的に置き換えられます。この置き換えには[i18n gem](https://github.com/ruby-i18n/i18n)が使われるため、プレースホルダは完全に一致する必要があり、プレースホルダ内にはスペースを含んではいけません。

```ruby
class Person < ApplicationRecord
  # メッセージを直書きする場合
  validates :name, presence: { message: "省略できません" }

  # 動的な属性値を含むメッセージの場合。%{value}は実際の属性値に
  # 置き換えられる。%{attribute}や%{model}も利用可能。
  validates :age, numericality: { message: "%{value}は誤りかもしれません" }
end
```

`Proc`の`:message`値は以下の2つの引数を受け取ります。

- バリデーションの対象となるオブジェクト
- `:model`と`:attribute`と`:value`のキーバリューペアを含むハッシュ

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

エラーメッセージを翻訳する方法について詳しくは、[国際化（I18n）ガイド](i18n.html#エラーメッセージのスコープ)を参照してください。

### `:on`

`:on`オプションは、バリデーション実行のタイミングを指定するときに使います。
組み込みのバリデーションは、デフォルトでは保存時（レコードの作成時および更新時の両方）に実行されます。

バリデーションが実行されるタイミングは、以下で変更できます。

- `on: :create`: レコード新規作成時にのみバリデーションを行います。
- `on: :update`: レコードの更新時にのみバリデーションを行います。

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

`on:`にはカスタムコンテキストも定義できます。

カスタムコンテキストは、`valid?`や`invalid?`や`save`にコンテキスト名を渡して明示的にトリガーする必要があります。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
end
```

```irb
irb> person = Person.new(age: 'thirty-three')
irb> person.valid?
#=> true

irb> person.valid?(:account_setup)
#=> false

irb> person.errors.messages
#=> {:email=>["has already been taken"], :age=>["is not a number"]}
```

`person.valid?(:account_setup)`は、モデルを保存せずにバリデーションを2つとも実行します。
`person.save(context: :account_setup)`は、保存の前に`account_setup`コンテキストで`person`をバリデーションします。

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
#=> true

irb> book.valid?(:ensure_title)
#=> false

irb> book.errors.messages
#=> {:title=>["can't be blank"]}
```

タイミングを明示的に指定したモデルのバリデーションがトリガーされると、そのタイミングを指定したバリデーションに加えて、タイミングを指定していないバリデーションもすべて実行されます。

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
#=> false

irb> person.errors.messages
#=> {:email=>["has already been taken"], :age=>["is not a number"], :name=>["can't be blank"]}
```

`on:`のユースケースについて詳しくは、[コールバックガイド](active_record_callbacks.html)で解説します。

条件付きバリデーション
----------------------

特定の条件を満たす場合にのみバリデーションを実行したい場合があります。

このような条件指定は、`:if`オプションや`:unless`オプションで指定できます。引数にはシンボル、`Proc`または`Array`を使えます。

- `:if`オプションは、特定の条件でバリデーションを行なう**べきである**場合に使います。
- `:unless`オプションは、特定の条件でバリデーションを行なう**べきでない**場合に使います。

### `:if`や`:unless`でシンボルを渡す

バリデーションの実行直前に呼び出されるメソッド名は、`:if`や`:unless`オプションにシンボルで渡せます。これは最もよく使われるオプションです。

```ruby
class Order < ApplicationRecord
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### `:if`や`:unless`で`Proc`を渡す

呼び出したい`Proc`オブジェクトを`:if`や`:unless`に渡すことも可能です。

`Proc`オブジェクトを使えば、別のメソッドを渡さなくても、その場で条件を書けるようになります。ワンライナーに収まるシンプルな条件を指定したい場合に最適です。

```ruby
class Account < ApplicationRecord
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

lambdaは`Proc`の一種なので、lambda記法（`-> `）を用いて以下のようにインライン条件をさらに短く書くことも可能です。

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

[`with_options`]:
  https://api.rubyonrails.org/classes/Object.html#method-i-with_options

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
=> ActiveModel::StrictValidationFailed: Name can't be blank
```

上のように`:strict`オプションでバリデーションを厳密化すると、バリデーションが失敗したときに即座に例外が発生します。

これは、無効なデータが検出されたら即座に処理を停止する必要がある場合などに役立ちます。たとえば、重要なトランザクションの処理やデータ整合性チェックの実行など、無効な入力によってそれ以上操作を進めないようにする必要があるシナリオでは、厳密なバリデーションが有効です。

以下のようにカスタム例外を`:strict`オプションに追加することも可能です。

```ruby
class Person < ApplicationRecord
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end
```

```irb
irb> Person.new.valid?
#=> TokenGenerationException: Token can't be blank
```

### バリデータを一覧表示する

指定したオブジェクトのバリデータをすべて調べたい場合は、`validators`でバリデータのリストを表示できます。

たとえば、カスタムバリデータと組み込みバリデータを使った次のようなモデルがあるとします。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, on: :create
  validates :email, format: URI::MailTo::EMAIL_REGEXP
  validates_with MyOtherValidator, strict: true
end
```

このとき、以下のようにIRBで`validators`を実行して`Person`モデルのすべてのバリデータのリストを表示することも、`validators_on`で特定のフィールド用のバリデータがあるかどうかをチェックすることも可能です。

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

[`validate`]:
  https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validate

カスタムバリデーションを実行する
-----------------------------

組み込みのバリデーションだけでは不足の場合、好みのバリデータやバリデーションメソッドを作成して利用できます。

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

個別の属性をバリデーションするカスタムバリデータを追加するには、[`ActiveModel::EachValidator`][]を使うのが最も手軽で便利です。

カスタムバリデータクラスを作成するときは、以下の3つの引数を受け取る`validate_each`メソッドを実装する必要があります。

- `record`: インスタンスに対応するレコード
- `attribute`: バリデーション対象となる属性
- `value`: 渡されたインスタンスの属性の値

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless URI::MailTo::EMAIL_REGEXP.match?(value)
      record.errors.add attribute, (options[:message] || "is not an email")
    end
  end
end

class Person < ApplicationRecord
  validates :email, presence: true, email: true
end
```

上の例に示したように、標準のバリデーションとカスタムバリデーションを組み合わせて使うことも可能です。

[`ActiveModel::EachValidator`]:
    https://api.rubyonrails.org/classes/ActiveModel/EachValidator.html
[`ActiveModel::Validator`]:
    https://api.rubyonrails.org/classes/ActiveModel/Validator.html

### カスタムメソッド

モデルのステートを確認して、無効な場合に`errors`コレクションにメッセージを追加するメソッドを作成できます。これらのメソッドを作成後、[`validate`][]クラスメソッドを使って登録し、バリデーションメソッド名を指すシンボルを渡す必要があります。

クラスメソッドごとに複数のシンボルを渡せます。バリデーションは登録されたとおりの順序で実行されます。

`valid?`メソッドは`errors`コレクションが空であることをチェックするので、カスタムバリデーションにはバリデーションが失敗したときにエラーを追加する必要があります。

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

これらのバリデーションは、デフォルトでは`valid?`を呼び出したりオブジェクトを保存したりするたびに実行されます。

しかし`:on`オプションを使えば、カスタムバリデーションが実行されるタイミングを変更できます。`validate`に対して`on: :create`または`on: :update`を指定します。

```ruby
class Invoice < ApplicationRecord
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "はアクティブではありません") unless customer.active?
  end
end
```

`:on`について詳しくは上述の[`:on`](#on)セクションを参照してください。

### カスタムコンテキスト

コールバックに対して独自のバリデーションコンテキストをカスタム定義できます。
これは、特定のシナリオに基づいてバリデーションを実行したり、特定のコールバックをグループ化して特定のコンテキストで実行したりする場合に便利です。

カスタムコンテキストがよく使われるシナリオは、ウィザードのように複数のステップを持つフォームがあり、ステップごとにバリデーションを実行する場合です。

たとえば、以下のようにフォームのステップごとにカスタムコンテキストを定義できます。

```ruby
class User < ApplicationRecord
  validate :personal_information, on: :personal_info
  validate :contact_information, on: :contact_info
  validate :location_information, on: :location_info

  private
    def personal_information
      errors.add(:base, "名前は省略できません") if first_name.blank?
      errors.add(:base, "年齢は18歳以上でなければなりません") if age && age < 18
    end

    def contact_information
      errors.add(:base, "メールアドレスは省略できません") if email.blank?
      errors.add(:base, "電話番号は省略できません") if phone.blank?
    end

    def location_information
      errors.add(:base, "住所は省略できません") if address.blank?
      errors.add(:base, "市区町村名は省略できません") if city.blank?
    end
end
```

このような場合、ステップごとに[コールバックをスキップ](active_record_callbacks.html#コールバックをスキップする)する形で実装したくなるかもしれませんが、カスタムコンテキストを定義する方がより構造化できます。

コールバックのカスタムコンテキストを定義するには、`:on`オプションにコンテキストを指定する形で組み合わせる必要があります（`on: :personal_info`など）。

カスタムコンテキストを定義し終えたら、バリデーションをトリガーするときに、以下のように`:personal_info`などのカスタムコンテキストを指定できます。

```irb
irb> user = User.new(name: "John Doe", age: 17, email: "jane@example.com", phone: "1234567890", address: "123 Main St")
irb> user.valid?(:personal_info) # => false
irb> user.valid?(:contact_info)  # => true
irb> user.valid?(:location_info) # => false
```

カスタムコンテキストを使うと、コールバックをサポートする任意のメソッドでバリデーションをトリガーすることも可能になります。

たとえば、以下のように`save`でバリデーションをトリガーするときに`:personal_info`などのカスタムコンテキストを指定できます。

```irb
irb> user = User.new(name: "John Doe", age: 17, email: "jane@example.com", phone: "1234567890", address: "123 Main St")
irb> user.save(context: :personal_info) # => false
irb> user.save(context: :contact_info)  # => true
irb> user.save(context: :location_info) # => false
```

バリデーションエラーに対応する
------------------------------

[`valid?`][]メソッドや[`invalid?`][]メソッドでは、有効かどうかという概要しかわかりません。しかし[`errors`][]コレクションにあるさまざまなメソッドを使えば、個別のエラーをさらに詳しく調べられます。

以下は最もよく使われるメソッドの一覧です。利用可能なすべてのメソッドについては、[`ActiveModel::Errors`][] APIドキュメントを参照してください。

[`ActiveModel::Errors`]:
  https://api.rubyonrails.org/classes/ActiveModel/Errors.html

### `errors`

[`errors`][]メソッドは、個別のエラーを詳しく掘り下げるときの入り口となります。

`errors`メソッドは、すべてのエラーを含む`ActiveModel::Error`クラスのインスタンスを1つ返します。個別のエラーは、[`ActiveModel::Error`][]オブジェクトによって表現されます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
#=> false
irb> person.errors.full_messages
#=> ["Name can't be blank", "Name is too short (minimum is 3 characters)"]

irb> person = Person.new(name: "John Doe")
irb> person.valid?
#=> true
irb> person.errors.full_messages
#=> []

irb> person = Person.new
irb> person.valid?
#=> false
irb> person.errors.first.details
#=> {:error=>:too_short, :count=>3}
```

[`ActiveModel::Error`]:
    https://api.rubyonrails.org/classes/ActiveModel/Error.html

### `errors[]`

[`errors[]`][Errors_squarebrackets]は、特定の属性についてエラーメッセージをチェックしたい場合に使います。指定の属性に関するすべてのエラーメッセージの文字列の配列を返します（1つの文字列に1つのエラーメッセージが対応します）。属性に関連するエラーがない場合は空の配列を返します。

`errors[]`は、あくまでオブジェクトの個々の属性でエラーが見つかったかどうかをチェックするだけなので、このメソッドが役に立つのは、バリデーションの実行が完了した後だけです（`errors`のコレクションにエラーがあるかどうかを調べるだけで、バリデーション自体はトリガーしません）。
`errors[]`はオブジェクト全体の有効性に関するバリデーションは行わないので、上で説明した`ActiveRecord::Base#invalid?`メソッドとは異なります。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new(name: "John Doe")
irb> person.valid?
#=> true
irb> person.errors[:name]
#=> []

irb> person = Person.new(name: "JD")
irb> person.valid?
#=> false
irb> person.errors[:name]
#=> ["is too short (minimum is 3 characters)"]

irb> person = Person.new
irb> person.valid?
#=> false
irb> person.errors[:name]
#=> ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.where`とエラーオブジェクト

エラーごとに、そのエラーメッセージ以外の情報も必要になることがあります。各エラーは`ActiveModel::Error`オブジェクトとしてカプセル化されており、それらへのアクセスに最もよく用いられるのが[`where`][]メソッドです。

`where`は、さまざまな度合いの条件でフィルタされたエラーオブジェクトの配列を返します。

以下のバリデーションを考えてみましょう。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

`errors.where(:attr)`の第1パラメータに属性名を渡すと、その属性名だけをフィルタで絞り込めます。
第2パラメータにエラーの種別を渡すと、`errors.where(:attr, :type)`を呼び出してフィルタで絞り込みます。

```irb
irb> person = Person.new
irb> person.valid?
#=> false

irb> person.errors.where(:name)
#=> [ ... ] # :name属性のすべてのエラー

irb> person.errors.where(:name, :too_short)
#=> [ ... ] # :nameの:too_shortエラー
```

最後の第3パラメータには、指定の型のエラーオブジェクトに存在する可能性のある任意のオプションを指定してフィルタで絞り込めます。

```irb
irb> person = Person.new
irb> person.valid?
#=> false

irb> person.errors.where(:name, :too_short, minimum: 3)
#=> [ ... ] # 最小が3で短すぎるすべてのnameのエラー
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
#=> "is too short (minimum is 3 characters)"
irb> error.full_message
#=> "Name is too short (minimum is 3 characters)"
```

[`full_message`][]メソッドは、属性名の冒頭を大文字にした読みやすいメッセージを生成します。

NOTE: `full_message`で使うフォーマットをカスタマイズする方法については、[国際化（i18n）ガイド](i18n.html#active-modelのメソッド)を参照してください

[`full_message`]:
    https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-full_message
[`where`]:
    https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-where

### `errors.add`

[`add`][]メソッドを使って、特定の属性に関連するエラーメッセージを手動で追加できます。このメソッドは、属性とエラーメッセージを引数として受け取ります。

[`add`][]メソッドは、「属性名」「エラー種別」「オプションの追加ハッシュ」を受け取ってエラーオブジェクトを作成します。非常に具体的なエラー状況を定義できるため、独自のバリデータを作成するときに便利です。

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
#=> :too_plain
irb> person.errors.where(:name).first.full_message
#=> "Nameはあまりクールじゃない"
```

[`add`]:
    https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add

### `errors[:base]`

特定の属性に関連するエラーではなく、オブジェクト全体の状態に関連するエラーを追加できます。
これを行うには、新しいエラーを追加するときに属性として`:base`を指定する必要があります。

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
#=> "この人物は以下の理由で無効です: "
```

### `errors.size`

`size`メソッドは、オブジェクトのエラーの全件数を返します。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
#=> false
irb> person.errors.size
#=> 2

irb> person = Person.new(name: "Andrea", email: "andrea@example.com")
irb> person.valid?
#=> true
irb> person.errors.size
#=> 0
```

### `errors.clear`

`clear`メソッドは、`errors`コレクションに含まれるメッセージをすべてクリアしたい場合に使えます。無効なオブジェクトに対して`errors.clear`メソッドを呼び出しても、オブジェクトが実際に有効になるわけではありませんのでご注意ください。

`errors`は空になりますが、`valid?`やオブジェクトをデータベースに保存しようとするメソッドが次回呼び出されたときに、バリデーションが再実行されます。そしていずれかのバリデーションが失敗すると、`errors`コレクションに再びメッセージが保存されます。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end
```

```irb
irb> person = Person.new
irb> person.valid?
#=> false
irb> person.errors.empty?
#=> false

irb> person.errors.clear
irb> person.errors.empty?
#=> true

irb> person.save
#=> false

irb> person.errors.empty?
#=> false
```

バリデーションエラーをビューで表示する
-------------------------------------

モデルを定義してバリデーションを追加したら、Webフォームでそのモデルを作成中にバリデーションが失敗したときに、ユーザーにエラーメッセージを表示する必要があります。

エラーメッセージの表示方法はアプリケーションごとに異なるため、そうしたメッセージを直接生成するビューヘルパーはRailsに含まれていません。
しかし、Railsでは一般的なバリデーションメソッドが多数提供されているので、それらを活用してカスタムのメソッドを作成できます。

また、生成をscaffoldで行なうと、そのモデルのエラーメッセージをすべて表示するERBがRailsによって自動的に`_form.html.erb`ファイルに追加されます。

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

この`<div>`タグに好みのスタイルを追加できます。Railsがscaffoldで生成するデフォルトのCSSルールは以下のようになります。

```css
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

このCSSは、バリデーションエラーが発生したフィールドを太さ2ピクセルの赤い枠で囲みます。

### エラー表示用フィールドのラッパーをカスタマイズする

Railsは、エラーが表示されているフィールドを[`field_error_proc`][]設定オプションを用いてHTMLでラップします。

このオプションは、デフォルトでは上述の例に示すように、エラーが表示されているフォームフィールドを`field_with_errors` CSSクラスで`<div>`要素にラップします。

```ruby
config.action_view.field_error_proc = Proc.new { |html_tag, instance| content_tag :div, html_tag, class: "field_with_errors" }
```

フォームでのエラーの表示スタイルは、アプリケーションの[`field_error_proc`][]設定を変更してこの振る舞いをカスタマイズすることで変更できます。詳しくは設定ガイドの[`field_error_proc`][]を参照してください。

[`field_error_proc`]:
  configuring.html#config-action-view-field-error-proc
