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

アセットパイプライン（asset pipeline）は、JavaScriptとCSSアセットの配信を処理するためのフレームワークを提供します。これは、HTTP/2のような技術や、アセットの連結や最小化といった技術を活用することによって行われます。アプリケーションは、最終的に他のgemのアセットと自動的に結合できるようになります。

アセットパイプラインは [importmap-rails](https://github.com/rails/importmap-rails) gem、[sprockets](https://github.com/rails/sprockets) gem、[sprockets-rails](https://github.com/rails/sprockets-rails) gem によって実装されており、デフォルトで有効になっています。新しいアプリケーションを作成する際に、以下のように`--skip-asset-pipeline`オプションを渡すとアセットパイプラインを無効にできます。

```bash
$ rails new appname --skip-asset-pipeline
```

NOTE: 本ガイドでは、CSSの処理に`sprockets`を、JavaScriptの処理に`importmap-rails`のみを利用するデフォルトのアセットパイプラインに重点を置いています。この2つの主な制限は、トランスパイルをサポートしていないため、Babel、TypeScript、Sass、React JSX format、Tailwind CSSといったものが使えないことです。JavaScriptやCSSのトランスパイルが必要な場合は、「[別のライブラリを使う](#別のライブラリを使う)」セクションをお読みください。

### 主要な機能

アセットパイプラインの第1の機能は、各ファイル名にSHA256フィンガープリントを挿入し、ファイルがWebブラウザとCDNによってキャッシュされるようにすることです。このフィンガープリントは、ファイルの内容を変更すると自動的に更新され、キャッシュが無効化されます。

アセットパイプラインの第2の機能は、JavaScriptファイルの配信に[import maps](https://github.com/WICG/import-maps)を使うことです。これにより、ESモジュール（ESM）用に作られたJavaScriptライブラリを利用する、トランスパイルやバンドリングを必要としないモダンなアプリケーションを構築できるようになり、**Webpack、yarn、nodeなどのJavaScriptツールチェーンが不要になります**。

アセットパイプラインの第3の機能は、すべてのCSSファイルを1個のメイン`.css`ファイルに連結して、最小化（minify）または圧縮することです。本ガイドの後半で学ぶように、この戦略をカスタマイズして、好みの形でファイルをグループ化できます。production環境のRailsでは、各ファイル名にSHA256フィンガープリントを挿入して、ファイルがWebブラウザでキャッシュされるようにします。このフィンガープリントを変更することでキャッシュを無効にすることが可能です。フィンガープリントの変更は、ファイルの内容を変更するたびに自動的に行われます。

アセットパイプラインの第4の機能は、CSSの上位言語によるアセットコーディングを可能にすることです。

### フィンガープリントと注意点

フィンガープリント（fingerprinting）は、アセットファイルの内容に応じてアセットファイル名を変更する技術です。アセットファイルの内容が少しでも変わると、アセットファイル名も必ずそれに応じて変わります。静的なコンテンツや変更頻度の低いコンテンツについては、フィンガープリントをチェックすれば内容が変更されていないかどうかを容易に確認できます。これはサーバーやデプロイ日が異なっていても有効です。

コンテンツの変更に応じてファイル名も一意に変化するようになっていれば、CDN、ISP、ネットワーク機器、Webブラウザなどあらゆる場面で有効なキャッシュをHTTPヘッダに設定できます。ファイルの内容が更新されると、フィンガープリントも必ず更新されます。これにより、リモートクライアントはコンテンツの新しいコピーをサーバーにリクエストするようになります。この手法を一般に「キャッシュ破棄（cache busting）」と呼びます。

Sprocketsがフィンガープリントを使う際には、ファイルの内容をハッシュ化したものをファイル名（通常は末尾）に追加します。たとえば、`global.css`というCSSファイル名は以下のようになります。

```
global-908e25f4bf641868d8683022a5b62f54.css
```

これはRailsのアセットパイプラインの戦略として採用されています。

フィンガープリントは、development環境とproduction環境の両方でデフォルトで有効になっています。フィンガープリントは、設定の[`config.assets.digest`][]オプションで有効または無効にできます。

### import mapと注意点

import mapは、バージョンとダイジェストを持つファイルに対応する論理名を用いて、ブラウザから直接JavaScriptモジュールをインポートできます。そのため、トランスパイルやバンドリングを必要とせず、ESモジュール（ESM）用に作られたJavaScriptライブラリを用いて最新のJavaScriptアプリケーションを構築できるようになります

import mapの方法では、1個の巨大なJavaScriptファイルの代わりに、多数の小さなJavaScriptファイルを送信することになります。HTTP/2のおかげで、最初の転送時に重大なパフォーマンス上のペナルティが発生しなくなっていますし、実際、より優れたキャッシュの力学により、本質的なメリットを長期的に得られます。

import mapをJavaScriptアセットパイプラインとして使う
-----------------------------

import mapは、RailsのデフォルトのJavaScriptプロセッサです。import mapを生成するロジックは[`importmap-rails`](https://github.com/rails/importmap-rails) gemによって処理されます。

WARNING: import mapはJavaScriptファイル専用であり、CSSの配信には利用できません。CSSについては、[Sprocketsの利用法](#sprocketsの利用法)セクションを参照してください。

詳しい使い方は`importmap-rails` gemのホームページで確認できますが、`importmap-rails`の基本を理解しておくことが大切です。

### しくみ

import mapsは、基本的に「bare module specifiers」と呼ばれるものの文字列置換です。これにより、JavaScriptモジュールのインポート名を標準化できるようになります。

たとえば以下のインポート定義は、import mapがなければ機能しません。

```javascript
import React from "react"
```

インポート定義を有効にするには、たとえば以下のように定義する必要があるでしょう。

```javascript
import React from "https://ga.jspm.io/npm:react@17.0.2/index.js"
```

ここでimport mapが登場して、`https://ga.jspm.io/npm:react@17.0.2/index.js`アドレスにピン留めする`react`名を定義します。このような情報が提供されれば、ブラウザは簡略化された`import React from "react"`定義を受け取れるようになります。import mapは、ライブラリのソースアドレスのエイリアスのようなものと見なせます。

### 利用法

`importmap-rails`では、ライブラリパスを`pin`で名前にピン留め（pinning）したimportmap設定ファイルを作成します。

```ruby
# config/importmap.rb
pin "application"
pin "react", to: "https://ga.jspm.io/npm:react@17.0.2/index.js"
```

設定されたすべてのimport mapは、アプリケーションで`<head>`要素に`<%= javascript_importmap_tags %>`を追加することでアタッチする必要があります。`javascript_importmap_tags`は、`head`要素で多くのスクリプトをまとめてレンダリングします。

- import mapの設定がすべて完了しているJSON

```html
<script type="importmap">
{
  "imports": {
    "application": "/assets/application-39f16dc3f3....js"
    "react": "https://ga.jspm.io/npm:react@17.0.2/index.js"
  }
}
</script>
```

- `app/javascript/application.js`からのJavaScriptの読み込みのエントリポイント:

```html
<script type="module">import "application"</script>
```

NOTE: v2.0.0より前の`importmap-rails`は、古いブラウザでのimport mapを確実にサポートするため、[`Es-module-shims`](https://github.com/guybedford/es-module-shims)をポリフィルとして`javascript_importmap_tags`の出力に挿入していました。しかし現在は、すべての主要ブラウザでimport mapがネイティブサポートされているので、v2.0.0でバンドルされていたshimは削除されました。import mapをサポートしていないレガシーブラウザをサポートする場合は、`javascript_importmap_tags`の前に`Es-module-shims`を手動で挿入してください。詳しくは、[importmap-railsのREADME](https://github.com/rails/importmap-rails?tab=readme-ov-file#supporting-legacy-browsers-such-as-safari-on-ios-15)を参照してください。

### npmパッケージをJavaScript CDN経由で利用する

`importmap-rails`インストールの一部として追加される`bin/importmap`コマンドを使って、import map内のnpmパッケージを`pin`、`unpin`、または更新できます。binstubではCDNとして[`JSPM.org`](https://jspm.org/)を利用しています。

このコマンドは以下のように動作します。

```bash
$ bin/importmap pin react react-dom
Pinning "react" to https://ga.jspm.io/npm:react@17.0.2/index.js
Pinning "react-dom" to https://ga.jspm.io/npm:react-dom@17.0.2/index.js
Pinning "object-assign" to https://ga.jspm.io/npm:object-assign@4.1.1/index.js
Pinning "scheduler" to https://ga.jspm.io/npm:scheduler@0.20.2/index.js

bin/importmap json

{
  "imports": {
    "application": "/assets/application-37f365cbecf1fa2810a8303f4b6571676fa1f9c56c248528bc14ddb857531b95.js",
    "react": "https://ga.jspm.io/npm:react@17.0.2/index.js",
    "react-dom": "https://ga.jspm.io/npm:react-dom@17.0.2/index.js",
    "object-assign": "https://ga.jspm.io/npm:object-assign@4.1.1/index.js",
    "scheduler": "https://ga.jspm.io/npm:scheduler@0.20.2/index.js"
  }
}
```

上のように、reactとreact-domという2つのパッケージは、jspmのデフォルトで解決すると、合計4つの依存関係に解決されます。

これで、他のモジュールと同じように、`application.js`のエントリポイントでこれらを利用できるようになります。

```javascript
import React from "react"
import ReactDOM from "react-dom"
```

`pin`コマンドでは、以下のようにバージョンも指定できます。

```bash
$ bin/importmap pin react@17.0.1
Pinning "react" to https://ga.jspm.io/npm:react@17.0.1/index.js
Pinning "object-assign" to https://ga.jspm.io/npm:object-assign@4.1.1/index.js
```

`pin`したパッケージは、以下のように`unpin`で削除できます。

```bash
$ bin/importmap unpin react
Unpinning "react"
Unpinning "object-assign"
```

production（デフォルト）とdevelopmentでビルドが分かれているパッケージでは、以下のように`--env`でパッケージの環境を制御できます。

```bash
$ bin/importmap pin react --env development
Pinning "react" to https://ga.jspm.io/npm:react@17.0.2/dev.index.js
Pinning "object-assign" to https://ga.jspm.io/npm:object-assign@4.1.1/index.js
```

また、`pin`実行時に、サポートされている別のCDNプロバイダー（[`unpkg`](https://unpkg.com/)や[`jsdelivr`](https://www.jsdelivr.com/)など）も指定できます。デフォルトのCDNは[`jspm`](https://jspm.org/)です。

```bash
$ bin/importmap pin react --from jsdelivr
Pinning "react" to https://cdn.jsdelivr.net/npm/react@17.0.2/index.js
```

ただし、`pin`をあるCDNプロバイダから別のプロバイダに切り替える場合、最初のプロバイダが追加した依存関係のうち、次のプロバイダで使われていないものを整理しなければならない場合があります。

単に`bin/importmap`を実行すると、すべてのオプションが表示されます。

なお、この`importmap`コマンドは、単に論理パッケージ名をCDN URLに解決するための便宜的なラッパーです。
また、CDN URLを自分で調べて`pin`することも可能です。たとえば、ReactにSkypackを使いたい場合は、`config/importmap.rb`に以下を追加できます。

```ruby
pin "react", to: "https://cdn.skypack.dev/react"
```

### ピン留めしたモジュールをプリロードする

ウォーターフォール効果（ブラウザがネストの最も深いインポートに到達するまで次々とファイルを読み込まなければならなくなる現象）を避けるために、importmap-railsは[modulepreload links](https://developer.chrome.com/blog/modulepreload/)をサポートしています。`pin`したモジュールに`preload: true` を追加することでプリロードできるようになります。

以下のように、アプリ内で使うライブラリやフレームワークをプリロードしておくと、早い段階でダウンロードするようブラウザに指示できます。

```ruby
# config/importmap.rb
pin "@github/hotkey", to: "https://ga.jspm.io/npm:@github/hotkey@1.4.4/dist/index.js", preload: true
pin "md5", to: "https://cdn.jsdelivr.net/npm/md5@2.3.0/md5.js"
```

```erb
<%# app/views/layouts/application.html.erb %>
<%= javascript_importmap_tags %>

<%# これにより、importmapがセットアップされる前に以下のリンクがインクルードされる: %>
<link rel="modulepreload" href="https://ga.jspm.io/npm:@github/hotkey@1.4.4/dist/index.js">
...
```

NOTE: 最新のドキュメントについては[`importmap-rails`](https://github.com/rails/importmap-rails)リポジトリを参照してください。

Sprocketsの利用法
-----------------------------

アプリケーションのアセットをWebで公開する素朴なアプローチは、`public`フォルダの`images`や `stylesheets`などのサブディレクトリにアセットを保存することでしょう。現代のWebアプリケーションは、アセットの圧縮やフィンガープリントの追加といった特定の方法で処理する必要があるため、これを手動で行うことは困難です。

Sprocketsは、設定済みディレクトリに保存されたアセットを自動的に前処理し、処理後にフィンガープリント追加、圧縮、ソースマップ生成といった設定可能な機能を使って`public/assets`フォルダに公開するように設計されています。

アセットを引き続き`public`階層に配置することは可能です。[`config.public_file_server.enabled`][]がtrueに設定されている場合、`public`以下のアセットは、アプリケーションまたはWebサーバによって静的ファイルとして配信されます。配信前に何らかの前処理が必要なファイルについては、`manifest.js`ディレクティブを定義しておく必要があります。

Railsのproduction環境では、これらのファイルをデフォルトで`public/assets`にプリコンパイルします。プリコンパイルされたファイルは、Webサーバで静的アセットとして配信されます。`app/assets`にあるファイルそのものは、productionで直接配信されることは決してありません。

[`config.public_file_server.enabled`]: configuring.html#config-public-file-server-enabled

### マニフェストファイルとディレクティブ

Sprocketsでアセットをコンパイルするとき、Sprocketsはどのトップレベルターゲットをコンパイルするかを決める必要があります（通常は`application.css`と画像ファイルです）。トップレベルターゲットはSprocketsの`manifest.js`ファイルで定義されます。

```js
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_tree ../../javascript .js
//= link_tree ../../../vendor/javascript .js
```

このファイルには**ディレクティブ**（directive）が含まれています。ディレクティブは、単一のCSSファイルやJavaScriptファイルをビルドするためにどのファイルが必要かをSprocketsに指示します。

上のマニフェストファイルは、`./app/assets/images`ディレクトリやそのサブディレクトリにあるすべてのファイル、`./app/javascript`ディレクトリや`./vendor/javascript`で直接JSとして認識されるすべてのファイルの内容をインクルードすることを意味しています。

このマニフェストファイルは `./app/assets/stylesheets`ディレクトリにあるすべてのCSSを読み込みます（ただしサブディレクトリは含めません）。
`./app/assets/stylesheets`フォルダに`application.css`ファイルと`marketing.css`ファイルがあると仮定すると、ビューに`<%= stylesheet_link_tag "application" %>`または`<%= stylesheet_link_tag "marketing" %>`と書くことでこれらのスタイルシートを読み込めるようになります。

JavaScriptファイルは、デフォルトでは`assets`ディレクトリから読み込まれないことにお気づきでしょうか。その理由は、`./app/javascript`が既に`importmap-rails` gemのデフォルトのエントリポイントになっていて、`vendor`フォルダはダウンロードしたJSパッケージの置き場所になっているからです。

`manifest.js`では、ディレクトリ全体ではなく、特定のファイルを読み込むために `link`ディレクティブを指定することも可能です。`link`ディレクティブでは、ファイルの拡張子を明示的に指定する必要があります。

Sprocketsは、指定されたファイルを読み込んで必要に応じて処理し、1個のファイルに連結した後、（`config.assets.css_compressor`または`config.assets.js_compressor`の値に基づいて）圧縮を行います。圧縮することでファイルサイズが小さくなり、ブラウザのファイルダウンロードがより高速になります。

### コントローラ固有のアセット

Railsでscaffoldやコントローラを生成すると、そのコントローラ用のCSSファイルも生成されます。scaffoldで生成する場合は、`scaffolds.css`というファイルも生成されます。

たとえば、`ProjectsController`を生成すると、Railsは`app/assets/stylesheets/projects.css`というファイルも追加します。デフォルトでは、`manifest.js`ファイル内の`link_directory`ディレクティブを使うことで、これらのファイルをアプリケーションですぐに利用可能になります。

また、以下の方法で、コントローラ固有のスタイルシートファイルを、それぞれのコントローラにのみインクルードすることも可能です。

```html+erb
<%= stylesheet_link_tag params[:controller] %>
```

ただし、この方法を使う場合は、`application.css`に対して`require_tree`ディレクティブを使わないでください。そうしないと、コントローラ固有のアセットが複数回インクルードされる可能性があります。

### アセットの編成

パイプラインのアセットは、アプリケーション内部の3つの場所（`app/assets`、`lib/assets`、`vendor/assets`）のいずれかに配置できます。

* `app/assets`: アプリケーションが所有するアセット（カスタムの画像やスタイルシートなど）はここに配置します。

* `app/javascript`: アプリケーションのJavaScriptコードはここに配置します。

* `vendor/[assets|javascript]`: 外部のエンティティ（CSSフレームワークやJavaScriptライブラリなど）が所有するアセットはここに配置します。アセットパイプラインで処理される他のファイル（画像、スタイルシートなど）への参照を持つサードパーティのコードは、`asset_path`などのヘルパーを使う形に書き換える必要があることにご注意ください。

`manifest.js`ファイルで設定可能なその他の場所については、[マニフェストファイルとディレクティブ](#マニフェストファイルとディレクティブ)を参照してください。

#### 探索パス

ファイルがマニフェストやヘルパーから参照されると、Sprocketsは`manifest.js`で指定されたすべての場所を探索してファイルを探します。探索パスは、Railsコンソールで [`Rails.application.config.assets.paths`](configuring.html#config-assets-paths)を調べることで表示できます。

#### indexファイルをフォルダのプロキシとして使う

Sprocketsでは、`index`（および関連する拡張子）という名前のファイルを特殊な目的のために利用します。

たとえば、多数のモジュールを持つCSSライブラリが`lib/assets/stylesheets/library_name`ディレクトリに置かれている場合、`lib/assets/stylesheets/library_name/index.css`ファイルは、このライブラリ内のすべてのファイルに対するマニフェストとして機能します。この`index`ファイルには、必要なすべてのファイルの順序付きリストか、シンプルな`require_tree`ディレクティブを含めることが可能です。

これは、`/library_name`へのリクエストで`public/library_name/index.html`にあるファイルに到達できるのと多少似ています。つまり、インデックスファイルは直接利用できません。

ライブラリ全体としては、`.css`ファイルから以下のようにアクセスできます。

```css
/* ...
*= require library_name
*/
```

こうすることで、関連するコードを他の場所でインクルードする前にグループ化できるようになり、設定がシンプルになってメンテナンスしやすくなります。

### アセットにリンクするコードを書く

Sprocketsはアセットにアクセスするためのメソッドを特に追加しません。使い慣れている`stylesheet_link_tag`を引き続き使います。

```erb
<%= stylesheet_link_tag "application", media: "all" %>
```

Railsにデフォルトで含まれている[`turbo-rails`](https://github.com/hotwired/turbo-rails) gemを使う場合は、以下のように`data-turbo-track`オプションも含めることで、アセットが更新されているかどうかをTurboがチェックし、更新されていればアセットをページに読み込むようになります。

```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

通常のビューでは、以下のような方法で`app/assets/images`ディレクトリの画像にアクセスできます。

```erb
<%= image_tag "rails.png" %>
```

パイプラインが有効で、かつ現在の環境で無効になっていない場合、このファイルはSprocketsによって配信されます。ファイルが`public/assets/rails.png`に置かれている場合、Webサーバーによって配信されます。

`public/assets/rails-f90d8a84c707a8dc923fca1ca1895ae8ed0a09237f6992015fef1e11be77c023.png`など、ファイル名にSHA256ハッシュを含むファイルへのリクエストについても同様に扱われます。ハッシュの生成法については、本ガイドの[production環境の場合](#production環境の場合)で後述します。

画像は、必要に応じてサブディレクトリで整理し、以下のようにタグでディレクトリ名を指定してアクセスすることも可能です。

```erb
<%= image_tag "icons/rails.png" %>
```

WARNING: アセットのプリコンパイルを行っている場合（[production環境の場合](#production環境の場合)を参照）、存在しないアセットへのリンクを含むページを呼び出すと例外が発生します。空文字列へのリンクも同様に例外が発生します。ユーザーから提供されるデータに対して`image_tag`などのヘルパーを使う場合はご注意ください。

#### CSSとERB

アセットパイプラインは自動的にERBを評価します。たとえば、cssアセットファイルに`erb`という拡張子を追加すると（`application.css.erb`など）、以下のようにCSS内で`asset_path`などのヘルパーが利用可能になります。

```css
.class { background-image: url(<%= asset_path 'image.png' %>) }
```

ここには、参照される特定のアセットへのパスを記述します。上の例では、アセット読み込みパスのいずれかにある画像ファイル（`app/assets/images/image.png`など）が指定されたと解釈されます。この画像が既にフィンガープリント付きで`public/assets`にあれば、このパスによる参照は有効になります。

[データURIスキーム](https://ja.wikipedia.org/wiki/Data_URI_scheme)（CSSファイルにデータを直接埋め込む手法）を使いたい場合は、`asset_data_uri`ヘルパーが利用できます。

```css
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

上のコードは、CSSソースに正しくフォーマットされたdata URIを挿入します。

この場合、`-%>`でタグを閉じることはできませんのでご注意ください。

### アセットが見つからない場合にエラーをraiseする

sprockets-rails 3.2.0以降を使っている場合は、アセットの探索時に何も見つからなかった場合の挙動を設定できます。以下のように`unknown_asset_fallback`を`false`にすると、アセットが見つからない場合にエラーをraiseします。

```ruby
config.assets.unknown_asset_fallback = false
```

`unknown_asset_fallback`を`true`にすると、エラーをraiseせずにパスを出力します。アセットのフォールバック動作はデフォルトでは無効です。

### ダイジェストをオフにする

`config/environments/development.rb`を更新して以下を記述すると、ダイジェストをオフにできます。


```ruby
config.assets.digest = false
```

このオプションが`true`の場合は、ダイジェストが生成されてアセットへのURLに含まれるようになります。

### ソースマップをオンにする

`config/environments/development.rb`に以下を記述すると、[ソースマップ](https://developer.mozilla.org/ja/docs/Tools/Debugger/How_to/Use_a_source_map)（Source Map）を有効にできます。


```ruby
config.assets.debug = true
```

デバッグモードを有効にすると、Sprocketsはアセットごとにソースマップを生成します。このソースマップによって、ブラウザの開発コンソールで個別のファイルをデバッグできるようになります。

アセットは、サーバー起動後に最初のリクエストを受けてコンパイルされ、キャッシュされます。
Sprocketは、以後のリクエストでコンパイルのオーバーヘッドを減らすために、[Cache-Control](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Cache-Control) HTTPヘッダーに`must-revalidate`を設定します。ブラウザは、これらのリクエストで[HTTP 304（Not Modified）](https://developer.mozilla.org/ja/docs/Web/HTTP/Status/304)レスポンスを受け取ります。

リクエストとリクエストの間にマニフェスト内のファイルが変更されると、サーバーは新たにコンパイルしたファイルを用いてレスポンスを返します。

production環境の場合
-------------

Sprocketsは、production環境では上述のフィンガープリントによるスキームを利用します。デフォルトでは、Railsのアセットはプリコンパイル済みかつ静的なアセットとしてWebサーバーから配信されることが前提になっています。

プリコンパイル中に、コンパイルされるファイルの内容を元にSHA256ハッシュを生成し、ディスクに保存するときにファイル名に挿入します。フィンガープリントが追加されたファイル名は、Railsヘルパーによってマニフェストファイルの代わりに使われます。

以下の例で説明します。

```erb
<%= stylesheet_link_tag "application" %>
```

上のコードによって以下のようなフィンガープリントが生成されます。

```html
<link href="/assets/application-4dd5b109ee3439da54f5bdfd78a80473.css" rel="stylesheet" />
```

フィンガープリントの振る舞いについては、[`config.assets.digest`][]初期化オプションで制御できます。デフォルトでは`true`です。

NOTE: 通常の利用状況では、デフォルトの`config.assets.digest`オプションを変更するべきではありません。ファイル名にダイジェストがなく、期限の失効がヘッダーで遠い将来に設定されている場合、リモートクライアントはファイルの内容が変更されたときに再取得することを認識できなくなります。

[`config.assets.digest`]: configuring.html#config-assets-digest

### アセットをプリコンパイルする

Railsには、パイプラインにあるアセットのマニフェストなどのファイルを手動でコンパイルするためのコマンドがバンドルされています。

コンパイルされたアセットは、[`config.assets.prefix`][]で指定された場所に保存されます。この保存場所は、デフォルトでは`/assets`ディレクトリです。

デプロイ時にこのタスクをサーバー上で呼び出すと、コンパイル済みアセットをサーバー上で直接作成できます。ローカル環境でコンパイルする方法については次のセクションを参照してください。

以下がそのコマンドです。

```bash
$ RAILS_ENV=production rails assets:precompile
```

これにより、`config.assets.prefix`で指定されたフォルダが`shared/assets`にリンクされます。
既にこの共有フォルダを利用している場合は、独自のデプロイ用タスクを作成する必要があります。

古いコンパイル済みアセットを参照するリモートキャッシュ済みページが、そのキャッシュ済みページの期限が切れるまで動作するには、このフォルダを複数のデプロイで共有しておくことが重要です。

NOTE: 常に`.js`または`.css`で終わるコンパイル済みファイル名を指定してください。

このコマンドは、`.sprockets-manifest-randomhex.json`（`randomhex` は16バイトのランダムな16進文字列を表す）も生成します。このJSONファイルには、すべてのアセットとそれぞれのフィンガープリントのリストが含まれます。これは、RailsヘルパーメソッドでマッピングリクエストをSprocketsに送信するのを避けるために使われます。
以下は典型的なマニフェストファイルです。

```json
{"files":{"application-<fingerprint>.js":{"logical_path":"application.js","mtime":"2016-12-23T20:12:03-05:00","size":412383,
"digest":"<fingerprint>","integrity":"sha256-<random-string>"}},
"assets":{"application.js":"application-<fingerprint>.js"}}
```

実際のアプリケーションでは、マニフェストに記載されるファイルやアセットはこれよりも増え、`<fingerprint>`や`<random-string>`の部分も生成されます。

マニフェストのデフォルトの置き場所は、`config.assets.prefix`で指定された場所のルートディレクトリ）です（デフォルトは`/assets`）。

NOTE: productionモードでプリコンパイル済みファイルが見つからない場合は、見つからないファイル名をエラーメッセージに含む例外`Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError`が発生します。

[`config.assets.prefix`]: configuring.html#config-assets-prefix

#### 遠い将来に期限が切れるヘッダー

プリコンパイル済みのアセットはファイルシステム上に置かれ、Webサーバーから直接クライアントに配信されます。これらプリコンパイル済みアセットには、いわゆる「遠い将来に失効するヘッダー（far-future headers）」はデフォルトでは含まれません。したがって、フィンガープリントのメリットを得るためには、サーバーの設定を更新してこのヘッダを含める必要があります。

Apacheの設定例:

```apache
# Expires* ディレクティブを使う場合はApacheの
# `mod_expires`モジュールを有効にする必要がある
<Location /assets/>
  # Last-Modifiedフィールドが存在する場合はETagの利用は推奨されない
  Header unset ETag
  FileETag None
  # RFCによるとキャッシュは最長1年まで
  ExpiresActive On
  ExpiresDefault "access plus 1 year"
</Location>
```

NGINXの設定例:

```nginx
location ~ ^/assets/ {
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
}
```

### ローカルでプリコンパイルする

場合によっては、productionサーバーでアセットをコンパイルしたくないことがあります。たとえば、productionファイルシステムへの書き込みアクセスが制限されている場合や、アセットを変更しないデプロイが頻繁に行われる場合などが考えられます。

そのような場合は、アセットを**ローカルで**プリコンパイルできます。つまり、production向けの最終的なコンパイル済みアセットを、production環境にデプロイする前にソースコードリポジトリに追加するということです。この方法なら、productionサーバーにデプロイするたびにproductionで別途プリコンパイルを実行する必要はありません。

以下を実行すると、production向けにプリコンパイルできます。

```bash
$ RAILS_ENV=production rails assets:precompile
```

ただし以下の注意点があります。

*  プリコンパイル済みのアセットが配信可能な状態になっていると、元の（コンパイルされていない）アセットと一致していなくてもプリコンパイル済みのアセットが配信されてしまいます。**これはdevelopmentサーバーでも同じことが起きます**。

    developmentサーバーが常にアセット変更のたびにオンザフライでコンパイルし、常に最新のコードが反映されるようにするには、development環境ではproductionと異なるディレクトリにプリコンパイル済みアセットを保存する設定が必要です。そうしないと、production用のプリコンパイル済みアセットがdevelopment環境でのブラウザ表示に影響を与えてしまいます（つまりアセットを変更してもブラウザに反映されなくなります）。

    この設定は、`config/environments/development.rb`ファイルに以下の行を追加することでできます。

    ```ruby
    config.assets.prefix = "/dev-assets"
    ```

* Capistranoなどの開発ツールで行われるアセットプリコンパイルは無効にしておく必要があります。

* アセットの圧縮や最小化に必要なツールをdevelopment環境のシステムで利用可能にしておく必要があります。

また、`ENV["SECRET_KEY_BASE_DUMMY"]`を設定すると、一時ファイルに保存されるランダム生成の`secret_key_base`が使われるようになります。これは、ビルド中にproduction用のsecretsにアクセスせずに、production用のアセットをプリコンパイルしたい場合に便利です。

```bash
$ SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
```

### 動的コンパイル

状況によっては動的コンパイル（live compilation）を使いたいこともあります。動的コンパイルモードでは、パイプラインのアセットへのリクエストは直接Sprocketsによって扱われます。

このオプションを有効にするには以下を設定します。

```ruby
config.assets.compile = true
```

最初のリクエストを受けると、[アセットのキャッシュストア](#アセットのキャッシュストア)で説明したとおりにアセットがコンパイルおよびキャッシュされ、ヘルパーで使われるマニフェスト名にSHA256ハッシュが含まれるようになります。

また、Sprocketsは[`Cache-Control` HTTPヘッダー](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Cache-Control)を`max-age=31536000`に変更します。このヘッダーは、サーバーとクライアントブラウザの間にあるすべてのキャッシュ（プロキシなど）に対して「サーバーが配信するこのコンテンツは1年間キャッシュに保存してよい」と通知します。これにより、そのサーバーのアセットに対するリクエスト数を削減でき、アセットをローカルブラウザのキャッシュやその他の中間キャッシュで代替するよい機会を得られます。


このモードはデフォルトよりもメモリ消費が多くパフォーマンスも落ちるため、推奨されません。

### CDN

[CDN（コンテンツデリバリーネットワーク）](https://ja.wikipedia.org/wiki/%E3%82%B3%E3%83%B3%E3%83%86%E3%83%B3%E3%83%84%E3%83%87%E3%83%AA%E3%83%90%E3%83%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF)は、全世界を対象としてアセットをキャッシュすることを主な目的として設計されています。CDNを利用すると、ブラウザからアセットをリクエストしたときに、ネットワーク上で地理的に最も「近く」にあるキャッシュのコピーが使われます。production環境のRailsサーバーから（中間キャッシュを使わずに）直接アセットを配信しているのであれば、アプリケーションとブラウザの間でCDNを利用するのがベストプラクティスです。

CDNの典型的な利用法は、productionサーバーを"origin"サーバーとして設定することです。つまり、ブラウザがCDN上のアセットをリクエストしてキャッシュが見つからない場合は、オンデマンドでサーバーからアセットファイルを取得してキャッシュします。

たとえば、Railsアプリケーションを`example.com`というドメインで運用しており、`mycdnsubdomain.fictional-cdn.com`というCDNが設定済みであるとします。ブラウザから`mycdnsubdomain.fictional-cdn.com/assets/smile.png`がリクエストされると、CDNはいったん元のサーバーの`example.com/assets/smile.png`にアクセスしてこのリクエストをキャッシュします。

CDN上の同じURLに対して次のリクエストが発生すると、キャッシュされたコピーにヒットします。CDNがアセットを直接配信可能な場合は、ブラウザからのリクエストが直接Railsサーバーに到達することはありません。CDNが配信するアセットはネットワーク上でブラウザと地理的に「近い」位置にあるので、リクエストは高速化されます。また、サーバーはアセットの送信に使う時間を節約できるので、アプリケーション本来のコードをできるだけ高速で配信することに専念できます。

#### CDNで静的なアセットを配信する

CDNを設定するには、Railsアプリケーションがインターネット上でproductionモードで運用されており、`example.com`などのような一般公開されているURLでアクセス可能になっている必要があります。次に、クラウドホスティングプロバイダが提供するCDNサービスと契約を結ぶ必要もあります。その際、CDNの"origin"設定をRailsアプリケーションのWebサイト`example.com`にする必要もあります。originサーバーの設定方法のドキュメントについてはプロバイダーにお問い合わせください。

利用するCDNから、アプリケーションで使うカスタムサブドメイン（例: `mycdnsubdomain.fictional-cdn.com`）を交付してもらう必要もあります（注: fictional-cdn.comは説明用のドメインであり、少なくとも執筆時点では本当のCDNプロバイダーではありません）。CDNサーバーの設定が終わったら、今度はブラウザに対して、Railsサーバーに直接アクセスするのではなく、CDNからアセットを取得するように通知する必要があります。これを行なうには、従来の相対パスに代えてCDNをアセットのホストサーバーとするようRailsを設定します。Railsでアセットホストを設定するには、`config/environments/production.rb`の[`config.asset_host`][]を以下のように設定します。

```ruby
config.asset_host = "mycdnsubdomain.fictional-cdn.com"
```

NOTE: ここに記述する必要があるのは「ホスト名（サブドメインとルートドメインを合わせたもの）」だけです。`http://`や`https://`などのプロトコルスキームを記述する必要はありません。アセットへのリンクで使われるプロトコルスキームは、Webページヘのリクエスト発生時に、そのページへのデフォルトのアクセス方法に合わせて適切に生成されます。

この値は、以下のように[環境変数](https://ja.wikipedia.org/wiki/%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0)でも設定できます。環境変数を使うと、stagingサーバーを実行しやすくなります。

```ruby
config.asset_host = ENV["CDN_HOST"]
```

NOTE: 上の設定を有効にするには、サーバーの`CDN_HOST`環境変数に値（この場合は`mycdnsubdomain.fictional-cdn.com`）を設定しておく必要があるかもしれません。

サーバーとCDNの設定が完了し、以下のアセットを持つWebページにアクセスしたとします。

```erb
<%= asset_path('smile.png') %>
```

この場合、`http://mycdnsubdomain.fictional-cdn.com/assets/smile.png`のような完全CDN URLが生成されます（読みやすくするためダイジェスト文字は省略してあります）。

`smile.png`のコピーがCDNにあれば、CDNが代わりにこのファイルをブラウザに送信します。元のサーバーはリクエストがあったことすら気づきません。ファイルのコピーがCDNにない場合は、CDNが「origin」（この場合は`example.com/assets/smile.png`）を探して今後のために保存しておきます。

一部のアセットだけをCDNで配信したい場合は、アセットヘルパーのカスタム`:host`オプションで[`config.action_controller.asset_host`][]の値セットを上書きすることも可能です。

```erb
<%= asset_path 'image.png', host: 'mycdnsubdomain.fictional-cdn.com' %>
```

[`config.action_controller.asset_host`]: configuring.html#config-action-controller-asset-host
[`config.asset_host`]: configuring.html#config-asset-host

#### CDNのキャッシュの動作をカスタマイズする

CDNは、コンテンツをキャッシュすることで動作します。CDNに保存されているコンテンツが古くなったり壊れていたりすると、メリットよりも害の方が大きくなります。本セクションでは、多くのCDNにおける一般的なキャッシュの動作について解説します。プロバイダによってはこの記述のとおりでないことがありますのでご注意ください。

##### CDNリクエストキャッシュ

これまでCDNがアセットをキャッシュするのに向いていると説明しましたが、実際にキャッシュされているのはアセット単体ではなくリクエスト全体です。リクエストにはアセット本体の他に各種ヘッダーも含まれています。

ヘッダーの中でもっとも重要なのは`Cache-Control`です。これはCDN（およびWebブラウザ）にキャッシュの取り扱い方法を通知するためのものです。たとえば、誰かが実際には存在しないアセット`/assets/i-dont-exist.png`にリクエストを行い、Railsが404エラーを返したとします。このときに`Cache-Control`ヘッダーが有効になっていると、CDNがこの404エラーページをキャッシュする可能性があります。

##### CDNヘッダをデバッグする

このヘッダが正しくキャッシュされているかどうかを確認する方法の1つは、[curl]( http://explainshell.com/explain?cmd=curl+-I+http%3A%2F%2Fwww.example.com)を使う方法です。curlを使ってサーバーとCDNにそれぞれリクエストを送信し、ヘッダーが同じであるかどうかを以下のように確認できます。

```bash
$ curl -I http://www.example/assets/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
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

CDNにあるコピーは以下のようになります。

```bash
$ curl -I http://mycdnsubdomain.fictional-cdn.com/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK Server: Cowboy Last-
Modified: Thu, 08 May 2014 01:24:14 GMT Content-Type: text/css
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

CDNが提供する`X-Cache`などの機能やCDNが追加するヘッダなどの追加情報については、CDNのドキュメントを参照してください。

##### CDNとCache-Controlヘッダ

[`Cache-Control`][]ヘッダーは、リクエストがキャッシュされる方法を定めたW3Cの仕様です。CDNを使わない場合は、ブラウザはこのヘッダ情報に基づいてコンテンツをキャッシュします。このヘッダのおかげで、アセットで変更が発生していない場合にブラウザがCSSやJavaScriptをリクエストのたびに再度ダウンロードせずに済むので、非常に有用です。

アセットの`Cache-Control`ヘッダは一般に"public"にしておくものであり、RailsサーバーはCDNやブラウザに対して、そのことをこのヘッダで通知します。アセットが"public"であるということは、そのリクエストをどのキャッシュに保存してもよいということを意味します。

同様に、`max-age`もこのヘッダでCDNやブラウザに通知されます。`max-age`は、オブジェクトをキャッシュに保存する期間を指定します。この期間を過ぎるとキャッシュは廃棄されます。`max-age`の値は秒単位で指定します。最大値は`31536000`であり、これは1年に相当します。

Railsでは以下の設定でこの期間を指定できます。

```ruby
config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000"
}
```

これで、production環境のアセットがアプリケーションから配信されると、キャッシュは1年間保存されます。多くのCDNはリクエストのキャッシュも保存しているので、この`Cache-Control`ヘッダーはアセットをリクエストするすべてのブラウザ（将来登場するブラウザも含む）に渡されます。ブラウザはこのヘッダを受け取ると、次回再度リクエストが必要になったときに備えて、そのアセットを非常に長い期間キャッシュに保存してよいことを認識します。

[`Cache-Control`]: https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Cache-Control

##### CDNにおけるURLベースのキャッシュ無効化について

多くのCDNでは、アセットのキャッシュを完全なURLに基いて行います。たとえば以下のアセットへのリクエストがあるとします。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile-123.png
```

上のリクエストのキャッシュは、下のアセットへのリクエストのキャッシュとは完全に異なるものとして扱われます。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`Cache-Control`の`max-age`を遠い将来に設定する場合は、アセットに変更が生じた時にこれらのキャッシュが確実に無効化されるようにしてください。たとえば、ニコニコマーク画像の色を黄色から青に変更したら、サイトを訪れた人には変更後の青いニコニコマークが見えるようにしたいはずです。

RailsでCDNを併用している場合、Railsのアセットパイプライン設定`config.assets.digest`はデフォルトで`true`に設定されるので、アセットの内容が少しでも変更されれば必ずファイル名も変更されます。

このとき、キャッシュ内の項目を手動で削除する必要はありません。アセットファイル名が内容に応じて常に一意になるので、ユーザーは常に最新のアセットを利用できます。

パイプラインをカスタマイズする
------------------------

### CSSを圧縮する

YUIはCSS圧縮方法の1つです。[YUI CSS compressor](https://yui.github.io/yuicompressor/css.html)は最小化機能を提供します。

YUI圧縮は以下の記述で有効にできます。これには`yui-compressor` gemが必要です。

```ruby
config.assets.css_compressor = :yui
```

### JavaScriptを圧縮する

JavaScriptの圧縮オプションには、`:terser`、`:closure`、`:uglifier`、`:yui`のいずれかを指定できます。それぞれ、`terser` gem、`closure-compiler` gem、`uglifier` gem、`yui-compressor` gemが必要です。

ここでは`terser` gemを例にします。
Railsの`Gemfile`にはデフォルトで[terser](https://github.com/terser/terser)が含まれています。このgemは、Node.js向けのコードをRubyでラップしたものです。terserによる圧縮は次のように行われます。ホワイトスペースとコメントを除去し、ローカル変数名を短くし、可能であれば`if`と`else`を三項演算子に置き換えるなどの細かな最適化を行います。


以下の設定により、JavaScriptの圧縮に`terser`が使われます。

```ruby
config.assets.js_compressor = :terser
```

NOTE: `terser`を利用するには[ExecJS](https://github.com/sstephenson/execjs#readme)をサポートするJavaScriptランタイムが必要です。macOSやWindowsを利用している場合は、OSにJavaScriptランタイムをインストールしてください。

NOTE: JavaScriptの圧縮は、`importmap-rails` gemや`jsbundling-rails` gemsでアセットを読み込む場合でも有効です。

### gzip圧縮されたアセットを配信する

非圧縮版のアセットに加えて、gzip圧縮されたコンパイル済みアセットもデフォルトで生成されます。gzipアセットはデータ転送を削減するのに有用です。これを指定するには`gzip`フラグを設定します。

```ruby
config.assets.gzip = false # gzipアセットの生成を無効にする場合
```

gzip形式のアセットの配信方法については、利用しているWebサーバーのドキュメントを参照してください。

### 独自の圧縮機能を使う

CSSやJavaScriptの圧縮設定にはあらゆるオブジェクトを渡せます。設定に与えるオブジェクトには`compress`メソッドが実装されている必要があります。このメソッドは文字列のみを引数として受け取り、圧縮結果を文字列で返す必要があります。

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

### アセットのパスを変更する

Sprocketsが利用するデフォルトのパブリックなパスは`/assets`です。

このパスは以下のように変更可能です。

```ruby
config.assets.prefix = "/他のパス"
```

このオプションは、アセットパイプラインを利用していない既存のプロジェクトがあり、そのプロジェクトの既存のパスを指定したり、別途新しいリソース用のパスを指定したりする場合に便利です。

### X-Sendfileヘッダー

`X-Sendfile`ヘッダーはWebサーバーに対するディレクティブであり、アプリケーションからのレスポンスをブラウザに送信せずに破棄し、代わりに別のファイルをディスクから読みだしてブラウザに送信します。

このオプションはデフォルトでは無効ですが、サーバーがこのヘッダーをサポートしていれば有効にできます。このオプションをオンにすると、それらのファイル送信がWebサーバーに一任され、それによって高速化されます。
この機能の利用方法については、[`send_file`](http://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file) APIドキュメントを参照してください。

ApacheとNGINXではこのオプションがサポートされており、以下のように`config/environments/production.rb`で有効にできます。

```ruby
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # Apache用
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # NGINX用
```

WARNING: 既存のRailsアプリケーションをアップグレードする際にこの機能の利用を検討している場合は、このオプションの貼り付け先に十分ご注意ください。このオプションを貼り付けてよいのは`production.rb`と、production環境として振る舞わせたい他の環境ファイルだけです。`application.rb`ではありません。

TIP: 詳しくは、production環境で利用するWebサーバーのドキュメントを参照してください。
- [Apache](https://tn123.org/mod_xsendfile/)
- [NGINX](http://wiki.nginx.org/XSendfile)

アセットのキャッシュストア
------------------

デフォルトのSprocketsは、development環境とproduction環境で`tmp/cache/assets`にアセットをキャッシュします。これは以下のように変更できます。

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:memory_store,
                                                { size: 32.megabytes })
end
```

アセットキャッシュストアを無効にするには以下のようにします。

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:null_store)
end
```

アセットをGemに追加する
--------------------------

アセットはgemの形式で外部から持ち込むこともできます。

そのよい例は`jquery-rails` gemです。これは標準のJavaScriptライブラリをgemとしてRailsに提供します。このgemには`Rails::Engine`から継承したエンジンクラスが含まれています。このgemを導入することにより、Railsはこのgem用のディレクトリにアセットを配置可能であることを認識し、`app/assets`、`lib/assets`、`vendor/assets`ディレクトリがSprocketsの検索パスに追加されます。

ライブラリやGemをプリプロセッサ化する
------------------------------------------

Sprocketsでは機能を拡張するのにProcessors、Transformers、Compressors、Exportersを使います。詳しくはSprocketsのREADME「[Extending Sprockets](https://github.com/rails/sprockets/blob/main/guides/extending_sprockets.md)」を参照してください。以下ではtext/css (`.css`)ファイルの末尾にコメントを追加するプリプロセッサを登録しています。

```ruby
module AddComment
  def self.call(input)
    { data: input[:data] + "/* Hello From my sprockets extension */" }
  end
end
```

これで入力データを変更するモジュールができたので、続いてMIMEタイプのプリプロセッサとして登録します。

```ruby
Sprockets.register_preprocessor "text/css", AddComment
```


別のライブラリを使う
------------------------------------------

長年にわたり、アセットを処理するためのデフォルトの手法は複数ありました。Webが進化して、JavaScriptを多用するアプリケーションが増えてきました。The Rails Doctrineでは[メニューは"おまかせ"](https://rubyonrails.org/doctrine#omakase)と考えているので、デフォルトのセットアップである**Sprocketsとimport map**に重点を置きました。

私たちは、さまざまなJavaScriptフレームワークやCSSのフレームワーク、拡張機能に対して万能なソリューションが存在しないことを認識しています。Railsのエコシステムには他にもさまざまなバンドルライブラリがあり、デフォルトのセットアップでは不十分な場合に頼りにできるはずです。

### jsbundling-rails

[`jsbundling-rails`](https://github.com/rails/jsbundling-rails) gemを使うと、`importmap-rails`方式の代わりに以下のいずれかをJavaScriptのバンドルに利用できるようになります。

- [Bun](https://bun.sh)
- [esbuild](https://esbuild.github.io/)
- [rollup.js](https://rollupjs.org/)
- [Webpack](https://webpack.js.org/)

`jsbundling-rails` gemは、`yarn build --watch`プロセスを提供し、development環境で自動的に出力を生成します。production環境では`javascript:build`タスクを`assets:precompile`タスクに自動的にフックし、パッケージの依存関係がすべてインストールされ、すべてのエントリポイントに対してJavaScriptがビルドされるようにできます。

**`importmap-rails`の代わりに使うのがよい場合**: JavaScriptコードがトランスパイルに依存している場合（例: [Babel](https://babeljs.io/)、[TypeScript](https://www.typescriptlang.org/)、 React JSXフォーマット）は、`jsbundling-rails`が正しい方法となります。

### Webpacker/Shakapacker

[`Webpacker`](https://github.com/rails/webpacker)は、Rails 5および6のデフォルトのJavaScriptプリプロセッサ兼バンドラでした。現在は開発が終了しています。後継として[`shakapacker`](https://github.com/shakacode/shakapacker)が存在しますが、Railsチームやプロジェクトはメンテナンスしていません。

このリストにある他のライブラリと異なり、`webpacker`/`shakapacker`はSprocketsから完全に独立していて、JavaScriptとCSSの両方のファイルを処理できます。

NOTE: `jsbundling-rails`と`webpacker`/`shakapacker`の違いについては、[Webpackerとの比較](https://github.com/rails/jsbundling-rails/blob/main/docs/comparison_with_webpacker.md)ドキュメントをお読みください。

### cssbundling-rails

[`cssbundling-rails`](https://github.com/rails/cssbundling-rails) gemは、以下のいずれかを利用するCSSをバンドルおよび処理して、アセットパイプライン経由でCSSを配信します。

- [Tailwind CSS](https://tailwindcss.com/)
- [Bootstrap](https://getbootstrap.com/)
- [Bulma](https://bulma.io/)
- [PostCSS](https://postcss.org/)
- [Dart Sass](https://sass-lang.com/)

`cssbundling-rails`の動作は`jsbundling-rails`と似ています。development環境では`yarn build:css --watch`プロセスでスタイルシートを再生成し、production環境では`assets:precompile`タスクにフックしてアプリケーションにNode.js依存関係を追加します。

**Sprocketsとの違い**: Sprockets単体ではSassをCSSにトランスパイルできないため、`.sass`ファイルから`.css`ファイルを生成するためにNode.jsが必要です。`.css`ファイルが生成されれば、Sprocketsからクライアントに配信できるようになります。

NOTE: `cssbundling-rails`はCSSの処理をNode.jsに依存しています。
`dartsass-rails` gemと`tailwindcss-rails` gemは、それぞれTailwind CSSとDart Sassのスタンドアロン版実行ファイルを使うので、Node.jsに依存しません。
JavaScriptを`importmap-rails`で処理し、CSSを`dartsass-rails`または`tailwindcss-rails`で処理する形にすれば、Node依存を完全に避けられるので、よりシンプルなソリューションとなります。

### dartsass-rails

アプリケーションで [Sass](https://sass-lang.com/)を使いたい場合は、レガシーな`sassc-rails` gemの代わりにこの[`dartsass-rails`](https://github.com/rails/dartsass-rails) gemが提供されています。
`dartsass-rails` gemは、`sassc-rails` gemで使われていた[LibSass](https://sass-lang.com/blog/libsass-is-deprecated)（2020年に非推奨化）に代えてDart Sassの実装を利用しています。

この新しい`dartsass-rails` gemは`sassc-rails`とは異なり、Sprocketsと直接統合されているわけではありません。インストールや移行の手順については、[dartsass-rails gem](https://github.com/rails/dartsass-rails)のドキュメントを参照してください。

WARNING: 以前広く使われていた`sassc-rails` gemは、2019年以降メンテナンスされていません。

### tailwindcss-rails

[`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails) gemは、Tailwind CSS v3フレームワークの[スタンドアロン実行可能版](https://tailwindcss.com/blog/standalone-cli)をラップしています。新しいアプリケーションを開発する際に、`rails new`コマンドに `--css tailwind`を指定することで利用できます。development環境では、Tailwindの出力を自動的に生成するための`watch`プロセスが提供されます。production環境では、`assets:precompile`タスクにフックします。
