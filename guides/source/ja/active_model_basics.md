Active Model の基礎
===================

本ガイドでは、モデルクラスを使って作業を開始するのに必要な知識について解説します。Active Modelは、Action PackやAction ViewヘルパーにプレーンなRubyオブジェクトとのやりとりを行う手段を提供します。Active Modelを用いることで、カスタムのORM (オブジェクト/リレーショナルマッパー) を作成してRailsフレームワークの外で利用できるようになります。

このガイドの内容:

* Active Modelの概要とActive Recordとの関係
* Active Modelに含まれるさまざまなモジュール
* Active Modelを自分のクラスで利用する方法

--------------------------------------------------------------------------------


はじめに
------------

Active Modelを理解するには、まず[Active Record][]について少し知っておく必要があります。Active RecordはORM（オブジェクト/リレーショナル マッパー）の一種であり、データを永続的に保存する必要のあるオブジェクトをリレーショナルデータベースに接続します。ただし、ORM以外にも、バリデーション、コールバック、変換、カスタム属性を作成する機能といった有用な機能がたくさんあります。

Active Recordのそうした機能の一部が抽象化されてActive Modelに移転しました。Active Modelは、モデルのような機能を必要としているが、データベース内のテーブルには関連付けないプレーンなRubyオブジェクト（PORO）で利用できるさまざまなモジュールを含むライブラリです。

要約すると、Active Recordは「データベースのテーブルに対応するモデル」を定義するインターフェイスを提供するものであり、Active Modelは「必ずしもデータベースを必要としない、モデル風のRubyクラス」を構築するための機能を提供するものです。Active Modelは、Active Recordとは独立して利用できます。

いくつかのモジュールについては、以下で説明します。

[Active Record]: active_record_basics.html

### API

[`ActiveModel::API`][]は、クラスを[Action Pack][]や[Action View][]と連携させる機能をすぐ利用可能な形でクラスに追加します。

`ActiveModel::API`を`include`すると、他のモジュールがデフォルトで`include`され、以下のような機能が使えるようになります。

- [属性への代入](#attributeassignmentモジュール)
- [型変換](#conversionモジュール)
- [属性の命名](#namingモジュール)
- [翻訳（i18n）](#translationモジュール)
- [バリデーション](#validationsモジュール)

`ActiveModel::API`を`include`したクラスとその使い方の例を以下に示します。

```ruby
class EmailContact
  include ActiveModel::API
  attr_accessor :name, :email, :message
  validates :name, :email, :message, presence: true
  def deliver
    if valid?
      # メールを配信する
    end
  end
end
```

```irb
irb> email_contact = EmailContact.new(name: "David", email: "david@example.com", message: "Hello World")

irb> email_contact.name # 属性の代入
=> "David"

irb> email_contact.to_model == email_contact # 変換
=> true

irb> email_contact.model_name.name # 名前の取得
=> "EmailContact"

irb> EmailContact.human_attribute_name("name") # 翻訳（ロケールが設定済みの場合）
=> "Name"

irb> email_contact.valid? # バリデーション
=> true

irb> empty_contact = EmailContact.new
irb> empty_contact.valid?
=> false
```

`ActiveModel::API`を`include`したクラスは、Active Recordオブジェクトと同様に、`form_with`や`render`などの[Action Viewのヘルパーメソッド][]でも利用できます。

たとえば、次のように`form_with`メソッドを利用して`EmailContact`オブジェクトのフォームを作成できます。

```html+erb
<%= form_with model: EmailContact.new do |form| %>
  <%= form.text_field :name %>
<% end %>
```

上によって以下のHTMLが生成されます。

```html
<form action="/email_contacts" method="post">
  <input type="text" name="email_contact[name]" id="email_contact_name">
</form>
```

以下のように`render`メソッドを使うことで、このオブジェクトのパーシャルをレンダリングすることも可能です。

```html+erb
<%= render @email_contact %>
```

NOTE: `form_with`や`render`を`ActiveModel::API`互換オブジェクトで利用する方法について詳しくは、それぞれ[Action Viewフォームヘルパー][]ガイドと[レイアウトとレンダリング][]ガイドを参照してください。

[`ActiveModel::API`]: https://api.rubyonrails.org/classes/ActiveModel/API.html
[Action Pack]: https://api.rubyonrails.org/files/actionpack/README_rdoc.html
[Action View]: action_view_overview.html
[Action Viewのヘルパーメソッド]: https://api.rubyonrails.org/classes/ActionView/Helpers.html
[Action Viewフォームヘルパー]: form_helpers.html
[レイアウトとレンダリング]: layouts_and_rendering.html

### `Model`モジュール

[`ActiveModel::Model`][]モジュールには、Action PackやAction Viewとやりとりするための[`ActiveModel::API`](#api)がデフォルトで含まれており、モデル的なRubyクラスを実装する場合はこの方法が推奨されています。将来的には拡張され、より多くの機能が追加される予定です。

```ruby
class Person
  include ActiveModel::Model

  attr_accessor :name, :age
end
```

```irb
irb> person = Person.new(name: 'bob', age: '18')
irb> person.name # => "bob"
irb> person.age  # => "18"
```

[`ActiveModel::Model`]: https://api.rubyonrails.org/classes/ActiveModel/Model.html

### `Attributes`モジュール

[`ActiveModel::Attributes`][]モジュールを利用することで、データ型の定義、デフォルト値の設定、PORO（プレーンなRubyオブジェクト）のキャストやシリアライズの処理が可能になります。これは、フォームデータで通常のオブジェクトの日付やブーリアン値などに対してActive Recordと同じような変換を行うときに便利です。

`Attributes`を利用するには、以下のようにモデルクラスにモジュールを`include`してから、`attribute`マクロで属性を定義します。この属性には、「属性名」「キャスト型」「デフォルト値」など、属性型でサポートされる任意のオプションを指定できます。

```ruby
class Person
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :date_of_birth, :date
  attribute :active, :boolean, default: true
end
```

```irb
irb> person = Person.new

irb> person.name = "Jane"
irb> person.name
=> "Jane"

# 文字列を、属性によって設定された日付にキャストする
irb> person.date_of_birth = "2020-01-01"
irb> person.date_of_birth
=> Wed, 01 Jan 2020
irb> person.date_of_birth.class
=> Date

# 属性に設定されているデフォルト値を利用する
irb> person.active
=> true

# 整数値を、属性に設定されているブーリアン値にキャストする
irb> person.active = 0
irb> person.active
=> false
```

`ActiveModel::Attributes`で利用できるメソッドを以下にいくつか紹介します。

[`ActiveModel::Attributes`]: https://api.rubyonrails.org/classes/ActiveModel/Attributes.html

#### `attribute_names`メソッド

`attribute_names`メソッドは、属性名のリストを配列で返します。

```irb
irb> Person.attribute_names
=> ["name", "date_of_birth", "active"]
```

#### `attributes`メソッド

`attributes`は、すべての属性のリストをハッシュで返します。ハッシュのキーは属性名で、値は属性の値です。

```irb
irb> person.attributes
=> {"name" => "Jane", "date_of_birth" => Wed, 01 Jan 2020, "active" => false}
```

### `AttributeAssignment`モジュール

[`ActiveModel::AttributeAssignment`][]モジュールを利用すると、属性名と一致するキーを持つ属性のハッシュを渡す形でオブジェクトの属性を一括で設定できます。これは、複数の属性を一度にまとめて設定したい場合に便利です。

以下のクラスを考えてみましょう。

```ruby
class Person
  include ActiveModel::AttributeAssignment

  attr_accessor :name, :date_of_birth, :active
end
```

```irb
irb> person = Person.new

# 複数の属性を一括で設定する
irb> person.assign_attributes(name: "John", date_of_birth: "1998-01-01", active: false)

irb> person.name
=> "John"
irb> person.date_of_birth
=> Thu, 01 Jan 1998
irb> person.active
=> false
```

渡されたハッシュが`permitted?`メソッドに応答し、かつこのメソッドの戻り値が`false`の場合は、`ActiveModel::ForbiddenAttributesError`例外が発生します。

NOTE: `permitted?`メソッドは、[strong parameters][]でリクエストからのパラメータを`params`属性に設定するときに使われます。

```irb
irb> person = Person.new

# strong parametersチェックを用いて、リクエストから受け取るパラメータと同じようなハッシュをビルドする
irb> params = ActionController::Parameters.new(name: "John")
=> #<ActionController::Parameters {"name" => "John"} permitted: false>

irb> person.assign_attributes(params)
=> # Raises ActiveModel::ForbiddenAttributesError
irb> person.name
=> nil

# 代入を許可したい属性で代入を許可する
irb> permitted_params = params.permit(:name)
=> #<ActionController::Parameters {"name" => "John"} permitted: true>

irb> person.assign_attributes(permitted_params)
irb> person.name
=> "John"
```

[`ActiveModel::AttributeAssignment`]: https://api.rubyonrails.org/classes/ActiveModel/AttributeAssignment.html
[strong parameters]: action_controller_overview.html#strong-parameters

#### `attributes=`エイリアスメソッド

`assign_attributes`には`attributes=`というエイリアスメソッドもあります。

INFO: エイリアスメソッドは、同じ操作を実行しますが呼び名が異なるメソッドです。エイリアスはコードの読みやすく使いやすくするために存在します。

`attributes=`メソッドで複数の属性を一度に設定する方法の例を以下に示します。

```irb
irb> person = Person.new

irb> person.attributes = { name: "John", date_of_birth: "1998-01-01", active: false }

irb> person.name
=> "John"
irb> person.date_of_birth
=> "1998-01-01"
```

INFO: `assign_attributes`と`attributes=` はどちらもメソッド呼び出しであり、代入する属性のハッシュを引数として渡せます。Rubyでは多くの場合、メソッド呼び出しの丸かっこ`()`やハッシュ定義の波かっこ`{}`を省略できます。 <br><br>
`attributes=`のような「セッター」メソッドの呼び出しでは、丸かっこ`()`を省略することがよくあります（`()`を省略しなくても振る舞いは変わりません）が、セッターメソッドにハッシュを渡す場合は波かっこ`{}`を省略してはいけない点にご注意ください。たとえば`person.attributes=({ name: "John" })`は正常に動作しますが、`person.attributes = name: "John"`では`SyntaxError`が発生します。<br><br>`assign_attributes`などの（セッターでない）メソッド呼び出しでは、ハッシュ引数の丸かっこ`()`や`{}`を両方書くことも両方省略することも可能です。たとえば、`assign_attributes name: "John"`や`assign_attributes({ name: "John" })`はどちらもRubyコードとして完全に有効です。ただし`assign_attributes { name: "John" }`という波かっこ`{}`だけの書き方は有効ではなく、`SyntaxError`が発生します（波かっこ`{}`がハッシュ引数なのかブロックなのかをRubyが区別できないため）。

### `AttributeMethods`モジュール

[`ActiveModel::AttributeMethods`][]モジュールは、モデルの属性メソッドを動的に定義する方法を提供します。このモジュールは、属性へのアクセスと操作をシンプルにするうえで特に有用であり、クラスのメソッドにカスタムのプレフィックスやサフィックスを追加することも可能です。プレフィックスとサフィックス、およびそれらをオブジェクトのどのメソッドで利用するかを定義するには、次の手順で実装できます。

1. クラスに`ActiveModel::AttributeMethods`を`include`します。
2. 追加したいメソッド（`attribute_method_suffix`、`attribute_method_prefix`、`attribute_method_affix`など）を呼び出します。
3. 他のメソッドに続けて`define_attribute_methods`を呼び出して、プレフィックスやサフィックスを付ける必要がある属性を宣言します。
4. 宣言した属性にさまざまな汎用`_attribute`メソッドを定義します。これらのメソッドの`attribute`パラメータは、`define_attribute_methods`で渡される引数に置き換えられます（以下の例では`name`）。

NOTE: `attribute_method_prefix`や`attribute_method_suffix`は、メソッドの作成で利用するプレフィックスまたはサフィックスを定義するのに使います。`attribute_method_affix`は、プレフィックスとサフィックスを両方同時に定義するのに使います。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_affix prefix: "reset_", suffix: "_to_default!"
  attribute_method_prefix "first_", "last_"
  attribute_method_suffix "_short?"

  define_attribute_methods "name"

  attr_accessor :name

  private
    # 'first_name'用の属性メソッド呼び出し
    def first_attribute(attribute)
      public_send(attribute).split.first
    end

    # 'last_name'用の属性メソッド呼び出し
    def last_attribute(attribute)
      public_send(attribute).split.last
    end

    # 'name_short?'用の属性メソッド呼び出し
    def attribute_short?(attribute)
      public_send(attribute).length < 5
    end

    # 'reset_name_to_default!'用の属性メソッド呼び出し
    def reset_attribute_to_default!(attribute)
      public_send("#{attribute}=", "Default Name")
    end
end
```

```irb
irb> person = Person.new
irb> person.name = "Jane Doe"

irb> person.first_name
=> "Jane"
irb> person.last_name
=> "Doe"

irb> person.name_short?
=> false

irb> person.reset_name_to_default!
=> "Default Name"
```

[`ActiveModel::AttributeMethods`]: https://api.rubyonrails.org/classes/ActiveModel/AttributeMethods.html

定義されていないメソッドを呼び出すと、`NoMethodError`をraiseします。

#### `alias_attribute`

`ActiveModel::AttributeMethods`は、`alias_attribute`による属性メソッドのエイリアス作成機能を提供しています。

以下の例では、`name`のエイリアス属性`full_name`を作成しています。どちらの属性も同じ値を返しますが、エイリアス`full_name`はこの属性に名と姓が含まれていることが明示されています。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_suffix "_short?"
  define_attribute_methods :name

  attr_accessor :name

  alias_attribute :full_name, :name

  private
    def attribute_short?(attribute)
      public_send(attribute).length < 5
    end
end
```

```irb
irb> person = Person.new
irb> person.name = "Joe Doe"
irb> person.name
=> "Joe Doe"

# `full_name` is the alias for `name`, and returns the same value
irb> person.full_name
=> "Joe Doe"
irb> person.name_short?
=> false

# `full_name_short?` is the alias for `name_short?`, and returns the same value
irb> person.full_name_short?
=> false
```

### `Callbacks`モジュール

[`ActiveModel::Callbacks`][]は、[Active Record スタイルのコールバック](active_record_callbacks.html)をプレーンなRubyオブジェクトの形で提供します。コールバックを利用して、`before_update`や`after_create`などのモデルのライフサイクルイベントにフックすることも、モデルのライフサイクルの特定の時点で実行されるカスタムロジックを定義することも可能になります。

`ActiveModel::Callbacks`は、以下の手順に沿って実装できます。

1. クラス内で`ActiveModel::Callbacks`を`extend`します。
2. コールバックを関連付ける必要があるメソッドのリストを`define_model_callbacks`で確立します。たとえば`:update`などのメソッドを指定すると、`:update`イベントの3つのデフォルトコールバック（`before`、`around`、`after`）がすべて自動的に`include`されます。
3. 定義されたメソッド内で`run_callbacks`を利用して、特定のイベントがトリガーされたときにコールバックチェインを実行します。
4. これで、Active Recordモデルと同様に、このクラスで`before_update`、`after_update`、`around_update`メソッドを利用できるようになります。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me
  after_update :finalize_me
  around_update :log_me

  # `define_model_callbacks`メソッドには、指定のイベントでコールバックを実行する`run_callbacks`が含まれる

  def update
    run_callbacks(:update) do
      puts "updateメソッドが呼び出された"
    end
  end

  private
    # オブジェクトでupdateが呼び出されると、`before_update`コールバックでこのメソッドが呼び出される
    def reset_me
      puts "reset_me method: updateメソッドの前に呼び出される"
    end

    # オブジェクトでupdateが呼び出されると、`after_update`コールバックでこのメソッドが呼び出される
    def finalize_me
      puts "finalize_me method: updateメソッドの後に呼び出される"
    end

    # オブジェクトでupdateが呼び出されると、`around_update`コールバックでこのメソッドが呼び出される
    def log_me
      puts "log_me method: updateメソッドの前後に呼び出される"
      yield
      puts "log_me method: ブロックの呼び出し成功"
    end
end
```

上記のクラスによって生成された以下の結果には、コールバックが呼び出された順序が示されています。

```irb
irb> person = Person.new
irb> person.update
reset_me method: updateメソッドの前に呼び出される
log_me method: updateメソッドの前に呼び出された
updateメソッドが呼び出された
log_me method: ブロックの呼び出し成功
finalize_me method: updateメソッドの後に呼び出される
=> nil
```

`around`コールバックを定義するときは、上記のコード例のようにブロック内で`yield`することを忘れてはいけません（さもないとコールバックが実行されません）。

NOTE: `define_model_callbacks`に渡す`method_name`には、`!`、`?`、`=`で終わるメソッド名は使えません。また、同じコールバックを複数回定義すると以前のコールバック定義は上書きされます。

[`ActiveModel::Callbacks`]: https://api.rubyonrails.org/classes/ActiveModel/Callbacks.html

#### 特定のコールバックを定義する

`define_model_callbacks`メソッドに`only`オプションを渡すと、特定のコールバックを指定して作成できます。

```ruby
define_model_callbacks :update, :create, only: [:after, :before]
```

これにより、`before_create`/`after_create`と、`before_update`/`after_update`コールバックだけが作成され、`around_*`コールバックは作成されずにスキップされます。この`only`オプションは、そのメソッド呼び出しで定義されたすべてのコールバックに適用されます。`define_model_callbacks`を複数回呼び出して、異なるライフサイクルイベントを指定することも可能です。

```ruby
define_model_callbacks :create, only: :after
define_model_callbacks :update, only: :before
define_model_callbacks :destroy, only: :around
```

上のコードは`after_create`、`before_update`、`around_destroy`だけを作成します。

#### コールバック定義にクラスを渡す

`before_<type>`や`after_<type>`や`around_<type>`にクラスを渡すことで、コールバックがいつ、どのようなコンテキストでトリガーされるかをより細かく制御できます。コールバックは、そのクラスにある`<action>_<type>`メソッドをトリガーし、そのクラスのインスタンスを引数として渡します。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :create
  before_create PersonCallbacks
end

class PersonCallbacks
  def self.before_create(obj)
    # この`obj`は、コールバックが呼び出されるPersonインスタンス
  end
end
```

#### コールバックを中断する

コールバックチェインは、`:abort`をスローすればいつでも中断できます。これは、Active Recordコールバックの仕組みと似ています。

以下の例では、`reset_me`メソッドの更新の前に`:abort`をスローしているので、`before_update`を含む残りのコールバックチェインは中止され、`update`メソッドの本体は実行されません。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me
  after_update :finalize_me
  around_update :log_me

  def update
    run_callbacks(:update) do
      puts "updateメソッドが呼び出された"
    end
  end

  private
    def reset_me
      puts "reset_me method: updateメソッドの前に呼び出される"
      throw :abort
      puts "reset_me method: abort後のコード"
    end

    def finalize_me
      puts "finalize_me method: updateメソッドの後に呼び出される"
    end

    def log_me
      puts "log_me method: updateメソッドの前後に呼び出される"
      yield
      puts "log_me method: ブロックの呼び出し成功"
    end
end
```

```irb
irb> person = Person.new
irb> person.update
reset_me method: updateメソッドの前に呼び出される
=> false
```

### `Conversion`モジュール

[`ActiveModel::Conversion`][]モジュールは、オブジェクトをさまざまな目的に応じて多様な形式に変換できるメソッドのコレクションです。一般的なユースケースは、URLやフォームフィールドなどをビルドするときにオブジェクトを文字列や整数に変換することです。

`ActiveModel::Conversion`モジュールは、以下のメソッドをクラスに追加します。

- `to_model`
- `to_key`
- `to_param`
- `to_partial_path`

メソッドの戻り値は、`persisted?`メソッドが定義されているかどうか、および`id`メソッドが指定されているかどうかによって異なります。
`persisted?`メソッドは、オブジェクトがデータベースまたはストアに保存されている場合は`true`を返し、それ以外の場合は`false`を返す必要があります。
`id`メソッドは、オブジェクトのIDを参照する必要があります。オブジェクトが保存されていない場合は`nil`を参照する必要があります。

```ruby
class Person
  include ActiveModel::Conversion
  attr_accessor :id

  def initialize(id)
    @id = id
  end

  def persisted?
    id.present?
  end
end
```

[`ActiveModel::Conversion`]: https://api.rubyonrails.org/classes/ActiveModel/Conversion.html

#### `to_model`

`to_model`メソッドは、そのオブジェクト自身を返します。

```irb
irb> person = Person.new(1)
irb> person.to_model == person
=> true
irb> person.to_key
=> nil
irb> person.to_param
=> nil
```

自作のモデルがActive Modelオブジェクトらしく振る舞わない場合は、`:to_model`を自分で定義する必要があります。この場合`:to_model`は、Active Modelに準拠したメソッドでオブジェクトをラップするプロキシオブジェクトを返さなければなりません。

```ruby
class Person
  def to_model
    # Active Modelに準拠したメソッドでオブジェクトをラップするプロキシオブジェクト
    PersonModel.new(self)
  end
end
```

#### `to_key`

`to_key`メソッドは、オブジェクトが永続化されているかどうかにかかわらず、いずれかの属性が設定済みであれば、オブジェクトのキー属性の配列を返します。キー属性が存在しない場合は`nil`を返します。

```irb
irb> person.to_key
=> [1]
```

NOTE: キー属性は、オブジェクトを識別するために使われる属性です。たとえば、データベースに裏付けられたモデルでは、キー属性は主キーです。

#### `to_param`

`to_param`メソッドは、URLでの利用に適したオブジェクトのキーの`string`表現を返します。
`persisted?`が`false`の場合は`nil`を返します。

```irb
irb> person.to_param
=> "1"
```

#### `to_partial_path`

`to_partial_path`メソッドは、オブジェクトに関連付けられているパスを`string`表現で返します。Action Packはこのメソッドを用いて、オブジェクトを表す適切なパーシャルを探索します。

```irb
irb> person.to_partial_path
=> "people/person"
```

### `Dirty`モジュール

[`ActiveModel::Dirty`][]モジュールは、モデル属性に加えられた変更を保存前にトラッキングするときに有用です。この機能を活用することで、どの属性が変更されたか、その以前の値と現在の値が何であるかを判断して、変更に基づいた処理を実行できるようになるので、特にアプリケーション内の監査・バリデーション、条件付きロジックで便利です。このモジュールは、Active Recordと同じような方法でオブジェクトの変更をトラッキングする方法を提供します。

あるオブジェクトが数度にわたって変更され、保存されていない状態は、「ダーティ（dirty:汚れた）」状態です。このオブジェクトでは、属性名に基づいたアクセサメソッドが利用できます。

`ActiveModel::Dirty`モジュールを利用するには、以下を実装する必要があります。

1. このモジュールをクラスに`include`します。
2. 変更をトラッキングする属性メソッドを`define_attribute_methods`で定義します。
3. トラッキングする属性を変更する直前に`属性名_will_change!`を呼び出します。
4. 変更の永続化が完了したら、`changes_applied`を呼び出します。
5. 変更情報をリセットしたい場合は、`clear_changes_information`を呼び出します。
6. 変更前のデータを復元したい場合は、`restore_attributes`を呼び出します。

これで、そのオブジェクトで`ActiveModel::Dirty`モジュールが提供するメソッドを利用して、変更が発生したすべての属性のリストや、変更された属性の元の値や、属性に加えられた変更内容を取得できるようになります。

例として、`first_name`属性と`last_name`属性を持つ以下の`Person`クラスを例に、これらの属性への変更を`ActiveModel::Dirty`モジュールでトラッキングする方法を決定してみましょう。

```ruby
class Person
  include ActiveModel::Dirty

  attr_reader :first_name, :last_name
  define_attribute_methods :first_name, :last_name

  def initialize
    @first_name = nil
    @last_name = nil
  end

  def first_name=(value)
    first_name_will_change! unless value == @first_name
    @first_name = value
  end

  def last_name=(value)
    last_name_will_change! unless value == @last_name
    @last_name = value
  end

  def save
    # データを永続化する（ダーティなデータは削除され、`changes`の内容は`previous_changes`に移動する）
    changes_applied
  end

  def reload!
    # ダーティなデータ（`changes`と`previous_changes`の内容）をすべて削除する
    clear_changes_information
  end

  def rollback!
    # 指定の属性の直前のデータをすべて復元する
    restore_attributes
  end
end
```

[`ActiveModel::Dirty`]: https://api.rubyonrails.org/classes/ActiveModel/Dirty.html

#### 変更されたすべての属性のリストをオブジェクトから直接取得する

```irb
irb> person = Person.new

# `Person`オブジェクトのインスタンス生成直後は変更された属性はない
irb> person.changed?
=> false

irb> person.first_name = "Jane Doe"
irb> person.first_name
=> "Jane Doe"
```

**`changed?`**: 1個以上の属性で変更が未保存の場合は`true`、それ以外の場合は`false`を返します。

```irb
irb> person.changed?
=> true
```

**`changed`**: 変更が保存されていない属性名のリストを配列で返します。

```irb
irb> person.changed
=> ["first_name"]
```

**`changed_attributes`**: 変更が未保存の属性名と元の値のリストをハッシュとして返します（例: `属性名 => 元の値`）。

```irb
irb> person.changed_attributes
=> {"first_name" => nil}
```

**`changes`**: 変更された属性名と「元の値と新しい値」のリストをハッシュとして返します（例: `属性名 => [元の値, 新しい値]`）。

```
irb> person.changes
=> {"first_name" => [nil, "Jane Doe"]}
```

**`previous_changes`**: モデルが保存される前（つまり`changes_applied`が呼び出される前）に変更されていた属性のリストをハッシュで返します。

```irb
irb> person.previous_changes
=> {}

irb> person.save
irb> person.previous_changes
=> {"first_name" => [nil, "Jane Doe"]}
```

#### 属性名に基づいたアクセサメソッド

```irb
irb> person = Person.new

irb> person.changed?
=> false

irb> person.first_name = "John Doe"
irb> person.first_name
=> "John Doe"
```

**`属性名_changed?`**: その属性が変更されているかどうかをチェックします。

```irb
irb> person.first_name_changed?
=> true
```

**`属性名_was`**: その属性の直前の値を返します。

```irb
irb> person.first_name_was
=> nil
```

**`属性名_change`**: その属性が変更されていれば、属性の「変更直前の値」と「現在の値」を`[元の値, 新しい値]`という配列で返し、変更がない場合は`nil`を返します。

```irb
irb> person.first_name_change
=> [nil, "John Doe"]
irb> person.last_name_change
=> nil
```

**`属性名_previously_changed?`**: その属性が、モデルの保存前（つまり`changes_applied`が呼び出される前）に変更されていたかどうかをチェックします。

```irb
irb> person.first_name_previously_changed?
=> false
irb> person.save
irb> person.first_name_previously_changed?
=> true
```

**`属性名_previous_change`**: その属性がモデルの保存前（つまり`changes_applied`が呼び出される前）に変更されていれば、属性の「変更直前の値」と「現在の値」を`[元の値, 新しい値]`という配列で返し、それ以外の場合は`nil`を返します。

```irb
irb> person.first_name_previous_change
=> [nil, "John Doe"]
```

### `Naming`モジュール

[`ActiveModel::Naming`][]モジュールは、命名やルーティングの管理を行いやすくするクラスメソッドとヘルパーメソッドを追加します。このモジュールが定義する`model_name`クラスメソッドは、[`ActiveSupport::Inflector`][]のメソッドを活用してさまざまなアクセサを定義します。

```ruby
class Person
  extend ActiveModel::Naming
end
```

**`name`**: そのモデルの名前を返します。

```irb
irb> Person.model_name.name
=> "Person"
```

**`singular`**: レコードやクラスのクラス名を単数形で返します。

```irb
irb> Person.model_name.singular
=> "person"
```

**`plural`**: レコードやクラスのクラス名を複数形で返します。

```irb
irb> Person.model_name.plural
=> "people"
```

**`element`**: 名前空間を除いたsnake_case形式の名前（単数形）を返します。このメソッドは、Action PackやAction Viewのヘルパーがパーシャルやフォームの名前でレンダリングするときに使われます。

```irb
irb> Person.model_name.element
=> "person"
```

**`human`**: 国際化（I18n）に基づいてモデル名をより人間に分かりやすい形式に変換します。デフォルトでは、クラス名をアンダースコアで区切ってから[`humanize`](active_support_core_extensions.html#humanize)します。

```irb
irb> Person.model_name.human
=> "Person"
```

**`collection`**: 名前空間を除いたsnake_case形式の名前（複数形）を返します。このメソッドは、Action PackやAction Viewのヘルパーがパーシャルやフォームの名前でレンダリングするときに使われます。

```irb
irb> Person.model_name.collection
=> "people"
```

**`param_key`**: パラメータ名として利用できる文字列を返します。

```irb
irb> Person.model_name.param_key
=> "person"
```

**`i18n_key`**: I18nで使う訳文のキー名を返します。モデル名をsnake_case化したものをシンボルとして返します。

```irb
irb> Person.model_name.i18n_key
=> :person
```

**`route_key`**: ルーティング名の生成で利用できる文字列を返します。

```irb
irb> Person.model_name.route_key
=> "people"
```

**`singular_route_key`**: ルーティング名の生成で利用できる文字列を単数形で返します。

```irb
irb> Person.model_name.singular_route_key
=> "person"
```

**`uncountable?`**: レコードやクラスのクラス名が不可算名詞かどうかを判定します。

```irb
irb> Person.model_name.uncountable?
=> false
```

NOTE: 分離された[Railsエンジン](engines.html)内では、`Naming`の一部のメソッド（`param_key`、`route_key`、`singular_route_key`など）におけるモデルの名前空間が異なります。

[`ActiveModel::Naming`]: https://api.rubyonrails.org/classes/ActiveModel/Naming.html
[`ActiveSupport::Inflector`]: https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html

#### モデル名をカスタマイズする

フォームヘルパーやURL生成で使われるモデル名を別の名前に変更したい場合があります。これは、モデルを完全な名前空間で参照可能にしながら、モデル名をさらに使いやすくしたい場合に便利です。

たとえば、Railsアプリケーションに`person`名前空間があり、新しい`person::Profile`のフォームを作成したいとします。

デフォルトのRailsは、名前空間`person`を含む`/person/profiles`というURLでフォームを生成します。ただし、URLで名前空間を含まない`profiles`を指すようにしたい場合は、`model_name`メソッドを次のようにカスタマイズできます。

```ruby
module Person
  class Profile
    include ActiveModel::Model

    def self.model_name
      ActiveModel::Name.new(self, nil, "Profile")
    end
  end
end
```

上のセットアップでは、新しい`person::Profile`を作成するためのフォームを`form_with`ヘルパーで作成すると、`/person/profiles`というURLではなく`/profiles`というURLを持つフォームが生成されます（`model_name`メソッドが`Profile`を返すようにオーバーライドされたため）。

さらに、パスヘルパーが名前空間なしで生成されるので、`person_profiles_path`の代わりに`profiles_path` で`profiles`リソースのURLを生成できます。`profiles_path`ヘルパーを利用可能にするには、`config/routes.rb`ファイルで`person::Profile`モデルのルーティングを以下のように定義する必要があります。

```ruby
Rails.application.routes.draw do
  resources :profiles
end
```

これで、前のセクションで説明したメソッドに対してモデルが次の値を返すようになります。

```irb
irb> name = ActiveModel::Name.new(Person::Profile, nil, "Profile")
=> #<ActiveModel::Name:0x000000014c5dbae0

irb> name.singular
=> "profile"
irb> name.singular_route_key
=> "profile"
irb> name.route_key
=> "profiles"
```

### `SecurePassword`モジュール

[`ActiveModel::SecurePassword`][]モジュールは、あらゆるパスワードを暗号化された形式で安全に保存する方法を提供します。このモジュールを`include`すると`has_secure_password`クラスメソッドが提供され、デフォルトで特定の検証を伴う`password`アクセサを定義します。

`ActiveModel::SecurePassword`は[`bcrypt`](https://github.com/bcrypt-ruby/bcrypt-ruby 'BCrypt')に依存しているため、利用する場合は以下のようにこのgemを`Gemfile`に追加してください。

```ruby
gem "bcrypt"
```

`ActiveModel::SecurePassword`を利用する場合は、`password_digest`属性が必要です。

以下のバリデーションは自動的に追加されます。

1. 作成時にパスワードが存在していること。
2. パスワードが（`XXX_confirmation`で渡された）パスワード確認入力と等しいこと
3. パスワードの最大長は72バイトであること（`bcrypt`は暗号化の前に文字列をこの長さに切り詰めるため）。

NOTE: パスワードの確認が不要な場合は、`password_confirmation`属性の値はそのままにしておいてください（つまりパスワード確認用のフィールドをフォームに置かない）。この属性の値が`nil`の場合はバリデーションされません。

さらなるカスタマイズ方法として、引数に`validations: false`オプションを渡すことでデフォルトのバリデーションを抑制することも可能です。

```ruby
class Person
  include ActiveModel::SecurePassword

  has_secure_password
  has_secure_password :recovery_password, validations: false

  attr_accessor :password_digest, :recovery_password_digest
end
```

```irb
irb> person = Person.new

# パスワードが存在しない場合
irb> person.valid?
=> false

# パスワード確認がパスワードと一致しない場合
irb> person.password = "aditya"
irb> person.password_confirmation = "nomatch"
irb> person.valid?
=> false

# パスワードが72バイトを超えた場合
irb> person.password = person.password_confirmation = "a" * 100
irb> person.valid?
=> false

# passwordのみが入力され、password_confirmationが入力されなかった場合
irb> person.password = "aditya"
irb> person.valid?
=> true

# すべてのバリデーションがパスした場合
irb> person.password = person.password_confirmation = "aditya"
irb> person.valid?
=> true

irb> person.recovery_password = "42password"

# `authenticate`は`authenticate_password`のエイリアス
irb> person.authenticate("aditya")
=> #<Person> # == person
irb> person.authenticate("notright")
=> false
irb> person.authenticate_password("aditya")
=> #<Person> # == person
irb> person.authenticate_password("notright")
=> false

irb> person.authenticate_recovery_password("aditya")
=> false
irb> person.authenticate_recovery_password("42password")
=> #<Person> # == person
irb> person.authenticate_recovery_password("notright")
=> false

irb> person.password_digest
=> "$2a$04$gF8RfZdoXHvyTjHhiU4ZsO.kQqV9oonYZu31PRE4hLQn3xM2qkpIy"
irb> person.recovery_password_digest
=> "$2a$04$iOfhwahFymCs5weB3BNH/uXkTG65HR.qpW.bNhEjFP3ftli3o5DQC"
```

[`ActiveModel::SecurePassword`]: https://api.rubyonrails.org/classes/ActiveModel/SecurePassword.html

### `Serialization`モジュール

[`ActiveModel::Serialization`][]モジュールはオブジェクトの基本的なシリアライズ機能を提供します。この機能を利用するには、シリアライズする属性を含む属性ハッシュを宣言する必要があります。また、属性はシンボルリテラル（`:name`など）ではなく文字列リテラル（`"name"`など）で記述しなければならない点にご注意ください。

```ruby
class Person
  include ActiveModel::Serialization

  attr_accessor :name, :age

  def attributes
    # シリアライズする属性を宣言する
    { "name" => nil, "age" => nil }
  end

  def capitalized_name
    # 宣言したメソッドは後からシリアライズ済みハッシュにinclude可能
    name&.capitalize
  end
end
```

これで、`serializable_hash`メソッドでオブジェクトのシリアライズ済みハッシュにアクセス可能になります。`serializable_hash`メソッドの有効なオプションには、`:only`、`:except`、`:methods`、および `:include`が含まれます。

```irb
irb> person = Person.new

irb> person.serializable_hash
=> {"name" => nil, "age" => nil}

# name属性とage属性を設定してオブジェクトをシリアライズする
irb> person.name = "bob"
irb> person.age = 22
irb> person.serializable_hash
=> {"name" => "bob", "age" => 22}

# capitalized_nameメソッドをincludeするにはmethodsオプションを使う
irb>  person.serializable_hash(methods: :capitalized_name)
=> {"name" => "bob", "age" => 22, "capitalized_name" => "Bob"}

# name属性だけを含めたい場合はonlyオプションを使う
irb> person.serializable_hash(only: :name)
=> {"name" => "bob"}

# name属性だけを除外したい場合はexceptオプションを使う
irb> person.serializable_hash(except: :name)
=> {"age" => 22}
```

`includes`オプションの利用例については、以下に定義されているように、もう少し複雑なシナリオが必要です。

```ruby
  class Person
    include ActiveModel::Serialization
    attr_accessor :name, :notes # `has_many :notes`をエミュレーションする

    def attributes
      { "name" => nil }
    end
  end

  class Note
    include ActiveModel::Serialization
    attr_accessor :title, :text

    def attributes
      { "title" => nil, "text" => nil }
    end
  end
```

```irb
irb> note = Note.new
irb> note.title = "Weekend Plans"
irb> note.text = "Some text here"

irb> person = Person.new
irb> person.name = "Napoleon"
irb> person.notes = [note]

irb> person.serializable_hash
=> {"name" => "Napoleon"}

irb> person.serializable_hash(include: { notes: { only: "title" }})
=> {"name" => "Napoleon", "notes" => [{"title" => "Weekend Plans"}]}
```

[`ActiveModel::Serialization`]: https://api.rubyonrails.org/classes/ActiveModel/Serialization.html

#### `ActiveModel::Serializers::JSON`モジュール

Active Modelは、JSONシリアライズ/デシリアライズ用の[`ActiveModel::Serializers::JSON`][]モジュールも提供しています。

JSONシリアライズを利用するには、`include`するモジュールを`ActiveModel::Serialization`から`ActiveModel::Serializers::JSON`に変更します。前者は既に`include`済みなので、明示的に`include`する必要はありません。

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes
    { "name" => nil }
  end
end
```

`as_json`メソッドは、`serializable_hash`と同様に、モデルを表すハッシュ（キーは文字列）を提供します。
`to_json`メソッドは、モデルを表すJSON文字列を返します。

```irb
irb> person = Person.new

# モデルを表すハッシュを返す（キーは文字列）
irb> person.as_json
=> {"name" => nil}

# モデルを表すJSON文字列を返す
irb> person.to_json
=> "{\"name\":null}"

irb> person.name = "Bob"
irb> person.as_json
=> {"name" => "Bob"}

irb> person.to_json
=> "{\"name\":\"Bob\"}"
```

JSON文字列を元にモデルの属性を定義することも可能です。これを行うには、まずクラスで`attributes=`メソッドを定義します。

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes=(hash)
    hash.each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def attributes
    { "name" => nil }
  end
end
```

これで、以下のように`person`のインスタンスを作成して`from_json`で属性を設定できます。

```irb
irb> json = { name: "Bob" }.to_json
=> "{\"name\":\"Bob\"}"

irb> person = Person.new

irb> person.from_json(json)
=> #<Person:0x00000100c773f0 @name="Bob">

irb> person.name
=> "Bob"
```

[`ActiveModel::Serializers::JSON`]: https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html

### `Translation`モジュール

[`ActiveModel::Translation`][]モジュールは、オブジェクトを[Railsの国際化（I18n）フレームワーク](i18n.html)と統合します。

```ruby
class Person
  extend ActiveModel::Translation
end
```

`human_attribute_name`メソッドを使用すると、属性名を人間が読みやすい形式に変換できます。人間用のフォーマットはロケールファイルで定義されます。

```yaml
# config/locales/app.pt-BR.yml
pt-BR:
  activemodel:
    attributes:
      person:
        name: "Nome"
```

```irb
irb> Person.human_attribute_name("name")
=> "Name"

irb> I18n.locale = :"pt-BR"
=> :"pt-BR"
irb> Person.human_attribute_name("name")
=> "Nome"
```

[`ActiveModel::Translation`]: https://api.rubyonrails.org/classes/ActiveModel/Translation.html


### `Validations`モジュール

[`ActiveModel::Validations`][]モジュールは、オブジェクトをバリデーション（検証）する機能を追加します。バリデーションは、アプリケーション内のデータの整合性と一貫性を確保するために重要です。バリデーションをモデルに組み込むことで、属性値の正確性を管理するルールを定義して、無効なデータの発生を防げるようになります。

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates! :token, presence: true
end
```

```irb
irb> person = Person.new
irb> person.token = "2b1f325"
irb> person.valid?
=> false

irb> person.name = "Jane Doe"
irb> person.email = "me"
irb> person.valid?
=> false

irb> person.email = "jane.doe@gmail.com"
irb> person.valid?
=> true

# `token`は未設定の場合に例外を発生する（validate!メソッドを利用）
irb> person.token = nil
irb> person.valid?
=> "Token can't be blank (ActiveModel::StrictValidationFailed)"
```

[`ActiveModel::Validations`]: https://api.rubyonrails.org/classes/ActiveModel/Validations.html

#### バリデーション用メソッドとオプション

以下のいくつかのメソッドを利用してバリデーションを追加できます。

- [`validate`][]:
  バリデーションをメソッドまたはブロックの形でクラスに追加します。

- [`validates`][]:
  `validates`メソッドに属性を渡すことで、すべてのデフォルトバリデータをショートカットで利用できます。

- [`validates!`][]（または`strict: true`オプションを指定）:
  エンドユーザー側で修正できない特殊なバリデーションを定義するのに使われます。バリデーションメソッドに`!`または`strict: true`を指定すると、バリデーション失敗時にエラーを追加するのではなく、常に`ActiveModel::StrictValidationFailed`をraiseします。

- [`validates_with`][]:
  指定のクラス（複数可）にレコードを渡して、より複雑な条件に基づいてエラーを追加できます。

- [`validates_each`][]:
  渡したブロックで個別の属性をバリデーションします。

以下のオプションの中には、特定のバリデータでしか利用できないものもあります。オプションが特定のバリデータで利用できるかどうかを判断するには、[バリデーションのAPIドキュメント][]を参照してください。

- `:on`:
  バリデーションを追加するコンテキストを指定します。引数にはシンボルまたはシンボルの配列を渡せます（例: `on: :create`、`on: :custom_validation_context`、`on: [:create, :custom_validation_context]`）。
  バリデーションで`:on`オプションを指定しない場合は、コンテキストと無関係に実行されます。
  `:on`オプションを指定したバリデーションは、指定されたコンテキストでのみ実行されます。
  バリデーションには`valid?(:context)`でコンテキストを渡せます。

- `:if`:
  バリデーションを実行するかどうかを決定するために呼び出すメソッド、`proc`、または文字列を指定します（例:  `if: :allow_validation`、`if: -> {signup_step > 2 }`）。
  渡すメソッド、proc、または文字列は、`true`または`false`値を返すか、`true`または`false`のいずれかに評価される必要があります。

- `:unless`:
  バリデーションを実行するかどうかを決定するために呼び出すメソッド、`proc`、または文字列を指定します（例:  `unless: :skip_validation`、`unless: Proc.new { |user| user.signup_step <= 2 }`）。
  渡すメソッド、proc、または文字列は、`true`または`false`値を返すか、`true`または`false`のいずれかに評価される必要があります。

- `:allow_nil`:
  属性が`nil`の場合にバリデーションをスキップします。

- `:allow_blank`:
  属性が空の場合にバリデーションをスキップします。

- `:strict`:
  `:strict: true`オプションを設定している場合、エラーを追加する代わりに`ActiveModel::StrictValidationFailed`をraiseします。`:strict`オプションに他の例外を設定することも可能です。

NOTE: `validate`を同じメソッドで複数回呼び出すと、以前の定義が上書きされます。

[`validate`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validate
[`validates`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates
[`validates!`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates-2
[`validates_with`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_with
[`validates_each`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates_each
[バリデーションのAPIドキュメント]: https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html

#### `Errors`モジュール

`ActiveModel::Validations`モジュールは、このモジュールを`include`したクラスのインスタンスに対して、`errors`メソッドを自動的に追加し、さらに、[`ActiveModel::Errors`][]の新しいオブジェクトを自動的に用意します。したがって、これらの処理を手動で行う必要はありません。

オブジェクトが有効かどうかを確認するには、オブジェクトに対して`valid?`を実行します。オブジェクトが有効でない場合は`false`が返され、エラーが`errors`オブジェクトに追加されます。

```irb
irb> person = Person.new

irb> person.email = "me"
irb> person.valid?
=> # Raises Token can't be blank (ActiveModel::StrictValidationFailed)

irb> person.errors.to_hash
=> {:name => ["can't be blank"], :email => ["is invalid"]}

irb> person.errors.full_messages
=> ["Name can't be blank", "Email is invalid"]
```

[`ActiveModel::Errors`]: https://api.rubyonrails.org/classes/ActiveModel/Errors.html

### `Lint::Tests`モジュール

[`ActiveModel::Lint::Tests`][]モジュールを利用することで、オブジェクトがActive Model APIに準拠しているかどうかをテストできます。TestCaseに`ActiveModel::Lint::Tests`を`include`すれば、オブジェクトがActive Model APIに完全に準拠しているかどうか、準拠していない場合はAPIのどの側面が実装されていないのかを示すテストが組み込まれます。

これらのテストは、戻り値の意味が正しいかどうかを判定するものではありません。たとえば、常に`true`を返すように`valid?`を実装すればテストはパスしますが、APIとしては無意味です。意味のある値を返すようにするのは、API開発者の責任です。

渡すオブジェクトは、`to_model`を呼び出したときに準拠済みオブジェクトを返すことが期待されます。`to_model`が`self`を返すのはまったく問題ありません。

* `app/models/person.rb`

    ```ruby
    class Person
      include ActiveModel::API
    end
    ```

* `test/models/person_test.rb`

    ```ruby
    require "test_helper"

    class PersonTest < ActiveSupport::TestCase
      include ActiveModel::Lint::Tests

      setup do
        @model = Person.new
      end
    end
    ```

これらのテストメソッドは、APIドキュメントの[`ActiveModel::Lint::Tests`][]に記載されています。

このテストは、以下のコマンドで実行できます。

```bash
$ bin/rails test

Run options: --seed 14596

# Running:

......

Finished in 0.024899s, 240.9735 runs/s, 1204.8677 assertions/s.

6 runs, 30 assertions, 0 failures, 0 errors, 0 skips
```

[`ActiveModel::Lint::Tests`]: https://api.rubyonrails.org/classes/ActiveModel/Lint/Tests.html
