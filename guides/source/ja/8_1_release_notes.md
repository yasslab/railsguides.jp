Ruby on Rails 8.1 リリースノート
===============================

Rails 8.1 の注目ポイント:

--------------------------------------------------------------------------------

Rails 8.1にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 8.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 8.1にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-8-0からrails-8-1へのアップグレード)を参照してください。

2

If you're upgrading an existing application, it's a great idea to have good test
coverage before going in. You should also first upgrade to Rails 8.0 in case you
haven't and make sure your application still runs as expected before attempting
an update to Rails 8.1. A list of things to watch out for when upgrading is
available in the
[Upgrading Ruby on Rails](upgrading_ruby_on_rails.html#upgrading-from-rails-8-0-to-rails-8-1)
guide.

Major Features
--------------

Railties
--------

Please refer to the [Changelog][railties] for detailed changes.

### Removals

*   Remove deprecated `rails/console/methods.rb` file.

*   Remove deprecated `bin/rake stats` command.

*   Remove deprecated `STATS_DIRECTORIES`.

### Deprecations

### Notable changes

Action Cable
------------

Please refer to the [Changelog][action-cable] for detailed changes.

### Removals

### Deprecations

### Notable changes

Action Pack
-----------

Please refer to the [Changelog][action-pack] for detailed changes.

### Removals

*   Remove deprecated support to skipping over leading brackets in parameter names in the parameter parser.

    Before:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "foo" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "foo" => { "bar" => "baz" } }
    ```

    After:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "[foo]" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "[foo]" => { "bar" => "baz" } }
    ```

*   Remove deprecated support for using semicolons as a query string separator.

    Before:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar"], ["baz", "quux"]]
    ```

    After:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar;baz=quux"]]
    ```

*   Remove deprecated support to a route to multiple paths.

### Deprecations

*   Deprecate `Rails.application.config.action_dispatch.ignore_leading_brackets`.

### Notable changes

Action View
-----------

Please refer to the [Changelog][action-view] for detailed changes.

### Removals

### Deprecations

### Notable changes

Action Mailer
-------------

Please refer to the [Changelog][action-mailer] for detailed changes.

### Removals

### Deprecations

### Notable changes

Active Record
-------------

Please refer to the [Changelog][active-record] for detailed changes.

### Removals

*   Remove deprecated `:retries` option for the SQLite3 adapter.

*   Remove deprecated `:unsigned_float` and `:unsigned_decimal` column methods for MySQL.

### Deprecations

### Notable changes

*   The table columns inside `schema.rb` are [now sorted alphabetically.](https://github.com/rails/rails/pull/53281)

Active Storage
--------------

Please refer to the [Changelog][active-storage] for detailed changes.

### Removals

*   Remove deprecated `:azure` storage service.

### Deprecations

### Notable changes

Active Model
------------

Please refer to the [Changelog][active-model] for detailed changes.

### Removals

### Deprecations

### Notable changes

Active Support
--------------

Please refer to the [Changelog][active-support] for detailed changes.

### Removals

*   Remove deprecated passing a Time object to `Time#since`.

*   Remove deprecated `Benchmark.ms` method. It is now defined in the `benchmark` gem.

*   Remove deprecated addition for `Time` instances with `ActiveSupport::TimeWithZone`.

*   Remove deprecated support for `to_time` to preserve the system local time. It will now always preserve the receiver
    timezone.

### Deprecations

*   Deprecate `config.active_support.to_time_preserves_timezone`.

### Notable changes

Active Job
----------

Please refer to the [Changelog][active-job] for detailed changes.

### Removals

*   Remove support to set `ActiveJob::Base.enqueue_after_transaction_commit` to `:never`, `:always` and `:default`.

*   Remove deprecated `Rails.application.config.active_job.enqueue_after_transaction_commit`.

*   Remove deprecated internal `SuckerPunch` adapter in favor of the adapter included with the `sucker_punch` gem.

### Deprecations

*   Custom Active Job serializers must have a public `#klass` method.

### Notable changes

Action Text
----------

Please refer to the [Changelog][action-text] for detailed changes.

### Removals

### Deprecations

### Notable changes

Action Mailbox
----------

Please refer to the [Changelog][action-mailbox] for detailed changes.

### Removals

### Deprecations

### Notable changes

Ruby on Rails Guides
--------------------

Please refer to the [Changelog][guides] for detailed changes.

### Notable changes

Credits
-------

See the
[full list of contributors to Rails](https://contributors.rubyonrails.org/)
for the many people who spent many hours making Rails, the stable and robust
framework it is. Kudos to all of them.

[railties]:       https://github.com/rails/rails/blob/8_1_stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/8_1_stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/8_1_stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/8_1_stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/8_1_stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/8_1_stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/8_1_stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/8_1_stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/8_1_stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/8_1_stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/8_1_stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/8_1_stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/8_1_stable/guides/CHANGELOG.md