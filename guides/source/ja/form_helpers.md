**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Action View フォームヘルパー
============

Webアプリケーションにおけるフォームは、ユーザー入力を扱うのに不可欠なインターフェイスです。しかしフォームのコントロールの命名法や大量の属性を扱わなければならず、フォームのマークアップは作成もメンテナンスも退屈な作業になりがちです。そこでRailsでは、フォームのマークアップを生成するビューヘルパーを提供し、こうした煩雑な作業を行わないで済むようにしました。しかしながら現実のユースケースはさまざまであるため、開発者はこれらを実際に使う前に、これらのよく似たヘルパーメソッド群にどのような違いがあるのかをすべて把握しておく必要があります。

このガイドの内容:

* 検索フォーム、および特定のモデルを表さない一般的なフォームの作成法
* 特定のデータベースレコードの作成編集を行なう、モデル中心のフォーム作成法
* 複数の種類のデータからセレクトボックスを生成する方法
* Railsが提供する日付時刻関連ヘルパー
* ファイルアップロード用フォームの動作を変更する方法
* 外部リソース向けにフォームを作成する方法
* 複雑なフォームの作成方法

--------------------------------------------------------------------------------

NOTE: このガイドはフォームヘルパーとその引数について網羅的に説明するものではありません。完全なリファレンスについては[Rails APIドキュメント](https://api.rubyonrails.org/)を参照してください。

基本的なフォームを作成する
------------------------

最も基本的なフォームヘルパは`form_tag`です。

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

`form_tag`は、上のように引数なしで呼び出されると`<form>`タグを生成します。このフォームを現在のページに送信するときにはHTTPのPOSTメソッドが使われます。たとえば現在のページが`/home/index`の場合、以下のようなHTMLが生成されます (読みやすくするため改行を追加してあります)。

```html
<form accept-charset="UTF-8" action="/" data-remote="true" method="post">
  <input name="authenticity_token" type="hidden" value="J7CBxfHalt49OSHp27hblqK20c9PgwJ108nDHX/8Cts=" />
  Form contents
</form>
```

上のHTMLには、種類が`hidden`の`input`要素があることにお気づきでしょうか。この`input`はとても重要です。理由は、これがないとGETでないフォームは送信できないからです。
`authenticity_token`という名前の隠し要素は、**クロスサイトリクエストフォージェリ（CSRF）保護**と呼ばれるRailsのセキュリティ機能であり、GETでないあらゆるフォームではフォームヘルパーによってこの要素が生成されます（このセキュリティ機能が無効にされていない場合）。詳しくは[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ-csrf)を参照してください。

### 一般的な検索フォーム

検索フォームはWebでよく使われています。検索フォームには以下のものが含まれています。

* GETメソッドを送信するためのフォーム要素
* 入力するものを示すラベル
* テキスト入力要素
* 「送信」ボタン要素

検索フォームの作成には、`form_tag`、`label_tag`、`text_field_tag`、`submit_tag`を使います。以下に例を示します。

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form accept-charset="UTF-8" action="/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <label for="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

TIP: どのフォームinputを使う場合でも、id属性はinputの`name`から生成されます (上の例では「q」)。これらのidは、cssでのスタイル追加やJavaScriptによるフォーム制御で使うのに便利です。

HTMLの**すべての**フォームコントロールには、`text_field_tag`や`submit_tag`と同様の便利なヘルパーが用意されています。

IMPORTANT: フォームを検索に使う場合は**必ずGETメソッドをお使いください**。こうすることで検索クエリがURLの一部となり、ユーザーが検索結果をブックマークしておけば、後でブックマークから同じ検索を実行できます。Railsでは基本的に、常にアクションに対応する適切なHTTP verbを選んでください (訳注: セキュリティガイドにも記載されていますが、たとえば更新フォームでGETメソッドを使うと重大なセキュリティホールが生じます)。

### フォーム要素生成に使うヘルパー

Railsには、チェックボックス/テキストフィールド/ラジオボタンなどのフォーム要素を生成するためのヘルパーが多数用意されています。これらの基本的なヘルパーは名前が`_tag`で終わっており (`text_field_tag`や`check_box_tag`など)、それぞれただ1つの`<input>`要素を生成します。これらのヘルパーの1番目のパラメータは、inputの名前と決まっています。フォームが送信されると、この名前がフォームデータに含まれて渡され、ユーザーが入力した値とともに、コントローラ内で`params`となってアクセス可能になります。たとえば、フォームに`<%= text_field_tag(:query) %>`というコードが含まれていたとすると、コントローラで`params[:query]`と指定すればこのフィールドの値にアクセスできます。

Railsは、一定のルールに従ってinputに名前を与えています。これにより、配列やハッシュのような「非スカラー値」のパラメータをフォームから送信できるようになり、コントローラで`params`としてアクセスできます。詳しくは[本ガイドの7章](#パラメータの命名ルールを理解する)を参照してください。これらのヘルパーの正確な利用法については[APIドキュメント](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html)を参照してください。

#### チェックボックス

チェックボックスはフォームコントロールの一種で、ユーザーがオプションをオンまたはオフにできるようにします。

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

上のコードによって以下が生成されます。

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label for="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label for="pet_cat">I own a cat</label>
```

`check_box_tag`の最初のパラメータは、言うまでもなくinputの名前です。2番目のパラメータは、input(タグ)のvalue属性になります。チェックボックスをオンにすると、この値はフォームデータに含まれ、最終的に`params`に渡されます。

#### ラジオボタン

チェックボックスと同様、ラジオボタンでも一連のオプションをユーザーが選択できますが、一度に1つの項目しか選択できない排他的な動作が特徴です。

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

出力は以下のようになります。

```html
<input id="age_child" name="age" type="radio" value="child" />
<label for="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label for="age_adult">I'm over 21</label>
```

`check_box_tag`ヘルパーのときと同様、`radio_button_tag`の2番目のパラメータがinput(タグ)のvalue属性になります。2つのラジオボタン項目は同じ名前 ('age') を共有しているので、ユーザーはどちらかの値だけを選択できます。そして`params[:age]`の値は"child"と"adult"のどちらかになります。

NOTE: チェックボックスとラジオボタンには必ずラベルを表示してください。ラベルを表示することで、そのオプションとラベルの名前が関連付けられるだけでなく、ラベルの部分までクリック可能になるのでユーザーにとってクリックしやすくなります。

### その他のヘルパー

これまで紹介した他にも、次のようなフィールドがあります: テキストエリア、パスワード、隠しフィールド、検索フィールド、電話番号フィールド、日付フィールド、時刻フィールド、色フィールド、ローカル日時フィールド、月フィールド、週フィールド、URLフィールド、メールアドレスフィールド、数値フィールド、範囲フィールド。

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag(:password) %>
<%= hidden_field_tag(:parent_id, "5") %>
<%= search_field(:user, :name) %>
<%= telephone_field(:user, :phone) %>
<%= date_field(:user, :born_on) %>
<%= datetime_local_field(:user, :graduation_day) %>
<%= month_field(:user, :birthday_month) %>
<%= week_field(:user, :birthday_week) %>
<%= url_field(:user, :homepage) %>
<%= email_field(:user, :address) %>
<%= color_field(:user, :favorite_color) %>
<%= time_field(:task, :started_at) %>
<%= number_field(:product, :price, in: 1.0..20.0, step: 0.5) %>
<%= range_field(:product, :discount, in: 1..100) %>
```

上の出力は以下のようになります。

```html
<textarea id="message" name="message" cols="24" rows="6">Hi, nice site</textarea>
<input id="password" name="password" type="password" />
<input id="parent_id" name="parent_id" type="hidden" value="5" />
<input id="user_name" name="user[name]" type="search" />
<input id="user_phone" name="user[phone]" type="tel" />
<input id="user_born_on" name="user[born_on]" type="date" />
<input id="user_graduation_day" name="user[graduation_day]" type="datetime-local" />
<input id="user_birthday_month" name="user[birthday_month]" type="month" />
<input id="user_birthday_week" name="user[birthday_week]" type="week" />
<input id="user_homepage" name="user[homepage]" type="url" />
<input id="user_address" name="user[address]" type="email" />
<input id="user_favorite_color" name="user[favorite_color]" type="color" value="#000000" />
<input id="task_started_at" name="task[started_at]" type="time" />
<input id="product_price" max="20.0" min="1.0" name="product[price]" step="0.5" type="number" />
<input id="product_discount" max="100" min="1" name="product[discount]" type="range" />
```

隠しinputはユーザーには表示されず、種類を問わず事前に与えられた値を保持します。隠しフィールドに含まれている値はJavaScriptで変更できます。

IMPORTANT: 「検索、電話、日付、時刻、色、日時、ローカル日時、月、週、URL、メールアドレス、数値、範囲」フィールドはHTML5から利用できるようになったコントロールです。
これらのフィールドを古いブラウザでも同じように扱いたいのであれば、CSSやJavaScriptを用いるHTML5ポリフィルが必要になるでしょう。
古いブラウザでHTML5に対応する方法は[山ほどあります](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills)が、現時点で代表的なものは[Modernizr](http://www.modernizr.com/)でしょう。これらは、HTML5の新機能が使われていることが検出された場合に、機能を追加するためのシンプルな方法を提供します。

TIP: パスワード入力フィールドを使っているのであれば、入力されたパスワードをRailsのログに残さないようにしたいと思うことでしょう。その方法については[セキュリティガイド](security.html#ログ出力)を参照してください。

モデルオブジェクトを扱う
--------------------------

### モデルオブジェクトヘルパー

フォームの主な仕事といえば、モデルオブジェクトの作成および修正でしょう。`*_tag`ヘルパーをモデルオブジェクトの作成/修正に用いることはもちろん可能ですが、1つ1つのタグについて正しいパラメータが使われているか、入力のデフォルト値は適切に設定されているかなどをいちいちコーディングするのは何とも面倒です。Railsにはまさにこのような作業を軽減するのにうってつけのヘルパーがあります。なお、これらのヘルパー名には`_tag`が付いていません (`text_field`、`text_area`など)

これらのヘルパーの最初の引数はインスタンス変数名、2番目の引数はオブジェクトを呼び出すためのメソッド名 (通常は属性名を使います)です。Railsは、オブジェクトのそのメソッドから値が返され、かつ適切な入力名が設定されるように、入力コントロールの値を設定してくれます。たとえば、コントローラで`@person`が定義されており、その人物の名前がHenryだとします。

```erb
<%= text_field(:person, :name) %>
```

このとき、上のコードからは以下のような出力が得られます。

```erb
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

このフォームを送信すると、ユーザーが入力した値は`params[:person][:name]`に保存されます。

WARNING: ヘルパーに渡すのはインスタンス変数の「名前」でなければなりません (シンボル`:person`や文字列`"person"`など)。渡すのはモデルオブジェクトのインスタンスそのものではありません。

Railsのヘルパーには、モデルオブジェクトに関連するバリデーション (検証) エラーを自動的に表示する機能もあります。詳細については本ガイドの[Active Record検証 (バリデーション)](active_record_validations.html#バリデーションエラーをビューで表示する)を参照してください。

### フォームとオブジェクトを結び付ける

上のやり方でだいぶコーディングが楽になりましたが、改善の余地はまだまだあります。Personモデルに多数の属性があると、編集されたオブジェクトの名前を何度も繰り返さなければなりません。もっと楽に、フォームとモデルオブジェクトを結び付けるだけで簡単に作れないものでしょうか。`form_with`と`model:`はまさにそのためにあるのです。

記事を扱うArticlesコントローラ`app/controllers/articles_controller.rb`があるとします。

```ruby
def new
  @article = Article.new
end
```

上のコントローラに対応するビュー`app/views/articles/new.html.erb`で`form_with`を使うと、以下のような感じになります。

```erb
<%= form_with model: @article, class: "nifty_form" do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

以下の点にご注目ください。

* `@article`は、実際に編集されるオブジェクトそのものです。
* オプションに使うハッシュが1つあります。ルーティングオプションが`:url`ハッシュで渡され、HTMLオプションが`:html`ハッシュで渡されています。フォームで`:namespace`オプションを使うことで、フォーム要素上のid属性同士が衝突しないようにすることもできます。この名前空間属性の値は、生成されたHTMLのid属性の先頭にアンダースコア付きで追加されます。
* `form_with`メソッドからは **フォームビルダー** オブジェクト(ここでは変数`f`)が生成されます。
* フォームのリクエストを特定のURLに送信したい場合は、代わりに`form_with url: my_nifty_url_path`をお使いください。`form_with`に渡せるオプションについてもっと詳しく知りたい場合は、ぜひ[APIドキュメント](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with)をご覧ください。
* フォームコントロールを作成するメソッドは、 **フォームビルダーオブジェクト`f`に対して** 呼び出されます。

これにより、以下のHTMLが生成されます。

```html
<form class="nifty_form" action="/articles" accept-charset="UTF-8" data-remote="true" method="post">
  <input type="hidden" name="authenticity_token" value="NRkFyRWxdYNfUg7vYxLOp2SLf93lvnl+QwDWorR42Dp6yZXPhHEb6arhDOIWcqGit8jfnrPwL781/xlrzj63TA==" />
  <input type="text" name="article[title]" id="article_title" />
  <textarea name="article[body]" id="article_body" cols="60" rows="12"></textarea>
  <input type="submit" name="commit" value="Create" data-disable-with="Create" />
</form>
```

`form_with`に`:model`で渡される名前は、`params`を使ってフォームの値にアクセスするときのキーに影響します。たとえば、この名前が`article`だとすると、すべての入力は`article[属性名]`というフォーム名を持ちます。従って`create`アクションでは、`:title`キーと`:body`キーを持つ1つのハッシュが`params[:article]`に含まれることになります。input名の重要性については、[パラメータの命名ルールを理解する](#パラメータの命名ルールを理解する)を参照してください。

TIP: 入力フィールド名はモデルの属性を踏まえた名前にするのが慣例ですが、これは実は必須ではありません。フォームに含める必要のある情報が他にもある場合は、その属性に`params[:article][:属性でない入力項目名]`のようにアクセスすればよいのです。

フォームビルダー変数に対して呼び出されるヘルパーメソッドは、モデルオブジェクトのヘルパーメソッドと同一です。ただし、フォームの場合は編集の対象となるオブジェクトが既にフォームビルダーで管理されているので、どのオブジェクトを編集するかを指定する必要がない点が異なります。

`fields_for`メソッドを使うと、`<form>`タグを実際に作成せずに同様のバインディングを設定できます。これは、同じフォームで別のモデルオブジェクトも編集できるようにしたい場合などに便利です。たとえば、Personモデルに関連付けられているContactDetailモデルがあるとすると、以下のようなフォームを作成すればよいのです。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for :contact_detail, @person.contact_detail do |contact_detail_form| %>
    <%= contact_detail_form.text_field :phone_number %>
  <% end %>
<% end
```

上のコードから以下の出力が得られます。

```html
<form action="/people" accept-charset="UTF-8" data-remote="true" method="post">
  <input type="hidden" name="authenticity_token" value="bL13x72pldyDD8bgtkjKQakJCpd4A8JdXGbfksxBDHdf1uC0kCMqe2tvVdUYfidJt0fj3ihC4NxiVHv8GVYxJA==" />
  <input type="text" name="person[name]" id="person_name" />
  <input type="text" name="contact_detail[phone_number]" id="contact_detail_phone_number" />
</form>
```

`fields_for`によって生成されたオブジェクトはフォームビルダーであり、`form_with`で生成されたものと似ています。

### レコード識別を利用する

これでArticleモデルをユーザーが直接操作できるようになりました。Rails開発で次に行なうべき最善の方法は、これを **リソース** として宣言することです。

```ruby
resources :articles
```

TIP: リソースを宣言すると、自動的に他にも多くの設定が行われます。リソースの設定方法の詳細については、[Railsルーティングガイド](routing.html#リソースベースのルーティング-railsのデフォルト)を参照してください。

RESTfulなリソースを扱っている場合、レコード識別(record identification)を使うと`form_with`の呼び出しがはるかに簡単になります。これは、モデルのインスタンスを渡すだけで、後はRailsがそこからモデル名など必要なものを取り出して処理してくれるというものです。

```ruby
## 新しい記事の作成
# 長いバージョン
form_with(model: @article, url: articles_path)
# 短いバージョン(レコード識別を利用)
form_with(model: @article)

## 既存の記事の修正
# 長いバージョン
form_with(model: @article, url: article_path(@article), method: "patch")
# 短いバージョン
form_with(model: @article)
```

この短い`form_with`呼び出しは、レコードの作成・編集のどちらでもまったく同じです。これがどれほど便利であるかおわかりいただけると思います。レコード識別は、レコードが新しい場合には`record.new_record?`が必要とされている、などの適切な推測を行ってくれます。さらに送信用の正しいパスを選択し、オブジェクトのクラスに基づいた名前も選択してくれます。

WARNING: モデルで単一テーブル継承(STI: single-table inheritance)を使っている場合、親クラスでリソースが宣言されていてもサブクラスでレコード識別を利用することはできません。その場合は、モデル名、`:url`、`:scope`を明示的に指定する必要があります。

#### 名前空間を扱う

名前空間付きのルーティングを作成してある場合、`form_with`でもこれを利用した簡潔な表記を利用できます。アプリケーションのルーティングでadmin名前空間が設定されているとします。

```ruby
form_with model: [:admin, @article]
```

上のコードはそれによって、admin名前空間内にある`ArticlesController`に送信を行なうフォームを作成します (たとえば更新の場合は`admin_article_path(@article)`に送信されます)。名前空間が多段階層になっている場合にも同様の文法が使えます。

```ruby
form_with model: [:admin, :management, @article]
```

Railsのルーティングシステムの詳細と、関連するルールについては[ルーティングガイド](routing.html)を参照してください。

### フォームにおけるPATCH・PUT・DELETEメソッドの動作

Railsのフレームワークは、開発者がアプリケーションをRESTfulなデザインで構築するように働きかけています。すなわち、開発者はGETやPOSTリクエストだけでなく、PATCHやDELETEリクエストをたくさん作成・送信することになります。しかしながら、現実には多くのブラウザはフォーム送信時にGETとPOST以外のHTTPメソッドを**サポートしていません**。

そこでRailsでは、POSTメソッド上でこれらのメソッドをエミュレートすることによってこの問題を解決しています。具体的には、`"_method"`という名前の隠し入力をフォームに用意し、使いたいメソッドをここで指定します。

```ruby
form_with(url: search_path, method: "patch")
```

上のコードから以下の出力が得られます。

```html
<form accept-charset="UTF-8" action="/search" data-remote="true" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  ...
</form>
```

Railsは、POSTされたデータを解析する際にこの特殊な`_method`パラメータをチェックし、ここで指定されているメソッド(この場合はPATCH)があたかも実際にHTTPメソッドとして指定されたかのように振る舞います。

IMPORTANT: `form_with`を用いるすべてのフォームでは、デフォルトで`remote: true`が実装されます。このフォームはXHR（Ajax）リクエストの形でデータを送信します。これを無効にするには`local: true`を追加します。詳しくはガイドの[Rails で JavaScript を使用する](working_with_javascript_in_rails.html#remote要素をカスタマイズする)を参照してください。

セレクトボックスを簡単に作成する
-----------------------------

HTMLでセレクトボックスを作成するには大量のマークアップを書かなくてはなりません(選択する1つのオプションに1つの`OPTION`要素が対応します)。従って、このようなマークアップを自動的に生成したいと思うのは自然な流れです。

HTMLマークアップは通常であれば以下のような感じになります。

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  <option value="3">Berlin</option>
</select>
```

ここでは都市の名前が一覧としてユーザーに示されています。アプリケーションの内部では、これらの項目のidを扱えればそれでよいのです。それによってそれらのidがオプションの値属性として使えるようになります。Railsの内部でどのようなことが行われているかを見てみましょう。

### SelectタグとOptionタグ

最も一般的なヘルパーは`select_tag`でしょう。これはその名の通り、オプションの文字列を内包した`SELECT`タグを生成するだけのメソッドです。

```erb
<%= select_tag(:city_id, raw('<option value="1">Lisbon</option><option value="2">Madrid</option><option value="3">Berlin</option>')) %>
```

まずは上のコードを書きますが、これだけではオプションタグは動的生成されません。オプションタグを生成するには`options_for_select`ヘルパーを使います。

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ['Berlin', 3]]) %>
```

上のコードから以下の出力が得られます。

```html
<option value="1">Lisbon</option>
<option value="2">Madrid</option>
<option value="3">Berlin</option>
```

`options_for_select`の最初の引数は入れ子になった配列であり、各要素には「オプションテキスト(city name)」と「オプション値(city id)」があります。オプション値の部分がコントローラに送信されます。送信されるidは、対応するデータベースオブジェクトのidになるのが普通ですが、ここでは必ずしもそうする必要はありません。

ここを理解すれば、`select_tag`と`options_for_select`を組み合わせて望み通りの完全なマークアップを得られます。

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select`では、デフォルトにしたいオプションを値を渡すことでデフォルト値を設定できます。

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ['Berlin', 3]], 2) %>
```

上のコードから以下の出力が得られます。

```html
<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
<option value="3">Berlin</option>
```

生成されるオプション内部の値がこの値とマッチすると、Railsは`selected`属性を自動的にそのオプションに追加します。

ハッシュで任意の値を追加することができます。

```html+erb
<%= options_for_select(
  [
    ['Lisbon', 1, { 'data-size' => '2.8 million' }],
    ['Madrid', 2, { 'data-size' => '3.2 million' }],
    ['Berlin', 3, { 'data-size' => '3.4 million' }]
  ], 2
) %>
```

上のコードから以下の出力が得られます。

```html
<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
<option value="3" data-size="3.4 million">Berlin</option>
```

### モデルを扱うセレクトボックス

フォームコントロールは、ほとんどの場合特定のデータベースと結び付けられので、Railsがそのためのヘルパーを提供してくれることを期待するのは当然です。他のフォームヘルパーのときと同じ要領で、モデルを扱う場合には`select_tag`から`_tag`という接尾語を取り除きます。

たとえばコントローラで`@person`が定義されており、city_idが2だとします。

```ruby
@person = Person.new(city_id: 2)
```

```erb
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ['Berlin', 3]]) %>
```

上のコードからは以下のような出力を得られます。

```html
<select name="person[city_id]" id="person_city_id">
  <option value="1">Lisbon</option>
  <option value="2" selected="selected">Madrid</option>
  <option value="3">Berlin</option>
</select>
```

第3のパラメータであるオプション配列は、`options_for_select`に渡した引数と同じ種類のものです。このオプションのメリットの1つは、ユーザーが既に選択していた街が、選択済みのデフォルト値として正しく表示されるという点です。Railsは`@person.city_id`属性を読み出して自動的に選択してくれるので、開発者は気にする必要はありません。

他のヘルパーの場合と同様、`@person`オブジェクトを対象としたフォームビルダーで`select`ヘルパーを使う場合は、以下のような文法になります。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.select(:city_id, [['Lisbon', 1], ['Madrid', 2], ['Berlin', 3]]) %>
<% end %>
```

`select`ヘルパーにブロックを渡すこともできます。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.select(:city_id) do %>
    <% [['Lisbon', 1], ['Madrid', 2], ['Berlin', 3]].each do |c| %>
      <%= content_tag(:option, c.first, value: c.last) %>
    <% end %>
  <% end %>
<% end %>
```

WARNING: `select`ヘルパー(および類似の`collection_select`ヘルパー)を用いて`belongs_to`関連付けを設定する場合は、関連付けそのものの名前ではなく、必ず外部キーの名前(上の例であれば`city_id`)を渡さなければなりません。

WARNING: `:include_blank`や`:prompt`が指定されていない場合、「selectの`required`属性がtrue」かつ「表示の`size`がひとつ」かつ「`multiple`がtrueでない」場合に`:include_blank`が強制的にtrueになります。

### 任意のオブジェクトのコレクションに対してオプションタグを使う

`options_for_select`でオプションタグを生成する場合、各オプションのテキストと値を含む配列を作成しておく必要があります。仮にCityというモデルがあるとして、それらのオブジェクトのコレクションからオプションタグを生成するにはどうしたらよいでしょうか。ひとつの方法は、コレクションをイテレートしてネストした配列を作成することです。

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

これはこれでまったく正当な方法ですが、Railsにはもっと簡潔な`options_from_collection_for_select`ヘルパーがあります。このヘルパーは、任意のオブジェクトのコレクションの他に2つの引数 ( **value** オプションと **text** オプションをそれぞれ読み出すためのメソッド名) を取ります。

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

その名前が示すとおり、このヘルパーが生成するのはオプションタグだけです。実際に動作するセレクトボックスを生成するには、次のように`collection_select`が必要になります。

```erb
<%= collection_select(:person, :city_id, City.all, :id, :name) %>
```

他のヘルパーと同様、`@person`オブジェクトを対象とするフォームビルダーで`collection_select`ヘルパーを使う場合の構文は以下のようになるでしょう。

```erb
<%= form_with model: @person do |person_form| %>
  <%= person_form.collection_select(:city_id, City.all, :id, :name) %>
<% end %>
```

NOTE: `options_for_select`に渡されるペアでは名前が1番目でidが2番目ですが、`options_from_collection_for_select`の場合は1番目の引数がvalueメソッドで2番目の引数がtextメソッドです。

### タイムゾーンと国を選択する

Railsでタイムゾーンをサポートするために、ユーザーが今どのタイムゾーンにいるのかを何らかの形でユーザーに尋ねなければなりません。そのためには、`collection_select`ヘルパーを使って、事前定義済みの[`ActiveSupport::TimeZone`](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)オブジェクトのリストからセレクトボックスを作成する必要がありますが、実はRailsではこの機能を実現する`time_zone_select`というそれ専用のヘルパーが既に用意されています。

```erb
<%= time_zone_select(:person, :time_zone) %>
```

`time_zone_options_for_select`という類似のヘルパーもあり、こちらではさらにきめ細かい設定を行なえます。これら2つのメソッドに渡せる引数について詳しくは、[APIドキュメント](http://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-time_zone_options_for_select)を参照してください。

**以前の**Railsでは`country_select`ヘルパーで国を選択していましたが、この機能は[country_selectプラグイン](https://github.com/stefanpenner/country_select)に書き出されました。この機能を使う場合、どの国名をリストに含めるべきで、どの国を含めるべきでないかを決める際に政治的な議論が紛糾する可能性がありますので、その点をご了承ください(この機能がプラグイン化された理由も実はそれです)。

日付時刻フォームヘルパーを使う
--------------------------------

HTML5標準の日付/時刻入力フィールドを生成するヘルパーの代りに、別の日付/時刻ヘルパーを使うこともできます。いずれにしろ、日付/時刻ヘルパーは以下の2つの点が他のヘルパーと異なっています。

* 日付と時刻を一度に表す入力要素はありません。そのため、年、月、日などの個別のコンポーネントをいくつも使わなければならず、従って`params`ハッシュ内でも日付時刻は単一の値では表されません。
* 他のヘルパーでは、そのヘルパーが最小限の基本機能を持つ (ベアボーン) ものであるか、あるいはモデルオブジェクトを扱うものであるかを`_tag`接尾語の有無で表します。日付/時刻ヘルパーの場合は、`select_date`、`select_time`、`select_datetime`がベアボーンヘルパーで、`date_select`、`time_select`、`datetime_select`がモデルオブジェクトヘルパーに相当します。

どちらのヘルパーファミリーを使った場合も、年・月・日など、さまざまなコンポーネントのセレクトボックスを同じように作成できます。

### ベアボーンヘルパー

`select_*`で始まる日付/時刻ヘルパーファミリーでは、Date、Time、DateTimeのいずれかのインスタンスを1番目の引数に取り、現在選択中の値として使われます。現在の日付が使われる場合は、次のようにこのパラメータを省略できます。

```erb
<%= select_date Date.today, prefix: :start_date %>
```

上のコードから以下の出力が得られます(簡単のため実際のオプション値を省略しています)。

```html
<select id="start_date_year" name="start_date[year]">
</select>
<select id="start_date_month" name="start_date[month]">
</select>
<select id="start_date_day" name="start_date[day]">
</select>
```

上の入力の結果は`params[:start_date]`に反映され、キーは`:year`、`:month`、`:day`となります。これらの値から実際のTimeオブジェクトやDateオブジェクトを得るには、値を取り出して適切なコンストラクタに渡す必要があります。

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

`:prefix`オプションは、`params`ハッシュから日付コンポーネントのハッシュを取り出すのに使われるキーです。これで`start_date`に設定されました。省略するとデフォルトは`date`に設定されます。

### モデルオブジェクトヘルパー

`select_date`ヘルパーは、Active Recordオブジェクトの更新や作成を行なうフォームでは扱いにくくなっています。Active Recordは、`param`ハッシュに含まれる要素がそれぞれ1つの属性にのみ対応していることを前提としているからです。
日付/時刻用のモデルオブジェクトヘルパーは、特殊な名前のパラメータを送信します。Active Recordがこの特殊な名前を見つけると、その名前が他のパラメータと結び付けられているとみなし、モデルのカラムの種類に合ったコンストラクタが与えられているとみなします。次の例をご覧ください。

```erb
<%= date_select :person, :birth_date %>
```

上のコードから以下の出力が得られます(簡単のため実際のオプション値を省略しています)。

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]">
</select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]">
</select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]">
</select>
```

ここから以下のような`params`ハッシュを得られます。

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

上が`Person.new` (または`Person.update`)に与えられると、Active Recordはこれらのパラメータが`birth_date`属性を構成するために使われなければならないことを理解し、接尾語（suffix）付きの情報を利用します。この情報は、`Date.civil`などの関数にどのような順序でこれらのパラメータを渡さなければならないかを決定するのに使われます。

### 共通のオプション

どちらのヘルパーファミリーでも、個別のセレクトタグを生成するためのコア機能は共通なので、多くのオプションが同じように使えます。特にRailsでは、年のオプションはどちらのファミリーでもデフォルトで現在の年の前後5年が使われます。この範囲が適切でない場合は`:start_year`オプションと`:end_year`オプションを使って上書きできます。利用できるすべてのオプションを知りたい場合は[APIドキュメント](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)を参照してください。

経験則から言うと、モデルオブジェクトを扱う場合は`date_select`を使うべきです。その他の場合、たとえば日付でフィルタするなどの検索フォームで使う場合は`select_date`を使うべきです。

### 個別のコンポーネント

日付のうち、たとえば年だけ、月だけのコンポーネントを表示したいことがあります。Railsでは日付/時刻の個別の要素を扱うための`select_year`、`select_month`、`select_day`、`select_hour`、`select_minute`、`select_second`ヘルパーが用意されています。これらのヘルパーのつくりは比較的単純で、その日付時刻コンポーネントの要素名をそのまま入力フィールド名として生成します。たとえば`select_year`ヘルパーを使うと「year」フィールドが生成され、`select_month`を使うと「month」が生成されるといった具合です。`:field_name`オプションでこの名前をカスタマイズすることもできます。`:prefix`オプションの動作は`select_date`や`select_time`のときと同じで、デフォルト値も同じです。

1番目のパラメータでは、選択されるべきパラメータを指定します。Date、Time、DateTimeのいずれかのインスタンスを指定でき、関連するコンポーネントや数値がそれらに対応して取り出されます。次の例をご覧ください。

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

現在の年が2009年であれば上のコードの出力結果は同じになり、値は取り出されて`params[:date][:year]`に保存されます。

ファイルのアップロード
---------------

ファイルのアップロードはアプリケーションでよく行われるタスクの1つです (プロフィール写真のアップロードや、処理したいCSVファイルのアップロードなど)。ファイルのアップロードでぜひとも気を付けなければならないのは、出力されるフォームのエンコードは **必ず** 「multipart/form-data」でなければならないという点です。`form_with`と`model:`を使えば、この点が自動的に処理されます。`form_with`と`model:`を使わずにファイルアップロードを行なう場合は、以下の例に示したようにエンコードを明示的に指定しなければなりません。

以下の2つはどちらもファイルアップロードのフォームです。

```erb
<%= form_with(url: {action: :upload}, multipart: true) do %>
  <%= file_field_tag 'picture' %>
<% end %>

<%= form_with model: @person do |f| %>
  <%= f.file_field :picture %>
<% end %>
```

Railsでは他と同様、ベアボーンヘルパーの`file_field_tag`と、モデル向けの`file_field`が両方提供されています。そしてご想像のとおり、アップロードされたファイルはベアボーンヘルパーでは`params[:picture]`に保存され、モデル向けのヘルパーでは`params[:person][:picture]`に保存されます。

### アップロード可能なファイル

`params`ハッシュに含まれるこのオブジェクトは、`IO`クラスのサブクラスのインスタンスです。このオブジェクトは、アップロードされるファイルのサイズに応じて、`StringIO`になったり、`File`クラスのインスタンス(実態は一時ファイルとして保存される)になったりします。どちらのヘルパーを使う場合でも、オブジェクトには`original_filename`属性と`content_type`属性が含まれます。`original_filename`属性に含まれる名前は、ユーザーのコンピュータ上にあるファイルの名前です。`content_type`属性には、アップロードの終わったファイルのMIMEタイプが含まれます。以下のスニペットでは、`#{Rails.root}/public/uploads`でアップロードされたコンテンツを、元と同じ名前で保存します(上の例と同じフォームを使っているとします)。

```ruby
def upload
  uploaded_file = params[:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_file.original_filename), 'wb') do |file|
    file.write(uploaded_file.read)
  end
end
```

ファイルがアップロードされた後にはやらなければならないことがたくさんあります。ファイルの保存先の決定 (ローカルディスク上か、Amazon S3か、など)、モデルとの関連付けの他に、画像であればサイズの変更やサムネイルの生成も必要になることがあります。これらの後処理は本ガイドの範疇を超えるのでここでは扱いませんが、これらの処理を助けるさまざまなライブラリがあることは知っておいてよいと思います。[Active Storage](active_storage_overview.html)はこうしたタスクを支援するために設計されています。

フォームビルダーをカスタマイズする
-------------------------

これまで説明したように、`form_with`や`fields_for`によって生成されるオブジェクトは、[`ActionView::Helpers::FormBuilder`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html)のインスタンスです。フォームビルダーは、ある1つのオブジェクトのフォーム要素を表示するために必要なものをカプセル化します。独自のフォーム用のヘルパーを普通の方法で自作することもできますし、`FormBuilder`のサブクラスを作成してそこにヘルパーを追加することもできます。次の例をご覧ください。

```erb
<%= form_with model: @person do |f| %>
  <%= text_field_with_label f, :first_name %>
<% end %>
```

上のコードは以下のように置き換えることもできます。

```erb
<%= form_with model: @person, builder: LabellingFormBuilder do |f| %>
  <%= f.text_field :first_name %>
<% end
```

上の結果を得るために、以下のようなLabellingFormBuilderクラスを定義しておきます。

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

このクラスを頻繁に再利用するのであれば、`labeled_form_with`ヘルパーを定義して`builder: LabellingFormBuilder`オプションを自動的に適用してもよいでしょう。

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

`f`が`ActionView::Helpers::FormBuilder`のインスタンスである場合、このコードは`form`パーシャルを生成し、パーシャルのオブジェクトをフォームビルダーに設定します。このフォームビルダーのクラスが`LabellingFormBuilder`の場合 、代りに`labelling_form`パーシャルが出力されます。

パラメータの命名ルールを理解する
------------------------------------------

これまで説明したように、フォームから受け取る値は`params`ハッシュのトップレベルに置かれるか、他のハッシュの中に入れ子になって含まれます。たとえば、`Person`モデルの標準的な`create`アクションでは、`params[:person]`はその人物について作成されるすべての属性のハッシュとなるでしょう。`params`ハッシュには配列やハッシュの配列なども含められます。

HTMLフォームは原理的に、いかなる構造化データについても関知しません。フォームが生成するのはすべて名前と値のペア（どちらも単なる文字列）です。これらのデータをアプリケーション側で参照した時に配列やハッシュになっているのは、Railsで使われているパラメータ命名ルールのおかげです。

### 基本構造

配列とハッシュは、基本的な2大データ構造です。ハッシュは、`params`の値にアクセスする時に使われる文法に反映されています。たとえば、フォームに以下が含まれているとします。

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

このとき、`params`ハッシュの内容は以下のようになります。

```ruby
{'person' => {'name' => 'Henry'}}
```

従って、コントローラ内で`params[:person][:name]`でアクセスすれば、送信された値を取り出せます。

ハッシュは、以下のように何階層でも好きなだけネストすることができます。

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

上のコードによってできる`params`ハッシュは以下のようになります。

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

Railsは、重複したパラメータ名を無視します。パラメータ名に空の角かっこ`[ ]`が含まれている場合、パラメータは配列の中にまとめられます。たとえば、電話番号入力時に、複数の電話番号を入力できるようにしたい場合、フォームに以下を置くことができます。

```html
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
<input name="person[addresses][][line1]" type="text"/>
<input name="person[addresses][][line2]" type="text"/>
<input name="person[addresses][][city]" type="text"/>
```

これにより、`params[:person][:phone_number]`が電話番号の配列になります。

### 組み合わせ方

これらの2つの概念を混ぜ合わせることもできます。たとえば、前述の例のようにハッシュの1つの要素を1個の配列にすることも、複数のハッシュを1個の配列にすることもできます。他にも、以下のようにフォームの一部を繰り返すことで、任意の数の住所を作成できるようなフォームも考えられます。

```html
<input name="addresses[][line1]" type="text"/>
<input name="addresses[][line2]" type="text"/>
<input name="addresses[][city]" type="text"/>
```

上のフォームでは`params[:addresses]`ハッシュが作成されます。これは`line1`、`line2`、`city`をキーに持つハッシュです。入力された名前が現在のハッシュに既にある場合は、新しいハッシュに値が追加されます。

ただしここで1つ制限があります。ハッシュはいくらでもネストできますが、配列は1階層しか使えません。配列はたいていの場合ハッシュで置き換えられます。たとえば、モデルオブジェクトの配列の代わりに、モデルオブジェクトのハッシュを使えます。このキーではid、配列インデックスなどのパラメータが利用できます。

WARNING: 配列パラメータは、`check_box`ヘルパーとの相性がよくありません。HTMLの仕様では、オンになっていないチェックボックスからは値が送信されません。しかし、チェックボックスから常に値が送信される方が何かと便利です。そこで`check_box`ヘルパーでは、同じ名前で予備の隠し入力を作成しておき、本来送信されないはずのチェックボックス値が見かけ上送信されるようになっています。チェックボックスがオフになっていると隠し入力値だけが送信され、チェックボックスがオンになっていると本来のチェックボックス値と隠し入力値が両方送信されますが、このとき優先されるのは本来のチェックボックス値の方です。

### フォームヘルパーを使う

前の節ではRailsのフォームヘルパーをまったく使っていませんでした。もちろん、このように入力名を自分でこしらえて`text_field_tag`などのヘルパーに渡してもよいのですが、Railsにはさらに高度なサポートがあります。そのための便利な道具は、`form_with`と`fields_for`のnameパラメータ、そしてヘルパーが引数に取る`:index`オプションの2つです。

複数の住所を編集できるフィールドを持つフォームを作ることもできます。次の例をご覧ください。

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

ここでは1人の人物が2つの住所 (idは23と45) を持てるものとします。これによって得られる出力は以下のようになります。

```html
<form accept-charset="UTF-8" action="/people/1" data-remote="true" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

ここから得られる`params`ハッシュは以下のようになります。

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => 'London'}}}}
```

Railsは、これらの入力がpersonハッシュの一部でなければならないことを認識してくれます。これが可能なのは、最初のフォームビルダーで`fields_for`を呼び出してあるからです。`:index`オプションを指定すると、入力は`person[address][city]`のような名前の代わりに、住所と都市名の間に`[ ]`で囲まれたインデックスが挿入された名前が使われます。このようにしておくと、修正すべきAddressレコードを簡単に指定できるので何かと便利です。他の意味を持つ数字を渡したり、文字列や`nil`を渡すこともできます。これらは、作成される配列パラメータの中に置かれます。

入力名の最初の部分(先の例の`person[address]`など)を明示的に示すことで、より複雑なネスティングを作成することもできます。

```erb
<%= fields_for 'person[address][primary]', address, index: address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

上のコードから以下のような入力が作成されます。

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="Bologna" />
```

Railsの一般的なルールとして、最終的な入力名は、「`fields_for`や`form_with`に与えられた名前」「インデックス値」「属性名」を連結したものになります。`text_field`などのヘルパーに`:index`オプションを直接渡してもよいのですが、入力コントロールごとに指定するより、フォームビルダーのレベルで一度指定する方が、たいていの場合繰り返しが少なくて済みます。

名前に`[]`を追加して`:index`オプションを省略する略記法もあります。以下は`index: address`を指定しています。

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

従って、上の結果はその前の例とまったく同じになります。

外部リソース用のフォーム
---------------------------

外部リソースに何らかのデータを渡す必要がある場合も、Railsのフォームヘルパーを用いてフォームを作成する方がやはり便利です。しかし、その外部リソースに対して`authenticity_token`を設定しなければならない場合にはどうしたらよいでしょう。これは、`form_tag`オプションに`authenticity_token: 'your_external_token'`パラメータを渡すことで実現できます。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

支払用ゲートウェイなどの外部リソースに対してデータを送信することがある場合、フォームで使えるフィールドは外部APIによって制限されてしまいます。その場合、`authenticity_token`隠しフィールドを生成すると不都合が生じることがあります。`authenticity_token`フィールドを出力したくない場合は次のようにします。

```erb
<%= form_with url: 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

複雑なフォームを作成する
----------------------

最初は単一のオブジェクトを編集していただけのシンプルなフォームも、やがて成長し複雑になります。たとえば、Personを1人作成するのであれば、そのうち同じフォームで複数の住所レコード(自宅、職場など)を登録したくなるでしょう。後でPersonを編集するときに、必要に応じて住所の追加・削除・変更が行えるようにする必要もあります。

### モデルを構成する

Active Recordは`accepts_nested_attributes_for`メソッドによってモデルレベルのサポートを行っています。

```ruby
class Person < ApplicationRecord
  has_many :addresses, inverse_of: :person
  accepts_nested_attributes_for :addresses
end

class Address < ApplicationRecord
  belongs_to :person
end
```

上のコードによって`addresses_attributes=`メソッドが`Person`モデル上に作成され、これを用いて住所の作成・更新・(必要であれば)削除を行なうことができます。

### ネストしたフォーム

ユーザーは以下のフォームを用いて`Person`とそれに関連する複数の住所を作成することができます。

```html+erb
<%= form_with model: @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
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

ネストした属性が関連付けに渡されると、`fields_for`ヘルパーはその関連付けのすべての要素を一度ずつ出力します。特に、Personに住所が登録されていない場合は何も出力しません。フィールドのセットが少なくとも1つはユーザーに表示されるように、コントローラで1つ以上の空白の子を作成しておくというのはよく行われるパターンです。以下の例では、Personフォームを新たに作成したときに2組の住所フィールドが表示されるようになっています。

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

`:addresses_attributes`ハッシュのキーはここでは重要ではありません。各アドレスのキーが重複していなければそれでよいのです。

関連付けられたオブジェクトが既に保存されている場合、`fields_for`メソッドは、保存されたレコードの`id`を持つ隠し入力を自動的に作成します。`fields_for`に`include_id: false`を渡すことでこの自動生成をオフにできます。

### コントローラ

コントローラ内でパラメータをモデルに渡す前に、定番の[パラメータのホワイトリストチェック](action_controller_overview.html#strong-parameters)を実施する必要があります。

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

`accepts_nested_attributes_for`に`allow_destroy: true`を渡すと、関連付けられたオブジェクトをユーザーが削除することを許可できるようになります。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

あるオブジェクトの属性のハッシュに、キーが`_destroy`で値が`1`または`true`の組み合わせがあると、そのオブジェクトは削除されます。以下のフォームではユーザーが住所を削除できるようになっています。

```erb
<%= form_with model: @person do |f| %>
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

このとき、コントローラ内の、ホワイトリストチェックの終わったパラメータを更新して、`_destroy`フィールドが必ずパラメータに含まれるようにする必要があります。

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 空のレコードができないようにする

ユーザーが何も入力しなかったフィールドを無視できれば何かと便利です。これは、`:reject_if` procを`accepts_nested_attributes_for`に渡すことで制御できます。このprocは、フォームから送信された属性のハッシュ1つ1つについて呼び出されます。このprocが`false`を返す場合、Active Recordはそのハッシュに関連付けられたオブジェクトを作成しません。以下の例では、`kind`属性が設定されている場合にのみ住所オブジェクトを生成します。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

代りにシンボル`:all_blank`を渡すこともできます。このシンボルが渡されると、すべての値が空欄のレコードを受け付けなくなるprocが1つ生成され、`_destroy`ですべての値が取り除かれます。

### フィールドを動的に追加する

多くのフィールドセットを事前に出力する代わりに、[新しい住所を追加] ボタンを押したときだけこれらのフィールドをその場で追加したいことがあります。残念ながらRailsではこのためのビルトインサポートは用意されていません。フィールドセットをその場で生成する場合は、関連する配列のキーが重複しないよう注意しなければなりません。JavaScriptで現在の日時を取得して数ミリ秒の時差から一意の値を得るのが定番の手法です。

古い`form_for`と`form_tag`について
---------------------------

Rails 5.1で`form_with`が導入される前は、同じ機能が`form_tag`と`form_for`に分かれていました。後者は現在（やや）非推奨です。後者のドキュメントについては、[古いRails Guides](https://guides.rubyonrails.org/v5.2/form_helpers.html)にあります（訳注: 日本語版は[RailsガイドProプラン](https://railsguides.jp/pro)で参照できます）。
