
Active Model の基礎
===================

このガイドでは、モデルクラスを使用して作業を開始するのに必要なことをすべて解説します。Action Packヘルパーは、Active Modelのおかげで非Active Recordモデルとやりとりすることができます。Active Modelを使用することで、カスタムのORM (オブジェクトリレーショナルマッピング) を作成してRailsフレームワークの外で使用することもできます。

このガイドの内容:

* Active Recordモデルの振る舞い
* コールバックやバリデーションのしくみ
* シリアライザのしくみ
* Active ModelとRails国際化（i18n）フレームワークの統合方法

--------------------------------------------------------------------------------

はじめに
------------

Active Modelは多くのモジュールを含むライブラリであり、それらのモジュールはRailsのAction Packライブラリとやりとりする必要のあるフレームワークで使用されます。Active Modelは、クラスで使用する既知の一連のインターフェイスを提供します。そのうちのいくつかについて以下で説明します。

### AttributeMethodsモジュール

AttributeMethodsモジュールは、クラスのメソッドにカスタムのプレフィックスやサフィックスを追加できます。このモジュールを使用するには、プレフィックスまたはサフィックスを定義し、オブジェクト内にあるプレフィックス/サフィックスの追加対象となるメソッドを指定します。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_prefix 'reset_'
  attribute_method_suffix '_highest?'
  define_attribute_methods 'age'

  attr_accessor :age

    private
    def reset_attribute(attribute)
      send("#{attribute}=", 0)
    end

    def attribute_highest?(attribute)
      send(attribute) > 100
    end
end

person = Person.new
person.age = 110
person.age_highest?  # true
person.reset_age     # 0
person.age_highest?  # false
```

### Callbacksモジュール

Callbacksを使用することで、Active Recordスタイルのコールバックを使用できます。これにより、必要なタイミングで実行されるコールバックを定義することができるようになります。コールバックの定義後、それらをカスタムメソッドの実行前(before)、実行後(after)、あるいは実行中(around)にラップすることができます。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me

  def update
    run_callbacks(:update) do
      # updateメソッドがオブジェクトに対して呼び出されるとこのメソッドが呼び出される
    end
  end

  def reset_me
    # このメソッドは、before_updateコールバックで定義されているとおり、updateメソッドがオブジェクトに対して呼び出される直前に呼び出される。
  end
end
```

### Conversionモジュール

クラスで`persisted?`メソッドと`id`メソッドが定義されていれば、この`Conversion`モジュールをインクルードしてRailsの変換メソッドをそのクラスのオブジェクトに対して呼び出すことができます。

```ruby
class Person
  include ActiveModel::Conversion

  def persisted?
    false
  end

  def id
    nil
  end
end

person = Person.new
person.to_model == person  # => true
person.to_key              # => nil
person.to_param            # => nil
```

### Dirtyモジュール

あるオブジェクトが数度にわたって変更され、保存されていない状態は、「汚れた (dirty)」状態です。このモジュールを使用して、オブジェクトで変更が生じたかどうかを検出できます。属性名に基づいたアクセサメソッドも使用できます。`first_name`属性と`last_name`を持つPersonというクラスを例に考えてみましょう。

```ruby
require 'active_model'

class Person
  include ActiveModel::Dirty
  define_attribute_methods :first_name, :last_name

  def first_name
    @first_name
  end

  def first_name=(value)
    first_name_will_change!
    @first_name = value
  end

  def last_name
    @last_name
  end

  def last_name=(value)
    last_name_will_change!
    @last_name = value
  end

  def save
    # 保存を実行
    changes_applied
  end
end
```

#### 変更されたすべての属性のリストをオブジェクトから直接取得する

```ruby
person = Person.new
person.changed? # => false 

person.first_name = "First Name"
person.first_name # => "First Name"

# 属性が1つ以上変更されている場合にtrueを返す
person.changed? # => true

# 保存前に変更された属性のリストを返す
person.changed # => ["first_name"]

# 元の値から変更された属性のハッシュを返す
person.changed_attributes # => {"first_name"=>nil}

# 変更のハッシュを返す (ハッシュのキーは属性名、ハッシュの値はフィールドの新旧の値の配列
person.changes # => {"first_name"=>[nil, "First Name"]}
```

#### 属性名に基づいたアクセサメソッド

特定の属性が変更されたかどうかを検出します。

```ruby
# attr_name_changed?
person.first_name # => "First Name"
person.first_name_changed? # => true
```

その属性の直前の値を返します。

```ruby
# attr_name_was accessor
person.first_name_was # => "First Name"
```

変更された属性の、直前の値と現在の値を両方返します。変更があった場合は配列を返し、変更がなかった場合はnilを返します。

```ruby
# attr_name_change
person.first_name_change # => [nil, "First Name"]
person.last_name_change # => nil
```

### `Validations`モジュール

`ActiveModel::Validations`モジュールを使用することで、クラスオブジェクトをActive Recordスタイルで検証することができます。

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates_format_of :email, with: /\A([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})\z/i
  validates! :token, presence: true
end

person = Person.new(token: "2b1f325")
person.valid? # => false 
person.name = 'vishnu'
person.email = 'me'
person.valid? # => false 
person.email = 'me@vishnuatrai.com'
person.valid? # => true
person.token = nil
person.valid? # => ActiveModel::StrictValidationFailedが発生する
```

### `Naming`モジュール

`ActiveModel::Naming`は、命名やルーティングの管理を支援するクラスメソッドを多数追加します。このモジュールが定義する`model_name`クラスメソッドは、`ActiveSupport::Inflector`メソッドの一部を用いて多くのアクセサを定義します。

```ruby
class Person
  extend ActiveModel::Naming
end

Person.model_name.name                # => "Person"
Person.model_name.singular            # => "person"
Person.model_name.plural              # => "people"
Person.model_name.element             # => "person"
Person.model_name.human               # => "Person"
Person.model_name.collection          # => "people"
Person.model_name.param_key           # => "person"
Person.model_name.i18n_key            # => :person
Person.model_name.route_key           # => "people"
Person.model_name.singular_route_key  # => "person"
```

### `Model`モジュール

`ActiveModel::Model`は、Action PackやAction Viewと連携する機能をクラスに追加してすぐに使えるようにします。

```ruby
class EmailContact
  include ActiveModel::Model

  attr_accessor :name, :email, :message
  validates :name, :email, :message, presence: true

  def deliver
    if valid?
      # deliver email
    end
  end
end
```

`ActiveModel::Model`を`include`すると、以下のような機能が使えるようになります。

- モデル名の調査
- 変換
- 翻訳
- バリデーション

Active Recordの場合と同じような方法で、オブジェクトを属性のハッシュで初期化することもできるようになります。


```ruby
email_contact = EmailContact.new(name: 'David',
                                 email: 'david@example.com',
                                 message: 'Hello World')
email_contact.name       # => 'David'
email_contact.email      # => 'david@example.com'
email_contact.valid?     # => true
email_contact.persisted? # => false
```

`ActiveModel::Model`を`include`するクラスでは、Active Recordの場合と同様に`form_for`や`render`などのAction Viewヘルパーメソッドを使えるようになります。

### シリアライズ

`ActiveModel::Serialization`は、オブジェクトに基本的なシリアライズ機能を提供します。シリアライズの対象となる属性を含む属性ハッシュを1つ宣言する必要があります。属性は文字列でなければならず、シンボルは使えません。

```ruby
class Person
  include ActiveModel::Serialization

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

上のようにすることで、`serializable_hash`を使ってオブジェクトのシリアライズ化ハッシュにアクセスできるようになります。

```ruby
person = Person.new
person.serializable_hash   # => {"name"=>nil}
person.name = "Bob"
person.serializable_hash   # => {"name"=>"Bob"}
```

#### `ActiveModel::Serializers`モジュール

Active Modelは、JSONシリアライズ/デシリアライズ用の`ActiveModel::Serializers::JSON`モジュールも提供しています。このモジュールは前述の`ActiveModel::Serialization`モジュールを自動で`include`します。

##### `ActiveModel::Serializers::JSON`

`include`するモジュールを`ActiveModel::Serialization`から`ActiveModel::Serializers::JSON`に変更するだけで`ActiveModel::Serializers::JSON`を使えるようになります。

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

`serializable_hash`と似ている`as_json`メソッドは、モデルを表現するハッシュ形式を提供します。

```ruby
person = Person.new
person.as_json # => {"name"=>nil}
person.name = "Bob"
person.as_json # => {"name"=>"Bob"}
```

JSON文字列を元にモデルの属性を定義することもできます。ただし、そのクラスに`attributes=`メソッドを定義しておく必要があります。

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    {'name' => nil}
  end
end
```

上のようにすることで、`Person`のインスタンスを作成して`from_json`で属性を設定できるようになります。

```ruby
json = { name: 'Bob' }.to_json
person = Person.new
person.from_json(json) # => #<Person:0x00000100c773f0 @name="Bob">
person.name            # => "Bob"
```

### `Translation`モジュール

`ActiveModel::Translation`は、オブジェクトとRails国際化（i18n）フレームワーク間の統合機能を提供します。

```ruby
class Person
  extend ActiveModel::Translation
end
```

`human_attribute_name`メソッドを使って属性名を人間にとって読みやすい形式に変換できます。人間が読むための形式は独自のロケールファイルで定義します。

* config/locales/app.pt-BR.yml

```yml
pt-BR:
  activemodel:
    attributes:
      person:
        name: 'Nome'
```

```ruby
Person.human_attribute_name('name') # => "Nome"
```

### Lintテスト

`ActiveModel::Lint::Tests`を用いて、オブジェクトがActive Model APIに準拠しているかどうかをテストできます。

* `app/models/person.rb`

```ruby
class Person
  include ActiveModel::Model
end
```

* `test/models/person_test.rb`

```ruby
require 'test_helper'
  class PersonTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  setup do
    @model = Person.new
  end
end
```

```bash
$ rails test

Run options: --seed 14596

# Running:

......

Finished in 0.024899s, 240.9735 runs/s, 1204.8677 assertions/s.

6 runs, 30 assertions, 0 failures, 0 errors, 0 skips
```

オブジェクトがAction Packと協調するためにAPIをすべて実装することが要求されているわけではありません。このモジュールは、すぐに使える機能をすべて揃えておきたい場合のガイダンスを提供することを意図しているに過ぎません。

### `SecurePassword`モジュール

`ActiveModel::SecurePassword`は、任意のパスワードを暗号化して安全に保存する手段を提供します。このモジュールを`include`すると、バリデーション機能を備えた`password`アクセサを定義する`has_secure_password`クラスメソッドが提供されます。

#### 必要条件

`ActiveModel::SecurePassword`モジュールは[`bcrypt`](https://github.com/codahale/bcrypt-ruby 'BCrypt') gemに依存しているので、`ActiveModel::SecurePassword`を正しく使うにはこのgemを`Gemfile`に含める必要があります。モジュールが機能するには、モデルに`password_digest`という名前のアクセサがなくてはなりません。`has_secure_password`は`password`アクセサに以下のバリデーションを追加します。

1. パスワードが存在すること
2. パスワードが（`password_confirmation`で渡された）パスワード確認入力と等しいこと
3. パスワードの最大長が72文字以下であること（`ActiveModel::SecurePassword`が依存している`bcrypt`による要求）

#### 例

```ruby
class Person
  include ActiveModel::SecurePassword
  has_secure_password
  attr_accessor :password_digest
end

person = Person.new

# パスワードが空の場合
person.valid? # => false

# パスワード確認入力がパスワードと一致しない場合
person.password = 'aditya'
person.password_confirmation = 'nomatch'
person.valid? # => false

# パスワードが72文字を超えた場合
person.password = person.password_confirmation = 'a' * 100
person.valid? # => false

# パスワードだけがありパスワード確認入力がない場合
person.password = 'aditya'
person.valid? # => true

# すべてのバリデーションをパスした場合
person.password = person.password_confirmation = 'aditya'
person.valid? # => true
```