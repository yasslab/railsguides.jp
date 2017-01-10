
Action Cable の概要
=====================

本ガイドでは、Action Cableのしくみと、WebSocketsをRailsアプリケーションに導入してリアルタイム機能を実現する方法について解説します。

このガイドの内容:

* Action Cableの概要、バックエンドとフロントエンドの統合
* Action Cableの設定方法
* チャネルの設定方法
* Action Cable向けのデプロイとアーキテクチャの設定

--------------------------------------------------------------------------------

はじめに
------------

Action Cableは、
[WebSockets](https://ja.wikipedia.org/wiki/WebSocket)とRailsのその他の部分をシームレスに統合するためのものです。Action Cable が導入されたことで、Rails アプリケーションの効率の良さとスケーラビリティを損なわずに、通常のRailsアプリケーションと同じスタイル・方法でリアルタイム機能をRubyで記述できます。クライアント側のJavaScriptフレームワークとサーバー側のRubyフレームワークを同時に提供する、フルスタックのフレームワークです。Active RecordなどのORMで書かれたすべてのドメインモデルにアクセスできます。

Pub/Subについて
---------------

[Pub/Sub](https://ja.wikipedia.org/wiki/%E5%87%BA%E7%89%88-%E8%B3%BC%E8%AA%AD%E5%9E%8B%E3%83%A2%E3%83%87%E3%83%AB)はパブリッシュ/サブスクライブとも呼ばれる、メッセージキューのパラダイムです。パブリッシャ（送信者）が、サブスクライバ（受信者）の抽象クラスに情報を送信します。
このとき、個別の受信者を指定しません。Action Cableでは、このアプローチを採用してサーバーと多数のクライアント間で通信を行います。

## サーバー側のコンポーネント

### 接続

*接続*（connection）は、クライアントとサーバー間の関係を成立させる基礎となります。サーバーでWebSocketを受け付けるたびに、接続オブジェクトがインスタンス化します。このオブジェクトは、今後作成されるすべての*チャネルサブスクリプション*の親となります。この接続自体は、認証や承認の後、特定のアプリケーションロジックを扱いません。WebSocket接続のクライアントは*コンシューマー*と呼ばれます。各ユーザーが開くブラウザタブ、ウィンドウ、デバイスごとに、コンシューマー接続ペアが1つずつ作成されます。

接続は、`ApplicationCable::Connection`のインスタンスです。このクラスでは、着信接続を承認し、ユーザーを特定できた場合に接続を確立します。

#### 接続の設定

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected
      def find_verified_user
        if current_user = User.find_by(id: cookies.signed[:user_id])
          current_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```

上の`identified_by`は接続IDであり、後で特定の接続を見つけるときに利用できます。IDとしてマークされたものは、その接続以外で作成されるすべてのチャネルインスタンスに、同じ名前で自動的にデリゲートを作成します。

この例では、アプリケーションの他の場所で既にユーザー認証を扱っており、認証成功によってユーザーIDに署名済みcookieが設定されていることを前提としています。

次に、新しい接続を求められたときにこのcookieが接続インスタンスに自動で送信され、`current_user`の設定に使われます。現在の同じユーザーによる接続が識別されると、そのユーザーが開いているすべての接続を取得することも、ユーザーが削除されたり認証できない場合に切断することもできるようになります。

### チャネル

*チャネル*は、論理的な作業単位をカプセル化します。通常のMVC設定でコントローラが果たす役割と似ています。Railsはデフォルトで、チャネル間で共有されるロジックをカプセル化する`ApplicationCable::Channel`という親クラスを作成します。

#### 親チャネルの設定

```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

上のコードによって、専用のChannelクラスを作成します。たとえば、
`ChatChannel`や`AppearanceChannel`などは次のように作成します。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
end

# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
end
```

これで、コンシューマはこうしたチャネルをサブスクライブできるようになります。

#### サブスクリプション

コンシューマーは、チャネルをサブスクライブする*サブスクライバ*の役割を果たします。そして、コンシューマーの接続は*サブスクリプション*と呼ばれます。生成されたメッセージは、Action Cableコンシューマーが送信するIDに基いて、これらのチャネルサブスクリプションにルーティングされます。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  # コンシューマーがこのチャネルのサブスクライバになると
  # このコードが呼び出される
  def subscribed
  end
end
```

## クライアント側のコンポーネント

### 接続

コンシューマー側でも、接続のインスタンスが必要になります。この接続は、Railsがデフォルトで生成する次のJavaScriptコードによって確立します。

#### コンシューマーの接続

```js
// app/assets/javascripts/cable.js
//= require action_cable
//= require_self
//= require_tree ./channels

(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();
}).call(this);
```

これにより、サーバーの`/cable`にデフォルトで接続するコンシューマーが準備されます。利用したいサブスクリプションが指定されていない場合、接続は確立しません。

#### サブスクライバ

指定のチャネルにサブスクリプションを作成することで、コンシューマーがサブスクライバになります。

```coffeescript
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" }

# app/assets/javascripts/cable/subscriptions/appearance.coffee
App.cable.subscriptions.create { channel: "AppearanceChannel" }
```

サブスクリプションは上のコードで作成されます。受信したデータに応答する機能については後述します。

コンシューマーは、指定のチャネルに対するサブスクライバとして振る舞うことができます。回数の制限はありません。たとえば、コンシューマーはチャットルームを同時にいくつでもサブスクライブできます。

```coffeescript
App.cable.subscriptions.create { channel: "ChatChannel", room: "1st Room" }
App.cable.subscriptions.create { channel: "ChatChannel", room: "2nd Room" }
```

## クライアント-サーバー間のやりとり

### ストリーム

*ストリーム*は、ブロードキャストでパブリッシュするコンテンツをサブスクライバにルーティングする機能をチャネルに提供します。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

あるモデルに関連するストリームを作成すると、利用するブロードキャストがそのモデルとチャネルから生成されます。次の例 では、`comments:Z2lkOi8vVGVzdEFwcC9Qb3N0LzE`のような形式のブロードキャストにサブスクライブします。

```ruby
class CommentsChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    stream_for post
  end 
end
```

これで、このチャネルに次のようにブロードキャストできるようになります。

```ruby
CommentsChannel.broadcast_to(@post, @comment)
```

### ブロードキャスト

*ブロードキャスト*（broadcasting）は、pub/subのリンクです。パブリッシャーからの送信内容はすべてブロードキャスト経由を経由し、その名前のブロードキャストをストリーミングするチャネルサブスクライバに直接ルーティングされます。各チャネルは、0個以上のブロードキャストをストリーミングできます。

ブロードキャストは純粋なオンラインキューであり、時間に依存します。ストリーミング（指定のチャネルへのサブスクライブ）を行っていないコンシューマーは、後で接続するときにブロードキャストを取得できません。

ブロードキャストは、Railsアプリケーションの別の場所で呼び出されます。

```ruby
WebNotificationsChannel.broadcast_to(
  current_user,
  title: 'New things!',
  body: 'All the news fit to print'
)
```

`WebNotificationsChannel.broadcast_to`呼び出しでは、現在のサブスクリプションアダプタ（デフォルトはRedis）のpubsubキューにメッセージを設定します。ユーザーごとに異なるブロードキャスト名が使用されます。IDが1のユーザーなら、ブロードキャスト名は`web_notifications_1`のようになります。

`received`コールバックを呼び出すことで、このチャネルは`web_notifications_1`に着信するものをすべてクライアントに直接ストリーミングするようになります。

### サブスクリプション

チャネルにサブスクライブしたコンシューマーは、サブスクライバとして振る舞います。この接続はサブスクリプションと呼ばれます。着信メッセージは、Action Cableコンシューマーが送信するIDに基いて、これらのチャネルサブスクリプションにルーティングされます。

```coffeescript
# app/assets/javascripts/cable/subscriptions/chat.coffee
# web通知の送信権をサーバーからリクエスト済みであることが前提
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    @appendLine(data)

  appendLine: (data) ->
    html = @createLine(data)
    $("[data-chat-room='Best Room']").append(html)

  createLine: (data) ->
    """
    <article class="chat-line">
      <span class="speaker">#{data["sent_by"]}</span>
      <span class="body">#{data["body"]}</span>
    </article>
    """
```

### チャネルにパラメータを渡す

サブスクリプション作成時に、クライアント側のパラメータをサーバー側に渡すことができます。以下に例を示します。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

`subscriptions.create`に最初の引数として渡されるオブジェクトは、Action Cableチャネルのparamsハッシュになります。キーワード`channel`の指定は省略できません。

```coffeescript
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    @appendLine(data)

  appendLine: (data) ->
    html = @createLine(data)
    $("[data-chat-room='Best Room']").append(html)

  createLine: (data) ->
    """
    <article class="chat-line">
      <span class="speaker">#{data["sent_by"]}</span>
      <span class="body">#{data["body"]}</span>
    </article>
    """
```

```ruby
# このコードはアプリのどこかで呼び出される
# おそらくNewCommentJobなどのあたりで
ChatChannel.broadcast_to(
  "chat_#{room}",
  sent_by: 'Paul',
  body: 'This is a cool chat app. '
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
    ChatChannel.broadcast_to("chat_#{params[:room]}", data)
  end
end
```

```coffeescript
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.chatChannel = App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    # data => { sent_by: "Paul", body: "This is a cool chat app." }

App.chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." })
```

再ブロードキャストは、接続しているすべてのクライアントで受信されます。送信元クライアント自身も再ブロードキャストを受信します。利用するparamsは、チャネルにサブスクライブするときと同じです。

## フルスタックの例

以下の設定手順は、2つの例で共通です。

  1. [接続を設定](#connection-setup).
  2. [親チャネルを設定](#parent-channel-setup).
  3. [コンシューマーを接続](#connect-consumer).

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
    current_user.appear(on: data['appearing_on'])
  end

  def away
    current_user.away
  end
end
```

サブスクリプションが開始されると、`subscribed`コールバックがトリガーされ、そのユーザーがオンラインであることが示されます。このアピアランスAPIをRedisやデータベースなどと連携することもできます。

クライアント側のアピアランスチャネルを作成します。

```coffeescript
# app/assets/javascripts/cable/subscriptions/appearance.coffee
App.cable.subscriptions.create "AppearanceChannel",
  # サブスクリプションがサーバー側で利用可能になると呼び出される
  connected: ->
    @install()
    @appear()

  # WebSocket接続が閉じると呼び出される
  disconnected: ->
    @uninstall()

  # サブスクリプションがサーバーに拒否されると呼び出される
  rejected: ->
    @uninstall()

  appear: ->
    # サーバーの`AppearanceChannel#appear(data)`を呼び出す
    @perform("appear", appearing_on: $("main").data("appearing-on"))

  away: ->
    # サーバーの`AppearanceChannel#away`を呼び出す
    @perform("away")


  buttonSelector = "[data-behavior~=appear_away]"

  install: ->
    $(document).on "page:change.appearance", =>
      @appear()

    $(document).on "click.appearance", buttonSelector, =>
      @away()
      false

    $(buttonSelector).show()

  uninstall: ->
    $(document).off(".appearance")
    $(buttonSelector).hide()
```

##### クライアント-サーバー間のやりとり

1. **クライアント**は**サーバー**に`App.cable = ActionCable.createConsumer("ws://cable.example.com")`経由で接続する（`cable.js`）。**サーバー**は、この接続の認識に`current_user`を使う。

2. **クライアント**はアピアランスチャネルに`App.cable.subscriptions.create(channel: "AppearanceChannel")`経由で接続する（`appearance.coffee`）

3. **サーバー**は、アピアランスチャネル向けに新しいサブスクリプションを開始したことを認識し、サーバーの`subscribed`コールバックを呼び出し、`current_user`の`appear`メソッドを呼び出す。（`appearance_channel.rb`）

4. **クライアント**は、サブスクリプションが確立したことを認識し、`connected`（`appearance.coffee`）を呼び出す。これにより、`@install`と`@appear`が呼び出される。`@appear`はサーバーの`AppearanceChannel#appear(data)`を呼び出して`{ appearing_on: $("main").data("appearing-on") }`のデータハッシュを渡す。なお、この動作が可能なのは、クラスで宣言されている（コールバックを除く）全パブリックメソッドが、サーバー側のチャネルインスタンスから自動的に公開されるからです。公開されたパブリックメソッドは、サブスクリプションで`perform`メソッドを使って、RPC（リモートプロシージャコール）として利用できます。

5. **サーバー**は、`current_user`で認識した接続のアピアランスチャネルで、`appear`アクションへのリクエストを受信する。（`appearance_channel.rb`）**サーバー**は`:appearing_on`キーを使ってデータをデータハッシュから取り出し、
`current_user.appear`に渡される`:on`キーの値として設定する。

### 例2: 新しいweb通知を受信する

この例では、WebSocket接続を使って、サーバーからクライアント側の機能をリモート実行するときのアピアランスを扱います。WebSocketでは双方向通信を利用できます。そこで、例としてサーバーからクライアントでアクションを起動してみます。

このweb通知チャネルは、正しいストリームにブロードキャストを行ったときに、クライアント側でweb通知を表示します。

サーバー側のweb通知チャネルを作成します。

```ruby
# app/channels/web_notifications_channel.rb
class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

クライアント側のweb通知チャネルを作成します。

```coffeescript
# app/assets/javascripts/cable/subscriptions/web_notifications.coffee
# クライアント側では、サーバーからweb通知の送信権を
# リクエスト済みであることが前提
App.cable.subscriptions.create "WebNotificationsChannel",
  received: (data) ->
    new Notification data["title"], body: data["body"]
```

アプリケーションのどこからでも、web通知チャネルのインスタンスにコンテンツを送信できます。

```ruby
# このコードはアプリのどこか（NewCommentJob あたり）で呼び出される
WebNotificationsChannel.broadcast_to(
  current_user,
  title: 'New things!',
  body: 'All the news fit to print'
)
```

`WebNotificationsChannel.broadcast_to`呼び出しでは、現在のサブスクリプションアダプタのpubsubキューにメッセージを設定します。ユーザーごとに異なるブロードキャスト名が使用されます。IDが1のユーザーなら、ブロードキャスト名は`web_notifications_1`のようになります。

`received`コールバックを呼び出すことで、このチャネルは`web_notifications_1`に着信するものをすべてクライアントに直接ストリーミングするようになります。引数として渡されたデータは、サーバー側のブロードキャスト呼び出しに2番目のパラメータとして渡されたハッシュです。このハッシュはJSONでエンコードされ、`received`で受信したときにデータ引数から取り出されます。

### より詳しい例

RailsアプリにAction Cableを設定する方法やチャネルの追加方法については、[rails/actioncable-examples](https://github.com/rails/actioncable-examples) で完全な例をご覧いただけます。

## 設定

Action Cableで必須となる設定は、「サブスクリプションアダプタ」と「許可されたリクエスト送信元」の2つです。

### サブスクリプションアダプタ

Action Cableは、デフォルトで`config/cable.yml`の設定ファイルを利用します。Railsの環境ごとに、アダプタとURLを1つずつ指定する必要があります。アダプタについて詳しくは、[依存関係](#依存関係) の節をご覧ください。

```yaml
development:
  adapter: async

test:
  adapter: async

production:
  adapter: redis
  url: redis://10.10.3.153:6381
```

### 許可されたリクエスト送信元

Action Cableは、指定されていない送信元からのリクエストを受け付けません。送信元リストは、配列の形でサーバー設定に渡します。送信元リストのインスタンスでは、文字列を利用することも、正規表現で一致をチェックすることもできます。

```ruby
config.action_cable.allowed_request_origins = ['http://rubyonrails.com', %r{http://ruby.*}]
```

すべての送信元からのリクエストを許可または拒否するには、次を設定します。

```ruby
config.action_cable.disable_request_forgery_protection = true
```

development環境で実行中、Action Cableはlocalhost:3000からのすべてのリクエストをデフォルトで許可します。

### コンシューマーの設定

URLを設定するには、HTMLレイアウトのHEADセクションに`action_cable_meta_tag`呼び出しを追加します。通常、ここで使うURLは、環境ごとの設定ファイルで`config.action_cable.url`に設定されます。

### その他の設定

他にも、接続ごとのロガーにタグを保存するオプションがあります。次の例は、ユーザーアカウントIDがある場合はそれを使い、ない場合は「no-account」を使うタグ付けです。

```ruby
config.action_cable.log_tags = [
  -> request { request.env['user_account_id'] || "no-account" },
  :action_cable,
  -> request { request.uuid }
]
```

利用可能なすべての設定オプションについては、`ActionCable::Server::Configuration`クラスをご覧ください。

もう1つ注意が必要な点があります。サーバーが提供するデータベース接続の数は、少なくともワーカー数を下回らないようにする必要があります。デフォルトのワーカープールサイズは4なので、データベース接続も4つは用意する必要があります。この値は、`config/database.yml`の`pool`属性で変更できます。

## Action Cable専用サーバーを実行する

### アプリで実行

Action CableはRailsアプリケーションと一緒に実行できます。たとえば、`/websocket`でWebSocketリクエストをリッスンするには、`config.action_cable.mount_path`でパスを指定します。

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_cable.mount_path = '/websocket'
end 
```

レイアウトで`action_cable_meta_tag`を呼び出すと、`App.cable = ActionCable.createConsumer()`でAction Cableサーバーに接続できるようになります。`createConsumer`の最初の引数にはカスタムパスが指定されます（例: `App.cable = ActionCable.createConsumer("/websocket")`）。

作成したサーバーの全インスタンスと、サーバーが作成した全ワーカーのインスタンスには、Action Cableの新しいインスタンスも含まれます。接続間のメッセージ同期は、Redisによって行われます。

### スタンドアロン

アプリケーション・サーバーとAction Cableサーバーを分けることもできます。Action CableサーバーはRackアプリケーションですが、独自のRackアプリケーションでもあります。推奨される基本設定は次のとおりです。

```ruby
# cable/config.ru
require_relative '../config/environment'
Rails.application.eager_load!

run ActionCable.server
```

続いて、 `bin/cable`のbinstubを使ってサーバーを起動します。

```
#!/bin/bash
bundle exec puma -p 28080 cable/config.ru
```

ポート28080でAction Cableサーバーが起動します。

### メモ

WebSocketサーバーからはセッションにアクセスできませんが、cookieにはアクセスできます。これを利用して認証を処理できます。[Action CableとDeviseでの認証](http://www.rubytutorial.io/actioncable-devise-authentication) 記事をご覧ください。

## 依存関係

Action Cableは、自身のpubsub内部のプロセスへのサブスクリプションアダプタインターフェイスを提供します。非同期、インライン、PostgreSQL、イベント化Redis、非イベント化Redisなどのアダプタをデフォルトで利用できます。新規Railsアプリケーションのデフォルトアダプタは非同期（`async`）アダプタです。

Ruby側では、[websocket-driver](https://github.com/faye/websocket-driver-ruby)、
[nio4r](https://github.com/celluloid/nio4r)、[concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby)の上に構築されています。

## デプロイ

Action Cableを支えているのは、WebSocketsとスレッドの組み合わせです。フレームワーク内部の流れや、ユーザー指定のチャネルの動作は、Rubyのネイティブスレッドによって処理されます。つまり、スレッドセーフを損なわない限り、Railsの正規のモデルはすべて問題なく利用できるということです。

Action Cableサーバーには、RackソケットをハイジャックするAPIが実装されています。これによって、アプリケーション・サーバーがマルチスレッドであるかどうかにかかわらず、内部の接続をマルチスレッドパターンで管理できます。

つまり、Action Cableは、Unicorn、Puma、Passengerなどの有名なサーバーと問題なく連携できるのです。