Action Text の概要
====================

本ガイドでは、リッチテキストコンテンツの扱いを始めるのに必要なものをすべて提供します。

このガイドの内容:

* Action Textの設定方法
* リッチテキストコンテンツの扱い方
* リッチテキストコンテンツにスタイルを付ける方法

--------------------------------------------------------------------------------

はじめに
------------

Action Textを使って、Railsにリッチテキストコンテンツと編集機能を導入できます。Action Textに含まれている[Trixエディタ](https://trix-editor.org)は、書式設定/リンク/引用/リスト/画像埋め込み/ギャラリーなどあらゆるものを扱えます。
Trixエディタが生成するリッチテキストコンテンツは独自のRichTextモデルに保存され、このモデルはアプリケーションの既存のあらゆるActive Recordモデルと関連付けられます。
あらゆる埋め込み画像（およびその他の添付ファイル）は自動的にActive Storageに保存され、includeされたRichTextモデルに関連付けられます。

## Trixと他のリッチテキストエディタを比較する

ほとんどのWYSIWYGエディタは、HTMLの`contenteditable`や`execCommand` APIのラッパーです。これはマイクロソフトがInternet Explorer 5.5のライブエディット機能をサポートするために設計したもので、最終的に[リバースエンジニアリング](https://blog.whatwg.org/the-road-to-html-5-contenteditable#history)されて他のブラウザに普及しました。

これらのAPIの仕様やドキュメントは永遠に未完成のままであり、かつWYSIWYG HTMLエディタが扱う範囲が広大なため、ブラウザの実装ごとに独自のバグやおかしな動作が発生しています。ブラウザ間の動作のぶれの解決はJavaScript開発者たちに任せきりの状態です。

Trixでは`contenteditable`をI/Oデバイスとして扱うことで、こうしたブラウザ間の動作のぶれを回避しました。エディタに独自の方法で入力されると、Trixはその入力を内部のドキュメントモデル上での編集操作に変換してから、ドキュメントをエディタ上で再レンダリングします。これにより、Trixはあらゆるキーストロークで発生するものを完全に制御し、`execCommand`を使う必要性をすべて回避しています。

## インストール

`rails action_text:install`を実行すると、Yarnパッケージが追加され、必要なマイグレーションがコピーされます。また、埋め込み画像や他の添付ファイルを扱うためにActive Storageのセットアップも必要です。詳しくは[Active Storageの概要](active_storage_overview.html)ガイドを参照してください。

## 例

既存のモデルにリッチテキストのフィールドを追加するには次のようにします。

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  has_rich_text :content
end
```

続いて、モデルのこのフィールドをフォーム内で参照します。

```erb
<%# app/views/messages/_form.html.erb %>
<%= form_with(model: message) do |form| %>
  <div class="field">
    <%= form.label :content %>
    <%= form.rich_text_area :content %>
  </div>
<% end %>
```

最後に、sanitize済みのリッチテキストをページ上に表示します。

```erb
<%= @message.content %>
```

リッチテキストコンテンツを受け取れるようにするには、参照される属性を許可するだけで済みます。

```ruby
class MessagesController < ApplicationController
  def create
    message = Message.create! params.require(:message).permit(:title, :content)
    redirect_to message
  end
end
```

## スタイルのカスタマイズ

Action Textエディタとコンテンツのスタイルには、デフォルトではTeixのデフォルトが使われます。これらのデフォルトを変更したい場合は、`app/assets/stylesheets/actiontext.css`リンカーを削除して、[trix.css](https://raw.githubusercontent.com/basecamp/trix/master/dist/trix.css)を元にスタイルを付けます。

埋め込み画像やその他の添付ファイル（いわゆるblob）で使われるHTMLにスタイルを付けることもできます。Action Textをインストールすると、パーシャルが`app/views/active_storage/blobs/_blob.html.erb`にコピーされるので、これをカスタマイズできます。
