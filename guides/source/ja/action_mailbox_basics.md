**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

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

Action Mailboxは、受信したメールをコントローラに似たメールボックスにルーティングし、Railsで処理できるようにします。Action Mailboxは、Mailgun、Mandrill、Postmark、SendGridへの入り口（ingress）を備えています。受信メールを組み込みのEximやPostfixやQmail用のingressで直接扱うこともできます。

受信メールはActive Recordを用いて`InboundEmail`レコードになり、Active Storageによってライフサイクルトラッキングや元のメールのクラウドストレージ保存を行い、データの扱いを「on-by-default incineration（焼却）」で扱います。

受信メールはActive Jobによって非同期的に1つまたは複数の専用メールボックスにルーティングされ、ドメインモデルの他の部分と直接やりとりできます。

## セットアップ

`InboundEmail`で必要なマイグレーションをインストールし、Active Storageがセットアップ済みであることを確認します。

```bash
$ rails action_mailbox:install
$ rails db:migrate
```

## 設定

### Exim

SMTPリレーからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Action Mailboxがrelay ingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`action_mailbox.ingress_password`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でパスワードを追加します。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD`環境変数でパスワードを指定します。

Eximが受信メールを`bin/rails action_mailbox:ingress:exim`にパイプでつなぐよう設定し、relay ingressの`URL`と先ほど生成した`INGRESS_PASSWORD`を指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のような感じになります。

```bash
bin/rails action_mailbox:ingress:exim URL=https://example.com/rails/action_mailbox/relay/inbound_emails INGRESS_PASSWORD=...
```

### Mailgun

Action Mailboxに自分の[Mailgun API key](https://help.mailgun.com/hc/en-us/articles/203380100-Where-can-I-find-my-API-key-and-SMTP-credentials)を渡して、Mailgunのingressへのリクエストを認証できるようにします。

`action_mailbox.mailgun_api_key`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

```yaml
action_mailbox:
  mailgun_api_key: ...
```

または、`MAILGUN_INGRESS_API_KEY`環境変数でパスワードを指定します。

Mailgunからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :mailgun
```

受信メールを`/rails/action_mailbox/mailgun/inbound_emails/mime`に転送するよう[Mailgunを設定](https://documentation.mailgun.com/en/latest/user_manual.html#receiving-forwarding-and-storing-messages)します。アプリケーションが`https://example.com`にある場合、完全修飾済みURLを`https://example.com/rails/action_mailbox/mailgun/inbound_emails/mime`のように指定します。

### Mandrill

Action Mailboxに自分のMandrill API keyを渡して、Mandrillのingressへのリクエストを認証できるようにします。

`action_mailbox.mandrill_api_key`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

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

`action_mailbox.ingress_password`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`bin/rails action_mailbox:ingress:postfix`にルーティングするよう[Postfixを設定](https://serverfault.com/questions/258469/how-to-configure-postfix-to-pipe-all-incoming-email-to-a-script)します。アプリケーションが`https://example.com`にある場合、完全なコマンドは次のような感じになります。

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

`action_mailbox.ingress_password`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`/rails/action_mailbox/postmark/inbound_emails`に転送するよう[Postmarkのinbound webhookを設定](https://postmarkapp.com/manual#configure-your-inbound-webhook-url)します。アプリケーションが`https://example.com`にある場合、完全なコマンドは次のような感じになります。

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/postmark/inbound_emails
```

NOTE: Postmarkのinbound webhookを設定するときには、必ず**"Include raw email content in JSON payload"**というチェックボックスをオンにしてください。Action Mailboxがrawメールを処理するのに必要です。

### Qmail

SMTPリレーからのメールを受け取るようAction Mailboxに指示します。

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

Action Mailboxがrelay ingressへのリクエストを認証するのに使える強力なパスワードを生成します。

`action_mailbox.ingress_password`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`bin/rails action_mailbox:ingress:qmail`にパイプでつなぐようQmailを設定し、relay ingressの`URL`と先ほど生成した`INGRESS_PASSWORD`を指定します。アプリケーションが`https://example.com`にある場合の完全なコマンドは以下のような感じになります。

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

`action_mailbox.ingress_password`の下にあるアプリケーションの暗号化済みcredential（Action Mailboxはこのcredentialを自動的に見つけます）に`rails credentials:edit`でAPIキーを追加します。

```yaml
action_mailbox:
  ingress_password: ...
```

または、`RAILS_INBOUND_EMAIL_PASSWORD `環境変数でパスワードを指定します。

受信メールを`/rails/action_mailbox/sendgrid/inbound_emails`に転送するよう[SendGridのInbound Parseを設定](https://sendgrid.com/docs/for-developers/parsing-email/setting-up-the-inbound-parse-webhook/)します。アプリケーションが`https://example.com`にある場合、SendGridの設定に使うURLは次のような感じになります。

```
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/sendgrid/inbound_emails
```

NOTE: SendGridのInbound Parse webhookを設定するときには、必ず**“Post the raw, full MIME message”**というチェックボックスをオンにしてください。Action Mailboxがraw MIMEメッセージを処理するのに必要です。

## 例

基本的なルーティングを設定します。

```ruby
# app/mailboxes/application_mailbox.rb
class ApplicationMailbox < ActionMailbox::Base
  routing /^save@/i     => :forwards
  routing /@replies\./i => :replies
end
```

続いてメールボックスを設定します。

```ruby
# 新しいメールボックスを生成する
$ bin/rails generate mailbox forwards
```

```ruby
# app/mailboxes/forwards_mailbox.rb
class ForwardsMailbox < ApplicationMailbox
  # 処理に必要な条件をコールバックで指定する
  before_processing :require_forward

  def process
    if forwarder.buckets.one?
      record_forward
    else
      stage_forward_and_request_more_details
    end
  end

  private
    def require_forward
      unless message.forward?
        # Action Mailersを用いて受信メールを送信者に送り返す（bounce back）
        # ここで処理が停止する
        bounce_with Forwards::BounceMailer.missing_forward(
          inbound_email, forwarder: forwarder
        )
      end
    end

    def forwarder
      @forwarder ||= Person.where(email_address: mail.from)
    end

    def record_forward
      forwarder.buckets.first.record \
        Forward.new forwarder: forwarder, subject: message.subject, content: mail.content
    end

    def stage_forward_and_request_more_details
      Forwards::RoutingMailer.choose_project(mail).deliver_now
    end
end
```

## InboundEmailsの「焼却（incineration）」

デフォルトでは、処理が成功したInboundEmailは30日が経過すると焼却（incinerate）されます。これにより、アカウントをキャンセルまたはコンテンツを削除したユーザーのデータをぐずぐず保持せずに済みます。設計の意図は、メールを処理した後に必要なメールをすべて切り出してアプリケーションの業務ドメインモデルやコンテンツに取り込んでおくべきであるということです。InboundEmailは単に、デバッグや法医学的なオプションを提供する目的でシステムに余分な期間残されます。

実際のincinerationは、`config.action_mailbox.incinerate_after`でスケジュールされた時刻の後、`IncinerationJob`で行われます。この値はデフォルトで`30.days`に設定されますが、production.rbで設定を変更できます（incinerationを遠い未来にスケジューリングする場合、その間ジョブキューがジョブを保持できることが重要です）。

## Action Mailboxをdevelopment環境で使う

実際にメールを送受信せずに、development環境でメールの受信をテストできると便利です。このために、`/rails/conductor/action_mailbox/inbound_emails`に「コンダクター（conductor）」コントローラがマウントされます。これはシステム内にあるすべてのInboundEmailsのインデックスや処理の状態を提供し、新しいInboundEmailを作成できるフォームも提供します。

## メールボックスをテストする

例:

```ruby
class ForwardsMailboxTest < ActionMailbox::TestCase
  test "directly recording a client forward for a forwarder and forwardee corresponding to one project" do
    assert_difference -> { people(:david).buckets.first.recordings.count } do
      receive_inbound_email_from_mail \
        to: 'save@example.com',
        from: people(:david).email_address,
        subject: "Fwd: ステータスは更新された？",
        body: <<~BODY
          --- Begin forwarded message ---
          From: Frank Holland <frank@microsoft.com>

          現在のステータスは？
        BODY
    end

    recording = people(:david).buckets.first.recordings.last
    assert_equal people(:david), recording.creator
    assert_equal "ステータスは更新された？", recording.forward.subject
    assert_match "現在のステータスは？", recording.forward.content.to_s
  end
end
```
