演習: 製品レビュー機能の追加
===============

本ガイドでは、[Railsをはじめよう](getting_started.html)で作成した練習用eコマースアプリ「`store`」に製品レビュー機能を追加する方法について解説します。本ガイドでは、『[演習: ウィッシュリスト機能の追加](wishlists.html)』の最終コードを出発点とします。

このガイドの内容:

* 製品レビューを集める
* 製品の評価平均を算出する
* レビューをフィルタで絞り込む機能を追加する

--------------------------------------------------------------------------------

はじめに
------------

近年のeコマースサイトにおいて、製品レビューは欠かせない要素です。本ガイドでは、製品レビューを収集して製品の評価平均を算出し、顧客や管理者がレビューを閲覧・絞り込みできる機能の実装方法を解説します。

早速作ってみましょう。

製品レビューのモデル
-------------

製品レビューは通常、1〜5つ星の評価と、ユーザーが書くテキストで構成されています。

最初に、このデータを保存するための`Review`モデルを以下のコマンドで作成しましょう。

```bash
$ bin/rails generate model Review product:belongs_to user:belongs_to rating:integer body:text images:attachments
```

この`Review`モデルには、以下の属性と関連付けがあります。

- `product:belongs_to`: `Review`を`Product`に関連付ける
- `user:belongs_to`: `Review`を、レビューを作成した`User`に関連付ける
- `rating`: 1〜5つ星の5段階評価を保存する整数型カラム
- `body`: レビュー本文を保存するテキスト型カラム
- `images`: 画像をActive Storageで保存するカラム

### キャッシュ

このマイグレーションを実行する前に、`products`テーブルに手を加えて、必要な項目をいくつか追加しましょう。

1. 製品レビューの総数をトラッキングするためのカウンタキャッシュ
2. 製品の評価平均を保存するための`rating`カラム

`db/migrate/<タイムスタンプ>_create_reviews.rb`ファイルを開いて以下の内容で更新し、これらのカラムを追加します。

```ruby
class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.belongs_to :product, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_column :products, :reviews_count, :integer, default: 0
    add_column :products, :rating, :decimal, precision: 2, scale: 1, default: 0
  end
end
```

`rating`カラムには小数を扱える`decimal`型を指定し、数値の保存方法を制御する以下のオプションも追加します。

- `precision`: 数値全体の桁数（精度）、ここでは`2`
- `scale`: 小数点以下の桁数、ここでは`1`

つまり、`rating`カラムには最大`9.9`まで保存できるようになります。数値は小数点以下も含めて2桁、そのうち小数点以下の桁数は1桁です。

終わったらターミナルでマイグレーションを実行し、データベースのスキーマを更新します。

```bash
$ bin/rails db:migrate
== 20260421200530 CreateReviews: migrating ====================================
-- create_table(:reviews)
   -> 0.0036s
-- add_column(:products, :reviews_count, :integer, {default: 0})
   -> 0.0005s
-- add_column(:products, :rating, :decimal, {precision: 2, scale: 1, default: 0})
   -> 0.0004s
== 20260421200530 CreateReviews: migrated (0.0045s) ===========================
```

次に、`app/models/review.rb`のモデルを以下のように更新します。ここでは、すべてのレビューに本文（`body`）と評価（`rating`）が存在することをチェックするバリデーションを追加しています。

```ruby
class Review < ApplicationRecord
  belongs_to :product, counter_cache: true
  belongs_to :user
  has_many_attached :images

  validates :body, presence: true
  validates :rating, presence: true, numericality: { in: 1..5, only_integer: true }
end
```

`product`への関連付けはジェネレータで作成されましたが、`reviews_count`カラムが自動的に更新されるように`counter_cache`オプションも追加しておく必要があります。

[`numericality`](https://guides.rubyonrails.org/active_record_validations.html#numericality)バリデータは、`rating`カラムの数値が1〜5の整数値であることをチェックします。

### 関連付け

次に、レビューとの関連付けを`Product`モデルと`User`モデルにも追加しておく必要があります。

`app/models/user.rb`ファイルを開いて、以下のように`has_many :reviews`関連付けを追加します。

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlists, dependent: :destroy
```

同様に、`app/models/product.rb`ファイルを開いて以下のように`has_many :reviews`関連付けを追加します。

```ruby
class Product < ApplicationRecord
  include Notifications

  has_many :reviews, dependent: :destroy
  has_many :subscribers, dependent: :destroy
```

これで、製品レビューをユーザーから集める準備が整いました。

## 製品レビューを投稿できるようにする

製品の詳細ページで、顧客にレビューの投稿を依頼したり、既存のレビューを一覧表示したりできます。
最初に、ユーザーがレビューを投稿できるようにしましょう。

### 製品レビュー用の一般公開ルーティング

手始めに、製品レビューのルーティングを作成しましょう。一般ユーザー向けの機能なので、必要なのは`new`アクションと`create`アクションだけです。

`config/routes.rb`ファイルを開いて、`resources :products`ブロックの内側に以下のように`reviews`ルーティングを追加します。

```ruby
  resources :products do
    resource :wishlist, only: [ :create ], module: :products
    resources :reviews, only: [ :new, :create ], module: :products
    resources :subscribers, only: [ :create ]
```

### 製品レビュー用のパーシャル

次に、製品詳細ページで表示するレビュー用のパーシャルを作成しましょう。

`app/views/products/_reviews.html.erb`ファイルを以下の内容で作成します。

```erb
<section class="reviews">
  <%= link_to "Write a review", new_product_review_path(product) %>
</section>
```

`app/views/products/show.html.erb`ファイルの末尾で、以下のようにパーシャルをレンダリングします。

```erb
<%= render "reviews", product: @product %>
```

ここでは、`product`をコンテキストとして渡しているので、パーシャルはどの製品のレビューをレンダリングするかを認識できます。

### `ReviewsController`を追加する

このフォームをレンダリングするには、コントローラを作成する必要があります。

`app/controllers/products/reviews_controller.rb`ファイルを以下の内容で作成します。

```ruby
class Products::ReviewsController < ApplicationController
  before_action :set_product

  def new
    @review = Review.new
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
```

このコントローラは、ネストされたルーティングを使用しており、各リクエストで`Product`モデルを検索します。

### レビュー投稿フォームを作成する

次に、レビューを投稿するためのフォームを作成しましょう。

`app/views/products/reviews/new.html.erb`ファイルを以下の内容で作成します。

```erb
<h1>Add a review</h1>

<%= form_with model: [@product, @review] do |form| %>
  <fieldset>
    <legend>Rating</legend>
    <div class="rating">
      <% 1.upto(5).each do |i| %>
        <%= form.radio_button :rating, i, required: true, class: "sr-only" %>
        <%= form.label :rating, value: i do %>
          <span aria-hidden="true">★</span>
          <span class="sr-only"><%= pluralize(i, "star") %></span>
        <% end %>
      <% end %>
    </div>
  </fieldset>

  <div>
    <%= form.label :body, style: "display: block;" %>
    <%= form.textarea :body, required: true %>
  </div>

  <div>
    <%= form.label :images, style: "display: block;" %>
    <%= form.file_field :images, multiple: true, accept: "image/*", capture: "environment" %>
  </div>

  <%= form.submit %>
<% end %>
```

ユーザーが評価を入力するためのラジオボタンは、1〜5の5つのボタンをループで作成しています。

画像のアップロード用に、以下の属性を持つファイルフィールドを使っています。

- `multiple: true`: 複数のファイルアップロードを許可するようブラウザに指示します。
- `accept: "image/*"`: ファイルセレクタを画像ファイルのみに限定するブラウザ向けのヒントです。
- `capture: "environment"`: モバイルブラウザで背面カメラでの撮影を有効にします。

### 評価入力用の星のスタイルを設定する

評価用の星は、デフォルトでは灰色で、評価を選択すると金色に変わります。これを実現するために、いくつかのCSSトリックを使います。

`app/assets/stylesheets/application.css`ファイルの末尾に以下のCSSを追加します。

```css
/* フィールドセットのデフォルトスタイルを取り消す */
fieldset {
  border: 0;
  padding: 0;
  margin: 0;
}

/* レジェンドのデフォルトスタイルを取り消す */
legend {
  padding: 0;
}

/* テキストは非表示にするが、スクリーンリーダーで読めるようにする */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.rating {
  display: flex;
}

/* デフォルトではすべての星を灰色にする */
.rating label {
  color: lightgray;
}

/* 星が選択・フォーカス・ホバーされたら、それより前の星も含めてハイライトする */
.rating input:is(:checked, :focus) + label,
.rating label:has(~ input:is(:checked, :focus)),
.rating label:hover,
.rating label:has(~ input + label:hover) {
  color: gold;
}

/* フォーカスされた入力に枠線を表示する */
.rating input:focus-visible + label {
  outline: .2em solid;
  outline-offset: 2px;
}
```

このCSSで行われていることを整理します。

1. 評価は星の個数で表示されますが、スクリーンリーダーのユーザーには`Rating, 1 star, radio button, 1 of 5`のように明確に読み上げられます。
2. ラジオボタンは非表示ですが、キーボードで操作可能です。
3. ラジオボタンが選択・フォーカス・ホバーされると、それより前の星のラベルも金色に変わります。

CSSでは、前の兄弟要素を選択するのに`:has(~ input:checked)`や`:has(~ input + label:hover)`が使えます。
このセレクタは、ユーザーが評価を選択したときに、それより前の星のラベルすべてを対象にします。
たとえば、星3を選択すると、星1、星2、星3が金色に変わります。

### レビューを作成する

次に、フォームが送信されたときにレビューをデータベースに保存する必要があります。

コントローラで以下のように`create`アクションを追加します。

```ruby
class Products::ReviewsController < ApplicationController
  before_action :set_product

  def new
    @review = Review.new
  end

  def create
    @review = @product.reviews.new(review_params)
    if @review.save
      redirect_to @product, notice: "Review was created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def review_params
    params.expect(review: [ :rating, :body, images: [] ]).with_defaults(user: Current.user)
  end
end
```

`store`アプリではRailsの認証ジェネレータで認証機能を構築してあるので、このコントローラは認証済みユーザーのみがアクセスできます。これで、ユーザー情報を`review_params`（strong parameter）にマージすることでレビューと`User`を自動的に関連付けて、関連付けが確実に設定されるようにできます。

## 製品レビューを表示する

次に、製品レビューを表示する方法が必要です。ここでは2カラムレイアウトを使って、左側に評価の概要を表示し、右側にレビューを表示することにします。

### レビューをレンダリングする

まず、`app/controllers/products_controller.rb`ファイルを開いて、表示するレビューを取得します。

```ruby
class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.with_attached_images
  end
end
```

[`with_attached_images`][]は、これらのレビューに関連付けられているすべてのActive Storage画像を事前に読み込む（プリロードする）ことで、N+1クエリ問題を回避します。

`app/views/products/show.html.erb`ファイルの末尾を以下のように更新して、`@reviews`もパーシャルに渡されるようにします。これで、どのレビューをレンダリングするかをパーシャルが認識できるようになります。

```erb
<%= render "reviews", product: @product, reviews: @reviews %>
```

[`with_attached_images`]:
  https://api.rubyonrails.org/classes/ActiveStorage/Attached/Model.html#method-i-with_attached_-2A

### 評価ごとの割合を算出する

製品レビューの評価ごとの割合を算出するメソッドを追加しましょう。
たとえば評価（`rating`）に`4`を指定すると、4つ星のレビューが全体で占める割合を返すようにします。

`app/models/product.rb`ファイルを開いて、`rating_percentage`メソッドを追加します。

```ruby
class Product < ApplicationRecord
  # ...

  def rating_percentage(rating)
    (reviews.where(rating: rating).count.to_f / reviews_count * 100).round
  end
end
```

このメソッドを使うことで、評価ごとのレビュー数とその割合を表示できます。

### 製品レビューの画面

`app/views/products/_reviews.html.erb`ファイルを以下の内容で更新し、レビューに加えて上記の情報も表示されるようにします。

```erb
<section class="reviews">
  <aside>
    <h3>Reviews</h3>

    <% if product.reviews_count > 0 %>
      <div role="img" aria-label="<%= product.rating.round %> out of 5 stars">
        <% 5.times do |i| %>
          <%= tag.span "★", class: (i < product.rating.round ? "gold" : "gray"), aria: { hidden: true } %>
        <% end %>
        <%= product.rating %> out of 5
      </div>

      <div><%= pluralize product.reviews_count, "review" %></div>

      <div>
        <% 5.downto(1).each do |i| %>
          <%= link_to product_path(product, rating: i), class: "review__summary", aria: { label: "#{pluralize(i, "star")} — #{product.rating_percentage(i)}% of reviews" } do %>
            <div aria-hidden="true">
              <div class="review__stars"><%= i %></div>
              <div class="gold">★</div>
              <div class="review__bars">
                <div class="review__bar--background"></div>
                <div class="review__bar" style="width: <%= product.rating_percentage(i) %>%;"></div>
              </div>
              <div class="review__percentage"><%= product.rating_percentage(i) %>%</div>
            </div>
          <% end %>
        <% end %>
      </div>
    <% else %>
      <p>None yet!</p>
    <% end %>

    <%= link_to "Write a review", new_product_review_path(product) %>
  </aside>

  <div>
    <%= render reviews %>
  </div>
</section>
```

レビューの評価ごとに表示される棒グラフは、`div`で灰色の背景を表示し、その上に金色の棒を重ねて、その評価のレビューの割合に応じた幅をインラインスタイルで設定しています。

このCSSを追加して、2カラムレイアウトとサイドバーの評価のスタイルを設定します。

`app/assets/stylesheets/application.css`ファイルを開いて以下のCSSを追加します。

```css
section.reviews {
  display: grid;
  grid-template-columns: 250px 1fr;
  margin-top: 2rem;
  gap: 2rem;
}

.review__summary {
  display: flex;
  align-items: center;
  margin-top: 0.25rem;
}

.review__stars {
  width: 1rem;
}

.review__bars {
  position: relative;
  flex: 1;
  display: flex;
  margin: 0px 5px;
}
.review__bar--background {
  background:#eee;
  border-radius: 15px;
  flex: 1;
  height: 12px;
}
.review__bar {
  background: gold;
  border-radius: 15px;
  position: absolute;
  inset-block: 0;
}

.review__percentage {
  text-align: right;
  width: 2.5rem;
}

.review {
  padding: 1rem;
}

.review__images {
  margin-top: 1em;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
```

### `review`パーシャル

個別のレビューを表示するために、`app/views/reviews/_review.html.erb`ファイルを以下の内容で追加します。

```erb
<%= tag.div id: dom_id(review), class: "review" do %>
  <div><%= tag.strong review.user.full_name %></div>
  <div role="img" aria-label="<%= review.rating %> out of 5 stars">
    <% 5.times do |i| %>
      <%= tag.span "★", class: (i < review.rating ? "gold" : "gray"), aria: { hidden: true } %>
    <% end %>
  </div>

  <%= review.body %>

  <% if review.images.attached? %>
    <div class="review__images">
      <% review.images.each do |image| %>
        <%= link_to image, target: :_blank, title: "View full-size image (opens in new tab)", aria: { label: "View full-size image (opens in new tab)" } do %>
          <%= image_tag image.variant(resize_to_limit: [150, 150]), alt: "" %>
        <% end %>
      <% end %>
    </div>
  <% end %>
<% end %>
```

レビュアーの名前の下で、1つ星から5つ星までのループを回して、灰色または金色の星をレビューの評価に応じた個数で表示します。

### 評価平均のキャッシュを更新する

この段階では、レビューをいくつ追加してもレビュー画面に表示されている製品評価が`0.0 out of 5`のまま変わっていないことにお気づきでしょうか。
レビューが作成されたときに評価の値は保存されますが、`Product`の評価平均は実際には更新されていないためです。

これを解決するために、`Review`モデルにコールバックを追加して、関連付けられている`Product`の評価が更新されるようにします。これはカウンタキャッシュと非常によく似ていますが、ここでは代わりに平均値を計算します。

`app/models/review.rb`ファイルを開いて、以下のように`after_commit`コールバックを追加します。

```ruby
class Review < ApplicationRecord
  belongs_to :product, counter_cache: true
  belongs_to :user
  has_many_attached :images

  validates :body, presence: true
  validates :rating, presence: true, numericality: { in: 1..5, only_integer: true }

  after_commit :update_product_rating

  def update_product_rating
    product.update_column(:rating, product.reviews.average(:rating)&.round(1))
  end
end
```

ここでは`after_commit`を用いて、レコードが作成・更新・削除された後にこの処理が実行されるようにしています。これにより、平均値が常に最新の状態に保たれます。

`update_column`メソッドを使うと、`Product`のバリデーションやコールバック、タイムスタンプの更新がスキップされるため、余分な変更をトリガーせずにレコードを高速に更新できます。

Railsコンソールを開いて、レビューに対して`update_product_rating`メソッドを呼び出してみましょう。

```irb
Loading development environment (Rails 8.2.0)
store(dev)> Review.last.update_product_rating
  Review Load (0.1ms)  SELECT "reviews".* FROM "reviews" ORDER BY "reviews"."id" DESC LIMIT 1 /*application='Store'*/
  Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 1 LIMIT 1 /*application='Store'*/
  Review Average (0.1ms)  SELECT AVG("reviews"."rating") FROM "reviews" WHERE "reviews"."product_id" = 1 /*application='Store'*/
  Product Update (0.1ms)  UPDATE "products" SET "rating" = 4.0 WHERE "products"."id" = 1 /*application='Store'*/
=> true
```

評価の平均値がSQLで計算され、製品の`rating`カラムがその値で更新されたことがログで確認できます。

## レビューをフィルタで絞り込む

レビューをフィルタで絞り込めると、製品の良し悪しを把握しやすくなります。サイドバーに表示される評価には、レビューを評価で絞り込むクエリパラメータを含んだ製品へのリンクも既に追加してあるので、コントローラでそのパラメータを利用して、評価を指定してレビューを絞り込めるようにしましょう。

`app/models/review.rb`ファイルを開いて、以下のスコープを追加します。

```ruby
class Review < ApplicationRecord
  belongs_to :product, counter_cache: true
  belongs_to :user
  has_many_attached :images

  scope :rated, ->(rating) { rating.present? ? where(rating: rating.to_i) : all }

  validates :body, presence: true
  validates :rating, presence: true, numericality: { in: 1..5, only_integer: true }

  after_commit :update_product_rating

  def update_product_rating
    product.update_column(:rating, product.reviews.average(:rating)&.round(1))
  end
end
```

このスコープが受け取った`rating`引数に一致するレビューをフィルタリングします。`nil`または空文字列`""`が渡された場合は、すべてのレビューを返します。

このスコープは無効な評価値も安全に処理します。
たとえば、`rated("foo")`と呼び出すと、`"foo".to_i`が`0`を返すため、評価が`0`のレビューを返します。`0`は有効な評価ではないため、結果としてレビューは返されません。

`app/controllers/products_controller.rb`ファイルを開いて、この新しいスコープを使うように`show`アクションを更新します。

```ruby
class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.with_attached_images.rated(params[:rating])
  end
end
```

`params[:rating]`を渡すことで、ユーザーはクエリパラメータでレビューを絞り込めるようになります。このとき以下のように振る舞います。

- URLに`?rating=3`が含まれている場合: 評価が3のレビューのみが返されます。
- この`rating`パラメータが空または存在しない場合: すべてのレビューが返されます。
- `?rating=foo`のように無効な値が渡された場合: レビューは返されません。

次に、`app/views/products/_reviews.html.erb`ファイルを以下の内容で更新して、フィルタの状態と「Clear filter」リンクを表示するようにします。

```erb
<section class="reviews">
  <aside>
    <%# ... %>
  </aside>

  <div>
    <% if params[:rating] %>
      <div>
        Filtered by <%= pluralize params[:rating].to_i, "star" %>.
        <%= link_to "Clear filter", product %>
      </div>
    <% end %>

    <%= render reviews %>
  </div>
</section>
```

評価をクリックするとレビューが絞り込まれ、「Clear filter」リンクをクリックするとすべてのレビューが表示されることを確かめましょう。

## レビューを管理する

管理者は、スパムレビューの削除や誤字の修正、その他の間違いを訂正する必要があります。次はこの機能を構築しましょう。

最初に、`config/routes.rb`ファイルを開いて、`store`名前空間にレビュー用の`resources`ルーティングを追加します。

```ruby
# 管理者専用の名前空間
namespace :store do
  resources :products
  resources :reviews
  resources :users
  resources :wishlists
  resources :subscribers
end
```

これで、`app/controllers/store/reviews_controller.rb`ファイルを以下の内容で作成して管理機能を実装できます。

```ruby
class Store::ReviewsController < Store::BaseController
  before_action :set_review, except: [ :index ]

  def index
    @reviews = Review.includes(:product, :user).with_attached_images.filter_by(params)
  end

  def show
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to store_review_path(@review)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @review.destroy
    redirect_to store_reviews_path
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.expect(review: [ :rating, :body, images: [] ])
  end
end
```

`index`アクションで評価・製品・ユーザーごとにレビューを絞り込めるように、`Wishlist`モデルで行ったのと同様に`filter_by`メソッドを追加します。

`app/models/review.rb`ファイルを開いて、以下の内容で更新します。

```ruby
class Review < ApplicationRecord
  belongs_to :product, counter_cache: true
  belongs_to :user
  has_many_attached :images

  scope :rated, ->(rating) { rating.present? ? where(rating: rating.to_i) : all }

  validates :body, presence: true
  validates :rating, presence: true, numericality: { in: 1..5, only_integer: true }

  after_commit :update_product_rating

  def self.filter_by(params)
    results = rated(params[:rating])
    results = results.where(product_id: params[:product_id]) if params[:product_id].present?
    results = results.where(user_id: params[:user_id]) if params[:user_id].present?
    results
  end

  def update_product_rating
    product.update_column(:rating, product.reviews.average(:rating)&.round(1))
  end
end
```

### サイドバーにリンクを追加する

ナビゲーションからレビューにアクセスできるように、レイアウトのサイドバーにリンクを追加しましょう。

`app/views/layouts/settings.html.erb`ファイルで以下のように「Reviews」リンクを追加します。

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
        <%= link_to "Reviews", store_reviews_path %>
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

製品の詳細ページにも、レビュー一覧ページへのリンクを追加します。
`app/views/store/products/show.html.erb`ファイルで末尾の`<section>`を以下の内容で更新します。

```erb
<%# ... %>

<section>
  <%= link_to pluralize(@product.reviews_count, "review"), store_reviews_path(product_id: @product.id) %>
  <%= link_to pluralize(@product.wishlists_count, "wishlist"), store_wishlists_path(product_id: @product.id) %>
  <%= link_to pluralize(@product.subscribers_count, "subscriber"), store_subscribers_path(product_id: @product.id) %>
</section>
```

これで、管理画面から製品のレビューに簡単にアクセスできるようになります。

### レビュー管理画面の`index`ビューとパーシャルを作成する

次に、`app/views/store/reviews/index.html.erb`ファイルで`index`ビューを作成します。

```erb
<h1>Reviews</h1>

<%= form_with url: store_reviews_path, method: :get do |form| %>
  <%= form.collection_select :product_id, Product.all, :id, :name, selected: params[:product_id], include_blank: "All Products" %>
  <%= form.select :rating, 5.downto(1).map{ pluralize it, "star" }, selected: params[:rating], include_blank: "All Ratings" %>
  <%= form.collection_select :user_id, User.all, :id, :full_name, selected: params[:user_id], include_blank: "All Users" %>
  <%= form.submit "Filter" %>
<% end %>

<%= render @reviews %>
```

次に、`store`名前空間のレビュー用パーシャルを作成します。
これは一般公開用のパーシャルと非常によく似ていますが、任意の製品レビューを表示するため、いくつか追加のコンテキストがあります。

`app/views/store/reviews/_review.html.erb`ファイルを以下の内容で作成します。

```erb
<%= tag.div id: dom_id(review), class: "review" do %>
  <div><%= link_to review.user.full_name, store_user_path(review.user) %> reviewed <%= link_to review.product.name, store_product_path(review.product) %></div>
  <div role="img" aria-label="<%= review.rating %> out of 5 stars">
    <% 5.times do |i| %>
      <%= tag.span "★", class: (i < review.rating ? "gold" : "gray"), aria: { hidden: true } %>
    <% end %>
  </div>

  <%= review.body %>

  <% if review.images.attached? %>
    <div class="review__images">
      <% review.images.each do |image| %>
        <%= link_to image, target: :_blank, title: "View full-size image (opens in new tab)", aria: { label: "View full-size image (opens in new tab)" } do %>
          <%= image_tag image.variant(resize_to_limit: [150, 150]), alt: "" %>
        <% end %>
      <% end %>
    </div>
  <% end %>

  <div>
    <%= link_to "View review", store_review_path(review) %>
  </div>
<% end %>
```

### レビュー管理画面の`show`ビューを作成する

次に、`app/views/store/reviews/show.html.erb`ファイルを以下の内容で作成します。

```erb
<%= link_to "Back to all reviews", store_reviews_path %>

<h1>Review</h1>

<%= tag.div id: dom_id(@review), class: "review" do %>
  <div><%= link_to @review.user.full_name, store_user_path(@review.user) %> reviewed <%= link_to @review.product.name, store_product_path(@review.product) %></div>
  <div>
    <% 5.times do |i| %>
      <%= tag.span "★", class: (i < @review.rating.round ? "gold" : "gray") %>
    <% end %>
  </div>

  <%= @review.body %>

  <% if @review.images.attached? %>
    <div class="review__images">
      <% @review.images.each do |image| %>
        <%= link_to image_tag(image.variant(resize_to_limit: [150, 150])), image, target: :_blank %>
      <% end %>
    </div>
  <% end %>
<% end %>

<div>
  <%= link_to "Edit", edit_store_review_path(@review) %>
  <%= button_to "Delete", store_review_path(@review), method: :delete, data: {turbo_confirm: "Are you sure?"} %>
</div>
```

### レビュー管理画面の`edit`ビューを作成する

最後に、`app/views/store/reviews/edit.html.erb`ファイルを以下の内容で作成します。

```erb
<h1>Edit Review</h1>

<%= form_with model: [:store, @review] do |form| %>
  <fieldset>
    <legend>Rating</legend>
    <div class="rating">
      <% 1.upto(5).each do |i| %>
        <%= form.radio_button :rating, i, required: true, class: "sr-only" %>
        <%= form.label :rating, value: i do %>
          <span aria-hidden="true">★</span>
          <span class="sr-only"><%= pluralize(i, "star") %></span>
        <% end %>
      <% end %>
    </div>
  </fieldset>

  <div>
    <%= form.label :body, style: "display: block;" %>
    <%= form.textarea :body, required: true %>
  </div>

  <div>
    <%= form.label :images, style: "display: block;" %>
    <%= form.file_field :images, multiple: true, accept: "image/*", capture: "environment" %>

    <% form.object.images.each do |image| %>
      <div>
        <%= image_tag image.variant(resize_to_limit: [150, 150]) %>
        <%= form.hidden_field :images, value: image.signed_id, multiple: true, id: nil %>
        <button onclick="this.parentElement.remove()">Remove</button>
      </div>
    <% end %>
  </div>

  <%= form.submit %>
<% end %>
```

デフォルトでは、新しい値が割り当てられると、既存の画像がすべて置き換えられてしまいます。
レビュー編集時に既存の画像が変わらないようにするには、すでにアップロードされている各画像に対応する隠しフィールドを`form.hidden_field`で作成する必要があります。
これらの隠しフィールドでは、画像の`signed_id`を指定して既存のActive Recordオブジェクトを参照すると同時に、改ざんが行われていないことを保証します。

`multiple: true`を指定することで、Railsは`images`パラメータを配列として送信するのに適した名前を生成します。また、これらのフィールドに対して生成される`id`は重複の原因となり、かつ不要なので、無効化しておきます。

以上の追加によって、管理者は必要に応じてレビューを表示・編集・削除できるようになりました。

## レビュー機能のテストを書く

作業を終える前に、ここまで実装した機能が正しく動作することを確認するためのテストをいくつか書いておきましょう。

### レビュー用フィクスチャを更新する

`test/fixtures/reviews.yml`ファイルに`Review`テスト用のフィクスチャが2つ生成されていますが、これらを以下のように更新して`Product`の`tshirt`フィクスチャに関連付ける必要があります。

```yaml
five_star:
  product: tshirt
  user: one
  rating: 5
  body: I love this.

four_star:
  product: tshirt
  user: two
  rating: 4
  body: Great quality.
```

`Product`用フィクスチャの`rating`も、実際のレビュー評価と一致するように設定しましょう。

`test/fixtures/products.yml`を以下のように更新します。

```yaml
tshirt:
  name: T-Shirt
  inventory_count: 15
  rating: 4.5
  reviews_count: 2

shoes:
  name: Shoes
  inventory_count: 0
  rating: 0
  reviews_count: 0
```

### レビュー機能のテストを作成する

まずは、`test/models/review_test.rb`ファイルにレビューを作成するテストを書きましょう。

```ruby
require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "create review" do
    assert_nothing_raised do
      products(:tshirt).reviews.create!(
        user: users(:one),
        rating: 5,
        body: "I love this product."
      )
    end
  end
end
```

テストを実行して、正しく動作することを確認します。

```bash
$ bin/rails test test/models/review_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 42591

# Running:

.

Finished in 0.317256s, 3.1520 runs/s, 3.1520 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

### 無効な評価値のテスト

評価は1〜5の間である必要があります。このテストを`test/models/review_test.rb`ファイルに追加しましょう。

```ruby
test "invalid rating" do
  review = products(:tshirt).reviews.create(
    rating: 0,
    user: users(:one),
    body: "Example"
  )

  refute review.valid?
  assert review.errors.has_key?(:rating)
end
```

このテストでは、評価が`0`の場合にレビューが無効であること、また`rating`がエラーのある属性の1つであることを確認します。

テストを実行して確認します。

```bash
$ bin/rails test test/models/review_test.rb
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 19665

# Running:

..

Finished in 0.323206s, 6.1880 runs/s, 9.2820 assertions/s.
2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

### 製品の評価平均をテストする

レビューによって、関連する製品の評価も更新されるため、そのテストも書く必要があります。

`test/models/review_test.rb`ファイルに以下のテストを追加します。

```ruby
test "updates product rating" do
  product = products(:tshirt)
  assert_equal 4.5, product.rating

  product.reviews.create!(
    rating: 3,
    user: users(:one),
    body: "Love it"
  )

  assert_equal 4, product.rating
end
```

`Product`フィクスチャにある`rating`は`4.5`なので、3つ星レビューを新規作成すると製品の新しい平均値は`4`になるはずです。

テストを実行して確認します。

```bash
$ bin/rails test test/models/review_test.rb
Running 3 tests in a single process (parallelization threshold is 50)
Run options: --seed 28957

# Running:

...

Finished in 0.347102s, 8.6430 runs/s, 14.4050 assertions/s.
3 runs, 5 assertions, 0 failures, 0 errors, 0 skips
```

### `rated`スコープのテスト

次に、`rated`スコープのテストを追加します。

```ruby
test "rated scope" do
  assert_equal Review.where(rating: 5), Review.rated(5)
  assert_equal Review.all, Review.rated(nil)
  assert_empty Review.rated("invalid")
end
```

このテストでは、先ほど扱った以下のケースの結果が正しいことを確認します。

- 評価が1〜5の場合
- 評価が無効な場合
- 評価がnilまたは空の場合

テストを実行して確認します。

```bash
$ bin/rails test test/models/review_test.rb
Running 4 tests in a single process (parallelization threshold is 50)
Run options: --seed 38054

# Running:

....

Finished in 0.351257s, 11.3877 runs/s, 25.6223 assertions/s.
4 runs, 9 assertions, 0 failures, 0 errors, 0 skips
```

### レビュー作成の統合テスト

次に、顧客がレビューを作成する機能の統合テストを追加しましょう。
最初に、以下のコマンドを実行して統合テスト用のファイルを生成します。

```bash
$ bin/rails generate integration_test reviews

      invoke  test_unit
      create    test/integration/reviews_test.rb
```

`test/integration/reviews_test.rb`ファイルを開いて、ログイン済みユーザーとしてレビューを送信するテストを追加します。

```ruby
require "test_helper"

class ReviewsTest < ActionDispatch::IntegrationTest
  test "review a product" do
    product = products(:tshirt)
    sign_in_as users(:one)
    assert_difference "Review.count" do
      post product_reviews_path(product), params: { review: { rating: 3, body: "Example" } }
      assert_redirected_to product
    end
  end
end
```

このテストでは、ユーザーがブラウザで送信するのと同じように、ログインして製品レビューを送信します。

以下のコマンドでこのテストを実行します。

```bash
$ bin/rails test test/integration/reviews_test.rb
Running 1 tests in a single process (parallelization threshold is 50)
Run options: --seed 18242

# Running:

.

Finished in 0.642394s, 1.5567 runs/s, 6.2267 assertions/s.
1 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

無事にパスしました！

### レビューのフィルタリング機能のテスト

レビューのフィルタ機能もフロントエンドでテストしたいので、同じ統合テストファイルに以下の新しいテストを追加しましょう。

```ruby
require "test_helper"

class ReviewsTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "review a product" do
    product = products(:tshirt)
    sign_in_as users(:one)
    assert_difference "Review.count" do
      post product_reviews_path(product), params: { review: { rating: 3, body: "Example" } }
      assert_redirected_to product
    end
  end

  test "filter product reviews" do
    get product_path(products(:tshirt), rating: 5)
    assert_response :success
    assert_dom "div", text: "Filtered by 5 stars. Clear filter"
    assert_dom "#" + dom_id(reviews(:five_star))
    assert_not_dom "#" + dom_id(reviews(:four_star))
  end
end
```

このテストでは、5つ星の評価に絞り込まれた状態で製品を読み込みます。正しく動作したことを確認するため、以下のアサーションを行います。

- ページが正常に読み込まれたこと
- フィルタのテキストとフィルタをクリアするリンクがページに含まれていること
- 5つ星のレビューがページに含まれていること
- 4つ星のレビューがページに含まれて**いない**こと

これらのアサーションにより、レビューのフィルタが正しく適用されたことを確認できます。

```bash
$ bin/rails test test/integration/reviews_test.rb
Running 2 tests in a single process (parallelization threshold is 50)
Run options: --seed 9516

# Running:

..

Finished in 0.720307s, 2.7766 runs/s, 11.1064 assertions/s.
2 runs, 8 assertions, 0 failures, 0 errors, 0 skips
```

### レビュー管理機能のテスト

最後に、管理者のみが管理画面のレビュー管理セクションにアクセスできることを確認するためのテストを追加しましょう。

レビュー管理の統合テストファイルが既にあるので、以下のテストを`test/integration/settings_test.rb`に追加します。

```ruby
test "regular user cannot access /store/reviews" do
  sign_in_as users(:one)
  get store_reviews_path
  assert_response :redirect
  assert_equal "You aren't allowed to do that.", flash[:alert]
end

test "admin can access /store/reviews" do
  sign_in_as users(:admin)
  get store_reviews_path
  assert_response :success
end
```

これらの新しいテストを実行して確認します。

```bash
$ bin/rails test test/integration/settings_test.rb
Running 8 tests in a single process (parallelization threshold is 50)
Run options: --seed 41516

# Running:

........

Finished in 0.689592s, 11.6011 runs/s, 18.8517 assertions/s.
8 runs, 13 assertions, 0 failures, 0 errors, 0 skips
```

完璧です！

すべてのテストが通ることを確認するため、テストスイート全体も実行します。

```bash
$ bin/rails test
Running 40 tests in a single process (parallelization threshold is 50)
Run options: --seed 27614

# Running:

........................................

Finished in 1.865963s, 21.4367 runs/s, 55.7353 assertions/s.
40 runs, 104 assertions, 0 failures, 0 errors, 0 skips
```

## production環境へのデプロイ

製品レビュー機能の追加が完了したので、production環境にデプロイしましょう。
変更をGitリポジトリにコミットしてプッシュしてから、以下のコマンドを実行します。

```bash
$ bin/kamal deploy
```

## 今後のステップ

これで、eコマースストアに製品レビュー機能が追加され、顧客がより詳しい製品情報に基づいて購入を決定できるようになりました。

ここからさらに、以下のような機能を構築したり改善を加えたりできます。

- テストを増やす
- アプリを別の言語に翻訳し終える（多言語化）
- 製品画像のカルーセルを追加する
- CSSでデザインを改善する
- 製品購入のための支払い機能を追加する
- 製品ページに表示するレビュー件数に上限を設定する

Happy building!

[Return to all tutorials](https://rubyonrails.org/docs/tutorials)