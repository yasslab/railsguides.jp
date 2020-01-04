**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Record クエリインターフェイス
=============================

このガイドでは、Active Recordを使用してデータベースからデータを取り出すためのさまざまな方法について解説します。

このガイドの内容:

* 多くのメソッドや条件を駆使してレコードを検索する
* 検索されたレコードのソート順、取り出したい属性、グループ化の有無などを指定する
* 一括読み込み (eager loading) を使用して、データ取り出しに必要なクエリの実行回数を減らす
* 動的検索メソッドを使用する
* 複数のActive Recordメソッドをメソッドチェインで同時に利用する
* 特定のレコードが存在するかどうかをチェックする
* Active Recordモデルでさまざまな計算を行う
* リレーションでEXPLAINを実行する

--------------------------------------------------------------------------------

生のSQLを使用してデータベースのレコードを検索することに慣れきった人がRailsに出会うと、Railsでは同じ操作をずっと洗練された方法で実現できることに気付くでしょう。Active Recordを使用することで、SQLを直に実行する必要はほぼなくなります。

本ガイドのコード例では、基本的に以下のモデルを使用します。

TIP: 特に記さない限り、モデル中の`id`は主キーを表します。

```ruby
class Client < ApplicationRecord
  has_one :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ApplicationRecord
  belongs_to :client
end
```

```ruby
class Order < ApplicationRecord
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ApplicationRecord
  has_and_belongs_to_many :clients
end
```

Active Recordは、ユーザーに代わってデータベースにクエリを発行します。発行されるクエリは多くのデータベースシステム (MySQL、MariaDB、PostgreSQL、SQLiteなど) と互換性があります。Active Recordを使用していれば、利用しているデータベースシステムの種類にかかわらず、同じ表記を使用できます。

データベースからオブジェクトを取り出す
------------------------------------

Active Recordでは、データベースからオブジェクトを取り出すための検索メソッドを多数用意しています。これらの検索メソッドを使用することで、生のSQLを書くことなく、データベースへの特定のクエリを実行するための引数を渡すことができます。

以下のメソッドが用意されています。

* `annotate`
* `find`
* `create_with`
* `distinct`
* `eager_load`
* `extending`
* `extract_associated`
* `from`
* `group`
* `having`
* `includes`
* `joins`
* `left_outer_joins`
* `limit`
* `lock`
* `none`
* `offset`
* `optimizer_hints`
* `order`
* `preload`
* `readonly`
* `references`
* `reorder`
* `reselect`
* `reverse_order`
* `select`
* `where`

検索メソッドは`where`や`group`といったコレクションを返したり、`ActiveRecord::Relation`のインスタンスを返します。また、`find`や`first`などの１つのエンティティを検索するメソッドの場合、そのモデルのインスタンスを返します。

`Model.find(options)`という操作を要約すると以下のようになります。

* 与えられたオプションを同等のSQLクエリに変換します。
* SQLクエリを発行し、該当する結果をデータベースから取り出します。
* 得られた結果を行ごとに同等のRubyオブジェクトとしてインスタンス化します。
* 指定されていれば、`after_find`を実行し、続いて`after_initialize`コールバックを実行します。

### 単一のオブジェクトを取り出す

Active Recordには、単一のオブジェクトを取り出すためのさまざま方法が用意されています。

#### `find`

`find`メソッドを使用すると、与えられたどのオプションにもマッチする _主キー_ に対応するオブジェクトを取り出すことができます。以下に例を示します。

```ruby
# 主キー（id）が10のクライアントを検索
clients = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

`find`メソッドでマッチするレコードが見つからない場合、`ActiveRecord::RecordNotFound`例外が発生します。

このメソッドを使用して、複数のオブジェクトへのクエリを作成することもできます。これを行うには、`find`メソッドの呼び出し時に主キーの配列を渡します。これにより、与えられた _主キー_ にマッチするレコードをすべて含む配列が返されます。以下に例を示します。

```ruby
# 主キー（id）が1と10のクライアントを検索
clients = Client.find([1, 10]) # Client.find(1, 10)も可
# => [
# <Client id: 1, first_name: "Lifo">,
# <Client id: 10, first_name: "Ryan">
# ]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: `find`メソッドで与えられた主キーの中に、どのレコードにもマッチしない主キーが**1つでも**あると、`ActiveRecord::RecordNotFound`例外が発生します。

#### `take`

`take`メソッドはレコードを1つ取り出します。どのレコードが取り出されるかは指定されません。以下に例を示します。

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 1
```

`Model.take`は、モデルにレコードが1つもない場合に`nil`を返します。このとき例外は発生しません。

`take`メソッドで返すレコードの最大数を数値の引数で指定することもできます。例:

```ruby
clients = Client.take(2)
# => [
#   #<Client id: 1, first_name: "Lifo">,
#   #<Client id: 220, first_name: "Sara">
# ]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients LIMIT 2
```

`take!`メソッドの動作は、`take`メソッドとまったく同じです。ただし、`take!`メソッドでは、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点だけが異なります。

TIP: このメソッドで取り出されるレコードは、使用するデータベースエンジンによっても異なることがあります。

#### `first`

`first`メソッドは、デフォルトでは主キー順の最初のレコードを取り出します。以下に例を示します。

```ruby
clients = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

`first`メソッドは、モデルにレコードが1つもない場合に`nil`を返します。このとき例外は発生しません。

[デフォルトスコープ](active_record_querying.html#デフォルトスコープを適用する)が順序に関するメソッドを含んでいる場合、`first`メソッドはその順序に従って最初のレコードを返します。

`first`メソッドで返すレコードの最大数を数値の引数で指定することもできます。例:

```ruby
clients = Client.first(3)
# => [
#   #<Client id: 1, first_name: "Lifo">,
#   #<Client id: 2, first_name: "Fifo">,
#   #<Client id: 3, first_name: "Filo">
# ]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 3
```

`order`を使って順序を変更したコレクションの場合、`first`メソッドは`order`で指定された属性に従って最初のレコードを返します。

```ruby
client = Client.order(:first_name).first
# => #<Client id: 2, first_name: "Fifo">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.first_name ASC LIMIT 1
```

`first!`メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`first`メソッドとまったく同じです。

#### `last`

`last`メソッドは、(デフォルトでは) 主キーの順序に従って最後のレコードを返します。 以下に例を示します。

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

lastメソッドは、モデルにレコードが1つもない場合に`nil`を返します。このとき例外は発生しません。

[デフォルトスコープ](active_record_querying.html#デフォルトスコープを適用する)が順序に関するメソッドを含んでいる場合、`last`メソッドはその順序に従って最後のレコードを返します。

`last`メソッドで返すレコードの最大数を数値の引数で指定することもできます。例:

```ruby
clients = Client.last(3)
# => [
#   #<Client id: 219, first_name: "James">,
#   #<Client id: 220, first_name: "Sara">,
#   #<Client id: 221, first_name: "Russel">
# ]
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 3
```

`order`を使って順序を変更したコレクションの場合、`last`メソッドは`order`で指定された属性に従って最後のレコードを返します。

```ruby
client = Client.order(:first_name).last
# => #<Client id: 220, first_name: "Sara">
```

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients ORDER BY clients.first_name DESC LIMIT 1
```

`last!`メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`last`メソッドとまったく同じです。

#### `find_by`

`find_by`メソッドは、与えられた条件にマッチするレコードのうち最初のレコードだけを返します。以下に例を示します。

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

これと同等のSQLは以下のようになります。

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Lifo') LIMIT 1
```

`find_by!`メソッドの動作は、マッチするレコードが見つからない場合に`ActiveRecord::RecordNotFound`例外が発生する点を除いて、`find_by`メソッドとまったく同じです。以下に例を示します。

```ruby
Client.find_by! first_name: 'does not exist'
# => ActiveRecord::RecordNotFound
```

上の文は以下のように書くこともできます。

```ruby
Client.where(first_name: 'does not exist').take!
```

### 複数のオブジェクトをバッチで取り出す

多数のレコードに対して反復処理を行いたいことがあります。たとえば、多くのユーザーにニュースレターを送信したい、データをエクスポートしたいなどです。

このような処理をそのまま実装すると以下のようになるでしょう。

```ruby
# このコードはテーブルが大きい場合、メモリを大量に消費する可能性あり
User.all.each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

しかし上のような処理は、テーブルのサイズが大きくなるにつれて非現実的になります。`User.all.each`は、Active Recordに対して _テーブル全体_ を一度に取り出し、しかも1行ごとにオブジェクトを生成し、その巨大なモデルオブジェクトの配列をメモリに配置するからです。もし莫大な数のレコードに対してこのようなコードをまともに実行すると、コレクション全体のサイズがメモリ容量を上回ってしまうことでしょう。

Railsでは、メモリを圧迫しないサイズにバッチを分割して処理するための方法を2とおり提供しています。1つ目は`find_each`メソッドを使用する方法です。これは、レコードのバッチを1つ取り出し、次に _各_ レコードを1つのモデルとして個別にブロックにyieldします。2つ目の方法は`find_in_batches`メソッドを使用する方法です。レコードのバッチを1つ取り出し、次に _バッチ全体_ をモデルの配列としてブロックにyieldします。

TIP: `find_each`メソッドと`find_in_batches`メソッドは、一度にメモリに読み込めないような大量のレコードに対するバッチ処理のためのものです。数千のレコードに対して単にループ処理を行なうのであれば通常の検索メソッドで十分です。

#### `find_each`

`find_each`メソッドは、複数のレコードを一括で取り出し、続いて _各_ レコードを1つのブロックにyieldします。以下の例では、`find_each`でバッチから1000件のレコードを一括で取り出し、各レコードをブロックにyieldします。

```ruby
User.find_each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

この処理は、必要に応じてさらにレコードのまとまりをフェッチし、すべてのレコードが処理されるまで繰り返されます。

`find_each`メソッドは上述のようにモデルのクラスに対して機能します。対象がリレーションの場合も同様です。

```ruby
User.where(weekly_subscriber: true).find_each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

ただしこれは順序指定がない場合に限ります。`find_each`メソッドでイテレートするには内部で順序を強制する必要があるためです。

レシーバー側に順序制約がある場合、`config.active_record.error_on_ignored_order`フラグの状態によって振る舞いが変わります。たとえば`true`の場合は`ArgumentError`が発生し、falseの場合は順序が無視され警告が発生します。デフォルトは`false`です。このフラグを上書きしたい場合は`:error_on_ignore`オプション（後述）を使います。

##### `find_each`のオプション

**`:batch_size`**

`:batch_size`オプションは、(ブロックに個別に渡される前に) 1回のバッチで取り出すレコード数を指定します。たとえば、1回に5000件ずつ処理したい場合は以下のように指定します。

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

**`:start`**

デフォルトでは、レコードは主キーの昇順に取り出されます。主キーは整数でなければなりません。並び順冒頭のIDが不要な場合、`:start`オプションを使用してシーケンスの開始IDを指定します。これは、たとえば中断したバッチ処理を再開する場合などに便利です (最後に実行された処理のIDがチェックポイントとして保存済みであることが前提です)。

たとえば主キーが2000番以降のユーザーに対してニュースレターを配信する場合は、以下のようになります。

```ruby
User.find_each(start: 2000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

**`:finish`**

`:start`オプションと同様に、シーケンスの末尾のIDを指定したい場合は、`:finish`オプションで末尾のIDを設定できます。 `:start`と`:finish`でレコードのサブセットを指定し、その中でバッチプロセスを走らせたい時に便利です。

たとえば主キーが2000番〜10000番のユーザーに対してニュースレターを配信したい場合は、以下のようになります。

```ruby
User.find_each(start: 2000, finish: 10000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

他にも、同じ処理キューを複数の作業者で手分けする場合が考えられます。たとえば各ワーカーに10000レコードずつ処理して欲しい場合も、`:start`と`:finish`オプションにそれぞれ適切な値を設定することで実現できます。

**`:error_on_ignore`**

リレーション内に順序制約があれば例外を発生させたい場合は、このオプションを使ってアプリケーションの設定を上書きしてください。

#### `find_in_batches`

`find_in_batches`メソッドは、レコードをバッチで取り出すという点で`find_each`と似ています。違うのは、`find_in_batches`は _バッチ_ を個別にではなくモデルの配列としてブロックにyieldするという点です。以下の例では、与えられたブロックに対して一度に最大1000までの納品書 (invoice) の配列をyieldしています。最後のブロックには残りの納品書が含まれます。

```ruby
# 1回あたりadd_invoicesに納品書1000通の配列を渡す
Invoice.find_in_batches do |invoices|
  export.add_invoices(invoices)
end
```

`find_in_batches`メソッドは上述のようにモデルのクラスに対して機能します。対象がリレーションの場合も同様です。

```ruby
Invoice.pending.find_in_batches do |invoices|
  pending_invoices_export.add_invoices(invoices)
end
```

ただしこれは順序指定がない場合に限ります。`find_in_batches`メソッドでイテレートするには内部で順序を強制する必要があるためです。

##### `find_in_batches`のオプション

`find_in_batches`メソッドでは、`find_each`メソッドと同様のオプションを使えます。

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

Active Recordは最初の引数を、文字列で表された条件として受け取ります。その後に続く引数は、文字列内にある疑問符 `?` と置き換えられます。

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

TIP: SQLインジェクションの詳細については[Ruby on Railsセキュリティガイド](security.html#sqlインジェクション)を参照してください。

#### プレースホルダを使用した条件

疑問符`(?)`をパラメータで置き換えるスタイルと同様、条件中でキー/値のハッシュを渡すことができます。ここで渡されたハッシュは、条件中の対応するキー/値の部分に置き換えられます。

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

これは以下のようなSQLを生成します。

```sql
SELECT * FROM clients WHERE (clients.locked = 1)
```

フィールド名は文字列形式にすることもできます。

```ruby
Client.where('locked' => true)
```

belongs_toリレーションシップの場合、Active Recordオブジェクトが値として使用されていれば、モデルを指定する時に関連付けキーを使用できます。この方法はポリモーフィックリレーションシップでも同様に使用できます。

```ruby
Article.where(author: author)
Author.joins(:articles).where(articles: { author: author })
```

#### 範囲条件

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

上の例では、昨日作成されたすべてのクライアントを検索します。内部ではSQLの`BETWEEN`文が使用されます。

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

[配列で表された条件](#配列で表された条件)では、さらに簡潔な文例をご紹介しています。

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
Client.where.not(locked: true)
```

言い換えれば、このクエリは`where`に引数を付けずに呼び出し、直後に`where`条件に`not`を渡してチェインすることで生成されています。これは以下のようなSQLを出力します。

```sql
SELECT * FROM clients WHERE (clients.locked != 1)
```

### OR条件

２つのリレーションをまたいで`OR`条件を使いたい場合は、１つ目のリレーションで`or`メソッドを呼び出し、そのメソッドの引数に２つ目のリレーションを渡すことで実現できます。


```ruby
Client.where(locked: true).or(Client.where(orders_count: [1,3,5]))
```

```sql
SELECT * FROM clients WHERE (clients.locked = 1 OR clients.orders_count IN (1,3,5))
```

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

`order`メソッドを複数回呼び出すと、続く並び順は最初の並び順に追加されていきます。

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

WARNING: **MySQL 5.7.5**以上のバージョンで `select`や`pluck`、`ids`メソッドを使ってフィールドを選択し、かつ、選択しているリストに`order`句を使ったフィールドが含まれていないと、`order`メソッドで`ActiveRecord::StatementInvalid`例外が発生します。結果から特定のフィールドだけを取り出す方法については、次のセクションを参照してください。

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

### グループ化された項目の合計

グループ化した項目の合計をひとつのクエリで得るには、`group`の次に`count`を呼び出します。

```ruby
Order.group(:status).count
# => { 'awaiting_approval' => 7, 'paid' => 12 }
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT COUNT (*) AS count_all, status AS status
FROM "orders"
GROUP BY status
```

Having
------

SQLでは、`GROUP BY`フィールドで条件を指定する場合に`HAVING`句を使用します。検索メソッドで`:having`メソッドを使用すると、`Model.find`で生成されるSQLに`HAVING`句を追加できます。

以下に例を示します。

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

これは各orderオブジェクトの注文日と合計金額を返します。具体的には、priceが$100を超えているものが、dateごとにまとめられて返されます。

条件を上書きする
---------------------

### `unscope`

`unscope`を使用して特定の条件を取り除くことができます。以下に例を示します。

```ruby
Article.where('id > 10').limit(20).order('id asc').unscope(:order)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM articles WHERE id > 10 LIMIT 20

# `unscope`する前のオリジナルのクエリ
SELECT * FROM articles WHERE id > 10 ORDER BY id asc LIMIT 20
```

特定の`where`句で`unscope`を指定することもできます。以下に例を示します。

```ruby
Article.where(id: 10, trashed: false).unscope(where: :id)
# SELECT "articles".* FROM "articles" WHERE trashed = 0
```

`unscope`をリレーションに適用すると、それにマージされるすべてのリレーションにも影響します。

```ruby
Article.order('id asc').merge(Article.unscope(:order))
# SELECT "articles".* FROM "articles"
```

### `only`

`only`メソッドを使用すると、条件を上書きできます。以下に例を示します。

```ruby
Article.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM articles WHERE id > 10 ORDER BY id DESC

# `only`を使用する前のオリジナルのクエリ
SELECT "articles".* FROM "articles" WHERE (id > 10) ORDER BY id desc LIMIT 20

```

### `reselect`

`reselect`メソッドは既存のselect文をオーバーライドします。次に例を示します。

```ruby
Post.select(:title, :body).reselect(:created_at)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT `posts`.`created_at` FROM `posts`
```

以下は`reselect`句を使わない場合です。

```ruby
Post.select(:title, :body).select(:created_at)
```

この場合のSQL文は以下のようになります。

```sql
SELECT `posts`.`title`, `posts`.`body`, `posts`.`created_at` FROM `posts`
```

### `reorder`

`reorder`メソッドは、デフォルトのスコープの並び順を上書きします。以下に例を示します。

```ruby
class Article < ApplicationRecord
  has_many :comments, -> { order('posted_at DESC') }
end

Article.find(10).comments.reorder('name')
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM articles WHERE id = 10
SELECT * FROM comments WHERE article_id = 10 ORDER BY name
```

`reorder`句が使われていない場合、実行されるSQLは以下のようになります。

```sql
SELECT * FROM articles WHERE id = 10
SELECT * FROM comments WHERE article_id = 10 ORDER BY posted_at DESC
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

`rewhere`メソッドは、既存のwhere条件を上書きします。以下に例を示します。

```ruby
Article.where(trashed: true).rewhere(trashed: false)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM articles WHERE `trashed` = 0
```

`rewhere`の代わりに`where`を2回使用すると、結果が異なります。

```ruby
Article.where(trashed: true).where(trashed: false)
```

上で実行されるSQLは以下のようなものになります。

```sql
SELECT * FROM articles WHERE `trashed` = 1 AND `trashed` = 0
```

Nullリレーション
-------------

`none`メソッドは、チェイン (chain) 可能なリレーションを返します (レコードは返しません)。このメソッドから返されたリレーションにどのような条件をチェインさせても、常に空のリレーションが生成されます。これは、メソッドまたはスコープへのチェイン可能な応答が必要で、しかも結果を一切返したくない場合に便利です。

```ruby
Article.none # 空のリレーションを返し、クエリを生成しない。
```

```ruby
# visible_articles メソッドはリレーションを返すことが期待されている
@articles = current_user.visible_articles.where(name: params[:name])

def visible_articles
  case role
  when 'Country Manager'
    Article.where(country: country)
  when 'Reviewer'
    Article.published
  when 'Bad User'
    Article.none # => []またはnilを返すと、このコード例では呼び出し元のコードを壊してしまう
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
class Client < ApplicationRecord
  self.locking_column = :lock_client_column
end
```

### 悲観的ロック (pessimistic)

悲観的ロックでは、データベースが提供するロック機構を使用します。リレーションの構築時に`lock`を使用すると、選択した行に対する排他的ロックを取得できます。`lock`を使用するリレーションは、デッドロック条件を回避するために通常トランザクションの内側にラップされます。

以下に例を示します。

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save!
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

Active Recordは `JOIN`句のSQLを具体的に指定する２つの検索メソッドを提供しています。１つは`joins`、もう１つは`left_outer_joins`です。`joins`メソッドは`INNER JOIN`やカスタムクエリに使われ、`left_outer_joins`は `LEFT OUTER JOIN`を使ったクエリの生成に使われます。

### `joins`

`joins`メソッドには複数の使い方があります。

#### SQLフラグメント文字列を使用する

`joins`メソッドの引数に生のSQLを指定することで`JOIN`句を指定できます。

```ruby
Author.joins("INNER JOIN posts ON posts.author_id = authors.id AND posts.published = 't'")
```

これによって以下のSQLが生成されます。

```sql
SELECT authors.* FROM authors INNER JOIN posts ON posts.author_id = authors.id AND posts.published = 't'
```

#### 名前付き関連付けの配列/ハッシュを使用する

Active Recordでは、`joins`メソッドを使用して関連付けで`JOIN`句を指定する際に、モデルで定義された関連付けの名前をショートカットとして使用できます (詳細は[Active Recordの関連付け](association_basics.html)を参照)。

たとえば、以下の`Category`、`Article`、`Comment`、`Guest`、`Tag`モデルについて考えてみましょう。

```ruby
class Category < ApplicationRecord
  has_many :articles
end

class Article < ApplicationRecord
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ApplicationRecord
  belongs_to :article
  has_one :guest
end

class Guest < ApplicationRecord
  belongs_to :comment
end

class Tag < ApplicationRecord
  belongs_to :article
end
```

以下のすべてにおいて、`INNER JOIN`を使用した結合クエリが期待どおりに生成されています。

##### 単一関連付けを結合する

```ruby
Category.joins(:articles)
```

上によって以下が生成されます。

```sql
SELECT categories.* FROM categories
  INNER JOIN articles ON articles.category_id = categories.id
```

上のSQLを日本語で書くと「記事 (article) のあるすべてのカテゴリーを含む、Categoryオブジェクトを1つ返す」となります。なお、同じカテゴリーに複数の記事がある場合、カテゴリーが重複します。重複のない一意のカテゴリーが必要な場合は、`Category.joins(:articles).distinct`を使用できます。

#### 複数の関連付けを結合する

```ruby
Article.joins(:category, :comments)
```

上によって以下が生成されます。

```sql
SELECT articles.* FROM articles
  INNER JOIN categories ON articles.category_id = categories.id
  INNER JOIN comments ON comments.article_id = articles.id
```

上のSQLを日本語で書くと、「カテゴリーが1つあり、かつコメントが1つ以上ある、すべての記事を返す」となります。こちらも、コメントが複数ある記事は複数回表示されます。

##### ネストした関連付けを結合する (単一レベル)

```ruby
Article.joins(comments: :guest)
```

上によって以下が生成されます。

```sql
SELECT articles.* FROM articles
  INNER JOIN comments ON comments.article_id = articles.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

上のSQLを日本語で書くと、「ゲストによるコメントが1つある記事をすべて返す」となります。

##### ネストした関連付けを結合する (複数レベル)

```ruby
Category.joins(articles: [{ comments: :guest }, :tags])
```

上によって以下が生成されます。

```sql
SELECT categories.* FROM categories
  INNER JOIN articles ON articles.category_id = categories.id
  INNER JOIN comments ON comments.article_id = articles.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.article_id = articles.id
```

上のSQLを日本語で書くと「ゲストによってコメントされた記事 (articles) の中で、タグを含んでいるCategoryオブジェクトをすべて返す」となります。

#### 結合されたテーブルで条件を指定する

標準の[配列](#配列で表された条件)および[文字列](#文字列だけで表された条件)条件を使用して、結合テーブルに条件を指定することができます。[ハッシュ条件](#ハッシュを使用した条件)の場合、結合テーブルで条件を指定する場合に特殊な構文を使用します。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

さらに読みやすい別の方法として、ハッシュ条件をネストさせる方法があります。

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: { created_at: time_range })
```

このコードでは、昨日作成された注文 (order) を持つすべてのクライアントを検索します。ここでもSQLの`BETWEEN`式を使用しています。

### `left_outer_joins`

関連レコードがあるかどうかにかかわらずレコードのセットを取得したい場合は、`left_outer_joins`メソッドを使います。

```ruby
Author.left_outer_joins(:posts).distinct.select('authors.*, COUNT(posts.*) AS posts_count').group('authors.id')
```

上のコードは、以下のクエリを生成します。

```sql
SELECT DISTINCT authors.*, COUNT(posts.*) AS posts_count FROM "authors"
LEFT OUTER JOIN posts ON posts.author_id = authors.id GROUP BY authors.id
```

上のSQLを日本語で書くと「著者 (authors) が記事 (posts) を持っているかどうかにかかわらず、すべての著者とその記事の数を返す」となります。


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
Article.includes(:category, :comments)
```

上のコードは、記事と、それに関連付けられたカテゴリやコメントをすべて読み込みます。

#### ネストした関連付けハッシュ

```ruby
Category.includes(articles: [{ comments: :guest }, :tags]).find(1)
```

上のコードは、id=1のカテゴリを検索し、関連付けられたすべての記事とそのタグやコメント、およびすべてのコメントのゲスト関連付けを一括読み込みします。

### 関連付けの一括読み込みで条件を指定する

Active Recordでは、`joins`のように事前読み込みされた関連付けに対して条件を指定することができますが、[joins](#テーブルを結合する) という方法を使用することをお勧めします。

しかし、このようにせざるを得ない場合は、`where`を通常どおりに使用することができます。

```ruby
Article.includes(:comments).where(comments: { visible: true })
```

このコードは、`LEFT OUTER JOIN`を含むクエリを1つ生成します。`joins`メソッドを使用していたら、代りに`INNER JOIN`を使用するクエリが生成されていたでしょう。

```ruby
  SELECT "articles"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "articles" LEFT OUTER JOIN "comments" ON "comments"."article_id" = "articles"."id" WHERE (comments.visible = 1)
```

`where`条件がない場合は、通常のクエリが2セット生成されます。

NOTE: `where`がこのように動作するのは、ハッシュを渡した場合だけです。SQL断片化 (fragmentation) を避けるためには、`references` を指定して強制的にテーブルをjoinする必要があります。

```ruby
Article.includes(:comments).where("comments.visible = true").references(:comments)
```

この`includes`クエリの場合、どの記事にもコメントがついていないので、すべての記事が読み込まれます。`joins` (INNER JOIN) を使用する場合、結合条件は必ずマッチ **しなければならず** 、それ以外の場合にはレコードは返されません。

NOTE: もしjoinの一部として関連付けが一括読み込みされている場合、読み込まれたモデルの中にカスタマイズされたSelect句のフィールドが存在しなくなります。これは親レコード (または子レコード) の中で表示して良いかどうかが曖昧になってしまうためです。

スコープ
------

スコープを設定することで、関連オブジェクトやモデルへのメソッド呼び出しとして参照される、よく使用されるクエリを指定することができます。スコープでは、`where`、`joins`、`includes`など、これまでに登場したすべてのメソッドを使用できます。どのスコープメソッドも、常に`ActiveRecord::Relation`オブジェクトを返します。このオブジェクトに対して、別のスコープを含む他のメソッド呼び出しを行なうこともできます。

単純なスコープを設定するには、クラスの内部で`scope`メソッドを使用し、スコープが呼び出されたときに実行して欲しいクエリをそこで渡します。

```ruby
class Article < ApplicationRecord
  scope :published, -> { where(published: true) }
end
```

スコープをスコープ内でチェイン (chain) させることもできます。

```ruby
class Article < ApplicationRecord
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

この`published`スコープを呼び出すには、クラスでこのスコープを呼び出します。

```ruby
Article.published # => [published articles]
```

または、`Article`オブジェクトからなる関連付けでこのスコープを呼び出します。

```ruby
category = Category.first
category.articles.published # => [このカテゴリに属する、公開済みの記事]
```

### 引数を渡す

スコープには引数を渡すことができます。

```ruby
class Article < ApplicationRecord
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

引数付きスコープの呼び出しは、クラスメソッドの呼び出しと同様の方法で行います。

```ruby
Article.created_before(Time.zone.now)
```

しかし、スコープに引数を渡す機能は、クラスメソッドによって提供される機能を単に複製したものです。

```ruby
class Article < ApplicationRecord
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

したがって、スコープで引数を使用するのであれば、クラスメソッドとして定義する方が推奨されます。クラスメソッドにした場合でも、関連オブジェクトからアクセス可能です。

```ruby
category.articles.created_before(time)
```

### 条件文を使う

スコープでは条件文を使うこともできます。

```ruby
class Article < ApplicationRecord
  scope :created_before, ->(time) { where("created_at < ?", time) if time.present? }
end
```

以下の例からもわかるように、これはクラスメソッドのように振る舞います。

```ruby
class Article < ApplicationRecord
  def self.created_before(time)
    where("created_at < ?", time) if time.present?
  end
end
```

ただし１つ注意点があります。それは条件文を評価した結果が`false`になった場合であっても、スコープは常に`ActiveRecord::Relation`オブジェクトを返すという点です。クラスメソッドの場合は`nil`を返すので、この振る舞いが異なります。したがって、条件文を使ってクラスメソッドをチェインさせていて、かつ、条件文のいずれかが`false`を返す場合、`NoMethodError`を発生することがあります。

### デフォルトスコープを適用する

あるスコープをモデルのすべてのクエリに適用したい場合、モデル自身の内部で`default_scope`メソッドを使用することができます。

```ruby
class Client < ApplicationRecord
  default_scope { where("removed_at IS NULL") }
end
```

このモデルに対してクエリが実行されたときのSQLクエリは以下のような感じになります。

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

デフォルトスコープの条件が複雑になるのであれば、スコープをクラスメソッドとして定義するのもひとつの手です。

```ruby
class Client < ApplicationRecord
  def self.default_scope
    # ActiveRecord::Relationを返すようにする
  end
end
```

NOTE: レコードを作成するときも、スコープの引数が`Hash`として与えられた場合は`default_scope`が適用されます。ただし、レコードを更新する場合は適用されません。例:

```ruby
class Client < ApplicationRecord
  default_scope { where(active: true) }
end

Client.new          # => #<Client id: nil, active: true>
Client.unscoped.new # => #<Client id: nil, active: nil>
```

引数に`Array`が与えられた場合は、`default_scope`クエリの引数は`Hash`のデフォルト値に変換されない点に注意してください。例:

```ruby
class Client < ApplicationRecord
  default_scope { where("active = ?", true) }
end

Client.new # => #<Client id: nil, active: nil>
```

### スコープのマージ

`where`句と同様、スコープも`AND`条件でマージできます。

```ruby
class User < ApplicationRecord
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

`scope`と`where`条件を混用してマッチさせることができます。その結果生成される最終的なSQLには、すべての条件が`AND`で結合されます。

```ruby
User.active.where(state: 'finished')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

末尾の`where`句をどうしてもスコープより優先したい場合は、`Relation#merge`を使用できます。

```ruby
User.active.merge(User.inactive)
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

ここでひとつ注意しなければならないのは、`default_scope`で定義した条件が、`scope`や`where`で定義した条件よりも先に評価されるという点です。

```ruby
class User < ApplicationRecord
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

上の例でわかるように、`default_scope`の条件が、`scope`と`where`の条件よりも先に評価されています。

### すべてのスコープを削除する

何らかの理由でスコープをすべて解除したい場合は`unscoped`メソッドを使用できます。このメソッドは、モデルで`default_scope`が指定されているが、それを適用したくないクエリがある場合に特に便利です。

```ruby
Client.unscoped.load
```

このメソッドはスコープをすべて解除し、テーブルに対して通常の (スコープなしの) クエリを実行するようにします。

```ruby
Client.unscoped.all
# SELECT "clients".* FROM "clients"

Client.where(published: false).unscoped.all
# SELECT "clients".* FROM "clients"
```

`unscoped` はブロックも受け取れます。

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

動的検索
---------------

Active Recordは、テーブルに定義されたすべてのフィールド (属性とも呼ばれます) に対して自動的に検索メソッドを提供します。たとえば、`Client`モデルに`first_name`というフィールドがあると、`find_by_first_name`というメソッドがActive Recordによって自動的に作成されます。`Client`モデルに`locked`というフィールドがあれば、`find_by_locked`というメソッドを使用できます。

この動的検索メソッドの末尾に`Client.find_by_name!("Ryan")`のように感嘆符 (`!`) を追加すると、該当するレコードがない場合に`ActiveRecord::RecordNotFound`エラーが発生します。

nameとlockedの両方を検索したいのであれば、2つのフィールド名をandでつなぐだけでメソッドを利用できます。たとえば、`Client.find_by_first_name_and_locked("Ryan", true)`のように書くことができます。

Enums
-----

`enum`マクロは整数のカラムを設定可能な値の集合にマッピングします。

```ruby
class Book < ApplicationRecord
  enum availability: [:available, :unavailable]
end
```

これは対応する[スコープ](#スコープ)を自動的に作成します。状態の遷移や現在の状態の問い合わせ用のメソッドも追加されます。

```ruby
# 下の両方の例で、利用可能な本を問い合わせている
Book.available
# または
Book.where(availability: :available)

book = Book.new(availability: :available)
book.available?   # => true
book.unavailable! # => true
book.available?   # => false
```

enumの詳細な仕様については、
[Rails API](http://api.rubyonrails.org/classes/ActiveRecord/Enum.html)を参照してください。

メソッドチェインを理解する
---------------------------------

Active Record パターンには [メソッドチェイン (Method chaining - Wikipedia)](http://en.wikipedia.org/wiki/Method_chaining) が実装されています。これにより、複数のActive Recordメソッドをシンプルな方法で次々に適用することができます。

文中でメソッドチェインができるのは、その前のメソッドが`ActiveRecord::Relation` (`all`、`where`、`joins`など) をひとつ返す場合です。文の末尾には、単一のオブジェクトを返すメソッド ([単一のオブジェクトを取り出す](#%E5%8D%98%E4%B8%80%E3%81%AE%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%82%92%E5%8F%96%E3%82%8A%E5%87%BA%E3%81%99)を参照) をひとつ置かなければなりません。

いくつか例をご紹介します。本ガイドでは一部の例のみをご紹介し、すべての例を網羅することはしません。Active Recordメソッドが呼び出されると、クエリはその時点ではすぐに生成されず、データベースに送信されます。クエリは、データが実際に必要になった時点で初めて生成されます。以下の例では、いずれも単一のクエリを生成します。

### 複数のテーブルからのデータをフィルタして取得する

```ruby
Person
  .select('people.id, people.name, comments.text')
  .joins(:comments)
  .where('comments.created_at > ?', 1.week.ago)
```

結果は次のようなものになります。

```sql
SELECT people.id, people.name, comments.text
FROM people
INNER JOIN comments
  ON comments.person_id = people.id
WHERE comments.created_at > '2015-01-01'
```

### 複数のテーブルから特定のデータを取得する

```ruby
Person
  .select('people.id, people.name, companies.name')
  .joins(:company)
  .find_by('people.name' => 'John') # 名を指定
```

上のコードから以下が生成されます。

```sql
SELECT people.id, people.name, companies.name
FROM people
INNER JOIN companies
  ON companies.person_id = people.id
WHERE people.name = 'John'
LIMIT 1
```

NOTE: ひとつのクエリが複数のレコードとマッチする場合、`find_by`は「最初」の結果だけを返し、他は返しません (上の`LIMIT 1` 文を参照)。

新しいオブジェクトを検索またはビルドする
---------------------------------

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

`find_or_create_by!`を使用すると、新しいレコードが無効な場合に例外を発生することもできます。検証 (validation) については本ガイドでは解説していませんが、たとえば

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
# => #<Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

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
# =>  [
#   #<Client id: 1, first_name: "Lucas" >,
#   #<Client id: 2, first_name: "Jan" >,
#   ...
# ]
```

`find_by_sql`は、カスタマイズしたデータベース呼び出しを簡単な方法で提供し、インスタンス化されたオブジェクトを返します。

### `select_all`

`find_by_sql`は`connection#select_all`と深い関係があります。`select_all`は`find_by_sql`と同様、カスタムSQLを使用してデータベースからオブジェクトを取り出しますが、取り出したオブジェクトのインスタンス化を行わない点が異なります。このメソッドは`ActiveRecord::Result`クラスのインスタンスを1つ返します。このオブジェクトで`to_hash`を呼ぶと、各レコードに対応するハッシュを含む配列を1つ返します。

```ruby
Client.connection.select_all("SELECT first_name, created_at FROM clients WHERE id = '1'").to_hash
# => [
#   {"first_name"=>"Rafael", "created_at"=>"2012-11-10 23:23:45.281189"},
#   {"first_name"=>"Eileen", "created_at"=>"2013-12-09 11:22:35.221282"}
# ]
```

### `pluck`

`pluck`は、1つのモデルで使用されているテーブルからカラム (1つでも複数でも可) を取得するクエリを送信するのに使用できます。引数としてカラム名のリストを与えると、指定したカラムの値の配列を、対応するデータ型で返します。

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

`select`と異なり、`pluck`はデータベースから受け取った結果を直接Rubyの配列に変換してくれます。そのための`ActiveRecord`オブジェクトを事前に構成しておく必要はありません。従って、このメソッドは大規模なクエリや使用頻度の高いクエリで使用するとパフォーマンスが向上します。ただし、オーバーライドを行なうモデルメソッドは使用できません。以下に例を示します。

```ruby
class Client < ApplicationRecord
  def name
    "私は#{super}"
  end
end

Client.select(:name).map &:name
# => ["私はDavid", "私はJeremy", "私はJose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

この操作は、単一テーブルのフィールドへのクエリに限定されません。以下のように複数テーブルへのクエリも行えます。

```
Client.joins(:comments, :categories).pluck("clients.email, comments.title, categories.name")
```


さらに`pluck`は、`select`などの`Relation`スコープと異なり、クエリを直接トリガするので、その後ろに他のスコープをチェインすることはできません。ただし、構成済みのスコープを`pluck`の前に置くことはできます。

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
class Person < ApplicationRecord
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

オブジェクトの存在チェック
--------------------

オブジェクトが存在するかどうかをチェックしたい時は`exists?`メソッドを使います。このメソッドは、`find`と同様のクエリを使用してデータベースにクエリを送信しますが、オブジェクトのコレクションの代わりに`true`または`false`を返します。

```ruby
Client.exists?(1)
```

`exists?`は複数の値を引数に取ることができます。ただし、それらの値のうち1つでも存在していれば、他の値が存在していなくても`true`を返します。

```ruby
Client.exists?(id: [1,2,3])
# または
Client.exists?(name: ['John', 'Sergei'])
```

`exists?`メソッドは、引数なしでモデルやリレーションに使用することもできます。

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
Article.any?
Article.many?

# 名前付きスコープを経由
Article.recent.any?
Article.recent.many?

# リレーション経由
Article.where(published: true).any?
Article.where(published: true).many?

# 関連付け経由
Article.first.categories.any?
Article.first.categories.many?
```

計算
------------

このセクションでは冒頭で`count`メソッドを例に取って説明していますが、ここで説明されているオプションは以下のすべてのサブセクションにも該当します。

あらゆる計算メソッドは、モデルに対して直接実行されます。

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

リレーションに対しても直接実行されます。

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

この他にも、リレーションに対してさまざまな検索メソッドを使用して複雑な計算を行なうことができます。

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: { status: 'received' }).count
```

上のコードは以下を実行します。

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = clients.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

### 個数を数える

モデルのテーブルに含まれるレコードの個数を数えるには`Client.count`を使用できます。返されるのはレコードの個数です。特定の年齢のクライアントの数を数えるのであれば、`Client.count(:age)`とします

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

リレーションによってトリガされるクエリでEXPLAINを実行することができます。以下に例を示します。

```ruby
User.where(id: 1).joins(:articles).explain
```

以下のような結果が生成されます。

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `articles` ON `articles`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+----------+-------+---------------+
| id | select_type | table    | type  | possible_keys |
+----+-------------+----------+-------+---------------+
|  1 | SIMPLE      | users    | const | PRIMARY       |
|  1 | SIMPLE      | articles | ALL   | NULL          |
+----+-------------+----------+-------+---------------+
+---------+---------+-------+------+-------------+
| key     | key_len | ref   | rows | Extra       |
+---------+---------+-------+------+-------------+
| PRIMARY | 4       | const |    1 |             |
| NULL    | NULL    | NULL  |    1 | Using where |
+---------+---------+-------+------+-------------+

2 rows in set (0.00 sec)
```

上の結果はMySQLの場合です。

Active Recordは、データベースシェルを模したデータをある程度整形して出力します。PostgreSQLアダプタで同じクエリを実行すると、今度は以下のような結果が得られます。

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "articles" ON "articles"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (articles.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on articles  (cost=0.00..28.88 rows=8 width=4)
         Filter: (articles.user_id = 1)
(6 rows)
```

一括読み込みを使用していると、内部で複数のクエリがトリガされることがあり、一部のクエリではその前の結果を必要とすることがあります。このため、`explain`はこのクエリを実際に実行し、それからクエリプランを要求します。以下に例を示します。

```ruby
User.where(id: 1).includes(:articles).explain
```

以下の結果を生成します。

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+
| id | select_type | table | type  | possible_keys |
+----+-------------+-------+-------+---------------+
|  1 | SIMPLE      | users | const | PRIMARY       |
+----+-------------+-------+-------+---------------+
+---------+---------+-------+------+-------+
| key     | key_len | ref   | rows | Extra |
+---------+---------+-------+------+-------+
| PRIMARY | 4       | const |    1 |       |
+---------+---------+-------+------+-------+

1 row in set (0.00 sec)

EXPLAIN for: SELECT `articles`.* FROM `articles`  WHERE `articles`.`user_id` IN (1)
+----+-------------+----------+------+---------------+
| id | select_type | table    | type | possible_keys |
+----+-------------+----------+------+---------------+
|  1 | SIMPLE      | articles | ALL  | NULL          |
+----+-------------+----------+------+---------------+
+------+---------+------+------+-------------+
| key  | key_len | ref  | rows | Extra       |
+------+---------+------+------+-------------+
| NULL | NULL    | NULL |    1 | Using where |
+------+---------+------+------+-------------+


1 row in set (0.00 sec)
```

上の結果はMySQLとMariaDBの場合です。

### EXPLAINの出力結果を解釈する

EXPLAINの出力を解釈することは、本ガイドの範疇を超えます。
以下の情報を参考にしてください。

* SQLite3: [EXPLAIN QUERY PLAN](http://www.sqlite.org/eqp.html)

* MySQL: [EXPLAIN Output Format](https://dev.mysql.com/doc/refman/5.6/ja/explain-output.html) （v5.6日本語）

* MariaDB: [EXPLAIN](https://mariadb.com/kb/en/mariadb/explain/)

* PostgreSQL: [Using EXPLAIN](https://www.postgresql.jp/document/10/html/using-explain.html) （v10日本語）
