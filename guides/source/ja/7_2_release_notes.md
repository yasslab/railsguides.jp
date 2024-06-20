**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Ruby on Rails 7.2 リリースノート
===============================

Rails 7.2の注目ポイント:

--------------------------------------------------------------------------------

Rails 7.2にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.2にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-1からrails-7-2へのアップグレード)を参照してください。

主要な機能
--------------

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails::Generators::Testing::Behaviour`を削除。

*   非推奨化されていた`Rails.application.secrets`を削除。

*   非推奨化されていた`Rails.config.enable_dependency_loading`を削除。

*   非推奨化されていた`find_cmd_and_exec`コンソールヘルパーを削除。

*   `rails new`コマンドや`rails db:system:change`コマンドから`oracle`、`sqlserver`、JRuby固有のデータベースアダプタのサポートを削除。

*   ジェネレータから`config.public_file_server.enabled`オプションを削除。

### 非推奨化

### 主な変更点

*   [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase) gemの`RuboCop`ルールを新規アプリケーションとプラグインの両方にデフォルトで追加。

*   `Brakeman`を新規アプリケーションにセキュリティチェック用デフォルト設定として追加。

*   `Dependabot`、`Brakeman`、`RuboCop`用のGitHub CIファイルを追加し、新規アプリケーションとプラグインの両方についてテストをデフォルトで実行するようになった。

*   YJITがRuby 3.3以降の新規アプリケーションでデフォルトで有効になった。

*   以下を実行することで`.devcontainer`フォルダが生成されるようになった（VS Codeでアプリケーションをコンテナ実行するのに用いられる）。

    ```bash
    $ rails new myapp --devcontainer
    ```

*   イニシャライザをテストする`Rails::Generators::Testing::Assertions#assert_initializer`が導入された。

*   新規アプリケーションのシステムテストでヘッドレスChromeがデフォルトで使われるようになった。

*   `BACKTRACE`環境変数で通常のサーバー実行時にバックトレースのクリーニングを無効にするサポートが追加された（従来はテスト時のみ利用可能だった）。

*   マニフェストおよびサービスワーカー用のPWA（Progressive Web App）ファイルがデフォルトで追加され、`app/views/pwa`から配信されるようになり、ERBで動的にレンダリング可能になった。

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActionDispatch::IllegalStateError`定数を削除。

*   非推奨化されていた`AbstractController::Helpers::MissingHelperError`定数を削除。

*   非推奨化されていた`ActionController::Parameters`と`Hash`の比較機能を削除。

*   非推奨化されていた`Rails.application.config.action_dispatch.return_only_request_media_type_on_content_type`を削除。

*   パーミッションポリシーの非推奨化されていた`speaker`、`vibrate`、`vr`ディレクティブを削除。

*   `Rails.application.config.action_dispatch.show_exceptions`の非推奨化されていた設定（`true`や`false`に設定可能）を削除。

### 非推奨化

*   `Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality`を非推奨化。

### 主な変更点

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

*   非推奨化されていた`@rails/ujs`が削除され、`Turbo`に置き換えられた。

### 非推奨化

* `tag.br`タグビルダーを使う場合に、void要素にコンテンツを渡すことが非推奨化された。

### 主な変更点

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.action_mailer.preview_path`を削除。

*   `assert_enqueued_email_with`で非推奨化されていた`:args`からのパラメータを削除。

### 非推奨化

### 主な変更点

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails.application.config.active_record.suppress_multiple_database_warning`を削除。

*   存在しない属性名を指定して`alias_attribute`を呼び出す非推奨化サポートを削除。

*   `ActiveRecord::Base.remove_connection`で非推奨化されていた`name`引数を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_active_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_reloadable_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_all_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.flush_idle_connections!`を削除。

*   非推奨化されていた`ActiveRecord::ActiveJobRequiredError`を削除。

*   コネクションアダプタで引数を2つ渡して`explain`を定義する非推奨化サポートを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.runtime`メソッドを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.runtime=`メソッドを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.reset_runtime`メソッドを削除。

*   非推奨化されていた`ActiveRecord::Migration.check_pending`メソッドを削除。

*   `ActiveRecord::MigrationContext`に`SchemaMigration`と`InternalMetadata`クラスを引数として渡す非推奨化サポートを削除。

*   単数形の関連付けを複数形の名前で参照する非推奨の振る舞いを削除。

*   非推奨化されていた`TestFixtures.fixture_path`を削除。

*   `ActiveRecord::Base#read_attribute(:id)`がカスタム主キー値を返す非推奨化サポートを削除。

*   `serialize`にコーダーやクラスを第2引数として渡す非推奨化サポートを削除。

*   データベースアダプタの非推奨化されていた`#all_foreign_keys_valid?`を削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::SchemaCache.load_from`を削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::SchemaCache#data_sources`を削除。

*   非推奨化されていた`#all_connection_pools`を削除。

*   `role`引数が指定されていない場合に、現在のロールのコネクションプールで`#connection_pool_list`、`#active_connections?`、`#clear_active_connections!`、`#clear_reloadable_connections!`、`#clear_all_connections!`、`#flush_idle_connections!`が適用される非推奨化サポートを削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::ConnectionPool#connection_klass`を削除。

*   非推奨化されていた`#quote_bound_value`を削除。

*   `ActiveSupport::Duration`を変換せずに式展開で渡せる非推奨化サポートを削除。

*   `add_foreign_key`に`deferrable: true`を渡す非推奨化サポートを削除。

*   `ActiveRecord::Relation#merge`に`rewhere`を渡す非推奨化サポートを削除。

*   トランザクションブロックを`return`、`break`、または`throw`で終了するとロールバックする非推奨化された振る舞いを削除。

### 非推奨化

*   `Rails.application.config.active_record.allow_deprecated_singular_associations_name`を非推奨化。

*   `Rails.application.config.active_record.commit_transaction_on_non_local_return`を非推奨化。

### 主な変更点

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_storage.replace_on_assign_to_many`を削除。

*   非推奨化されていた`config.active_storage.silence_invalid_content_types_warning`を削除。

### 非推奨化

### 主な変更点

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActiveSupport::Notifications::Event#children`と`ActiveSupport::Notifications::Event#parent_of?`を削除。

*   以下のメソッドをdeprecatorを渡さずに呼び出せる非推奨サポートを削除。

    - `deprecate`
    - `deprecate_constant`
    - `ActiveSupport::Deprecation::DeprecatedObjectProxy.new`
    - `ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy.new`
    - `ActiveSupport::Deprecation::DeprecatedConstantProxy.new`
    - `assert_deprecated`
    - `assert_not_deprecated`
    - `collect_deprecations`

*   非推奨化されていた`ActiveSupport::Deprecation`のインスタンスへの委譲を削除。

*   非推奨化されていた`SafeBuffer#clone_empty`を削除。

*   `#to_default_s` from `Array`、`Date`、`DateTime`、`Time`で非推奨化されていた`#to_default_s`を削除。

*   キャッシュストレージの非推奨化されていた`:pool_size`オプションと`:pool_timeout`オプションを削除。

*   非推奨化されていた`config.active_support.cache_format_version = 6.1`サポートを削除。

*   非推奨化されていた`ActiveSupport::LogSubscriber::CLEAR`定数と`ActiveSupport::LogSubscriber::BOLD`定数を削除。

*   ログテキストを`ActiveSupport::LogSubscriber#color`の位置引数ブーリアンで太字にする非推奨化サポートを削除。

*   非推奨化されていた`config.active_support.disable_to_s_conversion`を削除。

*   非推奨化されていた`config.active_support.remove_deprecated_time_with_zone_name`を削除。

*   非推奨化されていた`config.active_support.use_rfc4122_namespaced_uuids`を削除。

*   `MemCacheStore`に`Dalli::Client`インスタンスを渡せる非推奨化サポートを削除。

*   `to_time`のRuby 2.4以前の振る舞い（`to_time`がローカルタイムゾーンを持つ`Time`オブジェクトを返す）を削除。

### 非推奨化

*   `config.active_support.to_time_preserves_timezone`を非推奨化。

*   `DateAndTime::Compatibility.preserve_timezone`を非推奨化。

### 主な変更点

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   非推奨化されていた`BigDecimal`引数向けのプリミティブなシリアライザを削除。

*   `scheduled_at`属性に数値を設定できる非推奨化サポートを削除。

*   `retry_on`の`:wait`オプションの非推奨化された`:exponentially_longer`値を削除。

### 非推奨化

*   `Rails.application.config.active_job.use_big_decimal_serialize`を非推奨化。

### 主な変更点

Action Text
----------

変更点について詳しくは[Changelog][active-text]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Ruby on Rails Guides
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更点

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/7-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/7-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/7-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/7-2-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/7-2-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/7-2-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/7-2-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/7-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/7-2-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/7-2-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/7-2-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/7-2-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/7-2-stable/guides/CHANGELOG.md
