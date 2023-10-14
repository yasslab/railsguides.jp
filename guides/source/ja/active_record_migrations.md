Active Record マイグレーション
========================

マイグレーション（migration）はActive Recordの機能の1つであり、データベーススキーマが長期にわたって進化を安定して繰り返せるようにするための仕組みです。マイグレーション機能のおかげで、スキーマ変更を生SQLで記述せずに、Rubyで作成されたマイグレーション用のDSL（ドメイン固有言語）を用いてテーブルの変更を簡単に記述できます。

このガイドの内容:

* マイグレーション作成で利用できるジェネレータ
* Active Recordが提供するデータベース操作用メソッド群の解説
* マイグレーション実行とスキーマ更新用の`rails`タスクの解説
* マイグレーションとスキーマファイル`schema.rb`の関係

--------------------------------------------------------------------------------

マイグレーションの概要
------------------

マイグレーションは、[データベーススキーマの継続的な変更](https://en.wikipedia.org/wiki/Schema_migration)（英語）を、統一的かつ簡単に行なうための便利な手法です。マイグレーションではRubyのDSLが使われているので、生のSQLを作成する必要がなく、スキーマおよびスキーマ変更がデータベースに依存しなくなります。

個別のマイグレーションは、データベースの新しい「バージョン」とみなせます。スキーマは空の状態から始まり、マイグレーションによる変更が加わるたびにテーブル、カラム、エントリが追加または削除されます。Active Recordはマイグレーションの時系列に沿ってスキーマを更新する方法を知っているので、履歴のどの時点からでも最新バージョンのスキーマに更新できます。Active Recordは`db/schema.rb`ファイルを更新し、データベースの最新の構造と一致するようにします。

マイグレーションの例を以下に示します。

```ruby
class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

上のマイグレーションを実行すると`products`という名前のテーブルが追加されます。この中には`name`というstringカラムと、`description`というtextカラムが含まれています。主キーは`id`という名前で暗黙に追加されます。`id`はActive Recordモデルにおけるデフォルトの主キーです。`timestamps`マクロは、`created_at`と`updated_at`という2つのカラムを追加します。これらの特殊なカラムが存在する場合、Active Recordによって自動的に管理されます。

マイグレーションで定義されているのは、時間を先に進めるときに実行したい動作である点にご注目ください。マイグレーションの実行前にはテーブルは1つもありません。マイグレーションを実行すると、テーブルが作成されます。Active Recordは、このマイグレーションを逆進させる方法も知っています。マイグレーションをロールバックさせると、テーブルは削除されます。

トランザクション内でスキーマを変更するステートメントがデータベースでサポートされていれば、マイグレーションはトランザクションでラップされます。この機能がデータベースでサポートされていない場合は、マイグレーションの一部が失敗した場合にロールバックされません。その場合は、変更の逆進を手動で記述する必要があります。

NOTE: ある種のクエリは、トランザクション内で実行できないことがあります。アダプタがDDLトランザクションをサポートしている場合は、`disable_ddl_transaction!`を使えば単一のマイグレーションでこれらを無効にできます。

マイグレーションを取り消す（逆進させる）方法をActive Recordが推測できない場合は、`reversible`メソッドを利用できます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[7.0]
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

`change`の代わりに`up`と`down`を使うこともできます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[7.0]
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

マイグレーションを作成する
--------------------

### 単独のマイグレーションを作成する

マイグレーションは`db/migrate`ディレクトリに保存されます。1つのマイグレーションファイルが1つのマイグレーションクラスに対応します。マイグレーションファイル名は`YYYYMMDDHHMMSS_create_products.rb`のような形式になります。ファイル名の日時はマイグレーションを識別するUTCタイムスタンプであり、アンダースコアに続いてマイグレーション名が記述されます。マイグレーションのクラス名（CamelCase）は、ファイル名の後半（snake_case）と一致する必要があります。たとえば、`20080906120000_create_products.rb`では`CreateProducts`というクラスを定義し、`20080906120001_add_details_to_products.rb`では`AddDetailsToProducts`というクラスを定義する必要があります。Railsはマイグレーションの実行順序をファイル名のタイムスタンプで決定するので、マイグレーションを他のアプリケーションからコピーする場合や、自分でマイグレーションを生成する場合は、実行順に注意する必要があります。

タイムスタンプを算出する作業は退屈です。Active Recordにはタイムスタンプを自動生成するジェネレータが用意されています。

```bash
$ bin/rails generate migration AddPartNumberToProducts
```

上を実行すると、空のマイグレーションが適切な名前で作成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[7.0]
  def change
  end
end
```

ジェネレータは、単にファイル名の冒頭にタイムスタンプを追加するだけではありません。命名規約や追加の（オプション）引数に基づいて、マイグレーションに肉付けすることもできます。

マイグレーション名が"AddColumnToTable"や"RemoveColumnFromTable"で、かつその後ろにカラム名や型が続く形式になっていれば、適切な[`add_column`][]文や[`remove_column`][]文を含むマイグレーションが作成されます。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :part_number, :string
  end
end
```

新しいカラムにインデックスも追加したい場合は以下のようにします。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string:index
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

同様に、カラムを削除するマイグレーションをコマンドラインで生成するには以下のようにします。

```bash
$ bin/rails generate migration RemovePartNumberFromProducts part_number:string
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration[7.0]
  def change
    remove_column :products, :part_number, :string
  end
end
```

自動で生成できるカラムは1種類だけではありません。たとえば以下のような指定も可能です。

```bash
$ bin/rails generate migration AddDetailsToProducts part_number:string price:decimal
```

上を実行すると以下が生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

マイグレーション名が"CreateXXX"のような形式で、その後にカラム名と型が続く場合、XXXという名前のテーブルが作成され、指定の型のカラム名がその中に生成されます。たとえば次のようになります。

```bash
$ bin/rails generate migration CreateProducts name:string part_number:string
```

上を実行すると以下のマイグレーションファイルが生成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number

      t.timestamps
    end
  end
end
```

これまでと同様、ここまでに生成したマイグレーションの内容は単なる出発点でしかありません。`db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb`ファイルを編集して、項目の追加や削除を行えます。

同様に、カラム型に`references`も指定できます（`belongs_to`でも可）。たとえば次のようになります。

```bash
$ bin/rails generate migration AddUserRefToProducts user:references
```

上を実行すると以下の[`add_reference`][]呼び出しが生成されます。

```ruby
class AddUserRefToProducts < ActiveRecord::Migration[7.0]
  def change
    add_reference :products, :user, foreign_key: true
  end
end
```

このマイグレーションを実行すると、`user_id`が作成されます。[`reference`](#参照)（参照）は、「カラムの作成」「インデックスの作成」「外部キーの作成」そして「ポリモーフィック関連付けカラムの作成」のショートハンドです。

名前の一部に`JoinTable`が含まれているとjoinテーブルを生成するジェネレータもあります。

```bash
$ bin/rails generate migration CreateJoinTableCustomerProduct customer product
```

上によって以下のマイグレーションが生成されます。

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration[7.0]
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

[`add_column`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column
[`add_index`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index
[`add_reference`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference
[`remove_column`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_column

### モデルを生成する

モデルのジェネレータとscaffoldジェネレータは、新しいモデルを追加するマイグレーションを生成します。このマイグレーションには、関連するテーブルを作成する命令が既に含まれています。必要なカラムを指定すると、それらのカラムを追加する命令も同時に生成されます。たとえば、以下を実行するとします。

```bash
$ bin/rails generate model Product name:string description:text
```

このとき、以下のようなマイグレーションが作成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

カラム名と型のペアはいくつでも追加できます。

### 修飾子を渡す

よく使われる[型修飾子](#カラム修飾子)の中には、コマンドラインで直接渡せるものもあります。これらの型修飾子はフィールド型の後ろに波かっこ`{}`で追加します。

たとえば以下を実行したとします。

```bash
$ bin/rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

これによって以下のようなマイグレーションが生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true
  end
end
```

TIP: 詳しくはジェネレータのヘルプを参照してください。

マイグレーションを自作する
-------------------

ジェネレータでマイグレーションを作成できるようになったら、今度は自分で作成してみましょう。

### テーブルを作成する

[`create_table`][]メソッドは最も基本的なメソッドであり、ほとんどの場合モデルやscaffoldの生成時に使われます。典型的な利用法は以下のとおりです。

```ruby
create_table :products do |t|
  t.string :name
end
```

上によって`products`テーブルが生成され、`name`という名前のカラムがその中に作成されます（`id`というカラムも暗黙で生成されますが、これについては後述します）。

デフォルトでは、`create_table`によって`id`という名前の主キーが作成されます。`:primary_key`オプションを指定すれば主キー名も変更できます。主キーを使いたくない場合は`id: false`オプションを指定することも可能です。特定のデータベースに依存するオプションが必要な場合は、以下のように`:options`オプションに続けてSQLフラグメントを記述します。

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

上のマイグレーションでは、テーブルを生成するSQLステートメントに`ENGINE=BLACKHOLE`を追加しています。

以下のように`:index`オプションに`true`やオプションハッシュを渡すと、`create_table`ブロックで作成されるカラムにインデックスを追加できます。

```ruby
create_table :users do |t|
  t.string :name, index: true
  t.string :email, index: { unique: true, name: 'unique_emails' }
end
```

`:comment`オプションを使うと、テーブルを説明するコメントを書いてデータベース自身に保存することも可能です。保存した説明文はMySQL WorkbenchやPgAdmin IIIなどのデータベース管理ツールで表示できます。説明文を追加しておくことでデータモデルが理解しやすくなり、ドキュメントも生成されるので、大規模なデータベースを持つアプリケーションでは、マイグレーションにこのようなコメントを追加しておくことを強くおすすめします。
現時点では、MySQLとPostgreSQLアダプタのみがコメント機能をサポートしています。

[`create_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table

### joinテーブルを作成する

マイグレーションの[`create_join_table`][]メソッドはhas_and_belongs_to_many（HABTM）というjoinテーブルを作成します。典型的な利用法は以下のとおりです。

```ruby
create_join_table :products, :categories
```

上によって`categories_products`テーブルが作成され、その中に`category_id`カラムと`product_id`カラムが生成されます。これらのカラムには`:null`オプションがあり、デフォルト値は`false`です。`:column_options`オプションを指定すれば、これらを上書きできます。

```ruby
create_join_table :products, :categories, column_options: { null: true }
```

デフォルトでは、`create_join_table`に渡された引数の最初の2つをつなげたものがjoinテーブル名になります。
独自のテーブル名を使いたい場合は、`:table_name`で指定します。

```ruby
create_join_table :products, :categories, table_name: :categorization
```

上のようにすることで`categorization`テーブルが作成されます。

`create_join_table`にはブロックも渡せます。ブロックはインデックスの追加（インデックスはデフォルトでは作成されません）やカラムの追加に使われます。

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

[`create_join_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_join_table

### テーブルを変更する

既存のテーブルを変更する[`change_table`][]は、`create_table`とよく似ています。基本的には`create_table`と同じ要領で使いますが、ブロックでyieldされるオブジェクトではいくつかのテクニックが利用できます。たとえば次のようになります。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

上のマイグレーションでは`description`と`name`カラムが削除され、stringカラムである`part_number`が作成されてインデックスがそこに追加されます。そして最後に`upccode`カラムをリネームしています。

[`change_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_table

### カラムを変更する

マイグレーションでは、`remove_column`や`add_column`に加えて[`change_column`][]メソッドも利用できます。

```ruby
change_column :products, :part_number, :text
```

上は、productsテーブル上の`part_number`カラムの型を`:text`フィールドに変更しています。
`change_column`コマンドは逆進できない（可逆的でない）点にご注意ください。

`change_column`の他に、not null制約を変更する[`change_column_null`][]メソッドや、デフォルト値を指定する[`change_column_default`][]メソッドも利用できます。

```ruby
change_column_null :products, :name, false
change_column_default :products, :approved, from: true, to: false
```

上のマイグレーションはproductsテーブルの`:name`フィールドに`NOT NULL`制約を設定し、`:approved`フィールドのデフォルト値を`true`から`false`に変更します。

NOTE: 上の`change_column_default`マイグレーションは`change_column_default :products, :approved, false`と書くことも可能ですが、先ほどの例と異なり、マイグレーションは不可逆的になります。

[`change_column`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column
[`change_column_default`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_default
[`change_column_null`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_null

### カラム修飾子

カラムの作成時や変更時に、カラムの修飾子を適用できます。

* `comment`: カラムにコメントを追加します。
* `collation`: `string`カラムや`text`カラムのコレーション（照合順序）を指定します。
* `default`: カラムでのデフォルト値の設定を許可します。dateなどの動的な値を使う場合は、デフォルト値は最初（マイグレーションが実行された日付など）しか計算されないことにご注意ください。デフォルト値を`NULL`にする場合は`nil`を指定してください。
* `limit`: `string`フィールドについては最大文字数を、`text`/`binary`/`integer`については最大バイト数を設定します。
* `null`: カラムで`NULL`値を許可または禁止します。
* `precision`: `decimal`/`numeric`/`datetime`/`time`フィールドの精度（precision）を定義します。
* `scale`: `decimal`/`numeric`フィールドのスケールを指定します。スケールは小数点以下の桁数で表されます。

アダプタによっては他にも利用できるオプションがあります。詳しくは各アダプタ固有のAPIドキュメントを参照してください。

NOTE: `null`と`default`はコマンドラインで指定できません。

### 参照

`add_reference`メソッドを使うと、適切な名前のカラムを作成できます。

```ruby
add_reference :users, :role
```

このマイグレーションは、usersテーブルに`role_id`カラムを作成します。`index: false`オプションを明示的に指定しない限り、そのカラムのインデックスも作成します。

```ruby
add_reference :users, :role, index: false
```

`add_belongs_to`メソッドは`add_reference`のエイリアスです。

```ruby
add_belongs_to :taggings, :taggable, polymorphic: true
```

`polymorphic:`オプションは、taggingsテーブルに`taggable_type`カラムおよびtaggable_id`カラムというポリモーフィック関連付け用のカラムを2つ作成します。

`foreign_key`オプションを指定すると外部キーを作成できます。

```ruby
add_reference :users, :role, foreign_key: true
```

`add_reference`オプションについて詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference)を参照してください。

`remove_reference`を使って参照を削除できます。

```ruby
remove_reference :products, :user, foreign_key: true, index: false
```

### 外部キー

[参照整合性の保証](#active-recordと参照整合性) に対して外部キー制約を追加することもできます。これは必須ではありません。

```ruby
add_foreign_key :articles, :authors
```

上の[`add_foreign_key`][]呼び出しは、`articles`テーブルに新たな制約を追加します。この制約によって、`id`カラムが`articles.author_id`と一致する行が`authors`テーブル内に存在することが保証されます。

`to_table`名から`from_table`カラム名を導出できない場合は、`:column`オプションでカラム名を指定できます。参照されている主キーが`:id`以外の場合は、`:primary_key`オプションで主キーを指定してください。

たとえば、`authors.email`を参照する`articles.reviewer`に外部キーを追加するには以下のようにします。

```ruby
add_foreign_key :articles, :authors, column: :reviewer, primary_key: :email
```

`add_foreign_key`では、`name`、`on_delete`、`if_not_exists`、`validate`、`deferrable`などのオプションもサポートされています。

NOTE: Active Recordでは単一カラムの外部キーのみがサポートされています。複合外部キーを使う場合は`execute`と`structure.sql`が必要です。詳しくは[スキーマダンプの意義](#スキーマダンプの意義)を参照してください。

外部キーの削除も以下のように簡単に行えます。

```ruby
# 削除するカラム名の決定をActive Recordに任せる場合
remove_foreign_key :accounts, :branches

# カラムを指定して外部キーを削除する場合
remove_foreign_key :accounts, column: :owner_id
```

### ヘルパーの機能だけでは足りない場合

Active Recordが提供するヘルパーの機能だけでは不十分な場合、[`execute`][]メソッドで任意のSQLを実行できます。

```ruby
Product.connection.execute("UPDATE products SET price = 'free' WHERE 1=1")
```

個別のメソッドについて詳しくは、APIドキュメントを確認してください。
特に、[`ActiveRecord::ConnectionAdapters::SchemaStatements`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
（`change`、`up`、`down`メソッドで利用可能なメソッドを提供）、[`ActiveRecord::ConnectionAdapters::TableDefinition`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)（`create_table`で生成されるオブジェクトで利用可能なメソッドを提供）、および[`ActiveRecord::ConnectionAdapters::Table`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)（`change_table`で生成されるオブジェクトで利用可能なメソッドを提供）を参照してください。

[`execute`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-execute

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

[`add_check_constraint`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_check_constraint
[`add_foreign_key`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_foreign_key
[`add_timestamps`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_timestamps
[`change_column_comment`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_comment
[`change_table_comment`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_table_comment
[`drop_join_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-drop_join_table
[`drop_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-drop_table
[`remove_check_constraint`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_check_constraint
[`remove_foreign_key`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_foreign_key
[`remove_index`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_index
[`remove_reference`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_reference
[`remove_timestamps`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_timestamps
[`rename_column`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_column
[`remove_columns`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_columns
[`rename_index`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_index
[`rename_table`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-rename_table

### `reversible`を使う

マイグレーションが複雑になると、Active Recordがマイグレーションを逆進できないことがあります。[`reversible`][]メソッドを使うと、マイグレーションを通常どおり実行する場合と逆進する場合の動作を以下のように指定できます。

```ruby
class ExampleMigration < ActiveRecord::Migration[7.0]
  def change
    create_table :distributors do |t|
      t.string :zipcode
    end

    reversible do |direction|
      direction.up do
        # distributors viewを作成
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

`reversible`メソッドを使うことで、各命令を正しい順序で実行できます。前述のマイグレーション例を逆転させた場合、`down`ブロックは必ず`users.address`カラムが削除された直後、そして`distributors`テーブルがDROPされる直前に実行されます。

自作したマイグレーションが逆進不可能な場合、データの一部が失われる可能性があります。そのような場合は、`down`ブロック内で`ActiveRecord::IrreversibleMigration`をraiseできます。こうすることで、誰かが後にマイグレーションを逆転させたときに、実行不可能であることを示すエラーが表示されます。

[`reversible`]: https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-reversible

### `up`/`down`メソッドを使う

`change`の代わりに、従来の`up`メソッドと`down`メソッドも利用できます。
`up`メソッドにはスキーマに対する変換方法を記述し、`down`メソッドには`up`メソッドによって行われた変換をロールバック（逆転）する方法を記述する必要があります。つまり、`up`の後に`down`を実行した場合、スキーマが元に戻る必要があります。
たとえば、`up`メソッドでテーブルを作成したら、`down`メソッドではそのテーブルを削除する必要があります。`down`メソッド内で行なう変換の順序は、`up`メソッド内で行なう順序の正確な逆順にするのがよいでしょう。先の`reversible`セクションの例は以下と同等になります。

```ruby
class ExampleMigration < ActiveRecord::Migration[7.0]
  def up
    create_table :distributors do |t|
      t.string :zipcode
    end

    # distributors viewを作成
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

マイグレーションが逆進不可能な場合、`down`メソッド内で`ActiveRecord::IrreversibleMigration`エラーを発生させる必要があります。こうすることで、誰かが後にマイグレーションを逆進させたときに、実行不可能であることを示すエラーが表示されます。

### 以前のマイグレーションに戻す

[`revert`][]メソッドを使うと、Active Recordマイグレーションのロールバック機能を利用できます。

```ruby
require_relative '20121212123456_example_migration'

class FixupExampleMigration < ActiveRecord::Migration[7.0]
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert`には、逆進を行う命令を含むブロックも渡せます。これは、以前のマイグレーションの一部のみを逆進させたい場合に便利です。

たとえば、`ExampleMigration`がコミット済みになっており、後になってDistributors viewが不要になったとします。

```ruby
class DontUseDistributorsViewMigration < ActiveRecord::Migration[7.0]
  def change
    revert do
      # ExampleMigrationからコピペしたコード
      reversible do |direction|
        direction.up do
          # distributors viewを作成する
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

`revert`を使わなくても同様のマイグレーションは自作できますが、その分余計な手間がかかります（`create_table`と`reversible`の順序を逆にし、`create_table`を`drop_table`に置き換え、最後に`up`と`down`を入れ替える）。
`revert`はこれらの作業を一手に引き受けてくれます。

[`revert`]: https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-revert

マイグレーションを実行する
------------------

Railsにはマイグレーションを実行するための`rails`コマンドがいくつか用意されています。

マイグレーションを実行する`rails`コマンドの筆頭といえば、`rails db:migrate`でしょう。このタスクは基本的に、まだ実行されていない`change`または`up`メソッドを実行します。未実行のマイグレーションがない場合は何もせずに終了します。マイグレーションの実行順序は、マイグレーションの日付が基準になります。

`db:migrate`タスクを実行すると、`db:schema:dump`コマンドも同時に呼び出されます。このコマンドは`db/schema.rb`スキーマファイルを更新し、スキーマがデータベースの構造に一致するようにします。

マイグレーションの特定バージョンを指定すると、Active Recordは指定されたマイグレーションに達するまでマイグレーション（change・up・down）を実行します。マイグレーションのバージョンは、マイグレーションファイル名冒頭の数字で表されます。たとえば、20080906120000というバージョンまでマイグレーションしたい場合は、以下を実行します。

```bash
$ bin/rails db:migrate VERSION=20080906120000
```

20080906120000というバージョンが現在のバージョンより大きい場合（新しい方に進む通常のマイグレーションなど）、20080906120000に到達するまで（このマイグレーション自身も実行対象に含まれます）のすべてのマイグレーションの`change`（または`up`）メソッドを実行し、その先のマイグレーションは行いません。過去に遡るマイグレーションの場合、20080906120000に到達するまでのすべてのマイグレーションの`down`メソッドを実行しますが、上と異なり、20080906120000自身は含まれない点にご注意ください。

### ロールバック

直前に行ったマイグレーションをロールバックする作業はよく発生します（マイグレーションに誤りがあって訂正したい場合など）。この場合、バージョン番号を調べて明示的にロールバックを実行しなくても、以下を実行するだけで済みます。

```bash
$ bin/rails db:rollback
```

これにより、`change`メソッドを逆転実行するか`down`メソッドを実行する形で直前のマイグレーションにロールバックします。マイグレーションを2つ以上ロールバックしたい場合は、`STEP`パラメータを指定できます。

```bash
$ bin/rails db:rollback STEP=3
```

これにより、最後に行った3つのマイグレーションがロールバックされます。

`db:migrate:redo`コマンドは、ロールバックと再マイグレーションを一度に実行できるショートカットです。複数バージョンに対してこれを行いたい場合は、`db:rollback`コマンドの場合と同様に`STEP`パラメータも指定できます。

```bash
$ bin/rails db:migrate:redo STEP=3
```

ただし、これらのコマンドでできるのは、`db:migrate`でできることのみです。これらのコマンドは、バージョンを明示的に指定しなくて済むように`db:migrate`タスクを使いやすくした単なるショートカットです。

### データベースを設定する

`bin/rails db:setup`コマンドは、「データベースの作成」「スキーマの読み込み」「seedデータを用いたデータベースの初期化」をまとめて実行します。

### データベースをリセットする

`bin/rails db:reset`コマンドは、データベースをdropして再度設定します。このコマンドは`rails db:drop db:setup`と同等です。

NOTE: このコマンドは、すべてのマイグレーションを実行することと等価ではありません。このコマンドは単に現在の`schema.rb`の内容をそのまま使い回します。マイグレーションをロールバックできなくなると、`rails db:reset`を実行しても復旧できないことがあります。スキーマダンプについて詳しくは、[スキーマダンプの意義](#スキーマダンプの意義) セクションを参照してください。

### 特定のマイグレーションのみを実行する

特定のマイグレーションをupまたはdown方向に実行する必要がある場合は、`db:migrate:up`または`db:migrate:down`タスクを使います。以下に示したように、適切なバージョン番号を指定するだけで、該当するマイグレーションに含まれる`change`、`up`、`down`メソッドのいずれかが呼び出されます。

```bash
$ bin/rails db:migrate:up VERSION=20080906120000
```

上を実行すると、バージョン番号が20080906120000のマイグレーションに含まれる`change`メソッド（または`up`メソッド）が実行されます。このコマンドは、最初にそのマイグレーションが実行済みであるかどうかをチェックし、Active Recordによって実行済みであると認定された場合は何も行いません。

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
class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages {add_index :products, :name}
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

[`say`]: https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-say
[`say_with_time`]: https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-say_with_time
[`suppress_messages`]: https://api.rubyonrails.org/classes/ActiveRecord/Migration.html#method-i-suppress_messages

既存のマイグレーションを変更する
----------------------------

マイグレーションを自作していると、ときにはミスしてしまうこともあります。いったんマイグレーションを実行してしまった後では、既存のマイグレーションを単に編集してもう一度マイグレーションをやり直しても意味がありません。Railsはマイグレーションが既に実行済みであると認識しているので、`rails db:migrate`を実行しても何も変更されません。このような場合には、マイグレーションをいったんロールバック（`rails db:rollback`など）してからマイグレーションを修正し、それから`bin/rails db:migrate`を実行して修正済みバージョンのマイグレーションを実行する必要があります。

一般に、既存のマイグレーションを直接変更するのはよくありません。既存のマイグレーションを変更すると、自分自身はもちろん、共同作業者も余分な作業を強いられます。さらに、既存のマイグレーションがproduction環境で実行中の場合、ひどい頭痛の種になるでしょう。既存のマイグレーションを直接修正するのではなく、修正用のマイグレーションを新たに作成してそれを実行するのが正しい方法です。これまでコミットされてない（より一般的に言えば、これまでdevelopment環境以外にデプロイされたことのない）マイグレーションを新たに生成し、それを編集するのが害の少ない方法です。

`revert`メソッドは、以前のマイグレーション全体またはその一部を逆進させるためのマイグレーションを新たに書くときにも便利です（上述の[以前のマイグレーションに戻す](#以前のマイグレーションに戻す)を参照してください）。

スキーマダンプの意義
----------------------

### スキーマファイルの意味について

Railsのマイグレーションは強力ではありますが、データベースのスキーマを作成するための信頼できる情報源ではありません。信頼できる情報源は、やはりデータベースです。Railsは、デフォルトで`db/schema.rb`ファイルを生成してデータベーススキーマの最新の状態のキャプチャを試みます。

アプリケーションのデータベースの新しいインスタンスを作成する場合、マイグレーションの全履歴を最初から繰り返すよりも、単に`rails db:schema:load`でスキーマファイルを読み込む方が、高速かつエラーが起きにくい傾向があります。
マイグレーション内の外部依存性が変更されたり、マイグレーションと異なる進化を遂げたアプリケーションコードに依存していたりすると、[古いマイグレーション](#古いマイグレーション)を正しく適用できなくなる可能性があります。

スキーマファイルは、Active Recordの現在のオブジェクトにある属性を手軽にチェックするときにも便利です。スキーマ情報はモデルのコードにはありません。スキーマ情報は多くのマイグレーションに分かれて存在しており、そのままでは非常に探しにくいものですが、こうした情報はスキーマファイルにコンパクトな形で保存されています。

### スキーマダンプの種類

Railsで生成されるスキーマダンプのフォーマットは、`config/application.rb`の[`config.active_record.schema_format`][]設定で制御されます。デフォルトのフォーマットは`:ruby`ですが、`:sql`も指定できます。

`:ruby`を指定すると、スキーマは`db/schema.rb`に保存されます。このファイルを開いてみると、1つの巨大なマイグレーションのように見えます。

```ruby
ActiveRecord::Schema[7.0].define(version: 2008_09_06_171750) do
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

`db/schema.rb`では、「トリガ」「シーケンス」「ストアドプロシージャ」「チェック制約」などのデータベース固有の項目を表現できません。マイグレーションで`execute`を用いれば、RubyマイグレーションDSLでサポートされないデータベース構造も作成できますが、そうしたステートメントはスキーマダンプで再構成されない点にご注意ください。これらの機能が必要な場合は、新しいデータベースインスタンスの作成に有用なスキーマファイルを正確に得るために、スキーマのフォーマットに`:sql`を指定する必要があります。

スキーマフォーマットを`:sql`にすると、データベース固有のツールを用いてデータベースの構造を`db/structure.sql`にダンプします。たとえばPostgreSQLの場合は`pg_dump`ユーティリティが使われます。MySQLやMariaDBの場合は、多くのテーブルで`SHOW CREATE TABLE`の出力結果がファイルに含まれます。

スキーマを`db/structure.sql`から読み込む場合、`rails db:structure:load`を実行します。これにより、含まれているSQL文が実行されてファイルが読み込まれます。定義上、これによって作成されるデータベース構造は元の完全なコピーとなります。

[`config.active_record.schema_format`]: configuring.html#config-active-record-schema-format

### スキーマダンプとソースコード管理

スキーマダンプは一般にデータベースの作成に使われるものなので、スキーマファイルはGitなどのソースコード管理の対象に加えておくことを強く推奨します。

複数のブランチでスキーマを変更すると、マージしたときにスキーマファイルがコンフリクトする可能性があります。
コンフリクトを解決するには、`bin/rails db:migrate`を実行してスキーマファイルを再生成してください。

Active Recordと参照整合性
---------------------------------------

Active Recordは「高度な機能はデータベースではなくモデルに存在する」というコンセプトを主張しています。そのため、トリガーや制約などは、そうした高度な機能の一部をデータベースに戻すものとみなされており、Active Recordではあまり使われていません。

`validates :foreign_key, uniqueness: true`のようなデータベースバリデーション機能は、データ整合性をモデルが強制している例の１つです。モデルに関連付けの`:dependent`オプションを指定すると、親オブジェクトが削除されたときに子オブジェクトも自動的に削除されます。アプリケーションレベルで実行される他の機能と同様、モデルのこうした機能だけでは参照整合性を維持できないため、開発者によってはデータベースの[外部キー制約](#外部キー)機能を用いて参照整合性を高めることもあります。

Active Recordだけではこうした外部機能を扱うツールをすべて提供することはできませんが、`execute`メソッドを使えば任意のSQLを実行できます。

マイグレーションとseedデータ
------------------------

Railsのマイグレーション機能の主要な目的は、スキーマ変更のコマンドを一貫した手順で発行できるようにすることですが、データの追加や変更にも利用できます。これは、productionのデータベースのような削除や再作成を行えない既存データベースで便利です。

```ruby
class AddInitialProducts < ActiveRecord::Migration[7.0]
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

Railsには、データベース作成後に初期データを素早く簡単に追加するシード（seed）機能があります。シードは、development環境やtest環境で頻繁にデータを再読み込みする場合に特に便利です。
シード機能は、`db/seeds.rb`にRubyコードを記述して`rails db:seed`を実行するだけで簡単に利用できます。

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

この方法なら、マイグレーションよりもずっとクリーンに空のアプリケーションのデータベースをセットアップできます。

古いマイグレーション
--------------

`db/schema.rb`や`db/structure.sql`は、使っているデータベースの最新ステートのスナップショットであり、そのデータベースを再構築するための情報源として信頼できます。これを手がかりにして、古いマイグレーションファイルを削除できます。

`db/migrate/`ディレクトリ内のマイグレーションファイルを削除しても、マイグレーションファイルが存在していたときに`rails db:migrate`が実行されたあらゆる環境は、Rails内部の`schema_migrations`という名前のデータベース内に保存されている（マイグレーションファイル固有の）マイグレーションタイムスタンプへの参照を保持し続けます。このテーブルは、特定の環境でマイグレーションが実行されたことがあるかどうかをトラッキングするのに用いられます。

マイグレーションファイルを削除した状態で`rails db:migrate:status`コマンド（本来マイグレーションのステータス（upまたはdown）を表示する）を実行すると、削除したマイグレーションファイルの後に`********** NO FILE **********`と表示されるでしょう。これは、そのマイグレーションファイルが特定の環境で一度実行されたが、`db/migrate/`ディレクトリの下に見当たらない場合に表示されます。

ただし１つ注意点があります。エンジンからマイグレーションをインストールするrakeタスクは「冪等」です（2回以上実行しても結果が変わりません）。以前のインストールによって親アプリケーションに存在するマイグレーションはスキップされ、マイグレーションが見つからない場合は最新のタイムスタンプでコピーされます。古いエンジンのマイグレーションを削除してからインストールタスクを再実行すると、新しいタイムスタンプを持つ新しいファイルが作成され、`db:migrate`はそれらの新しいファイルを再実行しようとします。

したがって、一般にエンジン由来のマイグレーションは変更されないよう保護しておきましょう。そのようなマイグレーションには以下のようなコメントがあります。

```ruby
# このマイグレーションはblorghからのもの（ 元は20210621082949）
```
