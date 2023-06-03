レイアウトとレンダリング
==============================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Layouts and Rendering in Rails](https://guides.rubyonrails.org/layouts_and_rendering.html)を日本語に翻訳した文書です。

本ガイドでは、Action ControllerとAction Viewによる基本的なレイアウト機能について解説します。

本ガイドの内容:

* Railsに組み込まれているさまざまなレンダリング（出力）メソッドの利用法
* 複数のセクションでレイアウトを作成する方法
* パーシャルを利用してビューをDRYにする方法
* レイアウトをネストする方法（サブテンプレート）

--------------------------------------------------------------------------------

レンダリングの概要
-------------------------------------

本ガイドでは、「コントローラ・ビュー・モデル」三角形のうち、コントローラとビューの間でのやりとりを中心に扱います。ご存じのように、Railsのコントローラはリクエスト処理プロセス全体の制御を担当し、（ビジネスロジックのような）重い処理はモデルの方で行なうのが普通です。モデルの処理が完了すると、コントローラは処理結果をビューに渡し、ビューはユーザーにレスポンスを返します。本ガイドでは、コントローラからビューに結果を渡す方法について解説します。

大きな流れとしては、まずユーザーに送信すべきレスポンスの内容を決定し、次にユーザーへのレスポンスを作成する適切なメソッドを呼び出します。レスポンス画面を完全なビューで作成すると、Railsはそのビューをレイアウトでラップして、場合によってはパーシャルビューもそこに追加します。本ガイドではこれらの方法をひととおり紹介します。

レスポンスを作成する
------------------

コントローラ側から見たHTTPレスポンスの作成方法は、以下の3とおりです。

* [`render`][controller.render]を呼び出す: 完全なレスポンスを作成してブラウザに送信する
* [`redirect_to`][]を呼び出す: HTTPリダイレクトステータスコードをブラウザに送信する
* [`head`][]を呼び出す: HTTPヘッダーのみのレスポンスを作成してブラウザに送信する

[controller.render]: https://api.rubyonrails.org/classes/ActionController/Rendering.html#method-i-render
[`redirect_to`]: https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_to
[`head`]: https://api.rubyonrails.org/classes/ActionController/Head.html#method-i-head

### デフォルトのレンダリング: アクションにおける「設定より規約」

Railsでは「設定より規約（CoC: convention over configuration）」というポリシーが推奨されていることをご存じかと思います。デフォルトのレンダリング方法はCoCのよい例です。Railsのコントローラは、デフォルトでは正しいルーティングに対応する名前を持つビューを自動的に選択し、それを使ってレスポンスをレンダリングします。たとえば、`BooksController`というコントローラに以下のコードがあるとします。

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

ユーザーがブラウザで`/books`にアクセスすると、Railsは自動的に`app/views/books/index.html.erb`ビューを利用してレスポンスをレンダリングし、その結果「Books are coming soon!」という文字が画面に表示されます。

しかしこの画面だけではほとんど実用性がないので、`Book`モデルを作成し、`BooksController`にindexアクションを追加してみましょう。

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end
```

上のコードでは、「設定より規約」原則のおかげで`index`アクションの末尾で明示的にレンダリングを指示する必要がない点にご注目ください。ここでは「コントローラのアクションの末尾で明示的にレンダリングが指示されていない場合は、コントローラが利用可能なビューのパスから`アクション名.html.erb`というビューテンプレートを探し、それを使って自動的にレンダリングする」というルールが適用されます。それによって、ここでは`app/views/books/index.html.erb`ファイルがレンダリングされます。

ビューですべての本の属性を表示したい場合は、以下のようにERBを書けます。

```html+erb
<h1>Listing Books</h1>

<table>
  <thead>
    <tr>
      <th>Title</th>
      <th>Content</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @books.each do |book| %>
      <tr>
        <td><%= book.title %></td>
        <td><%= book.content %></td>
        <td><%= link_to "Show", book %></td>
        <td><%= link_to "Edit", edit_book_path(book) %></td>
        <td><%= link_to "Destroy", book, data: { turbo_method: :delete, turbo_confirm: "Are you sure?" } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to "New book", new_book_path %>
```

NOTE: 実際のレンダリングは、[`ActionView::Template::Handlers`][]の名前空間の中でネストされたクラスで行われます。本ガイドではこれについて詳しく述べませんが、ここで重要なのは、ビューテンプレートファイルの拡張子によってテンプレートハンドラが自動的に選択されることを理解することです。

[`ActionView::Template::Handlers`]: http://api.rubyonrails.org/classes/ActionView/Template/Handlers.html

### `render`メソッドを使う

ほとんどの場合、アプリケーションがブラウザで表示するコンテンツのレンダリングには、コントローラの[`render`][controller.render]メソッドが使われます。
`render`メソッドはさまざまな方法でカスタマイズできます。Railsテンプレートのデフォルトビューをレンダリングすることも、特定のテンプレート、ファイル、インラインコードを指定してレンダリングすることも、何も出力しないようにすることもできます。テキスト、JSON、XMLをレンダリングすることもできます。レスポンスをレンダリングするときにContent-TypeヘッダーやHTTPステータスを指定することもできます。

TIP: `render`呼び出しの正確な結果をブラウザを使わずに調べたい場合は、`render_to_string`を利用できます。このメソッドの振る舞いは、レンダリング結果をブラウザに返さずに文字列を返す点を除けば、`render`と完全に同じです。

#### Action Viewでレンダリングする

同じコントローラから、デフォルト以外のテンプレートに対応するビューをレンダリングしたい場合は、`render`メソッドでビュー名を指定できます。

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

上の`update`アクションでモデルに対する`update`メソッドの呼び出しが失敗すると、同じコントローラに用意しておいた別の`edit.html.erb`テンプレートがレンダリングで使われます。

レンダリングするアクションは、文字列の他にシンボルでも指定できます。

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render :edit, status: :unprocessable_entity
  end
end
```

#### 別のコントローラからアクションテンプレートをレンダリングする

あるコントローラのアクションから、まったく別のコントローラの配下にあるテンプレートを利用してレンダリングすることは可能でしょうか。これも`render`メソッドでできます。
`render`メソッドには`app/views`を起点とするフルパスを渡せるので、レンダリングするテンプレートをフルパスで指定します。たとえば、`app/controllers/admin`にある`AdminProducts`コントローラのコードを実行する場合、以下のように書くことでアクションの実行結果を`app/views/products`に置かれているビューテンプレートでレンダリングできます。

```ruby
render "products/show"
```

パスにスラッシュ`/`が含まれていると、Railsはこのビューが別のコントローラの配下にあることを認識します。別のコントローラのテンプレートを指定していることを明示的に指定したい場合は、以下のように`template:`オプションを使うこともできます （なおRails 2.2以前は`template:`を省略できませんでした）。

```ruby
render template: "products/show"
```

#### まとめ

これまでご紹介した2とおりのレンダリング方法（コントローラ内の別テンプレートを使う、別のコントローラのテンプレートを使う）は、実際には同じアクションのバリエーションにすぎません。

たとえば`BooksController`クラスの`update`アクションで本の更新に失敗したら`edit`テンプレートをレンダリングしたいとします。しかし実際は、以下のどのレンダリング呼び出しを使っても、最終的なレンダリングでは`views/books`ディレクトリの`edit.html.erb`が使われます。

```ruby
render :edit
render action: :edit
render "edit"
render action: "edit"
render "books/edit"
render template: "books/edit"
```

どの呼び出しを使うかは開発チームのコーディングスタイルと規約の問題に過ぎませんが、経験則では、今書いているコードに合う最もシンプルな記法を使うのがよいでしょう。

#### `render`で`:inline`を指定する

`render`メソッドを呼び出すときに`:inline`オプションでERBを渡すと、ビューをまったく使わずにレンダリングできます。以下の書き方は完全に有効です。

```ruby
render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>"
```

WARNING: このオプションを実際に使う意味はめったにありません。コントローラのコードにERBを直接書き込むと、RailsのMVC指向が損なわれ、開発者がプロジェクトのロジックを追いかけることが難しくなってしまいます。ERBビューをお使いください。

インラインのレンダリングでは、デフォルトでERBが使われます。`:type`オプションで`:builder`を指定すると、ERBではなくBuilderが使われます。

```ruby
render inline: "xml.p {'Horrid coding practice!'}", type: :builder
```

#### テキストをレンダリングする

`render`メソッドで`:plain`オプションを指定すると、平文テキストをマークアップせずにブラウザに送信できます。

```ruby
render plain: "OK"
```

TIP: 平文テキストのレンダリングは、HTML以外のレスポンスが期待されるAjaxやWebサービスリクエストにレスポンスを返すときに最も有用です。

NOTE: デフォルトでは、`:plain`オプションを指定すると現在のレイアウトはレンダリング結果に適用されません。テキストを現在のレイアウトでレンダリングしたい場合は、`layout: true`オプションを追加して、拡張子を`.text.erb`にする必要があります。

#### HTMLをレンダリングする

`render`メソッドで`:html`オプションを指定すると、HTML文字列をブラウザに送信できます。

```ruby
render html: helpers.tag.strong('Not Found')
```

TIP: この手法は、HTMLコードのごく小さなスニペットを出力したい場合に便利です。マークアップが複雑な場合は、テンプレートファイルに移行することを検討しましょう。

NOTE: `html:`オプションを指定すると、文字列が`html_safe`対応のAPIでビルドされていない場合にHTMLエンティティがエスケープされます。

#### JSONをレンダリングする

JSONはJavaScriptのデータ形式の一種で、多くのAjaxライブラリで利用されています。Railsには、オブジェクトからJSON形式への変換と、変換されたJSONをブラウザに送信する機能のサポートが組み込まれています。

```ruby
render json: @product
```

TIP: レンダリングするオブジェクトに対して`to_json`を呼び出す必要はありません。`:json`オプションを指定すれば、`render`メソッドで`to_json`が自動的に呼び出されます。

#### XMLをレンダリングする

Railsでは、オブジェクトからXML形式への変換と、変換されたXMLをブラウザに送信する機能がビルトインでサポートされています。

```ruby
render xml: @product
```

TIP: レンダリングするオブジェクトに対して`to_xml`を呼び出す必要はありません。`:xml`オプションが指定されていれば、`render`によって`to_xml`が自動的に呼び出されます。

#### vanilla JavaScriptをレンダリングする

vanilla JavaScript（素のJavaScript）もレンダリングできます。

```ruby
render js: "alert('Hello Rails');"
```

上のコードは、引数の文字列をMIMEタイプ`text/javascript`でブラウザに送信します。

#### 生のコンテンツを出力する

`render`で`:body`オプションを指定すると、Content-Typeヘッダーを指定しない生のコンテンツをブラウザに送信できます。

```ruby
render body: "raw"
```

TIP: このオプションは、レスポンスのContent-Typeヘッダーを気にする必要がない場合にのみお使いください。ほとんどの場合、`:plain`や`:html`などを使うのが適切です。

NOTE: このオプションを指定してブラウザにレスポンスを送信すると、上書きされない限り`text/plain`（Action DispatchによるレスポンスのデフォルトのContent-Type）が使われます。

#### 生のファイルをレンダリングする

絶対パスを指定して生のファイルをレンダリングできます。これは、条件を指定してエラーページのような静的ファイルをレンダリングするときに便利です。

```ruby
render file: "#{Rails.root}/public/404.html", layout: false
```

上のコードは生のファイルをレンダリングします（ERBなどのハンドラはサポートされません）。デフォルトでは、現在のレイアウト内でレンダリングされます。

WARNING: `:file`オプションにユーザー入力を渡すと、セキュリティ上の問題につながる可能性があります（攻撃者がこのアクションを悪用してファイルシステム上の重要なファイルにアクセスする可能性があります）。

TIP: レイアウトが不要な場合は、多くの場合`send_file`メソッドの方が高速かつ適切です。

#### オブジェクトをレンダリングする

Railsは、`:render_in`に応答できるオブジェクトを以下のようにレンダリングできます。

```ruby
render MyRenderable.new
```

上のコードは、現在のビューコンテキストで指定のオブジェクト上の`render_in`を呼び出します。

#### `render`のオプション

 [`render`][controller.render]メソッド呼び出しでは、一般に以下の6つのオプションを指定できます。

* `:content_type`
* `:layout`
* `:location`
* `:status`
* `:formats`
* `:variants`

##### `:content_type`オプション

レンダリングのMIME Content-Typeヘッダーは、デフォルトで`text/html`になります（ただし`:json`を指定すると`application/json`、`:xml`を指定すると`application/xml`になります）。Content-Typeを変更したい場合は、`:content_type`オプションを指定します。

```ruby
render template: "feed", content_type: "application/rss"
```

##### `:layout`オプション

`render`で指定できるほとんどのオプションでは、レンダリングされるコンテンツが現在のレイアウトの一部としてブラウザ上で表示されます。レイアウトの詳細や利用法については本ガイドで後述します。

`:layout`オプションで特定のファイルを指定すると、現在のアクションでレイアウトとして利用できるようになります。

```ruby
render layout: "special_layout"
```

レイアウトを使わずにレンダリングすることも可能です。

```ruby
render layout: false
```

##### `:location`オプション

`:location`オプションで、HTTP `Location`ヘッダーを設定できます。

```ruby
render xml: photo, location: photo_url(photo)
```

##### `:status`オプション

Railsが返すレスポンスのHTTPステータスコードは自動的に生成されます（ほとんどの場合`200 OK`）。`:status`オプションを使うと、レスポンスのステータスコードを変更できます。

```ruby
render status: 500
render status: :forbidden
```

ステータスコードは、以下の数字とシンボルのどちらでも指定できます。

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
|                     | 413              | :payload_too_large               |
|                     | 414              | :uri_too_long                    |
|                     | 415              | :unsupported_media_type          |
|                     | 416              | :range_not_satisfiable           |
|                     | 417              | :expectation_failed              |
|                     | 421              | :misdirected_request             |
|                     | 422              | :unprocessable_entity            |
|                     | 423              | :locked                          |
|                     | 424              | :failed_dependency               |
|                     | 426              | :upgrade_required                |
|                     | 428              | :precondition_required           |
|                     | 429              | :too_many_requests               |
|                     | 431              | :request_header_fields_too_large |
|                     | 451              | :unavailable_for_legal_reasons   |
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

NOTE: 「non-content」ステータスコード （100〜199、204、205、304のいずれか）を指定してレンダリングすると、コンテンツがレスポンスから削除されます。

##### `:formats`オプション

`:formats`オプションは、リクエストで利用するフォーマットを指定します（デフォルトは`html`）。`:formats`オプションにはシンボルまたは配列を渡せます。

```ruby
render formats: :xml
render formats: [:json, :xml]
```

指定されたフォーマットのテンプレートが存在しない場合は、`ActionView::MissingTemplate`エラーが発生します。

##### `:variants`オプション

`:variants`オプションは、同じフォーマットの別テンプレートを探索するようRailsに指示します。
:variants`オプションに渡す別テンプレートのリストには、シンボルまたは配列が使えます。

以下は利用方法の例です。

```ruby
# HomeController#indexで呼び出す
render variants: [:mobile, :desktop]
```

上のコードで別テンプレートのセットを渡すと、以下のテンプレートを探索して、存在するテンプレートのうち最初のものが使われます。

- `app/views/home/index.html+mobile.erb`
- `app/views/home/index.html+desktop.erb`
- `app/views/home/index.html.erb`

指定のフォーマットを持つテンプレートが存在しない場合は、`ActionView::MissingTemplate`エラーが発生します。

`render`呼び出しで別テンプレートリストを指定する代わりに、以下のようにコントローラアクションの`request`オブジェクトで設定することもできます。

```ruby
def index
  request.variant = determine_variant
end

private

def determine_variant
  variant = nil
  # 別テンプレートを決定するコード
  variant = :mobile if session[:use_mobile]

  variant
end
```

#### レイアウトの探索順序

Railsは現在のレイアウトを探索するときに、最初に現在のコントローラと同じ基本名を持つレイアウトが`app/views/layouts`ディレクトリにあるかどうかを調べます。
たとえば、`PhotosController`クラスのアクションからレンダリングする場合は、`app/views/layouts/photos.html.erb`（または`app/views/layouts/photos.builder`）を探索します。コントローラ固有のレイアウトが見つからない場合は、`app/views/layouts/application.html.erb`または`app/views/layouts/application.builder`を使います。`.erb`レイアウトがない場合は、`.builder`レイアウトがあればそれを使います。Railsには、個別のコントローラやアクションに割り当てる特定のレイアウトをより正確に指定するさまざまな方法も用意されています。

##### コントローラ用のレイアウトを指定する

デフォルトのレイアウト名ルールは、以下のように[`layout`][]宣言で上書きできます。

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

この宣言によって、上のコードの`ProductsController`のレンダリングで`app/views/layouts/inventory.html.erb`レイアウトが使われるようになります。

アプリケーション全体で特定のレイアウトを使いたい場合は、`layout`を`ApplicationController`クラスで宣言します。

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

この宣言によって、アプリケーションのすべてのビューで`app/views/layouts/main.html.erb`レイアウトが使われるようになります。

[`layout`]: https://edgeapi.rubyonrails.org/classes/ActionView/Layouts/ClassMethods.html#method-i-layout

##### 実行時にレイアウトを指定する

以下のようにレイアウトをシンボルで指定すると、リクエストが実際に処理されるまでレイアウトの選択を先延ばしできます。

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

上のコードは、現在のユーザーが特別なユーザーの場合、そのユーザーが表示する製品ページに特別なレイアウトを適用します。

レイアウトを決定するときには、Procなどのインラインメソッドも利用できます。たとえば以下のようにProcオブジェクトを渡すと、Procに渡すブロックに`controller`インスタンスが渡されるので、現在のリクエストに応じてレイアウトを切り替えられます。

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

##### 条件付きレイアウト

コントローラレベルで指定されたレイアウトでは、`:only`オプションと`:except`オプションがサポートされています。これらのオプションは、コントローラ内のメソッド名に対応する単一のメソッド名またはメソッド名の配列を引数として受け取ります。

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

上の宣言によって、`rss`メソッドと`index`メソッド以外のすべてのメソッドに`product`レイアウトが適用されます。

##### レイアウトの継承

レイアウト宣言は下の階層にカスケードされます。以下のように、下の階層（より具体的なレイアウト宣言）は、上の階層（より一般的なレイアウト）を常にオーバーライドします。

* `application_controller.rb`

    ```ruby
    class ApplicationController < ActionController::Base
      layout "main"
    end
    ```

* `articles_controller.rb`

    ```ruby
    class ArticlesController < ApplicationController
    end
    ```

* `special_articles_controller.rb`

    ```ruby
    class SpecialArticlesController < ArticlesController
      layout "special"
    end
    ```

* `old_articles_controller.rb`

    ```ruby
    class OldArticlesController < SpecialArticlesController
      layout false

      def show
        @article = Article.find(params[:id])
      end

      def index
        @old_articles = Article.older
        render layout: "old"
      end
      # ...
    end
    ```

上のアプリケーションは以下のように動作します。

* 原則としてビューのレンダリングには`main`レイアウトが使われる。
* `ArticlesController#index`では`main`レイアウトが使われる。
* `SpecialArticlesController#index`では`special`レイアウトが使われる。
* `OldArticlesController#show`ではレイアウトが適用されない。
* `OldArticlesController#index`では`old`レイアウトが使われる。

##### テンプレートの継承

レイアウト継承のロジックと同様に、テンプレートやパーシャルが通常のパスで見つからない場合、コントローラーは継承パスを探索してレンダリングするテンプレートやパーシャルを見つけようとします。以下の例で考えてみましょう。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
end
```

```ruby
# app/controllers/admin_controller.rb
class AdminController < ApplicationController
end
```

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < AdminController
  def index
  end
end
```

このときの`admin/products#index`アクションは以下の順に探索されます。

* `app/views/admin/products/`
* `app/views/admin/`
* `app/views/application/`

つまり、`app/views/application/`は共有パーシャルを置くのに適しています。これらはERBで次のようにレンダリングされます。

```erb
<%# app/views/admin/products/index.html.erb %>
<%= render @products || "empty_list" %>

<%# app/views/application/_empty_list.html.erb %>
There are no items in this list <em>yet</em>.
```

#### 二重レンダリングエラーを避ける

ほとんどのRails開発者は、"Can only render or redirect once per action"エラーを目にしたことがあるでしょう。いまいましいエラーですが、修正は比較的簡単です。このエラーはほとんどの場合、開発者が`render`メソッドの基本的な動作を誤解していることが原因です。

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

`@book.special?`が`true`と評価されると、Railsはレンダリングを開始し、`@book`変数を`special_show`ビューに転送します。しかし`show`アクションのコードはそこで**止まらない**ことにご注意ください。`show`アクションのコードは最終行まで実行され、`regular_show`ビューのレンダリングを行おうとした時点でエラーが発生します。
解決法はいたって単純で、`render`メソッドや`redirect`メソッドが1つのコード実行パス内で「1回だけ」呼び出されるようにすることです。こういうときには`and return`というとても便利な書き方があります。以下はこの方法で修正したコードです。

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show" and return
  end
  render action: "regular_show"
end
```

`&& return`ではなく`and return`を使うのがポイントです。Ruby言語の`&&`演算子の優先順位は`and`より高いので、`&& return`はこの文脈では正常に動作しません。

なお、Rails組み込みのActionControllerが行なう暗黙のレンダリングは、`render`メソッドが呼び出されているかどうかを確認してから開始されます。従って、以下のコードは正常に動作します。

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
end
```

上のコードは、ある本が`special?`である場合にのみ`special_show`テンプレートでレンダリングし、それ以外の場合は`show`テンプレートでレンダリングします。

### `redirect_to`を使う

HTTPリクエストにレスポンスを返すもう1つの方法は、[`redirect_to`][]を使う方法です。前述のとおり、`render`はレスポンスを構成するときに使うビュー（または他のアセット）を指定しますが、`redirect_to`メソッドは、この点において`render`メソッドと根本的に異なります。`redirect_to`メソッドは、別のURLにリクエストを再送信するようブラウザに指示します。たとえば以下の呼び出しを行なうと、アプリケーションで現在どのページが表示されていても、写真のindexページにリダイレクトされます。

```ruby
redirect_to photos_url
```

[`redirect_back`][]メソッドを使うと、直前のページに戻ります。戻る場所には`HTTP_REFERER`ヘッダから取り出した情報が使われますが、このヘッダーがブラウザ側で設定されているかどうかは保証されていないので、以下のように必ず`fallback_location`を設定しなければなりません。

```ruby
redirect_back(fallback_location: root_path)
```

NOTE: `redirect_to`や`redirect_back`を呼び出しても、メソッドの実行がすぐに中断されるのではなく、単にHTTPのレスポンスが設定されます。もしこれらの呼び出しの後に別のメソッドがあると、そのメソッドは実行されてしまいます。必要であれば、明示的に`return`することで（または別の方法で）中断できます。

[`redirect_back`]: https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_back

#### リダイレクトのステータスコードを変更する

`redirect_to`を呼び出すと、一時的なリダイレクトを意味する[HTTPステータスコード302](https://developer.mozilla.org/ja/docs/Web/HTTP/Status/302)がブラウザに返され、ブラウザはそれに基いてリダイレクトを行います。別のステータスコード（おそらく[HTTP 301](https://developer.mozilla.org/ja/docs/Web/HTTP/Status/301): 恒久的なリダイレクト）に変更するには`:status`オプションを使います。

```ruby
redirect_to photos_path, status: 301
```

`render`の`:status`オプションの場合と同様、`redirect_to`の`:status`オプションにも数値または数値に対応するシンボルを渡せます。

#### `render`と`redirect_to`の違いを理解する

`redirect_to`を一種の`goto`コマンドとして理解している開発者を見かけることがあります（Railsコードの実行位置をある場所から別の場所にジャンプするコマンドであると考えているわけです）。これは**正しくありません**。
`redirect_to`を実行すると、コードはそこで実行を停止して、ブラウザからの次のリクエストを待ちます（これは通常のスタンバイ状態です）。その直後、`redirect_to`でブラウザに送信したHTTPステータスコード302に従って、ブラウザは別のURLへのリクエストをサーバーに送信し、サーバーはそのリクエストを改めて処理します。

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

上のフォームのコードでは、`@book`インスタンス変数が`nil`の場合に問題が生じる可能性があります。`render :action`を実行しても、対象となるアクションのコードは実行されないことを思い出しましょう。つまり`index`ビューでおそらく必要となる`@books`インスタンス変数には何も設定されず、空の蔵書リストが表示されてしまいます。
これを修正する方法の1つは、`render`を以下のように`redirect_to`に変更することです。

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

上のコードでは、ブラウザから改めてindexページにリクエストが送信されるので、`index`メソッドのコードが正常に実行されます。

上のコードで唯一の欠点は、ブラウザとの通信が1往復必要になることです。ブラウザから`/books/1`に対して`show`アクションが呼び出され、本が1冊もないことをコントローラが検出すると、コントローラはブラウザにステータスコード302（リダイレクト）レスポンスを返し、`/books/`に再度アクセスするようブラウザに指示します。ブラウザはこの指示に沿って、コントローラの`index`アクションを呼び出すリクエストを改めてサーバーに送信します。コントローラはこのリクエストを受け取って、データベースからすべての蔵書リストを取り出し、`index`テンプレートをレンダリングして結果をブラウザに送り返すと、ブラウザで蔵書リストが表示されます。

このやりとりによる遅延は、小規模なアプリケーションであればおそらく問題になりませんが、場合によってはレスポンスの遅延が問題になることもあります。この問題を解決する方法の1つを以下のコードで説明します。

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    @books = Book.all
    flash.now[:alert] = "この本は見つかりませんでした"
    render "index"
  end
end
```

上のコードの動作は次のとおりです。指定されたidを持つ本が見つからない場合は、モデル内のすべての蔵書リストを`@books`インスタンス変数に保存します。次にflash警告メッセージを追加してユーザーに状況を伝え、さらに`index.html.erb`テンプレートを直接レンダリングしてから結果をブラウザに送り返します。

### `head`でヘッダのみのレスポンスを生成する

[`head`][]メソッドを使うと、本文（body）のないヘッダのみのレスポンスをブラウザに送信できます。`head`メソッドの引数には、HTTPステータスコードを示すさまざまなシンボルを指定できます（[テーブル](#statusオプション)を参照）。オプションの引数は、ヘッダ名と値をペアにしたハッシュ値として解釈されます。たとえば、以下のコードはエラーヘッダーのみのレスポンスを返します。

```ruby
head :bad_request
```

上のコードによって以下のヘッダーが生成されます。

```http
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

```http
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

Railsがビューをレスポンスとしてレンダリングすると、そのビューに現在のレイアウトも組み込まれます。現在のレイアウトを探索するときには、本ガイドで既に説明したルールが使われます。レイアウト内では、さまざまな出力の断片を組み合わせて最終的なレスポンスを得るために、以下の3つのツールを利用できます。

* アセットタグ
* `yield`と[`content_for`][]
* パーシャル

[`content_for`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#method-i-content_for

### アセットタグヘルパー

アセットタグヘルパーは、「フィード」「JavaScript」「スタイルシート」「画像」「動画」「音声」のビューにリンクするHTMLを生成するメソッドです。Railsでは以下の6つのアセットタグヘルパーが利用できます。

* [`auto_discovery_link_tag`][]
* [`javascript_include_tag`][]
* [`stylesheet_link_tag`][]
* [`image_tag`][]
* [`video_tag`][]
* [`audio_tag`][]

これらのタグは、レイアウトや別のビューでも利用できます。このうち、`auto_discovery_link_tag`、`javascript_include_tag`、`stylesheet_link_tag`はレイアウトの`<head>`セクションで使うのが普通です。

[`auto_discovery_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-auto_discovery_link_tag
[`javascript_include_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-javascript_include_tag
[`stylesheet_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-stylesheet_link_tag
[`image_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-image_tag
[`video_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-video_tag
[`audio_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-audio_tag

WARNING: これらのアセットタグヘルパーは、指定の場所にアセットがあるかどうかを**確認しません**。単に指示どおりにリンクを生成します。

#### `auto_discovery_link_tag`でフィードへのリンクを生成する

[`auto_discovery_link_tag`][]ヘルパーでHTMLを生成すると、さまざまなブラウザやRSSリーダーでRSSフィードやAtomフィード、JSONフィードを検出できるようになります。このメソッドの引数には、リンクの種類（`:rss`、`:atom`、`:json`）、`url_for`に渡されるオプションハッシュ、タグのオプションハッシュを渡せます。

```erb
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

`auto_discovery_link_tag`では以下の3つのタグオプションを利用できます。

* `:rel`: リンク内の`rel`値を指定する（デフォルト値は "alternate"）。
* `:type`: MIMEタイプを明示的に指定する（Railsは適切なMIMEタイプを自動生成します）。
* `:title`: リンクのタイトルを指定する（デフォルト値は大文字の`:type`値: "ATOM" や "RSS" など）。

#### `javascript_include_tag`でJavaScriptファイルにリンクする

[`javascript_include_tag`][]ヘルパーは、指定されたソースごとにHTML `<script>`タグを返します。

Railsの[アセットパイプライン](asset_pipeline.html) を有効にすると、`/assets/javascripts/`ディレクトリにあるJavaScriptファイルにリンクされます（旧Railsの`public/javascripts`ではありません）。このリンクはアセットパイプラインによって配信されます。

Railsアプリケーション内やRailsエンジン内のJavaScriptファイルは、`app/assets`、`lib/assets`、`vendor/assets`のいずれかのディレクトリに置かれます。これらの置き場所について詳しくは[アセットパイプラインガイドの「アセットの編成」](asset_pipeline.html#アセットの編成) を参照してください。

ドキュメントルートからの相対フルパスやURLも指定できます。たとえば、`app/assets`、`lib/assets`、または`vendor/assets`の下にある`javascripts`ディレクトリのJavaScriptファイルにリンクしたい場合は以下のようにします。

```erb
<%= javascript_include_tag "main" %>
```

上のコードにより、以下のような`script`タグが出力されます。

```html
<script src='/assets/main.js'></script>
```

このアセットへのリクエストは、sprockets gemによって配信されます。

複数のファイルをインクルードする（`app/assets/javascripts/main.js`と`app/assets/javascripts/columns.js`など）には、以下のように書きます。

```erb
<%= javascript_include_tag "main", "columns" %>
```

`app/assets/javascripts/main.js`とサブディレクトリの`app/assets/javascripts/photos/columns.js`ファイルをインクルードするには以下のように書きます。

```erb
<%= javascript_include_tag "main", "/photos/columns" %>
```

外部の`http://example.com/main.js`をインクルードするには以下のように書きます。

```erb
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### `stylesheet_link_tag`でCSSファイルにリンクする

[`stylesheet_link_tag`][]ヘルパーは、指定のソースごとにHTML `<link>`タグを返します。

Railsのアセットパイプラインを有効にすると、このヘルパーは`/assets/stylesheets/`ディレクトリにあるCSSファイルへのリンクを生成します。このリンクはsprockets gemによって処理されます。スタイルシートファイルは、`app/assets`、`lib/assets``vendor/assets`ディレクトリのいずれかに置かれます。

ドキュメントルートからの相対フルパスやURLも指定できます。たとえば、`app/assets`、`lib/assets`、または`vendor/assets`の下にある`stylesheets`ディレクトリのスタイルシートファイルにリンクするには、以下のように書きます。

```erb
<%= stylesheet_link_tag "main" %>
```

`app/assets/stylesheets/main.css`と`app/assets/stylesheets/columns.css`をインクルードするには、以下のように書きます。

```erb
<%= stylesheet_link_tag "main", "columns" %>
```

`app/assets/stylesheets/main.css`とサブディレクトリの`app/assets/stylesheets/photos/columns.css`ファイルをインクルードするには、以下のように書きます。

```erb
<%= stylesheet_link_tag "main", "photos/columns" %>
```

外部の`http://example.com/main.css`をインクルードするには、以下のように書きます。

```erb
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

`stylesheet_link_tag`によって作成されるリンクには、デフォルトで`rel="stylesheet"`属性が追加されます。適切なオプション（`:rel`など）を指定するとデフォルト値を上書きできます。

```erb
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### `image_tag`で画像にリンクする

[`image_tag`][]は、指定の画像ファイルにリンクするHTML `<img />`タグを生成します。デフォルトでは、ファイルは`public/images`以下から読み込まれます。

WARNING: 画像ファイルの拡張子は省略できません。

```erb
<%= image_tag "header.png" %>
```

画像ファイルへのパスも指定できます。

```erb
<%= image_tag "icons/delete.gif" %>
```

HTMLオプションをハッシュ形式で追加できます。

```erb
<%= image_tag "icons/delete.gif", {height: 45} %>
```

ユーザーがブラウザで画像を非表示にしている場合、`alt`属性のテキストを表示できます。`alt`属性が明示的に指定されていない場合は、ファイル名が`alt`テキストとして使われます。このときファイル名の先頭は大文字になり、拡張子は取り除かれます。たとえば、以下の2つのimage_tagヘルパーは同じコードを返します。

```erb
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

"幅x高さ"形式で特殊な`size`タグも指定できます。

```erb
<%= image_tag "home.gif", size: "50x20" %>
```

上の特殊タグ以外にも、`:class`、`:id`、`:name`などの標準的なHTMLオプションを最終的にハッシュにしたものを引数に渡せます。

```erb
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### `video_tag`で動画ファイルにリンクする

[`video_tag`][]ヘルパーは、指定の動画ファイルにリンクするHTML5 `<video>`タグを生成します。デフォルトでは、`public/videos`ディレクトリからファイルを読み込みます。

```erb
<%= video_tag "movie.ogg" %>
```

上のコードによって以下が生成されます。

```erb
<video src="/videos/movie.ogg" />
```

`image_tag`の場合と同様、`public/videos`ディレクトリからの絶対パスや相対パスも指定できます。さらに、`image_tag`の場合と同様に、`size: "#{幅}x#{高さ}"`オプションも指定できます。`id`や`class`などのHTMLオプションも引数の末尾に追加できます。

`video_tag`には、HTMLオプションハッシュ形式で以下を含む任意の`<video>` HTMLオプションも指定できます。

* `poster: "image_name.png"`:動画再生前に表示したい画像を指定します。
* `autoplay: true`: ページが読み込まれると動画を自動再生します。
* `loop: true`: 動画をループ再生します。
* `controls: true`: ブラウザの動画制御機能を有効にします。
* `autobuffer: true`: ページ読み込み時に動画ファイルをプリロードします。

複数の動画ファイルを表示するには、`video_tag`に動画ファイルの配列を渡します。

```erb
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

上のコードによって以下が生成されます。

```erb
<video>
  <source src="/videos/trailer.ogg">
  <source src="/videos/movie.ogg">
</video>
```

#### `audio_tag`で音声ファイルにリンクする

[`audio_tag`][]は、指定の音声ファイルにリンクするHTML5 `<audio>`タグを生成します。デフォルトでは、`public/audios`ディレクトリからファイルを読み込みます。

```erb
<%= audio_tag "music.mp3" %>
```

音声ファイルへのパスも指定できます。

```erb
<%= audio_tag "music/first_song.mp3" %>
```

`:id`や`:class`などのオプションもハッシュ形式で指定できます。

`video_tag`と同様、`audio_tag`にも以下の特殊オプションがあります。

* `autoplay: true`: ページ読み込み時に音声ファイルを自動再生します。
* `controls: true`: ブラウザの音声ファイル制御機能を有効にします。
* `autobuffer: true`: ページ読み込み時に動画ファイルをプリロードします。

### `yield`を理解する

レイアウトのコンテキスト内では、ビューのコンテンツを挿入する位置を`yield`で指定します。`yield`の最もシンプルな使い方は、以下のように`yield`を1個だけ使って、現在レンダリングされているビューのコンテンツ全体をその位置に挿入することです。

```html+erb
<html>
  <head>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

以下のように、`yield`をレイアウトの複数のセクションに配置することも可能です。

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

ビューのメインbodyは、常に「名前のない」`yield`の位置でレンダリングされます。コンテンツを名前付き`yield`の位置でレンダリングするには、`content_for`メソッドを使います。

### `content_for`を使う

[`content_for`][]メソッドを使うと、レイアウト内の名前付き`yield`ブロックの位置にコンテンツを挿入できます。たとえば、以下のビューは、上のレイアウトに挿入されます。

```html+erb
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

このページのレンダリング結果がレイアウトに挿入されると、最終的に以下のHTMLになります。

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

`content_for`メソッドは、たとえばレイアウトを「サイドバー」や「フッター」などの領域に分割して、それぞれに異なるコンテンツを挿入したい場合などに大変便利です。あるいは、多くのページで使う共通のヘッダーがあり、特定のページでのみJavaScriptやCSSファイルをそのヘッダーに挿入したい場合にも便利です。

### パーシャルを使う

パーシャル（部分テンプレート）は、上と別の方法でレンダリング処理を扱いやすい単位に分割するしくみです。パーシャルを使うと、レスポンスで表示するページの特定部分をレンダリングするコードを別ファイルに切り出せます。

#### パーシャルに名前を与える

パーシャルをビューの一部としてレンダリングするには、ビュー内で以下のように[`render`][view.render] メソッドを使います。

```html+erb
<%= render "menu" %>
```

レンダリングされるビュー内に置かれている上のコードは、その場所で`_menu.html.erb`という名前のファイルをレンダリングします。パーシャルファイル名の冒頭にはアンダースコア（`_`）が付いていることにご注意ください。パーシャルをコードから参照するときはアンダースコアを付けませんが、通常のビューファイルと区別するためにアンダースコアをパーシャルファイル名に付けます。これは他のフォルダの下にあるパーシャルを取り込む場合も同様です。

```html+erb
<%= render "shared/menu" %>
```

上のコードは、`app/views/shared/_menu.html.erb`パーシャルをその位置に取り込みます。

[view.render]: https://api.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render

#### シンプルなビューでパーシャルを使う

パーシャルの利用方法の1つは、パーシャルをサブルーチンと同様に扱うことです。表示の詳細をパーシャル化してビューから追い出し、コードを読みやすくします。たとえば以下のようなビューがあるとします。

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
...

<%= render "shared/footer" %>
```

上のコードの`_ad_banner.html.erb`パーシャルと`_footer.html.erb`パーシャルに含まれるコンテンツは、アプリケーションの多くのページと共有できます。こうすることで、そのセクションの詳細を気にせずにページの開発に集中できます。

本ガイドの直前のセクションで説明したように、`yield`はレイアウトを簡潔に保つ上で極めて強力なツールです。`yield`は純粋なRubyなので、ほぼどこでも利用できます。たとえば`yield`を用いると、同じようなさまざまなリソースで使うフォームのレイアウトをDRYに定義できます。

* `users/index.html.erb`

    ```html+erb
    <%= render "shared/search_filters", search: @q do |form| %>
      <p>
        Name contains: <%= form.text_field :name_contains %>
      </p>
    <% end %>
    ```

* `roles/index.html.erb`

    ```html+erb
    <%= render "shared/search_filters", search: @q do |form| %>
      <p>
        Title contains: <%= form.text_field :title_contains %>
      </p>
    <% end %>
    ```

* `shared/_search_filters.html.erb`

    ```html+erb
    <%= form_with model: search do |form| %>
      <h1>Search form:</h1>
      <fieldset>
        <%= yield form %>
      </fieldset>
      <p>
        <%= form.submit "Search" %>
      </p>
    <% end %>
    ```

TIP: すべてのページで共有したいコンテンツがある場合は、そのコンテンツのパーシャルをレイアウトに直接配置できます。

#### パーシャルレイアウト

ビューにレイアウトがあるのと同様に、パーシャルでも独自のレイアウトファイルを利用できます。たとえば、以下のようなパーシャルを呼び出すとします。

```erb
<%= render partial: "link_area", layout: "graybar" %>
```

上のコードは、`_link_area.html.erb`という名前のパーシャルを探索し、`_graybar.html.erb`という名前のレイアウトでレンダリングします。パーシャル用のレイアウトファイルは、対応する通常のパーシャルと同様、パーシャル名の冒頭にアンダースコアを追加して、（マスターの`layouts`ディレクトリではなく）そのレイアウトが属しているパーシャルファイルと同じディレクトリに配置します。

`:layout`などの追加オプションも渡す場合は、`:partial`オプションも明示的に指定する必要があります。

#### ローカル変数を渡す

パーシャルにローカル変数を渡すことで、パーシャルがさらに強力かつ柔軟になります。たとえば、以下のようにnewページとeditページの違いがごくわずかしかない場合は、この手法でコードの重複を解消できます。

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
    <%= form_with model: zone do |form| %>
      <p>
        <b>Zone name</b><br>
        <%= form.text_field :name %>
      </p>
      <p>
        <%= form.submit %>
      </p>
    <% end %>
    ```

上の2つのビューは同じパーシャルをレンダリングしますが、Action Viewのsubmitヘルパーはnewアクションで"Create Zone"を返し、editアクションで"Update Zone"を返します。

ローカル変数を特定の状況に限ってパーシャルに渡すには、`local_assigns`を使います。

* `index.html.erb`

    ```erb
    <%= render user.articles %>
    ```

* `show.html.erb`

    ```erb
    <%= render article, full: true %>
    ```

* `_article.html.erb`

    ```erb
    <h2><%= article.title %></h2>

    <% if local_assigns[:full] %>
      <%= simple_format article.body %>
    <% else %>
      <%= truncate article.body %>
    <% end %>
    ```

これにより、すべてのローカル変数を宣言せずにパーシャルを使えるようになります。

どのパーシャルにも、パーシャル名と同じ名前のローカル変数が1つずつあります（ローカル変数の冒頭にアンダースコアは付きません）。`object`オプションを使うと、以下のようにこのローカル変数にオブジェクトを渡せます。

```erb
<%= render partial: "customer", object: @new_customer %>
```

上の`customer`パーシャルの内側では、`customer`ローカル変数は親のビューの`@new_customer`変数を指すようになります。

あるモデルのインスタンスをパーシャルでレンダリングする場合は、以下のショートハンド記法を利用できます。

```erb
<%= render @customer %>
```

上のコードの`@customer`インスタンス変数に`Customer`モデルのインスタンスが含まれていると仮定すると、`_customer.html.erb`パーシャルを用いてレンダリングします。このパーシャルに渡した`customer`ローカル変数は、親ビューにある`@customer`インスタンス変数を参照します。

#### コレクションをレンダリングする

パーシャルはコレクションをレンダリングするときにも極めて有用です。`collection:`オプションを指定してパーシャルにコレクションを渡すと、コレクションのメンバーごとにパーシャルをレンダリングしてその位置に挿入します。

* `index.html.erb`

    ```html+erb
    <h1>Products</h1>
    <%= render partial: "product", collection: @products %>
    ```

* `_product.html.erb`

    ```html+erb
    <p>Product Name: <%= product.name %></p>
    ```

複数形のコレクションを渡してパーシャルを呼び出すと、パーシャルの個別のインスタンスは、パーシャルと同じ名前の変数（アンダースコアなし）を経由してコレクションの個別のメンバーにアクセスできます。上の場合はパーシャル名が`_product`なので、`_product`パーシャル内で`product`という名前の変数を参照することで、レンダリングされるインスタンスを取得できます。

コレクションのレンダリングにはショートハンド記法もあります。`@products`が`product`インスタンスのコレクションであるとすると、`index.html.erb`に以下のように書くことで同じ結果を得られます。

```html+erb
<h1>Products</h1>
<%= render @products %>
```

ここで使われるパーシャル名は、コレクションのモデル名に基いて決定されます。
実は、一様でない（種類の異なるメンバーを含む）コレクションでも上の方法が使えます。この場合、コレクションのメンバーに応じて適切なパーシャルが自動的に選択されます。

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

上のコードでは、コレクションのメンバーに応じてcustomerパーシャルまたはemployeeパーシャルが自動的に選択されます。

コレクションが空の場合は`render`がnilを返すので、以下のような比較的簡単な方法で代わりのコンテンツを表示するようにしましょう。

```html+erb
<h1>Products</h1>
<%= render(@products) || "製品はありません。" %>
```

#### ローカル変数

パーシャル内で独自のローカル変数を使いたい場合は、`:as`オプションを指定してパーシャルを呼び出します。

```erb
<%= render partial: "product", collection: @products, as: :item %>
```

上のように変更することで、`item`という名前のローカル変数で`@products`コレクションのインスタンスにアクセスできるようになります。

`locals: {}`オプションを使うと、レンダリングするパーシャルに任意のローカル変数を渡せます。

```erb
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

上の場合、`title`という名前のローカル変数に"Products Page"という値が含まれており、パーシャルからこの値にアクセスできるようになります。

TIP: コレクションによって呼び出されるパーシャル内では、カウンタ変数も利用できます。このカウンタ変数は、パーシャル名の末尾に`_counter`を追加した名前になります。たとえば、パーシャル内で`@products`をレンダリングするときに、`_product.html.erb`で`product_counter`変数を参照できます。`product_counter`変数は、それを囲むビュー内でレンダリングされた回数を表します。
なお、これは`as:`オプションでパーシャル名を変更した場合にも該当します。たとえば上のコードのカウンタ変数は`item_counter`になります。

#### スペーサーテンプレート

`:spacer_template`オプションを使うと、メインパーシャルのインスタンスと交互にレンダリングしたい調整用のセカンドパーシャルを指定できます。

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

上のコードは、`_product`パーシャルと`_product`パーシャルの間に`_product_ruler`パーシャル（引数を受け取らない）をレンダリングします。

#### コレクションのパーシャルレイアウト

コレクションをレンダリングするときにも`:layout`オプションを指定できます。

```erb
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

このレイアウトは、コレクション内の各項目をレンダリングするたびに一緒にレンダリングされます。パーシャル内の場合と同様、このレイアウトでも現在のオブジェクトと`オブジェクト名_counter`変数を利用できます。

### ネステッドレイアウトを使う

特定のコントローラをサポートするために、アプリケーションの標準レイアウトをほんの少し変えたレイアウトが必要になることがあります。メインのレイアウトを複製して編集したりしなくても、ネステッドレイアウト（サブテンプレートと呼ばれることもあります）を使えばこのようなレイアウトを実現できます。

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

`NewsController`で生成されるページでは、トップメニューを隠して右メニューを追加したいとします。

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

以上で完了です。これによってNewsビューで新しいレイアウトが使われるようになり、トップメニューが隠されて"content" `div`タグ内に右メニューが新しく追加されます。

この手法を用いる別のサブテンプレートでも同様の結果を得る方法はいくつも考えられます（ネストのレベルに制限はありません）。`ActionView::render`メソッドを`render template: 'layouts/news'`経由で使うと、`News`レイアウトで新しいレイアウトがベースになります。`News`レイアウトをサブテンプレート化する予定がない場合は、単に`content_for?(:news_content) ? yield(:news_content) : yield`を`yield`に置き換えれば済みます。
