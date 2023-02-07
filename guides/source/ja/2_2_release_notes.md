**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Ruby on Rails 2.2 リリースノート
===============================

Rails 2.2には多くの新機能と機能改善が盛り込まれています。このリストは主要なアップグレードをカバーしていますが、小さなバグフィックスや変更までは含まれていません。すべての変更を見るには、GitHubのRailsメインリポジトリの[コミットリスト](https://github.com/rails/rails/commits/2-2-stable)を参照してください。

Rails 2.2のリリースに伴い、現在進行中の[Rails Guides hackfest](https://rubyonrails.org/2008/9/4/guides-hackfest)の最初の成果である[Rails Guides](https://guides.rubyonrails.org/)が発表されました。[Rails Guides](https://guides.rubyonrails.org/)では、Railsの主要な機能に関する高品質なドキュメントを提供する予定です。

--------------------------------------------------------------------------------

インフラストラクチャ
--------------

Rails 2.2は、Railsを安定稼働させ、世界とつなぐインフラストラクチャとして重要なリリースです。

### 国際化

Rails 2.2では、国際化 (internationalization: 長いのでi18nと略されます) 向けの簡単なシステムが提供されます。

* リードコントリビュータ: Rails i18チーム
* 詳細:
    * [Official Rails i18 website](http://rails-i18n.org)
    * [Finally. Ruby on Rails gets internationalized](https://web.archive.org/web/20140407075019/http://www.artweb-design.de/2008/7/18/finally-ruby-on-rails-gets-internationalized)
    * [Localizing Rails : Demo application](https://github.com/clemens/i18n_demo_app)

### Ruby 1.9およびJRubyとの互換性

RailsがJRubyや次期Ruby 1.9とスレッド安全性に関してうまく動作するよう、多くの作業が行われました。Ruby 1.9のリリースはまだ先なので、Ruby 1.9でRailsを動かすのはまだ難しい状態ですが、Ruby 1.9がリリースされたときにRailsが移行する準備は整っています。

ドキュメント
-------------

コードコメント形式のRails内部ドキュメントが随所で改善されました。また、[Railsガイド](https://railsguides.jp/)プロジェクトは、Railsの主要なコンポーネントに関する決定的な情報源です。最初の公式リリースにはRailsガイドの以下のページが含まれています。

* [Rails をはじめよう](getting_started.html)
* [Active Record マイグレーション](active_record_migrations.html)
* [Active Record の関連付け](association_basics.html)
* [Active Record クエリインターフェイス](active_record_querying.html)
* [レイアウトとレンダリング](layouts_and_rendering.html)
* [Action View フォームヘルパー](form_helpers.html)
* [Rails のルーティング](routing.html)
* [Action Controller の概要](action_controller_overview.html)
* [Rails のキャッシュ機構](caching_with_rails.html)
* [Rails テスティングガイド](testing.html)
* [Rails セキュリティガイド](security.html)
* [Rails アプリケーションのデバッグ](debugging_rails_applications.html)
* [Rails プラグイン作成入門](plugins.html)

このガイドには、初級および中級Rails開発者向けの数万語におよぶガイドが用意されています。

ガイドをローカルで生成したい場合は、アプリケーションのディレクトリで以下を実行します。


```bash
$ rake doc:guides
```

これでガイドが `Rails.root/doc/guides` 以下に生成され、ブラウザで `Rails.root/doc/guides/index.html` を開けばすぐに内容を表示できます。

* 主なコントリビュータ: [Xavier Noria](http://advogato.org/person/fxn/diary.html)および[Hongli Lai](http://izumi.plan99.net/blog/)
* 詳細:
    * [Rails Guides hackfest](http://hackfest.rubyonrails.org/guide)
    * [Help improve Rails documentation on Git branch](https://weblog.rubyonrails.org/2008/5/2/help-improve-rails-documentation-on-git-branch)

HTTPとの統合を改善: すぐ利用できるETagサポート
----------------------------------------------------------

HTTPヘッダでETagと最終更新タイムスタンプをサポートしたことで、最近更新されていないリソースへのリクエストをRailsが受け取ったときに空のレスポンスを返せるようになりました。これにより、レスポンスの送信が不要かどうかを確認できます。

```ruby
class ArticlesController < ApplicationController
  def show_with_respond_to_block
    @article = Article.find(params[:id])

    # リクエストで送信するヘッダがstale?に提供されたオプションと異なる場合、
    # リクエストは実際にstaleし、respond_toブロックが起動する
    # (このときstale?呼び出しのオプションがレスポンスにセットされる）。
    # リクエストヘッダがマッチする場合リクエストはフレッシュなので respond_toブロックはトリガーされない。
    # 代わりにデフォルトのレンダリングが発生してlast-modified と etag ヘッダーをチェックし、
    # テンプレートをレンダリングする代わりに "304 Not Modified" だけを送信すればよいと判断する。
    if stale?(:last_modified => @article.published_at.utc, :etag => @article)
      respond_to do |wants|
        # normal response processing
      end
    end
  end

  def show_with_implied_render
    @article = Article.find(params[:id])

    # レスポンスヘッダを設定し、リクエストに対してそれらをチェックする。
    # リクエストがstaleの場合（すなわち etag または last-modified のいずれもマッチしない場合)、
    # デフォルトのテンプレートレンダリングが行われる。
    # リクエストがフレッシュな場合、デフォルトレンダリングはテンプレートをレンダリングする代わりに
    # "304 Not Modified "を返す。
    fresh_when(:last_modified => @article.published_at.utc, :etag => @article)
  end
end
```

スレッド安全性
-------------

Railsをスレッドセーフにするために行われた作業がRails 2.2に反映されています。Webサーバのインフラにもよりますが、これはメモリ内のRailsのコピー数が少なくても、より多くのリクエストを処理できることを意味し、サーバのパフォーマンス向上とマルチコアの利用率向上につながります。

アプリケーションのproductionモードでマルチスレッドディスパッチを有効にするには、 `config/environments/production.rb` に以下の行を追加してください。


```ruby
config.threadsafe!
```

* 詳細:
    * [Thread safety for your Rails](http://m.onkey.org/2008/10/23/thread-safety-for-your-rails)
    * [Thread safety project announcement](https://weblog.rubyonrails.org/2008/8/16/josh-peek-officially-joins-the-rails-core)
    * [Q/A: What Thread-safe Rails Means](http://blog.headius.com/2008/08/qa-what-thread-safe-rails-means.html)

Active Record
-------------


ここでは、「トランザクショナルマイグレーション」と「プールされたデータベーストランザクション」という、2つの大きな追加機能について説明します。また、joinテーブル条件向けの新しい（そしてよりきれいな）構文の導入や、多くの小さな改良も行われました。

### トランザクショナルマイグレーション

歴史的に、ステップを複数含むRailsマイグレーションはトラブルの元でした。マイグレーション中に何か問題が発生すると、エラー発生前のマイグレーションはデータベースを変更しますが、エラー発生後のマイグレーションは適用されません。また、マイグレーションのバージョンは実行済みとして保存されていたので、問題を解決した後に `rake db:migrate:redo` で単純に再実行できませんでした。トランザクショナルマイグレーションは、マイグレーションステップをDDLトランザクションでラップすることでこれを変更し、どれかが失敗したらマイグレーション全体を元に戻すようにします。Rails 2.2では、トランザクショナルマイグレーションは、PostgreSQLですぐにサポートされます。将来このコードは他のデータベースにも拡張可能で、IBMはすでにDB2アダプタをサポートするよう拡張しています。

* リードコントリビュータ: [Adam Wiggins](http://about.adamwiggins.com/)
* 詳細:
    * [DDL Transactions](http://adam.heroku.com/past/2008/9/3/ddl_transactions/)
    * [A major milestone for DB2 on Rails](http://db2onrails.com/2008/11/08/a-major-milestone-for-db2-on-rails/)

### コネクションプール

コネクションプーリングは、Railsがデータベース接続のプールにデータベースリクエストを分散させ、最大サイズまで成長させられます（デフォルトでは5ですが、 `database.yml` に `pool` キーを追加すれば調整できます）。これは、同時に多数のユーザーをサポートするアプリケーションのボトルネックを解消するのに役立ちます。また、 `wait_timeout` も用意されており、デフォルトでは 5 秒で終了します。`ActiveRecord::Base.connection_pool` は、必要に応じてプールに直接アクセスできます。


```yaml
development:
  adapter: mysql
  username: root
  database: sample_development
  pool: 10
  wait_timeout: 10
```

* リードコントリビュータ: [Nick Sieger](http://blog.nicksieger.com/)
* 詳細:
    * [What's New in Edge Rails: Connection Pools](http://archives.ryandaigle.com/articles/2008/9/7/what-s-new-in-edge-rails-connection-pools)

### joinテーブル条件でハッシュを利用可能に

joinテーブル条件をハッシュで指定できるようになりました。これは、複雑なjoinをまたいでクエリを実行する必要がある場合に非常に有用です。

```ruby
class Photo < ActiveRecord::Base
  belongs_to :product
end

class Product < ActiveRecord::Base
  has_many :photos
end

# 著作権フリーのproductをすべて取得する
Product.all(:joins => :photos, :conditions => { :photos => { :copyright => false }})
```

* 詳細:
    * [What's New in Edge Rails: Easy Join Table Conditions](http://archives.ryandaigle.com/articles/2008/7/7/what-s-new-in-edge-rails-easy-join-table-conditions)

### 新しい動的finderメソッド

Active Recordの動的finderファミリーに、新たに2つのメソッドが追加されました。

#### `find_last_by_attribute`

`find_last_by_attribute`メソッドは、`Model.last(:conditions => {:attribute => value})`と同等です。

```ruby
# ロンドンからサインアップした直近のユーザーを取得する
User.find_last_by_city('London')
```

* リードコントリビュータ: [Emilio Tagua](http://www.workingwithrails.com/person/9147-emilio-tagua)

#### `find_by_attribute!`

`!`付きの新しい`find_by_attribute!` は、`Model.first(:conditions => {:attribute => value}) || raise ActiveRecord::RecordNotFound` と同等です。マッチするレコードが見つからない場合は、`nil` を返す代わりに例外を発生します。

```ruby
# 'Moby'がサインアップしていなければActiveRecord::RecordNotFound例外を発生する
User.find_by_name!('Moby')
```

* リードコントリビュータ: [Josh Susser](http://blog.hasmanythrough.com)

### 関連付けがprivateやprotectedスコープを尊重するようになった

Active Recordの関連付けプロキシは、プロキシされたオブジェクトのメソッドのスコープを尊重するようになりました。以前の`@user.account.private_method` は、関連付けられた Account オブジェクトのprivateメソッドを呼び出していました(`User has_one :account`の場合)。この機能が必要な場合は、 `@user.account.send(:private_method)` をお使いください (または、メソッドを private や protected ではなく public にしてください)。 `method_missing` をオーバーライドしている場合は、関連付けが正常に機能するように `respond_to` も同じ挙動になるようにオーバーライドする必要がある点にご注意ください。

* リードコントリビュータ: Adam Milligan
* 詳細:
    * [Rails 2.2 Change: Private Methods on Association Proxies are Private](http://afreshcup.com/2008/10/24/rails-22-change-private-methods-on-association-proxies-are-private/)

### その他のActive Recordの変更

* `rake db:migrate:redo` にオプションで VERSION を追加して、特定のマイグレーションを redo に指定できるようになりました。
* UTC タイムスタンプの代わりに数値のプレフィックスを持つ移行を行うには `config.active_record.timestamped_migrations = false` と設定してください。
* カウンタキャッシュのカラム（`:counter_cache => true` で宣言された関連付け）をゼロに初期化する必要がなくなりました。
* `ActiveRecord::Base.human_name` により、国際化に対応したモデル名を人間に読みやすく翻訳できるようになりました。

Action Controller
-----------------

コントローラ側では、ルーティングを整理するのに役立ついくつかの変更があります。また、複雑なアプリケーションのメモリ使用量を減らすために、ルーティングエンジンの内部にもいくつかの変更が加えられています。

### ルーティングの浅いネスト

ルーティングの「浅いネスト」は、ネストの深いリソースを使うときのよく知られた問題に対するソリューションを提供します。浅いネストでは、作業したいリソースを一意に識別するのに十分な情報だけを提供すれば済むようになりました。

```ruby
map.resources :publishers, :shallow => true do |publisher|
  publisher.resources :magazines do |magazine|
    magazine.resources :photos
  end
end
```

これで、以下のルーティングが認識されるようになります。

```
/publishers/1           ==> publisher_path(1)
/publishers/1/magazines ==> publisher_magazines_path(1)
/magazines/2            ==> magazine_path(2)
/magazines/2/photos     ==> magazines_photos_path(2)
/photos/3               ==> photo_path(3)
```

* リードコントリビュータ: [S. Brent Faulkner](http://www.unwwwired.net/)
* 詳細:
    * [Rails のルーティング](routing.html#ネストしたリソース)
    * [What's New in Edge Rails: Shallow Routes](http://archives.ryandaigle.com/articles/2008/9/7/what-s-new-in-edge-rails-shallow-routes)

### Method Arrays for Member or Collection Routes

新しいmemberルーティングやcollectionルーティングに対して、メソッドの配列を指定できるようになりました。これにより、複数のHTTP verbを処理する必要があるときに、任意のverbを受け取るようにルーティングを定義しなければならないという煩わしさから解放されます。以下はRails 2.2で有効なルート宣言です。

```ruby
map.resources :photos, :collection => { :search => [:get, :post] }
```

* リードコントリビュータ: [Brennan Dunn](http://brennandunn.com/)

### 特定のアクションを持つresources

デフォルトでは、`map.resources`を使ってルートを作成すると、Railsは7つのデフォルトアクション（index, show, create, new, edit, update, and destroy）に対するルーティングを生成します。しかし、これらのルーティングはそれぞれアプリケーションのメモリを消費し、Railsが追加のルーティングロジックを生成することになります。そこで、`:only` と `:except` オプションを使って、Railsがリソースに対して生成するルートを細かく設定できるようになりました。単一のアクション、アクションの配列、または特殊オプション `:all` や `:none` を指定できます。これらのオプションは、ネストしたリソースに継承されます。

```ruby
map.resources :photos, :only => [:index, :show]
map.resources :products, :except => :destroy
```

* リードコントリビュータ: [Tom Stuart](http://experthuman.com/)

### その他のAction Controllerの変更

* リクエストのルーティング中に発生した例外で、[カスタムエラーページを簡単に表示](http://m.onkey.org/2008/7/20/rescue-from-dispatching)できるようになりました。
* HTTP Acceptヘッダはデフォルトで無効化されました。Accept ヘッダが必要な場合は、 `config.action_controller.use_accept_header = true` でオンに戻せます。
* ベンチマークが秒単位ではなくミリ秒単位で出力されるようになりました。
* RailsがHTTPonly cookieをサポートするようになりました（セッションで使われます）。 これは新しいブラウザでクロスサイトスクリプティングのリスクを軽減するのに有用です。
* `redirect_to` が URI スキームを完全にサポートしました（たとえば`ssh: URI` にリダイレクトできます）。
* `render` が `:js` オプションをサポートし、正しい MIME タイプを持つ素の JavaScript をレンダリングするようになりました。
* リクエストフォージェリ対策が HTML フォーマットのコンテンツリクエストにのみ適用されるように強化されました。
* 渡されたパラメータが nil の場合のポリモーフィック URL 動作が改良されました。たとえば、 `polymorphic_path([@project, @date, @area])` を nil の日付で呼ぶと、 `project_area_path` が返されます。

Action View
-----------

* `javascript_include_tag` と `stylesheet_link_tag` が新しい `:recursive` オプションをサポートし、 `:all` も指定することでファイルのツリー全体を読み込めるようになりました。
* 同梱の Prototype JavaScript ライブラリがバージョン 1.6.0.3 にアップグレードされました。
* `RJS#page.reload` は、ブラウザの現在のページをJavaScriptで再読み込みします。
* `atom_feed` ヘルパーに `:instruct` オプションが追加され、XML 処理命令を挿入できるようになりました。

Action Mailer
-------------

Action Mailerがメーラーでレイアウトをサポートするようになりました。適切な名前のレイアウトを指定すると、HTMLメールをブラウザ上のビューのように整形できます。たとえば、`CustomerMailer`クラスは `layouts/customer_mailer.html.erb` を使うことを想定しています。

* 詳細:
    * [What's New in Edge Rails: Mailer Layouts](http://archives.ryandaigle.com/articles/2008/9/7/what-s-new-in-edge-rails-mailer-layouts)

Action Mailer は、GMail の SMTP サーバーでSTARTTLS を自動的にオンにすることで、ビルトインのサポートを提供するようになりました。このためには、Ruby 1.8.7 がインストールされている必要があります。

Active Support
--------------

Active Supportは、Railsアプリケーションのメモ化機能の組み込み、`each_with_object`メソッド、委譲でのプレフィックスサポートなど、多くの新しいユーティリティメソッドを提供するようになりました。

### メモ化

メモ化（memoization）とは、あるメソッドを一度初期化した後、その値を保存して繰り返し使えるようにする手法です。自分のアプリケーションでこのパターンを使ったことがある人も多いでしょう。

```ruby
def full_name
  @full_name ||= "#{first_name} #{last_name}"
end
```

メモ化を使うと、このタスクを宣言的に処理できます。

```ruby
extend ActiveSupport::Memoizable

def full_name
  "#{first_name} #{last_name}"
end
memoize :full_name
```

その他のメモ化機能には、メモ化をオンオフできる`unmemoize`, `unmemoize_all`, `memoize_all` などがあります。

* リードコントリビュータ: [Josh Peek](http://joshpeek.com/)
* 詳細:
    * [What's New in Edge Rails: Easy Memoization](http://archives.ryandaigle.com/articles/2008/7/16/what-s-new-in-edge-rails-memoization)
    * [Memo-what? A Guide to Memoization](http://www.railway.at/articles/2008/09/20/a-guide-to-memoization)

### `each_with_object`

`each_with_object` メソッドは、Ruby 1.9 からバックポートされたメソッドを用いて `inject` の代替となるメソッドを提供します。これはコレクションに対して反復処理を行い、現在の要素とメモをブロックに渡します。

```ruby
%w(foo bar).each_with_object({}) { |str, hsh| hsh[str] = str.upcase }
# => {'foo' => 'FOO', 'bar' => 'BAR'}
```

リードコントリビュータ: [Adam Keys](http://therealadam.com/)

### 委譲でのプレフィックス指定

あるクラスから別のクラスに振る舞いを委譲する場合、委譲されるメソッドで以下のようにプレフィックスを指定できるようになりました。

```ruby
class Vendor < ActiveRecord::Base
  has_one :account
  delegate :email, :password, :to => :account, :prefix => true
end
```

上は`vendor#account_email` と `vendor#account_password` という委譲メソッドを生成します。また、以下のようにカスタムのプレフィックスも指定できます。

```ruby
class Vendor < ActiveRecord::Base
  has_one :account
  delegate :email, :password, :to => :account, :prefix => :owner
end
```

上は`vendor#owner_email` and `vendor#owner_password`という委譲メソッドを生成します。

リードコントリビュータ: [Daniel Schierbeck](http://workingwithrails.com/person/5830-daniel-schierbeck)

### その他のActive Supportの変更

* `ActiveSupport::Multibyte` が大幅に更新されました。Ruby 1.9 との互換性のための修正も含まれます。
* `ActiveSupport::Rescuable` が追加され、任意のクラスが `rescue_from` 構文にミックスインできるようになりました。
* `Date` と `Time` クラスに `past?`, `today?`, `future?` が追加され、日付や時間を比較しやすくなりました。
* `Array#[1]`〜`Array#[4]` までのエイリアスとして `Array#second`〜`Array#fifth` が追加されました。
* `Enumerable#many?` は `collection.size > 1` をカプセル化したものです。
* `Inflector#parameterize` は、 入力を URL で利用可能な形に変換します（`to_param` で使われます）。
* 日数や週数の端数を`1.7.weeks.ago` や `1.5.hours.since` のように認識できるようになりました。
* 付属のTzInfoライブラリがバージョン0.3.12にアップグレードされました。
* `ActiveSupport::StringInquirer` は、文字列が等しいかどうかをスマートにテストする方法を提供します（`ActiveSupport::StringInquirer.new("abc").abc? => true`）。

Railties
--------

Railties（Railsのコアコード）で最も大きな変更は、`config.gems` の仕組みです。

### `config.gems`

Railsアプリケーションで必要なすべてのgemsのコピーを `/vendor/gems` に配置可能にすることで、デプロイの問題を回避し、Railsアプリケーションを自己完結性を高められるようになりました。この機能はRails 2.1で初めて登場しましたが、Rails 2.2ではより柔軟で堅牢になり、gems間の複雑な依存関係も扱えるようになりました。RailsのGem管理では以下のコマンドが使えます。

* `config.gem _gem名_`: `config/environment.rb`ファイルに対応するgemを設定
* `rake gems`: 設定済みのgemをすべて表示する。gem（および依存関係が）インストール済みか、frozenか、フレームワークgemかも表示されます（フレームワークgemは他のgemが実行されるよりも先に読み込まれ、frozenにできない）。
* `rake gems:install`: インストールされていないgemをインストールする
* `rake gems:unpack`: 必須gemのコピーを`/vendor/gems`に配置する
* `rake gems:unpack:dependencies`: 必須gemのコピーと依存関係を`/vendor/gems`に配置する
* `rake gems:build`: ビルドされていないネイティブ拡張をビルドする
* `rake gems:refresh_specs`: Rails 2.1で作成されたベンダリングgemをRails 2.2の保存方法に変える

単一のgemをunpackまたはインストールする場合は、コマンドラインで`GEM=_gem名_`を指定します。

* リードコントリビュータ: [Matt Jones](https://github.com/al2o3cr)
* 詳細:
    * [What's New in Edge Rails: Gem Dependencies](http://archives.ryandaigle.com/articles/2008/4/1/what-s-new-in-edge-rails-gem-dependencies)
    * [Rails 2.1.2 and 2.2RC1: Update Your RubyGems](https://afreshcup.com/home/2008/10/25/rails-212-and-22rc1-update-your-rubygems)
    * [Detailed discussion on Lighthouse](http://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1128)

### その他のRailtiesの変更

* [Thin](http://code.macournoyer.com/thin/) Webサーバのファンに朗報です。`script/server` が Thin を直接サポートするようになりました。
* `script/plugin install &lt;plugin&gt; -r &lt;revision&gt;` が svn ベースのプラグインと同様に git ベースのプラグインでも動作するようになりました。
* `script/console` で `--debugger` オプションがサポートされました。
* Rails自体をビルドするためのCIサーバの設定方法は、Railsのソースコードに含まれています。
* `rake notes:custom ANNOTATION=MYFLAG` でカスタムアノテーションをリストアップできます。
* `Rails.env` が `StringInquirer` でラップされ、 `Rails.env.development?` が使えるようになりました。
* Railsで非推奨の警告が表示されないようにし、gemの依存性を適切に扱うためには、rubygems 1.3.1以降が必須となりました。

非推奨化されたもの
----------

今回のリリースで、一部の古いコードが非推奨化されました。

* `Rails::SecretKeyGenerator`は`ActiveSupport::SecureRandom`に置き換えられました。
* `render_component`は非推奨化されました。この機能が必要な場合は[render_components plugin](https://github.com/rails/render_component/tree/master)を利用できます。
* パーシャルをレンダリングするときの暗黙のローカル代入が非推奨化されました。

    ```ruby
    def partial_with_implicit_local_assignment
      @customer = Customer.new("Marcel")
      render :partial => "customer"
    end
    ```

    以前は、上記のコードで'customer'パーシャル内の `customer` というローカル変数が利用可能でした。現在は、すべての変数を明示的に`:locals`ハッシュで渡す必要があります。

* `country_select`が削除されました。詳細および代替プラグインについては、[http://www.rubyonrails.org/deprecation/list-of-countries](http://www.rubyonrails.org/deprecation/list-of-countries) を参照してください（訳注: このページは現在無効です）。
* `ActiveRecord::Base.allow_concurrency` は無効になりました。
* `ActiveRecord::Errors.default_error_messages` は非推奨化されました。`I18n.translate('activerecord.errors.messages')`をお使い下さい。
* `%s` と `%d` の式展開構文は国際化で非推奨化されました。
* `String#chars` は非推奨化され、代わりに `String#mb_chars` が採用されました。
* 小数で表される月や年の長さが非推奨化されました。代わりに、Rubyコアの`Date`クラスや`Time`クラスの演算をお使いください。
* `Request#relative_url_root` は非推奨化されました。代わりに `ActionController::Base.relative_url_root` をお使いください。

クレジット表記
-------

リリースノート編集担当:[Mike Gunderloy](http://afreshcup.com)
