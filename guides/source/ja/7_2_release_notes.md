**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Ruby on Rails 7.2 リリースノート
===============================

Rails 7.2の注目ポイント:

* devcontainer（development container）設定がオプションで利用可能になった
* ブラウザの最小バージョン指定がデフォルトで行われるようになった
* Ruby 3.1以上が必須になった
* PWA（Progressive Web Application）ファイルがデフォルトで生成されるようになった
* RuboCopおまかせルールがデフォルトで使われるようになった
* GitHub CIワークフローが新規アプリケーションでデフォルトで生成されるようになった
* Brakemanが新規アプリケーションでデフォルトで有効になった
* Pumaのスレッドカウントが新しいデフォルト値で改善された
* ジョブがトランザクション内でスケジューリングされないようになった
* トランザクションごとのコミットコールバックとロールバックコールバック
* YJITがデフォルトで有効（Ruby 3.3以降で実行する場合）
* Rails Guidesのページデザインを一新
* メモリ割り当てを最適化するjemallocをデフォルトでDockerファイルにセットアップ
* bin/setupを実行するとpuma-devの設定方法を提案するようになった

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/7-2-stable)を参照してください。


--------------------------------------------------------------------------------

Rails 7.2にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.2にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-1からrails-7-2へのアップグレード)を参照してください。

主要な機能
--------------

### アプリケーションでdevcontainerが設定可能になった

A [development container](https://containers.dev/)（以下devcontainer）を使うと、コンテナ環境をフル機能の開発環境として利用可能になります。

Rails 7.2から、アプリケーションでdevcontainer設定を生成する機能が追加されました。追加される設定には、`.devcontainer/`フォルダ内の`Dockerfile`ファイル、`docker-compose.yml`ファイル、`devcontainer.json`ファイルなどがあります。

デフォルトのdevcontainerには以下が含まれます。

* Redisコンテナ（KredisやAction Cableなどで利用）
* データベース（SQLite、Postgres、MySQL、またはMariaDB）
* ヘッドレスChromeコンテナ（システムテスト用）
* Active Storage（ローカルディスクを利用する設定、プレビュー機能が有効）

devcontainerを利用する新規アプリケーションを生成するには、以下のコマンドを実行します。

```bash
$ rails new myapp --devcontainer
```

既存のアプリケーション用にdevcontainer設定を生成するには、`devcontainer`コマンドが利用可能です。

```bash
$ rails devcontainer
```

詳しくは、[devcontainerガイド](getting_started_with_devcontainer.html)を参照してください。

### Add browser version guard by default

Rails now adds the ability to specify the browser versions that will be allowed to access all actions
(or some, as limited by `only:` or `except:`).

Only browsers matched in the hash or named set passed to `versions:` will be blocked if they're below the versions
specified.

This means that all other unknown browsers, as well as agents that aren't reporting a user-agent header, will be allowed access.

A browser that's blocked will by default be served the file in `public/406-unsupported-browser.html` with a HTTP status
code of "406 Not Acceptable".

Examples:

```ruby
class ApplicationController < ActionController::Base
  # Allow only browsers natively supporting webp images, web push, badges, import maps, CSS nesting + :has
  allow_browser versions: :modern
end

class ApplicationController < ActionController::Base
  # All versions of Chrome and Opera will be allowed, but no versions of "internet explorer" (ie). Safari needs to be 16.4+ and Firefox 121+.
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false }
end

class MessagesController < ApplicationController
  # In addition to the browsers blocked by ApplicationController, also block Opera below 104 and Chrome below 119 for the show action.
  allow_browser versions: { opera: 104, chrome: 119 }, only: :show
end
```

Newly generated applications have this guard set in `ApplicationController`.

For more information, see the [allow_browser](https://api.rubyonrails.org/classes/ActionController/AllowBrowser/ClassMethods.html#method-i-allow_browser)
documentation.

### Make Ruby 3.1 the new minimum version

Until now, Rails only dropped compatibility with older Rubies on new majors version.
We are changing this policy because it causes us to keep compatibility with long
unsupported versions of Ruby or to bump the Rails major version more often, and to
drop multiple Ruby versions at once when we bump the major.

We will now drop Ruby versions that are end-of-life on minor Rails versions at the time of the release.

For Rails 7.2, Ruby 3.1 is the new minimum version.

### Default Progressive Web Application (PWA) files

In preparation to better supporting the creation of PWA applications with Rails, we now generate default PWA files for the manifest
and service worker, which are served from `app/views/pwa` and can be dynamically rendered through ERB. Those files
are mounted explicitly at the root with default routes in the generated routes file.

For more information, see the [pull request adding the feature](https://github.com/rails/rails/pull/50528).

### Add omakase RuboCop rules by default

Rails applications now come with [RuboCop](https://rubocop.org/) configured with a set of rules from [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase) by default.

Ruby is a beautifully expressive language that not only tolerates many different dialects, but celebrates their
diversity. It was never meant as a language to be written exclusively in a single style across all libraries,
frameworks, or applications. If you or your team has developed a particular house style that brings you joy,
you should cherish that.

This collection of RuboCop styles is for those who haven't committed to any specific dialect already. Who would just
like to have a reasonable starting point, and who will benefit from some default rules to at least start a consistent
approach to Ruby styling.

These specific rules aren't right or wrong, but merely represent the idiosyncratic aesthetic sensibilities of Rails'
creator. Use them whole, use them as a starting point, use them as inspiration, or however you see fit.

### Add GitHub CI workflow by default to new applications

Rails now adds a default GitHub CI workflow file to new applications. This will get especially newcomers off to a good
start with automated scanning, linting, and testing. We find that a natural continuation for the modern age of what
we've done since the start with unit tests.

It's of course true that GitHub Actions are a commercial cloud product for private repositories after you've used the
free tokens. But given the relationship between GitHub and Rails, the overwhelming default nature of the platform for
newcomers, and the value of teaching newcomers good CI habits, we find this to be an acceptable trade-off.

### Add Brakeman by default to new applications

[Brakeman](https://brakemanscanner.org/) is a great way to prevent common security vulnerabilities in Rails from going
into production.

New applications come with Brakeman installed and combined with the GitHub CI workflow, it will run automatically on
every push.

### Set a new default for the Puma thread count

Rails changed the default number of threads in Puma from 5 to 3.

Due to the nature of well-optimized Rails applications, with quick SQL queries and slow 3rd-party calls running via jobs,
Ruby can spend a significant amount of time waiting for the Global VM Lock (GVL) to release when the thread count is too
high, which is hurting latency (request response time).

After careful consideration, investigation, and based on battle-tested experience from applications running in
production, we decided that a default of 3 threads is a good balance between concurrency and performance.

You can follow a very detailed discussion about this change in [the issue](https://github.com/rails/rails/issues/50450).

### Prevent jobs from being scheduled within transactions

A common mistake with Active Job is to enqueue jobs from inside a transaction, causing them to potentially be picked
and ran by another process, before the transaction is committed, which result in various errors.

```ruby
Topic.transaction do
  topic = Topic.create

  NewTopicNotificationJob.perform_later(topic)
end
```

Now Active Job will automatically defer the enqueuing to after the transaction is committed, and drop the job if the
transaction is rolled back.

Various queue implementations can chose to disable this behavior, and users can disable it, or force it on a per job
basis:

```ruby
class NewTopicNotificationJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end
```

### Per transaction commit and rollback callbacks

This is now possible due to a new feature that allows registering transaction callbacks outside of a record.

`ActiveRecord::Base.transaction` now yields an `ActiveRecord::Transaction` object, which allows registering callbacks
on it.

```ruby
Article.transaction do |transaction|
  article.update(published: true)

  transaction.after_commit do
    PublishNotificationMailer.with(article: article).deliver_later
  end
end
```

`ActiveRecord::Base.current_transaction` was also added to allow to register callbacks on it.

```ruby
Article.current_transaction.after_commit do
  PublishNotificationMailer.with(article: article).deliver_later
end
```

And finally, `ActiveRecord.after_all_transactions_commit` was added, for code that may run either inside or outside a
transaction and needs to perform work after the state changes have been properly persisted.

```ruby
def publish_article(article)
  article.update(published: true)

  ActiveRecord.after_all_transactions_commit do
    PublishNotificationMailer.with(article: article).deliver_later
  end
end
```

See [#51474](https://github.com/rails/rails/pull/51474) and [#51426](https://github.com/rails/rails/pull/51426) for more information:

### Enable YJIT by default if running Ruby 3.3+

YJIT is Ruby's JIT compiler that is available in CRuby since Ruby 3.1. It can provide significant performance
improvements for Rails applications, offering 15-25% latency improvements.

In Rails 7.2, YJIT is enabled by default if running Ruby 3.3 or newer.

You can disable YJIT by setting:

```ruby
Rails.application.config.yjit = false
```

### New design for the Rails guides

When Rails 7.0 landed in December 2021, it came with a fresh new homepage and a new boot screen. The design of the
guides, however, has remained largely untouched since 2009 - a point which hasn’t gone unnoticed (we heard your feedback).

With all of the work right now going into removing complexity from the Rails framework and making the documentation
consistent, clear, and up-to-date, it was time to tackle the design of the guides and make them equally modern, simple,
and fresh.

We worked with UX designer [John Athayde](https://meticulous.com/) to take the look and feel of the homepage and
transfer that over to the Rails guides to make them clean, sleek, and up-to-date.

The layout will remain the same, but from today you will see the following changes reflected in the guides:

* Cleaner, less busy design.
* Fonts, color scheme, and logo more consistent with the home page.
* Updated iconography.
* Simplified navigation.
* Sticky "Chapters" navbar when scrolling.

See the [announcement blog post for some before/after images](https://rubyonrails.org/2024/3/20/rails-guides-get-a-facelift).

### Setup jemalloc in default Dockerfile to optimize memory allocation

[Ruby's use of `malloc` can create memory fragmentation problems, especially when using multiple threads](https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html)
like Puma does. Switching to an allocator that uses different patterns to avoid fragmentation can decrease memory usage
by a substantial margin.

Rails 7.2 now includes [jemalloc](https://jemalloc.net/) in the default Dockerfile to optimize memory allocation.

### Suggest puma-dev configuration in bin/setup

[Puma-dev](https://github.com/puma/puma-dev) is the golden path for developing multiple Rails applications locally, if you're not using Docker.

Rails now suggests how to get that setup in a new comment you'll find in `bin/setup`.

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
