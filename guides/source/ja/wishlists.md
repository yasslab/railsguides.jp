演習: ウィッシュリスト機能の追加
=========

本ガイドでは、[Railsをはじめよう](getting_started.html)で作成した練習用アプリ「`store`」にウィッシュリスト機能を追加する方法について解説します。[演習: ユーザー登録・設定機能の追加](sign_up_and_settings.html)の最終コードを出発点として使います。

このガイドの内容:

* ウィッシュリスト機能を追加する
* カウンタキャッシュを利用する
* ウィッシュリストのURLをフレンドリーURLにする
* ウィッシュリストのレコードをフィルタで絞り込む

--------------------------------------------------------------------------------

はじめに
------------

多くのeコマースストアには、さまざまな製品を共有できるウィッシュリスト機能が備え付けられています。ストアの顧客は、ウィッシュリストを使って今後購入したい製品を追いかけたり、ギフトのアイデアを得るために知人や家族に見せたりできます。

早速作ってみましょう。

ウィッシュリストのモデル
---------------

eコマースストアには、これまでのチュートリアルで構築した`Product`モデルや`User`モデルが既にあります。ウィッシュリストは、これらを基盤として構築する必要があります。1個のウィッシュリストは1人のユーザーに属し、複数の製品のリスト（products）を含みます。

それでは最初に以下のコマンドを実行して、`Wishlist`モデルを作成しましょう。

```bash
$ bin/rails generate model Wishlist user:belongs_to name products_count:integer
```

このモデルには以下の3つの属性があります。

- `user:belongs_to`: `Wishlist`を所有する`User`と関連付けます
- `name`: フレンドリーURLにも使います
- `products_count`: ウィッシュリストに含まれる製品の個数を[カウンタキャッシュ](association_basics.html#カウンタキャッシュ)でカウントするのに使います

1個の`Wishlist`に複数の`Product`を関連付けるには、両者をJOINで結びつける中間テーブルを追加する必要があります。

```bash
$ bin/rails generate model WishlistProduct product:belongs_to wishlist:belongs_to
```

`Wishlist`に同じ`Product`を2つ以上含めたくないので、作成したマイグレーションにインデックスを追加します。

```ruby
class CreateWishlistProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :wishlist_products do |t|
      t.belongs_to :product, null: false, foreign_key: true
      t.belongs_to :wishlist, null: false, foreign_key: true

      t.timestamps
    end

    add_index :wishlist_products, [:product_id, :wishlist_id], unique: true
  end
end
```

最後に、`Wishlist`が`Product`モデルに何個あるかをトラッキングするため、`Product`モデルにカウンタを追加します。

```bash
$ bin/rails generate migration AddWishlistsCountToProducts wishlists_count:integer
```

### カウンタキャッシュのデフォルト値

新しいマイグレーションを実行する前に、カウンタキャッシュのカラムにデフォルト値を設定して、既存のレコードの開始値がNULLではなく`0`になるようにします。

`db/migrate/<タイムスタンプ>_create_wishlists.rb`マイグレーションファイルをエディタで開いて、以下のように`default:`オプションを追加します。

```ruby
class CreateWishlists < ActiveRecord::Migration[8.1]
  def change
    create_table :wishlists do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :name
      t.integer :products_count, default: 0

      t.timestamps
    end
  end
end
```

次に`db/migrate/<タイムスタンプ>_add_wishlists_count_to_products.rb`マイグレーションファイルをエディタで開いて、こちらにもデフォルト値を追加します。

```ruby
class AddWishlistsCountToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :wishlists_count, :integer, default: 0
  end
end
```

終わったらマイグレーションを実行しましょう。

```bash
$ bin/rails db:migrate
```

### 関連付けとカウンタキャッシュ

データベーステーブルを作成したので、Railsのモデルを更新して新しい関連付けを追加しましょう。

`app/models/user.rb`ファイルを開いて`wishlists`関連付けを追加します。

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :wishlists, dependent: :destroy

  # ...
```

`wishlists`関連付けに`dependent: :destroy`を指定することで、`User`モデルが削除されたら関連するウィッシュリストも削除されるようにします。

次に`app/models/product.rb`ファイルを開いて、以下の`has_many`関連付けを追加します。

```ruby
class Product < ApplicationRecord
  include Notifications

  has_many :subscribers, dependent: :destroy
  has_many :wishlist_products, dependent: :destroy
  has_many :wishlists, through: :wishlist_products
  has_one_attached :featured_image
  has_rich_text :description
```

ここでは`Product`モデルに2つの関連付けを追加しました。
1つ目の関連付けは、`WishlistProduct`というJOIN用の中間テーブルを`Product`モデルに関連付けます。
このJOINテーブルを用いて、2つ目の関連付けで`Product`が同じ`WishlistProduct` JOINテーブルを介して複数の`Wishlists`の一部であることをRailsに伝えます。これで、`Product`レコードから`Wishlists`に直接アクセスすると、RailsはSQLクエリで2つのテーブルを自動的に`JOIN`します。

`wishlist_products`関連付けにも`dependent: :destroy`を指定しているので、`Product`が削除されると、すべての`Wishlist`モデルからも製品が削除されます。

カウンタキャッシュは、関連付けられているレコードの件数を保存することで、件数が必要になるたびにクエリを別途実行しなくても件数を取り出せるようにします。
`app/models/wishlist_product.rb`ファイルをエディタで開いて、以下のように2つの関連付けにカウンタキャッシュを追加します。

```ruby
class WishlistProduct < ApplicationRecord
  belongs_to :product, counter_cache: :wishlists_count
  belongs_to :wishlist, counter_cache: :products_count

  validates :product_id, uniqueness: { scope: :wishlist_id }
end
```

ここでは、関連付けられているモデルを更新するためにカラム名を指定しています。
`Product`への関連付けでは`wishlists_count`カラムを指定し、`Wishlist`には`products_count`カラムを指定しています。これらのカウンタキャッシュは、`WishlistProduct`が作成または削除されるたびに更新されます。

また、`uniqueness`バリデーションを追加することで、製品がウィッシュリストに追加済みかどうかをチェックするようRailsに指示します。この`uniqueness`バリデーションを`wishlist_product`のuniqueインデックスと併用することで、データベースレベルでもバリデーションできるようにしています。

最後に、`app/models/wishlist.rb`ファイルをエディタで開いて、関連付けを以下のように更新しましょう。

```ruby
class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_products, dependent: :destroy
  has_many :products, through: :wishlist_products
end
```

`Product`モデルの場合と同様に、`wishlist_products`関連付けに`dependent: :destroy`オプションを指定することで、ウィッシュリストが削除されたときにJOINテーブルのレコードも自動的に削除されるようになります。

### フレンドリーURL

ウィッシュリストを共有する相手は、多くの場合友人や家族です。`Wishlist`を参照するときのURLに含まれるIDは、デフォルトでは単なる整数値です。このままでは、共有したい`Wishlist`を表すURLがどれなのか、URLを見ただけではわかりにくくなってしまいます。

Active Recordの`to_param`クラスメソッドは、整数値IDよりもわかりやすいIDでURLを生成するのに利用できます。`Wishlist`モデルでやってみましょう。

```ruby
class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_products, dependent: :destroy
  has_many :products, through: :wishlist_products

  def to_param
    "#{id}-#{name.squish.parameterize}"
  end
end
```

ここでは、`id`と`name`をハイフンでつないだ形で構成されたURLパラメータの文字列を返す`to_param`インスタンスメソッドを作成しています。`name`は、[`squish`][]メソッドで空白の重複をクリーンアップしてから、さらに[`parameterize`][]メソッドで特殊文字をURL安全な文字列に置き換えています。

[`squish`]: https://api.rubyonrails.org/classes/String.html#method-i-squish
[`parameterize`]: https://api.rubyonrails.org/classes/String.html#method-i-parameterize

これをRailsコンソールでテストしてみましょう。

```bash
$ bin/rails console
```

次に、`User`モデルで使う`Wishlist`のデータを作成します。

```irb
store(dev)> user = User.first
store(dev)> wishlist = user.wishlists.create!(name: "Example Wishlist")
store(dev)> wishlist.to_param
=> "1-example-wishlist"
```

完璧ですね！

それでは、このパラメータでレコードを検索してみましょう。

```irb
store(dev)> wishlist = Wishlist.find("1-example-wishlist")
=> #<Wishlist:0x000000012bb71d68
 id: 1,
 user_id: 1,
 name: "Example Wishlist",
 products_count: nil,
 created_at: "2025-07-22 15:21:29.036470000 +0000",
 updated_at: "2025-07-22 15:21:29.036470000 +0000">
```

成功です！
しかし、なぜこれだけでうまくいくのでしょうか？レコードを検索するときのIDは整数でなければならないはずでは？

実は、この`to_param`では、Rubyが文字列を[`to_i`][]メソッドで整数に変換するときの振る舞いをうまく活用しています。コンソールでそのパラメータを`to_i`で整数に変換してみましょう。

[`to_i`]: https://docs.ruby-lang.org/en/master/String.html#method-i-to_i

```irb
store(dev)> "1-example-wishlist".to_i
=> 1
```

Rubyは文字列を解析するときに、有効な数値ではない文字が見つかった時点で解析をやめます。ここでは、最初のハイフンで解析を停止します。次に、Rubyは文字列`"1"`を整数に変換し、`1`を返します。このおかげで、冒頭にIDをプレフィックスとして付加しても、特別な処理を行わずに`to_param`がシームレスに動作します。

これで振る舞いが理解できたので、`to_param`メソッドを`name`クラスメソッドのショートカット呼び出しに置き換えてみましょう。

```ruby
class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_products, dependent: :destroy
  has_many :products, through: :wishlist_products

  to_param :name
end
```

[`to_param`][]クラスメソッドは、指定した属性と同じ名前のインスタンスメソッドを定義します。このメソッドに渡すパラメータは、パラメータを生成するために呼び出されるメソッド名です。ここでは、パラメータ生成用に`name`属性を引数に渡しています。

[`to_param`]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/Integration/ClassMethods.html#method-i-to_param

`to_param`は、値が20文字を超えたときに単語単位で切り詰める処理も行います。

Railsコンソールでコードを再読み込みして、`Wishlist`に長い名前を渡して試してみましょう。

```irb
store(dev)> reload!
store(dev)> Wishlist.last.update(name: "A really, really long wishlist name!")
store(dev)> Wishlist.last.to_param
=> "1-a-really-really-long"
```

名前が20文字を超えると、最も近い単語で名前が切り詰められていることがわかります。

それではRailsコンソールを閉じて、ウィッシュリストのUI実装を開始しましょう。

## ウィッシュリストに製品を表示する

ユーザーがウィッシュリストを最初に使う場所といえば、`Product`のshowページでしょう。今見ている製品を、後で買うために保存しておくというシナリオが考えられます。これを最初に構築してみましょう。

### ウィッシュリストのフォームに製品表示を追加する

最初に、`config/routes.rb`ファイルを開いて、フォーム送信用のルーティングを追加します。

```ruby
  resources :products do
    resource :wishlist, only: [ :create ], module: :products
    resources :subscribers, only: [ :create ]
  end
```

ウィッシュリストのIDは事前に知りようがないため、ルーティングには単数形の`wishlist`を使う必要があります。また、`module: :products`を使って、このコントローラのスコープを`Products`に限定しています。

`app/views/products/show.html.erb`ファイルに、新しいウィッシュリストのパーシャルをレンダリングするコードを追加します。

```erb
<p><%= link_to "Back", products_path %></p>

<section class="product">
  <%= image_tag @product.featured_image if @product.featured_image.attached? %>

  <section class="product-info">
    <% cache @product do %>
      <h1><%= @product.name %></h1>
      <%= @product.description %>
    <% end %>

    <%= render "inventory", product: @product %>
    <%= render "wishlist", product: @product %>
  </section>
</section>
```

次に、`app/views/products/_wishlist.html.erb`ファイルを以下の内容で作成します。

```erb
<% if authenticated? %>
  <%= form_with url: product_wishlist_path(product) do |form| %>
    <div>
      <%= form.collection_select :wishlist_id, Current.user.wishlists, :id, :name %>
    </div>

    <div>
      <%= form.submit "Add to wishlist" %>
    </div>
  <% end %>
<% else %>
  <%= link_to "Add to wishlist", sign_up_path %>
<% end %>
```

ログインしていないユーザーには、ユーザー登録用のリンクが表示されます。ログインしているユーザーには、ウィッシュリストを選択して製品を追加するためのフォームが表示されます。

次に、このフォームを処理するコントローラを以下の内容で`app/controllers/products/wishlists_controller.rb`に作成します。

```ruby
class Products::WishlistsController < ApplicationController
  before_action :set_product
  before_action :set_wishlist

  def create
    @wishlist.wishlist_products.create(product: @product)
    redirect_to @wishlist, notice: "#{@product.name} added to wishlist."
  end

  private
    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_wishlist
      @wishlist = Current.user.wishlists.find(params[:wishlist_id])
    end
end
```

ここではネストしたリソースルーティング内にいるため、`:product_id`パラメータを指定して`Product`を検索しています。

この`create`アクションは、通常よりもシンプルです。製品がすでにウィッシュリストに存在する場合、`wishlist_product`レコードの作成は失敗しますが、このエラーをユーザーに通知する必要はないため、エラーが起きても起きなくてもウィッシュリストにリダイレクトできます。

それでは、先ほど作成したウィッシュリスト用のユーザーでログインし、製品をウィッシュリストに追加してみましょう。

### デフォルトのウィッシュリストを用意する

ここでは事前にRailsコンソールでウィッシュリストを作成してあったので、問題なく動作します。しかし、ユーザーがウィッシュリストを持っていない場合はどうなるでしょうか？

以下のコマンドを実行して、データベース内のすべてのウィッシュリストを削除してみましょう。

```bash
$ bin/rails runner "Wishlist.destroy_all"
```

次に、ブラウザで製品ページを表示して、ウィッシュリストに製品を追加してみましょう。

最初の問題は、セレクトボックスが空になってしまうことです。フォームはサーバーに`wishlist_id`パラメータを送信しないため、Active Recordでエラーが発生します。

```bash
ActiveRecord::RecordNotFound (Couldn't find Wishlist without an ID):

app/controllers/products/wishlists_controller.rb:16:in 'Products::WishlistsController#set_wishlist'
```

ここでは、ユーザーがウィッシュリストを持っていない場合は、新しいウィッシュリストを自動的に作成するようにしましょう。これにより、ユーザーがウィッシュリストを徐々に理解できるという効用も得られます。

コントローラの`set_wishlist`メソッドを更新して、ウィッシュリストを検索または作成するようにします。

```ruby
class Products::WishlistsController < ApplicationController
  before_action :set_product
  before_action :set_wishlist

  def create
    @wishlist.wishlist_products.create(product: @product)
    redirect_to @wishlist, notice: "#{@product.name} added to wishlist."
  end

  private
    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_wishlist
      if (id = params[:wishlist_id])
        @wishlist = Current.user.wishlists.find(id)
      else
        @wishlist = Current.user.wishlists.create(name: "My Wishlist")
      end
    end
end
```

このフォームを改善するために、ユーザーがウィッシュリストを持っていない場合はセレクトボックスを非表示にしましょう。`app/views/products/_wishlist.html.erb`ファイルを以下の内容で更新します。

```erb
<% if authenticated? %>
  <%= form_with url: product_wishlist_path(product) do |form| %>
    <% if Current.user.wishlists.any? %>
      <div>
        <%= form.collection_select :wishlist_id, Current.user.wishlists, :id, :name %>
      </div>
    <% end %>

    <div>
      <%= form.submit "Add to wishlist" %>
    </div>
  <% end %>
<% else %>
  <%= link_to "Add to wishlist", sign_up_path %>
<% end %>
```

## ウィッシュリストを管理する

次に、ユーザーがウィッシュリストを表示・管理する機能が必要です。

### Wishlistsコントローラ

最初に、`config/routes.rb`ファイルのトップレベルにウィッシュリスト用のルーティング（`resources :wishlists`）を追加します。

```ruby
Rails.application.routes.draw do
  # ...
  resources :products do
    resource :wishlist, only: [ :create ], module: :products
    resources :subscribers, only: [ :create ]
  end
  resource :unsubscribe, only: [ :show ]

  resources :wishlists
```

次に、`app/controllers/wishlists_controller.rb`を以下の内容で作成します。

```ruby
class WishlistsController < ApplicationController
  allow_unauthenticated_access only: %i[ show ]
  before_action :set_wishlist, only: %i[ edit update destroy ]

  def index
    @wishlists = Current.user.wishlists
  end

  def show
    @wishlist = Wishlist.find(params[:id])
  end

  def new
    @wishlist = Wishlist.new
  end

  def create
    @wishlist = Current.user.wishlists.new(wishlist_params)
    if @wishlist.save
      redirect_to @wishlist, notice: "Your wishlist was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @wishlist.update(wishlist_params)
      redirect_to @wishlist, status: :see_other, notice: "Your wishlist has been updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wishlist.destroy
    redirect_to wishlists_path, status: :see_other
  end

  private

  def set_wishlist
    @wishlist = Current.user.wishlists.find(params[:id])
  end

  def wishlist_params
    params.expect(wishlist: [ :name ])
  end
end
```

これは極めて標準的なRailsコントローラですが、いくつか重要な変更点があります。

- アクションのスコープが`Current.user.wishlists`に限定されているため、ウィッシュリストのオーナーだけが自分のウィッシュリストを作成・更新・削除できる
- `show`アクションでは`Wishlist.find`を使っているため、ウィッシュリストのオーナーでないユーザーもウィッシュリストを表示できる

### ウィッシュリストのビュー

`app/views/wishlists/index.html.erb`にindexビューを作成します。

```erb
<h1>Your Wishlists</h1>
<%= link_to "Create a wishlist", new_wishlist_path %>
<%= render @wishlists %>
```

ここでは`_wishlist`パーシャルをレンダリングしているので、パーシャルを`app/views/wishlists/_wishlist.html.erb`ファイルに作成します。

```erb
<div>
  <%= link_to wishlist.name, wishlist %>
</div>
```

次に、`app/views/wishlists/new.html.erb`に`new`ビューを作成します。

```erb
<h1>New Wishlist</h1>
<%= render "form", locals: { wishlist: @wishlist } %>
```

同様に`edit`ビューも`app/views/wishlists/edit.html.erb`に作成します。

```erb
<h1>Edit Wishlist</h1>
<%= render "form", locals: { wishlist: @wishlist } %>
```

対応する`_form`パーシャルも`app/views/wishlists/_form.html.erb`に作成します。

```erb
<%= form_with model: @wishlist do |form| %>
  <% if form.object.errors.any? %>
    <div><%= form.object.errors.full_messages.to_sentence %></div>
  <% end %>

  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div>
    <%= form.submit %>
    <%= link_to "Cancel", form.object.persisted? ? form.object : wishlists_path %>
  </div>
<% end %>
```

`show`ビューを以下の内容で`app/views/wishlists/show.html.erb`に作成します。

```erb
<h1><%= @wishlist.name %></h1>
<% if authenticated? && @wishlist.user == Current.user %>
  <%= link_to "Edit", edit_wishlist_path(@wishlist) %>
  <%= button_to "Delete", @wishlist, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>

<h3><%= pluralize @wishlist.products_count, "Product" %></h3>
<% @wishlist.wishlist_products.includes(:product).each do %>
  <div>
    <%= link_to it.product.name, it.product %>
    <small>Added <%= l it.created_at, format: :long %></small>
  </div>
<% end %>
```

最後に、`app/views/layouts/application.html.erb`レイアウトファイルのナビゲーションバーにウィッシュリストへのリンクを追加しましょう。

```erb
    <nav class="navbar">
      <%= link_to "Home", root_path %>
      <% if authenticated? %>
        <%= link_to "Wishlists", wishlists_path %>
        <%= link_to "Settings", settings_root_path %>
        <%= button_to "Log out", session_path, method: :delete %>
      <% else %>
        <%= link_to "Sign Up", sign_up_path %>
        <%= link_to "Login", new_session_path %>
      <% end %>
    </nav>
```

ページを再読み込みして、ナビゲーションバーの「Wishlists」リンクをクリックすると、ウィッシュリストの表示と管理を行えるようになります。

### クリップボードにコピーする

ウィッシュリストのURLを手軽に共有できるように、JavaScriptコードを少々使って「Copy to Clipboard」ボタンを追加してみましょう。

RailsにはデフォルトでHotwireが同梱されているので、Hotwireの[Stimulus.js](https://stimulus.hotwired.dev/)フレームワークを使って、UIに軽量なJavaScriptを追加できます。

最初に、`app/views/wishlists/show.html.erb`にボタンを追加しましょう。

```erb
<h1><%= @wishlist.name %></h1>
<% if authenticated? && @wishlist.user == Current.user %>
  <%= link_to "Edit", edit_wishlist_path(@wishlist) %>
  <%= button_to "Delete", @wishlist, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>

<%= tag.button "Copy to clipboard", data: { controller: :clipboard, action: "clipboard#copy", clipboard_text_value: wishlist_url(@wishlist) } %>
```

このボタンには、JavaScriptと連携するためのさまざまな`data-*`属性が付与されています。Railsの`tag`ヘルパーのおかげで`data-*`属性を簡潔に書けます。出力されるHTMLは以下のようになります。

```html
<button data-controller="clipboard" data-action="clipboard#copy" data-clipboard-text-value="/wishlists/1-example-wishlist">
  Copy to clipboard
</button>
```

これらの`data-*`属性は何をしているのでしょうか？個別の属性を見ていきましょう。

- `data-controller`: Stimulusの`clipboard`コントローラ（`clipboard_controller.js`ファイル）に接続するよう指示する
- `data-action`: ボタンがクリックされたときに`clipboard`コントローラの`copy()`メソッドを呼び出すよう指示する
- `data-clipboard-text-value`: `text`というデータが存在することをStimulusコントローラに伝えて、コントローラから利用可能にする

それでは、この`clipboard`コントローラを以下の内容で`app/javascript/controllers/clipboard_controller.js`に作成しましょう。

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue)
  }
}
```

このStimulusコントローラのコードは簡潔で、ここで行っているのは以下の2つだけです。

- `text`を値として登録し、コントローラでアクセス可能にします。これがクリップボードにコピーしたいURLです。
- `copy()`関数を呼び出すと、HTMLの`text`値をクリップボードに書き込みます。

JavaScriptに慣れている方なら、イベントリスナーを追加する必要も、このコントローラのセットアップやクリーンアップを手動で行う必要もないことにお気づきでしょう。StimulusはHTMLの`data-*`属性を読み取って、後は自動的に処理してくれます。

Stimulusについて詳しくは、[Stimulus](https://stimulus.hotwired.dev/)のWebサイトを参照してください。

### 製品をウィッシュリストから削除する

ユーザーが製品を購入した後や、製品に興味を失った場合、ウィッシュリストから製品を削除したくなるでしょう。それでは、製品を削除する機能を追加してみましょう。

最初に、`config/routes.rb`のルーティングを更新して、`wishlist_products`をネステッドリソースとして追加します。

```ruby
Rails.application.routes.draw do
  # ...
  resources :products do
    resource :wishlist, only: [ :create ], module: :products
    resources :subscribers, only: [ :create ]
  end
  resource :unsubscribe, only: [ :show ]

  resources :wishlists do
    resources :wishlist_products, only: [ :update, :destroy ], module: :wishlists
  end
```

次に「Remove」ボタンを追加しましょう。`app/views/wishlists/show.html.erb`ファイルを以下の内容で更新します。

```erb
<h1><%= @wishlist.name %></h1>
<% if authenticated? && @wishlist.user == Current.user %>
  <%= link_to "Edit", edit_wishlist_path(@wishlist) %>
  <%= button_to "Delete", @wishlist, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>

<h3><%= pluralize @wishlist.products_count, "Product" %></h3>
<% @wishlist.wishlist_products.includes(:product).each do %>
  <div>
    <%= link_to it.product.name, it.product %>
    <small>Added <%= l it.created_at, format: :long %></small>

    <% if authenticated? && @wishlist.user == Current.user %>
      <%= button_to "Remove", [ @wishlist, it ], method: :delete, data: { turbo_confirm: "Are you sure?" } %>
    <% end %>
  </div>
<% end %>
```

`app/controllers/wishlists/wishlist_products_controller.rb`を以下の内容で作成します。

```ruby
class Wishlists::WishlistProductsController < ApplicationController
  before_action :set_wishlist
  before_action :set_wishlist_product

  def destroy
    @wishlist_product.destroy
    redirect_to @wishlist, notice: "#{@wishlist_product.product.name} removed from wishlist."
  end

  private

  def set_wishlist
    @wishlist = Current.user.wishlists.find_by(id: params[:wishlist_id])
  end

  def set_wishlist_product
    @wishlist_product = @wishlist.wishlist_products.find(params[:id])
  end
end
```

これで、ウィッシュリストから製品を削除できるようになりました。実際に試してみましょう！

### 製品を別のウィッシュリストに移動する

ユーザーがウィッシュリストをいくつも持っていれば、製品を別のウィッシュリストに移動したくなることもあるでしょう（製品を「クリスマス」ウィッシュリストに移動するなど）。

`app/views/wishlists/show.html.erb`ファイルに以下を追加します。

```erb
<h1><%= @wishlist.name %></h1>
<% if authenticated? && @wishlist.user == Current.user %>
  <%= link_to "Edit", edit_wishlist_path(@wishlist) %>
  <%= button_to "Delete", @wishlist, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>

<h3><%= pluralize @wishlist.products_count, "Product" %></h3>
<% @wishlist.wishlist_products.includes(:product).each do %>
  <div>
    <%= link_to it.product.name, it.product %>
    <small>Added <%= l it.created_at, format: :long %></small>

    <% if authenticated? && @wishlist.user == Current.user %>
      <% if (other_wishlists = Current.user.wishlists.excluding(@wishlist)) && other_wishlists.any? %>
        <%= form_with url: [ @wishlist, it ], method: :patch do |form| %>
          <%= form.collection_select :new_wishlist_id, other_wishlists, :id, :name %>
          <%= form.submit "Move" %>
        <% end %>
      <% end %>

      <%= button_to "Remove", [ @wishlist, it ], method: :delete, data: { turbo_confirm: "Are you sure?" } %>
    <% end %>
  </div>
<% end %>
```

他のウィッシュリストのクエリが存在する場合は、製品を指定のウィッシュリストに移動するフォームをレンダリングします。他のウィッシュリストが存在しない場合は、このフォームは表示されません。

これをコントローラで処理するために、`app/controllers/wishlists/wishlist_products_controller.rb`ファイルに`update`アクションを追加します。

```ruby
class Wishlists::WishlistProductsController < ApplicationController
  before_action :set_wishlist
  before_action :set_wishlist_product

  def update
    new_wishlist = Current.user.wishlists.find(params[:new_wishlist_id])
    if @wishlist_product.update(wishlist: new_wishlist)
      redirect_to @wishlist, status: :see_other, notice: "#{@wishlist_product.product.name} has been moved to #{new_wishlist.name}"
    else
      redirect_to @wishlist, status: :see_other, alert: "#{@wishlist_product.product.name} is already on #{new_wishlist.name}."
    end
  end

  # ...
```

この`update`アクションは、まずログイン中のユーザーが持つウィッシュリストにある新規ウィッシュリストを探索します。次に、`@wishlist_product`のウィッシュリストIDの更新を試みます。製品が既に移動先のウィッシュリストに含まれている場合は、エラーを表示します。更新に成功した場合は、製品はそのまま新しいウィッシュリストに移動します。成功と失敗のどちらの場合もユーザーに表示されていたページをこの処理で変更したくないので、リダイレクトで元のウィッシュリスト表示に戻ります。

ウィッシュリストをもう1つ作成して、製品をウィッシュリスト間で移動できることを確かめてみましょう。

## 管理者用のウィッシュリスト表示を追加する

管理画面でウィッシュリストを表示できるようになれば、どの製品が人気かを知るのに有用です。

最初に、ウィッシュリストを`config/routes.rb`内の`store`名前空間ルーティングに追加します。

```ruby
  # Admins Only
  namespace :store do
    resources :products
    resources :users
    resources :wishlists

    root to: redirect("/store/products")
  end
```

`app/controllers/store/wishlists_controller.rb`ファイルを以下の内容で作成します。

```ruby
class Store::WishlistsController < Store::BaseController
  def index
    @wishlists = Wishlist.includes(:user)
  end

  def show
    @wishlist = Wishlist.find(params[:id])
  end
end
```

管理者にとって必要なのはウィッシュリストのindexページとshowページだけです（ウィッシュリストを誤って壊さないため）。

それでは、追加した2つのアクションに対応するビューを追加しましょう。
`app/views/store/wishlists/index.html.erb`ビューファイルを以下の内容で作成します。

```erb
<h1>Wishlists</h1>
<%= render @wishlists %>
```

次に、ウィッシュリストのパーシャル`app/views/store/wishlists/_wishlist.html.erb`ファイルを以下の内容で作成します。

```erb
<div>
  <%= link_to wishlist.name, store_wishlist_path(wishlist) %> by <%= link_to wishlist.user.full_name, store_user_path(wishlist.user) %>
</div>
```

次に、`app/views/store/wishlists/show.html.erb`ビューファイルを以下の内容で作成します。

```erb
<h1><%= @wishlist.name %></h1>
<p>By <%= link_to @wishlist.user.full_name, store_user_path(@wishlist.user) %></p>

<h3><%= pluralize @wishlist.products_count, "Product" %></h3>
<% @wishlist.wishlist_products.includes(:product).each do %>
  <div>
    <%= link_to it.product.name, store_product_path(it.product) %>
    <small>Added <%= l it.created_at, format: :long %></small>
  </div>
<% end %>
```

最後に、ウィッシュリストへのリンクをサイドバーのレイアウト（`app/views/layouts/settings.html.erb`）に追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Email", settings_email_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>

      <% if Current.user.admin? %>
        <h4>Store Settings</h4>
        <%= link_to "Products", store_products_path %>
        <%= link_to "Users", store_users_path %>
        <%= link_to "Wishlists", store_wishlists_path %>
      <% end %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

これで、管理画面でウィッシュリストを表示できるようになりました。

### ウィッシュリストにフィルタを追加する

管理画面でデータを見やすくするには、フィルタがあると便利です。ユーザーや製品を指定してウィッシュリストをフィルタリングできるようにしましょう。

`app/views/store/wishlists/index.html.erb`ビューに以下のフォームを追加します。

```erb
<h1><%= pluralize @wishlists.count, "Wishlist" %></h1>

<%= form_with url: store_wishlists_path, method: :get do |form| %>
  <%= form.collection_select :user_id, User.all, :id, :full_name, selected: params[:user_id], include_blank: "All Users" %>
  <%= form.collection_select :product_id, Product.all, :id, :name, selected: params[:product_id], include_blank: "All Products" %>
  <%= form.submit "Filter" %>
<% end %>

<%= render @wishlists %>
```

既にヘッダーを更新して、ウィッシュリストの総数を表示するようになっているので、フィルタを適用するときに一致した一致した件数がすぐわかります。
フォームを送信すると、Railsは選択したフィルタをクエリパラメータとしてURLに追加します。フォームはページを読み込むときにクエリパラメータの値を読み取って、ドロップダウンボックスで同じオプションを自動的に再選択するので、選択した項目はフォーム送信後も同じように表示されます。フォームは`index`アクションに送信されるので、すべてのウィッシュリストか、フィルタで絞り込まれたウィッシュリストのどちらかがページで表示されます。

この通りに動作させるには、Active Recordの機能を使ってSQLクエリにフィルタを適用する必要があります。`app/controllers/store/wishlists_controller.rb`コントローラを以下のように更新して、フィルタを追加しましょう。

```ruby
class Store::WishlistsController < Store::BaseController
  def index
    @wishlists = Wishlist.includes(:user)
    @wishlists = @wishlists.where(user_id: params[:user_id]) if params[:user_id].present?
    @wishlists = @wishlists.includes(:wishlist_products).where(wishlist_products: { product_id: params[:product_id] }) if params[:product_id].present?
  end

  def show
    @wishlist = Wishlist.find(params[:id])
  end
end
```

Active Recordのクエリは**遅延評価**されるため、SQLクエリは結果を要求するまで実行されません。これにより、コントローラでクエリをステップごとに構築し、必要に応じてそこにフィルタも含められます。

これで、システムに多数のウィッシュリストが追加されても、ユーザーや製品、またはその両方を組み合わせてウィッシュリストをフィルタリングできるようになりました。

### フィルタ機能をリファクタリングする

フィルタを導入したことでウィッシュリストコントローラがだいぶ散らかってきたので、今のうちに`app/controllers/store/wishlists_controller.rb`コントローラのロジックを`Wishlist`モデルのメソッドに切り出して整理しましょう。

```ruby
class Store::WishlistsController < Store::BaseController
  def index
    @wishlists = Wishlist.includes(:user).filter_by(params)
  end

  def show
    @wishlist = Wishlist.find(params[:id])
  end
end
```

`Wishlist`モデルで`filter_by`をクラスメソッドとして実装します。

```ruby
class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_products, dependent: :destroy
  has_many :products, through: :wishlist_products

  to_param :name

  def self.filter_by(params)
    results = all
    results = results.where(user_id: params[:user_id]) if params[:user_id].present?
    results = results.includes(:wishlist_products).where(wishlist_products: {product_id: params[:product_id]}) if params[:product_id].present?
    results
  end
end
```

`filter_by`メソッドの内容は、コントローラで行っていたこととほぼ同じですが、最初に[`all`](https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-all)を呼び出して、すでに適用されている条件を含むすべてのレコードの`ActiveRecord::Relation`を返します。次にフィルタを適用して結果を返します。

このようにリファクタリングすることで、コントローラはよりクリーンになり、フィルタリングロジックは他のデータベース関連ロジックとともにモデル内に凝縮されます。これは「**コントローラは薄くせよ、モデルは厚くせよ**（Fat Model, Skinny Controller）」原則に従ったRailsのベストプラクティスです。

TIP: 訳注: 「Fat Model を避けるための Service クラス」というアプローチの是非ついては、Kaigi on Rails の講演「[今改めてServiceクラスについて考える 〜あるRails開発者の10年〜](https://kaigionrails.org/2025/talks/joker1007/)」で過去の議論と今後の展望などがまとめられています。


## 管理画面に購読者の表示を追加する

ついでに、管理画面で製品の購読者（subscriber）を表示・フィルタリングする機能も追加しましょう。これは、製品の再入荷を待っている人が何人いるかを知るのに便利です。

### 購読者ビューを追加する

まず、`config/routes.rb`ファイルを開いて`subscribers`ルーティングを`store`名前空間に追加します。

```ruby
  # 管理者のみ
  namespace :store do
    resources :products
    resources :users
    resources :wishlists
    resources :subscribers

    root to: redirect("/store/products")
  end
```

続いて、`app/controllers/store/subscribers_controller.rb`ファイルを以下の内容で作成します。

```ruby
class Store::SubscribersController < Store::BaseController
  before_action :set_subscriber, except: [ :index ]

  def index
    @subscribers = Subscriber.includes(:product).filter_by(params)
  end

  def show
  end

  def destroy
    @subscriber.destroy
    redirect_to store_subscribers_path, notice: "Subscriber has been removed.", status: :see_other
  end

  private
    def set_subscriber
      @subscriber = Subscriber.find(params[:id])
    end
end
```

`Subscriber`コントローラには`index`、`show`、`destroy`アクションのみを実装しています。購読者はユーザーがメールアドレスを入力したときにのみ作成されます（ユーザーからサポートに購読解除を依頼されたときに、すぐ削除できるようにするため）。

この管理画面では、購読者を絞り込むためのフィルタも追加したいと思います。

`app/models/subscriber.rb`ファイルに`filter_by`クラスメソッドを追加します。

```ruby
class Subscriber < ApplicationRecord
  belongs_to :product
  generates_token_for :unsubscribe

  def self.filter_by(params)
    results = all
    results = results.where(product_id: params[:product_id]) if params[:product_id].present?
    results
  end
end
```

indexビューを`app/views/store/subscribers/index.html.erb`ファイルに以下の内容で作成します。

```erb
<h1><%= pluralize @subscribers.count, "Subscriber" %></h1>

<%= form_with url: store_subscribers_path, method: :get do |form| %>
  <%= form.collection_select :product_id, Product.all, :id, :name, selected: params[:product_id], include_blank: "All Products" %>
  <%= form.submit "Filter" %>
<% end %>

<%= render @subscribers %>
```

次に、購読者を表示する`app/views/store/subscribers/_subscriber.html.erb`パーシャルファイルを以下の内容で作成します。

```erb
<div>
  <%= link_to subscriber.email, store_subscriber_path(subscriber) %> subscribed to <%= link_to subscriber.product.name, store_product_path(subscriber.product) %> on <%= l subscriber.created_at, format: :long %>
</div>
```

次に、個別の購読者を表示するための`app/views/store/subscribers/show.html.erb`ビューファイルを以下の内容で作成します。

```erb
<h1><%= @subscriber.email %></h1>
<p>Subscribed to <%= link_to @subscriber.product.name, store_product_path(@subscriber.product) %> on <%= l @subscriber.created_at, format: :long %></p>

<%= button_to "Remove", store_subscriber_path(@subscriber), method: :delete, data: { turbo_confirm: "Are you sure?" } %>
```

最後に、サイドバーのレイアウト（`app/views/layouts/settings.html.erb`）に購読者表示用のリンクを追加します。

```erb
<%= content_for :content do %>
  <section class="settings">
    <nav>
      <h4>Account Settings</h4>
      <%= link_to "Profile", settings_profile_path %>
      <%= link_to "Email", settings_email_path %>
      <%= link_to "Password", settings_password_path %>
      <%= link_to "Account", settings_user_path %>

      <% if Current.user.admin? %>
        <h4>Store Settings</h4>
        <%= link_to "Products", store_products_path %>
        <%= link_to "Users", store_users_path %>
        <%= link_to "Subscribers", store_subscribers_path %>
        <%= link_to "Wishlists", store_wishlists_path %>
      <% end %>
    </nav>

    <div>
      <%= yield %>
    </div>
  </section>
<% end %>

<%= render template: "layouts/application" %>
```

これで、ストアの管理画面で購読者を表示・フィルタリング・削除できるようになりました。実際に試してみましょう！

## 製品表示用のリンクを追加する

フィルタの追加が終わったので、特定の製品のウィッシュリストや購読者を表示するためのリンクを追加できるようになりました。

`app/views/store/products/show.html.erb`ファイルを開き、リンクを追加します。

```erb
<p><%= link_to "Back", store_products_path %></p>

<section class="product">
  <%= image_tag @product.featured_image if @product.featured_image.attached? %>

  <section class="product-info">
    <% cache @product do %>
      <h1><%= @product.name %></h1>
      <%= @product.description %>
    <% end %>

    <%= link_to "View in Storefront", @product %>
    <%= link_to "Edit", edit_store_product_path(@product) %>
    <%= button_to "Delete", [ :store, @product ], method: :delete, data: { turbo_confirm: "Are you sure?" } %>
  </section>
</section>

<section>
  <%= link_to pluralize(@product.wishlists_count, "wishlist"), store_wishlists_path(product_id: @product) %>
  <%= link_to pluralize(@product.subscribers.count, "subscriber"), store_subscribers_path(product_id: @product) %>
</section>
```

## ウィッシュリストをテストする

それでは、ここまで構築した機能のテストを書いてみましょう。

### フィクスチャを追加する

最初に、`test/fixtures/wishlist_products.yml`のフィクスチャを更新して、以下のように定義した製品フィクスチャを参照するようにします。

```yaml
one:
  product: tshirt
  wishlist: one

two:
  product: tshirt
  wishlist: two
```

`test/fixtures/products.yml`ファイルにもテスト用の`Product`フィクスチャを追加します。

```yaml
tshirt:
  name: T-Shirt
  inventory_count: 15

shoes:
  name: shoes
  inventory_count: 0
```

### `filter_by`をテストする

`Wishlist`モデルの`filter_by`メソッドで重要なのは、レコードを正しくフィルタリングしていることを確認することです。

`test/models/wishlist_test.rb`ファイルを開き、まずは以下のテストを追加しましょう。

```ruby
require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  test "filter_by with no filters" do
    assert_equal Wishlist.all, Wishlist.filter_by({})
  end
end
```

このテストは、フィルタが適用されていない場合に`filter_by`がすべてのレコードを返すことを確認します。

次にテストを実行します。

```bash
$ bin/rails test test/models/wishlist_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 64578

# Running:

.

Finished in 0.290295s, 3.4448 runs/s, 3.4448 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

成功です！
次に、`user_id`フィルタをテストする必要があります。別のテストを追加しましょう。

```ruby
require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  test "filter_by with no filters" do
    assert_equal Wishlist.all, Wishlist.filter_by({})
  end

  test "filter_by with user_id" do
    wishlists = Wishlist.filter_by(user_id: users(:one).id)
    assert_includes wishlists, wishlists(:one)
    assert_not_includes wishlists, wishlists(:two)
  end
end
```

このテストは、クエリを実行すると、指定したユーザーのウィッシュリストが返され、他のユーザーのウィッシュリストは返されないことを確認します。

このテストファイルも実行してみましょう。

```bash
$ bin/rails test test/models/wishlist_test.rb
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 48224

# Running:

..

Finished in 0.292714s, 6.8326 runs/s, 17.0815 assertions/s.
2 runs, 5 assertions, 0 failures, 0 errors, 0 skips
```

成功です！2つのテストが両方ともパスしました。

最後に、特定の製品でウィッシュリストをテストするためのテストを追加しましょう。

このテストでは、重複のない一意の製品をウィッシュリストの1つに追加して、その製品でフィルタリングできるようにする必要があります。

`test/fixtures/wishlist_products.yml`ファイルを開き、`three:`を追加します。

```yaml
one:
  product: tshirt
  wishlist: one

two:
  product: tshirt
  wishlist: two

three:
  product: shoes
  wishlist: two
```

次に、`test/models/wishlist_test.rb`ファイルを開き、以下のテストを追加します。

```ruby
require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  test "filter_by with no filters" do
    assert_equal Wishlist.all, Wishlist.filter_by({})
  end

  test "filter_by with user_id" do
    wishlists = Wishlist.filter_by(user_id: users(:one).id)
    assert_includes wishlists, wishlists(:one)
    assert_not_includes wishlists, wishlists(:two)
  end

  test "filter_by with product_id" do
    wishlists = Wishlist.filter_by(product_id: products(:shoes).id)
    assert_includes wishlists, wishlists(:two)
    assert_not_includes wishlists, wishlists(:one)
  end
end
```

このテストでは、特定の製品でフィルタリングしたときに正しいウィッシュリストが返され、その製品を含まないウィッシュリストは返されないことを確認します。

このテストファイルも実行して、すべてパスするかどうかを確認しましょう。

```ruby
bin/rails test test/models/wishlist_test.rb
Running 3 tests in a single process (parallelization threshold is 50)
Run options: --seed 27430

# Running:

...

Finished in 0.320054s, 9.3734 runs/s, 28.1203 assertions/s.
3 runs, 9 assertions, 0 failures, 0 errors, 0 skips
```

### ウィッシュリストのCRUDをテストする

ウィッシュリストの結合テスト（integration tests）を書いてみましょう。

最初はウィッシュリストの作成に関するテストを追加しましょう。
`test/integration/wishlists_test.rb`ファイルを以下の内容で作成します。

```ruby
require "test_helper"

class WishlistsTest < ActionDispatch::IntegrationTest
  test "create a wishlist" do
    user = users(:one)
    sign_in_as user
    assert_difference "user.wishlists.count" do
      post wishlists_path, params: { wishlist: { name: "Example" } }
      assert_response :redirect
    end
  end
end
```

このテストは、ユーザーとしてログインしてから、POSTリクエストを送信してウィッシュリストを作成します。ウィッシュリストの個数が増えていることを確認し、フォームがエラーで再レンダリングされずにリダイレクトされることも確認します。

このテストファイルを実行して、すべてパスすることを確認しましょう。

```bash
$ bin/rails test test/integration/wishlists_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 40232

# Running:

.

Finished in 0.603018s, 1.6583 runs/s, 4.9750 assertions/s.
1 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

次に、ウィッシュリストの削除に関するテストを追加しましょう。

```ruby
test "delete a wishlist" do
  user = users(:one)
  sign_in_as user
  assert_difference "user.wishlists.count", -1 do
    delete wishlist_path(user.wishlists.first)
    assert_redirected_to wishlists_path
  end
end
```

このテストは、先ほどのウィッシュリスト作成テストに似ていますが、DELETEリクエストを送信した後にウィッシュリストの個数が1つ減っていることを確認しています。

次は、ウィッシュリストの表示に関するテストを追加しましょう。最初に、ユーザーが自分のウィッシュリストを表示するテストを追加します。

```ruby
test "view a wishlist" do
  user = users(:one)
  wishlist = user.wishlists.first
  sign_in_as user
  get wishlist_path(wishlist)
  assert_response :success
  assert_select "h1", text: wishlist.name
end
```

ユーザーは他のユーザーのウィッシュリストも表示できるはずなので、そのテストも追加しましょう。

```ruby
test "view a wishlist as another user" do
  wishlist = wishlists(:two)
  sign_in_as users(:one)
  get wishlist_path(wishlist)
  assert_response :success
  assert_select "h1", text: wishlist.name
end
```

ログインしていないゲストユーザーもウィッシュリストを表示できるはずなので、そのテストも追加しましょう。

```ruby
test "view a wishlist as a guest" do
  wishlist = wishlists(:one)
  get wishlist_path(wishlist)
  assert_response :success
  assert_select "h1", text: wishlist.name
end
```

テストを実行して、すべてパスすることを確認します。

```bash
$ bin/rails test test/integration/wishlists_test.rb
Running 5 tests in a single process (parallelization threshold is 50)
Run options: --seed 43675

# Running:

.....

Finished in 0.645956s, 7.7405 runs/s, 13.9328 assertions/s.
5 runs, 9 assertions, 0 failures, 0 errors, 0 skips
```

その調子！

### ウィッシュリストに表示される製品をテストする

次は、ウィッシュリスト内の製品に関するテストを書いてみましょう。最初は、ウィッシュリストに製品を追加するテストを書くのがよいでしょう。

`test/integration/wishlists_test.rb`に以下のテストを追加します。

```ruby
test "add product to a specific wishlist" do
  sign_in_as users(:one)
  wishlist = wishlists(:one)
  assert_difference "WishlistProduct.count" do
    post product_wishlist_path(products(:shoes)), params: { wishlist_id: wishlist.id }
    assert_redirected_to wishlist
  end
end
```

このテストは、ウィッシュリストに製品を追加するためのPOSTリクエストを送信すると、`WishlistProduct`の新しいレコードが作成されることを確認します。

次に、ユーザーがウィッシュリストを持っていない場合をテストしましょう。

```ruby
test "add product when no wishlists" do
  user = users(:one)
  sign_in_as user
  user.wishlists.destroy_all
  assert_difference "Wishlist.count" do
    assert_difference "WishlistProduct.count" do
      post product_wishlist_path(products(:shoes))
    end
  end
end
```

このテストでは、ユーザーのウィッシュリストをすべて削除して、フィクスチャに存在する可能性のあるウィッシュリストを取り除きます。新しい`WishlistProduct`が作成されたことの確認に加えて、今度は新しい`Wishlist`も作成されたことを確認します。

他のユーザーのウィッシュリストには製品を追加できないこともテストする必要があります。
以下のテストを追加します。

```ruby
test "cannot add product to another user's wishlist" do
  sign_in_as users(:one)
  assert_no_difference "WishlistProduct.count" do
    post product_wishlist_path(products(:shoes)), params: { wishlist_id: wishlists(:two).id }
    assert_response :not_found
  end
end
```

ここでは、あるユーザーとしてサインインしてから、別のユーザーのウィッシュリストのIDで`POST`します。期待通りに動作することを確認するために、新しい`WishlistProduct`レコードが作成されなかったというアサーションに加えて、レスポンスが"404 Not Found"であるというアサーションも行います。

次は、ウィッシュリストの製品を別のウィッシュリストに移動するテストを書きましょう。

```ruby
test "move product to another wishlist" do
  user = users(:one)
  sign_in_as user
  wishlist = user.wishlists.first
  wishlist_product = wishlist.wishlist_products.first
  second_wishlist = user.wishlists.create!(name: "Second Wishlist")
  patch wishlist_wishlist_product_path(wishlist, wishlist_product), params: { new_wishlist_id: second_wishlist.id }
  assert_equal second_wishlist, wishlist_product.reload.wishlist
end
```

このテストのセットアップは、他のテストより少し複雑です。製品を移動するための2つ目のウィッシュリストを作成します。このアクションは`WishlistProduct`レコードの`wishlist_id`カラムを更新するので、値を変数に保存して、その値がリクエスト完了後に変更されているというアサーションを行います。

このとき、`wishlist_product.reload`を呼び出す必要があります（リクエスト中に発生した変更が、メモリ上にあるレコードのコピーにまだ反映されていないため）。これにより、データベースからレコードが再読み込みされ、新しい値を確認できるようになります。

次は、製品を既に含んでいるウィッシュリストには同じ製品を移動できないことをテストしましょう。これを行うと、エラーメッセージが表示され、`WishlistProduct`は変更されないはずです。

```ruby
  test "cannot move product to a wishlist that already contains product" do
    user = users(:one)
    sign_in_as user
    wishlist = user.wishlists.first
    wishlist_product = wishlist.wishlist_products.first
    second_wishlist = user.wishlists.create!(name: "Second")
    second_wishlist.wishlist_products.create(product_id: wishlist_product.product_id)
    patch wishlist_wishlist_product_path(wishlist, wishlist_product), params: { new_wishlist_id: second_wishlist.id }
    assert_equal "T-Shirt is already on Second.", flash[:alert]
    assert_equal wishlist, wishlist_product.reload.wishlist
  end
```

このテストでは、`flash[:alert]`に対するアサーションを使ってエラーメッセージを確認しています。また、`wishlist_product`をリロードしても、ウィッシュリストが変更されていないことを確認しています。

最後に、製品を別のユーザーのウィッシュリストに移動できないことを確認するテストを追加しましょう。

```ruby
  test "cannot move product to another user's wishlist" do
    user = users(:one)
    sign_in_as user
    wishlist = user.wishlists.first
    wishlist_product = wishlist.wishlist_products.first
    patch wishlist_wishlist_product_path(wishlist, wishlist_product), params: { new_wishlist_id: wishlists(:two).id }
    assert_response :not_found
    assert_equal wishlist, wishlist_product.reload.wishlist
  end
```

この場合、レスポンスが"404 Not Found"であることを確認します。これは、`new_wishlist_id`が現在のユーザーに安全に限定されていることを示します。

直前のテストと同様に、ウィッシュリストが変更されないことも確認します。

それでは、すべてのテストを実行して、すべてパスすることを確認しましょう。

```bash
$ bin/rails test test/integration/wishlists_test.rb
Running 11 tests in a single process (parallelization threshold is 50)
Run options: --seed 65170

# Running:

...........

Finished in 1.084135s, 10.1463 runs/s, 23.0599 assertions/s.
11 runs, 25 assertions, 0 failures, 0 errors, 0 skips
```

素晴らしい！すべてのテストがパスしました。

## production環境にデプロイする

既に[Railsをはじめよう](getting_started.html)ガイドでKamalを設定してあるので、コードの変更をGitリポジトリにプッシュして、次のコマンドを実行するだけでデプロイは完了します。

```bash
$ bin/kamal deploy
```

## 今後のステップ

これで、eコマースストアにウィッシュリスト機能と、ウィッシュリストと購読者のフィルタリングが可能な管理画面が追加されました。

ここからさらに、以下のような機能を構築できます。

- 製品レビュー機能の追加
- テストを増やす
- アプリを別の言語に翻訳する（多言語化）
- 製品画像のカルーセルを追加する
- CSSでデザインを改善する
- 製品購入のための支払い機能を追加する

[全レベルユーザー向けのチュートリアル紹介ページ（英語）に戻る](https://rubyonrails.org/docs/tutorials)
