Rails のキャッシュ機構
===============================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Caching with Rails: An Overview](https://guides.rubyonrails.org/caching_with_rails.html)を日本語に翻訳した文書です。

本ガイドでは、キャッシュを導入してRailsアプリケーションを高速化する方法を解説します。

「キャッシュ（caching）」とは、リクエスト・レスポンスのサイクルの中で生成されたコンテンツを保存しておき、次回同じようなリクエストが発生したときのレスポンスでそのコンテンツを再利用することを指します。

多くの場合、キャッシュはアプリケーションのパフォーマンスを効果的に増大するのに最適な方法です。キャッシュを導入することで、単一サーバーや単一データベースのWebサイトでも、数千ユーザーの同時接続による負荷に耐えられるようになります。

Railsには、すぐ利用できるキャッシュ機能がいくつも用意されています。本ガイドでは、それぞれの機能について目的を解説します。Railsのキャッシュ機能を使いこなすことで、応答時間の低下や高額なサーバー使用料に悩まされずに、Railsアプリケーションが数百万ビューを配信できるようになります。

このガイドの内容:

* フラグメントキャッシュとロシアンドールキャッシュ
* キャッシュの依存関係の管理
* 代替キャッシュストア
* 条件付きGETのサポート

--------------------------------------------------------------------------------


基本的なキャッシュ
-------------

ここでは、キャッシュの手法を3種類ご紹介します。「ページキャッシュ」「アクションキャッシュ」「フラグメントキャッシュ」です。Railsのフラグメントキャッシュは本体に組み込まれており、デフォルトで利用できます。ページキャッシュやアクションキャッシュを利用するには、`Gemfile`に`actionpack-page_caching` gemや`actionpack-action_caching` gemを追加する必要があります。

キャッシュは、デフォルトではproduction環境でのみ有効になります。ローカルでキャッシュを使ってみたい場合は、対応する環境の`config/environments/*.rb`ファイルで[`config.action_controller.perform_caching`][]を`true`に設定します。

NOTE: `config.action_controller.perform_caching`値の変更は、Action Controllerコンポーネントで提供されるキャッシュでのみ有効です。つまり、後述する[低レベルキャッシュ](#低レベルキャッシュ)の動作には影響しません。

[`config.action_controller.perform_caching`]: configuring.html#config-action-controller-perform-caching

### ページキャッシュ

Railsのページキャッシュは、apacheやnginxなどのWebサーバーによって生成されるページへのリクエストを、Railsスタック全体を経由せずにキャッシュするメカニズムです。ページキャッシュはきわめて高速ですが、どんな場面でも有効とは限りません。たとえば、認証の必要なページにはキャッシュが適用されません。また、Webサーバーはファイルシステムから直接ファイルを読み出して配信するので、キャッシュを失効させる機能の実装も必要です。

INFO: ページキャッシュ機能は、Rails 4で本体から削除されてgem化されました。[actionpack-page_caching](https://github.com/rails/actionpack-page_caching) gemを参照してください。

### アクションキャッシュ

ページキャッシュは、`before_filter`のあるアクション（認証の必要なページなど）には適用できません。アクションキャッシュは、このような場合に使います。アクションキャッシュの動作は、ページキャッシュと似ていますが、WebサーバーへのリクエストがRailsスタックに到達したときに、`before_filter`を実行してからキャッシュを配信する点が異なります。これによって、認証などの制限をかけながらキャッシュを配信できるようになります。

INFO: アクションキャッシュ機能は、Rails 4から削除されました。詳しくは[actionpack-action_caching](https://github.com/rails/actionpack-action_caching) gemを参照してください。推奨される新しい方法については、[DHH's key-based cache expiration overview](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)を参照してください。

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

### パーシャルのキャッシュを共有する

パーシャルのキャッシュや関連付けのキャッシュをMIMEタイプの異なる複数のファイルで共有できます。たとえば、パーシャルキャッシュを共有すると、テンプレートのライターがHTMLとJavaScript間でパーシャルキャッシュを共有できるようになります。テンプレートリゾルバのファイルパスに複数のテンプレートがある場合は、テンプレート言語の拡張子のみが含まれ、MIMEタイプは含まれません。これによって、テンプレートを複数のMIMEタイプで利用できます。HTMLリクエストとJavaScriptリクエストは、いずれも以下のコードにレスポンスを返します。

```ruby
render(partial: 'hotels/hotel', collection: @hotels, cached: true)
```

上のコードは`hotels/hotel.erb`という名前のファイルを読み込みます。

以下のように、レンダリングするパーシャルの完全なファイル名も指定できます。

```ruby
render(partial: 'hotels/hotel.html.erb', collection: @hotels, cached: true)
```

上のコードは、ファイルのMIMEタイプにかかわらず`hotels/hotel.html.erb`という名前のファイルを読み込み、たとえばJavaScriptファイルでこのパーシャルをインクルードできるようになります。

### 依存関係の管理

キャッシュを正しく無効にするには、キャッシュの依存関係を適切に定義する必要があります。多くの場合、Railsでは依存関係が適切に処理されるので、特別な対応は不要です。ただし、カスタムヘルパーでキャッシュを扱うなどの場合は、明示的に依存関係を定義する必要があります。

#### 暗黙の依存関係

テンプレートの依存関係は、ほとんどの場合テンプレート自身で呼び出される`render`から導出されます。デコード方法を取り扱う`ActionView::Digestor`で`render`を呼び出す方法の例を以下にいくつか示します。

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" translates to render("comments/header")

render(@topic)         translates to render("topics/topic")
render(topics)         translates to render("topics/topic")
render(message.topics) translates to render("topics/topic")
```

ただし、一部の呼び出しについては、キャッシュが適切に動作するための変更が必要です。たとえば、独自のコレクションを渡す場合は、次のように変更する必要があります。

```ruby
render @project.documents.where(published: true)
```

上のコードを次のように変更します。

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

#### 明示的な依存関係

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

#### 外部の依存関係

たとえば、キャッシュされたブロック内でヘルパーメソッドを利用すると、このヘルパーを更新するときにキャッシュも更新しなければならなくなります。キャッシュの更新方法はさほど問題ではありませんが、テンプレートファイルのMD5を変更しなければなりません。推奨されている方法の1つは、以下のようにコメントで明示的に更新を示すことです。

```html+erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

### 低レベルキャッシュ

ビューのフラグメントをキャッシュするのではなく、特定の値やクエリ結果だけをキャッシュしたいことがあります。Railsのキャッシュメカニズムは、シリアライズ可能な任意の情報をキャッシュに保存するのに適しています。

低レベルキャッシュの最も効果的な実装方法は、`Rails.cache.fetch`メソッドを利用することです。このメソッドは、キャッシュの書き込みと読み出しの両方に対応しています。引数を1個だけ渡すと、キーを読み出し、キャッシュから値を取り出して返します。ブロックを渡すと、キャッシュにヒットしなかった場合にブロックが実行されます。ブロックの戻り値は、指定のキャッシュキーの配下にあるキャッシュに書き込まれます。キャッシュにヒットした場合は、ブロックを実行せずにキャッシュの値を返します。

次の例を考えてみましょう。アプリケーションに`Product`モデルがあり、競合Webサイトの製品価格を検索するインスタンスメソッドがそのモデルにあるとします。このメソッドが返すデータは、低レベルキャッシュに最適です。

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key_with_version}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 上の例では`cache_key_with_version`メソッドを使っているので、キャッシュキーは`products/233-20140225082222765838000/competing_price`のような形式になります。`cache_key_with_version`は、モデルのクラス名と`id`と`updated_at`属性を元に文字列を生成します。この生成ルールは一般的に使われており、productが更新されるたびにキャッシュが無効になるというメリットがあります。一般に、低レベルキャッシュを適用する場合、キャッシュキーを生成する必要があります。

#### Active Recordオブジェクトのインスタンスのキャッシュは避けること

以下のコード例で考えてみましょう。このコードでは、スーパーユーザーを表すActive Recordオブジェクトのリストをキャッシュに保存しています。

```ruby
# super_adminsのSQLクエリは重いので頻繁に実行しないこと
Rails.cache.fetch("super_admin_users", expires_in: 12.hours) do
  User.super_admins.to_a
end
```

このようなパターンは、インスタンスが変更される可能性があるので、**避けてください**。production環境では、インスタンスの属性が変わるかもしれませんし、レコードが削除される可能性もあります。development環境でも、コードを変更すると再読み込みするキャッシュストアの挙動は信頼できません。

インスタンスをキャッシュするのではなく、以下のようにidなどのプリミティブなデータ型をキャッシュするようにしましょう。

```ruby
# super_adminsのSQLクエリは重いので頻繁に実行しないこと
ids = Rails.cache.fetch("super_admin_user_ids", expires_in: 12.hours) do
  User.super_admins.pluck(:id)
end
User.where(id: ids).to_a
```

### SQLキャッシュ

Railsのクエリキャッシュは、各クエリが返す結果セットをキャッシュする機能です。リクエストによって以前と同じクエリが発生すると、データベースへのクエリを実行する代わりに、キャッシュされた結果セットを利用します。

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

データベースに対して同じクエリが再度実行されると、実際にはデータベースにアクセスしません。1回目のクエリでは、結果をメモリ上のクエリキャッシュに保存し、2回目のクエリではメモリから結果を読み出します。

ただし、キャッシュはアクションの実行中しか保持されないという点が重要です（クエリキャッシュはアクションの開始時に作成され、アクションの終了時に破棄されます）。クエリ結果をより長期間保存したい場合は、低レベルキャッシュを利用できます。

キャッシュストア
------------

Railsには、キャッシュデータの保存場所がいくつも用意されています。なお、SQLキャッシュやページキャッシュはこの中に含まれません。

### 設定

アプリケーションのデフォルトのキャッシュストアは、`config.cache_store`オプションで設定できます。キャッシュストアのコンストラクタには、引数として他のパラメータも渡せます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

または、設定ブロックの外部で`ActionController::Base.cache_store`を設定することも可能です。

キャッシュにアクセスするには、`Rails.cache`を呼び出します。

#### コネクションプールのオプション

[`:mem_cache_store`](#activesupport-cache-memcachestore)と[`:redis_cache_store`](#activesupport-cache-rediscachestore)は、デフォルトではプロセスごとに1つのコネクションを利用します。これは、Puma（または別のスレッド化サーバー）を使えば、コネクション待ちをマルチスレッド化できるということです。
利用可能なコネクション数を増やすには、コネクションプールを有効にします。

最初に、Gemfileに`connection_pool` gemを追加します。

```ruby
gem 'connection_pool'
```

次に、`config.cache_store`設定に`:pool_size`オプションや`:pool_timeout`オプションを渡します。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool_size: 5, pool_timeout: 5 }
```

* `:pool_size`: プロセス1個あたりのコネクション数を指定します（デフォルトは5）

* `:pool_timeout`: コネクションごとの待ち時間を秒で指定します（デフォルトは5）。タイムアウトまでにコネクションを利用できない場合は、`Timeout::Error` エラーが発生します。

### `ActiveSupport::Cache::Store`

[`ActiveSupport::Cache::Store`][]は、Railsでキャッシュとやりとりするための基盤を提供します。これは抽象クラスなので、単体では利用できません。代わりに、ストレージエンジンと結びついたこのクラスの具象実装を使う必要があります。Railsにはいくつかの実装が同梱されており、ドキュメントは以下にあります。

主要なAPIメソッドは、[`read`][ActiveSupport::Cache::Store#read]、[`write`][ActiveSupport::Cache::Store#write]、[`delete`][ActiveSupport::Cache::Store#delete]、[`exist?`][ActiveSupport::Cache::Store#exist?]、[`fetch`][ActiveSupport::Cache::Store#fetch]です。

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

キャッシュはディスクが満杯になるまで増加するため、古いエントリを定期的に削除することをおすすめします。

`config.cache_store`を明示的に指定しない場合は、デフォルトのキャッシュストア実装（`"#{root}/tmp/cache/"`）が提供されます。

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

サポートされているアドレスの種類について詳しくは[`Dalli::Client`のドキュメント](https://www.rubydoc.info/github/mperham/dalli/Dalli%2FClient:initialize)を参照してください。

このキャッシュの[`write`][ActiveSupport::Cache::MemCacheStore#write]メソッド（および`fetch`メソッド）は、memcached固有の機能を利用する追加オプションを受け取れます。

[`ActiveSupport::Cache::MemCacheStore`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html
[ActiveSupport::Cache::MemCacheStore#write]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html#method-i-write

### `ActiveSupport::Cache::RedisCacheStore`

[`ActiveSupport::Cache::RedisCacheStore`][]は、メモリ使用量が最大に達したときにRedisの自動eviction（立ち退き）を利用して、Memcachedキャッシュサーバーと同様の機能を実現しています。

デプロイに関するメモ: Redisのキーはデフォルトでは無期限なので、専用のRedisキャッシュサーバーを使うときはご注意ください。永続化用のRedisサーバーに期限付きのキャッシュデータを保存してはいけません。詳しくは[Redis cache server setup guide](https://redis.io/topics/lru-cache)（英語）を参照してください。

「キャッシュのみ」のRedisサーバーでは、`maxmemory-policy`に以下のいずれかのallkeysを設定してください。
Redis 4以降では`allkeys-lfu`によるLFU（Least Frequently Used: 利用頻度が最も低いキャッシュを削除する）evictionアルゴリズムがサポートされており、これはデフォルトの選択肢として非常によいものです。
Redis 3以前では、`allkeys-lru`を用いてLRU（Least Recently Used: 直近の利用が最も少ないキャッシュを削除する）アルゴリズムにすべきです。

キャッシュの読み書きのタイムアウトは、やや低めに設定しましょう。キャッシュの取り出しで1秒以上待つよりも、キャッシュ値を再生成する方が高速になることもよくあります。読み書きのデフォルトタイムアウト値は1秒ですが、ネットワークのレイテンシが常に低い場合は値を小さくするとよい結果が得られることがあります。

キャッシュストアがリクエスト中に接続に失敗した場合、デフォルトではRedisへの再接続を試みません。接続が切れやすい場合は、再接続を試みるようにするとよいでしょう。

キャッシュの読み書きでは決して例外が発生せず、単に`nil`を返してあたかも何もキャッシュされていないかのように振る舞います。キャッシュで例外が生じているかどうかを測定するには、`error_handler`を渡して例外収集サービスにレポートを送信してもよいでしょう。収集サービスは、「`method`（最初に呼び出されたキャッシュストアメソッド名、）」「`returning`（ユーザーに返した値（通常は`nil`）」「`exception`（rescueされた例外）」の3つのキーワード引数を受け取れる必要があります。

Redisを利用するには、まず`Gemfile`にredis gemを追加します。

```ruby
gem 'redis'
```

より高速な[hiredis](https://github.com/redis/hiredis)によるRubyラッパーを`Gemfile`に追加すると、hiredisコネクションライブラリによるサポートを有効にできます。

```ruby
gem 'hiredis'
```

hiredisが利用可能になっていれば、Redisキャッシュストアによって自動的にhiredisが`require`されます。その他の設定は不要です。

最後に、関連する`config/environments/*.rb`ファイルに以下の設定を追加します。

```ruby
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

少し複雑なproduction向けRedisキャッシュストアは以下のような感じになります。

```ruby
cache_servers = %w(redis://cache-01:6379/0 redis://cache-02:6379/0)
config.cache_store = :redis_cache_store, { url: cache_servers,

  connect_timeout:    30,  # デフォルトは20（秒）
  read_timeout:       0.2, # デフォルトは1（秒）
  write_timeout:      0.2, # デフォルトは1（秒）
  reconnect_attempts: 1,   # デフォルトは0

  error_handler: -> (method:, returning:, exception:) {
    # エラーをwarningとしてSentryに送信する
    Raven.capture_exception exception, level: 'warning',
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

[`ActiveSupport::Cache::NullStore`]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/NullStore.html

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

静的ページなどの有効期限のないページでキャッシュを有効にしたいことがあります。`http_cache_forever`ヘルパーを使うと、ブラウザやプロキシでキャッシュを無期限にできます。

キャッシュのレスポンスはデフォルトではprivateになっており、キャッシュはユーザーのWebブラウザでのみ行われます。プロキシでレスポンスをキャッシュ可能にするには、`public: true`を設定してすべてのユーザーへのレスポンスがキャッシュされるようにします。

このヘルパーメソッドを使うと、`last_modified`ヘッダーが`Time.new(2011, 1, 1).utc`に設定され、`expires`ヘッダーが100年に設定されます。

WARNING: このメソッドの利用には十分ご注意ください。ブラウザやプロキシにキャッシュされたレスポンスは、ブラウザのキャッシュを強制的にクリアしない限り無効にできません。

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

development環境のキャッシュ
----------------------

アプリケーションのキャッシュ戦略をdevelopmentモードで試したくなることがよくあります。Railsコマンドの`dev:cache`オプションを使うと、developmentモードのキャッシュを手軽にオンオフできます。

```bash
$ bin/rails dev:cache
Development mode is now being cached.
$ bin/rails dev:cache
Development mode is no longer being cached.
```

NOTE: Railsのdevelopmentモードでは、デフォルトでキャッシュが**オフ**になります。Railsは
[`:null_store`](#activesupport-cache-nullstore)を利用します。

参考
----------

* [DHHによるキーベースのキャッシュ無効化に関する記事](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)（英語）
* [Ryan BatesのRailsCast: キャッシュダイジェストについて](http://railscasts.com/episodes/387-cache-digests)（英語）
