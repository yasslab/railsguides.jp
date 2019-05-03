Ruby on Rails 6.0 リリースノート
===============================

Rails 6.0の注目ポイント:

* Action Mailbox
* Action Text
* 並列テスト
* Action Cableのテスト支援

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[list of
commits](https://github.com/rails/rails/commits/6-0-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 6.0へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 5.2までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 6.0にアップデートしてください。アップグレードの注意点などについては[Ruby on Rails](upgrading_ruby_on_rails.html#rails-5-2からrails-6-0へのアップグレード)アップグレードガイドを参照してください。

主要な機能
--------------

### Action Mailbox

[Pull Request](https://github.com/rails/rails/pull/34786)

[Action Mailbox](https://github.com/rails/rails/tree/6-0-stable/actionmailbox)は、受信メールをコントローラ的なメールボックスにルーティングできます。Action Mailboxについて詳しくは、[Action Mailbox Basics](action_mailbox_basics.html)ガイドを参照してください。

### Action Text

[Pull Request](https://github.com/rails/rails/pull/34873)

[Action Text](https://github.com/rails/rails/tree/6-0-stable/actiontext)は、リッチテキストコンテンツと編集機能をRailsで使えるようにします。[Trixエディタ](https://trix-editor.org)は、リンク/引用/リスト/画像埋め込み/ギャラリー【原文怪しい】などあらゆるものを扱えます。Trixエディタで生成されるリッチテキストコンテンツは独自のRichTextモデルに保存され、アプリ内にある既存のActive Recordモデルに関連付けられます。
埋め込み画像などの添付ファイルは自動的にActive Storageを用いて保存され、RichTextモデルに関連付けられます。

Action Textについて詳しくはガイドの[Action Text の概要](action_text_overview.html)を参照してください。

### 並列テスト

[Pull Request](https://github.com/rails/rails/pull/31900)

[並列テスト](testing.html#並列テスト)（parallel testing）機能によってテストスイートを並列化できます。デフォルトではプロセスをforkしますが、スレッド（threading）もサポートされます。テストを並列実行することで、テストスイート全体の実行時間を削減できます。

### Action Cableのテスト支援

[Pull Request](https://github.com/rails/rails/pull/33659)

[Action Cableテストツール](testing.html#testing-action-cable)を用いて、Action Cableの機能を任意のレベル（接続レベル/チャネルレベル/ブロードキャストレベル）でテストできます。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください

### 削除されたもの

*   プラグインテンプレートの非推奨化`after_bundle`ヘルパーを削除
    ([Commit](https://github.com/rails/rails/commit/4d51efe24e461a2a3ed562787308484cd48370c7))

*   `config.ru`でアプリケーションクラスを`run`の引数として用いる非推奨サポートを削除
    ([Commit](https://github.com/rails/rails/commit/553b86fc751c751db504bcbe2d033eb2bb5b6a0b))

*   `rails`コマンドから非推奨`environment`引数を削除
    ([Commit](https://github.com/rails/rails/commit/e20589c9be09c7272d73492d4b0f7b24e5595571))

*   ジェネレータとテンプレートから非推奨の`capify!`メソッドを削除
    ([Commit](https://github.com/rails/rails/commit/9d39f81d512e0d16a27e2e864ea2dd0e8dc41b17))

*   非推奨の`config.secret_token`設定を削除
    ([Commit](https://github.com/rails/rails/commit/46ac5fe69a20d4539a15929fe48293e1809a26b0))

### 非推奨化

*   Rackサーバー名を正規の引数として`rails server`に渡すことを非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/32058))

*   サーバーIPの指定に`HOST`環境変数を使えるようにするサポートを非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/32540))

*   `config_for`から返されるハッシュにシンボルでないキーでアクセスすることを非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/35198))

### 主な変更

*   `rails server`コマンドでサーバーを指定する明示的な`--using`（または`-u`）オプションを追加
    ([Pull Request](https://github.com/rails/rails/pull/32058))

*   `rails routes`出力を拡張フォーマットで表示できる機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/32130))

*   インラインのActive Jobアダプタを用いてデータベースseedタスクを実行
    ([Pull Request](https://github.com/rails/rails/pull/34953))

*   アプリケーションのデータベースを切り替える`rails db:system:change`コマンドを追加
    ([Pull Request](https://github.com/rails/rails/pull/34832))

*   Action Cableチャネルだけをテストする`rails test:channels`コマンドを追加
    ([Pull Request](https://github.com/rails/rails/pull/34947))

*   DNSリバインディング攻撃からの保護を導入
    ([Pull Request](https://github.com/rails/rails/pull/33145))

*   ジェネレータコマンド実行中の失敗をabortする機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/34420))

*   WebpackerがRails 6のデフォルトJavaScriptコンパイラになる
    ([Pull Request](https://github.com/rails/rails/pull/33079))

*   `rails db:migrate:status`コマンドでマルチデータベースをサポート
    ([Pull Request](https://github.com/rails/rails/pull/34137))

*   ジェネレータでマルチデータベースごとに異なるパスを利用する機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/34021))

*   credentialを複数の環境でサポート
    ([Pull Request](https://github.com/rails/rails/pull/33521))

*   `null_store`がtest環境のデフォルトキャッシュになる
    ([Pull Request](https://github.com/rails/rails/pull/33773))

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

* Action CableのJavaScriptパッケージがCoffeeScriptからES2015に変換され、ソースコードがnpmディストリビューションでパブリッシュされるようになりました。

    これによって、Action Cableのユーザーがコンパイル済みコードではなくJavaScriptソースコードを当てにできるようになり、JavaScriptバンドルのサイズが小さくなります。

    この変更に伴い、Action CableのJavaScript APIの一部のオプションで以下のようなbreaking changes（互換性のない変更）が発生します。

    - WebSockeアダプタやloggerアダプタの設定が、`ActionCable`のプロパティから`ActionCable.adapters`のプロパティに移動しました。

    - `ActionCable.startDebugging()`メソッドと`ActionCable.stopDebugging()`メソッドが削除され、`ActionCable.logger.enabled`のプロパティに置き換わりました。


Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   非推奨化された`fragment_cache_key`ヘルパーを削除、今後は`combined_fragment_cache_key`を用いる
    ([Commit](https://github.com/rails/rails/commit/e70d3df7c9b05c129b0fdcca57f66eca316c5cfc))

*   `ActionDispatch::TestResponse`から非推奨化された次のメソッドを削除: `#success?`（今後は`#successful?`を使う）、`#missing?`（今後は`#not_found?`を使う）、`#error?`（今後は`#server_error?`を使う）
    ([Commit](https://github.com/rails/rails/commit/13ddc92e079e59a0b894e31bf5bb4fdecbd235d1))

### 非推奨化

*   `ActionDispatch::Http::ParameterFilter`を非推奨化、今後は`ActiveSupport::ParameterFilter`を用いる
    ([Pull Request](https://github.com/rails/rails/pull/34039))

*   コントローラレベルの`force_ssl`を非推奨化、今後は`config.force_ssl`を用いる
    ([Pull Request](https://github.com/rails/rails/pull/32277))

### 主な変更

*   リソースparamにコロンが含まれている場合は`ArgumentError`をraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/35236))

*   `ActionDispatch::SystemTestCase.driven_by`をブロック付きで呼ぶことで特定のブラウザの機能を定義できるようになった
    ([Pull Request](https://github.com/rails/rails/pull/35081))

*   `ActionDispatch::HostAuthorization`ミドルウェアを追加（DNSリバインディング攻撃から保護する）
    ([Pull Request](https://github.com/rails/rails/pull/33145))

*   `parsed_body`を`ActionController::TestCase`内で利用できるようになった
    ([Pull Request](https://github.com/rails/rails/pull/34717))

*   複数のルートルーティングが同じコンテキストに存在し、`as:`による命名仕様がない場合は`ArgumentError`をraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/34494))

*   パラメータのパースエラーを`#rescue_from`で扱えるようになった
    ([Pull Request](https://github.com/rails/rails/pull/34341))

*   `ActionController::Parameters#each_value`を追加（パラメータの列挙用）
    ([Pull Request](https://github.com/rails/rails/pull/33979))

*   `send_data`や`send_file`でContent-Dispositionファイル名をエンコードするようになった
    ([Pull Request](https://github.com/rails/rails/pull/33829))

*   `ActionController::Parameters#each_key`が公開された
    ([Pull Request](https://github.com/rails/rails/pull/33758))

*   purposeメタデータを署名済み/暗号化済みcookieに追加（cookie値を別のcookieにコピーされないようにする）
    ([Pull Request](https://github.com/rails/rails/pull/32937))

*   `respond_to`呼び出しが衝突した場合に`ActionController::RespondToMismatchError`をraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/33446))

*   リクエストフォーマットでテンプレートが見つからない場合に使う明示的なエラーページを追加
    ([Pull Request](https://github.com/rails/rails/pull/29286))

*   `ActionDispatch::DebugExceptions.register_interceptor`を導入した（レンダリング開始前にDebugExceptionsにフックして例外を処理する手段のひとつ）
    ([Pull Request](https://github.com/rails/rails/pull/23868))

*   1リクエストに付きContent-Security-Policy（CSP）nonceヘッダー値を1つしか出力しないようになった
    ([Pull Request](https://github.com/rails/rails/pull/32602))

*   Railsのコントローラで明示的にincludeできるデフォルトのヘッダー設定で主に用いられるモジュールを追加
    ([Pull Request](https://github.com/rails/rails/pull/32484))

*   `#dig`を`ActionDispatch::Request::Session`に追加
    ([Pull Request](https://github.com/rails/rails/pull/32446))

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

*   非推奨の`#set_state`をトランザクションオブジェクトから削除
    ([Commit](https://github.com/rails/rails/commit/6c745b0c5152a4437163a67707e02f4464493983))

*   非推奨の`#supports_statement_cache?`をデータベースアダプタから削除
    ([Commit](https://github.com/rails/rails/commit/5f3ed8784383fb4eb0f9959f31a9c28a991b7553))

*   非推奨の`#insert_fixtures`をデータベースアダプタから削除
    ([Commit](https://github.com/rails/rails/commit/400ba786e1d154448235f5f90183e48a1043eece))

*   非推奨の`ActiveRecord::ConnectionAdapters::SQLite3Adapter#valid_alter_table_type?`を削除
    ([Commit](https://github.com/rails/rails/commit/45b4d5f81f0c0ca72c18d0dea4a3a7b2ecc589bf))

*   ブロックが1つ渡されたときにカラム名を`sum`に渡すサポートを廃止
    ([Commit](https://github.com/rails/rails/commit/91ddb30083430622188d76eb9f29b78131df67f9))

*   ブロックが1つ渡されたときにカラム名を`count`に渡すサポートを廃止
    ([Commit](https://github.com/rails/rails/commit/67356f2034ab41305af7218f7c8b2fee2d614129))

*   arelへのリレーション内で「missing」メソッドの委譲サポートを廃止
    ([Commit](https://github.com/rails/rails/commit/d97980a16d76ad190042b4d8578109714e9c53d0))

*   クラスのprivateメソッドへのリレーション内で「missing」メソッドの委譲サポートを廃止
    ([Commit](https://github.com/rails/rails/commit/a7becf147afc85c354e5cfa519911a948d25fc4d))

*   `#cache_key`のタイムスタンプ名指定のサポートを廃止
    ([Commit](https://github.com/rails/rails/commit/0bef23e630f62e38f20b5ae1d1d5dbfb087050ea))

*   非推奨の`ActiveRecord::Migrator.migrations_path=`を削除
    ([Commit](https://github.com/rails/rails/commit/90d7842186591cae364fab3320b524e4d31a7d7d))

*   非推奨の`expand_hash_conditions_for_aggregates`を削除
    ([Commit](https://github.com/rails/rails/commit/27b252d6a85e300c7236d034d55ec8e44f57a83e))


### 非推奨化

*   uniquenessバリデータで、大文字小文字が一致しない照合順序（collation）比較を非推奨化
    ([Commit](https://github.com/rails/rails/commit/9def05385f1cfa41924bb93daa187615e88c95b9))

*   レシーバのスコープが漏洩している場合のクラスレベルのクエリ送信メソッドを非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/35280))

*   `config.activerecord.sqlite3.represent_boolean_as_integer`を非推奨化
    ([Commit](https://github.com/rails/rails/commit/f59b08119bc0c01a00561d38279b124abc82561b))

*   `migrations_paths`を`connection.assume_migrated_upto_version`に渡すことを非推奨化
    ([Commit](https://github.com/rails/rails/commit/c1b14aded27e063ead32fa911aa53163d7cfc21a))

*   `ActiveRecord::Result#to_hash`を非推奨化、今後は`ActiveRecord::Result#to_a`を用いる
    ([Commit](https://github.com/rails/rails/commit/16510d609c601aa7d466809f3073ec3313e08937))

*   `DatabaseLimits`の以下のメソッドを非推奨化: `column_name_length`、`table_name_length`、`columns_per_table`、`indexes_per_table`、`columns_per_multicolumn_index`、`sql_query_length`、`joins_per_query`
    ([Commit](https://github.com/rails/rails/commit/e0a1235f7df0fa193c7e299a5adee88db246b44f))

*   `update_attributes`/`!`を非推奨化、今後は`update`/`!`を用いる
    ([Commit](https://github.com/rails/rails/commit/5645149d3a27054450bd1130ff5715504638a5f5))

### 主な変更

*   SQLite3の最小バージョンを1.4に上げる
    ([Pull Request](https://github.com/rails/rails/pull/35844))

*   `rails db:prepare`を追加: データベースが存在しない場合は作成してからマイグレーションを実行する
    ([Pull Request](https://github.com/rails/rails/pull/35768))

*   `after_save_commit`コールバックを追加（`after_commit :hook, on: [ :create, :update ]`のショートカット）
    ([Pull Request](https://github.com/rails/rails/pull/35804))

*   `ActiveRecord::Relation#extract_associated`を追加: 関連付けられたレコードをリレーションから切り出す
    ([Pull Request](https://github.com/rails/rails/pull/35784))

*   `ActiveRecord::Relation#annotate`を追加: `ActiveRecord::Relation`クエリにSQLコメントを追加する
    ([Pull Request](https://github.com/rails/rails/pull/35617))

*   データベースにOptimizer Hintsを設定するサポートを追加
    ([Pull Request](https://github.com/rails/rails/pull/35615))

*   一括INSERTを行う`insert_all`/`insert_all!`/`upsert_all`メソッドを追加
    ([Pull Request](https://github.com/rails/rails/pull/35631))

*   `rails db:seed:replant`を追加: 現在の環境で各データベースのテーブルをTRUNCATEしてseedを読み込む
    ([Pull Request](https://github.com/rails/rails/pull/34779))

*   `reselect`メソッドを追加（`unscope(:select).select(fields)`のショートハンド）
    ([Pull Request](https://github.com/rails/rails/pull/33611))

*   すべてのenum値についてネガティブスコープを追加
    ([Pull Request](https://github.com/rails/rails/pull/35381))

*   `#destroy_by`と`#delete_by`を追加: 条件付き削除を実行
    ([Pull Request](https://github.com/rails/rails/pull/35316))

*   データベース接続を自動的に切り替える機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/35073))

*   1つのブロック内でデータベースへの書き込みを防ぐ機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/34505))

*   接続切り替え用APIを追加（マルチデータベースサポート用）
    ([Pull Request](https://github.com/rails/rails/pull/34052))

*   マイグレーションのタイムスタンプにデフォルトで`precision: 6`を指定
    ([Pull Request](https://github.com/rails/rails/pull/34970))

*   MySQLでテキストやblobのサイズを変更する`:size`オプションを追加
    ([Pull Request](https://github.com/rails/rails/pull/35071))

*   `dependent: :nullify`ストラテジーのポリモーフィック関連付けで外部キーと外部typeカラムを両方ともNULLに設定
    ([Pull Request](https://github.com/rails/rails/pull/28078))

*   `ActionController::Parameters`の許可されたインスタンスを`ActiveRecord::Relation#exists?`の引数として渡せるようになった
    ([Pull Request](https://github.com/rails/rails/pull/34891))

*   Ruby 2.6で導入されたエンドレスrangeを`#where`でサポート
    ([Pull Request](https://github.com/rails/rails/pull/34906))

*   MySQLのテーブル作成オプションで`ROW_FORMAT=DYNAMIC`をデフォルトで設定
    ([Pull Request](https://github.com/rails/rails/pull/34742))

*   `ActiveRecord.enum`で生成されたスコープを無効にする機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/34605/files))

*   カラムの暗黙のORDERが設定可能になった
    ([Pull Request](https://github.com/rails/rails/pull/34480))

*   PostgreSQLの最小バージョンが9.3になり、9.1や9.2のサポートを廃止
    ([Pull Request](https://github.com/rails/rails/pull/34520))

*   enumの値がfrozenになり、変更しようとするとエラーがraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/34517))

*   `ActiveRecord::StatementInvalid`エラーのSQLがerrorプロパティになり、SQLバインドを独立したerrorプロパティとして含まれるようになった
    ([Pull Request](https://github.com/rails/rails/pull/34468))

*   `:if_not_exists`オプションを`create_table`に追加
    ([Pull Request](https://github.com/rails/rails/pull/31382))

*   `rails db:schema:cache:dump`や`rails db:schema:cache:clear`にマルチデータベースのサポートを追加
    and `rails db:schema:cache:clear`.
    ([Pull Request](https://github.com/rails/rails/pull/34181))

*   `ActiveRecord::Base.connected_to`のデータベースハッシュでハッシュやURLの設定をサポート
    ([Pull Request](https://github.com/rails/rails/pull/34196))

*   MySQLでデフォルト式や式インデックスをサポート
    ([Pull Request](https://github.com/rails/rails/pull/34307))

*   `change_table`マイグレーションヘルパーに`index`オプションを追加
    ([Pull Request](https://github.com/rails/rails/pull/23593))

*   マイグレーションでの`transaction`のrevertを修正（従来の`transaction`内のコマンドが修正された）
    ([Pull Request](https://github.com/rails/rails/pull/31604))

*   `ActiveRecord::Base.configurations=`がシンボルのハッシュで設定されるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33968))

*   レコードが実際に保存された場合にのみカウンタキャッシュが更新されるよう修正
    ([Pull Request](https://github.com/rails/rails/pull/33913))

*   SQLiteアダプタで式インデックスをサポート
    ([Pull Request](https://github.com/rails/rails/pull/33874))

*   関連付けられたレコードのautosaveコールバックをサブクラスで再定義できるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33378))

*   MySQLの最小バージョンが5.5.8に上がった
    ([Pull Request](https://github.com/rails/rails/pull/33853))

*   MySQLでデフォルトでutf8mb4文字セットが使われるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33608))

*   `#inspect`の個人情報データをフィルタで除外する機能を追加
    ([Pull Request](https://github.com/rails/rails/pull/33756), [Pull Request](https://github.com/rails/rails/pull/34208))

*   `ActiveRecord::Base.configurations`の戻り値をハッシュからオブジェクトに変更
    ([Pull Request](https://github.com/rails/rails/pull/33637))

*   データベース設定にアドバイザリーロック（勧告ロック）を無効にする設定を追加
    ([Pull Request](https://github.com/rails/rails/pull/33691))

*   SQLite3アダプタの`alter_table`メソッドを更新し、外部キーをリストアするようになった
    ([Pull Request](https://github.com/rails/rails/pull/33585))

*   `remove_foreign_key`の`:to_table`オプションをロールバックできるようにした
    ([Pull Request](https://github.com/rails/rails/pull/33530))

*   MySQLのtime型でprecisionが指定されている場合のデフォルト値を修正
    ([Pull Request](https://github.com/rails/rails/pull/33280))

*   `touch`オプションの挙動を`Persistence#touch`の挙動に合わせて修正
    ([Pull Request](https://github.com/rails/rails/pull/33107))

*   マイグレーションでカラム定義が重複した場合に例外をraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/33029))

*   SQLiteの最小バージョンが3.8に上がった
    ([Pull Request](https://github.com/rails/rails/pull/32923))

*   子レコードが重複している場合に親レコードが保存されない問題を修正
    ([Pull Request](https://github.com/rails/rails/pull/32952))

*   `Associations::CollectionAssociation#size`や `Associations::CollectionAssociation#empty?`で読み込み済みの関連idが存在する場合はそれを使うようになった
    ([Pull Request](https://github.com/rails/rails/pull/32617))

*   リクエストされた関連付けが一部のレコードにない場合にポリモーフィック関連付けをプリロードするサポートを追加
    ([Commit](https://github.com/rails/rails/commit/75ef18c67c29b1b51314b6c8a963cee53394080b))

*   `touch_all`メソッドを`ActiveRecord::Relation`に追加
    ([Pull Request](https://github.com/rails/rails/pull/31513))

*   `ActiveRecord::Base.base_class?`述語メソッドを追加
    ([Pull Request](https://github.com/rails/rails/pull/32417))

*   `ActiveRecord::Store.store_accessor`にカスタムprefix/suffixオプションを追加
    ([Pull Request](https://github.com/rails/rails/pull/32306))

*   `ActiveRecord::Base.create_or_find_by`/`!`を追加: データベースのunique制限に依存する形で`ActiveRecord::Base.find_or_create_by`/`!`でSELECTやINSERTの競合を扱う
    ([Pull Request](https://github.com/rails/rails/pull/31989))

*   `Relation#pick`を追加（`pluck`で単独の値を取るショートハンド）
    ([Pull Request](https://github.com/rails/rails/pull/31941))

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

*   アタッチされるモデルを`update`や`update!`で更新すると（例: `@user.update!(images: [ … ])`）、単に追加するのではなく既存の画像を置き換えるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33303))

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

*   `ActiveModel::Errors#full_message`のフォーマットをカスタマイズする設定オプションを追加
    ([Pull Request](https://github.com/rails/rails/pull/32956))

*   `has_secure_password`の属性名を設定するサポートを追加
    ([Pull Request](https://github.com/rails/rails/pull/26764))

*   `#slice!`メソッドを`ActiveModel::Errors`に追加
    ([Pull Request](https://github.com/rails/rails/pull/34489))

*   `ActiveModel::Errors#of_kind?`を追加: 特定のエラーが存在するかどうかをチェックする
    ([Pull Request](https://github.com/rails/rails/pull/34866))

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   Qu gemのサポートを削除
    ([Pull Request](https://github.com/rails/rails/pull/32300))

### 非推奨化

### 主な変更

*   Active Jobの引数にカスタムシリアライザのサポートを追加
    ([Pull Request](https://github.com/rails/rails/pull/30941))

*   キューが送信されたタイムゾーンでActive Jobを実行するサポートを追加
    they were enqueued.
    ([Pull Request](https://github.com/rails/rails/pull/32085))

*   `retry_on`や`discard_on`に複数の例外を渡せるようになった
    ([Commit](https://github.com/rails/rails/commit/3110caecbebdad7300daaf26bfdff39efda99e25))

*   `assert_enqueued_with`や`assert_enqueued_email_with`をブロックなしで呼べるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33258))

*   `enqueue`や`enqueue_at`の通知を、`after_enqueue`でラップするのではなく`around_enqueue`でラップするようになった
    ([Pull Request](https://github.com/rails/rails/pull/33171))

*   `perform_enqueued_jobs`をブロックなしで呼べるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33626))

*   `assert_performed_with`をブロックなしで呼べるようになった
    ([Pull Request](https://github.com/rails/rails/pull/33635))

*   `:queue`オプションをジョブのアサーションやヘルパーに追加
    ([Pull Request](https://github.com/rails/rails/pull/33635))

*   Active Jobにretryやdiscardなどのフックを追加
    ([Pull Request](https://github.com/rails/rails/pull/33751))

*   ジョブ実行時に引数のサブセットをテストする方法を追加
    ([Pull Request](https://github.com/rails/rails/pull/33995))

*   Active Jobテストヘルパーから返されるジョブに、デシリアライズされた引数が含まれるようになった
    ([Pull Request](https://github.com/rails/rails/pull/34204))

*   Active JobアサーションヘルパーでProcを受け取れるようになった（`only`用）
    keyword.
    ([Pull Request](https://github.com/rails/rails/pull/34339))

*   アサーションヘルパーで、ジョブの引数からマイクロセカンドやナノセカンドの桁を取り除けるようになった
    ([Pull Request](https://github.com/rails/rails/pull/35713))

Ruby on Rails Guides
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/6-0-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/6-0-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/6-0-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/6-0-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/6-0-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/6-0-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/6-0-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/6-0-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/6-0-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/6-0-stable/activejob/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/6-0-stable/guides/CHANGELOG.md
