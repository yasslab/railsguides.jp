Active Job の基礎
=================

本ガイドでは、バックグラウンドで実行するジョブの作成、キュー登録（エンキュー: enqueue）、実行方法について解説します。

このガイドの内容:

* ジョブの作成とキューへの登録方法
* Solid Queueの設定と利用方法
* バックグラウンドでのジョブ実行方法
* アプリケーションから非同期にメールを送信する方法

--------------------------------------------------------------------------------

Active Jobについて
------------

Active Jobは、バックグラウンドジョブを宣言してキューイングバックエンドで実行するために設計されたRailsのフレームワークです。

メールの送信、データの処理、クリーンアップや料金の請求といった定期的なメンテナンス業務の処理などのタスクを実行するための、標準化されたインターフェイスを提供します。Active Jobは、これらのタスクをメインアプリケーションスレッドで処理する代わりに、デフォルトのSolid Queueなどのキューイングバックエンドに処理させることで、時間のかかる操作がリクエスト・レスポンスのサイクルをブロックしないようにします。これにより、アプリケーションのパフォーマンスと応答性が向上し、タスクを並行して処理できるようになります。

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

[`perform_later`]:
    https://api.rubyonrails.org/classes/ActiveJob/Enqueuing/ClassMethods.html#method-i-perform_later
[`set`]:
    https://api.rubyonrails.org/classes/ActiveJob/Core/ClassMethods.html#method-i-set

Solid Queue: デフォルトのバックエンド
------------------------------

Solid Queueは、通常のデータベースを利用するActive Job用のキューイングシステムであり、Rails 8.0からデフォルトで有効になっています。Solid Queueは、Redisなどの追加の依存関係を必要とせずに大量のデータをジョブキューで処理できます。

Solid Queueは、通常のジョブのエンキューや処理に加えて、ジョブの遅延実行やコンカレンシー制御、数値によるジョブごとの優先度指定、キュー実行順序に基づいた優先度などをサポートします。

### セットアップ

#### development環境の場合

development環境のRailsは、非同期のインプロセスキューイングシステムを提供し、ジョブをメモリ上に保持します。

デフォルトの非同期バックエンドでは、プロセスがクラッシュしたり開発中のコンピュータがリセットされたりすると、未処理のジョブがすべて失われますが、開発中の小規模なアプリや重要度の低いジョブについては、これで十分です。

しかし、Solid Queueを使えば、production環境と同じ方法で以下のようにdevelopment環境のジョブキューシステムを設定できます。

```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

上の設定では、production環境におけるActive Jobのデフォルトと同様にdevelopment環境に`:solid_queue`アダプターが設定され、書き込み用に`queue`データベースに接続します。

次に、development環境用のデータベース設定で以下のように`queue`を追加します。

```yaml
# config/database.yml
development
  primary:
    <<: *default
    database: storage/development.sqlite3
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
```

NOTE: データベース設定の`queue`キーは、`config.solid_queue.connects_to`の設定で使われているキーと同じにする必要があります。

`queue`データベースのマイグレーションを実行すれば、キューデータベース内のすべてのテーブルが作成されるようになります。

```bash
$ bin/rails db:migrate:queue
```

TIPS: `queue`データベースのデフォルトの生成スキーマは`db/queue_schema.rb`に配置されます。これらのスキーマファイルには `solid_queue_ready_executions`や`solid_queue_scheduled_executions`などのテーブルが含まれます。

最後に、キューを開始してジョブの処理を開始するには、次のコマンドを実行します。

```bash
bin/jobs start
```

#### production環境の場合

Solid Queueはすでにproduction環境用に設定済みです。`config/environments/production.rb`ファイルを開くと、以下の内容が設定済みであることがわかります。

```ruby
# config/environments/production.rb
# Active Jobのデフォルトのキューイングバックエンド（インプロセスかつ永続化されない）を置き換える
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

さらに、`queue`データベースで利用するデータベースコネクションは、`config/database.yml`ファイルで設定されます。

```yaml
# config/database.yml
# production環境のデータベースは、デフォルトでstorage/ ディレクトリに保存される
# このディレクトリは、デフォルトでconfig/deploy.ymlで永続的なDockerボリュームとしてマウントされる
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
```

### 設定オプション

Solid Queueの設定オプションは`config/queue.yml`で定義します。
以下はデフォルト設定の例です。

```yaml
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

Solid Queueの設定オプションを理解するには、さまざまな種類のロール（role: 役割）を理解しておく必要があります。

- **ディスパッチャ**（dispatcher）: 今後実行するようにスケジュールされているジョブを選択します。
  これらのジョブを実行する時刻になったら、ディスパッチャはそれらのジョブを`solid_queue_scheduled_executions`テーブルから`solid_queue_ready_executions`テーブルに移動し、ワーカーがジョブを取得できるようにします。また、コンカレンシー関連のメンテナンスも管理します。

- **ワーカー**（worker）: 実行準備が整ったジョブを`solid_queue_ready_executions`テーブルから取得します。

- **スケジューラ**（scheduler）: 定期的なタスクを処理し、期限が来たらジョブをキューに追加します。

- **スーパーバイザ**（supervisor）: システム全体を監視して、ワーカーとディスパッチャを管理します。
  必要に応じてワーカーやディスパッチャを開始・停止し、健全性を監視し、すべてがスムーズに実行されるようにします。

`config/queue.yml`の設定は、すべてがオプションです（つまり必須項目はありません）。設定が指定されていない場合、Solid Queueはデフォルト設定で1つのディスパッチャーと1つのワーカーで実行されます。

以下は、`config/queue.yml`で設定できる設定オプションの一部です。

* `polling_interval`: ディスパッチャーやワーカーが次のジョブをチェックするまでの待ち時間を秒で指定します。
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

* `processes`: スーパーバイザによってforkされるワーカープロセスの個数を指定します。
  各プロセスはCPUコアを専有できます。
  デフォルト値は1です。

* `concurrency_maintenance`: ディスパッチャがコンカレンシーメンテナンス作業を行うかどうかを指定します。
  デフォルト値は`true`です。

設定オプションについて詳しくは、[Solid Queueのドキュメント](https://github.com/rails/solid_queue?tab=readme-ov-file#configuration)を参照してください。
また、`config/<environment>.rb`で設定できる[追加の設定オプション](https://github.com/rails/solid_queue?tab=readme-ov-file#other-configuration-settings)を使うことで、RailsアプリケーションでSolid Queueをさらに詳細に設定できます。

### キューの順序

設定の`queues`オプションには、後述する[設定](#configuration)のオプションに沿って、ワーカーがジョブを選択するキューのリストを記述します。キューのリストでは、キューの順序が重要です。ワーカーはリストの最初のキューからジョブを選択し、最初のキューにジョブがなくなると、2番目のキューに移動し、以下同様に繰り返します。

```yaml
# config/queue.yml
production:
  workers:
    - queues:[active_storage*, mailers]
      threads: 3
      polling_interval: 5
```

上の例では、ワーカーは最初に「active_storage」で始まるキュー（`active_storage_analyse`キューや`active_storage_transform`キューなど）からジョブを取得します。「active_storage」で始まるキューにジョブが残っていない場合にのみ、ワーカーは`mailers`キューに移動します。

NOTE: ワイルドカード`*`の利用は、「単独」または「キュー名の末尾に配置することで同じプレフィックスを持つすべてのキューに一致させる」形（`active_storage*`など）のみが可能です。`*_some_queue`などのようなキュー名の冒頭への追加はできません。

WARNING: `queues: active_storage*`のようにキュー名でワイルドカードを利用すると、マッチするすべてのキューを識別するために`DISTINCT`クエリが必要になるため、ポーリングのパフォーマンスが低下して大きなテーブルでは遅くなる可能性があります。パフォーマンスを落とさないためには、ワイルドカードを使わずに正確なキュー名を指定することが推奨されます。

Active Jobは、ジョブをエンキューするときに正の整数の優先度をサポートします（後述の[優先度](#priority)セクションを参照）。 1件のキュー内では、優先度に基づいてジョブが選択されます（整数が小さいほど優先度が高くなります）。

ただしキューが複数ある場合は、キュー自体の順序が優先されます。たとえば、`production`と`background`という2つのキューがこの順序で設定されている場合、場合、`background`キュー内の一部のジョブの優先度の方が高い場合でも、`production`キュー内のジョブが常に最初に処理されます。

### スレッド、プロセス、シグナル

Solid Queueの並列処理は、**スレッド**（[`threads`](#configuration)パラメータで設定可能）、**プロセス**（[`processes`](#configuration)パラメータで設定可能）、または**水平スケーリング**によって実現されます。

スーパーバイザーはプロセスを管理し、以下のシグナルに応答します。

- **TERM**、**INT**: 正常な終了処理を開始し、`TERM`シグナルを送信して`SolidQueue.shutdown_timeout`に達するまで待機します。
  終了しない場合は、`QUIT`シグナルでプロセスを強制終了します。

- **QUIT**: プロセスを強制的に即時終了します。

ワーカーが`KILL`シグナルなどによって予期せず強制終了された場合、実行中のジョブは失敗としてマークされ、`SolidQueue::Processes::ProcessExitError`や`SolidQueue::Processes::ProcessPrunedError`などのエラーが発生します。
ハートビート設定は、期限切れのプロセスを管理および検出するのに有用です。詳しくは[Solid Queueドキュメントの「スレッド、プロセス、シグナル」](https://github.com/rails/solid_queue?tab=readme-ov-file#threads-processes-and-signals)を参照してください。

### エンキュー時のエラー

Solid Queueは、ジョブのエンキュー中にActive Recordエラーが発生すると、`SolidQueue::Job::EnqueueError`を発生させます。このエラーは、Active Jobによって発生する`ActiveJob::EnqueueError`（エラーを処理して`perform_later`が`false`を返すようにする）とは異なることにご注意ください。このため、Railsや`Turbo::Streams::BroadcastJob`などのサードパーティgemによってエンキューされたジョブのエラー処理が複雑になります。

定期的なタスクの場合、エンキュー中に発生したエラーはすべてログに出力されますが、エラーをraiseしません。詳しくは[Solid Queue ドキュメントの「エンキュー時のエラー」](https://github.com/rails/solid_queue?tab=readme-ov-file#errors-when-enqueuing)を参照してください。

### コンカレンシーの制御

Solid Queueは、Active Jobをコンカレンシー制御で拡張し、特定の種類のジョブや特定の引数を持つジョブの同時実行数を制限できるようにします。ジョブがこの制限を超えると、別のジョブが終了するか期間が終了するまでブロックされます。

```ruby
class MyJob < ApplicationJob
  limits_concurrency to: 2, key: ->(contact) { contact.account }, duration: 5.minutes

  def perform(contact)
    # ジョブのロジックを実行する
  end
end
```

上の例では、同じアカウントの2つの`MyJob`インスタンスのみが同時に実行されます。その後、ジョブの1つが完了するまで、他のジョブはブロックされます。

以下のように`group`パラメータを指定すると、異なるジョブタイプ間での同時実行を制御できます。たとえば、同じグループに属する2つの異なるジョブクラスは、まとめて同時実行が制限されます。

```ruby
class Box::MovePostingsByContactToDesignatedBoxJob < ApplicationJob
  limits_concurrency key: ->(contact) { contact }, duration: 15.minutes, group: "ContactActions"
end

class Bundle::RebundlePostingsJob < ApplicationJob
  limits_concurrency key: ->(bundle) { bundle.contact }, duration: 15.minutes, group: "ContactActions"
end
```

これにより、特定の連絡先（contact）に対して一度に実行できるジョブは、ジョブクラスにかかわらず1件だけになります。

詳しくは[Solid Queueドキュメントの「同時実行制御」](https://github.com/rails/solid_queue?tab=readme-ov-file#concurrency-controls)を参照してください。

### ジョブのエラー報告

利用しているエラートラッキングサービスがジョブエラーを自動的に報告しない場合は、Active Jobに手動でフックする形で報告できます。たとえば、`ApplicationJob`で以下のように`rescue_from`ブロックを追加できます。

```ruby
class ApplicationJob < ActiveJob::Base
  rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

Action Mailerを利用している場合は、以下のように`MailDeliveryJob`のエラーを個別に処理する必要があります。

```ruby
class ApplicationMailer < ActionMailer::Base
  ActionMailer::MailDeliveryJob.rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end
end
```

### ジョブのトランザクション整合性

Solid Queueは、デフォルトではメインアプリケーションとは別のデータベースを利用します。これにより、トランザクションの整合性に関する問題が回避され、トランザクションがコミットされた場合にのみジョブがエンキューされるようになります。

ただし、Solid Queueをアプリと同一のデータベースで利用する場合は、Active Jobの`enqueue_after_transaction_commit`オプションでトランザクションの整合性を有効にできます。このオプションは、ジョブごとに有効にすることも、以下のように`ApplicationJob`ですべてのジョブに対して有効にすることも可能です。

```ruby
class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true
end
```

また、Solid Queueジョブ用のデータベースコネクションを別途設定することで、トランザクションの整合性の問題を回避しながら、アプリと同一のデータベースを利用するようにSolid Queueを構成することも可能です。詳しくは[Solid Queueドキュメントの「トランザクションの整合性」](https://github.com/rails/solid_queue?tab=readme-ov-file#jobs-and-transactional-integrity)を参照してください。

### 定期的なタスク

Solid Queueは、cronジョブに似た定期的なタスクをサポートしています。定期タスクは設定ファイル（デフォルトでは`config/recurring.yml`）で定義され、特定の時間にスケジューリングできます。タスク設定の例を以下に示します。

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
このようにして、ジョブを定期実行したり、指定の時間に実行したりできます。

詳しくは[Solid Queueドキュメントの「定期タスク」](https://github.com/rails/solid_queue?tab=readme-ov-file#recurring-tasks)を参照してください。

### ジョブのトラッキングと管理

失敗したジョブの監視や管理を一元化するには、[`mission_control-jobs`](https://github.com/rails/mission_control-jobs)などのツールが有用です、ジョブのステータス、ジョブ失敗の理由、ジョブ再試行の動作に関する洞察を提供し、問題をより効果的にトラッキングして解決を支援します。

`mission_control-jobs`ツールを使うと、たとえば大きなファイルを処理するジョブがタイムアウトで失敗したときに、失敗を検査し、ジョブの引数や実行履歴を確認して、「再試行」「再キューイング」「破棄」のいずれかを決定するのに役立ちます。

キュー
------

Active Jobの[`queue_as`][]を使って、特定のキューに入っているジョブをスケジューリングできます。

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

以下のようにジョブごとにプレフィックスを設定することも可能です。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  self.queue_name_prefix = nil
  # ...
end

# これで`config.active_job.queue_name_prefix`の設定が上書きされ、
# 自分のジョブキューにプレフィックスが設定されなくなります
```

キュー名のプレフィックスのデフォルト区切り文字は'\_'です。
この区切り文字は、[`config.active_job.queue_name_delimiter`][]設定で変更できます。

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

`#queue_as`にブロックを渡すと、キューをそのジョブレベルで制御できます。渡されたブロックは、そのジョブのコンテキストで実行されるため、キュー名を返す必要があります（これにより`self.arguments`にアクセス可能になります）。

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

NOTE: [SOLID QUEUE以外の一部のバックエンド](#代替キューイングバックエンド
)では、リッスンするキューを指定する必要が生じることもあります。

[`config.active_job.queue_name_delimiter`]: configuring.html#config-active-job-queue-name-delimiter
[`config.active_job.queue_name_prefix`]: configuring.html#config-active-job-queue-name-prefix
[`queue_as`]: https://api.rubyonrails.org/classes/ActiveJob/QueueName/ClassMethods.html#method-i-queue_as

優先度
--------------

優先度（priority）を指定してジョブをスケジューリングするには、[`queue_with_priority`][]メソッドを使います。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_with_priority 10
  # ...
end
```

デフォルトのキューイングバックエンドであるSolid Queueは、キューの順序に基づいてジョブの優先順位を決定します。詳しくは前述の[キューの順序](#キューの順序)セクションを参照してください。
Solid Queueでキューの順序と優先度オプションを両方使っている場合、キューの順序が優先され、優先度オプションは個別のキュー内でのみ適用されます。

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
ProcessVideoJob.perform_later(Video.last)
```

以下のように`set`に`:priority`オプションを渡すことも可能です。

```ruby
MyJob.set(priority: 50).perform_later(record)
```

NOTE: 優先度の低い番号が、優先度の高い番号より先に実行されるか後に実行されるかは、アダプタの実装によって異なります。詳しくは利用しているバックエンドのドキュメントを参照してください。アダプタの作成者は、小さい番号ほど重要度が高いものとして扱うことが推奨されます。

[`queue_with_priority`]:
    https://api.rubyonrails.org/classes/ActiveJob/QueuePriority/ClassMethods.html#method-i-queue_with_priority

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

`perform_all_later`でジョブをキューに一括登録すると、個別のジョブでは`around_enqueue`などのコールバックがトリガーされなくなる点にご注意ください。
詳しくは[一括登録のコールバック](#一括登録のコールバック)を参照してください。

一括登録
--------------

[`perform_all_later`][]を使うことで、複数のジョブをキューに一括登録（bulk enqueue: バルクエンキュー）できます。一括登録により、Redisやデータベースなどのキューデータストアとのジョブの往復回数を減らせるので、同じジョブを個別に登録するよりもパフォーマンスが向上します。

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

`perform_all_later`は、正常にエンキューされたジョブの個数をログ出力します。たとえば、上の`Guest.all.map`の結果`guest_cleanup_jobs`が3個になった場合、`Enqueued 3 jobs to Async (3 GuestsCleanupJob)`とログ出力されます（エンキューがすべて成功した場合）。

`perform_all_later`の戻り値は`nil`です。これは、`perform_later`の戻り値が、エンキューされたジョブクラスのインスタンスであるのと異なる点にご注意ください。

[`perform_all_later`]:
  https://api.rubyonrails.org/classes/ActiveJob.html#method-c-perform_all_later

### 複数のActive Jobクラスをキューに登録する

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

### 一括登録のコールバック

`perform_all_later`でジョブをキューに一括登録すると、個別のジョブでは`around_enqueue`などのコールバックがトリガーされません。この振る舞いは、Active Recordの他の一括処理系メソッドと一貫しています。コールバックは個別のジョブに対して個々に実行されるので、`perform_all_later`メソッドが持つ一括処理の性質の恩恵を受けられません。

ただし、`perform_all_later`メソッドは、`ActiveSupport::Notifications`でサブスクライブできる[`enqueue_all.active_job`][]イベントをトリガーします。

ジョブのエンキューが成功したかどうかを知るには、[`successfully_enqueued?`][]メソッドを利用できます。

[`enqueue_all.active_job`]:
  active_support_instrumentation.html#enqueue-all-active-job
[`successfully_enqueued?`]:
  https://api.rubyonrails.org/classes/ActiveJob/Core.html#method-i-successfully_enqueued-3F

### キューバックエンドのサポート

`perform_all_later`によるキューへの一括登録（一括エンキュー）は、キューバックエンド側でのサポートが必要ですす。デフォルトのキューバックエンドであるSolid Queueは、`enqueue_all`で一括登録をサポートします。

Sidekiqなどの[他のバックエンド](#alternate-queuing-backends)には`push_bulk`メソッドがあり、大量のジョブをRedisにプッシュして、ラウンドトリップネットワークの遅延を防ぐようになっています。GoodJobも`GoodJob::Bulk.enqueue`メソッドで一括登録をサポートします。

キューへの一括登録がキューバックエンドでサポートされていない場合、`perform_all_later`はジョブを1件ずつキューに登録します。

Action Mailer
------------

最近のWebアプリケーションでよく実行されるジョブといえば、リクエスト・レスポンスサイクルの外でメールを送信することでしょう。これにより、ユーザーが送信を待つ必要がなくなります。Active JobはAction Mailerと統合されているので、非同期メール送信を手軽に行えます。

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

現在は、上を以下のように簡潔に書けます。

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
class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
  # あるオブジェクトを、サポートされているオブジェクト型を使用して、よりシンプルな表現形式に変換する。
  # 推奨される表現形式は、特定のキーを持つハッシュ。キーには基本型のみが利用可能。
  # カスタムシリアライザ型をこのハッシュに追加するには、`super`を呼ぶ必要がある。
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

ジョブで発生した例外が回復されなかった場合、このジョブは「失敗（failed）」と呼ばれます。

[`rescue_from`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

### 失敗したジョブをリトライまたは廃棄する

失敗したジョブは、それ用の設定を行わない限り自動ではリトライされません。

実行中に例外が発生したジョブは、以下のように[`retry_on`]でリトライすることも、[`discard_on`]で廃棄することもできます。

```ruby
class RemoteServiceJob < ApplicationJob
  retry_on CustomAppException # デフォルトは「3秒ずつ待って5回リトライする」

  discard_on ActiveJob::DeserializationError

  def perform(*args)
    # CustomAppExceptionかActiveJob::DeserializationErrorをraiseする可能性があるとする
  end
end
```

[`discard_on`]:
    https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-discard_on
[`retry_on`]:
    https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on

### デシリアライズ

GlobalIDによって`#perform`に渡された完全なActive Recordオブジェクトのシリアライズが可能になります。

ジョブがキューに登録された後で、`#perform`メソッドが呼び出される前に、渡されたレコードが削除された場合は、Active Jobは[`ActiveJob::DeserializationError`][]例外をraiseします。

[`ActiveJob::DeserializationError`]:
    https://api.rubyonrails.org/classes/ActiveJob/DeserializationError.html

ジョブをテストする
--------------

ジョブのテスト方法について詳しくは、[テスティングガイド](testing.html#ジョブをテストする)をご覧ください。

デバッグ
---------

ジョブがどこから来ているのかを把握したい場合は、[詳細なログ](debugging_rails_applications.html#詳細なエンキューログ)を有効にできます。

代替キューイングバックエンド
--------------------------

Active Jobでは、複数のキューイングバックエンド（Sidekiq、Resque、Delayed Job など）用の組み込みアダプタも利用できます。アダプタの最新リストについては[`ActiveJob::QueueAdapters`][]のAPIドキュメントを参照してください。

[`ActiveJob::QueueAdapters`]:
    https://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html

### バックエンドを設定する

キューイングバックエンドは、[`config.active_job.queue_adapter`][]で以下のように設定できます。



```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # 必ずアダプタのgemをGemfileに追加し、
    # アダプタ固有のインストールおよびデプロイメント手順を実行すること
    config.active_job.queue_adapter = :sidekiq
  end
end
```

以下のように、バックエンドをジョブごとに設定することも可能です。

```ruby
class GuestsCleanupJob < ApplicationJob
  self.queue_adapter = :resque
  # ...
end

# これで、このジョブは`resque`をバックエンドキューアダプタとして使い
# デフォルトのSolid Queueアダプタをオーバーライドする
```

[`config.active_job.queue_adapter`]:
    configuring.html#config-active-job-queue-adapter

### バックエンドを起動する

ジョブはRailsアプリケーションと並行して実行されるため、ほとんどのキューイングライブラリでは、ジョブ処理を機能させるために、Railsアプリの起動とは別に、ライブラリ固有のキューイングサービスも起動しておく必要があります。キューバックエンドの起動手順については、利用するライブラリのドキュメントを参照してください。

主なドキュメントの一覧を以下に示します（すべてを網羅しているわけではありません）。

- [Sidekiq](https://github.com/mperham/sidekiq/wiki/Active-Job)
- [Resque](https://github.com/resque/resque/wiki/ActiveJob)
- [Sneakers](https://github.com/jondot/sneakers/wiki/How-To:-Rails-Background-Jobs-with-ActiveJob)
- [Queue Classic](https://github.com/QueueClassic/queue_classic#active-job)
- [Delayed Job](https://github.com/collectiveidea/delayed_job#active-job)
- [Que](https://github.com/que-rb/que#additional-rails-specific-setup)
- [Good Job](https://github.com/bensheldon/good_job#readme)