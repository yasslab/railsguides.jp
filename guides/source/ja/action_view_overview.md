
Action View の概要
====================

このガイドの内容:

* Action Viewの概要とRailsでの利用法
* テンプレート、パーシャル(部分テンプレート)、レイアウトの最適な利用法
* Action Viewで提供されるヘルパーの紹介と、カスタムヘルパーの作成法
* ビューのローカライズ方法
* Rails以外の環境でAction Viewを使用する方法

--------------------------------------------------------------------------------

Action Viewについて
--------------------

Action ViewおよびAction Controllerは、Action Packを構成する2大要素です。Railsでは、WebリクエストはAction Packで取り扱われます。この動作はコントローラ寄りの部分 (ロジックの実行) とビュー寄りの部分(テンプレートの描画) に分かれます。Action Controllerは、データベースとのやりとりや、必要に応じたCRUD (Create/Read/Update/Delete) アクションの実行にかかわります。Action View はその後レスポンスを実際のWebページにまとめる役割を担います。

Action Viewのテンプレートは、HTMLタグの合間にERB (Embedded Ruby) を含む形式で書かれます。ビューテンプレートがコードの繰り返しでうずまって乱雑になるのを避けるために、フォーム・日付・文字列に対して共通の動作を提供するヘルパークラスが多数用意されています。アプリケーションの機能向上に応じて独自のヘルパーを追加することも簡単にできます。

NOTE: Action Viewの一部の機能はActive Recordと結びついていますが、Action ViewがActive Recordに依存しているわけではありません。Action Viewは独立したパッケージであり、どのようなRubyライブラリとでも組み合わせて使用できます。

Action ViewをRailsで使用する
----------------------------

アプリケーションの`app/views`ディレクトリには、1つのコントローラごとに1つのディレクトリが作成され、そこにビューテンプレートファイルが置かれます。このビューテンプレートはそのコントローラと関連付けられています。これらのファイルは、コントローラ内にあるアクションごとに出力された結果をビューで表示するために使用されます。

scaffoldを使用してリソースを生成するときに、Railsがデフォルトでどんなことを行なうのか見てみましょう。

```bash
$ rails generate scaffold post
      [...]
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      create      app/views/posts/index.html.erb
      create      app/views/posts/edit.html.erb
      create      app/views/posts/show.html.erb
      create      app/views/posts/new.html.erb
      create      app/views/posts/_form.html.erb
      [...]
```

Railsのビューには命名規則があります。上で生成されたファイルを見るとわかるように、ビューテンプレートファイルは基本的にコントローラのアクションと関連付けられています。
たとえば、`posts_controller.rb`コントローラのindexアクションは、`app/views/posts`ディレクトリの`index.html.erb`を使用します。
これらのERBファイルに、それらを内包するレイアウトテンプレートや、ビューから参照されるあらゆるパーシャル (部分テンプレート) が組み合わさって完全なHTMLが生成され、クライアントに送信されます。この後、本ガイドではこれらの3つの要素について詳細に説明します。


テンプレート、パーシャル、レイアウト
-------------------------------

前述のとおり、Railsが出力する最終的なHTMLは`テンプレート`、`パーシャル`、`レイアウト`の3つの要素から成ります。
まずこれらについて簡単に説明いたします。

### テンプレート

Action Viewのテンプレートはさまざまな方法で記述することができます。テンプレートの拡張子が`.erb`であれば、ERB (ここにRubyのコードが含まれます) とHTMLが含まれます。テンプレートの拡張子が`.builder`であれば、`Builder::XmlMarkup`ライブラリの新鮮なインスタンスが使用されます。

Railsでは複数のテンプレートシステムがサポートされており、テンプレートファイルの拡張子で区別されます。たとえば、ERBテンプレートシステムを使用するHTMLファイルの拡張子は`.html.erb`になります。

#### ERB

ERBテンプレートの内部では、`<% %>`タグや`<%= %>`タグにRubyコードを含めることができます。最初の`<% %>`タグはその中に書かれたRubyコードを実行しますが、実行結果は出力されません。条件文やループ、ブロックなど出力の不要な行はこのタグの中に書くとよいでしょう。次の`<%= %>`タグでは実行結果がWebページに出力されます。

以下は、名前を出力するためのループです。

```html+erb
<h1>Names of all the people</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

ループの開始行と終了行は通常のERBタグ (`<% %>`) に書かれており、名前を出力する行は出力用のERBタグ (`<%= %>`) に書かれています。上のコードは、単にERBの書き方を説明しているだけではありません。Rubyでよく使用される`print`や`puts`のような通常の出力関数はERBでは使用できませんのでご注意ください。以下のコードは誤りです。

```html+erb
<%# 間違い %>
Hi, Mr. <% puts "Frodo" %>
```

なお、Webページへの出力結果の最初と最後からホワイトスペースを取り除きたい場合は`<%-` および `-%>`を通常の`<%` および `%>`と交互にご使用ください (訳注: これは英語のようなスペース分かち書きを行なう言語向けのノウハウです)。

#### Builderテンプレート

BuilderテンプレートはERBの代わりに使用できる、よりプログラミング向きな記法です。これは特にXMLコンテンツの生成を得意とします。テンプレートの拡張子を`.builder`にすると、`xml`という名前のXmlMarkupオブジェクトが自動で使用できるようになります。

基本的な例を以下にいくつか示します。

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "http://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

上のコードから以下が生成されます。

```html
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="http://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

ブロックを後ろに伴うメソッドはすべて、ブロックの中にネストしたマークアップを含むXMLマークアップタグとして扱われます。以下の例で示します。

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

上のコードの出力は以下のようなものになります。

```html
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

以下はBasecampで実際に使用されているRSS出力コードをそのまま引用したものです。

```ruby
xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    xml.title(@feed_title)
    xml.link(@url)
    xml.description "Basecamp: Recent items"
    xml.language "en-us"
    xml.ttl "40"

    for item in @recent_items
      xml.item do
        xml.title(item_title(item))
        xml.description(item_description(item)) if item_description(item)
        xml.pubDate(item_pubDate(item))
        xml.guid(@person.firm.account.url + @recent_items.url(item))
        xml.link(@person.firm.account.url + @recent_items.url(item))
        xml.tag!("dc:creator", item.author_name) if item_has_creator?(item)
      end
    end
  end
end
```

#### テンプレートをキャッシュする

Railsは、デフォルトですべてのビューテンプレートをコンパイルしてメソッド化し、出力に備えます。developmentモードの場合、ビューテンプレートが変更されるとファイルの日付で変更が検出され、再度コンパイルされます。

### パーシャル

部分テンプレートまたはパーシャルは、出力を扱いやすく分割するための仕組みです。パーシャルを使用することで、ビュー内のコードをいくつものファイルに分割して書き出し、他のテンプレートでも使いまわすことができます。

#### パーシャルの命名ルール

パーシャルをビューの一部に含めて出力するには、ビューで`render`メソッドを使用します。

```erb
<%= render "menu" %>
```

上の呼び出しにより、`_menu.html.erb`という名前のファイルの内容が、renderメソッドを書いたその場所でレンダリングされます。パーシャルファイル名の冒頭にはアンダースコアが付いていることにご注意ください。これは通常のビューと区別するために付けられています。ただしrenderで呼び出す際にはこのアンダースコアは不要です。以下のように、他のフォルダの下にあるパーシャルを呼び出す際にもアンダースコアは不要です。

```erb
<%= render "shared/menu" %>
```

上のコードでは、`app/views/shared/_menu.html.erb`パーシャルを読み込んで使用します。

#### パーシャルを活用してビューを簡潔に保つ

すぐに思い付くパーシャルの使い方といえば、パーシャルをサブルーチンと同等のものとみなすというのがあります。ビューの詳細部分をパーシャルに移動し、コードの見通しを良くするために、パーシャルを使うのです。たとえば、以下のようなビューがあるとします。

```html+erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: {product: product} %>
<% end %>

<%= render "shared/footer" %>
```

上のコードの`_ad_banner.html.erb`パーシャルと`_footer.html.erb`パーシャルに含まれるコンテンツは、アプリケーションの多くのページと共有できます。あるページを開発中、パーシャルの部分については詳細を気にせずに済みます。

#### `as`と`object`オプション

`ActionView::Partials::PartialRenderer`は、デフォルトでテンプレートと同じ名前を持つローカル変数の中に自身のオブジェクトを持ちます。以下のコードを見てみましょう。

```erb
<%= render partial: "product" %>
```

上のコードでは、ローカル変数である`product`の中に`@product`が置かれます。これは以下のコードと同等の結果になります。

```erb
<%= render partial: "product", locals: {product: @product} %>
```

`as`オプションは、ローカル変数の名前を変更したい場合に使用します。たとえば、ローカル変数名を`product`ではなく`item`にしたいのであれば、以下のようにします。

```erb
<%= render partial: "product", as: "item" %>
```

`object`オプションは、パーシャルで出力するオブジェクトを直接指定したい場合に使用します。これは、テンプレートのオブジェクトが他の場所 (別のインスタンス変数や別のローカル変数) にある場合に便利です。

たとえば、以下のコードがあるとします。

```erb
<%= render partial: "product", locals: {product: @item} %>
```

上のコードは以下のようになります。

```erb
<%= render partial: "product", object: @item %>
```

`object`オプションと`as`オプションは同時に使用することもできます。

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

#### コレクションを出力する

テンプレート上にコレクションを1つ表示し、サブテンプレートでそのコレクションの要素を1つずつ出力するというのは、よくあるパターンです。このパターンは1つのメソッドだけで実行できます。このメソッドは配列を受け取り、配列内の各要素ごとにパーシャルを出力します。

すべての製品(products)を出力するコード例は以下のようになります。

```erb
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

上のコードは以下のように1行で書けます。

```erb
<%= render partial: "product", collection: @products %>
```

パーシャルでこのようにコレクションなどが使用されている場合、パーシャルの各インスタンスは、パーシャル名に基づいた変数を経由して出力されるコレクションのメンバーにアクセスします。このパーシャルは`_product`という名前なので、`product`を指定すれば、出力されるインスタンスを取得できます。

コレクション出力には短縮記法があります。`@products`が`Product`インスタンスのコレクションであれば、以下のコードでも同じ結果を得られます。

```erb
<%= render @products %>
```

使用されるパーシャル名は、コレクションの中にある「モデル名」を参照して決定されます。この場合のモデル名は`Product`です。作成するコレクションの各要素が不揃い (訳注: 要素ごとにモデルが異なる場合を指します) であっても、Railsはコレクションのメンバごとに適切なパーシャルを選んで出力してくれます。

#### スペーサーテンプレート

`:spacer_template`オプションを使用すると、主要なパーシャル同士の間を埋める第二のパーシャルを指定することができます。

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

主要な`_product`パーシャルの合間に、スペーサーとなる`_product_ruler`パーシャルが出力されます (`_product_ruler`にはデータは渡していません)。

### レイアウト

Railsにおける「レイアウト」は、多くのコントローラのアクションにわたって共通して使用できるテンプレートのことです。Railsアプリケーションには必ず全体用のレイアウトがあり、ほぼすべてのWebページ出力はこの全体レイアウトの内側で行われますが、これが典型的なレイアウトです。たとえば、あるWebサイトにはユーザーログイン用のレイアウトが使用されていたり、別のWebサイトにはマーケティングやセールス用のレイアウトが使用されていたりします。ログインしたユーザー向けのレイアウトであれば、ナビゲーションツールバーをページのトップレベルに表示し、多くのコントローラ/アクションで共通して使用できるようにするでしょう。SaaSアプリケーションにおけるセールス用のレイアウトであれば、トップレベルのナビゲーションに「お値段」や「お問い合わせ先」を共通して表示するでしょう。レイアウトごとに異なる外観を設定してこれらを使い分けることができます。レイアウトの詳細については、[ビューのレイアウトとレンダリング](layouts_and_rendering.html) ガイドを参照してください。

パーシャルレイアウト
---------------

パーシャルに独自のレイアウトを適用することができます。パーシャル用のレイアウトは、アクション全体にわたるグローバルなレイアウトとは異なりますが、動作は同じです。

試しに、ページ上に投稿を1つ表示してみましょう。表示制御のため`div`タグで囲むことにします。最初に、`Post`を1つ新規作成します。

```ruby
Post.create(body: 'Partial Layouts are cool!')
```

`show`テンプレートは、`box`レイアウトに内包された`_post`パーシャルを出力します。

**posts/show.html.erb**

```erb
<%= render partial: 'post', layout: 'box', locals: {post: @post} %>
```

`box`レイアウトは、`div`タグの中に`_post`パーシャルを内包した簡単な構造です。

**posts/_box.html.erb**

```html+erb
<div class='box'>
  <%= yield %>
</div>
```

`_post`パーシャルは、投稿の本文(`body`)を`div`タグに内包します(`div_for`を使用して`div`タグに投稿の`id`を与えます)。

**posts/_post.html.erb**

```html+erb
<%= div_for(post) do %>
  <p><%= post.body %></p>
<% end %>
```

上のコードの出力は以下のようになります。

```html
<div class='box'>
  <div id='post_1'>
    <p>Partial Layouts are cool!</p>
  </div>
</div>
```

このパーシャルレイアウトは、`render`呼び出しに渡されたローカルの`post`変数にアクセスできる点にご注目ください。ただし、アプリケーション全体で共通のレイアウトとは異なり、パーシャルレイアウトのファイル名冒頭にはアンダースコアが必要です。

`yield`を呼び出す代わりに、パーシャルレイアウト内にあるコードのブロックを出力することもできます。たとえば、`_post`というパーシャルがない場合でも、以下のような呼び出しが行えます。

**posts/show.html.erb**

```html+erb
<% render(layout: 'box', locals: {post: @post}) do %>
  <%= div_for(post) do %>
    <p><%= post.body %></p>
  <% end %>
<% end %>
```

ここでは、同じ`_box`パーシャルを使用する前提であり、先の例と同じ出力が得られます。

ビューのパス
----------

(執筆予定)

Action Viewが提供するヘルパーの概要
-------------------------------------------

WIP: このリストにまだ含まれていないヘルパーがあります。完全なリストについては[APIドキュメント](http://api.rubyonrails.org/classes/ActionView/Helpers.html)を参照してください。

Action Viewで利用できるヘルパーの概要を以下に示します。[APIドキュメント](http://api.rubyonrails.org/classes/ActionView/Helpers.html) も参照して調べ直すことをお勧めします。APIドキュメントにはすべてのヘルパーの詳細が記載されており、本ガイドは概要を把握するためのものです。

### RecordTagHelper

このモジュールは、`div`などのコンテナタグを生成するメソッドを提供します。Active Recordオブジェクトを出力するためのコンテナ作成方法にはこれを使うことをお勧めします。この方法であれば、適切なクラスとid属性がコンテナに追加されるからです。これにより、これらのコンテナを通常の方法で簡単に参照でき、どのクラスやどのid属性を使用すべきかどうかを考えずに済みます。

#### content_tag_for

Active Recordオブジェクトに関連付けられるコンテナタグを出力します。

たとえば、`@post`が`Post`クラスのオブジェクトであれば、以下のように書くことができます。

```html+erb
<%= content_tag_for(:tr, @post) do %>
  <td><%= @post.title %></td>
<% end %>
```

上のコードによって以下のHTMLが生成されます。

```html
<tr id="post_1234" class="post">
  <td>Hello World!</td>
</tr>
```

オプションのハッシュを追加することで、HTML属性を指定することもできます。例：

```html+erb
<%= content_tag_for(:tr, @post, class: "frontpage") do %>
  <td><%= @post.title %></td>
<% end %>
```

上のコードによって以下のHTMLが生成されます。

```html
<tr id="post_1234" class="post frontpage">
  <td>Hello World!</td>
</tr>
```

Active Recordオブジェクトのコレクションを渡すこともできます。このメソッドはオブジェクトをループで回してそれぞれについてコンテナを作成します。たとえば、`@posts`は`Post`オブジェクトを2つ含む配列であるとします。

```html+erb
<%= content_tag_for(:tr, @posts) do |post| %>
  <td><%= post.title %></td>
<% end %>
```

上のコードによって以下のHTMLが生成されます。

```html
<tr id="post_1234" class="post">
  <td>Hello World!</td>
</tr>
<tr id="post_1235" class="post">
  <td>Ruby on Rails Rocks!</td>
</tr>
```

#### div_for

このメソッドは内部で`content_tag_for`を呼び出して`:div`をタグ名にしてくれる、便利なメソッドです。Active Recordオブジェクトを単体またはコレクションとして渡すことができます。例：

```html+erb
<%= div_for(@post, class: "frontpage") do %>
  <td><%= @post.title %></td>
<% end %>
```

上のコードによって以下のHTMLが生成されます。

```html
<div id="post_1234" class="post frontpage">
  <td>Hello World!</td>
</div>
```

### AssetTagHelper

このモジュールは、画像・JavaScriptファイル・スタイルシート・フィードなどのアセットにビューをリンクするHTMLを生成するメソッドを提供します。

デフォルトでは、現在ホストされているpublicフォルダ内のアセットに対してリンクしますが、アプリケーション設定 (通常は`config/environments/production.rb`) の`config.action_controller.asset_host`で設定されているアセット用サーバーにリンクすることもできます。たとえば、`assets.example.com`というアセット専用ホストを使用したいとします。

```ruby
config.action_controller.asset_host = "assets.example.com"
image_tag("rails.png") # => <img src="http://assets.example.com/images/rails.png" alt="Rails" />
```

#### register_javascript_expansion

javascript_include_tagにシンボルを渡すことで、インクルードしたいJavaScriptファイルを1つまたは複数登録できます。このメソッドの主な目的は、プラグインの初期化中に、プラグインによって`vendor/assets/javascripts`にインストールされたJavaScriptファイルを登録することです。

```ruby
ActionView::Helpers::AssetTagHelper.register_javascript_expansion monkey: ["head", "body", "tail"]

javascript_include_tag :monkey # =>
  <script src="/assets/head.js"></script>
  <script src="/assets/body.js"></script>
  <script src="/assets/tail.js"></script>
```

#### register_stylesheet_expansion

javascript_include_tagにシンボルを渡すことで、インクルードしたいスタイルシートファイルを1つまたは複数登録できます。このメソッドの主な目的は、プラグインの初期化中に、プラグインによって`vendor/assets/stylesheets`にインストールされたスタイルシートファイルを登録することです。

```ruby
ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion monkey: ["head", "body", "tail"]

stylesheet_link_tag :monkey # =>
  <link href="/assets/head.css" media="screen" rel="stylesheet" />
  <link href="/assets/body.css" media="screen" rel="stylesheet" />
  <link href="/assets/tail.css" media="screen" rel="stylesheet" />
```

#### auto_discovery_link_tag

ブラウザやフィードリーダーが検出可能なRSSフィードやAtomフィードのリンクタグを返します。

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", {title: "RSS Feed"}) # =>
  <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed" />
```

#### image_path

`app/assets/images`に置かれている画像アセットへのパスを算出します。ドキュメントルート・ディレクトリからの完全なパスが返されます。このメソッドは`image_tag`の内部で画像へのパス作成に使用されています。

```ruby
image_path("edit.png") # => /assets/edit.png
```

config.assets.digestがtrueに設定されている場合、ファイル名にフィンガープリントが追加されます。

```ruby
image_path("edit.png") # => /assets/edit-2d1a2db63fc738690021fedb5a65b68e.png
```

#### image_url

`app/assets/images`に置かれている画像アセットへのURLを算出します。このメソッドは内部で`image_path`を呼び出しており、現在のホストまたはアセット用のホストとマージしてURLを生成します。

```ruby
image_url("edit.png") # => http://www.example.com/assets/edit.png
```

#### image_tag

HTML imgタグを返します。画像へのフルパス、または`app/assets/images`ディレクトリ内にあるファイルを引数として与えられます。

```ruby
image_tag("icon.png") # => <img src="/assets/icon.png" alt="Icon" />
```

#### javascript_include_tag

引数に与えられたソースごとにHTML scriptタグを返します。`app/assets/javascripts`ディレクトリにあるJavaScriptファイル名 (拡張子`.js`はあってもなくても構いません) を引数として渡すことができます。この結果は現在のページにインクルードされます。ドキュメントルートからの相対完全パスを渡すこともできます。

```ruby
javascript_include_tag "common" # => <script src="/assets/common.js"></script>
```

アプリケーションでアセットパイプラインを使用せずにjQuery JavaScriptライブラリをインクルードする場合は、ソースとして`:defaults`を渡してください。`:defaults`を指定した場合、`app/assets/javascripts`ディレクトリに`application.js`というファイルがあればこれもインクルードされます。

```ruby
javascript_include_tag :defaults
```

ソースに`:all`を指定すると、`app/assets/javascripts`ディレクトリ以下にあるJavaScriptファイルをすべてインクルードできます。

```ruby
javascript_include_tag :all
```

複数のJavaScriptファイルをキャッシュして1つのファイルにすることができます。こうすることでJavaScriptファイルのダウンロードに必要なHTTP接続数を減らすことができ、速度が向上します。gzip圧縮すればさらに転送が速くなります。キャッシュが有効になるのは、`ActionController::Base.perform_caching`をtrueに設定した場合のみです。production環境ではデフォルトでtrueになりますが、development環境ではデフォルトではtrueになりません。

```ruby
javascript_include_tag :all, cache: true # =>
  <script src="/javascripts/all.js"></script>
```

#### javascript_path

`app/assets/javascripts`に置かれているJavaScriptアセットへのパスを算出します。ソースのファイル名に拡張子`.js`がない場合は自動的に補われます。ドキュメントルート・ディレクトリからの完全なパスが返されます。このメソッドは`javascript_include_tag`の内部でスクリプトパス作成に使用されています。

```ruby
javascript_path "common" # => /assets/common.js
```

#### javascript_url

`app/assets/javascripts`に置かれているJavaScriptアセットへのURLを算出します。このメソッドは内部で`javascript_path`を呼び出しており、現在のホストまたはアセット用のホストとマージしてURLを生成します。

```ruby
javascript_url "common" # => http://www.example.com/assets/common.js
```

#### stylesheet_link_tag

引数として指定されたソースにあるスタイルシートへのリンクタグを返します。拡張子が指定されていない場合は、`.css`が自動的に補われます。

```ruby
stylesheet_link_tag "application" # => <link href="/assets/application.css" media="screen" rel="stylesheet" />
```

ソースに`:all`を指定すると、stylesheetディレクトリにあるすべてのスタイルシートを含めることができます。

```ruby
stylesheet_link_tag :all
```

複数のスタイルシートファイルをキャッシュして1つのファイルにすることができます。こうすることでスタイルシートファイルのダウンロードに必要なHTTP接続数を減らすことができ、速度が向上します。gzip圧縮すればさらに転送が速くなります。キャッシュが有効になるのは、`ActionController::Base.perform_caching`をtrueに設定した場合のみです。production環境ではデフォルトでtrueになりますが、development環境ではデフォルトではtrueになりません。

```ruby
stylesheet_link_tag :all, cache: true
# => <link href="/assets/all.css" media="screen" rel="stylesheet" />
```

#### stylesheet_path

`app/assets/stylesheets`に置かれているスタイルシートアセットへのパスを算出します。ソースのファイル名に拡張子`.css`がない場合は自動的に補われます。ドキュメントルート・ディレクトリからの完全なパスが返されます。このメソッドは`stylesheet_link_tag`の内部でスタイルシートへのパス作成に使用されています。

```ruby
stylesheet_path "application" # => /assets/application.css
```

#### stylesheet_url

`app/assets/stylesheets`に置かれているスタイルシートアセットへのURLを算出します。このメソッドは内部で`stylesheet_path`を呼び出しており、現在のホストまたはアセット用のホストとマージしてURLを生成します。

```ruby
stylesheet_url "application" # => http://www.example.com/assets/application.css
```

### AtomFeedHelper

#### atom_feed

このヘルパーを使用して、Atomフィードを簡単に生成できます。以下にすべての使用例を示します。

**config/routes.rb**

```ruby
resources :posts
```

**app/controllers/posts_controller.rb**

```ruby
def index
  @posts = Post.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

**app/views/posts/index.atom.builder**

```ruby
atom_feed do |feed|
  feed.title("Posts Index")
  feed.updated((@posts.first.created_at))

  @posts.each do |post|
    feed.entry(post) do |entry|
      entry.title(post.title)
      entry.content(post.body, type: 'html')

      entry.author do |author|
        author.name(post.author_name)
      end
    end
  end
end
```

### BenchmarkHelper

#### benchmark

テンプレート内の1つのブロックの実行時間測定と、結果のログ出力に使用します。実行に時間のかかる行や、ボトルネックになる可能性のある行をこのブロックで囲み、実行にかかった時間を読み取ります。

```html+erb
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

上のコードは、"Process data files (0.34523)"のようなログを出力します。このログは、コード最適化のためにタイミングを比較する際に役立てることができます。

### CacheHelper

#### cache

`cache`メソッドは、(アクション全体やページ全体ではなく) ビューの断片をキャッシュするメソッドです。この手法は、メニュー・ニュース記事・静的HTMLの断片などをキャッシュするのに便利です。このメソッドには、キャッシュしたいコンテンツを1つのブロックに含めて引数として渡します。詳細については、`ActionController::Caching::Fragments`を参照してください。

```erb
<% cache do %>
  <%= render "shared/footer" %>
<% end %>
```

### CaptureHelper

#### capture

`capture`メソッドを使用することで、テンプレートの一部を変数に保存することができます。保存された変数は、テンプレートやレイアウトのどんな場所でも自由に使用できます。

```html+erb
<% @greeting = capture do %>
  <p>Welcome! The date and time is <%= Time.now %></p>
<% end %>
```

上でキャプチャした変数は以下のように他の場所で自由に使用できます。

```html+erb
<html>
  <head>
    <title>Welcome!</title>
  </head>
  <body>
    <%= @greeting %>
  </body>
</html>
```

#### content_for

`content_for`を呼び出すと、後の利用に備えて、idに対応するマークアップのブロックが保存されます。以後、保存されたコンテンツを他のテンプレートやレイアウトで呼び出すことができます。呼び出しの際には、`yield`の引数となるidを渡します。

たとえば、あるRailsアプリケーション全体にわたって標準のアプリケーションレイアウトを使用しているが、特定のページでのみ特定のJavaScriptコードが必要となり、他のページではこのJavaScriptはまったく不要であるとします。このようなときには`content_for`を使用します。これにより、そのJavaScriptコードを特定のページにだけインクルードし、サイトの他の部分でインクルードされることのないようにできます。

**app/views/layouts/application.html.erb**

```html+erb
<html>
  <head>
    <title>Welcome!</title>
    <%= yield :special_script %>
  </head>
  <body>
    <p>Welcome! The date and time is <%= Time.now %></p>
  </body>
</html>
```

**app/views/posts/special.html.erb**

```html+erb
<p>This is a special page.</p>

<% content_for :special_script do %>
  <script>alert('Hello!')</script>
<% end %>
```

### DateHelper

#### date_select

日付用のselectタグのセットを返します。タグは年・月・日用にそれぞれあり、日付に関する特定の属性にアクセスして年月日を選択済みの状態にします。

```ruby
date_select("post", "published_on")
```

#### datetime_select

日付・時刻用のselectタグのセットを返します。タグは年・月・日・時・分用にそれぞれあり、日付・時刻に関する特定の属性にアクセスして日時が選択済みになります。

```ruby
datetime_select("post", "published_on")
```

#### distance_of_time_in_words

TimeオブジェクトやDateオブジェクト、秒を表す整数同士を比較して近似表現を返します。`include_seconds`をtrueにすると、より詳細な差を得られます。

```ruby
distance_of_time_in_words(Time.now, Time.now + 15.seconds)        # => less than a minute
distance_of_time_in_words(Time.now, Time.now + 15.seconds, include_seconds: true)  # => less than 20 seconds
```

#### select_date

日付用のselectタグのセットを返します。タグは年・月・日用にそれぞれあり、`date`で得られる値で選択済みの状態にします。

```ruby
# 指定された日付 (ここでは本日から6日後) をデフォルト値とする日付セレクトボックスを生成する
select_date(Time.today + 6.days)

# 日付の指定がない場合、本日をデフォルト値とする日付セレクトボックスを生成する
select_date()
```

#### select_datetime

日付・時刻用のselectタグのセットを返します。タグは年・月・日・時・分用にそれぞれあり、`datetime`で得られる値で選択済みの状態にします。

```ruby
# 指定された日時 (ここでは本日から4日後) をデフォルト値とする日時セレクトボックスを生成する
select_datetime(Time.now + 4.days)

# 日時の指定がない場合、本日をデフォルト値とする日時セレクトボックスを生成する
select_datetime()
```

#### select_day

1から31までの日付をオプションに持ち、当日が選択されているselectタグを返します。

```ruby
# 指定された日付をデフォルト値に持つセレクトボックスを生成する
select_day(Time.today + 2.days)

# 指定された数値をデフォルトの日付として持つセレクトボックスを生成する
select_day(5)
```

#### select_hour

0から23までの時をオプションに持ち、現在時刻が選択されているselectタグを返します。

```ruby
# 指定された時をデフォルト値として持つセレクトボックスを生成する
select_hour(Time.now + 6.hours)
```

#### select_minute

0から59までの分をオプションに持ち、現在時刻の分が選択されているselectタグを返します。

```ruby
# 指定された分をデフォルト値として持つセレクトボックスを生成する
select_minute(Time.now + 6.hours)
```

#### select_month

JanuaryからDecemberまでの月をオプションに持ち、現在の月が選択されているselectタグを返します(訳注: 日本語環境では1月から12月が表示されます)。

```ruby
# 現在の月をデフォルト値に持つセレクトボックスを生成する
select_month(Date.today)
```

#### select_second

0から59までの秒をオプションに持ち、現在時刻の秒が選択されているselectタグを返します。

```ruby
# 指定の秒を現在時刻に加えた値をデフォルト値に持つ秒用のセレクトボックスを生成する
select_second(Time.now + 16.minutes)
```

#### select_time

時刻用のselectタグのセットを返します。タグは時・分用にそれぞれあります。

```ruby
# 現在時刻をデフォルト値に持つ時刻セレクトボックスを生成する
select_time(Time.now)
```

#### select_year

当年を含む直近の5つの年をオプションに持ち、当年がデフォルトとして選択されているselectタグを返します。`:start_year`キーと`:end_year`キーを`options`に設定することで、デフォルトの5年を変更できます。

```ruby
# 今年をデフォルト値に持ち、Date.todayで得られた日の前後5年をオプションに持つセレクトボックスを生成する
select_year(Date.today)

# 今年をデフォルト値に持ち、1900年から2009年までをオプションに持つセレクトボックスを生成する
select_year(Date.today, start_year: 1900, end_year: 2009)
```

#### time_ago_in_words

`distance_of_time_in_words`と基本的に同じ動作であり、`to_time`の部分が`Time.now`に固定されている点だけが異なります。

```ruby
time_ago_in_words(3.minutes.from_now)  # => 3分
```

#### time_select

時刻用のselectタグのセットを返します。タグは時・分用の他にオプションで秒もあります。時刻に関する特定の属性にアクセスして日時が選択済みになります。このタグで選択された項目は、Active Recordオブジェクトにマルチパラメータとして割り当て可能な形式になります。

```ruby
# 時刻選択用タグを作成する。フォームがPOSTされると、submitted属性のorder変数が保存される。
time_select("order", "submitted")
```

### DebugHelper

YAMLからダンプしたオブジェクトを含む`pre`タグを返します。これを利用することで、オブジェクトの内容が非常に読みやすくなります。

```ruby
my_hash = {'first' => 1, 'second' => 'two', 'third' => [1,2,3]}
debug(my_hash)
```

```html
<pre class='debug_dump'>---
first: 1
second: two 
third:
- 1
- 2
- 3
</pre>
```

### FormHelper

フォームヘルパーを使用すると、標準のHTML要素だけを使用するよりもはるかに容易に、モデルと連携動作するフォームを作成することができます。Formヘルパーはフォーム用のHTMLを生成し、テキストやパスワードといった入力の種類に応じたメソッドを提供します。(送信ボタンがクリックされたり、JavaScriptでform.submitを呼び出すなどして) フォームが送信されると、フォームの入力内容はparamsオブジェクトにまとめて保存され、コントローラに渡されます。

フォームヘルパーは、モデル属性の操作に特化したものと、より一般的なものの2種類に分類できます。ここではモデル属性の扱いに特化したものについて説明します。モデル属性に特化していない一般的なフォームヘルパーについては、ActionView::Helpers::FormTagHelperのドキュメントを参照してください。

ここで扱うフォームヘルパーの中心となるメソッドはform_forです。このメソッドはモデルのインスタンスからフォームを作成することができます。たとえば、以下のようにPersonというモデルがあり、このモデルをもとにしてインスタンスを1つ作成するとします。

```html+erb
# メモ: a @person変数はコントローラ側で設定済みであるとする (@person = Person.newなど)
<%= form_for @person, url: {action: "create"} do |f| %>
  <%= f.text_field :first_name %>
  <%= f.text_field :last_name %>
  <%= submit_tag 'Create' %>
<% end %>
```

上のコードによって生成されるHTMLは以下のようになります。

```html
<form action="/people/create" method="post">
  <input id="person_first_name" name="person[first_name]" type="text" />
  <input id="person_last_name" name="person[last_name]" type="text" />
  <input name="commit" type="submit" value="Create" />
</form>
```

上のフォームが送信される時に作成されるparamsオブジェクトは以下のようになります。

```ruby
{"action" => "create", "controller" => "people", "person" => {"first_name" => "William", "last_name" => "Smith"}}
```

上のparamsハッシュには、Personモデル用の値がネストした形で含まれているので、コントローラで`params[:person]`と書くことで内容にアクセスできます。

#### check_box

指定された属性にアクセスするためのチェックボックスタグを生成します。

```ruby
# @post.validated?が1の場合
check_box("post", "validated")
# => <input type="checkbox" id="post_validated" name="post[validated]" value="1" />
#    <input name="post[validated]" type="hidden" value="0" />
```

#### fields_for

form_forのような特定のモデルオブジェクトの外側にスコープを作成しますが、フォームタグ自体は作成しません。このため、fields_forは同じフォームに別のモデルオブジェクトを追加するのに向いています。

```html+erb
<%= form_for @person, url: {action: "update"} do |person_form| %>
  First name: <%= person_form.text_field :first_name %> 
  Last name : <%= person_form.text_field :last_name %>

  <%= fields_for @person.permission do |permission_fields| %>
    Admin?  : <%= permission_fields.check_box :admin %>
  <% end %>
<% end %>
```

#### file_field

特定の属性にアクセスするための、ファイルアップロード用inputタグを返します。

```ruby
file_field(:user, :avatar)
# => <input type="file" id="user_avatar" name="user[avatar]" />
```

#### form_for

フィールドにどのような値があるかを問い合わせるのに使用される、特定のモデルオブジェクトの外側にフォームを1つとスコープを1つ作成します。

```html+erb
<%= form_for @post do |f| %>
  <%= f.label :title, 'Title' %>:
  <%= f.text_field :title %><br>
  <%= f.label :body, 'Body' %>:
  <%= f.text_area :body %><br>
<% end %>
```

#### hidden_field

特定の属性にアクセスするための、隠されたinputタグを返します。

```ruby
hidden_field(:user, :token)
# => <input type="hidden" id="user_token" name="user[token]" value="#{@user.token}" />
```

#### label

特定の属性用のinputフィールドに与えるラベルを返します。

```ruby
label(:post, :title)
# => <label for="post_title">Title</label>
```

#### password_field

特定の属性にアクセスするための、種類が"password"のinputタグを返します。

```ruby
password_field(:login, :pass)
# => <input type="text" id="login_pass" name="login[pass]" value="#{@login.pass}" />
```

#### radio_button

特定の属性にアクセスするためのラジオボタンタグを返します。

```ruby
# @post.categoryが"rails"を返す場合
radio_button("post", "category", "rails")
radio_button("post", "category", "java")
# => <input type="radio" id="post_category_rails" name="post[category]" value="rails" checked="checked" />
#    <input type="radio" id="post_category_java" name="post[category]" value="java" />
```

#### text_area

特定の属性にアクセスするための、テキストエリア用開始タグと終了タグを返します。

```ruby
text_area(:comment, :text, size: "20x30")
# => <textarea cols="20" rows="30" id="comment_text" name="comment[text]">
#      #{@comment.text}
#    </textarea>
```

#### text_field

特定の属性にアクセスするための、種類が"text"のinputタグを返します。

```ruby
text_field(:post, :title)
# => <input type="text" id="post_title" name="post[title]" value="#{@post.title}" />
```

#### email_field

特定の属性にアクセスするための、種類が"email"のinputタグを返します。

```ruby
email_field(:user, :email)
# => <input type="email" id="user_email" name="user[email]" value="#{@user.email}" />
```

#### url_field

特定の属性にアクセスするための、種類が"url"のinputタグを返します。

```ruby
url_field(:user, :url)
# => <input type="url" id="user_url" name="user[url]" value="#{@user.url}" />
```

### FormOptionsHelper

さまざまな種類のコンテナを1つのオプションタグのセットにまとめるためのメソッドを多数提供します。

#### collection_select

`select`タグと、`object`が属するクラスのメソッド値の既存の戻り値をコレクションにした`option`タグを返します。

例として、このメソッドを適用するオブジェクトの構造が以下のようになっているとします。

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

利用法は、たとえば以下のようになります。ここでは、Postモデルのインスタンスである`@post`に関連付けられているAuthorモデルから選択肢を取り出しています。

```ruby
collection_select(:post, :author_id, Author.all, :id, :name_with_initial, {prompt: true})
```

`@post.author_id`が1の場合、以下が返されます。

```html
<select name="post[author_id]">
  <option value="">Please select</option>
  <option value="1" selected="selected">D. Heinemeier Hansson</option>
  <option value="2">D. Thomas</option>
  <option value="3">M. Clark</option>
</select>
```

#### collection_radio_buttons

`object`が属するクラスのメソッド値の既存の戻り値をコレクションにした`radio_button`タグを返します。

例として、このメソッドを適用するオブジェクトの構造が以下のようになっているとします。

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

利用法は、たとえば以下のようになります。ここでは、Postモデルのインスタンスである`@post`に関連付けられているAuthorモデルから選択肢を取り出しています。

```ruby
collection_radio_buttons(:post, :author_id, Author.all, :id, :name_with_initial)
```

`@post.author_id`が1の場合、以下が返されます。

```html
<input id="post_author_id_1" name="post[author_id]" type="radio" value="1" checked="checked" />
<label for="post_author_id_1">D. Heinemeier Hansson</label>
<input id="post_author_id_2" name="post[author_id]" type="radio" value="2" />
<label for="post_author_id_2">D. Thomas</label>
<input id="post_author_id_3" name="post[author_id]" type="radio" value="3" />
<label for="post_author_id_3">M. Clark</label>
```

#### collection_check_boxes

`object`が属するクラスのメソッド値の既存の戻り値をコレクションにした`check_box`タグを返します。

例として、このメソッドを適用するオブジェクトの構造が以下のようになっているとします。

```ruby
class Post < ActiveRecord::Base
  has_and_belongs_to_many :authors
end

class Author < ActiveRecord::Base
  has_and_belongs_to_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

利用法は、たとえば以下のようになります。ここでは、Postモデルのインスタンスである`@post`に関連付けられているAuthorsから選択肢を取り出しています。

```ruby
collection_check_boxes(:post, :author_ids, Author.all, :id, :name_with_initial)
```

`@post.author_ids`が1の場合、以下が返されます。

```html
<input id="post_author_ids_1" name="post[author_ids][]" type="checkbox" value="1" checked="checked" />
<label for="post_author_ids_1">D. Heinemeier Hansson</label>
<input id="post_author_ids_2" name="post[author_ids][]" type="checkbox" value="2" />
<label for="post_author_ids_2">D. Thomas</label>
<input id="post_author_ids_3" name="post[author_ids][]" type="checkbox" value="3" />
<label for="post_author_ids_3">M. Clark</label>
<input name="post[author_ids][]" type="hidden" value="" />
```

#### country_options_for_select

世界のほぼすべての国名を含むオプションタグの文字列を返します。

#### country_select

country_options_for_selectを使用してオプションタグを生成し、指定されたオブジェクトとメソッド用のselectタグとoptionタグを返します。

#### option_groups_from_collection_for_select

`option`タグの文字列を返します。後述の`options_from_collection_for_select`と似ていますが、引数のオブジェクトリレーションに基いて`optgroup`タグを使用する点が異なります。

例として、このメソッドを適用するオブジェクトの構造が以下のようになっているとします。

```ruby
class Continent < ActiveRecord::Base
  has_many :countries
  # attribs: id, name
end

class Country < ActiveRecord::Base
  belongs_to :continent
  # attribs: id, name, continent_id
end
```

使用例は以下のようになります。

```ruby
option_groups_from_collection_for_select(@continents, :countries, :name, :id, :name, 3)
```

出力結果は以下のようになります。

```html
<optgroup label="Africa">
  <option value="1">Egypt</option>
  <option value="4">Rwanda</option>
  ...
</optgroup>
<optgroup label="Asia">
  <option value="3" selected="selected">China</option>
  <option value="12">India</option>
  <option value="5">Japan</option>
  ...
</optgroup>
```

NOTE: 返されるのは`optgroup`タグと`option`だけです。従って、出力結果の外側を適切な`select`タグで囲む必要があります。

#### options_for_select

コンテナ (ハッシュ、配列、enumerable、独自の型) を引数として受け付け、オプションタグの文字列を返します。

```ruby
options_for_select([ "VISA", "MasterCard" ])
# => <option>VISA</option> <option>MasterCard</option>
```

NOTE: 返されるのは`option`だけです。従って、出力結果の外側を適切なHTML `select`タグで囲む必要があります。

#### options_from_collection_for_select

`collection`を列挙した結果をoptionタグ化した文字列を返し、呼び出しの結果を`value_method`にオプション値として割り当て、`text_method`にオプションテキストとして割り当てます。

```ruby
options_from_collection_for_select(collection, value_method, text_method, selected = nil)
```

たとえば、@project.peopleに入っているpersonをループですべて列挙してinputタグを作成するのであれば、以下のようになります。

```ruby
options_from_collection_for_select(@project.people, "id", "name")
# => <option value="#{person.id}">#{person.name}</option>
```

NOTE: 返されるのは`option`だけです。従って、出力結果の外側を適切なHTML `select`タグで囲む必要があります。

#### select

指定されたオブジェクトとメソッドに従って、selectタグの中に一連のoptionタグを含んだものを作成します。

例：

```ruby
select("post", "person_id", Person.all.collect {|p| [ p.name, p.id ] }, {include_blank: true})
```

`@post.person_id`が1の場合、以下が返されます。

```html
<select name="post[person_id]">
  <option value=""></option>
  <option value="1" selected="selected">David</option>
  <option value="2">Sam</option>
  <option value="3">Tobias</option>
</select>
```

#### time_zone_options_for_select

世界のほぼすべてのタイムゾーンを含むオプションタグの文字列を返します。

#### time_zone_select

time_zone_options_for_selectを使用してオプションタグを生成し、指定されたオブジェクトとメソッド用のselectタグとoptionタグを返します。

```ruby
time_zone_select( "user", "time_zone")
```

#### date_field

特定の属性にアクセスするための、種類が"date"のinputタグを返します。

```ruby
date_field("user", "dob")
```

### FormTagHelper

フォームタグを作成するためのメソッドを多数提供します。これらのメソッドは、テンプレートに割り当てられているActive Recordオブジェクトに依存しない点がFormHelperと異なります。その代わり、FormTagHelperのメソッドでは名前と値を個別に指定します。

#### check_box_tag

チェックボックス用のフォームinputタグを作成します。

```ruby
check_box_tag 'accept'
# => <input id="accept" name="accept" type="checkbox" value="1" />
```

#### field_set_tag

HTMLフォーム要素をグループ化するためのfieldsetタグを作成します。

```html+erb
<%= field_set_tag do %>
  <p><%= text_field_tag 'name' %></p>
<% end %>
# => <fieldset><p><input id="name" name="name" type="text" /></p></fieldset>
```

#### file_field_tag

ファイルアップロード用のフィールドを作成します。

```html+erb
<%= form_tag({action:"post"}, multipart: true) do %>
  <label for="file">File to Upload</label> <%= file_field_tag "file" %>
  <%= submit_tag %>
<% end %>
```

出力例:

```ruby
file_field_tag 'attachment'
# => <input id="attachment" name="attachment" type="file" />
```

#### form_tag

`url_for_options`で設定されたURLへのアクションに送信されるフォームタグを作成します。これは`ActionController::Base#url_for`と似ています。

```html+erb
<%= form_tag '/posts' do %>
  <div><%= submit_tag 'Save' %></div>
<% end %>
# => <form action="/posts" method="post"><div><input type="submit" name="submit" value="Save" /></div></form>
```

#### hidden_field_tag

フォームinputの「隠しフィールド」を作成します。この隠しフィールドは、通常であればHTTPがステートレスであることによって失われる可能性のあるデータを送信したり、ユーザーから見えないようにしておきたいデータを送信するのに使用されます。

```ruby
hidden_field_tag 'token', 'VUBJKB23UIVI1UU1VOBVI@'
# => <input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />
```

#### image_submit_tag

送信画像を表示します。この画像をクリックするとフォームが送信されます。

```ruby
image_submit_tag("login.png")
# => <input src="/images/login.png" type="image" />
```

#### label_tag

フィールドのラベルを作成します。

```ruby
label_tag 'name'
# => <label for="name">Name</label>
```

#### password_field_tag

パスワード用のフィールドを作成します。このフィールドへの入力はマスク用文字で隠されます。

```ruby
password_field_tag 'pass'
# => <input id="pass" name="pass" type="password" />
```

#### radio_button_tag

ラジオボタンを作成します。ユーザーが同じオプショングループ内から選択できるよう、同じname属性でラジオボタンをグループ化してください。

```ruby
radio_button_tag 'gender', 'male'
# => <input id="gender_male" name="gender" type="radio" value="male" />
```

#### select_tag

ドロップダウン選択ボックスを作成します。

```ruby
select_tag "people", "<option>David</option>"
# => <select id="people" name="people"><option>David</option></select>
```

#### submit_tag

キャプションとして指定されたテキストを使用して送信ボタンを作成します。

```ruby
submit_tag "Publish this post"
# => <input name="commit" type="submit" value="Publish this post" />
```

#### text_area_tag

textareaタグでテキスト入力エリアを作成します。ブログへの投稿や説明文などの長いテキストを入力するにはtextareaをご使用ください。

```ruby
text_area_tag 'post'
# => <textarea id="post" name="post"></textarea>
```

#### text_field_tag

通常のテキストフィールドを作成します。ユーザー名や検索キーワード入力用のフィールドにはこの通常のテキストフィールドをご使用ください。

```ruby
text_field_tag 'name'
# => <input id="name" name="name" type="text" />
```

#### email_field_tag

種類が`email`の標準入力フィールドを作成します。

```ruby
email_field_tag 'email'
# => <input id="email" name="email" type="email" />
```

#### url_field_tag

種類が`url`の標準入力フィールドを作成します。

```ruby
url_field_tag 'url'
# => <input id="url" name="url" type="url" />
```

#### date_field_tag

種類が`date`の標準入力フィールドを作成します。

```ruby
date_field_tag "dob"
# => <input id="dob" name="dob" type="date" />
```

### JavaScriptHelper

ビューでJavaScriptを使用するための機能を提供します。

#### button_to_function

`onclick`ハンドラを使用するJavaScript関数を起動するボタンを返します。以下の例を参照ください。

```ruby
button_to_function "Greeting", "alert('Hello world!')"
button_to_function "Delete", "if (confirm('Really?')) do_delete()"
button_to_function "Details" do |page|
  page[:details].visual_effect :toggle_slide
end
```

#### define_javascript_functions

単一の`script`タグ内にAction PackのJavaScriptライブラリを追加します。

#### escape_javascript

JavaScriptセグメントから改行 (CR) と一重引用符と二重引用符をエスケープします。

#### javascript_tag

渡されたコードをJavaScript用タグにラップして返します。

```ruby
javascript_tag "alert('All is good')"
```

```html
<script>
//<![CDATA[
alert('All is good')
//]]>
</script>
```

#### link_to_function

`onclick`ハンドラを使用するJavaScript関数を起動し、その後falseを返すリンクを返します。

```ruby
link_to_function "Greeting", "alert('Hello world!')"
# => <a onclick="alert('Hello world!'); return false;" href="#">Greeting</a>
```

### NumberHelper

数値をフォーマット済み文字列に変換するメソッド群を提供します。サポートされているフォーマットは電話番号、通貨、パーセント、精度、座標、ファイルサイズなどです。

#### number_to_currency

数値を通貨表示に変換します ($13.65など)。

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

#### number_to_human_size

バイト数を読みやすい形式にフォーマットします。ファイルサイズをユーザーに表示する場合に便利です。

```ruby
number_to_human_size(1234)          # => 1.2 KB
number_to_human_size(1234567)       # => 1.2 MB
```

#### number_to_percentage

数値をパーセント文字列に変換します。

```ruby
number_to_percentage(100, precision: 0)        # => 100%
```

#### number_to_phone

数値を米国式の電話番号に変換します。

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

#### number_with_delimiter

数値に3桁ごとの桁区切り文字を追加します。

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

#### number_with_precision

数値を指定された精度(`precision`)に変換します。デフォルトの精度は3です。

```ruby
number_with_precision(111.2345)     # => 111.235
number_with_precision(111.2345, 2)  # => 111.23
```

### SanitizeHelper

SanitizeHelperモジュールは、望ましくないHTML要素を除去するためのメソッド群を提供します。

#### sanitize

sanitizeヘルパーメソッドは、すべてのタグ文字をHTMLエンコードし、明示的に許可されていない属性をすべて削除します。

```ruby
sanitize @article.body
```

:attributesオプションまたは:tagsオプションが渡されると、そこで指定されたタグおよび属性のみが処理の対象外となります。

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

さまざまな用途に合わせてデフォルト設定を変更できます。たとえば以下のようにデフォルトのタグにtableタグを追加するとします。

```ruby
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
end
```

#### sanitize_css(style)

CSSコードをサニタイズします。

#### strip_links(html)
リンクテキストを残してリンクタグをすべて削除します。

```ruby
strip_links("<a href="http://rubyonrails.org">Ruby on Rails</a>")
# => Ruby on Rails
```

```ruby
strip_links("emails to <a href="mailto:me@email.com">me@email.com</a>.")
# => emails to me@email.com.
```

```ruby
strip_links('Blog: <a href="http://myblog.com/">Visit</a>.')
# => Blog: Visit.
```

#### strip_tags(html)

HTMLからHTMLタグをすべて削除します。HTMLコメントも削除されます。
このメソッドではHTMLスキャナとHTMLトークナイザ (tokenizer) を使用しており、HTMLの解析能力はスキャナの能力に依存しています。

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!
```

```ruby
strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more</a>")
# => Bold no more!  See more
```

CAUTION: この出力にはエスケープされていない'<'、'>'、'&'文字が残ることがあり、それによってブラウザが期待どおりに動作しなくなることがあります。

### CsrfHelper

"csrf-param"メタタグと"csrf-token"メタタグを返します。これらの名称はそれぞれ、クロスサイトリクエストフォージェリ (CSRF: cross-site request foregery) のパラメータとトークンが元になっています。

```html
<%= csrf_meta_tags %>
```

NOTE: 通常のフォームではそのための隠しフィールドが生成されるので、これらのタグは使用されません。詳細については[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ-csrf)を参照してください。

ローカライズされたビュー
---------------

Action Viewは、現在のロケールに応じてさまざまなテンプレートを出力することができます。

たとえば、`PostsController`にshowアクションがあるとしましょう。このshowアクションを呼び出すと、デフォルトでは`app/views/posts/show.html.erb`が出力されます。ここで`I18n.locale = :de`を設定すると、代りに`app/views/posts/show.de.html.erb`が出力されます。ローカライズ版のテンプレートが見当たらない場合は、装飾なしのバージョンが使用されます。つまり、ローカライズ版ビューがなくても動作しますが、ローカライズ版ビューがあればそれが使用されます。

同じ要領で、publicディレクトリのレスキューファイル (いわゆるエラーページ) もローカライズできます。たとえば、`I18n.locale = :de`と設定し、`public/500.de.html`と`public/404.de.html`を作成することで、ローカライズ版のレスキューページを作成できます。

RailsはI18n.localeに設定できるシンボルを制限していないので、ローカライズにかぎらず、あらゆる状況に合わせて異なるコンテンツを表示し分けるようにすることができます。たとえば、エキスパートユーザーには、通常ユーザーと異なる画面を表示したいとします。これを行なうには、`app/controllers/application.rb`に以下のように追記します。

```ruby
before_action :set_expert_locale

def set_expert_locale
  I18n.locale = :expert if current_user.expert?
end
```

これにより、たとえば`app/views/posts/show.expert.html.erb`のような特殊なビューをエキスパートユーザーにだけ表示することができます。

詳細については、[Rails国際化 (I18n) API](i18n.html) を参照してください。