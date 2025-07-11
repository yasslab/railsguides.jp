Rails プラグイン作成入門
====================================

Railsのプラグインは、コアフレームワークの拡張や変更に使われます。プラグインは以下の機能を提供します。

* 安定版コードベースを変更せずに、最先端のアイデアを共有できます。
* アーキテクチャを分割して、修正や更新を異なるスケジュールで進められます。
* コア開発者が新機能の一部のみを共有するのに使えます。

このガイドの内容:

* プラグインをゼロから作成する方法
* プラグイン用のテストの作成方法と実行方法

本ガイドでは以下を理解するために、テスト駆動方式によるプラグイン開発方法を解説します。

* HashやStringなどのコアRubyクラスを拡張する
* `acts_as`プラグインと同様の手法で`ApplicationRecord`にメソッドを追加する
* ジェネレータをプラグインのどこに配置するかを理解する

ここからは説明上、自分のことを熱烈なバードウォッチャーであるとお考えください。
あなたは鳥の中でも特に Yaffle（ヨーロッパアオゲラ）が大好きで、この鳥の素晴らしさを他の開発者と共有するプラグインを作成したいと考えています。

--------------------------------------------------------------------------------


設定
-----

Railsのプラグインは**gem化**されています。gem形式を採用したことで、必要に応じてプラグインをRubygemsとBundlerでさまざまなRailsアプリケーションと共有することも可能です。

### gem形式のプラグインを生成する

RailsにはあらゆるRails拡張機能の開発用スケルトンを作成する`rails plugin new`というコマンドが用意されています。これで作成したスケルトンはダミーのRailsアプリケーションを使用して結合テストを実行することもできます。プラグインを作成するには以下のコマンドを実行します。

```bash
$ rails plugin new yaffle
```

利用法とオプションは以下の方法で表示できます。

```bash
$ rails plugin new --help
```

新しく生成したプラグインをテストする
-----------------------------------

プラグインを作成したディレクトリに移動して`yaffle.gemspec`ファイルを編集し、値に`TODO`がある行をすべて以下の要領で置き換えます。

```ruby
spec.homepage    = "http://example.com"
spec.summary     = "（Yaffleの概要）"
spec.description = "（Yaffleの説明）"

...

spec.metadata["source_code_uri"] = "http://example.com"
spec.metadata["changelog_uri"] = "http://example.com"
```

終わったら`bundle install`コマンドを実行します。

これで、自動生成されたテストを`bin/test`コマンドで実行すると以下のような結果が出力されるはずです。

```bash
$ bin/test
...
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

生成が無事完了し、いつでも機能を追加できる状態であることがわかります。

コアクラスを拡張する
----------------------

このセクションでは、Railsアプリケーションのどこでも利用できるメソッドをStringクラスに追加する方法を解説します。

この例では、`to_squawk`（ガーガー鳴くの意）という名前のメソッドをStringクラスに追加します。最初に、テストファイルを1つ作成してそこにアサーションをいくつか追加しましょう。

```ruby
# yaffle/test/core_ext_test.rb

require "test_helper"

class CoreExtTest < ActiveSupport::TestCase
  def test_to_squawk_prepends_the_word_squawk
    assert_equal "squawk! Hello World", "Hello World".to_squawk
  end
end
```

`bin/test`を実行してテストします。`to_squawk`は実装されていないので、当然テストは失敗します。

```bash
$ bin/test
E

Error:
CoreExtTest#test_to_squawk_prepends_the_word_squawk:
NoMethodError: undefined method `to_squawk' for "Hello World":String


bin/test /path/to/yaffle/test/core_ext_test.rb:4

.

Finished in 0.003358s, 595.6483 runs/s, 297.8242 assertions/s.
2 runs, 1 assertions, 0 failures, 1 errors, 0 skips
```

ここまで準備できれば、いよいよコーディング開始です。

`lib/yaffle.rb`に`require "yaffle/core_ext"`を追加します。

```ruby
# yaffle/lib/yaffle.rb

require "yaffle/version"
require "yaffle/railtie"
require "yaffle/core_ext"

module Yaffle
  # ここにコードを書く
end
```

最後に`core_ext.rb`ファイルを作成して`to_squawk`メソッドを追加します。

```ruby
# yaffle/lib/yaffle/core_ext.rb

class String
  def to_squawk
    "squawk! #{self}".strip
  end
end
```

プラグインのあるディレクトリで`bin/test`テストを実行して、メソッドがテストにパスすることを確認します。

```bash
$ bin/test
...
2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

最後にメソッドを実際に使ってみましょう。`test/dummy`ディレクトリに移動して`bin/rails console`を実行し、鳴き声（squawk）を出してみましょう。

```irb
irb> "Hello World".to_squawk
=> "squawk! Hello World"
```

"acts_as"メソッドをActive Recordに追加する
----------------------------------------

プラグインでは、`acts_as_何とか`という名前のメソッドをモデルに追加することがよく行われます。この例ではそれにならって`acts_as_yaffle`というメソッドを追加してみます。これは`squawk`メソッドを自分のActive Recordモデルに追加するメソッドです。

最初に以下のファイルを準備します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require "test_helper"

class ActsAsYaffleTest < ActiveSupport::TestCase
end
```

```ruby
# yaffle/lib/yaffle.rb

require "yaffle/version"
require "yaffle/railtie"
require "yaffle/core_ext"
require "yaffle/acts_as_yaffle"

module Yaffle
  # ここにコードを書く
end
```

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
  end
end
```

### クラスメソッドを追加する

このプラグインはモデルに`last_squawk`という名前のメソッドが追加されていることを前提にしています。しかし、プラグインがインストールされた環境には、そのモデルに目的の異なる`last_squawk`という名前のメソッドが既にあるかもしれません。そこで、このプラグインでは`yaffle_text_field`という名前のクラスメソッドを1つ追加することによって名前を変更できるようにしたいと思います。

最初に、以下のように振る舞う、失敗するテストを1つ作成します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require "test_helper"

class ActsAsYaffleTest < ActiveSupport::TestCase
  def test_a_hickwalls_yaffle_text_field_should_be_last_squawk
    assert_equal "last_squawk", Hickwall.yaffle_text_field
  end

  def test_a_wickwalls_yaffle_text_field_should_be_last_tweet
    assert_equal "last_tweet", Wickwall.yaffle_text_field
  end
end
```

`bin/test`を実行すると以下が出力されます。

```bash
$ bin/test
# Running:

..E

Error:
ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
NameError: uninitialized constant ActsAsYaffleTest::Wickwall


bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:8

E

Error:
ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
NameError: uninitialized constant ActsAsYaffleTest::Hickwall


bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:4



Finished in 0.004812s, 831.2949 runs/s, 415.6475 assertions/s.
4 runs, 2 assertions, 0 failures, 2 errors, 0 skips
```

この結果から、そもそもテストで必要なモデル（HickwallとWickwall）がないことがわかります。必要なモデルはダミーのRailsアプリケーションで簡単に作成できます。`test/dummy`ディレクトリに移動して以下のコマンドを実行します。

```bash
$ cd test/dummy
$ bin/rails generate model Hickwall last_squawk:string
$ bin/rails generate model Wickwall last_squawk:string last_tweet:string
```

これで必要なデータベーステーブルをテストデータベース内に作成するための準備が整いました。作成は、ダミーアプリケーションのディレクトリに移動してデータベースのマイグレーションを実行することで行います。最初に以下を実行します。

```bash
$ cd test/dummy
$ bin/rails db:migrate
```

続いて、このディレクトリでHickwallモデルとWickwallモデルを変更し、これらのモデルにyafflesとしての振る舞いが期待されていることが伝わるようにします。

```ruby
# test/dummy/app/models/hickwall.rb

class Hickwall < ApplicationRecord
  acts_as_yaffle
end
```

```ruby
# test/dummy/app/models/wickwall.rb

class Wickwall < ApplicationRecord
  acts_as_yaffle yaffle_text_field: :last_tweet
end
```

`acts_as_yaffle`メソッドを定義するコードも追加します。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_yaffle(options = {})
      end
    end
  end
end
```

```ruby
# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

終わったら`cd ../..`を実行してプラグインのルートディレクトリに戻り、`bin/test`を実行してテストを再実行します。

```bash
$ bin/test
# Running:

.E

Error:
ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
NoMethodError: undefined method `yaffle_text_field' for #<Class:0x0055974ebbe9d8>


bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:4

E

Error:
ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
NoMethodError: undefined method `yaffle_text_field' for #<Class:0x0055974eb8cfc8>


bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:8

.

Finished in 0.008263s, 484.0999 runs/s, 242.0500 assertions/s.
4 runs, 2 assertions, 0 failures, 2 errors, 0 skips
```

開発がだいぶ進んできました。今度は`acts_as_yaffle`メソッドを実装し、テストがパスするようにしましょう。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field, default: (options[:yaffle_text_field] || :last_squawk).to_s
      end
    end
  end
end
```

```ruby
# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

`bin/test`を実行すると、今度のテストはすべてパスします。

```bash
$ bin/test
...
4 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

### インスタンスメソッドを追加する

今度はこのプラグインに'squawk'というメソッドを追加して、`acts_as_yaffle`を呼び出すすべてのActive Recordオブジェクトに追加しましょう。'squawk'メソッドはデータベースのフィールドにある値のいずれか1つを設定するだけのシンプルなものです。

最初に、以下のように振る舞う、失敗するテストを1つ作成します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb
require "test_helper"

class ActsAsYaffleTest < ActiveSupport::TestCase
  def test_a_hickwalls_yaffle_text_field_should_be_last_squawk
    assert_equal "last_squawk", Hickwall.yaffle_text_field
  end

  def test_a_wickwalls_yaffle_text_field_should_be_last_tweet
    assert_equal "last_tweet", Wickwall.yaffle_text_field
  end

  def test_hickwalls_squawk_should_populate_last_squawk
    hickwall = Hickwall.new
    hickwall.squawk("Hello World")
    assert_equal "squawk! Hello World", hickwall.last_squawk
  end

  def test_wickwalls_squawk_should_populate_last_tweet
    wickwall = Wickwall.new
    wickwall.squawk("Hello World")
    assert_equal "squawk! Hello World", wickwall.last_tweet
  end
end
```

テストを実行して、最後に追加した2つのテストが失敗することを確認します。失敗のメッセージには"NoMethodError: undefined method \`squawk'"が含まれているので、`acts_as_yaffle.rb`を以下のように更新します。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    included do
      def squawk(string)
        write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end
    end

    class_methods do
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field, default: (options[:yaffle_text_field] || :last_squawk).to_s
      end
    end
  end
end
```

```ruby
# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

最後に`bin/test`を実行すると以下の結果が表示されます。

```bash
$ bin/test
...
6 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

NOTE: 上のコードではモデルのフィールドへの書き込みを`write_attribute`で行っていますが、これはあくまでプラグインからモデルとやりとりする際の書き方を示すための一例にすぎません。このメソッドを使うのが適切とは限らないこともあるのでご注意ください。たとえば同じコードを以下のように書くこともできます。

```ruby
send("#{self.class.yaffle_text_field}=", string.to_squawk)
```

ジェネレータ
----------

gemにジェネレータを追加するには、単にジェネレータを作成してプラグインの`lib/generators`ディレクトリに置くだけでもかまいません。ジェネレータの作成方法について詳しくは[Rails ジェネレータとテンプレート入門](generators.html)を参照してください。

gemを公開する
-------------------

開発中のgemでもGitリポジトリで簡単に共有できます。今回のYaffle gemを他の開発者と共有するには、コードをGitHubなどのGitリポジトリにコミットしておき、gemを使いたいアプリケーションの`Gemfile`に一行書くだけでできます。

```ruby
gem "yaffle", git: "https://github.com/rails/yaffle.git"
```

後は`bundle install`を実行すればgemの機能をアプリケーションで利用できるようになります。

gemを正式なリリースとして一般公開するのであれば[RubyGems](https://www.rubygems.org)で公開します。

あるいは、Bundlerのrakeタスクも便利に使えます。以下に完全なリストを示します。

```bash
$ bundle exec rake -T

$ bundle exec rake build
# yaffle-0.1.0.gemをビルドしてpkgディレクトリに置く

$ bundle exec rake install
# yaffle-0.1.0.gemをビルドしてsystem gemとしてインストールする

$ bundle exec rake release
# tagをv0.1.0に設定してyaffle-0.1.0.gemをRubygemsにプッシュする
```

RubyGemsサイトでgemを公開する方法について詳しくは、[はじめてのRuby Gem作成・パブリッシュ方法](http://guides.rubygems.org/publishing)（英語）を参照してください。

RDocドキュメント
------------------

プラグインの開発が終わってデプロイする段階になったら、プラグインの利用者のためにちゃんとしたドキュメントを作成しましょう。幸い、プラグインのドキュメント作成は簡単です。

最初に、プラグインの使い方をREADMEファイルに詳しく記載します。以下の項目は忘れずに記入してください。

* 自分の名前
* インストール方法
* アプリケーションに機能を追加する具体的な方法（一般的なユースケースもいくつか例として追加）
* 警告、注意点、ヒントなど（ユーザーが無駄な時間を使わずに済むように）

READMEの内容が固まってきたら、コードをひととおりチェックしてすべてのメソッドにRDoc形式のコメントを追加します。このコメントは開発者にとって役立つ情報となります。パブリックAPIにしたくないメソッドには`# :nodoc:`というコメントを追加します。

コメントを付け終わったらプラグインのルートディレクトリに移動して以下を実行します。

```bash
$ bundle exec rake rdoc
```

### 参考資料

* [Bundlerを使ってRubyGemを開発する](https://bundler.io/guides/creating_gem.html)（英語）
* [gemspecsを意図したとおりに使う](http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/)（英語）
* [Gemspecリファレンス](https://guides.rubygems.org/specification-reference/)（英語）
