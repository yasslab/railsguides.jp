Ruby on Rails 5.1 リリースノート
===============================

Rails 5.1 の注目ポイント

* Yarnのサポート
* Webpackのサポート（オプション）
* デフォルトでのjQuery依存を廃止
* システムテスト
* 秘密情報の暗号化
* パラメータ化されたmailer
* directルーティングとresolvedルーティング
* form_forとform_tagのform_withへの統合

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/5-1-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------


Rails 5.1へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 5.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 5.0にアップデートしてください。アップグレードの注意点などについては[Ruby on Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-5-0からrails-5-1へのアップグレード) を参照してください。


主要な変更
--------------

### Yarnのサポート

[Pull Request](https://github.com/rails/rails/pull/26836)

Rails 5.1より、JavaScriptの依存管理をnpmからYarnに変更できるようになりました。ReactやVueJSをはじめ、あらゆるnpmライブラリを簡単に利用できます。Yarnサポートはアセットパイプラインに統合されるので、あらゆるライブラリ依存がRails 5.1アプリケーションでシームレスに動作します。

### Webpackのサポート（オプション）

[Pull Request](https://github.com/rails/rails/pull/27288)

新しい[Webpacker](https://github.com/rails/webpacker) gemの導入によって、JavaScriptのアセット用bundlerとも言うべき[Webpack](https://webpack.js.org/)を簡単にRailsアプリケーションに統合できるようになりました。Railsアプリケーションを新規に生成するときに`--webpack`フラグを付けることで、Webpack統合が有効になります。

統合されたWebpackはアセットパイプラインとの完全互換が保たれます。画像・フォント・音声などのアセットも従来どおりアセットパイプラインで利用できます。また、一部のJavaScriptコードをアセットパイプラインで管理し、その他のJavaScriptコードをWebpack経由で処理する、といったこともできます。これらはすべて、デフォルトで有効なYarnで管理されます。

### デフォルトでのjQuery依存を廃止

[Pull Request](https://github.com/rails/rails/pull/27113)

従来のRailsでは、`data-remote`や`data-confirm`についてはjQueryに依存し、その他の機能をUnobtrusive JavaScript（UJS: 控えめなJavaScript）に依存する形で機能を提供していました。Rails 5.1からはこれらの依存が解消され、UJSはvanilla JavaScript（=純粋なJavaScript）で書き直されました。このコードはAction View内部で`rails-ujs`としてリリースされています。

デフォルトではjQueryに依存しなくなりましたが、必要に応じて従来どおりjQueryに依存することもできます。

### システムテスト

[Pull Request](https://github.com/rails/rails/pull/26703)

Rails 5.1でCapybaraが標準サポートされ、システムテストの形式内でCapybaraでテストを書けるようになりました。今後はCapybaraの設定を気にする必要も、テストでデータベースのクリーニングを気にする必要もありません。Rails 5.1ではChrome用にテストを実行するためのラッパーが提供され、テスト失敗時に自動的にスクリーンショットを作成するなどの機能が追加されました。

### 秘密情報の暗号化

[Pull Request](https://github.com/rails/rails/pull/28038)

[sekrets](https://github.com/ahoward/sekrets) gemの手法にならい、Railsアプリケーションの秘密情報を安全に管理できるようになりました。

暗号化済みの秘密情報ファイルを生成するには`bin/rails secrets:setup`を実行します。このコマンドを実行するとマスターキーも同時に生成されます（マスターキーはリポジトリには絶対保存しないでください）。これにより、暗号化された秘密情報ファイルをGitなどのリビジョンコントロールシステムに安全にチェックインできるようになります。

production環境では、マスターキーを`RAILS_MASTER_KEY`環境変数やキーファイルに保存することで、秘密情報の暗号は自動解除されます。

### パラメータ化されたmailer

[Pull Request](https://github.com/rails/rails/pull/27825)

mailer用クラス内の全メソッドで利用する共通のパラメータを指定できるようになりました。これにより、インスタンス変数やヘッダーなどの共通設定を共有できます。

```ruby
 class InvitationsMailer < ApplicationMailer
  before_action { @inviter, @invitee = params[:inviter], params[:invitee] }
  before_action { @account = params[:inviter].account }

  def account_invitation
    mail subject: "#{@inviter.name} invited you to their Basecamp (#{@account.name})"
  end 
end

InvitationsMailer.with(inviter: person_a, invitee: person_b)
                 .account_invitation.deliver_later
```

### directルーティングとresolvedルーティング

[Pull Request](https://github.com/rails/rails/pull/23138)

Rails 5.1のルーティングDSLに`resolve`と`direct`という2つのメソッドが追加されました。`resolve`メソッドを使うと、モデルのポリモーフィックマッピングを以下のようにカスタマイズできます。

```ruby
 resource :basket

resolve("Basket") { [:basket] }
```

```erb
<%= form_for @basket do |form| %>
  <!-- basket form -->
<% end %>
```

上の場合、従来の`/baskets/:id`ではなく、単一の`/basket`というURLが生成されます。

`direct`メソッドを使うと、以下のようにカスタムURLヘルパーメソッドを作成できます。

```ruby
 direct(:homepage) { "http://www.rubyonrails.org" }

>> homepage_url
=> "http://www.rubyonrails.org"
```

ブロックの戻り値には、`url_for`メソッドに引数として渡せる有効なものを使う必要があります。つまり、`direct`メソッドには、有効な文字列URL、ハッシュ、配列、Active Modelインスタンス、Active Modelクラスを渡せます。

```ruby
 direct :commentable do |model|
  [ model, anchor: model.dom_id ]
end 

direct :main do
  { controller: 'pages', action: 'index', subdomain: 'www' }
end 
```

### form_forとform_tagのform_withへの統合

[Pull Request](https://github.com/rails/rails/pull/26976)

Rails 5.1より前のHTMLフォーム生成メソッドは、モデルインスタンス用の`form_for`と、カスタムURL用の`form_tag`の2種類がありました。

Rails 5.1ではこの2つのインターフェイスを`form_with`に統合し、URLベース、スコープ、モデルを指定してformタグを生成できるようになりました。

URLのみを指定する場合は次のようにします。

```erb
<%= form_with url: posts_path do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# ↓生成されるタグ %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="title">
</form>
```

inputフィールド名にスコープをプレフィックスとして追加する場合は以下のようにします。

```erb
<%= form_with scope: :post, url: posts_path do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# ↓生成されるタグ %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="post[title]">
</form>
```

モデルを指定して、URLとスコープを自動推論させるには以下のようにします。

```erb
<%= form_with model: Post.new do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# ↓生成されるタグ %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="post[title]">
</form>
```

既存のモデルの場合は更新用フォームが生成され、フィールドに値が表示されます。

```erb
<%= form_with model: Post.first do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# ↓生成されるタグ %>

<form action="/posts/1" method="post" data-remote="true">
  <input type="hidden" name="_method" value="patch">
  <input type="text" name="post[title]" value="<postのtitle>">
</form>
```

非互換性
-----------------

以下の変更については、アップグレード時に対応が必要となることがあります。

### 複数接続を用いるトランザクションテスト

トランザクションテストでは、データベーストランザクションにおいてActive Recordのすべての接続がラップされるようになりました。

テスト中にスレッドが生成され、かつそれらのスレッドがデータベース接続を取得する場合は、データベース接続について特別の注意が必要になります。

マネージドトランザクション内において、スレッドは個数にかかわらず単一のデータベース接続を共有します。このため、データベース接続のステータスはすべてのスレッドから見て同じになり、最も外側のトランザクションは無視されます。従来、こうした追加接続はfixtureのrowなどを参照できませんでした。

ネストしたトランザクション内に入ったスレッドでは、独立性を保つために一時的に接続を専有します。

アプリケーションの現在のテストが、生成されたスレッド内で（トランザクションの外にある）接続を個別に取得することを前提としている場合は、接続を明示的に管理する必要があります。

ただし、明示的なデータベーストランザクションを利用するようテストを変更すると、テストで生成されるスレッドが互いに関連して動作する場合にデッドロックが発生する可能性があります。

この新しい振る舞いを無効にする簡単な方法は、影響を受けるすべてのテストケースでトランザクションテストを無効にすることです。

Railties
--------

変更の詳細については[Changelog][railties]を参照してください。

### 削除されたもの

*   非推奨の`config.static_cache_control`を削除
    ([commit](https://github.com/rails/rails/commit/c861decd44198f8d7d774ee6a74194d1ac1a5a13))

*   非推奨の`config.serve_static_files`を削除
    ([commit](https://github.com/rails/rails/commit/0129ca2eeb6d5b2ea8c6e6be38eeb770fe45f1fa))

*   非推奨の`rails/rack/debugger`ファイルを削除
    ([commit](https://github.com/rails/rails/commit/7563bf7b46e6f04e160d664e284a33052f9804b8))

*   非推奨のタスク`rails:update`、`rails:template`、`rails:template:copy`、`rails:update:configs`、`rails:update:bin`を削除

    ([commit](https://github.com/rails/rails/commit/f7782812f7e727178e4a743aa2874c078b722eef))

*   `routes`タスクで非推奨の`CONTROLLER`環境変数を削除
    ([commit](https://github.com/rails/rails/commit/f9ed83321ac1d1902578a0aacdfe55d3db754219))

*   `rails new`コマンドから -j (--javascript)オプションを削除
    ([Pull Request](https://github.com/rails/rails/pull/28546))

### 主な変更点

*   `config/secrets.yml`に、全環境で読み込まれる共有のセクションを追加
    ([commit](https://github.com/rails/rails/commit/e530534265d2c32b5c5f772e81cb9002dcf5e9cf))

*   `config/secrets.yml`ですべてのキーをシンボルとして読み込むようになった
    ([Pull Request](https://github.com/rails/rails/pull/26929))

*   デフォルトスタックからjquery-railsを削除: rails-ujsはAction Viewの一部としてリリースされ、デフォルトのUJSアダプタとしてインクルードされる
    ([Pull Request](https://github.com/rails/rails/pull/27113))

*   新しいアプリケーションでyarnをサポート: yarn binstubとpackage.jsonを追加
    ([Pull Request](https://github.com/rails/rails/pull/26836))

*   新しいアプリケーションでWebpackをサポート: `--webpack`オプションを指定するとrails/webpacker gemに委譲される
    ([Pull Request](https://github.com/rails/rails/pull/27288))

*   新しいアプリケーションにGitリポジトリを追加（`--skip-git`を指定しない場合）
    ([Pull Request](https://github.com/rails/rails/pull/27632))

*   `config/secrets.yml.enc`に暗号化済み秘密情報を追加
    ([Pull Request](https://github.com/rails/rails/pull/28038))

*   `rails initializers`にrailtieクラス名を表示
    ([Pull Request](https://github.com/rails/rails/pull/25257))

Action Cable
-----------

変更の詳細については[Changelog][action-cable]を参照してください。

### 主な変更点

*   `cable.yml`のRadisアダプタとイベントベースRedisのアダプタで`channel_prefix`をサポート: 複数のRailsアプリケーションで同じRedisサーバーが使われている場合の名前衝突回避のため
    ([Pull Request](https://github.com/rails/rails/pull/27425))

*   データブロードキャスティング用の`ActiveSupport::Notifications`フックを追加
    ([Pull Request](https://github.com/rails/rails/pull/24988))

Action Pack
-----------

変更の詳細については[Changelog][action-pack]を参照してください。

### 削除されたもの

*   `ActionDispatch::IntegrationTest`クラスと`ActionController::TestCase`クラスで`#process`、`#get`、`#post`、`#patch`、`#put`、`#delete`、`#head`の非キーワード引数サポートを廃止
    ([Commit](https://github.com/rails/rails/commit/98b8309569a326910a723f521911e54994b112fb),
    [Commit](https://github.com/rails/rails/commit/de9542acd56f60d281465a59eac11e15ca8b3323))

*   非推奨の`ActionDispatch::Callbacks.to_prepare`と`ActionDispatch::Callbacks.to_cleanup`を削除
    ([Commit](https://github.com/rails/rails/commit/3f2b7d60a52ffb2ad2d4fcf889c06b631db1946b))

*   コントローラのフィルタに関連する非推奨メソッドを削除
    ([Commit](https://github.com/rails/rails/commit/d7be30e8babf5e37a891522869e7b0191b79b757))

*   `render` メソッドのキーワード引数 `:text`、`:nothing` のサポートを削除
    ([Commit](https://github.com/rails/rails/commit/79a5ea9eadb4d43b62afacedc0706cbe88c54496),
    [Commit](https://github.com/rails/rails/commit/57e1c99a280bdc1b324936a690350320a1cd8111))

*   `ActionController::Parameters` における `HashWithIndifferentAccess` のメソッド呼び出しのサポートを削除
    ([Commit](https://github.com/rails/rails/pull/26746/commits/7093ceb480ad6a0a91b511832dad4c6a86981b93))

### 非推奨

*  パスパラメータ`:controller`と`:action`を非推奨に指定。
    ([Pull Request](https://github.com/rails/rails/pull/23980))

*   `config.action_controller.raise_on_unfiltered_parameters`を非推奨に指定。Rails 5.1では既に無効。
    ([Commit](https://github.com/rails/rails/commit/c6640fb62b10db26004a998d2ece98baede509e5))

### 主な変更点

*   ルーティングDSLに`direct`メソッドと`resolve`メソッドを追加
    ([Pull Request](https://github.com/rails/rails/pull/23138))

*   アプリケーションのシステムテスト作成用クラス `ActionDispatch::SystemTestCase`を追加
    ([Pull Request](https://github.com/rails/rails/pull/26703))

Action View
-------------

変更の詳細については[Changelog][action-view]を参照してください。

### 削除されたもの

*   非推奨の`#original_exception`を`ActionView::Template::Error`から削除
    ([commit](https://github.com/rails/rails/commit/b9ba263e5aaa151808df058f5babfed016a1879f))

*   `strip_tags`の`encode_special_chars`の名前誤りを修正
    ([Pull Request](https://github.com/rails/rails/pull/28061))

### 非推奨

*   Erubis（ERBハンドラ）を非推奨化: 今後はErubiに
    ([Pull Request](https://github.com/rails/rails/pull/27757))

### 主な変更点

*   Rails 5のデフォルトであるrawテンプレートハンドラからHTMLセーフな文字列を出力するようになった
    ([commit](https://github.com/rails/rails/commit/1de0df86695f8fa2eeae6b8b46f9b53decfa6ec8))

*   `datetime_field`と`datetime_field_tag`で`datetime-local`フィールドを生成するよう変更
    ([Pull Request](https://github.com/rails/rails/pull/25469))

*   HTMLタグ用の新しいビルダ風の構文を導入（`tag.div`、`tag.br`など）
    ([Pull Request](https://github.com/rails/rails/pull/25543))

*   `form_tag`と`form_for`を統合する`form_with`を追加
    ([Pull Request](https://github.com/rails/rails/pull/26976))

*   `check_parameters`オプションを`current_page?`に追加
    ([Pull Request](https://github.com/rails/rails/pull/27549))

Action Mailer
-------------

変更の詳細については[Changelog][action-mailer]を参照してください。

### 主な変更点

*   例外ハンドリング: mailerのアクション・メッセージ配信・遅延した配信ジョブによってraiseした例外を`rescue_from`で扱うように変更
    ([commit](https://github.com/rails/rails/commit/e35b98e6f5c54330245645f2ed40d56c74538902))

*   ファイルが添付されbodyがインラインに設定されている場合にもcontent typeをカスタマイズできるようになった
    ([Pull Request](https://github.com/rails/rails/pull/27227))

*   `default`メソッドにlambdaを値として渡せるようになった
    ([Commit](https://github.com/rails/rails/commit/1cec84ad2ddd843484ed40b1eb7492063ce71baf))

*   mailerでパラメータ付き呼び出しがサポートされた: mailerアクション間でのbeforeフィルタやdefaultsの共有に使う
    ([Commit](https://github.com/rails/rails/commit/1cec84ad2ddd843484ed40b1eb7492063ce71baf))

*   mailerアクションで受け取った引数を`args`キーの`process.action_mailer`イベントに渡せるようになった
    ([Pull Request](https://github.com/rails/rails/pull/27900))

Active Record
-------------

変更の詳細については、[Changelog][active-record]を参照してください。

### 削除されたもの

*  `ActiveRecord::QueryMethods#select`に引数とブロックを同時に渡せるサポートを削除
    ([Commit](https://github.com/rails/rails/commit/4fc3366d9d99a0eb19e45ad2bf38534efbf8c8ce))

*   非推奨の`activerecord.errors.messages.restrict_dependent_destroy.one`と`activerecord.errors.messages.restrict_dependent_destroy.many` i18nスコープを削除
    ([Commit](https://github.com/rails/rails/commit/00e3973a311))

*   singularとcollectionにある関連付け読み出しメソッド`reader`から引数の強制再読込オプション（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/09cac8c67af))

*   `#quote`にカラムを渡すサポート（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/e646bad5b7c))

*   `#tables`メソッドから`name`引数（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/d5be101dd02214468a27b6839ffe338cfe8ef5f3))

*   `#tables`と`#table_exists?`から非推奨の動作を削除: `#table_exists?`がテーブルとビューを両方返していたのをテーブルだけを返すようになった
    ([Commit](https://github.com/rails/rails/commit/5973a984c369a63720c2ac18b71012b8347479a8))

*   `ActiveRecord::StatementInvalid#initialize`と`ActiveRecord::StatementInvalid#original_exception`から非推奨の`original_exception`引数を削除
    ([Commit](https://github.com/rails/rails/commit/bc6c5df4699d3f6b4a61dd12328f9e0f1bd6cf46))

*   クエリにクラスを値として渡せるサポート（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/b4664864c972463c7437ad983832d2582186e886))

*   LIMITにカンマを使うクエリのサポート（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/fc3e67964753fb5166ccbd2030d7382e1976f393))

*   `#destroy_all`から非推奨の`conditions`パラメータを削除
    ([Commit](https://github.com/rails/rails/commit/d31a6d1384cd740c8518d0bf695b550d2a3a4e9b))

*   `#delete_all`から非推奨の`conditions`パラメータを削除
    ([Commit](https://github.com/rails/rails/pull/27503/commits/e7381d289e4f8751dcec9553dcb4d32153bd922b))

*   非推奨の`#load_schema_for`を削除して`#load_schema`に置き換え
    ([Commit](https://github.com/rails/rails/commit/419e06b56c3b0229f0c72d3e4cdf59d34d8e5545))

*   非推奨の`#raise_in_transactional_callbacks`設定を削除
    ([Commit](https://github.com/rails/rails/commit/8029f779b8a1dd9848fee0b7967c2e0849bf6e07))

*   非推奨の`#use_transactional_fixtures`設定を削除
    ([Commit](https://github.com/rails/rails/commit/3955218dc163f61c932ee80af525e7cd440514b3))

### 非推奨

*   `error_on_ignored_order_or_limit`フラグを非推奨化: 今後は`error_on_ignored_order`を使用
    ([Commit](https://github.com/rails/rails/commit/451437c6f57e66cc7586ec966e530493927098c7))

*   `sanitize_conditions`を非推奨化: 今後は`sanitize_sql`を使用
    ([Pull Request](https://github.com/rails/rails/pull/25999))

*   接続アダプタのDeprecated `supports_migrations?`を非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/28172))

*   `Migrator.schema_migrations_table_name`を非推奨化: 今後は,`SchemaMigration.table_name`を使用
    ([Pull Request](https://github.com/rails/rails/pull/28351))

*   引用符追加や型変換で使われていた`#quoted_id`を非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/27962))

*   `#index_name_exists?`に`default`を渡すことを非推奨化
    ([Pull Request](https://github.com/rails/rails/pull/26930))

### 主な変更点

*   主キーのデフォルト型をBIGINTに変更
    ([Pull Request](https://github.com/rails/rails/pull/26266))

*   virtualカラムとgeneratedカラムのサポート（MySQL 5.7.5+、MariaDB 5.2.0+）
    ([Commit](https://github.com/rails/rails/commit/65bf1c60053e727835e06392d27a2fb49665484c))

*   バッチ処理を制限するサポートを追加
    ([Commit](https://github.com/rails/rails/commit/451437c6f57e66cc7586ec966e530493927098c7))

*   データベーストランザクション内のすべてのActive Record接続をトランザクションテストでラップするようになった
    ([Pull Request](https://github.com/rails/rails/pull/28726))

*   `mysqldump`コマンドの出力に含まれるコメントをデフォルトでスキップするようになった
    ([Pull Request](https://github.com/rails/rails/pull/23301))

*   `ActiveRecord::Relation#count`の修正: 従来は引数にブロックを渡すとエラーなしで無視されたが、Rubyの`Enumerable#count`でレコード数をカウントするようになった
    ([Pull Request](https://github.com/rails/rails/pull/24203))

*   `psql`コマンドに`"-v ON_ERROR_STOP=1"`フラグを渡し、SQLエラー出力を抑制しないようになった
    ([Pull Request](https://github.com/rails/rails/pull/24773))

*   `ActiveRecord::Base.connection_pool.stat`を追加
    ([Pull Request](https://github.com/rails/rails/pull/26988))

*   `ActiveRecord::Migration`を直接継承するとエラーをraiseするようになった: 今後はマイグレーションの対象となるRailsバージョンを指定する必要がある
    ([Commit](https://github.com/rails/rails/commit/249f71a22ab21c03915da5606a063d321f04d4d3))

*   `through`関連付けにあいまいなreflection名がある場合にエラーをraiseするようになった
    ([Commit](https://github.com/rails/rails/commit/0944182ad7ed70d99b078b22426cbf844edd3f61))

Active Model
------------

変更の詳細については[Changelog][active-model]を参照してください。

### 削除されたもの

*   `ActiveModel::Errors`の非推奨のメソッドを削除
    ([commit](https://github.com/rails/rails/commit/9de6457ab0767ebab7f2c8bc583420fda072e2bd))

*   lengthバリデータから非推奨の`:tokenizer`オプションを削除
    ([commit](https://github.com/rails/rails/commit/6a78e0ecd6122a6b1be9a95e6c4e21e10e429513))

*   戻り値がfalseの場合にコールバックを停止する動作（非推奨）を削除
    ([commit](https://github.com/rails/rails/commit/3a25cdca3e0d29ee2040931d0cb6c275d612dffe))

### 主な変更点

*   モデルの属性への関連付けに使われる元の文字列が誤ってfrozenにならないようになった
    ([Pull Request](https://github.com/rails/rails/pull/28729))

Active Job
-----------

変更の詳細については[Changelog][active-job]を参照してください。

### 削除されたもの

*   `.queue_adapter`にアダプタのクラスを渡すサポート（非推奨）を削除
    ([commit](https://github.com/rails/rails/commit/d1fc0a5eb286600abf8505516897b96c2f1ef3f6))

*   `ActiveJob::DeserializationError`から非推奨の`#original_exception`を削除
    ([commit](https://github.com/rails/rails/commit/d861a1fcf8401a173876489d8cee1ede1cecde3b))

### 主な変更点

*   `ActiveJob::Base.retry_on`や`ActiveJob::Base.discard_on`による宣言的な例外ハンドリングを追加
    ([Pull Request](https://github.com/rails/rails/pull/25991))

*   yieldされるジョブインスタンスで、リトライ失敗後にカスタムロジックで`job.arguments`などにアクセスできるようになった
    ([commit](https://github.com/rails/rails/commit/a1e4c197cb12fef66530a2edfaeda75566088d1f))

Active Support
--------------

変更の詳細については[Changelog][active-support]を参照してください。

### 削除されたもの

*   `ActiveSupport::Concurrency::Latch`クラスを削除
    ([Commit](https://github.com/rails/rails/commit/0d7bd2031b4054fbdeab0a00dd58b1b08fb7fea6))

*   `halt_callback_chains_on_return_false`を削除
    ([Commit](https://github.com/rails/rails/commit/4e63ce53fc25c3bc15c5ebf54bab54fa847ee02a))

*   戻り値がfalseの場合にコールバックを停止する動作（非推奨）を削除
    ([Commit](https://github.com/rails/rails/commit/3a25cdca3e0d29ee2040931d0cb6c275d612dffe))

### 非推奨

*   トップレベルの`HashWithIndifferentAccess`クラスをやや弱めに非推奨化: 今後は`ActiveSupport::HashWithIndifferentAccess`クラスを使用
    ([Pull Request](https://github.com/rails/rails/pull/28157))

*   `set_callback`や`skip_callback`で`:if`条件オプションや`:unless`条件オプションに文字列を渡すことを非推奨化
    ([Commit](https://github.com/rails/rails/commit/0952552))

### 主な変更点

*   期間の解析や移動をDSTの変更全体に渡って統一した
    ([Commit](https://github.com/rails/rails/commit/8931916f4a1c1d8e70c06063ba63928c5c7eab1e),
    [Pull Request](https://github.com/rails/rails/pull/26597))

*   Unicodeバージョンを9.0.0にアップデート
    ([Pull Request](https://github.com/rails/rails/pull/27822))

*   `Duration#before`（`#ago`のエイリアス）と`#after（`#since`のエイリアス）を追加
    ([Pull Request](https://github.com/rails/rails/pull/27721))

*   `Module#delegate_missing_to`を追加: 現在のオブジェクトで定義されていない、（プロキシオブジェクトへの）メソッド呼び出しの委譲に使う
    ([Pull Request](https://github.com/rails/rails/pull/23930))

*   `Date#all_day`を追加: 現在の日時の「その日全体」を表す期間を返す
    ([Pull Request](https://github.com/rails/rails/pull/24930))

*   テスト用の`assert_changes`メソッドと`assert_no_changes`メソッドを導入
    ([Pull Request](https://github.com/rails/rails/pull/25393))

*   `travel`メソッドと`travel_to`メソッドが、ネストした呼び出しでエラーをraiseするようになった
    ([Pull Request](https://github.com/rails/rails/pull/24890))

*   `DateTime#change`を更新し、usecとnsecをサポート
    ([Pull Request](https://github.com/rails/rails/pull/28242))

クレジット表記
-------


Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/5-1-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/5-1-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/5-1-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/5-1-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/5-1-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/5-1-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/5-1-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/5-1-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/5-1-stable/activejob/CHANGELOG.md
