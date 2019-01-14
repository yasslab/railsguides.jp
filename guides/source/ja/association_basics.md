


Active Record の関連付け (アソシエーション)
==========================

このガイドでは、Active Recordの関連付け機能(アソシエーション)について解説します。

このガイドの内容:

* Active Recordのモデル同士の関連付けを宣言する方法
* Active Recordのモデルを関連付けるさまざまな方法
* 関連付けを作成すると自動的に追加されるメソッドの利用方法

--------------------------------------------------------------------------------

関連付けを使う理由
-----------------

Railsでは、「関連付け(アソシエーション: association)」とは2つのActive Recordモデル同士のつながりを指します。モデルとモデルの間には関連付けを行なう必要がありますが、その理由を御存じでしょうか。関連付けを行なうのは、それによってコード内で一般的に行われる操作をはるかに簡単にできるからです。簡単なRailsアプリケーションを例にとって説明しましょう。このアプリケーションには著者用のモデル(Author)と書籍用のモデル(Book)があります。一人の著者は、複数の書籍を持っています。関連付けを設定していない状態では、モデルの宣言は以下のようになります。    

```ruby
class Author < ApplicationRecord
end

class Book < ApplicationRecord
end
```

ここで、既存の著者が新しい書籍を1つ執筆したくなったとします。この場合、以下のようなコードを実行する必要があるでしょう。

```ruby
@book = Book.create(published_at: Time.now, author_id: @author.id)
```

今度は著者を削除する場合を考えてみましょう。著者を削除するなら、以下のように、執筆した書籍も残らず削除されるようにしておかなければなりません。

```ruby
@books = Book.where(author_id: @author.id)
@books.each do |book|
  book.destroy
end
@author.destroy
```

Active Recordの関連付け機能を使うと、2つのモデルの間につながりがあることを明示的にRailsに対して宣言することができ、それによってモデルの操作を一貫させることができます。著者と書籍の設定するコードを次のように書き直せます。

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
end

class Book < ApplicationRecord
  belongs_to :author
end
```

上のように関連付けを追加したことで、特定の著者用に新しい書籍を1つ追加する作業が以下のように一行でできるようになりました。

```ruby
@book = @author.books.create(published_at: Time.now)
```

著者と、その著者の書籍をまとめて削除する作業はさらに簡単です。

```ruby
@author.destroy
```

その他の関連付け方法については、次の節をお読みください。それに続いて、関連付けに関するさまざまなヒントや活用方法、Railsの関連付けメソッドとオプションの完全な参照物もご紹介します。

関連付けの種類
-------------------------

Railsでサポートされている関連付けは以下の6種類です。

* `belongs_to`
* `has_one`
* `has_many`
* `has_many :through`
* `has_one :through`
* `has_and_belongs_to_many`

関連付けは、一種のマクロ的な呼び出しとして実装されており、これによってモデル間の関連付けを宣言的に追加することができます。たとえば、あるモデルが他のモデルに従属している(`belongs_to`)と宣言すると、2つのモデルのそれぞれのインスタンス間で「[主キー](https://ja.wikipedia.org/wiki/%E4%B8%BB%E3%82%AD%E3%83%BC) - [外部キー](https://ja.wikipedia.org/wiki/%E5%A4%96%E9%83%A8%E3%82%AD%E3%83%BC)」情報を保持しておくようにRailsに指示が伝わります。また、それに伴って幾つかの役立つメソッドもそのモデルに追加されます。

本ガイドではこの後、それぞれの関連付けの宣言方法と利用方法について詳しく解説します。その前に、それぞれの関連付けが適切となる状況について簡単にご紹介しましょう。

### `belongs_to`関連付け

あるモデルで`belongs_to`関連付けを行なうと、他方のモデルとの間に「1対1」のつながりが設定されます。このとき、宣言を行ったモデルのすべてのインスタンスは、他方のモデルのインスタンスに「従属(belongs to)」します。たとえば、Railsアプリケーションに著者(Author)と書籍(Book)情報が含まれており、１人の著者につき正確に1冊だけを割り当てたいのであれば、Bookモデルで以下のように宣言します。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

![belongs_to 関連付けの図](images/belongs_to.png)

NOTE: `belongs_to`関連付けで指定するモデル名は必ず「単数形」にしなければなりません。上記の例で、`Book`モデルの`author`関連付けを複数形（`authors`）にしてしまうと、「uninitialized constant Book::Authors」エラーが発生します。Railsは、関連付けの名前から自動的にモデルのクラス名を推測します。従って、関連付け名が誤って複数形になってしまっていると、そこから推測されるクラス名も誤った形の複数形になってしまいます。

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :authors do |t|
      t.string  :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author, index: true
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

### `has_one`関連付け

`has_one`関連付けも、他方のモデルとの間に1対1の関連付けを設定します。しかし、その意味と結果は`belongs_to`とは若干異なります。`has_one`関連付けの場合は、その宣言が行われているモデルのインスタンスが、他方のモデルのインスタンスを「まるごと含んでいる」または「所有している」ことを示します。たとえば、供給者(supplier)1人につきアカウント(account)を1つだけ持つという関係があるのであれば、以下のように宣言を行います。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end
```

![has_one関連付けの図](images/has_one.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration[5.0]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier, index: true
      t.string :account_number
      t.timestamps
    end
  end
end
```

ユースケースにもよりますが、アカウントとの関連付けのために、供給者のカラムに一意のインデックスや外部キー制約を追加する必要もある場合もあります。その場合、カラムの定義は次のようになる可能性があります。

```ruby
create_table :accounts do |t|
  t.belongs_to :supplier, index: { unique: true }, foreign_key: true
  # ...
end
```

### `has_many`関連付け

`has_many`関連付けは、他のモデルとの間に「1対多」のつながりがあることを示します。`has_many`関連付けが使われている場合、「反対側」のモデルでは`belongs_to`が使われることが多くあります。`has_many`関連付けが使われている場合、そのモデルのインスタンスは、反対側のモデルの「0個以上の」インスタンスを所有します。たとえば、著者(Author)と書籍(Book)を含むRailsアプリケーションでは、著者のモデルを以下のように宣言することができます。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

NOTE: `has_many`関連付けを宣言する場合、相手のモデル名は「複数形」にする必要があります。

![has_many関連付けの図](images/has_many.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAuthors < ActiveRecord::Migration[5.0]
  def change
    create_table :authors do |t|
      t.string  :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author, index: true
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

### `has_many :through`関連付け

`has_many :through`関連付けは、他方のモデルと「多対多」のつながりを設定する場合によく使われます。この関連付けは、2つのモデルの間に「第3のモデル」(結合モデル)が介在する点が特徴です。それによって、相手モデルの「0個以上」のインスタンスとマッチします。たとえば、患者(patient)が医師(physician)との診察予約(appointment)を取る医療業務を考えてみます。この場合、関連付けは次のような感じになるでしょう。

```ruby
class Physician < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient
end

class Patient < ApplicationRecord
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

![has_many :through関連付けの図](images/has_many_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAppointments < ActiveRecord::Migration[5.0]
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
      t.belongs_to :physician, index: true
      t.belongs_to :patient, index: true
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

結合モデル(join model)のコレクションは、[`has_many`](#has-many関連付け)経由で管理することができます。たとえば、以下のような割り当てを実行したとします。

```ruby
physician.patients = patients
```

このとき、新たに関連付けられたオブジェクトについて、新しい結合モデルが自動的に作成されます。結合時に不足している部分があれば、その行は結合モデルから削除され、結合モデルに含まれなくなります。

WARNING: モデル結合時の不足分自動削除は即座に行われます。さらに、その際にdestroyコールバックはトリガーされませんので注意が必要です。

`has_many :through`関連付けは、ネストした`has_many`関連付けを介して「ショートカット」を設定する場合にも便利です。たとえば、1つのドキュメントに多くの節(section)があり、1つの節の下に多くの段落(paragraph)がある状態で、節をスキップしてドキュメントの下のすべての段落の単純なコレクションが欲しいとします。その場合、以下の方法で設定できます。

```ruby
class Document < ApplicationRecord
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ApplicationRecord
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ApplicationRecord
  belongs_to :section
end
```

`through: :sections`と指定することにより、Railsは以下の文を理解できるようになります。

```ruby
@document.paragraphs
```

### `has_one :through`関連付け

`has_one :through`関連付けは、他方のモデルに対して「1対1」のつながりを設定します。この関連付けは、2つのモデルの間に「第3のモデル」(結合モデル)が介在する点が特徴です。それによって、相手モデルの1つのインスタンスとマッチします。たとえば、1人の提供者(supplier)が1つのアカウントに関連付けられ、さらに1つのアカウントが1つのアカウント履歴に関連付けられる場合、supplierモデルは以下のような感じになります。

```ruby
class Supplier < ApplicationRecord
  has_one :account
  has_one :account_history, through: :account
end

class Account < ApplicationRecord
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ApplicationRecord
  belongs_to :account
end
```

![has_one :through関連付けの図](images/has_one_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAccountHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier, index: true
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account, index: true
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

### `has_and_belongs_to_many`関連付け

`has_and_belongs_to_many`関連付けは、他方のモデルと「多対多」のつながりを作成しますが、`through:`を指定した場合と異なり、第3のモデル(結合モデル)が介在しません(訳注: 後述するように結合用のテーブルは必要です)。たとえば、アプリケーションに完成品(assembly)と部品(part)があり、1つの完成品に多数の部品が対応し、逆に1つの部品にも多くの完成品が対応するのであれば、モデルの宣言は以下のようになります。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many関連付けの図](images/habtm.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration[5.0]
  def change
    create_table :assemblies do |t|
      t.string  :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    create_table :assemblies_parts, id: false do |t|
      t.belongs_to :assembly, index: true
      t.belongs_to :part, index: true
    end
  end
end
```

### `belongs_to`と`has_one`のどちらを選ぶか

2つのモデルの間に1対1の関係を作りたいのであれば、いずれか一方のモデルに`belongs_to`を追加し、もう一方のモデルに`has_one`を追加する必要があります。どちらの関連付けをどちらのモデルに置けばよいのでしょうか。

区別の決め手となるのは外部キー(foreign key)をどちらに置くかです(外部キーは、`belongs_to`を追加した方のモデルのテーブルに追加されます)。もちろんこれだけでは決められません。データの実際の意味についてもう少し考えてみる必要があります。`has_one`というリレーションは、主語となるものが目的語となるものを「所有している」ということを表しています。そして、所有されている側(目的語)の方が、所有している側(主語)を指し示しているということも表しています。たとえば、「供給者がアカウントを持っている」とみなす方が、「アカウントが供給者を持っている」と考えるよりも自然です。つまり、この場合の正しい関係は以下のようになります。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end

class Account < ApplicationRecord
  belongs_to :supplier
end
```

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration[5.0]
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

    add_index :accounts, :supplier_id
  end
end
```

NOTE: マイグレーションで`t.integer :supplier_id`のように「小文字のモデル名_id」と書くと、外部キーを明示的に指定できます。新しいバージョンのRailsでは、同じことを`t.references :supplier`という方法で記述できます。こちらの方が実装の詳細が抽象化され、隠蔽されます。

### `has_many :through`と`has_and_belongs_to_many`のどちらを選ぶか

Railsでは、モデル間の多対多リレーションシップを宣言するのに2とおりの方法が利用できます。簡単なのは`has_and_belongs_to_many`を使う方法です。この方法では関連付けを直接指定できます。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

多対多のリレーションシップを宣言するもう1つの方法は`has_many :through`です。こちらの場合は、結合モデルを用いた間接的な関連付けが使われます。

```ruby
class Assembly < ApplicationRecord
  has_many :manifests
  has_many :parts, through: :manifests
end

class Manifest < ApplicationRecord
  belongs_to :assembly
  belongs_to :part
end

class Part < ApplicationRecord
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

どちらを使うかについてですが、経験上、リレーションシップのモデルそれ自体を独立したエンティティとして扱いたい(両モデルの関係そのものについて処理を行いたい)のであれば、中間に結合モデルを使う`has_many :through`リレーションシップを選ぶのが最もシンプルです。リレーションシップのモデルで何か特別なことをする必要がまったくないのであれば、結合モデルの不要な`has_and_belongs_to_many`リレーションシップを使うのがシンプルです(ただし、こちらの場合は結合モデルが不要な代わりに、専用の結合テーブルを別途データベースに作成しておく必要がありますので、お忘れなきよう)。

結合モデルで検証(validation)、コールバック、追加の属性が必要なのであれば、`has_many :through`を使いましょう。

### ポリモーフィック関連付け

_ポリモーフィック関連付け_は、関連付けのやや高度な応用です。ポリモーフィック関連付けを使うと、ある1つのモデルが他の複数のモデルに属していることを、1つの関連付けだけで表現することができます。たとえば、写真(picture)モデルがあり、このモデルを従業員(employee)モデルと製品(product)モデルの両方に従属させたいとします。この場合は以下のように宣言します。

```ruby
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable
end
```

ポリモーフィックな`belongs_to`は、他のあらゆるモデルから使える、(デザインパターンで言うところの)インターフェイスを設定する宣言とみなすこともできます。`@employee.pictures`とすると、写真のコレクションを`Employee`モデルのインスタンスから取得できます。

同様に、`@product.pictures`とすれば写真のコレクションを`Product`モデルのインスタンスから取得できます。

`Picture`モデルのインスタンスがあれば、`@picture.imageable`とすることで親を取得できます。これができるようにするためには、ポリモーフィックなインターフェイスを使うモデルで、外部キーのカラムと型のカラムを両方とも宣言しておく必要があります。

```ruby
class CreatePictures < ActiveRecord::Migration[5.0]
  def change
    create_table :pictures do |t|
      t.string  :name
      t.integer :imageable_id
      t.string  :imageable_type
      t.timestamps
    end

    add_index :pictures, [:imageable_type, :imageable_id]
  end
end
```

`t.references`という書式を使うと、さらにシンプルにできます。

```ruby
class CreatePictures < ActiveRecord::Migration[5.0]
  def change
    create_table :pictures do |t|
      t.string  :name
      t.references :imageable, polymorphic: true, index: true
      t.timestamps
    end
  end
end
```

![ポリモーフィック関連付けの図](images/polymorphic.png)

### 自己結合

データモデルを設計していると、時に自分自身に関連付けられる必要のあるモデルに出会うことがあります。たとえば、1つのデータベースモデルに全従業員を格納しておきたいが、マネージャーと部下(subordinate)の関係も追えるようにしておきたい場合が考えられます。この状況は、自己結合関連付けを使ってモデル化することができます。

```ruby
class Employee < ApplicationRecord
  has_many :subordinates, class_name: "Employee",
                          foreign_key: "manager_id"

  belongs_to :manager, class_name: "Employee"
end
```

上のように宣言しておくと、`@employee.subordinates`と`@employee.manager`が使えるようになります。

マイグレーションおよびスキーマでは、モデル自身にreferencesカラムを追加します。

```ruby
class CreateEmployees < ActiveRecord::Migration[5.0]
  def change
    create_table :employees do |t|
      t.references :manager, index: true
      t.timestamps
    end
  end
end
```

ヒントと注意事項
--------------------------

RailsアプリケーションでActive Recordの関連付けを効率的に使うためには、以下について知っておく必要があります。

* キャッシュ制御
* 名前衝突の回避
* スキーマの更新
* 関連付けのスコープ制御
* 双方向関連付け

### キャッシュ制御

関連付けのメソッドは、すべてキャッシュを中心に構築されています。最後に実行したクエリの結果はキャッシュに保持され、次回以降の操作で使えるようになります。このキャッシュはメソッド間でも共有されることに注意してください。例:

```ruby
author.books                 # データベースからbooksを取得する
author.books.size            # booksのキャッシュコピーが使われる
author.books.empty?          # booksのキャッシュコピーが使われる
```

データがアプリケーションの他の部分によって更新されている可能性に対応するために、キャッシュを再読み込みするにはどうしたらよいでしょうか。その場合は関連付けのメソッド呼び出しで`reload`を指定するだけで、キャッシュが破棄されてデータが再読み込みされます。

```ruby
author.books                 # データベースからbooksを取得する
author.books.size            # booksのキャッシュコピーが使われる
author.books.reload.empty?   # booksのキャッシュコピーが破棄される
                             # その後データベースから再度読み込まれる
```

### 名前衝突の回避

関連付けにはどんな名前でも使えるとは限りません。関連付けを作成すると、モデルにその名前のメソッドが追加されます。従って、`ActiveRecord::Base`のインスタンスで既に使われているような名前を関連付けに用いるのは禁物です。そのような名前を関連付けに使うと、基底メソッドが上書きされて不具合が生じる可能性があります。`attributes`や`connection`は関連付けに使ってはならない名前の例です。

### スキーマの更新

関連付けはきわめて便利ですが、残念ながら全自動の魔法ではありません。関連付けを使うからには、関連付けの設定に合わせてデータベースのスキーマを常に更新しておく責任が生じます。作成した関連付けにもよりますが、具体的には次の2つの作業が必要になります。1. `belongs_to`関連付けを使う場合は、外部キーを作成する必要があります。2. `has_and_belongs_to_many`関連付けを使う場合は、適切な結合テーブルを作成する必要があります。

#### `belongs_to`関連付けに対応する外部キーを作成する

`belongs_to`関連付けを宣言したら、対応する外部キーを作成する必要があります。以下のモデルを例にとります。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

上の宣言は、以下のようにbooksテーブル上の外部キー宣言によって裏付けられている必要があります。

```ruby
class CreateBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :books do |t|
      t.datetime :published_at
      t.string   :book_number
      t.integer  :author_id
    end
  end
end
```

モデルを先に作り、しばらく経過してから関連を追加で設定する場合は、`add_column`マイグレーションを作成して、必要な外部キーをモデルのテーブルに追加するのを忘れないようにしてください。

クエリのパフォーマンスを向上させたり、外部キー制約が正しくデータを参照しているかを保証するために、インデックスを追加するのは良い方法です。

```ruby
class CreateBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :books do |t|
      t.datetime :published_at
      t.string   :book_number
      t.integer  :author_id
    end

    add_index :books, :author_id
    add_foreign_key :books, :authors
  end
end
```

#### `has_and_belongs_to_many`関連付けに対応する結合テーブルを作成する

`has_and_belongs_to_many`関連付けを作成した場合は、それに対応する結合(join)テーブルを明示的に作成する必要があります。`:join_table`オプションを用いて明示的に結合テーブルの名前が指定されていない場合、Active Recordは2つのクラス名を辞書の並び順に連結して、適当に結合テーブル名をこしらえます。たとえばAuthorモデルとBookモデルを連結する場合、'a' は 'b' より辞書で先に出現するので "authors_books" というデフォルトの結合テーブル名が使われます。

WARNING: モデル名の並び順は`String`クラスの`<=>`演算子で計算されます。これは、2つの文字列の長さが異なり、短い方が長い方の途中まで完全に一致しているような場合、長い方の文字列は短い方よりも辞書上の並び順が前として扱われるということです。たとえば、"paper\_boxes" テーブルと "papers" テーブルがある場合、これらを結合すれば "papers\_paper\_boxes" となると推測されます。 "paper\_boxes" の方が長いので、常識的には並び順が後ろになると予測できるからです。しかし実際の結合テーブル名は "paper\_boxes\_papers" になってしまいます。これはアンダースコア '\_' の方が 's' よりも並びが前になっているためです。

生成された名前がどのようなものであれ、適切なマイグレーションを実行して結合テーブルを生成する必要があります。以下の関連付けを例にとって考えてみましょう。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

この関連付けに対応する `assemblies_parts` テーブルをマイグレーションで作成し、裏付けておく必要があります。このテーブルには主キーを設定しないでください。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :assemblies_parts, id: false do |t|
      t.integer :assembly_id
      t.integer :part_id
    end

    add_index :assemblies_parts, :assembly_id
    add_index :assemblies_parts, :part_id
  end
end
```

このテーブルはモデルを表さないので、`create_table`に`id: false`を渡します。こうしておかないとこの関連付けは正常に動作しません。モデルのIDが破損する、IDの競合で例外が発生するなど、`has_and_belongs_to_many`関連付けの動作が怪しい場合は、この設定を忘れていないかどうか再度確認してみてください。

`create_join_table`メソッドを使うことも可能です。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_join_table :assemblies, :parts do |t|
      t.index :assembly_id
      t.index :part_id
    end
  end
end
```

### 関連付けのスコープ制御

デフォルトでは、関連付けによって探索されるオブジェクトは、現在のモジュールのスコープ内のものだけです。Active Recordモデルをモジュール内で宣言している場合、この点に注意する必要があります。例：

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
       has_one :account
    end

    class Account < ApplicationRecord
       belongs_to :supplier
    end
  end
end
```

上のコードは正常に動作します。これは、`Supplier`クラスと`Account`クラスが同じスコープ内で定義されているためです。しかし下のコードは動作しません。`Supplier`クラスと`Account`クラスが異なるスコープ内で定義されているためです。

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
       has_one :account
    end
  end

  module Billing
    class Account < ApplicationRecord
       belongs_to :supplier
    end
  end
end
```

あるモデルと異なる名前空間にあるモデルを関連付けるには、関連付けの宣言で完全なクラス名を指定する必要があります

```ruby
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account,
      class_name: "MyApplication::Billing::Account"
    end
  end

  module Billing
    class Account < ApplicationRecord
      belongs_to :supplier,
      class_name: "MyApplication::Business::Supplier"
    end
  end
end
```

### 双方向関連付け

関連付けは、通常双方向で設定します。2つのモデル両方に関連を定義する必要があります。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
end
```

Active Recordは関連付けの設定から、これら２つのモデルが双方向の関連を共有していることを自動的に認識します。以下に示すとおり、Active Recordは`Author`オブジェクトのコピーを１つだけ読み出し、アプリケーションをより効率的かつ一貫性のあるデータに仕上げます。

```ruby
a = Author.first
b = a.books.first
a.first_name == b.author.first_name # => true
a.first_name = 'David'
a.first_name == b.author.first_name # => true
```

Active Recordでは標準的な名前同士の関連付けのほとんどをサポートしていて、自動的に認識することができます。一方で、Active Recordで次のようなオプションを使った場合、双方向の関連付けが自動的に認識されないようにすることもできます。

* `:conditions`
* `:through`
* `:polymorphic`
* `:class_name`
* `:foreign_key`

たとえば、次のようなモデルを宣言したケースを考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: 'Author', foreign_key: 'author_id'
end
```

この場合、Active Recordは双方向の関連付けを自動的に認識しません。

```ruby
a = Author.first
b = a.books.first
a.first_name == b.writer.first_name # => true
a.first_name = 'David'
a.first_name == b.writer.first_name # => false
```

Active Recordは`:inverse_of`オプションを提供していて、これを使うと双方向の関連付けを明示的に宣言することができます。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: 'writer'
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: 'Author', foreign_key: 'author_id'
end
```

`has_many`の関連付けを宣言するときに`:inverse_of`オプションも含めることで、Active Recordは双方向の関連付けを認識するようになります。

```ruby
a = Author.first
b = a.books.first
a.first_name == b.writer.first_name # => true
a.first_name = 'David'
a.first_name == b.writer.first_name # => true
```

関連付けの詳細情報
------------------------------

この節では、各関連付けの詳細を解説します。関連付けの宣言によって追加されるメソッドやオプションについても説明します。

### `belongs_to`関連付けの詳細

`belongs_to`関連付けは、別のモデルとの間に1対1の関連付けを作成します。データベースの用語で説明すると、この関連付けが行われているクラスには外部キーがあるということです。外部キーが自分のクラスではなく相手のクラスにあるのであれば、`belongs_to`ではなく`has_one`を使う必要があります。

#### `belongs_to`で追加されるメソッド

`belongs_to`関連付けを宣言したクラスでは、以下の5つのメソッドを自動的に利用できるようになります。

* `association`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`
* `reload_association`

これらのメソッドのうち、`association`の部分はプレースホルダであり、`belongs_to`の最初の引数である関連付け名をシンボルにしたものに置き換えられます。例えば次のように宣言をした場合

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

`Book`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
author
author=
build_author
create_author
create_author!
reload_author
```

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`build_`で始まるメソッドを使う必要があります。この場合`has_many`関連付けや`has_and_belongs_to_many`関連付けで使われる`association.build`メソッドは使わないでください。作成するには、`create_`で始まるメソッドをお使いください。

##### `association`

`association`メソッドは関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@author = @book.author
```

このオブジェクトに関連付けられたオブジェクトがデータベースから検索されたことがある場合は、キャッシュされたものを返します。この振る舞いをオーバーライドする（キャッシュを読み出さずにデータベースから直接読み込む）には、親オブジェクトが持つ`#reload_association`メソッドを呼び出します。

```ruby
@author = @book.reload.author
```

##### `association=(associate)`

`association=`メソッドは、引数のオブジェクトをそのオブジェクトに関連付けます。その背後では、関連付けられたオブジェクトから主キーを取り出し、そのオブジェクトの外部キーにその同じ値を設定しています。

```ruby
@book.author = @author
```

##### `build_association(attributes = {})`

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトは、値が返された時点ではまだ保存されて_いない_ことにご注意ください。

```ruby
@author = @book.build_author(author_number: 123,
                                  author_name: "John Doe")
```

##### `create_association(attributes = {})`

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@author = @book.create_author(author_number: 123,
                                   author_name: "John Doe")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。


#### `belongs_to`のオプション

Railsのデフォルトの`belongs_to`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときに渡すオプションとスコープブロックで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, dependent: :destroy,
    counter_cache: true
end
```

`belongs_to`関連付けでは以下のオプションがサポートされています。

* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:foreign_key`
* `:primary_key`
* `:inverse_of`
* `:polymorphic`
* `:touch`
* `:validate`
* `:optional`

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべての関連付けメンバを保存し、destroyフラグが立っているメンバを破棄します。`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは同じではありません。`:autosave`が存在しない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションでモデル名を直接指定できます。たとえば、書籍(book)が著者(author)に従属しているが実際の著者のモデル名が`Patron`である場合には、以下のように指定します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron"
end
```

##### `:counter_cache`

`:counter_cache`オプションは、従属しているオブジェクトの数の検索効率を向上させます。以下のモデルで説明します。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
class Author < ApplicationRecord
  has_many :books
end
```

上の宣言のままでは、`@author.books.size`の値を知るためにデータベースに対して`COUNT(*)`クエリを実行する必要があります。この呼び出しを避けるために、「従属している方のモデル(`belongs_to`を宣言している方のモデル)」にカウンタキャッシュを追加することができます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: true
end
class Author < ApplicationRecord
  has_many :books
end
```

上のように宣言すると、キャッシュ値が最新の状態に保たれ、次に`size`メソッドが呼び出されたときにその値が返されます。

ここで1つ注意が必要です。`:counter_cache`オプションは`belongs_to`宣言で指定しますが、実際に数を数えたいカラムは、相手のモデル(関連付けられている`has_many`モデル)の方に追加する必要があります。上の場合には、`Author`モデルの方に`books_count`カラムを追加する必要があります。

`counter_cache`オプションで`true`の代わりに任意のカラム名を設定すると、デフォルトのカラム名をオーバーライドできます。以下は、`books_count`の代わりに`count_of_books`を設定した場合の例です。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: :count_of_books
end
class Author < ApplicationRecord
  has_many :books
end
```

NOTE: `belongs_to`の関連付けをする時に、`:counter_cache`オプションを設定する必要があります。

カウンタキャッシュ用のカラムは、`attr_readonly`によって読み出し専用属性となるモデルのリストに追加されます。

##### `:dependent`

もし `:dependent` オプションの値が

* `:destroy` のときは、オブジェクトが削除された際に、関連付けられたオブジェクトの`destroy`メソッドが実行されます。
* `:delete` のときは、オブジェクトが削除された際に、関連付けられたオブジェクトが直接データベースから削除されます。`destroy`メソッドは実行されません。

WARNING: 他のクラスの`has_many` 関連付けとつながりのある `belongs_to` 関連付けに対してこのオプションを使ってはいけません。孤立したレコードがデータベースに残ってしまう可能性があります。

##### `:foreign_key`

Railsの慣例では、相手のモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使うと外部キーの名前を直接指定することができます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron",
                        foreign_key: "patron_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使う場合には、マイグレーションで明示的に定義する必要があります。

##### `:primary_key`

Railsでは慣習として、`id`カラムはそのテーブルの主キーとして使われます。`:primary_key`オプションを指定すると、指定された別のカラムを主キーとして設定することができます

たとえば、 `users`テーブルに`guid`という主キーがあるとします。 `todos`テーブルの外部キーである`user_id`カラムをその`guid`カラムと紐づけたい場合は、次のように`primary_key`を設定します。

```ruby
class User < ApplicationRecord
  self.primary_key = 'guid' # 主キーが guid になります
end

class Todo < ApplicationRecord
  belongs_to :user, primary_key: 'guid'
end
```

この時に`@user.todos.create`を実行すると、`@todo`レコードは`user_id`を`@user`の`guid`として持つようになります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`has_many`関連付けまたは`has_one`関連付けの名前を指定します。`:polymorphic`オプションと組み合わせた場合は無効です。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: :author
end

class Book < ApplicationRecord
  belongs_to :author, inverse_of: :books
end
```

##### `:polymorphic`

`:polymorphic`オプションに`true`を指定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けの詳細については[このガイドの説明](#ポリモーフィック関連付け)を参照してください。

##### `:touch`

`:touch`オプションを`true`に設定すると、関連付けられているオブジェクトが保存またはdestroyされるたびに、そのオブジェクトの`updated_at`または`updated_on`タイムスタンプが現在時刻に設定されます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: true
end

class Author < ApplicationRecord
  has_many :books
end
```

上の例の場合、Bookクラスは、関連付けられているAuthorのタイムスタンプを保存時またはdestroy時に更新します。更新時に特定のタイムスタンプ属性を指定することもできます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at
end
```

##### `:validate`

`:validate`オプションを`true`に設定すると、関連付けられたオブジェクトが保存時に必ず検証(validation)されます。デフォルトは`false`であり、この場合関連付けられたオブジェクトは保存時に検証されません。

##### `:optional`

`:optional`オプションを`true`に設定すると、関連付けされたオブジェクトの存在性のバリデーションが実行されないようになります。デフォルトではこのオプションは`false`となっています。

#### `belongs_to`のスコープ

場合によっては`belongs_to`で使われるクエリをカスタマイズしたくなることがあります。スコープブロックを使ってこのようなカスタマイズを行うことができます。以下に例を示します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { where active: true },
                        dependent: :destroy
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class book < ApplicationRecord
  belongs_to :author, -> { where active: true }
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class LineItem < ApplicationRecord
  belongs_to :book
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :line_items
end

class Author < ApplicationRecord
  has_many :books
end
```

LineItemから著者名(Author)を`@line_item.book.author`のように直接取り出す機会が頻繁にある場合は、LineItemとBookの関連付けを行なう時にAuthorをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。

```ruby
class LineItem < ApplicationRecord
  belongs_to :book, -> { includes :author }
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :line_items
end

class Author < ApplicationRecord
  has_many :books
end
```

NOTE: 直接の関連付けでは`includes`を使う必要はありません。`Book belongs_to :author`のような直接の関連付けでは必要に応じて自動的にeager-loadされます。

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトから取り出した内容は読み出し専用になります。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

TIP: `select`を`belongs_to`関連付けで使う場合、正しい結果を得るために`:foreign_key`オプションを必ず設定してください。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを使うと、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @book.author.nil?
  @msg = "No author found for this book"
end
```

#### オブジェクトが保存されるタイミング

オブジェクトを`belongs_to`関連付けに割り当てても、そのオブジェクトが自動的に保存されるわけでは_ありません_。関連付けられたオブジェクトが保存されることもありません。

### `has_one`関連付けの詳細

`has_one`関連付けは他のモデルと1対1対応します。データベースの観点では、この関連付けでは相手のクラスが外部キーを持ちます。相手ではなく自分のクラスが外部キーを持っているのであれば、`belongs_to`を使うべきです。

#### `has_one`で追加されるメソッド

`has_one`関連付けを宣言したクラスでは、以下の5つのメソッドを自動的に利用できるようになります。

* `association`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

これらのメソッドのうち、`association`の部分はプレースホルダであり、`has_one`の最初の引数である関連付け名をシンボルにしたものに置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Supplier < ApplicationRecord
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

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`build_`で始まるメソッドを使う必要があります。この場合`has_many`関連付けや`has_and_belongs_to_many`関連付けで使われる`association.build`メソッドは使わないでください。作成するには、`create_`で始まるメソッドをお使いください。

##### `association`

`association`メソッドは関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@account = @supplier.account
```

関連付けられたオブジェクトがデータベースから検索されたことがある場合は、キャッシュされたものを返します。キャッシュを読み出さずにデータベースから直接読み込ませたい場合は、親オブジェクトが持つ`#reload`メソッドを呼び出します。

```ruby
@account = @supplier.reload.account
```

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

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

#### `has_one`のオプション

Railsのデフォルトの`has_one`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Supplier < ApplicationRecord
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

`:as`オプションを設定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けの詳細については[このガイドの説明](#ポリモーフィック関連付け)を参照してください。

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは同じではありません。`:autosave`が存在しない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションでモデル名を直接指定できます。たとえば、Supplierにアカウントが1つあり、アカウントを含むモデルの実際の名前が`Account`ではなく`Billing`になっている場合、以下のようにモデル名を指定できます。

```ruby
class Supplier < ApplicationRecord
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

Railsの慣例では、相手のモデル上の外部キーを保持しているカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使うと外部キーの名前を直接指定することができます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, foreign_key: "supp_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使う場合には、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。`:through`または`:as`オプションと組み合わせた場合は無効です。

```ruby
class Supplier < ApplicationRecord
  has_one :account, inverse_of: :supplier
end

class Account < ApplicationRecord
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

`:through`オプションは、[このガイドで既に説明した](#has-one-through関連付け)`has_one :through`関連付けのクエリを実行する際に経由する結合モデルを指定します。

##### `:validate`

`:validate`オプションを`true`に設定すると、関連付けられたオブジェクトが保存時に必ず検証(validation)されます。デフォルトは`false`であり、この場合関連付けられたオブジェクトは保存時に検証されません。

#### `has_one`のスコープについて

場合によっては`has_one`で使われるクエリをカスタマイズしたくなることがあります。スコープブロックを使うと、このようなカスタマイズを行うことができます。以下に例を示します。

```ruby
class Supplier < ApplicationRecord
  has_one :account, -> { where active: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Supplier < ApplicationRecord
  has_one :account, -> { where "confirmed = 1" }
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end

class Account < ApplicationRecord
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ApplicationRecord
  has_many :accounts
end
```

上の例で、Supplierから代表(Representative)を`@supplier.account.representative`のように直接取り出す機会が頻繁にあるのであれば、SupplierからAccountへの関連付けにRepresentativeをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, -> { includes :representative }
end

class Account < ApplicationRecord
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ApplicationRecord
  has_many :accounts
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを使うと、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @supplier.account.nil?
  @msg = "No account found for this supplier"
end
```

#### オブジェクトが保存されるタイミング

`has_one`関連付けにオブジェクトをアサインすると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。さらに、置き換えられるオブジェクトは、これは外部キーが変更されたことによってすべて自動的に保存されます。

関連付けられているオブジェクト同士のいずれか一方が検証(validation)のために保存に失敗すると、アサインの状態からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_one`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存された場合は、子オブジェクトは保存されます。

`has_one`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`build_association`メソッドをお使いください。

### `has_many`関連付けの詳細

`has_many`関連付けは、他のモデルとの間に「1対多」のつながりを作成します。データベースの観点では、この関連付けにおいては相手のクラスが外部キーを持ちます。この外部キーは相手のクラスのインスタンスを参照します。

#### `has_many`で追加されるメソッド

`has_many`関連付けを宣言したクラスでは、以下の16のメソッドを自動的に利用できるようになります。

* `collection`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=(objects)`
* `collection_singular_ids`
* `collection_singular_ids=(ids)`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {}, ...)`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`
* `collection.reload`

上のメソッドの`collection`の部分はプレースホルダであり、実際には`has_many`への1番目の引数として渡されたシンボルに置き換えられます。また、`collection_singular`の部分はシンボルの単数形に置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

これにより、`Author`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
books
books<<(object, ...)
books.delete(object, ...)
books.destroy(object, ...)
books=(objects)
book_ids
book_ids=(ids)
books.clear
books.empty?
books.size
books.find(...)
books.where(...)
books.exists?(...)
books.build(attributes = {}, ...)
books.create(attributes = {})
books.create!(attributes = {})
books.reload
```

##### `collection`

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books
```

##### `collection<<(object, ...)`

`collection<<`メソッドは、1つ以上のオブジェクトをコレクションに追加します。このとき、追加されるオブジェクトの外部キーは、呼び出し側モデルの主キーに設定されます。

```ruby
@author.books << @book1
```

##### `collection.delete(object, ...)`

`collection.delete`メソッドは、外部キーを`NULL`に設定することで、コレクションから1つまたは複数のオブジェクトを削除します。

```ruby
@author.books.delete(@book1)
```

WARNING: 削除のされ方はこれだけではありません。オブジェクト同士が`dependent: :destroy`で関連付けられている場合はdestroyされますが、オブジェクト同士が`dependent: :delete_all`で関連付けられている場合はdeleteされますのでご注意ください。

##### `collection.destroy(object, ...)`

`collection.destroy`は、コレクションに関連付けられているオブジェクトに対して`destroy`を実行することで、コレクションから1つまたは複数のオブジェクトを削除します。

```ruby
@author.books.destroy(@book1)
```

WARNING: この場合オブジェクトは_無条件で_データベースから削除されます。このとき、`:dependent`オプションがどのように設定されていても無視して削除が行われます。

##### `collection=(objects)`

`collection=`メソッドは、指定したオブジェクトでそのコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。この変更はデータベースの中で存続します。

##### `collection_singular_ids`

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@book_ids = @author.book_ids
```

##### `collection_singular_ids=(ids)`

`collection_singular_ids=`メソッドは、指定された主キーidを持つオブジェクトの集まりでコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。この変更はデータベースで永続化されます。

##### `collection.clear`

`collection.clear`メソッドは、`dependent`オプションによって指定された手法に従って、コレクションからすべてのオブジェクトを削除します。もしオプションが渡されていなかった場合、デフォルトの手法に従います。デフォルトでは、`has_many :through`の関連付けの場合は`delete_all`が渡され、`has_many`の関連付けの場合は外部キーに`NULL`がセットされます。

```ruby
@author.books.clear
```

WARNING: `dependent: :delete_all`の場合と同様に、オブジェクトが`dependent: :destroy`で関連付けされていた場合、それらのオブジェクトは削除されます。

##### `collection.empty?`

`collection.empty?`メソッドは、関連付けられたオブジェクトがコレクションの中に1つもない場合に`true`を返します。

```erb
<% if @author.books.empty? %>
  No Books Found
<% end %>
```

##### `collection.size`

`collection.size`メソッドは、コレクションに含まれるオブジェクトの数を返します。

```ruby
@book_count = @author.books.size
```

##### `collection.find(...)`

`collection.find`メソッドは、コレクションに含まれるオブジェクトを検索します。このメソッドで使われる文法は、`ActiveRecord::Base.find`で使われているものと同じです。

```ruby
@available_book = @author.books.find(1)
```

##### `collection.where(...)`

`collection.where`メソッドは、コレクションに含まれているメソッドを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み(lazy load)される点にご注意ください。つまり、オブジェクトに実際にアクセスが行われる時にだけデータベースへのクエリが発生します。

```ruby
@available_books = @author.books.where(available: true) # No query yet
@available_book = @available_books.first # Now the database will be queried
```

##### `collection.exists?(...)`

`collection.exists?`メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。このメソッドで使われる文法は、[`ActiveRecord::Base.exists?`](http://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F)で使われているものと同じです。

##### `collection.build(attributes = {}, ...)`

`collection.build`メソッドは、関連付けが行われた1つのオブジェクトまたはオブジェクトの配列を返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが作成されます。関連付けられたオブジェクトは、値が返された時点ではまだ保存されて_いない_ことにご注意ください。

```ruby
@book = @author.books.build(published_at: Time.now,
                                book_number: "A12345")

@books = @author.books.build([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
    ...
```

##### `collection.create(attributes = {})`

`collection.create`メソッドは、関連付けが行われた新しい1つのオブジェクトまたは新しいオブジェクトの配列を返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが作成されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@book = @author.books.create(published_at: Time.now,
                                 book_number: "A12345")

@books = @author.books.create([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
    ...
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### `collection.reload`

`collection.reload`は、関連付けられたすべてのオブジェクトのリレーションを返し、データベースから強制的に読み込みます。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books.reload
```

#### `has_many`のオプション

Railsのデフォルトの`has_many`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :delete_all, validate: false
end
```

`has_many`関連付けでは以下のオプションがサポートされます。

* `:as`
* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

`:as`オプションを設定すると、ポリモーフィック関連付けであることが指定されます。([このガイドの説明](#ポリモーフィック関連付け)を参照)

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは同じではありません。`:autosave`が存在しない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションでモデル名を直接指定できます。たとえば、1人の著者(author)が複数の書籍(books)を持っているが、実際の書籍モデル名が`Transaction`である場合には以下のように指定します。

```ruby
class Author < ApplicationRecord
  has_many :books, class_name: "Transaction"
end
```

##### `:counter_cache`

このオプションは、`:counter_cache`オプションを任意の名前に変更したい場合に使います。このオプションは、[belongs_toの関連付け](#belongs-to%E3%81%AE%E3%82%AA%E3%83%97%E3%82%B7%E3%83%A7%E3%83%B3)で`:counter_cache`の名前を変更したときにのみ必要になります。

##### `:dependent`

オーナーオブジェクトがdestroyされたときに、オーナーに関連付けられたオブジェクトをどうするかを制御します。

* `:destroy`を指定すると、関連付けられたオブジェクトもすべて同時にdestroyされます。
* `:delete_all`を指定すると、関連付けられたオブジェクトはすべてデータベースから直接削除されます。このときコールバックは実行されません。
* `:nullify`を指定すると、外部キーはすべて`NULL`に設定されます。このときコールバックは実行されません。
* `:restrict_with_exception`を指定すると、関連付けられたレコードが1つでもある場合に例外が発生します。
* `:restrict_with_error`を指定すると、関連付けられたオブジェクトが1つでもある場合にエラーがオーナーに追加されます。

##### `:foreign_key`

Railsの慣例では、相手のモデル上の外部キーを保持しているカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使うことで、外部キーの名前を直接指定できます。

```ruby
class Author < ApplicationRecord
  has_many :books, foreign_key: "cust_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作ることはありません。外部キーを使う場合には、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。`:through`または`:as`オプションと組み合わせた場合は無効です。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: :author
end

class Book < ApplicationRecord
  belongs_to :author, inverse_of: :books
end
```

##### `:primary_key`

Railsの慣例では、関連付けの主キーは`id`カラムに保存されていることを前提とします。`:primary_key`オプションで主キーを明示的に指定することでこれを上書きすることができます。

`users`テーブルに主キーとして`id`カラムがあり、その他に`guid`カラムもあるとします。要件として、`todos`テーブルが (`id`ではなく) `guid`カラムの値を外部キーとして使いたいとします。これは以下のようにすることで実現できます。

```ruby
class User < ApplicationRecord
  has_many :todos, primary_key: :guid
end
```

このとき `@todo = @user.todos.create`を実行すると、`@todo`レコードの`user_id`の値は `@user`の`guid`になります。


##### `:source`

`:source`オプションは、`has_many :through`関連付けにおける「ソースの」関連付け名、つまり関連付け元の名前を指定します。このオプションは、関連付け名から関連付け元の名前が自動的に推論できない場合を除けば使う必要はありません。

##### `:source_type`

`:source_type`オプションは、ポリモーフィック関連付けを介して行われる`has_many :through`関連付けにおける「ソースの」関連付けタイプ、つまり関連付け元のタイプを指定します。

##### `:through`

`:through`オプションは、[このガイドで既に説明した](#has-one-through関連付け)`has_one :through`関連付けのクエリを実行する際に経由する結合モデルを指定します。

##### `:validate`

`:validate`オプションを`false`に設定すると、関連付けられたオブジェクトは保存時に検証(validation)されません。デフォルトは`true`であり、この場合関連付けられたオブジェクトは保存時に検証されます。

#### `has_many`のスコープについて

場合によっては`has_many`で使われるクエリをカスタマイズしたくなることがあります。スコープブロックを使うと、このようなカスタマイズを行うことができます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { where processed: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `distinct`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Author < ApplicationRecord
  has_many :confirmed_books, -> { where "confirmed = 1" },
    class_name: "Book"
end
```

条件をハッシュで指定することもできます。

```ruby
class Author < ApplicationRecord
  has_many :confirmed_books, -> { where confirmed: true },
                              class_name: "Book"
end
```

`where`オプションでハッシュを使った場合、この関連付けで作成されたレコードは、自動的にこのハッシュを使うスコープに含まれるようになります。この例の場合、`@author.confirmed_books.create`または`@author.confirmed_books.build`を実行すると、confirmedカラムの値が`true`の書籍(book)が常に作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については[後述します](#関連付けの拡張)。

##### `group`

`group`メソッドは、結果をグループ化する際の属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使われます。

```ruby
class Author < ApplicationRecord
  has_many :line_items, -> { group 'books.id' },
                        through: :books
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。以下のモデルを例にとって考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :line_items
end

class LineItem < ApplicationRecord
  belongs_to :book
end
```

著者名(Author)からLineItemを`@author.books.line_items`のように直接取り出す機会が頻繁にあるのであれば、AuthorとBookの関連付けを行なう時にLineItemをあらかじめincludeしておくことで無駄なクエリを減らし、効率を高めることができます。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { includes :line_items }
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :line_items
end

class LineItem < ApplicationRecord
  belongs_to :book
end
```

##### `limit`

`limit`メソッドは、関連付けを用いて取得できるオブジェクトの総数を制限するのに使います。

```ruby
class Author < ApplicationRecord
  has_many :recent_books,
    -> { order('published_at desc').limit(100) },
    class_name: "Book"
end
```

##### `offset`

`offset`メソッドは、関連付けを用いてオブジェクトを取得する際の開始オフセットを指定します。たとえば、`-> { offset(11) }`と指定すると、最初の11レコードはスキップされ、12レコード目から返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトに与えられる順序を指定します。内部的にはSQLの`ORDER BY`句が使われます。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order "date_confirmed DESC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

WARNING: 独自の`select`メソッドを使う場合には、関連付けられているモデルの主キーカラムと外部キーカラムを必ず含めておいてください。これを行わなかった場合、Railsでエラーが発生します。

##### `distinct`

`distinct`メソッドは、コレクション内で重複が発生しないようにします。
このメソッドは`:through`オプションと併用するときに特に便利です。

```ruby
class Person < ApplicationRecord
  has_many :readings
  has_many :articles, through: :readings
end

person = Person.create(name: 'John')
article = Article.create(name: 'a1')
person.articles << article
person.articles << article
person.articles.inspect # => [#<Article id: 5, name: "a1">, #<Article id: 5, name: "a1">]
Reading.all.inspect     # => [#<Reading id: 12, person_id: 5, article_id: 5>, #<Reading id: 13, person_id: 5, article_id: 5>]
```

上の例の場合、readingが2つあって重複しており、`person.articles`を実行すると、どちらも同じ記事を指しているにもかかわらず、両方とも取り出されてしまいます。

今度は`distinct`を設定してみましょう。

```ruby
class Person
  has_many :readings
  has_many :articles, -> { distinct }, through: :readings
end

person = Person.create(name: 'Honda')
article = Article.create(name: 'a1')
person.articles << article
person.articles << article
person.articles.inspect # => [#<Article id: 7, name: "a1">]
Reading.all.inspect     # => [#<Reading id: 16, person_id: 7, article_id: 7>, #<Reading id: 17, person_id: 7, article_id: 7>]
```

上の例でもreadingは2つあって重複しています。一方で、`person.articles`を実行すると、１つのarticleのみを表示します。これはコレクションが一意のレコードのみを読み出しているからです。

挿入時にも同様に、現在残っているすべてのレコードが一意であるようにする(関連付けを検査したときに重複レコードが決して発生しないようにする)には、テーブル自体に一意のインデックスを追加する必要があります。たとえば、`readings`というテーブルがあり、その記事を1人の人物（person）にのみ追加できるようにしたい場合、マイグレーションに以下を追加します。

```ruby
add_index :readings, [:person_id, :article_id], unique: true
```

一度ユニークなインデックスを持つと、ある記事をpersonに２回追加したときに
`ActiveRecord::RecordNotUnique`エラーが発生するようになります

```ruby
person = Person.create(name: 'Honda')
article = Article.create(name: 'a1')
person.articles << article
person.articles << article # => ActiveRecord::RecordNotUnique
```

なお、一意性のチェックに`include?`などを使うと競合が発生しやすいので注意が必要です。関連付けで強制的に一意になるようにするために`include?`を使わないでください。たとえば上のarticleを例にとると、以下のコードでは競合が発生しやすくなります。これは、複数のユーザーが同時にこのコードを実行する可能性があるためです。

```ruby
person.articles << article unless person.articles.include?(article)
```

#### オブジェクトが保存されるタイミング

`has_many`関連付けにオブジェクトをアサインすると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトをアサインすると、それらはすべて保存されます。

関連付けられているオブジェクトの1つでも検証(validation)エラーで保存に失敗すると、アサインの式からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_many`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバはすべて保存されます。

`has_many`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`collection.build`メソッドをお使いください。

### `has_and_belongs_to_many`関連付けの詳細

`has_and_belongs_to_many`関連付けは、他のモデルとの間に「多対多」のつながりを作成します。データベースの観点では、2つのクラスは中間で結合テーブルを介して関連付けられます。この結合テーブルには、両方のクラスを指す外部キーがそれぞれ含まれます。

#### `has_and_belongs_to_many`で追加されるメソッド

`has_and_belongs_to_many`関連付けを宣言したクラスでは、以下の16のメソッドを自動的に利用できるようになります。

* `collection`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=(objects)`
* `collection_singular_ids`
* `collection_singular_ids=(ids)`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {})`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`
* `collection.reload`

上のメソッドの`collection`の部分はプレースホルダであり、実際には`has_and_belongs_to_many`への1番目の引数として渡されたシンボルに置き換えられます。また、`collection_singular`の部分はシンボルの単数形に置き換えられます。たとえば以下の宣言を見てみましょう。

```ruby
class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

これにより、`Part`モデルのインスタンスで以下のメソッドが使えるようになります。

```ruby
assemblies
assemblies<<(object, ...)
assemblies.delete(object, ...)
assemblies.destroy(object, ...)
assemblies=(objects)
assembly_ids
assembly_ids=(ids)
assemblies.clear
assemblies.empty?
assemblies.size
assemblies.find(...)
assemblies.where(...)
assemblies.exists?(...)
assemblies.build(attributes = {}, ...)
assemblies.create(attributes = {})
assemblies.create!(attributes = {})
assemblies.reload
```

##### 追加のカラムメソッド

`has_and_belongs_to_many`関連付けで使う中間の結合テーブルが、2つの外部キー以外に何かカラムを含んでいる場合、これらのカラムは関連付けを介して取り出されるレコードに属性として追加されます。属性が追加されたレコードは常に読み出し専用になります。このようにして読み出された属性に対する変更は保存できないためです。

WARNING: `has_and_belongs_to_many`関連付けで使う結合テーブルにこのような余分なカラムを追加することはお勧めできません。2つのモデルを多対多で結合する結合テーブルでこのような複雑な振る舞いが必要になるのであれば、`has_and_belongs_to_many`ではなく`has_many :through`をお使いください。


##### `collection`

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

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

##### `collection.destroy(object, ...)`

`collection.destroy`メソッドは、結合テーブル上のレコードを削除することで、1つまたは複数のオブジェクトをコレクションから削除します。このメソッドを実行してもオブジェクトはdestroyされません。

```ruby
@part.assemblies.destroy(@assembly1)
```

##### `collection=(objects)`

`collection=`メソッドは、指定したオブジェクトでそのコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。この変更はデータベースで永続化されます。

##### `collection_singular_ids`

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@assembly_ids = @part.assembly_ids
```

##### `collection_singular_ids=(ids)`

`collection_singular_ids=`メソッドは、指定された主キーidを持つオブジェクトの集まりでコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。この変更はデータベースで永続化されます。

##### `collection.clear`

`collection.clear`メソッドは、結合テーブル上のレコードを削除し、それによってすべてのオブジェクトをコレクションから削除します。このメソッドを実行しても、関連付けられたオブジェクトはdestroyされません。

##### `collection.empty?`

`collection.empty?`メソッドは、関連付けられたオブジェクトがコレクションに含まれていない場合に`true`を返します。

```ruby
<% if @part.assemblies.empty? %>
  ※この部分はどのアセンブリでも使われません。
<% end %>
```

##### `collection.size`

`collection.size`メソッドは、コレクションに含まれるオブジェクトの数を返します。

```ruby
@assembly_count = @part.assemblies.size
```

##### `collection.find(...)`

`collection.find`メソッドは、コレクションに含まれるオブジェクトを検索します。このメソッドで使われる文法は、`ActiveRecord::Base.find`で使われているものと同じです。このメソッドでは、オブジェクトがコレクション内で従う必要のある追加条件も加味されます。

```ruby
@assembly = @part.assemblies.find(1)
```

##### `collection.where(...)`

`collection.where`メソッドは、コレクションに含まれているメソッドを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み(lazy load)される点にご注意ください。つまり、オブジェクトに実際にアクセスが行われる時にだけデータベースへのクエリが発生します。このメソッドでは、オブジェクトがコレクション内で従う必要のある追加条件も加味されます。

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

##### `collection.exists?(...)`

`collection.exists?`メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。このメソッドで使われる文法は、[`ActiveRecord::Base.exists?`](http://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F)で使われているものと同じです。

##### `collection.build(attributes = {})`

`collection.build`メソッドは、関連付けが行われたオブジェクトを1つ返します。このオブジェクトは、渡された属性でインスタンス化され、その結合テーブルを介してリンクが作成されます。ただし、関連付けられたオブジェクトはこの時点では保存されて_いない_ことにご注意ください。

```ruby
@assembly = @part.assemblies.build({assembly_name: "Transmission housing"})
```

##### `collection.create(attributes = {})`

`collection.create`メソッドは、関連付けが行われたオブジェクトを1つ返します。このオブジェクトは、渡された属性を用いてインスタンス化され、結合テーブルを介してリンクが作成されます。そして、関連付けられたモデルで指定されている検証がすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@assembly = @part.assemblies.create({assembly_name: "Transmission housing"})
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードがinvalidの場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### `collection.reload`

`collection.reload`は、関連付けられたすべてのオブジェクトのリレーションを返し、データベースから強制的に読み込みます。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

 ```ruby
@assemblies = @part.assemblies.reload
```

#### `has_and_belongs_to_many`のオプション

Railsのデフォルトの`has_and_belongs_to_many`関連付けは、ほとんどの場合カスタマイズ不要ですが、時には関連付けの動作をカスタマイズしたくなることもあると思います。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { readonly },
                                       autosave: true
end
```

`has_and_belongs_to_many`関連付けでは以下のオプションがサポートされます。

* `:association_foreign_key`
* `:autosave`
* `:class_name`
* `:foreign_key`
* `:join_table`
* `:validate`

##### `:association_foreign_key`

Railsの慣例では、相手のモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使われることを前提とします。`:association_foreign_key`オプションを使うと、外部キーの名前を直接指定できます。

TIP: `:foreign_key`オプションおよび`:association_foreign_key`オプションは、多対多の自己結合を行いたいときに便利です。以下に例を示します。

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべての関連付けられたメンバを保存し、destroyフラグが立っているメンバを破棄します。`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは同じではありません。`:autosave`が存在しない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連名から関連相手のオブジェクト名を生成できない事情がある場合、`:class_name`オプションでモデル名を直接指定できます。たとえば、1つの部品(Part)が複数の組み立て(Assembly)で使われ、組み立てを含む実際のモデル名が`Gadget`である場合、次のように設定します。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, class_name: "Gadget"
end
```

##### `:foreign_key`

Railsの慣例では、そのモデルを指す外部キーを保持している結合テーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使われることを前提とします。`:foreign_key`オプションを使うと、外部キーの名前を直接指定できます。

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:join_table`

辞書順に基いて生成された結合テーブルのデフォルト名が気に入らない場合、`:join_table`オプションを使ってデフォルトのテーブル名を上書きできます。

##### `:validate`

`:validate`オプションを`false`に設定すると、関連付けられたオブジェクトは保存時に検証(validation)されません。デフォルトは`true`であり、この場合関連付けられたオブジェクトは保存時に検証されます。

#### `has_and_belongs_to_many`のスコープについて

`has_and_belongs_to_many`で使われるクエリをカスタマイズしたいときがあります。スコープブロックを使うと、このようなカスタマイズを行えます。以下に例を示します。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `distinct`

##### `where`

`where`は、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

条件はハッシュで指定することもできます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where factory: 'Seattle' }
end
```

`where`オプションでハッシュを使う場合、この関連付けで作成されたレコードは自動的にこのハッシュを使うスコープに含まれるようになります。この例の場合、`@parts.assemblies.create`または`@parts.assemblies.build`を実行すると、`factory`カラムに`Seattle`を持つオブジェクトが作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については[後述します](#関連付けの拡張)。

##### `group`

`group`メソッドは、結果をグループ化する際の属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使われます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager-load (訳注:preloadとは異なる)しておきたい第2関連付けを指定することができます。

##### `limit`

`limit`メソッドは、関連付けを用いて取得できるオブジェクトの総数を制限するのに使います。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `offset`

`offset`メソッドは、関連付けを用いてオブジェクトを取得する際の開始オフセットを指定します。たとえばoffset(11)と指定すると、最初の11レコードはスキップされ、12レコード目から返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトに与えられる順序を指定します。内部的にはSQLの`ORDER BY`句が使われます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order "assembly_name ASC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを取り出すときに読み出し専用になります。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句を上書きします。Railsはデフォルトではすべてのカラムを取り出します。

##### `distinct`

`distinct`メソッドは、コレクション内の重複を削除します。

#### オブジェクトが保存されるタイミング

`has_and_belongs_to_many`関連付けにオブジェクトをアサインすると、結合テーブルを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトをアサインすると、それらはすべて保存されます。

関連付けられているオブジェクト同士の1つでも検証(validation)のために保存に失敗すると、アサインの状態からは`false`が返され、アサインはキャンセルされます。

親オブジェクト(`has_and_belongs_to_many`関連付けを宣言している側のオブジェクト)が保存されない場合(つまり`new_record?`が`true`を返す場合)、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバはすべて保存されます。

`has_and_belongs_to_many`関連付けにオブジェクトをアサインし、しかもそのオブジェクトを保存したくない場合、`collection.build`メソッドをお使いください。

### 関連付けのコールバック

通常のコールバックは、Active Recordオブジェクトのライフサイクルの中でフックされます。これにより、オブジェクトのさまざまな場所でコールバックを実行できます。たとえば、`:before_save`コールバックを使うと、オブジェクトが保存される直前に何かを実行することができます。

関連付けのコールバックも、上のような通常のコールバックとだいたい同じですが、(Active Recordオブジェクトではなく)コレクションのライフサイクルによってイベントがトリガされる点が異なります。以下の4つの関連付けコールバックを利用できます。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

これらのオプションを関連付けの宣言に追加することで、関連付けコールバックを定義できます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_credit_limit

  def check_credit_limit(book)
    ...
  end
end
```

Railsは、追加されるオブジェクトや削除されるオブジェクトをコールバックに(引数として)渡します。

1つのイベントで複数のコールバックを使いたい場合には、配列で渡します。

```ruby
class Author < ApplicationRecord
  has_many :books,
    before_add: [:check_credit_limit, :calculate_shipping_charges]

  def check_credit_limit(book)
    ...
  end

  def calculate_shipping_charges(book)
    ...
  end
end
```

`before_add`コールバックが例外を発生した場合、オブジェクトはコレクションに追加されません。同様に、`before_remove`で例外が発生した場合も、オブジェクトはコレクションに削除されません。

### 関連付けの拡張

Railsは自動的に関連付けのプロキシオブジェクトをビルドしますが、開発者はこれをカスタマイズすることができます。無名モジュール(anonymous module)を用いてこれらのオブジェクトを拡張(検索、作成などのメソッドを追加)することができます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books do
    def find_by_book_prefix(book_number)
      find_by(category_id: book_number[0..2])
    end
  end
end
```

拡張を多くの関連付けで共有したい場合は、名前付きの拡張モジュールを使うこともできます。以下に例を示します。

```ruby
module FindRecentExtension
  def find_recent
    where("created_at > ?", 5.days.ago)
  end
end

class Author < ApplicationRecord
  has_many :books, -> { extending FindRecentExtension }
end

class Supplier < ApplicationRecord
  has_many :deliveries, -> { extending FindRecentExtension }
end
```

関連付けプロキシの内部を参照するには、`proxy_association`アクセサにある以下の3つの属性を使います。

* `proxy_association.owner`は、関連付けを所有するオブジェクトを返します。
* `proxy_association.reflection`は、関連付けを記述するリフレクションオブジェクトを返します。
* `proxy_association.target`は、`belongs_to`または`has_one`関連付けのオブジェクトを返すか、`has_many`または`has_and_belongs_to_many`関連付けオブジェクトのコレクションを返します。

シングルテーブル継承
------------------------

異なるモデル間でフィールドや振る舞いを共有したい場合があります。`Car`モデル、`Motorcycle`モデル、`Bicycle`モデルを持っていた場合を考えてみましょう。このとき`color`や`price`といったフィールド、そしていくつかの関連メソッドを共有したい場合が考えられます。しかし、モデルごとに振る舞いやコントローラーが異なります。

Railsではこのような状況にも簡単に対応できます。まず、各モデルのベースとなる`Vehicle`モデルを生成します。

```bash
$ rails generate model vehicle type:string color:string price:decimal{10.2}
```

"type"フィールドを追加している点にご注目ください。すべてのモデルはデータベース上のテーブルに保存されるため、Railsはこのカラムに該当するモデル名を保存します。この例では、カラムには "Car"、"Motorcycle"、もしくは"Bicycle"が保存されます。今回のシングルテーブル継承（STI: Single Table Inheritance）ではテーブルにこの"type"フィールドがないとうまく動きません。

次に、`Vehicle`モデルを継承して３つの各モデルを生成します。このとき、`--parent=PARENT`オプションを使って特定の親モデルを継承している点にご注目ください。このオプションを使うと（該当するテーブルが既に存在しているため）マイグレーションファイルを生成せずに済みます。

たとえば`Car`モデルの場合は以下のようになります。

```bash
$ rails generate model car --parent=Vehicle
```

このときに生成されるモデルは次のとおりです。

```ruby
class Car < Vehicle
end
```

これによって`Vehicle`モデルに追加されたすべての振る舞いが`Car`モデルにも追加されるようになります。関連付けやpublicメソッドなども同様に追加されます。

この状態で新しく作成した`Car`を保存すると、`type`フィールドに"Car"が代入されたデータが`vehicles`テーブルに追加されます。

```ruby
Car.create(color: 'Red', price: 10000)
```

なお、実際に発行されるSQLは次のようになります。

```sql
INSERT INTO "vehicles" ("type", "color", "price") VALUES ('Car', 'Red', 10000)
```

`Car`のレコードを取得するクエリを送信すると、vehiclesテーブル中の`Car`が検索されるようになります。

```ruby
Car.all
```

実際のクエリは次のようになります。

```sql
SELECT "vehicles".* FROM "vehicles" WHERE "vehicles"."type" IN ('Car')
```
