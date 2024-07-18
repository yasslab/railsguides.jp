Active Record マイグレーション
========================

マイグレーション（migration）はActive Recordの機能の1つであり、データベーススキーマが長期にわたって進化を安定して繰り返せるようにするための仕組みです。マイグレーション機能のおかげで、スキーマ変更を生SQLで記述せずに、Rubyで作成されたマイグレーション用のDSL（ドメイン固有言語）を用いてテーブルの変更を簡単に記述できます。

このガイドの内容:

* マイグレーション作成でどんなジェネレータを利用できるか
* Active Recordでどんなデータベース操作用メソッドが提供されているか
* 既存のマイグレーションの変更方法や、スキーマの更新方法
* マイグレーションとスキーマファイル`schema.rb`の関係
* 参照整合性を維持する方法

--------------------------------------------------------------------------------

マイグレーションの概要
------------------

マイグレーションは、再現可能な方法で[データベーススキーマを継続的に進化させる](https://en.wikipedia.org/wiki/Schema_migration)便利な方法です。

マイグレーションではRubyの[DSL](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)を利用しているので、[SQL](https://ja.wikipedia.org/wiki/SQL)を手動で記述しなくても済み、スキーマやスキーマの変更がデータベースに依存しないようにできます。ここで説明した概念のいくつかについて詳しくは、[Active Record基礎ガイド](active_record_basics.html)および[Active Recordの関連付けガイド](association_basics.html)を読むことをオススメします。

個別のマイグレーションは、データベースの新しい「バージョン」とみなせます。スキーマは空の状態から始まり、マイグレーションによる変更が加わるたびにテーブルやカラムやインデックスがスキーマに追加・削除されます。Active Recordはマイグレーションの時系列に沿ってスキーマを更新する方法を知っているので、履歴のどの時点からでも最新バージョンのスキーマに更新できます。Railsがタイムライン内のどのマイグレーションを実行するかを認識する方法について詳しくは、後述する[マイグレーションのバージョン管理](#railsのマイグレーションによるバージョン管理)を参照してください。

Active Recordは`db/schema.rb`ファイルを更新し、データベースの最新の構造と一致するようにします。マイグレーションの例を以下に示します。

```ruby
# db/migrate/20240502100843_create_products.rb
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

上のマイグレーションを実行すると`products`という名前のテーブルが追加されます。この中には`name`というstringカラムと、`description`というtextカラムが含まれています。主キーは`id`という名前で暗黙に追加されます（`id`はActive Recordモデルにおけるデフォルトの主キーです）。`timestamps`マクロは、`created_at`と`updated_at`という2つのカラムを追加します。これらの特殊なカラムが存在する場合、Active Recordによって自動的に管理されます。

```ruby
# db/schema.rb
ActiveRecord::Schema[7.2].define(version: 2024_05_02_100843) do
  # 以下はこのデータベースをサポートするうえで有効にしなければならない拡張機能
  enable_extension "plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
```

今後、時間軸に沿って行いたい変更を定義します。このマイグレーションを実行する前は、データベースにテーブルは存在しません。マイグレーションの実行後はテーブルが存在するようになります。
Active Recordは、このマイグレーションを元に戻す方法も認識しています。このマイグレーションをロールバックすると、テーブルが削除されます。マイグレーションのロールバックの詳細については、[ロールバック](#ロールバック)セクションを参照してください。

時間軸に沿って行いたい変更を定義した後は、マイグレーションをロールバック可能にすることを考慮しておくことが重要です。Active Recordは、マイグレーションの進行を管理することでテーブルを確実に作成できますが、可逆性の概念が重要になります。マイグレーションが可逆的に作られていれば、マイグレーションを適用してテーブルを作成できるだけでなく、スムーズなロールバック機能も有効になります。
上記のマイグレーションを元に戻す場合、Active Recordはテーブルの削除をインテリジェントに処理し、マイグレーション作業全体でデータベースの一貫性を維持します。詳しくは、[以前のマイグレーションに戻す](#以前のマイグレーションに戻す)セクションを参照してください。

マイグレーションファイルを生成する
--------------------

### 単独のマイグレーションを作成する

マイグレーションは、マイグレーションクラスごとに1個ずつ`db/migrate`ディレクトリにファイルとして保存されます。

ファイル名は `YYYYMMDDHHMMSS_create_products.rb`という形式で、マイグレーションを識別するUTCタイムスタンプ、アンダースコア、マイグレーション名で構成されます。CamelCaseで記述するクラス名は、マイグレーションファイル名の後半部分と一致しなければなりません。

たとえば、`20240502100843_create_products.rb`というマイグレーションファイルでは`CreateProducts`クラスを定義し、`20240502101659_add_details_to_products.rb`というマイグレーションファイルでは`AddDetailsToProducts`クラスを定義する必要があります。Railsはこのタイムスタンプを手がかりにして、どのマイグレーションをどの順序で実行するかを決定します。そのため、別のアプリケーションからマイグレーションをコピーする場合や自分でファイルを生成する場合は、順序に注意してください。タイムスタンプの利用方法について詳しくは、[マイグレーションのバージョン管理](#railsのマイグレーションによるバージョン管理)セクションを参照してください。

Active Recordはマイグレーションファイルを生成するときに、マイグレーションのファイル名の冒頭に現在のタイムスタンプを自動的に追加します。たとえば、以下のコマンドを実行すると、アンダースコア形式のマイグレーション名の前にタイムスタンプが追加されたファイル名を持つ、空のマイグレーションファイルが作成されます。

```bash
$ bin/rails generate migration AddPartNumberToProducts
```

```ruby
# db/migrate/20240502101659_add_part_number_to_products.rb
class AddPartNumberToProducts < ActiveRecord::Migration[7.2]
  def change
  end
end
```

ジェネレータは、単にファイル名の冒頭にタイムスタンプを追加するだけではありません。命名規約や追加の（オプション）引数に基づいて、マイグレーションに肉付けすることもできます。

次のセクションでは、規約と追加の引数に基づいてマイグレーションを作成するさまざまな方法について解説します。

### 新しいテーブルを作成する

データベースに新しいテーブルを作成する場合は、「CreateXXX」という形式のマイグレーション名を指定して、その後にカラム名と型のリストを指定するようにしてください。こうすることで、指定したカラムでテーブルをセットアップするマイグレーションファイルが生成されます。

```bash
$ bin/rails generate migration CreateProducts name:string part_number:string
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number

      t.timestamps
    end
  end
end
```

ここまでに生成したマイグレーションの内容は、必要に応じてこれを元に作業するための単なる出発点でしかありません。`db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb`ファイルを編集して、項目の追加や削除を行えます。

### カラムを追加する

データベース内の既存のテーブルに新しいカラムを追加する場合は、「AddColumnToTable」という形式のマイグレーション名を指定して、その後にカラム名と型のリストを指定するようにしてください。こうすることで、適切な[`add_column`][]ステートメントを含むマイグレーションファイルが生成されます。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :part_number, :string
  end
end
```

新しいカラムにインデックスも追加したい場合は以下のようにコマンドを実行します。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string:index
```

上を実行すると以下のように適切な[`add_column`][]と[`add_index`][]ステートメントが生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

自動生成できるカラムは1個だけでは**ありません**。たとえば以下のように複数のカラムも指定できます。

```bash
$ bin/rails generate migration AddDetailsToProducts part_number:string price:decimal
```

上を実行すると、`products`テーブルに2個のカラムを追加するスキーママイグレーションを生成します。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

### カラムを削除する

同様に、「RemoveColumnFromTable」という形式のマイグレーション名を指定し、その後にカラム名と型のリストを与えることで、適切な[`remove_column`][]ステートメントを含むマイグレーションファイルが作成されます。

```bash
$ bin/rails generate migration RemovePartNumberFromProducts part_number:string
```

上を実行すると、適切な[`remove_column`][]ステートメントが生成されます。

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration[7.2]
  def change
    remove_column :products, :part_number, :string
  end
end
```

### 関連付けを作成する

Active Recordの**関連付け（association）**は、アプリケーション内のさまざまなモデル間のリレーションシップを定義するのに使われ、モデル同士がリレーションシップを通じてやり取りできるようにすることで、互いに関連するデータを操作しやすくします。関連付けについて詳しくは、[関連付けのガイド](association_basics.html)を参照してください。

関連付けの一般的なユースケースの1つは、テーブル間の外部キー参照を作成することです。Railsのマイグレーションジェネレーターは、この作業を軽減するために、`references`などのカラム型を渡せるようになっています。[`references`](#参照)型は、カラム、インデックス、外部キー、またはポリモーフィック関連付けカラムを作成するためのショートハンドです。

```bash
$ bin/rails generate migration AddUserRefToProducts user:references
```

たとえば上を実行すると、以下の[`add_reference`][]呼び出しが生成されます。

```ruby
class AddUserRefToProducts < ActiveRecord::Migration[7.2]
  def change
    add_reference :products, :user, null: false, foreign_key: true
  end
end
```

このマイグレーションを実行すると、`products`テーブルに`user_id`が作成されます。ここで`user_id`は、`users`テーブルの`id`カラムへの参照です。また、`user_id`カラムのインデックスも作成されます。
マイグレーション実行後のスキーマは次のようになります。

```ruby
  create_table "products", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_products_on_user_id"
  end
```

`belongs_to`は`references`のエイリアスなので、上述のマイグレーションコマンドは次のようにも記述できます。

```bash
$ bin/rails generate migration AddUserRefToProducts user:belongs_to
```

このマイグレーションコマンドで生成されるマイグレーションファイルやスキーマファイルは、上述のものと同じです。

名前の一部に`JoinTable`が含まれているとjoinテーブルを生成するジェネレータもあります。

```bash
$ bin/rails generate migration CreateJoinTableUserProduct user product
```

上によって以下のマイグレーションが生成されます。

```ruby
class CreateJoinTableUserProduct < ActiveRecord::Migration[7.2]
  def change
    create_join_table :users, :products do |t|
      # t.index [:user_id, :product_id]
      # t.index [:product_id, :user_id]
    end
  end
end
```

[`add_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column
[`add_index`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index
[`add_reference`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference
[`remove_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_column

### その他のマイグレーション作成用ジェネレータ

`migration`ジェネレータの他に、`model`ジェネレータ、`resource`ジェネレータ、`scaffold`ジェネレーターは、それぞれ新しいモデルを追加するのに適したマイグレーションを作成します。これらのマイグレーションには、関連するテーブルを作成するための手順がすでに含まれています。必要なカラムをRailsに指示すると、これらのカラムを追加するためのステートメントも作成されます。
たとえば、以下のコマンドを実行するとします。

```bash
$ bin/rails generate model Product name:string description:text
```

これにより、以下のようなマイグレーションが生成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

カラム名と型のペアは、好きなだけマイグレーションコマンドに追加できます。

### 修飾子を渡す

コマンドでマイグレーションを生成するときに、よく使われる[型修飾子](#カラム修飾子)をコマンドラインで直接指定できます。これらの修飾子は波かっこ`{}`で囲んでフィールド型の後ろに置きます。これにより、後でマイグレーションファイルを手動で編集せずにデータベースカラムをカスタマイズできます。

たとえば以下を実行したとします。

```bash
$ bin/rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

これによって以下のようなマイグレーションが生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true
  end
end
```

TIP: 詳しくはジェネレータのヘルプ（`bin/rails generate --help`）を参照してください。または、`bin/rails generate model --help`や`bin/rails generate migration --help`を実行して特定のジェネレーターのヘルプを表示することも可能です。

マイグレーションを更新する
-------------------

前述の[マイグレーションファイルを生成する](#マイグレーションファイルを生成する)セクションのいずれかのジェネレーターを使ってマイグレーションファイルを作成したら、`db/migrate`フォルダ内に生成されたマイグレーションファイルを更新して、データベーススキーマに加えたい変更を追加で定義できます。

### テーブルを作成する

[`create_table`][]は最も基本的なマイグレーションメソッドですが、手書きするよりも、モデルジェネレータやリソースジェネレータやscaffoldジェネレータで生成することがほとんどです。典型的な利用法は以下のとおりです。

```ruby
create_table :products do |t|
  t.string :name
end
```

上のメソッドは、`products`テーブルを作成し、`name`という名前のカラムをその中に作成します。

#### 関連付け

関連付けを持つモデルのテーブルを作成する場合は、以下のように`:references`型を指定することで適切なカラム型を作成できます。

```ruby
create_table :products do |t|
  t.references :category
end
```

上のマイグレーションによって`category_id`カラムが作成されます。以下のように、`belongs_to`の代わりに`references`をエイリアスとして使うことも可能です。

```ruby
create_table :products do |t|
  t.belongs_to :category
end
```

[`:polymorphic`](association_basics.html#ポリモーフィック関連付け)オプションを使って、以下のようなカラム型とインデックス作成を指定することも可能です。

```ruby
create_table :taggings do |t|
  t.references :taggable, polymorphic: true
end
```

上のマイグレーションによって、`taggable_id`カラムと`taggable_type`カラムと適切なインデックスが作成されます。

#### 主キー

`create_table`メソッドは、デフォルトで`id`という名前の主キーを暗黙で作成します。`:primary_key`オプションを使うと、以下のようにカラム名を変更できます。

```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, primary_key: "user_id" do |t|
      t.string :username
      t.string :email
      t.timestamps
    end
  end
end
```

上のマイグレーションで以下のスキーマが生成されます。

```ruby
create_table "users", primary_key: "user_id", force: :cascade do |t|
  t.string "username"
  t.string "email"
  t.datetime "created_at", precision: 6, null: false
  t.datetime "updated_at", precision: 6, null: false
end
```

複合主キーの場合は、以下のように`:primary_key`に配列も渡せます。複合主キーについて詳しくは[複合主キーガイド](active_record_composite_primary_keys.html)を参照してください。

```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, primary_key: [:id, :name] do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
  end
end
```

主キーを使いたくない場合は、以下のように`id: false`オプションを指定することも可能です。

```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: false do |t|
      t.string :username
      t.string :email
      t.timestamps
    end
  end
end
```

#### データベースオプション

特定のデータベースに依存するオプションが必要な場合は、以下のように`:options`オプションに続けてSQLフラグメントを記述します。

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

上のマイグレーションでは、テーブルを生成するSQLステートメントに`ENGINE=BLACKHOLE`を追加しています。

以下のように、`index: true`を渡すか、`:index`オプションにオプションハッシュを渡すと、[`create_table`][]ブロックで作成されるカラムにインデックスを追加できます。

```ruby
create_table :users do |t|
  t.string :name, index: true
  t.string :email, index: { unique: true, name: 'unique_emails' }
end
```

[`create_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table

#### コメント

`:comment`オプションを使うと、テーブルを説明するコメントを書いてデータベース自身に保存することも可能です。保存した説明文はMySQL WorkbenchやPgAdmin IIIなどのデータベース管理ツールで表示できます。説明文を追加しておくことでチームメンバーがデータモデルを理解しやすくなり、大規模なデータベースを持つアプリケーションでドキュメントを生成するのに役立ちます。
現時点では、MySQLとPostgreSQLアダプタのみがコメント機能をサポートしています。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :price, :decimal, precision: 8, scale: 2, comment: "製品価格（ドル）"
    add_column :products, :stock_quantity, :integer, comment: "現在の製品在庫数"
  end
end
```

### joinテーブルを作成する

マイグレーションの[`create_join_table`][]メソッドは、[has_and_belongs_to_many（HABTM）](association_basics.html#has-and-belongs-to-many関連付け)というjoinテーブルを作成します。典型的な利用法は以下のとおりです。

```ruby
create_join_table :products, :categories
```

上によって`categories_products`テーブルが作成され、その中に`category_id`カラムと`product_id`カラムが生成されます。

これらのカラムはデフォルトで`:null`オプションが`false`に設定されます。これは、このテーブルにレコードを保存するためには**必ず**何らかの値を指定しなければならないことを意味します。これは、以下のように`:column_options`オプションを指定することで上書きできます。

```ruby
create_join_table :products, :categories, column_options: { null: true }
```

デフォルトでは、`create_join_table`に渡された引数の最初の2つをつなげたものがjoinテーブル名になります。この場合、テーブル名は`categories_products`になります。

独自のテーブル名を使いたい場合は、`:table_name`で指定します。

```ruby
create_join_table :products, :categories, table_name: :categorization
```

上のようにすることで`categorization`という名前のjoinテーブルが作成されます。

`create_join_table`にはブロックも渡せます。ブロックはインデックスの追加（インデックスはデフォルトでは作成されません）やカラムの追加に使われます。

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

[`create_join_table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_join_table

### テーブルを変更する

既存のテーブルを変更する[`change_table`][]は、`create_table`とよく似ています。

基本的には`create_table`と同じ要領で使いますが、ブロックで生成されるオブジェクトでは、以下のようないくつかのテクニックが利用できます。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

上のマイグレーションでは`description`と`name`カラムが削除され、stringカラムである`part_number`が作成されてインデックスが追加されます。最後に`upccode`カラムを`upc_code`にリネームしています。

[`change_table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_table

### カラムを変更する

Railsのマイグレーションでは、[上述した](#カラムを追加する)`remove_column`や`add_column`と同様に、[`change_column`][]メソッドも利用できます。

```ruby
change_column :products, :part_number, :text
```

上は、productsテーブル上の`part_number`カラムの型を`:text`フィールドに変更しています。

NOTE: `change_column`コマンドは**逆進できない**点にご注意ください。マイグレーションを安全に元に戻せるようにするには、`reversible`なマイグレーションを独自に提供する必要があります。詳しくは、[`reversible`を使う](#reversibleを使う)を参照してください。

`change_column`の他に、カラムのnull制約を変更する[`change_column_null`][]メソッドや、カラムのデフォルト値を指定する[`change_column_default`][]メソッドも利用できます。

```ruby
change_column_default :products, :approved, from: true, to: false
```

上のマイグレーションは、`:approved`フィールドのデフォルト値を`true`から`false`に変更します。これらの変更は、どちらも今後のトランザクションにのみ適用され、既存のレコードには適用されない点にご注意ください。

null制約を変更するには、[`change_column_default`][]を使います。

```ruby
change_column_null :products, :name, false
```

上のマイグレーションは、productsの`:name`フィールドを `NOT NULL`カラムに設定します。この変更は既存のレコードにも適用されるため、既存のすべてのレコードの`:name`が`NOT NULL`になっていることを確認する必要があります。

NULL制約を`true`に設定すると、そのカラムはNULL値を許容するようになります。`false`に設定すると`NOT NULL`制約が適用され、レコードをデータベースに永続化するためには（NULL以外の）何らかの値を渡す必要があります。

NOTE: 上の`change_column_default`マイグレーションは`change_column_default :products, :approved, false`と書くことも可能ですが、先ほどの例と異なり、マイグレーションは逆進できなくなります。

[`change_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column
[`change_column_default`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_default
[`change_column_null`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_null

### カラム修飾子

カラムの作成時や変更時に、カラムの修飾子を適用できます。

* `comment`: カラムにコメントを追加します。
* `collation`: `string`カラムや`text`カラムのコレーション（照合順序）を指定します。
* `default`: カラムでのデフォルト値の設定を許可します。dateなどの動的な値を使う場合は、デフォルト値は初回（すなわちマイグレーションが実行された日付）しか計算されないことにご注意ください。デフォルト値を`NULL`にする場合は`nil`を指定してください。
* `limit`: `string`フィールドについては最大文字数を、`text`/`binary`/`integer`については最大バイト数を設定します。
* `null`: カラムで`NULL`値を許可または禁止します。
* `precision`: `decimal`/`numeric`/`datetime`/`time`フィールドの精度（precision）を定義します。
* `scale`: `decimal`/`numeric`フィールドのスケールを指定します。スケールは小数点以下の桁数で表されます。

NOTE: `add_column`と`change_column`にはインデックス追加用のオプションはありません。`add_index`で別途インデックスを追加する必要があります。

アダプタによっては他にも利用できるオプションがあります。詳しくは各アダプタ固有のAPIドキュメントを参照してください。

NOTE: `null`と`default`は、コマンドラインでマイグレーションを生成するときには指定できません。

### 参照

`add_reference`メソッドを使うと、1個以上の関連付け同士のつながりとして振る舞う適切な名前のカラムを作成できます。

```ruby
add_reference :users, :role
```

上のマイグレーションは、usersテーブルに`role_id`という外部キーカラムを作成します。`role_id`は、`roles`テーブルの`id`カラムへの参照です。さらに、`role_id`カラムのインデックスも作成されます（`index: false`オプションで明示的に無効にしない限り）。

INFO: 詳しくは[Active Record の関連付け](association_basics.html)ガイドも参照してください。

`add_belongs_to`メソッドは`add_reference`のエイリアスです。

```ruby
add_belongs_to :taggings, :taggable, polymorphic: true
```

`polymorphic:`オプションは、taggingsテーブルに`taggable_type`カラムおよび`taggable_id`カラムというポリモーフィック関連付け用のカラムを2つ作成します。

INFO: 詳しくは[ポリモーフィック関連付け](association_basics.html#ポリモーフィック関連付け)も参照してください。

`foreign_key`オプションを指定すると外部キーを作成できます。

```ruby
add_reference :users, :role, foreign_key: true
```

`add_reference`オプションについて詳しくは[APIドキュメント][`add_reference`]を参照してください。

`remove_reference`で以下のように参照を削除できます。

```ruby
remove_reference :products, :user, foreign_key: true, index: false
```

[`add_reference`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference

### 外部キー

[参照整合性の保証](#active-recordと参照整合性)に対して外部キー制約を追加することも可能です。これは必須ではありません。

```ruby
add_foreign_key :articles, :authors
```

上の[`add_foreign_key`][]呼び出しは、`articles`テーブルに新たな制約を追加します。この制約によって、`id`カラムが`articles.author_id`と一致する行が`authors`テーブル内に存在することが保証され、articlesテーブルにリストされているすべてのレビュー担当者が、authorsテーブルにリストされている有効な著者であることが保証されます。

NOTE: マイグレーションで`references`を使う場合、テーブルに新しいカラムを作成して、そのカラムに`foreign_key: true`で外部キーを追加するオプションもあります。ただし、既存のカラムに外部キーを追加する場合は、`add_foreign_key`を使えます。

参照される主キーを持つテーブルから、外部キーを追加するテーブルのカラム名を導出できない場合は、`:column`オプションでカラム名を指定できます。また、参照される主キーが`:id`でない場合は、`:primary_key`オプションを利用できます。

たとえば、`authors.email`を参照する`articles.reviewer`に外部キーを追加するには以下のようにします。

```ruby
add_foreign_key :articles, :authors, column: :reviewer, primary_key: :email
```

上は`articles`テーブルに制約を追加します。この制約は、`email`カラムが`articles.reviewer`フィールドと一致する行が、`authors`テーブルに存在することを保証します。

`add_foreign_key`では、`name`、`on_delete`、`if_not_exists`、`validate`、`deferrable`などのオプションもサポートされています。

外部キーの削除も以下のように[`remove_foreign_key`][]で行えます。

```ruby
# 削除するカラム名の決定をActive Recordに任せる場合
remove_foreign_key :accounts, :branches

# カラムを指定して外部キーを削除する場合
remove_foreign_key :accounts, column: :owner_id
```

NOTE: Active Recordでは単一カラムの外部キーのみがサポートされています。複合外部キーを使う場合は`execute`と`structure.sql`が必要です。詳しくは[スキーマダンプの意義](#スキーマダンプの意義)を参照してください。

### 複合主キー

1個のカラム値だけではテーブルの各行を一意に識別するのに不十分でも、2つ以上のカラムを組み合わせれば一意に**識別できる**場合があります。この状況は、主キーとして単一の`id`カラムを持たない既存のレガシーデータベースのスキーマを利用する場合や、シャーディングやマルチテナンシー向けにスキーマを変更する場合に起こる可能性があります。

`create_table`で以下のように`:primary_key`オプションと配列の値を渡すことで、複合主キー（composite primary key）を持つテーブルを作成できます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products, primary_key: [:customer_id, :product_sku] do |t|
      t.integer :customer_id
      t.string :product_sku
      t.text :description
    end
  end
end
```

INFO: 複合主キーを持つテーブルでは、多くのメソッドで整数のIDではなく配列値を渡す必要があります。詳しくは、[複合主キーガイド](active_record_composite_primary_keys.html)も参照してください。

### 生SQLを実行する

Active Recordが提供するヘルパーの機能だけでは不十分な場合、[`execute`][]メソッドで任意のSQLを実行できます。

```ruby
class UpdateProductPrices < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE products SET price = 'free'"
  end

  def down
    execute "UPDATE products SET price = 'original_price' WHERE price = 'free';"
  end
end
```

上の例では、productsテーブルの`price`カラムを全レコードについて'free'に更新しています。

WARNING: データをマイグレーションでみだりに直接変更しないよう注意が必要です。データを（rakeタスクやRailsランナーなどではなく）マイグレーションで変更することが本当にユースケースに最適な方法であるかどうかを慎重に検討し、複雑さやメンテナンスのオーバーヘッドが増加しないかどうか、データの整合性やデータベースの移植性に対するリスクが増加しないか、といった潜在的な欠点に十分注意してください。詳しくは、[データのマイグレーション](#データのマイグレーション)セクションを参照してください。

個別のメソッドについて詳しくは、APIドキュメントを確認してください。

特に、[`ActiveRecord::ConnectionAdapters::SchemaStatements`][]は、`change`、`up`、`down`メソッドで利用可能なメソッドを提供します。

`create_table`で生成されるオブジェクトで利用可能なメソッドについては、[`ActiveRecord::ConnectionAdapters::TableDefinition`][]を参照してください。

`change_table`で生成されるオブジェクトで利用可能なメソッドについては、[`ActiveRecord::ConnectionAdapters::Table`][]を参照してください。

[`execute`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-execute
[`ActiveRecord::ConnectionAdapters::SchemaStatements`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html
[`ActiveRecord::ConnectionAdapters::TableDefinition`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html
[`ActiveRecord::ConnectionAdapters::Table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html

### `change`メソッドを使う

`change`メソッドは、マイグレーションを自作する場合に最もよく使われます。このメソッドを使えば、多くの場合にActive Recordがマイグレーションを逆進させる（以前のマイグレーションにロールバックする）方法を自動的に認識します。以下は`change`でサポートされているマイグレーション定義の一部です。

* [`add_check_constraint`][]
* [`add_column`][]
* [`add_foreign_key`][]
* [`add_index`][]
* [`add_reference`][]
* [`add_timestamps`][]
* [`change_column_comment`][]（`:from`と`:to`の指定は省略不可）
* [`change_column_default`][]（`:from`と`:to`の指定は省略不可）
* [`change_column_null`][]
* [`change_table_comment`][]（`:from`と`:to`の指定は省略不可）
* [`create_join_table`][]
* [`create_table`][]
* `disable_extension`
* [`drop_join_table`][]
* [`drop_table`][]（テーブル作成時のオプションとブロックは省略不可）
* `enable_extension`
* [`remove_check_constraint`][]（元の制約式の指定は省略不可）
* [`remove_column`][]（元の型名とカラムオプションの指定は省略不可）
* [`remove_columns`][]（元の型名とカラムオプションの指定は省略不可）
* [`remove_foreign_key`][]（他のテーブル名と元のオプションの指定は省略不可）
* [`remove_index`][]（カラム名と元のオプションの指定は省略不可）
* [`remove_reference`][]（元のオプションの指定は省略不可）
* [`remove_timestamps`][]（元のオプションの指定は省略不可）
* [`rename_column`][]
* [`rename_index`][]
* [`rename_table`][]

ブロックで上記の逆進可能操作が呼び出されない限り、[`change_table`][] も逆進可能です。

これ以外のメソッドを使う必要がある場合は、`change`メソッドの代わりに`reversible`メソッドを利用するか、`up`と`down`メソッドを明示的に書いてください。

[`add_check_constraint`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_check_constraint
[`add_foreign_key`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_foreign_key
[`add_timestamps`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_timestamps
[`change_column_comment`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_comment
[`change_table_comment`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_table_comment
[`drop_join_table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-drop_join_table
[`drop_table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-drop_table
[`remove_check_constraint`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_check_constraint
[`remove_foreign_key`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_foreign_key
[`remove_index`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_index
[`remove_reference`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_reference
[`remove_timestamps`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_timestamps
[`rename_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_column
[`remove_columns`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_columns
[`rename_index`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_index
[`rename_table`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_table

### `reversible`を使う

マイグレーションが複雑になると、Active Recordがマイグレーションの`change`を逆進できなくなることがあります。[`reversible`][]メソッドを使うと、マイグレーションを通常どおり実行する場合と逆進する場合の動作を以下のように明示的に指定できます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[7.2]
  def change
    reversible do |direction|
      change_table :products do |t|
        direction.up   { t.change :price, :string }
        direction.down { t.change :price, :integer }
      end
    end
  end
end
```

上のマイグレーションは`price`カラムをstring型に変更し、マイグレーションが元に戻されるときにinteger型に戻します。`direction.up`と`direction.down`にそれぞれブロックを渡していることにご注目ください。

または、`change`の代わりに以下のように`up`と`down`に分けて書いても同じことができます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[7.2]
  def up
    change_table :products do |t|
      t.change :price, :string
    end
  end

  def down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
```

さらに`reversible`は、生SQLクエリを実行するときや、Active Recordメソッドに直接相当するものがないデータベース操作を実行するときにも便利です。以下のように、[`reversible`][]で、マイグレーションを実行するときの操作や、マイグレーションを元に戻すときの操作を個別に指定できます。

```ruby
class ExampleMigration < ActiveRecord::Migration[7.2]
  def change
    create_table :distributors do |t|
      t.string :zipcode
    end
    reversible do |direction|
      direction.up do
        # distributors_viewを作成する
        execute <<-SQL
          CREATE VIEW distributors_view AS
          SELECT id, zipcode
          FROM distributors;
        SQL
      end
      direction.down do
        execute <<-SQL
          DROP VIEW distributors_view;
        SQL
      end
    end

    add_column :users, :address, :string
  end
end
```

`reversible`メソッドを使えば、指示が正しい順序で実行されることも保証されます。上のマイグレーション例を元に戻すと、`users.address`カラムが削除された直後、`distributors`テーブルが削除される直前に`down`ブロックが実行されます。

[`reversible`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-reversible

### `up`/`down`メソッドを使う

`change`の代わりに、従来の`up`メソッドと`down`メソッドも利用できます。

`up`メソッドにはスキーマに対する変換方法を記述し、`down`メソッドには`up`メソッドによって行われた変換をロールバック（逆進、取り消し）する方法を記述する必要があります。つまり、`up`の後に`down`を実行した場合、スキーマが元通りになる必要があります。

たとえば、`up`メソッドでテーブルを作成したら、`down`メソッドではそのテーブルを削除する必要があります。`down`メソッド内で行なう変換の順序は、`up`メソッド内で行なう順序の正確な逆順にするのが賢明です。先の`reversible`セクションの例は以下と同等になります。

```ruby
class ExampleMigration < ActiveRecord::Migration[7.2]
  def up
    create_table :distributors do |t|
      t.string :zipcode
    end

    # distributors_viewを作成する
    execute <<-SQL
      CREATE VIEW distributors_view AS
      SELECT id, zipcode
      FROM distributors;
    SQL

    add_column :users, :address, :string
  end

  def down
    remove_column :users, :address

    execute <<-SQL
      DROP VIEW distributors_view;
    SQL

    drop_table :distributors
  end
end
```

### 逆進防止用のエラーを発生させる

場合によっては、逆進しようがないマイグレーションを実行することもあります（データの一部を削除するなど）。

このような場合、以下のように`down`ブロックで`ActiveRecord::IrreversibleMigration`をraiseできます。

```ruby
class IrreversibleMigrationExample < ActiveRecord::Migration[7.2]
  def up
    drop_table :example_table
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "データ破棄マイグレーションなので逆進できません"
  end
end
```

誰かがマイグレーションを取り消そうとすると、逆進不可能であることを示すエラーメッセージが表示されます。

### 以前のマイグレーションに戻す

[`revert`][]メソッドを使うと、Active Recordマイグレーションのロールバック機能を利用できます。

```ruby
require_relative '20121212123456_example_migration'

class FixupExampleMigration < ActiveRecord::Migration[7.2]
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert`メソッドには、逆進を行う命令を含むブロックも渡せます。これは、以前のマイグレーションの一部のみを逆進させたい場合に便利です。

たとえば、`ExampleMigration`がコミット済みになっており、後になってDistributorsビュー（データベースビュー）が不要になったとします。この場合、`revert`を使ってビューを削除するマイグレーションを作成できます。

```ruby
class DontUseDistributorsViewMigration < ActiveRecord::Migration[7.2]
  def change
    revert do
      # ExampleMigrationのコードのコピペ
      create_table :distributors do |t|
        t.string :zipcode
      end

      reversible do |direction|
        direction.up do
          # distributors_viewを作成する
          execute <<-SQL
            CREATE VIEW distributors_view AS
            SELECT id, zipcode
            FROM distributors;
          SQL
        end
        direction.down do
          execute <<-SQL
            DROP VIEW distributors_view;
          SQL
        end
      end

      # 以後のマイグレーションはOK
    end
  end
end
```

`revert`を使わなくても同様のマイグレーションは自作できますが、その分以下の作業が増えます。

1. `create_table`と`reversible`の順序を逆にする。
2. `create_table`を`drop_table`に置き換える。
3. 最後に`up`と`down`を入れ替える。

`revert`は、これらの作業を一手に引き受けてくれます。

[`revert`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-revert

マイグレーションを実行する
------------------

Railsにはマイグレーションを実行するためのコマンドがいくつか用意されています。

マイグレーションを実行する`rails`コマンドの筆頭といえば、`rails db:migrate`でしょう。このタスクは基本的に、まだ実行されていない`change`または`up`メソッドを実行します。未実行のマイグレーションがない場合は何もせずに終了します。マイグレーションの実行順序は、マイグレーションの日付が基準になります。

`db:migrate`タスクを実行すると、`db:schema:dump`コマンドも同時に呼び出されます。このコマンドは`db/schema.rb`スキーマファイルを更新し、スキーマがデータベースの構造に一致するようにします。

マイグレーションの特定バージョンを指定すると、Active Recordは指定されたマイグレーションに達するまでマイグレーション（`change`・`up`・`down`）を実行します。マイグレーションのバージョンは、マイグレーションファイル名冒頭の数字で表されます。たとえば、20240428000000というバージョンまでマイグレーションしたい場合は、以下を実行します。

```bash
$ bin/rails db:migrate VERSION=20240428000000
```

20240428000000というバージョンが現在のバージョンより大きい場合（新しい方に進む通常のマイグレーションなど）、20240428000000に到達するまで（このマイグレーション自身も実行対象に含まれます）のすべてのマイグレーションの`change`（または`up`）メソッドを実行し、その先のマイグレーションは行いません。過去に遡るマイグレーションの場合、20240428000000に到達するまでのすべてのマイグレーションの`down`メソッドを実行しますが、上と異なり、20240428000000自身は含まれない点にご注意ください。

### ロールバック

直前に行ったマイグレーションをロールバックして取り消す作業はよく発生します（マイグレーションに誤りがあって訂正したい場合など）。この場合、いちいちバージョン番号を調べて明示的にロールバックを実行しなくても、以下を実行するだけで済みます。

```bash
$ bin/rails db:rollback
```

これにより、`change`メソッドを逆進実行するか、`down`メソッドを実行する形で直前のマイグレーションにロールバックします。マイグレーションを2つ以上ロールバックしたい場合は、`STEP`パラメータを指定できます。

```bash
$ bin/rails db:rollback STEP=3
```

これにより、最後に行った3つのマイグレーションがロールバックされます。

ローカルのマイグレーションを一時的に変更して、再度マイグレーションする前にその特定のマイグレーションをロールバックしたい場合には、`db:migrate:redo`コマンドが使えます。`db:rollback`コマンドと同様に、複数のバージョンを戻す必要がある場合は`STEP`パラメータを指定できます。

```bash
$ bin/rails db:migrate:redo STEP=3
```

NOTE: `db:migrate`コマンドでも、`db:migrate:redo`コマンドと同じ結果を得られます。ただし`db:migrate:redo`コマンドは利便性のために用意されており、マイグレーション先のバージョンを明示的に指定する必要はありません。

#### トランザクション

DDLトランザクションをサポートするデータベースでは、単一のトランザクションでスキーマを変更すると、個別のマイグレーションがトランザクションにラップされます。

INFO: マイグレーションが途中で失敗した場合、途中まで正常に適用された変更はトランザクションによってすべてロールバックされ、データベースの一貫性が維持されます。つまり、トランザクション内のあらゆる操作は「正常に実行される」か「まったく実行されない」かのどちらかだけになり、トランザクションの途中でエラーが発生したときにデータベースが不整合な状態になるのを防ぎます。

データベースがDDLトランザクション（スキーマを変更するステートメントなど）をサポートしていない場合、マイグレーションが失敗しても成功した部分はロールバックされません。この変更は手動でロールバックする必要があります。

ただし、ある種のクエリはトランザクション内では実行できないので、そのような状況では、以下のように`disable_ddl_transaction!`で自動トランザクションを意図的にオフにできます。

```ruby
class ChangeEnum < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    execute "ALTER TYPE model_size ADD VALUE 'new_value'"
  end
end
```

NOTE: `self.disable_ddl_transaction!`でマイグレーションしている場合でも、独自のトランザクションを別途オープンすることは可能である点にご注意ください。

### データベースをセットアップする

`bin/rails db:setup`コマンドは、「データベースの作成」「スキーマの読み込み」「seedデータを用いたデータベースの初期化」をまとめて実行します。

### データベースを準備する

`bin/rails db:prepare`コマンドは`bin/rails db:setup`に似ていますが、冪等（べきとう: idempotent）に振る舞うので、複数回呼び出しても問題が生じず、必要なタスクは1回だけ実行されます。

* データベースがまだ作成されていない場合:
  `bin/rails db:prepare`コマンドは`bin/rails db:setup`と同じように実行されます。

* データベースは存在するがテーブルが作成されていない場合:
  `bin/rails db:prepare`コマンドはスキーマを読み込んで保留中のマイグレーションを実行し、更新されたスキーマをダンプし、最後にseedデータを読み込みます。詳しくは、[seedデータ](#マイグレーションとseedデータ)のセクションを参照してください。

* データベースとテーブルの両方が存在するがseedデータが読み込まれていない場合:
  `bin/rails db:prepare`コマンドはseedデータのみを読み込みます。

* データベース、テーブル、seedデータがすべて揃っている場合:
  `bin/rails db:prepare`コマンドは何も行いません。

NOTE: データベースの作成、テーブルの作成、seedデータの読み込みがすべて完了した後は、読み込み済みのseedデータや既存のseedファイルを変更または削除しても、このコマンドではseedデータの再読み込みは行われません。seedデータを再度読み込むには、`bin/rails db:seed`を手動で実行してください。

### データベースをリセットする

`bin/rails db:reset`コマンドは、データベースをdropして再度設定します。このコマンドは`rails db:drop db:setup`と同等です。

NOTE: このコマンドは、すべてのマイグレーションを実行することと等価ではありません。このコマンドは単に現在の`schema.rb`の内容をそのまま使い回します。マイグレーションをロールバックできなくなると、`rails db:reset`を実行しても復旧できないことがあります。スキーマダンプについて詳しくは、[スキーマダンプの意義](#スキーマダンプの意義)セクションを参照してください。

### 特定のマイグレーションのみを実行する

特定のマイグレーションをupまたはdown方向に実行する必要がある場合は、`db:migrate:up`または`db:migrate:down`タスクを使います。以下に示したように、適切なバージョン番号を指定するだけで、該当するマイグレーションに含まれる`change`、`up`、`down`メソッドのいずれかが呼び出されます。

```bash
$ bin/rails db:migrate:up VERSION=20240428000000
```

上を実行すると、バージョン番号が20240428000000のマイグレーションに含まれる`change`メソッド（または`up`メソッド）が実行されます。

このコマンドは、最初にそのマイグレーションが実行済みであるかどうかをチェックし、Active Recordによって実行済みであると認定された場合は何も行いません。

指定のバージョンが存在しない場合は、以下のように例外を発生します。

```bash
$ bin/rails db:migrate VERSION=00000000000000
rails aborted!
ActiveRecord::UnknownMigrationVersionError:

No migration with version number 00000000000000.
```

### 環境を指定してマイグレーションを実行する

デフォルトでは、`rails db:migrate`は`development`環境で実行されます。
他の環境に対してマイグレーションを行いたい場合は、コマンド実行時に`RAILS_ENV`環境変数を指定します。たとえば、`test`環境でマイグレーションを実行する場合は以下のようにします。

```bash
$ bin/rails db:migrate RAILS_ENV=test
```

### マイグレーション実行結果の出力を変更する

デフォルトでは、マイグレーション実行後に正確な実行内容とそれぞれの所要時間が出力されます。
たとえば、テーブル作成とインデックス追加を行なうと次のような出力が得られます。

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

マイグレーションには、これらの出力方法を制御するためのメソッドが提供されています。

| メソッド | 目的 |
| :- | :- |
| [`suppress_messages`][] | ブロックを渡すと、そのブロック内で生成される出力をすべて抑制する。|
| [`say`][] | 第1引数で渡したメッセージをそのまま出力する。第2引数には、出力をインデントするかどうかをboolean値で指定できる。|
| [`say_with_time`][] | 受け取ったブロックを実行するのに要した時間を示すテキストを出力する。ブロックが整数を1つ返す場合、影響を受けた行数であるとみなす。|

以下のマイグレーションを例に説明します。

```ruby
class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages { add_index :products, :name }
    say "and an index!", true

    say_with_time 'Waiting for a while' do
      sleep 10
      250
    end
  end
end
```

上によって以下の出力が得られます。

```bash
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

Active Recordから何も出力したくない場合は、`bin/rails db:migrate VERBOSE=false`で出力を完全に抑制できます。

[`say`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-say
[`say_with_time`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-say_with_time
[`suppress_messages`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-suppress_messages

### Railsのマイグレーションによるバージョン管理

Railsは、データベースの`schema_migrations`テーブルを介して、どのマイグレーションが実行されたかをトラッキングします。マイグレーションを実行すると、Railsは`version`カラムに保存されているマイグレーションのバージョン番号を含む行を`schema_migrations`テーブルに挿入します。これにより、Railsはどのマイグレーションがデータベースに適用済みかを判断できます。

たとえば、`20240428000000_create_users.rb`という名前のマイグレーションファイルがある場合、Railsはこのファイル名からバージョン番号（`20240428000000`）を抽出し、マイグレーションが正常に実行された後にそれを`schema_migrations`テーブルに挿入します。

`schema_migrations`テーブルの内容は、データベース管理ツールで直接表示することも、以下のようにRailsコンソールで表示することも可能です。

```irb
rails dbconsole
```

次に、データベースコンソール内で以下のように`schema_migrations`テーブルにクエリできます。

```sql
SELECT * FROM schema_migrations;
```

これにより、データベースに適用されたすべてのマイグレーションのバージョン番号のリストが表示されます。Railsはこの情報を用いて、`rails db:migrate`コマンドや`rails db:migrate:up`コマンドでどのマイグレーションを実行する必要があるかを決定します。

既存のマイグレーションを変更する
----------------------------

マイグレーションを自作していると、ときにはミスしてしまうこともあります。いったんマイグレーションを実行してしまった後では、既存のマイグレーションを単に編集してもう一度マイグレーションをやり直しても意味がありません。Railsはそのマイグレーションが既に実行済みであると認識しているので、`rails db:migrate`を実行しただけでは何も変更されません。
このような場合には、マイグレーションをいったんロールバック（`rails db:rollback`など）してからマイグレーションを修正し、それから`bin/rails db:migrate`を実行して修正済みバージョンのマイグレーションを実行する必要があります。

一般に、Gitなどのバージョン管理システムに既にコミットされた既存のマイグレーションを直接書き換えるのはよくありません。既存のマイグレーションが既にproduction環境で運用されているときに既存のマイグレーションを書き換えると、自分自身はもちろん、共同作業者も余分な作業を強いられます。
既存のマイグレーションを書き換えるのではなく、必要な変更を実行する新しいマイグレーションを作成すべきです。

なお、マイグレーションを新しく作成した直後で、バージョン管理システムにまだコミットしていない（一般的に言えば、開発用のコンピュータ以外に反映されていない）のであれば、そうしたマイグレーションを書き換えることは普通に行われています。

`revert`メソッドは、以前のマイグレーション全体またはその一部を逆進させるためのマイグレーションを新たに書くときにも便利です（上述の[以前のマイグレーションに戻す](#以前のマイグレーションに戻す)を参照してください）。

スキーマダンプの意義
----------------------

### スキーマファイルの意味について

Railsのマイグレーションは強力ではありますが、データベースのスキーマを作成するための信頼できる情報源ではありません。**最終的に信頼できる情報源は、やはり現在動いているデータベースです**。

Railsは、データベーススキーマの最新の状態のキャプチャを試みるために、デフォルトで`db/schema.rb`ファイルを生成します。

アプリケーションのデータベースの新しいインスタンスを作成する場合、マイグレーションの全履歴を最初から繰り返すよりも、単に`rails db:schema:load`でスキーマファイルを読み込む方が、高速でエラーも起きにくい傾向があります。

マイグレーション内の外部依存性が変更されたり、マイグレーションと異なる進化を遂げたアプリケーションコードに依存していたりすると、[古いマイグレーション](#古いマイグレーション)を正しく適用できなくなる可能性があります。

TIP: スキーマファイルは、Active Recordの現在のオブジェクトにある属性を手軽にチェックするときにも便利です。スキーマ情報はモデルのコードにはありません。スキーマ情報は多くのマイグレーションに分かれて存在しており、そのままでは非常に探しにくいものですが、こうした情報はスキーマファイルにコンパクトな形で保存されています。

### スキーマダンプの種類

Railsで生成されるスキーマダンプのフォーマットは、`config/application.rb`で定義される[`config.active_record.schema_format`][]設定で制御されます。デフォルトのフォーマットは`:ruby`ですが、`:sql`も指定できます。

#### デフォルトの`:ruby`スキーマを利用する場合

`:ruby`を選択すると、スキーマは`db/schema.rb`に保存されます。このファイルを開いてみると、1つの巨大なマイグレーションのように見えます。

```ruby
ActiveRecord::Schema[7.2].define(version: 2008_09_06_171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "part_number"
  end
end
```

このスキーマ情報は、見てのとおりその内容を単刀直入に表しています。このファイルは、データベースを詳細に検査し、`create_table`や`add_index`などでその構造を表現することで作成されています。

#### `:sql`スキーマダンプを利用する場合

しかし、`db/schema.rb`では、「トリガ」「シーケンス」「ストアドプロシージャ」「チェック制約」などのデータベース固有の項目までは表現できません。

マイグレーションで`execute`を用いれば、RubyマイグレーションDSLでサポートされないデータベース構造も作成できますが、そうしたステートメントはスキーマダンプで再構成されない点にご注意ください。

これらの機能が必要な場合は、新しいデータベースインスタンスの作成に有用なスキーマファイルを正確に得るために、スキーマのフォーマットに`:sql`を指定する必要があります。

スキーマフォーマットを`:sql`にすると、データベース固有のツールを用いてデータベースの構造を`db/structure.sql`にダンプします。たとえばPostgreSQLの場合は`pg_dump`ユーティリティが使われます。MySQLやMariaDBの場合は、多くのテーブルで`SHOW CREATE TABLE`の出力結果がファイルに含まれます。

スキーマを`db/structure.sql`から読み込む場合、`bin/rails db:schema:load`を実行します。これにより、含まれているSQL文が実行されてファイルが読み込まれます。定義上、これによって作成されるデータベース構造は元の完全なコピーとなります。

[`config.active_record.schema_format`]:
    configuring.html#config-active-record-schema-format

### スキーマダンプとソースコード管理

スキーマダンプは一般にデータベースの作成に使われるものなので、スキーマファイルはGitなどのソースコード管理の対象に加えておくことを強く推奨します。

複数のブランチでスキーマを変更すると、マージしたときにスキーマファイルがコンフリクトする可能性があります。
コンフリクトを解決するには、`bin/rails db:migrate`を実行してスキーマファイルを再生成してください。

INFO: 新規生成されたRailsアプリでは、既にmigrationsフォルダがgitツリーに含まれているので、必要な作業は、新たに追加するマイグレーションを常にgitに追加してコミットすることだけです。

Active Recordと参照整合性
---------------------------------------

Active Recordパターンでは、「高度な処理は、基本的にデータベースよりもモデル側に配置すべき」であることを示唆しています。したがって、高度な処理の一部をデータベース側で行うトリガーや制約などの機能は、設計理念としては無条件に望ましいとは限りません。

`validates :foreign_key, uniqueness: true`のようなデータベースバリデーション機能は、データ整合性をモデルが強制する方法の1つです。モデルで関連付けの`:dependent`オプションを指定すると、親オブジェクトが削除されたときに子オブジェクトも自動的に削除されます。アプリケーションレベルで実行される他の機能と同様、モデルのこうした機能だけでは参照整合性を維持できないため、開発者によってはデータベースの[外部キー制約](#外部キー)機能を用いて参照整合性を補強することもあります。

しかし現実には、外部キー制約とuniqueインデックスについては一般にデータベースレベルで適用する方が安全であると考えられます。Active Recordは、このようなデータベースレベルの機能の操作を直接サポートしていませんが、`execute`メソッドを使えば任意のSQLコマンドを実行可能です。

Active Recordパターンは高度な処理をモデル側に配置することを重視していますが、外部キーやunique制約についてはデータベースレベルで実装しておかないと整合性の問題が発生する可能性があることは、ここで強調しておく価値があります。したがって、必要に応じてActive Recordパターンにデータベースレベルの制約を併用する形で機能を補完しておくことをオススメします。こうしたデータベースレベルの制約を使う場合は、そうした制約に対応する関連付けやバリデーションをコード内でも明示的に定義しておき、アプリケーションレイヤとデータベースレイヤの双方でデータの整合性を確保しておくべきです。

マイグレーションとseedデータ
------------------------

Railsのマイグレーション機能の主要な目的は、スキーマ変更のコマンドを一貫した手順で発行できるようにすることですが、データの追加や変更にも利用できます。これは、productionのデータベースのような削除や再作成を行えない既存データベースで便利です。

```ruby
class AddInitialProducts < ActiveRecord::Migration[7.2]
  def up
    5.times do |i|
      Product.create(name: "Product ##{i}", description: "A product.")
    end
  end

  def down
    Product.delete_all
  end
end
```

Railsには、データベース作成後に初期データを素早く簡単に追加するシード（seed）機能があります。seedは、development環境やtest環境で頻繁にデータを再読み込みする場合に特に便利です。

seed機能を使うには、`db/seeds.rb`を開いてRubyコードを記述し、`rails db:seed`を実行します。

NOTE: seedに記述するコードは、いつ、どの環境でも実行できるように冪等にしておくべきです。

```ruby
["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
  MovieGenre.find_or_create_by!(name: genre_name)
end
```

この方法なら、マイグレーションよりもずっとクリーンに空のアプリケーションのデータベースをセットアップできます。

古いマイグレーション
--------------

`db/schema.rb`や`db/structure.sql`は、使っているデータベースの最新ステートのスナップショットであり、そのデータベースを再構築するための情報源として信頼できます。これを手がかりにして、古いマイグレーションファイルを削除・削減できます。

`db/migrate/`ディレクトリ内のマイグレーションファイルを削除しても、マイグレーションファイルが存在していたときに`rails db:migrate`が実行されたあらゆる環境は、Rails内部の`schema_migrations`という名前のデータベース内に保存されている（マイグレーションファイル固有の）マイグレーションタイムスタンプへの参照を保持し続けます。詳しくは[マイグレーションによるバージョン管理](#railsのマイグレーションによるバージョン管理)セクションを参照してください。

マイグレーションファイルを削除した状態で`rails db:migrate:status`コマンド（本来マイグレーションのステータス（upまたはdown）を表示する）を実行すると、削除したマイグレーションファイルの後に`********** NO FILE **********`と表示されるでしょう。これは、そのマイグレーションファイルが特定の環境で一度実行されたが、`db/migrate/`ディレクトリの下に見当たらない場合に表示されます。

### Railsエンジンからのマイグレーション

[Railsエンジン](engines.html)でマイグレーションを行う場合、注意すべき点があります。エンジンでのマイグレーションをインストールするrakeタスクは「冪等」であり、2回以上実行しても結果が変わりません。
つまり、親アプリケーションに存在するマイグレーションは、以前のインストールによってスキップされ、マイグレーションが見つからない場合は最新のタイムスタンプでコピーされます。
古いエンジンのマイグレーションを削除してからインストールタスクを再実行すると、新しいタイムスタンプを持つ新しいファイルが作成され、`db:migrate`はそれらの新しいファイルを再実行しようとします。

したがって、一般にエンジン由来のマイグレーションは変更されないよう保護しておきましょう。そのようなマイグレーションには以下のような特殊なコメントがあります。

```ruby
# This migration comes from blorgh (originally 20210621082949)
```

## その他

### IDの代わりにUUIDを主キーに使う場合

デフォルトのRailsは、オートインクリメントされる整数値をデータベースレコードの主キーとして利用します。ただし、分散システムや外部サービスとの統合が必要な場合など、主キーとして[UUID]（https://ja.wikipedia.org/wiki/UUID）（Universally Unique Identifier: 汎用一意識別子）を使う方が有利になるシナリオもあります。UUIDは、IDを生成する中央機関に依存せずに、グローバルで一意な識別子を提供します。

#### RailsでUUIDを有効にする

RailsアプリケーションでUUIDを利用する前に、データベースがUUIDの保存をサポートしていることを確認しておく必要があります。さらに、UUIDを処理できるようにデータベースアダプタを構成しておく必要が生じる場合もあります。

NOTE: バージョン13より前のPostgreSQLを使っている場合は、`gen_random_uuid()`関数にアクセスするためにpgcrypto拡張機能を有効にしておく必要があるでしょう。

1. Railsを設定する

    Railsのアプリケーション設定ファイル（`config/application.rb`）に以下の行を追加して、RailsがデフォルトでUUIDを主キーとして生成するように構成します。

    ```ruby
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
    ```

    この設定によって、Active Recordモデルのデフォルトの主キーにUUIDを使うようRailsに指示します。

2. UUIDで参照を追加する

    モデル間の関連付けを参照で作成するときは、主キーの種別との一貫性を維持するために、以下のようにデータ型を`:uuid`として指定します。

    ``` ruby
    create_table :posts, id: :uuid do |t|
      t.references :author, type: :uuid, foreign_key: true
      # 他のカラム...
      t.timestamps
    end
    ```

    この例では、postsテーブルの`author_id`カラムはauthorsテーブルの`id`カラムを参照しています。主キーの種別を明示的に`:uuid`に設定することで、外部キーカラムが参照する主キーのデータ型と一致することが保証されます。他の関連付けやデータベースに合わせて構文を調整してください。

3. マイグレーションが変更される

    以下のコマンドでモデルのマイグレーションを生成すると、`id`が`uuid:`型になっていることがわかります。

    ```bash
      $ bin/rails g migration CreateAuthors
    ```

    ```ruby
    class CreateAuthors < ActiveRecord::Migration[8.0]
      def change
        create_table :authors, id: :uuid do |t|
          t.timestamps
        end
      end
    end
    ```

    上のマイグレーションによって以下のスキーマが生成されます。

    ```ruby
    create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
    end
    ```

    このマイグレーションの`id`カラムは、`gen_random_uuid()`関数によって生成されるデフォルト値を持つUUID主キーとして定義されます。

UUIDは、異なるシステム間でグローバルに一意であることが保証されているため、分散アーキテクチャに適しています。また、集中ID生成に依存しない一意の識別子を提供することで、外部システムやAPIとの統合をシンプルにできます。また、オートインクリメントの整数値とは異なり、UUIDはテーブル内のレコードの合計数に関する情報が公開されないため、セキュリティ上の利点もあります。

ただしUUIDは通常のIDよりもサイズが大きいため、パフォーマンスに影響する可能性があり、インデックス作成がより困難になります。UUIDは、整数の主キーや外部キーと比較すると、書き込みや読み取りのパフォーマンスが低下します。

NOTE: したがって、UUIDを主キーに採用することを決定する前に、こうしたトレードオフを評価し、アプリケーション固有の要件を考慮することが重要です。

### データのマイグレーション

データをマイグレーションすると、データベース内でデータが変換されたり移動したりします。Railsでは一般的に、マイグレーションファイルでデータを操作することは**推奨されません**。理由は以下のとおりです。

- **関心の分離**: スキーマ変更とデータ変更は、ライフサイクルも目的もそれぞれ異なります。スキーマ変更はデータベースの構造を変更するための操作ですが、データ変更はコンテンツを書き換える操作です。
- **ロールバックが複雑になる**: データのマイグレーションを安全かつ予測通りにロールバックすることは困難になる場合があります。
- **パフォーマンス**: データのマイグレーションは実行に長時間かかり、完了するまでテーブルがロックされてアプリケーションのパフォーマンスと可用性に悪影響が生じる可能性があります。

データをマイグレーションで操作するよりも、[`maintenance_tasks`](https://github.com/Shopify/maintenance_tasks) gemの利用を検討してください。このgemは、スキーマのマイグレーションを妨げることなく、安全かつ簡単に管理できる方法でデータのマイグレーションやその他のメンテナンスタスクを作成・管理するためのフレームワークを提供します。
