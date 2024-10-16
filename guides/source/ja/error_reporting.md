Rails アプリケーションのエラー通知
========================

このガイドは、Ruby on Railsアプリケーションで発生するエラーの管理方法を解説します。

本ガイドの内容:

* Railsの`ErrorReporter`でエラーをキャプチャして通知する方法
* エラー通知サービス用のカスタムサブスクライバの作成方法

--------------------------------------------------------------------------------

エラー通知
------------------------

Railsの[`ErrorReporter`][]は、アプリケーションで発生したエラーを収集して、好みのサービスや場所に通知する標準的な方法を提供します（例: Sentryなどの監視サービスに通知する）。

この機能の目的は、以下のような定型的なエラー処理コードを置き換えることです。

```ruby
begin
  do_something
rescue SomethingIsBroken => error
  MyErrorReportingService.notify(error)
end
```

上の定形コードを、以下のようなインターフェイスで統一できます。

```ruby
Rails.error.handle(SomethingIsBroken) do
  do_something
end
```

Railsはすべての実行（HTTPリクエスト、[ジョブ](active_job_basics.html)、[`rails runner`](command_line.html#bin-rails-runner)の起動など）を`ErrorReporter`にラップするので、アプリで発生した未処理のエラーは、そのサブスクライバを介してエラーレポートサービスに自動的に通知されます。

これにより、サードパーティのエラー通知ライブラリは、[Rack](rails_on_rack.html)ミドルウェアを挿入したり、未処理の例外をキャプチャするパッチを適用したりする必要がなくなります。また、[Active Support](https://api.rubyonrails.org/classes/ActiveSupport.html)を使うライブラリがこの機能を利用して、従来ログに出力されなかった警告を、コードに手を加えずに通知できるようになります。

[`ErrorReporter`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html

NOTE: このエラーレポーターの利用は必須ではありません。エラーをキャプチャする他の手法はすべて引き続き利用できます。

### エラーレポーターにサブスクライブする

エラーレポーターを利用するには**サブスクライバ**（subscriber）が必要です。サブスクライバは、`report`メソッドを持つ任意のオブジェクトのことです。アプリケーションでエラーが発生したり、手動で通知されたりすると、Railsのエラーレポーターはエラーオブジェクトといくつかのオプションを使ってこのメソッドを呼び出します。

NOTE: SentryやHoneybadgerなどのように、自動的にサブスクライバを登録してくれるエラー通知ライブラリもあります。

また、以下のようにカスタムサブスクライバを作成することも可能です。

```ruby
# config/initializers/error_subscriber.rb
class ErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    MyErrorReportingService.report_error(error, context: context, handled: handled, level: severity)
  end
end
```

Subscriberクラスを定義したら、[`Rails.error.subscribe`][]メソッドを呼び出して登録します。

```ruby
Rails.error.subscribe(ErrorSubscriber.new)
```

サブスクライバはいくつでも登録できます。Railsはサブスクライバを登録順に呼び出します。

[`Rails.error.unsubscribe`][]を呼び出すことで、サブスクライバを登録解除することも可能です。これは、依存関係で追加されたサブスクライバを置換・削除する場合に便利です。`subscribe`と`unsubscribe`には、サブスクライバを渡すことも、サブスクライバのクラスを渡すことも可能です。

```ruby
subscriber = ErrorSubscriber.new
Rails.error.unsubscribe(subscriber)
# or
Rails.error.unsubscribe(ErrorSubscriber)
```

NOTE: Railsのエラーレポーターは、どの環境でも常に登録されたサブスクライバーを呼び出します。しかし多くのエラー通知サービスは、デフォルトではproduction環境でのみエラーを通知します。必要に応じて、複数の環境で設定を行ってテストする必要があります。

[`Rails.error.subscribe`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-subscribe
[`Rails.error.unsubscribe`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-unsubscribe

### エラーレポーターを利用する

Railsのエラーレポーターには、エラー通知用の4つのメソッドがあります。

* `Rails.error.handle`
* `Rails.error.record`
* `Rails.error.report`
* `Rails.error.unexpected`

#### エラーを通知して握りつぶす

[`Rails.error.handle`][] は、ブロック内で発生したエラーを通知してから、そのエラーを**握りつぶします**。ブロックの外の残りのコードは通常通り続行されます。

```ruby
result = Rails.error.handle do
  1 + '1' # TypeErrorが発生
end
result # => nil
1 + 1 # ここは実行される
```

ブロック内でエラーが発生しなかった場合、`Rails.error.handle`はブロックの結果を返し、エラーが発生した場合は`nil`を返します。

以下のように`fallback`を指定することで、この振る舞いをオーバーライドできます。

```ruby
user = Rails.error.handle(fallback: -> { User.anonymous }) do
  User.find_by(params[:id])
end
```

[`Rails.error.handle`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-handle

#### エラーを通知して再度raiseする

[`Rails.error.record`][] はすべての登録済みレポーターにエラーを通知し、その後エラーを再度raiseします。残りのコードは実行されません。

```ruby
Rails.error.record do
1 + '1' # TypeErrorが発生
end
1 + 1 # ここは実行されない
```

ブロック内でエラーが発生しなかった場合、`Rails.error.record`はそのブロックの結果を返します。

[`Rails.error.record`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-record

#### エラーを手動で通知する

[`Rails.error.report`][]を呼び出して手動でエラーを通知することも可能です。

```ruby
begin
  # code
rescue StandardError => e
  Rails.error.report(e)
end
```

渡したオプションは、すべてエラーサブスクライバに渡されます。

[`Rails.error.report`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-report

#### 想定外のエラーを報告する

[`Rails.error.unexpected`][]を呼び出すことで、想定外のエラーを報告できます。

production環境で呼び出された場合、このメソッドはエラーが報告された後に`nil`を返し、コードの実行を中断せずに続行します。

development環境で呼び出された場合、エラーは新しいエラークラスにラップされ（スタックの上位層で`rescue`されないようにするため）、開発者にデバッグ情報が表示されます。例:

```ruby
def edit
  if published?
    Rails.error.unexpected("[BUG] Attempting to edit a published article, that shouldn't be possible")
    false
  end
  # ...
end
```

NOTE: このメソッドは、production環境で発生する可能性があるが、通常の利用結果では発生することが想定されていないエラーを適切に処理することを目的としています。

[`Rails.error.unexpected`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-unexpected"

### エラー通知のオプション

3つのレポートAPI（`#handle`、`#record`、`#report`）はすべて以下のオプションをサポートしています。これらのオプションは、すべての登録済みサブスクライバに渡されます。

- `handled`: エラーが処理されたかどうかを示す`Boolean`。
  デフォルトは`true`です（ただし`#record`のデフォルトは`false`です）。

- `severity`: エラーの重大性を表す`Symbol`。
  期待される値は`:error`、`:warning`、`:info`のいずれか。
  `#handle`では`:warning`に設定されます。
  `#record`では`:error`に設定されます。

- `context`: リクエストやユーザーの詳細など、エラーに関する詳細なコンテキストを提供する`Hash`。

- `source`: エラーの発生源に関する`String`。
  デフォルトのソースは`"application"`です。
  内部ライブラリから通知されたエラーは他のソースを設定する可能性があります（例: Redisキャッシュライブラリは`"redis_cache_store.active_support"`を設定する可能性があります）。
  サブスクライバは、このソースを利用することで興味のないエラーを無視できます。

```ruby
Rails.error.handle(context: { user_id: user.id }, severity: :info) do
  # ...
end
```

### コンテキストをグローバルに設定する

コンテキストは、`context`オプションで設定することも、以下のように[`#set_context`][] APIで設定することもできます。

```ruby
Rails.error.set_context(section: "checkout", user_id: @user.id)
```

この方法で設定されたコンテキストは、`context`オプションとマージされます。

```ruby
Rails.error.set_context(a: 1)
Rails.error.handle(context: { b: 2 }) { raise }
# 通知されるコンテキスト: {:a=>1, :b=>2}
Rails.error.handle(context: { b: 3 }) { raise }
# 通知されるコンテキスト: {:a=>1, :b=>3}
```

[`#set_context`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-set_context

### エラークラスでフィルタリングする

`Rails.error.handle`や`Rails.error.record`では、以下のように特定のクラスのエラーだけを通知できます。

```ruby
Rails.error.handle(IOError) do
  1 + '1' # TypeErrorが発生
end
1 + 1 # TypeErrorsはIOErrorsではないので、ここは「実行されない」
```

上の`TypeError`はRailsのエラー通知レポーターにキャプチャされません。通知されるのは `IOError`およびその子孫インスタンスだけです。その他のエラーは通常どおりraiseします。

### 通知を無効にする

[`Rails.error.disable`](https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-disable)を呼び出すことで、ブロック内でサブスクライバにエラーが通知されないようにできます。`subscribe`や`unsubscribe`の場合と同様に、サブスクライバ自身を渡すことも、サブスクライバのクラスを渡すことも可能です。

```ruby
Rails.error.disable(ErrorSubscriber) do
  1 + '1' # TypeErrorはErrorSubscriber経由で報告されなくなる
end
```

NOTE: これは、サードパーティのエラー通知サービスでエラーを別の方法で処理したい場合や、技術スタックの上位で処理したい場合にも有用です。

[`Rails.error.disable`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-disable

### ライブラリで利用する

エラー通知ライブラリは、以下のように[Railtie](https://api.rubyonrails.org/classes/Rails/Railtie.html)でライブラリのサブスクライバを登録できます。

```ruby
module MySdk
  class Railtie < ::Rails::Railtie
    initializer "my_sdk.error_subscribe" do
      Rails.error.subscribe(MyErrorSubscriber.new)
    end
  end
end
```

NOTE: エラーサブスクライバを登録すると、Rackミドルウェアのような他のエラー機構がある場合、エラーが繰り返し通知される可能性があります。他のエラー機構を削除するか、レポーターの機能を調整して、通知済みの例外を通知しないようにする必要があります。
