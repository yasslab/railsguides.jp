**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Rails のスレッドとコード実行
=====================================

このガイドの内容:

* Railsで自動的にコンカレント実行されるコード
* rails内部の手動コンカレンシーを統合する方法
* アプリケーションの全コードをラップする方法
* アプリケーションの再読み込みへの影響

--------------------------------------------------------------------------------

自動コンカレンシー
---------------------

Railsでは同時に複数の操作を自動的に実行することができます。

スレッド化Webサーバー（RailsデフォルトのPumaなど）を用いると、複数のHTTPリクエストが同時に扱われ、各リクエストはコントローラの独自のインスタンスに渡されます。

スレッド化Active Jobアダプタ（Rails組み込みのAsyncなど）も、同様に複数のジョブを同時実行します。Action Cableも同様に管理されます。

これらの仕組みはすべてマルチスレッドに関連します。各スレッドは、グローバルなプロセス空間（クラス、クラスの設定、グローバル変数など）を共有しつつ、何らかのオブジェクト（コントローラ/ジョブ/チャンネル）固有のインスタンスの動作を管理します。共有情報が変更されない限り、他のスレッドの存在はほとんど無視されます。

本ガイドでは、Railsが「他のスレッドをほとんど無視できるようにする」仕組みと、拡張機能や特殊な用途に用いられるアプリケーションでスレッドが使われる仕組みについて解説します。

Executor
--------

Railsの「Executor」は、アプリケーションのコードをフレームワークのコードから切り離します。自分の書いたアプリケーションのコードがフレームワークで呼び出されるたびに、Executorによってラップされます。

Executorは`to_run`と`to_complete`という2つのコールバックでできています。Runコールバックはアプリケーションのコードが実行される前に呼び出され、Completeコールバックはアプリケーションのコードの実行後に呼び出されます。

### デフォルトのコールバック

デフォルトのRailsアプリケーションでは、Executorのコールバックを以下の用途に用います。

* 自動読み込みや再読み込みを安全に行えるスレッドがどれかをトラッキングする
* Active Recordクエリキャッシュをオン/オフする
* 獲得したActive Recordコネクションをコネクションプールに返す
* 内部キャッシュの寿命を制限する

Rails 5.0より前は、これらの一部をRackミドルウェアのクラス（`ActiveRecord::ConnectionAdapters::ConnectionManagement`）で扱ったり、`ActiveRecord::Base.connection_pool.with_connection`などのメソッドで直接ラップしていました。Executorはこれらをより抽象度の高い単一のインターフェイスで置き換えました。

### アプリケーションのコードのラップ

アプリケーションのコードを呼び出す何らかのライブラリやコンポーネントを書く場合は、次のように`executor`呼び出しでラップすべきです。


```ruby
Rails.application.executor.wrap do
  # アプリケーションのコードをここで呼び出す
end
```

TIP: 長時間実行されるプロセスからアプリケーションのコードを呼ぶ場合は、代わりに`Reloader`でラップするとよいでしょう。

各スレッドは、アプリケーションのコードを実行する前にこのようにラップされるべきです。これにより、アプリケーションで何らかの作業を他のスレッドに手動で委譲する場合（`Thread.new`を使うなど）や、Concurrent Rubyのスレッドプールを用いる場合は、そのブロックをただちにラップすべきです。

```ruby
Thread.new do
  Rails.application.executor.wrap do
    # ここにコードを書く
  end
end
```

NOTE: Concurrent Rubyで使われる`ThreadPoolExecutor`に`executor`オプションが設定されていることがありますが、これはその名に反してExecutorとは関係ありません。

Executorは安全に「リエントラント」できます。現在のスレッドで既にアクティブになっている場合、`wrap`は何も実行しません。

アプリケーションのコードをブロックで囲むと実用上問題がある場合（Rack APIで問題が生じる場合など）は、次のように`run!`と`complete!`を組み合わせる方法が使えます。

```ruby
Thread.new do
  execution_context = Rails.application.executor.run!
  # ここにコードを書く
ensure
  execution_context.complete! if execution_context
end
```

### コンカレンシー

Executorは現在のスレッドをLoad Interlockで`running`モードに設定します。別のスレッドが定数を読み出し中の場合や、アプリケーションでアンロード/リロードが発生中の場合は、この操作が一時的にブロックされます。

Reloader
--------

Reloaderは、Executorと同じようにアプリケーションのコードをラップします。現在のスレッドでExecutorが既にアクティブでなくなった場合は、Reloaderが呼び出しを行いますので、呼び出す必要があるのはいずれか1つだけです。また、これによってReloaderのすべての挙動（あらゆるコールバック呼び出しを含む）がExecutor内部で行われることも保証されます。


```ruby
Rails.application.reloader.wrap do
  # アプリケーションのコードをここに書く
end
```

Reloaderは、フレームワークレベルで長時間実行されるプロセスがアプリケーションのコードを繰り返し呼び出す場合（Webサーバーやジョブキューなど）にのみ適しています。RailsはWebリクエストやActive Jobワーカーを自動的にラップするので、Reloaderを手動で呼び出す必要はめったにありません。Executorの方が自分のユースケースにふさわしい可能性があることを常に検討しましょう。

### コールバック

Reloaderは、ラップされたブロックが実行される前に、現在実行中のアプリケーションを再読み込みする必要があるかどうか（モデルのソースコードファイルが変更された場合など）をチェックします。再読み込みが必要と判断されると、Reloaderは安全になるまで待機してから再読み込みを行い、それから実行を継続します。変更が行われたかどうかにかかわらず常に再読み込みを行うようアプリケーションが設定されている場合は、ブロックの末尾で再読み込みを実行します。

Reloaderにも`to_run`コールバックと`to_complete`コールバックが備わっており、呼び出される箇所もExecutorと同じですが、現在実行中にアプリケーションで再読み込みが始まった場合にのみ実行される点が異なります。再読み込みが不要とみなされた場合、Reloaderはラップされたブロックの呼び出しでその他のコールバックを実行しません。

### クラスのアンロード

再読み込みプロセスで最も重要な部分は、クラスのアンロードです。このとき、自動読み込みされたクラスがすべて削除され、再度読み込み可能な状態になります。クラスのアンロードは、`reload_classes_only_on_change`設定に応じて、RunコールバックやCompleteコールバックの直前で即座に行われます。

クラスのアンロードの直前や直後にさらに何らかの再読み込みが必要になることがよくあるので、Reloaderには`before_class_unload`コールバックや`after_class_unload`コールバックも備わっています。

### コンカレンシー

Reloaderを呼び出す箇所は、長時間実行される「トップレベル」プロセスに限定すべきです。そうすることで、再読み込みが必要と判断された場合に、他の全スレッドがExecutor呼び出しを完了するまでブロックされるようになるからです。

万一Reloadの呼び出しが「子」スレッドで発生し、かつExecutor内部で親スレッドが待ち状態になっていると、回避できないデッドロックが発生する可能性があります。再読み込みは子スレッド実行前に行われなければならないにもかかわらず、親スレッドの実行中は安全に再読み込みできないからです。子スレッドではreloaderではなくExcecutorを使うべきです。

フレームワークの挙動
------------------

Railsフレームワークのコンポーネントでは、Rails自身で必要になるコンカレンシーを管理するためにもこのツールが用いられています。

Rackミドルウェアである`ActionDispatch::Executor`と`ActionDispatch::Reloader`は、それぞれExecutorとReloaderでリクエストをラップします。2つのRackミドルウェアはデフォルトのアプリケーションスタックに自動的にインクルードされます。Reloaderは、コードが変更されたときに常に新しく読み込まれたアプリケーションでHTTPリクエストを扱えるようにします。

Active Jobでもジョブ実行をReloaderでラップし、キューに積まれた各ジョブを実行するときに最新のコードが読み込まれるようにします。

Action CableではReloaderではなくExecutorが使われます。Action Cableコネクションはクラスの特定のインスタンスに結び付けられており、websocketメッセージが到着するたびに再読み込みすることが不可能なためです。Action Cableではメッセージハンドラのみがラップされるので、長時間実行されるAction Cable接続でも、新しく到着したリクエストやジョブによってトリガされる再読み込みは妨げられません。クライアントが自動的に再接続すると、そのことが新バージョンのコードに伝わります。

上記はフレームワークのエントリポイントなので、それぞれのコンポーネントは自身のスレッド群が保護されていることを確認し、再読み込みが必要かどうかを決定する責務を負います。その他のコンポーネントは、追加のスレッドを生成するためだけにExecutorを必要とします。

### 設定

Reloaderは、`cache_classes`が`false`かつ`reload_classes_only_on_change`が`true`の場合（`development`のデフォルト設定）にのみファイルの変更をチェックします。

`cache_classes`が`true`（`production`のデフォルト設定）の場合、ReloaderはExecutorへのパススルーのみを行います。

Executorは、データベース接続の管理などの重要な作業を常に抱えています。`cache_classes`と`eager_load`がどちらも`true`（`production`）の場合、自動読み込みやクラスの再読み込みは発生しなくなるため、Load Interlockは不要になります。`cache_classes`と`eager_load`のいずれかが`false`（`development`）の場合、ExecutorはLoad Interlockを用いて安全な場合にのみ定数を読み込みます。

Load Interlock
--------------

Load Interlockは、マルチスレッド実行環境での自動読み込みや再読み込みを有効にできます。

あるスレッドが、該当するファイルのクラス定義が評価されたことで自動読み込みを実行している場合、他のスレッドで定義の中途半端な定数が参照されないようにすることが重要です。

同様に、実行中のアプリケーションコードがない場合にのみアンロード/リロードを実行しないと安全を保てません。そうしないと、再読み込み後にたとえば`User`定数が別のクラスを指してしまう可能性があります。このルールがないと、再読み込みのタイミングがまずければ`User.new.class == User`どころか`User == User`すら`false`になってしまうかもしれません。

これらの制約を正すのがLoad Interlockです。Load Interlockは、どのスレッドがアプリケーションのコードを実行中か、どのスレッドがクラスを読み込み中か、自動読込された定数をどのスレッドがアンロード中かを常にトラッキングします。

読み込みやアンロードは1度に1つのスレッドでしか行われないので、読み込みやアンロードを行うには、アプリケーションのコードを実行中のスレッドが存在しなくなるまで待たなければなりません。読み込みを実行するために待ち状態になっているスレッドがあるからといって、他のスレッドでの読み込みは阻止されません（実際はこれらのスレッドは協調動作するので、キューイングされた読み込みを個別のスレッドが実行してからすべてのスレッドが再開します）。

### `permit_concurrent_loads`

Executorは、ブロック期間中に`running`ロックを自動的に取得します。そして自動読み込みでは`load`ロックをアップグレードするタイミングが認識されており、その後再び`running`に戻します。

ただし、Executorブロック内で実行されるその他のブロッキング操作（アプリケーションの全コードを含む）では、不必要な`running`ロックが保持されることがあります。ある定数に他のスレッドが遭遇すると、その定数は自動読み込みされなければならないため、デッドロックの原因になることがあります。

たとえば、`User`が読み込まれていないと仮定すると、以下はデッドロックします。

```ruby
Rails.application.executor.wrap do
  th = Thread.new do
    Rails.application.executor.wrap do
      User # 内側のスレッドはここで待機する
           # 他のスレッドが実行中はUserを読み込めない
    end
  end

  th.join # 外側のスレッドは'running'を掴んだままここで待機する
end
```

外側のスレッドは`permit_concurrent_loads`メソッドを呼び出すことでこのデッドロックを防げます。このメソッドを呼ぶと、提供されたブロック内で自動読み込みされた可能性のある定数をそのスレッドが参照解決しないことが保証されます。この保証に合致する最も安全な手法は、このメソッド呼び出しを、可能な限りブロッキングされる呼び出しの近くに配置することです。


```ruby
Rails.application.executor.wrap do
  th = Thread.new do
    Rails.application.executor.wrap do
      User # 内側のスレッドは'load'ロックを取得し
           # Userを読み込んで続行できる
    end
  end

  ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
    th.join # 外側のスレッドはここで待機するがロックを保持しない
  end
end
```

Concurrent Rubyを用いる別の例は次のとおりです。

```ruby
Rails.application.executor.wrap do
  futures = 3.times.collect do |i|
    Concurrent::Future.execute do
      Rails.application.executor.wrap do
        # ここで何かする
      end
    end
  end

  values = ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
    futures.collect(&:value)
  end
end
```


### ActionDispatch::DebugLocks

デッドロックするアプリケーションでLoad Interlockが関与していると考えられる場合、一時的にActionDispatch::DebugLocksミドルウェアを`config/application.rb`に追加できます。

```ruby
config.middleware.insert_before Rack::Sendfile,
                                  ActionDispatch::DebugLocks
```

追加後アプリケーションを再起動してデッドロック条件を再度トリガすると、Load Interlockで現在認識されているすべてのスレッドと、それらが現在保持または待機しているロックのレベルと、それらの現在のバックトレースの概要を`/rails/locks`で表示できます。

デッドロックは一般に、Load Interlockが他の外部ロックやブロッキングI/O呼び出しと競合することで発生します。デッドロックに気づいたら、`permit_concurrent_loads`でラップできます。
