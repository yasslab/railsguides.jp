
Rails プラグイン作成入門
====================================

Railsのプラグインは、コアフレームワークを拡張したり変更したりするのに使用されます。プラグインは以下の機能を提供します。

* 安定版コードベースに手を加えることなく最先端のアイディアを開発者同士で共有する手段を提供します。
* アーキテクチャを分割し、それらのコード単位ごとに異なるスケジュールで修正や更新を進められるようにします。
* コア開発者が価値ある新機能を実装しても、その全てオープンにすることなく共有できるようにします。

このガイドの内容:

* プラグインをゼロから作成する方法
* プラグイン用のテストの作成方法と実行方法

本ガイドでは、以下を理解することを目的として、プラグインをテスト駆動方式で開発する方法を解説します。

* HashやStringなどのコアRubyクラスを拡張する
* `acts_as`プラグインと同様の手法で`ActiveRecord::Base`にメソッドを追加する
* プラグインのどこにジェネレータを配置すべきかを理解する

ここからは説明上の便宜のため、自分がひとりの熱心なバードウォッチャーであるとお考えください。
あなたは鳥の中でも特に Yaffle (ヨーロッパアオゲラ) が大好きで、この鳥がいかに素晴らしいかを他の開発者と共有するためのプラグインを作成したいと考えています。

--------------------------------------------------------------------------------

設定
-----

以前と異なり、現在Railsのプラグインはgemとしてビルドします。gem形式を取っているので、必要であればRubygemsとBunderを使用してプラグインを他のRailsアプリケーションと共有することもできます。

### gem形式のプラグインを生成する


RailsにはあらゆるRails拡張機能の開発用スケルトンを作成する`rails plugin new`というコマンドが最初から装備されています。これで作成したスケルトンはダミーのRailsアプリケーションを使用して結合テストを実行することもできます。プラグインを作成するには以下のコマンドを実行します。

```bash
$ bin/rails plugin new yaffle
```

使用法とオプションは以下の方法で表示できます。

```bash
$ bin/rails plugin new --help
```

新しく生成したプラグインをテストする
-----------------------------------

プラグインを作成したディレクトリに移動して`bundle install`コマンドを実行し、自動生成されたテストを`rake`コマンドで実行します。

実行結果は以下のようになります。

```bash
  1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

生成が無事完了し、いつでも機能を追加できる状態であることがわかります。

コアクラスを拡張する
----------------------

このセクションでは、Railsアプリケーションのどこでも利用できるメソッドをStringクラスに追加する方法を解説します。

この例では、`to_squawk`(ガーガー鳴くの意)という名前のメソッドをStringクラスに追加します。最初に、テストファイルをひとつ作成してそこにアサーションをいくつか追加しましょう。

  ```ruby
# yaffle/test/core_ext_test.rb

require 'test_helper'

class CoreExtTest < ActiveSupport::TestCase
  def test_to_squawk_prepends_the_word_squawk
    assert_equal "squawk! Hello World", "Hello World".to_squawk
  end
end
```

`rake`を実行してテストします。`to_squawk`は実装されていないので、当然テストは失敗します。

```bash
    1) Error:
  CoreExtTest#test_to_squawk_prepends_the_word_squawk:
  NoMethodError: undefined method `to_squawk' for "Hello World":String
    /path/to/yaffle/test/core_ext_test.rb:5:in `test_to_squawk_prepends_the_word_squawk'
```

ここまで準備できれば、いよいよコーディング開始です。

`lib/yaffle.rb`に`require 'yaffle/core_ext'`を追加します。

```ruby
# yaffle/lib/yaffle.rb

require 'yaffle/core_ext'

module Yaffle
end
```

最後に`core_ext.rb`ファイルを作成して`to_squawk`メソッドを追加します。

```ruby
# yaffle/lib/yaffle/core_ext.rb

String.class_eval do
  def to_squawk
    "squawk! #{self}".strip
  end
end
```

プラグインのあるディレクトリで`rake`テストを実行して、メソッドがテストにパスすることを確認します。

```bash
  2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

最後にメソッドを実際に使ってみましょう。test/dummyディレクトリに移動してガーガー鳴いてみましょう(squawk)。

```bash
$ bin/rails console
>> "Hello World".to_squawk
=> "squawk! Hello World"
```

"acts_as"メソッドをActive Recordに追加する
----------------------------------------

プラグインでは、`acts_as_何とか`という名前のメソッドをモデルに追加することがよく行われます。この例ではそれにならって`acts_as_yaffle`というメソッドを追加してみます。これは`squawk`メソッドを自分のActive Recordモデルに追加するメソッドです。

最初に以下のファイルを準備します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require 'test_helper'

class ActsAsYaffleTest < ActiveSupport::TestCase
end
```

```ruby
# yaffle/lib/yaffle.rb

require 'yaffle/core_ext'
require 'yaffle/acts_as_yaffle'

module Yaffle
end
```

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    # ここにコードを書く
  end
end
```

### クラスメソッドを追加する

このプラグインはモデルに`last_squawk`という名前のメソッドが追加されていることを前提にしています。しかし、プラグインがインストールされた環境には、そのモデルに目的の異なる`last_squawk`という名前のメソッドが既にあるかもしれません。そこで、このプラグインでは`yaffle_text_field`という名前のクラスメソッドをひとつ追加することによって名前を変更できるようにしたいと思います。

最初に、以下のように振る舞う、失敗するテストをひとつ作成します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require 'test_helper'

class ActsAsYaffleTest < ActiveSupport::TestCase

  def test_a_hickwalls_yaffle_text_field_should_be_last_squawk
    assert_equal "last_squawk", Hickwall.yaffle_text_field
  end

  def test_a_wickwalls_yaffle_text_field_should_be_last_tweet
    assert_equal "last_tweet", Wickwall.yaffle_text_field
  end

end
```

`rake`を実行すると以下が出力されます。

```
    1) Error:
  ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
  NameError: uninitialized constant ActsAsYaffleTest::Hickwall
    /path/to/yaffle/test/acts_as_yaffle_test.rb:6:in `test_a_hickwalls_yaffle_text_field_should_be_last_squawk'

    2) Error:
  ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
  NameError: uninitialized constant ActsAsYaffleTest::Wickwall
    /path/to/yaffle/test/acts_as_yaffle_test.rb:10:in `test_a_wickwalls_yaffle_text_field_should_be_last_tweet'

  4 runs, 2 assertions, 0 failures, 2 errors, 0 skips
```

この結果から、テストの対象となるモデル (Hickwall and Wickwall) がそもそもないことがわかります。必要なモデルはダミーのRailsアプリケーションで簡単に作成できます。test/dummyディレクトリに移動して以下のコマンドを実行します。

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

class Hickwall < ActiveRecord::Base
  acts_as_yaffle
end

# test/dummy/app/models/wickwall.rb

class Wickwall < ActiveRecord::Base
  acts_as_yaffle yaffle_text_field: :last_tweet
end

```

`acts_as_yaffle`メソッドを定義するコードも追加します。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb
module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        # ここにコードを書く
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

終わったら`cd ../..`を実行してプラグインのルートディレクトリに戻り、`rake`を実行してテストを再実行します。

```
    1) Error:
  ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
  NoMethodError: undefined method `yaffle_text_field' for #<Class:0x007fd105e3b218>
    activerecord (4.1.5) lib/active_record/dynamic_matchers.rb:26:in `method_missing'
    /path/to/yaffle/test/acts_as_yaffle_test.rb:6:in `test_a_hickwalls_yaffle_text_field_should_be_last_squawk'

    2) Error:
  ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
  NoMethodError: undefined method `yaffle_text_field' for #<Class:0x007fd105e409c0>
    activerecord (4.1.5) lib/active_record/dynamic_matchers.rb:26:in `method_missing'
    /path/to/yaffle/test/acts_as_yaffle_test.rb:10:in `test_a_wickwalls_yaffle_text_field_should_be_last_tweet'

  4 runs, 2 assertions, 0 failures, 2 errors, 0 skips

```

開発がだいぶ進んできました。今度は`acts_as_yaffle`メソッドを実装し、テストがパスするようにしましょう。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
   extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field
        self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

`rake`を実行すると、今度のテストはすべてパスします。

```bash
  4 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

### インスタンスメソッドを追加する

今度はこのプラグインに'squawk'というメソッドを追加して、'acts_as_yaffle'を呼び出すすべてのActive Recordオブジェクトに追加しましょう'squawk'メソッドはデータベースのフィールドにある値のいずれかひとつを設定するだけのシンプルなものです。

最初に、以下のように振る舞う、失敗するテストをひとつ作成します。

```ruby
# yaffle/test/acts_as_yaffle_test.rb
require 'test_helper'

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

テストを実行して、最後に追加した2つのテストが失敗することを確認します。失敗のメッセージには"NoMethodError: undefined method `squawk'"が含まれているので、'acts_as_yaffle.rb'を以下のように更新します。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field
        self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s

        include Yaffle::ActsAsYaffle::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def squawk(string)
        write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

最後に`rake`を実行すると以下の結果が表示されます。

```
  6 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

NOTE: 上のコードでは`write_attribute`を使用してモデルのフィールドへの書き出しを行っていますが、これはあくまでプラグインからモデルとやりとりする際の書き方を示すための一例にすぎません。この書き方が適切とは限らないこともあるのでご注意ください。たとえば同じコードを以下のように書くこともできます。

```ruby
send("#{self.class.yaffle_text_field}=", string.to_squawk)
```

ジェネレータ
----------

gemにジェネレータを含めるには、単にジェネレータを作成してプラグインのlib/generatorsディレクトリに置くだけでもかまいません。ジェネレータの作成方法の詳細については[Rails ジェネレータとテンプレート入門](generators.html)を参照してください。

gemを公開する
-------------------

開発中のgemであってもGitリポジトリで簡単に共有できます。今回のYaffle gemを他の開発者と共有するには、コードをGithubなどのGitリポジトリにコミットしておき、gemを使用したいアプリケーションのGemfileに一行書くだけで済みます。

```ruby
gem 'yaffle', git: 'git://github.com/yaffle_watcher/yaffle.git'
```

後は`bundle install`を実行すればgemの機能をアプリケーションで利用できるようになります。

gemを正式なリリースとして一般公開するのであれば[RubyGems](http://www.rubygems.org)でパブリッシュします。
RubyGemsサイトでgemを公開する方法の詳細については、[はじめてのRuby Gem作成・パブリッシュ方法](http://blog.thepete.net/2010/11/creating-and-publishing-your-first-ruby.html)(英語) を参照してください。

RDocドキュメント
------------------

プラグインの開発が一段落してデプロイする段階になったら、プラグインの利用者のためにちゃんとしたドキュメントを作成しましょう。幸い、プラグインのドキュメント作成は簡単です。

最初に、プラグインの使用法をREADMEファイルに詳しく記載します。以下の項目は忘れずに記入してください。

* 自分の名前
* インストール方法
* アプリケーションに機能を追加する具体的な方法 (一般的なユースケースもいくつか例として追加)
* 警告、注意点、ヒントなど (ユーザーが無駄な時間を使わずに済むように)

READMEの内容が固まってきたら、コードをひととおりチェックしてすべてのメソッドにrdoc形式のコメントを追加します。このコメントは開発者にとって役立つ情報となります。パブリックAPIにしたくない箇所には'#:nodoc:'というコメントを追加します。

コメントを付け終わったらプラグインのルートディレクトリに移動して以下を実行します。

```bash
$ bin/rails rdoc
```

### 参考資料

* [Bundlerを使用してRubyGemを開発する](https://github.com/radar/guides/blob/master/gem-development.md)(英語)
* [gemspecsを意図したとおりに使う](http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/)(英語)
* [Gemspecリファレンス](http://guides.rubygems.org/specification-reference/)(英語)
* [GemPlugin: Railsプラグインの今後の見通し](http://www.intridea.com/blog/2008/6/11/gemplugins-a-brief-introduction-to-the-future-of-rails-plugins)(英語)