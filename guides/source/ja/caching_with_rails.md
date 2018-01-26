


Rails のキャッシュ: 概要
===============================

本ガイドでは、キャッシュを導入してRailsアプリケーションを高速化する方法をご紹介します。

「キャッシュ（caching）」とは、リクエスト・レスポンスのサイクルの中で生成されたコンテンツを保存しておき、次回同じようなリクエストが発生したときのレスポンスでそのコンテンツを再利用することを指します。

ほとんどの場合、キャッシュは、アプリケーションのパフォーマンスを効果的に増大するのに最適な方法です。キャッシュを導入することで、単一サーバー、単一データベースのwebサイトでも数千ユーザーの同時接続による負荷に耐えられるようになります。

Railsには、面倒な設定なしですぐ利用できるキャッシュ機能がひととおり用意されています。本ガイドで、それぞれの機能について目的を解説します。Railsのキャッシュ機能を使いこなすことで、応答時間の低下や高額なサーバー使用料に悩まされずに、Railsアプリケーションが数百万ビューをこなせるようになります。

このガイドの内容:

* フラグメントキャッシュとロシアンドールキャッシュ
* キャッシュの依存関係の管理
* 代替キャッシュストア
* 条件付きGETのサポート

--------------------------------------------------------------------------------

基本的なキャッシュ
-------------

ここでは、キャッシュの手法を3種類ご紹介します。「ページキャッシュ」「アクションキャッシュ」「フラグメントキャッシュ」です。Railsのフラグメントキャッシュは本体に組み込まれており、デフォルトで利用できます。ページキャッシュやアクションキャッシュを利用するには、Gemfileに`actionpack-page_caching` gemや`actionpack-action_caching` gemを追加する必要があります。

キャッシュは、デフォルトではproduction環境でのみ有効になります。ローカルでキャッシュを使ってみたい場合は、対応する`config/environments/*.rb`ファイルで`config.action_controller.perform_caching`を`true`に設定します。

```ruby
config.action_controller.perform_caching = true
```

NOTE: `config.action_controller.perform_caching`値の変更は、Action Controllerコンポーネントで提供されるキャッシュでのみ有効になります。つまり、後述する [低レベルキャッシュ](#低レベルキャッシュ) の動作には影響しません。

### ページキャッシュ

Railsのページキャッシュは、apacheやnginxなどのwebサーバーによって生成されるページへのリクエストを（Railsスタック全体を経由せずに）キャッシュするメカニズムです。ページキャッシュはきわめて高速ですが、常に有効とは限りません。たとえば、認証にはページキャッシュは適用されません。また、webサーバーはファイルシステムから直接ファイルを読み出して利用するので、キャッシュの有効期限の実装も必要です。

INFO: ページキャッシュ機能は、Rails 4本体から取り除かれ、gem化されました。[actionpack-page_caching gem](https://github.com/rails/actionpack-page_caching)をご覧ください。

### アクションキャッシュ

ページキャッシュは、before_filterのあるアクション（認証の必要なページなど）には適用できません。アクションキャッシュは、このような場合に使います。アクションキャッシュの動作は、ページキャッシュと似ていますが、webサーバーへのリクエストがRailsスタックにヒットしたときに、before_filterを実行してからキャッシュを返す点が異なります。これによって、キャッシュの恩恵を受けながら、認証などの制限をかけられるようになります。

INFO: アクションキャッシュ機能は、Rails 4本体から取り除かれ、gem化されました。[actionpack-action_caching gem](https://github.com/rails/actionpack-action_caching)をご覧ください。新しい推奨メソッドについては、[DHH's key-based cache expiration overview](http://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works) をご覧ください。

### フラグメントキャッシュ

通常、動的なwebアプリケーションでは、ページのキャッシュ時の特性が異なるさまざまなコンポーネントによってページが生成されます。ページ内の異なる部品について、キャッシュや期限切れを個別に設定したい場合は、フラグメントキャッシュを使います。

フラグメントキャッシュでは、ビューのロジックのフラグメントをキャッシュブロックでラップし、次回のリクエストでそれをキャッシュストアから取り出して送信します。

たとえば、ページ内で表示する製品（product）を個別にキャッシュしたい場合、次のように書くことができます。

```html+erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

Railsアプリケーションが最初のリクエストを受信すると、一意のキーを備えた新しいキャッシュが保存されます。生成されるキーは次のようなものになります。

```
views/products/1-201505056193031061005000/bea67108094918eeba42cd4a6e786901
```

キーの中間にある長い数字は、`product_id`と、productレコードの`updated_at`属性のタイムスタンプ値です。タイムスタンプ値は、古いデータを返さないようにするために使われます。`updated_at`値が更新されると新しいキーが生成され、そのキーで新しいキャッシュを保存します。古いキーで保存された古いキャッシュは二度と利用されなくなります。この手法は「キーベースの有効期限」と呼ばれます。

キャッシュされたフラグメントは、ビューのフラグメントが変更された場合（ビューのHTMLが変更された場合など）にも期限が切れます。キーの後半にある文字列は、「テンプレートツリーダイジェスト」です。これは、キャッシュされるビューフラグメントの内容から算出されたMD5ハッシュです。ビューフラグメントが変更されると、MD5ハッシュも変更され、既存のファイルが期限切れになります。

TIP: Memcachedなどのキャッシュストアでは、古いキャッシュファイルを自動的に削除します。

特定の条件を満たす場合にのみフラグメントをキャッシュしたい場合は、`cache_if`や`cache_unless`を使います。

```erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### コレクションキャッシュ

`render`ヘルパーでは、コレクションを指定して個別のテンプレートをレンダリングするときにもキャッシュを利用できます。上の例で`each`を使っているコードで、全キャッシュテンプレートを（個別に読み出す代わりに）一括で読み出すこともできます。この機能を利用するには、コレクションをレンダリングするときに`cached: true`を指定します。

```html+erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

これにより、前回までにレンダリングされた全キャッシュテンプレートが一括で読み出され、劇的に速度が向上します。さらに、それまでキャッシュされていなかったテンプレートもキャッシュに追加され、次回のレンダリングでまとめて読み出されるようになります。


### ロシアンドールキャッシュ

フラグメントキャッシュ内で、さらにフラグメントをキャッシュしたいことがあります。このようにキャッシュをネストする手法を、マトリョーシカ人形のイメージになぞらえて「ロシアンドールキャッシュ」（Russian doll caching）と呼びます。

ロシアンドールキャッシュを使うことで、たとえば内側のフラグメントで製品（product）が1件だけ更新された場合に、内側の他のフラグメントを捨てずに再利用し、外側のフラグメントは通常通り再生成できます。

前節で解説したように、キャッシュされたファイルは、そのファイルが直接依存しているレコードの`updated_at`の値が変わると期限切れになりますが、そのフラグメント内でネストするキャッシュは期限切れになりません。

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

gameの属性で変更が発生すると、`updated_at`値が現在時刻で更新され、キャッシュが期限切れになります。しかし、productオブジェクトの`updated_at`は変更されないので、productのキャッシュは期限切れにならず、アプリケーションは古いデータを返します。これを修正したい場合は、次のように`touch`メソッドでモデル同士を結びつけます。

```ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end 
```

`touch`をtrueに設定すると、gameのレコードの`updated_at`を更新するアクションを実行すると、関連付けられているproductの`updated_at`も同様に更新されてキャッシュの期限が終了します。
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121546
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121572
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121576
-->
### 依存関係の管理
<!-- 
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121619
-->
キャッシュを正しく無効にするには、キャッシュの依存関係を適切に定義する必要があります。多くの場合、Railsでは依存関係が適切に処理されるので、特別な対応は不要です。ただし、カスタムヘルパーでキャッシュを扱うなどの場合は、明示的に依存関係を定義する必要があります。

#### 暗黙の依存関係
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121602
-->
ほとんどの場合、テンプレートの依存関係は、テンプレート自身で呼び出される`render`によって発生します。以下の例は、デコード方法を取り扱う`ActionView::Digestor`でrender呼び出しする方法です。

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" => render("comments/header")

render(@topic)         => render("topics/topic")
render(topics)         => render("topics/topic")
render(message.topics) => render("topics/topic")
```

一方、一部の呼び出しについて、キャッシュが適切に動作するよう変更が必要です。たとえば、独自のコレクションを渡す場合は、次のように変更する必要があります。

```ruby
render @project.documents.where(published: true)
```

上のコードを次のように変更します。

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

#### 明示的な依存関係
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121648
-->
テンプレートで、思わぬ依存関係が生じることがあります。典型的なのは、ヘルパー内でレンダリングする場合です。以下に例を示します。

```html+erb
<%= render_sortable_todolists @project.todolists %>
```

このような呼び出しには、次の特殊なコメント形式で明示的に依存関係を示す必要があります。

```html+erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

特殊なケース（単一テーブル継承の設定など）では、こうした明示的な依存関係を多数含むことがあります。個別のテンプレートを記述する代わりに、次のようにディレクトリ内の全テンプレートをワイルドカードで指定できます。

```html+erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

コレクションのキャッシュで、部分テンプレート（パーシャル）の冒頭でクリーンなキャッシュ呼び出しを行わない場合は、次の特殊コメント形式をテンプレートのどこかに追加することで、コレクションキャッシュを引き続き有効にできます。

```html+erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

#### 外部の依存関係

たとえば、キャッシュされたブロック内にヘルパーメソッドがあるとします。このヘルパーを更新するときに、キャッシュにもヒットしてしまわないよう、テンプレートファイルのMD5が何らかの方法で変更されるようにする必要があります。推奨される方法のひとつは、次のようにコメントで明示的に更新を示すことです。

```html+erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

### 低レベルキャッシュ

ビューのフラグメントをキャッシュするのではなく、特定の値やクエリ結果だけをキャッシュしたいことがあります。Railsのキャッシュメカニズムでは、どんな情報でもキャッシュに保存できます。
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27121773
-->
低レベルキャッシュの最も効果的な実装方法は、`Rails.cache.fetch`メソッドを利用することです。このメソッドは、キャッシュの書き込みと読み出しの両方に対応しています。引数が1つだけの場合、キーを読み出し、キャッシュから値を取り出して返します。ブロックを引数として渡すと、指定のキーでブロックの処理結果がキャッシュされ、その結果を返します。

次の例を考えてみましょう。アプリケーションに`Product`モデルがあり、競合webサイトの製品価格を検索するインスタンスメソッドがそのモデルにあるとします。低レベルキャッシュを使う場合、このメソッドから完全なデータが返ります。

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 上の例では`cache_key`メソッドを使っているので、キャッシュキーは`products/233-20140225082222765838000/competing_price`のような形式になります。`cache_key`で生成される文字列は、モデルの`id`と`updated_at`属性を元にしています。この生成ルールは一般的に使われており、productが更新されるたびにキャッシュを無効にできます。一般に、インスタンスレベルの情報に低レベルキャッシュを適用する場合、キャッシュキーを生成する必要があります。

### SQL キャッシュ

Railsのクエリキャッシュは、各クエリによって返った結果セットをキャッシュする機能です。リクエストによって以前と同じクエリが発生すると、データベースへのクエリを実行する代わりに、キャッシュされた結果セットを利用します。

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

データベースに対して同じクエリが2回実行されると、実際にはデータベースにアクセスしません。1回目のクエリでは、結果をメモリ上のクエリキャッシュに保存し、2回目のクエリではメモリから結果を読み出します。

ただし、次の点にご注意ください。クエリキャッシュはアクションの開始時に作成され、アクションの終了時に破棄されます。従って、キャッシュはアクションの実行中しか保持されません。キャッシュをもっと持続させたい場合は、低レベルキャッシュを使います。

キャッシュストア
------------

Railsには、キャッシュデータの保存場所がいくつも用意されています。なお、SQLキャッシュやページキャッシュはこの中に含まれません。

### 設定

アプリケーションのデフォルトのキャッシュストアは、`config.cache_store`オプションで設定できます。キャッシュストアのコンストラクタには、引数として他にもパラメータを渡せます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

NOTE: または、構成ブロックの外部で`ActionController::Base.cache_store`を呼び出すこともできます。

キャッシュにアクセスするには、`Rails.cache`を呼び出します。

### ActiveSupport::Cache::Store

このクラスは、Railsのキャッシュにアクセスするための基盤を提供します。抽象クラスであるため、直接利用できません。クラスを利用するには、ストレージエンジンに関連付けられたクラスを実装する必要があります。Railsでは以下が実装されています。

主要なメソッドは、`read`、`write`、`delete`、`exist?`、`fetch`です。fetchメソッドはブロックを1つ取り、キャッシュの値か、ブロックの評価を返します。既存の値がキャッシュにない場合は、結果をキャッシュに書き込みます。

いくつかのオプションについては、キャッシュのすべての実装で共通で利用できます。こうしたオプションは、コンストラクタに渡すことも、エントリーにアクセスするさまざまなメソッドに渡すこともできます。

* `:namespace` - キャッシュストア内で名前空間を作成します。特に、キャッシュを他のアプリケーションと共有する場合に役立ちます。

* `:compress` - キャッシュ内での圧縮を有効にします。低速ネットワークで巨大なキャッシュエントリを転送する場合に役立ちます。

* `:compress_threshold` - `:compress`オプションと併用します。キャッシュのサイズが指定の閾値を下回る場合、圧縮しません。デフォルト値は16KBです。

* `:expires_in` - 指定の秒数が経過すると、キャッシュを自動で削除します。

* `:race_condition_ttl` - `:expires_in`と併用します。dog pile（乱闘）効果と呼ばれる競合状態を防止するのに使います。この競合状態は、マルチプロセスによって同じエントリが同時に再生成されたためにキャッシュの期限が切れた場合に発生します。このオプションでは、新しい値の再生成が完了していない状態で、期限切れのエントリを再利用してよい時間を秒で指定します。`:expires_in`オプションを利用する場合は、このオプションにも値を設定することをおすすめします。

#### カスタムのキャッシュストア

キャッシュストアを独自に作成するには、`ActiveSupport::Cache::Store`をextendし、そこに適切なメソッドを実装します。これにより、Railsアプリケーションでさまざまなキャッシュ技術を差し替えることができます。

カスタムのキャッシュストアを利用するには、自作クラスの新しいインスタンスにキャッシュストアを設定します。

```ruby
config.cache_store = MyCacheStore.new
```

### ActiveSupport::Cache::MemoryStore

このキャッシュストアは、同じRubyプロセス内のメモリに保持されます。キャッシュストアのサイズを制限するには、イニシャライザに`:size`オプションを指定します（デフォルトは32MB）。キャッシュがこのサイズを超えるとクリーンアップが開始され、利用時期が最も古いエントリから削除されます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

Ruby on Railsサーバーのプロセスを複数実行している場合（mongrel_clusterやPhusion Passengerを利用中の場合）、Railsサーバーのキャッシュデータはプロセスのインスタンス間で共有されません。このキャッシュストアは、大規模にデプロイされるアプリケーションには向いていません。ただし、小規模でトラフィックの少ないサイトでサーバープロセスを数個動かす程度であれば問題なく動作します。もちろん、development環境やtest環境でも動作します。

### ActiveSupport::Cache::FileStore

このキャッシュストアでは、エントリをファイルシステムに保存します。ファイル保存場所へのパスは、キャッシュを初期化するときに指定する必要があります。

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

このキャッシュストアでは、複数のサーバープロセス間でキャッシュを共有できます。トラフィックが中規模程度のサイトを1、2個程度ホストする場合に向いています。異なるホストで実行するサーバープロセス間で、ファイルシステムによるキャッシュを共有することは一応可能ですが、おすすめできません。

ディスク容量がいっぱいになるほどキャッシュが増加する場合は、古いエントリを定期的に削除することをおすすめします。

これは、デフォルトのキャッシュストア実装です。

### ActiveSupport::Cache::MemCacheStore

このキャッシュストアでは、Dangaの`memcached`サーバーにアプリケーションのキャッシュを一元化保存します。Railsでは、本体にバンドルされている`dalli` gemをデフォルトで使います。現時点で、本番webサイトで最も広く利用されているキャッシュストアです。高性能かつ高冗長性を備えた、単一の共有キャッシュクラスタとして利用できます。

キャッシュの初期化時には、クラスタ内の全memcachedサーバーのアドレスを指定する必要があります。指定がない場合、memcachedがローカルのデフォルトポートで動作していると仮定して起動しますが、この設定は大規模サイトには向いていません。

このキャッシュの`write`メソッドや`fetch`メソッドでは、memcached固有の機能を利用する2つのオプションを指定できます。シリアル化を行わずに値を直接サーバーに送信するには、`:raw`を指定します。値は、文字列か数字を使用します。rawの値のみ、`increment`や`decrement`などを指定してmemcachedを直接操作できます。memcachedで既存エントリの上書きを許可しないようにするには、`:unless_exist`を指定します。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```
<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122060
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122073
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122078
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122080
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122081
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122082
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122084
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122085
-->

### ActiveSupport::Cache::NullStore

このキャッシュストア実装は、development環境やtest環境のみで使用され、実際にはキャッシュをまったく保存しません。これは、たとえば`Rails.cache`に直接アクセスするコードの効果が、キャッシュのせいで確認しづらい場合にきわめて便利です。このキャッシュストアを使うと、`fetch`や`read`はまったくヒットしなくなります。

```ruby
config.cache_store = :null_store
```

キャッシュのキー
----------

キャッシュのキーは、`cache_key`や`to_param`のいずれかに対応するオブジェクトになります。独自のキーを生成したい場合は、`cache_key`メソッドをクラスで実装してください。Active Recordでは、クラス名とレコードIDに基いてキーを生成します。

キャッシュのキーとして、値のハッシュや、値の配列を指定できます。

```ruby
# 通常のキャッシュキー
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

`Rails.cache`のキーは、ストレージエンジンで実際に使われるキーと異なります。実際のキーは、名前空間によって修飾されたり、バックエンドの技術的制約に合わせて変更されていたりする可能性もあります。つまり、`Rails.cache`で値を保存してから`dalli` gemで値を取り出す、といったことはできません。その代わり、memcachedのサイズ制限や、構文規則違反について心配する必要もありません。

条件付きGETのサポート
-----------------------

条件付きGETは、HTTP仕様で定められた機能です。GETリクエストへのレスポンスが前回のリクエストからまったく変わっていない場合はブラウザ内キャッシュを使ってもよいと、webサーバーからブラウザに通知します。

この機能では、`HTTP_IF_NONE_MATCH`ヘッダと`HTTP_IF_MODIFIED_SINCE`ヘッダを使って、一意のコンテンツIDや最終変更タイムスタンプをやり取りします。コンテンツID（etag）か最終更新タイムスタンプが、サーバー側のバージョンと一致した場合は、サーバーから「変更なし」ステータスのみを持つ空レスポンスを返します。

最終更新タイムスタンプやif-none-matchヘッダの有無を確認し、完全なレスポンスを返す必要があるかどうかを決定するのは、サーバー側（つまり開発者）の責任です。Railsでは、次のように条件付きGETを簡単に利用できます。

```ruby
class ProductsController < ApplicationController

  def show
    @product = Product.find(params[:id])

    # 指定のタイムスタンプやetag値によって、リクエストが古いことがわかった場合
    # （再処理が必要な場合）、このブロックを実行
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key)
      respond_to do |wants|
        # ... 通常のレスポンス処理
      end
    end

    # リクエストが新鮮（つまり前回から変更なし）な場合は
    # 処理不要。デフォルトのレンダリングでは、前回の`stale?`呼び出しの結果に基いて
    # 処理が必要かどうかを判断し、
    # :not_modifiedを送信する。以上でおしまい。
  end
end
```

オプションハッシュの代わりに、単にモデルで渡すこともできます。Railsの`last_modified`や`etag`の設定では、`updated_at`メソッドや`cache_key`メソッドが使われます。

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

特殊なレスポンス処理を行わず、デフォルトのレンダリングメカニズムを使う（つまり`respond_to`を使ったり独自にレンダリングしたりしない）場合、`fresh_when`ヘルパーで簡単に処理できます。

```ruby
class ProductsController < ApplicationController

  # リクエストが古くなければ自動的に:not_modifiedを返す
  # 古い場合はデフォルトのテンプレート（product.*）を返す

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

<!--
TODO: https://github.com/yasslab/railsguides.jp/commit/d2e8af6cf0dbc3374c8553c362e90b75604b9765#r27122153
-->

### 強いETagと弱いETag

Railsでは、デフォルトで「弱い」ETagを使います。弱いETagでは、レスポンスのbodyが微妙に異なっている場合にも同じETagを与えることで、事実上同じレスポンスとして扱えるようになります。レスポンスbodyのごく一部が変更されたときにページの再生成を避けたい場合に便利です。

弱いETagには`W/`が付けられ、強いETagと区別できます。

```
  W/"618bbc92e2d35ea1945008b42799b0e7" → 弱いETag
  "618bbc92e2d35ea1945008b42799b0e7" → 強いETag
```

強いETagは、弱いETagと異なり、レスポンスがバイトレベルで完全一致することが求められます。巨大な動画やPDFファイル内でRangeリクエストを実行する場合に便利です。Akamaiなど一部のCDNでは、強いETagのみをサポートしています。強いETagの生成がどうしても必要な場合は、次のようにします。

```ruby
  class ProductsController < ApplicationController
    def show
      @product = Product.find(params[:id])
      fresh_when last_modified: @product.published_at.utc, strong_etag: @product
    end
  end
```

次のように、レスポンスに強いETagを直接設定することもできます。

```ruby
  response.strong_etag = response.body # => "618bbc92e2d35ea1945008b42799b0e7"
```

参考資料
----------

* [DHH: キーに基づく有効期限](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)
* [Ryan Bates Railscast: キャッシュダイジェスト](http://railscasts.com/episodes/387-cache-digests)
