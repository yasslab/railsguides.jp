Active Record の関連付け
==========================

本ガイドでは、Active Recordの関連付け機能（アソシエーション）について解説します。

このガイドの内容:

* さまざまな種別の関連付けを理解する
* Active Recordのモデル同士の関連付けを宣言する方法
* モデルに適した関連付けの種別を選ぶ方法
* STI（Single Table Inheritance）の利用方法
* Delegated Typesのセットアップ方法と利用方法

--------------------------------------------------------------------------------

関連付けの概要
-----------------

Active Recordの「**関連付け**（アソシエーション: association）」を使うと、モデル間のリレーションシップを定義できます。関連付けは特殊なマクロスタイルの呼び出しとして実装されており、モデル同士をどのように関連させるかをRailsに手軽に指定できます。これにより、データの管理がより効率的になり、一般的なデータ操作がシンプルで読みやすくなります。

INFO: マクロスタイルの呼び出しは、実行時に他のメソッドを動的に生成・変更するメソッドであり、Railsでのモデルの関連付けの定義など、簡潔で表現力豊かな機能の宣言を可能にします。たとえば`has_many :comments`のように記述します。

関連付けを設定すると、Railsが2つのモデルのインスタンス同士の[主キー（primary key）](https://ja.wikipedia.org/wiki/%E4%B8%BB%E3%82%AD%E3%83%BC)と[外部キー（foreign key）](https://ja.wikipedia.org/wiki/%E5%A4%96%E9%83%A8%E3%82%AD%E3%83%BC)のリレーションシップや管理を支援し、データベースがデータの整合性を保つようにします。これにより、関連付けられているデータの取得・更新・削除を手軽に行えるようになります。

これにより、どのレコードがどのレコードと関係があるかを簡単に把握できるようになります。また、モデルにさまざまな便利メソッドが追加されるため、関連データをより手軽に操作可能になります。

`Author`（著者）モデルと`Book`（書籍）モデルを持つシンプルなアプリケーションを例に考えてみましょう。

### 関連付けを使わない場合

関連付けが設定されていない以下のような場合、その著者の本を作成・削除するために、以下のように面倒な手動の処理が必要になります。

```ruby
class CreateAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :name
      t.timestamps
    end

    create_table :books do |t|
      t.references :author
      t.datetime :published_at
      t.timestamps
    end
  end
end
```

```ruby
class Author < ApplicationRecord
end

class Book < ApplicationRecord
end
```

ここで、既存の著者に新しい書籍を1件追加するには、以下のように`author_id`の値を明示的に指定しなければならないでしょう。

```ruby
@book = Book.create(author_id: @author.id, published_at: Time.now)
```

今度は著者を1人削除し、その著者の書籍もすべて削除する場合を考えてみましょう。以下のように、その著者の`books`をすべて取り出してから、個別の`book`を`each`で回して削除し、それが終わってから著者を削除しなければならないでしょう。

```ruby
@books = Book.where(author_id: @author.id)
@books.each do |book|
  book.destroy
end
@author.destroy
```

### 関連付けを使う場合

しかし関連付けを使えば、2つのモデルのリレーションシップをRailsに明示的に指定することで、こうした操作を効率化できます。関連付けを使う形で`Author`モデルと`Book`モデルを設定する修正コードは次のとおりです。

```ruby
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
end

class Book < ApplicationRecord
  belongs_to :author
end
```

上のように関連付けを追加したことで、特定の著者の新しい書籍を1冊追加する作業が以下のように1行でシンプルに書けるようになりました。

```ruby
@book = @author.books.create(published_at: Time.now)
```

著者と、その著者の書籍をまとめて削除する作業も、以下のようにずっと簡単に書けます。

```ruby
@author.destroy
```

Railsで関連付けを設定する場合は、データベースが関連付けを適切に処理するよう構成するために、[マイグレーション](active_record_migrations.html)を作成する必要があります。このマイグレーションでは、関連付けで必要となる外部キー列をデータベーステーブルに追加しておく必要があります。

たとえば、`Book`モデルに`belongs_to :author`関連付けを設定する場合は、`books`テーブルに`author_id`カラムを追加するマイグレーションを以下のコマンドで作成します。

```bash
rails generate migration AddAuthorToBooks author:references
```

このマイグレーションを行うことで、`author_id`カラムが追加され、データベースに外部キーのリレーションが設定され、それによってモデルとデータベースが同期した状態が維持されます。

その他の関連付け方法については、本ガイドの次のセクションをお読みください。その後に、関連付けに関するさまざまなヒントや活用方法も記載されています。ガイドの末尾では、Railsの関連付けメソッドとオプションの完全な参考情報も記載されています。

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

本ガイドでは以後、それぞれの関連付けの宣言方法と利用方法について詳しく解説します。その前に、それぞれの関連付けが適切となる状況について簡単にご紹介します。

[`belongs_to`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to
[`has_and_belongs_to_many`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_and_belongs_to_many
[`has_many`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many
[`has_one`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_one

### `belongs_to`関連付け

あるモデルで[`belongs_to`][]関連付けを行なうと、宣言を行った側のモデルの各インスタンスは、他方のモデルのインスタンスに文字どおり「従属（belongs to）」します。

たとえば、Railsアプリケーションに著者（`Author`）と書籍（`Book`）の情報が含まれており、書籍1冊につき正確に1人の著者を割り当てたい場合は、`Book`モデルで以下のように宣言します。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

![belongs_to関連付けの図](images/association_basics/belongs_to.png)

NOTE: `belongs_to`関連付けで指定するモデル名は必ず「**単数形**」にしなければなりません。上記の例で、`Book`モデルの`author`関連付けを複数形（`authors`）にしてから`Book.create(authors: @author)`でインスタンスを作成しようとすると、`uninitialized constant Book::Authors`エラーが発生します。Railsは、関連付けの名前から自動的にモデルのクラス名を推測します。関連付け名を`:authors`にすると、Railsは本来の`Author`クラスではなく`Authors`という誤ったクラス名を探索してしまいます。

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateBooks < ActiveRecord::Migration[8.0]
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

データベースの観点における`belongs_to`関連付けは、このモデルのテーブルに、他方のテーブルへの参照を表すカラムが存在することを意味します。これは、設定に応じて「1対1リレーション」や「1対多リレーション」を設定するのに使えます。**他方のクラスの**テーブルに1対1リレーションの参照が含まれている場合は、`belongs_to`関連付けではなく`has_one`関連付けを使う必要があります。

`belongs_to`を単独で利用すると、一方向の1対1リレーションが生成されます。したがって、上記の例における個別の`book`はその`author`を「認識」しますが、逆に`author`は自分の著書である`book`を認識しません。
[双方向関連付け](#双方向関連付け)を設定するには、`belongs_to`を他のモデル（この場合は`Author`モデル）の`has_one`または`has_many`と組み合わせる形で使います。

NOTE: `belongs_to`はデフォルトで、[参照整合性](https://ja.wikipedia.org/wiki/%E5%8F%82%E7%85%A7%E6%95%B4%E5%90%88%E6%80%A7)を保証するために、関連付けられたレコードの存在バリデーションを行います。

モデルで`optional`が`true`に設定されている場合、`belongs_to`は参照整合性を保証しません。つまり、あるテーブルの外部キーが指している、参照先のテーブルの主キーが必ずしも有効ではない可能性があります。

```ruby
class Book < ApplicationRecord
  belongs_to :author, optional: true
end
```

つまり、ユースケースによっては、以下のように`foreign_key: true`オプションでデータベースレベルの外部キー制約を参照カラムに追加する必要が生じることもあります。

```ruby
create_table :books do |t|
  t.belongs_to :author, foreign_key: true
  # ...
end
```

上のように設定することで、`author_id`カラムが`optional: true`でNULL許容に設定されているとしても、このカラムがNULLでない場合は、参照する`authors`テーブル内のレコードが必ず有効でなければならないことが保証されます。

#### `belongs_to`関連付けで追加されるメソッド

`belongs_to`関連付けを宣言したクラスでは、さまざまなメソッドが自動的に利用できるようになります。以下はその一部です。

* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`
* `reload_association`
* `reset_association`
* `association_changed?`
* `association_previously_changed?`

本ガイドでは、よく使われるメソッドの一部を取り上げていますが、完全なリストについては[Active Recordの関連付けAPI](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to)を参照してください。

上のメソッド名の*`association`*の部分は**プレースホルダ**なので、`belongs_to`の第1引数として渡されるシンボルで読み替えてください。
たとえば以下のようなモデルが宣言されているとします。

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  belongs_to :author
end

# app/models/author.rb
class Author < ApplicationRecord
  has_many :books
  validates :name, presence: true
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

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`association.build`メソッドではなく、必ず`build_`で始まるメソッドを使わなければなりません（`association.build`は、`has_many`関連付けや`has_and_belongs_to_many`関連付けで使います）。関連付けを作成する場合は、`create_`で始まるメソッドをお使いください。

##### 関連付けを取り出す

*`association`*メソッドは、関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@author = @book.author
```

このオブジェクトに関連付けられたオブジェクトがデータベースから既に取得されている場合は、キャッシュされたものを返します。この振る舞いを上書きして、キャッシュを読み出さずにデータベースから強制的に読み込みたい場合は、親オブジェクトが持つ`#reload_association`メソッドを呼び出します。

```ruby
@author = @book.reload_author
```

関連付けされたオブジェクトのキャッシュバージョンをアンロードして、次回のアクセスでデータベース呼び出しからクエリするには、親オブジェクトの`#reset_association`を呼び出します。

```ruby
@book.reset_author
```

##### 関連付けの割り当て

`association=`メソッドは、関連付けられたオブジェクトをそのオブジェクトに割り当てます。これは、このオブジェクトから主キーを抽出して、関連付けられたオブジェクトの外部キーに同じ値を設定することを意味しています。

```ruby
@book.author = @author
```

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトは、その時点ではまだ**保存されない**ことにご注意ください。

```ruby
@author = @book.build_author(author_number: 123,
                             author_name: "John Doe")
```

`create_association`メソッドは、上の`build_association`に加えて、関連付けられたモデルで指定されているバリデーションがすべてパスしたときに、そのオブジェクトの保存も行います。

```ruby
@author = @book.create_author(author_number: 123,
                              author_name: "John Doe")
```

最後に、`create_association!`は上の`create_association`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

```ruby
# nameが空なのでActiveRecord::RecordInvalidをraiseする
begin
  @book.create_author!(author_number: 123, name: "")
rescue ActiveRecord::RecordInvalid => e
  puts e.message
end
```

```irb
irb> raise_validation_error: Validation failed: Name can't be blank (ActiveRecord::RecordInvalid)
```

##### 関連付けが変更されたかどうかをチェックする

`association_changed?`メソッドは、新しい関連付けオブジェクトが割り当てられた場合に`true`を返します。外部キーは次の保存で更新されます。

`association_previously_changed?`メソッドは、関連付けが前回の保存で更新されて新しい関連付けオブジェクトを参照している場合に`true`を返します。

```ruby
@book.author # => #<Author author_number: 123, author_name: "John Doe">
@book.author_changed?            # => false
@book.author_previously_changed? # => false

@book.author = Author.second # => #<Author author_number: 456, author_name: "Jane Smith">
@book.author_changed?            # => true

@book.save!
@book.author_changed?            # => false
@book.author_previously_changed? # => true
```

NOTE: `model.association_changed?`と`model.association.changed?`を取り違えないようご注意ください。前者の`model.association_changed?`は、その関連付けが新しいレコードで置き換えられたかどうかをチェックしますが、後者の`model.association.changed?`は関連付けの「属性」が変更されたかどうかをチェックします。

##### 既存の関連付けが存在するかどうかをチェックする

`association.nil?`メソッドを用いて、関連付けられたオブジェクトが存在するかどうかをチェックできます。

```ruby
if @book.author.nil?
  @msg = "この本の著者が見つかりません"
end
```

##### オブジェクトが保存されるタイミング

オブジェクトを`belongs_to`関連付けに割り当てても、現在のオブジェクトや関連付けられたオブジェクトが自動的に保存されるわけでは**ありません**。ただし、現在のオブジェクトを保存すれば、関連付けられたオブジェクトも保存されます。

### `has_one`関連付け

[`has_one`][]関連付けは、相手側のモデルがこのモデルへの参照を持っていることを示します。相手側のモデルは、この関連付けを経由してフェッチできます。

たとえば、アプリケーション内で供給元（supplier）ごとにアカウント（account）が1個だけ存在する場合は、次のように`Supplier`モデルを宣言します。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end
```

`belongs_to`関連付けとの主な違いは、リンクカラム（ここでは`supplier_id`）が相手側のテーブルにあり、`has_one`を宣言したテーブルには存在しないことです。

![has_one関連付けの図](images/association_basics/has_one.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration[8.0]
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

`has_one`関連付けは、他方のモデルとの1対1対応を作成します。データベースの観点では、この`has_one`関連付けは、外部キーが他方のクラスに存在することを意味します。外部キーがこのクラスに含まれている場合は、`has_one`ではなく、代わりに`belongs_to`を使う必要があります。

ユースケースによっては、`accounts`テーブルとの関連付けのために、`supplier`カラムにuniqueインデックスか外部キー制約を追加する必要が生じることもあります。uniqueインデックスにより、個別の供給元が1個のアカウントだけに関連付けられ、効率よくクエリを実行できるようになります。
一方、外部キー制約により、`accounts`テーブルの`supplier_id`が`suppliers`テーブルの有効な`supplier`を参照することが保証されます。これにより、関連付けがデータベースレベルで強制されます。

```ruby
create_table :accounts do |t|
  t.belongs_to :supplier, index: { unique: true }, foreign_key: true
  # ...
end
```

このリレーションは、相手側のモデルで`belongs_to`関連付けも設定することで[双方向関連付け](#双方向関連付け)になります。

#### `has_one`で追加されるメソッド

`has_one`関連付けを宣言したクラスでは、さまざまなメソッドが自動的に利用できるようになります。以下はその一部です。

* `association`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`
* `reload_association`
* `reset_association`

本ガイドでは、よく使われるメソッドの一部を取り上げていますが、完全なリストについては[Active Recordの関連付けAPI](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_one)を参照してください。

[`belongs_to`関連付け](#belongs-to関連付け)の場合と同様、上のメソッド名の*`association`*の部分はすべて**プレースホルダ**なので、`has_one`の第1引数として渡されるシンボルで読み替えてください。
たとえば以下のようなモデルが宣言されているとします。

```ruby
# app/models/supplier.rb
class Supplier < ApplicationRecord
  has_one :account
end

# app/models/account.rb
class Account < ApplicationRecord
  validates :terms, presence: true
  belongs_to :supplier
end
```

このとき、`Supplier`モデルのインスタンスで以下のメソッドが使えるようになります。

* `account`
* `account=`
* `build_account`
* `create_account`
* `create_account!`
* `reload_account`
* `reset_account`

NOTE: 新しく作成した`has_one`関連付けまたは`belongs_to`関連付けを初期化するには、`association.build`メソッドではなく、必ず`build_`で始まるメソッドを使わなければなりません（`association.build`は`has_many`関連付けや`has_and_belongs_to_many`関連付けで使います）。関連付けを作成する場合は、`create_`で始まるメソッドをお使いください。

##### 関連付けを取り出す

*`association`*メソッドは、関連付けられたオブジェクトを返します。関連付けられたオブジェクトがない場合は`nil`を返します。

```ruby
@account = @supplier.account
```

関連付けられたオブジェクトがデータベースから既に取得されている場合は、キャッシュされたものを返します。この振る舞いを上書きして、キャッシュを読み出さずにデータベースから強制的に読み込みたい場合は、親オブジェクトが持つ`#reload_association`メソッドを呼び出します。

```ruby
@account = @supplier.reload_account
```

関連付けされたオブジェクトのキャッシュバージョンをアンロードして、次回のアクセスでデータベース呼び出しからクエリするには、親オブジェクトの`#reset_association`を呼び出します。

```ruby
@supplier.reset_account
```

##### 関連付けの割り当て

`association=`メソッドは、関連付けられたオブジェクトをそのオブジェクトに割り当てます。これは、このオブジェクトから主キーを抽出して、関連付けられたオブジェクトの外部キーに同じ値を設定することを意味しています。

```ruby
@supplier.account = @account
```

`build_association`メソッドは、関連付けられた型の新しいオブジェクトを返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが設定されます。関連付けられたオブジェクトは、その時点ではまだ**保存されない**ことにご注意ください。

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

`create_association`メソッドは、上の`build_association`に加えて、関連付けられたモデルで指定されているバリデーションがすべてパスしたときに、そのオブジェクトの保存も行います。

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

最後に、`create_association!`は上の`create_association`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

```ruby
# termsが空なのでActiveRecord::RecordInvalidをraiseする
begin
  @supplier.create_account!(terms: "")
rescue ActiveRecord::RecordInvalid => e
  puts e.message
end
```

```irb
irb> raise_validation_error: Validation failed: Terms can't be blank (ActiveRecord::RecordInvalid)
```

##### 既存の関連付けが存在するかどうかをチェックする

`association.nil?`メソッドを用いて、関連付けられたオブジェクトが存在するかどうかをチェックできます。

```ruby
if @supplier.account.nil?
  @msg = "この本の著者が見つかりません"
end
```

##### オブジェクトが保存されるタイミング

オブジェクトを`has_one`関連付けに割り当てると、そのオブジェクトや関連付けられたオブジェクトが自動的に保存されて外部キーが更新されます。また、置き換えられるオブジェクトも自動的に保存され、その外部キーも更新されます。

保存のいずれかがバリデーションエラーで失敗すると、割り当てステートメントは`false`を返し、割り当て自体がキャンセルされます。

親オブジェクト（`has_one`関連付けを宣言している側のオブジェクト）が保存されていない場合（つまり、`new_record?`が`true`を返す場合）、子オブジェクトはすぐには保存されません。親オブジェクトが保存されると、子オブジェクトは自動的に保存されます。

オブジェクトを保存せずに`has_one`関連付けにオブジェクトを割り当てるには、`build_association`メソッドを使います。このメソッドは、関連付けられたオブジェクトの新しい未保存のインスタンスを作成して、保存するかどうかを決定する前に作業可能にします。

モデルに関連付けられたオブジェクトを保存するかどうかを制御するには、`autosave: false`オプションを使います。この設定により、親オブジェクトが保存されたときに関連付けられたオブジェクトが自動的に保存されなくなります。逆に、保存されていない関連付けられたオブジェクトを操作し、準備ができるまでその永続化を遅延する必要がある場合は、`build_association`メソッドを使います。

### `has_many`関連付け

[`has_many`][]関連付けは、`has_one`と似ていますが、相手のモデルとの「1対多」のつながりを表す点が異なります。`has_many`関連付けは、多くの場合`belongs_to`の反対側で使われます。

`has_many`関連付けは、そのモデルの各インスタンスが、相手のモデルのインスタンスを0個以上持っていることを示します。たとえば、さまざまな著者（`Author`）や書籍（`Book`）を含むアプリケーションでは、`Author`モデルを以下のように宣言できます。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

`has_many`関連付けは、モデル間に1対多のリレーションシップを確立し、宣言したモデル（`Author`）の各インスタンスが、関連付けられたモデル（`Book`）のインスタンスを複数持てるようにします。

NOTE: `has_one`関連付けや`belongs_to`関連付けの場合と異なり、`has_many`関連付けを宣言する場合は、相手のモデル名を「**複数形**」で指定する必要があります。

![has_many関連付けの図](images/association_basics/has_many.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAuthors < ActiveRecord::Migration[8.0]
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

`has_many`関連付けは、他方のモデルと1対多のリレーションシップを作成します。データベースの観点における`has_many`関連付けは、他方のクラスがこのクラスのインスタンスを参照する外部キーを持つことを意味します。

このマイグレーションでは`authors`テーブルが作成され、著者名を保存する`name`カラムがテーブルに含まれます。`books`テーブルも作成され、`belongs_to :author`関連付けが含まれます。

この関連付けにより、`books`テーブルと`authors`テーブルの間に外部キーリレーションシップが確立されます。具体的には、`books`テーブルの`author_id`カラムが、`authors`テーブルの`id`カラムを参照する外部キーとして機能します。この`belongs_to :author`関連付けを`books`テーブルに含めると、`Author`モデルからの`has_many`関連付けが有効になり、個別の書籍が1人の著者に関連付けられます。この設定により、1人の著者が複数の関連する書籍を持てるようになります。

ユースケースにもよりますが、通常はこの`books`テーブルの`author`カラムに「non-unique」インデックスを追加し、オプションで外部キー制約を作成することをオススメします。`author_id`カラムにインデックスを追加すると、特定の著者に関連付けられた書籍を取得するときのクエリパフォーマンスが向上します。

データベースレベルで[参照整合性](https://ja.wikipedia.org/wiki/%E5%8F%82%E7%85%A7%E6%95%B4%E5%90%88%E6%80%A7)を適用する場合は、上記の`reference`カラム宣言に[`foreign_key: true`](active_record_migrations.html#外部キー)オプションを追加します。これにより、`books`テーブルの`author_id`が、`authors`テーブルの有効な`id`に対応づけられるようになります。

```ruby
create_table :books do |t|
  t.belongs_to :author, index: true, foreign_key: true
  # ...
end
```

このリレーションは、相手側のモデルで`belongs_to`関連付けも設定することで[双方向関連付け](#双方向関連付け)にできます。

#### `has_many`関連付けで追加されるメソッド

`has_many`関連付けを宣言したクラスでは、さまざまなメソッドが自動的に利用できるようになります。以下はその一部です。

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

本ガイドでは、よく使われるメソッドの一部を取り上げていますが、完全なリストについては[Active Recordの関連付けAPI](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many)を参照してください。

上のメソッド名の*`collection`*の部分は**プレースホルダ**なので、`has_many`の第1引数として渡されるシンボルで読み替えてください。また、*`collection_singular`*の部分はコレクション名を単数形にして読み替えてください。
たとえば以下の宣言があるとします。

```ruby
class Author < ApplicationRecord
  has_many :books
end
```

これにより、`Author`モデルで以下のメソッドが使えるようになります。

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

[`collection<<`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-3C-3C
[`collection.build`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-build
[`collection.clear`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-clear
[`collection.create`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-create
[`collection.create!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-create-21
[`collection.delete`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-delete
[`collection.destroy`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-destroy
[`collection.empty?`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-empty-3F
[`collection.exists?`]:
    https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-exists-3F
[`collection.find`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-find
[`collection.reload`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-reload
[`collection.size`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html#method-i-size
[`collection.where`]:
    https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where

##### コレクションを管理する

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books
```

[`collection.delete`][]メソッドは、外部キーをNULLに設定することで、コレクションから1個以上のオブジェクトを削除します。

```ruby
@author.books.delete(@book1)
```

WARNING: 削除の方法はこれだけではありません。オブジェクト同士が`dependent: :destroy`で関連付けられている場合は`destroy`で削除されますが、オブジェクト同士が`dependent: :delete_all`で関連付けられている場合は`delete`で削除されるのでご注意ください。

[`collection.destroy`][]メソッドは、コレクションに関連付けられているオブジェクトに対して`destroy`を実行することで、コレクションから1つ以上のオブジェクトを削除します。

```ruby
@author.books.destroy(@book1)
```

WARNING: この場合オブジェクトは**無条件に**データベースから削除されます。このとき`:dependent`オプションはすべて無視されます。

[`collection.clear`][]メソッドは、`dependent`オプションで指定された戦略に応じて、コレクションからすべてのオブジェクトを削除します。オプションが渡されなかった場合は、デフォルトの戦略に従います。デフォルトの戦略は、`has_many :through`関連付けの場合は`delete_all`が指定され、`has_many`関連付けの場合は外部キーがNULLに設定されます。

```ruby
@author.books.clear
```

WARNING: オブジェクトが`dependent: :destroy`または`dependent: :destroy_async`を指定して関連付けされていた場合、それらのオブジェクトは`dependent: :delete_all`の場合と同様に削除されます。

[`collection.reload`][]メソッドは、関連付けられたすべてのオブジェクトのリレーションを1つ返し、データベースを強制的に読み出します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@books = @author.books.reload
```

##### コレクションの割り当て

`collection=(objects)`メソッドは、削除や追加を適宜実行することで、渡したオブジェクトだけがそのコレクションに含まれるようにします。変更の結果はデータベースで永続化されます。

`collection_singular_ids=(ids)`メソッドは、削除や追加を適宜実行することで、指定した主キーのidを持つオブジェクトだけがコレクションに含まれるようにします。変更の結果はデータベースで永続化されます。

##### コレクションにクエリを実行する

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@book_ids = @author.book_ids
```

[`collection.empty?`][]メソッドは、関連付けられたオブジェクトがコレクションに存在しない場合に`true`を返します。

```erb
<% if @author.books.empty? %>
  No Books Found
<% end %>
```

[`collection.size`][]メソッドは、コレクションに含まれるオブジェクトの個数を返します。

```ruby
@book_count = @author.books.size
```

[`collection.find`][]メソッドは、コレクションに含まれるオブジェクトを検索します。

```ruby
@available_book = @author.books.find(1)
```

[`collection.where`][]メソッドは、コレクションに含まれているオブジェクトを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み（lazy load）されるので、オブジェクトに実際にアクセスするときだけデータベースへのクエリが発生します。

```ruby
@available_books = @author.books.where(available: true) # クエリはまだ発生しない
@available_book = @available_books.first # ここでクエリが発生する
```

[`collection.exists?`][]メソッドは、指定された条件に合うオブジェクトがコレクションの中に存在するかどうかをチェックします。

##### 関連付けられるオブジェクトのビルドと作成

[`collection.build`][]メソッドは、関連付けされた型のオブジェクトまたはオブジェクトの配列を返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、外部キーを経由するリンクが作成されます。関連付けられたオブジェクトはまだ**保存されない**ことにご注意ください。

```ruby
@book = @author.books.build(published_at: Time.now,
                            book_number: "A12345")

@books = @author.books.build([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
])
```

[`collection.create`][]メソッドは、関連付けされた型の新しいオブジェクトまたはオブジェクトの配列を返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトの外部キーを介してリンクが作成されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは**保存されます**。

```ruby
@book = @author.books.create(published_at: Time.now,
                             book_number: "A12345")

@books = @author.books.create([
  { published_at: Time.now, book_number: "A12346" },
  { published_at: Time.now, book_number: "A12347" }
])
```

`collection.create!`は上の`collection.create`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

##### オブジェクトが保存されるタイミング

`has_many`関連付けにオブジェクトを割り当てると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトを割り当てると、それらはすべて保存されます。

関連付けられているオブジェクトのどれかがバリデーションエラーで保存に失敗すると、`false`を返し、割り当てはキャンセルされます。

親オブジェクト（`has_many`関連付けを宣言している側のオブジェクト）が保存されない場合（つまり`new_record?`が`true`を返す場合）、子オブジェクトを追加したときに保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバーはすべて保存されます。

`has_many`関連付けにオブジェクトを割り当てて、しかもそのオブジェクトを保存したくない場合は、`collection.build`メソッドをお使いください。

### `has_many :through`関連付け

[`has_many :through`][`has_many`]関連付けは、他方のモデルと「多対多」のリレーションシップを設定する場合によく使われます。この関連付けでは、2つのモデルの間に「第3のモデル」（joinモデル）が介在し、それを**経由**（through）して相手のモデルの「0個以上」のインスタンスとマッチします。

たとえば、患者（patients）が医師（physicians）との診察予約（appointments）を設定する医療業務を考えてみます。この場合、関連付けの宣言は次のような感じになるでしょう。

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

`has_many :through`関連付けは、モデル同士の間に多対多リレーションシップを確立し、一方のモデル（`Physician`）のインスタンスが、第3の「join」モデル（`Appointment`）を経由して、他方のモデル（`Patient`）の複数のインスタンスと関連付けられることを可能にします。

![has_many :through関連付けの図](images/association_basics/has_many_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAppointments < ActiveRecord::Migration[8.0]
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

このマイグレーションでは、`physicians`テーブルと`patients`テーブルが作成され、どちらのテーブルにも`name`カラムがあります。joinテーブルとして機能する`appointments`テーブルは`physician_id`カラムと`patient_id`カラムを持つ形で作成され、`physicians`と`patients`の間に多対多の関係を確立します。

また、以下のように`has_many :through`リレーションシップのjoinテーブルに[複合主キー](active_record_composite_primary_keys.html)を利用することも検討できます。

```ruby
class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    #  ...
    create_table :appointments, primary_key: [:physician_id, :patient_id] do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

`has_many :through`関連付けにあるjoinモデルのコレクションは、標準の[`has_many`関連付けメソッド](#has-many関連付け)経由で管理できます。たとえば、患者のリスト（`patients`）を以下のように医師（`physician`）に割り当てたとします。

```ruby
physician.patients = patients
```

Railsは自動的に、以前はその医師に関連付けられていなかった患者たちが新しいリスト内に含まれていれば、新しいjoinモデルを作成します。さらに、以前はその医師に関連付けられていた患者が新しいリストに含まれていなければ、そのjoinレコードは自動的に削除されます。
このようにしてjoinモデルの作成と削除が処理されるため、多対多リレーションシップの管理がシンプルになります。

WARNING: joinモデルの自動削除は即座に行われ、`destroy`コールバックは発生しないので注意が必要です。詳しくは[Active Recordコールバックガイド](active_record_callbacks.html)を参照してください。

`has_many :through`関連付けは、ネストした`has_many`関連付けを介して「ショートカット」を設定する場合にも便利です。このショートカットは、関連するレコードのコレクションに、中間の関連付けを介してアクセスする必要がある場合に特に有用です。

たとえば、あるドキュメントに多くの節（section）があり、1つの節の下に多くの段落（paragraph）がある状態で、個別の節をたどらずに、ドキュメントにあるすべての段落のコレクションだけが欲しいとします。

これは、以下のように`has_many :through`関連付けで設定できます。

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

`through: :sections`を指定することで、Railsは以下の文を理解できるようになります。

```ruby
@document.paragraphs
```

`has_many :through`関連付けを設定しないと、ドキュメント内の段落を取得するために以下のような煩雑な操作が必要になります。

```ruby
paragraphs = []
@document.sections.each do |section|
  paragraphs.concat(section.paragraphs)
end
```

### `has_one :through`関連付け

[`has_one :through`][`has_one`]関連付けは、他方のモデルに対して「1対1」のリレーションシップを設定します。この関連付けは、2つのモデルの間に「第3のモデル」（joinモデル）が介在し、それを**経由**（through）して相手モデルの1個のインスタンスとマッチします。

たとえば、個別の供給元（supplier）が1個のアカウント（account）を持ち、さらに1個のアカウントが1個のアカウント履歴に関連付けられる場合、`Supplier`モデルは以下のような感じになります。

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

上のセットアップによって、`supplier`は`account`を経由して直接`account_history`にアクセス可能になります。

![has_one :through関連付けの図](images/association_basics/has_one_through.png)

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAccountHistories < ActiveRecord::Migration[8.0]
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

[`has_and_belongs_to_many`][]関連付けは、他方のモデルと「多対多」のリレーションシップを作成しますが、`through:`を指定した場合と異なり、第3のモデル（joinモデル）が**介在しません**。この関連付けは、それを宣言しているモデルの各インスタンスが、他方のモデルのインスタンスを0個以上参照することを示します。

たとえば、`Assembly`（完成品）モデルと`Part`（部品）モデルを持つアプリケーションを考えてみましょう。個別の完成品には多数の部品が含まれ、個別の部品は多くの完成品で利用できます。このモデルは次のようにセットアップできます。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many関連付けの図](images/association_basics/habtm.png)

`has_and_belongs_to_many`は介在モデルが不要ですが、関係する2つのモデル間の多対多リレーションシップを確立するためのテーブルは別途必要です。この介在テーブルは、2つのモデルのインスタンス間の関連付けをマッピングし、関連するデータを保存する役割があります。この介在テーブルは、関連するレコード間のリレーションシップを管理することだけが目的なので、テーブルには必ずしも主キーは必要ありません。

上の関連付けに対応するマイグレーションは以下のような感じになります。

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration[8.0]
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    # `assemblies`テーブルと`parts`テーブル間の多対多リレーションシップを
    # 確立するためのjoinテーブルを作成する
    # `id: false`は、このテーブルには主キーが不要であることを指定する
    create_table :assemblies_parts, id: false do |t|
      # joinテーブルを`assemblies`テーブルと`parts`テーブルに
      # リンクする外部キーを追加する
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

`has_and_belongs_to_many`関連付けは、他方のモデルとの多対多の関係を作成します。データベースの観点では、これは各クラスを参照する外部キーを含む中間のjoinテーブルを介して、2つのクラスを関連付けることを指します。

`has_and_belongs_to_many`関連付けのjoinテーブルに2つの外部キー以外のカラムが存在すると、これらのカラムはその関連付けを介して取得されるレコードに「属性」として追加されます。追加の属性とともに返されるレコードは、常に読み取り専用になります（Railsはこのような属性への変更を保存できません）。

WARNING: `has_and_belongs_to_many`関連付けのjoinテーブルにこのような属性を追加して利用することは非推奨です。多対多リレーションシップで2つのモデルを結合するテーブルでこのような複雑な振る舞いを必要とする場合は、`has_and_belongs_to_many`関連付けではなく`has_many :through`関連付けを使うべきです。

#### `has_and_belongs_to_many`で追加されるメソッド

`has_and_belongs_to_many`関連付けを宣言したクラスでは、さまざまなメソッドが自動的に利用できるようになります。以下はその一部です。

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

本ガイドでは、よく使われるメソッドの一部を取り上げていますが、完全なリストについては[Active Recordの関連付けAPI](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_and_belongs_to_many)を参照してください。

上のメソッド名の*`collection`*の部分は**プレースホルダ**なので、`has_and_belongs_to_many`の第1引数として渡されるシンボルで読み替えてください。
また、*`collection_singular`*の部分はコレクション名を単数形にして読み替えてください。
たとえば以下の宣言があるとします。

```ruby
class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

これにより、`Part`モデルで以下のメソッドが使えるようになります。

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

##### コレクションを管理する

`collection`メソッドは、関連付けられたすべてのオブジェクトのリレーションを返します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@assemblies = @part.assemblies
```

[`collection<<`][]メソッドは、joinテーブル上でレコードを作成し、それによって1個以上のオブジェクトをコレクションに追加します。

```ruby
@part.assemblies << @assembly1
```

NOTE: このメソッドは`collection.concat`と`collection.push`のエイリアスです。

[`collection.delete`][]メソッドは、joinテーブル内のレコードを削除する形で、コレクションから1個以上のオブジェクトを取り除きます。オブジェクトはdestroyされません。

```ruby
@part.assemblies.delete(@assembly1)
```

[`collection.destroy`][]メソッドは、joinテーブル内のレコードを削除する形で、コレクションから1個以上のオブジェクトを取り除きます。オブジェクトはdestroyされません。

```ruby
@part.assemblies.destroy(@assembly1)
```

[`collection.clear`][]メソッドは、joinテーブル上のレコードを削除する形で、すべてのオブジェクトをコレクションから取り除きます。オブジェクトはdestroyされません。

##### コレクションの割り当て

`collection=`メソッドは、削除や追加を適宜実行することで、渡したオブジェクトだけがそのコレクションに含まれるようにします。変更の結果はデータベースで永続化されます。

`collection_singular_ids`メソッドは、削除や追加を適宜実行することで、指定した主キーの値を持つオブジェクトだけがコレクションに含まれるようにします。変更の結果はデータベースで永続化されます。

##### コレクションにクエリを実行する

`collection_singular_ids`メソッドは、そのコレクションに含まれるオブジェクトのidを配列にしたものを返します。

```ruby
@assembly_ids = @part.assembly_ids
```

[`collection.empty?`][]メソッドは、関連付けられたオブジェクトがコレクションに存在しない場合に`true`を返します。

```html+erb
<% if @part.assemblies.empty? %>
  この部品はどの完成品にも使われていません
<% end %>
```

[`collection.size`][]メソッドは、コレクションに含まれるオブジェクトの個数を返します。

```ruby
@assembly_count = @part.assemblies.size
```

[`collection.find`][]メソッドは、コレクションに含まれるオブジェクトを検索します。

```ruby
@assembly = @part.assemblies.find(1)
```

[`collection.where`][]メソッドは、コレクションに含まれているオブジェクトを指定された条件に基いて検索します。このメソッドではオブジェクトは遅延読み込み（lazy load）されるので、オブジェクトに実際にアクセスするときだけデータベースへのクエリが発生します。

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

[`collection.exists?`][]メソッドは、指定された条件に合うオブジェクトがコレクションのテーブル内に存在するかどうかをチェックします。

##### 関連付けられるオブジェクトのビルドと作成

[`collection.build`][]メソッドは、関連付けされた型のオブジェクトまたはオブジェクトの配列を返します。返されるオブジェクトは、渡された属性に基いてインスタンス化され、joinテーブルを経由するリンクが作成されます。関連付けられたオブジェクトはまだ**保存されない**ことにご注意ください。

```ruby
@assembly = @part.assemblies.build({ assembly_name: "Transmission housing" })
```

[`collection.create`][]メソッドは、関連付けされた型の新しいオブジェクトを返します。このオブジェクトは、渡された属性を用いてインスタンス化され、そのオブジェクトのjoinテーブルを介してリンクが作成されます。そして、関連付けられたモデルで指定されているバリデーションがすべてパスすると、この関連付けられたオブジェクトは**保存されます**。

```ruby
@assembly = @part.assemblies.create({ assembly_name: "Transmission housing" })
```

`collection.create!`は上の`collection.create`と同じですが、レコードが無効な場合に`ActiveRecord::RecordInvalid`がraiseされる点が異なります。

[`collection.reload`][]メソッドは、関連付けられたすべてのオブジェクトのリレーションを1つ返し、データベースを強制的に読み出します。関連付けられたオブジェクトがない場合は、空のリレーションを1つ返します。

```ruby
@assemblies = @part.assemblies.reload
```

##### オブジェクトが保存されるタイミング

`has_and_belongs_to_many`関連付けにオブジェクトを割り当てると、外部キーを更新するためにそのオブジェクトは自動的に保存されます。1つの文で複数のオブジェクトを割り当てると、それらはすべて保存されます。

関連付けられているオブジェクトのどれかがバリデーションエラーで保存に失敗すると、`false`を返し、割り当てはキャンセルされます。

親オブジェクト（`has_and_belongs_to_many`関連付けを宣言している側のオブジェクト）が保存されない場合（つまり`new_record?`が`true`を返す場合）、子オブジェクトを追加したときに保存されません。親オブジェクトが保存されると、関連付けられていたオブジェクトのうち保存されていなかったメンバーはすべて保存されます。

`has_and_belongs_to_many`関連付けにオブジェクトを割り当てて、しかもそのオブジェクトを`save`したくない場合、`collection.build`メソッドをお使いください。

関連付けの選び方
-----------------------

### `belongs_to`と`has_one`のどちらを選ぶか

2つのモデルの間に1対1のリレーションシップを設定したい場合は、一方のモデルに`belongs_to`関連付けを追加し、他方のモデルに`has_one`関連付けを追加できます。どちらの関連付けをどちらのモデルに置けばよいでしょうか。

区別の決め手となるのは、外部キー（foreign key）をどちらのモデルに置くかです（外部キーは、`belongs_to`関連付けを追加したモデルのテーブルに追加します）が、適切な関連付けを決めるためには、もう少しデータの実際の意味についても考えてみる必要があります。

- `belongs_to`: この関連付けは、それを宣言する現在のモデルに外部キーが含まれていることと、現在のモデルがリレーションシップにおける「子」であることを意味します。この関連付けで他方のモデルを参照すると、このモデルの各インスタンスが、他方のモデルの「1個の」インスタンスに紐づけられることを示します。

- `has_one`: この関連付けは、それを宣言する現在のモデルがリレーションシップにおける「親」であることと、他方のモデルのインスタンスを「1個」所有していることを意味します。

たとえば、供給元（suppliers）とそのアカウント（accounts）があるシナリオを考えてみましょう。アカウントが供給元を持っている/所有していると考えるよりも、供給元がアカウントを持っている/所有している（供給元が親になる）と考える方が自然です。したがって、正しい関連付けは次のようになります。

- 1つの供給元が、1個のアカウントを所有する（has one）。
- 1個のアカウントは、1つの供給元に属する（belongs to）。

Railsでは、これらの関連付けを以下のように定義できます。

```ruby
class Supplier < ApplicationRecord
  has_one :account
end

class Account < ApplicationRecord
  belongs_to :supplier
end
```

これらの関連付けを実装するには、対応するデータベーステーブルを作成して、外部キーを設定する必要があります。
マイグレーションの例は以下のような感じになります。

```ruby
class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier_id
      t.string :account_number
      t.timestamps
    end

    add_index :accounts, :supplier_id
  end
end
```

「外部キーは、`belongs_to`関連付けを宣言しているクラスのテーブルに配置する」と覚えておきましょう。この場合は、`account`テーブルの方に外部キーを配置します。

### `has_many :through`と`has_and_belongs_to_many`のどちらを選ぶか

Railsでは、モデル間の多対多リレーションシップを宣言するのに`has_many :through`関連付けと`has_and_belongs_to_many`関連付けという2とおりの方法が利用できます。2つの方法の違いとユースケースを理解することで、アプリケーションのニーズに最適な方法を決められるようになります。

`has_many :through`関連付けは、中間モデル（joinモデル）を介して多対多リレーションシップを設定します。
このアプローチは柔軟性が高く、joinモデルに「バリデーション」「コールバック」「追加の属性」も追加できます。joinテーブルには`primary_key`([複合主キー](active_record_composite_primary_keys.html))が必ず必要です。

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

以下に該当する場合は、`has_many :through`関連付けを使います。

- joinテーブルに追加の属性やメソッドを追加する必要がある場合。
- joinモデルで[バリデーション](active_record_validations.html)や[コールバック](active_record_callbacks.html)が必要な場合。
- joinテーブルを、独自に振る舞う「独立したエンティティ」として扱う必要がある場合

もうひとつの`has_and_belongs_to_many`関連付けは、中間モデルを必要とせずに、2つのモデル間に多対多リレーションシップを直接作成できます。
この方法は手軽で、joinテーブルに属性や振る舞いを追加する必要がないシンプルな関連付けに適しています。その代わり、`has_and_belongs_to_many`関連付けで作成するjoinテーブルには、主キーを含めないようにする必要があります。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

以下に該当する場合は、`has_and_belongs_to_many`関連付けを使います。

- 関連付けがシンプルで、joinテーブルに属性や振る舞いを追加する必要がない場合。
- joinテーブルで「バリデーション」「コールバック」「追加メソッド」が必要ない場合。

高度な関連付け
-------------------------

### ポリモーフィック関連付け

**ポリモーフィック関連付け**（polymorphic association）は、関連付けのやや高度な応用です。Railsのポリモーフィック関連付けを使うと、ある1つのモデルが他の複数のモデルに属していることを、1つの関連付けだけで表現できます。ポリモーフィック関連付けは、あるモデルを種類の異なる複数のモデルに紐づける必要がある場合に特に便利です。

たとえば、`Picture`（写真）モデルがあり、このモデルを`Employee`（従業員）モデルと`Product`（製品）モデルの両方に従属させたいとします。この場合は以下のように宣言します。

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

![ポリモーフィック関連付けの図](images/association_basics/polymorphic.png)

上の`imageable`は、関連付けを表すために選んだ名前です。これは、`Picture`モデルと、`Employee`や`Product`などの他のモデルとの間のポリモーフィック関連付けを表すシンボル名です。
ここで重要な点は、ポリモーフィック関連付けを正しく確立するためには、関連付けられるすべてのモデルで必ず同じ名前（`imageable`）に統一することです。

`Picture`モデルで`belongs_to :imageable, polymorphic: true`を宣言すると、「`Picture`はこの関連付けを通じて任意のモデル（`Employee`や`Product`など）に属することが可能である」と宣言したことになります。

ポリモーフィックな`belongs_to`宣言は、他の任意のモデルでも利用できるインターフェイスを設定するものとみなせます。これにより、たとえば`@employee.pictures`と書くだけで、`Employee`モデルのインスタンスから写真のコレクションを取得できます。同様に、`@product.pictures`と書くだけで、`Product`モデルのインスタンスから写真のコレクションを取得できます。

さらに、`Picture`モデルのインスタンスがある場合は、`@picture.imageable`を経由してその親モデル（`Employee`または`Product`）を取得できます。

ポリモーフィック関連付けを手動でセットアップする場合は、以下のようにモデルで外部キーカラム（`imageable_id`）とtypeカラム（`imageable_type`）の両方を宣言する必要があります。

```ruby
class CreatePictures < ActiveRecord::Migration[8.0]
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

上の例では、`imageable_id`は`Employee`や`Product`のIDであり、`imageable_type`は関連付けられるモデルのクラス名（つまり`Employee`や`Product`）になります。

ポリモーフィック関連付けを手動で作成することも一応可能ですが、それよりも以下のように`t.references`（またはそのエイリアス`t.belong_to`）を用いて`polymorphic: true`を指定する方がオススメです。これにより、関連付けがポリモーフィックであることがRailsに認識され、外部キーとtypeカラムが両方ともテーブルに自動的に追加されます。

```ruby
class CreatePictures < ActiveRecord::Migration[8.0]
  def change
    create_table :pictures do |t|
      t.string :name
      t.belongs_to :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

WARNING: ポリモーフィック関連付けは、クラス名がデータベースに保存されることに依存しているため、保存されているクラス名がRubyコードで使われるクラス名とずれないよう、常に同期させる必要があります。クラス名を変更する場合は、ポリモーフィックのtypeカラムのデータも必ず更新してください。<br><br>たとえば、クラス名を`Product`から`Item`に変更する場合は、マイグレーションスクリプトを実行して`pictures`テーブル（または影響を受けるテーブル）の`imageable_type`カラムの値を新しいクラス名で更新する必要があります。さらに、変更を反映するために、アプリケーションコード全体でもその他のクラス名への参照を更新する必要があります。

### 複合主キーを持つモデルの関連付け

Railsは多くの場合、関連付けられるモデル間の主キーと外部キーのリレーションシップを推測できますが、複合主キーを扱う場合、明示的に指示されない限り、複合キーの一部のみ（多くの場合idカラム）がデフォルトで利用されます。

Railsモデルで複合主キーを利用していて、関連付けを適切に処理する必要がある場合は、複合主キーガイドの[複合主キーを持つモデルの関連付け](active_record_composite_primary_keys.html#複合主キーを持つモデルの関連付け)セクションを参照してください。このセクションでは、必要に応じて複合外部キーを指定する方法など、Railsで複合主キーとの関連付けを設定・利用する方法について包括的なガイダンスを提供します。

### self-join

self-joining（自己結合）は通常のjoinですが、テーブルがそれ自身とjoinされます。これは、1個のテーブル内に階層関係がある場合に便利です。一般的な例としては、従業員管理システムがあります。従業員（employee）にはマネージャ（manager）がいて、そのマネージャも従業員の1人です。

ある従業員が他の従業員のマネージャーになる可能性がある組織を考えてみましょう。単一の`employees`テーブルで、このリレーションを追跡できるようにしたいします。

Railsモデルで、このリレーションシップを反映する`Employee`クラスを定義します。

```ruby
class Employee < ApplicationRecord
  # 1人の従業員が複数の部下を持つ可能性がある
  has_many :subordinates, class_name: "Employee", foreign_key: "manager_id"

  # 1人の従業員のマネージャは1人だけ
  belongs_to :manager, class_name: "Employee", optional: true
end
```

`has_many :subordinates`関連付けは、1人の従業員が複数の部下を持つ1対多リレーションシップを設定します。このとき、関連するモデルに`Employee`（`class_name: "Employee"`）を指定し、マネージャを特定するための外部キーに`manager_id`を指定します。

`belongs_to :manager`関連付けは、1人の従業員が1人のマネージャを持つ1対1リレーションシップを設定します。こちらにも`Employee`モデルを指定します。

このリレーションシップをサポートするには、以下のようなマイグレーションで`employees`テーブルに`manager_id`カラムを追加する必要があります。このカラムは、別の従業員（マネージャ）の`id`を参照します。

```ruby
class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      # belongs_to参照をマネージャに追加する（従業員でもある）
      t.belongs_to :manager, foreign_key: { to_table: :employees }
      t.timestamps
    end
  end
end
```

- `t.belongs_to :manager`は、`employees`テーブルに`manager_id`カラムを追加します。
- `foreign_key: { to_table: :employees }`は、`manager_id`カラムが、`employees`テーブルの`id`カラムを参照するようにします。

NOTE: `foreign_key`に渡している`to_table`オプションなどについては、APIドキュメント[`SchemaStatements#add_reference`][connection.add_reference]に解説があります。

このセットアップにより、Railsアプリケーションで従業員の部下やマネージャーに手軽にアクセスできます。

ある従業員の部下を取得するには、以下のようにします。

```ruby
employee = Employee.find(1)
subordinates = employee.subordinates
```

ある従業員のマネージャを取得するには、以下のようにします。

```ruby
manager = employee.manager
```

[connection.add_reference]:
    https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference

単一テーブル継承（STI）
------------------------

単一テーブル継承（STI: Single Table Inheritance）は、複数のモデルを単一のデータベーステーブルに収納できるRailsのパターンです。これは、さまざまなエンティティに共通の属性や振る舞いを持たせつつ、エンティティ固有の振る舞いも持たせたい場合に便利です。

たとえば、`Car`、`Motorcycle`、`Bicycle`というモデルがあるとします。これらのモデルは`color`や`price`などのフィールドを共有しますが、モデルごとに固有の振る舞いもあるとします。さらに、モデルごとに独自のコントローラーもあるとします。

### ベースとなるVehicleモデルを生成する

最初に、共有フィールドを持つ`Vehicle`モデルを生成します。

```bash
$ bin/rails generate model vehicle type:string color:string price:decimal{10.2}
```

STIで重要なのは、この`type`フィールドです（ここに`Car`、`Motorcycle`、`Bicycle`などのモデル名が保存されます）。STIでは、同じテーブルに保存されるさまざまなモデルを区別するために、このフィールドが不可欠です。

### 子モデルを生成する

次に、`Vehicle`を継承する`Car`、`Motorcycle`、`Bicycle`モデルをそれぞれ生成します。これらのモデルは独自のテーブルを持たない代わりに、`vehicles`テーブルを利用します。

たとえば`Car`モデルは以下のように生成します。

```bash
$ bin/rails generate model car --parent=Vehicle
```

ここで`--parent=親モデル`オプションを使うことで、指定した親モデルを継承できます。また、テーブルは既に存在しているので、マイグレーションファイルは生成されません。

`Vehicle`を継承した`Car`モデルは次のようになります。

```ruby
class Car < Vehicle
end
```

これで、`Vehicle`モデルに追加されたすべての振る舞いが、`Car`モデルにも追加されるようになります。関連付けやpublicメソッドなども同様に追加されます。
この状態で新しく作成した`Car`を保存すると、`type`フィールドに"Car"を割り当てたデータが`vehicles`テーブルに追加されます。

`Motorcycle`モデルと`Bicycle`モデルについても、`Car`モデルと同様の作業を繰り返します。

### レコードを作成する

以下を実行して`Car`モデルのレコードを作成します。

```ruby
Car.create(color: "Red", price: 10000)
```

実際に生成されるSQLは次のようになります。

```sql
INSERT INTO "vehicles" ("type", "color", "price") VALUES ('Car', 'Red', 10000)
```

### レコードのクエリを送信する

`Car`のレコードを取得するクエリを送信すると、`vehicles`テーブル内の`Car`に該当するレコードだけが検索されます。

```ruby
Car.all
```

実際のクエリは次のようになります。

```sql
SELECT "vehicles".* FROM "vehicles" WHERE "vehicles"."type" IN ('Car')
```

### モデルに固有の振る舞いを追加する

STIでは、子モデルに特定の振る舞いやメソッドを追加できます。たとえば、`Car`モデルにメソッドを追加するには以下のように書きます。

```ruby
class Car < Vehicle
  def honk
    "Beep Beep"
  end
end
```

これで、`Car`モデルのインスタンスでのみ`honk`メソッドを呼び出せるようになります。

```ruby
car = Car.first
car.honk
# => 'Beep Beep'
```

### コントローラーを追加する

STIの子モデルには、独自のコントローラも追加できます。たとえば以下の`CarsController`を追加できます。

```ruby
# app/controllers/cars_controller.rb

class CarsController < ApplicationController
  def index
    @cars = Car.all
  end
end
```

### 継承カラムをオーバーライドする

レガシーデータベースで作業する場合などで、継承カラム名をオーバーライドする必要が生じることがあります。これは、[`inheritance_column`][]メソッドで実現できます。

```ruby
# スキーマ: vehicles[ id, kind, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = "kind"
end

class Car < Vehicle
end

Car.create
# => #<Car kind: "Car", color: "Red", price: 10000>
```

このセットアップにすると、モデルのtype（モデル名）を`kind`カラムに保存するように変更され、STIがカスタムカラム名で正しく機能できるようになります。

### 継承カラムを無効にする

レガシーデータベースで作業する場合などで、単一テーブル継承（STI）を完全に無効にする必要が生じることがあります（そうしないと[`ActiveRecord::SubclassNotFound`][]が発生する）。

[`inheritance_column`][]を`nil`に設定することで、STIを無効にできます。

```ruby
# スキーマ: vehicles[ id, type, created_at, updated_at ]
class Vehicle < ApplicationRecord
  self.inheritance_column = nil
end

Vehicle.create!(type: "Car")
# => #<Vehicle type: "Car", color: "Red", price: 10000>
```

このセットアップにすると、`type`カラムが通常の属性として扱われるように変更され、STIで使われないようになります。これは、STIパターンに従っていないレガシースキーマで作業しなければならない場合に便利です。

これらの調整機能によって、Railsを既存のデータベースと統合する場合や、モデルに特定のカスタマイズが必要な場合に、柔軟な対応が可能になります。

[`inheritance_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-c-inheritance_column
[`ActiveRecord::SubclassNotFound`]:
    https://api.rubyonrails.org/classes/ActiveRecord/SubclassNotFound.html

### STIで考慮すべき点

[単一テーブル継承（STI）](#単一テーブル継承（sti）)は、サブクラス同士（およびその属性）にほとんど違いがない場合に最適ですが、すべてのサブクラスのすべての属性が1個のテーブルに収納されることになります。

この方法の欠点は、サブクラス固有の属性を（他のサブクラスで使われていない属性であっても）1個のテーブルに含めるため、テーブルが肥大化する可能性があることです。これについては、後述の[Delegated Types](#delegated-types)で解決できることがあります。

さらに、[ポリモーフィック関連付け](#ポリモーフィック関連付け)を使っている場合は、1個のモデルがtypeとIDを介して他の複数のモデルに属している可能性があるため、関連付けロジックがさまざまなモデルtypeを正しく処理するための参照整合性を維持する処理が複雑になる可能性があります。

最後に、データ整合性チェックやバリデーションがサブクラスごとに異なる場合は、特に外部キー制約を設定するときに、Railsやデータベースでデータ整合性チェックやバリデーションが正しく処理されるようにしておく必要があります。

Delegated Types
----------------

Delegated types（委譲型）は、[単一テーブル継承（STI）](#単一テーブル継承（sti）)によるテーブル肥大化の問題を、`delegated_type`で解決します。このアプローチにより、共有属性をスーパークラスのテーブルに保存し、サブクラス固有の属性を別のテーブルに保存できるようになります。

### Delegated Typesをセットアップする

Delegated typesを使うためには、データを以下のようにモデリングする必要があります。

- すべてのサブクラス間で共有する属性をそのテーブルに格納するためのスーパークラスが1個存在すること。
- 個別のサブクラスは必ずそのスーパークラスを継承し、サブクラス固有の追加属性については別途テーブルを用意すること。

これにより、単一のテーブルで、すべてのサブクラス間で不必要に共有される属性を定義する必要がなくなります。

### モデルを生成する

上記の例にDelegated typesを適用するには、モデルを再生成する必要があります。

まず、スーパークラスとして機能するベース`Entry`モデルを生成しましょう。

```bash
$ bin/rails generate model entry entryable_type:string entryable_id:integer
```

次に、委譲で使う`Message`モデルと`Comment`モデルを新しく生成します。

```bash
$ bin/rails generate model message subject:string body:string
$ bin/rails generate model comment content:string
```

ジェネレータ実行後のモデルは以下のようになります。

```ruby
# スキーマ: entries[ id, entryable_type, entryable_id, created_at, updated_at ]
class Entry < ApplicationRecord
end

# スキーマ: messages[ id, subject, body, created_at, updated_at ]
class Message < ApplicationRecord
end

# スキーマ: comments[ id, content, created_at, updated_at ]
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

この`entryable`パラメータは、委譲で使うフィールドを指定し、委譲クラスとして`Message`型と`Comment`型を含みます。`entryable_type`には委譲サブクラス名が保存され、`entryable_id`には委譲サブクラスのレコードIDが保存されます。

### `Entryable`モジュールを定義する

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

定義が完了すると、`Entry`デリゲーターは以下のメソッドを提供するようになります。

| メソッド | 戻り値 |
|---|---|
| `Entry.entryable_types` | `["Message", "Comment"]` |
| `Entry#entryable_class` | MessageまたはComment |
| `Entry#entryable_name` | "message"または"comment" |
| `Entry.messages` | `Entry.where(entryable_type: "Message")` |
| `Entry#message?` | `entryable_type == "Message"`の場合trueを返す |
| `Entry#message` | `entryable_type == "Message"`の場合はメッセージレコードを返し、それ以外の場合は`nil`を返す|
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

`Entry`デリゲータを拡張して`delegates`を定義し、サブクラスに対してポリモーフィズムを使うことで、さらに拡張できます。

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

このセットアップによって、`Entry`は`title`メソッドをサブクラスに委譲できるようになります。`Message`モデルは`subject`メソッドを利用し、`Comment`モデルは`content`メソッドの結果を`truncate`したものを利用できるようになります。

ヒントと注意事項
--------------------------

RailsアプリケーションでActive Recordの関連付けを効果的に使うためには、以下について知っておく必要があります。

* 関連付けのキャッシュを制御する
* 名前衝突の回避
* スキーマの更新
* 関連付けのスコープ制御
* 双方向関連付け

### 関連付けのキャッシュを制御する

すべての関連付けメソッドは、キャッシュを中心に構築されています。最後に実行したクエリの結果はキャッシュに保持され、次回以降の操作で利用されます。このキャッシュは、以下のようにメソッド間でも共有される点にご注意ください。

```ruby
# データベースからbooksを取得する
author.books.load

# booksのキャッシュコピーが使われる
author.books.size

# booksのキャッシュコピーが使われる
author.books.empty?
```

NOTE: この`author.books`を実行しても、それだけではデータベースからすぐにデータを読み込みません。代わりに、実際にデータを使おうとしたとき（例: `each`、`size`、`empty?`などの「データを必要とするメソッド」を呼び出したとき）に実行されるクエリを単にセットアップします。<br><br>データを利用する他のメソッドを呼び出す前に`author.books.load`メソッドを呼び出すと、データベースからデータを読み込むクエリがその場で明示的にトリガーされます。このテクニックは、データが必要であることが事前にわかっていて、関連付けを操作するときにクエリが何度もトリガーされることによるパフォーマンス上の潜在的なオーバーヘッドを回避したい場合に便利です。

しかし、アプリケーションの他の部分によってデータが変更されている可能性があるため、キャッシュを再読み込みしたい場合は、その関連付けで[`reload`](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-reload)メソッドを呼び出すだけで再読み込みできます。

```ruby
# データベースからbooksを取得する
author.books.load

# booksのキャッシュコピーが使われる
author.books.size

# booksのキャッシュコピーが破棄され、その後データベースから再度読み込まれる
author.books.reload.empty?
```

### 名前衝突の回避

Ruby on Railsのモデルで関連付けを作成する場合、`ActiveRecord::Base`のインスタンスメソッドで既に使われている名前を関連付け名で使わないようにすることが重要です。既存のメソッドと競合する名前で関連付けを作成すると、ベースメソッドがオーバーライドされて機能に問題が発生するなど、意図しない結果につながる可能性があります。たとえば、関連付け名に`attributes`や`connection`などを使うと問題が発生します。

### スキーマの更新

関連付けは非常に便利です。関連付けは、モデル間のリレーションシップを定義する役割を担いますが、データベーススキーマの更新は行いません。つまり、関連付けとデータベーススキーマを常に一致させる責任はアプリケーション開発者にあります。そのために、主に以下の2つのタスクについては手作業が必要です。

1. [`belongs_to`関連付け](#belongs-to関連付け)を使う場合は、外部キーを作成する必要があります。
2. [`has_and_belongs_to_many`関連付け](#has-and-belongs-to-many関連付け)を使う場合は、適切なjoinテーブルを作成する必要があります。

`has_many :through`と`has_and_belongs_to_many`の使い分けについて詳しくは、[`has_many :through`と`has_and_belongs_to_many`のどちらを選ぶか](#has-many-throughとhas-and-belongs-to-manyのどちらを選ぶか)を参照してください。

#### `belongs_to`関連付けに対応する外部キーを作成する

[`belongs_to`関連付け](#belongs-to関連付け)関連付けを宣言するときは、対応する外部キーも作成する必要があります。以下のモデルを例にとります。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end
```

上の宣言は、以下の`books`テーブルの対応する外部キーカラムと整合していなければなりません。テーブルを作成した直後のマイグレーションは、以下のような感じになります。

```ruby
class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.datetime   :published_at
      t.string     :book_number
      t.references :author
    end
  end
end
```

一方、既存のテーブルに外部キーを設定するときのマイグレーションは、以下のような感じになります。

```ruby
class AddAuthorToBooks < ActiveRecord::Migration[8.0]
  def change
    add_reference :books, :author
  end
end
```

#### `has_and_belongs_to_many`関連付けに対応するjoinテーブルを作成する

`has_and_belongs_to_many`関連付けを作成した場合は、それに対応するjoinテーブルも明示的に作成する必要があります。joinテーブルの名前が`:join_table`オプションで明示的に指定されていない場合、Active Recordは2つのクラス名をABC順に結合して、joinテーブル名を作成します。
たとえば`Author`モデルと`Book`モデルを結合する場合、'a'は辞書の並び順で'b'より先に出現するので、"authors_books"というデフォルトのjoinテーブル名が使われます。

どのような名前であっても、適切なマイグレーションを実行してjoinテーブルを手動で生成する必要があります。以下の関連付けを例にとって考えてみましょう。

```ruby
class Assembly < ApplicationRecord
  has_and_belongs_to_many :parts
end

class Part < ApplicationRecord
  has_and_belongs_to_many :assemblies
end
```

この関連付けに正しく対応する`assemblies_parts`テーブルは、以下のようなマイグレーションで作成する必要があります。

```bash
$ bin/rails generate migration CreateAssembliesPartsJoinTable assemblies parts
```

生成されたマイグレーションファイルを以下のように編集します。このとき、テーブルに主キーを設定してはいけません。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[8.0]
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

このjoinテーブルはモデルを表すためのものではないので、`create_table`に`id: false`オプションを指定します。
モデルのIDが破損する、IDの競合で例外が発生するなど、`has_and_belongs_to_many`関連付けの動作が怪しい場合は、マイグレーション作成時に`id: false`オプションの設定を忘れていないかどうか再度確認してみてください。

なお、以下のように`create_join_table`メソッドを使えば、同じことをもっとシンプルに書けます。

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :assemblies, :parts do |t|
      t.index :assembly_id
      t.index :part_id
    end
  end
end
```

`create_join_table`メソッドについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html#joinテーブルを作成する)ガイドを参照してください。

#### `has_many :through`に対応するjoinテーブルを作成する

`has_many :through`関連付けと`has_and_belongs_to_many`関連付けでjoinテーブルを作成する場合の、スキーマ実装方法の主な違いは、`has_many :through`のjoinテーブルには`id`が必須であることです。

```ruby
class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

### 関連付けのスコープを制御する

関連付けは、デフォルトでは現在のモジュールのスコープ内にあるオブジェクトだけを探索します。この機能は、特に以下のようにモジュール内でActive Recordモデルを宣言するときに、関連付けのスコープが適切に維持される点が有用です。

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

上の例では、`Supplier`クラスと`Account`クラスがどちらも同じモジュール（`MyApplication::Business`）内で定義されています。
このようにコードを編成すれば、すべての関連付けにスコープを明示的に追加しなくても、以下のようにモデルをスコープに基づいてフォルダで構造化できます。

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

モデルのスコープ設定はコードを整理するときに便利ですが、モデルのスコープ設定はデータベースのテーブル名の命名規則を**変更しない**ことに注意が必要です。
たとえば、`MyApplication::Business::Supplier`というモデルがある場合は、データベーステーブル名も命名規則に沿った`my_application_business_suppliers`にしなければなりません。

ただし、以下のように`Supplier`と`Account`モデルが異なるスコープで定義されている場合、この関連付けはデフォルトでは機能しません。

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

あるモデルを別の名前空間にあるモデルと関連付けるには、関連付けの宣言で以下のように`class_name`で完全なクラス名を指定する必要があります。

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

`class_name`オプションを明示的に宣言することで、名前空間が異なるモデル間で関連付けを作成し、モジュールのスコープに関係なく正しいモデルがリンクされるようになります。

### 双方向関連付け

Railsでは、モデル間の関連付けを双方向（bi-directional）に設定するのが一般的です。つまり、関連付けは2つのモデルの両方で宣言する必要があります。以下の例を考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :author
end
```

Active Recordは、関連付け名に基づいて、2つのモデルが双方向の関連を共有していることを自動的に認識しようとします。この情報によって、Active Recordは以下を行えるようになります。

* 既に読み込み済みのデータに対する不要なクエリを防ぐ

    ```irb
    irb> author = Author.first
    irb> author.books.all? do |book|
    irb>   book.author.equal?(author) # 追加クエリはここで実行されない
    irb> end
    => true
    ```

* データの不整合を防ぐ
  読み込む`Author`オブジェクトのコピーは1個だけなので、不整合が発生しにくくなります。

    ```irb
    irb> author = Author.first
    irb> book = author.books.first
    irb> author.name == book.writer.name
    => true
    irb> author.name = "Changed Name"
    irb> author.name == book.writer.name
    => true
    ```

* 関連付けが自動保存されるケースが増える

    ```irb
    irb> author = Author.new
    irb> book = author.books.new
    irb> book.save!
    irb> book.persisted?
    => true
    irb> author.persisted?
    => true
    ```

* 関連付けの[`presence`](active_record_validations.html#presence)や[`absence`](active_record_validations.html#absence)がバリデーションされるケースが増える

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

場合によっては、`:foreign_key`や`:class_name`などのオプションを用いて関連付けをカスタマイズする必要が生じることがあります。これらのオプションを設定すると、Railsが`:through`や`:foreign_key`オプションを含む双方向の関連付けを自動的に認識しなくなる可能性があります。

[`config.active_record.automatic_scope_inversing`][]を`true`に設定していない場合、関連付け自体にカスタムスコープを設定したときと同様に、逆方向の関連付けにカスタムスコープを設定したときの自動認識も効かなくなります。

たとえば、カスタム外部キーを含む次のモデル宣言を考えてみましょう。

```ruby
class Author < ApplicationRecord
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: "Author", foreign_key: "author_id"
end
```

この場合、`:foreign_key`オプションが指定されているため、Active Recordは双方向関連付けを自動的に認識しなくなります。これによってアプリケーションで以下が発生する可能性があります。

* 同じデータに対して不要なクエリが実行される（この例ではN+1クエリが発生する）

    ```irb
    irb> author = Author.first
    irb> author.books.any? do |book|
    irb>   book.writer.equal?(author) # authorクエリがbook 1件ごとに発生する
    irb> end
    => false
    ```

* 同じモデルの複数のコピーが参照しているデータが不整合になる

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

このような問題を解決するには、以下のように`:inverse_of`オプションで双方向関連付けを明示的に宣言できます。

```ruby
class Author < ApplicationRecord
  has_many :books, inverse_of: "writer"
end

class Book < ApplicationRecord
  belongs_to :writer, class_name: "Author", foreign_key: "author_id"
end
```

`has_many`関連付けの宣言で`:inverse_of`オプションを指定すると、Active Recordが双方向関連付けを認識して、上述の最初の例と同じように動作するようになります。

[`config.active_record.automatic_scope_inversing`]:
    configuring.html#config-active-record-automatic-scope-inversing

関連付けの詳しい参考情報
------------------------------

#### オプション

Railsで使われているインテリジェントなデフォルト設定は、ほとんどの状況で適切に機能しますが、関連付け参照の動作をカスタマイズしたい場合もあります。
このようなカスタマイズは、関連付けを作成するときにオプションブロックを渡すことで実現できます。たとえば、以下の関連付けでは、そうしたオプションが2つ使われています。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at,
    counter_cache: true
end
```

どの関連付けも多数のオプションをサポートしています。詳しくは、ActiveRecord Associations APIで[個別の関連付けの`Options`](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html)セクションを参照してください。ここからは、よくあるユースケースをいくつか解説します。

##### `:class_name`

関連付けの相手となるオブジェクト名を関連付け名から生成できない事情がある場合、`:class_name`オプションを用いてモデル名を直接指定できます。
たとえば、書籍（book）が著者（author）に従属しているが、実際の著者のモデル名が`Patron`である場合には、以下のように指定します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, class_name: "Patron"
end
```

##### `:dependent`

`:dependent`オプションは、オーナーが破棄されたときに、関連付けられているオブジェクトがどう振る舞うかを制御します。

* `:destroy`: オブジェクトが破棄されると、関連付けられたオブジェクトに対して`destroy`を呼び出します。
  このメソッドは、関連付けられたレコードをデータベースから削除するだけでなく、定義されているコールバック（`before_destroy`や`after_destroy`など）も実行します。このオプションは、ログ出力や関連データのクリーンアップなど、削除プロセス中にカスタムロジックを実行する場合に便利です。

* `:delete`: オブジェクトが破棄されると、`destroy`メソッドを呼び出さずに、そのオブジェクトに関連付けられたすべてのオブジェクトをデータベースから直接削除します。
  このメソッドは直接削除を実行し、関連付けられたモデル内のコールバックやバリデーションをバイパスするため、より効率的ですが、重要なクリーンアップタスクがスキップされると、データの整合性の問題が発生する可能性があります。`delete`メソッドは、レコードを迅速に削除する必要があり、関連付けられたレコードに対して追加のアクションが必要ないことが確実な場合に使うこと。

* `:destroy_async`: オブジェクトが破棄されると、関連付けられたオブジェクトの`destroy`を呼び出すための`ActiveRecord::DestroyAssociationAsyncJob`ジョブをキューに登録します。
  このオプションが機能するためには、Active Jobをセットアップしておく必要があります。関連付けの背後にあるデータベースで外部キー制約が設定されている場合は、このオプションを使ってはいけません。外部キー制約の操作は、オーナーを削除するのと同じトランザクション内で発生します。

* `:nullify`: 外部キーを`NULL`に設定します。
  ポリモーフィック関連付けでは、ポリモーフィック`type`カラムも`NULL`に設定されます。コールバックは実行されません。

* `:restrict_with_exception`: 関連付けられたレコードが存在している場合は`ActiveRecord::DeleteRestrictionError`例外が発生します

* `:restrict_with_error`: 関連付けられたオブジェクトが存在している場合は、オーナーにエラーが追加されます。

WARNING: このオプションは、他のクラスの`has_many`関連付けに接続されている`belongs_to`関連付けで指定してはいけません。これを行うと、親オブジェクトを破棄したときにその子オブジェクトも破棄され、その子オブジェクトが再び親オブジェクトを破棄しようとして不整合が発生し、データベースに孤立レコードが発生する可能性があります。

データベースの`NOT NULL`制約を使っている関連付けでは、`:nullify`オプションを指定しないでください。そのような関連付けでは、`dependent`を`:destroy`に設定することが必須です。さもないと、関連付けられたオブジェクトの外部キーが`NULL`に設定されて変更できなくなる可能性があります。

NOTE: `:dependent`オプションは、`:through`オプションでは無視されます。`:through`オプションを使う場合は、joinモデルには`belongs_to`関連付けが必要です。削除はjoinレコードのみに影響し、関連付けられたレコードには影響しません。

スコープ付き関連付けで`dependent: :destroy`オプションを指定すると、スコープ付きオブジェクトのみが破棄されます。
たとえば、`Post`モデルで`has_many :comments, -> { where published: true }, dependent: :destroy`と定義されている場合、postで`destroy`を呼び出すと、`published: true`のコメントだけが削除され、削除されたpostを指す外部キーを持つ未公開のコメントは削除されずに残ります。

`has_and_belongs_to_many`関連付けでは、`:dependent`オプションを直接指定できません。joinテーブルのレコードの削除を管理したい場合は、手動で処理するか、`:dependent`オプションをサポートしている柔軟な`has_many :through`関連付けに切り替えましょう。

##### `:foreign_key`

Railsの規約では、相手のモデルを指す外部キーを保持しているjoinテーブル上のカラム名には、そのモデル名にサフィックス`_id`を追加した関連付け名が使われることを前提とします。

`:foreign_key`オプションを使えば、外部キー名を直接指定できます。

```ruby
class Supplier < ApplicationRecord
  has_one :account, foreign_key: "supp_id"
end
```

NOTE: Railsは外部キーカラムを自動的に作成しません。外部キーを使うには、マイグレーションを作成して明示的に定義する必要があります。

##### `:primary_key`

Railsの規約では、`id`カラムをテーブルの主キーとして使います。
`:primary_key`オプションを指定すると、別のカラムを主キーに設定できます。

たとえば、`users`テーブルに`guid`という主キーがあるとします。その`guid`カラムに、別の`todos`テーブルの外部キーである`user_id`カラムを使いたい場合は、次のように`primary_key`を設定します。

```ruby
class User < ApplicationRecord
  self.primary_key = "guid" # 主キーをidからguidに変更する
end

class Todo < ApplicationRecord
  belongs_to :user, primary_key: "guid" # usersテーブル内のguidを参照する
end
```

`@user.todos.create`を実行すると、`@todo`レコードの`user_id`値が`@user`の`guid`値に設定されます。

`has_and_belongs_to_many`関連付けは、`:primary_key`オプションをサポートしていません。代わりに`has_many :through`関連付けとjoinテーブルを使えば、同様の機能を実現できます。これにより柔軟性が高まり、`:primary_key`オプションがサポートされます。詳しくは、[`has_many :through`](#has-many-through関連付け)セクションを参照してください。

##### `:touch`

`:touch`オプションを`true`に設定すると、そのオブジェクトが`save`または`destroy`されたときに、関連付けられたオブジェクトの`updated_at`タイムスタンプや`updated_on`タイムスタンプが常に現在時刻に設定されます。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: true
end

class Author < ApplicationRecord
  has_many :books
end
```

上の`Book`は、`save`または`destroy`したときに、関連付けられている`Author`のタイムスタンプが更新されます。
以下のように、更新時に特定のタイムスタンプ属性を指定することも可能です。

```ruby
class Book < ApplicationRecord
  belongs_to :author, touch: :books_updated_at
end
```

`has_and_belongs_to_many`関連付けは、`:touch`オプションをサポートしていません。代わりに`has_many :through`関連付けとjoinテーブルを使えば、同様の機能を実現できます。詳しくは、[`has_many :through`](#has-many-through関連付け)セクションを参照してください。

##### `:validate`

`:validate`オプションを`true`に設定すると、新たに関連付けられたオブジェクトを保存したときにバリデーションが実行されます。デフォルトは`false`であり、この場合新たに関連付けられたオブジェクトは保存時にバリデーションされません。

`has_and_belongs_to_many`関連付けは、`:validate`オプションをサポートしていません。代わりに`has_many :through`関連付けとjoinテーブルを使えば、同様の機能を実現できます。詳しくは、[`has_many :through`](#has-many-through関連付け)セクションを参照してください。

##### `:inverse_of`

`:inverse_of`オプションは、その関連付けの逆関連付けとなる`has_many`関連付けまたは`has_one`関連付けの名前を指定します。
詳しくは[双方向関連付け](#双方向関連付け)を参照してください。

```ruby
class Supplier < ApplicationRecord
  has_one :account, inverse_of: :supplier
end

class Account < ApplicationRecord
  belongs_to :supplier, inverse_of: :account
end
```

##### `:source_type`

`:source_type`オプションは、[ポリモーフィック関連付け](#ポリモーフィック関連付け)を介する`has_one :through`関連付けで、関連付け元の型を指定します。

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

##### `:association_foreign_key`

`:association_foreign_key`オプションは、`has_and_belongs_to_many`関連付けで利用可能です。Railsの規約では、相手のモデルを指す外部キーを保持しているjoinテーブル上のカラム名については、そのモデル名にサフィックス`_id`を追加した名前が使われることが想定されます。`:association_foreign_key`オプションを使うと、外部キー名を以下のように直接指定できます。

```ruby
class User < ApplicationRecord
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

TIP: `:foreign_key`オプションおよび`:association_foreign_key`オプションは、多対多のself-joinを行いたいときに便利です。

##### `:join_table`

`:join_table`オプションは、`has_and_belongs_to_many`関連付けで利用可能です。辞書順に基いて生成されたjoinテーブルのデフォルト名では不都合がある場合、`:join_table`オプションを用いてデフォルトのテーブル名を上書きできます。

### スコープ

スコープ（scope）を使うと、関連付けオブジェクトのメソッド呼び出しとして参照可能な共通クエリを指定できます。スコープは、以下のようにアプリケーション内の複数の場所で再利用されるカスタムクエリを定義する場合に便利です。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

#### 汎用のスコープ

スコープブロック内では標準の[クエリメソッド](active_record_querying.html)をすべて利用できます。ここでは以下について説明します。

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where`メソッドは、関連付けられるオブジェクトが満たすべき条件を指定します。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

以下のように`where`をハッシュ形式で使うことも可能です。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { where factory: "Seattle" }
end
```

`where`をハッシュ形式で利用すると、この関連付けによるレコード作成はハッシュによって自動的にスコープ設定されます。この場合、`@parts.assemblies.create`や`@parts.assemblies.build`を使うことで、`factory`カラムの値が"Seattle"であるアセンブリが作成されます。

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

供給元（supplier）からアカウントの代表（representative）を`@supplier.account.representative`のように直接取り出す機会が多い場合は、`Supplier`から`Account`への関連付けに`Representative`をあらかじめ`includes`しておくと、クエリ数が削減されて効率が高まります。

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

NOTE: 直接の関連付けでは`includes`を使う必要はありません。`Book belongs_to :author`のような直接の関連付けでは、必要に応じて自動的にeager loadingされます。

##### `readonly`

`readonly`を指定すると、関連付けられたオブジェクトを読み出し専用で取り出します。

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { readonly }
end
```

このオプションは、関連付けられたオブジェクトが関連付けで変更されないようにしたい場合に便利です。たとえば、`belongs_to :author`関連付けを指定した`Book`モデルがある場合、`readonly`オプションを指定することで、著者（author）が書籍（book）を介して変更される事故を防止できます。

```ruby
@book.author = Author.first
@book.author.save! # ActiveRecord::ReadOnlyRecordエラーをraiseする
```

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトですべてのカラムを取り出します。

たとえば、`Author`モデルが多数の`Book`を持つ場合に、書籍の`title`だけを取得したい場合は、次のようになります。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { select(:id, :title) } # idカラムとtitleカラムだけをSELECTする
end

class Book < ApplicationRecord
  belongs_to :author
end
```

これで、著者の本にアクセスすると、`books`テーブルから`id`カラムと`title`カラムだけが取得されます。

TIP: `select`を`belongs_to`関連付けで使う場合は、正しい結果を得るために`:foreign_key`オプションも設定する必要があります。

```ruby
class Book < ApplicationRecord
  belongs_to :author, -> { select(:id, :name) }, foreign_key: "author_id" # idカラムとnameカラムだけをselectする
end

class Author < ApplicationRecord
  has_many :books
end
```

#### コレクションのスコープ

`has_many`と`has_and_belongs_to_many`はレコードのコレクションを扱う関連付けなので、`group`、`limit`、`order`、`select`、`distinct`などの追加メソッドを用いて、関連付けで使われるクエリをカスタマイズできます。

##### `group`

`group`メソッドは、結果をグループ化する属性名を1つ指定します。内部的にはSQLの`GROUP BY`句が使われます。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `limit`

`limit`メソッドは、関連付けを用いて取得できるオブジェクトの総数の上限を指定するのに使います。

```ruby
class Parts < ApplicationRecord
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `order`

`order`メソッドは、関連付けられたオブジェクトを受け取るときの並び順を指定します。内部的にはSQLの`ORDER BY`句が使われます。

```ruby
class Author < ApplicationRecord
  has_many :books, -> { order "date_confirmed DESC" }
end
```

##### `select`

`select`メソッドを使うと、関連付けられたオブジェクトのデータ取り出しに使われるSQLの`SELECT`句をオーバーライドできます。Railsはデフォルトではすべてのカラムを取り出します。

WARNING: `select`メソッドをカスタマイズする場合、関連付けられているモデルの主キーカラムと外部キーカラムを除外してはいけません。さもないと、Railsでエラーが発生します。

##### `distinct`

`distinct`メソッドは、コレクション内で重複が発生しないようにします。
このメソッドは、特に`:through`オプションと併用するときに便利です。

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

上の例には`reading`が2件ありますが、これらのレコードは同じ`article`を指しているにもかかわらず、`person.articles`では2件重複して出力されています。

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

上の例にも`reading`が2件ありますが、`person.articles`を実行すると1件の`article`だけを表示します。これはコレクションが一意のレコードだけを読み出しているからです。

挿入時にも同様に、永続化済みのレコードをすべて一意にする（関連付けを検査したときに重複レコードが決して発生しないようにする）には、テーブル自体にuniqueインデックスを追加する必要があります。たとえば`readings`というテーブルがあるとすると、1人の`person`に記事を1回しか追加できないようにするには、マイグレーションに以下を追加します。

```ruby
add_index :readings, [:person_id, :article_id], unique: true
```

uniqueインデックスを設定すると、同じ記事を`person`に2回追加しようとしたときに
`ActiveRecord::RecordNotUnique`エラーが発生するようになります

```irb
irb> person = Person.create(name: 'Honda')
irb> article = Article.create(name: 'a1')
irb> person.articles << article
irb> person.articles << article
ActiveRecord::RecordNotUnique
```

なお、一意性チェックに`include?`などのRubyメソッドを使うと競合が発生しやすいので注意が必要です。Rubyの`include?`は、関連付けを強制的に一意にする目的で使ってはいけません。たとえば上の`article`の例では、以下のコードを複数のユーザーが同時に実行したときに競合が発生しやすくなります。

```ruby
person.articles << article unless person.articles.include?(article)
```

#### 関連付けのオーナーで関連付けのスコープを制御する

関連付けのスコープをさらに制御する必要がある状況では、関連付けのオーナーをスコープブロックに引数として渡す方法が使えます。ただし、これを行うと関連付けのプリロードが不可能になる点にご注意ください。

```ruby
class Supplier < ApplicationRecord
  has_one :account, ->(supplier) { where active: supplier.active? }
end
```

上の例では、`Supplier`モデルの`account`関連付けは、供給元（supplier）の`active`ステータスに基づいてスコープが設定されます。

関連付けを拡張して、関連付けのオーナーでスコープを設定することで、Railsアプリケーションでより動的でコンテキストに対応した関連付けを作成できるようになります。

### カウンタキャッシュ

`:counter_cache`オプションは、従属しているオブジェクトの個数の検索効率を向上させます。
以下のモデルで考えてみましょう。

```ruby
class Book < ApplicationRecord
  belongs_to :author
end

class Author < ApplicationRecord
  has_many :books
end
```

上の宣言のままでは、`@author.books.size`の値を知るためにデータベースで`COUNT(*)`クエリをデフォルトで実行します。

これを最適化するには、以下のように、そのモデルに「**従属する側の**モデル（`belongs_to`を宣言している側のモデル）」にカウンタキャッシュを追加します。これにより、Railsはデータベースにクエリを送信せずにキャッシュから直接カウントを返せるようになります。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: true
end

class Author < ApplicationRecord
  has_many :books
end
```

上のように宣言すると、Railsはキャッシュ値を最新の状態に保ち、次回`size`メソッドが呼び出されたときにその値を返します。これにより、不要なデータベースクエリを回避できます。

ここで1つ注意が必要です。`:counter_cache`オプションは`belongs_to`宣言があるモデルで指定しますが、実際に個数を数えたいカラムは**関連付け先の**モデル（ここでは`has_many`を宣言しているモデル）の側に追加する必要があります。上の場合は、相手側の`Author`モデルに`books_count`カラムを追加する必要があります。

```ruby
class AddBooksCountToAuthors < ActiveRecord::Migration[6.0]
  def change
    add_column :authors, :books_count, :integer, default: 0, null: false
  end
end
```

`counter_cache`オプションで`true`の代わりに任意のカラム名を設定すると、デフォルトのカラム名をオーバーライドできます。以下は、`books_count`の代わりに`count_of_books`を設定した場合の例です。

```ruby
class Book < ApplicationRecord
  belongs_to :author, counter_cache: :count_of_books
end

class Author < ApplicationRecord
  has_many :books
end
```

NOTE: `:counter_cache`オプションは、関連付けの`belongs_to`側にだけ指定する必要があります。

既存の巨大テーブルで準備なしにカウンタキャッシュを使い始めると、トラブルが生じる可能性があります。テーブルを長時間ロックされるのを避けるためには、カラムの追加作業と、値をバックフィルする作業を分けて行う必要があります（つまりカラムの追加と値のバックフィルを一度に行わないようにします）。このバックフィル作業は、`:counter_cache`オプションを利用する前の段階で行っておく必要があります（さもないと、カウンタキャッシュを内部で利用する`size`や`any?`などのメソッドで誤った結果が生成される可能性があります）。

子レコードの作成や削除で発生するカウンタキャッシュのカラム更新を止めずに、値を安全にバックフィルするには、`counter_cache: { active: false }`オプションを指定します。このオプションを指定している間は、上述のメソッドでカウンタキャッシュカラムの誤った値を使わなくなり、常にデータベースから結果を取得するようになります。

カスタムのカラム名も指定する必要がある場合は、`counter_cache: { active: false, column: :my_custom_counter }`を使います。

何らかの理由でオーナーモデルの主キーの値を変更し、カウントされたモデルの外部キーも更新しなかった場合、カウンタキャッシュのデータが古くなっている可能性があります（つまり、孤立したモデルも引き続きカウンタでカウントされます）。古くなったカウンタキャッシュを修正するには、[`reset_counters`][]をお使いください。

[`reset_counters`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-reset_counters


### 関連付けのコールバック

[通常のコールバック](active_record_callbacks.html)は、Active Recordオブジェクトのライフサイクルの中でフックされます。これにより、さまざまなタイミングでオブジェクトのコールバックを実行できます。たとえば、`:before_save`コールバックを使うと、オブジェクトが保存される直前に何かを実行できます。

関連付けのコールバックも、上のような通常のコールバックと似ていますが、（Active Recordオブジェクトではなく）コレクションのライフサイクルによってイベントがトリガーされる点が異なります。関連付けでは、以下の4つのコールバックを利用できます。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

これらのオプションを関連付けの宣言に追加することで、関連付けコールバックを定義できます。以下に例を示します。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_credit_limit

  def check_credit_limit(book)
    throw(:abort) if limit_reached?
  end
end
```

この例では、`Author`モデルは`books`と`has_many`関連付けがあります。`before_add`コールバックで指定した`check_credit_limit`は、書籍がコレクションに追加される前にトリガーされます。`limit_reached?`メソッドが`true`を返す場合、書籍はコレクションに追加されません。

これらの関連付けコールバックを活用することで、関連付けの振る舞いをカスタマイズして、コレクションのライフサイクルの重要なポイントで特定のアクションを実行できるようになります。

関連付けのコールバックについて詳しくは、[Active Recordコールバックガイド](active_record_callbacks.html#関連付けのコールバック)を参照してください。

### 関連付けの拡張

Railsは、関連付けのプロキシオブジェクト（関連付けを管理する）を拡張するための機能を提供しており、新しいファインダーやクリエーターなどのメソッドを無名モジュール（anonymous module）を介して追加します。この機能により、アプリケーションの特定のニーズに合わせて関連付けをカスタマイズできます。

以下のように、モデル定義内で直接カスタムメソッドを利用することで`has_many`関連付けを拡張できます。

```ruby
class Author < ApplicationRecord
  has_many :books do
    def find_by_book_prefix(book_number)
      find_by(category_id: book_number[0..2])
    end
  end
end
```

上の例では、`find_by_book_prefix`メソッドが`Author`モデルの`books`関連付けに追加されています。このカスタムメソッドを使えば、`book_number`の特定のプレフィックスに基づいて`books`を検索できるようになります。

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

ここでは、`Author`モデルの`books`関連付けと、`Supplier`モデルの`deliveries`関連付けの両方に対して、`FindRecentExtension`モジュールを使って`find_recent`メソッドを追加しています。このメソッドは、過去5日以内に作成されたレコードを取得します。

拡張は、`proxy_association`アクセサを用いて関連付けプロキシの内部にアクセスできます。`proxy_association`には、以下の重要な3つの属性があります。

* `proxy_association.owner`: 関連付けを所有するオブジェクトを返します。
* `proxy_association.reflection`: 関連付けを記述するリフレクションオブジェクトを返します。
* `proxy_association.target`: `belongs_to`または`has_one`関連付けのオブジェクトを返すか、`has_many`または`has_and_belongs_to_many`関連付けオブジェクトのコレクションを返します。

拡張はこれらの属性を用いることで、関連付けプロキシの内部状態や振る舞いにアクセスして操作できるようになります。

拡張におけるこれらの属性の利用方法を示す高度な例を次に示します。

```ruby
module AdvancedExtension
  def find_and_log(query)
    results = where(query)
    proxy_association.owner.logger.info("Querying #{proxy_association.reflection.name} with #{query}")
    results
  end
end

class Author < ApplicationRecord
  has_many :books, -> { extending AdvancedExtension }
end
```

上の例では、`find_and_log`メソッドは関連付けに対してクエリを実行し、オーナーのロガーを使ってクエリの詳細を記録しています。このメソッドは、`proxy_association.owner`を介してオーナーのロガーにアクセスし、`proxy_association.reflection.name`を介して関連付けの名前にアクセスします。
