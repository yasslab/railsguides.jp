Ruby on Rails 6.1 リリースノート
===============================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Ruby on Rails 6.1 Release Notes](https://guides.rubyonrails.org/6_1_release_notes.html)を日本語に翻訳した文書です。

Rails 6.1の注目ポイント:

* データベース単位のコネクション切り替え
* 水平シャーディング
* 関連付けのstrict loading
* Delegated Types
* 関連付けの非同期削除

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/6-1-stable)を参照してください。

--------------------------------------------------------------------------------

Rails 6.1へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 6.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 6.1にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-6-0からrails-6-1へのアップグレード)を参照してください。

主要な機能
--------------

### データベース単位のコネクション切り替え

Rails 6.1でデータベース単位のコネクション切り替え機能が使えるようになりました（[#40370](https://github.com/rails/rails/pull/40370)。6.0の場合は、ロールを`reading`に切り替えるとすべてのデータベースコネクションもreadingロールに切り替わりました。6.1からは、Railsの設定で`legacy_connection_handling`を`false`に指定しておけば、対応する抽象クラスで`connected_to`を呼び出すことでデータベースへのコネクションを切り替えられます。

### 水平シャーディング

Rails 6.0では、データベースの機能的パーティショニング（スキーマの異なる複数パーティション）が提供されていましたが、Active Recordのモデルがクラス単位およびロール単位で1つのコネクションしか持てなかったため、水平シャーディング（スキーマの同じ複数のパーティション）がサポートされていませんでした。Rails 6.1ではこの点が修正され、水平シャーディングを利用できるようになりました（[#38531](https://github.com/rails/rails/pull/38531)）

### 関連付けのstrict loading

関連付けのstrict loadingによって、N+1クエリ問題が発生する前に関連付けをeager loadingしてN+1クエリを防げるようになりました（[#37400](https://github.com/rails/rails/pull/37400)）。

### Delegated Types

「Delegated Types」は、単一テーブル継承（STI: Single Table Instance）の代替に使える設計です。（[#39341](https://github.com/rails/rails/pull/39341)）。Delegated Typesはクラス階層を表現するときに有用で、スーパークラスを「スーパークラス自身が持つテーブルで表される具象クラス」にできるようになります。スーパークラスの各サブクラスは、追加属性用に独自のテーブルを持ちます。

### 関連付けの非同期削除

関連付けの非同期削除は、関連付けをバックグラウンドジョブで`destroy`する機能を追加します（[#40157](https://github.com/rails/rails/pull/40157)）。データを削除するときのタイムアウトやパフォーマンス上の問題を回避するのに有用です。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください

### 削除されたもの

*   非推奨の`rake notes`タスクを削除

*   非推奨の`connection`オプションを`rails dbconsole`コマンドから削除

*   非推奨の`SOURCE_ANNOTATION_DIRECTORIES`環境変数サポートを`rails notes`から削除

*   非推奨の`server`引数をrailsのサーバーコマンドから削除

*   非推奨の`HOST`環境変数でサーバーIPを指定する機能のサポートを削除

*   非推奨の`rake dev:cache`タスクを削除

*   非推奨の`rake routes`タスクを削除

*   非推奨の`rake initializers`タスクを削除

### 非推奨化

(準備中...)

### 主な変更

(準備中...)

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

(準備中...)

### 非推奨化

(準備中...)

### 主な変更

(準備中...)

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   非推奨の`ActionDispatch::Http::ParameterFilter`を削除

*   非推奨のコントローラレベルの`force_ssl`を削除

### 非推奨化

*   `config.action_dispatch.return_only_media_type_on_content_type`を非推奨化

### 主な変更

*   `ActionDispatch::Response#content_type`が完全なContent-Typeヘッダーを返すよう変更

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

*   非推奨の`escape_whitelist`を`ActionView::Template::Handlers::ERB`から削除

*   非推奨の`find_all_anywhere`を`ActionView::Resolver`から削除

*   非推奨の`formats`を`ActionView::Template::HTML`から削除

*   非推奨の`formats`を`ActionView::Template::RawFile`から削除

*   非推奨の`formats`を`ActionView::Template::Text`から削除

*   非推奨の`find_file`を`ActionView::PathSet`から削除

*   非推奨の`rendered_format`を`ActionView::LookupContext`から削除

*   非推奨の`find_file`を`ActionView::ViewPaths`から削除

*   `ActionView::Base#initialize`で`ActionView::LookupContext`でないオブジェクトを第1引数として渡す機能（非推奨）を削除

*   非推奨の`format`引数を`ActionView::Base#initialize`から削除

*   非推奨の`ActionView::Template#refresh`を削除

*   非推奨の`ActionView::Template#original_encoding`を削除

*   非推奨の`ActionView::Template#variants`を削除

*   非推奨の`ActionView::Template#formats`を削除

*   非推奨の`ActionView::Template#virtual_path=`を削除

*   非推奨の`ActionView::Template#updated_at`を削除

*   `ActionView::Template#initialize`で必須だった非推奨の`updated_at`引数を削除

*   非推奨の`ActionView::Template.finalize_compiled_template_methods`を削除

*   非推奨の`config.action_view.finalize_compiled_template_methods`を削除

*   `ActionView::ViewPaths#with_fallback`のブロック付き呼び出し（非推奨）のサポートを削除

*   `render template:`に絶対パスを渡せる機能（非推奨）のサポートを削除

*   `render file:`に相対パスを渡せる機能（非推奨）のサポートを削除

*   引数を2つ受け取らないテンプレートハンドラー（非推奨）のサポートを削除

*   `ActionView::Template::PathResolver`のパターン引数（非推奨）を削除

*   一部のビューヘルパーでオブジェクトのprivateメソッドを呼び出すサポート（非推奨）を削除

### 非推奨化

(準備中...)

### 主な変更

*   `ActionView::Base`のサブクラスが`#compiled_method_container`を実装することが必須化された

*   `ActionView::Template#initialize`で`locals`引数が必須化された

*   アセットヘルパーの`javascript_include_tag`と`stylesheet_link_tag`がアセットのプリロードに関するヒントを提供する`Link`ヘッダを生成するようになった。これは`config.action_view.preload_links_header`を`false`に設定することで無効にできる

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

*   非推奨の`ActionMailer::Base.receive`を削除（今後は[Action Mailbox](https://github.com/rails/rails/tree/6-1-stable/actionmailbox)を利用）

### 非推奨化

(準備中...)

### 主な変更

(準備中...)

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

*   `ActiveRecord::ConnectionAdapters::DatabaseLimits`から以下の非推奨メソッドを削除

    `column_name_length`
    `table_name_length`
    `columns_per_table`
    `indexes_per_table`
    `columns_per_multicolumn_index`
    `sql_query_length`
    `joins_per_query`

*   非推奨の`ActiveRecord::ConnectionAdapters::AbstractAdapter#supports_multi_insert?`を削除

*   非推奨の`ActiveRecord::ConnectionAdapters::AbstractAdapter#supports_foreign_keys_in_create?`を削除

*   非推奨の`ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#supports_ranges?`を削除

*   非推奨の`ActiveRecord::Base#update_attributes`および`ActiveRecord::Base#update_attributes!`を削除

*   非推奨の`migrations_path`引数を
    `ActiveRecord::ConnectionAdapter::SchemaStatements#assume_migrated_upto_version`から削除

*   非推奨の`config.active_record.sqlite3.represent_boolean_as_integer`を削除

*   `ActiveRecord::DatabaseConfigurations`から以下の非推奨メソッドを削除

    `fetch`
    `each`
    `first`
    `values`
    `[]=`

*   非推奨の`ActiveRecord::Result#to_hash`メソッドを削除

*   `ActiveRecord::Relation`メソッドでの安全でない生SQLの利用（非推奨）を削除

### 非推奨化

*   `ActiveRecord::Base.allow_unsafe_raw_sql`を非推奨化

*   `connected_to`のキーワード引数`database`を非推奨化

*   `legacy_connection_handling`に`true`を設定している場合の`connection_handlers`を非推奨化

### 主な変更

*   MySQL: uniquenessバリデーターでデータベースのデフォルトコレーション（collation）が反映されるようになり、大文字小文字を区別する比較をデフォルトで強制しなくなった

*   `relation.create`のスコープが、初期化ブロック内やコールバック内でクラスレベルのクエリメソッドにリークしないようになった

    変更前:

    ```ruby
    User.where(name: "John").create do |john|
      User.find_by(name: "David") # => nil
    end
    ```

    変更後:

    ```ruby
    User.where(name: "John").create do |john|
      User.find_by(name: "David") # => #<User name: "David", ...>
    end
    ```

*   名前付きスコープをチェーンしたときのスコープが、クラスレベルのクエリメソッドにリークしないようになった

    ```ruby
    class User < ActiveRecord::Base
      scope :david, -> { User.where(name: "David") }
    end
    ```

    変更前:

    ```ruby
    User.where(name: "John").david
    # SELECT * FROM users WHERE name = 'John' AND name = 'David'
    ```

    変更後:

    ```ruby
    User.where(name: "John").david
    # SELECT * FROM users WHERE name = 'David'
    ```

*   `where.not`がNORではなくNANDを述部で生成するようになった

     変更前:

     ```ruby
     User.where.not(name: "Jon", role: "admin")
     # SELECT * FROM users WHERE name != 'Jon' AND role != 'admin'
     ```

     変更後:

     ```ruby
     User.where.not(name: "Jon", role: "admin")
     # SELECT * FROM users WHERE NOT (name == 'Jon' AND role == 'admin')
     ```

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

*   `ActiveStorage::Transformers::ImageProcessing`に`:combine_options`操作を渡すサポート（非推奨）を削除

*   非推奨の`ActiveStorage::Transformers::MiniMagickTransformer`を削除

*   非推奨の`config.active_storage.queue`を削除

*   非推奨の`ActiveStorage::Downloading`を削除

### 非推奨化

*   `Blob.create_after_upload`を非推奨化、今後は`Blob.create_and_upload`を利用（
    [#34827](https://github.com/rails/rails/pull/34827)）

### 主な変更

*   `Blob.create_and_upload`を追加: blobを新規作成し、指定の`io`をサービスにアップロードする（[#34827](https://github.com/rails/rails/pull/34827)）

*   `ActiveStorage::Blob#service_name`カラムを追加: アップグレード後にマイグレーションを実行する必要がある。マイグレーションを生成するためには`bin/rails app:update`を実行する

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

(準備中...)

### 非推奨化

(準備中...)

### 主な変更

*   Active Modelのエラーが、モデルで発生したエラーのインタラクティブな操作をアプリケーションで簡単に行えるインターフェイスを持つオブジェクトになった（[#32313](https://github.com/rails/rails/pull/32313)）: この機能に含まれるクエリインターフェイスによってテストの精度が向上し、エラーの詳細にアクセスできるようになる。

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   `config.i18n.fallbacks`が空の場合に`I18n.default_locale`にフォールバックする挙動（非推奨）を削除

*   非推奨の`LoggerSilence`定数を削除

*   非推奨の`ActiveSupport::LoggerThreadSafeLevel#after_initialize`を削除

*   非推奨の`Module#parent_name`、`Module#parent`、`Module#parents`を削除

*   非推奨の`active_support/core_ext/module/reachable`ファイルを削除

*   非推奨の`active_support/core_ext/numeric/inquiry`ファイルを削除

*   非推奨の`active_support/core_ext/array/prepend_and_append`ファイルを削除

*   非推奨の`active_support/core_ext/hash/compact`ファイルを削除

*   非推奨の`active_support/core_ext/hash/transform_values`ファイルを削除

*   非推奨の`active_support/core_ext/range/include_range`ファイルを削除

*   非推奨の`ActiveSupport::Multibyte::Chars#consumes?`および`ActiveSupport::Multibyte::Chars#normalize`を削除

*   非推奨の`ActiveSupport::Multibyte::Unicode.pack_graphemes`、
    `ActiveSupport::Multibyte::Unicode.unpack_graphemes`、
    `ActiveSupport::Multibyte::Unicode.normalize`、
    `ActiveSupport::Multibyte::Unicode.downcase`、
    `ActiveSupport::Multibyte::Unicode.upcase`、`ActiveSupport::Multibyte::Unicode.swapcase`を削除

*   非推奨の`ActiveSupport::Notifications::Instrumenter#end=`を削除

### 非推奨化

*   `ActiveSupport::Multibyte::Unicode.default_normalization_form`を非推奨化

### 主な変更

(準備中...)

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

(準備中...)

### 非推奨化

*   `config.active_job.return_false_on_aborted_enqueue`を非推奨化

### 主な変更

*   キューに入っているジョブがabortされたときに`false`を返すようになった

Action Text
----------

変更点について詳しくは[Changelog][action-text]を参照してください。

### 削除されたもの

(準備中...)

### 非推奨化

(準備中...)

### 主な変更

*   リッチテキストコンテンツの存在を確認するメソッド（リッチテキスト属性名の後ろに`?`を追加する）を追加（[#37951](https://github.com/rails/rails/pull/37951)）

*   システムテストケースヘルパー`fill_in_rich_text_area`を追加: Trixエディタを探索して、指定のHTMLコンテンツを入力する（[#35885](https://github.com/rails/rails/pull/35885)）

*   `ActionText::FixtureSet.attachment`を追加: データベースfixtureで`<action-text-attachment>`要素を生成する（[#40289](https://github.com/rails/rails/pull/40289)）

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

(準備中...)

### 非推奨化

*   `Rails.application.credentials.action_mailbox.api_key`および`MAILGUN_INGRESS_API_KEY`が非推奨化。今後は`Rails.application.credentials.action_mailbox.signing_key`および`MAILGUN_INGRESS_SIGNING_KEY`を利用すること。

### 主な変更

(準備中...)

Ruby on Railsガイド
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更

(準備中...)

Credits
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/6-1-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/6-1-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/6-1-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/6-1-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/6-1-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/6-1-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/6-1-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/6-1-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/6-1-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/6-1-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/6-1-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/6-1-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/6-1-stable/guides/CHANGELOG.md
