Action View の概要
====================

このガイドの内容:

* Action Viewの概要とRailsでの利用法
* テンプレート、パーシャル（部分テンプレート）、レイアウトの最適な利用法
* Action Viewで提供されるヘルパーの紹介
* ビューのローカライズ方法

--------------------------------------------------------------------------------


Action Viewについて
--------------------

Action Viewは、[MVC][]のVに相当し、 [Action Controller](action_controller_overview.html)と連携してWebリクエストを処理します。Action Controllerは（MVCにおける）モデル層とのやりとりやデータの取得を担当し、次にAction Viewがそのデータを利用してWebリクエストに対するレスポンスのbody（本文）をレンダリングします。

デフォルトのAction Viewテンプレート（単に「ビュー」とも呼ばれます）は、HTMLドキュメント内にRubyコードを記述可能にするERB（Embedded Ruby）で記述します。

Action Viewには、「フォーム」「日付」「文字列」用のHTMLタグを動的に生成する[ヘルパー](#helpers)メソッドが多数用意されています。必要であれば、アプリケーションに独自のヘルパーを追加することも可能です。

NOTE: Action Viewでは、コードを簡潔に書けるようにするためにActive Modelの[`to_param`][]メソッドや[`to_partial_path`][]メソッドを利用しています。ただし、Action ViewがActive Recordに依存しているわけではありません。Action Viewは独立したパッケージであり、任意のRubyライブラリと組み合わせて利用できます。

[MVC]: https://ja.wikipedia.org/wiki/Model_View_Controller
[`to_param`]: https://api.rubyonrails.org/classes/ActiveModel/Conversion.html#method-i-to_param
[`to_partial_path`]: https://api.rubyonrails.org/classes/ActiveModel/Conversion.html#method-i-to_partial_path

Action ViewをRailsで使う
----------------------------

Action Viewテンプレート（別名「ビュー」）は、`app/views`ディレクトリ内のサブディレクトリに保存されます。ここには、コントローラーごとに、コントローラと同じ名前のサブディレクトリがあります。そのサブディレクトリ内にビューファイルが置かれ、コントローラーのアクションへのレスポンスとして特定のビューをレンダリングするします。

たとえば、scaffoldで`article`リソースを生成すると、`app/views/articles`ディレクトリに以下のファイルが生成されます。

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

生成されるファイル名はRailsの命名規約に沿って、対応するコントローラーのアクション名がビューファイル名に取り入れられます（`index`アクションに対応する`index.html.erb`や、`edit`アクションに対応する`edit.html.erb`など）。

この命名規約が守られていれば、Railsがコントローラーのアクションを実行し終わったときに、ユーザーが指定しなくても、そのアクションに対応するビューを自動的に探索してレンダリングします。たとえば、`articles_controller.rb`の`index`アクションを実行すると、`app/views/articles/`ディレクトリ内の`index.html.erb`ビューを自動的にレンダリングします。そのためには、ファイル名と置き場所の両方が規約に沿っていることが重要です。

クライアント（ブラウザ）に返される最終的なHTMLは、「ERB」ファイル（拡張子は`.html.erb`）、それをラップする「レイアウトテンプレート」、ERBファイルが参照するすべての「パーシャル」ファイル（部分テンプレートとも）の組み合わせで構成されます。本ガイドでは、この後「テンプレート」、「パーシャル」、「レイアウト」という3つのコンポーネントについてそれぞれ詳しく説明します。

テンプレート
---------

Action Viewテンプレートは、さまざまなフォーマットで記述できます。
テンプレートファイルの拡張子が`.erb`の場合は、HTMLレスポンスのビルドにERBが使われます。
テンプレートファイルの拡張子が`.jbuilder`の場合は、JSONレスポンスのビルドに[Jbuilder][] gemが使われます。
テンプレートファイルの拡張子が`.builder`の場合は、XMLレスポンスのビルドに[`Builder::XmlMarkup`][]ライブラリが使われます。

Railsは、複数のテンプレートシステムをファイル拡張子で区別します。
たとえば、ERBテンプレートシステムを用いるHTMLファイルのファイル拡張子は`.html.erb`、Jbuilderテンプレートシステムを用いるJSONファイルのファイル拡張子は`.json.jbuilder`になります。他のテンプレートライブラリを利用すると、これ以外のテンプレート種別やファイル拡張子も追加される場合があります。

[Jbuilder]: https://github.com/rails/jbuilder
[`Builder::XmlMarkup`]: https://github.com/rails/builder

### ERB

ERBテンプレートの内部では、`<% %>`タグや`<%= %>`タグの中にRubyコードを書けます。
最初の`<% %>`タグはその中に書かれたRubyコードを実行しますが、実行結果はレンダリングされません。条件文やループ、ブロックなどレンダリングの不要な行はこのタグの中に書くとよいでしょう。
次の`<%= %>`タグでは実行結果がWebページにレンダリングされます。

以下は、名前をレンダリングするためのループです。

ERBテンプレートは、`<% %>`や`<%= %>`などの特殊なERBタグを利用して、Rubyコードを静的HTML内に埋め込む形で記述する方法です。

拡張子が`.html.erb`であるERBビューテンプレートをRailsが処理すると、ERB内のRubyコードが評価され、ERBタグを動的な出力に置き換えます。生成された動的コンテンツは静的なHTMLマークアップと結合されて、最終的なHTMLレスポンスが完成します。

ERBテンプレート内には、`<% %>`タグや`<%= %>`タグでRubyコードを記述できます。
`<% %>`タグ（`=`を含まない）は、実行結果を出力せずにRubyコードを実行したい場合に使います（条件やループなど）。
`<%= %>`タグ（`=`を含む）は、Rubyコードの実行結果を出力してテンプレート内でレンダリングしたい場合に使います（以下のコード例の`person.name`モデル属性など）。

```html+erb
<h1>Names</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

ループの開始行と終了行は通常のERBタグ（`<% %>`）に書かれており、名前をレンダリングする行はレンダリング用のERBタグ（`<%= %>`）に書かれています。

上のコードは、単にERBの書き方を説明しているだけではありません。Rubyでよく使われる`print`や`puts`のような通常のレンダリング関数は、ERBでは利用できませんのでご注意ください。たとえば以下のコードを書いても、ブラウザに`"Frodo"`は表示されません。

```html+erb
<%# 以下のコードは無効 %>
Hi, Mr. <% puts "Frodo" %>
```

なお、ERBには上のように`<%# %>`でコメントを書くことも可能です。

Webページへのレンダリング結果の冒頭と末尾からホワイトスペースを取り除きたい場合は、通常の`<% %>`の代わりに`<%- -%>`を利用できます（訳注: これは英語のようなスペース分かち書きを行なう言語向けのノウハウです）。

### Jbuilder

[Jbuilder](https://github.com/rails/jbuilder)はRailsチームによってメンテナンスされているgemの１つで、RailsのGemfileにデフォルトで含まれています。JbuilderはJSONレスポンスをビューテンプレートで生成するのに使われます。

Jbuilderが導入されていない場合は、Gemfileに以下を追加できます。

```ruby
gem 'jbuilder'
```

拡張子が`.jbuilder`のテンプレートでは、`json`という名前のJbuilderオブジェクトが自動的に利用可能になります。

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

詳しいコード例については[Jbuilderドキュメント](https://github.com/rails/jbuilder#jbuilder)を参照してください。

### Builder

BuilderテンプレートはERBの代わりに利用できる、よりプログラミング向きな記法です。これは`JBuilder`に似ていますが、JSONではなくXMLを生成するのに使われます。

拡張子が`.builder`のテンプレートでは、`xml`という名前の`XmlMarkup`オブジェクトが自動的に利用可能になります。

基本的な例を以下に示します。

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

ブロックを渡されたメソッドはすべて、ブロックの中にネストしたマークアップを含むXMLマークアップタグとして扱われます。以下の例で示します。

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

詳しいコード例については[Builderドキュメント](https://github.com/rails/builder)を参照してください。

### テンプレートをコンパイルする

Railsは、デフォルトでビューの各テンプレートをコンパイルしてレンダリング用メソッドにします。developmentモードの場合、ビューテンプレートが変更されるとファイルの更新日時で変更が検出され、再コンパイルされます。

ページのさまざまな部分を個別にキャッシュしたりキャッシュを失効させたりする必要がある場合には、フラグメントキャッシュも利用できます。詳しくは[キャッシュガイド](caching_with_rails.html#fragment-caching)を参照してください。

パーシャル
--------

パーシャル（部分テンプレート）は、ビューテンプレートを再利用可能な小さい部品に分割する方法です。パーシャルを利用することで、メインテンプレートのコードの一部を別の小さなファイルに抽出し、そのファイルをメインテンプレートでレンダリングできます。メインテンプレートからパーシャルファイルにデータを渡すことも可能です。

いくつかの例で実際の動作を見てみましょう。

### パーシャルをレンダリングする

パーシャルをビューの一部に含めてレンダリングするには、ビューで以下のように[`render`][]メソッドを使います。

```erb
<%= render "product" %>
```

上の呼び出しによって、`_product.html.erb`という名前のファイルが同じフォルダ内で検索され、そのビュー内でレンダリングされます。パーシャルファイル名の冒頭は、規約によりアンダースコア`_`で始まるので、パーシャルビューと通常のビューはファイル名で区別できます。ただし、レンダリングするパーシャルをビュー内で参照するときは、パーシャル名にアンダースコア`_`を追加せずに参照することにご注意ください。これは、以下のように別のディレクトリにあるパーシャルを参照する場合も同様です。

```erb
<%= render "application/product" %>
```

上のコードは、その位置に`app/views/application/_menu.html.erb`パーシャルを読み込みます。

[`render`]: https://api.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render

### パーシャルを活用してビューを簡潔に保つ

すぐに思い付くパーシャルの利用法のひとつが、パーシャルをサブルーチンと同等とみなすという方法です。ビューの詳細部分をパーシャルに移動し、コードの見通しを良くするためにパーシャルを使うのです。たとえば、以下のようなビューがあるとします。

```html+erb
<%= render "application/ad_banner" %>

<h1>Products</h1>

<p>私たちの素晴らしい製品のいくつかをご紹介します:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>

<%= render "application/footer" %>
```

上のコード例にある`_ad_banner.html.erb`パーシャルと`_footer.html.erb`パーシャルに含まれるコンテンツは、アプリケーション内のさまざまなページと共有できます。この"Products"ページの開発中は、パーシャルの細かな表示内容を気にせずに済みます。

上のコード例では、`_product.html.erb`パーシャルも使われています。このパーシャルには、個別の製品をレンダリングするための詳細なコードが含まれていて、`@products`コレクション内にある個別の製品をリスト化してレンダリングするのに使われます。

## パーシャルに`locals`オプションでデータを渡す

あるビュー内でパーシャルをレンダリングするときに、パーシャルにデータを引数のように渡すことが可能です。パーシャルに渡すデータは、`locals:`オプションにハッシュの形で渡します。`locals:`オプションに渡したハッシュの各キーは、パーシャル内でローカル変数として参照可能になります。

```html+erb
<%# app/views/products/show.html.erb %>

<%= render partial: "product", locals: { my_product: @product } %>
```

```html+erb
<%# app/views/products/_product.html.erb %>

<%= tag.div id: dom_id(my_product) do %>
  <h1><%= my_product.name %></h1>
<% end %>
```

「パーシャルローカル変数」とは、指定のパーシャル内のローカル変数、つまりそのパーシャル内でのみ利用可能な変数です。上のコード例では、`my_product`がパーシャルローカル変数であり、元のビューからパーシャルに渡されたときに、`@product`インスタンス変数の値が`my_product`に割り当てられたものです。

なお、このコード例では説明上インスタンス変数名やテンプレート名と一時的に区別するためにローカル変数名をあえて`my_product`としていますが、実際のコードでは`my_`などを付けずにインスタンス変数と一貫する`product`というローカル変数を使う方が一般的である点にご注意ください。

`locals`はハッシュなので、必要に応じて`locals: { my_product: @product, my_reviews: @reviews }`のように複数の変数を渡すことも可能です。

ただし、`locals:`オプションの一部としてビューに渡していない変数がテンプレート内で参照されると、`ActionView::Template::Error`が発生します。

```html+erb
<%# app/views/products/_product.html.erb %>

<%= tag.div id: dom_id(my_product) do %>
  <h1><%= my_product.name %></h1>

  <%# `product_reviews`は存在しないのでActionView::Template::Errorになる %>
  <% product_reviews.each do |review| %>
    <%# ... %>
  <% end %>
<% end %>
```

### `local_assigns`を使う

個別のパーシャル内では[`local_assigns`][]というメソッドが利用可能です。このメソッドを用いると、`locals:`オプション経由で渡されたキーにアクセスできます。パーシャルがレンダリングされるときに`:some_key`が未設定の場合、パーシャル内の `local_assigns[:some_key]`の値は`nil`になります。

たとえば、以下のコード例の`product_reviews`は`nil`になります。これは、`locals:`に設定されているのが`product`だけであるためです。

```html+erb
<%# app/views/products/show.html.erb %>

<%= render partial: "product", locals: { product: @product } %>

<%# app/views/products/_product.html.erb %>

<% local_assigns[:product]          # => "#<Product:0x0000000109ec5d10>" %>
<% local_assigns[:product_reviews]  # => nil %>
```

`local_assigns`のユースケースの1つは、ローカル変数をオプションとしてパーシャルに渡し、以下のようにローカル変数に値が設定済みかどうか基づいて条件付きで何らかの操作をパーシャル内で実行するというものです。

```html+erb
<% if local_assigns[:redirect] %>
  <%= form.hidden_field :redirect, value: true %>
<% end %>
```

別の例として、Active Storageの`_blob.html.erb`のコードを引用します。このコードは、この行を含むパーシャルをレンダリングするときに`in_gallery`ローカル変数が設定されているかどうかに基づいて表示サイズを設定します。

```html+erb
<%= image_tag blob.representation(resize_to_limit: local_assigns[:in_gallery] ? [ 800, 600 ] : [ 1024, 768 ]) %>
```

[`local_assigns`]: https://api.rubyonrails.org/classes/ActionView/Template.html#method-i-local_assigns

### `partial`や`locals`オプションを指定しない`render`

上の例では、`render`に`partial`と`locals`という2つのオプションを渡しましたが、渡したいオプションが他にない場合は、これらのオプションのキー名を省略して値だけを渡すことも可能です。

次の例で説明します。

```erb
<%= render partial: "product", locals: { product: @product } %>
```

上のコードは以下のように値だけを渡す形でも書けます。

```erb
<%= render "product", product: @product %>
```

上のコードは、パーシャル名とローカル変数名とインスタンス変数名が同じなので、以下のようにRailsの規約に沿った省略形でも書けます。

```erb
<%= render @product %>
```

この場合、`app/views/products/`ディレクトリ内で`_product.html.erb`というパーシャルを探索し、`product`というパーシャルローカル変数に`@product`インスタンス変数を設定します。

### `as`オプションと`object`オプション

`ActionView::Partials::PartialRenderer`は、デフォルトでテンプレートと同じ名前のローカル変数内に自身のオブジェクトを保持します。以下のコードを見てみましょう。

```erb
<%= render @product %>
```

上のコードでは、`_product`パーシャル内でローカル変数`product`から`@product`を取得できます。これは以下のコードと同等の結果になります。

```erb
<%= render partial: "product", locals: { product: @product } %>
```

`object`オプションは、パーシャルで出力するオブジェクトを直接指定したい場合に使います。これは、テンプレートのオブジェクトが他の場所（別のインスタンス変数や別のローカル変数など）にある場合に便利です。

たとえば、以下のコードがあるとします。

```erb
<%= render partial: "product", locals: { product: @item } %>
```

上のコードは以下のように書けます。

```erb
<%= render partial: "product", object: @item %>
```

ここでは、`@item`インスタンス変数が`product`という名前のパーシャルローカル変数に割り当てられます。

ローカル変数名をデフォルトの`product`から別の名前に変更したい場合は、`:as` オプションが使えます。
`as`オプションを使うと、以下のようにローカル変数に別の名前を指定できます。

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

上は以下と同等です。

```erb
<%= render partial: "product", locals: { item: @item } %>
```

### コレクションをレンダリングする

ビューで`@products`などのコレクションをイテレーションして、コレクション内のオブジェクトごとにパーシャルテンプレートをレンダリングするという方法は一般によく使われます。このパターンは、配列を受け取って、配列内の要素ごとにパーシャルをレンダリングする単一のメソッドとしてRailsに実装済みです。

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

パーシャルにコレクションを渡して呼び出すと、パーシャルの個別のインスタンスは、そのパーシャル名に沿った変数を介して、レンダリングするコレクションのメンバーにアクセスできるようになります。この場合、パーシャルは`_product.html.erb`というファイルなので、レンダリングするコレクションのメンバーに`product`という名前のローカル変数名で参照できます。

コレクションをレンダリングするために、Railsの規約に基づいた以下の省略形構文も利用できます。

```erb
<%= render @products %>
```

上のコード例では、`@products`インスタンス変数が`Product`インスタンスのコレクションであることが前提です。
Railsはコレクション内のモデル名（この場合は`Product`）を命名規約に沿って調べることで、利用するパーシャル名を決定します。

実は、この省略表現を使うと、コレクションがさまざまなモデルのインスタンスで構成されていてもレンダリング可能になります。Rails は、コレクションの各メンバーに適したパーシャルを選択します。

### スペーサーテンプレート

`:spacer_template`オプションを使うと、メインのパーシャルの間を埋める第2のパーシャルを指定できます。

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

上のコードは、メインの`_product`パーシャル同士の空きを調整するスペーサーとなる`_product_ruler`パーシャルをレンダリングします（`_product_ruler`にはデータを渡していません）。

### カウンタ変数

Railsでは、コレクションによって呼び出されるパーシャル内でカウンタ変数も利用可能です。カウンタ変数名は、パーシャル名の後ろに`_counter`を追加したものになります。たとえば、`@products`コレクションをレンダリングする場合、`_product.html.erb`パーシャルで`product_counter`変数にアクセスできます。このカウンタ変数は、最初のレンダリング時点の値が`0`から始まり、パーシャルの外側のビュー内でパーシャルがレンダリングされた回数を参照します。

```erb
<%# index.html.erb %>
<%= render partial: "product", collection: @products %>
```

```erb
<%# _product.html.erb %>
<%= product_counter %> # 1個目のproductは0、2個目のproductは1...
```

カウンタ変数は、`as:`オプションで名前が変更されたローカル変数でも利用できます。つまり、`as: :item`を指定すると、カウンタ変数は`item_counter`になります。

NOTE: 後述する2つのセクション[厳密な`locals`](#厳密なlocals)と[`local_assigns`でパターンマッチングを活用する](#local_assignsでパターンマッチングを活用する)では、より高度なパーシャルの利用法が説明されていますが、完全を期すためにここでも記載します。

### `local_assigns`でパターンマッチングを活用する

`local_assigns`は`Hash`なので、[Ruby 3.1のパターンマッチング代入演算子][pattern matching]と互換性があります。

```ruby
local_assigns => { product:, **options }
product # => "#<Product:0x0000000109ec5d10>"
options # => {}
```

パーシャルローカル変数に`:product`以外のキーを複数持つ`Hash`を代入する場合、以下のようにsplat演算子`**`でヘルパーメソッド呼び出しに展開して渡すことが可能です。

```html+erb
<%# app/views/products/_product.html.erb %>

<% local_assigns => { product:, **options } %>

<%= tag.div id: dom_id(product), **options do %>
  <h1><%= product.name %></h1>
<% end %>
```

```html+erb
<%# app/views/products/show.html.erb %>

<%= render "products/product", product: @product, class: "card" %>
<%# => <div id="product_1" class="card">
  #      <h1>A widget</h1>
  #    </div>
%>
```

パターンマッチングの代入では、変数のリネームもサポートされます。

```ruby
local_assigns => { product: record }
product             # => "#<Product:0x0000000109ec5d10>"
record              # => "#<Product:0x0000000109ec5d10>"
product == record   # => true
```

`local_assigns`で`fetch`を使うと、以下のように変数を条件付きで読み取り、キーが`locals:`オプションに含まれていない場合にデフォルト値にフォールバックすることも可能です。

```html+erb
<%# app/views/products/_product.html.erb %>

<% local_assigns.fetch(:related_products, []).each do |related_product| %>
  <%# ... %>
<% end %>
```

Ruby 3.1のパターンマッチング代入演算子に[`Hash#with_defaults`][]呼び出しを組み合わせると、パーシャルローカル変数のデフォルト値代入を以下のようにコンパクトに書けます。

```html+erb
<%# app/views/products/_product.html.erb %>

<% local_assigns.with_defaults(related_products: []) => { product:, related_products: } %>

<%= tag.div id: dom_id(product) do %>
  <h1><%= product.name %></h1>

  <% related_products.each do |related_product| %>
    <%# ... %>
  <% end %>
<% end %>
```

INFO: デフォルトのパーシャルは、`locals`として任意のキーワード引数を受け取れます。パーシャルが受け取れる`locals`のキーワード引数を限定するには、`locals:`マジックコメントを使います。詳しくは、次の[厳密な`locals`](#厳密なlocals)を参照してください。

[pattern matching]: https://docs.ruby-lang.org/en/master/syntax/pattern_matching_rdoc.html
[`local_assigns`]: https://api.rubyonrails.org/classes/ActionView/Template.html#method-i-local_assigns
[`Hash#with_defaults`]: https://api.rubyonrails.org/classes/Hash.html#method-i-with_defaults

### 厳密な`locals`

デフォルトのテンプレートは、`locals`として受け取れるキーワード引数の個数に制約がありません。テンプレートが受け取ってよい`locals`のキーワード引数やその個数に制約をかけたりデフォルト値を設定したりするには、以下のように`locals`マジックコメントをビューに追加します。

`locals:`マジックコメントの例を以下に示します。

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message:) -%>
<%= message %>
```

上のコード例では、`message`ローカル変数が必須になり、パーシャルを呼び出すときに省略できなくなります。引数に`:message`ローカル変数を渡さずにこのパーシャルをレンダリングすると例外が発生します。

```ruby
render "messages/message"
# => ActionView::Template::Error: missing local: :message for app/views/messages/_message.html.erb
```

以下のように`message`にデフォルト値を設定しておくと、`message`が渡されない場合にそのデフォルト値が使われます。

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!") -%>
<%= message %>
```

上のパーシャルに`:message`ローカル変数を渡さずにレンダリングすると、`locals:`マジックコメントで設定したデフォルト値が使われます。

```ruby
render "messages/message"
# => "Hello, world!"
```

同様に、`local:`マジックコメントで許可されていないローカル変数を渡してパーシャルをレンダリングすると、例外が発生します。

```ruby
render "messages/message", unknown_local: "will raise"
# => ActionView::Template::Error: unknown local: :unknown_local for app/views/messages/_message.html.erb
```

以下のようにdouble splat演算子`**`も併用すると、オプションのローカル変数も引数として渡せるようになります。

```erb

<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!", **attributes) -%>
<%= tag.p(message, **attributes) %>
```

逆に、以下のように`locals: ()`を設定すると、`locals`を完全に無効にできます。

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: () %>
```

上のコード例では、パーシャルにどんなローカル変数を渡しても以下のように例外が発生します。

```ruby
render "messages/message", unknown_local: "will raise"
# => ActionView::Template::Error: no locals accepted for app/views/messages/_message.html.erb
```

Action Viewでは、`#`で始まるコメントをサポートする任意のテンプレートエンジンで`locals:`マジックコメントを処理します。また、マジックコメントはパーシャル内のどの行に書かれていても認識されます。

CAUTION: サポートされているのはキーワード引数のみです。位置引数やブロック引数が使われると、レンダリング時にAction Viewエラーが発生します。

### レイアウト

レイアウト（layout）を使うと、Railsのさまざまなコントローラアクションの結果を共通のビューテンプレートでレンダリングできます。Railsアプリケーションでは、ページのレンダリングに複数のレイアウトを利用可能です。

たとえば、あるアプリケーションでは、ユーザーログインページでログインに適したレイアウトを利用し、マーケティングやセールス用ページではそれに適した別のレイアウトを利用できます。ログインしたユーザー向けのレイアウトであれば、ナビゲーションツールバーをページのトップレベルに表示するスタイルを多くのコントローラやアクションで共通化することも可能です。SaaSアプリケーションの商品販売用レイアウトであれば、トップレベルのナビゲーションに「お値段」や「お問い合わせ先」を共通して表示できます。また、レイアウトごとにヘッダーやフッターのコンテンツを変更することも可能です。

Railsでは、現在のコントローラアクションに対応するレイアウトを探索するために、最初にコントローラと同じベース名を持つファイルを`app/views/layouts`ディレクトリ内で探します。たとえば、`ProductsController`クラスのアクションをレンダリングする場合、`app/views/layouts/products.html.erb`が使われます。

コントローラに対応するレイアウトが存在しない場合は、`app/views/layouts/application.html.erb`

以下は、`application.html.erb`ファイルのシンプルなレイアウトの例です。

```html+erb
<!DOCTYPE html>
<html>
<head>
  <title><%= "Your Rails App" %></title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
<body>

<nav>
  <ul>
    <li><%= link_to "Home", root_path %></li>
    <li><%= link_to "Products", products_path %></li>
    <!-- Additional navigation links here -->
  </ul>
</nav>

<%= yield %>

<footer>
  <p>&copy; <%= Date.current.year %> Your Company</p>
</footer>
```

上のレイアウト例では、`<%= yield %>`の部分でビューコンテンツがレンダリングされ、それが`<head>`や`<nav>`や`<footer>`のコンテンツで囲まれる形になります。

Railsには、個別のコントローラアクションに対応するレイアウトを割り当てるためのさまざまな方法が用意されています。Railsのレイアウトについて詳しくは、[ビューのレイアウトとレンダリング](layouts_and_rendering.html)ガイドを参照してください。

### パーシャルレイアウト

パーシャルにも独自のレイアウトを適用できます。パーシャル用のレイアウトは、アクション全体にわたるグローバルなレイアウトとは異なりますが、同じように動作します。

試しに、ページ上に投稿を1つ表示してみましょう。表示制御のため`div`タグで囲むことにします。最初に、`Article`を1つ新規作成します。

```ruby
Article.create(body: 'パーシャルレイアウトはいいぞ！')
```

`show`テンプレートは、`box`レイアウトで囲まれた`_article`パーシャルを出力します。

**articles/show.html.erb**

```erb
<%= render partial: 'article', layout: 'box', locals: { article: @article } %>
```

`box`レイアウトは、`div`タグで`_article`パーシャルを囲んだ簡単な構造です。

 **articles/_box.html.erb**

```html+erb
<div class="box">
  <%= yield %>
</div>
```

この例では、パーシャルレイアウト`_box.html.erb`内で`article`ローカル変数が使われていないにもかかわらず、`render`呼び出しに渡された`article`ローカル変数にアクセスできる点にご注目ください。

アプリケーション共通のレイアウトを参照する場合とは異なり、パーシャルレイアウトを参照するときはアンダースコア`_`を付ける点にご注意ください。

`yield`を呼び出す代わりに、パーシャルレイアウト内にあるコードのブロックをレンダリングすることも可能です。たとえば、`_article`というパーシャルがない場合でも、以下のような呼び出しが行えます。

```html+erb
<%= render(layout: 'box', locals: { article: @article }) do %>
  <div>
    <p><%= article.body %></p>
  </div>
<% end %>
```

ここでも同じ`_box`パーシャルを使っていれば、上述の例と同じ出力が得られます。

### コレクションでパーシャルレイアウトを利用する

コレクションをレンダリングする場合、パーシャルレイアウトに`:layout`オプションを指定することも可能です。

```erb
<%= render partial: "article", collection: @articles, layout: "special_layout" %>
```

コレクション内の各アイテムに対してパーシャルをレンダリングするときに、このレイアウトもレンダリングされます。現在のオブジェクト（`article`など）やオブジェクトのカウンタ変数（`article_counter`など）は、パーシャル内の場合と同様にレイアウト内でも利用可能です。

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

たとえば、`ArticlesController`に`show`アクションがあるとします。この`show`アクションを呼び出すと、デフォルトでは`app/views/articles/show.html.erb`が出力されます。ここで`I18n.locale = :de`を設定すると、代わりに`app/views/articles/show.de.html.erb`がレンダリングされます。ローカライズ版のテンプレートが見当たらない場合は、装飾なしのバージョンが使われます。つまり、ローカライズ版ビューがなくても動作しますが、ローカライズ版ビューがあればそれが使われます。

同じ要領で、publicディレクトリのレスキューファイル (いわゆるエラーページ) もローカライズできます。たとえば、`I18n.locale = :de`と設定し、`public/500.de.html`と`public/404.de.html`を作成することで、ローカライズ版のレスキューページを作成できます。

詳しくは[Rails 国際化 (i18n) API](i18n.html) を参照してください。
