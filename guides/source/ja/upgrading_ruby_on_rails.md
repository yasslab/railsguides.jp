Rails アップグレードガイド
===================================

本ガイドでは、アプリケーションで使われているRuby on Railsのバージョンを新しいバージョンにアップグレードする手順を解説します。アップグレードの手順は、Railsのバージョンごとに記載されています。

--------------------------------------------------------------------------------


一般的なアドバイス
--------------

既存のアプリケーションをアップグレードする前に、アップグレードする理由を明確にしておく必要があります。「新しいバージョンのどの機能か必要か」「既存コードのサポートがどのぐらい困難になるか」「アップグレードに割り当てられる時間と人員スキルはどのぐらいか」など、いくつもの要素を調整しなければなりません。

### テスティングのカバレッジ

アップグレード後にアプリケーションが正常に動作していることを確認するには、良いテストカバレッジをアップグレード前に準備しておくのがベストです。アプリケーションを一度に検査できる自動テストがないと、変更点をすべて手動で確認するのに膨大な時間がかかってしまいます。Railsのようなアプリケーションの場合、これはアプリケーションのあらゆる機能を１つ残らず確認しなければならないということです。アップグレードを実施する「前に」、テストカバレッジが揃っていることを確認しておいてください。

### Rubyバージョン

Railsでは、一般にRubyの最新版がリリースされると最新版のRubyに近い状態に合わせます。

* Rails 7.2: Ruby 3.1.0以降が必須
* Rails 7.0と7.1: Ruby 2.7.0以降が必須
* Rails 6: Ruby 2.5.0以降が必須
* Rails 5: Ruby 2.2.2以降が必須

RubyのアップグレードとRailsのアップグレードは別々に行うのがよい方法です。最初にRubyを可能な限り最新版にアップグレードし、それからRailsをアップグレードします。

### アップグレード手順

Railsのバージョンを変更する場合、マイナーバージョンを1つずつゆっくりと上げながら、その都度表示される非推奨機能の警告メッセージを上手に利用するのがベストです。言い換えると、アップグレードを急ぐあまりバージョンをスキップするべきではありません。Railsのバージョン番号は「**メジャー番号.マイナー番号.パッチ番号**」の形式を取ります。メジャーバージョンやマイナーバージョンの変更では、public APIの変更によるエラーがアプリケーションで発生する可能性があります。パッチバージョンはバグ修正のみが含まれ、public API変更は含まれません。

アップグレードは以下の手順で行います。

1. テストを書き、テストがパスすることを確認する。
2. 現時点のバージョンのパッチバージョンを最新のパッチに移行する。
3. テストを修正し、非推奨の機能を修正する。
4. 次のマイナーバージョンの最新パッチに移行する。

上の手順を繰り返して、最終的にRailsを目的のバージョンにアップグレードします。

リリース済みのRailsバージョンのリストは https://rubygems.org/gems/rails/versions で確認できます。

TIP: 訳注：日本語の参考資料については本ページ末尾の「[参考資料（日本語）](#参考資料（日本語）)」でまとめています。

#### Railsバージョン間を移動する

Railsのバージョン間を移動するには以下のようにします。

1. `Gemfile`ファイル内のRailsバージョン番号を変更し、`bundle update`を実行する。
2. `package.json`ファイル内のRails JavaScriptパッケージのバージョンを変更する。jsbundling-railsを使っている場合は、`bin/rails javascript:install`を実行する。
3. [アップデートタスク](#アップデートタスク)を実行する。
4. テストを実行する。

リリースされたすべてのRails gemリストについては[こちら](https://rubygems.org/gems/rails/versions)を参照してください。

### アップデートタスク

Rails では`app:update`というコマンドが提供されています。`Gemfile`に記載されているRailsのバージョンを更新後、このコマンドを実行することで、新しいバージョンでのファイル作成や既存ファイルの変更を対話形式で行うことができます。

```bash
$ bin/rails app:update
       exist  config
    conflict  config/application.rb
Overwrite /myapp/config/application.rb? (enter "h" for help) [Ynaqdh]
       force  config/application.rb
      create  config/initializers/new_framework_defaults_7_2.rb
...
```

予期しなかった変更が発生した場合は、必ず差分を十分チェックしてください。

### フレームワークのデフォルトを設定する

新しいバージョンのRailsでは、前のバージョンとデフォルト設定が異なるものがあります。しかし上述の手順に従うことで、アプリケーションが引き続き**従来**バージョンのRailsのデフォルト設定で実行されます（`config/application.rb`の`config.load_defaults`の値がまだ変更されていないため）。

`app:update`タスクでは、アプリケーションを新しいデフォルト設定に1つずつアップグレードできるように、`config/initializers/new_framework_defaults_X.Y.rb`ファイルが作成されます（ファイル名にはRailsのバージョンが含まれます）。このファイル内のコメントを解除して、新しいデフォルト設定を有効にする必要があります。この作業は、数回のデプロイに分けて段階的に実行できます。アプリケーションを新しいデフォルト設定で動かせる準備が整ったら、このファイルを削除して`config.load_defaults`の値を反転できます。

Rails 7.1からRails 7.2へのアップグレード
-------------------------------------

Rails 7.2で行われた変更について詳しくは、[Rails 7.2のリリースノート](7_2_release_notes.html)を参照してください。

### `active_job.queue_adapter`コンフィグがすべてのテストで尊重されるようになった

従来は、`config/application.rb`や`config/environments/test.rb`で`config.active_job.queue_adapter`を設定しても、指定したアダプタがすべてのテストで一貫して使われるわけではありませんでした。一部のテストでは指定のアダプタが使われますが、`TestAdapter`が使われることもありました。

Rails 7.2では、`queue_adapter`コンフィグを指定すれば、すべてのテストで尊重されるようになります。このため、`queue_adapter`コンフィグを`:test`以外に設定していた場合、`TestAdapter`に依存していたテストがエラーになる可能性があります。

`queue_adapter`コンフィグを提供しない場合は、引き続き`TestAdapter`が使われます。

Rails 7.0からRails 7.1へのアップグレード
-------------------------------------

Rails 7.1で行われた変更について詳しくは、[Rails 7.1のリリースノート](7_1_release_notes.html)を参照してください。

TIP: 訳注：アップグレード事例については [ruby-jp](https://ruby-jp.github.io/) の「[Rails 7.1 Upgrade Knowledge](https://scrapbox.io/ruby-jp/Rails_7.1_Upgrade_Knowledge)」でまとめています。

### development環境とtest環境のsecret_key_baseファイル名が変更された


Railsがdevelopment環境とtest環境で読み込む`secret_key_base`のファイル名が`tmp/development_secret.txt`から`tmp/local_secret.txt`に変更されました。

同じsecretを引き続き利用するには、単に従来のファイルを`local_secret.txt`にリネームするか、従来のファイルにあるキーを新しいファイルにコピーします。

これを行わないと、Railsはアプリケーションの読み込み時に新しいsecretキーを含む新しいファイル`tmp/local_secret.txt`を生成します。

そうなると、development環境とtest環境の既存のセッションやcookieがすべて無効化され、`secret_key_base`から導出された署名も無効になってしまいます（例: Active StorageやAction Textの添付ファイル）。

production環境およびその他の環境は影響を受けません。

### 自動読み込みされるパスが`$LOAD_PATH`に含まれなくなった

* [Disable config.add_autoload_paths_to_load_path by default in Rails 7.1 by casperisfine · Pull Request #44133 · rails/rails](https://github.com/rails/rails/pull/44133)

Rails 7.1以降、オートローダーが管理するすべてのディレクトリは`$LOAD_PATH`に追加されなくなりました。
これにより、手動で`require`を呼び出してそれらを読み込むことはできなくなります（いずれにしろ手動の`require`は行うべきではありません）。

`$LOAD_PATH`のサイズが削減されたことで、`bootsnap`を使っていないアプリの `require`呼び出しが高速化され、その他のアプリの`bootsnap`キャッシュのサイズも削減されます。

これらのパスを引き続き`$LOAD_PATH`に残しておきたい場合は、以下の設定で一応可能です。

```ruby
config.add_autoload_paths_to_load_path = true
```

ただしこれは推奨されません。自動読み込みパス内のクラスやモジュールは、自動読み込みされるようにするためにあるので、単に参照するだけにしてください。

`lib`ディレクトリはこのフラグの影響を受けず、常に`$LOAD_PATH`に追加されます。

### config.autoload_libとconfig.autoload_lib_onceについて

* [Introduce config.autoload_lib_once(ignore:) by fxn · Pull Request #48610 · rails/rails](https://github.com/rails/rails/pull/48610)

アプリケーションの`lib`ディレクトリがautoloadのパスやautoload onceのパスに含まれていない場合、このセクションをスキップしてください。

パスに`lib`が含まれているかどうかは、以下の表示をチェックすることで確認できます。

```bash
# autoloadパスを表示する
$ bin/rails runner 'pp Rails.autoloaders.main.dirs'

# autoload onceパスを表示する
$ bin/rails runner 'pp Rails.autoloaders.once.dirs'
```

アプリケーションの`lib`ディレクトリがautoloadのパスに既に含まれている場合は、多くの場合、config/application.rbに以下のような設定があるでしょう。

```ruby
# libを自動読み込みするがeager loadはしない（見落とされる可能性あり）
config.autoload_paths << config.root.join("lib")
```

または

```ruby
# libを自動読み込みおよびeager loadする
config.autoload_paths << config.root.join("lib")
config.eager_load_paths << config.root.join("lib")
```

または

```ruby
# すべてのeager loadパスが自動読み込みパスにもなるので同じ
config.eager_load_paths << config.root.join("lib")
```

これらの設定も引き続き動作しますが、これらの設定行がある場合は以下のように簡潔な設定に置き換えることが推奨されます。

```ruby
config.autoload_lib(ignore: %w(assets tasks))
```

この`ignore`リストには、`lib`のサブディレクトリのうち、`.rb`ファイルを含まないサブディレクトリや、または、リロードもeager loadもすべきでないサブディレクトリを追加してください。
たとえば、アプリケーションに`lib/templates`、`lib/generators`、または`lib/middleware`がある場合、それらの名前を以下のように`lib`からの相対パスで追加します。

```ruby
config.autoload_lib(ignore: %w(assets tasks templates generators middleware))
```

この設定の行によって、`config.eager_load`が`true`の場合（`production`モードのデフォルト）には`lib`内の（無視されていない）コードもeager loadされるようになります。通常はこれが望ましい動作ですが、これまで`lib`をeager loadパスに追加しておらず、引き続き`lib`をeager loadしないようにしたい場合は、以下の設定でオプトアウトしてください。

```ruby
Rails.autoloaders.main.do_not_eager_load(config.root.join("lib"))
```

`config.autoload_lib_once`メソッドは、アプリケーションの[`config.autoload_once_paths`]に`lib`がある場合と同様に振る舞います。

[`config-autoload-once-paths`]: https://railsguides.jp/configuring.html#config-autoload-once-paths

### `ActiveStorage::BaseController`がストリーミングのconcernを`include`しなくなった

* [Don't stream redirect controller responses by bubba · Pull Request #44244 · rails/rails](https://github.com/rails/rails/pull/44244)

`ActiveStorage::BaseController`を継承し、カスタムファイル配信ロジックをストリーミングで実装するアプリケーションコントローラは、明示的に `ActiveStorage::Streaming`モジュールを`include`する必要があります。

### `MemCacheStore`と`RedisCacheStore`がデフォルトでコネクションプールを使うようになった

* [Enable connection pooling by default for `MemCacheStore` and `RedisCacheStore` by fatkodima · Pull Request #45235 · rails/rails](https://github.com/rails/rails/pull/45235)

`connection_pool` gem が`activesupport`gemの依存関係として追加され、`MemCacheStore`と`RedisCacheStore`はデフォルトでコネクションプールを使うようになりました。

コネクションプールを使いたくない場合は、キャッシュストアの設定時に`:pool`オプションを`false`に設定してください：

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool: false }
```

詳しくは、[Rails のキャッシュ機構](caching_with_rails.html#コネクションプールのオプション)ガイドを参照してください。

### `SQLite3Adapter`が文字列の`strict`モードで設定されるようになった

* [Add `:strict` option to default SQLite database.yml template by fatkodima · Pull Request #45346 · rails/rails](https://github.com/rails/rails/pull/45346)

`strict`文字列モードによって、二重引用符`""`で囲まれた文字列リテラルが無効になります。

SQLiteは、二重引用符で囲まれた文字列リテラルについて、いくつかの癖があります。
SQLiteは最初に、二重引用符で囲まれた文字列を識別子名と見なそうとしますが、識別子が存在しない場合は文字列リテラルと見なします。これが原因で入力ミスを見落としてしまう可能性があります。
たとえば、存在しないカラムに対してインデックスを作成できてしまいます。詳しくは[SQLiteドキュメント](https://www.sqlite.org/quirks.html#double_quoted_string_literals_are_accepted)を参照してください。

`SQLite3Adapter`を`strict`モードで使いたくない場合は、以下の設定でこの動作を無効にできます。

```ruby
# config/application.rb
config.active_record.sqlite3_adapter_strict_strings_by_default = false
```

### `ActionMailer::Preview`でプレビューのパスを複数指定できるようになった

* [Support multiple preview paths for mailers by fatkodima · Pull Request #31595 · rails/rails](https://github.com/rails/rails/pull/31595)

`config.action_mailer.preview_path`オプション（単数形）は非推奨化され、今後は`config.action_mailer.preview_paths`オプション（複数形）を使うようになります。
この設定オプションにパスを追加すると、メーラーのプレビューの探索でそれらのパスが使われるようになります。

```ruby
config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"
```

### `config.i18n.raise_on_missing_translations = true`で訳文が見つからない場合に常にエラーをraiseするようになった

* [Make `raise_on_missing_translations` raise on any missing translation by ghiculescu · Pull Request #47105 · rails/rails](https://github.com/rails/rails/pull/47105)

従来は、ビューやコントローラで呼び出されたときだけraiseしていました。今後は、`I18n.t`に認識できないキーが与えられると常にraiseします。

```ruby
# config.i18n.raise_on_missing_translations = trueの場合

# ビューとコントローラ:
t("missing.key") # 7.0/7.1どちらもraiseする
I18n.t("missing.key") # 7.0: raiseしない、7.1: raiseする

# すべての場所:
I18n.t("missing.key") # # 7.0: raiseしない、7.1: raiseする
```

この振る舞いにしたくない場合は、`config.i18n.raise_on_missing_translations = false`を設定します。

```ruby
# config.i18n.raise_on_missing_translations = falseの場合

# ビューとコントローラ:
t("missing.key") # 7.0/7.1どちらもraiseしない
I18n.t("missing.key") # 7.0/7.1どちらもraiseしない

# すべての場所:
I18n.t("missing.key") # 7.0/7.1どちらもraiseしない
```

または、`I18n.exception_handler`をカスタマイズすることも可能です。
詳しくは[国際化（i18n）ガイド](i18n.html#%E6%A8%99%E6%BA%96%E4%BB%A5%E5%A4%96%E3%81%AE%E4%BE%8B%E5%A4%96%E3%83%8F%E3%83%B3%E3%83%89%E3%83%A9%E3%82%92%E4%BD%BF%E3%81%86)を参照してください。

`AbstractController::Translation.raise_on_missing_translations`は削除されました。これはprivate APIですが、万一これに依存している場合は、`config.i18n.raise_on_missing_translations`またはカスタムの例外ハンドラに移行する必要があります。

### `bin/rails test`で`test:prepare`タスクが実行されるようになった

`bin/rails test`でテストを実行すると、テストの実行前に`rake test:prepare`タスクを実行するようになりました。`test:prepare`タスクを拡張している場合は、その拡張機能をテストの前に実行します。`tailwindcss-rails`、`jsbundling-rails`、`cssbundling-rails`は、他のサードパーティgemと同様にこのタスクを拡張します。

詳しくは、[Rails テスティングガイド](https://railsguides.jp/testing.html#テストをciで実行する)を参照してください。

なお、単体ファイルのテストを実行する場合（例: `bin/rails test test/models/user_test.rb`）は、`test:prepare`を事前実行しません。

### `@rails/ujs`からのインポート構文が変更された

Rails 7.1以降、`@rails/ujs`からモジュールをインポートするときの構文が変更されました。Railsは`@rails/ujs`からのモジュールの直接インポートをサポートしなくなりました。たとえば、以下の構文でライブラリから関数をインポートしようとすると失敗します。

```javascript
import { fileInputSelector } from "@rails/ujs"
// ERROR: export 'fileInputSelector' (imported as 'fileInputSelector') was not found in '@rails/ujs' (possible exports: default)
```

Rails 7.1 では、最初にRailsオブジェクトを`@rails/ujs`から直接インポートしておく必要があります。
ユーザーは、このRailsオブジェクトから特定のモジュールをインポートできます。
Rails 7.1でのインポートの例を以下に示します。

```javascript
import Rails from "@rails/ujs"
// このメソッドをエイリアスする
const fileInputSelector = Rails.fileInputSelector
// または、利用する場所でRailsオブジェクトから参照する
Rails.fileInputSelector(...)
```

訳注: 以前ここにあった「`ActionView::TestCase#rendered`が`String`を返さなくなった」セクションは、[#51093](https://github.com/rails/rails/pull/51093/files#r1491429456)で削除されました。

### `Rails.logger`が`ActiveSupport::BroadcastLogger`インスタンスを返すようになった

新しい`ActiveSupport::BroadcastLogger`クラスを使うと、ログを手軽にさまざまな出力先（STDOUT、ログファイルなど）にブロードキャストできるようになります。

`ActiveSupport::Logger.broadcast` privateメソッドを用いる従来のログブロードキャストAPIは削除されました。
アプリケーションがこのAPIに依存している場合は、以下のような変更が必要です。

```ruby
logger = Logger.new("some_file.log")

# 変更前

Rails.logger.extend(ActiveSupport::Logger.broadcast(logger))

# 変更後

Rails.logger.broadcast_to(logger)
```

アプリケーションでカスタムロガーを利用している場合は、すべてのメソッドが`Rails.logger`にラップおよびプロキシされるので、特に変更は必要ありません。

カスタムロガーのインスタンスにアクセスする必要がある場合は、以下のように`broadcasts`メソッドでアクセスできます。

```ruby
# config/application.rb
config.logger = MyLogger.new

# アプリケーションのどこでも利用できる
puts Rails.logger.class      #=> BroadcastLogger
puts Rails.logger.broadcasts #=> [MyLogger]
```

[`assert_match`]: https://docs.seattlerb.org/minitest/Minitest/Assertions.html#method-i-assert_match

### Active Record 暗号化アルゴリズムの変更について

Active Record暗号化で、ハッシュダイジェストアルゴリズムとしてSHA-256を使うようになりました。従来のRailsバージョンで暗号化したデータがある場合は、アップグレードで考慮すべき2つのシナリオがあります。

1. [`config.active_support.key_generator_hash_digest_class`](configuring.html#config-active-support-key-generator-hash-digest-class)が**SHA-1**に設定されている場合（Rails 7.0より前のデフォルト）、Active Record暗号化で以下の設定も**SHA-1**に設定する必要があります。

    ```ruby
    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA1
    ```

2. [`config.active_support.key_generator_hash_digest_class`](configuring.html#config-active-support-key-generator-hash-digest-class)が**SHA-256**に設定されている場合（Rails 7.0の新しいデフォルト）、Active Record暗号化で以下の設定も**SHA-256**に設定する必要があります。

    ```ruby
    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256
    ```

`config.active_record.encryption.hash_digest_class`について詳しくは、[Rails アプリケーションの設定項目](configuring.html#config-active-record-encryption-hash-digest-class)ガイドを参照してください。

また、[`config.active_record.encryption.support_sha1_for_non_deterministic_encryption`](configuring.html#config-active-record-encryption-support-sha1-for-non-deterministic-encryption)という新しい設定も導入されました（[#48530](https://github.com/rails/rails/pull/48530)）。これは、前述の`hash_digest_class`をSHA-256に設定していても、一部の属性がSHA-1で暗号化されるバグ（[#42922](https://github.com/rails/rails/issues/42922)）を解決するためのものです。

この`config.active_record.encryption.support_sha1_for_non_deterministic_encryption`設定は、Rails 7.1ではデフォルトで無効になっています。Rails 7.1より前のバージョンで、暗号化データが上記のバグの影響を受けている可能性がある場合は、この設定を有効にする必要があります。

```ruby
config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true
```

暗号化データを扱っている場合は、必ず上記の点を慎重に確認してください。

### コントローラーテスト、結合テスト、システムテストの例外処理方法が新しくなった

`config.action_dispatch.show_exceptions`設定は、リクエストへの応答中に発生した例外をAction Packで処理する方法を制御します。

Rails 7.1より前のAction Packでは、`config.action_dispatch.show_exceptions = true`を設定すると、例外をrescueして適切なHTMLエラーページをレンダリングするように設定されていました（例: `ActiveRecord::RecordNotFound`例外をraiseするのではなく、`public/404.html`をステータスコード`404 Not found`でレンダリングする）。
`config.action_dispatch.show_exceptions = false`を設定すると、例外をrescueしないようにAction Packが設定されました。Rails 7.1より前の新しいアプリケーションでは、生成された`config/environments/test.rb`内で`config.action_dispatch.show_exceptions = false`が設定されていました。

Rails 7.1では、この設定に渡せる値が`true`と`false`から、`:all`と`:rescuable`と`:none`に変更されました。

* `:all`（`true`と同等）: すべての例外をHTMLエラーページで表示する
* `:rescuable`: [`config.action_dispatch.rescue_responses`](/configuring.html#config-action-dispatch-rescue-responses)で宣言されている例外についてはHTMLエラーページを表示する
* `:none`（`false`と同等）: 例外をrescueしない

Rails 7.1以降で生成したアプリケーションの`config/environments/test.rb`には `config.action_dispatch.show_exceptions = :rescuable`が設定されます。アップグレードする場合、既存のアプリケーションの`config.action_dispatch.show_exceptions = :rescuable`を新しい振る舞いに沿って変更することも、古い値を対応する新しい値に置き換える（`true`を`:all`に置き換え、`false`を`:none`に置き換える）ことも可能です。

Rails 6.1からRails 7.0へのアップグレード
-------------------------------------

Rails 7.0で行われた変更について詳しくは、[Rails 7.0のリリースノート](7_0_release_notes.html)を参照してください。

TIP: 訳注：アップグレード事例については [ruby-jp](https://ruby-jp.github.io/) の「[Rails 7.0 Upgrade Knowledge](https://scrapbox.io/ruby-jp/Rails_7.0_Upgrade_Knowledge)」でまとめています。


### `ActionView::Helpers::UrlHelper#button_to`の振る舞いが変更された

Rails 7.0以降の`button_to`は、ボタンURLをビルドするのに使われるActive Recordオブジェクトが永続化されている場合は、`patch` HTTP verbを用いる`form`タグをレンダリングします。現在の振る舞いを維持するには、以下のように明示的に`method:`オプションを渡します。

```diff
-button_to("Do a POST", [:my_custom_post_action_on_workshop, Workshop.find(1)])
+button_to("Do a POST", [:my_custom_post_action_on_workshop, Workshop.find(1)], method: :post)
```

または、以下のようにURLをビルドするヘルパーを使います。

```diff
-button_to("Do a POST", [:my_custom_post_action_on_workshop, Workshop.find(1)])
+button_to("Do a POST", my_custom_post_action_on_workshop_workshop_path(Workshop.find(1)))
```

### spring gem

アプリケーションでspring gemを使っている場合は、spring gemのバージョンを3.0.0以上にアップグレードする必要があります。そうしないと以下のエラーが発生します。

```
undefined method `mechanism=' for ActiveSupport::Dependencies:Module
```

また、`config/environments/test.rb`で[`config.cache_classes`][]設定を必ず`false`にしてください。

[`config.cache_classes`]: configuring.html#config-cache-classes

### Sprocketsへの依存がオプショナルになった

`rails` gemは`sprockets-rails`に依存しなくなりました。アプリケーションで引き続きSprocketsを使う必要がある場合は、Gemfileに`sprockets-rails`を追加してください。

```ruby
gem "sprockets-rails"
```

### アプリケーションは`zeitwerk`モードでの実行が必須

`classic`モードで動作しているアプリケーションは、`zeitwerk`モードに切り替えなければなりません。詳しくは[クラシックオートローダーからZeitwerkへの移行](classic_to_zeitwerk_howto.html)ガイドを参照してください。

### `config.autoloader=`セッターが削除された

Rails 7では、自動読み込みモードを指定する`config.autoloader=`設定そのものがなくなりました。何らかの理由で`:zeitwerk`に設定していた場合は、その設定行を削除してください。

### `ActiveSupport::Dependencies`のprivate APIが削除された

`ActiveSupport::Dependencies`のprivate APIが削除されました。`hook!`、`unhook!`、`depend_on`、`require_or_load`、`mechanism`など多数のメソッドが削除されています。

注意点をいくつか示します。

* `ActiveSupport::Dependencies.constantize`または`ActiveSupport::Dependencies.safe_constantize`を使っている場合は、`String#constantize`または`String#safe_constantize`に変更してください。

```ruby
ActiveSupport::Dependencies.constantize("User") # 今後は利用不可
"User".constantize # 👍
```

* `ActiveSupport::Dependencies.mechanism`やそのリーダーやライターを使っている場合は、`config.cache_classes`のアクセスで置き換える必要があります。

* オートローダーの動作をトレースしたい場合、`ActiveSupport::Dependencies.verbose=`は利用できなくなりました。`config/application.rb`で`Rails.autoloaders.log!`をスローしてください。

`ActiveSupport::Dependencies::Reference`や`ActiveSupport::Dependencies::Blamable`などの補助的なクラスやモジュールも削除されました。

### 初期化中の自動読み込み

Rails 6.0以降では、アプリケーションの初期化中に、再読み込み可能な定数を`to_prepare`ブロックの外で自動読み込みすると、それらの定数がアンロードされて以下の警告が出力されます。

```
DEPRECATION WARNING: Initialization autoloaded the constant ....

Being able to do this is deprecated. Autoloading during initialization is going
to be an error condition in future versions of Rails.

...
```

この警告が引き続きログに出力される場合は、[アプリケーション起動時の自動読み込み](https://railsguides.jp/autoloading_and_reloading_constants.html#アプリケーション起動時の自動読み込み)でアプリケーション起動時の自動読み込みについての記述を参照してください。これに対応しないと、Rails 7で`NameError`が出力されます。

`once`オートローダーによって管理される定数は、初期化中にオートロードされ、通常どおり利用できます。`to_prepare`ブロックは必要ありません。ただし、`once`オートローダーは、これをサポートするために、より早期にセットアップされるようになりました。アプリケーションにカスタムの活用形（inflections）が設定されていて、`once`オートローダーでそれを認識する必要がある場合は、`config/initializers/inflections.rb`のコードを`config/application.rb`のアプリケーションクラス定義の本体に移動する必要があります。

```ruby
module MyApp
  class Application < Rails::Application
    # ...

    ActiveSupport::Inflector.inflections(:en) do |inflect|
      inflect.acronym "HTML"
    end
  end
end
```

### `config.autoload_once_paths`を設定可能になった

[`config.autoload_once_paths`][]は、`config/application.rb`で定義されるApplicationクラスの本体、または`config/environments/*`の環境向け設定で設定可能です。

エンジンも同様に、エンジンクラスのクラス本体内にあるコレクションや、環境向けの設定内にあるコレクションを設定可能です。

コレクションは以後frozenになり、これらのパスから自動読み込みできるようになります。特に、これらのパスから初期化中に自動読み込みできるようになります。これらのパスは、`Rails.autoloaders.once`オートローダーで管理されます。このオートローダーはリロードを行わず、自動読み込みやeager loadingのみを行います。

環境設定が完了した後でこの設定を行ったときに`FrozenError`が発生する場合は、コードの置き場所を移動してください。

[`config.autoload_once_paths`]: configuring.html#config-autoload-once-paths

### `ActionDispatch::Request#content_type`が Content-Typeヘッダーをそのまま返すようになった

従来は、`ActionDispatch::Request#content_type`が返す値にcharsetパートが含まれて「いませんでした」。
この振る舞いが変更され、charsetパートを含むContent-Typeヘッダーをそのまま返すようになりました。

MIMEタイプだけが欲しい場合は、代わりに`ActionDispatch::Request#media_type`をお使いください。

変更前:

```ruby
request = ActionDispatch::Request.new("CONTENT_TYPE" => "text/csv; header=present; charset=utf-16", "REQUEST_METHOD" => "GET")
request.content_type #=> "text/csv"
```

変更後:

```ruby
request = ActionDispatch::Request.new("Content-Type" => "text/csv; header=present; charset=utf-16", "REQUEST_METHOD" => "GET")
request.content_type #=> "text/csv; header=present; charset=utf-16"
request.media_type   #=> "text/csv"
```

### キージェネレータのメッセージダイジェストクラスでcookieローテーターが必須になった

キージェネレータで用いられるデフォルトのダイジェストクラスが、SHA1からSHA256に変更されました。
その結果、Railsで生成されるあらゆる暗号化メッセージがこの影響を受けるようになり、暗号化および署名済みcookieも同様に影響を受けます。

古いダイジェストクラスを用いてメッセージを読めるようにするには、ローテータの登録が必要です。これを行わないと、アップグレード中にユーザーのセッションが無効になる可能性があります。

以下は、暗号化cookie向けのローテータの設定例です。

```ruby
# config/initializers/cookie_rotator.rb
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    authenticated_encrypted_cookie_salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

    secret_key_base = Rails.application.secret_key_base

    key_generator = ActiveSupport::KeyGenerator.new(
      secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    old_encrypted_secret = key_generator.generate_key(authenticated_encrypted_cookie_salt, key_len)
    old_signed_secret = key_generator.generate_key(signed_cookie_salt)

    cookies.rotate :encrypted, old_encrypted_secret
    cookies.rotate :signed, old_signed_secret
  end
end
```

### `ActiveSupport::Digest`で用いられるメッセージダイジェストクラスがSHA256に変更

`ActiveSupport::Digest`で用いられるデフォルトのダイジェストクラスがSHA1からSHA256に変更されます。
その結果、Etagなどの変更やキャッシュキーにも影響します。
これらのキーを変更すると、キャッシュのヒット率が低下する可能性があるので、新しいハッシュにアップグレードする際は慎重に進めるようご注意ください。

### `ActiveSupport::Cache`の新しいシリアライズフォーマット

より高速かつコンパクトな新しいシリアライズフォーマットが導入されました。

これを有効にするには、以下のように`config.active_support.cache_format_version = 7.0`を設定する必要があります。

```ruby
# config/application.rb

config.load_defaults 6.1
config.active_support.cache_format_version = 7.0
```

または以下のようにシンプルに設定します。

```ruby
# config/application.rb

config.load_defaults 7.0
```

ただし、Rails 6.1アプリケーションはこの新しいシリアライズフォーマットを読み取れないので、シームレスにアップグレードするには、まずRails 7.0へのアップグレードを`config.active_support.cache_format_version = 6.1`でデプロイし、Railsプロセスがすべて更新されたことを確かめてから`config.active_support.cache_format_version = 7.0`を設定する必要があります。

Rails 7.0は新旧両方のフォーマットを読み取れるので、アップグレード中にキャッシュが無効になることはありません。

### ActiveStorageの動画プレビュー画像生成

動画のプレビュー画像生成で、FFmpegの場面転換検出機能を用いて従来よりも意味のあるプレビュー画像を生成するようになりました。従来は動画の冒頭フレームが使われたため、黒画面からフェードインして開始される動画で問題が生じました。この変更にはFFmpeg v3.4以降が必要です。

### Active Storageのデフォルトのバリアントプロセッサが `:vips`に変更

新規アプリの画像変換では、従来のImageMagickに代えてlibvipsが使われるようになります。これにより、バリアント（サムネイルなどで用いられるサイズ違いの画像）の生成時間が短縮されるとともにCPUやメモリの使用量も削減され、Active Storageで画像を配信するアプリのレスポンスが向上します。

`:mini_magick`オプションは非推奨化されていませんので、引き続き問題なく利用できます。

既存のアプリをlibvipsに移行するには、以下を設定します。

```ruby
Rails.application.config.active_storage.variant_processor = :vips
```

続いて、既存の画像変換コードを`image_processing`マクロに変更し、さらにImageMagickのオプションをlibvipsのオプションに置き換える必要があります。

#### `resize`を`resize_to_limit`に置き換える

```diff
- variant(resize: "100x")
+ variant(resize_to_limit: [100, nil])
```

上の置き換えを行わないと、vipsに切り替えたときに`no implicit conversion to float from string`エラーが表示されます。

#### `crop`で配列を使うよう変更する

```diff
- variant(crop: "1920x1080+0+0")
+ variant(crop: [0, 0, 1920, 1080])
```

上の置き換えを行わないと、vipsに移行したときに`unable to call crop: you supplied 2 arguments, but operation needs 5`エラーが表示されます。

#### `crop`の値を固定する

vipsの`crop`は、ImageMagickよりも厳密です。

1. `x`や`y`が負の値の場合は`crop`されない。例: `[-10, -10, 100, 100]`

2. 位置（`x`または`y`）と`crop`のサイズ（`width`、`height`）が画像サイズを上回る場合は`crop`されない。例: 125x125の画像に対して`[50, 50, 100, 100]`で`crop`する。

上を守らない場合、vipsに移行したときに`extract_area: bad extract area`エラーが表示されます。

#### `resize_and_pad`の背景色を調整する

vipsの`resize_and_pad`では、デフォルトバックグラウンド色にImageMagickの白ではなく黒が使われます。これは以下のように`background:`オプションで修正できます。

```diff
- variant(resize_and_pad: [300, 300])
+ variant(resize_and_pad: [300, 300, background: [255]])
```

#### EXIFベースの画像回転を止める

vipsでは、バリアントを処理中にEXIF値を用いて画像を自動回転します。ユーザーがアップロードした写真の回転値を保存してImageMagickで回転するのであれば、以下のようにこの機能を止める必要があります。

```diff
- variant(format: :jpg, rotate: rotation_value)
+ variant(format: :jpg)
```

#### `monochrome`を`colourspace`に置き換える。

vipsでは、モノクロ画像を作成するオプションを以下のように変更する必要があります。

```diff
- variant(monochrome: true)
+ variant(colourspace: "b-w")
```

#### libvipsの画像圧縮オプションに変更する

JPEGの場合。

```diff
- variant(strip: true, quality: 80, interlace: "JPEG", sampling_factor: "4:2:0", colorspace: "sRGB")
+ variant(saver: { strip: true, quality: 80, interlace: true })
```

PNGの場合。

```diff
- variant(strip: true, quality: 75)
+ variant(saver: { strip: true, compression: 9 })
```

WEBPの場合。

```diff
- variant(strip: true, quality: 75, define: { webp: { lossless: false, alpha_quality: 85, thread_level: 1 } })
+ variant(saver: { strip: true, quality: 75, lossless: false, alpha_q: 85, reduction_effort: 6, smart_subsample: true })
```

GIFの場合。

```diff
- variant(layers: "Optimize")
+ variant(saver: { optimize_gif_frames: true, optimize_gif_transparency: true })
```

#### production環境へのデプロイ

Active Storageは、実行されなければならない変換のリストを画像URLにエンコードします。
アプリケーションがこれらの画像URLをキャッシュしていると、新しいコードをproduction環境にデプロイした後で画像が破損します。
このため、影響を受けるキャッシュキーを手動で無効にしなければなりません。

たとえば、以下のようなビューがあるとします。

```erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= image_tag product.cover_photo.variant(resize: "200x") %>
  <% end %>
<% end %>
```

このキャッシュを無効にするには、`product`を以下のように変更するか、キャッシュキーを変更します。

```erb
<% @products.each do |product| %>
  <% cache ["v2", product] do %>
    <%= image_tag product.cover_photo.variant(resize_to_limit: [200, nil]) %>
  <% end %>
<% end %>
```

### Active RecordのスキーマダンプにRailsのバージョンが含まれるようになった

Rails 7.0では、いくつかのカラムタイプのデフォルト値が変更されました。6.1から7.0にアップグレードしたアプリケーションが現在のスキーマを読み込むときに、7.0の新しいデフォルト値が使われるのを避けるため、Railsはスキーマダンプにフレームワークのバージョンを含めるようになりました。

Rails 7.0で初めてスキーマを読み込むときは、その前に`rails app:update`を実行して、スキーマのバージョンがスキーマダンプに含まれていることを確認してください。

スキーマファイルは以下のような感じになります。

```ruby
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.
ActiveRecord::Schema[6.1].define(version: 2022_01_28_123512) do
  # ...
end
```

NOTE: Rails 7.0で初めてスキーマをダンプすると、そのファイルでカラム情報などさまざまな変更が行われていることがわかります。必ず新しいスキーマファイルの内容を確認してから、リポジトリにコミットすることを忘れないようにしましょう。


Rails 6.0からRails 6.1へのアップグレード
-------------------------------------

Rails 6.1の変更点について詳しくは[Rails 6.1のリリースノート](6_1_release_notes.html)を参照してください。

TIP: 訳注：アップグレード事例については [ruby-jp](https://ruby-jp.github.io/) の「[Rails 6.1 Upgrade Knowledge](https://scrapbox.io/ruby-jp/Rails_6.1_Upgrade_Knowledge)」でまとめています。


### `Rails.application.config_for`の戻り値をStringキーでアクセスするサポートが終了した

以下のような設定ファイルがあるとします。

```yaml
# config/example.yml
development:
  options:
    key: value
```

```ruby
Rails.application.config_for(:example).options
```

従来は、Stringキーで値にアクセス可能なハッシュを１つ返しました。この機能は6.0で非推奨化され、6.1で削除されました。

従来どおりStringキーを用いて値にアクセスしたい場合は、`config_for`の戻り値で`with_indifferent_access`を呼び出せます。

```ruby
Rails.application.config_for(:example).with_indifferent_access.dig('options', 'key')
```

### `respond_to#any`を使う場合のレスポンスのContent-Typeヘッダーについて

レスポンスで返されるContent-Typeヘッダーは、Rails 6.0で返されるものと異なる可能性があります。特にアプリケーションで`respond_to { |format| format.any }`を使っている場合、Content-Typeヘッダーはリクエストのフォーマットではなく、渡されたブロックを元にするようになりました。

以下の例をご覧ください。

```ruby
def my_action
  respond_to do |format|
    format.any { render(json: { foo: 'bar' }) }
  end
end
```

```ruby
get('my_action.csv')
```

従来の振る舞いではレスポンスのContent-Typeで`text/csv`を返していましたが、実際にはJSONレスポンスをレンダリングしているので正しくありません。現在の振る舞いではレスポンスのContent-Typeで`application/json`を正しく返すようになりました。

アプリケーションが従来の正しくない振る舞いに依存している場合は、以下のようにアクションで受け取るフォーマットを明示的に指定してください。

```ruby
format.any(:xml, :json) { render request.format.to_sym => @people }
```

### `ActiveSupport::Callbacks#halted_callback_hook`に第2引数を渡せるようになった

Active Supportは、コールバックのチェーンがhalt（停止）したときの`halted_callback_hook`をオーバーライドできます。このメソッドに、halt中のコールバック名を第2引数として渡せるようになりました。このメソッドをオーバーライドするクラスがある場合は、引数を2つ受け取れるようにしてください。なおパフォーマンス上の理由のため、この破壊的変更は非推奨化を経ていません。

以下の例をご覧ください。

```ruby
class Book < ApplicationRecord
  before_save { throw(:abort) }
  before_create { throw(:abort) }

  def halted_callback_hook(filter, callback_name) # => このメソッドが1個ではなく2個の引数を取れるようになった
    Rails.logger.info("Book couldn't be #{callback_name}d")
  end
end
```

### コントローラ内で`helper`のクラスメソッドが`String#constantize`を使うようになった

概念について説明します。

```ruby
helper "foo/bar"
```

Rails 6.1より前は、上のコードから以下の結果が得られました。

```ruby
require_dependency "foo/bar_helper"
module_name = "foo/bar_helper".camelize
module_name.constantize
```

Rail 6.1では以下のような結果になります。

```ruby
prefix = "foo/bar".camelize
"#{prefix}Helper".constantize
```

この変更は、多くのアプリケーションで後方互換性が保たれているので、これに該当する場合は対応不要です。

ただし技術的には、autoloadパス上にない`$LOAD_PATH`内のディレクトリを指すようコントローラが`helpers_path`を設定することも可能でしたが、今後このようなユースケースはすぐ使える形ではサポートされません。ヘルパーモジュールが自動読み込み可能でない場合は、`helper`を呼び出す前にアプリケーションが明示的に読み込んでおく責任があります。

TIP: （訳注）詳しくは[Remove \`require\_dependency\` usage in \`helper\` \[Closes \#37632\] · rails/rails@5b28a0e](https://github.com/rails/rails/commit/5b28a0e972da31da570ed24be505ef7958ab4b5e)もどうぞ。`helper`での読み込みに`require_dependency`が使われなくなったことによる変更です。

### HTTPからHTTPSへのリダイレクトでHTTP 308ステータスコードが使われるようになった

`ActionDispatch::SSL`でGETやHEAD以外のリクエストをHTTPからHTTPSにリダイレクトする場合のデフォルトHTTPステータスコードが、[RFC7538](https://tools.ietf.org/html/rfc7538)の定義に従って`308`に変更されました。

### Active Storageでimage_processing gemが必須になった

Active Storageでvariantを処理する場合、従来のように`mini_magick`を直接利用するのではなく、[image_processing](https://github.com/janko/image_processing) gemのバンドルが必須になりました。image_processingの背後ではデフォルトで`mini_magick`が使われるので、不要になった明示的な`combine_options`を必ず削除してください。

できれば、`image_processing`の`resize`マクロの直接呼び出しも変更しておくことをおすすめします（変更することでリサイズ後のサムネイルもシャープになります）。

```ruby
video.preview(resize: "100x100")
video.preview(resize: "100x100>")
video.preview(resize: "100x100^")
```

たとえば、上のコードはそれぞれ以下のように変更できます。

```ruby
video.preview(resize_to_fit: [100, 100])
video.preview(resize_to_limit: [100, 100])
video.preview(resize_to_fill: [100, 100])
```

### `ActiveModel::Error` クラスが追加された

エラーが新しく `ActiveModel::Error` クラスのインスタンスになり、APIの変更もあわせて行われました。これらの変更によって、新しくエラーが発生する、または Rails 7.0 で廃止されるため非推奨の警告を出力する場合があります。

この変更とAPIについて詳しくは[#32313](https://github.com/rails/rails/pull/32313)を参照してください。


Rails 5.2からRails 6.0へのアップグレード
-------------------------------------

Rails 6.0の変更点について詳しくは[Rails 6.0のリリースノート](6_0_release_notes.html)を参照してください。

TIP: 訳注：アップグレード事例については [ruby-jp](https://ruby-jp.github.io/) の「[Rails 6.0 Upgrade Knowledge](https://scrapbox.io/ruby-jp/Rails_6.0_Upgrade_Knowledge)」でまとめています。


### Webpackerの利用について

[Webpacker](https://github.com/rails/webpacker)はRails 6におけるデフォルトのJavaScriptコンパイラですが、アプリケーションを以前のバージョンからアップグレードした場合は自動的には有効になりません。
Webpackerを使いたい場合は、以下をGemfileに追記し、`bin/rails webpacker:install`コマンドを実行してインストールしてください。

```ruby
gem "webpacker"
```

```bash
$ bin/rails webpacker:install
```

### SSLの強制

コントローラの`force_ssl`メソッドは非推奨化され、Rails 6.1で削除される予定です。[`config.force_ssl`][]設定を有効にしてアプリ全体でHTTPS接続を強制することをおすすめします。特定のエンドポイントのみをリダイレクトしないようにする必要がある場合は、[`config.ssl_options`][]で振る舞いを変更できます。

[`config.force_ssl`]: configuring.html#config-force-ssl
[`config.ssl_options`]: configuring.html#config-ssl-options

### セキュリティ向上のためpurposeとexpiryメタデータが署名済みcookieや暗号化済みcookieに埋め込まれるようになった

これにより、Railsはcookieの署名済み・暗号化済みの値をコピーして別のcookieで流用する攻撃を阻止できるようになります。

新たに埋め込まれるこのpurpose情報によって、Rails 6.0のcookieはそれより前のバージョンのcookieとの互換性が失われます。

cookieを引き続きRails 5.2以前でも読み取れるようにする必要がある場合や、6.0のデプロイを検証中で前のバージョンに戻せるようにしたい場合は、`Rails.application.config.action_dispatch.use_cookies_with_metadata`に`false`を設定してください。

### npmの全パッケージが`@rails`スコープに移動

これまで「`actioncable`」「`activestorage`」「`rails-ujs`」パッケージのいずれかをnpmまたはyarn経由で読み込んでいた場合は、これらを`6.0.0`にアップグレードする前にそれらの依存関係の名前を以下のように更新しなければなりません。

```
actioncable   → @rails/actioncable
activestorage → @rails/activestorage
rails-ujs     → @rails/ujs
```

### Action Cable JavaScript APIの変更

Action Cable JavaScriptパッケージがCoffeeScriptからES2015に置き換えられ、ソースコードをnpmディストリビューションでパブリッシュできるようになりました。

今回のリリースでは、Action Cable JavaScript APIの選択可能な部分に若干のbreaking changesが生じます。

- WebSocketアダプタやロガーアダプタの設定が、`ActionCable`のプロパティから`ActionCable.adapters`のプロパティに移動しました。これらのアダプタを設定している場合は、以下の変更が必要です。

    ```diff
    -    ActionCable.WebSocket = MyWebSocket
    +    ActionCable.adapters.WebSocket = MyWebSocket
    ```

    ```diff
    -    ActionCable.logger = myLogger
    +    ActionCable.adapters.logger = myLogger
    ```

- `ActionCable.startDebugging()`メソッドと`ActionCable.stopDebugging()`メソッドが削除され、`ActionCable.logger.enabled`に置き換えられました。これらのメソッドを使っている場合は、以下の変更が必要です。

    ```diff
    -    ActionCable.startDebugging()
    +    ActionCable.logger.enabled = true
    ```

    ```diff
    -    ActionCable.stopDebugging()
    +    ActionCable.logger.enabled = false
    ```

### `ActionDispatch::Response#content_type`がContent-Typeヘッダーを変更せずに返すようになった

従来は、`ActionDispatch::Response#content_type`の戻り値にcharsetパートが**含まれていませんでした**。
この振る舞いは変更され、従来省略されていたcharsetパートも含まれるようになりました。

MIMEタイプだけが欲しい場合は、代わりに`ActionDispatch::Response#media_type`をお使いください。

変更前:

```ruby
resp = ActionDispatch::Response.new(200, "Content-Type" => "text/csv; header=present; charset=utf-16")
resp.content_type #=> "text/csv; header=present"
```

変更後:

```ruby
resp = ActionDispatch::Response.new(200, "Content-Type" => "text/csv; header=present; charset=utf-16")
resp.content_type #=> "text/csv; header=present; charset=utf-16"
resp.media_type   #=> "text/csv"
```

### 新しい`config.hosts`設定

Railsに、セキュリティ用の`config.hosts`設定が新たに追加されました。この設定は、development環境ではデフォルトで`localhost`に設定されます。開発中に他のドメインを使う場合は、以下のように明示的に許可する必要があります。

```ruby
# config/environments/development.rb

config.hosts << 'dev.myapp.com'
config.hosts << /[a-z0-9-]+\.myapp\.com/ # 正規表現も利用可能
```

その他の環境では、`config.hosts`はデフォルトで空になります。これは、Railsがホストをまったく検証しないことを意味します。production環境で検証を有効にしたい場合は、オプションで追加できます。

### 自動読み込み

Rails 6のデフォルト設定では、CRubyで`zeitwerk`の自動読み込みモードが有効になります。

```ruby
# config/application.rb

config.load_defaults "6.0"
```

自動読み込みモードでは、自動読み込み、再読み込み、eager loadingを[Zeitwerk](https://github.com/fxn/zeitwerk)で管理します。

以前のバージョンのRailsのデフォルトを使っている場合は、以下の方法でzeitwerkを有効にできます。

```ruby
# config/application.rb

config.autoloader = :zeitwerk
```

#### public APIについて

一般に、アプリケーションでZeitwerk APIの利用が直接必要になることはありません。Railsは、`config.autoload_paths`や`config.cache_classes`といった既存の約束事に沿ってセットアップを行います。

アプリケーションはこのインターフェイスを遵守すべきですが、実際のZeitwerkローダーオブジェクトに以下のようにアクセスできます。

```ruby
Rails.autoloaders.main
```

上は、たとえばSTI（単一テーブル継承）をプリロードする必要がある場合や、カスタムのinflectorを設定する必要が生じた場合には役立つことがあるでしょう。

#### プロジェクトの構成

アップグレードしたアプリケーションの自動読み込みが正しく動いていれば、プロジェクトの構成はほぼ互換性が保たれているはずです。

ただし`classic`モードは、見つからない定数名からファイル名を推測しますが（`underscore`）、`zeitwerk`モードはファイル名から定数名を推測します（`camelize`）。特に略語がからむ場合、これらのヘルパーで双方向に変換できるとは限りません。たとえば、`"FOO".underscore`は`"foo"`になりますが、`"foo".camelize`は`"FOO"`ではなく`"Foo"`になります。

互換性については、以下のように`zeitwerk:check`タスクでチェックできます。

```bash
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

#### `require_dependency`について

`require_dependency`の既知のユースケースはすべて排除されました。自分のプロジェクトをgrepして`require_dependency`を削除してください。

アプリケーションでSTI（単一テーブル継承）が使われている場合は、[定数の自動読み込みと再読み込み（Zeitwerkモード）](autoloading_and_reloading_constants.html#sti（単一テーブル継承）)ガイドの該当セクションを参照してください。

#### クラス定義やモジュール定義の完全修飾名

クラス定義やモジュール定義で、定数パスを安定して使えるようになりました。

```ruby
# このクラスの本文の自動読み込みがRubyのセマンティクスと一致するようになった
class Admin::UsersController < ApplicationController
  # ...
end
```

ここで知っておいていただきたいのは、`classic`モードのオートローダーでは、実行順序によっては以下のコードの`Foo::Wadus`を自動読み込みできてしまう場合があるということです。

```ruby
class Foo::Bar
  Wadus
end
```

上の`Foo`はネストしていないのでRubyのセマンティクスと一致せず、`zeitwerk`ではまったく動かなくなります。こうしたエッジケースが見つかったら、以下のように完全修飾名の`Foo::Wadus`を使えます。

```ruby
class Foo::Bar
  Foo::Wadus
end
```

または、以下のように`Foo`でネストすることもできます

```ruby
module Foo
  class Bar
    Wadus
  end
end
```

#### `concerns`について

以下のような標準的な構造は、自動読み込みもeager loadも可能です。

```
app/models
app/models/concerns
```

上は、（自動読み込みパスに属するので）`app/models/concerns`がrootディレクトリであると仮定され、名前空間としては無視されます。したがって、`app/models/concerns/foo.rb`は`Concerns::Foo`ではなく`Foo`と定義すべきです。

`Concerns::`名前空間は、`classic`モードのオートローダーでは実装の副作用によって動作していましたが、実際は意図した動作ではありませんでした。`Concerns::`を使っているアプリケーションが`zeitwerk`モードで動くようにするには、こうしたクラスやモジュールをリネームする必要があります。

#### 自動読み込みパス内に`app`がある場合

プロジェクトによっては、`API::Base`を定義するために`app/api/base.rb`のようなものが欲しい場合があります。`classic`モードではこれを行うために自動読み込みパスに`app`を追加します。Railsは`app`の全サブディレクトリを自動読み込みパスに追加するので、ネストしたルートディレクトリがある状況がもう１つ存在することになり、セットアップが機能しなくなります。この原則は上述の`concerns`と同様です。

そうした構造を維持したい場合は、イニシャライザで以下のようにサブディレクトリを自動読み込みパスから削除する必要があります。

```ruby
ActiveSupport::Dependencies.autoload_paths.delete("#{Rails.root}/app/api")
```

#### 定数の自動読み込みと明示的な名前空間

あるファイルの中で名前空間が1つ定義されているとします（ここでは`Hotel`）。

```
app/models/hotel.rb         # Hotelが定義される
app/models/hotel/pricing.rb # Hotel::Pricingが定義される
```

この`Hotel`という定数の定義には、必ず`class`キーワードまたは`module`キーワードを使わなければなりません。次の例をご覧ください。

```ruby
class Hotel
end
```

上は問題ありませんが、以下はどちらも動きません。

```ruby
Hotel = Class.new
```

```ruby
Hotel = Struct.new
```

後者は`Hotel::Pricing`などの子オブジェクトを探索できなくなります。

この制約は、明示的な名前空間にのみ適用されます。名前空間を定義しないクラスやモジュールであれば、後者の方法でも定義できます。

#### 「1つのファイルには1つの定数だけ」（同じトップレベルで）

`classic`モードでは、同じトップレベルに複数の定数を定義して、それらをすべて再読み込みすることが技術的には可能でした。以下の例をご覧ください。

```ruby
# app/models/foo.rb

class Foo
end

class Bar
end
```

上で`Foo`を自動読み込みすると、`Bar`を自動読み込みできなかった場合にも`Bar`を自動読み込み済みとマーキングすることがありました。このようなコードは`zeitwerk`では対象外なので、`Bar`はそれ専用の`bar.rb`というファイルに移すべきです。「1つのファイルには1つの定数だけ」となります。

これは、上の例のように「同じトップレベルにある」定数にのみ適用されます。ネストの内側にあるクラスやモジュールは影響を受けません。以下の例をご覧ください。

```ruby
# app/models/foo.rb

class Foo
  class InnerClass
  end
end
```

アプリケーションで`Foo`を再読み込みすれば、`Foo::InnerClass`も再読み込みされます。

#### spring gemと`test`環境について

spring gemは、アプリケーションのコードが変更されると再読み込みします。`test`環境では、そのために再読み込みを有効にしておく必要があります。

```ruby
# config/environments/test.rb

config.cache_classes = false
```

有効にしておかないと、以下のエラーが表示されます。

```
reloading is disabled because config.cache_classes is true
```

#### Bootsnapについて

Bootsnapのバージョンは1.4.2以上にする必要があります。

また、Ruby 2.5を実行中は、インタプリタのバグの関係で、iseqキャッシュを無効にする必要があります。その場合はBootsnap 1.4.4以上に依存するようにしてください。

#### `config.add_autoload_paths_to_load_path`

[`config.add_autoload_paths_to_load_path`][]は、後方互換性のためデフォルトで`true`になっていますが、これを`false`にすると`$LOAD_PATH`に自動読み込みパスを追加しなくなります。

この設定変更は、ほとんどのアプリケーションで有用です（`app/models`内などのファイルは決して`require`すべきではなく、Zeitwerkは内部で絶対パスだけを使うからです）。

この新しい設定を無効にすれば、`$LOAD_PATH`の探索を最適化して（つまりチェックするディレクトリを減らして）、Bootsnapの動作を軽くしてメモリ消費量を削減できます。Bootsnapがそうしたディレクトリのインデックスをビルドする必要がなくなるからです。

[`config.add_autoload_paths_to_load_path`]: configuring.html#config-add-autoload-paths-to-load-path

#### スレッド安全性について

`classic`モードにおける定数の自動読み込みはスレッド安全ではありません。Railsには、自動読み込みが有効な状態でWebのリクエストをスレッド安全にする（これはdevelopment環境でよくあることです）ためのロックがあるにもかかわらずです。

`zeitwerk`モードにおける定数の自動読み込みは、スレッド安全です。たとえば、`runner`コマンドで実行されるマルチスレッドでも自動読み込みが可能です。

#### config.autoload_pathsの注意事項

以下のような設定は要注意です。

```ruby
config.autoload_paths += Dir["#{config.root}/lib/**/"]
```

`config.autoload_paths`のあらゆる要素は、トップレベルの名前空間（`Object`）を表すべきなので、ネストできなくなります（前述の`concerns`ディレクトリは例外）。

この修正は、ワイルドカードを削除するだけでできます。

```ruby
config.autoload_paths << "#{config.root}/lib"
```

#### eager loadingと自動読み込みが一貫するようになる

`classic`の場合、たとえば`app/models/foo.rb`で`Bar`を定義すると、そのファイルを自動読み込みできなくなりますが、eager loading（一括読み込み）は機械的にファイルを再帰読み込みするため、自動読み込み可能です。この挙動のため、テストの冒頭で何かをeager loadingするとその後の実行で自動読み込みが失敗し、エラーの原因となる可能性があります。

`zeitwerk`モードの場合、どちらの読み込みモードも一貫するので、失敗やエラーは同一のファイルで発生するようになります。

#### Rails 6でclassicモードのオートローダーを利用する

アプリケーションはRails 6のデフォルトを読み込みますが、以下のように`config.autoloader`を設定することで`classic`モードのオートローダを使うこともできます。

```ruby
# config/application.rb

config.load_defaults 6.0
config.autoloader = :classic
```

Rails 6アプリケーションでclassicオートローダーを使う場合は、スレッド安全性上の懸念があるため、development環境ではWebサーバーやバックグラウンド処理のconcurrency levelを1に設定することをおすすめします。

### Active Storageの代入の振る舞いの変更

Rails 5.2のデフォルト設定では、`has_many_attached`で宣言された添付ファイル（attachment）のコレクションへの代入は、新しいファイルの追加（append）操作になります。

```ruby
class User < ApplicationRecord
  has_many_attached :highlights
end

user.highlights.attach(filename: "funky.jpg")
user.highlights.count # => 1

blob = ActiveStorage::Blob.create_after_upload!(filename: "town.jpg")
user.update!(highlights: [ blob ])

user.highlights.count # => 2
user.highlights.first.filename # => "funky.jpg"
user.highlights.second.filename # => "town.jpg"
```

Rails 6.0のデフォルト設定では、添付ファイルのコレクションへの代入は、追加ではなく既存ファイルの置き換え操作になります。これにより、Active Recordでコレクションの関連付けに代入するときの振る舞いと一貫するようになります。

```ruby
user.highlights.attach(filename: "funky.jpg")
user.highlights.count # => 1

blob = ActiveStorage::Blob.create_after_upload!(filename: "town.jpg")
user.update!(highlights: [ blob ])

user.highlights.count # => 1
user.highlights.first.filename # => "town.jpg"
```

既存のものを削除せずに添付ファイルを新たに追加するには、`#attach`が利用できます。

```ruby
blob = ActiveStorage::Blob.create_after_upload!(filename: "town.jpg")
user.highlights.attach(blob)

user.highlights.count # => 2
user.highlights.first.filename # => "funky.jpg"
user.highlights.second.filename # => "town.jpg"
```

この新しい振る舞いは、設定で[`config.active_storage.replace_on_assign_to_many`][]を`true`にすることで利用できます。従来の振る舞いはRails 7.0で非推奨化され、Rails 7.1で削除される予定です。

[`config.active_storage.replace_on_assign_to_many`]: configuring.html#config-active-storage-replace-on-assign-to-many

### カスタム例外処理アプリケーション

無効な`Accept`または`Content-Type`リクエストヘッダーは例外を発生するようになりました。

デフォルトの[`config.exceptions_app`][]は、このエラーを特別に処理して対処します。
カスタム例外アプリケーションもこのエラーを処理する必要があります。そうしないと、そうしたリクエストに対してフォールバック用の例外アプリケーションが使われ、Railsが`500 Internal Server Error`を返すようになります。

[`config.exceptions_app`]: configuring.html#config-exceptions-app

Rails 5.1からRails 5.2へのアップグレード
-------------------------------------

Rails 5.2 の変更点について詳しくは[Rails 5.2のリリースノート](5_2_release_notes.html)を参照してください。

### Bootsnap

Rails 5.2 では[新規作成したアプリケーションのGemfile](https://github.com/rails/rails/pull/29313)にbootsnap gemが追加されました。`boot.rb`の`app:update`コマンドを実行するとセットアップが行われます。使いたい場合は、Gemfileにbootsnap gemを追加してください。

```ruby
# キャッシュにより起動時間を短縮する: config/boot.rbでrequireされる
gem 'bootsnap', require: false
gem "bootsnap", require: false
```

`boot.rb`を変更することでbootsnapをオフにすることもできます。

### 暗号化または署名付きcookieに有効期限情報が付与されました

セキュリティ向上のため、Railsでは暗号化または署名付きcookieに有効期限情報を埋め込むようになりました。

有効期限情報が埋め込まれたcookieは、Rails 5.1 以前のバージョンとの互換性はありません。

Rails 5.1 以前で新しいcookieを読み込みたい場合や、Rails 5.2 でうまくデプロイできるかどうかを確認したい場合は（必要に応じてロールバックできるようにしたい場合は）`Rails.application.config` の `action_dispatch.use_authenticated_cookie_encryption`を`false`に設定してください。

Rails 5.0からRails 5.1へのアップグレード
-------------------------------------

Rails 5.1 の変更点について詳しくは[Rails 5.1のリリースノート](5_1_release_notes.html)を参照してください。

### トップレベルの`HashWithIndifferentAccess`が緩やかに非推奨化された

アプリケーションでトップレベルの`HashWithIndifferentAccess`クラスを使っている場合、すぐでなくてもよいので`ActiveSupport::HashWithIndifferentAccess`に置き換えてください。

これは「緩やかな非推奨化」なので、しばらくは正常に動作し、非推奨警告も表示されません。ただし、この定数は将来削除されます。

また、こうしたオブジェクトのダンプを含むかなり古いYAMLドキュメントがある場合は、YAMLを再度読み込み・ダンプして、正しい定数が参照されるようにしておく必要があるかもしれません。また、読み込みについては今後も利用できます。

### `application.secrets`ですべてのキーをシンボルとして読み込むようになった

`config/secrets.yml`に保存されているアプリケーションの設定がネストしている場合、すべてのキーがシンボルとして読み込まれます。このため、文字列による設定へのアクセス方法を以下のように変更する必要があります。

変更前:

```ruby
Rails.application.secrets[:smtp_settings]["address"]
```

変更後:

```ruby
Rails.application.secrets[:smtp_settings][:address]
```

### 非推奨化された`render :text`と`render :nothing`サポートが削除された

ビューの`render :text`は今後利用できません。MIME typeを「`text/plain`」にしてテキストをレンダリングする新しい方法は、`render :plain`を使うことです。

`render :nothing`も同様に削除されるので、今後ヘッダーのみのレスポンスを返すには`head`メソッドをお使いください。
例: `head :ok`は、bodyをレンダリングせずにresponse 200を返します。

### 非推奨化された`redirect_to :back`サポートが削除された

Rails 5.0で非推奨化された`redirect_to :back`は、Rails 5.1で完全に削除されました。

今後は代わりに`redirect_back`をお使いください。`redirect_back`は、`HTTP_REFERER`が見つからない場合に使われる`fallback_location`オプションも受け取る点にご注意ください。

```ruby
redirect_back(fallback_location: root_path)
```

Rails 4.2からRails 5.0へのアップグレード
-------------------------------------

Rails 5.0 の変更点について詳しくは[Rails 5.0のリリースノート](5_0_release_notes.html)を参照してください。

### Ruby 2.2.2以上が必須

Ruby on Rails 5.0以降は、バージョン2.2.2以降のRubyのみをサポートします。
Rubyのバージョンが2.2.2以降であることを確認してから手順を進めてください。

### Active Record モデルは今後デフォルトで ApplicationRecord を継承する

Rails 4.2のActive Recordモデルは`ActiveRecord::Base`を継承していました。Rails 5.0では、すべてのモデルが`ApplicationRecord`を継承するようになりました。

アプリケーションのコントローラーが`ActionController::Base`に代わって`ApplicationController`を継承するように、アプリケーションのすべてのモデルが`ApplicationRecord`をスーパークラスとして使うようになりました。この変更により、アプリケーション全体のモデルの動作を1か所で変更できるようになりました。

Rails 4.2をRails 5.0にアップグレードする場合、`app/models/`ディレクトリに`application_record.rb`ファイルを追加し、このファイルに以下の設定を追加する必要があります。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
```

最後に、すべてのモデルが`ApplicationRecord`を継承するように変更し、動作を確認してください。

### `throw(:abort)`でコールバックチェインを停止する

Rails 4.2では、Active RecordやActive Modelで「before」系コールバックが`false`を返すと、すべてのコールバックチェインが停止する仕様でした。この場合、以後の「before」系コールバックは実行されず、コールバック内にラップされているアクションも実行されません。

Rails 5.0ではこの副作用が修正され、Active RecordやActive Modelのコールバックで`false`が返ってもコールバックチェインが停止しなくなりました。その代わり、今後コールバックチェインは`throw(:abort)`で明示的に停止する必要があります。

Rails 4.2をRails5.0にアップグレードした場合、こうしたコールバックで`false`が返ると従来同様コールバックチェインは停止しますが、この変更にともなう非推奨警告が表示されます。

この変更内容とその影響を十分理解しているのであれば、`config/application.rb`に以下の記述を追加して非推奨警告をオフにできます。

```ruby
ActiveSupport.halt_callback_chains_on_return_false = false
```

Active Supportのコールバックはこのオプションの影響を受けないことにご注意ください。Active Supportのチェーンはどのような値が返っても停止しません。

詳しくは[#17227](https://github.com/rails/rails/pull/17227)を参照してください。

### ActiveJob は今後デフォルトで ApplicationJob を継承する

Rails 4.2のActive Jobは`ActiveJob::Base`を継承しますが、Rails 5.0ではデフォルトで`ApplicationJob`を継承するよう変更されました。

Rails 4.2をRails 5.0にアップグレードする場合、`app/jobs/`ディレクトリに`application_job.rb`ファイルを追加し、このファイルに以下の設定を追加する必要があります。

```ruby
class ApplicationJob < ActiveJob::Base
end
```

これにより、すべてのjobクラスがActiveJob::Baseを継承するようになります。

詳しくは[#19034](https://github.com/rails/rails/pull/19034)を参照してください。

### Rails コントローラのテスト

#### ヘルパーメソッドの一部が`rails-controller-testing`に移転

`assigns`メソッドと`assert_template`メソッドは`rails-controller-testing` gemに移転しました。これらのメソッドを引き続きコントローラのテストで使いたい場合は、`Gemfile`に`gem "rails-controller-testing"`を追加してください。

テストでRSpecを使っている場合は、このgemのドキュメントで必須となっている追加の設定方法もご確認ください。

#### ファイルアップロード時の新しい振る舞い

ファイルアップロードのテストで`ActionDispatch::Http::UploadedFile`クラスを使っている場合、`Rack::Test::UploadedFile`クラスに変更する必要があります。

詳しくは[#26404](https://github.com/rails/rails/issues/26404)を参照してください。

### production環境での起動後は自動読み込みが無効になる

今後Railsがproduction環境で起動されると、自動読み込みがデフォルトで無効になります。

アプリケーションのeager loading（一括読み込み）は起動プロセスに含まれています。このため、トップレベルの定数についてはファイルを`require`しなくても問題なく利用でき、従来と同様に自動読み込みされます。

トップレベルより下で、実行時にのみ有効にする定数（通常のメソッド本体など）を定義した場合も、起動時にeager loadingされるので問題なく利用できます。

ほとんどのアプリケーションでは、この変更に関して特別な対応は不要です。ごくまれにproduction環境のアプリケーションで自動読み込みが必要な場合は、`Rails.application.config.enable_dependency_loading`をtrueに設定してください。

### XMLシリアライズのgem化

Railsの`ActiveModel::Serializers::Xml`は`activemodel-serializers-xml` gemに切り出されました。アプリケーションで今後もXMLシリアライズを使うには、`Gemfile`に`gem "activemodel-serializers-xml"`を追加してください。

### 古い`mysql`データベースアダプタのサポートを終了

Rails 5で古い`mysql`データベース アダプタのサポートが終了しました。原則として`mysql2`をお使いください。今後古いアダプタのメンテナンス担当者が決まれば、別のgemに切り出される予定です。

### デバッガのサポートを終了

Rails 5が必要とするRuby 2.2では、`debugger`はサポートされていません。代わりに、今後は`byebug`をお使いください。

### タスクやテストの実行には`bin/rails`を使うこと

Rails 5では、rakeに代わって`bin/rails`でタスクやテストを実行できるようになりました。原則として、多くのタスクやテストはrakeでも引き続き実行できますが、一部のタスクやテストは完全に`bin/rails`に移行しました。

今後テストの実行には`bin/rails test`をお使いください。

`rake dev:cache`は`bin/rails dev:cache`に変更されました。

アプリケーションのルートディレクトリの下で`bin/rails`を実行すると、利用可能なコマンドリストを表示できます。

### `ActionController::Parameters`は今後`HashWithIndifferentAccess`を継承しない

アプリケーションで`params`を呼び出すと、今後はハッシュではなくオブジェクトが返されます。現在使っているパラメーターがRailsで既に利用できている場合、変更は不要です。`permitted?`の状態にかかわらずハッシュを読み取れることが前提のメソッド（`slice`メソッドなど）にコードが依存している場合、アプリケーションを以下のようにアップグレードして、`permit`を指定してからハッシュに変換する必要があります。

```ruby
params.permit([:proceed_to, :return_to]).to_h
```

### `protect_from_forgery`は今後デフォルトで`prepend: false`に設定される

`protect_from_forgery`は今後デフォルトで`prepend: false`に設定されます。これにより、`protect_from_forgery`はアプリケーションで呼び出される時点でコールバックチェインに挿入されます。`protect_from_forgery`を常に最初に実行したい場合は、アプリケーションの設定で`protect_from_forgery prepend: true`を指定する必要があります。

### デフォルトのテンプレートハンドラは今後rawになる

拡張子がテンプレートハンドラになっていないファイルは、今後rawハンドラで出力されるようになります。従来のRailsでは、このような場合にはERBテンプレートハンドラで出力されました。

ファイルをrawハンドラで出力したくない場合は、ファイルに明示的に拡張子を指定し、適切なテンプレート ハンドラで処理されるようにしてください。

### テンプレート依存関係の指定にワイルドカードマッチが追加された

テンプレート依存関係をワイルドカードマッチングで指定できるようになりました。以下のテンプレートを例に説明します。

```erb
<% # Template Dependency: recordings/threads/events/subscribers_changed %>
<% # Template Dependency: recordings/threads/events/completed %>
<% # Template Dependency: recordings/threads/events/uncompleted %>
```

上のようなテンプレートは、以下のようにワイルドカードを使えば1行で設定できます。

```erb
<% # Template Dependency: recordings/threads/events/* %>
```

### `ActionView::Helpers::RecordTagHelper`は外部のgemに移動（`record_tag_helper`）

`content_tag_for`と`div_for`が削除され、今後は`content_tag`のみの利用が推奨されます。これらの古いメソッドを使い続けたい場合、`record_tag_helper` gemを`Gemfile`に追加してください。

```ruby
gem "record_tag_helper", "~> 1.0"
```

詳しくは[#18411](https://github.com/rails/rails/pull/18411)を参照してください。

### `protected_attributes` gemのサポートが終了

`protected_attributes` gemのサポートはRails 5で終了しました。

### `activerecord-deprecated_finders` gemのサポートが終了

`activerecord-deprecated_finders` gemのサポートはRails 5で終了しました。

### `ActiveSupport::TestCase`でのテストは今後デフォルトでランダムに実行される

アプリケーションのテストのデフォルトの実行順序は、従来の`:sorted`から`:random`に変更されました。`:sorted`に戻すには以下のオプションを指定します。

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.active_support.test_order = :sorted
end
```

### `ActionController::Live` は`Concern`に変更された

コントローラにincludeされている別のモジュールに`ActionController::Live`が`include`されている場合、`ActiveSupport::Concern`を`extend`するコードの追加も必要です。または、`StreamingSupport`がincludeされてから、`self.included`フックを使って`ActionController::Live`をコントローラに直接`include`することもできます。

アプリケーションで独自のストリーミングモジュールを使っている場合、以下のコードはproduction環境で正常に動作しなくなる可能性があります。

```ruby
# Warden/Devise で認証するストリーミングコントローラでの回避方法を示すコード
# https://github.com/plataformatec/devise/issues/2332 を参照
# 上のissueではルーター内での認証で解決する方法もアドバイスされている
class StreamingSupport
  include ActionController::Live # Rails 5 の production モードではこの行は動作しない
  # extend ActiveSupport::Concern # この行をコメント解除することで上の行が動作するようになる

  def process(name)
    super(name)
  rescue ArgumentError => e
    if e.message == 'uncaught throw :warden'
      throw :warden
    else
      raise e
    end
  end
end
```

### フレームワークの新しいデフォルト設定

#### Active Recordの`belongs_to`はデフォルトオプションで必須

`belongs_to`関連付けが存在しない場合、バリデーションエラーが発生するようになりました。

なお、この機能は関連付けごとに`optional: true`を指定してオフにできます。

新しいアプリケーションでは、このデフォルト設定が自動で有効になります。この設定を既存のアプリケーションに追加するには、イニシャライザでこの機能をオンにする必要があります

```ruby
config.active_record.belongs_to_required_by_default = true
```

これはデフォルトですべてのモデルに対してグローバルに設定されますが、モデルごとに設定をオーバーライドすることもできます。これは、モデルを移行してデフォルトで必要な関連付けをすべてのモデルに持たせるのに便利です。

```ruby
class Book < ApplicationRecord
  # モデルがデフォルトで必要な関連付けを持つ準備ができていない場合の設定

  self.belongs_to_required_by_default = false
  belongs_to(:author)
end

class Car < ApplicationRecord
  # モデルがデフォルトで必要な関連付けを持つ準備ができた後の設定

  self.belongs_to_required_by_default = true
  belongs_to(:pilot)
end
```

#### フォーム単位のCSRFトークン

Rails 5 では、JavaScriptで作成されたフォームによるコードインジェクション攻撃に対応するため、フォーム単位のCSRFトークンをサポートします。このオプションがオンの場合、アクションやメソッド固有のCSRFトークンがアプリケーションのフォームごとに個別に生成されるようになります。

```ruby
config.action_controller.per_form_csrf_tokens = true
```

#### OriginチェックによるCSRF保護

アプリケーションで、CSRF保護の一環としてHTTP `Origin`ヘッダによるサイトのオリジンチェックを設定できるようになりました。以下の設定をtrueにすることで有効になります。

```ruby
config.action_controller.forgery_protection_origin_check = true
```

#### Action Mailerのキュー名がカスタマイズ可能に

デフォルトのメーラー キュー名は`mailers`です。新しい設定オプションを使うと、以下のようにキュー名をグローバルに変更できます。

```ruby
config.action_mailer.deliver_later_queue_name = :new_queue_name
```

#### Action Mailerのビューでフラグメントキャッシュをサポート

設定ファイルの[`config.action_mailer.perform_caching`][]で、Action Mailerのビューでキャッシュをサポートするかどうかを指定できます。

```ruby
config.action_mailer.perform_caching = true
```

[`config.action_mailer.perform_caching`]: configuring.html#config-action-mailer-perform-caching

#### `db:structure:dump`の出力形式のカスタマイズ

`schema_search_path`などのPostgreSQL拡張を使っている場合、スキーマのダンプ方法を指定できます。以下のように`:all`を指定するとすべてのダンプが生成され、`:schema_search_path`を指定するとスキーマ検索パスからダンプが生成されます。

```ruby
config.active_record.dump_schemas = :all
```

#### サブドメインでのHSTSを有効にするSSLオプション

サブドメインで [HSTS（HTTP Strict Transport Security）](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Strict-Transport-Security)を有効にするには、以下の設定を使います。

```ruby
config.ssl_options = { hsts: { subdomains: true } }
```

#### レシーバのタイムゾーンを保護する

Ruby 2.4を利用している場合、`to_time`の呼び出しでレシーバのタイムゾーンを変更しないようにできます。

```ruby
ActiveSupport.to_time_preserves_timezone = false
```

### JSON・JSONBのシリアライズに関する変更点

Rails 5.0では、JSON属性やJSONB属性をシリアライズ・デシリアライズする方法が変更されました。これにより、たとえばActive Recordである`String`に等しいカラムを設定しても、その文字列を`Hash`に変換せず、その文字列のみを返すようになります。この変更はモデル同士がやりとりするコードに限定されず、`db/schema.rb`で設定される`:default`カラムにも影響します。`String`に等しいカラムを設定せず、`Hash`を渡すようにしてください。これにより、JSON文字列への変換や逆変換が自動で行われるようになります。

Rails 4.1からRails 4.2へのアップグレード
-------------------------------------

### web-console gem

最初に`Gemfile`の`development`グループに`gem "web-console", "~> 2.0"`を追加し、次に`bundle install`を実行してください（このgemはRailsを過去バージョンからアップグレードした場合には含まれないので、手動で追加する必要があります）。gemのインストール完了後、`<%= console %>`などのコンソールヘルパーへの参照をビューに追加するだけで、どのビューでもコンソールを利用できるようになります。このコンソールは、development環境のビューで表示されるすべてのエラーページにも表示されます。

### responders gem

`respond_with`およびクラスレベルの`respond_to`メソッドは、`responders` gemに切り出されました。これらのメソッドを使いたい場合は、`Gemfile`に`gem "responders", "~> 2.0"`と記述するだけで利用できます。今後、`respond_with`呼び出しやクラスレベルの`respond_to`呼び出しは、`responders` gemなしでは動作しません。

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  respond_to :html, :json

  def show
    @user = User.find(params[:id])
    respond_with @user
  end
end
```

以下のようなインスタンスレベルの`respond_to`は今回のアップグレードの影響を受けないので、gemを追加する必要はありません。

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end
end
```

詳しくは[#16526](https://github.com/rails/rails/pull/16526)を参照してください。

### トランザクションコールバックのエラー処理

現在のActive Recordでは、`after_rollback`や`after_commit`コールバックでの例外を抑制しており、例外はログにのみ出力されます。次のバージョンからは、これらのエラーは抑制されなくなりますのでご注意ください。今後は他のActive Recordコールバックと同様のエラー処理を行います。

`after_rollback`コールバックや`after_commit`コールバックを定義すると、この変更にともなう非推奨警告が表示されるようになりました。この変更内容を十分理解し、受け入れる準備ができているのであれば、`config/application.rb`に以下の記述を行なうことで非推奨警告が表示されないようにすることができます。

```ruby
config.active_record.raise_in_transactional_callbacks = true
```

詳しくは、[#14488](https://github.com/rails/rails/pull/14488)および[#16537](https://github.com/rails/rails/pull/16537)を参照してください。

### テストケースの実行順序

Rails 5.0のテストケースは、デフォルトでランダムに実行されるよう変更される予定です。この変更に備えて、テスト実行順を明示的に指定する`active_support.test_order`という新しい設定オプションがRails 4.2に導入されました。このオプションを使うと、たとえばテスト実行順を現行の仕様のままにしておきたい場合に`:sorted`を指定することも、ランダム実行を今のうちに導入したい場合に`:random`を指定することも可能になります。

このオプションに値が指定されていないと、非推奨警告が表示されます。非推奨警告が表示されないようにするには、test環境に以下の記述を追加します。

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.active_support.test_order = :sorted # `:random`にしてもよい
end
```

### シリアル化属性

`serialize :metadata, JSON`などのカスタムコーダーを使っている場合に、シリアル化属性（serialized attribute）に`nil`を代入すると、コーダー内で`nil`値を渡す（`JSON`コーダーを使う場合の`"null"`など）のではなく、データベースに`NULL`として保存されるようになりました。

### Productionログのレベル

Rails 5のproduction環境では、デフォルトのログレベルが`:info`から`:debug`に変更される予定です。現在のログレベルを変更したくない場合は`production.rb`に以下の行を追加してください。

```ruby
# `:info`を指定すると現在のデフォルト設定が使われ、
# `:debug`を指定すると今後のデフォルト設定が使われる
config.log_level = :info
```

### Railsテンプレートの`after_bundle`

Railsテンプレートを利用し、かつすべてのファイルを（Gitなどで）バージョン管理している場合、生成されたbinstubをバージョン管理システムに追加できません。これは、binstubの生成がbundlerの実行前に行われるためです。

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
```

この問題を回避するために、`git`呼び出しを`after_bundle`ブロック内に置けるようになりました。こうすることで、binstubの生成が終わってからbundlerが実行されます。

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

### RailsのHTMLサニタイザ

アプリケーションでHTMLの断片をサニタイズする方法に新しい選択肢が追加され、従来の伝統的なHTMLスキャンによるサニタイズは公式に非推奨化されました。現在推奨される方法は[`rails-html-sanitizer`](https://github.com/rails/rails-html-sanitizer)です。

これにより、`sanitize`、`sanitize_css`、`strip_tags`、および`strip_links`メソッドは新しい実装に基いて動作するようになります。

新しいサニタイザは、内部で[Loofah](https://github.com/flavorjones/loofah)を使っています。そしてLoofahはNokogiriを使っています。Nokogiriで使われているXMLパーサーはCとJavaの両方で記述されているので、利用するRubyのバージョンにかかわらずサニタイズが高速化されるようになりました。

新しいRailsでは`sanitize`メソッドが更新され、`Loofah::Scrubber`で強力なスクラブを行なえます。スクラブの利用例は[こちら](https://github.com/flavorjones/loofah#loofahscrubber)を参照してください。

`PermitScrubber`および`TargetScrubber`という2つのスクラバーが新たに追加されました。詳しくは、[gemのReadme](https://github.com/rails/rails-html-sanitizer)を参照してください。

`PermitScrubber`および`TargetScrubber`のドキュメントには、どの要素をどのタイミングで除去すべきかを完全に制御する方法が記載されています。

従来のサニタイザ実装が必要な場合は、アプリケーションの`Gemfile`に`rails-deprecated_sanitizer`を追加してください。

```ruby
gem "rails-deprecated_sanitizer"
```

### RailsのDOMのテスト

`assert_tag`などを含む[`TagAssertions`](https://api.rubyonrails.org/classes/ActionDispatch/Assertions/TagAssertions.html)モジュールは[非推奨](https://github.com/rails/rails/blob/6061472b8c310158a2a2e8e9a6b81a1aef6b60fe/actionpack/lib/action_dispatch/testing/assertions/dom.rb)になりました。今後は、ActionViewから[rails-dom-testing gem](https://github.com/rails/rails-dom-testing)に移行した`SelectorAssertions`モジュールの`assert_select`メソッドが推奨されます。

### マスク済み真正性トークン

SSL攻撃を緩和するために、`form_authenticity_token`がマスクされるようになりました。これにより、このトークンはリクエストのたびに変更されます。トークンのバリデーションはマスク解除（unmasking）とそれに続く復号（decrypting）によって行われます。この変更により、Railsアプリケーション以外のフォームから送信される、静的なセッションCSRFトークンに依存するリクエストを検証する際には、このマスク済み真正性トークンを常に考慮する必要がある点にご注意ください。

### Action Mailer

従来は、メーラークラスでメーラーメソッドを呼び出すと、該当するインスタンスメソッドが直接実行されました。Active Jobと`#deliver_later`メソッドの導入に伴い、この動作が変更されました。Rails 4.2では、これらのインスタンスメソッド呼び出しは`deliver_now`や`deliver_later`が呼び出されるまで実行が延期されます。以下に例を示します。

```ruby
class Notifier < ActionMailer::Base
  def notify(user)
    puts "Called"
    mail(to: user.email)
  end
end
```

```ruby
mail = Notifier.notify(user) # Notifier#notifyはこの時点では呼び出されない
mail = mail.deliver_now     # "Called"を出力する
```

この変更によって実行結果が大きく変わるアプリケーションはそれほどないはずです。ただし、メーラー以外のメソッドを同期的に実行したい場合で、かつ従来の同期的なプロキシの振る舞いに依存している場合は、これらのメソッドをメーラークラスにクラスメソッドとして直接定義する必要があります。

```ruby
class Notifier < ActionMailer::Base
  def self.broadcast_notifications(users, ...)
    users.each { |user| Notifier.notify(user, ...) }
  end
end
```

### 外部キーのサポート

マイグレーションDSLが拡張され、外部キー定義をサポートするようになりました。foreigner gemを使っていた場合は、この機会に削除するとよいでしょう。Railsの外部キーサポートは、foreignerの全機能ではなく、一部のみである点にご注意ください。このため、foreignerの定義を必ずしもRailsのマイグレーションDSLに置き換えられないことがあります。

移行手順は次のとおりです。

1. `Gemfile`の`gem "foreigner"`を削除する
2. `bundle install`を実行する
3. `bin/rake db:schema:dump`を実行する
4. 外部キー定義と必要なオプションが`db/schema.rb`にすべて含まれていることを確認する

Rails 4.0からRails 4.1へのアップグレード
-------------------------------------

### リモート `<script>` タグのCSRF保護

これを行わないと、「なぜかテストがパスしない」「`<script>`ウィジェットがおかしい！」などという結果になりかねません。

JavaScriptレスポンスを伴うGETリクエストもCSRF（クロスサイトリクエストフォージェリ）保護の対象となりました。これは、サイトの`<script>`タグのJavaScriptコードが第三者のサイトから参照されて重要なデータが奪取されないよう保護するためのものです。

つまり、以下を使う機能テストや結合テストではCSRF保護が発動します。

```ruby
get :index, format: :js
```

`XmlHttpRequest`を明示的にテストするには、以下のように書き換えます。

```ruby
xhr :get, :index, format: :js
```

NOTE: 自サイトの`<script>`はクロスオリジンとして扱われるため、同様にブロックされます。JavaScriptを実際に`<script>`タグから読み込む場合は、そのアクションでCSRF保護を明示的にスキップしなければなりません。

### spring gem

アプリケーションのプリローダーとしてspring gemを使う場合は、以下を行う必要があります。

1. `gem "spring", group: :development` を `Gemfile`に追加する
2. `bundle install`を実行してspringをインストールする
3. `bundle exec spring binstub`を実行してspringのbinstubを生成する

NOTE: ユーザーが定義したrakeタスクはデフォルトでdevelopment環境で動作するようになります。これらのrakeタスクを他の環境でも実行したい場合は[spring README](https://github.com/rails/spring#rake)を参考にしてください。

### `config/secrets.yml`

新しい`secrets.yml`に秘密鍵を保存したい場合は以下の手順を実行します。

1. `secrets.yml`ファイルを`config`フォルダ内に作成し、以下の内容を追加する。

    ```yaml
    development:
      secret_key_base:

    test:
      secret_key_base:

    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    ```

2. `secret_token.rb`イニシャライザに記載されている既存の `secret_key_base`の秘密鍵を取り出して`SECRET_KEY_BASE`環境変数に設定し、Railsアプリケーションをproductionで実行するすべてのユーザーが秘密鍵の恩恵を受けられるようにする。あるいは、`secret_token.rb`イニシャライザにある既存の`secret_key_base`を`secrets.yml`のproductionセクションにコピーし、'<%= ENV["SECRET_KEY_BASE"] %>'を置き換えることもできます。

3. `secret_token.rb`イニシャライザを削除する。

4. `development`セクションと`test`セクションで使う新しい鍵を`rake secret`で生成する。

5. サーバーを再起動する。

### テストヘルパーの変更

テストヘルパーに含まれている`ActiveRecord::Migration.check_pending!`呼び出しは削除できます。このチェックは`require "rails/test_help"`で自動的に行われるようになりました。この呼び出しを削除しなくても悪影響は生じません。

### cookieシリアライザ

Rails 4.1より前に作成されたアプリケーションでは、`Marshal`を使ってcookie値を署名済みまたは暗号化したcookies jarにシリアライズしていました。アプリケーションで新しい`JSON`ベースのフォーマットを使いたい場合、以下のような内容のイニシャライザファイルを追加できます。

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
```

これにより、`Marshal`でシリアライズされた既存のcookieを、新しい`JSON`ベースのフォーマットに透過的に移行できます。

`:json`または`:hybrid`シリアライザを使う場合、一部のRubyオブジェクトがJSONとしてシリアライズされない可能性があることにご注意ください。たとえば、`Date`オブジェクトや`Time`オブジェクトは文字列としてシリアライズされ、`Hash`のキーは文字列に変換されます。

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2014
    redirect_to action: 'read_cookie'
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2014-03-20"
  end
end
```

cookieには文字列や数字などの単純なデータだけを保存することをおすすめします。cookieに複雑なオブジェクトを保存しなければならない場合は、以後のリクエストでcookieから値を読み出すときに自分で変換する必要があります。

これは、cookieセッションストアを使う場合の`session`や`flash`ハッシュについても該当します。

### Flash構造の変更

Flashメッセージのキーが[文字列に正規化](https://github.com/rails/rails/commit/a668beffd64106a1e1fedb71cc25eaaa11baf0c1)されました。シンボルまたは文字列のどちらでもアクセスできます。Flashのキーを取り出すと常に文字列になります。

```ruby
flash["string"] = "a string"
flash[:symbol] = "a symbol"

# Rails < 4.1
flash.keys # => ["string", :symbol]

# Rails >= 4.1
flash.keys # => ["string", "symbol"]
```

Flashメッセージのキーは必ず文字列と比較してください。

### JSONの扱いの変更点

Rails 4.1ではJSONの扱いが大きく変更された点が4つあります。

#### MultiJSONの廃止

MultiJSONはその役目を終えてRailsから削除されました（[#10576](https://github.com/rails/rails/pull/10576)）。

アプリケーションがMultiJSONに直接依存している場合、以下のような対応方法があります。

1. 'multi_json'を`Gemfile`に追加する。ただしこのGemは将来使えなくなるかもしれません。

2. `obj.to_json`と`JSON.parse(str)`を用いてMultiJSONから乗り換える。

WARNING: `MultiJson.dump` と `MultiJson.load`をそれぞれ`JSON.dump`と`JSON.load`に単純に置き換えては「いけません」。これらのJSON gem APIは任意のRubyオブジェクトをシリアライズおよびデシリアライズするためのものであり、一般に[安全ではありません](https://www.ruby-doc.org/stdlib-2.2.2/libdoc/json/rdoc/JSON.html#method-i-load)。

#### JSON gemの互換性

これまでのRailsでは、JSON gemとの互換性に何らかの問題が生じていました。Railsアプリケーション内の`JSON.generate`と`JSON.dump`ではときたまエラーが生じることがありました。

Rails 4.1では、Rails自身のエンコーダをJSON gemから切り離すことでこれらの問題が修正されました。JSON gem APIは今後も正常に動作しますが、その代わりJSON gem APIからRails特有の機能にアクセスできなくなります。以下に例を示します。

```ruby
class FooBar
  def as_json(options = nil)
    { foo: 'bar' }
  end
end
```

```irb
irb> FooBar.new.to_json
=> "{\"foo\":\"bar\"}"
irb> JSON.generate(FooBar.new, quirks_mode: true)
=> "\"#<FooBar:0x007fa80a481610>\""
```

#### 新しいJSONエンコーダ

Rails 4.1のJSONエンコーダは、JSON gemを使うように書き直されました。この変更によるアプリケーションへの影響はほとんどありません。ただし、エンコーダが書き直された際に以下の機能がエンコーダから削除されました。

1. データ構造の循環検出
2. `encode_json`フックのサポート
3. `BigDecimal`オブジェクトを文字列ではなく数値としてエンコードするオプション

アプリケーションがこれらの機能に依存している場合は、[`activesupport-json_encoder`](https://github.com/rails/activesupport-json_encoder) gemをGemfileに追加することで以前の状態に戻せます。

#### TimeオブジェクトのJSON形式表現

日時に関連するコンポーネント（`Time`、`DateTime`、`ActiveSupport::TimeWithZone`）を持つオブジェクトに対して`#as_json`を実行すると、デフォルトで値がミリ秒単位の精度で返されるようになりました。ミリ秒より精度の低い従来方式にしておきたい場合は、イニシャライザに以下を設定してください。

```ruby
ActiveSupport::JSON::Encoding.time_precision = 0
```

### インラインのコールバックブロックで`return`を利用できなくなる

以前のRailsでは、インラインコールバックブロックで以下のように`return`を書くことが許容されていました。

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { return false } # 良くない
end
```

この動作は決して意図的にサポートされたものではありません。`ActiveSupport::Callbacks`が書き直され、上のような動作はRails 4.1では許容されなくなりました。インラインコールバックブロックで`return`文を書くと、コールバック実行時に`LocalJumpError`が発生するようになりました。

インラインのコールバックブロックで`return`を使っている場合、以下のようにリファクタリングすることで、返された値として評価されるようになります。

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { false } # 良い
end
```

`return`を使いたい場合は、以下のように明示的にメソッドを定義することが推奨されます。

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save :before_save_callback # よい

  private
    def before_save_callback
      false
    end
end
```

この変更は、Railsでコールバックを使っている多くの箇所に適用されます。これにはActive RecordとActive ModelのコールバックやAction Controllerのフィルタ（`before_action` など）も含まれます。

詳しくは[#13271](https://github.com/rails/rails/pull/13271)を参照してください。

### Active Recordのフィクスチャで定義されたメソッド

Rails 4.1では、各フィクスチャのERBは独立したコンテキストで評価されます。このため、あるフィクスチャで定義されたヘルパーメソッドは他のフィクスチャでは利用できません。

ヘルパーメソッドを複数のフィクスチャで共用するには、`test_helper.rb`で定義したモジュールを以下のように新しく導入された`ActiveRecord::FixtureSet.context_class`で`include`する必要があります。

```ruby
module FixtureFileHelpers
  def file_sha(path)
    OpenSSL::Digest::SHA256.hexdigest(File.read(Rails.root.join('test/fixtures', path)))
  end
end

ActiveRecord::FixtureSet.context_class.include FixtureFileHelpers
```

### I18nオプションでavailable_localesリストの利用が強制される

Rails 4.1からI18nの`enforce_available_locales`オプションがデフォルトで`true`になりました。この設定にすると、I18nに渡されるすべてのロケールは、available_localesリストで宣言されていなければ使えません。

この機能をオフにしてI18nですべての種類のロケールオプションを使えるようにするには、以下のように変更します。

```ruby
config.i18n.enforce_available_locales = false
```

`enforce_available_locales`はセキュリティ対策のために追加された点にご注意ください。つまり、アプリケーションが認識していないロケールを持つユーザー入力がロケール情報として使われないようにするのが目的です。従って、やむを得ない理由がない限りこのオプションはfalseにしないでください。

### リレーションに対する破壊的メソッド呼び出し

`Relation`には`#map!`や`#delete_if`などの破壊的メソッド（mutator method）が含まれなくなりました。これらのメソッドを使いたい場合は`#to_a`を呼び出して`Array`に変更してからにしてください。

この変更は、`Relation`で破壊的メソッドを直接呼び出すことによる奇妙なバグや混乱を防ぐために行われました。

```ruby
# 以前の破壊的な呼び出し方法は使わないこと
Author.where(name: 'Hank Moody').compact!

# 今後はこの破壊的な呼び出し方法を使うこと
authors = Author.where(name: 'Hank Moody').to_a
authors.compact!
```

### デフォルトスコープの変更

デフォルトのスコープは、条件をチェインした場合にオーバーライドされなくなりました。

以前のバージョンでは、モデルで`default_scope`を定義すると、同じフィールドでチェインした条件によってオーバーライドされました。現在は、他のスコープと同様、マージされるようになりました。

変更前:

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

変更後:

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'inactive'
```

以前と同じ動作に戻したい場合は、`unscoped`、`unscope`、`rewhere`、`except`を用いて`default_scope`の条件を明示的に除外する必要があります。

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { unscope(where: :state).where(state: 'active') }
  scope :inactive, -> { rewhere state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

### 文字列コンテンツのレンダリング

Rails 4.1の`render`に`:plain`、`:html`、`:body`オプションが導入されました。以下のようにContent-Typeヘッダーを指定できるため、文字列ベースのコンテンツ表示にはこれらのオプションの利用が推奨されます。

* `render :plain`を実行すると、Content-Typeヘッダーが`text/plain`に設定される
* `render :html`を実行すると、Content-Typeヘッダーが`text/html`に設定される
* `render :body`を実行すると、Content-Typeヘッダーは「設定されない」

セキュリティ上の観点から、レスポンスのbodyにマークアップを含めない場合には`render :plain`を指定すべきです。これによって多くのブラウザが安全でないコンテンツをエスケープできるからです。

今後のバージョンでは、`render :text`は非推奨にされる予定です。今のうちに、正しい`:plain`、`:html`、`:body`オプションに切り替えてください。`render :text`を使うと`text/html`で送信されるため、セキュリティ上のリスクが生じる可能性があります。

### PostgreSQLのデータ型'json'と'hstore'について

Rails 4.1では、PostgreSQLの`json`カラムと`hstore`カラムを、文字列をキーとするRubyの`Hash`に対応付けるようになりました。なお、以前のバージョンでは`HashWithIndifferentAccess`が使われていました。この変更は、Rails 4.1以降ではこれらのデータ型にシンボルでアクセスできなくなるということを意味します。`store_accessors`メソッドは`json`カラムや`hstore`カラムに依存しているので、同様にシンボルでのアクセスが行えなくなります。今後は常に文字列をキーにするようにしてください。

### `ActiveSupport::Callbacks`では明示的にブロックを利用すること

Rails 4.1からは`ActiveSupport::Callbacks.set_callback`の呼び出しに明示的にブロックを渡すことが期待されます。これは、`ActiveSupport::Callbacks`がRails 4.1リリースに伴って大幅に書き換えられたことによるものです。

```ruby
# Rails 4.0の場合
set_callback :save, :around, ->(r, &block) { stuff; result = block.call; stuff }

# Rails 4.1の場合
set_callback :save, :around, ->(r, block) { stuff; result = block.call; stuff }
```

Rails 3.2からRails 4.0へのアップグレード
-------------------------------------

Railsアプリケーションのバージョンが3.2より前の場合、まず3.2へのアップグレードを完了してからRails 4.0へのアップグレードを開始してください。

以下の変更は、アプリケーションをRails 4.0にアップグレードするためのものです。

### HTTP PATCH

Rails 4では、`config/routes.rb`でRESTfulなリソースが宣言されたときに、更新用の主要なHTTP verbとして`PATCH`が使われるようになりました。`update`アクションは従来どおり利用でき、`PUT`リクエストは今後も`update`アクションにルーティングされます。標準的なRESTfulのみを使っている場合、これに関する変更は不要です。

```ruby
resources :users
```

```erb
<%= form_for @user do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update
    # 変更不要:PATCHが望ましいがPUTも引き続き使える
  end
end
```

ただし、`form_for`を用いてリソースを更新しており、`PUT` HTTPメソッドを使うカスタムルーティングと連動している場合は、変更が必要です。

```ruby
resources :users do
  put :update_name, on: :member
end
```

```erb
<%= form_for [ :update_name, @user ] do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update_name
    # 変更が必要: form_forは、存在しないPATCHルートを探そうとする
  end
end
```

このアクションがパブリックAPIで使われておらず、HTTPメソッドを自由に変更できるのであれば、以下のようにルーティングを更新して`patch`を`put`の代わりに利用できます。

```ruby
resources :users do
  patch :update_name, on: :member
end
```

Rails 4で`PUT`リクエストを`/users/:id`に送信すると、従来と同様`update`にルーティングされます。このため、実際のPUTリクエストを受け取るAPIは今後も利用できます。この場合、`PATCH`リクエストも`/users/:id`経由で`update`アクションにルーティングされます。

このアクションがパブリックAPIで使われており、HTTPメソッドを自由に変更できないのであれば、フォームを更新して`PUT`を代わりに使えます。

```erb
<%= form_for [ :update_name, @user ], method: :put do |f| %>
```

PATCHおよびこの変更が行われた理由について詳しくは、Railsブログの[この記事](https://weblog.rubyonrails.org/2012/2/26/edge-rails-patch-is-the-new-primary-http-method-for-updates/)を参照してください。

#### メディアタイプに関するメモ

[JSON Patch](https://tools.ietf.org/html/rfc6902)は、`PATCH` verbの正誤表で指摘されている「[`PATCH`では異なるメディアタイプを使う必要がある](https://www.rfc-editor.org/errata_search.php?rfc=5789)」に該当するものの１つです。RailsはJSON Patchをネイティブではサポートしませんが、サポートの追加は簡単です。

```ruby
# コントローラに以下を書く
def update
  respond_to do |format|
    format.json do
      # 部分的な変更を行なう
      @article.update params[:article]
    end

    format.json_patch do
      # 複雑な変更を行なう
    end
  end
end
```

```ruby
# config/initializers/json_patch.rb に以下を書く
Mime::Type.register 'application/json-patch+json', :json_patch
```

JSON Patchは最近RFC化されたばかりなのでRubyライブラリはそれほどありません。Aaron Pattersonの [hana](https://github.com/tenderlove/hana) gemが代表的ですが、最新の仕様変更をすべてサポートしているわけではありません。

### Gemfile

Rails 4.0の`Gemfile`から`assets`グループが削除されました。アップグレード時にはこの記述を`Gemfile`から削除する必要があります。アプリケーションの`config/application.rb`ファイルも以下のように更新する必要があります。

```ruby
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
```

### vendor/plugins

Rails 4.0 では`vendor/plugins` 読み込みのサポートは完全に終了しました。利用するプラグインはすべてgemに切り出して`Gemfile`に追加しなければなりません。何らかの理由でプラグインをgemにしないのであれば、プラグインを`lib/my_plugin/*`に移動し、適切な初期化の記述を`config/initializers/my_plugin.rb`に書いてください。

### Active Record

* [関連付けに関する若干の不整合](https://github.com/rails/rails/commit/302c912bf6bcd0fa200d964ec2dc4a44abe328a6)のため、Rails 4.0ではActive Recordからidentity mapが削除されました。アプリケーションでこの機能を手動で有効にしたい場合は、今や無効になった`config.active_record.identity_map`を削除する必要があるでしょう。

* コレクション関連付けの`delete`メソッドに、レコードの他に`Integer`や`String`引数もレコードidとして渡せるようになりました。これにより`destroy`メソッドの動作にかなり近くなりました。以前はこのような引数を使うと`ActiveRecord::AssociationTypeMismatch`例外が発生しました。Rails 4.0からは、`delete`メソッドを使うと、与えられたidにマッチするレコードを自動的に探索するようになりました。

* Rails 4.0では、カラム名やテーブル名を変更すると、関連するインデックスも自動的にリネームされるようになりました。インデックス名を変更するためだけのマイグレーションは今後不要です。

* Rails 4.0の`serialized_attributes`メソッドと`attr_readonly`メソッドは、クラスメソッドとしてのみ使う形に変更されました。これらのメソッドをインスタンスメソッドとして利用することは非推奨となったため、行わないでください。たとえば`self.serialized_attributes`は`self.class.serialized_attributes`のようにクラスメソッドとしてお使いください。

* デフォルトのコーダーを使う場合、シリアル化属性に`nil`を渡すと、YAML全体にわたって`nil`値を渡す（`"--- \n...\n"`）のではなく、`NULL`としてデータベースに保存されます。

* Rails 4.0ではStrong Parametersの導入に伴い、`attr_accessible`と`attr_protected`が削除されました。これらを引き続き使いたい場合は、[protected_attributes](https://github.com/rails/protected_attributes) gemを導入することでスムーズにアップグレードできます。

* Protected Attributesを使っていない場合は、`whitelist_attributes`や`mass_assignment_sanitizer`オプションなど、このgemに関連するすべてのオプションを削除できます。

* Rails 4.0のスコープでは、Procやlambdaなどの呼び出し可能なオブジェクトの利用が必須となりました。

    ```ruby
    scope :active, where(active: true)

    # 上のコードは以下のように変更が必要
    scope :active, -> { where active: true }
    ```

* Rails 4.0では`ActiveRecord::Fixtures`が非推奨となりました。今後は`ActiveRecord::FixtureSet`をお使いください。

* Rails 4.0では`ActiveRecord::TestCase`が非推奨となりました。今後は`ActiveSupport::TestCase`をお使いください。

* Rails 4.0では、ハッシュを用いる旧来のfinder APIが非推奨となりました。これまでこうしたfinderオプションを受け付けていたメソッドは、これらのオプションを今後受け付けなくなりますのでご注意ください。たとえば、`Book.find(:all, conditions: { name: '1984' })`は非推奨です。今後は`Book.where(name: '1984')`をご利用ください。

* 動的なメソッドは、`find_by_...`と`find_by_...!`を除いて非推奨になりました。以下のように変更してください。

      * `find_all_by_...`: 今後は`where(...)`を使う
      * `find_last_by_...`: 今後は`where(...).last`を使う
      * `scoped_by_...`: 今後は`where(...)`を使う
      * `find_or_initialize_by_...`: 今後は`find_or_initialize_by(...)`を使う
      * `find_or_create_by_...`: 今後は`find_or_create_by(...)`を使う

* 旧来のfinderメソッドが配列を返していたのに対し、`where(...)`はリレーションを返します。`Array`が必要な場合は, `where(...).to_a`をお使いください。

* これらの同等なメソッドが実行するSQLは、従来の実装のSQLと同じとは限りません。

* 旧来のfinderメソッドを再度有効にしたい場合は、[activerecord-deprecated_finders](https://github.com/rails/activerecord-deprecated_finders) gemを利用できます。

* Rails 4.0 では、`has_and_belongs_to_many`リレーションで2番目のテーブル名の共通プレフィックスを除去する際に、デフォルトでjoin tableを使うよう変更されました。共通プレフィックスがあるモデル同士の`has_and_belongs_to_many`リレーションでは、以下のように必ず`join_table`オプションを指定する必要があります。

    ```ruby
    class CatalogCategory < ActiveRecord::Base
      has_and_belongs_to_many :catalog_products, join_table: 'catalog_categories_catalog_products'
    end
    ```

    ```ruby
    class CatalogProduct < ActiveRecord::Base
      has_and_belongs_to_many :catalog_categories, join_table: 'catalog_categories_catalog_products'
    end
    ```

* プレフィックスではスコープも同様に考慮されるので、`Catalog::Category`と`Catalog::Product`間のリレーションや、`Catalog::Category`と`CatalogProduct`間のリレーションも同様に更新する必要があります。

### Active Resource

Rails 4.0ではActive Resourceがgem化されました。この機能が必要な場合は[Active Resource gem](https://github.com/rails/activeresource) を`Gemfile`に追加できます。

### Active Model

* Rails 4.0では`ActiveModel::Validations::ConfirmationValidator`にエラーがアタッチされる方法が変更されました。確認のバリデーションが失敗したときに、`attribute`ではなく`:#{attribute}_confirmation`にアタッチされるようになりました。

* Rails 4.0の`ActiveModel::Serializers::JSON.include_root_in_json`のデフォルト値が`false`に変更されました。これにより、Active Model SerializersとActive Recordオブジェクトのデフォルトの動作が同じになりました。これにより、`config/initializers/wrap_parameters.rb`ファイルの以下のオプションをコメントアウトしたり削除したりできるようになりました。

    ```ruby
    # Disable root element in JSON by default.
    # ActiveSupport.on_load(:active_record) do
    #   self.include_root_in_json = false
    # end
    ```

### Action Pack

* Rails 4.0から`ActiveSupport::KeyGenerator`が導入され、署名付きcookieの生成や照合などに使われるようになりました。Rails 3.xで生成された既存の署名付きcookieは、既存の`secret_token`はそのままにして`secret_key_base`を新しく追加することで透過的にアップグレードされます。

    ```ruby
    # config/initializers/secret_token.rb
    Myapp::Application.config.secret_token = 'existing secret token'
    Myapp::Application.config.secret_key_base = 'new secret key base'
    ```

    注意：`secret_key_base`を設定するのは、Rails 4.xへのユーザーベースの移行が100%完了し、Rails 3.xにロールバックする必要が完全になくなってからにしてください。これは、Rails 4.xの新しい`secret_key_base`で署名されたcookieにはRails 3.xのcookieとの後方互換性がないためです。他のアップグレードが完全に完了するまでは、既存の`secret_token`をそのままにして`secret_key_base`を設定せず、非推奨警告を無視する方法も可能です。

    外部アプリケーションやJavaScriptからRailsアプリケーションの署名付きセッションcookie（または一般の署名付きcookie）を読み出せる必要がある場合は、これらの問題を切り離すまでは`secret_key_base`を設定しないでください。

* Rails 4.0では、`secret_key_base`が設定されているとcookieベースのセッションの内容が暗号化されます。Rails 3.xではcookieベースのセッションを暗号化なしで署名していました。署名付きcookieは、そのRailsアプリケーションで生成されたことが確認でき、不正が防止されるという意味では安全ですが、セッションの内容はエンドユーザーから見えてしまいます。内容を暗号化することで懸念を取り除けるようになり、パフォーマンスもさほど低下しません。

    セッションcookieを暗号化する方法について詳しくは[#9978](https://github.com/rails/rails/pull/9978)を参照してください。

* Rails 4.0では`ActionController::Base.asset_path`オプションが廃止されました。今後はアセットパイプライン機能をご利用ください。

* Rails 4.0では`ActionController::Base.page_cache_extension`オプションが非推奨になりました。今後は`ActionController::Base.default_static_extension`をご利用ください。

* Rails 4.0のAction PackからActionキャッシュとPageキャッシュが取り除かれました。コントローラで`caches_action`を使いたい場合は`actionpack-action_caching` gemを、`caches_page`を使いたい場合は`actionpack-page_caching` gemをそれぞれGemfileに追加する必要があります。

* Rails 4.0からXMLパラメータパーサーが取り除かれました。この機能が必要な場合は`actionpack-xml_parser` gemを追加する必要があります。

* Rails 4.0では、シンボルやprocがnilを返す場合の、デフォルトの`layout`探索設定が変更されました。動作を「no layout」にするには、nilではなくfalseを返すようにします。

* Rails 4.0のデフォルトのmemcachedクライアントが`memcache-client`から`dalli`に変更されました。アップグレードするには、単に`gem "dalli"`を`Gemfile`に追加します。

* Rails 4.0ではコントローラでの`dom_id`および`dom_class`メソッドの利用が非推奨になりました（ビューでの利用は問題ありません）。この機能が必要なコントローラでは`ActionView::RecordIdentifier`モジュールをインクルードする必要があります。

* Rails 4.0では`link_to`ヘルパーの`:confirm`オプションが非推奨になりました。今後は`data`属性をお使いください（例： `data: { confirm: 'Are you sure?' }`）。`link_to_if`や`link_to_unless`などでも同様の対応が必要です。

* Rails 4.0では`assert_generates`、`assert_recognizes`、`assert_routing`の動作が変更されました。これらのアサーションは`ActionController::RoutingError`の代わりに`Assertion`をraiseします。

* Rails 4.0では、名前付きルーティングの定義が重複している場合に`ArgumentError`が発生するようになりました。このエラーは、明示的に定義された名前付きルーティングや`resources`メソッドによってトリガーされます。名前付きルーティング`example_path`が衝突している例を2つ示します。

    ```ruby
    get 'one' => 'test#example', as: :example
    get 'two' => 'test#example', as: :example
    ```

    ```ruby
    resources :examples
    get 'clashing/:id' => 'test#example', as: :example
    ```

    最初の例では、複数のルーティングで同じ名前を使わないようにすれば回避できます。次の例では、`only`または`except`オプションを`resources`メソッド内で使うことで、作成されるルーティングを制限できます。詳しくは[Railsのルーティング](routing.html#作成されるルーティングを制限する)を参照してください。

* Rails 4.0ではunicode文字のルーティングのレンダリング方法も変更され、unicode文字を用いるルーティングを直接レンダリングできるようになりました。既にこのようなルーティングを使っている場合は、以下の変更が必要です。

    ```ruby
    get Rack::Utils.escape('こんにちは'), controller: 'welcome', action: 'index'
    ```

    上のコードは以下のように変更する必要があります。

    ```ruby
    get 'こんにちは', controller: 'welcome', action: 'index'
    ```

* Rails 4.0でルーティングに`match`を使う場合は、リクエストメソッドの指定が必須となりました。以下に例を示します。

    ```ruby
    # Rails 3.x
    match '/' => 'root#index'

    # 上は以下に変更が必要
    match '/' => 'root#index', via: :get

    # または
    get '/' => 'root#index'
    ```

* Rails 4.0から`ActionDispatch::BestStandardsSupport`ミドルウェアが削除されました。`<!DOCTYPE html>`は既に https://msdn.microsoft.com/en-us/library/jj676915(v=vs.85).aspx の標準モードをトリガーするようになり、ChromeFrameヘッダは`config.action_dispatch.default_headers`に移動されました。

    アプリケーションコード内にあるこのミドルウェアへの参照は、すべて削除する必要があります。

    ```ruby
    # 例外発生
    config.middleware.insert_before(Rack::Lock, ActionDispatch::BestStandardsSupport)
    ```

    環境設定も確認し、`config.action_dispatch.best_standards_support`がある場合は削除してください。

* Rails 4.0では、`config.action_dispatch.default_headers`でHTTPヘッダーを設定できるようになりました。デフォルト設定は以下のとおりです。

    ```ruby
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block'
    }
    ```

    ただし、アプリケーションが特定のページで`<frame>`や`<iframe>`の読み込みに依存している場合は、`X-Frame-Options`を明示的に`ALLOW-FROM ...`または`ALLOWALL`に設定する必要があるでしょう。

* Rails 4.0のアセットのプリコンパイルでは、`vendor/assets`および`lib/assets`にある非JS/CSSアセットを自動的にはコピーしなくなりました。Railsアプリケーションやエンジンの開発者は、これらのアセットを手動で`app/assets`に置き、[`config.assets.precompile`][]`を設定してください。

* Rails 4.0では、リクエストされたフォーマットがアクションで扱えなかった場合に`ActionController::UnknownFormat`が発生するようになりました。デフォルトでは、この例外は406 Not Acceptableレスポンスとして扱われますが、この動作はオーバーライドできます。Rails 3では常に406 Not Acceptableが返され、オーバーライドはできません。

* Rails 4.0では、`ParamsParser`がリクエストパラメータを解析できなかった場合に一般的な`ActionDispatch::ParamsParser::ParseError`例外が発生するようになりました。`MultiJson::DecodeError`のような低レベルの例外の代わりにこの例外をrescueできます。

* Rails 4.0では、URLプレフィックスで指定されたアプリケーションにエンジンがマウントされている場合に`SCRIPT_NAME`が正しくネストするようになりました。今後はURLプレフィックスの上書きを回避するために`default_url_options[:script_name]`を設定する必要はありません。

* Rails 4.0では`ActionController::Integration`が非推奨となりました。今後は`ActionDispatch::Integration`をお使いください。
* Rails 4.0では`ActionController::IntegrationTest`は非推奨となりました。今後は`ActionDispatch::IntegrationTest`をお使いください。
* Rails 4.0では`ActionController::PerformanceTest`が非推奨となりました。今後は`ActionDispatch::PerformanceTest`をお使いください。
* Rails 4.0では`ActionController::AbstractRequest`が非推奨となりました。今後は`ActionDispatch::Request`をお使いください。
* Rails 4.0では`ActionController::Request`が非推奨となりました。今後は`ActionDispatch::Request`をお使いください。
* Rails 4.0では`ActionController::AbstractResponse`が非推奨となりました。今後は`ActionDispatch::Response`をお使いください。
* Rails 4.0では`ActionController::Response`が非推奨となりました。今後は`ActionDispatch::Response`をお使いください。
* Rails 4.0では`ActionController::Routing`が非推奨となりました。今後は`ActionDispatch::Routing`をお使いください。

[`config.assets.precompile`]: configuring.html#config-assets-precompile

### Active Support

Rails 4.0では`ERB::Util#json_escape`のエイリアス`j`が廃止されました。このエイリアス`j`は既に`ActionView::Helpers::JavaScriptHelper#escape_javascript`で使われているためです。

#### キャッシュ

Rails 3.xからRails 4.0への移行に伴い、キャッシュ用のメソッドが変更されました。[キャッシュの名前空間を変更](caching_with_rails.html#activesupport-cache-store)し、コールドキャッシュ（cold cache）を使って更新してください。

### ヘルパーの読み込み順序

Rails 4.0では複数のディレクトリからのヘルパーの読み込み順が変更されました。以前はすべてのヘルパーをいったん集めてからアルファベット順にソートしていました。Rails 4.0にアップグレードすると、ヘルパーは読み込まれたディレクトリの順序を保持し、ソートは各ディレクトリ内でのみ行われます。`helpers_path`パラメータを明示的に利用している場合を除いて、この変更はエンジンからヘルパーを読み込む方法にしか影響しません。ヘルパー読み込みの順序に依存している場合は、アップグレード後に正しいメソッドが使われているかどうかを確認する必要があります。エンジンが読み込まれる順序を変更したい場合は、`config.railties_order=` メソッドを利用できます。

### Active Record ObserverとAction Controller Sweeper

`Active Record Observer`と`Action Controller Sweeper`は`rails-observers` gemに切り出されました。これらの機能が必要な場合は`rails-observers` gemを追加してください。

### sprockets-rails

* `assets:precompile:primary`および`assets:precompile:all`は削除されました。今後は`assets:precompile`をお使いください。
* `config.assets.compress`オプションは、たとえば以下のように[`config.assets.js_compressor`][]に変更する必要があります。

    ```ruby
    config.assets.js_compressor = :uglifier
    ```

[`config.assets.js_compressor`]: configuring.html#config-assets-js-compressor

### sass-rails

* `asset-url`に引数を2つ渡すことは非推奨となりました。たとえば、`asset-url("rails.png", image)`は`asset-url("rails.png")`とする必要があります。

Rails 3.1からRails 3.2へのアップグレード
-------------------------------------

Railsアプリケーションのバージョンが3.1よりも古い場合、まず3.1へのアップグレードを完了してからRails 3.2へのアップグレードを開始してください。

以下の変更は、Rails 3.2.xにアップグレードするためのものです。

### Gemfile

`Gemfile`を以下のように変更します。

```ruby
gem "rails", "3.2.21"

group :assets do
  gem "sass-rails",   "~> 3.2.6"
  gem "coffee-rails", "~> 3.2.2"
  gem "uglifier",     ">= 1.0.3"
end
```

### config/environments/development.rb

development環境に新しい設定をいくつか追加する必要があります。

```ruby
# Active Recordのモデルをマスアサインメントから保護するために例外を発生する
config.active_record.mass_assignment_sanitizer = :strict

# クエリの実行計画 (クエリプラン) を現在より多く出力する
# (SQLite、MySQL、PostgreSQLで動作)
config.active_record.auto_explain_threshold_in_seconds = 0.5
```

### config/environments/test.rb

`mass_assignment_sanitizer`設定を`config/environments/test.rb`にも追加する必要があります。

```ruby
# Active Recordのモデルをマスアサインメントから保護するために例外を発生する
config.active_record.mass_assignment_sanitizer = :strict
```

### vendor/plugins

`vendor/plugins` はRails 3.2で非推奨となり、Rails 4.0では完全に削除されました。Rails 3.2へのアップグレードでは必須ではありませんが、今のうちにプラグインをgemにエクスポートして`Gemfile`に追加するのがよいでしょう。理由があってプラグインをgemにしないのであれば、プラグインを`lib/my_plugin/*`に移動し、適切な初期化の記述を`config/initializers/my_plugin.rb`に書いてください。

### Active Record

`:dependent => :restrict`オプションは`belongs_to`から削除されました。関連付けられたオブジェクトがある場合にこのオブジェクトを削除したくない場合は、`:dependent => :destroy`を設定し、関連付けられたオブジェクトのdestroyコールバックとの関連付けがあるかどうかを確認してから`false`を返すようにします。

Rails 3.0からRails 3.1へのアップグレード
-------------------------------------

Railsアプリケーションのバージョンが3.0より前の場合、まず3.0へのアップグレードを完了してからRails 3.1へのアップグレードにとりかかってください。

以下の変更は、Rails 3.1.xの最新版であるRails 3.1.12にアップグレードするためのものです。

### Gemfile

`Gemfile`を以下のように変更します。

```ruby
gem "rails", "3.1.12"
gem "mysql2"

# 新しいアセットパイプラインで必要
group :assets do
  gem "sass-rails",   "~> 3.1.7"
  gem "coffee-rails", "~> 3.1.1"
  gem "uglifier",     ">= 1.0.3"
end

# Rails 3.1からjQueryがデフォルトのJavaScriptライブラリになる
gem "jquery-rails"
```

### config/application.rb

アセットパイプラインを利用するには、以下の変更が必要です。

```ruby
config.assets.enabled = true
config.assets.version = "1.0"
```

Railsアプリケーションでリソースのルーティングに`/assets`ルートを使っている場合、コンフリクトを避けるために以下の変更を加えます。

```ruby
# '/assets'のデフォルト
config.assets.prefix = '/asset-files'
```

### config/environments/development.rb

RJSの設定`config.action_view.debug_rjs = true`を削除してください。

アセットパイプラインを有効にしている場合は以下の設定を追加します。

```ruby
# development環境ではアセットを圧縮しない
config.assets.compress = false

# アセットで読み込んだ行を展開する
config.assets.debug = true
```

### config/environments/production.rb

以下の変更はほとんどがアセットパイプライン用です。詳しくは [アセットパイプライン](asset_pipeline.html)ガイドを参照してください。

```ruby
# JavaScriptとCSSを圧縮する
config.assets.compress = true

# プリコンパイル済みのアセットが見当たらない場合にアセットパイプラインにフォールバックしない
config.assets.compile = false

# アセットURLのダイジェストを生成する
config.assets.digest = true

# Rails.root.join("public/assets")へのデフォルト
# config.assets.manifest = 該当するパス

# 追加のアセット（application.js、application.cssおよびすべての非JS/CSSが追加済み）をプリコンパイルする
# config.assets.precompile += %w( admin.js admin.css )

# アプリケーションへのすべてのアクセスを強制的にSSLにし、Strict-Transport-Securityとセキュアcookieを使う
# config.force_ssl = true
```

### config/environments/test.rb

テスト環境に以下を追加することでテストのパフォーマンスが向上します。

```ruby
# Cache-Controlを使うテストで静的アセットサーバーを構成し、パフォーマンスを向上させる
config.public_file_server.enabled = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=3600'
}
```

### config/initializers/wrap_parameters.rb

ネストしたハッシュにパラメータをラップしたい場合は、このファイルに以下のコンテンツを含めて追加します。新しいアプリケーションではこれがデフォルトになります。

```ruby
# このファイルを変更後サーバーを必ず再起動すること。
# このファイルにはActionController::ParamsWrapper用の設定が含まれており
# デフォルトでオンになっています。

# JSON用にパラメータをラップします。:formatに空配列を設定することで無効にできます。
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

# JSONのルート要素をデフォルトで無効にする
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
```

### config/initializers/session_store.rb

何らかの新しいセッションキーを設定するか、すべてのセッションを削除するかのどちらかにする必要があります。

```ruby
# config/initializers/session_store.rbに以下を設定する
AppName::Application.config.session_store :cookie_store, key: 'SOMETHINGNEW'
```

または

```bash
$ bin/rake db:sessions:clear
```

### ビューのアセットヘルパー参照から:cacheオプションと:concatオプションを削除する

* Asset Pipelineの`:cache`オプションと`:concat`オプションは廃止されました。ビューからこれらのオプションを削除してください。
