Action View ヘルパー
====================

このガイドの内容:

* 日付、文字列、数値のフォーマット方法
* テキストやタグの処理方法
* 画像、動画、スタイルシートなどへのリンク方法
* Atomフィードの生成方法やビューでのJavaScriptの利用方法
* キャッシュ、キャプチャ、デバッグ、コンテンツのサニタイズ方法

--------------------------------------------------------------------------------

本ガイドでは、Action Viewで利用できるヘルパーのうち、**最もよく使われるヘルパーの一部**の概要を解説するにとどめています。本ガイドはヘルパー入門として提供されていますが、すべてのヘルパーについて詳しい説明が網羅されている[APIドキュメント][API Documents]も参照するのがオススメです。

[API Documents]: https://api.rubyonrails.org/classes/ActionView/Helpers.html

フォーマット用ヘルパー
----------

### 日付・時刻ヘルパー

これらのヘルパーは、日付や時刻の要素をコンテキストに応じて人間が読み取り可能な形式として表示するのに役立ちます。

#### `distance_of_time_in_words`

2つの「`Time`オブジェクト」「`Date`オブジェクト」「整数（秒）」同士のおおよそのインターバル（日時と日時の間隔）を英文で出力します。単位を詳細にしたい場合は`include_seconds: true`を設定します。

```ruby
distance_of_time_in_words(Time.current, 15.seconds.from_now)
# => less than a minute
distance_of_time_in_words(Time.current, 15.seconds.from_now, include_seconds: true)
# => less than 20 seconds
```

NOTE: 上のサンプルコードで`Time.now`ではなく`Time.current`を使っている点にご注意ください。`Time.current`はRailsアプリケーションに設定されているタイムゾーンに基づいた現在時刻を返しますが、`Time.now`は（Railsアプリケーションではなく）サーバーのタイムゾーンに基づいた現在時刻を返します。

詳しくは[`distance_of_time_in_words`][]APIドキュメントを参照してください。

[`distance_of_time_in_words`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-distance_of_time_in_words

#### `time_ago_in_words`

「`Time`オブジェクト」「`Date`オブジェクト」または「整数（秒）」と、`Time.current`の間のおおよそのインターバル（日時と日時の間隔）を英文で出力します。

```ruby
time_ago_in_words(3.minutes.from_now) # => 3 minutes
```

詳しくは[`time_ago_in_words`][] APIドキュメントを参照してください。

[`time_ago_in_words`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-time_ago_in_words

### 数値ヘルパー

数値を書式付き文字列に変換するさまざまなメソッドを提供します。「電話番号」「通貨」「パーセント」「精度」「桁区切り記号」「ファイルサイズ」用のメソッドが提供されます。

#### `number_to_currency`

数値を通貨表示の文字列にフォーマットします（$13.65など）。

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

詳しくは[`number_to_currency`][] APIドキュメントを参照してください。

[`number_to_currency`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_currency

#### `number_to_human`

数値を、人間が読みやすい形式（数詞を追加）で近似表示します。数値が非常に大きくなる可能性がある場合に便利です。

```ruby
number_to_human(1234)    # => 1.23 Thousand
number_to_human(1234567) # => 1.23 Million
```

詳しくは[`number_to_human`][] APIドキュメントを参照してください。

[`number_to_human`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_human

#### `number_to_human_size`

バイト単位の数値を、KBやMBなどのわかりやすい単位でフォーマットします。ファイルサイズを表示する場合に便利です。

```ruby
number_to_human_size(1234)    # => 1.21 KB
number_to_human_size(1234567) # => 1.18 MB
```

詳しくは[`number_to_human_size`][] APIドキュメントを参照してください。

[`number_to_human_size`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_human_size

#### `number_to_percentage`

数値をパーセント形式の文字列にフォーマットします。

```ruby
number_to_percentage(100, precision: 0) # => 100%
```

詳しくは[`number_to_percentage`][] APIドキュメントを参照してください。

[`number_to_percentage`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_percentage

#### `number_to_phone`

数値を電話番号形式にフォーマットします（デフォルトは米国の電話番号形式）。

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

詳しくは[`number_to_phone`][] APIドキュメントを参照してください。

[`number_to_phone`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_phone

#### `number_with_delimiter`

数値を区切り文字で3桁ずつグループ化します。

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

詳しくは[`number_with_delimiter`][] APIドキュメントを参照してください。

[`number_with_delimiter`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_with_delimiter

#### `number_with_precision`

数値の小数点以下の精度（表示を丸める位置）を`precision`で指定できます（デフォルトは3）。

```ruby
number_with_precision(111.2345)               # => 111.235
number_with_precision(111.2345, precision: 2) # => 111.23
```

詳しくは[`number_with_precision`][] APIドキュメントを参照してください。

[`number_with_precision`]: https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_with_precision

### テキストヘルパー

文字列のフィルタリング、フォーマット、変換を行うメソッドを提供します。

#### `excerpt`

`excerpt`ヘルパーに`text`（第1引数）と`phrase`（第2引数）を渡すと、`phrase`で指定したものが最初に出現する位置を中心に、前後のテキストを`radius`オプションで指定した単語の数だけ`text`から抜粋します。抽出したテキストの冒頭や末尾が`text`の冒頭や末尾と異なる場合は、省略記号`...`が追加されます。

```ruby
excerpt("This is a very beautiful morning", "very", separator: " ", radius: 1)
# => ...a very beautiful...

excerpt("This is also an example", "an", radius: 8, omission: "<chop> ")
#=> <chop> is also an example
```

詳しくは[`excerpt`][] APIドキュメントを参照してください。

[`excerpt`]: https://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-excerpt

#### `pluralize`

英単語の単数形または複数形を、指定の数値に応じて返します。

```ruby
pluralize(1, "person") # => 1 person
pluralize(2, "person") # => 2 people
pluralize(3, "person", plural: "users") # => 3 users
```

詳しくは[`pluralize`][] APIドキュメントを参照してください。

[`pluralize`]: https://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-pluralize

#### `truncate`

`text`（第1引数）に渡したテキストを、`length`オプションで指定した長さに切り詰めます。テキストが切り詰められた場合は、`length`オプションで指定した長さを超えないように省略記号`...`が追加されます。

```ruby
truncate("Once upon a time in a world far far away")
# => "Once upon a time in a world..."

truncate("Once upon a time in a world far far away", length: 17)
# => "Once upon a ti..."

truncate("one-two-three-four-five", length: 20, separator: "-")
# => "one-two-three..."

truncate("And they found that many people were sleeping better.", length: 25, omission: "... (continued)")
# => "And they f... (continued)"

truncate("<p>Once upon a time in a world far far away</p>", escape: false)
# => "<p>Once upon a time in a wo..."
```

詳しくは[`truncate`][] APIドキュメントを参照してください。

[`truncate`]: https://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-truncate

#### `word_wrap`

`line_width`オプションで指定した幅に収まるようにテキストを改行します。

```ruby
word_wrap("Once upon a time", line_width: 8)
# => "Once\nupon a\ntime"
```

詳しくは[`word_wrap`][] APIドキュメントを参照してください。

[`word_wrap`]: https://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-word_wrap

フォームヘルパー
------------

フォームヘルパーを利用すると、HTML要素だけでフォームを作成するよりもモデルの扱いがシンプルになります。フォームヘルパーは、モデルに基づいたフォーム生成に特化しており、ユーザー入力の種類（テキストフィールド、パスワードフィールド、ドロップダウンボックスなど）に応じたさまざまなメソッドを提供します。フォームが送信されると、フォームへの入力が`params`オブジェクトにまとめられてコントローラに送信されます。

フォームヘルパーについて詳しくは、[Action View フォームヘルパー](form_helpers.html)ガイドを参照してください。

ナビゲーション
------------

ルーティングサブシステムに依存する形でリンクやURLをビルドするための一連のメソッドです。

### `button_to`

渡されたURLに送信するフォームを生成します。このフォームには、`name`の値がボタン名となる送信ボタンが表示されます。

```html+erb
<%= button_to "Sign in", sign_in_path %>
```

上は以下のようなフォームを生成します。

```html
<form method="post" action="/sessions" class="button_to">
  <input type="submit" value="Sign in" />
</form>
```

詳しくは[`button_to`][] APIドキュメントを参照してください。

[`button_to`]: https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to

### `current_page?`

このヘルパーに渡したオプションが現在のリクエストURLと一致する場合は`true`を返します。

```html+erb
<% if current_page?(controller: 'profiles', action: 'show') %>
  <strong>Currently on the profile page</strong>
<% end %>
```

詳しくは[`current_page?`][] APIドキュメントを参照してください。

[`current_page?`]: https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-current_page-3F

### `link_to`

内部で`url_for`から導出したURLへのリンクを生成します。`link_to`は、RESTfulリソースのリンクを作成するために用いるのが一般的で、特にモデルを引数として`link_to`に渡すときに多用されます。

```ruby
link_to "Profile", @profile
# => <a href="/profiles/1">Profile</a>

link_to "Book", @book # 複合主キー[:author_id, :id]を渡した場合
# => <a href="/books/2_1">Book</a>

link_to "Profiles", profiles_path
# => <a href="/profiles">Profiles</a>

link_to nil, "https://example.com"
# => <a href="https://www.example.com">https://www.example.com</a>

link_to "Articles", articles_path, id: "articles", class: "article__container"
# => <a href="/articles" class="article__container" id="articles">Articles</a>
```

以下のようにブロックを渡すと、リンクの表示名を`name`パラメーターと異なるものにできます。

```html+erb
<%= link_to @profile do %>
  <strong><%= @profile.name %></strong> -- <span>Check it out!</span>
<% end %>
```

上のコードで以下のようなHTMLが出力されます。

```html
<a href="/profiles/1">
  <strong>David</strong> -- <span>Check it out!</span>
</a>
```

詳しくは[`link_to`][] APIドキュメントを参照してください。

[`link_to`]: https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to

### `mail_to`

指定したメールアドレスへの`mailto`リンクタグを生成します。リンクテキスト、追加のHTMLオプション、メールアドレスをエンコードするかどうかも指定できます。

```ruby
mail_to "john_doe@gmail.com"
# => <a href="mailto:john_doe@gmail.com">john_doe@gmail.com</a>

mail_to "me@john_doe.com", cc: "me@jane_doe.com",
        subject: "This is an example email"
# => <a href="mailto:"me@john_doe.com?cc=me@jane_doe.com&subject=This%20is%20an%20example%20email">"me@john_doe.com</a>
```

詳しくは[`mail_to`][] APIドキュメントを参照してください。

[`mail_to`]: https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-mail_to

### `url_for`

`options`で渡した一連のオプションに対応するURLを返します。

```ruby
url_for @profile
# => /profiles/1

url_for [ @hotel, @booking, page: 2, line: 3 ]
# => /hotels/1/bookings/1?line=3&page=2

url_for @post # 複合主キー[:blog_id, :id]を渡した場合
# => /posts/1_2
```

サニタイズヘルパー
---------------

望ましくないHTML要素をテキストから除去するための一連のメソッドです。サニタイズヘルパーは、安全で有効なHTML/CSSだけをレンダリングするときに特に有用です。また、サニタイズヘルパーはXSS（クロスサイトスクリプティング）攻撃を防ぐうえでも有用で、ユーザー入力に含まれる可能性のある危険なコンテンツを、ビューで表示する前にエスケープまたは削除します。

サニタイズヘルパーは、内部で[rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer) gemを利用しています。

### `sanitize`

`sanitize`ヘルパーは、すべてのHTMLタグをエンコードし、許可されていない属性をすべて削除します。

```ruby
sanitize @article.body
```

`:attributes`オプションと`:tags`オプションのいずれかを渡すと、オプションで指定した属性またはタグだけが許可されます（つまり除去されません）。それ以外の属性やタグは除去されます。

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

よく使うオプションをデフォルト化するには、アプリケーション設定でオプションをデフォルトに追加します。以下はtable関連のタグを追加した場合の例です。

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = %w(table tr td)
end
```

詳しくは[`sanitize`][] APIドキュメントを参照してください。

[`sanitize`]: https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html#method-i-sanitize

### `sanitize_css`

CSSのコードブロックをサニタイズします（特にHTMLコンテンツ内にスタイル属性が含まれている場合）。`sanitize_css` は、ユーザー入力から生成されたコンテンツや、スタイル属性を含む動的コンテンツを扱う場合に特に役立ちます。

以下の`sanitize_css`メソッドは、許可されていないCSSスタイルを削除します。

```ruby
sanitize_css("background-color: red; color: white; font-size: 16px;")
```

詳しくは[`sanitize_css`][] APIドキュメントを参照してください。

[`sanitize_css`]: https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html#method-i-sanitize_css

### `strip_links`

テキストに含まれるリンクタグを削除し、リンクテキストだけを残します。

```ruby
strip_links("<a href='https://rubyonrails.org'>Ruby on Rails</a>")
# => Ruby on Rails

strip_links("emails to <a href='mailto:me@email.com'>me@email.com</a>.")
# => emails to me@email.com.

strip_links("Blog: <a href='http://myblog.com/'>Visit</a>.")
# => Blog: Visit.
```

詳しくは[`strip_links`][] APIドキュメントを参照してください。

[`strip_links`]: https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html#method-i-strip_links

### `strip_tags`

HTMLからすべてのHTMLタグを削除します（コメントも削除されます）。
この機能は[rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer) gemによるものです。

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!

strip_tags("<b>Bold</b> no more! <a href='more.html'>See more</a>")
# => Bold no more! See more

strip_links('<<a href="https://example.org">malformed & link</a>')
# => &lt;malformed &amp; link
```

詳しくは[`strip_tags`][] APIドキュメントを参照してください。

[`strip_tags`]: https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html#method-i-strip_tags

アセットヘルパー
-------------

アセットヘルパーは、ビューから「画像」「JavaScriptファイル」「スタイルシート（CSS）」「フィード」などのアセットにリンクするHTMLを生成する一連のヘルパーメソッドを提供します。

デフォルトでは、現在のホストの`public/`フォルダにあるアセットにリンクされますが、アプリケーション設定の[`config.asset_host`][]を設定すれば、アセット専用サーバー上にあるアセットに直接リンクできます（この設定は、通常`config/environments/production.rb`に記述します）。

たとえば、アセットが`assets.example.com`というホストに置かれている場合は、以下のように設定します。

```ruby
config.asset_host = "assets.example.com"
```

これで、設定に対応するURLが`image_tag`で生成されるようになります。

```ruby
image_tag("rails.png")
# => <img src="//assets.example.com/images/rails.png" />
```

[`config.asset_host`]: configuring.html#config-asset-host

### `audio_tag`

単独のソースURL文字列を渡すと単一の`src`タグを含むHTML `audio`タグを生成し、複数のソースURL文字列を渡すと複数の`src`タグを含む`audio`タグを生成します。`sources`オプションには、フルパス、公開しているオーディオディレクトリ内のファイル、または[Active Storage の添付ファイル](active_storage_overview.html)を指定できます。

```ruby
audio_tag("sound")
# => <audio src="/audios/sound"></audio>

audio_tag("sound.wav", "sound.mid")
# => <audio><source src="/audios/sound.wav" /><source src="/audios/sound.mid" /></audio>

audio_tag("sound", controls: true)
# => <audio controls="controls" src="/audios/sound"></audio>
```

INFO: `audio_tag`の内部では、[`AssetUrlHelper`の`audio_path`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html#method-i-audio_path)を用いてオーディオファイルへのパスをビルドしています。

詳しくは[`audio_tag`][] APIドキュメントを参照してください。

[`audio_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-audio_tag

### `auto_discovery_link_tag`

ブラウザやRSSフィードリーダーが「RSS」「Atom」または「JSON」フィードを自動検出するときに利用可能なリンクタグを返します。

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", { title: "RSS Feed" })
# => <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed.rss" />
```

詳しくは[`auto_discovery_link_tag`][] APIドキュメントを参照してください。

[`auto_discovery_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-auto_discovery_link_tag

### `favicon_link_tag`

アセットパイプラインによって管理されるファビコンのリンクタグを返します。`source`には、フルパス、またはアセットディレクトリに存在するファイルを指定できます。

```ruby
favicon_link_tag
# => <link href="/assets/favicon.ico" rel="icon" type="image/x-icon" />
```

詳しくは[`favicon_link_tag`][] APIドキュメントを参照してください。

[`favicon_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-favicon_link_tag

### `image_tag`

指定されたソースに対応するHTMLの`img`タグを返します。ソースには、フルパス、またはアプリの`app/assets/images`ディレクトリの下に存在するファイルを指定できます。

```ruby
image_tag("icon.png")
# => <img src="/assets/icon.png" />

image_tag("icon.png", size: "16x10", alt: "Edit Article")
# => <img src="/assets/icon.png" width="16" height="10" alt="Edit Article" />
```

INFO: `image_tag`の内部では、[`AssetUrlHelper`の`image_path`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html#method-i-image_path)を用いて画像ファイルへのパスをビルドしています。

詳しくは[`image_tag`][] APIドキュメントを参照してください。

[`image_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-image_tag

### `javascript_include_tag`

指定されたソースごとにHTMLの`script`タグを返します。`app/assets/javascripts`ディレクトリの下に存在するJavaScriptファイル名（拡張子`.js`はオプションなので指定しなくてもよい）を渡すことも、ドキュメントルートからの相対的な完全パスを渡すことも可能です。

```ruby
javascript_include_tag("common")
# => <script src="/assets/common.js"></script>

javascript_include_tag("common", async: true)
# => <script src="/assets/common.js" async="async"></script>
```

`async`や`defer`などがオプションとしてよく指定されます。`async: true`を指定すると、ドキュメントと並行してスクリプトファイルを読み込むことでスクリプトをできるだけ早い段階で解析して評価します。`defer: true`を指定すると、ドキュメントの解析後にスクリプトを実行するようブラウザに指示します。

INFO: `javascript_include_tag`の内部では、[`AssetUrlHelper`の`javascript_path`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html#method-i-javascript_path)を用いてスクリプトファイルへのパスをビルドしています。

詳しくは[`javascript_include_tag`][] APIドキュメントを参照してください。

[`javascript_include_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-javascript_include_tag

### `picture_tag`

ソースに対応するHTMLの`<picture>`タグを返します。String、Array、またはブロックを渡せます。

```ruby
picture_tag("icon.webp", "icon.png")
```

上のコードは以下のHTMLを生成します。

```html
<picture>
  <source srcset="/assets/icon.webp" type="image/webp" />
  <source srcset="/assets/icon.png" type="image/png" />
  <img src="/assets/icon.png" />
</picture>
```

詳しくは[`picture_tag`][] APIドキュメントを参照してください。

[`picture_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-picture_tag

### `preload_link_tag`

ブラウザでソースをプリロードさせるのに利用できるHTML `link`タグを返します。指定できるソースは、アセットパイプラインによって管理されるリソースパス、フルパス、またはURIです。

```ruby
preload_link_tag("application.css")
# => <link rel="preload" href="/assets/application.css" as="style" type="text/css" />
```

詳しくは[`preload_link_tag`][] APIドキュメントを参照してください。

[`preload_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-preload_link_tag

### `stylesheet_link_tag`

引数で指定したソースに対応するスタイルシート用リンクタグを返します。拡張子が指定されていない場合は、自動的に`.css`が追加されます。

```ruby
stylesheet_link_tag("application")
# => <link href="/assets/application.css" rel="stylesheet" />

stylesheet_link_tag("application", media: "all")
# => <link href="/assets/application.css" media="all" rel="stylesheet" />
```

`media`オプションは、リンクのメディアタイプを指定するのに使われます。最もよく使われるメディアタイプは`all`、`screen`、`print`、`speech`です。

INFO: `stylesheet_link_tag`の内部では、[`AssetUrlHelper`の`stylesheet_path`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html#method-i-stylesheet_path)を用いてスタイルシートへのパスをビルドしています。

詳しくは[`stylesheet_link_tag`][] APIドキュメントを参照してください。

[`stylesheet_link_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-stylesheet_link_tag

### `video_tag`

単独のソースURL文字列を渡すと単一の`src`タグを含むHTML `video`タグを生成し、複数のソースURL文字列を渡すと複数の`src`タグを含む`video`タグを生成します。`sources`オプションには、フルパス、公開している動画ディレクトリ内のファイル、または[Active Storage の添付ファイル](active_storage_overview.html)を指定できます。

```ruby
video_tag("trailer")
# => <video src="/videos/trailer"></video>

video_tag(["trailer.ogg", "trailer.flv"])
# => <video><source src="/videos/trailer.ogg" /><source src="/videos/trailer.flv" /></video>

video_tag("trailer", controls: true)
# => <video controls="controls" src="/videos/trailer"></video>
```

INFO: `video_tag`の内部では、[`AssetUrlHelper`の`video_path`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html#method-i-video_path)を用いて動画ファイルへのパスをビルドしています。

詳しくは[`video_tag`][] APIドキュメントを参照してください。

[`video_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-video_tag

JavaScriptヘルパー
-----------------

ビューでJavaScriptを利用するための機能を提供する一連のヘルパーメソッドです。

### `escape_javascript`

JavaScriptセグメントでキャリッジリターンや一重引用符や二重引用符をエスケープします。ブラウザが解析するときに無効な文字が含まれないようにしたいときは、このヘルパーメソッドにテキストの文字列を渡します。

たとえば、二重引用符が挨拶文に含まれている以下のようなパーシャルをJavaScriptのアラートボックスで表示したい場合は、以下のように書くことで二重引用符をエスケープできます。

```html+erb
<%# app/views/users/greeting.html.rb %>
My name is <%= current_user.name %>, and I'm here to say "Welcome to our website!"
```

```html+erb
<script>
  var greeting = "<%= escape_javascript render('users/greeting') %>";
  alert(`Hello, ${greeting}`);
</script>
```

これで、二重引用符が正しくエスケープされ、アラートボックスに挨拶文が表示されます。

詳しくは[`escape_javascript`][] APIドキュメントを参照してください。

[`escape_javascript`]: https://api.rubyonrails.org/classes/ActionView/Helpers/JavaScriptHelper.html#method-i-escape_javascript

### `javascript_tag`

渡されたコードをJavaScriptタグでラップして返します。オプションをハッシュ形式で渡すことで、`<script>`タグの振る舞いを制御できます。

```ruby
javascript_tag("alert('All is good')", type: "application/javascript")
```

```html
<script type="application/javascript">
//<![CDATA[
alert('All is good')
//]]>
</script>
```

コンテンツを引数に渡す代わりに、以下のようにブロックで渡すことも可能です。

```html+erb
<%= javascript_tag type: "application/javascript" do %>
  alert("Welcome to my app!")
<% end %>
```

詳しくは[`javascript_tag`][] APIドキュメントを参照してください。

[`javascript_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/JavaScriptHelper.html#method-i-javascript_tag

タグ生成ヘルパー
----------------

HTMLタグをプログラム的に生成するための一連のヘルパーメソッドです。

### `tag`

HTMLタグ名やオプションを指定してHTMLタグを生成します。

以下の書式であらゆるHTMLタグを生成できます。`

```ruby
tag.タグ名(追加コンテンツ, オプション)
```

`br`、`div`、`section`、`article`など任意のタグ名を指定できます。

以下はよく使われる例です。

```ruby
tag.h1 "All titles fit to print"
# => <h1>All titles fit to print</h1>

tag.div "Hello, world!"
# => <div>Hello, world!</div>
```

また、生成するタグには以下のようにオプションで属性も指定できます。

```ruby
tag.section class: %w( kitties puppies )
# => <section class="kitties puppies"></section>
```

さらに、`tag`ヘルパーに`data`オプションを指定するときは、サブ属性のキーバリューペアを含むハッシュを渡すことでHTMLの`data-*`属性を複数追加できます。JavaScriptで適切に動作させるため、指定したサブ属性名に含まれるアンダースコア`_`を以下のように`-`に置き換えてから`data-*`属性に変換します。

```ruby
tag.div data: { user_id: 123 }
# => <div data-user-id="123"></div>
```

詳しくは[`tag`][] APIドキュメントを参照してください（訳注: `tag`ヘルパーで生成されるタグはHTML5に準拠しており、閉じタグの自動追加やコンテンツのブロック渡しなどもサポートしています）。

[`tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-tag

### `token_list`

引数で渡したトークンをスペース区切りの文字列にして返します。このヘルパーメソッドは、CSSクラス名を生成する`class_names`メソッドのエイリアスです。

```ruby
token_list("cats", "dogs")
# => "cats dogs"

token_list(nil, false, 123, "", "foo", { bar: true })
# => "123 foo bar"

mobile, alignment = true, "center"
token_list("flex items-#{alignment}", "flex-col": mobile)
# => "flex items-center flex-col"
class_names("flex items-#{alignment}", "flex-col": mobile) # エイリアス
# => "flex items-center flex-col"
```

ブロックをキャプチャする
--------------------

生成されるマークアップの一部を抽出して、テンプレートやレイアウトファイルで他の部分で利用可能にする一連のヘルパーメソッドです。

マークアップのブロックを変数にキャプチャする`capture`メソッドと、マークアップのブロックをキャプチャしてレイアウトで利用可能にする`content_for`メソッドが提供されています。

### `capture`

`capture`メソッドを使うと、以下のようにテンプレートの一部を抽出して変数にキャプチャできます。

```html+erb
<% @greeting = capture do %>
  <p>Welcome to my shiny new web page! The date and time is <%= Time.current %></p>
<% end %>
```

この`@greeting`変数は、任意のテンプレートやレイアウトやヘルパーで利用可能になります。

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

キャプチャの戻り値は、そのブロックによって生成された文字列になります。

``` ruby
@greeting
# => "Welcome to my shiny new web page! The date and time is 2018-09-06 11:09:16 -0500"
```

詳しくは[`capture`][] APIドキュメントを参照してください。

[`capture`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#method-i-capture

### `content_for`

`content_for`を呼び出すとマークアップのブロックが識別子に保存され、この識別子を後で利用可能になります。他のテンプレートやヘルパーモジュールやレイアウトで`yield`にこの識別子を引数として渡すことで、識別子に保存されているコンテンツを以後呼び出せるようになります。

`content_for`は、`content_for`ブロックでページのタイトルを設定するときによく使われます。

`content_for`ブロックを以下のように`special_page.html.erb`ビューで定義しておいてから、それをレイアウト内で`yield`する形で利用すると、`content_for`ブロックを利用しない他のページでは`content_for`ブロックが生成されないようになります。

```html+erb
<%# app/views/users/special_page.html.erb %>
<% content_for(:html_title) { "Special Page Title" } %>
```

```html+erb
<%# app/views/layouts/application.html.erb %>
<html>
  <head>
    <title><%= content_for?(:html_title) ? yield(:html_title) : "Default Title" %></title>
  </head>
</html>
```

上記の例では、`content_for?`述語メソッドを利用してタイトルを条件付きでレンダリングしていることがわかります。このメソッドは、コンテンツが`content_for`でキャプチャ済みかどうかをチェックして、ビューのコンテンツに応じてレイアウトの一部を調整しています。

さらに、`content_for`は以下のようにヘルパーモジュール内でも利用できます。

```ruby
# app/helpers/title_helper.rb
module TitleHelper
  def html_title
    content_for(:html_title) || "Default Title"
  end
end
```

これで、レイアウト内で`html_title`を呼び出せば、`content_for`ブロックに保存されたコンテンツを取得できるようになります。`special_page`の場合のように、レンダリングされるページで`content_for`ブロックが設定されている場合はタイトルが表示され、`content_for`ブロックが設定されていない場合は、デフォルトの"Default Title"テキストが表示されます。

WARNING: `content_for`はキャッシュ内では無視されるので、フラグメントキャッシュされる要素では`content_for`を使わないでください。

NOTE: `capture`と`content_for`の違いでお悩みの方へ。<br><br>
`capture`はマークアップのブロックを変数にキャプチャするために使われ、`content_for`は、マークアップのブロックを識別子に保存して後で利用可能にするの使われます（`content_for`は実際には内部で`capture`を呼び出しています）。ただし両者の大きな違いは、複数回呼び出されたときの振る舞いにあります。<br><br>
`content_for`は繰り返し呼び出すことが可能であり、特定の識別子用に受け取ったブロックを提供された順序で連結します。以後の個別の呼び出しは、既に保存済みのコンテンツに追加するだけで。 対照的に、`capture`はブロックのコンテンツのみを返すだけで、以前の呼び出しをトラッキングしません。

詳しくは[`content_for`][] APIドキュメントを参照してください。

[`content_for`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#method-i-content_for

パフォーマンス測定ヘルパー
----------------------

### `benchmark`

コストの高い操作やボトルネックの可能性がある操作を`benchmark`ブロックで囲むことでパフォーマンスを測定できます。

```html+erb
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

これによってログに`Process data files (0.34523)`のような出力が追加されるので、コードを最適化するときにタイミングを比較できるようになります。

NOTE: `benchmark`はActive Supportのメソッドなので、コントローラやヘルパーやモデルでも利用できます。

詳しくは[`benchmark`][] APIドキュメントを参照してください。

[`benchmark`]: https://api.rubyonrails.org/classes/ActiveSupport/Benchmarkable.html#method-i-benchmark

### `cache`

アクションやページ全体をキャッシュする代わりに、フラグメントキャッシュでビューの一部をキャッシュできます。フラグメントキャッシュは、メニュー、ニューストピックのリスト、静的なHTMLの断片といった小さな部分をキャッシュするのに有用です。これにより、キャッシュブロックで囲んだビューロジックのフラグメントが、次のリクエストが到着したときにキャッシュストアから配信されるようになります。

`cache`メソッドは、キャッシュしたいコンテンツをブロックとして受け取ります。

たとえば、アプリケーションレイアウトのフッターをキャッシュするには、以下のように`cache`ブロックでフッターを囲みます。

```erb
<% cache do %>
  <%= render "application/footer" %>
<% end %>
```

モデルのインスタンスに基づいてキャッシュすることも可能です。たとえば、以下のように`cache`メソッドに`article`オブジェクトを渡すと、ページ上の個別の記事をキャッシュして、記事単位でキャッシュするようになります。

```erb
<% @articles.each do |article| %>
  <% cache article do %>
    <%= render article %>
  <% end %>
<% end %>
```

アプリケーションがこのページへの最初のリクエストを受け取ると、以下のような一意のキーを持つ新しいキャッシュエントリがRailsによって書き込まれます。

```irb
views/articles/index:bea67108094918eeba32cd4a6f786301/articles/1
```

詳しくは、[フラグメントキャッシュ](caching_with_rails.html#フラグメントキャッシュ)ガイドや[`cache`][] APIドキュメントを参照してください。

[`cache`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CacheHelper.html#method-i-cache

その他のヘルパー
-------------

### `atom_feed`

Atomフィードは、コンテンツの配信に使われるXMLベースのファイル形式で、ユーザーがフィードリーダーアプリでコンテンツを参照したり、検索エンジンでサイトに関する追加情報を検索したりするのに利用されます。

`atom_feed`ヘルパーを利用することで、Atomフィードを手軽に構築可能になります。主な利用場所はXMLを作成するBuilderテンプレートです。完全な利用例は以下のとおりです。

```ruby
# config/routes.rb
resources :articles
```

```ruby
# app/controllers/articles_controller.rb
def index
  @articles = Article.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

```ruby
# app/views/articles/index.atom.builder
atom_feed do |feed|
  feed.title("Articles Index")
  feed.updated(@articles.first.created_at)

  @articles.each do |article|
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(article.body, type: "html")

      entry.author do |author|
        author.name(article.author_name)
      end
    end
  end
end
```

詳しくは[`atom_feed`][] APIドキュメントを参照してください。

[`atom_feed`]: https://api.rubyonrails.org/classes/ActionView/Helpers/AtomFeedHelper.html#method-i-atom_feed

### `debug`

オブジェクトのYAML表現を`pre`タグで囲んで返します。これにより、オブジェクトを非常に読みやすい形で調べられるようになります。

```ruby
my_hash = { "first" => 1, "second" => "two", "third" => [1, 2, 3] }
debug(my_hash)
```

```html
<pre class="debug_dump">---
first: 1
second: two
third:
- 1
- 2
- 3
</pre>
```

詳しくは[`debug`][] APIドキュメントを参照してください。

[`debug`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DebugHelper.html#method-i-debug
