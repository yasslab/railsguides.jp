Rails のキャッシュ機構
===============================

本ガイドでは、キャッシュを導入してRailsアプリケーションを高速化する方法を解説します。

このガイドの内容:

* キャッシュとは何か
* キャッシュ戦略の種類
* キャッシュの依存関係の管理
* Solid Cache - データベースをバックエンドにしたActive Supportキャッシュストア
* その他の代替キャッシュストア
* キャッシュキー
* 条件付きGETのサポート

--------------------------------------------------------------------------------

キャッシュとは何か
----------------

「キャッシュ（caching）」とは、リクエスト・レスポンスサイクルの中で生成されたコンテンツを保存しておき、次回同じようなリクエストが発生したときのレスポンスでそのコンテンツを再利用することを指します。
キャッシュとは、お気に入りのコーヒーカップをキッチンの戸棚ではなく机の上に置いておくのと似ています。必要なときにすぐに手に届くところに置いておけば、時間と労力を節約できます。

多くの場合、キャッシュはアプリケーションのパフォーマンスを効果的に増大するのに最適な方法です。キャッシュを導入することで、単一サーバーや単一データベースのWebサイトでも、数千ユーザーの同時接続による負荷に耐えられるようになります。

Railsには、すぐ利用できるキャッシュ機能がいくつも用意されており、データを単にキャッシュできるだけでなく、キャッシュの有効期限、キャッシュの依存関係、キャッシュの無効化などの課題にも対処できます。

本ガイドでは、フラグメントキャッシュからSQLキャッシュまで、Railsの包括的なキャッシュ戦略について解説します。これらの手法により、Railsアプリケーションのレスポンス時間を短縮して、サーバー料金がかさまないよう管理可能な範囲に抑えながら、数百万ビューを配信できるようになります。

基本的なキャッシュ
-------------

NOTE: 訳注: 「ページキャッシュ」と「アクションキャッシュ」の項目はRails 8.0.1で削除されました。

ここでは、キャッシュの手法をいくつか紹介します。

デフォルトでは、Action Controllerのキャッシュはproduction環境でのみ有効になります。
`rails dev:cache`コマンドを実行するか、`config/environments/development.rb`ファイルで[`config.action_controller.perform_caching`][]を`true`に設定することで、ローカルでキャッシュを試せるようになります。

NOTE: `config.action_controller.perform_caching`値の変更は、Action Controllerコンポーネントで提供されるキャッシュでのみ有効です。つまり、後述する[低レベルキャッシュ](#低レベルキャッシュ)の動作には影響しません。

[`config.action_controller.perform_caching`]:
  configuring.html#config-action-controller-perform-caching

### フラグメントキャッシュ

通常、動的なWebアプリケーションではさまざまなコンポーネントを用いてページをビルドしますが、コンポーネントごとのキャッシュ特性は同じではありません。ページ内のさまざまなパーツごとにキャッシュや有効期限を設定したい場合は、フラグメントキャッシュを利用できます。

フラグメントキャッシュを使うと、ビューのロジックのフラグメントをキャッシュブロックでラップし、次回のリクエストでそれをキャッシュストアから取り出して配信します。

たとえば、ページ内で表示する製品（product）を個別にキャッシュしたい場合は、次のように書けます。

```html+erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

Railsアプリケーションが最初のリクエストを受信すると、一意のキーを持つ新しいキャッシュエントリが保存されます。生成されるキーは次のようなものになります。

```
views/products/index:bea67108094918eeba42cd4a6e786901/products/1
```

キーの途中にある文字列は、テンプレートツリーのダイジェストです。これは、キャッシュするビューフラグメントのコンテンツを元に算出されたハッシュダイジェストです。ビューフラグメントが変更されると（HTMLが変更されるなど）、このダイジェストも変更されて既存のファイルが無効になります。

productレコードから派生するキャッシュバージョンは、キャッシュエントリに保存されます。
productが変更されるとキャッシュバージョンが変更され、以前のバージョンを含むキャッシュフラグメントはすべて無視されます。

TIP: Memcachedなどのキャッシュストアは、古いキャッシュファイルを自動削除します。

条件を指定してフラグメントをキャッシュしたい場合は、`cache_if`や`cache_unless`を利用できます。

```erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### コレクションキャッシュ

`render`ヘルパーは、コレクションでレンダリングされた個別のテンプレートもキャッシュできます。上の`each`によるコード例のようにキャッシュテンプレートを個別に読み出す代わりに、すべてのキャッシュテンプレートを一括で読み出すことも可能です。この機能を利用するには、コレクションをレンダリングするときに以下のように`cached: true`を指定します。

```html+erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

これにより、前回までにレンダリングされたすべてのキャッシュテンプレートが一括で読み出され、劇的に速度が向上します。しかも、それまでキャッシュされていなかったテンプレートもキャッシュに追加され、次回のレンダリングでまとめて読み出されるようになります。

キャッシュのキーはカスタマイズ可能です。以下のコード例では、productページでローカライズ結果が別のローカライズで上書きされないようにするため、現在のロケールをキャッシュにプレフィックスしています。

```html+erb
<%= render partial: 'products/product',
           collection: @products,
           cached: ->(product) { [I18n.locale, product] } %>
```

### ロシアンドールキャッシュ

別のフラグメントキャッシュの内側にフラグメントをキャッシュしたいことがあります。このようにキャッシュをネストする手法を、マトリョーシカ人形のイメージになぞらえて「ロシアンドールキャッシュ」（Russian doll caching）と呼びます。

ロシアンドールキャッシュのメリットは、たとえば内側のフラグメントで製品（product）が1件だけ更新された場合に、内側の他のフラグメントを捨てずに再利用し、外側のフラグメントは通常どおり再生成できることです。

前節で解説したように、キャッシュされたファイルは、そのファイルが直接依存しているレコードの`updated_at`の値が変わると失効しますが、そのフラグメント内でネストしたキャッシュは失効しません。

次のビューを例に説明します。

```erb
<% cache product do %>
  <%= render product.games %>
<% end %>
```

上のビューをレンダリングした後、次のビューをレンダリングします。

```erb
<% cache game do %>
  <%= render game %>
<% end %>
```

gameのいずれかの属性で変更が発生すると、`updated_at`値が現在時刻で更新され、キャッシュが無効になります。しかし、productオブジェクトの`updated_at`は変更されないので、productのキャッシュは無効にならず、アプリケーションは古いデータを配信します。これを修正したい場合は、次のように`touch`メソッドでモデル同士を結びつけます。

```ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end
```

`touch`を`true`に設定すると、あるgameレコードの`updated_at`を更新するアクションを実行したときに、関連付けられているproductの`updated_at`も同様に更新して、キャッシュを無効にします。

### 共有パーシャルキャッシュ

共有パーシャルキャッシュ（shared partial cacning）では、パーシャルのキャッシュや関連付けのキャッシュをMIMEタイプの異なる複数のファイルで共有できます。
たとえば、パーシャルキャッシュを共有すると、テンプレートのライターがHTMLとJavaScript間でパーシャルキャッシュを共有できるようになります。テンプレートリゾルバのファイルパスに複数のテンプレートがある場合は、テンプレート言語の拡張子のみが含まれ、MIMEタイプは含まれません。これによって、テンプレートを複数のMIMEタイプで利用できます。

HTMLリクエストとJavaScriptリクエストは、いずれも以下のコードにレスポンスを返します。

```ruby
render(partial: "hotels/hotel", collection: @hotels, cached: true)
```

上のコードは`hotels/hotel.erb`という名前のファイルを読み込みます。

別の方法は、レンダリングするパーシャルで以下のように`formats`属性を指定することです。

```ruby
render(partial: "hotels/hotel", collection: @hotels, formats: :html, cached: true)
```

上のコードは、ファイルのMIMEタイプにかかわらず`hotels/hotel.html.erb`という名前のファイルを読み込み、たとえばJavaScriptファイルでこのパーシャルをインクルードできるようになります。

### `Rails.cache`による低レベルキャッシュ

ビューのフラグメントをキャッシュする代わりに、特定の値やクエリ結果をキャッシュする必要が生じる場合があります。Railsのキャッシュメカニズムは、シリアライズ可能な情報を保存するのに最も適しています。

低レベルキャッシュを実装する効率的な方法は、`Rails.cache.fetch`メソッドを使うことです。このメソッドは、キャッシュからの**読み取り**とキャッシュへの**書き込み**の両方を処理します。
引数を1個だけ渡して呼び出すと、指定されｔキーのキャッシュ値を取得して返します。
ブロックを渡して呼び出すと、ブロックはキャッシュミスの場合にのみ実行されます。指定したキャッシュキーの下のキャッシュにブロックの戻り値を書き込んでから、制御を戻します。キャッシュヒットの場合は、ブロックを実行せずにキャッシュされた値を直接返します。

以下の例を考えてみましょう。このアプリケーションには、ライバルWebサイトで製品価格を検索するインスタンスメソッドを持つ`Product`モデルがあります。このメソッドによって返されるデータは、低レベルキャッシュに最適です。

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key_with_version}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 上の例では`cache_key_with_version`メソッドを使っているため、結果のキャッシュキーは`products/233-20140225082222765838000/competing_price`のような形式になります。この`cache_key_with_version`メソッドは、モデルのクラス名、`id`、`updated_at`属性に基づいてこの文字列を生成します。これは一般によく使われる生成手法であり、製品が更新されるたびにキャッシュが無効になるというメリットがあります。一般に、低レベルのキャッシュを使う場合はキャッシュキーを生成する必要があります。

低レベルキャッシュの他の利用例も以下に示します。

```ruby
# `write`で値をキャッシュに保存する
Rails.cache.write("greeting", "Hello, world!")

# `read`でキャッシュから値を取り出す
greeting = Rails.cache.read("greeting")
puts greeting # 出力: Hello, world!

# `fetch`は、キャッシュが存在しない場合はデフォルト値を設定するためにブロックで値を取得する
welcome_message = Rails.cache.fetch("welcome_message") { "Welcome to Rails!" }
puts welcome_message # 出力: Welcome to Rails!

# `delete`はキャッシュの値を削除する
Rails.cache.delete("greeting")
```

#### Active Recordオブジェクトのインスタンスのキャッシュは避けること

以下の例を考えてみましょう。このコードでは、スーパーユーザーを表すActive Recordオブジェクトのリストをキャッシュに保存しています。

```ruby
# super_adminsを取り出すSQLクエリは重いので頻繁に実行しないこと
Rails.cache.fetch("super_admin_users", expires_in: 12.hours) do
  User.super_admins.to_a
end
```

このパターンは**避けるべき**です。理由は、インスタンスが変更される可能性があるためです。

production環境では、インスタンスの属性が異なっている可能性もあれば、レコードが削除されている可能性もあります。また、development環境でこのコードに変更を加えてコードが再読み込みされると、キャッシュストアが不安定になります。

インスタンスそのものをキャッシュするのではなく、以下のようにid（またはその他のプリミティブデータ型）をキャッシュするようにしましょう。

```ruby
# super_adminsを取り出すSQLクエリは重いので頻繁に実行しないこと
ids = Rails.cache.fetch("super_admin_user_ids", expires_in: 12.hours) do
  User.super_admins.pluck(:id)
end
User.where(id: ids).to_a
```

### SQLキャッシュ

Railsのクエリキャッシュは、各クエリが返す結果セットをキャッシュする機能です。リクエストによって以前と同じクエリが発生した場合は、データベースへのクエリを実行する代わりに、キャッシュされた結果セットを利用します。

以下に例を示します。

```ruby
class ProductsController < ApplicationController
  def index
    # 検索クエリの実行
    @products = Product.all

    ...

    # 同じクエリの再実行
    @products = Product.all
  end
end
```

同じクエリをデータベースに対して再実行しても、実際にはデータベースにアクセスしません。クエリから最初に結果が返されたときは、結果をメモリ上のクエリキャッシュに保存し、2回目はメモリから結果を取得します。ただし取得のたびに、クエリされたオブジェクトの新しいインスタンスが作成されます。

NOTE: クエリキャッシュはアクションの開始時に作成され、そのアクションの終了時に破棄されるため、アクションの継続時間中のみ保持されます。クエリ結果をより永続的な形で保存したい場合は、低レベルキャッシュを利用できます。

## 依存関係の管理

キャッシュを正しく無効にするには、キャッシュの依存関係を適切に定義する必要があります。多くの場合、Railsでは依存関係が適切に処理されるので、特別な対応は不要です。ただし、カスタムヘルパーでキャッシュを扱うなどの場合は、明示的に依存関係を定義する必要があります。

### 暗黙の依存関係

テンプレートの依存関係は、ほとんどの場合テンプレート自身で呼び出される`render`から導出されます。デコード方法を取り扱う[`ActionView::Digestor`][]で`render`を呼び出す方法の例を以下にいくつか示します。

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render "comments/comments"
render("comments/comments")

render "header" # render("comments/header")に変換される

render(@topic)         # render("topics/topic")に変換される
render(topics)         # render("topics/topic")に変換される
render(message.topics) # render("topics/topic")に変換される
```

ただし、一部の呼び出しについては、キャッシュが適切に動作するための変更が必要です。たとえば、独自のコレクションを渡す場合は、次のように変更する必要があります。

```ruby
render @project.documents.where(published: true)
```

上のコードを次のように変更します。

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

[`ActionView::Digestor`]:
  https://api.rubyonrails.org/classes/ActionView/Digestor.html

### 明示的な依存関係

テンプレートの依存関係を自動的に導出できないことがあります。以下のようなヘルパー内でのレンダリングが典型的な例です。

```html+erb
<%= render_sortable_todolists @project.todolists %>
```

このような呼び出しでは、次の特殊なコメント形式で明示的に依存関係を示す必要があります。

```html+erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

単一テーブル継承（STI）などでは、こうした明示的な依存関係を多数書かなければならなくなる可能性もあります。テンプレートごとに依存関係を書く代わりに、以下のようにワイルドカードを用いてディレクトリ内の任意のテンプレートにマッチさせることも可能です。

```html+erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

コレクションのキャッシュで、パーシャルの冒頭でクリーンなキャッシュ呼び出しを行わない場合は、以下の特殊コメント形式をテンプレートの任意の場所に追加することで、コレクションキャッシュを引き続き有効にできます。

```html+erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

### 外部の依存関係

たとえば、キャッシュされたブロック内でヘルパーメソッドを利用すると、このヘルパーを更新するときにキャッシュも更新しなければならなくなります。キャッシュの更新方法はさほど問題ではありませんが、テンプレートファイルのMD5を変更しなければなりません。推奨されている方法の1つは、以下のようにコメントで明示的に更新を示すことです。

```html+erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

Solid Cache
-----------

Solid Cacheは、データベース上に構築されるActive Supportキャッシュストアです。
従来のハードディスクよりずっと高速な最新の[SSD][]（ソリッドステートドライブ）を活用して、より大きなストレージ容量とシンプルなインフラストラクチャを備えたコストパフォーマンスの高いキャッシュを提供します。
SSDはRAMより若干遅いのですが、ほとんどのアプリケーションではその差はわずかであり、RAMよりも多くのデータを保存できるためキャッシュを頻繁に無効化する必要がないことで補われています。その結果、平均キャッシュミスが少なくなり、応答時間が速くなります。

Solid Cacheは[FIFO](https://ja.wikipedia.org/wiki/FIFO)（先入れ先出し）キャッシュ戦略を採用しています。
FIFO戦略では、キャッシュが上限に達したときに、キャッシュに最初に追加された項目が最初に削除されます。このアプローチは、最も最近アクセスされていない項目を最初に削除する [LRU][]（least recently used: 最も最近使われていない）キャッシュ戦略と比較するとシンプルな代わりに効率は落ちます。これにより、利用頻度の高いデータが重点的に最適化されます。ただしSolid Cacheは、キャッシュの持続期間を長くすることでFIFOの低効率を補い、キャッシュが無効化される頻度を減らします。

Solid Cacheは、Rails 8.0以降ではデフォルトで有効になっています。ただし、Solid Cacheが不要な場合は、以下のように`rails new`コマンドでスキップできます。

```bash
rails new app_name --skip-solid
```

WARNING: `--skip-solid`フラグを指定すると、Solid CacheとSolid Queueが両方ともスキップされます。Solid Queueを利用するがSolid Cacheは利用しない場合は、`rails app:enable-solid-queue`を実行してSolid Queueを有効にできます。

[SSD]:
  https://ja.wikipedia.org/wiki/%E3%82%BD%E3%83%AA%E3%83%83%E3%83%89%E3%82%B9%E3%83%86%E3%83%BC%E3%83%88%E3%83%89%E3%83%A9%E3%82%A4%E3%83%96
[FIFO]:
  https://ja.wikipedia.org/wiki/FIFO
[LRU]:
  https://ja.wikipedia.org/wiki/Least_Recently_Used

### データベースを設定する

Solid Cacheを利用するには、`config/database.yml`ファイルでデータベースコネクションを設定できます。
以下はSQLiteデータベースの設定例です。

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

この設定では、キャッシュされたデータを保存するために`cache`で指定したデータベースが使われます。必要に応じて、MySQLやPostgreSQLなどの別のデータベースアダプタも指定できます。

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

キャッシュの設定で`database`や[`databases`](#sharding-the-cache)が無指定の場合、Solid Cacheは`ActiveRecord::Base`コネクションプールを使います。つまり、キャッシュの読み取りと書き込みは、それらをラップするデータベーストランザクションの一部になります。

production環境のキャッシュストアは、以下のようにデフォルトでSolid Cacheストアを利用するように設定されます。

```yaml
  # config/environments/production.rb
  config.cache_store = :solid_cache_store
```

前述の[`Rails.cache`による低レベルキャッシュ](#rails.cacheによる低レベルキャッシュ)も参照してください。

### キャッシュストアをカスタマイズする

Solid Cacheの設定は、`config/cache.yml`ファイルでカスタマイズできます。

```yaml
default: &default
  store_options:
    # 保持ポリシーを満たすために最も古いキャッシュエントリの保存期間を制限する
    max_age: <%= 60.days.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>
```

`store_options`で利用できるキーの完全なリストについては、Solid Cache READMEの[キャッシュ設定](https://github.com/rails/solid_cache#cache-configuration)を参照してください。

ここでは`max_age`オプションと`max_size`オプションを調整して、キャッシュエントリの有効期間とサイズを制御できます。

### キャッシュの有効期限を処理する

Solid Cacheは、書き込みごとにカウンタを増やすことでキャッシュ書き込みをトラッキングします。
カウンターが[キャッシュ設定](https://github.com/rails/solid_cache#cache-configuration)の`expiry_batch_size`の50%に達すると、キャッシュの有効期限を処理するバックグラウンドタスクがトリガーされます。このアプローチにより、キャッシュ容量を縮小する必要がある場合、キャッシュレコードの有効期限が書き込みよりも早いタイミングで確実に失効するようになります。

バックグラウンドタスクは書き込みがある場合にのみ実行されるため、キャッシュが更新されない限りプロセスはアイドル状態のままです。有効期限プロセスをスレッドではなくバックグラウンドジョブで実行したい場合は、[キャッシュ設定](https://github.com/rails/solid_cache#cache-configuration)の`expiry_method`を`:job`に設定します。

### キャッシュをシャーディングする

キャッシュでさらなるスケーラビリティが必要な場合、Solid Cacheはシャーディング（sharding: キャッシュを複数のデータベースに分割する）をサポートしています。
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

Solid Cacheは機密データを保護するために暗号化をサポートしています。暗号化を有効にするには、キャッシュ設定ファイルで`encrypt`値を設定します。

```yaml
# config/cache.yml
production:
  encrypt: true
```

さらに、アプリケーションで[Active Record暗号化](active_record_encryption.html)を利用する設定も必要です。

### developmentモードでのキャッシュ

developmentモードでは、デフォルトで[`:memory_store`](#activesupport-cache-memorystore)によるキャッシュが**有効**になります。これは、デフォルトで無効になっているAction Controllerキャッシュには適用されません。

Railsは、Action Controllerキャッシュの有効・無効を切り替える`bin/rails dev:cache`コマンドを提供しています。

```bash
$ bin/rails dev:cache
Development mode is now being cached.
$ bin/rails dev:cache
Development mode is no longer being cached.
```

development環境でSolid Cacheを使いたい場合は、`config/environments/development.rb`ファイルで`cache_store`に`:solid_cache_store`を設定します。

```ruby
config.cache_store = :solid_cache_store
```

さらに、`cache`データベースを作成してマイグレーションを実行しておく必要もあります。

```bash
development:
  <<: * default
  database: cache
```

TIP: キャッシュそのものを無効にするには、`cache_store`に[`:null_store`](#activesupport-cache-nullstore)を設定します。

その他のキャッシュストア
------------

Railsは、キャッシュデータを保存するさまざまなストアが用意されています（SQLキャッシュを除く）。

### 設定

アプリケーションのデフォルトのキャッシュストアは、`config.cache_store`オプションで設定できます。キャッシュストアのコンストラクタには、引数として他のパラメータも渡せます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

または、設定ブロックの外部で`ActionController::Base.cache_store`を設定することも可能です。

キャッシュにアクセスするには、`Rails.cache`を呼び出します。

#### コネクションプールのオプション

[`:mem_cache_store`](#activesupport-cache-memcachestore)と[`:redis_cache_store`](#activesupport-cache-rediscachestore)は、デフォルトではプロセスごとに1つのコネクションを利用します。これは、[Puma][]（または別のスレッド化サーバー）を使えば、複数のスレッドがキャッシュストアへのクエリを同時実行できるということです。

コネクションプールを無効にしたい場合は、キャッシュストアの設定時に`:pool`オプションを`false`に設定します。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: false }
```

また、`:pool`オプションに個別のオプションを指定することで、デフォルトのプール設定をオーバーライドすることも可能です。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: { size: 32, timeout: 1 } }
```

* `:size`: プロセス1個あたりのコネクション数を指定します（デフォルトは5）

* `:timeout`: コネクションごとの待ち時間を秒で指定します（デフォルトは5）。
  タイムアウトまでにコネクションを利用できない場合は、`Timeout::Error`エラーが発生します。

[Puma]: https://github.com/puma/puma

### `ActiveSupport::Cache::Store`

[`ActiveSupport::Cache::Store`][]は、Railsでキャッシュとやりとりするための基盤を提供します。これは抽象クラスなので、単体では利用できません。代わりに、ストレージエンジンと結びついたこのクラスの具体的な実装が必要です。Railsには、以下で説明するいくつかの実装が組み込まれています。

主要なAPIメソッドを以下に示します。

* [`read`][ActiveSupport::Cache::Store#read]
* [`write`][ActiveSupport::Cache::Store#write]
* [`delete`][ActiveSupport::Cache::Store#delete]
* [`exist?`][ActiveSupport::Cache::Store#exist?]
* [`fetch`][ActiveSupport::Cache::Store#fetch]

キャッシュストアのコンストラクタに渡されるオプションは、該当するAPIメソッドのデフォルトオプションとして扱われます。

[`ActiveSupport::Cache::Store`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
[ActiveSupport::Cache::Store#delete]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-delete
[ActiveSupport::Cache::Store#exist?]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-exist-3F
[ActiveSupport::Cache::Store#fetch]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch
[ActiveSupport::Cache::Store#read]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-read
[ActiveSupport::Cache::Store#write]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-write

### `ActiveSupport::Cache::MemoryStore`

[`ActiveSupport::Cache::MemoryStore`][]は、エントリーを同じRubyプロセス内のメモリに保持します。
キャッシュストアのサイズを制限するには、イニシャライザで`:size`オプションを指定します（デフォルトは32MB）。キャッシュがこのサイズを超えるとクリーンアップが開始され、直近の利用が最も少ない（LRU: Least Recently Used）エントリから削除されます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

Ruby on Railsサーバーのプロセスを複数実行している場合（Phusion PassengerやPumaをクラスタモードで利用している場合）は、Railsサーバーのキャッシュデータをプロセスのインスタンス間で共有できなくなります。このキャッシュストアは、アプリケーションを大規模にデプロイするには向いていません。ただし、小規模でトラフィックの少ないサイトでサーバープロセスを数個動かす程度であれば問題なく動作します。もちろん、development環境やtest環境でも動作します。

新規Railsプロジェクトのdevelopment環境では、この実装をデフォルトで使うよう設定されます。

NOTE: `:memory_store`を使うとキャッシュデータがプロセス間で共有されないため、Railsコンソールから手動でキャッシュを読み書きすることも無効にすることもできません。

[`ActiveSupport::Cache::MemoryStore`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemoryStore.html

### `ActiveSupport::Cache::FileStore`

[`ActiveSupport::Cache::FileStore`][]は、エントリをファイルシステムに保存します。キャッシュを初期化するときに、ファイル保存場所へのパスを指定する必要があります。

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

このキャッシュストアを使うと、同一ホスト上にある複数のサーバープロセス間でキャッシュを共有できるようになります。トラフィックが中規模程度のサイトを1、2個程度ホストする場合に向いています。異なるホストで実行するサーバープロセス間のキャッシュを共有ファイルシステムで共有することも一応可能ですが、おすすめできません。

ファイルストアのキャッシュはディスクがいっぱいになるまで増加するため、古いエントリを定期的に削除することをおすすめします。

[`ActiveSupport::Cache::FileStore`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/FileStore.html

### `ActiveSupport::Cache::MemCacheStore`

[`ActiveSupport::Cache::MemCacheStore`][]は、アプリケーションキャッシュの保存先をDangaの`memcached`サーバーに一元化します。Railsでは、本体にバンドルされている`dalli` gemがデフォルトで使われます。`dalli`は、現時点で最も広くproduction Webサイトで利用されているキャッシュストアです。高性能かつ高冗長性を備えており、単一のキャッシュストアも共有キャッシュクラスタも提供できます。

キャッシュを初期化するときは、クラスタ内の全memcachedサーバーのアドレスを指定するか、`MEMCACHE_SERVERS`環境変数を適切に設定しておく必要があります。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

どちらも指定されていない場合は、memcachedがlocalhostのデフォルトポート（`127.0.0.1:11211`）で実行されていると仮定しますが、これは大規模サイトのセットアップには向いていません。

```ruby
config.cache_store = :mem_cache_store # $MEMCACHE_SERVERSにフォールバックし、次に127.0.0.1:11211になる
```

サポートされているアドレスの種類について詳しくは[`Dalli::Client`のドキュメント][`Dalli::Client`]を参照してください。

このキャッシュの[`write`][ActiveSupport::Cache::MemCacheStore#write]メソッド（および`fetch`メソッド）は、memcached固有の機能を利用する追加オプションを受け取れます。

[`ActiveSupport::Cache::MemCacheStore`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html
[ActiveSupport::Cache::MemCacheStore#write]:
  https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html#method-i-write
[`Dalli::Client`]:
  https://www.rubydoc.info/gems/dalli/Dalli/Client#initialize-instance_method

### `ActiveSupport::Cache::RedisCacheStore`

[`ActiveSupport::Cache::RedisCacheStore`][]は、メモリ使用量が最大に達したときにRedisの自動eviction（立ち退き）を利用して、Memcachedキャッシュサーバーと同様の機能を実現しています。

デプロイに関するメモ: Redisのキーはデフォルトでは無期限なので、専用のRedisキャッシュサーバーを使うときはご注意ください。永続化用のRedisサーバーに期限付きのキャッシュデータを保存してはいけません。詳しくは[Redis cache server setup guide](https://redis.io/topics/lru-cache)（英語）を参照してください。

「キャッシュのみ」のRedisサーバーでは、`maxmemory-policy`に以下のいずれかのallkeysを設定してください。
Redis 4以降では`allkeys-lfu`によるLFU（Least Frequently Used: 利用頻度が最も低いキャッシュを削除する）evictionアルゴリズムがサポートされており、これはデフォルトの選択肢として優れています。
Redis 3以前では、`allkeys-lru`を用いてLRU（Least Recently Used: 直近の利用が最も少ないキャッシュを削除する）アルゴリズムにすべきです。

キャッシュの読み書きのタイムアウトは、やや低めに設定しましょう。キャッシュの取り出しで1秒以上待つよりも、キャッシュ値を再生成する方が高速になることもよくあります。読み書きのデフォルトタイムアウト値は1秒ですが、ネットワークのレイテンシが常に低い場合は値を小さくするとよい結果が得られることがあります。

キャッシュストアがリクエスト中に接続に失敗した場合、デフォルトではRedisへの再接続を1回試みます。

キャッシュの読み書きでは決して例外が発生せず、単に`nil`を返してあたかも何もキャッシュされていないかのように振る舞います。
キャッシュで例外が生じているかどうかを測定するには、`error_handler`を渡して例外収集サービスにレポートを送信してもよいでしょう。収集サービスは、「`method`（最初に呼び出されたキャッシュストアメソッド名、）」「`returning`（ユーザーに返した値（通常は`nil`）」「`exception`（rescueされた例外）」の3つのキーワード引数を受け取れる必要があります。

Redisを利用するには、まず`Gemfile`にredis gemを追加します。

```ruby
gem "redis"
```

最後に、関連する`config/environments/*.rb`ファイルに以下の設定を追加します。

```ruby
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

少し複雑なproduction向けRedisキャッシュストアは以下のような感じになります。

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

[`ActiveSupport::Cache::RedisCacheStore`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html

### `ActiveSupport::Cache::NullStore`

[`ActiveSupport::Cache::NullStore`][]は個別のWebリクエストを対象とし、リクエストが終了すると保存された値をクリアするので、development環境やtest環境での利用のみを想定しています。`Rails.cache`と直接やりとりするコードを使っていて、キャッシュが原因でコード変更の結果が反映されなくなる場合にこのキャッシュストアを使うと非常に便利です。

```ruby
config.cache_store = :null_store
```

[`ActiveSupport::Cache::NullStore`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Cache/NullStore.html

#### カスタムのキャッシュストア

キャッシュストアを独自に作成するには、`ActiveSupport::Cache::Store`を拡張して適切なメソッドを実装します。これにより、Railsアプリケーションでさまざまなキャッシュ技術に差し替えられるようになります。

カスタムのキャッシュストアを利用するには、自作クラスの新しいインスタンスにキャッシュストアを設定します。

```ruby
config.cache_store = MyCacheStore.new
```

キャッシュのキー
----------

キャッシュで使うキーには、`cache_key`と`to_param`に応答する任意のオブジェクトが使えます。自分のクラスで`cache_key`メソッドを実装すると、カスタムキーを生成できるようになります。Active Recordは、このクラス名とレコードidに基づいてキーを生成します。

キャッシュのキーとして、値のハッシュと配列を指定できます。

```ruby
# このキャッシュキーは有効
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

`Rails.cache`で使うキーは、ストレージエンジンで実際に使われるキーと同じになりません。実際のキーは、バックエンドの技術的制約に合わせて名前空間化または変更される可能性もあります。そのため、たとえば`Rails.cache`で値を保存してから`dalli` gemで値を取り出すようなことはできません。その代わり、memcachedのサイズ制限超過や構文規則違反を気にする必要もありません。

条件付きGETのサポート
-----------------------

条件付きGETは、HTTP仕様で定められた機能です。「GETリクエストへのレスポンスが前回リクエストのレスポンスから変更されていなければ、ブラウザ内キャッシュを安全に利用できる」とWebサーバーからブラウザに通知します。

この機能は、`HTTP_IF_NONE_MATCH`ヘッダと`HTTP_IF_MODIFIED_SINCE`ヘッダを使って、一意のコンテンツidや最終更新タイムスタンプをやり取りします。コンテンツid（[ETag](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/ETag)）または最終更新タイムスタンプがサーバー側のバージョンと一致する場合は、「変更なし」ステータスのみを持つ空レスポンスをサーバーが返すだけで済みます。

最終更新タイムスタンプや`if-none-match`ヘッダの有無を確認して、完全なレスポンスを返す必要があるかどうかを決定するのは、サーバー側（つまり開発者）の責任です。Railsでは、次のように条件付きGETを比較的簡単に利用できます。

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
    # デフォルトのレンダリングでは、前回の`stale?`呼び出しの結果に基いて
    # 処理が必要かどうかを判断して :not_modifiedを送信するだけでよい。
  end
end
```

オプションハッシュの代わりに、単にモデルを渡すことも可能です。Railsの`last_modified`や`etag`の設定では、`updated_at`メソッドや`cache_key_with_version`メソッドが使われます。

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

特殊なレスポンス処理を使わずにデフォルトのレンダリングメカニズムを利用する（つまり`respond_to`も使わず独自レンダリングもしない）場合は、`fresh_when`ヘルパーで簡単に処理できます。

```ruby
class ProductsController < ApplicationController
  # リクエストがフレッシュな自動的に:not_modifiedを返す
  # 古い場合はデフォルトのテンプレート（product.*）を返す

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

`last_modified`と`etag`が両方設定されている場合の振る舞いは、`config.action_dispatch.strict_freshness`の値によって異なります。

- `true`に設定されている場合、RFC 7232セクション6で指定されているように`etag`のみが考慮されます。
- `false`に設定されている場合、両方の条件が満たされていれば、キャッシュは最新のものと見なされます。これは、従来のRailsの振る舞いと同じです。

静的ページなどの有効期限のないページでキャッシュを有効にしたいことがあります。`http_cache_forever`ヘルパーを使うと、ブラウザやプロキシでキャッシュを無期限にできます。

キャッシュのレスポンスはデフォルトではprivateになっており、キャッシュはユーザーのWebブラウザでのみ行われます。プロキシでレスポンスをキャッシュ可能にするには、`public: true`を設定してすべてのユーザーへのレスポンスがキャッシュされるようにします。

このヘルパーメソッドを使うと、`last_modified`ヘッダーが`Time.new(2011, 1, 1).utc`に設定され、`expires`ヘッダーが100年に設定されます。

WARNING: このメソッドの利用には十分ご注意ください。ブラウザやプロキシにキャッシュされたレスポンスは、ユーザーがブラウザ側でキャッシュを強制的にクリアしない限り無効にできません。

```ruby
class HomeController < ApplicationController
  def index
    http_cache_forever(public: true) do
      render
    end
  end
end
```

### 強いETagと弱いETag

Railsは、デフォルトで「弱い」[ETag](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/ETag)を使います。弱いETagでは、レスポンスのbodyが微妙に異なる場合にも同じETagを与えることで、事実上同じレスポンスとして扱えるようになります。レスポンスbodyのごく一部が変更されたときにページを再生成したくない場合に便利です。

弱いETagの冒頭には`W/`が追加されるので、強いETagと区別できます。

```
  W/"618bbc92e2d35ea1945008b42799b0e7" → 弱いETag
  "618bbc92e2d35ea1945008b42799b0e7"   → 強いETag
```

強いETagは、弱いETagと異なり、レスポンスがバイトレベルで完全一致しなければなりません。強いETagは巨大な動画やPDFファイル内でRangeリクエストを実行する場合に便利です。Akamaiなど一部のCDNでは、強いETagのみをサポートしています。強いETagの生成がどうしても必要な場合は、次のようにできます。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

次のように、レスポンスに強いETagを直接設定することも可能です。

```ruby
response.strong_etag = response.body # => "618bbc92e2d35ea1945008b42799b0e7"
```
