Classic から Zeitwerk への移行
=========================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Classic to Zeitwerk HOWTO](https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html)を日本語に翻訳した文書です。

本ガイドでは、Railsアプリケーションを`classic`モードから`zeitwerk`モードに移行する方法について解説します。

このガイドの内容:

* `classic`モードと`zeitwerk`モードについて
* `classic`から`zeitwerk`に切り替える理由
* `zeitwerk`モードを有効にする
* アプリケーションが`zeitwerk`モードで動いていることを検証する
* プロジェクトが正しく読み込まれることをコマンドラインで検証する
* プロジェクトが正しく読み込まれることをテストスイートで検証する
* 想定されるエッジケースの対応方法
* Zeitwerkで利用できる新機能

--------------------------------------------------------------------------------

`classic`モードと`zeitwerk`モードについて
--------------------------------------------------------

Railsは最初期からRails 5まで、Active Supportで実装されたオートローダーを用いていました。このオートローダーは`classic`と呼ばれ、Rails 6.xでは引き続き利用可能です。`classic`オートローダーはRails 7で廃止されました。

Rails 6から、より優れた新しいオートロード方法がRailsに搭載されました。これは[Zeitwerk](https://github.com/fxn/zeitwerk)というgemに一任されています。これが`zeitwerk`モードです。デフォルトでは、Railsフレームワーク6.0および6.1の読み込みは`zeitwerk`モードで実行され、Rails 7で利用できるのは`zeitwerk`モードのみとなります。

`classic`から`zeitwerk`に切り替える理由
----------------------------------------

`classic`オートローダーは非常に便利でしたが、取り扱いに少々注意を要したり時に混乱を招いたりする[問題](https://guides.rubyonrails.org/v6.1/autoloading_and_reloading_constants_classic_mode.html#common-gotchas)が多数存在していました。Zeitwerkはこうした問題を解決するために開発されました（その他にもさまざまな[動機](https://github.com/fxn/zeitwerk#motivation)があります）。

`classic`モードは非推奨化されたので、Railsを6.xにアップグレードする際に`zeitwerk`モードに移行することを強く推奨します。

この移行はRails 7で完了し、`classic`モードが含まれなくなりました。

「移行するのが怖いんですが」
-----------

大丈夫です。

Zeitwerkは従来のオートローダーとの互換性をできるだけ維持するように設計されています。現在のアプリケーションでオートロードが正しく行われていれば、切り替えは簡単です。大小さまざまなプロジェクトで、スムーズに切り替えられたことが報告されています。

本ガイドを読めば、安心してオートローダーを切り替えられます。

何らかの理由で解決方法が見当たらない状況に直面した場合は、お気軽に[`rails/rails`リポジトリ](https://github.com/rails/rails/issues/new)のissueをオープンして、[`@fxn`](https://github.com/fxn)にメンションしてください。

`zeitwerk`モードを有効にする
-------------------------------

### Rails 5.x以前のアプリケーションの場合

Rails 6.0より前のバージョンを実行するアプリケーションでは`zeitwerk`モードを利用できません。Rails 6.0以上が必要です。

### Rails 6.xアプリケーションの場合

Rails 6.xアプリケーションの場合は以下の2とおりのシナリオがあります。

アプリケーションがRails 6.0または6.1のフレームワークのデフォルトを読み込んでいて、かつ`classic`モードで実行されている場合は、`classic`モードを手動でオプトアウトしなければなりません。これは以下のような形で行う必要があります。

```ruby
# config/application.rb
config.load_defaults 6.0
config.autoloader = :classic # この行を削除する
```

上のコメントにあるように、このオーバーライドを削除すると`zeitwerk`モードがデフォルトになります。

一方、アプリケーションが古いフレームワークのデフォルトを読み込んでいる場合は、以下のように`zeitwerk`モードを明示的に有効にする必要があります。

```ruby
# config/application.rb
config.load_defaults 5.2
config.autoloader = :zeitwerk
```

### Rails 7アプリケーションの場合

Rails 7には`zeitwerk`モードしかないので、このモードを有効にするために設定を変更する必要はありません。

Rails 7では`config.autoloader=`セッターそのものがなくなりました。`config/application.rb`にこの記述がある場合は、その行を削除してください。

アプリケーションが`zeitwerk`モードで動いていることを検証する
------------------------------------------------------

アプリケーションが`zeitwerk`モードで動いていることを検証するには、以下を実行します。

```bash
$ bin/rails runner 'p Rails.autoloaders.zeitwerk_enabled?'
```

`true`が出力されれば、`zeitwerk`モードが有効です。


アプリケーションがZeitwerkに沿っているかを確かめる
-----------------------------------------------------

### config.eager_load_paths

Zeitwerkに準拠しているかどうかのテストは、eager loadingされたファイルに対してのみ実行されます。そのため、Zeitwerkへの準拠を検証するには、すべての自動読み込みパスをeager loadパスに追加することが推奨されます。

これは既にデフォルトで行われるようになっていますが、自分のプロジェクトで自動読み込みパスを以下のようにカスタマイズしている場合は、eager loadingされないため検証されません。

```ruby
config.autoload_paths << "#{Rails.root}/extras"
```

以下のようにすることで、手軽にeager loadingパスに追加できます。

```ruby
config.autoload_paths << "#{Rails.root}/extras"
config.eager_load_paths << "#{Rails.root}/extras"
```

### zeitwerk:check

`zeitwerk`モードを有効にし、eager loading設定をダブルチェックしたら、以下を実行します。

```bash
$ bin/rails zeitwerk:check
```

チェックが成功すると以下のように出力されます。

```bash
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

アプリケーションの設定によってはこの他にも出力されることがありますが、末尾に"All is good!"があればOKです。

前節で説明したダブルチェックで、カスタムの自動読み込みパスがeager loadingパスの外にあると判断されると、タスクはそれを検出して警告を発します。しかし、テストスイートがそれらのファイルの読み込みに成功していれば、問題ありません。

Zeitwerkで期待される定数が定義されていないファイルがあると、上のタスクで通知されます。このタスクは1ファイルごとに実行されます。問題が生じたときにタスクが先に進むと、あるファイルの読み込み失敗が他の無関係な失敗に連鎖してエラー出力が読みにくくなるためです。

定数に1つでも問題があれば、その問題を解決し、"All is good!"が出力されるまでタスクを再実行してください。

たとえば以下のように出力されたとします。

```bash
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
expected file app/models/vat.rb to define constant Vat
```

VATはヨーロッパの税制のことです。`app/models/vat.rb`では`VAT`が定義済みですが、オートローダーは`Vat`を期待しています。どんな理由でこうなったのでしょうか。

### 略語の扱い

これはZeitwerkで最もありがちな問題で、略語が関係しています。このエラーメッセージが生じた理由を考えてみましょう。

`classic`オートローダーは、すべて大文字の`VAT`をオートロードできます。その理由は、オートローダーの入力に`const_missing `の定数名が使われるからです。`VAT`という定数に対して`underscore`が呼び出されて`vat`が生成され、これを元に`vat.rb`というファイルを検索することで、ファイルが正常に見つかります。

新しいZeitwerkオートローダーの入力はファイルシステムです。`vat.rb`というファイルがあると、Zeitwerkは`vat`に対して`camelize`を呼び出し、冒頭のみが大文字の`Vat`が生成されます。これにより、`Vat`という定数名が定義されていることが期待されます。以上がエラーメッセージの内容です。

これは、以下のように`ActiveSupport::Inflector`の語尾活用機能を用いて略語を指定するだけで簡単に修正できます。

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "VAT"
end
```

上の方法は、Active Supportの語尾活用機能をグローバルに変更します。これで問題ない場合もありますが、オートローダーで用いられる語尾活用機能にオーバーライドを渡したい場合は、以下のようにします。

```ruby
# config/initializers/zeitwerk.rb
Rails.autoloaders.main.inflector.inflect("vat" => "VAT")
```

このオプションを使うと、`vat.rb`というファイル名、または`vat`というディレクトリ名のみが`VAT`として認識されるので、より細かく制御できます。`vat_rules.rb`という名前のファイルはその影響を受けないので、`VatRules`を正しく定義できるようになります。このような名前の不一致があるプロジェクトで役に立つでしょう。

以上が終われば、チェックはパスします。

```bash
$ bin/rails zeitwerk:check
Hold on, I am eager loading the application.
All is good!
```

すべて問題なく動くようになったら、テストスイートで今後もプロジェクトを検証し続けることをおすすめします。これについて詳しくは[Zeitwerk準拠をテストスイートでチェックする](#zeitwerk%E6%BA%96%E6%8B%A0%E3%82%92%E3%83%86%E3%82%B9%E3%83%88%E3%82%B9%E3%82%A4%E3%83%BC%E3%83%88%E3%81%A7%E3%83%81%E3%82%A7%E3%83%83%E3%82%AF%E3%81%99%E3%82%8B)で後述します。
### concernsについて

以下のように、`concerns`サブディレクトリを持つ標準的な構造からのオートロードやeager loadingを行えます。

```
app/models
app/models/concerns
```

`app/models/concerns`ディレクトリはデフォルトではオートロードのパスに属しているので、これがrootディレクトリと見なされます。そのため、デフォルトでは`app/models/concerns/foo.rb`ファイルで定義されるのは`Concerns::Foo`ではなく`Foo`になります。

アプリケーションで`Concerns`が名前空間として使われている場合は、以下の2つの方法があります。

1. これらのクラスやモジュールから`Concerns`名前空間を削除してクライアントコードを更新する。
2. オートロードのパスから`app/models/concerns`を除外することで現状のままにする。

```ruby
# config/initializers/zeitwerk.rb
ActiveSupport::Dependencies.
  autoload_paths.
  delete("#{Rails.root}/app/models/concerns")
```

### オートロードパスに`app`を追加する

プロジェクトによっては、たとえば`API::Base`を定義する`app/api/base.rb`を置き、オートロードパスに`app`を追加することで利用したい場合もあります。

Railsは自動的に`app`のすべてのサブディレクトリ（アセットのディレクトリなどは除く）もオートロードパスに追加するので、`app/models/concerns`で起きたのと似たようなネステッドrootディレクトリの問題がここでも起きます。今後、この設定はこのままでは機能しません。

ただし、以下のようにイニシャライザでオートロードパスから`app/api`を削除すれば現状の構造を維持できます。

```ruby
# config/initializers/zeitwerk.rb
ActiveSupport::Dependencies.
  autoload_paths.
  delete("#{Rails.root}/app/api")
```

オートロードまたはeager loadingするファイルが存在しないサブディレクトリについては注意が必要です。たとえば、[ActiveAdmin](https://activeadmin.info/)で使うリソースを保存する`app/admin`ディレクトリがアプリケーションにある場合、以下のようにそれらのリソースを無視する必要があります。`assets`ディレクトリなどについても同様の注意が必要です。

```ruby
# config/initializers/zeitwerk.rb
Rails.autoloaders.main.ignore(
  "app/admin",
  "app/assets",
  "app/javascripts",
  "app/views"
)
```

上の設定がないと、アプリケーションがこれらのツリーをeager loadingします。読み込まれたファイルは定数を定義しないので、`app/admin`でエラーが発生し、さらに副作用として不要な`View`モジュールも生成されてしまいます。

このように、オートロードのパスに`app`ディレクトリを含めることは一応可能ですが、ややトリッキーになります。

### オートロードした定数と明示的な名前空間

ファイル内で、たとえば以下のように`Hotel`という名前空間が定義されているとします。

```
app/models/hotel.rb         # Hotelを定義する
app/models/hotel/pricing.rb # Hotel::Pricingを定義する
```

この`Hotel`定数は、以下のように`class`または`module`キーワードで設定しなければなりません。

```ruby
class Hotel
end
```

上は問題ありません。

ただし、以下の2つは無効です。

```ruby
Hotel = Class.new
```

または

```ruby
Hotel = Struct.new
```

これらは`Hotel::Pricing`などの子オブジェクトを探索できません。

これらの制約は、明示的な名前空間にのみ適用されます。名前空間を定義しないクラスやモジュールであれば上述の記法でも定義できます。

### 1ファイルにつきトップレベル定数は1個

`classic`モードでは、以下のように同一トップレベルに複数の定数を定義して、それらすべてを再読み込みすることも技術的に可能でした。以下のコード例で考えます。

```ruby
# app/models/foo.rb

class Foo
end

class Bar
end
```

上の`Bar`は本来オートロードできないにもかかわらず、`Foo`をオートロードすると`Bar`もオートロード済みとマーキングされました。

これは`zeitwerk`モードでは利用できません。`Bar`は専用の`bar.rb`ファイルに移動する必要があります。これが「1ファイルにつきトップレベル定数は1個」という規則です。

これが影響するのは、上のコード例のように同一トップレベルに置かれた定数だけです。以下のようなネストしたクラスやモジュールには影響しません。

```ruby
# app/models/foo.rb

class Foo
  class InnerClass
  end
end
```

アプリケーションが`Foo`を再読み込みすると、`Foo::InnerClass`も再読み込みされます。

### `config.autoload_paths`について

以下のようにワイルドカードを含む設定では注意が必要です。

```ruby
config.autoload_paths += Dir["#{config.root}/extras/**/"]
```

`config.autoload_paths`のどの要素もトップレベルの名前空間（`Object`）を表さなければならないので、上の設定は無効です。

これは、以下のようにワイルドカードを削除するだけで修正できます。

```ruby
config.autoload_paths << "#{config.root}/extras"
```

### エンジンからのクラスやモジュールをdecorateする

アプリケーションがエンジンからクラスやモジュールをdecorateしているのであれば、どこかで以下のようなことをやっている可能性があります。

```ruby
config.to_prepare do
  Dir.glob("#{Rails.root}/app/overrides/**/*_override.rb").sort.each do |override|
    require_dependency override
  end
end
```

これは更新しなければなりません。以下のように`main`オートローダーでオーバーライドを含むディレクトリを無視するように指示し、代わりに`load`でそれらを読み込む必要があります。

```ruby
overrides = "#{Rails.root}/app/overrides"
Rails.autoloaders.main.ignore(overrides)
config.to_prepare do
  Dir.glob("#{overrides}/**/*_override.rb").sort.each do |override|
    load override
  end
end
```

### `before_remove_const`

Rails 3.1では`before_remove_const`というコールバックがサポートされ、このメソッドに応答するクラスやモジュールが再読み込みされるときに呼び出されるようになりました。このコールバックはドキュメント化されていないため、おそらくアプリケーションコードで使われていることはないでしょう。

しかしこのコールバックを利用している場合は、以下のように書き換えられます。

```ruby
class Country < ActiveRecord::Base
  def self.before_remove_const
    expire_redis_cache
  end
end
```

上を以下のように書き換えます。

```ruby
# config/initializers/country.rb
unless Rails.application.config.cache_classes
  Rails.autoloaders.main.on_unload("Country") do |klass, _abspath|
    klass.expire_redis_cache
  end
end
```

### spring gemと`test`環境

spring gemは、アプリケーションコードが変更されると再読み込みします。`test`環境でこの再読み込みを有効にするには、以下の設定が必要です。

```ruby
# config/environments/test.rb
config.cache_classes = false
```

そうしないと、以下のエラーが発生します。

```
reloading is disabled because config.cache_classes is true
```

なお、この設定でパフォーマンスは低下しません。

### bootsnap gem

少なくともbootsnap 1.4.4以上に依存する必要があります。

Zeitwerk準拠をテストスイートでチェックする
-------------------------------------------

Zeitwerkに移行するときは、`zeitwerk:check`タスクを使うと便利です。プロジェクトがZeitwerkに準拠したら、このチェックを自動化することをおすすめします。これを行うには、アプリケーションをeager loadingするだけで十分です（実際`zeitwerk:check`が行うのはそれだけです）。

### CI環境の場合

プロジェクトに[CI（Continuous Integration: 継続的インテグレーション）](https://ja.wikipedia.org/wiki/%E7%B6%99%E7%B6%9A%E7%9A%84%E3%82%A4%E3%83%B3%E3%83%86%E3%82%B0%E3%83%AC%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3)環境がある場合は、テストスイートを実行するときにアプリケーションをeager loadingするとよいでしょう。アプリケーションが何らかの理由でeager loadingできなくなっていることにproduction環境で気づくより、CI環境で知りたいものですよね。

CIでは、テストスイートが実行中であることを示すのに何らかの環境変数を設定することがよくあります。環境変数が`CI`の場合は、以下のように指定できます。

```ruby
# config/environments/test.rb
config.eager_load = ENV["CI"].present?
```

Rails 7以降で新規生成したアプリケーションでは、デフォルトで上の設定が有効になります。

### テストスイートを直接実行する場合

プロジェクトにCI環境がない場合は、テストスイートで`Rails.application.eager_load!`を呼ぶことでeager loadingできます。

#### minitestの場合

```ruby
require "test_helper"

class ZeitwerkComplianceTest < ActiveSupport::TestCase
  test "eager loads all files without errors" do
    assert_nothing_raised { Rails.application.eager_load! }
  end
end
```

#### RSpecの場合

```ruby
require "rails_helper"

RSpec.describe "Zeitwerk compliance" do
  it "eager loads all files without errors" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end
```

不要な`require`呼び出しはすべて削除すること
--------------------------

私の経験では、プロジェクトでの`require`呼び出しは一般に不要です。しかし`require`を呼び出しているプロジェクトをいくつか実際に見かけたことがあり、他にもそうした噂をいくつか耳にしています。

Railsアプリケーションでは、`require`は「`lib`のコード」「gemなどのサードパーティ依存関係」「標準ライブラリ」の読み込みにしか使いません。**アプリケーションのオートロード可能なコードは決して`require`しないでください**。この方法がよくない理由については、[Classicモードの解説](https://railsguides.jp/autoloading_and_reloading_constants_classic_mode.html#%E8%87%AA%E5%8B%95%E8%AA%AD%E3%81%BF%E8%BE%BC%E3%81%BF%E3%81%A8require)で説明しました。

```ruby
require "nokogiri" # よい
require "net/http" # よい
require "user"     # 絶対ダメ、削除せよ（app/models/user.rbがある場合）
```

そのような`require`呼び出しはすべて削除してください。

Zeitwerkで利用できる新機能
-----------------------------

### `require_dependency`呼び出しの削除

Zeitwerkによって、`require_dependency`の既知のユースケースはすべて削除されました。プロジェクトをgrepして`require_dependency`をすべて削除してください。

アプリケーションでSTIを利用している場合は、『定数の自動読み込みと再読み込み（Zeitwerk）』ガイドの『[STI（単一テーブル継承）』を参照してください。
](/autoloading_and_reloading_constants.html#sti（単一テーブル継承）)

### クラスやモジュールの定義内で定数名を修飾可能になった

クラスやモジュールの定義で、以下のような定数パスを安定して利用できるようになりました。

```ruby
# このクラスの本体でのオートロードがRubyのセマンティクスと一致するようになった
class Admin::UsersController < ApplicationController
  # ...
end
```

1つ注意すべき点があります。実行順序によってはclassicオートローダーで以下の`Foo::Wadus`をオートロードできてしまう場合がありました。

```ruby
class Foo::Bar
  Wadus
end
```

この`Foo`はネストの中に存在しないので、上はRubyのセマンティクスと一致しません。そのため、これは`zeitwerk`モードではまったく動作しません。このようなエッジケースに遭遇した場合は、以下のように`Foo::Wadus`という修飾名を利用できます。

```ruby
class Foo::Bar
  Foo::Wadus
end
```

あるいは、以下のように`Foo`をネストに追加します。

```ruby
module Foo
  class Bar
    Wadus
  end
end
```

### あらゆる場所でスレッドセーフになる

RailsにはWebリクエストをスレッドセーフにするロックが用意されているにもかかわらず、`classic`モードの定数自動読み込みはスレッドセーフではありませんでした。

`zeitwerk`モードの定数自動読み込みはスレッドセーフです。たとえば、`runner`コマンドで実行されるマルチスレッドのスクリプトをオートロードできるようになりました。

### eager loadingとオートロードが一貫するようになった

`classic`モードでは、`app/models/foo.rb`ファイルで`Bar`が定義されていると、このファイルをオートロードできません。しかし`classic`モードはファイルの読み込みを機械的に再帰するので、このファイルのeager loadingは可能です。テストを最初にeager loadingする形で実行すると、その後オートロードが発生したときに実行が失敗する可能性があります。

`zeitwerk`モードではどちらの読み込みモードも一貫しているので、テストの失敗やエラーは同じファイル内で発生します。
