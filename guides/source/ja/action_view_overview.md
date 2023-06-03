Action View の概要
====================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Action View Overview](https://guides.rubyonrails.org/action_view_overview.html)を日本語に翻訳した文書です。

このガイドの内容:

* Action Viewの概要とRailsでの利用法
* テンプレート、パーシャル（部分テンプレート）、レイアウトの最適な利用法
* Action Viewで提供されるヘルパーの紹介
* ビューのローカライズ方法

--------------------------------------------------------------------------------


Action Viewについて
--------------------

RailsにおけるWebリクエストは、[Action Controller](action_controller_overview.html)とAction Viewで扱われます。通常、Action Controllerは、データベースとのやりとりや、必要に応じたCRUD（Create/Read/Update/Delete）アクションの実行に関与します。Action View はその後レスポンスを実際のWebページにまとめる役割を担います。

Action Viewのテンプレートは、HTMLタグの間にERB（Embedded Ruby）を含む形式で書かれます。ビューテンプレートがコードの繰り返しでうずまって乱雑になるのを避けるために、フォーム・日付・文字列に対して共通の動作を提供するヘルパークラスが多数用意されています。アプリケーションの機能向上に応じて独自のヘルパーを追加することも簡単にできます。

NOTE: Action Viewの一部の機能はActive Recordと結びついていますが、Action ViewがActive Recordに依存しているわけではありません。Action Viewは独立したパッケージであり、任意のRubyライブラリと組み合わせて利用できます。

Action ViewをRailsで使う
----------------------------

アプリケーションの`app/views`ディレクトリには、1つのコントローラごとに1つのディレクトリが作成され、そこにビューテンプレートファイルが置かれます。このビューテンプレートはそのコントローラと関連付けられています。これらのファイルは、コントローラ内にあるアクションごとにレンダリング（画面への出力）された結果をビューで表示するために使われます。

scaffoldでリソースを生成するときに、Railsがデフォルトでどんなことを行なうのか見てみましょう。

```bash
$ bin/rails generate scaffold article
      [...]
      invoke  scaffold_controller
      create    app/controllers/articles_controller.rb
      invoke    erb
      create      app/views/articles
      create      app/views/articles/index.html.erb
      create      app/views/articles/edit.html.erb
      create      app/views/articles/show.html.erb
      create      app/views/articles/new.html.erb
      create      app/views/articles/_form.html.erb
      [...]
```

Railsのビューには命名規則があります。上で生成されたファイルを見るとわかるように、ビューテンプレートファイルは基本的にコントローラのアクションと関連付けられています。
たとえば、`articles_controller.rb`コントローラのindexアクションは、`app/views/articles`ディレクトリの`index.html.erb`を使います。

これらのERBファイルに、それらをラップするレイアウトテンプレートや、ビューから参照されるあらゆるパーシャル（部分テンプレート）を組み合わせることで完全なHTMLが生成され、クライアントに送信されます。この後、本ガイドではこれらの3つの要素について詳しく説明します。

テンプレート、パーシャル、レイアウト
-------------------------------

前述のとおり、Railsがレンダリングする最終的なHTMLは「テンプレート」「パーシャル」「レイアウト」の3つの要素から構成されます。
これらについて簡単に説明いたします。

### テンプレート

Action Viewのテンプレートはさまざまな方法で記述できます。テンプレートの拡張子が`.erb`であれば、ERB（Rubyのコードはここに含まれます）とHTMLを記述します。テンプレートの拡張子が`.builder`であれば、`Builder::XmlMarkup`ライブラリが使われます。

Railsでは複数のテンプレートシステムがサポートされており、テンプレートファイルの拡張子で区別されます。たとえば、ERBテンプレートシステムを使うHTMLファイルの拡張子は`.html.erb`になります。

#### ERB

ERBテンプレートの内部では、`<% %>`タグや`<%= %>`タグの中にRubyコードを書けます。
最初の`<% %>`タグはその中に書かれたRubyコードを実行しますが、実行結果はレンダリングされません。条件文やループ、ブロックなどレンダリングの不要な行はこのタグの中に書くとよいでしょう。
次の`<%= %>`タグでは実行結果がWebページにレンダリングされます。

以下は、名前をレンダリングするためのループです。

```html+erb
<h1>Names of all the people</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

ループの開始行と終了行は通常のERBタグ（`<% %>`）に書かれており、名前をレンダリングする行はレンダリング用のERBタグ（`<%= %>`）に書かれています。上のコードは、単にERBの書き方を説明しているだけではありません。Rubyでよく使われる`print`や`puts`のような通常のレンダリング関数はERBでは利用できませんのでご注意ください。以下のコードは誤りです。

```html+erb
<%# 誤り %>
Hi, Mr. <% puts "Frodo" %>
```

なお、Webページへのレンダリング結果の冒頭と末尾からホワイトスペースを取り除きたい場合は、`<%-` および `-%>`を通常の`<%` および `%>`と使い分けてください（訳注: これは英語のようなスペース分かち書きを行なう言語向けのノウハウです）。

#### Builder

BuilderテンプレートはERBの代わりに利用できる、よりプログラミング向きな記法です。これ特にXMLコンテンツを生成するときに便利です。テンプレートの拡張子を`.builder`にすると、`xml`という名前のXmlMarkupオブジェクトが自動で利用できるようになります。

基本的な例を以下にいくつか示します。

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "https://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

上のコードから以下が生成されます。

```html
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="https://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

ブロックを伴うメソッドはすべて、ブロックの中にネストしたマークアップを含むXMLマークアップタグとして扱われます。以下の例で示します。

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

上のコードの出力は以下のようになります。

```html
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

以下はBasecampで実際に使われているRSS出力コードをそのまま引用したものです。

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

#### Jbuilder

[Jbuilder](https://github.com/rails/jbuilder)はRailsチームによってメンテナンスされているgemの１つで、RailsのGemfileにデフォルトで含まれています。

JbuilderはBuilderと似ていますが、XMLではなくJSONを生成するのに使われます。

Jbuilderが導入されていない場合は、Gemfileに以下を追加できます。

```ruby
gem 'jbuilder'
```

`.jbuilder`という拡張子を持つテンプレートでは、`json`という名前のJbuilderオブジェクトが自動的に利用できるようになります。

基本的な例を以下に示します。

```ruby
json.name("Alex")
json.email("alex@example.com")
```

上のコードから以下のJSONが生成されます。

```json
{
  "name": "Alex",
  "email": "alex@example.com"
}
```

この他のコード例や詳しい情報については[Jbuilder documentation](https://github.com/rails/jbuilder#jbuilder)を参照してください。

#### テンプレートをキャッシュする

Railsは、デフォルトでビューの各テンプレートをコンパイルしてレンダリング用メソッドにします。developmentモードの場合、ビューテンプレートが変更されるとファイルの更新日時で変更が検出され、再コンパイルされます。

### パーシャル

パーシャル（部分テンプレート）は、レンダリング処理を扱いやすく分割する仕組みです。パーシャルを使うことで、ビュー内のコードをいくつものファイルに分割して書き出し、他のテンプレートでも使い回せるようになります。

#### パーシャルの命名ルール

パーシャルをビューの一部に含めてレンダリングするには、ビューで`render`メソッドを使います。

```erb
<%= render "menu" %>
```

上の呼び出しにより、`_menu.html.erb`という名前のファイルの内容が、`render`メソッドを書いたその場所でレンダリングされます。パーシャルファイル名の冒頭にアンダースコア（`_`）が付いていることにご注目ください。これは通常のビューと区別するために付けられています。

ただし`render`で呼び出す際にはこのアンダースコアは不要です。以下のように、他のフォルダの下にあるパーシャルを呼び出す際にもアンダースコアは不要です。

```erb
<%= render "shared/menu" %>
```

上のコードは、その位置に`app/views/shared/_menu.html.erb`パーシャルを読み込みます。

#### パーシャルを活用してビューを簡潔に保つ

すぐに思い付くパーシャルの利用法といえば、パーシャルをサブルーチンと同等とみなすというのがあります。ビューの詳細部分をパーシャルに移動し、コードの見通しを良くするために、パーシャルを使うのです。たとえば、以下のようなビューがあるとします。

```html+erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>私たちの素晴らしい製品のいくつかをご紹介します:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>

<%= render "shared/footer" %>
```

上のコードの`_ad_banner.html.erb`パーシャルと`_footer.html.erb`パーシャルに含まれるコンテンツは、アプリケーションの多くのページと共有できます。あるページを開発中、パーシャルの部分については詳細を気にせずに済みます。

#### `partial`と`locals`オプションのない`render`

上の例では、`render`は`partial`と`locals`の2つのオプションを取っています。しかし、渡したいオプションが他にない場合は、これらのオプションを省略できます。

次の例で説明します。

```erb
<%= render partial: "product", locals: { product: @product } %>
```

上のコードは以下のようにも書けます。

```erb
<%= render "product", product: @product %>
```

#### `as`と`object`オプション

`ActionView::Partials::PartialRenderer`は、デフォルトでテンプレートと同じ名前を持つローカル変数の中に自身のオブジェクトを持ちます。以下のコードを見てみましょう。

```erb
<%= render partial: "product" %>
```

上のコードでは、`_product`パーシャルはローカル変数`product`から`@product`を取得できます。これは以下のコードと同等の結果になります。

```erb
<%= render partial: "product", locals: { product: @product } %>
```

`object`オプションは、パーシャルで出力するオブジェクトを直接指定したい場合に使います。これは、テンプレートのオブジェクトが他の場所（別のインスタンス変数や別のローカル変数など）にある場合に便利です。

たとえば、以下のコードがあるとします。

```erb
<%= render partial: "product", locals: { product: @item } %>
```

上のコードは以下のようになります。

```erb
<%= render partial: "product", object: @item %>
```

`as`オプションを使うと、ローカル変数に異なる名前を指定できます。たとえば、`product`ではなく`item`にしたい場合は次のようにします。

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

上は以下と同等です。

```erb
<%= render partial: "product", locals: { item: @item } %>
```

#### コレクションを出力する

テンプレート上にコレクションを1つ表示し、サブテンプレートでそのコレクションの要素を1つずつレンダリングするというのは、よく行われるパターンです。このパターンは1つのメソッドだけで実行できます。このメソッドは配列を受け取り、配列内の各要素ごとにパーシャルを出力します。

すべての製品（products）を出力するコード例は以下のようになります。

```erb
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

上のコードは以下のように1行で書けます。

```erb
<%= render partial: "product", collection: @products %>
```

コレクションを渡してパーシャルが呼び出されると、パーシャルの各インスタンスは、パーシャル名に基づいた変数を経由してレンダリングされるコレクションのメンバーにアクセスします。このパーシャルは`_product`という名前なので、`product`を指定すれば、レンダリングされるインスタンスを取得できます。

コレクションのレンダリングにはショートハンド記法があります。`@products`が`Product`インスタンスのコレクションであれば、以下のコードでも同じ結果を得られます。

```erb
<%= render @products %>
```

使われるパーシャル名は、コレクションの中にある「モデル名」を参照して決定されます。この場合のモデル名は`Product`です。作成するコレクションの各要素が不揃い（訳注: 要素ごとにモデルが異なる場合を指します）であっても、Railsはコレクションのメンバごとに適切なパーシャルを選んでレンダリングします。

#### スペーサーテンプレート

`:spacer_template`オプションを使うと、メインのパーシャルの間を埋める第2のパーシャルを指定できます。

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

メインの`_product`パーシャルの間に、スペーサーとなる`_product_ruler`パーシャルをレンダリングします（`_product_ruler`にはデータを渡していません）。

### レイアウト

Railsにおける「レイアウト」は、多くのコントローラのアクションにわたって共通して利用できるテンプレートのことです。Railsアプリケーションには必ず全体用のレイアウトがあり、ほぼすべてのWebページ出力はこの全体レイアウトの内側で行われますが、これが典型的なレイアウトです。
たとえば、あるWebサイトにはユーザーログイン用のレイアウトが使われていたり、別のWebサイトにはマーケティングやセールス用のレイアウトが使われていたりします。ログインしたユーザー向けのレイアウトであれば、ナビゲーションツールバーをページのトップレベルに表示し、多くのコントローラやアクションで共通して利用できるようにするでしょう。SaaSアプリケーションにおけるセールス用のレイアウトであれば、トップレベルのナビゲーションに「お値段」や「お問い合わせ先」を共通して表示するでしょう。レイアウトごとに異なる外観を設定してこれらを使い分けることができます。
レイアウトについて詳しくは、[ビューのレイアウトとレンダリング](layouts_and_rendering.html) ガイドを参照してください。

パーシャルレイアウト
---------------

パーシャルに独自のレイアウトを適用できます。パーシャル用のレイアウトは、アクション全体にわたるグローバルなレイアウトとは異なりますが、動作は同じです。

試しに、ページ上に投稿を1つ表示してみましょう。表示制御のため`div`タグで囲むことにします。最初に、`Article`を1つ新規作成します。

```ruby
Article.create(body: 'パーシャルレイアウトはいいぞ！')
```

`show`テンプレートは、`box`レイアウトに内包された`_article`パーシャルを出力します。

**articles/show.html.erb**

```erb
<%= render partial: 'article', layout: 'box', locals: { article: @article } %>
```

`box`レイアウトは、`div`タグの中に`_article`パーシャルを内包した簡単な構造です。

 **articles/_box.html.erb**

```html+erb
<div class='box'>
  <%= yield %>
</div>
```

このパーシャルレイアウトでは、`render`呼び出しに渡されたローカルの`article`変数にアクセスできる点にご注目ください。ただし、アプリケーション全体で共通のレイアウトとは異なり、パーシャルレイアウトのファイル名冒頭にはアンダースコアが必要です。

`yield`を呼び出す代わりに、パーシャルレイアウト内にあるコードのブロックをレンダリングすることも可能です。たとえば、`_article`というパーシャルがない場合でも、以下のような呼び出しが行えます。

**articles/show.html.erb**

```html+erb
<% render(layout: 'box', locals: { article: @article }) do %>
  <div>
    <p><%= article.body %></p>
  </div>
<% end %>
```

ここでは、同じ`_box`パーシャルを使う前提であり、先の例と同じ出力が得られます。

ビューのパス
----------

レスポンスをレンダリングする場合、個別のビューが置かれている場所をコントローラが解決する必要があります。デフォルトでは、`app/views`ディレクトリの下のみを探索します。

`prepend_view_path`メソッドや`append_view_path`メソッドを用いることで、パスの解決時に優先して検索される別のディレクトリを追加できます。

### ビューパスの冒頭にパスを追加する

これは、たとえばサブドメインで使うビューを別のディレクトリ内に配置したい場合などに便利です。

次のように利用できます。

```ruby
prepend_view_path "app/views/#{request.subdomain}"
```

Action Viewは、ビューの解決時にこのディレクトリ内を最初に探索します。

### ビューパスの末尾にパスを追加する

同様に、パスを末尾に追加することもできます。

```ruby
append_view_path "app/views/direct"
```

上のコードは、探索パスの末尾に`app/views/direct`を追加します。

ヘルパー
-------

Railsでは、Action Viewで利用できるヘルパーメソッドを多数提供しています。ヘルパーメソッドには以下のものが含まれます。

* 日付・文字列・数値のフォーマット
* 画像・動画・スタイルシートなどへのHTMLリンク作成
* コンテンツのサニタイズ
* フォームの作成
* コンテンツのローカライズ

ヘルパーについて詳しくは、ガイドの[Action View ヘルパー](action_view_helpers.html)および[Action View フォームヘルパー](form_helpers.html)を参照してください。

ローカライズされたビュー
---------------

Action Viewは、現在のロケールに応じてさまざまなテンプレートをレンダリングできます。

たとえば、`ArticlesController`にshowアクションがあるとしましょう。このshowアクションを呼び出すと、デフォルトでは`app/views/articles/show.html.erb`が出力されます。ここで`I18n.locale = :de`を設定すると、代わりに`app/views/articles/show.de.html.erb`がレンダリングされます。ローカライズ版のテンプレートが見当たらない場合は、装飾なしのバージョンが使われます。つまり、ローカライズ版ビューがなくても動作しますが、ローカライズ版ビューがあればそれが使われます。

同じ要領で、publicディレクトリのレスキューファイル (いわゆるエラーページ) もローカライズできます。たとえば、`I18n.locale = :de`と設定し、`public/500.de.html`と`public/404.de.html`を作成することで、ローカライズ版のレスキューページを作成できます。

RailsはI18n.localeに設定できるシンボルを制限していないので、ローカライズにかぎらず、あらゆる状況に合わせて異なるコンテンツを表示し分けることが可能です。たとえば、エキスパートユーザーには通常ユーザーと異なる画面を表示したいとします。これを行なうには、`app/controllers/application.rb`に以下のように追記します。

```ruby
before_action :set_expert_locale

def set_expert_locale
  I18n.locale = :expert if current_user.expert?
end
```

これにより、たとえば`app/views/articles/show.expert.html.erb`のような特殊なビューをエキスパートユーザーにだけ表示できます。

詳しくは[Rails 国際化 (i18n) API](i18n.html) を参照してください。
