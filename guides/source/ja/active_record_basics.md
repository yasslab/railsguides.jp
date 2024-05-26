Active Record の基礎
====================

このガイドではActive Recordの基礎について説明します。

このガイドの内容:

* Active RecordがMVC (Model-View-Controller)パラダイムと調和する方法
* ORM (オブジェクト/リレーショナルマッピング) とActive Recordについて、およびRailsでの利用方法
* Active Recordモデルを利用してリレーショナルデータベースに保存されたデータを操作する
* Active Recordスキーマにおける命名規約
* データベースのマイグレーション、バリデーション（検証）、コールバックの概念

--------------------------------------------------------------------------------

Active Recordについて
----------------------

Active Recordとは、[MVC][]で言うところのM、つまりモデルの一部であり、データとビジネスロジックを表現するシステムの階層です。Active Recordは、データベースに恒久的に保存される必要のあるビジネスオブジェクトの作成と利用を円滑に行なえるようにします。

NOTE: RailsのActive Recordが[Active Model][]とどこが違うかというと、Active Modelは背後にデータベースが「なくてもよい」Rubyオブジェクトを用いてデータをモデル化するときに主に用いられます。Active RecordとActive Modelは、どちらもMVCのMの一部ですが、Active Modelは独自のプレーンなRubyオブジェクト（PORO）としても利用できます。

「Active Record」は、ソフトウェアアーキテクチャパターンを指すという用語でもあります。RailsのActive Recordは、「Active Record」パターンの実装でもあり、[オブジェクト リレーショナル マッピング][ORM]システムとも呼ばれます。以下のセクションでは、これらの用語について説明します。

[MVC]: https://ja.wikipedia.org/wiki/Model_View_Controller
[Active Model]: active_model_basics.html
[ORM]: https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E9%96%A2%E4%BF%82%E3%83%9E%E3%83%83%E3%83%94%E3%83%B3%E3%82%B0

### Active Recordパターン

パターン名としての[Active Record][MFAR]は、Martin Fowler『Patterns of Enterprise Application Architecture』という書籍で「データベーステーブル内の行をラップし、データベースアクセスをカプセル化し、そのデータにドメインロジックを追加するオブジェクト」と説明されています。Active Recordオブジェクトはデータと振る舞いの両方を保持します。Active Recordクラスは、背後のデータベースのレコード構造と非常に密接に対応します。これにより、以下の例でわかるように、ユーザーはデータベースの読み取りや書き込みを手軽に行えるようになります。

[MFAR]: https://www.martinfowler.com/eaaCatalog/activeRecord.html

### オブジェクト/リレーショナルマッピング（ORM）

[オブジェクト/リレーショナルマッピング][ORM]（一般にORMと呼ばれます）は、プログラミング言語のリッチなオブジェクトをリレーショナルデータベース管理システム（RDBMS）のテーブルに接続する技術です。Railsアプリケーションの場合、これらはRubyオブジェクトです。ORMによって、SQLステートメントを直接記述せずに、Rubyオブジェクトの属性やオブジェクト間の関係をデータベースに手軽に保存したり、データベースから取得したりできます。ORMによって、作成する必要があるデータベースアクセスコードの量は一般に最小限で済むようになります。

NOTE: Active Recordを完全に理解するには、リレーショナルデータベース管理システム（RDBMS）やSQL（構造化クエリ言語）についての知識が役に立ちます。これらについてもっと深く学びたい場合は、[このチュートリアル][sqlcourse]（[このチュートリアル][rdbmsinfo]も可）を参照するか、他の方法で学習しましょう。

[sqlcourse]: https://www.khanacademy.org/computing/computer-programming/sql
[rdbmsinfo]: https://www.devart.com/what-is-rdbms/

### ORMフレームワークとしてのActive Record

Active Recordでは、Rubyオブジェクトを用いて以下を行えます。

* モデルおよびモデル内のデータを表現する
* モデル同士の関連付け（association: アソシエーション）を表現する
* 関連付けられているモデル間の継承階層を表現する
* データをデータベースで永続化する前にバリデーション（検証）を行なう
* データベースをオブジェクト指向スタイルで操作する

Active RecordにおけるCoC（Convention over Configuration）
----------------------------------------------

他のプログラミング言語やフレームワークでアプリケーションを作成すると、設定のためのコードを大量に書く必要が生じがちです。一般的なORMアプリケーションでは特にこの傾向があります。しかし、Railsで採用されている規約（規約）に従っていれば、Active Recordモデルの作成時に書かなければならない設定用コードは最小限で済みますし、設定用コードが完全に不要になることすらあります。

Railsでは、アプリケーションの設定方法がほとんどの場合に同じになるのであれば、その方法をフレームワークのデフォルト設定にすべきという「設定よりも規約（Convention over Configuration）」の考えを採用しています。設定を明示的に行う必要があるのは、規約に沿えない事情がある場合だけです。

Active Recordで「設定よりも規約」を活かして楽に開発するには、命名とスキーマについていくつかの規約に従う必要があります。命名規約は必要に応じて[オーバーライド](#命名規約を上書きする)することも可能です。

### 命名規約

Active Recordには、モデルとデータベースのテーブルとのマッピング作成時に従うべき規約がいくつかあります。

Railsでは、データベースのテーブル名を探索するときに、モデルのクラス名を複数形にした名前で探索します。たとえば、`Book`というモデルクラスがある場合、これに対応するデータベースのテーブルは複数形の「**books**」になります。Railsの複数形化メカニズムは非常に強力で、不規則な語でも複数形/単数形に変換できます（person <-> peopleなど）。これには[Active Support](active_support_core_extensions.html#pluralize)の
[`pluralize`](https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-pluralize)メソッドが使われています。

モデルのクラス名が2語以上の複合語である場合、Rubyの規約であるキャメルケース（CamelCaseのように語頭を大文字にしてスペースなしでつなぐ記法）に従ってください。一方、テーブル名はスネークケース（snake_caseのように小文字とアンダースコアで構成する記法）にしなければなりません。以下の例を参照ください。

* モデルのクラス名: 単数形、語頭を大文字にする（例: `BookClub`）
* データベースのテーブル名: 複数形、語はアンダースコアで区切る（例: `book_clubs`）

| モデル / クラス | テーブル / スキーマ |
| ------------- | -------------- |
| `Article`     | `articles`     |
| `LineItem`    | `line_items`   |
| `Product`     | `products`     |
| `Person`      | `people`       |


### スキーマの規約

Active Recordでは、データベースのテーブルで使うカラム名についても、カラムの利用目的に応じた規約があります。

* **主キー**（primary key）: デフォルトでは、Active Recordはテーブルの主キーとして`id`という名前の整数型カラムを利用します（PostgreSQL、MySQL、MariaDBの場合は`bigint`型、SQLiteの場合は`integer`型）。`id`カラムは、[Active Recordのマイグレーション](#マイグレーション)でテーブルを作成すると自動的に作成されます。
* **外部キー**（foreign key）:これらのフィールドは、`単数形のテーブル名_id`パターンに沿って命名する必要があります（例: `order_id`、`line_item_id`）。これらは、モデル間の関連付けを作成するときにActive Recordが探索するフィールドです。

他にも、Active Recordインスタンスに機能を追加するカラム名がいくつかあります。

* `created_at`: レコード作成時に現在の日付時刻が自動的に設定されます
* `updated_at`: レコード作成時や更新時に現在の日付時刻が自動的に設定されます
* `lock_version`: モデルに[optimistic locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking.html)を追加します
* `type`: モデルで[Single Table Inheritance（STI）](https://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance)を使う場合に指定します
* `関連付け名_type`: [ポリモーフィック関連付け](association_basics.html#ポリモーフィック関連付け)の種類を保存します
* `テーブル名_count`: 関連付けにおいて、所属しているオブジェクトの個数をキャッシュするのに使われます。たとえば、`Article`クラスが`has_many`で`Comment`と関連付けられている場合、`articles`テーブルの`comments_count`カラムには記事ごとに既存のコメント数がキャッシュされます。

NOTE: これらのカラム名はオプションであり、必須ではありませんが、Active Recordで予約されています。特別な理由のない限り、これらの予約済みカラム名と同じカラム名の利用は避けてください。たとえば、`type`という語はテーブルでSTI（Single Table Inheritance）を指定するために予約されています。STIを使わない場合であっても、モデル化するデータを適切に表す別の語を検討してください。

Active Recordのモデルを作成する
-----------------------------

Railsアプリケーションを生成すると、`app/models/application_record.rb`ファイルに抽象クラス`ApplicationRecord`が作成されます。この`ApplicationRecord`クラスは[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html)を継承しており、通常のRubyクラスをActive Recordモデルに変えるものです。

`ApplicationRecord`は、アプリ内にあるすべてのActive Recordモデルの基本クラスです。Active Recordモデルは、以下のように`ApplicationRecord`クラスのサブクラスを作成するだけで完了します。

```ruby
class Book < ApplicationRecord
end
```

上のコードは、`Product`モデルを作成し、データベースの`products`テーブルにマッピングされます。さらに、テーブルに含まれている各行のカラムを、作成したモデルのインスタンスの属性にマッピングします。以下のSQL文（または拡張SQLの文）で`products`テーブルを作成したとします。

上のコードで作成される`Book`モデルは、データベース内の`books`テーブルに対応付けられ、このテーブル内の各カラムが`Book`クラスの属性に対応付けられます。`Book`モデルの1個のインスタンスが、`books`テーブル内の1行を表現できます。`id`カラム、`title`カラム、`author`カラムを持つ`books`テーブルは、次のようなSQLステートメントで作成できます。

```sql
CREATE TABLE books (
  id int(11) NOT NULL auto_increment,
  title varchar(255),
  author varchar(255),
  PRIMARY KEY  (id)
);
```

ただし、通常のRailsでは上のようなSQLステートメントで直接テーブルを作成することはありません。通常、Railsのデータベーステーブルは生SQLではなく[Active Recordのマイグレーション](#マイグレーション)で作成します。上記の`books`テーブルのマイグレーションは次のようなコマンドで生成できます。

```bash
$ bin/rails generate migration CreateBooks title:string author:string
```

上のコマンドを実行すると、以下のマイグレーションが生成されます。

```ruby
# Note:
# The `id` column, as the primary key, is automatically created by convention.
# Columns `created_at` and `updated_at` are added by `t.timestamps`.

# db/migrate/20240220143807_create_books.rb
class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :title
      t.string :author

      t.timestamps
    end
  end
end
```

このマイグレーションは、`id`カラム、`title`カラム、`author`カラム、`created_at`カラム、`updated_at`カラムを生成します。この`books`テーブルの各行は`Book`クラスのインスタンスで表現でき、カラム名と同じ名前の`id`属性、`title`属性、`author`属性、`created_at`属性、`updated_at`属性を持ちます。これらの属性にアクセスするには、次のようにします。

```irb
irb> book = Book.new
=> #<Book:0x00007fbdf5e9a038 id: nil, title: nil, author: nil, created_at: nil, updated_at: nil>

irb> book.title = "The Hobbit"
=> "The Hobbit"
irb> book.title
=> "The Hobbit"
```

NOTE: 上述のActive Recordモデルクラスと一致するマイグレーションを生成するには、`bin/rails generate model Book title:string author:string`コマンドを実行できます。このとき、モデルファイル`app/models/book.rb`、マイグレーションファイル`db/migrate/20240220143807_create_books.rb`に加えて、テスト用のファイルもいくつか生成されます。

### 名前空間付きモデルを作成する

デフォルトのActive Recordモデルは、`app/models`ディレクトリの下に配置されます。ただし、互いによく似たいくつかのモデルを独自のフォルダと名前空間の下にまとめて配置して、モデルを整理することも可能です。たとえば、`app/models/books`ディレクトリの下に`order.rb`ファイルと`review.rb`ファイルを置いて、それぞれ`Book::Order`と`Book::Review`という名前空間付きのクラス名を付けるというように、Active Recordでは名前空間モデルを作成できます。

`Book`という名前のモジュールがまだ存在していなければ、以下のように`generate`コマンドですべてを作成できます。

```bash
$ bin/rails generate model Book::Order
      invoke  active_record
      create    db/migrate/20240306194227_create_book_orders.rb
      create    app/models/book/order.rb
      create    app/models/book.rb
      invoke    test_unit
      create      test/models/book/order_test.rb
      create      test/fixtures/book/orders.yml
```

`Book`という名前のモジュールがすでに存在する場合、以下のように名前空間の衝突を解決するように求められます。

```bash
$ bin/rails generate model Book::Order
      invoke  active_record
      create    db/migrate/20240305140356_create_book_orders.rb
      create    app/models/book/order.rb
    conflict    app/models/book.rb
  Overwrite /Users/bhumi/Code/rails_guides/app/models/book.rb? (enter "h" for help) [Ynaqdhm]
```

名前空間付きモデルの生成が成功すると、以下のような`Book`クラスと`Order`クラスが作成されます。

```ruby
# app/models/book.rb
module Book
  def self.table_name_prefix
    "book_"
  end
end
```

```ruby
# app/models/book/order.rb
class Book::Order < ApplicationRecord
end
```

`Book`モデルに[`table_name_prefix`](https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-c-table_name_prefix-3D)を設定しておくと、`Order`モデルのデータベーステーブル名を単なる`orders`ではなく`book_orders`という名前空間を取り込んだテーブル名にできます。

別の可能性として、`app/models`ディレクトリの下に既に`Book`モデルが存在しており、このモデルを上書きしたくない場合は、プロンプトで`n`を選択すれば、`generate`コマンドで`book.rb`を上書きしなくなります。
この場合は、`table_name_prefix`を必要とせずに、引き続き`Book::Order`クラスに対応する名前空間付きテーブル名が利用できます。

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  # existing code
end

Book::Order.table_name
# => "book_orders"
```

命名規約を上書きする
---------------------------------

Railsアプリケーションで別の命名規約を使わなければならない場合や、レガシーデータベースを用いてRailsアプリケーションを作成しないといけない場合は、デフォルトの命名規約を手軽にオーバーライドできます。

`ApplicationRecord`は、有用なメソッドが多数定義されている`ActiveRecord::Base`を継承しているので、使うべきテーブル名を`ActiveRecord::Base.table_name=`メソッドで明示的に指定できます。

```ruby
class Book < ApplicationRecord
  self.table_name = "my_books"
end
```

テーブル名をこのように上書き指定する場合は、テストの定義で`set_fixture_class`メソッドを使い、[フィクスチャ](testing.html#フィクスチャのしくみ) (`my_books.yml`) に対応するクラス名を別途定義しておく必要があります。

```ruby
# test/models/book_test.rb
class BookTest < ActiveSupport::TestCase
  set_fixture_class my_books: Book
  fixtures :my_books
  # ...
end
```

`ActiveRecord::Base.primary_key=`メソッドを用いて、テーブルの主キーに使われるカラム名を上書きすることもできます。

```ruby
class Book < ApplicationRecord
  self.primary_key = "book_id"
end
```

NOTE: **Active Recordでは、`id`という名前を「主キー以外のカラム」で用いることは推奨されていません。**
単一カラムの主キーでない`id`という名前の列を使うと、カラム値へのアクセスが複雑になってしまいます。その場合、アプリケーションは「主キーでない」`id`カラムにアクセスするときは[`id_value`][]エイリアス属性を使わなければならなくなります。

[`id_value`]: https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-i-id_value

CRUD: データの読み書き
------------------------------

CRUDとは、データベース操作を表す4つの「**C**reate」「**R**ead」「**U**pdate」「**D**elete」の頭字語です。Active Recordはこれらのメソッドを自動的に作成するので、テーブルに保存されているデータをアプリケーションで操作できるようになります。

Active Recordでは、データベースアクセスの詳細を抽象化するこれらの高レベルのメソッドを活用して、CRUD操作をシームレスに実行できます。これらの便利なメソッドはすべて、背後のデータベースに対してSQLステートメントを実行します。

以下の例は、いくつかのCRUDメソッドと結果のSQLステートメントを示しています。

### Create

Active Recordのオブジェクトはハッシュやブロックから作成できます。また、作成後に属性を手動で追加できます。`new`メソッドを実行すると「永続化されていない」新規オブジェクトが返されますが、`create`を実行すると新しいオブジェクトが返され、さらにデータベースに保存（永続化）されます。

たとえば、`Book`というモデルに`title`と`author`という属性があるとすると、`create`メソッドで新しいレコードが1件作成され、データベースに保存されます。

```ruby
book = Book.create(title: "The Lord of the Rings", author: "J.R.R. Tolkien")
```

 `id`はこのレコードがデータベースにコミットされたときに初めて割り当てられる点にご注意ください。

```ruby
book.inspect
# => "#<Book id: 106, title: \"The Lord of the Rings\", author: \"J.R.R. Tolkien\", created_at: \"2024-03-04 19:15:58.033967000 +0000\", updated_at: \"2024-03-04 19:15:58.033967000 +0000\">"
```

`new`メソッドもインスタンスを作成しますが、データベースには**保存しません**。

```ruby
book = Book.new
book.title = "The Hobbit"
book.author = "J.R.R. Tolkien"
```

上に続いて以下を実行しても、この時点では`book`がデータベースに保存されていないので、`id`は設定されていません。

```ruby
book.inspect
# => "#<Book id: nil, title: \"The Hobbit\", author: \"J.R.R. Tolkien\", created_at: nil, updated_at: nil>"
```

以下を実行して`book`レコードをデータベースにコミットすると、`id`が割り当てられます。

```ruby
book.save
book.id # => 107
```

最後に、`create`や`new`にブロックを渡した場合は、そのブロックで初期化された新しいオブジェクトが`yield`されますが、得られたオブジェクトをデータベースで永続化するのは`create`のみです。

```ruby
book = Book.new do |b|
  b.title = "Metaprogramming Ruby 2"
  b.author = "Paolo Perrotta"
end

book.save
```

`book.save`と`Book.create`でそれぞれ生成されるSQLステートメントは以下のようになります。

```sql
/* 注: `created_at`と`updated_at`は自動設定されます */

INSERT INTO "books" ("title", "author", "created_at", "updated_at") VALUES (?, ?, ?, ?) RETURNING "id"  [["title", "Metaprogramming Ruby 2"], ["author", "Paolo Perrotta"], ["created_at", "2024-02-22 20:01:18.469952"], ["updated_at", "2024-02-22 20:01:18.469952"]]
```

### Read

Active Recordは、データベース内のデータにアクセスできる高機能なAPIを提供します。
単一レコードのクエリ、複数レコードのクエリ、属性を指定してフィルタリング、並べ替え、特定フィールドの選択など、SQLでできることはすべてActive Recordで実行できます。

```ruby
# すべての書籍のコレクションを返す
books = Book.all

# 1冊の書籍を返す
first_book = Book.first
last_book = Book.last
book = Book.take
```

上のコードを実行すると、それぞれ以下のSQLステートメントが生成されます。

```sql
-- Book.all
SELECT "books".* FROM "books"

-- Book.first
SELECT "books".* FROM "books" ORDER BY "books"."id" ASC LIMIT ?  [["LIMIT", 1]]

-- Book.last
SELECT "books".* FROM "books" ORDER BY "books"."id" DESC LIMIT ?  [["LIMIT", 1]]

-- Book.take
SELECT "books".* FROM "books" LIMIT ?  [["LIMIT", 1]]
```

`find_by`メソッドや`where`メソッドを用いて特定の書籍を検索することも可能です。`find_by`は1件のレコードを返し、`where`は複数のレコードを返します。

```ruby
# 指定のタイトルを持つ最初の書籍を返す、見つからない場合は`nil`を返す
book = Book.find_by(title: "Metaprogramming Ruby 2")

# 以下は`Book.find_by(id: 42)`の別記法（書籍が見つからない場合は例外をraiseする）
book = Book.find(42)
```

上のコードを実行すると、それぞれ以下のSQLステートメントが生成されます。

```sql
SELECT "books".* FROM "books" WHERE "books"."author" = ? LIMIT ?  [["author", "J.R.R. Tolkien"], ["LIMIT", 1]]

SELECT "books".* FROM "books" WHERE "books"."id" = ? LIMIT ?  [["id", 42], ["LIMIT", 1]]
```

```ruby
# 指定の著者名を持つ書籍をすべて検索し、結果をcreated_atの降順で返す
Book.where(author: "Douglas Adams").order(created_at: :desc)
```

上のコードを実行すると、それぞれ以下のSQLステートメントが生成されます。

```sql
SELECT "books".* FROM "books" WHERE "books"."author" = ? ORDER BY "books"."created_at" DESC [["author", "Douglas Adams"]]
```

Active Recordモデルの読み取りやクエリ方法はこの他にもたくさんあります。詳しくは、[Active Recordクエリインターフェイス](active_record_querying.html)ガイドを参照してください。

### Update

Active Recordオブジェクトを取得すると、オブジェクトの属性を変更してデータベースに保存できるようになります。

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.title = "The Lord of the Rings: The Fellowship of the Ring"
book.save
```

上のコードをもっと短く書くには、次のように、属性名と設定したい値をハッシュで対応付けて指定します。

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.update(title: "The Lord of the Rings: The Fellowship of the Ring")
```

上のコードを実行すると、以下のSQLステートメントが生成されます。

```sql
/* 注: `created_at`と`updated_at`は自動設定されます */

 UPDATE "books" SET "title" = ?, "updated_at" = ? WHERE "books"."id" = ?  [["title", "The Lord of the Rings: The Fellowship of the Ring"], ["updated_at", "2024-02-22 20:51:13.487064"], ["id", 104]]
```

このショートハンド記法は、多くの属性を一度に更新したい場合に特に便利です。なお、`update`は`create`と同様に、更新したレコードをデータベースにコミットします。

さらに、**コールバックやバリデーションをトリガーせずに**複数のレコードを一度に更新したい場合は、以下のように`update_all`でデータベースを直接更新できます。

```ruby
Book.update_all(status: "already own")
```

### Delete

他のメソッドと同様、Active Recordオブジェクトを取得すると、そのオブジェクトを`destroy`してデータベースから削除できます。

```ruby
book = Book.find_by(title: "The Lord of the Rings")
book.destroy
```

上のコードを実行すると、以下のSQLステートメントが生成されます。

```sql
DELETE FROM "books" WHERE "books"."id" = ?  [["id", 104]]
```

複数レコードを一括削除したい場合は、`destroy_by `または`destroy_all`を使えます。

```ruby
# Douglas Adams著の書籍をすべて検索して削除する
Book.destroy_by(author: "Douglas Adams")

# すべての書籍を削除する
Book.destroy_all
```

バリデーション（検証）
-----------

Active Recordを使って、モデルがデータベースに書き込まれる前にモデルの状態をバリデーション（検証: validation）できます。Active Recordにはモデルチェック用のさまざまなメソッドが用意されており、属性が空でないかどうか、属性が一意かどうか、既にデータベースにないかどうか、特定のフォーマットに沿っているかどうか、多岐にわたったバリデーションが行えます。

バリデーションは、データベースを永続化するときに考慮すべき重要な課題です。そのため、`save`、`create`、`update`メソッドは、バリデーションに失敗すると`false`を返します。このとき実際のデータベース操作は行われません。上のメソッドにはそれぞれ破壊的なバージョン (`save!`、`create!`、`update!`) があり、こちらは検証に失敗した場合にさらに厳しい対応、つまり`ActiveRecord::RecordInvalid`例外を発生します。以下はバリデーションの簡単な例です。


```ruby
class User < ApplicationRecord
  validates :name, presence: true
end
```

```irb
irb> user = User.new
irb> user.save
=> false
irb> user.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

バリデーションについて詳しくは、[Active Record バリデーションガイド](active_record_validations.html)を参照してください。

コールバック
---------

Active Recordコールバックを使うと、モデルのライフサイクル内で特定のイベントにコードをアタッチして実行できます。これにより、モデルで特定のイベントが発生したときにコードを実行できます。レコードの作成、更新、削除などさまざまなイベントに対してコールバックを設定できます。コールバックについて詳しくは、[Active Recordコールバックガイド](active_record_callbacks.html)を参照してください。

マイグレーション
----------

Railsにはデータベーススキーマを管理するためのDSL（ドメイン固有言語: Domain Specific Language）があり、マイグレーション（migration）と呼ばれています。マイグレーションをファイルに保存して`bin/rails`を実行すると、Active Recordがサポートするデータベースに対してマイグレーションが実行されます。以下はテーブルを作成するマイグレーションです。

```ruby
class CreatePublications < ActiveRecord::Migration[7.2]
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.references :publication_type
      t.references :publisher, polymorphic: true
      t.boolean :single_issue

      t.timestamps
    end
  end
end
```

上のマイグレーションコードは特定のデータベースに依存していないことにご注目ください。MySQL、MariaDB、PostgreSQL、Oracleなどさまざまなデータベースに対してマイグレーションを実行できます。

Railsはどのマイグレーションファイルがデータベースにコミットされたかをトラッキングしており、`schema_migrations`と呼ばれる隣接テーブルにその情報を保存します。

テーブルを実際に作成するには`bin/rails db:migrate`を実行します。ロールバックするには`bin/rails db:rollback`を実行します。

マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。

関連付け
------------

Active Recordの関連付け（association）を利用することで、モデル間のリレーションシップ（関係）を定義できます。関連付けでは、1対1リレーションシップ、1対多リレーションシップ、および多対多リレーションシップを記述できます。たとえば、「Author（著者）には多数のBooks（書籍）がある」というリレーションシップは次のように定義できます。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

これによって、1人の著者に書籍を追加・削除するメソッドなど、多数のメソッドが`Author`クラスに追加されます。

関連付けについて詳しくは、[Active Recordの関連付けガイド](association_basics.html)を参照してください。