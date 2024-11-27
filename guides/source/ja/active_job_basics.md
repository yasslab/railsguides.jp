Active Job の基礎
=================

本ガイドでは、バックグラウンドで実行するジョブの作成、キュー登録（エンキュー: enqueue）、実行方法について解説します。

このガイドの内容:

* ジョブの作成方法
* ジョブの登録方法
* バックグラウンドでのジョブ実行方法
* アプリケーションから非同期にメールを送信する方法

--------------------------------------------------------------------------------


はじめに
------------

Active Jobは、ジョブを宣言し、それによってバックエンドでさまざまな方法によるキュー操作を実行するためのフレームワークです。ジョブには、定期的なクリーンアップを始めとして、請求書発行やメール配信など、あらゆる処理がジョブになります。これらのジョブをより細かな作業単位に分割して並列実行することもできます。

Active Jobの目的
-----------------------------

Active Jobの主要な目的は、あらゆるRailsアプリケーションにジョブ管理インフラを配置することです。これにより、Delayed JobとResqueなどのように、さまざまなジョブ実行機能のAPIの違いを気にせずにジョブフレームワーク機能やその他のgemを搭載することができるようになります。バックエンドでのキューイング作業では、操作方法以外のことを気にせずに済みます。さらに、ジョブ管理フレームワークを切り替える際にジョブを書き直さずに済みます。

NOTE: デフォルトのRailsは非同期キューを実装します。これは、インプロセスのスレッドプールでジョブを実行します。ジョブは非同期に実行されますが、再起動するとすべてのジョブは失われます。

ジョブを作成して登録する
--------------

このセクションでは、ジョブの作成方法とジョブの登録（enqueue: エンキュー）方法を手順を追って説明します。

### ジョブを作成する

Active Jobは、ジョブ作成用のRailsジェネレータを提供しています。以下を実行すると、`app/jobs`にジョブが1つ作成されます。

```bash
$ bin/rails generate job guests_cleanup
invoke  test_unit
create    test/jobs/guests_cleanup_job_test.rb
create  app/jobs/guests_cleanup_job.rb
```

以下のようにすると、特定のキューに対してジョブを1件作成できます。

```bash
$ bin/rails generate job guests_cleanup --queue urgent
```

ジェネレータを使いたくない場合は、`app/jobs`の下に自分でジョブファイルを作成することもできます。ジョブファイルでは必ず`ApplicationJob`を継承してください。

作成されたジョブは以下のようになります。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*guests)
    # 後で実行するタスクをここに置く
  end
end
```

なお、`perform`の定義にはいくつでも引数を渡せます。

`ApplicationJob`と異なる名前の抽象クラスが既に存在する場合、以下のように`--parent`オプションを渡すことで、別の抽象クラスが必要であることを示せます。

```bash
$ bin/rails generate job process_payment --parent=payment_job
```

```ruby
class ProcessPaymentJob < PaymentJob
  queue_as :default

  def perform(*args)
    # 後で実行するタスクをここに置く
  end
end
```

### ジョブをキューに登録する

キューへのジョブ登録は[`perform_later`][]で以下のように行います。オプションで[`set`][]も指定できます。

```ruby
# 「キューイングシステムが空いたらジョブを実行する」とキューに登録する
GuestsCleanupJob.perform_later guest
```

```ruby
# 明日正午に実行したいジョブをキューに登録する
GuestsCleanupJob.set(wait_until: Date.tomorrow.noon).perform_later(guest)
```

```ruby
# 一週間後に実行したいジョブをキューに登録する
GuestsCleanupJob.set(wait: 1.week).perform_later(guest)
```

```ruby
# `perform_now`と`perform_later`は`perform`を呼び出すので、
# 定義した引数を渡すことができる
GuestsCleanupJob.perform_later(guest1, guest2, filter: "some_filter")
```

以上でジョブ登録は完了です。

[`perform_later`]: https://api.rubyonrails.org/classes/ActiveJob/Enqueuing/ClassMethods.html#method-i-perform_later
[`set`]: https://api.rubyonrails.org/classes/ActiveJob/Core/ClassMethods.html#method-i-set

### 複数のジョブを一括登録する

[`perform_all_later`][]を使うと、複数のジョブを一括登録できます。詳しくは[一括登録](#一括登録)を参照してください。

[`perform_all_later`]: https://api.rubyonrails.org/classes/ActiveJob.html#method-c-perform_all_later

ジョブを実行する
-------------

production環境でのジョブのキュー登録と実行では、キューイングのバックエンドを用意しておく必要があります。具体的には、Railsで使うべきサードパーティのキューイングライブラリを決める必要があります。
Rails自身が提供するのは、ジョブをメモリに保持するインプロセスのキューイングシステムだけです。
プロセスがクラッシュしたりコンピュータをリセットしたりすると、デフォルトの非同期バックエンドの振る舞いによって主要なジョブが失われてしまいます。アプリケーションが小規模な場合やミッションクリティカルでないジョブであればこれでも構いませんが、多くのproductionでは永続的なバックエンドを選ぶ必要があります。

### バックエンド

Active Jobには、Sidekiq、Resque、Delayed Jobなどさまざまなキューイングバックエンドに接続できるアダプタがビルトインで用意されています。利用可能な最新のアダプタのリストについては、APIドキュメントの[`ActiveJob::QueueAdapters`][]を参照してください。

[`ActiveJob::QueueAdapters`]: https://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html

### バックエンドを設定する

キューイングバックエンドは、[`config.active_job.queue_adapter`]で手軽に設定できます。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # 必ずGemfileにアダプタのgemを追加し、
    # アダプタ固有のインストール方法や
    # デプロイ方法に従うこと。
    config.active_job.queue_adapter = :sidekiq
  end
end
```

次のように、ジョブごとにバックエンドを設定することもできます。

```ruby
class GuestsCleanupJob < ApplicationJob
  self.queue_adapter = :resque
  # ...
end

# これでジョブが`resque`を使うようになります
# `config.active_job.queue_adapter`で設定された内容が
# バックエンドキューアダプタでオーバーライドされるためです
```

### バックエンドを起動する

ジョブはRailsアプリケーションに対して並列で実行されるので、多くのキューイングライブラリでは、ジョブを処理するためにライブラリ固有のキューイングサービスを （Railsアプリケーションの起動とは別に） 起動しておくことが求められます。キューのバックエンドの起動方法については、ライブラリのドキュメントを参照してください。

以下はドキュメントのリストの一部です（すべてを網羅しているわけではありません）。

- [Sidekiq](https://github.com/mperham/sidekiq/wiki/Active-Job)
- [Resque](https://github.com/resque/resque/wiki/ActiveJob)
- [Sneakers](https://github.com/jondot/sneakers/wiki/How-To:-Rails-Background-Jobs-with-ActiveJob)
- [Queue Classic](https://github.com/QueueClassic/queue_classic#active-job)
- [Delayed Job](https://github.com/collectiveidea/delayed_job#active-job)
- [Que](https://github.com/que-rb/que#additional-rails-specific-setup)
- [Good Job](https://github.com/bensheldon/good_job#readme)
- [Solid Queue](https://github.com/rails/solid_queue?tab=readme-ov-file#solid-queue)

キュー
------

多くのアダプタでは複数のキューを扱えます。Active Jobの[`queue_as`][]を使って、特定のキューに入っているジョブをスケジューリングできます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  # ...
end
```

`application.rb`で以下のように[`config.active_job.queue_name_prefix`][]を使うことで、すべてのジョブでキュー名の前に特定の文字列を追加できます。

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

# 以上で、production環境ではproduction_low_priorityというキューでジョブが
# 実行されるようになり、staging環境ではstaging_low_priorityというキューで
# ジョブが実行されるようになります
```

以下のようにジョブごとにプレフィックスを設定することもできます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  self.queue_name_prefix = nil
  # ...
end

# これで自分のジョブキューにプレフィックスが設定されなくなり
# `config.active_job.queue_name_prefix`の設定が上書きされます
```

キュー名のプレフィックスのデフォルト区切り文字は'\_'です。[`config.active_job.queue_name_delimiter`][]を設定することでこの区切り文字を変更できます。

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

# 以上で、production環境ではproduction.low_priorityというキューでジョブが
# 実行されるようになり、staging環境ではstaging.low_priorityというキューでジョブが実行されるようになります
```

`#queue_as`にブロックを渡すと、キューをそのジョブレベルで制御できます。与えられたブロックは、そのジョブのコンテキストで実行されます（これにより`self.arguments`にアクセスできるようになります）。そしてキュー名を返さなくてはなりません。

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
ProcessVideoJob.perform_later(Video.last)
```

ジョブを実行するキューをさらに細かく制御したい場合は、`#set`に`:queue`オプションを渡せます。

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

NOTE: 設定したキュー名をキューイングバックエンドが「リッスンする」ようにしてください。一部のバックエンドでは、リッスンするキューを指定する必要が生じることもあります。

[`config.active_job.queue_name_delimiter`]: configuring.html#config-active-job-queue-name-delimiter
[`config.active_job.queue_name_prefix`]: configuring.html#config-active-job-queue-name-prefix
[`queue_as`]: https://api.rubyonrails.org/classes/ActiveJob/QueueName/ClassMethods.html#method-i-queue_as

優先順位付け
--------------

アダプタによってはジョブレベルでの優先順位付けをサポートしており、キュー内の別のジョブや、すべてのキュー内にある他のジョブに対してジョブを優先できます。

優先順位を指定してジョブをスケジューリングするには、[`queue_with_priority`][]メソッドを使います。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_with_priority 10
  # ...
end
```

このメソッドは、優先順位付けをサポートしていないアダプタでは無効です。

`queue_as`の場合と同様に、`queue_with_priority`にブロックを渡してジョブのコンテキストで評価することも可能です。

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
    # Process video
  end
end
```

```ruby
ProcessVideoJob.perform_later(Video.last)
```

以下のように`set`に`:priority`オプションを渡すことも可能です。

```ruby
MyJob.set(priority: 50).perform_later(record)
```

NOTE: 優先度の低い番号が、優先度の高い番号より先に実行されるか後に実行されるかは、アダプタの実装によって異なります。詳しくはバックエンドのドキュメントを参照してください。アダプタの作成者は、小さい番号ほど重要度が高いものとして扱うことが推奨されます。

[`queue_with_priority`]: https://api.rubyonrails.org/classes/ActiveJob/QueuePriority/ClassMethods.html#method-i-queue_with_priority

コールバック
---------

Active Jobが提供するフックを用いて、ジョブのライフサイクル中にロジックをトリガーできます。これらのコールバックは、Railsの他のコールバックと同様に通常のメソッドとして実装し、マクロ風のクラスメソッドでコールバックとして登録できます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  around_perform :around_cleanup

  def perform
    # 後で行なう
  end

  private

  def around_cleanup
    # performの直前に何か実行
    yield
    # performの直後に何か実行
  end
end
```

このマクロスタイルのクラスメソッドは、ブロックを1つ受け取ることもできます。ブロック内のコード量が1行以内に収まるほど少ない場合は、この書き方をご検討ください。
たとえば、登録されたジョブごとの測定値を送信する場合は次のようにします。

```ruby
class ApplicationJob < ActiveJob::Base
  before_enqueue { |job| $statsd.increment "#{job.class.name.underscore}.enqueue" }
end
```

### 利用できるコールバック

* [`before_enqueue`][]
* [`around_enqueue`][]
* [`after_enqueue`][]
* [`before_perform`][]
* [`around_perform`][]
* [`after_perform`][]

[`before_enqueue`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-before_enqueue
[`around_enqueue`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-around_enqueue
[`after_enqueue`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-after_enqueue
[`before_perform`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-before_perform
[`around_perform`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-around_perform
[`after_perform`]: https://api.rubyonrails.org/classes/ActiveJob/Callbacks/ClassMethods.html#method-i-after_perform

`perform_all_later`でジョブをキューに一括登録すると、個別のジョブでは`around_enqueue`などのコールバックがトリガーされなくなる点にご注意ください。
詳しくは[一括登録のコールバック](#一括登録のコールバック)を参照してください。

一括登録
--------------

[`perform_all_later`][]を使うことで、複数のジョブをキューに一括登録（bulk enqueue: バルクエンキュー）できます。一括登録により、Redisやデータベースなどのキューデータストアとのジョブの往復が削減され、同じジョブを個別に登録するよりもパフォーマンスが向上します。

`perform_all_later`はActive JobのトップレベルAPIで、インスタンス化されたジョブを引数として受け取ります（この点が`perform_later`と異なることにご注意ください）。`perform_all_later`は内部で`perform`を呼び出します。`new`に渡された引数は、最終的に`perform`が呼び出されるときに`perform`に渡されます。

以下は、`GuestCleanupJob`インスタンスを用いて`perform_all_later`を呼び出すコード例です。

```ruby
# `perform_all_later`に渡すジョブを作成する
# この`new`に渡した引数は`perform`に渡される
guest_cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest) }

# `GuestCleanupJob`の個別のインスタンスごとにジョブをキューに登録する
ActiveJob.perform_all_later(guest_cleanup_jobs)

# `set`メソッドでオプションを設定してからジョブを一括登録してもよい
guest_cleanup_jobs = Guest.all.map { |guest| GuestsCleanupJob.new(guest).set(wait: 1.day) }

ActiveJob.perform_all_later(guest_cleanup_jobs)
```

`perform_all_later`は、正常にキューに登録されたジョブの個数をログ出力します。たとえば、上の`Guest.all.map`の結果`guest_cleanup_jobs`が3個になった場合、`Enqueued 3 jobs to Async (3 GuestsCleanupJob)`とログ出力されます（キュー登録がすべて成功した場合）。

`perform_all_later`の戻り値は`nil`です。これは、`perform_later`がキューに登録したジョブクラスのインスタンスを返すのと異なる点にご注意ください。

### 複数のActive Jobクラスを登録する

`perform_all_later`を使えば、同じ呼び出しでさまざまなActive Jobクラスのインスタンスを以下のようにキューに登録することも可能です。

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

### 一括登録のコールバック

`perform_all_later`でジョブをキューに一括登録すると、個別のジョブでは`around_enqueue`などのコールバックがトリガーされません。この振る舞いは、Active Recordの他の一括処理系メソッドと一貫しています。コールバックは個別のジョブに対して実行されるので、`perform_all_later`メソッドでは一括処理の恩恵を受けられません。

ただし、`perform_all_later`メソッドは、`ActiveSupport::Notifications`でサブスクライブできる[`enqueue_all.active_job`][]イベントをトリガーします。

ジョブのキューへの登録が成功したかどうかを知るには、[`successfully_enqueued?`][]メソッドが利用できます。

[`enqueue_all.active_job`]: active_support_instrumentation.html#enqueue-all-active-job
[`successfully_enqueued?`]: https://api.rubyonrails.org/classes/ActiveJob/Core.html#method-i-successfully_enqueued-3F

### キューバックエンドのサポート

`perform_all_later`によるキューへの一括登録を行うには、[キューのバックエンド](#バックエンド)にるサポートが必要です。

たとえば、Sidekiqには`push_bulk`メソッドがあるので、これを用いて多数のジョブをRedisにプッシュして、往復の増加によるネットワーク遅延を避けられます。GoodJobでは`GoodJob::Bulk.enqueue`メソッドによるキューへの一括登録もサポートしています。新しいキューバックエンドである[`Solid Queue`][]でもキューへの一括登録のサポートが追加されました。

キューへの一括登録がキューバックエンドでサポートされていない場合、`perform_all_later`はジョブを1件ずつキューに登録します。

[`Solid Queue`]: https://github.com/rails/solid_queue/pull/93

Action Mailer
------------

最近のWebアプリケーションでよく実行されるジョブといえば、リクエスト-レスポンスのサイクルの外でメールを送信することでしょう。これにより、ユーザーが送信を待つ必要がなくなります。Active JobはAction Mailerと統合されているので、非同期メール送信を簡単に行えます。

```ruby
# すぐにメール送信するなら#deliver_now
UserMailer.welcome(@user).deliver_now

# Active Jobで後でメール送信するなら#deliver_later
UserMailer.welcome(@user).deliver_later
```

NOTE: 一般に、非同期キュー（`.deliver_later`でメールを送信するなど）はRakeタスクに書いても動きません。Rakeが終了すると、`.deliver_later`がメールの処理を完了する前にインプロセスのスレッドプールを削除する可能性があるためです。この問題を回避するには、`.deliver_now`を用いるか、development環境で永続的キューを実行してください。

国際化（i18n）
--------------------

各ジョブでは、ジョブ作成時に設定された`I18n.locale`を使います。これはメールを非同期的に送信する場合に便利です。


```ruby
I18n.locale = :eo

UserMailer.welcome(@user).deliver_later # メールがエスペラント語にローカライズされる
```

引数でサポートされる型
----------------------------

Active Jobの引数では、デフォルトで以下の型をサポートします。

  - 基本型（`NilClass`、`String`、`Integer`、`Float`、`BigDecimal`、`TrueClass`、`FalseClass`）
  - `Symbol`
  - `Date`
  - `Time`
  - `DateTime`
  - `ActiveSupport::TimeWithZone`
  - `ActiveSupport::Duration`
  - `Hash`（キーの型は`String`か`Symbol`にすべき）
  - `ActiveSupport::HashWithIndifferentAccess`
  - `Array`
  - `Range`
  - `Module`
  - `Class`

GlobalID
--------

Active Jobでは[GlobalID](https://github.com/rails/globalid/blob/main/README.md)がパラメータとしてサポートされています。GlobalIDを使えば、動作中のActive Recordオブジェクトをジョブに渡す際にクラスとidを指定する必要がありません。クラスとidを指定する従来の方法では、後で明示的にデシリアライズ（deserialize）する必要がありました。従来のジョブが以下のようなものだったとします。

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

上は以下のように簡潔に書けます。

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

このコードは、`GlobalID::Identification`をミックスインするすべてのクラスで動作します。このモジュールはActive Recordクラスにデフォルトでミックスインされます。

### シリアライザ

サポートされる引数の型は、以下のような独自のシリアライザを定義するだけで拡張できます。

```ruby
# app/serializers/money_serializer.rb
  # あるオブジェクトを、オブジェクト型をサポートするもっとシンプルな表現形式に変換する。
  # 表現形式としては特定のキーを持つハッシュが推奨される。キーには基本型のみが利用可能。
  # `super`を読んでカスタムシリアライザ型をハッシュに追加すべき
  def serialize(money)
    super(
      "amount" => money.amount,
      "currency" => money.currency
    )
  end
  # シリアライズされた値を正しいオブジェクトに逆変換する
  def deserialize(hash)
    Money.new(hash["amount"], hash["currency"])
  end

  private
    # ある引数がこのシリアライザでシリアライズされるべきかどうかをチェックする
    def klass
      Money
    end
end
```

続いてこのシリアライザをリストに追加します。

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

初期化中は、再読み込み可能なコードの自動読み込みがサポートされていない点にご注意ください。そのため、たとえば以下のように`config/application.rb`を修正するなどして、シリアライザが1度だけ読み込まれるように設定することをおすすめします。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

例外処理
----------

Active Jobでは、ジョブ実行時に発生する例外を[`rescue_from`][]でキャッチする方法が提供されています。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
   # ここに例外処理を書く
  end

  def perform
    # 後で実行する処理を書く
  end
end
```

[`rescue_from`]: https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

### 失敗したジョブをリトライまたは廃棄する

実行中に例外が発生したジョブは、以下のように[`retry_on`]でリトライすることも、[`discard_on`]で廃棄することもできます。

```ruby
class RemoteServiceJob < ApplicationJob
  retry_on CustomAppException # defaults to 3s wait, 5 attempts

  discard_on ActiveJob::DeserializationError

  def perform(*args)
    # CustomAppExceptionかActiveJob::DeserializationErrorをraiseする可能性があるとする
  end
end
```

詳しくは、[ActiveJob::Exceptions](https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html) APIドキュメントを参照してください。

[`discard_on`]: https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-discard_on
[`retry_on`]: https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on

### デシリアライズ

GlobalIDによって`#perform`に渡された完全なActive Recordオブジェクトのシリアライズが可能になります。

ジョブがキューに登録された後で、渡したレコードが1件削除され、かつ`#perform`メソッドをまだ呼び出していない場合は、Active Jobによって[`ActiveJob::DeserializationError`][]エラーがraiseされます。

[`ActiveJob::DeserializationError`]: https://api.rubyonrails.org/classes/ActiveJob/DeserializationError.html

ジョブをテストする
--------------

ジョブのテスト方法について詳しくは、[テスティングガイド](testing.html#ジョブをテストする)をご覧ください。

デバッグ
---------

ジョブがどこから来ているのかを把握したい場合は、[詳細なログ](debugging_rails_applications.html#詳細なエンキューログ)を有効にできます。
