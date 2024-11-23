Ruby on Rails 2.3 リリースノート
===============================

Rails 2.3では、Rackの広範な統合、Railsエンジンのサポートの刷新、Active Recordのネストされたトランザクション、ダイナミックスコープとデフォルトスコープ、統一レンダリング、より効率のよいルーティング、アプリケーションテンプレート、静かなバックトレースといったさまざまな新機能や改善機能が提供されています。このリストは主要なアップグレードをカバーしていますが、すべての小さなバグフィックスや変更を含んでいるわけではありません。すべてを見たい場合は、GitHubのメインRailsリポジトリの[コミットリスト](https://github.com/rails/rails/commits/2-3-stable)をチェックするか、個別のRailsコンポーネントの`CHANGELOG`ファイルを確認してください。

--------------------------------------------------------------------------------


アプリケーションアーキテクチャ
------------------------

Railsアプリケーションのアーキテクチャには、モジュール式Webサーバインターフェースである[Rack](https://rack.github.io/)の完全統合と、Railsエンジンの新たなサポートという2つの大きな変更があります。

### Rackの統合

Railsは、これまでのCGIと決別し、あらゆる場所でRackを使うようになりました。このため、非常に多くの内部変更が必要となり、その結果、Railsはプロキシインタフェースを通じてCGIをサポートするようになりました（ただし、CGIを使っている人も心配ありません）。それでも、これはRails内部に対する大きな変更です。2.3にアップグレードしたら、ローカル環境と本番環境でテストする必要があります。以下などについてテストが必要です。

* セッション
* Cookie
* ファイルアップロード
* JSON/XML API

以下はRack関連の変更点の概要です。

* `script/server`はrackup設定ファイルが存在すれば、それを取得します。これはRackと互換性のある全てのサーバをサポートすることを意味します。デフォルトでは`config.ru`ファイルを探索しますが、`-c`スイッチでこれを上書きできます。
* FCGIハンドラはRackを経由します。
* `ActionController::Dispatcher`は独自のデフォルトミドルウェアスタックを保持しています。ミドルウェアは注入・並べ替え・削除できます。ミドルウェアスタックは起動時にチェーンにコンパイルされます。ミドルウェアスタックは`environment.rb`で設定できます。
* ミドルウェアスタックを調べられる`rake middleware`タスクが追加されました。これはミドルウェアスタックの読み込み順序をデバッグするのに便利です。
* 結合テストのランナーが、ミドルウェアとアプリケーションのスタック全体を実行するように変更されました。これにより、結合テストはRackミドルウェアのテストに最適になりました。
* `ActionController::CGIHandler`はRackの後方互換性のあるCGIラッパーです。`CGIHandler`は古いCGIオブジェクトを受け取り、その環境情報をRackと互換性のある形に変換します。
* `CgiRequest`と`CgiResponse`は削除されました。
* セッションストアがlazy loading（遅延読み込み）されるようになりました。リクエスト中に一度もセッションオブジェクトにアクセスしなかった場合、セッションデータを読み込むことはなくなりました（cookieの解析、memcacheからのデータ読み込み、Active Recordオブジェクトの探索）。
* クッキーの値を設定するテストで`CGI::Cookie.new`が不要になりました。`request.cookies["foo"]`に`String`値を代入すれば期待どおりcookieが設定されます。
* `CGI::Session::CookieStore`が`ActionController::Session::CookieStore`に置き換えられました。
* `CGI::Session::MemCacheStore`が`ActionController::Session::MemCacheStore`に置き換えられました。
* `CGI::Session::ActiveRecordStore`が`ActiveRecord::SessionStore`に置き換えられました。
* セッションストアは引き続き`ActionController::Base.session_store = :active_record_store`で変更できます。
* デフォルトのセッションオプションは引き続き`ActionController::Base.session = { :key => "..." }`で設定できます。ただし`:session_domain`オプション名は`:domain`に変更されました。
* 従来リクエスト全体をラップしていたミューテックスは、`ActionController::Lock`ミドルウェアに移動しました。
* `ActionController::AbstractRequest`と`ActionController::Request`が統合されました。新しい`ActionController::Request`は`Rack::Request`を継承しています。これは、テストリクエストにおける`response.headers['type']`へのアクセスに影響します。代わりに`response.content_type`をお使いください。
* `ActiveRecord::QueryCache`ミドルウェアは、`ActiveRecord`が読み込まれると自動的にミドルウェアスタックに挿入されます。このミドルウェアは、リクエストごとのActive Recordクエリキャッシュのセットアップやクリアを行います。
* RailsのルータとコントローラのクラスはRackの仕様に準拠するようになりました。コントローラを直接呼び出すには、`SomeController.call(env)`を使います。ルータはルーティングパラメータを`rack.routing_args`に保存します。
* `ActionController::Request`は`Rack::Request`を継承するようになりました。
* `config.action_controller.session = { :session_key => 'foo', ...`の代わりに、`config.action_controller.session = { :key => 'foo', ...`をお使い下さい。
* ミドルウェア`ParamsParser`を使うと、XML、JSON、またはYAMLリクエストを前処理して、任意の`Rack::Request`オブジェクトで正常に読み込めるようになりました。

### Railsエンジンを新たにサポート

ここしばらくアップグレードがありませんでしたが、Rails 2.3ではRailsエンジン（他のアプリケーションに組み込めるRailsアプリケーション）にいくつかの新機能が追加されました。まず、エンジン内のルーティングファイルは`routes.rb`ファイルと同様に自動的にロード・リロードされるようになりました（これは他のプラグイン内のルーティングファイルについても同様です）。次に、プラグインにappフォルダがある場合、`app/[models|controllers|helpers]`は自動的にRailsの読み込みパスに追加されます。エンジンもビューパスの追加をサポートするようになり、Action MailerやAction Viewはエンジンや他のプラグインからのビューを利用するようになりました。

ドキュメント
-------------

[Railsガイド](https://railsguides.jp/)プロジェクトはRails 2.3向けにガイドをいくつも追加しました。さらに、[edgeguides.rubyonrails.org](https://edgeguides.rubyonrails.org/)という別サイトでRails Edgeガイド（英語のみ）を参照できるようになりました。また、ドキュメント関連では[Rails wiki](http://newwiki.rubyonrails.org/)やRails Bookの再立ち上げなども行われました（訳注: Rails wikiとRails Bookは現在は動いていません）。


* 詳しくは[Rails Documentation Projects](https://rubyonrails.org/2009/1/15/rails-documentation-projects)を参照して下さい。

Ruby 1.9.1のサポート
------------------

Rails 2.3は、Ruby 1.8および現在リリースされているRuby 1.9.1のどちらでも、独自のテストにすべてパスするはずです。ただし1.9.1への移行には、Railsコアだけでなく、データアダプタ、プラグイン、その他依存するコードのすべてをRuby 1.9.1互換性でチェックする必要があることにご注意下さい。

Active Record
-------------

Rails 2.3のActive Recordでは、非常に多くの新機能追加とバグフィックスが施されています。特に、ネステッド属性、ネステッドトランザクション、動的スコープとデフォルトスコープ、およびバッチ処理がハイライトです。

### ネステッド属性

Active Recordは、モデルのネステッド属性を以下のように直接更新できるようになりました。

```ruby
class Book < ActiveRecord::Base
  has_one :author
  has_many :pages

  accepts_nested_attributes_for :author, :pages
end
```

ネステッド属性を有効にすると、レコードと関連する子レコードを自動的に（かつアトミックに）保存し、子を意識したバリデーションを行い、ネステッドフォームをサポートします（後述）。

また、`:reject_if`オプションを使うことで、ネステッド属性によって追加される新しいレコードに対する要件を指定することもできます。

```ruby
accepts_nested_attributes_for :author,
  :reject_if => proc { |attributes| attributes['name'].blank? }
```

* リードコントリビュータ: [Eloy Duran](http://superalloy.nl/)
* 詳細: [Nested Model Forms](https://weblog.rubyonrails.org/2009/1/26/nested-model-forms)

### ネステッドトランザクション

要望の多かったネステッドトランザクションがActive Recordでサポートされました。これで以下のようなコードを書けるようになりました。

```ruby
User.transaction do
  User.create(:username => 'Admin')
  User.transaction(:requires_new => true) do
    User.create(:username => 'Regular')
    raise ActiveRecord::Rollback
  end
end

User.find(:all)  # => Adminだけを返す
```

ネステッドトランザクションでは、外側のトランザクションの状態に影響を与えずに内側のトランザクションをロールバックできます。トランザクションをネストしたい場合は、明示的に`:requires_new`オプションを追加する必要があります。そうしないと、ネステッドトランザクションは単に親トランザクションの一部になります（現在のRails 2.2ではそうなっています）。ネステッドトランザクションは内部で[セーブポイントを使う](http://rails.lighthouseapp.com/projects/8994/tickets/383)ので、真のネステッドトランザクションを持たないデータベースでもサポートされます。また、テスト中にこれらのトランザクションをトランザクションフィクスチャでうまく動作させるために、ちょっとしたマジックも使っています。

* リードコントリビュータ: [Jonathan Viney](http://www.workingwithrails.com/person/4985-jonathan-viney)、[Hongli Lai](http://izumi.plan99.net/blog/)

### 動的スコープ

Railsのダイナミックファインダーメソッド（`find_by_color_and_flavor`のような動的に生成されるメソッド）や名前付きスコープ（再利用可能なクエリ条件を`currently_active`のようにフレンドリーな名前にカプセル化できる）は既にご存知でしょう。これらに加えて動的なスコープメソッドも使えるようになりました。このアイデアは、以下のように動的なフィルタリングやメソッドチェインを可能にする構文をまとめることです。

```ruby
Order.scoped_by_customer_id(12)
Order.scoped_by_customer_id(12).find(:all,
  :conditions => "status = 'open'")
Order.scoped_by_customer_id(12).scoped_by_status("open")
```

動的スコープは、何も定義せずにすぐ使えます。

* リードコントリビュータ: [Yaroslav Markin](http://evilmartians.com/)
* 詳細: [What's New in Edge Rails: Dynamic Scope Methods](http://archives.ryandaigle.com/articles/2008/12/29/what-s-new-in-edge-rails-dynamic-scope-methods)

### デフォルトスコープ

Rails 2.3では、名前付きスコープに似た**デフォルトスコープ**という概念が導入されます。これはモデル内のすべての名前付きスコープやfindメソッドに適用されます。たとえば、`default_scope :order => 'name ASC'`と書けば、そのモデルからレコードを取得するときはいつでも名前順でソートされて出力されます（もちろん、このオプションをオーバーライドしない限り）。

* リードコントリビュータ: Paweł Kondzior
* 詳細: [What's New in Edge Rails: Default Scoping](http://archives.ryandaigle.com/articles/2008/11/18/what-s-new-in-edge-rails-default-scoping)

### バッチ処理

`find_in_batches`を使うことで、メモリに負担をかけずにActive Recordモデルの大量のレコードを処理できるようになりました。

```ruby
Customer.find_in_batches(:conditions => {:active => true}) do |customer_group|
  customer_group.each { |customer| customer.update_account_balance! }
end
```

`find_in_batches`には、ほとんどの`find`オプションを渡せます。ただし、返すレコードの順序を指定することや（常に主キーの昇順で返される整数値でなければなりません）、`:limit`オプションを使うことはできません。代わりに、`:batch_size`オプション（デフォルトは1000件）を使って、各バッチで返されるレコードの数を設定できます。

新しい`find_each`メソッドは、個々のレコードを返す`find_in_batches`のラッパーで、検索自体はバッチ処理で行われます（デフォルトでは1000件）。

```ruby
Customer.find_each do |customer|
  customer.update_account_balance!
end
```

この方法はバッチ処理でのみ使うようご注意ください。少数のレコード（1000件以下）の場合は、通常のfindメソッドをループで回してください。

* 詳細（この時点では、この便利メソッドは単に`each`と呼ばれていました）。
    * [Rails 2.3: Batch Finding](http://afreshcup.com/2009/02/23/rails-23-batch-finding/)
    * [What's New in Edge Rails: Batched Find](http://archives.ryandaigle.com/articles/2009/2/23/what-s-new-in-edge-rails-batched-find)

### コールバックで複数条件を指定

Active Recordコールバックを使うときに、同じコールバックで`:if`と`:unless`オプションを組み合わせ、複数の条件を配列として指定できるようになりました。

```ruby
before_save :update_credit_rating, :if => :active,
  :unless => [:admin, :cash_only]
```

* リードコントリビュータ: L. Caviola
### `having`で検索

`:having`オプション（および`has_many`と`has_and_belongs_to_many`関連付け）が追加され、グループ化された検索結果のレコードを検索でフィルタできるようにました。SQLの知識が豊富な人ならご存知のように、グループ化された結果に基づいてフィルタをかけられるようになります。

```ruby
developers = Developer.find(:all, :group => "salary",
  :having => "sum(salary) > 10000", :select => "salary")
```

* リードコントリビュータ: [Emilio Tagua](https://github.com/miloops)

### MySQLコネクションの再接続

MySQLコネクションで再接続フラグをサポートされました。trueに設定すると、コネクションが切れてあきらめる前にクライアントがサーバーへの再接続を試みます。Railsアプリケーションでこの動作を有効にするために、`database.yml`でMySQLコネクションに`reconnect = true`を設定できるようになりました。デフォルトは`false`なので、既存のアプリケーションの動作は変わりません。

* リードコントリビュータ: [Dov Murik](http://x.com/dubek)
* 詳細:
    * [Controlling Automatic Reconnection Behavior](http://dev.mysql.com/doc/refman/5.6/en/auto-reconnect.html)
    * [MySQL auto-reconnect revisited](http://groups.google.com/group/rubyonrails-core/browse_thread/thread/49d2a7e9c96cb9f4)

### その他のActive Recordの変更点

* `has_and_belongs_to_many`プリロードの生成SQLから余分な`AS`が削除され、いくつかのデータベースの動作が改善されました。
* `ActiveRecord::Base#new_record?`は、既存のレコードが存在する場合に`nil`ではなく`false`を返すようになりました。
* `has_many :through`の関連付けにおいて、テーブル名の引用符のバグが修正されました。
* `updated_at`タイムスタンプに特定のタイムスタンプを指定できるようになりました: `cust = Customer.create(:name => "ABC Industries", :updated_at => 1.day.ago)`.
* `find_by_attribute!`呼び出しに失敗した場合のエラーメッセージを改善しました。
* Active Recordの`to_xml`サポートに`:camelize`オプションが追加され、柔軟性が少し高まりました。
* `before_update`や`before_create`のコールバックをキャンセルする際のバグが修正されました。
* JDBC経由でデータベースをテストするためのRakeタスクが追加されました。
* `validates_length_of`は、`:in`または`:within`オプション（オプションが指定された場合）でカスタムエラーメッセージを使うようになりました。
* スコープ付きselectのカウントが正しく動作するようになり、`Account.scoped(:select => "DISTINCT credit_limit").count`のようなことが可能になりました。
* `ActiveRecord::Base#invalid?`が`ActiveRecord::Base#valid?`の逆として動作するようになりました。

Action Controller
-----------------

Action Controllerは、今回のリリースでレンダリングに関する大幅な変更と、ルーティングなどの改善を行いました。

### レンダリング方法の統一

`ActionController::Base#render`でレンダリング対象を指定する方法がよりスマートになりました。レンダリング対象を指定するだけで、正しい結果が期待できます。以前のバージョンのRailsでは、以下のようにレンダリングで明示的な情報を提供する必要が生じることがよくありました。

```ruby
render :file => '/tmp/random_file.erb'
render :template => 'other_controller/action'
render :action => 'show'
```

Rails 2.3では以下のように、レンダリングしたいものを指定するだけで済みます。

```ruby
render '/tmp/random_file.erb'
render 'other_controller/action'
render 'show'
render :show
```

Railsは、レンダリング対象の冒頭にスラッシュがある場合、スラッシュが途中にある場合、スラッシュがまったくない場合に応じて、ファイル、テンプレート、アクションのいずれかを選択します。アクションをレンダリングするときに、文字列の代わりにシンボルも使えます。それ以外のレンダリングスタイル（`:inline`、`:text`、`:update`、`:nothing`、`:json`、`:xml`、`:js`）では、引き続き明示的なオプションが必要です。

### Application Controllerがリネームされた

`application.rb`で特殊なケースのネーミングにいつも悩まされている方へ朗報です。Rails 2.3では`application_controller.rb`という名前に代わりました。さらに、新しいrakeタスク`rake rails:update:application_controller`が用意され、これを自動的に実行できます（これは通常の`rake rails:update`プロセスの一部として実行されます）。

* 詳細:
    * [The Death of Application.rb](https://afreshcup.com/home/2008/11/17/rails-2x-the-death-of-applicationrb)
    * [What's New in Edge Rails: Application.rb Duality is no More](http://archives.ryandaigle.com/articles/2008/11/19/what-s-new-in-edge-rails-application-rb-duality-is-no-more)

### HTTPダイジェスト認証のサポート

Railsでは、HTTPダイジェスト認証がビルトインでサポートされるようになりました。これを使うには、以下のようにユーザーのパスワードを返すブロックを付けて`authenticate_or_request_with_http_digest`を呼び出します（パスワードはハッシュ化され、送信されたcredentialと比較されます）。

```ruby
class PostsController < ApplicationController
  Users = {"dhh" => "secret"}
  before_filter :authenticate

  def secret
    render :text => "Password Required!"
  end

  private
  def authenticate
    realm = "Application"
    authenticate_or_request_with_http_digest(realm) do |name|
      Users[name]
    end
  end
end
```

* リードコントリビュータ: [Gregg Kellogg](http://www.kellogg-assoc.com/)
* 詳細: [What's New in Edge Rails: HTTP Digest Authentication](http://archives.ryandaigle.com/articles/2009/1/30/what-s-new-in-edge-rails-http-digest-authentication)

### ルーティングの効率向上

Rails 2.3では、ルーティングにいくつかの重要な変更が加えられています。`formatted_`ルーティングヘルパーがなくなり、代わりに`:format`をオプションとして渡せるようになりました。これにより、どのリソースに対してもルート生成プロセスが50%削減され、かなりの量のメモリが節約できます（大規模なアプリケーションでは最大100MB）。自分のコードが`formatted_`ヘルパーを使っていたとしても、当面は動作しますが、この動作は非推奨であり、新しい標準でルーティングを書き直せば、アプリケーションの効率は向上します。もう一つの大きな変更点は、Railsが`routes.rb`だけでなく、複数のルーティングファイルをサポートするようになったことです。`RouteSet#add_configuration_file`を使えば、現在読み込まれているルーティングをクリアすることなく、いつでも新しいルートを取り込めます。この変更はRailsエンジンで最も有用ですが、ルーティングをバッチで一括読み込みする必要がある任意のアプリケーションで利用できます。

* リードコントリビュータ: [Aaron Batalion](http://blog.hungrymachine.com/)

### Rackベースの遅延読み込みセッション

大きな変更点として、Action Controllerのセッションストレージの基盤がRackレベルに押し下げられたことが挙げられます。Railsアプリケーションからはまったく見えないはずですが、コードにはかなりの作業が含まれています（ボーナスとして、古いCGIセッションハンドラ周辺の厄介なパッチがいくつか削除されました）。Rails以外のRackアプリケーションもRailsアプリケーションと同じセッションストレージハンドラにアクセスできる（つまり同じセッションにアクセスできる）からです。さらに、セッションは遅延読み込みされるようになりました（フレームワークの他の部分の読み込み改善と同様）。つまり、セッションが不要な場合に明示的に無効にする必要はなくなりました。セッションを参照しないようにすれば、セッションは読み込まれません。

### MIMEタイプの扱いが変更

RailsでMIMEタイプを処理するコードには、いくつかの変更があります。まず、`MIME::Type`が`=~`演算子を実装し、同義語を持つタイプの存在をチェックする必要がある場合の記法がずっと明確になりました。

```ruby
if content_type && Mime::JS =~ content_type
  # 何かする
end

Mime::JS =~ "text/javascript"        => true
Mime::JS =~ "application/javascript" => true
```

もう1つの変更は、フレームワークがさまざまな場所でJavaScriptをチェックするときに`Mime::JS`を使うようになり、それらの代替をきれいに処理できるようになったことです。

* リードコントリビュータ: [Seth Fitzsimmons](http://www.workingwithrails.com/person/5510-seth-fitzsimmons)

### `respond_to`の最適化

RailsとMerbチームの合併による最初の成果として、Rails 2.3には`respond_to`メソッドの最適化が含まれています。このメソッドはもちろん多くのRailsアプリケーションで多用されていて、送られてきたリクエストのMIMEタイプに応じてコントローラが異なる結果をフォーマットできるようになっています。`method_missing`の呼び出しをなくし、プロファイリングと微調整を行った結果、3つのフォーマットを切り替えるシンプルな`respond_to`で、1秒あたりのリクエスト数が8%向上しています。最も優れている点は、このスピードアップを利用するためにアプリケーションのコードを変更する必要がまったくないことです。

### キャッシュのパフォーマンス向上

Railsは、リモートキャッシュストアから読み込んだデータをリクエストごとにローカルキャッシュとして保持するようになり、不要な読み込みを減らしてサイトのパフォーマンスを向上させました。この機能はもともと`MemCacheStore`に限定されていましたが、必要なメソッドを実装しているリモートストアであれば、どのストアでも利用できます。

* リードコントリビュータ: [Nahum Wild](http://www.motionstandingstill.com/)

### ビューのローカライズ

Railsは、設定したロケールに応じてローカライズされたビューを提供できるようになりました。たとえば、`Posts`コントローラに`show`アクションがあると、デフォルトでは`app/views/posts/show.html.erb`がレンダリングされます。しかし`I18n.locale = :da`と設定すると、`app/views/posts/show.da.html.erb`がレンダリングされるようになります。ローカライズされたテンプレートが存在しない場合は、装飾なしバージョンが使われます。Railsには`I18n#available_locales`と`I18n::SimpleBackend#available_locales`もあり、これらは現在のRailsプロジェクトで利用可能な翻訳の配列を返します。

さらに、同じ方法でpublicディレクトリにあるrescueファイルもローカライズできます。たとえば、`public/500.da.html`や`public/404.en.html`が使えるようになります。

### 翻訳APIをパーシャルでスコープ化

翻訳APIの変更により、パーシャル内のキー翻訳を簡単に書けるようになり、記述の重複が少なくなりました。`people/index.html.erb`テンプレートから`translate(".foo")`を呼び出すと、実際には`I18n.translate("people.index.foo")`を呼び出します。キーの前にピリオドがない場合は、以前と同じようにAPIはスコープなしとなります。

### その他のAction Controllerの変更

* ETagの取り扱いが少し改善されました。レスポンスにbodyがないとき、または`send_file`でファイルを送信するときに、RailsはETagヘッダの送信をスキップするようになりました。
* RailsによるIPスプーフィングのチェックは、携帯電話のトラフィックが多いサイトで邪魔になることがありますが。そのような場合は`ActionController::Base.ip_spoofing_check = false`と設定することで、チェックを完全に無効にできるようになりました。
* `ActionController::Dispatcher`は独自のミドルウェアスタックを実装しており、`rake middleware`を実行することで確認できます。
* cookieセッションが永続的なセッション識別子を持つようになりました。これはサーバーサイドストアとのAPI互換性があります。
* `send_file`と`send_data`の`:type`オプションで、`send_file("fabulous.png", :type => :png)`のようにシンボルを使えるようになりました。
* `map.resources`の`:only`と`:except`オプションは、ネストしたリソースには継承されなくなりました。
* バンドルされているmemcachedクライアントがバージョン1.6.4.99に更新されました。
* プロキシキャッシュで動作するように`expires_in`、`stale?`、`fresh_when`メソッドに`:public`オプションを指定できるようになりました。
* RESTfulなmemberルーティングが追加され、`:requirements`オプションが正しく動作するようになりました。
* 浅いルーティングで、名前空間が適切に考慮されるようになりました。
* `polymorphic_url`が、不規則に活用される複数形の名前を持つオブジェクトをより適切に扱えるようになりました。

Action View
-----------

Rails 2.3のAction Viewでは、ネステッドモデルのフォーム、`render`の改善、日付選択ヘルパーのより柔軟な表示、アセットキャッシングの高速化などが行われました。

### ネステッドオブジェクトのフォーム

親モデルが子オブジェクトのネステッド属性を受け入れる場合（上述のActive Recordのセクションの説明を参照）、`form_for`と`field_for`を使ってネステッドフォームを作成できます。これらのフォームは任意の深さにネスト可能で、少ないコードで複雑なオブジェクト階層を単一のビューで編集できます。たとえば以下のようなモデルがあるとします。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders

  accepts_nested_attributes_for :orders, :allow_destroy => true
end
```

Rails 2.3では以下のようにビューを書けます。

```html+erb
<% form_for @customer do |customer_form| %>
  <div>
    <%= customer_form.label :name, 'Customer Name:' %>
    <%= customer_form.text_field :name %>
  </div>

  <!-- Here we call fields_for on the customer_form builder instance.
   The block is called for each member of the orders collection. -->
  <% customer_form.fields_for :orders do |order_form| %>
    <p>
      <div>
        <%= order_form.label :number, 'Order Number:' %>
        <%= order_form.text_field :number %>
      </div>

  <!-- The allow_destroy option in the model enables deletion of
   child records. -->
      <% unless order_form.object.new_record? %>
        <div>
          <%= order_form.label :_delete, 'Remove:' %>
          <%= order_form.checkbox :_delete %>
        </div>
      <% end %>
    </p>
  <% end %>

  <%= customer_form.submit %>
<% end %>
```

* リードコントリビュータ: [Eloy Duran](http://superalloy.nl/)
* 詳細:
    * [Nested Model Forms](https://weblog.rubyonrails.org/2009/1/26/nested-model-forms)
    * [complex-form-examples](https://github.com/alloy/complex-form-examples)
    * [What's New in Edge Rails: Nested Object Forms](http://archives.ryandaigle.com/articles/2009/2/1/what-s-new-in-edge-rails-nested-attributes)

### パーシャルのレンダリングがスマートに

`render`メソッドは年々賢くなり、今はさらに賢くなりました。オブジェクトやコレクションと適切なパーシャルがあり、命名が一致する場合は、オブジェクトを`render`するだけで動くようになりました。たとえばRails 2.3では、以下の`render`コールがビューで使えます（命名が適切であると仮定します）。

```ruby
# これは以下と同様
# render :partial => 'articles/_article', :object => @article
render @article

# これは以下と同様
# render :partial => 'articles/_article', :collection => @articles
render @articles
```

* 詳細: [What's New in Edge Rails: render Stops Being High-Maintenance](http://archives.ryandaigle.com/articles/2008/11/20/what-s-new-in-edge-rails-render-stops-being-high-maintenance)

### 日付セレクタヘルパーのプロンプト表示

Rails 2.3では、様々な日付選択ヘルパー（`date_select`、`time_select`、`datetime_select`）で、コレクション選択ヘルパーと同様にカスタムプロンプトを指定できます。プロンプトには、文字列の他に、様々なコンポーネントのプロンプト文字列のハッシュを渡せます。また、`:prompt`を`true`に設定することで、一般的なプロンプトも利用できます。

```ruby
select_datetime(DateTime.now, :prompt => true)

select_datetime(DateTime.now, :prompt => "Choose date and time")

select_datetime(DateTime.now, :prompt =>
  {:day => 'Choose day', :month => 'Choose month',
   :year => 'Choose year', :hour => 'Choose hour',
   :minute => 'Choose minute'})
```

* リードコントリビュータ: [Sam Oliver](http://samoliver.com/)

### AssetTagのタイムスタンプキャッシュ

静的アセットパスに「キャッシュバスター」としてタイムスタンプを追加するRailsの慣習はよく知られていると思います。これは、画像やスタイルシートなどの古いコピーが、サーバーで変更されたときにユーザーのブラウザのキャッシュから提供されないようにするためのものです。Action Viewの設定オプション`cache_asset_timestamps`で、この動作を変更できるようになりました。キャッシュを有効にすると、Railsは最初にアセットを提供するときにタイムスタンプを一度算出して値を保存します。これは、静的アセットを提供するための（コストのかかる）ファイルシステム呼び出しが減ることを意味しますが、その代わり、サーバーの実行中にアセットを変更しても変更がクライアントに反映されることも期待できなくなります。

### アセットホストをオブジェクトとして宣言

エッジRailsでは、アセットホストを「呼び出しに応答する特定のオブジェクト」として宣言できるようになり、アセットホストの柔軟性が高まりました。これにより、アセットホストで必要などんな複雑なロジックも実装できるようになります。

* 詳細: [asset-hosting-with-minimum-ssl](https://github.com/dhh/asset-hosting-with-minimum-ssl/tree/master)

### `grouped_options_for_select`ヘルパーメソッド

アクションビューには、セレクタボックスの生成を支援するヘルパーがすでにたくさんありますが、もうひとつ増えました。`grouped_options_for_select`です。これは以下のように、文字列の配列またはハッシュを受け取って、`option`タグを`optgroup`タグでラップした文字列に変換するものです。

```ruby
grouped_options_for_select([["Hats", ["Baseball Cap","Cowboy Hat"]]],
  "Cowboy Hat", "Choose a product...")
```

上は以下を返します。

```html
<option value="">Choose a product...</option>
<optgroup label="Hats">
  <option value="Baseball Cap">Baseball Cap</option>
  <option selected="selected" value="Cowboy Hat">Cowboy Hat</option>
</optgroup>
```

### フォームのセレクタヘルパーを無効にするオプションタグ

フォームのセレクタヘルパー（`select`や`options_for_select`など）が`:disabled`オプションをサポートするようになり、結果のタグで無効にしたい単一の値または値の配列を受け取れるようになりました。

```ruby
select(:post, :category, Post::CATEGORIES, :disabled => 'private')
```

上は以下を返します。

```html
<select name="post[category]">
<option>story</option>
<option>joke</option>
<option>poem</option>
<option disabled="disabled">private</option>
</select>
```

また、無名関数を使えば、コレクションからどのオプションを選択または無効にするかを実行時に決定することもできます。

```ruby
options_from_collection_for_select(@product.sizes, :name, :id, :disabled => lambda{|size| size.out_of_stock?})
```

* リードコントリビュータ: [Tekin Suleyman](http://tekin.co.uk/)
* 詳細: [New in Rails 2.3 - disabled option tags and lambdas for selecting and disabling options from collections](https://tekin.co.uk/2009/03/new-in-rails-23-disabled-option-tags-and-lambdas-for-selecting-and-disabling-options-from-collections)

### テンプレート読み込みに関する注意

Rails 2.3では、キャッシュされたテンプレートを特定の環境で有効または無効にする機能があります。キャッシュされたテンプレートは、レンダリング時に新しいテンプレートファイルがあるかどうかをチェックしないので、速度が向上します。しかし、これは同時に、サーバを再起動せずに「その場で」テンプレートを置き換えられないということでもあります。

ほとんどの場合、production環境ではテンプレートのキャッシュを有効にしたいと思うでしょう。これは`production.rb`ファイルで設定します。

```ruby
config.action_view.cache_template_loading = true
```

上の設定は、新しいRails 2.3アプリケーションではデフォルトで生成されます。古いバージョンのRailsからアップグレードした場合、Railsはproduction環境とtest環境ではテンプレートをキャッシュするようにデフォルトで設定しますが、development環境では設定しません。

### その他のAction Viewの変更

* CSRF保護トークンの生成がシンプルになりました。RailsはセッションIDをいじくりまわすのではなく、`ActiveSupport::SecureRandom`によって生成されたシンプルなランダム文字列を使うようになりました。
* `auto_link`が、生成されたメールのリンクにオプション（`:target`や`:class`など）を適切に適用するようになりました。
* `autolink`ヘルパーがリファクタリングされ、より直感的に使えるようになりました。
* URLに複数のクエリパラメータがある場合でも、`current_page?`が正しく動作するようになりました。

Active Support
--------------

Active Supportでも、`Object#try`などいくつかの興味深い変更が行われました。

### `Object#try`

多くの人が、オブジェクトに対する操作を試みるときに`try()`を使うというアイデアを採用しています。特にビューでは、`<%= @person.try(:name) %>`のようなコードを書くことでnilチェックを回避できるので便利です。この機能がRailsに組み込まれました。Railsに実装されたこの機能は、privateメソッドに対して`NoMethodError`を発生し、オブジェクトがnilの場合は常に`nil`を返します。

* 詳細: [try()](http://ozmm.org/posts/try.html)

### `Object#tap`のバックポート

`Object#tap`は[Ruby 1.9](http://www.ruby-doc.org/core-1.9/classes/Object.html#M000309)および1.8.7に追加されたもので、Railsに以前からある`returning`メソッドに似ています。ブロックを`yield`して、`yield`したオブジェクトを返すというものです。Railsは現在、これを古いバージョンのRubyでも使えるようにするコードを含んでいます。

### XMLminiのパーサーが差し替え可能に

Active SupportのXML解析サポートで、パーサーを別のものに差し替えられるようになり、柔軟性が増しました。デフォルトでは、標準的なREXMLの実装を使いますが、適切なgemがインストールされていれば、高速なLibXMLやNokogiriの実装を自分のアプリケーションに簡単に指定できます。


```ruby
XmlMini.backend = 'LibXML'
```

* リードコントリビュータ: [Bart ten Brinke](http://www.movesonrails.com/)
* リードコントリビュータ: [Aaron Patterson](http://tenderlovemaking.com/)

### `TimeWithZone`で秒以下をサポート

`Time`クラスと`TimeWithZone`クラスに、時刻をXMLフレンドリーな文字列で返す`xmlschema`メソッドが含まれました。Rails 2.3の`TimeWithZone`は`Time`と同じ引数になり、返される文字列の小数第2位の桁数を指定できるようになりました。

```ruby
Time.zone.now.xmlschema(6) # => "2009-01-16T13:00:06.13653Z"
```

* リードコントリビュータ: [Nicholas Dainty](http://www.workingwithrails.com/person/13536-nicholas-dainty)

### JSONキーの引用符

json.orgサイトで仕様を調べると、JSON構造体のキーはすべて文字列でなければならず、二重引用符で囲まなければならないことがわかります。Rails 2.3からは、数値キーについても適切に扱うようになりました。

### その他のActive Supportの変更

* `Enumerable#none?`で、与えられたブロックにマッチする要素がないことをチェックできます。
* Active Supportの[delegates](https://afreshcup.com/home/2008/10/19/coming-in-rails-22-delegate-prefixes)を使う場合、新しい`:allow_nil`オプションで、ターゲットオブジェクトがnilのときに例外を発生させずに`nil`を返すようになりました。
* `ActiveSupport::OrderedHash`が`each_key`と`each_value`を実装しました。
* `ActiveSupport::MessageEncryptor`は（cookieのような）信頼できない場所に保存する情報を暗号化する簡単な方法を提供します。
* Active Supportの`from_xml`がXmlSimpleに依存しなくなりました。その代わりに、Railsは必要な機能だけを備えた、独自のXmlMini実装を含むようになりました。これにより、RailsはこれまでバンドルされていたXmlSimpleのコピーから解放されました。
* privateメソッドをメモ化すると、その結果もprivateになります。
* `String#parameterize`にオプションの区切り文字を渡せるようになりました。例: `"Quick Brown Fox".parameterize('_') => "quick_brown_fox"`.
* `number_to_phone`に7桁の電話番号を渡せるようになりました。
* `ActiveSupport::Json.decode`が`u0000`形式のエスケープシーケンスを処理するようになりました。

Railties
--------

上記のRackの変更に加え、Railties（Railsのコアコード）には、Rails Metal、アプリケーションテンプレート、Quiet Backtraceなど、多くの重要な変更が加えられています。

### Rails Metal

Rails Metalは、Railsアプリケーションの内部に超高速なエンドポイントを提供する新しいメカニズムです。MetalクラスはルーティングとAction Controllerをバイパスして、素の速度を提供します（もちろん、Action Controllerにあるすべてのものが使えなくなりますが）。これは、Railsを「ミドルウェアスタックを公開したRackアプリケーション」にするための最近の基礎作業の上に構築されています。Metalエンドポイントはアプリケーションやプラグインから読み込めます。

* 詳細:
    * [Introducing Rails Metal](https://weblog.rubyonrails.org/2008/12/17/introducing-rails-metal)
    * [Rails Metal: a micro-framework with the power of Rails](http://soylentfoo.jnewland.com/articles/2008/12/16/rails-metal-a-micro-framework-with-the-power-of-rails-m)
    * [Metal: Super-fast Endpoints within your Rails Apps](http://www.railsinside.com/deployment/180-metal-super-fast-endpoints-within-your-rails-apps.html)
    * [What's New in Edge Rails: Rails Metal](http://archives.ryandaigle.com/articles/2008/12/18/what-s-new-in-edge-rails-rails-metal)

### アプリケーションテンプレート

Rails 2.3には、Jeremy McAnallyによる[rg](https://github.com/jm/rg)アプリケーションジェネレータが組み込まれています。つまり、Railsにテンプレートベースのアプリケーション生成機能が組み込まれたということです。（他の多くのユースケースの中から）すべてのアプリケーションに含めたいプラグインのセットがある場合、テンプレートを一度セットアップしておけば、`rails`コマンドを実行するときにそれらが常に適用されるようになります。また、既存のアプリケーションにテンプレートを適用するrakeタスクも用意されています。


```bash
$ rake rails:template LOCATION=~/template.rb
```

上を実行すると、プロジェクトにすでに含まれているコードの上に、テンプレートによる変更を配置します。

* リードコントリビュータ: [Jeremy McAnally](http://www.jeremymcanally.com/)
* More Info:[Rails templates](http://m.onkey.org/2008/12/4/rails-templates)

### Quieter Backtrace

thoughtbotの[Quiet Backtrace](https://github.com/thoughtbot/quietbacktrace)プラグインは`Test::Unit`のバックトレースから選択的に行を削除できますが、Rails 2.3ではそれをベースにした`ActiveSupport::BacktraceCleaner`と`Rails::BacktraceCleaner`をコアに実装しています。これは、フィルタ（バックトレース行を正規表現で置換する）とサイレンサー（バックトレース行を完全に削除する）の両方をサポートします。Railsは新しいアプリケーションで最も一般的なノイズを取り除くためにサイレンサーを自動的に追加し、フィルタに追加するものを保存できる`config/backtrace_silencers.rb`ファイルを生成します。この機能により、バックトレース中の任意のgemの出力もpretty printされるようになります。

### 遅延読み込みと自動読み込みでdevelopmentモードの起動が高速化

Railsの一部（とその依存関係）が実際に必要なときだけメモリに読み込まれるようにするために、かなりの作業が行われました。コアフレームワークであるActive Support、Active Record、Action Controller、Action Mailer、Action Viewは、それぞれのクラスを`autoload`で遅延読み込みするようになりました。この作業によりメモリフットプリントが抑えられ、Rails全体のパフォーマンスが向上するはずです。

また、起動時にコアライブラリを自動読み込みするかどうかを（新しい`preload_frameworks`オプションで）指定できます。デフォルトの`false`ではRailsが少しずつ自動読み込みされますが、一度にすべてを取り込む必要が生じることもあります（PassengerとJRubyは、Railsのすべてを一括で読み込むことを希望しています）。

### rake gemタスクが書き直された

様々な <code>rake gem</code> タスクの内部が、多くのケースでうまく動くよう大幅に改訂されました。gemシステムは開発時の依存関係と実行時の依存関係の違いを認識するようになり、unpackingがより堅牢になり、gemの状態問い合わせで返される情報が改善され、スクラッチでアプリを開発するときに依存関係で「卵が先かニワトリが先か」問題を起こしにくくなりました。また、JRubyでgemコマンドを使うときや、すでにベンダリングされているgemの外部コピーを持ち込もうとする依存関係についても修正されています。

* リードコントリビュータ: [David Dollar](http://www.workingwithrails.com/person/12240-david-dollar)

### その他のRailties変更

* Railsビルド用にCIサーバを更新する手順が更新され、拡張されました。
* Railsの内部テストが`Test::Unit::TestCase`から`ActiveSupport::TestCase`に変更され、RailsコアのテストでMochaが必須になりました。
* デフォルトの`environment.rb`ファイルが整理されました。
* dbconsoleスクリプトで数字のみのパスワードを設定してもクラッシュしなくなりました。
* `Rails.root`が`Pathname`オブジェクトを返すようになりました。つまり、`File.join`を使っている[既存のコードをクリーンアップ](https://afreshcup.wordpress.com/2008/12/05/a-little-rails_root-tidiness/)して`join`メソッドを直接使えるようになりました。
* CGIやFCGIのディスパッチを扱う/publicの様々なファイルが、デフォルトではすべてのRailsアプリケーションで生成されなくなりました（必要であれば、`rails`コマンドを実行するときに`--with-dispatchers`を追加すればまだ取得できますし、後から`rake rails:update:generate_dispatchers`で追加することも可能です)。
* Railsガイドの記法がAsciiDocからTextileマークアップに変更されました。
* scaffoldで生成されるビューやコントローラが少し整理されました。
* `script/server`に、特定のパスからRailsアプリケーションをマウントする`--path`引数を渡せるようになりました。
* gemのrakeタスクは、設定済みのgemがない場合に環境の読み込みをスキップするようになりました。これは、gemが見つからないために`rake gems:install`が実行できないといった「卵が先かニワトリが先か」問題の多くを解決するはずです。
* Gemsは正確に一度だけunpackされるようになりました。これは、ファイルの読み取り専用パーミッションでパックされたgem（hoeなど）の問題を解決します。


非推奨化されたもの
----------

今回のリリースで、いくつかの古いコードが非推奨化されました。

* めったにいないはずですが、Railsアプリのデプロイをinspector、reaper、spawnerスクリプトに依存している場合は、これらのスクリプトがRailsのコアに含まれなくなったことを知っておく必要があります。必要なら、[irs_process_scripts](https://github.com/rails/irs_process_scripts)プラグインでコピーを手に入れられるはずです。
* Rails 2.3で`render_component`が "deprecated" から "nonexistent" に変更されました。それでも必要な場合は、[render_component plugin](https://github.com/rails/render_component/tree/master)をインストールするとよいでしょう。
* Railsコンポーネントのサポートは削除されました。
* `script/performance/request`スクリプトは現在Railsのコアから削除されました。結合テストでこのスクリプトを用いてパフォーマンスをチェックしている方は、別の新しい方法を学ぶ必要があります。新しいrequest_profilerプラグインをインストールすれば、まったく同じ機能を復元できます。
* `ActionController::Base#session_enabled?`は、セッションが遅延読み込みされるようになったため非推奨化されました。
* `protect_from_forgery`の`:digest`と`:secret`オプションは非推奨化されました（無効なオプションです）。
* いくつかの結合テストヘルパーが削除されました。`response.headers["Status"]`と`headers["Status"]`は何も返さなくなりました。Rackは戻り値のヘッダに "Status" を使うことを許可していません。しかし、`status`ヘルパーや`status_message`ヘルパーは利用可能です。`response.headers["cookie"]`と`headers["cookie"]`はCGI cookieを一切返さなくなりました。生のcookieヘッダを見るために`headers["Set-Cookie"]`を検査したり、クライアントに送信されたcookieのハッシュを取得するために`cookies`ヘルパーを利用することは可能です。
* `formatted_polymorphic_url`は非推奨化されました。代わりに`polymorphic_url`と`:format`をお使いください。
* `ActionController::Response#set_cookie`の`:http_only`オプション名は`:httponly`に変更されました。
* `to_sentence`の`:connector`オプションと`:skip_last_comma`オプションは、`:words_connector`, `:two_words_connector`, `:last_word_connector`オプションに置き換わりました。
* `file_field`コントロールが空になっているマルチパートフォームを送信すると、以前は空文字列がコントローラに送信されていましたが、現在はnilを送信するようになりました。これは、RackのマルチパートパーサーとRailsの古いパーサーとの違いに起因します。

クレジット表記
-------

リリースノート編集担当:[Mike Gunderloy](http://afreshcup.com)。このRails 2.3リリースノートは、Rails 2.3 RC2を元に編集されています。

