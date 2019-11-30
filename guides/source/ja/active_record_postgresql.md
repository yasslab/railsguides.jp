**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Record と PostgreSQL
============================

このガイドでは、PostgreSQLに特化したActive Recordの利用法について説明します。

このガイドの内容:

* PostgreSQLのデータ型の使い方
* UUID主キーの使い方
* PostgreSQLで全文検索を実装する方法
* Active Recordモデルで「データベースビュー」をサポートする方法

> **訳注: 本ガイドにおける「ビュー」は、PostgreSQLの「データベースビュー」を指します。**

--------------------------------------------------------------------------------

PostgreSQLアダプタを利用する場合、PostgreSQLバージョン9.1以上が必要です。これより古いバージョンはサポートされません。

PostgreSQLを使う方は、[Rails アプリケーションを設定する](configuring.html#postgresqlデータベースを設定する)ガイドをご覧ください。Active RecordをPostgreSQL向けに正しく設定する方法が記載されています。

データ型
---------

PostgreSQLには固有のデータ型（datatype）が多数提供されています。PostgreSQLアダプタでサポートされるデータ型を以下にリストアップします。

### bytea（バイナリ列）

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-binary.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/functions-binarystring.html)

```ruby
# db/migrate/20140207133952_create_documents.rb
create_table :documents do |t|
  t.binary 'payload'
end

# app/models/document.rb
class Document < ApplicationRecord
end

# Usage
data = File.read(Rails.root + "tmp/output.pdf")
Document.create payload: data
```

### 配列

* [型の定義](https://www.postgresql.jp/document/current/html/arrays.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/functions-array.html)

```ruby
# db/migrate/20140207133952_create_books.rb
create_table :books do |t|
  t.string 'title'
  t.string 'tags', array: true
  t.integer 'ratings', array: true
end
add_index :books, :tags, using: 'gin'
add_index :books, :ratings, using: 'gin'

# app/models/book.rb
class Book < ApplicationRecord
end

# Usage
Book.create title: "Brave New World",
            tags: ["fantasy", "fiction"],
            ratings: [4, 5]

## 1つのタグに対応する本
Book.where("'fantasy' = ANY (tags)")

## 複数タグに対応する本
Book.where("tags @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])

## ratingが3以上の本
Book.where("array_length(ratings, 1) >= 3")
```

### hstore

* [型の定義](https://www.postgresql.jp/document/current/html/hstore.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/hstore.html#AEN179902)

NOTE: hstoreを使うには、`hstore`拡張をオンにする必要があります。

```ruby
# db/migrate/20131009135255_create_profiles.rb
ActiveRecord::Schema.define do
  enable_extension 'hstore' unless extension_enabled?('hstore')
  create_table :profiles do |t|
    t.hstore 'settings'
  end
end

# app/models/profile.rb
class Profile < ApplicationRecord
end

# Usage
Profile.create(settings: { "color" => "blue", "resolution" => "800x600" })

profile = Profile.first
profile.settings # => {"color"=>"blue", "resolution"=>"800x600"}

profile.settings = {"color" => "yellow", "resolution" => "1280x1024"}
profile.save!

Profile.where("settings->'color' = ?", "yellow")
# => #<ActiveRecord::Relation [#<Profile id: 1, settings: {"color"=>"yellow", "resolution"=>"1280x1024"}>]>
```

### JSONとJSONB

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-json.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/functions-json.html)

```ruby
# db/migrate/20131220144913_create_events.rb
# ... for json datatype:
create_table :events do |t|
  t.json 'payload'
end
# ... or for jsonb datatype:
create_table :events do |t|
  t.jsonb 'payload'
end

# app/models/event.rb
class Event < ApplicationRecord
end

# Usage
Event.create(payload: { kind: "user_renamed", change: ["jack", "john"]})

event = Event.first
event.payload # => {"kind"=>"user_renamed", "change"=>["jack", "john"]}

## JSONドキュメントベースのクエリ
# ->演算子は元のJSON型を返す（オブジェクトの可能性がある）
# ->>ならテキストを返す
Event.where("payload->>'kind' = ?", "user_renamed")
```

### 範囲型

* [型の定義](https://www.postgresql.jp/document/current/html/rangetypes.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/functions-range.html)

この型は、Rubyの[`Range`](https://docs.ruby-lang.org/ja/latest/class/Range.html)オブジェクトにマッピングされます。

```ruby
# db/migrate/20130923065404_create_events.rb
create_table :events do |t|
  t.daterange 'duration'
end

# app/models/event.rb
class Event < ApplicationRecord
end

# 使い方
Event.create(duration: Date.new(2014, 2, 11)..Date.new(2014, 2, 12))

event = Event.first
event.duration # => Tue, 11 Feb 2014...Thu, 13 Feb 2014

## 指定の日のすべての行事
Event.where("duration @> ?::date", Date.new(2014, 2, 12))

## 範囲を絞った操作
event = Event.
  select("lower(duration) AS starts_at").
  select("upper(duration) AS ends_at").first

event.starts_at # => Tue, 11 Feb 2014
event.ends_at # => Thu, 13 Feb 2014
```

### 複合型（composite type）

* [型の定義](https://www.postgresql.jp/document/current/html/rowtypes.html)

現時点では複合型に特化したサポートはありません。複合型は、通常のテキストカラムにマッピングされます。

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

# app/models/contact.rb
class Contact < ApplicationRecord
end

# 使い方
Contact.create address: "(Paris,Champs-Élysées)"
contact = Contact.first
contact.address # => "(Paris,Champs-Élysées)"
contact.address = "(Paris,Rue Basse)"
contact.save!
```

### 列挙型（enumrated type）

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-enum.html)

現時点では列挙型に特化したサポートはありません。複合型は、通常のテキストカラムにマッピングされます。

```ruby
# db/migrate/20131220144913_create_articles.rb
def up
  execute <<-SQL
    CREATE TYPE article_status AS ENUM ('draft', 'published');
  SQL
  create_table :articles do |t|
    t.column :status, :article_status
  end
end

# メモ: enumをドロップする前にテーブルをドロップすることが重要
def down
  drop_table :articles

  execute <<-SQL
    DROP TYPE article_status;
  SQL
end

# app/models/article.rb
class Article < ApplicationRecord
end

# 使い方
Article.create status: "draft"
article = Article.first
article.status # => "draft"

article.status = "published"
article.save!
```

既存の値の直前または直後に新しい値を追加する場合は、[ALTER TYPE](https://www.postgresql.jp/document/current/html/sql-altertype.html)を使うべきです。


```ruby
# db/migrate/20150720144913_add_new_state_to_articles.rb
# メモ: ALTER TYPE 〜 ADD VALUEはトランザクションブロック内では
# 実行できませんので、disable_ddl_transaction!を使っています
disable_ddl_transaction!

def up
  execute <<-SQL
    ALTER TYPE article_status ADD VALUE IF NOT EXISTS 'archived' AFTER 'published';
  SQL
end
```

NOTE: ENUM値は現在ドロップできません。理由については[こちら](https://www.postgresql.org/message-id/29F36C7C98AB09499B1A209D48EAA615B7653DBC8A@mail2a.alliedtesting.com)をご覧ください。

HINT: 現在あるすべてのenumについてすべての値を表示するには、`bin/rails db`または`psql`で以下のクエリを呼ぶべきです。

```sql
SELECT n.nspname AS enum_schema,
       t.typname AS enum_name,
       e.enumlabel AS enum_value
  FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
```

### UUID

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-uuid.html)
* [pgcrypto生成関数](https://www.postgresql.jp/document/current/html/pgcrypto.html#AEN182570)
* [uuid-ossp生成関数](https://www.postgresql.jp/document/current/html/uuid-ossp.html)

NOTE: UUIDを使うには、`pgcrypto`拡張（PostgreSQL 9.4以上）または`uuid=ossp`拡張を有効にする必要があります。

```ruby
# db/migrate/20131220144913_create_revisions.rb
create_table :revisions do |t|
  t.uuid :identifier
end

# app/models/revision.rb
class Revision < ApplicationRecord
end

# 使い方
Revision.create identifier: "A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11"

revision = Revision.first
revision.identifier # => "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
```

`uuid`型は、マイグレーション内で参照の定義に使えます。

```ruby
# db/migrate/20150418012400_create_blog.rb
enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
create_table :posts, id: :uuid, default: 'gen_random_uuid()'

create_table :comments, id: :uuid, default: 'gen_random_uuid()' do |t|
  # t.belongs_to :post, type: :uuid
  t.references :post, type: :uuid
end

# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
end
```

UUIDについて詳しくは、[UUID主キー](#uuid主キー)のセクションを参照してください。

### ビット列（bit string）データ型

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-bit.html)
* [関数と演算子](https://www.postgresql.jp/document/current/html/functions-bitstring.html)

> 訳注: bit stringはビット列またはビット文字列と訳されているようです。

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users, force: true do |t|
  t.column :settings, "bit(8)"
end

# app/models/device.rb
class User < ApplicationRecord
end

# 使い方
User.create settings: "01010011"
user = User.first
user.settings # => "01010011"
user.settings = "0xAF"
user.settings # => 10101111
user.save!
```

### ネットワークアドレス型

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-net-types.html)

この型である`idet`や`cdir`は、[`IPAddr`](https://docs.ruby-lang.org/ja/latest/class/IPAddr.html)オブジェクトにマッピングされます。`macaddr`型は通常のテキストにマッピングされます。

```ruby
# db/migrate/20140508144913_create_devices.rb
create_table(:devices, force: true) do |t|
  t.inet 'ip'
  t.cidr 'network'
  t.macaddr 'address'
end

# app/models/device.rb
class Device < ApplicationRecord
end

# 使い方
macbook = Device.create(ip: "192.168.1.12",
                        network: "192.168.2.0/24",
                        address: "32:01:16:6d:05:ef")

macbook.ip
# => #<IPAddr: IPv4:192.168.1.12/255.255.255.255>

macbook.network
# => #<IPAddr: IPv4:192.168.2.0/255.255.255.0>

macbook.address
# => "32:01:16:6d:05:ef"
```

### 幾何（geometric）データ型

* [型の定義](https://www.postgresql.jp/document/current/html/datatype-geometric.html)

`points`の例外を持つすべての幾何データ型は、通常のテキストにマッピングされます。
1つの点は、`x`座標と`y`座標を含む1つの配列にキャストされます。

UUID主キー
-----------------

NOTE: ランダムなUUIDを生成するには、`pgcrypto`拡張（PostgreSQL 9.4以上）または`uuid=ossp`拡張を有効にする必要があります。

```ruby
# db/migrate/20131220144913_create_devices.rb
enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
create_table :devices, id: :uuid, default: 'gen_random_uuid()' do |t|
  t.string :kind
end

# app/models/device.rb
class Device < ApplicationRecord
end

# 使い方
device = Device.create
device.id # => "814865cd-5a1d-4771-9306-4268f188fe9e"
```

NOTE: `pgcrypto`の`gen_random_uuid()`は、`create_table`に`:default`オプションが何も渡されていないことを前提としています。

全文検索
----------------

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string 'title'
  t.string 'body'
end

add_index :documents, "to_tsvector('english', title || ' ' || body)", using: :gin, name: 'documents_idx'

# app/models/document.rb
class Document < ApplicationRecord
end

# 使い方
Document.create(title: "Cats and Dogs", body: "are nice!")

## 'cat & dog'にマッチするすべてのドキュメント
Document.where("to_tsvector('english', title || ' ' || body) @@ to_tsquery(?)",
                 "cat & dog")
```

データベースビュー
--------------

* [CREATE VIEW](https://www.postgresql.jp/document/current/html/sql-createview.html)

以下のテーブルを含むレガシーなデータベースを使う必要が生じたとします。

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

このテーブルはRailsの慣習にまったく従っていません。PostgreSQLの単純なビューはデフォルトではアップデート不可なので、次のようにラップできます。

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

# app/models/article.rb
class Article < ApplicationRecord
  self.primary_key = "id"
  def archive!
    update_attribute :archived, true
  end
end

# 使い方
first = Article.create! title: "Winter is coming",
                        status: "published",
                        published_at: 1.year.ago
second = Article.create! title: "Brace yourself",
                         status: "draft",
                         published_at: 1.month.ago

Article.count # => 2
first.archive!
Article.count # => 1
```

NOTE: このアプリケーションでは、アーカイブされてない`Articles`のみを扱います。データベースビューでは、アーカイブされた`Articles`ディレクトリを除外する条件も使えます。
