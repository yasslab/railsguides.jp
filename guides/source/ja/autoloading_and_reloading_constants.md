定数の自動読み込みと再読み込み (Zeitwerk)
===================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Autoloading and Reloading Constants](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html)を日本語に翻訳した文書です。

本書では`Zeitwerk`モードでの自動読み込み（オートロード）および再読み込みの仕組みについて説明します。

このガイドの内容:

* 自動読み込みのモード
* 関連するRails設定
* プロジェクトの構造
* 自動読み込み、再読み込み、eager loading
* STI(単一テーブル継承)
* その他

--------------------------------------------------------------------------------


はじめに
------------

INFO: 本ガイドでは、Railsアプリケーションの「自動読み込み」「再読み込み」「eager loading」について解説します

通常のRubyプログラムのクラスでは、依存関係のあるプログラムを明示的に読み込む必要があります。たとえば、以下のコントローラでは`ApplicationController`クラスや`Post`クラスを用いており、通常、それらを呼び出すには`require`する必要があります。

```ruby
# Railsではこのように書かないこと
require "application_controller"
require "post"
# Railsではこのように書かないこと

class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

Railsアプリケーションでは上のようなことはしません。アプリケーションのクラスやモジュールはどこででも利用できます。

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

通常のRailsアプリケーションで`require`呼び出しを行うのは、`lib`ディレクトリにあるものや、Ruby標準ライブラリ、Ruby gemなどを読み込むときだけです。そのため、これらのような自動読み込みパスに属さないものについてはすべて後述します。

Railsではこの機能を提供するため、いくつもの[Zeitwerk](https://github.com/fxn/zeitwerk)ローダーを開発者の代わりに管理しています。

プロジェクトの構造
-----------------

Railsアプリケーションで使うファイル名は、そこで定義されている定数名と一致しなければなりません。ファイル名はディレクトリ名と合わせて名前空間として振る舞います。

たとえば、`app/helpers/users_helper.rb`ファイルでは`UsersHelper`を定義すべきですし、`app/controllers/admin/payments_controller.rb`では`Admin::PaymentsController`を定義すべきです。

デフォルトのRailsは、ファイル名を`String#camelize`メソッドで活用するようZeitwerkを設定します。たとえば、`app/controllers/users_controller.rb`から以下のように`UsersController`という定数を定義します。

```ruby
"users_controller".camelize # => UsersController
```

このような活用形をカスタマイズする方法については、本ガイドの「[活用形をカスタマイズする](#活用形をカスタマイズする)」で後述します。

詳しくは[Zeitwerkのドキュメント](https://github.com/fxn/zeitwerk#file-structure)を参照してください。

`config.autoload_paths`
--------------

**自動読み込みパス**（オートロードパス: autoload path）とは、その中身が自動読み込みの対象となるアプリケーションディレクトリ（`app/models`など）のリストを指します。これらのディレクトリはルート名前空間である`Object`を表します。

INFO: Zeitwerkのドキュメントでは自動読み込みのパスを**ルートディレクトリ**と呼んでいますが、本ガイドでは「自動読み込みパス」と呼びます。

自動読み込みパスの下にあるファイル名は、[Zeitwerkのドキュメント](https://github.com/fxn/zeitwerk#file-structure)に記載されているとおりに定義された定数と一致しなければなりません。

デフォルトでは、あるアプリケーションの自動読み込みパスは次のもので構成されています。アプリケーションの起動時に`app`の下にあるすべてのサブディレクトリ（`assets`、`javascript`、`views`は除く）と、アプリケーションが依存する可能性のあるエンジンの自動読み込みパスです。

たとえば、`app/helpers/users_helper.rb`に`UsersHelper`が実装されていれば、そのモジュールは以下のように自動読み込み可能になります。したがって`require`呼び出しは不要です（し、書くべきではありません）。

```bash
$ rails runner 'p UsersHelper'
UsersHelper
```

Railsの自動読み込みパスには、`app`の下のあらゆるカスタムディレクトリも自動的に追加されます。たとえば、アプリケーションに`app/presenters`ディレクトリがあれば、自動読み込みの設定を変更しなくても`app/presenters`の下に置かれたものをすぐ利用できます。

デフォルトの自動読み込みパスの配列は、`config/application.rb`または`config/environments/*.rb`で以下のように`config.autoload_paths`に追加することで拡張可能です。

```ruby
module MyApplication
  class Application < Rails::Application
    config.autoload_paths << "#{root}/extras"
  end
end
```

また、Railsエンジンはエンジンクラスの本文内やエンジン独自の`config/environments/*.rb`にあるものを自動読み込みパスに追加することも可能です。

WARNING: `ActiveSupport::Dependencies.autoload_paths`はくれぐれも改変しないでください。自動読み込みパスを変更するpublicなインターフェイスは`config.autoload_paths`の方です。

WARNING: アプリケーションの起動中は、自動読み込みパス内のコードは自動で読み込まれません（特に`config/initializers/*.rb`の中）。正しい方法については、後述の[アプリケーション起動時の自動読み込み](#アプリケーション起動時の自動読み込み)を参照してください。

自動読み込みパスは、`Rails.autoloaders.main`オートローダーによって管理されます。

`config.autoload_once_paths`
--------------------------

クラスやモジュールを再読み込みせずに自動読み込みできるようにしたい場合があります。`autoload_once_paths`には、自動読み込みするが再読み込みはしないコードの保存場所を指定します。

このコレクションはデフォルトでは空ですが、`config.autoload_once_paths`に追加する形で拡張可能です。たとえば以下は`config/application.rb`または`config/environments/*.rb`に書けます。

```ruby
module MyApplication
  class Application < Rails::Application
    config.autoload_once_paths << "#{root}/app/serializers"
  end
end
```

また、Railsエンジンはエンジンクラスの本文内やエンジン独自の`config/environments/*.rb`にあるものを自動読み込みパスに追加することも可能です。

INFO: `app/serializers`を`config.autoload_once_paths`に追加すると、`app/`の下のカスタムディレクトリであってもRailsはこれを自動読み込みパスと見なさなくなります。この設定を行うと、このルールが上書きされます。

これは、Railsフレームワーク自体のような、再読み込みが可能な場所でキャッシュされるクラスやモジュールで重要になります。

たとえば、Active JobシリアライザをActive Jobの中に保存するとします。

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

再読み込みが発生しても、Active Jobそのものは再読み込みされず、自動読み込みパスにあるアプリケーションコードとエンジンコードのみが再読み込みされます。

この`MoneySerializer`を再読み込み可能にすると、改変バージョンのコードを再読み込みしてもActive Job内に保存されるそのクラスのオブジェクトに反映されないので、混乱が生じる可能性があります。実際に`MoneySerializer`を再読み込み可能にすると、Rails 7以降ではそのようなイニシャライザで`NameError`が発生します。

別のユースケースは、以下のようにフレームワークのクラスをdecorateするエンジンの場合です。

```ruby
initializer "decorate ActionController::Base" do
  ActiveSupport.on_load(:action_controller_base) do
    include MyDecoration
  end
end
```

この場合、イニシャライザが実行される時点では`MyDecoration`に保存されているモジュールオブジェクトが`ActionController::Base`の先祖となるので、`MyDecoration`を再読み込みしても先祖への継承チェイン（ancestor chain）に反映されず、無意味です。

`autoload_once_paths`のクラスやモジュールは`config/initializers`で自動読み込み可能です。すなわち、以下の設定を行うことで動くようになります。

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

INFO: 技術的には、`once`オートローダーによって管理されるクラスやモジュールは、`:bootstrap_hook`より後に実行される任意のイニシャライザで自動読み込みが可能です。

`autoload_once_paths`は、`Rails.autoloaders.once`で管理されます。

`$LOAD_PATH{#load_path}`
----------

自動読み込みパスは、デフォルトで`$LOAD_PATH`に追加されます。ただしZeitwerkは内部で絶対ファイル名を用いており、アプリケーション内では自動読み込み可能なファイルを`require`呼び出しすべきではないため、それらのディレクトリは実際には不要です。以下のフラグを用いることで、`$LOAD_PATH`に自動読み込みパスを追加しないようにできます。

```ruby
config.add_autoload_paths_to_load_path = false
```

こうすることで探索が削減され、正当な`require`が少し速くなる可能性もあります。また、アプリケーションで[Bootsnap](https://github.com/Shopify/bootsnap)を使っている場合は、このライブラリが不要なインデックスを構築しなくても済むため、必要なメモリ使用量を節約できます。

再読み込み
---------

Railsアプリケーションのファイルが変更されると、クラスやモジュールを自動的に再読み込みします。

正確に言うと、Webサーバーが実行中の状態でアプリケーションのファイルが変更されると、Railsは次のリクエストが処理される直前に、`main`オートローダが管理しているすべての定数をアンロードします。これによって、アプリケーションでリクエスト継続中に使われるクラスやモジュールが自動読み込みされるようになり、続いてファイルシステム上の現在の実装が反映されます。

再読み込みは有効にも無効にもできます。この振る舞いを制御するのは[`config.cache_classes`][]設定です。これは`development`モードではデフォルトで`false`（再読み込みが有効）、`production`モードでは`true`（再読み込みが無効）になります。

デフォルトのRailsは、変更されたファイルをイベンテッドファイルモニタで検出しますが、自動読み込みパスを調べてファイル変更を検出することも可能です。これは、[`config.file_watcher`][]の設定で制御されます。

Railsコンソールでは、 `config.cache_classes`の値にかかわらずファイルウォッチャーは動作しません（通常、コンソールセッションの最中に再読み込みが行われると混乱を招く可能性があるためです）。一般にコンソールセッションは、 個別のリクエストと同様に変化しない、一貫したアプリケーションクラスとモジュールのセットによって提供されることが望まれます。

ただし、コンソールで`reload!`を実行することで強制的に再読み込みできます。

```irb
irb(main):001:0> User.object_id
=> 70136277390120
irb(main):002:0> reload!
Reloading...
=> true
irb(main):003:0> User.object_id
=> 70136284426020
```

上のように、`User`定数に保存されているクラスオブジェクトは、再読み込みすると異なるものに変わります。

[`config.cache_classes`]: configuring.html#config-cache-classes
[`config.file_watcher`]: configuring.html#config-file-watcher

### 古くなったオブジェクトの再読み込み

Rubyには、メモリ上のクラスやモジュールを真の意味で再読み込みする手段もなければ、既に利用されているすべてのクラスやモジュールに再読み込みを反映する手段もないことを理解しておくことが、きわめて重要です。技術的には、`User`クラスを「アンロード」することは、`Object.send(:remove_const, "User")`で`User`定数を削除するということです。

たとえば、Railsコンソールセッションで以下をチェックしてみます。

```irb
irb> joe = User.new
irb> reload!
irb> alice = User.new
irb> joe.class == alice.class
=> false
```

`joe`は元の`User`クラスのインスタンスです。再読み込みが発生すると、この`User`定数はそれまでと異なる、再読み込みされたクラスとして評価されます。`alice`は新たに読み込んだ`User`クラスのインスタンスですが、`joe`のクラスはそうではなく、クラスが古くなっています（stale）。この場合は`reload!`を再度呼び出す代わりに、`joe`を再度定義するか、IRBサブセッションを起動するか、単に新しいコンソールセッションを起動することでも解決します。

また、再読み込み可能なクラスを、再読み込みされない場所でサブクラス化している場合にもこの問題が発生する可能性があります。

```ruby
# lib/vip_user.rb
class VipUser < User
end
```

`User`が再読み込みされても`VipUser`は再読み込みされないので、`VipUser`のスーパークラスは元の古いクラスのオブジェクトのままです。

結論: **再読み込み可能なクラスやモジュールをキャッシュしてはいけません**。

## アプリケーション起動時の自動読み込み

起動中のアプリケーションは、`once`オートローダが管理する`autoload_once_paths`からの自動読み込みが可能です（詳しくは前述の[`config.autoload_once_paths`](#config-autoload-once-paths)を参照）。

ただし、`main`オートローダが管理している自動読み込みパスからの自動読み込みはできません。これは、`config/initializers`にあるコードや、アプリケーションやエンジンのイニシャライズについても同様です。

その理由は、イニシャライザはアプリケーション起動時に1度しか実行されないためです。サーバーを再起動すれば、新しいプロセスで再度実行されますが、再読み込みはサーバーを再起動しないので、イニシャライザは実行されません。主な2つのユースケースを見てみましょう。

### ユースケース1: 起動中に、再読み込み可能なコードを読み込む

#### 起動時と各再読み込みの両方で実行される自動読み込み

`main`オートローダーが管理している`app/services`に`ApiGateway`という再読み込み可能なクラスがあるとします。そしてアプリケーション起動時にエンドポイントを設定する必要が生じたとします。以下のように書くとエラーになります。

```ruby
# config/initializers/api_gateway_setup.rb
ApiGateway.endpoint = "https://example.com" # NameError
```

イニシャライザは再読み込み可能な定数を参照できないので、`to_prepare`ブロックを使って、再読み込み時に実行されるコードをラップする必要があります。この部分は起動時に読み込まれ、また再読み込みのたびに読み込まれるようになります。

```ruby
# config/initializers/api_gateway_setup.rb
Rails.application.config.to_prepare do
  ApiGateway.endpoint = "https://example.com" # 正しい
end
```

NOTE: 歴史的な理由により、このコールバックは2回実行される可能性があります。ここで実行するコードは[冪等](https://ja.wikipedia.org/wiki/%E5%86%AA%E7%AD%89#%E6%83%85%E5%A0%B1%E5%B7%A5%E5%AD%A6%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E5%86%AA%E7%AD%89)でなければなりません。

#### 起動時にのみ実行される自動読み込み

再読み込み可能なクラスとモジュールは、`after_initialize`ブロックでも自動読み込みが可能です。これらは起動時に実行されますが、再読み込み時には再実行されません。例外的な状況では、この振る舞いにしたいこともあります。

以下のようなプリフライトチェックはそうしたユースケースのひとつです。

```ruby
# config/initializers/check_admin_presence.rb
Rails.application.config.after_initialize do
  unless Role.where(name: "admin").exists?
    abort "adminロールが存在しません。データベースのseedを行ってください。"
  end
end
```

### ユースケース2: 起動中に、キャッシュされたままのコードを読み込む

設定によっては、何らかのクラスやモジュールのオブジェクトを受け取って、それを再読み込みされない場所に保存するものもあります。こうした設定では、コードの編集の結果がキャッシュ済みの古いオブジェクトに反映されないため、設定に渡すものは再読み込み可能にしないことが重要です。

そうした例の1つがミドルウェアです。

```ruby
config.middleware.use MyApp::Middleware::Foo
```

再読み込みを行っても、このミドルウェアスタックには反映されないので、`MyApp::Middleware::Foo`が再読み込み可能になっていると混乱の元になります（その実装を変更しても何も反映されません）。

別の例は、Active Jobシリアライザです。

```ruby
# config/initializers/custom_serializers.rb
Rails.application.config.active_job.custom_serializers << MoneySerializer
```

初期化時に`MoneySerializer`が評価したものは、すべてこのカスタムシリアライザにプッシュされ、そのオブジェクトは再読み込み時にも残り続けます。

さらに別の例は、Railtieやエンジンがモジュールを`include`してフレームワークのクラスをdecorateする場合です。たとえば、[`turbo-rails`](https://github.com/hotwired/turbo-rails)は`ActiveRecord::Base`を以下のようにdecorateします。

```ruby
initializer "turbo.broadcastable" do
  ActiveSupport.on_load(:active_record) do
    include Turbo::Broadcastable
  end
end
```

これにより、`ActiveRecord::Base`の先祖への継承チェインにモジュールオブジェクトが追加されます。しかし再読み込みが発生しても`Turbo::Broadcastable`の変更は反映されないので、先祖への継承チェインには元のオブジェクトが引き続き残ります。

すなわち、こうしたクラスやモジュールは**再読み込み可能にできません**。

そのようなクラスやモジュールを起動時に参照する最も手軽な方法は、自動読み込みパスに属さないディレクトリでそれらを定義することです。たとえば`lib/`に置くのが妥当でしょう。`lib/`はデフォルトでは自動読み込みパスに属しませんが、`$LOAD_PATH`には属しているので、`require`するだけで読み込めます。

別の方法は、上述のように、それらを`autoload_once_paths`ディレクトリで定義して自動読み込みすることです（詳しくは前述の[`config.autoload_once_paths`](#config-autoload-once-paths)を参照）。

### ユースケース3: エンジンで使うアプリケーションのクラスを設定する

あるエンジンが、ユーザーをモデリングする再読み込み可能なアプリケーションクラスと連携する場合、そのための設定ポイントが以下のようになっていると、エラーになります。

```ruby
# config/initializers/my_engine.rb
MyEngine.configure do |config|
  config.user_model = User # NameError
end
```

再読み込み可能なアプリケーションコードをエンジンで正しく扱うには、代わりにアプリケーションのクラス名を**文字列**で設定する必要があります。

```ruby
# config/initializers/my_engine.rb
MyEngine.configure do |config|
  config.user_model = "User" # OK
end
```

これで、実行時に`config.user_model.constantize`で現在のクラスオブジェクトを得られるようになります。

eager loading
-------------

一般的にproduction的な環境では、アプリケーションの起動時にアプリケーションコードをすべて読み込んでおく方が望ましいと言えます。eager loading（一括読み込み）はすべてをメモリ上に読み込むことでリクエストに即座に対応できるように備え、[CoW](https://ja.wikipedia.org/wiki/%E3%82%B3%E3%83%94%E3%83%BC%E3%82%AA%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%88)（コピーオンライト）との相性にも優れています。

eager loadingは[`config.eager_load`][]フラグで制御します。これは`production`以外のすべての環境でデフォルトで無効になっています。rakeタスクが実行されると、`config.eager_load`は[`config.rake_eager_load`][]で上書きされ、デフォルトでは`false`になります。つまり、production環境で実行するrakeタスクは、デフォルトではアプリケーションをeager loadingしません。

ファイルがeager loadingされる順序は未定義です。

eager loading中に、Railsは`Zeitwerk::Loader.eager_load_all`を呼び出します。これはすべてのZeitwerkが管理している依存gemもeager loadされていることを保証します。

[`config.eager_load`]: configuring.html#config-eager-load
[`config.rake_eager_load`]: configuring.html#config-rake-eager-load

STI（単一テーブル継承）
------------------------

単一テーブル継承機能は、lazy loading（遅延読み込み）との相性があまりよくありません。一般に単一テーブル継承のAPIが正しく動作するには、STI階層を正しく列挙できる必要があるためです。lazy loadingでは、クラスが参照されるまでクラス読み込みは遅延されます。まだ参照されていないものは列挙できないのです。

ある意味、アプリケーションは読み込みモードにかかわらずSTI階層をeager loadする必要があります。

もちろん、アプリケーションが起動時にeager loadするのであれば目的は既に達成されます。そうでない場合、実際にはデータベース内の既存の型をインスタンス化すれば十分です。developmentモードやtestモードであれば普通はこれで問題ありません。これを行う方法の1つは、このモジュールを`lib`ディレクトリに配置することです。

```ruby
module StiPreload
  unless Rails.application.config.eager_load
    extend ActiveSupport::Concern

    included do
      cattr_accessor :preloaded, instance_accessor: false
    end

    class_methods do
      def descendants
        preload_sti unless preloaded
        super
      end

      # データベース内にあるすべての型を定数化する。
      # その分ディスク容量が余分に必要だが、
      # STIのAPIに配慮されていれば実際には問題ではない。
      #
      # store_full_sti_classがtrue（デフォルト）であることが前提
      def preload_sti
        types_in_db = \
          base_class.
            unscoped.
            select(inheritance_column).
            distinct.
            pluck(inheritance_column).
            compact

        types_in_db.each do |type|
          logger.debug("Preloading STI type #{type}")
          type.constantize
        end

        self.preloaded = true
      end
    end
  end
end
```

続いて、プロジェクトのSTIルートクラスで`include`します。

```ruby
# app/models/shape.rb
require "sti_preload"

class Shape < ApplicationRecord
  include StiPreload # rootクラスにのみ存在する
end
```

```ruby
# app/models/polygon.rb
class Polygon < Shape
end
```

```ruby
# app/models/triangle.rb
class Triangle < Polygon
end
```

活用形をカスタマイズする
-----------------------

デフォルトのRailsは、指定のファイル名やディレクトリ名がどんな定数を定義すべきかを知るのに`String#camelize`を利用します。たとえば、`posts_controller.rb`というファイル名の場合は`PostsController`が定義されていると認識しますが、これは`"posts_controller".camelize`が`PostsController`を返すからです。

場合によっては、特定のファイル名やディレクトリ名が期待どおりに活用されないことがあります。たとえば`html_parser.rb`はデフォルトでは`HtmlParser`を定義すると予測できます。しかしクラス名を`HTMLParser`にしたい場合はどうすればよいでしょうか。この場合のカスタマイズ方法はいくつか考えられます。

最も手軽な方法は、以下のように略語を定義することです。

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "HTML"
  inflect.acronym "SSL"
end
```

これによって、Active Supportによる活用方法がグローバルに反映されます。
これで問題のないアプリケーションもありますが、以下のようにデフォルトのインフレクタに上書き用のコレクションを渡して、Active Supportの個別の基本語形をキャメルケース化する方法をカスタマイズすることも可能です。

```ruby
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

しかしデフォルトのインフレクタは`String#camelize`をフォールバック先として使っているので、この手法は依然として`String#camelize`に依存しています。Active Supportの活用形機能に一切依存せずに活用形を絶対的に制御したい場合は、以下のように`Zeitwerk::Inflector`のインスタンスをインフレクタとして設定します。

```ruby
Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "html_parser" => "HTMLParser",
    "ssl_error"   => "SSLError"
  )
end
```

この場合は、インスタンスに影響するようなグローバル設定が存在しないので、活用形は1つに決定されます。

カスタムインフレクタを定義して柔軟性を高めることも可能です。詳しくは[Zeitwerkドキュメント](https://github.com/fxn/zeitwerk#custom-inflector)を参照してください。

### 活用形のカスタマイズはどこで行うべきか

アプリケーションが`once`オートローダを使わない場合、上記のスニペットは`config/initializers`に保存できます。たとえば、Active Supportを使う場合は`config/initializers/inflections.rb`に書き、それ以外の場合は`config/initializers/zeitwerk.rb`に書くとよいでしょう。

アプリケーションが`once`オートローダを使う場合は、この設定を別の場所に移動するか、`config/application.rb`のアプリケーションクラスの本体から読み込む必要があります。`once`オートローダーはブートプロセスの早い段階でインフレクタを利用するからです。

自動読み込みとRailsエンジン
-----------------------

Railsエンジンは、親アプリケーションのコンテキストで動作し、エンジンのコードの自動読み込み、再読み込み、eager loadingは親アプリケーションによって行われます。アプリケーションを`zeitwerk`モードで実行する場合は、エンジンのコードも`zeitwerk`モードで読み込まれます。アプリケーションを`classic`モードで実行する場合は、エンジンのコードも`classic`モードで読み込まれます。

Railsが起動すると、エンジンのディレクトリが自動読み込みパスに追加されますが、自動読み込みという観点からは何の違いもありません。自動読み込みの主な入力は自動読み込みパスであり、そのパスがアプリケーションのソースツリーであるか、エンジンのソースツリーであるかは無関係です。

たとえば、以下のアプリケーションは[Devise](https://github.com/heartcombo/devise)を使っています。

```bash
% bin/rails runner 'pp ActiveSupport::Dependencies.autoload_paths'
[".../app/controllers",
 ".../app/controllers/concerns",
 ".../app/helpers",
 ".../app/models",
 ".../app/models/concerns",
 ".../gems/devise-4.8.0/app/controllers",
 ".../gems/devise-4.8.0/app/helpers",
 ".../gems/devise-4.8.0/app/mailers"]
```

このエンジンが親アプリケーションの自動読み込みを制御するのであれば、これまでどおりにエンジンを書けます。

しかし、エンジンがRails 6や6.1以降をサポートしており、親アプリケーションの自動読み込みを制御しないのであれば、`classic`モードと`zeitwerk`モードのどちらの場合でも実行可能になるように書かなければなりません。そのためには、以下を考慮する必要があります。

1. `classic`モードで特定の箇所で何らかの定数を確実に読み込ませるために`require_dependency`呼び出しが必要な場合は、`require_dependency`呼び出しを書く。これは`zeitwerk`モードでは不要ですが、`zeitwerk`モードでも問題なく動作します。

2. `classic`モードは定数名をアンダースコア化してファイル名を求め（"User" -> "user.rb"）、逆に`zeitwerk`モードではファイル名を`camelize`して定数名を求める（"user.rb" -> "User"）。両者はほとんどの場合一致しますが、`HTMLParser`のように大文字が連続すると一致しなくなります。互換性を保つ最も手軽な方法は、大文字が連続する名前を避けることです（この場合は"HtmlParser"にします）。

3. `classic`モードでは、`app/model/concerns/foo.rb`ファイルに`Foo`と`Concerns::Foo`を両方定義することを容認するが、`zeitwerk`モードでは`Foo`のみの定義しか許さない。互換性のためには`Foo`を定義してください。


テスト
-------

### 手動テスト

`zeitwerk:check`タスクを使うと、プロジェクトツリーが上述の命名規則に沿っているかを手軽に手動チェックできます。たとえば、`classic`モードから`zeitwerk`モードに移行するときや、何かを修正するときにこのタスクを使うと便利です。

```bash
% bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

アプリケーションの設定次第では他にも出力される可能性がありますが、末尾に"All is good!"が表示されるかどうかをチェックすれば十分です。

### 自動テスト

プロジェクトが正しくeager loadingされているかどうかをテストスイートで検証するのはよい方法です。

Zeitwerkの命名規則やその他に発生しうるエラー条件をカバーできます。詳しくは[Railsテスティングガイド](testing.html)の[eager loadingをテストする](testing.html#eager-loadingをテストする)を参照してください。

トラブルシューティング
---------------

ローダーの振る舞いを追跡するベストの方法は、ローダーの活動を調べることです。

最も手軽な方法は、フレームワークのデフォルトが読み込まれた後で以下を`config/application.rb`に設定することです。

```ruby
Rails.autoloaders.log!
```

これにより、標準出力にトレースが出力されます。

ログをファイルに出力したい場合は、上の代わりに以下を設定します。

```ruby
Rails.autoloaders.logger = Logger.new("#{Rails.root}/log/autoloading.log")
```

Railsロガーは、`config/application.rb`が実行される時点ではまだ利用できません。Railsロガーを使いたい場合は、イニシャライザの設定を以下のように変更します。

```ruby
# config/initializers/log_autoloaders.rb
Rails.autoloaders.logger = Rails.logger
```

`Rails.autoloaders`
-----------------

アプリを管理するZeitwerkのインスタンスは以下で利用できます。

```ruby
Rails.autoloaders.main
Rails.autoloaders.once
```

以下の述語メソッドは引き続きRails 7でも利用可能で、`true`を返します。

```ruby
Rails.autoloaders.zeitwerk_enabled?
```
