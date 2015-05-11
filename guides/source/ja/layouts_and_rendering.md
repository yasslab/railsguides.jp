
レイアウトとレンダリング
==============================

本ガイドでは、Action ControllerとAction Viewによる基本的なレイアウト機能について解説します。

このガイドの内容:

* Railsに組み込まれているさまざまなレンダリング (=レスポンスの出力) 方法の使い方
* コンテンツが複数のセクションからなるレイアウト作成法
* パーシャルを使用してビューをDRYにする方法
* レイアウトをネストする方法 (サブテンプレート)

--------------------------------------------------------------------------------

概要: 部品を組み上げる
-------------------------------------

本ガイドでは、コントローラ、ビュー、モデルによって形成される三角形のうち、コントローラとビューの間でのやりとりを中心に扱います。ご存じのように、Railsのコントローラはリクエストを扱うプロセス全体の流れを組織的に調整する責任を負い、(ビジネスロジックのような) 重い処理はモデルの方で行なうのが普通です。モデル側での処理が完了し、ユーザーに結果を表示する時がきたら、コントローラは処理結果をビューに渡します。このときの、コントローラからビューへの結果の渡し方こそが本ガイドの主なトピックです。

大きな流れとしては、ユーザーへのレスポンスとして送信すべき内容を決定することと、ユーザーへのレスポンスを作成するために適切なメソッドを呼び出すこともこの作業に含まれます。ユーザーに返すレスポンス画面を完全なビューにするのであれば、Railsはそのビューをさらに別のレイアウトでラッピングし、パーシャルビューとして取り出すでしょう。以後本ガイドではこれらの方法をすべて紹介します(訳注: 本ガイドではrenderを一般的な意味では「出力」、具体的な動作を指す場合は「レンダリング」と訳しています)。

レスポンスを作成する
------------------

コントローラ側から見ると、HTTPレスポンスの作成方法は以下の3とおりあります。

* `render`を呼び出し、ブラウザに返す完全なレスポンスを作成する
* `redirect_to`を呼び出し、HTTPリダイレクトコードステータスをブラウザに送信する
* `head`を呼び出し、HTTPヘッダーのみで構成されたレスポンスを作成してブラウザに送信する

### デフォルトの出力: アクションにおける「設定より規約」

Railsでは「設定より規約 (CoC: convention over configuration)」というポリシーが推奨されていることをご存じかと思います。デフォルトの出力結果は、CoCのよい例でもあります。Railsのコントローラは、デフォルトでは正しいルーティングに対応する名前を持つビューを自動的に選び、それを使用してレスポンスを出力します。たとえば、`BooksController`というコントローラに以下のコードがあるとします。

```ruby
class BooksController < ApplicationController
end
```

ルーティングファイルに以下が記載されているとします。

```ruby
  resources :books
```

`app/views/books/index.html.erb`ビューファイルの内容が以下のようになっているとします。

```html+erb
<h1>Books are coming soon!</h1>
```

以上のようにすることで、ユーザーがブラウザで`/books`にアクセスすると、Railsは自動的に`app/views/books/index.html.erb`ビューを使用してレスポンスを出力し、その結果「Books are coming soon!」という文字が画面に表示されます。

しかしこの画面だけではほとんど実用性がないので、`Book`モデルを作成し、`BooksController`にindexアクションを追加してみましょう。

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end
```

上のコードでご注目いただきたいのは、「設定より規約」の原則が利いているおかげでindexアクションの最後で明示的に画面出力を指示する必要がないという点です。ここでの原則は、「コントローラのアクションの最終部分で明示的な画面出力が指示されていない場合は、コントローラが使用できるビューのパスから`アクション名.html.erb`というビューテンプレートを探し、それを使用して自動的に出力する」というものです。従って、この場合は`app/views/books/index.html.erb`ファイルが出力されます。

ビューですべての本の属性を表示したい場合は、以下のようにERBを書くことができます。

```html+erb
<h1>Listing Books</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Summary</th>
    <th></th>
    <th></th>
    <th></th>
  </tr>

<% @books.each do |book| %>
  <tr>
    <td><%= book.title %></td>
    <td><%= book.content %></td>
    <td><%= link_to "Show", book %></td>
    <td><%= link_to "Edit", edit_book_path(book) %></td>
    <td><%= link_to "Remove", book, method: :delete, data: { confirm: "Are you sure?" } %></td>
  </tr>
<% end %>
</table>

<br>

<%= link_to "New book", new_book_path %>
```

NOTE: 実際のレンダリングは、`ActionView::TemplateHandlers`のサブクラスで行われます。本ガイドではレンダリングの詳細については触れませんが、テンプレートハンドラの選択がビューテンプレートファイルの拡張子によって制御されているという重要な点は理解しておいてください。Rails 2以降におけるビューテンプレートの標準拡張子は、ERB (HTML + eMbedded RuBy) でレンダリングする場合は`.erb`、Builder (XMLジェネレータ) でレンダリングする場合は`.builder`です。

### `render`を使用する

アプリケーションがブラウザで表示するコンテンツのレンダリング (出力) という力仕事は、`ActionController::Base#render`メソッドがほぼ一手に引き受けています。`render`メソッドはさまざまな方法でカスタマイズできます。Railsテンプレートのデフォルトビューを出力することもできますし、特定のテンプレート、ファイル、インラインコードを指定して出力したり、何も出力しないこともできます。テキスト、JSON、XMLを出力することもできます。出力されるレスポンスのcontent typeやHTTPステータスを指定することもできます。

TIP: 出力結果をブラウザで表示して調べることなく、`render`呼び出しの正確な結果を取得したい場合は、`render_to_string`を呼び出すことができます。このメソッドの動作は`render`と完全に同じであり、出力結果をブラウザに返さずに文字列を返す点だけが異なります。

#### 何も出力しない方法

`render`メソッドでできる最も単純な動作は、何も出力しないことでしょう。

```ruby
render nothing: true
```

このレスポンスをcurlコマンドを使用して調べてみると以下のようになっています。

```bash
$ curl -i 127.0.0.1:3000/books
HTTP/1.1 200 OK
Connection: close
Date: Sun, 24 Jan 2010 09:25:18 GMT
Transfer-Encoding: chunked
Content-Type: */*; charset=utf-8
X-Runtime: 0.014297
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache

$
```

レスポンスの内容は空欄になっています (`Cache-Control`行以降にデータがない) が、ステータスコートが200 OKになっているのでリクエストが成功していることがわかります。renderメソッドの`:status`オプションを設定することでレスポンスを変更できます。何も出力しないというレスポンスは、Ajaxリクエストを使用する時に便利です。これを使用することで、リクエストが成功したという確認応答だけをブラウザに送り返すことができるからです。

TIP: 200 OKヘッダーだけを送信したいのであれば、ここでご紹介した`render :nothing`よりも、本ガイドで後述する`head`メソッドを使用する方がおそらくよいでしょう。`head`メソッドは`render :nothing`よりも柔軟性が高く、HTTPヘッダーだけを生成していることが明確になるからです。

#### Action Viewを出力する

同じコントローラで、デフォルトと異なるテンプレートに対応するビューを出力したい場合は、`render`メソッドでビュー名を指定することができます。

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render "edit"
  end
end
```

上の`update`アクションでモデルに対する`update`メソッドの呼び出しが失敗すると、同じコントローラに用意しておいた別の`edit.html.erb`テンプレートを使用して出力します。

出力するアクションを指定するには、文字列の他にシンボルを使用することもできます。

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render :edit
  end
end
```

#### 別のコントローラからアクションのテンプレートを出力する

あるコントローラのアクションから、まったく別のコントローラの配下にあるテンプレートを使用して出力することは可能でしょうか。これも`render`メソッドだけで行なうことができます。`render`メソッドには`app/views`を起点とするフルパスを渡すことができますので、出力したいテンプレートをフルパスで指定します。たとえば、`app/controllers/admin`に置かれている`AdminProducts`コントローラのコードを実行しているとすると、`app/views/products`に置かれているビューテンプレートに対するアクションの実行結果を出力するには以下のようにします。

```ruby
render "products/show"
```

パスにスラッシュ`/`が含まれていると、Railsによってこのビューは異なるコントローラの配下にあると認識されます。異なるコントローラのテンプレートを指定していることをより明示的にしたい場合は、以下のように`:template`オプションを使用することもできます (Rails 2.2以前ではこのオプションは必須でした)。

```ruby
render template: "products/show"
```

#### 任意のファイルを使用して出力する

`render`メソッドで指定するビューは、現在のアプリケーションディレクトリの外部にあっても構いません (2つのRailsアプリケーションでビューを共有しているなどの場合)。

```ruby
render "/u/apps/warehouse_app/current/app/views/products/show"
```

パスがスラッシュ`/`で始まっている場合、Railsはこのコードがファイルの出力であると認識します。ファイルを出力することをより明示的にしたい場合は、以下のように`:file`オプションを使用することもできます (Rails 2.2以前ではこのオプションは必須でした)。

```ruby
render file: "/u/apps/warehouse_app/current/app/views/products/show"
```

`:file`オプションに与えるパスは、ファイルシステムの絶対パスです。当然ながら、コンテンツを出力したいファイルに対して適切なアクセス権が与えられている必要があります。

NOTE: ファイルを出力する場合、デフォルトでは現在のレイアウトが適用されません。ファイルの出力を現在のレイアウト内で行いたい場合は、`layout: true`オプションを追加する必要があります。

TIP: Microsoft Windows上でRailsを実行している場合、ファイルを出力する際に`:file`オプションを省略できません。Windowsのファイル名フォーマットはUnixのファイル名と同じではないためです。

#### まとめ

これまでご紹介した3通りの出力方法 (コントローラ内の別テンプレートを使用、別のコントローラのテンプレートを使用、ファイルシステム上の任意のファイルを使用) は、実際には同一のアクションのバリエーションにすぎません。

実のところ、たとえばBooksControllerクラスのupdateアクション内で、本の更新に失敗したらeditテンプレートを出力したいとすると、以下のどのレンダリング呼び出しを行っても最終的には必ず`views/books`ディレクトリの`edit.html.erb`を使用して出力が行われます。

```ruby
render :edit
render action: :edit
render "edit"
render "edit.html.erb"
render action: "edit"
render action: "edit.html.erb"
render "books/edit"
render "books/edit.html.erb"
render template: "books/edit"
render template: "books/edit.html.erb"
render "/path/to/rails/app/views/books/edit"
render "/path/to/rails/app/views/books/edit.html.erb"
render file: "/path/to/rails/app/views/books/edit"
render file: "/path/to/rails/app/views/books/edit.html.erb"
```

どの呼び出しを使用するかはコーディングのスタイルと規則の問題でしかありませんが、経験上なるべくシンプルな記法を使用する方がコードがわかりやすくなるでしょう。

#### `render`で`:inline`オプションを使用する

`render`メソッドは、メソッド呼び出しの際に`:inline`オプションを使用してERBを与えると、ビューがまったくない状態でも実行することができます。これは完全に有効な方法です。

```ruby
render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>"
```

WARNING: このオプションを実際に使用する意味はほぼないと思われます。コントローラのコードにERBを混在させると、RailsのMVC指向が崩されるだけでなく、開発者がプロジェクトのロジックを追いかけることが困難になってしまいます。通常のERBビューを使用してください。

インラインでは、デフォルトでERBを使用して出力を行います。`:type`オプションで:builderを指定すると、ERBに代えてBuilderが使用されます。

```ruby
render inline: "xml.p {'Horrid coding practice!'}", type: :builder
```

#### テキストを出力する

`render`で`:plain`オプションを使用すると、平文テキストをマークアップせずにブラウザに送信することができます。

```ruby
render plain: "OK"
```

TIP: 平文テキストの出力は、AjaxやWebサービスリクエストに応答するときに最も有用です。これらではHTML以外の応答を期待しています。

NOTE: デフォルトでは、`:plain`オプションを使用すると出力結果に現在のレイアウトが適用されません。テキストの出力を現在のレイアウト内で行いたい場合は、`layout: true`オプションを追加する必要があります。

#### HTMLを出力する

`render`で`:html`オプションを使用すると、HTML文字列を直接ブラウザに送信することができます。

```ruby 
render html: "<strong>Not Found</strong>".html_safe
```

TIP: この手法は、HTMLコードのごく小規模なスニペットを出力したい場合に便利です。
スニペットのマークアップが複雑になるようであれば、早めにテンプレートファイルに移行することをご検討ください。

NOTE: このオプションを使用すると、文字列が「HTML safe」でない場合にHTML要素をエスケープします。

#### JSONを出力する

JSONはJavaScriptのデータ形式の一種で、多くのAjaxライブラリで使用されています。Railsでは、オブジェクトからJSON形式への変換と、変換されたJSONをブラウザに送信する機能がビルトインでサポートされています。

```ruby
render json: @product
```

TIP: 出力するオブジェクトに対して`to_json`を呼び出す必要はありません。`:json`オプションが指定されていれば、`render`によって`to_json`が自動的に呼び出されるようになっています。

#### XMLを出力する

Railsでは、オブジェクトからXML形式への変換と、変換されたXMLをブラウザに送信する機能がビルトインでサポートされています。

```ruby
render xml: @product
```

TIP: 出力するオブジェクトに対して`to_xml`を呼び出す必要はありません。`:xml`オプションが指定されていれば、`render`によって`to_xml`が自動的に呼び出されるようになっています。

#### Vanilla JavaScriptを出力する

Railsはvanilla JavaScriptを出力することもできます。

```ruby
render js: "alert('Hello Rails');"
```

上のコードは、引数で与えられた文字列をMIMEタイプ`text/javascript`でブラウザに送信します。

#### 生のコンテンツを出力する

`render`で`:body`オプションを指定することで、content typeを一切指定しない生のコンテンツをブラウザに送信することができます。

```ruby
render body: "raw"
```

TIP: このオプションを使用するのは、レスポンスのcontent typeがどんなものであってもよい場合のみにしてください。ほとんどの場合、`:plain`や`:html`などを使用する方が適切です。

NOTE: このオプションを使用してブラウザに送信されるレスポンスは、上書きされない限り`text/html`が使用されます。これはAction Dispatchによるレスポンスのデフォルトのcontent typeであるためです。

#### `render`のオプション

`render`メソッドに対する呼び出しでは、一般に以下の4つのオプションが使用できます。

* `:content_type`
* `:layout`
* `:location`
* `:status`

##### `:content_type`オプション

Railsがデフォルトで出力する結果のMIME content-typeは、デフォルトで`text/html`になります (ただし`:json`を指定した場合には`application/json`、`:xml`を使用した場合は`application/xml`になります)。content-typeを変更したい場合は、`:content_type`オプションを指定します。

```ruby
render file: filename, content_type: "application/rss"
```

##### `:layout`オプション

`render`で指定できるほとんどのオプションでは、出力されるコンテンツは現在のレイアウトの一部としてブラウザ上で表示されます。これより、レイアウトの詳細と利用法について本ガイドで説明します。

`:layout`オプションを指定すると、現在のアクションに対して特定のファイルをレイアウトとして使用します。

```ruby
render layout: "special_layout"
```

出力時にレイアウトをまったく使用しないよう指定することもできます。

```ruby
render layout: false
```

##### `:location`オプション

`:location`を使用することで、HTTPの`Location`ヘッダーを設定できます。

```ruby
render xml: photo, location: photo_url(photo)
```

##### `:status`オプション

Railsが返すレスポンスのHTTPステータスコードは自動的に生成されます (ほとんどの場合`200 OK`となります)。`:status`オプションを使用することで、レスポンスのステータスコードを変更できます。

```ruby
render status: 500
render status: :forbidden
```

ステータスコードは数字で指定する他に、以下に示すシンボルで指定することもできます。

| レスポンスクラス      | HTTPステータスコード | シンボル                           |
| ------------------- | ---------------- | -------------------------------- |
| **Informational**   | 100              | :continue                        |
|                     | 101              | :switching_protocols             |
|                     | 102              | :processing                      |
| **Success**         | 200              | :ok                              |
|                     | 201              | :created                         |
|                     | 202              | :accepted                        |
|                     | 203              | :non_authoritative_information   |
|                     | 204              | :no_content                      |
|                     | 205              | :reset_content                   |
|                     | 206              | :partial_content                 |
|                     | 207              | :multi_status                    |
|                     | 208              | :already_reported                |
|                     | 226              | :im_used                         |
| **Redirection**     | 300              | :multiple_choices                |
|                     | 301              | :moved_permanently               |
|                     | 302              | :found                           |
|                     | 303              | :see_other                       |
|                     | 304              | :not_modified                    |
|                     | 305              | :use_proxy                       |
|                     | 306              | :reserved                        |
|                     | 307              | :temporary_redirect              |
|                     | 308              | :permanent_redirect              |
| **Client Error**    | 400              | :bad_request                     |
|                     | 401              | :unauthorized                    |
|                     | 402              | :payment_required                |
|                     | 403              | :forbidden                       |
|                     | 404              | :not_found                       |
|                     | 405              | :method_not_allowed              |
|                     | 406              | :not_acceptable                  |
|                     | 407              | :proxy_authentication_required   |
|                     | 408              | :request_timeout                 |
|                     | 409              | :conflict                        |
|                     | 410              | :gone                            |
|                     | 411              | :length_required                 |
|                     | 412              | :precondition_failed             |
|                     | 413              | :request_entity_too_large        |
|                     | 414              | :request_uri_too_long            |
|                     | 415              | :unsupported_media_type          |
|                     | 416              | :requested_range_not_satisfiable |
|                     | 417              | :expectation_failed              |
|                     | 422              | :unprocessable_entity            |
|                     | 423              | :locked                          |
|                     | 424              | :failed_dependency               |
|                     | 426              | :upgrade_required                |
|                     | 428              | :precondition_required           |
|                     | 429              | :too_many_requests               |
|                     | 431              | :request_header_fields_too_large |
| **Server Error**    | 500              | :internal_server_error           |
|                     | 501              | :not_implemented                 |
|                     | 502              | :bad_gateway                     |
|                     | 503              | :service_unavailable             |
|                     | 504              | :gateway_timeout                 |
|                     | 505              | :http_version_not_supported      |
|                     | 506              | :variant_also_negotiates         |
|                     | 507              | :insufficient_storage            |
|                     | 508              | :loop_detected                   |
|                     | 510              | :not_extended                    |
|                     | 511              | :network_authentication_required |

#### レイアウトの探索順序

Railsは現在のレイアウトを探索する場合、最初に現在のコントローラと同じ基本名を持つレイアウトが`app/views/layouts`ディレクトリにあるかどうかを調べます。たとえば、`PhotosController`クラスのアクションから出力するのであれば、`app/views/layouts/photos.html.erb`または`app/views/layouts/photos.builder`を探します。該当のコントローラに属するレイアウトがない場合、`app/views/layouts/application.html.erb`または`app/views/layouts/application.builder`を使用します。`.erb`レイアウトがない場合、`.builder`レイアウトがあればそれを使用します。Railsには、各コントローラやアクションに割り当てる特定のレイアウトをもっと正確に指定する方法がいくつも用意されています。

##### コントローラ用のレイアウトを指定する

`layout`宣言を使用することで、デフォルトのレイアウト名ルールを上書きすることができます。例: 

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

この宣言によって、`ProductsController`からの出力で使用されるレイアウトは`app/views/layouts/inventory.html.erb`になります。

アプリケーション全体で特定のレイアウトを使用したい場合は、`ApplicationController`クラスで`layout`を宣言します。

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

この宣言によって、アプリケーションのすべてのビューで使用されるレイアウトは`app/views/layouts/main.html.erb`になります。

##### 実行時にレイアウトを指定する

レイアウトの指定にシンボルを使用することで、リクエストが実際に処理されるときまでレイアウトを確定せず、選択を遅延することができます。

```ruby
class ProductsController < ApplicationController
  layout :products_layout

  def show
    @product = Product.find(params[:id])
  end

  private
    def products_layout
      @current_user.special? ? "special" : "products"
    end

end
```

上のコードは、現在のユーザーが特別なユーザーの場合、そのユーザーが製品ページを見るときに特別なレイアウトを適用します。

レイアウトを決定する際に、Procなどのインラインメソッドを使用することもできます。たとえばProcオブジェクトを渡すと、Procを渡されたブロックには`controller`インスタンスが渡されます。これにより、現在のリクエストを元にしてレイアウトを決定することができます。

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

##### 条件付きレイアウト

コントローラレベルで指定されたレイアウトでは、`:only`オプションと`:except`オプションがサポートされています。これらのオプションは、単一のメソッド名またはメソッド名の配列を引数として受け取ります。渡すメソッド名はコントローラ内のメソッド名に対応します。

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

上の宣言によって、`rss`メソッドと`index`メソッド以外のすべてのメソッドに`product`レイアウトが適用されます。

##### レイアウトの継承

レイアウト宣言は下の階層に継承されます。下の階層、つまりより具体的なレイアウト宣言は、上の階層、つまりより一般的なレイアウトよりも常に優先されます。例: 

* `application_controller.rb`

    ```ruby
class ApplicationController < ActionController::Base
      layout "main"
    end
    ```

* `posts_controller.rb`

    ```ruby
    class PostsController < ApplicationController
    end
    ```

* `special_posts_controller.rb`

    ```ruby
    class SpecialPostsController < PostsController
      layout "special"
    end
    ```

* `old_posts_controller.rb`

    ```ruby
    class OldPostsController < SpecialPostsController
      layout false

      def show
        @post = Post.find(params[:id])
      end

      def index
        @old_posts = Post.older
        render layout: "old"
      end
      # ...
    end
    ```

上のアプリケーションは以下のように動作します。

* ビューの出力には基本的に`main`レイアウトが使用されます。
* `PostsController#index`では`main`レイアウトが使用されます。
* `SpecialPostsController#index`では`special`レイアウトが使用されます。
* `OldPostsController#show`ではレイアウトが適用されません。
* `OldPostsController#index`では`old`レイアウトが使用されます。

#### 二重レンダリングエラーを避ける

Rails開発をやっていれば、一度は "Can only render or redirect once per action" エラーに遭遇したことがあるでしょう。いまいましいエラーですが、修正は比較的簡単です。このエラーはほとんどの場合、開発者が`render`メソッドの基本的な動作を誤って理解していることが原因です。

このエラーを発生する以下のコードを例にとって説明しましょう。

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  render action: "regular_show"
end
```

`@book.special?`が`true`の場合、Railsはレンダリングを開始し、`@book`変数を`special_show`ビューに転送します。しかし、`show`アクションのコードはそこで _止まらない_ ことにご注意ください。`show`アクションのコードは最終行まで実行され、`regular_show`ビューのレンダリングを行おうとした時点でエラーが発生します。解決法はいたって単純です。1つのコード実行パス内では、`render`メソッドや`redirect`メソッドの実行は1度だけにしてください。ここで非常に便利なのが`and return`というメソッドです。このメソッドを使用して修正したバージョンを以下に示します。

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show" and return
  end
  render action: "regular_show"
end
```

`&& return`ではなく`and return`を使用してください。`&& return`はRuby言語の&&演算子の優先順位が高すぎてこの文脈では正常に動作しません。

RailsにビルトインされているActionControllerが行なう暗黙のレンダリングでは、`render`メソッドが呼び出されたかどうかを確認してからレンダリングを開始します。従って、以下のコードは正常に動作します。

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
end
```

上のコードは、ある本が`special?`である場合にのみ`special_show`テンプレートを使用して出力します。それ以外の場合は`show`テンプレートを使用して出力します。

### `redirect_to`を使用する

HTTPリクエストにレスポンスを返すもう一つの方法は、`redirect_to`を使用することです。前述のとおり、`render`はレスポンス構成時にどのビュー (または他のアセット) を使用するかを指定するためのものです。`redirect_to`メソッドは、この点において`render`メソッドと根本的に異なります。`redirect_to`メソッドは、別のURLに対して改めてリクエストを再送信するよう、ブラウザに指令を出すためのものです。たとえば以下の呼び出しを行なうと、アプリケーションで現在どのページが表示されていても、写真のインデックス表示ページにリダイレクトされます。

```ruby 
redirect_to photos_url
```

`redirect_to`の引数にはどんな値も指定できますが、`link_to`や`url_for`を使用するのが普通です。ユーザーを直前のページに戻す、特殊なリダイレクトも行えます。

```ruby
redirect_to :back
```

#### リダイレクトのステータスコードを変更する

`redirect_to`を呼び出すと、一時的なリダイレクトを意味するHTTPステータスコード302がブラウザに返され、ブラウザはそれに基いてリダイレクトを行います。別のステータスコード (301: 恒久的なリダイレクトがよく使われます) に変更するには`:status`オプションを使用します。

```ruby
redirect_to photos_path, status: 301
```

`render`の`:status`オプションの場合と同様、`redirect_to`の`:status`もヘッダーを指定する時に数値の他にシンボルも使用できます。

#### `render`と`redirect_to`の違い

ときおり、`redirect_to`を一種の`goto`コマンドとして理解している開発初心者を見かけます。Railsコードの実行位置をある場所から別の場所に移動するコマンドであると考えているわけです。これは _正しくありません_ 。`redirect_to`を実行した後、コードはそこで実行を終了し、ブラウザからの次のリクエストを待ちます (通常のスタンバイ状態)。その直後、`redirect_to`でブラウザに送信したHTTPステータスコード302に従って、ブラウザから別のURLへのリクエストがサーバーに送信され、サーバーはそのリクエストを改めて処理します。それ以外のことは行っていません。

`render`と`redirect_to`の違いを以下のアクションで比較してみましょう。

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    render action: "index"
  end
end
```

上のフォームのコードでは、`@book`インスタンス変数が`nil`場合に問題が生じる可能性があります。`render :action`は対象となるアクションのコードを実行しないことを思い出してください。従って、`index`ビューでおそらく必要となる`@books`インスタンス変数には何も設定されず、空の蔵書リストが表示されてしまいます。これを修正する方法のひとつは、renderをredirectに変更することです。

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    redirect_to action: :index
  end
end
```

上のコードであれば、ブラウザから改めてindexページにリクエストが送信されるので、`index`メソッドのコードが正常に実行されます。

上のコードで1つ残念な点があるとすれば、ブラウザとのやりとりが1往復増えることです。ブラウザから`/books/1`に対してshowアクションが呼び出され、コントローラが本が1冊もないことを検出すると、コントローラはブラウザに対してステータスコード302 (リダイレクト) レスポンスを返し、`/books/`に再度アクセスするようブラウザに指令を出します。ブラウザはこの指令に応じ、このコントローラの`index`アクションを呼び出すためのリクエストを改めてサーバーに送信します。そしてコントローラはこのリクエストを受けてデータベースからすべての蔵書リストを取り出し、indexテンプレートをレンダリングして出力結果をブラウザに送り返すと、ブラウザで蔵書リストが表示されます。

このやりとりの増加による遅延は、小規模なアプリケーションであればおそらく問題になりませんが、遅延が甚だしくなってきた場合にはこの点を改める必要があるかもしれません。ブラウザとのやりとりを増やさないように工夫した例を以下に示します。

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    @books = Book.all
    flash.now[:alert] = "Your book was not found"
    render "index"
  end
end
```

上のコードの動作は次のとおりです。指定されたidを持つ本が見つからない場合は、モデル内のすべての蔵書リストを`@books`インスタンス変数に保存します。続いてflashによる警告メッセージを追加し、さらに`index.html.erb`テンプレートを直接レンダリングしてから出力結果をブラウザに送り返します。

### `head`でヘッダのみのレスポンスを生成する

`head`メソッドを使用することで、ヘッダだけで本文 (body) のないレスポンスをブラウザに送信できます。このメソッド名は`render :nothing`よりも動作を明確に表しています。`head`メソッドには、HTTPステータスコードを示す多くのシンボルを引数として指定できます ([参照テーブル](#:statusオプション) 参照)。オプションの引数はヘッダ名と値をペアにしたハッシュ値として解釈されます。たとえば、以下のコードはエラーヘッダーのみのレスポンスを返すことができます。

```ruby
head :bad_request
```

上のコードによって以下のヘッダーが生成されます。

```
HTTP/1.1 400 Bad Request
Connection: close
Date: Sun, 24 Jan 2010 12:15:53 GMT
Transfer-Encoding: chunked
Content-Type: text/html; charset=utf-8
X-Runtime: 0.013483
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

以下のように、ヘッダーに別の情報を含めることもできます。

```ruby
head :created, location: photo_path(@photo)
```

上のコードの結果は以下のようになります。

```
HTTP/1.1 201 Created
Connection: close
Date: Sun, 24 Jan 2010 12:16:44 GMT
Transfer-Encoding: chunked
Location: /photos/1
Content-Type: text/html; charset=utf-8
X-Runtime: 0.083496
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

レイアウトを構成する
-------------------

Railsがビューからレスポンスを出力するときには、そのビューには現在のレイアウトも組み込まれます。現在のレイアウトを探索するときのルールは、本ガイドで既に説明したものが使用されます。レイアウト内では、さまざまな出力の断片を組み合わせて最終的なレスポンス出力を得るための3つのツールを利用できます。

* Asset tags
* `yield` and `content_for`
* Partials

### アセットタグヘルパー

アセットタグヘルパーが提供するメソッドは、フィード、JavaScript、スタイルシート、画像、動画および音声のビューにリンクするHTMLを生成するためのものです。Railsでは以下の6つのアセットタグヘルパーが利用できます。

* `auto_discovery_link_tag`
* `javascript_include_tag`
* `stylesheet_link_tag`
* `image_tag`
* `video_tag`
* `audio_tag`

これらのタグは、レイアウトや別のビューで使用することもできます。このうち、`auto_discovery_link_tag`、`javascript_include_tag`、`stylesheet_link_tag`はレイアウトの`<head>`セクションで使用するのが普通です。

WARNING: これらのアセットタグヘルパーは、指定の場所にアセットがあるかどうかを _検証しません_ 。

#### `auto_discovery_link_tag`を使用してフィードにリンクする

`auto_discovery_link_tag`ヘルパーを使用すると、多くのブラウザやフィードリーダーでRSSフィードやAtomフィードを検出できるHTMLが生成されます。このメソッドが受け取れる引数は、リンクの種類 (`:rss`または`:atom`)、url_forで渡されるオプションのハッシュ、およびタグのハッシュです。

```erb
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

`auto_discovery_link_tag`では以下の3つのタグオプションが使用できます。

* `:rel`はリンク内の`rel`値を指定します。デフォルト値は "alternate" です。
* `:type`はMIMEタイプを明示的に指定したい場合に使用します。通常、Railsは適切なMIMEタイプを自動的に生成します。
* `:title`はリンクのタイトルを指定します。デフォルト値は`:type`値を大文字にしたものです ("ATOM" や "RSS" など)。

#### `javascript_include_tag`を使用してJavaScriptファイルにリンクする

`javascript_include_tag`ヘルパーは、指定されたソースごとにHTML `script`タグを返します。

Railsで[アセットパイプライン](asset_pipeline.html) を有効にしている場合、JavaScriptへのリンク先は旧Railsの`public/javascripts`ではなく`/assets/javascripts/`になります。その後このリンクはアセットパイプラインによって利用可能になります。

Railsアプリケーション内やRailsエンジン内のJavaScriptファイルは、`app/assets`、`lib/assets`、`vendor/assets`のいずれかの場所に置かれます。これらの置き場所の詳細については、[アセットパイプラインガイドの「アセットの編成」](asset_pipeline.html#アセットの編成) を参照してください。

好みに応じて、ドキュメントルートからの相対フルパスやURLを指定することもできます。たとえば、`app/assets`、`lib/assets`、または`vendor/assets`の下にある`javascripts`の下にあるJavaScriptファイルにリンクしたい場合は以下のようにします。

```erb
<%= javascript_include_tag "main" %>
```

上のコードにより、以下のような`script`タグが出力されます。

```html
<script src='/assets/main.js'></script>
```

このアセットへのリクエストは、Sprockets gemによって提供されます。

複数のファイルにアクセスしたい場合 (`app/assets/javascripts/main.js`と`app/assets/javascripts/columns.js`など) は以下のようにします。

```erb
<%= javascript_include_tag "main", "columns" %>
```

`app/assets/javascripts/main.js`と`app/assets/javascripts/photos/columns.js`を含めたい場合は以下のようにします。

```erb
<%= javascript_include_tag "main", "/photos/columns" %>
```

`http://example.com/main.js`を含めるには以下のようにします。

```erb
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### `stylesheet_link_tag`を使用してCSSファイルにリンクする

`stylesheet_link_tag`ヘルパーは、提供されたソースごとにHTML `<link>`タグを返します。

Railsでアセットパイプラインを有効にしている場合、このヘルパーは`/assets/stylesheets/`へのリンクを生成します。その後このリンクはSprockets gemによって処理されます。スタイルシートファイルは、`app/assets`、`lib/assets`、または`vendor/assets`のいずれかの場所に置かれます。

ドキュメントルートからの相対フルパスやURLを指定することもできます。たとえば、`app/assets`、`lib/assets`、または`vendor/assets`の下にある`stylesheets`の下にあるスタイルシートファイルにリンクしたい場合は以下のようにします。

```erb
<%= stylesheet_link_tag "main" %>
```

`app/assets/stylesheets/main.css`と`app/assets/stylesheets/columns.css`を含めるには、以下のようにします。

```erb
<%= stylesheet_link_tag "main", "columns" %>
```

`app/assets/stylesheets/main.css`と`app/assets/stylesheets/photos/columns.css`を含めるには以下のようにします。

```erb
<%= stylesheet_link_tag "main", "photos/columns" %>
```

`http://example.com/main.css`を含めるには以下のようにします。

```erb
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

デフォルトでは、`stylesheet_link_tag`によって作成されるリンクには`media="screen" rel="stylesheet"`という属性が含まれます。適切なオプション (`:media`, `:rel`) を使用することで、これらのデフォルト値を上書きできます。

```erb
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### `image_tag`を使用して画像にリンクする

`image_tag`は、特定のファイルを指すHTML `<img />`タグを生成します。デフォルトでは、ファイルは`public/images`以下から読み込まれます。

WARNING: 画像ファイルの拡張子は省略できません。

```erb
<%= image_tag "header.png" %>
```

好みに応じて、画像ファイルへのパスを直接指定することもできます。

```erb
<%= image_tag "icons/delete.gif" %>
```

ハッシュ形式で与えられたHTMLオプションを追加することもできます。

```erb
<%= image_tag "icons/delete.gif", {height: 45} %>
```

ユーザーがブラウザで画像を非表示にしている場合、alt属性のテキストを表示することができます。alt属性が明示的に指定されていない場合は、ファイル名がaltテキストとして使用されます。このときファイル名の先頭は大文字になり、拡張子は取り除かれます。たとえば、以下の2つのimage_tagヘルパーは同じコードを返します。

```erb
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

"{幅}x{高さ}"という形式で特殊なsizeタグを指定することもできます。

```erb
<%= image_tag "home.gif", size: "50x20" %>
```

上の特殊タグ以外にも、`:class`や`:id`や`:name`などの標準的なHTMLオプションを最終的にハッシュにしたものを引数として与えることができます。

```erb
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### `video_tag`を使用してビデオにリンクする

`video_tag`ヘルパーは、指定されたファイルを指すHTML 5 `<video>`タグを生成します。デフォルトでは、ファイルは`public/videos`から読み込まれます。

```erb
<%= video_tag "movie.ogg" %>
```

上のコードによって以下が生成されます。

```erb
<video src="/videos/movie.ogg" />
```

`image_tag`の場合と同様、絶対パスまたは`public/videos`ディレクトリからの相対パスを指定できます。さらに、`image_tag`の場合と同様に、`size: "#{幅}x#{高さ}"`オプションを指定することもできます。ビデオタグでは、`id`や`class`などのHTMLオプションを末尾で自由に指定することもできます。

ビデオタグでは、`<video>` HTMLオプションを以下のようなHTMLオプションハッシュ形式で指定することもできます。

* `poster: "image_name.png"`は、ビデオ再生前にビデオの位置に表示しておきたい画像を指定します。
* `autoplay: true`は、ページの読み込み時にビデオを再生します。
* `loop: true`は、ビデオを最後まで再生し終わったらループします。
* `controls: true`は、ブラウザが提供するビデオ制御機能を使用できるようにします。
* `autobuffer: true`は、ページ読み込み時にすぐ再生できるようにビデオを事前に読み込んでおきます。

`video_tag`にビデオファイルの配列を渡すことで、複数のビデオを再生することもできます。

```erb
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

上のコードによって以下が生成されます。

```erb
<video><source src="trailer.ogg" /><source src="movie.ogg" /></video>
```

#### `audio_tag`を使用して音声ファイルにリンクする

`audio_tag`は、指定されたファイルを指すHTML 5 `<audio>`タグを生成します。デフォルトでは、これらのファイルは`public/audios`以下から読み込まれます。

```erb
<%= audio_tag "music.mp3" %>
```

好みに応じて、音声ファイルへのパスを直接指定することもできます。

```erb
<%= audio_tag "music/first_song.mp3" %>
```

`:id`や`:class`などのオプションをハッシュ形式で指定することもできます。

`video_tag`の場合と同様、`audio_tag`にも以下の特殊オプションがあります。

* `autoplay: true`はページ読み込み時に音声ファイルを再生します。
* `controls: true`は、ブラウザが提供する音声ファイル制御機能を使用できるようにします。
* `autobuffer: true`は、ページ読み込み時にすぐ再生できるように音声ファイルを事前に読み込んでおきます。

### `yield`を理解する

`yield`メソッドは、レイアウトのコンテキストでビューを挿入すべき場所を指定するのに使用します。`yield`の最も単純な使用法は、`yield`を1つだけ使用して、現在レンダリングされているビューのコンテンツ全体をその場所に挿入するというものです。

```html+erb
<html>
  <head>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

`yield`を行なう領域を複数使用するレイアウトを作成することもできます。

```html+erb
<html>
  <head>
  <%= yield :head %>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

ビューのメイン部分は常に「名前のない」`yield`としてレンダリングされます。コンテンツを名前付きの`yield`としてレンダリングするには、`content_for`メソッドを使用します。

### `content_for`を使用する

`content_for`メソッドを使用することで、コンテンツを名前付きの`yield`ブロックとしてレイアウトに挿入できます。たとえば、以下のビューのレンダリング結果は上で紹介したレイアウト内に挿入されます。

```html+erb
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

このページのレンダリング結果がレイアウトに挿入されると、最終的に以下のHTMLが出力されます。

```html+erb
<html>
  <head>
  <title>A simple page</title>
  </head>
  <body>
  <p>Hello, Rails!</p>
  </body>
</html>
```

`content_for`メソッドは、たとえばレイアウトが「サイドバー」や「フッター」などの領域に分かれていて、それらに異なるコンテンツを挿入したいような場合に大変便利です。あるいは、多くのページで使用する共通のヘッダーがあり、このヘッダーに特定のページでのみJavaScriptやCSSファイルを挿入したい場合にも便利です。

### パーシャルを使用する

部分テンプレートは通常単にパーシャルと呼ばれます。パーシャルは、上とは異なる方法でレンダリング処理を扱いやすい単位に分割するためのしくみです。パーシャルを使用すると、レスポンスで表示するページの特定部分をレンダリングするためのコードを別ファイルに保存しておくことができます。

#### パーシャルに名前を与える

パーシャルをビューの一部に含めて出力するには、ビュー内で`render`メソッドを使用します。

```ruby
<%= render "menu" %>
```

レンダリング中のビュー内に置かれている上のコードは、その場所で`_menu.html.erb`という名前のファイルをレンダリングします。パーシャルファイル名の冒頭にはアンダースコアが付いていることにご注意ください。これは通常のビューと区別するために付けられています。ただしrenderで呼び出す際にはこのアンダースコアは不要です。以下のように、他のフォルダの下にあるパーシャルを呼び出す際にもアンダースコアは不要です。

```ruby
<%= render "shared/menu" %>
```

上のコードは、`app/views/shared/_menu.html.erb`パーシャルの内容をその場所でレンダリングします。

#### シンプルなビューでパーシャルを使用する

パーシャルの使用方法の1つは、パーシャルを一種のサブルーチンのようにみなすことです。詳細な表示内容をパーシャル化してビューから追い出し、コードを読みやすくします。例として、以下のようなビューがあるとします。

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
...

<%= render "shared/footer" %>
```

上のコードの`_ad_banner.html.erb`パーシャルと`_footer.html.erb`パーシャルに含まれるコンテンツは、アプリケーションの多くのページと共有できます。あるページを開発中、パーシャルの部分については詳細を気にせずに済みます。

TIP: すべてのページで共有されているコンテンツであれば、パーシャルをレイアウトで使用することができます。

#### パーシャルレイアウト

ビューにレイアウトがあるのと同様、パーシャルでも独自のレイアウトファイルを使用することができます。たとえば、以下のようなパーシャルを呼び出すとします。

```erb
<%= render partial: "link_area", layout: "graybar" %>
```

上のコードは、`_link_area.html.erb`という名前のパーシャルを探し、`_graybar.html.erb`という名前のレイアウトを使用してレンダリングを行います。パーシャルレイアウトは、対応する通常のパーシャルと同様、名前の先頭にアンダースコアを追加する必要があります。そして、パーシャルとそれに対応するパーシャルレイアウトは同じディレクトリに置く必要があります。パーシャルレイアウトは`layouts`フォルダーには置けませんのでご注意ください。

`:layout`などの追加オプションを渡す場合は、`:partial`オプションを明示的に指定する必要がある点にもご注意ください。

#### ローカル変数を渡す

パーシャルにローカル変数を引数として渡し、パーシャルをさらに強力かつ柔軟にすることもできます。たとえば、newページとeditページの違いがごくわずかしかないのであれば、この手法を使用してコードの重複を解消することができます。

* `new.html.erb`

    ```html+erb
    <h1>New zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `edit.html.erb`

    ```html+erb
    <h1>Editing zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `_form.html.erb`

    ```html+erb
    <%= form_for(zone) do |f| %>
      <p>
        <b>Zone name</b><br>
        <%= f.text_field :name %>
      </p>
      <p>
        <%= f.submit %>
      </p>
    <% end %>
    ```

上の2つのビューでは同じパーシャルがレンダリングされますが、Action Viewのsubmitヘルパーはnewアクションの場合には"Create Zone"を返し、editアクションの場合は"Update Zone"を返します。

どのパーシャルにも、パーシャル名からアンダースコアを取り除いた名前を持つローカル変数が与えられます。`:object`オプションを使用することで、このローカル変数にオブジェクトを渡すことができます。

```erb
<%= render partial: "customer", object: @new_customer %>
```

上の`customer`パーシャル呼び出しでは、`customer`ローカル変数は親のビューの`@new_customer`変数を指します。

あるモデルのインスタンスをパーシャルとしてレンダリングするのであれば、以下のような略記法を使用できます。

```erb
<%= render @customer %>
```

上のコードでは、`@customer`インスタンス変数に`Customer`モデルのインスタンスが含まれているとします。この場合レンダリングには`_customer.html.erb`パーシャルが使用され、このパーシャルには`customer`ローカル変数が渡されます。この`customer`ローカル変数は、親ビューにある`@customer`インスタンス変数を指します。

#### コレクションをレンダリングする

パーシャルはデータの繰り返し (コレクション) を出力する場合にもきわめて便利です。`:collection`オプションを使用してパーシャルにコレクションを渡すと、コレクションのメンバごとにパーシャルがレンダリングされて挿入されます。

* `index.html.erb`

    ```html+erb
    <h1>Products</h1>
    <%= render partial: "product", collection: @products %>
    ```

* `_product.html.erb`

    ```html+erb
    <p>Product Name: <%= product.name %></p>
    ```

パーシャルを呼び出す時に指定するコレクションが複数形の場合、パーシャルの個別のインスタンスから、出力するコレクションの個別のメンバにアクセスが行われます。このとき、パーシャル名に基づいた名前を持つ変数が使用されます。上の場合、パーシャルの名前は`_product`であり、この`_product`パーシャル内で`product`という名前の変数を使用して、出力されるインスタンスを取得できます。

このメソッドには略記法もあります。`@products`が`product`インスタンスのコレクションであるとすると、`index.html.erb`に以下のように書くことで同じ結果を得られます。

```html+erb
<h1>Products</h1>
<%= render @products %>
```

使用するパーシャル名は、コレクション内のモデル名に基いて決定されます。実は、メンバが一様でない (さまざまな種類のメンバが入り混じった) コレクションにも上の方法を使用できます。この場合、コレクションのメンバに応じて適切なパーシャルが自動的に選択されます。

* `index.html.erb`

    ```html+erb
    <h1>Contacts</h1>
    <%= render [customer1, employee1, customer2, employee2] %>
    ```

* `customers/_customer.html.erb`

    ```html+erb
    <p>Customer: <%= customer.name %></p>
    ```

* `employees/_employee.html.erb`

    ```html+erb
    <p>Employee: <%= employee.name %></p>
    ```

上のコードでは、コレクションのメンバに応じて、customerパーシャルまたはemployeeパーシャルが自動的に選択されます。

コレクションが空の場合、`render`はnilを返します。以下のような簡単な方法でもよいので、代わりのコンテンツを表示するようにしましょう。

```html+erb
<h1>Products</h1>
<%= render(@products) || "There are no products available." %>
```

#### ローカル変数

パーシャル内のローカル変数をカスタマイズしたい場合は、パーシャルの呼び出し時に`:as`オプションを指定します。

```erb
<%= render partial: "product", collection: @products, as: :item %>
```

上のように変更することで、`@products`コレクションのインスタンスに`item`という名前のローカル変数経由でアクセスできます。

`locals: {}`オプションを使用することで、レンダリング中のどのパーシャルにも任意の名前のローカル変数を渡すことができます。

```erb
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

上の場合、`title`という名前のローカル変数に"Products Page"という値が含まれており、パーシャルからこの値にアクセスできます。

TIP: コレクションによって呼び出されるパーシャル内でカウンタ変数を使用することもできます。このカウンタ変数は、コレクション名の後ろに`_counter`を追加した名前になります。たとえば、パーシャル内で`@products`をレンダリングした回数を`product_counter`変数で参照できます。ただし、このオプションは`as: :value`オプションと併用できません。

`:spacer_template`オプションを使用することで、メインパーシャルのインスタンスと交互にレンダリングされるセカンドパーシャルを指定することもできます。

#### スペーサーテンプレート

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

上のコードでは、`_product`パーシャルと`_product`パーシャルの合間に`_product_ruler`パーシャル (引数なし) をレンダリングします。

#### コレクションパーシャルレイアウト

コレクションをレンダリングするときにも`:layout`オプションを指定できます。

```erb
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

このレイアウトは、コレクション内の各項目をレンダリングするたびに一緒にレンダリングされます。パーシャル内の場合と同様、このレイアウトでも現在のオブジェクトと(オブジェクト名)_counter変数を使用できます。

### ネストしたレイアウトを使用する

特定のコントローラをサポートするために、アプリケーションの標準レイアウトとの違いがごくわずかしかないようなレイアウトを使いたくなることがあります。ネストしたレイアウト (サブテンプレートと呼ばれることもあります) を使用することで、メインのレイアウトを複製して編集したりせずにこれを実現できます。例: 

以下の`ApplicationController`レイアウトがあるとします。

* `app/views/layouts/application.html.erb`

    ```html+erb
    <html>
    <head>
      <title><%= @page_title or "Page Title" %></title>
      <%= stylesheet_link_tag "layout" %>
      <style><%= yield :stylesheets %></style>
    </head>
    <body>
      <div id="top_menu">Top menu items here</div>
      <div id="menu">Menu items here</div>
      <div id="content"><%= content_for?(:content) ? yield(:content) : yield %></div>
    </body>
    </html>
    ```

`NewsController`によって生成されるページでは、トップメニューを隠して右メニューを追加したいとします。

* `app/views/layouts/news.html.erb`

    ```html+erb
    <% content_for :stylesheets do %>
      #top_menu {display: none}
      #right_menu {float: right; background-color: yellow; color: black}
    <% end %>
    <% content_for :content do %>
      <div id="right_menu">Right menu items here</div>
      <%= content_for?(:news_content) ? yield(:news_content) : yield %>
    <% end %>
    <%= render template: "layouts/application" %>
    ```

以上でおしまいです。Newsビューで新しいレイアウトが使用されるようになり、トップメニューが隠されて"content" divタグ内に右メニューが新しく追加されました。

これと同じ結果を得られるサブテンプレートの使用法はこの他にもさまざまなものが考えられます。ネスティングレベルには制限がない点にご注目ください。たとえばNewsレイアウトで新しいレイアウトを使用するために、`render template: 'layouts/news'`経由で`ActionView::render`メソッドを使用することもできます。`News`レイアウトをサブテンプレート化するつもりがないのであれば、`content_for?(:news_content) ? yield(:news_content) : yield`を単に`yield`に置き換えれば済みます。