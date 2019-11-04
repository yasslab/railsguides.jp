**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Ruby on Rails 5.2 リリースノート
===============================

Rails 5.2の注目ポイント:

* Active Storage
* Redisキャッシュストア
* HTTP/2 Early Hints
* credential管理
* Content Security Policy（CSP）

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/5-2-stable)のchangelogを参照してください。


--------------------------------------------------------------------------------

Rails 5.2へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 5.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 5.2にアップデートしてください。アップグレードの注意点などについては[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-5-1からrails-5-2へのアップグレード)を参照してください。

主要な機能
--------------

### Active Storage

[Pull Request](https://github.com/rails/rails/pull/30020)

[Active Storage](https://github.com/rails/rails/tree/5-2-stable/activestorage)が、Amazon S3/Google Cloud Storage/Microsoft Azure Storageなどのクラウドストレージにファイルをアップロードし、それらのファイルをActive Recordオブジェクトにアタッチできるようになりました。開発中やテスト中に用いるローカルのディスクベースのサービスも利用でき、バックアップや移行に用いるサブサービスへのミラーリングもサポートされました。
Active Storageの詳細については[Active Storageの概要](active_storage_overview.html)を参照してください。

### Redis Cache Store

[Pull Request](https://github.com/rails/rails/pull/31134)

Rails 5.2にRedisキャッシュストアが組み込まれました。
詳しくは、ガイドの[Rails のキャッシュ機構](caching_with_rails.html#activesupport-cache-rediscachestore)を参照してください。

### HTTP/2 Early Hints

[Pull Request](https://github.com/rails/rails/pull/30744)

Rails 5.2で[HTTP/2 Early Hints](https://tools.ietf.org/html/rfc8297)がサポートされました。Early Hintsを有効にしてサーバーを起動するには、`bin/rails server`に`--early-hints`オプションを渡します。

### credential管理

[Pull Request](https://github.com/rails/rails/pull/30067)

`config/credentials.yml.enc`ファイルが追加され、productionアプリケーションの秘密情報（secret）をここに保存できるようになりました。これによって、外部サービスのあらゆる認証credentialを、`config/master.key`ファイルまたは`RAILS_MASTER_KEY`環境変数にあるキーで暗号化した形で直接リポジトリに保存できます。`Rails.application.secrets`やRails 5.1で導入された暗号化済み秘密情報は、最終的にこれによって置き換えられます。
さらに、Rails 5.2では[credentialを支えるAPIが用意され](https://github.com/rails/rails/pull/30940)、その他の暗号化済み設定/キー/ファイルも簡単に扱えます。
詳しくは、[Rails セキュリティガイド](security.html#独自のcredential)を参照してください。

### Content Security Policy（CSP）

[Pull Request](https://github.com/rails/rails/pull/31162)

Rails 5.2では、アプリケーションの [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)（CSP）を設定する新しいDSLが使えるようになりました。グローバルなポリシーを1つ設定しておき、続いてリソースベースでポリシーをオーバーライドすることも、lambdaを使ってリクエストごとにヘッダーに値を注入することもできます（マルチテナントのアプリでアカウントのサブドメインを注入するなど）。
詳しくは、[Rails セキュリティガイド](security.html#content-security-policy)を参照してください。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 非推奨

* ジェネレーターとテンプレートでの`capify!`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/29493))

* `rails dbconsole`や`rails console`に環境変数名を通常の引数として渡すことを非推奨に指定。`-e`オプションを明示的に利用すべき。
    ([Commit](https://github.com/rails/rails/commit/48b249927375465a7102acc71c2dfb8d49af8309))

* `Rails::Application`のサブクラスを用いてRailsサーバーを起動することを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/30127))

* Railsプラグインテンプレートでの`after_bundle`コールバックを非推奨に指定。

### 主な変更点

* `config/database.yml`に、すべての環境で読み込まれる共有セクションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/28896))

* プラグインジェネレーターに`railtie.rb`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/29576))

* `tmp:clear`タスクでスクリーンショットファイルを削除する機能。
    ([Pull Request](https://github.com/rails/rails/pull/29534))

* `bin/rails app:update`実行時に未利用のコンポーネントをスキップ。
  最初のアプリケーション生成でAction CableやActive Recordがスキップされると、これらに関連する更新もスキップされる。
    ([Pull Request](https://github.com/rails/rails/pull/29645))

* 3-levelデータベース設定利用時にカスタムコネクション名を`rails dbconsole`に渡せるようになった。
  例: `bin/rails dbconsole -c replica`.
    ([Commit](https://github.com/rails/rails/commit/1acd9a6464668d4d54ab30d016829f60b70dbbeb))

* `console`コマンドや`dbconsole`コマンドの実行時に渡す環境名のショートカットが正しく展開されるようになった。
    ([Commit](https://github.com/rails/rails/commit/3777701f1380f3814bd5313b225586dec64d4104))

* `bootsnap`をデフォルトの`Gemfile`に追加。
    ([Pull Request](https://github.com/rails/rails/pull/29313))

* `rails runner`でプラットフォームを問わずSTDINからのスクリプトを実行するための`-`をサポート
    ([Pull Request](https://github.com/rails/rails/pull/26343))

* Railsアプリケーション新規作成時に`Gemfile`に`ruby x.x.x`を追加し、`.ruby-version`に現在のRubyバージョンを追加するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30016))

* プラグインジェネレーターに`--skip-action-cable`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30164))

* `Gemfile`に`git_source`オプションを追加（プラグインジェネレータ用）。
    ([Pull Request](https://github.com/rails/rails/pull/30110))

* Railsプラグインで`bin/rails`を実行するときに未利用コンポーネントをスキップ。
    ([Commit](https://github.com/rails/rails/commit/62499cb6e088c3bc32a9396322c7473a17a28640))

* ジェネレーターのアクションのインデントを最適化。
    ([Pull Request](https://github.com/rails/rails/pull/30166))

* ルーティングのインデントを最適化。
    ([Pull Request](https://github.com/rails/rails/pull/30241))

* プラグインジェネレーターに`--skip-yarn`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30238))

* ジェネレータの`gem`メソッドで引数のバージョンを複数取れるようサポート。
    ([Pull Request](https://github.com/rails/rails/pull/30323))

* development/test環境でアプリケーション名を元に`secret_key_base`を生成。
    ([Pull Request](https://github.com/rails/rails/pull/30067))

* デフォルトの`Gemfile`に`mini_magick`をコメントアウトの形で追加。
    ([Pull Request](https://github.com/rails/rails/pull/30633))

* `Active Storage`が`rails new`または`rails plugin new`でデフォルトで有効。
  `--skip-active-storage`で`Active Storage`をスキップする。また、`--skip-active-record`を用いた場合にも`Active Storage`をスキップする。
    ([Pull Request](https://github.com/rails/rails/pull/30101))

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

*  非推奨のevented Redisアダプターを削除
    ([Commit](https://github.com/rails/rails/commit/48766e32d31651606b9f68a16015ad05c3b0de2c))

### 主な変更点

* cable.ymlに`host`、`port`、`db`、`password`オプションのサポートを追加。
    ([Pull Request](https://github.com/rails/rails/pull/29528))

* PostgreSQLアダプタ利用時のlong stream IDのハッシュを修正。
    ([Pull Request](https://github.com/rails/rails/pull/29297))

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

* 非推奨の`ActionController::ParamsParser::ParseError`を削除。
    ([Commit](https://github.com/rails/rails/commit/e16c765ac6dcff068ff2e5554d69ff345c003de1))

### 非推奨

* `ActionDispatch::TestResponse`のエイリアスである`#success?`、`#missing?`、`#error?`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/30104))

### 主な変更点

* フラグメントキャッシュでのリサイクル可能キャッシュキーをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/29092))

* フラグメントのキャッシュキー形式を変更（キーchurnのデバッグを容易にするため）
    ([Pull Request](https://github.com/rails/rails/pull/29092))

* AEAD暗号化cookieとセッションにGCMを追加。
    ([Pull Request](https://github.com/rails/rails/pull/28132))

* デフォルトでフォージェリーから保護。
    ([Pull Request](https://github.com/rails/rails/pull/29742))

* 署名/暗号化済みcookieの期限終了をサーバー側で強制。
    ([Pull Request](https://github.com/rails/rails/pull/30121))

* cookieの`:expires`オプションで`ActiveSupport::Duration`オブジェクトをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/30121))

* `:puma`サーバー設定にCapybaraを登録済みにした。
    ([Pull Request](https://github.com/rails/rails/pull/30638))

* cookieミドルウェアをシンプルにするためにキーローテーションサポートを追加。
    ([Pull Request](https://github.com/rails/rails/pull/29716))

* HTTP/2向けのEarly Hintsを有効にする機能を追加。
    ([Pull Request](https://github.com/rails/rails/pull/30744))

* システムテストでのheadless Chromeサポートを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30876))

* `redirect_back`メソッドに`:allow_other_host`オプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30850))

* `assert_recognizes`がマウントしたエンジンをトラバースするようにした。
    ([Pull Request](https://github.com/rails/rails/pull/22435))

* Content-Security-Policyヘッダー設定用のDSLを追加。
    ([Pull Request](https://github.com/rails/rails/pull/31162),
    [Commit](https://github.com/rails/rails/commit/619b1b6353a65e1635d10b8f8c6630723a5a6f1a),
    [Commit](https://github.com/rails/rails/commit/4ec8bf68ff92f35e79232fbd605012ce1f4e1e6e))

* モダンなブラウザでサポートされている著名な音声/動画/フォントのMIMEタイプを登録。
    ([Pull Request](https://github.com/rails/rails/pull/31251))

* システムテストのデフォルト出力フォーマットを`inline`から`simple`に変更。
    ([Commit](https://github.com/rails/rails/commit/9d6e288ee96d6241f864dbf90211c37b14a57632))

* システムテストにheadless Firefoxサポートを追加
    ([Pull Request](https://github.com/rails/rails/pull/31365))

* セキュアな`X-Download-Options`および`X-Permitted-Cross-Domain-Policies`をデフォルトのヘッダーセットに追加。
    ([Commit](https://github.com/rails/rails/commit/5d7b70f4336d42eabfc403e9f6efceb88b3eff44))

* システムテストで、ユーザーが別のサーバーを手動でしていない場合にのみPumaをデフォルトのサーバーとして設定するように変更。
    ([Pull Request](https://github.com/rails/rails/pull/31384))

* `Referrer-Policy`ヘッダーをデフォルトのヘッダーセットに追加。
    ([Commit](https://github.com/rails/rails/commit/428939be9f954d39b0c41bc53d85d0d106b9d1a1))

* `Hash#each`の振る舞いを`ActionController::Parameters#each`に合わせた。
    ([Pull Request](https://github.com/rails/rails/pull/27790))

* Rails UJS向けにnonceの自動生成をサポート。
    ([Commit](https://github.com/rails/rails/commit/b2f0a8945956cd92dec71ec4e44715d764990a49))

* デフォルトのHSTS `max-age`値を31536000秒（1年）に更新。
    ([Commit](https://github.com/rails/rails/commit/30b5f469a1d30c60d1fb0605e84c50568ff7ed37))

* `cookies`の`to_h`メソッドのエイリアス`to_hash`メソッドを追加
* `session`の`to_hash`メソッドのエイリアス`to_h`メソッドを追加
    ([Commit](https://github.com/rails/rails/commit/50a62499e41dfffc2903d468e8b47acebaf9b500))

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

* 非推奨のErubis ERB handler.
    ([Commit](https://github.com/rails/rails/commit/7de7f12fd140a60134defe7dc55b5a20b2372d06))

### 非推奨

*   `image_tag`のデフォルトのaltテキストを追加する`image_alt`ヘルパーが非推奨になりました。
    ([Pull Request](https://github.com/rails/rails/pull/30213))

### 主な変更点

*   [JSON Feeds](https://jsonfeed.org/version/1)に対応するため、`auto_discovery_link_tag`に`:json`タイプを追加しました。
    ([Pull Request](https://github.com/rails/rails/pull/29158))

*   `image_tag`ヘルパーに`srcset`オプションを追加しました。
    ([Pull Request](https://github.com/rails/rails/pull/29349))

*   `optgroup`と`option`でラップした`field_error_proc`のバグを修正しました。
    ([Pull Request](https://github.com/rails/rails/pull/31088))

*   `form_with`がデフォルトでidを生成するようになりました。
    ([Commit](https://github.com/rails/rails/commit/260d6f112a0ffdbe03e6f5051504cb441c1e94cd))

*   `preload_link_tag`ヘルパーを追加しました。
    ([Pull Request](https://github.com/rails/rails/pull/31251))

*   グループ化されたセレクト用のgroupメソッドが呼び出し可能オブジェクトとして使えるようになりました。
    ([Pull Request](https://github.com/rails/rails/pull/31578))

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 主要な変更

* Action Mailerクラスで自身の配信ジョブを設定できるようにした。
    ([Pull Request](https://github.com/rails/rails/pull/29457))

* `assert_enqueued_email_with`テストヘルパーを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30695))

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

* 非推奨の`#migration_keys`を削除。
    ([Pull Request](https://github.com/rails/rails/pull/30337))

* Active Recordオブジェクトをタイプキャストした場合の非推奨`quoted_id`を削除。
    ([Commit](https://github.com/rails/rails/commit/82472b3922bda2f337a79cef961b4760d04f9689))

* 非推奨の`default`引数を`index_name_exists?`から削除。
    ([Commit](https://github.com/rails/rails/commit/8f5b34df81175e30f68879479243fbce966122d7))

* 関連付けにおける`:class_name`へのクラス名渡し（非推奨）を削除。
    ([Commit](https://github.com/rails/rails/commit/e65aff70696be52b46ebe57207ebd8bb2cfcdbb6))

* 非推奨`initialize_schema_migrations_table`メソッドと    `initialize_internal_metadata_table`メソッドを削除。
    ([Commit](https://github.com/rails/rails/commit/c9660b5777707658c414b430753029cd9bc39934))

* 非推奨の`supports_migrations?`メソッドを削除。
    ([Commit](https://github.com/rails/rails/commit/9438c144b1893f2a59ec0924afe4d46bd8d5ffdd))

* 非推奨の`supports_primary_key?`メソッドを削除。
    ([Commit](https://github.com/rails/rails/commit/c56ff22fc6e97df4656ddc22909d9bf8b0c2cbb1))

* 非推奨の`ActiveRecord::Migrator.schema_migrations_table_name`メソッドを削除。
    ([Commit](https://github.com/rails/rails/commit/7df6e3f3cbdea9a0460ddbab445c81fbb1cfd012))

* 非推奨の`name`引数を`#indexes`から削除。
    ([Commit](https://github.com/rails/rails/commit/d6b779ecebe57f6629352c34bfd6c442ac8fba0e))

* 非推奨の引数を`#verify!`から削除
    ([Commit](https://github.com/rails/rails/commit/9c6ee1bed0292fc32c23dc1c68951ae64fc510be))

* 非推奨の`.error_on_ignored_order_or_limit`設定を削除。
    ([Commit](https://github.com/rails/rails/commit/e1066f450d1a99c9a0b4d786b202e2ca82a4c3b3))

* 非推奨の`#scope_chain`を削除。
    ([Commit](https://github.com/rails/rails/commit/ef7784752c5c5efbe23f62d2bbcc62d4fd8aacab))

* 非推奨の`#sanitize_conditions`メソッドを削除。
    ([Commit](https://github.com/rails/rails/commit/8f5413b896099f80ef46a97819fe47a820417bc2))

### 非推奨

* `supports_statement_cache?`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/28938))

* `ActiveRecord::Calculations`の`count`や`sum`に引数とブロックを同時に渡すことを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/29262))

* `Relation`を`arel`に委譲することを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/29619))

* `TransactionState`の`set_state`を非推奨に指定。
    ([Commit](https://github.com/rails/rails/commit/608ebccf8f6314c945444b400a37c2d07f21b253))

* `expand_hash_conditions_for_aggregates`を非推奨に指定（代替はなし）。
    ([Commit](https://github.com/rails/rails/commit/7ae26885d96daee3809d0bd50b1a440c2f5ffb69))

### 主な変更点

* 動的なフィクスチャアクセサメソッドを引数なしで呼び出した場合に、その種類のフィクスチャをすべて返すようになった。従来は常に空の配列を返していた。
    ([Pull Request](https://github.com/rails/rails/pull/28692))

* Active Recordの属性リーダーをオーバーライドした場合に属性の変更が一貫しなかったのを修正。
    ([Pull Request](https://github.com/rails/rails/pull/28661))

* MySQLの降順インデックスをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/28773))

* `bin/rails db:forward`の1回目のマイグレーションを修正。
    ([Commit](https://github.com/rails/rails/commit/b77d2aa0c336492ba33cbfade4964ba0eda3ef84))

* 現在のマイグレーションが存在しない場合にマイグレーション中に`UnknownMigrationVersionError`エラーをraiseするようになった。
    ([Commit](https://github.com/rails/rails/commit/bb9d6eb094f29bb94ef1f26aa44f145f17b973fe))

* データベース構造をダンプするrakeタスクで`SchemaDumper.ignore_tables`を考慮するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/29077))

* `ActiveSupport::Cache`で新しいバージョン付きエントリを介したキャッシュキーの再利用をサポートする`ActiveRecord::Base#cache_version`を追加。これによって、`ActiveRecord::Base#cache_key`がタイムスタンプを含まない安定したキーを返すようになった。
    ([Pull Request](https://github.com/rails/rails/pull/29092))

* キャストした値が`nil`の場合にバインドparamの作成を防止。
    ([Pull Request](https://github.com/rails/rails/pull/29282))

* フィクスチャの挿入に一括INSERTを用いてパフォーマンスを改善。
    ([Pull Request](https://github.com/rails/rails/pull/29504))

* ネストしたJOINを表す2つのリレーションをmergeした場合に、mergeされたリレーションのJOINをLEFT OUTER JOINに変換しなくなった。
    ([Pull Request](https://github.com/rails/rails/pull/27063))

* トランザクションのステートを子トランザクションに適用するよう修正。
    従来は、ネストしたトランザクションが1つあって外側のトランザクションがロールバックすると、内側のトランザクションのレコードがpersistedとマーキングされたままになることがあった。親トランザクションがロールバックした場合には親トランザクションのステートを子トランザクションに適用することで、この動作を修正した。これによって、内側のトランザクションのレコードが正しくマーキングされ、persistedにならなくなった。
    ([Commit](https://github.com/rails/rails/commit/0237da287eb4c507d10a0c6d94150093acc52b03))

* JOINを含むスコープを持つeager-load/preload関連付けを修正。
    ([Pull Request](https://github.com/rails/rails/pull/29413))

* `sql.active_record`通知サブスクライバによってraiseされるエラーを`ActiveRecord::StatementInvalid`例外に変換されないようにした。
    ([Pull Request](https://github.com/rails/rails/pull/29692))

* レコードを（`find_each`、`find_in_batches`、`in_batches`で）一括で扱う場合にクエリキャッシュをスキップするようにした。
    ([Commit](https://github.com/rails/rails/commit/b83852e6eed5789b23b13bac40228e87e8822b4d))

* sqlite3のbooleanシリアライズで`1`や`0`を利用するように変更。SQLiteはネイティブで`1`と`0`をそれぞれ`true`と`false`として認識するが、従来のシリアライズの`t`や`f`はネイティブでは認識しない。
    ([Pull Request](https://github.com/rails/rails/pull/29699))

* マルチパラメータ代入を用いて構成された値が、フィールドが1つのフォーム入力をレンダリングする場合にpost-type-cast値を使うようになった。
    ([Commit](https://github.com/rails/rails/commit/1519e976b224871c7f7dd476351930d5d0d7faf6))

* モデル生成時に`ApplicationRecord`を生成しないようになった。生成が必要な場合は`rails g application_record`で作成できる。
    ([Pull Request](https://github.com/rails/rails/pull/29916))

* `Relation#or`が、`references`の値のみ異なる2つのリレーションを受け取れるようになった。`references`は`where`によって暗黙に呼び出されることがあるため。
    ([Commit](https://github.com/rails/rails/commit/ea6139101ccaf8be03b536b1293a9f36bc12f2f7))

* `Relation#or`を使った場合に、共通の条件を抽出してOR条件の前に配置するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/29950))

* `binary`フィクスチャヘルパーメソッドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30073))

* STI（Single Table Inheritance）で関連付けの逆転を自動で推測するようにした。
    ([Pull Request](https://github.com/rails/rails/pull/23425))

* ロック待ちタイムアウト設定を超えた場合にraiseされるエラークラス`LockWaitTimeout`を新しく追加。
    ([Pull Request](https://github.com/rails/rails/pull/30360))

* `sql.active_record` instrumentationのペイロード名をわかりやすく変更。
    ([Pull Request](https://github.com/rails/rails/pull/30619))

* データベースからのインデックス削除でアルゴリズムを指定できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/24199))

* `Relation#where`に`Set`を渡した場合の挙動を、配列を渡した場合と同じにした。
    ([Commit](https://github.com/rails/rails/commit/9cf7e3494f5bd34f1382c1ff4ea3d811a4972ae2))

* PostgreSQLの`tsrange`で秒以下の精度が保持されるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30725))

* ダーティなレコードで`lock!`を呼ぶとraiseするようになった。
    ([Commit](https://github.com/rails/rails/commit/63cf15877bae859ff7b4ebaf05186f3ca79c1863))

* sqliteアダプタ利用時にインデックスのカラム順が`db/schema.rb`に記載されないバグを修正。
    ([Pull Request](https://github.com/rails/rails/pull/30970))

* `bin/rails db:migrate`で`VERSION`を指定した場合の動作を修正。VERSIONが空の`bin/rails db:migrate`の振る舞いは、`VERSION`を指定していない場合の動作と同じになった。
    `VERSION`の形式をチェックし、マイグレーションファイルのバージョン番号または名前であればそれを利用する。`VERSION`の形式が無効な場合はエラーをraiseする。対象となるマイグレーションが存在しない場合もエラーをraiseする。
    ([Pull Request](https://github.com/rails/rails/pull/30714))

* ステートメントタイムアウト設定を超えた場合にraiseされるエラークラス`StatementTimeout`を新しく追加。
    ([Pull Request](https://github.com/rails/rails/pull/31129))

* `update_all`で、値を`Type#serialize`に渡す前に`Type#cast`に渡すようにした。これにより、`update_all(foo: 'true')`でbooleanが正しく永続化するようになった。
    ([Commit](https://github.com/rails/rails/commit/68fe6b08ee72cc47263e0d2c9ff07f75c4b42761))

* リレーションクエリメソッドで生SQLフラグメントを使う場合は、そのことを明示的にマーキングしなければならないようになった。
    ([Commit](https://github.com/rails/rails/commit/a1ee43d2170dd6adf5a9f390df2b1dde45018a48),
    [Commit](https://github.com/rails/rails/commit/e4a921a75f8702a7dbaf41e31130fe884dea93f9))

* 「up」マイグレーション（新しいカラムの追加など）にのみ関係あるコード用の`#up_only`をデータベースマイグレーションに追加。
    ([Pull Request](https://github.com/rails/rails/pull/31082))

* ユーザーのリクエストが原因でステートメントをキャンセルした場合にraiseされるエラークラス`QueryCanceled `を新しく追加。
    ([Pull Request](https://github.com/rails/rails/pull/31235))

* `Relation`のインスタンスメソッドと衝突するスコープ定義を許さないようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31179))

* `add_index`にPostgreSQL演算子クラスのサポートを追加。
    ([Pull Request](https://github.com/rails/rails/pull/19090))

* データベースクエリ呼び出し元のログを出力できるようにした。
    ([Pull Request](https://github.com/rails/rails/pull/26815),
    [Pull Request](https://github.com/rails/rails/pull/31519),
    [Pull Request](https://github.com/rails/rails/pull/31690))

* カラム情報をリセットした場合に子孫クラスで属性メソッドをundefineするようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31475))

* `delete_all`で`limit`や`offset`を指定した場合にsubselectを使うようにした。
    ([Commit](https://github.com/rails/rails/commit/9e7260da1bdc0770cf4ac547120c85ab93ff3d48))

* `first(n)`を`limit()`と併用した場合の矛盾を修正。
    `first(n)`ファインダーが`limit()`を考慮するようになったことで`relation.to_a.first(n)`（と`last(n)`の場合も）の挙動が一貫するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/27597))

* 永続化していない親インスタンス上のネストした`has_many :through`関連付けを修正。
    ([Commit](https://github.com/rails/rails/commit/027f865fc8b262d9ba3ee51da3483e94a5489b66))

* レコードを通しで削除する場合に関連付けの条件を考慮するようにした。
    ([Commit](https://github.com/rails/rails/commit/ae48c65e411e01c1045056562319666384bb1b63))

* `save`や`save!`の呼び出し後はdestroyされたオブジェクトの改変を禁止。
    ([Commit](https://github.com/rails/rails/commit/562dd0494a90d9d47849f052e8913f0050f3e494))

* `left_outer_joins`でリレーションをmergeした場合の問題を修正。
    ([Pull Request](https://github.com/rails/rails/pull/27860))

* PostgreSQLの外部テーブルをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/31549))

* Active Recordオブジェクトが複製された場合はトランザクションのステートをクリアするようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31751))

* `composed_of`カラムを用いた`where`メソッドに配列オブジェクトを引数として渡した場合に展開されない問題を修正。
    ([Pull Request](https://github.com/rails/rails/pull/31724))

* 誤用を防ぐため`polymorphic?`の場合に`reflection.klass`でraiseするようになった。
    ([Commit](https://github.com/rails/rails/commit/63fc1100ce054e3e11c04a547cdb9387cd79571a))

* `ORDER BY`カラムに他のテーブルの主キーが含まれている場合であっても`ActiveRecord::FinderMethods#limited_ids_for`で正しい主キー値が使われるよう、MySQLとPostgreSQLの`#columns_for_distinct`を修正。
    ([Commit](https://github.com/rails/rails/commit/851618c15750979a75635530200665b543561a44))

* `dependent: :destroy`で、`has_one`/`belongs_to`リレーションシップの子クラスが削除されていないのに親クラスが削除される問題を修正。
    ([Commit](https://github.com/rails/rails/commit/b0fc04aa3af338d5a90608bf37248668d59fc881))

* アイドル状態のデータベース接続は従来孤立した接続だったのが、コネクションプールreaperによって定期的に刈り取られるようになった。
    [Commit](https://github.com/rails/rails/pull/31221/commits/9027fafff6da932e6e64ddb828665f4b01fc8902)

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 主な変更点

* `ActiveModel::Errors`の`#keys`メソッドと`#values`メソッドを修正。
    `#keys`はメッセージが空でないキーだけを返すように変更。
    `#values`は空でない値だけを返すように変更。
    ([Pull Request](https://github.com/rails/rails/pull/28584))

* `#merge!`メソッドを追加（`ActiveModel::Errors`向け）。
    ([Pull Request](https://github.com/rails/rails/pull/29714))

* `length`バリデータオプションにProcやシンボルを渡せるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30674))

* `_confirmation`の値が`false`の場合に`ConfirmationValidator`バリデーションを実行するようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31058))

* procデフォルトを含むattrebutes APIを用いるモデルをマーシャリングできるようになった。
    ([Commit](https://github.com/rails/rails/commit/0af36c62a5710e023402e37b019ad9982e69de4b))

* シリアライズで`:includes`オプションを複数指定しても失われないようにした。
    ([Commit](https://github.com/rails/rails/commit/853054bcc7a043eea78c97e7705a46abb603cc44))

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

* コールバックにおける非推奨の`:if`/`:unless`文字列フィルタを削除。
    ([Commit](https://github.com/rails/rails/commit/c792354adcbf8c966f274915c605c6713b840548))

* 非推奨の`halt_callback_chains_on_return_false`オプションを削除。
    ([Commit](https://github.com/rails/rails/commit/19fbbebb1665e482d76cae30166b46e74ceafe29))

### 非推奨

*   `Module#reachable?`メソッドを非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/30624))

*   `secrets.secret_token`を非推奨に指定。
    ([Commit](https://github.com/rails/rails/commit/fbcc4bfe9a211e219da5d0bb01d894fcdaef0a0e))

### 主な変更

* `fetch_values`を`HashWithIndifferentAccess`に追加。
    ([Pull Request](https://github.com/rails/rails/pull/28316))

* `Time#change`に`:offset`のサポートを追加。
    ([Commit](https://github.com/rails/rails/commit/851b7f866e13518d900407c78dcd6eb477afad06))

* `ActiveSupport::TimeWithZone#change`に`:offset`と`:zone`のサポートを追加。
    ([Commit](https://github.com/rails/rails/commit/851b7f866e13518d900407c78dcd6eb477afad06))

* 非推奨通知にgem名と非推奨の期間（horizon）を渡すようにした。
    ([Pull Request](https://github.com/rails/rails/pull/28800))

* バージョン付きキャッシュエントリをサポート。これによりキャッシュストアでキャッシュキーを再利用できるようになり、キャッシュの変動が著しい場合にストレージを大きく節約できるようになった。Active Recordで`#cache_key`と`#cache_version`を分離し、Action Packのフラグメントキャッシュを利用することで動作する。
    ([Pull Request](https://github.com/rails/rails/pull/29092))

* スレッド分離された属性シングルトンを提供する`ActiveSupport::CurrentAttributes`を追加。主なユースケースは、リクエストごとの属性をシステム全体で簡単に利用できるよう保持することである。
    ([Pull Request](https://github.com/rails/rails/pull/29180))

* `#singularize`と`#pluralize`が指定のロケールで非可算名詞を考慮するようになった。
    ([Commit](https://github.com/rails/rails/commit/352865d0f835c24daa9a2e9863dcc9dde9e5371a))

* `class_attribute`にデフォルトオプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/29270))

* 曜日を指定すると（現時点から見て）「前回その曜日だった日時」と「次回その曜日になる日時」を返す`Date#prev_occurring`と`Date#next_occurring`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/26600))

* モジュールやクラスの属性アクセサにデフォルトオプションを追加。
    ([Pull Request](https://github.com/rails/rails/pull/29294))

*   Cacheに`write_multi`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/29366))

*   `ActiveSupport::MessageEncryptor`でAES 256 GCMをデフォルトで利用。
    ([Pull Request](https://github.com/rails/rails/pull/29263))

* テスト時の`Time.now`の時間をfreezeする`freeze_time`ヘルパーを追加。
    ([Pull Request](https://github.com/rails/rails/pull/29681))

* `Hash#reverse_merge!`の順序を`HashWithIndifferentAccess`と一貫するようにした。
    ([Pull Request](https://github.com/rails/rails/pull/28077))

* `ActiveSupport::MessageVerifier`と`ActiveSupport::MessageEncryptor`で`purpose:`や期限指定をサポート。
    `ActiveSupport::MessageEncryptor`.
    ([Pull Request](https://github.com/rails/rails/pull/29892))

* `String#camelize`に誤ったオプションが渡されたときにフィードバックを返すようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30039))

* `Module#delegate_missing_to`で対象が`nil`の場合に`DelegationError`をraiseするようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30191))

*   `ActiveSupport::EncryptedFile`と`ActiveSupport::EncryptedConfiguration`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/30067))

*   productionアプリケーションの秘密情報を保存する`config/credentials.yml.enc`を追加。
    ([Pull Request](https://github.com/rails/rails/pull/30067))

* `MessageEncryptor`と`MessageVerifier`でキーのローテーションをサポート。
    ([Pull Request](https://github.com/rails/rails/pull/29716))

* `HashWithIndifferentAccess#transform_keys` が `HashWithIndifferentAccess` のインスタンスを返すようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30728))

* `Hash#slice`がRuby 2.5以降の組み込み定義にフォールバックするようになった（定義済みの場合）。
    ([Commit](https://github.com/rails/rails/commit/01ae39660243bc5f0a986e20f9c9bff312b1b5f8))

* `IO#to_json`が配列への変換を試みずに`to_s`表現を返すようになった。読み取り不能オブジェクトで`IO#to_json`を呼ぶと`IOError`がraiseされるバグがこれで修正される。
    ([Pull Request](https://github.com/rails/rails/pull/30953))

* `Date#prev_day`や`Date#next_day`に合わせて`Time#prev_day`と`Time#next_day`にも同じメソッドシグネチャを追加。
    `Time#prev_day`と`Time#next_day`に引数を渡せるようになった。
    ([Commit](https://github.com/rails/rails/commit/61ac2167eff741bffb44aec231f4ea13d004134e))

* `Date#prev_month`や`Date#next_month`に合わせて`Time#prev_month`と`Time#next_month`にも同じメソッドシグネチャを追加。
    `Time#prev_month`と`Time#next_month`に引数を渡せるようになった。
    ([Commit](https://github.com/rails/rails/commit/f2c1e3a793570584d9708aaee387214bc3543530))

* `Date#prev_year`や`Date#next_year`に合わせて`Time#prev_year`と`Time#next_year`にも同じメソッドシグネチャを追加。
    `Time#prev_year`と`Time#next_year`に引数を渡せるようになった。
    ([Commit](https://github.com/rails/rails/commit/ee9d81837b5eba9d5ec869ae7601d7ffce763e3e))

* `humanize`で略語をサポート。
    ([Commit](https://github.com/rails/rails/commit/0ddde0a8fca6a0ca3158e3329713959acd65605d))

* TimeWithZone（TWZ）のレンジで`Range#include?`をサポート。
    ([Pull Request](https://github.com/rails/rails/pull/31081))

* 1KBを超えるキャッシュをデフォルトで圧縮できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31147))

* Redisキャッシュストア。
    ([Pull Request](https://github.com/rails/rails/pull/31134),
    [Pull Request](https://github.com/rails/rails/pull/31866))

* `TZInfo::AmbiguousTime`エラーを扱えるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31128))

* MemCacheStore: 期限切れカウンタをサポート。
    ([Commit](https://github.com/rails/rails/commit/b22ee64b5b30c6d5039c292235e10b24b1057f6d))

* `ActiveSupport::TimeZone.all`が`ActiveSupport::TimeZone::MAPPING`に含まれるタイムゾーンだけを返すようにした。
    ([Pull Request](https://github.com/rails/rails/pull/31176))

* `ActiveSupport::SecurityUtils.secure_compare`のデフォルトの振る舞いを変更し、変数の長さの文字列についても長さ情報が漏洩しないようにした。
    `ActiveSupport::SecurityUtils.secure_compare`が`fixed_length_secure_compare`にリネームされ、渡された文字列の長さが一致しない場合に`ArgumentError`をraiseするようになった。
    ([Pull Request](https://github.com/rails/rails/pull/24510))

* SHA-1はETagヘッダーなどの重要度の低いダイジェストの生成に使うようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31289),
    [Pull Request](https://github.com/rails/rails/pull/31651))

* `assert_changes`によるアサーションが、引数の`from:`と`to:`の組み合わせにかかわらず常に式の変更をアサーションするようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31011))

* `ActiveSupport::Cache::Store`の`read_multi`になかったinstrumentationを追加。
    ([Pull Request](https://github.com/rails/rails/pull/30268))

* `assert_difference`の最初の引数でハッシュをサポート。これにより、同一のアサーションでさまざまな数値の違いを指定できるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/31600))

* キャッシュ: MemCacheやRedis の`read_multi`と`fetch_multi`を高速化。バックエンドに問い合わせる前にローカルのインメモリキャッシュから読み取るようになった。
    ([Commit](https://github.com/rails/rails/commit/a2b97e4ffef971607a1be8fc7909f099b6840f36))

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 主な変更点

* `ActiveJob::Base.discard_on`にブロックを渡すことで、ジョブの破棄をカスタマイズできるようになった。
    ([Pull Request](https://github.com/rails/rails/pull/30622))

Ruby on Railsガイド
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更点

* [Railsのスレッディングとコード実行](threading_and_code_execution.html)ガイドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/27494))

* [Active Storageの概要](active_storage_overview.html)ガイドを追加。
    ([Pull Request](https://github.com/rails/rails/pull/31037))

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/5-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/5-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/5-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/5-2-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/5-2-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/5-2-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/5-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/5-2-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/5-2-stable/activejob/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/5-2-stable/guides/CHANGELOG.md
