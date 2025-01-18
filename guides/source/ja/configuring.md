Rails アプリケーションの設定項目
==============================

本ガイドでは、Railsアプリケーションで利用可能な設定項目と初期化機能について解説します。

このガイドの内容:

* Railsアプリケーションの動作を調整する方法
* アプリケーション開始時に実行したいコードを追加する方法

--------------------------------------------------------------------------------


初期化コードの置き場所
---------------------------------

Railsには初期化コードの置き場所が4箇所あります。

* `config/application.rb`
* 環境ごとの設定ファイル
* イニシャライザファイル
* アフターイニシャライザファイル

Rails実行前にコードを実行する
-------------------------

アプリケーションでRails自体が読み込まれる前に何らかのコードを実行する必要が生じることがまれにあります。その場合は、実行したいコードを`config/application.rb`ファイルの`require 'rails/all'`行の上に書いてください。

Railsコンポーネントを構成する
----------------------------

一般に、Railsの設定作業には、Rails自身の設定と、Railsのコンポーネントの設定があります。`config/application.rb`および環境固有の設定ファイル（`config/environments/production.rb`など）に設定を記入すると、Railsのすべてのコンポーネントにそれらの設定が反映されます。

たとえば、`config/application.rb`ファイルに以下の設定を追加できます。

```ruby
config.time_zone = "Central Time (US & Canada)"
```

上はRails自身のための設定ですが、個別のRailsコンポーネントに設定を反映するときにも、以下のように`config/application.rb`内の同じ`config`オブジェクトを利用できます。

```ruby
config.active_record.schema_format = :ruby
```

この設定は、Active Record固有の設定に使われます。

WARNING: 関連付けされたクラスを直接呼び出すのではなく、必ずpublicな設定メソッドを使うこと。例: `ActionMailer::Base.options`ではなく`Rails.application.config.action_mailer.options`を使う。

NOTE: 設定をクラスに直接適用する必要がある場合は、イニシャライザで[`ActiveSupport::LazyLoadHooks`](https://api.rubyonrails.org/classes/ActiveSupport/LazyLoadHooks.html)をお使いください（初期化が完了する前にクラスが自動読み込みされるのを避けるため）。初期化中に自動読み込みされるとアプリの再読み込みを安全に繰り返せなくなるため、失敗します。

### Railsバージョンごとのデフォルト値

[`config.load_defaults`]はターゲットバージョンとそれ以前のすべてのバージョンのデフォルトの設定値を読み込みます。たとえば、`config.load_defaults 6.1`はバージョン6.1までの全バージョンのデフォルトを読み込みます。

[`config.load_defaults`]: https://api.rubyonrails.org/classes/Rails/Application/Configuration.html#method-i-load_defaults

ターゲットバージョンごとに関連するデフォルト値を以下に示します。値が矛盾する場合は、新しいバージョンが古いバージョンより優先されます。

#### ターゲットバージョン8.0のデフォルト値
<!-- ビルド対応として、設定項目と値の間に改行を追加、コードに含まれないことを明確にするためコロンを全角にした -->

- [`Regexp.timeout`](#regexp-timeout)
： `1`
- [`config.action_dispatch.strict_freshness`](#config-action-dispatch-strict-freshness)
： `true`
- [`config.active_support.to_time_preserves_timezone`](#config-active-support-to-time-preserves-timezone)
： `:zone`

#### ターゲットバージョン7.2のデフォルト値
<!-- ビルド対応として、設定項目と値の間に改行を追加、コードに含まれないことを明確にするためコロンを全角にした -->

- [`config.active_record.postgresql_adapter_decode_dates`](#config-active-record-postgresql-adapter-decode-dates)
： `true`
- [`config.active_record.validate_migration_timestamps`](#config-active-record-validate-migration-timestamps)
： `true`
- [`config.active_storage.web_image_content_types`](#config-active-storage-web-image-content-types)
： `%w[image/png image/jpeg image/gif image/webp]`
- [`config.yjit`](#config-yjit)
： `true`

#### ターゲットバージョン7.1のデフォルト値

- [`config.action_dispatch.debug_exception_log_level`](#config-action-dispatch-debug-exception-log-level)
： `:error`
- [`config.action_dispatch.default_headers`](#config-action-dispatch-default-headers)
： `{ "X-Frame-Options" => "SAMEORIGIN", "X-XSS-Protection" => "0", "X-Content-Type-Options" => "nosniff", "X-Permitted-Cross-Domain-Policies" => "none", "Referrer-Policy" => "strict-origin-when-cross-origin" }`
- [`config.action_text.sanitizer_vendor`](#config-action-text-sanitizer-vendor)
： `Rails::HTML::Sanitizer.best_supported_vendor`
- [`config.action_view.sanitizer_vendor`](#config-action-view-sanitizer-vendor)
： `Rails::HTML::Sanitizer.best_supported_vendor`
- [`config.active_record.before_committed_on_all_records`](#config-active-record-before-committed-on-all-records)
： `true`
- [`config.active_record.belongs_to_required_validates_foreign_key`](#config-active-record-belongs-to-required-validates-foreign-key)
： `false`
- [`config.active_record.default_column_serializer`](#config-active-record-default-column-serializer)
： `nil`
- [`config.active_record.encryption.hash_digest_class`](#config-active-record-encryption-hash-digest-class)
： `OpenSSL::Digest::SHA256`
- [`config.active_record.encryption.support_sha1_for_non_deterministic_encryption`](#config-active-record-encryption-support-sha1-for-non-deterministic-encryption)
： `false`
- [`config.active_record.generate_secure_token_on`](#config-active-record-generate-secure-token-on)
： `:initialize`
- [`config.active_record.marshalling_format_version`](#config-active-record-marshalling-format-version)
： `7.1`
- [`config.active_record.query_log_tags_format`](#config-active-record-query-log-tags-format)
： `:sqlcommenter`
- [`config.active_record.raise_on_assign_to_attr_readonly`](#config-active-record-raise-on-assign-to-attr-readonly)
： `true`
- [`config.active_record.run_after_transaction_callbacks_in_order_defined`](#config-active-record-run-after-transaction-callbacks-in-order-defined)
： `true`
- [`config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction`](#config-active-record-run-commit-callbacks-on-first-saved-instances-in-transaction)
： `false`
- [`config.active_record.sqlite3_adapter_strict_strings_by_default`](#config-active-record-sqlite3-adapter-strict-strings-by-default)
： `true`
- [`config.active_support.cache_format_version`](#config-active-support-cache-format-version)
： `7.1`
- [`config.active_support.message_serializer`](#config-active-support-message-serializer)
： `:json_allow_marshal`
- [`config.active_support.raise_on_invalid_cache_expiration_time`](#config-active-support-raise-on-invalid-cache-expiration-time)
： `true`
- [`config.active_support.use_message_serializer_for_metadata`](#config-active-support-use-message-serializer-for-metadata)
： `true`
- [`config.add_autoload_paths_to_load_path`](#config-add-autoload-paths-to-load-path)
： `false`
- [`config.dom_testing_default_html_version`](#config-dom-testing-default-html-version)
： `defined?(Nokogiri::HTML5) ? :html5 : :html4`
- [`config.log_file_size`](#config-log-file-size)
： `100 * 1024 * 1024`
- [`config.precompile_filter_parameters`](#config-precompile-filter-parameters)
： `true`

#### ターゲットバージョン7.0のデフォルト値

- [`config.action_controller.raise_on_open_redirects`](#config-action-controller-raise-on-open-redirects)
： `true`
- [`config.action_controller.wrap_parameters_by_default`](#config-action-controller-wrap-parameters-by-default)
： `true`
- [`config.action_dispatch.cookies_serializer`](#config-action-dispatch-cookies-serializer)
： `:json`
- [`config.action_dispatch.default_headers`](#config-action-dispatch-default-headers)
： `{ "X-Frame-Options" => "SAMEORIGIN", "X-XSS-Protection" => "0", "X-Content-Type-Options" => "nosniff", "X-Download-Options" => "noopen", "X-Permitted-Cross-Domain-Policies" => "none", "Referrer-Policy" => "strict-origin-when-cross-origin" }`
- [`config.action_mailer.smtp_timeout`](#config-action-mailer-smtp-timeout)
： `5`
- [`config.action_view.apply_stylesheet_media_default`](#config-action-view-apply-stylesheet-media-default)
： `false`
- [`config.action_view.button_to_generates_button_tag`](#config-action-view-button-to-generates-button-tag)
： `true`
- [`config.active_record.automatic_scope_inversing`](#config-active-record-automatic-scope-inversing)
： `true`
- [`config.active_record.partial_inserts`](#config-active-record-partial-inserts)
： `false`
- [`config.active_record.verify_foreign_keys_for_fixtures`](#config-active-record-verify-foreign-keys-for-fixtures)
： `true`
- [`config.active_storage.multiple_file_field_include_hidden`](#config-active-storage-multiple-file-field-include-hidden)
： `true`
- [`config.active_storage.variant_processor`](#config-active-storage-variant-processor)
： `:vips`
- [`config.active_storage.video_preview_arguments`](#config-active-storage-video-preview-arguments)
： `"-vf 'select=eq(n\\,0)+eq(key\\,1)+gt(scene\\,0.015),loop=loop=-1:size=2,trim=start_frame=1' -frames:v 1 -f image2"`
- [`config.active_support.cache_format_version`](#config-active-support-cache-format-version)
： `7.0`
- [`config.active_support.executor_around_test_case`](#config-active-support-executor-around-test-case)
： `true`
- [`config.active_support.hash_digest_class`](#config-active-support-hash-digest-class)
： `OpenSSL::Digest::SHA256`
- [`config.active_support.key_generator_hash_digest_class`](#config-active-support-key-generator-hash-digest-class)
： `OpenSSL::Digest::SHA256`

#### ターゲットバージョン6.1のデフォルト値

- [`ActiveSupport.utc_to_local_returns_utc_offset_times`](#activesupport-utc-to-local-returns-utc-offset-times)
： `true`
- [`config.action_dispatch.cookies_same_site_protection`](#config-action-dispatch-cookies-same-site-protection)
： `:lax`
- [`config.action_dispatch.ssl_default_redirect_status`](#config-action-dispatch-ssl-default-redirect-status)
： `308`
- [`config.action_mailbox.queues.incineration`](#config-action-mailbox-queues-incineration)
： `nil`
- [`config.action_mailbox.queues.routing`](#config-action-mailbox-queues-routing)
： `nil`
- [`config.action_mailer.deliver_later_queue_name`](#config-action-mailer-deliver-later-queue-name)
： `nil`
- [`config.action_view.form_with_generates_remote_forms`](#config-action-view-form-with-generates-remote-forms)
： `false`
- [`config.action_view.preload_links_header`](#config-action-view-preload-links-header)
： `true`
- [`config.active_job.retry_jitter`](#config-active-job-retry-jitter)
： `0.15`
- [`config.active_record.has_many_inversing`](#config-active-record-has-many-inversing)
： `true`
- [`config.active_storage.queues.analysis`](#config-active-storage-queues-analysis)
： `nil`
- [`config.active_storage.queues.purge`](#config-active-storage-queues-purge)
： `nil`
- [`config.active_storage.track_variants`](#config-active-storage-track-variants)
： `true`

#### ターゲットバージョン6.0のデフォルト値

- [`config.action_dispatch.use_cookies_with_metadata`](#config-action-dispatch-use-cookies-with-metadata)
： `true`
- [`config.action_mailer.delivery_job`](#config-action-mailer-delivery-job)
： `"ActionMailer::MailDeliveryJob"`
- [`config.action_view.default_enforce_utf8`](#config-action-view-default-enforce-utf8)
： `false`
- [`config.active_record.collection_cache_versioning`](#config-active-record-collection-cache-versioning)
： `true`
- [`config.active_storage.queues.analysis`](#config-active-storage-queues-analysis)
： `:active_storage_analysis`
- [`config.active_storage.queues.purge`](#config-active-storage-queues-purge)
： `:active_storage_purge`

#### ターゲットバージョン5.2のデフォルト値

- [`config.action_controller.default_protect_from_forgery`](#config-action-controller-default-protect-from-forgery)
： `true`
- [`config.action_dispatch.use_authenticated_cookie_encryption`](#config-action-dispatch-use-authenticated-cookie-encryption)
： `true`
- [`config.action_view.form_with_generates_ids`](#config-action-view-form-with-generates-ids)
： `true`
- [`config.active_record.cache_versioning`](#config-active-record-cache-versioning)
： `true`
- [`config.active_support.hash_digest_class`](#config-active-support-hash-digest-class)
： `OpenSSL::Digest::SHA1`
- [`config.active_support.use_authenticated_message_encryption`](#config-active-support-use-authenticated-message-encryption)
： `true`

#### ターゲットバージョン5.1のデフォルト値

- [`config.action_view.form_with_generates_remote_forms`](#config-action-view-form-with-generates-remote-forms)
： `true`
- [`config.assets.unknown_asset_fallback`](#config-assets-unknown-asset-fallback)
： `false`

#### ターゲットバージョン5.0のデフォルト値

- [`ActiveSupport.to_time_preserves_timezone`](#activesupport-to-time-preserves-timezone)
： `true`
- [`config.action_controller.forgery_protection_origin_check`](#config-action-controller-forgery-protection-origin-check)
： `true`
- [`config.action_controller.per_form_csrf_tokens`](#config-action-controller-per-form-csrf-tokens)
： `true`
- [`config.active_record.belongs_to_required_by_default`](#config-active-record-belongs-to-required-by-default)
： `true`
- [`config.active_support.to_time_preserves_timezone`](#config-active-support-to-time-preserves-timezone)
： `:offset`
- [`config.ssl_options`](#config-ssl-options)
： `{ hsts: { subdomains: true } }`

### Rails全般の設定

Rails全般に対する設定を行うには、`Rails::Railtie`オブジェクトを呼び出すか、`Rails::Engine`や`Rails::Application`のサブクラスを呼び出します。

#### `config.add_autoload_paths_to_load_path`

自動読み込みパスを`$LOAD_PATH`に追加しなければならないかどうかを指定します。`zeitwerk`モードでは`config/application.rb`で`false`に設定することが推奨されます。
Zeitwerkは内部的に絶対パスを使っており、`:zeitwerk`モードで動作するアプリケーションには`require_dependency`が不要なので、モデル、コントローラ、ジョブなどは`$LOAD_PATH`に入れておく必要がありません。
これを`false`に設定すると、Rubyが相対パスで`require`呼び出しを解決する際にこれらのディレクトリをチェックする必要がなくなり、Bootsnapの作業とメモリを節約できます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
|（オリジナル）            | `true`               |
| 7.1以降                | `false`              |

`lib`ディレクトリはこのフラグの影響を受けません。常に`$LOAD_PATH`に追加されます。

#### `config.after_initialize`

Railsによるアプリケーションの初期化が完了した**後に**実行されるブロックを渡せます。アプリケーションの初期化には、「フレームワーク自体の初期化」「エンジンの初期化」「`config/initializers`に記述されたすべてのアプリケーション初期化処理の実行」が含まれます。ここで渡すブロックは**rakeタスクで実行される**ことにご注意ください。このブロックは、他のイニシャライザによってセットアップ済みの値を設定するのに便利です。

```ruby
config.after_initialize do
  ActionView::Base.sanitized_allowed_tags.delete "div"
end
```

#### `config.after_routes_loaded`

Railsがアプリケーションルーティングの読み込みを終了した後に実行されるブロックを受け取ります。このブロックは、ルーティングがリロードされるときにも実行されます。

```ruby
config.after_routes_loaded do
  # Rails.application.routesで何かするコードを書く
end
```

#### `config.allow_concurrency`

リクエストをコンカレント処理するかどうかを制御します。アプリケーションのコードがスレッドセーフでない場合のみ`false`に設定する必要があります。
デフォルトは`true`です。

#### `config.asset_host`

アセットを置くホストを設定します。この設定は、アセットの置き場所がCDN（Contents Delivery Network）の場合や、別のドメインエイリアスを使うとブラウザの同時実行制限にひっかかるのを避けたい場合に便利です。この設定は`config.action_controller.asset_host`のショートハンドです。

#### `config.assume_ssl`

すべてのリクエストがSSLで到着しているとアプリケーションに思わせるようにします。これは、SSLを終端するロードバランサー経由でプロキシする場合に有用で、転送されたリクエストは、アプリケーションにはHTTPSではなくHTTPであるかのように見えます。これにより、リダイレクトやcookieのセキュリティがHTTPSではなくHTTPを対象とするようになります。このミドルウェアは、プロキシが既にSSLを終端しており、リクエストは本当にHTTPSであるとサーバーに思わせるようにします。

#### `config.autoflush_log`

ログのファイル出力をバッファリングせず、即座に書き出す設定を有効にします。
デフォルトは`true`です。

#### `config.autoload_lib(ignore:)`

このメソッドは、`lib`を`config.autoload_paths`と`config.eager_load_paths`に追加します。

通常、`lib`ディレクトリには自動読み込みやeager loadingされるべきでないサブディレクトリがあります。その場合は、必要に応じて以下のように`ignore`キーワード引数でそれらの名前を`lib`からの相対パスで指定してください。

```ruby
config.autoload_lib(ignore: %w(assets tasks generators))
```

詳しくは[定数の自動読み込みガイド](autoloading_and_reloading_constants.html)を参照してください。

#### `config.autoload_lib_once(ignore:)`

`config.autoload_lib_once`メソッドは、`config.autoload_lib`と似ていますが、`lib`を`config.autoload_once_paths`に追加する点が異なります。

`config.autoload_lib_once`を呼び出すことで、`lib`内のクラスやモジュールが自動的に読み込まれます。アプリケーションの初期化時でも再読み込みは行われません。

#### `config.autoload_once_paths`

サーバーへのリクエストごとにクリアされない定数を自動読み込みするパスの配列をRailsに渡せます。この設定は再読み込みが有効になっている場合に関連し、developmentモードではデフォルトでオフになります。それ以外の場合、自動読み込みは1度しか行われません。この配列内にあるすべての要素は`autoload_paths`に存在しなければなりません。
デフォルト値は空の配列です。

#### `config.autoload_paths`

Railsが定数を自動読み込みするパスの配列を渡せます。デフォルト値は空の配列です。[Rails 6](upgrading_ruby_on_rails.html#自動読み込み)以降は、この設定の変更は推奨されません。詳しくは[定数の自動読み込みと再読み込み](autoloading_and_reloading_constants.html)を参照してください。

#### `config.beginning_of_week`

アプリケーションでデフォルトの週の初日を何曜日にするかを設定します。有効な曜日をシンボルで指定します（例：`:monday`）。

#### `config.cache_classes`

後方互換性のためにサポートされている古い設定であり、`!config.enable_reloading`と同等です。

#### `config.cache_store`

Railsでのキャッシュ処理に使われるキャッシュストアを設定します。指定できるオプションは次のシンボル`:memory_store`、`:file_store`、`:mem_cache_store`、`:null_store`、`:redis_cache_store`のいずれか、またはキャッシュAPIを実装するオブジェクトです。デフォルト値は`:file_store`です。ストアごとの設定オプションについては[キャッシュストア](caching_with_rails.html#その他のキャッシュストア)を参照してください。

#### `config.colorize_logging`

出力するログ情報にANSI色情報を与えるかどうかを指定します。デフォルト値は`true`です。

#### `config.consider_all_requests_local`

このフラグが`true`の場合、エラー発生の種類を問わず詳細なデバッグ情報をHTTPレスポンスに出力し、`Rails::Info`コントローラがアプリケーションの実行時コンテキストを`/rails/info/properties`に出力します。このフラグはdevelopment環境とtest環境では`true`、production環境では`false`に設定されます。より細かく制御したい場合は、このフラグを`false`に設定してから、コントローラで`show_detailed_exceptions?`メソッドを実装し、エラー時にデバッグ情報を出力したいリクエストをそこで指定します。

#### `config.console`

これを用いて、コンソールで`rails console`を実行する時に使われるクラスをカスタマイズできます。このメソッドは`console`ブロックで使うのが最適です。

```ruby
console do
  # このブロックはコンソールで実行されるときしか呼び出されない
  # 従ってpryを安全にrequireできる
  require "pry"
  config.console = Pry
end
```

#### `config.content_security_policy_nonce_directives`

セキュリティガイドの[nonceを追加する](security.html#nonceを追加する)を参照

#### `config.content_security_policy_nonce_generator`

セキュリティガイドの[nonceを追加する](security.html#nonceを追加する)を参照

#### `config.content_security_policy_report_only`

セキュリティガイドの[違反をレポートする](security.html#違反をレポートする)を参照

#### `config.credentials.content_path`

暗号化済みcredentialsファイルのパスを指定します。

デフォルトでは、`config/credentials/#{Rails.env}.yml.enc`があればそのパスを使い、なければ`config/credentials.yml.enc`を使います。

NOTE: `bin/rails credentials`コマンドでこの値を認識させるために、必ず`config/application.rb`ファイルか`config/environments/#{Rails.env}.rb`ファイルで設定しなければなりません。

#### `config.credentials.key_path`

暗号化済みcredentialsキーファイルのパスを指定します。


デフォルトでは、`config/credentials/#{Rails.env}.key`があればそのパスを使い、なければ`config/master.key`を使います。

NOTE: `bin/rails credentials`コマンドでこの値を認識させるために、必ず`config/application.rb`ファイルか`config/environments/#{Rails.env}.rb`ファイルで設定しなければなりません。

#### `config.debug_exception_response_format`

development環境でエラーが発生した場合に、レスポンスで使う形式を設定します。デフォルトは、API専用アプリの場合は`:api`、通常のアプリの場合は`:default`です。

#### `config.disable_sandbox`

コンソールをsandboxモードで起動してよいかどうかを制御します。これは、sandboxコンソールのセッションを長時間動かしっぱなしにするとデータベースサーバーのメモリが枯渇するのを避けるうえで有用です。デフォルト値は`false`です。

#### `config.dom_testing_default_html_version`

Action View、Action Dispatch、`rails-dom-testing`のテストヘルパーでデフォルトで使うHTMLパーサーを、HTML4パーサーにするかHTML5パーサーにするかを制御します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
|（オリジナル）            | `:html4`             |
| 7.1以降                | `:html5`（以下の注を参照）|

NOTE: NokogiriのHTML5パーサーはJRubyではサポートされていないため、JRubyプラットフォームのRailsは`:html4`にフォールバックします。

#### `config.eager_load`

`true`にすると、登録された`config.eager_load_namespaces`をeager loadingします。ここにはアプリケーション、エンジン、Railsフレームワークを含むあらゆる登録済み名前空間が含まれます。

#### `config.eager_load_namespaces`

ここに登録した名前は、`config.eager_load`を`true`にするとeager loadingされます。登録される名前空間は、必ず`eager_load!`メソッドに応答しなければなりません。

#### `config.eager_load_paths`

パスの配列を引数に取ります。起動時のRailsは、cache_classesがオンの場合にこのパスからeager loadingします。デフォルトではアプリケーションの`app/`ディレクトリ以下のすべてのディレクトリが対象です。

#### `config.enable_reloading`

`config.enable_reloading`がtrueの場合、アプリケーションのクラスとモジュールが変更されると、Webリクエスト間に再読み込みされます。
デフォルトは`development`環境では`true`、`production`環境では`false`です。

述語`config.reloading_enabled?`も定義されています。

#### `config.encoding`

アプリケーション全体のエンコーディングを指定します。デフォルト値はUTF-8です。

#### `config.exceptions_app`

例外が発生したときに`ShowException`ミドルウェアによって呼び出される例外アプリケーションを設定します。
デフォルト値は`ActionDispatch::PublicExceptions.new(Rails.public_path)`です。

例外アプリケーションは`ActionDispatch::Http::MimeNegotiation::InvalidType`エラーを処理する必要があります。このエラーは、クライアントが無効な`Accept`ヘッダーまたは`Content-Type`ヘッダーを送信したときに発生します。

デフォルトの`ActionDispatch::PublicExceptions`アプリケーションは自動的にこれを行い、`Content-Type`を`text/html`に設定し、`406 Not Acceptable`ステータスを返します。

このエラーを処理しないと、`500 Internal Server Error`が発生します。

例外アプリケーションとして`Rails.application.routes`や`RouteSet`を使う場合にも、この特殊な処理が必要になります。次のような感じになります。

```ruby
# config/application.rb
config.exceptions_app = CustomExceptionsAppWrapper.new(exceptions_app: routes)
```

```ruby
# lib/custom_exceptions_app_wrapper.rb
class CustomExceptionsAppWrapper
  def initialize(exceptions_app:)
    @exceptions_app = exceptions_app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    fallback_to_html_format_if_invalid_mime_type(request)

    @exceptions_app.call(env)
  end

  private
    def fallback_to_html_format_if_invalid_mime_type(request)
      request.formats
    rescue ActionDispatch::Http::MimeNegotiation::InvalidType
      request.set_header "CONTENT_TYPE", "text/html"
    end
end
```

#### `config.file_watcher`

`config.reload_classes_only_on_change`が`true`の場合に、ファイルシステム上のファイル更新検出に使われるクラスを指定します。デフォルトのRailsでは`ActiveSupport::FileUpdateChecker`、および`ActiveSupport::EventedFileUpdateChecker`が指定されます。カスタムクラスはこの`ActiveSupport::FileUpdateChecker`APIに従わなければなりません。

`ActiveSupport::EventedFileUpdateChecker`の利用は、[listen](https://github.com/guard/listen) gemに依存します

```ruby
group :development do
  gem "listen", "~> 3.5"
end
```

LinuxやmacOSでは追加のgemは不要ですが、[BSDの場合](https://github.com/guard/listen#on-bsd)や[Windowsの場合](https://github.com/guard/listen#on-windows)にはいくつかのgemを追加する必要があります。
[一部の設定はサポートされていない](https://github.com/guard/listen#issues--limitations)ことにご注意ください。

#### `config.filter_parameters`

パスワードやクレジットカード番号など、ログに出力したくないパラメータをフィルタで除外するのに用います。また、Active Recordオブジェクトに対して`#inspect`を呼び出した際に、データベースの機密性の高い値をフィルタで除外します。デフォルトのRailsでは`config/initializers/filter_parameter_logging.rb`に以下の記述を追加することでパスワードをフィルタで除外しています。

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
```

パラメータのフィルタは正規表現の**部分一致**によって行われます（訳注: 他のパラメータ名が誤って部分一致しないようご注意ください）。

#### `config.filter_redirect`

アプリケーションログからリダイレクトURLをフィルタで除外するために使います。

```ruby
Rails.application.config.filter_redirect += ["s3.amazonaws.com", /private-match/]
```

リダイレクトフィルターは、URLが文字列を含むか、あるいは正規表現にマッチするかをテストすることで動作します。

#### `config.force_ssl`

すべてのリクエストをHTTPSプロトコル下で実行するよう強制し、URL生成でも"https://"をデフォルトのプロトコルに設定します。HTTPSの強制は`ActionDispatch::SSL`ミドルウェアによって行われ、`config.ssl_options`で設定できます。詳しくはAPIドキュメント[`ActionDispatch::SSL`](https://api.rubyonrails.org/classes/ActionDispatch/SSL.html)を参照してください。

#### `config.helpers_paths`

ビューヘルパーを読み込むための追加パスを配列で定義します。

#### `config.host_authorization`

[HostAuthorizationミドルウェア](#actiondispatch-hostauthorization)を設定するオプションハッシュを受け取ります。

#### `config.hosts`

`Host`ヘッダの有効性を確認するために使われる、「文字列」「正規表現」「`IPAddr`」の配列です。[HostAuthorizationミドルウェア](#actiondispatch-hostauthorization)で使われ、DNSリバインディング攻撃を防ぐのに役立ちます。

#### `config.javascript_path`

アプリのJavaScriptを保存するパスを、`app/`ディレクトリからの相対パスで設定します。デフォルト値は`javascript`です（[webpacker](https://github.com/rails/webpacker)で使われます）。アプリで設定済みの`javascript_path`は`autoload_paths`から除外されます。

#### `config.log_file_size`

Railsのログファイルの最大サイズをバイト単位で定義します。development環境とtest環境では`104_857_600`（100 MiB）がデフォルトで、それ以外の環境では無制限となります。

#### `config.log_formatter`

Railsロガーのフォーマットを定義します。このオプションは、デフォルトではすべてのモードで`ActiveSupport::Logger::SimpleFormatter`のインスタンスを使います。`config.logger`を設定する場合は、この設定が`ActiveSupport::TaggedLogging`インスタンスでラップされるより前の段階で、フォーマッターの値を手動で渡さなければなりません（Railsはこの処理を自動では行いません）。

#### `config.log_level`

Railsのログ出力をどのぐらい詳細にするかを指定します。デフォルト値は、production環境では`:info`、それ以外の環境では`:debug`です。指定可能な出力レベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`です。

#### `config.log_tags`

「`request`オブジェクトが応答するメソッド」「`request`オブジェクトを受け取る`Proc`」または「`to_s`に応答できるオブジェクト」のリストを引数に取ります。これは、ログの行にデバッグ情報をタグ付けする場合に便利です。たとえばサブドメインやリクエストidを指定可能で、これらはマルチユーザーのproductionアプリケーションのデバッグで非常に有用です。

#### `config.logger`

`Rails.logger`で使われるロガーやRails関連のあらゆるロガー（`ActiveRecord::Base.logger`など）を指定します。デフォルトでは、`ActiveSupport::Logger`のインスタンスをラップする`ActiveSupport::TaggedLogging`のインスタンスが指定されます。なお`ActiveSupport::Logger`はログを`log/`ディレクトリに出力します。ここにカスタムロガーを指定できますが、互換性を完全にするには以下のガイドラインに従わなければなりません。

* フォーマッターをサポートする場合は、`config.log_formatter`の値を手動でロガーに代入しなければなりません。
* タグ付きログをサポートする場合は、そのログのインスタンスを`ActiveSupport::TaggedLogging`でラップしなければなりません。
* ログ出力の抑制をサポートするには、`LoggerSilence`モジュールを`include`しなければなりません。`ActiveSupport::Logger`クラスは既にこれらのモジュールを`include`しています。

```ruby
class MyLogger < ::Logger
  include ActiveSupport::LoggerSilence
end

mylogger           = MyLogger.new(STDOUT)
mylogger.formatter = config.log_formatter
config.logger      = ActiveSupport::TaggedLogging.new(mylogger)
```

#### `config.middleware`

アプリケーションで使うミドルウェアをカスタマイズできます。詳細については[ミドルウェアを設定する](#ミドルウェアを設定する)の節を参照してください。

#### `config.precompile_filter_parameters`

`true`に設定すると、[`ActiveSupport::ParameterFilter.precompile_filters`][]を用いて[`config.filter_parameters`](#config-filter-parameters)をプリコンパイルします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
|（オリジナル）            | `false`              |
| 7.1以降                | `true`               |

[`ActiveSupport::ParameterFilter.precompile_filters`]: https://api.rubyonrails.org/classes/ActiveSupport/ParameterFilter.html#method-c-precompile_filters

#### `config.public_file_server.enabled`

Railsの`public`ディレクトリから静的ファイルを配信するかどうかを設定します。
デフォルトは`true`です。

NGINXやApacheなどのサーバーソフトウェアが静的ファイルを配信する場合は、この値を`false`に設定します。

#### `config.railties_order`

Railties/Engineの読み込み順序を手動で指定できます。
デフォルトは`[:all]`です。

```ruby
config.railties_order = [Blog::Engine, :main_app, :all]
```

#### `config.rake_eager_load`

`true`にすると、Rakeタスク実行中にアプリケーションをeager loadingします。
デフォルト値は`false`です。

#### `config.relative_url_root`

[サブディレクトリにデプロイする](configuring.html#サブディレクトリにデプロイする（相対url-rootの利用）)ことをRailsに指示します。
デフォルトは`ENV['RAILS_RELATIVE_URL_ROOT']`です。

#### `config.reload_classes_only_on_change`

トラッキングしているファイルが変更された場合のみのクラス再読み込みを有効または無効にします。
デフォルトでは、すべての自動読み込みパスをトラッキングし、`true`に設定されています。
このオプションは、`config.enable_reloading`が`false`の場合は無視されます。

#### `config.require_master_key`

`ENV["RAILS_MASTER_KEY"]`環境変数または`config/master.key`ファイルからマスターキーを取得できない場合はアプリを起動しないようにします。

#### `config.sandbox_by_default`

`true`にすると、Railsコンソールをsandboxモードで起動します。sandboxモードを無効にしてRailsコンソールを起動するには、`--no-sandbox`を明示的に指定しなければなりません。これは、production環境のデータベースに誤って書き込むのを防止したいときに有用です。デフォルト値は`false`です。

#### `config.secret_key_base`

アプリケーションのキージェネレータに入力する秘密鍵を指定する際に使われるフォールバックです。
これは設定せずに、`config/credentials.yml.enc`で`secret_key_base`を指定することが推奨されます。別の設定方法などについて詳しくはAPIドキュメント[`secret_key_base`]( https://api.rubyonrails.org/classes/Rails/Application.html#method-i-secret_key_base)を参照してください。

#### `config.server_timing`

`true`にすると、[ServerTimingミドルウェア](#actiondispatch-servertiming)をミドルウェアスタックに追加します。デフォルトは`false`ですが、生成されるデフォルトの`config/environments/development.rb`ファイルでは`true`に設定されます。

#### `config.session_options`

`config.session_store`に渡される追加オプションです。この設定は、自分で変更するのではなく、`config.session_store`で設定する必要があります。

```ruby
config.session_store :cookie_store, key: "_your_app_session"
config.session_options # => {key: "_your_app_session"}
```

#### `config.session_store`

セッションの保存に使うクラスを指定します。指定できる値は`cache_store`、`:cookie_store`、`:mem_cache_store`、カスタムストア、または`:disabled`です。`:disabled`を指定すると、Railsでセッションが扱われなくなります。

この設定は、セッターではなく、通常のメソッド呼び出しによって設定されます。これにより、以下のように追加のオプションを渡せます。

```ruby
config.session_store :cookie_store, key: "_your_app_session"
```

以下のようにカスタムストアをシンボルとして指定した場合、`ActionDispatch::Session`名前空間に解決されます。

```ruby
# ActionDispatch::Session::MyCustomStoreをセッションストアとして用いる
config.session_store :my_custom_store
```

デフォルトのストアは、アプリケーション名をセッションキーとするcookieストアです。

#### `config.silence_healthcheck_path`

ログ出力を抑制すべきヘルスチェックのパスを指定します。抑制の実装には`Rails::Rack::SilenceRequest`が使われます。これはすべて、特に初期段階のアプリケーションで、ヘルスチェックがproduction環境のログが詰まらないようにするためのものです。

```
config.silence_healthcheck_path = "/up"
```

#### `config.ssl_options`

[`ActionDispatch::SSL`](https://api.rubyonrails.org/classes/ActionDispatch/SSL.html)ミドルウェアの設定オプションを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `{}`                 |
| 5.0以降                | `{ hsts: { subdomains: true } }` |

#### `config.time_zone`

アプリケーションのデフォルトタイムゾーンを設定し、Active Recordで認識できるようにします。

#### `config.x`

ネストしたカスタム設定をアプリケーションの設定オブジェクトに手軽に追加したい場合に利用できます。

```ruby
config.x.payment_processing.schedule = :daily
Rails.configuration.x.payment_processing.schedule # => :daily
```

[カスタム設定](#カスタム設定)を参照。

#### `config.yjit`

Ruby 3.3以降でYJITを有効にするための設定です。メモリ制約のある環境でデプロイする場合は、`false`に設定できます。

| 以下のバージョン以降      | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.2                   | `true`               |

### アセットを設定する

#### `config.assets.css_compressor`

CSSの圧縮に用いるプログラムを定義します。このオプションは、`sass-rails`によってデフォルトで設定されます。現時点で他に設定できるのは`:yui`オプションだけです。この場合`yui-compressor` gemを利用します。

#### `config.assets.js_compressor`

JavaScriptの圧縮に使うプログラムを定義します。指定できる値は`:terser`、`:closure`、`:uglifier`、`:yui`です。それぞれ`terser` gem、`closure-compiler` gem、`uglifier` gem、`yui-compressor` gemに対応します。

#### `config.assets.gzip`

gzipされていないバージョンの作成に加えて、コンパイル済みアセットのgzipバージョン作成も有効にするかどうかを指定するフラグです。デフォルト値は`true`です。

#### `config.assets.paths`

アセット探索用のパスを指定します。この設定オプションにパスを追加すると、アセットの探索先として追加されます。

#### `config.assets.precompile`

`application.css`と`application.js`以外に追加したいアセットがある場合に指定します。これらは`bin/rails assets:precompile`を実行するときに一緒にプリコンパイルされます。

#### `config.assets.unknown_asset_fallback`

アセットがパイプラインにない場合のアセットパイプラインの挙動の変更に使います（sprockets-rails 3.2.0以降を使う場合）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| 以下のバージョン以降      | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 5.1                   | `false`              |

#### `config.assets.prefix`

アセットを置くディレクトリを指定します。デフォルト値は`/assets`です。

#### `config.assets.manifest`

アセットプリコンパイラのマニフェストファイルで使うフルパスを定義します。デフォルトでは、`config.assets.prefix`で指定された`public/`フォルダ内にある`manifest-<ランダム>.json`という名前のファイルになります。

#### `config.assets.digest`

アセット名に使うSHA256フィンガープリントを有効にするかどうかを指定します。デフォルトで`true`に設定されます。

#### `config.assets.debug`

デバッグ用にアセットの結合と圧縮をやめるかどうかを指定します。`development.rb`ではデフォルトで`true`に設定されます。

#### `config.assets.version`

SHA256ハッシュ生成に使われるオプション文字列です。この値を変更すると、すべてのアセットファイルが強制的に再コンパイルされます。

#### `config.assets.compile`

production環境での動的なSprocketsコンパイルをオンにするかどうかを指定するboolean値です。

#### `config.assets.logger`

ロガーを引数に取ります。このロガーは、Log4rのインターフェイスか、Rubyの`Logger`クラスに従います。デフォルトでは、`config.logger`と同じ設定が使われます。`config.assets.logger`を`false`に設定すると、配信されたアセットのログ出力がオフになります

#### `config.assets.quiet`

アセットへのリクエストのログ出力を無効にします。デフォルトでは`config/environments/development.rb`で`true`に設定されます。

### ジェネレータを設定する

`config.generators`メソッドを使って、Railsで使うジェネレータを変更できます。このメソッドはブロックを1つ受け取ります。

```ruby
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
```

ブロックで利用可能なメソッドの完全なリストは以下のとおりです。

* `force_plural`: モデル名を複数形にするかどうかを指定します。デフォルト値は`false`です。

* `helper`: ヘルパーを生成するかどうかを指定します。デフォルト値は`true`です。

* `integration_tool`: 結合テストの生成に使う統合ツールを定義します。デフォルト値は`:test_unit`です。

* `system_tests`: システムテスト生成に用いる統合ツールを定義します。デフォルト値は`:test_unit`です。

* `orm`: 使うORM（オブジェクトリレーショナルマッピング）を指定します。デフォルト値は`false`であり、この場合はActive Recordが使われます。

* `resource_controller`: `rails generate resource`の実行時にどのジェネレータでコントローラを生成するかを指定します。デフォルト値は`:controller`です。

* `resource_route`: リソースのルーティング定義を生成すべきかどうかを定義します。デフォルト値は`true`です。

* `scaffold_controller`: `resource_controller`と同じではありません。`bin/rails generate scaffold`を実行したときに **scaffold**でどのジェネレータでコントローラを生成するかを指定します。デフォルト値は`:scaffold_controller`です。

* `test_framework`: 利用するテストフレームワークを指定します。デフォルト値は`false`であり、この場合minitestが使われます。

* `template_engine`: ビューのテンプレートエンジン（ERBやHamlなど）を指定します。デフォルト値は`:erb`です。

* `apply_rubocop_autocorrect_after_generate!`: Railsジェネレータ実行後にRuboCopのオートコレクト機能を適用します。

### ミドルウェアを設定する

どのRailsアプリケーションの背後にも、いくつかの標準的なミドルウェアが配置されています。development環境では、以下の順序でミドルウェアを使います。

#### `ActionDispatch::HostAuthorization`

DNSリバインディングやその他の`Host`ヘッダー攻撃を防ぎます。
development環境ではデフォルトで以下の設定が含まれます。

```ruby
Rails.application.config.hosts = [
  IPAddr.new("0.0.0.0/0"),        # すべてのIPv4アドレス
  IPAddr.new("::/0"),             # すべてのIPv6アドレス
  "localhost",                    # localhost予約済みドメイン
  ENV["RAILS_DEVELOPMENT_HOSTS"]  # 開発用の追加ホストリスト（カンマ区切り）
]
```

development以外の環境では、`Rails.application.config.hosts`は空になり、`Host`ヘッダーチェックは行われません。production環境でヘッダー攻撃から保護したい場合は、以下のように手動でホストを許可する必要があります。

```ruby
Rails.application.config.hosts << "product.com"
```

リクエストのホストは、case演算子（`#===`）で`hosts`のエントリと照合されるので、`Regexp`型、`Proc`型、`IPAddr`型のエントリが`hosts`でサポートされます。以下は正規表現を使った例です。

```ruby
# `www.product.com`や`beta1.product.com`のようなサブドメインからの
# リクエストを許可する
Rails.application.config.hosts << /.*\.product\.com/
```

指定した正規表現はアンカー（`\A`と`\z`）で囲まれるので、ホスト名全体とマッチしなければなりません。たとえば`/product.com/`はアンカーで囲まれると`www.product.com`とのマッチに失敗します。

特殊なケースとして、すべてのサブドメインの許可がサポートされます。

```ruby
# `www.product.com`や`beta1.product.com`のようなサブドメインからの
# リクエストを許可する
Rails.application.config.hosts << ".product.com"
```

Host Authorizationチェックで特定のリクエストを除外するには`config.host_authorization.exclude`を設定します。

```ruby
# /healthcheck/パスへのリクエストをホストチェックから除外する
Rails.application.config.host_authorization = {
  exclude: ->(request) { request.path.include?("healthcheck") }
}
```

許可されていないホストからのリクエストを受け取ると、デフォルトのRackアプリケーションが`403 Forbidden`レスポンスを返します。この動作は以下のように`config.host_authorization.response_app`を設定することでカスタマイズできます。

```ruby
Rails.application.config.host_authorization = {
  response_app: -> env do
    [400, { "Content-Type" => "text/plain" }, ["Bad Request"]]
  end
}
```

#### `ActionDispatch::ServerTiming`

サーバーのパフォーマンスメトリクスを含む[`Server-Timing`][]ヘッダーをレスポンスに追加します。このデータは、ブラウザのDevToolsの「Network」ペインでレスポンスを調べることで確認できます。ほとんどのブラウザには、このデータを可視化する「Timing」タブがあります。

[`Server-Timing`]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing

#### `ActionDispatch::SSL`

すべてのリクエストでHTTPSプロトコルを強制します。これは`config.force_ssl`を`true`にすると有効になります。渡すオプションは`config.ssl_options`で設定できます。

#### `ActionDispatch::Static`

静的アセットの配信に使います。`config.public_file_server.enabled`が`false`の場合は無効に設定されます。静的ディレクトリのインデックスファイルが`index`でない場合には、`config.public_file_server.index_name`を設定してください。たとえば、ディレクトリへのリクエストを`index.html`ではなく`main.html`で扱うには、`config.public_file_server.index_name`を`"main"`に設定します。

#### `ActionDispatch::Executor`

スレッドセーフなコード再読み込みを許可します。これは`config.allow_concurrency`が`false`の場合に無効になり、`Rack::Lock`が読み込まれるようになります。`Rack::Lock`はアプリケーションをミューテックスにラップするので、同時に1つのスレッドでしか呼び出されなくなります。

#### `ActiveSupport::Cache::Strategy::LocalCache`

基本的なメモリバックアップ式キャッシュとして機能します。このキャッシュはスレッドセーフではなく、単一スレッド用の一時メモリキャッシュとして機能するためのものである点にご注意ください。

#### `Rack::Runtime`

`X-Runtime`ヘッダーを設定します。このヘッダーには、リクエストの実行に要した時間（秒）が含まれます。

#### `Rails::Rack::Logger`

リクエストが開始されたことをログに通知します。リクエストが完了すると、すべてのログをフラッシュします。

#### `ActionDispatch::ShowExceptions`

アプリケーションから返されるすべての例外をrescueし、リクエストがローカルであるか`config.consider_all_requests_local`が`true`に設定されている場合に適切な例外ページを出力します。`config.action_dispatch.show_exceptions`が`:none`に設定されていると、常に例外が出力されます。

#### `ActionDispatch::RequestId`

レスポンスで利用できる独自の`X-Request-Id`ヘッダーを作成し、`ActionDispatch::Request#uuid`メソッドを有効にします。`config.action_dispatch.request_id_header`で設定可能です。

#### `ActionDispatch::RemoteIp`

IPスプーフィング攻撃が行われていないかどうかをチェックし、リクエストヘッダーから正しい`client_ip`を取得します。この設定は`config.action_dispatch.ip_spoofing_check`オプションと`config.action_dispatch.trusted_proxies`オプションで変更可能です。

#### `Rack::Sendfile`

bodyがファイルから配信されているレスポンスをインターセプトし、サーバー固有の`X-Sendfile`ヘッダーに差し替えてから送信します。この動作は`config.action_dispatch.x_sendfile_header`で設定可能です。

#### `ActionDispatch::Callbacks`

リクエストを処理する前に、事前コールバックを実行します。

#### `ActionDispatch::Cookies`

リクエストにcookieを設定します。

#### `ActionDispatch::Session::CookieStore`

セッションをcookieに保存する役割を担います。[`config.session_store`](#config-session-store)の値を変更すると別のミドルウェアを使えます。

#### `ActionDispatch::Flash`

`flash`キーを設定します。これは、[`config.session_store`](#config-session-store)に値が設定されている場合にのみ有効です。

#### `Rack::MethodOverride`

`params[:_method]`が設定されている場合にHTTPメソッドの上書きを許可します。これは、HTTPでPATCH、PUT、DELETEメソッドを使えるようにするミドルウェアです。

#### `Rack::Head`

すべてのHEADリクエストに対して空のbodyを返します。その他すべてのリクエストは変更されません。

#### カスタムミドルウェアを追加する

`config.middleware.use`メソッドを使うと、上記以外に独自のミドルウェアを追加することもできます。

```ruby
config.middleware.use Magical::Unicorns
```

上の指定により、`Magical::Unicorns`ミドルウェアがスタックの最後に追加されます。あるミドルウェアの前に別のミドルウェアを追加したい場合は`insert_before`を使います。

```ruby
config.middleware.insert_before Rack::Head, Magical::Unicorns
```

ミドルウェアはインデックスを用いて挿入箇所に正確に指定できます。たとえば、`Magical::Unicorns`ミドルウェアをスタックの最上位に挿入するには次のように設定します。

```ruby
config.middleware.insert_before 0, Magical::Unicorns
```

あるミドルウェアの後に別のミドルウェアを追加したい場合は`insert_after`を使います。

```ruby
config.middleware.insert_after Rack::Head, Magical::Unicorns
```

これらのミドルウェアは、まったく別のものに差し替えることもできます。

```ruby
config.middleware.swap ActionController::Failsafe, Lifo::Failsafe
```

ミドルウェアをある位置から別の位置に移動できます。

```ruby
config.middleware.move_before ActionDispatch::Flash, Magical::Unicorns
```

上は`Magical::Unicorns`ミドルウェアを`ActionDispatch::Flash`の直前に移動します。

以下のように直後に移動することもできます。

```ruby
config.middleware.move_after ActionDispatch::Flash, Magical::Unicorns
```

ミドルウェアをスタックから完全に取り除くこともできます。

```ruby
config.middleware.delete Rack::MethodOverride
```

### i18nを設定する

以下のオプションはすべて`i18n`（internationalization: 国際化）ライブラリ用のオプションです。

#### `config.i18n.available_locales`

アプリケーションで利用できるロケールの許可リストを定義します。デフォルトでは、ロケールファイルにあるロケールキーはすべて有効になりますが、新しいアプリケーションの場合、通常は`:en`だけです。

#### `config.i18n.default_locale`

アプリケーションのi18nで使われるデフォルトのロケールを設定します。デフォルト値は`:en`です。

#### `config.i18n.enforce_available_locales`

これをオンにすると、`available_locales`リストで宣言されていないロケールはi18nに渡せなくなります。利用できないロケールがある場合は`i18n::InvalidLocale`例外が発生します。デフォルト値は`true`です。このオプションは、ユーザー入力のロケールが不正である場合のセキュリティ対策であるため、特別な理由がない限り無効にしないことをおすすめします。

#### `config.i18n.load_path`

ロケールファイルの探索パスを設定します。デフォルト値は`config/locales/*.{yml,rb}`です。

#### `config.i18n.raise_on_missing_translations`

コントローラやビューで訳文が見つからない場合にエラーをraiseするかどうかを指定します。
`true`に設定すると、ビューやコントローラが`I18n::MissingTranslationData`をraiseします。`:strict`に設定するとモデルもエラーをraiseします。デフォルト値は`false`です。

#### `config.i18n.fallbacks`

訳文がない場合のフォールバック動作を設定します。ここではオプションの3つの使い方を説明します。

  * デフォルトのロケールをフォールバック先として使う場合は次のように`true`を設定します。

  ```ruby
  config.i18n.fallbacks = true
  ```

  * ロケールの配列をフォールバック先に使う場合は次のようにします。

  ```ruby
  config.i18n.fallbacks = [:tr, :en]
  ```

  * ロケールごとに個別のフォールバックを設定することも可能です。たとえば`:az`に`:tr`を、`:da`に`:de`と`:en`をそれぞれフォールバック先として指定する場合は、次のようにします。

  ```ruby
  config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
  # または
  config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }
  ```

### Active Modelを設定する

#### `config.active_model.i18n_customize_full_message`

[`Error#full_message`][ActiveModel::Error#full_message]エラーフォーマットをi18nのロケールファイルで上書きしてよいかどうかを制御するboolean値です。デフォルト値は`false`です。

`true`に設定すると、`full_message`はロケールファイルの属性とモデルレベルでフォーマットを探索します。デフォルトのフォーマットは`"%{attribute} %{message}"`で、`attribute`は属性名、`message`はバリデーション固有のメッセージです。以下の例では、すべての`Person`属性と、特定の`Person`属性（`age`）のフォーマットをオーバーライドしています。

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :age

  validates :name, :age, presence: true
end
```

```yml
en:
  activemodel: # またはactiverecord:
    errors:
      models:
        person:
          # すべてのPerson属性についてフォーマットをオーバーライドする
          format: "Invalid %{attribute} (%{message})"
          attributes:
            age:
              # このage属性についてフォーマットをオーバーライドする
              format: "%{message}"
              blank: "Please fill in your %{attribute}"
```

```irb
irb> person = Person.new.tap(&:valid?)

irb> person.errors.full_messages
=> [
  "Invalid Name (can't be blank)",
  "Please fill in your Age"
]

irb> person.errors.messages
=> {
  :name => ["can't be blank"],
  :age  => ["Please fill in your Age"]
}
```

[ActiveModel::Error#full_message]: https://api.rubyonrails.org/classes/ActiveModel/Error.html#method-i-full_message

### Active Recordを設定する

`config.active_record`には多くのオプションが含まれています。

#### `config.active_record.logger`

Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは以後作成されるすべての新しいデータベース接続に渡されます。Active Recordのモデルクラスまたはモデルインスタンスに対して`logger`メソッドを呼び出すと、このロガーを取り出せます。ログ出力を無効にするには`nil`を設定します。

#### `config.active_record.primary_key_prefix_type`

主キーカラムの命名法を変更するのに使います。Railsでは、主キーカラムの名前にデフォルトで`id`が使われます（なお`id`にする場合は値の設定は不要です）。`id`以外に以下の2つを指定できます。

* `:table_name`: たとえばCustomerクラスの主キーは`customerid`になります
* `:table_name_with_underscore`: たとえばCustomerクラスの主キーは`customer_id`になります

#### `config.active_record.table_name_prefix`

テーブル名の冒頭にグローバルに追加したい文字列を指定します。たとえば`northwest_`を指定すると、Customerクラスは`northwest_customers`をテーブルとして探します。デフォルト値は空文字列です。

#### `config.active_record.table_name_suffix`

テーブル名の末尾にグローバルに追加したい文字列を指定します。たとえば`_northwest`を指定すると、Customerクラスは`customers_northwest`をテーブルとして探します。デフォルト値は空文字列です。

#### `config.active_record.schema_migrations_table_name`

スキーママイグレーションのテーブル名に使う文字列を指定します。

#### `config.active_record.internal_metadata_table_name`

内部のメタテーブル名に使う文字列を設定できます。

#### `config.active_record.protected_environments`

破壊的操作を禁止すべき環境名を配列で設定できます。

#### `config.active_record.pluralize_table_names`

Railsが探すデータベースのテーブル名を単数形にするか複数形にするかを指定します。`true`に設定すると、Customerクラスが使うテーブル名は複数形の`customers`になります（デフォルト）。`false`に設定すると、Customerクラスが使うテーブル名は単数形の`customer`になります。

#### `config.active_record.default_timezone`

データベースから日付・時刻を取り出した際のタイムゾーンを`Time.local`（`:local`を指定した場合）と`Time.utc`（`:utc`を指定した場合）のどちらにするかを指定します。デフォルト値は`:utc`です。

#### `config.active_record.schema_format`

データベーススキーマをファイルに書き出すときのフォーマットを指定します。デフォルト値は`:ruby`で、データベースには依存せず、マイグレーションに依存します。`:sql`を指定するとSQL文で書き出されますが、この場合潜在的にデータベースに依存する可能性があります。

#### `config.active_record.error_on_ignored_order`

バッチクエリの実行中にクエリの順序が無視された場合にエラーをraiseすべきかどうかを指定します。オプションは`true`（エラーをraise）または`false`（警告）で、デフォルト値は`false`です。

#### `config.active_record.timestamped_migrations`

マイグレーションファイル名にシリアル番号とタイムスタンプのどちらを与えるかを指定します。デフォルト値は`true`で、タイムスタンプが使われます。複数の開発者が作業する場合は、タイムスタンプの利用をおすすめします。

#### `config.active_record.automatically_invert_plural_associations`

複数形の名前を持つ逆関連付けをActive Recordが自動的に探索するかどうかを指定します。

例:

```ruby
class Post < ApplicationRecord
  has_many :comments
end

class Comment < ApplicationRecord
  belongs_to :post
end
```

従来は、Active Recordは上のコードの`Post`モデルで単数形の`:comment`関連付けのみを探索するだけで、見つけられませんでした。

このオプションを有効にすると、複数形の`:comments`関連付けも検索します。ほとんどの場合、逆関連付けを検出すると無駄なクエリを回避できるため便利ですが、それを想定していないレガシーコードとの下位互換性問題が発生する可能性があります。

この振る舞いはモデル単位で無効にできます。

```ruby
class Comment < ApplicationRecord
  self.automatically_invert_plural_associations = false

  belongs_to :post
end
```

以下のように関連付け単位でも設定できます。

```ruby
class Comment < ApplicationRecord
  self.automatically_invert_plural_associations = true

  belongs_to :post, inverse_of: nil
end
```

| 以下のバージョン以降      | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |

#### `config.active_record.validate_migration_timestamps`

マイグレーションのタイムスタンプを検証するかどうかを制御します。
有効にすると、マイグレーションファイル名のタイムスタンプが現在の時刻に関連付けられるタイムスタンプより1日以上進んでいる場合は、エラーが発生します。これは、マイグレーションファイルが未来の日付になるのを防ぐためです。日付が未来になると、マイグレーションの生成やその他のマイグレーションコマンドに影響する可能性があります。
`config.active_record.timestamped_migrations`は`true`に設定する必要があります。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| 以下のバージョン以降      | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.2                   | `true`               |

#### `config.active_record.db_warnings_action`

SQLクエリで警告が発生したときの動作を制御します。以下のオプションが利用可能です。

  * `:ignore`: データベースの警告は無視されます（デフォルト）。

  * `:log`: データベースの警告を`ActiveRecord.logger`を用いて`:warn`レベルで記録します。

  * `:raise`: データベースの警告を`ActiveRecord::SQLWarning`としてraiseします。

  * `:report`: Railsの`ErrorReporter`のサブスクライバに報告します。

  * カスタム`proc`: カスタム`proc`を提供できます。これは`SQLWarning`エラーオブジェクトを受け取れる必要があります。

    例:

    ```ruby
    config.active_record.db_warnings_action = ->(warning) do
      # カスタム例外報告サービスに報告する
      Bugsnag.notify(warning.message) do |notification|
        notification.add_metadata(:warning_code, warning.code)
        notification.add_metadata(:warning_level, warning.level)
      end
    end
    ```

#### `config.active_record.db_warnings_ignore`

設定された`db_warnings_action`にかかわらず無視する警告コードとメッセージの許可リストを指定します。

デフォルトの振る舞いでは、すべての警告を報告します。無視する警告は、以下のように文字列または正規表現で指定できます。たとえば、以下のようになります：

  ```ruby
  config.active_record.db_warnings_action = :raise
  # 以下の警告はraiseされなくなる
  config.active_record.db_warnings_ignore = [
    /Invalid utf8mb4 character string/,
    "An exact warning message",
    "1062", # MySQL Error 1062: Duplicate entry
  ]
  ```

#### `config.active_record.migration_strategy`

マイグレーションでスキーマステートメントのメソッド実行に使うストラテジークラスを制御します。
デフォルトのクラスはコネクションアダプタに委譲されます。
カスタムストラテジーは、`ActiveRecord::Migration::ExecutionStrategy`（または`DefaultStrategy`）を継承して、実装されていないメソッドのデフォルト動作を保持する必要があります。

```ruby
class CustomMigrationStrategy < ActiveRecord::Migration::DefaultStrategy
  def drop_table(*)
    raise "Dropping tables is not supported!"
  end
end

config.active_record.migration_strategy = CustomMigrationStrategy
```

#### `config.active_record.lock_optimistically`

Active Recordで楽観的ロック（optimistic locking）を使うかどうかを指定します。デフォルト値は`true`（利用する）です。

#### `config.active_record.cache_timestamp_format`

キャッシュキーに含まれるタイムスタンプ値の形式を指定します。デフォルト値は`:usec`です。

#### `config.active_record.record_timestamps`

モデルで発生する`create`操作や`update`操作にタイムスタンプを付けるかどうかを指定します。デフォルト値は`true`です。

#### `config.active_record.partial_inserts`

新規レコード作成で部分書き込みを行うかどうか（挿入時にデフォルトと異なる属性だけを設定するかどうか）を指定するboolean値です。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 7.0以降                | `false`              |

#### `config.active_record.partial_updates`

既存レコードの更新で部分書き込みを行なうかどうか（「dirty」とマークされた属性だけを更新するか）を指定するboolean値です。データベースで部分書き込みを使う場合は、`config.active_record.lock_optimistically`で楽観的ロックも有効にする必要がある点にご注意ください。これは更新処理が並行して実行された場合に、読み込み中の古い情報に基づいて属性に書き込まれる可能性があるためです。デフォルト値は`true`です。

#### `config.active_record.maintain_test_schema`

テスト実行時にActive Recordがテスト用データベーススキーマを`db/schema.rb`（または`db/structure.sql`）に基づいて最新の状態にするかどうかを指定します。デフォルト値は`true`です。

#### `config.active_record.dump_schema_after_migration`

マイグレーション実行時にスキーマダンプ（`db/schema.rb`または`db/structure.sql`）を行なうかどうかを指定します。このオプションは、Railsが生成する`config/environments/production.rb`では`false`に設定されます。この設定が無指定の場合は、デフォルトの`true`が指定されます。

#### `config.active_record.dump_schemas`

`db:structure:dump`の呼び出し時にデータベーススキーマをダンプするかどうかを指定します。利用可能なオプションは、`:schema_search_path`（デフォルト、`schema_search_path`内のすべてのスキーマをダンプ）、`:all`（`schema_search_path`と無関係にすべてのスキーマをダンプ）、またはスキーマ文字列（カンマ区切り）です。

#### `config.active_record.before_committed_on_all_records`

トランザクションに登録されているすべてのレコードに対して、`before_committed!`コールバックを有効にします。
従来の動作は、トランザクションに登録されている同じレコードのコピーが複数ある場合、レコードの最初のコピーに対してのみコールバックを実行します。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
|（オリジナル）            | `false`              |
| 7.1以降                | `true`               |

#### `config.active_record.belongs_to_required_by_default`

`belongs_to`関連付けが存在しない場合にレコードのバリデーションを失敗させるかどうかを指定するboolean値です。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `nil`                |
| 5.0以降                | `true`               |

#### `config.active_record.belongs_to_required_validates_foreign_key`

親が必須である場合に、親に関連するカラムについてのみ存在をバリデーションします。
従来の動作では、親レコードの存在をバリデーションするときに、親が変更されていない場合でも、子レコードが更新されるたびに親を取得するクエリが余分に実行されていました。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 7.1以降                | `false`              |

#### `config.active_record.marshalling_format_version`

`7.1`に設定すると、Active Recordインスタンスを`Marshal.dump`でより効率的にシリアライズ可能になります。

これによりシリアライズ形式が変更されるため、この方法でシリアライズされたモデルは古いバージョンのRails（< 7.1）では読み込めなくなります。
ただし、この最適化が有効かどうかにかかわらず、古い形式が使われているメッセージは引き続き読み込めます。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `6.1`                |
| 7.1以降                | `7.1`                |

#### `config.active_record.action_on_strict_loading_violation`

関連付けに`strict_loading`が設定されている場合に、例外をraiseするかログに出力するかを設定します。デフォルト値はすべての環境で`:raise`です。これを`:log`に変更すると、例外をraiseせずにロガーに送信できます。

#### `config.active_record.strict_loading_by_default`

`strict_loading`モードをデフォルトで有効にするか無効にするかを指定するboolean値です。デフォルト値は`false`です。

#### `config.active_record.strict_loading_mode`

strict loadingを報告するモードを設定します。デフォルトは`:all`です。
`:n_plus_one_only`に変更することで、N+1クエリにつながる関連付けを読み込むときにのみ報告するようにできます。

#### `config.active_record.index_nested_attribute_errors`

ネストした`has_many`関連付けのエラーをインデックス付きでエラー表示するかどうかを指定します。デフォルト値は`false`です。

#### `config.active_record.use_schema_cache_dump`

（`bin/rails db:schema:cache:dump`で生成された）`db/schema_cache.yml`のスキーマ情報を、データベースにクエリを送信しなくてもユーザーが取得できるようにするかどうかを指定します。デフォルト値は`true`です。

#### `config.active_record.cache_versioning`

キャッシュバージョン変更を伴う安定した`#cache_key`メソッドを`#cache_version`メソッドで使うかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.2以降                | `true`               |

#### `config.active_record.collection_cache_versioning`

`ActiveRecord::Relation`型でキャッシュされたオブジェクトが、そのリレーションのキャッシュキーの揮発性の情報（updated atとcountの最大値）をキャッシュキーの再利用サポートのためにキャッシュバージョンに移動したときに、同じキャッシュキーが再利用されるようにします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 6.0以降                | `true`               |

#### `config.active_record.has_many_inversing`

`belongs_to`関連付けを`has_many`関連付けにトラバースするときに逆方向の（inverse）レコードを設定できるようにします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 6.1以降                | `true`               |

#### `config.active_record.automatic_scope_inversing`

スコープ付き関連付けで`inverse_of`を自動的に推論するようにします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

#### `config.active_record.destroy_association_async_job`

関連付けられたレコードの非同期削除に使うジョブを指定します。デフォルト値は`ActiveRecord::DestroyAssociationAsyncJob`です。

#### `config.active_record.destroy_association_async_batch_size`

`dependent: :destroy_async`関連オプションによってバックグラウンドジョブで破棄されるレコードの最大数を指定できます。

他の条件が同じであれば、バッチサイズが小さいほど、エンキューされるバックグラウンドジョブの個数が増える代わりに個別の実行時間が短くなり、バッチサイズが大きいほど、エンキューされるバックグラウンドジョブの個数が減る代わりに個別の実行時間が長くなります。

このオプションのデフォルトは`nil`で、指定された関連付けのすべての依存レコードが同じバックグラウンドジョブで破棄されます。

#### `config.active_record.queues.destroy`

非同期の破棄ジョブに使うActive Jobキューを指定できます。このオプションを`nil`にすると、purgeジョブがデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。デフォルト値は`nil`です。

#### `config.active_record.enumerate_columns_in_select_statements`

`true`にすると、`SELECT`文に常にカラム名が含まれるようになり、`SELECT * FROM ...`のようなワイルドカードクエリを回避します。これにより、PostgreSQLデータベースにカラムを追加するときなどに、prepared statementのキャッシュエラーを回避できるようになります。デフォルト値は`false`です。

#### `config.active_record.verify_foreign_keys_for_fixtures`

フィクスチャがテストに読み込まれた後で、すべての外部キー制約が有効になるようにします（PostgreSQLとSQLiteのみ）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

#### `config.active_record.raise_on_assign_to_attr_readonly`

`attr_readonly`属性への代入時のraiseを有効にします。
従来の動作では代入してもraiseしませんが、変更がデータベースで永続化されません。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1以降                | `true`               |

#### `config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction`

Active Recordの複数のインスタンスがトランザクション内で同一のレコードを変更する場合、そのうちの1つに対してのみ`after_commit`または`after_rollback`コールバックを実行します。このオプションは、どのインスタンスがコールバックを受け取るかをRailsが選択する方法を指定します。

`true`の場合、トランザクションコールバックは、そのインスタンスのステートが古くなっていても、最初に`save`されるインスタンスで実行されます。

`false`の場合、トランザクションコールバックは、ステートが最新であるインスタンスで実行されます。これらのインスタンスは次のように選択されます。

- 一般に、トランザクション内の所定のレコードを`save`する場合は、最新のインスタンスでトランザクションコールバックを実行します。
- ただし例外が2つあります。
    - トランザクション内でレコードが作成され、その後別のインスタンスで更新された場合、`after_create_commit`コールバックは2番目のインスタンスで実行されます。これは、インスタンスのステートに基づいてナイーブに実行される`after_update_commit`コールバックの代わりに実行されます。
    - レコードがトランザクション内で破棄された場合、`after_destroy_commit`コールバックは最後に破棄されたインスタンスで実行されます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 7.1以降                | `false`              |

#### `config.active_record.default_column_serializer`

カラムでシリアライザが明示的に指定されていない場合に使うシリアライザーの実装です。

歴史的に`serialize`と`store`は異なるシリアライザ実装を利用可能ですが、デフォルトでは`YAML`を利用します。しかし、このフォーマットはあまり効率的ではなく、慎重に採用しないとセキュリティの脆弱性の原因となる可能性があります。

そのため、データベースのシリアライズには、従来よりも厳格かつ限定的なフォーマットを選択することが推奨されます。

残念ながら、Rubyの標準ライブラリには適切なデフォルトがありません。`JSON`はフォーマットとして機能しますが、`json` gemsはサポートされていない型を文字列にキャストするため、バグを引き起こす可能性があります。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `YAML`               |
| 7.1以降                | `nil`                |

#### `config.active_record.run_after_transaction_callbacks_in_order_defined`

`true`にすると、`after_commit`コールバックはモデル内で定義された順に実行されます。`false`にすると、逆順に実行されます。

その他のコールバックは、常にモデルで定義された順序で実行されます（`prepend: true`を使わない限り）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1以降                | `true`               |

#### `config.active_record.query_log_tags_enabled`

クエリコメントをアダプタレベルで有効にするかどうかを指定します。
デフォルト値は`false`です。ただしデフォルトで生成される`config/environments/development.rb`ファイルでは`true`に設定されます。

NOTE: これを`true`に設定すると、データベースの「prepared statement」は自動的に無効になります。

#### `config.active_record.query_log_tags`

SQLコメントに挿入するキーバリュータグを指定する`Array`を定義します。
デフォルト値は、`[ :application, :controller, :action, :job ]`です。
利用可能なタグは、`:application`、`:controller`、`:namespaced_controller`、`:action`、`:job`、`:source_location`です。

#### `config.active_record.query_log_tags_format`

`QueryLogs`のタグに使うフォーマッタを`Symbol`で指定します。有効な値は`:sqlcommenter`と`:legacy`です。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:legacy`            |
| 7.1以降                | `:sqlcommenter`      |

#### `config.active_record.cache_query_log_tags`

クエリログタグのキャッシュを有効にするかどうかを指定します。クエリ数が非常に多いアプリケーションでは、クエリログタグのキャッシュを有効にすると、リクエストやジョブの実行中にコンテキストが変更されない場合にパフォーマンスが向上します。
デフォルト値は`false`です。

#### `config.active_record.schema_cache_ignored_tables`

スキーマキャッシュの生成中に無視するテーブルのリストを定義します。テーブル名を表す文字列の`Array`または正規表現を指定できます。

#### `config.active_record.verbose_query_logs`

データベースクエリを呼び出すメソッドのソースコードの位置を、関連するクエリでログに出力するかどうかを指定します。デフォルトでは、development環境で`true`、それ以外の環境では`false`に設定されます。

#### `config.active_record.sqlite3_adapter_strict_strings_by_default`

SQLite3Adapterを"strict strings"モードで利用するかどうかを指定します。
このモードにすると、二重引用符（`""`）で囲まれた文字列リテラルが無効になります。

SQLiteは、二重引用符で囲まれた文字列リテラルに関していくつかの癖があります。
SQLiteは最初に、二重引用符で囲まれた文字列を識別子名と見なそうとしますが、識別子が存在しない場合は文字列リテラルと見なします。このため、入力ミスを見落とす可能性があります。たとえば、存在しないカラムに対してインデックスを作成できてしまいます。

詳しくは[SQLiteのドキュメント](https://www.sqlite.org/quirks.html#double_quoted_string_literals_are_accepted)を参照してください。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1以降                | `true`               |

#### `config.active_record.postgresql_adapter_decode_dates`

PostgresqlAdapterでdateカラムをデコードするかどうかを指定します。

```ruby
ActiveRecord::Base.connection
     .select_value("select '2024-01-01'::date").class #=> Date
```

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.2                   | `true`               |

#### `config.active_record.async_query_executor`

非同期クエリをプールする方法を指定します。

デフォルトは`nil`で、この場合`load_async`は無効になり、クエリをフォアグラウンドで直接実行します。
クエリを実際に非同期実行する場合は、必ず`:global_thread_pool`または`:multi_thread_pool`を指定しなければなりません。

`:global_thread_pool`: アプリケーションが接続するすべてのデータベースで単一のプールを使います。この設定は、データベースが1つしかないアプリケーションや、データベースのシャードに1度に1件しかクエリを発行しないアプリケーションに適しています。

`:multi_thread_pool`: データベースごとに1つのプールを使います。各プールのサイズは、`database.yml`ファイルの`max_threads`プロパティや`min_thread`プロパティで設定できます。この設定は、クエリを複数のデータベースに対して発行することが多いアプリケーションで、並行処理の最大数をより正確に定義したい場面で有用です。

#### `config.active_record.global_executor_concurrency`

`config.active_record.async_query_executor = :global_thread_pool`設定で、並行（concurrent）に実行できる非同期クエリの個数を定義します。

デフォルトは`4`です。

この数値を検討するときは、`database.yml`で設定されているデータベースコネクションのプールサイズと調和させなければなりません。コネクションプールのサイズは、フォアグラウンドのスレッド（Webサーバーやジョブワーカーのスレッド）とバックグラウンドのスレッドを両方とも扱えるサイズにする必要があります。

Railsはプロセスごとに、この個数のスレッドを用いて非同期クエリを処理するグローバルクエリエグゼキュータを1つ作成します。したがって、プールサイズは`thread_count + global_executor_concurrency + 1`以上である必要があります。たとえば、Webサーバーの最大スレッド数が3で、`global_executor_concurrency`が4に設定されている場合、プールサイズは8以上にする必要があります。

#### `config.active_record.yaml_column_permitted_classes`

デフォルトは`[Symbol]`です。ここで追加したクラスのリストは、`ActiveRecord::Coders::YAMLColumn`の`safe_load()`でアプリケーションに含まれるようになります。

#### `config.active_record.use_yaml_unsafe_load`

デフォルトは`false`です。アプリケーションが`ActiveRecord::Coders::YAMLColumn`に対して`unsafe_load`を利用することを許可します。

#### `config.active_record.raise_int_wider_than_64bit`

デフォルトは`true`です。PostgreSQLアダプタに64ビット符号付き整数表現を超える整数が渡された場合に例外を発生させるかどうかを指定します。

#### `config.active_record.generate_secure_token_on`

`has_secure_token`宣言の値が生成されるタイミングを制御します。デフォルトでは、モデルが初期化されたときに値が生成されます。

```ruby
class User < ApplicationRecord
  has_secure_token
end

record = User.new
record.token # => "fwZcXX6SkJBJRogzMdciS7wf"
```
`config.active_record.generate_secure_token_on = :create`を指定すると、モデルの作成時に値が生成されます。

```ruby
# config/application.rb

config.active_record.generate_secure_token_on = :create

# app/models/user.rb
class User < ApplicationRecord
  has_secure_token on: :create
end

record = User.new
record.token # => nil
record.save!
record.token # => "fwZcXX6SkJBJRogzMdciS7wf"
```

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:create`            |
| 7.1以降                | `:initialize`        |


#### `config.active_record.permanent_connection_checkout`

`ActiveRecord::Base.connection`の振る舞いを、「エラーを発生」「非推奨警告を表示」「どちらも行わない」のどれにするかを制御します。

`ActiveRecord::Base.connection`は、プールからデータベースコネクションをチェックアウトし、リクエストやジョブの終了までリースされた状態にします。この振る舞いは、利用可能なコネクション数よりも多くのスレッドまたはファイバーを用いる環境では望ましくない場合があります。

この設定を使うことで、`ActiveRecord::Base.connection`を呼び出すコードをトラッキングして削除し、代わりに`ActiveRecord::Base.with_connection`を利用する形に移行できます。

設定可能な値は、`:disallowed`（エラーを発生）、`:deprecated`（非推奨警告）、`true`（どちらも行わない）です。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`              |

#### `config.active_record.database_cli`

`rails dbconsole`を実行するときにデータベースへのアクセスに利用するCLIツールを制御します。デフォルトでは、データベースの標準ツールが使われます（例: PostgreSQLの場合は`psql`、MySQLの場合は`mysql`）。このオプションは、データベースシステムごとにツールを指定するハッシュを受け取り、フォールバックオプションが必要な場合は配列を渡せます。

```ruby
# config/application.rb
config.active_record.database_cli = { postgresql: "pgcli", mysql: %w[ mycli mysql ] }
```

#### `ActiveRecord::ConnectionAdapters::Mysql2Adapter.emulate_booleans`と`ActiveRecord::ConnectionAdapters::TrilogyAdapter.emulate_booleans`

Active RecordのMySQLアダプタがすべての`tinyint(1)`カラムをデフォルトでbooleanと認識するかどうかを指定します。デフォルト値は`true`です。

#### `ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables`

PostgreSQLが作成するデータベースを「unlogged」にすべきかどうかを制御します。unloggedにするとパフォーマンスは向上しますが、データベースがクラッシュしたときのデータ喪失リスクも増加します。production環境ではこれを有効にしないことを強くおすすめします。デフォルトではすべての環境で`false`になります。

test環境で有効にするには以下のようにします。

```ruby
# config/environments/test.rb

ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.create_unlogged_tables = true
end
```

#### `ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type`

マイグレーションやスキーマで`datetime`を呼び出したときに、Active RecordのPostgreSQLアダプタが使うネイティブ型を指定します。この設定が受け取るシンボルは、`NATIVE_DATABASE_TYPES`で設定された内容のいずれかに対応していなければなりません。デフォルト値は`:timestamp`で、この場合マイグレーション内の`t.datetime`で「タイムゾーンなしのタイムスタンプ」が作成されます。

「タイムゾーンありのタイムスタンプ」を利用するには以下のように設定します。

```ruby
# config/application.rb

ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
```

#### `ActiveRecord::SchemaDumper.ignore_tables`

生成されるどのスキーマファイルにも**含めたくない**テーブル名の配列を渡せます。

#### `ActiveRecord::SchemaDumper.fk_ignore_pattern`

外部キー名をdb/schema.rbにダンプすべきかどうかを指定する正規表現を変更できます。デフォルトでは、`fk_rails_`で始まる外部キー名はデータベースのスキーマダンプにエクスポートされません。デフォルト値は`/^fk_rails_[0-9a-f]{10}$/`です。

#### `config.active_record.encryption.add_to_filter_parameters`

`inspect`で暗号化属性を自動フィルタリングで除外するかどうかを指定します。

デフォルト値は`true`です。

#### `config.active_record.encryption.hash_digest_class`

Active Record Encryptionで利用するダイジェストアルゴリズムを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値                |
|-----------------------|---------------------------|
| （オリジナル）           | `OpenSSL::Digest::SHA1`   |
| 7.1以降                | `OpenSSL::Digest::SHA256` |

#### `config.active_record.encryption.support_sha1_for_non_deterministic_encryption`

SHA-1ダイジェストクラスを用いて暗号化された既存のデータの復号サポートを有効にします。`false`の場合、`config.active_record.encryption.hash_digest_class`で設定されたダイジェストのみをサポートします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値                |
|-----------------------|---------------------------|
| （オリジナル）           | `true`                    |
| 7.1以降                | `false`                   |

#### `config.active_record.encryption.compressor`

Active Record暗号化で利用する圧縮ライブラリを設定します。デフォルト値は`Zlib`です。
これを`deflate`と`inflate`に応答するクラスに設定することで、独自の圧縮ライブラリを利用できます。

#### `config.active_record.protocol_adapters`

データベースコネクションをURLで構成する場合、このオプションはプロトコルと背後のデータベースアダプタへのマッピングを提供します。たとえば、環境変数で`DATABASE_URL=mysql://localhost/database`を指定するとRailsは`mysql`を`mysql2`アダプタにマッピングしますが、アプリケーションでこれらのマッピングを以下のようにオーバーライドすることも可能です。

```ruby
config.active_record.protocol_adapters.mysql = "trilogy"
```

マッピングが見つからない場合、プロトコルがアダプタ名として使われます。

### Action Controllerを設定する

`config.action_controller`には多数の設定が含まれています。

#### `config.action_controller.asset_host`

アセットを置くホストを設定します。これは、アセットをホストする場所としてアプリケーションサーバーの代わりにCDN(コンテンツ配信ネットワーク)を使いたい場合に便利です。この設定を使うのは、Action Mailerで別の設定を使う場合だけにとどめてください。それ以外の場合は`config.asset_host`をお使いください。

#### `config.action_controller.perform_caching`

Action Controllerコンポーネントが提供するキャッシュ機能をアプリケーションで使うかどうかを指定します。developmentモードでは`false`、productionモードでは`true`に設定します。指定のない場合は`true`になります。

#### `config.action_controller.default_static_extension`

キャッシュされたページに与える拡張子を指定します。デフォルト値は`.html`です。

#### `config.action_controller.include_all_helpers`

すべてのビューヘルパーをあらゆる場所で使えるようにするか、対応するコントローラのスコープ内に限定するかを設定します。

`false`に設定すると、たとえば`UsersHelper`は`UsersController`の一部としてレンダリングされるビューでしか使えなくなります。`true`に設定すると、この`UsersHelper`はどこからでも使えるようになります。

デフォルト設定の振る舞い（このオプションに`true`や`false`が明示的に設定されていない場合）は、どのコントローラでもあらゆるビューヘルパーを使えます。

#### `config.action_controller.logger`

Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Controllerからの情報をログ出力するのに使われます。ログ出力を無効にするには`nil`を設定します。

#### `config.action_controller.request_forgery_protection_token`

RequestForgery対策用のトークンパラメータ名を設定します。`protect_from_forgery`を呼び出すと、デフォルトで`:authenticity_token`が設定されます。

#### `config.action_controller.allow_forgery_protection`

CSRF保護を有効にするかどうかを指定します。testモードではデフォルトで`false`に設定され、それ以外では`true`に設定されます。

#### `config.action_controller.forgery_protection_origin_check`

CSRFの追加対策として、HTTPの`Origin`ヘッダーがサイトのoriginと一致することをチェックすべきかどうかを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.0以降                | `true`               |

#### `config.action_controller.per_form_csrf_tokens`

CSRFトークンの正当性をそれらが生成されたメソッドやアクションに対してのみ認めるかどうかを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.0以降                | `true`               |

#### `config.action_controller.default_protect_from_forgery`

フォージェリ保護を`ActionController:Base`に追加するかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.2以降                | `true`               |

#### `config.action_controller.relative_url_root`

[サブディレクトリへのデプロイ](configuring.html#サブディレクトリにデプロイする（相対url-rootの利用）)を行っていることをRailsに指示するのに使えます。デフォルト値は[`config.relative_url_root`](#config-relative-url-root)です。

#### `config.action_controller.permit_all_parameters`

マスアサインメント（mass assignment）されるすべてのパラメータをデフォルトで許可することを設定します。デフォルト値は`false`です。

#### `config.action_controller.action_on_unpermitted_parameters`

明示的に許可されていないパラメータが見つかった場合にログ出力または例外発生を行なうかどうかを指定します。test環境とdevelopment環境でのデフォルト値は`:log`であり、それ以外の環境では`false`が設定されます。以下の値を指定できます。

* `false`: 何もしない
* `:log`: `ActiveSupport::Notifications.instrument`イベントを`unpermitted_parameters.action_controller`で発火し、DEBUGレベルでログ出力する
* `:raise`: `ActionController::UnpermittedParameters`例外をraiseする

#### `config.action_controller.always_permitted_parameters`

デフォルトで許可される許可リストパラメータのリストを設定します。デフォルト値は`['controller', 'action']`です。

#### `config.action_controller.enable_fragment_cache_logging`

フラグメントキャッシュの読み書きのログを以下のように詳細な形式で出力するかどうかを指定します。

```
Read fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/d0bdf2974e1ef6d31685c3b392ad0b74 (0.6ms)
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Write fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/3b4e249ac9d168c617e32e84b99218b5 (1.1ms)
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```

デフォルト値は`false`で、以下のように出力されます。

```
Rendered messages/_message.html.erb in 1.2 ms [cache hit]
Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
```

#### `config.action_controller.raise_on_missing_callback_actions`

コールバックの`:only`オプションや`:except`オプションで指定したアクションがコントローラ内に存在しない場合に`AbstractController::ActionNotFound`をraiseするかどうかを指定します。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1                   | `true`（developmentとtest）、`false`（その他の環境）|

#### `config.action_controller.raise_on_open_redirects`

外部リダイレクトをオプトインにすることで、アプリケーションが意図せずに外部ホストにリダイレクトされること（オープンリダイレクト（open redirect）とも呼ばれます）から保護します。

この設定が`true`の場合、外部ホストを含むURLが[`redirect_to`][]に渡されると、`ActionController::Redirecting::UnsafeRedirectError`が発生します。オープンリダイレクトを許可する必要がある場合は、`redirect_to`呼び出しに`allow_other_host: true`オプションを追加できます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

[`redirect_to`]: https://api.rubyonrails.org/classes/ActionController/Redirecting.html#method-i-redirect_to

#### `config.action_controller.log_query_tags_around_actions`

クエリタグのコントローラコンテキストが`around_filter`で更新されるかどうかを指定します。デフォルト値は`true`です。

#### `config.action_controller.wrap_parameters_by_default`

Rails 7.0より前は、新しいアプリケーションを生成するときに、JSONリクエスト用に`ActionController::Base`でパラメータのラッピングを有効にする`wrap_parameters.rb`という名前のイニシャライザが生成されていました。

この設定値を`true`にすると、そのイニシャライザがある場合と同じ振る舞いになるので、パラメータのラッピング動作をカスタマイズしない場合、アプリケーションのイニシャライザを削除できるようになります。

この値に関係なく、アプリケーションはイニシャライザで、またはコントローラごとに従来と同様にパラメータのラッピング動作をカスタマイズ可能です。パラメータのラッピングについて詳しくは、[`ParamsWrapper`][params_wrapper]を参照してください。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

[params_wrapper]: https://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html

#### `ActionController::Base.wrap_parameters`

[`ParamsWrapper`](https://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html)を設定します。これはトップレベルで呼び出すことも、コントローラで個別に呼び出すこともできます。

### Action Dispatchを設定する

#### `config.action_dispatch.cookies_serializer`

cookieで使うシリアライザを指定します。[`config.active_support.message_serializer`](#config-active-support-message-serializer)と同じ値を渡せますが、`:hybrid`は`:json_allow_marshal`のエイリアスです。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:marshal`           |
| 7.0以降                | `:json`              |

#### `config.action_dispatch.debug_exception_log_level`

リクエスト中にキャッチされない例外をログ出力する際に、[`ActionDispatch::DebugExceptions`]ミドルウェアで使うログレベルを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:fatal`             |
| 7.1以降                | `:error`             |

[`ActionDispatch::DebugExceptions`]: https://api.rubyonrails.org/classes/ActionDispatch/DebugExceptions.html

#### `config.action_dispatch.default_headers`

HTTPヘッダーで使われるハッシュです。このヘッダーはデフォルトですべてのレスポンスに設定されます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | <pre><code>{<br>  "X-Frame-Options" => "SAMEORIGIN",<br>  "X-XSS-Protection" => "1; mode=block",<br>  "X-Content-Type-Options" => "nosniff",<br>  "X-Download-Options" => "noopen",<br>  "X-Permitted-Cross-Domain-Policies" => "none",<br>  "Referrer-Policy" => "strict-origin-when-cross-origin"<br>}</code></pre> |
| 7.0                  | <pre><code>{<br>  "X-Frame-Options" => "SAMEORIGIN",<br>  "X-XSS-Protection" => "0",<br>  "X-Content-Type-Options" => "nosniff",<br>  "X-Download-Options" => "noopen",<br>  "X-Permitted-Cross-Domain-Policies" => "none",<br>  "Referrer-Policy" => "strict-origin-when-cross-origin"<br>}</code></pre> |
| 7.1以降               | <pre><code>{<br>  "X-Frame-Options" => "SAMEORIGIN",<br>  "X-XSS-Protection" => "0",<br>  "X-Content-Type-Options" => "nosniff",<br>  "X-Permitted-Cross-Domain-Policies" => "none",<br>  "Referrer-Policy" => "strict-origin-when-cross-origin"<br>}</code></pre> |

#### `config.action_dispatch.default_charset`

すべてのレンダリングで使うデフォルトの文字セットを指定します。デフォルト値は`nil`です。

#### `config.action_dispatch.tld_length`

アプリケーションで使うトップレベルドメイン（TLD）の長さを指定します。デフォルト値は`1`です。

#### `config.action_dispatch.ignore_accept_header`

リクエストのヘッダーを受け付けるかどうかを指定します。デフォルト値は`false`です。

#### `config.action_dispatch.x_sendfile_header`

サーバー固有の`X-Sendfile`ヘッダーを指定します。これは、サーバーからの送信を加速するのに有用です。たとえば、`X-Sendfile`をApache向けに設定できます。

#### `config.action_dispatch.http_auth_salt`

HTTP Authのsalt値（訳注: ハッシュの安全性を強化するために加えられる値）を設定します。デフォルト値は`'http authentication'`です。

#### `config.action_dispatch.signed_cookie_salt`

署名済みcookie用のsalt値を設定します。デフォルト値は`'signed cookie'`です。

#### `config.action_dispatch.encrypted_cookie_salt`

暗号化済みcookie用のsalt値を設定します。デフォルト値は`'encrypted cookie'`です。

#### `config.action_dispatch.encrypted_signed_cookie_salt`

署名暗号化済みcookie用のsalt値を設定します。デフォルト値は`'signed encrypted cookie'`です。

#### `config.action_dispatch.authenticated_encrypted_cookie_salt`

認証された暗号化済みcookieのsalt値を設定します。デフォルト値は`'authenticated encrypted cookie'`です。

#### `config.action_dispatch.encrypted_cookie_cipher`

暗号化済みcookieに使う暗号化方式を設定します。デフォルト値は`"aes-256-gcm"`です。

#### `config.action_dispatch.signed_cookie_digest`

署名済みcookieに使うダイジェスト方式を設定します。デフォルト値は`"SHA1"`です。

#### `config.action_dispatch.cookies_rotations`

署名暗号化済みcookieの秘密情報、暗号化方式、ダイジェスト方式のローテーションを行えるようにします。

#### `config.action_dispatch.use_authenticated_cookie_encryption`

署名暗号化済みcookieでAES-256-GCMまたは旧AES-256-CBC暗号を用いるかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.2以降                | `true`               |

#### `config.action_dispatch.use_cookies_with_metadata`

`purpose`メタデータを埋め込んだcookieの書き込みを有効にします。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 6.0以降                | `true`               |

#### `config.action_dispatch.perform_deep_munge`

パラメータに対して`deep_munge`メソッドを実行すべきかどうかを指定します。詳細については[セキュリティガイド](security.html#安全でないクエリ生成)を参照してください。デフォルト値は`true`です。

#### `config.action_dispatch.rescue_responses`

HTTPステータスに割り当てる例外を設定します。ここには、例外とステータスのペアを指定したハッシュを1つ指定可能です。

```ruby
# デフォルト値を尊重するために、#[]= または #merge! を使うのがよい
config.action_dispatch.rescue_responses["MyAuthenticationError"] = :unauthorized
```

この設定を観察するには`ActionDispatch::ExceptionWrapper.rescue_responses`を使います。デフォルトの定義は次のようになっています。

```ruby
{
  "ActionController::RoutingError" => :not_found,
  "AbstractController::ActionNotFound" => :not_found,
  "ActionController::MethodNotAllowed" => :method_not_allowed,
  "ActionController::UnknownHttpMethod" => :method_not_allowed,
  "ActionController::NotImplemented" => :not_implemented,
  "ActionController::UnknownFormat" => :not_acceptable,
  "ActionDispatch::Http::MimeNegotiation::InvalidType" => :not_acceptable,
  "ActionController::MissingExactTemplate" => :not_acceptable,
  "ActionController::InvalidAuthenticityToken" => :unprocessable_entity,
  "ActionController::InvalidCrossOriginRequest" => :unprocessable_entity,
  "ActionDispatch::Http::Parameters::ParseError" => :bad_request,
  "ActionController::BadRequest" => :bad_request,
  "ActionController::ParameterMissing" => :bad_request,
  "Rack::QueryParser::ParameterTypeError" => :bad_request,
  "Rack::QueryParser::InvalidParameterError" => :bad_request,
  "ActiveRecord::RecordNotFound" => :not_found,
  "ActiveRecord::StaleObjectError" => :conflict,
  "ActiveRecord::RecordInvalid" => :unprocessable_entity,
  "ActiveRecord::RecordNotSaved" => :unprocessable_entity
}
```

設定されていない例外はすべて500 Internal Server Errorに割り当てられます。

#### `config.action_dispatch.cookies_same_site_protection`

cookie設定時の`SameSite`属性のデフォルト値を設定します。`nil`に設定すると`SameSite`属性は追加されません。以下のように`proc`を渡すことでリクエストに応じて`SameSite`属性の値を動的に設定できます。

```ruby
config.action_dispatch.cookies_same_site_protection = ->(request) do
  :strict unless request.user_agent == "TestAgent"
end
```

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `nil`                |
| 6.1以降                | `lax`                |

#### `config.action_dispatch.ssl_default_redirect_status`

`ActionDispatch::SSL`ミドルウェア内で、GETリクエストとHEADリクエスト以外のリクエストをHTTPからHTTPSにリダイレクトするときに用いるデフォルトのHTTPステータスコードを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `307`                |
| 6.1以降                | `308`                |

#### `config.action_dispatch.log_rescued_responses`

`rescue_responses`で設定されている、処理されなかった例外のログ出力を有効にします。デフォルト値は`true`です。

#### `config.action_dispatch.show_exceptions`

`config.action_dispatch.show_exceptions`設定は、リクエストへの応答中にAction Pack（具体的には[`ActionDispatch::ShowExceptions`](/configuring.html#actiondispatch-showexceptions)ミドルウェア）が発生した例外を処理する方法を指定します。

値を`:all`に設定すると、例外をrescueして対応するエラーページを表示するようにAction Packを構成します。たとえば、Action Packは`ActiveRecord::RecordNotFound`例外をrescueし、`public/404.html`にあるコンテンツをステータスコード`404 Not found`でレンダリングします。

値を`:rescueable`に設定すると、[`config.action_dispatch.rescue_responses`](#config-action-dispatch-rescue-responses)リストで定義されている例外についてはrescueし、その他すべてはraiseするようAction Packを構成します。たとえば、Action Packは`ActiveRecord::RecordNotFound`をrescueしますが、`NoMethodError`をraiseします。

値を``:none`に設定すると、Action Packがすべての例外をraiseするように構成されます。

* `:all`: すべての例外をエラーページで表示する
* `:rescuable`: [`config.action_dispatch.rescue_responses`](#config-action-dispatch-rescue-responses)で宣言されている例外をエラーページで表示する
* `:none`: すべての例外をraiseする

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`                |
| 7.1以降                | `:all`                |

#### `config.action_dispatch.strict_freshness`

レスポンスに`Last-Modified`ヘッダーと`ETag`ヘッダーの両方が存在する場合に、`ActionDispatch::ETag`ミドルウェアが`ETag`ヘッダーを`Last-Modified`ヘッダーよりも優先するかどうかを設定します。

`true`に設定すると、両方のヘッダーが存在する場合、「[RFC 7232セクション6](https://datatracker.ietf.org/doc/html/rfc7232#section-6)」で指定されているように`ETag`のみが考慮されます。

`false`に設定すると、両方のヘッダーが存在する場合、両方のヘッダーがチェックされ、レスポンスが新しいと見なされるためには両方が一致する必要があります。

| バージョン              | デフォルト値           |
| --------------------- | --------------------- |
| （オリジナル）           | `false`               |
| 8.0以降                | `true`                |

#### `config.action_dispatch.always_write_cookie`

「cookieが安全でないとマーキングされている場合」や「リクエストがSSL経由で行われている場合」や「リクエストが[Onion Service](https://ja.wikipedia.org/wiki/Tor#%E3%83%A9%E3%83%B3%E3%83%87%E3%83%96%E3%83%BC%E3%83%9D%E3%82%A4%E3%83%B3%E3%83%88%E3%81%A8Onion_Service)に対して行われている場合」にも、リクエストの最後にcookieを書き込むかどうかを指定します。

`true`に設定すると、この条件が満たされない場合でもcookieを書き込みます。

デフォルト値は、`development`環境では`true`、その他の環境では`false`です。

#### `ActionDispatch::Callbacks.before`

リクエストより前に実行したいコードブロックを渡します。

#### `ActionDispatch::Callbacks.after`

リクエストの後に実行したいコードブロックを渡します。

### Action Viewを設定する

`config.action_view`にも若干の設定があります。

#### `config.action_view.cache_template_loading`

リクエストのたびにビューテンプレートを再読み込みするかどうか（キャッシュしないかどうか）を指定します。デフォルト値は`!config.enable_reloading`に従います。

#### `config.action_view.field_error_proc`

Active Modelで発生したエラーの表示に使うHTMLジェネレータを指定します。渡したブロックは、Action Viewテンプレートのコンテキスト内で評価されます。デフォルト値は以下のとおりです。

```ruby
Proc.new { |html_tag, instance| content_tag :div, html_tag, class: "field_with_errors" }
```

#### `config.action_view.default_form_builder`

Railsでデフォルトで使うフォームビルダーを指定します。デフォルト値は、`ActionView::Helpers::FormBuilder`です。フォームビルダーを初期化処理の後に読み込みたい場合（developmentモードではフォームビルダーがリクエストのたびに再読み込みされます）は、`String`として渡すこともできます。

#### `config.action_view.logger`

Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを渡せます。このロガーは、Action Viewからの情報をログ出力するために使われます。ログ出力を無効にするには`nil`を設定します。

#### `config.action_view.erb_trim_mode`

特定のERB構文をトリミングするかどうかを指定します。デフォルト値は`'-'`で、`<%= -%>`または`<%= =%>`の場合に末尾スペースを削除して改行します。それ以外の値に設定するとトリミングサポートがオフになります。

#### `config.action_view.frozen_string_literal`

ERBテンプレートを`# frozen_string_literal: true`マジックコメント付きでコンパイルすることで、すべての文字列リテラルをfrozenにしてアロケーションを削減します。`true`に設定するとすべてのビューで有効になります。

#### `config.action_view.embed_authenticity_token_in_remote_forms`

フォームで`remote: true`を使う場合の`authenticity_token`のデフォルトの動作を設定します。デフォルトでは`false`で、この場合リモートフォームには`authenticity_token`フォームが含まれません。これはフォームでフラグメントキャッシュを使っている場合に便利です。

リモートフォームは`meta`タグから認証を受け取るので、JavaScriptの動作しないブラウザをサポートしなければならない場合を除いて、トークンの埋め込みは不要です。JavaScriptが動かないブラウザのサポートが必要な場合は、`authenticity_token: true`をフォームオプションとして渡すか、この設定を`true`にします。

#### `config.action_view.prefix_partial_path_with_controller_namespace`

名前空間化されたコントローラでレンダリングされたテンプレートにあるサブディレクトリから、パーシャルを探索するかどうかを指定します。たとえば、`Admin::PostsController`というコントローラがあり、以下のテンプレートを出力するとします。

```erb
<%= render @article %>
```

デフォルト設定は`true`で、その場合`/admin/posts/_post.erb`にあるパーシャルを使います。この値を`false`にすると、`/posts/_post.erb`がレンダリングされます。この動作は、`PostsController`などの名前空間化されていないコントローラでレンダリングした場合と同じです。

#### `config.action_view.automatically_disable_submit_tag`

クリック時に`submit_tag`を自動的に無効にするかどうかを指定します。デフォルト値は`true`です。

#### `config.action_view.debug_missing_translation`

訳文の存在しないキーを`<span>`タグで囲むかどうかを指定します。デフォルト値は`true`です。

#### `config.action_view.form_with_generates_remote_forms`

`form_with`でリモートフォームを生成するかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| 5.1                   | `true`               |
| 6.1以降                | `false`              |

#### `config.action_view.form_with_generates_ids`

`form_with`のinputでidを生成するかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.2以降                | `true`               |

#### `config.action_view.default_enforce_utf8`

フォームを生成するときに、UTF-8でエンコードされたフォームを古いInternet Explorerで強制送信する隠しタグを付けるかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 6.0以降                | `false`              |

#### `config.action_view.image_loading`

`image_tag`ヘルパーでレンダリングされた`<img>`タグの`loading`属性のデフォルト値を指定します。

たとえば`"lazy"`を設定すると、`image_tag`ヘルパーでレンダリングされた`<img>`タグに`loading="lazy"`が含まれ、[画像がビューポートに近づくまで読み込みを遅延するようブラウザに指示します](https://html.spec.whatwg.org/#lazy-loading-attributes)（`image_tag`に`loading: "eager"`渡すなどの方法で、画像ごとに挙動を上書きできます）。デフォルト値は`nil`です。

#### `config.action_view.image_decoding`

`image_tag`ヘルパーでレンダリングされる`<img>`タグの`decoding`属性に使うデフォルト値を指定します。デフォルト値は`nil`です。

#### `config.action_view.annotate_rendered_view_with_filenames`

レンダリングされたビューにテンプレートファイル名を追加するかどうかを指定します。デフォルト値は`false`です。

#### `config.action_view.preload_links_header`

`javascript_include_tag`や`stylesheet_link_tag`で、アセットをプリロードする`link`ヘッダーを生成するかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `nil`                |
| 6.1以降                | `true`               |

#### `config.action_view.button_to_generates_button_tag`

`false`に設定すると、`button_to`がコンテンツの受け渡し方法に応じて`<form>`内に`<button>`要素または`<input>`要素のどちらかをレンダリングします（以下は簡潔にするために`<form>`を省略）。

```erb
<%= button_to "Content", "/" %>
# => <input type="submit" value="Content">

<%= button_to "/" do %>
  Content
<% end %>
# => <button type="submit">Content</button>
```

`true`に設定すると、`button_to`は上のどちらの場合も`<form>`内に`<button>`タグを生成します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

#### `config.action_view.apply_stylesheet_media_default`

`media`属性が提供されていない場合に、`stylesheet_link_tag`で`media`属性のデフォルト値を`screen`としてレンダリングするかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `true`               |
| 7.0以降                | `false`              |

#### `config.action_view.prepend_content_exfiltration_prevention`

`form_tag`ヘルパーと`button_to`ヘルパーが、HTMLをブラウザセーフにする（ただし技術的には無効な）HTMLタグをHTMLの冒頭で生成するかどうかを決定します。このHTMLタグは、先行する「閉じていないタグ」がそのHTMLタグの内容をキャプチャできないことを保証します。デフォルト値は`false`です。

#### `config.action_view.sanitizer_vendor`

Action Viewで利用されるHTMLサニタイザのセットを設定するには、`ActionView::Helpers::SanitizeHelper.sanitizer_vendor`を設定します。デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン   | デフォルト値                 | マークアップの解釈 |
|------------|----------------------------|------------------------|
|（オリジナル） | `Rails::HTML4::Sanitizer`  | HTML4            |
| 7.1以降     | `Rails::HTML5::Sanitizer`（以下の注を参照）| HTML5     |

NOTE: `Rails::HTML5::Sanitizer`はJRubyではサポートされないため、JRubyプラットフォームのRailsでは`Rails::HTML4::Sanitizer`にフォールバックします。

### Action Mailboxを設定する

`config.action_mailbox`には以下の設定オプションがあります。

#### `config.action_mailbox.logger`

Action Mailboxで用いるロガーを含みます。Log4rまたはデフォルトのRuby Loggerクラスに従うロガーを渡せます。デフォルト値は`Rails.logger`です。

```ruby
config.action_mailbox.logger = ActiveSupport::Logger.new(STDOUT)
```

#### `config.action_mailbox.incinerate_after`

`ActiveSupport::Duration`を受け取ります。これは`ActionMailbox::InboundEmail`レコードを処理後に自動的に破棄（destroy）するまでの期間を指定します。デフォルト値は`30.days`です。

```ruby
# 受信メールの処理後、14日後に「焼却」する
config.action_mailbox.incinerate_after = 14.days
```

#### `config.action_mailbox.queues.incineration`

焼却（incinerate）ジョブに用いるActive Jobキューを示すシンボルを渡せます。このオプションが`nil`の場合、焼却ジョブがデフォルトのActive Jobキューに送信されます（`config.active_job.default_queue_name`を参照）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:action_mailbox_incineration` |
| 6.1以降                | `nil`                |

#### `config.action_mailbox.queues.routing`

ルーティングジョブに用いるActive Jobキューを示すシンボルを渡せます。このオプションが`nil`の場合、ルーティングジョブがデフォルトのActive Jobキューに送信されます（`config.active_job.default_queue_name`を参照）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:action_mailbox_routing` |
| 6.1以降                | `nil`                |

#### `config.action_mailbox.storage_service`

メールのアップロードに使うActive Storageサービスを示すシンボルで指定します。このオプションが`nil`の場合、メールがデフォルトのActive Storageサービスにアップロードされます（`config.active_storage.service`を参照）。

### Action Mailerを設定する

`config.action_mailer`には多数の設定オプションがあります。

#### `config.action_mailer.asset_host`

メーラーで用いるアセットのホストを指定します。アプリケーションサーバーではなくCDNにアセットをホスティングする場合に便利です。この設定はAction Controllerで異なるアセットホストを設定する場合にのみ使います。それ以外の場合は`config.asset_host`をお使いください。

#### `config.action_mailer.logger`

Log4rのインターフェイスまたはデフォルトのRuby Loggerクラスに従うロガーを引数として取ります。このロガーは、Action Mailerからの情報をログ出力するために使われます。ログ出力を無効にするには`nil`を設定します。

#### `config.action_mailer.smtp_settings`

`:smtp`配信方法を詳細に設定するのに使えます。引数に渡すオプションハッシュには、以下のオプションを含められます。

* `:address`: リモートのメールサーバーを指定します。デフォルトの"localhost"設定から変更します。
* `:port`: 使うメールサーバーのポートが25番でない場合は（めったにないと思いますが）、ここで対応できます。
* `:domain`: HELOドメインの指定が必要な場合に使います。
* `:user_name`: メールサーバーで認証が要求される場合は、ここでユーザー名を設定します。
* `:password`: メールサーバーで認証が要求される場合は、ここでパスワードを設定します。
* `:authentication`: メールサーバーで認証が要求される場合は、ここで認証の種類を指定します。`:plain`、`:login`、`:cram_md5`のいずれかのシンボルを指定できます。
* `:enable_starttls`: SMTPサーバーにSTARTTLSで接続します（サポートされていない場合は失敗します）。デフォルト値は`false`です。
* `:enable_starttls_auto`: 利用するSMTPサーバーでSTARTTLSが有効かどうかを検出し、可能な場合は使います。デフォルト値は`true`です。
* `:openssl_verify_mode`: TLSを使う場合、OpenSSLの認証方法を設定できます。これは、自己署名証明書やワイルドカード証明書が必要な場合に便利です。OpenSSLの検証定数である`:none`や`:peer`を指定することも、`OpenSSL::SSL::VERIFY_NONE`定数や`OpenSSL::SSL::VERIFY_PEER`定数を直接指定することもできます。
* `:ssl/:tls`: SMTP接続でSMTP/TLS（SMTPS: SMTP over direct TLS connection）を有効にします。
* `:open_timeout`: コネクション開始の試行中の待ち時間を秒で指定します。
* `:read_timeout`: read(2)呼び出しのタイムアウトを秒で指定します。

また、[`Mail::SMTP`をサポートする任意の設定オプション](https://github.com/mikel/mail/blob/master/lib/mail/network/delivery_methods/smtp.rb)も渡せます。

#### `config.action_mailer.smtp_timeout`

バージョン2.8.0より前の`mail` gemは、SMTPリクエストにデフォルトのタイムアウトを設定していませんでした。この設定を使うことで、アプリケーションで`mail` gemの`:open_timeout`と`:read_timeout`の両方についてデフォルト値を設定してリクエストが無期限に停止しないようにできます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `nil`                |
| 7.0以降                | `5`                  |

#### `config.action_mailer.sendmail_settings`

`:sendmail`の詳細な配信方法を設定できます。引数に渡すオプションハッシュには、以下のオプションを含められます。

* `:location` - sendmail実行ファイルの場所。デフォルト値は`/usr/sbin/sendmail`です。
* `:arguments` - コマンドラインに与える引数。デフォルト値は`%w[ -i ]`です。

#### `config.action_mailer.file_settings`

`:file`配信方法を設定します。以下を含むオプションハッシュを渡せます。

* `:location`: ファイルの保存場所（デフォルトは`"#{Rails.root}/tmp/mails"`）。
* `:extension`: ファイル拡張子（デフォルトは空文字列）。

#### `config.action_mailer.raise_delivery_errors`

メール配信が完了しなかった場合にエラーを発生させるかどうかを指定します。デフォルト値は`true`です。

#### `config.action_mailer.delivery_method`

メール配信方法を指定します。デフォルト値は`:smtp`です。詳しくは[Action Mailerガイド](action_mailer_basics.html#action-mailerを設定する)を参照してください。

#### `config.action_mailer.perform_deliveries`

メールを実際に配信するかどうかを指定します。デフォルト値は`true`です。テスト時にメール送信を抑制するのに便利です。

#### `config.action_mailer.default_options`

Action Mailerのデフォルトを設定します。これは、メーラーごとに`from`や`reply_to`などを設定します。デフォルト値は以下のとおりです。

```ruby
{
  mime_version:  "1.0",
  charset:       "UTF-8",
  content_type: "text/plain",
  parts_order:  ["text/plain", "text/enriched", "text/html"]
}
```

ハッシュを1つ指定してオプションを追加することもできます。

```ruby
config.action_mailer.default_options = {
  from: "noreply@example.com"
}
```

#### `config.action_mailer.observers`

メールを配信したときに通知を受けるオブザーバーを登録します。

```ruby
config.action_mailer.observers = ["MailObserver"]
```

#### `config.action_mailer.interceptors`

メールを送信する前に呼び出すインターセプタを登録します。

```ruby
config.action_mailer.interceptors = ["MailInterceptor"]
```

#### `config.action_mailer.preview_interceptors`

メールのプレビュー前に呼び出すインターセプタを登録します。

```ruby
config.action_mailer.preview_interceptors = ["MyPreviewMailInterceptor"]
```

#### `config.action_mailer.preview_paths`

メーラープレビューの置き場所を指定します。この設定オプションにパスを追加すると、メーラープレビューの探索でそのパスが使われるようになります。

```ruby
config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"
```

#### `config.action_mailer.show_previews`

メーラーのプレビューを有効または無効にします。デフォルトではdevelopment環境で`true`です。

```ruby
config.action_mailer.show_previews = false
```

#### `config.action_mailer.perform_caching`

メーラーテンプレートがフラグメントキャッシングを行うかどうかを指定します。無指定の場合、デフォルトは`true`となります。

#### `config.action_mailer.deliver_later_queue_name`

デフォルトの配信ジョブ（`config.action_mailer.delivery_job`を参照）で用いるActive Jobキューを指定します。

このオプションを`nil`に設定すると、配送ジョブはデフォルトのActive Jobキュー （[`config.active_job.default_queue_name`][]を参照）に送信されます。

メーラークラスはこれをオーバーライドすることで別のキューを利用できます。これはデフォルトの配信ジョブを使う場合にのみ適用されることに注意してください。メーラーがカスタムジョブを使っている場合、そのキューが使われます。

Active Jobアダプタも指定されたキューを処理するように設定されていることを確認してください。そうでない場合、配信ジョブが何も知らせずに無視する可能性があります。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:mailers`           |
| 6.1以降                | `nil`                |

#### `config.action_mailer.delivery_job`

メールの配信ジョブを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `ActionMailer::MailDeliveryJob` |
| 6.0以降                | `"ActionMailer::MailDeliveryJob"` |

### Active Supportを設定する

Active Supportにもいくつかの設定オプションがあります。

#### `config.active_support.bare`

Rails起動時に`active_support/all`の読み込みを行なうかどうかを指定します。デフォルト値は`nil`であり、この場合`active_support/all`が読み込まれます。

#### `config.active_support.test_order`

テストケースの実行順序を指定します。`:random`か`:sorted`を指定可能で、デフォルト値は`:random`です。

#### `config.active_support.escape_html_entities_in_json`

JSONシリアライズに含まれるHTMLエンティティをエスケープするかどうかを指定します。デフォルト値は`true`です。

#### `config.active_support.use_standard_json_time_format`

日付のシリアライズをISO 8601フォーマットで行うかどうかを指定します。デフォルト値は`true`です。

#### `config.active_support.time_precision`

JSONエンコードされた時間値の精度を指定します。デフォルト値は`3`桁です。

#### `config.active_support.hash_digest_class`

重要でないダイジェスト（ETagヘッダーなど）の生成に用いるダイジェスト用クラスを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `OpenSSL::Digest::MD5` |
| 5.2                   | `OpenSSL::Digest::SHA1` |
| 7.0以降                | `OpenSSL::Digest::SHA256` |

#### `config.active_support.key_generator_hash_digest_class`

暗号化済みcookieなどで設定済みのsecretベースを元にして、secretを導出するのに用いるダイジェスト用クラスを設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `OpenSSL::Digest::SHA1` |
| 7.0以降                | `OpenSSL::Digest::SHA256` |

#### `config.active_support.use_authenticated_message_encryption`

AES-256-CBCの代わりに、AES-256-GCM認証済み暗号をメッセージ暗号化のデフォルト暗号化方式として用いるかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.2以降                | `true`               |

#### `config.active_support.message_serializer`

[`ActiveSupport::MessageEncryptor`][]および[`ActiveSupport::MessageVerifier`][]インスタンスで利用するデフォルトのシリアライザを指定します。シリアライザ間の移行を容易にするため、提供されるシリアライザには複数のデシリアライズ形式をサポートするフォールバックメカニズムが組み込まれています。

|シリアライザ| シリアライズとデシリアライズ | デシリアライズのフォールバック|
| ---------- | ------------------------- | -------------------- |
| `:marshal` | `Marshal` | `ActiveSupport::JSON`、`ActiveSupport::MessagePack` |
| `:json` | `ActiveSupport::JSON` | `ActiveSupport::MessagePack` |
| `:json_allow_marshal` | `ActiveSupport::JSON` | `ActiveSupport::MessagePack`、`Marshal` |
| `:message_pack` | `ActiveSupport::MessagePack` | `ActiveSupport::JSON` |
| `:message_pack_allow_marshal` | `ActiveSupport::MessagePack` | `ActiveSupport::JSON`、`Marshal` |

WARNING: `Marshal`は、メッセージ署名のsecret（秘密情報）が漏洩した場合にデシリアライズ攻撃のベクタになる可能性があります。**可能であれば、`Marshal`をサポートしていないシリアライザを選択すること。**

INFO: `:message_pack`および`:message_pack_allow_marshal`シリアライザは、JSONではサポートされていない`Symbol`などの一部のRubyの型を双方向変換できます。また、パフォーマンスの向上やペイロードサイズの縮小も提供します。ただし、[`msgpack` gem](https://rubygems.org/gems/msgpack)が必要です。

上記のシリアライザーは、代替のデシリアライズ形式にフォールバックする際に[`message_serializer_fallback.active_support`][]というイベント通知を出力します。これにより、そのようなフォールバックがどれくらい頻繁に発生しているかをトラッキングできます。

または、`dump`メソッドと`load`メソッドに応答するシリアライザオブジェクトを以下のように指定することも可能です。

```ruby
config.active_support.message_serializer = YAML
```

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:marshal`           |
| 7.1以降                | `:json_allow_marshal`|

[`ActiveSupport::MessageEncryptor`]: https://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html
[`ActiveSupport::MessageVerifier`]: https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifier.html
[`message_serializer_fallback.active_support`]: active_support_instrumentation.html#message-serializer-fallback-active-support

#### `config.active_support.use_message_serializer_for_metadata`

`true`に設定すると、メッセージデータとメタデータを一緒にシリアライズするときのパフォーマンスの最適化を有効にします。これによりメッセージのフォーマットが変更されるため、この方法でシリアライズされたモデルは古いバージョンのRails（< 7.1）では読み込めなくなります。
ただし、この最適化が有効かどうかにかかわらず、古い形式を使っているメッセージも引き続き読み込めます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1以降                | `true`               |

#### `config.active_support.cache_format_version`

キャッシュで使うシリアライズ形式を指定します。利用可能な値は`7.0`、`7.1`です。

`7.1`にすると、キャッシュエントリのシリアライズの効率が向上します。

`7.1`では、効率が向上するとともに、キャッシュエントリの値をデシリアライズせずにキャッシュエントリの期限切れやバージョンミスマッチを検出可能になります。また、ビューフラグメントなどのベアストリング値も最適化されます。

どの形式も前方互換性と後方互換性があります。つまり、ある形式で書かれたキャッシュエントリは別の形式で読み取り可能です。この振る舞いによって、キャッシュ全体を無効化せずに異なる形式間の移行を楽に行えるようになります。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| 7.0                   | `7.0`                |
| 7.1以降                | `7.1`                |

#### `config.active_support.deprecation`

非推奨警告メッセージの振る舞いを設定します。指定可能なオプションについては[`Deprecation::Behavior`][deprecation_behavior]を参照してください。

デフォルトで生成される`config/environments`以下のファイルでは、development環境では`:log`が、test環境では`:stderr`がそれぞれ設定されます。production環境ではこの設定は無視され、[`config.active_support.report_deprecations`] (#config-active-support-report-deprecations)の設定が使われます。

[deprecation_behavior]: https://api.rubyonrails.org/classes/ActiveSupport/Deprecation/Behavior.html#method-i-behavior-3D

#### `config.active_support.disallowed_deprecation`

利用が許されない非推奨警告メッセージの振る舞いを設定します。指定可能なオプションについては[`Deprecation::Behavior`][deprecation_behavior]を参照してください。

このオプションは、development環境とtest環境での利用を想定しています。production環境では[`config.active_support.report_deprecations`] (#config-active-support-report-deprecations)をお使いください。

#### `config.active_support.disallowed_deprecation_warnings`

アプリケーションで利用を許可しない項目として扱う非推奨警告メッセージを設定します。これを用いて、たとえば特定の非推奨項目を重大な失敗として扱えるようになります。

#### `config.active_support.report_deprecations`

`false`に設定すると、アプリケーションの[`deprecators`](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-deprecators)からのすべての非推奨警告メッセージ（利用が許されない非推奨項目も含めて）を停止できます。停止の対象には、Railsや他のgemのdeprecatorをdeprecatorのコレクションに追加可能なすべての非推奨警告が含まれますが、`ActiveSupport::Deprecation`から発せられる非推奨警告については停止できないものもあります。

デフォルトで生成される`config/environments`以下のファイルのうち、production環境では`false`に設定されます。

#### `config.active_support.isolation_level`

Rails内部ステートのほとんどの局所性（locality）を設定します。Fiberベースのサーバーやジョブプロセッサ（`falcon`など）を使う場合は、`:fiber`を設定してください。
それ以外の場合は局所性を`:thread`にするのが最適です。デフォルトは`:thread`です。

#### `config.active_support.executor_around_test_case`

テストケースをラップする`Rails.application.executor.wrap`を呼び出すように設定します。これにより、テストケースの振る舞いが実際のリクエストやジョブに近づきます。Active Recordクエリキャッシュや非同期クエリのような、通常のテストで無効にされる多くの機能が有効になります。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

#### `config.active_support.to_time_preserves_timezone`

`to_time`メソッドが受信者のUTCオフセットを保持するか、タイムゾーンを保持するかを指定します。

`:zone`に設定すると、`to_time`メソッドは受信者のタイムゾーンを利用します。
`:offset`に設定すると、`to_time`メソッドはUTCオフセットを利用します。
`false`の場合、`to_time`メソッドは代わりにローカルシステムのUTCオフセットに変換します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.0                   | `:offset`            |
| 8.0                   | `:zone`              |

#### `ActiveSupport::Logger.silencer`

`false`に設定すると、ブロック内でのログ出力を抑制する機能がオフになります。デフォルト値は`true`です。

#### `ActiveSupport::Cache::Store.logger`

キャッシュストア操作で使うロガーを指定します。

#### `ActiveSupport.to_time_preserves_timezone`

`to_time`メソッドでレシーバのUTCオフセットを保持するかどうかを指定します。`false`の場合、`to_time`メソッドはローカルシステムのUTCオフセットに変換されます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 5.0以降                | `true`               |

#### `ActiveSupport.utc_to_local_returns_utc_offset_times`

`ActiveSupport::TimeZone.utc_to_local`で、そのオフセットを考慮したUTC時間ではなく、UTCオフセット付きのローカル時間を返すように設定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 6.1以降                | `true`               |

#### `config.active_support.raise_on_invalid_cache_expiration_time`

`Rails.cache`の`fetch`または`write`に無効な`expires_at`または`expires_in`時刻を指定した場合に、`ArgumentError`を発生させるかどうかを指定します。

オプションは`true`と`false`です。
`false`の場合、例外は`handled`として報告され、代わりにログに出力されます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.1以降                | `true`               |

### Active Jobを設定する

`config.active_job`では以下の設定オプションが利用できます。

#### `config.active_job.queue_adapter`

キューのバックエンドに用いるアダプタを設定します。デフォルトのアダプタは`:async`です。最新の組み込みアダプタについてはAPIドキュメント[`ActiveJob::QueueAdapters`](https://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html)を参照してください。

```ruby
# 必ずGemfileにアダプタのgemを追加し、
# アダプタ固有のインストール/デプロイ方法に従うこと
config.active_job.queue_adapter = :sidekiq
```

#### `config.active_job.default_queue_name`

デフォルトのキュー名を変更できます。デフォルト値は`"default"`です。

```ruby
config.active_job.default_queue_name = :medium_priority
```

[`config.active_job.default_queue_name`]: #config-active-job-default-queue-name

#### `config.active_job.queue_name_prefix`

すべてのジョブ名の前に付けられるプレフィックスを設定します（スペースは含めません）。デフォルト値は空欄なので何も追加されません。

以下の設定では、production実行時に指定のジョブが`production_high_priority`キューに送信されます。

```ruby
config.active_job.queue_name_prefix = Rails.env
```

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :high_priority
  #....
end
```

#### `config.active_job.queue_name_delimiter`

デフォルト値は`'_'`です。`queue_name_prefix`が設定されている場合は、プレフィックスされていないキュー名とプレフィックスの結合に`queue_name_delimiter`が使われます。

以下の設定では、指定のジョブが`video_server.low_priority`キューに送信されます。

```ruby
# この区切り文字を使うにはprefixを設定しなければならない
config.active_job.queue_name_prefix = "video_server"
config.active_job.queue_name_delimiter = "."
```

```ruby
class EncoderJob < ActiveJob::Base
  queue_as :low_priority
  #....
end
```

#### `config.active_job.logger`

Active Jobのログ情報に使うロガーとして、Log4rのインターフェイスに準拠したロガーか、デフォルトのRubyロガーを指定できます。このロガーは、Active JobのクラスかActive Jobのインスタンスで`logger`を呼び出すことで取り出せます。ログ出力を無効にするには`nil`を設定します。

#### `config.active_job.custom_serializers`

カスタムの引数シリアライザを設定できます。デフォルト値は`[]`です。

#### `config.active_job.log_arguments`

ジョブの引数をログに出力するかどうかを指定します。デフォルト値は`true`です。

#### `config.active_job.verbose_enqueue_logs`

バックグラウンドジョブをエンキューするメソッドのソースコードの場所を、関連するエンキューログ行の下にログ出力するかどうかを指定します。
デフォルトは、development環境では`true`、それ以外の環境では`false`です。

#### `config.active_job.retry_jitter`

失敗したジョブをリトライするときに算出する遅延時間に加えるジッター（jitter: ランダムな微変動値）の総量を指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `0.0`                |
| 6.1以降                | `0.15`               |

#### `config.active_job.log_query_tags_around_perform`

クエリタグのジョブコンテキストが`around_perform`で自動的に更新されるようにするかどうかを指定します。デフォルト値は`true`です。

### Action Cableを設定する

#### `config.action_cable.url`

Action CableサーバーがホストされているURLを文字列で指定します。Action Cableサーバーがメインのアプリケーションと別になっている場合に使う可能性があります。

#### `config.action_cable.mount_path`

Action Cableをメインサーバープロセスの一部としてマウントする場所を文字列で指定します。デフォルト値は`/cable`です。`nil`を設定すると、Action Cableは通常のRailsサーバーの一部としてマウントされなくなります。

設定オプションについて詳しくは、[Action Cableの概要](action_cable_overview.html#設定)を参照してください。

#### `config.action_cable.precompile_assets`

Action Cableのアセットをアセットパイプラインのプリコンパイルに追加するかどうかを指定します。Sprocketsを使っていない場合、この設定は影響しません。デフォルト値は`true`です。

#### `config.action_cable.allow_same_origin_as_host`

Action Cableサーバー自身に一致するオリジンを許可するかどうかを決定します。
デフォルト値は`true`です。

`false`に設定すると、同一オリジンリクエストの自動アクセスが無効になり、設定済みオリジンのみが厳格に許可されます。

#### `config.action_cable.allowed_request_origins`

Action Cableサーバーが受け入れるリクエストの送信元を決定します。
`development`環境でのデフォルト値は、`/https?:\/\/localhost:\d+/`です。

### Active Storageを設定する

`config.active_storage`では以下の設定オプションが提供されています。

#### `config.active_storage.variant_processor`

`:mini_magick`または`:vips`いずれかのシンボルを渡せます。これらはvariantの変換やblob解析にMiniMagickとruby-vipsのどちらを使うかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `:mini_magick`        |
| 7.0以降                | `:vips`               |

#### `config.active_storage.analyzers`

Active Storageのblob（binary large object）で利用できるアナライザを指定するクラスの配列を受け取ります。デフォルトでは以下のように定義されます。

```ruby
config.active_storage.analyzers = [ActiveStorage::Analyzer::ImageAnalyzer::Vips, ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick, ActiveStorage::Analyzer::VideoAnalyzer, ActiveStorage::Analyzer::AudioAnalyzer]
```

画像アナライザは、画像blobの幅（width）や高さ（height）を取り出せます。

動画アナライザは、動画blobの幅（width）、高さ（height）、再生時間（duration）、角度（angle）、縦横比（aspect ratio、アスペクト比）、動画/音声チャンネルの有無を取り出せます。

音声アナライザは、音声blobの再生時間やビットレートを取り出せます。

#### `config.active_storage.previewers`

Active Storageのblobで利用できる画像プレビューアを指定するクラスを配列で受け取ります。デフォルトでは以下のように定義されます。

```ruby
config.active_storage.previewers = [ActiveStorage::Previewer::PopplerPDFPreviewer, ActiveStorage::Previewer::MuPDFPreviewer, ActiveStorage::Previewer::VideoPreviewer]
```

`PopplerPDFPreviewer`と`MuPDFPreviewer`はPDF blobの最初のページのサムネイルを生成できます。

`VideoPreviewer`は動画blobのフレームの中から動画の内容を代表するフレームを生成できます。

#### `config.active_storage.paths`

プレビューアやアナライザのコマンドがあるディレクトリを示すオプションをハッシュで受け取ります。デフォルトの`{}`の場合、コマンドをデフォルトパスで探索します。オプションには以下を含められます。

* `:ffprobe`: ffprobe実行ファイルの場所
* `:mutool`: mutool実行ファイルの場所
* `:ffmpeg`: ffmpeg実行ファイルの場所

```ruby
config.active_storage.paths[:ffprobe] = "/usr/local/bin/ffprobe"
```

#### `config.active_storage.variable_content_types`

Active Storageがvariantプロセッサで変換可能なContent-Typeを示す文字列を配列で受け取ります。デフォルトでは以下のように定義されます。

```ruby
config.active_storage.variable_content_types = %w(image/png image/gif image/jpeg image/tiff image/bmp image/vnd.adobe.photoshop image/vnd.microsoft.icon image/webp image/avif image/heic image/heif)
```

#### `config.active_storage.web_image_content_types`

variantをフォールバック用のPNGフォーマットに変換せずに処理可能なWeb画像Content-Typeを示す文字列を配列で受け取ります。

たとえば、アプリケーションのバリアント処理に`AVIF`を使いたい場合は、この配列に`image/avif`を追加できます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `%w(image/png image/jpeg image/gif)`            |
| 7.0以降                | `%w(image/png image/jpeg image/gif image/webp)` |

#### `config.active_storage.content_types_to_serve_as_binary`

Active Storageが常に添付ファイルとして扱うContent-Typeを示す文字列を配列で受け取ります。デフォルトでは以下のように定義されます。

```ruby
config.active_storage.content_types_to_serve_as_binary = %w(text/html image/svg+xml application/postscript application/x-shockwave-flash text/xml application/xml application/xhtml+xml application/mathml+xml text/cache-manifest)
```

#### `config.active_storage.content_types_allowed_inline`

Active Storageでインライン配信を許可するContent-Typeを示す文字列を配列で受け取ります。デフォルトでは以下のように定義されます。

```ruby
config.active_storage.content_types_allowed_inline = %w(image/webp image/avif image/png image/gif image/jpeg image/tiff image/vnd.adobe.photoshop image/vnd.microsoft.icon application/pdf)
```

#### `config.active_storage.queues.analysis`

解析ジョブに用いるActive Jobキューをシンボルで指定します。このオプションが`nil`の場合、解析ジョブはデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| 6.0                   | `:active_storage_analysis` |
| 6.1以降                | `nil`                |

#### `config.active_storage.queues.mirror`

ダイレクトアップロードのミラーリングジョブに用いるActive Jobキューをシンボルで指定します。このオプションが`nil`の場合、ミラーリングジョブはデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。デフォルト値は`nil`です。

#### `config.active_storage.queues.preview_image`

画像プレビューの前処理に用いるActive Jobキューをシンボルで指定します。このオプションが`nil`の場合、ジョブはデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。デフォルト値は`nil`です。

#### `config.active_storage.queues.purge`

purgeジョブに用いるActive Jobキューをシンボルで指定します。このオプションが`nil`の場合、purgeジョブはデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| 6.0                   | `:active_storage_purge` |
| 6.1以降                | `nil`                |

#### `config.active_storage.queues.transform`

バリアントの前処理に用いるActive Jobキューをシンボルで指定します。このオプションが`nil`の場合、ジョブはデフォルトのActive Jobキューに送信されます（[`config.active_job.default_queue_name`][]を参照）。デフォルト値は`nil`です。

#### `config.active_storage.logger`

Active Storageで用いられるロガーを設定できます。Log4rのインターフェイスに沿ったロガーや、デフォルトのRuby `Logger`クラスを指定できます。

```ruby
config.active_storage.logger = ActiveSupport::Logger.new(STDOUT)
```

#### `config.active_storage.service_urls_expire_in`

以下によって生成されるURLのデフォルトの有効期限を指定します。

* [`ActiveStorage::Blob#url`][]
* [`ActiveStorage::Blob#service_url_for_direct_upload`][]
* [`ActiveStorage::Preview#url`][]
* [`ActiveStorage::Variant#url`][]

デフォルト値は5分間です。

[`ActiveStorage::Blob#url`]: https://api.rubyonrails.org/classes/ActiveStorage/Blob.html#method-i-url
[`ActiveStorage::Blob#service_url_for_direct_upload`]: https://api.rubyonrails.org/classes/ActiveStorage/Blob.html#method-i-service_url_for_direct_upload
[`ActiveStorage::Preview#url`]: https://api.rubyonrails.org/classes/ActiveStorage/Preview.html#method-i-url
[`ActiveStorage::Variant#url`]: https://api.rubyonrails.org/classes/ActiveStorage/Variant.html#method-i-url

#### `config.active_storage.urls_expire_in`

Active Storageで生成される、Railsアプリケーション内URLのデフォルトの有効期限を指定します。デフォルト値は`nil`です。

#### `config.active_storage.touch_attachment_records`

対応するレコードを更新時に`touch`するように`ActiveStorage::Attachments`に指示します。デフォルトは`true`です。

#### `config.active_storage.routes_prefix`

Active Storageが提供するルーティングのプレフィックスを設定できます。生成されるルーティングの冒頭に追加する文字列を渡せます。

```ruby
config.active_storage.routes_prefix = "/files"
```

デフォルト値は`/rails/active_storage`です。

#### `config.active_storage.track_variants`

variantをデータベースに記録するかどうかを指定します。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 6.1以降                | `true`               |

#### `config.active_storage.draw_routes`

Active Storageのルーティング生成をオンオフできます。デフォルト値は`true`です。

#### `config.active_storage.replace_on_assign_to_many`

（準備中）

#### `config.active_storage.resolve_model_to_route`

Active Storageのファイル配信方法をグローバルに変更できます。

利用可能な値は以下です。

* `:rails_storage_redirect`: 署名済みの短命なサービスURLにリダイレクトする
* `:rails_storage_proxy`: プロキシファイルでダウンロードする

デフォルト値は`:rails_storage_redirect`です。

#### `config.active_storage.video_preview_arguments`

ffmpegの動画プレビュー画像生成方法を変更できます。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `"-y -vframes 1 -f image2"` |
| 7.0以降                | `"-vf 'select=eq(n\\,0)+eq(key\\,1)+gt(scene\\,0.015)"`<sup><mark><strong><em>1</em></strong></mark></sup> <br> `+ ",loop=loop=-1:size=2,trim=start_frame=1'"`<sup><mark><strong><em>2</em></strong></mark></sup><br> `+ " -frames:v 1 -f image2"` <br><br> <ol><li>冒頭の動画フレームとキーフレーム、閾値に合う場面変更のフレームを選択する。</li> <li>他のフレームが条件を満たさない場合は、選択した冒頭の動画フレームにフォールバックして動画をループするか、選択した2つの動画フレームにフォールバックして動画をループする（冒頭のループフレームは使わない）。</li></ol> |

#### `config.active_storage.multiple_file_field_include_hidden`

Rails 7.1以降、Active Storageの`has_many_attached`リレーションシップは、デフォルトで現在のコレクションに**追加されるのではなく**、デフォルトで現在のコレクションを**置き換える**ようになる予定です。

「**空の**」コレクションの送信をサポートするために、この`multiple_file_field_include_hidden`が`true`の場合は[`file_field`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-file_field)ヘルパーが補助的な隠しフィールドをレンダリングするようになります。これは、[`checkbox`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-checkbox)ヘルパーで補助フィールドをレンダリングするのと似ています。

デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

#### `config.active_storage.precompile_assets`

アセットパイプラインのプリコンパイルにActive Storageアセットを追加するかどうかを指定します。Sprocketsを使っていない場合は、この設定は影響しません。デフォルト値は`true`です。

### Action Textを設定する

#### `config.action_text.attachment_tag_name`

添付ファイルをラップするHTMLタグを文字列で指定します。デフォルト値は`"action-text-attachment"`です。

#### `config.action_text.sanitizer_vendor`

Action Textで利用するHTMLサニタイザを設定します。`ActionText::ContentHelper.sanitizer`には、ベンダーの`.safe_list_sanitizer`メソッドから返されるクラスのインスタンスが設定されます。デフォルト値は、`config.load_defaults`のターゲットバージョンによって異なります。

| バージョン              | デフォルト値           |
| --------------------- | -------------------- |
| （オリジナル）           | `false`              |
| 7.0以降                | `true`               |

| バージョン | デフォルト値 | マークアップ解析ライブラリ |
|-----------------------|--------------------------------------|------------------------|
| （オリジナル）          | `Rails::HTML4::Sanitizer`            | HTML4                  |
| 7.1                   | `Rails::HTML5::Sanitizer`（以下の注を参照）| HTML5                  |

NOTE: `Rails::HTML5::Sanitizer`はJRubyではサポートされていないため、JRubyプラットフォームのRailsは`Rails::HTML4::Sanitizer`にフォールバックします。

#### `Regexp.timeout`

詳しくはRubyドキュメントの[`Regexp.timeout=`](https://docs.ruby-lang.org/en/3.3/Regexp.html#method-c-timeout-3D)を参照してください。

See Ruby's documentation for [`Regexp.timeout=`](https://docs.ruby-lang.org/en/3.3/Regexp.html#method-c-timeout-3D).

### データベースを設定する

ほぼすべてのRailsアプリケーションは、何らかの形でデータベースにアクセスします。データベースへの接続は、環境変数`ENV['DATABASE_URL']`を設定するか、`config/database.yml`というファイルを設定することで行えます。

`config/database.yml`ファイルを使うことで、データベース接続に必要なすべての情報を指定できます。

```yaml
development:
  adapter: postgresql
  database: blog_development
  pool: 5
```

上の設定は、`postgresql`を用いて`blog_development`という名前のデータベースに接続します。同じ接続情報をURL化して、以下のように環境変数に保存することも可能です。

```ruby
ENV["DATABASE_URL"] # => "postgresql://localhost/blog_development?pool=5"
```

`config/database.yml`ファイルには、Railsがデフォルトで実行できる以下の3つの異なる環境を記述するセクションが含まれています。

* `development`環境: ローカルの開発環境でアプリケーションと手動でやりとりを行うために使われます。
* `test`環境: 自動化されたテストを実行するために使われます。
* `production`環境: アプリケーションを世界中に公開する本番環境で使われます。

必要であれば、`config/database.yml`の内部でURLを直接指定することも可能です。

```yaml
development:
  url: postgresql://localhost/blog_development?pool=5
```

`config/database.yml`ファイルにはERBタグ`<%= %>`も含められます。タグ内に記載されたものはすべてRubyのコードとして評価されます。このタグを用いて、環境変数から接続情報を取り出したり、接続情報の生成に必要な計算を行なうことも可能です。

`config/database.yml`ファイルで`ENV['DATABASE_URL']`または`url`キーを使うと、RailsはURL内のプロトコルを、アプリケーション内から設定可能なデータベースアダプタにマッピングできます。これにより、デプロイ先の環境で設定されるURLを変更せずにアダプタを設定可能になります。詳しくは[`config.active_record.protocol_adapters`](#config-active-record-protocol-adapters)を参照してください。

TIP: データベースの接続設定を手動で更新する必要はありません。アプリケーションのジェネレータのオプションを表示してみると、`--database`というオプションがあるのがわかります。このオプションでは、リレーショナルデータベースで最もよく使われるアダプタをリストから選択できます。さらに、`cd .. && rails new blog --database=mysql`のようにジェネレータを繰り返し実行することも可能です。`config/database.yml`ファイルが上書きされたことを確認すれば、アプリケーションの設定はSQLite用からMySQL用に変更されます。よく使われるデータベース接続方法の詳しい例については後述します。

### 接続設定

データベース接続の設定方法は、`config/database.yml`による方法と環境変数による方法の2とおりがあります。この2つがどのように相互作用するかを理解しておくことが重要です。

`config/database.yml`ファイルの内容が空で、かつ環境変数`ENV['DATABASE_URL']`が設定されている場合、データベースへの接続には環境変数が使われます。

```bash
$ cat config/database.yml

$ echo $DATABASE_URL
postgresql://localhost/my_database
```

`config/database.yml`ファイルがあり、環境変数`ENV['DATABASE_URL']`が設定されていない場合は、`config/database.yml`ファイルがデータベース接続に使われます。

```bash
$ cat config/database.yml
development:
  adapter: postgresql
  database: my_database
  host: localhost

$ echo $DATABASE_URL
```

`config/database.yml`ファイルと環境変数`ENV['DATABASE_URL']`が両方存在する場合、両者の設定はマージして使われます。以下のいくつかの例を参照して理解を深めてください。

提供された接続情報が重複している場合、環境変数が優先されます。

```bash
$ cat config/database.yml
development:
  adapter: sqlite3
  database: NOT_my_database
  host: localhost

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"postgresql", "database"=>"my_database", "host"=>"localhost"}
    @url="postgresql://localhost/my_database">
  ]
```

上の実行結果で使われているアダプタ、ホスト、データベースは`ENV['DATABASE_URL']`の内容と一致しています。

提供された複数の情報が重複ではなく競合している場合も、常に環境変数の接続設定が優先されます。

```bash
$ cat config/database.yml
development:
  adapter: sqlite3
  pool: 5

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"postgresql", "database"=>"my_database", "host"=>"localhost", "pool"=>5}
    @url="postgresql://localhost/my_database">
  ]
```

poolは`ENV['DATABASE_URL']`で提供される情報に含まれていないので、マージされています。adapterは重複しているので、`ENV['DATABASE_URL']`の接続情報が優先されています。

`ENV['DATABASE_URL']`の情報よりもdatabase.ymlの情報を優先する唯一の方法は、database.ymlで`"url"`サブキーを用いて明示的にURL接続を指定することです。

```bash
$ cat config/database.yml
development:
  url: sqlite3:NOT_my_database

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations.inspect'
#<ActiveRecord::DatabaseConfigurations:0x00007fc8eab02880 @configurations=[
  #<ActiveRecord::DatabaseConfigurations::UrlConfig:0x00007fc8eab020b0
    @env_name="development", @spec_name="primary",
    @config={"adapter"=>"sqlite3", "database"=>"NOT_my_database"}
    @url="sqlite3:NOT_my_database">
  ]
```

今度は`ENV['DATABASE_URL']`の接続情報は無視されました。アダプタとデータベース名が異なります。

`config/database.yml`にはERBを記述できるので、database.yml内で明示的に`ENV['DATABASE_URL']`を使うのが最もよい方法です。これは特にproduction環境で有用です。理由は、データベース接続のパスワードのような秘密情報をGitなどのソースコントロールに直接登録すべきではないからです。

```bash
$ cat config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
```

以上の説明で動作が明らかになりました。接続情報は決してdatabase.ymlに直接書かず、常に`ENV['DATABASE_URL']`に保存したものを利用してください。

#### SQLite3データベースを設定する

Railsには[SQLite3](https://www.sqlite.org)のサポートが組み込まれています。SQLiteは軽量かつ専用サーバーの不要なデータベースアプリケーションです。SQLiteは、production環境の負荷に耐えるよう、より適切に設定されますが、production環境の負荷が高すぎる場合はSQLiteが過負荷になる可能性があります。Railsで新規プロジェクトを作成するとデフォルトでSQLiteが指定されますが、これはいつでも後から変更できます。

以下はデフォルトのコネクション設定ファイル（`config/database.yml`）に含まれる、開発環境用のコネクション設定です。

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  pool: 5
  timeout: 5000
```

NOTE: Railsでデータ保存用にSQLite3データベースが採用されている理由は、設定なしですぐに使えるからです。RailsではSQLiteの他にMySQL（MariaDB含む）やPostgreSQLなども使えますし、データベースコネクション用のプラグインも多数あります。production環境で何らかのデータベースを使う場合、そのためのアダプタはたいていの場合探せば見つかります。

#### MySQLやMariaDBデータベースを設定する

Rails同梱のSQLite3ではなくMySQLやMariaDBなどを採用する場合、`config/database.yml`の記述方法を少し変更します。developmentセクションの記述は以下のようになります。

```yaml
development:
  adapter: mysql2
  encoding: utf8mb4
  database: blog_development
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
```

ユーザー名root、パスワードなしでdevelopment環境のデータベースに接続できれば、上の設定で接続できるはずです。接続できない場合は、`development`セクションのユーザー名またはパスワードを適切なものに変更してください。

NOTE: MySQLのバージョンが5.5または5.6で、かつ`utf8mb4`文字セットをデフォルトで使いたい場合は、MySQLサーバーで`innodb_large_prefix`システム変数を有効にすることで、長いキープレフィックスがサポートされるよう設定してください。

MySQLのAdvisory Locksはデフォルトで有効になります。これはデータベースマイグレーションの並行処理を安全に実行するために用いられます。`advisory_locks`を`false`にするとAdvisory Locksを無効にできます。

```yaml
production:
  adapter: mysql2
  advisory_locks: false
```

#### PostgreSQLデータベースを設定する

PostgreSQLを採用した場合は、`config/database.yml`の記述は以下のようになります。

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: blog_development
  pool: 5
```

Active Recordでは、Prepared StatementsやAdvisory Locksなどの機能がデフォルトでオンになります。PgBouncerなどの外部コネクションプーラーを用いる場合、これらの機能をオフにできます。

```yaml
production:
  adapter: postgresql
  prepared_statements: false
  advisory_locks: false
```

オンにする場合、Active Recordはデフォルトでデータベース接続ごとに最大`1000`までのPrepared Statementsを作成します。この数値を変更したい場合は`statement_limit`に別の数値を指定します。

```yaml
production:
  adapter: postgresql
  statement_limit: 200
```

Prepared Statementsの利用量を増やすと、データベースで必要なメモリー量も増大します。PostgreSQLデータベースのメモリー利用量が上限に達した場合は、`statement_limit`の値を小さくするかPrepared Statementsをオフにしてください。

#### JRubyプラットフォームでSQLite3データベースを設定する

JRuby環境でSQLite3を採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcsqlite3
  database: storage/development.sqlite3
```

#### JRubyプラットフォームでMySQLやMariaDBのデータベースを使う

JRuby環境でMySQLやMariaDBなどを採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcmysql
  database: blog_development
  username: root
  password:
```

#### JRubyプラットフォームでPostgreSQLデータベースを使う

JRuby環境でPostgreSQLを採用する場合、`config/database.yml`の記述方法は少し異なります。developmentセクションは以下のようになります。

```yaml
development:
  adapter: jdbcpostgresql
  encoding: unicode
  database: blog_development
  username: blog
  password:
```

`development`セクションのユーザー名とパスワードは適切なものに置き換えてください。

#### メタデータストレージを設定する

Railsは、自分のRails環境とスキーマに関する情報を、`ar_internal_metadata`という名前の内部テーブルにデフォルトで保存します。

この機能をコネクションごとにオフにするには、利用するデータベース設定ファイルで以下のように`use_metadata_table`を設定します。これは、共有データベースで作業する場合や、テーブル作成権限を持たないデータベースユーザーで作業する場合に便利です。

```yaml
development:
  adapter: postgresql
  use_metadata_table: false
```

#### リトライの振る舞いを設定する

デフォルトでは、Railsは何か問題が発生すると自動的にデータベースサーバに再接続し、特定のクエリをリトライ（再試行）します。安全に再試行できる（冪等な）クエリのみが再試行されます。再試行回数はデータベースの設定で`connection_retries`を使って指定するか、値を0に設定して無効にできます。

```yaml
development:
  adapter: mysql2
  connection_retries: 3
```

データベース設定では`retry_deadline`を設定できます。
`retry_deadline`が設定されると、リトライ可能なクエリが最初に試行されてから指定の時間が経過すると、リトライを**行わなくなります**。たとえば`retry_deadline`を5秒に設定すると、クエリが最初に試行されてから5秒経過すると、たとえそのクエリが冪等かつ`connection_retries`が残っていたとしても、クエリを再試行しなくなります。

デフォルト値は`nil`です。これは、経過時間に関係なく、すべての再試行可能なクエリがリトライされることを意味します。
この設定の値は秒単位で指定する必要があります。

```yaml
development:
  adapter: mysql2
  retry_deadline: 5 # 5秒経過したらリトライを停止する
```

#### クエリキャッシュを設定する

デフォルトでは、Railsはクエリによって返される結果セットを自動的にキャッシュします。同じクエリが発生した場合は、データベースへのクエリ実行ではなく、キャッシュされた結果セットを使います。

このクエリキャッシュはメモリ上に保存されており、メモリ使用量を増やしすぎないために、最も使われていないクエリが一定の閾値に達した時点で自動的に削除されます。デフォルトの閾値は`100`ですが、`database.yml`で設定することも可能です。

```yaml
development:
  adapter: mysql2
  query_cache: 200
```

クエリキャッシュを完全に無効にするには、以下のように`false`に設定します。

```yaml
development:
  adapter: mysql2
  query_cache: false
```

### Rails環境を作成する

Railsにデフォルトで備わっている環境は、"development"、"test"、"production"の3つです。通常はこの3つの環境で事足りますが、場合によっては環境を追加したくなることもあると思います。

たとえば、production環境をミラーコピーしたサーバーをテスト目的でのみ使いたいという場合を想定してみましょう。このようなサーバーは通常「ステージングサーバー（staging server）」と呼ばれます。"staging"環境をサーバーに追加したいのであれば、`config/environments/staging.rb`というファイルを作成するだけで済みます。その際にはなるべく`config/environments`にある既存のファイルを流用し、必要な部分のみを変更するようにしてください。

この環境はproductionに近いので、`config/environments/production.rb`の内容を出発点としてコピーし、そこから必要な変更を加えていけばよいでしょう。また、以下のように他の環境設定を`require`して拡張することも可能です。

```ruby
# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  # stagingをオーバーライドする
end
```

このようにして追加された環境は、デフォルトの3つの環境と同じように利用できます。`rails server -e staging`を実行すればステージング環境でサーバーを起動でき、`rails console -e staging`や`Rails.env.staging?`なども動作するようになります。

### サブディレクトリにデプロイする（相対URL rootの利用）

Railsアプリケーションの実行は、アプリケーションのrootディレクトリ（`/`など）で行なうことが前提となっています。この節では、アプリケーションをディレクトリの下で実行する方法について説明します。

ここでは、アプリケーションを"/app1"ディレクトリにデプロイしたいとします。これを行なうには、適切なルーティングを生成できるディレクトリをRailsに指示する必要があります。

```ruby
config.relative_url_root = "/app1"
```

あるいは、`RAILS_RELATIVE_URL_ROOT`環境変数に設定することも可能です。

これで、リンクが生成される時に"/app1"がディレクトリ名の前に追加されます。

#### Passengerを使う

Passengerを使うと、アプリケーションを手軽にサブディレクトリで実行できます。設定方法について詳しくは、[passengerマニュアル](https://www.phusionpassenger.com/library/deploy/apache/deploy/ruby/#deploying-an-app-to-a-sub-uri-or-subdirectory)を参照してください。

#### リバースプロキシを使う

リバースプロキシを用いるアプリケーションをデプロイすることで、従来のデプロイと比べて確実なメリットが得られます。アプリケーションで必要なコンポーネントの層が追加され、サーバーを制御しやすくなります。

現代的なWebサーバーの多くは、キャッシュサーバーやアプリケーションサーバーなどのロードバランシングにプロキシサーバーを用いています。

[Unicorn](https://bogomips.org/unicorn/)は、リバースプロキシの背後で実行されるアプリケーションサーバーの例です。

この場合、NGINXやApacheなどのプロキシサーバーを設定して、アプリケーションサーバー（ここではUnicorn）からの接続を受け付けるようにする必要があります。Unicornは、デフォルトでTCP接続のポート8000をリッスンしますが、このポート番号を変更することも、ソケットを用いるように設定することも可能です。

詳しくは[Unicorn readme](https://bogomips.org/unicorn/README.html)を参照し、背後の[哲学](https://bogomips.org/unicorn/PHILOSOPHY.html)を理解してください。

アプリケーションサーバーの設定が終わったら、Webサーバーも適切に設定してリクエストのプロキシを行わなければなりません。以下の設定はNGINXの設定に含まれることがあります。


```nginx
upstream application_server {
  server 0.0.0.0:8080;
}

server {
  listen 80;
  server_name localhost;

  root /root/path/to/your_app/public;

  try_files $uri/index.html $uri.html @app;

  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://application_server;
  }

  # （省略）
}
```

必ず[NGINXのドキュメント](https://nginx.org/en/docs/)で最新情報を参照してください。

Rails環境の設定
--------------------------

一部の設定については、Railsの外部から環境変数の形で与えることも可能です。以下の環境変数は、Railsの多くの部分で認識されます。

* `ENV["RAILS_ENV"]`: Railsが実行される環境（production、development、testなど）を定義します。

* `ENV["RAILS_RELATIVE_URL_ROOT"]`: [アプリケーションをサブディレクトリにデプロイする](configuring.html#サブディレクトリにデプロイする（相対url-rootの利用）)ときにルーティングシステムがURLを認識するために使われます。

* `ENV["RAILS_CACHE_ID"]`と`ENV["RAILS_APP_VERSION"]`: Railsのキャッシュを扱うコードで拡張キャッシュを生成するために使われます。これにより、１つのアプリケーションの中で複数の独立したキャッシュを扱えるようになります。

イニシャライザファイルを使う
-----------------------

Railsは、フレームワークの読み込みとすべてのgemの読み込みが完了してから、イニシャライザの読み込みを開始します。イニシャライザとは、アプリケーションの`config/initializers`ディレクトリに保存されているRubyファイルのことです。イニシャライザファイルには、フレームワークやgemがすべて読み込まれた後に行いたい設定（フレームワークやgemを設定するオプションなど）を保存できます。

`config/initializers`（および`config/initializers`のサブディレクトリ）にあるファイルは、`load_config_initializers`イニシャライザの一部として、ソートされて1つずつ読み込まれます。

あるイニシャライザのコードが別のイニシャライザのコードに依存する場合、代わりにそれらを1つのイニシャライザーにまとめることが可能です。こうすることで依存関係がより明確になり、アプリケーション内で新しい概念を表面化するのに有用です。Railsは番号を振ったイニシャライザファイル名もサポートしていますが、これはファイル名の乱立につながる可能性があります。`require`で明示的にイニシャライザを読み込むとイニシャライザが2回読み込まれるので、おすすめできません。

NOTE: 自分のイニシャライザが、他のすべてのgemのイニシャライザが実行された後で実行されるという保証はありません。そのようなgemに依存する初期化コードは、`config.after_initialize`ブロックに配置してください。

読み込みフック
----------

Railsコードは、アプリケーションの読み込み時に頻繁に参照される可能性があります。Railsはこれらのフレームワークの読み込み順序を管理しているので、`ActiveRecord::Base`などのフレームワークを不注意に読み込むと、アプリケーションとRailsとの暗黙の取り決めに違反することになります。さらに、アプリケーションの起動時に`ActiveRecord::Base`などのコードを読み込むとフレームワーク全体が読み込まれてしまうため、起動時間が遅くなり、アプリケーションの読み込み順序や起動で競合が発生する可能性があります。

読み込みフックと設定フックは、読み込みに関するRailsの取り決めに違反せずに、この初期化プロセスにフックできるAPIです。これを使うことで、起動時のパフォーマンス低下も軽減され、競合も回避されます。

### Railsフレームワークの不要な読み込みを回避する

Rubyは動的言語なので、一部のコードで別のRailsフレームワークが読み込まれてしまうことがあります。以下のスニペットを例に挙げます。

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

上のスニペットは、「このファイルが読み込まれると`ActiveRecord::Base`に遭遇する」ことを意味します。これにより、Rubyはその定数の定義を検索して`require`します。これにより、起動時にActive Recordフレームワーク全体が読み込まれてしまいます。

`ActiveSupport.on_load`は、本当に必要になるまでコードの読み込みを延期できるメカニズムです。上のスニペットは以下のように変更できます。

```ruby
ActiveSupport.on_load(:active_record) do
  include MyActiveRecordHelper
end
```

変更後のスニペットは、`ActiveRecord::Base`が読み込まれるときだけ`MyActiveRecordHelper`を`include`します。

### フックはいつ呼ばれるか

Railsフレームワークでは、特定のライブラリが読み込まれたタイミングでこれらのフックが呼び出されます。たとえば、`ActionController::Base`が読み込まれると、`:action_controller_base`フックが呼び出されます。つまり、`:action_controller_base`フックを使うすべての`ActiveSupport.on_load`呼び出しは、`ActionController::Base`のコンテキストで呼び出されることになります（つまり、`self`は`ActionController::Base`になります）。

### 読み込みフックでコードを変更する

コードの変更は一般的に簡単です。`ActiveRecord::Base`などのRailsフレームワークを参照するコード行がある場合は、そのコードを読み込みフックでラップできます。


**`include`呼び出しを変更する場合**

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

上を以下のように変更します。

```ruby
ActiveSupport.on_load(:active_record) do
  # self refers to ActiveRecord::Base here,
  # so we can call .include
  include MyActiveRecordHelper
end
```

**`prepend`呼び出しを変更する場合**

```ruby
ActionController::Base.prepend(MyActionControllerHelper)
```

上を以下のように変更します。

```ruby
ActiveSupport.on_load(:action_controller_base) do
  # self refers to ActionController::Base here,
  # so we can call .prepend
  prepend MyActionControllerHelper
end
```

**クラスメソッド呼び出しを変更する場合**

```ruby
ActiveRecord::Base.include_root_in_json = true
```

上を以下のように変更します。

```ruby
ActiveSupport.on_load(:active_record) do
  # self refers to ActiveRecord::Base here
  self.include_root_in_json = true
end
```

### 利用可能な読み込みフック

以下の読み込みフックは独自のコードで利用可能です。以下のクラスのいずれかの初期化プロセスにフックするには、利用可能なフックを使います。

| クラス名                              |フック                                 |
| -------------------------------------| ------------------------------------ |
| `ActionCable`                        | `action_cable`                       |
| `ActionCable::Channel::Base`         | `action_cable_channel`               |
| `ActionCable::Connection::Base`      | `action_cable_connection`            |
| `ActionCable::Connection::TestCase`  | `action_cable_connection_test_case`  |
| `ActionController::API`              | `action_controller_api`              |
| `ActionController::API`              | `action_controller`                  |
| `ActionController::Base`             | `action_controller_base`             |
| `ActionController::Base`             | `action_controller`                  |
| `ActionController::TestCase`         | `action_controller_test_case`        |
| `ActionDispatch::IntegrationTest`    | `action_dispatch_integration_test`   |
| `ActionDispatch::Response`           | `action_dispatch_response`           |
| `ActionDispatch::Request`            | `action_dispatch_request`            |
| `ActionDispatch::SystemTestCase`     | `action_dispatch_system_test_case`   |
| `ActionMailbox::Base`                | `action_mailbox`                     |
| `ActionMailbox::InboundEmail`        | `action_mailbox_inbound_email`       |
| `ActionMailbox::Record`              | `action_mailbox_record`              |
| `ActionMailbox::TestCase`            | `action_mailbox_test_case`           |
| `ActionMailer::Base`                 | `action_mailer`                      |
| `ActionMailer::TestCase`             | `action_mailer_test_case`            |
| `ActionText::Content`                | `action_text_content`                |
| `ActionText::Record`                 | `action_text_record`                 |
| `ActionText::RichText`               | `action_text_rich_text`              |
| `ActionText::EncryptedRichText`      | `action_text_encrypted_rich_text`    |
| `ActionView::Base`                   | `action_view`                        |
| `ActionView::TestCase`               | `action_view_test_case`              |
| `ActiveJob::Base`                    | `active_job`                         |
| `ActiveJob::TestCase`                | `active_job_test_case`               |
| `ActiveModel::Model`                 | `active_model`                       |
| `ActiveModel::Translation`           | `active_model_translation`           |
| `ActiveRecord::Base`                 | `active_record`                      |
| `ActiveRecord::Encryption`           | `active_record_encryption`           |
| `ActiveRecord::TestFixtures`         | `active_record_fixtures`             |
| `ActiveRecord::ConnectionAdapters::PostgreSQLAdapter`    | `active_record_postgresqladapter`    |
| `ActiveRecord::ConnectionAdapters::Mysql2Adapter`        | `active_record_mysql2adapter`        |
| `ActiveRecord::ConnectionAdapters::TrilogyAdapter`       | `active_record_trilogyadapter`       |
| `ActiveRecord::ConnectionAdapters::SQLite3Adapter`       | `active_record_sqlite3adapter`       |
| `ActiveStorage::Attachment`          | `active_storage_attachment`          |
| `ActiveStorage::VariantRecord`       | `active_storage_variant_record`      |
| `ActiveStorage::Blob`                | `active_storage_blob`                |
| `ActiveStorage::Record`              | `active_storage_record`              |
| `ActiveSupport::TestCase`            | `active_support_test_case`           |
| `i18n`                               | `i18n`                               |

初期化イベント
---------------------

Railsにはフック可能な初期化イベントが5つあります。以下のイベントは、実際に実行される順序で掲載しています。

#### `before_configuration`

このフックは、アプリケーションのクラスが`config/application.rb`で`Rails::Application`を継承するタイミングで（クラスの本文が実行される前に）実行されます。Railsエンジンは、アプリケーション自身が設定される前に、このフックでコードを実行する場合があります。

#### `before_initialize`

このフックは、`:bootstrap_hook`イニシャライザによる初期化プロセスの直前に直接実行されます。`:bootstrap_hook`は、Railsアプリケーション初期化プロセスのうち比較的初期の段階で実行されます。

#### `to_prepare`

このフックは、Railties（およびアプリケーション自身）の初期化処理がすべて完了した後で、ミドルウェアスタックがビルドされた**直後**、かつeager loadingの**直前**に実行されます。さらに重要な点は、このフックは`development`モードではコードが再読み込みされるたびに必ず実行されますが、`production`モードと`test`モードでは起動時に1度しか実行されないことです。

#### `before_eager_load`

このフックは、事前eager loadingの前に直接実行されます。これは`production`環境のデフォルトの動作で、`development`環境では実行されません。

#### `after_initialize`

このフックは、アプリケーションの初期化が完了し、かつ`config/initializers`以下のイニシャライザが実行された後に実行されます。

これらのフックでイベントを定義するには、`Rails::Application`、`Rails::Railtie`、または`Rails::Engine`サブクラス内でブロック記法を使います。

```ruby
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # ここに初期化コードを書く
    end
  end
end
```

あるいは、`Rails.application`オブジェクトで以下のように`config`メソッドを実行することも可能です。

```ruby
Rails.application.config.before_initialize do
  # ここに初期化コードを書く
end
```

WARNING: アプリケーションの一部（特にルーティング）には、`after_initialize`ブロックが呼び出された時点で設定が完了しないものがあります。

### `Rails::Railtie#initializer`

Railsには起動時に実行されるさまざまなイニシャライザがあり、それらはすべて`Rails::Railtie`の`initializer`メソッドで定義されます。以下はAction Controllerの`set_helpers_path`イニシャライザの例です。

```ruby
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
```

この`initializer`メソッドは3つの引数を取ります。第1引数はイニシャライザ名、第2引数はオプションハッシュ（上の例では使っていません）、そして第3引数はブロックです。

オプションハッシュに含まれる`:before`キーを使うと、新しいイニシャライザより前に実行したいイニシャライザを指定できます。同様に、`:after`キーを使うと、このイニシャライザより**後**に実行したいイニシャライザを指定できます。

`initializer`メソッドで定義されたイニシャライザは、定義された順序で実行されます（`:before`や`:after`を使った場合は除きます）。

WARNING: イニシャライザの起動順序は、論理的に矛盾が生じない限り、どのイニシャライザの前または後にでも配置可能です。たとえば、"one"〜"four"という4つのイニシャライザがあり、かつこの順序で定義されたとします。ここで"four"を"two"より**前**かつ"three"よりも**後**になるように定義すると論理矛盾が発生し、イニシャライザの実行順を決定できなくなってしまいます。

`initializer`メソッドのブロック引数は、アプリケーション自身のインスタンスです。そのおかげで、上の例で示したように、`config`メソッドでアプリケーションの設定にアクセスできます。

`Rails::Application`は`Rails::Railtie`を間接的に継承しているので、`config/application.rb`で`initializer`メソッドを使ってアプリケーションの初期化処理を定義できます。

### イニシャライザ

以下はRailsにあるイニシャライザのリストです。これらは定義された順序で並んでおり、特記事項がない限り実行されます。

#### `load_environment_hook`

これはプレースホルダとして使われます。具体的には、`:load_environment_config`を定義してこのイニシャライザより前に実行したい場合に使います。

#### `load_active_support`

Active Supportの基本部分を設定する`active_support/dependencies`を`require`します。`config.active_support.bare`がない場合はデフォルトで`active_support/all`を`require`します。

#### `initialize_logger`

ここより前の位置に`Rails.logger`を定義するイニシャライザがない場合、アプリケーションのロガー（`ActiveSupport::BroadcastLogger`オブジェクト）を初期化し、`Rails.logger`にアクセスできるようにします。

#### `initialize_cache`

`Rails.cache`が未設定の場合、`config.cache_store`の値を参照してキャッシュを初期化し、その結果を`Rails.cache`として保存します。そのオブジェクトが`middleware`メソッドに応答する場合、そのミドルウェアをミドルウェアスタックの`Rack::Runtime`の前に挿入します。

#### `set_clear_dependencies_hook`

このイニシャライザは、`config.enable_reloading`が`true`の場合にのみ実行され、オブジェクト空間からのリクエスト中に参照された定数を`ActionDispatch::Callbacks.after`で削除します。これにより、これらの定数が以後のリクエストで再読み込みされるようになります。

#### `bootstrap_hook`

このフックはすべての設定済み`before_initialize`ブロックを実行します。

#### `i18n.callbacks`

development環境の場合、`to_prepare`コールバックを設定します。このコールバックは、最後にリクエストが発生した後にロケールが変更されると`I18n.reload!`を呼び出します。productionモードの場合、このコールバックは最初のリクエストでのみ実行されます。

#### `active_support.deprecation_behavior`

以下に基づいた[`Rails.application.deprecators`][]の非推奨項目レポートをセットアップします。

- [`config.active_support.report_deprecations`](#config-active-support-report-deprecations)
- [`config.active_support.deprecation`](#config-active-support-deprecation)
- [`config.active_support.disallowed_deprecation`](#config-active-support-disallowed-deprecation)
- [`config.active_support.disallowed_deprecation_warnings`](#config-active-support-disallowed-deprecation-warnings)

#### `active_support.initialize_time_zone`

`config.time_zone`の設定に基いてアプリケーションのデフォルトタイムゾーンを設定します。デフォルト値は"UTC"です。

#### `active_support.initialize_beginning_of_week`

`config.beginning_of_week`の設定に基づいてアプリケーションのデフォルトの週開始日を設定します。デフォルト値は`:monday`です。

#### `active_support.set_configs`

`config.active_support`内の設定を用いてActive Supportをセットアップします。メソッド名を`ActiveSupport`のセッターとして`send`し、その値をActive Supportに渡します。

#### `action_dispatch.configure`

`ActionDispatch::Http::URL.tld_length`を構成して、`config.action_dispatch.tld_length`の値（トップレベルドメイン名の長さ）が設定されるようにします。

#### `action_view.set_configs`

`config.action_view`内の設定を用いてAction Viewをセットアップします。メソッド名を`ActionView::Base`のセッターとして`send`し、その値をAction Viewに渡します。

#### `action_controller.assets_config`

明示的に設定されていない場合は、`config.action_controller.assets_dir`をアプリケーションの`public/`ディレクトリに設定します。

#### `action_controller.set_helpers_path`

Action Controllerの`helpers_path`をアプリケーションの`helpers_path`に設定します。

#### `action_controller.parameters_config`

`ActionController::Parameters`で使うStrong Parametersオプションを設定します。

#### `action_controller.set_configs`

`config.action_controller`内の設定を用いてAction Controllerをセットアップします。メソッド名を`ActionController::Base`のセッターとして`send`し、その値をAction Controllerに渡します。

#### `action_controller.compile_config_methods`

指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

#### `active_record.initialize_timezone`

`ActiveRecord::Base.time_zone_aware_attributes`を`true`に設定し、`ActiveRecord::Base.default_timezone`をUTCに設定します。属性がデータベースから読み込まれると、`Time.zone`で指定されたタイムゾーンに変換されます。

#### `active_record.logger`

`ActiveRecord::Base.logger`に`Rails.logger`を設定します（未設定の場合）。

#### `active_record.migration_error`

未実行のマイグレーションがあるかどうかをチェックするミドルウェアを設定します。

#### `active_record.check_schema_cache_dump`

スキーマキャッシュダンプを読み込みます（設定済みかつ可能な場合）。

#### `active_record.set_configs`

`config.active_record`内の設定を用いてActive Recordをセットアップします。メソッド名を`ActiveRecord::Base`のセッターとして`send`し、その値をActive Recordに渡します。

#### `active_record.initialize_database`

データベース設定を`config/database.yml`（デフォルト）から読み込み、現在の環境でデータベース接続を確立します。

#### `active_record.log_runtime`

リクエストでActive Record呼び出しに要した時間をロガーに出力する`ActiveRecord::Railties::ControllerRuntime`および`ActiveRecord::Railties::JobRuntime`をインクルードします。

#### `active_record.set_reloader_hooks`

`config.cache_classes`が`false`の場合、再読み込み可能なデータベース接続をすべてリセットします。

#### `active_record.add_watchable_files`

変更の監視対象ファイルに`schema.rb`ファイルと`structure.sql`ファイルを追加します。

#### `active_job.logger`

`ActiveJob::Base.logger`に`Rails.logger`を設定します（未設定の場合）。

#### `active_job.set_configs`

`config.active_job`内の設定を用いてActive Jobをセットアップします。メソッド名を`ActiveJob::Base`のセッターとして`send`し、その値をActive Jobに渡します。

#### `action_mailer.logger`

`ActionMailer::Base.logger`に`Rails.logger`を設定します（未設定の場合）。

#### `action_mailer.set_configs`

`config.action_mailer`内の設定を用いてAction Mailerをセットアップします。メソッド名を`ActionMailer::Base`のセッターとして`send`し、その値をAction Mailerに渡します。

#### `action_mailer.compile_config_methods`

指定された設定用メソッドを初期化し、より高速にアクセスできるようにします。

#### `set_load_path`

このイニシャライザは`bootstrap_hook`の前に実行されます。`config.load_paths`およびすべての自動読み込みパスが`$LOAD_PATH`に追加されます。
また、`config.add_autoload_paths_to_load_path`を`false`に設定「しない」場合は、`config.autoload_paths`、`config.eager_load_paths`、`config.autoload_once_paths`で指定された自動読み込みパスもすべて追加されます。

#### `set_autoload_paths`

このイニシャライザは`bootstrap_hook`の前に実行されます。`app/`以下のすべてのサブディレクトリと、`config.autoload_paths`、`config.eager_load_paths`、`config.autoload_once_paths`で指定したすべてのパスが`ActiveSupport::Dependencies.autoload_paths`に追加されます。

#### `add_routing_paths`

デフォルトで、アプリケーションやrailtiesやエンジンにある`config/routes.rb`ファイルをすべて読み込み、アプリケーションのルーティングを設定します。

#### `add_locales`

アプリケーションやrailtiesやエンジンにある`config/locales`ファイルを`I18n.load_path`に追加し、そのパスで指定された場所にある訳文にアクセスできるようにします。

#### `add_view_paths`

`app/views`（アプリケーションとrailties、エンジンも含む）へのパスをビューファイルへの探索パスに追加します。

#### `add_mailer_preview_paths`

アプリケーションやrailtiesやエンジンからの`test/mailers/previews`ディレクトリを、そのアプリケーションのメーラープレビューファイルの検索パスに追加します。

#### `load_environment_config`

このイニシャライザーは`load_environment_hook`の前に実行されます。現在の環境用の`config/environments`ファイルを読み込みます。

#### `prepend_helpers_path`

アプリケーションやrailtiesやエンジンに含まれる`app/helpers`ディレクトリをヘルパーへの探索パスに追加します。

#### `load_config_initializers`

アプリケーションやrailtiesやエンジンにある`config/initializers`のRubyファイルをすべて読み込みます。このディレクトリに置かれているファイルには、フレームワークの読み込みがすべて完了した後に行うべき設定も保存できます。

#### `engines_blank_point`

エンジンの読み込みが完了する前に行いたい処理に使う初期化ポイントへのフックを提供します。このポイント以後は、railtiesやエンジンのイニシャライザはすべて実行されます。

#### `add_generator_templates`

アプリケーションやrailtiesやエンジンにある`lib/templates`ディレクトリにあるジェネレータ用のテンプレートを探索して`config.generators.templates`設定に追加します。この設定によって、すべてのジェネレータでテンプレートを参照できるようになります。

#### `ensure_autoload_once_paths_as_subset`

`config.autoload_once_paths`に、`config.autoload_paths`以外のパスが含まれないようにします。それ以外のパスが含まれている場合は例外が発生します。

#### `add_to_prepare_blocks`

アプリケーションやrailtiesやエンジンにあるすべての`config.to_prepare`呼び出しのブロックが、Action Dispatchの`to_prepare`に追加されます。Action Dispatchはdevelopmentモードではリクエストごとに実行され、productionモードでは最初のリクエストの前に実行されます。

#### `add_builtin_route`

アプリケーションがdevelopment環境で動作している場合、`rails/info/properties`へのルーティングをアプリケーションのルーティングに追加します。ブラウザでこのルーティングにアクセスすると、デフォルトのRailsアプリケーションで`public/index.html`に表示されるのと同様の詳細情報（RailsやRubyのバージョンなど）を表示できます。

#### `build_middleware_stack`

アプリケーションのミドルウェアスタックをビルドし、`call`メソッドを持つオブジェクトを返します。この`call`メソッドは、リクエストに対するRack環境のオブジェクトを受け取ります。

#### `eager_load!`

`config.eager_load`がtrueに設定されている場合、`config.before_eager_load`フックを実行してから`eager_load!`を呼び出します。この呼び出しによって、すべての`config.eager_load_namespaces`が呼び出されます。

#### `finisher_hook`

アプリケーションの初期化プロセス完了後に実行されるフックを提供します。アプリケーションやrailtiesやエンジンの`config.after_initialize`ブロックもすべて実行します。

#### `set_routes_reloader_hook`

ルーティングファイルが`ActiveSupport::Callbacks.to_run`で再読み込みされるようAction Dispatchを構成します。

#### `disable_dependency_loading`

`config.eager_load`が`true`の場合は自動依存関係読み込み（automatic dependency loading）を無効にします。

[`Rails.application.deprecators`]: https://api.rubyonrails.org/classes/Rails/Application.html#method-i-deprecators

データベースコネクションをプールする
----------------

Active Recordのデータベースコネクションは[`ActiveRecord::ConnectionAdapters::ConnectionPool`][]で管理されます。これは、コネクション数に限りのあるデータベースコネクションにアクセスするときに、スレッドアクセス数とコネクションプールが同期するようにします。デフォルトの最大接続数は5で、`database.yml`でカスタマイズ可能です。

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  pool: 5
  timeout: 5000
```

コネクションプールはデフォルトでActive Recordが扱うので、ThinやPumaやUnicornなどのアプリケーションサーバーの動作は同じになるはずです。最初はデータベースのコネクションプールは空で、コネクションプールの上限に達するまで必要に応じてコネクションが追加されます。

１つのリクエストでは、データベースアクセスが最初に必要になったときにコネクションをチェックアウト（貸出）し、リクエストが終了するときにコネクションをチェックイン（返却）します。つまり、キューで待機している後続のリクエストで追加のコネクションスロットが再び利用可能になります。

利用可能な数を超えるコネクションを使おうとすると、Active Recordはコネクションをブロックし、プールのコネクションが空くのを待ちます。コネクションを取得できない場合は以下のようなタイムアウトエラーが発生します。

```
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5.000 seconds (waited 5.000 seconds)
```

上のエラーが発生する場合は、`database.yml`の`pool`オプションの数値を増やしてコネクションプールのサイズを増やすとよいでしょう。

NOTE: マルチスレッド環境で動作しているアプリケーションでは、多数のスレッドが多数のコネクションに同時アクセスする可能性があります。その時点のリクエストの負荷によっては、限られたコネクションを多数のスレッドが奪い合う可能性があります。

[`ActiveRecord::ConnectionAdapters::ConnectionPool`]: https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html

カスタム設定
--------------------

Railsの設定オブジェクトに独自のコードを設定するには、`config.x`名前空間または`config`に直接コードを書きます。両者の重要な違いは、**ネストした**設定（`config.x.nested.nested.hi`など）の場合は`config.x`を使うべきで、**単一レベル**の設定（`config.hello`など）では`config`だけを使うべきであるという点です。

```ruby
config.x.payment_processing.schedule = :daily
config.x.payment_processing.retries  = 3
config.super_debugger = true
```

これにより、設定オブジェクトを介してこれらの設定場所にアクセス可能になります。

```ruby
Rails.configuration.x.payment_processing.schedule # => :daily
Rails.configuration.x.payment_processing.retries  # => 3
Rails.configuration.x.payment_processing.not_set  # => nil
Rails.configuration.super_debugger                # => true
```

`Rails::Application.config_for`を使うと、設定ファイル全体を読み込むことも可能です。

```yaml
# config/payment.yml
production:
  environment: production
  merchant_id: production_merchant_id
  public_key:  production_public_key
  private_key: production_private_key

development:
  environment: sandbox
  merchant_id: development_merchant_id
  public_key:  development_public_key
  private_key: development_private_key
```

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.payment = config_for(:payment)
  end
end
```

```ruby
Rails.configuration.payment["merchant_id"] # => production_merchant_id or development_merchant_id
```

`Rails::Application.config_for`は、共通の設定をグループ化する`shared`設定をサポートしています。この共有設定は、環境設定にマージされます。

```yaml
# config/example.yml
shared:
  foo:
    bar:
      baz: 1

development:
  foo:
    bar:
      qux: 2
```

```ruby
# development environment
Rails.application.config_for(:example)[:foo][:bar] #=> { baz: 1, qux: 2 }
```

検索エンジン向けのインデックス作成
-----------------------

場合によっては、アプリケーションの一部のページをGoogleやBingやYahooやDuck Duck Goなどの検索サイトに表示したくないことがあります。サイトのインデックスを作成するロボットは、インデックス作成を許可されているページを調べるために、最初に`http://your-site.com/robots.txt`ファイルの内容を分析します。

Railsはこのファイルを`/public`の下に作成します。デフォルトの設定では、アプリケーションのすべてのページで検索エンジンによるインデックス作成を許可します。アプリケーションのすべてのページでインデックス作成をブロックするには、robots.txtに以下を記述します。

```
User-agent: *
Disallow: /
```

特定のページのみをブロックする場合は、もう少し複雑な構文が必要です。詳しくはrobot.txtの[公式ドキュメント](https://www.robotstxt.org/robotstxt.html)を参照してください。
