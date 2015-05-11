


Ruby on Rails 4.0 リリースノート
===============================

Rails 4.0の注目ポイント

* Ruby 2.0が推奨。1.9.3以上が必須。
* Strong Parameters
* Turbolinks
* ロシアンドールキャッシュ (Russian Doll Caching)

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/4-0-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 4.0へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 3.2までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 4.0にアップデートしてください。アップグレードの注意点などについては[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-3.2%E3%81%8B%E3%82%89rails-4.0%E3%81%B8%E3%81%AE%E3%82%A2%E3%83%83%E3%83%97%E3%82%B0%E3%83%AC%E3%83%BC%E3%83%89) を参照してください。


Rails 4.0アプリケーションを作成する
--------------------------------

```
# 'rails'というRubyGemがインストールされている必要があります。
$ rails new myapp
$ cd myapp
```

### gemに移行する

Rails 4.0からは、アプリケーションのルートディレクトリに置かれる`Gemfile`を使用して、アプリケーションの起動に必要なgemを指定するようになりました。この`Gemfile`は[Bundler](https://github.com/carlhuda/bundler)というgemによって処理され、依存関係のある必要なgemをすべてインストールします。依存するgemをそのアプリケーションの中にだけインストールして、OS環境にある既存のgemに影響を与えないようにすることもできます。

詳細情報: [Bundlerホームページ](http://gembundler.com)

### 最新のgemを使用する

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使用してアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```
$ ruby /path/to/rails/railties/bin/rails new myapp --dev
```

主要な変更
--------------

[![Rails 4.0](images/rails4_features.png)](http://railsguides.jp/images/rails4_features.png)

### アップグレード

* **Ruby 1.9.3** ([コミット](https://github.com/rails/rails/commit/a0380e808d3dbd2462df17f5d3b7fcd8bd812496)) - Ruby 2.0を推奨、1.9.3以降は必須。
* **[今後の非推奨化ポリシー](http://www.youtube.com/watch?v=z6YgD6tVPQs)** - 非推奨となった機能はRails 4.0で警告が表示されるようになり、Rails 4.1ではその機能が完全に削除される。
* **ActionPackの「ページとアクションキャッシュ」(page and action caching)** ([コミット](https://github.com/rails/rails/commit/b0a7068564f0c95e7ef28fc39d0335ed17d93e90)) - ページとアクションキャッシュは個別のgemに分離された。ページとアクションキャッシュは手動での調整が必要な部分が多すぎる(背後のモデルオブジェクトが更新されたらキャッシュを手動で期限切れにする必要がある)。今後はロシアンドールキャッシュを使用のこと。
* **ActiveRecord observers** ([コミット](https://github.com/rails/rails/commit/ccecab3ba950a288b61a516bf9b6962e384aae0b)) - observers (デザインパターン) は個別のgemに分離された。observersパターンはページとアクションキャッシュでしか使用されず、コードがスパゲッティになりやすいため。
* **ActiveRecordセッションストア** ([コミット](https://github.com/rails/rails/commit/0ffe19056c8e8b2f9ae9d487b896cad2ce9387ad)) - ActiveRecordセッションストアは個別のgemに分離された。セッションをSQLに保存するのはコストがかさむ傾向がある。今後はcookiesセッション、memcacheセッション、または独自のセッションストアを使用のこと。
* **ActiveModelマスアサインメント保護** ([コミット](https://github.com/rails/rails/commit/f8c9a4d3e88181cee644f91e1342bfe896ca64c6)) - Rails 3のマスアサインメント保護は非推奨に指定された。今後はStrong Parametersを使用のこと。
* **ActiveResource** ([コミット](https://github.com/rails/rails/commit/f1637bf2bb00490203503fbd943b73406e043d1d)) - ActiveResourceは個別のgemに分離された。ActiveResourceの使用頻度が低いため。
* **vendor/plugins の削除** ([コミット](https://github.com/rails/rails/commit/853de2bd9ac572735fa6cf59fcf827e485a231c3)) - 今後はGemfileでgemのインストールを管理すること。

### ActionPack

* **Strong Parameters** ([コミット](https://github.com/rails/rails/commit/a8f6d5c6450a7fe058348a7f10a908352bb6c7fc)) - ホワイトリストで明示的に許可されたパラメータ (`params.permit(:title, :text)`) を使用しないとモデルオブジェクトを更新できないようにする。
* **ルーティングの「concern」機能** ([コミット](https://github.com/rails/rails/commit/0dd24728a088fcb4ae616bb5d62734aca5276b1b)) - ルーティング用のDSLで、共通となるサブルーティング (subroutes) を除外する (`/posts/1/comments`と`/videos/1/comments`における`comments`など)。
* **ActionController::Live** ([コミット](https://github.com/rails/rails/commit/af0a9f9eefaee3a8120cfd8d05cbc431af376da3)) - JSONを`response.stream`でストリーミングする。
* **「宣言的 (declarative)」ETag** ([コミット](https://github.com/rails/rails/commit/ed5c938fa36995f06d4917d9543ba78ed506bb8d)) - コントローラレベルのetagを追加する。これはアクションでのetag算出にも使用される。
* **[ロシアンドールキャッシュ](http://37signals.com/svn/posts/3113-how-key-based-cache-expiration-works)** ([コミット](https://github.com/rails/rails/commit/4154bf012d2bec2aae79e4a49aa94a70d3e91d49)) - ビューで、ネストしたコード断片をキャッシュする。各断片は依存関係のセット (キャッシュキー) に応じて期限切れになる。通常、このキャッシュキーにはテンプレートのバージョン番号とモデルオブジェクトが使用される。
* **Turbolinks** ([コミット](https://github.com/rails/rails/commit/e35d8b18d0649c0ecc58f6b73df6b3c8d0c6bb74)) - 最初のHTMLページだけを使用してサービスを提供する (訳注: 一部しか違わないページのためにページ全体を HTTP 送信しないで済むようにするための仕組み)。ユーザーが別のページに遷移すると、pushStateでURLを差し替え、AJAXでタイトルとbodyを差し替える。
* **ActionControllerとActionViewの分離** ([コミット](https://github.com/rails/rails/commit/78b0934dd1bb84e8f093fb8ef95ca99b297b51cd)) - ActionViewはActionPackから分離され、Rails 4.1で個別のgemに移行する予定。
* **ActiveModelへの依存をただちにやめること** ([コミット](https://github.com/rails/rails/commit/166dbaa7526a96fdf046f093f25b0a134b277a68)) - ActionPackはもはやActiveModelを使用しなくなった。

### 一般

* **ActiveModel::Model** ([commit](https://github.com/rails/rails/commit/3b822e91d1a6c4eab0064989bbd07aae3a6d0d08)) - `ActiveModel::Model`は通常のRubyオブジェクトでもActionPackの機能を利用できるようにする (`form_for`など) ためのミックスイン。 
* **新しい「スコープAPI」** ([コミット](https://github.com/rails/rails/commit/50cbc03d18c5984347965a94027879623fc44cce)) - scopeメソッドの引数は常にcallメソッドを実装していなくてはならない。
* **スキーマキャッシュダンプ** ([コミット](https://github.com/rails/rails/commit/5ca4fc95818047108e69e22d200e7a4a22969477)) - Railsの起動時間短縮のため、スキーマをデータベースから直接読み込むのではなくダンプファイルから読み込む。
* **トランザクション分離レベル指定のサポート** ([コミット](https://github.com/rails/rails/commit/392eeecc11a291e406db927a18b75f41b2658253)) - 読み出しを頻繁に行うか、書き込みのパフォーマンスを重視してロックを減らすかを選択できる。
* **Dalli** ([コミット](https://github.com/rails/rails/commit/82663306f428a5bbc90c511458432afb26d2f238)) - memcacheストアにはDalliのmemcacheクライアントを使用すること。
* **通知の開始と終了** ([コミット](https://github.com/rails/rails/commit/f08f8750a512f741acb004d0cebe210c5f949f28)) - Active Support の内部フック機構 (instrumentation) によってサブスクライバへの通知の開始と終了が報告されます。
* **デフォルトでのスレッドセーフ提供** ([コミット](https://github.com/rails/rails/commit/5d416b907864d99af55ebaa400fff217e17570cd)) - Railsは追加設定なしでスレッド化されます。

NOTE: 追加したgemも同様にスレッドセーフであるかどうかをチェックしておいてください。


* **PATCH 動詞** ([コミット](https://github.com/rails/rails/commit/eed9f2539e3ab5a68e798802f464b8e4e95e619e)) - 従来の HTTP 動詞であるPUTはPATCHに置き換えられました。PATCHはリソースの部分的な更新に使用されます。

### セキュリティ

* **matchだけですべてをまかなわないこと** ([コミット](https://github.com/rails/rails/commit/90d2802b71a6e89aedfe40564a37bd35f777e541)) - ルーティング用のDSLで match を使用する場合には HTTP 動詞 (verb) を明示的にひとつまたは複数指定する必要があります。
* **htmlエンティティをデフォルトでエスケープ** ([コミット](https://github.com/rails/rails/commit/5f189f41258b83d49012ec5a0678d827327e7543)) - ERB内でレンダリングされる文字列は、`raw`や`html_safe`メソッドでラップしない限り常にエスケープされます。
* **新しいセキュリティヘッダー** ([コメント](https://github.com/rails/rails/commit/6794e92b204572d75a07bd6413bdae6ae22d5a82)) - Railsから送信されるあらゆるHTTPリクエストに次のヘッダーが含まれるようになりました: `X-Frame-Options` (クリックジャック防止のため、フレーム内へのページ埋め込みを禁止するようブラウザに指示する)、`X-XSS-Protection` (スクリプト注入を停止するようブラウザに指示する)、`X-Content-Type-Options` (jpegファイルをexeとして開かないようブラウザに指示する)。

外部gem化された機能
---------------------------

Rails 4.0では多くの機能が切り出されてgemに移行しました。切り出されたgemを`Gemfile`ファイルに追加するだけでこれまでと同様に利用できます。

* ハッシュベースおよび動的findメソッド群 ([GitHub](https://github.com/rails/activerecord-deprecated_finders))
* Active Recordモデルでのマスアサインメント保護 ([GitHub](https://github.com/rails/protected_attributes)、[Pull Request](https://github.com/rails/rails/pull/7251))
* ActiveRecord::SessionStore ([GitHub](https://github.com/rails/activerecord-session_store)、[Pull Request](https://github.com/rails/rails/pull/7436))
* Active Record Observerパターン ([GitHub](https://github.com/rails/rails-observers)、[Commit](https://github.com/rails/rails/commit/39e85b3b90c58449164673909a6f1893cba290b2))
* Active Resource ([GitHub](https://github.com/rails/activeresource), [Pull Request](https://github.com/rails/rails/pull/572)、[ブログ記事](http://yetimedia.tumblr.com/post/35233051627/activeresource-is-dead-long-live-activeresource))
* アクションキャッシュ ([GitHub](https://github.com/rails/actionpack-action_caching)、[Pull Request](https://github.com/rails/rails/pull/7833))
* ページキャッシュ ([GitHub](https://github.com/rails/actionpack-page_caching)、[Pull Request](https://github.com/rails/rails/pull/7833))
* Sprockets ([GitHub](https://github.com/rails/sprockets-rails))
* パフォーマンステスト ([GitHub](https://github.com/rails/rails-perftest)、[Pull Request](https://github.com/rails/rails/pull/8876))

ドキュメント
-------------

* ガイドはGitHub風マークダウンで書き直されました。

* ガイドのデザインがレスポンシブになりました。

Railties
--------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/railties/CHANGELOG.md) を参照してください。

### 主な変更点

* テスト用ディレクトリが追加されました: `test/models`、`test/helpers`、`test/controllers`、`test/mailers`これらに対応するrakeタスクも追加されました。([Pull Request](https://github.com/rails/rails/pull/7878))

* アプリケーション内の実行ファイルは`bin/`ディレクトリに置かれるようになりました。`rake rails:update:bin`を実行すると`bin/bundle`、`bin/rails`、`bin/rake`を取得します。

* デフォルトでスレッドセーフになりました。

* `rails new`に`--builder`または`-b`を渡すことでカスタムビルダーを使用できる機能は削除されました。今後はアプリケーションテンプレートの利用をご検討ください。([Pull Request](https://github.com/rails/rails/pull/9401))

### 非推奨

* `config.threadsafe!`は非推奨になりました。今後は`config.eager_load`をご利用ください。後者は一括読み込み (eager load) の対象をさらに細かい粒度で制御できます。

* `Rails::Plugin`は廃止されました。今後は`vendor/plugins`にプラグインを追加する代わりに、gemやbundlerでパスやgit依存関係を指定してご利用ください。

Action Mailer
-------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/actionmailer/CHANGELOG.md) を参照してください。

### 主な変更点

### 非推奨

Active Model
------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/activemodel/CHANGELOG.md) を参照してください。

### 主な変更点

* `ActiveModel::ForbiddenAttributesProtection`を追加しました。許可されていない属性が渡された場合にマスアサインメントから属性を保護するためのシンプルなモジュールです。

* `ActiveModel::Model`を追加しました。RubyオブジェクトをAction Packですぐに使えるようにするためのミックスインです。

### 非推奨

Active Support
--------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/activesupport/CHANGELOG.md) を参照してください。

### 主な変更点

* 非推奨の`memcache-client` gemを`ActiveSupport::Cache::MemCacheStore`の`dalli`に置き換えました。

* `ActiveSupport::Cache::Entry`が最適化され、メモリ使用量と処理のオーバーヘッドが軽減されました。

* 語の活用形 (inflection) をロケールごとに設定できるようになり、`singularize`や`pluralize`メソッドの引数にロケールも指定できるようになりました。

* `Object#try`に渡したオブジェクトにメソッドが実装されていなかった場合に、NoMethodErrorエラーを発生する代わりにnilを返すようになりました。新しい`Object#try!`を使用すれば従来と同じ動作になります。

* `String#to_date`に無効な日付を渡した場合に発生するエラーが`NoMethodError: undefined method 'div' for nil:NilClass`から`ArgumentError: invalid date`に変更されました。これによって`Date.parse`と同じ動作になり、以下のように3.xよりも日付を適切に扱えるようになりました。

  ```ruby
  # ActiveSupport 3.x
  "asdf".to_date # => NoMethodError: undefined method `div' for nil:NilClass
  "333".to_date # => NoMethodError: undefined method `div' for nil:NilClass

  # ActiveSupport 4
  "asdf".to_date # => ArgumentError: invalid date
  "333".to_date # => Fri, 29 Nov 2013
  ```

### 非推奨

* `ActiveSupport::TestCase#pending`メソッドが非推奨になりました。今後はMiniTestの`skip`をご利用ください。

* `ActiveSupport::Benchmarkable#silence`はスレッドセーフでないため非推奨となりました。Rails 4.1では代替されることなく削除される予定です。

* `ActiveSupport::JSON::Variable`は非推奨になりました。カスタムのJSON文字列リテラルを扱いたい場合は、`#as_json`と`#encode_json`メソッドを自分で定義してください。

* 互換用の`Module#local_constant_names`メソッドは非推奨になりました。今後はシンボルを返す`Module#local_constants`をご利用ください。

* `BufferedLogger`は非推奨になりました。今後は`ActiveSupport::Logger`またはRuby標準ライブラリのロガーをご利用ください。

* `assert_present`および`assert_blank`は非推奨になりました。今後は`assert object.blank?`や`assert object.present?`をご利用ください。

Action Pack
-----------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/actionpack/CHANGELOG.md) を参照してください。

### 主な変更点

* developmentモードでの例外ページのスタイルシートが変更されました。また、例外ページにはその例外が実際に発生したコードの行や断片も常に表示されるようになりました。

### 非推奨


Active Record
-------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-0-stable/activerecord/CHANGELOG.md) を参照してください。

### 主な変更点

* マイグレーションで`change`を書く方法が改良され、以前のように`up`や`down`メソッドを使用する必要がなくなりました。

    * `drop_table`メソッドと`remove_column`メソッドは逆方向のマイグレーション (取り消し) が可能になりました。ただしそのために必要な情報が与えられていることが前提です。
      `remove_column`メソッドは従来複数のカラムを引数に指定する際に使用されていましたが、今後はそのような場合には`remove_columns`メソッドをご利用ください (ただしこちらは逆マイグレーションできません)。
      `change_table`も逆マイグレーション可能になりました。ただしそのブロックで`remove`、`change`、`change_default`が呼び出されていないことが前提です。

    * `reversible`メソッドが新たに追加され、マイグレーション (up) や逆マイグレーション (down) 時に実行するコードを指定できるようになりました。
      詳細については[Active Record マイグレーションガイド](https://github.com/rails/rails/blob/master/guides/source/active_record_migrations.md#using-reversible)を参照してください。

    * 新しい`revert`メソッドは、特定のブロックやマイグレーション全体を逆転します。
      逆マイグレーション (down) を行うと、指定されたマイグレーションやブロックは通常のマイグレーション (up) になります。
      詳細については[Active Record マイグレーションガイド](https://github.com/rails/rails/blob/master/guides/source/active_record_migrations.md#reverting-previous-migrations)を参照してください。

* PostgreSQLの配列型サポートが追加されました。配列カラムの作成時に任意のデータ型を使用できます。それらのデータ型はフルマイグレーションやスキーマダンプでもサポートされます。

* `Relation#load`メソッドが追加されました。これはレコードを明示的に読み込んで`self`を返します。

* `Model.all`が`ActiveRecord::Relation`を返すようになりました。従来はレコードの配列を返していました。レコードの配列がどうしても必要な場合は`Relation#to_a`をご利用ください。ただし場合によっては今後のアップグレード時に正常に動作しなくなることがありえます。

* `ActiveRecord::Migration.check_pending!`が追加されました。これはマイグレーションが延期されている場合にエラーを発生します。

* `ActiveRecord::Store`用のカスタムコーダーのサポートが追加されました。これにより、以下のような方法でカスタムコーダーを設定できます。

        store :settings, accessors: [ :color, :homepage ], coder: JSON

* `mysql`や`mysql2`への接続時にデフォルトで`SQL_MODE=STRICT_ALL_TABLES`が設定されるようになりました。これはデータ損失時に何も通知されない状態を回避するための設定です。`database.yml`ファイルで`strict: false`を指定するとこの設定は無効になります。

* IdentityMapは削除されました。

* EXPLAINクエリの自動実行は削除されました。この`active_record.auto_explain_threshold_in_seconds`オプションは今後利用されないので削除する必要があります。

* `ActiveRecord::NullRelation`と`ActiveRecord::Relation#none`が追加されました。これらはRelationクラスにnullオブジェクトパターンを実装するためのものです。

* `create_join_table`マイグレーションヘルパーが追加されました。これはHABTM (Has And Belongs To Many) 結合テーブルを作成します。

* PostgreSQL hstoreレコードを作成できるようになりました。

### 非推奨

* 従来のハッシュベースのfind関連APIメソッドは非推奨になりました。これにより、従来利用できた「findオプション」はサポートされなくなりました。

* 動的なfind関連メソッドは、`find_by_...`と`find_by_...!`を除いて非推奨になりました。以下の要領でコードを書き直してください。

      * `find_all_by_...`は`where(...)`で書き直せる。
      * `find_last_by_...`は`where(...).last`で書き直せる。
      * `scoped_by_...`は`where(...)`で書き直せる。
      * `find_or_initialize_by_...`は`find_or_initialize_by(...)`で書き直せる。
      * `find_or_create_by_...`は`find_or_create_by(...)`で書き直せる。
      * `find_or_create_by_...!`は`find_or_create_by!(...)`で書き直せる。

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](http://contributors.rubyonrails.org/)を参照してください。これらの方々全員に敬意を表明いたします。