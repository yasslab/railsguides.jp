
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
Active Jobの主要な目的は、Railsアプリを即席で作成した直後でも使用できる、自前のジョブ管理インフラを持つことです。これにより、Delayed JobとResqueなどのように、さまざまなジョブ実行機能のAPIの違いを気にせずにジョブフレームワーク機能やその他のgemを搭載することができるようになります。バックエンドでのキューイング作業では、操作方法以外のことを気にせずに済みます。さらに、ジョブ管理フレームワークを切り替える際にジョブを書き直さずに済みます。


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

ジェネレータを使用したくないのであれば、`app/jobs`の下に自分でジョブファイルを作成することもできます。ジョブファイルでは必ず`ActiveJob::Base`を継承してください。

作成されたジョブは以下のようになります。

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    # 後で実行したい作業をここに書く
  end
end
```

### ジョブをキューに登録する

キューへのジョブ登録は以下のように行います。

```ruby
MyJob.perform_later record  # キューイングシステムがビジーでなくなり次第ジョブをキューに登録する
```

```ruby
MyJob.set(wait_until: Date.tomorrow.noon).perform_later(record)  # 明日正午に実行したいジョブをキューに登録する
```

```ruby
MyJob.set(wait: 1.week).perform_later(record) # 一週間後に実行したいジョブをキューに登録する
```

以上で終わりです。


ジョブを実行する
-------------

アダプタが設定されていない場合、ジョブは直ちに実行されます。

### バックエンド

Active Jobには、Sidekiq、Resque、Delayed Jobなどさまざまなキューイングバックエンドに接続できるアダプタがビルトインで用意されています。利用可能な最新のアダプタのリストについては、APIドキュメントの[ActiveJob::QueueAdapters](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html) を参照してください。

### バックエンドを変更する

キューイングバックエンドは自由に取り替えることができます。

```ruby
# 必ずアダプタgemをGemfileに追加し、アダプタごとに必要な
# インストールとデプロイ指示に従ってください。
Rails.application.config.active_job.queue_adapter = :sidekiq
```


キュー
------

多くのアダプタでは複数のキューを扱うことができます。Active Jobを使用することで、特定のキューに入っているジョブをスケジューリングすることができます。

```ruby
class GuestsCleanupJob < ActiveJob::Base
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

# app/jobs/guests_cleanup.rb
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end

# 以上で、production環境ではproduction_low_priorityというキューでジョブが
# 実行されるようになり、beta環境ではbeta_low_priorityというキューでジョブが実行されるようになります
#
```

ジョブを実行するキューをより詳細に制御したい場合は、#setに`:queue`オプションを追加することもできます。

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

そのジョブレベルにあるキューを制御するために、queue_asにブロックを渡すこともできます。与えられたブロックは、そのジョブのコンテキストで実行されます (従ってself.argumentsにアクセスできます)。そしてキュー名を返さなくてはなりません。

```ruby
class ProcessVideoJob < ActiveJob::Base
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # do process video
  end
end

ProcessVideoJob.perform_later(Video.last)
```


NOTE: 設定したキュー名をキューイングバックエンドが「リッスンする」ようにしてください。一部のバックエンドでは、リッスンするキューを指定する必要があるものがあります。


コールバック
---------

Active Jobは、ジョブのライフサイクルでのフックを提供します。これによりコールバックが利用できるので、ジョブのライフサイクルの間に特定のロジックをトリガできます。

### 利用可能なコールバック

* `before_enqueue`
* `around_enqueue`
* `after_enqueue`
* `before_perform`
* `around_perform`
* `after_perform`

### 使用法

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  before_enqueue do |job|
    # ジョブインスタンスで行なう作業
  end

  around_perform do |job, block|
    # 実行前に行なう作業
    block.call
    # 実行後に行なう作業
  end

  def perform
    # 後で行なう
  end
end
```


ActionMailer
------------

最近のWebアプリケーションでよく実行されるジョブといえば、リクエスト-レスポンスのサイクルの外でメールを送信することでしょう。これにより、ユーザーが送信を待つ必要がなくなります。Active JobはAction Mailerと統合されているので、非同期メール送信を簡単に行えます。

```ruby
# すぐにメール送信したい場合は#deliver_nowを使用
UserMailer.welcome(@user).deliver_now

# Active Jobを使用して後でメール送信したい場合は#deliver_laterを使用
UserMailer.welcome(@user).deliver_later
```


GlobalID
--------
Active JobではGlobalIDがパラメータとしてサポートされています。GlobalIDを使用すると、動作中のActive Recordオブジェクトをジョブに渡す際にクラスとidを指定する必要がありません。クラスとidを指定する従来の方法では、後で明示的にデシリアライズ (deserialize) する必要がありました。従来のジョブが以下のようなものだったとします。

```ruby
class TrashableCleanupJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

現在は以下のように簡潔に書くことができます。

```ruby
class TrashableCleanupJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

上のコードは、`ActiveModel::GlobalIdentification`をミックスインするすべてのクラスで動作します。このモジュールはActive Modelクラスにデフォルトでミックスインされます。


例外
----------

Active Jobでは、ジョブ実行時に発生する例外をキャッチする方法が1つ提供されています。

```ruby

class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
   # ここに例外処理を書く
  end

  def perform
    # 後で実行する処理を書く
  end
end
```