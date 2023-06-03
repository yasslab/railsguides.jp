Action View ヘルパー
====================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Action View Helpers](https://guides.rubyonrails.org/action_view_helpers.html)を日本語に翻訳した文書です。

このガイドの内容:

* 日付、文字列、数値のフォーマット方法
* 画像、動画、スタイルシートなどへのリンク方法
* コンテンツのサニタイズ方法
* コンテンツのローカライズ方法

--------------------------------------------------------------------------------

Action Viewで提供されるヘルパーの概要
-------------------------------------------

WIP: ここに記載されているのはヘルパーの一部です。完全なリストについては[APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers.html)を参照してください。

以下は、Action Viewで利用できるヘルパーの簡単な概要のまとめに過ぎません。すべてのヘルパーについて詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers.html)を参照することをおすすめしますが、本ガイドを最初に読んでおくとよいでしょう。

### AssetTagHelperモジュール

このモジュールは、ビューを「画像」「JavaScriptファイル」「スタイルシート（CSS）」「フィード」などのアセットにリンクするHTMLを生成するメソッド（ヘルパーメソッド）を提供します。

デフォルトでは、現在のホストの`public/`フォルダにあるこれらのアセットにリンクされますが、アプリケーション設定の[`config.asset_host`][]を設定すれば、アセット専用サーバー上にあるアセットに直接リンクできます。たとえば、アセットホストが`assets.example.com`の場合は以下のように設定します。

```ruby
config.asset_host = "assets.example.com"
image_tag("rails.png")
# => <img src="http://assets.example.com/images/rails.png" />
```

[`config.asset_host`]: configuring.html#config-asset-host

#### `auto_discovery_link_tag`

ブラウザやRSSフィードリーダーが「RSS」「Atom」または「JSON」フィードを自動検出するときに利用可能なリンクタグを返します。

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", { title: "RSS Feed" })
# => <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed.rss" />
```

#### `image_path`

`app/assets/images`ディレクトリの下に置かれている画像アセットへのパスを算出します。ドキュメントルートを基点とする完全なパスはそのままパススルーされます。内部では`image_tag`を用いて画像パスをビルドします。

```ruby
image_path("edit.png") # => /assets/edit.png
```

`config.assets.digest `をtrueに設定すると、以下のようにフィンガープリントがファイル名に追加されます。

```ruby
image_path("edit.png")
# => /assets/edit-2d1a2db63fc738690021fedb5a65b68e.png
```

#### `image_url`

`app/assets/images`ディレクトリの下に置かれている画像アセットへのURLを算出します。このヘルパーの内部では`image_path`を呼び出し、現在のホストやアセットホストをマージします。

```ruby
image_url("edit.png") # => http://www.example.com/assets/edit.png
```

#### `image_tag`

指定されたソースに対応するHTMLの`img`タグを返します。ソースには、完全なパスか、アプリの`app/assets/images`ディレクトリの下に存在するファイルを指定できます。

```ruby
image_tag("icon.png") # => <img src="/assets/icon.png" />
```

#### `javascript_include_tag`

指定されたソースごとにHTMLの`script`タグを返します。`app/assets/javascripts`ディレクトリの下に存在するJavaScriptファイル名（拡張子`.js`はオプションなので、あってもなくてもよい）を渡すことも、ドキュメントルートからの相対的な完全パスを渡すこともできます。

```ruby
javascript_include_tag "common"
# => <script src="/assets/common.js"></script>
```

#### `javascript_path`

`app/assets/javascripts`ディレクトリの下に置かれているJavaScriptアセットへのパスを算出します。ソースファイル名に拡張子がない場合は`.js`が追加されます。ドキュメントルートを基点とする完全なパスはそのままパススルーされます。このヘルパーの内部では`javascript_include_tag`を用いてスクリプトパスをビルドします。

```ruby
javascript_path "common" # => /assets/common.js
```

#### `javascript_url`

`app/assets/javascripts`ディレクトリの下にあるJavaScriptアセットへのURLを算出します。このヘルパーの内部では`javascript_path`を呼び出し、現在のホストやアセットホストをマージします。

```ruby
javascript_url "common"
# => http://www.example.com/assets/common.js
```

#### `stylesheet_link_tag`

引数で指定されたソースに対応するスタイルシートリンクタグを返します。拡張子が指定されていない場合は、自動的に`.css`が追加されます。

```ruby
stylesheet_link_tag "application"
# => <link href="/assets/application.css" rel="stylesheet" />
```

#### `stylesheet_path`

`app/assets/stylesheets`ディレクトリの下にあるスタイルシートアセットへのパスを算出します。ファイル名に拡張子がない場合は`.css`が追加されます。ドキュメントルートを基点とする完全なパスはそのままパススルーされます。このヘルパーの内部では`stylesheet_link_tag`を用いてスタイルシートパスをビルドします。

```ruby
stylesheet_path "application" # => /assets/application.css
```

#### `stylesheet_url`

`app/assets/stylesheets`ディレクトリの下にあるスタイルシートアセットへのURLを算出します。このヘルパーの内部では`stylesheet_path`を用いてスタイルシートパスをビルドします。

```ruby
stylesheet_url "application"
# => http://www.example.com/assets/application.css
```

### AtomFeedHelperモジュール

#### `atom_feed`

このヘルパーは、Atomフィードを簡単にビルドできるようにします。以下は完全な利用例です。

**config/routes.rb**

```ruby
resources :articles
```

**app/controllers/articles_controller.rb**

```ruby
def index
  @articles = Article.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

**app/views/articles/index.atom.builder**

```ruby
atom_feed do |feed|
  feed.title("Articles Index")
  feed.updated(@articles.first.created_at)

  @articles.each do |article|
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(article.body, type: 'html')

      entry.author do |author|
        author.name(article.author_name)
      end
    end
  end
end
```

### BenchmarkHelperモジュール

#### `benchmark`

ビューテンプレート内にあるブロックの実行時間を測定して、結果をログに出力できます。コストの高い操作やボトルネックになっている可能性のある部分をブロックで囲むことで、その中での処理時間を読み取れます。

```html+erb
<% benchmark "データファイルの処理" do %>
  <%= expensive_files_operation %>
<% end %>
```

上のようにすることで、"Process data files (0.34523)" のような情報がログに追加され、コード最適化作業でタイミングを比較できるようになります。

### CacheHelperモジュール

#### `cache`

アクション全体やページ全体ではなく、ビューのフラグメントをキャッシュするメソッドです。この手法は、メニューやニューストピックのリスト、静的なHTMLフラグメントなどをキャッシュする場合に便利です。このメソッドは、キャッシュしたいコンテンツを含むブロックを1個受け取ります。詳しくは`AbstractController::Caching::Fragments`を参照してください。

```erb
<% cache do %>
  <%= render "shared/footer" %>
<% end %>
```

### CaptureHelperモジュール

#### `capture`

`capture`は、テンプレートの一部を変数に切り出すのに使えます。切り出したこの変数は、そのテンプレートやレイアウト内のどこでも利用できます。

```html+erb
<% @greeting = capture do %>
  <p>ようこそ！現在の日時: <%= Time.now %></p>
<% end %>
```

上のように書くことで、キャプチャされた変数を以下のように他のどこでも利用できるようになります。

```html+erb
<html>
  <head>
    <title>ようこそ！</title>
  </head>
  <body>
    <%= @greeting %>
  </body>
</html>
```

#### `content_for`

`content_for`を呼び出すと、マークアップのブロックを識別子に保存して、後で利用できるようにします。その識別子を`yield`の引数に渡すことで、以後他のテンプレートやレイアウト内に保存されたコンテンツを呼び出せるようになります。

たとえば、標準的なアプリケーションレイアウトがあり、特定のページでのみ、他のサイトでは必要とされないJavaScriptが必要になるとします。このような場合は、以下のように`content_for`を使うことで、他のサイトのコード量を増やさずに特定のページでのみこのJavaScriptコードをインクルードできます。

**app/views/layouts/application.html.erb**

```html+erb
<html>
  <head>
    <title>ようこそ！</title>
    <%= yield :special_script %>
  </head>
  <body>
    <p>ようこそ！現在の日時:  <%= Time.now %></p>
  </body>
</html>
```

**app/views/articles/special.html.erb**

```html+erb
<p>ここは特別なページ</p>

<% content_for :special_script do %>
  <script>alert('こんにちは！')</script>
<% end %>
```

### DateHelperモジュール

#### `distance_of_time_in_words`

2つの「`Time`オブジェクト」「`Date`オブジェクト」「整数（秒）」同士のおおよそのインターバル（時刻と時刻の間隔）を英文で出力します。単位を詳細にしたい場合は`include_seconds`をtrueに設定します。

```ruby
distance_of_time_in_words(Time.now, Time.now + 15.seconds)
# => less than a minute
distance_of_time_in_words(Time.now, Time.now + 15.seconds, include_seconds: true)
# => less than 20 seconds
```

#### `time_ago_in_words`

`distance_of_time_in_words`と同様ですが、`to_time`（終端時刻）が`Time.now`に固定されている点が異なります。

```ruby
time_ago_in_words(3.minutes.from_now) # => 3 minutes
```

### DebugHelperモジュール

オブジェクトをYAML形式でダンプした`pre`タグを返します。これにより、オブジェクトを見やすい形で取り出せます。

```ruby
my_hash = { 'first' => 1, 'second' => 'two', 'third' => [1,2,3] }
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

### FormHelperモジュール

フォームヘルパーは、モデルに基づいてフォームを作成する一連のメソッドを提供します。これらを用いることで、標準のHTML要素を用いるよりもモデルでの作業の負担を大きく軽減できるよう設計されています。フォームペルパーは、フォーム用のHTMLを生成し、ユーザー入力の種類（テキストフィールド、パスワードフィールド、ドロップダウンボックスなど）に応じたメソッドを提供します。フォームが（ユーザーが送信ボタンを押す、JavaScriptで`form.submit`を呼び出すなどの方法で）送信されると、フォームへの入力が`params`オブジェクトにまとめられてコントローラに返されます。

フォームヘルパーについて詳しくは、ガイドの[Action View フォームヘルパー](form_helpers.html)を参照してください。

### JavaScriptHelperモジュール

ビューでJavaScriptを操作するための機能を提供します。

#### `escape_javascript`

JavaScriptセグメントでキャリッジリターンや一重引用符や二重引用符をエスケープします。

#### `javascript_tag`

渡されたコードをJavaScriptタグでラップして返します。

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

### NumberHelperモジュール

数値を書式付き文字列に変換するメソッドを提供します。「電話番号」「通貨」「パーセント」「精度」「桁区切り記号の位置」「ファイルサイズ」用のメソッドが提供されます。

#### `number_to_currency`

数値を通貨表示の文字列にフォーマットします（$13.65など）。

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

#### `number_to_human`

数値を、人間が読みやすい形式（数詞を追加）で近似表示します。数値が非常に大きくなる可能性がある場合に便利です。

```ruby
number_to_human(1234)    # => 1.23 Thousand
number_to_human(1234567) # => 1.23 Million
```

#### `number_to_human_size`

バイト単位の数値を、KBやMBなどのわかりやすい単位でフォーマットします。ファイルサイズを表示する場合に便利です。

```ruby
number_to_human_size(1234)    # => 1.21 KB
number_to_human_size(1234567) # => 1.18 MB
```

#### `number_to_percentage`

数値をパーセント形式の文字列にフォーマットします。

```ruby
number_to_percentage(100, precision: 0) # => 100%
```

#### `number_to_phone`

数値を電話番号形式にフォーマットします（デフォルトは米国の電話番号形式）。

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

#### `number_with_delimiter`

数値を区切り文字で3桁ずつグループ化します。

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

#### `number_with_precision`

数値の小数点以下の精度（表示を丸める位置）を`precision`で指定できます（デフォルトは3）。

```ruby
number_with_precision(111.2345)               # => 111.235
number_with_precision(111.2345, precision: 2) # => 111.23
```

### SanitizeHelperモジュール

SanitizeHelperモジュールは、望ましくないHTML要素のテキストをスクラブ（除去）する一連のメソッドを提供します。

#### `sanitize`

この`sanitize`ヘルパーは、すべてのタグをHTMLエンコードし、許可されていない属性をすべて削除します。

```ruby
sanitize @article.body
```

`:attributes`オプションと`:tags`オプションのいずれかを渡すと、オプションで指定した属性またはタグだけが許可されます（つまり除去されません）。それ以外の属性やタグは許可されません（つまり除去されます）。

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

よく使うオプションをデフォルト化するには、以下のようにアプリケーション設定でオプションをデフォルトに追加します。以下はtable関連のタグを追加した場合の例です。

```ruby
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
end
```

#### `sanitize_css(style)`

CSSコードのブロックをサニタイズします。

#### `strip_links(html)`

テキスト内のリンクタグを削除し、リンクテキストだけを残します。

```ruby
strip_links('<a href="https://rubyonrails.org">Ruby on Rails</a>')
# => Ruby on Rails
```

```ruby
strip_links('emails to <a href="mailto:me@email.com">me@email.com</a>.')
# => emails to me@email.com.
```

```ruby
strip_links('Blog: <a href="http://myblog.com/">Visit</a>.')
# => Blog: Visit.
```

#### `strip_tags(html)`

HTMLからすべてのHTMLタグをストリップします（コメントもストリップされます）。
この機能は[rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer) gemによるものです。

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!
```

```ruby
strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more</a>")
# => Bold no more!  See more
```

### UrlHelper

リンクを作成するメソッドや、ルーティングサブシステムに応じたURLを取得するメソッドを提供します。

#### `url_for`

`options`で渡されたセットに対応するURLを返します。

##### 例

```ruby
url_for @profile
# => /profiles/1

url_for [ @hotel, @booking, page: 2, line: 3 ]
# => /hotels/1/bookings/1?line=3&page=2
```

#### `link_to`

背後の`url_for`で得られたURLへのリンクを生成します。主な用途は、RESTfulなリソースリンクの作成です。たとえば`link_to`にモデルを渡すと以下のようにリンクが生成されます。

##### 例

```ruby
link_to "Profile", @profile
# => <a href="/profiles/1">Profile</a>
```

以下のERBのようにブロックを渡すことで、リンク文字列を`name`パラメータに応じて変えることもできます。

```html+erb
<%= link_to @profile do %>
  <strong><%= @profile.name %></strong> -- <span>Check it out!</span>
<% end %>
```

上は以下のリンクを生成します。

```html
<a href="/profiles/1">
  <strong>David</strong> -- <span>Check it out!</span>
</a>
```

詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to)を参照してください。

#### `button_to`

渡されたURLに送信するフォームを生成します。このフォームには、`name`の値がボタン名となる送信ボタンが表示されます。

##### 例

```html+erb
<%= button_to "Sign in", sign_in_path %>
```

上は以下のようなフォームを生成します。

```html
<form method="post" action="/sessions" class="button_to">
  <input type="submit" value="Sign in" />
</form>
```

詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)を参照してください。

### CsrfHelper

"csrf-param"メタタグと"csrf-token"メタタグに、CSRF保護用のパラメータとトークンを入れて返します。

```html+erb
<%= csrf_meta_tags %>
```

NOTE: 通常のフォームではhiddenフィールドが生成されるので、これらのタグは使われません。詳しくは[Railsセキュリティガイド](/security.html#クロスサイトリクエストフォージェリ（csrf）)を参照してください。
