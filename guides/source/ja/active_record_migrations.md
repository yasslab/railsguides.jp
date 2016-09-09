
Active Record マイグレーション
========================

マイグレーション (migration) はActive Recordの機能の1つであり、データベーススキーマを長期にわたって安定して発展・増築し続けることができるようにするための仕組みです。マイグレーション機能のおかげで、Rubyで作成されたマイグレーション用のDSL (ドメイン固有言語) を使用して、テーブルの変更を簡単に記述できます。スキーマを変更するためにSQLを直に書いて実行する必要がありません。

このガイドの内容:

* マイグレーション作成で使用できるジェネレータ
* Active Recordが提供するデータベース操作用メソッド群の解説
* マイグレーション実行とスキーマ更新用のRakeタスクの解説
* マイグレーションとスキーマファイル`schema.rb`の関係

--------------------------------------------------------------------------------

マイグレーションの概要
------------------

マイグレーションは、[データベーススキーマの継続的な変更](http://en.wikipedia.org/wiki/Schema_migration) (英語) を、統一的かつ簡単に行なうための便利な手法です。マイグレーションではRubyのDSLを使用しているので、生のSQLを作成する必要がなく、スキーマとスキーマへの変更をデータベースの種類に依存せずに済みます。

1つ1つのマイグレーションは、データベースの新しい'version'とみなすことができます。スキーマは最初空の状態から始まり、マイグレーションによる変更が加わるたびにテーブル、カラム、エントリが追加または削除されます。Active Recordは時系列に沿ってスキーマを更新する方法を知っているので、履歴のどの時点からでも最新バージョンのスキーマに更新することができます。Active Recordは`db/schema.rb`ファイルを更新し、データベースの最新の構造と一致するようにします。

マイグレーションの例を以下に示します。

```ruby
class CreateProducts < ActiveRecord::Migration
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

スキーマ変更のステートメントが使用できるトランザクションをサポートするデータベースでは、マイグレーションはトランザクションの内側にラップされて実行されます。これらがデータベースでサポートされていない場合は、マイグレーション中に一部が失敗した場合にロールバックされません。その場合は、変更を手動でロールバックする必要があります。

NOTE: ある種のクエリは、トランザクション内で実行できないことがあります。アダプタがDDLトランザクションをサポートしている場合は、`disable_ddl_transaction!`を使用して単一のマイグレーションでこれらを無効にすることができます。

マイグレーションを逆方向に実行 (ロールバック) する方法が推測できない場合、`reversible` を使用します。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
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

`change`の代りに`up`と`down`を使用することもできます。

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
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

タイムスタンプを算出する作業は楽しいものではありませんので、Active Recordにはこれらを扱うためのジェネレータが用意されています。

```bash
$ bin/rails generate migration AddPartNumberToProducts
```

これによって生成されるマイグレーションは中身が空ですが、適切な名前が付けられています。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

マイグレーション名が"AddXXXToYYY"や"RemoveXXXFromYYY"の形式になっており、その後にカラム名と種類が続いていれば、マイグレーション内に適切な`add_column`文と`remove_column`文が作成されます。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string
```

上を実行すると以下が生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
  end
end
```

新しいカラムにインデックスを追加したい場合は以下のようにします。

```bash
$ bin/rails generate migration AddPartNumberToProducts part_number:string:index
```

上を実行すると以下が生成されます。

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
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

上を実行すると以下が生成されます。

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :part_number, :string
  end
end
```

自動で生成できるカラムは1つだけではありません。たとえば次のようになります。

```bash
$ bin/rails generate migration AddDetailsToProducts part_number:string price:decimal
```

上を実行すると以下が生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

マイグレーション名が"CreateXXX"のような形式であり、その後にカラム名と種類が続く場合、XXXという名前のテーブルが作成され、指定の種類のカラム名がその中に生成されます。たとえば次のようになります。

```bash
$ bin/rails generate migration CreateProducts name:string part_number:string
```

上を実行すると以下が生成されます。

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
    end
  end
end
```

これまでと同様、ここまでに生成した内容は単なる出発点でしかありません。`db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb`ファイルを編集して、項目の追加や削除を行なうことができます。

同様に、カラムの種類として`references` (`belongs_to` も可) を指定することができます。たとえば次のようになります。

```bash
$ bin/rails generate migration AddUserRefToProducts user:references
```

上を実行すると以下が生成されます。

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

このマイグレーションを実行すると、`user_id`が作成され、適切なインデックスが追加されます。

名前の一部に`JoinTable`が含まれているとテーブル結合を生成するジェネレータもあります。

```bash
$ bin/rails g migration CreateJoinTableCustomerProduct customer product
```

上によって以下のマイグレーションが生成されます。

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration
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
$ bin/rails generate model Product name:string description:text
```

このとき、以下のようなマイグレーションが作成されます。

```ruby
class CreateProducts < ActiveRecord::Migration
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

コマンドラインである種の[型修飾子](#カラム修飾子) を直接渡すこともできます。これらは波かっこで囲まれ、後ろにフィールドの種類が追加されます。

たとえば以下を実行したとします。

```bash
$ bin/rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

これによって以下のようなマイグレーションが生成されます。

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

TIP: 詳細についてはジェネレータのヘルプを参照してください。

マイグレーションを自作する
-------------------

ジェネレータでマイグレーションを作成できるようになったら、今度は自分で作成してみましょう。

### テーブルを作成する

`create_table`メソッドは最も基本的なメソッドであり、ほとんどの場合モデルやscaffoldの生成時に使用されます。典型的な利用法を以下に示します。

```ruby
create_table :products do |t|
  t.string :name
end
```

上によって`products`テーブルが生成され、`name`という名前のカラムがその中に作成されます (`id`というカラムも暗黙で生成されますが、これについては後述します)。

デフォルトでは、`create_table`によって`id`という名前の主キーが作成されます。`:primary_key`オプションを指定することで、主キー名を変更することもできます (その場合は必ず対応するモデル名を変更してください)。 主キーを使用したくない場合は`id: false`オプションを指定することもできます。特定のデータベースで使用するオプションが必要な場合は、`:options`オプションに続けてSQLフラグメントを記述します。たとえば次のようになります。

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

上のマイグレーションでは、テーブルを生成するSQLステートメントに`ENGINE=BLACKHOLE`を指定しています (MySQLを使用する場合、デフォルトは`ENGINE=InnoDB`です)。

### テーブル結合を作成する

マイグレーションの`create_join_table`メソッドはhas_and_belongs_to_many (HABTM) テーブル結合を作成します。典型的な利用法を以下に示します。

```ruby
create_join_table :products, :categories
```

上によって`categories_products`テーブルが作成され、その中に`category_id`カラムと`product_id`カラムが生成されます。これらのカラムには`:null`オプションがあり、デフォルト値は`false`です。`:column_options`オプションを指定することでこれらを上書きできます。

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

上によって`product_id`と`category_id`が作成され、`:null`が`true`に設定されます。

テーブル名をカスタマイズしたい場合は`:table_name`オプションを渡すこともできます。たとえば次のようになります。

```ruby
create_join_table :products, :categories, table_name: :categorization
```

上のようにすることで`categorization`テーブルが作成されます。

`create_join_table`はブロックを引数に取ることもできます。これはインデックスを追加したり (インデックスはデフォルトでは作成されません)、カラムを追加するのに使用されます。

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### テーブルを変更する

既存のテーブルを変更する`change_table`は、`create_table`とよく似ています。基本的には`create_table`と同じ要領で使用しますが、ブロックに対してyieldされるオブジェクトではいくつかのテクニックが使用できます。たとえば次のようになります。

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

`change_column`の他に`change_column_null`メソッドと`change_column_default`メソッドもあり、それぞれnot null制約を変更したりデフォルト値を指定したりするのに使用します。

```ruby
change_column_null :products, :name, false
change_column_default :products, :approved, false
```

上のマイグレーションはproductsテーブルの`:name`フィールドに`NOT NULL`制約を設定し、`:approved`フィールドのデフォルト値をfalseに設定します。

TIP: `change_column` (および`change_column_default`) と異なる点は、`change_column_null`が可逆的であることです。

### カラム修飾子

カラムの作成または変更時に、カラムの修飾子を適用できます。

* `limit` - `string/text/binary/integer`フィールドの最大サイズを設定します。
* `precision` - `decimal`フィールドの精度 (precision) を定義します。この精度は、その数字の総桁数で表されます。
* `scale` - `decimal`フィールドの精度 (スケール: scale) を指定します。この精度は小数点以下の桁数で表されます。
* `polymorphic` - `belongs_to`関連付けで使用する`type`カラムを追加します。
* `null` - カラムで`NULL`値を許可または禁止します。
* `default` - カラムでのデフォルト値の設定を許可します。dateなどの動的な値を使用している場合は、デフォルト値は最初 (マイグレーションが実行された日付など) にしか計算されないことに注意してください。
* `index` - カラムにインデックスを追加します。

アダプタによってはこの他にも使用できるオプションがあるものもあります。詳細については各アダプタ固有のAPIドキュメントを参照してください。

### 外部キー

[参照整合性の保証](#active-recordと参照整合性) に対して外部キー制約を追加することもできます。これは必須ではありません。

```ruby
add_foreign_key :articles, :authors
```

上によって新たな外部キーが`articles`テーブルの`author_id`カラムに追加されます。このキーは`authors`テーブルの`id`カラムを参照します。欲しいカラム名をテーブル名から類推できない場合は、`:column`オプションと`:primary_key`オプションを使用できます。

Railsでは、すべての外部キーは`fk_rails_`という名前で始まり、その後ろに10文字のランダムな文字列が続きます。
必要であれば、`:name`オプションを指定することで別の名前を使用できます。

NOTE: Active Recordでは単一カラムの外部キーのみがサポートされています。複合外部キーを使用する場合は`execute`と`structure.sql`が必要です。

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

Active Recordが提供するヘルパーの機能だけでは不十分な場合、`execute`メソッドを使用して任意のSQLを実行できます。

```ruby
Product.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

個別のメソッドの詳細については、APIドキュメントを確認してください。
特に、[`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
(`change`、`up`、`down`メソッドで利用可能なメソッドを提供)、[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html) (`create_table`で生成されるオブジェクトで使用可能なメソッドを提供)、および[`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html) (`change_table`で生成されるオブジェクトで使用可能なメソッドを提供) を参照ください。

### `change`メソッドを使用する

`change`メソッドは、マイグレーションを自作する場合に最もよく使用されます。このメソッドを使用すれば、Active Recordがマイグレーションを逆方向に実行 (ロールバック) する方法を自動的に理解してくれるため、多くの場面で使用できます。現時点では、`change`でサポートされているマイグレーション定義は以下のものだけです。

* `add_column`
* `add_index`
* `add_reference`
* `add_timestamps`
* `add_foreign_key`
* `create_table`
* `create_join_table`
* `drop_table` (ブロックを渡す必要あり)
* `drop_join_table` (ブロックを渡す必要あり)
* `remove_timestamps`
* `rename_column`
* `rename_index`
* `remove_reference`
* `rename_table`

`change_table`の逆転は、`change`、`change_default`、`remove`が呼び出されない限り可能です。

これ以外のメソッドを使用する必要が生じた場合は、`change`メソッドではなく`reversible`メソッドを利用するか、`up`と`down`メソッドを明示的に書くようにしてください。

### `reversible`を使用する

マイグレーションが複雑になると、Active Recordがマイグレーションを逆転できないことがあります。`reversible`メソッドを使用することで、マイグレーションを通常どおり実行する場合と逆転する場合の動作を指定できます。たとえば次のようになります。

```ruby
class ExampleMigration < ActiveRecord::Migration
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

`reversible`メソッドを使用することで、各命令を正しい順序で実行できます。前述のマイグレーション例を逆転させた場合、`down`ブロックは必ず`home_page_url`カラムが削除された直後、そして`distributors`テーブルがdropされる直前に実行されます。

自作したマイグレーションがたまたま逆転不可能にするしかない内容の場合、データの一部が失われる可能性があります。そのような場合は、`down`ブロック内で`ActiveRecord::IrreversibleMigration`をレイズできます。こうすることで、誰かが後にマイグレーションを逆転させたときに、実行不可能であることを示すエラーが表示されるようになります。

### `up`/`down`メソッドを使用する

`change`の代りに、従来の`up`メソッドと`down`メソッドを使用することもできます。
`up`メソッドにはスキーマに対する変換方法を記述し、`down`メソッドには`up`メソッドによって行われた変換を逆転する方法を記述する必要があります。つまり、`up`の後に`down`を実行した場合、スキーマが変更されないようにする必要があります。たとえば、`up`メソッドでテーブルを作成したら、`down`メソッドではそのテーブルを削除する必要があります。`down`メソッド内で行なう変換の順序は、`up`メソッド内で行なうのと逆の順序にするのが賢明と言えます。先の`reversible`セクションの例は以下と同等になります。

```ruby
class ExampleMigration < ActiveRecord::Migration
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

マイグレーションが逆転不可能な場合、`down`メソッド内に`ActiveRecord::IrreversibleMigration`を記述しておく必要があります。こうすることで、誰かが後にマイグレーションを逆転させたときに、実行不可能であることを示すエラーが表示されるようになります。

### 以前のマイグレーションを逆転する

`revert`メソッドを使用することで、Active Recordのマイグレーションロールバック (逆転) 機能を使用できます。

```ruby
require_relative '2012121212_example_migration'

class FixupExampleMigration < ActiveRecord::Migration
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert`はブロックを受け取ることもできます。ブロックには逆転のための命令群が含まれます。
これは、以前のマイグレーションの一部のみを逆転したい場合に便利です。
たとえば、`ExampleMigration`がコミット済みになっており、後になって郵便番号を検証するには`CHECK`制約よりもActive Recordのバリデーションを使う方がよいことに気付いたとしましょう。

```ruby
class DontUseConstraintForZipcodeValidationMigration < ActiveRecord::Migration
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

`revert`を使用せずに同様のマイグレーションを自作することもできますが、その分余計な手間がかかります (`create_table`と`reversible`の順序を逆にし、`create_table`を`drop_table`に置き換え、最後に`up`と`down`を入れ替えます)。
`revert`はこれらを一手に引き受けてくれます。

マイグレーションを実行する
------------------

Railsにはマイグレーションを実行するためのRakeタスクがいくつか用意されています。

最も手っ取り早くマイグレーションを実行するRakeタスクは、ほとんどの場合`bin/rails db:migrate`でしょう。このRakeタスクは、基本的にこれまで実行されたことのない`change`または`up`メソッドを実行します。未実行のマイグレーションがない場合は何もせずに終了します。マイグレーションの実行順序は、マイグレーションの日付に基づきます。

`db:migrate`タスクを実行すると、`db:schema:dump`タスクも同時に呼び出される点にご注意ください。このタスクは`db/schema.rb`スキーマファイルを更新し、スキーマがデータベースの構造に一致するようにします。

マイグレーションの特定のバージョンを指定すると、Active Recordは指定されたマイグレーションに達するまでマイグレーション (change/up/down) を実行します。マイグレーションのバージョンは、マイグレーションファイル名の冒頭に付いている数字で表されます。たとえば、20080906120000というバージョンまでマイグレーションしたい場合は、以下を実行します。

```bash
$ bin/rails db:migrate VERSION=20080906120000
```

20080906120000というバージョンが現在のバージョンより大きい場合 (新しい方に進む通常のマイグレーションなど)、20080906120000に到達するまで (このマイグレーション自身も実行対象に含まれます) のすべてのマイグレーションの`change` (または`up`) メソッドを実行し、それより先のマイグレーションは行いません。過去に遡るマイグレーションの場合、20080906120000に到達するまでのすべてのマイグレーションの`down`メソッドを実行しますが、上と異なり、20080906120000自身は含まれない点にご注意ください。

### ロールバック

直前に行ったマイグレーションをロールバックする作業はよく発生します。たとえば、マイグレーションに誤りがあって訂正したい場合などです。この場合、バージョン番号を調べて明示的にロールバックを実行しなくても、次を実行するだけで済みます。

```bash
$ bin/rails db:rollback
```

これにより、直前のマイグレーションがロールバックされます。`change`メソッドを逆転実行するか`down`メソッドを実行します。マイグレーションを複数ロールバックしたい場合は、`STEP`パラメータを指定できます。

```bash
$ bin/rails db:rollback STEP=3
```

これにより、最後に行った3つのマイグレーションがロールバックされます。

`db:migrate:redo`タスクは、ロールバックと再マイグレーションを一度に実行できるショートカットです。複数バージョンに対してこれを行いたい場合は、`db:rollback`タスクの場合と同様に`STEP`パラメータを指定することもできます。

```bash
$ bin/rails db:migrate:redo STEP=3
```

ただし、`db:migrate`で実行できないタスクをこれらのタスクで実行することはできません。これらは単に、バージョンを明示的に指定しなくて済むように`db:migrate`タスクを使いやすくしたものに過ぎません。

### データベースを設定する

`bin/rails db:setup`タスクは、データベースの作成、スキーマの読み込み、シードデータを使用したデータベースの初期化を実行します。

### データベースをリセットする

`bin/rails db:reset`タスクは、データベースをdropして再度設定します。このタスクは、`bin/rails db:drop db:setup`と同等です。

NOTE: このタスクは、すべてのマイグレーションを実行することと等価ではありません。このタスクでは現在の`schema.rb`の内容をそのまま使い回しているためです。マイグレーションをロールバックできなくなった場合には、`bin/rails db:reset`を実行しても復旧できないことがあります。スキーマダンプの詳細については、[スキーマダンプの意義](#スキーマダンプの意義) セクションを参照してください。

### 特定のマイグレーションのみを実行する

特定のマイグレーションをupまたはdown方向に実行する必要がある場合は、`db:migrate:up`または`db:migrate:down`タスクを使用します。以下に示したように、適切なバージョン番号を指定するだけで、該当するマイグレーションに含まれる`change`、`up`、`down`メソッドのいずれかが呼び出されます。

```bash
$ bin/rails db:migrate:up VERSION=20080906120000
```

上を実行すると、バージョン番号が20080906120000のマイグレーションに含まれる`change`メソッド (または`up`メソッド) が実行されます。このタスクは、最初にそのマイグレーションが実行済みであるかどうかをチェックし、Active Recordによって実行済みであると認定された場合は何も行いません。

### 異なる環境でマイグレーションを実行する

デフォルトでは、`bin/rails db:migrate`は`development`環境で実行されます。
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

| メソッド               | 目的
| -------------------- | -------
| suppress_messages    | 引数としてブロックを1つ取り、そのブロックによって生成される出力をすべて抑制する。
| say                  | 引数としてメッセージを1つ受け取り、それをそのまま出力する。2番目の引数として、出力をインデントするかどうかを指定するbooleanを与えられる。
| say_with_time        | 受け取ったブロックを実行するのにかかった時間を示すテキストを出力する。ブロックが整数を1つ返す場合、影響を受けた行数であるとみなす。

以下のマイグレーションを例に説明します。

```ruby
class CreateProducts < ActiveRecord::Migration
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

マイグレーションを自作していると、ときにはミスしてしまうこともあります。いったんマイグレーションを実行してしまった後では、既存のマイグレーションを単に編集してもう一度マイグレーションをやり直しても意味がありません。Railsはマイグレーションが既に実行済みであると認識しているので、`bin/rails db:migrate`を実行しても何も変更されません。このような場合には、マイグレーションをいったんロールバック (`bin/rails db:rollback`など) してからマイグレーションを修正し、それから修正の完了したバージョンのマイグレーションを実行するために`bin/rails db:migrate`を実行する必要があります。

そもそも、既存のマイグレーションを直接変更するのは一般的によい方法とは言えません。既存のマイグレーションを変更すると、自分どころか共同作業者にまで余分な作業を強いることになります。さらに、既存のマイグレーションが本番環境で実行中の場合、ひどい頭痛の種になるでしょう。既存のマイグレーションを直接修正するのではなく、そのためのマイグレーションを新たに作成してそれを実行するのが正しい方法です。これまでコミットされてない (より一般的に言えば、これまでdevelopment環境以外に展開されたことのない) マイグレーションを新たに生成し、それを編集するのが害の少ない方法であると言えます。

`revert`メソッドは、以前のマイグレーション全体またはその一部を取り消すためのマイグレーションを新たに書くときにも便利です (前述の[以前のマイグレーションを逆転する](#以前のマイグレーションを逆転する)を参照してください)。

スキーマダンプの意義
----------------------

### スキーマファイルの意味について

Railsのマイグレーションはあまりに強力であるため、データベースのスキーマを作成するための信頼できる情報源とするには適切ではありません。スキーマ情報は、`db/schema.rb`か、Active Recordがデータベースを検査することによって生成されるSQLファイルのどちらかを元にすることになります。これらのファイルは単にデータベースの現在の状態を表すものであり、開発者が編集するものではありません。

アプリケーションの新しいインスタンスをデプロイするときに、膨大なマイグレーション履歴をすべて再実行する必要はありません。むしろ、そのようなことをすると逆にエラーが発生しやすくなるでしょう。単に現在のスキーマの記述をデータベースに読み込む方がはるかに簡潔かつ高速です。

例として、Railsでtest環境のデータベースを作成するときの方法を説明します。現在のdevelopmentデータベースからいったん`db/schema.rb`または`db/structure.sql`にダンプされ、続いてtest環境のデータベースに読み込まれます。

スキーマファイルは、Active Recordのオブジェクトにどのような属性があるのかを概観するのにも便利です。スキーマ情報はモデルのコードの中にはありません。スキーマ情報は多くのマイグレーションに分かれて存在しており、そのままでは非常に探しにくいものですが、この情報はスキーマファイルにコンパクトに収まっています。なお、[annotate_models](https://github.com/ctran/annotate_models) gemを使用すると、モデルファイルの冒頭にスキーマ情報の要約コメントが自動的に追加・更新されるようになるので便利です。

### スキーマダンプの種類

スキーマのダンプ方法は2種類あります。ダンプ方法は`config/application.rb`の`config.active_record.schema_format`で設定します。`:sql`または`:ruby`を指定できます。

`:ruby`を指定すると、スキーマは`db/schema.rb`に保存されます。このファイルを開いてみると、1つの巨大なマイグレーションのように見えるはずです。

```ruby
ActiveRecord::Schema.define(version: 20080906171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "part_number"
  end
end
```

このスキーマ情報は、見てのとおりその内容を単刀直入に表しています。このファイルは、データベースを詳細に検査し、`create_table`や`add_index`などでその構造を表現することによって作成されています。このスキーマ情報はデータベースの種類に依存しないため、Active Recordがサポートしているデータベースであればどんなものにでも読み込むことができます。この特性は、複数の種類のデータベースを実行できるアプリケーションを展開する必要がある場合に特に有用です。

このような有用な特性を得られる代りに、1つの代償があります。当然ながら、`db/schema.rb`にはデータベース固有の項目 (トリガーやストアドプロシージャなど) を含めることはできません。マイグレーションにはカスタムSQLを含めることはできますが、スキーマをダンプするときにデータベースからこの構文を再構成することはできないのです。データベース固有の機能を使用するのであれば、スキーマのフォーマットを`:sql`にする必要があります。

この場合、Active Recordのスキーマダンプを使用する代りに、データベース固有のツールを使用してデータベースの構造を`db/structure.sql`にダンプします (`db:structure:dump` Rakeタスクを使用します)。たとえばPostgreSQLの場合は`pg_dump`ユーティリティが使用されます。MySQLの場合は、多くのテーブルにおいて`SHOW CREATE TABLE`の出力結果がファイルに含まれます。

これらのスキーマの読み込みは、そこに含まれるSQL文を実行するだけの非常にシンプルなものです。定義上、これによってデータベース構造の完全なコピーが作成されます。その代わり、`:sql`スキーマフォーマットを使用した場合は、そのスキーマを作成したRDBMS以外では読み込めないという制限が生じます。

### スキーマダンプとソースコード管理

上述の通り、スキーマダンプはデータベーススキーマの情報源として信頼するに足るものです。従って、スキーマファイルをGitなどのソースコード管理の対象に加えることを強く推奨します。

`db/schema.rb`にはデータベースの現在のバージョン番号が含まれています。これにより、ソースコード管理の異なるブランチでスキーマが変更されていた場合に、両者をマージすると競合が発生していることが警告されるというメリットもあります。スキーマの競合が発生した場合は手動で解決し、数字の大きい方のバージョン番号を保持する必要があります。

Active Recordと参照整合性
---------------------------------------

Active Recordは、知的に動作すべきはモデルであり、データベースではないというコンセプトに基づいています。そして実際、トリガーや制約などの高度なデータベース機能はそれほど使用されていません。

`validates :foreign_key, uniqueness: true`のようなデータベース検証機能は、データ整合性の強制をモデルが行っている1つの例です。モデルに関連付けの`:dependent`オプションを指定すると、親オブジェクトが削除されたときに子オブジェクトも自動的に削除されます。アプリケーションレベルで実行される他のものと同様、モデルのこうした機能だけでは参照整合性を維持できないため、データベースの[外部キー制約](#外部キー)を使用して参照整合性を増大させる開発者もいます。

Active Recordだけではこうした外部機能を扱うツールをすべて提供することはできませんが、`execute`メソッドを使用して任意のSQLを実行することができます。

マイグレーションとシードデータ
------------------------

データベースにデータを追加するのにマイグレーションが使用されることがあります。

```ruby
class AddInitialProducts < ActiveRecord::Migration
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

しかしRailsには初期データをデータベースに与えるためのシード機能があります。これは、`db/seeds.rb`ファイルに若干のRubyコードを追加して`bin/rails db:seed`を実行するだけですぐに利用できます。

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

この方法なら、マイグレーションを使用するよりもずっとクリーンに空のアプリケーションのデータベースを設定できます。