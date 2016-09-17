
Active Record の基礎
====================

このガイドではActive Recordの基礎について説明します。

このガイドの内容:

* ORM (オブジェクトリレーショナルマッピング) とActive Recordについて、およびRailsでの利用方法
* Active RecordとMVC (Model-View-Controller)パラダイムの親和性
* Active Recordモデルを使用してリレーショナルデータベースに保存されたデータを操作する
* Active Recordスキーマにおける名前付けルール
* データベースのマイグレーション、検証(validation)、コールバック

--------------------------------------------------------------------------------

Active Recordについて
----------------------

Active Recordとは、[MVC](http://ja.wikipedia.org/wiki/Model_View_Controller)で言うところのM、つまりモデルに相当するものであり、ビジネスデータとビジネスロジックを表すシステムの階層です。Active Recordは、データベースに恒久的に保存される必要のあるビジネスオブジェクトの作成と利用を円滑に行なえるようにします。Active Recordは、ORM (オブジェクトリレーショナルマッピング) システムに記述されている「Active Recordパターン」を実装したものであり、同じ名前が付けられています。

### Active Recordパターン

[Active RecordはMartin Fowlerによって](http://www.martinfowler.com/eaaCatalog/activeRecord.html) _Patterns of Enterprise Application Architecture_ という書籍で記述されました。Active Recordにおいて、オブジェクトとは永続的なデータであり、そのデータに対する振る舞いでもあります。Active Recordでは、データアクセスのロジックを確実なものにすることは、そのオブジェクトの利用者にデータベースへの読み書き方法を教育することの一部である、という意見を採用しています。

### O/Rマッピング

オブジェクトリレーショナルマッピング (O/RマッピングやORMと略されることもあります)とは、アプリケーションが持つリッチなオブジェクトをリレーショナルデータベース(RDBMS)のテーブルに接続するものです。ORMを使用することで、SQL文を直接書く代りにわずかなアクセスコードを書くだけで、アプリケーションにおけるオブジェクトの属性やリレーションシップをデータベースに保存したりデータベースから読み出したりすることができるようになります。

### ORMフレームワークとしてのActive Record

Active Recordにはさまざまな機能が搭載されており、その中でも以下のものが特に重要です。

* モデルおよびモデル内のデータを表現する
* モデル間の関連付け(アソシエーション)を表現する
* 関連するモデルを介した継承階層を表現する
* データがデータベースに永続的に保存される前に検証(validation)を行なう
* オブジェクト指向の表記方法でデータベースを操作する

Active RecordにおけるCoC(Convention over Configuration)
----------------------------------------------

他のプログラミング言語やフレームワークを使用してアプリケーションを作成すると、設定のためのコードを大量に書く必要が生じがちです。一般的なORMアプリケーションでは特にこの傾向があります。しかし、Railsに適合するルールに従っていれば、Active Recordモデルを作成するときに、設定のために書かなければならないコードは最小限で済みます。場合によっては設定のためのコードが完全に不要であることすらあります。これは、アプリケーションの設定がほとんどの場合で同じならば、それをデフォルトにすべきであるという考えに基づいています。つまり、明示的な設定が必要となるのは標準のルールだけでは不足がある場合のみということです。

### 命名ルール

Active Recordには、モデルとデータベースのテーブルとのマッピング作成時に従うべきルールがいくつかあります。Railsでは、データベースのテーブル名を見つけるときに、モデルのクラス名を複数形にしたものを使用します。つまり、`Book`というモデルクラスがある場合、これに対応するデータベースのテーブルは複数形の**books**になります。Railsの複数形化メカニズムは非常に強力で、不規則な語であっても複数形にしたり単数形にしたりできます(person <-> peopleなど)。モデルのクラス名が2語以上の複合語である場合、Rubyの慣習であるキャメルケース(CamelCaseのように語頭を大文字にしてスペースなしでつなぐ)に従ってください。一方、テーブル名は(camel_caseなどのように)小文字かつアンダースコアで区切られなければなりません。以下の例を参照ください。

* データベースのテーブル - 複数形であり、語はアンダースコアで区切られる (例: `book_clubs`)
* モデルのクラス - 単数形であり、語頭を大文字にする (例: `BookClub`)

| モデル / クラス | テーブル / スキーマ |
| ------------- | -------------- |
| `Post`        | `posts`        |
| `LineItem`    | `line_items`   |
| `Deer`        | `deers`        |
| `Mouse`       | `mice`         |
| `Person`      | `people`       |


### スキーマのルール

Active Recordでは、データベースのテーブルで使用されるカラムの名前についても、利用目的に応じてルールがあります。

* **外部キー** - このカラムは `テーブル名の単数形_id` にする必要があります (例 `item_id`、`order_id`)これらのカラムは、Active Recordがモデル間の関連付けを作成するときに参照されます。

* **主キー** - デフォルトでは `id` という名前を持つintegerのカラムをテーブルの主キーとして使用します。このカラムは、[Active Recordマイグレーション](active_record_migrations.html)を使用してテーブルを作成するときに自動的に作成されます。

他にも、Active Recordインスタンスに機能を追加するカラム名がいくつかあります。

* `created_at` - レコードが作成された時に現在の日付時刻が自動的に設定されます
* `updated_at` - レコードが更新されたときに現在の日付時刻が自動的に設定されます
* `lock_version` - モデルに[optimistic locking](http://api.rubyonrails.org/classes/ActiveRecord/Locking.html)を追加します
* `type` - モデルで[Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#label-Single+table+inheritance)を使用する場合に指定します
* `関連付け名_type` - [ポリモーフィック関連付け](association_basics.html#ポリモーフィック関連付け)の種類を保存します
* `テーブル名_count` - 関連付けにおいて、所属しているオブジェクトの数をキャッシュするのに使用されます。たとえば、`Post`クラスに`comments_count`というカラムがあり、そこに`Comment`のインスタンスが多数あると、ポストごとのコメント数がここにキャッシュされます。

NOTE: これらのカラム名は必須ではありませんが、Active Recordに予約されています。特殊なことをするのでなければ、これらの予約済みカラム名の使用は避けてください。たとえば、`type`という語はテーブルでSingle Table Inheritance (STI)を指定するために予約されています。STIを使用しないとしても、予約語より先にまず"context"などのような、モデルのデータを適切に表す語を検討してください。

Active Recordのモデルを作成する
-----------------------------

Active Recordモデルの作成は非常に簡単です。以下のように`ActiveRecord::Base`クラスのサブクラスを作成するだけで完了します。

```ruby
class Product < ActiveRecord::Base
end
```

上のコードは、`Product`モデルを作成し、データベースの`products`テーブルにマッピングされます。さらに、テーブルに含まれている各行のカラムを、作成したモデルのインスタンスの属性にマッピングします。以下のSQL文で`products`テーブルを作成したとします。

```sql
CREATE TABLE products (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   PRIMARY KEY  (id)
);
```

上のテーブルスキーマに従って、以下のようなコードをいきなり書くことができます。

```ruby
p = Product.new
p.name = "Some Book"
puts p.name # "Some Book"
```

命名ルールを上書きする
---------------------------------

Railsアプリケーションで別の命名ルールを使用しなければならない、レガシデータベースを使用してRailsアプリケーションを作成しないといけないなどの場合にはどうすればよいでしょうか。そんなときにはデフォルトの命名ルールを簡単にオーバーライドできます。

`ActiveRecord::Base.table_name=`メソッドを使用して、使用すべきテーブル名を明示的に指定できます。

```ruby
class Product < ActiveRecord::Base
  self.table_name = "PRODUCT"
end
```

この指定を行った場合、テストの定義で`set_fixture_class`メソッドを使用し、フィクスチャ (クラス名.yml) に対応するクラス名を別途定義する必要があります。

```ruby
class FunnyJoke < ActiveSupport::TestCase
  set_fixture_class funny_jokes: Joke
  fixtures :funny_jokes
  ...
end
```

`ActiveRecord::Base.primary_key=`メソッドを使用して、テーブルの主キーとして使用されるカラム名もオーバーライドできます。

```ruby
class Product < ActiveRecord::Base
  self.primary_key = "product_id"
end
```

CRUD: データの読み書き
------------------------------

CRUDとは、4つのデータベース操作を表す **C** reate、 **R** ead、 **U** pdate、 **D** eleteの頭字語です。Active Recordはこれらのメソッドを自動的に作成し、これによってアプリケーションはテーブルに保存されているデータを操作することができます。

### Create

Active Recordのオブジェクトはハッシュやブロックから作成することができます。また、作成後に属性を手動で追加できます。`new`メソッドを実行すると単に新しいオブジェクトが返されますが、`create`を実行すると新しいオブジェクトが返され、さらにデータベースに保存されます。

たとえば、`User`というモデルに`name`と`occupation`という属性があるとすると、`create`メソッドを実行すると新しいレコードが1つ作成され、データベースに保存されます。

```ruby
user = User.create(name: "David", occupation: "Code Artist")
```

`new`メソッドを使用した場合は、オブジェクトは保存されずにインスタンス化されます。

```ruby
user = User.new
user.name = "David"
user.occupation = "Code Artist"
```

この場合、`user.save`を実行して初めてデータベースにレコードがコミットされます。

最後に、`create`や`new`にブロックが渡されると、新しいオブジェクトは初期化のためにブロックに渡されます。

```ruby
user = User.new do |u|
  u.name = "David"
  u.occupation = "Code Artist"
end
```

### Read

Active Recordは、データベース内のデータにアクセスするためのリッチなAPIを提供します。以下は、Active Recordによって提供されるさまざまなデータアクセスメソッドのほんの一例です。

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

Active Recordモデルへのクエリについては[Active Recordクエリインターフェイス](active_record_querying.html)ガイドで詳細を説明します。

### Update

Active Recordオブジェクトをひとたび取得すると、オブジェクトの属性を変更してデータベースに保存できるようになります。

```ruby
user = User.find_by(name: 'David')
user.name = 'Dave'
user.save
```

上のコードをもっと短くするのであれば、属性名と、設定したい値をマッピングするハッシュを使用して次のように書きます。

```ruby
user = User.find_by(name: 'David')
user.update(name: 'Dave')
```

これは多くの属性を一度に更新したい場合に特に便利です。さらに、複数のレコードを一度に更新したいのであれば、`update_all`というクラスメソッドが便利です。

```ruby
User.update_all "max_login_attempts = 3, must_change_password = 'true'"
```

### Delete

他のメソッドと同様、Active Recordオブジェクトをひとたび取得すれば、そのオブジェクトをdestroyすることでデータベースから削除できます。

```ruby
user = User.find_by(name: 'David')
user.destroy
```

検証(validation)
-----------

Active Recordを使用して、モデルがデータベースに書き込まれる前にモデルの状態を検証することができます。モデルをチェックするためのさまざまなメソッドが用意されています。属性が空でないこと、一意であること、既にデータベースにないこと、特定のフォーマットに従っていることなど、多岐にわたった検証が行えます。

検証は、データベースを永続化するうえで極めて重要です。そのため、`create`、`save`、`update`メソッドは、検証に失敗した場合に`false`を返します。このとき実際のデータベース操作は行われません。上の3つのメソッドにはそれぞれ破壊的なバージョン (`create!`、`save!`、`update!`)があり、こちらは検証に失敗した場合にさらに厳しい対応、つまり`ActiveRecord::RecordInvalid`例外を発生します。
以下の例で簡単に説明します。

```ruby
class User < ActiveRecord::Base
  validates :name, presence: true
end

User.create  # => false
User.create! # => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

検証の詳細については[Active Record検証ガイド](active_record_validations.html)を参照してください。

コールバック
---------

Active Recordコールバックを使用することで、モデルのライフサイクルにおける特定のイベント実行時にコードをアタッチして実行することができます。これにより、モデルで特定のイベントが発生したときにコードが透過的に実行されるようになります。レコードの作成、更新、削除などさまざまなイベントに対してコールバックを設定できます。コールバックの詳細については[Active Recordコールバックガイド](active_record_callbacks.html)を参照してください。

マイグレーション
----------

Railsにはデータベーススキーマを管理するためのドメイン固有言語(DSL: Domain Specific Language)があり、マイグレーション(migration)と呼ばれています。マイグレーションはファイルに保存されます。`bin/rails`を実行すると、Active Recordがサポートするあらゆるデータベースに対してマイグレーションが実行されます。以下はテーブルを作成するマイグレーションです。

```ruby
class CreatePublications < ActiveRecord::Migration
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

Railsはどのマイグレーションファイルがデータベースにコミットされたかを把握しており、その情報を使用してロールバック機能を提供しています。テーブルを実際に作成するには`bin/rails db:migrate`を実行します。ロールバックするには`bin/rails db:rollback`を実行します。

上のマイグレーションコードはデータベースに依存していないことにご注目ください。MySQL、PostgreSQL、Oracleなど多くのデータベースに対して実行できます。マイグレーションの詳細については[Active Recordマイグレーション](active_record_migrations.html)を参照してください。