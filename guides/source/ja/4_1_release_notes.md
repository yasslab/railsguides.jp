
Ruby on Rails 4.1 リリースノート
===============================

Rails 4.1の注目ポイント

* アプリケーションプリローダーSpring
* `config/secrets.yml`
* Action Packのバリアント
* Action Mailerプレビュー

本リリースノートでは、主要な変更についてのみ説明します。細かなバグ修正や変更については、change logを参照するか、Githubの主要なRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/master) を参照してください

--------------------------------------------------------------------------------

Rails 4.1へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのがよい考えです。アプリケーションがRails 4.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 4.1にアップデートしてください。アップグレードの注意点などについては[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-4.0からrails-4.1へのアップグレード) を参照してください。


主要な変更
--------------

### 「Spring」アプリケーションプリローダー

SpringはRailsアプリケーション用のプリローダーです。アプリケーションをバックグラウンドで常駐させることで開発速度を向上させ、テストやrakeタスク、マイグレーションを実行するたびにRailsを起動しないで済むようにします。

Rails 4.1アプリケーションに含まれるbinstubは「spring化」されています。これは、アプリケーションのルートディレクトリで`bin/rails`および`bin/rake`を実行すると自動的にspring環境をプリロードするということです。

**rakeタスクの実行:**

```
bin/rake test:models
```

**Railsコマンドの実行:**

```
bin/rails console
```

**Springの状態確認:**

```
$ bin/spring status
Spring is running:

1182 spring server | my_app | started 29 mins ago
3656 spring app    | my_app | started 23 secs ago | test mode
3746 spring app    | my_app | started 10 secs ago | development mode
```

Springのすべての機能については[Spring README](https://github.com/rails/spring/blob/master/README.md)を参照してください。

[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#spring)には、この機能を既存のアプリケーションと統合する方法について記載されています。

### `config/secrets.yml`

Rails 4.1では`config`フォルダ内に新しく`secrets.yml`ファイルが生成されます。デフォルトでは、このファイルにはアプリケーションの`secret_key_base`が含まれていますが、外部API用のアクセスキーなどの秘密キーもここに保存できます。

このファイルに保存された秘密キーは`Rails.application.secrets`を使用してアクセスできます。
たとえば、以下の`config/secrets.yml`について見てみましょう。

```yaml
development:
  secret_key_base: 3b7cd727ee24e8444053437c36cc66c3
  some_api_key: SOMEKEY
```

上の設定にした場合、development環境で`Rails.application.secrets.some_api_key`を実行すると`SOMEKEY`が返されます。

既存のアプリケーションにこの機能を統合する方法については[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#config/secrets.yml)を参照してください。

### Action Pack Variant

スマートフォン、タブレット、デスクトップブラウザごとに異なるHTML/JSON/XMLテンプレートを使いたいことはよくあります。Variantを使用することで、これを簡単に実現できます。

リクエストvariantは、`:tablet`、`:phone`、`:desktop`のようなリクエストフォーマットを特殊化したものです。

`before_action`で以下のvariantを設定できます。

```ruby
request.variant = :tablet if request.user_agent =~ /iPad/
```

アクションの側では、フォーマットへの応答と同じ要領でvariantに応答します。

```ruby
respond_to do |format|
  format.html do |html|
    html.tablet # renders app/views/projects/show.html+tablet.erb
    html.phone { extra_setup; render ... }
  end
end
```

フォーマットごと、variantごとに個別のテンプレートを用意してください。

```
app/views/projects/show.html.erb
app/views/projects/show.html+tablet.erb
app/views/projects/show.html+phone.erb
```

以下のようなインライン文法を使用することで、variant定義を簡略化することもできます。

```ruby
respond_to do |format|
  format.js         { render "trash" }
  format.html.phone { redirect_to progress_path }
  format.html.none  { render "trash" }
end
```

### Action Mailerプレビュー

Action Mailerプレビューは、特定のURLにアクセスすることで、送信されるメールがどんなふうに見えるかをレンダリングしてプレビューします。

チェックしたいメールオブジェクトを返すメソッドを持つプレビュークラスを定義してください。

```ruby
class NotifierPreview < ActionMailer::Preview
  def welcome
    Notifier.welcome(User.first)
  end
end
```

プレビューを表示するには http://localhost:3000/rails/mailers/notifier/welcome にアクセスします。プレビューのリストは http://localhost:3000/rails/mailers にあります。

デフォルトのプレビュークラスは`test/mailers/previews`に置かれます。
`preview_path`オプションを変更することでこれを変更できます。

詳細については[ドキュメント](http://api.rubyonrails.org/v4.1.0/classes/ActionMailer/Base.html)を参照してください。

### Active Record enums

データベースで値をintegerにマップしたい場所でenum属性を宣言しますが、名前でクエリを発行することもできます。

```ruby
class Conversation < ActiveRecord::Base
  enum status: [ :active, :archived ]
end

conversation.archived!
conversation.active? # => false
conversation.status  # => "archived"

Conversation.archived # => Relation for all archived Conversations

Conversation.statuses # => { "active" => 0, "archived" => 1 }
```

詳細については[マニュアル](http://api.rubyonrails.org/v4.1.0/classes/ActiveRecord/Enum.html)を参照してください。

### メッセージベリファイア

メッセージベリファイア (message verifier) は、署名付きメッセージの生成と照合に使用できます。この機能は、「パスワードを保存 (remember me)」トークンや友人リストのような機密データを安全に転送するときに便利です。

`Rails.application.message_verifier`メソッドは、 secret_key_baseを使用して生成されたキーで署名された新しいメッセージベリファイアと、与えられたメッセージ照合名を返します。

```ruby
signed_token = Rails.application.message_verifier(:remember_me).generate(token)
Rails.application.message_verifier(:remember_me).verify(signed_token) # => token

Rails.application.message_verifier(:remember_me).verify(tampered_token)
# ActiveSupport::MessageVerifier::InvalidSignatureをはっせいする
```

### Module#concerning

自然かつ堅苦しくない方法で、クラスから責任を分離します。

```ruby
class Todo < ActiveRecord::Base
  concerning :EventTracking do
    included do
      has_many :events
    end

    def latest_event
      ...
    end

    private
      def some_internal_method
        ...
      end
  end
end
```

この例は、`EventTracking`モジュールをインラインで定義し、`ActiveSupport::Concern`でextendし、`Todo`クラスにミックスインしたのと同等です。

詳細および想定されるユースケースについては[マニュアル](http://api.rubyonrails.org/v4.1.0/classes/Module/Concerning.html) を参照してください。

### リモート `<script>` タグにCSRF保護を実施

JavaScriptレスポンスを伴うGETリクエストもクロスサイトリクエストフォージェリ (CSRF) 保護の対象となりました。この保護によって、第三者のサイトが重要なデータの奪取のために自分のサイトのJavaScript URLを参照して実行しようとすることを防止します。

これは、xhr`を使用しない場合、`.js` URLにヒットするすべてのテストはCSRF保護によって失敗するということです。`XmlHttpRequestsを明示的に想定するようにテストをアップグレードしてください。`post :create, format: :js`の代りに、明示的に`xhr :post, :create, format: :js`を使用してください。


Railties
--------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md) を参照してください。

### 削除されたもの

* `update:application_controller` rake taskが削除されました。

* 非推奨の`Rails.application.railties.engines`が除外されました。

* 非推奨の`threadsafe!`がRails Configから削除されました。

* 非推奨の`ActiveRecord::Generators::ActiveModel#update_attributes`が削除されました。`ActiveRecord::Generators::ActiveModel#update`をご使用ください。

* 非推奨の`config.whiny_nils`オプションが削除されました。

* 非推奨のテスト実行rakeタスク`rake test:uncommitted`および`rake test:recent`が削除されました。

### 主な変更点

* [Springアプリケーションプリローダー](https://github.com/rails/spring) は新規アプリケーションにデフォルトでインストールされます。Gemfileのdevelopグループにインストールされ、productionグループにはインストールされません。([Pull Request](https://github.com/rails/rails/pull/12958))

* テスト失敗時にフィルタされていないバックトレースを表示する`BACKTRACE`環境変数。([Commit](https://github.com/rails/rails/commit/84eac5dab8b0fe9ee20b51250e52ad7bfea36553))

* `MiddlewareStack#unshift`が環境構成用に公開されました。([Pull Request](https://github.com/rails/rails/pull/12479))

* メッセージベリファイアを返す`Application#message_verifier`メソッド。([Pull Request](https://github.com/rails/rails/pull/12995))

* デフォルトで生成されるテストヘルパーでrequireされる`test_help.rb`ファイルは、`db/schema.rb` (または `db/structure.sql`) を使用して自動的にテストデータベースを最新の状態に保ちます。スキーマを再度読み込んでもペンディング中のマイグレーションをすべて解決できなかった場合はエラーが発生します。`config.active_record.maintain_test_schema = false`を指定することでエラーを回避できます。([Pull Request](https://github.com/rails/rails/pull/13528))

* `Gem::Version.new(Rails.version)`を返す便利なメソッドとして`Rails.gem_version`が導入されました。より信頼できるバージョン比較法を提供します。([Pull Request](https://github.com/rails/rails/pull/14103))


Action Pack
-----------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md) を参照してください。

### 削除されたもの

* 非推奨の、結合テスト用Railsアプリケーションフォールバックが削除されました。`ActionDispatch.test_app`を代りにご使用ください。

* 非推奨の`page_cache_extension` configが削除されました。

* 非推奨の`ActionController::RecordIdentifier`が削除されました。`ActionView::RecordIdentifier`を代りにご使用ください。

* 以下の非推奨の定数がAction Controllerから削除されました。

| 削除された                            | 今後使用する                       |
|:-----------------------------------|:--------------------------------|
| ActionController::AbstractRequest  | ActionDispatch::Request         |
| ActionController::Request          | ActionDispatch::Request         |
| ActionController::AbstractResponse | ActionDispatch::Response        |
| ActionController::Response         | ActionDispatch::Response        |
| ActionController::Routing          | ActionDispatch::Routing         |
| ActionController::Integration      | ActionDispatch::Integration     |
| ActionController::IntegrationTest  | ActionDispatch::IntegrationTest |

### 主な変更点

* `protect_from_forgery`によって、クロスオリジン`<script>`タグも使用できなくなりました。テストをアップデートして、 `get :foo, format: :js`の代りに`xhr :get, :foo, format: :js`を使うようにしてください。([Pull Request](https://github.com/rails/rails/pull/13345))

* `#url_for`は、オプションのハッシュを配列の中で使用できるようになりました。([Pull Request](https://github.com/rails/rails/pull/9599))

* `session#fetch`メソッドが追加されました。この振る舞いは[Hash#fetch](http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-fetch)と似ていますが、戻り値が常にセッションに保存される点が異なります。([Pull Request](https://github.com/rails/rails/pull/12692))

* Action ViewはAction Packから完全に分離されました。([Pull Request](https://github.com/rails/rails/pull/11032))

* deep_mungeに影響されているキーがログ出力されるようになりました。([Pull Request](https://github.com/rails/rails/pull/13813))

* セキュリティ脆弱性CVE-2013-0155に対応するため、パラメータのdeep_munge化を回避する`config.action_dispatch.perform_deep_munge`configオプションが新たに追加されました。([Pull Request](https://github.com/rails/rails/pull/13188))

* 署名及び暗号化されたcookies jarのシリアライザを指定する`config.action_dispatch.cookies_serializer`configオプションが新たに追加されました。 (Pull Requests [1](https://github.com/rails/rails/pull/13692), [2](https://github.com/rails/rails/pull/13945) / [詳細](upgrading_ruby_on_rails.html#cookiesシリアライザ))

* `render :plain`、`render :html`、`render :body`が追加されました。([Pull Request](https://github.com/rails/rails/pull/14062) / [詳細](upgrading_ruby_on_rails.html#文字列からのコンテンツ描出))


Action Mailer
-------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) を参照してください。

### 主な変更点

* 37 Signals社のmail_view gemを元にメイラーのプレビュー機能が追加されました。([Commit](https://github.com/rails/rails/commit/d6dec7fcb6b8fddf8c170182d4fe64ecfc7b2261))

* Action Mailerメッセージの生成が計測されるようになりました。メッセージを生成するのにかかった時間がログに記録されます。([Pull Request](https://github.com/rails/rails/pull/12556))


Active Record
-------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md) を参照してください。

### 削除されたもの

* `SchemaCache`メソッド (`primary_keys`、`tables`、`columns`、`columns_hash`) にnilを渡す非推奨機能が削除されました。

* 非推奨のブロックフィルタが`ActiveRecord::Migrator#migrate`から削除されました。

* 非推奨のStringコンストラクタが`ActiveRecord::Migrator`から削除されました。

* `scope`で呼び出し可能オブジェクトを渡さない用法が削除されました。

* 非推奨の`transaction_joinable=`が削除されました。`:joinable`オプション付きで`begin_transaction`をお使いください。

* 非推奨の`decrement_open_transactions`が削除されました。

* 非推奨の`increment_open_transactions`が削除されました。

* 非推奨の`PostgreSQLAdapter#outside_transaction?`メソッドが削除されました。代りに`#transaction_open?`をお使いください。

* 非推奨の`ActiveRecord::Fixtures.find_table_name`が削除されました。`ActiveRecord::Fixtures.default_fixture_model_name`をお使いください。

* 非推奨の`columns_for_remove`が`SchemaStatements`削除されました。

* 非推奨の`SchemaStatements#distinct`が削除されました。

* 非推奨の`ActiveRecord::TestCase`がRailsテストスイートに移動しました。このクラスはpublicでなくなり、Railsテストの内部でのみ使用されます。

* 関連付けの`:dependent`で、非推奨の`:restrict`オプションのサポートが削除されました。

* 関連付けにおいて、非推奨の`:delete_sql`、`:insert_sql`、`:finder_sql`、`:counter_sql`オプションが削除されました。

* Columnから非推奨の`type_cast_code`が削除されました。

* 非推奨の`ActiveRecord::Base#connection`メソッドが削除されました。このメソッドにはクラス経由でアクセスするようにしてください。

* `auto_explain_threshold_in_seconds`における非推奨の警告が削除されました。

* `Relation#count`から非推奨の`:distinct`オプションが削除されました。

* 非推奨の`partial_updates`、`partial_updates?`、`partial_updates=`が削除されました。

* 非推奨の`scoped`メソッドが削除されました。

* 非推奨の`default_scopes?`が削除されました。

* 4.0で非推奨だった、暗黙の結合参照が削除されました。

* 依存関係としての`activerecord-deprecated_finders`が削除されました。詳細については[gem README](https://github.com/rails/activerecord-deprecated_finders#active-record-deprecated-finders)を参照してください。

* `implicit_readonly`の用法が削除されました。明示的に`readonly`メソッドを使用してレコードを`readonly`に設定してください。([Pull Request](https://github.com/rails/rails/pull/10769))

### 非推奨

* `quoted_locking_column`メソッドは非推奨です。現在使われている場所はありません。

* `ConnectionAdapters::SchemaStatements#distinct`は内部で使用されなくなったため非推奨です。([Pull Request](https://github.com/rails/rails/pull/10556))

* `rake db:test:*`タスクは非推奨となりました。データベースは自動的にメンテナンスされます。railtiesのリリースノートを参照してください。([Pull Request](https://github.com/rails/rails/pull/13528))

* 使用されていない`ActiveRecord::Base.symbolized_base_class`、および置き換えのない`ActiveRecord::Base.symbolized_sti_name`は非推奨になりました。[Commit](https://github.com/rails/rails/commit/97e7ca48c139ea5cce2fa9b4be631946252a1ebd)

### 主な変更点

デフォルトのスコープは、条件を連鎖した場合にオーバーライドされなくなりました。

  今回の変更より前にモデルで`default_scope`を定義していた場合、同じフィールドで条件が連鎖している場合にはオーバーライドされていました。現在は、他のスコープと同様、マージされるようになりました。[詳細](upgrading_ruby_on_rails.html#デフォルトスコープの変更)

* モデルの属性やメソッドから派生する便利な "pretty" URL用に`ActiveRecord::Base.to_param`が追加されました。([Pull Request](https://github.com/rails/rails/pull/12891))

* `ActiveRecord::Base.no_touching`が追加されました。モデルへのタッチを無視します。([Pull Request](https://github.com/rails/rails/pull/12772))

* `MysqlAdapter`および`Mysql2Adapter`における型変換の真偽値が統一されました。`type_cast`は`true`の場合に`1を、`false`の場合に`2`を返します。([Pull Request](https://github.com/rails/rails/pull/12425))

* `.unscope`を指定すると`default_scope`で指定された条件が削除されます。([Commit](https://github.com/rails/rails/commit/94924dc32baf78f13e289172534c2e71c9c8cade))

* `ActiveRecord::QueryMethods#rewhere`が追加されました。既存の名前付きwhere条件をオーバーライドします。([Commit](https://github.com/rails/rails/commit/f950b2699f97749ef706c6939a84dfc85f0b05f2))

* `ActiveRecord::Base#cache_key`が拡張され、timestamp属性のリストをオプションで取れるようになりました。timestamp属性リストのうち最大値が使用されます。([Commit](https://github.com/rails/rails/commit/e94e97ca796c0759d8fcb8f946a3bbc60252d329))

* enum属性を宣言する`ActiveRecord::Base#enum`が追加されました。enum属性はデータベースのintegerにマップされますが、名前でクエリできます。([Commit](https://github.com/rails/rails/commit/db41eb8a6ea88b854bf5cd11070ea4245e1639c5))

* json値が書き込み時に型変換されます。これにより値がデータベースからの読み出し時と一貫します。([Pull Request](https://github.com/rails/rails/pull/12643))

* hstore値が書き込み時に型変換されます。これにより値がデータベースからの読み出し時と一致します。([Commit](https://github.com/rails/rails/commit/5ac2341fab689344991b2a4817bd2bc8b3edac9d))

* サードパーティ製ジェネレータ用に、`next_migration_number`がアクセス可能になりました。([Pull Request](https://github.com/rails/rails/pull/12407))

* 引数を`nil`にして`update_attributes`を呼び出すと、常に`ArgumentError`エラーが発生します。具体的には、渡された引数が`stringify_keys`に応答しない場合にエラーが発生します。([Pull Request](https://github.com/rails/rails/pull/9860))

* `CollectionAssociation#first`/`#last` (`has_many`など) による結果の取り出しで、コレクション全体を読み出すクエリの代りに、限定的なクエリが使用されるようになりました。([Pull Request](https://github.com/rails/rails/pull/12137))

* Active Recordモデルクラスの`inspect`は新しい接続を初期化しなくなりました。つまり、データベースが見つからない状態で`inspect`を呼び出した場合に例外を発生しなくなりました。([Pull Request](https://github.com/rails/rails/pull/11014))

* `count`のカラム制約が削除されました。SQLが無効な場合にはデータベース側でraiseされます。([Pull Request](https://github.com/rails/rails/pull/10710))

* Railsが逆関連付けを自動で検出するようになりました。関連付けで`:inverse_of`オプションを設定していない場合、Active Recordはヒューリスティックに逆関連付けを推測します。([Pull Request](https://github.com/rails/rails/pull/10886))

* ActiveRecord::Relationの属性のエイリアスを扱うようになりました。シンボルキーを使用すると、ActiveRecordはエイリアス化された属性名をデータベース上の実際のカラム名に翻訳します。([Pull Request](https://github.com/rails/rails/pull/7839))

* フィクスチャーのERBファイルはメインオブジェクトのコンテキストでは評価されなくなりました。複数のフィクスチャーで使用されているヘルパーメソッドは、`ActiveRecord::FixtureSet.context_class`でインクルードされるモジュール上で定義しておく必要があります。([Pull Request](https://github.com/rails/rails/pull/13022))

* RAILS_ENVが明示的に指定されている場合はテストデータベースのcreateやdropは行いません。([Pull Request](https://github.com/rails/rails/pull/13629))

`Relation`には`#map!`や`#delete_if`などのミューテーターメソッド (mutator method) が含まれなくなりました。これらのメソッドを使用したい場合は`#to_a`を呼び出して`Array`に変更してからにしてください。([Pull Request](https://github.com/rails/rails/pull/13314))

* `find_in_batches`、`find_each`、`Result#each` and `Enumerable#index_by`は、自身のサイズを計算可能な`Enumerator`を返すようになりました。([Pull Request](https://github.com/rails/rails/pull/13938))

* `scope`、`enum`とAssociationsで "dangerous" 名前衝突が発生するようになりました。([Pull Request](https://github.com/rails/rails/pull/13450), [Pull Request](https://github.com/rails/rails/pull/13896))

* `second`から`fifth`メソッドは`first`ファインダーと同様に動作します。([Pull Request](https://github.com/rails/rails/pull/13757))

* `touch`が`after_commit`と`after_rollback`コールバックを発火するようになりました。([Pull Request](https://github.com/rails/rails/pull/12031))

* `sqlite >= 3.8.0`でのパーシャルインデックスが有効になりました。([Pull Request](https://github.com/rails/rails/pull/13350))

* `change_column_null`が復元可能になりました。([Commit](https://github.com/rails/rails/commit/724509a9d5322ff502aefa90dd282ba33a281a96))

* マイグレーション後無効になったスキーマダンプにフラグが追加されました。これは新しいアプリケーションのproduction環境ではデフォルトで`false`に設定されます。([Pull Request](https://github.com/rails/rails/pull/13948))

Active Model
------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md) を参照してください。

### 非推奨

* `Validator#setup`は非推奨です。今後はバリデーターのコンストラクタ内で手動で行なう必要があります。([Commit](https://github.com/rails/rails/commit/7d84c3a2f7ede0e8d04540e9c0640de7378e9b3a))

### 主な変更点

* `ActiveModel::Dirty`に、状態を制御する新しいAPI`reset_changes` および`changes_applied`が追加されました。

* 検証の定義時に複数のコンテキストを指定できるようになりました。([Pull Request](https://github.com/rails/rails/pull/13754))

* `attribute_changed?`がハッシュを受け付けるようになり、属性が与えられた値`に`変更されたか(または与えられた値`から`変更されたか)どうかをチェックするようになりました。([Pull Request](https://github.com/rails/rails/pull/13131))


Active Support
--------------

変更の詳細については[Changelog](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) を参照してください。


### 削除されたもの

* `MultiJSON`依存が削除されました。これにより、`ActiveSupport::JSON.decode`は`MultiJSON`のオプションハッシュを受け付けなくなりました。([Pull Request](https://github.com/rails/rails/pull/10576) / [詳細](upgrading_ruby_on_rails.html#jsonの扱いの変更点))

* カスタムオブジェクトをJSONにエンコードする`encode_json`フックのサポートが削除されました。この機能は[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) gemに書き出されました。
この機能は[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) gemに書き出されました。

* 非推奨の`ActiveSupport::JSON::Variable`が代替なしで削除されました。

* 非推奨の`String#encoding_aware?`コアエクステンション (`core_ext/string/encoding`) が削除されました。

* 非推奨の`Module#local_constant_names`が削除されました。`Module#local_constants`を使用します。

* 非推奨の`DateTime.local_offset`が削除されました。`DateTime.civil_from_format`を使用します。

* 非推奨の`Logger`コアエクステンション (`core_ext/logger.rb`) が削除されました。

* 非推奨の`Time#time_with_datetime_fallback`、`Time#utc_time`、`Time#local_time`が削除されました。`Time#utc`および`Time#local`を使用します。

* 非推奨の`Hash#diff`が代替なしで削除されました。

* 非推奨の`Date#to_time_in_current_zone`が削除されました。`Date#in_time_zone`を使用します。

* 非推奨の`Proc#bind`が代替なしで削除されました。

* 非推奨の`Array#uniq_by`と`Array#uniq_by!`が削除されました。ネイティブの`Array#uniq`および`Array#uniq!`を使用してください。

* 非推奨の`ActiveSupport::BasicObject`が削除されました。`ActiveSupport::ProxyObject`を使用してください。

* 非推奨の`BufferedLogger`が削除されました。`ActiveSupport::Logger`を使用してください。

* 非推奨の`assert_present`メソッドと`assert_blank`メソッドが削除されました。`assert object.blank?`および`assert object.present?`を使用してください。

* フィルタオブジェクト用の非推奨`#filter`メソッドが削除されました。対応する別のメソッドを使用してください。(before filterの`#before`など)

* デフォルトの活用形から不規則活用の'cow' => 'kine'が削除されました。([Commit](https://github.com/rails/rails/commit/c300dca9963bda78b8f358dbcb59cabcdc5e1dc9))

### 非推奨

* 時間表現`Numeric#{ago,until,since,from_now}`が非推奨になりました。この値はAS::Durationに明示的に変換してください。例: `5.ago` => `5.seconds.ago` ([Pull Request](https://github.com/rails/rails/pull/12389))

* requireパス`active_support/core_ext/object/to_json`が非推奨になりました。`active_support/core_ext/object/json`を代りにrequireしてください。([Pull Request](https://github.com/rails/rails/pull/12203))

* `ActiveSupport::JSON::Encoding::CircularReferenceError`が非推奨になりました。この機能は[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) gemに書き出されました。([Pull Request](https://github.com/rails/rails/pull/10785) / [詳細](upgrading_ruby_on_rails.html#jsonの扱いの変更点))

* `ActiveSupport.encode_big_decimal_as_string`オプションが非推奨になりました。この機能は[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) gemに書き出されました。
([Pull Request](https://github.com/rails/rails/pull/13060) / [詳細](upgrading_ruby_on_rails.html#jsonの扱いの変更点))

* カスタムの`BigDecimal`シリアライズが非推奨になりました。([Pull Request](https://github.com/rails/rails/pull/13911))

### 主な変更点

* `ActiveSupport`のJSONエンコーダーが書き直され、pure-RubyのカスタムエンコーディングではなくJSON gemを利用するようになりました。
([Pull Request](https://github.com/rails/rails/pull/12183) / [詳細](upgrading_ruby_on_rails.html#jsonの扱いの変更点))

* JSON gemとの互換性が向上しました。
([Pull Request](https://github.com/rails/rails/pull/12862) / [詳細](upgrading_ruby_on_rails.html#jsonの扱いの変更点))

* `ActiveSupport::Testing::TimeHelpers#travel`および`#travel_to`が追加されました。これらのメソッドは、`Time.now`および`Date.today`をスタブ化することによって、現在時刻を指定の時刻または時間に変換します。

* `ActiveSupport::Testing::TimeHelpers#travel_back`が追加されました。このメソッドは、`travel`および`travel_to`メソッドによって追加されたスタブを削除することで、現在時刻を元の状態に戻します。([Pull Request](https://github.com/rails/rails/pull/13884))

* `Numeric#in_milliseconds`が追加されました。`1.hour.in_milliseconds`のように使用でき、これを`getTime()`などのJavaScript関数に渡すことができます。([Commit](https://github.com/rails/rails/commit/423249504a2b468d7a273cbe6accf4f21cb0e643))

* `Date#middle_of_day`、`DateTime#middle_of_day`、`Time#middle_of_day`メソッドが追加されました。エイリアスとして`midday`、`noon`、`at_midday`、`at_noon`、`at_middle_of_day`も追加されました。([Pull Request](https://github.com/rails/rails/pull/10879))

* 期間を生成するための`Date#all_week/month/quarter/year`が追加されました。([Pull Request](https://github.com/rails/rails/pull/9685))

* `Time.zone.yesterday`と`Time.zone.tomorrow`が追加されました。([Pull Request](https://github.com/rails/rails/pull/12822))

* よく使用される`String#gsub("pattern,'')`の省略表現として`String#remove(pattern)`が追加されました。([Commit](https://github.com/rails/rails/commit/5da23a3f921f0a4a3139495d2779ab0d3bd4cb5f))

* 値がnilの項目をハッシュから削除するための`Hash#compact`および`Hash#compact!`が追加されました。([Pull Request](https://github.com/rails/rails/pull/13632))

* `blank?`および`present?`はシングルトンを返します。([Commit](https://github.com/rails/rails/commit/126dc47665c65cd129967cbd8a5926dddd0aa514))

* 新しい`I18n.enforce_available_locales` configのデフォルトは`true`です。これは、ロケールに渡された`I18n`が`available_locales`リストに載っていなければならないということです。([Pull Request](https://github.com/rails/rails/pull/13341))

`Module#concerning`が導入されました。自然かつ堅苦しくない方法で、クラスから責任を分離します。([Commit](https://github.com/rails/rails/commit/1eee0ca6de975b42524105a59e0521d18b38ab81))

* `Object#presence_in`が追加されました。値のホワイトリスト化を簡略化します。([Commit](https://github.com/rails/rails/commit/4edca106daacc5a159289eae255207d160f22396))


クレジット表記
-------

膨大な時間を費やしてRailsを作り、頑丈かつ安定したフレームワークにしてくれた多くの皆様については、[Railsコントリビューターの完全なリスト](http://contributors.rubyonrails.org/)を参照してください。これらの方々全員に敬意を表明いたします。