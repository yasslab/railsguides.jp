Active Record コールバック
=======================

このガイドでは、Active Recordオブジェクトのライフサイクルにフックをかける方法について説明します。

このガイドの内容:

* Active Recordオブジェクトのどのライフサイクルでどのイベントが発生するか
* それらのイベントに応答するコールバックを登録・実行・スキップする方法
* リレーション/関連付け/条件付き/トランザクションのコールバックを作成する方法
* コールバックを再利用するためのオブジェクトを作成する方法

--------------------------------------------------------------------------------

オブジェクトのライフサイクル
---------------------

Railsアプリケーションの通常の操作中に、オブジェクトが[作成・更新・破棄](active_record_basics.html#crud-データの読み書き)されることがあります。Active Recordは、このオブジェクトのライフサイクルへのフックを提供することでアプリケーションとそのデータを制御できます。

コールバックを使うと、オブジェクトの状態の変更「前」または変更「後」にロジックをトリガーできます。コールバックとは、オブジェクトのライフサイクルの特定の瞬間に呼び出されるメソッドのことです。コールバックを使えば、Active Recordオブジェクトがデータベースで初期化・作成・保存・更新・削除・バリデーション・読み込みのたびに実行されるコードを記述できます。

```ruby
class BirthdayCake < ApplicationRecord
  after_create -> { Rails.logger.info("Congratulations, the callback has run!") }
end
```

```irb
irb> BirthdayCake.create
Congratulations, the callback has run!
```

このように、ライフサイクルにはさまざまなイベントがあり、イベントの「前」「後」「前後」のフックするさまざまなオプションがあります。

コールバックを登録する
------------------

利用可能なコールバックを使うには、コールバックを実装して登録する必要があります。コールバックの実装は、通常のメソッド、ブロック、procを利用したり、クラスまたはモジュールでカスタムコールバックオブジェクトを定義するなど、さまざまな方法で行えます。これらの実装手法をそれぞれ見ていきましょう。

コールバックを登録するために、**通常のメソッドを呼び出すマクロ形式のクラスメソッド**を実装用に利用できます。

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation :ensure_username_has_value

  private
    def ensure_username_has_value
      if username.blank?
        self.username = email
      end
    end
end
```

**このマクロスタイルのクラスメソッドはブロックも受け取れます**。以下のようにコールバックしたいコードがきわめて短く、1行に収まるような場合にこのスタイルを検討しましょう。

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation do
    self.username = email if username.blank?
  end
end
```

以下のように、**コールバックにprocを渡してトリガー*させる*ことも可能です。

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation ->(user) { user.username = user.email if user.username.blank? }
end
```

最後に、独自の[カスタムコールバックオブジェクト](#コールバックオブジェクト)も定義できます。これについては後述します。

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation AddUsername
end

class AddUsername
  def self.before_validation(record)
    if record.username.blank?
      record.username = record.email
    end
  end
end
```

### ライフサイクルイベントで実行されるコールバックを登録する

コールバックは、特定のライフサイクルイベントでのみ実行されるように登録することも可能です。`:on`オプションを指定することで、コールバックがいつ、どのようなコンテキストでトリガーされるかを完全に制御できます。

NOTE: コンテキスト（context）とは、特定のバリデーションを適用するカテゴリまたはシナリオのようなものです。Active Recordモデルをバリデーションするときに、コンテキストを指定することでバリデーションをグループ化できます。これにより、さまざまな状況に適用される多種多様なバリデーションセットを作成できます。Railsには、`:create`、`:update`、`:save`などのバリデーション用コンテキストがデフォルトで用意されています。

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true

  before_validation :ensure_username_has_value, on: :create

  # :onは配列も受け取れる
  after_validation :set_location, on: [ :create, :update ]

  private
    def ensure_username_has_value
      if username.blank?
        self.username = email
      end
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

NOTE: コールバックはprivateメソッドとして宣言するのが好ましい方法です。コールバックメソッドがpublicな状態のままだと、このメソッドがモデルの外から呼び出され、オブジェクトのカプセル化の原則に違反する可能性があります。

WARNING: コールバックメソッド内では、`update`や`save`などのメソッドや、オブジェクトに副作用を引き起こすその他のメソッド呼び出しは避けてください。<br><br>たとえば、コールバック内で`update(attribute: "value")`を呼び出してはいけません。この方法はモデルの状態を変更してしまい、コミット中に思わぬ副作用を引き起こす可能性があります。<br><br>代わりに、より安全なアプローチとして、`before_create`、`before_update`、またはそれ以前のタイミングでトリガーされるコールバックを使えば安全に値を直接代入できます（例: `self.attribute = "value"`）。

利用可能なコールバック
-------------------

Active Recordで利用可能なコールバックの一覧を以下に示します。これらのコールバックは、**実際の操作中に呼び出される順序に並んでいます**。

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

この2つのコールバックについて詳しくは、[`after_commit`と`after_rollback`セクション](#after-commitコールバックとafter-rollbackコールバック)を参照してください。

[`after_create`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_create
[`after_commit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_commit
[`after_rollback`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_rollback
[`after_save`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_save
[`after_validation`]:
    https://api.rubyonrails.org/classes/ActiveModel/Validations/Callbacks/ClassMethods.html#method-i-after_validation
[`around_create`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_create
[`around_save`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_save
[`before_create`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_create
[`before_save`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_save
[`before_validation`]:
    https://api.rubyonrails.org/classes/ActiveModel/Validations/Callbacks/ClassMethods.html#method-i-before_validation

これらのコールバックの利用方法を示す例を以下に示します。コールバックは関連する操作ごとにグループ化されており、最後に組み合わせて使う方法を示します。

#### バリデーション時のコールバック

バリデーション時のコールバックは、レコードが[`valid?`](https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-valid-3F)（またはエイリアスの[`validate`](https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-validate)）、または[`invalid?`](https://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-invalid-3F)メソッドで直接バリデーションされるか、もしくは`create`、`update`、`save`で間接的にバリデーションされるたびにトリガーされます。これらはバリデーションフェーズの直前（`before_validation`）または直後（`after_validation`）に呼び出されます。

```ruby
class User < ApplicationRecord
  validates :name, presence: true
  before_validation :titleize_name
  after_validation :log_errors

  private
    def titleize_name
      self.name = name.downcase.titleize if name.present?
      Rails.logger.info("Name titleized to #{name}")
    end

    def log_errors
      if errors.any?
        Rails.logger.error("Validation failed: #{errors.full_messages.join(', ')}")
      end
    end
end
```

```irb
irb> user = User.new(name: "", email: "john.doe@example.com", password: "abc123456")
=> #<User id: nil, email: "john.doe@example.com", created_at: nil, updated_at: nil, name: "">
irb> user.valid?
Name titleized to
Validation failed: Name can't be blank
=> false
```

#### 保存時のコールバック

保存時のコールバックは、レコードが`create`、`update`、または`save`メソッドで背後のデータベースに永続化（保存）されるたびにトリガーされます。これらは、オブジェクトが保存される直前（`before_save`）、保存された直後（`after_save`）、および保存の直前直後（`around_save`）に呼び出せます。

```ruby
class User < ApplicationRecord
  before_save :hash_password
  around_save :log_saving
  after_save :update_cache

  private
    def hash_password
      self.password_digest = BCrypt::Password.create(password)
      Rails.logger.info("Password hashed for user with email: #{email}")
    end

    def log_saving
      Rails.logger.info("Saving user with email: #{email}")
      yield
      Rails.logger.info("User saved with email: #{email}")
    end

    def update_cache
      Rails.cache.write(["user_data", self], attributes)
      Rails.logger.info("Update Cache")
    end
end
```

```irb
irb> user = User.create(name: "Jane Doe", password: "password", email: "jane.doe@example.com")
Password encrypted for user with email: jane.doe@example.com
Saving user with email: jane.doe@example.com
User saved with email: jane.doe@example.com
Update Cache
=> #<User id: 1, email: "jane.doe@example.com", created_at: "2024-03-20 16:02:43.685500000 +0000", updated_at: "2024-03-20 16:02:43.685500000 +0000", name: "Jane Doe">
```

#### 作成時のコールバック

作成時のコールバックは、レコードが背後のデータベースに**初めて**保存されるたびに、つまり、`create` または `save` メソッドで新規レコードを保存するときにトリガーされます。これらは、オブジェクトが作成される直前（`before_create`）、作成された直後（`after_create`）、および作成の直前直後（`around_create`）に呼び出されます。

```ruby
class User < ApplicationRecord
  before_create :set_default_role
  around_create :log_creation
  after_create :send_welcome_email

  private
    def set_default_role
      self.role = "user"
      Rails.logger.info("User role set to default: user")
    end

    def log_creation
      Rails.logger.info("Creating user with email: #{email}")
      yield
      Rails.logger.info("User created with email: #{email}")
    end

    def send_welcome_email
      UserMailer.welcome_email(self).deliver_later
      Rails.logger.info("User welcome email sent to: #{email}")
    end
end
```

```irb
irb> user = User.create(name: "John Doe", email: "john.doe@example.com")
User role set to default: user
Creating user with email: john.doe@example.com
User created with email: john.doe@example.com
User welcome email sent to: john.doe@example.com
=> #<User id: 10, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe">
```

### オブジェクトの更新

更新時のコールバックは、**既存の**レコードが背後のデータベースで永続化（保存）されるたびにトリガーされます。これらは、オブジェクトが更新される直前、更新された直後、および更新の直前直後に呼び出されます。

* [`before_validation`][]
* [`after_validation`][]
* [`before_save`][]
* [`around_save`][]
* [`before_update`][]
* [`around_update`][]
* [`after_update`][]
* [`after_save`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_update`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_update
[`around_update`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_update
[`before_update`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_update

WARNING: `after_save`コールバックは`create`と`update`の両方で実行されますが、マクロ呼び出しの実行順序にかかわらず、常に`after_create`や`after_update`という特定のコールバックよりも**後**に呼び出されます。同様に、保存前と保存前後のコールバックも同じルールに従います。`before_save`は作成・更新よりも**前**に実行され、`around_save`は作成・更新操作の**直前直後**で実行されます。保存コールバックは常に、より具体的な作成・更新コールバックの直前/直前直後/直後に実行されることに注意しておくことが重要です。

[バリデーション時のコールバック](#バリデーション時のコールバック)と[保存時のコールバック](#保存時のコールバック)については既に説明しました。これら2つのコールバックの利用例については、[`after_commit`と`after_rollback`](#after-commitコールバックとafter-rollbackコールバック)セクションを参照してください。

#### 更新時のコールバック

```ruby
class User < ApplicationRecord
  before_update :check_role_change
  around_update :log_updating
  after_update :send_update_email

  private
    def check_role_change
      if role_changed?
        Rails.logger.info("User role changed to #{role}")
      end
    end

    def log_updating
      Rails.logger.info("Updating user with email: #{email}")
      yield
      Rails.logger.info("User updated with email: #{email}")
    end

    def send_update_email
      UserMailer.update_email(self).deliver_later
      Rails.logger.info("Update email sent to: #{email}")
    end
end
```

```irb
irb> user = User.find(1)
=> #<User id: 1, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe", role: "user" >
irb> user.update(role: "admin")
User role changed to admin
Updating user with email: john.doe@example.com
User updated with email: john.doe@example.com
Update email sent to: john.doe@example.com
```

#### コールバックを組み合わせる

欲しい振る舞いを実現するには、コールバックを組み合わせて使う必要が生じることがよくあります。たとえば、ユーザーが作成された後に確認メールを送信したいが、そのユーザーが新規で更新されていない場合のみ確認メールを送信したい場合や、ユーザー更新時に重要な情報が変更された場合は管理者に通知したい場合があります。

この場合、`after_create`コールバックと`after_update`コールバックを組み合わせて使えます。

```ruby
class User < ApplicationRecord
  after_create :send_confirmation_email
  after_update :notify_admin_if_critical_info_updated

  private
    def send_confirmation_email
      UserMailer.confirmation_email(self).deliver_later
      Rails.logger.info("Confirmation email sent to: #{email}")
    end

    def notify_admin_if_critical_info_updated
      if saved_change_to_email? || saved_change_to_phone_number?
        AdminMailer.user_critical_info_updated(self).deliver_later
        Rails.logger.info("Notification sent to admin about critical info update for: #{email}")
      end
    end
end
```

```irb
irb> user = User.create(name: "John Doe", email: "john.doe@example.com")
Confirmation email sent to: john.doe@example.com
=> #<User id: 1, email: "john.doe@example.com", ...>
irb> user.update(email: "john.doe.new@example.com")
Notification sent to admin about critical info update for: john.doe.new@example.com
=> true
```

### オブジェクトの破棄

破棄（destroy）時のコールバックは、レコードが破棄されるたびにトリガーされますが、レコードが削除（delete）されるときは無視されます。破棄時のコールバックは、オブジェクトが破棄される直前（`before_destroy`）、破棄された直後（`after_destroy`）、および破棄される直前直後（`around_destroy`）に呼び出されます。

* [`before_destroy`][]
* [`around_destroy`][]
* [`after_destroy`][]
* [`after_commit`][] / [`after_rollback`][]

[`after_destroy`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_destroy
[`around_destroy`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-around_destroy
[`before_destroy`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-before_destroy

利用例については、[`after_commit`と`after_rollback`](#after-commitコールバックとafter-rollbackコールバック).を参照してください。

#### 破棄時のコールバック

```ruby
class User < ApplicationRecord
  before_destroy :check_admin_count
  around_destroy :log_destroy_operation
  after_destroy :notify_users

  private
    def check_admin_count
      if admin? && User.where(role: "admin").count == 1
        throw :abort
      end
      Rails.logger.info("Checked the admin count")
    end

    def log_destroy_operation
      Rails.logger.info("About to destroy user with ID #{id}")
      yield
      Rails.logger.info("User with ID #{id} destroyed successfully")
    end

    def notify_users
      UserMailer.deletion_email(self).deliver_later
      Rails.logger.info("Notification sent to other users about user deletion")
    end
end
```

```irb
irb> user = User.find(1)
=> #<User id: 1, email: "john.doe@example.com", created_at: "2024-03-20 16:19:52.405195000 +0000", updated_at: "2024-03-20 16:19:52.405195000 +0000", name: "John Doe", role: "admin">

irb> user.destroy
Checked the admin count
About to destroy user with ID 1
User with ID 1 destroyed successfully
Notification sent to other users about user deletion
```

### `after_initialize`と`after_find`

[`after_initialize`][]コールバックは、Active Recordオブジェクトが`new`で直接インスタンス化されるたびに、またはレコードがデータベースから読み込まれるたびに呼び出されます。これを利用すれば、Active Recordの`initialize`メソッドを直接オーバーライドせずに済みます。

[`after_find`][]コールバックは、Active Recordがデータベースからレコードを1件読み込むたびに呼び出されます。`after_find`と`after_initialize`が両方定義されている場合は、`after_find`が先に呼び出されます。

NOTE: `after_initialize`と`after_find`コールバックには、対応する`before_*`メソッドはありません。

これらも、他のActive Recordコールバックと同様に登録できます

```ruby
class User < ApplicationRecord
  after_initialize do |user|
    Rails.logger.info("オブジェクトは初期化されました")
  end

  after_find do |user|
    Rails.logger.info("オブジェクトが見つかりました")
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

[`after_find`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_find
[`after_initialize`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_initialize

### `after_touch`

[`after_touch`][]コールバックは、Active Recordオブジェクトがtouchされるたびに呼び出されます。詳しくはAPIドキュメントの[`touch`](https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-touch)を参照してください。

```ruby
class User < ApplicationRecord
  after_touch do |user|
    Rails.logger.info("オブジェクトにtouchしました")
  end
end
```

```irb
user = User.create(name: "Kuldeep")
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

irb> user.touch
オブジェクトにtouchしました
=> true
```

このコールバックは`belongs_to`と併用できます。

```ruby
class Book < ApplicationRecord
  belongs_to :library, touch: true
  after_touch do
    Rails.logger.info("Bookがtouchされました")
  end
end

class Library < ApplicationRecord
  has_many :books
  after_touch :log_when_books_or_library_touched

  private
    def log_when_books_or_library_touched
      Rails.logger.info("Book/Libraryがtouchされました")
    end
end
```

```irb
irb> book = Book.last
=> #<Book id: 1, library_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

irb> book.touch # book.library.touchがトリガーされる
Bookがtouchされました
Book/Libraryがtouchされました
=> true
```

[`after_touch`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Callbacks/ClassMethods.html#method-i-after_touch

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
* `update_attribute!`
* `update`
* `update!`
* `valid?`
* `validate`

また、`after_find`コールバックは以下のfinderメソッドを実行すると呼び出されます。

* `all`
* `first`
* `find`
* `find_by`
* `find_by!`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`
* `sole`
* `take`

`after_initialize`コールバックは、そのクラスの新しいオブジェクトが初期化されるたびに呼び出されます。

NOTE: `find_by_*`メソッドと`find_by_*!`メソッドは、属性ごとに自動的に生成される動的なfinderメソッドです。詳しくは[動的finderのセクション](active_record_querying.html#動的検索)を参照してください。

条件付きコールバック
---------------------

[バリデーション](active_record_validations.html)のときと同様に、指定された述語の条件を満たす場合に実行されるコールバックメソッドの呼び出しも作成可能です。これを行なうには、コールバックで`:if`オプションまたは`:unless`オプションを使います。このオプションはシンボル、`Proc`、または`Array`を引数に取ります。

特定の状況でのみコールバックを**呼び出す必要がある**場合は、`:if`オプションを使います。
特定の状況でコールバックを**呼び出してはならない**場合は、`:unless`オプションを使います。

### `:if`および`:unless`オプションでシンボルを使う

`:if`オプションまたは`:unless`オプションは、コールバックの直前に呼び出される述語メソッド名に対応するシンボルと関連付けることが可能です。

`:if`オプションを使う場合、述語メソッドが`false`を返せばコールバックは**実行されません**。
`:unless`オプションを使う場合、述語メソッドが`true`を返せばコールバックは**実行されません**。これはコールバックで最もよく使われるオプションです。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

この方法で登録すれば、さまざまな述語メソッドを登録して、コールバックを呼び出すべきかどうかをチェックできるようになります。詳しくは[コールバックで複数の条件を指定する](#コールバックで複数の条件を指定する)で後述します。

### `:if`および`:unless`オプションで`Proc`を使う

`:if`および`:unless`オプションでは`Proc`オブジェクトも利用できます。このオプションは、1行以内に収まるワンライナーでバリデーションを行う場合に最適です。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number,
    if: ->(order) { order.paid_with_card? }
end
```

procはそのオブジェクトのコンテキストで評価されるので、以下のように書くこともできます。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: -> { paid_with_card? }
end
```

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
    if: [:subject_to_parental_control?, -> { untrusted_author? }]
end
```

### `:if`と`:unless`を同時に使う

コールバックでは、同じ宣言の中で`:if`と`:unless`を併用できます。

```ruby
class Comment < ApplicationRecord
  before_save :filter_content,
    if: -> { forum.parental_control? },
    unless: -> { author.trusted? }
end
```

このコールバックは、すべての`:if`条件が`true`と評価され、どの`:unless`条件も`true`と評価されなかった場合にのみ実行されます。

コールバックをスキップする
------------------

[バリデーション](active_record_validations.html)の場合と同様、以下のメソッドを使うことでコールバックをスキップできます。

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

`User`モデルの`before_save`コールバックがユーザーのメールアドレスの変更を記録する場合を考えてみましょう。

```ruby
class User < ApplicationRecord
  before_save :log_email_change

  private
    def log_email_change
      if email_changed?
        Rails.logger.info("Email changed from #{email_was} to #{email}")
      end
    end
end
```

ここで、メールアドレスの変更を記録する`before_save`コールバックをトリガーせずにユーザーのメールアドレスを更新したいというシナリオがあるとします。これは`update_columns`メソッドを使えば可能です。

```irb
irb> user = User.find(1)
irb> user.update_columns(email: 'new_email@example.com')
```

上は、`before_save`コールバックをトリガーせずにユーザーのメールアドレスを更新しています。

WARNING: コールバックには、スキップしてはならない重要なビジネスルールやアプリケーションロジックが設定されている可能性もあるので、これらのメソッドの利用には十分注意すべきです。この点を理解せずにコールバックをバイパスすると、データの不整合が発生する可能性があります。

[`decrement!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-decrement-21
[`decrement_counter`]:
    https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-decrement_counter
[`delete`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-delete
[`delete_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-delete_all
[`delete_by`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-delete_by
[`increment!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-increment-21
[`increment_counter`]:
    https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html#method-i-increment_counter
[`insert`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert
[`insert!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert-21
[`insert_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all
[`insert_all!`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all-21
[`touch_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-touch_all
[`update_column`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_column
[`update_columns`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_columns
[`update_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_all
[`update_counters`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_counters
[`upsert`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert
[`upsert_all`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert_all

コールバックを抑制する
---------------------

特定のシナリオでは、Railsアプリケーション内で特定のコールバックの実行を一時的に抑制しなければならなくなる場合があります。これは、コールバックを恒久的に無効にせずに、特定の操作で特定のアクションをスキップしたい場合に便利です。

Railsは、[`ActiveRecord::Suppressor`モジュール](https://api.rubyonrails.org/classes/ActiveRecord/Suppressor.html)でコールバックを抑制する（suppress）メカニズムを提供しています。コールバックを抑制したいコードブロックをこのモジュールでラップすれば、その特定の操作中はコールバックが実行されないようにできます。

`User`モデルがあり、新規ユーザーがサインアップした後に「ようこそメール」を送信するコールバックがモデルに含まれているシナリオを考えてみましょう。ただし、ようこそメールを送信せずにユーザーを作成しなければならない場合もあります（データベースにテストデータをシードするときなど）。


```ruby
class User < ApplicationRecord
  after_create :send_welcome_email

  def send_welcome_email
    puts "Welcome email sent to #{self.email}"
  end
end
```

この例の`after_create`コールバックは、新しいユーザーが作成されるたびに`send_welcome_email`メソッドをトリガーします。

ようこそメールを送信せずにユーザーを作成するには、次のように`ActiveRecord::Suppressor`モジュールを利用します。

```ruby
User.suppress do
  User.create(name: "Jane", email: "jane@example.com")
end
```

上記のコードでは、`User.suppress`ブロックによって、"Jane"ユーザーの作成中は`send_welcome_email`コールバックが実行されないようにし、ようこそメールを送信せずにユーザーを作成できるようにしています。

WARNING: `ActiveRecord::Suppressor`を利用すると、コールバックの実行を選択的に制御できるメリットがある反面、コードが複雑になって思わぬ振る舞いが発生する可能性もあります。コールバックを抑制すると、アプリケーションで意図したフローがわかりにくくなり、今後のコードベースの理解やメンテナンスが困難になる可能性があります。コールバックを抑制した場合の影響の大きさを慎重に検討し、ドキュメント作成やテストを入念に実施して、意図しない副作用やパフォーマンスの問題、テストの失敗のリスクを軽減する必要があります。

コールバックを停止する
-----------------

モデルに新しくコールバックを登録すると、コールバックは実行キューに入ります。このキューには、あらゆるモデルに対するバリデーション、登録済みコールバック、実行待ちのデータベース操作が置かれます。

コールバックチェーン全体は、1つのトランザクションにラップされます。コールバックの1つで例外が発生すると、実行チェーン全体が停止（halt）して**ロールバック**が発行され、エラーが再度raiseします。

```ruby
class Product < ActiveRecord::Base
  before_validation do
    raise "Price can't be negative" if total_price < 0
  end
end

Product.create # "Price can't be negative"がraiseする
```

これによって、`create`や`save`などのメソッドで例外が発生することが想定されていないコードが、予期せず壊れます。

NOTE: コールバックチェインの途中で例外が発生した場合は、`ActiveRecord::Rollback`または`ActiveRecord::RecordInvalid`例外でない限り、Railsは例外を再度raiseします。代わりに`throw :abort`を用いてコールバックチェインを意図的に停止する必要があります。いずれかのコールバックが`:abort`をスローすると、プロセスは中止し、`create`はfalseを返します。

```ruby
class Product < ActiveRecord::Base
  before_validation do
    throw :abort if total_price < 0
  end
end

Product.create # => false
```

ただし、（`create`ではなく）`create!`を呼び出した場合は`ActiveRecord::RecordNotSaved`が発生します。この例外は、コールバックの中断によりレコードが保存されなかったことを示します。

```ruby
User.create! # => raises an ActiveRecord::RecordNotSaved
```

`throw :abort`がdestroy系のコールバックで呼び出された場合は、`destroy`はfalseを返します。

```ruby
class User < ActiveRecord::Base
  before_destroy do
    throw :abort if still_active?
  end
end

User.first.destroy # => false
```

ただし、（`destroy`ではなく）`destroy!`を呼び出した場合は`ActiveRecord::RecordNotDestroyed`が発生します。

```ruby
User.first.destroy! # => raises an ActiveRecord::RecordNotDestroyed
```

関連付けのコールバック
---------------------

関連付けのコールバックは通常のコールバックと似ていますが、コレクションのライフサイクル内で発生するイベントによってトリガーされる点が異なります。利用可能な関連付けコールバックは以下のとおりです。

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

関連付けのコールバックは、関連付けの宣言でオプションを追加することでを定義できます。

`Author`モデルに`has_many :books`が定義されている例を考えてみましょう。ただし、`authors`コレクションに本を追加する前に、その著者が本の個数制限に達していないことを確認する必要があります。個数制限を確認するための`before_add`コールバックを追加することで、これを実行できます。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: :check_limit

  private
    def check_limit
      if books.count >= 5
        errors.add(:base, "この著者には本を5冊までしか追加できません")
        throw(:abort)
      end
    end
end
```

`before_add`コールバックが`:abort`をスローした場合、オブジェクトはコレクションに追加されません。

関連付けられているオブジェクトに対して複数の操作を実行したい場合があります。この場合はコールバックを配列として渡せば、単一のイベントに複数のコールバックを積み上げられます。 さらにRailsは、追加または削除されるオブジェクトをコールバックに渡して利用可能にしてくれます。

```ruby
class Author < ApplicationRecord
  has_many :books, before_add: [:check_limit, :calculate_shipping_charges]

  def check_limit
    if books.count >= 5
      errors.add(:base, "この著者には本を5冊までしか追加できません")
      throw(:abort)
    end
  end

  def calculate_shipping_charges(book)
    weight_in_pounds = book.weight_in_pounds || 1
    shipping_charges = weight_in_pounds * 2

    shipping_charges
  end
end
```

同様に、`before_remove`コールバックが`:abort`をスローした場合、オブジェクトはコレクションから削除されません。

NOTE: これらのコールバックは、関連付けられているオブジェクトが関連付けコレクションを通じて追加・削除された場合にのみ呼び出されます。

```ruby
# `before_add`コールバックがトリガーされる
author.books << book
author.books = [book, book2]

# `before_add`コールバックはトリガーされない
book.update(author_id: 1)
```

関連付けのコールバックをカスケードする
-------------------------------

コールバックは、関連付けられたオブジェクトが変更されたタイミングで実行できます。コールバックはモデルの関連付けを通じて機能し、ライフサイクルイベントが関連付けにカスケードする形でコールバックを起動できます。

`User`モデルに`has_many :articles`が定義されている例を考えてみましょう。ユーザーが破棄（destroy）された場合、そのユーザーの記事も合わせて破棄する必要があります。`Article`モデルへの関連付けを介して、`User`モデルに `after_destroy`コールバックを追加してみましょう。

```ruby
class User < ApplicationRecord
  has_many :articles, dependent: :destroy
end

class Article < ApplicationRecord
  after_destroy :log_destroy_action

  def log_destroy_action
    Rails.logger.info("Article destroyed")
  end
end
```

```irb
irb> user = User.first
=> #<User id: 1>
irb> user.articles.create!
=> #<Article id: 1, user_id: 1>
irb> user.destroy
Article destroyed
=> #<User id: 1>
```

WARNING: `before_destroy`コールバックを使う場合は、レコードが`dependent: :destroy`で削除される前に実行されるように、`dependent: :destroy`関連付けの前に配置する（または`prepend: true`オプションを指定する）必要があります。

トランザクションのコールバック
---------------------

### `after_commit`コールバックと`after_rollback`コールバック

データベースのトランザクションが完了したときにトリガーされるコールバックが2つあります。[`after_commit`][]と[`after_rollback`][]です。

これらのコールバックは`after_save`コールバックときわめて似ていますが、データベースの変更のコミットまたはロールバックが完了するまでトリガされない点が異なります。これらのメソッドは、Active Recordのモデルから、データベーストランザクションの一部に含まれていない外部のシステムとやりとりしたい場合に特に便利です。


例として、`PictureFile`モデルで、対応するレコードが削除された後にファイルを1つ削除する必要があるとしましょう。

```ruby
class PictureFile < ApplicationRecord
  after_destroy :delete_picture_file_from_disk

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

`after_destroy`コールバックの直後に何らかの例外が発生してトランザクションがロールバックすると、ファイルが削除され、モデルの一貫性が損なわれたままになってしまいます。
ここで、以下のコードにある`picture_file_2`オブジェクトが無効で、`save!`メソッドがエラーを発生するとします。

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

NOTE: `:on`オプションは、コールバックがトリガされるタイミングを指定します。`:on`オプションを指定しないと、すべてのアクションでコールバックがトリガされます。詳しくは[`:on`の利用方法](#ライフサイクルイベントで実行されるコールバックを登録する)を参照してください。

トランザクションが完了すると、そのトランザクション内で作成・更新・破棄されたすべてのモデルに対して`after_commit`コールバックまたは`after_rollback`コールバックが呼び出されます。ただし、これらのコールバックのいずれかで例外が発生した場合、その例外はバブルアップされ、残りの`after_commit`や`after_rollback`メソッドは実行されません。

```ruby
class User < ActiveRecord::Base
  after_commit { raise "Intentional Error" }
  after_commit {
    # 1つ上のafter_commitで例外が発生するため、これは呼び出されない
    Rails.logger.info("This will not be logged")
  }
end
```

WARNING: コールバックコードで例外が発生した場合は、他のコールバック実行が中断されないよう、その例外を`rescue`してコールバック内で処理する必要があります。

`after_commit`の保証は、`after_save`や`after_update`や`after_destroy`とはまったく異なる保証です。たとえば、以下の`after_save`で例外が発生した場合、トランザクションはロールバックし、データは保持されません。

```ruby
class User < ActiveRecord::Base
  after_save do
    # これが失敗したらユーザーは保存されない
    EventLog.create!(event: "user_saved")
  end
end
```

しかし、データは`after_commit`中に既にデータベースに保存されているため、例外が発生しても何もロールバックしなくなります。

```ruby
class User < ActiveRecord::Base
  after_commit do
    # これが失敗したらユーザーは既に保存済み
    EventLog.create!(event: "user_saved")
  end
end
```

`after_commit`コールバックや`after_rollback`コールバック内で実行されるコード自体は、トランザクション内に囲まれません。

データベース内の同じレコードを単一のトランザクションのコンテキストで表現する場合、`after_commit`コールバックや`after_rollback`コールバックで注意すべき重要な動作があります。これらのコールバックは、トランザクション内で変更される**特定のレコードの最初のオブジェクトに対してのみトリガーされます**。読み込まれている他のオブジェクトは、同じデータベースレコードを表現しているにもかかわらず、`after_commit`コールバックや`after_rollback`コールバックはどのオブジェクトでもトリガーされません。

```ruby
class User < ApplicationRecord
  after_commit :log_user_saved_to_db, on: :update

  private
    def log_user_saved_to_db
      Rails.logger.info("ユーザーはデータベースに保存されました")
    end
end
```

```irb
irb> user = User.create
irb> User.transaction { user.save; user.save }
# ユーザーはデータベースに保存されました
```

WARNING: この微妙な振る舞いは、同じデータベースレコードに関連付けられている個別のオブジェクトに対して独立したコールバック実行が予想されるシナリオで、特に大きな影響を及ぼします。コールバックシーケンスのフローや予測可能性に影響し、そのトランザクションの後のアプリケーションロジックに不整合が生じる可能性があります。

### `after_commit`コールバックのエイリアス

`after_commit`コールバックは作成・更新・削除でのみ用いることが多いので、それぞれのエイリアスも用意されています。場合によっては、`create`と`update`の両方に単一のコールバックを使わなければならなくなることもあります。これらの操作の一般的なエイリアスを次に示します。

* [`after_destroy_commit`][]
* [`after_create_commit`][]
* [`after_update_commit`][]
* [`after_save_commit`][]

いくつか例を見てみましょう。

以下は、`on`オプションを指定した`after_commit`を`destroy`に使っています。

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

上と同じことを`after_destroy_commit`を使ってもできます。

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

同じ要領で`after_create_commit`や`after_update_commit`も使えます。

ただし、`after_create_commit`コールバックと`after_update_commit`コールバックに同じメソッド名を指定すると、両方とも内部的に`after_commit`にエイリアスされ、同じメソッド名で以前に定義されたコールバックをオーバーライドするため、最後に定義されたコールバックだけが有効になってしまいます。

```ruby
class User < ApplicationRecord
  after_create_commit :log_user_saved_to_db
  after_update_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      # これは1回しか呼び出されない
      Rails.logger.info("ユーザーはデータベースに保存されました")
    end
end
```

```irb
irb> user = User.create # 何も出力しない

irb> user.save          # userを更新する
ユーザーはデータベースに保存されました
```

この場合は、代わりに`after_save_commit`を使う方が適切です。これは、作成と更新の両方で`after_commit`コールバックを利用するためのエイリアスです。

```ruby
class User < ApplicationRecord
  after_save_commit :log_user_saved_to_db

  private
    def log_user_saved_to_db
      Rails.logger.info("ユーザーはデータベースに保存されました")
    end
end
```

```irb
irb> user = User.create # Userを作成
ユーザーはデータベースに保存されました

irb> user.save # userを更新
ユーザーはデータベースに保存されました
```

### トランザクショナルなコールバックの順序

Rails 7.1以降のコールバックは、デフォルトでは定義された順序で実行されます。

```ruby
class User < ActiveRecord::Base
  after_commit { Rails.logger.info("これは1番目に実行される") }
  after_commit { Rails.logger.info("これは2番目に実行される") }
end
```

ただし、それより前のバージョンのRailsでは、トランザクショナルな`after_`コールバック（`after_commit`、`after_rollback` など）を複数定義すると、コールバックの実行順序が定義と逆順になりました。

何らかの理由で引き続き逆順に実行したい場合は、以下の設定を`false`に設定することで、コールバックが逆順で実行されます。詳しくは、[Active Recordの設定オプション](configuring.html#config-active-record-run-after-transaction-callbacks-in-order-defined)を参照してください。

```ruby
config.active_record.run_after_transaction_callbacks_in_order_defined = false
```

NOTE: これは、`after_destroy_commit`などを含むすべての`after_*_commit`コールバックに適用されます。

[`after_create_commit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_create_commit
[`after_destroy_commit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_destroy_commit
[`after_save_commit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_save_commit
[`after_update_commit`]:
    https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_update_commit

コールバックオブジェクト
----------------

作成したコールバックメソッドが便利なので、他のモデルで再利用したくなる場合があります。Active Recordでは、コールバックメソッドをカプセル化するクラスを作成することでコールバックを再利用可能にできます。

以下は、ファイルシステム上で破棄したファイルのクリーンアップを処理する`after_commit`コールバッククラスの例です。この振る舞いは`PictureFile`モデルに固有とは限らず、他でも共有したい場合もあるため、これを別のクラスにカプセル化することをオススメします。こうすることで、この振る舞いのテストや変更がずっと簡単になります。

```ruby
class FileDestroyerCallback
  def after_commit(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

クラス内で上記のように宣言すると、コールバックメソッドはモデルオブジェクトをパラメーターとして受け取ります。これは次のように、そのクラスを利用するすべてのモデルで機能します。

```ruby
class PictureFile < ApplicationRecord
  after_commit FileDestroyerCallback.new
end
```

ここではコールバックをインスタンスメソッドとして宣言しているので、`FileDestroyerCallback`オブジェクトを`new`でインスタンス化する必要があることにご注意ください。これは、コールバックがインスタンス化されたオブジェクトのステートを利用する場合に特に便利です。ただし多くの場合、以下のようにコールバックをクラスメソッドとして宣言する方が合理的です。

```ruby
class FileDestroyerCallback
  def self.after_commit(file)
    if File.exist?(file.filepath)
      File.delete(file.filepath)
    end
  end
end
```

コールバックメソッドがこのようにクラスメソッドとして宣言されていれば、モデル内で`FileDestroyerCallback`オブジェクトを`new`でインスタンス化せずに済みます。

```ruby
class PictureFile < ApplicationRecord
  after_commit FileDestroyerCallback
end
```

コールバックオブジェクト内では、コールバックを必要なだけいくつでも宣言できます。
