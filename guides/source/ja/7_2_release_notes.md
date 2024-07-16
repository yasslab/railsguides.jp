**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Ruby on Rails 7.2 リリースノート
===============================

Rails 7.2の注目ポイント:

* Dev Container（Development Container）設定がオプションで利用可能になった
* ブラウザの最小バージョン指定がデフォルトで行われるようになった
* Ruby 3.1以上が必須になった
* PWA（Progressive Web Application）ファイルがデフォルトで生成されるようになった
* RuboCop omakaseのルールがデフォルトで使われるようになった
* GitHub CIワークフローが新規アプリケーションでデフォルトで生成されるようになった
* Brakemanが新規アプリケーションでデフォルトで有効になった
* Pumaのスレッドカウントが新しいデフォルト値で改善された
* ジョブがトランザクション内でスケジューリングされないようになった
* トランザクションごとにコミットやロールバックのコールバックを書けるようになった
* YJITがデフォルトで有効（Ruby 3.3以降で実行する場合）
* Rails Guidesのページデザインを一新
* メモリ割り当てを最適化するjemallocをデフォルトでDockerfileに設定するようになった
* bin/setupを実行するとpuma-devの設定方法を提案するようになった

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/7-2-stable)を参照してください。


--------------------------------------------------------------------------------

Rails 7.2にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.2にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-1からrails-7-2へのアップグレード)を参照してください。

主要な機能
--------------

### アプリケーションでDev Containerが設定可能になった

[Development Container](https://containers.dev/)（以下Dev Container）を使うと、コンテナ環境をフル機能の開発環境として利用可能になります。

Rails 7.2から、アプリケーションでDev Container設定を生成する機能が追加されました。追加される設定には、`.devcontainer/`フォルダ内の`Dockerfile`ファイル、`docker-compose.yml`ファイル、`devcontainer.json`ファイルなどがあります。

デフォルトのDev Containerには以下が含まれます。

* Redisコンテナ（KredisやAction Cableなどで利用）
* データベース（SQLite、Postgres、MySQL、またはMariaDB）
* ヘッドレスChromeコンテナ（システムテスト用）
* Active Storage（ローカルディスクを利用する設定、プレビュー機能が有効）

Dev Containerを利用する新規アプリケーションを生成するには、以下のコマンドを実行します。

```bash
$ rails new myapp --devcontainer
```

既存のアプリケーション用にdevcontainer設定を生成するには、`devcontainer`コマンドが利用可能です。

```bash
$ rails devcontainer
```

詳しくは、[Dev Containerでの開発ガイド](getting_started_with_devcontainer.html)を参照してください。

### ブラウザのバージョン保護機能がデフォルトで追加されるようになった

Railsの全アクションへのアクセス（または`only:`や`except:`で指定されたアクションのみへのアクセス）を許可する、ブラウザバージョン指定機能が追加されました。

`versions:`に渡したハッシュまたは名前付きセットのみが、指定バージョンより下の場合にブロックされます。

つまり、それ以外の未知のブラウザや、User-Agentヘッダーを送信していないエージェントはアクセスを許可されます。


ブロックされたブラウザには、デフォルトでHTTPステータスコード"406 Not Acceptable"が`public/406-unsupported-browser.html`ファイルで配信されます。

例:

```ruby
class ApplicationController < ActionController::Base
  # 以下をネイティブサポートするブラウザのみを許可:
  # webp画像、webプッシュ、バッジ、importmap、CSSネスティングと`:has`
  allow_browser versions: :modern
end

class ApplicationController < ActionController::Base
  # ChromeとOpera: 全バージョンを許可する
  # Internet Explorer: どのバージョンも不許可にする
  # Safari: 16.4以上を許可する
  # Firefox: 121以上を許可する
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false }
end

class MessagesController < ApplicationController
  # ApplicationControllerでブロックされるブラウザに加えて、
  # showアクションでOpera 104未満とChrome 119未満もブロックする
  allow_browser versions: { opera: 104, chrome: 119 }, only: :show
end
```

新規生成されるアプリケーションでは、このバージョン保護機能が`ApplicationController`に設定されます。

詳しくは、Rails APIドキュメントの[`allow_browser`](https://api.rubyonrails.org/classes/ActionController/AllowBrowser/ClassMethods.html#method-i-allow_browser)を参照してください。

### 最小RubyバージョンがRuby 3.1になった

従来は、Railsが古いRubyとの互換性を失うのは、Railsの新しいメジャーバージョンがリリースされた場合だけでしたが、このポリシーを変更します。その理由は、従来のポリシーではサポートが終了して久しいRubyバージョンをサポートしなければならなくなったり、Railsのメジャーバージョンを上げるたびに複数バージョンのRubyをサポート終了しなければならなくなったりするためです。

今後は、Railsのマイナーバージョンがリリースされるときに、その時点でサポートが終了しているRubyバージョンをサポート対象から外します。

Rails 7.2では、Ruby 3.1が新しい最小バージョンになります。

### PWA（Progressive Web Application）ファイルがデフォルトで生成されるようになった

Railsを用いたPWAアプリケーションの作成をより適切にサポートするための準備として、マニフェストとサービスワーカー用にデフォルトのPWAファイルを生成するようになりました。これらのファイルは`app/views/pwa`から配信され、ERBで動的にレンダリングできます。これらのファイルは、生成されたルーティングファイル内のデフォルトのルーティングとともに、rootディレクトリに明示的にマウントされます。

詳しくは、[#50528](https://github.com/rails/rails/pull/50528)を参照してください。

### RuboCopの「おまかせ」ルールがデフォルトで追加されるようになった

Railsアプリケーションに、[rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase)のルールセットで設定済みの[RuboCop](https://rubocop.org/)がデフォルトで含まれるようになりました。

Ruby は、さまざまな方言を許容するだけでなく、その多様性を尊重する、美しく表現力豊かな言語です。Rubyは、あらゆるライブラリやフレームワークやアプリケーションを統一されたスタイルだけで記述することを意図した言語ではありません。あなたやあなたのチームが、喜びをもたらす特定のハウススタイルを培ってきた場合は、それを尊重すべきです。

このRuboCopスタイルは、特定の方言をまだ採用していない人やチームに向けたコレクションです。合理的な根拠のある設定や、少なくともRubyのコーディングスタイルを統一する設定でスタートできるデフォルトルールを採用することで、メリットを得られる方を念頭に置いています。

個別のルールは、その書き方が正しいか間違っているかではなく、Rails作成者にとっての「Railsらしい美しい書き方」を表しているに過ぎません。ルールをそのまま使うもよし、これを元に独自ルールを作るのもよし、ルール策定のヒントを得るのに使うもよし、皆さんの望むようにお使いください。

### GitHub CIワークフローがデフォルトで新規アプリケーションに追加されるようになった

Railsの新規アプリケーションに、デフォルトでGitHub CIワークフロー用のファイルが追加されるようになりました。これにより、特にRails初心者がセキュリティスキャンやlintやテストを最初から自動化できるようになります。この機能は、単体テストの開始以来行われてきたこと自然な形でを現代に引き継いだものであると私たちは考えています。

もちろんGitHub Actionsは、無料トークンを使い切った後は、プライベートリポジトリ用の商用クラウド製品として利用することになります。しかし、GitHubとRailsの緊密な関係、初心者にとって使いやすい圧倒的なプラットフォームデフォルト設定、そして初心者が身につけるのにふさわしいCI習慣を学べる教育的価値を考えると、これは許容できるトレードオフであると考えています。

### Brakemanが新規アプリケーションでデフォルトで有効になった

[Brakeman](https://brakemanscanner.org/) gemは、Railsの一般的なセキュリティ脆弱性がproduction環境に侵入するのを防ぐ優れた方法です。

新しいアプリケーションにはBrakemanがインストールされるようになり、GitHub CIワークフローと組み合わせることで、プッシュのたびに自動的に実行されます。

### Pumaのデフォルトのスレッド数が新しくなった

Railsで使われるPuma（Webサーバー）のデフォルトのスレッド数が5から3に変更されました。

最適化されたRailsアプリケーションの性質上、高速なSQLクエリとジョブ経由で実行される低速のサードパーティ呼び出しが組み合わさった状態でのスレッド数が多すぎると、RubyはGVL（Global VM Lock）が解放されるまでかなり長い間待つことになる可能性があり、レイテンシ（リクエストやレスポンスの時間）に悪影響を及ぼします。


慎重な検討と調査の結果、production環境で実際に実行されているアプリケーションで実証された経験に基づいて、デフォルトのスレッドを3にすることでコンカレンシー（並行性）とパフォーマンスのバランスが取れていると判断しました。

この変更に関する議論について詳しくは、[#50450](https://github.com/rails/rails/issues/50450)で確認できます。

### ジョブがトランザクション内でスケジューリングされないようになった

Active Jobでよくある間違いは、以下のようにトランザクションの内部でジョブをエンキューしてしまうことです。このような書き方をすると、トランザクションがコミットされる前に別のプロセスによってジョブが拾われて実行される可能性があり、さまざまなエラーが発生します。

```ruby
Topic.transaction do
  topic = Topic.create

  NewTopicNotificationJob.perform_later(topic)
end
```

Active Jobが改修されて、ジョブのエンキューをトランザクションのコミットが完了するまで自動的に延期し、トランザクションがロールバックされた場合はジョブを削除するようになりました。

この振る舞いは、さまざまなキュー実装で無効にできます。以下のようにジョブ単位で無効にしたり矯正したりできます。

```ruby
class NewTopicNotificationJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never
end
```

詳しくは、[#51426](https://github.com/rails/rails/pull/51426)を参照してください。

### トランザクションごとにコミットやロールバックのコールバックを書けるようになった

この機能は、トランザクションコールバックをレコードの外で登録可能になったことで実現できました。

`ActiveRecord::Base.transaction`は`ActiveRecord::Transaction`オブジェクトを`yield`するようになりました。ここにコールバックを登録できます。

```ruby
Article.transaction do |transaction|
  article.update(published: true)

  transaction.after_commit do
    PublishNotificationMailer.with(article: article).deliver_later
  end
end
```

`ActiveRecord::Base.current_transaction`も追加され、ここにもコールバックを登録できるようになりました。

```ruby
Article.current_transaction.after_commit do
  PublishNotificationMailer.with(article: article).deliver_later
end
```

最後に、`ActiveRecord.after_all_transactions_commit`が追加されました。これは、トランザクションの内部または外部で実行される可能性があり、かつステートの変更が正しく永続化された後で実行されなければならないコードに対して使えます。

```ruby
def publish_article(article)
  article.update(published: true)

  ActiveRecord.after_all_transactions_commit do
    PublishNotificationMailer.with(article: article).deliver_later
  end
end
```

詳しくは、[#51474](https://github.com/rails/rails/pull/51474)を参照してください。

### YJITがRuby 3.3以降でデフォルトで有効になった

YJITは、Ruby 3.1以降のCRubyで利用可能なJIT（Just-In-Time）コンパイラです。YJITはRailsアプリケーションのパフォーマンスを大幅に向上させることが可能で、レイテンシを15〜25%改善できます。

Rails 7.2をRuby 3.3以降で実行すると、YJITがデフォルトで有効になります。

YJITを無効にするには以下の設定を行います。

```ruby
Rails.application.config.yjit = false
```

### Rails GuidesのWebデザインが一新された

2021年12月にリリースされたRails 7.0では、Rails公式ホームページ起動画面が新しくなりましたが、Rails GuidesのWebデザインは2009年からほとんど変更されていませんでした。この点は見逃せません（皆さんからフィードバックをいただきました）。

現在、Railsフレームワークの複雑さを解消し、ドキュメントの一貫性と明瞭性を高めて最新の内容にするための作業が全面的に進められているので、この機会にRails GuidesのWebデザインも同様にモダンかつシンプルで新鮮なものにする作業に取り組むときが来ました。

UXデザイナー[John Athayde](https://meticulous.com/)との共同作業によって、Railsホームページの新しい外観や雰囲気をRails Guidesにも取り入れ、すっきりと洗練された最新デザインに変えました。

レイアウトは従来と同じですが、今度からRails Guidesに以下の変更が反映されます。

* クリアかつシンプルなWebデザイン。
* フォント、配色、ロゴがRailsホームページと統一された。
* アイコンが更新された。
* ページ操作がシンプルになった。
* 「チャプター」ナビゲーションバーがスクロール時に固定されるようになった。

Webデザインの変更前と変更後の画像については、[Rails公式ブログのお知らせ](https://rubyonrails.org/2024/3/20/rails-guides-get-a-facelift)を参照してください。

### Dockerfileにメモリアロケーション最適化用のjemallocが設定されるようになった

Rubyのメモリアロケーションに`malloc`が使われていると、特にPumaで使われているようなマルチスレッドで[メモリ断片化問題が発生する可能性があります](https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html)。別のパターンを利用するアロケータに切り替えると、メモリ使用量を大幅に削減できる可能性があります。

Rails 7.2のDockerfileでは、メモリアロケーション最適化用の[jemalloc](https://jemalloc.net/)がデフォルトで設定されるようになりました。

### bin/setupを実行するとpuma-devの設定方法を提案するようになった

[Puma-dev](https://github.com/puma/puma-dev)は、Dockerを使っていない環境で複数のRailsアプリケーションを同居させる形でローカル開発するのに最適な方法です。

`bin/setup`を実行すると、Puma-devをセットアップする方法を提案する新しいコメントが表示されるようになりました。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails::Generators::Testing::Behaviour`を削除。

*   非推奨化されていた`Rails.application.secrets`を削除。

*   非推奨化されていた`Rails.config.enable_dependency_loading`を削除。

*   非推奨化されていた`find_cmd_and_exec`コンソールヘルパーを削除。

*   `rails new`コマンドや`rails db:system:change`コマンドから`oracle`、`sqlserver`、JRuby固有のデータベースアダプタのサポートを削除。

*   ジェネレータから`config.public_file_server.enabled`オプションを削除。

### 非推奨化

### 主な変更点

*   [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase) gemの`RuboCop`ルールを新規アプリケーションとプラグインの両方にデフォルトで追加。

*   `Brakeman`を新規アプリケーションにセキュリティチェック用デフォルト設定として追加。

*   `Dependabot`、`Brakeman`、`RuboCop`用のGitHub CIファイルを追加し、新規アプリケーションとプラグインの両方についてテストをデフォルトで実行するようになった。

*   YJITがRuby 3.3以降の新規アプリケーションでデフォルトで有効になった。

*   以下を実行することで`.devcontainer`フォルダが生成されるようになった（VS Codeでアプリケーションをコンテナ実行するのに用いられる）。

    ```bash
    $ rails new myapp --devcontainer
    ```

*   イニシャライザをテストする`Rails::Generators::Testing::Assertions#assert_initializer`が導入された。

*   新規アプリケーションのシステムテストでヘッドレスChromeがデフォルトで使われるようになった。

*   `BACKTRACE`環境変数で通常のサーバー実行時にバックトレースのクリーニングを無効にするサポートが追加された（従来はテスト時のみ利用可能だった）。

*   マニフェストおよびサービスワーカー用のPWA（Progressive Web App）ファイルがデフォルトで追加され、`app/views/pwa`から配信されるようになり、ERBで動的にレンダリング可能になった。

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActionDispatch::IllegalStateError`定数を削除。

*   非推奨化されていた`AbstractController::Helpers::MissingHelperError`定数を削除。

*   非推奨化されていた`ActionController::Parameters`と`Hash`の比較機能を削除。

*   非推奨化されていた`Rails.application.config.action_dispatch.return_only_request_media_type_on_content_type`を削除。

*   パーミッションポリシーの非推奨化されていた`speaker`、`vibrate`、`vr`ディレクティブを削除。

*   `Rails.application.config.action_dispatch.show_exceptions`の非推奨化されていた設定（`true`や`false`に設定可能）を削除。

### 非推奨化

*   `Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality`を非推奨化。

### 主な変更点

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

*   非推奨化されていた`@rails/ujs`が削除され、`Turbo`に置き換えられた。

### 非推奨化

* `tag.br`タグビルダーを使う場合に、void要素にコンテンツを渡すことが非推奨化された。

### 主な変更点

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.action_mailer.preview_path`を削除。

*   `assert_enqueued_email_with`で非推奨化されていた`:args`からのパラメータを削除。

### 非推奨化

### 主な変更点

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

*   非推奨化されていた`Rails.application.config.active_record.suppress_multiple_database_warning`を削除。

*   存在しない属性名を指定して`alias_attribute`を呼び出す非推奨化サポートを削除。

*   `ActiveRecord::Base.remove_connection`で非推奨化されていた`name`引数を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_active_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_reloadable_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.clear_all_connections!`を削除。

*   非推奨化されていた`ActiveRecord::Base.flush_idle_connections!`を削除。

*   非推奨化されていた`ActiveRecord::ActiveJobRequiredError`を削除。

*   コネクションアダプタで引数を2つ渡して`explain`を定義する非推奨化サポートを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.runtime`メソッドを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.runtime=`メソッドを削除。

*   非推奨化されていた`ActiveRecord::LogSubscriber.reset_runtime`メソッドを削除。

*   非推奨化されていた`ActiveRecord::Migration.check_pending!`メソッドを削除。

*   `ActiveRecord::MigrationContext`に`SchemaMigration`と`InternalMetadata`クラスを引数として渡す非推奨化サポートを削除。

*   単数形の関連付けを複数形の名前で参照する非推奨の振る舞いを削除。

*   非推奨化されていた`TestFixtures.fixture_path`を削除。

*   `ActiveRecord::Base#read_attribute(:id)`がカスタム主キー値を返す非推奨化サポートを削除。

*   `serialize`にコーダーやクラスを第2引数として渡す非推奨化サポートを削除。

*   データベースアダプタの非推奨化されていた`#all_foreign_keys_valid?`を削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::SchemaCache.load_from`を削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::SchemaCache#data_sources`を削除。

*   非推奨化されていた`#all_connection_pools`を削除。

*   `role`引数が指定されていない場合に、現在のロールのコネクションプールで`#connection_pool_list`、`#active_connections?`、`#clear_active_connections!`、`#clear_reloadable_connections!`、`#clear_all_connections!`、`#flush_idle_connections!`が適用される非推奨化サポートを削除。

*   非推奨化されていた`ActiveRecord::ConnectionAdapters::ConnectionPool#connection_klass`を削除。

*   非推奨化されていた`#quote_bound_value`を削除。

*   `ActiveSupport::Duration`を変換せずに式展開で渡せる非推奨化サポートを削除。

*   `add_foreign_key`に`deferrable: true`を渡す非推奨化サポートを削除。

*   `ActiveRecord::Relation#merge`に`rewhere`を渡す非推奨化サポートを削除。

*   トランザクションブロックを`return`、`break`、または`throw`で終了するとロールバックする非推奨化された振る舞いを削除。

### 非推奨化

*   `Rails.application.config.active_record.allow_deprecated_singular_associations_name`を非推奨化。

*   `Rails.application.config.active_record.commit_transaction_on_non_local_return`を非推奨化。

### 主な変更点

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

*   非推奨化されていた`config.active_storage.replace_on_assign_to_many`を削除。

*   非推奨化されていた`config.active_storage.silence_invalid_content_types_warning`を削除。

### 非推奨化

### 主な変更点

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   非推奨化されていた`ActiveSupport::Notifications::Event#children`と`ActiveSupport::Notifications::Event#parent_of?`を削除。

*   以下のメソッドをdeprecatorを渡さずに呼び出せる非推奨サポートを削除。

    - `deprecate`
    - `deprecate_constant`
    - `ActiveSupport::Deprecation::DeprecatedObjectProxy.new`
    - `ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy.new`
    - `ActiveSupport::Deprecation::DeprecatedConstantProxy.new`
    - `assert_deprecated`
    - `assert_not_deprecated`
    - `collect_deprecations`

*   非推奨化されていた`ActiveSupport::Deprecation`のインスタンスへの委譲を削除。

*   非推奨化されていた`SafeBuffer#clone_empty`を削除。

*   `#to_default_s` from `Array`、`Date`、`DateTime`、`Time`で非推奨化されていた`#to_default_s`を削除。

*   キャッシュストレージの非推奨化されていた`:pool_size`オプションと`:pool_timeout`オプションを削除。

*   非推奨化されていた`config.active_support.cache_format_version = 6.1`サポートを削除。

*   非推奨化されていた`ActiveSupport::LogSubscriber::CLEAR`定数と`ActiveSupport::LogSubscriber::BOLD`定数を削除。

*   ログテキストを`ActiveSupport::LogSubscriber#color`の位置引数ブーリアンで太字にする非推奨化サポートを削除。

*   非推奨化されていた`config.active_support.disable_to_s_conversion`を削除。

*   非推奨化されていた`config.active_support.remove_deprecated_time_with_zone_name`を削除。

*   非推奨化されていた`config.active_support.use_rfc4122_namespaced_uuids`を削除。

*   `MemCacheStore`に`Dalli::Client`インスタンスを渡せる非推奨化サポートを削除。

### 非推奨化

*   `config.active_support.to_time_preserves_timezone`を非推奨化。

*   `DateAndTime::Compatibility.preserve_timezone`を非推奨化。

### 主な変更点

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   非推奨化されていた`BigDecimal`引数向けのプリミティブなシリアライザを削除。

*   `scheduled_at`属性に数値を設定できる非推奨化サポートを削除。

*   `retry_on`の`:wait`オプションの非推奨化された`:exponentially_longer`値を削除。

### 非推奨化

*   `Rails.application.config.active_job.use_big_decimal_serialize`を非推奨化。

### 主な変更点

Action Text
----------

変更点について詳しくは[Changelog][active-text]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更点

Ruby on Rails Guides
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更点

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/7-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/7-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/7-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/7-2-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/7-2-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/7-2-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/7-2-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/7-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/7-2-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/7-2-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/7-2-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/7-2-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/7-2-stable/guides/CHANGELOG.md
