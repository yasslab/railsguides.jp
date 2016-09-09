
アセットパイプライン
==================

本ガイドでは、アセットパイプライン (asset pipeline) について解説します。

このガイドの内容:

* アセットパイプラインの概要と機能
* アプリケーションのアセットを正しく編成する方法
* アセットパイプラインのメリット
* アセットパイプラインにプリプロセッサを追加する
* アセットをgemパッケージにする

--------------------------------------------------------------------------------

アセットパイプラインについて
---------------------------

アセットパイプラインとは、JavaScriptやCSSのアセットを最小化 (minify: スペースや改行を詰めるなど) または圧縮して連結するためのフレームワークです。アセットパイプラインでは、CoffeeScriptやSASS、ERBなど他の言語で記述されたアセットを作成する機能を追加することもできます。

技術的には、アセットパイプラインは既にRails 4のコア機能ではありません。フレームワークから分離され、[sprockets-rails](https://github.com/rails/sprockets-rails)というgemに書き出されています。

Railsではデフォルトでアセットパイプラインが有効になっています。

Railsアプリケーションを新規作成する際にアセットパイプラインをオフにしたい場合は、以下のように`--skip-sprockets`オプションを渡します。

```bash
rails new appname --skip-sprockets
```

Rails 4では`sass-rails`、`coffee-rails`、`uglifier` gemが自動的にGemfileに追加されます。Sprocketsはアセット圧縮の際にこれらのgemを使用します。

```ruby
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
```

`--skip-sprockets`オプションを使用すると、Rails 4で`sass-rails`と`uglifier`がGemfileに追加されなくなります。アセットパイプラインを後から有効にしたい場合は、これらのgemもGemfileに追加する必要があります。同様に、アプリケーション新規作成時に`--skip-sprockets`オプションを指定すると`config/application.rb`ファイルの記述内容がデフォルトから若干異なります。具体的にはsprocket railtieで必要となる記述がコメントアウトされます。アセットパイプラインを手動で有効にする場合は、これらのコメントアウトも解除する必要があります。

```ruby
# require "sprockets/railtie"
```

アセット圧縮方式を指定するには、`production.rb`の該当する設定オプションを設定します。`config.assets.css_compressor`はCSSの圧縮方式、`config.assets.js_compressor`はJavaScriptの圧縮方式をそれぞれ指定します。

```ruby
config.assets.css_compressor = :yui
config.assets.js_compressor = :uglifier
```

NOTE: `sass-rails` gemがGemfileに含まれていれば自動的にCSS圧縮に使用されます。この場合`config.assets.css_compressor`オプションは設定されません。


### 主要な機能

アセットパイプラインの第一の機能はアセットを連結することです。これにより、ブラウザがWebページをレンダリングするためのリクエスト数を減らすことができます。Webブラウザが同時に処理できるリクエスト数には限りがあるため、同時リクエスト数を減らすことができればその分読み込みが高速になります。

SprocketsはすべてのJavaScriptファイルを1つのマスター`.js`ファイルに連結し、すべてのCSSファイルを1つのマスター`.css`ファイルに連結します。本ガイドで後述するように、アセットファイルをグループ化する方法は自由にカスタマイズできます。production環境では、アセットファイル名にMD5フィンガープリントを挿入し、アセットファイルがWebブラウザでキャッシュされるようにしています。このフィンガープリントを変更することでブラウザでキャッシュされていた既存のアセットを無効にすることができます。フィンガープリントの変更は、アセットファイルの内容が変更された時に自動的に行われます。

アセットパイプラインのもうひとつの機能はアセットの最小化 (一種の圧縮) です。CSSファイルの最小化は、ホワイトスペースとコメントを削除することによって行われます。JavaScriptの最小化プロセスはもう少し複雑です。最小化方法はビルトインのオプションから選んだり、独自に指定したりすることができます。

アセットパイプラインの第3の機能は、より高級な言語を使用したコーディングのサポートです。これらの言語で記述されたコードはプリコンパイルされ、実際のアセットになります。デフォルトでサポートされている言語は、CSSに代わるSASS、JavaScriptに代わるCoffeeScript、CSS/JavaScriptに代わるERBです。

### フィンガープリントと注意点

アセットファイル名で使用されるフィンガープリントは、アセットファイルの内容に応じて変わります。アセットファイルの内容が少しでも変わると、アセットファイル名も必ずそれに応じて変わります (訳注: MD5の性質により、異なるファイルからたまたま同じフィンガープリントが生成されることはほぼありません)。変更されていないファイルやめったに変更されないファイルがある場合、フィンガープリントも変化しないので、ファイルの内容が完全に同一であることが容易に確認できます。これはサーバーやデプロイ日が異なっていても有効です。

アセットファイル名は内容が変わると必ず変化するので、CDN、ISP、ネットワーク機器、Webブラウザなどあらゆる場面で有効なキャッシュをHTTPヘッダに設定することができます。ファイルの内容が更新されると、フィンガープリントも更新されます。これにより、リモートクライアントは (訳注: 既存のキャッシュを使用せずに) コンテンツの新しいコピーをサーバーにリクエストします。この手法を一般に _キャッシュ破棄 (cache busting)_ と呼びます。

Sprocketsがフィンガープリントを使用する際には、ファイルの内容をハッシュ化したものをファイル名 (通常は末尾) に追加します。たとえば、`global.css`というCSSファイル名は以下のようになります。

```
global-908e25f4bf641868d8683022a5b62f54.css
```

これはRailsのアセットパイプラインの戦略として採用されています。

以前のRailsでは、ビルトインのヘルパーにリンクされているすべてのアセットに日付ベースのクエリ文字列を追加するという戦略が使用されていました。当時のソースで生成されたコードは以下のようになります。

```
/stylesheets/global.css?1309495796
```

このクエリ文字列ベースの戦略には多くの問題点があります。

1. **クエリパラメータ以外にファイル名に違いのないコンテンツは確実にキャッシュされないことがある**

    [Steve Soudersのブログ記事](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)によると、「キャッシュされる可能性のあるリソースにクエリ文字列でアクセスするのは避けること」が推奨されています。Steveは、5%から20%ものリクエストがキャッシュされていないことに気付きました。クエリ文字列は、キャッシュ無効化が発生する一部のCDNでは役に立ちません。

2. **マルチサーバー環境でファイル名が異なってしまうことがある**

    Rails 2.xのデフォルトのクエリ文字列はファイルの更新日付に基いていました。このアセットをサーバークラスタにデプロイすると、サーバー間でファイルのタイムスタンプが同じになる保証がないため、リクエストを受けるサーバーが変わるたびに値が異なってしまいます。

3. **キャッシュの無効化が過剰に発生する**

    コードリリース時のデプロイが行われると、アセットに変更があるかどうかにかかわらず _すべての_ ファイルのmtime (最後に更新された時刻) が変更されてしまいます。このため、アセットに変更がなくてもWebブラウザを含むあらゆるリモートクライアントで強制的にアセットが再取得されてしまいます。

フィンガープリントが導入されたことによって上述のクエリ文字列による問題点が解決され、アセットの内容が同じであればファイル名も常に同じになるようになりました。

フィンガープリントはproduction環境ではデフォルトでオンになっており、それ以外の環境ではオフになります。設定ファイルで`config.assets.digest`オプションを使用してフィンガープリントのオン/オフを制御できます。

詳細については以下を参照してください。

* [キャッシュの最適化](http://code.google.com/speed/page-speed/docs/caching.html)
* [ファイル名の変更にクエリ文字列を使用してはいけない理由](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)


アセットパイプラインの使用方法
-----------------------------

以前のRailsでは、すべてのアセットは`public`ディレクトリの下の`images`、`javascripts`、`stylesheets`などのサブフォルダに置かれました。アセットパイプライン導入後は、`app/assets`ディレクトリがアセットの置き場所として推奨されています。このディレクトリに置かれたファイルはSprocketsミドルウェアによってサポートされます。

アセットは引き続き`public`ディレクトリ以下に置くことも可能です。`config.serve_static_files`がtrueに設定されていると、`public`ディレクトリ以下に置かれているあらゆるアセットはアプリケーションまたはWebサーバーによって静的なファイルとして取り扱われます。プリプロセスが必要なファイルは`app/assets`ディレクトリの下に置く必要があります。

Railsは、productionモードではデフォルトで`public/assets`ファイルをプリコンパイルします。このプリコンパイルされたファイルがWebサーバーによって静的なアセットとして扱われます。`app/assets`に置かれたファイルがそのままの形でproduction環境で使用されることは決してありません。

### コントローラ固有のアセット

Railsでscaffoldやコントローラを生成すると、JavaScriptファイル (`coffee-rails` gemが`Gemfile`で有効になっている場合はCoffeeScript) とCSS (`sass-rails` gemが`Gemfile`で有効になっている場合はSCSS) もそのコントローラ用に生成されます。scaffold生成時には、さらにscaffolds.css (`sass-rails` gemが`Gemfile`で有効になっている場合はscaffolds.css.scss) も生成されます。

たとえば`ProjectsController`を生成すると、`app/assets/javascripts/projects.js.coffee`ファイルと`app/assets/stylesheets/projects.css.scss`ファイルが新しく作成されます。`require_tree`ディレクティブを使用すると、これらのファイルを即座にアプリケーションから利用できます。require_treeの詳細については[マニフェストファイルとディレクティブ](#マニフェストファイルとディレクティブ)を参照してください。

関連するコントローラで以下のコードを使用することで、コントローラ固有のスタイルシートやJavaScriptファイルをそのコントローラだけで使用できます。

`<%= javascript_include_tag params[:controller] %>` または `<%= stylesheet_link_tag params[:controller] %>`

上のコードを使用する際は、`require_tree`ディレクティブを使用していないことを必ず確認してください。`require_tree`と併用すると、アセットが2回以上インクルードされてしまいます。

WARNING: アセットのプリコンパイルを使用する場合、ページが読み込まれるたびにコントローラのアセットがプリコンパイルされるようにしておく必要があります。デフォルトでは、.coffeeファイルと.scssファイルは自動ではプリコンパイルされません。プリコンパイルの動作の詳細については、[アセットをプリコンパイルする](#アセットをプリコンパイルする)を参照してください。

NOTE: CoffeeScriptを使用するには、ExecJSがランタイムでサポートされている必要があります。Mac OS XまたはWindowsを使用している場合は、OSにJavaScriptランタイムをインストールしてください。サポートされているすべてのJavaScriptランタイムに関するドキュメントは、[ExecJS](https://github.com/sstephenson/execjs#readme) で参照できます。

`config/application.rb`設定に以下を追加することで、コントローラ固有のアセットファイル生成を止めることもできます。

```ruby
config.generators do |g|
  g.assets false
end 
```

### アセットの編成

パイプラインのアセットは、アプリケーション内の`app/assets`、`lib/assets`、`vendor/assets`の3つのディレクトリのいずれかに置くことができます。

* `app/assets`は、カスタム画像ファイル、JavaScript、スタイルシートなど、アプリケーション自身が保有するアセットの置き場所です。

* `lib/assets`は、1つのアプリケーションの範疇に収まらないライブラリのコードや、複数のアプリケーションで共有されるライブラリのコードを置く場所です。

* `vendor/assets`は、JavaScriptプラグインやCSSフレームワークなど、外部の団体などによって所有されているアセットの置き場所です。

WARNING: Rails 3からのアップグレードを行なう際には、`lib/assets`と`vendor/assets`の下に置かれているアセットがRails 4ではアプリケーションのマニフェストによってインクルードされて利用可能になること、しかしプリコンパイル配列の一部には含まれなくなることを考慮に入れてください。ガイダンスについては[アセットをプリコンパイルする](#アセットをプリコンパイルする)を参照してください。

#### パスの検索

ファイルがマニフェストやヘルパーから参照される場合、Sprocketsはデフォルトのアセットの置き場所である3つのディレクトリからファイルを探します。

3つのディレクトリとは、`app/assets`の下にある`images`、`javascripts`、`stylesheets`ディレクトリです。ただしこれらのサブディレクトリは特殊なものではなく、実際には`assets/*`以下のすべてのパスが検索対象になります。

以下のファイルを例に説明します。

```
app/assets/javascripts/home.js
lib/assets/javascripts/moovinator.js
vendor/assets/javascripts/slider.js
vendor/assets/somepackage/phonebox.js
```

上のファイルはマニフェスト内で以下のように参照されます。

```js
//= require home
//= require moovinator
//= require slider
//= require phonebox
```

サブディレクトリ内のアセットにもアクセスできます。

```
app/assets/javascripts/sub/something.js
```

上のファイルは以下のように参照されます。

```js
//= require sub/something
```

検索パスを調べるには、Railsコンソールで`Rails.application.config.assets.paths`を調べます。

`config/application.rb`に記述することで、標準の`assets/*`に加えて追加の (fully qualified) パスをパイプラインに追加することができます。以下の例で説明します。

```ruby
config.assets.paths << Rails.root.join("lib", "videoplayer", "flash")
```

パスの探索は、検索パスでの出現順で行われます。デフォルトでは`app/assets`の検索が優先されるので、対応するパスが`lib`や`vendor`にある場合はマスクされます。

ここでご注意いただきたいのは、参照したいファイルがマニフェストの外にある場合は、それらをプリコンパイル配列に追加しなければならないという点です。追加しない場合、production環境で利用することができなくなります。

#### indexファイルを使用する

Sprocketsでは、`index`という名前のファイル (および関連する拡張子) を特殊な目的に使用します。

たとえば、たくさんのモジュールがあるjQueryライブラリを使用していて、それらが`lib/assets/javascripts/library_name`に保存されているとします。この`lib/assets/javascripts/library_name/index.js`ファイルはそのライブラリ内のすべてのファイルで利用できるマニフェストとして機能します。このファイルには必要なファイルをすべて順に記述するか、あるいは単に`require_tree`と記述します。

一般に、このライブラリはアプリケーションマニフェストに以下のように記述することでアクセスできます。

```js
//= require library_name
```

このように記述することで、他でインクルードする前に関連するコードをグループ化できるようになり、記述が簡潔になり保守がしやすくなります。

### アセットにリンクするコードを書く

Sprocketsはアセットにアクセスするためのメソッドを特に追加しません。従来同様`javascript_include_tag`と`stylesheet_link_tag`を使用します。

```erb
<%= stylesheet_link_tag "application", media: "all" %>
<%= javascript_include_tag "application" %>
```

Rails 4から同梱されるようになったturbolinks gemを使用している場合、'data-turbolinks-track'オプションが利用できます。これはアセットが更新されてページに読み込まれたかどうかをturbolinksがチェックします。

```erb
<%= stylesheet_link_tag "application", media: "all", "data-turbolinks-track" => true %>
<%= javascript_include_tag "application", "data-turbolinks-track" => true %>
```

通常のビューでは以下のような方法で`public/assets/images`ディレクトリの画像にアクセスできます。

```erb
<%= image_tag "rails.png" %>
```

パイプラインが有効でかつ現在の環境で無効になっていない場合、このファイルはSprocketsによって扱われます。ファイルが`public/assets/rails.png`に置かれている場合、Webサーバーによって扱われます。

`public/assets/rails-af27b6a414e6da00003503148be9b409.png`など、ファイル名にMD5ハッシュを含むファイルへのリクエストについても同様に扱われます。ハッシュの生成法については、本ガイドの[production環境の場合](#production環境の場合)で後述します。

Sprocketsは`config.assets.paths`で指定したパスも探索します。このパスには、標準的なアプリケーションパスと、Railsエンジンによって追加されるすべてのパスが含まれます。

必要であれば画像ファイルをサブディレクトリに置いて整理することもできます。この画像にアクセスするには、ディレクトリ名を含めて以下のようにタグで指定します。

```erb
<%= image_tag "icons/rails.png" %>
```

WARNING: アセットのプリコンパイルを行っている場合 ([production環境の場合](#production環境の場合)参照)、存在しないアセットへのリンクを含むページを呼び出すと例外が発生します。空文字へのリンクも同様に例外が発生します。ユーザーから提供されたデータに対して`image_tag`などのヘルパーを使用する場合はご注意ください。

#### CSSとERB 

アセットパイプラインは自動的にERBを評価します。たとえば、cssアセットファイルに`erb`という拡張子を追加すると (`application.css.erb`など)、CSSルール内で`asset_path`などのヘルパーが使用できるようになります。

```css
.class { background-image: url(<%= asset_path 'image.png' %>) }
```

これは、指定されたアセットへのパスを記述します。上の例では、アセット読み込みパスのいずれかにある画像ファイル (`app/assets/images/image.png`など) が指定されたと解釈されます。この画像が既にフィンガープリント付きで`public/assets`にあれば、このパスによる参照は有効になります。

[データURIスキーム](http://ja.wikipedia.org/wiki/Data_URI_scheme) (CSSファイルにデータを直接埋め込む手法) を使用したい場合は、`asset_data_uri`を使用できます。

```css
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

上のコードは、CSSソースに正しくフォーマットされたdata URIを挿入します。

この場合、`-%>`でタグを閉じることはできませんのでご注意ください。

#### CSSとSass

アセットパイプラインを使用する場合、最終的にアセットへのパスを変換する必要があります。このために、`sass-rails` gemは名前が`-url`や`-path`で終わる (Sass内ではハイフンですが、Rubyではアンダースコアで表します) 各種ヘルパーを提供しています。ヘルパーがサポートするアセットクラスは、画像、フォント、ビデオ、音声、JavaScript、stylesheetです。

* `image-url("rails.png")`は`url(/assets/rails.png)`に変換される
* `image-path("rails.png")`は`"/assets/rails.png"`に変換される

以下のような、より一般的な記法を使用することもできます。

* `asset-url("rails.png")`は`url(/assets/rails.png)`に変換される
* `asset-path("rails.png")`は`"/assets/rails.png"`に変換される

#### JavaScript/CoffeeScriptとERB

JavaScriptアセットに`erb`拡張子を追加すると (`application.js.erb`など)、以下のようにJavaScriptコード内で`asset_path`ヘルパーを使用できます。

```js
$('#logo').attr({ src: "<%= asset_path('logo.png') %>" });
```

これは、指定されたアセットへのパスを記述します。

CoffeeScriptファイルでも、`application.js.coffee.erb`のように`erb`拡張子を追加することで同様に`asset_path`ヘルパーを使用できます。

```js
$('#logo').attr src: "<%= asset_path('logo.png') %>"
```

### マニフェストファイルとディレクティブ

Sprocketsでは、どのアセットをインクルードしてサポートするかを指定するのにマニフェストファイルを使用します。マニフェストファイルには _ディレクティブ (directive: 命令、指示)_ を含めます。ディレクティブを使用して必要なファイルを指定し、それに基いて最終的に単一のCSSやJavaScriptファイルがビルドされます。Sprocketsはディレクティブで指定されたファイルを読み込み、必要に応じて処理を行い、連結して単一のファイルを生成し、圧縮します (`Rails.application.config.assets.compress`がtrueの場合)。ファイルを連結してひとつにすることにより、ブラウザからサーバーへのリクエスト数を減らすことができ、ページの読み込み時間が大きく短縮されます。圧縮することによってもファイルサイズが小さくなり、ブラウザへの読み込み時間が短縮されます。


新規作成したRails 4アプリケーションにはデフォルトで`app/assets/javascripts/application.js`ファイルに以下のような記述が含まれています。

```js
// ...
//= require jquery
//= require jquery_ujs
//= require_tree .
```

JavaScriptのSprocketsディレクティブは`//=`で始まります。上の例では`require`と`require_tree`というディレクティブが使用されています。`require`は、必要なファイルをSprocketsに指定するのに使用します。ここでは`jquery.js`と`jquery_ujs.js`を必要なファイルとして指定しています。これらのファイルはSprocketsの検索パスのどこかから読み込み可能になっています。このディレクティブでは拡張子を明示的に指定する必要はありません。ディレクティブが`.js`ファイルに書かれていれば、Sprocketsによって自動的に`.js`ファイルが必要ファイルとして指定されます。

`require_tree`ディレクティブは、指定されたディレクトリ以下の _すべての_ JavaScriptファイルを再帰的にインクルードし、出力に含めます。このパスは、マニフェストファイルからの相対パスとして指定する必要があります。`require_directory`ディレクティブを使用すると、指定されたディレクトリの直下にあるすべてのJavaScriptファイルのみをインクルードします。この場合サブディレクトリを再帰的に探索しません。

ディレクティブは記載した順に実行されますが、`require_tree`でインクルードされるファイルの読み込み順序は指定できません。従って、特定の読み込み順に依存しないようにする必要があります。もしどうしても特定のJavaScriptファイルを他のJavaScriptファイルよりも結合順を先にしたい場合、そのファイルへのrequireディレクティブをマニフェストの最初に置きます。`require`および類似のディレクティブは、出力時に同じファイルを2回以上インクルードしないようになっています。

Railsは以下の行を含むデフォルトの`app/assets/stylesheets/application.css`ファイルも作成します。

```css
/* ...
*= require_self
*= require_tree .
*/
```

Rails 4は`app/assets/javascripts/application.js`と`app/assets/stylesheets/application.css`ファイルを両方作成します。これはRailsアプリケーション新規作成時に--skip-sprocketsを指定するかどうかにかかわらず行われます。これにより、必要に応じて後からアセットパイプラインを追加することもできます。

JavaScriptで使用できるディレクティブはスタイルシートでも使用できます (なおJavaScriptと異なりスタイルシートは明示的にインクルードされるという違いがあります)。CSSマニフェストにおける`require_tree`ディレクティブの動作はJavaScriptの場合と同様に現在のディレクトリにあるすべてのスタイルシートをrequireします。

上の例では`require_self`が使用されています。このディレクティブは、`require_self`呼び出しが行われたその場所にCSSファイルがあれば読み込みます。

NOTE: Sassファイルを複数使用しているのであれば、Sprocketsディレクティブで読み込まずに[Sass `@import`ルール](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#import)を使用する必要があります。このような場合にSprocketsディレクティブを使用してしまうと、Sassファイルが自分自身のスコープに置かれるため、その中で定義されている変数やミックスインが他のSassから利用できなくなってしまいます。

`@import "*"`や`@import "**/*"`などのようにワイルドカードマッチでツリー全体を指定することもできます。これは`require_tree`と同等です。詳細および重要な警告については[sass-railsドキュメント](https://github.com/rails/sass-rails#features)を参照してください。

マニフェストファイルは必要に応じていくつでも使用できます。たとえば、アプリケーションのadminセクションで使用するJSファイルとCSSファイルを`admin.css`と`admin.js`マニフェストにそれぞれ記載することができます。

読み込み順についても前述のとおり反映されます。特に、個別に指定したファイルは、そのとおりの順序でコンパイルされます。たとえば、以下では3つのCSSファイルを結合しています。

```js
/* ...
*= require reset
*= require layout
*= require chrome
*/
```

### プリプロセス

適用されるプリプロセスの種類は、アセットファイルの拡張子によって決まります。コントローラやscaffoldをデフォルトのgemセットで生成した場合、通常JavaScriptファイルやCSSファイルが置かれる場所にCoffeeScriptファイルとSCSSファイルがそれぞれ生成されます。先の例では、コントローラ名が"projects"で、`app/assets/javascripts/projects.js.coffee`ファイルと`app/assets/stylesheets/projects.css.scss`ファイルが生成されます。

developmentモードの場合、あるいはアセットパイプラインが無効になっている場合は、これらのアセットへのリクエストは`coffee-script` gemと`sass` gemが提供するプロセッサによって処理され、それぞれJavaScriptとCSSとしてブラウザへのレスポンスが送信されます。アセットパイプラインが有効になっている場合は、これらのアセットファイルはプリプロセスの対象となり、処理後のファイルが`public/assets`ディレクトリに置かれてRailsアプリケーションまたはWebサーバーによって利用されます。

アセットファイル名に別の拡張子を追加することにより、プリプロセス時に別のレイヤを追加でリクエストすることができます。アセットファイル名の拡張子は、「右から左」の順に処理されます。従って、アセットファイル名の拡張子は、これに従って処理を行うべき順序で与える必要があります。たとえば、`app/assets/stylesheets/projects.css.scss.erb`というスタイルシートでは、最初にERBとして処理され、続いてSCSS、最後にCSSとして処理されます。同様にして、 `app/assets/javascripts/projects.js.coffee.erb` というJavaScriptファイルの場合では、ERB → CoffeeScript → JavaScript の順に処理されます。

このプリプロセス順序は非常に重要ですので、心に留めておいてください。たとえば、仮に`app/assets/javascripts/projects.js.erb.coffee`というファイルを呼び出すと、最初にCoffeeScriptインタプリタによって処理されます。しかしこれは次のERBで処理できないので問題が発生することがあります。


development環境の場合
--------------

developmentモードの場合、アセットは個別のファイルとして、マニフェストファイルの記載順に読み込まれます。

`app/assets/javascripts/application.js`というマニフェストの内容が以下のようになっているとします。

```js
//= require core
//= require projects
//= require tickets
```

上によって以下のHTMLが生成されます。

```html
<script src="/assets/core.js?body=1"></script>
<script src="/assets/projects.js?body=1"></script>
<script src="/assets/tickets.js?body=1"></script>
```

`body`パラメータはSprocketsで必要となります。

### ランタイムエラーをチェックする

アセットパイプラインはdevelopmentモードでランタイム時のエラーをデフォルトでチェックします。この動作を無効にするには、以下の設定を使用します。

```ruby
config.assets.raise_runtime_errors = false
```

このオプションがtrueになっていると、アプリケーションのアセットが`config.assets.precompile`に記載されているとおりにすべて読み込まれているかどうかをチェックします。`config.assets.digest`もtrueになっている場合、アセットへのリクエストにダイジェストを含むことが必須となります。

### ダイジェストをオフにする

`config/environments/development.rb`を更新して以下のようにすることで、ダイジェストをオフにできます。

```ruby
config.assets.digest = false
```

このオプションがtrueになっていると、ダイジェストが生成されてアセットへのURLに含まれるようになります。

### デバッグをオフにする

デバッグモードをオフにするには、`config/environments/development.rb`に以下を追記します。

```ruby
config.assets.debug = false
```

デバッグモードをオフにすると、Sprocketsはすべてのファイルを結合して、必要なプリプロセッサを実行します。デバッグモードをオフにすると、上のマニフェストファイルによって以下が生成されるようになります。

```html
<script src="/assets/application.js"></script> 
```

アセットは、サーバー起動後に最初にリクエストを受け取った時点でコンパイルとキャッシュが行われます。Sprocketsは、`must-revalidate`というCache-Control HTTPヘッダを設定することで、以後のリクエストのオーバーヘッドを減らします。この場合、ブラウザはレスポンス304 (Not Modified) を受け取ります。

リクエストとリクエストの合間に、マニフェストに記載されているファイルのいずれかで変更が生じた場合、Railsサーバーは新しくコンパイルされたファイルをレスポンスで返します。

Railsのヘルパーメソッドを使用してデバッグモードをオンにすることもできます。

```erb
<%= stylesheet_link_tag "application", debug: true %>
<%= javascript_include_tag "application", debug: true %>
```

デバッグモードが既にオンの場合、`:debug`オプションは冗長です。

developmentモードで健全性チェックの一環として圧縮をオンにしたり、デバッグの必要性に応じてオンデマンドで無効にしたりすることもできます。

production環境の場合
-------------

Sprocketsは、production環境では前述のフィンガープリントによるスキームを使用します。デフォルトでは、Railsのアセットはプリコンパイル済みかつ静的なアセットとしてWebサーバーから提供されることが前提になっています。

MD5はコンパイルされるファイルの内容を元にプリコンパイル中に生成され、ファイル名に挿入されてディスクに保存されます。マニフェスト名はRailsヘルパーによってこれらのフィンガープリント名と置き換えられて使用されます。

以下の例で説明します。

```erb
<%= javascript_include_tag "application" %>
<%= stylesheet_link_tag "application" %>
```

上のコードによって以下のような感じで生成されます。

```html
<script src="/assets/application-908e25f4bf641868d8683022a5b62f54.js"></script>
<link href="/assets/application-4dd5b109ee3439da54f5bdfd78a80473.css" media="screen" rel="stylesheet" />
```

NOTE: アセットパイプラインの:cacheオプションと:concatオプションは廃止されました。これらのオプションは`javascript_include_tag`と`stylesheet_link_tag`から削除してください。

フィンガープリントの振る舞いについては`config.assets.digest`初期化オプションで制御できます。productionモードではデフォルトで`true`、それ以外では`false`です。

NOTE: デフォルトの`config.assets.digest`オプションは、通常は変更しないでください。ファイル名にダイジェストが含まれないと、遠い将来にヘッダが設定されたときに (ブラウザなどの) リモートクライアントがファイルの内容変更を検出して再度取得することができなくなってしまいます。

### アセットをプリコンパイルする

Railsには、パイプラインにあるアセットマニフェストなどのファイルを手動でコンパイルするためのタスクが1つバンドルされています。

コンパイルされたアセットは、`config.assets.prefix`で指定された場所に保存されます。この保存場所は、デフォルトでは`/assets`ディレクトリです。

デプロイ時にこのタスクをサーバー上で呼び出すと、コンパイル済みアセットをサーバー上で直接作成できます。ローカル環境でコンパイルする方法については次のセクションを参照してください。

以下がそのタスクです。

```bash
$ RAILS_ENV=production bin/rails assets:precompile
```

Capistrano (v2.15.1以降) にはデプロイ中にこのタスクを扱うレシピが含まれています。
`Capfile`に以下を追加します。

```ruby
load 'deploy/assets'
```

これにより、`config.assets.prefix`で指定されたフォルダが`shared/assets`にリンクされます。
既にこの共有フォルダを使用しているのであれば、独自のデプロイ用タスクを作成する必要があります。

このフォルダは、複数のデプロイによって共有されている点が重要です。これは、サーバー以外の離れた場所でキャッシュされているページが古いコンパイル済みアセットを参照している場合でも、キャッシュ済みページの寿命が来て削除されるまではその古いページへの参照が有効になるようにするためです。

ファイルをコンパイルする際のデフォルトのマッチャによって、`app/assets`フォルダ以下の`application.js`、`application.css`、およびすべての非JS/CSSファイル (これにより画像ファイルもすべて自動的にインクルードされます) がインクルードされます。`app/assets`フォルダにあるgemも含まれます。

```ruby
[ Proc.new { |filename, path| path =~ /app\/assets/ && !%w(.js .css).include?(File.extname(filename)) },
/application.(css|js)$/ ]
```

NOTE: このマッチャ (および後述するプリコンパイル配列の他のメンバ) が適用されるのは、コンパイル前やコンパイル中のファイル名ではなく、コンパイル後の最終的なファイル名である点にご注意ください。これは、コンパイルされてJavaScriptやCSSになるような中間ファイルはマッチャの対象からすべて除外されるということです (純粋なJavaScript/CSSと同様)。たとえば、`.coffee`と`.scss`ファイルはコンパイル後にそれぞれJavaScriptとCSSになるので、これらは自動的にはインクルードされません。

他のマニフェストや、個別のスタイルシート/JavaScriptファイルをインクルードしたい場合は、`config/initializers/assets.rb`の`precompile`という配列を使用します。

```ruby
Rails.application.config.assets.precompile += ['admin.js', 'admin.css', 'swfObject.js']
```

あるいは、以下のようにすべてのアセットをプリコンパイルすることもできます。

```ruby
# config/initializers/assets.rb
Rails.application.config.assets.precompile << Proc.new do |path|
  if path =~ /\.(css|js)\z/
    full_path = Rails.application.assets.resolve(path).to_path
    app_assets_path = Rails.root.join('app', 'assets').to_path
    if full_path.starts_with? app_assets_path
      logger.info "including asset: " + full_path
      true
    else
      logger.info "excluding asset: " + full_path
      false
    end
  else
    false
  end
end
```

NOTE: プリコンパイル配列にSassやCoffeeScriptファイルなどを追加する場合にも、必ず.jsや.cssで終わるファイル名 (つまりコンパイル後のファイル名として期待されているファイル名) も指定してください。

このタスクは、`manifest-md5hash.json`ファイルも生成します。これはすべてのアセットとそれらのフィンガープリントのリストです。Railsヘルパーはこれを使用して、マッピングリクエストがSprocketsへ戻されることを回避します。典型的なマニフェストファイルの内容は以下のような感じになっています。

```ruby
{"files":{"application-723d1be6cc741a3aabb1cec24276d681.js":{"logical_path":"application.js","mtime":"2013-07-26T22:55:03-07:00","size":302506,
"digest":"723d1be6cc741a3aabb1cec24276d681"},"application-12b3c7dd74d2e9df37e7cbb1efa76a6d.css":{"logical_path":"application.css","mtime":"2013-07-26T22:54:54-07:00","size":1560,
"digest":"12b3c7dd74d2e9df37e7cbb1efa76a6d"},"application-1c5752789588ac18d7e1a50b1f0fd4c2.css":{"logical_path":"application.css","mtime":"2013-07-26T22:56:17-07:00","size":1591,
"digest":"1c5752789588ac18d7e1a50b1f0fd4c2"},"favicon-a9c641bf2b81f0476e876f7c5e375969.ico":{"logical_path":"favicon.ico","mtime":"2013-07-26T23:00:10-07:00","size":1406,
"digest":"a9c641bf2b81f0476e876f7c5e375969"},"my_image-231a680f23887d9dd70710ea5efd3c62.png":{"logical_path":"my_image.png","mtime":"2013-07-26T23:00:27-07:00","size":6646,
"digest":"231a680f23887d9dd70710ea5efd3c62"}},"assets":{"application.js":
"application-723d1be6cc741a3aabb1cec24276d681.js","application.css":
"application-1c5752789588ac18d7e1a50b1f0fd4c2.css",
"favicon.ico":"favicona9c641bf2b81f0476e876f7c5e375969.ico","my_image.png":
"my_image-231a680f23887d9dd70710ea5efd3c62.png"}}
```

マニフェストのデフォルトの置き場所は、`config.assets.prefix`で指定された場所のルートディレクトリ (デフォルトでは'/assets') です。

NOTE: productionモードで見つからないプリコンパイル済みファイルがあると、見つからないファイル名をエラーメッセージに含んだ`Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError`が発生します。

#### 遠い将来に期限切れになるヘッダー

プリコンパイル済みのアセットはファイルシステム上に置かれ、Webサーバーから直接クライアントに提供されます。これらプリコンパイル済みアセットには、いわゆる遠い将来に期限切れになるヘッダ (far-future headers) はデフォルトでは含まれていません。したがって、フィンガープリントのメリットを得るためには、サーバーの設定を更新してこのヘッダを含める必要があります。

Apacheの設定: 

```apache
# Expires* ディレクティブを使用する場合はApacheの
# `mod_expires`モジュールを有効にする必要あり
<Location /assets/>
  # Last-Modifiedフィールドが存在する場合はETagの使用が妨げられる
  Header unset ETag
  FileETag None
  # RFCによるとキャッシュは最長1年まで
  ExpiresActive On
  ExpiresDefault "access plus 1 year"
</Location>
```

NGINXの場合:

```nginx
location ~ ^/assets/ {
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
  break;
}
```

#### GZip圧縮

ファイルをプリコンパイルする際に、Sprocketsによって[gzipされた](http://ja.wikipedia.org/wiki/Gzip) (.gz) アセットも作成されます。Webサーバーによる圧縮はほどほどの圧縮率で行われるのが普通ですが、プリコンパイルが1度発生するとSprocketsによって最大圧縮率で圧縮され、Webサーバーからのデータ転送量が最小化されます。逆に、圧縮されてないファイルを自前で圧縮する代りに、事前に圧縮しておいたコンテンツを直接ディスクに配置しておくようWebサーバーを設定することもできます。

NGINXでは`gzip_static`を使用することでこれを自動的に行なうことができます。

```nginx
location ~ ^/(assets)/  {
  root /path/to/public;
  gzip_static on; # gzip済みのバージョンを提供する
  expires max;
  add_header Cache-Control public;
}
```

このディレクティブは、この機能を提供するコアモジュールがWebサーバーと一緒にコンパイルされている場合に使用可能になります。Ubuntu/Debianパッケージはもちろん、`nginx-light`にもこのモジュールがコンパイル済みで用意されています。それ以外の場合には、自分でコンパイルを行う必要があるでしょう。

```bash
./configure --with-http_gzip_static_module
```

NGINXをPhusion Passengerと共にコンパイルする場合は、コンパイル中にプロンプトが表示された時にそのためのオプションを渡す必要があります。

Apacheで堅牢な設定を行なうことは可能ですが、何かとトリッキーであるため、ネットを検索して情報を十分集めてください。(Apache用のよい設定例を確立したら本ガイドに反映いただけると大変助かります)

### ローカルでプリコンパイルを行なう

アセットをローカルでプリコンパイルする理由はいくつか考えられます。たとえば以下のようなものがあります。

* production環境のファイルシステムへの書き込み権限がない。
* デプロイ先が複数あり、同じ作業を繰り返したくない。
* アセットの変更を伴わないデプロイが頻繁に発生する。

ローカルでのコンパイルを行なうことで、コンパイル済みのアセットファイルをGitなどによるソース管理対象に含め、他のファイルと一緒にデプロイできるようになります。

ただし、以下の3つの注意点があります。

* Capistranoのデプロイメントタスクでアセットのプリコンパイルを行わないこと。
* development環境で圧縮機能や最小化機能がすべて利用できるようにしておくこと。
* 以下のアプリケーション設定を変更しておくこと。

`config/environments/development.rb`に以下の行があります。

```ruby
config.assets.prefix = "/dev-assets"
```

`prefix`を変更すると、Sprocketsはdevelopmentモードで別のURLを使用してアセットを提供し、すべてのリクエストがSprocketsに渡されるようになります。production環境のプレフィックスは`/assets`のままです。この変更を行わなかった場合、アプリケーションはdevelopment環境でもproduction環境と同じ`/assets`からプリコンパイルしたアセットを提供します。この場合、アセットを再コンパイルしないとローカルでの変更が反映されません。

実用上は、この変更によってローカルでのプリコンパイルが行えるようになり、必要に応じてそれらのファイルをワーキングツリーに追加してソース管理にコミットできるようになります。developmentモードは期待どおり動作します。

### 動的コンパイル

状況によっては動的コンパイル (live compilation) を使用したいこともあるでしょう。このモードでは、パイプラインのアセットへのリクエストは直接Sprocketsによって扱われます。

このオプションを有効にするには以下を設定します。

```ruby
config.assets.compile = true
```

最初のリクエストを受けると、アセットは上述のdevelopment環境のところで説明したとおりにコンパイルおよびキャッシュされます。ヘルパーで使用されるマニフェスト名にはMD5ハッシュが含まれます。

また、Sprocketsは`Cache-Control` HTTPヘッダーを`max-age=31536000`に変更します。このヘッダーは、サーバーとクライアントブラウザの間にあるすべてのキャッシュ (プロキシなど) に対して、サーバーが提供するこのコンテンツは1年間キャッシュしてよいと通知します。これにより、そのサーバーのアセットに対するリクエスト数を減らすことができ、アセットをローカルブラウザのキャッシュやその他の中間キャッシュで代替するよい機会が与えられます。

このモードはデフォルトよりもメモリを余分に消費し、パフォーマンスも落ちるためお勧めできません。

本番アプリケーションのデプロイ先のシステムに既存のJavaScriptランタイムがない場合は、以下をGemfileに記述します。

```ruby
group :production do
  gem 'therubyracer'
end
```

### CDN

CDN ([コンテンツデリバリーネットワーク](http://ja.wikipedia.org/wiki/%E3%82%B3%E3%83%B3%E3%83%86%E3%83%B3%E3%83%84%E3%83%87%E3%83%AA%E3%83%90%E3%83%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF))は、全世界を対象としてアセットをキャッシュすることを主な目的として設計されています。それにより、ブラウザからアセットをリクエストすると、ネットワーク上で最も近くにあるキャッシュのコピーが使用されます。production環境のRailsサーバーから (中間キャッシュを使用せずに) 直接アセットを提供しているのであれば、アプリケーションとブラウザの間でCDNを使用するのがベストプラクティスです。

CDNの典型的な利用法は、productionサーバーを "origin" サーバーとして設定することです。つまり、ブラウザがCDN上のアセットをリクエストしてキャッシュが見つからない場合、オンデマンドでサーバーからアセットファイルを取得してキャッシュするということです。たとえば、Railsアプリケーションを`example.com`というドメインで運用しており、`mycdnsubdomain.fictional-cdn.com`というCDNが設定済みであるとします。`mycdnsubdomain.fictional-cdn.com/assets/smile.png`がリクエストされると、CDNはいったん元のサーバーの`example.com/assets/smile.png`にアクセスしてこのリクエストをキャッシュします。CDN上の同じURLに対して次のリクエストが発生すると、キャッシュされたコピーがヒットします。CDNがアセットを直接提供する場合、ブラウザからのリクエストが直接Railsサーバーに達することはありません。CDNが提供するアセットはネットワーク上でブラウザに近い位置にあるので、リクエストは高速化されます。また、サーバーはアセットの送信に使う時間を節約できるので、アプリケーション本来のコードをより高速で提供することに集中できます。

#### CDNで静的なアセットを提供する

CDNを設定するには、Railsアプリケーションがインターネット上でproductionモードで運用されており、`example.com`などのように誰でもアクセスできるURLがある必要があります。続いて、クラウドホスティングプロバイダーが提供するCDNサービスと契約を結ぶ必要もあります。その際、CDNの"origin"設定をRailsアプリケーションのWebサイト`example.com`にする必要もあります。originサーバーの設定方法のドキュメントについてはプロバイダーにお問い合わせください。

サービスに使用するCDNから、アプリケーションで使用するためのカスタムサブドメイン (例: `mycdnsubdomain.fictional-cdn.com`) を交付してもらう必要もあります (メモ: fictional-cdn.comは説明用であり、少なくとも執筆時点では本当のCDNプロバイダーではありません)。以上でCDNサーバーの設定が終わりましたので、今度はブラウザに対して、Railsサーバーに直接アクセスするのではなく、CDNからアセットを取得するように通知する必要があります。これを行なうには、従来の相対パスに代えてCDNをアセットのホストサーバーとするようRailsを設定します。Railsでアセットホストを設定するには、`config/production.rb`の`config.action_controller.asset_host`を以下のように設定します。

```ruby
config.action_controller.asset_host = 'mycdnsubdomain.fictional-cdn.com'
```

NOTE: ここに記述するのは "ホスト名" (サブドメインとルートドメインを合わせたもの) のみです。`http://`や`https://`などのプロトコルスキームを記述する必要はありません。アセットへのリンクで使用されるプロトコルスキームは、Webページヘのリクエスト発生時に、そのページへのデフォルトのアクセス方法に合わせて適切に生成されます。

この値は[環境変数](http://ja.wikipedia.org/wiki/%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0)で設定することもできます。これを使用すると、ステージングサーバー (訳注: 検証用に本番サーバーを複製したサーバー) の実行が楽になります。

```
config.action_controller.asset_host = ENV['CDN_HOST']
```



NOTE: 上の設定が有効になるためには、サーバーの`CDN_HOST`環境変数に値 (この場合であれば`mycdnsubdomain.fictional-cdn.com`) を設定しておく必要があります。

サーバーとCDNの設定完了後、以下のアセットを持つWebページにアクセスしたとします。

```erb
<%= asset_path('smile.png') %>
```

上の例では、`/assets/smile.png`のようなパスは返されません (読みやすくするためダイジェスト文字は省略してあります)。実際に生成されるCDNへのフルパスは以下のようになります。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`smile.png`のコピーがCDNにあれば、CDNが代りにこのファイルをブラウザに送信します。元のサーバーはリクエストがあったことすら知りません。ファイルのコピーがCDNにない場合、CDNは "origin" (この場合`example.com/assets/smile.png`) を探して今後のために保存しておきます。

CDNで扱うアセットを一部だけに限っておきたい場合、アセットヘルパーのカスタム`:host`オプションを使用して`config.action_controller.asset_host`の値セットを上書きすることもできます。

```erb
<%= asset_path 'image.png', host: 'mycdnsubdomain.fictional-cdn.com' %>
```

#### CDNのキャッシュの動作をカスタマイズする

CDNはコンテンツをキャッシュすることで動作します。CDNに保存されているコンテンツが古くなったり壊れていたりすると、メリットよりも害の方が大きくなります。本セクションでは、多くのCDNにおける一般的なキャッシュの動作について解説します。プロバイダによってはこの記述のとおりでないことがありますのでご注意ください。

##### CDNリクエストキャッシュ

これまでCDNがアセットをキャッシュするのに向いていると説明しましたが、実際にキャッシュされているのはアセット単体ではなくリクエスト全体です。リクエストにはアセット本体の他に各種ヘッダーも含まれています。ヘッダーの中でもっとも重要なのは`Cache-Control`です。これはCDN (およびWebブラウザ) にキャッシュの取り扱い方法を通知するためのものです。たとえば、誰かが実際には存在しないアセット`/assets/i-dont-exist.png`にリクエストを行い、Railsが404エラーを返したとします。このときに`Cache-Control`ヘッダーが有効になっていると、CDNはこの404エラーページをキャッシュしようとします。

##### CDNヘッダをデバッグする

このヘッダが正しくキャッシュされているかどうかを確認するひとつの方法として、[curl]( http://explainshell.com/explain?cmd=curl+-I+http%3A%2F%2Fwww.example.com)を使用するという方法があります。curlを使用して、サーバーとCDNにそれぞれリクエストを送信し、ヘッダーが同じであるかどうかを以下のように確認できます。

```
$ curl -I http://www.example/assets/application-d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK
Server: Cowboy
Date: Sun, 24 Aug 2014 20:27:50 GMT
Connection: keep-alive
Last-Modified: Thu, 08 May 2014 01:24:14 GMT
Content-Type: text/css
Cache-Control: public, max-age=2592000
Content-Length: 126560
Via: 1.1 vegur
```

今度はCDNのコピーです。

```
$ curl -I http://mycdnsubdomain.fictional-cdn.com/application-d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK Server: Cowboy
Last-Modified: Thu, 08 May 2014 01:24:14 GMT Content-Type: text/css
Cache-Control:
public, max-age=2592000
Via: 1.1 vegur
Content-Length: 126560
Accept-Ranges:
bytes
Date: Sun, 24 Aug 2014 20:28:45 GMT
Via: 1.1 varnish
Age: 885814
Connection: keep-alive
X-Served-By: cache-dfw1828-DFW
X-Cache: HIT
X-Cache-Hits:
68
X-Timer: S1408912125.211638212,VS0,VE0
```

CDNが提供する`X-Cache`などの機能やCDNが追加するヘッダなどの付加的情報については、CDNのドキュメントを確認してください。

##### CDNとCache-Controlヘッダ

[Cache-Controlヘッダ](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9)は、リクエストがキャッシュされる方法を定めたW3Cの仕様です。CDNを使用していない場合、ブラウザはこのヘッダ情報を使用してコンテンツをキャッシュします。このヘッダのおかげで、アセットで変更が発生していない場合にブラウザがCSSやJavaScriptをリクエストのたびに再度ダウンロードせずに済み、非常に有用です。アセットのCache-Controlヘッダは一般に "public" にしておくものであり、RailsサーバーはCDNやブラウザに対してこのヘッダを通じてそのことを通知します。アセットが "public" であるということは、そのリクエストをどんなキャッシュにも保存してよいということを意味します。同様に`max-age` もこのヘッダでCDNやブラウザに通知されます。`max-age`は、キャッシュがオブジェクトを保存する期間を指定します。この期間を過ぎるとキャッシュは廃棄されます。`max-age`の値は秒単位で指定します。最大値は`31536000`であり、これは一年に相当します。Railsでは以下の設定でこの期間を指定できます。

```
config.static_cache_control = "public, max-age=31536000"
```

production環境のアセットは上の設定によってアプリケーションから提供されるようになり、キャッシュは1年間保存されます。多くのCDNはリクエストのキャッシュも保存しているので、この`Cache-Control`ヘッダーはアセットをリクエストするすべてのブラウザ (将来登場するブラウザも含める) に渡されます。ブラウザはこのヘッダを受け取ると、次回再度リクエストが必要になったときに備えてそのアセットを当分の間キャッシュに保存してよいことを知ります。

##### CDNにおけるURLベースのキャッシュ廃棄について

多くのCDNでは、アセットのキャッシュを完全なURLに基いて行います。たとえば以下のアセットへのリクエストがあるとします。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile-123.png
```

上のリクエストのキャッシュは、下のアセットへのリクエストのキャッシュとは完全に異なるものとして扱われます。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`Cache-Control`の`max-age`を遠い将来に設定する場合は、アセットに変更が生じた時にこれらのキャッシュが確実に廃棄されるようにしてください。たとえば、ニコニコマーク画像の色を黄色から青に変更したら、サイトを訪れた人には変更後の青いニコニコマークが見えるようにしたいはずです。RailsをCDNを併用している場合、Railsのアセットパイプライン`config.assets.digest`はデフォルトでtrueに設定されるので、アセットの内容に少しでも変更が生じれば必ずファイル名も変更されます。このとき、キャッシュ内の項目を手動で削除する必要がまったくない点にご注目ください。アセット名が内容に応じて常に一意になるので、ユーザーは常に最新のアセットを利用できます。

パイプラインをカスタマイズする
------------------------

### CSSを圧縮する

YUIはCSS圧縮方法のひとつです。[YUI CSS compressor](http://yui.github.io/yuicompressor/css.html)は最小化機能を提供します (訳注: この項では、圧縮 (compress) という語は最小化 (minify) や難読化 (uglify) と同じ意味で使用されており、圧縮後のファイルはzipのようなバイナリになりません)。

YUI圧縮は以下の記述で有効にできます。これには`yui-compressor` gemが必要です。

```ruby
config.assets.css_compressor = :yui
```
sass-rails gemを使用している場合は、以下のように代替のCSS圧縮方法として指定できます。

```ruby
config.assets.css_compressor = :sass
```

### JavaScriptを圧縮する

JavaScriptを圧縮する際には`:closure`、`:uglifier`、`:yui`のいずれかのオプションを指定できます。それぞれ、`closure-compiler` gem、`uglifier` gem、`yui-compressor` gemが必要です。

RailsのGemfileにはデフォルトで[uglifier](https://github.com/lautis/uglifier)が含まれています。このgemは、NodeJSで記述された[UglifyJS](https://github.com/mishoo/UglifyJS)をRubyでラップしたものです。uglifierによる圧縮は次のように行われます。ホワイトスペースとコメントを除去し、ローカル変数名を短くし、可能であれば`if`と`else`を三項演算子に置き換えるなどの細かな最適化を行います。

以下の設定により、JavaScriptの圧縮に`uglifier`が使用されます。

```ruby
config.assets.js_compressor = :uglifier
```

NOTE: `uglifier`を利用するには[ExecJS](https://github.com/sstephenson/execjs#readme)をサポートするJavaScriptランタイムが必要です。Mac OS XやWindowsを使用している場合は、OSにJavaScriptランタイムをインストールしてください。

NOTE: CSSやJavaScriptの圧縮を有効にする`config.assets.compress`初期化オプションはRails 4で廃止されました。現在はこのオプションを設定しても何も変わりません。CSSおよびJavaScriptアセットの圧縮を制御するには、`config.assets.css_compressor`および`config.assets.js_compressor`を使用します。

### 独自の圧縮機能を使用する

CSSやJavaScriptの圧縮設定にはあらゆるオブジェクトを設定できます。設定に与えるオブジェクトには`compress`メソッドが実装されている必要があります。このメソッドは文字列のみを引数として受け取り、圧縮結果を文字列で返す必要があります。

```ruby
class Transformer
  def compress(string)
    do_something_returning_a_string(string)
  end
end
```

上のコードを有効にするには、`application.rb`の設定オプションに新しいオブジェクトを渡します。

```ruby
config.assets.css_compressor = Transformer.new
```


### _アセット_ のパスを変更する

デフォルトでは、Sprocketsが使用するパブリックなパスは`/assets`になります。

このパスは以下のように変更可能です。

```ruby
config.assets.prefix = "/他のパス"
```

このオプションは次のような場合に便利です。アセットパイプラインを使用しない既存のプロジェクトがあり、そのプロジェクトの既存のパスを指定したり、別途新しいリソース用のパスを指定したりする場合なのです。

### X-Sendfileヘッダー

X-SendfileヘッダーはWebサーバーに対するディレクティブであり、アプリケーションからのレスポンスをブラウザに送信せずに破棄し、代りに別のファイルをディスクから読みだしてブラウザに送信します。このオプションはデフォルトでは無効です。サーバーがこのヘッダーをサポートしていればオンにできます。このオプションをオンにすると、それらのファイル送信はWebサーバーに一任され、それによって高速化されます。この機能の使用法については[send_file](http://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file)を参照してください。

ApacheとNGINXではこのオプションがサポートされており、以下のように`config/environments/production.rb`で有効にすることができます。

```ruby
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # Apache用
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # NGINX用
```

WARNING: 既存のRailsアプリケーションをアップグレードする際にこの機能を使用することを検討している場合は、このオプションの貼り付け先に十分ご注意ください。このオプションを貼り付けてよいのは`production.rb`と、production環境として振る舞わせたい他の環境ファイルのみです。`application.rb`ではありません。

TIP: 詳細については、production環境用Webサーバーのドキュメントを参照してください。
- [Apache](https://tn123.org/mod_xsendfile/)
- [NGINX](http://wiki.nginx.org/XSendfile)

アセットのキャッシュストア
------------------

Railsのキャッシュストアは、Sprocketsを使用してdevelopment環境とproduction環境のアセットをキャッシュを使用します。キャッシュストアの設定は`config.assets.cache_store`で変更できます。

```ruby
config.assets.cache_store = :memory_store
```

アセットキャッシュストアで利用できるオプションは、アプリケーションのキャッシュストアと同じです。


```ruby
config.assets.cache_store = :memory_store, { size: 32.megabytes }
```

アセットキャッシュストアを無効にするには以下のようにします。

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:null_store)
end
```

アセットをGemに追加する
--------------------------

アセットはgemの形式で外部ソースから持ち込むこともできます。

そのよい例は`jquery-rails` gemです。これは標準のJavaScriptライブラリをgemとしてRailsに提供します。このgemには`Rails::Engine`から継承したエンジンクラスが1つ含まれています。このgemを導入することにより、Railsはこのgem用のディレクトリにアセットを配置可能であることを認識し、`app/assets`、`lib/assets`、`vendor/assets`ディレクトリがSprocketsの検索パスに追加されます。

ライブラリやGemをプリプロセッサ化する
------------------------------------------

Sprocketsは異なるテンプレートエンジンへの一般的なインターフェイスとして[Tilt](https://github.com/rtomayko/tilt)を使用するため、gemにTiltテンプレートプロトコルのみを実装するだけで済みます。通常、Tiltを`Tilt::Template`のようにサブクラス化して`prepare`メソッドと`evaluate`メソッドを再実装します。`prepare`メソッドはテンプレートを初期化し、`evaluate`メソッドは処理の終わったソースを返します。処理前のソースは`data`に保存されます。詳細については[`Tilt::Template`](https://github.com/rtomayko/tilt/blob/master/lib/tilt/template.rb)のソースを参照してください。

```ruby
module BangBang
  class Template < ::Tilt::Template
    def prepare
      # ここですべての初期化を行なう
    end

    # 元のテンプレートに"!"を追加する
    def evaluate(scope, locals, &block)
      "#{data}!"
    end
  end
end
```

これで`Template`クラスができましたので、続いてテンプレートファイルの拡張子との関連付けを行います。

```ruby
Sprockets.register_engine '.bang', BangBang::Template
```

古いバージョンのRailsからアップグレードする
------------------------------------

Rails 3.0やRails 2.xからのアップグレードの際には、いくつかの作業を行う必要があります。最初に、`public/`ディレクトリ以下のファイルを新しい場所に移動します。ファイルの種類ごとの正しい置き場所については、[アセットの編成](#アセットの編成)を参照してください。

続いて、JavaScriptファイルの重複を解消します。jQueryはRails 3.1以降におけるデフォルトのJavaScriptライブラリなので、`jquery.js`を`app/assets`に置かなくても自動的に読み込まれます。

3番目に、多くの環境設定ファイルを正しいデフォルトオプションに更新します。

`application.rb`の場合。

```ruby
# アセットのバージョンを指定する。アセットをすべて期限切れにしたい場合はこの値を変更する。
config.assets.version = '1.0'

# config.assets.prefix = "/assets"は、アセットの置き場所となるパスを変更する際に使用する。
```

`development.rb`の場合。

```ruby
# アセットで読み込んだ行を展開する。
config.assets.debug = true
```

`production.rb`の場合。

```ruby
# 圧縮機能を使用するには config.assets.js_compressor  = を使用する
# :uglifier config.assets.css_compressor = :yui

# プリコンパイル済みのアセットが見当たらない場合にアセットパイプラインにフォールバックしない
config.assets.compile = false

# アセットURLのダイジェストを生成する。(今後非推奨になる計画あり)
config.assets.digest = true

# 追加のアセットをプリコンパイルする (application.js、application.css、およびすべての
# 非JS/CSSファイルが追加済み) config.assets.precompile += %w( search.js )
```

Rails 4はSprocketsのデフォルト設定値をtest環境用の`test.rb`に設定しなくなりました。従って、`test.rb`にSprocketsの設定を行なう必要があります。test環境における以前のデフォルト値は、`config.assets.compile = true`、`config.assets.compress = false`、`config.assets.debug = false`、`config.assets.digest = false`です。

以下を`Gemfile`に追加する必要があります。

```ruby
gem 'sass-rails',   "~> 3.2.3"
gem 'coffee-rails', "~> 3.2.1"
gem 'uglifier'
```