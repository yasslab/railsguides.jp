
Action Mailer の基礎
====================

本章では、アプリケーションでメールの送受信を行えるようにするために必要なすべての事項と、Action Mailerのさまざまな内部情報を提供します。また、メイラーのテスト方法についても説明します。

このガイドの内容:

* Railsアプリケーションでメールを送受信する方法
* Action Mailerクラスとメイラービューの生成および編集方法
* 環境に合わせてAction Mailerを設定する方法
* Action Mailerクラスのテスト方法

--------------------------------------------------------------------------------

はじめに
------------

Action Mailerを使用することで、アプリケーションのメイラークラスやビューでメールを送信することができます。メイラーの動作はコントローラときわめて似通っています。メイラーは`ActionMailer::Base`を継承し、`app/mailers`に配置され、`app/views`にあるビューと結び付けられます。

メールを送信する
--------------

このセクションでは、メイラーとビューの作成方法を手順を追って説明します。

### メイラー生成の全手順

#### メイラーを作成する

```bash
$ bin/rails generate mailer UserMailer
create  app/mailers/user_mailer.rb
create  app/mailers/application_mailer.rb
invoke  erb
create    app/views/user_mailer
create    app/views/layouts/mailer.text.erb
create    app/views/layouts/mailer.html.erb
invoke  test_unit
create    test/mailers/user_mailer_test.rb
create    test/mailers/previews/user_mailer_preview.rb
```

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout 'mailer'
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
end
```

上に示したとおり、Railsの他のジェネレータ同様の方法でメイラーを生成できます。メイラーは概念上コントローラと似通っており、メイラーを生成すると (コントローラと同様に) ビューのディレクトリとテストも同時に生成されます。

ジェネレータを使用したくない場合は、app/mailersディレクトリ以下にファイルを作成し、`ActionMailer::Base`を継承してください。

```ruby
class MyMailer < ActionMailer::Base
end
```

#### メイラーを編集する

メイラーはRailsのコントローラと非常に似通っています。メイラーには「アクション」と呼ばれるメソッドがあり、メールのコンテンツを構成するのにビューを使用します。コントローラでHTMLなどのメールコンテンツを生成して顧客に送信したい場合、その箇所でメイラーを使用して、送信したいメッセージを作成します。

`app/mailers/user_mailer.rb`には空のメイラーがあります。

```ruby
class UserMailer < ApplicationMailer
end
```

`welcome_email`という名前のメソッドを追加し、ユーザーが登録したメールアドレスにメールを送信できるようにしてみましょう。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end
```

上のメソッドで使用されている項目について簡単に説明します。利用可能なすべてのオプションについては、「Action Mailerの全メソッド」セクションでユーザー設定可能な属性を参照してください。

* `default Hash` - メイラーから送信するあらゆるメールで使用されるデフォルト値のハッシュです。上の例の場合、`:from`ヘッダーにこのクラスのすべてのメッセージで使用する値を1つ設定しています。この値はメールごとに上書きすることもできます。
* `mail` - 実際のメール・メッセージです。ここでは`:to`ヘッダーと`:subject`ヘッダーを渡しています。

コントローラの場合と同様、メイラーのメソッド内で定義されたすべてのインスタンス変数はそのままビューで使用できます。

#### メイラービューを作成する

`app/views/user_mailer/`ディレクトリで`welcome_email.html.erb`というファイルを1つ作成してください。このファイルを、HTMLでフォーマットされたメールテンプレートにします。

```html+erb
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1><%= @user.name %>様、example.comへようこそ。</h1>
      <p>
      example.comへのサインアップが成功しました。
      your username is: <%= @user.login %>.<br>
    </p>
    <p>
      このサイトにログインするには、<%= @url %>をクリックしてください。
    </p>
    <p>ご入会ありがとうございます。どうぞお楽しみくださいませ。</p>
  </body>
</html>
```

続いて、同じ内容のテキストメールも作成しましょう。顧客によってはHTMLフォーマットのメールを受け取りたくない人もいるので、テキストメールも作成しておくのが最善です。これを行なうには、`app/views/user_mailer/`ディレクトリで`welcome_email.text.erb`というファイルを以下の内容で作成してください。

```erb
<%= @user.name %>様、example.comへようこそ。
===============================================

example.comへのサインアップが成功しました。ユーザー名は「<%= @user.login %>」です。

このサイトにログインするには、<%= @url %>をクリックしてください。

本サイトにユーザー登録いただきありがとうございます。
```

現在のAction Mailerでは、`mail`メソッドを呼び出すと2種類のテンプレート (テキストおよびHTML) があるかどうかを探し、`multipart/alternative`形式のメールを自動生成します。

#### メイラーを呼び出す

Railsのメイラーは、ビューのレンダリングと本質的に同じことを行っています。ビューのレンダリングではHTTPプロトコルとして送信されますが、メイラーではメールのプロトコルを経由して送信する点のみが異なります。従って、ユーザー作成に成功したときにメールを送信するようコントローラからメイラーに指示するだけで機能するようになります。

メイラー呼び出しは非常に簡単です。

例として、最初にscaffoldで`User`を作成してみましょう。

```bash
$ bin/rails generate scaffold user name email login
$ bin/rails db:migrate
```

説明用のユーザーモデルを作成したので、続いて`app/controllers/users_controller.rb`を編集し、新規ユーザーの保存成功直後に`UserMailer`の`UserMailer.welcome_email`を使用してそのユーザーにメールが送信されるようにしましょう。

Action MailerはActive Jobとうまく統合されているので、Webのリクエスト/レスポンスサイクルの外で非同期にメールを送信できます。このおかげで、ユーザーは送信完了を待つ必要がありません。

```ruby
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # 保存後にUserMailerを使用してwelcomeメールを送信
        UserMailer.welcome_email(@user).deliver_later

        format.html { redirect_to(@user, notice: 'ユーザーが正常に作成されました。') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
```

NOTE: Active Jobはデフォルトでジョブを':inline'で実行します。したがって、この時点で`deliver_later`を使用してメールを送信できます。また、メールを後でバックグラウンドジョブから送信したい場合は、SidekiqやResqueなどのバックエンドクエリシステムを使用するようActive Jobを設定するだけで済みます。

メールをcronjobなどから今すぐ送信したい場合は、`deliver_now`を呼び出すだけで済みます。

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.weekly_summary(user).deliver_now
    end
  end
end
```

この`welcome_email`メソッドは`ActionMailer::MessageDelivery`オブジェクトを1つ返します。このオブジェクトは、そのメール自身が送信対象であることを`deliver_now`や`deliver_later`に伝えます。`ActionMailer::MessageDelivery`オブジェクトは、`Mail::Message`をラップしています。内部の`Mail::Message`オブジェクトの表示や変更などを行いたい場合は、`ActionMailer::MessageDelivery`オブジェクトの`message`メソッドにアクセスします。

### ヘッダーの値を自動エンコードする

Action Mailerは、メールのヘッダーや本文のマルチバイト文字を自動的にエンコードします。

別の文字セットを定義したい場合や、事前に手動で別のエンコードを行っておきたい場合などの複雑な事例については、[Mail](https://github.com/mikel/mail)ライブラリを参照してください。

### Action Mailerの全メソッド

以下の3つのメソッドを使用すれば、ほとんどのメール送信をカバーできます。

* `headers` - メールに追加したいヘッダーを指定します。メールヘッダーのフィールド名と値のペアをハッシュにまとめて渡すこともできますし、`headers[:field_name] = 'value'`のように呼び出すこともできます。
* `attachments` - メールにファイルを添付します。`attachments['file-name.jpg'] = File.read('file-name.jpg')`のように記述します。
* `mail` - 実際のメール自身を送信します。このメソッドにはヘッダーのハッシュをパラメータとして渡すことができます。メソッドを呼び出すと、定義しておいたメールテンプレートに応じて、プレーンテキストメールまたはマルチパートメールを送信します。

#### ファイルを添付する

Action Mailerではファイルを簡単に添付できます。

* ファイル名とコンテンツを渡すと、Action Mailerと[Mail gem](https://github.com/mikel/mail)が自動的にmime_typeを推測し、エンコードを設定してファイルを添付します。

    ```ruby
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ```

  `mail`メソッドをトリガーすると、マルチパート形式のメールが1つ送信されます。送信されるメールは、トップレベルが`multipart/mixed`で最初のパートが`multipart/alternative`という正しい形式でネストしている、プレーンテキストメールまたはHTMLメールです。

NOTE: メールに添付されるファイルは自動的にBase64でエンコードされます。他のエンコードを使用したい場合、事前に好みのエンコードを適用したコンテンツを`Hash`でエンコードしてから`attachments`に渡します。

* ヘッダーとコンテンツを指定してファイル名を渡すと、それらの設定がAction MailerとMailによって使用されます。

    ```ruby
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {
      mime_type: 'application/x-gzip',
      encoding: 'SpecialEncoding',
      content: encoded_content
    }
    ```

NOTE: エンコーディングの種類を指定すると、Mailはコンテンツが既にエンコード済みであると判断し、Base64によるエンコードを行いません。

#### ファイルをインラインで添付する

Action Mailer 3.0はファイルをインライン添付できます。この機能は3.0より前に行われた多数のハックを基に、理想に近づけるべくシンプルな実装にしたものです。

* インライン添付を使用することをMailに指示するには、Mailer内のattachmentsメソッドに対して`#inline`を呼び出すだけで済みます。

    ```ruby
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ```

* 続いて、ビューで`attachments`をハッシュとして参照し、表示したい添付ファイルを指定することができます。これを行なうには、`attachments`に対して`url`を呼び出し、その結果を`image_tag`メソッドに渡します。

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url %>
    ```

* これは`image_tag`に対する標準的な呼び出しであるため、画像ファイルを扱う時と同様、添付URLの後にもオプションのハッシュを1つ置くことができます。

    ```html+erb
    <p>こんにちは、以下の写真です。</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
    ```

#### メールを複数の相手に送信する

1つのメールを複数の相手に送信することももちろん可能です (サインアップが新規に行われたことを全管理者に通知するなど)。これを行なうには、メールのリストを`:to`キーに設定します。メールのリストの形式は、メールアドレスの配列でも、メールアドレスをカンマで区切った文字列でも構いません。

```ruby
class AdminMailer < ActionMailer::Base
  default to: Proc.new { Admin.pluck(:email) },
          from: 'notification@example.com'

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
```

CC (カーボンコピー) やBCC (ブラインドカーボンコピー) アドレスを指定する場合にも同じ形式を使用できます。それぞれ`:cc`キーと`:bcc`キーを使用します。

#### メールアドレスを名前で表示する

受信者のメールアドレスをメールにそのまま表示するのではなく、受信者の名前で表示したいことがあります。これを行なうには、メールアドレスを`"フルネーム <メールアドレス>"`の形式で指定します。

```ruby
def welcome_email(user)
  @user = user
  email_with_name = %("#{@user.name}" <#{@user.email}>)
  mail(to: email_with_name, subject: 'Welcome to My Awesome Site')
end
```

### メイラーのビュー

メイラーのビューは`app/views/name_of_mailer_class`ディレクトリに置かれます。個別のメイラービューは、その名前がメイラーメソッドと同じになるので、クラスから認識できます。先の例の場合、`welcome_email`メソッドで使用するメイラービューは、HTML版であれば`app/views/user_mailer/welcome_email.html.erb`が使用され、プレーンテキストであれば`welcome_email.text.erb`が使用されます。

アクションで使用するデフォルトのメイラービューを変更するには、たとえば以下のようにします。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site',
         template_path: 'notifications',
         template_name: 'another')
  end
end
```

上のコードは、`another`という名前のテンプレートを`app/views/notifications`ディレクトリ以下から探索します。`template_path`にはパスの配列を指定することもできます。この場合探索は配列順に沿って行われます。

より柔軟性の高い方法を使用したい場合は、ブロックを1つ渡して特定のテンプレートをレンダリングしたり、テンプレートを使用せずにインラインまたはテキストでレンダリングすることもできます。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site') do |format|
      format.html { render 'another_template' }
      format.text { render text: 'Render text' }
    end
  end
end
```

上のコードは、HTMLの部分を'another_template.html.erb'テンプレートを使用してレンダリングし、テキスト部分を`:text`でレンダリングしています。レンダリングのコマンドはAction Controllerで使用されているものと同じなので、`:text`、`:inline`などのオプションもすべて同様に使用できます。

### Action Mailerのレイアウト

メイラーもコントローラのビューと同様の方法でレイアウトを設定できます。メイラーで使用するレイアウト名はメイラーと同じ名前である必要があります。たとえば、`user_mailer.html.erb`や`user_mailer.text.erb`というレイアウトは自動的にメイラーでレイアウトとして認識されます。

別のレイアウトファイルを明示的に指定したい場合は、メイラーで`layout`を呼び出します。

```ruby
class UserMailer < ApplicationMailer
  layout 'awesome' # awesome.(html|text).erbをレイアウトとして使用する
end
```

コントローラのビューと同様に、`yield`を使用してレイアウト内のビューをレンダリングできます。

formatブロック内でrenderメソッド呼び出しに`layout: 'layout_name'`オプションを渡すことで、フォーマットごとに異なるレイアウトを指定することもできます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(to: user.email) do |format|
      format.html { render layout: 'my_layout' }
      format.text
    end
  end
end
```

上のコードは、HTMLの部分については`my_layout.html.erb`レイアウトファイルを明示的に使用してレンダリングし、テキストの部分については通常の`user_mailer.text.erb`があればそれを使用してレンダリングします。

### Action MailerのビューでURLを生成する

メイラーがコントローラと異なる点のひとつは、メイラーのインスタンスはサーバーに届くHTTPリクエストのコンテキストと無関係であることです。アプリケーションのホスト情報をメイラー内で使用したい場合は`:host`パラメータを明示的に指定します。

`:host`に指定する値はそのアプリケーション内で共通であるのが普通なので、`config/application.rb`に以下の記述を追加してグローバルに利用できるようにします。

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

`*_path`ヘルパーは、動作の性質上メール内では一切使用できない点にご注意ください。メールでURLが必要な場合は`*_url`ヘルパーを使用してください。以下に例を示します。

```
<%= link_to 'ようこそ', welcome_path %>
```

上のコードの代りに、以下のコードを使用する必要があります。

```
<%= link_to 'ようこそ', welcome_url %>
```

こうすることでフルパスのURLが引用され、メールのURLが正常に機能するようになります。

#### `url_for`を使用してURLを生成する

テンプレートで`url_for`を使用して生成されるURLはデフォルトでフルパスになります。

`:host`オプションをグローバルに設定していない場合は、`url_for`に`:host`オプションを明示的に渡す必要があることにご注意ください。


```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

#### 名前付きルーティングを使用してURLを生成する

メールクライアントはWebサーバーのコンテキストから切り離されているので、メールに記載するパスではWebのアドレスのベースURLは補完されません。従って、名前付きルーティングヘルパーについても "*_path" ではなく "*_url" を使用する必要があります。

`:host`オプションをグローバルに設定していない場合は、"*_url" ヘルパーに`:host`オプションを明示的に渡す必要があることにご注意ください。

```erb
<%= user_url(@user, host: 'example.com') %>
```

### マルチパートメールを送信する

あるアクションに複数の異なるテンプレートがあると、Action Mailerによって自動的にマルチパート形式のメールが送信されます。UserMailerを例にとって説明します。`app/views/user_mailer`ディレクトリに`welcome_email.text.erb`と`welcome_email.html.erb`というテンプレートがあると、Action MailerはそれぞれのテンプレートからHTMLメールとテキストメールを生成し、マルチパート形式のメールとしてひとつにまとめて自動的に送信します。

マルチパートメールに挿入されるパートの順序は`ActionMailer::Base.default`メソッドの`:parts_order`によって決まります。

### メール送信時に配信オプションを動的に変更する

SMTP認証情報などのデフォルトの配信オプションをメール配信時に上書きしたい場合、メイラーのアクションで`delivery_method_options`を使用して変更することができます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user, company)
    @user = user
    @url  = user_url(@user)
    delivery_options = { user_name: company.smtp_user,
                         password: company.smtp_password,
                         address: company.smtp_host }
    mail(to: @user.email,
         subject: "添付の利用規約を参照してください", 
         delivery_method_options: delivery_options)
  end
end
```

### テンプレートをレンダリングせずにメール送信する

メール送信時にテンプレートのレンダリングをスキップしてメール本文を単なる文字列にしたくなることがあります。このような場合には`:body`オプションを使用できます。このオプションを使用する場合は、必ず`:content_type`オプションも指定してください。指定しなかった場合はデフォルトの`text/plain`が適用されます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user, email_body)
    mail(to: user.email,
         body: email_body,
         content_type: "text/html",
         subject: "レンダリングしました")
  end
end
```

メールを受信する
----------------

Action Mailerを使用するメールの受信と解析は、メール送信に比べてやや複雑です。Railsアプリケーションでメールを受信できるようにするためには、その前にメール受信待ちするRailsアプリケーションに何らかの形でメールが転送されるようにしておく必要があります。Railsアプリケーションでメールを受信できるようにするためには、以下の作業が必要になります。

* メイラーに`receive`メソッドを実装する

* `/(アプリのパス)/bin/rails runner 'UserMailer.receive(STDIN.read)'`でメールを受信するアプリケーションに、メールサーバーからメールを転送する。

いずれかのメイラーに`receive`メソッドを定義すると、受信した生のメールはAction Mailerによって解析され、emailオブジェクトに変換されてデコードされた後、メイラーが新たにインスタンス化され、そのメイラーの`receive`インスタンスメソッドに渡されます。以下に例を示します。

```ruby
class UserMailer < ApplicationMailer
  def receive(email)
    page = Page.find_by(address: email.to.first)
    page.emails.create(
      subject: email.subject,
      body: email.body
    )

    if email.has_attachments?
      email.attachments.each do |attachment|
        page.attachments.create({
          file: attachment,
          description: email.subject
        })
      end
    end
  end
end
```

Action Mailerのコールバック
---------------------------

Action Mailerでは`before_action`、`after_action`および`around_action`というコールバックを指定できます。

* コントローラと同様、メイラークラスのメソッドにもフィルタ付きのブロックまたはシンボルを1つ指定することができます。

* `before_action`コールバックを使用してmailオブジェクトにデフォルト値やdelivery_method_optionsを与えたり、デフォルトのヘッダと添付を挿入することもできます。

* `after_action`コールバックも`before_action`と同様の設定を行いますが、メイラーのアクション内のインスタンス変数を使用します。

```ruby
class UserMailer < ApplicationMailer
  after_action :set_delivery_options,
               :prevent_delivery_to_guests,
               :set_business_headers

  def feedback_message(business, user)
    @business = business
    @user = user
    mail
  end

  def campaign_message(business, user)
    @business = business
    @user = user
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

* メールのbodyにnil以外の値が設定されている場合、Mailer Filtersは処理を中止します。

Action Mailerヘルパーを使用する
---------------------------

Action Mailerは`AbstractController`を継承しているので、Action Controllerと同様に一般的なヘルパーメソッドを使用できます。

Action Mailerを設定する
---------------------------

以下の設定オプションは、environment.rbやproduction.rbなどの環境設定ファイルのいずれかで使用するのが最適です。

| 設定 | 説明 |
|---------------|-------------|
|`logger`|可能であればメール送受信に関する情報を生成します。`nil`を指定するとログ出力を行わなくなります。Ruby自身の`Logger`ロガーおよび`Log4r`ロガーのどちらとも互換性があります。|
|`smtp_settings`|`:smtp`の配信メソッドの詳細設定を行います。<ul><li>`:address` - リモートのメールサーバーの使用を許可する。デフォルトは`"localhost"`であり、必要に応じて変更する。</li><li>`:port` - メールサーバーが万一ポート25番で動作していない場合はここで変更する。</li><li>`:domain` - HELOドメインを指定する必要がある場合はここで行なう。</li><li>`:user_name` - メールサーバーで認証が必要な場合はここでユーザー名を指定する。</li><li>`:password` - メールサーバーで認証が必要な場合はここでパスワードを指定する。</li><li>`:authentication` - メールサーバーで認証が必要な場合はここで認証の種類を指定する。`:plain`、`:login`、`:cram_md5`のいずれかのシンボルを指定する。</li><li>`:enable_starttls_auto` - 自力では解決できない証明書問題が発生している場合は`false`を指定する。</li></ul>|
|`sendmail_settings`|`:sendmail`の配信オプションを上書きします。<ul><li>`:location` - sendmailの実行可能ファイルの場所を指定する。デフォルトは`/usr/sbin/sendmail`。</li><li>`:arguments` - sendmailに渡すコマンドライン引数を指定する。デフォルトは`-i -t`。</li></ul>|
|`raise_delivery_errors`|メール配信に失敗した場合にエラーを発生するかどうかを指定します。このオプションは、外部のメールサーバーが即時配信を行っている場合にのみ機能します。|
|`delivery_method`|配信方法を指定します。以下の配信方法を指定可能です。<ul><li>`:smtp` (default) -- `config.action_mailer.smtp_settings`で設定可能。</li><li>`:sendmail` -- `config.action_mailer.sendmail_settings`で設定可能。</li><li>`:file`: -- メールをファイルとして保存する。`config.action_mailer.file_settings`で設定可能。</li><li>`:test`: -- メールを配列`ActionMailer::Base.deliveries`に保存する。</li></ul>詳細については[APIドキュメント](http://api.rubyonrails.org/classes/ActionMailer/Base.html)を参照。|
|`perform_deliveries`|Mailのメッセージに`deliver`メソッドを実行したときに実際にメール配信を行なうかどうかを指定します。デフォルトでは配信が行われます。機能テストなどで配信を一時的にオフにしたい場合に便利です。|
|`deliveries`|`delivery_method :test`を使用してAction Mailerから送信されたメールの配列を保持します。単体テストおよび機能テストで最も便利です。|
|`default_options`|`mail`メソッドオプション (`:from`、`:reply_to`など)のデフォルト値を設定します。|

設定オプションの完全な説明については「Railsアプリケーションを設定する」ガイドの[Action Mailerを設定する](configuring.html#action-mailerを設定する)を参照してください。

### Action Mailerの設定例

適切な`config/environments/$RAILS_ENV.rb`ファイルに追加する設定の例を以下に示します。

```ruby
config.action_mailer.delivery_method = :sendmail
# デフォルトは以下のとおりです。
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i -t'
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = {from: 'no-reply@example.com'}
```

### Gmail用のAction Mailer設定

Action Mailerに[Mail gem](https://github.com/mikel/mail)が導入されたので、`config/environments/$RAILS_ENV.rb`ファイルの設定は以下のように非常に簡単になりました。

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            '<ユーザー名>',
  password:             '<パスワード>',
  authentication:       'plain',
  enable_starttls_auto: true  }
```

メイラーのテスト
--------------

メイラーのテスト方法の詳細についてはテスティングガイドの[メイラーをテストする](testing.html#メイラーをテストする)を参照してください。

メールを配信直前に加工する
-------------------

メールを配信する前に何らかの編集を加えたいことがあります。幸い、Action Mailerにはすべてのメールの配信前に処理を加えるためのフックが提供されています。これを使用して、メールが配信エージェントに最終的に渡される直前にメールの内容を変更するためのインターセプタを登録することができます。

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

インターセプタが動作するようにするには、Action Mailerフレームワークに登録する必要があります。これは、以下のようにイニシャライザファイル`config/initializers/sandbox_email_interceptor.rb`で行います。

```ruby
ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if Rails.env.staging?
```

NOTE: 上の例では"staging"というカスタマイズした環境を使用しています。これは本番 (production環境) に準じた状態でテストを行うための環境です。Railsのカスタム環境については[Rails環境を作成する](configuring.html#rails環境を作成する)を参照してください。