Ruby on Rails 8.0 リリースノート
===============================

Rails 8.0の注目ポイント:

- [Kamal 2](https://kamal-deploy.org/)や[Thruster](https://github.com/basecamp/thruster)を使ったPaaS不要のデプロイにも対応
- [アセットパイプライン](/asset_pipeline.html)のデフォルトを[Sprockets](https://github.com/rails/sprockets)から[Propshaft](https://github.com/rails/propshaft)へ
- [認証機能ジェネレータ](https://github.com/rails/rails/issues/50446)の追加: `rails generate authentication`
- [SQLite](https://www.sqlite.org/)で本番環境用データベースも構築可能に: [&raquo; 関連動画（日本語字幕あり）](https://youtu.be/-cEn_83zRFw?list=PLHFP2OPUpCeb182aDN5cKZTuyjn3Tdbqx&t=2440)
- [SQLite](https://www.sqlite.org/)のみで双方向通信、キャッシュ、非同期処理などを実装可能に:
  - SQLiteのみで双方向通信が可能になる[Solid Cable](https://github.com/rails/solid_cable)
  - SQLiteのみでキャッシュが可能になる[Solid Cache](https://github.com/rails/solid_cache)
  - SQLiteのみで非同期処理が可能になる[Solid Queue](https://github.com/rails/solid_queue)

訳注: [Railsの公式ブログ](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required)などから注目ポイントを一部抜粋しています。

--------------------------------------------------------------------------------

Rails 8.0にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.2までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 8.0にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-2からrails-8-0へのアップグレード)を参照してください。

主要な機能
--------------

### Kamal 2

アプリケーションをデプロイするツールである[Kamal 2](https://kamal-deploy.org/)がRailsにプリインストールされました。Kamalを使うと、新品のLinuxマシンを`kamal setup`コマンド1つでアプリケーションサーバーやアクセサリサーバーに変えます。

Kamal 2には、[Kamal Proxy](https://github.com/basecamp/kamal-proxy)と呼ばれるプロキシも含まれています。これは、従来起動時に用いられていた汎用のTraefikオプションを置き換えたものです。

### Thruster

Dockerfileがアップグレードされ、[Thruster](https://github.com/basecamp/thruster)と呼ばれる新しいプロキシが含まれるようになりました。これはPuma Webサーバーの手前に配置され、X-Sendfileアクセラレーション、アセットキャッシュ、アセット圧縮を提供します。

### Solid Cable

[Solid Cable](https://github.com/rails/solid_cable)は、Redisに代わる pub/subサーバーとして機能し、アプリケーションからのWebSocketメッセージを、異なるプロセスに接続されたクライアントに中継します。Solid Cableは、送信されたメッセージをデフォルトで1日間データベースに保持します。

### Solid Cache

[Solid Cache](https://github.com/rails/solid_cache)は、特にHTMLフラグメントキャッシュを保存するためにRedisまたはMemcachedのいずれかを置き換えます。

### Solid Queue

[Solid Queue](https://github.com/rails/solid_queue)は、Redisと、Resque、Delayed Job、Sidekiqなどの独立したジョブ実行フレームワークを不要にします。

Solid Queueは、高パフォーマンス環境向けに`FOR UPDATE SKIP LOCKED`という新しいメカニズムを基盤としています（これはPostgreSQL 9.5で初めて導入され、現在ではMySQL 8.0以降でも利用可能）。Solid QueueはSQLiteでも動作します。

### Propshaft

[Propshaft](https://github.com/rails/propshaft)は、古いSprocketsシステムに代わってデフォルトのアセットパイプラインとなりました。

### 認証システムジェネレータ

認証システムジェネレータが追加されました（[#52328](https://github.com/rails/rails/pull/52328)）これを元にして、セッションベース、パスワードリセット可能、メタデータ追跡機能を持つ認証システムを構築できます。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.read_encrypted_secrets`を削除。

*   非推奨化されていた`rails/console/app`ファイルを削除

*   非推奨化されていた`rails/console/helpers`ファイルを削除。

*   `Rails::ConsoleMethods`によるRailsコンソール拡張のサポート（非推奨化済み）を削除。

### 非推奨化

*   `"rails/console/methods"`を`require`するサポートを非推奨化。

*   `STATS_DIRECTORIES`の変更を非推奨化。今後は`Rails::CodeStatistics.register_directory`に置き換えられる。

*   `bin/rake stats`を非推奨化。今後は`bin/rails stats`を使うこと。

### 主な変更点

*   `Regexp.timeout`がデフォルトで`1`に設定されるようになった（Regexp DoS攻撃に対するセキュリティ強化のため）。

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   `Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality`を削除。

### 非推奨化

*   ルーティング高速化のため、複数のパスを指定するルーティングを非推奨化。

### 主な変更

*   従来よりも安全かつ明示的なパラメータ処理メソッドである[`params#expect`](https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-expect)が導入されました。従来の`params.expect(table: [ :attr ])`をシンプルな`params.require(:table).permit(:attr)`に置き換えられます。

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

* `form_with`の`model:`引数に`nil`を渡す非推奨のサポートを削除。

* `tag`ビルダーで空のタグ要素にコンテンツを渡す非推奨のサポートを削除。

### 非推奨化

### 主な変更

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_record.commit_transaction_on_non_local_return`を削除。

*   非推奨化されていた`config.active_record.allow_deprecated_singular_associations_name`を削除。

*   Active Recordに登録されていないデータベースを探索するサポート（非推奨化）を削除。

*   `enum`をキーワード引数で定義するサポート（非推奨化済み）を削除。

*   非推奨化されていた`config.active_record.warn_on_records_fetched_greater_than`を削除。

*   非推奨化されていた`config.active_record.sqlite3_deprecated_warning`を削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::ConnectionPool#connection`を削除。

*   `cache_dump_filename`にデータベース名を渡すサポート（非推奨化済み）を削除。

*   `ENV["SCHEMA_CACHE"]`を設定するサポート（非推奨化済み）を削除。

### 非推奨化

*   `SQLite3Adapter`の`retries`オプションを非推奨化。今後は`timeout`を使うこと。

### 主な変更

*   新しいデータベースで`db:migrate`を実行すると、マイグレーションの実行前にスキーマが読み込まれるように変更された。以後の呼び出しでは、保留中のマイグレーションが実行される。
  （従来のようにマイグレーションを最初から実行する振る舞いが必要な場合は、`db:migrate:reset`を実行することで利用可能。**これはデータベースをドロップして再作成した後にマイグレーションを実行する**）

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

### 非推奨化

*    Active StorageでのAzureバックエンド利用を非推奨化。

### 主な変更

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActiveSupport::ProxyObject`を削除。

*   `attr_internal_naming_format`に`@`をプレフィックスとして設定するサポート（非推奨化済み）を削除。

*   `ActiveSupport::Deprecation#warn`に文字列の配列を渡すサポート（非推奨化済み）を削除。

### 非推奨化

*   `Benchmark.ms`を非推奨化。

*   加算や`since`で`Time`と`ActiveSupport::TimeWithZone`を混ぜることを非推奨化。

### 主な変更

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_job.use_big_decimal_serializer`を削除。

### 非推奨化

   `enqueue_after_transaction_commit`を非推奨化。

*   組み込みの`SuckerPunch`アダプタを非推奨化。今後は`sucker_punch` gemに含まれるアダプタを使うこと。

### 主な変更

Action Text
----------

変更点について詳しくは[Changelog][action-text]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Ruby on Railsガイド
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/8-0-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/8-0-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/8-0-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/8-0-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/8-0-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/8-0-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/8-0-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/8-0-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/8-0-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/8-0-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/8-0-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/8-0-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/8-0-stable/guides/CHANGELOG.md
