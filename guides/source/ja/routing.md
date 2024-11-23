Rails のルーティング
=================================

このガイドでは、開発者に向けてRailsのルーティング機能を解説します（訳注: routeとrootを区別するため、訳文ではrouteを基本的に「ルーティング」と訳します）。

このガイドの内容:

* `config/routes.rb`のコードの読み方
* 独自のルーティング作成法 （リソースベースのルーティングが推奨されますが、`match`メソッドによるルーティングも可能です）
* ルーティングのパラメータの宣言方法（コントローラのアクションに渡される）
* ルーティングヘルパーを使ってパスやURLを自動生成する方法
* 制限の作成やRackエンドポイントのマウントなどの高度な手法

--------------------------------------------------------------------------------


Railsルーターの目的
-------------------------------

Railsのルーター（router）は、URLパスに基づいて、受信したHTTPリクエストをRailsアプリケーション内の特定のコントローラーアクションに対応付けます（[Rack](rails_on_rack.html)アプリケーションに転送することも可能です）。ルーターは、ルーターで構成されたリソースに基づいて、パスとURLヘルパーも生成します。

### 受信したURLを実際のコードにルーティングする

RailsアプリケーションがHTTPリクエストを受け取ると、このリクエストをコントローラーのアクション（メソッドとも呼ばれます）に対応付けるようルーターに要求します。たとえば、以下の受信リクエストを考えてみましょう。

```
GET /users/17
```

最初にマッチしたのが以下のルーティングだとします。

```ruby
get "/users/:id", to: "user#show"
```

このリクエストは`UsersController`クラスの`show`アクションに一致し、`params`ハッシュには`{ id: '17' }`が含まれます。

`to:`オプションは、`コントローラ名#アクション名`形式の文字列が渡されることを前提としています。
`to:`オプションでアクション名を文字列で指定する代わりに、`action:`オプションでアクション名のシンボルを指定することも可能です。
さらに`controller:`オプションも使えば、以下のように`#`記号なしの文字列を指定することも可能です。

```ruby
get "/users/:id", controller: "users", action: :show
```

NOTE: Railsではルーティングを指定するときにスネークケースを使います。たとえば`UserProfilesController`のような複合語のコントローラを使う場合は、`user_profiles#show`のように指定します。

### コードからパスやURLを生成する

ルーターは、アプリケーションのパスやURLヘルパーメソッドを自動的に生成します。これらのメソッドを使うことで、パスやURL文字列をハードコードすることを回避できます。

たとえば、以下のルーティングを定義することで、`user_path`と`user_url`というヘルパーメソッドを利用できます。

```ruby
get "/users/:id", to: "users#show", as: "user"
```

NOTE: `as:`オプションは、ルーティングのカスタム名を指定するときに使います。ここで指定した名前は、URLとパスヘルパーを生成するときに使われます。

そして、アプリケーションのコントローラに以下のコードがあるとします。

```ruby
@user = User.find(params[:id])
```

上記に対応するビューは以下です。

```erb
<%= link_to 'User Record', user_path(@user) %>
```

すると、ルーターによって`/patients/17`というパスが生成されます。これを利用することでビューが改修しやすくなり、コードも読みやすくなります。このidはルーティングヘルパーで指定する必要がない点にご注目ください。

ルーターは、`user_path(@user)`から`/users/17`というパスを生成します。この`user_path`ヘルパーを使えば、ビューにパスをハードコードする必要がなくなります。こうすることで、最終的にルーティングを別のURLに移動するときに、対応するビューのコードを更新する必要がなくなるので、便利です。

ルーターは、同様の目的を持つ`user_url`も生成します。上述の`user_path`が生成するのは`/users/17`のような相対URLですが、`user_url`は上記の例で言うと`https://example.com/users/17`のような絶対URLを生成する点が異なります。

### Railsルーターを設定する

アプリケーションやエンジンのルーティングは`config/routes.rb`ファイルの中に存在します。これは、典型的なRailsアプリケーションでのルーティングの配置場所です。

次のセクションでは、このファイルで使われるさまざまなルーティングヘルパーについて説明します。

```ruby
Rails.application.routes.draw do
  resources :brands, only: [:index, :show] do
    resources :products, only: [:index, :show]
  end

  resource :basket, only: [:show, :update, :destroy]

  resolve("Basket") { route_for(:basket) }
end
```

これは通常のRubyソースファイルなので、ルーティング定義には、条件やループなど、Rubyのあらゆる機能を利用できます。

NOTE: ルーティング定義をラップする`Rails.application.routes.draw do ... end`ブロックは、ルーターDSL（Domain Specific Language: ドメイン固有言語）のスコープを確定するのに不可欠なので、削除してはいけません。

WARNING: `routes.rb`ファイルで変数名を使う場合は、ルーターのDSLメソッドと名前が衝突しないように十分ご注意ください。

リソースベースのルーティング: Railsのデフォルト
-----------------------------------

リソースベースのルーティング（以下リソースルーティング）を使うことで、指定のリソースコントローラでよく使われるすべてのルーティングを手軽に宣言できます。[`resources`][]を宣言するだけで、コントローラの`index`、`show`、`new`、`edit`、`create`、`update`、`destroy`アクションを個別に宣言しなくても1行で宣言が完了します。

[`resources`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-resources

### Web上のリソース

ブラウザはRailsに対してリクエストを送信する際に、特定のHTTP verb（`GET`、`POST`、`PATCH`、`PUT`、`DELETE`など）を使って、URLに対するリクエストを作成します。上に述べたHTTP verbは、いずれもリソースに対して特定の操作の実行を指示するリクエストです。リソースルーティングでは、関連するリクエストを1つのコントローラ内のアクションに割り当てます。

Railsアプリケーションが以下のHTTPリクエストを受け取ったとします。

```
DELETE /photos/17
```

このリクエストは、特定のコントローラ内アクションにマッピングさせるようルーターに要求しています。最初にマッチしたのが以下のルーティングだとします。

```ruby
resources :photos
```

Railsはこのリクエストを`PhotosController`内の`destroy`アクションに割り当て、`params`ハッシュに`{ id: '17' }`を含めます。

### CRUD、verb、アクション

Railsのリソースフルルーティングでは、（GET、PUTなどの）各種HTTP verb（動詞、HTTPメソッドとも呼ばれます） と、コントローラ内アクションを指すURLが対応付けられます。1つのアクションは、データベース上での特定の[CRUD（Create/Read/Update/Delete）](active_record_basics.html#crud-データの読み書き)操作に対応付けられるルールになっています。たとえば、以下のようなルーティングが1つあるとします。

```ruby
resources :photos
```

上の記述により、アプリケーション内に以下の7つのルーティングが作成され、いずれも`PhotosController`に対応付けられます。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | ---------------- | ----------------- | -------------------------------------------- |
| GET       | /photos          | photos#index      | すべての写真の一覧を表示                 |
| GET       | /photos/new      | photos#new        | 写真を1つ作成するためのHTMLフォームを返す |
| POST      | /photos          | photos#create     | 写真を1つ作成する                           |
| GET       | /photos/:id      | photos#show       | 特定の写真を表示する                     |
| GET       | /photos/:id/edit | photos#edit       | 写真編集用のHTMLフォームを1つ返す      |
| PATCH/PUT | /photos/:id      | photos#update     | 特定の写真を更新する                      |
| DELETE    | /photos/:id      | photos#destroy    | 特定の写真を削除する                      |

Railsのルーターでは、サーバーへのリクエストをマッチさせる際にHTTP verbとURLを**組み合わせる形で**使っているため、4種類のURL（`/photos`、`/photos/new`、`/photos/:id`、`/photos/:id/edit`）を7種類の異なるアクション（`index`、`show`、`new`、`create`、`edit`、`update`、`destroy`）に割り当てています。たとえば、同じ`photos/`パスであっても、HTTP verbが`GET`のときは`photos#index`にマッチし、HTTP verbが`POST`のときは`photos#create`にマッチします。

NOTE: Railsのルーティングファイル`routes.rb`では、ルーティングを記載する順序が重要であり、「上からの記載順に」マッチします。たとえば、`resources :photos`というルーティングが`get 'photos/poll'`よりも上の行にあれば、`resources`行の`show`アクションが`get`行の記述よりも優先されるので、`get 'photos/poll'`行のルーティングは有効になりません。`get 'photos/poll'`を最初にマッチさせるには、`get 'photos/poll'`行を`resources`行 **よりも上** に移動する必要があります。

### パスとURL用ヘルパー

リソースフルなルーティングを作成すると、アプリケーションのコントローラやビューで多くのヘルパーが利用できるようになります。

たとえば、`resources :photos`というルーティングをルーティングファイルに追加すると、コントローラやビューで以下の`_path`ヘルパーが使えるようになります。

| `_path`ヘルパー | 返すURL |
| --------- | ---------------- |
| `photos_path` | /photos |
| `new_photo_path` | /photos/new |
| `edit_photo_path(:id)` | /photos/:id/edit |
| `photo_path(:id)` | /photos/:id |

上記の`:id`などのパスヘルパーのパラメーターは、生成されたURLに渡されます。つまり、`edit_photo_path(10)`は`/photos/10/edit`を返します。

これらの`_path`ヘルパーに対応する`_url`ヘルパー（`photos_url`など）も生成されます。`_url`ヘルパーは、同じパスの前に「現在のホスト名」「ポート番号」「パスのプレフィックス」を追加して返します。

TIP: "_path"や"_url"の前に付けられるプレフィックスには、ルーティング名が使われます。これは、`rails routes`コマンド出力の"prefix"列を確認することで特定できます。詳しくは、後述の[既存のルールを一覧表示する](#既存のルールを一覧表示する)を参照してください。

### 複数のリソースを同時に定義する

リソースをいくつも定義しなければならない場合は、以下のような略記法で一度に定義することでタイプ量を節約できます。

```ruby
resources :photos, :books, :videos
```

上の記法は、以下の記法のショートカットです。

```ruby
resources :photos
resources :books
resources :videos
```

### 単数形リソース

場合によっては、ユーザーがリソースを1個しか持たないことが前提となることもあります（この場合、そのリソースのすべての値を一覧表示する`index`アクションを用意する意味はありません）。このような場合は、複数形の`resources`の代わりに単数形の`resource`を指定できます。

以下のリソースフルなルーティングは、アプリケーション内に6つのルーティングを作成して、それらすべてを`Geocoders`コントローラーに対応付けます。

```ruby
resource :geocoder
resolve("Geocoder") { [:geocoder] }
```

NOTE: 上の`resolve`呼び出しは、`Geocoder`のインスタンスを[レコード識別](form_helpers.html#レコード識別を利用する)を介して単数形ルーティングに変換するために必要です。

`Geocoders`コントローラに割り当てられた以下の6つのルーティングを作成します。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | -------------- | ----------------- | --------------------------------------------- |
| GET       | /geocoder/new  | geocoders#new     | geocoder作成用のHTMLフォームを返す |
| POST      | /geocoder      | geocoders#create  | geocoderを作成する                       |
| GET       | /geocoder      | geocoders#show    | 1つしかないgeocoderリソースを表示する    |
| GET       | /geocoder/edit | geocoders#edit    | geocoder編集用のHTMLフォームを返す  |
| PATCH/PUT | /geocoder      | geocoders#update  | 1つしかないgeocoderリソースを更新する     |
| DELETE    | /geocoder      | geocoders#destroy | geocoderリソースを削除する                  |

NOTE: 単数形リソースは、複数形のコントローラに対応付けられます。たとえば、`geocoder`という単数形リソースは、`GeocodersController`という複数形の名前を持つコントローラに対応付けられます。

単数形のリソースフルなルーティングを使うと、以下のヘルパーメソッドが生成されます。

| `_path`ヘルパー | 返すURL |
| --------- | ---------------- |
| `new_geocoder_path` | /geocoder/new |
| `edit_geocoder_path` | /geocoder/edit |
| `geocoder_path)` | /geocoder |

複数形リソースの場合と同様に、末尾が`_url`で終わる同じヘルパー名でも「現在のホスト名」「ポート番号」「パスのプレフィックス」が含まれます。

### コントローラの名前空間とルーティング

大規模なアプリケーションでは、コントローラーを名前空間でグループ化して整理したい場合があります。たとえば、`app/controllers/admin`ディレクトリ内にある`Admin::`名前空間の下に、複数のコントローラーがあるとします。以下のように[`namespace`][]ブロックを使うと、このようなグループへルーティングできます。

```ruby
namespace :admin do
  resources :articles
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

上記の例では、`namespace`のデフォルトの規則に沿って、すべてのパスに`/admin`プレフィックスが追加されていることにご注目ください。

#### モジュールを利用する

例外的に、（`/admin`が前についていない）`/articles`を`Admin::ArticlesController`にルーティングしたい場合は、以下のように[`scope`][]ブロックでモジュールを指定できます。

```ruby
scope module: "admin" do
  resources :articles
end
```

上は以下のように`scope`を使わない書き方も可能です。

```ruby
resources :articles, module: "admin"
```

#### スコープを領する

逆に、`/admin/articles`を（`Admin::`モジュールのプレフィックスなしの）`ArticlesController`にルーティングしたい場合は、以下のように`scope`ブロックでパスを指定できます。

```ruby
scope "/admin" do
  resources :articles
end
```

上は以下のように`scope`を使わない書き方も可能です。

```ruby
resources :articles, path: "/admin/articles"
```

いずれの場合も、名前付きルーティング（named route）は、`scope`を使わなかった場合と同じになることにご注目ください。最後の例の場合は、以下のパスが`ArticlesController`に割り当てられます。

上述の2つの書き方（パスに`/admin`をプレフィックスしない場合、モジュールに`Admin::`をプレフィックスしない場合）は、どちらの場合も、名前付きルーティングヘルパーは`scope`を使わなかった場合と同じになります。

最後のケースでは、`ArticlesController`に以下のパスが対応付けられます。


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

ルーティングをネストする（入れ子にする）宣言を使うことで、この親子関係をルーティングで表せるようになります。

```ruby
resources :magazines do
  resources :ads
end
```

上のルーティングによって、雑誌（magazines）へのルーティングに加えて、広告（ads）を`AdsController`にもルーティングできるようになりました。ネストした`ads`リソースの全ルーティングは以下のようになります。

| HTTP verb | パス             | コントローラ#アクション | 目的                                     |
| --------- | ------------------------------------ | ----------------- | -------------------------------------------------------------------------- |
| GET       | /magazines/:magazine_id/ads          | ads#index         | ある雑誌1冊に含まれる広告をすべて表示する                          |
| GET       | /magazines/:magazine_id/ads/new      | ads#new           | ある1冊の雑誌用の広告を1つ作成するHTMLフォームを返す |
| POST      | /magazines/:magazine_id/ads          | ads#create        | ある1冊の雑誌用の広告を1つ作成する                           |
| GET       | /magazines/:magazine_id/ads/:id      | ads#show          | ある雑誌1冊に含まれる広告を1つ表示する                    |
| GET       | /magazines/:magazine_id/ads/:id/edit | ads#edit          | ある雑誌1冊に含まれる広告1つを編集するHTMLフォームを返す     |
| PATCH/PUT | /magazines/:magazine_id/ads/:id      | ads#update        | ある雑誌1冊に含まれる広告を1つ更新する                      |
| DELETE    | /magazines/:magazine_id/ads/:id      | ads#destroy       | ある雑誌1冊に含まれる広告を1つ削除する                      |

これによって、パスとURLについて通常のルーティングヘルパーも作成されます。ヘルパーは`magazine_ads_url`や`edit_magazine_ad_path`のような名前になります。`ads`リソースは`magazines`の下にネストしているので、adのURLではmagazineを省略できません。これらのヘルパーは、最初のパラメータとしてMagazineモデルのインスタンスを1つ受け取ります（`magazine_ads_url(@magazine, @ad)`）。

#### ネスティング回数の上限

次のように、ネストしたリソースの中で別のリソースをネストできます。

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

たとえば上のルーティング例は、アプリケーションで以下のようなパスとして認識されます。

```
/publishers/1/magazines/2/photos/3
```

このURLに対応するルーティングヘルパーは`publisher_magazine_photo_url`となります。このヘルパーを使うには、毎回3つの階層すべてでオブジェクトを指定する必要があります。このように、リソースのネストを深くすると複雑になりすぎてしまい、ルーティングをメンテナンスしにくくなります。

TIP: **リソースのネスティングの深さは、経験則として1階層にとどめておくべきです。**

#### ネストを浅くする

（上記で推奨したような）深いネストを回避する方法の1つとして、コレクションアクションの生成場所を親のスコープに移動するという方法があります。この方法を使うと、階層化されたという感覚を得ながら、メンバーアクションをネストしないようにできます。言い換えると、最小限の情報でリソースを一意に指定できるルーティングを作成するということです。

NOTE: "メンバー"アクションとは、個別のリソースに適用され、アクションの対象となる特定のリソースを識別するためにIDを指定する必要のあるアクション（`show`や`edit`など）を指します。"コレクション"アクションとは、リソースのセット全体を操作するアクション（`index`など）を指します。

```ruby
resources :articles do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

上のルーティングでは、`:only`オプションを用いることで、指定したルーティングだけを生成するようRailsに指示しています。
この方法は、ルーティングの記述を複雑にせずに済み、かつ深いネストを作らずに済むという絶妙なバランスを保っています。`:shallow`オプションを使うことで、上と同じ内容をさらに簡単に記述できます。

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
| GET       | /articles(.:format)                          | articles#index    | articles_path            |
| POST      | /articles(.:format)                          | articles#create   | articles_path            |
| GET       | /articles/new(.:format)                      | articles#new      | new_article_path         |
| GET       | /articles/:id/edit(.:format)                 | articles#edit     | edit_article_path        |
| GET       | /articles/:id(.:format)                      | articles#show     | article_path             |
| PATCH/PUT | /articles/:id(.:format)                      | articles#update   | article_path             |
| DELETE    | /articles/:id(.:format)                      | articles#destroy  | article_path             |


ブロック内で[`shallow`][]メソッドを使うと、すべてのネストが1階層浅くなるように内側にスコープを1つ作成します。これによって生成されるルーティングは、最初の例と完全に同じです。

```ruby
shallow do
  resources :articles do
    resources :comments
    resources :quotes
  end
end
```

`scope`メソッドには、「浅い」ルーティングをカスタマイズするためのオプションが2つあります。`:shallow_path`と`:shallow_prefix`です。

`:shallow_path`オプションは、指定されたパラメータをメンバーのパスの冒頭に追加します。

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

`:shallow_prefix`オプションを使うと、指定されたパラメータを`_path`および`_url`ルーティングヘルパー名の冒頭に追加します。

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

concernを使うことで、他のリソース内で使いまわせる共通のルーティングを宣言できます。concernは以下のように[`concern`][]ブロックで定義します。

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

`scope`ブロック内や`namespace`ブロック内では、以下のように複数形の[`concerns`][]を呼び出すことでも上と同じ結果を得られます。

```ruby
namespace :messages do
  concerns :commentable
end

namespace :articles do
  concerns :commentable
  concerns :image_attachable
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

上で生成されるパスは`/magazines/5/ads/42`のようになります。

以下のように複数のオブジェクトを持つ配列に対して[`url_for`][ActionView::RoutingUrlFor#url_for]を使うときも、上と同じようにパスを得られます。

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

上の場合、Railsは`@magazine`が`Magazine`であり、`@ad`が`Ad`であることを認識し、それに基づいて`magazine_ad_path`ヘルパーを呼び出します。[`link_to`][]ヘルパーでは、[`url_for`][]呼び出しを書かなくても、以下のようにずっと簡潔な方法でオブジェクトだけを指定できます。

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

1冊の雑誌にだけリンクしたい場合は、以下のように書きます。

```erb
<%= link_to 'Magazine details', @magazine %>
```

それ以外のアクションについては、配列の第1要素にアクション名を挿入する必要があります。たとえば、`edit_magazine_ad_path`と書く代わりに以下のように書けます。

```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

これにより、モデルのインスタンスをURLとして扱えるようになります。これはリソースフルなスタイルを採用する大きなメリットの1つです。

NOTE: `[@magazine, @ad]`のようなオブジェクトからパスとURLを自動的に取得するために、Railsでは[`ActiveModel::Naming`][]モジュールと[`ActiveModel::Conversion`][]モジュールのメソッドを利用してします。具体的には、`@magazine.model_name.route_key`は`magazines`を返し、`@magazine.to_param`はモデルの`id`の文字列表現を返します。したがって、`[@magazine, @ad]`オブジェクトに対して生成されるパスは、`/magazines/1/ads/42`のようになります。

[ActionView::RoutingUrlFor#url_for]: https://api.rubyonrails.org/classes/ActionView/RoutingUrlFor.html#method-i-url_for
[`link_to`]:
  https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to
[`url_for`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html
[`ActiveModel::Naming`]:
  https://api.rubyonrails.org/classes/ActiveModel/Naming.html
[`ActiveModel::Conversion`]:
  https://api.rubyonrails.org/classes/ActiveModel/Conversion.html

### RESTfulなルーティングをさらに追加する

デフォルトで作成されるRESTfulなルーティングは[7つ](#crud、verb、アクション)ありますが、7つと決まっているわけではありません。必要であれば、コレクションやコレクションの各メンバーに対して適用されるルーティングを追加することも可能です。

以下のセクションでは、メンバールーティングとコレクションルーティングの追加について説明します。`member`という用語は、単一の要素に作用するルーティング（`show`、`update`、`destroy`など）を指します。`collection`という用語は、複数の要素（要素のコレクション）を操作するルーティング（`index`ルーティングなど）を指します。

#### メンバールーティングを追加する

[`member`][]ブロックは、以下のようにリソースブロックに追加できます。

```ruby
resources :photos do
  member do
    get "preview"
  end
end
```

上のルーティングはGETリクエストとそれに伴う`/photos/1/preview`を認識し、リクエストを`Photos`コントローラの`preview`アクションにルーティングし、リソースid値を`params[:id]`に渡します。同時に、`preview_photo_url`ヘルパーと`preview_photo_path`ヘルパーも作成されます。

`/photos/1/preview`への受信GETリクエストは、`PhotosController`の`preview`アクションにルーティングされます。リソースID値は`params[:id]`で得られます。また、`preview_photo_url`ヘルパーおよび`preview_photo_path`ヘルパーも作成されます。

`member`ブロック内では、各ルート定義でHTTP verb（上記の例では`get 'preview'`の`get`）が指定されます。[`get`][]の他に、[`patch`][]、[`put`][]、[`post`][]、または[`delete`][]も利用できます。

`member`ルーティングが1つしかない場合は、以下のようにルーティングで`:on`オプションを指定することでブロックを省略できます。

```ruby
resources :photos do
  get "preview", on: :member
end
```

上の`:on`オプションは省略することも可能です。この場合、リソースidの値の取得に`params[:id]`ではなく`params[:photo_id]`を使う点を除いて、同じメンバールーティングが生成されます。ルーティングヘルパーも、`preview_photo_url`が`photo_preview_url`に、`preview_photo_path`が`photo_preview_path`にそれぞれリネームされます。

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
    get "search"
  end
end
```

上のルーティングは、GETリクエスト + `/photos/search`などの（idを伴わない）パスを認識し、リクエストを`Photos`コントローラの`search`アクションにルーティングします。このとき`search_photos_url`や`search_photos_path`ルーティングヘルパーも同時に作成されます。

collectionルーティングでもmemberルーティングのときと同様に`:on`オプションを使えます。

```ruby
resources :photos do
  get "search", on: :collection
end
```

NOTE: 追加のresourceルーティングをシンボルで第1引数として定義する場合は、文字列で定義した場合と振る舞いが同等ではなくなる点にご注意ください。文字列はパスとして推測されますが、シンボルはコントローラのアクションとして推測されます。

[`collection`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-collection

#### 追加されたnewアクションへのルーティングを追加する

`:on`オプションを使って、たとえば以下のように別のnewアクションを追加できます。

```ruby
resources :comments do
  get "preview", on: :new
end
```

上のようにすることで、GET + `/comments/new/preview`のようなパスが認識され、`Comments`コントローラの`preview`アクションにルーティングされます。`preview_new_comment_url`や`preview_new_comment_path`ルーティングヘルパーも同時に作成されます。

TIP: リソースフルなルーティングにアクションが多数追加されていることに気付いたら、それ以上アクションを追加するのをやめて、そこに別のリソースが隠されているのではないかと疑ってみる方がよいでしょう。

`resources`で生成されるデフォルトのルーティングやヘルパーは、カスタマイズ可能です。詳しくは、[リソースフルルーティングをカスタマイズする](#リソースフルルーティングをカスタマイズする)セクションを参照してください。

リソースフルでないルーティング
----------------------

Railsでは、`resources`によるリソースフルなルーティングの他に、任意のURLをアクションにルーティングすることも可能です。この方式を使う場合、リソースフルルーティングのような自動的なルーティンググループの生成は行われません。従って、アプリケーションで必要なルーティングを個別に設定することになります。

基本的にはリソースフルルーティングを使うべきですが、このような単純なルーティングの方が適している場合もあります。リソースフルルーティングが適していない場合に、アプリケーションのあらゆる部分を無理にリソースフルなフレームワークに押し込める必要はありません。

リソースフルでないルーティングが適しているユースケースの1つに、既存のレガシーURLを新しいRailsアクションに対応付ける場合があります。

### パラメータの割り当て

通常のルーティングを設定する場合は、RailsがルーティングをブラウザからのHTTPリクエストに割り当てるためのシンボルをいくつか渡します。以下のルーティングを例にとってみましょう。

```ruby
get "photos(/:id)", to: "photos#display"
```

`/photos/1`に対するブラウザからの`GET`リクエストが上のルーティングで処理されると、`PhotosController`の`display`アクションが呼び出され、URL末尾のパラメータ`"1"`へのアクセスは`params[:id]`で行なえます。`:id`が必須パラメータではないことが丸かっこ`()`で示されているので、このルーティングは、上の例の`/photos`を`PhotosController#display`にルーティングすることもできます。

### 動的なセグメント

通常のルーティングの一部として、文字列を固定しない動的なセグメントを自由に使えます。あらゆるセグメントは`params`の一部に含めてアクションに渡せます。以下のルーティングを設定したとします。

```ruby
get "photos/:id/:user_id", to: "photos#show"
```

上のルーティングは、`/photos/1/2`のようなパスにマッチします。このときアクションで使える`params`は`{ controller: "photos", action: "show", id: "1", user_id: "2" }`となります。

TIP: デフォルトでは動的なセグメント分割にドット`.`を渡せません。ドットはフォーマット済みルーティングでは区切り文字として使われるためです。どうしても動的セグメント内でドットを使いたい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使えます。

### 静的なセグメント

ルーティング作成時にコロンを付けなかった部分は、静的なセグメントとして固定文字列が指定されます。

```ruby
get "photos/:id/with_user/:user_id", to: "photos#show"
```

上のルーティングは、`/photos/1/with_user/2`のようなパスにマッチします。このときアクションで使える`params`は`{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### クエリ文字列

クエリ文字列（訳注: URLの末尾に`?パラメータ名=値`の形式で追加されるパラメータ）で指定されているパラメータも、すべて`params`に含まれます。以下のルーティングを例にとってみましょう。

```ruby
get "photos/:id", to: "photos#show"
```

ブラウザからの`GET`リクエストで`/photos/1?user_id=2`というパスが渡されると、通常通り`PhotosController`クラスの`show`アクションに割り当てられます。このときの`params`は`{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`となります。

### デフォルトパラメータを定義する

`:defaults`オプションにハッシュを1つ渡すことで、ルーティング内にデフォルト値を定義できます。このとき、動的なセグメントとして指定する必要のないパラメータを次のように適用することも可能です。

```ruby
get "photos/:id", to: "photos#show", defaults: { format: "jpg" }
```

上のルーティングはブラウザからの`/photos/12`パスにマッチし、`Photos`コントローラの`show`アクションに割り当てられます。`params[:format]`は`"jpg"`に設定されます。

ブロック形式の[`defaults`][]を使うと、複数の項目についてデフォルト値を設定することもできます。

```ruby
defaults format: :json do
  resources :photos
  resources :articles
end
```

NOTE: セキュリティ上の理由により、クエリパラメータでデフォルト値をオーバーライドすることはできません。オーバーライド可能なデフォルト値は、URLパスの置き換えによる動的なセグメントのみです。

[`defaults`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-defaults

### 名前付きルーティング

`:as`オプションを使うと、任意のルーティングの`_path`ヘルパーと`_url`ヘルパーで使われる名前を指定できます。

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

上のルーティングでは`logout_path`と`logout_url`がアプリケーションのルーティングヘルパーとして作成されます。`logout_path`を呼び出すと`/exit`が返されます。

リソースを定義する前に、以下のように`as`でカスタムルーティングを配置すると、リソースで定義されたルーティングヘルパー名をオーバーライドすることも可能です。

```ruby
get ":username", to: "users#show", as: :user
resources :users
```

上のルーティングでは、`/:username`（`/jane`など）にマッチする`user_path`ヘルパーが生成されます。`UsersController`の`show`アクションの内部で`params[:username]`にアクセスすると、ユーザー名を取り出せます。

### HTTP verbを制限する

あるルーティングを特定のHTTP verbに割り当てるために、通常は[`get`][]、[`patch`][]、[`put`][]、[`post`][]、[`delete`][]メソッドのいずれかを使う必要があります。[`match`][]メソッドと`:via`オプションを使うことで、複数のHTTP verbに同時にマッチするルーティングを作成できます。

```ruby
match "photos", to: "photos#show", via: [:get, :post]
```

上のルーティングは、`PhotosController`の`show`アクションに対して`GET`リクエストと`POST`リクエストの両方を受け取ります。

`via: :all`を指定すると、すべてのHTTP verbにマッチする特別なルーティングを作成できます。

```ruby
match "photos", to: "photos#show", via: :all
```

NOTE: 1つのアクションに`GET`リクエストと`POST`リクエストの両方をルーティングすると、セキュリティ上の悪影響が生じます。たとえば、`GET`アクションはCSRFトークンをチェックしません（したがって、`GET`リクエストでデータベースに書き込むことは推奨されていません。詳しくは[セキュリティガイド](security.html#csrfへの対応策)のCSRF対策を参照してください）。一般に、どうしても必要な理由がない限り、1つのアクションにすべてのHTTP verbをルーティングしてはいけません。

[`match`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Base.html#method-i-match

### セグメントを制限する

`:constraints`オプションを使って、動的セグメントのURLフォーマットを特定の形式に制限できます。

```ruby
get "photos/:id", to: "photos#show", constraints: { id: /[A-Z]\d{5}/ }
```

上のルーティング定義では、`id`は5文字の英数字でなければなりません。したがって、上のルーティングは`/photos/A12345`のようなパスにはマッチしますが、`/photos/893`にはマッチしません。

以下のようにもっと簡潔な方法でも記述できます。

```ruby
get "photos/:id", to: "photos#show", id: /[A-Z]\d{5}/
```

`:constraints`では正規表現を使えますが、ここでは正規表現の「アンカー（`^`や`$`など）」は使えないという制限があることにご注意ください。たとえば、以下のルーティングは無効です。

```ruby
get '/:id', to: 'articles#show', constraints: { id: /^\d/ }
```

対象となるすべてのルーティングは冒頭と末尾が既にアンカーされているので、このようなアンカーを指定する必要はないはずです。
以下の例をご覧ください。

```ruby
get "/:id", to: "articles#show", constraints: { id: /\d.+/ }
get "/:username", to: "users#show"
```

上のルーティングでは、root名前空間が共有され、さらに以下の振る舞いも共有可能になります。

- 常に数字で始まるルーティングパスの扱い（例: `/1-hello-world`は`articles`に`id`値を渡す）
- 数字で始まらないルーティングパスの扱い（例: `/david`は`users`に`username`値を渡す）

### リクエスト内容に応じて制限を加える

また、`String`を返す[Requestオブジェクト](action_controller_overview.html#requestオブジェクト)の任意のメソッドに基いてルーティングを制限することもできます。

リクエストに応じた制限は、セグメントを制限するときと同様の方法で指定できます。

```ruby
get "photos", to: "photos#index", constraints: { subdomain: "admin" }
```

上は、受信リクエストを`admin`サブドメインへのパスと照合します。

[`constraints`][]ブロックで制限を指定することも可能です。

```ruby
namespace :admin do
  constraints subdomain: "admin" do
    resources :photos
  end
end
```

上は`https://admin.example.com/photos`のようなURLにマッチします。

リクエストベースの制限は、[Requestオブジェクト](action_controller_overview.html#requestオブジェクト)に対してあるメソッドを呼び出し、戻り値をハッシュと比較する形で機能します。たとえば、`constraints: { subdomain: 'api' }`という制限は`api`サブドメインに期待どおりマッチしますが、`constraints: { subdomain: :api }`のようにシンボルを使った場合は`api`サブドメインに一致しません（`request.subdomain`が返す`'api'`は文字列型であるため）。

NOTE: 制約の値は、対応するリクエストオブジェクトのメソッドの戻り値型と一致する必要があります。

`format`の制限には例外があります。これはRequestオブジェクトのメソッドですが、すべてのパスに含まれる暗黙的なオプションのパラメータでもあります。`format`の制限よりセグメント制限が優先され、`format`制約はハッシュを通じて強制される場合にのみ適用されます。たとえば、`get "foo"、constraints: { format： "json" }`は`GET /foo`と一致します。

NOTE: `get "foo", constraints: lambda { |req| req.format == :json }`のように制約で[lambdaを指定する](#高度な制限)と、明示的なJSONリクエストへのルーティングのみを一致させることも可能です。

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
  get "*path", to: "restricted_list#index",
    constraints: RestrictedListConstraint.new
end
```

制限をlambdaとして指定することもできます。

```ruby
Rails.application.routes.draw do
  get "*path", to: "restricted_list#index",
    constraints: lambda { |request| RestrictedList.retrieve_ips.include?(request.remote_ip) }
end
```

`matches?`メソッドおよびlambdaは、どちらも引数として`request`オブジェクトを受け取ります。

#### 制限をブロック形式で指定する

制限はブロック形式で指定することも可能です。これは以下のように、同一のルールを複数のルーティングに適用する必要がある場合に便利です。

```ruby
class RestrictedListConstraint
  # ...上述の例と同じ
end

Rails.application.routes.draw do
  constraints(RestrictedListConstraint.new) do
    get "*path", to: "restricted_list#index"
    get "*other-path", to: "other_restricted_list#index"
  end
end
```

制限を`lambda`で指定することもできます。

```ruby
Rails.application.routes.draw do
  constraints(lambda { |request| RestrictedList.retrieve_ips.include?(request.remote_ip) }) do
    get "*path", to: "restricted_list#index"
    get "*other-path", to: "other_restricted_list#index"
  end
end
```

### ワイルドカードセグメント

ルーティング定義ではワイルドカードセグメント（`*`）を利用できます。これは、`*other`のように`*`をセグメントにプレフィックスしたものです。

```ruby
get "photos/*other", to: "photos#unknown"
```

上のルーティングは`photos/12`や`/photos/long/path/to/12`（`long/path/to`は長いパス）にマッチし、`params[:other]`には`"12"`や`"long/path/to/12"`が設定されます。冒頭にアスタリスク`*`が付いているセグメントを「ワイルドカードセグメント」と呼びます。

ワイルドカードセグメントを使うと、特定のパラメーター（上記の`*other`）がルーティングの残りの部分に一致する形で指定する、「ルートグロビング（route globbing）」と呼ばれる方法が利用できます。

したがって、上記のルーティングは`photos/12`や`/photos/long/path/to/12`に一致し、`params[:other]`には`"12"`が設定されます（`"long/path/to/12"`）。

ワイルドカードセグメントは、以下のようにルーティングのどの部分でも使えます。

```ruby
get "books/*section/:title", to: "books#show"
```

上は`books/some/section/last-words-a-memoir`にマッチし、`params[:section]`には`'some/section'`が保存され、`params[:title]`には`'last-words-a-memoir'`が保存されます。

技術上は、1つのルーティングに2つ以上のワイルドカードセグメントを含めることは可能です。マッチャによるセグメントのパラメータ割り当ては、出現順に行われます。

```ruby
get "*a/foo/*b", to: "test#index"
```

たとえば、上のルーティングは`zoo/woo/foo/bar/baz`にマッチし、`params[:a]`には`'zoo/woo'`が保存され、`params[:b]`には`'bar/baz'`が保存されます。

### セグメントのフォーマット

以下のルーティング定義があるとします。

```ruby
get "*pages", to: "pages#show"
```

このルーティングに対して`'/foo/bar.json'`をリクエストしたときの`params[:pages]`は、`"foo/bar"`でリクエストフォーマット`params[:format]`にJSONを指定したものと等しくなります。

`format`のデフォルトの振る舞いは、URLにフォーマット指定が含まれていれば、それをURLから自動的にキャプチャして`params[:format]`に含めますが、この場合、URLの`format`パラメータは必須ではありません。

フォーマットが明示的に指定されていない場合のURLにマッチさせ、フォーマット拡張子を含むURLを無視する場合は、以下のように`format: false`オプションを指定できます。

```ruby
get "*pages", to: "pages#show", format: false
```

逆に、フォーマットセグメントを必須にして省略不可にしたい場合は、`format: true`を指定します。

```ruby
get "*pages", to: "pages#show", format: true
```

### リダイレクト

ルーティングで[`redirect`][]を使うと、任意のパスを他のパスにリダイレクトできます。

```ruby
get "/stories", to: redirect("/articles")
```

パスにマッチする動的セグメントを再利用してリダイレクトすることもできます。

```ruby
get "/stories/:name", to: redirect("/articles/%{name}")
```

リダイレクトにブロックを渡すこともできます。このリダイレクトは、シンボル化されたパスパラメータとrequestオブジェクトを受け取ります。

```ruby
get "/stories/:name", to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
get "/stories", to: redirect { |path_params, req| "/articles/#{req.subdomain}" }
```

デフォルトのリダイレクトは、HTTPステータス「301 "Moved Permanently"」のリダイレクトになる点にご注意ください。一部のWebブラウザやプロキシサーバーはこの種のリダイレクトをキャッシュすることがあり、その場合リダイレクト前の古いページにはアクセスできなくなります。次のように`:status`オプションを使うことでレスポンスのステータスを変更できます。

```ruby
get "/stories/:name", to: redirect("/articles/%{name}", status: 302)
```

どの場合であっても、ホスト（`http://www.example.com`など）が指定されていない場合は、Railsは（以前のリクエストではなく）現在のリクエストから詳細を取得します。

[`redirect`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Redirection.html#method-i-redirect

### Rackアプリケーションにルーティングする

`:to`オプションに`'articles#index'`（`ArticlesController`クラスの`index`アクションに対応する）のような文字列を指定する代わりに、任意の[Rackアプリケーション](rails_on_rack.html)をマッチャーのエンドポイントとして指定できます。

```ruby
match "/application.js", to: MyRackApp, via: :all
```

Railsルーターは、`MyRackApp`が`call`に応答して`[status, headers, body]`を返す限り、ルーティング先がRackアプリケーションであるかコントローラのアクションであるかを区別しません。これによって、適切と考えられるすべてのHTTP verbをRackアプリケーションで扱えるようになるので、これは`via: :all`の適切な利用法です。

NOTE: 参考までに、`'articles#index'`は実際には`ArticlesController.action(:index)`という形に展開されます。これは有効なRackアプリケーションを返します。

NOTE: procやlambdaは`call`に応答するオブジェクトなので、たとえばヘルスチェックで用いるルーティングを`get '/health', to: ->(env) { [204, {}, ['']] }`のように極めてシンプルにインライン実装できます。

Rackアプリケーションをマッチャーのエンドポイントとして指定すると、それを受け取るRackアプリケーションのルーティングは変更されない点にご留意ください。以下のルーティングでは、Rackアプリケーションは`/admin`へのルーティングを期待するべきです。

```ruby
match "/admin", to: AdminApp, via: :all
```

Rackアプリケーションがrootパスでリクエストを受け取るようにしたい場合は、[`mount`][]を使います。

```ruby
mount AdminApp, at: "/admin"
```

[`mount`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Base.html#method-i-mount

### `root`を使う

[`root`][]メソッドを使うことで、`'/'`によるルーティング先を指定できます。

```ruby
root to: "pages#main"
root "pages#main" # 上の省略形
```

`root`ルーティングは、ルーティングファイルの冒頭に記述するのが一般的です（最初にマッチする必要があるため）。

NOTE: `root`ルーティングがデフォルトで処理するのは`GET`リクエストですが、それ以外のHTTP verbを指定することも一応可能です（例: `root "posts#index", via: :post`）。

`root`ルーティングは、以下のように名前空間やスコープの内側でも指定できます。

```ruby
root to: "home#index"

namespace :admin do
  root to: "admin#index"
end
```

上は、`/admin`が`AdminController`の`index`アクションにマッチし、`/`は`HomeController`の`index`アクションにマッチします。

[`root`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-root

### Unicode文字列をルーティングで使う

Unicode文字列を以下のようにルーティングで直接使うこともできます。

```ruby
get "こんにちは", to: "welcome#index"
```

### ダイレクトルーティング（Direct routes）

[`direct`][]を呼び出すことで、カスタムURLヘルパーを次のように直接作成できます。

```ruby
direct :homepage do
  "http://www.rubyonrails.org"
end

# >> homepage_url
# => "http://www.rubyonrails.org"
```

このブロックの戻り値は、必ず[`url_for`][]メソッドで有効な1個の引数にしなければなりません。これによって、有効な「文字列URL」「ハッシュ」「配列」「Active Modelインスタンス」「Active Modelクラス」のいずれか1つを渡せるようになります。


```ruby
direct :commentable do |model|
  [ model, anchor: model.dom_id ]
end

direct :main do
  { controller: "pages", action: "index", subdomain: "www" }
end

# >> main_url
# => "http://www.example.com/pages"
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

ほとんどの場合、[`resources`][]で生成されるデフォルトのルーティングやヘルパーで用は足りますが、ルーティングを何らかの方法でカスタマイズしたくなることもあります。Railsでは、リソースフルルーティングやヘルパーをカスタマイズするためのさまざまな方法が用意されています。このセクションでは、利用可能なオプションについて詳しく説明します。

### 利用するコントローラを指定する

`:controller`オプションは、リソースで使うコントローラを以下のように明示的に指定します。

```ruby
resources :photos, controller: "images"
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

名前空間内のコントローラは以下のように直接指定できます。

```ruby
resources :user_permissions, controller: "admin/user_permissions"
```

上は`Admin::UserPermissionsController`のインスタンスにルーティングされます。

NOTE: ここでサポートされている記法は、`/`で区切る「ディレクトリ記法」のみです。コントローラをRubyの定数表記法（`controller: "Admin::UserPermissions"`など）で指定する記法はサポートされていません。

### 制限を`id`で指定する

`:constraints`オプションを使うと、暗黙で使われる`id`に対して以下のように必須のフォーマットを指定できます。

```ruby
resources :photos, constraints: { id: /[A-Z][A-Z][0-9]+/ }
```

上の宣言は`:id`パラメータに制限を加え、指定した正規表現にのみマッチするようにします。上のルーティング例では`/photos/1`のようなパスにはマッチしなくなり、代わりに`/photos/RR27`のようなパスにマッチするようになります。

以下のようにブロック形式を使うことで、1つの制限を多数のルーティングに対してまとめて指定することも可能です。

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: このコンテキストでは、リソースフルでないルーティングの[より高度な制限](#高度な制限)セクションで説明した方法も利用できます。

TIP: デフォルトでは`:id`パラメータにドット`.`を渡せません。ドットはフォーマット済みルーティングでは区切り文字として使われるためです。どうしても`:id`内でドットを使いたい場合は、デフォルト設定を上書きする制限を与えます。たとえば`id: /[^\/]+/`とすると、スラッシュ以外のすべての文字が使えます。

### 名前付きルーティングヘルパーをオーバーライドする

`:as`オプションを使うと、ルーティングヘルパーのデフォルトの命名方法を以下のように上書きしてルーティングヘルパー名を変えられます。

```ruby
resources :photos, as: "images"
```

上のルーティングは`/photos`にマッチし、リクエストを通常どおり`PhotosController`にルーティングしますが、ヘルパーには`:as`オプションで指定した値を用いて`images_path`などの名前を付けます。

| HTTP verb  | パス                  | コントローラ#アクション   | 名前付きルーティングヘルパー              |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | photos#index      | images_path          |
| GET       | /photos/new      | photos#new        | new_image_path       |
| POST      | /photos          | photos#create     | images_path          |
| GET       | /photos/:id      | photos#show       | image_path(:id)      |
| GET       | /photos/:id/edit | photos#edit       | edit_image_path(:id) |
| PATCH/PUT | /photos/:id      | photos#update     | image_path(:id)      |
| DELETE    | /photos/:id      | photos#destroy    | image_path(:id)      |

### `new`や`edit`のパス名をリネームする

`:path_names`オプションを使うと、パスに含まれているデフォルトの"new"セグメントや"edit"セグメントをオーバーライドできます。

```ruby
resources :photos, path_names: { new: "make", edit: "change" }
```

これにより、ルーティングで`/photos/new`の代わりに`/photos/make`、`/photos/1/edit`の代わりに`/photos/1/change`というパスを認識できるようになります。

NOTE: このオプションを指定しても、実際のルーティングヘルパーやコントローラアクション名が変更されるわけではありません。表示されるパスには`new_photo_path`ヘルパーと`edit_photo_path`ヘルパーが引き続き存在し、ルーティング先も`new`アクションと`edit`アクションのままです。

この`:path_names`オプションをブロック付き`scope`で使うと、スコープ内のすべてのルーティングに対してパス名を変更できます。

```ruby
scope path_names: { new: "make" } do
  # ブロック内の残りすべてのルーティング
end
```

### 名前付きルーティングヘルパーに`:as`でプレフィックスを追加する

以下のように`:as`オプションを使うことで、Railsがルーティングに対して生成する名前付きルーティングヘルパー名の冒頭に文字を追加（プレフィックス）できます。パススコープを使うルーティング同士での名前の衝突を避けたい場合にお使いください。

```ruby
scope "admin" do
  resources :photos, as: "admin_photos"
end

resources :photos
```

上のように`as:`を使うと、`/admin/photos`のルーティングヘルパーが、`photos_path`、`new_photos_path`などから`admin_photos_path`、`new_admin_photo_path`などに変更されます。
`as: "admin_photos"`をスコープ付き`resources :photos`に追加しない場合は、スコープなしの`resources :photos`はルーティングヘルパーを持つことができません。

ルーティングヘルパーのグループにまとめてプレフィックスを追加するには、以下のように`scope`メソッドで`:as`オプションを使います。

```ruby
scope "admin", as: "admin" do
  resources :photos, :accounts
end

resources :photos, :accounts
```

上のルーティングは、先ほどと同様に`/admin`のスコープ付きリソースヘルパーを`admin_photos_path`と`admin_accounts_path`に変更し、さらにスコープなしのリソース`photos_path`と`accounts_path`も利用可能になります。

NOTE: `namespace`スコープを使うと、`:module`や`:path`プレフィックスに加えて`:as`も自動的に追加されます。

### ネストしたリソース内で`:as`を使う

`:as`オプションを使うと、以下のようにネストしたルーティング内のリソースルーティングヘルパー名もオーバーライドできます。

```ruby
resources :magazines do
  resources :ads, as: "periodical_ads"
end
```

これにより、デフォルトの`magazine_ads_url`や`edit_magazine_ad_path`の代わりに、`magazine_periodical_ads_url`や`edit_magazine_periodical_ad_path`などのルーティングヘルパーが作成されます。

#### パラメトリックスコープ

名前付きパラメータを持つルーティングにプレフィックスを追加できます。

```ruby
scope ":account_id", as: "account", constraints: { account_id: /\d+/ } do
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

`as`オプションは必須ではありませんが、これがないと`url_for([@account, @article])`や、`url_for`に依存するヘルパー（[`form_with`][]など）の評価時にエラーが発生します。

[`form_with`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with

### 作成されるルーティングを制限する

`resources`を使うと、デフォルトで7つのアクション（`index`、`show`、`new`、`create`、`edit`、`update`、`destroy`）へのルーティングを作成します。作成されるルーティングは、`:only`オプションや`:except`オプションで制限をかけられます。

`:only`オプションは、指定したルーティングだけを生成するよう指示します。

```ruby
resources :photos, only: [:index, :show]
```

これで、`/photos`や`/photos/:id`への`GET`リクエストは成功し、`/photos`への`POST`リクエストは失敗します。

`:except`オプションは逆に、生成**しない**ルーティング（またはルーティングのリスト）を指定します。

```ruby
resources :photos, except: :destroy
```

この場合、`destroy`（`/photos/:id`への`DELETE`リクエスト）を除いた通常のルーティングが生成されます。

TIP: アプリケーションでRESTfulルーティングが多数使われている場合は、適宜`:only`や`:except`を用いて実際に必要なルーティングのみを生成することで、メモリ使用量の節約と[未使用のルーティング](#使われていないルーティングを表示する)の削減によるルーティング処理の速度向上が見込めます。

### パスを変更する

`scope`メソッドを使うことで、`resources`によって生成されるデフォルトのパス名を変更できます。

```ruby
scope(path_names: { new: "neu", edit: "bearbeiten" }) do
  resources :categories, path: "kategorien"
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

### リソースの単数形を指定する

リソースの単数形の名前をオーバーライドしたい場合、以下のように`ActiveSupport::Inflector`の[`inflections`][]で活用形ルールを追加します。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular "tooth", "teeth"
end
```

[`inflections`]: https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-inflections

### ルーティングのデフォルトパラメータ`id`をリネームする

`:param`オプションを指定することで、以下のようにデフォルトの`id`パラメータ名を別の名前に変更できます。

```ruby
resources :videos, param: :identifier
```

これにより、`params[:id]`の代わりに`params[:identifier]`が使われるようになります。

```
    videos GET  /videos(.:format)                  videos#index
           POST /videos(.:format)                  videos#create
 new_video GET  /videos/new(.:format)              videos#new
edit_video GET  /videos/:identifier/edit(.:format) videos#edit
```

```ruby
Video.find_by(id: params[:identifier])

# ↓変更前
Video.find_by(id: params[:id])
```

関連するモデルの[`ActiveRecord::Base#to_param`][]を以下のようにオーバーライドしてURLを作成できます。

```ruby
class Video < ApplicationRecord
  def to_param
    identifier
  end
end
```

```irb
irb> video = Video.find_by(identifier: "Roman-Holiday")
irb> edit_video_path(video)
=> "/videos/Roman-Holiday/edit"
```

[`ActiveRecord::Base#to_param`]: https://api.rubyonrails.org/classes/ActiveRecord/Integration.html#method-i-to_param

ルーティングを調べる
-----------------

Railsには、ルーティングを調べるさまざまな機能（inspection）とテスト機能が備わっています。

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

一番左のルーティング名（上の`new_user`など）は、生成されるルーティングヘルパー名のベースとみなせます。
ルーティングヘルパー名を取得するには、このルーティング名にサフィックス（`_path`や`_url`）を追加します（例: `new_user_path`）。

`--expanded`オプションを指定することで、ルーティングテーブルのフォーマットを以下のような詳細モードに切り替えることも可能です。

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

### ルーティングを検索する

`-g`（grepオプション）でルーティングを絞り込めます。URLヘルパー名、HTTP verb、URLパスのいずれかに部分マッチするルーティングが出力されます。

```bash
$ bin/rails routes -g new_comment
$ bin/rails routes -g POST
$ bin/rails routes -g admin
```

特定のコントローラに対応するルーティングだけを表示したい場合は、`-c`オプションでコントローラ名を指定します。

```bash
$ bin/rails routes -c users
$ bin/rails routes -c admin/users
$ bin/rails routes -c Comments
$ bin/rails routes -c Articles::CommentsController
```

TIP: `bin/rails routes`コマンド出力を読みやすく表示するには、出力が折り返されなくなるまでターミナルウィンドウを拡大するか、`--expanded`オプションを指定します。

### 使われていないルーティングを表示する

`--unused`オプションを指定することで、アプリケーションで使われていないルーティングをスキャンできます。Railsにおける「未使用」ルーティングとは、`config/routes.rb`ファイルには定義されているが、アプリケーション内のどのコントローラーアクションやビューからも参照されていないルーティングのことです。

```bash
$ bin/rails routes --unused
Found 8 unused routes:

     Prefix Verb   URI Pattern                Controller#Action
     people GET    /people(.:format)          people#index
            POST   /people(.:format)          people#create
 new_person GET    /people/new(.:format)      people#new
edit_person GET    /people/:id/edit(.:format) people#edit
     person GET    /people/:id(.:format)      people#show
            PATCH  /people/:id(.:format)      people#update
            PUT    /people/:id(.:format)      people#update
            DELETE /people/:id(.:format)      people#destroy
```

### Railsコンソールでルーティングにアクセスする

[Railsコンソール](command_line.html#bin-rails-console)内では、`Rails.application.routes.url_helpers`でルーティングヘルパーにアクセスできます。ルーティングヘルパーは、[app](command_line.html#appオブジェクトとhelperオブジェクト)オブジェクト経由でもアクセスできます。

```irb
irb> Rails.application.routes.url_helpers.users_path
=> "/users"
irb> user = User.first
=> #<User:0x00007fc1eab81628
irb> app.edit_user_path(user)
=> "/users/1/edit"
```

ルーティングをテストする
-----------------------

Railsでは、テストをシンプルに書くための3つの組み込みアサーションが用意されています。

* [`assert_generates`][]
* [`assert_recognizes`][]
* [`assert_routing`][]

[`assert_generates`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_generates
[`assert_recognizes`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_recognizes
[`assert_routing`]: https://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html#method-i-assert_routing

### `assert_generates`アサーション

[`assert_generates`][]は、特定のオプションの組み合わせを使った場合に特定のパスが生成されること、そしてそれらがデフォルトのルーティングでもカスタムルーティングでも使えることをテストするアサーション（assertion: 主張）です。

```ruby
assert_generates "/photos/1", { controller: "photos", action: "show", id: "1" }
assert_generates "/about", controller: "pages", action: "about"
```

### `assert_recognizes`アサーション

[`assert_recognizes`][]は`assert_generates`と逆方向のテスティングを行います。与えられたパスが認識可能であること、アプリケーションの特定の場所にルーティングされることをテストするアサーションです。

```ruby
assert_recognizes({ controller: "photos", action: "show", id: "1" }, "/photos/1")
```

`:method`引数でHTTP verbを指定することもできます。

```ruby
assert_recognizes({ controller: "photos", action: "create" }, { path: "photos", method: :post })
```

### `assert_routing`アサーション

[`assert_routing`][]アサーションは、`assert_generates`と`assert_recognizes`の機能を組み合わせたもので、ルーティングを2つの観点（与えられたパスによってオプションが生成されること、そのオプションによって元のパスが生成されること）でまとめてチェックします。

```ruby
assert_routing({ path: "photos", method: :post }, { controller: "photos", action: "create" })
```

巨大なルーティングファイルを分割する
-------------------------------------------------------

ルーティングが数千にもおよぶ大規模アプリケーションでは、複雑な`config/routes.rb`ファイル1個だけでは読みづらくなります。Railsでは、このような巨大`routes.rb`ファイルを[`draw`][]マクロで小さなルーティングファイルに分割する方法が提供されています。

たとえば`admin.rb`にはadmin関連のルーティングをすべて含め、API関連リソースのルーティングは`api.rb`ファイルで記述するといったことが可能です。

```ruby
# config/routes.rb

Rails.application.routes.draw do
  get "foo", to: "foo#bar"

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

NOTE: `admin.rb`ルーティングファイル内でも通常のルーティングDSLを利用できますが、`Rails.application.routes.draw`ブロックで囲んでは**いけません**。`Rails.application.routes.draw`ブロックは、メインの`config/routes.rb`ファイルでのみ使われるべきです。

[`draw`]: https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-draw

NOTE: ルーティングファイルの分割機能は、本当に必要になるまでは使ってはいけません。ルーティングファイルが複数になると、1つのファイルでルーティングを探すときよりも手間がかかります。ほとんどのアプリケーションでは（ルーティングが数百件にのぼる場合であっても）、ルーティングファイルを1つにまとめておく方が開発者にとって扱いやすくなります。RailsのルーティングDSLでは、`namespace`や`scope`でルーティングを体系的に分割する方法がすでに提供されています。
