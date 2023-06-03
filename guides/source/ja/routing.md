Rails のルーティング
=================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Rails Routing from the Outside In](https://guides.rubyonrails.org/routing.html)を日本語に翻訳した文書です。

本ガイドでは、開発者に向けてRailsのルーティング機能を解説します（訳注: routeとrootを区別するため、訳文ではrouteを基本的に「ルーティング」と訳します）。

このガイドの内容:

* `config/routes.rb`のコードの読み方
* 独自のルーティング作成法 （リソースベースのルーティングが推奨されますが、`match`メソッドによるルーティングも可能です）
* ルーティングのパラメータの宣言方法（コントローラのアクションに渡される）
* ルーティングヘルパーを使ってパスやURLを自動生成する方法
* 制限の作成やRackエンドポイントのマウントなどの高度な手法

--------------------------------------------------------------------------------


Railsルーターの目的
-------------------------------

Railsのルーターは受け取ったURLを認識し、適切なコントローラ内アクションやRackアプリケーションに振り分けます。ルーターはパスやURLも生成できるので、ビューでこれらのパスやURLを直接ハードコードする必要はありません。

### URLを実際のコードに振り分ける

Railsアプリケーションが以下のHTTPリクエストを受け取ったとします。

```
GET /patients/17
```

このリクエストは、特定のコントローラ内アクションにマッチさせるようルーターに要求しています。最初にマッチしたのが以下のルーティングだとします。

```ruby
get '/patients/:id', to: 'patients#show'
```

このリクエストは`patients`コントローラの`show`アクションに割り当てられ、`params`には`{ id: '17' }`ハッシュが含まれています。

NOTE: Railsではコントローラ名にスネークケースを使います。たとえば`MonsterTrucksController`のような複合語のコントローラを使う場合は、`monster_trucks#show`のように指定します。

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

すると、ルーターによって`/patients/17`というパスが生成されます。これを利用することでビューが改修しやすくなり、コードも読みやすくなります。このidはルーティングヘルパーで指定する必要がない点にご注目ください。

### Railsルーターを設定する

アプリケーションやエンジンのルーティングは`config/routes.rb`ファイルの中に存在し、通常以下のような感じになっています。

```ruby
Rails.application.routes.draw do
  resources :brands, only: [:index, :show] do
    resources :products, only: [:index, :show]
  end

  resource :basket, only: [:show, :update, :destroy]

  resolve("Basket") { route_for(:basket) }
end
```

これは通常のRubyソースファイルなので、Rubyのあらゆる機能を用いてルーティングを定義できます。ただしルーターのDSLメソッド名と変数名と衝突する可能性があるので、変数名には注意が必要です。

NOTE: ルーティング定義をラップする`Rails.application.routes.draw do ... end`ブロックは、ルーターDSLのスコープを確定するのに不可欠なので、削除してはいけません。

リソースベースのルーティング: Railsのデフォルト
-----------------------------------

リソースベースのルーティング (以下リソースルーティング) を使うことで、リソースベースで構成されたコントローラに対応する共通のルーティングを手軽に宣言できます。[`resources`][]を宣言するだけで、コントローラの`index`、`show`、`new`、`edit`、`create`、`update`、`destroy`アクションを個別に宣言しなくても1行で宣言が完了します。

[`resources`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-resources

### Web上のリソース

ブラウザはRailsに対してリクエストを送信する際に、特定のHTTPメソッド（`GET`、`POST`、`PATCH`、`PUT`、`DELETE`など）を使って、URLに対するリクエストを作成します。上に述べたHTTPメソッドは、いずれもリソースに対して特定の操作の実行を指示するリクエストです。リソースルーティングでは、関連するさまざまなリクエストを1つのコントローラ内のアクションに割り当てます。

Railsアプリケーションが以下のHTTPリクエストを受け取ったとします。

```
DELETE /photos/17
```

このリクエストは、特定のコントローラ内アクションにマッピングさせるようルーターに要求しています。最初にマッチしたのが以下のルーティングだとします。

```ruby
resources :photos
```

Railsはこのリクエストを`photos`コントローラ内の`destroy`アクションに割り当て、`params`ハッシュに`{ id: '17' }`を含めます。

### CRUD、verb、アクション

Railsのリソースフルルーティングでは、（GET、PUTなどの）各種HTTP verb（動詞、HTTPメソッドとも呼ばれます） と、コントローラ内アクションを指すURLが対応付けられます。1つのアクションは、データベース上での特定のCRUD（Create/Read/Update/Delete）操作に対応付けられるルールになっています。たとえば、以下のようなルーティングが1つあるとします。

```ruby
resources :photos
```

上の記述により、アプリケーション内に以下の7つのルーティングが作成され、いずれも`Photos`コントローラに対応付けられます。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | ---------------- | ----------------- | -------------------------------------------- |
| GET       | /photos          | photos#index      | すべての写真の一覧を表示                 |
| GET       | /photos/new      | photos#new        | 写真を1つ作成するためのHTMLフォームを返す |
| POST      | /photos          | photos#create     | 写真を1つ作成する                           |
| GET       | /photos/:id      | photos#show       | 特定の写真を表示する                     |
| GET       | /photos/:id/edit | photos#edit       | 写真編集用のHTMLフォームを1つ返す      |
| PATCH/PUT | /photos/:id      | photos#update     | 特定の写真を更新する                      |
| DELETE    | /photos/:id      | photos#destroy    | 特定の写真を削除する                      |

NOTE: Railsのルーターでは、サーバーへのリクエストをマッチさせる際にHTTP verbとURLを使っているため、4種類のURL（`/photos`、`/photos/new`、`/photos/:id`、`/photos/:id/edit`）が7種類の異なるアクション（`index`、`show`、`new`、`create`、`edit`、`update`、`destroy`）に割り当てられています。

NOTE: Railsのルーティングは、ルーティングファイルの「上からの記載順に」マッチします。このため、たとえば`resources :photos`というルーティングが`get 'photos/poll'`よりも上の行にあれば、`resources`行の`show`アクションが`get`行の記述よりも優先されるので、`get`行のルーティングは有効になりません。これを修正するには、`get`行を`resources`行 **よりも上** の行に移動してください。これにより、`get`行がマッチするようになります。

### パスとURL用ヘルパー

リソースフルなルーティングを作成すると、アプリケーションのコントローラで多くのヘルパーが利用できるようになります。`resources :photos`というルーティングを例に取ってみましょう。

* `photos_path`は`/photos`を返します
* `new_photo_path`は`/photos/new`を返します
* `edit_photo_path(:id)`は`/photos/:id/edit`を返します（`edit_photo_path(10)`であれば`/photos/10/edit`を返します）
* `photo_path(:id)`は`/photos/:id`を返します（`photo_path(10)`であれば`/photos/10`を返します）

これらの`_path`ヘルパーには、それぞれに対応する`_url`ヘルパー（`photos_url`など）もあります。`_url`ヘルパーは、同じパスの前に「現在のホスト名」「ポート番号」「パスのプレフィックス」を追加して返します。

TIP: 自分のルーティングで利用できるルーティングヘルパーを見つけるには、後述の[既存のルールを一覧表示する](#既存のルールを一覧表示する)を参照してください。

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

ユーザーがページを表示する際にidを一切参照しないリソースが使われることがあります。たとえば、`/profile`では常に「現在ログインしているユーザー自身」のプロファイルを表示し、他のユーザーidを参照する必要がないとします。このような場合には、単数形リソース（singular resource）を使って以下のように`show`アクションに（`/profile/:id`ではなく）`/profile`を割り当てられます。

```ruby
get 'profile', to: 'users#show'
```

`to:`の引数に`String`を渡す場合は`コントローラ#アクション`形式であることが前提ですが、`Symbol`を使う場合は、`to:`オプションを`action:`に置き換えるべきです。`#`なしの`String`を使う場合は、`to:`オプションを`controller:`に置き換えるべきです。

```ruby
get 'profile', action: :show, controller: 'users'
```

以下のリソースフルなルーティングは

```ruby
resource :geocoder
resolve('Geocoder') { [:geocoder] }
```

`Geocoders`コントローラに割り当てられた以下の6つのルーティングを作成します。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | -------------- | ----------------- | --------------------------------------------- |
| GET       | /geocoder/new  | geocoders#new     | geocoder作成用のHTMLフォームを返す |
| POST      | /geocoder      | geocoders#create  | geocoderを作成する                       |
| GET       | /geocoder      | geocoders#show    | 1つしかないgeocoderリソースを表示する    |
| GET       | /geocoder/edit | geocoders#edit    | geocoder編集用のHTMLフォームを返す  |
| PATCH/PUT | /geocoder      | geocoders#update  | 1つしかないgeocoderリソースを更新する     |
| DELETE    | /geocoder      | geocoders#destroy | geocoderリソースを削除する                  |

NOTE: 単数形リソースは複数形のコントローラに対応付けられます。これは、同じコントローラで単数形のルーティング（`/account`）と複数形のルーティング（`/accounts/45`）を両方使いたい場合を想定しているためです。従って、`resource :photo`と`resources :photos`のどちらも、単数形ルーティングと複数形ルーティングを両方作成し、同一のコントローラ（`PhotosController`）に割り当てられます。

単数形のリソースフルなルーティングを使うと、以下のヘルパーメソッドが生成されます。

* `new_geocoder_path`は`/geocoder/new`を返します
* `edit_geocoder_path`は`/geocoder/edit`を返します
* `geocoder_path`は`/geocoder`を返します。

NOTE: `Geocoder`のインスタンスを[レコード識別](form_helpers.html#レコード識別を利用する)でルーティングするには`resolve`の呼び出しが必要です。

複数形リソースの場合と同様に、同じヘルパー名の末尾を`_url`にすると「現在のホスト名」「ポート番号」「パスのプレフィックス」も含まれます。

### コントローラの名前空間とルーティング

コントローラを名前空間でグループ化することもできます。最もよく使われる名前空間といえば、多数の管理用コントローラ群をまとめる`Admin::`名前空間でしょう。これらのコントローラを`app/controllers/admin`ディレクトリに配置し、ルーティングでこれらをグループ化できます。[`namespace`][]ブロックを使うと、このようなグループへルーティングできます。

```ruby
namespace :admin do
  resources :articles, :comments
end
```

上のルーティングにより、`articles`コントローラや`comments`コントローラへのルーティングが多数生成されます。たとえば、`Admin::ArticlesController`向けに作成されるルーティングは以下のとおりです。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | ------------------------ | ---------------------- | ---------------------------- |
| GET       | /admin/articles          | admin/articles#index   | admin_articles_path          |
| GET       | /admin/articles/new      | admin/articles#new     | new_admin_article_path       |
| POST      | /admin/articles          | admin/articles#create  | admin_articles_path          |
| GET       | /admin/articles/:id      | admin/articles#show    | admin_article_path(:id)      |
| GET       | /admin/articles/:id/edit | admin/articles#edit    | edit_admin_article_path(:id) |
| PATCH/PUT | /admin/articles/:id      | admin/articles#update  | admin_article_path(:id)      |
| DELETE    | /admin/articles/:id      | admin/articles#destroy | admin_article_path(:id)      |

例外的に、(`/admin`が前についていない) `/articles`を`Admin::ArticlesController`にルーティングしたい場合は、以下のようにすることもできます。

```ruby
scope module: 'admin' do
  resources :articles, :comments
end
```

以下のようにブロックを使わない記述も可能です。

```ruby
resources :articles, module: 'admin'
```

逆に、`/admin/articles`を (`Admin::`なしの) `ArticlesController`にルーティングしたい場合は、以下のように`scope`ブロックでパスを指定できます。

```ruby
scope '/admin' do
  resources :articles, :comments
end
```

以下のように単数形ルーティングでもできます。

```ruby
resources :articles, path: '/admin/articles'
```

いずれの場合も、名前付きルーティング（named route）は、`scope`を使わなかった場合と同じになることにご注目ください。最後の例の場合は、以下のパスが`ArticlesController`に割り当てられます。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | --------------------- | ----------------- | ------------------- |
| GET       | /admin/articles          | articles#index       | articles_path          |
| GET       | /admin/articles/new      | articles#new         | new_article_path       |
| POST      | /admin/articles          | articles#create      | articles_path          |
| GET       | /admin/articles/:id      | articles#show        | article_path(:id)      |
| GET       | /admin/articles/:id/edit | articles#edit        | edit_article_path(:id) |
| PATCH/PUT | /admin/articles/:id      | articles#update      | article_path(:id)      |
| DELETE    | /admin/articles/:id      | articles#destroy     | article_path(:id)      |

TIP: `namespace`ブロックの内部で異なるコントローラ名前空間を使いたい場合、「`get '/foo', to: '/foo#index'`」のような絶対コントローラパスを指定することもできます。

[`namespace`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-namespace
[`scope`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-scope

### ネストしたリソース

他のリソースの配下に論理的な子リソースを配置することはよくあります。たとえば、Railsアプリケーションに以下のモデルがあるとします。

```ruby
class Magazine < ApplicationRecord
  has_many :ads
end

class Ad < ApplicationRecord
  belongs_to :magazine
end
```

ルーティングをネストする（入れ子にする）ことで、この親子関係をルーティングで表せるようになります。上の例の場合、以下のようにルーティングを宣言できます。

```ruby
resources :magazines do
  resources :ads
end
```

上のルーティングによって、雑誌（magazines）へのルーティングに加えて、広告（ads）を`AdsController`にもルーティングできるようになりました。adへのURLにはmagazineも必要です。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | ------------------------------------ | ----------------- | -------------------------------------------------------------------------- |
| GET       | /magazines/:magazine_id/ads          | ads#index         | ある雑誌1冊に含まれる広告をすべて表示する                          |
| GET       | /magazines/:magazine_id/ads/new      | ads#new           | ある1冊の雑誌用の広告を1つ作成するHTMLフォームを返す |
| POST      | /magazines/:magazine_id/ads          | ads#create        | ある1冊の雑誌用の広告を1つ作成する                           |
| GET       | /magazines/:magazine_id/ads/:id      | ads#show          | ある雑誌1冊に含まれる広告を1つ表示する                    |
| GET       | /magazines/:magazine_id/ads/:id/edit | ads#edit          | ある雑誌1冊に含まれる広告1つを編集するHTMLフォームを返す     |
| PATCH/PUT | /magazines/:magazine_id/ads/:id      | ads#update        | ある雑誌1冊に含まれる広告を1つ更新する                      |
| DELETE    | /magazines/:magazine_id/ads/:id      | ads#destroy       | ある雑誌1冊に含まれる広告を1つ削除する                      |

ルーティングを作成すると、ルーティングヘルパーも作成されます。ヘルパーは`magazine_ads_url`や`edit_magazine_ad_path`のような名前になります。これらのヘルパーは、最初のパラメータとしてMagazineモデルのインスタンスを1つ取ります（`magazine_ads_url(@magazine)`）。

#### ネスティング回数の上限

次のように、ネストしたリソースの中で別のリソースをネストできます。

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

ただしリソースのネストが深くなるとたちまち扱いにくくなります。たとえば、上のルーティングはアプリケーションで以下のようなパスとして認識されます。

```
/publishers/1/magazines/2/photos/3
```

このURLに対応するルーティングヘルパーは`publisher_magazine_photo_url`となります。このヘルパーを使うには、毎回3つの階層すべてでオブジェクトを指定する必要があります。ネスティングが深くなるとルーティングが扱いにくくなる問題については、Jamis Buckの有名な[記事](http://weblog.jamisbuck.org/2007/2/5/nesting-resources)を参照してください。JamisはRailsアプリケーション設計上の優れた経験則を提案しています。

TIP: **リソースのネスティングは、ぜひとも1回にとどめて下さい。決して2回以上ネストするべきではありません。**

#### 浅いネスト

前述したような深いネストを避ける１つの方法として、コレクション（`index/new/create`のような、idを持たないもの）のアクションだけを親のスコープの下で生成するという手法があります。このとき、メンバー（`show/edit/update/destroy`のような、idを必要とするもの）のアクションをネストに含めないようにするのがポイントです。これによりコレクションだけが階層化のメリットを受けられます。つまり、以下のように最小限の情報でリソースを一意に指定できるルーティングを作成するということです。

```ruby
resources :articles do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

この方法は、ルーティングの記述を複雑にせず、かつ深いネストを作らないという絶妙なバランスを保っています。`:shallow`オプションを使うことで、上と同じ内容をさらに簡単に記述できます。

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

この`articles`リソースでは以下のルーティングが生成されます。

| HTTP verb | パス             | コントローラ#アクション | 名前付きルーティングヘルパー         |
| --------- | -------------------------------------------- | ----------------- | ------------------------ |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path    |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path    |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path |
| GET       | /comments/:id/edit(.:format)                 | comments#edit     | edit_comment_path        |
| GET       | /comments/:id(.:format)                      | comments#show     | comment_path             |
| PATCH/PUT | /comments/:id(.:format)                      | comments#update   | comment_path             |
| DELETE    | /comments/:id(.:format)                      | comments#destroy  | comment_path             |
| GET       | /articles/:article_id/quotes(.:format)       | quotes#index      | article_quotes_path      |
| POST      | /articles/:article_id/quotes(.:format)       | quotes#create     | article_quotes_path      |
| GET       | /articles/:article_id/quotes/new(.:format)   | quotes#new        | new_article_quote_path   |
| GET       | /quotes/:id/edit(.:format)                   | quotes#edit       | edit_quote_path          |
| GET       | /quotes/:id(.:format)                        | quotes#show       | quote_path               |
| PATCH/PUT | /quotes/:id(.:format)                        | quotes#update     | quote_path               |
| DELETE    | /quotes/:id(.:format)                        | quotes#destroy    | quote_path               |
| GET       | /articles/:article_id/drafts(.:format)       | drafts#index      | article_drafts_path      |
| POST      | /articles/:article_id/drafts(.:format)       | drafts#create     | article_drafts_path      |
| GET       | /articles/:article_id/drafts/new(.:format)   | drafts#new        | new_article_draft_path   |
| GET       | /drafts/:id/edit(.:format)                   | drafts#edit       | edit_draft_path          |
| GET       | /drafts/:id(.:format)                        | drafts#show       | draft_path               |
| PATCH/PUT | /drafts/:id(.:format)                        | drafts#update     | draft_path               |
| DELETE    | /drafts/:id(.:format)                        | drafts#destroy    | draft_path               |
| GET       | /articles(.:format)                          | articles#index    | articles_path            |
| POST      | /articles(.:format)                          | articles#create   | articles_path            |
| GET       | /articles/new(.:format)                      | articles#new      | new_article_path         |
| GET       | /articles/:id/edit(.:format)                 | articles#edit     | edit_article_path        |
| GET       | /articles/:id(.:format)                      | articles#show     | article_path             |
| PATCH/PUT | /articles/:id(.:format)                      | articles#update   | article_path             |
| DELETE    | /articles/:id(.:format)                      | articles#destroy  | article_path             |


DSL（ドメイン固有言語）である[`shallow`][]メソッドをルーティングで使うと、すべてのネストが浅くなるように内側にスコープを1つ作成します。これによって生成されるルーティングは、最初の例と完全に同じです。

```ruby
shallow do
  resources :articles do
    resources :comments
    resources :quotes
    resources :drafts
  end
end
```

`scope`メソッドには、「浅い」ルーティングをカスタマイズするためのオプションが2つあります。`:shallow_path`オプションは、指定されたパラメータをメンバーのパスの冒頭に追加します。

```ruby
scope shallow_path: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上の場合、`comments`リソースのルーティングは以下のようになります。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | -------------------------------------------- | ----------------- | ------------------------ |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path    |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path    |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path |
| GET       | /sekret/comments/:id/edit(.:format)          | comments#edit     | edit_comment_path        |
| GET       | /sekret/comments/:id(.:format)               | comments#show     | comment_path             |
| PATCH/PUT | /sekret/comments/:id(.:format)               | comments#update   | comment_path             |
| DELETE    | /sekret/comments/:id(.:format)               | comments#destroy  | comment_path             |

`:shallow_prefix`オプションを使うと、指定されたパラメータを（パスではなく）名前付きルーティングヘルパー名の冒頭に追加します。

```ruby
scope shallow_prefix: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上の場合、`comments`リソースのルーティングは以下のようになります。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | -------------------------------------------- | ----------------- | --------------------------- |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path       |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path       |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path    |
| GET       | /comments/:id/edit(.:format)                 | comments#edit     | edit_sekret_comment_path    |
| GET       | /comments/:id(.:format)                      | comments#show     | sekret_comment_path         |
| PATCH/PUT | /comments/:id(.:format)                      | comments#update   | sekret_comment_path         |
| DELETE    | /comments/:id(.:format)                      | comments#destroy  | sekret_comment_path         |

[`shallow`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-shallow

### ルーティングの「concern」機能

concern（関心）を使うことで、他のリソースやルーティング内で使いまわせる共通のルーティングを宣言できます。concernは以下のように[`concern`][]ブロックで定義します。

```ruby
concern :commentable do
  resources :comments
end

concern :image_attachable do
  resources :images, only: :index
end
```

concernを利用すると、同じようなルーティングを繰り返し記述せずに済み、複数のルーティング間で同じ振る舞いを共有できます。

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

複数形の[`concerns`][]呼び出しはルーティング内のどの場所にでも配置できます。`scope`や`namespace`ブロックでは以下のように利用できます。

```ruby
namespace :articles do
  concerns :commentable
end
```

[`concern`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Concerns.html#method-i-concern
[`concerns`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Concerns.html#method-i-concerns

### オブジェクトからパスとURLを作成する

ルーティングヘルパーを使う方法の他に、パラメータの配列からパスやURLを作成することもできます。例として、以下のようなルーティングがあるとします。

```ruby
resources :magazines do
  resources :ads
end
```

`magazine_ad_path`を使うと、idを数字で渡す代わりに`Magazine`と`Ad`のインスタンスを引数として渡せます。

```erb
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

複数のオブジェクトが集まったセットに対して[`url_for`][ActionView::RoutingUrlFor#url_for]を使うこともできます。複数のオブジェクトを渡しても、適切なルーティングが自動的に決定されます。

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

上の場合、Railsは`@magazine`が`Magazine`であり、`@ad`が`Ad`であることを認識し、それに基づいて`magazine_ad_path`ヘルパーを呼び出します。`link_to`などのヘルパーでも、完全な`url_for`呼び出しの代わりに単にオブジェクトを渡せます。

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

1冊の雑誌にだけリンクしたい場合は、以下のように書きます。

```erb
<%= link_to 'Magazine details', @magazine %>
```

それ以外のアクションについては、配列の最初の要素にアクション名を挿入するだけで済みます。

```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

これにより、モデルのインスタンスをURLとして扱えるようになります。これはリソースフルなスタイルを採用する大きなメリットの1つです。

[ActionView::RoutingUrlFor#url_for]: https://api.rubyonrails.org/classes/ActionView/RoutingUrlFor.html#method-i-url_for

### RESTfulなアクションをさらに追加する

デフォルトで作成されるRESTfulなルーティングは7つですが、7つと決まっているわけではありません。必要であれば、コレクションやコレクションの各メンバーに対して適用されるリソースを追加することも可能です。

#### メンバールーティングを追加する

メンバー（member）ルーティングを追加したい場合は、[`member`][]ブロックをリソースブロックに1つ追加します。

```ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

上のルーティングはGETリクエストとそれに伴う`/photos/1/preview`を認識し、リクエストを`Photos`コントローラの`preview`アクションにルーティングし、リソースid値を`params[:id]`に渡します。同時に、`preview_photo_url`ヘルパーと`preview_photo_path`ヘルパーも作成されます。

memberルーティングブロックの内側では、認識させるHTTP verbをルーティング名ごとに指定します。指定可能なHTTP verbは[`get`][]、[`patch`][]、[`put`][]、[`post`][]、[`delete`][]です。`member`ルーティングが1つしかない場合は、以下のようにルーティングで`:on`オプションを指定することでブロックを省略できます。

```ruby
resources :photos do
  get 'preview', on: :member
end
```

`:on`オプションを省略しても同様のmemberルーティングが生成されます。この場合リソースidの値の取得に`params[:id]`ではなく`params[:photo_id]`を使う点が異なります。ルーティングヘルパーも、`preview_photo_url`が`photo_preview_url`に、`preview_photo_path`が`photo_preview_path`にそれぞれリネームされます。

[`delete`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-delete
[`get`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-get
[`member`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-member
[`patch`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-patch
[`post`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-post
[`put`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-put
[`put`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/HttpHelpers.html#method-i-put

#### コレクションルーティングを追加する

ルーティングにコレクション（collection）を追加するには以下のように[`collection`][]ブロックを使います。

```ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

上のルーティングは、GETリクエスト + `/photos/search`などの（idを伴わない）パスを認識し、リクエストを`Photos`コントローラの`search`アクションにルーティングします。このとき`search_photos_url`や`search_photos_path`ルーティングヘルパーも同時に作成されます。

collectionルーティングでもmemberルーティングのときと同様に`:on`オプションを使えます。

```ruby
resources :photos do
  get 'search', on: :collection
end
```

NOTE: 追加のresourceルーティングをシンボルで第1引数として定義する場合は、文字列で定義した場合と振る舞いが同等ではなくなる点にご注意ください。文字列はパスとして推測されますが、シンボルはコントローラのアクションとして推測されます。

[`collection`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-collection

#### 追加されたnewアクションへのルーティングを追加する

`:on`オプションを使って、たとえば以下のように別のnewアクションを追加できます。

```ruby
resources :comments do
  get 'preview', on: :new
end
```

上のようにすることで、GET + `/comments/new/preview`のようなパスが認識され、`Comments`コントローラの`preview`アクションにルーティングされます。`preview_new_comment_url`や`preview_new_comment_path`ルーティングヘルパーも同時に作成されます。

TIP: リソースフルなルーティングにアクションが多数追加されていることに気付いたら、それ以上アクションを追加するのをやめて、そこに別のリソースが隠されているのではないかと疑ってみる方がよいでしょう。

リソースフルでないルーティング
----------------------

Railsではリソースルーティングを行なう他に、任意のURLをアクションにルーティングすることもできます。この方式を使う場合、リソースフルルーティングのような自動的なルーティンググループの生成は行われません。従って、アプリケーションで必要なルーティングを個別に設定することになります。

基本的にはリソースフルルーティングを使うべきではありますが、このような単純なルーティングの方が適している箇所も多数あるはずです。リソースフルルーティングでは大袈裟すぎる場合に、アプリケーションを無理にリソースフルなフレームワークに押し込める必要はありません。

シンプルなルーティングは、特に従来形式のURLを新しいRailsのアクションに割り当てる場合にはるかに簡単に行えるようになります。

### パラメータの割り当て

通常のルーティングを設定する場合は、RailsがルーティングをブラウザからのHTTPリクエストに割り当てるためのシンボルをいくつか渡します。以下のルーティングを例にとってみましょう。

```ruby
get 'photos(/:id)', to: 'photos#display'
```

ブラウザからの`/photos/1`リクエストが上のルーティングで処理される（ファイル内でそれより上の行のルーティング設定にはマッチしなかったとします）と、`PhotosController`の`display`アクションが呼び出され、URL末尾のパラメータ`"1"`へのアクセスは`params[:id]`で行なえます。`:id`が必須パラメータではないことが丸かっこ`()`で示されているので、このルーティングは`/photos`を`PhotosController#display`にルーティングすることもできます。

### 動的なセグメント

通常のルーティングの一部として、文字列を固定しない動的なセグメントを自由に使えます。あらゆるセグメントは`params`の一部に含めてアクションに渡せます。以下のルーティングを設定したとします。

```ruby
get 'photos/:id/:user_id', to: 'photos#show'
```

ブラウザからの`/photos/1/2`パスは`PhotosController`の`show`アクションに割り当てられます。`params[:id]`には`"1"`、`params[:user_id]`には`"2"`がそれぞれ保存されます。

TIP: デフォルトでは動的なセグメント分割にドット`.`を渡せません。ドットはフォーマット済みルーティングでは区切り文字として使われるためです。どうしても動的セグメント内でドットを使いたい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使えます。

### 静的なセグメント

ルーティング作成時にコロンを付けなかった部分は、静的なセグメントとして固定文字列が指定されます。

```ruby
get 'photos/:id/with_user/:user_id', to: 'photos#show'
```

上のルーティングは、`/photos/1/with_user/2`のようなパスにマッチします。このときアクションで使える`params`は `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### クエリ文字列

クエリ文字列（訳注: URLの末尾に`?パラメータ名=値`の形式で置かれるパラメータ）で指定されているパラメータもすべて`params`に含まれます。以下のルーティングを例にとってみましょう。

```ruby
get 'photos/:id', to: 'photos#show'
```

ブラウザからのリクエストで`/photos/1?user_id=2`というパスが渡されると、`Photos`コントローラの`show`アクションに割り当てられます。このときの`params`は`{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### デフォルト設定を定義する

`:defaults`オプションにハッシュを1つ渡すことで、ルーティング内にデフォルト値を定義できます。このとき、動的なセグメントとして指定する必要のないパラメータを次のように適用することも可能です。

```ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

上のルーティングはブラウザからの`/photos/12`パスにマッチし、`Photos`コントローラの`show`アクションに割り当てられます。`params[:format]`は`"jpg"`に設定されます。

ブロック形式の[`defaults`][]を使うと、複数の項目についてデフォルト値を設定することもできます。

```ruby
defaults format: :json do
  resources :photos
end
```

NOTE: セキュリティ上の理由により、クエリパラメータでデフォルト値をオーバーライドすることはできません。オーバーライド可能なデフォルト値は、URLパスの置き換えによる動的なセグメントのみです。

[`defaults`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-defaults

### 名前付きルーティング

`:as`オプションを使うと、任意のルーティングに名前を指定できます。

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

上のルーティングでは`logout_path`と`logout_url`がアプリケーションの名前付きルーティングヘルパーとして作成されます。`logout_path`を呼び出すと`/exit`が返されます。

この方法を使って、リソースを定義する前にカスタムルーティングを配置することで、リソースで定義されたルーティングメソッドをオーバーライドすることも可能です。

```ruby
get ':username', to: 'users#show', as: :user
resources :users
```

上のルーティングでは`user_path`メソッドが生成され、コントローラ・ヘルパー・ビューでそれぞれ使えるようになります。このメソッドは、`/bob`のようなユーザー名を持つルーティングに移動します。`Users`コントローラの`show`アクションの内部で`params[:username]`にアクセスすると、ユーザー名を取り出せます。パラメータ名を`:username`にしたくない場合は、ルーティング定義の`:username`の部分を変更してください。

### HTTP verbを制限する

あるルーティングを特定のHTTP verbに割り当てるために、通常は[`get`][]、[`patch`][]、[`put`][]、[`post`][]、[`delete`][]メソッドのいずれかを使う必要があります。[`match`][]メソッドと`:via`オプションを使うことで、複数のHTTP verbに同時にマッチするルーティングを作成できます。

```ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

`via: :all`を指定すると、すべてのHTTP verbにマッチする特別なルーティングを作成できます。

```ruby
match 'photos', to: 'photos#show', via: :all
```

NOTE: 1つのアクションに`GET`リクエストと`POST`リクエストを両方ルーティングすると、セキュリティに影響する可能性があります。どうしても必要な理由がない限り、1つのアクションにすべてのHTTP verbをルーティングしないでください。

NOTE: Railsでは`GET`のCSRFトークンをチェックしません。決して`GET`リクエストでデータベースに書き込んではいけません。詳しくは[セキュリティガイド](security.html#csrfへの対応策)のCSRF対策を参照してください。

[`match`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Base.html#method-i-match

### セグメントを制限する

`:constraints`オプションを使って、動的セグメントのURLフォーマットを特定の形式に制限できます。

```ruby
get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }
```

上のルーティングは`/photos/A12345`のようなパスにはマッチしますが、`/photos/893`にはマッチしません。以下のようにもっと簡潔な方法でも記述できます。

```ruby
get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/
```

`:constraints`では正規表現を使えますが、ここでは正規表現の「アンカー（`^`や`$`など）」は使えないという制限があることにご注意ください。たとえば、以下のルーティングは無効です。

```ruby
get '/:id', to: 'articles#show', constraints: { id: /^\d/ }
```

対象となるすべてのルーティングは冒頭と末尾がアンカーされているので、このようなアンカー表現を使う必要はないはずです。

たとえば以下のルーティングでは、ルート（root）名前空間を共有する際に`articles`の`to_param`では`1-hello-world`のように数字で始まる値だけが使えるようになっており、`users`の`to_param`では`david`のように数字で始まらない値だけが使えるようになっています。

```ruby
get '/:id', to: 'articles#show', constraints: { id: /\d.+/ }
get '/:username', to: 'users#show'
```

### リクエスト内容に応じて制限を加える

また、`String`を返す[Requestオブジェクト](action_controller_overview.html#requestオブジェクト)の任意のメソッドに基いてルーティングを制限することもできます。

リクエストに応じた制限は、セグメントを制限するときと同様の方法で指定できます。

```ruby
get 'photos', to: 'photos#index', constraints: { subdomain: 'admin' }
```

[`constraints`][]ブロックで制限を指定することもできます。

```ruby
namespace :admin do
  constraints subdomain: 'admin' do
    resources :photos
  end
end
```

NOTE: リクエストベースの制限は、[Requestオブジェクト](action_controller_overview.html#requestオブジェクト)に対してあるメソッドを呼び出すことで実行されます。ハッシュキーと同じ名前のメソッドを呼び出し、返された値をハッシュの値と比較します。従って、制限された値は、対応するRequestオブジェクトのメソッドが返す型と一致する必要があります。たとえば、`constraints: { subdomain: 'api' }`という制限は`api`サブドメインに期待どおりマッチしますが、`constraints: { subdomain: :api }`のようにシンボルを使った場合は`api`サブドメインに一致しません。`request.subdomain`が返す`'api'`は文字列型であるためです。

NOTE: `format`の制限には例外があります。これはRequestオブジェクトのメソッドですが、すべてのパスに含まれる暗黙的なオプションのパラメータでもあります。`format`の制限よりセグメント制限が優先されます。たとえば、`get 'foo'、constraints: { format： 'json' }`は`GET /foo`と一致します。これはデフォルトで`format`がオプションであるためです。しかし、次のように[lambdaを使う](#高度な制限)ことが可能です。`get 'foo', constraints: lambda { |req| req.format == :json }` というルーティング指定は明示的なJSONリクエストにのみ一致します。

[`constraints`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-constraints

### 高度な制限

より高度な制限を使いたい場合、Railsで必要な`matches?`に応答できるオブジェクトを渡す方法があります。例として、制限リストに記載されているすべてのユーザーを`RestrictedListController`にルーティングしたいとします。この場合、以下のように設定します。

```ruby
class RestrictedListConstraint
  def initialize
    @ips = RestrictedList.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end

Rails.application.routes.draw do
  get '*path', to: 'restricted_list#index',
    constraints: RestrictedListConstraint.new
end
```

制限をlambdaとして指定することもできます。

```ruby
Rails.application.routes.draw do
  get '*path', to: 'restricted_list#index',
    constraints: lambda { |request| RestrictedList.retrieve_ips.include?(request.remote_ip) }
end
```

`matches?`メソッドおよびlambdaはいずれも引数として`request`オブジェクトを受け取ります。

### ルーティンググロブとワイルドカードセグメント

ルーティンググロブ（route globbing）とはワイルドカード（`*`）展開のことであり、以下のようにルーティングのある位置から下のすべての部分に特定のパラメータをマッチさせるときに使います。

```ruby
get 'photos/*other', to: 'photos#unknown'
```

上のルーティングは`photos/12`や`/photos/long/path/to/12`（`long/path/to`は長いパス）にマッチし、`params[:other]`には`"12"`や`"long/path/to/12"`が設定されます。冒頭にアスタリスク`*`が付いているセグメントを「ワイルドカードセグメント」と呼びます。

ワイルドカードセグメントは、以下のようにルーティングのどの部分でも使えます。

```ruby
get 'books/*section/:title', to: 'books#show'
```

上は`books/some/section/last-words-a-memoir`にマッチし、`params[:section]`には`'some/section'`が保存され、`params[:title]`には`'last-words-a-memoir'`が保存されます。

技術上は、1つのルーティングに2つ以上のワイルドカードセグメントを含めることは可能です。マッチャがセグメントをパラメータに割り当てる方法は、以下のように直感的です。

```ruby
get '*a/foo/*b', to: 'test#index'
```

上のルーティングは`zoo/woo/foo/bar/baz`にマッチし、`params[:a]`には`'zoo/woo'`が保存され、`params[:b]`には`'bar/baz'`が保存されます。

NOTE: `'/foo/bar.json'`をリクエストすると`params[:pages]`には`'foo/bar'`がJSONリクエストフォーマットで保存されます。Rails 3.0.xの動作に戻したい場合は、以下のように`format: false`を指定できます。

```ruby
get '*pages', to: 'pages#show', format: false
```

NOTE: このセグメントフォーマットを必須にしたい場合は、以下のように`format: true`を指定します。

```ruby
get '*pages', to: 'pages#show', format: true
```

### リダイレクト

ルーティングで[`redirect`][]を使うと、任意のパスを他のパスにリダイレクトできます。

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

デフォルトのリダイレクトは、HTTPステータス「301 "Moved Permanently"」のリダイレクトになる点にご注意ください。一部のWebブラウザやプロキシサーバーはこの種のリダイレクトをキャッシュすることがあり、その場合リダイレクト前の古いページにはアクセスできなくなります。次のように`:status`オプションを使うことでレスポンスのステータスを変更できます。

```ruby
get '/stories/:name', to: redirect('/articles/%{name}', status: 302)
```

どの場合であっても、ホスト（`http://www.example.com`など）がURLの冒頭で指定されていない場合は、Railsは（以前のリクエストではなく）現在のリクエストから詳細を取得します。

[`redirect`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Redirection.html#method-i-redirect

### Rackアプリケーションにルーティングする

`Post`コントローラの`index`アクションに対応する`'articles#index'`のような文字列の代わりに、任意の[Rackアプリケーション](rails_on_rack.html)をマッチャーのエンドポイントとして指定できます。

```ruby
match '/application.js', to: MyRackApp, via: :all
```

Railsルーターから見れば、`MyRackApp`が`call`に応答して`[status, headers, body]`を返す限り、ルーティング先がRackアプリケーションであるかアクションであるかを区別しません。これによって、適切と考えられるすべてのHTTP verbをRackアプリケーションで扱えるようになるので、これは`via: :all`の適切な利用法です。

NOTE: 参考までに、`'articles#index'`は実際には`ArticlesController.action(:index)`という形に展開されます。これは有効なRackアプリケーションを返します。

NOTE: procやlambdaは`call`に応答するオブジェクトなので、たとえばヘルスチェックで用いるルーティングを以下のように極めてシンプルにインライン実装できます。 <br>`get '/health', to: ->(env) { [204, {}, ['']] }`

Rackアプリケーションをマッチャーのエンドポイントとして指定すると、それを受け取るRackアプリケーションのルーティングは変更されない点にご留意ください。以下のルーティングでは、Rackアプリケーションは`/admin`へのルーティングを期待するべきです。

```ruby
 match '/admin', to: AdminApp, via: :all
```

Rackアプリケーションがrootパスでリクエストを受け取るようにしたい場合は、[`mount`][]を使います。

```ruby
 mount AdminApp, at: '/admin'
```

[`mount`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Base.html#method-i-mount

### `root`を使う

[`root`][]メソッドを使うことで、`'/'`によるルーティング先を指定できます。

```ruby
root to: 'pages#main'
root 'pages#main' # 上の省略形
```

`root`ルーティングは、ルーティングファイルの冒頭に記述してください。rootは最もよく使われるルーティングであり、最初にマッチする必要があるからです。

NOTE: `root`ルーティングがアクションに渡せるのは`GET`リクエストだけです。

以下のように、名前空間やスコープの内側でもrootを指定できます。

```ruby
namespace :admin do
  root to: "admin#index"
end

root to: "home#index"
```

[`root`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-root

### Unicode文字列をルーティングで使う

Unicode文字列を以下のようにルーティングで直接使うこともできます。

```ruby
get 'こんにちは', to: 'welcome#index'
```

### ダイレクトルーティング（Direct routes）

[`direct`][]を呼び出すことで、カスタムURLヘルパーを次のように作成できます。

```ruby
direct :homepage do
  "http://www.rubyonrails.org"
end

# >> homepage_url
# => "http://www.rubyonrails.org"
```

このブロックの戻り値は、必ず`url_for`メソッドで有効な1個の引数にならなければなりません。これによって、有効な「文字列URL」「ハッシュ」「配列」「Active Modelインスタンス」「Active Modelクラス」のいずれか1つを渡せるようになります。


```ruby
direct :commentable do |model|
  [ model, anchor: model.dom_id ]
end

direct :main do
  { controller: 'pages', action: 'index', subdomain: 'www' }
end
```

[`direct`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/CustomUrls.html#method-i-direct

### `resolve`を使う

[`resolve`][]メソッドを使うと、モデルのポリモーフィックなマッピングを次のようにカスタマイズできます。

```ruby
resource :basket

resolve("Basket") { [:basket] }
```

```erb
<%= form_with model: @basket do |form| %>
  <!-- basket form -->
<% end %>
```

上のコードは、通常の`/baskets/:id`ではなく、単数形の`/basket`というURLを生成します。

[`resolve`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/CustomUrls.html#method-i-resolve

リソースフルルーティングをカスタマイズする
------------------------------

ほとんどの場合、[`resources`][]で生成されるデフォルトのルーティングやヘルパーで用は足りますが、もう少しルーティングをカスタマイズしたくなることもあります。Railsでは、リソースフルなヘルパーの一般的などの部分であっても事実上自由にカスタマイズ可能です。

### 利用するコントローラを指定する

`:controller`オプションは、リソースで使うコントローラを以下のように明示的に指定します。

```ruby
resources :photos, controller: 'images'
```

上のルーティングは、`/photos`で始まるパスを認識しますが、ルーティング先を`Images`コントローラにします。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | images#index      | photos_path          |
| GET       | /photos/new      | images#new        | new_photo_path       |
| POST      | /photos          | images#create     | photos_path          |
| GET       | /photos/:id      | images#show       | photo_path(:id)      |
| GET       | /photos/:id/edit | images#edit       | edit_photo_path(:id) |
| PATCH/PUT | /photos/:id      | images#update     | photo_path(:id)      |
| DELETE    | /photos/:id      | images#destroy    | photo_path(:id)      |

NOTE: このリソースへのパスを生成するには`photos_path`や`new_photo_path`などをお使いください。

名前空間内のコントローラは以下のように直接指定できます。

```ruby
resources :user_permissions, controller: 'admin/user_permissions'
```

上は`Admin::UserPermissions`にルーティングされます。

NOTE: ここでサポートされている記法は、`/`で区切る「ディレクトリ記法」のみです。Rubyの定数表記法（`controller: 'Admin::UserPermissions'`など）をコントローラに対して使うと、ルーティングで問題が生じ、警告が出力される可能性があります。

### 制限を指定する

`:constraints`オプションを使うと、暗黙で使われる`id`に対して以下のように必須のフォーマットを指定できます。

```ruby
resources :photos, constraints: { id: /[A-Z][A-Z][0-9]+/ }
```

上の宣言は`:id`パラメータに制限を加え、指定した正規表現にのみマッチするようにします。従って、上の例では`/photos/1`のようなパスにはマッチしなくなり、代わりに`/photos/RR27`のようなパスにマッチするようになります。

以下のようにブロック形式を使うことで、1つの制限を多数のルーティングに対してまとめて指定することも可能です。

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: もちろん、このコンテキストでは「リソースフルでない」ルーティングに適用可能な、より高度な制限を加えることもできます。

TIP: デフォルトでは`:id`パラメータにドット`.`を渡せません。ドットはフォーマット済みルーティングでは区切り文字として使われるためです。どうしても`:id`内でドットを使いたい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使えます。

### 名前付きルーティングヘルパーをオーバーライドする

`:as`オプションを使うと、名前付きルーティングヘルパーを以下のように上書きしてルーティングヘルパー名を変えられます。

```ruby
resources :photos, as: 'images'
```

上のルーティングでは、`/photos`で始まるブラウザからのパスを認識し、このリクエストを`Photos`コントローラにルーティングしますが、ヘルパーの命名には`:as`オプションの値が使われます。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | photos#index      | images_path          |
| GET       | /photos/new      | photos#new        | new_image_path       |
| POST      | /photos          | photos#create     | images_path          |
| GET       | /photos/:id      | photos#show       | image_path(:id)      |
| GET       | /photos/:id/edit | photos#edit       | edit_image_path(:id) |
| PATCH/PUT | /photos/:id      | photos#update     | image_path(:id)      |
| DELETE    | /photos/:id      | photos#destroy    | image_path(:id)      |

### `new`セグメントや`edit`セグメントをオーバーライドする

`:path_names`オプションを使うと、パスに含まれている、自動生成された"new"セグメントや"edit"セグメントをオーバーライドできます。

```ruby
resources :photos, path_names: { new: 'make', edit: 'change' }
```

これにより、ルーティングで以下のようなパスが認識できるようになります。

```
/photos/make
/photos/1/change
```

NOTE: このオプションを指定しても、実際のアクション名が変更されるわけではありません。変更後のパスを使っても、ルーティング先は依然として`new`アクションと`edit`アクションのままです。

TIP: このオプションによる変更をすべてのルーティングに統一的に適用したい場合は、スコープを使えます。

```ruby
scope path_names: { new: 'make' } do
  # 残りすべてのルーティング
end
```

### 名前付きルーティングヘルパーにプレフィックスを追加する

以下のように`:as`オプションを使うことで、Railsがルーティングに対して生成する名前付きルーティングヘルパー名の冒頭に文字を追加できます（プレフィックス）。パススコープを使うルーティング同士での名前の衝突を避けたい場合にお使いください。

```ruby
scope 'admin' do
  resources :photos, as: 'admin_photos'
end

resources :photos
```

上のルーティングでは、`admin_photos_path`や`new_admin_photo_path`などのルーティングヘルパーが生成されます。

ルーティングヘルパーのグループにまとめてプレフィックスを追加するには、以下のように`scope`メソッドで`:as`オプションを使います。

```ruby
scope 'admin', as: 'admin' do
  resources :photos, :accounts
end

resources :photos, :accounts
```

上によって、`admin_photos_path`と`admin_accounts_path`などのルーティングが生成されます。これらは`/admin/photos`と`/admin/accounts`にそれぞれ割り当てられます。

NOTE: `namespace`スコープを使うと、`:module`や`:path`プレフィックスに加えて`:as`も自動的に追加されます。

#### パラメトリックスコープ

名前付きパラメータを持つルーティングにプレフィックスを追加できます。

```ruby
scope ':account_id', as: 'account', constraints: { account_id: /\d+/ } do
  resources :articles
end
```

上のルーティングは`/1/articles/9`のようなパスを提供します。パスの`account_id`部分を`params[:account_id]`の形でコントローラ、ヘルパー、ビューで参照できるようになります。

また、`account_`をプレフィックスとするパスヘルパーやURLヘルパーも生成され、これらにオブジェクトを渡すこともできます。

```ruby
account_article_path(@account, @article) # => /1/article/9
url_for([@account, @article])            # => /1/article/9
form_with(model: [@account, @article])   # => <form action="/1/article/9" ...>
```

[セグメントの制限](#セグメントを制限する)を用いて、IDのような文字列にのみマッチするようにスコープを制限しています。この制限は、必要に応じて変更することも完全に省略することも可能です。`as`オプションも厳密には必須ではありませんが、これがないと`url_for([@account, @article])`や [`form_with`][]のような`url_for`に依存するヘルパーの評価時にエラーが発生します。

[`form_with`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with

### 作成されるルーティングを制限する

Railsは、アプリケーション内のすべてのRESTfulルーティングに対してデフォルトで7つのアクション（`index`、`show`、`new`、`create`、`edit`、`update`、`destroy`）へのルーティングを作成します。この振る舞いは、`:only`オプションや`:except`オプションで微調整できます。

`:only`オプションは、指定したルーティングだけを生成するよう指示します。

```ruby
resources :photos, only: [:index, :show]
```

これで、`/photos`への`GET`リクエストは成功し、`/photos` への`POST`リクエスト（通常は`create`アクションにルーティングされる）は失敗します。

`:except`オプションは逆に、生成**しない**ルーティング（またはルーティングのリスト）を指定します。

```ruby
resources :photos, except: :destroy
```

この場合、`destroy`（`/photos/:id`への`DELETE`リクエスト）を除いた通常のルーティングが生成されます。

TIP: アプリケーションでRESTfulルーティングが多数使われている場合は、それらに適宜`:only`や`:except`を使って、本当に必要なルーティングのみを生成することで、メモリ使用量の節約とルーティング処理の速度向上が見込めます。

### パスを変更する

`scope`メソッドを使うことで、`resources`によって生成されるデフォルトのパス名を変更できます。

```ruby
scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
  resources :categories, path: 'kategorien'
end
```

上のようにすることで、以下のような`Categories`コントローラへのルーティングが作成されます。

| HTTP verb  | パス | コントローラ#アクション | 名前付きルーティングヘルパー |
| --------- | -------------------------- | ------------------ | ----------------------- |
| GET       | /kategorien                | categories#index   | categories_path         |
| GET       | /kategorien/neu            | categories#new     | new_category_path       |
| POST      | /kategorien                | categories#create  | categories_path         |
| GET       | /kategorien/:id            | categories#show    | category_path(:id)      |
| GET       | /kategorien/:id/bearbeiten | categories#edit    | edit_category_path(:id) |
| PATCH/PUT | /kategorien/:id            | categories#update  | category_path(:id)      |
| DELETE    | /kategorien/:id            | categories#destroy | category_path(:id)      |

### 単数形の名前をオーバーライドする

単数形リソースの名前をオーバーライドしたい場合、以下のように[`inflections`][]で活用形ルールを追加します。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tooth', 'teeth'
end
```

[`inflections`]: https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-inflections

### ネストしたリソースで`:as`を使う

`:as`を使うと、ネストしたルーティングヘルパー内のリソース用に自動生成された名前を以下のようにオーバーライドできます。

```ruby
resources :magazines do
  resources :ads, as: 'periodical_ads'
end
```

上のルーティングによって、`magazine_periodical_ads_url`や`edit_magazine_periodical_ad_path`などのルーティングヘルパーが生成されます。

### 名前付きルーティングのパラメータをオーバーライドする

`:param`オプションは、デフォルトのリソース識別子`:id` (ルーティングの生成に使われる[動的なセグメント](routing.html#動的なセグメント)の名前) をオーバーライドします。`params[<:パラメータ>]`を使って、コントローラからそのセグメントにアクセスできます。

```ruby
resources :videos, param: :identifier
```

```
    videos GET  /videos(.:format)                  videos#index
           POST /videos(.:format)                  videos#create
 new_video GET  /videos/new(.:format)              videos#new
edit_video GET  /videos/:identifier/edit(.:format) videos#edit
```

```ruby
Video.find_by(identifier: params[:identifier])
```

関連するモデルの `ActiveRecord::Base#to_param` をオーバーライドしてURLを作成できます。

```ruby
class Video < ApplicationRecord
  def to_param
    identifier
  end
end
```

```ruby
video = Video.find_by(identifier: "Roman-Holiday")
edit_video_path(video) # => "/videos/Roman-Holiday/edit"
```

巨大なルーティングファイルを分割する
-------------------------------------------------------

ルーティングが数千にもおよび大規模アプリケーションでは、複雑な`config/routes.rb`ファイル1個だけでは読みづらくなります。

Railsでは、このような巨大`routes.rb`ファイルを[`draw`][]マクロで小さなルーティングファイルに分割する方法が提供されています。

たとえば`admin.rb`にはadmin関連のルーティングをすべて含め、API関連リソースのルーティングは`api.rb`ファイルで記述するといったことが可能です。

```ruby
# config/routes.rb

Rails.application.routes.draw do
  get 'foo', to: 'foo#bar'

  draw(:admin) # `config/routes/admin.rb`にある別のルーティングファイルを読み込む
end
```

```ruby
# config/routes/admin.rb

namespace :admin do
  resources :comments
end
```

`Rails.application.routes.draw`自身の中で`draw(:admin)`を呼び出すと、指定の引数と同じ名前のルーティングファイル（この例では`admin.rb`）の読み込みを試行します。
このファイルは、`config/routes`ディレクトリの下か、任意のサブディレクトリ（`config/routes/admin.rb`や`config/routes/external/admin.rb`など）に存在する必要があります。

`admin.rb`ルーティングファイル内でも通常のルーティングDSLを利用できますが、メインの`config/routes.rb`ファイルのような`Rails.application.routes.draw`ブロックで囲んでは**いけません**。

[`draw`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-draw

### 本当に必要になるまでは分割しないこと

ルーティングファイルを複数に分けると、ルーティングを探すのも理解するのも難しくなります。ほとんどのアプリケーションでは、たとえルーティングが数百個になっていたとしても、ルーティングファイルを1つのままにしておくほうが開発者にとっては楽です。Railsのルーティングには、`namespace`や`scope`を用いてルーティングを分割整理する方法が既に用意されています。

ルーティングの調査とテスト
-----------------------------

Railsには、ルーティングを調べる機能（inspection）とテスト機能が備わっています。

### 既存のルールを一覧表示する

現在のアプリケーションで利用可能なルーティングをすべて表示するには、サーバーが**development**環境で動作している状態で`http://localhost:3000/rails/info/routes`をブラウザで開きます。ターミナルで`bin/rails routes`コマンドを実行しても同じ結果を得られます。

どちらの方法を使った場合でも、`config/routes.rb`ファイルに記載された順にルーティングが表示されます。1つのルーティングについて以下の情報が表示されます。

* ルーティング名（あれば）
* 使われるHTTP verb（そのルーティングが一部のHTTP verbに応答しない場合）
* マッチするURLパターン
* そのルーティングで使うパラメータ

以下は、あるRESTfulルーティングに対して`bin/rails routes`を実行した結果から抜粋したものです。

```
    users GET    /users(.:format)          users#index
          POST   /users(.:format)          users#create
 new_user GET    /users/new(.:format)      users#new
edit_user GET    /users/:id/edit(.:format) users#edit
```

`--expanded`オプションを用いて、ルーティングテーブルのフォーマットを以下のような詳細モードに切り替えることもできます。

```bash
$ bin/rails routes --expanded

--[ Route 1 ]----------------------------------------------------
Prefix            | users
Verb              | GET
URI               | /users(.:format)
Controller#Action | users#index
--[ Route 2 ]----------------------------------------------------
Prefix            |
Verb              | POST
URI               | /users(.:format)
Controller#Action | users#create
--[ Route 3 ]----------------------------------------------------
Prefix            | new_user
Verb              | GET
URI               | /users/new(.:format)
Controller#Action | users#new
--[ Route 4 ]----------------------------------------------------
Prefix            | edit_user
Verb              | GET
URI               | /users/:id/edit(.:format)
Controller#Action | users#edit
```

`-g`（grepオプション）でルーティングを絞り込めます。URLヘルパー名、HTTP verb、URLパスのいずれかに部分マッチするルーティングが出力されます。

```bash
$ bin/rails routes -g new_comment
$ bin/rails routes -g POST
$ bin/rails routes -g admin
```

特定のコントローラに対応するルーティングだけを表示したい場合は、`-c`オプションを使います。

```bash
$ bin/rails routes -c users
$ bin/rails routes -c admin/users
$ bin/rails routes -c Comments
$ bin/rails routes -c Articles::CommentsController
```

TIP: テキストの折り返しが発生しないぐらいに十分大きなターミナル画面では、おそらく`bin/rails routes`コマンド出力の方が読みやすいでしょう。

### ルーティングをテストする

アプリケーションの他の部分と同様、ルーティング部分もテスト戦略に含めておくべきでしょう。Railsでは、テストを楽にするために3つの組み込みアサーションが用意されています。

* [`assert_generates`][]
* [`assert_recognizes`][]
* [`assert_routing`][]

[`assert_generates`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_generates
[`assert_recognizes`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_recognizes
[`assert_routing`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_routing

#### `assert_generates`アサーション

[`assert_generates`][]は、特定のオプションの組み合わせを使った場合に特定のパスが生成されること、そしてそれらがデフォルトのルーティングでもカスタムルーティングでも使えることをテストするアサーション（assertion: 主張）です。

```ruby
assert_generates '/photos/1', { controller: 'photos', action: 'show', id: '1' }
assert_generates '/about', controller: 'pages', action: 'about'
```

#### `assert_recognizes`アサーション

[`assert_recognizes`][]は`assert_generates`と逆方向のテスティングを行います。与えられたパスが認識可能であること、アプリケーションの特定の場所にルーティングされることをテストするアサーションです。

```ruby
assert_recognizes({ controller: 'photos', action: 'show', id: '1' }, '/photos/1')
```

`:method`引数でHTTP verbを指定することもできます。

```ruby
assert_recognizes({ controller: 'photos', action: 'create' }, { path: 'photos', method: :post })
```

#### `assert_routing`アサーション

[`assert_routing`][]アサーションは、ルーティングを2つの観点（与えられたパスによってオプションが生成されること、そのオプションによって元のパスが生成されること）からチェックします。つまり、`assert_generates`と`assert_recognizes`の機能を組み合わせたものになります。

```ruby
assert_routing({ path: 'photos', method: :post }, { controller: 'photos', action: 'create' })
```
