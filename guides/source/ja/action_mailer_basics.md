Action Mailer の基礎
====================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html)を日本語に翻訳した文書です。

本章では、アプリケーションでメールの送受信を行うために必要なすべての事項と、Action Mailerのさまざまな内部情報を提供します。また、メーラーのテスト方法についても説明します。

このガイドの内容:

* Railsアプリケーションでメールを送信する方法
* Action Mailerクラスとメーラービューの生成および編集方法
* 環境に合わせてAction Mailerを設定する方法
* Action Mailerクラスのテスト方法

--------------------------------------------------------------------------------


はじめに
------------

Action Mailerを使うと、アプリケーションのメーラークラスやビューでメールを送信できます。メーラーの動作はコントローラときわめて似通っています。メーラーは`ActionMailer::Base`を継承し、`app/mailers`に配置され、`app/views`にあるビューと結び付けられます。

メーラーには以下が含まれます。

* アクション、および関連付けられたビュー（`app/views`に現れる）
* インスタンス変数（ビューでアクセス可能）
* レイアウトやパーシャルを利用可能にする機能
* paramsハッシュにアクセス可能にする機能

[`ActionMailer::Base`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html

メールを送信する
--------------

このセクションでは、メーラーとビューの作成方法を手順を追って説明します。

### メーラー生成の全手順

#### メーラーを作成する

```bash
$ bin/rails generate mailer User
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
```

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
end
```

上に示したとおり、Railsの他のジェネレータ同様の方法でメーラーを生成できます。

ジェネレータを使いたくない場合は、`app/mailers`ディレクトリ以下にファイルを作成し、`ActionMailer::Base`を継承してください。

```ruby
class MyMailer < ActionMailer::Base
end
```

#### メーラーを編集する

メーラーはRailsのコントローラと非常に似通っています。メーラーには「アクション」と呼ばれるメソッドがあり、ビューを使ってメールのコンテンツを構成します。コントローラでHTMLなどのメールコンテンツを生成して顧客に送信したい場合、その箇所でメーラーを使って、送信したいメッセージを作成します。

`app/mailers/user_mailer.rb`には空のメーラーがあります。

```ruby
class UserMailer < ApplicationMailer
end
```

`welcome_email`という名前のメソッドを追加し、ユーザーが登録したメールアドレスにメールを送信できるようにしてみましょう。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    @user = params[:user]
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: '私の素敵なサイトへようこそ')
  end
end
```

上のメソッドで使われている項目について簡単に説明します。利用可能なすべてのオプションについては、「Action Mailerの全メソッド」セクションでユーザー設定可能な属性を参照してください。

* [`default`][]: メーラーから送信するあらゆるメールで使われるデフォルト値のハッシュです。上の例の場合、`:from`ヘッダーにこのクラスのすべてのメッセージで使う値を1つ設定しています。この値はメールごとに上書きすることもできます。
* [`mail`][]: 実際のメールメッセージです。ここでは`:to`ヘッダーと`:subject`ヘッダーを渡しています。

コントローラの場合と同様、メーラーのメソッド内で定義されたすべてのインスタンス変数はそのままビューで使えます。

[`default`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-c-default
[`mail`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-mail

#### メーラービューを作成する

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
      ユーザー名は「<%= @user.login %>」です。<br>
    </p>
    <p>
      このサイトにログインするには、<%= @url %>をクリックしてください。
    </p>
    <p>本サイトにユーザー登録いただきありがとうございます。</p>
  </body>
</html>
```

続いて、同じ内容のテキストメールも作成しましょう。顧客によってはHTMLフォーマットのメールを受け取りたくない人もいるので、テキストメールも作成しておくとベストです。これを行なうには、`app/views/user_mailer/`ディレクトリで`welcome_email.text.erb`というファイルを以下の内容で作成してください。

```erb
<%= @user.name %>様、example.comへようこそ。
===============================================

example.comへのサインアップが成功しました。ユーザー名は「<%= @user.login %>」です。

このサイトにログインするには、<%= @url %>をクリックしてください。

本サイトにユーザー登録いただきありがとうございます。
```

現在のAction Mailerでは、`mail`メソッドを呼び出すと2種類のテンプレート (テキストおよびHTML) があるかどうかを探し、`multipart/alternative`形式のメールを自動生成します。

#### メーラーを呼び出す

Railsのメーラーは、ビューのレンダリングと本質的に同じことを行っています。ビューのレンダリングではHTTPプロトコルとして送信されますが、メーラーではメールのプロトコルを経由して送信する点のみが異なります。従って、コントローラでユーザー作成に成功したときに、ビューのレンダリングと同じ要領でメーラーにメール送信を指示できます。

メーラー呼び出しは非常に簡単です。

例として、最初にscaffoldで`User`を作成してみましょう。

```bash
$ bin/rails generate scaffold user name email login
$ bin/rails db:migrate
```

説明用のユーザーモデルを作成したので、続いて`app/controllers/users_controller.rb`を編集し、新規ユーザーの保存成功直後に`UserMailer`の`UserMailer.with(user: @user)`を用いてそのユーザーにメールが送信されるようにしましょう。

[`deliver_later`][]を使うと、Active Jobによるメールキューにメールを登録できます。これにより、コントローラは送信完了を待たずに処理を続行できます。

```ruby
class UsersController < ApplicationController
  # ...

  # POST /users（または/users.json）
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        # 保存後にUserMailerを使ってwelcomeメールを送信
        UserMailer.with(user: @user).welcome_email.deliver_later

        format.html { redirect_to(@user, notice: 'ユーザーが正常に作成されました') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # ...
end
```

NOTE: Active Jobはデフォルトでジョブを`:async`アダプタで実行するので、この時点でメールを`deliver_later`で送信できます。
Active Jobのデフォルトのアダプタでは、インプロセスのスレッドプールが送信に用いられます。これは外部のインフラを一切必要としないので、development/test環境に適していますが、ペンディング中のジョブが再起動時に削除されるため、productionには不向きです。永続的なバックエンドが必要な場合は、永続的なバックエンドを用いるActive Jobアダプタ（SidekiqやResqueなど）を使う必要があります。

メールをcronjobなどから今すぐ送信したい場合は、[`deliver_now`][]を呼び出すだけで済みます。

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.with(user: user).weekly_summary.deliver_now
    end
  end
end
```

[`with`][]に渡されるキーの値は、メーラーアクションでは単なる`params`になります。つまり、`with(user: @user, account: @user.account)`と書けば、メーラーアクションで`params[:user]`や`params[:account]`を使えるようになります。ちょうどコントローラのparamsと同じ要領です。

この`welcome_email`メソッドは[`ActionMailer::MessageDelivery`][]オブジェクトを1つ返します。このオブジェクトは、そのメール自身が送信対象であることを`deliver_now`や`deliver_later`に伝えます。`ActionMailer::MessageDelivery`オブジェクトは、`Mail::Message`をラップしています。内部の[`Mail::Message`][]オブジェクトの表示や変更などを行いたい場合は、[`ActionMailer::MessageDelivery`][]オブジェクトの[`message`][]メソッドにアクセスします。

[`ActionMailer::MessageDelivery`]: https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html
[`deliver_later`]: https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-deliver_later
[`deliver_now`]: https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-deliver_now
[`Mail::Message`]: https://api.rubyonrails.org/classes/Mail/Message.html
[`message`]: https://api.rubyonrails.org/classes/ActionMailer/MessageDelivery.html#method-i-message
[`with`]: https://api.rubyonrails.org/classes/ActionMailer/Parameterized/ClassMethods.html#method-i-with

### ヘッダーの値を自動エンコードする

Action Mailerは、メールのヘッダーや本文のマルチバイト文字を自動的にエンコードします。

別の文字セットを定義したい場合や、事前に手動で別のエンコードを行っておきたい場合などの複雑な事例については、[Mail](https://github.com/mikel/mail)ライブラリを参照してください。

### Action Mailerの全メソッド

以下の3つのメソッドを使えば、ほとんどのメール送信をカバーできます。

* [`headers`][]: メールに追加したいヘッダーを指定します。メールヘッダーのフィールド名と値のペアをハッシュにまとめて渡すことも、`headers[:field_name] = 'value'`のように呼び出すことも可能です。
* [`attachments`][]: メールにファイルを添付します。`attachments['file-name.jpg'] = File.read('file-name.jpg')`のように記述します。
* [`mail`][]: 実際のメール自身を送信します。このメソッドにはヘッダーのハッシュをパラメータとして渡せます。メソッドを呼び出すと、定義しておいたメールテンプレートに応じて、プレーンテキストメールまたはマルチパートメールを送信します。

[`attachments`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-attachments
[`headers`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-headers

#### ファイルを添付する

Action Mailerではファイルを簡単に添付できます。

* ファイル名とコンテンツを渡すと、Action Mailerと[Mail gem](https://github.com/mikel/mail)が自動的に`mime_type`を推測し、`encoding`を設定してファイルを添付します。

    ```ruby
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ```

    `mail`メソッドをトリガーすると、マルチパート形式のメールが1つ送信されます。送信されるメールは、トップレベルが`multipart/mixed`で最初のパートが`multipart/alternative`という正しい形式でネストしている、プレーンテキストメールまたはHTMLメールです。

NOTE: メールに添付されるファイルは自動的に[Base64](https://ja.wikipedia.org/wiki/Base64)でエンコードされます。他のエンコードを使いたい場合は、事前に好みのエンコードを適用したコンテンツを`Hash`でエンコードしてから`attachments`に渡します。

* ヘッダーとコンテンツを指定してファイル名を渡すと、それらの設定がAction MailerとMailによって使われます。


    ```ruby
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {
      mime_type: 'application/gzip',
      encoding: 'SpecialEncoding',
      content: encoded_content
    }
    ```

NOTE: エンコーディングの種類を指定すると、Mailはコンテンツが既にエンコード済みであると判断し、Base64によるエンコードを行いません。

#### ファイルをインラインで添付する

Action Mailer 3.0はファイルをインライン添付できます。この機能は3.0より前に行われた多数のハックを基に、理想に近づけるべくシンプルな実装にしたものです。

* インライン添付を利用することをMailに指示するには、Mailer内のattachmentsメソッドに対して`#inline`を呼び出すだけで済みます。

    ```ruby
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ```

* これで、ビューで`attachments`をハッシュとして参照するだけで、表示したい添付ファイルを指定できます。これを行なうには、`attachments`に対して`url`を呼び出し、その結果を`image_tag`メソッドに渡します。

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url %>
    ```

* これは`image_tag`に対する標準的な呼び出しであるため、画像ファイルを扱う場合と同様に、添付URLの後にもオプションのハッシュを渡せます。

    ```html+erb
    <p>こんにちは、以下の写真です。</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
    ```

#### メールを複数の相手に送信する

1つのメールを複数の相手に送信することももちろん可能です（サインアップが新規に行われたことを全管理者に通知するなど）。これを行なうには、メールのリストを`:to`キーに設定します。メールのリストの形式は、メールアドレスの配列でも、メールアドレスをカンマで区切った文字列でも構いません。

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

CC (カーボンコピー) やBCC (ブラインドカーボンコピー) アドレスを指定する場合にも同じ形式を使えます。それぞれ`:cc`キーと`:bcc`キーを使います。

#### メールアドレスを名前で表示する

受信者のメールアドレスをメールにそのまま表示するのではなく、受信者の名前で表示したいことがあります。これは以下のように[`email_address_with_name`][]メソッドで行なえます。

```ruby
def welcome_email
  @user = params[:user]
  mail(
    to: email_address_with_name(@user.email, @user.name),
    subject: '私の素敵なサイトへようこそ'
  )
end
```

同じ要領で、送信者名も指定できます。

```ruby
class UserMailer < ApplicationMailer
  default from: email_address_with_name('notification@example.com', '会社からのお知らせの例')
end
```

名前が空文字列の場合は、メールアドレスのみを返します。

[`email_address_with_name`]: https://api.rubyonrails.org/classes/ActionMailer/Base.html#method-i-email_address_with_name

### メーラーのビュー

メーラーのビューは`app/views/name_of_mailer_class`ディレクトリに置かれます。個別のメーラービューは、その名前がメーラーメソッドと同じになるので、クラスから認識できます。先の例の場合、`welcome_email`メソッドで使うメーラービューは、HTML版では`app/views/user_mailer/welcome_email.html.erb`が使われ、プレーンテキストでは`welcome_email.text.erb`が使われます。

アクションで使うデフォルトのメーラービューを変更するには、たとえば以下のようにします。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    @user = params[:user]
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: '私の素敵なサイトへようこそ',
         template_path: 'notifications',
         template_name: 'another')
  end
end
```

上のコードは、`app/views/notifications`ディレクトリ以下にある`another`という名前のテンプレートを探索します。`template_path`にはパスの配列も指定できます。この場合探索は配列順に沿って行われます。

より柔軟な方法を使いたい場合は、ブロックを渡して特定のテンプレートをレンダリングする方法や、テンプレートを使わずにインラインまたはテキストでレンダリングする方法も利用できます。

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    @user = params[:user]
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: '私の素敵なサイトへようこそ') do |format|
      format.html { render 'another_template' }
      format.text { render plain: 'Render text' }
    end
  end
end
```

上のコードは、HTMLの部分を'another_template.html.erb'テンプレートでレンダリングし、テキスト部分をプレーンテキストでレンダリングしています。レンダリングのコマンドはAction Controllerで使われているものと同じなので、`:text`、`:inline`などのオプションもすべて同様に利用できます。

デフォルトの`app/views/mailer_name/`ディレクトリ以外の場所にあるテンプレートでレンダリングしたい場合は、以下のように[`prepend_view_path`][]を適用します。

```ruby
class UserMailer < ApplicationMailer
  prepend_view_path "custom/path/to/mailer/view"

  # "custom/path/to/mailer/view/welcome_email" テンプレートの読み出しを試みる
  def welcome_email
    # ...
  end
end
```

または[`append_view_path`][]メソッドの利用を検討してもよいでしょう。

[`append_view_path`]: https://api.rubyonrails.org/classes/ActionView/ViewPaths/ClassMethods.html#method-i-append_view_path
[`prepend_view_path`]: https://api.rubyonrails.org/classes/ActionView/ViewPaths/ClassMethods.html#method-i-prepend_view_path

#### メーラービューをキャッシュする

[`cache`][]メソッドを用いるアプリケーションビューと同じように、メーラービューでもフラグメントキャッシュを利用できます。

```html+erb
<% cache do %>
  <%= @company.name %>
<% end %>
```

この機能を使うには、アプリケーションで以下の設定が必要です。

```ruby
config.action_mailer.perform_caching = true
```

フラグメントキャッシュはメールがマルチパートの場合にもサポートされています。詳しくは[Rails のキャッシュ機構](caching_with_rails.html)ガイドを参照してください。

[`cache`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CacheHelper.html#method-i-cache

### Action Mailerのレイアウト

メーラーのレイアウトも、コントローラのビューと同様の方法で設定できます。メーラーで使うレイアウト名はメーラーと同じ名前にする必要があります。たとえば、`user_mailer.html.erb`や`user_mailer.text.erb`というレイアウトは自動的にメーラーでレイアウトとして認識されます。

別のレイアウトファイルを明示的に指定したい場合は、メーラーで[`layout`][]を呼び出します。

```ruby
class UserMailer < ApplicationMailer
  layout 'awesome' # awesome.(html|text).erbをレイアウトとして使う
end
```

レイアウト内のビューは、コントローラのビューと同様に`yield`でレンダリングできます。

`format`ブロック内の`render`メソッド呼び出しに`layout: 'layout_name'`オプションを渡すと、フォーマットごとに異なるレイアウトも指定できます。

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

上のコードは、HTMLの部分については`my_layout.html.erb`レイアウトファイルを明示的に用いてレンダリングし、テキストの部分については通常の`user_mailer.text.erb`があればそれを使ってレンダリングします。

[`layout`]: https://api.rubyonrails.org/classes/ActionView/Layouts/ClassMethods.html#method-i-layout

### メールのプレビュー

Action Mailerのプレビュー機能は、レンダリング用のURLを開くことでメールの外観を確認する方法を提供します。上の例の`UserMailer`クラスは、プレビューでは`UserMailerPreview`という名前にして`test/mailers/previews/user_mailer_preview.rb`に配置すべきです。`welcome_email`のプレビューを表示するには、同じ名前のメソッドを実装して`UserMailer.welcome_email`を呼び出します。

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.with(user: User.first).welcome_email
  end
end
```

これで、<http://localhost:3000/rails/mailers/user_mailer/welcome_email>にアクセスしてプレビューを表示できます。

`app/views/user_mailer/welcome_email.html.erb`やメーラー自身に何らかの変更を加えると、自動的に再読み込みしてレンダリングされるので、スタイル変更を画面ですぐ確認できます。利用可能なプレビューのリストは<http://localhost:3000/rails/mailers>で表示できます。

これらのプレビュー用クラスは、デフォルトで`test/mailers/previews`に配置されます。このパスは`preview_path`オプションで設定できます。たとえば`lib/mailer_previews`に変更したい場合は`config/application.rb`に以下の設定を追加します。

```ruby
config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
```

### Action MailerのビューでURLを生成する

メーラーのインスタンスは、サーバーが受信するHTTPリクエストのコンテキストと無関係である点がコントローラと異なります。アプリケーションのホスト情報をメーラー内で使いたい場合は`:host`パラメータを明示的に指定します。

通常、`:host`に指定する値はそのアプリケーション内で共通なので、`config/application.rb`に以下の記述を追加してグローバルに利用できるようにします。

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

`*_path`ヘルパーは、この動作の性質上メール内では一切利用できない点にご注意ください。メールでURLが必要な場合は、`*_url`ヘルパーをお使いください。

```html+erb
<%= link_to 'ようこそ', welcome_path %>
```

上のコードの代わりに、以下のコードを使う必要があります。

```html+erb
<%= link_to 'ようこそ', welcome_url %>
```

これでフルパスのURLが引用され、メールのURLが正常に機能するようになります。

#### `url_for`でURLを生成する

テンプレートで[`url_for`][]を用いて生成されるURLは、デフォルトでフルパスになります。

`:host`オプションをグローバルに設定していない場合は、[`url_for`][]に`:host`オプションを明示的に渡す必要があることにご注意ください。

```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

[`url_for`]: https://api.rubyonrails.org/classes/ActionView/RoutingUrlFor.html#method-i-url_for

#### 名前付きルーティングでURLを生成する

メールクライアントはWebサーバーのコンテキストから切り離されているので、メールに記載するパスではWebのアドレスのベースURLは補完されません。従って、名前付きルーティングヘルパーについても`*_path`ではなく常に`*_url`を使う必要があります。

`:host`オプションをグローバルに設定していない場合は、「*_url」ヘルパーに`:host`オプションを明示的に渡す必要があることにご注意ください。

```erb
<%= user_url(@user, host: 'example.com') %>
```

NOTE: `GET`以外のリンクが機能するには[rails-ujs](https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts)または[jQuery UJS](https://github.com/rails/jquery-ujs)が必須ですが、これらはメーラーテンプレートでは機能しません（通常の`GET`リクエストが出力されます）。

### Action Mailerのビューに画像を追加する

コントローラの場合と異なり、メーラーのインスタンスには受け取ったリクエストのコンテキストが一切含まれません。このため、`:asset_host`パラメータを自分で指定する必要があります。

`:asset_host`が多くの場合アプリケーション全体で一貫しているのと同様、`config/application.rb`でグローバルな設定を行えます。

```ruby
config.action_mailer.asset_host = 'http://example.com'
```

これで、以下のようにメール内で画像を表示できます。

```html+erb
<%= image_tag 'image.jpg' %>
```

### マルチパートメールを送信する

あるアクションに複数の異なるテンプレートがあると、Action Mailerによって自動的にマルチパート形式のメールが送信されます。`UserMailer`を例にとって説明します。`app/views/user_mailer`ディレクトリに`welcome_email.text.erb`と`welcome_email.html.erb`というテンプレートがあると、Action MailerはそれぞれのテンプレートからHTMLメールとテキストメールを生成し、マルチパート形式のメールとして１つにまとめて自動的に送信します。

マルチパートメールに挿入されるパートの順序は、`ActionMailer::Base.default`メソッドの`:parts_order`によって決まります。

### メール送信時に配信オプションを動的に変更する

SMTP認証情報などのデフォルトの配信オプションをメール配信時に上書きしたい場合、メーラーのアクションで`delivery_method_options`を使って変更できます。

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

### テンプレートをレンダリングせずにメール送信する

メール送信時にテンプレートのレンダリングをスキップしてメール本文を単なる文字列にしたい場合は、`:body`オプションを使えます。このオプションを使う場合は、必ず`:content_type`オプションも指定してください。指定がない場合はデフォルトの`text/plain`が適用されます。

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

Action Mailerのコールバック
---------------------------

Action Mailerでは、[`before_action`][]、[`after_action`][]、[`around_action`][]というコールバックを指定できます。

* コントローラと同様、メーラークラスのメソッドにもフィルタ付きのブロックまたはシンボルを渡せます。

* `before_action`コールバックを使うと、メールオブジェクトにデフォルト値を渡したり、デフォルトのヘッダや添付ファイルを挿入したりできるようになります。

```ruby
class InvitationsMailer < ApplicationMailer
  before_action :set_inviter_and_invitee
  before_action { @account = params[:inviter].account }

  default to:       -> { @invitee.email_address },
          from:     -> { common_address(@inviter) },
          reply_to: -> { @inviter.email_address_with_name }

  def account_invitation
    mail subject: "#{@inviter.name} invited you to their Basecamp (#{@account.name})"
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

* `after_action`コールバックも`before_action`と同様のセットアップを行えますが、メーラーのアクション内のインスタンス変数を使います。

* `after_action`コールバックは、`mail.delivery_method.settings`設定を更新して配信メソッドを上書きするときにも利用できます。

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

* メールのbodyにnil以外の値が設定されている場合、Mailer Filtersは処理を中止します。

[`after_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-after_action
[`around_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-around_action
[`before_action`]: https://api.rubyonrails.org/classes/AbstractController/Callbacks/ClassMethods.html#method-i-before_action

Action Mailerヘルパーを使う
---------------------------

Action Mailerは`AbstractController`を継承しているので、Action Controllerと同様に一般的なヘルパーメソッドを使えます。

Action Mailer固有のヘルパーメソッドは[`ActionMailer::MailHelper`][]で利用できます。たとえば、[`mailer`][MailHelper#mailer]を用いてビューからメーラーインスタンスにアクセスすることも、[`message`][MailHelper#message]でメッセージにアクセスすることも可能です。

```erb
<%= stylesheet_link_tag mailer.name.underscore %>
<h1><%= message.subject %></h1>
```

[`ActionMailer::MailHelper`]: https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html
[MailHelper#mailer]: https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html#method-i-mailer
[MailHelper#message]: https://api.rubyonrails.org/classes/ActionMailer/MailHelper.html#method-i-message

Action Mailerを設定する
---------------------------

以下の設定オプションは、environment.rbやproduction.rbなどの環境設定ファイルのいずれかで利用するのが最適です。


| 設定 | 説明 |
|---------------|-------------|
|`logger`|可能であればメール送受信に関する情報を生成します。`nil`を指定するとログ出力を行わなくなります。Ruby自身の`Logger`ロガーおよび`Log4r`ロガーのどちらとも互換性があります。|
|`smtp_settings`|`:smtp`の配信メソッドの詳細設定を行います。<ul><li>`:address`: リモートメールサーバーの利用を許可する。デフォルトは`"localhost"`であり、必要に応じて変更する。</li><li>`:port`: メールサーバーが万一ポート25番で動作していない場合はここで変更する。</li><li>`:domain`: HELOドメインを指定する必要がある場合はここで行なう。</li><li>`:user_name`: メールサーバーで認証が必要な場合はここでユーザー名を指定する。</li><li>`:password`: メールサーバーで認証が必要な場合はここでパスワードを指定する。</li><li>`:authentication`: メールサーバーで認証が必要な場合はここで認証の種類を指定する。`:plain`（パスワードを平文で送信）、`:login`（パスワードをBase64でエンコードする）、`:cram_md5`（チャレンジ/レスポンスによる情報交換と、MD5アルゴリズムによる重要情報のハッシュ化の組み合わせ）のいずれかのシンボルを指定する。</li><li>`:enable_starttls`: SMTPサーバーへの接続でSTARTTLSを利用する（サポートされていない場合は失敗する）。デフォルトは`false`。</li><li>`:enable_starttls_auto`: SMTPサーバーでSTARTTLSが有効かどうかを検出して有効にする。デフォルトは`true`。</li><li>`:openssl_verify_mode`: TLSを利用する場合にOpenSSLが認証をチェックする方法を指定できる。自己署名証明書やワイルドカード証明書でバリデーションを行う必要がある場合に非常に有用。OpenSSL検証定数の名前（'none'、'peer'、'client_once'、'fail_if_no_peer_cert'）を用いることも、この定数を直接用いることもできる（`OpenSSL::SSL::VERIFY_NONE`や`OpenSSL::SSL::VERIFY_PEER`など）</li><li>`:ssl/:tls`: SMTP接続でSMTP/TLS（SMTPS: SMTP over direct TLS connection）を有効にする。</li><li>`:open_timeout`: 接続オープン試行のタイムアウトを秒で指定する。</li><li>`:read_timeout`: read(2)呼び出しのタイムアウトを秒で指定する。</li></ul>|
|`sendmail_settings`|`:sendmail`の配信オプションを上書きします。<ul><li>`:location`: sendmailの実行可能ファイルの場所を指定する。デフォルトは`/usr/sbin/sendmail`。</li><li>`:arguments`: sendmailに渡すコマンドライン引数を指定する。デフォルトは`-i`。</li></ul>|
|`raise_delivery_errors`|メール配信に失敗した場合にエラーを発生するかどうかを指定します。このオプションは、外部のメールサーバーが即時配信を行っている場合にのみ機能します。|
|`delivery_method`|配信方法を指定します。以下の配信方法を指定可能です。<ul><li>`:smtp` (default): [`config.action_mailer.smtp_settings`][]で設定可能。</li><li>`:sendmail`: [`config.action_mailer.sendmail_settings`][]で設定可能。</li><li>`:file`: メールをファイルとして保存する。`config.action_mailer.file_settings`で設定可能。</li><li>`:test`: メールを配列`ActionMailer::Base.deliveries`に保存する。</li></ul>詳しくは[APIドキュメント](http://api.rubyonrails.org/classes/ActionMailer/Base.html)を参照。|
|`perform_deliveries`|Mailのメッセージに`deliver`メソッドを実行したときに実際にメール配信を行なうかどうかを指定します。デフォルトでは配信が行われます。機能テストなどで配信を一時的にオフにしたい場合に便利です。|
|`deliveries`|`delivery_method :test`を用いてAction Mailerから送信されたメールの配列を保持します。単体テストおよび機能テストで最も便利です。|
|`delivery_job`|`deliver_later`で使われるジョブクラス。デフォルトは`ActionMailer::MailDeliveryJob`。|
|`deliver_later_queue_name`|`deliver_later`で使われるキュー名。|
|`default_options`|`mail`メソッドオプション (`:from`、`:reply_to`など)のデフォルト値を設定します。|

設定オプションの完全な説明については「Rails アプリケーションを設定する」ガイドの[Action Mailerを設定する](configuring.html#action-mailerを設定する)を参照してください。

[`config.action_mailer.sendmail_settings`]: configuring.html#config-action-mailer-sendmail-settings
[`config.action_mailer.smtp_settings`]: configuring.html#config-action-mailer-smtp-settings

### Action Mailerの設定例

適切な`config/environments/$RAILS_ENV.rb`ファイルに追加する設定の例を以下に示します。

```ruby
config.action_mailer.delivery_method = :sendmail
# デフォルトは以下:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i'
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = {from: 'no-reply@example.com'}
```

### Gmail用のAction Mailer設定

Action Mailerは[Mail gem](https://github.com/mikel/mail)を利用して同様の設定を受け取れます。Gmailで送信するには、`config/environments/$環境名.rb`ファイルに以下の設定を追加します。

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            '<ユーザー名>',
  password:             '<パスワード>',
  authentication:       'plain',
  enable_starttls_auto: true,
  open_timeout:         5,
  read_timeout:         5 }
```

NOTE: Googleは2014年7月15日より[同社のセキュリティ対策を引き上げ](https://support.google.com/accounts/answer/6010255)、「安全性が低い」とみなされたアプリケーションからの試行をブロックするようになりました。
この試行を許可するには、[ここ](https://www.google.com/settings/security/lesssecureapps)でGmailの設定を変更できます。利用するGmailアカウントで2要素認証が有効になっている場合は、[アプリケーションのパスワード](https://myaccount.google.com/apppasswords)を設定して通常のパスワードの代わりに使う必要があります。

メーラーのテスト
--------------

メーラーのテスト方法の詳細についてはテスティングガイドの[メーラーをテストする](testing.html#メーラーをテストする)を参照してください。

メールのインターセプタとオブザーバー
-------------------

### メールをインターセプトする

インターセプタを使うと、メールを配信エージェントに渡す前にメールを加工できます。インターセプタクラスは以下のように、メールが送信される前に呼び出される`::delivering_email(message)`メソッドを実装しなければなりません。

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

インターセプタを動かす前に、`interceptors`設定オプションを用いてインターセプタを登録する必要があります。これを行うには、`config/initializers/mail_interceptors.rb`などのイニシャライズファイルを作成します。

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

インターセプタのときと同様、`observers`設定オプションを用いてオブザーバーを登録しなければなりません。これを行うには、`config/initializers/mail_observers.rb`などのイニシャライズファイルを作成します。

```ruby
Rails.application.configure do
  config.action_mailer.observers = %w[EmailDeliveryObserver]
end
```
