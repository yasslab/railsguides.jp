Active Record の基礎
====================

このガイドではActive Recordの基礎について説明します。

このガイドの内容:

* ORM (オブジェクト/リレーショナルマッピング) とActive Recordについて、およびRailsでの利用方法
* Active RecordとMVC (Model-View-Controller)パラダイムの親和性
* Active Recordモデルを使用してリレーショナルデータベースに保存されたデータを操作する
* Active Recordスキーマにおける名前付けルール
* データベースのマイグレーション、バリデーション(検証)、コールバック

--------------------------------------------------------------------------------

Active Recordについて
----------------------

Active Recordとは、[MVC](https://ja.wikipedia.org/wiki/Model_View_Controller)で言うところのM、つまりモデルに相当するものであり、ビジネスデータとビジネスロジックを表すシステムの階層です。Active Recordは、データベースに恒久的に保存される必要のあるビジネスオブジェクトの作成と利用を円滑に行なえるようにします。Active Recordは、ORM (オブジェクト/リレーショナルマッピング) システムに記述されている「Active Recordパターン」を実装したものであり、このパターンと同じ名前が付けられています。

### Active Recordパターン

パターン名としての[Active Record](http://www.martinfowler.com/eaaCatalog/activeRecord.html)はMartin Fowler『Patterns of Enterprise Application Architecture』という書籍で記述されました。Active Recordパターンにおいて、オブジェクトとは永続的なデータであり、そのデータに対する振る舞いでもあります。Active Recordパターンは、データアクセスのロジックを常にオブジェクトに含めておくことで、そのオブジェクトの利用者にデータベースへの読み書き方法を指示できる、という立場に立っています。

### O/Rマッピング

[オブジェクト/リレーショナルマッピング](https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E9%96%A2%E4%BF%82%E3%83%9E%E3%83%83%E3%83%94%E3%83%B3%E3%82%B0)(O/RマッピングやORMと略されることもあります)とは、アプリケーションが持つリッチなオブジェクトをリレーショナルデータベース(RDBMS)のテーブルに接続することです。ORMを用いると、SQL文を直接書く代りにわずかなアクセスコードを書くだけで、アプリケーションにおけるオブジェクトの属性やリレーションシップをデータベースに保存することもデータベースから読み出すこともできるようになります。

NOTE: [RDBMS](https://ja.wikipedia.org/wiki/%E9%96%A2%E4%BF%82%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9%E7%AE%A1%E7%90%86%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0)（リレーショナルデータベース管理システム）や[SQL](https://ja.wikipedia.org/wiki/SQL)についてまだよくわからない場合は、チュートリアル（[w3schools.com](https://www.w3schools.com/sql/default.asp)や[sqlcourse.com](http://www.sqlcourse.com/)など）やその他の方法でRDBMSやSQLを学んでからにしてください。一般に、Active RecordやRailsの理解にはリレーショナルデータベースの動作の理解が不可欠です。

### ORMフレームワークとしてのActive Record

Active Recordにはさまざまな機能が搭載されており、その中でも以下のものが特に重要です。

* モデルおよびモデル内のデータを表現する
* モデル同士の関連付け(アソシエーション)を表現する
* 関連付けられているモデル間の継承階層を表現する
* データをデータベースで永続化する前にバリデーション(検証)を行なう
* データベースをオブジェクト指向スタイルで操作する

Active RecordにおけるCoC(Convention over Configuration)
----------------------------------------------

他のプログラミング言語やフレームワークでアプリケーションを作成すると、設定のためのコードを大量に書く必要が生じがちです。一般的なORMアプリケーションでは特にこの傾向があります。しかし、Railsで採用されているルール（慣習）に従っていれば、Active Recordモデルの作成時に書かなければならない設定用コードは最小限で済みますし、設定用コードが完全に不要になることすらあります。これは「設定がほとんどの場合で共通ならば、その設定をアプリケーションのデフォルトにすべきである」という考えに基づいています。つまり、ユーザーによる明示的な設定が必要となるのは、標準のルールでは足りない場合だけです。

### 命名ルール

Active Recordには、モデルとデータベースのテーブルとのマッピング作成時に従うべきルールがいくつかあります。Railsでは、データベースのテーブル名を探索するときに、モデルのクラス名を複数形にした名前で探索します。つまり、`Book`というモデルクラスがある場合、これに対応するデータベースのテーブルは複数形の「**books**」になります。Railsの複数形化メカニズムは非常に強力で、不規則な語でも複数形/単数形に変換できます(person <-> peopleなど)。モデルのクラス名が2語以上の複合語である場合、Rubyの慣習であるキャメルケース(CamelCaseのように語頭を大文字にしてスペースなしでつなぐ)に従ってください。一方、テーブル名は(camel_caseなどのように)小文字かつアンダースコアで区切られなければなりません。以下の例を参照ください。

* データベースのテーブル - 複数形、語はアンダースコアで区切られる (例: `book_clubs`)
* モデルのクラス - 単数形、語頭を大文字にする (例: `BookClub`)

| モデル / クラス | テーブル / スキーマ |
| ------------- | -------------- |
| `Post`        | `posts`        |
| `LineItem`    | `line_items`   |
| `Deer`        | `deers`        |
| `Mouse`       | `mice`         |
| `Person`      | `people`       |


### スキーマのルール

Active Recordでは、データベースのテーブルで使うカラム名についても利用目的に応じたルールがあります。

* **外部キー** - このカラムは`テーブル名の単数形_id`にする必要があります（例: `item_id`、`order_id`）。これらのカラムは、Active Recordがモデル間の関連付けを作成するときに参照されます。

* **主キー** - デフォルトでは `id` という名前の`integer`カラムがテーブルの主キーに使われます。[Active Recordマイグレーション](active_record_migrations.html)でテーブルを作成すると、このカラムが自動的に作成されます。

他にも、Active Recordインスタンスに機能を追加するカラム名がいくつかあります。

* `created_at`: レコード作成時に現在の日付時刻が自動的に設定されます
* `updated_at`: レコード更新時に現在の日付時刻が自動的に設定されます
* `lock_version`: モデルに[optimistic locking](http://api.rubyonrails.org/classes/ActiveRecord/Locking.html)を追加します
* `type`: モデルで[Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance)を使う場合に指定します
* `関連付け名_type`: [ポリモーフィック関連付け](association_basics.html#ポリモーフィック関連付け)の種類を保存します

* `テーブル名_count`: 関連付けにおいて、所属しているオブジェクトの数をキャッシュするのに使われます。たとえば、`Article`クラスに`comments_count`というカラムがあり、そこに`Comment`のインスタンスが多数あると、ポストごとのコメント数がここにキャッシュされます。

NOTE: これらのカラム名は必須ではありませんが、Active Recordで予約されています。特別な理由のない限り、これらの予約済みカラム名の利用は避けてください。たとえば、`type`という語はテーブルでSTI（Single Table Inheritance）を指定するために予約されています。STIを使わない場合であっても、予約語より先にまず「context」などのようなモデルのデータを適切に表す語を検討してください。

Active Recordのモデルを作成する
-----------------------------

Active Recordモデルの作成は非常に簡単です。以下のように`ApplicationRecord`クラスのサブクラスを作成するだけで完了します。

```ruby
class Product < ApplicationRecord
end
```

上のコードは、`Product`モデルを作成し、データベースの`products`テーブルにマッピングされます。さらに、テーブルに含まれている各行のカラムを、作成したモデルのインスタンスの属性にマッピングします。以下のSQL文（または拡張SQLの文）で`products`テーブルを作成したとします。

```sql
CREATE TABLE products (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   PRIMARY KEY  (id)
);
```

上のテーブルスキーマは、`id`と`name`という2つのカラムがある1つのテーブルを宣言しています。このテーブルの各行が、これら2つのパラメータを持つ特定の1つの製品名を表します。これで、次のようなコードを書けるようになります。

```ruby
p = Product.new
p.name = "Some Book"
puts p.name # "Some Book"
```

命名ルールを上書きする
---------------------------------

Railsアプリケーションで別の命名ルールを使わなければならない、レガシーデータベースを用いてRailsアプリケーションを作成しないといけないなどの場合にはどうすればよいでしょうか。そんなときは、デフォルトの命名ルールを簡単にオーバーライドできます。

`ApplicationRecord`は、有用なメソッドが多数定義されている`ActiveRecord::Base`を継承しているので、使うべきテーブル名を`ActiveRecord::Base.table_name=`メソッドで明示的に指定できます。

```ruby
class Product < ApplicationRecord
  self.table_name = "PRODUCT"
end
```

テーブル名をこのように指定する場合、テストの定義では`set_fixture_class`メソッドを使い、フィクスチャ (クラス名.yml) に対応するクラス名を別途定義しておく必要があります。

```ruby
class ProductTest < ActiveSupport::TestCase
  set_fixture_class my_products: Product
  fixtures :my_products
  ...
end
```

`ActiveRecord::Base.primary_key=`メソッドを用いて、テーブルの主キーに使われるカラム名を上書きすることもできます。

```ruby
class Product < ApplicationRecord
  self.primary_key = "product_id"
end
```

CRUD: データの読み書き
------------------------------

CRUDとは、4つのデータベース操作を表す「**C**reate」「**R**ead」「**U**pdate」「**D**elete」の頭字語です。Active Recordはこれらのメソッドを自動的に作成するので、テーブルに保存されているデータをアプリケーションで操作できるようになります。

### Create

Active Recordのオブジェクトはハッシュやブロックから作成できます。また、作成後に属性を手動で追加できます。`new`メソッドを実行すると単に新しいオブジェクトが返されますが、`create`を実行すると新しいオブジェクトが返され、さらにデータベースに保存されます。

たとえば、`User`というモデルに`name`と`occupation`という属性があるとすると、`create`メソッドで新しいレコードが1つ作成され、データベースに保存されます。

```ruby
user = User.create(name: "David", occupation: "Code Artist")
```

`new`メソッドでインスタンスを作成する場合、オブジェクトは保存されません。

```ruby
user = User.new
user.name = "David"
user.occupation = "Code Artist"
```

上の場合、`user.save`を実行して初めてデータベースにレコードがコミットされます。

最後に、`create`や`new`にブロックを渡すと、そのブロックで初期化された新しいオブジェクトが`yield`されます。

```ruby
user = User.new do |u|
  u.name = "David"
  u.occupation = "Code Artist"
end
```

### Read

Active Recordは、データベース内のデータにアクセスできる高機能なAPIを提供します。以下は、Active Recordが提供するさまざまなデータアクセスメソッドのほんの一部の例です。

```ruby
# すべてのユーザーのコレクションを返す
users = User.all
```

```ruby
# 最初のユーザーを返す
user = User.first
```

```ruby
# Davidという名前を持つ最初のユーザーを返す
david = User.find_by(name: 'David')
```

```ruby
# 名前がDavidで、職業がコードアーティストのユーザーをすべて返し、created_atカラムで逆順ソートする
users = User.where(name: 'David', occupation: 'Code Artist').order('created_at DESC')
```

Active Recordモデルへのクエリについて詳しくは、[Active Recordクエリインターフェイス](active_record_querying.html)ガイドを参照してください。

### Update

Active Recordオブジェクトを取得すると、オブジェクトの属性を変更してデータベースに保存できるようになります。

```ruby
user = User.find_by(name: 'David')
user.name = 'Dave'
user.save
```

上のコードをもっと短く書くには、次のように、属性名と設定したい値をハッシュで対応付けて指定します。

```ruby
user = User.find_by(name: 'David')
user.update(name: 'Dave')
```

これは多くの属性を一度に更新したい場合に特に便利です。さらに、複数のレコードを一度に更新したい場合は`update_all`というクラスメソッドが便利です。

```ruby
User.update_all "max_login_attempts = 3, must_change_password = 'true'"
```

### Delete

他のメソッドと同様、Active Recordオブジェクトを取得すると、そのオブジェクトを`destroy`してデータベースから削除できます。

```ruby
user = User.find_by(name: 'David')
user.destroy
```

複数レコードを一括削除したい場合は、`destroy_all`を使えます。

```ruby
# Davidという名前のユーザーを検索してすべて削除
User.where(name: 'David').destroy_all

# 全ユーザーを削除
User.destroy_all
```

バリデーション（検証）
-----------

Active Recordを使って、モデルがデータベースに書き込まれる前にモデルの状態をバリデーション（検証: validation）できます。Active Recordにはモデルチェック用のさまざまなメソッドが用意されており、属性が空でないかどうか、属性が一意かどうか、既にデータベースにないかどうか、特定のフォーマットに沿っているかどうか、多岐にわたったバリデーションが行えます。

バリデーションは、データベースを永続化するうえで極めて重要です。そのため、`save`、`update`メソッドは、バリデーションに失敗すると`false`を返します。このとき実際のデータベース操作は行われません。上のメソッドにはそれぞれ破壊的なバージョン (`save!`、`update!`) があり、こちらは検証に失敗した場合にさらに厳しい対応、つまり`ActiveRecord::RecordInvalid`例外を発生します。以下はバリデーションの簡単な例です。

```ruby
class User < ApplicationRecord
  validates :name, presence: true
end

user = User.new
user.save  # => false
user.save! # => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

バリデーションについて詳しくは、[Active Recordバリデーションガイド](active_record_validations.html)を参照してください。

コールバック
---------

Active Recordコールバックを使うと、モデルのライフサイクル内で特定のイベントにコードをアタッチして実行できます。これにより、モデルで特定のイベントが発生したときにコードを透過的に実行できます。レコードの作成、更新、削除などさまざまなイベントに対してコールバックを設定できます。コールバックについて詳しくは、[Active Recordコールバックガイド](active_record_callbacks.html)を参照してください。

マイグレーション
----------

Railsにはデータベーススキーマを管理するためのDSL（ドメイン固有言語: Domain Specific Language）があり、マイグレーション(migration)と呼ばれています。マイグレーションをファイルに保存して`bin/rails`を実行すると、Active Recordがサポートするデータベースに対してマイグレーションが実行されます。以下はテーブルを作成するマイグレーションです。

```ruby
class CreatePublications < ActiveRecord::Migration[5.0]
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.references :publication_type
      t.integer :publisher_id
      t.string :publisher_type
      t.boolean :single_issue

      t.timestamps
    end
    add_index :publications, :publication_type_id
  end
end
```

Railsはどのマイグレーションファイルがデータベースにコミットされたかを把握しており、その情報を元にロールバック機能を提供しています。テーブルを実際に作成するには`bin/rails db:migrate`を実行します。ロールバックするには`bin/rails db:rollback`を実行します。

上のマイグレーションコードは特定のデータベースに依存していないことにご注目ください。MySQL、PostgreSQL、Oracleなどさまざまなデータベースに対してマイグレーションを実行できます。マイグレーションについて詳しくは、[Active Recordマイグレーション](active_record_migrations.html)を参照してください。
