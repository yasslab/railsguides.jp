Rails プラグイン作成入門
====================================

本ガイドは、Rails アプリケーションの動作を拡張または変更するために、Railsプラグインを作成したい開発者を対象としています。

このガイドの内容:

* Railsプラグインの概要と、使うべきタイミング
* プラグインをゼロから作成する
* Rubyのコアクラスを拡張する
* `ApplicationRecord`にメソッドを追加する
* プラグインをRubyGemsに公開する

--------------------------------------------------------------------------------

プラグインとは
-----------------

Railsプラグインは、Railsアプリケーションに機能を追加するためのパッケージ化された拡張です。プラグインは、いくつかの目的を果たします。

* プラグインは、コアコードベースの安定性を損なわずに新しいアイデアを試す方法を開発者に提供します。
* プラグインは、モジュールアーキテクチャをサポートし、機能を独立してメンテナンス・更新・リリースできるようにします。
* プラグインは、すべてを直接フレームワークに含める必要なしに、強力な機能を導入する手段をチームに提供します。

技術的なレベルでは、プラグインはRailsアプリケーション内で動作するように設計されたRuby gemのことです。多くの場合、プラグインは[Railtie][]でRailsの起動プロセスにフックし、フレームワークの動作を構造化された方法で拡張または変更できるようにします。RailtieはRailsを拡張する最も基本的な統合ポイントであり、通常、「設定」「rakeタスク」「初期化コード」を追加する必要がある場合に使います。ただし、プラグインはコントローラー、ビュー、モデルを公開しません。

NOTE: [Railsエンジン](engines.html)（または単にエンジン）は、一種の高度なプラグインであり、ミニRailsアプリケーションのように振る舞います。エンジンには、独自のルーティング、コントローラー、ビューに加えて、アセットも含められます。すべてのエンジンはプラグインですが、すべてのプラグインがエンジンとは限りません。プラグインとエンジンの主な違いはスコープにあります。プラグインは通常、小さなカスタマイズやアプリ間で共有される振る舞いを扱うのに対し、エンジンは独自のルーティング、モデル、ビューを持ち、完全に近い機能を提供します。

[Railtie]: https://api.rubyonrails.org/classes/Rails/Railtie.html

ジェネレータのオプション
------------------

Railsのプラグインはgemとして構築されます。必要であれば[RubyGems][]と[Bundler][]を用いて、異なるRailsアプリケーション間で共有できます。

`rails plugin new`コマンドは、生成されるプラグイン構造の種別を決定するいくつかのオプションをサポートしています。

**基本プラグイン**（デフォルト）: オプションを指定しない場合、コアクラスのメソッドやユーティリティ関数などのシンプルな拡張に適した最小限のプラグイン構造を生成します。

```bash
$ rails plugin new api_boost
```

本ガイドでは、基本的なプラグインジェネレータで解説します。ジェネレータには`--full`と`--mountable`の2つのオプションがあり、これら2つについては[Railsエンジンガイド](engines.html)で説明されています。

**フルプラグイン**（`--full`）: このオプションは、`app`ディレクトリツリー（モデル、ビュー、コントローラー）、`config/routes.rb`ファイル、および`lib/api_boost/engine.rb`にエンジンクラスを含む、より完全なプラグイン構造を作成します。

```bash
$ rails plugin new api_boost --full
```

`--full`オプションは、独自のモデル、コントローラー、ビューが必要だが、名前空間の分離は必要としないプラグインを作成するときに使います。

**マウンタブルエンジン**（`--mountable`）: このオプションは、`--full`のすべての要素に加えて、以下の要素も含む完全に分離されたマウンタブルエンジンを作成します。

- 名前空間の分離（すべてのクラスに`ApiBoost::`がプレフィックスされる）
- アセットマニフェストファイル
- 名前空間付きの`ApplicationController`と`ApplicationHelper`
- テスト用のダミーアプリでの自動マウント機能

```bash
$ rails plugin new api_boost --mountable
```

`--mountable`オプションは、管理パネル、ブログ、APIモジュールなど、独立したアプリケーションとして機能できる自己完結型の機能を構築するときに使います。

Railsエンジンについて詳しくは、[Railsエンジンのガイド](engines.html)を参照してください。

以下は、適切なオプションを選択するための目安です。

- **基本プラグイン**: シンプルなユーティリティ、コアクラスの拡張、または小さなヘルパーメソッド
- **`--full`プラグイン**: モデル/コントローラーが必要だが、ホストアプリの名前空間を共有する複雑な機能
- **`--mountable`エンジン**: 管理パネル、ブログ、APIモジュールなどの自己完結型機能

利用法やオプションについては、ヘルプを参照してください。

```bash
$ rails plugin new --help
```

[RubyGems]: https://guides.rubygems.org/make-your-own-gem/
[Bundler]: https://bundler.io/guides/creating_gem.html

セットアップ
------

本ガイドでは、「API構築中に、リクエストのスロットリング、レスポンスのキャッシュ、自動APIドキュメント生成など、一般的なAPI機能を追加するプラグインを作成したい」という想定で解説します。そのために`ApiBoost`というプラグインを作成し、任意のRails APIアプリケーションを強化できるようにします。

### プラグインを生成する

以下のコマンドを実行して、基本的なプラグインを作成します。

```bash
$ rails plugin new api_boost
```

これにより、`api_boost/`という名前のディレクトリにApiBoostプラグインが作成されます。生成された内容を見てみましょう。

```
api_boost/
├── api_boost.gemspec
├── Gemfile
├── lib/
│   ├── api_boost/
│   │   └── version.rb
│   ├── api_boost.rb
│   └── tasks/
│       └── api_boost_tasks.rake
├── test/
│   ├── dummy/
│   │   ├── app/
│   │   ├── bin/
│   │   ├── config/
│   │   ├── db/
│   │   ├── public/
│   │   └── ... (full Rails application)
│   ├── integration/
│   └── test_helper.rb
├── MIT-LICENSE
└── README.md
```

**`lib/`ディレクトリ**には、プラグインのソースコードが含まれています。

- `lib/api_boost.rb`: プラグインのメインエントリポイント
- `lib/api_boost/`: プラグイン機能のためのモジュールやクラスはここに配置する
- `lib/tasks/`: プラグインが提供するRakeタスクはここに配置する

**`test/dummy`ディレクトリ**には、プラグインのテストに使用される完全なRailsアプリケーションが含まれています。このダミーアプリケーションは以下を行います。

- プラグインをGemfileで自動的に読み込む
- プラグインとの統合をテストするためのRails環境を提供する
- テストに必要なジェネレーター、モデル、コントローラー、ビューが含まれている
- `rails console`や`rails server`を使って対話的に利用できる

**Gemspecファイル**（`api_boost.gemspec`）は、プラグインgemのメタデータ、依存関係、およびパッケージング時にインクルードするファイルを定義します。

### プラグインをセットアップする

プラグインを含むディレクトリに移動し、`api_boost.gemspec`をエディタで編集して、値が`TODO`の行を置き換えます。

```ruby
spec.homepage    = "http://example.com"
spec.summary     = "Enhance your API endpoints"
spec.description = "Adds common API functionality like request throttling, response caching, and automatic API documentation."

...

spec.metadata["source_code_uri"] = "http://example.com"
spec.metadata["changelog_uri"] = "http://example.com"
```

続いて、`bundle install`コマンドを実行します。

終わったら、テスト用データベースをセットアップします。`test/dummy`ディレクトリに移動して、以下のコマンドを実行します。

```bash
$ cd test/dummy
$ bin/rails db:create
```

ダミーアプリケーションは、通常のRailsアプリケーションと同じように動作します。これによって、モデルの生成、マイグレーションの実行、サーバーの起動、コンソールのオープンなどのプラグインの機能を、プラグインの開発中にテストできます。

データベースが作成されたら、プラグインのrootディレクトリに戻ります（`cd ../..`）。

これで、`bin/test`でテストを実行できます。以下のような出力が表示されるはずです。

```bash
$ bin/test
...
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

これで、生成がすべて正しく行われ、機能追加の準備が整ったことを確認できました。

コアクラスを拡張する
----------------------

本セクションでは、Railsアプリケーションのどこからでも利用できるように、[Integer](https://docs.ruby-lang.org/ja/latest/class/Integer.html)クラスにメソッドを追加する方法を説明します。

WARNING: コアクラスを拡張する場合は、その前に「`String`や`Array`や`Hash`などのコアクラスの拡張は、たとえ使うとしても控えめにすべきである」ことを十分理解しておかなければなりません。コアクラスの拡張は壊れやすく、危険であり、多くの場合不要です。<br></br>コアクラスを拡張すると、以下のような問題を引き起こす可能性があります。</br>
- 複数のgemが同じクラスを同じメソッド名で拡張した場合にメソッド名が競合する</br>
- RubyやRailsがアップデートされてコアクラスの振る舞いが変更された場合に予期せず壊れる</br>
- 拡張メソッドの場所が不明なため、デバッグが困難になる</br>
- プラグインと他のコードの間に結合の問題を引き起こす</br>
コアクラスを拡張する前に、まず以下の代替案を検討してください。</br>
- ユーティリティモジュールやヘルパークラスを作成する</br>
- モンキーパッチではなく、コンポジションを使う</br>
- 独自のクラスのインスタンスメソッドとして機能を実装する</br>
コアクラスを拡張すると問題を引き起こす理由について詳しくは、『[The Case Against Monkey Patching](https://shopify.engineering/the-case-against-monkey-patching)』を参照してください。</br>ただし、コアクラスを拡張するしくみを理解しておくことには価値があります。以下の例ではコアクラスを拡張する具体的な方法を示していますが、実際の利用は慎重に検討すべきです。

このサンプルでは、Rubyのコアクラスである`Integer`クラスに`requests_per_hour`というメソッドを追加します。


`lib/api_boost.rb`ファイルをエディタで開いて、`require "api_boost/core_ext"`を追加します。

```ruby
# api_boost/lib/api_boost.rb

require "api_boost/version"
require "api_boost/railtie"
require "api_boost/core_ext"

module ApiBoost
  # ここに独自のコードを書く
end
```

`core_ext.rb`ファイルを作成し、`10.requests_per_hour`というRateLimitを定義するメソッドを`Integer`クラスに追加します。このメソッドは、`Time`を返す`10.hours`メソッドに形が似ています

```ruby
# api_boost/lib/api_boost/core_ext.rb

ApiBoost::RateLimit = Data.define(:requests, :per)

class Integer
  def requests_per_hour
    ApiBoost::RateLimit.new(self, :hour)
  end
end
```

これを実際に動かしてみましょう。`test/dummy`ディレクトリに移動し、`bin/rails console`を起動して、APIレスポンスのフォーマットをテストします。

```bash
$ cd test/dummy
$ bin/rails console
```

```irb
irb> 10.requests_per_hour
=> #<data ApiBoost::RateLimit requests=10, per=:hour>
```

ダミーアプリケーションはプラグインを自動的に読み込むため、追加した拡張をその場でテストできます。

"act_as"メソッドをActive Recordに追加する
----------------------------------------

Railsのモデルに`acts_as_something`メソッドを追加するのは、プラグインでよく使われるパターンです。ここでは、Active RecordモデルにAPI固有の機能を追加する`acts_as_api_resource`というメソッドを追加したいとします。

APIを構築中に、リソースに最後にアクセスし時間をトラッキングしたいとします。たとえば、`Product`のようなリソースがAPIで最後にアクセスされた時間を追跡したいとします。このタイムスタンプを使って次のようなことができます。

* リクエストのスロットリング（減速）
* 管理パネルに「最後にアクティブだった時刻」を表示する
* 古くなったレコードを優先的に同期する

プラグインを共有することで、このロジックをすべてのモデルに書かなくても済むようになります。`act_as_api_resource`メソッドは、この機能を任意のモデルに追加して、タイムスタンプフィールドを更新してAPIアクティビティをトラッキング可能にします。

まず、必要なファイルを以下のようにセットアップします。

```ruby
# api_boost/lib/api_boost.rb

require "api_boost/version"
require "api_boost/railtie"
require "api_boost/core_ext"
require "api_boost/acts_as_api_resource"

module ApiBoost
  # Your code goes here...
end
```

```ruby
# api_boost/lib/api_boost/acts_as_api_resource.rb

module ApiBoost
  module ActsAsApiResource
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_api_resource(api_timestamp_field: :last_requested_at)
        # APIタイムスタンプ用のフィールド名を指定するオプションを保存するクラスレベルの設定を作成する
        cattr_accessor :api_timestamp_field, default: api_timestamp_field.to_s
      end
    end
  end
end
```

上のコードでは、`ActiveSupport::Concern`を使って、クラスメソッドとインスタンスメソッドの両方を持つモジュールを手軽に`include`できるようにしています。`class_methods`ブロック内のメソッドは、モジュールが`include`されたタイミングでクラスメソッドになります。詳しくは、APIドキュメントの[`ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)を参照してください。

### クラスメソッドを追加する

デフォルトでは、このプラグインはモデルに`last_requested_at`という名前のカラムがあることを前提としていますが、そのカラム名がすでに他の目的で使われている可能性があるため、プラグインでカスタマイズ可能にしています。
`api_timestamp_field:`オプションで別のカラム名を渡すことで、デフォルトのカラム名を上書きできます。この値はクラスレベルの設定`api_timestamp_field`に保存され、プラグインがタイムスタンプを更新するときに使われます。

たとえば、カラム名を`last_requested_at`ではなく`last_api_call`にしたい場合、以下のようにします。

まず、この機能をテストするために、"dummy" Railsアプリケーションでいくつかのモデルを生成しておきます。以下のコマンドを`test/dummy/`ディレクトリで実行します。

```bash
$ cd test/dummy
$ bin/rails generate model Product last_requested_at:datetime last_api_call:datetime
$ bin/rails db:migrate
```

```bash
$ cd test/dummy
$ bin/rails generate model Product last_requested_at:datetime last_api_call:datetime
$ bin/rails db:migrate
```

次に、Productモデルを以下のように更新して、APIリソースとして機能するようにします。

```ruby
# test/dummy/app/models/product.rb

class Product < ApplicationRecord
  acts_as_api_resource api_timestamp_field: :last_api_call
end
```

このプラグインをすべてのモデルで利用可能にするには、`ApplicationRecord`にモジュールを`include`します（この作業を自動化する方法については後述します）。

```ruby
# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include ApiBoost::ActsAsApiResource

  self.abstract_class = true
end
```

これで、この機能をRailsコンソールでテストできます。

```irb
irb> Product.api_timestamp_field
=> "last_api_call"
```

### インスタンスメソッドを追加する

このプラグインは、`track_api_request`というインスタンスメソッドを、`acts_as_api_resource`を呼び出す任意のActive Recordモデルに追加します。このインスタンスメソッドは、設定されたタイムスタンプフィールドの値を現在の時刻（または提供されたカスタム時刻）に設定し、APIリクエストが行われた日時をトラッキングできるようにします。

この振る舞いを追加するには、`acts_as_api_resource.rb`ファイルを以下のように更新します。

```ruby
# api_boost/lib/api_boost/acts_as_api_resource.rb

module ApiBoost
  module ActsAsApiResource
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_api_resource(options = {})
        cattr_accessor :api_timestamp_field,
                       default: (options[:api_timestamp_field] || :last_requested_at).to_s
      end
    end

    def track_api_request(timestamp = Time.current)
      write_attribute(self.class.api_timestamp_field, timestamp)
    end
  end
end
```

NOTE: 上のサンプルコードでは`write_attribute`メソッドでモデルのフィールドに書き込んでいますが、これはプラグインがモデルとやり取りする方法の一例を示したに過ぎず、常に適切な方法とは限りません。たとえば、`send`でセッターメソッドを呼び出す方法を好む場合もあります。

```ruby
send("#{self.class.api_timestamp_field}=", timestamp)
```

これで、この機能をRailsコンソールでテストできます。

```irb
irb> product = Product.new
irb> product.track_api_request
irb> product.last_api_call
=> 2025-06-01 10:31:15 UTC
```

高度な統合: Railtiesを利用する
------------------------------------

これまで構築したプラグインは、基本的な機能には十分ですが、Railsのフレームワークとより深いレベルで統合する必要が生じた場合は、[Railtie](https://api.rubyonrails.org/classes/Rails/Railtie.html)を利用することも可能です。

プラグインでRailtiesが必要になるのは、以下のような場合です。

* `Rails.application.config`経由で設定オプションにアクセスする
* Railsクラスにモジュールを自動的に`include`する
* Rakeタスクをホストアプリケーションに提供する
* Railsの起動中にイニシャライザをセットアップする
* アプリケーションのスタックにミドルウェアを追加する
* 独自のRailsジェネレーターを設定する
* `ActiveSupport::Notifications`にサブスクライブする

これまで見てきたようなシンプルなプラグインでは、Railtieは必要ありません。

### 設定オプションにアクセスする

たとえば、`to_throttled_response`メソッド内のデフォルトのレート制限を設定可能にしたいとします。

まず、Railtieを作成します。

```ruby
# api_boost/lib/api_boost/railtie.rb

module ApiBoost
  class Railtie < Rails::Railtie
    config.api_boost = ActiveSupport::OrderedOptions.new
    config.api_boost.default_rate_limit = 60.requests_per_hour

    initializer "api_boost.configure" do |app|
      ApiBoost.configuration = app.config.api_boost
    end
  end
end
```

プラグインに設定モジュールを追加します。

```ruby
# api_boost/lib/api_boost/configuration.rb

module ApiBoost
  mattr_accessor :configuration, default: nil

  def self.configure
    yield(configuration) if block_given?
  end
end
```

コア拡張を更新して、設定を利用できるようにします。

```ruby
# api_boost/lib/api_boost/core_ext.rb

module ApiBoost
  module ActsAsApiResource
    def to_throttled_json(rate_limit = ApiBoost.configuration.default_rate_limit)
      limit_window = 1.send(rate_limit.per).ago..
      num_of_requests = self.class.where(self.class.api_timestamp_field => limit_window).count
      if num_of_requests > rate_limit.requests
        { error: "Rate limit reached" }.to_json
      else
        to_json
      end
    end
  end
end
```

プラグインのメインのファイルで、新しいファイルを`require`します。

```ruby
# api_boost/lib/api_boost.rb

require "api_boost/version"
require "api_boost/configuration"
require "api_boost/railtie"
require "api_boost/core_ext"
require "api_boost/acts_as_api_resource"

module ApiBoost
  # ここに独自のコードを書く
end
```

これで、このプラグインを利用するアプリケーションで以下のように設定できるようになります。

```ruby
# config/application.rb
config.api_boost.default_rate_limit = "100 requests per hour"
```

### モジュールを自動的に`include`する

`ApplicationRecord`でユーザーが手動で`ActsAsApiResource`を`include`しなくてもよいように、以下のようにRailtieで自動的に行うことができます。

```ruby
# api_boost/lib/api_boost/railtie.rb

module ApiBoost
  class Railtie < Rails::Railtie
    config.api_boost = ActiveSupport::OrderedOptions.new
    config.api_boost.default_rate_limit = 60.requests_per_hour

    initializer "api_boost.configure" do |app|
      ApiBoost.configuration = app.config.api_boost
    end

    initializer "api_boost.active_record" do
      ActiveSupport.on_load(:active_record) do
        include ApiBoost::ActsAsApiResource
      end
    end
  end
end
```

`ActiveSupport.on_load`フックは、Railsの初期化中に適切なタイミングで（ActiveRecordが完全に読み込まれた後）モジュールが`include`されることを保証します。

### Rakeタスクを提供する

プラグインを使っているアプリケーションにRakeタスクを提供したい場合は、以下のようにします。

```ruby
# api_boost/lib/api_boost/railtie.rb

module ApiBoost
  class Railtie < Rails::Railtie
    # ...既存の設定...

    rake_tasks do
      load "tasks/api_boost_tasks.rake"
    end
  end
end
```

Rakeタスクファイルを作成します。

```ruby
# api_boost/lib/tasks/api_boost_tasks.rake

namespace :api_boost do
  desc "Show API usage statistics"
  task stats: :environment do
    puts "API Boost Statistics:"
    puts "Models using acts_as_api_resource: #{api_resource_models.count}"
  end

  def api_resource_models
    ApplicationRecord.descendants.select do |model|
      model.include?(ApiBoost::ActsAsApiResource)
    end
  end
end
```

これで、このプラグインを利用しているRailsアプリケーションで`rails api_boost:stats`コマンドを実行可能になります。


### Railtiesをテストする

ダミーアプリケーションを使うことで、Railtieが正しく動作することをテストできます。

```ruby
# api_boost/test/railtie_test.rb

require "test_helper"

class RailtieTest < ActiveSupport::TestCase
  def test_configuration_is_available
    assert_not_nil ApiBoost.configuration
    assert_equal 60.requests_per_hour, ApiBoost.configuration.default_rate_limit
  end

  def test_acts_as_api_resource_is_automatically_included
    assert Class.new(ApplicationRecord).include?(ApiBoost::ActsAsApiResource)
  end

  def test_rake_tasks_are_loaded
    Rails.application.load_tasks
    assert Rake::Task.task_defined?("api_boost:stats")
  end
end
```

Railtiesは、プラグインをRailsの初期化プロセスとクリーンに統合する方法を提供します。Railsの完全な初期化ライフサイクルについて詳しくは、[Rails初期化プロセスのガイド](initialization.html)を参照してください。

プラグインをテストする
-------------------

テストを追加するのはよい習慣です。Railsプラグインジェネレータは、テストフレームワークも作成してくれます。ここでは、先ほど構築した機能のテストを追加してみましょう。

### コア拡張をテストする

コア拡張をテストするためのファイルを作成します。

```ruby
# api_boost/test/core_ext_test.rb

require "test_helper"

class CoreExtTest < ActiveSupport::TestCase
  def test_to_throttled_response_adds_rate_limit_header
    response_data = "Hello API"
    expected = { data: "Hello API", rate_limit: 60.requests_per_hour }
    assert_equal expected, response_data.to_throttled_response
  end

  def test_to_throttled_response_with_custom_limit
    response_data = "User data"
    expected = { data: "User data", rate_limit: "100 requests per hour" }
    assert_equal expected, response_data.to_throttled_response("100 requests per hour")
  end
end
```

### "acts_as"メソッドをテストする

自作の"acts_as"メソッドをテストするためのファイルを作成します。

```ruby
# api_boost/test/acts_as_api_resource_test.rb

require "test_helper"

class ActsAsApiResourceTest < ActiveSupport::TestCase
  def test_a_users_api_timestamp_field_should_be_last_requested_at
    assert_equal "last_requested_at", User.api_timestamp_field
  end

  def test_a_products_api_timestamp_field_should_be_last_api_call
    assert_equal "last_api_call", Product.api_timestamp_field
  end

  def test_users_track_api_request_should_populate_last_requested_at
    user = User.new
    freeze_time = Time.current
    Time.stub(:current, freeze_time) do
      user.track_api_request
      assert_equal freeze_time.to_s, user.last_requested_at.to_s
    end
  end

  def test_products_track_api_request_should_populate_last_api_call
    product = Product.new
    freeze_time = Time.current
    Time.stub(:current, freeze_time) do
      product.track_api_request
      assert_equal freeze_time.to_s, product.last_api_call.to_s
    end
  end
end
```

テストを実行して、すべてが正常に動作していることを確認します。

```bash
$ bin/test
...
6 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

ジェネレータ
----------

ジェネレータは、プラグインgemの`lib/generators/`ディレクトリに配置するだけで手軽に追加できます。ジェネレータの作成について詳しくは、[ジェネレータのガイド](generators.html)を参照してください。

Gemを公開する
-------------------

今開発しているgemプラグインをGitリポジトリに配置することで、簡単に共有できます。ApiBoost gemを他の人と共有するには、コードをGitリポジトリ（GitHubなど）にコミットし、対象のアプリケーションの`Gemfile`に以下の行を追加します。

```ruby
gem "api_boost", git: "https://github.com/YOUR_GITHUB_HANDLE/api_boost.git"
```

`bundle install`を実行すると、アプリケーションでgemの機能を利用できます。

Gemを正式なリリースとして共有できる準備が整ったら、[RubyGems](https://rubygems.org)に公開できます。

BundlerのRakeタスクを利用することも可能です。利用可能なタスクの一覧は以下のコマンドで確認できます。

```bash
$ bundle exec rake -T

$ bundle exec rake build
# Build api_boost-0.1.0.gem into the pkg directory

$ bundle exec rake install
# Build and install api_boost-0.1.0.gem into system gems

$ bundle exec rake release
# Create tag v0.1.0 and build and push api_boost-0.1.0.gem to Rubygems
```

自作のgemをRubyGemsで公開する方法について詳しくは、RubyGemsの『[Publishing your gem](https://guides.rubygems.org/publishing)』を参照してください。

RDocドキュメントを追加する
------------------

プラグインが安定したら、ドキュメントを作成できます。最初のステップは、`README.md`ファイルを更新して、プラグインの使用方法に関する詳細情報を追加することです。以下の情報をドキュメントに含める必要があります。

* 自分の名前
* インストール方法
* アプリに機能を追加する方法（一般的なユースケースのいくつかの例）
* ユーザーにとって有用な、時間を節約できる警告、注意点、ヒント

`README.md`ファイルの内容が固まったら、開発者が利用するすべてのメソッドにRDocコメントを追加します。また、パブリックAPIに含めないコード部分には`# :nodoc:`コメントを追加するのが慣習です。

APIドキュメントが準備できたら、プラグインディレクトリに移動して、次のコマンドを実行します。

```bash
$ bundle exec rake rdoc
```