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

Action Mailerを使うと、アプリケーションのメイラークラスやビューでメールを送信することができます。メイラーの動作はコントローラときわめて似通っています。メイラーは`ActionMailer::Base`を継承し、`app/mailers`に配置され、`app/views`にあるビューと結び付けられます。

#### メイラーとコントローラは似ている

メイラーは`ActionMailer::Base`を継承し、`app/mailers`に配置されます。また、メイラーの動作はコントローラと非常に似通っています。類似点をいくつか下にリストアップしました。

* メイラーにはアクションがあり、`app/views`にあるビューにも関連付けられている
* メイラーにはビューでアクセス可能なインスタンス変数がある
* メイラーではレイアウトやパーシャルを使える
* メイラーではparamsハッシュにアクセスできる

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

上に示したとおり、Railsの他のジェネレータ同様の方法でメイラーを生成できます。

ジェネレータを使いたくない場合は、`app/mailers`ディレクトリ以下にファイルを作成する方法もあります。その場合、`ActionMailer::Base`は継承するようにします。


```ruby
class MyMailer < ActionMailer::Base
end
```

#### メイラーを編集する

メイラーには「アクション」と呼ばれるメソッドがあり、メールのコンテンツはビューで構成します。コントローラでHTMLなどのメールコンテンツを生成して顧客に送信したい場合、その箇所でメイラーを使って、送信したいメッセージを作成します。

`app/mailers/user_mailer.rb`には空のメイラーがあります。

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

* `default Hash` - メイラーから送信するあらゆるメールで使われるデフォルト値のハッシュです。上の例の場合、`:from`ヘッダーにこのクラスのすべてのメッセージで使う値を1つ設定しています。この値はメールごとに上書きすることもできます。
* `mail` - 実際のメール・メッセージです。ここでは`:to`ヘッダーと`:subject`ヘッダーを渡しています。

コントローラの場合と同様、メイラーのメソッド内で定義されたすべてのインスタンス変数はそのままビューで使えます。

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

続いて、同じ内容のテキストメールも作成しましょう。顧客によってはHTMLフォーマットのメールを受け取りたくない人もいるので、テキストメールも作成しておくのが最善の方法です。これを行なうには、`app/views/user_mailer/`ディレクトリで`welcome_email.text.erb`というファイルを以下の内容で作成してください。

```erb
<%= @user.name %>様、example.comへようこそ。
===============================================

example.comへのサインアップが成功しました。ユーザー名は「<%= @user.login %>」です。

このサイトにログインするには、<%= @url %>をクリックしてください。

本サイトにユーザー登録いただきありがとうございます。
```

後は`mail`メソッドを呼び出せば、Action Mailerが2種類のテンプレート (テキストおよびHTML) があるかどうかを探し、`multipart/alternative`形式のメールを自動生成するようになります。

#### メイラーを呼び出す

Railsのメイラーは、ビューのレンダリングと本質的に同じことを行っています。ビューのレンダリングではHTTPプロトコルとして送信されますが、メイラーではメールのプロトコルを経由して送信する点のみが異なります。従って、ユーザー作成に成功したときにメールを送信するようコントローラからメイラーに指示するだけで機能するようになります。

メイラー呼び出しは非常に簡単です。

例として、最初にscaffoldで`User`を作成してみましょう。

```bash
$ bin/rails generate scaffold user name email login
$ bin/rails db:migrate
```

説明用のユーザーモデルを作成したので、続いて`app/controllers/users_controller.rb`を編集し、新規ユーザーの保存成功直後に`UserMailer`の`UserMailer.with(user: @user)`を用いてそのユーザーにメールが送信されるようにしましょう。

Action MailerはActive Jobとうまく統合されているので、Webのリクエスト/レスポンスサイクルの外で非同期にメールを送信できます。このおかげで、ユーザーは送信完了を待つ必要がありません。

```ruby
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # 保存後にUserMailerを使ってwelcomeメールを送信
        UserMailer.with(user: @user).welcome_email.deliver_later

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

NOTE: Active Jobはデフォルトでジョブを`:async`で実行します。したがって、この時点でメールを`deliver_later`で送信できます。Active Jobのデフォルトのアダプタの実行では、インプロセスのスレッドプールが用いられます。これは外部のインフラを一切必要としないので、development/test環境に適しています。しかし、ペンディング中のジョブが再起動時に削除されるため、productionには不向きです。永続的なバックエンドが必要な場合は、永続的なバックエンドを用いるActive Jobアダプタ（SidekiqやResqueなど）を使う必要があります。

NOTE: `deliver_later`を呼び出すと、そのジョブは`mailers`キューの配下に置かれます。Active Jobアダプタがこれをサポートしていることを確認しておいてください。さもないと、通知なしでジョブが無視され、メール配信が差し止められる可能性があります。この動作は`config.action_mailer.deliver_later_queue_name`オプションで変更できます。

メールをcronjobなどから今すぐ送信したい場合は、`deliver_now`を呼び出すだけで済みます。

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.with(user: user).weekly_summary.deliver_now
    end
  end
end
```

`with`に渡されるキーの値は、メイラーアクションでは単なる`params`になります。つまり、`with(user: @user, account: @user.account)`とすることでメイラーアクションで`params[:user]`や`params[:account]`を使えるようになります。ちょうどコントローラのparamsと同じ要領です。

この`welcome_email`メソッドは`ActionMailer::MessageDelivery`オブジェクトを1つ返します。このオブジェクトは、そのメール自身が送信対象であることを`deliver_now`や`deliver_later`に伝えます。`ActionMailer::MessageDelivery`オブジェクトは、`Mail::Message`をラップしています。内部の`Mail::Message`オブジェクトの表示や変更などを行いたい場合は、`ActionMailer::MessageDelivery`オブジェクトの`message`メソッドにアクセスします。

### ヘッダーの値を自動エンコードする

Action Mailerは、メールのヘッダーや本文のマルチバイト文字を自動的にエンコードします。

別の文字セットを定義したい場合や、事前に手動で別のエンコードを行っておきたい場合などの複雑な事例については、[Mail](https://github.com/mikel/mail)ライブラリを参照してください。

### Action Mailerの全メソッド

以下の3つのメソッドで、ほとんどのメール送信をカバーできます。

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

NOTE: メールに添付されるファイルは自動的にBase64でエンコードされます。他のエンコードを使いたい場合、事前に好みのエンコードを適用したコンテンツを`Hash`でエンコードしてから`attachments`に渡します。

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

* 最初に、インライン添付を利用することをMailに指示するために、Mailer内のattachmentsメソッドに対して`#inline`を呼び出します。

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
    <p>こんにちは、こちらが私たちの写真です。</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
    ```

#### メールを複数の相手に送信する

1つのメールを複数の相手に送信することももちろん可能です (サインアップが新規に行われたことを全管理者に通知するなど)。これを行なうには、メールのリストを`:to`キーに設定します。メールのリストの形式は、メールアドレスの配列でも、メールアドレスをカンマで区切った文字列でも構いません。

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

受信者のメールアドレスをメールにそのまま表示するのではなく、受信者の名前で表示したいことがあります。これを行なうには、メールアドレスを`"フルネーム" <メールアドレス>`の形式で指定します。

```ruby
def welcome_email
  @user = params[:user]
  email_with_name = %("#{@user.name}" <#{@user.email}>)
  mail(to: email_with_name, subject: '私の素敵なサイトへようこそ')
end
```

### メイラーのビュー

メイラーのビューは`app/views/name_of_mailer_class`ディレクトリに置かれます。個別のメイラービューは、その名前がメイラーメソッドと同じになるので、クラスから認識できます。先の例の場合、`welcome_email`メソッドで使うメイラービューは、HTML版であれば`app/views/user_mailer/welcome_email.html.erb`が使われ、プレーンテキストであれば`welcome_email.text.erb`が使われます。

アクションで使うデフォルトのメイラービューを変更するには、たとえば以下のようにします。

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

上のコードは、`another`という名前のテンプレートを`app/views/notifications`ディレクトリ以下から探索します。`template_path`にはパスの配列を指定することもできます。この場合探索は配列順に沿って行われます。

より柔軟性の高い方法を使いたい場合は、ブロックを1つ渡して特定のテンプレートをレンダリングしたり、テンプレートを使わずにインラインまたはテキストでレンダリングすることもできます。

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

デフォルトの`app/views/mailer_name/`ディレクトリの外に配置されているテンプレートをレンダリングしたい場合は、以下のように`prepend_view_path`を適用できます。

```ruby
class UserMailer < ApplicationMailer
  prepend_view_path "custom/path/to/mailer/view"

  # ここでは"custom/path/to/mailer/view/welcome_email"テンプレートを読み出そうとする
  def welcome_email
    # ...
  end
end
```

[`append_view_path`](https://guides.rubyonrails.org/action_view_overview.html#view-paths)メソッドを用いる方法を検討してもよいでしょう。

#### メイラービューをキャッシュする

`cache`メソッドを用いるアプリケーションビューと同じように、メイラービューでもフラグメントキャッシュを利用できます。

```
<% cache do %>
  <%= @company.name %>
<% end %>
```

この機能を使うには、アプリケーションで次の設定が必要です。

```
  config.action_mailer.perform_caching = true
```

フラグメントキャッシュはメールがマルチパートの場合にもサポートされています。詳しくは[Rails caching guide](caching_with_rails.html)を参照してください。

### Action Mailerのレイアウト

メイラーもコントローラのビューと同様の方法でレイアウトを設定できます。メイラーで使うレイアウト名はメイラーと同じ名前にする必要があります。たとえば、`user_mailer.html.erb`や`user_mailer.text.erb`というレイアウトは自動的にメイラーでレイアウトとして認識されます。

別のレイアウトファイルを明示的に指定したい場合は、メイラーで`layout`を呼び出します。

```ruby
class UserMailer < ApplicationMailer
  layout 'awesome' # awesome.(html|text).erbをレイアウトとして使う
end
```

レイアウト内のビューは、コントローラのビューと同様に`yield`でレンダリングできます。

`format`ブロック内の`render`メソッド呼び出しに`layout: 'layout_name'`オプションを渡すことで、フォーマットごとに異なるレイアウトを指定することもできます。

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

`app/views/user_mailer/welcome_email.html.erb`やメイラー自身に何らかの変更を加えると、自動的に再読み込みしてレンダリングされるので、スタイル変更を画面ですぐ確認できます。利用可能なプレビューのリストは<http://localhost:3000/rails/mailers>で表示できます。

これらのプレビュー用クラスは、デフォルトでは`test/mailers/previews`に配置されます。このパスは`preview_path`オプションで設定できます。たとえば`lib/mailer_previews`に変更したい場合は`config/application.rb`に以下の設定を追加します。

```ruby
config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
```

### Action MailerのビューでURLを生成する

メイラーがコントローラと異なる点は、メイラーのインスタンスはサーバーが受信するHTTPリクエストのコンテキストと無関係であることです。アプリケーションのホスト情報をメイラー内で使いたい場合は、`:host`パラメータを明示的に指定します。

通常、`:host`に指定する値はそのアプリケーション内で共通なので、`config/application.rb`に以下の記述を追加してグローバルに利用できるようにします。

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

`*_path`ヘルパーは、上の動作の性質上、メール内では一切利用できない点にご注意ください。メールでURLが必要な場合は`*_url`ヘルパーを使ってください。以下に例を示します。

```
<%= link_to 'ようこそ', welcome_path %>
```

上のコードの代りに、以下のコードを使う必要があります。

```
<%= link_to 'ようこそ', welcome_url %>
```

こうすることでフルパスのURLが引用され、メールのURLが正常に機能するようになります。

#### `url_for`でURLを生成する

テンプレートで`url_for`を用いて生成されるURLはデフォルトでフルパスになります。

`:host`オプションをグローバルに設定していない場合は、`url_for`に`:host`オプションを明示的に渡す必要があることにご注意ください。

```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

#### 名前付きルーティングでURLを生成する

メールクライアントはWebサーバーのコンテキストから切り離されているので、メールに記載するパスではWebのアドレスのベースURLは補完されません。従って、名前付きルーティングヘルパーについても「*_path」ではなく「*_url」を使う必要があります。

`:host`オプションをグローバルに設定していない場合は、「*_url」ヘルパーに`:host`オプションを明示的に渡す必要があることにご注意ください。

```erb
<%= user_url(@user, host: 'example.com') %>
```

NOTE: `GET`以外のリンクが機能するには[rails-ujs](https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts)または[jQuery UJS](https://github.com/rails/jquery-ujs)が必須です。また、これらはメイラーテンプレートでは機能しません（通常の`GET`リクエストが出力されます）。

### Action Mailerのビューに画像を追加する

コントローラの場合と異なり、メイラーのインスタンスには受け取ったリクエストのコンテキストが一切含まれません。このため、`:asset_host`パラメータを自分で指定する必要があります。

`:asset_host`が（多くの場合）アプリケーション全体で一貫しているのと同様、`config/application.rb`でグローバルな設定を行えます。

```ruby
config.action_mailer.asset_host = 'http://example.com'
```

後は以下のようにしてメール内に画像を表示できます。

```ruby
<%= image_tag 'image.jpg' %>
```

### マルチパートメールを送信する

あるアクションに複数の異なるテンプレートがあると、Action Mailerによって自動的にマルチパート形式のメールが送信されます。`UserMailer`を例にとって説明します。`app/views/user_mailer`ディレクトリに`welcome_email.text.erb`と`welcome_email.html.erb`というテンプレートがあると、Action MailerはそれぞれのテンプレートからHTMLメールとテキストメールを生成し、マルチパート形式のメールとしてひとつにまとめて自動的に送信します。

マルチパートメールに挿入されるパートの順序は`ActionMailer::Base.default`メソッドの`:parts_order`によって決まります。

### メール送信時に配信オプションを動的に変更する

SMTP認証情報などのデフォルトの配信オプションをメール配信時に上書きしたい場合、メイラーのアクションで`delivery_method_options`を使って変更できます。

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

メール送信時にテンプレートのレンダリングをスキップしてメール本文を単なる文字列にしたいことがあります。このような場合には`:body`オプションを使えます。このオプションを使う場合は、必ず`:content_type`オプションも指定してください。指定しなかった場合はデフォルトの`text/plain`が適用されます。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email
    mail(to: params[:user].email,
         body: params[:email_body],
         content_type: "text/html",
         subject: "レンダリングしました")
  end
end
```

Action Mailerのコールバック
---------------------------

Action Mailerでは`before_action`、`after_action`および`around_action`というコールバックを指定できます。

* コントローラと同様、メイラークラスのメソッドにもフィルタ付きのブロックまたはシンボルを1つ指定することができます。

* `before_action`コールバックを使ってmailオブジェクトにデフォルト値やdelivery_method_optionsを与えたり、デフォルトのヘッダと添付を挿入することもできます。

```ruby
class InvitationsMailer < ApplicationMailer
  before_action { @inviter, @invitee = params[:inviter], params[:invitee] }
  before_action { @account = params[:inviter].account }

  default to:       -> { @invitee.email_address },
          from:     -> { common_address(@inviter) },
          reply_to: -> { @inviter.email_address_with_name }

  def account_invitation
    mail subject: "#{@inviter.name}様があなたを該当のBasecamp (#{@account.name})にご招待しました "
  end

  def project_invitation
    @project    = params[:project]
    @summarizer = ProjectInvitationSummarizer.new(@project.bucket)

    mail subject: "#{@inviter.name.familiar}様があなたをBasecampのプロジェクト (#{@account.name}) に追加しました"
  end
end
```

* `after_action`コールバックも`before_action`と同様の設定を行いますが、メイラーのアクション内のインスタンス変数を使います。

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

Action Mailerヘルパーを使う
---------------------------

Action Mailerは`AbstractController`を継承しているので、Action Controllerと同様に一般的なヘルパーメソッドを使えます。

Action Mailerを設定する
---------------------------

以下の設定オプションは、environment.rbやproduction.rbなどの環境設定ファイルのいずれかで利用するのが最適です。


| 設定 | 説明 |
|---------------|-------------|
|`logger`|可能であればメール送受信に関する情報を生成します。`nil`を指定するとログ出力を行わなくなります。Ruby自身の`Logger`ロガーおよび`Log4r`ロガーのどちらとも互換性があります。|
|`smtp_settings`|`:smtp`の配信メソッドの詳細設定を行います。<ul><li>`:address` - リモートメールサーバーの利用を許可する。デフォルトは`"localhost"`であり、必要に応じて変更する。</li><li>`:port` - メールサーバーが万一ポート25番で動作していない場合はここで変更する。</li><li>`:domain` - HELOドメインを指定する必要がある場合はここで行なう。</li><li>`:user_name` - メールサーバーで認証が必要な場合はここでユーザー名を指定する。</li><li>`:password` - メールサーバーで認証が必要な場合はここでパスワードを指定する。</li><li>`:authentication` - メールサーバーで認証が必要な場合はここで認証の種類を指定する。`:plain`（パスワードを平文で送信）、`:login`（パスワードをBase64でエンコードする）、`:cram_md5`（チャレンジ/レスポンスによる情報交換と、MD5アルゴリズムによる重要情報のハッシュ化の組み合わせ）のいずれかのシンボルを指定する。</li><li>`:enable_starttls_auto` - SMTPサーバーでSTARTTLSが有効かどうかを検出して有効にする。デフォルトは`true`。</li><li>`:openssl_verify_mode` - TLSを利用する場合にOpenSSLが認証をチェックする方法を指定できる。自己署名証明書やワイルドカード証明書でバリデーションを行う必要がある場合に非常に有用。OpenSSL検証定数の名前（'none'、'peer'、'client_once'、'fail_if_no_peer_cert'）を用いることも、この定数を直接用いることもできる（`OpenSSL::SSL::VERIFY_NONE`や`OpenSSL::SSL::VERIFY_PEER`など）</li></ul>|
|`sendmail_settings`|`:sendmail`配信方法のオプションを上書きします。<ul><li>`:location` - sendmailの実行可能ファイルの場所を指定する。デフォルトは`/usr/sbin/sendmail`。</li><li>`:arguments` - sendmailに渡すコマンドライン引数を指定する。デフォルトは`-i`。</li></ul>|
|`raise_delivery_errors`|メール配信に失敗した場合にエラーを発生するかどうかを指定します。このオプションは、外部のメールサーバーが即時配信を行っている場合にのみ機能します。|
|`delivery_method`|配信方法を指定します。以下の配信方法を指定可能です。<ul><li>`:smtp` (default) -- `config.action_mailer.smtp_settings`で設定可能。</li><li>`:sendmail` -- `config.action_mailer.sendmail_settings`で設定可能。</li><li>`:file`: -- メールをファイルとして保存する。`config.action_mailer.file_settings`で設定可能。</li><li>`:test`: -- メールを配列`ActionMailer::Base.deliveries`に保存する。</li></ul>詳細については[APIドキュメント](http://api.rubyonrails.org/classes/ActionMailer/Base.html)を参照。|
|`perform_deliveries`|Mailのメッセージに`deliver`メソッドを実行したときに実際にメール配信を行なうかどうかを指定します。デフォルトでは配信が行われます。機能テストなどで配信を一時的にオフにしたい場合に便利です。この値が`false`の場合、`deliveries`の配列は`delivery_method`が`:test`の場合でも用いられなくなります。|
|`deliveries`|`delivery_method :test`を用いてAction Mailerから送信されたメールの配列を保持します。単体テストおよび機能テストで最も便利です。|
|`default_options`|`mail`メソッドオプション (`:from`、`:reply_to`など)のデフォルト値を設定します。|

設定オプションの完全な説明については「Railsアプリケーションを設定する」ガイドの[Action Mailerを設定する](configuring.html#action-mailerを設定する)を参照してください。

### Action Mailerの設定例

適切な`config/environments/$RAILS_ENV.rb`ファイルに追加する設定の例を以下に示します。

```ruby
config.action_mailer.delivery_method = :sendmail
# デフォルトは以下のとおりです。
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i'
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
  enable_starttls_auto: true }
```

Note: Googleは2014年7月15日より[同社のセキュリティ対策を引き上げ](https://support.google.com/accounts/answer/6010255)、「安全性が低い」とみなされたアプリケーションからの試行をブロックするようになりました。Gmailの設定については、[ここ](https://www.google.com/settings/security/lesssecureapps)でこの試行を許可できます。利用するGmailアカウントで2要素認証が有効になっている場合は、[アプリケーションのパスワード](https://myaccount.google.com/apppasswords)を設定して通常のパスワードの代わりに使う必要があります。または、メール送信をsmtp.gmail.comから、プロバイダが提供する別のESPに置き換える方法もあります。

メイラーのテスト
--------------

メイラーのテスト方法の詳細についてはテスティングガイドの[メイラーをテストする](testing.html#メイラーをテストする)を参照してください。

メールのインターセプトとObserver
-------------------

Action Mailerは、メールのオブザーバー（observer）メソッドやインターセプタ（intercepter）メソッドを提供します。これらを用いて、送信されるあらゆるメールの配信ライフサイクル期間内に呼び出されるクラスを登録できます。

### メールをインターセプトする

インターセプタを使うと、メールが配信エージェントによって送信される前にメールを加工できます。インターセプタクラスには、メール送信前に呼び出す`:delivering_email(message)`メソッドが実装されていなければなりません。


```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

インターセプタが動作するより前に、Action Mailerフレームワークにインターセプタを登録する必要があります。これは、以下のようにイニシャライザファイル`config/initializers/sandbox_email_interceptor.rb`で行います。

```ruby
if Rails.env.staging?
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end
```

NOTE: 上の例では"staging"というカスタマイズした環境を使っています。これは本番 (production環境) に準じた状態でテストを行うための環境です。Railsのカスタム環境については[Rails環境を作成する](configuring.html#rails環境を作成する)を参照してください。

### メールのオブザーバー

オブザーバーは、メール送信後のメールメッセージへのアクセスを提供します。オブザーバークラスには、メール送信後に呼び出す`:delivering_email(message)`メソッドが実装されていなければなりません。

```ruby
class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailDelivery.log(message)
  end
end
```

インターセプタの場合と同様、オブザーバーもAction Mailerフレームワークに登録する必要があります。これは、以下のようにイニシャライザファイル`config/initializers/email_delivery_observer.rb `で行います。

```ruby
ActionMailer::Base.register_observer(EmailDeliveryObserver)
```