
Active Model の基礎
===================

このガイドでは、モデルクラスを使用して作業を開始するのに必要なことをすべて解説します。Action Packヘルパーは、Active Modelのおかげで非Active Recordモデルとやりとりすることができます。Active Modelを使用することで、カスタムのORM (オブジェクトリレーショナルマッピング) を作成してRailsフレームワークの外で使用することもできます。



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

# 属性が1つ以上変更されている場合に返す
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

### Validationsモジュール

Validationsモジュールを使用することで、クラスオブジェクトをActive Recordスタイルで検証することができます。

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