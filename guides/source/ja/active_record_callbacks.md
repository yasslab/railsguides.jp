Active Record コールバック
=======================

このガイドでは、Active Recordオブジェクトのライフサイクルにフックをかける方法について説明します。

このガイドの内容:

* Active Recordオブジェクトのライフサイクルでいつイベントが発生するか
* オブジェクトのライフサイクルにおけるイベントに応答するコールバックメソッドを作成する方法
* コールバックで共通となる振る舞いをカプセル化する特殊なクラスの作成方法

--------------------------------------------------------------------------------

オブジェクトのライフサイクル
---------------------

Railsアプリケーションを普通に操作すると、その内部でオブジェクトが作成・更新・削除（destroy）されます。Active Recordはこの**オブジェクトライフサイクル**へのフックを提供しており、これを用いてアプリケーションやデータを制御できます。

コールバックは、オブジェクトの状態が切り替わる「前」または「後」にロジックをトリガします。

```ruby
class Baby < ApplicationRecord
  after_create -> { puts "Congratulations!" }
end
```

```irb
irb> @baby = Baby.create
Congratulations!
```

このように、ライフサイクルにはさまざまなイベントがあり、イベントの「前」「後」「前後」のいずれかにフックできます。

コールバックの概要
------------------

コールバックとは、オブジェクトのライフサイクル期間における特定の瞬間に呼び出されるメソッドのことです。コールバックを利用することで、Active Recordオブジェクトが作成・保存・更新・削除・検証・データベースからの読み込み、などのイベント発生時に常に実行されるコードを書けるようになります。

### コールバックの登録

コールバックを利用するためには、コールバックを登録する必要があります。コールバックの実装は普通のメソッドと特に違うところはありません。これをコールバックとして登録するには、マクロのようなスタイルのクラスメソッドを使います。

```ruby
class User < ApplicationRecord
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  private
    def ensure_login_has_a_value
      if login.blank?
        self.login = email unless email.blank?
      end
    end
end
```

このマクロスタイルのクラスメソッドはブロックも受け取れます。以下のようにコールバックしたいコードがきわめて短く、1行に収まるような場合にこのスタイルを検討しましょう。

```ruby
class User < ApplicationRecord
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

以下のように、コールバックにprocを渡してトリガーさせることも可能です。

```ruby
class User < ApplicationRecord
  before_create ->(user) { user.name = user.login.capitalize if user.name.blank? }
end
```

最後に、独自のカスタムコールバックオブジェクトも定義できます。これについては[後述](#コールバッククラス)します。

```ruby
class User < ApplicationRecord
  before_create MaybeAddName
end

class MaybeAddName
  def self.before_create(record)
    if record.name.blank?
      record.name = record.login.capitalize
    end
  end
end
```

コールバックは、特定のライフサイクルのイベントでのみ呼び出される形で登録することも可能です。 これにより、コールバックがトリガーされるタイミングやコンテキストを完全に制御できるようになります。

```ruby
class User < ApplicationRecord
  before_validation :normalize_name, on: :create

  # :onは配列も受け取れる
  after_validation :set_location, on: [ :create, :update ]

  private
    def normalize_name
      self.name = name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

コールバックはprivateメソッドとして宣言するのが好ましい方法です。コールバックメソッドがpublicな状態のままだと、このメソッドがモデルの外から呼び出され、オブジェクトのカプセル化の原則に違反する可能性があります。

WARNING: コールバック内のオブジェクトに副作用を与える`update`、`save`などのメソッド呼び出しは避けてください。たとえば、コールバック内で`update(attribute: "value")`を呼び出してはいけません。これはモデルのステートを変更する可能性があり、コミット時に予期せぬ副作用が発生する可能性があります。代わりに、`before_create`や`before_update`、またはそれより前にトリガーされるコールバックで安全に値を直接代入できます（例: `self.attribute = "value"`）。

利用可能なコールバック
-------------------

Active Recordで利用可能なコールバックの一覧を以下に示します。これらのコールバックは、実際の操作中に呼び出される順序に並んでいます。

### オブジェクトの作成

* [`before_validation`][]
* [`after_validation`][]
* [`before_save`][]
* [`around_save`][]
* [`before_create`][]
* [`around_create`][]
* [`after_create`][]
* [`after_save`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_create`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_create
[`after_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_commit
[`after_rollback`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_rollback
[`after_save`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_save
[`after_validation`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/Callbacks/ClassMethods.html#method-i-after_validation
[`around_create`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_create
[`around_save`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_save
[`before_create`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_create
[`before_save`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_save
[`before_validation`]: https://api.rubyonrails.org/classes/ActiveModel/Validations/Callbacks/ClassMethods.html#method-i-before_validation

### オブジェクトの更新

* [`before_validation`][]
* [`after_validation`][]
* [`before_save`][]
* [`around_save`][]
* [`before_update`][]
* [`around_update`][]
* [`after_update`][]
* [`after_save`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_update`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_update
[`around_update`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_update
[`before_update`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_update

WARNING: `after_save`は`create`と`update`の両方で実行されますが、マクロ呼び出しの実行順序にかかわらず、常に`after_create`や`after_update`という特定のコールバックよりも**後**に呼び出されます。

### オブジェクトのdestroy

* [`before_destroy`][]
* [`around_destroy`][]
* [`after_destroy`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_destroy
[`around_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_destroy
[`before_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_destroy

NOTE: `before_destroy`コールバックは、`dependent: :destroy`よりも**前**に配置すること（または`prepend: true`オプションをお使いください）。理由は、そのレコードが`dependent: :destroy`関連付けによって削除されるよりも前に`before_destroy`コールバックが実行されるようにするためです。

WARNING: `after_commit`の保証は、`after_save`や`after_update`や`after_destroy`の保証とは大きく異なります。たとえば、`after_save`で例外が発生した場合、トランザクションはロールバックされ、データは永続化されません。
一方、`after_commit`で発生したものは、トランザクションが既に完了し、データがデータベースに永続化されたことを保証できます。詳しくは[トランザクションのコールバック](#トランザクションのコールバック)で後述します。

### `after_initialize`と`after_find`

[`after_initialize`][]コールバックは、Active Recordオブジェクトがインスタンス化されるたびに呼び出されます。インスタンス化は、直接`new`を実行する他に、データベースからレコードが読み込まれるときにも行われます。これを利用すれば、Active Recordの`initialize`メソッドを直接オーバーライドせずに済みます。

[`after_find`][]コールバックは、Active Recordがデータベースからレコードを1件読み込むたびに呼び出されます。`after_find`と`after_initialize`が両方定義されている場合は、`after_find`が先に呼び出されます。

NOTE: `after_initialize`と`after_find`コールバックには、対応する`before_*`メソッドはありませんが、他のActive Recordコールバックと同様に登録できます。

```ruby
class User < ApplicationRecord
  after_initialize do |user|
    puts "オブジェクトは初期化されました"
  end

  after_find do |user|
    puts "オブジェクトが見つかりました"
  end
end
```

```irb
irb> User.new
オブジェクトは初期化されました
=> #<User id: nil>

irb> User.first
オブジェクトが見つかりました
オブジェクトは初期化されました
=> #<User id: 1>
```

[`after_find`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_find
[`after_initialize`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_initialize

### `after_touch`

[`after_touch`][]コールバックは、Active Recordオブジェクトがtouchされるたびに呼び出されます。

```ruby
class User < ApplicationRecord
  after_touch do |user|
    puts "オブジェクトにtouchしました"
  end
end
```

```irb
irb> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

irb> u.touch
オブジェクトにtouchしました
=> true
```

このコールバックは`belongs_to`と併用できます。

```ruby
class Book < ApplicationRecord
  belongs_to :library, touch: true
  after_touch do
    puts 'Bookがtouchされました'
  end
end

class Library < ApplicationRecord
  has_many :books
  after_touch :log_when_books_or_library_touched

  private
    def log_when_books_or_library_touched
      puts 'Book/Libraryがtouchされました'
    end
end
```

```irb
irb> @book = Book.last
=> #<Book id: 1, library_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

irb> @book.touch # @book.library.touchがトリガーされる
Bookがtouchされました
Book/Libraryがtouchされました
=> true
```

[`after_touch`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_touch

コールバックの実行
-----------------

以下のメソッドはコールバックをトリガします。

* `create`
* `create!`
* `destroy`
* `destroy!`
* `destroy_all`
* `destroy_by`
* `save`
* `save!`
* `save(validate: false)`
* `save!(validate: false)`
* `toggle!`
* `touch`
* `update_attribute`
* `update`
* `update!`
* `valid?`

また、`after_find`コールバックは以下のfinderメソッドを実行すると呼び出されます。

* `all`
* `first`
* `find`
* `find_by`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`

`after_initialize`コールバックは、そのクラスの新しいオブジェクトが初期化されるたびに呼び出されます。

NOTE: `find_by_*`メソッドと`find_by_*!`メソッドは、属性ごとに自動的に生成される動的なfinderメソッドです。詳しくは[動的finderのセクション](active_record_querying.html#動的検索)を参照してください。

コールバックをスキップする
------------------

バリデーション（検証）の場合と同様、以下のメソッドでもコールバックをスキップできます。

* [`decrement!`][]
* [`decrement_counter`][]
* [`delete`][]
* [`delete_all`][]
* [`delete_by`][]
* [`increment!`][]
* [`increment_counter`][]
* [`insert`][]
* [`insert!`][]
* [`insert_all`][]
* [`insert_all!`][]
* [`touch_all`][]
* [`update_column`][]
* [`update_columns`][]
* [`update_all`][]
* [`update_counters`][]
* [`upsert`][]
* [`upsert_all`][]

ただし、重要なビジネスルールやアプリケーションロジックがコールバックに設定されている可能性もあるので、これらのメソッドの利用には十分注意すべきです。この点を理解せずにコールバックをバイパスすると、データの不整合が発生する可能性があります。

[`decrement!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-decrement-21
[`decrement_counter`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-decrement_counter
[`delete`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-delete
[`delete_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-delete_all
[`delete_by`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-delete_by
[`increment!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-increment-21
[`increment_counter`]: https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-increment_counter
[`insert`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert
[`insert!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert-21
[`insert_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all
[`insert_all!`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all-21
[`touch_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-touch_all
[`update_column`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_column
[`update_columns`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_columns
[`update_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_all
[`update_counters`]: https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_counters
[`upsert`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert
[`upsert_all`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all

コールバックの停止
-----------------

モデルに新しくコールバックを登録すると、コールバックは実行キューに入ります。このキューには、あらゆるモデルに対するバリデーション、登録済みコールバック、実行待ちのデータベース操作が置かれます。

コールバックチェーン全体は、1つのトランザクションにラップされます。コールバックの1つで例外が発生すると、実行チェーン全体が停止してロールバックが発行されます。チェーンを意図的に停止するには次のようにします。

```ruby
throw :abort
```

WARNING: `ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`を除く例外は、その例外によってコールバックチェインが停止した後も、Railsによって再び発生します。さらに、`ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`以外の例外が発生すると、`save`や`update`のようなメソッド（つまり通常`true`か`false`を返そうとするメソッド）が例外を発生することを想定していないコードが中断する恐れがあります。

NOTE: `after_destroy`、`before_destroy`、または`around_destroy`コールバック内で `ActiveRecord::RecordNotDestroyed`例外が発生した場合、`destroy`メソッドは再度例外を発生せずに`false`を返します。

リレーションシップのコールバック
--------------------

コールバックはモデルのリレーションシップを経由して動作できます。また、リレーションシップを用いてコールバックを定義することも可能です。1人のユーザーが多数の記事（article）を持っている状況を例に取ります。ユーザーが削除されたら、ユーザーの記事も削除する必要があります。`User`モデルに`after_destroy`コールバックを追加し、このコールバックで`Post`モデルへのリレーションシップを経由すると以下のようになります。

```ruby
class User < ApplicationRecord
  has_many :articles, dependent: :destroy
end

class Article < ApplicationRecord
  after_destroy :log_destroy_action

  def log_destroy_action
    puts '記事を削除しました'
  end
end
```

```irb
irb> user = User.first
=> #<User id: 1>
irb> user.articles.create!
=> #<Article id: 1, user_id: 1>
irb> user.destroy
記事を削除しました
=> #<User id: 1>
```

関連付けのコールバック
---------------------

関連付けのコールバックは通常のコールバックと似ていますが、コレクションのライフサイクル内で発生するイベントによってトリガーされる点が異なります。利用可能な関連付けコールバックは以下のとおりです。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

関連付けコールバックを定義するには、関連付けの宣言で以下のようにオプションを追加します。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_credit_limit

  def check_credit_limit(book)
    # ...
  end
end
```

Railsは、追加または削除されるオブジェクトをコールバックに渡します。

以下のようにコールバックを配列として渡すことで、単一のイベントに複数のコールバックを登録できます。

```ruby
class Author < ApplicationRecord
  has_many :books,
    before_add: [:check_credit_limit, :calculate_shipping_charges]

  def check_credit_limit(book)
    # ...
  end

  def calculate_shipping_charges(book)
    # ...
  end
end
```

`before_add`コールバックが`:abort`をスローした場合、オブジェクトはコレクションに追加されません。 同様に、`before_remove`コールバックが``:abort`をスローした場合、オブジェクトはコレクションから削除されません。

```ruby
# limit_reached?がtrueの場合はbookが追加されない
def check_credit_limit(book)
  throw(:abort) if limit_reached?
end
```

NOTE: これらのコールバックは、関連付けられるオブジェクトが関連付けのコレクションを介して追加または削除された場合にのみ呼び出されます。

```ruby
# この場合は`before_add`コールバックがトリガーされる
author.books << book
author.books = [book, book2]

# この場合は`before_add`コールバックがトリガーされない
book.update(author_id: 1)
```

条件付きコールバック
---------------------

バリデーションと同様、指定された述語の条件を満たす場合に実行されるコールバックメソッドの呼び出しも作成可能です。これを行なうには、コールバックで`:if`オプションまたは`:unless`オプションを使います。このオプションはシンボル、`Proc`、または`Array`を引数に取ります。

特定の状況でのみコールバックを**呼び出す必要がある**場合は、`:if`オプションを使います。特定の状況でコールバックを**呼び出してはならない**場合は、`:unless`オプションを使います。

### `:if`および`:unless`オプションでシンボルを使う

`:if`オプションまたは`:unless`オプションは、コールバックの直前に呼び出される述語メソッド名に対応するシンボルと関連付けることが可能です。

`:if`オプションを使う場合、述語メソッドが`false`を返せばコールバックは**実行されません**。
`:unless`オプションを使う場合、述語メソッドが`true`を返せばコールバックは**実行されません**。これはコールバックで最もよく使われるオプションです。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

この方法で登録すれば、さまざまな述語メソッドを登録して、コールバックを呼び出すべきかどうかをチェックできるようになります。詳しくは[後述](#コールバックで複数の条件を指定する)します。

### `:if`および`:unless`オプションで`Proc`を使う

`:if`および`:unless`オプションでは`Proc`オブジェクトも利用できます。このオプションは、1行以内に収まるワンライナーでバリデーションを行う場合に最適です。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

procはそのオブジェクトのコンテキストで評価されるので、以下のように書くこともできます。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: Proc.new { paid_with_card? }
end
```

### `:if`と`:unless`を同時に使う

コールバックでは、以下のように同じ宣言内で`:if`と`:unless`を併用できます。

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: Proc.new { forum.parental_control? },
    unless: Proc.new { author.trusted? }
end
```

上のコールバックは、`:if`条件がすべて`true`と評価され、かつ`:unless`条件が1件も`true`と評価されない場合にのみ実行されます。

### コールバックで複数の条件を指定する

`:if`と`:unless`オプションは、procやメソッド名のシンボルの配列を受け取ることも可能です。

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: [:subject_to_parental_control?, :untrusted_author?]
end
```

条件リストではprocを手軽に利用できます。

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: [:subject_to_parental_control?, Proc.new { untrusted_author? }]
end
```

### `:if`と`:unless`を同時に使う

コールバックは、同じ宣言の中で`:if`と`:unless`を併用できます。

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: Proc.new { forum.parental_control? },
    unless: Proc.new { author.trusted? }
end
```

このコールバックは、すべての`:if`条件が`true`と評価され、どの`:unless`条件も`true`と評価されなかった場合にのみ実行されます。

コールバッククラス
----------------

有用なコールバックメソッドを書いた後で、他のモデルでも使い回したいことがあります。Active Recordは、コールバックメソッドをカプセル化したクラスを作成できるので、手軽に再利用できます。

ここでは、ファイルシステム上で破棄されたファイルのクリーンアップを行うために`after_destroy`コールバックを持つクラスを作成する例を示します。
この振る舞いは`PictureFile`モデルに固有のものではなく、共有したい場合もあるので、これを別のクラスにカプセル化するのは良い考えです。これにより、その振る舞いのテストや変更がずっと簡単になります。

```ruby
class FileDestroyerCallback
  def after_destroy(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

上のようにクラス内で宣言すると、コールバックメソッドはモデルオブジェクトをパラメータとして受け取れるようになります。これで、このコールバッククラスをモデルで使えます。

```ruby
class PictureFile < ApplicationRecord
  after_destroy FileDestroyerCallbacks.new
end
```

コールバックをインスタンスメソッドとして宣言したので、`FileDestroyerCallback`オブジェクトを新しくインスタンス化する必要があったことにご注意ください。これは、インスタンス化されたオブジェクトの状態をコールバックメソッドで利用したい場合に特に便利です。ただし、コールバックをクラスメソッドとして宣言する方が理にかなうこともよくあります。

```ruby
class FileDestroyerCallback
  def self.after_destroy(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

コールバックメソッドを上のように宣言した場合は、モデル内で`FileDestroyerCallback`オブジェクトのインスタンス化が不要になります。

```ruby
class PictureFile < ApplicationRecord
  after_destroy FileDestroyerCallback
end
```

コールバッククラスの内部では、いくつでもコールバックを宣言できます。

トランザクションのコールバック
---------------------

### `after_commit`コールバックと`after_rollback`コールバック

データベースのトランザクションが完了したときにトリガされるコールバックが2つあります。[`after_commit`][]と[`after_rollback`][]です。

これらのコールバックは`after_save`コールバックときわめて似ていますが、データベースの変更のコミットまたはロールバックが完了するまでトリガされない点が異なります。これらのメソッドは、Active Recordのモデルから、データベーストランザクションの一部に含まれていない外部のシステムとやりとりしたい場合に特に便利です。

例として、直前の例で用いた`PictureFile`モデルで、対応するレコードが削除された後にファイルを1つ削除する必要があるとしましょう。`after_destroy`コールバックの直後に何らかの例外が発生してトランザクションがロールバックすると、ファイルが削除され、モデルの一貫性が損なわれたままになります。ここで、以下のコードにある`picture_file_2`オブジェクトが無効で、`save!`メソッドがエラーを発生するとします。

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

`after_commit`コールバックを使えば、このような場合に対応できます。

```ruby
class PictureFile < ApplicationRecord
  after_commit :delete_picture_file_from_disk, on: :destroy

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

NOTE: `:on`オプションは、コールバックがトリガされる条件を指定します。`:on`オプションを指定しないと、すべてのアクションでコールバックがトリガされます。

WARNING: トランザクションが完了すると、そのトランザクション内で作成・更新・破棄されたすべてのモデルに対して`after_commit`コールバックまたは`after_rollback`コールバックが呼び出されます。
ただし、これらのコールバックのいずれか内で例外が発生した場合、例外はバブルアップし、残りの`after_commit`メソッドや`after_rollback`メソッドは実行されません。
そのため、コールバックのコードで例外が発生する可能性がある場合は、他のコールバックを実行できるように、その例外を`rescue`してコールバック内で処理する必要があることにご注意ください。

WARNING: `after_commit`コールバックや`after_rollback`コールバック内で実行されるコード自体は、トランザクション内に含まれない点にご注意ください。

WARNING: 単一トランザクションのコンテキストで、データベース内の同じレコードを表す複数の読み込み済みオブジェクトを操作する場合、`after_commit`コールバックや`after_rollback`コールバックの振る舞いには重要な注意点があります。
これらのコールバックは、トランザクション内で変更される特定のレコードの「最初のオブジェクト」に対してのみトリガーされます。読み込まれている他のオブジェクトは、同じデータベースレコードを表しているにもかかわらず、`after_commit`コールバックや`after_rollback`コールバックをトリガーしません。
この微妙な振る舞いによる影響が特に大きいシナリオは、「同じデータベースレコードに関連付けられるオブジェクトごとに、コールバックが独立して実行されることが予想される」場合です。この振る舞いは、コールバックシーケンスのフローや予測可能性に影響を与える可能性があり、トランザクションに沿って動作するアプリケーションロジックに不整合が生じる可能性があります。

### `after_commit`コールバックのエイリアス

`after_commit`コールバックは作成・更新・削除でのみ用いることが多いので、それぞれのエイリアスも用意されています。

* [`after_create_commit`][]
* [`after_update_commit`][]
* [`after_destroy_commit`][]

```ruby
class PictureFile < ApplicationRecord
  after_destroy_commit :delete_picture_file_from_disk

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

WARNING: 同一のモデル内で同じメソッド名を引数に取る`after_create_commit`と`after_update_commit`を両方用いると、最後に定義したコールバックだけが有効になります。理由は、これらのコールバックが内部で`after_commit`のエイリアスになっていて、最初に同じメソッド名を引数に定義したコールバックがオーバーライドされるからです。

```ruby
class User < ApplicationRecord
  after_create_commit :log_user_saved_to_db
  after_update_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      puts 'ユーザーはデータベースに保存されました'
    end
end
```

```irb
irb> @user = User.create # 何も出力しない

irb> @user.save          # @userを更新する
ユーザーはデータベースに保存されました
```

### `after_save_commit`

作成と更新の両方で`after_commit`コールバックを使う場合のエイリアスとして、[`after_save_commit`][]も利用できます。

```ruby
class User < ApplicationRecord
  after_save_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      puts 'ユーザーはデータベースに保存されました'
    end
end
```

```irb
irb> @user = User.create # Userを作成
ユーザーはデータベースに保存されました

irb> @user.save # @userを更新
ユーザーはデータベースに保存されました
```

### トランザクショナルなコールバックの順序

デフォルトでは、コールバックは定義された順序で実行されます。
ただし、トランザクショナルな`after_`コールバック（`after_commit`や`after_rollback`など）を複数定義すると、定義時と逆順で実行される可能性があります。

```ruby
class User < ActiveRecord::Base
  after_commit { puts("これは実際には2番目に実行される") }
  after_commit { puts("これは実際には1番目に実行される") }
end
```

NOTE: これは、`after_destroy_commit`などを含む、すべての`after_*_commit`のバリエーションにも当てはまります。

この実行順序は以下の設定で変更できます。

```ruby
config.active_record.run_after_transaction_callbacks_in_order_defined = false
```

`true`（Rails 7.1以降のデフォルト）に設定すると、コールバックは定義された順序で実行されます。
`false`に設定すると、上の例と同様に、実行順序が逆になります。

[`after_create_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_create_commit
[`after_destroy_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_destroy_commit
[`after_save_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_save_commit
[`after_update_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_update_commit
