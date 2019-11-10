定数の自動読み込みと再読み込み (Zeitwerk)
===================================

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

INFO: 本ガイドでは、Rails 6.0で新たに導入された`Zeitwerk`モードの自動読み込みについて解説します。Rails 5.2以前の`Classic`モードについては、[定数の自動読み込みと再読み込み (Classic)](autoloading_and_reloading_constants_classic_mode.html) を参照してください。

通常のRubyプログラムのクラスであれば、依存関係のあるプログラムを明示的に読み込む必要があります。たとえば、以下のコントローラでは`ApplicationController`クラスや`Post`クラスを用いており、通常、それらを呼び出すには`require`する必要があります。

```ruby
# 実際にはこのように書かないこと
require "application_controller"
require "post"
# 実際にはこのように書かないこと

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


Zeitwerkモードを有効にする
----------------------

自動読み込みの`zeitwerk`モードは、CRuby上で実行されるRails 6アプリケーションではデフォルトで有効になります。

```ruby
# config/application.rb
config.load_defaults "6.0" # CRubyでzeitwerkモードが有効になる
```

`zeitwerk`モードのRailsは、内部で自動読み込み、再読み込み、eager loadingに[Zeitwerk](https://github.com/fxn/zeitwerk)を用います。Railsは、プロジェクトを管理する専用のZeitwerkインスタンスのインスタンス化や設定を行います。

INFO: RailsアプリケーションのZeitwerkは手動で設定しないでください。代わりに、本ガイドで後述する移植可能な設定ポイントを用いてアプリケーションを設定してください。代わりにRailsが設定をZeitwerk向けに変換します。

プロジェクトの構造
-----------------

Railsアプリケーションで使うファイル名は、そこで定義されている定数名と一致しなければなりません。ファイル名はディレクトリ名と合わせて名前空間として振る舞います。

たとえば、`app/helpers/users_helper.rb`ファイルでは`UsersHelper`を定義すべきですし、`app/controllers/admin/payments_controller.rb`では`Admin::PaymentsController`を定義すべきです。

Railsは、ファイル名を`String#camelize`で活用するようZeitwerkを設定します。たとえば、`app/controllers/users_controller.rb`は以下のために`UsersController`という定数を定義します。

```ruby
"users_controller".camelize # => UsersController
```

このような活用形をカスタマイズする必要が生じた場合（略語を追加するなど）は、`config/initializers/inflections.rb`をチェックしてみてください。

詳しくは[Zeitwerkのドキュメント](https://github.com/fxn/zeitwerk#file-structure)を参照してください。

自動読み込みのパス
--------------

**自動読み込みパス**（autoload path）とは、その中身が自動読み込みの対象となるアプリケーションディレクトリを指します（`app/models`など）。これらのディレクトリはルート名前空間`Object`を表します。

INFO: Zeitwerkのドキュメントでは自動読み込みのパスを**ルートディレクトリ**と呼んでいますが、本ガイドでは「自動読み込みパス」と呼びます。

自動読み込みパスの下にあるファイル名は、[Zeitwerkのドキュメント](https://github.com/fxn/zeitwerk#file-structure)に記載されているとおりに定義された定数と一致しなければなりません。

デフォルトでは、あるアプリケーションの自動読み込みパスは次のもので構成されています。アプリケーションの起動時に`app`の下にあるすべてのサブディレクトリ（`assets`、`javascripts`、`views`は除外）と、アプリケーションが依存する可能性のあるエンジンの自動読み込みパスです。

たとえば、`app/helpers/users_helper.rb`に`UsersHelper`が実装されていれば、そのモジュールは以下のように自動読み込み可能になります。したがって`require`呼び出しは不要です（し、書くべきではありません）。

```
$ rails runner 'p UsersHelper'
UsersHelper
```

自動読み込みパスは、`app`の下のあらゆるカスタムディレクトリを自動的に扱います。たとえば、アプリケーションに`app/presenters`や`app/services`があれば、自動読み込みパスに追加されます。

自動読み込みパスの配列は、`config/application.rb`の`config.autoload_paths`を書き換えることで拡張可能ではありますが、やめておきましょう。

WARNING: `ActiveSupport::Dependencies.autoload_paths`はくれぐれも変更しないでください。自動読み込みパスを変更するpublicなインターフェイスは`config.autoload_paths`の方です。

`$LOAD_PATH`
----------

自動読み込みパスはデフォルトで`$LOAD_PATH`に追加されます。ただし、Zeitwerkの内部では絶対ファイル名が使われますし、アプリケーションで自動読み込み可能なファイルを`require`すべきではありませんので、`$LOAD_PATH`に追加されたこれらのディレクトリは実際には不要です。この動作は以下のフラグで無効にできます。

```ruby
config.add_autoload_paths_to_load_path = false
```

こうすることで探索量が削減されて、正しい`require`呼び出しがわずかに高速化される可能性があります。また、アプリケーションで[Bootsnap](https://github.com/Shopify/bootsnap)を使っている場合も、ライブラリの不要なインデックス構築や、必要なメモリ量が節約されます。


再読み込み
---------

Railsアプリケーションのファイルが変更されると、クラスやモジュールを自動的に再読み込みします。

正確に言うと、Webサーバーが実行中の状態でアプリケーションのファイルが変更されると、Railsは次のリクエストが処理される直前にすべての定数をアンロードします。これによって、アプリケーションでリクエスト継続中に使われるクラスやモジュールが自動読み込みされるようになり、続いてファイルシステム上の現在の実装が反映されます。

再読み込みは有効にも無効にもできます。この振る舞いを制御するのは`config.cache_classes`設定です。これは`development`モードではデフォルトで`false`（再読み込みが有効）、`production`モードでは`true`（再読み込みが無効）になります。

デフォルトのRailsは、変更されたファイルをイベンテッドファイルモニタで検出します。あるいは、`config.file_watcher`に応じて自動読み込みパスを探索します。

Railsコンソールでは、 `config.cache_classes`の値にかかわらずファイルウォッチャーは動作しません。通常、コンソールセッションの最中に再読み込みが行われると混乱を招く可能性があるので、アプリケーションのクラスやモジュールは変更されない一貫した状態で個別のリクエストを提供することが一般に望まれます。

ただし、`reload!`を実行することで強制的に再読み込みできます。

```
$ bin/rails c
Loading development environment (Rails 6.0.0)
irb(main):001:0> User.object_id
=> 70136277390120
irb(main):002:0> reload!
Reloading...
=> true
irb(main):003:0> User.object_id
=> 70136284426020
```

上のように、`User`定数に保存されているクラスオブジェクトは、再読み込み後に変わります。

### 古くなったオブジェクトの再読み込み

Rubyには、メモリ上のクラスやモジュールを真の意味で再読み込みする手段もなければ、既に利用されているすべてのクラスやモジュールにそれを反映する手段もないことを理解しておくことが、きわめて重要です。技術的には、`User`クラスを「アンロード」することは、`Object.send(:remove_const, "User")`で`User`定数を削除するということです。

つまり、再読み込み可能なクラスやモジュールのオブジェクトが、再読み込みできない場所に保存されると、それらの値はいずれ古くなります（stale）。

たとえば、あるイニシャライザが、特定のクラスオブジェクトを1つ保存してキャッシュするとします。

```ruby
# config/initializers/configure_payment_gateway.rb
# 実際にはこのように書かないこと
$PAYMENT_GATEWAY = Rails.env.production? ? RealGateway : MockedGateway
# 実際にはこのように書かないこと
```

`MockedGateway`が再読み込みされると、`MockedGateway`クラスオブジェクトはイニシャライザが実行されたときの状態で引き続き`$PAYMENT_GATEWAY`に保管されていると評価されます。`$PAYMENT_GATEWAY`に保存されているクラスオブジェクトは、再読み込みで変更されません。

同様に、Railsコンソールでuserインスタンスを作って再読み込みするとします。

```
> user = User.new
> reload!
```

この`user`オブジェクトは、古くなったクラスオブジェクトのインスタンスです。`User`を再度評価すればRubyが新しいクラスを渡しますが、そのインスタンスの`User`クラスは更新されません。

別のユースケースで注意点を示します。再読み込み可能なクラスを、再読み込みできない場所でサブクラス化するとします。

```ruby
# lib/vip_user.rb
class VipUser < User
end
```

`User`が再読み込みされても`VipUser`は再読み込みされないので、`VipUser`のスーパークラスは元の古いクラスオブジェクトのままです。

結論: **再読み込み可能なクラスやモジュールをキャッシュしてはいけません**。


eager loading
-------------

production的な環境では、アプリケーションの起動時にアプリケーションコードをすべて読み込んでおく方が一般的によくなります。eager loading（一括読み込み）はすべてをメモリ上に読み込むことでリクエストに即座に対応できるように備え、[CoW](https://en.wikipedia.org/wiki/Copy-on-write)（コピーオンライト）との相性にも優れています。

eager loadingは`config.eager_load`フラグで制御します。`production`モードではデフォルトで有効です。

ファイルがeager loadingされる順序は未定義です。

`Zeitwerk`という定数を定義すると、Railsはアプリケーションの自動読み込みモードにかかわらず`Zeitwerk::Loader.eager_load_all`を呼び出します。Zeitwerkが管理する依存はこのようにしてeager loadされます。


STI(単一テーブル継承)
------------------------

単一テーブル継承機能は、lazy loadingとの相性があまりよくありません。一般に単一テーブル継承のAPIが正しく動作するには、STI階層を正しく列挙できる必要があるためです。lazy loadingでは、クラスが参照されるまでクラス読み込みは遅延されます。まだ参照されていないものは列挙できないのです。

ある意味、アプリケーションはSTI階層を読み込みモードにかかわらずeager loadする必要があります。

もちろん、アプリケーションが起動時にeager loadするのであれば目的は既に達成されます。そうでない場合、実際にはデータベース内の既存の型をインスタンス化すれば十分です。developmentモードやtestモードであれば普通はこれで問題ありません。これを行う方法のひとつは、このモジュールを`lib`ディレクトリに配置することです。

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
      # store_full_sti_classがtrueであることが前提（デフォルト）
      def preload_sti
        types_in_db = \
          base_class.
            select(inheritance_column).
            distinct.
            pluck(inheritance_column).
            compact.
            each(&:constantize)

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

続いて、プロジェクトでSTIのルートクラスで`include`します。

```ruby
# app/models/shape.rb
require "sti_preload"

class Shape < ApplicationRecord
  include StiPreload # Only in the root class.
end

# app/models/polygon.rb
class Polygon < Shape
end

# app/models/triangle.rb
class Triangle < Polygon
end
```

トラブルシューティング
---------------

ローダーの振る舞いを追跡するベストの方法は、ローダーの活動を調べることです。

最も簡単な方法は、フレームワークのデフォルトが読み込まれた後で以下を`config/application.rb`に設定することです。

```ruby
Rails.autoloaders.log!
```

これにより、標準出力にトレースが出力されます。

ログをファイルに出力したい場合は、上の代わりに以下を設定します。

```ruby
Rails.autoloaders.logger = Logger.new("#{Rails.root}/log/autoloading.log")
```

Railsロガーは`config/application.rb`には設定されていませんが、以下のようにイニシャライザで設定されています。

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

最初のものがメインで、次のものは主に後方互換性上の理由で存在しています。たとえばアプリケーションが`config.autoload_once_paths`で何かを行う場合などです（これは現在おすすめしません）。

`zeitwerk`モードが有効かどうかは以下の設定で確認できます。

```ruby
Rails.autoloaders.zeitwerk_enabled?
```

Zeitwerkを使わない場合
----------

次のようにすることで、アプリケーションがRails 6のデフォルトを読み込みながら`classic`オートローダーを引き続き使えます。

```ruby
# config/application.rb
config.load_defaults "6.0"
config.autoloader = :classic
```

これはRails 6をいくつかのフェーズに分けてアップグレードする場合に便利ですが、`classic`モードは新しいアプリケーションではおすすめしません。

`zeitwerk`モードは、Rails 6.0より前のバージョンでは利用できません。
