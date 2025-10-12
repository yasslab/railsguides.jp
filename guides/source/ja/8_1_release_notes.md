Ruby on Rails 8.1 リリースノート
===============================

Rails 8.1 の注目ポイント:

--------------------------------------------------------------------------------

Rails 8.1にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 8.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 8.1にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-8-0からrails-8-1へのアップグレード)を参照してください。

主要な機能
--------------

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

* 非推奨化されていた`rails/console/methods.rb`ファイルを削除。

* 非推奨化されていた`bin/rake stats`コマンドを削除。

* 非推奨化されていた`STATS_DIRECTORIES`グローバル定数を削除。

### 非推奨化

### 主な変更

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

*   パラメータパーサー内で、パラメータ名の冒頭に含まれるブラケット`[]`をスキップするサポート（非推奨化）を削除。

    削除前:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "foo" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "foo" => { "bar" => "baz" } }
    ```

    削除後:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "[foo]" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "[foo]" => { "bar" => "baz" } }
    ```

*   セミコロンをクエリ文字列パラメータとして利用するサポート（非推奨化）を削除。

    削除前:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar"], ["baz", "quux"]]
    ```

    削除後:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar;baz=quux"]]
    ```

*   複数パスへのルーティング（非推奨化）を削除。

### 非推奨化

*   `Rails.application.config.action_dispatch.ignore_leading_brackets`を非推奨化。

### 主な変更

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

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

*   SQLite3アダプタで非推奨化されていた`:retries`オプションを削除。

*   MySQL用の非推奨化された`:unsigned_float`および`:unsigned_decimal`カラムメソッドを削除。

### 非推奨化

### 主な変更

*   `schema.rb`内のテーブルカラムのソート順がアルファベット順に変更された（[#53281](https://github.com/rails/rails/pull/53281)）。

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

*   非推奨化されていた`:azure`ストレージサービスを削除。

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

*   `Time#since`にTimeオブジェクトを渡せるサポート（非推奨化）を削除。

*   非推奨化されていた`Benchmark.ms`メソッドを削除。現在は`benchmark` gem内で定義されている。

*   `Time`インスタンスと`ActiveSupport::TimeWithZone`を加算できる機能（非推奨化）を削除。

*   `to_time`メソッドがシステムのローカル時間を保持するサポート（非推奨化）を削除。今後は常にレシーバーのタイムゾーンを保持する。

### 非推奨化

*   `config.active_support.to_time_preserves_timezone`を非推奨化。

### 主な変更

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   `ActiveJob::Base.enqueue_after_transaction_commit`に`:never`、`:always`、 `:default`を設定するサポートを削除。

*   非推奨化されていた`Rails.application.config.active_job.enqueue_after_transaction_commit`を削除。

*   非推奨化されていた組み込み`SuckerPunch`アダプタを削除。今後は`sucker_punch` gemに含まれるアダプタを使うこと。

### 非推奨化

*   Active Jobのカスタムシリアライザには`#klass` publicメソッドを含めなければならない。

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

Ruby on Rails Guides
--------------------

+変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

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