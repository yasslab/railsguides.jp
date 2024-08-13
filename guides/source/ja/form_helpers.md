Action View フォームヘルパー
============

Webアプリケーションのフォームは、ユーザー入力で多用されるインターフェイスです。しかしフォームのマークアップは、フォームのコントロールの命名法や大量の属性を扱わなければならず、作成もメンテナンスも退屈な作業になりがちです。そこでRailsでは、フォームのマークアップを生成するビューヘルパーを提供することで作業をシンプルにしています。このガイドは、さまざまなヘルパーメソッドや、利用する時期を理解するのに役立ちます。

このガイドの内容:

* 基本的なフォーム（検索フォームなど）の作成法
* データベースの特定のレコードを作成・編集する、モデルベースのフォーム作成法
* 複数の種類のデータからセレクトボックスを生成する方法
* Railsが提供する日付時刻関連ヘルパー
* ファイルアップロード用フォームの動作を変更する方法
* 外部リソース向けにフォームを作成する方法と`authenticity_token`を設定する方法
* 複雑なフォームの作成方法

--------------------------------------------------------------------------------

このガイドはフォームヘルパーとその引数について網羅的に説明するものではありません。完全なリファレンスについては[Rails APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers.html)を参照してください。


基本的なフォームを作成する
------------------------

最も基本的なフォームヘルパーは[`form_with`][]です。

```erb
<%= form_with do |form| %>
  Form contents
<% end %>
```

上のように`form_with`を引数なしで呼び出すと、`<form>`タグが生成されます。このフォームは、`method`属性の値が`post`に設定され、`action`属性の値が現在のページに設定されます。このフォームを現在のページに送信するときにHTTP POSTメソッドが使われます。たとえば現在のページが`/home`ページだとすると、以下のようなHTMLが生成されます。

```html
<form action="/home" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="Lz6ILqUEs2CGdDa-oz38TqcqQORavGnbGkG0CQA8zc8peOps-K7sHgFSTPSkBx89pQxh3p5zPIkjoOTiA_UWbQ" autocomplete="off">
```

このフォームに含まれている`input`要素では、`type`属性が`hidden`になっていることにご注目ください。GET以外のフォームを送信する場合は、この`authenticity_token`の隠し入力が必要です。
このトークンは、クロスサイトリクエストフォージェリ（CSRF）攻撃を防ぐために使われるRailsのセキュリティ機能であり、フォームヘルパーは、セキュリティ機能が有効になっていることを前提として、GET以外のすべてのフォームでこのトークンを自動的に生成します。詳しくは、[Rails アプリケーションのセキュリティ保護](security.html#クロスサイトリクエストフォージェリ（csrf）)ガイドを参照してください。

[`form_with`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with

### 一般的な検索フォーム

検索フォームはWebでよく使われています。検索フォームには以下のものが含まれています。

* GETメソッドを送信するためのフォーム要素
* 入力項目を示すラベル
* テキスト入力要素
* 送信ボタン要素

`form_with`で検索フォームを作成するには、以下のように書きます。

```erb
<%= form_with url: "/search", method: :get do |form| %>
  <%= form.label :query, "Search for:" %>
  <%= form.text_field :query %>
  <%= form.submit "Search" %>
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form action="/search" accept-charset="UTF-8" method="get">
  <label for="query">Search for:</label>
  <input type="text" name="query" id="query">
  <input type="submit" name="commit" value="Search" data-disable-with="Search">
</form>
```

この検索フォームでは、`form_with`の`url`オプションが使われていることにご注目ください。`url: "/search"`を設定すると、フォームの`action`の値がデフォルトの現在のページのパスから`action="/search"`に変更されます。

一般に、`form_with`に`url: my_path`を渡すと、リクエストを送信する場所がフォームで指定されます。別のオプションとして、Active Modelオブジェクトをフォームに渡す方法も使えます。これについては、[モデルオブジェクトを指定してフォームを作成する](#モデルオブジェクトを指定してフォームを作成する)で後述します。[URLヘルパー](routing.html#パスとurl用ヘルパー)を利用することも可能です。

上記の検索フォームの例では、[`FormBuilder`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html)オブジェクトも示されています。次のセクションでは、フォームビルダーオブジェクトが提供する多くのヘルパー（`form.label`や`form.text_field`など）について学習します。

TIPS: フォームのあらゆる`input`要素に対して、その名前（上記の例では`"query"`）から`id`属性が生成されます。これらのIDは、CSSスタイル設定やJavaScriptによるフォームコントロールの操作で非常に有用です。

IMPORTANT: 検索フォームには"GET"メソッドを使ってください。Railsでは基本的に、常にアクションに対応する適切なHTTPメソッド（verb）を選ぶことが推奨されています（訳注: [セキュリティガイド](security.html#csrfへの対応策)にも記載されているように、たとえば更新フォームでGETメソッドを使うと重大なセキュリティホールが生じる可能性があります）。検索フォームで"GET"メソッドを使うと、ユーザーが特定の検索をブックマークできるようになります。

### フォーム要素を生成するヘルパー

`form_with`で生成されるフォームビルダーオブジェクトには、「テキストフィールド」「チェックボックス」「ラジオボタン」などの一般的なフォーム要素を生成するためのヘルパーメソッドが多数用意されています。

これらのメソッドの第1引数は、常に入力の名前です。フォームが送信されると、この名前がフォームデータとともに`params`ハッシュでコントローラに渡されるので、覚えておくと便利です。この名前は、そのフィールドにユーザーが入力した値の`params`のキーになります。

たとえば、フォームに`<%= form.text_field :query %>`が含まれている場合、コントローラで`params[:query]`と書くことでこのフィールドの値を取得できます。

Railsでは、`input`に名前を与えるときに特定の規約を利用します。これにより、配列やハッシュのような「非スカラー値」のパラメータをフォームから送信できるようになり、コントローラでも`params`にアクセス可能になります。これらの命名規約について詳しくは、本ガイドで後述する「[フォーム入力の命名規約と`params`ハッシュ](#フォーム入力の命名規約とparamsハッシュ)」を参照してください。これらのヘルパーの具体的な利用法について詳しくはAPIドキュメントの[`ActionView::Helpers::FormTagHelper`][]を参照してください。

[`ActionView::Helpers::FormTagHelper`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html

#### チェックボックス

チェックボックスはフォームコントロールの一種で、ユーザーが選択肢の項目をオン/オフできるようにします。チェックボックスのグループは、通常、グループから1つ以上のオプションをユーザーが選択可能にしたいときに使われます。

3つのチェックボックスがあるフォームの例を以下に示します。

```erb
<%= form.check_box :biography %>
<%= form.label :biography, "Biography" %>
<%= form.check_box :romance %>
<%= form.label :romance, "Romance" %>
<%= form.check_box :mystery %>
<%= form.label :mystery, "Mystery" %>
```

上のコードによって以下が生成されます。

```html
<input name="biography" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="biography" id="biography">
<label for="biography">Biography</label>
<input name="romance" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="romance" id="romance">
<label for="romance">Romance</label>
<input name="mystery" type="hidden" value="0" autocomplete="off"><input type="checkbox" value="1" name="mystery" id="mystery">
<label for="mystery">Mystery</label>
```

[`check_box`][]の第1パラメータ`name`は、`params`ハッシュで見つかる入力の名前です。ユーザーが「Biography」チェックボックスのみをチェックした場合、`params`ハッシュには次の内容が含まれます。

```ruby
{
  "biography" => "1",
  "romance" => "0",
  "mystery" => "0"
}
```

`params[:biography]`で、ユーザーがそのチェックボックスを選択しているかどうかを確認できます。

チェックボックスの値（`params`に表示される値）は、オプションで`checked_value`パラメータと`unchecked_value`パラメータで指定できます。詳しくは、APIドキュメントの[`check_box`][]を参照してください。

また、`collection_check_boxes`も利用できます。これについては[コレクション関連のヘルパー](#コレクション関連のヘルパー)セクションで学習できます。

[`check_box`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box

#### ラジオボタン

ラジオボタンは、リストから1個の項目だけを選択できるフォームコントロールです。

たとえば、以下のラジオボタンではアイスクリームの好みのフレーバーを選択できます。

```erb
<%= form.radio_button :flavor, "chocolate_chip" %>
<%= form.label :flavor_chocolate_chip, "Chocolate Chip" %>
<%= form.radio_button :flavor, "vanilla" %>
<%= form.label :flavor_vanilla, "Vanilla" %>
<%= form.radio_button :flavor, "hazelnut" %>
<%= form.label :flavor_hazelnut, "Hazelnut" %>
```

出力されるHTMLは以下のようになります。

```html
<input type="radio" value="chocolate_chip" name="flavor" id="flavor_chocolate_chip">
<label for="flavor_chocolate_chip">Chocolate Chip</label>
<input type="radio" value="vanilla" name="flavor" id="flavor_vanilla">
<label for="flavor_vanilla">Vanilla</label>
<input type="radio" value="hazelnut" name="flavor" id="flavor_hazelnut">
<label for="flavor_hazelnut">Hazelnut</label>
```

[`radio_button`][]の第2パラメータは、inputの値（`value`）です。2つのラジオボタン項目は同じ名前（`flavor`）を共有しているので、ユーザーは一方の値だけを選択できます。これにより、`params[:flavor]`の値は`"chocolate_chip"`、`"vanilla"`、`hazelnut`のいずれかになります。

NOTE: チェックボックスやラジオボタンには必ずラベルも表示しておきましょう。`for`属性でそのオプションとラベル名を関連付けておけば、ラベルの部分もクリック可能になるのでユーザーにとって使いやすくなります。

[`radio_button`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button

### その他のヘルパー

これまで紹介した他にも、テキスト用、メールアドレス用、パスワード用、日付時刻用など、多くのフォームコントロールを利用できます。以下の例では、これらのヘルパーの利用例と生成されるHTMLを示します。

日付時刻関連のヘルパー:

```erb
<%= form.date_field :born_on %>
<%= form.time_field :started_at %>
<%= form.datetime_local_field :graduation_day %>
<%= form.month_field :birthday_month %>
<%= form.week_field :birthday_week %>
```

上の出力は以下のようになります。

```html
<input type="date" name="born_on" id="born_on">
<input type="time" name="started_at" id="started_at">
<input type="datetime-local" name="graduation_day" id="graduation_day">
<input type="month" name="birthday_month" id="birthday_month">
<input type="week" name="birthday_week" id="birthday_week">
```

特殊フォーマット用ヘルパー:

```erb
<%= form.password_field :password %>
<%= form.email_field :address %>
<%= form.telephone_field :phone %>
<%= form.url_field :homepage %>
```

上の出力は以下のようになります。

```html
<input type="password" name="password" id="password">
<input type="email" name="address" id="address">
<input type="tel" name="phone" id="phone">
<input type="url" name="homepage" id="homepage">
```

その他のよく使われるヘルパー:

```erb
<%= form.text_area :message, size: "70x5" %>
<%= form.hidden_field :parent_id, value: "foo" %>
<%= form.number_field :price, in: 1.0..20.0, step: 0.5 %>
<%= form.range_field :discount, in: 1..100 %>
<%= form.search_field :name %>
<%= form.color_field :favorite_color %>
```

上の出力は以下のようになります。

```html
<textarea name="message" id="message" cols="70" rows="5"></textarea>
<input value="foo" autocomplete="off" type="hidden" name="parent_id" id="parent_id">
<input step="0.5" min="1.0" max="20.0" type="number" name="price" id="price">
<input min="1" max="100" type="range" name="discount" id="discount">
<input type="search" name="name" id="name">
<input value="#000000" type="color" name="favorite_color" id="favorite_color">
```

隠し属性（`type="hidden"`）付きの`input`はユーザーには表示されず、種類を問わず事前に与えられた値を保持します。隠しフィールドに含まれている値はJavaScriptで変更できます。

TIP: パスワード入力フィールドを使っている場合は、利用目的にかかわらず、入力されたパスワードをRailsのログに残さないようにするとよいでしょう。方法については[セキュリティガイド](security.html#ログ出力)を参照してください。

モデルオブジェクトを指定してフォームを作成する
--------------------------

### フォームをオブジェクトに結び付ける

`form_with`ヘルパーの`:model`引数を使うと、フォームビルダーオブジェクトをモデルオブジェクトに紐付けできるようになります。つまり、フォームはそのモデルオブジェクトを対象とし、そのモデルオブジェクトの値がフォームのフィールドに自動入力されるようになります。

たとえば、以下のような`@book`というモデルオブジェクトがあるとします。

```ruby
@book = Book.find(42)
# => #<Book id: 42, title: "Walden", author: "Henry David Thoreau">
```

新しいbookを作成するフォームは以下のようになります。

```erb
<%= form_with model: @book do |form| %>
  <div>
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>
  <div>
    <%= form.label :author %>
    <%= form.text_field :author %>
  </div>
  <%= form.submit %>
<% end %>
```

HTML出力は以下のようになります。

```html
<form action="/books" accept-charset="UTF-8" method="post">
  <input type="hidden" name="authenticity_token" value="ChwHeyegcpAFDdBvXvDuvbfW7yCA3e8gvhyieai7DhG28C3akh-dyuv-IBittsjPrIjETlQQvQJ91T77QQ8xWA" autocomplete="off">
  <div>
    <label for="book_title">Title</label>
    <input type="text" name="book[title]" id="book_title">
  </div>
  <div>
    <label for="book_author">Author</label>
    <input type="text" name="book[author]" id="book_author">
  </div>
  <input type="submit" name="commit" value="Create Book" data-disable-with="Create Book">
</form>
```

`form_with`でモデルオブジェクトを使うと以下のような重要な処理が自動的に行われます。

* フォームの`action`属性には適切な値`action="/books"`が自動的に入力されます。書籍を更新する場合は`action="/books/42"`になります。
* フォームのフィールド名は`book[...]`でスコープされます。つまり、`params[:book]`はこれらのフィールドの値をすべて含むハッシュになります。入力名の重要性について詳しくは、本ガイドの[フォーム入力の命名規約と`params`ハッシュ](#フォーム入力の命名規約とparamsハッシュ)の章を参照してください。
* 送信ボタンには、適切なテキスト値 (この場合は「Create Book」) が自動的に入力されます。

TIP: 通常、フォーム入力にはモデル属性が反映されますが、必ずしもそうである必要はありません。モデル属性以外にも必要な情報がある場合は、フォームにフィールドを含めておけば、`params[:book][:my_non_attribute_input]`のようにアクセスできます。

#### 複合主キーを使うフォーム

モデルで[複合主キー（composite primary key）](active_record_composite_primary_keys.html)が使われている場合は、同じフォームビルダー構文から少し異なる出力が得られます。

複合主キー`[:author_id, :id]`を持つ`@book`モデルオブジェクトの場合を例にします。

```ruby
@book = Book.find([2, 25])
# => #<Book id: 25, title: "Some book", author_id: 2>
```

以下のフォームを作成します。

```erb
<%= form_with model: @book do |form| %>
  <%= form.text_field :title %>
  <%= form.submit %>
<% end %>
```

上のコードから以下のHTML出力が生成されます。

```html
<form action="/books/2_25" method="post" accept-charset="UTF-8" >
  <input name="authenticity_token" type="hidden" value="ChwHeyegcpAFDdBvXvDuvbfW7yCA3e8gvhyieai7DhG28C3akh-dyuv-IBittsjPrIjETlQQvQJ91T77QQ8xWA" />
  <input type="text" name="book[title]" id="book_title" value="Some book" />
  <input type="submit" name="commit" value="Update Book" data-disable-with="Update Book">
</form>
```

生成されたURLには、`author_id`と`id`が`2_25`のようにアンダースコア区切りの形で含まれていることにご注目ください。送信後、コントローラーはパラメータから[個別の主キーの値を抽出](action_controller_overview.html#複合主キーのパラメータ)して、単一の主キーと同様にレコードを更新できます。

#### `fields_for`ヘルパー

[`fields_for`][]ヘルパーは、同じフォーム内の関連モデルオブジェクトのフィールドをレンダリングするのに使われます。通常、関連付けられている「内部の」モデルはActive Recordの関連付けを介して「メインの」フォームモデルに関連付けられます。たとえば、関連付けられている`ContactDetail`モデルを持つ`Person`モデルがある場合、以下のように両方のモデルの入力を含む単一のフォームを作成できます。

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
  <input type="hidden" name="authenticity_token" value="..." autocomplete="off" />
  <input type="text" name="person[name]" id="person_name" />
  <input type="text" name="contact_detail[phone_number]" id="contact_detail_phone_number" />
</form>
```

`fields_for`で生成されるオブジェクトは、`form_with`で生成されるのと同様のフォームビルダーです。
`fields_for`ヘルパーは同様のバインディングを作成しますが、`<form>`タグはレンダリングされません。`field_for`について詳しくは、[APIドキュメント][`fields_for`]を参照してください。

[`fields_for`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-fields_for

### レコード識別を利用する

RESTfulなリソースを扱っている場合、**レコード識別（record identification）**を使うと`form_with`の呼び出しがはるかに簡単になります。これは、モデルのインスタンスを渡すだけで、後はRailsがそこからモデル名など必要な情報を取り出して処理してくれるというものです。以下の例では、長いバージョンと短いバージョンのどちらを使っても同じ出力を得られます。

```ruby
# 長いバージョン:
form_with(model: @article, url: articles_path)
# 短いバージョン（レコード識別を利用）:
form_with(model: @article)
```

同様に、以下のように既存の記事を編集する場合、`form_with`の長いバージョンと短いバージョンのどちらを使っても同じ出力を得られます。

```ruby
# 長いバージョン:
form_with(model: @article, url: article_path(@article), method: "patch")
# 短いバージョン（レコード識別を利用）:
form_with(model: @article)
```

短い方の`form_with`呼び出し構文は、レコードの作成・編集のどちらでもまったく同じである点が便利です。レコード識別では、レコードが新しいかどうかを[`record.persisted?`][]で自動的に識別します。さらに送信用の正しいパスを選択し、オブジェクトのクラスに基づいた名前も選択してくれます。

これは、ルーティングファイルで`Article`モデルが`resources :articles`で宣言されていることを前提としています。

[単数形リソース](routing.html#単数形リソース)を使う場合は、`form_with`が機能するために以下のように`resource`と`resolve`を呼び出す必要があります。

```ruby
resource :article
resolve('Article') { [:article] }
```

TIP: リソースを宣言すると、いくつかの副作用があります。リソースの設定や利用方法について詳しくは、[ルーティングガイド](routing.html#リソースベースのルーティング-railsのデフォルト)を参照してください。

WARNING: モデルで[単一テーブル継承（STI: single-table inheritance）](association_basics.html#単一テーブル継承-（sti）)を使っている場合、親クラスがリソースを宣言されていてもサブクラスでレコード識別を利用できません。その場合は`:url`と`:scope`（モデル名）を明示的に指定する必要があります。

[`record.persisted?`]: https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-persisted-3F

#### 名前空間を扱う

名前空間付きのルーティングがある場合、`form_with`でそのためのショートカットを利用できます。たとえば、アプリケーションに`admin`名前空間がある場合は、以下のように書けます。

```ruby
form_with model: [:admin, @article]
```

上のコードはそれによって、admin名前空間内にある`ArticlesController`に送信するフォームを作成します。つまり、更新の場合は`admin_article_path(@article)`に送信します。

名前空間に複数のレベルがある場合も、同様の構文で書けます。

```ruby
form_with model: [:admin, :management, @article]
```

Railsのルーティングシステムおよび関連するルールについて詳しくは[ルーティングガイド](routing.html)を参照してください。

### フォームにおけるPATCH・PUT・DELETEメソッドの動作

RailsフレームワークはRESTfulな設計を推奨しています。つまり、アプリケーション内のフォームは`GET`と`POST`の他に、`method`が`PATCH`、`PUT`、または`DELETE`であるリクエストを作成します。しかし、HTMLフォーム自体は、フォームの送信に関して`GET`と`POST`以外のHTTPメソッドを**サポートしていません**。

そこでRailsでは、これらのメソッドを`POST`メソッド上でエミュレートする形でこの制約を回避しています。具体的には、フォームのHTMLに`"_method"`という名前の隠し入力を追加し、使いたいHTTPメソッドをここで指定します。

```ruby
form_with(url: search_path, method: "patch")
```

上のコードから以下のHTML出力が得られます。

```html
<form action="/search" accept-charset="UTF-8" method="post">
  <input type="hidden" name="_method" value="patch" autocomplete="off">
  <input type="hidden" name="authenticity_token" value="R4quRuXQAq75TyWpSf8AwRyLt-R1uMtPP1dHTTWJE5zbukiaY8poSTXxq3Z7uAjXfPHiKQDsWE1i2_-h0HSktQ" autocomplete="off">
<!-- ... -->
</form>
```

Railsは、`POST`されたデータを解析する際にこの特殊な`_method`パラメータをチェックし、リクエストのHTTPメソッドが`_method`の値として指定されているもの（この場合は`PATCH`）であるかのように振る舞います。

`formmethod:`キーワードを指定すると、フォームをレンダリングするときに送信ボタンが指定の`method`属性をオーバーライドできるようになります。

```erb
<%= form_with url: "/posts/1", method: :patch do |form| %>
  <%= form.button "Delete", formmethod: :delete, data: { confirm: "Are you sure?" } %>
  <%= form.button "Update" %>
<% end %>
```

`<form>`要素の場合と同様、ほとんどのブラウザは[`formmethod`][]で宣言される`GET`と`POST`以外のフォームメソッドを**サポートしていません**。

Railsでは、`POST`メソッド上でこれらのメソッドをエミュレートする形でこの問題を回避しています。具体的には、[`formmethod`][]、[`value`][button-value]、[`name`][button-name]属性を組み合わせることでエミュレートします。

```html
<form accept-charset="UTF-8" action="/posts/1" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  <!-- ... -->

  <button type="submit" formmethod="post" name="_method" value="delete" data-confirm="Are you sure?">Delete</button>
  <button type="submit" name="button">Update</button>
</form>
```

上の場合、「Update」ボタンは`PATCH`メソッドとして扱われ、「Delete」ボタンは`DELETE`メソッドとして扱われます。

[`formmethod`]: https://developer.mozilla.org/ja/docs/Web/HTML/Element/button#attr-formmethod
[button-name]: https://developer.mozilla.org/ja/docs/Web/HTML/Element/button#attr-name
[button-value]: https://developer.mozilla.org/ja/docs/Web/HTML/Element/button#attr-value

セレクトボックスを手軽に作成する
-----------------------------

セレクトボックス（ドロップダウンリストとも呼ばれます）を使うと、ユーザーがオプションリストから項目を選択できるようになります。セレクトボックスのHTMLには、選択するオプションごとに1個の`<option>`要素を書かなければならないので、かなりの量のマークアップが必要になります。Railsには、このマークアップを生成するヘルパーメソッドが用意されています。

たとえば、ユーザーに選択して欲しい都市名のリストがあるとします。[`select`][]ヘルパーを使うと以下のようにセレクトボックスを作成できます。

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

選択の結果は、他のパラメータと同様に`params[:city]`で取得できます。

セレクトボックスのラベル（表示名）と異なる`<option>`値を指定することもできます。

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

[`select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-select

### セレクトボックス用のオプショングループ

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

### セレクトボックスをモデルオブジェクトに紐づける

セレクトボックスも、他のフォームコントロールと同様にモデル属性に紐づけ可能です。たとえば、以下の`@person`というモデルオブジェクトがあるとします。

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

唯一の違いは、選択されたオプションが`params[:city]`ではなく`params[:person][:city]`にあることです。

`selected="selected"`が適切なオプションに自動的に追加されている点にご注目ください。このセレクトボックスはモデルに紐付けられているので、`:selected`引数を指定する必要はありません。

日付時刻フォームヘルパーを使う
--------------------------------

[前述](#その他のヘルパー)した`date_field`ヘルパーや`time_field`ヘルパーに加えて、Railsはプレーンなセレクトボックスをレンダリングする日付および時刻の代替フォームヘルパーも提供します。`date_select`ヘルパーは、年/月/日などの一時コンポーネントごとにセレクトボックスをレンダリングします。

たとえば、以下のような`@person`というモデルオブジェクトがあるとします。

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

フォームが送信されたときの`params`ハッシュには、完全な日付を含む単一の値が存在しない点にご注目ください。代わりに、`"birth_date(1i)"`のような特殊な名前を持つ複数の値が存在します。しかしActive Modelは、モデル属性の宣言された型に基づいて、これらの特殊な名前を持つ値を完全な日付や時刻として組み立てる方法を知っています。つまり、フォームで完全な日付を表す1個のフィールドを使う場合と同じように、`params[:person]`を`Person.new`や`Person#update`などに渡せるということです。

Railsでは、[`date_select`][]ヘルパーの他に[`time_select`][]ヘルパー（時や分のセレクトボックスを出力する）や[`datetime_select`][]ヘルパー（日付と時刻のセレクトボックスの組み合わせ）も提供しています。

[`date_select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-date_select
[`time_select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-time_select
[`datetime_select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-datetime_select

### 個別の日付・時刻コンポーネント用のセレクトボックス

Railsでは、個別の日付時刻コンポーネント向けのセレクトボックスをレンダリングするヘルパーとして[`select_year`][]、[`select_month`][]、[`select_day`][]、[`select_hour`][]、[`select_minute`][]、[`select_second`][]も提供しています。

これらのヘルパーは「素の」メソッドなので、フォームビルダーのインスタンスでは呼び出されません。たとえば以下のように`select_year`ヘルパーを使うとします。

```erb
<%= select_year 2024, prefix: "party" %>
```

セレクトボックスのHTML出力は以下のようになります。

```html
<select id="party_year" name="party[year]">
  <option value="2019">2019</option>
  <option value="2020">2020</option>
  <option value="2021">2021</option>
  <option value="2022">2022</option>
  <option value="2023">2023</option>
  <option value="2024" selected="selected">2024</option>
  <option value="2025">2025</option>
  <option value="2026">2026</option>
  <option value="2027">2027</option>
  <option value="2028">2028</option>
  <option value="2029">2029</option>
</select>
```

各ヘルパーでは、デフォルト値として数値ではなく`Date`オブジェクトや`Time`オブジェクトを指定できます（たとえば、上記の代わりに`<%= select_year Date.today, prefix: "party" %>`）。ここから適切な日付と時刻の部分が抽出されて使われます。

[`select_year`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_year
[`select_month`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_month
[`select_day`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_day
[`select_hour`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_hour
[`select_minute`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_minute
[`select_second`]: https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-select_second

### タイムゾーンを選択する

ユーザーにどのタイムゾーンにいるのかを尋ねる必要がある場合は、非常に便利な[`time_zone_select`][]ヘルパーが使えます。

通常は、ユーザーが選択可能なタイムゾーンオプションのリストを提供する必要があります。定義済みの [`ActiveSupport::TimeZone`][]オブジェクトのリストがなければ作業が面倒になる可能性があります。`time_with_zone`ヘルパーはこのリストをラップしているので、次のように書けます。

```erb
<%= form.time_zone_select :time_zone %>
```

上のコードから、以下のHTMLが出力されます。

```html
<select name="time_zone" id="time_zone">
  <option value="International Date Line West">(GMT-12:00) International Date Line West</option>
  <option value="American Samoa">(GMT-11:00) American Samoa</option>
  <option value="Midway Island">(GMT-11:00) Midway Island</option>
  <option value="Hawaii">(GMT-10:00) Hawaii</option>
  <option value="Alaska">(GMT-09:00) Alaska</option>
  ...
  <option value="Samoa">(GMT+13:00) Samoa</option>
  <option value="Tokelau Is.">(GMT+13:00) Tokelau Is.</option>
</select>
```

**以前の**Railsには国を選択する`country_select`ヘルパーがありましたが、この機能は[country_selectプラグイン](https://github.com/stefanpenner/country_select)に切り出されました。

[`time_zone_select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-time_zone_select
[`ActiveSupport::TimeZone`]: https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html

コレクション関連のヘルパー
----------------------------------------------

Railsで任意のオブジェクトのコレクションから選択肢のセットを生成する必要がある場合は、`collection_select`、`collection_radio_button`、および`collection_check_boxes`ヘルパーが利用できます。

これらのヘルパーの有用さを示すために、`City`モデルと、それに対応する`Person`モデルとの間に`belongs_to :city`関連付けがある場合を考えます。

```ruby
class City < ApplicationRecord
end

class Person < ApplicationRecord
  belongs_to :city
end
```

データベースには以下の都市名が保存されているとします。

```ruby
City.order(:name).map { |city| [city.name, city.id] }
# => [["Berlin", 1], ["Chicago", 3], ["Madrid", 2]]
```

続いて、以下のようなフォームで、ユーザーがデータベースから都市名を選択できるようにします。

```erb
<%= form_with model: @person do |form| %>
  <%= form.select :city_id, City.order(:name).map { |city| [city.name, city.id] } %>
<% end %>
```

上のコードから、以下のHTMLが出力されます。

```html
<select name="person[city_id]" id="person_city_id">
  <option value="1">Berlin</option>
  <option value="3">Chicago</option>
  <option value="2">Madrid</option>
</select>
```

上のコード例は、選択肢を手動で生成する方法を示していますが、Railsには明示的に反復処理を書かずにコレクションから選択肢を生成するヘルパーがあります。これらのヘルパーは、コレクション内の各オブジェクトで指定のメソッドを呼び出すことによって、各選択肢の値とテキストラベルを決定します。

NOTE: `belongs_to`関連付けのフィールドをレンダリングするときは、関連付け自体の名前ではなく、外部キー名（上の例では`city_id`）を指定しなければなりません。

### `collection_select`ヘルパー

[`collection_select`][]ヘルパーを使えば、以下のように都市名を選択するセレクトボックスを生成できます。

```erb
<%= form.collection_select :city_id, City.order(:name), :id, :name %>
```

セレクトボックスのHTML出力は以下のように手書きの場合と同じになります。

```html
<select name="person[city_id]" id="person_city_id">
  <option value="1">Berlin</option>
  <option value="3">Chicago</option>
  <option value="2">Madrid</option>
</select>
```

NOTE: 引数の順序は、 `collection_select`の場合と`select`の場合で異なっていることにご注意ください。`collection_select`では、第1引数に値のメソッド（上の例では`:id`）、第2引数にテキストラベルのメソッド（上の例では`:name`）を指定します。`select`ヘルパーで選択肢を指定する場合の引数の順序はこれと逆である点にご注意ください（テキストラベルが最初で次が値）。前述のコード例では`["Berlin", 1]`となります。

[`collection_select`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_select

### `collection_radio_buttons`ヘルパー

ラジオボタンのセットを生成するには、[`collection_radio_buttons`][]ヘルパーを使います。

```erb
<%= form.collection_radio_buttons :city_id, City.order(:name), :id, :name %>
```

ラジオボタンのHTML出力は以下のようになります。

```html
<input type="radio" value="1" name="person[city_id]" id="person_city_id_1">
<label for="person_city_id_1">Berlin</label>

<input type="radio" value="3" name="person[city_id]" id="person_city_id_3">
<label for="person_city_id_3">Chicago</label>

<input type="radio" value="2" name="person[city_id]" id="person_city_id_2">
<label for="person_city_id_2">Madrid</label>
```

[`collection_radio_buttons`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_radio_buttons

### `collection_check_boxes`ヘルパー

たとえば`has_and_belongs_to_many`関連付けをサポートする形でチェックボックスのセットを生成するには、[`collection_check_boxes`][]ヘルパーを使います。

```erb
<%= form.collection_check_boxes :interest_ids, Interest.order(:name), :id, :name %>
```

チェックボックスのHTML出力は以下のようになります。

```html
<input type="checkbox" name="person[interest_id][]" value="3" id="person_interest_id_3">
<label for="person_interest_id_3">Engineering</label>

<input type="checkbox" name="person[interest_id][]" value="4" id="person_interest_id_4">
<label for="person_interest_id_4">Math</label>

<input type="checkbox" name="person[interest_id][]" value="1" id="person_interest_id_1">
<label for="person_interest_id_1">Science</label>

<input type="checkbox" name="person[interest_id][]" value="2" id="person_interest_id_2">
<label for="person_interest_id_2">Technology</label>
```

[`collection_check_boxes`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-collection_check_boxes

ファイルのアップロード
---------------

ファイルのアップロードはフォームでよく行われるタスクの1つです（アバター画像のアップロードや、処理したいCSVファイルのアップロードなど）。[`file_field`][]ヘルパーを使えば、以下のようにファイルアップロード用フィールドをレンダリングできます。

```erb
<%= form_with model: @person do |form| %>
  <%= form.file_field :csv_file %>
<% end %>
```

ファイルアップロードで忘れてはならない重要な点は、レンダリングされるフォームの`enctype`属性を**必ず**`multipart/form-data`に設定しておかなければならない点です。これは、以下のように`form_with`の内側で`file_field_tag`ヘルパーを使えば自動で行われます。`enctype`属性は手動でも設定できます。

```erb
<%= form_with url: "/uploads", multipart: true do |form| %>
  <%= file_field_tag :csv_file %>
<% end %>
```

どちらの場合も、出力されるHTMLフォームは以下のようになります。

```html
<form enctype="multipart/form-data" action="/people" accept-charset="UTF-8" method="post">
  <!-- ... -->
</form>
```

なお、`form_with`の規約によって、上述の2つのフィールド名が異なっている点にご注意ください。つまり前者のフォームではフィールド名が`person[csv_file]`になり（`params[:person][:csv_file]`でアクセス可能）、後者のフォームでは単なる`csv_file`になります（`params[:csv_file]`でアクセス可能）。

[`file_field`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-file_field

### CSVファイルのアップロード例

`file_field`を使う場合、`params`ハッシュ内のオブジェクトは [`ActionDispatch::Http::UploadedFile`][]のインスタンスです。アップロードされたCSVファイルのデータをアプリケーションのレコードに保存する方法の例を次に示します。

```ruby
  require 'csv'

  def upload
    uploaded_file = params[:csv_file]
    if uploaded_file.present?
      csv_data = CSV.parse(uploaded_file.read, headers: true)
      csv_data.each do |row|
        # Process each row of the CSV file
        # SomeInvoiceModel.create(amount: row['Amount'], status: row['Status'])
        Rails.logger.info row.inspect
        #<CSV::Row "id":"po_1KE3FRDSYPMwkcNz9SFKuaYd" "Amount":"96.22" "Created (UTC)":"2022-01-04 02:59" "Arrival Date (UTC)":"2022-01-05 00:00" "Status":"paid">
      end
    end
    # ...
  end
```

ファイルをモデルと一緒に保存する必要がある画像（ユーザーのプロフィール写真など）である場合、ファイルの保存場所（ディスク、Amazon S3 など）、画像ファイルのサイズ変更、サムネイルの生成など、考慮すべきタスクがいくつかあります。[Active Storage](active_storage_overview.html)は、このようなタスクを支援するように設計されています。

[`ActionDispatch::Http::UploadedFile`]: https://api.rubyonrails.org/classes/ActionDispatch/Http/UploadedFile.html

フォームビルダーをカスタマイズする
-------------------------

`form_with`や`fields_for`によって生成されるオブジェクトは、フォームビルダーと呼ばれます。フォームビルダーは[`ActionView::Helpers::FormBuilder`][]のインスタンスであり、フォームビルダーを使うことで、モデル要素に関連付けられているフォーム要素を生成できます。このクラスは、アプリケーションにカスタムヘルパーを追加する形で拡張可能です。

たとえば、アプリケーション全体で`text_field`と`label`を表示する場合は、以下のヘルパーメソッドを`application_helper.rb`に追加できます。

```ruby
module ApplicationHelper
  def text_field_with_label(form, attribute)
    form.label(attribute) + form.text_field(attribute)
  end
end
```

以下のように、このヘルパーを通常通りにフォーム内で利用します。

```erb
<%= form_with model: @person do |form| %>
  <%= text_field_with_label form, :first_name %>
<% end %>
```

ただし、`ActionView::Helpers::FormBuilder`のサブクラスを作成し、そこにヘルパーを追加することも可能です。この`LabellingFormBuilder`サブクラスを以下のように定義します。

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    # superは元のtext_fieldメソッドを呼び出す
    label(attribute) + super
  end
end
```

先ほどのフォームは以下で置き換え可能です。

```erb
<%= form_with model: @person, builder: LabellingFormBuilder do |form| %>
  <%= form.text_field :first_name %>
<% end %>
```

このクラスを頻繁に再利用する場合は、以下のように`labeled_form_with`ヘルパーを定義して`builder: LabellingFormBuilder`オプションを自動的に適用してもよいでしょう。

```ruby
module ApplicationHelper
  def labeled_form_with(**options, &block)
    options[:builder] = LabellingFormBuilder
    form_with(**options, &block)
  end
end
```

`form_with`の代わりに以下の書き方も可能です。

```erb
<%= labeled_form_with model: @person do |form| %>
  <%= form.text_field :first_name %>
<% end %>
```

上記の3つのケース（`text_field_with_label`ヘルパー、`LabellingFormBuilder`サブクラス、および`labeled_form_with`ヘルパー）は、いずれも以下のように同じHTML出力を生成します。

```html
<form action="/people" accept-charset="UTF-8" method="post">
  <!-- ... -->
  <label for="person_first_name">First name</label>
  <input type="text" name="person[first_name]" id="person_first_name">
</form>
```

ここで使われているフォームビルダーは、以下のコードが実行された時の動作も決定します。

```erb
<%= render partial: f %>
```

`f`が`ActionView::Helpers::FormBuilder`のインスタンスである場合、このコードは`form`パーシャルを生成し、そのパーシャルオブジェクトをフォームビルダーに設定します。このフォームビルダーのクラスが`LabellingFormBuilder`の場合 、代わりに`labelling_form`パーシャルがレンダリングされます。

`LabellingFormBuilder`などのフォームビルダーのカスタマイズでは、実装の詳細が隠蔽されます（上記の単純な例ではやり過ぎのように思えるかもしれません）。フォームでカスタム要素をどの程度頻繁に利用するかに応じて、`FormBuilder`クラスを拡張するか、ヘルパーを作成するかなど、さまざまなカスタマイズから選択することになります。

[`ActionView::Helpers::FormBuilder`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html

フォーム入力の命名規約と`params`ハッシュ
------------------------------------------

これまで説明したフォームヘルパーはすべて、ユーザーがさまざまなタイプの入力を行えるフォーム要素のHTMLを生成するのに役立ちます。ユーザー入力値にコントローラー側でアクセスするにはどうすればよいでしょうか。その答えが`params`ハッシュです。`params`ハッシュについては、上記の例で既に確認しました。このセクションでは、フォーム入力が`params`ハッシュでどのように構造化されるかという命名規約について、より具体的に説明します。

`params`ハッシュには、配列や、ハッシュの配列を含めることが可能です。値は、`params`ハッシュの最上位レベルに置くことも、別のハッシュにネストすることも可能です。たとえば、Personモデルの標準の`create`アクションでは、`params[:person]`は`Person`オブジェクトのすべての属性のハッシュになります。

HTMLフォーム自体にはユーザー入力データに対する固有の構造が定められておらず、生成されるのは名前と値の文字列のペアだけであることにご注意ください。アプリケーションで表示される配列やハッシュは、Railsで利用するパラメータ命名規約の結果です。

NOTE: `params`ハッシュ内のフィールドは、[コントローラで許可](#コントローラでパラメータを許可する) しておく必要があります。

### 基本構造

ユーザー入力フォームデータの基本的な2つの構造は、配列とハッシュです。

ハッシュには、`params`の値にアクセスするための構文が反映されます。たとえば、フォームに次の内容が含まれている場合は以下のようになります。

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

このとき、`params`ハッシュの内容は以下のようになります。

```ruby
{ 'person' => { 'name' => 'Henry' } }
```

コントローラ内で`params[:person][:name]`でアクセスすると、送信された値を取り出せます。

ハッシュは、以下のように必要に応じて何階層でもネストできます。

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

上のコードによってできる`params`ハッシュは以下のようになります。

```ruby
{ 'person' => { 'address' => { 'city' => 'New York' } } }
```

もう1つの構造は配列です。通常、Railsは重複するパラメータ名を無視しますが、パラメータ名が空の角かっこ`[]`で終わる場合、パラメータは配列に蓄積されます。

たとえば、ユーザーが複数の電話番号を入力できるようにするには、フォームに次のコードを配置します。

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

これにより、`params[:person][:phone_number]`は送信された電話番号の配列になります。

```ruby
{ 'person' => { 'phone_number' => ['555-0123', '555-0124', '555-0125'] } }
```

### 配列とハッシュの組み合わせ

ハッシュの配列も利用できます。たとえば、フォームで以下のコード片を繰り返すことで、任意の個数の住所を作成できます。

```html
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
```

これにより、ハッシュの配列`params[:person][:addresses]`が得られます。配列内の各ハッシュには、次のようなキー`line1`、`line2`、および`city`が含まれます。

```ruby
{ 'person' =>
  { 'addresses' => [
    { 'line1' => '1000 Fifth Avenue',
      'line2' => '',
      'city' => 'New York'
    },
    { 'line1' => 'Calle de Ruiz de Alarcón',
      'line2' => '',
      'city' => 'Madrid'
    }
    ]
  }
}
```

ここで注意が必要なのは、ハッシュはいくらでもネストできますが、配列は1階層しか使えない点です。配列はたいていの場合ハッシュで置き換えられます。たとえば、モデルオブジェクトの配列の代わりに、モデルオブジェクトのハッシュを使えます。このキーではid、配列インデックスなどのパラメータが利用できます。

WARNING: 配列パラメータは、`check_box`ヘルパーとの相性がよくありません。HTMLの仕様では、オンになっていないチェックボックスからは値が送信されません。しかし、チェックボックスから常に値が送信される方が何かと便利です。そこで`check_box`ヘルパーでは、同じ名前で予備の隠し入力を作成しておき、本来送信されないはずのチェックボックス値が見かけ上送信されるようになっています。チェックボックスがオフになっていると隠し入力値だけが送信され、チェックボックスがオンになっていると本来のチェックボックス値と隠し入力値が両方送信されますが、このとき優先されるのは本来のチェックボックス値の方です。この隠しフィールドを省略したい場合は、`include_hidden`オプションを`false`に設定できます（デフォルトでは`true`）。

### 添字付きのハッシュ

たとえば、各個人の住所に対応するフィールドのセットを持つフォームをレンダリングしたいとします。こんなときは[`fields_for`][]ヘルパーと、ハッシュの添字を指定する`:index`オプションが便利です。

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

この個人が2つの住所を持っていて、idがそれぞれ23と45だとすると、上のフォームから以下のようなHTMLが出力されます。

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
{
  "person" => {
    "name" => "Bob",
    "address" => {
      "23" => {
        "city" => "Paris"
      },
      "45" => {
        "city" => "London"
      }
    }
  }
}
```

フォームビルダーの`person_form`で`fields_for`を呼び出したので、フォームのすべてのinputは`"person"`ハッシュに対応付けられます。また、`index: address.id`を指定することで、各都市のinputの`name`属性を`person[address][city]`ではなく`person[address][#{address.id}][city]`としてレンダリングしています。このように、`params`ハッシュを処理する際に、どのAddressレコードを変更すべきかを決定可能になります。

`fields_for`で添字を利用する`index`オプションについて詳しくは、[APIドキュメント][`fields_for`]を参照してください。

[`fields_for`]: https://api.rubyonrails.org/v7.1.3.4/classes/ActionView/Helpers/FormHelper.html#method-i-fields_for

複雑なフォームを作成する
----------------------

アプリケーションが大きくなるにつれて、単一オブジェクトの編集を超える複雑なフォームを作成しなければならなくなる場合があります。たとえば、`Person`を作成するときに、ユーザーが同じフォーム内に複数の`Address`レコード（自宅、職場など）を作成できます。後でユーザーが`Person`レコードを編集するときに、住所を追加・削除・更新できるようにしておく必要もあります。

### モデルをネステッド属性用に構成する

特定のモデル（この場合は`Person`）に関連付けられているレコードを編集するために、Active Recordは [`accepts_nested_attributes_for`][]メソッドを介したモデルレベルのサポートを提供します。

```ruby
class Person < ApplicationRecord
  has_many :addresses, inverse_of: :person
  accepts_nested_attributes_for :addresses
end

class Address < ApplicationRecord
  belongs_to :person
end
```

上のコードによって`addresses_attributes=`メソッドが`Person`モデル上に作成され、これを用いて住所の作成、更新、および削除を行なえます。

[`accepts_nested_attributes_for`]: https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for

### ネストしたフォームをビューに追加する

ユーザーは以下のフォームを用いて`Person`とそれに関連する複数の住所を作成できます。

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

関連付けにネステッド属性が渡されると、`fields_for`ヘルパーは関連付けの要素ごとにブロックを1回ずつレンダリングします。特に、`Person`に住所が登録されていない場合は何もレンダリングされません。

フィールドのセットが1個以上ユーザーに表示されるように、コントローラで1つ以上の空白の子要素を作成しておくというのはよく行われるパターンです。以下の例では、新しいPersonフォームに2組みの住所フィールドがレンダリングされます。

たとえば、上記の`form_with`に以下の変更を加えたとします。

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build }
end
```

上のコードによって以下のHTMLが出力されます。

```html
<form action="/people" accept-charset="UTF-8" method="post"><input type="hidden" name="authenticity_token" value="lWTbg-4_5i4rNe6ygRFowjDfTj7uf-6UPFQnsL7H9U9Fe2GGUho5PuOxfcohgm2Z-By3veuXwcwDIl-MLdwFRg" autocomplete="off">
  Addresses:
  <ul>
      <li>
        <label for="person_addresses_attributes_0_kind">Kind</label>
        <input type="text" name="person[addresses_attributes][0][kind]" id="person_addresses_attributes_0_kind">

        <label for="person_addresses_attributes_0_street">Street</label>
        <input type="text" name="person[addresses_attributes][0][street]" id="person_addresses_attributes_0_street">
        ...
      </li>

      <li>
        <label for="person_addresses_attributes_1_kind">Kind</label>
        <input type="text" name="person[addresses_attributes][1][kind]" id="person_addresses_attributes_1_kind">

        <label for="person_addresses_attributes_1_street">Street</label>
        <input type="text" name="person[addresses_attributes][1][street]" id="person_addresses_attributes_1_street">
        ...
      </li>
  </ul>
</form>
```

`fields_for`ヘルパーはフォームフィールドを1つ生成します。`accepts_nested_attributes_for`ヘルパーが受け取るのはこのようなパラメータの名前です。たとえば、2つの住所を持つユーザーを1人作成する場合、送信される`params`内のパラメータは以下のようになります。

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

この`:address_attributes`ハッシュのキーの実際の値は重要ではありませんが、アドレスごとに異なる整数の文字列である必要があります。

関連付けられたオブジェクトが既に保存されている場合、`fields_for`メソッドは、保存されたレコードの`id`を持つ隠し入力を自動生成します。`fields_for`に`include_id: false`を渡すことでこの自動生成をオフにできます。

```ruby
{
  'person' => {
    'name' => 'John Doe',
    'addresses_attributes' => {
      '0' => {
        'id' => 1,
        'kind' => 'Home',
        'street' => '221b Baker Street'
      },
      '1' => {
        'id' => '2',
        'kind' => 'Office',
        'street' => '31 Spooner Street'
      }
    }
  }
}
```

### コントローラでパラメータを許可する

コントローラ内でパラメータをモデルに渡す前に、いつもと同様にコントローラ内で[パラメータの許可リストチェック](action_controller_overview.html#strong-parameters)を宣言する必要があります。

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

### 関連付けられているオブジェクトを削除する

`accepts_nested_attributes_for`に`allow_destroy: true`を渡すと、関連付けられているオブジェクトをユーザーが削除することを許可できます。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

あるオブジェクトの属性のハッシュに、キーが`_destroy`で、値が`true`と評価可能（`1`、`'1'`、`true`、`'true'`など）な組み合わせがあると、そのオブジェクトは破棄されます。以下のフォームではユーザーが住所を削除可能です。

```erb
<%= form_with model: @person do |form| %>
  Addresses:
  <ul>
    <%= form.fields_for :addresses do |addresses_form| %>
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

`_destroy`フィールドのHTMLは以下のようになります。

```html
<input type="checkbox" value="1" name="person[addresses_attributes][0][_destroy]" id="person_addresses_attributes_0__destroy">
```

このとき、コントローラ内でパラメータの許可リストを以下のように更新して、`_destroy`フィールドが必ずパラメータに含まれるようにしておく必要もあります。

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 空のレコードができないようにする

ユーザーが何も入力しなかったフィールドを無視できれば何かと便利です。これは、`:reject_if` procを`accepts_nested_attributes_for`に渡すことで制御できます。このprocは、フォームから送信された属性にあるハッシュごとに呼び出されます。このprocが`true`を返す場合、Active Recordはそのハッシュに関連付けられたオブジェクトを作成しません。以下の例では、`kind`属性が設定されている場合にのみ住所オブジェクトを生成します。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda { |attributes| attributes['kind'].blank? }
end
```

代わりにシンボル`:all_blank`を渡すこともできます。このシンボルが渡されると、`_destroy`の値を除くすべての属性が空白レコードを受け付けなくなるprocが1つ生成されます。

外部リソース用のフォーム
---------------------------

外部リソースに何らかのデータを渡す必要がある場合も、Railsのフォームヘルパーを用いてフォームを作成する方がやはり便利です。外部APIに対して`authenticity_token`を設定することが期待されている場合は、以下のように`form_with`に`authenticity_token: '外部トークン'`パラメータを渡すことで実現できます。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

場合によっては、フォームで利用可能なフィールドが外部APIによって制限されていて、`authenticity_token`隠しフィールドを生成すると不都合が生じることがあります。トークンを**送信しない**ようにするには、以下のように`:authenticity_token`オプションに`false`を渡します。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

フォームビルダーなしで利用できるタグヘルパー
----------------------------------------

フォームのフィールドをフォームビルダーのコンテキストの外でレンダリングする必要が生じたときのために、よく使われるフォーム要素を生成するタグヘルパーを提供しています。たとえば、[`check_box_tag`][]は以下のように使えます。

```erb
<%= check_box_tag "accept" %>
```

上のコードから以下のHTMLが生成されます。

```html
<input type="checkbox" name="accept" id="accept" value="1" />
```

一般に、これらのヘルパー名は、フォームビルダーのヘルパー名の末尾に`_tag`を追加したものになります。完全なリストについては、[`FormTagHelper`][] APIドキュメントを参照してください。

[`check_box_tag`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-check_box_tag
[`FormTagHelper`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html

`form_tag`や`form_for`の利用について
-------------------------------

Rails 5.1で`form_with`が導入されるまでは、`form_with`の機能は[`form_tag`][]と[`form_for`][]に分かれていました。`form_tag`および`form_for`は、禁止ではないものの、利用は推奨されていません。現在は`form_with`の利用が推奨されています。

[`form_tag`]: https://api.rubyonrails.org/v5.2/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag
[`form_for`]: https://api.rubyonrails.org/v5.2/classes/ActionView/Helpers/FormHelper.html#method-i-form_for
