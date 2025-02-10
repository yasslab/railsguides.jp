アセットパイプライン
==================

本ガイドでは、必要なアセット管理タスクの処理方法について解説します。

このガイドの内容:

* アセットパイプラインについて
* Propshaftの主な機能とセットアップ方法
* SprocketsからPropshaftへの移行方法
* より高度なアセット管理用ライブラリの利用法

--------------------------------------------------------------------------------


アセットパイプラインについて
---------------------------

Railsのアセットパイプライン（Asset Pipeline）は、JavaScript、CSS、画像ファイルなどの静的アセットを整理・キャッシュ・配信するために設計されたライブラリです。これらのアセットの管理を合理化および最適することで、アプリケーションのパフォーマンスとメンテナンス性を高めます。

Railsのアセットパイプラインは、[**Propshaft**](https://github.com/rails/propshaft)によって管理されています。Propshaftは、基本的なアプリケーションにおけるトランスパイルやバンドルや圧縮が、ブラウザでのサポート強化やネットワーク高速化、HTTP/2機能によって以前ほど重要ではなくなった時代に合わせて構築されています。

Propshaftは、基本的なアセット管理タスクに特化しています。JavaScriptやCSSのバンドルや最小化といった複雑なタスクについては、アプリケーションで個別に追加できる[`js-bundling-rails`](https://github.com/rails/jsbundling-rails)や[`css-bundling-rails`](https://github.com/rails/cssbundling-rails)などの専用ツールに任せています。Propshaftは[フィンガープリント](#フィンガープリント-ダイジェストベースのurlによるバージョニング)の処理に重点を置いており、アセットのダイジェストをベースとしたURLを生成することに注力しています。これにより、ブラウザがアセットをキャッシュできるようになり、複雑なコンパイルやバンドルの必要性が最小限に抑えられます。

[Propshaft](https://github.com/rails/propshaft) gemは、新しいアプリケーションではデフォルトで有効になっています。何らかの理由で`rails new`で無効にしたい場合は、`--skip-asset-pipeline`オプションを指定できます。

```bash
$ rails new app_name --skip-asset-pipeline
```

NOTE: Rails 8より前のバージョンのアセットパイプラインは、[Sprockets](https://github.com/rails/sprockets) gemによって実行されていました。Sprocketsによるアセットパイプラインについては、[Railsガイドの以前のバージョン](https://railsguides.jp/v7.2/asset_pipeline.html)で読めます。また、Railsのアセットパイプラインが時間の経過とともにどのように進化してきたかについては、本ガイドで後述する[アセット管理技術の進化](#アセット管理技術の進化)で確認できます。

Propshaftの機能
------------------

Propshaftでは、アセットがすでにブラウザ対応の形式（プレーンCSS、JavaScript、前処理済みのJPEG画像やPNG画像など）になっていることを前提としています。Propshaftの役割は、それらのアセットを効率的に整理・バージョニングしてブラウザに配信することです。本セクションでは、Propshaftの主な機能とその仕組みについて解説します。

### アセットの読み込み順

Propshaftを使うと、依存ファイルの読み込み順序を制御できます。これは、各アセットファイルを明示的に指定して手動で読み込み順を制御するか、HTML内やレイアウトファイル内に適切な順序で配置することで行います。これにより、自動化された依存関係管理ツールに依存せずに、依存関係の管理や読み込みを行えるようになります。以下は、依存関係を管理するためのいくつかの戦略です。

1. アセットを手動で正しい順序で指定する

    HTMLレイアウトファイル（Railsアプリの場合は通常`application.html.erb`）では、各アセットファイルを以下のように特定の順序で個別に記述することで、CSSファイルやJavaScriptファイルの読み込み順序を正確に指定できます。

    ```erb
    <!-- application.html.erb -->
    <head>
     <%= stylesheet_link_tag "reset" %>
     <%= stylesheet_link_tag "base" %>
     <%= stylesheet_link_tag "main" %>
    </head>
    <body>
     <%= javascript_include_tag "utilities" %>
     <%= javascript_include_tag "main" %>
    </body>
    ```

    たとえば、`main.js`が`utilities.js`に依存していて`utilities.js`を最初に読み込む必要がある場合、この順序で指定することが重要です。

2. JavaScriptのモジュール（ES6）を利用する

    JavaScriptファイル内に依存関係がある場合は、ES6モジュールが役立つことがあります。JavaScriptコード内の依存関係は、`import`ステートメントで明示的に制御できます。HTMLで`<script type="module">`を記述して、JavaScriptファイルがモジュールとして設定されるようにしてください。

    ```javascript
    // main.js
    import { initUtilities } from "./utilities.js";
    import { setupFeature } from "./feature.js";

    initUtilities();
    setupFeature();
    ```

    main.jsで上のように指定したら、レイアウトファイルで以下の記述を追加します。

    ```erb
    <script type="module" src="main.js"></script>
    ```

    こうすることで、Propshaftに依存することなくJavaScriptファイル内の依存関係を管理できます。モジュールをインポートすることで、ファイルが読み込まれる順序を制御して依存関係を満たせるようになります。

3. 必要に応じてファイルを組み合わせる

    常に一緒に読み込まれなければならないJavaScriptファイルやCSSファイルが複数ある場合は、それらを1つのファイルにまとめられます。たとえば、他のスクリプトからコードをインポートまたはコピーする`combined.js`ファイルを作成できます。次にレイアウトファイルで`combined.js`を指定すれば、ファイルが別々に順序付けされるのを回避できます。これは、ユーティリティ関数のセットや特定のコンポーネント用のスタイルのグループなど、常に一緒に読み込まれる必要があるファイルで有用です。このアプローチは、小規模なプロジェクトや単純なユースケースでは機能しますが、大規模なアプリケーションでは手間が増えてエラーが発生しやすくなる可能性があります。

4. バンドラーでJavaScriptやCSSをバンドルする

    プロジェクトで依存関係の連鎖やCSSの前処理などの機能が必要な場合は、Propshaft以外の[高度なアセット管理](#高度なアセット管理)も検討してください。

    [`js-bundling-rails`](https://github.com/rails/jsbundling-rails)などのツールは、[Bun](https://bun.sh/)、[esbuild](https://esbuild.github.io/)、[rollup.js](https://rollupjs.org/)、[Webpack](https://webpack.js.org/)をRails アプリケーションに統合します。

    一方、[`css-bundling-rails`](https://github.com/rails/cssbundling-rails)は、スタイルシートを[Tailwind CSS](https://tailwindcss.com/)、[Bootstrap](https://getbootstrap.com/)、[Bulma](https://bulma.io/)、[PostCSS](https://postcss.org/)、[Dart Sass](https://sass-lang.com/)などで処理するために利用できます。

    これらのツールが複雑な処理を担当することでPropshaftを補完し、Propshaftは最終アセットを効率的に整理して配信することに専念します。

### アセットの編成

Propshaftは、アセットを`app/assets/`ディレクトリ内で編成します。このディレクトリには、`images`、`javascripts`、`stylesheets`などのサブディレクトリが含まれます。JavaScript、CSS、画像ファイル、その他のアセットをこれらのディレクトリの下に配置すると、プリコンパイルプロセス中にPropshaftがそれらのアセットを管理します。

また、`config/initializers/assets.rb`ファイルの`config.assets.paths`設定を以下のように変更することで、Propshaftが探索するアセットパスを追加することも可能です。

```ruby
# アセット読み込みパスにアセットを追加する
Rails.application.config.assets.paths << Emoji.images_path
```

Propshaftは、設定されたパスにあるすべてのアセットを配信できるようにします。Propshaftは、プリコンパイルプロセス中にこれらのアセットを`public/assets/`ディレクトリにコピーすることで、production環境で利用可能な状態にします。

アセットは、`asset_path`、`image_tag`、`javascript_include_tag`、その他のアセットヘルパータグなどのヘルパーを使うことで、[論理パスを介して参照](#ダイジェスト化されたアセットをビューで利用する)できます。[production環境で`assets:precompile`を実行](#production環境の場合)すると、これらの論理参照は[`.manifest.json`ファイル](#マニフェストファイル)によって自動的にフィンガープリントパスに変換されます。

このプロセスから特定のディレクトリを除外することもできます。詳しくは以下の[フィンガープリント](#フィンガープリント-ダイジェストベースのurlによるバージョニング)セクションを参照してください。

### フィンガープリント: ダイジェストベースのURLによるバージョニング

Rails では、アセットのバージョニングでフィンガープリント（fingerprinting）を利用することで、アセットのファイル名に一意の識別子を追加します。

フィンガープリンティングとは、ファイルの内容に応じてファイル名を決定する手法で、ファイルの内容を元に一定の長さのダイジェストを生成してファイル名に追加します。こうすることで、ファイルの内容が少しでも変更されると、ファイルのダイジェストも変化し、ひいてはファイル名も変化します。
このメカニズムは、アセットを効果的にキャッシュするために不可欠です。コンテンツが変更されたときに、ブラウザは常に更新版のアセットを読み込むので、パフォーマンスが向上します。静的なコンテンツや更新が頻繁でないコンテンツの場合、これにより、サーバーが異なっていたりデプロイ日時が異なっていても、2つのファイルのバージョンが同一であるかどうかをアセットファイル名のダイジェストで簡単に判別できます。

#### アセットのダイジェスト化

[アセットの編成](#アセットの編成)で述べたように、Propshaftでは、`config.assets.paths`で設定されたパスにあるすべてのアセットを配信可能です。これらのアセットは`public/assets/`ディレクトリにコピーされます。

フィンガープリントが行われると、`styles.css`などのアセットファイル名はたとえば`styles-a1b2c3d4e5f6.css`のような名前に変更されます。これにより、`styles.css`が更新されるとファイル名も必ず変更され、ブラウザはキャッシュされた古いコピーではなく最新バージョンのアセットファイルをダウンロードするようになります。

#### マニフェストファイル

Propshaftは、アセットのプリコンパイル中に `.manifest.json`ファイルを自動的に生成します。このマニフェスト（manifest）ファイルは、元のアセットファイル名をフィンガープリント付きのファイル名に対応付けて、適切なキャッシュ無効化と効率的なアセット管理を保証します。`public/assets/`ディレクトリにある`.manifest.json`ファイルは、Railsが実行時にアセットパスを解決するのに役立ち、適切にフィンガープリントされたファイルを参照できるようにします。

`.manifest.json`ファイルには、`application.js`や`application.css`などのメインアセットのエントリと、画像などのその他のファイルが含まれます。このJSONファイルの例を以下に示します。

```json
{
  "application.css": "application-6d58c9e6e3b5d4a7c9a8e3.css",
  "application.js": "application-2d4b9f6c5a7c8e2b8d9e6.js",
  "logo.png": "logo-f3e8c9b2a6e5d4c8.png",
  "favicon.ico": "favicon-d6c8e5a9f3b2c7.ico"
}
```

ファイル名が一意で、ダイジェストがファイルの内容に基づいている場合、HTTPヘッダーを設定して、あらゆる場所（CDN、ISP、ネットワーク機器、Webブラウザなど）のキャッシュに、コンテンツのコピーを独自に保持することを促進できます。コンテンツが更新されればフィンガープリントも変更されるので、リモートクライアントはコンテンツの新しいコピーをリクエストします。これは一般にキャッシュバスティング（cache busting）と呼ばれます。

#### ダイジェスト化されたアセットをビューで利用する

Rails標準のアセットヘルパー（`asset_path`、`image_tag`、`javascript_include_tag`、`stylesheet_link_tag`など）を利用することで、ビューでダイジェストアセットを参照できます。

たとえば、レイアウトファイルでは、スタイルシートを以下のように指定できます。

```erb
<%= stylesheet_link_tag "application", media: "all" %>
```

Railsにデフォルトで含まれる[`turbo-rails`](https://github.com/hotwired/turbo-rails) gemを使っている場合は、以下のように`data-turbo-track`オプションも指定できます。これにより、Turboはアセットが更新されたかどうかを確認し、更新されている場合はページで再読み込みします。

```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

`app/assets/images/`ディレクトリの下にある画像は、ビューで以下のようにアクセスできます。

```erb
<%= image_tag "rails.png" %>
```

アセットパイプラインが有効になっていれば、この画像ファイルはPropshaftによって配信されます。ファイルが`public/assets/rails.png`に存在する場合は、Webサーバーによって配信されます。

あるいは、フィンガープリント化されたアセット（例: `rails-f90d8a84c707a8dc923fca1ca1895ae8ed0a09237f6992015fef1e11be77c023.png`）を使う場合、これらもPropshaftによって正しく配信されます。フィンガープリントは、プリコンパイルプロセス中に自動的に適用されます。

画像ファイルはサブディレクトリで分類することも可能で、以下のようにタグでディレクトリを指定して参照できます。

```erb
<%= image_tag "icons/rails.png" %>
```

最後に、CSSファイル内でも以下のように画像を参照できます。

```css
background: url("/bg/pattern.svg");
```

Propshaftは上を自動的に以下に変換します。

```css
background: url("/assets/bg/pattern-2169cbef.svg");
```

WARNING: アセットをプリコンパイルするときに（[production環境](#production環境の場合)を参照）、存在しないアセットにリンクしていると、呼び出しページで例外が発生します。これには、空文字列へのリンクも含まれます。ユーザーがアップロードして提供したデータに対して`image_tag`などのヘルパーを利用する場合は注意してください。これらに注意することで、ブラウザが常に正しいバージョンのアセットを取得するようになります。

#### ダイジェスト化されたアセットをJavaScriptで利用する

JavaScriptでアセットにアクセスするには、`RAILS_ASSET_URL`マクロを用いてアセット変換を手動でトリガーする必要があります。以下に例を示します。

```javascript
export default class extends Controller {
  init() {
    this.img = RAILS_ASSET_URL("/icons/trash.svg");
  }
}
```

上のコードは以下のように変換されます。

```javascript
export default class extends Controller {
  init() {
    this.img = "/assets/icons/trash-54g9cbef.svg";
  }
}
```

これにより、JavaScriptコードで正しいダイジェストファイルを利用可能になります。

[Webpack](https://webpack.js.org/)や[esbuild](https://esbuild.github.io/)などのバンドラーを利用する場合は、ダイジェスト処理をこれらのバンドラーに任せる必要があります。Propshaftは、ファイル名にすでにダイジェストが含まれていることを検出すると（例: `script-2169cbef.js`）、不要な再処理を避けるためにファイルのダイジェスト処理をスキップします。

アセットを[importmap](#importmap-rails)で管理する場合、importmapで参照されるアセットはPropshaftによって適切に処理され、プリコンパイル中にダイジェストパスにマッピングされます。

#### ダイジェスト処理をバイパスする

ファイルを相互に参照する必要がある場合（JavaScriptファイルとそのsource mapファイルなど）にダイジェスト処理を避けたい場合は、これらのファイルを事前に手動ダイジェストできます。Propshaftは、`-[digest].digested.js`というパターンを持つファイルを「ダイジェスト済みファイル」として認識し、ファイル名を安定させます。

#### ダイジェスト処理から特定ディレクトリを除外する

`config.assets.excluded_pa​​ths`設定で以下のように特定のディレクトリを追加することで、プリコンパイルやダイジェスト処理から除外できます。これは、たとえば`app/assets/stylesheets/`ディレクトリが[Dart Sass](https://sass-lang.com/)などのコンパイラへの入力として使われていて、これらのファイルをアセット読み込みパスの一部にしたくない場合に便利です。

```ruby
config.assets.excluded_paths = [Rails.root.join("app/assets/stylesheets")]
```

これにより、指定のディレクトリはPropshaftで処理されなくなりますが、プリコンパイルプロセスからは除外されません。

Propshaftを利用する
----------------------

Rails 8以降では、Propshaftがデフォルトで同梱されます。Propshaftを使うには、Propshaftを適切に設定して、Railsが効率よく配信できるようにアセットを配置する必要があります。

### セットアップ

RailsアプリケーションでPropshaftを設定するには、以下の手順を実行します。

1. 新しいRailsアプリケーションを作成します。

    ```bash
    $ rails new app_name
    ```

2. アセットを配置します。

    Propshaftは、アセットが`app/assets/`ディレクトリ以下に配置されていることを前提としています。アセットは、JavaScriptファイルの場合は`app/assets/javascripts/`、CSSファイルの場合は`app/assets/stylesheets/`、画像の場合は`app/assets/images/`などのサブディレクトリで分類できます。

    たとえば、`app/assets/javascripts/`ディレクトリで以下のように新しいJavaScriptファイルを作成できます。

    ```javascript
    // app/assets/javascripts/main.js
    console.log("Hello, world!");
    ```

    新しいCSSファイルは`app/assets/stylesheets/`ディレクトリの下で以下のように作成できます。

    ```css
    /* app/assets/stylesheets/main.css */
    body {
      background-color: red;
    }
    ```

3. アプリケーションのレイアウトファイルでアセットにリンクします。

    アプリケーションのレイアウトファイル（通常は`app/views/layouts/application.html.erb`）では、以下のように`stylesheet_link_tag`ヘルパーと`javascript_include_tag`ヘルパーを使ってアセットを追加できます。

    ```erb
    <!-- app/views/layouts/application.html.erb -->
    <!DOCTYPE html>
    <html>
      <head>
        <title>MyApp</title>
        <%= stylesheet_link_tag "main" %>
      </head>
      <body>
        <%= yield %>
        <%= javascript_include_tag "main" %>
      </body>
    </html>
    ```

    このレイアウトファイルには、アプリケーションの`main.css`スタイルシートと`main.js` JavaScriptファイルが含まれます。

4. Railsサーバーを起動します。

    ```bash
    $ bin/rails server
    ```

5. アプリケーションをプレビューします。

    Webブラウザで`http://localhost:3000`を開くと、アセットが含まれたRailsアプリケーションが表示されます。

### development環境の場合

RailsとPropshaftは、development環境でスムーズに開発できるようにするために、production環境とは異なる設定になっています。

#### キャッシュは無効化される

development環境のRailsでは、アセットキャッシュをバイパスするように設定されています。つまり、アセットファイル（CSS、JavaScriptなど）を変更すると、ファイルシステムから最新バージョンを直接配信します。キャッシュは完全にスキップされるため、バージョニングやファイル名の変更について気にする必要はありません。ページを再読み込みするたびに、ブラウザは自動的に最新バージョンのアセットを取得します。

#### アセットの自動再読み込み

development環境でPropshaftを単体で利用すると、リクエストのたびにJavaScript、CSS、画像などのアセットの更新が自動的にチェックされます。つまり、これらのファイルを編集してブラウザをリロードすると、Railsサーバーを再起動せずに変更をブラウザ上で即座に確認できます。

[esbuild](https://esbuild.github.io/)や[Webpack](https://webpack.js.org/)などのJavaScriptバンドラーをPropshaftと併用する場合、以下のように両方のツールをワークフローで効果的に組み合わせられます。

- バンドラーはJavaScriptファイルとCSSファイルの変更を監視し、適切なビルドディレクトリでコンパイルしてファイルを最新の状態に保ちます。
- Propshaftは、リクエストが行われるたびに最新のコンパイル済みアセットがブラウザに提供されるようにします。

これらの設定では、`./bin/dev`コマンドを実行したときに、Railsサーバーとアセットバンドラーの開発用サーバーが両方とも起動します。

どちらの場合でも、Propshaftは、サーバーを再起動しなくても、ブラウザページがリロードされたらアセットへの変更がただちに反映されるようにします。

#### ファイルウォッチャー

development環境のPropshaftは、アプリケーションのファイルウォッチャー（デフォルトでは `ActiveSupport::FileUpdateChecker`）によって、各リクエストの前にアセットが更新されたかどうかをチェックします。アセットの数が多い場合は、`listen` gemを追加して、`config/environments/development.rb`ファイルに以下の設定を追加することでパフォーマンスが向上します。

```ruby
config.file_watcher = ActiveSupport::EventedFileUpdateChecker
```

これにより、ファイル更新をチェックするオーバーヘッドが削減され、効率よく開発できるようになります。

### Production環境の場合

production環境のRailsは、キャッシュを有効にしてアセットを配信し、パフォーマンスを最適化して、アプリケーションが大量のトラフィックを効率よく処理できるようにします。

#### Production環境のアセットキャッシュとバージョニング

[フィンガープリント](#フィンガープリント-ダイジェストベースのurlによるバージョニング)セクションで説明したように、ファイルの内容が変更されると、そのダイジェストも変更されるため、更新版のファイルがブラウザで使われるようになります。一方、ファイルの内容が変更されていない場合は、キャッシュされたファイルがブラウザで使われます。

#### アセットのプリコンパイル

production環境では、最新バージョンのアセットが配信されるようにするため、デプロイメント中にプリコンパイルが実行されるのが普通です。Propshaftは、完全なトランスパイラ機能を提供するようには設計されていません。ただし、入力->出力コンパイラ設定が提供されており、デフォルトでは、CSSの`url(asset)`関数呼び出しを`url(digested-asset)`に変換し、ソースマッピングのコメントも同様に変換します。

プリコンパイルを手動で実行するには、以下のコマンドを使います。

```bash
$ RAILS_ENV=production rails assets:precompile
```

このコマンドを実行すると、読み込みパス内にあるすべてのアセットがプリコンパイル中にコピーされ（[高度なアセット管理](#高度なアセット管理)を利用している場合はコンパイルが実行され）、ダイジェストハッシュがアセットファイル名に追加されます。

さらに、`ENV["SECRET_KEY_BASE_DUMMY"]`環境変数を以下のように設定すると、一時ファイルに保存されているランダムに生成された`secret_key_base`が利用されるようになります。これは、production環境のsecrets（秘密情報）にアクセスする必要がないビルドステップの一部としてproduction環境用のアセットをプリコンパイルする場合に便利です。

```bash
$ RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 rails assets:precompile
```

production環境のアセットは、デフォルトでは`/assets/`ディレクトリから配信されます。

WARNING: development環境で`rails assets:precompile`コマンドを実行すると、`.manifest.json`というマーカーファイルが生成され、コンパイル済みアセットを配信可能であることがアプリケーションに通知されます。その結果、ソースアセットに変更を加えても、プリコンパイル済みアセットが更新されるまでブラウザに反映されなくなります。developmentモードでアセットが更新されなくなってしまった場合の解決策は、`public/assets/`ディレクトリの下にある`.manifest.json`ファイルを削除することです。また、`rails assets:clobber`コマンドを実行すると、すべてのプリコンパイル済みアセットと`.manifest.json`ファイルを削除できます。これにより、Railsはアセットを即座に再コンパイルして最新の変更を反映するようになります。

NOTE: コンパイル済みファイル名が期待通りに`.js`または`.css`で終わるよう常に確認してください。

##### 遠い将来に期限が切れるヘッダー

プリコンパイル済みのアセットはファイルシステム上に置かれ、Webサーバーから直接クライアントに配信されます。これらプリコンパイル済みアセットには、いわゆる「遠い将来に失効するヘッダー（far-future headers）」はデフォルトでは含まれません。したがって、フィンガープリントのメリットを得るためには、サーバーの設定を更新してこのヘッダを含める必要があります。

Apacheの設定例:

```apache
# Expires* ディレクティブを使う場合はApacheの
# `mod_expires`モジュールを有効にする必要がある
<Location /assets/>
  # Last-Modifiedフィールドが存在する場合はETagの利用は推奨されない
  Header unset ETag
  FileETag None
  # RFCによるとキャッシュは最長でも1年まで
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

#### CDN

[CDN（コンテンツデリバリーネットワーク）](https://ja.wikipedia.org/wiki/%E3%82%B3%E3%83%B3%E3%83%86%E3%83%B3%E3%83%84%E3%83%87%E3%83%AA%E3%83%90%E3%83%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF)は、全世界を対象としてアセットをキャッシュすることを主な目的として設計されています。CDNを利用すると、ブラウザからアセットをリクエストしたときに、ネットワーク上で地理的に最も「近く」にあるキャッシュのコピーが使われます。production環境のRailsサーバーから（中間キャッシュを使わずに）直接アセットを配信しているのであれば、アプリケーションとブラウザの間でCDNを利用するのがベストプラクティスです。

CDNの典型的な利用法は、productionサーバーを"origin"サーバーとして設定することです。つまり、ブラウザがCDN上のアセットをリクエストしてキャッシュが見つからない場合は、オンデマンドでサーバーからアセットファイルを取得してキャッシュします。

たとえば、Railsアプリケーションをexample.comというドメインで運用しており、mycdnsubdomain.fictional-cdn.comというCDNが設定済みであるとします。ブラウザからmycdnsubdomain.fictional-cdn.com/assets/smile.pngがリクエストされると、CDNはいったん元のサーバーのexample.com/assets/smile.pngにアクセスしてこのリクエストをキャッシュします。

CDN上の同じURLに対して次のリクエストが発生すると、キャッシュされたコピーにヒットします。CDNがアセットを直接配信可能な場合は、ブラウザからのリクエストが直接Railsサーバーに到達することはありません。CDNが配信するアセットはネットワーク上でブラウザと「地理的に」近い位置にあるので、リクエストは高速化されます。また、サーバーはアセットの送信に使う時間を節約できるので、アプリケーション本来のコードをできるだけ高速で配信することに専念できます。

##### CDNで静的なアセットを配信する

CDNを設定するには、Railsアプリケーションがインターネット上でproductionモードで運用されており、example.comなどのような一般公開されているURLでアクセス可能になっている必要があります。次に、クラウドホスティングプロバイダが提供するCDNサービスと契約を結ぶ必要もあります。その際、CDNの"origin"設定をRailsアプリケーションのWebサイトexample.comにする必要もあります。originサーバーの設定方法のドキュメントについてはプロバイダーにお問い合わせください。

利用するCDNから、アプリケーションで使うカスタムサブドメイン（例: mycdnsubdomain.fictional-cdn.com）を交付してもらう必要もあります（注: fictional-cdn.comは説明用のドメインであり、少なくとも執筆時点では本当のCDNプロバイダーではありません）。

CDNサーバーの設定が終わったら、今度はブラウザに対して、Railsサーバーに直接アクセスするのではなく、CDNからアセットを取得するように通知する必要があります。これを行なうには、従来の相対パスに代えてCDNをアセットのホストサーバーとするようRailsを設定します。Railsでアセットホストを設定するには、`config/environments/production.rb`の[`config.asset_host`][]を以下のように設定します。

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

この場合、`http://mycdnsubdomain.fictional-cdn.com/assets/smile.png`のようなCDNの完全なURLが生成されます（読みやすくするためダイジェスト文字は省略してあります）。

`smile.png`のコピーがCDNにあれば、CDNが代わりにこのファイルをブラウザに送信します。元のサーバーはリクエストがあったことすら気づきません。ファイルのコピーがCDNにない場合は、CDNが「origin」（この場合は`example.com/assets/smile.png`）を探して今後のために保存しておきます。

一部のアセットだけをCDNで配信したい場合は、以下のようにアセットヘルパーのカスタム`:host`オプションで[`config.action_controller.asset_host`][]の値セットを上書きすることも可能です。

```erb
<%= asset_path 'image.png', host: 'mycdnsubdomain.fictional-cdn.com' %>
```

[`config.action_controller.asset_host`]:
  configuring.html#config-action-controller-asset-host
[`config.asset_host`]:
  configuring.html#config-asset-host

##### CDNのキャッシュの動作をカスタマイズする

CDNは、コンテンツをキャッシュすることで動作します。CDNに保存されているコンテンツが古くなったり壊れていたりすると、メリットよりも害の方が大きくなります。本セクションでは、多くのCDNにおける一般的なキャッシュの動作について解説します。プロバイダによってはこの記述のとおりでないことがありますのでご注意ください。

###### CDNリクエストキャッシュ

CDNはアセットをキャッシュするのに向いていると言われていますが、CDNで実際にキャッシュされているのはアセット単体ではなくリクエスト全体です。リクエストにはアセット本体の他に各種ヘッダーも含まれています。

ヘッダーの中でもっとも重要なのは`Cache-Control`です。これはCDN（およびWebブラウザ）にキャッシュの取り扱い方法を通知するためのものです。たとえば、誰かが実際には存在しないアセット`/assets/i-dont-exist.png`にリクエストを行い、Railsが404エラーを返したとします。このときに有効な`Cache-Control`ヘッダーが存在すると、CDNがこの404エラーページをキャッシュする可能性があります。

###### CDNヘッダをデバッグする

このヘッダが正しくキャッシュされているかどうかを確認する方法の1つは、[curl](https://explainshell.com/explain?cmd=curl+-I+http%3A%2F%2Fwww.example.com)を使う方法です。curlを使ってサーバーとCDNにそれぞれリクエストを送信し、ヘッダーが同じであるかどうかを以下のように確認できます。

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

###### CDNとCache-Controlヘッダ

[`Cache-Control`][]ヘッダーは、リクエストがキャッシュされる方法を定めたW3Cの仕様です。CDNを使わない場合は、ブラウザはこのヘッダ情報に基づいてコンテンツをキャッシュします。このヘッダのおかげで、アセットで変更が発生していない場合にブラウザがCSSやJavaScriptをリクエストのたびに再度ダウンロードせずに済むので、非常に有用です。

アセットの`Cache-Control`ヘッダーは"public"にしておくのが一般的であり、RailsサーバーはCDNやブラウザに対して、そのことをこのヘッダで通知します。アセットが"public"であるということは、そのリクエストをどのキャッシュに保存してもよいということを意味します。

同様に、キャッシュがオブジェクトを保存する期間である`max-age`を設定することもよくあります。この期間を過ぎるとキャッシュは廃棄されます。`max-age`の値は秒単位で指定し、最大値は`31536000`です（1年に相当）。

Railsでは以下の設定でこの期間を指定できます。

```ruby
config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000"
}
```

これで、production環境のアセットがアプリケーションから配信されると、キャッシュは1年間保存されます。多くのCDNはリクエストのキャッシュも保存しているので、この`Cache-Control`ヘッダーはアセットをリクエストするすべてのブラウザ（将来登場するブラウザも含む）に渡されます。ブラウザはこのヘッダを受け取ると、次回再度リクエストが必要になったときに備えて、そのアセットを非常に長い期間キャッシュに保存してよいことを認識します。

[`Cache-Control`]:
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control

###### CDNにおけるURLベースのキャッシュ無効化について

多くのCDNでは、アセットのキャッシュを完全なURLに基いて行います。たとえば以下のアセットへのリクエストがあるとします。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile-123.png
```

上のリクエストのキャッシュは、下のアセットへのリクエストのキャッシュとは完全に異なるものとして扱われます。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`Cache-Control`の`max-age`を遠い将来に設定する場合は、アセットが変更されたときにこれらのキャッシュが確実に無効化されるようにしてください。たとえば、ニコニコマーク画像の色を黄色から青に変更したら、サイトを訪れた人には変更後の青いニコニコマークが見えるようにしたいはずです。

RailsでCDNを併用している場合、Railsのアセットパイプライン設定`config.assets.digest`はデフォルトで`true`に設定されるので、アセットの内容が少しでも変更されれば必ずファイル名も変更されます。

このとき、キャッシュ内の項目を手動で無効にする必要はありません。アセットファイル名が内容に応じて常に一意になるので、ユーザーは常に最新のアセットを利用できます。

SprocketsからPropshaftへの移行
-------------------------------------

### アセット管理技術の進化

ここ数年、Web技術の進化により、Webアプリケーションでのアセットの管理方法に影響を与える大きな変化が起こりました。このような変化には以下のものが含まれます。

1. **ブラウザサポート**: 最新のブラウザでは新しい機能や構文のサポートが強化され、トランスパイルやポリフィルの必要性が減りました。

2. **HTTP/2**: HTTP/2プロトコルの導入により、複数のファイルを並行して配信しやすくなり、アセットをバンドルする必要性が減りました。

3. **ES6+**: 最新のJavaScript構文（ES6以降）はほとんどの最新のブラウザでサポートされているため、トランスパイルの必要性が減りました。

そのため、Propshaftで動作するアセットパイプラインには、デフォルトでアセットの「トランスパイル」「バンドル」「圧縮」機能が含まれなくなりました。ただし、フィンガープリントは引き続き不可欠な機能です。以下では、アセット管理技術の進化と、それらの進化がSprocketsからPropshaftへの変更にどのように影響したかについて詳しく解説します。

#### トランスパイル❌

トランスパイル（transpile）は、コードをある言語やフォーマットから別の言語やフォーマットへ変換する処理に関連します。

たとえば、TypeScriptをJavaScriptに変換する場合を考えてみましょう。

```typescript
const greet = (name: string): void => {
  console.log(`Hello, ${name}!`);
};
```

トランスパイルによって、上のコードは以下のように変わります。

```javascript
const greet = (name) => {
  console.log(`Hello, ${name}!`);
};
```

従来は、CSS変数やネストなどのCSS機能を利用するために[Sass](https://sass-lang.com/)や[Less](https://lesscss.org/)といったプリプロセッサが不可欠でした。現在、最新のCSSはこれらをネイティブにサポートしており、トランスパイルの必要性は薄れています。

#### バンドル❌

バンドル（bundling）は、複数のファイルを1つに結合することで、ブラウザがページをレンダリングするのに必要なHTTPリクエスト数を減らす技術です。

たとえば、アプリケーションに以下の3つのJavaScriptファイルがあるとします。

- menu.js
- cart.js
- checkout.js

これら3つのファイルをバンドルすると、以下の1つのapplication.jsファイルにマージされます。

```javascript
// app/javascript/application.js
// （menu.js、cart.js、checkout.jsの内容が結合されてここに配置される）
```

バンドルは、1ドメインあたりの同時接続数が6～8に制限されていたHTTP/1.1の時代には重要でした。HTTP/2では、ブラウザが複数のファイルを並行して取得するため、最新のアプリケーションではバンドルが以前ほど重要ではなくなりました。

#### 圧縮❌

圧縮（compression）では、ファイルをより効率的な形式でエンコードして、ユーザーに配信するときにサイズをさらに縮小します。一般的な圧縮手法は[Gzip圧縮](https://ja.wikipedia.org/wiki/Gzip)です。

たとえば、200KBのCSSファイルは、Gzip圧縮するとわずか50KBに圧縮されることもあります。ブラウザは、このような圧縮済みファイルを受信時に自動的に解凍することで、帯域幅を節約して速度を向上させます。

ただし、現代ではCDNがアセットを自動圧縮するようになったため、手動で圧縮する必要性は薄れました。

### SprocketsとPropshaftの違い

#### 読み込みの順序

Sprocketsは、ファイルをリンクして正しい順序で読み込まれるようにできます。たとえば、他のファイルに依存するメインのJavaScriptファイルでは、Sprocketsによって依存関係が自動的に管理され、すべてが正しい順序で読み込まれるようになります。

Propshaftでは、これらの依存関係は自動的に処理されませんが、代わりに[アセットの読み込み順序を手動で管理できます](#アセットの読み込み順)。

#### バージョニング

Sprocketsは、アセットが更新されるたびにファイル名にハッシュを追加することでアセットのフィンガープリント処理をシンプルにして、適切なキャッシュ無効化を保証します。

Propshaftでは、特定の側面について手動で処理する必要があります。たとえば、アセットのフィンガープリント処理は行われますが、ファイル名が正しく更新されるようにするには、バンドラーを使うか、JavaScriptファイルの変換を手動でトリガーする必要が生じる場合があります。詳しくは[Propshaftでのフィンガープリント](#フィンガープリント-ダイジェストベースのurlによるバージョニング)セクションを参照してください。

#### プリコンパイル

Sprocketsは、バンドルに明示的に含まれているアセットを処理しました。

対照的に、Propshaftは明示的なバンドルを必要とせずに、画像、スタイルシート、JavaScriptファイルなど、指定されたパスにあるすべてのアセットを自動的に処理します。詳しくは[アセットダイジェスト](#アセットのダイジェスト化)セクションを参照してください。

### SprocketsからPropshaftへの移行手順

Propshaftは意図的に[Sprockets](https://github.com/rails/sprockets-rails)よりもシンプルになっており、そのためSprocketsからの移行に必要な作業がそれなりに増える可能性があります。これは、特に[TypeScript](https://www.typescriptlang.org/)や[Sass](https://sass-lang.com/)のトランスパイルなどのタスクがSprocketsに依存している場合や、この機能を提供するgemを利用している場合に当てはまります。

このような場合は、トランスパイルの利用をやめるか、[`jsbundling-rails`](https://github.com/rails/jsbundling-rails)と[`cssbundling-rails`](https://github.com/rails/cssbundling-rails)で提供されるNode.jsベースのトランスパイラに切り替える必要があります。詳しくは[高度なアセット管理](#高度なアセット管理)セクションを参照してください。

ただし、現在すでにNodeベースのセットアップを用いてJavaScriptとCSSをバンドルしている場合は、Propshaftをワークフローにスムーズに統合できます。バンドルやトランスパイル用の追加ツールは必要ないため、Propshaftは主にアセットのダイジェスト処理と配信を処理します。

移行の主な手順は以下のとおりです。

1. 以下のコマンドを実行して一部のgemを削除します。

    ```bash
    bundle remove sprockets
    bundle remove sprockets-rails
    bundle remove sass-rails
    ```

2. プロジェクトから`config/assets.rb`ファイルと`assets/config/manifest.js`ファイルを削除します。

3. 既にRails 8にアップグレードしている場合は、Propshaftがアプリケーションに含まれています。まだRails 8にアップ具グレードしていない場合は、`bundle add propshaft`コマンドを実行してPropshaftをインストールします。

4. `application.rb`ファイルの`config.assets.paths << Rails.root.join('app', 'assets')`行を削除します。

5. Propshaftは相対パスを使うので、アセットヘルパーのすべてのインスタンス（`image_url`など）を標準URLに置き換えて、アセットヘルパーを移行します。
  たとえば、`image_url("logo.png")`は `url("/logo.png")`に置き換えます。

6. トランスパイルにSprocketsを使っている場合は、Nodeベースのトランスパイラ（Webpack、esbuild、Viteなど）に切り替える必要があります。`jsbundling-rails` gemと`cssbundling-rails` gemを使うことで、これらのツールをRailsアプリケーションに統合できます。

詳しくは、Propshaft READMEの[SprocketsからPropshaftに移行する方法の詳細ガイド](https://github.com/rails/propshaft/blob/main/UPGRADING.md)を参照してください。

## 高度なアセット管理

アセットを処理するためのデフォルトのアプローチが長年にわたって複数存在し、Webが進化するにつれて、JavaScriptを多用するアプリケーションが増え始めました。私たちはRailsドクトリンの[メニューはomakase（おまかせ）](https://rubyonrails.org/doctrine#omakase)を信じているので、Propshaftは、デフォルトで最新のブラウザにproduction環境対応のセットアップを提供することに重点を置いています。

実にさまざまなJavaScriptやCSSフレームワークと拡張機能を利用可能である現代において、すべてに対応できる万能のソリューションは存在しません。ただし、Railsエコシステムでは、デフォルトのセットアップでは不十分な場合に役立つ他のバンドルライブラリも利用できます。

### `jsbundling-rails`

[`jsbundling-rails`](https://github.com/rails/jsbundling-rails) gemを使うと、以下を含む最新JavaScriptバンドラーをRailsアプリケーションに統合できます。

- [Bun](https://bun.sh)
- [esbuild](https://esbuild.github.io/)
- [rollup.js](https://rollupjs.org/)
- [Webpack](https://webpack.js.org/)

これらのツールを使うことでJavaScriptアセットを管理・バンドルできるようになり、柔軟性とパフォーマンスを必要とする開発者にランタイム依存のアプローチを提供します。

#### `jsbundling-rails`のしくみ

1. インストールされると、指定のJavaScriptバンドラーを利用するようにRailsアプリを設定します。
2. JavaScriptアセットをコンパイルするために、`package.json`ファイル内に`build`スクリプトを作成します。
3. 開発中にアセットに変更を加えると、`build:watch`スクリプトによってアセットがライブ更新されます。
4. production環境では、`jsbundling-rails` gemによって、プリコンパイル時にJavaScriptが自動的にビルドされて組み込まれるため、手動による介入を削減できます。デプロイ中にすべてのエントリポイントのJavaScriptをビルドするために、これをRailsの`assets:precompile`タスクにフックします。この統合により、最小限の構成でJavaScriptをproduction環境で使用できるようになります。

`jsbundling-rails` gemはエントリポイントを自動的に検出します。つまり、Railsの規約に沿ってバンドルされる主要なJavaScriptファイルを自動的に特定します。通常は、`app/javascript/`ディレクトリや設定で追加したディレクトリを検索します。Railsの規約に沿うことで、`jsbundling-rails`は複雑なJavaScriptワークフローをシンプルなプロセスでRailsプロジェクトに統合できるようになります。

#### `jsbundling-rails`が適している場合

`jsbundling-rails`は、以下のようなRailsアプリケーションに最適です。

- ES6+、TypeScript、JSXなどの最新のJavaScript機能を必要としている。
- ツリーシェイキング、コード分割、最小化などのバンドラー固有の最適化を活用する必要がある。
- アセット管理に`Propshaft`を利用しているが、プリコンパイルされたJavaScriptをより広範なRailsアセットパイプラインに統合するための信頼性の高い方法を必要としている。
- ビルドステップに依存するライブラリやフレームワークを利用している。
  たとえばトランスパイルを必要とするプロジェクト（[Babel](https://babeljs.io/)、[TypeScript](https://www.typescriptlang.org/)、React JSXを利用しているプロジェクトなど）は、`jsbundling-rails`によって大きなメリットを得られます。これらのツールはビルドステップに依存しており、`jsbundling-rails` gemによってシームレスにサポートされます。

`jsbundling-rails` gemを利用すると、JavaScriptワークフローが簡素化されるとともに、`Propshaft`などのRailsツールにも統合されるので、 Railsの規約に準拠しながら高い生産性を維持する、リッチで動的なフロントエンドを構築できます。

### `cssbundling-rails`

[`cssbundling-rails`](https://github.com/rails/cssbundling-rails) gemは、最新のCSSフレームワークとツールをRailsアプリケーションに統合することで、スタイルシートをバンドルして処理できるようになります。処理が完了すると、得られたCSSがRailsのアセットパイプライン経由で配信されます。

#### `cssbundling-rails`のしくみ

1. インストールされると、指定したCSSフレームワークやCSSプロセッサを利用するようにRailsアプリを設定します。
2. `package.json`ファイル内に、スタイルシートをコンパイルするための`build:css`スクリプトを作成します。
3. 開発中は、`build:css --watch`タスクにより、CSSに変更を加えるとCSSがライブ更新され、スムーズで応答性の高いワークフローが実現します。
4. production環境では、`cssbundling-rails` gemによってスタイルシートがコンパイルされ、デプロイを準備します。
  `assets:precompile`ステップでは、すべての`package.json`依存関係が`bun`、`yarn`、`pnpm`、`npm`のいずれかを介してインストールされます。
  次に`build:css`タスクが実行され、スタイルシートのエントリポイントが処理されます。
  得られたCSS出力は、アセットパイプラインによってダイジェスト化され、他のアセットパイプラインファイルと同様に`public/assets/`ディレクトリにコピーされます。

この統合により、すべてのCSSが効率的に管理・処理されると同時に、production環境対応のスタイルを準備するプロセスが簡素化されます。

#### `cssbundling-rails`が適している場合

`cssbundling-rails`は、以下のようなRailsアプリケーションに最適です。

- 開発中やデプロイ中にビルド処理を必要とするCSSフレームワークを利用している。
  （[Tailwind CSS](https://tailwindcss.com/)、[Bootstrap](https://getbootstrap.com/)、[Bulma](https://bulma.io/)などの）
- [PostCSS](https://postcss.org/)や[Dart Sass](https://sass-lang.com/)プラグインによるカスタム前処理などの高度なCSS機能を必要としている。
- 処理されたCSSをRailsのアセットパイプラインにシームレスに統合する必要がある。
- 開発中の手動介入を最小限にとどめてスタイルシートをライブ更新できる。

**注意**: `cssbundling-rails`を利用すると、Node.js依存関係が導入されます（[`dartsass-rails`](https://github.com/rails/dartsass-rails)や[`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails)はNode.jsに依存せず、それぞれ[Dart Sass](https://sass-lang.com/)と[Tailwind CSS](https://tailwindcss.com/)のスタンドアロン版を利用する点が異なります）。そのため、`cssbundling-rails` gemは、JavaScriptの処理をNodeに依存する`jsbundling-rails`などのgemを既に利用しているアプリケーションに適しています。
ただし、JavaScriptに[`importmap-rails`](https://github.com/rails/importmap-rails)を利用していてNode.jsへの依存を避けたい場合は、[`dartsass-rails`](https://github.com/rails/dartsass-rails)や[`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails)などのスタンドアロンの代替手段を利用することでセットアップが簡単になります。

`cssbundling-rails`は、最新のCSSワークフローを統合してproduction環境でのビルドを自動化し、Railsアセットパイプラインを活用することで、開発者が動的なCSSスタイルを効率的に管理および配信できるようにします。

### `tailwindcss-rails`

[`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails)は、[Tailwind CSS](https://tailwindcss.com/)をRailsアプリケーションに統合するラッパーgemです。

`tailwindcss-rails` gemは、Tailwind CSSの[スタンドアロン実行可能ファイル](https://tailwindcss.com/blog/standalone-cli)をバンドルすることで、Node.jsや追加のJavaScript依存関係が不要になります。これにより、Railsアプリケーションをスタイリングする軽量で効率的なソリューションを実現します。

#### `tailwindcss-rails`のしくみ

1. `rails new`コマンドに`--css tailwind`オプションを指定すると、Tailwind設定をカスタマイズするための`tailwind.config.js`ファイルと、CSSエントリポイントを管理するための`stylesheets/application.tailwind.css`ファイルが生成されます。
2. `tailwindcss-rails` gemはNode.jsに依存する代わりに、コンパイル済みのTailwind CSS実行可能バイナリを利用します。
  このスタンドアロンアプローチにより、プロジェクトにJavaScriptランタイムを追加せずにCSSを処理・コンパイルできるようになります。
3. 開発中、Tailwindの設定ファイルやCSSファイルの変更は自動的に検出・処理されます。
  `tailwindcss-rails` gemはスタイルシートを再構築し、開発中にTailwind出力を自動的に生成するための`watch`プロセスを提供します。
4. production環境では、`assets:precompile`タスクにフックすることで、Tailwind CSSファイルを処理し、production環境に最適化されたスタイルシートを生成してアセットパイプラインに含めます。出力はフィンガープリント化され、効率的な配信のためにキャッシュされます。

#### `tailwindcss-rails`が適している場合

`tailwindcss-rails`は、以下のようなRailsアプリケーションに最適です。

- Node.js依存関係やJavaScriptビルドツールを導入せずに[Tailwind CSS](https://tailwindcss.com/)を使いたい。
- ユーティリティファーストのCSSフレームワークを管理する最小限のセットアップが必要。
- Tailwindの強力な機能（カスタムテーマやバリアント、プラグインなど）を複雑な設定なしで利用する必要がある。

`tailwindcss-rails` gemは、PropshaftなどのRailsのアセットパイプラインツールとシームレスに連携し、CSSを前処理・ダイジェスト化して、production環境で効率的に配信されるようにします。

### `importmap-rails`

[`importmap-rails`](https://github.com/rails/importmap-rails)を使うと、RailsアプリケーションのJavaScriptをNode.jsなしで管理できるようになります。
最新ブラウザでの[ESモジュール](https://developer.mozilla.org/ja-JP/docs/Web/JavaScript/Guide/Modules)サポートを活用して、バンドルやトランスパイルを必要とせずにブラウザで直接JavaScriptを読み込みます。このアプローチは、Railsのシンプルさと「設定より規約を重視」という方針にも一致しています。

#### `importmap-rails`のしくみ

- インストールされると、`importmap-rails`はJavaScriptモジュールを`<script type="module">`タグでブラウザに直接読み込むようRailsアプリを設定します。
- JavaScriptの依存関係は`bin/importmap`コマンドで管理されます。
  このコマンドは、バンドル済みブラウザ対応版のライブラリ（[jsDelivr](https://www.jsdelivr.com/)などのCDNでホストされることが多い）をホストするURLにモジュールをピン留め（pinning）します。これにより、Node.jsの`node_modules/`ディレクトリやパッケージマネージャーが不要になります。
- 開発中はバンドルが発生しないため、JavaScriptの更新が即座に利用できるようになり、ワークフローが合理化されます。
- production環境では、`importmap-rails` gemはPropshaftと統合され、アセットパイプラインの一部としてJavaScriptファイルを配信します。
  Propshaftは、ファイルがダイジェスト・キャッシュされて、production環境に対応していることを保証します。
  依存関係はバージョニング・フィンガープリントされ、手動介入なしで効率的に配信されます。

**注意**: Propshaftはアセットが適切に処理されるようにしますが、JavaScriptの処理や変換は行いません。`importmap-rails`は、JavaScriptがすでにブラウザ互換形式であることを前提としています。これが、トランスパイルやバンドルを必要としないプロジェクトに最適な理由です。

`importmap-rails`は、ビルドステップとNode.jsの必要性を排除することで、JavaScript管理を簡素化します。

#### `importmap-rails`が適している場合

`importmap-rails`は、以下のようなRailsアプリケーションに最適です:

- トランスパイルやバンドルなどの複雑なJavaScript機能を必要としない。
- 最新のJavaScriptを[Babel](https://babeljs.io/)などのツールに依存せずに利用する。
