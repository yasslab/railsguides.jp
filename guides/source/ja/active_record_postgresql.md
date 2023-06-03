Active Record と PostgreSQL
============================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Active Record and PostgreSQL](https://guides.rubyonrails.org/active_record_postgresql.html)を日本語に翻訳した文書です。

本ガイドでは、PostgreSQL特有のActive Record利用法について解説します。

このガイドの内容:

* PostgreSQLのデータ型の利用法
* UUID主キーの利用法
* PostgreSQLで全文検索を実装する方法
* Active Recordモデルでデータベースビューを使う方法

--------------------------------------------------------------------------------

PostgreSQLアダプタを利用するには、PostgreSQL 9.3以上がインストールされている必要があります。これより古いバージョンはサポートされません。

PostgreSQLを使う場合は、『[Rails アプリケーションを設定する](https://railsguides.jp/configuring.html)』ガイドをお読みください。Active RecordをPostgreSQL向けに正しくセットアップする方法が記載されています。

データ型
---------

PostgreSQLにはさまざまな種類の[データ型（datatype）](https://www.postgresql.jp/document/13/html/datatype.html)があります。以下はPostgreSQLアダプタでサポートされているデータ型のリストです。

### `bytea`（バイナリデータ）

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-binary.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-binarystring.html)

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

### 配列

* [データ型の定義](https://www.postgresql.jp/document/13/html/arrays.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-array.html)

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

### `hstore`（キーバリューに相当）

* [データ型の定義](https://www.postgresql.jp/document/13/html/hstore.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/hstore.html#id-1.11.7.26.5)

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

### JSONとJSONB

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-json.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-json.html)

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

### 範囲型（range）

* [データ型の定義](https://www.postgresql.jp/document/13/html/rangetypes.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-range.html)

このデータ型はRubyの[`Range`](https://docs.ruby-lang.org/ja/latest/class/Range.html)オブジェクトに対応付けられます。

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

### 複合型（composite type）

* [データ型の定義](https://www.postgresql.jp/document/13/html/rowtypes.html)

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

### 列挙型（enumerated type）

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-enum.html)

この型は、通常のtextカラムまたは[`ActiveRecord::Enum`](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)に対応付けられます。

```ruby
# db/migrate/20131220144913_create_articles.rb
def up
  create_enum :article_status, ["draft", "published"]

  create_table :articles do |t|
    t.enum :status, enum_type: :article_status, default: "draft", null: false
  end
end

# enumの削除機能はRailsに組み込まれていないが、手動での削除は可能
# 依存するテーブルを最初にすべて削除しておくこと
def down
  drop_table :articles

  execute <<-SQL
    DROP TYPE article_status;
  SQL
end
```

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  enum status: {
    draft: "draft", published: "published"
  }, _prefix: true
end
```

```irb
irb> Article.create status: "draft"
irb> article = Article.first
irb> article.status
=> "draft"

irb> article.status = "published"
irb> article.save!
```

既存の値の前または後に新しい値を追加する場合は、[`ALTER TYPE`](https://www.postgresql.jp/document/13/html/sql-altertype.html)を使うこと。

```ruby
# db/migrate/20150720144913_add_new_state_to_articles.rb
# メモ: ALTER TYPE ... ADD VALUEはトランザクションブロック内では実行できないので、
# ここではdisable_ddl_transaction!を利用
disable_ddl_transaction!

def up
  execute <<-SQL
    ALTER TYPE article_status ADD VALUE IF NOT EXISTS 'archived' AFTER 'published';
  SQL
end
```

NOTE: `ENUM`の値は`DROP`できません。理由については[この記事](https://www.postgresql.org/message-id/29F36C7C98AB09499B1A209D48EAA615B7653DBC8A@mail2a.alliedtesting.com)を参照してください。

Hint: 現在のenumにある値をすべて表示するには、クエリを`bin/rails db`または`psql`で実行できます。

```sql
SELECT n.nspname AS enum_schema,
       t.typname AS enum_name,
       e.enumlabel AS enum_value
  FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
```

### UUID

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-uuid.html)
* [pgcryptoのジェネレータ関数](https://www.postgresql.jp/document/13/html/pgcrypto.html)
* [uuid-osspのジェネレータ関数](https://www.postgresql.jp/document/13/html/uuid-ossp.html)

NOTE: `uuid`を使うには、`pgcrypto`拡張（PostgreSQL 9.4以降のみ）または`uuid-ossp`拡張を有効にする必要があります。

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

### ビット列データ型（bit string type）

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-bit.html)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-bitstring.html)

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

### ネットワークアドレス型

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-net-types.html)

`inet`型および`cidr`型は、Rubyの[`IPAddr`](https://docs.ruby-lang.org/ja/latest/class/IPAddr.html)オブジェクトに対応付けられます。`macaddr`型は通常のtextデータ型に対応付けられます。

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

### 幾何データ型（geometric type）

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-geometric.html)

`point`を除くすべての幾何データ型は、通常のtextデータ型に対応付けられます。`point`は、`x`座標と`y`座標を含む配列にキャストされます。

### 期間（interval）

* [データ型の定義](https://www.postgresql.jp/document/13/html/datatype-datetime.html#DATATYPE-INTERVAL-INPUT)
* [関数と演算子](https://www.postgresql.jp/document/13/html/functions-datetime.html)

このデータ型は[`ActiveSupport::Duration`](https://api.rubyonrails.org/classes/ActiveSupport/Duration.html)オブジェクトに対応付けられます。

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

生成列（generated column）
-----------------

NOTE: [生成列](https://www.postgresql.jp/document/13/html/ddl-generated-columns.html)はPostgreSQL 12.0以降でサポートされます。

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

* [`CREATE VIEW`](https://www.postgresql.jp/document/13/html/sql-createview.html)

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

Structure Dumpについて
--------------

Railsの`config.active_record.schema_format`を`:sql`に設定すると、`pg_dump`を呼び出してstructure dumpを生成します。

`ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags`で`pg_dump`を設定できます。たとえば、structure dumpでコメントを除外したい場合は、イニシャライザに以下を追加します。

```ruby
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ['--no-comments']
```