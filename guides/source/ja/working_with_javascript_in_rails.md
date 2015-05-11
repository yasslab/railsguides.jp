
Rails で JavaScript を使用する
================================

本ガイドでは、RailsにビルトインされているAjax/JavaScript機能などについて解説します。これらを活用して、リッチな動的Ajaxアプリケーションをお手軽に作ることができます。

このガイドの内容:

* Ajaxの基礎
* 「控えめなJavaScript」について
* Railsのビルトインヘルパーの活用方法
* サーバー側でAjaxを扱う方法
* Turbolinks gem

-------------------------------------------------------------------------------

はじめてのAjax
------------------------

Ajaxを理解するには、Webブラウザの基本的な動作について理解しておく必要があります。

ブラウザのアドレスバーに`http://localhost:3000`と入力して'Go'を押すと、ブラウザ (つまりクライアント) はサーバーに対してリクエストを1つ送信します。ブラウザは、サーバーから受け取ったレスポンスを解析し、続いて必要なすべてのアセット (JavaScriptファイル、スタイルシート、画像) をサーバーから取得します。続いてブラウザはページを組み立てます。ブラウザに表示されているリンクをクリックすると、同じプロセスが実行されます。ブラウザはページを取得し、続いてアセットを取得し、それらをすべてまとめてから結果を表示します。これが、いわゆる「リクエスト-レスポンス」のサイクルです。

JavaScriptも、上と同様にサーバーにリクエストを送信し、レスポンスを解析することができます。JavaScriptはページ上の情報を更新することもできます。JavaScriptの開発者は、ブラウザとJavaScriptという2つの力を1つに結集させることで、現在のWebページの一部だけを更新することができます。必要なWebページをサーバーからすべて取得する必要はありません。この強力な技法が、Ajaxと呼ばれているものです。

Railsには、JavaScriptをさらに使いやすくしたCoffeeScriptがデフォルトで組み込まれています。以後、本ガイドではすべての例をCoffeeScriptで記述します。もちろん、これらのレッスンはすべて通常のJavaScriptにも適用できます。

例として、jQueryライブラリを使用してAjaxリクエストを送信するCoffeeScriptコードを以下に示します。

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

上のコードは "/test" からデータを取得し、結果をWebページ上の`results`というidを持つ`div`タグに押し込みます。

Railsには、この種の技法をWebページ作成で使用するためのサポートが多数ビルトインされています。従って、こうしたコードをすべて自分で作成する必要はほとんどありません。この後、このような手法でRails Webサイトを作成する方法をご紹介します。これらの手法は、いずれもシンプルな基本テクニックのうえに成り立っています。

「控えめなJavaScript」
-------------------------------------

Railsでは、JavaScriptをDOMに追加する際の手法を「控えめな (unobtrusive) JavaScript」と呼んでいます。これは一般にフロントエンド開発者コミュニティでベストプラクティスであると見なされていますが、ここではもう少し違う角度から説明したいと思います。

最もシンプルなJavaScriptを例にとって考えてみましょう。以下のような書き方は'インラインJavaScript'と呼ばれています。

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```
このリンクをクリックすると、背景が赤くなります。しかし早くもここで問題が生じ始めます。クリックした時にJavaScriptでもっといろんなことをさせるとどうなるでしょうか。

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

だいぶ乱雑になってきました。ではここで関数定義をclickハンドラの外に追い出し、CoffeeScriptで書き換えてみましょう。

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

ページの内容は以下のとおりです。

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

これでコードがだいぶ良くなりました。しかし、同じ効果を複数のリンクに与えるとどうなるでしょうか。

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

これではDRYとは言えません。今度はイベントを活用して改良してみましょう。最初に`data-*`属性をリンクに追加しておきます。続いて、この属性を持つすべてのリンクで発生するクリックイベントにハンドラをバインドします。

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click (e) ->
    e.preventDefault()

    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```
```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

私たちはこの手法を「控えめなJavaScript」と呼んでいます。この名称は、HTMLの中にJavaScriptを混入させないという意図に由来しています。JavaScriptを正しく分離することができたので、今後の変更が容易になりました。今後は、この`data-*`属性をリンクタグに追加するだけでこの動作を簡単に追加できます。Railsでは、こうした最小化と連結を使用することで、あらゆるJavaScriptを実行できます。JavaScriptコードはRailsのあらゆるWebページでまるごとバンドルされます。つまり、ページが最初にブラウザに読み込まれるときにダウンロードされ、以後はブラウザでキャッシュされます。これにより多くの利点が得られます。

Railsチームは、本ガイドでご紹介した方法でCoffeeScriptとJavaScriptを使用することを強く推奨いたします。多くのJavaScriptライブラリもこの方法で利用できることが期待できます。

組み込みヘルパー
----------------------

HTML生成を行い易くするために、Rubyで記述されたさまざまなビューヘルパーメソッドが用意されています。それらのHTML要素にAjaxコードを若干追加したくなったときにも、Railsがちゃんとサポートしてくれます。

RailsのJavaScriptは、「控えめなJavaScript」原則に基いて、JavaScriptによる要素とRubyによる要素の2つの要素で構成されています。

JavaScriptによる要素は[rails.js](https://github.com/rails/jquery-ujs/blob/master/src/rails.js)であり、Rubyによる要素である正規のビューヘルパーによってDOMに適切なタグが追加されます。これによりrails.jsに含まれるCoffeeScriptがDOMの属性をリッスンするようになり、それらの属性に適切なハンドラが与えられます。

### form_for

[`form_for`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for) はフォーム作成を支援するヘルパーです。`form_for`は、JavaScriptを利用するための`:remote`オプションを引数に取ることができます。この動作は次のようになります。

```erb
<%= form_for(@article, remote: true) do |f| %>
  ...
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form accept-charset="UTF-8" action="/articles" class="new_article" data-remote="true" id="new_article" method="post">
  ...
</form>
```

formタグに`data-remote="true"`という属性が追加されていることにご注目ください。これにより、フォームの送信がブラウザによる通常の送信メカニズムではなくAjaxによって送信されるようになります。

記入済みの`<form>`を得られただけでは何か物足りません。フォーム送信が成功した場合に何らかの表示を行いたいものです。これを行なうには、`ajax:success`イベントをバインドします。送信に失敗した場合は`ajax:error`を使用します。実際に見てみましょう。

```coffeescript
$(document).ready ->
  $("#new_article").on("ajax:success", (e, data, status, xhr) ->
    $("#new_article").append xhr.responseText
  ).on "ajax:error", (e, xhr, status, error) ->
    $("#new_article").append "<p>ERROR</p>"
```

明らかに、従来の書き方よりも洗練されています。しかしこれはほんのさわりです。詳細については、[jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki/ajax)に掲載されているイベントを参照してください。

### form_tag

[`form_tag`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag) は`form_for`とよく似ています。このメソッドには`:remote`オプションがあり、以下のように使用できます。

```erb
<%= form_tag('/articles', remote: true) do %>
  ...
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form accept-charset="UTF-8" action="/articles" data-remote="true" method="post">
  ...
</form>
```

その他の点は`form_for`と同じです。詳細についてはドキュメントを参照してください。

### link_to

[`link_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to) はリンクの生成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使用できます。

```erb
<%= link_to "an article", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<a href="/articles/1" data-remote="true">an article</a>
```

`form_for`の場合と同様、同じAjaxイベントをバインドできます。例を以下に示します。1クリックで削除できる記事の一覧があるとします。このHTMLは以下のような感じになります。

```erb
<%= link_to "Delete article", @article, remote: true, method: :delete %>
```

上に加え、以下の様なCoffeeScriptを作成します。

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The article was deleted."
```

### button_to

[`button_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)はボタン作成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使用できます。

```erb
<%= button_to "An article", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<form action="/articles/1" class="button_to" data-remote="true" method="post">
  <div><input type="submit" value="An article"></div>
</form>
```

作成されるのは通常の`<form>`なので、`form_for`に関する情報はすべて`button_to`にも適用できます。

サーバー側で考慮すべき点
--------------------

Ajaxはクライアント側だけでなく、ある程度サーバー側でのサポートも必要です。Ajaxリクエストに対してレスポンスを返す際の形式は、HTMLよりもJSONを使用することが好まれるようです。それでは、必要となるものについて解説します。

### シンプルな例

表示したいユーザーリストがあり、そのページに新規ユーザーを作成するフォームも置きたいとします。このコントローラのindexアクションは以下のようになります。

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

indexビュー (`app/views/users/index.html.erb`) の内容は以下のようになります。

```erb
<b>Users</b>

<ul id="users">
<%= render @users %>
</ul>

<br>

<%= form_for(@user, remote: true) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

`app/views/users/_user.html.erb`パーシャルの内容は以下のようになります。

```erb
<li><%= user.name %></li>
```

indexページの上部にはユーザーの一覧が表示されます。下部にはユーザー作成用のフォームが表示されます。

下部のフォームは`UsersController`の`create`アクションを呼び出します。フォームのremoteオプションがオンになっているので、リクエストはAjaxリクエストとして`UsersController`に渡され、JavaScriptを探します。コントローラ内でリクエストに応答する`create`アクションは以下のようになります。

```ruby
# app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js   {}
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

format.jsが`respond_to`ブロックの中にある点にご注目ください。これによって、 コントローラがAjaxリクエストに応答できるようになります。続いて、対応する`app/views/users/create.js.erb`ビューファイルを作成します。実際のJavaScriptはこのビューで生成され、クライアントに送信されてそこで実行されます。

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
----------

Rails 4には[Turbolinks gem](https://github.com/rails/turbolinks)が同梱されています。このgemでは、ページのレンダリングを多くのページで高速化するのにAjaxを使用しています。

### Turbolinksの動作原理

Turbolinksは、ページにあるすべての`<a>`にクリックハンドラを1つずつ追加します。ブラウザで[PushState](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#The_pushState\(\).C2.A0method)がサポートされている場合、Turbolinksはそのページ用のAjaxリクエストを生成し、サーバーからのレスポンスを解析し、そのページの`<body>`全体をレスポンスの`<body>`で置き換えます。続いて、TurbolinksはPushStateを使用してURLを正しいものに書き換え、リフレッシュのセマンティクスを維持しながらプリティURLを与えます。

Turbolinksを有効にするには、TurbolinksをGemfileに追加し、CoffeeScriptのマニフェスト (通常は`app/assets/javascripts/application.js`) に`//= require turbolinks`を追加します。

Turbolinksを特定のリンクでのみ無効にしたい場合は、タグに`data-no-turbolink`属性を追加します。

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### ページ変更イベント

CoffeeScriptコードを開発中、ページ読み込みに関連する処理を追加したくなることがよくあります。jQueryを使用するのであれば、たとえば以下のようなコードを書くことがあるでしょう。

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

しかし、通常のページ読み込みプロセスはTurbolinksによって上書きされてしまうため、ページ読み込みに依存するイベントはトリガされません。このようなコードがある場合は、以下のように書き換えなければなりません。

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

この他にバインド可能なイベントなどの詳細については、[Turbolinks README](https://github.com/rails/turbolinks/blob/master/README.md)を参照してください。

その他の情報源
---------------

詳細の学習に役立つリンクをいくつか紹介します。

* [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki)
* [jquery-ujsに関する外部記事のリスト](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote LinksとFormsについて: 決定版ガイド](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: 控えめなJavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks?language=ja&view=asciicast) (日本語)