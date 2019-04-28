Ruby on Rails 2.3 リリースノート
===============================

Rails 2.3ではさまざまな新機能や改善をお届けします: Rackの全面的統合、Railsエンジンサポートのリニューアル、Active Recordのネステッドトランザクションサポート、動的スコープやデフォルトスコープ、統合されたレンダリング、効率の高いルーティング、アプリケーションテンプレート、Quiet Backtraceなどです。本リストでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GitHubのRailsリポジトリにある[コミットリスト](http://github.com/rails/rails/commits/master)でRailsの個別のコンポーネントの`CHANGELOG`を参照してください。

--------------------------------------------------------------------------------

アプリケーションアーキテクチャ
------------------------

Railsアプリケーションのアーキテクチャに対して2つの大きな変更が行われました。[Rack](http://rack.rubyforge.org/)（モジュラーWebサーバーインターフェイス）の完全な統合と、Railsエンジンサポートのリニューアルです。

### Rack統合

Railsは古臭いGCIを捨て去り、全面的にRackを採用しました。これは膨大な内部変更を必要とし、また実際に行われました（GCIを使っていても心配は無用です: RailsはCGIをプロキシインターフェイス経由でサポートするようになりました）。これはRailsの大きな内部変更のひとつであり、Rails 2.3にアップグレードする場合はローカルのdevelopment環境とproduction環境の両方で以下を含むテストを行うべきです。

* セッション
* cookie
* ファイルのアップロード
* JSON/XML APIs

Rack関連の変更点の概要を以下にまとめました。

* `script/server`がRackを用いる形に変更されました。これにより、Rack互換のあらゆるWebサーバーがサポートされます。rackup設定ファイルが存在する場合は`script/server`も利用されます。デフォルトでは`config.ru`を探索しますが、`-c`スイッチでオーバーライドできます。
* FCGIハンドラはRackを経由します。
* `ActionController::Dispatcher`はデフォルトのミドルウェアスタックを独自に保持します。ミドルウェアは、注入/並べ替え/削除が可能です。ミドルウェアスタックは起動時に1つのチェインにまとめられます。ミドルウェアスタックは`environment.rb`で設定できます。
* ミドルウェアスタックをinspectする`rake middleware`タスクが追加されました。これはミドルウェアスタックの並び順をデバッグするのに有用です。
* 結合テストランナーが変更され、ミドルウェアスタック全体とアプリケーションスタックを実行するようになりました。これにより結合テストでRackミドルウェアを完全にテストできるようになります。
* `ActionController::CGIHandler`はRack周辺での後方互換性用CGIラッパーです。`CGIHandler`は旧来のCGIオブジェクトを1つ受け取って環境情報をRack互換形式に変換します。
* `CgiRequest`と`CgiResponse`は削除されました。
* セッションストアが遅延読み込みされるようになりました。リクエスト中にセッションオブエクトにまったくアクセスしない場合、セッションデータの読み込み（およびcookieのパース、memcacheデータの読み込み、Active Recordオブジェクトの探索）を試行しません。
* cookie値の設定に`CGI::Cookie.new`を使う必要がなくなりました。`String`値を`request.cookies["foo"]`に代入するだけでcookieが期待どおりに設定されます。
* `CGI::Session::CookieStore`が`ActionController::Session::CookieStore`に置き換えられました。
* `CGI::Session::MemCacheStore`が`ActionController::Session::MemCacheStore`に置き換えられました。
* `CGI::Session::ActiveRecordStore`が`ActiveRecord::SessionStore`に置き換えられました。
* セッションストアは引き続き`ActionController::Base.session_store = :active_record_store`で変更できます。
* デフォルトのセッションオプションは引き続き`ActionController::Base.session = { :key => "..." }`で設定できます。ただし`:session_domain`オプションは`:domain`にリネームされました。
* リクエスト全体をラップするミューテックスが`ActionController::Lock`ミドルウェアに移動しました。
* `ActionController::AbstractRequest`と`ActionController::Request`が統合されました。新しい`ActionController::Request`は`Rack::Request`を継承します。これはテストリクエストの`response.headers['type']`に影響しますので、今後は`response.content_type`をお使いください。
* `ActiveRecord`が読み込まれると`ActiveRecord::QueryCache`ミドルウェアが自動的に挿入されるようになりました。このミドルウェアはリクエストごとのActive Recordクエリキャッシュをセットアップおよび削除します。
* RailsルータークラスとコントローラクラスがRackの仕様に従うようになりました。コントローラを`SomeController.call(env)`のように直接呼び出せるようになり、ルーターはルーティングパラメータを`rack.routing_args`に保存します。
* `ActionController::Request`は`Rack::Request`を継承します。
* 今後は`config.action_controller.session = { :session_key => 'foo', ...`ではなく`config.action_controller.session = { :key => 'foo', ...`をお使いください。
* `ParamsParser`ミドルウェアで任意のXML/JSON/YAMLがプリプロセスされるので、その後あらゆる`Rack::Request`オブジェクトから通常どおりに読み出せます。

### Railsエンジンサポートのリニューアル

いくつかのマイナーチェンジを経て、Rails 2.3ではRailsエンジン（他のアプリケーションに埋め込めるRailsアプリケーション）の新しい機能を利用できるようになりました。まず、エンジン内のルーティングファイルは、通常の`routes.rb`と同様に自動的に読み込みおよび再読み込みされます（その他のプラグイン内のルーティングファイルについても同様です）。次に、プラグインにappフォルダがあればRailsの読み込みパスにapp/[models|controllers|helpers]が自動的に追加されます。エンジンではビューパスの追加もサポートされ、Action Viewと同様にAction Mailerでもエンジンやその他のプラグインのビューを利用できるようになります。

ドキュメント
-------------

[Ruby on Railsガイド](http://guides.rubyonrails.org/)（英語版）にRails 2.3向けの追加のガイドが公開されました。さらに[edgeguidesサイト](http://edgeguides.rubyonrails.org/)にはEdge Railsガイドの更新版コピーが配置されます。ドキュメントに関する作業として、他にも[Rails wiki](http://newwiki.rubyonrails.org/)の再開やRails Bookの初期構想などがあります。

* 詳しくは[Rails Documentation Projects](http://weblog.rubyonrails.org/2009/1/15/rails-documentation-projects)を参照してください。

Ruby 1.9.1のサポート
------------------

Rails 2.3は、Ruby 1.8や新たにリリースされたRuby 1.9.1で動作するかどうかのテストをすべてパスするはずです。ただし、Ruby 1.9.1に移行する場合、Railsコアと同様、Ruby 1.9.1に依存するデータアダプタやプラグインなどのコードについてももれなくチェックすることになるのをご承知おきください。

Active Record
-------------

Rails 2.3のActive Recordには多くの機能追加とバグ修正が行われました。主要な機能には、ネステッド属性、ネステッドトランザクション、動的かつデフォルトのスコープ、バッチ処理などがあります。

### ネステッド属性（nested attribute）

Active Recordは、ネストしたモデル上の属性を直接更新できるようになりました。たとえば次のような状況だとします。


```ruby
class Book < ActiveRecord::Base
  has_one :author
  has_many :pages

  accepts_nested_attributes_for :author, :pages
end
```

ネステッド属性を有効にすることで、次のようなさまざまなことを行えます: 関連付けられた子とともにレコード1件を自動（かつアトミックに）保存する、子を意識したバリデーション、ネストしたフォームのサポート（後述）などです。

`:reject_if`オプションを用いれば、ネステッド属性を経由して追加されるレコードすべてに条件を指定することもできます。

```ruby
accepts_nested_attributes_for :author,
  :reject_if => proc { |attributes| attributes['name'].blank? }
```

* リードコントリビュータ: [Eloy Duran](http://superalloy.nl/)
* 詳細: [Nested Model Forms](http://weblog.rubyonrails.org/2009/1/26/nested-model-forms)

### ネステッドトランザクション（nested transaction）

多くの方から希望されていたネステッドトランザクションがついにActive Recordでサポートされました。以下のようにトランザクションを書けます。

```ruby
User.transaction do
  User.create(:username => 'Admin')
  User.transaction(:requires_new => true) do
    User.create(:username => 'Regular')
    raise ActiveRecord::Rollback
  end
end

User.find(:all)  # => Adminのみを返す
```

ネステッドトランザクションを用いることで、外側のトランザクションのステートに影響を与えずに内側のトランザクションをロールバックできます。トランザクションをネストしたい場合は、明示的に`:requires_new`オプションを追加しなければなりません。これを行わない場合、現行のRails 2.2と同様、そのトランザクションは単に親トランザクションの一部として動作します。ネステッドトランザクションの内部では[savepoints](http://rails.lighthouseapp.com/projects/8994/tickets/383)を用いているので、真のネステッドトランザクションを搭載していないデータベースでもネステッドトランザクションをサポートします。また、テスト中のトランザクショナルなフィクスチャとネステッドトランザクションが協調動作するよう、若干のマジックが施されています。

* リードコントリビュータ: [Jonathan Viney](http://www.workingwithrails.com/person/4985-jonathan-viney)、[Hongli Lai](http://izumi.plan99.net/blog/)

### 動的スコープ

Railsの動的なfinderメソッド群（`find_by_color_and_flavor`などのメソッドがその場で生えてくる）や、名前付きスコープ（`currently_active`といったわかりやすい名前で再利用可能なクエリ条件をカプセル化する）については皆さま既に御存知かと思います。この度、動的なスコープメソッドを利用できるようになりました。考え方としては、オンザフライのフィルタリング構文とメソッドチェインの「合わせ技」となります。次の例をご覧ください。

```ruby
Order.scoped_by_customer_id(12)
Order.scoped_by_customer_id(12).find(:all,
  :conditions => "status = 'open'")
Order.scoped_by_customer_id(12).scoped_by_status("open")
```

動的なスコープは定義なしでいきなり利用できます。

* リードコントリビュータ: [Yaroslav Markin](http://evilmartians.com/)
* 詳細: [What's New in Edge Rails: Dynamic Scope Methods](http://ryandaigle.com/articles/2008/12/29/what-s-new-in-edge-rails-dynamic-scope-methods.)

### デフォルトスコープ

Rails 2.3で導入された「デフォルトスコープ」記法は名前付きスコープと似ていますが、すべての名前付きスコープやモデル内のfindメソッドに適用される点が異なります。たとえば、`default_scope :order => 'name ASC'`と書くことで、そのモデルからレコードを取り出すたびに結果が常に名前順でソートされます（もちろん、このオプションをオーバーライドすれば別です）。

* リードコントリビュータ: Paweł Kondzior
* 詳細: [What's New in Edge Rails: Default Scoping](http://ryandaigle.com/articles/2008/11/18/what-s-new-in-edge-rails-default-scoping)

### バッチ処理

`find_in_batches`を用いることで、Active Recordのモデルに含まれる多数のレコードを少ないメモリ負荷で処理できるようになりました。

```ruby
Customer.find_in_batches(:conditions => {:active => true}) do |customer_group|
  customer_group.each { |customer| customer.update_account_balance! }
end
```

`find_in_batches`には`find`オプションのほとんどを渡せますが、レコードの戻り順は指定できず（常に主キーの昇順で返され、主キーはintegerでなければなりません）、`:limit`オプションも利用できません。代わりに`:batch_size`オプションを用いてバッチごとに返されるレコード数を設定できます（デフォルトは1000）。

新しい`find_each`メソッドは、個別のレコードを返す`find_in_batches`のラッパーを提供し、find自身はバッチで実行されます（デフォルトは1000）。

```ruby
Customer.find_each do |customer|
  customer.update_account_balance!
end
```

このメソッドはバッチ処理以外では使わないようご注意ください。レコード数が1000未満の小規模な場合は、自分でループを書いて通常のfindメソッドを使うべきです。

* 詳細（この時点では、この便利メソッドは単に`each`という名前でした）
    * [Rails 2.3: Batch Finding](http://afreshcup.com/2009/02/23/rails-23-batch-finding/)
    * [What's New in Edge Rails: Batched Find](http://ryandaigle.com/articles/2009/2/23/what-s-new-in-edge-rails-batched-find)

### コールバックで複数条件を指定する

Active Recordの同じ1つのコールバックで`:if`や`:unless`を組み合わせたり、複数の条件を配列で渡したりできるようになりました。

```ruby
before_save :update_credit_rating, :if => :active,
  :unless => [:admin, :cash_only]
```

* リードコントリビュータ: L. Caviola

### `having`オプションによる検索

Railsのグループ化されたfindでレコードをフィルタするのに、（`has_many`や`has_and_belongs_to_many`と同様に）`:having`オプションが利用できるようになりました。これを用いることで、SQLのベテラン勢にとってお馴染みの、グループ化された結果に基づくフィルタをかけられます。

```ruby
developers = Developer.find(:all, :group => "salary",
  :having => "sum(salary) > 10000", :select => "salary")
```

* リードコントリビュータ: [Emilio Tagua](http://github.com/miloops)

### MySQL接続の再接続機能

MySQLの接続はreconnectフラグをサポートしています。このフラグをtrueにすると、クライアントは接続が失われた場合にサーバーへの再接続を試行します。MySQL接続用の`reconnect = true`を`database.yml`に設定することで、Railsアプリケーションでこの振る舞いを得られます。デフォルトはfalseなので、既存のアプリケーションの振る舞いは変更されません。

* リードコントリビュータ: [Dov Murik](http://twitter.com/dubek)
* 詳細:
    * [Controlling Automatic Reconnection Behavior](http://dev.mysql.com/doc/refman/5.0/en/auto-reconnect.html)
    * [MySQL auto-reconnect revisited](http://groups.google.com/group/rubyonrails-core/browse_thread/thread/49d2a7e9c96cb9f4)

### Active Recordのその他の変更

* `has_and_belongs_to_many`のプリロードで生成されるSQLから余分な`AS`を削除し、一部のデータベースでの動作を改善した
* `ActiveRecord::Base#new_record?`で既存のレコードがある場合に`nil`ではなく`false`を返すようになった
* 一部の`has_many :through`関連付けでテーブル名のクォーテーションのバグが修正された
* `updated_at`タイムスタンプで特定のタイムスタンプを指定できるようになった（`cust = Customer.create(:name => "ABC Industries", :updated_at => 1.day.ago)`など）
* `find_by_attribute!`呼び出しが失敗した場合のエラーメッセージを改善した
* `:camelize`オプションを追加することでActive Recordの`to_xml`サポートの柔軟性を若干向上させた
* `before_update`や`before_create`からのコールバックをキャンセルするときのバグが修正された
* JDBC経由でデータベースをテストするrakeタスクを追加
* `validates_length_of`で`:in`オプションや`:within`オプションを用いてエラーメッセージをカスタマイズできるようになった
* scoped selectのカウントが正常に動作するようになり、`Account.scoped(:select => "DISTINCT credit_limit").count`のように書けるようになった
* `ActiveRecord::Base#invalid?`が`ActiveRecord::Base#valid?`の逆の結果を正しく返すようになった

Action Controller
-----------------

今回のリリースではAction Controllerのレンダリングでいくつかの重要な変更が行われ、ルーティングなどについても改善されました。

### レンダリングの統一

`ActionController::Base#render`はレンダリングの対象を従来よりずっとスマートに決定します。レンダリング対象を`ActionController::Base#render`で指定するだけで正しい結果を期待できます。従来のRailsでは、以下のようにレンダリングに必要な情報を明示的に渡す必要がありました。

```ruby
render :file => '/tmp/random_file.erb'
render :template => 'other_controller/action'
render :action => 'show'
```

Rails 2.3では、レンダリングしたいものを渡すだけでうまくやってくれます。

```ruby
render '/tmp/random_file.erb'
render 'other_controller/action'
render 'show'
render :show
```

Railsは、レンダリング対象に冒頭のスラッシュや中間のスラッシュがあるか、あるいはスラッシュがないかに応じて、ファイル/テンプレート/アクションを適切に選択します。アクションのレンダリングでは文字列の代わりにシンボルを使うこともできることにご注目ください。その他のレンダリングスタイル（`:inline`、`:text`、`:update`、`:nothing`、`:json`、`:xml`、`:js`）については、従来同様の明示的なオプションが必要です。

### Application Controllerファイルがリネームされた

`application.rb`の命名が特殊なせいでつらい思いをしていた皆さまに朗報です。Rails 2.3ではapplication_controller.rbというファイル名に変更されました。さらに`rake rails:update:application_controller`というrakeタスクも追加されましたので、この変更を自動で行うこともできます。このタスクは通常の`rake rails:update`処理の一環としても実行されます。

* 詳細:
    * [The Death of Application.rb](http://afreshcup.com/2008/11/17/rails-2x-the-death-of-applicationrb/)
    * [What's New in Edge Rails: Application.rb Duality is no More](http://ryandaigle.com/articles/2008/11/19/what-s-new-in-edge-rails-application-rb-duality-is-no-more)

### HTTPダイジェスト認証のサポート

RailsにHTTPダイジェスト認証のサポートが組み込まれました。ダイジェスト認証を利用するには、ユーザーのパスワードを返すブロックを`authenticate_or_request_with_http_digest`に渡します（パスワードはハッシュ化された後に、送信されたcredentialと比較されます）。

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
* 詳細: [What's New in Edge Rails: HTTP Digest Authentication](http://ryandaigle.com/articles/2009/1/30/what-s-new-in-edge-rails-http-digest-authentication)

### ルーティングの効率向上

Rails 2.3ではルーティングの重要な変更がいくつも行われました。`formatted_`ルーティングヘルパーは廃止され、今後は`:format`をオプションとして渡すだけでできるようになりました。これによりあらゆるリソースのルーティング生成プロセスが50%も削減され、メモリ使用量も本質的に節約できます（大規模なアプリで最大100MB）。現在のコードで使われている`formatted_`は当面利用可能ですが、この振る舞いは非推奨化されており、ルーティングを新標準に基づいて書き換えることでアプリケーションの効率が高まります。もうひとつ大きな変更は、ルーティングファイルを`routes.rb`以外に複数使えるようになったことです。`RouteSet#add_configuration_file`を用いることでルーティングファイルをいつでも増やせます。その際、現在読み込まれているルーティングをクリアする必要はありません。この変更が最も有用なのはRailsエンジンにおいてですが、ルーティングをバッチで読み込む必要のあるアプリケーションでも利用できます。

* リードコントリビュータ: [Aaron Batalion](http://blog.hungrymachine.com/)

### Rackベースの遅延読み込みセッション

大きな変更のひとつとして、Action ControllerのセッションストレージがRackレベルに落とし込まれました。セッションストレージはRailsアプリケーションから見て完全に透過的になり、コードにもよい効果がもたらされました。おまけに、旧来のCGIセッションハンドラに当てられていた邪魔くさいパッチも取り除けました。この変更は、Rails以外のRackアプリケーションが、同じセッションストレージハンドラにアクセスできるという点において重要です。さらに（Railsフレームワークの他の部分の改善と歩調を合わせて）セッションの読み込みが遅延化されました。つまり、セッションが不要な場合であってもセッションを明示的に無効にする必要がなくなったということです。要らないセッションは参照しなければ読み込まれません。

### MIMEタイプの扱いを変更

RailsのMIMEタイプを扱うコードにもいくつかの変更が行われました。まず、`MIME::Type`に`=~`演算子が実装されたことで、同義語がいくつもあるMIMEタイプが存在するかどうかをチェックするコードをすっきりと書けます。

```ruby
if content_type && Mime::JS =~ content_type
  # 何かクールなことをする
end

Mime::JS =~ "text/javascript"        => true
Mime::JS =~ "application/javascript" => true
```

その他の変更としては、RailsでJavaScriptをさまざまな場所でチェックするときに`Mime::JS`を使うようになったことで、JavaScriptの同義語をすっきりと扱えるようになりました。

* リードコントリビュータ: [Seth Fitzsimmons](http://www.workingwithrails.com/person/5510-seth-fitzsimmons)

### `respond_to`の最適化

RailsチームとMerbチームが合流した最初の成果のひとつとして、`respond_to`メソッドに関するいくつかの最適化がRails 2.3で行われたことが挙げられます。言うまでもなく`respond_to`は多くのRailsアプリケーションで多用されるメソッドであり、コントローラが受け取りリクエストのMIMEタイプに応じて異なるフォーマットで結果を返すのに使われます。`respond_to`から`method_missing`呼び出しを排除してプロファイリングや微調整を行った結果、3種類のフォーマットを切り替えるシンプルな`respond_to`の1秒あたりの処理リクエスト数が8%も改善されました。最も嬉しい点は、皆さんのアプリケーションのコードに一切変更を加えることなくこの高速化のメリットを受けられることです。

### キャッシュのパフォーマンス向上

Railsがリモートキャッシュストアから読み出したリクエスト単位のローカルキャッシュを保持するようになったことで、不要な読み出しを削減してサイトのパフォーマンスを向上させました。当初この成果は`MemCacheStore`限定でしたが、現在は必要なメソッドを実装していればあらゆるリモートストアで利用できます。

* リードコントリビュータ: [Nahum Wild](http://www.motionstandingstill.com/)

### ビューのローカライズ

Railsにビューのローカライズ機能が導入され、設定したロケールに応じてローカライズされたビューを表示できるようになりました。たとえば、`Posts`コントローラに`show`アクションがあるとします。デフォルトでは`app/views/posts/show.html.erb`がレンダリングされますが、`I18n.locale = :da`（デンマーク語）を設定すれば`app/views/posts/show.da.html.erb`がレンダリングされます。該当のローカライズ済みテンプレートが見当たらない場合は、ロケールなしのバージョンが使われます。Railsの`I18n#available_locales`や`I18n::SimpleBackend#available_locales`を使って、現在のRailsプロジェクトで利用可能なロケールのリストを配列で取得することもできます。

さらに、`public`ディレクトリ以下のエラー用ファイルでも同じスキームが使えます（`public/500.da.html`や`public/404.en.html`など）。

### 訳文をパーシャルスコープで使う

翻訳APIの変更によって、訳文のキーをパーシャル（部分テンプレート）に書いて繰り返しを簡単に減らせるようになりました。`translate(".foo")`を`people/index.html.erb`テンプレートから呼び出すと、実際には`I18n.translate("people.index.foo")`が呼び出されます。キーの冒頭にピリオド`.`を付けなければ、従来と同様にAPIはスコープ化されません。

### Action Controllerのその他の変更

* ETagハンドリングが若干クリーンアップされた: 応答にbodyがない場合や`send_file`でファイルを送信する場合にETagヘッダー送信をスキップする
* RailsによるIPスプーフィング攻撃のチェックは、携帯電話からのトラフィックが多いサイトではつらくなる場合がある（携帯電話のプロキシでは一般に正しく設定されないため）。その場合は`ActionController::Base.ip_spoofing_check = false` でチェックを完全に無効にできる。
* `ActionController::Dispatcher`に独自のミドルウェアスタックが実装された（`rake middleware`で確認可能）
* cookieセッションに永続的なセッションidができた（APIはサーバーサイドストアと互換）
* `send_file`や`send_data`の`:type`オプションにシンボルが使えるようになった（例: `send_file("fabulous.png", :type => :png)`）
* `map.resources`の`:only`オプションや`:except`オプションはネストしたリソースを継承しなくなった
* 組み込みのmemcachedクライアントが1.6.4.99にアップデートされた
* `expires_in`メソッド、`stale?`メソッド、`fresh_when`メソッドでプロキシのキャッシュをうまく扱うための`:public`オプションを受け取れるようになった
* `:requirements`オプションが追加のRESTful memberルーティングで正しく動作するようになった
* 浅いルーティング（shallow routes）が名前空間を正しく扱うようになった
* `polymorphic_url`で、不規則な複数形の名前を持つオブジェクトを扱うジョブを改善した

Action View
-----------

Rails 2.3のAction Viewでは、モデルフォームのネスト、`render`の改善、より柔軟な日付選択ヘルパー表示、アセットキャッシュの高速化などを行いました。

### ネステッドオブジェクトのフォーム

親モデルが子オブジェクトのネステッド属性を受け付ける場合（上のActive Recordセクションで解説）、`form_for`や`field_for`を用いることでネストしたフォームを作成できます。フォームのネストはいくらでも深くでき、少ないコードで複雑なオブジェクト階層を1つのビューで編集できるようになります。たとえば以下のようなモデルがあるとします。

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
          <%= order_form.check_box :_delete %>
        </div>
      <% end %>
    </p>
  <% end %>

  <%= customer_form.submit %>
<% end %>
```

* リードコントリビュータ: [Eloy Duran](http://superalloy.nl/)
* 詳細:
    * [Nested Model Forms](http://weblog.rubyonrails.org/2009/1/26/nested-model-forms)
    * [complex-form-examples](http://github.com/alloy/complex-form-examples)
    * [What's New in Edge Rails: Nested Object Forms](http://ryandaigle.com/articles/2009/2/1/what-s-new-in-edge-rails-nested-attributes)

### パーシャルのスマートレンダリング

`render`メソッドは年々賢くなっており、今回もさらに賢くなっています。オブジェクトやコレクションや適切なパーシャル（部分テンプレート）があり、命名法が一致すれば、こうしたオブジェクトなどがレンダリングされます。たとえばRails 2.3のビューでは以下の`render`呼び出しは正常に動作します（Rails wayに沿った命名が前提です）。

```ruby
# 以下と同等
# render :partial => 'articles/_article',
# :object => @article
render @article

# 以下と同等
# render :partial => 'articles/_article',
# :collection => @articles
render @articles
```

* 詳細: [What's New in Edge Rails: render Stops Being High-Maintenance](http://ryandaigle.com/articles/2008/11/20/what-s-new-in-edge-rails-render-stops-being-high-maintenance)

### 日付選択ヘルパーの表示

Rails 2.3では、さまざまな日付選択ヘルパー（`date_select`、`time_select`、`datetime_select`）に、コレクション選択ヘルパーと同様のカスタム表示が提供されています。表示は文字列で与えることも、さまざまなコンポーネントで使える個別の表示文字列のハッシュで与えることもできます。`:prompt`に`true`を設定することで、カスタム表示文字を使えます。
In Rails 2.3, you can supply custom prompts for the various date select helpers (`date_select`, `time_select`, and `datetime_select`), the same way you can with collection select helpers. You can supply a prompt string or a hash of individual prompt strings for the various components. You can also just set `:prompt` to `true` to use the custom generic prompt:

```ruby
select_datetime(DateTime.now, :prompt => true)

select_datetime(DateTime.now, :prompt => "日付と時刻の選択")

select_datetime(DateTime.now, :prompt =>
  {:day => '日付の選択', :month => '月の選択',
   :year => '年の選択', :hour => '時の選択',
   :minute => '分の選択'})
```

* リードコントリビュータ: [Sam Oliver](http://samoliver.com/)

### AssetTagタイムスタンプのキャッシュ

Railsの静的なアセットパスにタイムスタンプを追加する「cache buster」という手法に慣れ親しんでいる方もいらっしゃると思います。これにより、サーバーで画像やスタイルシートが変更されたときにユーザーのブラウザに保存されている古い画像やスタイルシートが使われないようにできます。この設定をAction Viewの`cache_asset_timestamps`設定で変更できるようになりました。このキャッシュを有効にすると、アセットが最初に送信されるときにRailsがタイムスタンプを算出し、その値を保存します。これにより、静的アセットを送信するときにコストの高いファイルシステム呼び出しを削減できますが、その代り、サーバー実行中にアセットを変更してもクライアント側に変更が反映されることは期待できなくなります。

### オブジェクトとしてのアセットホスト

edge Railsのアセットホストがより柔軟になり、アセットホストを、呼び出しに応答する特定のオブジェクトとして宣言できるようになりました。これにより、アセットのホスティングで必要となる複雑なロジックをいくらでも実装できるようになります。

* 詳細: [asset-hosting-with-minimum-ssl](http://github.com/dhh/asset-hosting-with-minimum-ssl/tree/master)

### grouped_options_for_selectヘルパーメソッド

Action Viewには、セレクトボックスの生成などを支援するヘルパーが多数含まれていますが、新たに`grouped_options_for_select`ヘルパーが加わりました。このヘルパーは、以下のように文字列の配列またはハッシュを1つ受け取り、`optgroup`タグで囲まれた`option`タグの文字列に変換します。

```ruby
grouped_options_for_select([["Hats", ["Baseball Cap","Cowboy Hat"]]],
  "Cowboy Hat", "Choose a product...")
```

上は以下を出力します。

```ruby
<option value="">Choose a product...</option>
<optgroup label="Hats">
  <option value="Baseball Cap">Baseball Cap</option>
  <option selected="selected" value="Cowboy Hat">Cowboy Hat</option>
</optgroup>
```

### フォームのセレクトボックスヘルパーの`:disabled`オプション

フォームのセレクトボックスヘルパー（`select`や`options_for_select`など）で`:disabled`オプションがサポートされました。これは単独の値や値の配列を受け取って、無効にするタグを指定します。

```ruby
select(:post, :category, Post::CATEGORIES, :disabled => 'private')
```

上は以下を出力します。

```html
<select name="post[category]">
<option>story</option>
<option>joke</option>
<option>poem</option>
<option disabled="disabled">private</option>
</select>
```

以下のように無名関数を使って、コレクションのどのオプションを選択済みにするか無効にするかを実行時に決定することもできます。

```ruby
options_from_collection_for_select(@product.sizes, :name, :id, :disabled => lambda{|size| size.out_of_stock?})
```

* リードコントリビュータ: [Tekin Suleyman](http://tekin.co.uk/)
* 詳細: [New in rails 2.3 - disabled option tags and lambdas for selecting and disabling options from collections](http://tekin.co.uk/2009/03/new-in-rails-23-disabled-option-tags-and-lambdas-for-selecting-and-disabling-options-from-collections/)

### 追記: テンプレート読み込みについて

Rails 2.3では、キャッシュされたテンプレートを特定の環境で有効または無効にする機能があります。キャッシュされたテンプレートではレンダリング時にテンプレートファイルが新しいかどうかをチェックしないので高速になりますが、サーバーを再起動しないとテンプレートを即座に更新できなくなるということでもあります。

production環境では、ほとんどの場合テンプレートキャッシュを有効にしておきたいのが普通なので、 `production.rb`に以下のように書くことで設定できます。

```ruby
config.action_view.cache_template_loading = true
```

Rails 2.3の新しいアプリケーションでは上の行が自動生成されます。以前のバージョンのRailsからアップグレードする場合は、production環境とtest環境ではテンプレートのキャッシュはデフォルトで有効になりますが、development環境ではデフォルトで有効になりません。

### Action Viewのその他の変更

* CSRF保護用のトークン生成方法がシンプルになった: セッションIDをこねこねする方法ではなく、`ActiveSupport::SecureRandom`で生成されるランダム文字列を使うようになった
* 生成されたメールのリンクで`auto_link`のオプション（`:target`や`:class`など）が正しく適用されるようになった
* `autolink`ヘルパーがリファクタリングされて使いにくさが軽減され、より直感的になった
* `current_page?`のURLにクエリパラメータが複数ある場合にも正しく動作するようになった

Active Support
--------------

Active Support has a few interesting changes, including the introduction of `Object#try`.

### Object#try

A lot of folks have adopted the notion of using try() to attempt operations on objects. It's especially helpful in views where you can avoid nil-checking by writing code like `<%= @person.try(:name) %>`. Well, now it's baked right into Rails. As implemented in Rails, it raises `NoMethodError` on private methods and always returns `nil` if the object is nil.

* 詳細: [try()](http://ozmm.org/posts/try.html.)

### Object#tap Backport

`Object#tap` is an addition to [Ruby 1.9](http://www.ruby-doc.org/core-1.9/classes/Object.html#M000309) and 1.8.7 that is similar to the `returning` method that Rails has had for a while: it yields to a block, and then returns the object that was yielded. Rails now includes code to make this available under older versions of Ruby as well.

### Swappable Parsers for XMLmini

The support for XML parsing in Active Support has been made more flexible by allowing you to swap in different parsers. By default, it uses the standard REXML implementation, but you can easily specify the faster LibXML or Nokogiri implementations for your own applications, provided you have the appropriate gems installed:

```ruby
XmlMini.backend = 'LibXML'
```

* リードコントリビュータ: [Bart ten Brinke](http://www.movesonrails.com/)
* リードコントリビュータ: [Aaron Patterson](http://tenderlovemaking.com/)

### Fractional seconds for TimeWithZone

The `Time` and `TimeWithZone` classes include an `xmlschema` method to return the time in an XML-friendly string. As of Rails 2.3, `TimeWithZone` supports the same argument for specifying the number of digits in the fractional second part of the returned string that `Time` does:

```ruby
>> Time.zone.now.xmlschema(6)
=> "2009-01-16T13:00:06.13653Z"
```

* リードコントリビュータ: [Nicholas Dainty](http://www.workingwithrails.com/person/13536-nicholas-dainty)

### JSON Key Quoting

If you look up the spec on the "json.org" site, you'll discover that all keys in a JSON structure must be strings, and they must be quoted with double quotes. Starting with Rails 2.3, we do the right thing here, even with numeric keys.

### Other Active Support Changes

* You can use `Enumerable#none?` to check that none of the elements match the supplied block.
* If you're using Active Support [delegates](http://afreshcup.com/2008/10/19/coming-in-rails-22-delegate-prefixes/,) the new `:allow_nil` option lets you return `nil` instead of raising an exception when the target object is nil.
* `ActiveSupport::OrderedHash`: now implements `each_key` and `each_value`.
* `ActiveSupport::MessageEncryptor` provides a simple way to encrypt information for storage in an untrusted location (like cookies).
* Active Support's `from_xml` no longer depends on XmlSimple. Instead, Rails now includes its own XmlMini implementation, with just the functionality that it requires. This lets Rails dispense with the bundled copy of XmlSimple that it's been carting around.
* If you memoize a private method, the result will now be private.
* `String#parameterize` accepts an optional separator: `"Quick Brown Fox".parameterize('_') => "quick_brown_fox"`.
* `number_to_phone` accepts 7-digit phone numbers now.
* `ActiveSupport::Json.decode` now handles `\u0000` style escape sequences.

Railties
--------

上述のRackの変更に加えて、Railties（Rails自身のコアなコード）にも、Rails Metalやアプリケーションテンプレート、Quiet Backtraceなどの重要な変更が行われました。

### Rails Metal

Rails Metalは、Railsアプリケーション内部に高速なエンドポイントを提供する新しいメカニズムです。Metalクラスはルーティングをバイパスして、Action Controllerの「本来の速度」を得られるようにします（もちろんAction Controllerで行われるすべての処理を含みます）。このメカニズムは、公開されたミドルウェアスタックを持つRackアプリケーションとしてRailsを動かすためにここ最近行われてた根本的な作業すべての上に構築されています。Metalのエンドポイントはアプリケーションやプラグインから読み込めます。

* 詳細:
    * [Introducing Rails Metal](http://weblog.rubyonrails.org/2008/12/17/introducing-rails-metal)
    * [Rails Metal: a micro-framework with the power of Rails](http://soylentfoo.jnewland.com/articles/2008/12/16/rails-metal-a-micro-framework-with-the-power-of-rails-m)
    * [Metal: Super-fast Endpoints within your Rails Apps](http://www.railsinside.com/deployment/180-metal-super-fast-endpoints-within-your-rails-apps.html)
    * [What's New in Edge Rails: Rails Metal](http://ryandaigle.com/articles/2008/12/18/what-s-new-in-edge-rails-rails-metal)

### アプリケーションテンプレート

Rails 2.3には、Jeremy McAnally作の[rg](http://github.com/jeremymcanally/rg/tree/master)アプリケーションジェネレータを用いています。rgの意義は、アプリケーションをテンプレートベースで生成する機能がRailsに組み込まれたということです。使いみちはさまざまですが、たとえばどのアプリケーションにも入れておきたいプラグインのセットがある場合、テンプレートを一度セットアップしておけば`rails`コマンドを実行するたびにテンプレートを何度でも利用できるようになります。次のように、既存のアプリケーションにテンプレートを適用するためのrakeタスクもあります。

```
rake rails:template LOCATION=~/template.rb
```

上を実行すると、このテンプレートによる変更が、既存のプロジェクトに含まれているあらゆるコードの上にレイヤーとして追加されます。

* リードコントリビュータ: [Jeremy McAnally](http://www.jeremymcanally.com/)
* More Info:[Rails templates](http://m.onkey.org/2008/12/4/rails-templates)

### Quiet Backtrace

Thoughtbotによる[Quiet Backtrace](https://github.com/thoughtbot/quietbacktrace)プラグイン

Building on Thoughtbot's [Quiet Backtrace](https://github.com/thoughtbot/quietbacktrace) plugin, which allows you to selectively remove lines from `Test::Unit` backtraces, Rails 2.3 implements `ActiveSupport::BacktraceCleaner` and `Rails::BacktraceCleaner` in core. This supports both filters (to perform regex-based substitutions on backtrace lines) and silencers (to remove backtrace lines entirely). Rails automatically adds silencers to get rid of the most common noise in a new application, and builds a `config/backtrace_silencers.rb` file to hold your own additions. This feature also enables prettier printing from any gem in the backtrace.

### Faster Boot Time in Development Mode with Lazy Loading/Autoload

Quite a bit of work was done to make sure that bits of Rails (and its dependencies) are only brought into memory when they're actually needed. The core frameworks - Active Support, Active Record, Action Controller, Action Mailer and Action View - are now using `autoload` to lazy-load their individual classes. This work should help keep the memory footprint down and improve overall Rails performance.

You can also specify (by using the new `preload_frameworks` option) whether the core libraries should be autoloaded at startup. This defaults to `false` so that Rails autoloads itself piece-by-piece, but there are some circumstances where you still need to bring in everything at once - Passenger and JRuby both want to see all of Rails loaded together.

### rake gem Task Rewrite

The internals of the various <code>rake gem</code> tasks have been substantially revised, to make the system work better for a variety of cases. The gem system now knows the difference between development and runtime dependencies, has a more robust unpacking system, gives better information when querying for the status of gems, and is less prone to "chicken and egg" dependency issues when you're bringing things up from scratch. There are also fixes for using gem commands under JRuby and for dependencies that try to bring in external copies of gems that are already vendored.

* リードコントリビュータ: [David Dollar](http://www.workingwithrails.com/person/12240-david-dollar)

### Other Railties Changes

* The instructions for updating a CI server to build Rails have been updated and expanded.
* Internal Rails testing has been switched from `Test::Unit::TestCase` to `ActiveSupport::TestCase`, and the Rails core requires Mocha to test.
* The default `environment.rb` file has been decluttered.
* The dbconsole script now lets you use an all-numeric password without crashing.
* `Rails.root` now returns a `Pathname` object, which means you can use it directly with the `join` method to [clean up existing code](http://afreshcup.com/2008/12/05/a-little-rails_root-tidiness/) that uses `File.join`.
* Various files in /public that deal with CGI and FCGI dispatching are no longer generated in every Rails application by default (you can still get them if you need them by adding `--with-dispatchers` when you run the `rails` command, or add them later with `rake rails:update:generate_dispatchers`).
* Rails Guides have been converted from AsciiDoc to Textile markup.
* Scaffolded views and controllers have been cleaned up a bit.
* `script/server` now accepts a <tt>--path</tt> argument to mount a Rails application from a specific path.
* If any configured gems are missing, the gem rake tasks will skip loading much of the environment. This should solve many of the "chicken-and-egg" problems where rake gems:install couldn't run because gems were missing.
* Gems are now unpacked exactly once. This fixes issues with gems (hoe, for instance) which are packed with read-only permissions on the files.

Deprecated
----------

A few pieces of older code are deprecated in this release:

* If you're one of the (fairly rare) Rails developers who deploys in a fashion that depends on the inspector, reaper, and spawner scripts, you'll need to know that those scripts are no longer included in core Rails. If you need them, you'll be able to pick up copies via the [irs_process_scripts](http://github.com/rails/irs_process_scripts/tree) plugin.
* `render_component` goes from "deprecated" to "nonexistent" in Rails 2.3. If you still need it, you can install the [render_component plugin](http://github.com/rails/render_component/tree/master).
* Support for Rails components has been removed.
* If you were one of the people who got used to running `script/performance/request` to look at performance based on integration tests, you need to learn a new trick: that script has been removed from core Rails now. There's a new request_profiler plugin that you can install to get the exact same functionality back.
* `ActionController::Base#session_enabled?` is deprecated because sessions are lazy-loaded now.
* The `:digest` and `:secret` options to `protect_from_forgery` are deprecated and have no effect.
* Some integration test helpers have been removed. `response.headers["Status"]` and `headers["Status"]` will no longer return anything. Rack does not allow "Status" in its return headers. However you can still use the `status` and `status_message` helpers. `response.headers["cookie"]` and `headers["cookie"]` will no longer return any CGI cookies. You can inspect `headers["Set-Cookie"]` to see the raw cookie header or use the `cookies` helper to get a hash of the cookies sent to the client.
* `formatted_polymorphic_url` is deprecated. Use `polymorphic_url` with `:format` instead.
* The `:http_only` option in `ActionController::Response#set_cookie` has been renamed to `:httponly`.
* The `:connector` and `:skip_last_comma` options of `to_sentence` have been replaced by `:words_connnector`, `:two_words_connector`, and `:last_word_connector` options.
* Posting a multipart form with an empty `file_field` control used to submit an empty string to the controller. Now it submits a nil, due to differences between Rack's multipart parser and the old Rails one.

Credits
-------

Release notes compiled by [Mike Gunderloy](http://afreshcup.com.) This version of the Rails 2.3 release notes was compiled based on RC2 of Rails 2.3.