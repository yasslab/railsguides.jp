Ruby on Rails 7.1 リリースノート
===============================

Rails 7.1の注目ポイント:

* 新規RailsアプリケーションでDockerfilesを生成するようになった
* `ActiveRecord::Base.normalizes`を追加
* `ActiveRecord::Base.generates_token_for`を追加
* 複数ジョブを一括エンキューする`perform_all_later`
* 複合主キー
* `Trilogy`用アダプタの導入
* `ActiveSupport::MessagePack`を追加
* `config.autoload_lib`と`config.autoload_lib_once`を追加（拡張オートローディング用）
* 汎用の非同期クエリ用Active Record API
* ビューテンプレートに厳密な`locals`を設定可能になった
* `Rails.application.deprecators`を追加
* JSONの`response.parsed_body`のパターンマッチングをサポート
* `response.parsed_body`を拡張してHTMLをNokogiriでパース可能になった
* `ActionView::TestCase.register_parser`を導入

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/7-1-stable)を参照してください。

--------------------------------------------------------------------------------

Rails 7.1にアップグレードする
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 7.0までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 7.1にアップデートしてください。アップグレードの注意点などについては[Railsアップグレードガイド](upgrading_ruby_on_rails.html#rails-7-0からrails-7-1へのアップグレード)を参照してください。

主要な機能
--------------

### 新規RailsアプリケーションでDockerfileが生成されるようになった

新規Railsアプリケーションでは、デフォルトでDockerがサポートされるようになりました（[#46762][]）。
新しいアプリケーションを生成すると、そのアプリケーションにDocker関連ファイルも含まれます。

これらのファイルは、RailsアプリケーションをDockerでproduction環境にデプロイするための基本的なセットアップとして提供されます。重要なのは、これらのファイルは開発用ではないことです。

以下は、これらのDockerファイルでRailsアプリをビルドして実行する簡単な例です。

```bash
$ docker build -t app .
$ docker volume create app-storage
$ docker run --rm -it -v app-storage:/rails/storage -p 3000:3000 --env RAILS_MASTER_KEY=<your-config-master-key> app
```

Railsコンソールやランナーも、このDockerイメージから起動できます。

```bash
$ docker run --rm -it -v app-storage:/rails/storage --env RAILS_MASTER_KEY=<your-config-master-key> app console
```

マルチプラットフォーム向けイメージ（Apple SiliconをAMDやIntelデプロイするなど）を作成してDocker Hubにプッシュする方法を知りたい方は、以下の手順に沿ってください。

```bash
$ docker login -u <your-user>
$ docker buildx create --use
$ docker buildx build --push --platform=linux/amd64,linux/arm64 -t <your-user/image-name> .
```

この拡張によってデプロイプロセスがシンプルになるので、これを出発点としてRailsアプリケーションをproduction環境ですばやく立ち上げられるようにできます。

[#46762]: https://github.com/rails/rails/pull/46762

### `ActiveRecord::Base.normalizes`が追加

[`ActiveRecord::Base.normalizes`][]は属性値に対して正規化を宣言します（[#43945][]）。正規化は、属性の代入や更新のタイミングで行われ、データベースで永続化されます。正規化はfinder系メソッドの対応するキーワード引数にも適用されるので、正規化されていない値でレコードをクエリできるようになります。

例:

```ruby
class User < ActiveRecord::Base
  normalizes :email, with: -> email { email.strip.downcase }
  normalizes :phone, with: -> phone { phone.delete("^0-9").delete_prefix("1") }
end

user = User.create(email: " CRUISE-CONTROL@EXAMPLE.COM\n")
user.email                  # => "cruise-control@example.com"

user = User.find_by(email: "\tCRUISE-CONTROL@EXAMPLE.COM ")
user.email                  # => "cruise-control@example.com"
user.email_before_type_cast # => "cruise-control@example.com"

User.where(email: "\tCRUISE-CONTROL@EXAMPLE.COM ").count         # => 1
User.where(["email = ?", "\tCRUISE-CONTROL@EXAMPLE.COM "]).count # => 0

User.exists?(email: "\tCRUISE-CONTROL@EXAMPLE.COM ")         # => true
User.exists?(["email = ?", "\tCRUISE-CONTROL@EXAMPLE.COM "]) # => false

User.normalize_value_for(:phone, "+1 (555) 867-5309") # => "5558675309"
```

[`ActiveRecord::Base.normalizes`]: https://api.rubyonrails.org/v7.1/classes/ActiveRecord/Normalization/ClassMethods.html#method-i-normalizes
[#43945]: https://github.com/rails/rails/pull/43945

### `ActiveRecord::Base.generates_token_for`が追加

[`ActiveRecord::Base.generates_token_for`][]は特定の目的で利用するトークンの生成を定義します（[#44189][]）。生成されたトークンは失効させることも、レコードデータを埋め込むこともできます。トークンを用いてレコードを取得すると、トークンのデータと現在のレコードのデータが比較されます。両者が一致しない場合、トークンは無効とみなされ、期限切れとして扱われます。

単一利用の例として、パスワードリセットのトークンの実装を以下に示します。

```ruby
class User < ActiveRecord::Base
  has_secure_password

  generates_token_for :password_reset, expires_in: 15.minutes do
    # `password_salt`（`has_secure_password`で定義される）は、
    # そのパスワードのsaltを返す。パスワードが変更されるとsaltも変更されるので、
    # パスワードが変更されるとこのトークンは無効になる。
    password_salt&.last(10)
  end
end

user = User.first
token = user.generate_token_for(:password_reset)

User.find_by_token_for(:password_reset, token) # => user

user.update!(password: "new password")
User.find_by_token_for(:password_reset, token) # => nil
```

[`ActiveRecord::Base.generates_token_for`]: https://api.rubyonrails.org/v7.1/classes/ActiveRecord/TokenFor/ClassMethods.html#method-i-generates_token_for
[#44189]: https://github.com/rails/rails/pull/44189

### 大量のジョブを一度にエンキューする`perform_all_later`が追加

Active Jobの`perform_all_later`メソッドは、複数のジョブを同時にエンキューするプロセスを効率化するために設計されています（[#46603][]）。この強力な追加機能により、コールバックをトリガーせずに効率的にジョブをエンキューできるようになります。これは特に複数ジョブを一括でエンキューする必要がある場合や、データがキューデータストアと何度も往復することによるオーバーヘッドを削減したい場合に便利です。

`perform_all_later`の利用方法を以下に示します。

```ruby
# 個別のジョブをエンキューする
ActiveJob.perform_all_later(MyJob.new("hello", 42), MyJob.new("world", 0))

# ジョブの配列をエンキューする
user_jobs = User.pluck(:id).map { |id| UserJob.new(user_id: id) }
ActiveJob.perform_all_later(user_jobs)
```

 `perform_all_later`を利用することで、ジョブのエンキュー処理を最適化し、特に大量のジョブを扱うときの効率が向上します。Sidekiqアダプタなど、新しい`enqueue_all`メソッドをサポートするキューアダプタでは、`push_bulk`を使うことでさらにエンキュー処理が最適化されます。

この新しいメソッドでは、既存の`enqueue.active_job`イベントを使わず、別の`enqueue_all.active_job`イベントが導入されます。これにより、一括エンキュー処理のトラッキングとレポートが精密に行われるようになります。

[#46603]: https://github.com/rails/rails/pull/46603

### 複合主キー

データベースとアプリケーションの両方で複合主キー（composite primary key）がサポートされるようになりました。Railsはスキーマからこれらのキーを直接導出できるようになります。この機能は、「多対多」リレーションシップや、その他の複雑なデータモデルで、単一カラムだけではレコードをうまく一意に識別できない場合に特に有用です。

Active Recordのクエリメソッドで生成されるSQL（`#reload`、`#update`、`#delete`など）には、複合主キーのすべての部分が含まれます。`#first`や`#last`などのメソッドでは、`ORDER BY`ステートメントで複合主キー全体が使われます。

`query_constraints`マクロは、データベーススキーマを変更せずに同じ振る舞いを実現するための「仮想主キー」として利用できます。

例:

```ruby
class TravelRoute < ActiveRecord::Base
  query_constraints :origin, :destination
end
```

同様に、関連付けにも`query_constraints:`オプションを渡せます。このオプションは、関連付けられるレコードにアクセスするのに使うカラムのリストを設定する「複合外部キー（composite foreign key）」として機能します。

例:

```ruby
class TravelRouteReview < ActiveRecord::Base
  belongs_to :travel_route, query_constraints: [:travel_route_origin, :travel_route_destination]
end
```

### Trilogy用のアダプタが導入

MySQL互換のデータベースクライアントである`Trilogy`とRailsアプリケーションをシームレスに統合する新しいアダプターが導入されました（[#47880][]）。これにより、Railsアプリケーションで以下のように`config/database.yml`ファイルを設定することで、`Trilogy`の機能を取り込むオプションが提供されます。

```yaml
development:
  adapter: trilogy
  database: blog_development
  pool: 5
```

または、以下のように`DATABASE_URL`環境変数で統合することも可能です。

```ruby
ENV["DATABASE_URL"] # => "trilogy://localhost/blog_development?pool=5"
```

[#47880]: https://github.com/rails/rails/pull/47880

### `ActiveSupport::MessagePack`が追加

[`ActiveSupport::MessagePack`][]は、[`msgpack`](https://github.com/msgpack/msgpack-ruby) gemと統合されたシリアライザです（[#47770][]）。`ActiveSupport::MessagePack`は、`msgpack`でサポートされている基本的なRubyの型に加えて、`Time`、`ActiveSupport::TimeWithZone`、`ActiveSupport::HashWithIndifferentAccess`などの追加の型もシリアライズできます。`ActiveSupport::MessagePack`は、`JSON`や`Marshal`に比べてペイロードサイズを削減しパフォーマンスを向上させることが可能です。

`ActiveSupport::MessagePack`は、以下のように[メッセージシリアライザ](configuring.html#config-active-support-message-serializer)として利用できます。

```ruby
config.active_support.message_serializer = :message_pack

# または個別に指定する
ActiveSupport::MessageEncryptor.new(secret, serializer: :message_pack)
ActiveSupport::MessageVerifier.new(secret, serializer: :message_pack)
```

以下のように[cookieシリアライザ](configuring.html#config-action-dispatch-cookies-serializer)としても利用できます（[#48103][]）。

```ruby
config.action_dispatch.cookies_serializer = :message_pack
```

以下のように[キャッシュシリアライザ](caching_with_rails.html#設定)としても利用できます（[#48104][]）。

```ruby
config.cache_store = :file_store, "tmp/cache", { serializer: :message_pack }

# または個別に指定する
ActiveSupport::Cache.lookup_store(:file_store, "tmp/cache", serializer: :message_pack)
```

[`ActiveSupport::MessagePack`]: https://api.rubyonrails.org/v7.1/classes/ActiveSupport/MessagePack.html
[`msgpack` gem]: https://github.com/msgpack/msgpack-ruby

[#47770]: https://github.com/rails/rails/pull/47770
[#48103]: https://github.com/rails/rails/pull/48103
[#48104]: https://github.com/rails/rails/pull/48104

### 自動読み込みを拡張する`config.autoload_lib`と`config.autoload_lib_once`設定が導入

`config.autoload_lib(ignore:)`という新しい設定メソッドが導入されました（[#48572][]）。このメソッドは、デフォルトでは自動読み込みパスに含まれていない`lib`ディレクトリをアプリケーションの自動読み込みパスに追加するために利用されます。また、新しいアプリケーションでは`config.autoload_lib(ignore: %w(assets tasks))`が生成されます。

このメソッドが`config/application.rb`または`config/environments/*.rb`から呼び出されると、`lib`ディレクトリを`config.autoload_paths`および`config.eager_load_paths`の両方に追加します。ただし、この機能はエンジンでは利用できません。

オートローダーによって管理されるべきではない`lib`ディレクトリ内のサブディレクトリを`ignore`キーワード引数で指定することで、柔軟性を確保できます。たとえば、`assets`、`tasks`、および`generators`などのディレクトリを`ignore`引数に渡すことで除外できるようになります。

```ruby
config.autoload_lib(ignore: %w(assets tasks generators))
```

`config.autoload_lib_once`メソッド（[#48610][]）は、`config.autoload_lib`と似ていますが、`lib`を`config.autoload_once_paths`に追加する点が異なります。

詳しくはZeitwerkの[自動読み込みガイド](autoloading_and_reloading_constants.html#config-autoload-lib-ignore)を参照してください。

[#48610]: https://github.com/rails/rails/pull/48610
[#48572]: https://github.com/rails/rails/pull/48572

### 汎用の非同期クエリを対象とするActive Record API

Active Record APIに重要な改善が導入され、非同期クエリのサポートが拡張されました（[#44446][]）。この拡張により、特に集計メソッド（`count`、`sum`など）や、（`Relation`でない）単一レコードを返すメソッドなど、あまり速くないクエリをより効率的に処理するニーズに応えます。

新しいAPIには、以下の非同期メソッドが含まれます。

- `async_count`
- `async_sum`
- `async_minimum`
- `async_maximum`
- `async_average`
- `async_pluck`
- `async_pick`
- `async_ids`
- `async_find_by_sql`
- `async_count_by_sql`

これらの中から`async_count`メソッドを用いて、公開済み投稿の数を非同期的にカウントする方法の簡単な例を以下に示します。

```ruby
# 同期的なカウント
published_count = Post.where(published: true).count # => 10

# 非同期なカウント
promise = Post.where(published: true).async_count # => #<ActiveRecord::Promise status=pending>
promise.value # => 10
```

これらの非同期メソッドは、特定のデータベースクエリにおいてパフォーマンスを大幅に向上可能な非同期な方法でこれらの操作を実行できます。

[#44446]: https://github.com/rails/rails/pull/44446

### テンプレートで厳密な`locals`を設定可能になった

テンプレートで`locals`を明示的に設定できる新機能が導入されました（[#45602][]）。
この拡張により、テンプレートに渡される変数を明確に制御できるようになります。

デフォルトのテンプレートは、任意の`locals`をキーワード引数として受け入れます。ただし、テンプレートファイルの先頭に`locals`をERBマジックコメントの形で追加することで、テンプレートが受け取るべき`locals`を定義できます。

`locals`は以下のように指定します。

```erb
<%# locals: (message:) -%>
<%= message %>
```

この`locals`には以下のようにデフォルト値も設定できます。

```erb
<%# locals: (message: "Hello, world!") -%>
<%= message %>
```

オプショナルのキーワード引数で以下のようにsplat `**`を使うことも可能です。

```erb
<%# locals: (message: "Hello, world!", **attributes) -%>
<%= tag.p(message, **attributes) %>
```

`locals`を完全に無効にしたい場合は、以下のように設定できます。

```erb
<%# locals: () %>
```

Action Viewは、`#`で始まるコメントをサポートするテンプレートエンジンであれば、ビューの任意の行にある`locals:`マジックコメントを処理し、パーシャルの任意の行にあるマジックコメントを読み取ります。

CAUTION: サポートされるのはキーワード引数だけです。位置引数やブロック引数を定義すると、レンダリング時にAction Viewエラーが発生します。

[#45602]: https://github.com/rails/rails/pull/45602

### `Rails.application.deprecators`が追加

新しい`Rails.application.deprecators`メソッド（[#46049][]）は、アプリケーション内の管理された非推奨要素のコレクションを返し、個別の非推奨要素を手軽に追加および取得できます。

```ruby
Rails.application.deprecators[:my_gem] = ActiveSupport::Deprecation.new("2.0", "MyGem")
Rails.application.deprecators[:other_gem] = ActiveSupport::Deprecation.new("3.0", "OtherGem")
```

このコレクションの設定は、コレクション内のすべての非推奨機能に影響を与えます。

```ruby
Rails.application.deprecators.debug = true

Rails.application.deprecators[:my_gem].debug
# => true

Rails.application.deprecators[:other_gem].debug
# => true
```

場合によっては、特定のコードブロックですべての非推奨警告をミュートしたいことがあります。
`deprecators`コレクションを使うことで、ブロック内のすべてのdeprecator警告を手軽に無効化できます。

```ruby
Rails.application.deprecators.silence do
  Rails.application.deprecators[:my_gem].warn    # 警告を表示しなくなる
  Rails.application.deprecators[:other_gem].warn # 警告を表示しなくなる
end
```

[#46049]: https://github.com/rails/rails/pull/46049

### JSONの`response.parsed_body`でパターンマッチングをサポート

`ActionDispatch::IntegrationTest`のテストブロックがJSONレスポンスに対して`response.parsed_body`を呼び出すと、そのペイロードは`HashWithIndifferentAccess`で利用可能になります。これにより、[Rubyのパターンマッチング][pattern-matching]と組み合わせられるようになり、[Minitest組み込みのパターンマッチングサポート][minitest-pattern-matching]とも連携可能になります。

```ruby
get "/posts.json"

response.content_type         # => "application/json; charset=utf-8"
response.parsed_body.class    # => Array
response.parsed_body          # => [{},...

assert_pattern { response.parsed_body => [{ id: 42 }] }

get "/posts/42.json"

response.content_type         # => "application/json; charset=utf-8"
response.parsed_body.class    # => ActiveSupport::HashWithIndifferentAccess
response.parsed_body          # => {"id"=>42, "title"=>"Title"}

assert_pattern { response.parsed_body => [{ title: /title/i }] }
```

[pattern-matching]: https://docs.ruby-lang.org/en/master/syntax/pattern_matching_rdoc.html
[minitest-pattern-matching]: https://docs.seattlerb.org/minitest/Minitest/Assertions.html#method-i-assert_pattern

### `response.parsed_body`が拡張されてHTMLをNokogiriで解析可能になった

`ActionDispatch::Testing`モジュールが拡張され（[#47144][]）、HTMLの`response.body`の値を解析して`Nokogiri::HTML5::Document`インスタンスにするサポートを追加します。

```ruby
get "/posts"

response.content_type         # => "text/html; charset=utf-8"
response.parsed_body.class    # => Nokogiri::HTML5::Document
response.parsed_body.to_html  # => "<!DOCTYPE html>\n<html>\n..."
```

新たに追加された[Nokogiriパターンマッチングのサポート][nokogiri-pattern-matching]と、[Minitest組み込みのパターンマッチングのサポート][minitest-pattern-matching]を利用して、HTMLレスポンスの構造や内容に関するテストアサーションを行えるようになります。

```ruby
get "/posts"

html = response.parsed_body # => <html>
                            #      <head></head>
                            #        <body>
                            #          <main><h1>何らかのメインコンテンツ</h1></main>
                            #        </body>
                            #     </html>

assert_pattern { html.at("main") => { content: "何らかのメインコンテンツ" } }
assert_pattern { html.at("main") => { content: /content/ } }
assert_pattern { html.at("main") => { children: [{ name: "h1", content: /content/ }] } }
```

[#47144]: https://github.com/rails/rails/pull/47144
[nokogiri-pattern-matching]: https://nokogiri.org/rdoc/Nokogiri/XML/Attr.html#method-i-deconstruct_keys
[minitest-pattern-matching]: https://docs.seattlerb.org/minitest/Minitest/Assertions.html#method-i-assert_pattern

### `ActionView::TestCase.register_parser`の導入

`ActionView::TestCase`を拡張して、ビューパーシャルでレンダリングするコンテンツを解析して既知の構造に変換する機能をサポートしました（[#49194][]）。
デフォルトでは、以下が定義されています。

* `rendered_html`: HTMLを`Nokogiri::XML::Node`に変換
* `rendered_json`: JSONを`ActiveSupport::HashWithIndifferentAccess`に変換

```ruby
test "renders HTML" do
  article = Article.create!(title: "Hello, world")

  render partial: "articles/article", locals: { article: article }

  assert_pattern { rendered_html.at("main h1") => { content: "Hello, world" } }
end
```

```ruby
test "renders JSON" do
  article = Article.create!(title: "Hello, world")

  render formats: :json, partial: "articles/article", locals: { article: article }

  assert_pattern { rendered_json => { title: "Hello, world" } }
end
```

レンダリングしたコンテンツをRSSに変換するには、`RSS::Parser.parse`呼び出しを登録します。

```ruby
register_parser :rss, -> rendered { RSS::Parser.parse(rendered) }

test "renders RSS" do
  article = Article.create!(title: "Hello, world")

  render formats: :rss, partial: article, locals: { article: article }

  assert_equal "Hello, world", rendered_rss.items.last.title
end
```

レンダリングしたコンテンツを`Capybara::Simple::Node`に変換するには、`:html`パーサーに`Capybara.string`呼び出しを再登録します。

```ruby
register_parser :html, -> rendered { Capybara.string(rendered) }

test "renders HTML" do
  article = Article.create!(title: "Hello, world")

  render partial: article

  rendered_html.assert_css "main h1", text: "Hello, world"
end
```

[#49194]: https://github.com/rails/rails/pull/49194

Railties
--------

変更点について詳しくは[Changelog][railties]を参照してください。

### 削除されたもの

* 非推奨化された`bin/rails secrets:setup`コマンドを削除（[#47801][]）。

* デフォルトの`X-Download-Options`ヘッダー（Internet Explorerでしか使われていない）を削除（[#43968][]）。

### 非推奨化

* `Rails.application.secrets`の利用を非推奨化（[#48472][]）。

* `secrets:show`コマンドと`secrets:edit`コマンドが非推奨化、今後は`credentials`を利用する（[#47801][]）。

* `Rails::Generators::Testing::Behaviour`（英国スペル）を非推奨化、今後は米国スペルの`Rails::Generators::Testing::Behavior`を使う（[#45180][]）。

### 主な変更点

* production環境でのRailsコンソールをデフォルトでsandboxモードで起動できるようにする`sandbox_by_default`オプションが追加（[#48984][]）。

* 実行するテストを行範囲で指定できる新しい構文を追加（[#48807][]）。

* マイグレーションをコピーするために`rails railties:install:migrations`コマンドを実行したときに対象データベースの仕様を有効にする`DATABASE`オプションを追加（[#48579][]）。

* `rails new --javascript`ジェネレータで[Bun](https://bun.sh/)をサポート（[#49241][]）。

    ```bash
    $ rails new my_new_app --javascript=bun
    ```

* 遅いテストをテストランナーで表示する機能を追加（[#49257][]）。

[#47801]: https://github.com/rails/rails/pull/47801
[#43968]: https://github.com/rails/rails/pull/43968
[#48472]: https://github.com/rails/rails/pull/48472
[#45180]: https://github.com/rails/rails/pull/45180
[#48984]: https://github.com/rails/rails/pull/48984
[#48807]: https://github.com/rails/rails/pull/48807
[#48579]: https://github.com/rails/rails/pull/48579
[#49241]: https://github.com/rails/rails/pull/49241
[#49257]: https://github.com/rails/rails/pull/49257

Action Cable
------------

変更点について詳しくは[Changelog][action-cable]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

特になし。

### 主な変更点

* `capture_broadcasts`テストヘルパーを追加（[#48798][]）。ブロードキャストされたすべてのメッセージをブロック内でキャプチャする。

* Redisのコネクションが失われたときにRedisのpub/subアダプタを自動再接続する機能を追加（[#46562][]）。

* `ActionCable::Connection::Base`に`before_command`、`after_command`、`around_command`コールバックを追加（[#44696][]）。

[#48798]: https://github.com/rails/rails/pull/48798
[#46562]: https://github.com/rails/rails/pull/46562
[#44696]: https://github.com/rails/rails/pull/44696

Action Pack
-----------

変更点について詳しくは[Changelog][action-pack]を参照してください。

### 削除されたもの

* `Request#content_type`の非推奨化された振る舞いを削除（[689b277][]）。

* `config.action_dispatch.trusted_proxies`に単一の値を代入可能だった非推奨の機能を削除（[1e70d0f][]）。

* 非推奨化されていた`poltergeist`と`webkit`（capybara-webkit）ドライバのシステムテストへの登録を削除（[696ccbc][]）。

[689b277]: https://github.com/rails/rails/commit/689b27773396c06b49333de9f6e9d0127f16d6ea
[1e70d0f]: https://github.com/rails/rails/commit/1e70d0f5d3695bd9f18f909e953e84ca04d25e17
[696ccbc]: https://github.com/rails/rails/commit/696ccbc26568fb98af4695ad4dd445b593bbc43e

### 非推奨化

* `config.action_dispatch.return_only_request_media_type_on_content_type`を非推奨化（[689b277][]）。

* `AbstractController::Helpers::MissingHelperError`を非推奨化（[#47199][]）。

* `ActionDispatch::IllegalStateError`を非推奨化（[#47200][]）。

* パーミッションポリシーの古くなったディレクティブ`speaker`、`vibrate`、`vr`を非推奨化（[#46199][]）。

* `config.action_dispatch.show_exceptions`に`true`や`false`を設定することを非推奨化（[#45867][]）。今後は`:all`、`:rescuable`、`:none`を使うこと。

[689b277]: https://github.com/rails/rails/commit/689b27773396c06b49333de9f6e9d0127f16d6ea
[#47199]: https://github.com/rails/rails/pull/47199
[#47200]: https://github.com/rails/rails/pull/47200
[#46199]: https://github.com/rails/rails/pull/46199
[#45867]: https://github.com/rails/rails/pull/45867

### 主な変更点

* `ActionController::Parameters`に`exclude?`メソッドを追加。これは`include?`と逆の動作（[#45887][]）。

* `ActionController::Parameters#extract_value`メソッドを追加。これはparamsからシリアライズ済みの値を抽出できる（[#49042][]）。

* カスタムロジックでCSRFトークンの保存と取り出しを行えるようになった（[#44283][]）。

* システムテストのスクリーンショットヘルパーに`html`と`screenshot`キーワード引数を追加（[#44720][]）。

[#45887]: https://github.com/rails/rails/pull/45887
[#49042]: https://github.com/rails/rails/pull/49042
[#44283]: https://github.com/rails/rails/pull/44283
[#44720]: https://github.com/rails/rails/pull/44720

Action View
-----------

変更点について詳しくは[Changelog][action-view]を参照してください。

### 削除されたもの

* 非推奨化されていた定数`ActionView::Path`を削除（[23344d4][]）。

* パーシャルにインスタンス変数をローカル変数として渡す非推奨のサポートを削除（[8241178][]）。

[23344d4]: https://github.com/rails/rails/commit/23344d4b8cc36bb8ae3db209e0365b70469118d2
[8241178]: https://github.com/rails/rails/commit/8241178723d02123734a1efd01c12b9fda2f4fea

### 非推奨化

特になし。

### 主な変更点

* `checkbox_tag`と`radio_button_tag`に`checked:`をキーワード引数として渡せるようになった（[#45527][]）。

* HTML `<picture>`タグを生成する`picture_tag`を追加（[#48100][]）。

* `simple_format`ヘルパーで`:sanitize_options`機能が使えるようになった（[#48355][]）。これを用いてサニタイズ処理に追加オプションを指定できる。

    ```ruby
    simple_format("<a target=\"_blank\" href=\"http://example.com\">Continue</a>", {}, { sanitize_options: { attributes: %w[target href] } })
    # => "<p><a target=\"_blank\" href=\"http://example.com\">Continue</a></p>"
    ```

[#45527]: https://github.com/rails/rails/pull/45527
[#48100]: https://github.com/rails/rails/pull/48100
[#48355]: https://github.com/rails/rails/pull/48355

Action Mailer
-------------

変更点について詳しくは[Changelog][action-mailer]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

* `config.action_mailer.preview_path`（単数形）が非推奨化（[#31595][]）。

* パラメータを`:args`キーワード引数経由で`assert_enqueued_email_with`に渡すことが非推奨化（[#48194][]）。`:params`キーワード引数がサポートされたので、今後はこれを用いてparamsを渡すこと。

[#31595]: https://github.com/rails/rails/pull/31595
[#48194]: https://github.com/rails/rails/pull/48194

### 主な変更点

* 複数のプレビューパスをサポートする`config.action_mailer.preview_paths`（複数形）を追加（[#31595][]）。

* ブロック内で送信された全メールをキャプチャする`capture_emails`テストヘルパーを追加（[#48798][]）。

* エンキューされた全メールジョブを配信する`deliver_enqueued_emails`を`ActionMailer::TestHelper`に追加（[#47520][]）。

[#31595]: https://github.com/rails/rails/pull/31595
[#48798]: https://github.com/rails/rails/pull/48798
[#47520]: https://github.com/rails/rails/pull/47520

Active Record
-------------

変更点について詳しくは[Changelog][active-record]を参照してください。

### 削除されたもの

* 非推奨化されていた`ActiveRecord.legacy_connection_handling`のサポートを削除（[#44827][]）。

* 非推奨化されていた`ActiveRecord::Base`の設定アクセサを削除（[96c9db1][]）。

* `configs_for`での`:include_replicas`のサポートを削除。今後は`:include_hidden`を使うこと（[#47536][]）。

* 非推奨化されていた`config.active_record.partial_writes`を削除（[96b9fd6][]）。

* 非推奨化されていた`Tasks::DatabaseTasks.schema_file_type`を削除（[049dfd4][]）。

* PostgreSQL向けのstructure dumpでの`--no-comments`フラグを削除（[#44633][]）。

[#44827]: https://github.com/rails/rails/pull/44827
[96c9db1]: https://github.com/rails/rails/commit/96c9db1b4829cb5d2f0e7054bec5a9c6b33f8725
[#47536]: https://github.com/rails/rails/pull/47536
[96b9fd6]: https://github.com/rails/rails/commit/96b9fd6f140674c58e2b83740d8478cdb02236ad
[049dfd4]: https://github.com/rails/rails/commit/049dfd4ccf22b9abc4283053ca8d38a6235c237e
[#44633]: https://github.com/rails/rails/pull/44633

### 非推奨化

* `#remove_connection`の`name`引数を非推奨化（[#48681][]）。

* `check_pending!`を非推奨化（[#48964][]）。今後は`check_all_pending!`を使うこと。

* `add_foreign_key`の`deferrable: true`オプションを非推奨化（[#47659][]）。今後は`deferrable: :immediate`を使うこと。

* 単数形の`TestFixtures#fixture_path`を非推奨化（[#47675][]）。今後は複数形の`TestFixtures#fixture_paths`を使うこと。

* `Base`から`connection_handler`への委譲を非推奨化（[#46274][]）。

* `config.active_record.suppress_multiple_database_warning`を非推奨化（[#46134][]）。

* `ActiveSupport::Duration`をSQL文字列テンプレート内でバインドパラメータとして式展開することを非推奨化（[#44438][]）。

* `all_connection_pools`を非推奨化し、`connection_pool_list`でオプションを明示的に指定する形に変わった（[#45961][]）。

* 主キーが`:id`でない場合に`read_attribute(:id)`が主キーを返す振る舞いを非推奨化（[#49019][]）。

* `#merge`の`rewhere`オプションを非推奨化（[#45498][]）。

* 属性でないものを`alias_attribute`でエイリアスにすることを非推奨化（[#48972][]）。

[#48681]: https://github.com/rails/rails/pull/48681
[#48964]: https://github.com/rails/rails/pull/48964
[#47659]: https://github.com/rails/rails/pull/47659
[#47675]: https://github.com/rails/rails/pull/47675
[#46274]: https://github.com/rails/rails/pull/46274
[#46134]: https://github.com/rails/rails/pull/46134
[#44438]: https://github.com/rails/rails/pull/44438
[#45961]: https://github.com/rails/rails/pull/45961
[#49019]: https://github.com/rails/rails/pull/49019
[#45498]: https://github.com/rails/rails/pull/45498
[#48972]: https://github.com/rails/rails/pull/48972

### 主な変更点

* 複数のフィクスチャパスをサポートする`TestFixtures#fixture_paths`を追加（[#47675][]）。

* `has_secure_password`に`authenticate_by`メソッドを追加（[#43765][]）。

* `ActiveRecord::Persistence`に`update_attribute!`を追加。`update_attribute`と同様だが、`before_*`コールバックで`:abort`がスローされた場合は`ActiveRecord::RecordNotSaved`をraiseする点が異なる（[#44141][]）。

* `insert_all`と`upsert_all`でエイリアス属性も指定できるようになった（[#45036][]）。

* マイグレーションの`add_index`に`:include`オプションを追加（PostgreSQLのみ）（[#44803][]）。

* `#regroup`クエリメソッドを追加（[#47010][]）。これは`.unscope(:group).group(fields)`のショートハンド。

* `SQLite3`アダプタに自動生成カラム、カスタム主キーのサポートを追加（[#49290][]）。

* `SQLite3`データベースコネクション用の設定に高パフォーマンスの新しいデフォルトを追加（[#49349][]）。

* `where`にカラムの"タプル"構文を導入（[#47729][]）。

    ```ruby
    Topic.where([:title, :author_name] => [["The Alchemist", "Paulo Coelho"], ["Harry Potter", "J.K Rowling"]])
    ```

* 自動生成されるインデックス名が最大62バイトになった（[#47753][]）。この長さは、MySQL、PostgreSQL、SQLite3のインデックス名のデフォルトの最大長さに収まる

* Trilogyデータベースクライアント用のアダプタを導入（[#47880][]）。

* 全コネクションプールにある全コネクションを即座にクローズする`ActiveRecord.disconnect_all!`を追加（[#47856][]）。

* PostgreSQLのマイグレーションでenumのリネーム、値の追加、値のリネームが可能になった （[#44898][]）。

* レコードの`id`カラムの生の値にアクセスする`ActiveRecord::Base#id_value`を追加（[#48930][]）。

* `enum`に`validate`オプションを追加（[#49100][]）。

[#43765]: https://github.com/rails/rails/pull/43765
[#44141]: https://github.com/rails/rails/pull/44141
[#45036]: https://github.com/rails/rails/pull/45036
[#44803]: https://github.com/rails/rails/pull/44803
[#47010]: https://github.com/rails/rails/pull/47010
[#47729]: https://github.com/rails/rails/pull/47729
[#49290]: https://github.com/rails/rails/pull/49290
[#49349]: https://github.com/rails/rails/pull/49349
[#47753]: https://github.com/rails/rails/pull/47753
[#47880]: https://github.com/rails/rails/pull/47880
[#47856]: https://github.com/rails/rails/pull/47856
[#44898]: https://github.com/rails/rails/pull/44898
[#48930]: https://github.com/rails/rails/pull/48930
[#49100]: https://github.com/rails/rails/pull/49100

* `encrypts`で定義した属性で使われる`ActiveRecord::Encryption`のデフォルトのハッシュダイジェストが、デフォルト設定の`SHA1`から`SHA256`に変更された。これらのデフォルトには`support_sha1_for_non_deterministic_encryption = false` も含まれており、データが再暗号化されていない場合、アプリは古いデフォルトのハッシュダイジェストで暗号化されたデータを復号化できなくなる可能性がある。

Active Storage
--------------

変更点について詳しくは[Changelog][active-storage]を参照してください。

### 削除されたもの

* Active Storageの設定で非推奨化されていた無効なデフォルトContent-Typeを削除（[4edaa41][]）。

* 非推奨化されていた`ActiveStorage::Current#host`メソッドと`ActiveStorage::Current#host=`メソッドを削除（[0591de5][]）。

* 添付ファイルのコレクションへの代入時の非推奨化されていた振る舞いを削除（[c720b7e][]）。コレクションへの追加ではなく、コレクションが置き換えられるようになった。

* 非推奨化されていた、添付ファイルの関連付けからの`purge`メソッドと`purge_later`メソッドを削除（[18e53fb][]）。

[4edaa41]: https://github.com/rails/rails/commit/4edaa4120bd76fafa770dc654f85f83f1c2c6d78
[0591de5]: https://github.com/rails/rails/commit/0591de55af5cb1fa249237772309e94b07a640c2
[c720b7e]: https://github.com/rails/rails/commit/c720b7eba8bab1d227553ad4f962bf35abd41c88
[18e53fb]: https://github.com/rails/rails/commit/18e53fbb2c1b76e4e0b906e602edb4ad7291b621

### 非推奨化

特になし。

### 主な変更点

* `ActiveStorage::Analyzer::AudioAnalyzer`が、出力の`metadata`ハッシュで`sample_rate`と`tags`を出力するようになった（[#48823][]、[#47749][]）。

* 添付ファイルで`preview`メソッドや`representation`メソッドを呼び出したときに定義済みのvariantを利用可能にするオプションを追加（[#45098][]）。

* variantをプリプロセス用に宣言できる`preprocessed`オプションを追加（[#47473][]）。

* Active Storageのvariantを削除する機能を追加（[#47150][]）。

    ```ruby
    User.first.avatar.variant(resize_to_limit: [100, 100]).destroy
    ```

[#48823]: https://github.com/rails/rails/pull/48823
[#47749]: https://github.com/rails/rails/pull/47749
[#45098]: https://github.com/rails/rails/pull/45098
[#47473]: https://github.com/rails/rails/pull/47473
[#47150]: https://github.com/rails/rails/pull/47150

Active Model
------------

変更点について詳しくは[Changelog][active-model]を参照してください。

### 削除されたもの

特になし。

### 非推奨化

特になし。

### 主な変更点

* `LengthValidator`の`:in`オプションや`:within`オプションでbeginless/endless rangeをサポート（[#45138][]）。

    ```ruby
    validates_length_of :first_name, in: ..30
    ```

* `validates_inclusion_of`や`validates_exclusion_of`でbeginless rangeをサポート（[#45123][]）。

    ```ruby
    validates_inclusion_of :birth_date, in: -> { (..Date.today) }
    ```

    ```ruby
    validates_exclusion_of :birth_date, in: -> { (..Date.today) }
    ```

* `has_secure_password`に`password_challenge`アクセサを追加。`password_challenge`が設定されている場合、現在永続化済みの`password_digest`とマッチするかどうかをバリデーションする（[#43688][]）。

* バリデータに`record`引数なしのlambdaを渡せるようになった（[#45118][]）。

    ```ruby
    # 更新前
    validates_comparison_of :birth_date, less_than_or_equal_to: ->(_record) { Date.today }

    # 更新後
    validates_comparison_of :birth_date, less_than_or_equal_to: -> { Date.today }
    ```

[#45138]: https://github.com/rails/rails/pull/45138
[#45123]: https://github.com/rails/rails/pull/45123
[#43688]: https://github.com/rails/rails/pull/43688
[#45118]: https://github.com/rails/rails/pull/45118

Active Support
--------------

変更点について詳しくは[Changelog][active-support]を参照してください。

### 削除されたもの

* `Enumerable#sum`の非推奨化されたオーバーライドを削除（[3ec6297][]）。

* 非推奨化されていた`ActiveSupport::PerThreadRegistry`を削除（[4eb6441][]）。

* `Array`、`Range`、`Date`、`DateTime`、`Time`、`BigDecimal`、`Float`、`Integer`でフォーマットが`#to_s`に渡される非推奨のオプションを削除（[e420c33][]）。

* 非推奨化されていた`ActiveSupport::TimeWithZone.name`のオーバーライドを削除（[34e296d][]）。

* 非推奨化されていた`active_support/core_ext/uri`ファイルを削除（[da8e6f6][]）。

* 非推奨化されていた`active_support/core_ext/range/include_time_with_zone`ファイルを削除（[f0ddb77][]）。

* `ActiveSupport::SafeBuffer`でオブジェクトが暗黙で`String`に変換されていたのを削除（[f02998d][]）。

* `Digest::UUID`で定義されている定数に含まれていない名前空間IDを提供すると、誤ったRFC 4122 UUIDを生成する非推奨のサポートを削除（[7b4affc][]）。

[3ec6297]: https://github.com/rails/rails/commit/3ec629784cac7a8b518feb402475153465cd8e96
[4eb6441]: https://github.com/rails/rails/commit/4eb6441dd8f0409ae432f1596cf35d7c5468292c
[e420c33]: https://github.com/rails/rails/commit/e420c3380eb2b698a4fe84ed196f914d18f7844a
[34e296d]: https://github.com/rails/rails/commit/34e296d4927938a69caf118c98ab9f8a7afa10a5
[da8e6f6]: https://github.com/rails/rails/commit/da8e6f61752b34baaf7a0f26cdc9902a734a7fd9
[f0ddb77]: https://github.com/rails/rails/commit/f0ddb7709bcd076256d8e4ce494963a7bef3ec29
[f02998d]: https://github.com/rails/rails/commit/f02998d2b5982434faf2d258fe2977074ee4424f
[7b4affc]: https://github.com/rails/rails/commit/7b4affc78bf2fdd349a86c60b940b7c172e111df

### 非推奨化

* `config.active_support.disable_to_s_conversion`を非推奨化（[e420c33][]）。

* `config.active_support.remove_deprecated_time_with_zone_name`を非推奨化（[34e296d][]）。

* `config.active_support.use_rfc4122_namespaced_uuids`を非推奨化（[7b4affc][]）。

* `SafeBuffer#clone_empty`を非推奨化（[#48264][]）。

* `ActiveSupport::Deprecation`をシングルトンとして利用することを非推奨化（[#47354][]）。

* `ActiveSupport::Cache::MemCacheStore`を`Dalli::Client`のインスタンスで初期化することを非推奨化（[#47340][]）。

* `Notification::Event`の`#children`メソッドと`#parent_of?`メソッドを非推奨化（[#43390][]）

[#48264]: https://github.com/rails/rails/pull/48264
[#47354]: https://github.com/rails/rails/pull/47354
[#47340]: https://github.com/rails/rails/pull/47340
[#43390]: https://github.com/rails/rails/pull/43390

### 主な変更点

特になし。

Active Job
----------

変更点について詳しくは[Changelog][active-job]を参照してください。

### 削除されたもの

* `QueAdapter`を削除（[#46005][]）。

[#46005]: https://github.com/rails/rails/pull/46005

### 非推奨化

特になし。

### 主な変更点

* 複数のジョブを一括でエンキューする`perform_all_later`が追加（[#46603][]）。

* ジョブジェネレータでジョブの親クラスを指定する`--parent`オプションが追加（[#45528][]）。

* ジョブが破棄されるときにコールバックを実行する`after_discard`メソッドを`ActiveJob::Base`に追加（[#48010][]）。

* バックグラウンドのジョブエンキュー呼び出し元をログ出力するサポートを追加（[#47839][]）。

[#46603]: https://github.com/rails/rails/pull/46603
[#45528]: https://github.com/rails/rails/pull/45528
[#48010]: https://github.com/rails/rails/pull/48010
[#47839]: https://github.com/rails/rails/pull/47839

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

特になし。

### 非推奨化

特になし。

### 主な変更点

* `Mail::Message#recipients`に`X-Forwarded-To`アドレスを追加（[#46552][]）。

* バウンスメールをメーラーのキューを通さずに送信する`bounce_now_with`メソッドを`ActionMailbox::Base`に追加（[#48446][]）。

[#46552]: https://github.com/rails/rails/pull/46552
[#48446]: https://github.com/rails/rails/pull/48446

Ruby on Railsガイド
--------------------

変更点について詳しくは[Changelog][guides]を参照してください。

### 主な変更点

訳注：以下のガイドが新たに追加されました。

* [Active Record の複合主キー](active_record_composite_primary_keys.html)
* [Rails アプリケーションのエラー通知](error_reporting.html)


Credits
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](https://contributors.rubyonrails.org/)を参照してください。これらの方々全員に深く敬意を表明いたします。

[railties]:       https://github.com/rails/rails/blob/7-1-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/7-1-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/7-1-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/7-1-stable/actionmailer/CHANGELOG.md
[action-cable]:   https://github.com/rails/rails/blob/7-1-stable/actioncable/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/7-1-stable/activerecord/CHANGELOG.md
[active-storage]: https://github.com/rails/rails/blob/7-1-stable/activestorage/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/7-1-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/7-1-stable/activesupport/CHANGELOG.md
[active-job]:     https://github.com/rails/rails/blob/7-1-stable/activejob/CHANGELOG.md
[action-text]:    https://github.com/rails/rails/blob/7-1-stable/actiontext/CHANGELOG.md
[action-mailbox]: https://github.com/rails/rails/blob/7-1-stable/actionmailbox/CHANGELOG.md
[guides]:         https://github.com/rails/rails/blob/7-1-stable/guides/CHANGELOG.md
