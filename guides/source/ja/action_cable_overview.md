Action Cable の概要
=====================

本ガイドでは、Action Cableのしくみと、WebSocketをRailsアプリケーションに導入してリアルタイム機能を実現する方法について解説します。

このガイドの内容:

* Action Cableの概要、バックエンドとフロントエンドの統合
* Action Cableの設定方法
* チャネルの設定方法
* Action Cable向けのデプロイとアーキテクチャの設定

--------------------------------------------------------------------------------

はじめに
------------

Action Cableは、[WebSocket](https://ja.wikipedia.org/wiki/WebSocket)とRailsのその他の部分をシームレスに統合します。Action Cableを導入すると、Railsアプリケーションのパフォーマンスとスケーラビリティを損なわずに、通常のRailsアプリケーションと同じスタイル・方法でリアルタイム機能をRubyで記述できるようになります。Action Cableはフルスタックのフレームワークであり、クライアント側のJavaScriptフレームワークとサーバー側のRubyフレームワークの両方を提供します。Active RecordなどのORMで書かれたドメインモデル全体にアクセスできます。

用語について
-----------

Action Cableは、通常のHTTPリクエスト・レスポンスプロトコルの代わりにWebSocketを利用します。Action CableとWebSocketでは、以下のような新しい用語がいくつか導入されます。

### コネクション

**コネクション**（connection）は、クライアント・サーバーの関係の基礎をなすものです。
1個のAction Cableサーバーは、コネクションインスタンスを複数扱うことが可能で、WebSocketのコネクションごとに1つのコネクションインスタンスを持ちます。あるユーザーがブラウザタブを複数開いたり複数のデバイスを用いている場合は、アプリケーションに対して複数のWebSocketコネクションをオープンします。

### コンシューマー

WebSocketコネクションのクライアントは、**コンシューマー**（consumer）と呼ばれます。
Action Cableのコンシューマーは、クライアント側のJavaScriptフレームワークによって作成されます。

### チャネル

コンシューマごとに、複数の**チャネル**（channel）をサブスクライブできます。
各チャネルは論理的な機能単位をカプセル化しており、チャネル内ではコントローラが典型的なMVCセットアップで行っていることと同様のことを行います。たとえば`ChatChannel`と`AppearancesChannel`が1つずつあると、あるコンシューマーはそれらチャネルの一方または両方でサブスクライブされることが可能です。1つのコンシューマーは、少なくとも1つのチャネルにサブスクライブされるべきです。

### サブスクライバ

コンシューマーがチャネルでサブスクライブされると、**サブスクライバ**（subscriber）として振る舞います。サブスクライバとチャネルの間のコネクションは、（驚くことに）サブスクリプションと呼ばれます。あるコンシューマーは、何度でも指定のチャネルのサブスクライバとして振る舞えます。たとえば、あるコンシューマーが複数のチャットルームに同時にサブスクライブことも可能です（物理的なユーザーが複数のコンシューマーを持つことが可能で、コネクションはブラウザタブやデバイスごとにオープン可能であることを思い出しましょう）。

### Pub/Sub

[Pub/Sub](https://ja.wikipedia.org/wiki/%E5%87%BA%E7%89%88-%E8%B3%BC%E8%AA%AD%E5%9E%8B%E3%83%A2%E3%83%87%E3%83%AB)（Publish-Subscribe）はメッセージキューのパラダイムの一種であり、情報の送信者（パブリッシャ）は個別の受信者を指定する代わりに、受信側の抽象クラスにデータを送信します。Action Cableでは、このPub/Subアプローチを用いてサーバーと多数のクライアントの間の通信を行います。

### ブロードキャスト

ブロードキャスト（broadcasting）とは、あるブロードキャスター（broadcaster）によって転送されるあらゆる情報をチャネルのサブスクライバ（サブスクライバはその名前を持つブロードキャストをストリーミングします）に直接送信するpub/subリンクを指します。
各チャネルは、0個以上のブロードキャストをストリーミングできます。

## サーバー側のコンポーネント

### コネクション

サーバーがWebSocketを1個受信するたびに、コネクションオブジェクトのインスタンスが生成されます。
このオブジェクトは、以後作成されるすべての**チャネルサブスクリプション**の親オブジェクトとなり、
認証（authentication）と認可（authorization）以後は、コネクション自身がアプリケーションロジックを扱うことはありません。WebSocketコネクションのクライアントは、コネクションの**コンシューマー**と呼ばれます。
ある個人ユーザーが「ブラウザタブ」「ウィンドウ」「デバイス」を開いて接続するたびに、コンシューマコネクションが1個ずつ作成されます。

コネクションは`ApplicationCable::Connection`のインスタンスで、[`ActionCable::Connection::Base`][]を継承しています。
`ApplicationCable::Connection`では、ユーザーを識別できる場合に、コネクションを認証したのち接続の確立を続行します。

#### コネクションの設定

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        if verified_user = User.find_by(id: cookies.encrypted[:user_id])
          verified_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```

上の[`identified_by`][]はコネクションidであり、後で特定のコネクションを見つけるときに利用できます。idとしてマークされたものは、そのコネクション以外で作成されるすべてのチャネルインスタンスに、同じ名前で自動的にデリゲート（delegate）を作成します。

この例は、アプリケーションの他の場所で既にユーザー認証が扱われており、認証が成功してユーザーIDに暗号化済みcookieが設定されていることを前提としています。

次に、新しいコネクションを試行すると、このcookieがコネクションのインスタンスに自動で送信され、`current_user`の設定に使われます。現在の同じユーザーによるコネクションが識別されれば、以後そのユーザーが開いているすべてのコネクションを取得することも、ユーザーが削除されたり認証できない場合に切断することも可能になります。

認証にセッションを含む場合、セッションにcookieストアを使い、セッションcookieの`_session`とユーザーIDのキーとなる`user_id`を使う方法が利用可能になります。

```ruby
verified_user = User.find_by(id: cookies.encrypted["_session"]["user_id"])
```

[`ActionCable::Connection::Base`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Base.html
[`identified_by`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Identification/ClassMethods.html#method-i-identified_by

#### 例外ハンドリング

デフォルトでは、補足されていない例外は補足されてRailsのログに出力されます。これらの例外をグローバルにインターセプトして外部のバグトラッキングサービスに通知したい場合は、たとえば以下のように[`rescue_from`][]を使う方法があります。

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    private
      def report_error(e)
        SomeExternalBugtrackingService.notify(e)
      end
  end
end
```

[`rescue_from`]:
  https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from

#### コネクションのコールバック

[`ActionCable::Connection::Callbacks`][]は、（サブスクライブ、アンサブスクライブ、アクションの実行などで）クライアントにコマンドを送信するときに呼び出される以下のコールバックフックを提供します。

* [`before_command`][]（コマンドの実行前）
* [`after_command`][]（コマンドの実行後）
* [`around_command`][]（コマンドの実行前後）

[`ActionCable::Connection::Callbacks`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Callbacks.html
[`after_command`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Callbacks/ClassMethods.html#method-i-after_command
[`around_command`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Callbacks/ClassMethods.html#method-i-around_command
[`before_command`]:
  https://api.rubyonrails.org/classes/ActionCable/Connection/Callbacks/ClassMethods.html#method-i-before_command

### チャネル

**チャネル**（Channel） は論理的な作業単位をカプセル化するものであり、典型的なMVCセットアップでコントローラが果たす役割と似ています。チャネルジェネレータを初めて使うとき、チャネル間の共有ロジックをカプセル化するために、Railsはチャネル間で共有されるロジックをカプセル化する以下の`ApplicationCable::Channel`という親クラス（これは[`ActionCable::Channel::Base`][]を継承します）をデフォルトで作成します。

#### 親チャネルの設定

```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

独自のチャネルクラスの例は以下の通りです。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
end
```

```ruby
# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
end
```

これで、コンシューマーがチャネルをサブスクライブできるようになります。

[`ActionCable::Channel::Base`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Base.html

#### サブスクリプション

コンシューマーはチャネルをサブスクライブして、**サブスクライバ**（Subscriber）の役割を果たします。それらのコンシューマーのコネクションは**サブスクリプション**（Subscription: 購読）と呼ばれます。生成されたメッセージは、Action Cableコンシューマーが送信するidに基いて、これらのチャネルサブスクライバ側にルーティングされます。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  # コンシューマーがこのチャネルのサブスクライバになると
  # このコードが呼び出される
  def subscribed
  end
end
```

#### 例外ハンドリング

`ApplicationCable::Connection`の場合と同様、[`rescue_from`][]を利用すると特定チャネルで発生する例外を扱えるようになります。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  rescue_from "MyError", with: :deliver_error_message

  private
    def deliver_error_message(e)
      # broadcast_to(...)
    end
end
```

#### チャネルのコールバック

[`ActionCable::Channel::Callbacks`][]は、チャネルのライフサイクルの間に呼び出される以下のコールバックフックを提供します。

* [`before_subscribe`][]
* [`after_subscribe`][]（エイリアス: [`on_subscribe`][]）
* [`before_unsubscribe`][]
* [`after_unsubscribe`][]（エイリアス: [`on_unsubscribe`][]）

[`ActionCable::Channel::Callbacks`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks.html
[`after_subscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-after_subscribe
[`after_unsubscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-after_unsubscribe
[`before_subscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-before_subscribe
[`before_unsubscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-before_unsubscribe
[`on_subscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-on_subscribe
[`on_unsubscribe`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Callbacks/ClassMethods.html#method-i-on_unsubscribe

## クライアント側のコンポーネント

### コネクション

コンシューマー側でも、コネクションのインスタンスが必要になります。このコネクションは、Railsがデフォルトで生成する以下のJavaScriptコードによって確立します。

#### コンシューマーに接続する

```js
// app/javascript/channels/consumer.js
// Action CableはRailsでWebSocketを扱うフレームワークを提供する
// WebSocketがある場所で`bin/rails generate channel`コマンドを使うと新しいチャネルを生成できる

import { createConsumer } from "@rails/actioncable"

export default createConsumer()
```

これにより、サーバーの`/cable`にデフォルトで接続するコンシューマーが利用可能になります。コネクションは、利用するサブスクリプションを1つ以上指定するまで確立しません。

このコンシューマーは、オプションとして接続先URLを指定する引数を1つ受け取れます。引数には文字列を渡すことも、WebSocketがオープンされるときに呼び出されて文字列を返す関数も渡すことも可能です。

```js
// 異なる接続先URLを指定する
createConsumer('wss://example.com/cable')
// または、websockets over HTTPを使う場合
createConsumer('https://ws.example.com/cable')

// 動的にURLを生成する関数
createConsumer(getWebSocketURL)

function getWebSocketURL() {
  const token = localStorage.get('auth-token')
  return `wss://example.com/cable?token=${token}`
}
```

#### サブスクライバ

指定のチャネルでサブスクリプションを作成すると、コンシューマーがサブスクライバになります。

```js
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" })

// app/javascript/channels/appearance_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "AppearanceChannel" })
```

サブスクリプションは上のコードで作成されます。受信したデータに応答する機能については後述します。

コンシューマーは、指定のチャネルに対するサブスクライバとして振る舞えます（回数の制限はありません）。たとえば、コンシューマーでは以下のようにチャットルームを同時にいくつでもサブスクライブできます。

```js
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "1st Room" })
consumer.subscriptions.create({ channel: "ChatChannel", room: "2nd Room" })
```

## クライアント-サーバー間のやりとり

### ストリーム

**ストリーム**（stream）は、パブリッシュされたコンテンツ（ブロードキャスト）をサブスクライバに配信するメカニズムです。
たとえば以下のコードは、`room`パラメータの値が`"Best Room"`の場合に、[`stream_from`][]を用いて`chat_Best Room`という名前のブロードキャストをサブスクライブしています。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

これで、Railsアプリケーションのどのコードでも、以下のように[`broadcast`][]を呼び出せばチャットルームにブロードキャストできるようになります。

```ruby
ActionCable.server.broadcast("chat_Best Room", { body: "このチャットルーム名はBest Roomです" })
```

あるモデルに関連するストリームを作成すると、そのモデルとチャネルからブロードキャストが生成されます。以下の例は、`posts:Z2lkOi8vVGVzdEFwcC9Qb3N0LzE`のような形式のブロードキャストを[`stream_for`][]でサブスクライブします（`Z2lkOi8vVGVzdEFwcC9Qb3N0LzE`はPostモデルのGlobalID）。

```ruby
class PostsChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    stream_for post
  end
end
```

これで、以下のように[`broadcast_to`][]を呼び出せばこのチャネルにブロードキャストできるようになります。

```ruby
PostsChannel.broadcast_to(@post, @comment)
```

[`broadcast`]:
  https://api.rubyonrails.org/classes/ActionCable/Server/Broadcasting.html#method-i-broadcast
[`broadcast_to`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Broadcasting/ClassMethods.html#method-i-broadcast_to
[`stream_for`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Streams.html#method-i-stream_for
[`stream_from`]:
  https://api.rubyonrails.org/classes/ActionCable/Channel/Streams.html#method-i-stream_from

### ブロードキャスト

**ブロードキャスト**（broadcasting）は、pub/subのリンクです。パブリッシャからの送信内容がすべてブロードキャストを経由し、その名前のブロードキャストをストリーミングするチャネルサブスクライバに直接ルーティングされます。各チャネルは、0個以上のブロードキャストをストリーミングできます。

ブロードキャストは純粋なオンラインキューであり、時間に依存します。ストリーミング（指定のチャネルにサブスクライブされること）を行っていないコンシューマーは、後で接続してもブロードキャストを取得できません。

### サブスクリプション

あるチャネルでサブスクライブされたコンシューマーは、サブスクライバとして振る舞います。このコネクションもサブスクリプションと呼ばれます。受信メッセージは、Action Cableコンシューマーが送信するidに基いて、これらのチャネルサブスクライバにルーティングされます。

```js
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    this.appendLine(data)
  },

  appendLine(data) {
    const html = this.createLine(data)
    const element = document.querySelector("[data-chat-room='Best Room']")
    element.insertAdjacentHTML("beforeend", html)
  },

  createLine(data) {
    return `
      <article class="chat-line">
        <span class="speaker">${data["sent_by"]}</span>
        <span class="body">${data["body"]}</span>
      </article>
    `
  }
})
```

### チャネルにパラメータを渡す

サブスクリプション作成時に、以下のようにクライアント側のパラメータをサーバー側に渡せます。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

`subscriptions.create`に第1引数として渡されるオブジェクトは、そのAction Cableチャネルのparamsハッシュになります。キーワード`channel`は必須です。

```js
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    this.appendLine(data)
  },

  appendLine(data) {
    const html = this.createLine(data)
    const element = document.querySelector("[data-chat-room='Best Room']")
    element.insertAdjacentHTML("beforeend", html)
  },

  createLine(data) {
    return `
      <article class="chat-line">
        <span class="speaker">${data["sent_by"]}</span>
        <span class="body">${data["body"]}</span>
      </article>
    `
  }
})
```

```ruby
# このコードはアプリケーションのどこか（NewCommentJobあたり）で呼び出される
ActionCable.server.broadcast(
  "chat_#{room}",
  {
    sent_by: "Paul",
    body: "This is a cool chat app."
  }
)
```

### メッセージを再ブロードキャストする

あるクライアントから、接続している別のクライアントに、メッセージを*再ブロードキャスト*することはよくあります。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end

  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:room]}", data)
  end
end
```

```js
// app/javascript/channels/chat_channel.js
import consumer from "./consumer"

const chatChannel = consumer.subscriptions.create({ channel: "ChatChannel", room: "Best Room" }, {
  received(data) {
    // data => { sent_by: "Paul", body: "This is a cool chat app." }
  }
})

chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." })
```

再ブロードキャストは、**送信元クライアント自身も含め**、接続しているすべてのクライアントで受信されます。paramsは、チャネルをサブスクライブするときと同じである点にご注意ください。

## フルスタックの例

以下の設定手順は、2つの例で共通です。

  1. [コネクションの設定](#コンシューマーの設定)
  2. [親チャネルの設定](#親チャネルの設定)
  3. [コンシューマーの接続](#コンシューマーに接続する)

### 例1: ユーザーアピアランスの表示

これは、ユーザーがオンラインかどうか、ユーザーがどのページを開いているかという情報を追跡するチャネルの簡単な例です（オンラインユーザーの横に緑の点を表示する機能を作成する場合などに便利です）。

サーバー側のアピアランスチャネルを作成します。

```ruby
# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    current_user.appear
  end

  def unsubscribed
    current_user.disappear
  end

  def appear(data)
    current_user.appear(on: data["appearing_on"])
  end

  def away
    current_user.away
  end
end
```

サブスクリプションが開始されると、`subscribed`コールバックがトリガーされ、そのユーザーがオンラインであることが示されます。このアピアランスAPIをRedisやデータベースなどと連携することも可能です。

クライアント側のアピアランスチャネルを作成します。

```js
// app/javascript/channels/appearance_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("AppearanceChannel", {
  // サブスクリプション作成時に1度呼び出される
  initialized() {
    this.update = this.update.bind(this)
  },

  // サブスクリプションがサーバーで利用可能になると呼び出される
  connected() {
    this.install()
    this.update()
  },

  // WebSocket接続がクローズすると呼び出される
  disconnected() {
    this.uninstall()
  },

  // サブスクリプションがサーバーで却下されると呼び出される
  rejected() {
    this.uninstall()
  },

  update() {
    this.documentIsActive ? this.appear() : this.away()
  },

  appear() {
    // サーバーの`AppearanceChannel#appear(data)`を呼び出す
    this.perform("appear", { appearing_on: this.appearingOn })
  },

  away() {
    // サーバーの`AppearanceChannel#away`を呼び出す
    this.perform("away")
  },

  install() {
    window.addEventListener("focus", this.update)
    window.addEventListener("blur", this.update)
    document.addEventListener("turbo:load", this.update)
    document.addEventListener("visibilitychange", this.update)
  },

  uninstall() {
    window.removeEventListener("focus", this.update)
    window.removeEventListener("blur", this.update)
    document.removeEventListener("turbo:load", this.update)
    document.removeEventListener("visibilitychange", this.update)
  },

  get documentIsActive() {
    return document.visibilityState === "visible" && document.hasFocus()
  },

  get appearingOn() {
    const element = document.querySelector("[data-appearing-on]")
    return element ? element.getAttribute("data-appearing-on") : null
  }
})
```

##### クライアント-サーバー間のやりとり

1. **クライアント**は、**サーバー**に`createConsumer()`経由で接続する（`consumer.js`）。**サーバー**は、このコネクションを`current_user`で識別する。

2. **クライアント**は、アピアランスチャネルに`consumer.subscriptions.create({ channel: "AppearanceChannel" })`経由で接続する（`appearance_channel.js`）。

3. **サーバー**は、アピアランスチャネル向けに新しいサブスクリプションを開始したことを認識し、サーバーの`subscribed`コールバックを呼び出し、`current_user`の`appear`メソッドを呼び出す（`appearance_channel.rb`）。

4. **クライアント**は、サブスクリプションが確立したことを認識し、`connected`を呼び出す（`appearance_channel.js`）。これにより、`install`と`appear`が呼び出される。`appear`はサーバーの`AppearanceChannel#appear(data)`を呼び出して`{ appearing_on: this.appearingOn }`のデータハッシュを渡す。なお、この動作が可能なのは、クラスで宣言されている（コールバックを除く）全パブリックメソッドが、サーバー側のチャネルインスタンスから自動的に公開されるからです。公開されたパブリックメソッドは、サブスクリプションで`perform`メソッドを使うとRPC（リモートプロシージャコール）として利用できます。

5. **サーバー**は、`current_user`で認識したコネクションのアピアランスチャネルで、`appear`アクションへのリクエストを受信する（`appearance_channel.rb`）。**サーバー**は`:appearing_on`キーを使ってデータをデータハッシュから取り出し、
`current_user.appear`に渡される`:on`キーの値として設定する。

### 例2: 新しいWeb通知を受信する

この例では、WebSocketコネクションを使って、クライアントの機能をサーバーからリモート実行するときのアピアランスを扱います。WebSocketでは双方向通信を利用できます。そこで、例としてサーバーからクライアントでアクションを起動してみましょう。

このWeb通知チャネルは、関連するストリームにブロードキャストを行ったときに、クライアント側でWeb通知を表示します。

サーバー側のWeb通知チャネルを作成します。

```ruby
# app/channels/web_notifications_channel.rb
class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

クライアント側のWeb通知チャネルを作成します。

```js
// app/javascript/channels/web_notifications_channel.js
// クライアント側では、サーバーからWeb通知の送信権を
// リクエスト済みであることが前提
import consumer from "./consumer"

consumer.subscriptions.create("WebNotificationsChannel", {
  received(data) {
    new Notification(data["title"], { body: data["body"] })
  }
})
```

以下のように、アプリケーションのどこからでもWeb通知チャネルのインスタンスにコンテンツをブロードキャストできます。

```ruby
# このコードはアプリケーションのどこか（NewCommentJobあたり）で呼び出される
WebNotificationsChannel.broadcast_to(
  current_user,
  title: "新着情報！",
  body: "印刷しておきたいニュース記事リスト"
)
```

`WebNotificationsChannel.broadcast_to`呼び出しでは、現在のサブスクリプションアダプタのpub/subキューにメッセージを設定します。ユーザーごとに異なるブロードキャスト名が使われます。idが1のユーザーなら、ブロードキャスト名は`web_notifications:1`のようになります。

このチャネルは、`web_notifications:1`で受信したものすべてを`received`コールバック呼び出しでクライアントに直接ストリーミングするようになります。引数として渡されるデータは、サーバー側のブロードキャスト呼び出しに第2パラメータとして渡されたハッシュです。このハッシュはJSONでエンコードされ、`received`として受信したデータ引数から取り出されます。

### より詳しい例

RailsアプリケーションにAction Cableを設定する方法や、チャネルの追加方法の完全な例については、[rails/actioncable-examples](https://github.com/rails/actioncable-examples)を参照してください。

## 設定

Action Cableで必須となる設定は、「サブスクリプションアダプタ」と「許可されたリクエスト送信元」の2つです。

### サブスクリプションアダプタ

Action Cableは、デフォルトで`config/cable.yml`の設定ファイルを利用します。Railsの環境ごとに、アダプタとURLを1つずつ指定する必要があります。アダプタについて詳しくは、[依存関係](#依存関係)を参照してください。

```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: redis
  url: redis://10.10.3.153:6381
  channel_prefix: appname_production
```

#### 利用できるアダプタ設定

以下は、エンドユーザー向けに利用できるサブスクリプションアダプタの一覧です。

##### Asyncアダプタ

`async`アダプタはdevelopment環境やtest環境で利用するためのものなので、production環境では使わないでください。

##### Redisアダプタ

Redisアダプタでは、Redisサーバーを指すURLを指定する必要があります。
また、複数のアプリケーションが同一のRedisサーバーを用いる場合は、チャネル名衝突を避けるために`channel_prefix`の指定が必要になることもあります。詳しくは[Redis Pub/Subドキュメント](https://redis.io/topics/pubsub#database-amp-scoping)を参照してください。

RedisアダプタではSSL/TLS接続もサポートされています。SSL/TLS接続に必要なパラメータは、設定用yamlファイルの`ssl_params`で指定できます（注: `rediss://`は[RedisのHTTPS接続](https://github.com/redis/redis-rb/#ssltls-support)を表します）。

```yaml
production:
  adapter: redis
  url: rediss://10.10.3.153:tls_port
  channel_prefix: appname_production
  ssl_params:
    ca_file: "/path/to/ca.crt"
```

`ssl_params`オプションに渡したパラメータは`OpenSSL::SSL::SSLContext#set_params`メソッドに直接渡され、SSLコンテキストで有効な任意の属性を指定できます。その他に利用可能な属性名については[`OpenSSL::SSL::SSLContext`ドキュメント](https://docs.ruby-lang.org/ja/latest/class/OpenSSL=3a=3aSSL=3a=3aSSLContext.html)を参照してください。

ファイアウォールの内側にあるRedisアダプタ用の自己署名証明書を使うときに、証明書のチェックをスキップしたい場合は、SSLの`verify_mode`に`OpenSSL::SSL::VERIFY_NONE`を指定します。

WARNING: セキュリティ上の影響を完全に理解するまでは、Redisアダプタの設定で`VERIFY_NONE`を指定することはおすすめできません（その場合の設定は`ssl_params: { verify_mode: <%= OpenSSL::SSL::VERIFY_NONE %> }`になります）。

##### PostgreSQLアダプタ

PostgreSQLアダプタはActive Recordコネクションプールを利用するため、アプリケーションのデータベース設定ファイル（`config/database.yml`）でコネクションを設定します。これについては将来変更される可能性があります（[#27214](https://github.com/rails/rails/issues/27214)）。

NOTE: PostgreSQLでは、`NOTIFY`（通知を送信するために内部的に使われるコマンド）に[8000バイトの制限](https://www.postgresql.org/docs/current/sql-notify.html)があり、大きなペイロードを処理するときに制約となる可能性があります。

### 許可されたリクエスト送信元

Action Cableは、指定されていない送信元からのリクエストを受け付けません。送信元リストは、配列の形でサーバー設定に渡します。送信元リストには文字列のインスタンスや正規表現を利用でき、これに対して一致するかどうかがチェックされます。

```ruby
config.action_cable.allowed_request_origins = ["https://rubyonrails.com", %r{http://ruby.*}]
```

すべての送信元からのリクエストを許可または拒否するには、以下を設定します。

```ruby
config.action_cable.disable_request_forgery_protection = true
```

デフォルトでは、development環境で実行中のAction Cableは、localhost:3000からのすべてのリクエストを許可します。

### コンシューマーの設定

URLを設定するには、HTMLレイアウトのHEADセクションに[`action_cable_meta_tag`][]呼び出しを追加します。通常、環境の設定ファイル[`config.action_cable.url`][]で設定されたURLかパスを指定します。

[`config.action_cable.url`]: configuring.html#config-action-cable-url
[`action_cable_meta_tag`]:
  https://api.rubyonrails.org/classes/ActionCable/Helpers/ActionCableHelper.html#method-i-action_cable_meta_tag

### ワーカープールの設定

ワーカープールは、サーバーのメインスレッドから隔離された状態でコネクションのコールバックやチャネルのアクションを実行するために用いられます。Action Cableでは、アプリケーションのワーカープール内で同時に処理されるスレッド数を次のように設定できます。

```ruby
config.action_cable.worker_pool_size = 4
```

サーバーが提供するデータベースコネクション数は、少なくとも利用するワーカー数と同じでなければならない点にもご注意ください。デフォルトのワーカープールサイズは4に設定されているので、データベースコネクション数は少なくとも4以上を確保しなければなりません。この設定は`config/database.yml`の`pool`属性で変更できます。

### クライアント側のログ出力

クライアント側のログ出力はデフォルトで無効になります。以下のように`ActionCable.logger.enabled`に`true`を設定することで、クライアントログ出力有効にできます。

```js
import * as ActionCable from '@rails/actioncable'

ActionCable.logger.enabled = true
```

### その他の設定

その他によく使われるオプションとして、コネクションごとのロガーにタグを保存するオプションがあります。以下の例は、ユーザーアカウントidがある場合はそれをタグ名にし、ない場合は「no-account」をタグ名にします。

```ruby
config.action_cable.log_tags = [
  -> request { request.env["user_account_id"] || "no-account" },
  :action_cable,
  -> request { request.uuid }
]
```

利用可能なすべての設定オプションについては、[`ActionCable::Server::Configuration`][]クラスを参照してください。

[`ActionCable::Server::Configuration`]:
  https://api.rubyonrails.org/classes/ActionCable/Server/Configuration.html

## Action Cable専用サーバーを実行する

Action Cableは、Railsアプリケーションの一部として実行することも、スタンドアロンサーバーとして実行することも可能です。development環境ではRailsアプリケーションの一部として実行するのが一般的ですが、production環境ではスタンドアロンとして実行すべきです。

### アプリケーションで実行

Action CableはRailsアプリケーションと一緒に実行できます。たとえば、`/websocket`でWebSocketリクエストをリッスンするには、以下のように[`config.action_cable.mount_path`][]にパスを指定します。

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_cable.mount_path = "/websocket"
end
```

レイアウトで[`action_cable_meta_tag`][]が呼び出されると、`ActionCable.createConsumer()`でAction Cableサーバーに接続できるようになります。それ以外の場合は、パスが`createConsumer`の最初の引数として指定されます（例: `ActionCable.createConsumer("/websocket")`）。

この場合、サーバーのインスタンスを作成するたびに、およびサーバーがワーカーを生成するたびに、Action Cableの新しいインスタンスも含まれます。RedisやPostgreSQLのアダプタは、コネクション間でメッセージを同期します。

[`config.action_cable.mount_path`]:
  configuring.html#config-action-cable-mount-path
[`action_cable_meta_tag`]:
  https://api.rubyonrails.org/classes/ActionCable/Helpers/ActionCableHelper.html#method-i-action_cable_meta_tag

### スタンドアロン

アプリケーションサーバーとAction Cableサーバーを分けることもできます。Action Cableサーバーは引き続きRackアプリケーションのまま、独自のRackアプリケーションとなります。推奨される基本設定は次のとおりです。

```ruby
# cable/config.ru
require_relative "../config/environment"
Rails.application.eager_load!

run ActionCable.server
```

続いて、サーバーを起動します。

```bash
#!/bin/bash
bundle exec puma -p 28080 cable/config.ru
```

これで、Action Cableサーバーがポート28080で起動します。Railsにこのサーバーを使うように指示するには、設定を以下のように更新します。

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.action_cable.mount_path = nil
  config.action_cable.url = "ws://localhost:28080" # productionではwss://を使うこと
end
```

最後に、[コンシューマーが正しく設定済みである](#コンシューマーの設定)ことを確認してください。

### メモ

WebSocketサーバーはセッションにアクセスできませんが、cookieにはアクセスできます。これを利用して認証を処理できます。ブログ記事「[Action CableとDeviseでの認証](https://greg.molnar.io/blog/actioncable-devise-authentication/)（英語）」を参照してください。

## 依存関係

Action Cableは、pub/subの内部を処理するためのサブスクリプションアダプタインターフェイスを提供します。デフォルトで利用できるアダプタは「非同期」「インライン」「PostgreSQL」「Redis」などです。新規Railsアプリケーションのアダプタは、デフォルトで非同期（`async`）アダプタになります。

Ruby側は、[websocket-driver](https://github.com/faye/websocket-driver-ruby)、
[nio4r](https://github.com/celluloid/nio4r)、[concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby)の上に構築されています。

## デプロイ

Action Cableは、WebSocketとスレッドの組み合わせによって支えられています。フレームワーク内部のフローや、ユーザー指定のチャネルの動作は、Rubyのネイティブスレッドによって処理されます。すなわち、スレッドセーフを損なわない限り、Railsの既存のモデルはすべて問題なく利用できます。

Action CableサーバーはRackのソケットハイジャックAPIを実装しているので、アプリケーションサーバーがマルチスレッドであるかどうかにかかわらず、内部のコネクションをマルチスレッドパターンで管理できます。

これによって、Action Cableは、Unicorn、Puma、Passengerなどの有名なサーバーと問題なく対応できます。

## テスト

Action Cableで作成した機能のテスト方法について詳しくは、[テスティングガイド](testing.html#action-cableをテストする)を参照してください。
