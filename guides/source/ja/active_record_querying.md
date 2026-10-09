Active Record クエリインターフェイス
=============================

このガイドでは、Active Recordを利用してデータベースからデータを取り出すためのさまざまな方法について解説します。

このガイドの内容:

* さまざまなメソッドや条件を駆使してレコードを検索する
* 検索されたレコードのソート順、取り出したい属性、グループ化の有無などを指定する
* データを効率よく取り出す
* テーブルをjoinする方法、複数のテーブルにあるデータを扱う方法
* 作成するクエリロジックをスコープで再利用可能にする
* 特定のレコードが存在するかどうかをチェックする
* Active Recordモデルでさまざまな計算を行う
* ロック機構を用いてコンカレントなアクセス制御を行う
* `explain`でクエリを分析する

--------------------------------------------------------------------------------

Active Recordクエリインターフェイスについて
------------------------------------------

Active Recordは、生SQLを直接扱うことに慣れている開発者に、同じ操作をより読みやすく表現力の高い形で行う方法を提供します。
Active Recordは、多くのデータベースシステムで利用でき（MySQL、MariaDB、PostgreSQL、SQLiteなど）、メソッドベースのインターフェイスは、利用するデータベースにかかわらず統一されます。

INFO: 本ガイドを最大限に活用するには、リレーショナルデータベース（RDBMS）とSQL（Structured Query Language）の知識があると役に立ちます。詳しくはこちらの[SQLチュートリアル][`sqlcourse`]や[RDBMSチュートリアル][`rdbmsinfo`]を参照してください（いずれも英語版です）。

他にも本ガイドに関連する便利なガイドが多数あります。

* [Active Record の基礎](active_record_basics.html) - Active Recordのモデル、関連付け、バリデーションの基礎を学べます
* [Active Record マイグレーション](active_record_migrations.html) - データベーススキーマの変更方法を学べます
* [Active Record バリデーション](active_record_validations.html) - データを保存する前にバリデーション（検証）する方法を学べます
* [Active Record コールバック](active_record_callbacks.html) - オブジェクトのライフサイクルで特定のイベントにコードを紐づける方法を学べます
* [Active Record の関連付け](association_basics.html) - Active Recordのモデル同士をつなげる方法を学べます
* [Active Record の複合主キー](active_record_composite_primary_keys.html) - 複合主キーの使い方を学べます
* [Active Record のトランザクション](active_record_basics.html) - データベーストランザクションについて学べます（訳注: 原文はリンク切れです）

書店サービスで使うモデルの例
-------------------------

本ガイドで用いるコード例では、以下のモデルを参照します。

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
  has_and_belongs_to_many :orders, join_table: "books_orders"

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
  scope :out_of_print_and_expensive, -> { out_of_print.where("price > 500") }
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
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
  has_and_belongs_to_many :books, join_table: "books_orders"

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

NOTE: 特に指定のない場合は、モデルの`id`を主キーとして使います。

![bookstoreの全モデルの図](images/active_record_querying/bookstore_models.png)

データベースからレコードを取り出す
------------------------------------

Active Recordでは、データベースからオブジェクトを取り出すための検索メソッド（finder methods）を多数用意しています。これらの検索メソッドを利用することで、生のSQLを書かずにデータベースへの特定のクエリを実行するための引数を渡せるようになります。

このセクションでは、よく使われる検索メソッドの一部を扱います。

* [`find`](#find)
* [`take`](#take)
* [`first`](#first)
* [`last`](#last)
* [`find_by`](#find-by)

この他のクエリメソッド（[`where`](#レコードをフィルタで絞り込む)や[`group`](#レコードをグループ化する)など）については、本ガイドで後述します。

クエリメソッドや検索メソッドの完全なリストについては、APIドキュメントの[`ActiveRecord::QueryMethods`][]や[`ActiveRecord::FinderMethods`][]を参照してください。

`where`や`group`のようにコレクションを返す検索メソッドは、[`ActiveRecord::Relation`][]インスタンスを返します。また、`find`や`first`など1件のエンティティを検索するメソッドの場合、そのモデルの単一のインスタンスを返します。

`ActiveRecord::Relation`の主な操作を要約すると以下のようになります。

* 与えられたオプションを同等のSQLクエリに変換します。
* SQLクエリを発行し、該当する結果をデータベースから取り出します。
* 得られた結果を行ごとに同等のRubyオブジェクトとしてインスタンス化します。
* 指定されていれば、`after_find`を実行し、続いて`after_initialize`コールバックを実行します。

[`ActiveRecord::Relation`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[`ActiveRecord::QueryMethods`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html
[`ActiveRecord::FinderMethods`]:
    https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html
[`distinct`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-distinct
[`eager_load`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-eager_load
[`find`]:
    https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find
[`group`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-group
[`having`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-having
[`includes`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-includes
[`joins`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-joins
[`left_outer_joins`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-left_outer_joins
[`limit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-limit
[`lock`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-lock
[`none`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-none
[`offset`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-offset
[`order`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-order
[`preload`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-preload
[`readonly`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-readonly
[`references`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-references
[`reorder`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reorder
[`reselect`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reselect
[`regroup`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-regroup
[`reverse_order`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-reverse_order
[`select`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-select
[`where`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where
[`with_lock`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html#method-i-with_lock
[`sqlcourse`]: https://www.khanacademy.org/computing/computer-programming/sql
[`rdbmsinfo`]: https://www.devart.com/what-is-rdbms/

### 単一のオブジェクトを取り出す

Active Recordには、単一のオブジェクトを取り出すためのさまざまな方法が用意されています。

#### `find`

[`find`][]メソッドを使うと、与えられたどのオプションにもマッチする「主キー」に対応するオブジェクトを取り出せます。以下に例を示します。

```irb
# 主キー（id）が10の顧客を検索
store(dev)> customer = Customer.find(10)
=> #<Customer id: 10, first_name: "Ryan">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.id = 10) LIMIT 1
```

`find`メソッドでマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

このメソッドを使って、複数のレコードを取り出すクエリも作成できます。これを行うには、`find`メソッドの呼び出し時に主キーの配列を渡します。これにより、指定の「主キー」にマッチするレコードをすべて含む配列が返されます。以下に例を示します。

```irb
# 主キー（id）が1と10の顧客を検索
store(dev)> customers = Customer.find([1, 10]) # OR Customer.find(1, 10)
=> [#<Customer id: 1, first_name: "Lifo">,
    #<Customer id: 10, first_name: "Ryan">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.id IN (1,10))
```

WARNING: `find`メソッドに渡された主キーの中に、どのレコードにもマッチしない主キーが**1個でも**あると、`ActiveRecord::RecordNotFound`例外が発生します。

テーブルで[複合主キー](active_record_composite_primary_keys.html)を利用している場合、単一の項目を検索するときに配列を渡す必要があります。詳細や例については[複合主キーガイド](active_record_composite_primary_keys.html#findの場合)を参照してください。

#### `take`

[`take`][]メソッドはレコードを1件取り出します。どのレコードが取り出されるかは指定されません。以下に例を示します。

```irb
store(dev)> customer = Customer.take
=> #<Customer id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 1
```

`take`メソッドは、マッチするレコードが見つからない場合に`nil`を返します。このとき例外は発生しません。

以下のように、`take`メソッドで返すレコードの最大数を数値の引数で指定することもできます。

```irb
store(dev)> customers = Customer.take(2)
=> [#<Customer id: 1, first_name: "Lifo">,
    #<Customer id: 220, first_name: "Sara">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 2
```

[`take!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`take`メソッドとまったく同じです。

INFO: `take`メソッドでは`ORDER BY`句が指定されないため、取り出されるレコードはデータベースエンジンによって異なる可能性があります。明示的にソート順を指定していないSQLでは、どのレコードが返されるかが保証されません。

[`take`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-take
[`take!`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-take-21

#### `first`

[`first`][]メソッドは、デフォルトでは主キー順の最初のレコードを取り出します。以下に例を示します。

```irb
store(dev)> customer = Customer.first
=> #<Customer id: 1, first_name: "Lifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 1
```

`first`メソッドは、マッチするレコードが見つからない場合に`nil`を返します。このとき例外は発生しません。

[デフォルトスコープ](#デフォルトスコープを適用する)が[`order`](#レコードを並べ替える)メソッドを含んでいる場合、`first`メソッドはその順序に沿って最初のレコードを返します。

以下のように、`first`メソッドで返すレコードの最大数を数値の引数で指定することもできます。

```irb
store(dev)> customers = Customer.first(3)
=> [#<Customer id: 1, first_name: "Lifo">,
    #<Customer id: 2, first_name: "Fifo">,
    #<Customer id: 3, first_name: "Filo">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id ASC LIMIT 3
```

モデルで[複合主キー](active_record_composite_primary_keys.html)を利用している場合の検索メソッドや並び順について詳しくは、[複合主キーガイド](active_record_composite_primary_keys.html)を参照してください。

コレクションの順序を`order`メソッドで変更した場合、`first`メソッドは`order`で指定された属性に従って最初のレコードを返します。

```irb
store(dev)> customer = Customer.order(:first_name).first
=> #<Customer id: 2, first_name: "Fifo">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.first_name ASC LIMIT 1
```

[`first!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`first`メソッドとまったく同じです。

[`first`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-first
[`first!`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-first-21

#### `last`

[`last`][]メソッドは、（デフォルトでは）主キーの順序に従って最後のレコードを返します。以下に例を示します。

```irb
store(dev)> customer = Customer.last
=> #<Customer id: 221, first_name: "Russel">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 1
```

`last`メソッドは、マッチするレコードが見つからない場合に`nil`を返します。このとき例外は発生しません。

モデルで[複合主キー](active_record_composite_primary_keys.html)を利用している場合の検索メソッドや並び順について詳しくは、[複合主キーガイド](active_record_composite_primary_keys.html#findの場合)を参照してください。

[デフォルトスコープ](#デフォルトスコープを適用する)が[`order`](#レコードを並べ替える)メソッドを含んでいる場合、`last`メソッドはその順序に沿って最後のレコードを返します。

`last`メソッドで返すレコードの最大数を数値の引数で指定することも可能です。

```irb
store(dev)> customers = Customer.last(3)
=> [#<Customer id: 219, first_name: "James">,
    #<Customer id: 220, first_name: "Sara">,
    #<Customer id: 221, first_name: "Russel">]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.id DESC LIMIT 3
```

`order`を使って順序を変更したコレクションの場合、`last`メソッドは`order`で指定された属性に従って最後のレコードを返します。

```irb
store(dev)> customer = Customer.order(:first_name).last
=> #<Customer id: 220, first_name: "Sara">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers ORDER BY customers.first_name DESC LIMIT 1
```

[`last!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`last`メソッドとまったく同じです。

[`last`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-last
[`last!`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-last-21

#### `find_by`

[`find_by`][]メソッドは、与えられた条件にマッチするレコードのうち最初のレコードだけを返します。以下に例を示します。

```irb
store(dev)> Customer.find_by(first_name: "Lifo")
=> #<Customer id: 1, first_name: "Lifo">

store(dev)> Customer.find_by(first_name: "Jon")
=> nil
```

上の文は以下のようにも書けます。

```ruby
Customer.where(first_name: "Lifo").take
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM customers WHERE (customers.first_name = "Lifo") LIMIT 1
```

上のSQLに`ORDER BY`がない点にご注意ください。`find_by`の条件が複数のレコードにマッチする場合は、レコードの順序を一貫させるために[並び順](#レコードを並べ替える)を指定する必要があります。

[`find_by!`][]メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`find_by`メソッドとまったく同じです。以下に例を示します。

```irb
store(dev)> Customer.find_by!(first_name: "does not exist")
ActiveRecord::RecordNotFound
```

上の文は以下のようにも書けます。

```ruby
Customer.where(first_name: "does not exist").take!
```

モデルで[複合主キー](active_record_composite_primary_keys.html)を利用している場合は、複合主キーガイドの[条件で`:id`を指定する場合](active_record_composite_primary_keys.html#条件で-idを指定する場合)で`find_by(id:)`の振る舞いを参照してください。

[`find_by`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find_by
[`find_by!`]:
  https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find_by-21

#### 動的な検索メソッド

Active Recordは、テーブルで定義したあらゆるフィールド（属性とも呼ばれます）について検索メソッド（finder methods）を動的に提供します。
たとえば、`Customer`モデルに`first_name`というフィールドがあると、何もしなくてもActive Recordによって`find_by_first_name`という検索メソッドが使えるようになります。

```irb
store(dev)> Customer.find_by_first_name("Bhumi")
=> #<Customer id: 25, first_name: "Bhumi">
```

同様に、`Customer`モデルに`locked`があれば、これにも`find_by_locked`という検索メソッドが「生えてきます」。

動的な検索メソッド名の末尾に`!`を追加すると、レコードが見つからない場合に`ActiveRecord::RecordNotFound`エラーが発生するようになります。

```irb
store(dev)> Customer.find_by_first_name!("Ryan")
ActiveRecord::RecordNotFound
```

`first_name`と`orders_count`を両方使って検索したい場合は、以下の`find_by_first_name_and_orders_count`のようにフィールド名同士を`_and_`でつなぐことで、これらの検索メソッドをチェインできます。

```irb
store(dev)> Customer.find_by_first_name_and_orders_count("Bhumi", 5)
=> #<Customer id: 25, first_name: "Bhumi">
```

### 複数のレコードを取り出す

Active Recordには、データベースから複数のレコードをまとめて取り出すメソッドが多数用意されています。
最も基本的なメソッドは[`all`][]で、これはモデル内の全レコードを返します。

```irb
store(dev)> customers = Customer.all
=> [#<Customer id: 1, first_name: "Lifo">,
    #<Customer id: 2, first_name: "Fifo">, ...]
```

上のRubyコードは以下のSQLと同等です。

```sql
SELECT * FROM customers
```

`all`メソッドが実際に返すのは`ActiveRecord::Relation`オブジェクトです。そのおかげで、そこに追加のクエリメソッドをチェインできます。
たとえば、以下のように[`where`][]メソッドを組み合わせることで、レコードをフィルタで絞り込めます。

```irb
store(dev)> customers = Customer.all.where(active: true)
=> [#<Customer id: 1, first_name: "Lifo", active: true>,
    #<Customer id: 3, first_name: "Joe", active: true>]
```

これは以下のRubyコードと同じです。

```ruby
customers = Customer.where(active: true)
```

以下は同等のSQLです。

```sql
SELECT * FROM customers WHERE (customers.active = true)
```

`all`は`ActiveRecord::Relation`を返します。リレーションはlazy loading（遅延読み込み）されるので、`all`を最初に呼び出しても呼び出さなくても、クエリの振る舞いは変わりません。

NOTE: Railsコンソールで`Customer.all`を実行すると、クエリが即座に実行されているように見えます。これは、コンソールでは戻り値の表示に`inspect`呼び出しが使われているためです。`inspect`はレコードを読み込みます。

その他の[`order`][]、[`limit`][]、[`group`][]などのメソッドもクエリの絞り込みに使えます。これらのメソッドについて詳しくは、「[レコードをフィルタで絞り込む](#レコードをフィルタで絞り込む)」「[レコードを並べ替える](#レコードを並べ替える)」「[レコード件数を制限する](#レコード件数を制限する)」「[レコードをグループ化する](#レコードをグループ化する)」セクションで後述します。

TIP: データセットの量が多い場合は、全レコードが一挙にメモリに読み込まれることを防ぐために、本セクションで後述するバッチ処理用のメソッドの利用を検討してください。

[`all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-all
[`where`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where
[`order`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-order
[`limit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-limit
[`group`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-group

### メソッドチェインを理解する

Active Recordは[メソッドチェイン](https://en.wikipedia.org/wiki/Method_chaining)をサポートしています。これにより、複数のActive Recordメソッドをシンプルな方法で次々に適用できるようになります。

文中でメソッドチェインを利用できるのは、その前のメソッドが[`ActiveRecord::Relation`][]オブジェクトを1つ返す場合です（`all`、`where`、`joins`など）。
単一のオブジェクトを返すメソッド（[単一のオブジェクトを取り出す](#単一のオブジェクトを取り出す)を参照）は文の末尾に置かなければなりません。

Active Recordのメソッドが呼び出されても、クエリが即座に生成されてデータベースに送信されるわけではありません。
クエリが送信されるのは、データが実際に必要になったときだけです。そのため、以下の個別の例は1個のクエリを生成します。

NOTE: Railsコンソールでは、`inspect`を呼び出す形で結果を表示するため、クエリがその場で実行されるように見える場合があります。`inspect`は、リレーションオブジェクトを探索するだけでもクエリの実行をトリガーするためです。たとえば、コンソールで`Customer.where(active: true)`と入力すると、デフォルトではリレーションが遅延読み込みされているにもかかわらず、クエリが即座に実行されて結果が表示されます。

#### 複数のテーブルからのデータをフィルタして取得する

```ruby
Customer
  .select("customers.id, customers.last_name, reviews.body")
  .joins(:reviews)
  .where("reviews.created_at > ?", 1.week.ago)
```

上のコードから以下のようなSQLが生成されます。

```sql
SELECT customers.id, customers.last_name, reviews.body
  FROM customers
  INNER JOIN reviews
  ON reviews.customer_id = customers.id
  WHERE (reviews.created_at > "2019-01-08")
```

#### 複数のテーブルから特定のデータを取得する

```ruby
Book
  .select("books.id, books.title, authors.first_name")
  .joins(:author)
  .find_by(title: "Abstraction and Specification in Program Development")
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

NOTE: 1つのクエリが複数のレコードとマッチする場合、`find_by`は「最初」の結果だけを返し、他は返しません（上の`LIMIT 1`文を参照）。

### レコードや値を検索する

以下のメソッドを用いて、データベース内のレコードや値を検索できます。

#### `find_by_sql`

独自のSQLでレコードを検索したい場合は、[`find_by_sql`][]メソッドが使えます。この`find_by_sql`メソッドは、オブジェクトの配列を1つ返します。クエリがレコードを1つしか返さなかった場合にも配列が返されますのでご注意ください。たとえば、以下のクエリを実行したとします。

```irb
store(dev)> Customer.find_by_sql("SELECT * FROM customers INNER JOIN orders ON customers.id = orders.customer_id ORDER BY customers.created_at desc")
=> [#<Customer id: 1, first_name: "Lucas" ...>,
    #<Customer id: 2, first_name: "Jan" ...>, ...]
```

`find_by_sql`は、カスタマイズしたデータベース呼び出しをシンプルな方法で提供し、インスタンス化されたレコードを返します。

[`find_by_sql`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Querying.html#method-i-find_by_sql

#### `select_all`

`find_by_sql`は[`lease_connection.select_all`][]と深い関係があります。この`select_all`は`find_by_sql`と同様、カスタムSQLを用いてデータベースから結果を取り出しますが、取り出した結果をインスタンス化しない点が異なります。このメソッドは`ActiveRecord::Result`クラスのインスタンスを1つ返します。このオブジェクトで`to_a`を呼ぶと、各レコードに対応するハッシュを含む配列を1つ返します。

```irb
store(dev)> Customer.lease_connection.select_all("SELECT first_name, created_at FROM customers WHERE id = \"1\"").to_a
=> [{"first_name"=>"Rafael", "created_at"=>"2012-11-10 23:23:45.281189"},
    {"first_name"=>"Eileen", "created_at"=>"2013-12-09 11:22:35.221282"}]
```

[`lease_connection.select_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-select_all

#### `pluck`

[`pluck`][]は、指定したカラム名の値を現在のリレーションから配列として取得するときに利用できます。
引数としてカラム名のリストを渡すと、指定したカラムの値の配列を、対応するデータ型で返します。

```irb
store(dev)> Book.where(out_of_print: true).pluck(:id)
SELECT id FROM books WHERE out_of_print = true
=> [1, 2, 3]

store(dev)> Order.distinct.pluck(:status)
SELECT DISTINCT status FROM orders
=> ["shipped", "being_packed", "cancelled"]

store(dev)> Customer.pluck(:id, :first_name)
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

`select`と異なり、`pluck`はデータベースから受け取った結果を直接Rubyの配列に変換します。`ActiveRecord`オブジェクトはビルドしません。
従って、このメソッドは大量の結果を返すクエリや利用頻度の高いクエリで使うとパフォーマンスが向上します。ただし、モデルメソッドのオーバーライドは`pluck`では無効になります。以下に例を示します。

```ruby
class Customer < ApplicationRecord
  def first_name
    "私は#{super}"
  end
end
```

```irb
store(dev)> Customer.select(:first_name).map(&:first_name)
=> ["私はDavid", "私はJeremy", "私はJose"]

store(dev)> Customer.pluck(:first_name)
=> ["David", "Jeremy", "Jose"]
```

単一テーブルのフィールド読み出しに加えて、複数のテーブルでも同じことができます。

```irb
store(dev)> Order.joins(:customer, :books).pluck("orders.created_at, customers.email, books.title")
```

さらに`pluck`は、`select`などの`Relation`スコープと異なり、クエリを直接トリガーするので、その後ろに他のスコープをチェインできません。
ただし、構成済みのスコープを`pluck`の前に置くことは可能です。

```irb
store(dev)> Customer.pluck(:first_name).limit(1)
NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

store(dev)> Customer.limit(1).pluck(:first_name)
=> ["David"]
```

NOTE: リレーションオブジェクトで`includes`の値が含まれていると、eager-loadingが不必要なクエリでも`pluck`がeager-loadingを引き起こすことに注意が必要です。以下に例を示します。

```irb
store(dev)> assoc = Customer.includes(:reviews)
store(dev)> assoc.pluck(:id)
SELECT "customers"."id" FROM "customers" LEFT OUTER JOIN "reviews" ON "reviews"."id" = "customers"."review_id"
```

これを回避する方法の1つは、以下のようにincludesを`unscope`することです。

```irb
store(dev)> assoc.unscope(:includes).pluck(:id)
```

[`pluck`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-pluck

#### `pick`

[`pick`][]は、指定したカラム名の値を現在のリレーションから取得するときに利用できます。引数としてカラム名のリストを渡すと、指定したカラムの値の最初の行を、対応するデータ型で返します。
`pick`は、`relation.limit(1).pluck(*column_names).first`のショートハンドです。主に、既に1行に制限されたリレーションがある場合に有用です。

`pick`を使うと、以下のようなコードをシンプルなものに置き換えられます。

```ruby
Customer.where(id: 1).pluck(:id).first
```

上のコードは以下のように置き換えられます。

```ruby
Customer.where(id: 1).pick(:id)
# => 1
```

[`pick`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-pick

#### `ids`

[`ids`][]は、テーブルの主キーを使ってリレーションの全IDを取り出すのに使えます。

```irb
store(dev)> Customer.ids
SELECT id FROM customers
```

別の`primary_key`を使っている場合は、その主キーが代わりに使われます。

```ruby
class Customer < ApplicationRecord
  self.primary_key = "customer_id"
end
```

```irb
store(dev)> Customer.ids
SELECT customer_id FROM customers
```

[`ids`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-ids

新しいオブジェクトを検索またはビルドする
---------------------------------

レコードを検索し、レコードがなければ作成するという連続処理はよく行われます。
`find_or_create_by`および`find_or_create_by!`メソッドを使えば、これらの処理を一度に行なえます。

### `find_or_create_by`

[`find_or_create_by`][]メソッドは、指定された属性を持つレコードが存在するかどうかをチェックします。レコードがない場合は`create`が呼び出されます。

"andy@example.com"というメールアドレスを持つ顧客（customer）を検索し、そのメールアドレスを持つ顧客が存在しない場合は、新たに作成したいとします。これは以下で実行できます。

```irb
store(dev)> Customer.find_or_create_by(email: "andy@example.com")
=> #<Customer id: 5, email: "andy@example.com", last_name: nil, title: nil, visits: 0, orders_count: nil, lock_version: 0, created_at: "2019-01-17 07:06:45", updated_at: "2019-01-17 07:06:45">
```

このメソッドによって生成されるSQLは以下のようになります。

```sql
SELECT *
  FROM customers
  WHERE (customers.email = "andy@example.com")
  LIMIT 1

BEGIN
INSERT INTO customers (created_at, email, locked, orders_count, updated_at) VALUES ("2011-08-30 05:22:57", "andy@example.com", 1, NULL, "2011-08-30 05:22:57")
COMMIT
```

`find_or_create_by`は、既にあるレコードか新しいレコードのいずれかを返します。
上の例の場合、指定のメールアドレスを持つ顧客が存在しなかったので、レコードを作成して返しました。

`create`などと同様、バリデーションがパスするかどうかによって、新しいレコードがデータベースに保存されない可能性があります。

今度は、新しいレコードを作成するときに`locked`属性を`false`に設定したいが、それをクエリに含めたくないとします。そこで、"andy@example.com"というメールアドレスを持つ顧客を検索するか、該当する顧客が存在しない場合は、そのメールアドレスを持つ顧客をロックなしで作成することにします。

これは2とおりの方法で実装できます。1つ目は`create_with`を使う方法です。

```ruby
Customer.create_with(locked: false).find_or_create_by(email: "andy@example.com")
```

2つ目はブロックを使う方法です。

```ruby
Customer.find_or_create_by(email: "andy@example.com") do |c|
  c.locked = false
end
```

このブロックは、顧客が作成されるときにだけ実行されます。このコードを再度実行すると、このブロックは実行されません。

NOTE: `find_or_create_by`メソッドはアトミックでないため、競合状態が発生する可能性があります。コンカレントな処理の場合、2つのプロセスが同時にレコードが存在するかどうかを確認し、レコードが存在しないと判断して両方がレコードを作成しようとすると、重複レコードが発生する可能性があります。このような競合状態を回避するには、クエリ対象のデータベースカラムにUNIQUE制約を設定するか、UNIQUE制約違反をアトミックに処理できる後述の[`create_or_find_by`](#create-or-find-by)メソッドの利用を検討してください。

[`find_or_create_by`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by

### `find_or_create_by!`

[`find_or_create_by!`][]を使うと、新しいレコードが無効な場合に例外を発生するようになります。バリデーション（検証）については本ガイドでは解説していませんが、たとえば以下のバリデーションを一時的に`Customer`モデルに追加したとします。

```ruby
validates :orders_count, presence: true
```

`orders_count`を指定せずに新しい`Customer`モデルを作成しようとすると、レコードは無効になって以下のように例外が発生します。

```irb
store(dev)> Customer.find_or_create_by!(first_name: "Andy")
ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

[`find_or_create_by!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by-21

### `find_or_initialize_by`

[`find_or_initialize_by`][]メソッドは`find_or_create_by`と同様に動作しますが、`create`ではなく`new`を呼ぶ点が異なります。
つまり、モデルの新しいインスタンスがメモリ上に作成されますが、データベースへの保存は行いません。

今度は'Nina'という名前の顧客を検索したいとします。

```irb
store(dev)> nina = Customer.find_or_initialize_by(first_name: "Nina")
=> #<Customer id: nil, first_name: "Nina", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

store(dev)> nina.persisted?
=> false

store(dev)> nina.new_record?
=> true
```

オブジェクトはまだデータベースに保存されていないため、生成されるSQLは以下のようなものになります。

```sql
SELECT * FROM customers WHERE (customers.first_name = "Nina") LIMIT 1
```

このオブジェクトをデータベースに保存したい場合は、単に`save`を呼び出します。

```irb
store(dev)> nina.save
=> true
```

[`find_or_initialize_by`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_initialize_by

### `create_or_find_by`

[`create_or_find_by`][]メソッドは、指定の属性を持つレコードの作成を試みます。
指定の属性を持つレコードが既に存在する場合（UNIQUE制約違反を意味する）、既存のレコードを検索して返します。このメソッドの振る舞いはアトミックであり、`find_or_create_by`で起きる可能性のある競合状態を回避します。

```irb
store(dev)> Customer.create_or_find_by(first_name: "Andy")
=> #<Customer id: 5, first_name: "Andy", last_name: nil, title: nil, visits: 0, orders_count: nil, lock_version: 0, created_at: "2019-01-17 07:06:45", updated_at: "2019-01-17 07:06:45">
```

このメソッドを最初に呼び出すと、以下のようなSQLが生成されます。

```sql
BEGIN
INSERT INTO customers (created_at, first_name, locked, orders_count, updated_at) VALUES ("2011-08-30 05:22:57", "Andy", 1, NULL, "2011-08-30 05:22:57")
COMMIT
```

レコードが存在することが（UNIQUE制約によって）検出されると、作成は失敗し、代わりに既存のレコードを検索します。

```sql
BEGIN
INSERT INTO customers (created_at, first_name, locked, orders_count, updated_at) VALUES ("2011-08-30 05:22:57", "Andy", 1, NULL, "2011-08-30 05:22:57")
ROLLBACK

SELECT *
  FROM customers
  WHERE (customers.first_name = "Andy")
  LIMIT 1
```

`create_or_find_by`と`find_or_create_by`の重要な違いは、操作の順序と、アトミックであるかどうかです。

- `find_or_create_by`: 最初に検索を試み、見つからない場合は作成する。この動作は**アトミックではない**ため、重複レコードが作成されうる競合状態が発生する可能性がある。

- `create_or_find_by`: 最初に作成を試み、UNIQUE制約違反によって作成が失敗した場合は検索を実行する。この動作は**アトミック**であり、競合状態を防止する。

IMPORTANT: `create_or_find_by`が正しく動作するには、クエリ対象の属性にUNIQUE制約が設定されていることが不可欠です。この制約がないと、メソッドは重複キー違反を引き起こす可能性があります。このメソッドは、「レコードの作成がほとんどのケースで成功することを期待する場合」「関連する属性に既にUNIQUE制約が設定されている場合」「重複レコードの原因となる可能性のある競合状態を回避したい場合」に最適です。

[`create_or_find_by`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-create_or_find_by

### `create_or_find_by!`

[`create_or_find_by!`][]は、UNIQUE制約違反以外の理由でレコード作成が失敗した場合に例外を発生したい場合に利用できます。このメソッドは`find_or_create_by!`と似ていますが、最初に作成を試みる点とアトミックである点が異なります。

```irb
store(dev)> Customer.create_or_find_by!(first_name: "Andy", orders_count: 5)
=> #<Customer id: 5, first_name: "Andy", orders_count: 5, ...>
```

レコード作成中に（UNIQUE制約違反以外の理由で）バリデーションが失敗すると、以下のように例外を発生します。

```irb
store(dev)> Customer.create_or_find_by!(first_name: "Andy", orders_count: nil)
ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

ただし、UNIQUE制約違反で失敗した場合は例外を発生せず、通常通り既存のレコードを検索して返します（`create_or_find_by`と同様）。

[`create_or_find_by!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-create_or_find_by-21

レコードの存在チェック
--------------------

レコードが1件以上存在するかどうかをチェックするには、以下のメソッドを利用できます。

### `exists?`

レコードが存在するかどうかを、レコードをインスタンス化せずにチェックしたい場合は、[`exists?`][]メソッドが使えます。
このメソッドは、`find`と同じクエリをデータベースに送信しますが、レコードやレコードのコレクションではなく`true`または`false`を返します。

```irb
store(dev)> Customer.exists?(1)
SELECT 1 AS one FROM customers WHERE customers.id = 1 LIMIT 1
=> true
```

`exists?`メソッドの引数には複数の値を渡せます。ただし、それらの値のうち1つでも存在していれば、他の値が存在していなくても`true`を返します。

```irb
store(dev)> Customer.exists?(id: [1, 2, 3])
=> true
store(dev)> Customer.exists?(first_name: ["Jane", "Sergei"])
=> true
```

引数なしの`exists?`メソッドは、モデルやリレーションにも利用できます。

```irb
store(dev)> Customer.where(first_name: "Ryan").exists?
=> true
```

上の例では、`first_name`が'Ryan'である顧客が1人でもいれば`true`を返し、それ以外の場合は`false`を返します。

```irb
store(dev)> Customer.exists?
=> true
```

上の例では、`customers`テーブルが空なら`false`を返し、それ以外の場合は`true`を返します。

### `any?`

モデルやリレーションの存在チェックには`any?`メソッドも使えます。

レコードが既にメモリ上に読み込み済みの場合、データベースにクエリを再送信せずにメモリ上のレコードをチェックします。

```irb
store(dev)> orders = Order.limit(10).load
SELECT orders.* FROM orders LIMIT 10
store(dev)> orders.any?
=> true
```

```irb
store(dev)> Order.any?
SELECT 1 FROM orders LIMIT 1
=> true

store(dev)> Order.shipped.any?
SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 1
=> true

store(dev)> Book.where(out_of_print: true).any?
=> true

store(dev)> Customer.first.orders.any?
=> true
```

### `many?`

モデルやリレーションにレコードが2個以上存在するかどうかのチェックには、`many?`メソッドが使えます。レコードがメモリ上に読み込まれていない場合は、SQLの`count`を使います。

```irb
store(dev)> Order.many?
SELECT COUNT(*) FROM (SELECT 1 FROM orders LIMIT 2)
=> true

store(dev)> Order.shipped.many?
SELECT COUNT(*) FROM (SELECT 1 FROM orders WHERE orders.status = 0 LIMIT 2)
=> true

store(dev)> Book.where(out_of_print: true).many?
=> true

store(dev)> Customer.first.orders.many?
=> true
```

[`exists?`]:
    https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F

### 複数レコードをバッチ処理で取り出す

大量のレコードに対して処理を反復したいことがあります（多くのユーザーにニュースレターを送信したい、データをエクスポートしたいなど）。

そうした処理を、つい以下のように`all.each`で書きたくなるかもしれません。

```ruby
# このコードはテーブルが大きい場合にメモリを大量に消費する可能性あり
Customer.all.each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

しかし上のような処理は、テーブルのサイズが大きくなるに従ってだんだん使い物にならなくなります。`Customer.all.each`は、Active Recordに対して **テーブル全体**を一度に取り出し、しかも1行ごとにオブジェクトを生成し、その巨大なモデルオブジェクトの配列をメモリに配置するからです。このようなコードを大量のレコードに対してうかつに実行すると、コレクション全体のサイズがメモリ容量を上回ってしまう可能性があります。

Railsでは、メモリを圧迫しないサイズにバッチを分割して処理するために、2種類のメソッドを提供しています。

- 1: `find_each`: このメソッドは、レコードのバッチを1つ取り出してから、次にブロック内で**各**レコードを1つのモデルとして個別にyieldします。

- 2: `find_in_batches`: このメソッドは、レコードのバッチを1つ取り出してから、次に**バッチ全体**をモデルの配列としてブロックにyieldします。

NOTE: `find_each`メソッドと`find_in_batches`メソッドは、一度にメモリに読み込めないような大量のレコードに対するバッチ処理のためのものです。千件程度のレコードに対して単純なループ処理を行うのであれば、通常の検索メソッドで十分です。

#### `find_each`

[`find_each`][]メソッドは、複数のレコードを一括で取り出し、続いて **各**レコードをブロックにyieldします。以下の例では、`find_each`は顧客を1,000件ずつのバッチで取り出し、各レコードをブロックにyieldします。

```ruby
Customer.find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

NOTE: デフォルトのバッチサイズは1,000件ですが、この値はカスタマイズ可能です。詳しくは[`find_each`のオプション](#find-eachのオプション)を参照してください。

この処理は、必要に応じて次のレコードのバッチをフェッチし、すべてのレコードが処理されるまで繰り返されます。

`find_each`メソッドは上述のようにモデルのクラスに対して機能しますが、順序付けされていないリレーションに対しても機能します。これは、メソッドが反復処理を行うために内部的に順序を強制する必要があるためです。

```ruby
Customer.where(weekly_subscriber: true).find_each do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

リレーションが順序付けされている場合、このメソッドの振る舞いは[`config.active_record.error_on_ignored_order`][]フラグによって決まります。
このフラグが`true`に設定されている場合、`ArgumentError`が発生します。それ以外の場合は、順序は無視され、警告が表示されます。
これはデフォルトの動作ですが、後述の`:error_on_ignore`オプションで上書きできます。

[`config.active_record.error_on_ignored_order`]:
    configuring.html#config-active-record-error-on-ignored-order
[`find_each`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_each

##### `find_each`のオプション

**`:batch_size`**

`:batch_size`オプションは、（ブロックに個別に渡される前に）1回のバッチで取り出すレコード数を指定します。たとえば、1回に5,000件ずつ処理したい場合は以下のように指定します。

```ruby
Customer.find_each(batch_size: 5000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

**`:start`**

デフォルトでは、レコードは主キーの昇順で取り出されます。並び順冒頭のIDが不要な場合は、`:start`オプションを使ってシーケンスの開始IDを指定できます。これは、たとえば中断したバッチ処理を再開する場合などに便利です（最後に実行された処理のIDがチェックポイントとして保存済みであることが前提です）。

たとえば主キーが2,000番以降のユーザーに対してニュースレターを配信する場合は、以下のようになります。

```ruby
Customer.find_each(start: 2000) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

**`:finish`**

`:start`オプションと同様に、シーケンスの末尾のIDを指定したい場合は、`:finish`オプションで末尾のIDを設定できます。`:start`と`:finish`でレコードのサブセットを指定し、その中でバッチプロセスを走らせたい場合に便利です。

たとえば主キーが2,000番〜9,999番のユーザーに対してニュースレターを配信したい場合は、以下のようになります。

```ruby
Customer.find_each(start: 2000, finish: 9999) do |customer|
  NewsMailer.weekly(customer).deliver_now
end
```

他にも、同じ処理キューを複数のワーカーで手分けする場合が考えられます。たとえばワーカーごとに10,000レコードずつ処理したい場合も、`:start`と`:finish`オプションにそれぞれ適切な値を設定することで実現できます。

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

[`find_in_batches`][]メソッドは、レコードをバッチで取り出すという点で`find_each`と似ています。違うのは、`find_in_batches`は**バッチ**を個別にではなくモデルの配列としてブロックにyieldするという点です。
以下の例では、与えられたブロックに対して一度に最大1,000人までの顧客（customer）の配列をyieldしています。最後のブロックには残りの顧客が含まれます。

```ruby
# 1回あたり1,000人の顧客の配列をadd_customersに渡す
Customer.find_in_batches do |customers|
  export.add_customers(customers)
end
```

`find_in_batches`メソッドは上述のようにモデルのクラスに対して機能するだけでなく、順序付けされていないリレーションに対しても機能します。その理由は、このメソッドが反復処理のために内部で強制的に順序付けする必要があるためです。

```ruby
# 最近アクティブな顧客を1,000人ずつ配列にしてadd_customersに渡す
Customer.recently_active.find_in_batches do |customers|
  export.add_customers(customers)
end
```

[`find_in_batches`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_in_batches

##### `find_in_batches`のオプション

`find_in_batches`メソッドでは、`find_each`メソッドと同様のオプションを使えます。

**`:batch_size`**

`find_each`と同様に、`batch_size`はグループごとのレコード数を指定します。たとえば、レコードを2,500件ずつ取り出すには以下のように指定できます。

```ruby
Customer.find_in_batches(batch_size: 2500) do |customers|
  export.add_customers(customers)
end
```

**`:start`**

`start`オプションを使うと、レコードがSELECTされるときの最初のIDを指定できます。上述のように、デフォルトではレコードを主キーの昇順でフェッチします。たとえば、ID: 5000から始まる顧客レコードを2,500件ずつ取り出すには、以下のようなコードが使えます。

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

レコードをフィルタで絞り込む
----------

[`where`][]メソッドは、返されるレコードを制限するための条件を指定します。SQL文で言う`WHERE`の部分に相当します。
条件は、「文字列」「配列」「ハッシュ」のいずれかの方法で与えられます。

### 条件を文字列だけで指定する

検索メソッドに条件を追加したい場合、以下のように`where`で直接指定できます。

```ruby
Book.where("title = \"Introduction to Algorithms\"")
```

この場合、`title`フィールドの値が'Introduction to Algorithms'であるすべての本が検索されます。

WARNING: 条件を文字列だけで構成すると、SQLインジェクションの脆弱性が発生する可能性があります。たとえば、`Book.where("title LIKE '%#{params[:title]}%'")`という書き方は危険です。次で説明するように、配列を使うのが望ましい方法です。詳しくは、セキュリティガイドの[SQLインジェクション](security.html#sqlインジェクション)を参照してください。

### 条件を配列で指定する

条件が引数に依存している場合、以下のように配列で条件を指定できます。

```ruby
Book.where(["title = ?", params[:title]])
```

渡せるのは実際の配列だけではありません。以下のように引数のリストも渡せます。

```ruby
Book.where("title = ?", params[:title])
```

Active Recordは最初の引数を、文字列で表された条件として受け取ります。その後に続く引数は、文字列内にある疑問符`?`と置き換えられます。
Active Recordは、SQLインジェクションを防止するために、渡された値をエスケープし、必要に応じて適切なデータベース型に変換します。

以下のような安全でない文字列条件が使われると、意図しない危険なSQLが生成される可能性があります。

```ruby
unsafe_title = "a' OR '1'='1"
Book.where("title = '#{unsafe_title}'")
```

以下のようにプレースホルダ`?`を介することで、値がエスケープされるようになります。

```ruby
Book.where("title = ?", unsafe_title)
```

複数の条件を指定したい場合は次のようにします。

```ruby
Book.where("title = ? AND out_of_print = ?", params[:title], false)
```

上の例では、1つ目の疑問符は`params[:title]`のエスケープ済みの値で置き換えられ、2つ目の疑問符は`false`をSQL形式に変換したもので置き換えられます（変換方法はアダプタによって異なります）。

#### 条件でプレースホルダを使う

疑問符`(?)`をパラメータで置き換えるスタイルと同様に、名前付きプレースホルダを使って値のハッシュを渡す方法も利用できます。

```ruby
Book.where("title = :title AND out_of_print = :out_of_print",
  title: params[:title], out_of_print: false)
```

このように書くことで、多数の変数を使う条件が読みやすくなります。

#### 条件で`LIKE`を使う

引数はSQLインジェクションを防ぐために自動的にエスケープされますが、SQL `LIKE`ワイルドカード（つまり、`%`と`_`）はエスケープ**されません**。引数にサニタイズされていない値が使われている場合、予期しない動作となることがあります。
以下の例をご覧ください。

```ruby
Book.where("title LIKE ?", params[:title] + "%")
```

上の例は、ユーザーが指定した文字列で始まるタイトルに一致することを意図しています。しかし、`params[:title]`に含まれる`%`または`_`はワイルドカードとして扱われるため、予想外の結果をもたらします。状況によっては、データベースがインデックスを利用できなくなるため、クエリが大幅に遅くなる可能性があります。

これらの問題を回避するには、引数の該当部分にあるワイルドカード文字を[`sanitize_sql_like`][]でエスケープします。

```ruby
Book.where("title LIKE ?",
  Book.sanitize_sql_like(params[:title]) + "%")
```

[`sanitize_sql_like`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Sanitization/ClassMethods.html#method-i-sanitize_sql_like

### 条件でハッシュを使う

Active Recordは条件をハッシュで渡すこともできます。この書式を使うことで条件構文が読みやすくなります。条件をハッシュで渡す場合、ハッシュのキーには条件付けしたいフィールドを、ハッシュの値にはそのフィールドをどのように条件づけするかを、それぞれ指定します。

NOTE: ハッシュによる条件を利用できるのは、等値、範囲、サブセットのチェックだけです。

#### 等値条件

```ruby
Book.where(out_of_print: true)
```

これは以下のようなSQLを生成します。

```sql
SELECT * FROM books WHERE (books.out_of_print = true)
```

フィールド名は文字列でも指定できます。

```ruby
Book.where("out_of_print" => true)
```

belongs_toリレーションシップの場合、Active Recordオブジェクトが値として使われていれば、モデルを指定する時に関連付けキーを利用できます。
この方法は[ポリモーフィックリレーションシップ](association_basics.html#ポリモーフィック関連付け)でも同様に利用できます。

```ruby
author = Author.first
Book.where(author: author)
Author.joins(:books).where(books: { author: author })
```

ハッシュ条件は、以下のように「キーがカラムの配列である」かつ「値がタプルの配列である」タプル的な構文でも指定できます。

```ruby
Book.where([:author_id, :id] => [[15, 1], [15, 2]])
```

この構文は、[複合主キー](active_record_composite_primary_keys.html)を利用しているモデルで便利な場合があります。詳しくは[複合主キーのガイド](active_record_composite_primary_keys.html)を参照してください。

#### 範囲条件

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

上の例では、昨日作成されたすべての本を検索します。内部ではSQLの`BETWEEN`文が使われます。

```sql
SELECT * FROM books WHERE (books.created_at BETWEEN "2008-12-21 00:00:00" AND "2008-12-22 00:00:00")
```

これは、[条件を配列で指定する](#条件を配列で指定する)をさらに短い構文で表した例です。

Rubyの[終端/始端を持たない範囲オブジェクト](https://docs.ruby-lang.org/ja/latest/class/Range.html)（beginless/endless range）がサポートされており、以下のように「〜より大きい」「〜より小さい」条件の構築で利用できます。

```ruby
Book.where(created_at: (Time.now.midnight - 1.day)..)
```

上は、以下のようなSQLを生成します。

```sql
SELECT * FROM books WHERE books.created_at >= "2008-12-21 00:00:00"
```

#### サブセット条件

SQLの`IN`式でレコードを検索したい場合、条件ハッシュにそのための配列を渡せます。

```ruby
Customer.where(orders_count: [1, 3, 5])
```

上のコードを実行すると、以下のようなSQLが生成されます。

```sql
SELECT * FROM customers WHERE (customers.orders_count IN (1,3,5))
```

### NOT条件

SQLの`NOT`クエリは、[`where.not`][]で表せます。

```ruby
Customer.where.not(orders_count: [1, 3, 5])
```

言い換えれば、このクエリは`where`に引数を付けずに呼び出し、直後に`not`をチェインして、そこに`where`条件を渡すことで生成されています。これは以下のようなSQLを出力します。

```sql
SELECT * FROM customers WHERE (customers.orders_count NOT IN (1,3,5))
```

あるクエリのnull許容（nullable）カラムに、非nil値を指定したハッシュ条件がある場合、null許容カラムに`nil`値を持つレコードは返されません。

```ruby
Customer.create!(nullable_country: nil)
Customer.where.not(nullable_country: "UK")
# => []

Customer.create!(nullable_country: "UK")
Customer.where.not(nullable_country: nil)
# => [#<Customer id: 2, nullable_country: "UK">]
```

[`where.not`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods/WhereChain.html#method-i-not

### OR条件

2つのリレーションをまたいで`OR`条件を使いたい場合は、1つ目のリレーションで[`or`][]メソッドを呼び出し、そのメソッドの引数に2つ目のリレーションを渡すことで実現できます。

```ruby
Customer.where(last_name: "Smith").or(Customer.where(orders_count: [1, 3, 5]))
```

```sql
SELECT * FROM customers WHERE (customers.last_name = "Smith" OR customers.orders_count IN (1,3,5))
```

[`or`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-or

### AND条件

`AND`条件は、`where`条件をチェインすることで構成できます。

```ruby
Customer.where(last_name: "Smith").where(orders_count: [1, 3, 5])
```

```sql
SELECT * FROM customers WHERE customers.last_name = "Smith" AND customers.orders_count IN (1,3,5)
```

リレーション間の論理的な交差（共通集合）を表す`AND`条件は、1個目のリレーションで[`and`][]を呼び出し、その引数で2個目のリレーションを指定することで構成できます。

```ruby
Customer.where(id: [1, 2]).and(Customer.where(id: [2, 3]))
```

```sql
SELECT * FROM customers WHERE (customers.id IN (1, 2) AND customers.id IN (2, 3))
```

[`and`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-and

レコードを並べ替える
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

`order`メソッドを複数回呼び出すと、最初の並び順の後ろに以後の並び順が追加されていきます。

```irb
store(dev)> Book.order("title ASC").order("created_at DESC")
SELECT * FROM books ORDER BY title ASC, created_at DESC
```

以下のようにjoinしたテーブルで順序を指定することも可能です。

```ruby
Book.includes(:author).order(books: { print_year: :desc }, authors: { name: :asc })
# または
Book.includes(:author).order("books.print_year desc", "authors.name asc")
```

WARNING: 多くのデータベースシステムでは、`select`、`pluck`、`ids`メソッドを使った結果を`distinct`で絞り込んだとき、`order`句で指定したフィールドがselectのリストに含まれていないと`ActiveRecord::StatementInvalid`例外が発生します。結果から特定のフィールドを取り出す方法については、次のセクションを参照してください。

フィールドを選択する
-------------------------

`ActiveRecord::Relation`は、デフォルトでは結果セットからすべてのフィールドを選択します。内部的にはSQLの`select *`が実行されています。

結果セットからフィールドのサブセットだけを取り出したい場合は、[`select`][]メソッドでサブセットを指定できます。

たとえば、`isbn`カラムと`out_of_print`カラムだけを取り出したい場合は以下のようにします。

```ruby
Book.select(:isbn, :out_of_print)
# または
Book.select("isbn, out_of_print")
```

上の検索で実際に使われるSQL文は以下のようになります。

```sql
SELECT isbn, out_of_print FROM books
```

`select`を実行して初期化されたモデルオブジェクトには、選択したフィールドしか含まれていないことに注意が必要です。
モデルオブジェクトの初期化時に指定しなかったフィールドにアクセスしようとすると、以下のメッセージが表示されます。

```text
ActiveModel::MissingAttributeError: missing attribute '<属性名>' for Book
```

`<属性名>`は、アクセスしようとした属性です。`id`メソッドは、この`ActiveModel::MissingAttributeError`を発生しません。
このため、関連付けを扱う場合にはご注意ください。関連付けが正常に動作するには`id`メソッドが必要です。

レコード件数を制限する
----------------

データベースから取り出すレコード件数を制限するには、リレーションで[`limit`][]メソッドや[`offset`][]メソッドを用いて`LIMIT`を指定できます。

`limit`メソッドは、取り出すレコード数の上限を指定します。
`offset`は、レコードを返す前にスキップするレコード数を指定します。

```ruby
Customer.limit(5)
```

上を実行すると顧客が最大で5人返されます。オフセットは指定されていないので、最初の5つがテーブルから取り出されます。この時実行されるSQLは以下のような感じになります。

```sql
SELECT * FROM customers LIMIT 5
```

`offset`を追加すると、最初の30件をスキップして31件目から最大5件のレコードを返します。

```ruby
Customer.limit(5).offset(30)
```

このときのSQLは以下のようになります。

```sql
SELECT * FROM customers LIMIT 5 OFFSET 30
```

特定のフィールドについて、重複のない一意の値ごとに1レコードだけ取り出したい場合は、[`distinct`][]が使えます。

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

レコードをグループ化する
-----

レコードをグループ化したい場合は、[`group`][]メソッドを検索メソッドに追加することで、生成されるSQLに`GROUP BY`句を適用できます。

たとえば、注文（order）のコレクションを検索してステータスでグループ化したい場合は、以下のようにします。

```ruby
Order.group("status")
```

上のコードは、データベース内で一意のステータス値ごとに`Order`オブジェクトを1つ返します。

上で実行されるSQLは以下のようなものになります。

```sql
SELECT *
  FROM orders
  GROUP BY status
```

### グループ化した項目の合計

グループごとの項目数を数えるには、`group`に続けて[`count`][]を呼び出します。

```irb
store(dev)> Order.group(:status).count
=> {"being_packed"=>7, "shipped"=>12}
```

上で実行されるSQLは以下のようになります。

```sql
SELECT COUNT (*) AS count_all, status AS status
  FROM orders
  GROUP BY status
```

[`count`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-count

### HAVING条件

グループ化したクエリの結果をフィルタで絞り込むには、[`having`][]メソッドが使えます。

`where`はグループ化の前に行をフィルタしますが、`having`は集計後にグループをフィルタする点が異なります。

以下に例を示します。

```ruby
Order.select("customer_id, sum(total) as total_price").
  group("customer_id").having("sum(total) > ?", 200)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT customer_id, sum(total) as total_price
  FROM orders
  GROUP BY customer_id
  HAVING sum(total) > 200
```

これは、注文合計金額が200ドルを超える顧客ごとに、顧客IDと合計金額をグループ化して返します。

orderオブジェクトごとの`total_price`にアクセスするには以下のように書きます。

```ruby
big_orders = Order.select("customer_id, sum(total) as total_price")
                  .group("customer_id")
                  .having("sum(total) > ?", 200)

big_orders[0].total_price
# 最初のOrderオブジェクトの合計額が返される
```

SQL句を上書きする
---------------------

既存のリレーションを基に構築するときに、クエリの一部を「条件の削除」「条件の置換」「レコードのselect方法や順序の再定義」によって変更したい場合があります。
Active Recordには、リレーション全体を最初から再構築しなくとも、個々のSQL句をオーバーライドできる方法がいくつも用意されています。

### `unscope`

[`unscope`][]で特定の条件を取り除けます。以下に例を示します。

```ruby
Book.where("id > 100").limit(20).order("id desc").unscope(:order)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT *
  FROM books
  WHERE id > 100
  LIMIT 20

-- `unscope`する前のオリジナルのクエリ
SELECT *
  FROM books
  WHERE id > 100
  ORDER BY id desc
  LIMIT 20
```

`unscope`で特定の`where`句を指定することも可能です。たとえば、以下は`where`句から`id`条件を取り除きます。

```ruby
Book.where(id: 10, out_of_print: false).unscope(where: :id)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT books.* FROM books WHERE out_of_print = false
```

`unscope`を使ったリレーションは、マージ先のリレーションにも影響します。以下の例では、オリジナルのリレーションから`order`が取り除かれます。

```ruby
Book.order("id desc").merge(Book.unscope(:order))
```

上で生成されるSQLは以下のようになります。

```sql
SELECT books.* FROM books
```

[`unscope`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-unscope

### `unscoped`

何らかの理由でスコープをすべて解除したい場合は[`unscoped`][]メソッドが使えます。このメソッドは、モデルで指定されている`default_scope`を適用したくないクエリがある場合に特に便利です。
ただし、`unscoped`はスコープが存在しない場合でも利用できます。

```ruby
Book.unscoped.load
```

このメソッドはスコープをすべて解除し、テーブルに対して通常の（スコープなしの）クエリを実行するようにします。

```ruby
Book.unscoped.all
```

```ruby
Book.where(out_of_print: true).unscoped.all
```

上の2つの例は、どちらも以下のSQLを生成します。

```sql
SELECT books.* FROM books
```

`unscoped`にはブロックも渡せます。

```ruby
Book.unscoped { Book.out_of_print }
```

```sql
SELECT books.* FROM books WHERE books.out_of_print = true
```

[`unscoped`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Default/ClassMethods.html#method-i-unscoped

### `only`

以下のように[`only`][]メソッドを使って条件を上書きできます。

以下の例では`:order`スコープと`:where`スコープだけが適用され、`:limit`スコープは解除されます。

```ruby
Book.where("id > 10").limit(20).order("id desc").only(:order, :where)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT *
  FROM books
  WHERE id > 10
  ORDER BY id DESC

-- `only`を使う前のオリジナルのクエリ
SELECT *
  FROM books
  WHERE id > 10
  ORDER BY id DESC
  LIMIT 20
```

[`only`]:
    https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-only

### `except`

[`except`][]メソッドを使うと、以下のように特定の条件を削除できます。

```ruby
Book.where("id > 100").limit(20).order("id desc").except(:order)
```

生成されたSQLが実行されるときに、`:order`句は無視されます。

```sql
SELECT *
  FROM books
  WHERE id > 100
  LIMIT 20

-- `except`を使う前のオリジナルのクエリ
SELECT *
  FROM books
  WHERE id > 100
  ORDER BY id desc
  LIMIT 20
```

以下のように複数の条件を削除することも可能です。

```ruby
Book.where("id > 100").limit(20).order("id desc").except(:order, :limit)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT books.* FROM books WHERE id > 100
```

[`except`]:
    https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-except

### `reselect`

[`reselect`][]メソッドを使うと、以下のように既存の`select`文を上書きできます。

```ruby
Book.select(:title, :isbn).reselect(:created_at)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT books.created_at FROM books
```

`reselect`句を使わない場合と比較してみましょう。

```ruby
Book.select(:title, :isbn).select(:created_at)
```

上で生成されるSQLは以下のようになります。

```sql
SELECT books.title, books.isbn, books.created_at FROM books
```

### `reorder`

[`reorder`][]メソッドは、それまでに定義された`order`句をすべて上書きします。たとえばクラス定義に以下があるとします。

```ruby
class Book < ApplicationRecord
  default_scope { order(year_published: :desc) }
end
```

続いて以下を実行します。

```ruby
Book.all
```

上で生成されるSQLは以下のようになります。

```sql
SELECT *
  FROM books
  ORDER BY year_published DESC
```

`reorder`を使うと、以下のように別の並び順を指定できます。

```ruby
Book.reorder("year_published ASC")
```

上で生成されるSQLは以下のようになります。

```sql
SELECT *
  FROM books
  ORDER BY year_published ASC
```

<!-- 原文エラー修正 https://github.com/rails/rails/pull/59008 を先行反映 -->

`reorder`メソッドは、デフォルトスコープの順序指定だけでなく、クエリチェインで事前に定義されたどの順序指定に対しても有効です。

```ruby
Book.where("id > 100").order("id desc").reorder("title ASC")
```

上のようにすると、デフォルトスコープの順序指定と、その前の`order("id desc")`が両方とも上書きされて、タイトルだけで並べ替えられます。

### `reverse_order`

[`reverse_order`][]メソッドは、並び順が指定されている場合に並び順を逆にします。

```ruby
Book.where("author_id > 10").order(:year_published).reverse_order
```

上で生成されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY year_published DESC
```

SQLクエリで並び順を指定する句がない状態で`reverse_order`を実行すると、主キーの逆順になります。

```ruby
Book.where("author_id > 10").reverse_order
```

上で生成されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE author_id > 10 ORDER BY books.id DESC
```

このメソッドは引数を**取りません**。

### `rewhere`

[`rewhere`][]メソッドは、以下のように既存の名前付き`where`条件を上書きします。

```ruby
Book.where(out_of_print: true).rewhere(out_of_print: false)
```

実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE out_of_print = false
```

`rewhere`ではなく、以下のように`where`にすると、置き換えではなく、2つの`where`句のAND条件になります。

```ruby
Book.where(out_of_print: true).where(out_of_print: false)
```

実行されるSQLは以下のようになります。

```sql
SELECT * FROM books WHERE out_of_print = true AND out_of_print = false
```

[`rewhere`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-rewhere

### `regroup`

[`regroup`][]メソッドは、既存の名前付き`group`条件をオーバーライドします。例:

```ruby
Book.group(:author_id).regroup(:id)
```

実行されるSQLは以下のようになります。

```sql
SELECT * FROM books GROUP BY id
```

`regroup`ではなく通常の`group`を使った場合、オーバーライドではなく`group`句同士が結合されます。

```ruby
Book.group(:author_id).group(:id)
```

実行されるSQLは以下のようになります。

```sql
SELECT * FROM books GROUP BY author_id, id
```

[`regroup`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-regroup

Nullリレーション
-------------

[`none`][]メソッドは、チェイン（chain）可能なリレーションを返します（レコードは返しません）。このメソッドから返されたリレーションにどのような条件をチェインさせても、常に空のリレーションが生成されます。
これは、結果が0件になる可能性のあるメソッドやスコープで、チェイン可能なレスポンスが必要な場合に便利です。

```ruby
Book.none # 空のリレーションを返し、クエリを生成しない
```

```ruby
class Book
  # レビューが5件以上の場合にレビューを返す
  # それ以外の本はレビューなしとみなす
  def highlighted_reviews
    if reviews.count >= 5
      reviews
    else
      Review.none # レビュー5件未満の場合
    end
  end
end

# highlighted_reviewsメソッドは常にリレーションを返すことが期待されている
Book.first.highlighted_reviews.average(:rating)
# => 本1冊あたりの平均レーティングを返す（レビュー数が5件未満であっても）
```

読み取り専用レコード
----------------

Active Recordがリレーションで提供する[`readonly`][]メソッドは、返されたどのレコードについても改変を明示的に禁止します。読み取り専用のオブジェクトに対する改変の試みはすべて失敗し、`ActiveRecord::ReadOnlyRecord`例外が発生します。

```ruby
customer = Customer.readonly.first
customer.visits += 1
customer.save # ActiveRecord::ReadOnlyRecordがraiseされる
```

上のコードでは`customer`に対して明示的に`readonly`が指定されているため、`visits`の値を更新して`customer.save`を行なうと`ActiveRecord::ReadOnlyRecord`例外が発生します。

更新のためにレコードをロックする
--------------------------

ロックは、データベースのレコードを更新する際の競合状態を避け、アトミックな（=中途半端な状態のない）更新を行なうために有用です。

NOTE: アトミックな操作とは、完全に実行されるか、まったく実行されないかのいずれかであり、部分的な更新が他のプロセスから見えることを防ぐ操作のことです。

Active Recordには2とおりのロック機構があります。

* 楽観的ロック（optimistic locking）
* 悲観的ロック（pessimistic locking）

### 楽観的ロック（optimistic locking）

楽観的ロックでは、複数のユーザーが同じレコードを編集のために開くことを許し、データの衝突は最小限であると想定します。レコードを開いてから別のプロセスが変更を加えていないかをチェックし、変更が発生した場合は、`ActiveRecord::StaleObjectError`例外がスローされ、更新は無視されます。

#### 楽観的ロックカラム

楽観的ロックを使うには、テーブルに`lock_version`という名前のinteger型カラムが必要です。Active Recordは、レコードが更新されるたびに`lock_version`カラムの値を1ずつ増やします。
更新リクエストが発生したときの`lock_version`の値がデータベース上の`lock_version`カラムの値よりも小さい場合、更新リクエストは失敗し、以下のように`ActiveRecord::StaleObjectError`エラーが発生します。

```ruby
c1 = Customer.find(1)
c2 = Customer.find(1)

c1.first_name = "Sandra"
c1.save

c1.lock_version # => 1
c2.lock_version # => 0

c2.first_name = "Michael"
c2.save # ActiveRecord::StaleObjectErrorが発生
```

開発者は、例外の発生後にこの例外をrescueして衝突を解決する責任があります。
衝突の解決方法は、ロールバック、マージ、またはビジネスロジックに応じた解決方法のいずれかをお使いください。

`ActiveRecord::Base.lock_optimistically = false`を設定するとこの動作をオフにできます。

`ActiveRecord::Base`には、`lock_version`カラム名を上書きするための`locking_column`属性が用意されています。

```ruby
class Customer < ApplicationRecord
  self.locking_column = :lock_customer_column
end
```

### 悲観的ロック（pessimistic locking）

悲観的ロックでは、データベースが提供するロック機構を利用します。リレーションの構築時に`lock`を使うと、選択した行に対する排他的ロックを取得できます。`lock`を用いているリレーションは、デッドロック条件を回避するために、通常トランザクションの内側にラップされます。

以下に例を示します。

```ruby
Book.transaction do
  book = Book.lock.first
  book.title = "Algorithms, second edition"
  book.save!
end
```

バックエンドがMySQLの場合、上のセッションによって以下のSQLが生成されます。

```sql
SQL (0.2ms)   BEGIN
Book Load (0.3ms)   SELECT * FROM books LIMIT 1 FOR UPDATE
Book Update (0.4ms)   UPDATE books SET updated_at = "2009-02-07 18:05:56", title = "Algorithms, second edition" WHERE id = 1
SQL (0.8ms)   COMMIT
```

ロックの種別を変更したい場合は、`lock`メソッドに生SQLを渡すことも可能です。たとえば、MySQLには`LOCK IN SHARE MODE`（レコードのロック中にも他のクエリからの読み出しを許可する）という式があります。
この式を指定するには、以下のように単にlockオプションの引数で渡します。

```ruby
Book.transaction do
  book = Book.lock("LOCK IN SHARE MODE").find(1)
  book.increment!(:views)
end
```

WARNING: この機能を使うには、`lock`メソッドで渡す生SQLがデータベースでサポートされていなければなりません。サポートされていない場合は`ActiveRecord::StatementInvalid`例外が発生します。

モデルのインスタンスが既にある場合は、[`with_lock`][]メソッドを使うことで、トランザクションの開始とロックの取得を一度に行えます。
ブロックは現在のトランザクションを受け取るので、以下のようにコールバックを登録できます。

```ruby
book = Book.first
# yieldする前にbookをロック付きで再読み込みする
book.with_lock do |transaction|
  # このブロックはトランザクション内で呼び出される
  # bookはロック済み
  transaction.after_commit { puts "hello" }
  book.increment!(:views)
end
```

テーブルを結合する
--------------

テーブルの結合（JOIN）を使うと、1件のクエリで複数のテーブルからレコードを取得できます。たとえば、書籍（books）とその著者（authors）をまとめて取得できます。

Active Recordは`JOIN`句のSQLを具体的に指定するために、[`joins`][]と[`left_outer_joins`][]という2つの検索メソッドを提供しています。

- `joins`メソッド:`INNER JOIN`を行うクエリや、カスタムクエリで使う
- `left_outer_joins`メソッド: `LEFT OUTER JOIN`を行うクエリで使う

### `joins`

[`joins`][]メソッドには複数の使い方があります。

#### SQLフラグメント文字列を使う

`joins`メソッドの引数に生のSQLを指定することで`JOIN`句を指定できます。

```ruby
Author.joins("INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE")
```

これによって以下のSQLが生成されます。

```sql
SELECT authors.* FROM authors
  INNER JOIN books ON books.author_id = authors.id AND books.out_of_print = FALSE
```

#### 名前付き関連付けの配列/ハッシュを使う

Active Recordでは、[関連付け](association_basics.html)で`joins`メソッドを利用して`JOIN`句を指定する際に、モデルで定義されている関連付け名をショートカットとして利用できます。

以下のすべてにおいて、`INNER JOIN`による結合クエリが期待どおりに生成されます。

##### 単一関連付けを結合する

関連付け名（`:reviews`）を渡すことで単一のテーブルを結合します。

```ruby
Book.joins(:reviews)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
```

上のSQLクエリは、レビュー付きのすべての本についてBookのレコードを返します。

NOTE: 本1冊にレビューが2件以上ついている場合は、本が重複表示される点にご注意ください。重複のない一意の本を表示したい場合は、`Book.joins(:reviews).distinct`が使えます。

##### 複数の関連付けを結合する

関連付け名を複数（`:author`、`:reviews`）渡すことで、複数のテーブルを結合します。

```ruby
Book.joins(:author, :reviews)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN authors ON authors.id = books.author_id
  INNER JOIN reviews ON reviews.book_id = books.id
```

上のSQLクエリは、著者があり、かつレビューが1件以上ついているすべての本を返します。

NOTE: 本1冊にレビューが2件以上ついている場合は、本が重複表示される点にご注意ください。重複のない一意の本を表示したい場合は、`Book.joins(:reviews).distinct`が使えます。

##### ネストした関連付けを結合する（単一レベル）

関連付け名をハッシュ形式で渡すことで、テーブルを別の結合済みテーブルに結合できます。

```ruby
Book.joins(reviews: :customer)
```

上によって以下が生成されます。

```sql
SELECT books.* FROM books
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
```

上のSQLクエリは、顧客がレビューを付けたすべての本を返します。

##### ネストした関連付けを結合する（複数レベル）

より複雑な結合を行いたい場合は、ハッシュと配列を組み合わせて指定します。

```ruby
Author.joins(books: [{ reviews: { customer: :orders } }, :supplier])
```

上によって以下のSQLクエリが生成されます。

```sql
SELECT authors.* FROM authors
  INNER JOIN books ON books.author_id = authors.id
  INNER JOIN reviews ON reviews.book_id = books.id
  INNER JOIN customers ON customers.id = reviews.customer_id
  INNER JOIN orders ON orders.customer_id = customers.id
  INNER JOIN suppliers ON suppliers.id = books.supplier_id
```

上のSQLクエリは、「"注文したことのある顧客によるレビュー"と"仕入先"（supplier）の**両方**を持つ本の、すべての著者」を返します。

#### 結合テーブルで条件を指定する

結合テーブルに条件を指定するときには、標準の[配列](#条件を配列で指定する)や[文字列](#条件を文字列だけで指定する)条件を利用できます。
[ハッシュ条件](#条件でハッシュを使う)の場合は、結合テーブルで条件を指定するときに特殊な構文を使います。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where("orders.created_at" => time_range).distinct
```

上は、`created_at`をSQLの`BETWEEN`式で比較することで、昨日注文を行ったすべての顧客を検索できます。

以下のようにハッシュ条件をネストさせると、さらに読みやすくなります。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).where(orders: { created_at: time_range }).distinct
```

さらに高度な条件指定や既存の名前付きスコープの再利用を行いたい場合は、[`merge`][]を利用してもよいでしょう。
最初に、`Order`モデルに新しい名前付きスコープを追加してみましょう。

```ruby
class Order < ApplicationRecord
  belongs_to :customer

  scope :created_in_time_range, ->(time_range) {
    where(created_at: time_range)
  }
end
```

これで、`created_in_time_range`スコープを`merge`でマージできるようになります。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Customer.joins(:orders).merge(Order.created_in_time_range(time_range)).distinct
```

上も、SQLの`BETWEEN`式で比較することで、昨日注文を行ったすべての顧客を検索できます。

### `left_outer_joins`

INNER JOINでは、関連付けられたレコードを持つレコードのみが返されます。

関連レコードがあるかどうかにかかわらずレコードのセットを取得したい場合は、[`left_outer_joins`][]メソッドを使います。

```ruby
Customer.left_outer_joins(:reviews).distinct.select("customers.*, COUNT(reviews.*) AS reviews_count").group("customers.id")
```

上のコードは、以下のSQLクエリを生成します。

```sql
SELECT DISTINCT customers.*, COUNT(reviews.*) AS reviews_count FROM customers
  LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
  GROUP BY customers.id
```

上のSQLクエリは、レビュー投稿の有無にかかわらずすべての顧客を対象とし、それぞれの顧客情報とレビューの投稿数を返します。


### `where.associated`と`where.missing`

`associated`クエリメソッドと`missing`クエリメソッドは、それぞれ関連付けが「存在する場合」や「存在しない場合」に基づいてレコードのコレクションをSELECTできます。

`where.associated`を使うには、以下のように最初に`where`を引数なしで記述し、それに続けて関連付け名を指定した`associated`を記述します。

```ruby
Customer.where.associated(:reviews)
```

上によって以下のSQLクエリが生成されます。

```sql
SELECT customers.* FROM customers
  INNER JOIN reviews ON reviews.customer_id = customers.id
  WHERE reviews.id IS NOT NULL
```

このSQLクエリは、レビューを1件以上投稿したすべての顧客を返します。

`where.missing`は、`where.associated`と逆の動作です。`where.missing`を使うと、関連付けを持たないレコードをSELECTできます。

```ruby
Customer.where.missing(:reviews)
```

上によって以下のSQLクエリが生成されます。

```sql
SELECT customers.* FROM customers
  LEFT OUTER JOIN reviews ON reviews.customer_id = customers.id
  WHERE reviews.id IS NULL
```

このSQLクエリは、レビューをまったく投稿していないすべての顧客を返します。

joinが既に定義済みの場合、`associated`でそのjoinが使われます。

```ruby
# associatedは、このクエリではJOINではなくLEFT JOINを使う
Post.left_joins(:author).where.associated(:author)
```

関連付けをeager-loadingする
--------------------------

eager-loading（一括読み込み）とは、`ActiveRecord::Relation`から返されるオブジェクトに関連付けられたレコードを、できるだけパフォーマンスの高いクエリで読み込むためのメカニズムです。

### N + 1クエリ問題

1件のクエリでN個のレコード（Nは1より大きい数）のリストを取得すると、レコード1件につき1個のクエリが発行され、合計でN個の追加クエリが発生する場合があります。

以下のコードについて考えてみましょう。このコードは、本を10冊検索して著者の`last_name`を表示します。

```ruby
books = Book.limit(10)

books.each do |book|
  puts book.author.last_name
end
```

このコードは一見何の問題もないように見えます。しかし本当の問題は、実行されたクエリの回数が無駄に多いことなのです。
上のコードでは、最初に本を10冊検索するクエリを1回発行し、次にそこから`last_name`を取り出すのにクエリを10回発行しますので、合計で **11** 回のクエリが発行されます。

#### N + 1クエリ問題を解決する

Active Recordでは、以下のメソッドを用いることで、読み込まれるすべての関連付けを事前に指定できます。

* [`includes`][]
* [`preload`][]
* [`eager_load`][]

INFO: 3つのメソッドのうち、より高機能な[`includes`][]メソッドを使うことが推奨されます。[`includes`][]は、クエリに応じて[`preload`][]と[`eager_load`][]を自動的に使い分けるようになっています。

### `includes`

`includes`を指定すると、Active Recordは指定されたすべての関連付けをできるだけパフォーマンスの高いクエリで読み込むようになります。

上の例で言うと、以下のように`includes`メソッドを使う形に書き直すことで、著者（author）がeager-loading（一括読み込み）されます。

```ruby
books = Book.includes(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

最初の例では **11** 回もクエリが実行されましたが、書き直した例ではわずか **2** 回にまで減りました。

```sql
SELECT books.* FROM books
  LIMIT 10

SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

#### 複数の関連付けをeager-loadingする

Active Recordは、1回の`ActiveRecord::Relation`呼び出しで、関連付けをいくつでもeager-loading（一括読み込み）できます。
これを行なうには、`includes`メソッドに「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を渡します。

複数の関連付けをeager-loadingするには、以下のように関連付け名を配列として渡します。

```ruby
Customer.includes(:orders, :reviews)
```

上のコードは、すべての顧客を読み込むとともに、顧客ごとに関連付けられている注文やレビューも読み込みます。

ネストした関連付けをeager-loadingするには、以下のようにハッシュを渡します。

```ruby
Customer.includes(orders: { books: [:supplier, :author] }).find(1)
```

上のコードは、id=1の顧客を検索し、関連付けられたすべての注文、すべての注文に対応する書籍、そして各書籍の著者と仕入先をeager-loadingします。

Active Recordでは、eager-loadingされた関連付けに条件も指定可能ですが、この方法よりも[joins](#テーブルを結合する)を使うことをオススメします。

とはいえ、eager-loadingされた関連付けに対して条件を指定せざるを得ない場合は、以下のように普通にwhereを使っても大丈夫です。

```ruby
Author.includes(:books).where(books: { out_of_print: true })
```

上のコードは、以下のように`LEFT OUTER JOIN`を含むクエリを1件生成します。`joins`メソッドを使うと、代わりに`INNER JOIN`を使うクエリが生成されます。

```sql
  SELECT authors.id AS t0_r0, ... books.updated_at AS t1_r5 FROM authors
    LEFT OUTER JOIN books ON books.author_id = authors.id
    WHERE (books.out_of_print = true)
```

`where`条件がない場合は、通常のクエリが2つ生成されます。

NOTE: `where`がこのように動作するのは、ハッシュを渡した場合だけです。SQLフラグメント文字列を渡す場合には、強制的に結合テーブルとして扱うために[`references`][]を使う必要があります。

```ruby
Author.includes(:books).where("books.out_of_print = true").references(:books)
```

この`includes`クエリでは、仮にどの著者にも本がない場合でも、すべての著者が引き続き読み込まれます。
`joins`（INNER JOIN）を使う場合、結合条件は**必ずマッチしなければならず** 、それ以外の場合にはレコードは返されません。

NOTE: 関連付けがjoinの一部としてeager-loadingされている場合、読み込んだモデルの中にカスタマイズされたselect句のフィールドが存在しなくなります。これは親レコードと子レコードのどちらに現れるべきかが曖昧なためです。

INFO: `includes`の利用が推奨されます。`includes`は、クエリに応じて個別のクエリと`LEFT OUTER JOIN`を使い分ける、より高機能なメソッドです。

### `preload`

`preload`を使うと、Active Recordは指定された関連付けを、1つの関連付けにつき1件のクエリで読み込みます。
これは、条件がない場合の`includes`の振る舞いと完全に同じです。

N+1クエリ問題が発生した場合で再び説明すると、以下のように`Book.limit(10)`を`preload`メソッドで書き換えることで著者（author）をプリロードできます。

```ruby
books = Book.preload(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

書き換え前は **11** 回もクエリが実行されましたが、書き直した上のコードはわずか **2** 回にまで減りました。

```sql
SELECT books.* FROM books
  LIMIT 10

SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

NOTE: 「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を用いる`preload`メソッドは、`includes`メソッドと同様に1件の`ActiveRecord::Relation`呼び出しで任意の個数の関連付けを読み込みます。シンプルなケースでは、`includes`メソッドと同じ戦略を取ります。ただし`includes`メソッドと異なり、プリロードされる関連付けに条件を指定できません。

### `eager_load`

`eager_load`メソッドを使うと、Active Recordは、指定されたすべての関連付けを`LEFT OUTER JOIN`で読み込みます。

N+1クエリ問題が発生した場合で再び説明すると、以下のように`Book.limit(10)`を`eager_load`メソッドで書き換えることで著者（author）をeager-loadingできます。

```ruby
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

書き換え前は**11**回もクエリが実行されましたが、書き直した上のコードはわずか**1**回にまで減りました。

```sql
SELECT "books"."id" AS t0_r0, "books"."title" AS t0_r1, ... FROM "books"
  LEFT OUTER JOIN "authors" ON "authors"."id" = "books"."author_id"
  LIMIT 10
```

NOTE: 「配列」「ハッシュ」または「配列やハッシュをネストしたハッシュ」を用いる`eager_load`メソッドは、`includes`メソッドと同様に1件の`ActiveRecord::Relation`呼び出しで任意の個数の関連付けを読み込みます。また、`includes`メソッドと同様に、eager-loadingされる関連付けに条件を指定できます。

### `strict_loading`

eager-loadingはN+1クエリを防止できますが、いくつかの関連付けを遅延読み込み（lazy-loading）している可能性もあります。[`strict_loading`][]を有効にすることで、関連付けを遅延読み込みしなくなります。

リレーションで`strict_loading`モードを有効にすると、レコードが任意の関連付けを遅延読み込みしようとしたときに`ActiveRecord::StrictLoadingViolationError`が発生します。

```ruby
user = User.strict_loading.first
user.address.city  # ActiveRecord::StrictLoadingViolationErrorが発生
user.comments.to_a # ActiveRecord::StrictLoadingViolationErrorが発生
```

すべてのリレーションで`strict_loading`を有効にするには、[`config.active_record.strict_loading_by_default`][]フラグを`true`に変更します。

```ruby
config.active_record.strict_loading_by_default = true
```

違反をロガーに送信するには、[`config.active_record.action_on_strict_loading_violation`][]を`:log`に変更します。

```ruby
config.active_record.action_on_strict_loading_violation = :log
```

[`strict_loading`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-strict_loading
[`config.active_record.strict_loading_by_default`]:
    configuring.html#config-active-record-strict-loading-by-default
[`config.active_record.action_on_strict_loading_violation`]:
    configuring.html#config-active-record-action-on-strict-loading-violation

### `strict_loading!`

以下のように、レコード自身で[`strict_loading!`][]を呼び出すことでstrict-loading（強制読み込み）を有効にすることも可能です。

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
user.address.city # => "Tatooine"
user.comments.to_a # => [#<Comment:0x00...]
user.comments.first.likes.to_a # ActiveRecord::StrictLoadingViolationErrorをraiseする
```

[`strict_loading!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Core.html#method-i-strict_loading-21

### 関連付けに`strict_loading`オプションを指定する

以下のように`strict_loading`オプションを指定することで、単一の関連付けに対してstrict-loadingを有効にすることも可能です。

```ruby
class Author < ApplicationRecord
  has_many :books, strict_loading: true
end
```

スコープ
------

よく使うクエリをスコープに設定しておくと、関連オブジェクトやモデルへのメソッド呼び出しとして参照できるようになります。スコープでは、`where`、`joins`、`includes`など、これまでに登場したメソッドをすべて使えます。
別のスコープなどのメソッドをスコープ上で呼び出せるようにするため、スコープ本体は常に`ActiveRecord::Relation`か`nil`のいずれかを返すべきです。

シンプルなスコープを設定するには、以下のようにクラスの内部に[`scope`][]メソッドを書き、スコープが呼び出されたときに実行したいクエリをそこで渡します。

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

作成した`out_of_print`スコープは、以下のようにクラスメソッドとして呼び出せます。

```irb
store(dev)> Book.out_of_print
=> #<ActiveRecord::Relation> # すべての絶版の本
```

あるいは、以下のように`Book`オブジェクトを用いる関連付けでも呼び出せます。

```irb
store(dev)> author = Author.first
store(dev)> author.books.out_of_print
=> #<ActiveRecord::Relation> # `author`によるすべての絶版の本
```

[`scope`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope

### 引数を渡す

スコープには以下のように引数を渡せます。

```ruby
class Book < ApplicationRecord
  scope :costs_more_than, ->(amount) { where("price > ?", amount) }
end
```

引数付きスコープの呼び出しは、クラスメソッドの呼び出しと同様です。

```irb
store(dev)> Book.costs_more_than(100.10)
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
store(dev)> author.books.costs_more_than(100.10)
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

ただし、1つ重要な注意点があります。スコープは、条件文を評価した結果が`false`であっても、常に`ActiveRecord::Relation`オブジェクトを返します。クラスメソッドの場合は`nil`を返すので、この点において振る舞いが異なります。
したがって、条件文を使うクラスメソッドをチェインし、かつ、条件文のいずれかが`false`を返す場合、`NoMethodError`を発生する可能性があります。

条件が`false`と評価された場合に`self`を返すことで、クラスメソッドをスコープと同じ振る舞いにできます（常に`ActiveRecord::Relation`を返す）。

```ruby
class Order < ApplicationRecord
  def self.created_before(time)
    if time.present?
      where(created_at: ...time)
    else
      self
    end
  end
end
```

こうすることで、このクラスメソッドは常に`ActiveRecord::Relation`オブジェクトを返すようになるので、スコープと同様に安全にチェインできます。

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

スコープの引数が`Hash`で与えられると、レコードを作成・ビルドするときに`default_scope`も適用されます。ただし、レコードを更新する場合は適用されません。

たとえば、`out_of_print`を`false`に設定する`default_scope`がある状況で、`out_of_print`属性を`true`に設定した新しい書籍を作成すると、`default_scope`が適用されます。

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }
end
```

```irb
store(dev)> Book.new
=> #<Book id: nil, out_of_print: false>
store(dev)> Book.unscoped.new
=> #<Book id: nil, out_of_print: nil>
```

ただし、引数が`Array`として渡されると、`default_scope`クエリの引数は`Hash`のデフォルト値に変換されない点に注意が必要です。

```ruby
class Book < ApplicationRecord
  default_scope { where("out_of_print = ?", false) }
end
```

```irb
store(dev)> Book.new
=> #<Book id: nil, out_of_print: nil>
```

[`default_scope`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Default/ClassMethods.html#method-i-default_scope


### スコープのマージ

複数のスコープを順に呼び出す場合、`where`句の場合と同様に、スコープも`AND`条件でマージできます。

```ruby
class Book < ApplicationRecord
  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }

  scope :old, -> { where(year_published: ...50.years.ago.year) }
end
```

```irb
store(dev)> Book.out_of_print.old
SELECT books.* FROM books WHERE books.out_of_print = "true" AND books.year_published < 1969
```

スコープから別のスコープを呼び出すことも可能です。

```ruby
class Book < ApplicationRecord
  scope :out_of_print, -> { where(out_of_print: true) }
  scope :old, -> { where(year_published: ...50.years.ago.year) }
  scope :out_of_print_and_old, -> { out_of_print.old }
end
```

`scope`と`where`条件は自由に組み合わせられます。このとき生成される最終的なSQLでは、以下のようにすべての条件が`AND`で結合されます。

```irb
store(dev)> Book.in_print.where(price: ...100)
SELECT books.* FROM books WHERE books.out_of_print = "false" AND books.price < 100
```

末尾の`where`句を直前の`scope`より優先したい場合は、[`merge`][]が使えます。

```irb
store(dev)> Book.in_print.merge(Book.out_of_print)
SELECT books.* FROM books WHERE books.out_of_print = true
```

ただし、1つ重要な注意点があります。`default_scope`で定義した条件は、以下のように`scope`や`where`で定義した条件の前方に追加されます。

```ruby
class Book < ApplicationRecord
  default_scope { where(year_published: 50.years.ago.year..) }

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

```irb
store(dev)> Book.all
SELECT books.* FROM books WHERE (year_published >= 1969)

store(dev)> Book.in_print
SELECT books.* FROM books WHERE (year_published >= 1969) AND books.out_of_print = false

store(dev)> Book.where(year_published: 2020)
SELECT books.* FROM books WHERE (year_published >= 1969) AND (year_published = 2020)
```

上の例でわかるように、`default_scope`は、`scope`条件と`where`の条件の両方でマージされています。

[`merge`]:
    https://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html#method-i-merge

### ブロックレベルのスコープ

[`scoping`][]メソッドを使うと、現在のリレーションの条件を一時的にブロック内で適用できます。ブロック内で実行されるすべてのクエリで、そのリレーションのスコープが使われるようになります。

#### 基本的な使い方

```ruby
Order.where(customer_id: 1).scoping do
  Order.first
end

# SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = ? ORDER BY "orders"."id" ASC LIMIT ?  [["customer_id", 1], ["LIMIT", 1]]
```

上の例では、ブロックがリレーションのスコープ内で実行されるため、`customer_id: 1`という条件が自動的に適用されます。

#### ブロック内のすべてのクエリにスコープを適用する

`scoping`は、デフォルトでは`first`や`last`や`where`などの検索メソッド（finderメソッド）のみに適用されます。
個別のレコードに対する`update`や`delete`などを含む「すべてのクエリ」に対してスコープが効くようにしたい場合は、`all_queries: true`オプションを指定します。

```ruby
Order.where(customer_id: 1).scoping(all_queries: true) do
  order = Order.first
  order.update(status: :complete)
end

# Order Load (0.1ms)    SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = ? ORDER BY "orders"."id" ASC LIMIT ?  [["customer_id", 1], ["LIMIT", 1]]
# TRANSACTION (0.0ms)   BEGIN immediate TRANSACTION
# Order Update (0.1ms)  UPDATE "orders" SET "status" = ?, "updated_at" = ? WHERE "orders"."id" = ? AND "orders"."customer_id" = ?  [["status", 2], ["updated_at", "2025-11-25 11:26:16.089553"], ["id", 1], ["customer_id", 1]]
# TRANSACTION (0.0ms)   COMMIT TRANSACTION
```

これにより、ブロック内で実行されるすべてのクエリに対して`customer_id: 1`条件が適用されます。

`scoping`ブロックで`all_queries: true`が指定されると、その内側のブロックで`all_queries: false`を指定しても解除できません。

```ruby
Order.where(customer_id: 1).scoping(all_queries: true) do
  # ArgumentErrorが発生する
  Order.scoping(all_queries: false) do
    # ...
  end
end
```

[`scoping`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-scoping

### すべてのスコープを解除する

何らかの理由でスコープをすべて解除したい場合は[`unscoped`][]メソッドが使えます。このメソッドは、モデルで指定されている`default_scope`を適用したくないクエリがある場合に特に便利です。

```ruby
class Book < ApplicationRecord
  default_scope { where(out_of_print: false) }

  scope :in_print, -> { where(out_of_print: false) }
  scope :out_of_print, -> { where(out_of_print: true) }
end
```

このメソッドはスコープをすべて解除し、テーブルに対して通常の（スコープなしの）クエリを実行するようにします。

```irb
store(dev)> Book.unscoped.all
SELECT books.* FROM books

store(dev)> Book.where(out_of_print: true).unscoped.all
SELECT books.* FROM books
```

`unscoped`にはブロックも渡せます。ブロック内では、それまでに設定されたスコープがどのクエリにも適用されなくなります。

```irb
store(dev)> Book.in_print.unscoped { Book.out_of_print }

SELECT books.* FROM books WHERE books.out_of_print = true
```

[`unscoped`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Default/ClassMethods.html#method-i-unscoped

`enum`
-----

属性で使う値を、事前定義済みの値リストのみに制限したい場合があります。

enumを使うと、属性で使う値を配列で定義して名前で参照できるようになります。値がデータベースに実際に保存されるときは、値に対応する整数値が保存されます。

enumを宣言すると、enumに設定可能なすべての値に対して「スコープ」「述語メソッド」「セッターメソッド」が作成されます。例:

```ruby
class Order < ApplicationRecord
  enum :status, [:shipped, :being_packaged, :complete, :cancelled]
end
```

上の[`enum`][]が宣言されると、個別のenum値に対して自動的に[スコープ](#スコープ)が作成され、`status`に特定の値が設定されている（もしくは設定されていない）すべてのレコードを検索できるようになります。

```irb
store(dev)> Order.shipped
=> #<ActiveRecord::Relation> # status == :shippedを満たすすべての注文
store(dev)> Order.not_shipped
=> #<ActiveRecord::Relation> # status != :shippedを満たすすべての注文
```

enumの各値に対応する述語メソッド（`?`で終わるメソッド）も自動で作成されます。
述語メソッドは、モデルの`status` enumにその値があるかどうかを以下のように`true`/`false`で返します。

```irb
store(dev)> order = Order.shipped.first
store(dev)> order.shipped?
=> true
store(dev)> order.complete?
=> false
```

enumの各値に対応する`!`付きのインスタンスメソッドも自動で作成されます。
enum値の名前を持つインスタンスメソッドを呼び出すと、まず`status`の値が指定の値に更新され、次に`status`の値が指定された値で正常に更新されたかどうかを返します。

```irb
store(dev)> order = Order.first
store(dev)> order.shipped!
UPDATE "orders" SET "status" = ?, "updated_at" = ? WHERE "orders"."id" = ?  [["status", 0], ["updated_at", "2019-01-24 07:13:08.524320"], ["id", 1]]
=> true
```

enumの完全なドキュメントについては[`ActiveRecord::Enum`](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)を参照してください。

[`enum`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Enum.html#method-i-enum

計算
------------

Active Recordは、データベース上でさまざまな計算を実行するメソッドをサポートしています。これらのメソッドで計算する場合、`ActiveRecord`モデルをインスタンス化する必要はありません。
一般に、結果の計算はデータベースで実行する方が高速です。

このセクションでは[`count`][]メソッドを例に説明しますが、同じパターンがすべての計算メソッドに当てはまります。

すべての計算メソッドは、モデルに対して直接実行できます。

```irb
store(dev)> Customer.count
SELECT COUNT(*) FROM customers
# => 3753
```

リレーションに対しても直接実行できます。

```irb
store(dev)> Customer.where(first_name: "Ryan").count
SELECT COUNT(*) FROM customers WHERE (first_name = "Ryan")
# => 17
```

この他にも、リレーションに対してさまざまな検索メソッドを利用して複雑な計算を行なえます。

```irb
store(dev)> Customer.includes("orders").where(first_name: "Ryan", orders: { status: "shipped" }).count
```

上のコードは以下のSQLを実行します。

```sql
SELECT COUNT(DISTINCT customers.id) FROM customers
  LEFT OUTER JOIN orders ON orders.customer_id = customers.id
  WHERE (customers.first_name = "Ryan" AND orders.status = 0)
```

上は、Orderモデルに`enum status: [ :shipped, :being_packed, :cancelled ]`が設定されていることが前提です。

### `count`

モデルのテーブルに含まれるレコードの件数を数えたいときは、`Customer.count`を呼び出すことでレコードの件数が返されます。

データベースで肩書き（title）を持つ顧客だけを数えたいときは、以下のように`:title`を渡します。

```ruby
Customer.count(:title)
```

### `average`

テーブルに含まれる特定の数値の平均を得るには、そのテーブルを持つクラスで[`average`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.average("subtotal")
# => 3.14159265
```

[`average`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-average

### `minimum`

テーブルに含まれるフィールドの最小値を得るには、そのテーブルを持つクラスで[`minimum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.minimum("subtotal")
# => 123.45
```

[`minimum`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-minimum

### `maximum`

テーブルに含まれるフィールドの最大値を得るには、そのテーブルを持つクラスに対して[`maximum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.maximum("subtotal")
# => 4567.89
```

[`maximum`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-maximum

### `sum`

テーブルに含まれるフィールドのすべてのレコードにおける合計を得るには、そのテーブルを持つクラスに対して[`sum`][]メソッドを呼び出します。このメソッド呼び出しは以下のようになります。

```ruby
Order.sum("subtotal")
# => 12345.67
```

[`sum`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-sum

EXPLAINを実行する
---------------

リレーションに対して[`explain`][]を実行できます。EXPLAINの出力形式はデータベースによって異なります。

以下の例は、リレーションに対して`explain`を実行する方法を示しています。

```ruby
Customer.where(id: 1).joins(:orders).explain
```

出力結果は、データベースアダプタによって変わります。
たとえば、MySQLとMariaDBでは、以下のような結果が生成されます。

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

Active Recordは、対応するデータベースシェルの出力をエミュレーションして読みやすく整形します。
そのため、同じクエリをPostgreSQLアダプタで実行すると、以下のような結果が得られます。

```sql
EXPLAIN SELECT "customers".* FROM "customers" INNER JOIN "orders" ON "orders"."customer_id" = "customers"."id" WHERE "customers"."id" = $1 [["id", 1]]
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop  (cost=4.33..20.85 rows=4 width=164)
    ->  Index Scan using customers_pkey on customers  (cost=0.15..8.17 rows=1 width=164)
          Index Cond: (id = "1"::bigint)
    ->  Bitmap Heap Scan on orders  (cost=4.18..12.64 rows=4 width=8)
          Recheck Cond: (customer_id = "1"::bigint)
          ->  Bitmap Index Scan on index_orders_on_customer_id  (cost=0.00..4.18 rows=4 width=0)
                Index Cond: (customer_id = "1"::bigint)
(7 rows)
```

eager-loadingを使うと、内部的には複数のクエリがトリガーされることがあり、このとき一部のクエリで先行クエリの結果が必要になることがあります。
このため、`explain`は、このクエリを実際に実行してから、クエリプランを要求します。以下に例を示します。

```ruby
Customer.where(id: 1).includes(:orders).explain
```

MySQLとMariaDBでは、以下の結果を生成します。

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

EXPLAIN SELECT `orders`.* FROM `orders`  WHERE `orders`.`customer_id` IN (1)
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
   Index Cond: (id = "1"::bigint)
(2 rows)
```

`explain`にさまざまな計算メソッド（[`count`][]、[`first`][]、[`last`][]、[`average`][]、[`maximum`][]、[`minimum`][]、[`sum`][]、[`pluck`][] など）をチェインすることで、それらの操作のクエリプランを表示できます。

```ruby
Customer.where(active: true).explain.count
Customer.order(:created_at).explain.first
```

[`explain`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-explain

### `explain`のオプション

データベースとそれをサポートするアダプタ（現在はPostgreSQL、MySQL、MariaDB）については、より深い分析を行うためのオプションも渡せます。

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
         Index Cond: (shop_accounts.id = "1"::bigint)
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

[MySQL5.7-explain]:
  https://dev.mysql.com/doc/refman/5.7/en/explain.html
[MySQL8-explain]:
  https://dev.mysql.com/doc/refman/8.0/en/explain.html
[MariaDB-explain]:
  https://mariadb.com/kb/en/analyze-and-explain-statements/

### `explain`の出力結果を解釈する

EXPLAINの出力を解釈することは、本ガイドの範疇を超えます。
以下の情報を参考にしてください。

* SQLite3: [EXPLAIN QUERY PLAN](https://www.sqlite.org/eqp.html)

* MySQL: [EXPLAIN出力フォーマット](https://dev.mysql.com/doc/refman/8.0/ja/explain-output.html) （v8.0日本語）

* MariaDB: [EXPLAIN](https://mariadb.com/kb/en/explain/)

* PostgreSQL: [EXPLAINの利用](https://www.postgresql.jp/document/current/html/using-explain.html)
