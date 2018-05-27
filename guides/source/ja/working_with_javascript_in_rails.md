
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

Railsでは、JavaScriptをDOMに追加する際の手法を「UJS: Unobtrusive（控えめな）JavaScript」と呼んでいます。これは一般にフロントエンド開発者コミュニティでベストプラクティスであると見なされていますが、ここではもう少し違う角度から説明したいと思います。

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
@paintIt = (element, backgroundColor, textColor) ->
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
@paintIt = (element, backgroundColor, textColor) ->
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

私たちはこの手法を「UJS: Unobtrusive（控えめな）JavaScript」と呼んでいます。この名称は、HTMLの中にJavaScriptを混入させないという意図に由来しています。JavaScriptを正しく分離することができたので、今後の変更が容易になりました。今後は、この`data-*`属性をリンクタグに追加するだけでこの動作を簡単に追加できます。Railsでは、こうした最小化と連結を使用することで、あらゆるJavaScriptを実行できます。JavaScriptコードはRailsのあらゆるWebページでまるごとバンドルされます。つまり、ページが最初にブラウザに読み込まれるときにダウンロードされ、以後はブラウザでキャッシュされます。これにより多くの利点が得られます。

Railsチームは、本ガイドでご紹介した方法でCoffeeScriptとJavaScriptを使用することを強く推奨いたします。多くのJavaScriptライブラリもこの方法で利用できることが期待できます。

組み込みヘルパー
----------------------

HTML生成を行い易くするために、Rubyで記述されたさまざまなビューヘルパーメソッドが用意されています。それらのHTML要素にAjaxコードを若干追加したくなったときにも、Railsがちゃんとサポートしてくれます。

RailsのJavaScriptは、「控えめなJavaScript」原則に基いて、JavaScriptによる要素とRubyによる要素の2つの要素で構成されています。

JavaScriptによる要素は[rails-ujs](https://github.com/rails/rails/tree/master/actionview/app/assets/javascripts)であり、Rubyによる要素である正規のビューヘルパーによってDOMに適切なタグが追加されます。

アプリ内の`remote`要素を扱うその他の発火イベントについては以下をご覧ください。

#### form_with

[`form_with`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with) はフォーム作成を支援するヘルパーです。`form_with`では、デフォルトでAjaxをフォームで使えることが前提になっています。`form_with`に`:local`オプションを渡すことでこの振る舞いを変更できます。

```erb
<%= form_with(model: @article) do |f| %>
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
  $("#new_article").on("ajax:success", (event) ->
    [data, status, xhr] = event.detail
  ).on "ajax:error", (event) ->
    $("#new_article").append "<p>ERROR</p>"
```

明らかに、従来の書き方よりも洗練されています。しかしこれはほんのさわりです。

NOTE: Rails 5.1では新しい`rails-ujs`が導入されたことにより、`data, status, xhr`パラメータは`event.detail`に組み込まれました。Rails 5およびそれ以前で利用されていた`jquery-ujs`について詳しくは、[`jquery-ujs` wiki](https://github.com/rails/jquery-ujs/wiki/ajax)をお読みください。

#### link_to

[`link_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to) はリンクの生成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使用できます。

```erb
<%= link_to "記事", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<a href="/articles/1" data-remote="true">記事</a>
```

`form_with`の場合と同様、同じAjaxイベントをバインドできます。例を以下に示します。1クリックで削除できる記事の一覧があるとします。このHTMLは以下のような感じになります。

```erb
<%= link_to "記事を削除", @article, remote: true, method: :delete %>
```

上に加え、以下の様なCoffeeScriptを作成します。

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (event) ->
    alert "この記事を削除しました"
```

#### button_to

[`button_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)はボタン作成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使用できます。

```erb
<%= button_to "記事", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<form action="/articles/1" class="button_to" data-remote="true" method="post">
  <input type="submit" value="記事" />
</form>
```

作成されるのは通常の`<form>`なので、`form_with`に関する情報はすべて`button_to`にも適用できます。

### `remote`要素をカスタマイズする

`data-remote`属性を用いることで、JavaScriptを一行も書かずに要素の振る舞いをカスタマイズできます。`data-`属性を他にも指定することでこれを行うこともできます。

#### `data-method`

ハイパーリンクをクリックすると、常にHTTP `GET`リクエストが発生します。しかし実際には、[RESTful](https://en.wikipedia.org/wiki/Representational_State_Transfer)なアプリのリンクの中には、クリックするとサーバーのデータを変更するものもあり、そうした操作は`GET`以外のリクエストで行わなければなりません。この`data-method`属性は、そうしたリンクのHTTPメソッドに`POST`や`PUT`や`DELETE`を明示的に指定できます。

この方法を用いると、リンクをクリックしたときにドキュメント内に隠しフォームが作成されます。そこにはリンクの`href`値に対応する`action`属性や`data-method`値に対応するHTTPメソッドを含まれており、そのフォームが送信されます。

NOTE: `GET`や`POST`以外のHTTPメソッドによるフォーム送信をサポートするブラウザは多くないため、実際にはそうした他のHTTPメソッドは`_method`パラメータで指定する形で`POST`メソッドとして送信されます。Railsはこうした点を自動検出してカバーします。

#### `data-url`と`data-params`

ページの特定の要素が実際にはURLを参照していなくても、これを用いてAjax呼び出しをトリガしたいことがあります。`data-remote`で`data-url`属性を指定すると、そこで指定されたURLを用いてAjax呼び出しをトリガできます。`data-params`属性を介してこの他にもパラメータを指定できます。

たとえば、チェックボックスを操作したときに何らかの操作をトリガできると便利な場合があります。

```html
<input type="checkbox" data-remote="true"
    data-url="/update" data-params="id=10" data-method="put">
```

#### `data-type`

`data-type`属性を用いることで、`data-remote`を用いるリクエストを実行する際にAjaxの`dataType`属性を明示的に定義することもできます。

### 確認ダイアログ

リンクやフォームに`data-confirm`属性を追加することで、確認ダイアログをさらに表示できます。ユーザーに表示されるのはJavaScriptの`confirm()`ダイアログで、この属性のテキストがダイアログに表示されます。ユーザーがダイアログをキャンセルすると、その操作は実行されません。

`data-confirm`属性をリンクに追加した場合は、クリック時にダイアログがトリガされます。フォームに追加した場合は、送信時にトリガされます。次の例をご覧ください。

```erb
<%= link_to "Dangerous zone", dangerous_zone_path,
  data: { confirm: 'よろしいですか？' } %>
```

上のコードから以下が生成されます。

```html
<a href="..." data-confirm="よろしいですか？">Dangerous zone</a>
```

`data-confirm`属性はフォームの送信ボタンにも使えます。これを使うと、クリックしたボタンに応じて警告メッセージを変更できます。ただし、この場合はフォームそのものに`data-confirm`属性を追加しては**いけません**。

デフォルトの確認ダイアログではJavaScriptの確認ダイアログが使われますが、`confirm`イベントをリッスンすればこの振る舞いをカスタマイズできます。`confirm`イベントは確認ウィンドウがユーザーに表示される直前に発火します。このデフォルトの確認ダイアログをキャンセルするには、確認ハンドラで`false`を返してください。

### 入力を自動で無効にする

`data-disable-with`属性を用いて、フォームを送信するときに入力フィールドを自動で無効にすることもできます。これは、ユーザーの「2回クリック」誤操作を防止するためのものです。2回クリックされてしまうとHTTPリクエストが重複してしまい、バックエンド側で検出できなくなる可能性があります。`data-disable-with`属性の値は、無効状態になったボタンテキストの新しい値になります。

`data-disable-with`属性は、`data-method`属性を持つリンクでも使えます。

次の例をご覧ください。

```erb
<%= form_with(model: @article.new) do |f| %>
  <%= f.submit data: { "disable-with": "保存しています..." } %>
<%= end %>
```

上のコードから以下のフォームが生成されます。

```html
<input data-disable-with="保存しています..." type="submit">
```

### rails-ujsのイベントハンドラ

Rails 5.1ではrails-ujsが導入され、jQueryに依存しなくなりました。この結果、UJS（Unobtrusive JavaScript）ドライバが書き直されてjQueryなしで使えるようになりました。rails-ujsが導入されたことによって、リクエスト中に発火する`custom events`に若干変更が生じます。

NOTE: UJSイベントハンドラ呼び出しのシグネチャは変更されました。jQueryの場合と異なり、あらゆるカスタムイベントは`event`パラメータだけを返します。このパラメータには`detail`という属性が追加されており、追加パラメータの配列がその中に1つ含まれています。

| イベント名          | 追加のパラメータ（`event.detail`） | 発火のタイミング                                                       |
|---------------------|---------------------------------|-------------------------------------------------------------|
| `ajax:before`       |                                 | Ajax全体が作動する前                             |
| `ajax:beforeSend`   | [xhr, options]                  | リクエストが送信される前                                 |
| `ajax:send`         | [xhr]                           | リクエストの送信時                                   |
| `ajax:stopped`      |                                 | リクエストの停止時                                |
| `ajax:success`      | [response, status, xhr]         | 完了後、レスポンス成功時            |
| `ajax:error`        | [response, status, xhr]         | 完了後、レスポンスエラー時             |
| `ajax:complete`     | [xhr, status]                   | リクエスト完了時（結果にかかわらず）|

利用例は次のとおりです。

```html
document.body.addEventListener('ajax:success', function(event) {
  var detail = event.detail;
  var data = detail[0], status = detail[1],  xhr = detail[2];
})
```

NOTE: Rails 5.1では新しい`rails-ujs`が導入されたことにより、`data, status, xhr`パラメータは`event.detail`に組み込まれました。Rails 5およびそれ以前で利用されていた`jquery-ujs`について詳しくは、[`jquery-ujs` wiki](https://github.com/rails/jquery-ujs/wiki/ajax)をお読みください。

### 停止してもよいイベント

ハンドラメソッドから`false`を返すことで`ajax:before`や`ajax:beforeSend`を停止すると、以後のAjaxリクエストがまったく発生しなくなります。`ajax:before`イベントがフォームのデータを操作できるのはシリアライズ前なので、独自のリクエストヘッダを追加するには`ajax:beforeSend`が便利です。

`ajax:aborted:file`イベントを停止すると、ブラウザがフォームを通常の方法（Ajaxを用いない送信など）で送信するときのデフォルトの振る舞いがキャンセルされ、以後そのフォームは送信されなくなります。この動作は、独自のAjaxでファイルアップロードを実装するときの回避方法として便利です。

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

<%= form_with(model: @user) do |f| %>
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
        format.js
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

`format.js`が`respond_to`ブロックの中にある点にご注目ください。これによって、 コントローラがAjaxリクエストに応答できるようになります。続いて、対応する`app/views/users/create.js.erb`ビューファイルを作成します。実際のJavaScriptはこのビューで生成され、クライアントに送信されてそこで実行されます。

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
----------

Railsには[Turbolinksライブラリ](https://github.com/turbolinks/turbolinks)が同梱されており、Ajaxを利用して多くのアプリケーションでページのレンダリングを高速化しています。

### Turbolinksの動作原理

Turbolinksは、ページにあるすべての`<a>`にクリックハンドラを1つずつ追加します。ブラウザで[PushState](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#The_pushState\(\).C2.A0method)がサポートされている場合、Turbolinksはそのページ用のAjaxリクエストを生成し、サーバーからのレスポンスを解析し、そのページの`<body>`全体をレスポンスの`<body>`で置き換えます。続いて、TurbolinksはPushStateを使用してURLを正しいものに書き換え、リフレッシュのセマンティクスを維持しながらプリティURLを与えます。

Turbolinksを有効にするには、TurbolinksをGemfileに追加し、JavaScriptのマニフェスト (通常は`app/assets/javascripts/application.js`) に`//= require turbolinks`を追加します。

Turbolinksを特定のリンクでのみ無効にしたい場合は、タグに`data-turbolinks="false"`属性を追加します。

```html
<a href="..." data-turbolinks="false">No turbolinks here</a>.
```

### ページ変更イベント

CoffeeScriptコードを開発中、ページ読み込みに関連する処理を追加したくなることがよくあります。jQueryを使用するのであれば、たとえば以下のようなコードを書くことがあるでしょう。

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

しかし、通常のページ読み込みプロセスはTurbolinksによって上書きされてしまうため、ページ読み込みに依存するイベントはトリガされません。このようなコードがある場合は、以下のように書き換えなければなりません。

```coffeescript
$(document).on "turbolinks:load", ->
  alert "page has loaded!"
```

この他にバインド可能なイベントなどの詳細については、[Turbolinks README](https://github.com/turbolinks/turbolinks/blob/master/README.md)を参照してください。

その他の情報源
---------------

詳細の学習に役立つリンクをいくつか紹介します。

* [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki)
* [jquery-ujsに関する外部記事のリスト](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote LinksとFormsについて: 決定版ガイド](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: 控えめなJavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks?language=ja&view=asciicast) (日本語)
