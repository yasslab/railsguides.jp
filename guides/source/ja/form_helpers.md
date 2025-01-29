**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Action View フォームヘルパー
============

Webアプリケーションのフォームは、ユーザー入力を扱うための重要なインターフェイスです。しかしフォームのマークアップは、フォームのコントロールの命名法や大量の属性を扱わなければならず、作成もメンテナンスも退屈な作業になりがちです。そこでRailsでは、フォームのマークアップを生成するビューヘルパーを提供し、こうした煩雑な作業を行わずに済むようにしました。しかし現実にはさまざまなユースケースがあるため、開発者はこれらを実際に使う前に、これらのよく似たヘルパーメソッド群にどのような違いがあるのかをすべて把握しておく必要があります。

このガイドの内容:

* 検索フォーム、および特定のモデルを表さない一般的なフォームの作成法
* 特定のデータベースレコードの作成編集を行なう、モデル中心のフォーム作成法
* 複数の種類のデータからセレクトボックスを生成する方法
* Railsが提供する日付時刻関連ヘルパー
* ファイルアップロード用フォームの動作を変更する方法
* 外部リソース向けにフォームを作成する方法と`authenticity_token`を設定する方法
* 複雑なフォームの作成方法

--------------------------------------------------------------------------------


NOTE: このガイドはフォームヘルパーとその引数について網羅的に説明するものではありません。完全なリファレンスについては[Rails APIドキュメント](https://api.rubyonrails.org/)を参照してください。


基本的なフォームを作成する
------------------------

最も基本的なフォームヘルパーは[`form_with`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with)です。

```erb
<%= form_with do |form| %>
  Form contents
<% end %>
```

上のように`form_with`を引数なしで呼び出すと、`<form>`タグを生成します。このフォームを現在のページに送信するときにHTTP POSTメソッドが使われます。たとえば現在のページがhomeページの場合、以下のようなHTMLが生成されます。

```html
<form accept-charset="UTF-8" action="/" method="post">
  <input name="authenticity_token" type="hidden" value="J7CBxfHalt49OSHp27hblqK20c9PgwJ108nDHX/8Cts=" />
  Form contents
</form>
```

上のHTMLでは、`input`要素に`type=hidden`が指定されていることがわかります。GET以外のフォームは`input`がないと正常に送信できないので、この`input`は重要です。
`authenticity_token`という名前の隠し`input`要素は、**クロスサイトリクエストフォージェリ（CSRF）保護** と呼ばれるRailsのセキュリティ機能です。フォームヘルパーは、GET以外のフォームでこのトークンを生成します（CSRF保護が有効な場合）。詳しくはは[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ-csrf)を参照してください。

### 一般的な検索フォーム

検索フォームはWebでよく使われています。検索フォームには以下のものが含まれています。

* GETメソッドを送信するためのフォーム要素
* 入力するものを示すラベル
* テキスト入力要素
* 送信ボタン要素

この検索フォームの作成には、以下のように、`form_with`とその中で生成されるフォームビルダーオブジェクトを使います。

```erb
<%= form_with url: "/search", method: :get do |form| %>
  <%= form.label :query, "Search for:" %>
  <%= form.text_field :query %>
  <%= form.submit "Search" %>
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form action="/search" method="get" accept-charset="UTF-8" >
  <label for="query">Search for:</label>
  <input id="query" name="query" type="text" />
  <input name="commit" type="submit" value="Search" data-disable-with="Search" />
</form>
```

TIP: `form_with`に`url: my_specified_path`を渡すと、リクエストの送信先をフォームで指定できるようになります。しかし後述するように、フォームにActive Recordオブジェクトを渡すことも可能です。

TIP: すべてのフォーム入力の`id`属性は、`name`属性から生成されます（上の例では"query"）。この`id`属性は、CSSでスタイルを設定するときや、JavaScriptでフォームを操作するときに非常に便利です。

IMPORTANT: GETメソッドは検索フォームでお使いください。こうすることで検索クエリがURLの一部に含まれ、ユーザーが検索結果をブックマークしておけば、後で同じ検索をブックマークから実行できるようになります。Railsでは基本的に、常にアクションに対応する適切なHTTPメソッド（verb）を選んでください（訳注: [セキュリティガイド](security.html#csrfへの対応策)にも記載されているように、たとえば更新フォームでGETメソッドを使うと重大なセキュリティホールが生じる可能性があります）。

### フォーム要素を生成するヘルパー

`form_with`で生成するフォームビルダーオブジェクトは、テキストフィールド/チェックボックス/ラジオボタンなどのフォーム要素を生成するヘルパーメソッドを多数提供します。
これらのヘルパーメソッドに渡す第1パラメータには、常にinputの名前を指定します。
フォームが送信されると、フォームデータとともにこの名前も渡され、ユーザーがフィールドに入力した値とともにコントローラの`params`に送られます。たとえばフォームに`<%= form.text_field :query %>`があると、コントローラ側で`params[:query]`と書くことでこのフィールドの値を取り出せるようになります。

Railsでは、inputに名前を与えるときに特定の規約を利用します。これにより、配列やハッシュのような「非スカラー値」のパラメータをフォームから送信できるようになり、コントローラでも`params`にアクセス可能になりますこれらの命名規約について詳しくは、本ガイドで後述する「[パラメータの命名ルールを理解する](#パラメータの命名ルールを理解する)」を参照してください。これらのヘルパーの具体的な利用法について詳しくは[`ActionView::Helpers::FormTagHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html) APIドキュメントを参照してください。

#### チェックボックス

チェックボックスはフォームコントロールの一種で、ユーザーがオプションをオンまたはオフにできるようにします。

```erb
<%= form.check_box :pet_dog %>
<%= form.label :pet_dog, "I own a dog" %>
<%= form.check_box :pet_cat %>
<%= form.label :pet_cat, "I own a cat" %>
```

上のコードによって以下が生成されます。

```html
<input type="checkbox" id="pet_dog" name="pet_dog" value="1" />
<label for="pet_dog">I own a dog</label>
<input type="checkbox" id="pet_cat" name="pet_cat" value="1" />
<label for="pet_cat">I own a cat</label>
```

[`check_box`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box)の第1パラメータはinputの名前です。第2パラメータはinput要素の`value`属性を指定します。チェックボックスをオンにすると、この値がフォームデータに含まれ、最終的に`params`に渡されます。

#### ラジオボタン

チェックボックスと同様、ラジオボタンも一連のオプションをユーザーが選択できますが、一度に1つの項目しか選択できない排他的な動作が特徴です。

```erb
<%= form.radio_button :age, "child" %>
<%= form.label :age_child, "I am younger than 21" %>
<%= form.radio_button :age, "adult" %>
<%= form.label :age_adult, "I am over 21" %>
```

出力は以下のようになります。

```html
<input type="radio" id="age_child" name="age" value="child" />
<label for="age_child">I am younger than 21</label>
<input type="radio" id="age_adult" name="age" value="adult" />
<label for="age_adult">I am over 21</label>
```

`check_box`ヘルパーのときと同様、[`radio_button`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button)の第2パラメータはinput要素の`value`属性を指定します。2つのラジオボタン項目は同じ名前（'age'）を共有しているので、ユーザーは一方の値だけを選択できます。そして`params[:age]`の値は"child"と"adult"のいずれかになります。

NOTE: チェックボックスとラジオボタンには必ずラベルを表示してください。ラベルを表示することで、そのオプションとラベルの名前が関連付けられるだけでなく、ラベルの部分もクリック可能になるのでユーザーの操作性が向上します。

### その他のヘルパー

これまで紹介した他にも、以下の「テキストエリア」「隠しフィールド」「パスワードフィールド」「数値フィールド」「日付時刻フィールド」など多くのフォームコントロールがあります。

```erb
<%= form.text_area :message, size: "70x5" %>
<%= form.hidden_field :parent_id, value: "foo" %>
<%= form.password_field :password %>
<%= form.number_field :price, in: 1.0..20.0, step: 0.5 %>
<%= form.range_field :discount, in: 1..100 %>
<%= form.date_field :born_on %>
<%= form.time_field :started_at %>
<%= form.datetime_local_field :graduation_day %>
<%= form.month_field :birthday_month %>
<%= form.week_field :birthday_week %>
<%= form.search_field :name %>
<%= form.email_field :address %>
<%= form.telephone_field :phone %>
<%= form.url_field :homepage %>
<%= form.color_field :favorite_color %>
```

上の出力は以下のようになります。

```html
<textarea name="message" id="message" cols="70" rows="5"></textarea>
<input type="hidden" name="parent_id" id="parent_id" value="foo" />
<input type="password" name="password" id="password" />
<input type="number" name="price" id="price" step="0.5" min="1.0" max="20.0" />
<input type="range" name="discount" id="discount" min="1" max="100" />
<input type="date" name="born_on" id="born_on" />
<input type="time" name="started_at" id="started_at" />
<input type="datetime-local" name="graduation_day" id="graduation_day" />
<input type="month" name="birthday_month" id="birthday_month" />
<input type="week" name="birthday_week" id="birthday_week" />
<input type="search" name="name" id="name" />
<input type="email" name="address" id="address" />
<input type="tel" name="phone" id="phone" />
<input type="url" name="homepage" id="homepage" />
<input type="color" name="favorite_color" id="favorite_color" value="#000000" />
```

隠しinputはユーザーには表示されず、種類を問わず事前に与えられた値を保持します。隠しフィールドに含まれている値はJavaScriptで変更できます。

IMPORTANT: 「検索」「電話番号」「日付」「時刻」「色」「日時」「ローカル日時」「月」「週」「URL」「メールアドレス」「数値」「範囲」フィールドは、HTML5から利用可能になったコントロールです。
これらのフィールドを古いブラウザでも同じように扱いたい場合は、CSSやJavaScriptを用いるHTML5ポリフィルが必要になるでしょう。
古いブラウザでHTML5に対応する方法は[山ほどあります](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills)が、現時点で代表的なものは[Modernizr](https://modernizr.com/)でしょう。これらは、HTML5の新機能が使われていることを検出すると、機能を追加するためのシンプルな方法を提供します。

TIP: パスワード入力フィールドを使っている場合は、入力されたパスワードをRailsのログに残さないようにするとよいでしょう。方法については[セキュリティガイド](security.html#ログ出力)を参照してください。

モデルオブジェクトを扱う
--------------------------

### モデルオブジェクトヘルパー

### フォームをオブジェクトに結び付ける

`form_with`の`:model`引数を使うと、フォームビルダーオブジェクトをモデルオブジェクトに紐付けできるようになります。つまり、フォームはそのモデルオブジェクトを対象とし、そのモデルオブジェクトの値がフォームのフィールドに自動入力されるようになります。

たとえば、以下のような`@article`というモデルオブジェクトがあるとします。

```ruby
@article = Article.find(42)
# => #<Article id: 42, title: "My Title", body: "My Body">
```

以下はそのフォームです。

```erb
<%= form_with model: @article do |form| %>
  <%= form.text_field :title %>
  <%= form.text_area :body, size: "60x10" %>
  <%= form.submit %>
<% end %>
```

HTML出力は以下のようになります。

```html
<form action="/articles/42" method="post" accept-charset="UTF-8" >
  <input name="authenticity_token" type="hidden" value="..." />
  <input type="text" name="article[title]" id="article_title" value="My Title" />
  <textarea name="article[body]" id="article_body" cols="60" rows="10">
    My Body
  </textarea>
  <input type="submit" name="commit" value="Update Article" data-disable-with="Update Article">
</form>
```

上では以下のようにさまざまなことが行われています。

* フォームの`action`には、`@article`に適した値が自動入力されている。
* フォームのフィールドには、`@article`にある値が自動入力されている。
* フォームのフィールド名は、`article[...]`という形でスコープされている。これは、`params[:article]`がすべてのフィールドの値を含むハッシュになるということです。input名について詳しくは、本ガイドで後述する「[パラメータの命名ルールを理解する](#パラメータの命名ルールを理解する)」を参照してください。
* 送信ボタンに自動的に適切なテキスト値が与えられている。

TIP: 通常、inputにはモデルの属性が反映されます。しかしこれは必須ではありません。フォームに他の情報を含めたい場合は、属性と同じようにフォームに含めれば`params[:article][:my_nifty_non_attribute_input]`でアクセスできるようになります。

#### `fields_for`ヘルパー

[`fields_for`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-fields_for)ヘルパーを使えば、`<form>`タグを実際に作成せずにフォームとオブジェクトを同様に紐付けできます。これは、同じフォームで別のモデルオブジェクトも編集可能にしたいときに便利です。たとえば、`Person`モデルと、それに関連付けられる`ContactDetail`モデルがある場合は、以下のようにフォームを作成できます。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for :contact_detail, @person.contact_detail do |contact_detail_form| %>
    <%= contact_detail_form.text_field :phone_number %>
  <% end %>
<% end %>
```

上のコードから以下のHTML出力が得られます。

```html
<form action="/people" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="bL13x72pldyDD8bgtkjKQakJCpd4A8JdXGbfksxBDHdf1uC0kCMqe2tvVdUYfidJt0fj3ihC4NxiVHv8GVYxJA==" />
  <input type="text" name="person[name]" id="person_name" />
  <input type="text" name="contact_detail[phone_number]" id="contact_detail_phone_number" />
</form>
```

`fields_for`で生成されるオブジェクトは、`form_with`で生成されるのと同様のフォームビルダーです。

### レコード識別を利用する

これでアプリケーションのユーザーがArticleモデルを直接操作できるようになりました。Rails開発では、次にこれをルーティングで**リソース** として宣言するのがベストプラクティスです。

```ruby
resources :articles
```

TIP: リソースを宣言すると、他にも多くの設定が自動的に行われます。リソースの設定方法について詳しくは、[Railsルーティングガイド](routing.html#リソースベースのルーティング-railsのデフォルト)を参照してください。

RESTfulなリソースを扱っている場合、レコード識別（record identification）を使うと`form_with`の呼び出しがはるかに簡単になります。これは、モデルのインスタンスを渡すだけで、後はRailsがそこからモデル名など必要なものを取り出して処理してくれるというものです。

```ruby
## 新しい記事の作成
# 長いバージョン
form_with(model: @article, url: articles_path)
# 短いバージョン（レコード識別を利用）
form_with(model: @article)

## 既存の記事の編集
# 長いバージョン
form_with(model: @article, url: article_path(@article), method: "patch")
# 短いバージョン（レコード識別を利用）
form_with(model: @article)
```

この短い`form_with`呼び出しは、レコードの作成・編集のどちらでもまったく同じです。これがどれほど便利であるかおわかりいただけると思います。レコード識別は、レコードが新しいかどうかを`record.persisted?`で識別します。さらに送信用の正しいパスを選択し、オブジェクトのクラスに基づいた名前も選択してくれます。

[単数形リソース](routing.html#単数形リソース)を使う場合は、`form_with`が機能するために以下のように`resource`と`resolve`を呼び出す必要があります。

```ruby
resource :geocoder
resolve('Geocoder') { [:geocoder] }
```

WARNING: モデルで単一テーブル継承（STI: single-table inheritance）を使っている場合、親クラスがリソースを宣言されていてもサブクラスでレコード識別を利用できません。その場合は`:url`と`:scope`（モデル名）を明示的に指定する必要があります。

#### 名前空間を扱う

名前空間付きのルーティングを作成してある場合、`form_with`でもこれを利用した簡潔な表記を利用できます。アプリケーションのルーティングでadmin名前空間が設定されているとします。

```ruby
form_with model: [:admin, @article]
```

上のコードはそれによって、admin名前空間内にある`ArticlesController`に送信するフォームを作成します（たとえば更新の場合は`admin_article_path(@article)`に送信されます）。名前空間の階層が複数ある場合にも同様の文法が使えます。

```ruby
form_with model: [:admin, :management, @article]
```

Railsのルーティングシステムおよび関連するルールについて詳しくは[ルーティングガイド](routing.html)を参照してください。

### フォームにおけるPATCH・PUT・DELETEメソッドの動作

Railsのフレームワークは、開発者がアプリケーションをRESTfulな設計で構築することを推奨しています。すなわち、開発者はGETやPOSTリクエストだけでなく、PATCHやDELETEリクエストを多数作成・送信することになります。しかし、現実のブラウザの多くはフォーム送信時にGETとPOST以外のHTTPメソッドを**サポートしていません**。

そこでRailsでは、POSTメソッド上でこれらのメソッドをエミュレートすることによってこの問題を解決しています。具体的には、`"_method"`という名前の隠し入力をフォームに用意し、使いたいメソッドをここで指定します。

```ruby
form_with(url: search_path, method: "patch")
```

上のコードから以下の出力が得られます。

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  <!-- ... -->
</form>
```

Railsは、POSTされたデータを解析する際にこの特殊な`_method`パラメータをチェックし、ここで指定されているメソッド(この場合はPATCH)があたかも実際にHTTPメソッドとして指定されたかのように振る舞います。

`formmethod:`キーワードを指定すると、フォームをレンダリングするときに送信ボタンが指定の`method`属性をオーバーライドできるようになります。

```erb
<%= form_with url: "/posts/1", method: :patch do |form| %>
  <%= form.button "Delete", formmethod: :delete, data: { confirm: "Are you sure?" } %>
  <%= form.button "Update" %>
<% end %>
```

`<form>`要素の場合と同様、ほとんどのブラウザは[`formmethod`][]で宣言されるGETとPOST以外のフォームメソッドを**サポートしていません**。

Railsでは、POSTメソッド上でこれらのメソッドをエミュレートすることによってこの問題を解決しています。具体的には、[`formmethod`][]、[`value`][button-value]、[`name`][button-name]属性を組み合わせることでエミュレートします。

```html
<form accept-charset="UTF-8" action="/posts/1" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  <!-- ... -->

  <button type="submit" formmethod="post" name="_method" value="delete" data-confirm="Are you sure?">Delete</button>
  <button type="submit" name="button">Update</button>
</form>
```

IMPORTANT: Rails 6.0および5.2では、`form_with`を使うすべてのフォームはデフォルトで`remote: true`を実装します。これらのフォームではXHR（Ajax）リクエストを使ってデータを送信します。これを無効にするには、`local: true`を指定してください。詳しくは[Rails で JavaScript を使用する](working_with_javascript_in_rails.html#remote要素をカスタマイズする)ガイドを参照してください。

[`formmethod`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-formmethod
[button-name]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-name
[button-value]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-value

セレクトボックスを簡単に作成する
-----------------------------

HTMLでセレクトボックスを作成するには大量のマークアップを書かなくてはなりません（選択するオプションごとに1つの<option>`要素が対応します）。そこでRailsでは、こうした作業を軽減するヘルパーメソッドを提供しています。

たとえば、ユーザーに選択して欲しい都市名のリストがあるとします。[`select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-select)ヘルパーを使うと以下のようにセレクトボックスを作成できます。

```erb
<%= form.select :city, ["Berlin", "Chicago", "Madrid"] %>
```

上のコードで以下のHTMLが出力されます。

```html
<select name="city" id="city">
  <option value="Berlin">Berlin</option>
  <option value="Chicago">Chicago</option>
  <option value="Madrid">Madrid</option>
</select>
```

以下のようにセレクトボックスの表示名と別の`<option>`値を指定することも可能です。

```erb
<%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]] %>
```

上のコードで以下のHTMLが出力されます。

```html
<select name="city" id="city">
  <option value="BE">Berlin</option>
  <option value="CHI">Chicago</option>
  <option value="MD">Madrid</option>
</select>
```

こうすることで、ユーザーには完全な都市名が表示されますが、`params[:city]`は`"BE"`、`"CHI"`、`"MD"`のいずれかの値になります。

最後に、`:selected`引数を使うとセレクトボックスのデフォルト値も指定できます。

```erb
<%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]], selected: "CHI" %>
```

上のコードで以下のHTMLが出力されます。

```html
<select name="city" id="city">
  <option value="BE">Berlin</option>
  <option value="CHI" selected="selected">Chicago</option>
  <option value="MD">Madrid</option>
</select>
```

### オプショングループ

場合によっては、関連するオプションをグループ化してユーザーエクスペリエンスを向上させたいことがあります。これは、以下のように`select`に`Hash`（または同等の`Array`）を渡すことで行なえます。

```erb
<%= form.select :city,
      {
        "Europe" => [ ["Berlin", "BE"], ["Madrid", "MD"] ],
        "North America" => [ ["Chicago", "CHI"] ],
      },
      selected: "CHI" %>
```

上のコードで以下のHTMLが出力されます。

```html
<select name="city" id="city">
  <optgroup label="Europe">
    <option value="BE">Berlin</option>
    <option value="MD">Madrid</option>
  </optgroup>
  <optgroup label="North America">
    <option value="CHI" selected="selected">Chicago</option>
  </optgroup>
</select>
```

### セレクトボックスとモデルオブジェクト

セレクトボックスも、他のフォームコントロールと同様にモデル属性に紐付け可能です。たとえば、以下の`@person`というモデルオブジェクトがあるとします。

```ruby
@person = Person.new(city: "MD")
```

以下はそのフォームです。

```erb
<%= form_with model: @person do |form| %>
  <%= form.select :city, [["Berlin", "BE"], ["Chicago", "CHI"], ["Madrid", "MD"]] %>
<% end %>
```

セレクトボックスのHTML出力は以下のようになります。

```html
<select name="person[city]" id="person_city">
  <option value="BE">Berlin</option>
  <option value="CHI">Chicago</option>
  <option value="MD" selected="selected">Madrid</option>
</select>
```

適切なオプションに`selected="selected"`が自動的に追加されている点にご注目ください。このセレクトボックスはモデルに紐付けられているので、`:selected`引数を指定する必要はありません。

### タイムゾーンと国を選択する

Railsでタイムゾーンをサポートするために、ユーザーが今どのタイムゾーンにいるのかを何らかの形でユーザーに尋ねなければなりません。そのためには、`collection_select`ヘルパーを使って、事前定義済みの[`ActiveSupport::TimeZone`](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)オブジェクトのリストからセレクトボックスを作成する必要がありますが、以下のようにその機能を既に持っている[`time_zone_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-time_zone_select)ヘルパーを使えば簡単にできます。

```erb
<%= form.time_zone_select :time_zone %>
```

**以前の**Railsには国を選択する`country_select`ヘルパーがありましたが、この機能は[country_selectプラグイン](https://github.com/stefanpenner/country_select)に切り出されました。

日付時刻フォームヘルパーを使う
--------------------------------

HTML5標準の日付/時刻入力フィールドを生成するヘルパーを使いたくない場合は、Railsにある別の日付/時刻ヘルパーを使うこともできます。Railsの日付/時刻ヘルパーは、年/月/日などの一時コンポーネントごとにセレクトボックスをレンダリングします。たとえば、以下のような`@person`というモデルオブジェクトがあるとします。

```ruby
@person = Person.new(birth_date: Date.new(1995, 12, 21))
```

以下はそのフォームです。

```erb
<%= form_with model: @person do |form| %>
  <%= form.date_select :birth_date %>
<% end %>
```

セレクトボックスのHTML出力は以下のようになります。

```html
<select name="person[birth_date(1i)]" id="person_birth_date_1i">
  <option value="1990">1990</option>
  <option value="1991">1991</option>
  <option value="1992">1992</option>
  <option value="1993">1993</option>
  <option value="1994">1994</option>
  <option value="1995" selected="selected">1995</option>
  <option value="1996">1996</option>
  <option value="1997">1997</option>
  <option value="1998">1998</option>
  <option value="1999">1999</option>
  <option value="2000">2000</option>
</select>
<select name="person[birth_date(2i)]" id="person_birth_date_2i">
  <option value="1">January</option>
  <option value="2">February</option>
  <option value="3">March</option>
  <option value="4">April</option>
  <option value="5">May</option>
  <option value="6">June</option>
  <option value="7">July</option>
  <option value="8">August</option>
  <option value="9">September</option>
  <option value="10">October</option>
  <option value="11">November</option>
  <option value="12" selected="selected">December</option>
</select>
<select name="person[birth_date(3i)]" id="person_birth_date_3i">
  <option value="1">1</option>
  ...
  <option value="21" selected="selected">21</option>
  ...
  <option value="31">31</option>
</select>
```

フォームが送信されたときの`params`ハッシュには、完全な日付を含む単一の値が存在しない点にご注目ください。代わりに、`"birth_date(1i)"`のような特殊な名前を持つ複数の値が存在します。Active Recordは、モデル属性の宣言された型に基づいて、これらの特殊な名前を持つ値を完全な日付や時刻として組み立てる方法を知っています。つまり、フォームで完全な日付を表す1個のフィールを使う場合と同じように、`params[:person]`を`Person.new`や`Person#update`などに渡せるということです。

Railsでは、[`date_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-date_select)ヘルパーの他に[`time_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-time_select)ヘルパーや[`datetime_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-datetime_select)も提供しています。

### 個別の一時コンポーネント用のセレクトボックス

Railsでは、個別の一時コンポーネント向けのセレクトボックスをレンダリングするヘルパーとして[`select_year`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_year)、[`select_month`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_month)、[`select_day`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_day)、[`select_hour`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_hour)、[`select_minute`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_minute)、[`select_second`](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_second)も提供しています。

これらのヘルパーは「素の」メソッドなので、フォームビルダーのインスタンスでは呼び出されません。たとえば以下のように`select_year`ヘルパーを使うとします。

```erb
<%= select_year 1999, prefix: "party" %>
```

セレクトボックスのHTML出力は以下のようになります。

```html
<select name="party[year]" id="party_year">
  <option value="1994">1994</option>
  <option value="1995">1995</option>
  <option value="1996">1996</option>
  <option value="1997">1997</option>
  <option value="1998">1998</option>
  <option value="1999" selected="selected">1999</option>
  <option value="2000">2000</option>
  <option value="2001">2001</option>
  <option value="2002">2002</option>
  <option value="2003">2003</option>
  <option value="2004">2004</option>
</select>
```

各ヘルパーでは、数値の代わりに日付オブジェクトや時刻オブジェクトをデフォルト値に指定でき、そこから適切な一時コンポーネントを抽出して使います。

任意のオブジェクトのコレクションから選択する
----------------------------------------------

フォームで、オブジェクトのコレクションを選択可能にしたいことがよくあります。たとえば、ユーザーに選択して欲しい都市名がデータベースにあり、以下のような`City`モデルがあるとします。

```ruby
City.order(:name).to_a
# => [
#      #<City id: 3, name: "Berlin">,
#      #<City id: 1, name: "Chicago">,
#      #<City id: 2, name: "Madrid">
#    ]
```

Railsは、コレクションを明示的にイテレートせずにセレクトボックス/ラジオボタン/チェックボックスを生成できるヘルパーを提供しています。これらのヘルパーは、コレクション内のオブジェクトごとに指定のメソッドを代わりに呼び出して、選択肢の値とテキストラベルを決定します。

### `collection_select`ヘルパー

[`collection_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_select)ヘルパーを使えば、以下のように都市名を選択するセレクトボックスを生成できます。

```erb
<%= form.collection_select :city_id, City.order(:name), :id, :name %>
```

セレクトボックスのHTML出力は以下のようになります。

```html
<select name="city_id" id="city_id">
  <option value="3">Berlin</option>
  <option value="1">Chicago</option>
  <option value="2">Madrid</option>
</select>
```

NOTE: `collection_select`では、第1引数に値のメソッド（上の例では`:id`）、第2引数にテキストラベルのメソッド（上の例では`:name`）を指定します。この順序は、`select`ヘルパーで選択肢を指定する場合（テキストラベルが最初で次が値）と逆である点にご注意ください。

### `collection_radio_buttons`ヘルパー

[`collection_radio_buttons`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_radio_buttons)ヘルパーを使えば、以下のように都市名を選択するラジオボタンのセットを生成できます。

```erb
<%= form.collection_radio_buttons :city_id, City.order(:name), :id, :name %>
```

ラジオボタンのHTML出力は以下のようになります。

```html
<input type="radio" name="city_id" value="3" id="city_id_3">
<label for="city_id_3">Berlin</label>
<input type="radio" name="city_id" value="1" id="city_id_1">
<label for="city_id_1">Chicago</label>
<input type="radio" name="city_id" value="2" id="city_id_2">
<label for="city_id_2">Madrid</label>
```

### `collection_check_boxes`ヘルパー

[`collection_check_boxes`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_check_boxes)ヘルパーを使えば、以下のように都市名を選択するチェックボックスのセットを生成できます。

```erb
<%= form.collection_check_boxes :city_id, City.order(:name), :id, :name %>
```

チェックボックスのHTML出力は以下のようになります。

```html
<input type="checkbox" name="city_id[]" value="3" id="city_id_3">
<label for="city_id_3">Berlin</label>
<input type="checkbox" name="city_id[]" value="1" id="city_id_1">
<label for="city_id_1">Chicago</label>
<input type="checkbox" name="city_id[]" value="2" id="city_id_2">
<label for="city_id_2">Madrid</label>
```

ファイルのアップロード
---------------

ファイルのアップロードはアプリケーションでよく行われるタスクの1つです（プロフィール写真のアップロードや、処理したいCSVファイルのアップロードなど）。[`file_field`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-file_field)ヘルパーを使えば、以下のようにファイルアップロード用フィールドをレンダリングできます。

```erb
<%= form_with model: @person do |form| %>
  <%= form.file_field :picture %>
<% end %>
```

ファイルアップロードで最も重要なのは、レンダリングされるフォームの`enctype`属性を**必ず**"multipart/form-data"に設定しなければならない点です。これは、以下のように`form_with`の内側で`file_field_tag`ヘルパーを使えば自動で行われます。`enctype`属性は手動でも設定できます。

```erb
<%= form_with url: "/uploads", multipart: true do |form| %>
  <%= file_field_tag :picture %>
<% end %>
```

なお、`form_with`の規約に基づいて上述の2つのフィールド名もそれぞれ異なります。つまり前者のフォームではフィールド名が`person[picture]`になり（`params[:person][:picture]`でアクセス可能）、後者のフォームでは単なる`picture`になります（`params[:picture]`でアクセス可能）。

### アップロード可能なファイル

`params`ハッシュに含まれるこのオブジェクトは、[`ActionDispatch::Http::UploadedFile`](https://api.rubyonrails.org/classes/ActionDispatch/Http/UploadedFile.html)のインスタンスです。以下のコードスニペットは、アップロードされたファイルを`#{Rails.root}/public/uploads`のパスに元のファイル名で保存します。

```ruby
def upload
  uploaded_file = params[:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_file.original_filename), 'wb') do |file|
    file.write(uploaded_file.read)
  end
end
```

ファイルのアップロードが完了すると、ファイルの保存先の決定（DiskやAmazon S3など）、モデルとの関連付け、画像ファイルのりサイズ、サムネイルの生成など、さまざまなタスクが必要になる可能性があります。[Active Storage](active_storage_overview.html)は、こうしたタスクを支援するように設計されています。

フォームビルダーをカスタマイズする
-------------------------

`form_with`や`fields_for`によって生成されるオブジェクトは、[`ActionView::Helpers::FormBuilder`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html)のインスタンスです。フォームビルダーは、1個のオブジェクトのフォーム要素を表示するのに必要なものをカプセル化します。フォーム用のヘルパーを通常の方法で自作するときに、`ActionView::Helpers::FormBuilder`のサブクラスを作成してそこにヘルパーを追加することも可能です。次の例をご覧ください。

```erb
<%= form_with model: @person do |form| %>
  <%= text_field_with_label form, :first_name %>
<% end %>
```

上のコードは以下のように置き換えることもできます。

```erb
<%= form_with model: @person, builder: LabellingFormBuilder do |form| %>
  <%= form.text_field :first_name %>
<% end %>
```

上の結果を得るには、以下のような`LabellingFormBuilder`クラスを定義しておきます。

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

このクラスを頻繁に再利用する場合は、以下のように`labeled_form_with`ヘルパーを定義して`builder: LabellingFormBuilder`オプションを自動的に適用してもよいでしょう。

```ruby
def labeled_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
  options.merge! builder: LabellingFormBuilder
  form_with model: model, scope: scope, url: url, format: format, **options, &block
end
```

ここで使われているフォームビルダーは、以下のコードが実行された時の動作も決定します。

```erb
<%= render partial: f %>
```

`f`が`ActionView::Helpers::FormBuilder`のインスタンスである場合、このコードは`form`パーシャルを生成し、そのパーシャルオブジェクトをフォームビルダーに設定します。このフォームビルダーのクラスが`LabellingFormBuilder`の場合 、代わりに`labelling_form`パーシャルがレンダリングされます。

パラメータの命名ルールを理解する
------------------------------------------

フォームから受け取る値は、`params`ハッシュのトップレベルに置かれるか、他のハッシュの中に入れ子になって含まれます。たとえば、`Person`モデルの標準的な`create`アクションでは、`params[:person]`はその人物について作成されるすべての属性のハッシュになります。`params`ハッシュには配列やハッシュの配列なども含められます。

HTMLフォームは原理的に、いかなる構造化データについても関知しません。フォームが生成するのはすべて名前と値のペア（どちらも単なる文字列）です。これらのデータをアプリケーション側で参照したときに配列やハッシュになっているのは、Railsで使われているパラメータ命名ルールのおかげです。

### 基本構造

配列とハッシュは、基本的な2大データ構造です。ハッシュは、`params`の値にアクセスする時に使われる文法に反映されています。たとえば、フォームに以下が含まれているとします。

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

このとき、`params`ハッシュの内容は以下のようになります。

```ruby
{'person' => {'name' => 'Henry'}}
```

コントローラ内で`params[:person][:name]`でアクセスすると、送信された値を取り出せます。

ハッシュは、以下のように必要に応じて何階層でもネストすることができます。

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

上のコードによってできる`params`ハッシュは以下のようになります。

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

Railsは、重複したパラメータ名を無視します。パラメータ名に空の角かっこ`[ ]`が含まれている場合、パラメータは配列の中にまとめられます。たとえば、複数の電話番号を入力できるようにしたい場合、フォームに以下を置くことができます。

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

これにより、`params[:person][:phone_number]`は入力された電話番号の配列になります。

### 組み合わせ方

これらの2つの概念を混ぜて使うことも可能です。たとえば、前述の例のようにハッシュの1つの要素を配列にすることも、複数のハッシュを配列にすることもできます。以下のようにフォームの一部を繰り返すことで、任意の数の住所を作成できるようなフォームも作成可能です。

```html
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
```

上のフォームでは`params[:person][:addresses]`ハッシュが作成されます。これは`line1`、`line2`、`city`をキーに持つハッシュの配列です。

ただしここで1つ制限があります。ハッシュはいくらでもネストできますが、配列は1階層しか使えません。配列はたいていの場合ハッシュで置き換えられます。たとえば、モデルオブジェクトの配列の代わりに、モデルオブジェクトのハッシュを使えます。このキーではid、配列インデックスなどのパラメータが利用できます。

WARNING: 配列パラメータは、`check_box`ヘルパーとの相性がよくありません。HTMLの仕様では、オンになっていないチェックボックスからは値が送信されません。しかし、チェックボックスから常に値が送信される方が何かと便利です。そこで`check_box`ヘルパーでは、同じ名前で予備の隠し入力を作成しておき、本来送信されないはずのチェックボックス値が見かけ上送信されるようになっています。チェックボックスがオフになっていると隠し入力値だけが送信され、チェックボックスがオンになっていると本来のチェックボックス値と隠し入力値が両方送信されますが、このとき優先されるのは本来のチェックボックス値の方です。

### `fields_for`ヘルパー

たとえば、個人の各住所に対応するフィールドのセットを持つフォームをレンダリングしたいとします。こんなときは`fields_for`ヘルパーと`:index`引数が役に立ちます。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.text_field :name %>
  <% @person.addresses.each do |address| %>
    <%= person_form.fields_for address, index: address.id do |address_form| %>
      <%= address_form.text_field :city %>
    <% end %>
  <% end %>
<% end %>
```

この個人が2つの住所を持っていて、idがそれぞれ23と45だとすると、以下のようなHTMLが出力されます。

```html
<form accept-charset="UTF-8" action="/people/1" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

このときの`params`ハッシュは以下のようになります。

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => 'London'}}}}
```

最初のフォームビリダーで`fields_for`を呼び出していたので、Railsはこれらの入力が`person`ハッシュの一部であることを認識します。`:index`を指定すると、入力を`person[address][city]という名前にするのではなく、`[]`で囲まれたインデックスを`address`と`city`の間に挿入するようRailsに指示します。

これは、Addressのどのレコードを変更すべきかを簡単に見つけられるので、何かと便利です。別の意味を持つ数字を渡すことも、文字列を渡すことも、`nil`を渡すことも可能です（この場合は配列パラメータが作成されます）。

さらに複雑な入れ子を作る場合は、入力名の冒頭部分（上の例では`person[address]`）を以下のように明示的に指定できます。

```erb
<%= fields_for 'person[address][primary]', address, index: address.id do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="Bologna" />
```

一般に、最終的な入力名は`fields_for`や`form_with`に渡された名前、インデックス値、属性名を連結したものになります。`:index`オプションは`text_field`などのヘルパーに直接渡すことも可能ですが、通常は個別の入力コントロールよりもフォームビルダーのレベルで指定する方がコードの繰り返しが少なく済みます。

以下のように、名前に`[]`を追加して`:index`オプションを省略するショートカットも利用できます。これは`index: address.id`を指定するのと同じです。

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

つまり、上のコードでは前述の例と完全に同じHTML出力を得られます。

外部リソース用のフォーム
---------------------------

外部リソースに何らかのデータを渡す必要がある場合も、Railsのフォームヘルパーを用いてフォームを作成する方がやはり便利です。しかし、その外部リソースに対して`authenticity_token`を設定しなければならない場合にはどうしたらよいでしょう。これは、`form_with`オプションに`authenticity_token: 'your_external_token'`パラメータを渡すことで実現できます。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

支払用ゲートウェイなどの外部リソースに対してデータを送信する場合、`authenticity_token`隠しフィールドを生成すると、フォームで使えるフィールドは外部APIによって制限されて不都合が生じることがあります。フィールド生成を抑制するには、`:authenticity_token`オプションに`false`を渡します。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

複雑なフォームを作成する
----------------------

最初は単一のオブジェクトを編集していただけのシンプルなフォームも、やがて成長し複雑になります。たとえば、`Person`を1人作成するのであれば、そのうち同じフォームで複数の住所レコード（自宅と職場など）を登録したくなるでしょう。後で`Person`を編集するときに、必要に応じて住所の追加・削除・変更も行えるようにする必要があります。

### モデルを構成する

Active Recordは[`accepts_nested_attributes_for`](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for)メソッドでモデルレベルのサポートを行っています。

```ruby
class Person < ApplicationRecord
  has_many :addresses, inverse_of: :person
  accepts_nested_attributes_for :addresses
end

class Address < ApplicationRecord
  belongs_to :person
end
```

上のコードによって`addresses_attributes=`メソッドが`Person`モデル上に作成され、これを用いて住所の作成・更新・削除（必要な場合）を行なえます。

### ネストしたフォーム

ユーザーは以下のフォームを用いて`Person`とそれに関連する複数の住所を作成することができます。

```html+erb
<%= form_with model: @person do |form| %>
  Addresses:
  <ul>
    <%= form.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>

        <%= addresses_form.label :street %>
        <%= addresses_form.text_field :street %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

ネストした属性が関連付けに渡されると、`fields_for`ヘルパーはその関連付けのすべての要素を一度ずつ出力します。特に、`Person`に住所が登録されていない場合は何も出力しません。フィールドのセットが少なくとも1つはユーザーに表示されるように、コントローラで1つ以上の空白の子を作成しておくというのはよく行われるパターンです。以下の例では、Personフォームを新たに作成したときに2組の住所フィールドがレンダリングされます。

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build }
end
```

`fields_for`ヘルパーはフォームフィールドを1つ生成します。`accepts_nested_attributes_for`ヘルパーが受け取るのはこのようなパラメータの名前です。たとえば、2つの住所を持つユーザーを1人作成する場合、送信されるパラメータは以下のようになります。

```ruby
{
  'person' => {
    'name' => 'John Doe',
    'addresses_attributes' => {
      '0' => {
        'kind' => 'Home',
        'street' => '221b Baker Street'
      },
      '1' => {
        'kind' => 'Office',
        'street' => '31 Spooner Street'
      }
    }
  }
}
```

`:addresses_attributes`ハッシュのキーはここでは重要ではありません。各アドレスのキーが重複しないことが必要です。

関連付けられたオブジェクトが既に保存されている場合、`fields_for`メソッドは、保存されたレコードの`id`を持つ隠し入力を自動生成します。`fields_for`に`include_id: false`を渡すことでこの自動生成をオフにできます。

### コントローラ

コントローラ内でパラメータをモデルに渡す前に、定番の[パラメータの許可リストチェック](action_controller_overview.html#strong-parameters)を宣言する必要があります。

```ruby
def create
  @person = Person.new(person_params)
  # ...
end

private
  def person_params
    params.require(:person).permit(:name, addresses_attributes: [:id, :kind, :street])
  end
```

### オブジェクトを削除する

`accepts_nested_attributes_for`に`allow_destroy: true`を渡すと、関連付けられたオブジェクトをユーザーが削除することを許可できます。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

あるオブジェクトの属性のハッシュに、キーが`_destroy`で、値が`true`と評価可能（1、`1`、true、`true`など）な組み合わせがあると、そのオブジェクトは削除されます。以下のフォームではユーザーが住所を削除可能です。

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.check_box :_destroy %>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

コントローラ内にある許可されたパラメータを以下のように更新して、`_destroy`フィールドが必ずパラメータに含まれるようにしておく必要があります。

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 空のレコードができないようにする

ユーザーが何も入力しなかったフィールドを無視できれば何かと便利です。これは、`:reject_if` procを`accepts_nested_attributes_for`に渡すことで制御できます。このprocは、フォームから送信された属性にあるハッシュごとに呼び出されます。このprocが`false`を返す場合、Active Recordはそのハッシュに関連付けられたオブジェクトを作成しません。以下の例では、`kind`属性が設定されている場合にのみ住所オブジェクトを生成します。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

代わりにシンボル`:all_blank`を渡すこともできます。このシンボルが渡されると、すべての値が空欄のレコードを受け付けなくなるprocが1つ生成され、`_destroy`ですべての値が取り除かれます。

### フィールドを動的に追加する

多くのフィールドセットを事前にレンダリングする代わりに、「新しい住所を追加」ボタンを押したときだけこれらのフィールドを動的に追加したいことがあります。残念ながらRailsではこのためのサポートは組み込まれていません。フィールドセットを動的に生成する場合は、関連する配列のキーが重複しないよう注意しなければなりません。JavaScriptで現在の日時（[エポック時間](https://ja.wikipedia.org/wiki/UNIX%E6%99%82%E9%96%93)からのミリ秒の経過時間）を取得して一意の値を得るのが定番の手法です。

フォームビルダーなしで利用できるタグヘルパー
----------------------------------------

フォームのフィールドをフォームビルダーのコンテキストの外でレンダリングする必要が生じたときのためにRailsではよく使われるフォーム要素を生成するタグヘルパーを提供しています。たとえば、[`check_box_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-check_box_tag)は以下のように使えます。

```erb
<%= check_box_tag "accept" %>
```

上のコードから以下のHTMLが生成されます。

```html
<input type="checkbox" name="accept" id="accept" value="1" />
```

一般に、これらのヘルパー名は、フォームビルダーのヘルパー名の末尾に`_tag`を追加したものになります。完全なリストについては、[`FormTagHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html) APIドキュメントを参照してください。

`form_tag`や`form_for`の利用について
-------------------------------

Rails 5.1で`form_with`が導入されるまでは、`form_with`の機能は[`form_tag`](https://api.rubyonrails.org/v5.2/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag)と[`form_for`](https://api.rubyonrails.org/v5.2/classes/ActionView/Helpers/FormHelper.html#method-i-form_for)に分かれていました。`form_tag`および`form_for`は、禁止ではないものの利用は推奨されていません。これらのメソッドの利用方法については、[旧バージョンのガイド](https://railsguides.jp/?version=5.2)を参照してください。
