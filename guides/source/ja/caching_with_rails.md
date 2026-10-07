Rails のキャッシュ機構
==================

本ガイドでは、キャッシュを導入してRailsアプリケーションを高速化する方法を解説します。

このガイドの内容:

* キャッシュとは何か
* キャッシュ戦略の種類
* キャッシュの依存関係の管理
* Solid Cache やその他のキャッシュストアの設定方法

--------------------------------------------------------------------------------

キャッシュとは何か
----------------

**キャッシュ**（caching）とは、リクエスト・レスポンスサイクルの中で生成されたコンテンツを保存しておき、次回同じようなリクエストが発生したときのレスポンスでそのコンテンツを再利用することを指します。コストのかかる処理を何度も繰り返すのではなく、一度計算した結果を保存しておいて後で参照することで時間を節約するようなものです。

キャッシュはアプリケーションのパフォーマンスをきわめて効果的に向上させる方法です。キャッシュを導入することで、サーバー1台とデータベース1台のWebサイトのような小規模なインフラでも、数千ユーザーの同時接続を処理できるようになります。

Railsは、データのキャッシュだけでなく、キャッシュの有効期限、キャッシュの依存関係、キャッシュの無効化などにも対応できるキャッシュ機能をひと通り標準で提供しています。

セットアップ
-----

[Action Controllerのキャッシュ][Action Controller Caching]は、デフォルトではproduction環境でのみ有効になります。
`bin/rails dev:cache`コマンドを実行するか、`config/environments/development.rb`ファイルで[`config.action_controller.perform_caching`][]を`true`に設定することで、ローカルでキャッシュを試せるようになります。

```bash
$ bin/rails dev:cache
Development mode is now being cached.
$ bin/rails dev:cache
Development mode is no longer being cached.
```

NOTE: `config.action_controller.perform_caching`値の変更は、Action Controllerコンポーネントで提供されるキャッシュでのみ有効です。つまり、後述する[低レベルキャッシュ](#rails-cacheによる低レベルキャッシュ)の動作には影響しません。

新規Railsアプリケーションのdevelopment環境では、デフォルトで[`:memory_store`](#activesupport-cache-memorystore)によるキャッシュが使われます。development環境でSolid Cacheを使いたい場合は、`config/environments/development.rb`ファイルの`cache_store`設定を以下のように変更してください。

```ruby
config.cache_store = :solid_cache_store
```

さらに、`config/database.yml`の`development/cache`にあるデータベースの設定、作成、マイグレーションを完了してください。

```yaml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  cache:
    <<: *default
    database: storage/development_cache.sqlite3
    migrations_paths: db/cache_migrate
```

データベースの設定が完了したら、`bin/rails db:prepare`を実行してキャッシュ用のテーブルを作成します。

TIP: キャッシュそのものを無効にするには、`cache_store`に[`:null_store`](#activesupport-cache-nullstore)を設定します。

[Action Controller Caching]:
  https://api.rubyonrails.org/classes/ActionController/Caching.html
[`config.action_controller.perform_caching`]:
  configuring.html#config-action-controller-perform-caching

キャッシュの種類
----------------

NOTE: 訳注: 「ページキャッシュ」と「アクションキャッシュ」の項目はRails 8.0.1で削除されました。

Railsは、多くのニーズやユースケースに対応できるさまざまなキャッシュ戦略を提供しています。メリットや有用なシナリオは、アプローチごとに異なります。

### `Rails.cache`による低レベルキャッシュ

`Rails.cache`で利用できるRailsの**低レベルキャッシュ**（low-level caching）は、APIレスポンス、計算結果、高負荷クエリの結果などのシリアライズ可能な値を保存します。これにより、ビュー全体をキャッシュすることなく、個々のデータをキャッシュできるようになります。

`Rails.cache.fetch`メソッドは、キャッシュからの**読み取り**と**書き込み**の両方を処理します。
このメソッドが単一の引数で呼び出された場合、指定されたキーに対するキャッシュ済みの値を取得して返します。

このメソッドにブロックを渡すと、キャッシュミスのときだけブロックが実行されます。ブロックの戻り値は、指定されたキャッシュキーの下にキャッシュされ、返されます。キャッシュヒットの場合、ブロックを実行せずにキャッシュ済みの値が直接返されます。

利用例:

```ruby
# `fetch`は、キャッシュが存在しない場合はデフォルト値を設定するためにブロックで値を取得する
welcome_message = Rails.cache.fetch("welcome_message") { "Welcome to Rails!" }
puts welcome_message # Output: Welcome to Rails!
```

INFO: 「キャッシュがヒットする」とは、Railsがキャッシュ内に既存の値を見つけて再利用できたことを意味します。「キャッシュがミスする」とは、値がまだキャッシュ内に存在せず、Railsがそれを生成して保存する必要があったことを意味します。キャッシュミスは正常な動作であり、特にエントリの有効期限が切れた場合、キャッシュがクリアされた場合、またはキーが初めて使われた場合に発生します。

より高度なユースケースとして、`Rails.cache.fetch`に`race_condition_ttl`のようなオプションも指定できます。これはキャッシュスタンピード（複数のプロセスが同時にキャッシュをリビルドしようとする状態）を防ぐのに有用なオプションで、1つのプロセスがエントリをリビルドしている間、期限切れ間もないエントリを短時間だけ再利用可能にします。オプションの完全なリストはAPIドキュメント[`ActiveSupport::Cache::Store`][]で参照できます。

あるいは、キャッシュからの読み取りや書き込みを`Rails.cache.read`や`Rails.cache.write`で指定することも可能です。キーを削除するには、`Rails.cache.delete`を使います。

```ruby
# `write`: 値をキャッシュに保存する
Rails.cache.write("greeting", "Hello, world!")

# `read`: キャッシュから値を取り出す
greeting = Rails.cache.read("greeting")
puts greeting # Output: Hello, world!

# `fetch`: キャッシュが存在しない場合はデフォルト値を設定するためにブロックで値を取得する
welcome_message = Rails.cache.fetch("welcome_message") { "Welcome to Rails!" }
puts welcome_message # Output: Welcome to Rails!

# `delete`: キャッシュの値を削除する
Rails.cache.delete("greeting")
```

現在のキャッシュストアからすべてのデータを削除する必要がある場合は、`Rails.cache.clear`を呼び出します。
これは主にdevelopment環境や、明示的にキャッシュをリセットしたい場合に有用です。production環境でキャッシュをすべてクリアすると、膨大なキャッシュエントリがリビルドされて処理負荷が急増する可能性があります。

キャッシュのキーとして、値のハッシュや配列を指定できます。

```ruby
# このキャッシュキーは有効
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

キャッシュで使うキーには、`cache_key`または`to_param`に応答する任意のオブジェクトが使えます。カスタムキーが必要な場合は、独自のクラスで`cache_key`メソッドを実装できます。Active Recordモデルは、モデル名とレコードIDに基づくキャッシュキーを最初から生成します。

以下の例を考えてみましょう。アプリケーションの`Product`モデルには、競合他社のWebサイトで製品の価格を調べるインスタンスメソッドがあります。このメソッドが返すデータは、低レベルキャッシュに適しています。

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key_with_version}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

上の例では`cache_key_with_version`メソッドを使っているため、結果のキャッシュキーは`products/233-20140225082222765838000/competing_price`のような形式になります。この`cache_key_with_version`メソッドは、モデルのクラス名、`id`、`updated_at`属性に基づいて文字列を`<model class name>/<resource id>-<resource updated_at>`の形式で生成します。
これは一般によく使われる生成手法であり、製品が更新されるたびにキャッシュが無効になるというメリットがあります。

INFO: `Rails.cache`で使われるキーは、ストレージエンジンで実際に使われるキーとは異なります。後者のキーは名前空間によって修飾されたり、バックエンド技術の制約に合わせて変更されたりする可能性があるためです。つまり、`Rails.cache`で保存した値を、[`dalli`][] gemなどで取り出すことはできません。その代わり、memcachedのサイズ制限を超過したり、構文規則に違反したりすることを心配する必要もありません。

[`dalli`]:
  https://github.com/petergoldstein/dalli

#### Active Recordオブジェクトのインスタンスのキャッシュは避けること

Railsのキャッシュに、Active Recordオブジェクトのリストを保存することは**避けるべき**です。

```ruby
# super_adminsを取り出すSQLクエリは高負荷なので頻繁に実行したくないとする
Rails.cache.fetch("super_admin_users", expires_in: 12.hours) do
  User.super_admins.to_a
end
```

上の例では、`super_admins`を表す`User`のインスタンスは変更される可能性があり、属性も異なる場合があります。また、レコードが削除されることもあります。development環境では、コード変更時の再読み込みとの組み合わせによってキャッシュストアの動作が不安定になることもあります。

代わりに、以下のようにリソースIDなどのプリミティブなデータ型をキャッシュすべきです。

```ruby
ids = Rails.cache.fetch("super_admin_user_ids", expires_in: 12.hours) do
  User.super_admins.pluck(:id)
end
User.where(id: ids).to_a
```

### フラグメントキャッシュ

動的なWebアプリケーションでは、基本的にさまざまなコンポーネントを用いてページをビルドしますが、キャッシュの特性はコンポーネントによって異なります。たとえば、サイトのロゴのような静的なコンポーネントは、他のより動的なコンポーネントに比べてキャッシュ期間を長く取ります。

ページ内のパーツごとに個別のキャッシュや有効期限を設定したい場合は、**フラグメントキャッシュ**（fragment caching）を利用できます。

フラグメントキャッシュでは、ビューのロジックのフラグメントをキャッシュブロックでラップして、次回のリクエストでそれをキャッシュストアから取り出して配信できるようになります。

たとえば、ページ内で表示する製品（product）を製品ごとにキャッシュしたい場合は、以下のように書けます。

```html+erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

Railsアプリケーションがこのページへの最初のリクエストを受信すると、一意のキーを持つ新しいキャッシュエントリが保存されます。生成されるキーは以下のようなものになります。

```
views/products/index:bea67108094918eeba42cd4a6e786901/products/1
```

キーの途中にある文字列（`bea67108094918eeba42cd4a6e786901`）は、テンプレートツリーのダイジェストです。これは、キャッシュするビューフラグメントのコンテンツを元に算出されたハッシュダイジェストです。ビューフラグメントが変更されると（HTMLが変更されるなど）このダイジェストも変更され、別のキャッシュエントリとして扱われるようになります。

productレコードから導出されたキャッシュのバージョンもキャッシュエントリに保存されます。productレコードが更新されるとキャッシュバージョンも変更され、古いバージョンを含むキャッシュフラグメントは無効になります。

Railsではキャッシュキーとキャッシュバージョンが分離されていることで、キャッシュキーが再利用可能になります。つまり、productが更新されるたびにキャッシュエントリを新たに作成するのではなく、同じキャッシュキーに書き込まれるようになります。これにより、古いキャッシュエントリが新しいエントリで上書きされるため、キャッシュ容量全体が削減されます。

TIP: [Memcached](https://memcached.org)などのキャッシュストアは、領域の回収が必要になったときに、古いキャッシュエントリを自動削除します。

条件を指定してフラグメントをキャッシュしたい場合は、`cache_if`や`cache_unless`を利用できます。

```erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### コレクションキャッシュ

`render`ヘルパーは、コレクションでレンダリングされた個別のテンプレートもキャッシュします。上のコード例のようにキャッシュテンプレートを`each`ループで個別に読み出す代わりに、すべてのキャッシュテンプレートを一括で読み出すことも可能です。

この**コレクションキャッシュ**（collection caching）機能を利用するには、コレクションをレンダリングするときに以下のように`cached: true`を指定します。

```html+erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

これにより、前回までにレンダリングされたすべてのキャッシュテンプレートが一括で読み出されるようになります。それまでキャッシュされていなかったテンプレートもレンダリング後にキャッシュに追加され、次回のレンダリングでまとめて読み出されます。

このキャッシュキーはカスタマイズ可能です。
以下のコード例では、productページでローカライズ結果が別のローカライズで上書きされないようにするため、現在のロケールをキャッシュキーにプレフィックスしています。

```html+erb
<%= render partial: 'products/product',
           collection: @products,
           cached: ->(product) { [I18n.locale, product] } %>
```

`cached`は、以下のように`expires_in`キーと`key`キーを受け取るオプションハッシュで設定することも可能です。これにより、キャッシュキーと有効期限を明示的に制御できます。

```html+erb
<%= render partial: 'products/product',
           collection: @products,
           cached: { expires_in: 1.hour, key: ->(product) { [I18n.locale, product] } } %>
```

#### 依存関係の管理

フラグメントキャッシュを利用する場合、Railsがキャッシュフラグメントを正しく無効化できるよう、テンプレートの依存関係を適切に定義する必要があります。

Railsは、一般的な多くのケースについてはテンプレートの依存関係を自動的に推論しますが、ヘルパー内でのレンダリングや、間接的な`render`呼び出しが行われる場合には、テンプレートの依存関係を明示的に宣言する必要が生じることがあります。

##### 暗黙の依存関係

Railsは、テンプレート内の`render`呼び出しから、テンプレートの依存関係の多くを直接推論できます。たとえば、[`ActionView::Digestor`][]は以下のような呼び出しを認識できます。

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render("comments/comments")

render "header" # render("comments/header")に変換される

render(@topic)         # render("topics/topic")に変換される
render(topics)         # render("topics/topic")に変換される
render(message.topics) # render("topics/topic")に変換される
```

ただし、一部の`render`呼び出しでは、Railsがテンプレートの依存関係を推論するために、より多くの情報を必要とします。たとえば、以下のようにカスタムコレクションを渡す場合です。

```ruby
render @project.documents.where(published: true)
```

上のコードは、以下のようにパーシャル名とコレクションを明示的に指定する形に書き換える必要があります。

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

[`ActionView::Digestor`]:
  https://api.rubyonrails.org/classes/ActionView/Digestor.html

##### 明示的な依存関係

テンプレートの依存関係をまったく導出できないことがあります。典型的な例は、以下のように`render`呼び出しがヘルパーメソッド内で隠蔽されている場合です。

```html+erb
<%= render_sortable_todolists @project.todolists %>
```

このような呼び出しでは、以下のような特殊コメント形式で明示的に依存関係を示す必要があります。

```html+erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

[単一テーブル継承（STI）](association_basics.html#単一テーブル継承（sti）)などでは、ヘルパーが同じディレクトリ内のさまざまなパーシャルをレンダリングする可能性があります。

このような場合、テンプレートの特殊コメントですべての依存関係を網羅する代わりに、以下のようにワイルドカードを用いてディレクトリ内の任意のテンプレートにマッチさせることも可能です。

```html+erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

キャッシュ呼び出しがヘルパー内で隠蔽されている場合は、コレクションキャッシュ用の特殊コメントも利用できます。
パーシャルテンプレートの冒頭が明示的な`cache`呼び出しでなければ、このコメントをテンプレート内の任意の場所に追加できます。

```html+erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

##### 外部の依存関係

テンプレートファイルの外部での変更も、キャッシュされた出力に影響を与える可能性があります。たとえば、キャッシュされたブロック内でヘルパーメソッドを呼び出している場合、ヘルパーのコードを更新してもテンプレートのダイジェストは自動的に変更されません。

そのような場合は、テンプレートのダイジェストが変更されるようにテンプレートを更新します。シンプルな方法の1つは、以下のように更新日時をコメントとして追加・更新することです。

```html+erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

### ロシアンドールキャッシュ

別のフラグメントキャッシュの内側にフラグメントをキャッシュしたいことがあります。このようにキャッシュをネストする手法を、マトリョーシカ人形のイメージになぞらえて**ロシアンドールキャッシュ**（Russian doll caching）と呼びます。

ロシアンドールキャッシュのメリットは、たとえば内側のフラグメントで製品（product）が1件だけ更新された場合に、内側の他のフラグメントを捨てずに再利用し、外側のフラグメントは通常どおり再生成できることです。

前のセクションで解説したように、キャッシュされたフラグメントは、そのフラグメントが直接依存しているレコードの`updated_at`値が変わると失効しますが、そのフラグメントを含む外側のフラグメントは自動的には失効しません。

以下のビューを例に説明します。

```erb
<% cache product do %>
  <%= render product.reviews %>
<% end %>
```

上のビューは、さらに以下のビューをレンダリングします。

```erb
<% cache review do %>
  <%= render review %>
<% end %>
```

内側の`review`が変更されると、その`updated_at`値も変わり、該当するフラグメントは失効します。しかし、外側の`product`レコードの`updated_at`は自動的には変わらないため、外側のフラグメントは古いデータを返し続けます。

これを解決するには、以下のように`touch`メソッドでモデル同士を連動させます。

```ruby
class Product < ApplicationRecord
  has_many :reviews
end

class Review < ApplicationRecord
  belongs_to :product, touch: true
end
```

`touch: true`を設定すると、内側の`review`レコードの`updated_at`が変更されるたびに、関連付けられている`product`レコードの`updated_at`も変更され、キャッシュが失効するようになります。

### 共有パーシャルキャッシュ

**共有パーシャルキャッシュ**（shared partial caching）は、パーシャルと、そのキャッシュ済み出力を[MIMEタイプ][MIME_types]の異なる複数のテンプレートで共有できます。

たとえば、HTMLテンプレートとJavaScriptテンプレート間でパーシャルキャッシュを共有できます。`render partial:`が解決されるときに、明示的なフォーマットが指定されていないパーシャルを複数のレスポンスフォーマットで利用できます。

以下のコードは、HTMLリクエストでもJavaScriptリクエストでも利用できます。

```ruby
render(partial: "hotels/hotel", collection: @hotels, cached: true)
```

上のコードは`hotels/_hotel.html.erb`パーシャルファイルを読み込みます。

以下のように、レンダリングするパーシャルで明示的に`formats`オプションを指定する方法も使えます。

```ruby
render(partial: "hotels/hotel", collection: @hotels, formats: :html, cached: true)
```

上のコードは、MIMEタイプの異なるテンプレート（JavaScriptテンプレートなど）でも`hotels/_hotel.html.erb`パーシャルファイルを読み込みます。

[MIME_types]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Guides/MIME_types

### 条件付きGET

[条件付きGET][Conditional_requests]はHTTP仕様で定められた機能で、サーバーがブラウザに対して、前回のリクエスト以降にレスポンスが変更されていないことを通知し、ブラウザがキャッシュを再利用できるようにする仕組みです。

この仕組みは、ブラウザや中間キャッシュが既にレスポンスの直近のコピーを持っている場合に、サーバーがレスポンスbody全体の再送信を避けるのに有用です。

この仕組みは、`If-None-Match`および`If-Modified-Since`リクエストヘッダーと連携して動作します。
サーバーは、レスポンスが最新かどうかを[ETag](#強いetagと弱いetag)や最終更新日時の情報で確認します。ブラウザ側のコピーがサーバーのバージョンと一致する場合、サーバーは`304 Not Modified`レスポンスをbodyなしで返せるようになります。

これらのヘッダーを評価して、完全なレスポンスを返すかどうかを判断するのはサーバー側の責任です。
Railsでは、この仕組みを手軽に実装できます。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    # 指定のタイムスタンプやETag値によって、リクエストが古いことがわかった場合
    # （再処理が必要な場合）、このブロックを実行する
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key_with_version)
      respond_to do |wants|
        # ... 通常のレスポンス処理
      end
    end

    # リクエストがフレッシュな（つまり前回から変更されていない）場合は処理不要。
    # デフォルトのレンダリングでは、直前の`stale?`呼び出しで使ったパラメータに基づいて
    # 処理が必要かどうかを判断し、:not_modifiedを自動的に送信する。
  end
end
```

オプションハッシュの代わりに、単にモデルを渡すことも可能です。
Railsは、`updated_at`メソッドや`cache_key_with_version`メソッドを用いて`last_modified`や`etag`を設定します。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    if stale?(@product)
      respond_to do |wants|
        # ... 通常のレスポンス処理
      end
    end
  end
end
```

特殊なレスポンス処理を使わずにデフォルトのレンダリングメカニズムを利用する（つまり`respond_to`も使わず独自の`render`呼び出しも行わない）場合は、以下のように`fresh_when`ヘルパーで簡単に処理できます。

```ruby
class ProductsController < ApplicationController
  # リクエストがフレッシュな場合は自動的に:not_modifiedを返す
  # 古い場合はデフォルトのテンプレート（product.*）をレンダリングする

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

オプションハッシュの代わりに、単にモデルを渡すことも可能です。
Railsは、`updated_at`メソッドや`cache_key_with_version`メソッドを用いて`last_modified`や`etag`を設定します。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when @product
  end
end
```

`last_modified`と`etag`が両方とも設定されたときの振る舞いは、[`config.action_dispatch.strict_freshness`][]設定に依存します。

`true`の場合、RFC 7232のセクション6の規定に従い、`etag`のみが考慮されます。
`false`の場合は、両方のヘッダーがチェックされ、両方とも一致した場合にのみ、レスポンスはフレッシュであるとみなされます。

[Conditional_requests]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Guides/Conditional_requests
[`config.action_dispatch.strict_freshness`]:
  configuring.html#config-action-dispatch-strict-freshness

#### 強いETagと弱いETag

[ETag][]は、レスポンスbodyの特定のバージョンを一意に表すトークンで、多くの場合はハッシュです。サーバーがETagを送信すると、ブラウザは後でETagを返すことで「レスポンスはまだ同じか？」とサーバーに問い合わせられるようになり、完全なレスポンスを取得せずに済みます。

Railsは、デフォルトで「**弱い**」ETagを使います。
弱いETagは、レスポンスbodyがバイト単位で完全に一致しなくても、意味的に同等のレスポンスが同じETagを共有できるようにします。これは、意味の変わらない微細な表現の違い（無意味なホワイトスペースやフォーマットの変更など）が発生する場合に有用です。

弱いETagの冒頭には以下のように`W/`が追加されるので、強いETagと区別できます。

```
W/"618bbc92e2d35ea1945008b42799b0e7" -> 弱いETag
"618bbc92e2d35ea1945008b42799b0e7"   -> 強いETag
```

強いETagは、弱いETagと異なり、レスポンスbodyがバイトレベルで完全一致しなければなりません。

強いETagは、巨大な動画やPDFファイル内で`Range`リクエストを実行する場合に便利です（一部のCDNでは、強いETagが必要です）。

強いETagの生成が必要な場合は、次のようにできます。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

以下のように、レスポンスに強いETagを直接設定することも可能です。

```ruby
response.strong_etag = response.body # => "618bbc92e2d35ea1945008b42799b0e7"
```

静的ページなどの変更が発生しないページでキャッシュを有効にしたいことがあります。
[`http_cache_forever`][]ヘルパーを使うと、ブラウザやプロキシでキャッシュを極めて長い期間に設定できます。

キャッシュのレスポンスはデフォルトではprivateになっており、キャッシュはユーザーのWebブラウザでのみ行われます。プロキシでレスポンスをキャッシュ可能にするには、`public: true`を設定してプロキシがキャッシュ済みレスポンスをすべてのユーザーに配信してよいことを示します。

このヘルパーメソッドを使うと、`last_modified`ヘッダーが`Time.new(2011, 1, 1).utc`に設定され、`Cache-Control`ヘッダーが極めて長い期間に設定されます。

WARNING: `http_cache_forever`メソッドの利用には十分ご注意ください。ブラウザやプロキシは、別のURLでレスポンスが変更されるかキャッシュがクリアされるまで、キャッシュしたレスポンスをいつまでも再利用し続けます。

```ruby
class HomeController < ApplicationController
  def index
    http_cache_forever(public: true) do
      render
    end
  end
end
```

[ETag]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Reference/Headers/ETag

[`http_cache_forever`]:
  https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-http_cache_forever

### SQLキャッシュ

Active Recordの**クエリキャッシュ**（query caching）は、各クエリが返す結果セットをキャッシュする機能です。
同じリクエストまたは同じ実行コンテキスト内で同じクエリが再度実行された場合は、データベースへのクエリを実行する代わりに、キャッシュされた結果セットを利用します。

以下に例を示します。

```ruby
class ProductsController < ApplicationController
  def index
    # 検索クエリの実行
    @products = Product.all

    # ...

    # 同じクエリの再実行
    @products = Product.all
  end
end
```

同じクエリの2回目の実行では、データベースにアクセスしません。Active Recordは結果セットをメモリから読み出します。ただし取得のたびに、クエリされたオブジェクトの新しいインスタンスが引き続き作成されます。

NOTE: クエリキャッシュはアクションの開始時に作成され、そのアクションの終了時に破棄されるため、リクエストが継続している間のみ保持されます。クエリ結果をより永続的な形で保存したい場合は、低レベルキャッシュをお使いください。

Solid Cache: デフォルトのキャッシュストア
--------------------------

Solid Cacheは、データベースにバックエンドを持つActive Supportのキャッシュストアで、新規Railsアプリケーションのデフォルトのキャッシュストアとして採用されています。RedisやMemcachedなどのキャッシュサービスを別途実行せずに、従来よりも大容量・高耐久性のキャッシュが必要な場合に適しています。

Solid Cacheは[FIFO][]（First In, First Out）キャッシュ戦略を採用しており、キャッシュ容量の上限に達した場合、最初に追加されたアイテムが最初に削除されます。
このアプローチはシンプルですが、[LRU][]（Least Recently Used）キャッシュと比較すると効率が落ちます。LRUは、直近で最もアクセスされていないアイテムを優先的に削除することで、利用頻度の高いデータを最適化できます。しかし、Solid CacheはFIFOの効率の低さを補うために、キャッシュの寿命を長くすることで無効化処理の発生頻度を減らしています。

Rails 8.0以降で生成された新しいRailsアプリケーションには、デフォルトでSolid Cacheが含まれています。Solid Cacheを使わない場合は、アプリケーションを生成するコマンドに`--skip-solid`フラグを追加してください。

```bash
$ bin/rails new app_name --skip-solid
```

NOTE: `--skip-solid`フラグを使うと、Solid3兄弟（Solid Cache、Solid Queue、Solid Cable）のすべての機能がスキップされます。もし一部の機能だけを使いたい場合は、それぞれのインストールガイドに沿って個別にインストールしてください。たとえば、Solid Cacheを使わずにSolid QueueとSolid Cableだけを使いたい場合は、[Solid Queue][]と[Solid Cable][]のインストールガイドを参照してください。

[FIFO]:
  https://ja.wikipedia.org/wiki/FIFO
[LRU]:
  https://ja.wikipedia.org/wiki/Least_Recently_Used
[Solid Queue]:
  https://github.com/rails/solid_queue#installation
[Solid Cable]:
  https://github.com/rails/solid_cable#installation

### データベースを設定する

Solid Cacheで利用するデータベースコネクションは、`config/database.yml`ファイルで設定できます。
以下はSQLiteデータベースの例です。

```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
```

この設定では、`cache`に記載したデータベースがキャッシュデータの保存に使われます。MySQLやPostgreSQLなど、別のデータベースアダプターを指定することも可能です。

```yaml
production:
  primary: &primary_production
    <<: *default
    database: app_production
    username: app
    password: <%= ENV["APP_DATABASE_PASSWORD"] %>
  cache:
    <<: *primary_production
    database: app_production_cache
    migrations_paths: db/cache_migrate
```

`database`または[`databases`](#キャッシュをシャーディングする)がキャッシュ設定で指定されていない場合、Solid Cacheは`ActiveRecord::Base`のコネクションプールを利用します。つまり、キャッシュの読み書きは、それを囲んでいるデータベーストランザクションに参加します。

Solid Cacheをキャッシュストアとして利用するには、環境設定ファイルで以下のように設定します。

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store
```

[`Rails.cache`](#rails-cacheによる低レベルキャッシュ)を呼び出すことでキャッシュにアクセスできます。

### キャッシュストアをカスタマイズする

Solid Cacheの設定は、`config/cache.yml`ファイルでカスタマイズできます。

```yaml
default: &default
  store_options:
    # 保持ポリシーを満たすために最も古いキャッシュエントリの保存期間に上限を設定する
    max_age: <%= 60.days.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>
```

`store_options`で利用できるキーの完全なリストについては、Solid Cache READMEの[キャッシュ設定][cache-config]を参照してください。

ここでは、`max_age`と`max_size`のオプションを調整して、キャッシュエントリの寿命とサイズをそれぞれ制御できます。

[cache-config]:
  https://github.com/rails/solid_cache#cache-configuration

### キャッシュの有効期限を制御する

Solid Cacheは、キャッシュの書き込みをトラッキングするために、書き込みごとにカウンタをインクリメントします。カウンタが[キャッシュ設定][cache-config]で指定した`expiry_batch_size`の50%に達すると、キャッシュの有効期限を処理するバックグラウンドタスクがトリガーされます。

このアプローチにより、キャッシュ容量を縮小する必要が生じたときに、キャッシュレコードが書き込みを上回るペースで確実に失効するようになります。

バックグラウンドタスクは書き込みが発生した場合にのみ実行されるため、キャッシュが更新されない限りプロセスはアイドル状態のままです。キャッシュの失効処理をスレッドではなくバックグラウンドジョブで実行したい場合は、[キャッシュ設定][cache-config]の`expiry_method`を`:job`に設定してください。

### キャッシュをシャーディングする

キャッシュをさらに大規模化する必要が生じた場合のために、Solid Cacheでは**シャーディング**（sharding: キャッシュを複数のデータベースに分割する）をサポートしています。
これによりキャッシュの負荷が分散されてさらに強力になります。

シャーディングを有効にするには、まず以下のように複数のキャッシュデータベースをdatabase.ymlに追加します。

```yaml
# config/database.yml
production:
  cache_shard1:
    database: cache1_production
    host: cache1-db
  cache_shard2:
    database: cache2_production
    host: cache2-db
  cache_shard3:
    database: cache3_production
    host: cache3-db
```

さらに、キャッシュの設定ファイルでシャードを指定する必要もあります。

```yaml
# config/cache.yml
production:
  databases: [cache_shard1, cache_shard2, cache_shard3]
```

### 暗号化

Solid Cacheは、機密データを保護するための暗号化をサポートしています。

暗号化を有効にするには、キャッシュ設定ファイルで`encrypt`値を設定します。

```yaml
# config/cache.yml
production:
  encrypt: true
```

さらに、アプリケーションで[Active Record暗号化](active_record_encryption.html)をセットアップする必要もあります。

その他のキャッシュストア
------------------

Railsは、キャッシュデータを保存するさまざまなストアを提供しています（SQLキャッシュを除く）。

### 設定

別のキャッシュストアをセットアップするには、`config.cache_store`オプションを使います。キャッシュストアのコンストラクタには、引数として他のパラメータも渡せます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

または、設定ブロックの外部で`ActionController::Base.cache_store`を設定することも可能です。

キャッシュにアクセスするには、`Rails.cache`を呼び出します。

#### コネクションプールのオプション

[`:mem_cache_store`](#activesupport-cache-memcachestore)と[`:redis_cache_store`](#activesupport-cache-rediscachestore)は、デフォルトではコネクションプールを利用します。つまり、[Puma][]（または別のスレッド化サーバー）を使えば、複数のスレッドがキャッシュストアへのクエリを同時実行できるようになります。

コネクションプールを無効にしたい場合は、キャッシュストアの設定時に`:pool`オプションを`false`に設定します。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: false }
```

また、`:pool`オプションに個別のオプションを指定することで、デフォルトのプール設定をオーバーライドすることも可能です。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: { size: 32, timeout: 1 } }
```

* `:size`: プロセス1個あたりのコネクション数を指定します（デフォルトは5）。

* `:timeout`: コネクションを取得できるまでの待ち時間を秒で指定します（デフォルトは5）。
  タイムアウトまでにコネクションを利用できない場合は、`Timeout::Error`エラーが発生します。

[Puma]: https://github.com/puma/puma

### `ActiveSupport::Cache::Store`

[`ActiveSupport::Cache::Store`][]は、Railsでキャッシュとやりとりするための基盤を提供します。これは抽象クラスなので、単体では利用できません。代わりに、ストレージエンジンと結びついたこのクラスの具体的な実装が必要です。

Railsには、以下で説明するいくつかの実装が組み込まれています。

主要なAPIメソッドを以下に示します。

* [`read`][ActiveSupport::Cache::Store#read]
* [`write`][ActiveSupport::Cache::Store#write]
* [`delete`][ActiveSupport::Cache::Store#delete]
* [`exist?`][ActiveSupport::Cache::Store#exist?]
* [`fetch`][ActiveSupport::Cache::Store#fetch]

キャッシュストアのコンストラクタに渡されたオプションは、該当するAPIメソッドのデフォルトオプションとして扱われます。

[`ActiveSupport::Cache::Store`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
[ActiveSupport::Cache::Store#delete]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-delete
[ActiveSupport::Cache::Store#exist?]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-exist-3F
[ActiveSupport::Cache::Store#fetch]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch
[ActiveSupport::Cache::Store#read]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-read
[ActiveSupport::Cache::Store#write]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-write

### `ActiveSupport::Cache::MemoryStore`

[`ActiveSupport::Cache::MemoryStore`][]は、エントリを同じRubyプロセス内のメモリに保持します。

キャッシュストアのサイズを制限するには、キャッシュの初期化で`memory_store`を設定するときに`:size`オプションを指定します（デフォルトは32MB）。キャッシュがこのサイズを超えるとクリーンアップが開始され、直近の利用が最も少ない（LRU: Least Recently Used）エントリから削除されます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

Ruby on Railsサーバーのプロセスを複数実行している場合（Phusion PassengerやPumaをクラスタモードで利用している場合）は、Railsサーバーのキャッシュデータをプロセスのインスタンス間で共有できなくなります。

このキャッシュストアは、アプリケーションを大規模にデプロイするには適していません。ただし、小規模でトラフィックの少ないサイトでサーバープロセスを数個動かす程度であれば問題なく動作します。もちろん、development環境やtest環境でも動作します。

新規Railsプロジェクトのdevelopment環境では、`memory_store`の実装がデフォルトで使われます。

NOTE: `:memory_store`を使うとキャッシュデータがプロセス間で共有されないため、Railsコンソールでの変更は、そのコンソールプロセスにのみ影響し、実行中のサーバープロセスには影響しません。

[`ActiveSupport::Cache::MemoryStore`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemoryStore.html

### `ActiveSupport::Cache::FileStore`

[`ActiveSupport::Cache::FileStore`][]は、キャッシュエントリをファイルシステムに保存します。`file_store`を使う場合は、キャッシュを初期化するときにファイル保存場所へのパスを指定する必要があります。

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

このキャッシュストアを使うと、同一ホスト上にある複数のサーバープロセス間でキャッシュを共有できるようになります。

このキャッシュストアは、1〜2台のホストで運用される、トラフィックが小〜中規模のサイトに向いています。共有ファイルシステムを使えば、異なるホストで実行するサーバープロセス間のキャッシュを共有することも一応可能ですが、この設定は推奨されていません。

ファイルストアのキャッシュはディスクがいっぱいになるまで増加し続けるため、古いエントリを定期的に削除することをおすすめします。

[`ActiveSupport::Cache::FileStore`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/FileStore.html

### `ActiveSupport::Cache::MemCacheStore`

[`ActiveSupport::Cache::MemCacheStore`][]は、[`memcached`][]を用いてアプリケーションキャッシュの保存先を一元化します。デフォルトでは、本体にバンドルされている[`dalli`][] gemが使われます。`MemCacheStore`は、高性能かつ冗長性のある単一の共有キャッシュクラスタを提供できます。

キャッシュを初期化するときは、クラスタ内の全memcachedサーバーのアドレスを指定するか、`MEMCACHE_SERVERS`環境変数を適切に設定しておく必要があります。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

どちらも指定されていない場合は、memcachedがlocalhostのデフォルトポート（`127.0.0.1:11211`）で実行されていると仮定しますが、これは大規模サイトのセットアップには向いていません。

```ruby
config.cache_store = :mem_cache_store # $MEMCACHE_SERVERSにフォールバックし、次に127.0.0.1:11211になる
```

サポートされているアドレスの種類について詳しくは[`Dalli::Client`のドキュメント][`Dalli::Client`]を参照してください。

このキャッシュの[`write`][ActiveSupport::Cache::MemCacheStore#write]メソッド（および`fetch`メソッド）には、memcached固有の機能を利用する追加オプションを渡せます。

[`ActiveSupport::Cache::MemCacheStore`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html
[`memcached`]: https://memcached.org/
[ActiveSupport::Cache::MemCacheStore#write]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html#method-i-write
[`Dalli::Client`]:
  https://www.rubydoc.info/gems/dalli/Dalli/Client#initialize-instance_method

### `ActiveSupport::Cache::RedisCacheStore`

[`ActiveSupport::Cache::RedisCacheStore`][]は、メモリ使用量が最大に達したときに[Redis][]の自動eviction（立ち退き）を利用して、Memcachedキャッシュサーバーと同様の機能を実現しています。

NOTE: Redisのキーはデフォルトでは無期限なので、キャッシュ専用のRedisサーバーを別途使うようにし、永続化用のRedisサーバーには期限付きのキャッシュデータを保存しないようにしてください。詳しくは[Redis cache server setup guide](https://redis.io/topics/lru-cache)（英語）を参照してください。

「キャッシュのみ」のRedisサーバーでは、`maxmemory-policy`をallkeysのバリエーションのいずれかに設定します。最も利用頻度の低いキーを削除する`allkeys-lfu`は、デフォルトの選択肢として適しています。

キャッシュの読み書きのタイムアウトは、やや小さめに設定しましょう。多くの場合、キャッシュされた値を再生成する方が、1秒以上待って取得するよりも高速です。読み取りと書き込みのタイムアウトはデフォルトで1秒ですが、ネットワークのレイテンシが一貫して低い場合は、さらに短い値を設定できます。

キャッシュストアがリクエスト中にRedisへの接続に失敗した場合、デフォルトでは再接続を1回試みます。

キャッシュの読み書きでは決して例外が発生せず、単に`nil`を返してあたかも何もキャッシュされていないかのように振る舞います。

キャッシュで例外が生じているかどうかを計測するには、`error_handler`を渡して例外収集サービスにレポートを送信してもよいでしょう。`error_handler`は以下の3つのキーワード引数を受け取れる必要があります。

- `method`: 最初に呼び出されたキャッシュストアメソッド名
- `returning`: ユーザーに返した値（通常は`nil`）
- `exception`: rescueされた例外

Redisを利用するには、まず`Gemfile`にredis gemを追加します。

```ruby
gem "redis"
```

最後に、関連する`config/environments/*.rb`ファイルに以下の設定を追加します。

```ruby
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

より複雑なproduction向けRedisキャッシュストアの設定は、以下のような感じになります。

```ruby
cache_servers = %w(redis://cache-01:6379/0 redis://cache-02:6379/0)
config.cache_store = :redis_cache_store, { url: cache_servers,

  connect_timeout:    30,  # デフォルトは1（秒）
  read_timeout:       0.2, # デフォルトは1（秒）
  write_timeout:      0.2, # デフォルトは1（秒）
  reconnect_attempts: 2,   # デフォルトは1

  error_handler: -> (method:, returning:, exception:) {
    # エラーをwarningとしてSentryに送信する
    Sentry.capture_exception exception, level: "warning",
      tags: { method: method, returning: returning }
  }
}
```

[`ActiveSupport::Cache::RedisCacheStore`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html
[Redis]: https://redis.io/

### `ActiveSupport::Cache::NullStore`

[`ActiveSupport::Cache::NullStore`][]は、リクエスト間でキャッシュされた値を永続化しません。development環境やtest環境での利用を想定しています。

`null_store`キャッシュストアは、`Rails.cache`と直接やりとりするコードを使っていて、キャッシュが原因でコード変更の結果が反映されなくなる場合に使うと非常に便利なことがあります。

```ruby
config.cache_store = :null_store
```

[`ActiveSupport::Cache::NullStore`]:
    https://api.rubyonrails.org/classes/ActiveSupport/Cache/NullStore.html

### カスタムのキャッシュストア

キャッシュストアを独自に作成するには、`ActiveSupport::Cache::Store`を拡張して適切なメソッドを実装します。これにより、Railsアプリケーションで任意のキャッシュ技術に差し替えられるようになります。

カスタムのキャッシュストアを利用するには、キャッシュストアに自作クラスの新しいインスタンスを設定します。

```ruby
config.cache_store = MyCacheStore.new
```

キャッシュの高度な利用パターン
-------------------------

### バックグラウンドジョブやその他のリクエスト外コンテキストでキャッシュを利用する

キャッシュの利用は、コントローラのアクションに限定されません。バックグラウンドジョブ、Service Objectパターン、スクリプト、その他のアプリケーションコードでも`Rails.cache`を利用できます。

低レベルキャッシュは、リクエスト内でもリクエスト外でも同じように動作します。

```ruby
class ReportJob < ApplicationJob
  def perform(account)
    Rails.cache.fetch([account, "daily-report"], expires_in: 1.hour) do
      account.generate_daily_report
    end
  end
end
```

ただし、一部のキャッシュ動作は、Railsの実行コンテキスト内で動作することに依存しています。Active Recordのクエリキャッシュや、その他の実行ごとのステートは、Railsが管理する通常のリクエストやジョブに対して自動的にセットアップされます。

アプリケーションコードをカスタムスレッドや長時間実行されるスクリプトから独自に実行する場合は、Railsがステートを正しく管理できるようにするため、以下のように`Rails.application.executor.wrap`でラップしてください。

```ruby
Rails.application.executor.wrap do
  Rails.cache.fetch("stats", expires_in: 5.minutes) { expensive_calculation }
end
```

Executorや非リクエストコードの実行について詳しくは、[Rails のスレッドとコード実行](threading_and_code_execution.html)ガイドを参照してください。

### ローカルキャッシュ

一部のキャッシュストアは、「ローカルキャッシュ（local cache）」レイヤをサポートしています。これは、リクエストやブロックの実行中に最近読み取った値をメモリに保持することで、同じキーに対する読み取りの繰り返しを、背後のキャッシュストアを利用せずに提供できるようにします。

ローカルキャッシュは、特にRedisやMemcachedなどのリモートキャッシュストアで非常に有効です。ネットワーク経由の往復が繰り返されるのを避けることでパフォーマンスが向上します。

通常のRailsリクエストでは、ローカルキャッシュはミドルウェアによって管理されます。以下のようにブロックで囲むことで、ローカルキャッシュを手動で利用することも可能です。

```ruby
Rails.cache.with_local_cache do
  Rails.cache.read("hot-key")
  Rails.cache.read("hot-key")
end
```

ローカルキャッシュはあくまで一時的なものであり、現在の実行に限定されます。メインのキャッシュストアに取って代わるものではなく、ローカルキャッシュに書き込まれた値はリクエスト・ジョブ・プロセス間で共有されません。
