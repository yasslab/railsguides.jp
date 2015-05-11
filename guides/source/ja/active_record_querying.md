
Active Record クエリインターフェイス
=============================

このガイドでは、Active Recordを使用してデータベースからデータを取り出すためのさまざまな方法について解説します。

このガイドの内容:

* 多くのメソッドや条件を駆使してレコードを検索する
* 検索されたレコードのソート順、取り出したい属性、グループ化の有無などを指定する
* eager loadingを使用して、データ取り出しに必要なクエリの実行回数を減らす
* 動的検索メソッドを使用する
* 特定のレコードが存在するかどうかをチェックする
* Active Recordモデルでさまざまな計算を行う
* リレーションでEXPLAINを実行する

--------------------------------------------------------------------------------

生のSQLを使用してデータベースのレコードを検索することに慣れきった人がRailsに出会うと、Railsでは同じ操作をずっと洗練された方法で実現できることに気付くでしょう。Active Recordを使用することで、SQLを直に実行する必要はほぼなくなります。

本ガイドのコード例では、基本的に以下のモデルを使用します。

TIP: 特に記さない限り、モデル中の`id`は主キーを表します。

```ruby
class Client < ActiveRecord::Base
  has_one :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ActiveRecord::Base
  belongs_to :client
end
```

```ruby
class Order < ActiveRecord::Base
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ActiveRecord::Base
  has_and_belongs_to_many :clients
end
```

Active Recordは、ユーザーに代わってデータベースにクエリを発行します。発行されるクエリは多くのデータベースシステム (MySQL、PostgreSQL、SQLiteなど) と互換性があります。Active Recordを使用していれば、利用しているデータベースシステムの種類にかかわらず、同じ表記を使用できます。

データベースからオブジェクトを取り出す
------------------------------------

Active Recordでは、データベースからオブジェクトを取り出すための検索メソッドを多数用意しています。これらの検索メソッドを使用することで、生のSQLを書くことなく、データベースへの特定のクエリを実行するための引数を渡すことができます。

以下のメソッドが用意されています。

* `bind`
* `create_with`
* `distinct`
* `eager_load`
* `extending`
* `from`
* `group`
* `having`
* `includes`
* `joins`
* `limit`
* `lock`
* `none`
* `offset`
* `order`
* `preload`
* `readonly`
* `references`
* `reorder`
* `reverse_order`
* `select`
* `uniq`
* `where`

上のメソッドは、すべて`ActiveRecord::Relation`のインスタンスを返します。

`Model.find(options)`という操作を要約すると以下のようになります。

* 与えられたオプションを同等のSQLクエリに変換します。
* SQLクエリを発行し、該当する結果をデータベースから取り出します。
* 得られた結果を行ごとに同等のRubyオブジェクトとしてインスタンス化します。
* 必要であれば`after_find`コールバックを実行します。

### 単一のオブジェクトを取り出す

Active Recordには、単一のオブジェクトを取り出すためのさまざま方法が用意されています。

#### 主キーを使用する

`Model.find(primary_key)`を使用すると、与えられたどのオプションにもマッチする _主キー_ に対応するオブジェクトを取り出すことができます。例：

```ruby
# Find the client with primary key (id) 10.
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

`Model.find(primary_key)`でマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

#### `take`

`Model.take`はレコードを1つ取り出します。このとき、どのレコードが取り出されるかは指定されません。例：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 1
```

モデルにレコードが1つもない場合は`Model.take`は`nil`を返します。このとき例外は発生しません。

TIP: このメソッドでどのレコードが取り出されるかは、使用するデータベースエンジンによって異なることがあります。

#### `first`

`Model.first`は、主キー順の最初のレコードを取り出します。例：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql 
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

モデルにレコードが1つもない場合は`Model.first`は`nil`を返します。このとき例外は発生しません。

#### `last`

`Model.last`は、主キー順の最後のレコードを取り出します。例：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

モデルにレコードが1つもない場合は`Model.last`は`nil`を返します。このとき例外は発生しません。

#### `find_by`

`Model.find_by` は、与えられた条件にマッチするレコードのうち最初のレコードだけを返します。例：

```ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

上の文は以下のように書くこともできます。

```ruby
Client.where(first_name: 'Lifo').take
```

#### `take!`

`Model.take!`は、レコードを1つ取り出します。例：

```ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 1
```

`Model.take!`でマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

#### `first!`

`Model.first!`は、主キー順の最初のレコードを取り出します。例：

```ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql 
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

`Model.first!`でマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

#### `last!`

`Model.last!`は、主キー順の最後のレコードを取り出します。例：

```ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

`Model.last!`でマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

#### `find_by!`

`Model.find_by!` は、与えられた条件にマッチするレコードのうち最初のレコードだけを返します。マッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。例：

```ruby
Client.find_by! first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by! first_name: 'Jon'
# => ActiveRecord::RecordNotFound
```

上の文は以下のように書くこともできます。

```ruby
Client.where(first_name: 'Lifo').take! 
```

### 複数のオブジェクトを取り出す

#### 複数の主キーを使用する

`Model.find()` は _主キー_ の配列を受け付け、与えられた _主キー_ にマッチするすべてのレコードを配列の形で返します。例：

```ruby
# Find the clients with primary keys 1 and 10.
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: `Model.find(array_of_primary_key)`は、与えられた主キーのうち1つでもマッチしなければ`ActiveRecord::RecordNotFound`例外を発生します。

#### take

`Model.take(limit)`は、`limit`で指定された数だけレコードを取り出します。このとき取り出し順は指定できません。

```ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 2
```

#### first

`Model.first(limit)`は、主キー順の最初から、`limit`で指定された数だけレコードを取り出します。

```ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

#### last

`Model.last(limit)`は、主キー順の最後から、`limit`で指定された数だけレコードを取り出します。

```ruby
Client.last(2)
# => [#<Client id: 10, first_name: "Ryan">,
      #<Client id: 9, first_name: "John">]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY id DESC LIMIT 2
```

### 複数のオブジェクトをバッチで取り出す

多数のレコードに対して反復処理を行いたいことがあります。たとえば、多くのユーザーにニュースレターを送信したい、データをエクスポートしたいなどです。

このような処理をそのまま実装すると以下のようになるでしょう。

```ruby
# このような処理を数千件ものレコードに対して実行すると、効率が大幅に低下します。
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

しかし上のような処理は、テーブルのサイズが大きくなるにつれて非現実的になります。`User.all.each`は、Active Recordに対して _テーブル全体_ を一度に取り出し、しかも1行ごとにオブジェクトを生成し、その巨大なモデルオブジェクトの配列をメモリに配置するからです。もし莫大な数のレコードに対してこのようなコードをまともに実行すると、コレクション全体のサイズがメモリ容量を上回ってしまうことでしょう。

Railsでは、メモリを圧迫しないサイズにバッチを分割して処理するための方法を2とおり提供しています。1つ目は`find_each`メソッドを使用する方法です。これは、レコードのバッチを1つ取り出し、次に _各_ レコードを1つのモデルとして個別にブロックにyieldします。2つ目の方法は`find_in_batches`メソッドを使用する方法です。レコードのバッチを1つ取り出し、次に _バッチ全体_ をモデルの配列としてブロックにyieldします。

TIP: `find_each`メソッドと`find_in_batches`メソッドは、一度にメモリに読み込めないような大量のレコードに対するバッチ処理のためのものです。数千のレコードに対して単にループ処理を行なうのであれば通常の検索メソッドで十分です。

#### `find_each`

`find_each`メソッドは、レコードのバッチを1つ取り出し、続いて _各_ レコードを1つのモデルとして個別にブロックにyieldします。以下の例では、`find_each`で1000件のレコードを取り出しています。この件数は`find_each`と`find_in_batches`のどちらでもデフォルト値として使用されており、続いて各レコードを1つのモデルとしてブロックに個別にyieldします。この処理は、すべてのレコードが処理されるまで繰り返されます。

```ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

##### `find_each`のオプション

`find_each`メソッドでは、通常の`find`メソッドとほぼ同じオプションが使用できます。`:order`と`:limit`は`find_each`内部で利用するために予約されており、使用できません。

通常のオプションの他に、`:batch_size`オプションと`:start`オプションも使用できます。

**`:batch_size`**

`:batch_size`オプションは、(ブロックに個別に渡される前に) 1回のバッチで取り出すレコード数を指定します。たとえば、1回に5000件ずつ処理したい場合は以下のように指定します。

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

**`:start`**

デフォルトでは、レコードは主キーの昇順に取り出されます。主キーは整数でなければなりません。並び順冒頭のIDが不要な場合、`:start`オプションを使用してシーケンスの開始IDを指定します。これは、たとえば中断したバッチ処理を再開する場合などに便利です (最後に実行された処理のIDがチェックポイントとして保存済みであることが前提です)。

たとえば、1回のバッチで5000件を取り出し、主キーが2000以降のユーザーだけにニュースレターを送信したい場合は以下のようにします。

```ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

他にも、同じ処理キューを複数の作業者で手分けする場合が考えられます。`start`オプションを適切に使用して、作業者1人につき10000レコードずつ割り当てるといった利用法です。

#### `find_in_batches`

`find_in_batches`メソッドは、レコードをバッチで取り出すという点で`find_each`と似ています。違うのは、`find_in_batches`は _バッチ_ を個別にではなくモデルの配列としてブロックにyieldするという点です。以下の例では、与えられたブロックに対して一度に最大1000までの納品書 (invoice) の配列をyieldしています。最後のブロックには残りの納品書が含まれます。

```ruby
# 1回あたりadd_invoicesに納品書1000通の配列を渡す
Invoice.find_in_batches(include: :invoice_lines) do |invoices|
  export.add_invoices(invoices)
end
```

NOTE: `:include`オプションを使用すると、モデルとともに読み込まれる関連付けに名前を付けることができます。

##### `find_in_batches`のオプション

`find_in_batches`メソッドでは、`find_each`メソッドと同様、通常の`find`メソッド用オプションに加えて`:batch_size`オプションや`:start`オプションが使用できます。`:order`と`:limit`は`find_in_batches`内部で利用するために予約されており、使用できません。

条件
----------

`where`メソッドは、返されるレコードを制限するための条件を指定します。SQL文で言う`WHERE`の部分に相当します。条件は、文字列、配列、ハッシュのいずれかの方法で与えることができます。

### 文字列だけで表された条件

検索メソッドに条件を追加したい場合、たとえば`Client.where("orders_count = '2'")`のように条件を単純に指定することができます。この場合、`orders_count`フィールドの値が2であるすべてのクライアントが検索されます。

WARNING: 条件を文字列だけで構成すると、SQLインジェクションの脆弱性が発生する可能性があります。たとえば、`Client.where("first_name LIKE '%#{params[:first_name]}%'")`という書き方は危険です。次で説明するように、配列を使用するのが望ましい方法です。

### 配列で表された条件

条件で使用する数値が変動する可能性がある場合、引数をどのようにすればよいでしょうか。この場合は以下のようにします。

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Recordは条件値の最初の要素を調べ、その後に要素が追加されていたら、最初の要素の中にある疑問符`(?)`を追加要素で置き換えます。

複数の条件を指定したい場合は次のようにします。

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

上の例では、1つ目の疑問符は`params[:orders]`の値で置き換えられ、2つ目の疑問符は`false`をSQL形式に変換したもの (変換方法はアダプタによって異なる) で置き換えられます。

以下のようなコードの書き方を強く推奨します。

```ruby
Client.where("orders_count = ?", params[:orders])
```

以下の書き方は危険であり、避ける必要があります。

```ruby
Client.where("orders_count = #{params[:orders]}")
```

条件文字列の中に変数を直接置くと、その変数はデータベースに **そのまま** 渡されてしまいます。これは、悪意のある人物がエスケープされていない危険な変数を渡すことができるということです。このようなコードがあると、悪意のある人物がデータベースを意のままにすることができ、データベース全体が危険にさらされます。くれぐれも、条件文字列の中に引数を直接置くことはしないでください。

TIP: SQLインジェクションの詳細については[Ruby on Railsセキュリティガイド](security.html#sqlインジェクション) を参照してください。

#### プレースホルダを使用した条件

疑問符`(?)`をパラメータで置き換えるスタイルと同様、配列による条件中でキー/値のハッシュを指定できます。

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date",
  {start_date: params[:start_date], end_date: params[:end_date]})
```

このように書くことで、条件で多数の変数が使用されている場合にコードが読みやすくなります。

### ハッシュを使用した条件

Active Recordは条件をハッシュで渡すこともできます。この書式を使用することで条件構文が読みやすくなります。条件をハッシュで渡す場合、ハッシュのキーには条件付けしたいフィールドを、ハッシュの値にはそのフィールドをどのように条件づけするかを、それぞれ指定します。

NOTE: ハッシュによる条件は、等値、範囲、サブセットのチェックでのみ使用できます。

#### 等値条件

```ruby
Client.where(locked: true)
```

フィールド名は文字列形式にすることもできます。

```ruby
Client.where('locked' => true)
```

belongs_toリレーションシップの場合、Active Recordオブジェクトが値として使用されていれば、モデルを指定する時に関連付けキーを使用できます。この方法はポリモーフィックリレーションシップでも同様に使用できます。

```ruby
Post.where(author: author)
Author.joins(:posts).where(posts: { author: author })
```

NOTE: この値はシンボルにすることはできません。たとえば`Client.where(status: :active)`のような書き方はできません。

#### 範囲条件

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

上の例では、昨日作成されたすべてのクライアントを検索します。内部ではSQLの`BETWEEN`文が使用されます。

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

[配列による条件](#配列で表された条件) ではさらに簡潔な文例をご紹介しています。

#### サブセット条件

SQLの`IN`式を使用してレコードを検索したい場合、条件ハッシュにそのための配列を1つ渡すことができます。

```ruby
Client.where(orders_count: [1,3,5])
```

上のコードを実行すると、以下のようなSQLが生成されます。

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

### NOT条件

SQLの`NOT`クエリは、`where.not`で表せます。

```ruby
Post.where.not(author: author)
```

言い換えれば、このクエリは`where`に引数を付けずに呼び出し、直後に`where`条件に`not`を渡して連鎖させることによって生成されています。

並び順
--------

データベースから取り出すレコードを特定の順序で並べ替えたい場合、`order`を使用できます。

たとえば、ひとかたまりのレコードを取り出し、それをテーブル内の`created_at`の昇順で並べたい場合には以下のようにします。

```ruby
Client.order(:created_at)
# または
Client.order("created_at")
```

`ASC`(昇順)や`DESC`(降順)を指定することもできます。

```ruby
Client.order(created_at: :desc)
# または
Client.order(created_at: :asc)
# または
Client.order("created_at DESC")
# または
Client.order("created_at ASC")
```

複数のフィールドを指定して並べることもできます。

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# または
Client.order(:orders_count, created_at: :desc)
# または
Client.order("orders_count ASC, created_at DESC")
# または
Client.order("orders_count ASC", "created_at DESC")
```

`order`メソッドを(条件を変えて)複数回呼び出したい場合、最初の条件に新しい条件が追加されます。

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

特定のフィールドだけを取り出す
-------------------------

デフォルトでは、`Model.find`を実行すると、結果セットからすべてのフィールドが選択されます。内部的にはSQLの`select *`が実行されています。

結果セットから特定のフィールドだけを取り出したい場合、`select`メソッドを使用できます。

たとえば、`viewable_by`カラムと`locked`カラムだけを取り出したい場合は以下のようにします。

```ruby
Client.select("viewable_by, locked")
```

上で実際に使用されるSQL文は以下のようになります。

```sql
SELECT viewable_by, locked FROM clients
```

selectを使用すると、選択したフィールドだけを使用してモデルオブジェクトが初期化されるため、注意してください。モデルオブジェクトの初期化時に指定しなかったフィールドにアクセスしようとすると、以下のメッセージが表示されます。

```bash
ActiveModel::MissingAttributeError: missing attribute: <属性名> 
```

`<属性名>`は、アクセスしようとした属性です。`id`メソッドは、この`ActiveRecord::MissingAttributeError`を発生しません。このため、関連付けを扱う場合には注意してください。関連付けが正常に動作するには`id`メソッドが必要だからです。

特定のフィールドについて、重複のない一意の値を1レコードだけ取り出したい場合、`distinct`を使用できます。

```ruby
Client.select(:name).distinct
```

上のコードを実行すると、以下のようなSQLが生成されます。

```sql
SELECT DISTINCT name FROM clients
```

一意性の制約を外すこともできます。

```ruby
query = Client.select(:name).distinct
# => 重複のない一意の名前が返される

query.distinct(false)
# => 重複の有無を問わずすべての名前が返される
```

LimitとOffset
----------------

`Model.find`で実行されるSQLに`LIMIT`を適用したい場合、リレーションで`limit`メソッドと`offset`メソッドを使用することで`LIMIT`を指定できます。

`limit`メソッドは、取り出すレコード数の上限を指定します。`offset`は、レコードを返す前にスキップするレコード数を指定します。例：

```ruby
Client.limit(5)
```

上を実行するとクライアントが最大で5つ返されます。オフセットは指定されていないので、最初の5つがテーブルから取り出されます。この時実行されるSQLは以下のような感じになります。

```sql
SELECT * FROM clients LIMIT 5
```

`offset`を追加すると以下のようになります。

```ruby
Client.limit(5).offset(30)
```

上のコードは、最初の30クライアントをスキップして31人目から最大5人のクライアントを返します。このときのSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

グループ
-----

検索メソッドで実行されるSQLに`GROUP BY`句を追加したい場合は、`group`メソッドを検索メソッドに追加できます。

たとえば、注文 (order) の作成日のコレクションを検索したい場合は、以下のようにします。

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

上のコードは、データベースで注文のある日付ごとに`Order`オブジェクトを1つ作成します。

上で実行されるSQLは以下のようなものになります。

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

Having
------

SQLでは、`GROUP BY`フィールドで条件を指定する場合に`HAVING`句を使用します。検索メソッドで`:having`オプションを使用すると、`Model.find`で生成されるSQLに`HAVING`句を追加できます。

例：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

上の例では、1日あたり1つの注文 (order) オブジェクトを返しますが、1日あたりの注文合計が$100を超える場合にのみこれを行います。

条件を上書きする
---------------------

### `unscope`

`unscope`を使用して特定の条件を取り除くことができます。例：

```ruby
Post.where('id > 10').limit(20).order('id asc').unscope(:order)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE id > 10 LIMIT 20

# `unscope`する前のオリジナルのクエリ
SELECT * FROM posts WHERE id > 10 ORDER BY id asc LIMIT 20

```

特定のwhere句で`unscope`を指定することもできます。例：

```ruby
Post.where(id: 10, trashed: false).unscope(where: :id)
# SELECT "posts".* FROM "posts" WHERE trashed = 0
```

`unscope`をリレーションに適用すると、それにマージされるすべてのリレーションにも影響します。

```ruby
Post.order('id asc').merge(Post.unscope(:order))
# SELECT "posts".* FROM "posts"
```

### `only`

`only`メソッドを使用すると、条件を上書きできます。例：

```ruby
Post.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE id > 10 ORDER BY id DESC

# `only`を使用する前のオリジナルのクエリ
SELECT "posts".* FROM "posts" WHERE (id > 10) ORDER BY id desc LIMIT 20

```

### `reorder`

`reorder`メソッドは、デフォルトのスコープの並び順を上書きします。例：

```ruby
class Post < ActiveRecord::Base
  ..
  ..
  has_many :comments, -> { order('posted_at DESC') }
end

Post.find(10).comments.reorder('name')
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY name
```

`reorder`を実行しなかった場合に実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY posted_at DESC
```

### `reverse_order`

`reverse_order`メソッドは、並び順が指定されている場合に並び順を逆にします。

```ruby
Client.where("orders_count > 10").order(:name).reverse_order
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

SQLクエリで並び順を指定する句がない場合に`reverse_order`を実行すると、主キーの逆順になります。

```ruby
Client.where("orders_count > 10").reverse_order
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

このメソッドは引数を**取りません**。

### `rewhere`

`rewhere`メソッドは、既存のwhere条件を上書きします。例：

```ruby
Post.where(trashed: true).rewhere(trashed: false)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE `trashed` = 0
```

`rewhere`の代わりに`where`を2回使用すると、以下のようになってしまいます。

```ruby
Post.where(trashed: true).where(trashed: false)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM posts WHERE `trashed` = 1 AND `trashed` = 0
```

Nullリレーション
-------------

`none`メソッドは、連鎖 (chain) 可能なリレーションを返します (レコードは返しません)。このメソッドから返されたリレーションにどのような条件を連鎖しても、常に空のリレーションが生成されます。これは、メソッドまたはスコープへの連鎖可能な応答が必要で、しかも結果を一切返したくない場合に便利です。

```ruby
Post.none # 空のリレーションを返し、クエリを生成しない。
```

```ruby
# 以下のvisible_postsメソッドはリレーションを1つ返すことが期待されている
@posts = current_user.visible_posts.where(name: params[:name])

def visible_posts
  case role
  when 'Country Manager'
    Post.where(country: country)
  when 'Reviewer'
    Post.published
  when 'Bad User'
    Post.none # => この場合[]またはnilを返し、呼び出し側のコードを中断する
  end
end
```

読み取り専用オブジェクト
----------------

Active Recordには、返されたどのオブジェクトに対しても変更を明示的に禁止する`readonly`メソッドがあります。読み取り専用を指定されたオブジェクトに対する変更の試みはすべて失敗し、`ActiveRecord::ReadOnlyRecord`例外が発生します。

```ruby
client = Client.readonly.first
client.visits += 1
client.save
```

上のコードでは `client`に対して明示的に`readonly`が指定されているため、 _visits_ の値を更新して `client.save`を行なうと`ActiveRecord::ReadOnlyRecord`例外が発生します。

レコードを更新できないようロックする
--------------------------

ロックは、データベースのレコードを更新する際の競合状態を避け、アトミックな (=中途半端な状態のない) 更新を行なうために有用です。

Active Recordには2とおりのロック機構があります。

* 楽観的ロック (optimistic)
* 悲観的ロック (pessimistic)

### 楽観的ロック (optimistic)

楽観的ロックでは、複数のユーザーが同じレコードを編集することを許し、データの衝突が最小限であることを仮定しています。この方法では、レコードがオープンされてから変更されたことがあるかどうかをチェックします。そのような変更が行われ、かつ更新が無視された場合、`ActiveRecord::StaleObjectError`例外が発生します。

**楽観的ロックカラム**

楽観的ロックを使用するには、テーブルに`lock_version`という名前のinteger型カラムがある必要があります。Active Recordは、レコードが更新されるたびに`lock_version`カラムの値を1ずつ増やします。更新リクエストが発生したときの`lock_version`の値がデータベース上の`lock_version`カラムの値よりも小さい場合、更新リクエストは失敗し、`ActiveRecord::StaleObjectError`エラーが発生します。例：

```ruby
c1 = Client.find(1)
c2 = Client.find(1)

c1.first_name = "Michael"
c1.save

c2.name = "should fail"
c2.save # ActiveRecord::StaleObjectErrorを発生
```

例外の発生後、この例外をレスキューすることで衝突を解決する必要があります。衝突の解決方法は、ロールバック、マージ、またはビジネスロジックに応じた解決方法のいずれかを使用してください。

`ActiveRecord::Base.lock_optimistically = false`を設定するとこの動作をオフにできます。

`ActiveRecord::Base`には、`lock_version`カラム名を上書きするための`locking_column`が用意されています。

```ruby
class Client < ActiveRecord::Base
  self.locking_column = :lock_client_column
end
```

### 悲観的ロック

悲観的ロックでは、データベースが提供するロック機構を使用します。リレーションの構築時に`lock`を使用すると、選択した行に対する排他的ロックを取得できます。`lock`を使用するリレーションは、デッドロック条件を回避するために通常トランザクションの内側にラップされます。

例：

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save
end
```

バックエンドでMySQLを使用している場合、上のセッションによって以下のSQLが生成されます。

```sql
SQL (0.2ms)   BEGIN
Item Load (0.3ms)   SELECT * FROM `items` LIMIT 1 FOR UPDATE
Item Update (0.4ms)   UPDATE `items` SET `updated_at` = '2009-02-07 18:05:56', `name` = 'Jones' WHERE `id` = 1
SQL (0.8ms)   COMMIT
```

異なる種類のロックを使用したい場合、`lock`メソッドに生のSQLを渡すこともできます。たとえば、MySQLには`LOCK IN SHARE MODE`という式があります。これはレコードのロック中にも他のクエリからの読み出しは許可するものです。この式を指定するには、単にlockオプションの引数にします。

```ruby
Item.transaction do
  i = Item.lock("LOCK IN SHARE MODE").find(1)
  i.increment!(:views)
end
```

モデルのインスタンスが既にある場合は、トランザクションを開始してその中でロックを一度に取得できます。

```ruby
item = Item.first
item.with_lock do
  # このブロックはトランザクション内で呼び出される
  # itemはロック済み
  item.increment!(:views)
end
```

テーブルを結合する
--------------

Active Recordの検索メソッドには`joins`があり、生成されたSQLで`JOIN`句を使用できます。`joins`メソッドにはさまざまな使用方法があります。

### SQLフラグメント文字列を使用する

`joins`メソッドの引数に生のSQLを指定することで`JOIN`句を指定できます。

```ruby
Client.joins('LEFT OUTER JOIN addresses ON addresses.client_id = clients.id')
```

これによって以下のSQLが生成されます。

```sql
SELECT clients.* FROM clients LEFT OUTER JOIN addresses ON addresses.client_id = clients.id
```

### 名前付き関連付けの配列/ハッシュを使用する

WARNING: このメソッドは`INNER JOIN`でしか使用できません。

Active Recordでは、`joins`メソッドを使用して関連付けで`JOIN`句を指定する際に、モデルで定義された[関連付け](association_basics.html)の名前をショートカットとして使用できます。

たとえば、以下の`Category`、`Post`、`Comment`、`Guest`、`Tag`モデルについて考えてみましょう。

```ruby
class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ActiveRecord::Base
  belongs_to :post
  has_one :guest
end

class Guest < ActiveRecord::Base
  belongs_to :comment
end

class Tag < ActiveRecord::Base
  belongs_to :post
end
```

以下のすべてにおいて、`INNER JOIN`を使用した結合クエリが期待どおりに生成されています。

#### 単一関連付けを結合する

```ruby
Category.joins(:posts)
```

上によって以下が生成されます。

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
```

上のSQLを日本語で書くと「投稿 (post) のあるすべてのカテゴリーを含む、Categoryオブジェクトを1つ返す」となります。なお、同じカテゴリーに複数の投稿がある場合、カテゴリーが重複します。重複のない一意のカテゴリーが必要な場合は、`Category.joins(:posts).uniq`を使用できます。

#### 複数の関連付けを結合する

```ruby
Post.joins(:category, :comments)
```

上によって以下が生成されます。

```sql
SELECT posts.* FROM posts
  INNER JOIN categories ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
```

上のSQLを日本語で書くと、「カテゴリーが1つあり、かつコメントが少なくとも1つある、すべての投稿を返す」となります。こちらも、コメントが複数ある投稿は複数回表示されます。

#### ネストした関連付けを結合する (単一レベル)

```ruby
Post.joins(comments: :guest)
```

上によって以下が生成されます。

```sql
SELECT posts.* FROM posts
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

上のSQLを日本語で書くと、「ゲストによるコメントが1つある投稿をすべて返す」となります。

#### ネストした関連付けを結合する (複数レベル)

```ruby
Category.joins(posts: [{ comments: :guest }, :tags])
```

上によって以下が生成されます。

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.post_id = posts.id
```

### 結合されたテーブルで条件を指定する

標準の[配列](#配列で表された条件)および[文字列](#文字列だけで表された条件)条件を使用して、結合テーブルに条件を指定することができます。[ハッシュ条件](#ハッシュを使用した条件) の場合、結合テーブルで条件を指定する場合に特殊な構文を使用します。

```ruby
time_range = (Time.now.midnight - 1.day).Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

さらに読みやすい別の方法として、ハッシュ条件をネストさせる方法があります。

```ruby
time_range = (Time.now.midnight - 1.day).Time.now.midnight
Client.joins(:orders).where(orders: { created_at: time_range })
```

このコードでは、昨日作成された注文 (order) を持つすべてのクライアントを検索します。ここでもSQLの`BETWEEN`式を使用しています。

関連付けを一括読み込みする
--------------------------

一括読み込み (eager loading) とは、`Model.find`によって返されるオブジェクトに関連付けられたレコードを読み込むためのメカニズムであり、できるだけクエリの使用回数を減らすようにします。

**N + 1クエリ問題**

以下のコードについて考えてみましょう。クライアントを10人検索して郵便番号を表示します。

```ruby
clients = Client.limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

このコードは一見何の問題もないように見えます。しかし本当の問題は、実行されたクエリの回数が無駄に多いことなのです。上のコードでは、最初にクライアントを10人検索するのにクエリを1回発行し、次にそこから住所を取り出すのにクエリを10回発行しますので、合計で **11** 回のクエリが発行されます。

**N + 1クエリ問題を解決する**

Active Recordは、読み込まれるすべての関連付けを事前に指定することができます。これは、`Model.find`呼び出しで`includes`を指定することで実現できます。`includes`を指定すると、Active Recordは指定されたすべての関連付けが最小限のクエリ回数で読み込まれるようにしてくれます。

上の例で言うと、`Client.limit(10)`というコードを書き直して、住所が一括で読み込まれるようにします。

```ruby
clients = Client.includes(:address).limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

最初の例では **11** 回もクエリが実行されましたが、今度の例ではわずか **2** 回にまで減りました。

```sql
SELECT * FROM clients LIMIT 10
SELECT addresses.* FROM addresses
  WHERE (addresses.client_id IN (1,2,3,4,5,6,7,8,9,10))
```

### 複数の関連付けを一括で読み込む

Active Recordは、1つの`Model.find`呼び出しで関連付けをいくつでも一括読み込みすることができます。これを行なうには、`includes`メソッドで配列、ハッシュ、または、配列やハッシュのネストしたハッシュを使用します。

#### 複数の関連付けの配列

```ruby
Post.includes(:category, :comments)
```

上のコードは、投稿と、それに関連付けられたカテゴリとコメントをすべて読み込みます。

#### ネストした関連付けハッシュ

```ruby
Category.includes(posts: [{ comments: :guest }, :tags]).find(1)
```

上のコードは、id=1のカテゴリを検索し、関連付けられたすべての投稿およびそのタグとコメント、およびすべてのコメントのゲスト関連付けを一括読み込みします。

### 関連付けの一括読み込みで条件を指定する

Active Recordでは、`joins`のように事前読み込みされた関連付けに対して条件を指定することができますが、[joins](#テーブルを結合する) という方法を使用することをお勧めします。

しかし、このようにせざるを得ない場合は、`where`を通常どおりに使用することができます。

```ruby
Post.includes(:comments).where("comments.visible" => true)
```

このコードは、`LEFT OUTER JOIN`を含むクエリを1つ生成します。`joins`メソッドを使用していたら、代りに`INNER JOIN`を使用するクエリが生成されていたでしょう。

```ruby
  SELECT "posts"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "posts" LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id" WHERE (comments.visible = 1)
```

`where`条件がない場合は、通常のクエリが2セット生成されます。

この`includes`クエリの場合、どの投稿にもコメントがついていないで、やはりすべての投稿が読み込まれるでしょう。`joins` (INNER JOIN) を使用する場合、結合条件は必ずマッチ **しなければならず** 、それ以外の場合にはレコードは返されません。

スコープ
------

スコープを設定することで、関連オブジェクトやモデルへのメソッド呼び出しとして参照される、よく使用されるクエリを指定することができます。スコープでは、`where`、`joins`、`includes`など、これまでに登場したすべてのメソッドを使用できます。どのスコープメソッドも、常に`ActiveRecord::Relation`オブジェクトを返します。このオブジェクトに対して、別のスコープを含む他のメソッド呼び出しを行なうこともできます。

単純なスコープを設定するには、クラスの内部で`scope`メソッドを使用し、スコープが呼び出されたときに実行して欲しいクエリをそこで渡します。

```ruby
class Post < ActiveRecord::Base
  scope :published, -> { where(published: true) }
end
```

以下でもわかるように、スコープでのメソッドの設定は、クラスメソッドの定義と完全に同じ (というよりクラスメソッドの定義そのもの) です。どちらの形式を使用するかは好みの問題です。

```ruby
class Post < ActiveRecord::Base
  def self.published
    where(published: true)
  end
end
```

スコープをスコープ内で連鎖 (chain) させることもできます。

```ruby
class Post < ActiveRecord::Base
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

この`published`スコープを呼び出すには、クラスでこのスコープを呼び出します。

```ruby
Post.published # => [published posts]
```

または、`Post`オブジェクトからなる関連付けでこのスコープを呼び出します。

```ruby
category = Category.first
category.posts.published # => [published posts belonging to this category]
```

### 引数を渡す

スコープには引数を渡すことができます。

```ruby
class Post < ActiveRecord::Base
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

引数付きスコープの呼び出しは、クラスメソッドの呼び出しと同様の方法で行います。

```ruby
Post.created_before(Time.zone.now)
```

しかし、このスコープでできる機能は、クラスメソッドでできる機能と重複しています。

```ruby
class Post < ActiveRecord::Base
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

スコープで引数を使用するのであれば、クラスメソッドとして定義する方が推奨されます。クラスメソッドにした場合でも、関連オブジェクトからアクセス可能です。

```ruby
category.posts.created_before(time)
```

### スコープのマージ

`where`句と同様、`AND`条件を使用してスコープをマージできます。

```ruby
class User < ActiveRecord::Base
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

`scope`と`where`条件を混用してマッチさせることができます。その結果生成される最終的なSQLには、すべての条件が`AND`で結合されて使用されます。

```ruby
User.active.where(state: 'finished')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

スコープよりも最後のwhere句をどうしても優先したい場合は、`Relation#merge`を使用できます。

```ruby
User.active.merge(User.inactive)
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

ここで一つ注意すべき点は、`default_scope`は
`scope`や`where`条件よりも前に置かれるという点です。

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'inactive'
```

上の例でわかるように、`default_scope`が`scope`と`where`よりも前の場所にマージされています。


### デフォルトスコープを適用する

あるスコープをモデルのすべてのクエリに適用したい場合、モデル自身の内部で`default_scope`メソッドを使用することができます。

```ruby
class Client < ActiveRecord::Base
  default_scope { where("removed_at IS NULL") }
end
```

このモデルに対してクエリが実行されたときのSQLクエリは以下のような感じになります。

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

デフォルトスコープの条件が複雑になるのであれば、スコープをクラスメソッドとして定義するのもひとつの手です。

```ruby
class Client < ActiveRecord::Base
  def self.default_scope
    # ActiveRecord::Relationを返すようにする
  end
end
```

### すべてのスコープを削除する

何らかの理由でスコープをすべて解除したい場合は`unscoped`メソッドを使用できます。このメソッドは、モデルで`default_scope`が指定されているが、それを適用したくないクエリがある場合に特に便利です。

```ruby
Client.unscoped.load
```

このメソッドはスコープをすべて解除し、テーブルに対して通常の (スコープなしの) クエリを実行するようにします。

`unscoped`に`scope`を連鎖させることはできませんので注意が必要です。このような場合は、`unscoped`のブロック形式を使用することが推奨されます。

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

動的ファインダ
---------------

Active Recordは、テーブルに定義されたすべてのフィールド (属性とも呼ばれます) に対して自動的にファインダメソッドを提供します。たとえば、`Client`モデルに`first_name`というフィールドがあると、`find_by_first_name`というメソッドがActive Recordによって自動的に作成されます。`Client`モデルに`locked`というフィールドがあれば、`find_by_locked`というメソッドを使用できます。

この動的ファインダメソッドの末尾に`Client.find_by_name!("Ryan")`のように感嘆符 (`!`) を追加すると、該当するレコードがない場合に`ActiveRecord::RecordNotFound`エラーが発生します。

nameとlockedの両方を検索したいのであれば、2つのフィールド名をandでつなぐだけでメソッドを利用できます。たとえば、`Client.find_by_first_name_and_locked("Ryan", true)`のように書くことができます。

新しいオブジェクトを検索またはビルドする
--------------------------

NOTE: Rails 4.0では一部の動的ファインダメソッドが非推奨に指定されました。これらはRails 4.1で削除される予定です。最良の方法は、Active Recordのスコープを代りに使用することです。非推奨になったファインダgemは https://github.com/rails/activerecord-deprecated_finders にあります。

レコードを検索し、レコードがなければ作成する、というのはよくある一連の流れです。`find_or_create_by`および`find_or_create_by!`メソッドを使用すればこれらを一度に行なうことができます。

### `find_or_create_by`

`find_or_create_by`メソッドは、指定された属性を持つレコードが存在するかどうかをチェックします。レコードがない場合は`create`が呼び出されます。以下の例を見てみましょう。

'Andy'という名前のクライアントを探し、いなければ作成したいとします。これを行なうには以下を実行します。

```ruby
Client.find_or_create_by(first_name: 'Andy')
# => #<Client id: 1, first_name: "Andy", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">
```

このメソッドによって生成されるSQLは以下のようなものになります。

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO clients (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by`は、既にあるレコードか新しいレコードのいずれかを返します。上の例の場合、Andyという名前のクライアントがなかったのでレコードを作成して返しました。

`create`などと同様、検証にパスするかどうかによって、新しいレコードがデータベースに保存されていないことがあるかもしれません。

今度は、新しいレコードを作成するときに'locked'属性を`false`に設定したいが、それをクエリに含めたくないとします。そこで、"Andy"という名前のクライアントを検索するか、その名前のクライアントがいない場合は"Andy"というクライアントを作成してロックを外すことにします。

これは2とおりの方法で実装できます。1つ目は`create_with`を使用する方法です。

```ruby
Client.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

2つ目はブロックを使用する方法です。

```ruby
Client.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

このブロックは、クライアントが作成されるときにだけ実行されます。このコードを再度実行すると、このブロックは実行されません。

### `find_or_create_by!`

`find_or_create_by!`を使用すると、新しいレコードが無効な場合に例外を発生することもできます。このガイドでは検証については解説の対象ではありませんが、

```ruby
validates :orders_count, presence: true
```

上を`Client`モデルに追加したとします。`orders_count`を指定しないで新しい`Client`モデルを作成しようとすると、レコードは無効になって例外が発生します。

```ruby
Client.find_or_create_by!(first_name: 'Andy')
# => ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

### `find_or_initialize_by`

`find_or_initialize_by`メソッドは`find_or_create_by`と同様に動作しますが、`create`の代りに`new`を呼ぶ点が異なります。つまり、モデルの新しいインスタンスは作成されますが、その時点ではデータベースに保存されていません。`find_or_create_by`の例を少し変えて説明を続けます。今度は'Nick'という名前のクライアントが必要だとします。

```ruby
nick = Client.find_or_initialize_by(first_name: 'Nick')
# => <Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

nick.persisted?
# => false

nick.new_record?
# => true
```

オブジェクトはまだデータベースに保存されていないため、生成されるSQLは以下のようなものになります。

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Nick') LIMIT 1
```

このオブジェクトをデータベースに保存したい場合は、単に`save`を呼び出します。

```ruby
nick.save
# => true
```

SQLで検索する
--------------

独自のSQLを使用してレコードを検索したい場合、`find_by_sql`メソッドを使用できます。この`find_by_sql`メソッドは、オブジェクトの配列を1つ返します。クエリがレコードを1つしか返さなかった場合にも配列が返されますのでご注意ください。たとえば、以下のクエリを実行したとします。

```ruby
Client.find_by_sql("SELECT * FROM clients
  INNER JOIN orders ON clients.id = orders.client_id
  ORDER BY clients.created_at desc")
```

`find_by_sql`は、カスタマイズしたデータベース呼び出しを簡単な方法で提供し、インスタンス化されたオブジェクトを返します。

### `select_all`

`find_by_sql`は`connection#select_all`と深い関係があります。`select_all`は`find_by_sql`と同様、カスタムSQLを使用してデータベースからオブジェクトを取り出しますが、取り出したオブジェクトのインスタンス化を行わない点が異なります。代りに、ハッシュの配列を返します。1つのハッシュが1レコードを表します。

```ruby
Client.connection.select_all("SELECT * FROM clients WHERE id = '1'")
```

### `pluck`

`pluck`は、1つのモデルで使用されているテーブルから1つまたは複数のカラムをクエリするのに使用できます。引数としてカラム名のリストを取り、指定したカラムの値の配列を、対応するデータ型で返します。

```ruby
Client.where(active: true).pluck(:id)
# SELECT id FROM clients WHERE active = 1
# => [1, 2, 3]

Client.distinct.pluck(:role)
# SELECT DISTINCT role FROM clients
# => ['admin', 'member', 'guest']

Client.pluck(:id, :name)
# SELECT clients.id, clients.name FROM clients
# => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]
```

`pluck`を使用すると、以下のようなコードをシンプルなものに置き換えることができます。

```ruby
Client.select(:id).map { |c| c.id }
  # または
Client.select(:id).map(&:id)
  # または
Client.select(:id, :name).map { |c| [c.id, c.name] }
```

上は以下に置き換えられます。

```ruby
Client.pluck(:id)
  # または
Client.pluck(:id, :name)
```

`select`と異なり、`pluck`はデータベースから受け取った結果を直接Rubyの配列に変換してくれます。そのための`ActiveRecord`オブジェクトを事前に構成しておく必要はありません。従って、このメソッドは大規模なクエリや使用頻度の高いクエリで使用するとパフォーマンスが向上します。ただし、オーバーライドを行なうモデルメソッドは使用できません。例：

```ruby
class Client < ActiveRecord::Base
  def name
    "私は#{super}"
  end
end

Client.select(:name).map &:name
# => ["私はDavid", "私はJeremy", "私はJose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

さらに`pluck`は、`select`などの`Relation`スコープと異なり、クエリを直接トリガするので、その後ろに他のスコープを連鎖することはできません。ただし、構成済みのスコープを`pluck`の前に置くことはできます。

```ruby
Client.pluck(:name).limit(1)
# => NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

Client.limit(1).pluck(:name)
# => ["David"]
```

### `ids`

`ids`は、テーブルの主キーを使用するリレーションのIDをすべて取り出すのに使用できます。

```ruby
Person.ids
# SELECT id FROM people
```

```ruby
class Person < ActiveRecord::Base
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

オブジェクトの存在チェック
--------------------

オブジェクトが存在するかどうかは、`exists?`メソッドでチェックできます。
このメソッドは、`find`と同様のクエリを使用してデータベースにクエリを送信しますが、オブジェクトのコレクションの代わりに`true`または`false`を返します。

```ruby
Client.exists?(1)
```

`exists?`は複数の値を引数に取ることができます。ただし、それらの値のうち1つでも存在していれば、他の値が存在していなくても`true`を返します。

```ruby
Client.exists?(id: [1,2,3])
  # または
Client.exists?(name: ['John', 'Sergei'])
```

`exists?`メソッドは、モデルやリレーションに対して引数なしで呼び出すことすらできます。

```ruby
Client.where(first_name: 'Ryan').exists?
```

上の例では、`first_name`が'Ryan'のクライアントが1人でもいれば`true`を返し、それ以外の場合は`false`を返します。

```ruby
Client.exists?
```

上の例では、`Client`テーブルが空なら`false`を返し、それ以外の場合は`true`を返します。

モデルやリレーションでの存在チェックには`any?`や`many?`も使用できます。

```ruby
# via a model
Post.any?
Post.many?

# 名前付きスコープを経由
Post.recent.any?
Post.recent.many?

# リレーション経由
Post.where(published: true).any?
Post.where(published: true).many?

# 関連付け経由
Post.first.categories.any?
Post.first.categories.many?
```

計算
------------

このセクションでは冒頭で`count`メソッドを例に取って説明していますが、ここで説明されているオプションは以下のすべてのサブセクションにも該当します。

あらゆる計算メソッドは、モデルに対して直接実行されます。All calculation methods work directly on a model:

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

リレーションに対しても直接実行されます。

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

この他にも、リレーションに対してさまざまなファインダメソッドを使用して複雑な計算を行なうことができます。

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: { status: 'received' }).count
```

上のコードは以下を実行します。

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = client.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

### 個数を数える

モデルのテーブルに含まれるレコードの個数を数えるには`Client.count`を使用できます。返されるのはレコードの個数です。特定の年齢のクライアントの数を数えるのであれば、`Client.count(:age)`とします。

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

### 平均

テーブルに含まれる特定の数値の平均を得るには、そのテーブルを持つクラスに対して`average`メソッドを呼び出します。このメソッド呼び出しは以下のようなものになります。

```ruby
Client.average("orders_count")
```

返される値は、そのフィールドの平均値です。通常3.14159265のような浮動小数点になります。

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

### 最小値

テーブルに含まれるフィールドの最小値を得るには、そのテーブルを持つクラスに対して`minimum`メソッドを呼び出します。このメソッド呼び出しは以下のようなものになります。

```ruby
Client.minimum("age")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

### 最大値

テーブルに含まれるフィールドの最大値を得るには、そのテーブルを持つクラスに対して`maximum`メソッドを呼び出します。このメソッド呼び出しは以下のようなものになります。

```ruby
Client.maximum("age")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

### 合計

テーブルに含まれるフィールドのすべてのレコードにおける合計を得るには、そのテーブルを持つクラスに対して`sum`メソッドを呼び出します。このメソッド呼び出しは以下のようなものになります。

```ruby
Client.sum("orders_count")
```

オプションについては、1つ上の[計算](#計算)セクションを参照してください。

EXPLAINを実行する
---------------

リレーションによってトリガされるクエリでEXPLAINを実行することができます。たとえば、以下のコードでは、

```ruby
User.where(id: 1).joins(:posts).explain
```

以下のような結果が生成されます。

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `posts` ON `posts`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |             |
|  1 | SIMPLE      | posts | ALL   | NULL          | NULL    | NULL    | NULL  |    1 | Using where |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
2 rows in set (0.00 sec)
```

上の結果はMySQLの場合です。

Active Recordは、データベースのシェルを模した整形済みのデータを出力します。PostgreSQLアダプタで同じクエリを実行すると、今度は以下のような結果が得られます。

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (posts.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on posts  (cost=0.00..28.88 rows=8 width=4)
         Filter: (posts.user_id = 1)
(6 rows)
```

一括読み込みを使用していると、内部で複数のクエリがトリガされることがあり、一部のクエリではその前の結果を必要とすることがあります。このため、`explain`はこのクエリを実際に実行し、それからクエリプランを要求します。たとえば、以下のコードでは、

```ruby
User.where(id: 1).includes(:posts).explain
```

以下の結果を生成します。

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
1 row in set (0.00 sec)

EXPLAIN for: SELECT `posts`.* FROM `posts`  WHERE `posts`.`user_id` IN (1)
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | posts | ALL  | NULL          | NULL | NULL    | NULL |    1 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0.00 sec)
```

上の結果はMySQLの場合です。

### EXPLAINの出力結果を解釈する

EXPLAINの出力を解釈することは、本ガイドの範疇を超えます。以下の情報を参考にしてください。

* SQLite3: [EXPLAIN QUERY PLAN](http://www.sqlite.org/eqp.html) (英語)

* MySQL: [EXPLAIN Output Format](http://dev.mysql.com/doc/refman/5.6/en/explain-output.html) (英語)

* PostgreSQL: [EXPLAINの利用](https://www.postgresql.jp/document/9.3/html/using-explain.html)