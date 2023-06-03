Active Record コールバック
=======================

本ガイドでは、Active Recordオブジェクトのライフサイクルにフックをかける方法について説明します。

このガイドの内容:

* Active Recordオブジェクトのライフサイクル
* オブジェクトのライフサイクルにおけるイベントに応答するコールバックメソッドを作成する方法
* コールバックで共通となる振る舞いをカプセル化する特殊なクラスの作成方法

--------------------------------------------------------------------------------

オブジェクトのライフサイクル
---------------------

Railsアプリケーションを普通に操作すると、その内部でオブジェクトが作成・更新・削除（destroy）されます。Active Recordはこの**オブジェクトライフサイクル**へのフックを提供しており、これを用いてアプリケーションやデータを制御できます。

コールバックは、オブジェクトの状態が切り替わる「前」または「後」にロジックをトリガします。

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
      if login.nil?
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

特定のライフサイクルのイベントでのみ呼び出されるようにコールバックを登録することも可能です。

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

### オブジェクトのdestroy

* [`before_destroy`][]
* [`around_destroy`][]
* [`after_destroy`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_destroy
[`around_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_destroy
[`before_destroy`]: https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_destroy

WARNING: `after_save`コールバックは作成と更新の両方で呼び出されますが、コールバックマクロの呼び出し順序にかかわらず、常に、より具体的な`after_create`コールバックや`after_update`コールバックより**後に**呼び出されます。

WARNING: コールバック内では属性の更新や保存は行わないようにしてください。たとえば、コールバック内で`update(attribute: "value")`を呼び出してはいけません。このような操作はモデルのステートを変化させて、コミット時に思わぬ副作用が生じる可能性があります。`before_create`、`before_update`、およびそれより前に発火するコールバックで値を（`self.attribute = "value"`のように）直接代入するのは安全です。

NOTE: `before_destroy`コールバックは、`dependent: :destroy`よりも**前**に配置すること（または`prepend: true`オプションをお使いください）。理由は、そのレコードが`dependent: :destroy`関連付けによって削除されるよりも前に`before_destroy`コールバックが実行されるようにするためです。

### `after_initialize`と`after_find`

[`after_initialize`][]コールバックは、Active Recordオブジェクトが1つインスタンス化されるたびに呼び出されます。インスタンス化は、直接`new`を実行する他にデータベースからレコードが読み込まれるときにも行われます。これを利用すれば、Active Recordの`initialize`メソッドを直接オーバーライドせずに済みます。

[`after_find`][]コールバックは、Active Recordがデータベースからレコードを1つ読み込むたびに呼び出されます。`after_find`と`after_initialize`が両方定義されている場合は、`after_find`が先に実行されます。

`after_initialize`と`after_find`コールバックには、対応する`before_*`メソッドはありませんが、他のActive Recordコールバックと同様に登録できます。

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
class Employee < ApplicationRecord
  belongs_to :company, touch: true
  after_touch do
    puts 'Employeeがtouchされました'
  end
end

class Company < ApplicationRecord
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
    def log_when_employees_or_company_touched
      puts 'Employee/Companyがtouchされました'
    end
end
```

```irb
irb> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

irb> @employee.touch # triggers @employee.company.touch
Employeeがtouchされました
Employee/Companyがtouchされました
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

* `decrement!`
* `decrement_counter`
* `delete`
* `delete_all`
* `delete_by`
* `increment!`
* `increment_counter`
* `insert`
* `insert!`
* `insert_all`
* `insert_all!`
* `touch_all`
* `update_column`
* `update_columns`
* `update_all`
* `update_counters`
* `upsert`
* `upsert_all`

ただし、重要なビジネスルールやアプリケーションロジックがコールバックに設定されている可能性もあるので、これらのメソッドの利用には十分注意すべきです。この点を理解せずにコールバックをバイパスすると、データの不整合が発生する可能性があります。

コールバックの停止
-----------------

モデルに新しくコールバックを登録すると、コールバックは実行キューに入ります。このキューには、あらゆるモデルに対するバリデーション、登録済みコールバック、実行待ちのデータベース操作が置かれます。

コールバックチェーン全体は、1つのトランザクションにラップされます。コールバックの1つで例外が発生すると、実行チェーン全体が停止してロールバックが発行されます。チェーンを意図的に停止するには次のようにします。

```ruby
throw :abort
```

WARNING: `ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`を除く例外は、その例外によってコールバックチェインが停止した後も、Railsによって再び発生します。このため、`ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`以外の例外を発生させると、`save`や`update`のようなメソッド（つまり通常`true`か`false`を返そうとするメソッド）が例外を発生することを想定していないコードが中断する恐れがあります。

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

条件付きコールバック
---------------------

検証と同様、与えられた述語の条件を満たす場合に実行されるコールバックメソッドの呼び出しも作成可能です。これを行なうには、コールバックで`:if`オプションまたは`:unless`オプションを使います。このオプションはシンボル、`Proc`、または`Array`を引数に取ります。特定の状況でのみコールバックが呼び出される必要がある場合は、`:if`オプションを使います。特定の状況でコールバックを**呼び出してはならない**場合は、`:unless`オプションを使います。

### `:if`および`:unless`オプションでシンボルを使う

`:if`オプションまたは`:unless`オプションは、コールバックの直前に呼び出される述語メソッドの名前に対応するシンボルと関連付けることが可能です。`:if`オプションを使う場合、述語メソッドが`false`を返せばコールバックは実行されません。`:unless`オプションを使う場合、述語メソッドが`true`を返せばコールバックは実行されません。これはコールバックで最もよく使われるオプションです。この方法で登録すれば、さまざまな述語メソッドを登録して、コールバックを呼び出すべきかどうかをチェックできるようになります。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

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

コールバッククラス
----------------

有用なコールバックメソッドを書いた後で、他のモデルでも使い回したいことがあります。Active Recordは、コールバックメソッドをカプセル化したクラスを作成できるので、手軽に再利用できます。

以下の例では、`PictureFile`モデル用に`after_destroy`コールバックを持つクラスを作成しています。

```ruby
class PictureFileCallbacks
  def after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

上のようにクラス内で宣言すると、コールバックメソッドはモデルオブジェクトをパラメータとして受け取れるようになります。これで、このコールバッククラスをモデルで使えます。

```ruby
class PictureFile < ApplicationRecord
  after_destroy PictureFileCallbacks.new
end
```

コールバックをインスタンスメソッドとして宣言したので、`PictureFileCallbacks`オブジェクトを新しくインスタンス化する必要があったことにご注意ください。これは、インスタンス化されたオブジェクトの状態をコールバックメソッドで利用したい場合に特に便利です。ただし、コールバックをクラスメソッドとして宣言する方が理にかなうこともよくあります。

```ruby
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

コールバックメソッドを上のように宣言した場合は、`PictureFileCallbacks`オブジェクトのインスタンス化は不要です。

```ruby
class PictureFile < ApplicationRecord
  after_destroy PictureFileCallbacks
end
```

コールバッククラスの内部では、いくつでもコールバックを宣言できます。

トランザクションのコールバック
---------------------

データベースのトランザクションが完了したときにトリガされるコールバックが2つあります。[`after_commit`][]と[`after_rollback`][]です。これらのコールバックは`after_save`コールバックときわめて似ていますが、データベースの変更のコミットまたはロールバックが完了するまでトリガされない点が異なります。これらのメソッドは、Active Recordのモデルから、データベーストランザクションの一部に含まれていない外部のシステムとやりとりしたい場合に特に便利です。

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

`after_commit`コールバックは作成/更新/削除でのみ用いることが多いので、それぞれのエイリアスも用意されています。

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

WARNING: あるトランザクションが完了すると、`after_commit`コールバックおよび`after_rollback`コールバックは、1つのトランザクションブロック内で作成・更新・削除されたすべてのモデルで呼び出されます。ただし、これらのコールバックのいずれかで何らかの例外が発生すると、その例外のせいで以後の`after_commit`コールバックや`after_rollback`コールバックのメソッドは**実行されなくなります**。このため、もし自作のコールバックで例外が発生する可能性がある場合は、他のコールバックが停止しないように自分のコールバック内で`rescue`して適切にエラー処理を行う必要があります。

WARNING: `after_commit`コールバックや`after_rollback`コールバックの中で実行されるコードそのものは、トランザクションで囲まれません。

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

コールバックを作成と更新の両方の操作に登録するには、代わりに`after_commit`をお使いください。以下のエイリアスも、作成や更新の両方で使える`after_commit`コールバックとして用いることができます。

* [`after_save_commit`][]

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

[`after_create_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_create_commit
[`after_destroy_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_destroy_commit
[`after_save_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_save_commit
[`after_update_commit`]: https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_update_commit
