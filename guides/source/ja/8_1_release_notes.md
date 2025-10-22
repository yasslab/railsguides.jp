Ruby on Rails 8.1 リリースノート
===============================

Rails 8.1 の注目ポイント:


* Active Jobの継続機能
* 構造化イベントレポート
* ローカルCI
* Markdownレンダリング
* コマンドラインでのcredentials取得
* 関連付けの非推奨化機能
* Kamalをリモートレジストリ不要で利用可能

このリリースノートでは、主な変更点のみを取り上げています。バグ修正や変更点については、Changelogを参照するか、GitHubのRailsリポジトリにある[コミット一覧](https://github.com/rails/rails/commits/8-1-stable)を確認してください。

--------------------------------------------------------------------------------

Rails 8.1にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 8.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 8.1にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-8-0からrails-8-1へのアップグレード)を参照してください。

主要な機能
--------------

### Active Jobの継続機能

実行に時間のかかるジョブを、離散的なステップに分割可能になりました。これにより、再起動後に最初からやり直すのではなく、最後に完了したステップの続きから実行を再開できます。これは特にKamalでのデプロイ時に有用です（Kamalはジョブ実行中のコンテナにシャットダウンの猶予をデフォルトで30秒しか与えないためです）。

コード例:

```ruby
class ProcessImportJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(import_id)
    @import = Import.find(import_id)

    # ブロック形式の場合
    step :initialize do
      @import.initialize
    end

    # ステップにカーソルを設定することで、ジョブの中断時にカーソルが保存される
    step :process do |step|
      @import.records.find_each(start: step.cursor) do |record|
        record.process
        step.advance! from: record.id
      end
    end

    # メソッド形式の場合
    step :finalize
    end

  private
    def finalize
      @import.finalize
    end
end
```

## 構造化イベントレポート

Railsに組み込まれているデフォルトのロガーは、人間が読むのには適していますが、機械的な後処理にはあまり向いていませんでした。Railsに新しく追加されたイベントレポーターは、構造化されたイベントを生成するための統一されたインターフェイスをRailsアプリケーションに提供します。

```ruby
Rails.event.notify("user.signup", user_id: 123, email: "user@example.com")
```

以下のようにイベントにタグを追加できます。

```ruby
Rails.event.tagged("graphql") do
  # イベントに`{ graphql: true }`タグを追加
  Rails.event.notify("user.signup", user_id: 123, email: "user@example.com")
end
```

コンテキストを追加することも可能です。

```ruby
# すべてのイベントに`{request_id: "abc123", shop_id: 456}`コンテキストを追加
Rails.event.set_context(request_id: "abc123", shop_id: 456)
```

イベントはサブスクライバに送信されます。アプリケーションはサブスクライバを登録して、イベントのシリアライズと送信方法を制御します。サブスクライバは以下のように、イベントハッシュを受け取る`#emit`メソッドを実装しなければなりません。

```ruby
class LogSubscriber
  def emit(event)
    payload = event[:payload].map { |key, value| "#{key}=#{value}" }.join(" ")
    source_location = event[:source_location]
    log = "[#{event[:name]}] #{payload} at #{source_location[:filepath]}:#{source_location[:lineno]}"
    Rails.logger.info(log)
  end
end
```

## ローカルCI

近年の開発用コンピュータは驚くほど高速になり、多くのコアを搭載しているため、比較的大きなテストスイートでもローカルで十分実行可能です。

このため、小・中規模のアプリケーションでは、クラウドベースのCIセットアップを廃止してローカルでのCI実行に切り替えることが現実的かつ望ましい状況になっています。そこでRailsでは、`config/ci.rb`に定義することで、`bin/ci`コマンドで実行できるデフォルトのCI宣言DSLが追加されました。`config/ci.rb`の内容は以下のような感じになります。

```ruby
CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # `gh` CLIと`gh extension install basecamp/gh-signoff`が必要
  if success?
    step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  else
    failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  end
end
```

オプションで`gh`と連携することにより、CIが成功しない限りプルリクがマージ可能にならないようにできます。

## Markdownレンダリング

markdown形式は今やAIのリンガフランカ（共通語）となりつつあります。Railsは、Markdown形式のリクエストに応答して直接レンダリング可能にすることで、markdownの採用を受け入れています。

```ruby
class Page
  def to_markdown
    body
  end
end

class PagesController < ActionController::Base
  def show
    @page = Page.find(params[:id])

    respond_to do |format|
      format.html
      format.md { render markdown: @page }
    end
  end
end
```

## credentialsをコマンドラインで取得

Kamalは、デプロイ時にRailsの暗号化credentialsストアからsecrets（秘密情報）を手軽に取得できるようになりました。これにより、マスターキーさえあれば動作する外部のsecretsストアの安価な代替手段となります。

```bash
# .kamal/secrets
KAMAL_REGISTRY_PASSWORD=$(rails credentials:fetch kamal.registry_password)
```

## 関連付けの非推奨化

Active Recordの関連付けに、`deprecated: true`で非推奨化を指定できるようになりました。

```ruby
class Author < ApplicationRecord
  has_many :posts, deprecated: true
end
```

これにより、`posts`関連付けにアクセスすると、非推奨化の警告がレポートされます。以下のような明示的なAPI呼び出しも非推奨化レポートの対象となります。

```ruby
author.posts
author.posts = ...
```

以下のように関連付けを間接的に利用する場合やネステッド属性で利用する場合も、非推奨化レポートの対象となります。

```ruby
author.preload(:posts)
```

非推奨化レポートでは、3つのモードがサポートされています（`:warn`、`:raise`、`:notify`）。バックトレースは有効化または無効化できますが、報告された利用箇所の位置は常に取得されます。デフォルトは`:warn`モードで、バックトレースは無効化されています。

## Kamalをリモートレジストリ不要でデプロイ

Kamalで基本的なデプロイを行うときに、Docker HubやGitHub Container Registry（GHCR）などのリモートレジストリが不要になりました。Kamal 2.8では、シンプルなデプロイにはデフォルトでローカルレジストリを使うようになりました。大規模なデプロイでは引き続きリモートレジストリが必要ですが、これによりプロジェクトの立ち上げが容易になり、Hello Worldデプロイを実際の環境で確認しやすくなります。

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

* 非推奨化されていた`rails/console/methods.rb`ファイルを削除。

* 非推奨化されていた`bin/rake stats`コマンドを削除。

* 非推奨化されていた`STATS_DIRECTORIES`グローバル定数を削除。

### 非推奨化

### 主な変更

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

*   パラメータパーサー内で、パラメータ名の冒頭に含まれるブラケット`[]`をスキップするサポート（非推奨化）を削除。

    削除前:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "foo" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "foo" => { "bar" => "baz" } }
    ```

    削除後:

    ```ruby
    ActionDispatch::ParamBuilder.from_query_string("[foo]=bar") # => { "[foo]" => "bar" }
    ActionDispatch::ParamBuilder.from_query_string("[foo][bar]=baz") # => { "[foo]" => { "bar" => "baz" } }
    ```

*   セミコロンをクエリ文字列パラメータとして利用するサポート（非推奨化）を削除。

    削除前:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar"], ["baz", "quux"]]
    ```

    削除後:

    ```ruby
    ActionDispatch::QueryParser.each_pair("foo=bar;baz=quux").to_a
    # => [["foo", "bar;baz=quux"]]
    ```

*   複数パスへのルーティング（非推奨化）を削除。

### 非推奨化

*   `Rails.application.config.action_dispatch.ignore_leading_brackets`を非推奨化。

### 主な変更

*   新規Railsアプリでは、development環境でリダイレクトのログ出力が詳細になった。既存のアプリで有効にするには、`config/development.rb`ファイルに`config.action_dispatch.verbose_redirect_logs = true`を追加すること。

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

*   SQLite3アダプタで非推奨化されていた`:retries`オプションを削除。

*   MySQL用の非推奨化された`:unsigned_float`および`:unsigned_decimal`カラムメソッドを削除。

### 非推奨化

*   `order`を指定せずに順序依存のfinderメソッド（例: `#first`）を使うことを非推奨化（[#54608](https://github.com/rails/rails/pull/54608)）。

*   `ActiveRecord::Base.signed_id_verifier_secret`を非推奨化（[#54422](https://github.com/rails/rails/pull/54422)）。今後は、`Rails.application.message_verifiers`を使うこと（または特定モデルに固有のsecretの場合は`Model.signed_id_verifier`を使うこと）。

*   永続化されていないレコードを含む関連付けで`insert_all`/`upsert_all`を使うことを非推奨化（[#53920](https://github.com/rails/rails/pull/53920)）。

*   `update_all`で`WITH`や`WITH RECURSIVE`や`DISTINCT`を併用することを非推奨化（[#54231](https://github.com/rails/rails/pull/54231)）。

### 主な変更

*   `schema.rb`内のテーブルカラムのソート順がアルファベット順に変更された（[#53281](https://github.com/rails/rails/pull/53281)）。

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

*   非推奨化されていた`:azure`ストレージサービスを削除。

### 非推奨化

### 主な変更

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

*   `Time#since`にTimeオブジェクトを渡せるサポート（非推奨化）を削除。

*   非推奨化されていた`Benchmark.ms`メソッドを削除。現在は`benchmark` gem内で定義されている。

*   `Time`インスタンスと`ActiveSupport::TimeWithZone`を加算できる機能（非推奨化）を削除。

*   `to_time`メソッドがシステムのローカル時間を保持するサポート（非推奨化）を削除。今後は常にレシーバーのタイムゾーンを保持する。

### 非推奨化

*   `config.active_support.to_time_preserves_timezone`を非推奨化。

*   `ActiveSupport::Configurable`を非推奨化。

### 主な変更

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

*   `ActiveJob::Base.enqueue_after_transaction_commit`に`:never`、`:always`、 `:default`を設定するサポートを削除。

*   非推奨化されていた`Rails.application.config.active_job.enqueue_after_transaction_commit`を削除。

*   非推奨化されていた組み込み`SuckerPunch`アダプタを削除。今後は`sucker_punch` gemに含まれるアダプタを使うこと。

### 非推奨化

*   Active Jobのカスタムシリアライザには`#klass` publicメソッドを含めなければならない。

### 主な変更

Action Text
----------

変更点について詳しくは[Changelog][action-text]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Action Mailbox
----------

変更点について詳しくは[Changelog][action-mailbox]を参照してください。

### 削除されたもの

### 非推奨化

### 主な変更

Ruby on Rails Guides
--------------------

+変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更

クレジット
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/8_1_stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/8_1_stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/8_1_stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/8_1_stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/8_1_stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/8_1_stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/8_1_stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/8_1_stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/8_1_stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/8_1_stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/8_1_stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/8_1_stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/8_1_stable/guides/CHANGELOG.md