Action Controller の概要
==========================

本ガイドでは、コントローラの動作と、アプリケーションのリクエストサイクルにおけるコントローラの役割について解説します。

このガイドの内容:

* コントローラを経由するリクエストの流れを理解する
* コントローラに渡されるパラメータを制限する方法
* セッションやcookieにデータを保存する理由とその方法
* リクエストの処理中にアクションコールバックでコードを実行する方法
* Action Controller組み込みのHTTP認証機能
* ユーザーのブラウザにデータを直接ストリーミング送信する方法
* 機密性の高いパラメータをアクションコールバックしてログに出力されないようにする方法
* リクエスト処理中に発生する可能性のある例外の取り扱い
* 組み込みのヘルスチェックエンドポイントをロードバランサーやアップタイムモニタで活用する方法

--------------------------------------------------------------------------------


コントローラの役割
--------------------------

Action Controllerは、[MVC](https://ja.wikipedia.org/wiki/Model_View_Controller)アーキテクチャの「C」に相当します。リクエストを処理するコントローラがルーティング設定によって決定されると、コントローラはリクエストの意味を理解して適切な出力を行う役目を担います。ありがたいことに、これらの処理のほとんどはAction Controllerが行ってくれます。リクエストは、十分に吟味された規約によって可能な限りわかりやすい形で処理されます。

伝統的な[RESTful](https://ja.wikipedia.org/wiki/REST)なアプリケーションでは、コントローラはリクエストの受信（この部分はアプリケーション開発者から見えません）を担当し、モデルはデータの取得や保存を担当し、ビューはHTML出力を担当します。自分のコントローラがこれと少し違っていても気にする必要はありません。ここで説明しているのは、あくまでコントローラの一般的な使われ方です。

つまり、コントローラは「モデルとビューの間を仲介する」と考えられます。コントローラがモデルのデータをビューで利用可能にすることで、データをビューで表示したり、入力されたデータでモデルを更新したりします。

NOTE: ルーティングについて詳しくは、[Railsのルーティング](routing.html)ガイドを参照してください。

コントローラの命名規約
----------------------------

Railsのコントローラ名は、基本的に英語の「複数形」を使います（なお「Controller」という文字は含めません）。ただしこれは絶対的に守らなければならないというものではありません（実際 `ApplicationController`はApplicationが単数形です）。たとえば、`ClientsController`の方が`ClientController`より好ましく、`SiteAdminsController`の方が`SiteAdminController`や`SitesAdminsController`よりも好ましいといった具合です。

しかし、この規約は守っておくことをおすすめします。規約を守ることで、`resources`などのデフォルトのルーティングジェネレータをそのまま利用できるようになりますし、生成される名前付きルーティングヘルパー名もアプリケーション全体で一貫するからです。
コントローラ名を複数形にしておかないと、たとえば`resources`だけでルーティングを一括設定できなくなり、`:path`や`:controller`をいちいち指定しなければならなくなります。詳しくは[レイアウト・レンダリングガイド](layouts_and_rendering.html)を参照してください。

NOTE: モデルの命名規約はコントローラの命名規約と異なり、「単数形」が期待されます。

メソッドとアクション
-------------------

Railsのコントローラは、`ApplicationController`を継承したRubyのクラスであり、他のクラスと同様のメソッドが使えます。アプリケーションがブラウザからのリクエストを受け取ると、ルーティングによってコントローラとアクションが確定し、Railsはそれに応じてコントローラのインスタンスを生成し、アクション名と同じ名前のメソッドを実行します。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

たとえば、クライアントを1人追加するためにブラウザでアプリケーションの`/clients/new`にアクセスすると、Railsは`ClientsController`のインスタンスを作成して`new`メソッドを呼び出します。
このとき、`new`メソッドの内容が空であるにもかかわらず正常に動作するという点にご注目ください。これが可能なのは、Railsでは特に指定のない場合は、`new`アクションが`new.html.erb`ビューをレンダリングするようになっているからです。
以下のように`new`アクション（メソッド）内で`Client`モデルを新規作成すると`@client`インスタンス変数が作成されます。この`@client`インスタンス変数は、ビューでもアクセスできるようになっています。

```ruby
def new
  @client = Client.new
end
```

詳しくは、[レイアウト・レンダリングガイド](layouts_and_rendering.html)を参照してください。

`ApplicationController`が継承している[`ActionController::Base`][]には、便利なメソッドが多数定義されています。本ガイドで説明しているのはその一部なので、詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActionController.html)またはRailsのソースコードを参照してください。

アクションとして呼び出せるのは、publicメソッドだけです。補助メソッドやアクションコールバックのような、アクションとして呼び出したくないメソッドには、`private`や`protected`を指定して公開しないようにするのが定石です。

WARNING: 一部のメソッド名はAction Controllerで予約されています。予約済みメソッドを誤ってアクションや補助メソッドとして再定義すると、`SystemStackError`が発生する可能性があります。コントローラ内でRESTfulな[リソースルーティング][]アクションだけを使うようにしていれば、心配は無用です。

NOTE: 予約済みメソッド名をアクション名として使わざるを得ない場合は、たとえばカスタムルーティングを利用して、予約済みメソッド名を予約されていないアクションメソッド名に対応付けるという回避策が考えられます。

[`ActionController::Base`]: https://api.rubyonrails.org/classes/ActionController/Base.html
[リソースルーティング]: routing.html#リソースベースのルーティング-railsのデフォルト

パラメータ
----------

コントローラのアクションで作業を行なうときは、ユーザーから送信されたデータやその他のパラメータにアクセスするでしょう。Railsに限らず、一般にWebアプリケーションでは2種類のパラメータを扱えます。

1つ目は、URLの一部として送信される「**クエリ文字列パラメータ**」と呼ばれるパラメータです（クエリパラメータ）。クエリ文字列は、常にURLの`?`文字の後に追加されます。

2つ目は、「**POSTデータ**」と呼ばれるパラメータです。通常、ユーザーが記入したHTMLフォームから受け取るのはPOSTデータです。POSTデータという名称は、HTTP POSTリクエストの一部として送信されることが由来です。

Railsでは、パラメータをクエリ文字列で受け取ることもPOSTデータで受け取ることもできます。いずれの場合も、コントローラ内では[`params`][]という名前のハッシュでパラメータにアクセスできます。

```ruby
class ClientsController < ApplicationController
  # 送信側でHTTP GETリクエストが使われると
  # このアクションでクエリ文字列パラメータが使われる
  # ただしパラメータのアクセス方法はPOSTデータの場合と同じ
  # 有効な顧客リストを得るためにアクションに送信される
  # クエリパラメータは /clients?status=activated となる
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # このアクションではPOSTパラメータが使われている
  # ユーザーが送信するHTMLフォームは、ほとんどの場合POSTパラメータになる
  # これはRESTfulなアクセスであり、URLは"/clients"となる
  # データはURLに含まれず、リクエストのbodyの一部として送信される
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # 以下の行はデフォルトのレンダリング動作を上書きしている
      # （本来は"create"ビューがレンダリングされる）
      render "new"
    end
  end
end
```

[`params`]: https://api.rubyonrails.org/classes/ActionController/StrongParameters.html#method-i-params

### ハッシュと配列のパラメータ

`params`ハッシュには、一次元のキーバリューペアの他に、ネストした配列やハッシュも保存できます。値の配列をフォームから送信するには、以下のようにキー名に空の角かっこ`[]`のペアを追加します。

```
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

NOTE: `[`や`]`はURLで利用できない文字なので、この例の実際のURLは`/clients?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3`のようになります。これについては、ブラウザで自動的にエンコードされ、Railsがパラメータを受け取るときに自動的に復元するので、通常は気にする必要はありません。ただし、何らかの理由でサーバーにリクエストを手動送信しなければならない場合には、このことを思い出す必要があるでしょう。

これで、受け取った`params[:ids]`の値は`["1", "2", "3"]`になりました。ここで重要なのは、パラメータの値が常に「文字列」になることです。Railsはパラメータの型推測や型変換を行いません。

NOTE: `params`の中にある`[nil]`や`[nil, nil, ...]`などの値は、セキュリティ上の理由でデフォルトでは`[]`に置き換えられます。詳しくは [セキュリティガイド](security.html#安全でないクエリ生成) を参照してください。

フォームからハッシュを送信するには、以下のようにキー名を角かっこ`[]`の中に置きます。

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

このフォームを送信すると、`params[:client]`の値は`{ "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }`になります。`params[:client][:address]`のハッシュがネストしていることにご注目ください。

この`params`ハッシュはハッシュのように振る舞いますが、キー名にシンボルと文字列のどちらでも指定できる点がハッシュと異なります。

### JSONパラメータ

アプリケーションでAPIを公開している場合、JSON形式のパラメータを受け取ることが多いでしょう。リクエストの"Content-Type"ヘッダーが"application/json"に設定されていれば、Railsは自動的にパラメータを`params`ハッシュに読み込んで、通常と同じようにアクセスできるようになります。

たとえば、以下のJSONコンテンツを送信したとします。

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

コントローラの`params[:company]`は、`{ "name" => "acme", "address" => "123 Carrot Street" }`という値を受け取ります。

また、イニシャライザで`config.wrap_parameters`設定をオンにするか、コントローラで[`wrap_parameters`][]が呼び出すと、JSONパラメータのroot要素を安全に除去できます。このとき、このパラメータはデフォルトで複製され、コントローラ名に応じたキー名でラップされます。つまり、上のJSONリクエストは以下のように書けます。

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

データの送信先が`CompaniesController`であれば、以下のように`:company`というキーでラップされます。

```ruby
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

キー名のカスタマイズや、ラップする特定のパラメータについて詳しくは[`ActionController::ParamsWrapper`](https://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html) APIドキュメントを参照してください。

NOTE: 従来のXMLパラメータ解析のサポートは、`actionpack-xml_parser`というgemに切り出されました。

[`wrap_parameters`]: https://api.rubyonrails.org/classes/ActionController/ParamsWrapper/Options/ClassMethods.html#method-i-wrap_parameters

### ルーティングパラメータ

`params`ハッシュには、`:controller`キーと`:action`キーが必ず含まれます。ただしこれらの値には直接アクセスせず、専用の[`controller_name`][]や[`action_name`][]メソッドをお使いください。
ルーティングで定義されるその他の値パラメータ（`id`など）にもアクセスできます。例として、「有効」または「無効」で表される顧客のリストについて考えてみましょう。「プリティな」URLの`:status`パラメータを受信する以下のルーティングを追加できます。

```ruby
get '/clients/:status', to: 'clients#index', foo: 'bar'
```

この場合、ブラウザで`/clients/active`というURLを開くと、`params[:status]`が「active」（有効）に設定されます。このルーティングを使うと、あたかもクエリ文字列で渡したかのように`params[:foo]`にも"bar"が設定されます。コントローラは、`params[:action]`（indexとして）や`params[:controller]`（clientsとして）も受け取ります。

[`controller_name`]: https://api.rubyonrails.org/classes/ActionController/Metal.html#method-i-controller_name
[`action_name`]: https://api.rubyonrails.org/classes/AbstractController/Base.html#method-i-action_name

### 複合主キーのパラメータ

複合主キーのパラメータには、1つのパラメータに複数の値が含まれているため、各値を抽出してActive Recordに渡す必要があります。このユースケースでは、`extract_value`メソッドを活用できます。

以下のコントローラがあるとします。

```ruby
class BooksController < ApplicationController
  def show
    # URLパラメータから複合ID値を抽出する
    id = params.extract_value(:id)
    # この複合IDでbookを検索する
    @book = Book.find(id)
    # デフォルトのレンダリング動作でビューを表示する
  end
end
```

ルーティングは以下のようになっているとします。

```ruby
get '/books/:id', to: 'books#show'
```

ユーザーがURL `/books/4_2`を開くと、コントローラは複合主キーの値`["4", "2"]`を抽出して`Book.find`に渡し、ビューで正しいレコードを表示します。`extract_value`メソッドは、区切られた任意のパラメータから配列を抽出するのに利用できます。

### `default_url_options`

コントローラで`default_url_options`という名前のメソッドを定義すると、URL生成用のグローバルなデフォルトパラメータを設定できます。このようなメソッドは、必要なデフォルト値を持つハッシュを必ず1つ返さねばならず、ハッシュのキーはシンボルでなければなりません。

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

これらのオプションはURL生成の開始点として使われるので、`url_for`呼び出しに渡されるオプションで上書きされます。

`ApplicationController`で`default_url_options`を定義すると、上の例で示したように、すべてのURL生成で使われるようになります。このメソッドを特定のコントローラで定義すると、そのコントローラが生成するURLにだけ影響します。

リクエストでは、生成されるあらゆるURLごとにこのメソッドが実際に呼び出されるわけではありません。パフォーマンス上の理由により、戻り値のハッシュがキャッシュされるので、呼び出し回数は最大でリクエストごとに1回までとなります。

### Strong Parameters

strong parametersは、Action ControllerのパラメータをActive Modelの「マスアサインメント」で利用することを禁止します（許可されたパラメータは除く）。したがって、開発者は、マスアップデートを許可する属性をコントローラで明示的に指定しなければなりません。strong parametersは、ユーザーがモデルの重要な属性を誤って更新してしまうことを防止するための、より優れたセキュリティ対策です。

さらに、パラメータの属性を`require`にすると、渡された必須パラメータが不足している場合に、事前定義済みのraise/rescueフローで「400 Bad Request」で終了できるようになります。

```ruby
class PeopleController < ActionController::Base
  # 以下のコードはActiveModel::ForbiddenAttributesError例外を発生する
  # （明示的な許可を行なわずに、パラメータを一括で渡してしまう
  # 危険な「マスアサインメント」が行われているため）
  def create
    Person.create(params[:person])
  end

  # 以下のコードは、パラメータにpersonキーがあれば成功する
  # personキーがない場合は
  # ActionController::ParameterMissing例外を発生する
  # この例外はActionController::Baseでキャッチされ、
  # 400 Bad Requestを返す
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # 許可するパラメータをprivateメソッドでカプセル化するのは
    # 非常によい手法であり、createとupdateの両方で同じ許可を与えられる
    # このメソッドを特殊化してユーザーごとに許可属性をチェックすることも可能
    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

#### スカラー値を許可する

以下のように[`permit`][] で許可します。

```ruby
params.permit(:id)
```

`params`に`:id`キーがあり、それに対応する許可済みスカラー値に`:id`キーがあれば、許可リストチェックはパスします。この条件を満たさない場合は、`:id`キーが除外されます。これにより、外部からハッシュなどのオブジェクトを不正に注入できなくなります。

スカラーで許可される型は以下のとおりです。

* `String`
* `Symbol`
* `NilClass`
* `Numeric`
* `TrueClass`
* `FalseClass`
* `Date`
* `Time`
* `DateTime`
* `StringIO`
* `IO`
* `ActionDispatch::Http::UploadedFile`
* `Rack::Test::UploadedFile`

「`params`の値には許可されたスカラー値の**配列**を使わなければならない」ことを宣言するには、以下のようにキーに空配列を対応付けます。

```ruby
params.permit(id: [])
```

ハッシュパラメータやその内部構造の正しいキーをすべて明示的に宣言できない場合や、すべて宣言するのが面倒な場合があります。次のように空のハッシュを割り当てることは一応可能です。

```ruby
params.permit(preferences: {})
```

ただし、この指定は任意の入力を受け付けてしまうため、利用には十分ご注意ください。この場合`permit`によって、受け取った構造内の値が許可済みのスカラーとして扱われ、それ以外の値がアクションコールバックで除外されます。

パラメータのハッシュ全体を許可したい場合は、[`permit!`][]メソッドが使えます。

```ruby
params.require(:log_entry).permit!
```

こうすることで、`:log_entry`パラメータハッシュとすべてのサブハッシュが「許可済み（permitted）」としてマーキングされ、スカラー許可済みかどうかがチェックされなくなってあらゆる値を受け付けるようになります。ただし、現在のモデルの属性はもちろん、今後モデルに追加される属性も一括で許可されてしまうので、`permit!`はくれぐれも慎重にお使いください。

[`permit`]: https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-permit
[`permit!`]: https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-permit-21

#### ネストしたパラメータを許可する

`permit`は、以下のようにネストしたパラメータに対しても使えます。

```ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

この宣言では、`name`、`emails`、`friends`属性が許可されます。
ここでは以下が期待されます。

* `emails`: 許可済みスカラー値の配列
* `friends`: 以下で指定する属性を持つリソースの配列
    * `name`属性が必須
        * `name`属性は任意の許可済みスカラー値を受け付ける
    * `hobbies`属性: 許可済みスカラー値の配列
    * `family`属性:`name`属性が必須
        * `name`属性は任意の許可済みスカラー値を受け付ける

#### その他の例

許可済み属性は`new`アクションでも利用できます。しかし通常は`new`を呼び出す時点ではrootキーがないので、rootキーで[`require`][]を指定できません。

```ruby
# `fetch`を使うとデフォルト値を渡して
# Strong Parameters APIを使えるようになる
params.fetch(:blog, {}).permit(:title, :author)
```

このモデルの`accepts_nested_attributes_for`クラスメソッドを使うと、関連付けられたレコードを更新・削除できるようになります。以下は`id`と`_destroy`パラメータに基づいています。

```ruby
# :id と :_destroyを許可する
params.require(:author).permit(:name, books_attributes: [:title, :id, :_destroy])
```

キーが整数のハッシュは異なる方法で処理されます。これらは、あたかも直接の子オブジェクトであるかのように属性を宣言できます。`has_many`関連付けと`accepts_nested_attributes_for`メソッドを使うと、このようなパラメータを取得できます。

```ruby
# 以下のデータを許可
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.require(:book).permit(:title, chapters_attributes: [:title])
```

次のような状況を想像してみましょう。パラメータに「製品名」「その製品名に関連付けられる任意のデータを表すハッシュ」があるとします。以下のように、この製品名とデータハッシュ全体をまとめて許可できます。

```ruby
def product_params
  params.require(:product).permit(:name, data: {})
end
```

[`require`]: https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-require

#### Strong Parametersでカバーされないケースについて

strong parameter APIの設計で考慮されているのは最も一般的なユースケースであり、あらゆるパラメータのフィルタ問題を扱える「銀の弾丸」ではありません。しかし、このAPIを自分のコードに取り入れてアプリの実情に対応することは難しくありません。

セッション
-------

Railsアプリケーションは、ユーザーごとにセッションを設定します。前のリクエストの情報を次のリクエストでも利用するためにセッションに少量のデータが保存されます。セッションはコントローラとビューでのみ利用できます。また、以下のようにさまざまなストレージを選べます。

* [`ActionDispatch::Session::CookieStore`][] すべてをクライアント側に保存する
* [`ActionDispatch::Session::CacheStore`][]: データをRailsのキャッシュに保存する
* [`ActionDispatch::Session::MemCacheStore`][] データをmemcachedクラスタに保存する（この実装は古いので`CacheStore`をご検討ください）
* [`ActionDispatch::Session::ActiveRecordStore`][activerecord-session_store]: Active Recordデータベースに保存する（[`activerecord-session_store`][activerecord-session_store] gemが必要）
* 独自のストアや、サードパーティgemが提供するストア

あらゆるセッションは、cookieを利用してセッション固有のIDを保存します（cookieは必ず使うこと: セッションIDをURLで渡すとセキュリティが低下するため、この方法はRailsで許可されません）。

ほとんどのセッションストアでは、サーバー上のセッションデータ（データベーステーブルなど）を検索するときにこのIDを使います。

CookieStoreは、Railsで推奨されているデフォルトのセッションストアであり、例外的にすべてのセッションデータをcookie自身に保存します（必要に応じてセッションIDも利用可能です）。CookieStoreには非常に軽量であるというメリットがあり、新規Webアプリケーションでセッションを利用するための準備も不要です。このcookieデータは改ざん防止のために暗号署名が追加されており、cookie自身も暗号化されているので、他人が読むことはできません（改ざんされたcookieはRailsに拒否されます）。

CookieStoreには約4KBのデータを保存できます。他のセッションストアに比べて小容量ですが、通常はこれで十分です。利用するセッションストアの種類にかかわらず、セッションに大量のデータを保存することはおすすめできません。特に、セッションに複雑なオブジェクト（モデルインスタンスなど）を保存することはおすすめできません。複雑なオブジェクトを保存すると、サーバーがリクエストとリクエストの間でセッションを組み立てられなくなり、エラーになる可能性があります。

ユーザーセッションに重要なデータを保存しない場合や、ユーザーセッションを長期間保存する必要がない場合（flashメッセージでセッションを使うだけの場合など）は、`ActionDispatch::Session::CacheStore`の利用をご検討ください。この方式では、Webアプリケーションに設定されているキャッシュ実装を利用してセッションを保存します。この方法のよい点は、既存のキャッシュインフラをそのまま利用してセッションを保存できることと、管理用の設定を追加する必要がないことです。この方法の欠点は、セッションが短命で、いつでも消える可能性があることです。

セッションストレージについて詳しくは[セキュリティガイド](security.html)を参照してください。

別のセッションメカニズムが必要な場合は、イニシャライザで切り替えられます。

```ruby
Rails.application.config.session_store :cache_store
```

詳しくは設定ガイドの[`config.session_store`](configuring.html#config-session-store)を参照してください。

Railsは、セッションデータに署名するときにセッションキー（cookieの名前）を設定します。この動作もイニシャライザで変更できます。

```ruby
# このファイルを変更後、サーバーを必ず再起動すること。
Rails.application.config.session_store :cookie_store, key: '_your_app_session'
```

`:domain`キーを渡して、cookieを使うドメイン名を指定することも可能です。

```ruby
# このファイルを変更後、サーバーを必ず再起動すること。
Rails.application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Railsは、`config/credentials.yml.enc`のセッションデータの署名に用いる秘密鍵を設定します（CookieStore用）。この秘密鍵は`bin/rails credentials:edit`コマンドで変更できます。


```yaml
# aws:
#   access_key_id: 123
#   secret_access_key: 345

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 492f...
```

NOTE: `CookieStore`を利用中に`secret_key_base`を変更すると、既存のセッションがすべて無効になります。

[`ActionDispatch::Session::CookieStore`]: https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html
[`ActionDispatch::Session::CacheStore`]: https://api.rubyonrails.org/classes/ActionDispatch/Session/CacheStore.html
[`ActionDispatch::Session::MemCacheStore`]: https://api.rubyonrails.org/classes/ActionDispatch/Session/MemCacheStore.html
[activerecord-session_store]: https://github.com/rails/activerecord-session_store

### セッションにアクセスする

コントローラ内では、`session`インスタンスメソッドでセッションにアクセスできます。

NOTE: セッションは遅延読み込み（lazy loaded）されます。アクションのコードでセッションにアクセスしなかった場合、セッションは読み込まれません。セッションにアクセスしなければセッションを無効にする必要は生じないので、アクセスしないようにするだけで十分です。

セッションの値は、ハッシュと同様にキーバリューペアとして保存されます。

```ruby
class ApplicationController < ActionController::Base
  private
    # :current_user_idキーを持つセッションに保存されたidでユーザーを検索する
    #  これはRailsアプリケーションでユーザーログインを扱う際の定番の方法
    # ログインするとセッション値が設定され、
    # ログアウトするとセッション値が削除される
    def current_user
      @_current_user ||= session[:current_user_id] &&
        User.find_by(id: session[:current_user_id])
    end
end
```

セッションに何かを保存するには、ハッシュと同様にキーに代入します。

```ruby
class LoginsController < ApplicationController
  # ログインを作成する（ユーザーをログインさせる）
  def create
    if user = User.authenticate(params[:username], params[:password])
      # セッションのuser idを保存し、
      # 今後のリクエストで使えるようにする
      session[:current_user_id] = user.id
      redirect_to root_url, status: :see_other
    end
  end
end
```

セッションからデータの一部を削除するには、そのキーバリューペアを削除します。

```ruby
class LoginsController < ApplicationController
  # ログインを削除する（ユーザーをログアウトさせる）
  def destroy
    # セッションからユーザーidを削除する
    session.delete(:current_user_id)
    # メモ化された現在のユーザーをクリアする
    @_current_user = nil
    redirect_to root_url
  end
end
```

セッション全体をリセットするには[`reset_session`][]を使います。

[`reset_session`]: https://api.rubyonrails.org/classes/ActionController/Metal.html#method-i-reset_session

### Flash

flashはセッションの特殊な部分であり、リクエストごとにクリアされます。つまり、flashは「直後のリクエスト」でのみ参照可能になるという特徴があり、エラーメッセージをビューに渡したりするのに便利です。

flashにアクセスするには[`flash`][]メソッドを使います。flashは、セッションと同様にハッシュで表わされます。

例として、ログアウトする動作を扱ってみましょう。コントローラは、次回のリクエストで表示するメッセージを以下のように送信できます。

```ruby
class LoginsController < ApplicationController
  def destroy
    session.delete(:current_user_id)
    flash[:notice] = "ログアウトしました"
    redirect_to root_url, status: :see_other
  end
end
```

flashメッセージを、以下のようにリダイレクトのオプションとして記述することもできます。オプションとして`:notice`、`:alert`の他に、一般的な`:flash`も使えます。

```ruby
redirect_to root_url, notice: "ログアウトしました"
redirect_to root_url, alert: "問題が発生しました！"
redirect_to root_url, flash: { referral_code: 1234 }
```

この`destroy`アクションでは、アプリケーションの`root_url`にリダイレクトし、そこでメッセージを表示します。

flashメッセージは、直前のアクションで設定したflashメッセージと無関係に、次に行われるアクションだけで決まることにご注意ください。通常、Railsアプリケーションのレイアウトでは、警告や通知をflashで表示します。

```erb
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>

    <!-- more content -->
  </body>
</html>
```

このように、アクションで通知（notice）や警告（alert）メッセージを指定すると、レイアウト側で自動的にそのメッセージが表示されます。

flashは、通知や警告に限らず、セッションに保存可能なものであれば何でも保存できます。

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

flashの値を別のリクエストに引き継ぎたい場合は、[`flash.keep`][]メソッドを使います。

```ruby
class MainController < ApplicationController
  # このアクションはroot_urlに対応しており、このアクションの
  # すべてのリクエストをUsersController#indexにリダイレクトしたいとする
  # あるアクションでflashを設定してこのindexアクションにリダイレクトすると、
  # 別のリダイレクトが発生した場合にはflashは消えてしまう
  # 'keep'を使えば別のリクエストでflashが消えなくなる
  def index
    # すべてのflash値を保持する
    flash.keep

    # キーを指定して特定の値だけをkeepすることも可能
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

[`flash`]: https://api.rubyonrails.org/classes/ActionDispatch/Flash/RequestMethods.html#method-i-flash
[`flash.keep`]: https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html#method-i-keep

#### `flash.now`

デフォルトでは、flashに値を追加すると次回のリクエストでその値を利用できますが、次のリクエストを待たずに同じリクエスト内でこれらのflash値にアクセスしたい場合があります。

たとえば、`create`アクションに失敗してリソースが保存されなかった場合は`new`テンプレートを直接レンダリングするとします。この場合は新しいリクエストが発生しませんが、flashを使ってメッセージを表示したいことがあります。

このような場合、[`flash.now`][]を使えば通常の`flash`と同じ要領でメッセージを表示できます。

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(client_params)
    if @client.save
      # ...
    else
      flash.now[:error] = "クライアントを保存できませんでした"
      render action: "new"
    end
  end
end
```

[`flash.now`]: https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html#method-i-now

Cookie
-------

Webアプリケーションでは、cookieと呼ばれる少量のデータをクライアントのブラウザに保存できます。HTTPは「ステートレス」なプロトコルなので、基本的にリクエストとリクエストの間には何の関連もありませんが、cookieを使うとリクエスト同士の間で（あるいはセッション同士の間であっても）このデータが保持されるようになります。

Railsでは[`cookies`][]メソッドでcookieに簡単にアクセスできます。セッションの場合と同様にハッシュとしてアクセス可能です。

```ruby
class CommentsController < ApplicationController
  def new
    # cookieにコメント作者名が残っていたらフィールドに自動入力する
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(comment_params)
    if @comment.save
      flash[:notice] = "Thanks for your comment!"
      if params[:remember_name]
        # コメント作者名をcookieに保存する
        cookies[:commenter_name] = @comment.author
      else
        # コメント作者名がcookieに残っていたら削除する
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

セッションを削除する場合はキーに`nil`を指定すると削除されますが、cookieを削除するには、この方法ではなく`cookies.delete(:key)`を使う必要があります。

Railsでは、機密データを保存するための署名済みcookie jarと暗号化cookie jarも提供しています。
署名済みcookie jarは、暗号化済み署名をcookie値に追加することで、cookieの改竄を防ぎます。
暗号化cookie jarは、署名を追加するとともに、値自体も暗号化してエンドユーザーが読めないようにします。

詳しくは[APIドキュメント](https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html)を参照してください。

これらの特殊なcookie jarは、値をシリアライザで文字列に変換して保存し、読み込み時にデシリアライズしてRubyオブジェクトを復元します。
どのシリアライザを利用するかについては[`config.action_dispatch.cookies_serializer`][]で設定可能です。

新しいアプリケーションのシリアライザはデフォルトで`:json`に設定されます。ただし、JSONはRubyオブジェクトのシリアライズ/デシリアライズのサポートが限られていることにご注意ください。たとえば、`Date`、`Time`、および`Symbol`オブジェクト（`Hash`のキーを含む）は `String`にシリアライズおよびデシリアライズされます。

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2014
    redirect_to action: 'read_cookie'
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2014-03-20"
  end
end
```

そうしたオブジェクトや、さらに複雑なオブジェクトを保存する必要がある場合は、後続のリクエストで読み込む際に値を手動で変換する必要があります。

cookieセッションストアを使う場合、`session`や`flash`ハッシュについても同様のことが該当します。

[`config.action_dispatch.cookies_serializer`]: configuring.html#config-action-dispatch-cookies-serializer
[`cookies`]: https://api.rubyonrails.org/classes/ActionController/Cookies.html#method-i-cookies

レンダリング
----------

ActionControllerでは、HTMLデータ、XMLデータ、JSONデータのレンダリングを非常に手軽に行えます。scaffoldで生成したコントローラは、以下のようになっています。

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users }
      format.json { render json: @users }
    end
  end
end
```

上のコードでは、`render xml: @users.to_xml`ではなく`render xml: @users`となっていることにご注目ください。Railsは、オブジェクトが`String`型でない場合は自動的に`to_xml`を呼び出します。

レンダリングについて詳しくは、[レイアウトとレンダリング](layouts_and_rendering.html)ガイドを参照してください。

アクションコールバック
-------

> 訳注: Rails 7.2から、従来のフィルタ（filter）という用語がアクションコールバックに置き換えられました。

**アクションコールバック（action callback）**は、コントローラにあるアクションが実行される「直前 (before)」、「直後 (after)」、あるいは「直前と直後の両方 (around)」に実行されるメソッドです。

アクションコールバックは継承されるので、アクションコールバックを`ApplicationController`で設定すればアプリケーションのすべてのコントローラで有効になります。

「before系」アクションコールバックは、[`before_action`][]で登録します。リクエストサイクルを止めてしまう可能性があるのでご注意ください。「before系」アクションコールバックのよくある使われ方の1つは、ユーザーがアクションを実行する前にログインを要求するというものです。このアクションコールバックメソッドは以下のような感じになるでしょう。

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private
    def require_login
      unless logged_in?
        flash[:error] = "このセクションにアクセスするにはログインが必要です"
        redirect_to new_login_url # リクエストサイクルを停止する
      end
    end
end
```

このメソッドはエラーメッセージをflashに保存し、ユーザーがログインしていない場合にはログインフォームにリダイレクトするというシンプルなものです。「before系」アクションコールバックによってビューのレンダリングやリダイレクトが行われると、コントローラのこのアクションは実行されなくなります。アクションコールバックの実行後に実行されるようスケジュールされた追加のアクションコールバックがある場合、これらもキャンセルされます。

この例ではアクションコールバックを`ApplicationController`に追加したので、これを継承するすべてのコントローラが影響を受けます。つまり、アプリケーションのあらゆる機能についてログインが要求されることになります。当然ですが、アプリケーションのあらゆる画面で認証を要求してしまうと、認証に必要なログイン画面まで表示できなくなるという困った事態が発生するので、このようにすべてのコントローラやアクションでログイン要求を設定すべきではありません。[`skip_before_action`][]メソッドを使えば、特定のアクションでアクションコールバックをスキップできます。


```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

上のようにすることで、`LoginsController`の`new`アクションと`create`アクションがこれまでどおり認証不要になります。

特定のアクションのみアクションコールバックをスキップしたい場合には、`:only`オプションでアクションを指定します。逆に特定のアクションのみアクションコールバックをスキップしたくない場合は、`:except`オプションでアクションを指定します。これらのオプションはアクションコールバックの追加時にも使えるので、最初の場所で選択したアクションに対してだけ実行されるアクションコールバックを追加することも可能です。

NOTE: 同じアクションコールバックを異なるオプションで複数回呼び出しても期待どおりに動作しません。最後に呼び出されたアクションコールバックの定義によって、それまでのアクションコールバックの定義は上書きされます。

[`before_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-before_action
[`skip_before_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-skip_before_action

### afterアクションコールバックとaroundアクションコールバック

「before系」アクションコールバック以外に、アクションの実行後に実行されるアクションコールバックや、実行前実行後の両方で実行されるアクションコールバックも利用できます。

「after系」アクションコールバックは[`after_action`][]で登録します。「before系」アクションコールバックと似ていますが、「after系」アクションコールバックの場合アクションは既に実行済みであり、クライアントに送信されようとしているレスポンスデータにアクセスできる点が「before系」アクションコールバックとは異なります。当然ながら、「after系」アクションコールバックをどのように書いても、アクションの実行は中断されません。ただし、「after系」アクションコールバックは、アクションが成功した後にしか実行されず、リクエストサイクルの途中で例外が発生した場合は実行されませんのでご注意ください。

「around系」アクションコールバックは[`around_action`][]で登録します。「around系」アクションコールバックを使う場合は、これはRackミドルウェアの動作と同様に、アクションコールバック内のどこかで必ず`yield`を実行して、関連付けられたアクションを実行する義務が生じます。

たとえば、何らかの変更に際して承認ワークフローがあるWebサイトを考えてみましょう。以下のコードでは、管理者がこれらの変更内容を簡単にプレビューし、トランザクション内で承認できるようになります。

```ruby
class ChangesController < ApplicationController
  around_action :wrap_in_transaction, only: :show

  private
    def wrap_in_transaction
      ActiveRecord::Base.transaction do
        begin
          yield
        ensure
          raise ActiveRecord::Rollback
        end
      end
    end
end
```

「around系」アクションコールバックの作業にはレンダリングも含まれることにご注意ください。特に上の例では、ビュー自身が（スコープなどを使って）データベースを読み出すと、その読み出しはトランザクション内で行われ、データがプレビューに表示されます。

あえて`yield`を実行せず、自分でレスポンスをビルドすることも可能です。この場合、そのコントローラアクションは実行されません。

[`after_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-after_action
[`around_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-around_action

### アクションコールバックのその他の利用法

アクションコールバックの最も一般的な利用方法は、privateメソッドを作成し、そのメソッドを`*_action`で追加することですが、同じ結果を得られるアクションコールバックの利用法は他にも2とおりあります。

1番目は、`*_action` メソッドに直接ブロックを渡すことです。このブロックはコントローラを引数として受け取ります。前述の`require_login`アクションコールバックを書き換えてブロックを使うようにすると、以下のようになります。

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = "このセクションにアクセスするにはログインが必要です"
      redirect_to new_login_url
    end
  end
end
```

このとき、アクションコールバックで`send`メソッドを使っていることにご注意ください。その理由は、`logged_in?`メソッドはprivateであり、コントローラのスコープではアクションコールバックが動作しないためです（訳注: `send`メソッドを使うとprivateメソッドを呼び出せます）。この方法は、特定のアクションコールバックを実装する方法としては推奨されませんが、もっとシンプルな場合には役に立つことがあるかもしれません。

`around_action`のブロックは、`action`内で`yield`も実行します。

```ruby
around_action { |_controller, action| time(&action) }
```

2番目の方法ではクラスを使ってアクションコールバックを処理します（実際には、正しいメソッドに応答するオブジェクトであれば何でも構いません）。他の2つの方法で実装すると読みやすくならず、再利用も困難になるような複雑なケースで有用です。例として、ログインのアクションコールバックをクラスで書き換えてみましょう。

```ruby
class ApplicationController < ActionController::Base
  before_action LoginActionCallback
end

class LoginActionCallback
  def self.before(controller)
    unless controller.send(:logged_in?)
      controller.flash[:error] = "このセクションにアクセスするにはログインが必要です"
      controller.redirect_to controller.new_login_url
    end
  end
end
```

この例も、アクションコールバックとして理想的なものではありません。その理由は、このアクションコールバックがコントローラのスコープで動作せず、コントローラが引数として渡されるからです。このアクションコールバッククラスには、アクションコールバックと同じ名前のメソッドを実装する必要があります。従って、`before_action`アクションコールバックの場合、クラスに`before`メソッドを実装するなどの処置が必要になります。`around`メソッド内では、`yield`を呼んでアクションを実行しなければなりません。

リクエストフォージェリからの保護
--------------------------

クロスサイトリクエストフォージェリ（cross-site request forgery）は攻撃手法の一種です。悪質なWebサイトがユーザーをだまして、ユーザーが気づかないうちに攻撃目標となるWebサイトへの危険なリクエストを作成させるというものです。攻撃者は標的ユーザーに関する知識や権限を持っていなくても、目標サイトに対してデータの追加・変更・削除を行わせることができてしまいます。

この攻撃を防ぐために必要な手段の第一歩は、「create/update/destroyのような破壊的な操作に対して絶対にGETリクエストでアクセスできない」ようにすることです。WebアプリケーションがRESTful規約に従っていれば、これは守られているはずです。しかし、引き続き悪質なWebサイトはGET以外のリクエストを目標サイトに送信することなら簡単にできてしまいます。リクエストフォージェリはまさにこの部分を保護するためのものであり、文字どおり偽造リクエスト（forged requests）から保護します。

具体的な保護方法は、サーバーだけが知っている推測不可能なトークンをすべてのリクエストに追加することです。これにより、リクエストに不正なトークンが含まれているとサーバーはアクセスを拒否します。

以下のようなフォームを試しに生成してみます。

```erb
<%= form_with model: @user do |form| %>
  <%= form.text_field :username %>
  <%= form.text_field :password %>
<% end %>
```

以下のようにトークンが隠しフィールドに追加されている様子がわかります。

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- フィールド -->
</form>
```

Railsは、[formヘルパー](form_helpers.html)で生成されたあらゆるフォームにトークンを追加するので、この攻撃を心配する必要はほとんどありません。formヘルパーを使わずにフォームを手作りした場合や、別の理由でトークンが必要な場合には、`form_authenticity_token`メソッドでトークンを生成できます。

`form_authenticity_token`メソッドは、有効な認証トークンを生成します。このメソッドは、カスタムAjax呼び出しなどのように、Railsが自動的にトークンを追加しない場所で使うのに便利です。

本ガイドの[セキュリティガイド](security.html)では、この話題を含む多くのセキュリティ問題について解説しており、Webアプリケーションを開発するうえで必読です。

`request`オブジェクトと`response`オブジェクト
--------------------------------

すべてのコントローラには、現在実行中のリクエストサイクルに関連するリクエストオブジェクトとレスポンスオブジェクトを指す、2つのアクセサメソッドがあります。[`request`][]メソッドは`ActionDispatch::Request`クラスのインスタンスを含みます。[`response`][]メソッドは、クライアントに戻されようとしている内容を表すレスポンスオブジェクトを返します。

[`ActionDispatch::Request`]: https://api.rubyonrails.org/classes/ActionDispatch/Request.html
[`request`]: https://api.rubyonrails.org/classes/ActionController/Base.html#method-i-request
[`response`]: https://api.rubyonrails.org/classes/ActionController/Base.html#method-i-respons

### `request`オブジェクト

リクエストオブジェクトには、クライアントブラウザから返されるリクエストに関する有用な情報が多数含まれています。利用可能なメソッドをすべて知りたい場合は[Rails APIドキュメント](https://api.rubyonrails.org/classes/ActionDispatch/Request.html)と[Rackドキュメント](https://www.rubydoc.info/github/rack/rack/Rack/Request)を参照してください。その中から、このオブジェクトでアクセス可能なメソッドを紹介します。

| `request`のプロパティ                     | 目的                                                                          |
| ----------------------------------------- | -------------------------------------------------------------------------------- |
| `host`                                      | リクエストで使われるホスト名                                              |
| `domain(n=2)`                               | ホスト名の右（TLD:トップレベルドメイン）から数えて`n`番目のセグメント            |
| `format`                                    | クライアントからリクエストされた`Content-Type`ヘッダー                                        |
| `method`                                    | リクエストで使われるHTTPメソッド                                            |
| `get?`、`post?`、`patch?`、`put?`、`delete?`、`head?` | HTTPメソッドがGET/POST/PATCH/PUT/DELETE/HEADのいずれかの場合にtrueを返す               |
| `headers`                                   | リクエストに関連付けられたヘッダーを含むハッシュを返す               |
| `port`                                      | リクエストで使われるポート番号（整数）                                 |
| `protocol`                                  | プロトコル名に"://"を加えたものを返す（"http://"など） |
| `query_string`                              | URLの一部で使われるクエリ文字（"?"より後の部分）                    |
| `remote_ip`                                 | クライアントのIPアドレス                                                    |
| `url`                                       | リクエストで使われるURL全体                                             |

#### `path_parameters`、`query_parameters`、`request_parameters`

Railsは、リクエストに関連するすべてのパラメータを`params`ハッシュに集約します。これは、クエリ文字列の場合も、POSTのbodyで送信されたパラメータの場合も同様です。`request`オブジェクトには3つのアクセサメソッドがあり、パラメータの由来に応じたアクセスも可能です。[`query_parameters`][]ハッシュにはクエリ文字列として送信されたパラメータが含まれます。[`request_parameters`][]ハッシュにはPOSTのbodyの一部として送信されたパラメータが含まれます。
[`path_parameters`][]には、ルーティング機構によって特定のコントローラとアクションへのパスの一部であると認識されたパラメータが含まれます。

[`path_parameters`]: https://api.rubyonrails.org/classes/ActionDispatch/Http/Parameters.html#method-i-path_parameters
[`query_parameters`]: https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-query_parameters
[`request_parameters`]: https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-request_parameters

### `response`オブジェクト

responseオブジェクトを直接使うことは通常ありません。しかし、たとえば「after系」アクションコールバック内などで`response`オブジェクトを直接操作できると便利です。`response`オブジェクトのアクセサメソッドにセッターがあれば、それを利用して`response`オブジェクトの値を直接変更できます。利用可能なメソッドをすべて知りたい場合は[Rails APIドキュメント](https://api.rubyonrails.org/classes/ActionDispatch/Response.html)と[Rackドキュメント](https://www.rubydoc.info/github/rack/rack/Rack/Response)を参照してください。

| `response`のプロパティ | 目的                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| body                   | クライアントに送り返されるデータの文字列（HTMLで最もよく使われる）                |
| status                 | レスポンスのステータスコード（200 OK、404 file not foundなど）|
| location               | リダイレクト先URL（存在する場合）                                                  |
| content_type           | レスポンスのContent-Type ヘッダー                                                           |
| charset                | レスポンスで使われる文字セット（デフォルトは"utf-8"）                                  |
| headers                | レスポンスで使われるヘッダー                                                                      |

#### カスタムヘッダーを設定する

レスポンスでカスタムヘッダーを使いたい場合は、`response.headers`を利用できます。このヘッダー属性はハッシュであり、ヘッダ名と値がその中でマップされています。一部の値はRailsによって自動的に設定されます。ヘッダに追加・変更を行いたい場合は以下のように`response.headers`に代入します。

```ruby
response.headers["Content-Type"] = "application/pdf"
```

NOTE: 上の場合、直接`content_type`セッターを使う方がずっと自然です。

HTTP認証
--------------------

Railsには3種類のHTTP認証機構が組み込まれています。

* BASIC認証
* ダイジェスト認証
* トークン認証

### HTTP BASIC認証

HTTP BASIC認証は認証スキームの一種であり、主要なブラウザおよびHTTPクライアントでサポートされています。例として、Webアプリケーションに管理画面があり、ブラウザのHTTP BASIC認証ダイアログウィンドウでユーザー名とパスワードを入力しないとアクセスできないようにしたいとします。組み込み認証メカニズムを使えば、以下の[`http_basic_authenticate_with`][]メソッドだけでできます。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

このとき、`AdminsController`を継承した名前空間付きのコントローラを作成することもできます。このアクションコールバックは、該当するコントローラのすべてのアクションで実行されるので、それらをHTTP BASIC認証で保護できるようになります。

[`http_basic_authenticate_with`]: https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods/ClassMethods.html#method-i-http_basic_authenticate_with

### HTTPダイジェスト認証

HTTPダイジェスト認証は、BASIC認証よりも高度な認証システムであり、暗号化されていない平文パスワードをネットワークに送信しなくて済む利点があります (BASIC認証も、HTTPS上で行えば安全になります)。RailsのHTTPダイジェスト認証は、以下の[`authenticate_or_request_with_http_digest`][]メソッドだけでできます。

[`authenticate_or_request_with_http_digest`]: https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Digest/ControllerMethods.html#method-i-authenticate_or_request_with_http_digest

```ruby
class AdminsController < ApplicationController
  USERS = { "lifo" => "world" }

  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

上の例で示したように、`authenticate_or_request_with_http_digest`のブロックでは引数を1つ（ユーザー名）だけ受け取ります。ブロックからはパスワードが返されます。`authenticate_or_request_with_http_digest`が`nil`または`false`が返すと、認証が失敗します。

### HTTPトークン認証

HTTPトークン認証は、HTTPの`Authorization`ヘッダー内で[Bearerトークン](https://ja.wikipedia.org/wiki/Bearer%E3%83%88%E3%83%BC%E3%82%AF%E3%83%B3)を利用可能にするスキームです。本ガイドでは触れませんが、トークン認証ではさまざまなフォーマットや記述方法を利用できます。

例として、事前に発行された認証トークンを利用して認証とアクセスを行えるようにしたいとします。Railsのトークン認証の実装は、以下の[`authenticate_or_request_with_http_token`][]メソッドだけでできます。

```ruby
class PostsController < ApplicationController
  TOKEN = "secret"

  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
      end
    end
end
```

上の例のように、`authenticate_or_request_with_http_token`のブロックでは、「トークン」と「HTTP `Authorization`ヘッダーを解析したオプションを含む`Hash`」という2個の引数を受け取ります。このブロックは、認証が成功した場合は`true`を返し、認証に失敗した場合は`false`か`nil`を返す必要があります。

[`authenticate_or_request_with_http_token`]: https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_or_request_with_http_token

ストリーミングとファイルダウンロード
----------------------------

HTMLをレンダリングせずに、ユーザーにファイルを直接送信したい場合があります。[`send_data`][]メソッドと[`send_file`][]メソッドはRailsのすべてのコントローラで利用でき、いずれもストリームデータをクライアントに送信するのに使います。`send_file`は、ディスク上のファイル名を取得することも、ファイルの内容をストリーミングすることもできる便利なメソッドです。

クライアントにデータをストリーミングするには、`send_data`を使います。

```ruby
require "prawn"
class ClientsController < ApplicationController
  # クライアントに関する情報を含むPDFを生成し、
  # 返します。ユーザーはPDFをファイルダウンロードとして取得できます。
  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private
    def generate_pdf(client)
      Prawn::Document.new do
        text client.name, align: :center
        text "Address: #{client.address}"
        text "Email: #{client.email}"
      end.render
    end
end
```

上の例の`download_pdf`アクションは、呼び出されたprivateメソッドで実際のPDFを生成し、結果を文字列として返します。続いてこの文字列がファイルダウンロードとしてクライアントにストリーミング送信されます。このときにクライアントで保存ダイアログが表示され、そこにファイル名が表示されます。
ストリーミング送信するファイルをクライアント側でファイルとしてダウンロードできないようにしたい場合があります。たとえば、HTMLページに埋め込める画像ファイルで考えてみましょう。このとき、このファイルはダウンロード用ではないということをブラウザに伝えるには、`:disposition`オプションで"inline"を指定します。逆のオプションは"attachment"で、こちらはストリーミングのデフォルト設定です。

[`send_data`]: https://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_data
[`send_file`]: https://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file

### ファイルを送信する

サーバーのディスク上に既にあるファイルを送信するには、`send_file`メソッドを使います。

```ruby
class ClientsController < ApplicationController
  # ディスク上に生成・保存済みのファイルをストリーミング送信する
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

上のコードはファイルを4KBずつ読み出してストリーミング送信します。これは、巨大なファイルを一度にメモリに読み込まないようにするためです。分割読み出しは`:stream`オプションでオフにすることも、`:buffer_size`オプションでブロックサイズを調整することも可能です。

`:type`オプションが未指定の場合、`:filename`で取得したファイル名の拡張子から推測して与えられます。拡張子に該当するContent-TypeヘッダーがRailsに登録されていない場合、`application/octet-stream`が使われます。

WARNING: サーバーのディスク上のファイルパスを指定するときに、（paramsやcookieなどの）クライアントが入力したデータを使う場合は十分な注意が必要です。クライアントから悪質なファイルパスが入力されると、開発者が意図しないファイルにアクセスされてしまうというセキュリティ上のリスクが生じる可能性を常に念頭に置いてください。

TIP: 静的なファイルをRailsからストリーミング送信することはおすすめできません。ほとんどの場合、Webサーバーのpublicフォルダに置いてダウンロードさせれば済むはずです。Railsからストリーミングでダウンロードするよりも、ApacheなどのWebサーバーから直接ファイルをダウンロードする方がはるかに効率が高く、しかもRailsスタック全体を経由する不必要なリクエストを受信せずに済みます。

### RESTfulなダウンロード

`send_data`は問題なく利用できますが、真にRESTfulなアプリケーションを作成しているときに、ファイルダウンロード専用のアクションを別途作成する必要は通常ありません。RESTという用語においては、上の例で使われているPDFファイルのようなものは、クライアントリソースを別の形で表現したものであると見なされます。Railsには、これに基づいた「RESTful」ダウンロードを手軽に実現するための洗練された方法も用意されています。以下は上の例を変更して、PDFダウンロードをストリーミングとして扱わずに`show`アクションの一部として扱うようにしたものです。

```ruby
class ClientsController < ApplicationController
  # ユーザーはリソース受信時にHTMLまたはPDFをリクエストできる
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

この`format`では、RailsによってMIME タイプとして登録されている拡張機能である任意のメソッドを呼び出せます。
Railsには既に`"text/html"`や`"application/pdf"`などの一般的な MIMEタイプが登録されています。

```ruby
Mime::Type.lookup_by_extension(:pdf)
# => "application/pdf"
```

なお、この例が実際に動作するには、RailsのMIME typeに"PDF"を追加する必要があります。これを行なうには、`config/initializers/mime_types.rb`に以下を追加します。

MIMEタイプを追加する必要が生じた場合は、`config/initializers/mime_types.rb`ファイル内で[`Mime::Type.register`](https://api.rubyonrails.org/classes/Mime/Type.html#method-c-register)を呼び出してください。たとえば、RTF（リッチテキスト形式）を登録するには以下のように呼び出します。

```ruby
Mime::Type.register("application/rtf", :rtf)
```

NOTE: Railsの設定ファイルは起動時にしか読み込まれません。上の設定変更を反映するには、サーバーを再起動する必要があります。

これで、以下のようにURLに".pdf"を追加するだけでPDF版のclientを取得できます。

```bash
GET /clients/1.pdf
```

### 任意のデータをライブストリーミングする

Railsは、ファイル以外のものもストリーミング送信できます。実は`response`オブジェクトに含まれるものなら何でもストリーミング送信できます。[`ActionController::Live`][]モジュールを使うと、ブラウザとの永続的なコネクションを作成できます。これにより、いつでも好きなタイミングで任意のデータをブラウザに送信できるようになります。

[`ActionController::Live`]: https://api.rubyonrails.org/classes/ActionController/Live.html

#### ライブストリーミングを利用する

コントローラクラスで`ActionController::Live`を`include`すると、そのコントローラのすべてのアクションでデータをストリーミングできるようになります。このモジュールは以下のようにミックスインできます。

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

上のコードは、ブラウザとの間に永続的なコネクションを確立し、1秒おきに`"hello world\n"`を100個ずつ送信します。

上の例には注意点がいくつもあります。レスポンスのストリームは確実に閉じる必要があります。ストリームを閉じ忘れると、ソケットが永久に開いたままになってしまいます。レスポンスストリームへの書き込みを行う前に、Content-Typeヘッダーに`text/event-stream`を設定する必要もあります。その理由は、（`response.committed?`が「truthy」な値を返したときに）レスポンスがコミットされると、以後ヘッダーに書き込みできなくなるためです。これは、レスポンスストリームに対して`write`または`commit`を行った場合に発生します。

#### 利用例

カラオケマシンを開発していて、あるユーザーが特定の曲の歌詞を表示したいとします。`Song`ごとに特定の行数のデータがあり、各行に「後何拍あるか」を表す`num_beats`が記入されているとします。

歌詞を「カラオケスタイル」でユーザーに表示したいので、直前の歌詞を歌い終わってから次の歌詞を表示することになります。このようなときは、以下のように`ActionController::Live`を利用できます。

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    song = Song.find(params[:id])

    song.each do |line|
      response.stream.write line.lyrics
      sleep line.num_beats
    end
  ensure
    response.stream.close
  end
end
```

上のコードでは、客が直前の歌詞を歌い終わった場合にのみ、次の歌詞を送信しています。

#### ストリーミングで考慮すべき点

任意のデータをストリーミング送信できることは、きわめて強力なツールとなります。これまでの例でご紹介したように、任意のデータをいつでもレスポンスストリームで送信できます。ただし、以下の点についてご注意ください。

* レスポンスストリームを作成するたびに新しいスレッドが作成され、元のスレッドからスレッドローカルな変数がコピーされます。スレッドローカルな変数が増えすぎたり、スレッド数が増えすぎると、パフォーマンスに悪影響が生じます。
* レスポンスストリームを閉じることに失敗すると、該当のソケットが永久に開いたままになってしまいます。レスポンスストリームを使う場合は、`close`を確実に呼び出してください。
* WEBrickサーバーはすべてのレスポンスをバッファリングするので、`ActionController::Live`を`include`しても動作しません。このため、レスポンスを自動的にバッファリングしないWebサーバーを使う必要があります。

ログをフィルタする
-------------

Railsのログファイルは、環境ごとに`log`フォルダの下に出力されます。デバッグ時にアプリケーションで何が起こっているかをログで確認できると非常に便利ですが、production環境のアプリケーションでは顧客のパスワードのような重要な情報をログファイルに出力したくないでしょう。

### パラメータをフィルタする

Railsアプリケーションの設定ファイル[`config.filter_parameters`][]には、特定のリクエストパラメータをログ出力時にフィルタで除外する設定を追加できます。
フィルタされたパラメータはログ内で`[FILTERED]`という文字に置き換えられます。

```ruby
config.filter_parameters << :password
```

NOTE: 渡されるパラメータは、正規表現の「部分マッチ」によってフィルタされる点にご注意ください。Railsは適切なイニシャライザ（`initializers/filter_parameter_logging.rb`）にデフォルトで`:password`を追加し、アプリケーションの典型的な`password`パラメータや`password_confirmation`パラメータも同様にフィルタで除外します。

[`config.filter_parameters`]: configuring.html#config-filter-parameters

### リダイレクトをフィルタする

アプリケーションが機密性の高いURLにリダイレクトされる場合は、ログに出力するのは好ましくありません。
設定の`config.filter_redirect`オプションを使って、リダイレクト先URLをログに出力しないようにできます。

```ruby
config.filter_redirect << 's3.amazonaws.com'
```

フィルタしたいリダイレクト先は、文字列か正規表現、またはそれらを含む配列で指定できます。

```ruby
config.filter_redirect.concat ['s3.amazonaws.com', /private_path/]
```

マッチしたURLはログで`[FILTERED]`という文字に置き換えられます。ただし、URL全体ではなくパラメータのみをフィルタで除外したい場合は、[パラメータをフィルタする](#パラメータをフィルタする)を参照してください。

`rescue`
------

どんなアプリケーションでも、バグが潜んでる可能性や、適切に扱う必要のある例外をスローする可能性があるものです。たとえば、データベースに既に存在しなくなったリソースに対してユーザーがアクセスすると、Active Recordは`ActiveRecord::RecordNotFound`例外をスローします。

Railsのデフォルトの例外ハンドリングでは、例外の種類にかかわらず「500 Server Error」を表示します。ローカルブラウザからのリクエストであれば詳細なトレースバックや追加情報が表示されるので、問題点を把握して対応することができます。リモートブラウザからのリクエストの場合は「500 Server Error」や「404 Not Found」などのメッセージだけをユーザーに表示します。

こうしたエラーのキャッチ方法やユーザーへの表示方法をカスタマイズして表示を改善したいことはよくあります。Railsアプリケーションでは、例外ハンドリングをさまざまなレベルで実行できます。

### デフォルトの500・404テンプレート

デフォルトでは、本番のRailsアプリケーションは404または500エラーメッセージを表示します（development環境の場合はあらゆるunhandled exceptionを表示します）。これらのエラーメッセージには、`public`フォルダ以下に置かれている静的なHTMLファイル（`404.html`および`500.html`）が使われます。これらのファイルをカスタマイズすることで、情報やスタイルを追加できるようになります。ただし、これらはあくまで静的なHTMLファイルなので、レイアウトでERBやSCSSやCoffeeScriptを利用できません。

### `rescue_from`

もう少し洗練された方法でエラーをキャッチしたい場合は、[`rescue_from`][]を使えます。これにより、1つ以上の例外を1つのコントローラ全体およびそのサブクラスで扱えるようになります。

`rescue_from`キャッチできる例外が発生すると、ハンドラに例外オブジェクトが渡されます。このハンドラはメソッドか、`:with`オプション付きで渡された`Proc`オブジェクトのいずれかです。明示的に`Proc`オブジェクトを使う代わりに、ブロックを直接使うことも可能です。

`rescue_from`を使ってすべての`ActiveRecord::RecordNotFound`エラーをインターセプトし、処理を行なう方法を以下に示します。

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private
    def record_not_found
      render plain: "404 Not Found", status: 404
    end
end
```

先ほどよりもコードが洗練されましたが、もちろんこれだけではエラーハンドリングは何も改良されていません。しかしこのようにすべての例外をキャッチ可能にすることで、以後は自由にカスタマイズできるようになります。たとえば、以下のようなカスタム例外クラスを作成すると、アクセス権を持たないユーザーがアプリケーションの特定部分にアクセスした場合に例外をスローできます。

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private
    def user_not_authorized
      flash[:error] = "このセクションへのアクセス権がありません"
      redirect_back(fallback_location: root_path)
    end
end

class ClientsController < ApplicationController
  # ユーザーがクライアントにアクセスする権限を持っているかどうかをチェックする
  before_action :check_authorization

  # このアクション内で認証周りを気にする必要はない
  def edit
    @client = Client.find(params[:id])
  end

  private
    # ユーザーが認証されていない場合は単に例外をスローする
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

WARNING: `rescue_from`で`Exception`や`StandardError`を指定すると、Railsでの正しい例外ハンドリングが阻害されて深刻な副作用が生じる可能性があります。よほどの理由がない限り、このような指定はおすすめできません。

NOTE: `ActiveRecord::RecordNotFound`エラーは、production環境では常に404エラーページを表示します。この振る舞いをカスタマイズする必要がない限り、開発者がこのエラーを処理する必要はありません。

NOTE: 例外の中には`ApplicationController`クラスでしかrescueできないものがあります。その理由は、コントローラが初期化されてアクションが実行される前に発生する例外があるからです。

[`rescue_from`]: https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

HTTPSプロトコルを強制する
--------------------

コントローラへの通信をHTTPSのみに限定するには、アプリケーション環境の[`config.force_ssl`][]設定で[`ActionDispatch::SSL`][]ミドルウェアを有効にします。

[`config.force_ssl`]: configuring.html#config-force-ssl
[`ActionDispatch::SSL`]: https://api.rubyonrails.org/classes/ActionDispatch/SSL.html
[`ActionDispatch::SSL`]: https://api.rubyonrails.org/classes/ActionDispatch/SSL.html

組み込みのヘルスチェックエンドポイント
------------------------------

Railsには、`/up`パスでアクセス可能な組み込みのヘルスチェックエンドポイントも用意されています。このエンドポイントは、アプリが正常に起動した場合はステータスコード200を返し、例外が発生した場合はステータスコード500を返します。

production環境では、多くのアプリケーションが、問題が発生したときにエンジニアに報告するアップタイムモニタや、ポッドの健全性を判断するロードバランサや、Kubernetesコントローラーなどを用いて、状態を上流側に報告する必要があります。このヘルスチェックは、多くの状況で利用できるように設計されています。

新しく生成されたRailsアプリケーションのヘルスチェックは`/up`にありますが、`config/routes.rb`でパスを自由に設定できます。

```ruby
Rails.application.routes.draw do
  get "healthz" => "rails/health#show", as: :rails_health_check
end
```

上の設定によって、`/healthz`パスでヘルスチェックにアクセスできるようになります。

NOTE: このエンドポイントは、データベースやredisクラスタなど、アプリケーションのあらゆる依存関係のステータスを反映するものではありません。アプリケーション固有のニーズについては、`rails/health#show`を独自のコントローラアクションに置き換えてください。

ヘルスチェックで何をチェックするかは慎重に検討しましょう。場合によっては、サードパーティのサービスの不具合でアプリケーションが再起動するような事態を招く可能性もあります。理想的には、そのような停止を優雅に処理できるようにアプリケーションを設計する必要があります。
