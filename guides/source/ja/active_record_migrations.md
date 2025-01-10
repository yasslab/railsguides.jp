**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Record マイグレーション
========================

マイグレーション (migration) はActive Recordの機能の1つであり、データベーススキーマを長期にわたって安定して発展・増築し続けることができるようにするための仕組みです。マイグレーション機能のおかげで、Rubyで作成されたマイグレーション用のDSL (ドメイン固有言語) を用いて、テーブルの変更を簡単に記述できます。スキーマを変更するためにSQLを直に書いて実行する必要がありません。

このガイドの内容:

* マイグレーション作成で利用できるジェネレータ
* Active Recordが提供するデータベース操作用メソッド群の解説
* マイグレーション実行とスキーマ更新用の`rails`タスクの解説
* マイグレーションとスキーマファイル`schema.rb`の関係

--------------------------------------------------------------------------------

マイグレーションの概要
------------------

マイグレーションは、[データベーススキーマの継続的な変更](https://en.wikipedia.org/wiki/Schema_migration) (英語) を、統一的かつ簡単に行なうための便利な手法です。マイグレーションではRubyのDSLを使っているので、生のSQLを作成する必要がなく、スキーマとスキーマへの変更をデータベースの種類に依存せずに済みます。

1つ1つのマイグレーションは、データベースの新しい'version'とみなすことができます。スキーマは最初空の状態から始まり、マイグレーションによる変更が加わるたびにテーブル、カラム、エントリが追加または削除されます。Active Recordは時系列に沿ってスキーマを更新する方法を知っているので、履歴のどの時点からでも最新バージョンのスキーマに更新することができます。Active Recordは`db/schema.rb`ファイルを更新し、データベースの最新の構造と一致するようにします。

マイグレーションの例を以下に示します。

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
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

マイグレーションは、時間を先に進めるときに実行したい動作を定義していることにご注目ください。マイグレーションの実行前にはテーブルは1つもありません。マイグレーションを実行すると、テーブルが作成されます。Active Recordは、このマイグレーションの進行を逆転させる方法も知っています。マイグレーションをロールバックすると、テーブルは削除されます。

スキーマ変更のステートメントを利用できるトランザクションがデータベースでサポートされている場合、マイグレーションはトランザクションの内側にラップされて実行されます。これらがデータベースでサポートされていない場合は、マイグレーション中に一部が失敗した場合にロールバックされません。その場合は、変更を手動でロールバックする必要があります。

NOTE: ある種のクエリは、トランザクション内で実行できないことがあります。アダプタがDDLトランザクションをサポートしている場合は、`disable_ddl_transaction!`を使えば単一のマイグレーションでこれらを無効にできます。

マイグレーションを逆方向に実行 (ロールバック) する方法が推測できない場合、`reversible` を使います。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      change_table :products do |t|
        dir.up   { t.change :price, :string }
        dir.down { t.change :price, :integer }
      end
    end
  end
end
```

`change`の代わりに`up`と`down`を使うこともできます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[5.0]
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

マイグレーションは`db/migrate`ディレクトリに保存されます。1つのファイルが1つのマイグレーションクラスに対応します。マイグレーションファイル名は`YYYYMMDDHHMMSS_create_products.rb`のような形式になります。ファイル名の日時はマイグレーションを識別するUTCタイムスタンプであり、アンダースコアにつづいてマイグレーション名が記述されます。マイグレーション クラスの名前 (CamelCaseで表されるバージョン) は、ファイル名の後半と一致する必要があります。たとえば、`20080906120000_create_products.rb`では`CreateProducts`というクラスが定義され、`20080906120001_add_details_to_products.rb`では`AddDetailsToProducts`というクラスが定義される必要があります。Railsではマイグレーションの実行順序をファイル名のタイムスタンプで決定します。従って、マイグレーションを他のアプリケーションからコピーしたり、自分でマイグレーションを生成する場合は、実行順に注意する必要があります。

タイムスタンプを算出する作業は退屈です。Active Recordにはこれらを扱うためのジェネレータが用意されています。

```bash
$ rails generate migration AddPartNumberToProducts
```

これによって、適切な名前の付いた空のマイグレーションが作成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
  end
end
```

このジェネレータでは、ファイル名の末尾にタイムスタンプを追加する以外の操作もできます。命名規約や追加の（オプション）引数に基づいて、マイグレーションに肉付けすることもできます。

マイグレーション名が"AddColumnToTable"や"RemoveColumnFromTable"で、かつその後ろにカラム名や型が続く形式になっていれば、適切な`add_column`文や`remove_column`文を含むマイグレーションが作成されます。

```bash
$ rails generate migration AddPartNumberToProducts part_number:string
```

上を実行すると以下が生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
  end
end
```

新しいカラムにインデックスを追加したい場合は以下のようにします。

```bash
$ rails generate migration AddPartNumberToProducts part_number:string:index
```

上を実行すると以下が生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```


同様に、カラムを削除するマイグレーションをコマンドラインで生成するには以下のようにします。

```bash
$ rails generate migration RemovePartNumberFromProducts part_number:string
```

上を実行すると以下が生成されます。

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :part_number, :string
  end
end
```

自動で生成できるカラムは1つだけではありません。たとえば次のようになります。

```bash
$ rails generate migration AddDetailsToProducts part_number:string price:decimal
```

上を実行すると以下が生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

マイグレーション名が"CreateXXX"のような形式であり、その後にカラム名と種類が続く場合、XXXという名前のテーブルが作成され、指定の種類のカラム名がその中に生成されます。たとえば次のようになります。

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

上を実行すると以下が生成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number

      t.timestamps
    end
  end
end
```

これまでと同様、ここまでに生成した内容は単なる出発点でしかありません。`db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb`ファイルを編集して、項目の追加や削除を行なうことができます。

同様に、カラムの種類として`references` (`belongs_to` も可) を指定することができます。たとえば次のようになります。

```bash
$ rails generate migration AddUserRefToProducts user:references
```

上を実行すると以下が生成されます。

```ruby
class AddUserRefToProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :products, :user, foreign_key: true
  end
end
```

このマイグレーションを実行すると、`user_id`が作成され、適切なインデックスが追加されます。
`add_reference`オプションについて詳しくは、[APIドキュメント](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference)をご覧ください。

名前の一部に`JoinTable`が含まれているとテーブル結合を生成するジェネレータもあります。

```bash
$ rails g migration CreateJoinTableCustomerProduct customer product
```

上によって以下のマイグレーションが生成されます。

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration[5.0]
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

### モデルを生成する

モデルのジェネレータとscaffoldジェネレータは、新しいモデルを追加するマイグレーションを生成します。このマイグレーションには、関連するテーブルを作成する命令が既に含まれています。必要なカラムを指定すると、それらのカラムを追加する命令も同時に生成されます。たとえば、以下を実行するとします。

```bash
$ rails generate model Product name:string description:text
```

このとき、以下のようなマイグレーションが作成されます。

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

カラム名と種類のペアはいくつでも追加できます。

### 修飾子を渡す

ある種の[型修飾子](#カラム修飾子) をコマンドラインで直接渡すこともできます。これらは波かっこで囲まれ、後ろにフィールドの種類が追加されます。

たとえば以下を実行したとします。

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

これによって以下のようなマイグレーションが生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[5.0]
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

`create_table`メソッドは最も基本的なメソッドであり、ほとんどの場合モデルやscaffoldの生成時に使われます。典型的な利用法を以下に示します。

```ruby
create_table :products do |t|
  t.string :name
end
```

上によって`products`テーブルが生成され、`name`という名前のカラムがその中に作成されます (`id`というカラムも暗黙で生成されますが、これについては後述します)。

デフォルトでは、`create_table`によって`id`という名前の主キーが作成されます。`:primary_key`オプションを指定することで、主キー名を変更することもできます (その場合は必ず対応するモデル名を変更してください)。 主キーを使いたくない場合は`id: false`オプションを指定することもできます。特定のデータベースで使われるオプションが必要な場合は、`:options`オプションに続けてSQLフラグメントを記述します。たとえば次のようになります。

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

上のマイグレーションでは、テーブルを生成するSQLステートメントに`ENGINE=BLACKHOLE`を指定しています。

`:comment`オプションを使うと、テーブルの説明文を書いてデータベース自身に保存することもできます。保存された説明文はMySQL WorkbenchやPgAdmin IIIなどのデータベース管理ツールで表示できます。大規模なデータベースを持つアプリケーションでは、マイグレーションにこのようなコメントを追加しておくことを強くおすすめします。それによってデータモデルを理解しやすくなり、ドキュメントも生成されるからです。
現時点では、MySQLとPostgreSQLアダプタのみがコメント機能をサポートしています。

### テーブル結合を作成する

マイグレーションの`create_join_table`メソッドはhas_and_belongs_to_many (HABTM) テーブル結合（join）を作成します。典型的な利用法を以下に示します。

```ruby
create_join_table :products, :categories
```

上によって`categories_products`テーブルが作成され、その中に`category_id`カラムと`product_id`カラムが生成されます。これらのカラムには`:null`オプションがあり、デフォルト値は`false`です。`:column_options`オプションを指定すれば、これらを上書きできます。

```ruby
create_join_table :products, :categories, column_options: { null: true }
```

デフォルトでは、`create_join_table`に渡された引数の最初の2つをつなげたものが結合テーブル名になります。
独自のテーブル名を使いたい場合は`:table_name`で指定します。

```ruby
create_join_table :products, :categories, table_name: :categorization
```

上のようにすることで`categorization`テーブルが作成されます。

`create_join_table`はブロックを引数に取ることもできます。これはインデックスを追加したり (インデックスはデフォルトでは作成されません)、カラムを追加するのに使われます。

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### テーブルを変更する

既存のテーブルを変更する`change_table`は、`create_table`とよく似ています。基本的には`create_table`と同じ要領で使いますが、ブロックに対してyieldされるオブジェクトではいくつかのテクニックが利用できます。たとえば次のようになります。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

上のマイグレーションでは`description`と`name`カラムが削除され、stringカラムである`part_number`が作成されてインデックスがそこに追加されます。そして最後に`upccode`カラムをリネームしています。

### カラムを変更する

マイグレーションでは、`remove_column`や`add_column`に加えて`change_column`メソッドも利用できます。

```ruby
change_column :products, :part_number, :text
```

productsテーブル上の`part_number`カラムの種類を`:text`フィールドに変更しています。
`change_column`コマンドはロールバックされない（可逆的でない）点にご注意ください。

`change_column`の他に`change_column_null`メソッドと`change_column_default`メソッドもあり、それぞれnot null制約を変更したりデフォルト値を指定したりするのに使います。

```ruby
change_column_null :products, :name, false
change_column_default :products, :approved, from: true, to: false
```

上のマイグレーションはproductsテーブルの`:name`フィールドに`NOT NULL`制約を設定し、`:approved`フィールドのデフォルト値を`true`から`false`に変更します。

NOTE: 上の`change_column_default`マイグレーションは`change_column_default :products, :approved, false`と書くこともできます。しかし先ほどの例と異なり、マイグレーションは不可逆的になります。

### カラム修飾子

カラムの作成時や変更時に、カラムの修飾子を適用できます。

* `limit`: `string/text/binary/integer`フィールドの最大サイズを設定します。
* `precision`: `decimal`フィールドの精度 (precision) を定義します。この精度は、その数字の総桁数で表されます。
* `scale`: `decimal`フィールドの精度 (スケール: scale) を指定します。この精度は小数点以下の桁数で表されます。
* `polymorphic`: `belongs_to`関連付けで使う`type`カラムを追加します。
* `null`: カラムで`NULL`値を許可または禁止します。
* `default`: カラムでのデフォルト値の設定を許可します。dateなどの動的な値を使う場合は、デフォルト値は最初 (マイグレーションが実行された日付など) にしか計算されないことに注意してください。
* `comment`: カラムにコメントを追加します。

アダプタによっては他にも利用できるオプションがあります。詳細については各アダプタ固有のAPIドキュメントを参照してください。

NOTE: `null`と`default`はコマンドラインで指定できません。

### 外部キー

[参照整合性の保証](#active-recordと参照整合性) に対して外部キー制約を追加することもできます。これは必須ではありません。

```ruby
add_foreign_key :articles, :authors
```

上によって新たな外部キーが`articles`テーブルの`author_id`カラムに追加されます。このキーは`authors`テーブルの`id`カラムを参照します。欲しいカラム名をテーブル名から類推できない場合は、`:column`オプションと`:primary_key`オプションを使えます。

Railsでは、すべての外部キーは`fk_rails_`という名前で始まり、その後ろに`from_table`と`column`から一意に生成された文字列が10文字追加されます。
必要であれば、`:name`オプションを指定することで別の名前を使えます。

NOTE: Active Recordでは単一カラムの外部キーのみがサポートされています。複合外部キーを使う場合は`execute`と`structure.sql`が必要です。詳しくは[スキーマダンプの意義](#スキーマダンプの意義)をご覧ください。

外部キーの削除も以下のように簡単に行えます。

```ruby
# 削除するカラム名の決定をActive Recordに任せる場合
remove_foreign_key :accounts, :branches

# カラムを指定して外部キーを削除する場合
remove_foreign_key :accounts, column: :owner_id

# 名前を指定して外部キーを削除する場合
remove_foreign_key :accounts, name: :special_fk_name
```

### ヘルパーの機能だけでは足りない場合

Active Recordが提供するヘルパーの機能だけでは不十分な場合、`execute`メソッドで任意のSQLを実行できます。


```ruby
Product.connection.execute("UPDATE products SET price = 'free' WHERE 1=1")
```

個別のメソッドの詳細については、APIドキュメントを確認してください。
特に、[`ActiveRecord::ConnectionAdapters::SchemaStatements`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
(`change`、`up`、`down`メソッドで利用可能なメソッドを提供)、[`ActiveRecord::ConnectionAdapters::TableDefinition`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html) (`create_table`で生成されるオブジェクトで利用可能なメソッドを提供)、および[`ActiveRecord::ConnectionAdapters::Table`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html) (`change_table`で生成されるオブジェクトで利用可能なメソッドを提供) を参照してください。

### `change`メソッドを使う

`change`メソッドは、マイグレーションを自作する場合に最もよく使われます。このメソッドを使えば、Active Recordがマイグレーションを逆方向に実行 (ロールバック) する方法を自動的に理解してくれるため、多くの場面で利用できます。現時点では、`change`でサポートされているマイグレーション定義は以下のものだけです。

* `add_column`
* `add_foreign_key`
* `add_index`
* `add_reference`
* `add_timestamps`
* `change_column_default` (`:from`と`:to`の指定は省略できない)
* `change_column_null`
* `create_join_table`
* `create_table`
* `disable_extension`
* `drop_join_table`
* `drop_table` （ブロックを渡さなければならない）
* `enable_extension`
* `remove_column`（型を指定しなければならない）
* `remove_foreign_key`（2番目のテーブルを指定しなければならない）
* `remove_index`
* `remove_reference`
* `remove_timestamps`
* `rename_column`
* `rename_index`
* `rename_table`


ブロックで`change`、`change_default`、`remove`が呼び出されない限り、`change_table`もロールバック可能です。

`remove_column`は、3番目の引数でカラムの型を指定すればロールバック可能になります。元々のカラムオプションも指定しておかないと、ロールバック時にRailsがカラムを再作成できなくなります。

```ruby
remove_column :posts, :slug, :string, null: false, default: ''
```

これ以外のメソッドを使う必要が生じた場合は、`change`メソッドではなく`reversible`メソッドを利用するか、`up`と`down`メソッドを明示的に書くようにしてください。

### `reversible`を使う

マイグレーションが複雑になると、Active Recordがマイグレーションを逆転できないことがあります。`reversible`メソッドを使うことで、マイグレーションを通常どおり実行する場合と逆転する場合の動作を指定できます。たとえば次のようになります。

```ruby
class ExampleMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :distributors do |t|
      t.string :zipcode
    end

    reversible do |dir|
      dir.up do
        # CHECK制約を追加
        execute <<-SQL
          ALTER TABLE distributors
            ADD CONSTRAINT zipchk
              CHECK (char_length(zipcode) = 5) NO INHERIT;
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE distributors
            DROP CONSTRAINT zipchk
        SQL
      end
    end

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end
end
```

`reversible`メソッドを使うことで、各命令を正しい順序で実行できます。前述のマイグレーション例を逆転させた場合、`down`ブロックは必ず`home_page_url`カラムが削除された直後、そして`distributors`テーブルがdropされる直前に実行されます。

自作したマイグレーションがたまたま逆転不可能にするしかない内容の場合、データの一部が失われる可能性があります。そのような場合は、`down`ブロック内で`ActiveRecord::IrreversibleMigration`をraiseできます。こうすることで、誰かが後にマイグレーションを逆転させたときに、実行不可能であることを示すエラーが表示されるようになります。

### `up`/`down`メソッドを使う

`change`の代わりに、従来の`up`メソッドと`down`メソッドを使うこともできます。
`up`メソッドにはスキーマに対する変換方法を記述し、`down`メソッドには`up`メソッドによって行われた変換を逆転する方法を記述する必要があります。つまり、`up`の後に`down`を実行した場合、スキーマが変更されないようにする必要があります。
たとえば、`up`メソッドでテーブルを作成したら、`down`メソッドではそのテーブルを削除する必要があります。`down`メソッド内で行なう変換の順序は、`up`メソッド内で行なうのとは逆順にするのが賢明と言えます。先の`reversible`セクションの例は以下と同等になります。

```ruby
class ExampleMigration < ActiveRecord::Migration [5.0]
  def up
    create_table :distributors do |t|
      t.string :zipcode
    end

    # CHECK制約を追加
    execute <<-SQL
      ALTER TABLE distributors
        ADD CONSTRAINT zipchk
        CHECK (char_length(zipcode) = 5);
    SQL

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end

  def down
    rename_column :users, :email_address, :email
    remove_column :users, :home_page_url

    execute <<-SQL
      ALTER TABLE distributors
        DROP CONSTRAINT zipchk
    SQL

    drop_table :distributors
  end
end
```

マイグレーションが逆転不可能な場合、`down`メソッド内に`ActiveRecord::IrreversibleMigration`エラーを発生させる必要があります。こうすることで、誰かが後にマイグレーションを逆転させたときに、実行不可能であることを示すエラーが表示されるようになります。

### 以前のマイグレーションを逆転する

`revert`メソッドを使って、Active Recordのマイグレーションロールバック (逆転) 機能を利用できます。

```ruby
require_relative '20121212123456_example_migration'

class FixupExampleMigration < ActiveRecord::Migration[5.0]
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert`は、逆転を行う命令を含むブロックを受け取ることもできます。これは、以前のマイグレーションの一部のみを逆転したい場合に便利です。
たとえば、`ExampleMigration`がコミット済みになっており、後になって郵便番号を検証するには`CHECK`制約よりもActive Recordのバリデーションを使う方がよいことに気付いたとしましょう。

```ruby
class DontUseConstraintForZipcodeValidationMigration < ActiveRecord::Migration[5.0]
  def change
    revert do
      # ExampleMigrationのコードをコピー＆ペースト
      reversible do |dir|
        dir.up do
          # CHECK制約を追加
          execute <<-SQL
            ALTER TABLE distributors
              ADD CONSTRAINT zipchk
                CHECK (char_length(zipcode) = 5);
          SQL
        end
        dir.down do
          execute <<-SQL
            ALTER TABLE distributors
              DROP CONSTRAINT zipchk
          SQL
        end
      end

      # 以後のマイグレーションはOK
    end
  end
end
```

`revert`を使わずに同様のマイグレーションを自作することもできますが、その分余計な手間がかかります (`create_table`と`reversible`の順序を逆にし、`create_table`を`drop_table`に置き換え、最後に`up`と`down`を入れ替えます)。
`revert`はこれらを一手に引き受けてくれます。

NOTE: 上のようなチェック制約を追加したい場合は、ダンプのメソッドに`structure.sql`を使わなければなりません。詳しくは[スキーマダンプの意義](#スキーマダンプの意義)をご覧ください。

マイグレーションを実行する
------------------

Railsにはマイグレーションを実行するための`rails`コマンドがいくつか用意されています。

最も手っ取り早くマイグレーションを実行する`rails`コマンドは、ほとんどの場合`rails db:migrate`でしょう。このタスクは、基本的にこれまで実行されたことのない`change`または`up`メソッドを実行します。未実行のマイグレーションがない場合は何もせずに終了します。マイグレーションの実行順序は、マイグレーションの日付に基づきます。

`db:migrate`タスクを実行すると、`db:schema:dump`コマンドも同時に呼び出される点にご注意ください。このコマンドは`db/schema.rb`スキーマファイルを更新し、スキーマがデータベースの構造に一致するようにします。

マイグレーションの特定のバージョンを指定すると、Active Recordは指定されたマイグレーションに達するまでマイグレーション (change/up/down) を実行します。マイグレーションのバージョンは、マイグレーションファイル名の冒頭に付いている数字で表されます。たとえば、20080906120000というバージョンまでマイグレーションしたい場合は、以下を実行します。

```bash
$ rails db:migrate VERSION=20080906120000
```

20080906120000というバージョンが現在のバージョンより大きい場合 (新しい方に進む通常のマイグレーションなど)、20080906120000に到達するまで (このマイグレーション自身も実行対象に含まれます) のすべてのマイグレーションの`change` (または`up`) メソッドを実行し、それより先のマイグレーションは行いません。過去に遡るマイグレーションの場合、20080906120000に到達するまでのすべてのマイグレーションの`down`メソッドを実行しますが、上と異なり、20080906120000自身は含まれない点にご注意ください。

### ロールバック

直前に行ったマイグレーションをロールバックする作業はよく発生します。たとえば、マイグレーションに誤りがあって訂正したい場合などです。この場合、バージョン番号を調べて明示的にロールバックを実行しなくても、次を実行するだけで済みます。

```bash
$ rails db:rollback
```

これにより、直前のマイグレーションがロールバックされます。`change`メソッドを逆転実行するか`down`メソッドを実行します。マイグレーションを複数ロールバックしたい場合は、`STEP`パラメータを指定できます。

```bash
$ rails db:rollback STEP=3
```

これにより、最後に行った3つのマイグレーションがロールバックされます。

`db:migrate:redo`コマンドは、ロールバックと再マイグレーションを一度に実行できるショートカットです。複数バージョンに対してこれを行いたい場合は、`db:rollback`コマンドの場合と同様に`STEP`パラメータを指定することもできます。

```bash
$ rails db:migrate:redo STEP=3
```

ただし、`db:migrate`で実行できないコマンドをこれらのコマンドで実行することはできません。これらは単に、バージョンを明示的に指定しなくて済むように`db:migrate`タスクを使いやすくしたものに過ぎません。

### データベースを設定する

`bin/rails db:setup`コマンドは、データベースの作成、スキーマの読み込み、シードデータを用いてデータベースの初期化を実行します。

### データベースをリセットする

`bin/rails db:reset`コマンドは、データベースをdropして再度設定します。このコマンドは`rails db:drop db:setup`と同等です。

NOTE: このコマンドは、すべてのマイグレーションを実行することと等価ではありません。このコマンドでは現在の`schema.rb`の内容をそのまま使い回しているためです。マイグレーションをロールバックできなくなった場合には、`rails db:reset`を実行しても復旧できないことがあります。スキーマダンプの詳細については、[スキーマダンプの意義](#スキーマダンプの意義) セクションを参照してください。

### 特定のマイグレーションのみを実行する

特定のマイグレーションをupまたはdown方向に実行する必要がある場合は、`db:migrate:up`または`db:migrate:down`タスクを使います。以下に示したように、適切なバージョン番号を指定するだけで、該当するマイグレーションに含まれる`change`、`up`、`down`メソッドのいずれかが呼び出されます。

```bash
$ rails db:migrate:up VERSION=20080906120000
```

上を実行すると、バージョン番号が20080906120000のマイグレーションに含まれる`change`メソッド (または`up`メソッド) が実行されます。このコマンドは、最初にそのマイグレーションが実行済みであるかどうかをチェックし、Active Recordによって実行済みであると認定された場合は何も行いません。

### 異なる環境でマイグレーションを実行する

デフォルトでは、`rails db:migrate`は`development`環境で実行されます。
他の環境に対してマイグレーションを行いたい場合は、コマンド実行時に`RAILS_ENV`環境変数を指定します。たとえば、`test`環境でマイグレーションを実行する場合は以下のようにします。

```bash
$ rails db:migrate RAILS_ENV=test
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
| suppress_messages | 引数としてブロックを1つ取り、そのブロックによって生成される出力をすべて抑制する。 |
| say | 引数としてメッセージを1つ受け取り、それをそのまま出力する。2番目の引数として、出力をインデントするかどうかを指定するbooleanを与えられる。 |
| say_with_time | 受け取ったブロックを実行するのにかかった時間を示すテキストを出力する。ブロックが整数を1つ返す場合、影響を受けた行数であるとみなす。 |

以下のマイグレーションを例に説明します。

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
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

Active Recordから何も出力したくない場合は、`bin/rails db:migrate VERBOSE=false`を実行することで出力を完全に抑制できます。

既存のマイグレーションを変更する
----------------------------

マイグレーションを自作していると、ときにはミスしてしまうこともあります。いったんマイグレーションを実行してしまった後では、既存のマイグレーションを単に編集してもう一度マイグレーションをやり直しても意味がありません。Railsはマイグレーションが既に実行済みであると認識しているので、`rails db:migrate`を実行しても何も変更されません。このような場合には、マイグレーションをいったんロールバック (`rails db:rollback`など) してからマイグレーションを修正し、それから修正の完了したバージョンのマイグレーションを実行するために`bin/rails db:migrate`を実行する必要があります。

そもそも、既存のマイグレーションを直接変更するのは一般的によくありません。既存のマイグレーションを変更すると、自分どころか共同作業者にまで余分な作業を強いることになります。さらに、既存のマイグレーションが本番環境で実行中の場合、ひどい頭痛の種になるでしょう。既存のマイグレーションを直接修正するのではなく、そのためのマイグレーションを新たに作成してそれを実行するのが正しい方法です。これまでコミットされてない (より一般的に言えば、これまでdevelopment環境以外に展開されたことのない) マイグレーションを新たに生成し、それを編集するのが害の少ない方法であると言えます。

`revert`メソッドは、以前のマイグレーション全体またはその一部を取り消すためのマイグレーションを新たに書くときにも便利です (前述の[以前のマイグレーションを逆転する](#以前のマイグレーションを逆転する)を参照してください)。

スキーマダンプの意義
----------------------

### スキーマファイルの意味について

Railsのマイグレーションは強力ではありますが、データベースのスキーマを作成するための信頼できる情報源ではありません。信頼できる情報源は、やはりデータベースです。Railsは、デフォルトでデータベーススキーマの最新の状態のキャプチャを試みる`db/schema.rb`を生成します。

アプリケーションのデータベースの新しいインスタンスを作成する場合、マイグレーションの全履歴を一から繰り返すよりも、`rails db:schema:load`でスキーマファイルを読み込む方が、高速かつエラーが起きにくい傾向があります。
[古いマイグレーション](#古いマイグレーション)は、その中で外部への依存性が変更されたり、マイグレーションとは独自の進化を遂げたアプリケーションコードに依存していたりすると、正しく適用できなくなる可能性があります。

スキーマファイルは、Active Recordのオブジェクトにどのような属性があるのかを概観するのにも便利です。スキーマ情報はモデルのコードの中にはありません。スキーマ情報は多くのマイグレーションに分かれて存在しており、そのままでは非常に探しにくいものですが、この情報はスキーマファイルにコンパクトに収まっています。

### スキーマダンプの種類

Railsで生成されるスキーマダンプのフォーマットは、`config/application.rb`の`config.active_record.schema_format`設定で制御されます。デフォルトのフォーマットは`:ruby`ですが、`:sql`も指定できます。

`:ruby`を指定すると、スキーマは`db/schema.rb`に保存されます。このファイルを開いてみると、1つの巨大なマイグレーションのように見えるはずです。

```ruby
ActiveRecord::Schema.define(version: 2008_09_06_171750) do
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
    t.string.  "part_number"
  end
end
```

このスキーマ情報は、見てのとおりその内容を単刀直入に表しています。このファイルは、データベースを詳細に検査し、`create_table`や`add_index`などでその構造を表現することによって作成されています。

`db/schema.rb`では、トリガ/シーケンス/ストアドプロシージャ/チェック制約などのデータベース固有の項目を表現できません。マイグレーションで`execute`を用いれば、RubyマイグレーションDSLでサポートされないデータベース構造も作成できますが、そうしたステートメントはスキーマダンプで再構成されない点にご注意ください。これらの機能が必要な場合は、新しいデータベースインスタンスの作成に有用なスキーマファイルを正確に得るためにスキーマのフォーマットを`:sql`にする必要があります。

スキーマフォーマットを`:sql`にすると、データベース固有のツールを用いてデータベースの構造を`db/structure.sql`にダンプします。たとえばPostgreSQLの場合は`pg_dump`ユーティリティが使われます。MySQLやMariaDBの場合は、多くのテーブルにおいて`SHOW CREATE TABLE`の出力結果がファイルに含まれます。

スキーマを`db/structure.sql`から読み込む場合、`rails db:structure:load`を実行します。これにより、含まれているSQL文が実行されてファイルが読み込まれます。定義上、これによって作成されるデータベース構造は元の完全なコピーとなります。

### スキーマダンプとソースコード管理

上述の通り、スキーマダンプはデータベーススキーマの情報源として信頼するに足るものです。従って、スキーマファイルをGitなどのソースコード管理の対象に加えることを強く推奨します。

`db/schema.rb`にはデータベースの現在のバージョン番号が含まれています。これにより、ソースコード管理の異なるブランチでスキーマが変更されていた場合に、両者をマージすると競合が発生していることが警告されるというメリットもあります。スキーマの競合が発生した場合は手動で解決し、数字の大きい方のバージョン番号を保持する必要があります。

Active Recordと参照整合性
---------------------------------------

Active Recordは、「知的に振る舞うのはモデルであり、データベースではない」というコンセプトに基づいています。そして実際、トリガーや制約などの高度なデータベース機能はそれほど使われていません。

`validates :foreign_key, uniqueness: true`のようなデータベース検証機能は、データ整合性の強制をモデルが行っている1つの例です。モデルに関連付けの`:dependent`オプションを指定すると、親オブジェクトが削除されたときに子オブジェクトも自動的に削除されます。アプリケーションレベルで実行される他のものと同様、モデルのこうした機能だけでは参照整合性を維持できないため、データベースの[外部キー制約](#外部キー)を用いて参照整合性を高める開発者もいます。

Active Recordだけではこうした外部機能を扱うツールをすべて提供することはできませんが、`execute`メソッドを使えば任意のSQLを実行できます。

マイグレーションとシードデータ
------------------------

Railsのマイグレーション機能の主要な目的は、スキーマ変更のコマンドを一貫した手順で発行できるようにすることですが、データの追加や変更に使うこともできます。これは、productionのデータベースのような削除や再作成を行えない既存データベースで便利です。

```ruby
class AddInitialProducts < ActiveRecord::Migration[5.0]
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

Railsには、データベース作成後に初期データを素早く簡単に追加するための`seed`機能があります。シードは、development環境やtest環境で頻繁にデータを再読込する場合に特に便利です。
シード機能は、`db/seeds.rb`にRubyコードを記述して`rails db:seed`を実行するだけで簡単に使えます。

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

この方法なら、マイグレーションよりもずっとクリーンに空のアプリケーションのデータベースを設定できます。


古いマイグレーション
--------------

`db/schema.rb`や`db/structure.sql`は、使っているデータベースの最新ステートのスナップショットであり、そのデータベースを再構築するための情報源として信頼できます。このことを頼りにして、古いマイグレーションファイルを削除できます。

`db/migrate/`ディレクトリ内のマイグレーションファイルを削除しても、マイグレーションファイルが存在していたときに`rails db:migrate`が実行されたあらゆる環境は、Rails内部の`schema_migrations`という名前のデータベース内に保存されている（マイグレーションファイル固有の）マイグレーションタイムスタンプへの参照を保持し続けます。このテーブルは、特定の環境でマイグレーションが実行されたことがあるかどうかをトラッキングするのに用いられます。

マイグレーションファイルを削除した状態で`rails db:migrate:status`コマンド（本来マイグレーションのステータス（upまたはdown）を表示する）を実行すると、削除したマイグレーションファイルの後に`********** NO FILE **********`と表示されるでしょう。これは、そのマイグレーションファイルが特定の環境で一度実行されたが、`db/migrate/`ディレクトリの下に見当たらない場合に表示されます。
