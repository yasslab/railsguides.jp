Action Mailer の基礎
====================

本ガイドは、Railsアプリケーションからメールを送信する方法について解説します。

このガイドの内容:

* Action Mailerクラスとメーラービューの生成および編集方法
* Railsアプリケーションで添付ファイルやマルチパートメールを送信する方法
* Action Mailerコールバックの利用方法
* 環境に合わせてAction Mailerを設定する方法
* メールのプレビュー方法と、Action Mailerクラスのテスト方法

--------------------------------------------------------------------------------

Action Mailerについて
------------

Action Mailerを使うと、アプリケーションからメールを送信できるようになります。Action Mailerは、Railsフレームワークにおけるメール関連コンポーネントの1つであり、メール受信を処理する[Action Mailbox](action_mailbox_basics.html)と対になります。

Action Mailerでは、「メーラー（mailer）」と呼ばれるクラスと、メールの作成や送信設定用のビューが使われます。メーラーは、[`ActionMailer::Base`][]クラスを継承します。

メーラーの振る舞いは、以下の点がコントローラときわめて似通っています。

* ビューでアクセス可能なインスタンス変数がある
* レイアウトやパーシャルを利用可能にする機能
* paramsハッシュにアクセス可能にする機能
* アクションと、関連するビュー（`app/views`ディレクトリ以下に配置される）がある

[`ActionMailer::Base`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html

メーラーとビューを作成する
--------------

このセクションでは、Action Mailerによるメール送信方法を手順を追って説明します。詳しい手順は以下の通りです。

### メーラーを生成する

最初に、以下の「メーラー」ジェネレータコマンドを実行して、メーラー関連のクラスを作成します。

```bash
$ bin/rails generate mailer User
create  app/mailers/user_mailer.rb
invoke  erb
create    app/views/user_mailer
invoke  test_unit
create    test/mailers/user_mailer_test.rb
create    test/mailers/previews/user_mailer_preview.rb
```

生成されるすべてのメーラークラスは、以下の`UserMailer`と同様に`ApplicationMailer`を継承します。

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
end
```

上の`ApplicationMailer`クラスは`ActionMailer::Base`を継承しており、すべてのメーラーに共通する属性を以下のように定義できます。

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout 'mailer'
end
```

ジェネレータを使いたくない場合は、`app/mailers`ディレクトリ以下にファイルを手動で作成します。このクラスは、必ず`ActionMailer::Base`を継承するようにしてください。

```ruby
# app/mailers/custom_mailer.rb
class CustomMailer < ApplicationMailer
end
```

### メーラーを編集する

`app/mailers/user_mailer.rb`に最初に作成される`UserMailer`クラスには、メソッドがありません。そこで、次に特定のメールを送信するメソッド（アクション）をメーラーに追加します。

メーラーには「アクション」と呼ばれるメソッドがあり、コントローラーのアクションと同様に、ビューを用いてコンテンツを構造化します。コントローラーはクライアントに送り返すHTMLコンテンツを生成しますが、メーラーはメールで配信されるメッセージを作成します。

`UserMailer`クラスに以下のように`welcome_email`というメソッドを追加して、ユーザーの登録済みメールアドレスにメールを送信しましょう。

```ruby
class UserMailer < ApplicationMailer
  default from: "notifications@example.com"

  def welcome_email
    @user = params[:user]
    @url  = "http://example.com/login"
    mail(to: @user.email, subject: "私の素敵なサイトへようこそ")
  end
end
```

NOTE: メーラー内のメソッド名は、末尾を`_email`にする必要はありません。

上のメソッドで使われているメーラー関連のメソッドについて簡単に説明します。

* [`default`][]: メーラーから送信するあらゆるメールで使われるデフォルト値のハッシュです。上の例の場合、`:from`ヘッダーにこのクラスのすべてのメッセージで使う値を1つ設定しています。この値はメールごとに上書きすることもできます。
* [`mail`][]: 実際のメールメッセージです。ここでは`:to`ヘッダーと`:subject`ヘッダーを渡しています。

また、[`headers`][]メソッドは、メールのヘッダーをハッシュで渡すか、`headers[:field_name] = 'value'`を呼び出すことで指定できます（上のサンプルで使っていません）。

以下のように、メーラーをジェネレータで生成するときに直接アクションを指定することも可能です。

```bash
$ bin/rails generate mailer User welcome_email
```

上のコマンドは、空の`welcome_email`メソッドを持つ`UserMailer`クラスを生成します。

1個のメーラークラスから複数のメールを送信することも可能です。これは、関連するメールをグループ化するのに便利です。たとえば、、`UserMailer`クラスには`welcome_email`メソッドの他に、`password_reset_email`メソッドも追加できます。

[`default`]:
    https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-c-default
[`mail`]:
    https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-mail
[`headers`]:
    https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-headers

#### メーラービューを作成する

次に、`welcome_email`アクションに対応する`welcome_email.html.erb`というファイル名のビューを`app/views/user_mailer/`ディレクトリの下に作成する必要があります。以下は、ウェルカムメールに使えるHTMLテンプレートのサンプルです。

```html+erb
<h1><%= @user.name %>様、example.comへようこそ。</h1>
<p>
  example.comへのサインアップが成功しました。
  ユーザー名は「<%= @user.login %>」です。<br>
</p>
<p>
  このサイトにログインするには、次のリンクをクリックしてください: <%= link_to 'login`, login_url %>
</p>
<p>本サイトにユーザー登録いただきありがとうございます。</p>
```

NOTE: 上のサンプルは`<body>`タグの内容です。これは、`<html>`タグを含むデフォルトのメーラーレイアウトに埋め込まれます。詳しくは、[メーラーのレイアウト](#action-mailerのレイアウト) を参照してください。

また、上のメールのテキストバージョンを`app/views/user_mailer/`ディレクトリの`welcome_email.text.erb`ファイルに保存することも可能です（拡張子が`html.erb`ではなく`.text.erb`である点にご注意ください）。テキストバージョンも用意しておくと、HTMLレンダリングで問題が発生した場合に信頼できるフォールバックとして機能するため、HTML形式とテキスト形式の両方を送信することがベストプラクティスと見なされます。テキストメールの例を次に示します。

```erb
<%= @user.name %>様、example.comへようこそ。
===============================================

example.comへのサインアップが成功しました。ユーザー名は「<%= @user.login %>」です。

このサイトにログインするには、次のリンクをクリックしてください: <%= @url %>

本サイトにユーザー登録いただきありがとうございます。
```

なお、インスタンス変数（`@user`と`@url`）は、HTMLテンプレートとテキストテンプレートの両方で利用可能になります。

これで、`mail`メソッドを呼び出せば、Action Mailerは2種類のテンプレート (テキストおよびHTML) を探索して、`multipart/alternative`形式のメールを自動生成します。

### メーラーを呼び出す

メーラーのクラスとビューのセットアップが終わったら、次は、メーラーメソッドを実際に呼び出してメールのビューをレンダリングします。メーラーは、コントローラと別の方法でビューをレンダリングするものであるとみなせます。コントローラのアクションは、HTTPプロトコルで送信するためのビューをレンダリングしますが、メーラーのアクションは、メールプロトコルを経由して送信するためのビューをレンダリングします。

それでは、ユーザーの作成に成功したら`UserMailer`でウェルカムメールを送信するサンプルコードを見てみましょう。

最初にscaffoldで`User`を作成します。

```bash
$ bin/rails generate scaffold user name email login
$ bin/rails db:migrate
```

次に、`UserController`の`create`アクションを編集して、新しいユーザーが作成されたときにウェルカムメールを送信するようにします。これは、ユーザーが正常に保存された直後に`UserMailer.with(user: @user).welcome_email`への呼び出しを挿入する形で行います。

NOTE: ここでは[`deliver_later`][]を使って、Active Jobによるメールキューにメールを登録して後で送信するようにしています。これにより、コントローラのアクションはメールの送信完了を待たずに処理を続行できます。`deliver_later`メソッドは、[Active Job](active_job_basics.html#action-mailer)に支えられています。

```ruby
class UsersController < ApplicationController
  # ...

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        # 保存後にUserMailerを使ってwelcomeメールを送信
        UserMailer.with(user: @user).welcome_email.deliver_later

        format.html { redirect_to user_url(@user), notice: "ユーザーが正常に作成されました" }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # ...
end
```

[`with`][]に任意のキーバリューペアを渡すことで、Mailerアクションの`params`にできます。たとえば、`with(user: @user, account: @user.account)`を渡すことで、Mailerアクションで`params[:user]`と`params[:account]`が利用可能になります。

上記のメーラー、ビュー、コントローラーをセットアップできたので、後は新しい`User`を作成すれば、ウェルカムメールが送信されているかどうかをログをチェックすることで確認できます。ログファイルには、以下のように、テキストバージョンのメールとHTMLバージョンのメールが送信される様子が表示されます。

```bash
[ActiveJob] [ActionMailer::MailDeliveryJob] [ec4b3786-b9fc-4b5e-8153-9153095e1cbf] Delivered mail 6661f55087e34_1380c7eb86934d@Bhumis-MacBook-Pro.local.mail (19.9ms)
[ActiveJob] [ActionMailer::MailDeliveryJob] [ec4b3786-b9fc-4b5e-8153-9153095e1cbf] Date: Thu, 06 Jun 2024 12:43:44 -0500
From: notifications@example.com
To: test@gmail.com
Message-ID: <6661f55087e34_1380c7eb86934d@Bhumis-MacBook-Pro.local.mail>
Subject: Welcome to My Awesome Site
Mime-Version: 1.0
Content-Type: multipart/alternative;
 boundary="--==_mimepart_6661f55086194_1380c7eb869259";
 charset=UTF-8
Content-Transfer-Encoding: 7bit

----==_mimepart_6661f55086194_1380c7eb869259
Content-Type: text/plain;

...

----==_mimepart_6661f55086194_1380c7eb869259
Content-Type: text/html;

...
```

Railsコンソールでメーラーを呼び出してメールを送信することも可能です。この方法は、コントローラーアクションを設定する前のテストとして有用でしょう。以下は、上記と同じ`welcome_email`を送信します。

```irb
irb> user = User.first
irb> UserMailer.with(user: user).welcome_email.deliver_later
```

メールをcronjobなどから今すぐ送信したい場合は、以下のように[`deliver_now`][]を呼び出すだけで済みます。

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.with(user: user).weekly_summary.deliver_now
    end
  end
end
```

`UserMailer`などの`weekly_summary`メソッドは、[`ActionMailer::MessageDelivery`][]オブジェクトを1つ返します。このオブジェクトは、そのメール自身が送信対象であることを`deliver_now`や`deliver_later`に伝えます。`ActionMailer::MessageDelivery`オブジェクトは、[`Mail::Message`][]のラッパーです。内部の`Mail::Message`オブジェクトの表示や変更などを行いたい場合は、[`ActionMailer::MessageDelivery`][]オブジェクトの[`message`][]メソッドにアクセスできます。

上のRailsコンソールにおける`MessageDelivery`の例を以下に示します。

```irb
irb> UserMailer.with(user: user).weekly_summary
#<ActionMailer::MailDeliveryJob:0x00007f84cb0367c0
 @_halted_callback_hook_called=nil,
 @_scheduled_at_time=nil,
 @arguments=
  ["UserMailer",
   "welcome_email",
   "deliver_now",
   {:params=>
     {:user=>
       #<User:0x00007f84c9327198
        id: 1,
        name: "Bhumi",
        email: "hi@gmail.com",
        login: "Bhumi",
        created_at: Thu, 06 Jun 2024 17:43:44.424064000 UTC +00:00,
        updated_at: Thu, 06 Jun 2024 17:43:44.424064000 UTC +00:00>},
    :args=>[]}],
 @exception_executions={},
 @executions=0,
 @job_id="07747748-59cc-4e88-812a-0d677040cd5a",
 @priority=nil,
```

[`ActionMailer::MessageDelivery`]:
    https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html
[`deliver_later`]:
    https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-deliver_later
[`deliver_now`]:
    https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-deliver_now
[`Mail::Message`]: https://api.rubyonrails.org/classes/Mail/Message.html
[`message`]:
    https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-message
[`with`]:
    https://api.rubyonrails.org/classes/ActionMailer/Parameterized/ClassMethods.html#method-i-with

マルチパートメールと添付ファイル
--------------------------------

MIMEタイプ`multipart`は、ドキュメントを複数のコンポーネントパーツで構成して表現します。個別のコンポーネントパーツには、それぞれ独自のMIMEタイプ（`text/html`や`text/plain`など）を利用できます。`multipart`タイプは、複数のファイルを1つのトランザクションで送信するために使います（例: メールに複数のファイルを添付する）。

### ファイルを添付する

Action Mailerで添付ファイルを追加するには、以下のように[`attachments`][]メソッドにファイル名とコンテンツを渡します。Action Mailerは自動的に`mime_type`を推測し、`encoding`を設定して添付ファイルを作成します。

```ruby
attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
```

`mail`メソッドをトリガーすると、マルチパート形式のメールが1件送信されます。送信されるメールは、トップレベルが`multipart/mixed`で最初のパートが`multipart/alternative`という正しい形式でネストしている、プレーンテキストメールまたはHTMLメールです。

添付ファイルを送信するもう1つの方法は、以下のようにファイル名、MIMEタイプとエンコードヘッダー、コンテンツを指定することです。Action Mailerは、渡された設定を利用します。

```ruby
encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
attachments['filename.jpg'] = {
  mime_type: 'application/gzip',
  encoding: 'SpecialEncoding',
  content: encoded_content
}
```

NOTE: Action Mailerは添付ファイルを自動的にBase64でエンコードします。別のエンコードが必要な場合は、コンテンツをエンコードしてから、エンコードされたコンテンツとエンコードを`Hash`として`attachments`メソッドに渡せます。エンコードを指定すると、Action Mailerは添付ファイルをBase64でエンコードしません。

[`attachments`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-attachments

### インライン添付ファイルを作成する

場合によっては、添付ファイル（画像など）をメール本文内にインライン表示したいことがあります。

これを行うには、まず以下のように`#inline`を呼び出して添付ファイルをインライン添付ファイルに変換します。

```ruby
def welcome
  attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
end
```

次に、ビューで`attachments`をハッシュとして参照して、インライン表示したい添付ファイルを指定します。以下のように、ハッシュで`url`を呼び出した結果を[`image_tag`](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-image_tag)メソッドに渡せます。

```html+erb
<p>こんにちは、リクエストいただいた写真は以下です:</p>

<%= image_tag attachments['image.jpg'].url %>
```

これは`image_tag`に対する標準的な呼び出しであるため、画像ファイルを扱う場合と同様に、添付URLの後にもオプションのハッシュを渡せます。

```html+erb
<p>こんにちは、以下の写真です。</p>

<%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
```

### マルチパートメール

[メーラービューを作成する](#メーラービューを作成する)で説明したように、同じアクションに異なるテンプレートがある場合、Action Mailerは自動的にマルチパートメールを送信します。たとえば、`UserMailer`が`app/views/user_mailer`ディレクトリに`welcome_email.text.erb`と`welcome_email.html.erb`を配置している場合、Action MailerはHTMLバージョンとテキストバージョンのメーラーを両方とも異なる部分として含めたマルチパートメールを自動的に送信します。

[Mail](https://github.com/mikel/mail) gem には、`text/plain`および`text/html`という[MIMEタイプ](https://developer.mozilla.org/ja-JP/docs/Web/HTTP/Basics_of_HTTP/MIME_types)を対象とする`multipart/alternate`メールを作成するためのヘルパーメソッドがあり、その他のMIMEタイプのメールについては手動で作成できます。

NOTE: 挿入されるパーツの順序は、`ActionMailer::Base.default`メソッド内の`:parts_order`で決定されます。

マルチパートは、電子メールで添付ファイルを送信するときにも使われます。

メーラーのビューとレイアウト
------------------------

Action Mailerは、メールで送信するコンテンツをビューファイルで指定します。デフォルトでは、メーラーのビューは`app/views/name_of_mailer_class`ディレクトリに配置されます。コントローラのビューの場合と同様に、ファイル名はMailerのメソッド名と一致します。

メーラーのビューは、コントローラのビューと同様に、レイアウトの内側でレンダリングされます。メーラーのレイアウトは、`app/views/layouts`に配置されます。メーラーのデフォルトのレイアウトファイルは、`mailer.html.erb`と`mailer.text.erb`です。このセクションでは、メーラーのビューとレイアウトに関するさまざまな機能について説明します。

### ビューのパスをカスタマイズする

アクションに対応するデフォルトのメーラービューは、以下のようにさまざまな方法で変更できます。

`mail`メソッドでは、以下のように`template_path`と`template_name`オプションが利用できます。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    @user = params[:user]
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: '私の素敵なサイトへようこそ',
         template_path: 'notifications',
         template_name: 'hello')
  end
end
```

上の設定によって、`mail`メソッドは`app/views/notifications`ディレクトリ以下にある`hello`という名前のテンプレートを探索します。`template_path`にはパスの配列も指定できます。この場合探索は配列順に沿って行われます。

より柔軟な方法を使いたい場合は、ブロックを渡して特定のテンプレートをレンダリングする方法や、テンプレートファイルを使わずにインラインでテキストをレンダリングする方法も利用できます。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    @user = params[:user]
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: '私の素敵なサイトへようこそ') do |format|
      format.html { render 'another_template' }
      format.text { render plain: 'hello' }
    end
  end
end
```

上のコードは、HTMLパートを`another_template.html.erb`テンプレートでレンダリングし、テキストパートを"hello"でレンダリングしています。[render][]メソッドはAction Controllerで使われているものと同じなので、`:plain`や`:inline`などのオプションもすべて同様に利用できます。

最後に、デフォルトの`app/views/mailer_name/`ディレクトリ以外の場所にあるテンプレートでレンダリングしたい場合は、以下のように[`prepend_view_path`][]を適用します。

```ruby
class UserMailer < ApplicationMailer
  prepend_view_path "custom/path/to/mailer/view"

  # "custom/path/to/mailer/view/welcome_email" テンプレートの読み出しを試みる
  def welcome_email
    # ...
  end
end
```

または[`append_view_path`][]メソッドも利用できます。

[`append_view_path`]:
    https://api.rubyonrails.org/classes/ActionView/ViewPaths/ClassMethods.html#method-i-append_view_path
[`prepend_view_path`]:
    https://api.rubyonrails.org/classes/ActionView/ViewPaths/ClassMethods.html#method-i-prepend_view_path
[render]:
    https://api.rubyonrails.org/classes/ActionController/Rendering.html#method-i-render

### Action MailerのビューでURLを生成する

アプリケーションのホスト情報をメーラー内で使いたい場合は、最初に`:host`パラメータでアプリケーションのドメイン名を明示的に指定する必要があります。理由は、メーラーのインスタンスは、コントローラと異なり、サーバーが受信するHTTPリクエストのコンテキストと無関係であるためです。

アプリケーション全体で共通のデフォルト`:host`を設定するには、`config/application.rb`に以下を追加します。

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

独自の`host`を設定したら、メールビューでは、相対URLを生成する`*_path`ヘルパーではなく、完全なURLを生成する`*_url`を使うことをオススメします。メールクライアントはWebリクエストのコンテキストを持たないため、`*_path`ヘルパーが完全なWebアドレスをビルドするのに必要なベースURLがありません。

```html+erb
<%= link_to 'ようこそ', welcome_path %>
```

たとえば、メールビューでは上の`*_path`ではなく、以下のように`*_url`を使う必要があります。

```html+erb
<%= link_to 'ようこそ', welcome_url %>
```

フルパスのURLを使うことで、メール内のリンクが正常に機能するようになります。

#### `url_for`でURLを生成する

テンプレートで[`url_for`][]を用いて生成したURLは、デフォルトでフルパスになります。

`:host`オプションをグローバルに設定していない場合は、[`url_for`][]に`:host`オプションを明示的に渡す必要があります。

```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

[`url_for`]:
    https://api.rubyonrails.org/classes/ActionView/RoutingUrlFor.html#method-i-url_for

#### 名前付きルーティングでURLを生成する

他のURLと同様に、名前付きルーティングヘルパーについても`*_path`ではなく`*_url`を使う必要があります。

`:host`オプションをグローバルに設定するか、[`url_for`][]に`:host`オプションを明示的に渡すようにしてください。

```erb
<%= user_url(@user, host: 'example.com') %>
```

### Action Mailerのビューに画像を追加する

`image_tag`ヘルパーをメールで使えるようにするには、`:asset_host`パラメータを指定する必要があります。理由は、メーラーのインスタンスは、サーバーが受信するHTTPリクエストのコンテキストを持っていないためです。

`:asset_host`はアプリケーション全体で同じものを使うのが普通なので、`config/application.rb`で以下のようにグローバルに設定できます。

```ruby
config.action_mailer.asset_host = 'http://example.com'
```

NOTE: このプロトコルはリクエストから推測できないため、`:asset_host`コンフィグでは`http://`や`https://`などのプロトコルを指定する必要があります。

これで、以下のようにメール内で画像を表示できます。

```html+erb
<%= image_tag 'image.jpg' %>
```

### メーラービューをキャッシュする

アプリケーションビューで[`cache`][]メソッドを用いるときと同じように、メーラービューでもフラグメントキャッシュを利用できます。

```html+erb
<% cache do %>
  <%= @company.name %>
<% end %>
```

この機能を使うには、アプリケーションの`config/environments/*.rb`ファイルで以下の設定が必要です。

```ruby
config.action_mailer.perform_caching = true
```

フラグメントキャッシュはマルチパートメールでもサポートされています。詳しくは[Rails のキャッシュ機構](caching_with_rails.html)ガイドを参照してください。

[`cache`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CacheHelper.html#method-i-cache

### Action Mailerのレイアウト

メーラーのレイアウトも、コントローラのビューと同様の方法で設定できます。メーラーのレイアウトは`app/views/layouts`ディレクトリに配置されます。以下はデフォルトのレイアウトです。

```html
# app/views/layouts/mailer.html.erb
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

上のレイアウトは、`mailer.html.erb`ファイルにあります。デフォルトのレイアウト名は、先ほど[メーラーを生成する](#メーラーを生成する)セクションの`layout "mailer"`行で見たように、`ApplicationMailer`で指定されます。コントローラーのレイアウトと同様に、メーラーのビューをレイアウト内でレンダリングするには`yield`を使います。

別のレイアウトファイルを明示的に指定したい場合は、メーラーで[`layout`][]を呼び出します。

```ruby
class UserMailer < ApplicationMailer
  layout 'awesome' # awesome.(html|text).erbをレイアウトとして使う
end
```

特定のメールでレイアウトを指定するには、以下のように`format`ブロック内の`render`メソッド呼び出しで`layout: 'layout_name'`オプションを渡します。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    mail(to: params[:user].email) do |format|
      format.html { render layout: 'my_layout' }
      format.text
    end
  end
end
```

上のコードは、HTMLパートについては`my_layout.html.erb`レイアウトファイルでレンダリングし、テキストパートについては通常の`user_mailer.text.erb`でレンダリングします。

[`layout`]:
    https://api.rubyonrails.org/classes/ActionView/Layouts/ClassMethods.html#method-i-layout

メールを送信する
-------------

### メールを複数の相手に送信する

`:to`キーにメールアドレスのリストを設定すると、1件のメールを複数の相手に送信できます。メールアドレスのリストの形式は、メールアドレスの配列でも、メールアドレスをカンマで区切った単一の文字列でも構いません。

たとえば、新規登録を管理者全員に通知するには以下のようにします。

```ruby
class AdminMailer < ApplicationMailer
  default to: -> { Admin.pluck(:email) },
          from: 'notification@example.com'

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
```

CC (カーボンコピー) やBCC (ブラインドカーボンコピー) アドレスを指定する場合にも同じ形式を使えます。それぞれ`:cc`キーと`:bcc`キーを使います（使い方は`:to`フィールドと同じ要領です）。

### メールアドレスを名前で表示する

メールアドレスを表示する代わりに、メールの受信者や送信者の名前をメールに表示したいことがあります。

ユーザーがメールを受信したときにメールアドレスの位置に受信者名を表示するには、以下のように`to:`フィールドで[`email_address_with_name`][]メソッドを使います。

```ruby
def welcome_email
  @user = params[:user]
  mail(
    to: email_address_with_name(@user.email, @user.name),
    subject: '私の素敵なサイトへようこそ'
  )
end
```

同じ要領で、送信者名も`from:`フィールドで指定できます。

```ruby
class UserMailer < ApplicationMailer
  default from: email_address_with_name('notification@example.com', '会社からのお知らせの例')
end
```

名前が空白（`nil`または空文字）の場合は、メールアドレスのみを返します。

[`email_address_with_name`]:
    https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-email_address_with_name

### 送信メールの件名を訳文に置き換える

メールメソッドに件名を渡さなかった場合、Action Mailerは件名を国際化（I18n）の訳文から探索します。詳しくは、[国際化ガイド](i18n.html#action-mailerメールの件名を訳文に置き換える)を参照してください。

### テンプレートをレンダリングせずにメール送信する

メール送信時にテンプレートのレンダリングをスキップしてメール本文に単なる文字列を指定したい場合は、`:body`オプションを使えます。このオプションを使う場合は、`:content_type`オプションも指定も忘れないでください。`:content_type`オプションが指定されていないと、デフォルトの`text/plain`が適用されます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    mail(to: params[:user].email,
         body: params[:email_body],
         content_type: "text/html",
         subject: "レンダリング完了")
  end
end
```

### メール送信時に配信オプションを動的に変更する

SMTP認証情報（credential）などのデフォルトの[配信設定](#action-mailerを設定する)をメール配信時に上書きしたい場合、メーラーのアクションで`delivery_method_options`を使って変更できます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url  = user_url(@user)
    delivery_options = { user_name: params[:company].smtp_user,
                         password: params[:company].smtp_password,
                         address: params[:company].smtp_host }
    mail(to: @user.email,
         subject: "添付の利用規約を参照してください",
         delivery_method_options: delivery_options)
  end
end
```

Action Mailerのコールバック
---------------------------

Action Mailerには以下のコールバックがあります。

メッセージの設定: [`before_action`][]、[`after_action`][]、
[`around_action`][]。

配信の制御: [`before_deliver`][]、[`after_deliver`][]、[`around_deliver`][]。

メーラーのコールバックには、コントローラやモデルのコールバックと同様、ブロックまたはシンボル（メーラークラス内のメソッド名を表す）を渡せます。コールバックをメーラーで利用する場合の例をいくつか示します。

### `before_action`

`before_action`コールバックは、インスタンス変数を設定したり、デフォルト値付きのメールオブジェクトを渡したり、デフォルトのヘッダや添付ファイルを挿入したりするのに利用できます。

```ruby
class InvitationsMailer < ApplicationMailer
  before_action :set_inviter_and_invitee
  before_action { @account = params[:inviter].account }

  default to:       -> { @invitee.email_address },
          from:     -> { common_address(@inviter) },
          reply_to: -> { @inviter.email_address_with_name }

  def account_invitation
    mail subject: "#{@inviter.name} をBasecampに招待いたします (#{@account.name})"
  end

  def project_invitation
    @project    = params[:project]
    @summarizer = ProjectInvitationSummarizer.new(@project.bucket)

    mail subject: "#{@inviter.name.familiar} をBasecampのプロジェクトに追加しました (#{@account.name})"
  end

  private
    def set_inviter_and_invitee
      @inviter = params[:inviter]
      @invitee = params[:invitee]
    end
end
```

### `after_action`

`after_action`コールバックも`before_action`と同様のセットアップで利用できますが、メーラーのアクション内で設定されたインスタンス変数も利用できます。`after_action`コールバックは、`mail.delivery_method.settings`設定を更新して配信メソッドを上書きするときにも利用できます。

```ruby
class UserMailer < ApplicationMailer
  before_action { @business, @user = params[:business], params[:user] }

  after_action :set_delivery_options,
               :prevent_delivery_to_guests,
               :set_business_headers

  def feedback_message
  end

  def campaign_message
  end

  private
    def set_delivery_options
      # ここではメールのインスタンスや
      # @businessや@userインスタンス変数にアクセスできる
      if @business && @business.has_smtp_settings?
        mail.delivery_method.settings.merge!(@business.smtp_settings)
      end
    end

    def prevent_delivery_to_guests
      if @user && @user.guest?
        mail.perform_deliveries = false
      end
    end

    def set_business_headers
      if @business
        headers["X-SMTPAPI-CATEGORY"] = @business.code
      end
    end
end
```

### `after_deliver`

`after_deliver`はメッセージ配信を記録するのに利用できます。メーラーのコンテキスト全体にアクセスするオブザーバーやインターセプタのような振る舞いも可能です。

```ruby
class UserMailer < ApplicationMailer
  after_deliver :mark_delivered
  before_deliver :sandbox_staging
  after_deliver :observe_delivery

  def feedback_message
    @feedback = params[:feedback]
  end

  private
    def mark_delivered
      params[:feedback].touch(:delivered_at)
    end

    # インターセプタの代替
    def sandbox_staging
      message.to = ['sandbox@example.com'] if Rails.env.staging?
    end

    # コールバックは、同様のオブザーバーの例よりも多くのコンテキストを含む
    def observe_delivery
      EmailDelivery.log(message, self.class, action_name, params)
    end
end
```

メールの`body`に`nil`以外の値が設定されている場合、メーラーのコールバックは以後の処理を中止します。
`before_deliver`は`throw :abort`で中止できます。

[`after_action`]:
    https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-after_action
[`after_deliver`]:
    https://api.rubyonrails.org/classes/ActionMailer/Callbacks/ClassMethods.html#method-i-after_deliver
[`around_action`]:
    https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-around_action
[`around_deliver`]:
    https://api.rubyonrails.org/classes/ActionMailer/Callbacks/ClassMethods.html#method-i-around_deliver
[`before_action`]:
    https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-before_action
[`before_deliver`]:
    https://api.rubyonrails.org/classes/ActionMailer/Callbacks/ClassMethods.html#method-i-before_deliver

Action Mailerのビューヘルパー
---------------------------

Action Mailerでは、通常のビューと同様のヘルパーメソッドを利用できます。

Action Mailer固有のヘルパーメソッドは、[`ActionMailer::MailHelper`][]で利用できます。
たとえば、[`mailer`][MailHelper#mailer]を用いてビューからメーラーインスタンスにアクセスすることも、[`message`][MailHelper#message]でメッセージにアクセスすることも可能です。


```erb
<%= stylesheet_link_tag mailer.name.underscore %>
<h1><%= message.subject %></h1>
```

[`ActionMailer::MailHelper`]:
    https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html
[MailHelper#mailer]:
    https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html#method-i-mailer
[MailHelper#message]:
    https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html#method-i-message

Action Mailerを設定する
---------------------------

本セクションでは、Action Mailerの設定例の一部を示すにとどめます。

さまざまな設定オプションの説明について詳しくは、「Rails アプリケーションを設定する」ガイドの[Action Mailerを設定する](configuring.html#action-mailerを設定する)を参照してください。これらのオプションは、`production.rb`などの環境固有の設定ファイルで設定できます。

### Action Mailerの設定例

適切な`config/environments/$RAILS_ENV.rb`ファイルに追加する設定の例を以下に示します。

```ruby
config.action_mailer.delivery_method = :sendmail
# デフォルトは以下:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: %w[ -i ]
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = { from: 'no-reply@example.com' }
```

### Gmail用のAction Mailer設定

Gmail経由でメールを送信するには、`config/environments/$環境名.rb`ファイルに以下の設定を追加します。

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:         'smtp.gmail.com',
  port:            587,
  domain:          'example.com',
  user_name:       Rails.application.credentials.dig(:smtp, :user_name),
  password:        Rails.application.credentials.dig(:smtp, :password),
  authentication:  'plain',
  enable_starttls: true,
  open_timeout:    5,
  read_timeout:    5 }
```

NOTE: Googleは、安全性が低いと判断したアプリからのサインインを[ブロック](https://support.google.com/accounts/answer/6010255)しています。<br><br>[Gmailの設定を変更](https://www.google.com/settings/security/lesssecureapps)することで、サインイン試行を許可できます。Gmailアカウントで2要素認証が有効になっている場合は、[アプリケーションのパスワード](https://myaccount.google.com/apppasswords)を設定し、通常のパスワードの代わりにそれを使う必要があります。

メーラーのテストとプレビュー
------------------------------

メーラーのテスト方法について詳しくは、テスティングガイドの[メーラーをテストする](testing.html#メーラーをテストする)を参照してください。

### メールのプレビュー

Action Mailerのプレビュー機能は、レンダリング用のURLを開くことでメールの外観を確認する方法を提供します。

上述の`UserMailer`クラスでプレビューをセットアップするには、`UserMailerPreview`という名前のクラスを作成して`test/mailers/previews/`ディレクトリに配置します。`UserMailer`の`welcome_email`のプレビューを表示するには、`UserMailerPreview`で同じ名前のメソッドを実装してから、`UserMailer.welcome_email`を呼び出します。

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.with(user: User.first).welcome_email
  end
end
```

これで、<http://localhost:3000/rails/mailers/user_mailer/welcome_email>にアクセスしてプレビューを表示できます。

`app/views/user_mailer/welcome_email.html.erb`メーラービューやメーラー自身に何らかの変更を加えると、自動的に再読み込みしてレンダリングされるので、スタイル変更を画面ですぐ確認できます。利用可能なプレビューのリストは<http://localhost:3000/rails/mailers>で表示できます。

これらのプレビュー用クラスは、デフォルトで`test/mailers/previews`に配置されます。このパスは`preview_paths`オプションで設定できます。たとえば`lib/mailer_previews`に変更したい場合は`config/application.rb`に以下の設定を追加します。

```ruby
config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"
```

### エラーを`rescue`する

メーラーメソッド内の`rescue`ブロックは、レンダリングの外で発生したエラーをキャッチできません。たとえば、バックグラウンドジョブ内でのレコードのデシリアライズエラーや、サードパーティのメール配信サービスからのエラーはキャッチできません。

メール送信処理中に発生するエラーをキャッチするには、以下のように[`rescue_from`][]を使います。

```ruby
class NotifierMailer < ApplicationMailer
  rescue_from ActiveJob::DeserializationError do
    # ...
  end

  rescue_from "SomeThirdPartyService::ApiError" do
    # ...
  end

  def notify(recipient)
    mail(to: recipient, subject: "Notification")
  end
end
```

[`rescue_from`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

メールのインターセプタとオブザーバー
-------------------

Action Mailerは、メールのオブザーバーやインターセプターのメソッドへのフックを提供します。これを用いて、送信されるすべてのメールのメール配信のライフサイクル中に呼び出されるクラスを登録できます。

### メールをインターセプトする

インターセプタを使うと、メールを配信エージェントに渡す前にメールを加工できます。インターセプタクラスは以下のように、メールが送信される前に呼び出される`::delivering_email(message)`メソッドを実装しなければなりません。

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

`interceptors`設定オプションを用いてインターセプタを登録しておく必要があります。これを行うには、`config/initializers/mail_interceptors.rb`などのイニシャライズファイルを以下のような内容で作成します。

```ruby
Rails.application.configure do
  if Rails.env.staging?
    config.action_mailer.interceptors = %w[SandboxEmailInterceptor]
  end
end
```

NOTE: 上の例では"staging"というカスタマイズした環境を使っています。これはproduction環境に準じた状態でテストを行うための環境です。Railsのカスタム環境については[Rails環境を作成する](configuring.html#rails環境を作成する)を参照してください。

### メールのオブザーバー

オブザーバーを使うと、メールが送信された後でメールのメッセージにアクセスできるようになります。オブザーバークラスは以下のように、メール送信後に呼び出される`:delivered_email(message)`メソッドを実装しなければなりません。

```ruby
class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailDelivery.log(message)
  end
end
```

インターセプタのときと同様、`observers`設定オプションを用いてオブザーバーを登録しておかなければなりません。これを行うには、`config/initializers/mail_observers.rb`などのイニシャライズファイルを以下のような内容で作成します。

```ruby
Rails.application.configure do
  config.action_mailer.observers = %w[EmailDeliveryObserver]
end
```
