Action Text の概要
====================

本ガイドでは、リッチテキストコンテンツの扱いを始めるのに必要なものをすべて提供します。

このガイドの内容:

* Action Textの概要、インストール方法、設定方法
* リッチテキストコンテンツの作成・レンダリング・スタイル指定・カスタマイズ方法
* 添付ファイルの処理方法

--------------------------------------------------------------------------------


はじめに
------------

Action Textは、リッチテキストコンテンツを手軽に処理・表示する機能です。リッチテキストコンテンツは、太字・斜体・色・ハイパーリンクなどの書式設定要素を含むテキストであり、プレーンテキストよりも豊かに表示可能で、構造化されたプレゼンテーションを提供します。Action Textを利用することで、リッチテキストコンテンツを作成してテーブルに保存することも、任意のモデルに添付することも可能になります。

Trixエディタが生成するリッチテキストコンテンツは独自のRichTextモデルに保存され、このモデルはアプリケーションの既存のあらゆるActive Recordモデルと関連付けられます。
あらゆる埋め込み画像（およびその他の添付ファイル）は自動的にActive Storageに保存され、`include`されたRichTextモデルに関連付けられます。

Action Textには、Trixと呼ばれる[WYSIWYG](https://ja.wikipedia.org/wiki/WYSIWYG)エディタが含まれています。Trixはリッチテキストコンテンツの作成・編集用の使いやすいインターフェイスをユーザーに提供するためにWebアプリケーションで利用され、テキストの書式設定、リンクや引用の追加、画像埋め込みなど多くの機能が使えるようになります。Trixエディタの利用例について詳しくは[TrixエディタのWebサイト](https://trix-editor.org/)を参照してください。

Trixエディタで生成されたリッチテキストコンテンツは、アプリケーションにある既存のActive Recordモデルに関連付け可能な独自のRichTextモデルに保存されます。さらに、埋め込み画像（またはその他の添付ファイル）は、Active Storage（依存関係として追加されます）自動的に保存されてRichTextモデルに関連付けられます。コンテンツをレンダリングするとき、Action Textが最初にコンテンツをサニタイズしてから処理するので、ページのHTMLに直接埋め込んでも安全です。

INFO: WYSIWYGエディタのほとんどは、HTMLの`contenteditable`と`execCommand`APIのラッパーです。これらのAPIは、Internet Explorer 5.5でWebページのライブ編集をサポートするためにMicrosoftによって設計されました。これらは最終的にリバースエンジニアリングされて他のブラウザにコピーされました。その結果、これらのAPIは完全な形では仕様化されておらず、ドキュメント化もされていません。また、WYSIWYG HTMLエディタが扱う範囲が広大であるため、ブラウザの実装ごとに独自のバグや癖が存在します。したがって、この不一致は多くの場合JavaScript開発者によって解決されなければなりませんでした。

Trixは、`contenteditable`をI/Oデバイスとして扱うことで、こうした不一致を回避します。入力がエディタに送信されると、Trixはその入力を編集用に変換して内部ドキュメントモデルに対する操作を実行してから、そのドキュメントをエディタに再レンダリングします。これにより、Trixは振る舞いをキーストローク単位で完全に制御できるようになり、`execCommand`への依存とそれに伴う不一致を回避できます。

## インストール

Action Textをインストールしてリッチテキストコンテンツを扱えるようにするには、以下を実行します。

```bash
$ bin/rails action_text:install
```

上を実行すると、以下が行われます。

- `trix`と`@rails/actiontext`で利用するJavaScriptパッケージをインストールして、`application.js`ファイルに追加します。
- `image_processing` gem（Active Storageで埋め込み画像などの添付ファイルの分析・変換を行う）を追加します。詳しくは[Active Storageの概要](active_storage_overview.html)ガイドを参照してください。
- リッチテキストコンテンツや添付ファイルを保存するために以下のテーブルを作成するマイグレーションファイルを追加します。
  - `action_text_rich_texts`
  - `active_storage_blobs`
  - `active_storage_attachments`
  - `active_storage_variant_records`
- `actiontext.css`を作成します。ここにはTrixスタイルシートも含まれます。
- Action Textコンテンツをレンダリングするためのビューパーシャル`_content.html`と、Active Storageの添付ファイル（blob）をレンダリングするための`_blob.html`を追加します。

続いて以下のようにマイグレーションを実行すると、アプリケーションに`action_text_*`テーブルと`active_storage_*`テーブルが追加されます。

```bash
$ bin/rails db:migrate
```

Action Textのインストールで`action_text_rich_texts`テーブルを作成する場合、ポリモーフィックリレーションシップが使われるため、複数のモデルでリッチテキスト属性を追加可能になります。これは、モデルのClassNameを保存する`record_type`カラムとレコードのIDを保存する`record_id`カラムを通じて行われます。

INFO: ポリモーフィック関連付けを利用すると、1個の関連付けでモデルを複数の他のモデルに従属させることが可能になります。詳しくは[Active Recordの関連付けガイド](association_basics.html#ポリモーフィック関連付け)を参照してください。

したがって、Action Textのコンテンツを含むモデルが識別子としてUUID値を利用する場合は、Action Textの属性を使うすべてのモデルでもUUID値を一意の識別子として使わなければなりません。Action Text用に生成したマイグレーションでも、以下のようにレコードの`references`行に`type: :uuid`を指定する形で更新する必要があります。

```ruby
t.references :record, null: false, polymorphic: true, index: false, type: :uuid
```

## リッチテキストコンテンツを作成する

本セクションでは、リッチテキストを作成するときに従う必要があるいくつかの設定について解説します。

RichTextレコードは、Trixエディタによって生成されたコンテンツをシリアライズ`body`属性に保持します。ここには、Active Storageによって保存される埋め込みファイルへのすべての参照も保持されます。このレコードは、リッチテキストコンテンツを必要とするActive Recordモデルに関連付けられます。この関連付けを行うには、リッチテキストを追加するモデルで以下のように`has_rich_text`クラスメソッドを配置します。

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  has_rich_text :content
end
```

NOTE: Articleモデルのテーブルに`content`フィールドを追加する必要はありません（`has_rich_text`クラスメソッドによって、作成済みの`action_text_rich_texts`テーブルに関連付けられ、モデルにリンクされます）。また、属性名を`content`以外に変更することも可能です。

`has_rich_text`クラスメソッドをモデルに追加したら、そのフィールドでリッチテキストエディタ（Trix）を利用できるようにビューを更新します。これを行うには、ビューのフォームフィールドで以下のように[`rich_textarea`][]メソッドを使います。

```html+erb
<%# app/views/articles/_form.html.erb %>
<%= form_with model: article do |form| %>
  <div class="field">
    <%= form.label :content %>
    <%= form.rich_textarea :content %>
  </div>
<% end %>
```

これによりTrixエディタが表示され、リッチテキストを作成・更新する機能が提供されます。詳しくは[エディタのスタイルを更新する方法](action_text_overview.html#trixのスタイルを追加・削除する)で後述します。

最後に、エディタからの更新を受け付け可能にするため、参照する属性を以下のように`permit`でパラメータとして関連コントローラ内で許可する必要があります。

```ruby
class ArticlesController < ApplicationController
  def create
    article = Article.create! params.expect(article: [:title, :content])
    redirect_to article
  end
end
```

`has_rich_text`を利用するクラスの名前を変更する必要が生じた場合は、`action_text_rich_texts`テーブル内の対応するすべての行でポリモーフィック型`record_type`カラムも更新しなければなりません。

Action Textが依存しているポリモーフィック関連付けでは、クラス名をデータベースに保存する必要があるため、Rubyコードで使われるクラス名とデータがずれないよう常に同期を保つことが重要です。この同期は、保存したデータとコードベース内のクラス参照との一貫性を維持するうえで不可欠です。

[`rich_textarea`]:
  https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-rich_textarea

## リッチテキストコンテンツをレンダリングする

`ActionText::RichText`のインスタンスは、安全なレンダリングのためにコンテンツがサニタイズ済みなので、ビューのページに直接埋め込み可能です。コンテンツは以下のように表示できます。

```erb
<%= @article.content %>
```

`ActionText::RichText#to_s`メソッドはRichTextをHTML安全な文字列に変換しますが、`ActionText::RichText#to_plain_text`はHTML安全ではない文字列を返すため、ブラウザでレンダリングすべきではありません。Action Textのサニタイズプロセスについて詳しくは、APIドキュメントの[`ActionText::RichText`](https://api.rubyonrails.org/classes/ActionText/RichText.html)クラスを参照してください。

NOTE: `content`フィールドに添付（attached）リソースが存在する場合は、リソースの種別に応じて[Active Storageで必要な依存関係](active_storage_overview.html#要件)をインストールしておかないと正しく表示されない可能性があります。

## リッチテキストコンテンツエディタ（Trix）をカスタマイズする

スタイル上の要件を満たすためにエディタの表示を更新したい場合があります。本セクションでは、その方法について解説します。

### Trixのスタイルを追加・削除する

デフォルトでは、Action TextはCSSの`.trix-content`クラスを宣言した要素内でリッチテキストコンテンツをレンダリングします。これは`app/views/layouts/action_text/contents/_content.html.erb`で設定されます。このクラスの要素のスタイルは、Trixのスタイルシートによって設定されます。

Trixのスタイルのいずれかを更新したい場合は、`app/assets/stylesheets/actiontext.css`にカスタムスタイルを追加できます。ここには、Trix用のスタイルシートの完全なセットと、Action Textで必要なオーバーライドの両方が含まれています。

### エディタコンテナをカスタマイズする

リッチテキストコンテンツの周囲にレンダリングされるHTMLコンテナ要素をカスタマイズするには、インストーラが作成した以下の`app/views/layouts/action_text/contents/_content.html.erb`レイアウトファイルを編集します。

```html+erb
<%# app/views/layouts/action_text/contents/_content.html.erb %>
<div class="trix-content">
  <%= yield %>
</div>
```

### 埋め込み画像や添付ファイルのHTMLをカスタマイズする

埋め込み画像やその他の添付ファイル（いわゆる[blob](https://ja.wikipedia.org/wiki/%E3%83%90%E3%82%A4%E3%83%8A%E3%83%AA%E3%83%BB%E3%83%A9%E3%83%BC%E3%82%B8%E3%83%BB%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88)）に対してレンダリングされるHTMLをカスタマイズするには、インストーラが作成する`app/views/active_storage/blobs/_blob.html.erb`テンプレートを以下のように編集します。

```html+erb
<%# app/views/active_storage/blobs/_blob.html.erb %>
<figure class="attachment attachment--<%= blob.representable? ? "preview" : "file" %> attachment--<%= blob.filename.extension %>">
  <% if blob.representable? %>
    <%= image_tag blob.representation(resize_to_limit: local_assigns[:in_gallery] ? [ 800, 600 ] : [ 1024, 768 ]) %>
  <% end %>

  <figcaption class="attachment__caption">
    <% if caption = blob.try(:caption) %>
      <%= caption %>
    <% else %>
      <span class="attachment__name"><%= blob.filename %></span>
      <span class="attachment__size"><%= number_to_human_size blob.byte_size %></span>
    <% end %>
  </figcaption>
</figure>
```

## 添付ファイル

現在のAction Textでは、Active Storage経由でアップロードされた添付ファイル（attachment）と、署名付きGlobalIDにリンクされた添付ファイルをサポートしています。

### Active Storage

リッチテキストエディタ内で画像をアップロードするとAction Textが使われ、そしてActive Storageが使われます。ただし[Active Storageで使われる依存関係](active_storage_overview.html#要件)の中には、デフォルトのRailsでは提供されていないものもあります。組み込みのプレビューアを利用するには、これらのライブラリを別途インストールしておく必要があります。

中には必須ではないライブラリもありますが、どのライブラリをインストールすべきかについては、エディタでのアップロードをサポートしたいファイルの種別によって異なります。ユーザーがAction TextやActive Storageを使うときによく遭遇するエラーは、エディタで画像が正しくレンダリングされないことです。このエラーは多くの場合、`libvips`依存関係がインストールされていないことが原因です。

#### 添付ファイルのダイレクトアップロード用JavaScriptイベント

| イベント名 | イベントのターゲット | イベントのデータ（`event.detail`）| 説明 |
| --- | --- | --- | --- |
| `direct-upload:start` | `<input>` | `{id, file}` | ダイレクトアップロードが開始中。|
| `direct-upload:progress` | `<input>` | `{id, file, progress}` | ファイルの保存リクエストが進行中。|
| `direct-upload:error` | `<input>` | `{id, file, error}` | エラーが発生。このイベントがキャンセルされない限り`alert`が表示される。|
| `direct-upload:end` | `<input>` | `{id, file}` | ダイレクトアップロードが完了。|

### 署名済みGlobalID

Action Textでは、Active Storage経由でアップロードした添付ファイルを埋め込むことも、[署名済みグローバルID](https://github.com/rails/globalid#signed-global-ids)で解決可能な任意のデータを埋め込むことも可能です。

グローバルIDは`gid://YourApp/Some::Model/id`のような形式を取る、モデルのインスタンスを一意に識別するアプリ全体のURIです。グローバルIDは、オブジェクトのさまざまなクラスを一意に参照する識別子が必要な場合に有用です。

この方法を使う場合、Action Textの添付ファイルで署名済みグローバルID（sgid）が必要になります。Railsアプリ内のすべてのActive Recordモデルは、デフォルトで`GlobalID::Identification`のconcernにミックスインされていて署名済みグローバルIDで解決可能になっているので、`ActionText::Attachable`と互換性があります。

Action Textは、挿入したHTMLを保存時に参照するため、後で最新のコンテンツで再レンダリングできます。これにより、参照しているモデルのレコードが変更されたときに常に最新のコンテンツを表示できるようになります。

Action Textは、モデルをグローバルIDから読み込むことで、コンテンツをレンダリングするときにデフォルトのパーシャルパスを用いてモデルをレンダリングします。

Action Textの添付ファイルは次のようになります。

```html
<action-text-attachment sgid="BAh7CEkiCG…"></action-text-attachment>
```

Action Textは、要素のsgid属性をインスタンスに解決することで、埋め込まれた`<action-text-attachment>`要素をレンダリングします。解決が成功すると、そのインスタンスはレンダリングヘルパーに渡され、最終的なHTMLが`<action-text-attachment>`要素の子孫要素として埋め込まれます。

Action Textの`<action-text-attachment>`要素内で添付ファイルとしてレンダリングするには、`#to_sgid(**options)`メソッド（これは`GlobalID::Identification` concernを介して利用可能になります）を実装する`ActionText::Attachable`モジュールを`include`する必要があります。

オプションとして、カスタムのパーシャルパスをレンダリングする`#to_attachable_partial_path`メソッドや、欠落したレコードを処理する`#to_missing_attachable_partial_path`メソッドも宣言できます。

以下はグローバルIDの利用例です。

```ruby
class Person < ApplicationRecord
  include ActionText::Attachable
end

person = Person.create! name: "Javan"
html = %Q(<action-text-attachment sgid="#{person.attachable_sgid}"></action-text-attachment>)
content = ActionText::Content.new(html)
content.attachables # => [person]
```

### Action Textの添付ファイルをレンダリングする

デフォルトでは、`<action-text-attachment>`はデフォルトのパーシャルパスを介してレンダリングされます。

以下の`User`モデルを例に詳しく考えてみましょう。

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
end

user = User.find(1)
user.to_global_id.to_s #=> gid://MyRailsApp/User/1
user.to_signed_global_id.to_s #=> BAh7CEkiCG…
```

NOTE: `.find(id)`クラスメソッドを利用すれば、`GlobalID::Identification`を任意のモデルにミックスインできます。このサポートはActive Recordに自動的に`include`されます。

上記のコードは、モデルのインスタンスを一意に識別するための識別子を返します。

次に、Userモデルのインスタンスにある署名済みグローバルIDを参照する`<action-text-attachment>`要素が埋め込まれたリッチテキストを考えてみましょう。

```html
<p>Hello, <action-text-attachment sgid="BAh7CEkiCG…"></action-text-attachment>.</p>
```

Action Textは、この"BAh7CEkiCG…"というStringを用いて`User`インスタンスを解決し、次にデフォルトのパーシャルパスを用いてコンテンツをレンダリングします。

この場合、デフォルトのパーシャルパスは`users/user`パーシャルになります。

```html+erb
<%# app/views/users/_user.html.erb %>
<span><%= image_tag user.avatar %> <%= user.name %></span>
```

これによって、Action Textで以下のHTMLがレンダリングされます。

```html
<p>Hello, <action-text-attachment sgid="BAh7CEkiCG…"><span><img src="..."> Jane Doe</span></action-text-attachment>.</p>
```

### action-text-attachmentで別のパーシャルをレンダリングする

別のパーシャルをレンダリングするには、以下のように`User#to_attachable_partial_path`を定義します。

```ruby
class User < ApplicationRecord
  def to_attachable_partial_path
    "users/attachable"
  end
end
```

次にそのパーシャルを宣言します。Userインスタンスは、パーシャル内の`user`ローカル変数でアクセスできます。

```html+erb
<%# app/views/users/_attachable.html.erb %>
<span><%= image_tag user.avatar %> <%= user.name %></span>
```

### 解決できなかったインスタンスやaction-text-attachmentが見つからないパーシャルをレンダリングする

Action TextがUserモデルのインスタンスを解決できない場合（レコードが削除されているなど）、デフォルトのフォールバック用パーシャルがレンダリングされます。

添付ファイルが見つからない場合にレンダリングするパーシャルを変更するには、以下のようにクラスレベルの`to_missing_attachable_partial_path`メソッドを定義します。

```ruby
class User < ApplicationRecord
  def self.to_missing_attachable_partial_path
    "users/missing_attachable"
  end
end
```

次にそのパーシャルを宣言します。

```html+erb
<%# app/views/users/missing_attachable.html.erb %>
<span>Deleted user</span>
```

### ファイルアップロードAPIを独自に提供する

アプリケーションのアーキテクチャが伝統的なサーバーサイドレンダリングパターンに沿っていない場合は、バックエンドAPI（JSONを使うなど）で利用するファイルアップロード用のエンドポイントを自分で用意しなければならない場合があります。このエンドポイントは`ActiveStorage::Blob`を作成し、以下のようにその`attachable_sgid`を返す必要があります。

```json
{
  "attachable_sgid": "BAh7CEkiCG…"
}
```

これで、`attachable_sgid`を取得してから`<action-text-attachment>`タグを用いてフロントエンドコード内のリッチテキストコンテンツに以下のように挿入できるようになります。

```html
<action-text-attachment sgid="BAh7CEkiCG…"></action-text-attachment>
```

## その他

### N+1クエリを回避する

依存する`ActionText::RichText`をプリロードしたい場合は、以下のように名前付きスコープを利用できます（リッチテキストフィールド名が`content`という前提）。

```ruby
Message.all.with_rich_text_content            # 添付ファイルなしで本文をプリロードする
Message.all.with_rich_text_content_and_embeds # 本文と添付ファイルを両方プリロードする
```
