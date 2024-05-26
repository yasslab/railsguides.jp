Action Mailbox の基礎
=====================

本ガイドでは、アプリケーションでメールを受信するために必要なすべての情報を提供します。

このガイドの内容:

* メールをRailsアプリケーションで受信する方法
* Action Mailboxの設定方法
* メールボックスの生成方法とメールをメールボックスにルーティングする方法
* 受信メールをテストする方法

--------------------------------------------------------------------------------


はじめに
------------

Action Mailboxは、受信したメールをコントローラに似たメールボックスにルーティングし、Railsで処理できるようにします。なお、[Action Mailer](action_mailer_basics.html)は**メール送信**のための機能です

受信したメールは[Active Job](active_job_basics.html)によって非同期で1個以上の専用メールボックスにルーティングされます。それらのメールは、さらに[Active Record](active_record_basics.html)を用いて[`InboundEmail`](https://api.rubyonrails.org/classes/ActionMailbox/InboundEmail.html)レコードに変換されます。`InboundEmail`は、ドメインモデルの他の部分と直接やりとりできるようになります。

`InboundEmail`は、ライフサイクルのトラッキング機能や、[Active Storage](active_storage_overview.html)を介したオリジナルメールの保存機能、およびデフォルトでデータの[焼却（incineration）](#incineration-of-inboundemails)を行う機能も提供します。

Action Mailboxは、Mailgun、Mandrill、Postmark、SendGridなどの外部メールプロバイダ用の入り口（ingress）を備えています。受信メールを組み込みのEximやPostfixやQmail用のingressで直接扱うことも可能です。

## セットアップ

Action Mailboxにはいくつかの可動部分があります。
最初に、インストーラを実行します。
次に、受信メールを処理するingressを選択して設定します。
これでAction Mailboxのルーティング追加やメールボックス作成を行って、受信メールの処理を開始する準備が整います。

最初に、以下を実行してAction Mailboxをインストールします。

```bash
$ bin/rails action_mailbox:install
```

これで、Action MailboxのマイグレーションとActive Storageのマイグレーションが実行されます。

Action Mailboxの`action_mailbox_inbound_emails`テーブルには、受信メッセージと処理のステータスが保存されます。

この時点で、Railsサーバを起動して`http://localhost:3000/rails/conductor/action_mailbox/inbound_emails`をチェックできるようになります。詳しくは[ローカル環境での開発とテスト](#ローカル環境での開発とテスト)を参照してください。

次のステップは、Railsアプリケーションでのメール受信方法を指定するために、受信メールを処理するingressを選択して設定します。

## ingressの設定

ingressの設定作業には、選択したメールサービスのcredentialやエンドポイント情報のセットアップ作業が関連しています。サポートされているingressごとにステップを以下に示します。

### Exim

SMTPリレーからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Action Mailboxがrelay ingressへのリクエストを認証するのに使える強力なパスワードを生成します。

パスワードを追加するには`bin/rails credentials:edit`を実行します。パスワードはアプリケーションの暗号化済みcredentialの`action_mailbox.ingress_password`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD`環境変数でパスワードを指定します。

Eximを設定して受信メールを`bin/rails action_mailbox:ingress:exim`にパイプでつなぎ、relay ingressの`URL`と先ほど生成した`INGRESS_PASSWORD`を指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のような感じになります。

```bash
bin/rails action_mailbox:ingress:exim URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### Mailgun

Action Mailboxに自分のMailgun署名キー（Signing key）を渡して、Mailgun ingressへのリクエストを認証できるようにします。

`bin/rails credentials:edit`を実行して署名キーを追加します。署名キーはアプリケーションの暗号化済みcredentialの`action_mailbox.mailgun_signing_key`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  mailgun_api_key: ...
```

または、`MAILGUN_INGRESS_SIGNING_KEY`環境変数でパスワードを指定します。

Mailgunからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :mailgun
```

受信メールを`/rails/action_mailbox/mailgun/inbound_emails/mime`に転送するよう[Mailgunを設定](https://documentation.mailgun.com/en/latest/user_manual.html#receiving-forwarding-and-storing-messages)します。たとえばアプリケーションが`https://example.com`にある場合は、完全修飾済みURLを`https://example.com/rails/action_mailbox/mailgun/inbound_emails/mime`のように指定します。

### Mandrill

Action Mailboxに自分のMandrill APIキーを渡して、Mandrillのingressへのリクエストを認証できるようにします。

`bin/rails credentials:edit`を実行してAPIキーを追加します。APIキーはアプリケーションの暗号化済みcredentialの`action_mailbox.mandrill_api_key`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  mandrill_api_key: ...
```

または、`MANDRILL_INGRESS_API_KEY`環境変数でパスワードを指定します。

Mandrillからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :mandrill
```

受信メールを`/rails/action_mailbox/mandrill/inbound_emails`にルーティングするよう[Mandrillを設定](https://mandrill.zendesk.com/hc/en-us/articles/205583197-Inbound-Email-Processing-Overview)します。アプリケーションが`https://example.com`にある場合、完全修飾済みURLを`https://example.com/rails/action_mailbox/mandrill/inbound_emails`のように指定します。

### Postfix

SMTPリレーからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Action Mailboxがrelay ingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`bin/rails credentials:edit`を実行してAPIキーを追加します。APIキーはアプリケーションの暗号化済みcredentialの`action_mailbox.ingress_password`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`bin/rails action_mailbox:ingress:postfix`にルーティングするよう[Postfixを設定](https://serverfault.com/questions/258469/how-to-configure-postfix-to-pipe-all-incoming-email-to-a-script)し、Postfix ingressの`URL`と先ほど生成した`INGRESS_PASSWORD`を指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のようになります。

```bash
$ bin/rails action_mailbox:ingress:postfix URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### Postmark

Postmarkからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :postmark
```

Action MailboxがPostmarkのingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`bin/rails credentials:edit`を実行してAPIキーを追加します。APIキーはアプリケーションの暗号化済みcredentialの`action_mailbox.ingress_password`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`/rails/action_mailbox/postmark/inbound_emails`に転送するよう[Postmarkのinbound webhookを設定](https://postmarkapp.com/manual#configure-your-inbound-webhook-url)し、ユーザー名`actionmailbox`と上で生成したパスワードを指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のようになります。

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/postmark/inbound_emails
```

NOTE: Postmarkのinbound webhookを設定するときには、必ず**"Include raw email content in JSON payload"**というチェックボックスをオンにしてください。これはAction Mailboxがメールのrawコンテンツを処理するのに必要です。

### Qmail

SMTPリレーからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Action Mailboxがrelay ingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`bin/rails credentials:edit`を実行してAPIキーを追加します。APIキーはアプリケーションの暗号化済みcredentialの`action_mailbox.ingress_password`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`bin/rails action_mailbox:ingress:qmail`にパイプでつなぐようQmailを設定し、relay ingressの`URL`と先ほど生成した`INGRESS_PASSWORD`を指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のようになります。

```bash
bin/rails action_mailbox:ingress:qmail URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### SendGrid

SendGridからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :sendgrid
```

Action MailboxがSendGridのingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`bin/rails credentials:edit`を実行してAPIキーを追加します。APIキーはアプリケーションの暗号化済みcredentialの`action_mailbox.ingress_password`の下に追加されます（Action Mailboxはこのcredentialを自動的に見つけます）。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`/rails/action_mailbox/sendgrid/inbound_emails`に転送するよう[SendGridのInbound Parseを設定](https://sendgrid.com/docs/for-developers/parsing-email/setting-up-the-inbound-parse-webhook/)し、ユーザー名`actionmailbox`と上で生成したパスワードを指定します。アプリケーションが`https://example.com`にある場合、SendGridの設定に使うURLは次のような感じになります。

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/sendgrid/inbound_emails
```

NOTE: SendGridのInbound Parse webhookを設定するときには、必ず**“Post the raw, full MIME message”**というチェックボックスをオンにしてください。これはAction Mailboxがraw MIMEメッセージを処理するのに必要です。

## 受信メールを処理する

Railsアプリケーションで受信メールを処理するには、通常、メールのコンテンツを用いてモデルを作成し、ビューを更新し、バックグラウンド作業をエンキュー（enqueue: キューに入れる）する必要があります。

受信メールの処理を開始する前に、Action Mailboxのルーティングを設定し、メールボックスを作成しておく必要があります。

### ルーティングを設定する

設定したingress経由で受信したメールをアプリケーションで実際に処理するには、メールボックスに転送する必要があります。Action Mailboxのルーティングは、[Railsのルーター](routing.html)がURLをコントローラーにディスパッチするのと同様に、どのメールがどのメールボックスに送信されて処理されるかを定義します。このルーティングは、正規表現を用いて`application_mailbox.rb`ファイルに追加されます。

```ruby
# app/mailboxes/application_mailbox.rb
class ApplicationMailbox < ActionMailbox::Base
  routing(/^save@/i     => :forwards)
  routing(/@replies\./i => :replies)
end
```

この正規表現は、受信したメールの`to`フィールド、`cc`フィールド、`bcc`フィールドのいずれかにマッチします。
たとえば、上のルーティングは、`save@`にマッチするすべてのメールを"forwards"というメールボックスに転送します。メールをルーティングする方法はいくつもあります。詳しくはAPIドキュメント[`ActionMailbox::Base`](https://api.rubyonrails.org/classes/ActionMailbox/Base.html)を参照してください。

続いて、forwards"というメールボックスを作成する必要があります。

## メールボックスを設定する

```ruby
# 新しいメールボックスを生成する
$ bin/rails generate mailbox forwards
```

上を実行すると`app/mailboxes/forwards_mailbox.rb`ファイルが作成され、そこに`ForwardsMailbox`クラスと`process`メソッドも同時に作成されます。

### メールを処理する

`InboundEmail`の処理では、`InboundEmail#mail`メソッドを利用することで、解析済みの[`Mail`](https://github.com/mikel/mail)オブジェクトを取得することも、`#source`メソッドで生のソースを直接取得することも可能です。`Mail`オブジェクトを取得すれば、`mail.to`や`mail.body.decoded`などの関連フィールドにアクセスできます。

```irb
irb> mail
=> #<Mail::Message:33780, Multipart: false, Headers: <Date: Wed, 31 Jan 2024 22:18:40 -0600>, <From: someone@hey.com>, <To: save@example.com>, <Message-ID: <65bb1ba066830_50303a70397e@Bhumis-MacBook-Pro.local.mail>>, <In-Reply-To: >, <Subject: Hello Action Mailbox>, <Mime-Version: 1.0>, <Content-Type: text/plain; charset=UTF-8>, <Content-Transfer-Encoding: 7bit>, <x-original-to: >>
irb> mail.to
=> ["save@example.com"]
irb> mail.from
=> ["someone@hey.com"]
irb> mail.date
=> Wed, 31 Jan 2024 22:18:40 -0600
irb> mail.subject
=> "Hello Action Mailbox"
irb> mail.body.decoded
=> "This is the body of the email message."
# mail.decoded, a shorthand for mail.body.decoded, also works
irb> mail.decoded
=> "This is the body of the email message."
irb> mail.body
=> <Mail::Body:0x00007fc74cbf46c0 @boundary=nil, @preamble=nil, @epilogue=nil, @charset="US-ASCII", @part_sort_order=["text/plain", "text/enriched", "text/html", "multipart/alternative"], @parts=[], @raw_source="This is the body of the email message.", @ascii_only=true, @encoding="7bit">
```

### 受信メールのステータス

メールにマッチするメールボックスにメールがルーティングされて処理されている間、Action Mailboxは `action_mailbox_inbound_emails`テーブルに保存されているメールのステータスを次のいずれかの値で更新します。

- `pending`: ingressコントローラの1つがメールを受信完了して、ルーティングがスケジュールされている状態。
- `processing`: アクティブな処理内で、特定のメールボックスがその`process`メソッドを実行中の状態。
- `delivered`: メールが特定のメールボックスによって正常に処理完了した状態。
- `failed`: 特定のメールボックスの`process`メソッドの実行中に例外が発生したことを表す。
- `bounced`: 特定のメールボックスでメールの処理が拒否され、送信者にバウンス（bounce: ）された状態。

メールのステータスが`delivered`、`failed`、`bounced`のいずれかになった場合、そのメールは「処理完了」とみなされ、[焼却](#InboundEmailsの「焼却」)とマーキングされます。

## 例

Action Mailboxでメールを処理してプロジェクトの"forwards"を作成するアクションの例を次に示します。。

`before_processing`コールバックは、`process`メソッドが呼び出される前に特定の条件が確実に満たされるようにする目的で使います。`before_processing`は、ユーザーに少なくとも1個のプロジェクトが存在することをチェックします。[Action Mailboxのコールバック](https://api.rubyonrails.org/classes/ActionMailbox/Callbacks.html)
では、この他に`after_processing`と`around_processing`もサポートされています。

"forwarder"にプロジェクトが1個もない場合は、`bounced_with`でメールをバウンスできます。
この"forwarder"は、`mail.from`と同じメールアドレスを持つ`User`です。

"forwarder"にプロジェクトが1個以上ある場合は、`record_forward`メソッドでアプリケーションのActive Recordモデルを作成し、そのモデルにはメールの`mail.subject`と`mail.decoded`データが含まれます。それ以外の場合はAction Mailerでメールを送信して、何らかのプロジェクトを"forwarder"で選択するようリクエストします。

```ruby
# app/mailboxes/forwards_mailbox.rb
class ForwardsMailbox < ApplicationMailbox
  # 処理に必要な条件をコールバックで指定する
  before_processing :require_projects

  def process
    # 転送を1個のプロジェクトに記録する、または…
    if forwarder.projects.one?
      record_forward
    else
      # …2番目のAction Mailerに転送先プロジェクトを問い合わせてもらう
      request_forwarding_project
    end
  end

  private
    def require_projects
      if forwarder.projects.none?
        # Action Mailersを用いて受信メールを送信者に送り返す（bounce back）
        # ここで処理が停止する
        bounce_with Forwards::BounceMailer.no_projects(inbound_email, forwarder: forwarder)
      end
    end

    def record_forward
      forwarder.forwards.create subject: mail.subject, content: mail.decoded
    end

    def request_forwarding_project
      Forwards::RoutingMailer.choose_project(inbound_email, forwarder: forwarder).deliver_now
    end

    def forwarder
      @forwarder ||= User.find_by(email_address: mail.from)
    end
end
```

## ローカル環境での開発とテスト

development環境では、実際にメールを送受信せずにメールの受信をテストできると便利です。このために、`/rails/conductor/action_mailbox/inbound_emails`にコンダクター（conductor）コントローラがマウントされます。コンダクターコントローラは、システム内にあるすべてのInboundEmailsのインデックスや処理のステートを提供し、新しいInboundEmailを作成するときのフォームも提供します。

以下は、Action MailboxのTestHelpersを利用して受信メールをテストするコード例です。

```ruby
class ForwardsMailboxTest < ActionMailbox::TestCase
  test "directly recording a client forward for a forwarder and forwardee corresponding to one project" do
    assert_difference -> { people(:david).buckets.first.recordings.count } do
      receive_inbound_email_from_mail \
        to: 'save@example.com',
        from: people(:david).email_address,
        subject: "Fwd: ステータスは更新されたか？",
        body: <<~BODY
          --- Begin forwarded message ---
          From: Frank Holland <frank@microsoft.com>

          現在のステータスは？
        BODY
    end

    recording = people(:david).buckets.first.recordings.last
    assert_equal people(:david), recording.creator
    assert_equal "Status update?", recording.forward.subject
    assert_match "What's the status?", recording.forward.content.to_s
  end
end
```

テストヘルパーメソッドについて詳しくは、APIドキュメントの[`ActionMailbox::TestHelper`](https://api.rubyonrails.org/classes/ActionMailbox/TestHelper.html)を参照してください。

## InboundEmailsの「焼却」

デフォルトでは、処理が成功したInboundEmailは30日後に焼却（incinerate）されます。これにより、アカウントをキャンセルまたはコンテンツを削除したユーザーのデータをむやみに保持せずに済みます。この設計では、メールを処理した後に必要なメールをすべて切り出して、アプリケーションの業務ドメインモデルやコンテンツに取り込む必要があることが前提となります。InboundEmailがシステムに余分に保持される期間は、単にデバッグや事後調査のためのものです。

実際のincinerationは、[`config.action_mailbox.incinerate_after`][]でスケジュールされた時刻の後、[`IncinerationJob`][]で行われます。この値はデフォルトで`30.days`に設定されますが、production.rbで設定を変更できます（incinerationを遠い未来にスケジューリングする場合、その間ジョブキューがジョブを保持可能になっていることが重要です）。

[`config.action_mailbox.incinerate_after`]: configuring.html#config-action-mailbox-incinerate-after
[`IncinerationJob`]: https://api.rubyonrails.org/classes/ActionMailbox/IncinerationJob.html
