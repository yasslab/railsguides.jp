
Active Job の基礎
=================

本ガイドでは、バックグラウンドで実行するジョブの作成やキュー登録 (エンキュー: enqueue) 、実行方法について解説します。

このガイドの内容:

* ジョブの作成方法
* ジョブの登録方法
* バックグラウンドでのジョブ実行方法
* アプリケーションから非同期にメールを送信する方法

--------------------------------------------------------------------------------


はじめに
------------

Active Jobは、ジョブを宣言し、それによってバックエンドでさまざまな方法によるキュー操作を実行するためのフレームワークです。これらのジョブでは、定期的なクリーンアップを始めとして、請求書発行やメール配信など、どんなことでも実行できます。これらのジョブをより細かな作業単位に分割して並列実行することもできます。


Active Jobの目的
-----------------------------

Active Jobの主要な目的は、ジョブ管理インフラを設置することです。これにより、Delayed JobとResqueなどのように、さまざまなジョブ実行機能のAPIの違いを気にせずにジョブフレームワーク機能やその他のgemを搭載することができるようになります。バックエンドでのキューイング作業では、操作方法以外のことを気にせずに済みます。さらに、ジョブ管理フレームワークを切り替える際にジョブを書き直さずに済みます。

NOTE: デフォルトのRailsは非同期キューを実装します。これは、インプロセスのスレッドプールでジョブを実行します。ジョブは非同期に実行されますが、再起動するとすべてのジョブは失われます。


ジョブを作成する
--------------

このセクションでは、ジョブの作成方法とジョブの登録 (enqueue) 方法を手順を追って説明します。

### ジョブを作成する

Active Jobは、ジョブ作成用のRailsジェネレータを提供しています。以下を実行すると、`app/jobs`にジョブが1つ作成されます。

```bash
$ bin/rails generate job guests_cleanup
create  app/jobs/guests_cleanup_job.rb
```

以下のようにすると、特定のキューに対してジョブを1つ作成できます。

```bash
$ bin/rails generate job guests_cleanup --queue urgent
create  app/jobs/guests_cleanup_job.rb
```

上のように、Railsで他のジェネレータを使用するときとまったく同じ方法でジョブを作成できます。

ジェネレータを使用したくないのであれば、`app/jobs`の下に自分でジョブファイルを作成することもできます。ジョブファイルでは必ず`ApplicationJob`を継承してください。

作成されたジョブは以下のようになります。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # 後で実行したい作業をここに書く
  end
end
```

### ジョブをキューに登録する

キューへのジョブ登録は以下のように行います。

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
GuestsCleanupJob.perform_later(guest1, guest2, filter: 'some_filter')
```

以上で終わりです。


ジョブを実行する
-------------

production環境でのジョブのキュー登録と実行では、キューイングのバックエンドを設定しておく必要があります。具体的には、Railsで使うべきサードパーティのキューイングライブラリを決める必要があります。
Rails自身が提供するのは、ジョブをメモリに保持するインプロセスのキューイングシステムだけです。
プロセスがクラッシュしたりコンピュータをリセットしたりすると、デフォルトの非同期バックエンドの振る舞いによって主要なジョブが失われてしまいます。アプリが小規模な場合やミッションクリティカルでないジョブであればこれでも構いませんが、多くのproductionアプリでは永続的なバックエンドを選ぶ必要があります。

アダプタが設定されていない場合、ジョブは直ちに実行されます。

### バックエンド

Active Jobには、Sidekiq、Resque、Delayed Jobなどさまざまなキューイングバックエンドに接続できるアダプタがビルトインで用意されています。利用可能な最新のアダプタのリストについては、APIドキュメントの[ActiveJob::QueueAdapters](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html) を参照してください。

### バックエンドを変更する

キューイングバックエンドは自由に取り替えることができます。

```ruby
# 必ずアダプタgemをGemfileに追加し、アダプタごとに必要な
# インストールとデプロイ指示に従ってください
Rails.application.config.active_job.queue_adapter = :sidekiq
```

次のように、ジョブごとにバックエンドを設定することもできます。

```ruby
class GuestsCleanupJob < ApplicationJob
  self.queue_adapter = :resque
  #....
end

# これでジョブが`resque`を使うようになります
# `config.active_job.queue_adapter`で設定された内容が
# バックエンドキューアダプタでオーバーライドされるためです
```

### バックエンドを起動する

ジョブはRailsアプリに対して並列で実行されるので、多くのキューイングライブラリでは、ジョブを処理するためにライブラリ固有のキューイングサービスを（Railsアプリの起動とは別に）起動しておくことが求められます。キューのバックエンドの起動方法については、ライブラリのドキュメントを参照してください。

以下はドキュメントのリストの一部です。

- [Sidekiq](https://github.com/mperham/sidekiq/wiki/Active-Job)
- [Resque](https://github.com/resque/resque/wiki/ActiveJob)
- [Sneakers](https://github.com/jondot/sneakers/wiki/How-To:-Rails-Background-Jobs-with-ActiveJob)
- [Sucker Punch](https://github.com/brandonhilkert/sucker_punch#active-job)
- [Queue Classic](https://github.com/QueueClassic/queue_classic#active-job)

キュー
------

多くのアダプタでは複数のキューを扱うことができます。Active Jobを使用することで、特定のキューに入っているジョブをスケジューリングすることができます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end
```

`application.rb`で以下のように`config.active_job.queue_name_prefix`を使用することで、すべてのジョブでキュー名の前に特定の文字列を追加することができます。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end

# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end

# 以上で、production環境ではproduction_low_priorityというキューでジョブが
# 実行されるようになり、staging環境ではstaging.low_priorityというキューでジョブが実行されるようになります
```

キュー名のプレフィックスのデフォルト区切り文字は'\_'です。`application.rb`の`config.active_job.queue_name_delimiter`を設定することでこの区切り文字を変更できます。
 
```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = '.'
  end
end

# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end

# 以上で、production環境ではproduction_low_priorityというキューでジョブが
# 実行されるようになり、staging環境ではstaging.low_priorityというキューでジョブが実行されるようになります
```

ジョブを実行するキューをさらに細かく制御したい場合は、`:queue`オプションを`#set`に追加することもできます。

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

そのジョブレベルにあるキューを制御するために、queue_asにブロックを渡すこともできます。与えられたブロックは、そのジョブのコンテキストで実行されます (従ってself.argumentsにアクセスできます)。そしてキュー名を返さなくてはなりません。

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
    # Do process video
  end
end

ProcessVideoJob.perform_later(Video.last)
```


NOTE: 設定したキュー名をキューイングバックエンドが「リッスンする」ようにしてください。一部のバックエンドでは、リッスンするキューを指定する必要があるものがあります。


コールバック
---------

Active Jobが提供するフックを用いて、ジョブのライフサイクル中にロジックをトリガできます。これらのコールバックは、Railsの他のコールバックと同様に通常のメソッドとして実装し、マクロ風のクラスメソッドでコールバックとして登録できます。

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  around_perform :around_cleanup
  
  def perform
    # 後で行なう
  end

  private

  def around_cleanup(job)
    # performの直前に何か実行
    yield
    # performの直後に何か実行
  end
end
```

このマクロスタイルのクラスメソッドは、ブロックを1つ受け取ることもできます。ブロック内のコード量が1行以内に収まるほど少ない場合は、この書き方をご検討ください。
たとえば、登録されたジョブごとの測定値を送信する場合は次のようにします。

```ruby
class ApplicationJob
  before_enqueue { |job| $statsd.increment #{job.name.underscore}.enqueue" }
end
```

### 利用できるコールバック

* `before_enqueue`
* `around_enqueue`
* `after_enqueue`
* `before_perform`
* `around_perform`
* `after_perform`

ActionMailer
------------

最近のWebアプリケーションでよく実行されるジョブといえば、リクエスト-レスポンスのサイクルの外でメールを送信することでしょう。これにより、ユーザーが送信を待つ必要がなくなります。Active JobはAction Mailerと統合されているので、非同期メール送信を簡単に行えます。

```ruby
# すぐにメール送信したい場合は#deliver_nowを使用
UserMailer.welcome(@user).deliver_now

# Active Jobを使用して後でメール送信したい場合は#deliver_laterを使用
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

GlobalID
--------
Active JobではGlobalIDがパラメータとしてサポートされています。GlobalIDを使用すると、動作中のActive Recordオブジェクトをジョブに渡す際にクラスとidを指定する必要がありません。クラスとidを指定する従来の方法では、後で明示的にデシリアライズ (deserialize) する必要がありました。従来のジョブが以下のようなものだったとします。

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

現在は以下のように簡潔に書くことができます。

```ruby
class TrashableCleanupJob  < ApplicationJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

上のコードは、`ActiveModel::GlobalIdentification`をミックスインするすべてのクラスで動作します。このモジュールはActive Recordクラスにデフォルトでミックスインされます。


例外
----------

Active Jobでは、ジョブ実行時に発生する例外をキャッチする方法が1つ提供されています。

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

### 失敗したジョブをリトライまたは廃棄する

実行中に例外が発生したジョブのリトライや廃棄も行えます。次の例をご覧ください。

```ruby
class RemoteServiceJob < ApplicationJob
  retry_on CustomAppException # defaults to 3s wait, 5 attempts

  discard_on ActiveJob::DeserializationError

  def perform(*args)
    # CustomAppExceptionかActiveJob::DeserializationErrorをraiseする可能性があるとする
  end
end
```

詳しくは、[ActiveJob::Exceptions](http://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html) APIドキュメントを参照してください。

### デシリアライズ

GlobalIDの`#perform`に完全なActive Recordオブジェクトを渡してシリアライズできます。

ジョブがキューに登録された後で、渡したレコードが1件削除され、かつ`#perform`メソッドをまだ呼び出していない場合は、Active Jobによって`ActiveJob::DeserializationError`エラーがraiseされます。


ジョブをテストする
--------------

ジョブのテスト方法について詳しくは、[テスティングガイド](testing.html#ジョブをテストする)をご覧ください。
