Active Job の基礎
=================

本ガイドでは、バックグラウンドで実行するジョブの作成、キューへの登録（enqueue: エンキュー）、実行方法について解説します。

このガイドの内容:

* ジョブの作成とキューへの登録方法
* Solid Queueの設定と利用方法
* バックグラウンドでのジョブ実行方法
* アプリケーションから非同期にメールを送信する方法

--------------------------------------------------------------------------------

Active Jobについて
------------

RailsのActive Jobフレームワークを利用すると、バックグラウンドジョブを定義して、キューイングバックエンド上で実行できます。メール送信、データ処理、定期的なメンテナンス作業などの一般的な非同期タスクに、高レベルな統一インターフェースを提供します。

バックグラウンドジョブの目的は、処理に時間がかかるタスクや即時性が求められないタスクをHTTPリクエスト/レスポンスのサイクルから切り離して、バックグラウンドキュー（デフォルトのSolid Queueなど）へ移行させることで、Webリクエストの処理を高速・軽快に保つことです。
アプリケーションでこうした処理を分離することで、タスクを非同期に実行することも、バックグラウンド処理を独立して大規模化することも、ユーザー操作を妨げずに複数のタスクを並列処理することも可能になります。

ジョブを作成する
--------------

本セクションでは、ジョブ用のRubyクラスを定義して`perform_*`メソッドでバックグラウンド実行する処理をキューに登録（enqueue: エンキュー）する方法を、手順を追って説明します。

### ジョブを定義する

Active Jobは、ジョブ作成用のRailsジェネレータを提供しています。以下を実行すると、`app/jobs/`ディレクトリの下にジョブが1件作成されます（テストファイルは`test/jobs/`ディレクトリの下に作成されます）。

```bash
$ bin/rails generate job guests_cleanup
invoke  test_unit
create    test/jobs/guests_cleanup_job_test.rb
create  app/jobs/guests_cleanup_job.rb
```

ジェネレータを使いたくない場合は、`app/jobs/`ディレクトリの下に自分でジョブファイルを定義できます。そのジョブファイルで`ApplicationJob`クラスを継承します。

作成されたジョブは以下のようになります。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*guests)
    # 後で実行するタスクをここに置く
  end
end
```

ジョブクラス内の`perform`メソッドには、引数をいくつでも定義できます。

アプリケーションで`ApplicationJob`以外の抽象ジョブ基底クラスを独自に使っている場合は、ジェネレータの`--parent`オプションを利用できます。このオプションで指定する親クラスは`ApplicationJob`を継承している必要があります。これは、関連する機能を一箇所にまとめる際に役立ちます。

たとえば、以下のように[`queue_as`][]を使うカスタム抽象クラスを作成したとします。

```ruby
class PaymentJob < ApplicationJob
  queue_as :payments
end
```

以下のコマンドで、この`PaymentJob`クラスを継承する新しいジョブを作成できます。

```bash
$ bin/rails generate job process_payment --parent=payment_job
```

`payments`キューを使う以下のジョブクラスを作成できます。

```ruby
class ProcessPaymentJob < PaymentJob
  def perform(*args)
    # 後で"payments"キューを用いて何かを処理する
  end
end
```

### `perform_*`メソッドを呼び出す

ジョブクラスを作成して`perform`メソッドを定義したら、通常は、キューイングバックエンドで実行するジョブを[`perform_later`][]メソッドでジョブキューに登録します。ジョブをキューに登録せずに直ちに実行したい場合は、[`perform_now`][]メソッドを使います。どちらのメソッドも、内部で`perform`メソッドを呼び出します。

以下の例にあるメソッドは、Railsアプリケーション内のどこからでも呼び出せますが、一般的にはコントローラ、モデル、または他のジョブから呼び出します。

```ruby
# ジョブをキューに登録せずに即座に実行する
GuestsCleanupJob.perform_now(guest)

# ジョブをキューに登録して後で実行する
GuestsCleanupJob.perform_later(guest)
```

ジョブを実行するタイミングを正確に指定するには、[`set`][]メソッドを使います。

```ruby
# 明日正午に実行したいジョブをキューに登録する
GuestsCleanupJob.set(wait_until: Date.tomorrow.noon).perform_later(guest)

# 一週間後に実行したいジョブをキューに登録する
GuestsCleanupJob.set(wait: 1.week).perform_later(guest)
```

`perform_now`や`perform_later`に渡した引数は`perform`に転送されるので、キーワード引数を含め、`perform`で定義された通りの引数をいくつでも渡せます。

```ruby
GuestsCleanupJob.perform_later(guest1, guest2, filter: "some_filter")
```

#### 例: メール送信

ユーザーへのメール送信は、現代のWebアプリケーションでごく一般的な処理のひとつです。Active Jobを使えば、メール送信をリクエスト/レスポンスのサイクルから切り離せるので、ユーザーはメール送信の完了を待たずに済みます。Active JobはAction Mailerと統合されているので、メールを手軽に非同期送信できます。

```ruby
# メールを即時送信したい場合は #deliver_now を使う
UserMailer.welcome(@user).deliver_now

# メールを後で非同期送信したい場合は、#deliver_later を使う
UserMailer.welcome(@user).deliver_later
```

`deliver_now`や`deliver_later`メソッドは、Action Mailerにおける`perform_now`や`perform_later`に相当するメソッドです。`deliver_later`は、内部的にはRails標準のActive Jobである`ActionMailer::MailDeliveryJob`をキューに登録する形で動作します。登録されたジョブは、ユーザーが独自に定義したジョブと同様のキューイングパイプラインを経由し、最終的にJobクラスの`perform`メソッドを呼び出します。

[`perform_now`]:
    https://api.rubyonrails.org/classes/ActiveJob/Execution.html#method-i-perform_now
[`perform_later`]:
 https://api.rubyonrails.org/classes/ActiveJob/Enqueuing/ClassMethods.html#method-i-perform_later
[`set`]:
    https://api.rubyonrails.org/classes/ActiveJob/Core/ClassMethods.html#method-i-set

### 引数でサポートされる型

Active Jobの引数では、デフォルトで以下の型をサポートします。

  - 基本型（`NilClass`、`String`、`Integer`、`Float`、`BigDecimal`、`TrueClass`、`FalseClass`）
  - `Symbol`
  - `Date`
  - `Time`
  - `DateTime`
  - `ActiveSupport::TimeWithZone`
  - `ActiveSupport::Duration`
  - `Hash`（キーの型は`String`か`Symbol`にすること）
  - `ActiveSupport::HashWithIndifferentAccess`
  - `Array`
  - `Range`
  - `Module`
  - `Class`

Active Jobでは[GlobalID][]が引数としてサポートされています。
GlobalIDを使えば、動作中のActive Recordオブジェクトをジョブに渡す際にクラスとidを指定する必要がなくなります。クラスとidを指定する従来の方法では、後で明示的にデシリアライズ（deserialize）する必要がありました。

従来のジョブが以下のようなものだったとします。

```ruby
class GuestsCleanupJob < ApplicationJob
  def perform(guests_class, guests_id, depth)
    guests = guests_class.constantize.find(guests_id)
    guest.cleanup(depth)
  end
end
```

GlobalIDを使うと以下のようにシンプルに書けます。

```ruby
class GuestsCleanupJob < ApplicationJob
  def perform(guest, depth)
    guest.cleanup(depth)
  end
end
```

このコードは、`GlobalID::Identification`をミックスインするすべてのクラスで動作します。このモジュールはActive Recordクラスにデフォルトでミックスインされます。

[GlobalID]:
  https://github.com/rails/globalid/blob/main/README.md

#### シリアライザを定義してカスタム型を追加する

カスタム型用のシリアライザを定義することで、サポートされる引数の型のリストを拡張できます。シリアライザには、`serialize`、`deserialize`、`klass`という3つのメソッドが必要です。

`serialize`メソッドは、サポートされている型だけを用いて、オブジェクトをより単純な表現に変換します。推奨される方法は、以下のように文字列をキーとするHashを渡して`super`を呼び出し、Active Jobにシリアライザの型情報をマージさせる方法です。

```ruby
# app/serializers/money_serializer.rb
class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(money)
    super(
      "amount" => money.amount,
      "currency" => money.currency
    )
  end

  def deserialize(hash)
    Money.new(hash["amount"], hash["currency"])
  end

  def klass
    Money
  end
end
```

`deserialize`メソッドは、そのハッシュを受け取り、元のオブジェクトを復元します。
`klass`メソッドは、このシリアライザが扱うクラスを返します。
これにより、Active Jobは特定の引数に対してどのシリアライザを適用すべきかを判断できるようになります。

定義したシリアライザは、Railsが認識するシリアライザのリストに追加する必要があります。

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

カスタムActive Jobシリアライザは、アプリケーションの初期化時に登録されることと、プロセスの持続期間を通じて安定して存在し続けることが想定されています。そのため、再読み込み可能なオートロード機能でのシリアライザ登録はサポートされていません。

シリアライザが一度だけ読み込まれるようにするには（development環境での再読み込みを防ぐため）、`autoload_once_paths`に含まれるディレクトリ（以下のような場所）に配置してください。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

ジョブをキューに登録する
--------------

### キュー名を指定する

Active Jobの[`queue_as`][]を使うと、特定のキュー名を指定してジョブをスケジューリングできます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end
```

ジェネレータを使う場合は、以下のように`--queue`オプションを指定して、特定のキューで実行されるジョブファイルを生成することも可能です。

```bash
$ bin/rails generate job guests_cleanup --queue low_priority
```

以下のように[`config.active_job.queue_name_prefix`][]を`application.rb`で設定すると、すべてのジョブで特定の文字列をキュー名の前に追加（プレフィックス）できます。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end
```

```ruby
# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end
```

これで、ジョブはproduction環境では`production_low_priority`キューで、staging環境では`staging_low_priority`キューで実行されるようになります。

プレフィックスをジョブ単位で設定することも可能です。

```ruby
# グローバルなプレフィックスを上書きして、このジョブのキュー名にプレフィックスが付かないようにする
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  self.queue_name_prefix = nil
  # ...
end
```

キュー名のプレフィックスのデフォルト区切り文字はアンダースコア`_`です。
この区切り文字は、`application.rb`の[`config.active_job.queue_name_delimiter`][]設定で変更できます。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = "."
  end
end
```

```ruby
# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end
```

これでキュー名は`production.low_priority`または`staging.low_priority`になります。

キュー名をジョブごとに変更するには、`queue_as`にブロックを渡します。このブロックはジョブのコンテキストで実行され（そのため`self.arguments`にアクセスできます）、戻り値はキュー名でなければなりません。

```ruby
class ProcessVideoJob < ApplicationJob
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # 動画を処理する
  end
end
```

```ruby
last_video = Video.last
ProcessVideoJob.perform_later(last_video)
```

ジョブを実行するキュー名をより細かく制御したい場合は、`set`メソッドに`:queue`オプションを渡せます。

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

TIP: キューに名前を与えるときに、レイテンシ（待ち時間）を基準にするという方法も考えられます。たとえば、「critical」「default」「low」といった名前の代わりに、「within_30_seconds」（30秒以内）、「within_5_minutes」（5分以内）、「within_1_hour」（1時間以内）といった名前を付けられます。特定のキューでジョブが規定時間を超えて滞留した場合にエンジニアリングチームへ通知するようキューイングバックエンドを設定すれば、この命名を一種の契約のように徹底できます。

NOTE: [Solid Queue以外のキューイングバックエンド](#代替キューイングバックエンド)を使う場合は、リッスンするキュー名を指定する必要が生じることもあります。

[`config.active_job.queue_name_delimiter`]:
    configuring.html#config-active-job-queue-name-delimiter
[`config.active_job.queue_name_prefix`]:
    configuring.html#config-active-job-queue-name-prefix
[`queue_as`]:
    https://api.rubyonrails.org/classes/ActiveJob/QueueName/ClassMethods.html#method-i-queue_as

### キューの優先度

優先度（priority）を指定してジョブをスケジューリングするには、[`queue_with_priority`][]メソッドを使います。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_with_priority 10
  # ...
end
```

デフォルトのキューイングバックエンドであるSolid Queueは、[キューの順序](#キューの順序)に基づいてジョブの優先順位を決定します。Solid Queueでキューの順序と優先度オプションを両方使っている場合は、キューの順序が優先され、優先度オプションは各キューの内部でのみ適用されます。

Solid Queue以外のキューイングバックエンドでは、ジョブを同じキュー内や複数のキュー間の他のジョブと比較する形で優先度を指定できる場合があります。詳しくは、利用するバックエンドのドキュメントを参照してください。

以下のように`queue_with_priority`にブロックを渡すことで、`queue_as`の場合と同様にブロックをジョブコンテキストで評価することも可能です。

```ruby
class ProcessVideoJob < ApplicationJob
  queue_with_priority do
    video = self.arguments.first
    if video.owner.premium?
      0
    else
      10
    end
  end

  def perform(video)
    # 動画を処理する
  end
end
```

```ruby
last_video = Video.last
ProcessVideoJob.perform_later(last_video)
```

以下のように`set`メソッドに`:priority`オプションを渡すことも可能です。

```ruby
MyJob.set(priority: 50).perform_later(record)
```

NOTE: 優先度の数値が小さいジョブが、数値の大きいジョブよりも先に実行されるか後に実行されるかは、アダプタの実装によって異なります。詳しくは、利用しているバックエンドのドキュメントを参照してください。アダプタの作成者は、「番号が小さいほど重要度が高い」という慣例に沿うことが推奨されます。

[`queue_with_priority`]:
    https://api.rubyonrails.org/classes/ActiveJob/QueuePriority/ClassMethods.html#method-i-queue_with_priority

### 複数のジョブを一括登録する

[`perform_all_later`][]を使うことで、複数のジョブをキューに一括登録（bulk enqueue: バルクエンキュー）できます。一括登録により、Redisやデータベースなどのキューデータストアとの通信の往復回数を減らせるので、同じジョブを個別に登録するよりもパフォーマンスが向上します。

`perform_all_later`メソッドは、インスタンス化されたジョブを引数として受け取り（引数が`perform_later`と異なる点に注意）、内部で`perform`を呼び出します。ジョブのインスタンスを生成するときに`new`へ渡された引数は、最終的に`perform`が呼び出されるときにそのまま`perform`へ渡されます。

```ruby
# `perform_all_later`に渡すジョブを作成する
# この`new`に渡した引数は`perform`に渡される
cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest) }

# `GuestsCleanupJob`の個別のインスタンスごとにジョブをキューに登録する
ActiveJob.perform_all_later(cleanup_jobs)

# `set`メソッドでオプションを設定してからジョブを一括登録してもよい
cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest).set(wait: 1.day) }

ActiveJob.perform_all_later(cleanup_jobs)
```

`perform_all_later`を呼び出すと、正常にエンキューされたジョブの個数をログ出力します。
たとえば、上の`Guest.all.map`の結果`cleanup_jobs`が3個になった場合、`Enqueued 3 jobs to Async (3 GuestsCleanupJob)`とログ出力されます（エンキューがすべて成功した場合）。

`perform_all_later`の戻り値は`nil`です。これは、`perform_later`の戻り値が、エンキューされたジョブクラスのインスタンスであるのと異なる点にご注意ください。

[`perform_all_later`]:
  https://api.rubyonrails.org/classes/ActiveJob.html#method-c-perform_all_later

#### 複数のActive Jobクラスをキューに登録する

`perform_all_later`を使えば、同じ呼び出しでさまざまなActive Jobクラスのインスタンスを以下のようにエンキューすることも可能です。

```ruby
class ExportDataJob < ApplicationJob
  def perform(*args)
    # データをエクスポートする
  end
end

class NotifyGuestsJob < ApplicationJob
  def perform(*guests)
    # ゲストにメールを送信する
  end
end

# ジョブインスタンスをインスタンス化する
cleanup_job = GuestsCleanupJob.new(guest)
export_job = ExportDataJob.new(data)
notify_job = NotifyGuestsJob.new(guest)

# さまざまなクラスのジョブインスタンスをまとめてキューに登録する
ActiveJob.perform_all_later(cleanup_job, export_job, notify_job)
```

#### 一括登録のコールバック

`perform_all_later`でジョブをキューに一括登録すると、個別のジョブでは`around_enqueue`などのコールバックがトリガーされません。この振る舞いは、Active Recordの他の一括処理系メソッドと一貫しています。コールバックは個別のジョブに対して個々に実行されるので、`perform_all_later`メソッドが持つ一括処理の性質の恩恵を受けられません。

ただし、`perform_all_later`メソッドは、`ActiveSupport::Notifications`でサブスクライブできる[`enqueue_all.active_job`][]イベントをトリガーします。

ジョブのキュー登録が成功したかどうかを知るには、[`successfully_enqueued?`][]メソッドを利用できます。

[`enqueue_all.active_job`]:
  active_support_instrumentation.html#enqueue-all-active-job
[`successfully_enqueued?`]:
  https://api.rubyonrails.org/classes/ActiveJob/Core.html#method-i-successfully_enqueued-3F

#### キューバックエンドのサポート

`perform_all_later`によるキューへの一括登録（バルクエンキュー）は、キューバックエンド側でのサポートが必要です。デフォルトのキューバックエンドであるSolid Queueは、`enqueue_all`で一括登録をサポートします。

Sidekiqなどの[他のバックエンド](#代替キューイングバックエンド)には`push_bulk`メソッドがあります。Sidekiqアダプタはこれを内部で利用して大量のジョブをRedisにプッシュし、ネットワークのラウンドトリップ遅延を防いでいます。GoodJobも`GoodJob::Bulk.enqueue`メソッドで一括登録をサポートします。

キューへの一括登録がキューバックエンドでサポートされて「いない」場合、`perform_all_later`はジョブを1件ずつキューに登録します。

コールバック
---------

Active Jobが提供するフックを用いて、ジョブのライフサイクル中にロジックをトリガーできます。これらのコールバックは、Railsの他のコールバックと同様に通常のメソッドとして実装し、クラスレベルのメソッドでコールバックとして登録できます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  around_perform :around_cleanup

  def perform
    # 後で実行するタスクをここに置く
  end

  private
    def around_cleanup
      # performの直前に何か実行
      yield
      # performの直後に何か実行
    end
end
```

このクラスレベルのメソッドは、ブロックも受け取れます。ブロック内のコード量が1行以内に収まるほど少ない場合は、この書き方が適しています。
たとえば、登録されたジョブごとの測定値を送信する場合は次のようにします。

```ruby
class ApplicationJob < ActiveJob::Base
  before_enqueue { |job| Rails.logger.info "Enqueuing #{job.class.name}" }
end
```

### 利用できるコールバック

Active Jobではさまざまなコールバックがサポートされています。

* [`before_enqueue`][]: ジョブがキューに登録される直前に実行されます。
* [`around_enqueue`][]: キュー登録処理をラップし、キュー登録の直前と直後にロジックを実行します。
* [`after_enqueue`][]: ジョブがキューに登録された直後に実行されます。

利用例:

```ruby
class GuestsCleanupJob < ApplicationJob
  before_enqueue { |job| Rails.logger.info "About to enqueue #{job.class.name}" }
  around_enqueue { |job, block| block.call }
  after_enqueue  { |job| Rails.logger.info "Successfully enqueued #{job.class.name}" }
end
```

* [`before_perform`][]: ジョブが実行される直前に実行されます。
* [`around_perform`][]: ジョブの実行処理をラップし、実行の直前と直後にロジックを実行します。
* [`after_perform`][]: ジョブが実行された直後に実行されます。

利用例:

```ruby
class GuestsCleanupJob < ApplicationJob
  before_perform { |job| Rails.logger.info "About to perform #{job.class.name}" }
  around_perform { |job, block| block.call }
  after_perform  { |job| Rails.logger.info "#{job.class.name} performed successfully" }
end
```

最後に、[`after_discard`][]コールバックは、未処理の例外によってジョブが破棄されたときに実行されます。

```ruby
class GuestsCleanupJob < ApplicationJob
  after_discard { |job, exception| Rails.logger.error "#{job.class.name} discarded: #{exception.message}" }
end
```

ジョブを`perform_all_later`で一括登録する場合、個々のジョブに対して`around_enqueue`などのコールバックは実行されない点にご注意ください。詳しくは[一括登録のコールバック](#一括登録のコールバック)を参照してください。

[`before_enqueue`]:
 https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-before_enqueue
[`around_enqueue`]:
https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-around_enqueue
[`after_enqueue`]:
    https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-after_enqueue
[`before_perform`]:
https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-before_perform
[`around_perform`]:
https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-around_perform
[`after_perform`]:
https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-after_perform
[`after_discard`]:
https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-after_discard

### コールバックを停止させる

`:abort`をスローすることで、コールバックチェインを停止できます。これは、Active Recordやその他のRailsコールバックと同様に動作します。たとえば、条件に基づいてジョブがエンキューされるのを阻止するには、以下のように書きます。

```ruby
class GuestsCleanupJob < ApplicationJob
  before_enqueue do |job|
    throw :abort if ENV.fetch("DISABLE_GUESTS_CLEANUP_JOB", true)
  end

  def perform(guest)
    # ...
  end
end
```

`:abort`が`before_enqueue`コールバックの実行中にスローされると、ジョブはキューに登録されず、`perform_later`は`false`を返します。
`:abort`が`before_perform`コールバックの実行中にスローされた場合、ジョブは実行されません。また、以後の`before_*`、`around_*`、`after_*`コールバックの実行もすべてスキップされます。

NOTE: `:abort`をスローしても`after_discard`はトリガーされません。`after_discard`コールバックは、特別に`discard_on`メカニズムと連動します。

ジョブの継続
-----------------

Active Jobのジョブ継続（continuation）機能を使うと、ジョブを再開可能なステップに分割できるので、長時間実行されるジョブが中断されても処理を先に進められます。継続機能を使うと、ジョブは最後に完了したステップから自動的に再開されるため、最初からやり直す必要がなくなります。

ジョブの継続機能を使うには、[`ActiveJob::Continuable`][]モジュールをジョブクラスに`include`します。次に、`perform`メソッド内で[`step`][]メソッドを使って各ステップを定義できます。

```ruby
class ProcessImportJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(import_id)
    # 常にジョブ開始時に実行される（中断されたステップから再開する場合でも実行される）
    @import = Import.find(import_id)

    # ステップをブロックで定義する場合
    step :initialize do
      @import.initialize
    end

    step :process do
      @import.records.find_each { |record| record.process }
    end

    # メソッドを参照してステップを定義する場合
    step :finalize
  end

  private
    def finalize
      @import.finalize
    end
end
```

各ステップはブロックで宣言することも、メソッド名を参照して宣言することも可能です。ブロックが呼び出される際には、ステップオブジェクトが引数として渡されます。メソッドは、引数を取らないか、ステップオブジェクトを単独の引数として受け取るかのどちらかになります。

個別のステップは、実行時に到達した時点で直ちに実行されます。ステップに含まれていないコードは、ジョブが実行されるたびに実行されます。ジョブが中断された場合、すでに完了したステップはスキップされます。実行中だったステップは、最初からやり直されるか、カーソルを使っている場合は最後に記録されたカーソル位置から再開されます。

[`ActiveJob::Continuable`]:
  https://api.rubyonrails.org/classes/ActiveJob/Continuable.html
[`step`]:
  https://api.rubyonrails.org/classes/ActiveJob/Continuable.html#method-i-step

### カーソルを使う

ステップでオプションの[カーソル][]を利用することで、ステップ「内」の進捗状況をトラッキングすることも可能です。中断後にカーソルを利用して適切な箇所から処理を再開するのは、ステップ内のコードの責務です。

例:

```ruby
class ProcessImportJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(import_id)
    # 常にジョブ開始時に実行される（中断されたステップから再開する場合でも実行される）
    @import = Import.find(import_id)

    # ステップでカーソルを利用する
    step :process do |step|
      @import.records.find_each(start: step.cursor) do |record|
        record.process
        step.advance!
      end
    end

  end
end
```

上の例では、カーソルは正常に処理された最後のレコードの`id`をトラッキングします。大規模なインポートの実行中にジョブが中断された場合、保存したカーソル値を`find_each`に渡すことで、最初からレコードを再処理せずに、中断した箇所から処理を再開するようになります。

[カーソル]:
  https://api.rubyonrails.org/classes/ActiveJob/Continuation.html#class-ActiveJob::Continuation-label-Cursors

Solid Queue: デフォルトのバックエンド
------------------------------

Solid Queueは、Active Job向けのデータベースバックエンド型キューシステムであり、Rails 8.0以降のデフォルトのキューバックエンドです。Redisのような専用インフラストラクチャを別途必要とせず、既存のデータベースでジョブの永続化と処理を行います。Solid Queueは、ジョブの遅延実行、優先度設定、コンカレンシー制御、定期実行タスク、ジョブの一括登録などの機能もサポートしています。

### セットアップとデフォルト設定

production環境では、Solid Queueがデフォルトで設定されています。たとえば、`config/environments/production.rb`ファイルを開くと、以下のような設定が確認できます。

```ruby
# config/environments/production.rb
# Replace the default in-process and non-durable queuing backend for Active Job.
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

さらに、`queue`データベースへの接続は`config/database.yml`ファイルで設定されています。

```yaml
# config/database.yml
# Store production database in the storage/ directory, which by default
# is mounted as a persistent Docker volume in config/deploy.yml.
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
```

NOTE: データベース設定の`queue`キーは、`config.solid_queue.connects_to`設定で使われているキーと一致しなければなりません（前述のコードスニペットを参照）。

Solid Queueの利用を開始するには、`db:prepare`を実行して、Solid Queue関連のテーブルをデータベースに作成します。

```bash
$ bin/rails db:prepare
```

TIP: `queue`データベースのスキーマは、自動生成される`db/queue_schema.rb`で参照できます。ここには`solid_queue_jobs`、`solid_queue_recurring_executions`、`solid_queue_scheduled_executions`などのテーブルが含まれています。

最後に、キューを起動してジョブの処理を開始するには、以下のコマンドを実行します。

```bash
$ bin/jobs start
```

#### development環境の場合

Railsは、インプロセスの非同期キューイングシステムを提供し、ジョブをメモリ上に保持します。development環境のデフォルトの`async`アダプタは、プロセスがクラッシュしたり開発中のコンピュータがリセットされたりすると、未処理のジョブがすべて失われますが、開発中の重要度の低いジョブについては、これで十分です。

development環境でもSolid Queueを利用できます。設定方法はproduction環境の場合と同じです。

```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

development環境用のデータベース設定に`queue`を以下のように追加します。

```yml
# config/database.yml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
```

### ワーカー、ディスパッチャ、スーパバイザ

Solid Queueでは、以下の3種類のプロセスによってジョブのキューイングと実行を処理しています。

1. **ワーカー**（worker）: 実行準備が整ったジョブをキューからポーリングで見つけ、実行します。

2. **ディスパッチャ**（dispatcher）: スケジュールされたジョブを処理します。これから実行される予定のジョブをチェックして準備完了キューに移動し、ワーカーが処理できるようにします。

3. **スーパバイザ**（supervisor）: ワーカーとディスパッチャをforkして監視する形で両者を管理します。

`bin/jobs start`を実行すると、スーパバイザプロセスが起動します。スーパバイザは、`config/queue.yml`の設定に従ってワーカーとディスパッチャをforkして管理します。

デフォルト設定の例を以下に示します。

```yaml
# config/queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1
```

`config/queue.yml`の設定は必須ではありません。設定が指定されていない場合、Solid Queueはデフォルト設定のまま、1つのディスパッチャと1つのワーカーで動作します。
以下に、設定可能なオプションとそのデフォルト値をいくつか示します。

* `polling_interval`: ディスパッチャやワーカーが次のジョブをチェックするまでの待ち時間を秒で指定します。
  ディスパッチャのデフォルト値は1秒、ワーカーのデフォルト値は0.1秒です。

* `batch_size`: 1回のバッチでディスパッチされるジョブの件数です。
  デフォルト値は500です。

* `concurrency_maintenance_interval`: ディスパッチャがブロックされたジョブを解除できるかどうかを確認するまでの待ち時間を秒で指定します。
  デフォルト値は600秒です。

* `queues`: ワーカーがジョブを取得するキューのリストを指定します。
  `*`を使って、すべてのキューまたはキュー名のプレフィックスを指定できます。
  デフォルト値は`*`です。

* `threads`: 各ワーカーのスレッドプールの最大サイズを指定します。
  ワーカーが1回に取得するジョブの件数を決定します。
  デフォルト値は3です。

* `processes`: スーパバイザによってforkされるワーカープロセスの個数を指定します。
  各プロセスはCPUコアを専有できます。
  デフォルト値は1です。

* `concurrency_maintenance`: ディスパッチャがコンカレンシーメンテナンス作業を行うかどうかを指定します。
  デフォルト値は`true`です。

設定オプションについて詳しくは、[Solid Queueのドキュメント](https://github.com/rails/solid_queue?tab=readme-ov-file#configuration)を参照してください。
また、`config/<environment>.rb`で設定できる[追加の設定オプション](https://github.com/rails/solid_queue?tab=readme-ov-file#other-configuration-settings)を使うことで、RailsアプリケーションでSolid Queueをさらに詳細に設定できます。

### キューの順序と優先度

Solid Queueには、ジョブの処理順序を制御するための「キューの順序指定」と「数値による優先度指定」という2つの異なる仕組みが用意されています。期待通りの振る舞いを実現するには、この2つの相互作用を理解することが重要です。

#### キューの順序

Solid Queueの「キューの順序指定」は、作業の優先順位を決定する主要な方法です。`config/queue.yml`ファイルでワーカー用の`queues`の配列に記載されている順序によって、ポーリングの順序が決まります。ワーカーは、より優先度の高いキュー（配列内の左に記述されているもの）がすべて空になるまでは、優先度の低いキュー（配列内の右に記述されているもの）からジョブを取得しません。

```yaml
production:
  workers:
    - queues: [critical, default, low]
      threads: 5
```

上の設定では、`critical`キューに待機中のジョブがある間は`default`キューからジョブが取り出されることはなく、`critical`キューまたは`default`キューのいずれかに待機中のジョブがある間は`low`キューからジョブが取り出されることはありません。

Solid Queueの処理は、この順序に厳密に従います（優先度の低いキューにも処理時間が比例配分されるよう相対的な重み付けを許容する他のキューイングバックエンドとは異なります）。そのため、優先度の高いキューが常に処理で埋まっている状態が続くと、優先度の低いキューのジョブがいつまでも処理されない状態が発生する可能性があります。

設定するキュー名にはワイルドカード`*`を指定できます。
たとえば、ワーカーの設定が`queues:[active_storage*, mailers]`の場合、`active_storage_analyze`や`active_storage_transform`など「active_storageで始まる」キューからジョブが取得されます。`active_storage`で始まるキュー内のジョブがすべて処理された場合にのみ、ワーカーは`mailers`キューの処理に移ります。

WARNING: SQLiteやPostgreSQLで使うキュー名にワイルドカードが含まれていると（例: `queues: active_storage*`）、ポーリングのパフォーマンスが低下する可能性があります。これは、一致するすべてのキューを特定するために`DISTINCT`クエリが必要となり、大規模なテーブルでは処理に時間がかかるためです。パフォーマンスを落とさないためには、ワイルドカードを使わずに具体的なキュー名を指定するのが最適です。

#### 数値指定の優先度

数値指定の優先度は、単一のキューの「内部」で適用されます。ジョブの優先度の数値は[`queue_with_priority`][]で指定できます。数値が小さいほど優先順位が高くなり、デフォルト値は0です。

```ruby
class CriticalReportJob < ApplicationJob
  queue_as :default
  queue_with_priority 0
end

class RoutineCleanupJob < ApplicationJob
  queue_as :default
  queue_with_priority 10
end
```

上の2件のジョブが`default`キューにある場合、`CriticalReportJob`が先に処理されます。ただし、数値による優先度は同一キュー内でのみ有効であり、影響が他のキューに及ぶことはありません。キューの順序指定と優先度の仕組みを両方使う場合、キューの順序が優先されます。

#### ポーリング間隔

Solid Queueにおいて、ワーカーの`polling_interval`設定は、新しいジョブをどれだけ敏速に取得できるかに直接影響します。ポーリング間隔が長いと、優先度の高いキューであっても実際には反応が遅いと感じられる可能性があります。

```yaml
production:
  workers:
    - queues: critical
      threads: 5
      polling_interval: 0.1  # 100ms間隔のポーリング -- 高速なレスポンス
    - queues: low
      threads: 2
      polling_interval: 10   # 10s間隔のポーリング -- 低優先度の処理に向いている
```

特に処理の即応性が求められるキューでは、`polling_interval`をワーカーごとに調整することが重要です。

#### リトライ

Solid Queueのリトライは、Active Jobの[`retry_on`][]で明示的に設定する必要があります。

```ruby
class ExternalApiJob < ApplicationJob
  retry_on Net::TimeoutError, wait: :exponentially_longer, attempts: 5
  retry_on ActiveRecord::Deadlocked, wait: 2.seconds, attempts: 3

  def perform
    # ...
  end
end
```

デフォルトですべてのジョブに共通のリトライポリシーを適用したい場合は、`ApplicationJob`でグローバルに設定することも可能です。`retry_on`が設定されていないジョブが失敗した場合、リトライされずに、そのまま「失敗した実行（failed executions）」に移動します。

### コンカレンシー制御

Solid QueueはActive Jobを拡張して、コンカレンシー制御機能を提供しています。これにより、特定の種類のジョブを同時実行できる数を制限できるようになります。
これは、共有リソースを保護するときに有用です。たとえば、1つのアカウントが一度に実行できるエクスポートジョブを1件だけに制限したり、外部サービスへの同時API呼び出し数に上限を設定したりできます。

コンカレンシー制御は、ジョブクラス内の`limits_concurrency`で宣言します。

```ruby
class InvoiceExportJob < ApplicationJob
  limits_concurrency to: 1, key: ->(account_id) { "invoice_export_#{account_id}" }, duration: 10.minutes

  def perform(account_id)
    # ...
  end
end
```

設定内容は以下です。

- `:to`: コンカレント実行可能なジョブの最大数を設定します。
- `:key`: ジョブの引数に基づいてコンカレンシー処理のキーを算出するラムダを渡しています。上の例では、制限はグローバルではなく、アカウントごとに適用されます。
- `:duration`: このオプションはフェイルセーフとして機能します。そのため、ジョブの実行中にワーカーが停止しロックが解放されなかった場合でも、ここで指定した期間が経過すれば、ブロックされていたジョブが解放の候補となります。

コンカレンシー制御を指定したジョブがエンキューされると、Solid Queueは算出されたキーに対応するデータベース上のロックを確認します。

ロックが利用可能な場合は、ジョブは実行可能な状態（ready）としてマーキングされます。
ロックが利用できない場合は、`:on_conflict`オプションの設定で振る舞いが決まります。

`on_conflict`が`:block`（デフォルト）に設定されている場合、ジョブはブロック状態のまま保留され、実行中のジョブが完了した時点で初めて実行可能としてマーキングされます。
もう1つのオプションは`:discard`で、この場合、ジョブは完全に破棄されます。

`:group`オプションを使うと、制限の範囲を複数の「異なる」ジョブクラスにまたがって指定することも可能になります。

```ruby
class AnalyticsExportJob < ApplicationJob
  limits_concurrency to: 1, key: ->(account_id) { account_id }, group: "account_exports", duration: 10.minutes
end

class InvoiceExportJob < ApplicationJob
  limits_concurrency to: 1, key: ->(account_id) { account_id }, group: "account_exports", duration: 10.minutes
end
```

上の例では、両方のジョブクラスが「account_exports」グループによる同一のコンカレンシー制限を共有しています。つまり、ジョブの種別がどちらであっても、特定の1つのアカウントが一度に実行できるエクスポート処理は1つだけとなります。

NOTE: コンカレンシー制御は、ブロックされた実行をトラッキングしてロックを作成・更新する必要があるため、オーバーヘッドが生じます。そのため、コンカレンシー制御の利用は必要最小限に留めるべきです。単純なスループット制限を行う場合は、キューごとにワーカースレッド数を制限する方が効率的です。

WARNING: コンカレンシー制御は、`perform_all_later`によるキューへの一括登録と互換性がありません。コンカレンシー制御を行っているジョブは、設定された制限を遵守するために1件ずつエンキューしなければならないためです。

### エラー処理

Solid Queueは、ジョブのエンキュー中にActive Recordのエラーが発生すると`SolidQueue::Job::EnqueueError`をraiseします。このエラーは、`ActiveJob::EnqueueError`とは別物です（`ActiveJob::EnqueueError`の場合、Active Jobが内部で処理して`perform_later`が`false`を返します）。
このため、Railsの内部処理や`Turbo::Streams::BroadcastJob`などのサードパーティ製gemによってエンキューされるジョブについては、`perform_later`の呼び出しを直接制御できないため、エラーの処理が難しくなるという実用上の問題が生じます。
なお、定期実行タスク（recurring tasks）の場合、エンキュー時のエラーはログに記録されますが、例外は発生しません（詳しくは、Solid Queueドキュメント「[Errors When Enqueuing](https://github.com/rails/solid_queue?tab=readme-ov-file#errors-when-enqueuing)」を参照してください）。

ワーカープロセスが予期せず終了した場合（例: `KILL`シグナルによって）、実行中のジョブはすべて「失敗」としてマーキングされ、`SolidQueue::Processes::ProcessExitError`や`SolidQueue::Processes::ProcessPrunedError`などのエラーがraiseされます。
Solid Queueが期限切れのプロセスをどの程度迅速に検出・クリーンアップするかは、ハートビートの設定によって制御されます（この動作の設定について詳しくはSolid Queueドキュメント「[Threads, Processes and Signals](https://github.com/rails/solid_queue?tab=readme-ov-file#threads-processes-and-signals)」を参照してください）。

利用しているエラートラッキングサービスでジョブのエラーが自動的にキャプチャされない場合は、`ApplicationJob`内でActive Jobの`rescue_from`を利用できます。

```ruby
class ApplicationJob < ActiveJob::Base
  rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

アプリケーションでAction Mailerを利用している場合、メーラーの配信は`ActionMailer::MailDeliveryJob`を介して実行される点にご注意ください。このジョブは`ApplicationJob`を継承していますが、個別に処理する必要があります。

```ruby
class ApplicationMailer < ActionMailer::Base
  ActionMailer::MailDeliveryJob.rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

### ジョブのトランザクション整合性

Solid Queueはアプリケーションと同じデータベースを利用できるため、アプリケーションのデータと同じACIDトランザクションに参加できます。しかし、この振る舞いには重要な特性があり、実際に利用する前にそれを理解しておく必要があります。

Solid Queueがアプリケーションと同じデータベースを利用する場合、ジョブのエンキューは、その前後で行われるActive Recordの操作と「同一の」トランザクション内で行われます。つまり、そのトランザクションがロールバックされればジョブはエンキューされず、逆にジョブのエンキューが成功しない限りトランザクションもコミットされなくなります。これにより、Redisをバックエンドとする場合に起こりがちな競合状態（例: 必要なレコードがデータベースにコミットされる前にジョブが実行されてしまう）を回避できます。

しかしRails 8では、まさにこの挙動への暗黙的な依存を避けるために、デフォルトでSolid Queueを「**別のデータベース**」に設定するようになりました。トランザクションの整合性に依存するロジックを構築した後で、Solid Queueを専用のデータベースへ移行したり、別のバックエンドに切り替えたりすると、気が付かないうちにこの振る舞いが失われてしまうからです。ほとんどのアプリケーションにとっては、デフォルトで別のデータベースを利用する方が安全な選択と言えます。

#### `enqueue_after_transaction_commit`を使う

トランザクションの安全性を、アプリケーションとSolid Queueが同じデータベースを共有することに依存せずに確保する方法として、[`enqueue_after_transaction_commit`][]の利用が推奨されます。これにより、ジョブのエンキューは、それを含むActive Recordのトランザクションが正常にコミットされるまで延期されます。この機能は、ジョブ単位またはグローバルに有効化できます。

```ruby
class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true
end
```

この設定によって、ロールバックされるトランザクション内でエンキューされたジョブは、単にエンキューされなくなります。これにより、Solid Queueがアプリケーションとデータベースを共有しているかどうかにかかわらず、環境に依存しない形でこの振る舞いが保証されます。

[`enqueue_after_transaction_commit`]:
  https://api.rubyonrails.org/classes/ActiveJob/Enqueuing.html#method-c-enqueue_after_transaction_commit

#### ジョブを`after_commit`コールバックからエンキューする

`enqueue_after_transaction_commit`を使いたくない場合は、トランザクションの内部から直接ジョブをエンキューするのではなく、常に`after_commit`コールバックからエンキューするという方法もあります。

```ruby
after_commit :schedule_cleanup, on: :create

def schedule_cleanup
  GuestsCleanupJob.perform_later(self)
end
```

これにより、関連するデータがデータベースに永続的にコミットされた後にのみ、ジョブがキューに登録されるようになります。

#### 暗黙的な依存関係で生じるリスク

見落とされやすい危険なケースとして、前述の安全策を講じないままトランザクション内でジョブをエンキューすることが挙げられます。この場合、ジョブで必要なデータが他のコネクションから参照可能になる前にジョブが実行される、トランザクションがロールバックされたにもかかわらずジョブがエンキューされる、といった可能性が生じます。

こうした問題は、Redisをバックエンドとするシステムでは同じ形では発生しないため、そうした環境に慣れていると、この点を見落としてしまいがちです。自分たちのコードがトランザクションの整合性に依存しているかどうかが不明な場合は、`ApplicationJob`で`enqueue_after_transaction_commit`をグローバルに有効にしておくのが最も安全なデフォルト設定と言えます。

詳しくはSolid Queueドキュメントの「[Transactional Integrity](https://github.com/rails/solid_queue?tab=readme-ov-file#jobs-and-transactional-integrity)」を参照してください。

### 定期実行タスク

Solid Queueは、cronジョブに似た定期実行タスクをサポートしています。定期実行タスクは設定ファイル（デフォルトでは`config/recurring.yml`）で定義され、特定の時間を指定してスケジューリングできます。タスク設定の例を以下に示します。

```yaml
production:
  a_periodic_job:
    class: MyJob
    args: [42, { status: "custom_status" }]
    schedule: every second
  a_cleanup_task:
    command: "DeletedStuff.clear_all"
    schedule: every day at 9am
```

各タスクには、`class`（または`command`）と`schedule`を指定します（スケジュール指定文字列の解析には[Fugit](https://github.com/floraison/fugit) gemが使われます）。
上の設定例の`MyJob`のように、`args`オプションでジョブに引数を渡すことも可能です。`args`オプションには「単一の引数」「ハッシュ」「引数の配列」のいずれかを渡すことが可能で、配列の場合は最後の要素にキーワード引数も含められます。

定期実行タスクについて詳しくはSolid Queueドキュメント「[Recurring Tasks](https://github.com/rails/solid_queue?tab=readme-ov-file#recurring-tasks)」を参照してください。

代替キューイングバックエンド
--------------------------

RailsではSolid Queueがデフォルトのキューイングバックエンドとして採用されていますが、Active Jobはさまざまなキューイングバックエンドとシームレスに連携できるように設計されています。
[Sidekiq](https://github.com/sidekiq/sidekiq)、[GoodJob](https://github.com/bensheldon/good_job)、[Resque](https://github.com/resque/resque)などの別のバックエンドに切り替える場合、Gemfileに対象バックエンドのアダプタを追加し、設定を変更するだけで済みます（通常、ジョブのコード自体を修正する必要はありません）。

以下は、代替キューイングバックエンドとそのドキュメントのリストです（すべてを網羅しているわけではありません）。

- [Sidekiq](https://github.com/mperham/sidekiq/wiki/Active-Job)
- [Resque](https://github.com/resque/resque/wiki/ActiveJob)
- [Sneakers](https://github.com/jondot/sneakers/wiki/How-To:-Rails-Background-Jobs-with-ActiveJob)
- [Queue Classic](https://github.com/QueueClassic/queue_classic#active-job)
- [Delayed Job](https://github.com/collectiveidea/delayed_job#active-job)
- [Que](https://github.com/que-rb/que#additional-rails-specific-setup)
- [Good Job](https://github.com/bensheldon/good_job#readme)

キューイングバックエンドをグローバルに切り替えるには、アプリケーション設定ファイルで以下のように`config.active_job.queue_adapter`を設定します。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_adapter = :sidekiq
  end
end
```

アダプタは環境単位でも設定できます。production環境ではSolid Queueを使い、development環境ではもっとシンプルなアダプタを使いたいといった場合に便利です。

```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :async
```

キューイングバックエンドを段階的に移行したい場合は、アダプタをジョブクラスレベルで設定する方法が使えます。
これは、すべてを一度に切り替えるのではなく、1度に1個のジョブを移行したい場合に便利です。

```ruby
class MyJob < ApplicationJob
  self.queue_adapter = :sidekiq
end
```

キューイングバックエンドごとに専用のgemが必要で、通常は専用のプロセスも必要です。アダプタのgemを`Gemfile`に追加したら、アダプタのドキュメントを参照して追加の設定を行ってください。ほとんどのバックエンドでは、Railsアプリケーションとは別にワーカープロセスを起動する必要があり、Redisなどの追加インフラを必要とする場合もあります（Sidekiqなど）。

バックエンドを切り替えても、古いキューに既に存在するジョブは移行されない点にご注意ください。切り替え前に古いキューを空にするか、既存のジョブが完了するまで一時的に両方のバックエンドを並行して運用する必要があります。

NOTE: Active Jobの初期リリースには各種キューイングバックエンド用のアダプタが組み込まれていましたが、後に、キューイングバックエンドのプロバイダ自身がアダプタを管理する方針に変更されました。アダプタがActive Jobに組み込まれているかどうかにかかわらず、あらゆるバックエンドをActive Jobで利用できます。

TIP: `config.active_job.queue_name_prefix`を使う場合、新しいバックエンドのワーカー設定が、プレフィックスなしのキュー名ではなく、プレフィックス付きのキュー名をリッスンするようになっていることを確認してください。

失敗したジョブの監視と処理
-----------------------------------

### Mission Controlで監視する

[Mission Control](https://github.com/rails/mission_control-jobs)は、Active Jobアダプタ向けのRails製フロントエンドであり、失敗したジョブの監視と管理を一元化するのに役立ちます。ジョブのステータス、失敗の原因、リトライの挙動に関する情報を提供し、問題のトラッキングや解決をより効率的に行えるようになります。

たとえば、あるジョブが大きなファイルの処理中にタイムアウトで失敗した場合、`mission_control-jobs`を使えば、失敗の詳細を確認したり、ジョブの引数や実行履歴を調べてから、ジョブのリトライ・再キューイング・破棄のどれを行うかを判断できるようになります。

### `rescue_from`でエラーを検出する

ジョブの実行中に発生した例外は、[`rescue_from`][]で処理できます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
    # 例外を処理する
  end

  def perform
    # 後で実行するタスクをここに置く
  end
end
```

ジョブから発生した例外が`rescue`されない場合、そのジョブは「失敗」したとみなされます。

[詳細なエンキューログ](debugging_rails_applications.html#詳細なエンキューログ)を有効にすると、ジョブの発生元を特定するログを追加出力できるようになります。

[`rescue_from`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

### 失敗したジョブのリトライと破棄

失敗したジョブは、明示的に設定しない限りリトライされません。

失敗したジョブは、以下のように[`retry_on`][]で条件を指定してリトライすることも、[`discard_on`][]で条件を指定して破棄することも可能です。

```ruby
class RemoteServiceJob < ApplicationJob
  retry_on CustomAppException # デフォルトは3秒間待ち、最大5回試行する

  discard_on Net::OpenTimeout

  def perform(*args)
    # CustomAppException または Net::OpenTimeout がraiseされる可能性があるとする
  end
end
```

[`discard_on`]:
    https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-discard_on
[`retry_on`]:
    https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on

### レコードが見つからない場合

`#perform`メソッドを呼び出すと、GlobalIDは一意の識別子でActive Recordの完全なオブジェクトを特定します。

渡されたレコードが、「ジョブがエンキューされた後」かつ「`#perform`メソッドが呼び出される前」に削除されると、Active Jobは[`ActiveJob::DeserializationError`](https://api.rubyonrails.org/classes/ActiveJob/DeserializationError.html)をraiseします。
