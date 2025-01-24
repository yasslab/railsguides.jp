Action Controller の高度なトピック
=================================

本ガイドでは、コントローラに関連するいくつかの高度なトピックについて学習します。
このガイドの内容:

* クロスサイトリクエストフォージェリ（CSRF）に対する保護
* Action Controller組み込みのHTTP認証機能の使い方
* データをユーザーのブラウザに直接ストリーミングする方法
* アプリケーションログに含まれる機密情報をフィルタで除外する方法
* リクエストの処理中に発生する可能性のある例外を処理する方法
* 組み込みのヘルスチェック用エンドポイントをロードバランサーや稼働時間モニターで利用する方法

--------------------------------------------------------------------------------

はじめに
------------

本ガイドでは、Railsアプリケーションのコントローラに関連する高度なトピックをいくつか取り上げます。Action Controllerの概要については、[Action Controller の概要](action_controller_overview.html)ガイドを参照してください。

認証トークンとリクエスト偽造防止
-------------------------------------------------

クロスサイトリクエストフォージェリ（[CSRF][]）は、Webアプリケーションが信頼しているユーザーになりすまして不正な偽造リクエストを送信する形で行われる、悪意のある攻撃の一種です。

この種の攻撃を回避するために開発者が最初に行うべきステップは、アプリケーション内の「破壊的な」操作（作成、更新、破棄）では常に**`GET`以外のリクエスト**（`POST`、`PUT`、`DELETE`など）を使うようにすること、つまり`GET`リクエストで破壊的操作が絶対に行われないようにすることです。

ただし、悪意のあるサイトが`GET`以外のリクエストを標的サイトに送信する可能性もあるため、Railsではリクエストフォージェリ（リクエストの偽造）からの保護機能がデフォルトでコントローラに組み込まれています。

この保護は、[`protect_from_forgery`][]メソッドでトークンを追加することで行われます。このトークンはサーバーのみが認識しており、リクエストのたびに異なるトークンが追加されます。Railsは、受信したトークンをセッション内のトークンで検証します。受信リクエスト内で適切なトークンと一致しない場合、サーバーはアクセスを拒否します。

[`config.action_controller.default_protect_from_forgery`][]が`true`に設定されている場合、CSRFトークンは自動的に追加されます（新規作成Railsアプリケーションのデフォルト設定）。以下のように手動でも設定できます。

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
```

NOTE: `ActionController::Base`のすべてのサブクラスはデフォルトで保護されており、検証されていないリクエストでは`ActionController::InvalidAuthenticityToken`エラーが発生します。

[CSRF]:
  https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html#method-i-form_authenticity_token
[`protect_from_forgery`]:
  https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html#method-i-protect_from_forgery

[`config.action_controller.default_protect_from_forgery`]:
  configuring.html#config-action-controller-default-protect-from-forgery

### フォームの認証トークン

`form_with`で以下のようにフォームを生成すると、

```erb
<%= form_with model: @user do |form| %>
  <%= form.text_field :username %>
  <%= form.text_field :password %>
<% end %>
```

生成されるHTMLのhiddenフィールドに、`authenticity_token`という名前を持つCSRFトークンが自動的に追加されます。

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- fields -->
</form>
```

Railsは、[フォームヘルパー](form_helpers.html)によって生成されるすべての`form`要素にこのトークンを追加するため、ほとんどの場合、開発者は何もする必要はありません。フォームを手動で作成する場合や、別の理由でトークンを追加する必要がある場合は、以下のように[`form_authenticity_token`][]メソッドでトークンを利用できるようになります。

```html
<!-- app/views/layouts/application.html.erb -->
<head>
  <meta name="csrf-token" content="<%= form_authenticity_token %>">
</head>
```

`form_authenticity_token`メソッドは、有効な認証トークンを生成します。これは、カスタムAjax呼び出しなど、Railsが認証トークンを自動的に追加しない場所で有用です。

CSRF攻撃やCSRF対策について詳しくは、[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ（csrf）)を参照してください。

[`form_authenticity_token`]:
  https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html#method-i-form_authenticity_token

ユーザーが利用してよいブラウザバージョンを制御する
------------------------------------

Rails 8.0からは、`ApplicationController`で[`allow_browser`][]メソッドを使うことで、デフォルトでは「モダンな」ブラウザの利用のみをユーザーに許可し、古いブラウザではアクセスできなくなります。

```ruby
class ApplicationController < ActionController::Base
  # 以下を指定すると、webp画像、web push、バッジ、importmap、CSSネスト、CSS :hasをサポートするモダンブラウザのみが許可される。
  allow_browser versions: :modern
end
```

TIP: `:modern`を指定した場合に許可されるブラウザには、Safari 17.2以上、Chrome 120以上、Firefox 121以上、Opera 106以上が含まれます。使いたい機能がどのバージョンのブラウザでサポートされているかを確認するには、[caniuse.com](https://caniuse.com/)を利用できます。

デフォルトの`:modern`以外に、許可したいブラウザバージョンを以下のように手動で指定することも可能です。

```ruby
class ApplicationController < ActionController::Base
  # ChromeとOperaについては全バージョンを許可するが、"internet explorer"（ie）はどのバージョンも許可しない。
  # Safariは16.4以上、Firefoxは121以上を許可する。
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false }
end
```

`versions:`オプションにハッシュを渡した場合、ハッシュに一致するブラウザが指定のバージョンより古い場合はブロックされます。つまり、`versions:`に明示的に記載していない他のすべてのブラウザ（上の例ではChromeとOpera）や、[`User-Agent`][]ヘッダーを通知しないエージェントは、アクセスが「**許可される**」点にご注意ください。

また、以下のように特定のコントローラで`allow_browser`メソッドを書いて、`only`オプションや`except`オプションで特定のアクションのみを許可または拒否することも可能です。

```ruby
class MessagesController < ApplicationController
  # ApplicationControllerでブロックされるブラウザの他に、
  # showアクションについてはOpera 104未満、Chrome 119未満もブロックする。
  allow_browser versions: { opera: 104, chrome: 119 }, only: :show
end
```

ブロックされたブラウザには、デフォルトでHTTPステータスコード[406 Not Acceptable][]で`public/406-unsupported-browser.html`のエラー表示用ファイルが配信されます。

[`allow_browser`]:
  https://api.rubyonrails.org/classes/ActionController/AllowBrowser/ClassMethods.html#method-i-allow_browser
[`User-Agent`]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/User-Agent
[406 Not Acceptable]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Status/406

HTTP認証
--------------------

Railsには3種類のHTTP認証機構が組み込まれています。

* BASIC認証
* ダイジェスト認証
* トークン認証

### HTTP BASIC認証

HTTP BASIC認証（基本認証）は、ユーザーがWebサイト（または管理者セクションなど、Webサイトの特定のセクション）にアクセスするためにユーザー名とパスワードの入力を要求するシンプルな認証方法です。これらの認証情報（credential）をブラウザのHTTP BASIC認証用ダイアログウィンドウに入力すると、ユーザーの認証情報はエンコードされて、以後のリクエストのたびにHTTPヘッダー経由で送信されます。

HTTP BASIC認証は認証スキームの一種であり、主要なブラウザおよびHTTPクライアントでサポートされています。RailsコントローラでHTTP BASIC認証を使うには、[`http_basic_authenticate_with`][]メソッドを利用します。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "Arthur", password: "42424242"
end
```

上のコードを実行すると、`AdminsController`から継承したコントローラを作成できます。これらのコントローラのすべてのアクションは、HTTP BASIC認証によるユーザー認証情報の入力が必須となります。

WARNING: HTTP BASIC認証は手軽に実装できますが、ネットワーク経由で送信されるcredentialは暗号化されないため、BASIC認証自体は安全ではありません。BASIC認証を使う場合は、必ずHTTPSプロトコルも併用してください。[HTTPSプロトコルを強制する](#httpsプロトコルを強制する)設定も利用できます。

[`http_basic_authenticate_with`]:
    https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods/ClassMethods.html#method-i-http_basic_authenticate_with

### HTTPダイジェスト認証

HTTPダイジェスト認証は、暗号化されていないパスワードをクライアントからネットワーク経由で送信する必要がないため、BASIC認証より安全性が高まります。認証情報はハッシュ化されて、[ダイジェスト][`Digest`]が送信されます。

Railsでダイジェスト認証を利用するには、[`authenticate_or_request_with_http_digest`][]メソッドを使います。

```ruby
class AdminsController < ApplicationController
  USERS = { "admin" => "helloworld" }

  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

上の例で示したように、`authenticate_or_request_with_http_digest`のブロックでは引数を1つ（ユーザー名）だけ受け取ります。ブロックは、パスワードが見つかった場合はパスワードを返します。`nil`または`false`が返される場合は、認証が失敗したとみなされます。

[`Digest`]:
  https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Digest.html
[`authenticate_or_request_with_http_digest`]:
    https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Digest/ControllerMethods.html#method-i-authenticate_or_request_with_http_digest

### HTTPトークン認証

トークン認証は「ベアラー（Bearer）認証」とも呼ばれ、クライアントがログインに成功した後に一意の[Bearerトークン](https://ja.wikipedia.org/wiki/Bearer%E3%83%88%E3%83%BC%E3%82%AF%E3%83%B3)を受け取り、それを以後のリクエストで`Authorization`ヘッダーに含める認証方法です。
クライアントは、リクエストのたびに認証情報を送信する代わりに、この[トークン](https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html)（ユーザーのセッションを表す文字列）を認証の「ベアラー」として送信します。

このアプローチでは、進行中のセッションから資格情報を分離することでセキュリティが向上します。事前に発行された認証トークンを使用して認証を実行します。

Railsでトークン認証を実装するには、[`authenticate_or_request_with_http_token`][]メソッドを使います。

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

上の例のように、`authenticate_or_request_with_http_token`のブロックでは、「トークン」と「HTTP `Authorization`ヘッダーを解析したオプションを含む`Hash`」という2個の引数を受け取ります。このブロックは、認証が成功した場合は`true`を返します。`false`か`nil`を返した場合は認証失敗です。

[`authenticate_or_request_with_http_token`]:
    https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_or_request_with_http_token

ストリーミングとファイルダウンロード
----------------------------

Railsコントローラは、HTMLページをレンダリングする代わりに、ユーザーにファイルを送信する方法を提供します。これは、クライアントにデータをストリーミングする[`send_data`][]メソッドと[`send_file`][]メソッドで実行できます。

[`send_data`][]メソッドは、ファイル名を指定してそのファイルの内容をストリーミングできる便利なメソッドです。

`send_data`メソッドの利用方法を以下に示します。

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

ストリーミング送信するファイルをクライアント側でファイルとしてダウンロードできないようにしたい場合があります。たとえば、HTMLページに埋め込める画像ファイルで考えてみましょう。このとき、このファイルはダウンロード用ではないということをブラウザに伝えるには、`:disposition`オプションで"inline"を指定します。
逆のオプションは"attachment"で、こちらはストリーミングのデフォルト設定です。

[`send_data`]:
    https://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_data
[`send_file`]:
    https://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file

### ファイルを送信する

サーバーのディスク上に既にあるファイルを送信するには、[`send_file`][]メソッドを使います。

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

ファイルは、デフォルトでは4KBずつ読み出されてストリーミング送信されます。これは、巨大なファイルを一度にメモリに読み込まないようにするためです。分割読み出しは`:stream`オプションでオフにすることも、`:buffer_size`オプションでブロックサイズを調整することも可能です。

`:type`オプションが未指定の場合、`:filename`で取得したファイル名の拡張子から推測して設定されます。拡張子に該当する[`Content-Type`][]ヘッダーがRailsに登録されていない場合、`application/octet-stream`が使われます。

WARNING: サーバーのディスク上のファイルパスを指定するときに、（paramsやcookieなどの）ユーザーがクライアントで入力したデータを使う場合は十分な注意が必要です。クライアントから悪質なファイルパスが入力されると、開発者が意図しないファイルにアクセスされてしまうというセキュリティ上のリスクが生じる可能性を常に念頭に置いてください。

TIP: 静的なファイルをRailsからストリーミング送信することは推奨されていません。ほとんどの場合、Webサーバーのpublicフォルダに置いてダウンロードさせれば済むはずです。Railsからストリーミングでダウンロードするよりも、ApacheなどのWebサーバーから直接ファイルをダウンロードする方がはるかに効率が高く、しかもRailsスタック全体を経由する不必要なリクエストを受信せずに済みます。

[`Content-Type`]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Content-Type

### RESTfulなダウンロード

`send_data`は問題なく利用できますが、真にRESTfulなアプリケーションを作成しているときに、ファイルダウンロード専用のアクションを別途作成する必要は通常ありません。RESTという用語においては、上の例で使われているPDFファイルのようなものは、クライアントリソースを別の形で表現したものであると見なされます。

Railsには、これに基づいた「RESTful」ダウンロードを手軽に実現するための洗練された方法も用意されています。以下は上の例を変更して、PDFダウンロードをストリーミングとして扱わずに`show`アクションの一部として扱うようにしたものです。

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

これで、ユーザーは以下のようにURLの末尾に`.pdf`を追加するだけで、クライアントのPDFバージョンを取得するリクエストを送信できます。

```
GET /clients/1.pdf
```

この`format`では、RailsによってMIMEタイプとして登録されている拡張機能の任意のメソッドを呼び出せます。
Railsには既に`"text/html"`や`"application/pdf"`などの一般的なMIMEタイプが登録されています。

```ruby
Mime::Type.lookup_by_extension(:pdf)
# => "application/pdf"
```

MIMEタイプを追加する必要がある場合は、`config/initializers/mime_types.rb`ファイルで[`Mime::Type.register`][]を呼び出します。たとえば、リッチテキスト形式（RTF）は以下の方法で登録できます。

```ruby
Mime::Type.register("application/rtf", :rtf)
```

NOTE: Railsの設定ファイルは起動時にしか読み込まれません。上の設定変更を反映するには、サーバーを再起動する必要があります。

[`Mime::Type.register`]:
  https://api.rubyonrails.org/classes/Mime/Type.html#method-c-register

### 任意のデータをライブストリーミングする

Railsは、ファイル以外のデータもストリーミング送信できます。実は`response`オブジェクトに含まれるものなら何でもストリーミング送信できます。

[`ActionController::Live`][]モジュールを使うと、ブラウザとの永続的なコネクションを作成できます。このモジュールを`include`することで、いつでも好きなタイミングで任意のデータをブラウザに送信できるようになります。

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers["Content-Type"] = "text/event-stream"
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

上のコードは、ブラウザとの間に永続的なコネクションを確立し、1秒おきに`"hello world\n"`メッセージを100個ずつ送信します。

上の例にはいくつか注意点があります。

- レスポンスのストリームは確実に閉じること。
  ストリームを閉じ忘れると、ソケットが開きっぱなしになってしまいます。

- `Content-Type`ヘッダーに`text/event-stream`を設定するときは、レスポンスストリームへの書き込みの「**前に**」行うこと。
  （`response.committed?`が「truthy」な値を返したときに）レスポンスがコミット済みになっていると、以後ヘッダーに書き込みできなくなります。これは、レスポンスストリームに対して`write`または`commit`を行った場合に発生します。

[`ActionController::Live`]:
  https://api.rubyonrails.org/classes/ActionController/Live.html

#### 利用例

カラオケマシンを開発していて、ユーザーが特定の曲の歌詞を表示できるようにしたいとします。`Song`ごとに特定の行数の歌詞データがあり、各行には「その行を歌い終わるまであと何拍残っているか」を表す`num_beats`が記入されているとします。

歌詞を「カラオケスタイル」でユーザーに表示したいので、直前の歌詞を歌い終わってから次の歌詞を表示することになります。このようなときは、以下のように`ActionController::Live`を利用できます。

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

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

#### ストリーミングで考慮すべき点

任意のデータをストリーミング送信できる機能は、きわめて強力なツールとなります。これまでの例でご紹介したように、任意のデータをいつでもレスポンスストリームで送信できます。ただし、以下の点についてご注意ください。

* レスポンスストリームを作成するたびに新しいスレッドが作成され、元のスレッドからスレッドローカルな変数がコピーされます。スレッドローカルな変数が増えすぎたり、スレッド数が増えすぎると、パフォーマンスに悪影響が生じます。

* レスポンスストリームを閉じることに失敗すると、該当のソケットが開きっぱなしになってしまいます。レスポンスストリームを使う場合は、`close`を確実に呼び出してください。

* WEBrickサーバーはすべてのレスポンスをバッファリングするので、`ActionController::Live`ではストリーミングできません。このため、レスポンスを自動的にバッファリングしないWebサーバーを使う必要があります。

ログをフィルタする
-------------

Railsのログファイルは、環境ごとに`log`フォルダの下に保存されます。ログは、デバッグ時にアプリケーションで何が起こっているかを確認するときには非常に便利ですが、production環境のアプリケーションでは顧客のパスワードのような重要な情報をログファイルに出力しないようにしておきたいのが普通でしょう。

Railsでは、ログに保存してはいけないパラメータを指定できます。

### パラメータをフィルタする

Railsアプリケーションの設定ファイル[`config.filter_parameters`][]には、特定のリクエストパラメータをログ出力時にフィルタで除外する設定を追加できます。
フィルタされたパラメータはログ内で`[FILTERED]`という文字に置き換えられます。

```ruby
config.filter_parameters << :password
```

ここで指定したパラメータは、ログで`[FILTERED]`と出力されます。

`filter_parameters`で指定したパラメータは、正規表現の「部分マッチ」によるフィルタで除外される点にご注意ください。たとえば、`:passw`を指定すると、`password`、`password_confirmation`などもフィルタで除外されます。

Railsでは、`:passw`、`:secret`、`:token`などのデフォルトのフィルタリストが適切なイニシャライザ（`initializers/filter_parameter_logging.rb`）に追加されているので、`password`、`password_confirmation`、`my_token`などの一般的なアプリケーションパラメータはデフォルトで除外されるようになっています。

[`config.filter_parameters`]:
  configuring.html#config-filter-parameters

### リダイレクト結果をフィルタする

機密性の高いURLにリダイレクトした結果をアプリケーションのログに残したくない場合があります。
設定の[`config.filter_redirect`][]オプションを使って、リダイレクト先URLをログに出力しないようにできます。

```ruby
config.filter_redirect << "s3.amazonaws.com"
```

フィルタしたいリダイレクト先は、文字列か正規表現、またはそれらを含む配列で指定できます。

```ruby
config.filter_redirect.concat ["s3.amazonaws.com", /private_path/]
```

マッチしたURLはログで`[FILTERED]`という文字に置き換えられます。ただし、URL全体ではなくパラメータのみをフィルタで除外したい場合は、[パラメータをフィルタする](#パラメータをフィルタする)を参照してください。

[`config.filter_redirect`]:
  configuring.html#config-filter-redirect

HTTPSプロトコルを強制する
--------------------

コントローラへの通信をHTTPSのみに限定するには、アプリケーション環境の[`config.force_ssl`][]設定で[`ActionDispatch::SSL`][]ミドルウェアを有効にします。

[`config.force_ssl`]:
  configuring.html#config-force-ssl
[`ActionDispatch::SSL`]:
    https://api.rubyonrails.org/classes/ActionDispatch/SSL.html

組み込みのヘルスチェックエンドポイント
------------------------------

Railsには、`/up`パスでアクセス可能な組み込みのヘルスチェックエンドポイントも用意されています。このエンドポイントは、アプリが正常に起動した場合はステータスコード200を返し、例外が発生した場合はステータスコード[500 Server Error][]を返します。

production環境では、多くのアプリケーションが、問題が発生したときにエンジニアに報告するアップタイムモニタや、ポッドの健全性を判断するロードバランサや、Kubernetesコントローラなどを用いて、状態を上流側に報告する必要があります。このヘルスチェック機能は、そうした多くの状況で利用できるように設計されています。

新しく生成されたRailsアプリケーションのヘルスチェックはデフォルトで`/up`に配置されますが、`config/routes.rb`でパスを自由に設定できます。

```ruby
Rails.application.routes.draw do
  get "health" => "rails/health#show", as: :rails_health_check
end
```

上の設定によって、`GET`リクエストまたは`HEAD`リクエストで`/health`パスのヘルスチェックにアクセスできるようになります。

NOTE: このエンドポイントは、データベースやredisクラスタなど、アプリケーションのあらゆる依存関係のステータスを反映しているわけではありません。アプリケーション固有のニーズについては、`rails/health#show`を独自のコントローラアクションに置き換えてください。

ヘルスチェックでどんな項目をチェックするかの決定は、慎重に検討しましょう。場合によっては、サードパーティのサービスが不具合で停止したためにアプリケーションが不必要に再起動するような事態を招く可能性もあります。理想的には、そのような停止を適切に処理できるようにアプリケーションを設計する必要があります。

エラー処理
----------------

どんなアプリケーションでも、バグが潜んでる可能性や、適切に扱う必要のある例外をスローする可能性があるものです。たとえば、データベースに既に存在しなくなったリソースにユーザーがアクセスすると、Active Recordは`ActiveRecord::RecordNotFound`例外をスローします。

Railsのデフォルトの例外ハンドリングでは、例外の種類にかかわらず「[500 Server Error][]」を表示します。development環境でのリクエストであれば、詳細なトレースバックや追加情報も表示されるので、これらを元に問題点を把握して対応できます。production環境でのリクエストの場合は「[500 Server Error][]」や「[404 Not Found][]」などのメッセージだけをユーザーに表示します。

これらのようなエラーキャッチ方法や、ユーザーへのエラー表示方法は設定でカスタマイズ可能です。Railsアプリケーションでは、さまざまなレベルの例外処理を利用できます。`config.action_dispatch.show_exceptions`設定を使えば、リクエストへの応答中に発生した例外をRailsが処理する方法を制御できます。

例外のレベルについて詳しくは、[Railsアプリケーションの設定項目](configuring.html#config-action-dispatch-show-exceptions)ガイドを参照してください。

[500 Server Error]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Status/500
[404 Not Found]:
  https://developer.mozilla.org/ja/docs/Web/HTTP/Status/404

### デフォルトのエラーテンプレート

production環境のRailsアプリケーションは、デフォルトではエラー時にエラーページを表示します。
これらのエラーメッセージには、`public/`フォルダ以下に置かれている静的なHTMLファイル（`404.html`および`500.html`）が使われるので、これらのファイルをカスタマイズすることで情報やスタイルをエラーページに追加できます。

NOTE: これらのエラーページは静的なHTMLファイルなので、ERBやSCSSや[レイアウト](layouts_and_rendering.html#レイアウトを構成する)のような動的な機能は利用できません。

### `rescue_from`

もう少し洗練された方法でエラーをキャッチしたい場合は、[`rescue_from`][]を使えます。これにより、1つ以上の例外を1つのコントローラ全体で扱うことも、そのサブクラスで扱うことも可能になります。

`rescue_from`ディレクティブでキャッチ可能な例外が発生すると、ハンドラに例外オブジェクトが渡されます。

`rescue_from`を使ってすべての`ActiveRecord::RecordNotFound`エラーをインターセプトし、処理を行なう方法の例を以下に示します。

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private
    def record_not_found
      render plain: "Record Not Found", status: 404
    end
end
```

このハンドラには、メソッドを渡すことも、`:with`オプションで`Proc`オブジェクトを渡すことも可能です。`Proc`オブジェクトを明示的な渡す代わりに、ブロックを直接渡すことも可能です。

これで先ほどよりもコードが洗練されましたが、もちろんこれだけではエラー処理は何も改良されていません。しかしこのようにすべての例外をキャッチ可能にしておくことで、今後自由にカスタマイズできるようになります。

たとえば、以下のようなカスタム例外クラスを作成すると、アクセス権を持たないユーザーがアプリケーションの特定部分にアクセスした場合に例外をスローできます。

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

WARNING: `rescue_from`で`Exception`や`StandardError`を指定すると、Railsの正常な例外ハンドリングが阻害されて深刻な副作用が生じる可能性があります。よほどの理由がない限り、このような指定はおすすめできません。

NOTE: `ActiveRecord::RecordNotFound`エラーは、production環境では常に404エラーページを表示します。この振る舞いをカスタマイズする必要がない限り、開発者がこのエラーを処理する必要はありません。

[`rescue_from`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from
