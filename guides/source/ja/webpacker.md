Webpacker の概要
=========

本ガイドではWebpackerのインストール方法と、Railsアプリケーションのクライアント側で用いるJavaScriptやCSSなどのアセットをWebpackerで利用する方法について解説します。**ただし[Webpackerの開発は終了した](https://github.com/rails/webpacker#webpacker-has-been-retired-)点にご注意ください。(訳注: 移行方法は末尾の[参考資料](#追加のドキュメント)をご参照ください)**

このガイドの内容:

* Webpackerとは何か、およびSprocketsと異なっている理由
* Webpackerのインストール方法、および選択したフレームワークとの統合方法
* JavaScriptアセットをWebpackerで管理する方法
* CSSアセットをWebpackerで管理する方法
* 静的アセットをWebpackerで管理する方法
* Webpackerを利用しているサイトのデプロイ方法
* WebpackerをRailsエンジンやDockerコンテナなどの異なるコンテキストで利用する方法


--------------------------------------------------------------

Webpackerとは
------------------

Webpackerは、汎用的な[webpack](https://webpack.js.org)ビルドシステムのRailsラッパーであり、標準的なwebpackの設定と合理的なデフォルト設定を提供します。

### webpackとは

webpackなどのフロントエンドビルドシステムの目的は、開発者にとって使いやすい方法でフロントエンドのコードを書き、そのコードをブラウザで利用しやすい方法でパッケージ化することです。webpackは「JavaScript」「CSS」「画像やフォント」といった静的アセットを管理できます。webpackを使うと、「JavaScriptコードの記述」「アプリケーション内の他のコードの参照」「コードの変換（トランスパイル）や結合」をダウンロードしやすいpackにまとめられます。

詳しくは[webpackのドキュメント](https://webpack.js.org)を参照してください。

### WebpackerがSprocketsと異なる理由

RailsにはSprocketsも同梱されています。SprocketsもWebpackerと同様のアセットパッケージングツールで、Webpackerと機能が重複しています。どちらのツールも、JavaScriptをブラウザに適したファイルにコンパイルすることでproduction環境でのminifyやフィンガープリント追加を行えます。development環境では、SprocketsもWebpackerもファイルをインクリメンタルに変更できます。

SprocketsはRailsで使われる前提で設計されているため、統合方法はWebpackerよりもシンプルで、Ruby gemを用いてSprocketsにコードを追加できます。webpackは、より新しいJavaScriptツールやnpmパッケージとの統合に優れており、より多くのものを統合できます。新しいRailsアプリは「JavaScriptはwebpackで管理する」「CSSはSprocketsで管理する」設定になっていますが、webpackでCSSを管理することもできます。

新しいプロジェクトで「npmパッケージを使いたい場合」「最新のJavaScript機能やツールにアクセスしたい場合」は、Sprocketsではなくwebpackerを選択すべきでしょう。「移行にコストがかかるレガシーアプリケーション」「gemで統合したい場合」「パッケージ化するコードの量が非常に少ない場合」は、WebpackerではなくSprocketsを選ぶべきでしょう。

Sprocketsに慣れ親しんでいる方は、以下の表を参考に両者の対応関係を理解するとよいでしょう。なお、ツールごとに構造が微妙に異なっているため、必ずしも概念が直接対応しているとは限らない点にご注意ください。

|タスク             | Sprockets            | Webpacker         |
|------------------|----------------------|-------------------|
|JavaScriptをアタッチする |`javascript_include_tag`|`javascript_pack_tag`|
|CSSをアタッチする        |`stylesheet_link_tag`   |`stylesheet_pack_tag`|
|画像にリンクする         |`image_url`             |`image_pack_tag`     |
|アセットにリンクする      |`asset_url`             |`asset_pack_tag`     |
|スクリプトをrequireする  |`//= require`         |`import`または`require`  |

Webpackerをインストールする
--------------------

Webpackerを使うには、Yarnパッケージマネージャー（1.x以上）とNode.js（10.13.0以上）のインストールが必要です。

NOTE: WebpackerはnpmとYarnに依存しています。npm（Node Package Manager）レジストリは、Node.jsとブラウザランタイムの両方で、主にオープンソースのJavaScriptプロジェクトの公開やダウンロードに用いられるリポジトリです。npmの位置づけは、Rubyのgemを扱うrubygems.orgに似ています。Yarnコマンドラインユーティリティは、RubyのBundlerと位置づけが似ています。BundlerがRubyの依存関係のインストールや管理を行うのと同様に、YarnはJavaScriptの依存関係をインストールおよび管理できます。

新規プロジェクトにWebpackerを含めるには、`rails new`コマンドに`--webpack`を追加します。
既存のプロジェクトにWebpackerを追加するには、プロジェクトの`Gemfile`に`webpacker` gemを追加して`bundle install`を実行し、続いて`bin/rails webpacker:install`を実行します。

|ファイルとフォルダ        |場所                     |説明                     |
|------------------------|------------------------|------------------------|
|JavaScriptフォルダ       | `app/javascript`       |フロントエンド向けJavaScriptソースコードの置き場所 |
|Webpacker設定ファイル     | `config/webpacker.yml` |Webpacker gemを設定する |
|Babel設定ファイル         | `babel.config.js`      |[Babel](https://babeljs.io)（JavaScriptコンパイラ）の設定 |
|PostCSS設定ファイル       | `postcss.config.js`    |[PostCSS](https://postcss.org)（CSSポストプロセッサ）の設定|
|Browserlistファイル      | `.browserslistrc`      |[Browserlist](https://github.com/browserslist/browserslist)（対象ブラウザを管理する）設定 |

また、インストールコマンドは`yarn`パッケージマネージャを呼び出して`package.json`というファイルを作成し、基本的なパッケージセットのリストをこのファイルに含めます。これらの依存関係はYarnでインストールされます。

使い方
-----

### JavaScriptをWebpacker経由で利用する

Webpackerをインストールすると、`app/javascript/packs`ディレクトリ以下のJavaScriptファイルがコンパイルされて独自のpackファイルにまとめられます。

たとえば、`app/javascript/packs/application.js`というファイルが存在すると、Webpackerは`application`という名前のpackを作成します。このpackは、`<%= javascript_pack_tag "application" %>`というERBコードが使われているRailsアプリケーションで追加されます。これによって、development環境では`application.js`が変更されるたびに再コンパイルされ、ページを読み込むとコンパイル後のpackが使われます。実際の`pack`ディレクトリに置かれるのは、主に他のファイルを読み込むマニフェストファイルですが、任意のJavaScriptコードも置けます。

RailsのデフォルトJavaScriptパッケージがプロジェクトに含まれていれば、Webpackerで作成されたデフォルトのpackはそのデフォルトJavaScriptパッケージにリンクします。

```javascript
import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
Turbolinks.start()
ActiveStorage.start()
```

これらのパッケージをRailsアプリケーションで使うには、これらのパッケージを`require`するパックをインクルードする必要があります。

`app/javascript/packs`ディレクトリにはwebpackのエントリーファイルだけを置き、それ以外のものを置かないことが重要です。webpackはエントリーポイントごとに個別の依存関係グラフを作成するので、packを多数作成するとコンパイルのオーバーヘッドが大きくなります（アセットのその他のソースコードはこのディレクトリの外に置くべきです: Webpacker自身はソースコードの構造に制約をかけませんが、適切なソースコード構造を提案することもありません）。以下はソースコード構造の例です。

```sh
app/javascript:
  ├── packs:
  │   # ここにはwebpackエントリーファイルだけを置くこと
  │   └── application.js
  │   └── application.css
  └── src:
  │   └── my_component.js
  └── stylesheets:
  │   └── my_styles.css
  └── images:
      └── logo.svg
```

通常、packファイル自体は`import`や`require`で必要なファイルを読み込むマニフェストですが、いくつかの初期化を行うこともあります。

これらのディレクトリを変更したい場合は、`config/webpacker.yml`ファイルの`source_path`（デフォルトは`app/javascript`ディレクトリ）と`source_entry_path`（デフォルトは`packs`ディレクトリ）も変更してください。

JavaScriptソースファイル内の`import`ステートメントは、インポートするファイルの位置を「相対的に」解決します。つまり、`import Bar from "./foo"`と書くと、現在いるディレクトリにある`foo.js`ファイルを探索しますが、`import Bar from "../src/foo"`と書くと`src` という名前の親ディレクトリにあるファイルを探索します。

### CSSをWebpacker経由で利用する

Webpackerでは、PostCSSプロセッサを用いてCSSやSCSSのサポートを即座に利用できます。

CSSコードをpackにインクルードするには、まずCSSファイルをトップレベルのpackファイルにインクルードします（JavaScriptファイルをインクルードするときと同じ要領です）。つまり、CSSのトップレベルマニフェストが`app/javascript/styles/styles.scss`にある場合は、`import styles/styles` でインポートします。これにより、webpackがCSSファイルをダウンロードに含められるようになります。実際にWebページで読み込むには、ビューのコードに`<%= stylesheet_pack_tag "application" %>`を追加します。

CSSフレームワークを用いる場合は、フレームワークを`yarn`でnpmモジュールとして読み込むインストール手順（`yarn add <フレームワーク名>`が典型）に従えば、Webpackerにフレームワークを追加できます。たいていのフレームワークには、CSSやSCSSファイルにインポートする手順があるはずです。

### 静的アセットをWebpacker経由で利用する

Webpackerのデフォルト[設定](https://github.com/rails/webpacker/blob/master/lib/install/config/webpacker.yml#L21)では、画像やフォントなどの静的アセットもすぐに使えるようになっています。この設定には画像ファイルやフォントファイルのフォーマットに対応する拡張子が多数含まれており、webpackはそれらの拡張子も生成された`manifest.json`ファイルに追加します。

webpackのおかげで、以下のコード例のように静的アセットをJavaScriptファイル内で直接インポートできます。インポートされた値は、そのアセットへのURLを表します。

```javascript
import myImageUrl from '../images/my-image.jpg'

// ...
let myImage = new Image();
myImage.src = myImageUrl;
myImage.alt = "I'm a Webpacker-bundled image";
document.body.appendChild(myImage);
```

Webpackerの静的アセットをRailsのビューで参照する必要がある場合は、WebpackerにバンドルされるJavaScriptファイルで明示的に`require`する必要があります。Sprockets とは異なり、Webpackerはデフォルトでは静的アセットをインポートしない点にご注意ください。デフォルトの`app/javascript/packs/application.js`ファイルには、指定のディレクトリからファイルをインポートするテンプレートがコメントの形で用意されているので、静的ファイルを置きたいディレクトリごとにコメント解除して利用できます。ディレクトリは`app/javascript`を起点とする相対パスです。テンプレートでは`images`というディレクトリ名になっていますが、`app/javascript`の中であれば任意のディレクトリ名に変更できます。

```javascript
const images = require.context("../images", true)
const imagePath = name => images(name, true)
```

静的アセットは、`public/packs/media`ディレクトリ以下に出力されます。たとえば、`app/javascript/images/my-image.jpg`にある画像をインポートすると、`public/packs/media/images/my-image-abcd1234.jpg`に出力されます。この画像の`image`タグをRailsのビューでレンダリングするには、`image_pack_tag 'media/images/my-image.jpg`を使います。

Webpackerで静的アセットを扱う場合のAction Viewヘルパーについては、以下の表でアセットパイプラインのヘルパーとの対応を確認できます。

|ActionViewヘルパー | Webpackerヘルパー |
|------------------|------------------|
|`favicon_link_tag`  |`favicon_pack_tag`  |
|`image_tag`         |`image_pack_tag`    |


`asset_pack_path`というジェネリックなヘルパーも利用できます。このヘルパーにローカルファイルのパスを渡すと、Railsのビューで使えるWebpackerパスを返します。

また、`app/javascript`のCSSファイルから直接ファイルを参照して画像にアクセスすることもできます。

### RailsエンジンでのWebpacker利用について

バージョン5の時点のWebpackerは「Railsエンジン対応」では**ありません**。つまりWebpackerは、Railsエンジンで利用できるSprocketsと機能的な互換性がありません。

Railsエンジンgemの作者がWebpackerの利用をサポートする場合は、フロントエンドアセットをgem本体に追加してnpmパッケージとして配布し、ホストアプリケーションとの統合方法を説明する指示書（またはインストーラ）を提供することが推奨されます。[Alchemy CMS](https://github.com/AlchemyCMS/alchemy_cms)は、このアプローチの良い例です。

### webpackのHot Module Replacement（HMR）について

Webpackerは、webpack-dev-serverでのHMR（Hot Module Replacement）をすぐ利用できるようになっており、`webpacker.yml`ファイルで`dev_server/hmr`オプションを設定することで切り替えられます。

詳しくはwebpackの[DevServerドキュメント](https://webpack.js.org/configuration/dev-server/#devserver-hot)を参照してください。

ReactでHMRをサポートするには、react-hot-loaderの追加が必要です。詳しくはReact Hot Loaderの[Getting Startedガイド](https://gaearon.github.io/react-hot-loader/getstarted/)を参照してください。

webpack-dev-serverを実行していない場合は、HMRを**必ず**無効にしてください。そうしないと、CSSで"not found error"エラーが発生します。

環境ごとのWebpacker設定について
-----------------------------------

Webpackerにはデフォルトで`development`、`test`、`production`の3つの環境があります。`webpacker.yml` ファイルに環境設定を追加することで、環境ごとに異なるデフォルトを設定できます。また、Webpackerは環境設定を追加するために`config/webpack/<environment>.js` ファイルを読み込みます。

## development環境でWebpackerを実行する

Webpackerには、development環境で実行する`./bin/webpack`と`./bin/webpack-dev-server`という2つのbinstubファイルが同梱されます。これらのbinstubファイルは、標準の実行ファイルである`webpack.js`と`webpack-dev-server.js`の薄いラッパーになっており、環境に応じて適切な設定ファイルや環境変数が読み込まれるようになっています。

development環境のWebpackerは、デフォルトでRailsページが読み込まれると必要に応じて自動的にコンパイルを行います。つまり別のプロセスの実行は不要であり、コンパイルエラーは標準のRailsログに出力されます。これを変更するには、`config/webpacker.yml`ファイルを`compile: false`に変更します。`bin/webpack`を実行すると、packを強制的にコンパイルします。

コードのライブリロード機能を使いたい場合や、JavaScriptコードが多くてオンデマンドのコンパイルが遅くなる場合は、`./bin/webpack-dev-server`または`ruby ./bin/webpack-dev-server` を実行する必要があります。webpack-dev-serverのプロセスは、`app/javascript/packs/*.js`ファイルの変更を監視して変更時に自動的に再コンパイルし、ブラウザを再読み込みします。

Windowsユーザーは、これらのコマンドを`bundle exec rails server`とは別のターミナルで実行する必要があります。

このdevelopmentサーバーを起動すると、Webpackerが自動的にすべてのwebpackアセットリクエストをこのサーバーにプロキシします。サーバーを停止すると、オンデマンドのコンパイルに戻ります。

[Webpackerドキュメント](https://github.com/rails/webpacker)には、`webpack-dev-server`を制御する環境変数の情報が記載されています。また、rails/webpackerの[webpack-dev-server利用法](https://github.com/rails/webpacker#development)ドキュメントにある追加の注意事項も参照してください。

### Webpackerをデプロイする

Webpackerは`bin/rails assets:precompile`のrakeタスクに`webpacker:compile`タスクを追加するので、`assets:precompile`を使う既存のデプロイパイプラインはすべて動作します。`webpacker:compile`タスクはpackをコンパイルして`public/packs`に配置します。

追加のドキュメント
------------------------

Webpackerでメジャーなフレームワークを利用する方法などの高度な話題については、[Webpackerドキュメント](https://github.com/rails/webpacker)を参照してください。
