Rails で JavaScript を利用する
================================

本ガイドでは、JavaScript機能をRailsアプリケーションに統合する方法について解説します。外部のJavaScriptパッケージを利用する場合に使えるオプションや、RailsでTurboを使う方法についても解説します。

このガイドの内容:

* Node.jsやYarnやJavaScriptのバンドラーを使わずにRailsを利用する方法
* JavaScriptをimport maps・Bun・esbuild・Rollup・webpackでバンドルする新規Railsアプリケーションを作成する方法
* Turboの概要と利用法
* Railsが提供するTurbo HTMLヘルパーの利用法

--------------------------------------------------------------------------------

import maps
-----------

[import maps](https://github.com/rails/importmap-rails)は、バージョン付けされたファイルに対応する論理名を用いてJavaScriptモジュールをブラウザで直接importできます。import mapsはRails 7からデフォルトになっており、トランスパイルやバンドルの必要なしにほとんどのnpmパッケージを用いて誰でもモダンなJavaScriptアプリケーションを構築できるようになります。

import mapsを利用するアプリケーションは、[Node.js](https://nodejs.org/en/)や[Yarn](https://yarnpkg.com/)なしで機能します。RailsのJavaScript依存関係を`importmap-rails`で管理する予定であれば、Node.jsやYarnをインストールする必要はありません。

import mapsを利用する場合、別途ビルドプロセスを実行する必要はなく、`bin/rails server`コマンドでサーバーを起動するだけでOKです。

### importmap-railsをインストールする

Importmap for Railsは、Rails 7以降の新規アプリケーションに自動的に含まれていますが、既存のアプリケーションに手動でインストールすることも可能です。

```bash
$ bin/bundle add importmap-rails
```

以下のインストールタスクを実行します。

```bash
$ bin/rails importmap:install
```

### npmパッケージをimportmap-railsで追加する

import mapを利用するアプリケーションに新しいパッケージを追加するには、ターミナルで以下のように`bin/importmap pin`コマンドを実行します。

```bash
$ bin/importmap pin react react-dom
```

続いて、従来と同様に`application.js`ファイルでパッケージを`import`します。


```javascript
import React from "react"
import ReactDOM from "react-dom"
```

npmパッケージをJavaScriptバンドラーで追加する
--------

import mapsは新規Railsアプリケーションのデフォルトですが、従来のJavaScriptバンドラーを使いたい場合は、新規Railsアプリケーション作成時にいずれかを選択できます。

* [Bun](https://bun.sh)
* [esbuild](https://esbuild.github.io/)
* [webpack](https://webpack.js.org/)
* [Rollup.js](https://rollupjs.org/guide/en/)

import mapsではなくJavaScriptバンドラーを新規Railsアプリケーションで利用するには、以下のように`rails new`コマンドに`—-javascript`または`-j`オプションを渡します。

```bash
$ rails new my_new_app --javascript=bun
# または
$ rails new my_new_app -j bun
```

どのバンドルオプションにも、シンプルな設定と、[jsbundling-rails](https://github.com/rails/jsbundling-rails) gemによるアセットパイプラインとの統合が用意されています。

バンドルオプションを利用する場合は、development環境でのRailsサーバー起動とJavaScriptのビルドに`bin/dev`コマンドをお使いください。

### JavaScriptランタイムをインストールする

Railsアプリケーションでesbuild、Rollup.js、webpackのいずれかをJavaScriptランタイムとして使う場合は、Node.jsとYarnをインストールしなければなりません。

Bunを使う場合は、BunをJavaScriptのランタイムとバンドラーの兼用としてインストールするだけで済みます。

#### Bunをインストールする

[Bunウェブサイト](https://bun.sh)でインストール手順を見つけ、インストール後にプロジェクトのパスで以下のコマンドを実行して、正しいパスにインストールされているかを確認してください。

```bash
$ bun --version
```

インストールされているBunランタイムのバージョンが表示されるはずです。`1.0.0`のようにバージョンが表示されれば、Bunは正しくインストールされています。

バージョンが表示されない場合は、Bunを現在のディレクトリで再インストールするか、ターミナルを再起動する必要があるかもしれません。

#### Node.jsとYarnをインストールする

Railsアプリケーションでesbuild、rollup.js、webpackのいずれかを使う場合は、Node.jsとYarnをインストールしなければなりません。

Node.jsのインストール方法については[Node.js Webサイト](https://nodejs.org/ja/download/)を参照してください。また、以下のコマンドで正しくインストールされたかどうかを確認してください。

```bash
$ node --version
```

Node.jsランタイムのバージョンが出力されるはずです。必ず`8.16.0`より大きいバージョンをお使いください。

Yarnのインストール方法については[Yarn Webサイト](https://classic.yarnpkg.com/en/docs/install)の手順に沿ってください。インストール後、以下のコマンドを実行するとYarnのバージョンが出力されるはずです。

```bash
$ yarn --version
```

`1.22.0`のように表示されれば、Yarnは正しくインストールされています。

import mapsとJavaScriptバンドラーのどちらを選ぶか
-----------------------------------------------------

Railsアプリケーションを新規作成する場合、import mapsとJavaScriptバンドラーのどちらかのソリューションを選ぶ必要があります。アプリケーションごとに要件は異なるので、JavaScriptのオプションを決める際には十分注意してください。特に大規模で複雑なアプリケーションほど、後から別のオプションに乗り換えようとすると時間がかかる可能性があります。

Railsチームは、import mapsが複雑さを削減して開発者のエクスペリエンスやパフォーマンスを向上させる能力を持っていると信じているので、import mapsがデフォルトのオプションとして選ばれています。

多くのアプリケーション、特にJavaScriptのニーズを[Hotwire](https://hotwired.dev/)スタックに依存しているアプリケーションにおいては、import mapが長期的に正しい選択肢となるでしょう。Rails 7でimport mapsがデフォルトのオプションになった背景については[こちら](https://world.hey.com/dhh/rails-7-will-have-three-great-answers-to-javascript-in-2021-8d68191b)の記事を参照してください。

それ以外のアプリケーションでは、引き続き従来のJavaScriptバンドラーが必要になることもあるでしょう。従来のJavaScriptバンドラーを選択すべきであることを示唆する要件は以下のとおりです。

* コードでトランスパイルが必須である場合（JSXやTypeScriptなどを使う場合）
* CSSをインクルードするJavaScriptライブラリや、[webpack loaders](https://webpack.js.org/loaders/)に依存する必要がある場合
* [tree-shaking](https://webpack.js.org/guides/tree-shaking/)がどうしても必要な場合
* [cssbundling-rails gem](https://github.com/rails/cssbundling-rails)経由でBootstrap、Bulma、PostCSS、Dart CSSをインストールする場合。なお、`rails new`で特に別のオプションを指定しなかった場合は、cssbundling-rails gemが自動的に`esbuild`をインストールします（TailwindやSassを選んだ場合はインストールされません）。

Turbo
-----

[Turbo](https://turbo.hotwired.dev/)は、import mapsを選ぶか従来のJavaScriptバンドラーを選ぶかどうかにかかわらず、Railsアプリケーションに同梱されます。Turboは、書かなければならないJavaScriptコード量を劇的に減らしつつ、アプリケーションを高速化します。

Turboは、Railsアプリケーションのサーバーサイドの役割をJSON API専用同然に縮小するさまざまなフロントエンドフレームワークとは異なる手法を用いるもので、サーバーから直接HTMLを配信できるようにします。

### Turbo Drive

[Turbo Drive](https://turbo.hotwired.dev/handbook/drive)は、ページ遷移リクエストのたびにページ全体を取り壊して再構築する動作を回避する形でページの読み込みを高速化します。

### Turbo Frames

[Turbo Frames](https://turbo.hotwired.dev/handbook/frames)は、ページの他の部分に影響を及ぼさずに、ページで事前定義された部分をリクエストに応じて更新できるようにします。

Turbo Framesを使うと、カスタムJavaScriptをまったく書かずにインプレース編集機能を構築したり、コンテンツを遅延読み込みしたり、サーバーレンダリングされたタブインターフェイスを作成したりする作業が手軽に行なえます。

Railsでは、[turbo-rails](https://github.com/hotwired/turbo-rails) gemを介してTurbo Framesを手軽に利用できるHTMLヘルパーを提供します。

このgemを使うと、アプリケーションで以下のように`turbo_frame_tag`ヘルパーを用いてTurbo Framesを追加できるようになります。

```erb
<%= turbo_frame_tag dom_id(post) do %>
  <div>
     <%= link_to post.title, post_path(post) %>
  </div>
<% end %>
```

### Turbo Streams

[Turbo Streams](https://turbo.hotwired.dev/handbook/streams)は、ページの変更を自己実行型の`<turbo-stream>`要素でラップされたHTMLフラグメントとして配信します。Turbo Streamsを用いることで、他のユーザーによる変更内容をWebSocket上でブロードキャストしたり、フォーム送信後にページ全体を更新する必要なしにページの一部のみを更新したりできるようになります。

Railsでは、[turbo-rails](https://github.com/hotwired/turbo-rails) gemを介してTurbo Streamsを手軽に利用できるHTMLヘルパーを提供します。

このgemを使うと、以下のようにコントローラのアクションでTurbo Streamsをレンダリングできます。

```ruby
def create
  @post = Post.new(post_params)

  respond_to do |format|
    if @post.save
      format.turbo_stream
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

Railsは自動的に`.turbo_stream.erb`ビューファイルを探索し、見つかったらそのビューをレンダリングします。

Turbo Streamsのレスポンスも、以下のようにコントローラのアクションでインラインレンダリングできます。

```ruby
def create
  @post = Post.new(post_params)

  respond_to do |format|
    if @post.save
      format.turbo_stream { render turbo_stream: turbo_stream.prepend("posts", partial: "post") }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

最後に、Turbo Streamsは組み込みヘルパーを用いてモデルやバックグラウンドジョブから開始できます。これらのブロードキャストは、WebSocketコネクション経由で全ユーザーのコンテンツを更新するのにも利用可能で、ページの内容を常に最新に保って生き生きとしたアプリケーションにすることができます。

モデルでTurbo Streamsをブロードキャストするには、以下のようにモデルのコールバックと組み合わせます。

```ruby
class Post < ApplicationRecord
  after_create_commit { broadcast_append_to("posts") }
end
```

WebSocketによって、更新を受け取る以下のようなページとのコネクションが設定されます。

```erb
<%= turbo_stream_from "posts" %>
```

Rails/UJSの機能を置き換える
----------------------------------------

Rails 6にはUJS（Unobtrusive JavaScript）というツールが同梱されていました。UJSは、開発者が`<a>`タグをオーバーライドすることでハイパーリンクのクリック後に非GETリクエストを実行し、アクション実行前に確認ダイアログを追加できるようにします。Rails 7より前はこの方法がデフォルトでしたが、現在はTurboの利用が推奨されています。

### HTTPメソッド

リンクをクリックすると、常にHTTP GETリクエストが発生します。[RESTful](https://ja.wikipedia.org/wiki/Representational_State_Transfer)なアプリケーションでは、実際には一部のリンクがサーバーのデータを変更するアクションを起動しますが、これは非GETリクエストで実行されるべきです。`data-turbo-method`属性を利用することで、そうしたリンクをPOSTやPUTやDELETEなどのHTTPメソッドで明示的にマークアップできるようになります。

Turboは、アプリケーション内の`<a>`タグをスキャンして`turbo-method`データ属性があるかどうかを調べ、HTTPメソッドが指定されている場合はそのHTTPメソッドを使う形で、デフォルトのGETアクションをオーバーライドします。

例:

```erb
<%= link_to "投稿を削除", post_path(post), data: { turbo_method: "delete" } %>
```

上のERBは以下のHTMLを生成します。

```html
<a data-turbo-method="delete" href="...">投稿を削除</a>
```

HTTPメソッドの変更は、`data-turbo-method`属性をリンクに追加する方法の他に、Railsの`button_to`ヘルパーでもできます。なお実際には、アクセシビリティの観点から、非GETアクションには（リンクではなく）ボタンとフォームを用いるのが望ましい方法です。

### 確認ダイアログ

リンクやフォームに`data-turbo-confirm`属性を追加することで、ユーザーに確認ダイアログを表示して確認を求めることができます。リンクのクリックやフォームの送信では、JavaScriptの`confirm()`ダイアログに属性のテキストを含んだものが表示されます。ユーザーがキャンセルを選択するとアクションは行われません。
たとえば`link_to`ヘルパーを用いると、

```erb
<%= link_to "投稿を削除", post_path(post),
            data: {
              turbo_method: "delete",
              turbo_confirm: "削除してよろしいですか？"
            } %>
```

以下が生成されます。

```html
<a href="..." data-turbo-confirm="削除してよろしいですか？" data-turbo-method="delete">
  投稿を削除
</a>
```

ユーザーがこの"投稿を削除"リンクをクリックすると、"削除してよろしいですか？"という確認ダイアログが表示されます。

この属性は`button_to`ヘルパーでも利用できますが、`button_to`ヘルパーが内部でレンダリングするフォームに属性を追加する必要があります。

```erb
<%= button_to "Delete post", post,
              method: :delete,
              form: {
                data: {
                  turbo_confirm: "削除してよろしいですか？"
                }
              } %>
```
### Ajaxリクエスト

JavaScriptからGET以外のリクエストを行う場合、`X-CSRF-Token`ヘッダーが必要です。このヘッダーがないと、Railsはリクエストを受け付けません。

NOTE: このトークンは、クロスサイトリクエストフォージェリ（CSRF）攻撃を防ぐためにRailsで必須になっています。詳しくは[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ（csrf）)をお読みください。

Railsリポジトリにある[Request.JS](https://github.com/rails/request.js)は、Railsで必須のリクエストヘッダーを追加するロジックをカプセル化したものです。このパッケージから`FetchRequest`クラスをインポートして、リクエストメソッド、URL、オプションを渡してインスタンス化し、`await request.perform()`を呼び出せば、レスポンスに必要な処理を行えます。

以下の例を見てみましょう。

```javascript
import { FetchRequest } from '@rails/request.js'

....

async myMethod () {
  const request = new FetchRequest('post', 'localhost:3000/posts', {
    body: JSON.stringify({ name: 'Request.JS' })
  })
  const response = await request.perform()
  if (response.ok) {
    const body = await response.text
  }
}
```

その他のライブラリを利用してAjax呼び出しを行う場合、自分でセキュリティトークンをデフォルトヘッダーとして追加する必要があります。このトークンを取得するには、[`csrf_meta_tags`][]から出力される`<meta name='csrf-token' content='（トークン）'>`を参照します。トークンの取得は以下のような感じで行なえます。

```javascript
document.head.querySelector("meta[name=csrf-token]")?.content
```

[`csrf_meta_tags`]: https://api.rubyonrails.org/classes/ActionView/Helpers/CsrfHelper.html#method-i-csrf_meta_tags
