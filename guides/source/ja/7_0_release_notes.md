Ruby on Rails 7.0 リリースノート
===============================

Rails 7.0の注目ポイント:

* Ruby 2.7.0以上が必須、Ruby 3.0以上が望ましい

--------------------------------------------------------------------------------

Rails 7.0にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 6.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.0にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-6-1からrails-7-0へのアップグレード)を参照してください。

主要な機能
--------------

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

*   `dbconsole`で非推奨化されていた`config`を削除。

### 非推奨化

特になし。

### 主な変更点

*   Sprocketsへの依存がオプショナルになった

    `rails` gemが`sprockets-rails`に依存しなくなりました。自分のアプリケーションでSprocketsを使う必要がある場合は、以下のようにGemfileに追加してください。

    ```ruby
    gem "sprockets-rails"
    ```

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

特になし。

### 主な変更点

特になし。

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActionDispatch::Response.return_only_media_type_on_content_type`を削除。

*   非推奨化されていた`Rails.config.action_dispatch.hosts_response_app`を削除。

*   非推奨化されていた`ActionDispatch::SystemTestCase#host!`を削除。

*   `fixture_path`への相対パスを`fixture_file_upload`に渡すサポート（非推奨化済み）を削除。

### 非推奨化

特になし。

### 主な変更点

特になし。

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails.config.action_view.raise_on_missing_translations`を削除

### 非推奨化

特になし。

### 主な変更点

*  `button_to`メソッドでオブジェクトがURLのビルドに使われている場合に、Active RecordオブジェクトからHTTP verb [method]を推論するようになった。

    ```ruby
    button_to("Do a POST", [:do_post_action, Workshop.find(1)])
    # Before
    #=>   <input type="hidden" name="_method" value="post" autocomplete="off" />
    # After
    #=>   <input type="hidden" name="_method" value="patch" autocomplete="off" />
    ```

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActionMailer::DeliveryJob`および`ActionMailer::Parameterized::DeliveryJob`が削除された（今後は`ActionMailer::MailDeliveryJob`を使う）。

### 非推奨化

特になし。

### 主な変更点

特になし。

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

*   非推奨化されていた`database`キーワード引数を`connected_to`から削除。

*   非推奨化されていた`ActiveRecord::Base.allow_unsafe_raw_sql`を削除。

*   `configs_for`メソッドで非推奨化されていた`:spec_name`オプションを削除。

*   Rails 4.2および4.1フォーマットで非推奨化されていた`ActiveRecord::Base`インスタンスのYAML読み込みサポートを削除。

*   PostgreSQLで`:interval`カラムが使われている場合の非推奨化警告メッセージを削除。

    今後`:interval`カラムは文字列ではなく`ActiveSupport::Duration`オブジェクトを返します。

    従来の振る舞いを維持する場合は、以下の行を自分のモデルに追加できます。

    ```ruby
    attribute :column, :string
    ```

*   コネクションのspecification名として`"primary"`を用いてコネクションを解決するサポート（非推奨化済み）を削除。

*   `ActiveRecord::Base`オブジェクトを引用符で直接囲めるようにするサポート（非推奨化済み）を削除。

*   `ActiveRecord::Base`オブジェクトを`type_cast`で直接データベース値へ型キャストできるようにするサポート（非推奨化済み）を削除。

*   カラムを`type_cast`に直接渡せるようにするサポート（非推奨化済み）を削除。

*   非推奨化されていた`DatabaseConfig#config`メソッドを削除。

*   非推奨化されていた以下のrakeタスクを削除。

    * `db:schema:load_if_ruby`
    * `db:structure:dump`
    * `db:structure:load`
    * `db:structure:load_if_sql`
    * `db:structure:dump:#{name}`
    * `db:structure:load:#{name}`
    * `db:test:load_structure`
    * `db:test:load_structure:#{name}`

*   `Model.reorder(nil).first`を用いて非決定論的な順序で検索できるようにするサポート（非推奨化済み）を削除。

*   `Tasks::DatabaseTasks.schema_up_to_date?`で非推奨化されていた`environment`引数と`name`引数を削除。

*   非推奨化されていた`Tasks::DatabaseTasks.dump_filename`を削除。

*   非推奨化されていた`Tasks::DatabaseTasks.schema_file`を削除。

*   非推奨化されていた`Tasks::DatabaseTasks.spec`を削除。

*   非推奨化されていた`Tasks::DatabaseTasks.current_config`を削除。

*   非推奨化されていた`ActiveRecord::Connection#allowed_index_name_length`を削除。

*   非推奨化されていた`ActiveRecord::Connection#in_clause_length`を削除。

*   非推奨化されていた`ActiveRecord::DatabaseConfigurations::DatabaseConfig#spec_name`を削除。

*   非推奨化されていた`ActiveRecord::Base.connection_config`を削除。

*   非推奨化されていた`ActiveRecord::Base.arel_attribute`を削除。

*   非推奨化されていた`ActiveRecord::Base.configurations.default_hash`を削除。

*   非推奨化されていた`ActiveRecord::Base.configurations.to_h`を削除。

*   非推奨化されていた`ActiveRecord::Result#map!`および`ActiveRecord::Result#collect!`を削除。

*   非推奨化されていた`ActiveRecord::Base#remove_connection`を削除。

### 非推奨化

*   `Tasks::DatabaseTasks.schema_file_type`を非推奨化。

### 主な変更点

*   トランザクションブロックが期待より早期に返された場合にトランザクションをロールバックするようになった。

    変更前は、ブロックが期待より早期に返されるとトランザクションがコミットされる可能性がありました。

    この問題は、トランザクションブロック内部でトリガーされるタイムアウトによって不完全なトランザクションがコミットされるというものです。この問題を回避するため、トランザクションブロックはロールバックされます。

*   同じカラム上で条件をマージした場合に両方の条件が維持されなくなり、常に後者の条件によって置き換わるようになった。

    ```ruby
    # Rails 6.1 （IN句はマージする側の等値条件によって置き換えられる）
    Author.where(id: [david.id, mary.id]).merge(Author.where(id: bob)) # => [bob]
    # Rails 6.1 （競合する条件がどちらも存在する: 非推奨）
    Author.where(id: david.id..mary.id).merge(Author.where(id: bob)) # => []
    # Rails 6.1 でrewhereを用いてRails 7.0の挙動に移行する）
    Author.where(id: david.id..mary.id).merge(Author.where(id: bob), rewhere: true) # => [bob]
    # Rails 7.0 （IN句の振る舞いは同じで、マージされる側の条件が常に置き換えられる）
    Author.where(id: [david.id, mary.id]).merge(Author.where(id: bob)) # => [bob]
    Author.where(id: david.id..mary.id).merge(Author.where(id: bob)) # => [bob]
    ```

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

特になし。

### 主な変更点

特になし。

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

*   `ActiveModel::Errors`をハッシュとして列挙できるようにするサポート（非推奨化済み）を削除。

*   非推奨化された`ActiveModel::Errors#to_h`を削除。

*   非推奨化された`ActiveModel::Errors#slice!`を削除。

*   非推奨化された`ActiveModel::Errors#values`を削除。

*   非推奨化された`ActiveModel::Errors#keys`を削除。

*   非推奨化された`ActiveModel::Errors#to_xml`を削除。

*   `ActiveModel::Errors#messages`で非推奨化されていたconcatエラーのサポートを削除。

*   `ActiveModel::Errors#messages`のエラーを`clear`するサポート（非推奨化済み）を削除。

*   `ActiveModel::Errors#messages`のエラーを`delete`するサポート（非推奨化済み）を削除。

*   `ActiveModel::Errors#messages`で`[]=`を利用できるようにするサポート（非推奨化済み）を削除。

*   MarshalとYAMLのloadからRails 5.xのエラーフォーマットのサポートを削除

*   MarshalのloadからRails 5.xの`ActiveModel::AttributeSet`フォーマットのサポートを削除。

### 非推奨化

特になし。

### 主な変更点

特になし。

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_support.use_sha1_digests`を削除。

*   非推奨化されていた`URI.parser`を削除。

*   日時のrange内に値が含まれているかどうかのチェックに`Range#include?`を利用できるようにするサポート（非推奨化済み）を削除。

*   非推奨化されていた`ActiveSupport::Multibyte::Unicode.default_normalization_form`を削除。

### 非推奨化

*   フォーマットを`#to_s`に渡すことが非推奨化された。今後`Array`、`Range`、`Date`、`DateTime`、`Time`、`BigDecimal`、`Float`、`Integer`では`#to_fs`を使うこと。

    この非推奨化は、Ruby 3.1である種のオブジェクトの式展開を高速化する[最適化](https://github.com/ruby/ruby/commit/b08dacfea39ad8da3f1fd7fdd0e4538cc892ec44)を利用できるようにするためのものです。

    新しいアプリケーションではそれらのクラスの`#to_s`メソッドがオーバーライドされません。既存のアプリケーションでは`config.active_support.disable_to_s_conversion`でオーバーライドされないようにできます。

### 主な変更点

特になし。

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   前のコールバックが`throw :abort`で中断された場合に、`after_enqueue`/`after_perform`コールバックが停止しない振る舞い（非推奨化済み）を削除。

*   非推奨化されていた`:return_false_on_aborted_enqueue`オプションを削除。

### 非推奨化

`Rails.config.active_job.skip_after_callbacks_if_terminated`を非推奨化。

### 主な変更

特になし。

Action Text
----------

変更点について詳しくは[Changelog][action-text]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

特になし。

### 主な変更点

特になし。

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails.application.credentials.action_mailbox.mailgun_api_key`を削除。

*   非推奨化されていた環境変数`MAILGUN_INGRESS_API_KEY`を削除。

### 非推奨化

特になし。

### 主な変更点

特になし。

Ruby on Railsガイド
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更点

特になし。

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/7-0-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/7-0-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/7-0-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/7-0-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/7-0-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/7-0-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/7-0-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/7-0-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/7-0-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/7-0-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/7-0-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/7-0-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/7-0-stable/guides/CHANGELOG.md
