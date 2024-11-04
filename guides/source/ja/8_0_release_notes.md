Ruby on Rails 8.0 リリースノート
===============================

Rails 8.0の注目ポイント:
【TBD】

--------------------------------------------------------------------------------

Rails 8.0にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.2までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.2にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-2からrails-8-0へのアップグレード)を参照してください。

主要な機能
--------------

【TBD】

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.read_encrypted_secrets`を削除。

*   非推奨化されていた`rails/console/app`ファイルを削除

*   非推奨化されていた`rails/console/helpers`ファイルを削除。

*   `Rails::ConsoleMethods`によるRailsコンソール拡張のサポート（非推奨化済み）を削除。

### 非推奨化

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

### 主な変更

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

* `form_with`の`model:`引数に`nil`を渡すことが非推奨化された。

* `tag`ビルダーで空のタグ要素にコンテンツを渡すことが非推奨化された。

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

### 主な変更

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

### 非推奨化

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

### 主な変更

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_job.use_big_decimal_serializer`を削除。

### 非推奨化

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

Ruby on Rails ガイド
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
