
Rails のルーティング
=================================

このガイドでは、開発者に向けてRailsのルーティング機能を解説します (訳注: routeとrootを区別するため、訳文ではrouteを基本的に「ルーティング」と訳します)。

このガイドの内容:

* `routes.rb`のコードの読み方
* 独自のルーティング作成法 (リソースベースのルーティングが推奨されますが、`match`メソッドによるルーティングも可能です)
* ルーティングのパラメータの宣言方法（コントローラのアクションに渡される）
* ルーティングヘルパーを使用してパスやURLを自動生成する方法
* 制限の作成やRackエンドポイントのマウントなどの高度な手法

--------------------------------------------------------------------------------

Railsルーターの目的
-------------------------------

Railsのルーターは受け取ったURLを認識し、適切なコントローラ内アクションやRackアプリに割り当てます。ルーターは、ビューでこれらのパスやURLを直接ハードコードすることを避けるためにパスやURLを生成することもできます。

### URLを実際のコードに割り振る

Railsアプリケーションが以下のHTTPリクエストを受け取ったとします。

```
GET /patients/17
```

このリクエストは、特定のコントローラ内アクションにマッチさせるようルーターに要求しています。最初にマッチしたのが以下のルーティングだとします。

```ruby
get '/patients/:id', to: 'patients#show'
```

このリクエストは`patients`コントローラの`show`アクションに割り当てられ、`params`には`{ id: '17' }`ハッシュが含まれています。

### コードからパスやURLを生成する

パスやURLを生成することもできます。たとえば、上のルーティングが以下のように変更されたとします。

```ruby
get '/patients/:id', to: 'patients#show', as: 'patient'
```

そして、アプリケーションのコントローラに以下のコードがあるとします。

```ruby
@patient = Patient.find(params[:id])
```

上記に対応するビューは以下です。

```erb
<%= link_to 'Patient Record', patient_path(@patient) %>
```

これで、ルーターによって`/patients/17`というパスが生成されます。これを利用することでビューが改修しやすくなり、コードも読みやすくなります。このルーティングヘルパーではidを指定する必要がない点にご注目ください。

リソースベースのルーティング: Railsのデフォルト
-----------------------------------

リソースベースのルーティング (以下リソースルーティング) を使用することで、リソースベースで構成されたコントローラに対応する共通のルーティングを手軽に宣言できます。リソースフルなルーティングを宣言することで、コントローラの`index`、`show`、`new`、`edit`、`create`、`update`、`destroy`アクションを個別に宣言しなくても1行で宣言が完了します。

### Web上のリソース

ブラウザはRailsに対してリクエストを送信する際に、特定のHTTPメソッド (`GET`、`POST`、`PATCH`、`PUT`、`DELETE`など) を使用して、URLに対するリクエストを作成します。上に述べたHTTPメソッドは、いずれもリソースに対して特定の操作の実行を指示するリクエストです。リソースルーティングでは、関連するさまざまなリクエストを1つのコントローラ内のアクションに割り当てます。

Railsアプリケーションが以下のHTTPリクエストを受け取ったとします。

```
DELETE /photos/17
```

このリクエストは、特定のコントローラ内アクションにマッピングさせるようルーターに要求しています。最初にマッチしたのが以下のルーティングだとします。

```ruby
resources :photos
```

Railsはこのリクエストを`photos`コントローラ内の`destroy`アクションに割り当て、`params`ハッシュに`{ id: '17' }`を含めます。

### CRUD、動詞、アクション

Railsのリソースフルルーティングでは、(GET、PUTなどの) 各種HTTP動詞 (verb) と、コントローラ内アクションを指すURLが対応付けられます。1つのアクションは、データベース上での特定のCRUD (Create/Read/Update/Delete) 操作に対応付けられるルールになっています。たとえば、以下のようなルーティングが1つあるとします。

```ruby
resources :photos
```

上の記述により、アプリケーション内に以下の7つのルーティングが作成され、いずれも`Photos`コントローラに対応付けられます。

| HTTP動詞 | パス             | コントローラ#アクション | 目的                                     |
| --------- | ---------------- | ----------------- | -------------------------------------------- |
| GET       | /photos          | photos#index      | すべての写真の一覧を表示                 |
| GET       | /photos/new      | photos#new        | 写真を1つ作成するためのHTMLフォームを返す |
| POST      | /photos          | photos#create     | 写真を1つ作成する                           |
| GET       | /photos/:id      | photos#show       | 特定の写真を表示する                     |
| GET       | /photos/:id/edit | photos#edit       | 写真編集用のHTMLフォームを1つ返す      |
| PATCH/PUT | /photos/:id      | photos#update     | 特定の写真を更新する                      |
| DELETE    | /photos/:id      | photos#destroy    | 特定の写真を削除する                      |

NOTE: Railsのルーターでは、サーバーへのリクエストをマッチさせる際にHTTP動詞とURLを使用しているため、4種類のURL (GET/POST/PATCH/DELETE) が7種類の異なるアクション (index/new/create/show/edit/update/destroy) に割り当てられています。

NOTE: Railsのルーティングは、ルーティングファイルの「上からの記載順に」マッチします。このため、たとえば`resources :photos`というルーティングが`get 'photos/poll'`よりも前の行にあれば、`resources`行の`show`アクションが`get`行の記述よりも優先されますので、`get`行のルーティングは有効になりません。これを修正するには、`get`行を`resources`行 **よりも上** の行に移動してください。これにより、`get`行がマッチするようになります。

### パスとURL用ヘルパー

リソースフルなルーティングを作成すると、アプリケーションのコントローラで多くのヘルパーが利用できるようになります。`resources :photos`というルーティングを例に取ってみましょう。

* `photos_path`は`/photos`を返します
* `new_photo_path`は`/photos/new`を返します
* `edit_photo_path(:id)`は`/photos/:id/edit`を返します (`edit_photo_path(10)`であれば`/photos/10/edit`が返されます)
* `photo_path(:id)`は`/photos/:id`を返します。 (`photo_path(10)`であれば`/photos/10`が返されます)

これらの_pathヘルパーには、それぞれに対応する`_url`ヘルパー (`photos_url`など) があります。_urlヘルパーは、_pathの前に現在のホスト名、ポート番号、パスのプレフィックスが追加されている点が異なります。

### 複数のリソースを同時に定義する

リソースをいくつも定義しなければならない場合は、以下のような略記法で一度に定義することでタイプ量を節約できます。

```ruby
resources :photos, :books, :videos
```

上の記法は以下と完全に同一です。

```ruby
resources :photos
resources :books
resources :videos
```

### 単数形リソース

場合によっては、ユーザーがページを表示する時にidを参照することのないリソースが使用されることがあります。たとえば、`/profile`では常に「現在ログインしているユーザー自身」のプロファイルを表示し、他のユーザーidを参照する必要がないとします。このような場合には、単数形リソース (singular resource) を使用して`show`アクションに (`/profile/:id`ではなく) `/profile`を割り当てることができます。

```ruby
get 'profile', to: 'users#show'
```

`to:`の引数に`文字列`を渡す場合は`コントローラ#アクション`形式であることが前提ですが、`シンボル`を使う場合は、`to:`オプションを`action:`に置き換えるべきです。`#`なしの`文字列`を使う場合は、`to:`オプションを`controller:`に置き換えるべきです。

```ruby
get 'profile', to: :show, controller: 'users'
```

以下に記述するリソースフルなルーティングは

```ruby
resource :geocoder
resolve('Geocoder') { [:geocoder] }
```

`Geocoders`コントローラに割り当てられた以下の6つのルーティングを作成します。

| HTTP動詞 | パス             | コントローラ#アクション | 目的                                     |
| --------- | -------------- | ----------------- | --------------------------------------------- |
| GET       | /geocoder/new  | geocoders#new     | geocoder作成用のHTMLフォームを返す |
| POST      | /geocoder      | geocoders#create  | geocoderを作成する                       |
| GET       | /geocoder      | geocoders#show    | 1つしかないgeocoderリソースを表示する    |
| GET       | /geocoder/edit | geocoders#edit    | geocoder編集用のHTMLフォームを返す  |
| PATCH/PUT | /geocoder      | geocoders#update  | 1つしかないgeocoderリソースを更新する     |
| DELETE    | /geocoder      | geocoders#destroy | geocoderリソースを削除する                  |

NOTE: 単数形リソースは複数形のコントローラに割り当てられます。これは、同じコントローラで単数形のルーティング (`/account`) と複数形のルーティング (`/accounts/45`) を両方使いたい場合を想定しているためです。従って、`resource :photo`と`resources :photos`のどちらも、単数形ルーティングと複数形ルーティングを両方作成し、同一のコントローラ (`PhotosController`) に割り当てられます。

単数形のリソースフルなルーティングを使用すると、以下のヘルパーメソッドが生成されます。

* `new_geocoder_path`は`/geocoder/new`を返します
* `edit_geocoder_path`は`/geocoder/edit`を返します
* `geocoder_path`は`/geocoder`を返します。

複数形リソースの場合と同様に、単数形リソースでも_pathヘルパーに対応する`_url`ヘルパーが使用できます。_urlヘルパーは、_pathの前に現在のホスト名、ポート番号、パスのプレフィックスが追加されている点が異なります。

### コントローラの名前空間とルーティング

コントローラを名前空間によってグループ化することもできます。最もよく使用される名前空間といえば、多数の管理用コントローラ群をまとめる`Admin::`名前空間でしょう。これらのコントローラを`app/controllers/admin`ディレクトリに配置し、ルーティングでこれらをグループ化できます。

```ruby
namespace :admin do
  resources :articles, :comments
end
```

上のルーティングにより、`articles`コントローラや`comments`コントローラへのルーティングが多数生成されます。たとえば、`Admin::ArticlesController`向けに作成されるルーティングは以下のとおりです。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | --------------------- | ------------------- | ------------------------- |
| GET       | /admin/articles          | admin/articles#index   | admin_articles_path          |
| GET       | /admin/articles/new      | admin/articles#new     | new_admin_article_path       |
| POST      | /admin/articles          | admin/articles#create  | admin_articles_path          |
| GET       | /admin/articles/:id      | admin/articles#show    | admin_article_path(:id)      |
| GET       | /admin/articles/:id/edit | admin/articles#edit    | edit_admin_post_path(:id)    |
| PATCH/PUT | /admin/articles/:id      | admin/articles#update  | edit_admin_article_path(:id) |
| DELETE    | /admin/articles/:id      | admin/articles#destroy | admin_article_path(:id)      |

例外的に、(`/admin`が前についていない) `/articles`を`Admin::ArticlesController`にルーティングしたい場合は、以下のようにすることもできます。

```ruby
scope module: 'admin' do
  resources :articles, :comments
end
```

以下のようにブロックを使用しない記述も可能です。

```ruby
resources :articles, module: 'admin'
```

逆に、`/admin/articles`を (`Admin::`なしの) `ArticlesController`にルーティングしたい場合は、以下のようにします。

```ruby
scope '/admin' do
  resources :articles, :comments
end
```

以下のようにブロックを使用しない記述も可能です。

```ruby
resources :articles, path: '/admin/articles'
```

いずれの場合も、名前付きルート (named route)は、`scope`を使用しなかった場合と同じであることにご注目ください。最後の例の場合は、以下のパスが`ArticlesController`に割り当てられます。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | --------------------- | ----------------- | ------------------- |
| GET       | /admin/articles          | articles#index       | articles_path          |
| GET       | /admin/articles/new      | articles#new         | new_article_path       |
| POST      | /admin/articles          | articles#create      | new_article_path          |
| GET       | /admin/articles/:id      | articles#show        | article_path(:id)      |
| GET       | /admin/articles/:id/edit | articles#edit        | edit_article_path(:id) |
| PATCH/PUT | /admin/articles/:id      | articles#update      | article_path(:id)      |
| DELETE    | /admin/articles/:id      | articles#destroy     | article_path(:id)      |

TIP: _`namespace`ブロックの内部で異なるコントローラ名前空間を使用したいのであれば、「`get '/foo' => '/foo#index'`」のような絶対コントローラパスを指定することもできます。_

### ネストしたリソース

論理上、他のリソースの配下に子リソースを配置することはよくあります。たとえば、Railsアプリケーションに以下のモデルがあるとします。

```ruby
class Magazine < ApplicationRecord
  has_many :ads
end

class Ad < ApplicationRecord
  belongs_to :magazine
end
```

ルーティングをネストする (入れ子にする) ことで、この親子関係をルーティングで表すことができるようになります。上の例の場合、以下のようにルーティングを宣言することができます。

```ruby
resources :magazines do
  resources :ads
end
```

上のルーティングによって、雑誌 (magazine) へのルーティングに加えて、広告 (ad) を`AdsController`にルーティングすることもできるようになりました。adへのURLにはmagazineもなければなりません。

| HTTP動詞 | パス             | コントローラ#アクション | 目的                                     |
| --------- | ------------------------------------ | ----------------- | -------------------------------------------------------------------------- |
| GET       | /magazines/:magazine_id/ads          | ads#index         | ある雑誌1冊に含まれる広告をすべて表示する                          |
| GET       | /magazines/:magazine_id/ads/new      | ads#new           | ある1冊の雑誌用の広告を1つ作成するHTMLフォームを返す |
| POST      | /magazines/:magazine_id/ads          | ads#create        | ある1冊の雑誌用の広告を1つ作成する                           |
| GET       | /magazines/:magazine_id/ads/:id      | ads#show          | ある雑誌1冊に含まれる広告を1つ表示する                    |
| GET       | /magazines/:magazine_id/ads/:id/edit | ads#edit          | ある雑誌1冊に含まれる広告1つを編集するHTMLフォームを返す     |
| PATCH/PUT | /magazines/:magazine_id/ads/:id      | ads#update        | ある雑誌1冊に含まれる広告を1つ更新する                      |
| DELETE    | /magazines/:magazine_id/ads/:id      | ads#destroy       | ある雑誌1冊に含まれる広告を1つ削除する                      |

ルーティングを作成すると、ルーティングヘルパーも作成されます。ヘルパーは`magazine_ads_url`や`edit_magazine_ad_path`のような名前になります。これらのヘルパーは、最初のパラメータとしてMagazineモデルのインスタンスを1つ取ります (`magazine_ads_url(@magazine)`)。

#### ネスティング回数の限界

ネストしたリソースの中でさらに別のリソースをネストすることは可能です。例：

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

すぐ想像が付くと思いますが、ネストが深くなるとたちまち扱いが厄介になります。たとえば、上のルーティングはアプリケーションで以下のようなパスとして認識されます。

```
/publishers/1/magazines/2/photos/3
```

このURLに対応するルーティングヘルパーは`publisher_magazine_photo_url`となります。このヘルパーを使用するには毎回3つの階層すべてでオブジェクトを指定する必要があります。ネスティングが深くなることでルーティングの扱いが困難になる問題については、Jamis Buckの有名な [記事](http://weblog.jamisbuck.org/2007/2/5/nesting-resources) を参照してください。JamisはRailsアプリケーション設計上のよい経験則を提案しています。

TIP: _リソースのネスティングは、ぜひとも1回にとどめて下さい。決して2回以上ネストするべきではありません。_

#### 「浅い」ネスト

前述したような深いネストを避けるひとつの方法として、コレクション (index/new/createのような、idを持たないアクション) だけを親のスコープの下で生成するという手法があります。このとき、メンバー (show/edit/update/destroyのような、idを必要とするアクション) をネストに含めないのがポイントです。これによりコレクションだけが階層化のメリットを受けられます。つまり、以下のように最小限の情報でリソースを一意に指定できるルーティングを作成するということです。

```ruby
resources :articles do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

この方法は、ルーティングの記述を複雑にせず、かつ深いネストを作らないという絶妙なバランスを保っています。`:shallow`オプションを使用することで、上と同じ内容をさらに簡単に記述できます。

```ruby
resources :articles do
  resources :comments, shallow: true
end
```

これによって生成されるルーティングは、最初の例と完全に同じです。親リソースで`:shallow`オプションを指定すると、すべてのネストしたリソースが浅くなります。

```ruby
resources :articles, shallow: true do
  resources :comments
  resources :quotes
  resources :drafts
end
```

DSL (ドメイン固有言語) である`shallow`メソッドをルーティングで使用すると、すべてのネストが浅くなるように内側にスコープを1つ作成します。これによって生成されるルーティングは、最初の例と完全に同じです。

```ruby
shallow do
  resources :articles do
    resources :comments
    resources :quotes
    resources :drafts
  end
end
```

`scope`メソッドには、「浅い」ルーティングをカスタマイズするためのオプションが2つあります。`:shallow_path`オプションは、指定されたパラメータをメンバーのパスの冒頭にだけ追加します。

```ruby
scope shallow_path: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上の場合、commentsリソースのルーティングは以下のようになります。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | -------------------------------------- | ----------------- | --------------------- |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path    |
| POST      | /articles/:article_id/comments(.:format)    | comments#create   | article_comments_path    |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path |
| GET       | /sekret/comments/:id/edit(.:format)    | comments#edit     | edit_comment_path     |
| GET       | /sekret/comments/:id(.:format)         | comments#show     | comment_path          |
| PATCH/PUT | /sekret/comments/:id(.:format)         | comments#update   | comment_path          |
| DELETE    | /sekret/comments/:id(.:format)         | comments#destroy  | comment_path          |

`:shallow_prefix`オプションを使用すると、指定されたパラメータを (パスではなく) 名前付きヘルパー名の冒頭に追加します。

```ruby
scope shallow_prefix: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上の場合、commentsリソースのルーティングは以下のようになります。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | -------------------------------------- | ----------------- | ------------------------ |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path    |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path    |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | article_comments_path    |
| GET       | /comments/:id/edit(.:format)           | comments#edit     | edit_sekret_comment_path |
| GET       | /comments/:id(.:format)                | comments#show     | sekret_comment_path      |
| PATCH/PUT | /comments/:id(.:format)                | comments#update   | sekret_comment_path      |
| DELETE    | /comments/:id(.:format)                | comments#destroy  | sekret_comment_path      |

### ルーティングの「concern」機能

concernを使用することで、他のリソースやルーティング内で使いまわせる共通のルーティングを宣言することができます。concernは以下のように定義します。

```ruby
concern :commentable do
  resources :comments
end

concern :image_attachable do
  resources :images, only: :index
end
```

concernを利用すると、同じようなルーティングを繰り返し記述せずに済み、複数のルーティング間で同じ動作を共有できます。

```ruby
resources :messages, concerns: :commentable

resources :articles, concerns: [:commentable, :image_attachable]
```

上のコードは以下と同等です。

```ruby
resources :messages do
  resources :comments
end

resources :articles do
  resources :comments
  resources :images, only: :index
end
```

concernはルーティング内のどのような場所にでも配置することができます。`scope`や`namespace`呼び出しでの使用法は以下のとおりです。

```ruby
namespace :articles do
  concerns :commentable
end
```

### オブジェクトからパスとURLを作成する

ルーティングヘルパーを使用する方法の他に、パラメータの配列からパスやURLを作成することもできます。例として、以下のようなルーティングがあるとします。

```ruby
resources :magazines do
  resources :ads
end
```

`magazine_ad_path`を使用すると、idを数字で渡す代りに`Magazine`と`Ad`のインスタンスを引数として渡すことができます。

```erb
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

複数のオブジェクトが集まったセットに対して`url_for`を使用することもできます。複数のオブジェクトを渡しても、適切なルーティングが自動的に決定されます。

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

上の場合、Railsは`@magazine`が`Magazine`であり、`@ad`が`Ad`であることを認識し、それに基づいて`magazine_ad_path`ヘルパーを呼び出します。`link_to`などのヘルパーでも、完全な`url_for`呼び出しの代りに単にオブジェクトを渡すことができます。

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

1冊の雑誌にだけリンクしたいのであれば、以下のように書きます。

```erb
<%= link_to 'Magazine details', @magazine %>
```

それ以外のアクションであれば、配列の最初の要素にアクション名を挿入するだけで済みます。

```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

これにより、モデルのインスタンスをURLとして扱うことができます。これはリソースフルなスタイルを採用する大きなメリットの1つです。

### RESTfulなアクションをさらに追加する

デフォルトで作成されるRESTfulなルーティングは7つですが、7つでなければならないということはありません。必要であれば、コレクションやコレクションの各メンバーに対して適用されるリソースを追加することもできます。

#### メンバールーティングを追加する

メンバー (member) ルーティングを追加したい場合は、`member`ブロックをリソースブロックに1つ追加します。

```ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

上のルーティングはGETリクエストとそれに伴う`/photos/1/preview`を認識し、リクエストを`Photos`コントローラの`preview`アクションにルーティングし、リソースid値を`params[:id]`に渡します。同時に、`photo_preview_url`ヘルパーと`photo_preview_path`ヘルパーも作成されます。

memberルーティングブロックの内側では、次に述べるHTTP動詞が指定されたルーティング名を認識できます。指定可能な動詞は`get`、`patch`、`put`、`post`、`delete`です。`member`ルーティングが1つだけしかないのであれば、以下のようにルーティングで`:on`オプションを指定することでブロックを省略できます。

```ruby
resources :photos do
  get 'preview', on: :member
end
```

`:on`オプションを省略しても同様のmemberルーティングが生成されます。この場合リソースidの値の取得に`params[:id]`ではなく`params[:photo_id]`を使用する点が異なります。

#### コレクションルーティングを追加する

ルーティングにコレクション (collection) を追加するには以下のようにします。

```ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

上のルーティングは、GETリクエスト+`/photos/search`などの (idを伴わない) パスを認識し、リクエストを`Photos`コントローラの`search`アクションにルーティングします。このとき`search_photos_url`や`search_photos_path`ルーティングヘルパーも同時に作成されます。

collectionルーティングでもmemberルーティングのときと同様に`:on`オプションを使用できます。

```ruby
resources :photos do
  get 'search', on: :collection
end
```

#### 追加されたnewアクションへのルーティングを追加する

`:on`オプションを使用して、たとえば以下のように別のnewアクションを追加できます。

```ruby
resources :comments do
  get 'preview', on: :new
end
```

上のようにすることで、GET + `/comments/new/preview`のようなパスが認識され、`Comments`コントローラの`preview`アクションにルーティングされます。`preview_new_comment_url`や`preview_new_comment_path`ルーティングヘルパーも同時に作成されます。

TIP: リソースフルなルーティングにアクションが多数追加されていることに気付いたら、それ以上アクションを追加するのをやめて、そこに別のリソースが隠されているのではないかと疑ってみる方がよいでしょう。

リソースフルでないルーティング
----------------------

Railsではリソースルーティングを行なう他に、任意のURLをアクションにルーティングすることもできます。この方式を使用する場合、リソースフルルーティングのような自動的なルーティンググループの生成は行われません。従って、アプリケーションで必要なルーティングを個別に設定することになります。

基本的にはリソースフルルーティングを使用すべきではありますが、このような単純なルーティングの方が適している箇所も多数あるはずです。リソースフルルーティングでは大袈裟過ぎる場合に、アプリケーションを無理にリソースフルなフレームワークに押し込める必要はありません。

シンプルルーティングは、特に従来形式のURLを新しいRailsのアクションに割り当てることがずっと簡単に行えるようになります。

### パラメータの割り当て

通常のルーティングを設定するのであれば、RailsがルーティングをブラウザからのHTTPリクエストに割り当てるためのシンボルをいくつか渡します。以下のルーティングを例にとってみましょう。

```ruby
get 'photos(/:id)', to: :display
```

ブラウザからの`/photos/1`リクエストが上のルーティングで処理される (他のルーティング設定にはマッチしなかったとします) と、`PhotosController`の`display`アクションが呼び出され、URL末尾のパラメータ`"1"`へのアクセスは`params[:id]`で行なえます。`:id`が必須パラメータではないことがかっこ () で示されているので、このルーティングは`/photos`を`PhotosController#display`にルーティングすることもできます。

### 動的なセグメント

通常のルーティングの一部として、文字列を固定しない動的なセグメントを自由に使用できます。あらゆるセグメントは`params`の一部に含めてアクションに渡すことができます。以下のルーティングを設定したとします。

```ruby
get 'photos/:id/:user_id', to: 'photos#show'
```

ブラウザからの`/photos/1/2`パスは`PhotosController`の`show`アクションに割り当てられます。`params[:id]`には`"1"`、`params[:user_id]`には`"2"`がそれぞれ保存されます。

TIP: 動的なセグメント分割ではドット`.`をデフォルトでは使用できません。ドットはフォーマット済みルーティングでは区切り文字として使用されるためです。どうしても動的セグメント内でドットを使用したい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使用できます。

### 静的なセグメント

ルート作成時にコロンを付けなかった部分は、静的なセグメントとして固定文字列が指定されます。

```ruby
get 'photos/:id/with_user/:user_id', to: 'photos#show'
```

上のルーティングは、`/photos/1/with_user/2`のようなパスにマッチします。このときアクションで使用できる`params`は `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### クエリ文字列

クエリ文字列 (訳注: `?パラメータ名=値`の形式でURLの末尾に置かれるパラメータ) で指定されているパラメータもすべて`params`に含まれます。以下のルーティングを例にとってみましょう。

```ruby
photos/:id', to: 'photos#show'
```

ブラウザからのリクエストで`/photos/1?user_id=2`というパスが渡されると、`Photos`コントローラの`show`アクションに割り当てられます。このときの`params`は`{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### デフォルト設定を定義する

`:defaults`オプションにハッシュを1つ渡すことで、ルーティング内にデフォルトを定義できます。このとき、動的なセグメントとして指定する必要のないパラメータを次のように適用することも可能です。

```ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

上のルーティングはブラウザからの`/photos/12`パスにマッチし、`Photos`コントローラの`show`アクションに割り当てられます。

`defaults`をブロック形式で使うと、複数の項目についてデフォルトを設定することもできます。

```ruby
defaults format: :json do
  resources :photos
end
```

NOTE: セキュリティ上の理由により、クエリパラメータでデフォルトをオーバーライドすることはできません。URLパスの置き換えによる動的セグメントのみ、オーバーライド可能です。

### 名前付きルーティング

`:as`オプションを使用することで、どんなルーティングにも名前を指定できます。

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

上のルーティングでは`logout_path`と`logout_url`がアプリケーションの名前付きヘルパーとして作成されます。`logout_path`を呼び出すと`/exit`が返されます。

この方法を使用して、リソースとして定義されているルーティングを以下のように上書きすることもできます。

```ruby
get ':username', to: 'users#show', as: :user
```

上のルーティングでは`user_path`メソッドが生成され、コントローラ・ヘルパー・ビューでそれぞれ使用できるようになります。このメソッドは、`/bob`のようなユーザー名を持つルーティングに移動します。`Users`コントローラの`show`アクションの内部で`params[:username]`にアクセスすると、ユーザー名を取り出すことができます。パラメータ名を`:username`にしたくない場合は、ルーティング定義の`:username`の部分を変更してください。

### HTTP動詞を制限する

あるルーティングを特定のHTTP動詞に割り当てるために、通常は`get`、`post`、`put`、`patch`、`delete`メソッドのいずれかを使用する必要があります。`match`メソッドと`:via`オプションを使用することで、複数のHTTP動詞に同時にマッチするルーティングを作成できます。

```ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

`via: :all`を指定すると、すべてのHTTP動詞にマッチする特別なルーティングを作成できます。

```ruby
match 'photos', to: 'photos#show', via: :all
```

NOTE: 1つのアクションに`GET`リクエストと`POST`リクエストを両方ルーティングすると、セキュリティに影響する可能性があります。本当に必要な理由がない限り、1つのアクションにすべてのHTTP動詞をルーティングすることは避けてください。

NOTE: Railsでは`GET`のCSRFトークンをチェックしません。絶対に`GET`リクエストでデータベースに書き込んではいけません。詳しくは[セキュリティガイド](security.html#csrfへの対応策)のCSRF対策を参照してください。

### セグメントを制限する

`:constraints`オプションを使用すると、動的セグメントのURLフォーマットを特定の形式に制限することができます。

```ruby
get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }
```

上のルーティングは`/photos/A12345`のようなパスにはマッチしますが、`/photos/893`にはマッチしません。以下のようにもっと簡潔な方法で記述することもできます。

```ruby
get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/
```

`:constraints`では正規表現を使用できますが、ここでは正規表現の「アンカー」は使用できないという制限があることにご注意ください。たとえば、以下のルーティングは無効です。

```ruby
get '/:id', to: 'articles#show', constraints: {id: /^\d/}
```

対象となるルーティングはすべて初めからアンカーされているので、このようなアンカー表現を使用する必要はないはずです。

たとえば以下のルーティングでは、ルート (root) 名前空間を共有する際に`articles`に対して`to_param`が`1-hello-world`のように数字で始まる値だけが使用できるようになっており、`users`に対して`to_param`が`david`のように数字で始まらない値だけが使用できるようになっています。

```ruby
get '/:id', to: 'articles#show', constraints: { id: /\d.+/ }
get '/:username', to: 'users#show'
```

### リクエスト内容に応じて制限を加える

また、`String`を返す<a href="action_controller_overview.html#requestオブジェクト">Requestオブジェクト</a>の任意のメソッドに基いてルーティングを制限することもできます。

リクエストに応じた制限は、セグメントを制限するときと同様の方法で指定することができます。

```ruby
get 'photos', constraints: {subdomain: 'admin'}
```

ブロックフォームに対して制限を指定することもできます。

```ruby
namespace :admin do
  constraints subdomain: 'admin' do
    resources :photos
  end
end
```

NOTE: リクエストベースの制限は、<a href="action_controller_overview.html#requestオブジェクト">Requestオブジェクト</a>に対してあるメソッドを呼び出すことで実行されます。メソッド呼び出し時にハッシュキーと同じ名前をメソッドに渡し、返された値をハッシュ値と比較します。従って、制限された値は、対応するRequestオブジェクトメソッドが返す型と一致する必要があります。たとえば、`constraints: { subdomain: 'api' }`という制限は`api`サブドメインに期待どおりマッチしますが、`constraints: { subdomain: :api }`のようにシンボルを使用した場合は`api`サブドメインに一致しません。`request.subdomain`が返す`'api'`は文字列型であるためです。

NOTE: `format`の制限には例外があります。これはRequestオブジェクトのメソッドですが、すべてのパスに含まれる暗黙的なオプションのパラメータでもあります。`format`の制限よりセグメント制限が優先されます。たとえば、`get 'foo'、constraints: {format： 'json'}`は`GET / foo`と一致します。これはデフォルトでformatがオプションであるためです。しかし、次のように[ラムダを使う](#高度な制限)ことができます。`get 'foo', constraints: lambda { |req| req.format == :json }` このルーティング指定は明示的なJSONリクエストにのみ一致します。

### 高度な制限

より高度な制限を使用したい場合、Railsで必要な`matches?`に応答できるオブジェクトを渡す方法があります。例として、ブラックリストに記載されているすべてのユーザーを`BlacklistController`にルーティングしたいとします。この場合、以下のように設定します。

```ruby
class BlacklistConstraint
  def initialize
    @ips = Blacklist.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end

Rails.application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: BlacklistConstraint.new
end
```

制限をラムダとして指定することもできます。

```ruby
Rails.application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: lambda { |request| Blacklist.retrieve_ips.include?(request.remote_ip) }
end
```

`matches?`メソッドおよびラムダはいずれも引数として`request`オブジェクトを取ります。

### ルーティンググロブとワイルドカードセグメント

ルーティンググロブ (route globbing) とはワイルドカード展開のことであり、ルーティングのある位置から下のすべての部分に特定のパラメータをマッチさせる際に使用します。例:

```ruby
get 'photos/*other', to: 'photos#unknown'
```

上のルーティングは`photos/12`や`/photos/long/path/to/12`にマッチし、`params[:other]`には`"12"`や`"long/path/to/12"`が設定されます。先頭にアスタリスク`*`が付いている部分を「ワイルドカードセグメント」と呼びます。

ワイルドカードセグメントはルーティングのどの部分でも使用できます。例:

```ruby
get 'books/*section/:title', to: 'books#show'
```

上は`books/some/section/last-words-a-memoir`にマッチし、`params[:section]`には`'some/section'`が保存され、`params[:title]`には`'last-words-a-memoir'`が保存されます。

技術上は、1つのルーティングに2つ以上のワイルドカードセグメントを含めることは可能です。マッチャがセグメントをパラメータに割り当てる方法は直感的です。例:

```ruby
get '*a/foo/*b', to: 'test#index'
```

上のルーティングは`zoo/woo/foo/bar/baz`にマッチし、`params[:a]`には`'zoo/woo'`が保存され、`params[:b]`には`'bar/baz'`が保存されます。

NOTE: `'/foo/bar.json'`をリクエストすると`params[:pages]`には`'foo/bar'`がJSONリクエストフォーマットで保存されます。Rails 3.0.xの動作に戻したい場合は、以下のように`format: false`を指定することができます。

```ruby
get '*pages', to: 'pages#show', format: false
```

NOTE: このセグメントフォーマットを必須にしたい場合は、以下のように`format: true`を指定します。

```ruby
get '*pages', to: 'pages#show', format: true
```

### リダイレクト

ルーティングで`redirect`を使用すると、あるパスを他のあらゆるパスにリダイレクトできます。

```ruby
get '/stories', to: redirect('/articles')
```

パスにマッチする動的セグメントを再利用してリダイレクトすることもできます。

```ruby
get '/stories/:name', to: redirect('/articles/%{name}')
```

リダイレクトにブロックを渡すこともできます。このリダイレクトは、シンボル化されたパスパラメータとrequestオブジェクトを受け取ります。

```ruby
get '/stories/:name', to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
get '/stories', to: redirect { |path_params, req| "/articles/#{req.subdomain}" }
```

デフォルトのリダイレクトは、HTTPステータスで言う「301 "Moved Permanently"」であることにご注意ください。一部のWebブラウザやプロキシサーバーはこの種のリダイレクトをキャッシュすることがあり、その場合リダイレクト前の古いページにはアクセスできなくなります。次のように`:status`オプションを使うことでレスポンスのステータスを変更できます。

```ruby
get '/stories/:name', to: redirect('/articles/%{name}', status: 302)
```

どの場合であっても、ホスト (`http://www.example.com`など) がURLの冒頭で指定されていない場合は、Railsは (以前のリクエストではなく) 現在のリクエストから詳細を取得します。

### Rackアプリケーションにルーティングする

`Post`コントローラの`index`アクションに対応する`'articles#index'`のような文字列の代りに、任意の<a href="rails_on_rack.html">Rackアプリケーション</a>をマッチャーのエンドポイントとして指定することができます。

```ruby
match '/application.js', to: MyRackApp, via: :all
```

Railsルーターから見れば、`MyRackApp`が`call`に応答して`[status, headers, body]`を返す限り、ルーティング先がRackアプリケーションであるかアクションであるかは区別できません。これは`via: :all`の適切な利用法です。というのは、適切と考えられるすべてのHTTP動詞をRackアプリケーションで扱えるようにできるからです。

NOTE: 参考までに、`'articles#index'`は実際には`ArticlesController.action(:index)`という形に展開されます。これは正しいRackアプリケーションを返します。

マッチャーのエンドポイントとしてRackアプリを指定する場合、受け取るアプリのルーティングは変更されない点にご留意ください。以下のルーティングでは、Rackアプリは`/admin`へのルーティングを期待するべきです。

```ruby
 match '/admin', to: AdminApp, via: :all
 ```

Rackアプリがルートパスでリクエストを受け取れるようにしたい場合は、`mount`を使います。

```ruby
 mount AdminApp, at: '/admin'
 ```

### `root`を使用する

`root`メソッドを使用することで、Railsがルート`'/'`とすべき場所を指定できます。

```ruby
root to: 'pages#main'
root 'pages#main' # 上の省略形
```

`root`ルーティングは、ルーティングファイルの先頭に記述してください。rootは最もよく使用されるルーティングであり、最初にマッチする必要があるからです。

NOTE: `root`ルーティングがアクションに渡せるのは`GET`リクエストだけです。

名前空間やスコープの内側にrootを置くこともできます。例:

```ruby
namespace :admin do
  root to: "admin#index"
end

root to: "home#index"
```

### Unicode文字列をルーティングで使用する

Unicode文字列をルーティングで直接使用することもできます。例:

```ruby
get 'こんにちは', to: 'welcome#index'
```

リソースフルルーティングをカスタマイズする
------------------------------

ほとんどの場合、`resources :articles`のような指定を行ってデフォルトのルーティングやヘルパーを生成することで用は足りますが、もう少しルーティングをカスタマイズしたくなることもあります。Railsでは、リソースフルなヘルパーの一般的などの部分であっても事実上自由にカスタマイズ可能です。

### 使用するコントローラを指定する

`:controller`オプションは、リソースで使用するコントローラを明示的に指定します。例:

```ruby
resources :photos, controller: 'images'
```

上のルーティングは、`/photos`で始まるパスを認識しますが、ルーティング先を`Images`コントローラにします。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | images#index      | photos_path          |
| GET       | /photos/new      | images#new        | new_photo_path       |
| POST      | /photos          | images#create     | photos_path          |
| GET       | /photos/:id      | images#show       | photo_path(:id)      |
| GET       | /photos/:id/edit | images#edit       | edit_photo_path(:id) |
| PATCH/PUT | /photos/:id      | images#update     | photo_path(:id)      |
| DELETE    | /photos/:id      | images#destroy    | photo_path(:id)      |

NOTE: このリソースへのパスを生成するには`photos_path`や`new_photo_path`などを使用してください。

名前空間内のコントローラは以下のように直接指定することができます。例:

```ruby
resources :user_permissions, controller: 'admin/user_permissions'
```

上は`Admin::UserPermissions`にルーティングされます。

NOTE: ここでサポートされている記法は、`/`で区切る「ディレクトリ式」のみです。Rubyの定数表記法 (`controller: 'Admin::UserPermissions'`など) をコントローラに対して使用すると、ルーティングで問題が生じ、警告が出力される可能性があります。

### 制限を指定する

`:constraints`オプションを使用すると、暗黙で使用される`id`に対してフォーマットを指定することができます。例:

```ruby
resources :photos, constraints: {id: /[A-Z][A-Z][0-9]+/}
```

上の宣言は`:id`パラメータに制限を加え、指定した正規表現にのみマッチするようにします。従って、上の例では`/photos/1`のようなパスにはマッチしなくなります。代わって、`/photos/RR27`のようなパスにマッチするようになります。

ブロックフォームを使用することで、多数のルーティングに対して1つの制限をまとめて与えることもできます。

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: もちろん、この場合であれば「リソースフルでない」ルーティングに適用可能な、より高度な制限を加えることもできます。

TIP: `:id`パラメータではドット`.`をデフォルトでは使用できません。ドットはフォーマット済みルーティングでは区切り文字として使用されるためです。どうしても`:id`内でドットを使用したい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使用できます。

### 名前付きヘルパーをオーバーライドする

`:as`オプションを使用すると、名前付きルーティングヘルパーを上書きして異なる名前を使用できます。例:

```ruby
resources :photos, as: 'images'
```

上のルーティングでは、`/photos`で始まるブラウザからのパスを認識し、このリクエストを`Photos`コントローラにルーティングしますが、ヘルパーの命名に`:as`オプションの値が使用されます。

| HTTP 動詞 | パス                  | コントローラ#アクション   | 名前付きヘルパー              |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | photos#index      | images_path          |
| GET       | /photos/new      | photos#new        | new_image_path       |
| POST      | /photos          | photos#create     | images_path          |
| GET       | /photos/:id      | photos#show       | image_path(:id)      |
| GET       | /photos/:id/edit | photos#edit       | edit_image_path(:id) |
| PATCH/PUT | /photos/:id      | photos#update     | image_path(:id)      |
| DELETE    | /photos/:id      | photos#destroy    | image_path(:id)      |

### `new`セグメントや`edit`セグメントをオーバーライドする

`:path_names`オプションを使用すると、パスに含まれている、自動生成された"new"セグメントや"edit"セグメントをオーバーライドできます。

```ruby
resources :photos, path_names: { new: 'make', edit: 'change' }
```

これにより、ルーティングで以下のようなパスが認識できるようになります。

```
/photos/make
/photos/1/change
```

NOTE: このオプションを指定しても、実際のアクション名が変更されるわけではありません。変更後のパスを使用しても、ルーティング先は依然として`new`アクションと`edit`アクションのままです。

TIP: このオプションによる変更をすべてのルーティングに統一的に適用したくなった場合は、スコープを使用できます。

```ruby
scope path_names: { new: 'make' } do
  # 残りすべてのルーティング
end
```

### 名前付きルーティングヘルパーにプレフィックスを追加する

`:as`オプションを使用することで、Railsがルーティングに対して生成する名前付きルーティングヘルパー名の冒頭に文字を追加できます (プレフィックス)。パススコープを使用するルーティング同士での名前の衝突を避けたい場合に使用してください。例:

```ruby
scope 'admin' do
  resources :photos, as: 'admin_photos'
end

resources :photos
```

上のルーティングでは、`admin_photos_path`や`new_admin_photo_path`などのルーティングヘルパーが生成されます。

ルーティングヘルパーのグループにプレフィックスを追加するには、以下のように`scope`メソッドで`:as`オプションを使用します。

```ruby
scope 'admin', as: 'admin' do
  resources :photos, :accounts
end

resources :photos, :accounts
```

上によって、`admin_photos_path`と`admin_accounts_path`などのルーティングが生成されます。これらは`/admin/photos`と`/admin/accounts`にそれぞれ割り当てられます。

NOTE: `namespace`スコープを使用すると、`:module`や`:path`プレフィックスに加えて`:as`も自動的に追加されます。

名前付きパラメータを持つルーティングにプレフィックスを追加することもできます。

```ruby
scope ':username' do
  resources :articles
end
```

上のルーティングにより、`/bob/articles/1`のような形式のURLを使用できるようになります。さらに、コントローラ、ヘルパー、ビューのいずれにおいても、このパスの`username`の部分に相当する文字列 (この場合であればbob) を`params[:username]`で参照できます。

### ルーティングの作成を制限する

Railsは、アプリケーション内のすべてのRESTfulルーティングに対してデフォルトで7つのアクション (index、show、new、create、edit、update、destroy) へのルーティングを作成します。`:only`オプションや`:except`オプションを使用することで、これらのルーティングを微調整できます。`:only`オプションは、指定されたルーティングだけを生成するよう指示します。

```ruby
resources :photos, only: [:index, :show]
```

これで、`/photos`への`GET`リクエストは成功し、`/photos` への`POST`リクエスト (通常であれば`create`アクションにルーティングされます) は失敗します。

`:except`オプションは逆に、指定したルーティングのみを生成 _しない_ よう指示します。

```ruby
resources :photos, except: :destroy
```

この場合、`destroy` (`/photos/:id`への`DELETE`リクエスト) を除いて通常のルーティングが生成されます。

TIP: アプリケーションでRESTfulルーティングが多数使用されているのであれば、それらに適宜`:only`や`:except`を使用して、本当に必要なルーティングのみを生成することで、メモリ使用量の節約とルーティングプロセスの速度向上が見込めます。

### パスを変更する

`scope`メソッドを使用することで、`resources`によって生成されるデフォルトのパス名を変更できます。

```ruby
scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
  resources :categories, path: 'kategorien'
end
```

上のようにすることで、以下のような`Categories`コントローラへのルーティングが作成されます。

| HTTP 動詞 | パス | コントローラ#アクション | 名前付きヘルパー |
| --------- | -------------------------- | ------------------ | ----------------------- |
| GET       | /kategorien                | categories#index   | categories_path         |
| GET       | /kategorien/neu            | categories#new     | new_category_path       |
| POST      | /kategorien                | categories#create  | categories_path         |
| GET       | /kategorien/:id            | categories#show    | category_path(:id)      |
| GET       | /kategorien/:id/bearbeiten | categories#edit    | edit_category_path(:id) |
| PATCH/PUT | /kategorien/:id            | categories#update  | category_path(:id)      |
| DELETE    | /kategorien/:id            | categories#destroy | category_path(:id)      |

### 「単数形のフォーム」をオーバーライドする

あるリソースの「単数形のフォーム」を定義したい場合、`Inflector`に活用形ルールを追加します。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tooth', 'teeth'
end
```

### 名前付きリソースで`:as`を使用する

`:as`を使用すると、ネストしたルーティングヘルパー内のリソース用に自動生成された名前をオーバーライドできます。例:

```ruby
resources :magazines do
  resources :ads, as: 'periodical_ads'
end
```

上のルーティングによって、`magazine_periodical_ads_url`や`edit_magazine_periodical_ad_path`などのルーティングヘルパーが生成されます。

### 名前付きルーティングのパラメータをオーバーライドする

`:param`オプションは、デフォルトのリソース識別子`:id` (ルーティングを生成するために使用される[動的なセグメント](routing.html#動的なセグメント)の名前) をオーバーライドします。`params[<:param>]`を使用して、コントローラからそのセグメントにアクセスできます。

```ruby
resources :videos, param: :identifier
```

```
     videos GET  /videos(.:format)                  videos#index
            POST /videos(.:format)                  videos#create
 new_videos GET  /videos/new(.:format)              videos#new
edit_videos GET  /videos/:identifier/edit(.:format) videos#edit
```

```ruby
Video.find_by(identifier: params[:identifier])
```

関連するモデルの `ActiveRecord::Base#to_param` をオーバーライドしてURLを作成することができます。

```ruby
class Video < ApplicationRecord
  def to_param
    identifier
  end
end

video = Video.find_by(identifier: "Roman-Holiday")
edit_videos_path(video) # => "/videos/Roman-Holiday"
```

ルーティングの調査とテスト
-----------------------------

Railsには、ルーティングを調べる機能とテストする機能が備わっています。

### 既存のルールを一覧表示する

現在のアプリケーションで利用可能なルーティングをすべて表示するには、サーバーが **development** 環境で動作している状態で`http://localhost:3000/rails/info/routes`をブラウザで開きます。ターミナルで`rails routes`コマンドを実行しても同じ結果を得られます。

どちらの方法を使用した場合でも、`config/routes.rb`ファイルに記載された順にルーティングが表示されます。1つのルーティングについて以下の情報が表示されます。

* ルーティング名 (あれば)
* 使用されているHTTP動詞 (そのルーティングがすべてのHTTP動詞に応答するのでない場合)
* マッチするURLパターン
* そのルーティングで使用するパラメータ

以下は、あるRESTfulルーティングに対して`rails routes`を実行した結果から抜粋したものです。

```
    users GET    /users(.:format)          users#index
          POST   /users(.:format)          users#create
new_user GET    /users/new(.:format)      users#new
edit_user GET    /users/:id/edit(.:format) users#edit
```

`-g`（grepオプション）を使ってルーティングを検索できます。URLヘルパー名、HTTP動詞、URLパスのいずれかに部分マッチするルーティングが出力されます。

```
$ bin/rails routes -g new_comment
$ bin/rails routes -g POST
$ bin/rails routes -g admin
```

特定のコントローラに対応するルーティングだけを表示したい場合は、`-c`オプションを使います。


```
$ bin/rails routes -c users
$ bin/rails routes -c admin/users
$ bin/rails routes -c Comments
$ bin/rails routes -c Articles::CommentsController
```

TIP: 折り返しが発生しないぐらいに十分大きなサイズのターミナルを使用できるのであれば、`rails routes`コマンドの出力の方がおそらく読みやすいでしょう。

### ルーティングをテストする

アプリケーションの他の部分と同様、ルーティング部分もテスティング戦略に含めておくべきでしょう。Railsでは、テスティングを容易にするために3つの[ビルトインアサーション](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html) が用意されています。

* `assert_generates`
* `assert_recognizes`
* `assert_routing`

#### `assert_generates`アサーション

`assert_generates`は、特定のオプションの組み合わせを使用した場合に特定のパスが生成されること、そしてそれらがデフォルトのルーティングでもカスタムルーティングでも使用できることをテストするアサーション (assert, assertion: 主張・検証とも) です。例:

```ruby
assert_generates '/photos/1', { controller: 'photos', action: 'show', id: '1' }
assert_generates '/about', controller: 'pages', action: 'about'
```

#### `assert_recognizes`アサーション

`assert_recognizes`は`assert_generates`と逆方向のテスティングを行います。与えられたパスが認識可能であること、アプリケーションの特定の場所にルーティングされることをテストするアサーションです。例:

```ruby
assert_recognizes({ controller: 'photos', action: 'show', id: '1' }, '/photos/1')
```

引数で`:method`を使用してHTTP動詞を指定することもできます。

```ruby
assert_recognizes({ controller: 'photos', action: 'create' }, { path: 'photos', method: :post })
```

#### `assert_routing`アサーション

`assert_routing`アサーションは、ルーティングを2つの観点 (与えられたパスによってオプションが生成されること、そのオプションによって元のパスが生成されること) からチェックします。つまり、`assert_generates`と`assert_recognizes`の機能を組み合わせたものになります。

```ruby
assert_routing({ path: 'photos', method: :post }, { controller: 'photos', action: 'create' })
```
