Active Record の関連付け
==========================

本ガイドでは、Active Recordの関連付け機能（アソシエーション）について解説します。

このガイドの内容:

* Active Recordのモデル同士の関連付けを宣言する方法
* Active Recordのモデルを関連付けるさまざまな方法
* 関連付けを作成すると自動的に追加されるメソッドの利用方法

--------------------------------------------------------------------------------

関連付けを使う理由
-----------------

Railsの「関連付け（アソシエーション: association）」は、2つのActive Recordモデル同士のつながりを指します。モデルとモデルの間で関連付けを行なう理由はおわかりでしょうか。関連付けを行うことで、自分のコードの共通操作がシンプルになって扱いやすくなります。

簡単なRailsアプリケーションを例にとって説明しましょう。このアプリケーションにはAuthor（著者）モデルとBook（書籍）モデルがあります。一人の著者は、複数の書籍を持っています。

関連付けを設定していない状態では、モデルの宣言は以下のようになります。

```ruby
class Author < ApplicationRecord
end

class Book < ApplicationRecord
end
```

ここで、既存の著者が新しい書籍を1件追加したくなったとします。この場合、以下のようなコードを実行する必要があるでしょう。

```ruby
@book = Book.create(published_at: Time.now, author_id: @author.id)
```

今度は著者を1人削除する場合を考えてみましょう。著者を削除するときは、その著者の書籍もすべて削除されるようにしておきます。

```ruby
@books = Book.where(author_id: @author.id)
@books.each do |book|
  book.destroy
end
@author.destroy
```

Active Recordの関連付け機能を使うと、2つのモデルの間につながりがあることを明示的にRailsに対して宣言でき、それによってモデルの操作を一貫させることができます。著者と書籍を設定するコードを次のように書き直せます。

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
end

class Book < ApplicationRecord
  belongs_to :author
end
```

上のように関連付けを追加したことで、特定の著者の新しい書籍を1冊追加する作業が以下のように1行で書けるようになりました。

```ruby
@book = @author.books.create(published_at: Time.now)
```

著者と、その著者の書籍をまとめて削除する作業は**ずっと**簡単です。

```ruby
@author.destroy
```

その他の関連付け方法については、次のセクションをお読みください。その後で、関連付けに関するさまざまなヒントや活用方法、Railsの関連付けメソッドとオプションの完全な参考情報も紹介します。

関連付けの種類
-------------------------

Railsでは6種類の関連付けをサポートしています。それぞれの関連付けは、特定の用途に特化しています。

以下は、Railsでサポートされている全種類の関連付けのリストです。リストはAPIドキュメントにリンクされているので、詳しい情報や利用方法、メソッドパラメータなどはリンク先を参照してください。

* [`belongs_to`][]
* [`has_one`][]
* [`has_many`][]
* [`has_many :through`][`has_many`]
* [`has_one :through`][`has_one`]
* [`has_and_belongs_to_many`][]

関連付けは、一種のマクロ的な呼び出しとして実装されており、これによってモデル間の関連付けを宣言的に追加できます。たとえば、あるモデルが他のモデルに従属している(`belongs_to`)と宣言すると、2つのモデルのそれぞれのインスタンス間で「[主キー](https://ja.wikipedia.org/wiki/%E4%B8%BB%E3%82%AD%E3%83%BC) - [外部キー](https://ja.wikipedia.org/wiki/%E5%A4%96%E9%83%A8%E3%82%AD%E3%83%BC)」情報を保持しておくようにRailsに指示します。同時に、いくつかの便利なメソッドもそのモデルに追加されます。

本ガイドではこの後、それぞれの関連付けの宣言方法と利用方法について詳しく解説します。その前に、それぞれの関連付けが適切となる状況について簡単にご紹介します。

[`belongs_to`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to
[`has_and_belongs_to_many`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_and_belongs_to_many
[`has_many`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many
[`has_one`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_one

### `belongs_to`関連付け

あるモデルで[`belongs_to`][]関連付けを行なうと、宣言を行ったモデルの各インスタンスは、他方のモデルのインスタンスに文字どおり「従属（belongs to）」します。たとえば、Railsアプリケーションに著者（Author）と書籍（Book）情報が含まれており、書籍1冊につき正確に1人の著者を割り当てたいのであれば、Bookモデルで以下のように宣言します。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

![belongs_to 関連付けの図](images/association_basics/belongs_to.png)

NOTE: `belongs_to`関連付けで指定するモデル名は必ず「**単数形**」にしなければなりません。上記の例で、`Book`モデルの`author`関連付けを複数形（`authors`）にしてから`Book.create(authors: @author)`でインスタンスを作成しようとすると、`uninitialized constant Book::Authors`エラーが発生します。Railsは、関連付けの名前から自動的にモデルのクラス名を推測します。従って、関連付け名が誤って複数形になってしまっていると、そこから推測されるクラス名も誤った形の複数形になってしまいます。

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

`belongs_to`を単独で利用すると、一方向のみの「1対1」つながりが生成されます。つまり上の例で言うと、「個別の書籍はその著者を知っている」状態になりますが、「著者は自分の書籍について知らない」状態になります。

[双方向関連付け](#双方向関連付け)をセットアップするには、`belongs_to`関連付けを使うときに相手側のモデル（ここではAuthorモデル）に`has_one`または`has_many`関連付けを指定します。

`optional`がtrueに設定されている場合、`belongs_to`では「参照の一貫性」が担保されません。そのため、ユースケースによっては以下のように参照カラムでデータベースレベルの外部キー制約（`foreign_key: true`）を追加する必要があります。

```ruby
create_table :books do |t|
  t.belongs_to :author, foreign_key: true
  # ...
end
```

### `has_one`関連付け

[`has_one`][]関連付けは、相手側の1つのモデルがこのモデルへの参照を持っていることを示します。相手側のモデルは、この関連付けを経由してフェッチできます。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end
```

`belongs_to`との主な違いは、リンクカラム`supplier_id`が相手側のテーブルにあることです。

![has_one関連付けの図](images/association_basics/has_one.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end
  end
end
```

ユースケースによっては、accountsテーブルとの関連付けのために、supplierカラムにuniqueインデックスか外部キー制約を追加する必要が生じることもあります。その場合、カラムの定義は次のようになるでしょう。

```ruby
create_table :accounts do |t|
  t.belongs_to :supplier, index: { unique: true }, foreign_key: true
  # ...
end
```

このリレーションは、相手側のモデルで`belongs_to`関連付けも設定することで[双方向関連付け](#双方向関連付け)になります。

### `has_many`関連付け

[`has_many`][]関連付けは、`has_one`と似ていますが、相手のモデルとの「1対多」のつながりを表す点が異なります。`has_many`関連付けは、多くの場合`belongs_to`の反対側で使われます。

`has_many`関連付けは、そのモデルの各インスタンスが、相手のモデルのインスタンスを0個以上持っていることを示します。たとえば、さまざまな著者や書籍を含むアプリケーションでは、Author（著者）モデルを以下のように宣言できます。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

NOTE: `has_many`関連付けを宣言する場合、相手のモデル名は「複数形」で指定する必要があります。

![has_many関連付けの図](images/association_basics/has_many.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.belongs_to :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

ユースケースにもよりますが、通常はこのbooksテーブルのauthorカラムに「一意でない」インデックスを追加し、オプションで外部キー制約を作成するのがよいでしょう。

```ruby
create_table :books do |t|
  t.belongs_to :author, index: true, foreign_key: true
  # ...
end
```

### `has_many :through`関連付け

[`has_many :through`][`has_many`]関連付けは、他方のモデルと「多対多」のつながりを設定する場合によく使われます。

この関連付けでは、2つのモデルの間に「第3のモデル」（joinモデル）が介在し、それを経由（through）して相手のモデルの「0個以上」のインスタンスとマッチします。たとえば、患者（patients）が医師（physicians）との診察予約（appointments）を取る医療業務を考えてみます。この場合、関連付けの宣言は次のような感じになるでしょう。

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

![has_many :through関連付けの図](images/association_basics/has_many_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAppointments < ActiveRecord::Migration[7.2]
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
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

joinモデルのコレクションは、[`has_many`関連付けメソッド](#has-many関連付け)経由で管理できます。たとえば、以下のような割り当てを実行したとします。

```ruby
physician.patients = patients
```

このとき、新たに関連付けられたオブジェクトについて、新しいjoinモデルが自動的に作成されます。以前あった行がなくなった場合は、その行はjoinモデルから自動的に削除され、joinモデルに含まれなくなります。

WARNING: joinモデルでは、以前あった行がなくなった場合の自動削除は即座に行われます。しかも、そのときにdestroyコールバックが発生しないので注意が必要です。

`has_many :through`関連付けは、ネストした`has_many`関連付けを介して「ショートカット」を設定する場合にも便利です。たとえば、1つのドキュメントに多くの節（section）があり、1つの節の下に多くの段落（paragraph）がある状態で、節をスキップしてドキュメントにあるすべての段落のシンプルなコレクションが欲しいとします。その場合、以下の方法で設定できます。

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

`through: :sections`を指定することにより、Railsは以下の文を理解できるようになります。

```ruby
@document.paragraphs
```

### `has_one :through`関連付け

[`has_one :through`][`has_one`]関連付けは、他方のモデルに対して「1対1」のつながりを設定します。この関連付けは、2つのモデルの間に「第3のモデル」（joinモデル）が介在し、それを経由（through）して相手モデルの1個のインスタンスとマッチします。たとえば、個別の供給者（supplier）が1個のアカウント（account）を持ち、さらに1個のアカウントが1個のアカウント履歴に関連付けられる場合、Supplierモデルは以下のような感じになります。

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

![has_one :through関連付けの図](images/association_basics/has_one_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAccountHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

### `has_and_belongs_to_many`関連付け

[`has_and_belongs_to_many`][]関連付けは、他方のモデルと「多対多」のつながりを作成しますが、`through:`を指定した場合と異なり、第3のモデル（joinモデル）が介在しません（訳注: 後述するようにjoin用のテーブルは必要です）。たとえば、アプリケーションにさまざまな完成品（assemblies）と部品（parts）があり、完成品ごとに多数の部品が対応し、逆に1個の部品も多くの完成品に対応するのであれば、モデルの宣言は以下のようになります。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many関連付けの図](images/association_basics/habtm.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration[7.2]
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    create_table :assemblies_parts, id: false do |t|
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

### `belongs_to`と`has_one`のどちらを選ぶか

2つのモデルの間に1対1のリレーションシップを設定したいのであれば、一方のモデルに`belongs_to`を追加し、他方のモデルに`has_one`を追加する必要があります。どちらの関連付けをどちらのモデルに置けばよいのでしょうか。

区別の決め手となるのは外部キー（foreign key）をどちらに置くかです（外部キーは、`belongs_to`関連付けを追加したモデルのテーブルに追加されます）が、もう少しデータの実際の意味についても考えてみる必要があります。`has_one`というリレーションシップは、主語となるものが目的語となるものを「所有する」ことを表します。「1人の供給者がアカウントを1つ所有する」と考える方が、「1つのアカウントが1人の供給者を所有する」と考えるよりも自然です。つまり、この場合の正しいリレーションシップは以下のようになります。

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
class CreateSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.bigint  :supplier_id
      t.string  :account_number
      t.timestamps
    end

    add_index :accounts, :supplier_id
  end
end
```

NOTE: マイグレーションで`t.bigint :supplier_id`のように「小文字のモデル名_id」と書くと、外部キーを明示的に指定できます。現在のバージョンのRailsでは、同じことを`t.references :supplier`という方法で記述できます。こちらの方が実装の詳細を抽象化して隠蔽できます。

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

多対多リレーションシップを宣言するもう1つの方法は`has_many :through`です。こちらの場合は、joinモデルを経由する間接的な関連付けが使われます。

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

どちらを使うかを決める最もシンプルな経験則は次のとおりです。
リレーションシップモデル自体を独立したエンティティとして扱いたい場合は、中間にjoinモデルを使う`has_many :through`リレーションシップを設定します。
リレーションシップモデルで何か特別なことをする必要がまったくない場合は、joinモデルの不要な`has_and_belongs_to_many`リレーションシップを使う方がよりシンプルです（ただし、こちらの場合はjoinモデルが不要な代わりに、専用のjoinテーブルを別途データベースに作成しておく必要があることをお忘れなく）。

joinモデルでバリデーション、コールバック、追加の属性が必要な場合は、`has_many :through`をお使いください。

`has_and_belongs_to_many`リレーションシップは、`id: false`を介して「主キーを含まない」joinテーブルを作成することを示唆していますが、`has_many :through`リレーションシップでは、joinテーブルに複合主キーを含めることを検討してください。

たとえば上の例では `create_table :manifests, primary_key: [:assembly_id, :part_id]`を使うことが推奨されます。

### ポリモーフィック関連付け

**ポリモーフィック関連付け**（polymorphic association）は、関連付けのやや高度な応用です。ポリモーフィック関連付けを使うと、ある1つのモデルが他の複数のモデルに属していることを、1つの関連付けだけで表現できます。たとえば、写真（picture）モデルがあり、このモデルを従業員（employee）モデルと製品（product）モデルの両方に従属させたいとします。この場合は以下のように宣言します。

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

ポリモーフィックな`belongs_to`は、他のあらゆるモデルから利用可能なインターフェイスを設定する宣言と考えてもよいでしょう。`@employee.pictures`とすると、写真のコレクションを`Employee`モデルの1個のインスタンスから取得できます。

同様に、`@product.pictures`とすれば、写真のコレクションを`Product`モデルの1個のインスタンスから取得できます。

`Picture`モデルのインスタンスがあれば、`@picture.imageable`とすることでその親を取得できます。これを可能にするには、ポリモーフィックなインターフェイスを宣言するモデルで、外部キーのカラムと型のカラムを両方とも宣言しておく必要があります。

```ruby
class CreatePictures < ActiveRecord::Migration[7.2]
  def change
    create_table :pictures do |t|
      t.string  :name
      t.bigint  :imageable_id
      t.string  :imageable_type
      t.timestamps
    end

    add_index :pictures, [:imageable_type, :imageable_id]
  end
end
```

`t.references`という書式を使うと、同じことをもっとシンプルに書けます。

```ruby
class CreatePictures < ActiveRecord::Migration[7.2]
  def change
    create_table :pictures do |t|
      t.string  :name
      t.references :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

NOTE: [ポリモーフィック関連付け](association_basics.html#ポリモーフィック関連付け)は、クラス名がデータベースに保存されることが前提になっているため、そのデータはRubyコードで使われるクラス名と常に手動で同期しておく必要があります。クラス名を変更する場合は、対応するポリモーフィック型カラムのデータも必ず更新してください。

![ポリモーフィック関連付けの図](images/association_basics/polymorphic.png)

### 複合主キーを持つモデルの関連付け

Railsは多くの場合、追加情報を必要とせずに、複合主キーをモデル間の関連付けで「主キー〜外部キー」情報を推論できます。以下の例をご覧ください。

```ruby
class Order < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :order
end
```

ここでRailsは、1件のorder（注文）とそのbooks（本）の関連付けの主キーに`:id`カラムが使われると仮定します。これは、通常の`has_many`関連付けや`belongs_to`関連付けと同様です。Railsは、`books`テーブル上の外部キーカラムが`:order_id`であると推測します。
ある本の注文に、以下のようにアクセスするとします。

```ruby
order = Order.create!(id: [1, 2], status: "pending")
book = order.books.create!(title: "A Cool Book")

book.reload.order
```

この場合、以下のSQLを生成してorderにアクセスします。

```sql
SELECT * FROM orders WHERE id = 2
```

これが期待通りに動作するのは、このモデルの複合主キーに`:id`カラムが含まれており、かつ`:id`カラムがすべてのレコードで一意である場合だけです。関連付けで完全な複合主キーを使うには、その関連付けで`foreign_key`オプションを設定してください。このオプションは、関連付けられるレコードをクエリするときに複合外部キーを指定します。例:

```ruby
class Author < ApplicationRecord
  self.primary_key = [:first_name, :last_name]
  has_many :books, foreign_key: [:first_name, :last_name]
end

class Book < ApplicationRecord
  belongs_to :author, foreign_key: [:author_first_name, :author_last_name]
end
```

以下のように、ある本のauthor（著者）にアクセスするとします。

```ruby
author = Author.create!(first_name: "Jane", last_name: "Doe")
book = author.books.create!(title: "A Cool Book")

book.reload.author
```

この場合、以下のようにSQLクエリで`:first_name`と`:last_name`が使われます。

```sql
SELECT * FROM authors WHERE first_name = 'Jane' AND last_name = 'Doe'
```

### 自己結合

データモデルを設計していると、モデルを自分自身に関連付ける必要が生じることがあります。たとえば、全従業員（employees）を1つのデータベースモデルに格納しておきたいが、マネージャー（manager）と部下（subordinates）のリレーションシップも追えるようにしておきたい場合が考えられます。この状況は、以下のように自己結合（self-joining）関連付けでモデル化できます。

```ruby
class Employee < ApplicationRecord
  has_many :subordinates, class_name: "Employee",
                          foreign_key: "manager_id"

  belongs_to :manager, class_name: "Employee", optional: true
end
```

上のように宣言しておくと、`@employee.subordinates`と`@employee.manager`を取り出せるようになります。

マイグレーションおよびスキーマでは、モデル自身にreferencesカラムを追加します。

```ruby
class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.references :manager, foreign_key: { to_table: :employees }
      t.timestamps
    end
  end
end
```

NOTE: `foreign_key`に渡される`to_table`オプションなどについて詳しくは、[`SchemaStatements#add_reference`][connection.add_reference]を参照してください。

[connection.add_reference]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference

ヒントと注意事項
--------------------------

RailsアプリケーションでActive Recordの関連付けを効果的に使うためには、以下について知っておく必要があります。

* キャッシュ制御
* 名前衝突の回避
* スキーマの更新
* 関連付けのスコープ制御
* 双方向関連付け

### キャッシュ制御

関連付けのメソッドは、すべてキャッシュを中心に構築されています。最後に実行したクエリの結果はキャッシュに保持され、次回以降の操作で利用できます。このキャッシュは、以下のようにメソッド間でも共有される点にご注意ください。

```ruby
# データベースからbooksを取得する
author.books.load

# booksのキャッシュコピーが使われる
author.books.size

# booksのキャッシュコピーが使われる
author.books.empty?
```

データがアプリケーションの他の部分によって更新されている可能性があるのでキャッシュを再読み込みしたい場合は、どうしたらよいでしょうか。その場合は、以下のように関連付けのメソッド呼び出しで`reload`を呼び出せば、キャッシュが破棄されてデータが再読み込みされます。

```ruby
# データベースからbooksを取得する
author.books.load

# booksのキャッシュコピーが使われる
author.books.size

# booksのキャッシュコピーが破棄され、その後データベースから再度読み込まれる
author.books.reload.empty?
```

### 名前衝突の回避

関連付けにはどんな名前でも使えるとは限りません。関連付けを作成すると、モデルにその名前のメソッドが追加されます。従って、`ActiveRecord::Base`のインスタンスで既に使われているような名前を関連付けに使うのは禁物です。そのような名前を関連付けに使うと、基底メソッドが上書きされて不具合が生じる可能性があります。`attributes`や`connection`は関連付けに使ってはならない名前の例です。

### スキーマの更新

関連付けはきわめて便利ですが、残念ながら魔法ではありません。関連付けを使うからには、関連付けの設定に合わせてデータベースのスキーマを常に更新しておく責任が生じます。作成した関連付けにもよりますが、具体的には次の2つの作業が必要になります。

1. `belongs_to`関連付けを使う場合は、外部キーを作成する必要があります。
2. `has_and_belongs_to_many`関連付けを使う場合は、適切なjoinテーブルを作成する必要があります。

#### `belongs_to`関連付けに対応する外部キーを作成する

`belongs_to`関連付けを宣言したら、対応する外部キーを作成する必要があります。以下のモデルを例にとります。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

上の宣言は、以下のbooksテーブル上で対応する外部キーカラムと整合している必要があります。作成した直後のテーブルの場合、マイグレーションは次のような感じになります。

```ruby
class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :books do |t|
      t.datetime   :published_at
      t.string     :book_number
      t.references :author
    end
  end
end
```

一方、既存のテーブルの場合、マイグレーションは次のような感じになります。

```ruby
class AddAuthorToBooks < ActiveRecord::Migration[7.2]
  def change
    add_reference :books, :author
  end
end
```

NOTE: [データベースレベルでの参照整合性を強制する][foreign_keys]には、上の‘reference’カラム宣言に`foreign_key: true`オプションを追加します。

[foreign_keys]: /active_record_migrations.html#外部キー

#### `has_and_belongs_to_many`関連付けに対応するjoinテーブルを作成する

`has_and_belongs_to_many`関連付けを作成した場合は、それに対応するjoinテーブルを明示的に作成する必要があります。joinテーブルの名前が`:join_table`オプションで明示的に指定されていない場合、Active Recordは2つのクラス名をABC順に結合して、joinテーブル名を作成します。たとえばAuthorモデルとBookモデルを結合する場合、'a'は辞書で'b'より先に出現するので "authors_books"というデフォルトのjoinテーブル名が使われます。

WARNING: モデル名の優先順位は`String`クラスの`<=>`演算子を用いて算出されます。つまり、2つの文字列の長さが異なり、短い方が長い方の途中まで完全に一致している場合は、長い方の文字列は短い方よりも優先順位が高くなるということです。たとえば、"paper\_boxes" テーブルと "papers" テーブルがある場合、"paper\_boxes" の方が長いので、これらのjoinテーブル名は "papers\_paper\_boxes" になりそうな気がします。しかし実際に生成されるjoinテーブル名は "paper\_boxes\_papers" になります（これは多くのエンコーディングでアンダースコア '\_' の方が 's' よりも並び順が前になるためです）。

生成された名前がどのようなものであれ、適切なマイグレーションを実行してjoinテーブルを生成する必要があります。以下の関連付けを例にとって考えてみましょう。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

この関連付けに対応する`assemblies_parts`テーブルをマイグレーションで作成する必要があります。作成するテーブルには主キーを設定しないでください。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_table :assemblies_parts, id: false do |t|
      t.bigint :assembly_id
      t.bigint :part_id
    end

    add_index :assemblies_parts, :assembly_id
    add_index :assemblies_parts, :part_id
  end
end
```

このテーブルはモデルを表現していないので、`create_table`に`id: false`を渡します。こうしておかないとこの関連付けは正常に動作しません。モデルのIDが破損する、IDの競合で例外が発生するなど、`has_and_belongs_to_many`関連付けの動作が怪しい場合は、この設定を忘れていないかどうか再度確認してみてください。

以下のように`create_join_table`メソッドを使ってシンプルに書くことも可能です。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_join_table :assemblies, :parts do |t|
      t.index :assembly_id
      t.index :part_id
    end
  end
end
```

### 関連付けのスコープを制御する

デフォルトでは、関連付けによって探索されるのは、現在のモジュールのスコープ内にあるオブジェクトだけです。Active Recordモデルをモジュール内で宣言する場合は、この点に注意する必要があります。


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

上のコードは正常に動作します。これは、`Supplier`クラスと`Account`クラスが同じスコープ（`MyApplication::Business`）内で定義されているためです。
この編成では、すべての関連付けにスコープを明示的に追加することなく、スコープに基づいてモデルをフォルダで構造化できます。

```ruby
# app/models/my_application/business/supplier.rb
module MyApplication
  module Business
    class Supplier < ApplicationRecord
      has_one :account
    end
  end
end
```

```ruby
# app/models/my_application/business/account.rb
module MyApplication
  module Business
    class Account < ApplicationRecord
      belongs_to :supplier
    end
  end
end
```

ここで重要なのは、これはテーブルの名前付けには影響しないことです。たとえば、`MyApplication::Business::Supplier`というモデルがある場合は、`my_application_business_suppliers`テーブルも必ず存在していなければなりません。

`Supplier`と`Account`は異なるスコープ（`MyApplication::Business`と`MyApplication::Billing`）で定義されているため、次のコードは**動かない**ことにご注意ください。

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

あるモデルを別の名前空間にあるモデルと関連付けるには、関連付けの宣言で以下のように完全なクラス名を指定する必要があります。

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

通常は、関連付けを双方向に機能させるために、2つのモデルの両方に関連付けを定義する必要があります。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
end
```

Active Recordは、これらの関連付けの設定から、2つのモデルが双方向の関連を共有していることを自動的に認識しようとします。以下に示すように、Active Recordは`Author`オブジェクトを1個だけ読み出すことで、アプリケーションの効率を高めるとともにデータの一貫性を維持します。

* 既に読み込まれたデータに対する不要なクエリを防ぐ

    ```irb
    irb> author = Author.first
    irb> author.books.all? do |book|
    irb>   book.author.equal?(author) # 追加クエリはここで実行されない
    irb> end
    => true
    ```

* データの不整合を防ぐ（`Author`オブジェクトのコピーは1個しか読み込まれない）

    ```irb
    irb> author = Author.first
    irb> book = author.books.first
    irb> author.name == book.writer.name
    => true
    irb> author.name = "Changed Name"
    irb> author.name == book.writer.name
    => true
    ```

* 関連付けを自動保存するケースを増やす

    ```irb
    irb> author = Author.new
    irb> book = author.books.new
    irb> book.save!
    irb> book.persisted?
    => true
    irb> author.persisted?
    => true
    ```

* 関連付けの[`presence`](active_record_validations.html#presence)や[`absence`](active_record_validations.html#absence)をバリデーションするケースを増やす

    ```irb
    irb> book = Book.new
    irb> book.valid?
    => false
    irb> book.errors.full_messages
    => ["Author must exist"]
    irb> author = Author.new
    irb> book = author.books.new
    irb> book.valid?
    => true
    ```

Active Recordでは、ほとんどの標準的な名前同士の関連付けについて自動識別をサポートしています。ただしActive Recordは、`:through`や`:foreign_key`オプションを含む双方向関連付けを自動認識しません。

また、関連付け自身でカスタムスコープが使われている場合も、[`config.active_record.automatic_scope_inversing`][]を`true`に設定しない限り自動識別しません（新しいアプリケーションではデフォルトで`config.active_record.automatic_scope_inversing = true`が設定されます）。

たとえば、次のようなモデルを宣言したケースを考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: 'Author', foreign_key: 'author_id'
end
```

この場合、`:foreign_key`オプションのため、Active Recordは双方向関連付けを自動的に認識しなくなります。これによってアプリケーションで以下が発生する可能性があります。

* 同じデータに対して不要なクエリを実行する（この例ではN+1クエリが発生する）

    ```irb
    irb> author = Author.first
    irb> author.books.any? do |book|
    irb>   book.writer.equal?(author) # authorクエリがbook 1件ごとに発生する
    irb> end
    => false
    ```

* データが一貫していないモデルの複数のコピーを参照する

    ```irb
    irb> author = Author.first
    irb> book = author.books.first
    irb> author.name == book.author.name
    => true
    irb> author.name = "Changed Name"
    irb> author.name == book.author.name
    => false
    ```

* 関連付けの自動保存が失敗する

    ```irb
    irb> author = Author.new
    irb> book = author.books.new
    irb> book.save!
    irb> book.persisted?
    => true
    irb> author.persisted?
    => false
    ```

* `presence`や`absence`バリデーションが失敗する

    ```irb
    irb> author = Author.new
    irb> book = author.books.new
    irb> book.valid?
    => false
    irb> book.errors.full_messages
    => ["Author must exist"]
    ```
Active Recordが提供している`:inverse_of`オプションを使うと、双方向関連付けを明示的に宣言できます。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: 'writer'
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: 'Author', foreign_key: 'author_id'
end
```

`has_many`関連付けの宣言で`:inverse_of`オプションを使うと、Active Recordが双方向関連付けを認識して、上述の最初の例のように動作するようになります。

[`config.active_record.automatic_scope_inversing`]: configuring.html#config-active-record-automatic-scope-inversing

関連付けの詳細な参照
------------------------------

本セクションでは、関連付けの種別ごとの詳細を解説します。関連付けの宣言によって追加されるメソッドやオプションについても説明します。

### `belongs_to`関連付けの詳細な参照

`belongs_to`関連付けは、データベースの観点では、このモデルのテーブルに別のテーブルへの参照を表すカラムが含まれていることを意味します。`belongs_to`関連付けは、状況に応じて1対1または1対多のリレーションを設定するのに利用できます。相手側クラスのテーブルが1対1のリレーションで参照を含んでいる場合は、`has_one`を使うべきです。

#### `belongs_to`で追加されるメソッド

`belongs_to`関連付けを宣言したクラスでは、以下の8つのメソッドが自動的に利用できるようになります。

* `association`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`
* `reload_association`
* `reset_association`
* `association_changed?`
* `association_previously_changed?`

上のメソッド名の*`association`*の部分は**プレースホルダ**なので、`belongs_to`の第1引数として渡されるものの名前で読み替えてください。

たとえば以下の宣言があるとします。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

このとき、`Book`モデルのインスタンスで以下のメソッドが使えるようになります。

* `author`
* `author=`
* `build_author`
* `create_author`
* `create_author!`
* `reload_author`
* `reset_author`
* `author_changed?`
* `author_previously_changed?`

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`association.build`メソッドではなく`build_`で始まるメソッドを使う必要があります（`association.build`は`has_many`関連付けや`has_and_belongs_to_many`関連付けで使われます）。関連付けを作成する場合も、`create_`で始まるメソッドをお使いください。

##### `association`

`association`メソッドは、関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@author = @book.author
```

関連付けられたオブジェクトがデータベースから既に取得されている場合は、キャッシュされたものを返します。この振る舞いを上書きして、キャッシュを読み出さずにデータベースから強制的に読み込みたい場合は、親オブジェクトが持つ`#reload_association`メソッドを呼び出します。

```ruby
@author = @book.reload_author
```

関連付けされたオブジェクトのキャッシュバージョンをアンロードして、次回のアクセスでデータベース呼び出しからクエリするには、親オブジェクトの`#reset_association`を呼び出します。

```ruby
@book.reset_author
```

##### `association=(associate)`

`association=`メソッドは、引数のオブジェクトをそのオブジェクトに関連付けます。その背後では、関連付けられたオブジェクトから主キーを取り出し、そのオブジェクトの外部キーにその同じ値を設定しています。

```ruby
@book.author = @author
```

##### `build_association(attributes = {})`

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトはまだ**保存されていない**ことにご注意ください。

```ruby
@author = @book.build_author(author_number: 123,
                                  author_name: "John Doe")
```

##### `create_association(attributes = {})`

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは**保存されます**。

```ruby
@author = @book.create_author(author_number: 123,
                                   author_name: "John Doe")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### `association_changed?`

`association_changed?`メソッドは、新しい関連付けオブジェクトが代入された場合に`true`を返します。外部キーは次の保存で更新されます。

```ruby
@book.author # => #<Author author_number: 123, author_name: "John Doe">
@book.author_changed? # => false

@book.author = Author.second # => #<Author author_number: 456, author_name: "Jane Smith">
@book.author_changed? # => true

@book.save!
@book.author_changed? # => false
```

##### `association_previously_changed?`

`association_previously_changed?`メソッドは、関連付けが前回の保存で更新されて新しい関連付けオブジェクトを参照している場合に`true`を返します。

```ruby
@book.author # => #<Author author_number: 123, author_name: "John Doe">
@book.author_previously_changed? # => false

@book.author = Author.second # => #<Author author_number: 456, author_name: "Jane Smith">
@book.save!
@book.author_previously_changed? # => true
```

#### `belongs_to`のオプション

Railsのデフォルトの`belongs_to`関連付けは優秀なので、ほとんどの場合カスタマイズ不要ですが、関連付けの参照をカスタマイズしたい場合もあります。これは、作成するときに渡すオプションとスコープブロックで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at,
    counter_cache: true
end
```

[`belongs_to`][]関連付けでは以下のオプションがサポートされています。

* `:autosave`
* `:class_name`
* `:counter_cache`
* `:default`
* `:dependent`
* `:ensuring_owner_was`
* `:foreign_key`
* `:foreign_type`
* `:primary_key`
* `:inverse_of`
* `:optional`
* `:polymorphic`
* `:required`
* `:strict_loading`
* `:touch`
* `:validate`

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべての関連付けメンバを保存し、destroyフラグが立っているメンバを破棄します。
`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは**同じではありません**。`:autosave`オプションを渡さない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連付けの相手となるオブジェクト名を関連付け名から生成できない事情がある場合、`:class_name`オプションを用いてモデル名を直接指定できます。たとえば、書籍（book）が著者（author）に従属しているが実際の著者のモデル名が`Patron`である場合には、以下のように指定します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron"
end
```

##### `:counter_cache`

`:counter_cache`オプションは、従属しているオブジェクトの個数の検索効率を向上させます。以下のモデルで説明します。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
class Author < ApplicationRecord
  has_many :books
end
```

上の宣言のままでは、`@author.books.size`の値を知るためにデータベースに対して`COUNT(*)`クエリを実行する必要があります。この呼び出しを避けるために、「従属している側のモデル（`belongs_to`を宣言している側のモデル）」にカウンタキャッシュを追加できます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: true
end
class Author < ApplicationRecord
  has_many :books
end
```

上のように宣言すると、キャッシュ値が最新の状態に保たれ、次に`size`メソッドが呼び出されたときにその値が返されます。

ここで1つ注意が必要です。`:counter_cache`オプションは`belongs_to`宣言で指定しますが、実際に個数を数えたいカラムは「相手の」モデル（関連付け先のモデル）の側に追加する必要があります。上の場合は、`Author`モデルに`books_count`カラムを追加する必要があります。

`counter_cache`オプションで`true`の代わりに任意のカラム名を設定すると、デフォルトのカラム名をオーバーライドできます。以下は、`books_count`の代わりに`count_of_books`を設定した場合の例です。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: :count_of_books
end

class Author < ApplicationRecord
  has_many :books
end
```

NOTE: これは、関連付けの`belongs_to`側で`:counter_cache`オプションを設定するだけでできます。

既存の大きなテーブルでカウンタキャッシュの利用を開始すると、カラムの追加とは別にカラムの値をバックフィルする必要があります（テーブルを長時間ロックしないようにするため）。このバックフィルは`:counter_cache`オプションを使う前に行っておく必要があるため（さもないと、カウンタキャッシュを内部で利用する`size`や`any?`などのメソッドで誤った結果が生成される可能性がある）、問題が発生する可能性があります。
子レコードの作成や削除でカウンタキャッシュのカラムを更新したまま値を安全にバックフィルし、前述のメソッドでカウンタキャッシュカラムの誤った値が使われないようにすることで、常にデータベースから結果を取得するには、`counter_cache: { active: false }`を使います。カスタムのカラム名も指定する必要がある場合は、`counter_cache: { active: false, column: :my_custom_counter }`を使います。

何らかの理由でオーナーモデルの主キーの値を変更し、カウントされたモデルの外部キーも更新しなかった場合、カウンタキャッシュのデータが古くなっている可能性があります（つまり、孤立したモデルも引き続きカウンタでカウントされます）。古くなったカウンタキャッシュを修正するには、[`reset_counters`][]をお使いください。

[`reset_counters`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-reset_counters

##### `:default`

`true`に設定すると、その関連付けが存在することが保証されなくなります。

##### `:dependent`

`:dependent`で指定するオプションの挙動は以下のとおりです。

* `:destroy`: オブジェクトが削除されるときに、関連付けられたオブジェクトの`destroy`メソッドが実行されます。
* `:delete`: オブジェクトが削除されるときに、関連付けられたオブジェクトが直接データベースから削除されます。`destroy`メソッドは実行されません。
* `:destroy_async`: オブジェクトが削除されるときに、`ActiveRecord::DestroyAssociationAsyncJob`ジョブがジョブキューに入り、関連付けられたオブジェクトで`destroy`メソッドを呼び出します。このジョブが動作するには、Active Jobをセットアップしておく必要があります。
  関連付けの背後にデータベースの外部キー制約がある場合は、このオプションを使ってはいけません。外部キー制約の操作は、そのオーナーを削除するのと同じトランザクション内で発生します。

WARNING: このオプションは、他のクラスの`has_many`関連付けとつながりのある`belongs_to`関連付けに対して使ってはいけません。孤立レコードがデータベースに残ってしまう可能性があります。

##### `:ensuring_owner_was`

オーナーによって呼び出されるインスタンスメソッドを指定します。関連付けられるレコードがバックグラウンドジョブで削除されるようにするには、このメソッドが`true`を返さなければなりません。

##### `:foreign_key`

Railsの規約では、相手のモデルを指す外部キーを保持しているjoinテーブル上のカラム名については、そのモデル名にサフィックス`_id`を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使えば、外部キーの名前を直接指定できます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron",
                        foreign_key: "patron_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作成することはありません。外部キーを使うには、マイグレーションで明示的に定義する必要があります。

##### `:foreign_type`

ポリモーフィック関連付けが有効になっている場合、関連付けられるオブジェクトの型を保存するカラムを指定します。デフォルトでは、これは関連付け名の末尾に`_type`サフィックスを追加した名前を推測します。したがって、`belongs_to :taggable, polymorphic: true`という関連付けを定義するクラスでは、`taggable_type`がデフォルトの`:foreign_type`として使われます。

##### `:primary_key`

Railsの規約では、`id`カラムはそのテーブルの主キーとして使われます。`:primary_key`オプションを指定すると、指定された別のカラムを主キーとして設定できます

たとえば、`users`テーブルに`guid`という主キーがあるとします。その`guid`カラムに、別の`todos`テーブルの外部キーである`user_id`カラムを使いたい場合は、次のように`primary_key`を設定します。

```ruby
class User < ApplicationRecord
  self.primary_key = 'guid' # 主キーがguidになる
end

class Todo < ApplicationRecord
  belongs_to :user, primary_key: 'guid'
end
```

`@user.todos.create`を実行すると、`@todo`レコードは`@user`の`guid`として`user_id`を持つようになります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`has_many`関連付けまたは`has_one`関連付けの名前を指定します。
詳しくは[双方向関連付け](#双方向関連付け)を参照してください。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: :author
end

class Book < ApplicationRecord
  belongs_to :author, inverse_of: :books
end
```

##### `:optional`

`:optional`オプションに`true`を指定すると、関連付けられるオブジェクトが存在することが保証されなくなります。このオプションは、デフォルトでは`false`です。

##### `:polymorphic`

`:polymorphic`オプションに`true`を指定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けについて詳しくは本ガイドの[ポリモーフィック関連付け](#ポリモーフィック関連付け)を参照してください。

##### `:required`

`true`を指定すると、その関連付けが存在することも保証されるようになります。これによってバリデーションされるのは関連付け自身であり、idではありません。`:inverse_of`を使うと、バリデーション時に余分なクエリが発生することを回避できます。

NOTE: この`required`オプションはデフォルトで`true`に設定されますが、これは非推奨化されています。関連付けの存在をバリデーションしたくない場合は、`optional: true`をお使いください。

##### `:strict_loading`

`true`を指定すると、関連付けられるレコードが、この関連付けを経由して読み込まれるたびにstrict loadingを強制するようになります。

##### `:touch`

`:touch`オプションを`true`に設定すると、そのオブジェクトが`save`または`destroy`されたときに、関連付けられたオブジェクトの`updated_at`タイムスタンプや`updated_on`タイムスタンプが常に現在の時刻に設定されます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: true
end

class Author < ApplicationRecord
  has_many :books
end
```

上の`Book`は、関連付けられている`Author`のタイムスタンプを`save`または`destroy`するときに更新します。更新時に特定のタイムスタンプ属性を指定することも可能です。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at
end
```

##### `:validate`

`:validate`オプションを`true`に設定すると、新たに関連付けられたオブジェクトを保存するときに必ずバリデーションされます。デフォルトは`false`であり、この場合新たに関連付けられたオブジェクトは保存時にバリデーションされません。

#### `belongs_to`のスコープ

`belongs_to`で使われるクエリをカスタマイズしたい場合があります。スコープブロックを用いてこのようなカスタマイズを行えます。以下に例を示します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { where active: true }
end
```

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`メソッドは、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { where active: true }
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager loadingすべき第2関連付けを指定できます。以下のモデルを例に考えてみましょう。

```ruby
class Chapter < ApplicationRecord
  belongs_to :book
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters
end

class Author < ApplicationRecord
  has_many :books
end
```

章（chapter）から本の著者名（author）を`@chapter.book.author`のように直接取り出す頻度が高い場合は、以下のように`Chapter`から`Book`への関連付けで`Author`をあらかじめ`includes`しておくと、クエリが減って効率が高まります。

```ruby
class Chapter < ApplicationRecord
  belongs_to :book, -> { includes :author }
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters
end

class Author < ApplicationRecord
  has_many :books
end
```

NOTE: 直接の関連付けでは`includes`を使う必要はありません。`Book belongs_to :author`のような直接の関連付けでは必要に応じて自動的にeager loadingされます。

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを読み出し専用で取り出します。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトですべてのカラムを取り出します。

TIP: `select`を`belongs_to`関連付けで使う場合は、正しい結果を得るために`:foreign_key`オプションも設定してください。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを用いて、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @book.author.nil?
  @msg = "この本の著者が見つかりません"
end
```

#### オブジェクトが保存されるタイミング

オブジェクトを`belongs_to`関連付けに割り当てても、オブジェクトが自動的に保存されるわけでは**ありません**。関連付けられたオブジェクトも保存されません。

### `has_one`関連付けの詳細な参照

`has_one`関連付けは相手のモデルと1対1対応します。データベースの観点では、この関連付けは相手のクラスが外部キーを持つことを意味します。相手ではなく自分のクラスが外部キーを持つのであれば、`belongs_to`を使うべきです。

#### `has_one`で追加されるメソッド

`has_one`関連付けを宣言したクラスでは、以下の6つのメソッドが自動的に利用できるようになります。

* `association`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`
* `reload_association`
* `reset_association`

上のメソッド名の*`association`*の部分は**プレースホルダ**なので、`has_one`の第1引数として渡されるものの名前で読み替えてください。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end
```

これにより、`Supplier`モデルのインスタンスで以下のメソッドが使えるようになります。

* `account`
* `account=`
* `build_account`
* `create_account`
* `create_account!`
* `reload_account`
* `reset_account`

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`association.build`メソッドではなく`build_`で始まるメソッドを使う必要があります（`association.build`は`has_many`関連付けや`has_and_belongs_to_many`関連付けで使われます）。関連付けを作成する場合も、`create_`で始まるメソッドをお使いください。

##### `association`

`association`メソッドは、関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@account = @supplier.account
```

関連付けられたオブジェクトがデータベースから既に取得されている場合は、キャッシュされたものを返します。キャッシュを読み出さずにデータベースから直接読み込みたい場合は、親オブジェクトが持つ`#reload_association`メソッドを呼び出します。

```ruby
@account = @supplier.reload_account
```

関連付けされたオブジェクトのキャッシュバージョンをアンロードして、次回のアクセスでデータベース呼び出しからクエリするには、親オブジェクトの`#reset_association`を呼び出します。

```ruby
@supplier.reset_account
```

##### `association=(associate)`

`association=`メソッドは、引数のオブジェクトをそのオブジェクトに関連付けます。その背後では、関連付けられたオブジェクトから主キーを取り出し、そのオブジェクトの外部キーにその同じ値を設定しています。

```ruby
@supplier.account = @account
```

##### `build_association(attributes = {})`

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトはまだ**保存されていない**ことにご注意ください。

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

##### `create_association(attributes = {})`

`create_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが設定されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは**保存されます**。

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

##### `create_association!(attributes = {})`

上の`create_association`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

#### `has_one`のオプション

Railsのデフォルトの`has_one`関連付けは優秀なので、ほとんどの場合カスタマイズ不要ですが、関連付けの参照をカスタマイズしたい場合もあります。これは、作成するときに渡すオプションで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, class_name: "Billing", dependent: :nullify
end
```

[`has_one`][]関連付けでは以下のオプションがサポートされます。

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:disable_joins`
* `:ensuring_owner_was`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:query_constraints`
* `:required`
* `:source`
* `:source_type`
* `:strict_loading`
* `:through`
* `:touch`
* `:validate`

##### `:as`

`:as`オプションを設定すると、ポリモーフィック関連付けを指定できます。ポリモーフィック関連付けについて詳しくは本ガイドの[ポリモーフィック関連付け](#ポリモーフィック関連付け)を参照してください。

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。
`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは**同じではありません**。`:autosave`オプションを渡さない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連付けの相手となるオブジェクト名を関連付け名から生成できない事情がある場合、`:class_name`オプションを用いてモデル名を直接指定できます。たとえば、Supplier（供給者）がAccount（アカウント）を1つ持ち、アカウントを含むモデルの実際の名前が`Account`ではなく`Billing`になっている場合、以下のようにモデル名を指定できます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, class_name: "Billing"
end
```

##### `:dependent`

オブジェクトのオーナーがdestroyされたときの、それに関連付けられたオブジェクトの扱いを制御します。

* `:destroy`: 関連付けられたオブジェクトも同時にdestroyされます。
* `:delete`: 関連付けられたオブジェクトはデータベースから直接削除されます（コールバックは実行されません）。
* `:destroy_async`: オブジェクトが削除されるときに、`ActiveRecord::DestroyAssociationAsyncJob`ジョブがジョブキューに入り、関連付けられたオブジェクトで`destroy`メソッドを呼び出します。このジョブが動作するには、Active Jobをセットアップしておく必要があります。
    関連付けの背後にデータベースの外部キー制約がある場合は、このオプションを使ってはいけません。外部キー制約の操作は、そのオーナーを削除するのと同じトランザクション内で発生します。
* `:nullify`: 外部キーが`NULL`に設定されます。ポリモーフィックなtypeカラムもポリモーフィック関連付けで`NULL`に設定されます。コールバックは実行されません。
* `:restrict_with_exception`: 関連付けられたレコードがある場合に`ActiveRecord::DeleteRestrictionError`例外が発生します。
* `:restrict_with_error`: 関連付けられたオブジェクトがある場合にエラーがオーナーに追加されます。

`NOT NULL`データベース制約のある関連付けでは、`:nullify`オプションを与えないようにする必要があります。そのような関連付けをdestroyするときに`dependent`を設定しなかった場合、関連付けられたオブジェクトを変更できなくなってしまいます。これは、最初に関連付けられたオブジェクトの外部キーが`NULL`値になってしまい、この値は許されていないためです。

##### `:disable_joins`

関連付けでJOINをスキップするかどうかを指定します。
`true`を指定した場合、クエリが2つ以上生成されるようになります。ただし場合によっては、ORDERやLIMITが適用されるとデータベースの制限によりインメモリで処理されることがあります。
このオプションは、`has_one :through`関連付けにのみ適用されます（`has_one`単体ではJOINは実行されません）。

##### `:foreign_key`

Railsの規約では、相手のモデル上の外部キーを保持しているカラム名については、そのモデル名にサフィックス`_id`を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使うと外部キーの名前を直接指定できます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, foreign_key: "supp_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作成することはありません。外部キーを使うには、マイグレーションで明示的に定義する必要があります。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。
詳しくは[双方向関連付け](#双方向関連付け)を参照してください。

```ruby
class Supplier < ApplicationRecord
  has_one :account, inverse_of: :supplier
end

class Account < ApplicationRecord
  belongs_to :supplier, inverse_of: :account
end
```

##### `:primary_key`

Railsの規約では、モデルの主キーは`id`カラムに保存されていることを前提とします。`:primary_key`オプションで主キーを明示的に指定することでこれを上書きできます。

##### `:query_constraints`

複合外部キーとして機能するようになります。関連付けられるオブジェクトをクエリするために使うカラムのリストを定義します。この機能はオプションです（デフォルトでは、値の自動導出を試みます）。値が設定されている場合、`Array`のサイズは、関連付けられるモデルの主キーのサイズまたは`query_constraints`のサイズと一致する必要があります。

##### `:required`

`true`を指定すると、その関連付けが存在することも保証されるようになります。これによってバリデーションされるのは関連付け自身であり、idではありません。`:inverse_of`を使うと、バリデーション時に余分なクエリが発生することを回避できます。

##### `:source`

`:source`オプションは、`has_one :through`関連付けで用いる関連付け元の名前を指定します。

##### `:source_type`

`:source_type`オプションは、ポリモーフィック関連付けを介する`has_one :through`関連付けで、関連付け元の型を指定します。

```ruby
class Author < ApplicationRecord
  has_one :book
  has_one :hardback, through: :book, source: :format, source_type: "Hardback"
  has_one :dust_jacket, through: :hardback
end

class Book < ApplicationRecord
  belongs_to :format, polymorphic: true
end

class Paperback < ApplicationRecord; end

class Hardback < ApplicationRecord
  has_one :dust_jacket
end

class DustJacket < ApplicationRecord; end
```

##### `:strict_loading`

`true`を指定すると、関連付けられるレコードが、この関連付けを経由して読み込まれるたびにstrict loadingを強制するようになります。

##### `:through`

`:through`オプションは、[このガイドで既に説明した](#has-one-through関連付け)`has_one :through`関連付けのクエリを実行する際に経由するjoinモデルを指定します。

##### `:touch`

`:touch`オプションを`true`に設定すると、そのオブジェクトが`save`または`destroy`されたときに、関連付けられたオブジェクトの`updated_at`タイムスタンプや`updated_on`タイムスタンプが常に現在の時刻に設定されます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, touch: true
end

class Account < ApplicationRecord
  belongs_to :supplier
end
```

上の`Supplier`は、関連付けられている`Account`のタイムスタンプを`save`または`destroy`するときに更新します。更新時に特定のタイムスタンプ属性を指定することも可能です。

```ruby
class Supplier < ApplicationRecord
  has_one :account, touch: :suppliers_updated_at
end
```

##### `:validate`

`:validate`オプションを`true`に設定すると、新たに関連付けられたオブジェクトが保存時に必ずバリデーションされます。デフォルトは`false`であり、この場合新たに関連付けられたオブジェクトは保存時に **バリデーション** されません。

#### `has_one`のスコープ

`has_one`で使われるクエリをカスタマイズしたい場合があります。スコープブロックを用いてこのようなカスタマイズを行えます。以下に例を示します。

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

`includes`メソッドを使うと、その関連付けが使われるときにeager loadingすべき第2関連付けを指定できます。以下のモデルを例に考えてみましょう。

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

供給者（supplier）からアカウントの代表（representative）を`@supplier.account.representative`のように直接取り出す頻度が高い場合は、`Supplier`から`Account`への関連付けに`Representative`をあらかじめ`includes`しておくと、クエリが減って効率が高まります。

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

`readonly`を指定すると、関連付けられたオブジェクトを読み出し専用で取り出します。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトではすべてのカラムを取り出します。

#### 関連付けられたオブジェクトが存在するかどうかを確認する

`association.nil?`メソッドを用いて、関連付けられたオブジェクトが存在するかどうかを確認できます。

```ruby
if @supplier.account.nil?
  @msg = "この供給者のアカウントがありません"
end
```

#### オブジェクトが保存されるタイミング

`has_one`関連付けにオブジェクトを割り当てると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。さらに、オブジェクトを置き換えると外部キーも変更されるので、置き換えられたオブジェクトはすべて自動的に保存されます。

関連付けられているオブジェクト同士のいずれか一方がバリデーションによって保存に失敗すると、割り当ての状態が`false`になり、割り当てはキャンセルされます。

親オブジェクト（`has_one`関連付けを宣言している側のオブジェクト）が保存されていない場合（つまり`new_record?`が`true`を返す場合）、子オブジェクトは保存されません。親オブジェクトが保存されると、子オブジェクトは自動的に保存されます。

`has_one`関連付けにオブジェクトを割り当てて、しかもそのオブジェクトを保存したくない場合は、`build_association`メソッドをお使いください。

### `has_many`関連付けの詳細な参照

`has_many`関連付けは、他のモデルとの間に「1対多」のつながりを作成します。データベースの観点では、この関連付けは、他のクラスがこのクラスのインスタンスを参照する外部キーを持っていることを意味します。

#### `has_many`で追加されるメソッド

`has_many`関連付けを宣言したクラスでは、以下の17のメソッドが自動的に利用できるようになります。

* `collection`
* [`collection<<(object, ...)`][`collection<<`]
* [`collection.delete(object, ...)`][`collection.delete`]
* [`collection.destroy(object, ...)`][`collection.destroy`]
* `collection=(objects)`
* `collection_singular_ids`
* `collection_singular_ids=(ids)`
* [`collection.clear`][]
* [`collection.empty?`][]
* [`collection.size`][]
* [`collection.find(...)`][`collection.find`]
* [`collection.where(...)`][`collection.where`]
* [`collection.exists?(...)`][`collection.exists?`]
* [`collection.build(attributes = {})`][`collection.build`]
* [`collection.create(attributes = {})`][`collection.create`]
* [`collection.create!(attributes = {})`][`collection.create!`]
* [`collection.reload`][]

上のメソッド名の*`collection`*の部分は**プレースホルダ**なので、`has_many`の第1引数として渡されるものの名前で読み替えてください。また、*`collection_singular`*の部分は名前を単数形にして読み替えてください。たとえば以下の宣言があるとします。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

これにより、`Author`モデルのインスタンスで以下のメソッドが使えるようになります。

```
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

[`collection<<`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-3C-3C
[`collection.build`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-build
[`collection.clear`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-clear
[`collection.create`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-create
[`collection.create!`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-create-21
[`collection.delete`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-delete
[`collection.destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-destroy
[`collection.empty?`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-empty-3F
[`collection.exists?`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F
[`collection.find`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-find
[`collection.reload`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-reload
[`collection.size`]: https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-size
[`collection.where`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where

##### `collection`

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books
```

##### `collection<<(object, ...)`

[`collection<<`][]メソッドは、1つ以上のオブジェクトをコレクションに追加します。このとき、追加されるオブジェクトの外部キーは、呼び出し側モデルの主キーに設定されます。

```ruby
@author.books << @book1
```

##### `collection.delete(object, ...)`

[`collection.delete`][]メソッドは、外部キーを`NULL`に設定することで、コレクションから1個以上のオブジェクトを削除します。

```ruby
@author.books.delete(@book1)
```

WARNING: 削除の方法はこれだけではありません。オブジェクト同士が`dependent: :destroy`で関連付けられている場合はdestroyされますが、オブジェクト同士が`dependent: :delete_all`で関連付けられている場合はdeleteされるのでご注意ください。

##### `collection.destroy(object, ...)`

[`collection.destroy`][]は、コレクションに関連付けられているオブジェクトに対して`destroy`を実行することで、コレクションから1つまたは複数のオブジェクトを削除します。

```ruby
@author.books.destroy(@book1)
```

WARNING: この場合オブジェクトは**無条件に**データベースから削除されます。このとき`:dependent`オプションはすべて無視されます。

##### `collection=(objects)`

`collection=`メソッドは、削除や追加を適宜実行することで、コレクションに渡されたオブジェクトだけが含まれるようにします。変更の結果はデータベースで永続化されます。

##### `collection_singular_ids`

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@book_ids = @author.book_ids
```

##### `collection_singular_ids=(ids)`

`collection_singular_ids=`メソッドは、削除や追加を適宜実行することで、指定された主キーのidを持つオブジェクトだけが含まれるようにします。変更の結果はデータベースで永続化されます。

##### `collection.clear`

[`collection.clear`][]メソッドは、`dependent`オプションで指定された戦略に沿って、コレクションからすべてのオブジェクトを削除します。オプションが渡されなかった場合は、デフォルトの戦略に従います。デフォルトの戦略は、`has_many :through`の関連付けの場合は`delete_all`が指定され、`has_many`の関連付けの場合は外部キーが`NULL`に設定されます。

```ruby
@author.books.clear
```

WARNING: `dependent: :delete_all`の場合と同様に、オブジェクトが`dependent: :destroy`または`dependent: :destroy_async`で関連付けされていた場合、それらのオブジェクトは削除されます。

##### `collection.empty?`

[`collection.empty?`][]メソッドは、関連付けられたオブジェクトがコレクションに存在しない場合に`true`を返します。

```erb
<% if @author.books.empty? %>
  No Books Found
<% end %>
```

##### `collection.size`

[`collection.size`][]メソッドは、コレクションに含まれるオブジェクトの個数を返します。

```ruby
@book_count = @author.books.size
```

##### `collection.find(...)`

[`collection.find`][]メソッドは、コレクションに含まれるオブジェクトを検索します。

```ruby
@available_book = @author.books.find(1)
```

##### `collection.where(...)`

[`collection.where`][]メソッドは、コレクションに含まれているオブジェクトを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み（lazy load）されるので、オブジェクトに実際にアクセスするときだけデータベースへのクエリが発生します。

```ruby
@available_books = @author.books.where(available: true) # クエリはまだ発生しない
@available_book = @available_books.first                # ここでクエリが発生する
```

##### `collection.exists?(...)`

[`collection.exists?`][]メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。

##### `collection.build(attributes = {}, ...)`

[`collection.build`][]メソッドは、関連付けされた型のオブジェクトまたはオブジェクトの配列を返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが作成されます。関連付けられたオブジェクトはまだ**保存されていない**ことにご注意ください。

```ruby
@book = @author.books.build(published_at: Time.now,
                            book_number: "A12345")

@books = @author.books.build([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
])
```

##### `collection.create(attributes = {})`

[`collection.create`][]メソッドは、関連付けされた型の新しいオブジェクトまたはオブジェクトの配列を返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが作成されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは**保存されます**。

```ruby
@book = @author.books.create(published_at: Time.now,
                                 book_number: "A12345")

@books = @author.books.create([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
    ...
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### `collection.reload`

[`collection.reload`][]メソッドは、関連付けられたすべてのオブジェクトのリレーションを1つ返し、データベースを強制的に読み出します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books.reload
```

#### `has_many`のオプション

Railsのデフォルトの`has_many`関連付けは優秀なので、ほとんどの場合カスタマイズ不要ですが、関連付けの参照をカスタマイズしたい場合もあります。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :delete_all, validate: false
end
```

[`has_many`][]関連付けでは以下のオプションがサポートされます。

* `:as`
* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:disable_joins`
* `:ensuring_owner_was`
* `:extend`
* `:foreign_key`
* `:foreign_type`
* `:inverse_of`
* `:primary_key`
* `:query_constraints`
* `:source`
* `:source_type`
* `:strict_loading`
* `:through`
* `:validate`

##### `:as`

`:as`オプションを設定すると、ポリモーフィック関連付けであることが指定されます。ポリモーフィック関連付けについて詳しくは本ガイドの[ポリモーフィック関連付け](#ポリモーフィック関連付け)を参照してください。

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべてのメンバを保存し、destroyフラグが立っているメンバを破棄します。
`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは**同じではありません**。`:autosave`オプションを渡さない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連付けの相手となるオブジェクト名を関連付け名から生成できない事情がある場合、`:class_name`オプションを用いてモデル名を直接指定できます。たとえば、1人の著者（author）が複数の書籍（books）を持っているが、実際の書籍モデル名が`Transaction`である場合には以下のように指定します。

```ruby
class Author < ApplicationRecord
  has_many :books, class_name: "Transaction"
end
```

##### `:counter_cache`

このオプションは、`:counter_cache`オプションを任意の名前に変更したい場合に使います。このオプションは、[belongs_toの関連付け](#belongs-to%E3%81%AE%E3%82%AA%E3%83%97%E3%82%B7%E3%83%A7%E3%83%B3)で`:counter_cache`の名前を変更したときにのみ必要になります。

##### `:dependent`

オーナーオブジェクトがdestroyされたときに、オーナーに関連付けられたオブジェクトの扱いを制御します。

* `:destroy`: 関連付けられたオブジェクトもすべて同時にdestroyされます。
* `:delete_all`: 関連付けられたオブジェクトはすべてデータベースから直接削除されます（コールバックは実行されません）。
* `:destroy_async`: オブジェクトが削除されるときに、`ActiveRecord::DestroyAssociationAsyncJob`ジョブがジョブキューに入り、関連付けられたオブジェクトで`destroy`メソッドを呼び出します。このジョブが動作するには、Active Jobをセットアップしておく必要があります。
* `:nullify`: 外部キーは`NULL`に設定されます。ポリモーフィックなtypeカラムもポリモーフィック関連付けで`NULL`に設定されます。コールバックは実行されません。
* `:restrict_with_exception`: 関連付けられたレコードがある場合に`ActiveRecord::DeleteRestrictionError`例外が発生します。
* `:restrict_with_error`: 関連付けられたオブジェクトがある場合にエラーがオーナーに追加されます。

`:destroy`オプションや`:delete_all`オプションは、`collection.delete`メソッドや`collection=`メソッドのセマンティクス（意味）にも影響します（コレクションから削除されると、関連付けられたオブジェクトもdestroyされます）。

##### `:disable_joins`

関連付けでJOINをスキップするかどうかを指定します。
`true`を指定した場合、クエリが2つ以上生成されるようになります。ただし場合によっては、ORDERやLIMITが適用されるとデータベースの制限によりインメモリで処理されることがあります。
このオプションは、`has_many :through associations`関連付けにのみ適用されます（`has_many`単体ではJOINは実行されません）。

##### `:ensuring_owner_was`

オーナーによって呼び出されるインスタンスメソッドを指定します。関連付けられるレコードがバックグラウンドジョブで削除されるようにするには、このメソッドが`true`を返さなければなりません。

##### `:extend`

返される関連付けオブジェクトを拡張するのに使うモジュール（またはモジュールの配列）を指定します。メソッドを複数の関連付けで定義する場合、特に複数の関連付けオブジェクト間で共有する必要がある場合に便利です。

##### `:foreign_key`

Railsの規約では、相手のモデル上の外部キーを保持しているカラム名については、そのモデル名にサフィックス `_id` を追加した関連付け名が使われることを前提とします。`:foreign_key`オプションを使うと外部キーの名前を直接指定できます。

```ruby
class Author < ApplicationRecord
  has_many :books, foreign_key: "cust_id"
end
```

TIP: Railsは外部キーのカラムを自動的に作成することはありません。外部キーを使うには、マイグレーションで明示的に定義する必要があります。

##### `:foreign_type`

ポリモーフィック関連付けが有効になっている場合、関連付けられるオブジェクトの型を保存するカラムを指定します。デフォルトでは、`as`オプションで指定したポリモーフィック関連付け名に`_type`サフィックスを追加した名前を推測します。したがって、`has_many :tags, as: :taggable`という関連付けを定義するクラスでは、`taggable_type`がデフォルトの`:foreign_type`として使われます。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`belongs_to`関連付けの名前を指定します。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: :author
end

class Book < ApplicationRecord
  belongs_to :author, inverse_of: :books
end
```

##### `:primary_key`

Railsの規約では、関連付けの主キーは`id`カラムに保存されていることを前提とします。`:primary_key`オプションで主キーを明示的に指定することでこれを上書きできます。

`users`テーブルに主キーとして`id`カラムがあり、その他に`guid`カラムもあるとします。要件として、`todos`テーブルで（`id`ではなく）`guid`カラムの値を外部キーとして使いたいとします。これは以下のように実現できます。

```ruby
class User < ApplicationRecord
  has_many :todos, primary_key: :guid
end
```

`@todo = @user.todos.create`を実行すると、`@todo`レコードの`user_id`の値は `@user`の`guid`になります。

##### `:query_constraints`

複合外部キーとして機能するようになります。関連付けられるオブジェクトをクエリするために使うカラムのリストを定義します。この機能はオプションです（デフォルトでは、値の自動導出を試みます）。値が設定されている場合、`Array`のサイズは、関連付けられるモデルの主キーのサイズまたは`query_constraints`のサイズと一致する必要があります。

##### `:source`

`:source`オプションは、`has_many :through`関連付けで用いる関連付け元の名前を指定します。このオプションが必要になるのは、関連付け名から関連付け元の名前を自動的に推論できない場合のみです。

##### `:source_type`

`:source_type`オプションは、ポリモーフィック関連付けを介する`has_many :through`関連付けで、関連付け元の型を指定します。

```ruby
class Author < ApplicationRecord
  has_many :books
  has_many :paperbacks, through: :books, source: :format, source_type: "Paperback"
end

class Book < ApplicationRecord
  belongs_to :format, polymorphic: true
end

class Hardback < ApplicationRecord; end
class Paperback < ApplicationRecord; end
```

##### `:strict_loading`

`true`を指定すると、関連付けられるレコードが、この関連付けを経由して読み込まれるたびにstrict loadingを強制するようになります。

##### `:through`

`:through`オプションは、[本ガイドで既に説明した](#has-one-through関連付け)`has_one :through`関連付けのクエリを実行する際に経由するjoinモデルを指定します。

##### `:validate`

`:validate`オプションを`false`に設定すると、新たに関連付けられたオブジェクトは保存時にバリデーションされません。デフォルトは`true`であり、この場合新たに関連付けられたオブジェクトは保存時にバリデーションされます。

#### `has_many`のスコープ

`has_many`で使われるクエリをカスタマイズしたい場合があります。スコープブロックを用いてこのようなカスタマイズを行えます。以下に例を示します。

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

条件はハッシュで指定することもできます。

```ruby
class Author < ApplicationRecord
  has_many :confirmed_books, -> { where confirmed: true },
    class_name: "Book"
end
```

`where`オプションでハッシュを用いた場合、この関連付けで作成されたレコードは自動的にこのハッシュを使うスコープに含まれるようになります。この例の場合、`@author.confirmed_books.create`または`@author.confirmed_books.build`を実行すると、`confirmed`カラムの値が`true`の書籍（book）が常に作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については[後述します](#関連付けの拡張)。

##### `group`

`group`メソッドは、結果をグループ化する属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使われます。

```ruby
class Author < ApplicationRecord
  has_many :chapters, -> { group 'books.id' },
                      through: :books
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager loadingすべき第2関連付けを指定できます。以下のモデルを例に考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters
end

class Chapter < ApplicationRecord
  belongs_to :book
end
```

著者名（author）から本の章（chapter）を`@author.books.chapters`のように直接取り出す頻度が高い場合は、`Author`から`Book`への関連付けを行なう時に`Chapters`をあらかじめ`includes`しておくと、クエリが減って効率が高まります。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { includes :chapters }
end

class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters
end

class Chapter < ApplicationRecord
  belongs_to :book
end
```

##### `limit`

`limit`メソッドは、関連付けを用いて取得できるオブジェクトの総数の上限を指定するのに使います。

```ruby
class Author < ApplicationRecord
  has_many :recent_books,
    -> { order('published_at desc').limit(100) },
    class_name: "Book"
end
```

##### `offset`

`offset`メソッドは、関連付けを用いてオブジェクトを取得する際の開始オフセットを指定します。たとえば、`-> { offset(11) }`と指定すると、最初の11レコードはスキップされ、12レコード目以降が返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトの並び順を指定します。内部的にはSQLの`ORDER BY`句が使われます。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order "date_confirmed DESC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを読み出し専用で取り出します。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトではすべてのカラムを取り出します。

WARNING: 独自の`select`メソッドを使う場合には、関連付けられているモデルの主キーカラムと外部キーカラムを必ず含めておいてください。これを行わなかった場合、Railsでエラーが発生します。

##### `distinct`

`distinct`メソッドは、コレクション内で重複が発生しないようにします。
このメソッドは`:through`オプションと併用するときに特に便利です。

```ruby
class Person < ApplicationRecord
  has_many :readings
  has_many :articles, through: :readings
end
```

```irb
irb> person = Person.create(name: 'John')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
irb> person.articles.to_a
=> [#<Article id: 5, name: "a1">, #<Article id: 5, name: "a1">]
irb> Reading.all.to_a
=> [#<Reading id: 12, person_id: 5, article_id: 5>, #<Reading id: 13, person_id: 5, article_id: 5>]
```

上の例の場合、2つのreadingがどちらも同じ記事を指しており、`person.articles`を実行すると同じ記事が2件取り出されてしまいます。

今度は`distinct`を設定してみましょう。

```ruby
class Person
  has_many :readings
  has_many :articles, -> { distinct }, through: :readings
end
```

```irb
irb> person = Person.create(name: 'Honda')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
irb> person.articles.to_a
=> [#<Article id: 7, name: "a1">]
irb> Reading.all.to_a
=> [#<Reading id: 16, person_id: 7, article_id: 7>, #<Reading id: 17, person_id: 7, article_id: 7>]
```

上の例でも2つのreadingは重複していますが、`person.articles`を実行すると1件の記事だけを表示します。これはコレクションが一意のレコードのみを読み出しているからです。

挿入時にも同様に、永続化済みのレコードをすべて一意にする（関連付けを検査したときに重複レコードが決して発生しないようにする）には、テーブル自体にuniqueインデックスを追加する必要があります。たとえば`readings`というテーブルがあるとすると、1人のpersonに記事を1回しか追加できないようにするには、マイグレーションに以下を追加します。

```ruby
add_index :readings, [:person_id, :article_id], unique: true
```

インデックスが一意になると、同じ記事をpersonに2回追加しようとすると
`ActiveRecord::RecordNotUnique`エラーが発生するようになります

```irb
irb> person = Person.create(name: 'Honda')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
ActiveRecord::RecordNotUnique
```

なお、`include?`などのRubyメソッドで一意性をチェックすると競合が発生しやすいので注意が必要です。関連付けで強制的に一意にする目的で`include?`を使わないでください。たとえば上のarticleの例では、以下のコードで競合が発生しやすくなります。これは、複数のユーザーが同時にこのコードを実行する可能性があるためです。

```ruby
person.articles << article unless person.articles.include?(article)
```

#### オブジェクトが保存されるタイミング

`has_many`関連付けにオブジェクトを割り当てると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトを割り当てると、それらはすべて保存されます。

関連付けられているオブジェクトのどれかがバリデーションエラーで保存に失敗すると、割り当ての状態が`false`になり、割り当てはキャンセルされます。

親オブジェクト（`has_many`関連付けを宣言している側のオブジェクト）が保存されない場合（つまり`new_record?`が`true`を返す場合）、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバーはすべて保存されます。

`has_many`関連付けにオブジェクトを割り当てて、しかもそのオブジェクトを保存したくない場合、`collection.build`メソッドをお使いください。

### `has_and_belongs_to_many`関連付けの参照

`has_and_belongs_to_many`関連付けは、他のモデルとの間に「多対多」リレーションシップを作成します。データベースの観点では、2つのクラスは中間でjoinテーブルを介して関連付けられます。このjoinテーブルには、両方のクラスを参照する外部キーがそれぞれ含まれます。

#### `has_and_belongs_to_many`で追加されるメソッド

`has_and_belongs_to_many`関連付けを宣言したクラスでは、以下のメソッドが自動的に利用できるようになります。

* `collection`
* [`collection<<(object, ...)`][`collection<<`]
* [`collection.delete(object, ...)`][`collection.delete`]
* [`collection.destroy(object, ...)`][`collection.destroy`]
* `collection=(objects)`
* `collection_singular_ids`
* `collection_singular_ids=(ids)`
* [`collection.clear`][]
* [`collection.empty?`][]
* [`collection.size`][]
* [`collection.find(...)`][`collection.find`]
* [`collection.where(...)`][`collection.where`]
* [`collection.exists?(...)`][`collection.exists?`]
* [`collection.build(attributes = {})`][`collection.build`]
* [`collection.create(attributes = {})`][`collection.create`]
* [`collection.create!(attributes = {})`][`collection.create!`]
* [`collection.reload`][]

上のメソッド名の*`collection`*の部分は**プレースホルダ**なので、`has_and_belongs_to_many`の第1引数として渡されるものの名前で読み替えてください。また、*`collection_singular`*の部分は名前を単数形にして読み替えてください。たとえば以下の宣言があるとします。

```ruby
class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

これにより、`Part`モデルのインスタンスで以下のメソッドが使えるようになります。

```
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

`has_and_belongs_to_many`関連付けで利用している中間のjoinテーブルが、2つの外部キー以外のカラムを含んでいる場合、これらのカラムは関連付けを介して取り出されるレコードに属性として追加されます。属性が追加されたレコードは常に読み出し専用になります。このようにして読み出された属性に対する変更は保存できないためです。

WARNING: `has_and_belongs_to_many`関連付けで使うjoinテーブルにこのような余分なカラムを追加することは非推奨化されています。2つのモデルを多対多リレーションシップで結合するjoinテーブルでこのような複雑な振る舞いが必要な場合は、`has_and_belongs_to_many`ではなく`has_many :through`をお使いください。


##### `collection`

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを1つ返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@assemblies = @part.assemblies
```

##### `collection<<(object, ...)`

[`collection<<`][]メソッドは、joinテーブル上でレコードを作成し、それによって1個以上のオブジェクトをコレクションに追加します。

```ruby
@part.assemblies << @assembly1
```

NOTE: このメソッドは`collection.concat`および`collection.push`のエイリアスです。

##### `collection.delete(object, ...)`

[`collection.delete`][]メソッドは、joinテーブル上のレコードを削除し、それによって1個以上のオブジェクトをコレクションから削除します。オブジェクトはdestroyされません。

```ruby
@part.assemblies.delete(@assembly1)
```

##### `collection.destroy(object, ...)`

[`collection.destroy`][]メソッドは、joinテーブル上のレコードを削除することで、1個以上のオブジェクトをコレクションから削除します。オブジェクトはdestroyされません。

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

`collection_singular_ids=`メソッドは、指定された主キーidを持つオブジェクトでコレクションの内容を置き換えます。元からあったオブジェクトは削除されます。この変更はデータベースで永続化されます。

##### `collection.clear`

[`collection.clear`][]メソッドは、joinテーブル上のレコードを削除し、それによってすべてのオブジェクトをコレクションから削除します。このメソッドを実行しても、関連付けられたオブジェクトはdestroyされません。

##### `collection.empty?`

[`collection.empty?`][]メソッドは、関連付けられたオブジェクトがコレクションに含まれていない場合に`true`を返します。

```html+erb
<% if @part.assemblies.empty? %>
  ※この部品はどの完成品でも使われていません。
<% end %>
```

##### `collection.size`

[`collection.size`][]メソッドは、コレクションに含まれるオブジェクトの個数を返します。

```ruby
@assembly_count = @part.assemblies.size
```

##### `collection.find(...)`

[`collection.find`][]メソッドは、コレクションに含まれるオブジェクトを検索します。

```ruby
@assembly = @part.assemblies.find(1)
```

##### `collection.where(...)`

[`collection.where`][]メソッドは、コレクションに含まれているオブジェクトを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み（lazy load）されるので、オブジェクトに実際にアクセスするときだけデータベースへのクエリが発生します。

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

##### `collection.exists?(...)`

[`collection.exists?`][]メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。

##### `collection.build(attributes = {})`

[`collection.build`][]メソッドは、関連付けられた型の新しいオブジェクトを1つ返します。このオブジェクトは、渡された属性でインスタンス化され、そのjoinテーブルを介してリンクが作成されます。ただし、関連付けられたオブジェクトはこの時点では保存されて**いない**ことにご注意ください。

```ruby
@assembly = @part.assemblies.build({ assembly_name: "Transmission housing" })
```

##### `collection.create(attributes = {})`

[`collection.create`][]メソッドは、関連付けられた型の新しいオブジェクトを1つ返します。このオブジェクトは、渡された属性を用いてインスタンス化され、joinテーブルを介してリンクが作成されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは保存されます。

```ruby
@assembly = @part.assemblies.create({ assembly_name: "Transmission housing" })
```

##### `collection.create!(attributes = {})`

上の`collection.create`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### `collection.reload`

[`collection.reload`][]メソッドは、関連付けられたすべてのオブジェクトのリレーションを1つ返し、データベースを強制的に読み出します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@assemblies = @part.assemblies.reload
```

#### `has_and_belongs_to_many`のオプション

Railsのデフォルトの`has_and_belongs_to_many`関連付けは優秀なので、ほとんどの場合カスタマイズ不要ですが、関連付けの参照をカスタマイズしたい場合もあります。これは、作成するときにオプションを渡すことで簡単にカスタマイズできます。たとえば、以下のようなオプションを関連付けに追加できます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { readonly },
                                       autosave: true
end
```

[`has_and_belongs_to_many`][]関連付けでは以下のオプションがサポートされます。

* `:association_foreign_key`
* `:autosave`
* `:class_name`
* `:foreign_key`
* `:join_table`
* `:strict_loading`
* `:validate`

##### `:association_foreign_key`

Railsの慣例では、相手のモデルを指す外部キーを保持しているjoinテーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使われることを前提とします。`:association_foreign_key`オプションを使うと外部キーの名前を直接指定できます。

TIP: `:foreign_key`オプションおよび`:association_foreign_key`オプションは、以下のような多対多の自己結合を行いたいときに便利です。

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:autosave`

`:autosave`オプションを`true`に設定すると、親オブジェクトが保存されるたびに、読み込まれているすべての関連付けられたメンバを保存し、destroyフラグが立っているメンバを破棄します。
`:autosave`を`false`に設定することと、`:autosave`オプションを未設定のままにしておくことは**同じではありません**。`:autosave`オプションを渡さない場合、関連付けられたオブジェクトのうち、新しいオブジェクトは保存されますが、更新されたオブジェクトは保存されません。

##### `:class_name`

関連付けの相手となるオブジェクト名を関連付け名から生成できない事情がある場合、`:class_name`オプションを用いてモデル名を直接指定できます。たとえば、1つの部品（Part）が複数の組み立て（Assembly）で使われ、組み立てを含む実際のモデル名が`Gadget`である場合、次のように設定します。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, class_name: "Gadget"
end
```

##### `:foreign_key`

Railsの規約では、そのモデルを指す外部キーを保持しているjoinテーブル上のカラム名については、そのモデル名にサフィックス `_id` を追加した名前が使われることを前提とします。`:foreign_key`オプションを使うと外部キーの名前を直接指定できます。

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:join_table`

辞書順に基いて生成されたjoinテーブルのデフォルト名が気に入らない場合、`:join_table`オプションを用いてデフォルトのテーブル名を上書きできます。

##### `:strict_loading`

`true`を指定すると、関連付けられるレコードが、この関連付けを経由して読み込まれるたびにstrict loadingを強制するようになります。

##### `:validate`

`:validate`オプションを`false`に設定すると、新たに関連付けられたオブジェクトは保存時にバリデーションされません。デフォルトは`true`であり、この場合新たに関連付けられたオブジェクトは保存時にバリデーションされます。

#### `has_and_belongs_to_many`のスコープ

`has_and_belongs_to_many`で使われるクエリをカスタマイズしたい場合があります。スコープブロックを用いてこのようなカスタマイズを行えます。以下に例を示します。

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

`where`オプションでハッシュを用いた場合、この関連付けで作成されたレコードは自動的にこのハッシュを使うスコープに含まれるようになります。この例の場合、`@parts.assemblies.create`または`@parts.assemblies.build`を実行すると、`factory`カラムに`Seattle`を持つassembliesが作成されます。

##### `extending`

`extending`メソッドは、関連付けプロキシを拡張する名前付きモジュールを指定します。関連付けの拡張については[後述します](#関連付けの拡張)。

##### `group`

`group`メソッドは、結果をグループ化する属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使われます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `includes`

`includes`メソッドを使うと、その関連付けが使われるときにeager loadingすべき第2関連付けを指定できます。

##### `limit`

`limit`メソッドは、関連付けを用いて取得できるオブジェクトの総数の上限を指定するのに使います。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `offset`

`offset`メソッドは、関連付けを用いてオブジェクトを取得する際の開始オフセットを指定します。たとえばoffset(11)と指定すると、最初の11レコードはスキップされ、12レコード以降が返されるようになります。

##### `order`

`order`メソッドは、関連付けられたオブジェクトの並び順を指定します。内部的にはSQLの`ORDER BY`句が使われます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order "assembly_name ASC" }
end
```

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを読み出し専用で取り出します。

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトではすべてのカラムを取り出します。

##### `distinct`

`distinct`メソッドは、コレクション内の重複を削除します。

#### オブジェクトが保存されるタイミング

`has_and_belongs_to_many`関連付けにオブジェクトを割り当てると、joinテーブルを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトを割り当てると、それらはすべて保存されます。

関連付けられているオブジェクト同士のどれかがバリデーションエラーで保存に失敗すると、割り当ての状態が`false`になり、割り当てはキャンセルされます。

親オブジェクト（`has_and_belongs_to_many`関連付けを宣言している側のオブジェクト）が保存されない場合（つまり`new_record?`が`true`を返す場合）、子オブジェクトは追加時に保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバはすべて保存されます。

`has_and_belongs_to_many`関連付けにオブジェクトを割り当てて、しかもそのオブジェクトを保存したくない場合は、`collection.build`メソッドをお使いください。

### 関連付けのコールバック

通常のコールバックは、Active Recordオブジェクトのライフサイクルの中でフックされます。これにより、オブジェクトのさまざまな場所でコールバックを実行できます。たとえば、`:before_save`コールバックを使って、オブジェクトが保存される直前に何かを実行できます。

関連付けのコールバックも、上のような通常のコールバックと似ていますが、（Active Recordオブジェクトではなく）コレクションのライフサイクルによってイベントがトリガされる点が異なります。以下の4つの関連付けコールバックを利用できます。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

これらのオプションを関連付けの宣言に追加することで、関連付けコールバックを定義できます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_credit_limit

  def check_credit_limit(book)
    # ...
  end
end
```

関連付けのコールバックについて詳しくは、[Active Recordコールバックガイド](active_record_callbacks.html#関連付けのコールバック)を参照してください。

### 関連付けの拡張

Railsは自動的に機能を関連付けのプロキシオブジェクトにビルドしますが、開発者はこれをカスタマイズできます。無名モジュール（anonymous module）を用いてこれらのオブジェクトを拡張（検索、作成などのメソッドを追加）できます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books do
    def find_by_book_prefix(book_number)
      find_by(category_id: book_number[0..2])
    end
  end
end
```

拡張をさまざまな関連付けで共有したい場合は、名前付きの拡張モジュールを使うことも可能です。以下に例を示します。

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

* `proxy_association.owner`: 関連付けを所有するオブジェクトを返します。
* `proxy_association.reflection`: 関連付けを記述するリフレクションオブジェクトを返します。
* `proxy_association.target`: `belongs_to`または`has_one`関連付けのオブジェクトを返すか、`has_many`または`has_and_belongs_to_many`関連付けオブジェクトのコレクションを返します。

### 関連付けのオーナーで関連付けのスコープを制御する

関連付けのスコープをさらに制御する必要がある状況では、関連付けのオーナーをスコープブロックに引数として渡すことが可能です。ただし、関連付けのプリロードができなくなる点にご注意ください。

```ruby
class Supplier < ApplicationRecord
  has_one :account, ->(supplier) { where active: supplier.active? }
end
```
単一テーブル継承 （STI）
------------------------

異なるモデル間でフィールドや振る舞いを共有したい場合があります。
たとえば、`Car`モデル、`Motorcycle`モデル、`Bicycle`モデルがあり、`color`や`price`などのフィールドや、いくつかの関連メソッドを共有したいが、モデルごとに振る舞いやコントローラーが異なっているとしましょう。

まず、各モデルのベースとなる`Vehicle`モデルを生成します。

```bash
$ bin/rails generate model vehicle type:string color:string price:decimal{10.2}
```

"type"フィールドを追加している点にご注目ください。すべてのモデルはデータベース上のテーブルに保存されるため、Railsはこのカラムに該当するモデル名を保存します。この例では "Car"、"Motorcycle"または"Bicycle"になります。この例の単一テーブル継承（STI: Single Table Inheritance）では、テーブルに"type"フィールドがないとうまく動きません。

次に、`Vehicle`モデルを継承して3つのモデルをそれぞれ生成します。このとき、`--parent=親モデル`オプションを使って特定の親モデルを継承している点にご注目ください。このオプションを使うと、同様のマイグレーションファイルを生成せずにモデルを生成できます（該当するテーブルが既に存在しているため）。

たとえば`Car`モデルの場合は以下のようになります。

```bash
$ bin/rails generate model car --parent=Vehicle
```

生成されたモデルは次のようになります。

```ruby
class Car < Vehicle
end
```

これによって`Vehicle`モデルに追加されたすべての振る舞いが`Car`モデルにも追加されるようになります。関連付けやpublicメソッドなども同様に追加されます。

この状態で新しく作成した`Car`を保存すると、`type`フィールドに"Car"が代入されたデータが`vehicles`テーブルに追加されます。

```ruby
Car.create(color: 'Red', price: 10000)
```

実際に生成されるSQLは次のようになります。

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

### 継承カラムをオーバーライドする

レガシーデータベースで作業する場合などで、継承カラム名をオーバーライドする必要が生じることがあります。これは、[inheritance_column][]メソッドで実現できます。

```ruby
# スキーマ: vehicles[ id, kind, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = "kind"
end

class Car < Vehicle
end

Car.create
# => #<Car kind: "Car">
```

### 継承カラムを無効にする

レガシーデータベースで作業する場合などで、単一テーブル継承を完全に無効にする必要が生じる（そうしないと[`ActiveRecord::SubclassNotFound`][]が発生する）ことがあります。

これは、[inheritance_column][]を`nil`に設定することで実現できます。

```ruby
# スキーマ: vehicles[ id, type, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = nil
end

Vehicle.create!(type: "Car")
# => #<Vehicle type: "Car">
```

[inheritance_column]: https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-c-inheritance_column
[`ActiveRecord::SubclassNotFound`]: https://api.rubyonrails.org/classes/ActiveRecord/SubclassNotFound.html

Delegated Types
----------------

[単一テーブル継承（STI）](#%E5%8D%98%E4%B8%80%E3%83%86%E3%83%BC%E3%83%96%E3%83%AB%E7%B6%99%E6%89%BF-%EF%BC%88sti%EF%BC%89)は、サブクラスとその属性にほとんど違いがない場合に最適ですが、単一テーブルを作るために必要なすべてのサブクラスのすべての属性を含めることになります。

この方法の欠点は、テーブルが肥大化することです。他のクラスでは使われないサブクラス固有の属性まで含まれてしまうからです。

以下の例では、同じ"Entry"クラスを継承する2つのActive Recordモデルがあり、`subject`属性が含まれています。

```ruby
# Schema: entries[ id, type, subject, created_at, updated_at]
class Entry < ApplicationRecord
end

class Comment < Entry
end

class Message < Entry
end
```

delegated typesでは、`delegated_type`を用いてこの問題を解決します。

delegated typesを使うためには、特定の方法でデータをモデル化する必要があります。要件は以下の通りです。

* すべてのサブクラス間で共有される属性をテーブルに格納するスーパークラスが存在すること。
* 各サブクラスはスーパークラスを継承しなければならず、そのクラス固有の追加属性のために別のテーブルを持たなければならない。

これにより、すべてのサブクラスで意図せず共有される属性を1個のテーブルで定義する必要がなくなります。

これを上記の例に適用するためには、モデルを再度生成する必要があります。
まず、スーパークラスとして機能するベース`Entry`モデルを生成してみましょう：

```bash
$ bin/rails generate model entry entryable_type:string entryable_id:integer
```

次に、委譲で使う新しい`Message`モデルと`Comment`モデルを生成します。

```bash
$ bin/rails generate model message subject:string body:string
$ bin/rails generate model comment content:string
```

ジェネレータを実行すると、次のようなモデルができるはずです。

```ruby
# Schema: entries[ id, entryable_type, entryable_id, created_at, updated_at ]
class Entry < ApplicationRecord
end

# Schema: messages[ id, subject, body, created_at, updated_at ]
class Message < ApplicationRecord
end

# Schema: comments[ id, content, created_at, updated_at ]
class Comment < ApplicationRecord
end
```

### `delegated_type`を宣言する

まず、`Entry`スーパークラスで`delegated_type`を宣言します。

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[ Message Comment ], dependent: :destroy
end
```

`entryable`パラメータは、委譲で使うフィールドを指定し、委譲クラスとして`Message`型と`Comment`型を含みます。

この`Entry`クラスは`entryable_type`フィールドと`entryable_id`フィールドを持ちます。これは、`delegated_type`の定義内で、`entryable`という名前に`_type`と`_id`というサフィックスを付加したフィールドです。

`entryable_type`には委譲サブクラス名が保存され、`entryable_id`には委譲サブクラスのレコードIDが保存されます。

次に、それらのdelegated typesを実装するモジュールを定義する必要があります。このモジュールは、`as: :entryable`パラメータを`has_one`関連付けに宣言することで定義します。

```ruby
module Entryable
  extend ActiveSupport::Concern

  included do
    has_one :entry, as: :entryable, touch: true
  end
end
```

続いて、作成したモジュールをサブクラスに`include`します。

```ruby
class Message < ApplicationRecord
  include Entryable
end

class Comment < ApplicationRecord
  include Entryable
end
```

定義が完了し、`Entry`デリゲーターは以下のメソッドを提供するようになりました。

| メソッド | 戻り値 |
|---|---|
| `Entry.entryable_types` | `["Message", "Comment"]` |
| `Entry#entryable_class` | Message または Comment |
| `Entry#entryable_name` | "message" または "comment" |
| `Entry.messages` | `Entry.where(entryable_type: "Message")` |
| `Entry#message?` | `entryable_type == "Message"`の場合trueを返す |
| `Entry#message` | `entryable_type == "Message"`の場合はメッセージレコードを返し、それ以外の場合は `nil` を返す|
| `Entry#message_id` | `entryable_type == "Message"`の場合は`entryable_id`を返し、それ以外の場合は`nil`を返す |
| `Entry.comments` | `Entry.where(entryable_type: "Comment")` |
| `Entry#comment?` | `entryable_type == "Comment"`の場合はtrueを返す |
| `Entry#comment` | `entryable_type == "Comment"`の場合はコメント・メッセージを返し、それ以外の場合は`nil`を返す |
| `Entry#comment_id` | `entryable_type == "Comment"`の場合は`entryable_id`を返し、それ以外の場合は`nil`を返す |

### オブジェクトを作成する

新しい`Entry`オブジェクトを作成する際に、`entryable`サブクラスを同時に指定できます。

```ruby
Entry.create! entryable: Message.new(subject: "hello!")
```

### さらに委譲を追加する

`Entry`デリゲータを拡張し、`delegates`を定義してサブクラスに対してポリモーフィズムを使用することで、さらに拡張できます。

たとえば、`Entry`の`title`メソッドをそのサブクラスに委譲するには以下のようにします。

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[ Message Comment ]
  delegate :title, to: :entryable
end

class Message < ApplicationRecord
  include Entryable

  def title
    subject
  end
end

class Comment < ApplicationRecord
  include Entryable

  def title
    content.truncate(20)
  end
end
```
