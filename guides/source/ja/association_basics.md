
Active Record の関連付け (アソシエーション)
==========================

このガイドでは、Active Recordの関連付け機能(アソシエーション)について解説します。

このガイドの内容:

* Active Recordのモデル同士の関連付けを宣言する方法
* Active Recordのモデルを関連付けるさまざまな方法
* 関連付けを作成すると自動的に追加されるメソッドの使用方法

--------------------------------------------------------------------------------

関連付けを使用する理由
-----------------

モデルとモデルの間には関連付けを行なう必要がありますが、その理由を御存じでしょうか。関連付けを行なうのは、それによってコード内で一般的に行われる操作をはるかに簡単にできるからです。簡単なRailsアプリケーションを例にとって説明しましょう。このアプリケーションには顧客用のモデル(Customer)と注文用のモデル(Order)があります。一人の顧客は、多くの注文を行なうことができます。関連付けを設定していない状態では、モデルの宣言は以下のようになります。

```ruby
class Customer < ActiveRecord::Base
end

class Order < ActiveRecord::Base
end
```

ここで、既存の顧客のために新しい注文を1つ追加したくなったとします。この場合、以下のようなコードを実行する必要があるでしょう。

```ruby
@order = Order.create(order_date: Time.now, customer_id: @customer.id)
```

今度は顧客を削除する場合を考えてみましょう。顧客を削除するなら、以下のように、顧客の注文も残らず削除されるようにしておかなければなりません。

```ruby
@orders = Order.where(customer_id: @customer.id)
@orders.each do |order|
  order.destroy
end
@customer.destroy
```

Active Recordの関連付け機能を使用すると、2つのモデルの間につながりがあることを明示的にRailsに対して宣言することができ、それによってモデルの操作を一貫させることができます。顧客と注文を設定するコードを次のように書き直します。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :destroy
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

上のように関連付けを追加したことで、特定の顧客用に新しい注文を1つ作成する作業が以下のように一行でできるようになりました。

```ruby
@order = @customer.orders.create(order_date: Time.now)
```

顧客と、顧客の注文をまとめて削除する作業はさらに簡単です。

```ruby
@customer.destroy
```

その他の関連付け方法については、次の節をお読みください。それに続いて、関連付けに関するさまざまなヒントや活用方法、Railsの関連付けメソッドとオプションの完全な参照物もご紹介します。

関連付けの種類
-------------------------

Railsでは、「関連付け(アソシエーション: association)」とは2つのActive Recordモデル同士のつながりを指します。関連付けは、一種のマクロ的な呼び出しとして実装されており、これによってモデル間の関連付けを宣言的に追加することができます。たとえば、あるモデルが他のモデルに従属している(`belongs_to`)と宣言すると、2つのモデルのそれぞれのインスタンス間で「主キー - 外部キー」情報を保持しておくようにRailsに指示が伝わります。Railsでサポートされている関連付けは以下の6種類です。

* `belongs_to`
* `has_one`
* `has_many`
* `has_many :through`
* `has_one :through`
* `has_and_belongs_to_many`

本ガイドではこの後、それぞれの関連付けの宣言方法と使用方法について詳しく解説します。その前に、それぞれの関連付けが適切となる状況について簡単にご紹介しましょう。

### `belongs_to`関連付け

あるモデルで`belongs_to`関連付けを行なうと、他方のモデルとの間に「1対1」のつながりが設定されます。このとき、宣言を行ったモデルのすべてのインスタンスは、他方のモデルのインスタンスに「従属(belongs to)」します。たとえば、Railsアプリケーションに顧客(customer)と注文(order)情報が含まれており、1つの注文につき正確に1人の顧客だけを割り当てたいのであれば、Orderモデルで以下のように宣言します。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

![belongs_to 関連付けの図](images/belongs_to.png)

NOTE: `belongs_to`関連付けで指定するモデル名は必ず「単数形」にしなければなりません。上の場合、`Order`モデルにおける関連付けの`customer`を複数形の`customers`にしてしまうと、"uninitialized constant Order::Customers" エラーが発生します。Railsは、関連付けの名前から自動的にモデルのクラス名を推測します。関連付け名が`customer`ならクラス名を`Customer`と推測します。従って、関連付け名が誤って複数形になってしまっていると、そこから推測されるクラス名も誤って複数形になってしまいます。

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :customers do |t| 
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_one`関連付け

`has_one`関連付けも、他方のモデルとの間に1対1の関連付けを設定します。しかし、その意味と結果は`belongs_to`とは若干異なります。`has_one`関連付けの場合は、その宣言が行われているモデルのインスタンスが、他方のモデルのインスタンスを「まるごと含んでいる」または「所有している」ことを示します。たとえば、供給者(supplier)1人につきアカウント(account)を1つだけ持つという関係があるのであれば、以下のように宣言を行います。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

![has_one関連付けの図](images/has_one.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end
  end
end
```

### `has_many`関連付け

`has_many`関連付けは、他のモデルとの間に「1対多」のつながりがあることを示します。`has_many`関連付けが使用されている場合、「反対側」のモデルでは`belongs_to`が使用されることが多くあります。`has_many`関連付けが使用されている場合、そのモデルのインスタンスは、反対側のモデルの「0個以上の」インスタンスを所有します。たとえば、顧客(customer)と注文(order)を含むRailsアプリケーションでは、顧客のモデルを以下のように宣言することができます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: `has_many`関連付けを宣言する場合、相手のモデル名は「複数形」にする必要があります。

![has_many関連付けの図](images/has_many.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t| 
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_many :through`関連付け

`has_many :through`関連付けは、他方のモデルと「多対多」のつながりを設定する場合によく使われます。この関連付けは、2つのモデルの間に「第3のモデル」(結合モデル)が介在する点が特徴です。それによって、相手モデルの「0個以上」のインスタンスとマッチします。たとえば、患者(patient)が医師(physician)との診察予約(appointment)を取る医療業務を考えてみます。この場合、関連付けは次のような感じになるでしょう。

```ruby
class Physician < ActiveRecord::Base
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ActiveRecord::Base
  belongs_to :physician
  belongs_to :patient
end

class Patient < ActiveRecord::Base 
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

![has_many :through関連付けの図](images/has_many_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :physicians do |t|
      t.string :name
      t.timestamps
    end

    create_table :patients do |t|
      t.string :name
      t.timestamps
    end

    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

結合モデル(join model)のコレクションは、API経由で管理できます。たとえば、以下のような割り当てを実行したとします。

```ruby
physician.patients = patients
```

このとき、新たに関連付けられたオブジェクトについて、新しい結合モデルが作成されます。結合時に不足している部分があれば、その行は結合モデルから削除され、結合モデルに含まれなくなります。

WARNING: モデル結合時の不足分自動削除は即座に行われます。さらに、その際にdestroyコールバックはトリガーされませんので注意が必要です。

`has_many :through`関連付けは、ネストした`has_many`関連付けを介して「ショートカット」を設定する場合にも便利です。たとえば、1つのドキュメントに多くの節(section)があり、1つの節の下に多くの段落(paragraph)がある状態で、節をスキップしてドキュメントの下のすべての段落の単純なコレクションが欲しいとします。その場合、以下の方法で設定できます。

```ruby
class Document < ActiveRecord::Base
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ActiveRecord::Base
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ActiveRecord::Base
  belongs_to :section
end
```

`through: :sections`と指定することにより、Railsは以下の文を理解できるようになります。

```ruby
@document.paragraphs
```

### `has_one :through`関連付け

`has_one :through`関連付けは、他のモデルとの間に1対1のつながりを設定します。この関連付けは、2つのモデルの間に「第3のモデル」(結合モデル)が介在する点が特徴です。それによって、相手モデルの1つのインスタンスとマッチします。
たとえば、1人の提供者(supplier)が1つのアカウントに関連付けられ、さらに1つのアカウントが1つのアカウント履歴に関連付けられる場合、supplierモデルは以下のような感じになります。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
  has_one :account_history, through: :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ActiveRecord::Base
  belongs_to :account
end
```

![has_one :through関連付けの図](images/has_one_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAccountHistories < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

### `has_and_belongs_to_many`関連付け

`has_and_belongs_to_many`関連付けは、他方のモデルと「多対多」のつながりを作成しますが、`through:`を指定した場合と異なり、第3のモデル(結合モデル)が介在しません(訳注: 後述するように結合用のテーブルは必要です)。たとえば、アプリケーションに完成品(assembly)と部品(part)があり、1つの完成品に多数の部品が対応し、逆に1つの部品にも多くの完成品が対応するのであれば、モデルの宣言は以下のようになります。

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many関連付けの図](images/habtm.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    create_table :assemblies_parts, id: false do |t|
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

### `belongs_to`と`has_one`のどちらを選ぶか

2つのモデルの間に1対1の関係を作りたいのであれば、いずれか一方のモデルに`belongs_to`を追加し、もう一方のモデルに`has_one`を追加する必要があります。どちらの関連付けをどちらのモデルに置けばよいのでしょうか。

区別の決め手となるのは外部キー(foreign key)をどちらに置くかです(外部キーは、`belongs_to`を追加した方のモデルのテーブルに追加されます)。もちろんこれだけでは決められません。データの実際の意味についてもう少し考えてみる必要があります。`has_one`というリレーションは、主語となるものが目的語となるものを「所有している」ということを表しています。そして、所有されている側(目的語)の方が、所有している側(主語)を指し示しているということも表しています。たとえば、「供給者がアカウントを持っている」とみなす方が、「アカウントが供給者を持っている」と考えるよりも自然です。つまり、この場合の正しい関係は以下のようになります。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
end
```

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.integer :supplier_id
      t.string  :account_number
      t.timestamps
    end
  end
end
```

NOTE: マイグレーションで`t.integer :supplier_id`のように「小文字のモデル名_id」と書くと、外部キーを明示的に指定できます。新しいバージョンのRailsでは、同じことを`t.references :supplier`という方法で記述できます。こちらの方が実装の詳細が抽象化され、隠蔽されます。

### `has_many :through`と`has_and_belongs_to_many`のどちらを選ぶか

Railsでは、モデル間の多対多リレーションシップを宣言するのに2とおりの方法が使用できます。簡単なのは`has_and_belongs_to_many`を使用する方法です。この方法では関連付けを直接指定できます。

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

多対多のリレーションシップを宣言するもう1つの方法は`has_many :through`です。こちらの場合は、結合モデルを使用した間接的な関連付けが使用されます。

```ruby
class Assembly < ActiveRecord::Base
  has_many :manifests
  has_many :parts, through: :manifests
end

class Manifest < ActiveRecord::Base
  belongs_to :assembly
  belongs_to :part
end

class Part < ActiveRecord::Base
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

どちらを使用するかについてですが、経験上、リレーションシップのモデルそれ自体を独立したエンティティとして扱いたい(両モデルの関係そのものについて処理を行いたい)のであれば、中間に結合モデルを使用する`has_many :through`リレーションシップを選ぶのが最もシンプルです。リレーションシップのモデルで何か特別なことをする必要がまったくないのであれば、結合モデルの不要な`has_and_belongs_to_many`リレーションシップを使用するのがシンプルです(ただし、こちらの場合は結合モデルが不要な代わりに、専用の結合テーブルを別途データベースに作成しておく必要がありますので、お忘れなきよう)。

結合モデルで検証(validation)、コールバック、追加の属性が必要なのであれば、`has_many :through`を使用しましょう。

### ポリモーフィック関連付け

_ポリモーフィック関連付け_は、関連付けのやや高度な応用です。ポリモーフィック関連付けを使用すると、ある1つのモデルが他の複数のモデルに属していることを、1つの関連付けだけで表現することができます。たとえば、写真(picture)モデルがあり、このモデルを従業員(employee)モデルと製品(product)モデルの両方に従属させたいとします。この場合は以下のように宣言します。

```ruby
class Picture < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
end

class Employee < ActiveRecord::Base
  has_many :pictures, as: :imageable
end

class Product < ActiveRecord::Base
  has_many :pictures, as: :imageable
end
```

ポリモーフィックな`belongs_to`は、他のあらゆるモデルから使用できる、(デザインパターンで言うところの)インターフェイスを設定する宣言とみなすこともできます。`@employee.pictures`とすると、写真のコレクションを`Employee`モデルのインスタンスから取得できます。

同様に、`@product.pictures`とすれば写真のコレクションを`Product`モデルのインスタンスから取得できます。

`Picture`モデルのインスタンスがあれば、`@picture.imageable`とすることで親を取得できます。これができるようにするためには、ポリモーフィックなインターフェイスを使用するモデルで、外部キーのカラムと型のカラムを両方とも宣言しておく必要があります。

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string  :name
      t.integer :imageable_id
      t.string  :imageable_type
      t.timestamps
    end
  end
end
```

`t.references`という書式を使用するとさらにシンプルにできます。

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string  :name
      t.references :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

![ポリモーフィック関連付けの図](images/polymorphic.png)

### 自己結合

データモデルを設計していると、時に自分自身に関連付けられる必要のあるモデルに出会うことがあります。たとえば、1つのデータベースモデルに全従業員を格納しておきたいが、マネージャーと部下(subordinate)の関係も追えるようにしておきたい場合が考えられます。この状況は、自己結合関連付けを使用してモデル化することができます。

```ruby
class Employee < ActiveRecord::Base
  has_many :subordinates, class_name: "Employee",
                          foreign_key: "manager_id"

  belongs_to :manager, class_name: "Employee"
end
```

上のように宣言しておくと、`@employee.subordinates`と`@employee.manager`が使用できるようになります。

マイグレーションおよびスキーマでは、モデル自身にreferencesカラムを追加します。

```ruby
class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.references :manager
      t.timestamps
    end
  end
end
```

ヒントと注意事項
--------------------------

RailsアプリケーションでActive Recordの関連付けを効率的に使用するためには、以下について知っておく必要があります。

* キャッシュ制御
* 名前衝突の回避
* スキーマの更新
* 関連付けのスコープ制御
* 双方向関連付け

### キャッシュ制御

関連付けのメソッドは、すべてキャッシュを中心に構築されています。最後に実行したクエリの結果はキャッシュに保持され、次回以降の操作で使用できます。このキャッシュはメソッド間でも共有されることに注意してください。例:

```ruby
customer.orders                 # データベースからordersを取得する
customer.orders.size            # ordersのキャッシュコピーが使用される
customer.orders.empty?          # ordersのキャッシュコピーが使用される
```

データがアプリケーションの他の部分によって更新されている可能性に対応するために、キャッシュを再読み込みするにはどうしたらよいでしょうか。その場合は関連付けのメソッド呼び出しで`true`を指定するだけで、キャッシュが破棄されてデータが再読み込みされます。

```ruby
customer.orders                 # データベースからordersを取得する
customer.orders.size            # ordersのキャッシュコピーが使用される
customer.orders(true).empty?    # ordersのキャッシュコピーが破棄される
                                # その後データベースから再度読み込まれる
```

### 名前衝突の回避

関連付けにはどんな名前でも使用できるとは限りません。関連付けを作成すると、モデルにその名前のメソッドが追加されます。従って、`ActiveRecord::Base`のインスタンスで既に使用されているような名前を関連付けに使用するのは禁物です。そのような名前を関連付けに使用すると、基底メソッドが上書きされて不具合が生じる可能性があります。`attributes`や`connection`は関連付けに使ってはならない名前の例です。

### スキーマの更新

関連付けはきわめて便利ですが、残念ながら全自動の魔法ではありません。関連付けを使用するからには、関連付けの設定に合わせてデータベースのスキーマを常に更新しておく責任が生じます。作成した関連付けにもよりますが、具体的には次の2つの作業が必要になります。1. `belongs_to`関連付けを使用する場合は、外部キーを作成する必要があります。2. `has_and_belongs_to_many`関連付けを使用する場合は、適切な結合テーブルを作成する必要があります。

#### `belongs_to`関連付けに対応する外部キーを作成する

`belongs_to`関連付けを宣言したら、対応する外部キーを作成する必要があります。以下のモデルを例にとります。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

上の宣言は、以下のようにordersテーブル上の外部キー宣言によって裏付けられている必要があります。

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :order_date
      t.string   :order_number
      t.integer  :customer_id
    end
  end
end
```

モデルを先に作り、しばらく経過してから関連を追加で設定する場合は、`add_column`マイグレーションを作成して、必要な外部キーをモデルのテーブルに追加するのを忘れないようにしてください。

#### `has_and_belongs_to_many`関連付けに対応する結合テーブルを作成する

`has_and_belongs_to_many`関連付けを作成した場合は、それに対応する結合(join)テーブルを明示的に作成する必要があります。`:join_table`オプションを使用して明示的に結合テーブルの名前が指定されていない場合、Active Recordは2つのクラス名を辞書の並び順に連結して、適当に結合テーブル名をこしらえます。たとえばCustomerモデルOrderモデルを連結する場合、cはoより辞書で先に出現するので "customers_orders" というデフォルトの結合テーブル名が使用されます。

WARNING: モデル名の並び順は`String`クラスの`<`演算子を使用して計算されます。これは、2つの文字列の長さが異なり、短い方が長い方の途中まで完全に一致しているような場合、長い方の文字列は短い方よりも辞書上の並び順が前として扱われるということです。たとえば、"paper\_boxes" テーブルと "papers" テーブルがある場合、これらを結合すれば "papers\_paper\_boxes" となると推測されます。 "paper\_boxes" の方が長いので、常識的には並び順が後ろになると予測できるからです。しかし実際の結合テーブル名は "paper\_boxes\_papers" になってしまいます。これはアンダースコア '\_' の方が 's' よりも並びが前になっているためです。

生成された名前がどのようなものであれ、適切なマイグレーションを実行して結合テーブルを生成する必要があります。以下の関連付けを例にとって考えてみましょう。

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

この関連付けに対応する `assemblies_parts` テーブルをマイグレーションで作成し、裏付けておく必要があります。このテーブルには主キーを設定しないでください。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration
  def change
    create_table :assemblies_parts, id: false do |t|
      t.integer :assembly_id
      t.integer :part_id
    end
  end
end
```

このテーブルはモデルを表さないので、`create_table`に`id: false`を渡します。こうしておかないとこの関連付けは正常に動作しません。モデルのIDが破損する、IDの競合で例外が発生するなど、`has_and_belongs_to_many`関連付けの動作が怪しい場合は、この設定を忘れていないかどうか再度確認してみてください。

### 関連付けのスコープ制御

デフォルトでは、関連付けによって探索されるオブジェクトは、現在のモジュールのスコープ内のものだけです。Active Recordモデルをモジュール内で宣言している場合、この点に注意する必要があります。例：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end

    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

上のコードは正常に動作します。これは、`Supplier`クラスと`Account`クラスが同じスコープ内で定義されているためです。しかし下のコードは動作しません。`Supplier`クラスと`Account`クラスが異なるスコープ内で定義されているためです。

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

あるモデルと異なる名前空間にあるモデルを関連付けるには、関連付けの宣言で完全なクラス名を指定する必要があります

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account,
        class_name: "MyApplication::Billing::Account"
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier,
        class_name: "MyApplication::Business::Supplier"
    end
  end
end
```

### 双方向関連付け

関連付けは、通常双方向で設定します。2つのモデル両方に関連を定義する必要があります。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

Active Recordは、これらの双方向関連付け同士につながりがあることをデフォルトでは認識しません。これにより、以下のようにオブジェクトの2つのコピー同士で内容が一致しなくなることがあります。

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => false
```

これが起こるのは、cとo.customerは同じデータがメモリ上で異なる表現となっており、一方が更新されても他方が自動的には更新されないためです。Active Recordの`:inverse_of`オプションを使用すればこれらの関係を通知することができます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

上のように変更することで、Active Recordはcustomerオブジェクトのコピーを1つだけ読み込むようになり、不整合を防ぐと同時にアプリケーションの効率も高まります。

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => true
```

ただし、`inverse_of`のサポートにはいくつかの制限があります。

* `:through`関連付けと併用することはできません。
* `:polymorphic`関連付けと併用することはできません。
* `:as`関連付けと併用することはできません。
* `belongs_to`関連付けの場合、`has_many`の逆関連付けは無視されます。

関連付けでは、常に逆関連付けを自動的に検出しようとします。その際、関連付け名に基いて`:inverse_of`オプションがヒューリスティックに設定されます。
標準的な名前であれば、ほとんどの関連付けで逆関連付けがサポートされます。ただし、以下のオプションを設定した関連付けでは、逆関連付けは自動的には設定されません。

* :conditions
* :through
* :polymorphic
* :foreign_key

関連付けの詳細情報
------------------------------

この節では、各関連付けの詳細を解説します。関連付けの宣言によって追加されるメソッドやオプションについても説明します。

### `belongs_to`関連付けの詳細

`belongs_to`関連付けは、別のモデルとの間に1対1の関連付けを作成します。データベースの用語で説明すると、この関連付けが行われているクラスには外部キーがあるということです。外部キーが自分のクラスではなく相手のクラスにあるのであれば、`belongs_to`ではなく`has_one`を使用する必要があります。

#### `belongs_to`で追加されるメソッド

`belongs_to`関連付けを宣言したクラスでは、以下の5つのメソッドを自動的に利用できるようになります。

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

これらのメソッドのうち、`association`の部分はプレースホルダであり、`belongs_to`の最初の引数である関連付け名をシンボルにしたものに置き換えられます。以下の例ではcustomerが宣言されています。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

これにより、Orderモデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
customer
customer=
build_customer
create_customer
create_customer!
```

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`build_`で始まるメソッドを使用する必要があります。この場合`has_many`関連付けや`has_and_belongs_to_many`関連付けで使用される`association.build`メソッドは使用しないでください。作成するには、`create_`で始まるメソッドを使用してください。

##### `association(force_reload = false)`

`association`メソッドは関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@customer = @order.customer
```

関連付けられたオブジェクトがデータベースから検索されたことがある場合は、キャッシュされたものを返します。キャッシュを読み出さずにデータベースから直接読み込ませたい場合は、`force_reload`の引数に`true`を設定します。

##### `association=(associate)`

`association=`メソッドは、引数のオブジェクトをそのオブジェクトに関連付けます。その背後では、関連付けられたオブジェクトから主キーを取り出し、そのオブジェクトの外部キーにその同じ値を設定しています。

```ruby
@order.customer = @customer
```

##### `build_association(attributes = {})`

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトは、値が返された時点ではまだ保存されて_いない_ことにご注意ください。

```ruby
@customer = @order.build_customer(customer_number: 123,
                                  customer_name: "John Doe")
```

##### `create_association(attributes = {})`

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を使用してインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@customer = @order.create_customer(customer_number: 123,
                                   customer_name: "John Doe")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。


#### `belongs_to`のオプション

Railsのデフォルトの`belongs_to`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときに渡すオプションとスコープブロックで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, dependent: :destroy,
    counter_cache: true
end
```

`belongs_to`関連付けでは以下のオプションがサポートされています。

* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:polymorphic`
* `:touch`
* `:validate`

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションを使用してモデル名を直接指定できます。たとえば、注文(order)が顧客(customer)に従属しているが、実際の顧客モデル名が`Patron`である場合には以下のように指定します。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron"
end
```

##### `:counter_cache`

`:counter_cache`オプションは、従属しているオブジェクトの数の検索効率を向上させます。以下のモデルで説明します。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

上の宣言のままでは、`@customer.orders.size`の値を知るためにデータベースに対して`COUNT(*)`クエリを実行する必要があります。この呼び出しを避けるために、「従属している方のモデル(`belongs_to`を宣言している方のモデル)」にカウンタキャッシュを追加することができます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: true
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

上のように宣言すると、キャッシュ値が最新の状態に保たれ、次に`size`メソッドが呼び出されたときにその値が返されます。

ここで1つ注意が必要です。`:counter_cache`オプションは`belongs_to`宣言で指定しますが、実際に数を数えたいカラムは、相手のモデル(関連付けられているモデル)の方に追加する必要があります。上の場合には、`Customer`モデルの方に`orders_count`カラムを追加する必要があります。必要であれば、デフォルトのカラム名を以下のようにオーバーライドできます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: :count_of_orders
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

カウンタキャッシュ用のカラムは、`attr_readonly`によって読み出し専用属性となるモデルのリストに追加されます。

##### `:dependent`
`:dependent`オプションの動作は以下のように対象によって異なります。

* `:destroy` -- そのオブジェクトがdestroyされると、関連付けられたオブジェクトに対して`destroy`が呼び出されます。
* `:delete` -- オブジェクトがdestroyされると、関連付けられたオブジェクトはすべて直接削除されます。このときオブジェクトの`destroy`メソッドは呼び出されません。

WARNING: `他のクラスの`has_many` 関連付けとつながりのある `belongs_to` 関連付けに対してこのオプションを使用してはいけません。孤立したレコードがデータベースに残ってしまう可能性があります。

##### `:foreign_key`

Railsの慣例では、相手のモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使用されることを前提とします。`:foreign_key`オプションを使用すると外部キーの名前を直接指定することができます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron",
                        foreign_key: "patron_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使用する場合には、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`has_many`関連付けまたは`has_one`関連付けの名前を指定します。`:polymorphic`オプションと組み合わせた場合は無効です。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:polymorphic`

`:polymorphic`オプションに`true`を指定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けの詳細については<a href="#ポリモーフィック関連付け">このガイドの説明</a>を参照してください。

##### `:touch`

`:touch`オプションを`:true`に設定すると、関連付けられているオブジェクトが保存またはdestroyされるたびに、そのオブジェクトの`updated_at`または`updated_on`タイムスタンプが現在時刻に設定されます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: true
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

上の例の場合、Orderクラスは、関連付けられているCustomerのタイムスタンプを保存時またはdestroy時に更新します。更新時に特定のタイムスタンプ属性を指定することもできます。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: :orders_updated_at
end
```

##### `:validate`

`:validate`オプションを`true`に設定すると、関連付けられたオブジェクトが保存時に必ず検証(validation)されます。デフォルトは`false`であり、この場合関連付けられたオブジェクトは保存時に検証されません。

#### `belongs_to`のスコープ

場合によっては`belongs_to`で使用されるクエリをカスタマイズしたくなることがあります。スコープブロックを使用してこのようなカスタマイズを行うことができます。例：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true },
                        dependent: :destroy 
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて使用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true }
end
```

##### `includes`

`includes`メソッドを使用すると、その関連付けが使用されるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

LineItemから顧客名(Customer)を`@line_item.order.customer`のように直接取り出す機会が頻繁にあるのであれば、LineItemとOrderの関連付けを行なう時にCustomerをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order, -> { includes :customer }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: 直接の関連付けでは`includes`を使用する必要はありません。`Order belongs_to :customer`のような直接の関連付けでは必要に応じて自動的にeager-loadされます。

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトから取り出した内容は読み出し専用になります。

##### `select`

`select`メソッドを使用すると、関連付けられたオブジェクトのデータ取り出しに使用されるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

TIP: `select`を`belongs_to`関連付けで使用する場合、正しい結果を得るために`:foreign_key`オプションを必ず設定してください。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを使用して、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @order.customer.nil?
  @msg = "No customer found for this order"
end
```

#### オブジェクトが保存されるタイミング

オブジェクトを`belongs_to`関連付けに割り当てても、そのオブジェクトが自動的に保存されるわけでは_ありません_。関連付けられたオブジェクトが保存されることもありません。

### `has_one`関連付けの詳細

`has_one`関連付けは他のモデルと1対1対応します。データベースの観点では、この関連付けでは相手のクラスが外部キーを持ちます。相手ではなく自分のクラスが外部キーを持っているのであれば、`belongs_to`を使うべきです。

#### `has_one`で追加されるメソッド

`has_one`関連付けを宣言したクラスでは、以下の5つのメソッドを自動的に利用できるようになります。

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

これらのメソッドのうち、`association`の部分はプレースホルダであり、`has_one`の最初の引数である関連付け名をシンボルにしたものに置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

これにより、`Supplier`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
account
account=
build_account
create_account
create_account!
```

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`build_`で始まるメソッドを使用する必要があります。この場合`has_many`関連付けや`has_and_belongs_to_many`関連付けで使用される`association.build`メソッドは使用しないでください。作成するには、`create_`で始まるメソッドを使用してください。

##### `association(force_reload = false)`

`association`メソッドは関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@account = @supplier.account
```

関連付けられたオブジェクトがデータベースから検索されたことがある場合は、キャッシュされたものを返します。キャッシュを読み出さずにデータベースから直接読み込ませたい場合は、`force_reload`の引数に`true`を設定します。

##### `association=(associate)`

`association=`メソッドは、引数のオブジェクトをそのオブジェクトに関連付けます。その背後では、そのオブジェクトから主キーを取り出し、関連付けるオブジェクトの外部キーの値をその主キーと同じ値にします。

```ruby
@supplier.account = @account
```

##### `build_association(attributes = {})`

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性でインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。ただし、関連付けられたオブジェクトはまだ保存されません。

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

##### `create_association(attributes = {})`

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を使用してインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

#### `has_one`のオプション

Railsのデフォルトの`has_one`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing", dependent: :nullify
end
```

`has_one`関連付けでは以下のオプションがサポートされます。

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

`:as`オプションに`true`を設定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けの詳細については<a href="#ポリモーフィック関連付け">このガイドの説明</a>を参照してください。

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションを使用してモデル名を直接指定できます。たとえば、Supplierにアカウントが1つあり、アカウントを含むモデルの実際の名前が`Account`ではなく`Billing`になっている場合、以下のようにモデル名を指定できます。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing"
end
```

##### `:dependent`

オーナーオブジェクトがdestroyされた時に、それに関連付けられたオブジェクトをどうするかを制御します。

* `:destroy`を指定すると、関連付けられたオブジェクトも同時にdestroyされます。
* `:delete`を指定すると、関連付けられたオブジェクトはデータベースから直接削除されます。このときコールバックは実行されません。
* `:nullify`を指定すると、外部キーが`NULL`に設定されます。このときコールバックは実行されません。
* `:restrict_with_exception`を指定すると、関連付けられたレコードがある場合に例外が発生します。
* `:restrict_with_error`を指定すると、関連付けられたオブジェクトがある場合にエラーがオーナーに追加されます。

`NOT NULL`データベース制約のある関連付けでは、`:nullify`オプションを与えないようにする必要があります。そのような関連付けをdestroyする`dependent`を設定しなかった場合、関連付けられたオブジェクトを変更できなくなってしまいます。これは、最初に関連付けられたオブジェクトの外部キーが`NULL`値になってしまい、この値は許されていないためです。

##### `:foreign_key`

Railsの慣例では、相手のモデル上の外部キーを保持しているカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使用されることを前提とします。`:foreign_key`オプションを使用すると外部キーの名前を直接指定することができます。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, foreign_key: "supp_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使用する場合には、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。`:through`または`:as`オプションと組み合わせた場合は無効です。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, inverse_of: :supplier
end

class Account < ActiveRecord::Base
  belongs_to :supplier, inverse_of: :account
end
```

##### `:primary_key`

Railsの慣例では、モデルの主キーは`id`カラムに保存されていることを前提とします。`:primary_key`オプションで主キーを明示的に指定することでこれを上書きすることができます。

##### `:source`

`:source`オプションは、`has_one :through`関連付けにおける「ソースの」関連付け名、つまり関連付け元の名前を指定します。

##### `:source_type`

`:source_type`オプションは、ポリモーフィック関連付けを介して行われる`has_one :through`関連付けにおける「ソースの」関連付けタイプ、つまり関連付け元のタイプを指定します。

##### `:through`

`:through`オプションは、<a href="#has-one-through関連付け">このガイドで既に説明した</a>`has_one :through`関連付けのクエリを実行する際に経由する結合モデルを指定します。

##### `:validate`

`:validate`オプションを`true`に設定すると、関連付けられたオブジェクトが保存時に必ず検証(validation)されます。デフォルトは`false`であり、この場合関連付けられたオブジェクトは保存時に検証されません。

#### `has_one`のスコープについて

場合によっては`has_one`で使用されるクエリをカスタマイズしたくなることがあります。スコープブロックを使用してこのようなカスタマイズを行うことができます。例：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where active: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて使用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where "confirmed = 1" }
end
```

##### `includes`

`includes`メソッドを使用すると、その関連付けが使用されるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

上の例で、Supplierから代表(Representative)を`@supplier.account.representative`のように直接取り出す機会が頻繁にあるのであれば、SupplierからAccountへの関連付けにRepresentativeをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。 

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { includes :representative }
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使用すると、関連付けられたオブジェクトのデータ取り出しに使用されるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを使用して、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @supplier.account.nil?
  @msg = "No account found for this supplier"
end
```

#### オブジェクトが保存されるタイミング

`has_one`関連付けにオブジェクトをアサインすると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。さらに、置き換えられるオブジェクトは、これは外部キーが変更されたことによってすべて自動的に保存されます。

関連付けられているオブジェクト同士のいずれか一方が検証(validation)のために保存に失敗すると、アサインの状態からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_one`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存された場合は、子オブジェクトは保存されます。

`has_one`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`association.build`メソッドを使用してください。

### `has_many`関連付けの詳細

`has_many`関連付けは、他のモデルとの間に「1対多」のつながりを作成します。データベースの観点では、この関連付けにおいては相手のクラスが外部キーを持ちます。この外部キーは相手のクラスのインスタンスを参照します。

#### `has_many`で追加されるメソッド

`has_many`関連付けを宣言したクラスでは、以下の16のメソッドを自動的に利用できるようになります。

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects` 
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...) `
* `collection.build(attributes = {}, ...)`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

上のメソッドの`collection`の部分はプレースホルダであり、実際には`has_many`への1番目の引数として渡されたシンボルに置き換えられます。また、`collection_singular`の部分はシンボルの単数形に置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

これにより、`Customer`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
orders(force_reload = false)
orders<<(object, ...)
orders.delete(object, ...)
orders.destroy(object, ...)
orders=objects
order_ids
order_ids=ids
orders.clear
orders.empty?
orders.size
orders.find(...)
orders.where(...)
orders.exists?(...)
orders.build(attributes = {}, ...)
orders.create(attributes = {})
orders.create!(attributes = {})`
```

##### `collection(force_reload = false)`

`collection`メソッドは、関連付けられたすべてのオブジェクトの配列を返します。関連付けられたオブジェクトがない場合は、空の配列を1つ返します。

```ruby
@orders = @customer.orders
```

##### `collection<<(object, ...)`

`collection<<`メソッドは、1つ以上のオブジェクトをコレクションに追加します。このとき、追加されるオブジェクトの外部キーは、呼び出し側モデルの主キーに設定されます。

```ruby
@customer.orders << @order1
```

##### `collection.delete(object, ...)`

`collection.delete`メソッドは、外部キーを`NULL`に設定することで、コレクションから1つまたは複数のオブジェクトを削除します。

```ruby
@customer.orders.delete(@order1)
```

WARNING: 削除のされ方はこれだけではありません。オブジェクト同士が`dependent: :destroy`で関連付けられている場合はdestroyされますが、オブジェクト同士が`dependent: :delete_all`で関連付けられている場合はdeleteされますのでご注意ください。

##### `collection.destroy(object, ...)`

`collection.destroy`は、コレクションに関連付けられているオブジェクトに対して`destroy`を実行することで、コレクションから1つまたは複数のオブジェクトを削除します。

```ruby
@customer.orders.destroy(@order1)
```

WARNING: この場合オブジェクトは_無条件で_データベースから削除されます。このとき、`:dependent`オプションがどのように設定されていても無視して削除が行われます。

##### `collection=objects`

`collection=`メソッドは、指定したオブジェクトでそのコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。

##### `collection_singular_ids`

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@order_ids = @customer.order_ids
```

##### `collection_singular_ids=ids`

`collection_singular_ids=`メソッドは、指定された主キーidを持つオブジェクトの集まりでコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。

##### `collection.clear`

`collection.clear`メソッドは、コレクションからすべてのオブジェクトを削除します。`dependent: :destroy`で関連付けられたオブジェクトがある場合は、それらのオブジェクトはdestroyされます。`dependent: :delete_all`で関連付けられたオブジェクトがある場合は、データベースから直接deleteされます。それ以外の場合は単に外部キーが`NULL`に設定されます。

##### `collection.empty?`

`collection.empty?`メソッドは、関連付けられたオブジェクトがコレクションの中に1つもない場合に`true`を返します。

```erb
<% if @customer.orders.empty? %>
  注文はありません。
<% end %>
```

##### `collection.size`

`collection.size`メソッドは、コレクションに含まれるオブジェクトの数を返します。

```ruby
@order_count = @customer.orders.size
```

##### `collection.find(...)`

`collection.find`メソッドは、コレクションに含まれるオブジェクトを検索します。このメソッドで使用される文法は、`ActiveRecord::Base.find`で使用されているものと同じです。

```ruby
@open_orders = @customer.orders.find(1)
```

##### `collection.where(...)`

`collection.where`メソッドは、コレクションに含まれているメソッドを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み(lazy load)される点にご注意ください。つまり、オブジェクトに実際にアクセスが行われる時にだけデータベースへのクエリが発生します。

```ruby
@open_orders = @customer.orders.where(open: true) # この時点ではクエリは行われない
@open_order = @open_orders.first # ここで初めてデータベースへのクエリが行われる
```

##### `collection.exists?(...)`

`collection.exists?`メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。このメソッドで使用される文法は、`ActiveRecord::Base.exists?`で使用されているものと同じです。`.

##### `collection.build(attributes = {}, ...)`

`collection.build`メソッドは、関連付けが行われたオブジェクトを1つまたは複数返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが作成されます。関連付けられたオブジェクトは、値が返された時点ではまだ保存されて_いない_ことにご注意ください。

```ruby
@order = @customer.orders.build(order_date: Time.now,
                                order_number: "A12345")
```

##### `collection.create(attributes = {})`

`collection.create`メソッドは、関連付けが行われたオブジェクトを1つ返します。このオブジェクトは、渡された属性を使用してインスタンス化され、そのオブジェクトの外部キーを介してリンクが作成されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@order = @customer.orders.create(order_date: Time.now,
                                 order_number: "A12345")
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

#### `has_many`のオプション

Railsのデフォルトの`has_many`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :delete_all, validate: :false
end
```

`has_many`関連付けでは以下のオプションがサポートされます。

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

`:as`オプションを設定すると、ポリモーフィック関連付けであることが指定されます。(<a href="#ポリモーフィック関連付け">このガイドの説明</a>を参照)

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションを使用してモデル名を直接指定できます。たとえば、1人の顧客(customer)が複数の注文(order)を持っているが、実際の注文モデル名が`Transaction`である場合には以下のように指定します。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, class_name: "Transaction"
end
```

##### `:dependent`

オーナーオブジェクトがdestroyされたときに、オーナーに関連付けられたオブジェクトをどうするかを制御します。

* `:destroy`を指定すると、関連付けられたオブジェクトもすべて同時にdestroyされます。
* `:delete`を指定すると、関連付けられたオブジェクトはすべてデータベースから直接削除されます。このときコールバックは実行されません。
* `:nullify`を指定すると、外部キーはすべて`NULL`に設定されます。このときコールバックは実行されません。
* `:restrict_with_exception`を指定すると、関連付けられたレコードが1つでもある場合に例外が発生します。
* `:restrict_with_error`を指定すると、関連付けられたオブジェクトが1つでもある場合にエラーがオーナーに追加されます。

NOTE: その関連付けで`:through`オプションが指定されている場合、このオプションは無効です。

##### `:foreign_key`

Railsの慣例では、外部キーを保持するためのカラム名については、モデル名にサフィックス `_id` を追加した名前が使用されることを前提とします。`:foreign_key`オプションを使用すると外部キーの名前を直接指定することができます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, foreign_key: "cust_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使用する場合には、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。`:through`または`:as`オプションと組み合わせた場合は無効です。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:primary_key`

Railsの慣例では、関連付けの主キーは`id`カラムに保存されていることを前提とします。`:primary_key`オプションで主キーを明示的に指定することでこれを上書きすることができます。

`users`テーブルに主キーとして`id`カラムがあり、その他に`guid`カラムもあるとします。さらに、`todos`テーブルでは`users`テーブルの`id`カラムの値ではなく`guid`カラムの値を保持したいとします。これは以下のようにすることで実現できます。

```ruby
class User < ActiveRecord::Base
  has_many :todos, primary_key: :guid
end
```

ここで`@user.todos.create`を実行すると、`@todo`レコードの`user_id`カラムの値には`@user`の`guid`値が設定されます。


##### `:source`

`:source`オプションは、`has_many :through`関連付けにおける「ソースの」関連付け名、つまり関連付け元の名前を指定します。このオプションは、関連付け名から関連付け元の名前が自動的に推論できない場合以外には使用する必要はありません。

##### `:source_type`

`:source_type`オプションは、ポリモーフィック関連付けを介して行われる`has_many :through`関連付けにおける「ソースの」関連付けタイプ、つまり関連付け元のタイプを指定します。

##### `:through`

`:through`オプションは、クエリ実行時に経由する結合(join)モデルを指定します。`has_many :through`関連付けは、多対多の関連付けを実装する方法を提供します(詳細については<a href="#has-many-through関連付け">このガイドの説明</a>を参照)。

##### `:validate`

`:validate`オプションを`false`に設定すると、関連付けられたオブジェクトは保存時に検証(validation)されません。デフォルトは`true`であり、この場合関連付けられたオブジェクトは保存時に検証されます。

#### `has_many`のスコープについて

場合によっては`has_many`で使用されるクエリをカスタマイズしたくなることがあります。スコープブロックを使用してこのようなカスタマイズを行うことができます。例：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { where processed: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて使用できます。ここでは以下について説明します。

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where "confirmed = 1" },
    class_name: "Order"
end
```

条件はハッシュを使用して指定することもできます。

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where confirmed: true },
                              class_name: "Order"
end
```

`where`オプションでハッシュを使用した場合、この関連付けで作成されたレコードは自動的にこのハッシュを使用したスコープに含まれるようになります。この例の場合、`@customer.confirmed_orders.create`または`@customer.confirmed_orders.build`を実行すると、comfirmedカラムの値が`true`の注文(order)が常に作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については<a href="#関連付けの拡張">後述します</a>。

##### `group`

`group`メソッドは、結果をグループ化する際の属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使用されます。

```ruby
class Customer < ActiveRecord::Base
  has_many :line_items, -> { group 'orders.id' },
                        through: :orders
end
```

##### `includes`

`includes`メソッドを使用すると、その関連付けが使用されるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

顧客名(Customer)からLineItemを`@customer.orders.line_items`のように直接取り出す機会が頻繁にあるのであれば、LineItemとOrderの関連付けを行なう時にCustomerをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { includes :line_items }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

##### `limit`

`limit`メソッドは、関連付けを使用して取得できるオブジェクトの総数を制限するのに使用します。

```ruby
class Customer < ActiveRecord::Base
  has_many :recent_orders,
    -> { order('order_date desc').limit(100) },
    class_name: "Order",
end
```

##### `offset`

`offset`メソッドは、関連付けを使用してオブジェクトを取得する際の開始オフセットを指定します。たとえば、`-> { offset(11) }`と指定すると、最初の11レコードはスキップされ、12レコード目から返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトに与えられる順序を指定します。内部的にはSQLの`ORDER BY`句が使用されます。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { order "date_confirmed DESC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使用すると、関連付けられたオブジェクトのデータ取り出しに使用されるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

WARNING: 独自の`select`メソッドを使用する場合には、関連付けられているモデルの主キーカラムと外部キーカラムを必ず含めておいてください。これを行わなかった場合、Railsでエラーが発生します。

##### `distinct`

`distinct`メソッドは、コレクション内で重複が発生しないようにします。このメソッドは`:through`オプションと併用するときに特に便利です。

```ruby
class Person < ActiveRecord::Base
  has_many :readings
  has_many :posts, through: :readings
end

person = Person.create(name: 'John')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 5, name: "a1">, #<Post id: 5, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 12, person_id: 5, post_id: 5>, #<Reading id: 13, person_id: 5, post_id: 5>]
```

上の例の場合、readingが2つあって重複しており、`person.posts`を実行すると、どちらも同じポストを指しているにもかかわらず、両方とも取り出されてしまいます。

今度は`distinct`を設定してみましょう。

```ruby
class Person
  has_many :readings
  has_many :posts, -> { distinct }, through: :readings
end

person = Person.create(name: 'Honda')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 7, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 16, person_id: 7, post_id: 7>, #<Reading id: 17, person_id: 7, post_id: 7>]
```

上の例でもreadingは2つあって重複しています。しかし今度は`person.posts`の実行結果にはポストは1つだけ含まれるようになりました。これはこのコレクションが一意のレコードだけを読み込むようになったためです。

挿入時にも同様に、現在残っているすべてのレコードが一意であるようにする(関連付けを検査したときに重複レコードが決して発生しないようにする)には、テーブル自体に一意のインデックスを追加する必要があります。たとえば、`person_posts`というテーブルがあり、すべてのポストが一意であるようにしたいのであれば、マイグレーションに以下を追加します。

```ruby
add_index :person_posts, :post, unique: true
```

なお、`include?`などを使用して一意性をチェックすると競合が発生しやすいので注意が必要です。関連付けで強制的に一意になるようにするために`include?`を使用しないでください。たとえば上のpostを例にとると、以下のコードでは競合が発生しやすくなります。これは、複数のユーザーが同時にこのコードを実行する可能性があるためです。

```ruby
person.posts << post unless person.posts.include?(post)
```

#### オブジェクトが保存されるタイミング

`has_many`関連付けにオブジェクトをアサインすると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトをアサインすると、それらはすべて保存されます。

関連付けられているオブジェクト同士の1つでも検証(validation)のために保存に失敗すると、アサインの状態からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_many`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバはすべて保存されます。

`has_many`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`collection.build`メソッドを使用してください。

### `has_and_belongs_to_many`関連付けの詳細

`has_and_belongs_to_many`関連付けは、他のモデルとの間に「多対多」のつながりを作成します。データベースの観点では、2つのクラスは中間で結合テーブルを介して関連付けられます。この結合テーブルには、両方のクラスを指す外部キーがそれぞれ含まれます。

#### `has_and_belongs_to_many`で追加されるメソッド

`has_and_belongs_to_many`関連付けを宣言したクラスでは、以下の16のメソッドを自動的に利用できるようになります。

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects` 
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...) `
* `collection.build(attributes = {})`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

上のメソッドの`collection`の部分はプレースホルダであり、実際には`has_and_belongs_to_many`への1番目の引数として渡されたシンボルに置き換えられます。また、`collection_singular`の部分はシンボルの単数形に置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

これにより、`Part`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
assemblies(force_reload = false)
assemblies<<(object, ...)
assemblies.delete(object, ...)
assemblies.destroy(object, ...)
assemblies=objects
assembly_ids
assembly_ids=ids
assemblies.clear
assemblies.empty?
assemblies.size
assemblies.find(...)
assemblies.where(...)
assemblies.exists?(...)
assemblies.build(attributes = {}, ...)
assemblies.create(attributes = {})
assemblies.create!(attributes = {})`
```

##### 追加のカラムメソッド

`has_and_belongs_to_many`関連付けで使用している中間の結合テーブルが、2つの外部キー以外に何かカラムを含んでいる場合、これらのカラムは関連付けを介して取り出されるレコードに属性として追加されます。属性が追加されたレコードは常に読み出し専用になります。このようにして読み出された属性に対する変更は保存できないためです。

WARNING: `has_and_belongs_to_many`関連付けで使用する結合テーブルにこのような余分なカラムを追加することはお勧めできません。2つのモデルを多対多で結合する結合テーブルでこのような複雑な振る舞いが必要になるのであれば、`has_and_belongs_to_many`ではなく`has_many :through`を使用してください。


##### `collection(force_reload = false)`

`collection`メソッドは、関連付けられたすべてのオブジェクトの配列を返します。関連付けられたオブジェクトがない場合は、空の配列を1つ返します。

```ruby
@assemblies = @part.assemblies
```

##### `collection<<(object, ...)`

`collection<<`メソッドは、結合テーブル上でレコードを作成し、それによって1つまたは複数のオブジェクトをコレクションに追加します。

```ruby
@part.assemblies << @assembly1
```

NOTE: このメソッドは`collection.concat`および`collection.push`のエイリアスです。

##### `collection.delete(object, ...)`

`collection.delete`メソッドは、結合テーブル上のレコードを削除し、それによって1つまたは複数のオブジェクトをコレクションから削除します。このメソッドを実行してもオブジェクトはdestroyされません。

```ruby
@part.assemblies.delete(@assembly1)
```

WARNING: このメソッドを呼び出しても、結合レコードでコールバックはトリガされません。

##### `collection.destroy(object, ...)`

`collection.destroy`は、結合テーブル上のレコードに対して`destroy`を実行する(このときコールバックも実行します)ことで、コレクションから1つまたは複数のオブジェクトを削除します。このメソッドを実行してもオブジェクトはdestroyされません。

```ruby
@part.assemblies.destroy(@assembly1)
```

##### `collection=objects`

`collection=`メソッドは、指定したオブジェクトでそのコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。

##### `collection_singular_ids`

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@assembly_ids = @part.assembly_ids
```

##### `collection_singular_ids=ids`

`collection_singular_ids=`メソッドは、指定された主キーidを持つオブジェクトの集まりでコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。

##### `collection.clear`

`collection.clear`メソッドは、結合テーブル上のレコードを削除し、それによってすべてのオブジェクトをコレクションから削除します。このメソッドを実行しても、関連付けられたオブジェクトはdestroyされません。

##### `collection.empty?`

`collection.empty?`メソッドは、関連付けられたオブジェクトがコレクションに含まれていない場合に`true`を返します。

```ruby
<% if @part.assemblies.empty? %>
  ※この部分はどのアセンブリでも使用されません。
<% end %>
```

##### `collection.size`

`collection.size`メソッドは、コレクションに含まれるオブジェクトの数を返します。

```ruby
@assembly_count = @part.assemblies.size
```

##### `collection.find(...)`

`collection.find`メソッドは、コレクションに含まれるオブジェクトを検索します。このメソッドで使用される文法は、`ActiveRecord::Base.find`で使用されているものと同じです。このメソッドでは、オブジェクトがコレクション内で従う必要のある追加条件も加味されます。

```ruby
@assembly = @part.assemblies.find(1)
```

##### `collection.where(...)`

`collection.where`メソッドは、コレクションに含まれているメソッドを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み(lazy load)される点にご注意ください。つまり、オブジェクトに実際にアクセスが行われる時にだけデータベースへのクエリが発生します。このメソッドでは、オブジェクトがコレクション内で従う必要のある追加条件も加味されます。

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

##### `collection.exists?(...)`

`collection.exists?`メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。このメソッドで使用される文法は、`ActiveRecord::Base.exists?`で使用されているものと同じです。`.

##### `collection.build(attributes = {})`

`collection.build`メソッドは、関連付けが行われたオブジェクトを1つ返します。このオブジェクトは、渡された属性でインスタンス化され、その結合テーブルを介してリンクが作成されます。ただし、関連付けられたオブジェクトはこの時点では保存s慣れて_いない_ことにご注意ください。

```ruby
@assembly = @part.assemblies.build({assembly_name: "Transmission housing"})
```

##### `collection.create(attributes = {})`

`collection.create`メソッドは、関連付けが行われたオブジェクトを1つ返します。このオブジェクトは、渡された属性を使用してインスタンス化され、結合テーブルを介してリンクが作成されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@assembly = @part.assemblies.create({assembly_name: "Transmission housing"})
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

#### `has_and_belongs_to_many`のオプション

Railsのデフォルトの`has_and_belongs_to_many`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, autosave: true,
                                       readonly: true
end
```

`has_and_belongs_to_many`関連付けでは以下のオプションがサポートされます。

* `:association_foreign_key`
* `:autosave`
* `:class_name`
* `:foreign_key`
* `:join_table`
* `:validate`
* `:readonly`

##### `:association_foreign_key`

Railsの慣例では、相手のモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使用されることを前提とします。`:association_foreign_key`オプションを使用すると外部キーの名前を直接指定することができます。

TIP: `:foreign_key`オプションおよび`:association_foreign_key`オプションは、多対多の自己結合を行いたいときに便利です。例：

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションを使用してモデル名を直接指定できます。たとえば、1つの部品(Part)が複数の組み立て(Assembly)で使用され、組み立てを含む実際のモデル名が`Gadget`である場合、次のように設定します。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, class_name: "Gadget"
end
```

##### `:foreign_key`

Railsの慣例では、そのモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使用されることを前提とします。`:foreign_key`オプションを使用すると外部キーの名前を直接指定することができます。

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:join_table`

辞書順に基いて生成された結合テーブルのデフォルト名が気に入らない場合、`:join_table`オプションを使用してデフォルトのテーブル名を上書きできます。

##### `:validate`

`:validate`オプションを`false`に設定すると、関連付けられたオブジェクトは保存時に検証(validation)されません。デフォルトは`true`であり、この場合関連付けられたオブジェクトは保存時に検証されます。

#### `has_and_belongs_to_many`のスコープについて

場合によっては`has_and_belongs_to_many`で使用されるクエリをカスタマイズしたくなることがあります。スコープブロックを使用してこのようなカスタマイズを行うことができます。例：

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて使用できます。ここでは以下について説明します。

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

条件はハッシュを使用して指定することもできます。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where factory: 'Seattle' }
end
```

`where`オプションでハッシュを使用した場合、この関連付けで作成されたレコードは自動的にこのハッシュを使用したスコープに含まれるようになります。この例の場合、`@parts.assemblies.create`または`@parts.assemblies.build`を実行すると、`factory`カラムの値が`Seattle`の注文(order)が常に作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については<a href="#関連付けの拡張">後述します</a>。

##### `group`

`group`メソッドは、結果をグループ化する際の属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使用されます。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `includes`

`includes`メソッドを使用すると、その関連付けが使用されるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。

##### `limit`

`limit`メソッドは、関連付けを使用して取得できるオブジェクトの総数を制限するのに使用します。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `offset`

`offset`メソッドは、関連付けを使用してオブジェクトを取得する際の開始オフセットを指定します。たとえばoffset(11)と指定すると、最初の11レコードはスキップされ、12レコード目から返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトに与えられる順序を指定します。内部的にはSQLの`ORDER BY`句が使用されます。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order "assembly_name ASC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使用すると、関連付けられたオブジェクトのデータ取り出しに使用されるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

##### `uniq`

`uniq`メソッドは、コレクション内の重複を削除します。

#### オブジェクトが保存されるタイミング

`has_and_belongs_to_many`関連付けにオブジェクトをアサインすると、結合テーブルを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトをアサインすると、それらはすべて保存されます。

関連付けられているオブジェクト同士の1つでも検証(validation)のために保存に失敗すると、アサインの状態からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_and_belongs_to_many`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバはすべて保存されます。

`has_and_belongs_to_many`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`collection.build`メソッドを使用してください。

### 関連付けのコールバック

通常のコールバックは、Active Recordオブジェクトのライフサイクルの中でフックされます。これにより、オブジェクトのさまざまな場所でコールバックを実行できます。たとえば、`:before_save`コールバックを使用して、オブジェクトが保存される直前に何かを実行することができます。

関連付けのコールバックも、上のような通常のコールバックとだいたい同じですが、(Active Recordオブジェクトではなく)コレクションのライフサイクルによってイベントがトリガされる点が異なります。以下の4つの関連付けコールバックを使用できます。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

これらのオプションを関連付けの宣言に追加することで、関連付けコールバックを定義できます。例：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, before_add: :check_credit_limit

  def check_credit_limit(order)
    ...
  end
end
```

Railsは、追加されるオブジェクトや削除されるオブジェクトをコールバックに(引数として)渡します。

1つのイベントで複数のコールバックを使用したい場合には、配列を使用して渡します。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders,
    before_add: [:check_credit_limit, :calculate_shipping_charges]

  def check_credit_limit(order)
    ...
  end

  def calculate_shipping_charges(order)
    ...
  end
end
```

`before_add`コールバックが例外を発生した場合、オブジェクトはコレクションに追加されません。同様に、`before_remove`で例外が発生した場合も、オブジェクトはコレクションに追加されません。

### 関連付けの拡張

Railsは自動的に関連付けのプロキシオブジェクトをビルドしますが、開発者はこれをカスタマイズすることができます。無名モジュール(anonymous module)を使用してこれらのオブジェクトを拡張(検索、作成などのメソッドを追加)することができます。例：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders do
    def find_by_order_prefix(order_number)
      find_by(region_id: order_number[0..2])
    end
  end
end
```

拡張を多くの関連付けで共有したい場合は、名前付きの拡張モジュールを使用することもできます。例：

```ruby
module FindRecentExtension
  def find_recent
    where("created_at > ?", 5.days.ago)
  end
end

class Customer < ActiveRecord::Base
  has_many :orders, -> { extending FindRecentExtension }
end

class Supplier < ActiveRecord::Base
  has_many :deliveries, -> { extending FindRecentExtension }
end
```

関連付けプロキシの内部を参照するには、`proxy_association`アクセサにある以下の3つの属性を使用します。

* `proxy_association.owner`は、関連付けを所有するオブジェクトを返します。
* `proxy_association.reflection`は、関連付けを記述するリフレクションオブジェクトを返します。
* `proxy_association.target`は、`belongs_to`または`has_one`関連付けのオブジェクトを返すか、`has_many`または`has_and_belongs_to_many`関連付けオブジェクトのコレクションを返します。