Active Record と PostgreSQL
============================

本ガイドでは、PostgreSQL特有のActive Record利用法について解説します。

このガイドの内容:

* PostgreSQLのデータ型の利用法
* UUID主キーの利用法
* インデックスにキー以外のカラムを含める方法
* deferrable（延期可能）外部キーの利用方法
* 一意制約の利用方法
* 排他制約の実装方法
* PostgreSQLで全文検索を実装する方法
* Active Recordモデルでデータベースビューを使う方法

--------------------------------------------------------------------------------

PostgreSQLアダプタを利用するには、PostgreSQL 9.3以上がインストールされている必要があります。これより古いバージョンはサポートされません。

PostgreSQLを使う場合は、『[Rails アプリケーションを設定する][configuring]』ガイドをお読みください。Active RecordをPostgreSQL向けに正しくセットアップする方法が記載されています。

[configuring]: configuring.html

データ型
---------

PostgreSQLにはさまざまな種類の[データ型（datatype）][datatype]があります。以下はPostgreSQLアダプタでサポートされているデータ型のリストです。

[datatype]: https://www.postgresql.jp/document/current/html/datatype.html
### `bytea`（バイナリデータ）

* [データ型の定義][datatype_binary]
* [関数と演算子][functions_binarystring]

```ruby
# db/migrate/20140207133952_create_documents.rb
create_table :documents do |t|
  t.binary 'payload'
end
```

```ruby
# app/models/document.rb
class Document < ApplicationRecord
end
```

```ruby
# 利用法
data = File.read(Rails.root + "tmp/output.pdf")
Document.create payload: data
```

[datatype_binary]: https://www.postgresql.jp/document/current/html/datatype-binary.html
[functions_binarystring]: https://www.postgresql.jp/document/current/html/functions-binarystring.html

### 配列

* [データ型の定義][arrays]
* [関数と演算子][functions_array]

```ruby
# db/migrate/20140207133952_create_books.rb
create_table :books do |t|
  t.string 'title'
  t.string 'tags', array: true
  t.integer 'ratings', array: true
end
add_index :books, :tags, using: 'gin'
add_index :books, :ratings, using: 'gin'
```

```ruby
# app/models/book.rb
class Book < ApplicationRecord
end
```

```ruby
# 利用法
Book.create title: "Brave New World",
            tags: ["fantasy", "fiction"],
            ratings: [4, 5]

## 1個のタグに対応するBooks
Book.where("'fantasy' = ANY (tags)")

## 複数のタグに対応するBooks
Book.where("tags @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])

## ratingが3以上のBooks
Book.where("array_length(ratings, 1) >= 3")
```

[arrays]: https://www.postgresql.jp/document/current/html/arrays.html
[functions_array]: https://www.postgresql.jp/document/current/html/functions-array.html

### `hstore`（キーバリューに相当）

* [データ型の定義][hstore]
* [関数と演算子][hstore_1_11_7]

NOTE: hstoreを使うには`hstore`拡張を有効にする必要があります。

```ruby
# db/migrate/20131009135255_create_profiles.rb
class CreateProfiles < ActiveRecord::Migration[7.0]
  enable_extension 'hstore' unless extension_enabled?('hstore')
  create_table :profiles do |t|
    t.hstore 'settings'
  end
end
```

```ruby
# app/models/profile.rb
class Profile < ApplicationRecord
end
```

```irb
irb> Profile.create(settings: { "color" => "blue", "resolution" => "800x600" })

irb> profile = Profile.first
irb> profile.settings
=> {"color"=>"blue", "resolution"=>"800x600"}

irb> profile.settings = {"color" => "yellow", "resolution" => "1280x1024"}
irb> profile.save!

irb> Profile.where("settings->'color' = ?", "yellow")
=> #<ActiveRecord::Relation [#<Profile id: 1, settings: {"color"=>"yellow", "resolution"=>"1280x1024"}>]>
```

[hstore]: https://www.postgresql.jp/document/current/html/hstore.html
[hstore_1_11_7]: https://www.postgresql.jp/document/current/html/hstore.html#id-1.11.7.26.5

### JSONとJSONB

* [データ型の定義][datatype_json]
* [関数と演算子][functions_json]

```ruby
# db/migrate/20131220144913_create_events.rb
# ... jsonデータ型の場合:
create_table :events do |t|
  t.json 'payload'
end
# ... jsonbデータ型の場合:
create_table :events do |t|
  t.jsonb 'payload'
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```irb
irb> Event.create(payload: { kind: "user_renamed", change: ["jack", "john"]})

irb> event = Event.first
irb> event.payload
=> {"kind"=>"user_renamed", "change"=>["jack", "john"]}

## JSONドキュメントに基づくクエリ
# ->演算子は元のJSONデータ型を返す（オブジェクトの可能性がある）が、
# ->>はテキストを返す
irb> Event.where("payload->>'kind' = ?", "user_renamed")
```

[datatype_json](https://www.postgresql.jp/document/current/html/datatype-json.html)
[functions_json](https://www.postgresql.jp/document/current/html/functions-json.html)

### 範囲型（range）

* [データ型の定義][rangetypes]
* [関数と演算子][functions_rang]

このデータ型はRubyの[`Range`][]オブジェクトに対応付けられます。

```ruby
# db/migrate/20130923065404_create_events.rb
create_table :events do |t|
  t.daterange 'duration'
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```irb
irb> Event.create(duration: Date.new(2014, 2, 11)..Date.new(2014, 2, 12))

irb> event = Event.first
irb> event.duration
=> Tue, 11 Feb 2014...Thu, 13 Feb 2014

## 指定の日付の全イベント
irb> Event.where("duration @> ?::date", Date.new(2014, 2, 12))

## 範囲の境界を指定
irb> event = Event.select("lower(duration) AS starts_at").select("upper(duration) AS ends_at").first

irb> event.starts_at
=> Tue, 11 Feb 2014
irb> event.ends_at
=> Thu, 13 Feb 2014
```

[rangetypes]: https://www.postgresql.jp/document/current/html/rangetypes.html
[functions_rang]: https://www.postgresql.jp/document/current/html/functions-range.html
[`Range`]: https://docs.ruby-lang.org/ja/latest/class/Range.html

### 複合型（composite type）

* [データ型の定義][rowtypes]

現在は複合型について特別なサポートはありません。これらは通常のtextカラムに対応付けられます。

```sql
CREATE TYPE full_address AS
(
  city VARCHAR(90),
  street VARCHAR(90)
);
```

```ruby
# db/migrate/20140207133952_create_contacts.rb
execute <<-SQL
  CREATE TYPE full_address AS
  (
    city VARCHAR(90),
    street VARCHAR(90)
  );
SQL
create_table :contacts do |t|
  t.column :address, :full_address
end
```

```ruby
# app/models/contact.rb
class Contact < ApplicationRecord
end
```

```irb
irb> Contact.create address: "(Paris,Champs-Élysées)"
irb> contact = Contact.first
irb> contact.address
=> "(Paris,Champs-Élysées)"
irb> contact.address = "(Paris,Rue Basse)"
irb> contact.save!
```

[rowtypes]: https://www.postgresql.jp/document/current/html/rowtypes.html

### 列挙型（enumerated type）

* [データ型の定義][datatype_enum]

この型は、通常のtextカラムまたは[`ActiveRecord::Enum`][ActiveRecord::Enum]に対応付けられます。

```ruby
# db/migrate/20131220144913_create_articles.rb
def up
  create_enum :article_status, ["draft", "published", "archived"]

  create_table :articles do |t|
    t.enum :status, enum_type: :article_status, default: "draft", null: false
  end
end
```

enum型を作成して既存のテーブルにenumカラムを追加することも可能です。

```ruby
# db/migrate/20230113024409_add_status_to_articles.rb
def change
  create_enum :article_status, ["draft", "published", "archived"]

  add_column :articles, :status, :enum, enum_type: :article_status, default: "draft", null: false
end
```

上のマイグレーションはどちらも可逆的ですが、必要に応じて`#up`メソッドと`#down`メソッドに分けて定義することも可能です。カラムをDROPするときは、必ずenum型に依存しているカラムやテーブルを先に削除してください。

```ruby
def down
  drop_table :articles

  # または: remove_column :articles, :status
  drop_enum :article_status
end
```

モデル内でenum属性を宣言するとヘルパーメソッドが追加され、クラスのインスタンスに無効な値を代入できなくなります。

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  enum :status, {
    draft: "draft", published: "published", archived: "archived"
  }, prefix: true
end
```

```irb
irb> article = Article.create
irb> article.status
=> "draft" # default status from PostgreSQL, as defined in migration above

irb> article.status_published!
irb> article.status
=> "published"

irb> article.status_archived?
=> false

irb> article.status = "deleted"
ArgumentError: 'deleted' is not a valid status
```

enumの名前をリネームするには、`rename_enum`を利用して、モデルの使用方法も更新します。

```ruby
# db/migrate/20150718144917_rename_article_status.rb
def change
  rename_enum :article_status, to: :article_state
end
```

enumに新しい値を追加するには、`add_enum_value`を利用します。

```ruby
# db/migrate/20150720144913_add_new_state_to_articles.rb
def up
  add_enum_value :article_state, "archived" # "published"の後、最終的にこれになる
  add_enum_value :article_state, "in review", before: "published"
  add_enum_value :article_state, "approved", after: "in review"
end
```

NOTE: enum値は削除できません。これは、`add_enum_value`が可逆的ではない（ロールバックできない）ということでもあります。理由については[ここ](https://www.postgresql.org/message-id/29F36C7C98AB09499B1A209D48EAA615B7653DBC8A@mail2a.alliedtesting.com)を参照してください。

enum値をリネームするには、`rename_enum_value`を利用します。

```ruby
# db/migrate/20150722144915_rename_article_state.rb
def change
  rename_enum_value :article_state, from: "archived", to: "deleted"
end
```

HINT: 現在のenumにある値をすべて表示するには、`bin/rails db`または`psql`コンソールで以下のクエリを実行できます。

```sql
SELECT n.nspname AS enum_schema,
       t.typname AS enum_name,
       e.enumlabel AS enum_value
  FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
```

[datatype_enum]: https://www.postgresql.jp/document/current/html/datatype-enum.html
[ActiveRecord::Enum]: https://api.rubyonrails.org/classes/ActiveRecord/Enum.html
[ALTER_TYPE]: https://www.postgresql.jp/document/current/html/sql-altertype.html

### UUID

* [データ型の定義][datatype_uuid]
* [pgcryptoのジェネレータ関数][pgcrypto]
* [uuid-osspのジェネレータ関数][uuid_ossp]

NOTE: バージョン13.0より前のPostgreSQLを使っている場合は、UUIDを利用するために特別な拡張機能を有効にする必要が生じる場合があります。`pgcrypto`拡張機能（PostgreSQL 9.4以上）または`uuid-ossp`拡張機能 (それ以前のバージョン) を有効にしてください。

```ruby
# db/migrate/20131220144913_create_revisions.rb
create_table :revisions do |t|
  t.uuid :identifier
end
```

```ruby
# app/models/revision.rb
class Revision < ApplicationRecord
end
```

```irb
irb> Revision.create identifier: "A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11"

irb> revision = Revision.first
irb> revision.identifier
=> "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
```

`uuid`型を用いて、マイグレーションファイル内で以下のように参照を定義できます。

```ruby
# db/migrate/20150418012400_create_blog.rb
enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
create_table :posts, id: :uuid

create_table :comments, id: :uuid do |t|
  # t.belongs_to :post, type: :uuid
  t.references :post, type: :uuid
end
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments
end
```

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
end
```

UUIDを主キーとして利用する方法について詳しくは[後述](#uuid主キー)します。

[datatype_uuid]: https://www.postgresql.jp/document/current/html/datatype-uuid.html
[pgcrypto]: https://www.postgresql.jp/document/current/html/pgcrypto.html
[uuid_ossp]: https://www.postgresql.jp/document/current/html/uuid-ossp.html

### ビット列データ型（bit string type）

* [データ型の定義][datatype_bit]
* [関数と演算子][functions_bitstring]

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users, force: true do |t|
  t.column :settings, "bit(8)"
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
end
```

```irb
irb> User.create settings: "01010011"
irb> user = User.first
irb> user.settings
=> "01010011"
irb> user.settings = "0xAF"
irb> user.settings
=> "10101111"
irb> user.save!
```

[datatype_bit]: https://www.postgresql.jp/document/current/html/datatype-bit.html
[functions_bitstring]: https://www.postgresql.jp/document/current/html/functions-bitstring.html

### ネットワークアドレス型

* [データ型の定義][datatype-net-types]

`inet`型および`cidr`型は、Rubyの[`IPAddr`][IPAddr]オブジェクトに対応付けられます。`macaddr`型は通常のtextデータ型に対応付けられます。

```ruby
# db/migrate/20140508144913_create_devices.rb
create_table(:devices, force: true) do |t|
  t.inet 'ip'
  t.cidr 'network'
  t.macaddr 'address'
end
```

```ruby
# app/models/device.rb
class Device < ApplicationRecord
end
```

```irb
irb> macbook = Device.create(ip: "192.168.1.12", network: "192.168.2.0/24", address: "32:01:16:6d:05:ef")

irb> macbook.ip
=> #<IPAddr: IPv4:192.168.1.12/255.255.255.255>

irb> macbook.network
=> #<IPAddr: IPv4:192.168.2.0/255.255.255.0>

irb> macbook.address
=> "32:01:16:6d:05:ef"
```

[datatype_net_types]: https://www.postgresql.jp/document/current/html/datatype-net-types.html
[IPAddr]: https://docs.ruby-lang.org/ja/latest/class/IPAddr.html

### 幾何データ型（geometric type）

* [データ型の定義][datatype_geometric]

`point`を除くすべての幾何データ型は、通常のtextデータ型に対応付けられます。`point`は、`x`座標と`y`座標を含む配列にキャストされます。

[datatype_geometric]: https://www.postgresql.jp/document/current/html/datatype-geometric.html
### 期間（interval）

* [データ型の定義][datatype_datetime]
* [関数と演算子][functions_datetime]

このデータ型は[`ActiveSupport::Duration`][ActiveSupport::Duration]オブジェクトに対応付けられます。

```ruby
# db/migrate/20200120000000_create_events.rb
create_table :events do |t|
  t.interval 'duration'
end
```

```ruby
# app/models/event.rb
class Event < ApplicationRecord
end
```

```irb
irb> Event.create(duration: 2.days)

irb> event = Event.first
irb> event.duration
=> 2 days
```

[datatype_datetime]: https://www.postgresql.jp/document/current/html/datatype-datetime.html#DATATYPE-INTERVAL-INPUT
[functions_datetime]: https://www.postgresql.jp/document/current/html/functions-datetime.html
[ActiveSupport::Duration]: https://api.rubyonrails.org/classes/ActiveSupport/Duration.html

UUID主キー
-----------------

NOTE: ランダムなUUIDを生成するには、`pgcrypto`拡張（PostgreSQL9.4以降）または`uuid-ossp`拡張を有効にする必要があります。

```ruby
# db/migrate/20131220144913_create_devices.rb
enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
create_table :devices, id: :uuid do |t|
  t.string :kind
end
```

```ruby
# app/models/device.rb
class Device < ApplicationRecord
end
```

```ruby
irb> device = Device.create
irb> device.id
=> "814865cd-5a1d-4771-9306-4268f188fe9e"
```

NOTE: `pgcrypto`の`gen_random_uuid()`関数は、`create_table`に`:default`オプションが渡されていないことを前提としています。

UUIDを主キーとするテーブルに対してRailsのモデルジェネレータを実行するには、モデルジェネレータに以下のように`--primary-key-type=uuid`を渡します。

```bash
$ rails generate model Device --primary-key-type=uuid kind:string
```

このUUIDを参照する外部キーを持つモデルを構築する場合は、以下のように`uuid`をネイティブのフィールドタイプとして扱ってください。

```bash
$ rails generate model Case device_id:uuid
```

インデックス化
--------

* [インデックス作成方法](https://www.postgresql.jp/document/14/html/sql-createindex.html)

PostgreSQLには豊富なインデックスオプションがあります。PostgreSQLアダプタでは、[よく使われるインデックスオプション][common index options]に加えて以下のオプションもサポートされています。

[common index options]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index

### `:include`オプション

新しいインデックスの作成時に、`:include`オプションでキー以外のカラムも含めることが可能です。
これらのキーは検索時のインデックススキャンで使われませんが、インデックスのみのスキャンでは関連付けされたテーブルにアクセスせずに読み取ることが可能です。

```ruby
# db/migrate/20131220144913_add_index_users_on_email_include_id.rb

add_index :users, :email, include: :id
```

以下のように複数のカラムも指定できます。

```ruby
# db/migrate/20131220144913_add_index_users_on_email_include_id_and_created_at.rb

add_index :users, :email, include: [:id, :created_at]
```

生成列（generated column）
-----------------

NOTE: [生成列][ddl_generated_columns]はPostgreSQL 12.0以降でサポートされます。

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users do |t|
  t.string :name
  t.virtual :name_upcased, type: :string, as: 'upper(name)', stored: true
end

# app/models/user.rb
class User < ApplicationRecord
end

# 利用法
user = User.create(name: 'John')
User.last.name_upcased # => "JOHN"
```

[ddl_generated_columns]: https://www.postgresql.jp/document/current/html/ddl-generated-columns.html

延期可能な外部キー
-----------------------

* [foreign key table constraints][sql-set-constraints]

PostgreSQLのテーブル制約は、デフォルトでは各ステートメントの直後にチェックされます。このため、「参照されるレコードが、参照されるテーブル内にまだ存在しない」レコードを作成することは意図的に禁止されています。

外部キーの定義に`DEFERRABLE`（延期可能）を追加することで、トランザクションのコミット時にこの整合性チェックを後で実行可能にできます。デフォルトですべてのチェックを延期するには、`DEFERRABLE INITIALLY DEFERRED`に設定できます。

Railsでは、`add_reference`メソッドや`add_foreign_key`メソッドの`foreign_key`オプションに`:deferrable`キーを追加することで、このPostgreSQLの機能を利用できます。

例として、外部キーを作成してもトランザクションに循環依存が形成されてしまう場合を考えてみましょう。

```ruby
add_reference :person, :alias, foreign_key: { deferrable: :deferred }
add_reference :alias, :person, foreign_key: { deferrable: :deferred }
```

参照先を`foreign_key: true`オプションで作成した場合、以下のトランザクションは最初の`INSERT`文を実行すると失敗します。ただし、`deferrable: :deferred`オプションが設定されている場合は失敗しません。

```ruby
ActiveRecord::Base.connection.transaction do
  person = Person.create(id: SecureRandom.uuid, alias_id: SecureRandom.uuid, name: "John Doe")
  Alias.create(id: person.alias_id, person_id: person.id, name: "jaydee")
end
```

`deferrable`オプションには`:immediate`も指定可能です。これを指定すると、外部キーが制約を即座にチェックするデフォルトの振る舞いは変わりませんが、トランザクション内で`set_constraints`を指定することでチェックを手動で延期できます。これにより、トランザクションがコミットされたタイミングで外部キーがチェックされるようになります。

```ruby
ActiveRecord::Base.connection.transaction do
  ActiveRecord::Base.connection.set_constraints(:deferred)
  person = Person.create(alias_id: SecureRandom.uuid, name: "John Doe")
  Alias.create(id: person.alias_id, person_id: person.id, name: "jaydee")
end
```

`:deferrable`のデフォルトは`false`で、制約は常に直ちにチェックされます。

[sql_set_constraints]: https://www.postgresql.jp/document/current/html/sql-set-constraints.html

一意制約
-----------------

* [一意性制約](https://www.postgresql.jp/document/14/html/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS)

```ruby
# db/migrate/20230422225213_create_items.rb
create_table :items do |t|
  t.integer :position, null: false
  t.unique_constraint [:position], deferrable: :immediate
end
```

既存の一意インデックス（unique index）をdeferrable（延期可能）に変更したい場合は、`:using_index`を指定することでdeferrableな一意制約を作成できます。

```ruby
add_unique_constraint :items, deferrable: :deferred, using_index: "index_items_on_position"
```

外部キーと同様に、一意制約は`:deferrable`を`:immediate`または`:deferred`のいずれかに設定することで延期できます。`:deferrable`はデフォルトでは`false`で、制約は常に即座にチェックされます。

排他制約
---------------------

* [排他制約](https://www.postgresql.jp/document/14/html/ddl-constraints.html#DDL-CONSTRAINTS-EXCLUSION)

```ruby
# db/migrate/20131220144913_create_products.rb
create_table :products do |t|
  t.integer :price, null: false
  t.daterange :availability_range, null: false

  t.exclusion_constraint "price WITH =, availability_range WITH &&", using: :gist, name: "price_check"
end
```

外部キーと同様に、排他制約（exclusion constraints）は`:deferrable`を`:immediate`または`:deferred`のいずれかに設定することで延期できます。`:deferrable`はデフォルトでは`false`で、制約は常に即座にチェックされます。

全文検索
----------------

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string :title
  t.string :body
end

add_index :documents, "to_tsvector('english', title || ' ' || body)", using: :gin, name: 'documents_idx'
```

```ruby
# app/models/document.rb
class Document < ApplicationRecord
end
```

```ruby
# Usage
Document.create(title: "Cats and Dogs", body: "are nice!")

## 'cat & dog'にマッチするすべてのドキュメント
Document.where("to_tsvector('english', title || ' ' || body) @@ to_tsquery(?)",
                 "cat & dog")
```

オプションで、このベクタを自動生成カラムとして保存することも可能です（PostgreSQL 12.0以降）。

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string :title
  t.string :body

  t.virtual :textsearchable_index_col,
            type: :tsvector, as: "to_tsvector('english', title || ' ' || body)", stored: true
end

add_index :documents, :textsearchable_index_col, using: :gin, name: 'documents_idx'

# 利用法
Document.create(title: "Cats and Dogs", body: "are nice!")

## 'cat & dog'にマッチするすべてのドキュメント
Document.where("textsearchable_index_col @@ to_tsquery(?)", "cat & dog")
```

データベースビュー（database view）
--------------

* [`CREATE VIEW`][CREATE_VIEW]

以下のテーブルを含むレガシーデータベースを扱う必要があるとします。

```
rails_pg_guide=# \d "TBL_ART"
                                        Table "public.TBL_ART"
   Column   |            Type             |                         Modifiers
------------+-----------------------------+------------------------------------------------------------
 INT_ID     | integer                     | not null default nextval('"TBL_ART_INT_ID_seq"'::regclass)
 STR_TITLE  | character varying           |
 STR_STAT   | character varying           | default 'draft'::character varying
 DT_PUBL_AT | timestamp without time zone |
 BL_ARCH    | boolean                     | default false
Indexes:
    "TBL_ART_pkey" PRIMARY KEY, btree ("INT_ID")
```

このテーブルはRailsの規約にまったく従っていません。
PostgreSQLのシンプルなビュー（view）はデフォルトで更新可能なので、以下のようにラップできます。

```ruby
# db/migrate/20131220144913_create_articles_view.rb
execute <<-SQL
CREATE VIEW articles AS
  SELECT "INT_ID" AS id,
         "STR_TITLE" AS title,
         "STR_STAT" AS status,
         "DT_PUBL_AT" AS published_at,
         "BL_ARCH" AS archived
  FROM "TBL_ART"
  WHERE "BL_ARCH" = 'f'
SQL
```

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  self.primary_key = "id"
  def archive!
    update_attribute :archived, true
  end
end
```

```irb
irb> first = Article.create! title: "Winter is coming", status: "published", published_at: 1.year.ago
irb> second = Article.create! title: "Brace yourself", status: "draft", published_at: 1.month.ago

irb> Article.count
=> 2
irb> first.archive!
irb> Article.count
=> 1
```

NOTE: このアプリケーションは、`archive`されていない`Articles`のみを扱う前提です。ビューには条件を設定可能なので、`archive`された`Articles`を直接除外できます。

[`CREATE_VIEW`]: https://www.postgresql.jp/document/current/html/sql-createview.html

Structure Dumpについて
--------------

Railsの`config.active_record.schema_format`を`:sql`に設定すると、`pg_dump`を呼び出してstructure dumpを生成します。

`ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags`で`pg_dump`を設定できます。たとえば、structure dumpでコメントを除外したい場合は、イニシャライザに以下を追加します。

```ruby
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ["--no-comments"]
```