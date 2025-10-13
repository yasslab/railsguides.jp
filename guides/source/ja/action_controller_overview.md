Action Controller の概要
==========================

本ガイドでは、コントローラの動作と、アプリケーションのリクエストサイクルにおけるコントローラの役割について解説します。

このガイドの内容:

* コントローラを経由するリクエストの流れを理解する
* コントローラに渡されたパラメータにアクセスする方法
* Strong Parametersで値を許可する方法
* データをcookie、セッション、フラッシュに保存する方法
* リクエストの処理中にアクションコールバックでコードを実行する方法
* requestオブジェクトとresponseオブジェクトの使い方

--------------------------------------------------------------------------------

はじめに
--------------------------

Action Controllerは、[MVC](https://ja.wikipedia.org/wiki/Model_View_Controller)アーキテクチャの「C」に相当します。リクエストを処理するコントローラが[ルーター](routing.html)によって決定されると、コントローラはリクエストの意味を理解して適切な出力を行う役目を担います。ありがたいことに、これらの処理のほとんどはAction Controllerが行ってくれます。リクエストは、十分に吟味された規約によって可能な限りわかりやすい形で処理されます。

伝統的な[RESTful](https://ja.wikipedia.org/wiki/REST)アプリケーションでは、コントローラ（C）がリクエストの受信を担当し、モデル（M）がデータの取得や保存を担当し、ビュー（V）がHTML出力を担当します。

つまり、コントローラは「モデルとビューの間を仲介する」と考えられます。コントローラがモデルのデータをビューで利用可能にすることで、データをビューで表示したり、入力されたデータでモデルを更新したりします。

コントローラを作成する
---------------------

Railsのコントローラは、`ApplicationController`を継承したRubyのクラスであり、他のクラスと同様にメソッドが使えます。アプリケーションがブラウザからのリクエストを受け取ると、ルーターによってコントローラとアクションが確定し、Railsはそれに応じてコントローラのインスタンスを生成し、アクション名と同じ名前のメソッドを実行します。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

上の`ClientsController`は、ユーザーがブラウザでアプリケーションの`/clients/new`にアクセスして新しいクライアントを追加すると、`ClientsController`のインスタンスが作成され、そのインスタンスの`new`メソッドが呼び出されます。

`new`メソッドが存在しているが中身が空の場合、Railsはデフォルトで`new.html.erb`ビューを自動的にレンダリングします。

NOTE: この`new`メソッドはインスタンスメソッドなので、`ClientsController`のインスタンスで呼び出されます（つまりインスタンスを作らないと呼び出せません）。`new`メソッドのように、インスタンスを作らずに`ClientsController.new`で呼び出せるクラスメソッドと混同しないようにしましょう。

`new`クラスメソッドを実行したときの典型的な振る舞いは次の通りです。コントローラが`Client`モデルのインスタンスを作成し、それをビューで`@client`というインスタンス変数として利用できるようにします。

```ruby
def new
  @client = Client.new
end
```

NOTE: `ApplicationController`を継承したすべてのコントローラは、最終的に[`ActionController::Base`][]を継承します。ただし、[API専用アプリケーション](https://guides.rubyonrails.org/api_app.html)の場合のみ、`ApplicationController`は[`ActionController::API`][]を継承します。


[`ActionController::Base`]:
  https://api.rubyonrails.org/classes/ActionController/Base.html
[`ActionController::API`]:
  https://edgeapi.rubyonrails.org/classes/ActionController/API.html

コントローラの命名規約
---------------------

Railsのコントローラ名には、基本的に英語の「複数形」を使うのが望ましい命名です（ただし末尾の「Controller」という語は固定です）。たとえば、`ClientsController`の方が`ClientController`より好ましく、`SiteAdminsController`の方が`SiteAdminController`や`SitesAdminsController`よりも好ましいといった具合です。
なお、この規約は絶対ではありません（実際`ApplicationController`はApplicationが単数形です）。

しかし、この規約は守っておくことをおすすめします。規約を守ることで、[`:controller`](routing.html#利用するコントローラを指定する)オプションをわざわざ書かなくても、`resources`などの[デフォルトのルーティングジェネレーター](routing.html#crud、verb、アクション)をそのまま利用できるようになりますし、生成される名前付きルーティングヘルパー名もアプリケーション全体で一貫するからです。

コントローラの命名規約はモデルの命名規約と異なることにご注意ください。コントローラ名は「複数形」が望ましい命名ですが、[モデル名](active_record_basics.html#命名規約)は「単数形」が望ましい命名です。

コントローラのアクションは、アクションとして呼び出し可能なpublicメソッドでなければなりません。ヘルパーメソッドのような「アクションとして外部から呼び出したくない」メソッドには、`private`や`protected`を指定して公開しないようにするのが定石です。

WARNING: ある種のメソッド名はAction Controllerで予約されているため、利用できません。予約済みメソッドを誤ってアクションやヘルパーメソッドとして再定義すると、`SystemStackError`が発生する可能性があります。コントローラ内でRESTfulな[リソースルーティング][]アクションだけを使うようにしていれば、メソッド名が使えなくなる心配はありません。

NOTE: 予約済みメソッド名をアクション名として使わざるを得ない場合は、たとえばカスタムルーティングを利用して、予約済みメソッド名を予約されていないアクションメソッド名に対応付けるという回避策が考えられます。

[リソースルーティング]:
  routing.html#リソースベースのルーティング-railsのデフォルト

パラメータ
----------

リクエストによって送信されたデータを受信すると、コントローラ内では[`params`][]ハッシュとして利用できます。パラメータのデータには以下の2種類があります:

- URL の一部として送信される**クエリ文字列パラメータ**
  （例: `http://example.com/accounts?filter=free`の`?`以降の`filter=free`の部分）
- HTMLフォームから送信される**`POST`パラメータ**

Railsは、クエリ文字列パラメータと`POST`パラメータを区別しません。以下のように、どちらもコントローラの`params`ハッシュで同じように利用できます。

```ruby
class ClientsController < ApplicationController
  # このアクションは、"/clients?status=activated"というURLへの
  # HTTP GETリクエストからクエリ文字列パラメータを受け取る
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # このアクションは、"/clients"というURLへのHTTP POSTリクエストに含まれる
  # リクエストbody内のフォームデータからパラメータを受け取る
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      render "new"
    end
  end
end
```

NOTE: `params`ハッシュは、Rubyの単なる`Hash`ではなく、[`ActionController::Parameters`][]オブジェクトである点にご注意ください。このオブジェクトはRubyの`Hash`のように振る舞いますが、`Hash`を継承していません。また、`params`をフィルタリングするためのメソッドが提供され、シンボルキー`:foo`と文字列キー`"foo"`が同じものと見なされる点も`Hash`と異なります。

[`params`]:
  https://api.rubyonrails.org/classes/ActionController/StrongParameters.html#method-i-params
[`ActionController::Parameters`]:
  https://api.rubyonrails.org/classes/ActionController/Parameters.html

### ハッシュと配列のパラメータ

`params`ハッシュには、一次元のキーバリューペアの他に、ネストした配列やハッシュも保存できます。値の配列をフォームから送信するには、以下のようにキー名に空の角かっこ`[]`のペアを追加します。

```
GET /users?ids[]=1&ids[]=2&ids[]=3
```

NOTE: `[`や`]`はURLで利用できない文字なので、この例の実際のURLは`/users?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3`のようになります。これについては、ブラウザで自動的にエンコードされ、Railsがパラメータを受け取るときに自動的に復元するので、開発者が気にする必要はほとんどありません。ただし、何らかの理由でサーバーにリクエストを手動送信しなければならない場合には、このことを思い出す必要があるでしょう。

これで、受け取った`params[:ids]`の値は`["1", "2", "3"]`になりました。ここで重要なのは、**パラメータの値は常に「文字列」になる**ことです。Railsはパラメータの型推測や型変換を行いません。

NOTE: `params`の中にある`[nil]`や`[nil, nil, ...]`などの値は、セキュリティ上の理由でデフォルトでは`[]`に置き換えられます。詳しくは[セキュリティガイド](security.html#安全でないクエリ生成)を参照してください。

フォームからハッシュを送信するには、以下のようにキー名を角かっこ`[]`の中に置きます。

```html
<form accept-charset="UTF-8" action="/users" method="post">
  <input type="text" name="user[name]" value="Acme" />
  <input type="text" name="user[phone]" value="12345" />
  <input type="text" name="user[address][postcode]" value="12345" />
  <input type="text" name="user[address][city]" value="Carrot City" />
</form>
```

このフォームを送信すると、`params[:user]`の値は以下のようになります。`params[:user][:address]`のハッシュがネストしていることにご注目ください。

```ruby
{ "name" => "Acme",
  "phone" => "12345",
  "address" => {
    "postcode" => "12345",
    "city" => "Carrot City"
  }
}
```

この`params`オブジェクトの振る舞いはRubyの`Hash`と似ていますが、キー名にシンボルと文字列のどちらでも指定できる点が`Hash`と異なります。

### 複合主キーのパラメータ

[複合キーパラメータ](active_record_composite_primary_keys.html)は、1個のパラメータに複数の値を含み、値同士は区切り文字（アンダースコアなど）で区切られます。したがって、Active Recordに渡すには個別の値を抽出する必要があります。これを行うには、[`extract_value`][]メソッドを使います。

たとえば以下のコントローラがあるとします。

```ruby
class BooksController < ApplicationController
  def show
    # URLパラメータから複合ID値を抽出する
    id = params.extract_value(:id)
    @book = Book.find(id)
  end
end
```

ルーティングは以下のようになっているとします。

```ruby
get "/books/:id", to: "books#show"
```

ユーザーが`/books/4_2`というURLでリクエストを送信すると、コントローラは複合キー値`["4", "2"]`を抽出してから`Book.find`に渡します。このように`extract_value`メソッドを使うことで、区切り文字で区切られたパラメータから配列を抽出できます。

[`extract_value`]:
  https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-extract_value

### JSONパラメータ

アプリケーションでAPIを公開している場合、パラメータをJSON形式で受け取ることになるでしょう。リクエストの[`Content-Type`][]ヘッダーが`application/json`に設定されていると、Railsは自動的にパラメータを`params`ハッシュに読み込んで、通常と同じようにアクセスできるようになります。

たとえば、以下のJSONコンテンツを送信したとします。

```json
{ "user": { "name": "acme", "address": "123 Carrot Street" } }
```

このとき、コントローラは以下を受け取ります。

```ruby
{ "user" => { "name" => "acme", "address" => "123 Carrot Street" } }
```

[`Content-Type`]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Content-Type

#### `wrap_parameters`を設定する

[`wrap_parameters`][]メソッドを使うと、コントローラ名がJSONパラメータに自動で追加されます。たとえば、以下のJSONは`:user`というrootキープレフィックスなしで送信できます。

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

上のデータを`UsersController`に送信すると、以下のように`:user`キー内にラップされたJSONデータも追加されます。

```ruby
{ name: "acme", address: "123 Carrot Street", user: { name: "acme", address: "123 Carrot Street" } }
```

NOTE: `wrap_parameters`は、コントローラ名と同じキー内のハッシュにパラメータの複製を追加します。その結果、`params`ハッシュには、パラメータの元のバージョンと「ラップされた」バージョンのパラメータの**両方が存在する**ことになります。

この機能は、パラメータを複製してから、コントローラ名に基づいて選択したキーを用いてラップします。これを制御する[`config.action_controller.wrap_parameters_by_default`][]設定はデフォルトで`true`に設定されていますが、パラメータをラップしたくない場合は以下のように`false`に設定できます。

```ruby
config.action_controller.wrap_parameters_by_default = false
```

キー名のカスタマイズ方法や、ラップしたいパラメータを指定する方法について詳しくは、[`ActionController::ParamsWrapper`][] APIドキュメントを参照してください。

NOTE: 訳注: 従来のXMLパラメータ解析のサポートは、Rails 4.0のときに[`actionpack-xml_parser`][]というgemに切り出されました。

[`wrap_parameters`]:
  https://api.rubyonrails.org/classes/ActionController/ParamsWrapper/Options/ClassMethods.html#method-i-wrap_parameters
[`config.action_controller.wrap_parameters_by_default`]:
  configuring.html#config-action-controller-wrap-parameters-by-default
[`ActionController::ParamsWrapper`]:
  https://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html
[`actionpack-xml_parser`]:
  https://github.com/rails/actionpack-xml_parser

### ルーティングパラメータ

パラメータを`routes.rb`ファイル内のルーティング宣言の一部として指定すると、そのパラメータを`params`ハッシュでも利用可能になります。たとえば、クライアントの`:status`パラメータを取得するルーティングは以下のように追加できます。

```ruby
get "/clients/:status", to: "clients#index", foo: "bar"
```

この場合、ブラウザで`/clients/active`というURLを開くと、`params[:status]`が`"active"`（有効）に設定されます。このルーティングを使うと、クエリ文字列で渡したのと同様に`params[:foo]`にも`"bar"`が設定されます。

ルーティング宣言で定義された他のパラメータ（`:id` など）にも同様にアクセスできます。

NOTE: 上の例では、コントローラは`params[:action]`を`"index"`として、`params[:controller]`を`"clients"`として受け取ります。`params`ハッシュには常に`:controller`キーと`:action`キーが含まれますが、これらの値にアクセスする場合は、`params[:controller]`や`params[:action]`のような方法ではなく、[`controller_name`][]メソッドや[`action_name`][]メソッドを使うことが推奨されます。

[`controller_name`]:
  https://api.rubyonrails.org/classes/ActionController/Metal.html#method-i-controller_name
[`action_name`]:
  https://api.rubyonrails.org/classes/AbstractController/Base.html#method-i-action_name

### `default_url_options`メソッド

コントローラで以下のように`default_url_options`という名前のメソッドを定義すると、[`url_for`][]ヘルパーのグローバルなデフォルトパラメータを設定できます。

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

このメソッドで指定したデフォルトパラメータは、URLを生成する際の開始点として使われるようになります。これらのデフォルトパラメータは、`url_for`に渡したオプションや、`posts_path`などのパスヘルパーで上書きできます。たとえば、`locale: I18n.locale`を設定すると、Railsは以下のようにすべてのURLにロケールを自動的に追加します。

```ruby
posts_path # => "/posts?locale=en"
```

このパラメータは、必要に応じて以下のように上書きできます。

```ruby
posts_path(locale: :fr) # => "/posts?locale=fr"
```

NOTE: `posts_path`ヘルパーは、内部的には`url_for`を適切なパラメータで呼び出すためのショートハンドです。

`ApplicationController`で上の例のように`default_url_options`を定義すると、これらのデフォルトパラメータがすべてのURL生成で使われるようになります。この`default_url_options`メソッドは特定のコントローラで定義することも可能で、その場合は、そのコントローラ用に生成されたURLにのみ適用されます。

リクエストを受け取ったときに、生成されたURLごとにこのメソッドが常に呼び出されるとは限りません。パフォーマンス上の理由から、返されたハッシュはリクエストごとにキャッシュされます。

[`url_for`]:
  https://api.rubyonrails.org/classes/ActionView/RoutingUrlFor.html#method-i-url_for

Strong Parameters
-----------------

Action Controllerの[`StrongParameters`](https://api.rubyonrails.org/classes/ActionController/StrongParameters.html)は、明示的に許可されていないパラメータをActive Modelの「マスアサインメント（mass-assignment: 一括代入）」で利用することを禁止します。したがって、開発者は、どの属性でマスアップデート（mass-update: 一括更新）を許可するかをコントローラで必ず明示的に宣言しなければなりません。strong parametersは、ユーザーがモデルの重要な属性を誤って更新してしまうことを防止するためのセキュリティ対策です。

さらに、strong parametersではパラメータを必須（つまり省略不可）として指定できます。リクエストで渡された必須パラメータが不足している場合は、[400 Bad Request][]を返します。

```ruby
class PeopleController < ActionController::Base
  # 以下のコードはActiveModel::ForbiddenAttributesError例外を発生する
  # （明示的に許可していないパラメータを一括で渡してしまう危険な「マスアサインメント」が行われているため）
  def create
    Person.create(params[:person])
  end

  # 以下のコードは`person_params`ヘルパーメソッドを使っているため正常に動作する。
  # このヘルパーメソッドには、マスアサインメントを許可する`expect`呼び出しが含まれている。
  def update
    person = Person.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # 許可するパラメータは、このようにprivateメソッドでカプセル化するのがよい手法である。
    # このヘルパーメソッドは、createとupdateの両方で同じ許可リストを与えるのに使える。
    def person_params
      params.expect(person: [:name, :age])
    end
end
```

[400 Bad Request]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Status/400

### 値を許可する

#### `expect`

Rails 8から導入された[`expect`][]メソッドは、パラメータの必須化とパラメータの許可を同時に行うための簡潔かつ安全な方法を提供します。

```ruby
id = params.expect(:id)
```

上の`expect`は常にスカラー値を返すようになり、配列やハッシュを返すことはありません。

`expect`の別の利用例としてはフォームパラメータがあります。以下のように`expect`を使うことで、rootキーが存在することと、属性が許可されていることを保証できます。

```ruby
user_params = params.expect(user: [:username, :password])
user_params.has_key?(:username) # => true
```

上の例では、`:user`キーが指定のキー（`:username`と`:password`）を持つ「ネストしたハッシュ」でない場合、`expect`はエラーを発生して「400 Bad Request」レスポンスを返します。

パラメータのハッシュ全体に対して（つまりハッシュの内容を問わずに）必須化と許可を同時に行いたい場合は、[`expect`][]で以下のように空ハッシュ`{}`を指定することも「一応」可能です。

```ruby
params.expect(log_entry: {})
```

この場合、`:log_entry`パラメータハッシュとそのサブハッシュはすべて許可済みとして扱われ、スカラー値が許可済みかどうかのチェックも行われなくなるため、どんなサブハッシュを渡してもすべて受け入れるようになります。

WARNING: このように空ハッシュ`{}`を渡して`expect`を呼び出すと、現在のモデル属性だけでなく、今後追加されるすべてモデル属性も無条件にマスアサインメントされる可能性があるため、取り扱いには細心の注意が必要です。

#### `permit`

[`permit`][]を呼び出すと、`params`内の指定したキー（以下の例では`:id`または`:admin`）を`createアクション`や`update`アクションなどのマスアサインメントに含めることを許可できます。

```irb
params = ActionController::Parameters.new(id: 1, admin: "true")
#=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: false>

params.permit(:id)
#=> #<ActionController::Parameters {"id"=>1} permitted: true>

params.permit(:id, :admin)
#=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: true>
```

上で許可した`:id`キーの値は、以下の許可済みスカラー値のいずれかでなければなりません。

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

`permit`を呼び出さなかったキーは、フィルタで除外されます（訳注: エラーは発生しません）。配列やハッシュ、およびその他のオブジェクトは、デフォルトでは挿入されません。

許可済みのスカラー値を要素に持つ配列を`params`の値に含めることを許可するには、以下のようにキーに空配列`[]`を対応付けます。

```irb
params = ActionController::Parameters.new(tags: ["rails", "parameters"])
#=> #<ActionController::Parameters {"tags"=>["rails", "parameters"]} permitted: false>

params.permit(tags: [])
#=> #<ActionController::Parameters {"tags"=>["rails", "parameters"]} permitted: true>
```

ハッシュ値を`params`の値に含めることを許可するには、以下のようにキーに空ハッシュ`{}`を対応付けます。

```irb
params = ActionController::Parameters.new(options: { darkmode: true })
#=> #<ActionController::Parameters {"options"=>{"darkmode"=>true}} permitted: false>

params.permit(options: {})
#=> #<ActionController::Parameters {"options"=>#<ActionController::Parameters {"darkmode"=>true} permitted: true>} permitted: true>
```

上の`permit`呼び出しは、`options`内の値が許可済みのスカラー値であることを保証し、それ以外のものをフィルタで除外します。

WARNING: ハッシュパラメータや、その内部構造の有効なキーをいちいち宣言することが不可能な場合や不便な場合があるため、`permit`に空ハッシュ`{}`を渡せるのは確かに便利ではあります。ただし、上のように`permit`で空ハッシュ`{}`を指定すると、ユーザーがどんなデータでもパラメータとして渡せるようになってしまうことは認識しておかなければなりません。

#### `permit!`

値をチェックせずにパラメータのハッシュ全体を許可する`!`付きの[`permit!`][]メソッドも利用可能です。

```irb
params = ActionController::Parameters.new(id: 1, admin: "true")
#=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: false>

params.permit!
#=> #<ActionController::Parameters {"id"=>1, "admin"=>"true"} permitted: true>
```

WARNING: `permit!`を使うと、現在のモデル属性だけでなく、今後追加されるすべてのモデル属性も無条件にマスアサインメントされる可能性があるため、取り扱いには細心の注意が必要です。

[`permit`]:
    https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-permit
[`permit!`]:
    https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-permit-21
[`expect`]:
    https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-expect

#### ネストしたパラメータを許可する

`expect`（または`permit`）は、以下のようにネストしたパラメータ（ネステッドパラメータ）に対しても使えます。

```ruby
# 期待されるパラメータの例:
params = ActionController::Parameters.new(
  name: "Martin",
  emails: ["me@example.com"],
  friends: [
    { name: "André", family: { name: "RubyGems" }, hobbies: ["keyboards", "card games"] },
    { name: "Kewe", family: { name: "Baroness" }, hobbies: ["video games"] },
  ]
)

# パラメータは以下のexpectによって許可済みであることが保証される:
name, emails, friends = params.expect(
  :name,                 # 許可済みのスカラー値
  emails: [],            # 許可済みのスカラー値の配列
  friends: [[            # 許可済みのParameterハッシュの配列
    :name,               # 許可済みのスカラー値
    family: [:name],     # family: { name: "許可済みのスカラー値" }
    hobbies: []          # 許可済みのスカラー値の配列
  ]]
)
```

この宣言は、`name`属性、`emails`属性、`friends`属性を許可し、それぞれ以下を返すことが前提となっています。

* `emails`属性: 許可済みのスカラー値を要素に持つ配列を返す
* `friends`は特定の属性を持つリソースの配列を返す
  （配列を明示的に必須にするための新しい**二重配列構文`[[ ]]`**が使われていることに注意）
  このリソースには以下の属性が必要:
  * `name`属性: 許可済みの任意のスカラー値
  * `hobbies`属性: 許可済みのスカラー値を要素に持つ配列
  * `family`属性: `name`キーと、任意の許可済みスカラー値を持つハッシュのみに制限される

NOTE: 訳注: この特殊な二重配列構文`[[:属性名]]`は、Rails 8.0に導入された新しい配列マッチング構文です（[#51674](https://github.com/rails/rails/pull/51674)）。`[[:属性名]]`は、（ハッシュではなく）配列を渡さなければならないことを意味します。ただし、従来からある`permit`では、後方互換性のため、`[[:属性名]]`が指定されている場合にハッシュを渡しても許容されますが、新しい`expect`では、`[[:属性名]]`に配列以外のものを渡すとエラーになります。

### Strong Parametersの例

`permit`や`expect`の使い方の例をいくつか紹介します。

**例1**: `new`アクションで許可済み属性を使いたい場合の利用法です（`new`を呼び出した時点ではrootキーが存在しないのが普通なので、そのままではrootキーに対して[`require`][]を呼び出せません）。

```ruby
# この場合は以下のように`fetch`を使うことで、デフォルトを指定しつつ
# Strong Parameters APIを利用できるようになる。
params.fetch(:blog, {}).permit(:title, :author)
```

**例2**: モデルクラスの[`accepts_nested_attributes_for`]メソッドによって、関連付けられているレコードの更新や破棄を行えるようになります。この例は、`id`パラメータと`_destroy`パラメータに基づいています。

```ruby
# `:id`と`:_destroy`が許可される
params.expect(author: [ :name, books_attributes: [[ :title, :id, :_destroy ]] ])
```

**例3**: integerキーを持つハッシュを異なる方法で処理し、属性を直接の子であるかのように宣言できます。`accepts_nested_attributes_for`と`has_many`関連付けを組み合わせると、以下のようなパラメータを得られます。

```ruby
# 以下のようなデータが許可される:
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}
params.expect(book: [ :title, chapters_attributes: [[ :title ]] ])
```

**例4**: 製品名を表す`name`パラメータと、その製品に関連付けられた任意の`data`ハッシュがあり、製品名の`name`属性と、`data`ハッシュ全体（空ハッシュ`{}`で指定）を許可したい場合のシナリオを想定しています。

```ruby
def product_params
  params.expect(product: [ :name, data: {} ])
end
```

[`require`]:
    https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-require

[`accepts_nested_attributes_for`]:
  https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for

cookie
-------

cookieの概念は、Rails固有ではありません。[cookie](https://ja.wikipedia.org/wiki/HTTP_cookie) （HTTP cookieやWeb cookieとも呼ばれます）は、サーバーから送信されてユーザーのブラウザに保存される小さなデータです。

ブラウザ側では、cookieを保存することも、新しいcookieを作成したり、既存のcookieを変更することも、以後のリクエストでサーバーに送り返すことも可能です。Webリクエスト間のデータがcookieとして保存されることで、Webアプリケーションはユーザーの設定を記憶できるようになります。

Railsでは、[`cookies`][]メソッドを使うことで、ハッシュのようにcookieにアクセスできます。

```ruby
class CommentsController < ApplicationController
  def new
    # cookieにコメント作者名が残っていたらフィールドに自動入力する
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(comment_params)
    if @comment.save
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

NOTE: cookieを削除するには、`cookies.delete(:key)`メソッドを使う必要があります。`key`に`nil`値を設定してもcookieは削除されません。

cookieにスカラー値を渡した場合は、ユーザーがブラウザを閉じたときにそのcookieが削除されます。cookieを期限切れにする日時を指定したい場合は、cookieを設定するときに`:expires`オプションを指定したハッシュを渡します。

たとえば、設定するCookieを1時間で失効させるには、次のようにします。

```ruby
cookies[:login] = { value: "XJ-122", expires: 1.hour }
```

有効期限のないCookieを作成したい場合は、以下のようにcookieで`permanent`メソッドを使います。これにより、割り当てられたcookieの有効期限が20年後に設定されます。

```ruby
cookies.permanent[:locale] = "fr"
```

### 暗号化cookieと署名済みcookie

cookieはクライアントのブラウザに保存されるため、クライアントによって改ざんされる可能性があり、機密データを保存するうえで安全とは言えません。Railsでは、機密データの保存用に「署名付きcookie（signed cookie）」と「暗号化cookie（encrypted cookie）」を提供しています。

- 署名付きcookieは、cookie値に暗号署名を追加して整合性を保護します。
- 暗号化cookieは、署名に加えて値の暗号化も行うので、ユーザーは内容を読み取れません。

詳しくは[`Cookies`](https://api.rubyonrails.org/classes/ActionDispatch/Cookies.html) APIドキュメントを参照してください。

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.signed[:user_id] = current_user.id
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2024
    redirect_to action: "read_cookie"
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2024-03-20"
  end
end
```

これらの特殊なcookieは、cookie値をシリアライザで文字列にシリアライズし、読み戻すときにRubyオブジェクトにデシリアライズします。利用するシリアライザは[`config.action_dispatch.cookies_serializer`][]で指定できます。新規アプリケーションのデフォルトのシリアライザは`:json`です。

NOTE: JSONでは、`Date`、`Time`、`Symbol`などのRubyオブジェクトのシリアライズのサポートに制約がある点にご注意ください。これらはすべて`String`にシリアライズ/デシリアライズされます。

これらのオブジェクトや、さらに複雑なオブジェクトをcookieに保存する必要がある場合は、以後のリクエストでcookieを読み取るときに手動で値を変換する必要が生じる場合があります。

cookieセッションストアを使う場合、上記は`session`や`flash`ハッシュにも適用されます。

[`config.action_dispatch.cookies_serializer`]:
    configuring.html#config-action-dispatch-cookies-serializer
[`cookies`]:
    https://api.rubyonrails.org/classes/ActionController/Cookies.html#method-i-cookies

セッション
-------

cookieはクライアント側（ブラウザ）に保存されますが、セッションデータはサーバー側（メモリ、データベース、またはキャッシュ）に保存されます。

セッションデータの有効期間は通常一時的であり（例: ブラウザを閉じるまで）、ユーザーのセッションに関連付けられます。セッションのユースケースの1つは、ユーザー認証などの機密データの保存です。

Railsアプリケーションでは、コントローラとビューでセッションを利用できます。

### セッションにアクセスする

コントローラ内のセッションにアクセスするには`session`インスタンスメソッドを利用できます。セッション値はハッシュに似たキーバリューペアとして保存されます。

```ruby
class ApplicationController < ActionController::Base
  private
    # セッション内の`:current_user_id`キーを探索して現在の`User`を見つけるのに使う。
    # これはRailsアプリケーションでユーザーログインを扱う際の定番の方法
    # ログインするとセッション値が設定され、
    # ログアウトするとセッション値が削除される
    def current_user
      @current_user ||= User.find_by(id: session[:current_user_id]) if session[:current_user_id]
    end
end
```

セッションに何かを保存するには、ハッシュに値を追加するのと同じ要領でキーに代入できます。

以下の例では、ユーザーが認証されると、ユーザーの`id`がセッションに保存されて、以後のリクエストで使われるようになります。

```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      # セッションのuser idを保存し、
      # 以後のリクエストで使えるようにする
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

セッションからデータの一部を削除するには、そのキーバリューペアを削除します。セッションから`current_user_id`キーを削除する方法は、ユーザーをログアウトするときに一般に使われます。

```ruby
class SessionsController < ApplicationController
  def destroy
    session.delete(:current_user_id)
    # 現在のユーザーもクリアする
    @current_user = nil
    redirect_to root_url, status: :see_other
  end
end
```

[`reset_session`][]メソッドを使うと、セッション全体をリセットできます。セッション固定攻撃（session fixation attack）を回避するため、ログイン後には`reset_session`を実行することが推奨されています。詳しくは[セキュリティガイド](security.html#セッション固定攻撃-対応策)を参照してください。

NOTE: セッションは遅延読み込み（lazy load）されるため、アクションのコードでセッションにアクセスしない限り、セッションは読み込まれません。したがって、セッションを常に明示的に無効にする必要はなく、アクセスしないようにすれば十分です。

[`reset_session`]: https://api.rubyonrails.org/classes/ActionController/Metal.html#method-i-reset_session

### flash

[`Flash`][]は、コントローラのアクション同士の間で一時的なデータを渡す方法を提供します。flashに配置したものはすべて、次のアクションで利用可能になり、その後クリアされます。

flashは、ユーザーにメッセージを表示するアクションにリダイレクトする前に、コントローラのアクションでメッセージ（通知やアラートなど）を設定するときによく使われます。

flashにアクセスするには[`flash`][]メソッドを使います。flashはセッションと同様にキーバリューペアとして保存されます。

たとえば、コントローラでユーザーをログアウトするアクションでは、次回のリクエストでコントローラがユーザーに表示できるflashメッセージを以下のように設定できます。

```ruby
class SessionsController < ApplicationController
  def destroy
    session.delete(:current_user_id)
    flash[:notice] = "ログアウトしました"
    redirect_to root_url, status: :see_other
  end
end
```

ユーザーがアプリケーションで何らかの対話的操作を実行した後にメッセージで結果を表示することは、アクションの成功（もしくはエラーの発生）をユーザーにフィードバックする良い方法です。

flashでは、通常の`:notice`（通知）メッセージの他に、`:alert`（アラート）メッセージも表示できます。これらのflashメッセージには、意味を表す色をCSSで設定するのが普通です（例: 通知は緑、アラートはオレンジや赤）。

以下のように`redirect_to`のパラメータにflashメッセージを追加することで、リダイレクト時にflashメッセージを表示することも可能です。

```ruby
redirect_to root_url, notice: "ログアウトしました"
redirect_to root_url, alert: "問題が発生しました"
```

flashメッセージの種別は、`notice`や`alert`だけではありません。`:flash`引数にキーを割り当てることで、flashに任意のキーを設定できます。

たとえば、`:just_signed_up`を割り当てるには以下のようにします。

```ruby
redirect_to root_url, flash: { just_signed_up: true }
```

これでビューで以下の表示用のコードを書けるようになります。

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

上記のログアウトの例では、`destroy`アクションを実行するとアプリケーションの`root_url`にリダイレクトし、そこでflashメッセージを表示できます。ただし、このメッセージが自動的に表示されるわけではありません。直前のアクションでflashに設定した内容がどう扱われるかは、次に実行されるアクションで決定されます。

#### flashメッセージを表示する

直前のアクションでflashメッセージが**設定された**場合は、flashメッセージをユーザーに表示するのがよいでしょう。flashメッセージを表示する以下のようなHTMLをアプリケーションのデフォルトレイアウトに追加しておけば、flashメッセージが常に表示されるようになります。

以下は`app/views/layouts/application.html.erb`にflashメッセージの表示コードを追加する例です。

```erb
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>
    <!-- （他にもコンテンツがあるとする） -->
    <%= yield %>
  </body>
</html>
```

上の`name`は、`notice`や`alert`などのflashメッセージの種別を表します。この情報は通常、flashメッセージをどのようなスタイルでユーザーに表示するかを指定するのに使われます。

TIP: レイアウトファイルで`notice`と`alert`だけを表示するように制限したい場合は、`name`でフィルタリングする方法が使えます。フィルタを行わない場合は、`flash`で設定されたすべてのキーが表示されます。

flashメッセージの読み取りと表示のコードをレイアウトファイルに含めておけば、flashを読み取るロジックを個別のビューに含めなくても、アプリケーション全体で自動的に表示されるようになります。

#### `flash.keep`と`flash.now`

[`flash.keep`][]は、flashの値を以後のリクエストにも引き継ぎたいときに使えます。このメソッドは、リダイレクトが複数回行われる場合に便利です。

たとえば、以下のコントローラの`index`アクションが`root_url`に対応していて、ここでのリクエストをすべて`UsersController#index`にリダイレクトするとします。
アクションがflashを設定してから`MainController#index`にリダイレクトすると、`flash.keep`メソッドで別のリクエスト用の値を保持しておかない限り、別のリダイレクトが発生したときにflashの値は失われます。

```ruby
class MainController < ApplicationController
  def index
    # すべてのflash値を保持する
    flash.keep
    # 以下のようにキーを指定すれば、特定の値だけを保持することも可能
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

[`flash.now`][]は、同じリクエストでflash値を利用可能にするときに使います。
flashに値を追加すると、デフォルトでは（現在のリクエストではなく）次回のリクエストでflashの値を利用可能になります。

たとえば、`create`アクションでリソースの保存に失敗し、`new`テンプレートを直接レンダリングした場合は、新しいリクエストが発生しないため、flashメッセージは表示されません。

しかし、そのような場合でもflashメッセージを表示したいことがあります。これを行うには、通常の`flash`と同じように[`flash.now`][]を使うと、現在のリクエストでflashメッセージが表示されるようになります。

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

[`Flash`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Flash.html
[`flash`]:
    https://api.rubyonrails.org/classes/ActionDispatch/Flash/RequestMethods.html#method-i-flash
[`flash.keep`]:
    https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html#method-i-keep
[`flash.now`]:
    https://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html#method-i-now

### セッションストア

すべてのセッションには、セッションオブジェクトを表す一意のIDが存在し、これらのセッションIDはcookieに保存されます。実際のセッションオブジェクトは、次のいずれかの保存メカニズムを利用します。

* [`ActionDispatch::Session::CookieStore`][]: すべてをクライアント側に保存する
* [`ActionDispatch::Session::CacheStore`][]: データをRailsのキャッシュに保存する
* [`ActionDispatch::Session::ActiveRecordStore`][activerecord-session_store]: Active Recordデータベースに保存する（[`activerecord-session_store`][activerecord-session_store] gemが必要）
* 独自のストアや、サードパーティgemが提供するストア

ほとんどのセッションストアでは、サーバー上のセッションデータ（データベーステーブルなど）を検索するときに、cookie内にある一意のセッションidを使います。セッションIDをURLとして渡す方法は安全性が低いため、Railsでは利用できません。

#### `CookieStore`

[`CookieStore`][]はデフォルトで推奨されるセッションストアで、すべてのセッションデータをcookie自体に保存します（セッションIDも必要に応じて引き続き利用可能です）。`CookieStore`は軽量で、新規Railsアプリケーションでは設定なしで利用できます。

`CookieStore`には4KBのデータを保存できます。他のセッションストアに比べるとずっと小容量ですが、通常はこれで十分です。

利用するセッションストアの種類にかかわらず、セッションに大量のデータを保存することは**推奨されていません**。特に、モデルインスタンスのような複雑なオブジェクトをセッションに保存することは避けてください。

[`CookieStore`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html

#### `CacheStore`

[`CacheStore`][]は、セッションに重要なデータを保存しない場合や、長期間の保存が不要な場合（例: メッセージングにflashだけを使う場合）に利用できます。これにより、アプリケーション用に構成したキャッシュ実装を利用してセッションが保存されるようになります。

`CacheStore`のメリットは、追加のセットアップや管理を必要とせずに、既存のキャッシュインフラストラクチャを利用してセッションを保存できることです。
デメリットは、セッションの保存が一時的なものに限られ、いつでも消えてしまう可能性があることです。

セッションストレージについて詳しくは[セキュリティガイド](security.html#セッション)を参照してください。

[`CacheStore`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Session/CacheStore.html

### セッションストレージの設定オプション

Railsでは、セッションストレージに関連するいくつかの設定オプションを利用できます。
利用するストレージの種類は、イニシャライザで以下のように設定できます。

```ruby
Rails.application.config.session_store :cache_store
```

Railsは、セッションデータに署名するときにセッションキー（cookieの名前）を設定します。この動作もイニシャライザで変更できます。

```ruby
Rails.application.config.session_store :cookie_store, key: "_your_app_session"
```

NOTE: イニシャライザファイルの変更を反映するには、サーバーを再起動する必要があります。

以下のように`:domain`キーを渡して、cookieを使うドメイン名を指定することも可能です。

```ruby
Rails.application.config.session_store :cookie_store, key: "_your_app_session", domain: ".example.com"
```

TIP: 詳しくはRails設定ガイドの[`config.session_store`](configuring.html#config-session-store)を参照してください。

Railsは、`config/credentials.yml.enc`のセッションデータの署名に用いる秘密鍵を`CookieStore`に設定します。この秘密鍵は`bin/rails credentials:edit`コマンドで変更できます。

```yaml
# aws:
#   access_key_id: 123
#   secret_access_key: 345

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 492f...
```

WARNING: `CookieStore`を利用中に`secret_key_base`を変更すると、既存のセッションがすべて無効になります。既存のセッションをローテーションするには、[Cookieローテーター](configuring.html#config-action-dispatch-cookies-rotations)の設定が必要です。

[`ActionDispatch::Session::CookieStore`]:
    https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html
[`ActionDispatch::Session::CacheStore`]:
    https://api.rubyonrails.org/classes/ActionDispatch/Session/CacheStore.html
[activerecord-session_store]:
    https://github.com/rails/activerecord-session_store

コントローラコールバック
-------

NOTE: 訳注: Rails 7.2で従来のフィルタ（filter）という用語がアクションコールバック（action callback）に置き換えられ、その後さらにRails 8でコントローラコールバック（あるいは単にコールバック）に置き換えられました。

**コントローラコールバック（controller callback）**は、コントローラのアクションが実行される「直前（before）」、「直後（after）」、あるいは「直前と直後（around）」に実行されるメソッドです。

コントローラコールバックのメソッドは、特定のコントローラで定義することも`ApplicationController`で定義することも可能です。すべてのコントローラは`ApplicationController`を継承するので、ここで定義されたコールバックはアプリケーション内のすべてのコントローラで実行されます。

### `before_action`

[`before_action`][]に登録したコールバックメソッドは、コントローラのアクションの直前に実行されます。リクエストサイクルを止めてしまう可能性があるのでご注意ください。`before_action`の一般的なユースケースは、ユーザーがログイン済みであることを確認することです。

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

このメソッドはエラーメッセージをflashに保存し、ユーザーがログインしていない場合にはログインフォームにリダイレクトします。

`before_action`コールバックによってビューのレンダリングや前述の例のようなリダイレクトが行われると、コントローラのこのアクションは実行されなくなる点にご注意ください。コールバックの実行後に実行されるようスケジュールされた追加のコントローラコールバックが存在する場合は、これらもキャンセルされ、実行されなくなります。

上の例では、`before_action`を`ApplicationController`で定義しているため、アプリケーション内のすべてのコントローラに継承されます。つまり、アプリケーション内のあらゆるリクエストでユーザーのログインが必須になります。

これは他の部分では問題ありませんが、「ログイン」ページだけは別です。「ログイン」操作はユーザーがログインしていない状態でも成功する必要があり、そうしておかないとユーザーがログインできなくなります。

[`skip_before_action`][]を使えば、特定のコントローラアクションでのみ指定の`before_action`をスキップできます。

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

上のようにすることで、ユーザーがログインしていなくても`LoginsController`の`new`アクションと`create`アクションが成功するようになります。

特定のアクションでのみコールバックをスキップしたい場合には、`:only`オプションでアクションを指定します。逆に特定のアクションのみコールバックをスキップしたくない場合は、`:except`オプションでアクションを指定します。
これらのオプションはコールバックの追加時にも使えるので、最初の場所で選択したアクションに対してだけ実行されるコールバックを追加することも可能です。

NOTE: 同じコールバックを異なるオプションで複数回呼び出すと、最後に呼び出されたアクションコールバックの定義によって、それまでのコールバックの定義は上書きされます。

[`before_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-before_action
[`skip_before_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-skip_before_action

### `after_action`コールバックと`around_action`コールバック

コントローラアクションが実行される「直後」に実行するアクションコールバックは、[`after_action`][]で定義できます。
コントローラアクションが実行される「直前」と「直後」に実行するアクションコールバックは、[`around_action`][]で定義できます。

`after_action`コールバックは`before_action`コールバックに似ていますが、コントローラアクションがすでに実行済みのため、クライアントに送信されるレスポンスデータにアクセスできる点が異なります。

NOTE: `after_action`コールバックは、アクションが成功した場合にのみ実行されます。リクエストサイクルの途中で例外が発生した場合は実行されません。

`around_action`コールバックは、コントローラアクションの直前と直後にコードを実行する場合に便利で、アクションの実行に影響する機能をカプセル化できます。これらは、関連するアクションを`yield`で実行させる役割を担います。

たとえば特定のアクションのパフォーマンスを監視したいとします。以下のように`around_action`を使うことで、各アクションが完了するまでにかかる時間を測定した情報をログに出力できます。

```ruby
class ApplicationController < ActionController::Base
  around_action :measure_execution_time

  private
    def measure_execution_time
      start_time = Time.now
      yield  # ここでアクションが実行される
      end_time = Time.now

      duration = end_time - start_time
      Rails.logger.info "Action #{action_name} from controller #{controller_name} took #{duration.round(2)} seconds to execute."
    end
end
```

TIP: アクションコールバックには、上の例に示したように`controller_name`と `action_name`が利用可能なパラメータとして渡されます。

`around_action`コールバックはレンダリングもラップします。上の例では、ビューのレンダリングは`duration`の値に含まれます。

`around_action`の`yield`以降のコードは、関連付けられたアクションで例外が発生すれば、コールバックに`ensure`ブロックが存在する場合でも実行されます（この振る舞いは、アクションで例外が発生すると`after_action`コードがキャンセルされる`after_action`コールバックとは異なります）。

[`after_action`]:
  https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-after_action
[`around_action`]:
  https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-around_action

### コールバックのその他の利用法

`before_action`、`after_action`、`around_action`の他にも、あまり一般的ではないコールバック登録方法が2つあります。

1つ目の方法は、`*_action`メソッドに直接ブロックを渡すことです。このブロックはコントローラを引数として受け取ります。

たとえば、前述の`require_login`アクションコールバックを書き換えてブロックを使うようにすると、以下のようになります。

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

このとき、コールバック内で`send`メソッドを使っていることにご注意ください。
その理由は、`logged_in?`はprivateメソッドであり、そのままではコールバックがコントローラのスコープで実行されないためです（訳注: `send`メソッドを使うとprivateメソッドを呼び出せます）。
この方法は、特定のコールバックを実装する方法としては推奨されませんが、もっとシンプルな場合には役に立つことがあるかもしれません。

特に`around_action`の場合、以下のコードの`time(&action)`はコントローラアクションをブロックとして`time`メソッドに渡します。

```ruby
around_action { |_controller, action| time(&action) }
```

2つ目の方法は、コールバックアクションにクラス（または期待されるメソッドに応答する任意のオブジェクト）を指定することです。
これは、より複雑なコールバックコードをシンプルに書くときに便利です。

たとえば、`around_action`コールバックを以下のように書き換えることで、渡したクラスを使って実行時間を測定できます。

```ruby
class ApplicationController < ActionController::Base
  around_action ActionDurationCallback
end

class ActionDurationCallback
  def self.around(controller)
    start_time = Time.now
    yield # ここでアクションが実行される
    end_time = Time.now

    duration = end_time - start_time
    Rails.logger.info "Action #{controller.action_name} from controller #{controller.controller_name} took #{duration.round(2)} seconds to execute."
  end
end
```

上の例では、`ActionDurationCallback`クラスのメソッドはコントローラのスコープ内で実行されませんが、`controller`を引数として受け取る点にご注目ください。

一般に、`*_action`コールバックに渡すクラスは、そのコールバックと同じ名前のメソッドを実装する必要があります。つまり、たとえば`before_action`コールバックに渡すクラスは`before`メソッドを実装する必要があります。

また、`around`メソッドには、アクションを実行するための`yield`が必要です。

`request`オブジェクトと`response`オブジェクト
--------------------------------

すべてのコントローラには[`request`][]メソッドと[`response`][]メソッドが必ず存在しているので、これらを使って現在のリクエストサイクルに関連付けられたリクエストオブジェクトとレスポンスオブジェクトにアクセスできます。

- [`request`][]メソッドは、[`ActionDispatch::Request`][] のインスタンスを返します。
- [`response`][]メソッドは、[`ActionDispatch::Response`][]のインスタンスを返します。
  これは、クライアント（ブラウザ）に返す内容を表すオブジェクトです（コントローラアクションの`render`や`redirect`など）。

[`ActionDispatch::Request`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Request.html
[`request`]:
  https://api.rubyonrails.org/classes/ActionController/Base.html#method-i-request
[`response`]:
  https://api.rubyonrails.org/classes/ActionController/Base.html#method-i-response
[`ActionDispatch::Response`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Response.html

### `request`オブジェクト

[`response`][]オブジェクトには、クライアントから受信したリクエストに関する有用な情報が多数含まれています。本セクションでは、`request`オブジェクトの一部のプロパティの目的について説明します。

リクエストオブジェクトで利用可能なメソッドの完全なリストについては、Rails APIドキュメントの[`ActionDispatch::Request`][]や[Rack][Rack-Request] gemのドキュメントを参照してください。

| `request`のプロパティ                                 | 目的                                                                     |
| ----------------------------------------------------- | ------------------------------------------------------------------------ |
| `host`                                                | リクエストで使われるホスト名                                             |
| `domain(n=2)`                                         | ホスト名の右（TLD:トップレベルドメイン）から数えて`n`番目のセグメント    |
| `format`                                              | クライアントからリクエストされた`Content-Type`ヘッダー                   |
| `method`                                              | リクエストで使われるHTTPメソッド                                         |
| `get?`、`post?`、`patch?`、`put?`、`delete?`、`head?` | HTTPメソッドがGET/POST/PATCH/PUT/DELETE/HEADのいずれかの場合にtrueを返す |
| `headers`                                             | リクエストに関連付けられたヘッダーを含むハッシュを返す                   |
| `port`                                                | リクエストで使われるポート番号（整数）                                   |
| `protocol`                                            | プロトコル名に"://"を加えたものを返す（"http://"など）                   |
| `query_string`                                        | URLの一部で使われるクエリ文字（"?"より後の部分）                         |
| `remote_ip`                                           | クライアントのIPアドレス                                                 |
| `url`                                                 | リクエストで使われるURL全体                                              |

[Rack-Request]:
  https://www.rubydoc.info/gems/rack/Rack/Request

#### `query_parameters`、`request_parameters`、`path_parameters`

Railsの`params`には、クエリ文字列パラメータとしてURLに設定されたデータや、`POST`リクエストのbodyとして送信されたデータなど、特定のリクエストに関するすべてのパラメータが集まっています。

[`request`][]オブジェクトでは、さまざまなパラメータにアクセスできる以下の3つのメソッドを利用できます。

* [`query_parameters`][]: クエリ文字列の一部として送信されたパラメータが含まれます。
* [`request_parameters`][]: `POST`のbodyの一部として送信されたパラメータが含まれます。
* [`path_parameters`][]: ルーターによって特定のコントローラとアクションへのパスの一部であると解析されたパラメータが含まれます。

[`path_parameters`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Http/Parameters.html#method-i-path_parameters
[`query_parameters`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-query_parameters
[`request_parameters`]:
  https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-request_parameters


#### `request.variant`

コントローラのレスポンスを、リクエスト内のコンテキスト固有の情報に基づいてカスタマイズする必要が生じる場合があります。たとえば、モバイルプラットフォームからのリクエストに応答するコントローラは、デスクトップブラウザからのリクエストとは異なるコンテンツをレンダリングする必要がある場合があります。

これを実現する方法のひとつは、リクエストのバリアントをカスタマイズすることです。バリアント名は任意で、リクエストのプラットフォーム（`:android`、`:ios`、`:linux`、`:macos`、`:windows`）からブラウザ（`:chrome`、`:edge`、`:firefox`、`:safari`）、ユーザー種別（`:admin`、`:guest`、`:user`）まで、あらゆる情報を伝えられます。

以下のように、[`request.variant`][]を`before_action`で設定できます。

```ruby
request.variant = :tablet if request.user_agent.include?("iPad")
```

コントローラアクション内でバリアントを使って応答するには、以下のように`format`を利用できます。

```ruby
# app/controllers/projects_controller.rb

def show
  # ...
  respond_to do |format|
    format.html do |html|
      html.tablet                        # app/views/projects/show.html+tablet.erbをレンダリング
      html.phone { extra_setup; render } # app/views/projects/show.html+phone.erbをレンダリング
    end
  end
end
```

フォーマットやバリアントに応じて、以下のように個別にビューテンプレートを作成しておく必要があります。

* `app/views/projects/show.html.erb`
* `app/views/projects/show.html+tablet.erb`
* `app/views/projects/show.html+phone.erb`

以下のようなインライン構文でバリアントをシンプルに定義することも可能です。

```ruby
respond_to do |format|
  format.html.tablet
  format.html.phone  { extra_setup; render }
end
```

[`request.variant`]: https://api.rubyonrails.org/classes/ActionDispatch/Http/MimeNegotiation.html#method-i-variant-3D

### `response`オブジェクト

[`response`][]オブジェクトは、アクションの実行中に、クライアント（ブラウザ）に送り返すデータをレンダリングすることでビルドされます。

通常は`response`オブジェクトを直接使うことはありませんが、`after_action`コールバックなどでは、レスポンスに直接アクセスすると便利な場合があります。

`response`オブジェクトのユースケースの1つは、[`Content-Type`][]ヘッダーを設定することです。

```ruby
response.content_type = "application/pdf"
```

`response`オブジェクトの別のユースケースとして、カスタムヘッダーを設定するのにも使われます。

```ruby
response.headers["X-Custom-Header"] = "some value"
```

`headers`属性は、ヘッダー名をヘッダー値に対応付けるハッシュです。Railsは、一部のヘッダーについては自動的に設定しますが、ヘッダーの更新やカスタムヘッダーの追加が必要な場合は、上の例のように`response.headers`を利用できます。

NOTE: `headers`メソッドには、コントローラから直接アクセスすることも可能です。

`response`オブジェクトに含まれるプロパティの一部を以下に示します。

| `response`のプロパティ | 目的                                                               |
| ---------------------- | ------------------------------------------------------------------ |
| `body`                 | クライアントに送り返されるデータの文字列（HTMLで最もよく使われる） |
| `status`               | レスポンスのステータスコード（200 OK、404 file not foundなど）     |
| `location`             | リダイレクト先URL（存在する場合）                                  |
| `content_type`         | レスポンスのContent-Typeヘッダー                                   |
| `charset`              | レスポンスで使われる文字セット（デフォルトは"utf-8"）              |
| `headers`              | レスポンスで使われるヘッダー                                       |

リクエストオブジェクトで利用可能なメソッドの完全なリストについては、Rails APIドキュメントの[`ActionDispatch::Response`][]や[Rack][Rack-Response] gemのドキュメントを参照してください。

[Rack-Response]:
  https://www.rubydoc.info/gems/rack/Rack/Response
