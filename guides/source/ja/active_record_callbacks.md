
Active Record コールバック
=======================

このガイドでは、Active Recordオブジェクトのライフサイクルにフックをかける方法について説明します。

このガイドの内容:

* Active Recordオブジェクトのライフサイクル
* オブジェクトのライフサイクルにおけるイベントに応答するコールバックメソッドを作成する方法
* コールバックで共通となる振る舞いをカプセル化する特殊なクラスの作成方法

--------------------------------------------------------------------------------

オブジェクトのライフサイクル
---------------------

Railsアプリケーションを普通に操作すると、その内部でオブジェクトが作成されたり、更新されたりdestroyされたりします。Active Recordはこの<em>オブジェクトライフサイクル</em>へのフックを提供しており、これを使用してアプリケーションやデータを制御できます。

コールバックは、オブジェクトの状態が切り替わる「前」または「後」にロジックをトリガします。

コールバックの概要
------------------

コールバックとは、オブジェクトのライフサイクル期間における特定の瞬間に呼び出されるメソッドのことです。コールバックを利用することで、Active Recordオブジェクトが作成/保存/更新/削除/検証/データベースからの読み込み、などのイベント発生時に常に実行されるコードを書くことができます。

### コールバックの登録

コールバックを利用するためには、コールバックを登録する必要があります。コールバックの実装は普通のメソッドと特に違うところはありません。これをコールバックとして登録するには、マクロのようなスタイルのクラスメソッドを使用します。

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

このマクロスタイルのクラスメソッドはブロックを受け取ることもできます。以下のようにコールバックしたいコードがきわめて短く、1行に収まるような場合にこのスタイルを使ってみます。

```ruby
class User < ApplicationRecord
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

コールバックは、特定のライフサイクルのイベントでのみ呼び出されるように登録することもできます。

```ruby
class User < ApplicationRecord
  before_validation :normalize_name, on: :create

  # :onは配列を取ることもできる
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

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_create`
* `around_create`
* `after_create`
* `after_save`

### オブジェクトの更新

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_update`
* `around_update`
* `after_update`
* `after_save`

### オブジェクトのdestroy

* `before_destroy`
* `around_destroy`
* `after_destroy`

WARNING: `after_save`は作成と更新の両方で呼び出されますが、コールバックマクロの呼び出し順にかかわらず、必ず、より具体的な`after_create`および`after_update`より _後_ に呼び出されます。

NOTE: `before_destroy`コールバックは、`dependent: :destroy`よりも前に配置する（または`prepend: true`オプションを用いる）べきです。これは、そのレコードが`dependent: :destroy`によって削除されるよりも前に`before_destroy`コールバックが実行されるようにするためです。

### `after_initialize`と`after_find`

`after_initialize`コールバックは、Active Recordオブジェクトが1つインスタンス化されるたびに呼び出されます。インスタンス化は、直接`new`を実行する他にデータベースからレコードが読み込まれるときにも行われます。これを利用すれば、Active Recordの`initialize`メソッドを直接オーバーライドせずに済みます。

`after_find`コールバックは、Active Recordがデータベースからレコードを1つ読み込むたびに呼び出されます。`after_find`と`after_initialize`が両方定義されている場合は、`after_find`が先に実行されます。

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

>> User.new
オブジェクトは初期化されました
=> #<User id: nil>

>> User.first
オブジェクトが見つかりました
オブジェクトは初期化されました
=> #<User id: 1>
```

### `after_touch`

`after_touch`コールバックは、Active Recordオブジェクトがタッチされるたびに呼び出されます。

```ruby
class User < ApplicationRecord
  after_touch do |user|
    puts "オブジェクトにタッチしました"
  end
end

>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
オブジェクトにタッチしました
=> true
```

このコールバックは`belongs_to`と併用できます。

```ruby
class Employee < ApplicationRecord
  belongs_to :company, touch: true
  after_touch do
    puts 'Employeeモデルにタッチされました'
  end
end

class Company < ApplicationRecord
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Companyにタッチされました'
  end
end

>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# @employee.company.touchをトリガーする
>> @employee.touch
Employeeにタッチされました
Employee/Companyにタッチされました
=> true
```

コールバックの実行
-----------------

以下のメソッドはコールバックをトリガします。

* `create`
* `create!`
* `destroy`
* `destroy!`
* `destroy_all`
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

NOTE: `find_by_*`メソッドと`find_by_*!`メソッドは、属性ごとに自動的に生成される動的なfinderメソッドです。詳細については[動的finderのセクション](active_record_querying.html#動的検索)を参照してください。

コールバックをスキップする
------------------

検証(validation)の場合と同様、以下のメソッドを使用するとコールバックをスキップできます。

* `decrement`
* `decrement_counter`
* `delete`
* `delete_all`
* `increment`
* `increment_counter`
* `toggle`
* `update_column`
* `update_columns`
* `update_all`
* `update_counters`

重要なビジネスルールやアプリケーションロジックがコールバックに実装されている可能性があるので、これらのメソッドの使用には十分気をつけてください。コールバックをうかつにバイパスすると、データの不整合が発生する可能性があります。

コールバックの停止
-----------------

モデルに新しくコールバックを登録すると、コールバックは実行キューに入ります。このキューには、あらゆるモデルに対する検証、登録済みコールバック、実行待ちのデータベース操作が置かれます。

コールバックチェイン全体は、1つのトランザクションにラップされます。コールバックの1つで例外が発生すると、実行チェイン全体が停止してロールバックが発行されます。チェインを意図的に停止するには次のようにします。

```ruby
throw :abort
```

WARNING: `ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`を除く例外は、その例外によってコールバックチェインが停止した後も、Railsによって再び発生します。このため、`ActiveRecord::Rollback`や`ActiveRecord::RecordInvalid`以外の例外を発生させると、`save`や`update_attributes`のようなメソッド (つまり通常`true`か`false`を返そうとするメソッド) が例外を発生させることを想定していないコードが中断する恐れがあります。

リレーションシップのコールバック
--------------------

コールバックはモデルのリレーションシップを経由して動作できます。また、リレーションシップを使用してコールバックを定義することすらできます。1人のユーザーが多数のポストを持っている状況を例に取ります。あるユーザーが所有するポストは、そのユーザーがdestroyされたらdestroyされる必要があります。`User`モデルに`after_destroy`コールバックを追加し、このコールバックで`Post`モデルへのリレーションシップを経由すると以下のようになります。

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
end

class Post < ApplicationRecord
  after_destroy :log_destroy_action

  def log_destroy_action
    puts 'Post destroyed'
  end
end

>> user = User.first
=> #<User id: 1>
>> user.posts.create!
=> #<Post id: 1, user_id: 1>
>> user.destroy
Post destroyed
=> #<User id: 1>
```

条件付きコールバック
---------------------

検証と同様、与えられた述語による条件を満たす場合に実行されるコールバックメソッドの呼び出しを作成することもできます。これを行なうには、コールバックで`:if`オプションまたは`:unless`オプションを使用します。このオプションはシンボル、`Proc`、または`Array`を引数に取ります。特定の状況でのみコールバックが呼び出される必要がある場合は、`:if`オプションを使用します。特定の状況ではコールバックを呼び出してはならない場合は、`:unless`オプションを使用します。

### `:if`および`:unless`オプションでシンボルを使用する

`:if`オプションまたは`:unless`オプションは、コールバックの直前に呼び出される述語メソッド(訳注: trueかfalseのいずれかの値のみを返すメソッド)の名前に対応するシンボルと関連付けることができます。`:if`オプションを使用する場合、述語メソッドがfalseを返せばコールバックは実行されません。`:unless`オプションを使用する場合、述語メソッドがtrueを返せばコールバックは実行されません。これはコールバックで最もよく使用されるオプションです。この方法で登録することで、いくつもの異なる述語メソッドを登録して、コールバックを呼び出すべきかどうかをチェックすることができます。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

### `:if`および`:unless`オプションで`Proc`を使用する

最後に、`:if`および`:unless`オプションで`Proc`オブジェクトを使用することもできます。このオプションは、1行以内に収まるワンライナーで検証を行う場合に最適です。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

### コールバックで複数の条件を指定する

1つの条件付きコールバック宣言内で、`:if`オプションと`:unless`オプションを同時に使用することができます。

```ruby
class Comment < ApplicationRecord
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.post.ignore_comments? }
end
```

コールバッククラス
----------------

うまく書けたコールバックメソッドを他のモデルでも使い回したくなることもあります。Active Recordは、コールバックメソッドをカプセル化したクラスを作成できますので、簡単に再利用できます。

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

上のようにクラス内で宣言することにより、コールバックメソッドはモデルオブジェクトをパラメータとして受け取れるようになります。これでこのコールバッククラスをモデルで使用できます。

```ruby
class PictureFile < ApplicationRecord
  after_destroy PictureFileCallbacks.new
end
```

コールバックをインスタンスメソッドとして宣言したので、`PictureFileCallbacks`オブジェクトを新しくインスタンス化する必要があったことにご注意ください。これは、インスタンス化されたオブジェクトの状態をコールバックメソッドで利用したい場合に特に便利です。ただし、コールバックをクラスメソッドとして宣言する方がわかりやすいこともしばしばあります。

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

トランザクションコールバック
---------------------

データベースのトランザクションが完了したときにトリガされるコールバックが2つあります。`after_commit`と`after_rollback`です。これらのコールバックは`after_save`コールバックときわめて似通っていますが、データベースの変更のコミットまたはロールバックが完了するまでトリガされない点が異なります。これらのメソッドは、Active Recordのモデルから、データベーストランザクションの一部に含まれていない外部のシステムとやりとりを行ないたい場合に特に便利です。

例として、直前の例に使用した`PictureFile`モデルで、対応するレコードがdestroyされた後にファイルを1つ削除する必要があるとしましょう。`after_destroy`コールバックの直後に何らかの例外が発生してトランザクションがロールバックすると、ファイルが削除され、モデルの一貫性が損なわれたままになります。ここで、以下のコードにある`picture_file_2`オブジェクトが無効で、`save!`メソッドがエラーを発生するとします。

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

`after_commit`コールバックを使用することで、このような場合に対応することができます。

```ruby
class PictureFile < ApplicationRecord
  after_commit :delete_picture_file_from_disk, on: [:destroy]

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

NOTE: `:on`オプションは、コールバックがトリガされる条件を指定します。`:on`オプションを指定しないと、すべてのアクションでコールバックがトリガされます。

`after_commit`コールバックは作成/更新/削除でのみ用いるのが普通であるため、それぞれのエイリアスも用意されています。

* `after_create_commit`
* `after_update_commit`
* `after_destroy_commit`

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

WARNING: `after_commit`コールバックおよび`after_rollback`コールバックは、1つのトランザクションブロック内におけるあらゆるモデルの作成/更新/destroy時に呼び出されます。これらのコールバックのいずれかで何らかの例外が発生すると、その例外のせいで以後の`after_commit`コールバックや`after_rollback`コールバックのメソッドは**実行されなくなります**。このため、もし自作のコールバックが例外を発生する可能性がある場合は、自分のコールバック内で`rescue`して適切にエラー処理を行い、他のコールバックが停止しないようにする必要があります。

WARNING: 同一のモデル内で`after_create_commit`と`after_update_commit`を両方用いると、最後に定義された方のコールバックだけが有効になり、その他はすべてオーバライドされます。

```ruby
class User < ApplicationRecord
  after_create_commit :log_user_saved_to_db
  after_update_commit :log_user_saved_to_db

  private
  def log_user_saved_to_db
    puts 'User was saved to database'
  end
end

# 何も出力されない
>> @user = User.create

# @userを更新する
>> @user.save
=> User was saved to database
```

`create`アクションのコールバックと`update`アクションのコールバックを両方とも登録するには、代わりに`after_commit`を使います。

```ruby
class User < ApplicationRecord
  after_commit :log_user_saved_to_db, on: [:create, :update]
end
```
