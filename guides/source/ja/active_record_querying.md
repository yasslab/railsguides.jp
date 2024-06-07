Active Record クエリインターフェイス
=============================

このガイドでは、Active Recordを利用してデータベースからデータを取り出すためのさまざまな方法について解説します。

このガイドの内容:

* 多くのメソッドや条件を駆使してレコードを検索する
* 検索されたレコードのソート順、取り出したい属性、グループ化の有無などを指定する
* 一括読み込み (eager loading) を使って、データ取り出しに必要なクエリの実行回数を減らす
* 動的検索メソッドを使う
* 複数のActive Recordメソッドをメソッドチェインで同時に利用する
* 特定のレコードが存在するかどうかをチェックする
* Active Recordモデルでさまざまな計算を行う
* リレーションでEXPLAINを実行する

--------------------------------------------------------------------------------

Active Recordクエリインターフェイスとは？
------------------------------------------

生のSQLを使ってデータベースのレコードを検索することに慣れた人がRailsに出会うと、Railsでは同じ操作をずっと洗練された方法で実現できることに気付くでしょう。Active Recordを使うことで、SQLを直に実行する必要はほぼなくなります。

Active Recordは、ユーザーに代わってデータベースにクエリを発行します。発行されるクエリは多くのデータベースシステム（MySQL、MariaDB、PostgreSQL、SQLiteなど）と互換性があります。Active Recordを使えば、利用しているデータベースシステムの種類にかかわらず同じ記法を使えます。

本ガイドのコード例では以下のモデルを使います。

TIP: 特に記さない限り、モデル中の`id`は主キーを表します。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }
end
```

```ruby
class Book < ApplicationRecord
  belongs_to :supplier
  belongs_to :author
  has_many :reviews
  has_and_belongs_to_many :orders, join_table: 'books_orders'

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
  scope :out_of_print_and_expensive, -> { out_of_print.where('price > 500') }
  scope :costs_more_than, ->(amount) { where('price > ?', amount) }
end
```

```ruby
class Customer < ApplicationRecord
  has_many :orders
  has_many :reviews
end
```

```ruby
class Order < ApplicationRecord
  belongs_to :customer
  has_and_belongs_to_many :books, join_table: 'books_orders'

  enum :status, [:shipped, :being_packed, :complete, :cancelled]

  scope :created_before, ->(time) { where(created_at: ...time) }
end
```

```ruby
class Review < ApplicationRecord
  belongs_to :customer
  belongs_to :book

  enum :state, [:not_reviewed, :published, :hidden]
end
```

```ruby
class Supplier < ApplicationRecord
  has_many :books
  has_many :authors, through: :books
end
```

![bookstoreの全モデルの図](images/active_record_querying/bookstore_models.png)

データベースからオブジェクトを取り出す
------------------------------------

Active Recordでは、データベースからオブジェクトを取り出すための検索メソッドを多数用意しています。これらの検索メソッドを利用することで、生のSQLを書かずにデータベースへの特定のクエリを実行するための引数を渡せるようになります。

以下のメソッドが用意されています。

* [`annotate`][]
* [`find`][]
* [`create_with`][]
* [`distinct`][]
* [`eager_load`][]
* [`extending`][]
* [`extract_associated`][]
* [`from`][]
* [`group`][]
* [`having`][]
* [`includes`][]
* [`joins`][]
* [`left_outer_joins`][]
* [`limit`][]
* [`lock`][]
* [`none`][]
* [`offset`][]
* [`optimizer_hints`][]
* [`order`][]
* [`preload`][]
* [`readonly`][]
* [`references`][]
* [`reorder`][]
* [`reselect`][]
* [`regroup`][]
* [`reverse_order`][]
* [`select`][]
* [`where`][]

検索メソッドには`where`や`group`といったコレクションを返すものもあれば、[`ActiveRecord::Relation`][]インスタンスを返すものもあります。また、`find`や`first`など1件のエンティティを検索するメソッドの場合、そのモデルの単一のインスタンスを返します。

`Model.find(options)`という操作を要約すると以下のようになります。

* 与えられたオプションを同等のSQLクエリに変換します。
* SQLクエリを発行し、該当する結果をデータベースから取り出します。
* 得られた結果を行ごとに同等のRubyオブジェクトとしてインスタンス化します。
* 指定されていれば、`after_find`を実行し、続いて`after_initialize`コールバックを実行します。

[`ActiveRecord::Relation`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[`annotate`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-annotate
[`create_with`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-create_with
[`distinct`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-distinct
[`eager_load`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-eager_load
[`extending`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-extending
[`extract_associated`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-extract_associated
[`find`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find
[`from`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-from
[`group`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-group
[`having`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-having
[`includes`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-includes
[`joins`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-joins
[`left_outer_joins`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-left_outer_joins
[`limit`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-limit
[`lock`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-lock
[`none`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-none
[`offset`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-offset
[`optimizer_hints`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-optimizer_hints
[`order`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-order
[`preload`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-preload
[`readonly`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-readonly
[`references`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-references
[`reorder`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reorder
[`reselect`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reselect
[`regroup`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-regroup
[`reverse_order`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reverse_order
[`select`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-select
[`where`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where

### 単一のオブジェクトを取り出す

Active Recordには、単一のオブジェクトを取り出すためのさまざま方法が用意されています。

#### `find`

`find`メソッドを使うと、与えられたどのオプションにもマッチする「主キー」に対応するオブジェクトを取り出せます。以下に例を示します。

```ruby
# 主キー（id）が10のクライアントを検索
irb> customer = Customer.find(10)
=> #<Customer id: 10, first_name: "Ryan">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.id = 10) LIMIT 1
```

`find`メソッドでマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

このメソッドを使って、複数のオブジェクトへのクエリを作成することもできます。これを行うには、`find`メソッドの呼び出し時に主キーの配列を渡します。これにより、指定の「主キー」にマッチするレコードをすべて含む配列が返されます。以下に例を示します。

```ruby
# 主キー（id）が1と10のクライアントを検索
irb> customers = Customer.find([1, 10]) # OR Customer.find(1, 10)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 10, first_name: "Ryan">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.id IN (1,10))
```

WARNING: `find`メソッドに渡された主キーの中に、どのレコードにもマッチしない主キーが**1個でも**あると、`ActiveRecord::RecordNotFound`例外が発生します。

テーブルで複合主キーを利用している場合、単一の項目を検索するときに配列を渡す必要があります。たとえば、customersテーブルの主キーが`[:store_id, :id]`と定義されている場合は、以下のように指定します。

```irb
# customerを「store_id 3」と「id 17」で検索する
irb> customers = Customer.find([3, 17])
=> #<Customer store_id: 3, id: 17, first_name: "Magda">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE store_id = 3 AND id = 17
```

複合IDで複数の顧客を検索する場合は、以下のように配列の配列を渡します。

```irb
# 複数の顧客を主キー「[1, 8]」と「[7, 15]」で検索する
irb> customers = Customer.find([[1, 8], [7, 15]]) # OR Customer.find([1, 8], [7, 15])
=> [#<Customer store_id: 1, id: 8, first_name: "Pat">, #<Customer store_id: 7, id: 15, first_name: "Chris">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (store_id = 1 AND id = 8 OR store_id = 7 AND id = 15)
```

#### `take`

[`take`][]メソッドはレコードを1件取り出します。どのレコードが取り出されるかは指定されません。以下に例を示します。

```irb
irb> customer = Customer.take
=> #<Customer id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 1
```

`Model.take`は、モデルにレコードが1つもない場合に`nil`を返します。このとき例外は発生しません。

以下のように、`take`メソッドで返すレコードの最大数を数値の引数で指定することもできます。

```ruby
irb> customers = Customer.take(2)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 220, first_name: "Sara">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 2
```

[`take!`][] メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`take`メソッドとまったく同じです。

TIP: このメソッドで取り出されるレコードは、利用するデータベースエンジンによって異なることがあります。

[`take`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-take
[`take!`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-take-21

#### `first`

[`first`][]メソッドは、デフォルトでは主キー順の最初のレコードを取り出します。以下に例を示します。

```irb
irb> customer = Customer.first
=> #<Customer id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 1
```

`first`メソッドは、モデルにレコードが1件もない場合は`nil`を返します。このとき例外は発生しません。

[デフォルトスコープ](active_record_querying.html#デフォルトスコープを適用する)が順序に関するメソッドを含んでいる場合、`first`メソッドはその順序に沿って最初のレコードを返します。

以下のように、`first`メソッドで返すレコードの最大数を数値の引数で指定することもできます。

```irb
irb> customers = Customer.first(3)
=> [#<Customer id: 1, first_name: "Lifo">, #<Customer id: 2, first_name: "Fifo">, #<Customer id: 3, first_name: "Filo">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 3
```

複合主キーを持つモデルの順序付けは、複合主キー全体を利用する形で行われます。
たとえば、Customerモデルの主キーが`[:store_id, :id]`で定義されている場合は以下のようになります。

```irb
irb> customer = Customer.first
=> #<Customer id: 2, store_id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.store_id ASC, customers.id ASC LIMIT 1
```

`order`を使って順序を変更したコレクションの場合、`first`メソッドは`order`で指定された属性に従って最初のレコードを返します。

```irb
irb> customer = Customer.order(:first_name).first
=> #<Customer id: 2, first_name: "Fifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.first_name ASC LIMIT 1
```

[`first!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`first`メソッドとまったく同じです。

[`first`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-first
[`first!`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-first-21

#### `last`

[`last`][]メソッドは、(デフォルトでは) 主キーの順序に従って最後のレコードを返します。 以下に例を示します。

```irb
irb> customer = Customer.last
=> #<Customer id: 221, first_name: "Russel">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 1
```

`last`メソッドは、モデルにレコードが1件もない場合は`nil`を返します。このとき例外は発生しません。

複合主キーを持つモデルの順序付けは、複合主キー全体を利用する形で行われます。
たとえば、Customerモデルの主キーが`[:store_id, :id]`で定義されている場合は以下のようになります。

```irb
irb> customer = Customer.last
=> #<Customer id: 221, store_id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.store_id DESC, customers.id DESC LIMIT 1
```

[デフォルトスコープ](active_record_querying.html#デフォルトスコープを適用する)が順序に関するメソッドを含んでいる場合、`last`メソッドはその順序に従って最後のレコードを返します。

`last`メソッドで返すレコードの最大数を数値の引数で指定することもできます。例:

```irb
irb> customers = Customer.last(3)
=> [#<Customer id: 219, first_name: "James">, #<Customer id: 220, first_name: "Sara">, #<Customer id: 221, first_name: "Russel">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 3
```

`order`を使って順序を変更したコレクションの場合、`last`メソッドは`order`で指定された属性に従って最後のレコードを返します。

```irb
irb> customer = Customer.order(:first_name).last
=> #<Customer id: 220, first_name: "Sara">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.first_name DESC LIMIT 1
```

[`last!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`last`メソッドとまったく同じです。

[`last`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-last
[`last!`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-last-21

#### `find_by`

[`find_by`][]メソッドは、与えられた条件にマッチするレコードのうち最初のレコードだけを返します。以下に例を示します。

```irb
irb> Customer.find_by first_name: 'Lifo'
=> #<Customer id: 1, first_name: "Lifo">

irb> Customer.find_by first_name: 'Jon'
=> nil
```

上の文は以下のように書くこともできます。

```ruby
Customer.where(first_name: 'Lifo').take
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Lifo') LIMIT 1
```

上のSQLに`ORDER BY`がない点にご注意ください。`find_by`の条件が複数のレコードにマッチする場合は、レコードの順序を一貫させるために[並び順](#並び順)を指定すべきです。

[`find_by!`][] メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`find_by`メソッドとまったく同じです。以下に例を示します。

```irb
irb> Customer.find_by! first_name: 'does not exist'
=> ActiveRecord::RecordNotFound
```

上の文は以下のように書くこともできます。

```ruby
Customer.where(first_name: 'does not exist').take!
```

[`find_by`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find_by
[`find_by!`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find_by-21

##### 条件を`id`で指定する

[`find_by`][]や[`where`][]などのメソッドで条件を指定するときに`id`を使うと、モデルの`:id`属性と一致します（これは、渡すIDが主キーでなければならない[`find`][]と異なります）。

`:id`が主キー**でない**モデルで`find_by(id:)`を使う場合は注意が必要です。たとえば、`[:store_id, :id]`が主キーとして定義されているCustomerモデルの場合を考えてみましょう。

```irb
irb> customer = Customer.last
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
irb> Customer.find_by(id: customer.id) # Customer.find_by(id: [5, 10])
=> #<Customer id: 5, store_id: 3, first_name: "Bob">
```

ここでは、複合主キー`[5, 10]`を持つ1件のレコードを検索するつもりだった可能性がありますが、Active Recordは`:id`カラムが5または10の**いずれか一方**であるレコードを検索するため、誤ったレコードを返す可能性があります。

TIP:  [`id_value`][]メソッドは、`find_by`や`where`などのfinderメソッドでレコードの`:id`カラムの値を取得する目的に利用できます。以下に例を示します。

```irb
irb> customer = Customer.last
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
irb> Customer.find_by(id: customer.id_value) # Customer.find_by(id: 10)
=> #<Customer id: 10, store_id: 5, first_name: "Joe">
```

[`id_value`]: https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-i-id_value

### 複数のオブジェクトをバッチで取り出す

多数のレコードに対して反復処理を行いたいことがあります。たとえば、多くのユーザーにニュースレターを送信したい、データをエクスポートしたいなどです。

このような処理をそのまま実装すると以下のようになるでしょう。

```ruby
# このコードはテーブルが大きい場合にメモリを大量に消費する可能性あり
Customer.all.each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

しかし上のような処理は、テーブルのサイズが大きくなるにつれて非現実的になります。`Customer.all.each`は、Active Recordに対して **テーブル全体**を一度に取り出し、しかも1行ごとにオブジェクトを生成し、その巨大なモデルオブジェクトの配列をメモリに配置するからです。もし莫大な数のレコードに対してこのようなコードをまともに実行すると、コレクション全体のサイズがメモリ容量を上回ってしまうことでしょう。

Railsでは、メモリを圧迫しないサイズにバッチを分割して処理するための方法を2とおり提供しています。1つ目は`find_each`メソッドを使う方法です。これは、レコードのバッチを1つ取り出してから、次に**各**レコードを1つのモデルとして個別にブロックにyieldします。2つ目の方法は`find_in_batches`メソッドを使う方法です。レコードのバッチを1つ取り出してから、次に**バッチ全体**をモデルの配列としてブロックにyieldします。

TIP: `find_each`メソッドと`find_in_batches`メソッドは、一度にメモリに読み込めないような大量のレコードに対するバッチ処理のためのものです。数千件のレコードに対して単にループ処理を行なう程度なら通常の検索メソッドで十分です。

#### `find_each`

[`find_each`][]メソッドは、複数のレコードを一括で取り出し、続いて _各_ レコードを1つのブロックにyieldします。以下の例では、`find_each`でバッチから1000件のレコードを一括で取り出し、各レコードをブロックにyieldします。

```ruby
Customer.find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

この処理は、必要に応じてさらにレコードのまとまりをフェッチし、すべてのレコードが処理されるまで繰り返されます。

`find_each`メソッドは上述のようにモデルのクラスに対して機能します。上で見たように、対象がリレーションの場合も同様です。

```ruby
Customer.where(weekly_subscriber: true).find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

ただしこれは順序指定がない場合に限ります。`find_each`メソッドでイテレートするには内部で順序を強制する必要があるためです。

レシーバー側に順序がある場合、[`config.active_record.error_on_ignored_order`][]フラグの状態によって振る舞いが変わります。たとえば`true`の場合は`ArgumentError`が発生し、`false`の場合は順序が無視されて警告が発生します。デフォルトは`false`です。このフラグを上書きしたい場合は`:error_on_ignore`オプション（後述）を使います。

[`config.active_record.error_on_ignored_order`]: configuring.html#config-active-record-error-on-ignored-order
[`find_each`]: https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_each

##### `find_each`のオプション

**`:batch_size`**

`:batch_size`オプションは、（ブロックに個別に渡される前に）1回のバッチで取り出すレコード数を指定します。たとえば、1回に5000件ずつ処理したい場合は以下のように指定します。

```ruby
Customer.find_each(batch_size: 5000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

**`:start`**

デフォルトでは、レコードは主キーの昇順に取り出されます。並び順冒頭のIDが不要な場合は、`:start`オプションを使ってシーケンスの開始IDを指定できます。これは、たとえば中断したバッチ処理を再開する場合などに便利です（最後に実行された処理のIDがチェックポイントとして保存済みであることが前提です）。

たとえば主キーが2000番以降のユーザーに対してニュースレターを配信する場合は、以下のようになります。

```ruby
Customer.find_each(start: 2000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

**`:finish`**

`:start`オプションと同様に、シーケンスの末尾のIDを指定したい場合は、`:finish`オプションで末尾のIDを設定できます。 `:start`と`:finish`でレコードのサブセットを指定し、その中でバッチプロセスを走らせたい時に便利です。

たとえば主キーが2000番〜10000番のユーザーに対してニュースレターを配信したい場合は、以下のようになります。

```ruby
Customer.find_each(start: 2000, finish: 10000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

他にも、同じ処理キューを複数のワーカーで手分けする場合が考えられます。たとえばワーカーごとに10000レコードずつ処理したい場合も、`:start`と`:finish`オプションにそれぞれ適切な値を設定することで実現できます。

**`:error_on_ignore`**

リレーション内に特定の順序があれば例外を発生させたい場合は、このオプションでアプリケーションの設定を上書きします。

**`:order`**

主キーの並び順（`:asc`または`:desc`）を指定します。デフォルト値は`:asc`です。

```ruby
Customer.find_each(order: :desc) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

#### `find_in_batches`

[`find_in_batches`][]メソッドは、レコードをバッチで取り出すという点で`find_each`と似ています。違うのは、`find_in_batches`は**バッチ**を個別にではなくモデルの配列としてブロックにyieldするという点です。以下の例では、与えられたブロックに対して一度に最大1000人までの顧客（customer）の配列をyieldしています。最後のブロックには残りの顧客が含まれます。

```ruby
# 1回あたり1000人の顧客の配列をadd_customersに渡す
Customer.find_in_batches do |customers|
  export.add_customers(customers)
end
```

`find_in_batches`メソッドは上述のようにモデルのクラスに対して機能します。対象がリレーションの場合も同様です。

```ruby
# 1回あたり直近のアクティブな1000人の顧客の配列をadd_customersに渡す
Customer.recently_active.find_in_batches do |customers|
  export.add_customers(customers)
end
```

ただしこれは順序指定がない場合に限ります。`find_in_batches`メソッドでイテレートするには内部で順序を強制する必要があるためです。

[`find_in_batches`]: https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_in_batches

##### `find_in_batches`のオプション

`find_in_batches`メソッドでは、`find_each`メソッドと同様のオプションを使えます。

**`:batch_size`**

`find_each`と同様に、`batch_size`はグループごとのレコード数を指定します。たとえば、レコードを2500件ずつ取り出すには以下のように指定できます。

```ruby
Customer.find_in_batches(batch_size: 2500) do |customers|
  export.add_customers(customers)
end
```

**`:start`**

`start`オプションを使うと、レコードがSELECTされるときの最初のIDを指定できます。上述のように、デフォルトではレコードを主キーの昇順でフェッチします。たとえば、ID: 5000から始まる顧客レコードを2500件ずつ取り出すには、以下のようなコードが使えます。

```ruby
Customer.find_in_batches(batch_size: 2500, start: 5000) do |customers|
  export.add_customers(customers)
end
```

**`:finish`**

`finish`オプションを使うと、レコードを取り出すときの末尾のIDを指定できます。以下は、ID: 7000までの顧客レコードをバッチで取り出す場合のコードです。

```ruby
Customer.find_in_batches(finish: 7000) do |customers|
  export.add_customers(customers)
end
```

**`:error_on_ignore`**

リレーション内に特定の順序があれば例外を発生させたい場合は、`error_on_ignore`オプションでアプリケーションの設定を上書きします。

条件
----------

[`where`][] メソッドは、返されるレコードを制限するための条件を指定します。SQL文で言う`WHERE`の部分に相当します。条件は、文字列、配列、ハッシュのいずれかの方法で与えることができます。

### 条件を文字列だけで表す

検索メソッドに条件を追加したい場合、たとえば`Book.where("title = 'Introduction to Algorithms'")`のように条件を単純に指定できます。この場合、`title`フィールドの値が'Introduction to Algorithms'であるすべてのクライアントが検索されます。

WARNING: 条件を文字列だけで構成すると、SQLインジェクションの脆弱性が発生する可能性があります。たとえば、`Book.where("title LIKE '%#{params[:title]}%'")`という書き方は危険です。次で説明するように、配列を使うのが望ましい方法です。

### 条件を配列で表す

条件で使う数値が変動する可能性がある場合、引数をどのようにすればよいでしょうか。この場合は以下のようにします。

```ruby
Book.where("title = ?", params[:title])
```

Active Recordは最初の引数を、文字列で表された条件として受け取ります。その後に続く引数は、文字列内にある疑問符 `?` と置き換えられます。

複数の条件を指定したい場合は次のようにします。

```ruby
Book.where("title = ? AND out_of_print = ?", params[:title], false)
```

上の例では、1つ目の疑問符は`params[:title]`の値で置き換えられ、2つ目の疑問符は`false`をSQL形式に変換したもの (変換方法はアダプタによって異なる) で置き換えられます。

以下のように`?`を用いるコードの書き方を強く推奨します。

```ruby
Book.where("title = ?", params[:title])
```

以下のように文字列で式展開`#{}`を使う書き方は危険であり、避ける必要があります。

```ruby
Book.where("title = #{params[:title]}")
```

条件文字列の中に変数を直接置くと、その変数はデータベースに**そのまま**渡されてしまいます。これは、悪意のある人物がエスケープされていない危険な変数を渡すことが可能になるということです。このようなコードがあると、悪意のある人物がデータベースを意のままにすることができ、データベース全体が危険にさらされます。くれぐれも、条件文字列の中に引数を直接置くことはしないでください。

TIP: SQLインジェクションの詳細については[Ruby on Railsセキュリティガイド](security.html#sqlインジェクション)を参照してください。

#### 条件でプレースホルダを使う

疑問符`(?)`をパラメータで置き換えるスタイルと同様、条件中でキーバリューのハッシュも渡せます。ここで渡されたハッシュは、条件中の対応するキーバリューの部分に置き換えられます。

```ruby
Book.where("created_at >= :start_date AND created_at <= :end_date",
  { start_date: params[:start_date], end_date: params[:end_date] })
```

このように書くことで、条件で多数の変数を使うコードが読みやすくなります。

#### 条件で`LIKE`を使う

引数はSQLインジェクションを防ぐために自動的にエスケープされますが、SQL `LIKE`ワイルドカード（つまり、`%`と`_`）はエスケープ**されません**。引数にサニタイズされていない値が使用されている場合、予期しない動作となることがあります。例えば:

```ruby
Book.where("title LIKE ?", params[:title] + "%")
```

上の例は、ユーザーが指定した文字列で始まるタイトルに一致することを意図しています。しかし、`params[:title]`に含まれる`%`または`_`はワイルドカードとして扱われるため、意外な結果をもたらします。状況によっては、データベースがインデックスを使用できなくなるため、クエリが大幅に遅くなる可能性があります。

これらの問題を回避するには、[`sanitize_sql_like`][]を使用して関連する引数のワイルドカード文字をエスケープします。

```ruby
Book.where("title LIKE ?",
  Book.sanitize_sql_like(params[:title]) + "%")
```

[`sanitize_sql_like`]: https://api.rubyonrails.org/classes/ActiveRecord/Sanitization/ClassMethods.html#method-i-sanitize_sql_like

### 条件でハッシュを使う

Active Recordは条件をハッシュで渡すこともできます。この書式を使うことで条件構文が読みやすくなります。条件をハッシュで渡す場合、ハッシュのキーには条件付けしたいフィールドを、ハッシュの値にはそのフィールドをどのように条件づけするかを、それぞれ指定します。

NOTE: ハッシュによる条件を利用できるのは、等値、範囲、サブセットのチェックだけです。

#### 等値条件

```ruby
Book.where(out_of_print: true)
```

これは以下のようなSQLを生成します。

```sql
SELECT * FROM books WHERE (books.out_of_print = 1)
```

フィールド名は文字列形式にもできます。

```ruby
Book.where('out_of_print' => true)
```

belongs_toリレーションシップの場合、Active Recordオブジェクトが値として使われていれば、モデルを指定する時に関連付けキーを利用できます。この方法はポリモーフィックリレーションシップでも同様に利用できます。

```ruby
author = Author.first
Book.where(author: author)
Author.joins(:books).where(books: { author: author })
```

ハッシュ条件は、以下のように「キーがカラムの配列である」かつ「値がタプルの配列である」タプル的な構文でも指定できます。

```ruby
Book.where([:author_id, :id] => [[15, 1], [15, 2]])
```

この構文は、以下のようにテーブルが複合主キーを利用しているリレーションをクエリするときに便利な場合があります。

```ruby
class Book < ApplicationRecord
  self.primary_key = [:author_id, :id]
end

Book.where(Book.primary_key => [[2, 1], [3, 1]])
```

#### 範囲条件

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

上の例では、昨日作成されたすべてのクライアントを検索します。内部ではSQLの`BETWEEN`文が使われます。

```sql
SELECT * FROM books WHERE (books.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

[条件を配列で表す](#条件を配列で表す)では、さらに簡潔な文例をご紹介しています。

Rubyの[終端/始端を持たない範囲オブジェクト](https://docs.ruby-lang.org/ja/latest/class/Range.html)（beginless/endless range）がサポートされており、以下のように「〜より大きい」「〜より小さい」条件の構築で利用できます。

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..)
```

上は、以下のようなSQLを生成します。

```sql
SELECT * FROM books WHERE books.created_at >= '2008-12-21 00:00:00'
```

#### サブセット条件

SQLの`IN`式でレコードを検索したい場合、条件ハッシュにそのための配列を渡せます。

```ruby
Customer.where(orders_count: [1, 3, 5])
```

上のコードを実行すると、以下のようなSQLが生成されます。

```sql
SELECT * FROM customers WHERE (customers.orders_count IN (1, 3, 5))
```

### NOT条件

SQLの`NOT`クエリは、[`where.not`][]で表せます。

```ruby
Customer.where.not(orders_count: [1, 3, 5])
```

言い換えれば、このクエリは`where`に引数を付けずに呼び出し、直後に`where`条件に`not`を渡してチェインすることで生成されています。これは以下のようなSQLを出力します。

```sql
SELECT * FROM customers WHERE (customers.orders_count NOT IN (1, 3, 5))
```

あるクエリのnull許容（nullable）カラムに、非nil値を指定したハッシュ条件がある場合、null許容カラムに`nil`値を持つレコードは返されません。

```ruby
Customer.create!(nullable_country: nil)
Customer.where.not(nullable_country: "UK")
# => []
# ただし
Customer.create!(nullable_country: "UK")
Customer.where.not(nullable_country: nil)
# => [#<Customer id: 2, nullable_country: "UK">]
```

[`where.not`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods/WhereChain.html#method-i-not

### OR条件

２つのリレーションをまたいで`OR`条件を使いたい場合は、１つ目のリレーションで[`or`][]メソッドを呼び出し、そのメソッドの引数に２つ目のリレーションを渡すことで実現できます。

```ruby
Customer.where(last_name: 'Smith').or(Customer.where(orders_count: [1, 3, 5]))
```

```sql
SELECT * FROM customers WHERE (customers.last_name = 'Smith' OR customers.orders_count IN (1, 3, 5))
```

[`or`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-or

### AND条件

`AND`条件は、`where`条件をチェインすることで構成できます。

```ruby
Customer.where(last_name: 'Smith').where(orders_count: [1, 3, 5]))
```

```sql
SELECT * FROM customers WHERE customers.last_name = 'Smith' AND customers.orders_count IN (1, 3, 5)
```

リレーション間の論理的な交差（共通集合）を表す`AND`条件は、1個目のリレーションで[`and`][]を呼び出し、その引数で2個目のリレーションを指定することで構成できます。

```ruby
Customer.where(id: [1, 2]).and(Customer.where(id: [2, 3]))
```

```sql
SELECT * FROM customers WHERE (customers.id IN (1, 2) AND customers.id IN (2, 3))
```

[`and`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-and

並び順
--------

データベースから取り出すレコードを特定の順序で並べ替えたい場合は、[`order`][]メソッドが使えます。

たとえば、ひとかたまりのレコードを取り出し、それをテーブル内の`created_at`の昇順で並べたい場合には以下のようにします。

```ruby
Book.order(:created_at)
# または
Book.order("created_at")
```

`ASC`（昇順）や`DESC`（降順）も指定できます。

```ruby
Book.order(created_at: :desc)
# または
Book.order(created_at: :asc)
# または
Book.order("created_at DESC")
# または
Book.order("created_at ASC")
```

複数のフィールドを指定して並べることもできます。

```ruby
Book.order(title: :asc, created_at: :desc)
# または
Book.order(:title, created_at: :desc)
# または
Book.order("title ASC, created_at DESC")
# または
Book.order("title ASC", "created_at DESC")
```

`order`メソッドを複数回呼び出すと、続く並び順は最初の並び順に追加されていきます。

```irb
irb> Book.order("title ASC").order("created_at DESC")
# SELECT * FROM books ORDER BY title ASC, created_at DESC
```

WARNING: 多くのデータベースシステムでは、`select`、`pluck`、`ids`メソッドを使ってフィールドを選択しています。これらのデータベースシステムでは、選択しているリストに`order`句を使ったフィールドが含まれていないと、`order`メソッドで`ActiveRecord::StatementInvalid`例外が発生します。結果から特定のフィールドを取り出す方法については、次のセクションを参照してください。

特定のフィールドだけを取り出す
-------------------------

デフォルトでは、`Model.find`を実行すると、結果セットからすべてのフィールドが選択されます。内部的にはSQLの`select *`が実行されています。

結果セットから特定のフィールドだけを取り出したい場合は、 [`select`][]メソッドが使えます。

たとえば、`out_of_print`カラムと`isbn`カラムだけを取り出したい場合は以下のようにします。

```ruby
Book.select(:isbn, :out_of_print)
# または
Book.select("isbn, out_of_print")
```

上の検索で実際に使われるSQL文は以下のようになります。

```sql
SELECT isbn, out_of_print FROM books
```

`select`を使うと、選択したフィールドだけを使ってモデルオブジェクトが初期化されるため、注意が必要です。モデルオブジェクトの初期化時に指定しなかったフィールドにアクセスしようとすると、以下のメッセージが表示されます。

```bash
ActiveModel::MissingAttributeError: missing attribute: <属性名> for Book
```

`<属性名>`は、アクセスしようとした属性です。`id`メソッドは、この`ActiveRecord::MissingAttributeError`を発生しません。このため、関連付けを扱う場合にはご注意ください。関連付けが正常に動作するには`id`メソッドが必要です。

特定のフィールドについて、重複のない一意の値を1レコードだけ取り出したい場合は、 [`distinct`][]が使えます。

```ruby
Customer.select(:last_name).distinct
```

上のコードを実行すると、以下のようなSQLが生成されます。

```sql
SELECT DISTINCT last_name FROM customers
```

一意性の制約を外すこともできます。

```ruby
# 一意のlast_namesを返す
query = Customer.select(:last_name).distinct

# 重複の有無を問わず、すべてのlast_namesを返す
query.distinct(false)
```

LimitとOffset
----------------

`Model.find`で実行されるSQLに`LIMIT`を適用したい場合は、リレーションで[`limit`][]メソッドや[`offset`][]メソッドを用いて`LIMIT`を指定できます。

`limit`メソッドは、取り出すレコード数の上限を指定します。`offset`は、レコードを返す前にスキップするレコード数を指定します。

```ruby
Customer.limit(5)
```

上を実行すると顧客が最大で5人返されます。オフセットは指定されていないので、最初の5つがテーブルから取り出されます。この時実行されるSQLは以下のような感じになります。

```sql
SELECT * FROM customers LIMIT 5
```

`offset`を追加すると以下のようになります。

```ruby
Customer.limit(5).offset(30)
```

上のコードは、顧客の最初の30人をスキップして31人目から最大5人の顧客を返します。このときのSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 5 OFFSET 30
```

グループ
-----

検索メソッドで実行されるSQLに`GROUP BY`句を追加したい場合は、[`group`][]メソッドを検索メソッドに追加できます。

たとえば、注文（order）の作成日のコレクションを検索したい場合は、以下のようにします。

```ruby
Order.select("created_at").group("created_at")
```

上のコードは、データベースで注文のある日付ごとに`Order`オブジェクトを1つ作成します。

上で実行されるSQLは以下のようなものになります。

```sql
SELECT created_at
FROM orders
GROUP BY created_at
```

### グループ化された項目の合計

グループ化した項目の合計を１つのクエリで得るには、`group`の次に[`count`][]を呼び出します。

```irb
irb> Order.group(:status).count
=> {"being_packed"=>7, "shipped"=>12}
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT COUNT (*) AS count_all, status AS status
FROM orders
GROUP BY status
```

[`count`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-count

HAVING条件
------

SQLでは、`GROUP BY`フィールドで条件を指定する場合に`HAVING`句を使います。検索メソッドで[`having`][]メソッドを使えば、`Model.find`で生成されるSQLに`HAVING`句を追加できます。

以下に例を示します。

```ruby
Order.select("created_at, sum(total) as total_price").
  group("created_at").having("sum(total) > ?", 200)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT created_at as ordered_date, sum(total) as total_price
FROM orders
GROUP BY created_at
HAVING sum(total) > 200
```

これはorderオブジェクトごとに注文日と合計金額を返します。具体的には、priceが$200を超えている注文が、dateごとにまとめられて返されます。

orderオブジェクトごとの`total_price`にアクセスするには以下のように書きます。

```ruby
big_orders = Order.select("created_at, sum(total) as total_price")
                  .group("created_at")
                  .having("sum(total) > ?", 200)

big_orders[0].total_price
# 最初のOrderオブジェクトの合計額が返される
```

条件を上書きする
---------------------

### `unscope`

[`unscope`][]で特定の条件を取り除けます。以下に例を示します。

```ruby
Book.where('id > 100').limit(20).order('id desc').unscope(:order)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM books WHERE id > 100 LIMIT 20

-- `unscope`する前のオリジナルのクエリ
SELECT * FROM books WHERE id > 100 ORDER BY id desc LIMIT 20
```

以下のように特定の`where`句で`unscope`を指定することも可能です。

```ruby
Book.where(id: 10, out_of_print: false).unscope(where: :id)
# SELECT books.* FROM books WHERE out_of_print = 0
```

`unscope`をリレーションに適用すると、それにマージされるすべてのリレーションにも影響します。

```ruby
Book.order('id desc').merge(Book.unscope(:order))
# SELECT books.* FROM books
```

[`unscope`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-unscope

### `only`

以下のように[`only`][]メソッドを使って条件を上書きできます。

```ruby
Book.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE id > 10 ORDER BY id DESC

-- `only`を使う前のオリジナルのクエリ
SELECT * FROM books WHERE id > 10 ORDER BY id DESC LIMIT 20
```

[`only`]: https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-only

### `reselect`

[`reselect`][]メソッドで以下のように既存の`select`文を上書きできます。

```ruby
Book.select(:title, :isbn).reselect(:created_at)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT books.created_at FROM books
```

`reselect`句を使わない場合と比較してみましょう。

```ruby
Book.select(:title, :isbn).select(:created_at)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT books.title, books.isbn, books.created_at FROM books
```

### `reorder`

[`reorder`][]メソッドは、以下のようにデフォルトのスコープの並び順を上書きします。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order(year_published: :desc) }
end
```

続いて以下を実行します。

```ruby
Author.find(10).books
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM authors WHERE id = 10 LIMIT 1
SELECT * FROM books WHERE author_id = 10 ORDER BY year_published DESC
```

`reorder`を使うと、以下のようにbooksで別の並び順を指定できます。

```ruby
Author.find(10).books.reorder('year_published ASC')
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM authors WHERE id = 10 LIMIT 1
SELECT * FROM books WHERE author_id = 10 ORDER BY year_published ASC
```

### `reverse_order`

[`reverse_order`][]メソッドは、並び順が指定されている場合に並び順を逆にします。

```ruby
Book.where("author_id > 10").order(:year_published).reverse_order
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY year_published DESC
```

SQLクエリで並び順を指定する句がない状態で`reverse_order`を実行すると、主キーの逆順になります。

```ruby
Book.where("author_id > 10").reverse_order
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY books.id DESC
```

このメソッドは引数を**取りません**。

### `rewhere`

[`rewhere`][]メソッドは、以下のように既存の`where`条件を上書きします。

```ruby
Book.where(out_of_print: true).rewhere(out_of_print: false)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE out_of_print = 0
```

`rewhere`句ではなく`where`句にすると、2つの`where`句のAND条件になります。

```ruby
Book.where(out_of_print: true).where(out_of_print: false)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE out_of_print = 1 AND out_of_print = 0
```

[`rewhere`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-rewhere

### `regroup`

[`regroup`][]メソッドは、既存の名前付き`group`条件をオーバーライドします。
例:

```ruby
Book.group(:author).regroup(:id)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books GROUP BY id
```

`regroup`を使わない場合、`group`句は結合されます。

```ruby
Book.group(:author).group(:id)
```

上で実行されるSQLは以下のようになります。

```sql
SELECT * FROM books GROUP BY author, id
```

[`regroup`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-regroup

Nullリレーション
-------------

[`none`][]メソッドは、チェイン（chain）可能なリレーションを返します（レコードは返しません）。このメソッドから返されたリレーションにどのような条件をチェインさせても、常に空のリレーションが生成されます。これは、メソッドまたはスコープへのチェイン可能な応答が必要で、しかも結果を一切返したくない場合に便利です。

```ruby
Book.none # 空のリレーションを返し、クエリを生成しない
```

```ruby
# highlighted_reviewsメソッドはリレーションを返すことが期待されている
Book.first.highlighted_reviews.average(:rating)
# => 本1冊あたりの平均レーティングを返す

class Book
  # レビューが5件以上の場合にレビューを返す
  # それ以外の本はレビューなしとみなす
  def highlighted_reviews
    if reviews.count > 5
      reviews
    else
      Review.none # レビュー5件未満の場合
    end
  end
end
```

読み取り専用オブジェクト
----------------

Active Recordには、返されたどのオブジェクトに対しても変更を明示的に禁止する[`readonly`][]メソッドがあります。読み取り専用を指定されたオブジェクトに対する変更の試みはすべて失敗し、`ActiveRecord::ReadOnlyRecord`例外が発生します。

```ruby
customer = Customer.readonly.first
customer.visits += 1
customer.save # ActiveRecord::ReadOnlyRecordがraiseされる
```

上のコードでは `customer`に対して明示的に`readonly`が指定されているため、`visits`の値を更新して `customer.save`を行なうと`ActiveRecord::ReadOnlyRecord`例外が発生します。

レコードを更新できないようロックする
--------------------------

ロックは、データベースのレコードを更新する際の競合状態を避け、アトミックな (=中途半端な状態のない) 更新を行なうために有用です。

Active Recordには2とおりのロック機構があります。

* 楽観的ロック（optimistic）
* 悲観的ロック（pessimistic）

### 楽観的ロック（optimistic）

楽観的ロックでは、複数のユーザーが同じレコードを同時編集することを許し、データの衝突が最小限であることを仮定しています。この方法では、レコードがオープンされてから変更されたことがあるかどうかをチェックします。そのような変更が行われ、かつ更新が無視された場合、`ActiveRecord::StaleObjectError`例外が発生します。

**楽観的ロックカラム**

楽観的ロックを使うには、テーブルに`lock_version`という名前のinteger型カラムが必要です。Active Recordは、レコードが更新されるたびに`lock_version`カラムの値を1ずつ増やします。更新リクエストが発生したときの`lock_version`の値がデータベース上の`lock_version`カラムの値よりも小さい場合、更新リクエストは失敗し、以下のように`ActiveRecord::StaleObjectError`エラーが発生します。

```ruby
c1 = Customer.find(1)
c2 = Customer.find(1)

c1.first_name = "Sandra"
c1.save

c2.first_name = "Michael"
c2.save # ActiveRecord::StaleObjectErrorが発生
```

開発者は、例外の発生後にこの例外をrescueして衝突を解決する必要があります。衝突の解決方法は、ロールバック、マージ、またはビジネスロジックに応じた解決方法のいずれかをお使いください。

`ActiveRecord::Base.lock_optimistically = false`を設定するとこの動作をオフにできます。

`ActiveRecord::Base`には、`lock_version`カラム名を上書きするための`locking_column`属性が用意されています。

```ruby
class Customer < ApplicationRecord
  self.locking_column = :lock_customer_column
end
```

### 悲観的ロック（pessimistic）

悲観的ロックでは、データベースが提供するロック機構を利用します。リレーションの構築時に`lock`を使うと、選択した行に対する排他的ロックを取得できます。`lock`を用いているリレーションは、デッドロック条件を回避するために通常トランザクションの内側にラップされます。

以下に例を示します。

```ruby
Book.transaction do
  book = Book.lock.first
  book.title = 'Algorithms, second edition'
  book.save!
end
```

バックエンドがMySQLの場合、上のセッションによって以下のSQLが生成されます。

```sql
SQL (0.2ms)   BEGIN
Book Load (0.3ms)   SELECT * FROM books LIMIT 1 FOR UPDATE
Book Update (0.4ms)   UPDATE books SET updated_at = '2009-02-07 18:05:56', title = 'Algorithms, second edition' WHERE id = 1
SQL (0.8ms)   COMMIT
```

異なる種類のロックを使いたい場合は、`lock`メソッドに生SQLを渡すことも可能です。たとえば、MySQLには`LOCK IN SHARE MODE`という式があります（レコードのロック中にも他のクエリからの読み出しを許可します）。この式を指定するには、以下のように単にlockオプションの引数で渡します。

```ruby
Book.transaction do
  book = Book.lock("LOCK IN SHARE MODE").find(1)
  book.increment!(:views)
end
```

NOTE:  この機能を使うには、`lock`メソッドで渡す生SQLがデータベースでサポートされていなければなりません。

モデルのインスタンスが既にある場合は、トランザクションを開始してその中でロックを一度に取得できます。

```ruby
book = Book.first
book.with_lock do
  # このブロックはトランザクション内で呼び出される
  # bookはロック済み
  book.increment!(:views)
end
```

テーブルを結合する
--------------

Active Recordは `JOIN`句のSQLを具体的に指定する２つの検索メソッドを提供しています。１つは`joins`、もう１つは`left_outer_joins`です。`joins`メソッドは`INNER JOIN`やカスタムクエリに使われ、`left_outer_joins`は`LEFT OUTER JOIN`クエリの生成に使われます。

### `joins`

[`joins`][]メソッドには複数の使い方があります。

#### SQLフラグメント文字列を使う

`joins`メソッドの引数に生のSQLを指定することで`JOIN`句を指定できます。

```ruby
Author.joins("INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE")
```

これによって以下のSQLが生成されます。

```sql
SELECT authors.* FROM authors INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE
```

#### 名前付き関連付けの配列/ハッシュを使う

Active Recordでは、`joins`メソッドを利用して関連付けで`JOIN`句を指定する際に、モデルで定義されている関連付け名をショートカットとして利用できます（詳しくは[Active Recordの関連付け](association_basics.html)を参照）。

以下のすべてにおいて、`INNER JOIN`による結合クエリが期待どおりに生成されます。

##### 単一関連付けを結合する

```ruby
Book.joins(:reviews)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
```

上のSQLを日本語で書くと「レビュー付きのすべての本について、Bookオブジェクトを1つ返す」となります。本1冊にレビューが1件以上ついている場合は、本が重複表示される点にご注意ください。重複のない一意の本を表示したい場合は、`Book.joins(:reviews).distinct`が使えます。

#### 複数の関連付けを結合する

```ruby
Book.joins(:author, :reviews)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN authors ON authors.id = books.author_id
  INNER JOIN reviews ON reviews.book_id = books.id
```

上のSQLを日本語で書くと「著者があり、レビューが1件以上ついている本をすべて表示する」となります。これも上と同様に、レビューが複数ある本は複数回表示されます。

##### ネストした関連付けを結合する（単一レベル）

```ruby
Book.joins(reviews: :customer)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
```

上のSQLを日本語で書くと「ある顧客によるレビューが付いている本をすべて返す」となります。

##### ネストした関連付けを結合する（複数レベル）

```ruby
Author.joins(books: [{ reviews: { customer: :orders } }, :supplier])
```

上によって以下が生成されます。

```sql
SELECT authors.* FROM authors
  INNER JOIN books ON books.author_id = authors.id
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
  INNER JOIN orders ON orders.customer_id = customers.id
INNER JOIN suppliers ON suppliers.id = books.supplier_id
```

上のSQLを日本語で書くと「レビューが付いていて、**かつ**、ある顧客が注文した本のすべての著者と、それらの本の仕入先（suppliers）を返す」となります。

#### 結合テーブルで条件を指定する

標準の[配列](#条件を配列で表す)および[文字列](#条件を文字列だけで表す)条件を使って、結合テーブルに条件を指定できます。[ハッシュ条件](#条件でハッシュを使う)の場合は、結合テーブルで条件を指定するときに特殊な構文を使います。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where('orders.created_at' => time_range).distinct
```

上は、`created_at`をSQLの`BETWEEN`式で比較することで、昨日注文を行ったすべての顧客を検索できます。

さらに読みやすい別の方法は、以下のようにハッシュ条件をネストさせることです。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where(orders: { created_at: time_range }).distinct
```

さらに高度な条件指定や既存の名前付きスコープの再利用を行いたい場合は、[`merge`][]が利用できるでしょう。最初に、`Order`モデルに新しい名前付きスコープを追加してみましょう。

```ruby
class Order < ApplicationRecord
  belongs_to :customer

  scope :created_in_time_range, ->(time_range) {
    where(created_at: time_range)
  }
end
```

これで、`created_in_time_range`スコープ内で`merge`を用いてマージできるようになります。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).merge(Order.created_in_time_range(time_range)).distinct
```

上も、SQLの`BETWEEN`式で比較することで、昨日注文を行ったすべての顧客を検索できます。

### `left_outer_joins`

関連レコードがあるかどうかにかかわらずレコードのセットを取得したい場合は、[`left_outer_joins`][] メソッドを使います。

```ruby
Customer.left_outer_joins(:reviews).distinct.select('customers.*, COUNT(reviews.*) AS reviews_count').group('customers.id')
```

上のコードは、以下のクエリを生成します。

```sql
SELECT DISTINCT customers.*, COUNT(reviews.*) AS reviews_count FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id GROUP BY customers.id
```

上のSQLを日本語で書くと「すべての顧客を返すとともに、それらの顧客がレビューを付けていればレビュー数を返し、レビューを付けていない場合はレビュー数を返さない」となります。

### `where.associated`と`where.missing`

`associated`クエリメソッドと`missing`クエリメソッドでは、関連付けの有無に基づいてレコードの集合を選択できます。

`where.associated`は以下のように使います。

```ruby
Customer.where.associated(:reviews)
```

Produces:

```sql
SELECT customers.* FROM customers
INNER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NOT NULL
```

これは「1件以上レビューした全顧客を返せ」という意味になります。

`where.missing`は以下のように使います。

```ruby
Customer.where.missing(:reviews)
```

上のコードは、以下のクエリを生成します。

```sql
SELECT customers.* FROM customers
LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
WHERE reviews.id IS NULL
```

これは「レビューをしていない全顧客を返せ」という意味になります。

関連付けをeager loadingする
--------------------------

eager loading（一括読み込み）とは、`Model.find`によって返されるオブジェクトに関連付けられたレコードを、クエリの利用回数をできるかぎり減らして読み込むためのメカニズムです。

### N + 1クエリ問題

以下のコードについて考えてみましょう。このコードは、本を10冊検索して著者の`last_name`を表示します。

```ruby
books = Book.limit(10)

books.each do |book|
  puts book.author.last_name
end
```

このコードは一見何の問題もないように見えます。しかし本当の問題は、実行されたクエリの回数が無駄に多いことなのです。上のコードでは、最初に本を10冊検索するクエリを1回発行し、次にそこから`last_name`を取り出すのにクエリを10回発行しますので、合計で **11** 回のクエリが発行されます。

#### N + 1クエリ問題を解決する

Active Recordでは、以下のメソッドを用いることで、読み込まれるすべての関連付けを事前に指定できます。

* [`includes`][]
* [`preload`][]
* [`eager_load`][]

### `includes`

`includes`を指定すると、Active Recordは指定されたすべての関連付けを最小限のクエリ回数で読み込むようになります。

上の例で言うと、`Book.limit(10)`というコードを以下のように書き直すことで、`last_name`が一括で読み込まれます。

```ruby
books = Book.includes(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

最初の例では **11** 回もクエリが実行されましたが、書き直した例ではわずか **2** 回にまで減りました。

```sql
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

#### 複数の関連付けをeager loading

Active Recordは、1つの`Model.find`呼び出しで関連付けをいくつでもeager loadingできます。これを行なうには、`includes`メソッドを呼び出して「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を指定します。

##### 複数の関連付けの配列

```ruby
Customer.includes(:orders, :reviews)
```

上のコードは、すべての顧客を表示するとともに、顧客ごとに関連付けられている注文やレビューも表示します。

##### ネストした関連付けハッシュ

```ruby
Customer.includes(orders: { books: [:supplier, :author] }).find(1)
```

上のコードは、id=1の顧客を検索し、関連付けられたすべての注文、それぞれの本の仕入先と著者を読み込みます。

#### 関連付けのeager loadingで条件を指定する

Active Recordでは、eager loadingされた関連付けに対して、`joins`のように条件を指定可能ですが、このやり方よりも[joins](#テーブルを結合する)の使用を推奨します。

とはいえ、eager loadingされた関連付けに対して条件を指定せざるを得ない場合は、以下のように普通にwhereを使っても大丈夫です。

```ruby
Author.includes(:books).where(books: { out_of_print: true })
```

このコードは、以下のように`LEFT OUTER JOIN`を含むクエリを1つ生成します。`joins`メソッドを使うと、代わりに`INNER JOIN`を使うクエリが生成されます。

```sql
SELECT authors.id AS t0_r0, ... books.updated_at AS t1_r5 FROM authors LEFT OUTER JOIN books ON books.author_id = authors.id WHERE (books.out_of_print = 1)
```

`where`条件がない場合は、通常のクエリが2つ生成されます。

NOTE: `where`がこのように動作するのは、ハッシュを渡した場合だけです。SQLフラグメント文字列を渡す場合には、強制的に結合テーブルとして扱うために `references`を使う必要があります。

```ruby
Author.includes(:books).where("books.out_of_print = true").references(:books)
```

この`includes`クエリの場合、どの著者にも本がないので、すべての著者が引き続き読み込まれます。`joins`（INNER JOIN）を使う場合、結合条件は必ずマッチ **しなければならず** 、それ以外の場合にはレコードは返されません。

NOTE: 関連付けがjoinの一部としてeager loadingされている場合、読み込んだモデルの中にカスタマイズされたselect句のフィールドが存在しなくなります。これは親レコード（または子レコード）の中で表示してよいかどうかが曖昧になってしまうためです。

### `preload`

`preload`を使うと、Active Recordは指定された関連付けを、1つの関連付けにつき1件のクエリで読み込むようにします。

N+1クエリ問題が発生した場合で再び説明すると、`preload`メソッドを使って以下のように`Book.limit(10)`を書き換えて著者（author）をプリロードできます。

```ruby
books = Book.preload(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

書き換え前は **11** 回もクエリが実行されましたが、書き直した上のコードはわずか **2** 回にまで減りました。

```sql
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

NOTE: 「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を用いる`preload`メソッドは、`includes`メソッドと同様に`Model.find`呼び出しで任意の個数の関連付けを読み込みます。ただし`includes`メソッドと異なり、eager loadingされる関連付けに条件を指定できません。

### `eager_load`

`eager_load`メソッドを使うと、Active Recordは、指定されたすべての関連付けを`LEFT OUTER JOIN`で読み込みます。

N+1クエリが発生した場合で再び説明すると、`eager_load`メソッドを使って以下のように`Book.limit(10)`を書き換えて著者（author）をeager loadingできます。

```ruby
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

書き換え前は **11** 回もクエリが実行されましたが、書き直した上のコードはわずか **2** 回にまで減りました。

```sql
SELECT DISTINCT books.id FROM books LEFT OUTER JOIN authors ON authors.id = books.author_id LIMIT 10
SELECT books.id AS t0_r0, books.last_name AS t0_r1, ...
  FROM books LEFT OUTER JOIN authors ON authors.id = books.author_id
  WHERE books.id IN (1,2,3,4,5,6,7,8,9,10)
```

NOTE: 「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を用いる`eager_load`メソッドは、`includes`メソッドと同様に`Model.find`呼び出しで任意の個数の関連付けを読み込みます。また、`includes`メソッドと同様に、eager loadingされる関連付けに条件を指定できます。

### `strict_loading`

eager loadingはN+1クエリを防止できますが、いくつかの関連付けを遅延読み込みしている可能性もあります。[`strict_loading`][]を有効にすることで、関連付けが遅延読み込みされないようにできます。

リレーションで`strict_loading`モードを有効にすると、レコードが任意の関連付けを遅延読み込みしようとしたときに`ActiveRecord::StrictLoadingViolationError`が発生します。

```ruby
user = User.strict_loading.first
user.address.city  # ActiveRecord::StrictLoadingViolationErrorが発生
user.comments.to_a # ActiveRecord::StrictLoadingViolationErrorが発生
```

[`strict_loading`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-strict_loading

### `strict_loading!`

以下のように、レコード自身で[`strict_loading!`][]を呼び出すことでstrict loadingを有効にすることも可能です。

```ruby
user = User.first
user.strict_loading!
user.address.city  # ActiveRecord::StrictLoadingViolationErrorが発生
user.comments.to_a # ActiveRecord::StrictLoadingViolationErrorが発生
```

`strict_loading!`メソッドには`:mode`引数も渡せます。
`:n_plus_one_only`を指定すると、N+1クエリを引き起こす関連付けが遅延読み込みされた場合にのみエラーをraiseするようになります。

```ruby
user.strict_loading!(mode: :n_plus_one_only)
user.address.city  # => "Tatooine"
user.comments.to_a # => [#<Comment:0x00...]
user.comments.first.likes.to_a # ActiveRecord::StrictLoadingViolationErrorが発生
```

[`strict_loading!`]: https://api.rubyonrails.org/classes/ActiveRecord/Core.html#method-i-strict_loading-21

スコープ
------

よく使うクエリをスコープに設定すると、関連オブジェクトやモデルへのメソッド呼び出しとして参照できるようになります。スコープでは、`where`、`joins`、`includes`など、これまでに登場したメソッドをすべて使えます。どのスコープメソッドも、常に`ActiveRecord::Relation`オブジェクトを返します。スコープの本体では、別のスコープなどのメソッドをスコープ上で呼び出せるようにするため、`ActiveRecord::Relation`か`nil`のいずれかを返すようにすべきです。

シンプルなスコープを設定するには、以下のようにクラスの内部に[`scope`][]メソッドを書き、スコープが呼び出されたときに実行したいクエリをそこで渡します。

```ruby
class Article < ApplicationRecord
  scope :published, -> { where(published: true) }
end
```

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

作成した`out_of_print`スコープは、以下のようにクラスメソッドとして呼び出せます。

```irb
irb> Book.out_of_print
=> #<ActiveRecord::Relation> # all out of print books
```

あるいは、以下のように`Book`オブジェクトを用いる関連付けでも呼び出せます。

```irb
irb> author = Author.first
irb> author.books.out_of_print
=> #<ActiveRecord::Relation> # all out of print books by `author`
```

スコープは、以下のようにスコープ内でチェインすることも可能です。

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
end
```

[`scope`]: https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope

### 引数を渡す

スコープには以下のように引数を渡せます。

```ruby
class Book < ApplicationRecord
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
end
```

引数付きスコープの呼び出しは、クラスメソッドの呼び出しと同様です。

```irb
irb> Book.costs_more_than(100.10)
```

ただし、スコープに引数を渡す機能は、クラスメソッドによって提供される機能を単に複製したものです。

```ruby
class Book < ApplicationRecord
  def self.costs_more_than(amount)
    where("price > ?", amount)
  end
end
```

スコープとして定義したメソッドは、関連付けオブジェクトからもアクセス可能です。

```irb
irb> author.books.costs_more_than(100.10)
```

### 条件文を使う

スコープで条件文を使うことも可能です。

```ruby
class Order < ApplicationRecord
  scope :created_before, ->(time) { where(created_at: ...time) if time.present? }
end
```

他の例と同様、これもクラスメソッドのように振る舞います。

```ruby
class Order < ApplicationRecord
  def self.created_before(time)
    where(created_at: ...time) if time.present?
  end
end
```

ただし、1つ重要な注意点があります。条件文を評価した結果が`false`になった場合であっても、スコープは常に`ActiveRecord::Relation`オブジェクトを返します。クラスメソッドの場合は`nil`を返すので、この点において振る舞いが異なります。したがって、条件文を使うクラスメソッドをチェインし、かつ、条件文のいずれかが`false`を返す場合、`NoMethodError`を発生する可能性があります。

### デフォルトスコープを適用する

あるスコープをモデルのすべてのクエリに適用したい場合、モデル自身の内部で[`default_scope`][]メソッドを使えます。

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

このモデルに対してクエリが実行されたときのSQLクエリは以下のような感じになります。

```sql
SELECT * FROM books WHERE (out_of_print = false)
```

デフォルトスコープの条件が複雑になる場合は、以下のようにスコープをクラスメソッドとして定義してもよいでしょう。

```ruby
class Book < ApplicationRecord
  def self.default_scope
    # ActiveRecord::Relationを返すべき
  end
end
```

NOTE: スコープの引数が`Hash`で与えられると、レコードを作成するときに`default_scope`も適用されます。ただし、レコードを更新する場合は適用されません。例:

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

```irb
irb> Book.new
=> #<Book id: nil, out_of_print: false>
irb> Book.unscoped.new
=> #<Book id: nil, out_of_print: nil>
```

引数に`Array`が与えられた場合は、`default_scope`クエリの引数は`Hash`のデフォルト値に変換されない点に注意が必要です。例:

```ruby
class Book < ApplicationRecord
  default_scope { where("out_of_print = ?", false) }
end
```

```irb
irb> Book.new
=> #<Book id: nil, out_of_print: nil>
```

[`default_scope`]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/Scoping/Default/ClassMethods.html#method-i-default_scope

### スコープのマージ

`where`句と同様、スコープも`AND`条件でマージできます。

```ruby
class Book < ApplicationRecord
  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }

  scope :recent, -> { where(year_published: 50.years.ago.year..) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
end
```

```irb
irb> Book.out_of_print.old
SELECT books.* FROM books WHERE books.out_of_print = 'true' AND books.year_published < 1969
```

`scope`と`where`条件を混用してマッチさせることが可能です。このとき生成される最終的なSQLでは、以下のようにすべての条件が`AND`で結合されます。

```irb
irb> Book.in_print.where(price: ...100)
SELECT books.* FROM books WHERE books.out_of_print = 'false' AND books.price < 100
```

末尾の`where`句をどうしてもスコープより優先したい場合は、[`merge`][]が使えます。

```irb
irb> Book.in_print.merge(Book.out_of_print)
SELECT books.* FROM books WHERE books.out_of_print = true
```

ただし、1つ重要な注意点があります。`default_scope`で定義した条件は、以下のように`scope`や`where`で定義した条件よりも前に配置されます。

```ruby
class Book < ApplicationRecord
  default_scope { where(year_published: 50.years.ago.year..) }

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

```irb
irb> Book.all
SELECT books.* FROM books WHERE (year_published >= 1969)

irb> Book.in_print
SELECT books.* FROM books WHERE (year_published >= 1969) AND books.out_of_print = false

irb> Book.where('price > 50')
SELECT books.* FROM books WHERE (year_published >= 1969) AND (price > 50)
```

上の例でわかるように、`default_scope`の条件は、`scope`と`where`の条件よりも前に配置されています。

[`merge`]: https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-merge

### すべてのスコープを削除する

何らかの理由でスコープをすべて解除したい場合は[`unscoped`][]メソッドが使えます。このメソッドは、モデルで指定されている`default_scope`を適用したくないクエリがある場合に特に便利です。

```ruby
Book.unscoped.load
```

このメソッドはスコープをすべて解除し、テーブルに対して通常の (スコープなしの) クエリを実行するようにします。

```irb
irb> Book.unscoped.all
SELECT books.* FROM books

irb> Book.where(out_of_print: true).unscoped.all
SELECT books.* FROM books
```

`unscoped`にはブロックも渡せます。

```irb
irb> Book.unscoped { Book.out_of_print }
SELECT books.* FROM books WHERE books.out_of_print = true
```

[`unscoped`]: https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Default/ClassMethods.html#method-i-unscoped

動的検索
---------------

Active Recordは、テーブルに定義されるすべてのフィールド（属性とも呼ばれます）に対して自動的に検索メソッド（finderメソッド）を提供します。たとえば、`Customer`モデルに`first_name`というフィールドがあると、`find_by_first_name`というメソッドがActive Recordによって自動的に作成されます。`Customer`モデルに`locked`というフィールドがあれば、`find_by_locked`というメソッドを利用できるようになります。

この動的検索メソッドの末尾に`Customer.find_by_first_name!("Ryan")`のように感嘆符 (`!`) を追加すると、該当するレコードがない場合に`ActiveRecord::RecordNotFound`エラーが発生するようになります。

`first_name`と`orders_count`を両方検索したい場合は、2つのフィールド名を`_and_`でつなぐだけでメソッドを利用できるようになります。たとえば、`Customer.find_by_first_name_and_orders_count("Ryan", 5)`といった書き方が可能です。

`enum`
-----

enumを使うと、属性で使う値を配列で定義して名前で参照できるようになります。enumがデータベースに実際に保存されるときは、値に対応する整数値が保存されます。

enumを宣言すると、enumのすべての値について以下が作成されます。

* enum値のいずれかの値を持つ（またはもたない）すべてのオブジェクトの検索に利用可能なスコープが作成される
* あるオブジェクトがenumの特定の値を持つかどうかを判定できるインスタンスメソッドを作成する
* あるオブジェクトのenum値を変更するインスタンスメソッドを作成する

たとえば以下の[`enum`][]宣言があるとします。

```ruby
class Order < ApplicationRecord
  enum :status, [:shipped, :being_packaged, :complete, :cancelled]
end
```

このとき`status` enumの[スコープ](#スコープ)が自動的に作成され、以下のように`status`の特定の値を持つ（または持たない）すべてのオブジェクトを検索できるようになります。

```irb
irb> Order.shipped
=> #<ActiveRecord::Relation> # all orders with status == :shipped
irb> Order.not_shipped
=> #<ActiveRecord::Relation> # all orders with status != :shipped
```

以下の`?`付きインスタンスメソッドは自動で作成されます。以下のようにモデルが`status` enumの値を持っているかどうかを`true`/`false`で返します。

```irb
irb> order = Order.shipped.first
irb> order.shipped?
=> true
irb> order.complete?
=> false
```

以下の`!`付きインスタンスメソッドは自動で作成されます。最初に`status`の値を更新し、次に`status`がその値に設定されたかどうかを`true`/`false`で返します。

```irb
irb> order = Order.first
irb> order.shipped!
UPDATE "orders" SET "status" = ?, "updated_at" = ? WHERE "orders"."id" = ?  [["status", 0], ["updated_at", "2019-01-24 07:13:08.524320"], ["id", 1]]
=> true
```

enumの完全なドキュメントについては[`ActiveRecord::Enum`](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)を参照してください。

[`enum`]: https://api.rubyonrails.org/classes/ActiveRecord/Enum.html#method-i-enum

メソッドチェインを理解する
---------------------------------

Active Record パターンには [メソッドチェイン (Method chaining - Wikipedia)](http://en.wikipedia.org/wiki/Method_chaining) が実装されています。これにより、複数のActive Recordメソッドをシンプルな方法で次々に適用できるようになります。

文中でメソッドチェインを利用できるのは、その前のメソッドが`ActiveRecord::Relation` (`all`、`where`、`joins`など) を１つ返す場合です。単一のオブジェクトを返すメソッド ([単一のオブジェクトを取り出す](#%E5%8D%98%E4%B8%80%E3%81%AE%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%82%92%E5%8F%96%E3%82%8A%E5%87%BA%E3%81%99)を参照) は文の末尾に置かなければなりません。

いくつか例をご紹介します。本ガイドでは一部の例のみをご紹介し、すべての例を網羅することはしません。Active Recordメソッドが呼び出されると、クエリはその時点ではすぐには生成されず、データベースへの送信もされません。クエリは、データが実際に必要になった時点で初めて生成され送信されます。したがって、以下のそれぞれの例で生成されるクエリはそれぞれ1つのみです。

### 複数のテーブルからのデータをフィルタして取得する

```ruby
Customer
  .select('customers.id, customers.last_name, reviews.body')
  .joins(:reviews)
  .where('reviews.created_at > ?', 1.week.ago)
```

上のコードから以下のようなSQLが生成されます。

```sql
SELECT customers.id, customers.last_name, reviews.body
FROM customers
INNER JOIN reviews
  ON reviews.customer_id = customers.id
WHERE (reviews.created_at > '2019-01-08')
```

### 複数のテーブルから特定のデータを取得する

```ruby
Book
  .select('books.id, books.title, authors.first_name')
  .joins(:author)
  .find_by(title: 'Abstraction and Specification in Program Development')
```

上のコードから以下のようなSQLが生成されます。

```sql
SELECT books.id, books.title, authors.first_name
FROM books
INNER JOIN authors
  ON authors.id = books.author_id
WHERE books.title = $1 [["title", "Abstraction and Specification in Program Development"]]
LIMIT 1
```

NOTE: １つのクエリが複数のレコードとマッチする場合、`find_by`は「最初」の結果だけを返し、他は返しません（上の`LIMIT 1` 文を参照）。

新しいオブジェクトを検索またはビルドする
---------------------------------

レコードを検索し、レコードがなければ作成するという連続処理はよく行われます。`find_or_create_by`および`find_or_create_by!`メソッドを使えば、これらの処理を一度に行なえます。

### `find_or_create_by`

[`find_or_create_by`][]メソッドは、指定された属性を持つレコードが存在するかどうかをチェックします。レコードがない場合は`create`が呼び出されます。以下の例を見てみましょう。

'Andy'という名前の顧客を探し、いなければ作成したいとします。これを行なうには以下を実行します。

```irb
irb> Customer.find_or_create_by(first_name: 'Andy')
=> #<Customer id: 5, first_name: "Andy", last_name: nil, title: nil, visits: 0, orders_count: nil, lock_version: 0, created_at: "2019-01-17 07:06:45", updated_at: "2019-01-17 07:06:45">
```

このメソッドによって生成されるSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO customers (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by`は、既にあるレコードか新しいレコードのいずれかを返します。上の例の場合、Andyという名前の顧客がなかったのでレコードを作成して返しました。

`create`などと同様、バリデーションがパスするかどうかによって、新しいレコードがデータベースに保存されていない可能性があります。

今度は、新しいレコードを作成するときに`locked`属性を`false`に設定したいが、それをクエリに含めたくないとします。そこで、"Andy"という名前の顧客を検索するか、その名前の顧客がいない場合は"Andy"というクライアントを作成してロックを外すことにします。

これは2とおりの方法で実装できます。1つ目は`create_with`を使う方法です。

```ruby
Customer.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

2つ目はブロックを使う方法です。

```ruby
Customer.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

このブロックは、顧客が作成されるときにだけ実行されます。このコードを再度実行すると、このブロックは実行されません。

[`find_or_create_by`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by

### `find_or_create_by!`

[`find_or_create_by!`][]を使うと、新しいレコードが無効な場合に例外を発生するようになります。バリデーション（検証）については本ガイドでは解説していませんが、たとえば以下のバリデーションを`Customer`モデルに追加したとします。

```ruby
validates :orders_count, presence: true
```

`orders_count`を指定せずに新しい`Customer`モデルを作成しようとすると、レコードは無効になって以下のように例外が発生します。

```irb
irb> Customer.find_or_create_by!(first_name: 'Andy')
ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

[`find_or_create_by!`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by-21

### `find_or_initialize_by`

[`find_or_initialize_by`][]メソッドは`find_or_create_by`と同様に動作しますが、`create`の代わりに`new`を呼ぶ点が異なります。つまり、モデルの新しいインスタンスは作成されますが、その時点ではデータベースに保存されていません。`find_or_create_by`の例を少し変えて説明を続けます。今度は'Nina'という名前の顧客が必要だとします。

```irb
irb> nina = Customer.find_or_initialize_by(first_name: 'Nina')
=> #<Customer id: nil, first_name: "Nina", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

irb> nina.persisted?
=> false

irb> nina.new_record?
=> true
```

オブジェクトはまだデータベースに保存されていないため、生成されるSQLは以下のようなものになります。

```sql
SELECT * FROM customers WHERE (customers.first_name = 'Nina') LIMIT 1
```

このオブジェクトをデータベースに保存したい場合は、単に`save`を呼び出します。

```irb
irb> nina.save
=> true
```

[`find_or_initialize_by`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_initialize_by

SQLで検索する
--------------

独自のSQLでレコードを検索したい場合は、[`find_by_sql`][]メソッドが使えます。この`find_by_sql`メソッドは、オブジェクトの配列を1つ返します。クエリがレコードを1つしか返さなかった場合にも配列が返されますのでご注意ください。たとえば、以下のクエリを実行したとします。

```irb
irb> Customer.find_by_sql("SELECT * FROM customers INNER JOIN orders ON customers.id = orders.customer_id ORDER BY customers.created_at desc")
=> [#<Customer id: 1, first_name: "Lucas" ...>, #<Customer id: 2, first_name: "Jan" ...>, ...]
```

`find_by_sql`は、カスタマイズしたデータベース呼び出しを簡単な方法で提供し、インスタンス化されたオブジェクトを返します。

[`find_by_sql`]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/Querying.html#method-i-find_by_sql

### `select_all`

`find_by_sql`は[`connection.select_all`][]と深い関係があります。`select_all`は`find_by_sql`と同様、カスタムSQLを用いてデータベースからオブジェクトを取り出しますが、取り出したオブジェクトをインスタンス化しない点が異なります。このメソッドは`ActiveRecord::Result`クラスのインスタンスを1つ返します。このオブジェクトで`to_a`を呼ぶと、各レコードに対応するハッシュを含む配列を1つ返します。

```irb
irb> Customer.connection.select_all("SELECT first_name, created_at FROM customers WHERE id = '1'").to_a
=> [{"first_name"=>"Rafael", "created_at"=>"2012-11-10 23:23:45.281189"}, {"first_name"=>"Eileen", "created_at"=>"2013-12-09 11:22:35.221282"}]
```

[`connection.select_all`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-select_all

### `pluck`

`pluck`は、指定したカラム名の値を現在のリレーションから取得するときに利用できます。引数としてカラム名のリストを渡すと、指定したカラムの値の配列を、対応するデータ型で返します。

```irb
irb> Book.where(out_of_print: true).pluck(:id)
SELECT id FROM books WHERE out_of_print = true
=> [1, 2, 3]

irb> Order.distinct.pluck(:status)
SELECT DISTINCT status FROM orders
=> ["shipped", "being_packed", "cancelled"]

irb> Customer.pluck(:id, :first_name)
SELECT customers.id, customers.first_name FROM customers
=> [[1, "David"], [2, "Fran"], [3, "Jose"]]
```

`pluck`を使えば、以下のようなコードをシンプルなものに置き換えられます。

```ruby
Customer.select(:id).map { |c| c.id }
# または
Customer.select(:id).map(&:id)
# または
Customer.select(:id, :first_name).map { |c| [c.id, c.first_name] }
```

上は以下に置き換えられます。

```ruby
Customer.pluck(:id)
# または
Customer.pluck(:id, :first_name)
```

`select`と異なり、`pluck`はデータベースから受け取った結果を直接Rubyの配列に変換してくれます。そのための`ActiveRecord`オブジェクトを事前に構成しておく必要はありません。従って、このメソッドは大規模なクエリや利用頻度の高いクエリで使うとパフォーマンスが向上します。ただし、オーバーライドを行なうモデルメソッドは使えません。以下に例を示します。

```ruby
class Customer < ApplicationRecord
  def name
    "私は#{first_name}"
  end
end
```

```irb
irb> Customer.select(:first_name).map &:name
=> ["私はDavid", "私はJeremy", "私はJose"]

irb> Customer.pluck(:first_name)
=> ["David", "Jeremy", "Jose"]
```

単一テーブルのフィールド読み出しに加えて、複数のテーブルでも同じことができます。

```irb
irb> Order.joins(:customer, :books).pluck("orders.created_at, customers.email, books.title")
```

さらに`pluck`は、`select`などの`Relation`スコープと異なり、クエリを直接トリガするので、その後ろに他のスコープをチェインできません。ただし、構成済みのスコープを`pluck`の前に置くことは可能です。

```irb
irb> Customer.pluck(:first_name).limit(1)
NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

irb> Customer.limit(1).pluck(:first_name)
=> ["David"]
```

NOTE: 知っておくと良い注意点は、リレーションオブジェクトにincludesがあると、eager loadingが不必要なクエリにおいてでも、`pluck`がeager loadingを引き起こすことです。以下に例を示します。

```irb
irb> assoc = Customer.includes(:reviews)
irb> assoc.pluck(:id)
SELECT "customers"."id" FROM "customers" LEFT OUTER JOIN "reviews" ON "reviews"."id" = "customers"."review_id"
```

これを回避する方法の1つは、以下のようにincludesを`unscope`することです。

```irb
irb> assoc.unscope(:includes).pluck(:id)
```

[`pluck`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-pluck

### `pick`

[`pick`][]は、指定したカラム名の値を現在のリレーションから取得するときに利用できます。引数としてカラム名のリストを渡すと、指定したカラムの値の最初の行を、対応するデータ型で返します。

`pick`は、`relation.limit(1).pluck(*column_names).first`のショートハンドです。主に、既に1行に制限されたリレーションがある場合に有用です。

`pick`を使うと、以下のようなコードをシンプルなものに置き換えられます。

```ruby
Customer.where(id: 1).pluck(:id).first
```

上のコードは以下のように置き換えられます。

```ruby
Customer.where(id: 1).pick(:id)
```

[`pick`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-pick

### `ids`

[`ids`][]は、テーブルの主キーを使っているリレーションのIDをすべて取り出すのに使えます。

```irb
irb> Customer.ids
SELECT id FROM customers
```

```ruby
class Customer < ApplicationRecord
  self.primary_key = "customer_id"
end
```

```irb
irb> Customer.ids
SELECT customer_id FROM customers
```

[`ids`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-ids

オブジェクトの存在チェック
--------------------

オブジェクトが存在するかどうかをチェックするには[`exists?`][]メソッドを使います。このメソッドは、`find`と同様のクエリを使ってデータベースにクエリを送信しますが、オブジェクトのコレクションではなく`true`または`false`を返します。

```ruby
Customer.exists?(1)
```

`exists?`の引数には複数の値を渡せます。ただし、それらの値のうち1つでも存在していれば、他の値が存在していなくても`true`を返します。

```ruby
Customer.exists?(id: [1, 2, 3])
# または
Customer.exists?(first_name: ['Jane', 'Sergei'])
```

`exists?`メソッドは、引数なしでモデルやリレーションに使うことも可能です。

```ruby
Customer.where(first_name: 'Ryan').exists?
```

上の例では、`first_name`が'Ryan'のクライアントが1人でもいれば`true`を返し、それ以外の場合は`false`を返します。

```ruby
Customer.exists?
```

上の例では、`Customer`テーブルが空なら`false`を返し、それ以外の場合は`true`を返します。

モデルやリレーションでの存在チェックには`any?`や`many?`も使えます。`many?`はSQLの`COUNT`で存在をチェックします。

```ruby
# モデル経由
Order.any?
# SELECT 1 FROM orders LIMIT 1
Order.many?
# SELECT COUNT(*) FROM (SELECT 1 FROM orders LIMIT 2)

# 名前付きスコープ経由
Order.shipped.any?
# SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 1
Order.shipped.many?
# SELECT COUNT(*) FROM (SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 2)

# リレーション経由
Book.where(out_of_print: true).any?
Book.where(out_of_print: true).many?

# 関連付け経由
Customer.first.orders.any?
Customer.first.orders.many?
```

[`exists?`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F

計算
------------

このセクションでは冒頭で[`count`][]メソッドを例に説明していますが、ここで説明されているオプションは以下のすべてのサブセクションにも該当します。

あらゆる計算メソッドは、モデルに対して直接実行できます。

```irb
irb> Customer.count
SELECT COUNT(*) FROM customers
```

リレーションに対しても直接実行できます。

```irb
irb> Customer.where(first_name: 'Ryan').count
SELECT COUNT(*) FROM customers WHERE (first_name = 'Ryan')
```

この他にも、リレーションに対してさまざまな検索メソッドを利用して複雑な計算を行なえます。

```irb
irb> Customer.includes("orders").where(first_name: 'Ryan', orders: { status: 'shipped' }).count
```

上のコードは以下を実行します。

```sql
SELECT COUNT(DISTINCT customers.id) FROM customers
  LEFT OUTER JOIN orders ON orders.customer_id = customers.id
  WHERE (customers.first_name = 'Ryan' AND orders.status = 0)
```

### `count`

モデルのテーブルに含まれるレコードの個数を数えるには`Customer.count`が使えます。返されるのはレコードの個数です。肩書きを指定して顧客の数を数えるときは`Customer.count(:title)`と書けます。

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

### `average`

テーブルに含まれる特定の数値の平均を得るには、そのテーブルを持つクラスで[`average`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.average("subtotal")
```

返される値は、そのフィールドの平均値です。通常3.14159265のような浮動小数点になります。

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

[`average`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-average

### `minimum`

テーブルに含まれるフィールドの最小値を得るには、そのテーブルを持つクラスで[`minimum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.minimum("subtotal")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

[`minimum`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-minimum

### `maximum`

テーブルに含まれるフィールドの最大値を得るには、そのテーブルを持つクラスに対して[`maximum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.maximum("subtotal")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

[`maximum`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-maximum

### `sum`

テーブルに含まれるフィールドのすべてのレコードにおける合計を得るには、そのテーブルを持つクラスに対して[`sum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.sum("subtotal")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

[`sum`]: https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-sum

EXPLAINを実行する
---------------

リレーションでは[`explain`][]を実行できます。EXPLAINの出力はデータベースによって異なります。

```ruby
Customer.where(id: 1).joins(:orders).explain
```

上では以下のような結果が生成されます。

```sql
EXPLAIN SELECT `customers`.* FROM `customers` INNER JOIN `orders` ON `orders`.`customer_id` = `customers`.`id` WHERE `customers`.`id` = 1
+----+-------------+------------+-------+---------------+
| id | select_type | table      | type  | possible_keys |
+----+-------------+------------+-------+---------------+
|  1 | SIMPLE      | customers  | const | PRIMARY       |
|  1 | SIMPLE      | orders     | ALL   | NULL          |
+----+-------------+------------+-------+---------------+
+---------+---------+-------+------+-------------+
| key     | key_len | ref   | rows | Extra       |
+---------+---------+-------+------+-------------+
| PRIMARY | 4       | const |    1 |             |
| NULL    | NULL    | NULL  |    1 | Using where |
+---------+---------+-------+------+-------------+

2 rows in set (0.00 sec)
```

上の結果はMySQLの場合です。

Active Recordは、対応するデータベースシェルの出力をエミュレーションして整形します。同じクエリをPostgreSQLアダプタで実行すると、以下のような結果が得られます。

```sql
EXPLAIN SELECT "customers".* FROM "customers" INNER JOIN "orders" ON "orders"."customer_id" = "customers"."id" WHERE "customers"."id" = $1 [["id", 1]]
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop  (cost=4.33..20.85 rows=4 width=164)
    ->  Index Scan using customers_pkey on customers  (cost=0.15..8.17 rows=1 width=164)
          Index Cond: (id = '1'::bigint)
    ->  Bitmap Heap Scan on orders  (cost=4.18..12.64 rows=4 width=8)
          Recheck Cond: (customer_id = '1'::bigint)
          ->  Bitmap Index Scan on index_orders_on_customer_id  (cost=0.00..4.18 rows=4 width=0)
                Index Cond: (customer_id = '1'::bigint)
(7 rows)
```

eager loadingを使用している場合、内部的には複数のクエリがトリガされることがあり、このとき一部のクエリが先行するクエリの結果を必要とすることがあります。このためexplainは、このクエリを実際に実行した後で、クエリプランを要求します。以下に例を示します。

```ruby
Customer.where(id: 1).includes(:orders).explain
```

MySQLとMariaDBでは以下の結果を生成します。

```sql
EXPLAIN SELECT `customers`.* FROM `customers`  WHERE `customers`.`id` = 1
+----+-------------+-----------+-------+---------------+
| id | select_type | table     | type  | possible_keys |
+----+-------------+-----------+-------+---------------+
|  1 | SIMPLE      | customers | const | PRIMARY       |
+----+-------------+-----------+-------+---------------+
+---------+---------+-------+------+-------+
| key     | key_len | ref   | rows | Extra |
+---------+---------+-------+------+-------+
| PRIMARY | 4       | const |    1 |       |
+---------+---------+-------+------+-------+

1 row in set (0.00 sec)

EXPLAIN for: SELECT `orders`.* FROM `orders`  WHERE `orders`.`customer_id` IN (1)
+----+-------------+--------+------+---------------+
| id | select_type | table  | type | possible_keys |
+----+-------------+--------+------+---------------+
|  1 | SIMPLE      | orders | ALL  | NULL          |
+----+-------------+--------+------+---------------+
+------+---------+------+------+-------------+
| key  | key_len | ref  | rows | Extra       |
+------+---------+------+------+-------------+
| NULL | NULL    | NULL |    1 | Using where |
+------+---------+------+------+-------------+


1 row in set (0.00 sec)
```

PostgreSQLの場合は以下のような結果を生成します。

```sql
  Customer Load (0.3ms)  SELECT "customers".* FROM "customers" WHERE "customers"."id" = $1  [["id", 1]]
  Order Load (0.3ms)  SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = $1  [["customer_id", 1]]
=> EXPLAIN SELECT "customers".* FROM "customers" WHERE "customers"."id" = $1 [["id", 1]]
                                    QUERY PLAN
----------------------------------------------------------------------------------
 Index Scan using customers_pkey on customers  (cost=0.15..8.17 rows=1 width=164)
   Index Cond: (id = '1'::bigint)
(2 rows)
```

[`explain`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-explain

### Explainのオプション

データベースとそれをサポートするアダプタ（現在はPostgreSQLとMySQL）については、より深い分析を行うためのオプションを渡すことが可能です。

PostgreSQLの場合は以下のようになります。

```ruby
Customer.where(id: 1).joins(:orders).explain(:analyze, :verbose)
```

上のコードは以下を生成します。

```sql
EXPLAIN (ANALYZE, VERBOSE) SELECT "shop_accounts".* FROM "shop_accounts" INNER JOIN "customers" ON "customers"."id" = "shop_accounts"."customer_id" WHERE "shop_accounts"."id" = $1 [["id", 1]]
                                                                   QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.30..16.37 rows=1 width=24) (actual time=0.003..0.004 rows=0 loops=1)
   Output: shop_accounts.id, shop_accounts.customer_id, shop_accounts.customer_carrier_id
   Inner Unique: true
   ->  Index Scan using shop_accounts_pkey on public.shop_accounts  (cost=0.15..8.17 rows=1 width=24) (actual time=0.003..0.003 rows=0 loops=1)
         Output: shop_accounts.id, shop_accounts.customer_id, shop_accounts.customer_carrier_id
         Index Cond: (shop_accounts.id = '1'::bigint)
   ->  Index Only Scan using customers_pkey on public.customers  (cost=0.15..8.17 rows=1 width=8) (never executed)
         Output: customers.id
         Index Cond: (customers.id = shop_accounts.customer_id)
         Heap Fetches: 0
 Planning Time: 0.063 ms
 Execution Time: 0.011 ms
(12 rows)
```

MySQLまたはMariaDBの場合は、以下のようになります。

```ruby
Customer.where(id: 1).joins(:orders).explain(:analyze)
```

上のコードは以下を生成します。

```sql
ANALYZE SELECT `shop_accounts`.* FROM `shop_accounts` INNER JOIN `customers` ON `customers`.`id` = `shop_accounts`.`customer_id` WHERE `shop_accounts`.`id` = 1
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | r_rows | filtered | r_filtered | Extra                          |
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL          | NULL | NULL    | NULL | NULL | NULL   | NULL     | NULL       | no matching row in const table |
+----+-------------+-------+------+---------------+------+---------+------+------+--------+----------+------------+--------------------------------+
1 row in set (0.00 sec)
```

NOTE: EXPLAINやANALYZEのオプションは、MySQLやMariaDBのバージョンによって異なります。

- [MySQL 5.7][MySQL5.7-explain]
- [MySQL 8.0][MySQL8-explain]
- [MariaDB][MariaDB-explain]

[MySQL5.7-explain]: https://dev.mysql.com/doc/refman/5.7/en/explain.html
[MySQL8-explain]: https://dev.mysql.com/doc/refman/8.0/en/explain.html
[MariaDB-explain]: https://mariadb.com/kb/en/analyze-and-explain-statements/

### EXPLAINの出力結果を解釈する

EXPLAINの出力を解釈することは、本ガイドの範疇を超えます。
以下の情報を参考にしてください。

* SQLite3: [EXPLAIN QUERY PLAN](https://www.sqlite.org/eqp.html)

* MySQL: [EXPLAIN 出力フォーマット](https://dev.mysql.com/doc/refman/8.0/ja/explain-output.html) （v8.0日本語）

* MariaDB: [EXPLAIN](https://mariadb.com/kb/en/explain/)

* PostgreSQL: [EXPLAINの利用](https://www.postgresql.jp/document/current/html/using-explain.html)
