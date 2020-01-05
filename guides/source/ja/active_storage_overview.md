**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Active Storage の概要
=====================

このガイドはActive Recordモデルにファイルを添付する方法について説明します。

このガイドを読むと下記の内容が理解できるでしょう。

* 1つまたは複数のファイルを1つのレコードに添付する方法。
* 添付ファイルを消す方法
* 添付ファイルへのリンク方法
* バリアントを利用して画像を変換する方法
* PDFや動画に代表されるような非画像ファイルの生成方法
* あなたのアプリケーションサーバーを介して、ブラウザからストレージサービスに直接ファイルをアップロードする方法
* テスト中に保存されたファイルをクリーンアップする方法
* 追加のストレージサービスをサポートするための実装方法

--------------------------------------------------------------------------------

Active Storageについて
-----------------------

Active StorageとはAmazon S3、Google Cloud Storage、Microsoft Azure Storageなどの
クラウドストレージサービスへのファイルのアップロードや、ファイルをActive Recordオブジェクトにアタッチする機能を提供します。development環境とtest環境向けのローカルディスクベースのサービスを利用できるようになっており、ファイルを下位のサービスにミラーリングしてバックアップや移行に用いることもできます。

アプリケーションでActive Storageを用いることで、[ImageMagick](https://www.imagemagick.org)で画像のアップロードを変換したり、
PDFやビデオなどの非画像アップロードの画像表現を生成したり、任意のファイルからメタデータを抽出したりできます。

## セットアップ

Active Storageは、アプリケーションのデータベースで `active_storage_blobs`と`active_storage_attachments`という名前の2つのテーブルを使用します。
新規アプリケーション作成した後（または既存のアプリケーションをRails 5.2にアップグレードした後）に、`rails active_storage:install`を実行して、これらのテーブルを作成するmigrationファイルを作成します。
migrationファイルを実行するには`rails db:migrate`をお使いください。

WARNING: `active_storage_attachments`は、使うモデルのクラス名を保存するポリモーフィックjoinテーブルです。モデルのクラス名を変更した場合は、このテーブルに対してマイグレーションを実行して背後の`record_type`をモデルの新しいクラス名に更新する必要があります。

Active Storageのサービスは`config/storage.yml`で宣言します。アプリケーションが使うサービスごとに、名前と必要な構成を指定します。
次の例では、`local`、`test`、`amazon`という3つのサービスを宣言しています。

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

amazon:
  service: S3
  access_key_id: ""
  secret_access_key: ""
  bucket: ""
  region: "" # 例: 'us-east-1'
```


利用するサービスをActive Storageに認識させるには、`Rails.application.config.active_storage.service`を設定します。
使うサービスは環境ごとに異なることもあるため、この設定を環境ごとに行うことをおすすめします。前述したローカルDiskサービスをdevelopment環境で使うには、`config/environments/development.rb`に以下を追加します。

```ruby
# ファイルをローカルに保存する
config.active_storage.service = :local
```

production環境でAmazon S3を利用するには、`config/environments/production.rb`に以下を追加します。

```ruby
# ファイルをAmazon S3に保存する
config.active_storage.service = :amazon
```

テスト時にテスト用サービスを使うには、`config/environments/test.rb`に以下を追加します。

```ruby
# アップロードしたファイルをローカルファイルシステムの一時ディレクトリに保存する
config.active_storage.service = :test
```

内蔵されているサービスアダプタ(`Disk`や`S3`など)およびそれらに必要な設定について、詳しくは後述します。

### Diskサービス

Diskサービスは`config/storage.yml`で宣言します。

``` yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

### Amazon S3サービス

S3サービスは`config/storage.yml`で宣言します。

``` yaml
amazon:
  service: S3
  access_key_id: ""
  secret_access_key: ""
  region: ""
  bucket: ""
```

`Gemfile`に[`aws-sdk-s3`](https://github.com/aws/aws-sdk-ruby) gemを追加します。

``` ruby
gem "aws-sdk-s3", require: false
```

NOTE: Active Storageのコア機能では、`s3:ListBucket`、`s3:PutObject`、`s3:GetObject`、`s3:DeleteObject`という4つのパーミッションが必要です。ACLの設定といったアップロードオプションを追加で設定した場合は、この他にもパーミッションが必要になることがあります。

NOTE: 環境変数、標準SDKの設定ファイル、プロファイル、IAMインスタンスのプロファイルやタスクロールを使いたい場合は、上述の`access_key_id`、`secret_access_key`、`region`を省略できます。Amazon S3サービスでは、[AWS SDK documentation]
(https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html)に記載されている認証オプションをすべてサポートします。

### Microsoft Azure Storageサービス

Azure Storageサービスは`config/storage.yml`で宣言します。

``` yaml
azure:
  service: AzureStorage
  storage_account_name: ""
  storage_access_key: ""
  container: ""
```

`Gemfile`に[`azure-storage`](https://github.com/Azure/azure-storage-ruby) gemを追加します。

``` ruby
gem "azure-storage", require: false
```

### Google Cloud Storageサービス

Google Cloud Storageサービスは`config/storage.yml`で宣言します。

```yaml
google:
  service: GCS
  credentials: <%= Rails.root.join("path/to/keyfile.json") %>
  project: ""
  bucket: ""
```

keyfileパスの代わりに、credentialのハッシュを渡すこともできます。

```yaml
google:
  service: GCS
  credentials:
    type: "service_account"
    project_id: ""
    private_key_id: <%= Rails.application.credentials.dig(:gcs, :private_key_id) %>
    private_key: <%= Rails.application.credentials.dig(:gcs, :private_key).dump %>
    client_email: ""
    client_id: ""
    auth_uri: "https://accounts.google.com/o/oauth2/auth"
    token_uri: "https://accounts.google.com/o/oauth2/token"
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs"
    client_x509_cert_url: ""
  project: ""
  bucket: ""
```

`Gemfile`に[`google-cloud-storage`](https://github.com/GoogleCloudPlatform/google-cloud-ruby/tree/master/google-cloud-storage) gemを追加します。

``` ruby
gem "google-cloud-storage", "~> 1.11", require: false
```

### ミラーサービス

ミラーサービスを定義すると、複数のサービスを同期できます。ファイルのアップロードや削除は、ミラー化されたすべてのサービスに渡って行われます。ミラーリングされたサービスを用いることで、production環境内のサービス間の移行も行えます。新しいサービスへのミラーリングを開始したり、既存のファイルを古いサービスから新しいサービスにコピーしたり、新しいサービスに完全に切り替えたりできます。利用したいサービスごとに上と同じ要領で定義し、ミラー化されたサービスから参照します。

``` yaml
s3_west_coast:
  service: S3
  access_key_id: ""
  secret_access_key: ""
  region: ""
  bucket: ""

s3_east_coast:
  service: S3
  access_key_id: ""
  secret_access_key: ""
  region: ""
  bucket: ""

production:
  service: Mirror
  primary: s3_east_coast
  mirrors:
    - s3_west_coast
```

NOTE: ファイルはprimaryサービスから提供されます。

NOTE: この機能は[ダイレクトアップロード](#ダイレクトアップロード)機能との互換性がありません。

ファイルをレコードに添付する
-----------------------

### `has_one_attached`

`has_one_attached`マクロは、レコードとファイルの間に1対1のマッピングを設定します。各レコードには1つのファイルを添付できます。

たとえば、アプリケーションに`User`モデルがあるとします。各userにavatarを持たせたい場合は、以下のように`User`モデルを定義します。

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
end
```

以下のように書くことでavatar付きのuserを作成できます。

```erb
<%= form.file_field :avatar %>
```

```ruby
class SignupController < ApplicationController
  def create
    user = User.create!(user_params)
    session[:user_id] = user.id
    redirect_to root_path
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :avatar)
    end
end
```

既存のuserにavatarを添付するには`avatar.attach`を呼び出します。

```ruby
user.avatar.attach(params[:avatar])
```

`avatar.attached?`で特定のuserがavatarを持っているかどうかを調べられます。

```ruby
user.ava.user.avatar.attached?
```

### `has_many_attached`

`has_many_attached`マクロは、レコードとファイルの間に1対多の関係を設定します。各レコードには、多数の添付ファイルをアタッチできます。

たとえば、アプリケーションに`Message`モデルがあるとします。メッセージごとに多数の画像を持たせるには、次のような`Message`モデルを定義します.

```ruby
class Message < ApplicationRecord
  has_many_attached :images
end
```

以下のように書くことで、画像付きのメッセージを作成できます。

```ruby
class MessagesController < ApplicationController
  def create
    message = Message.create!(message_params)
    redirect_to message
  end

  private
    def message_params
      params.require(:message).permit(:title, :content, images: [])
    end
end
```

`images.attach`を呼び出すと、既存のメッセージに新しい画像を追加できます。

```ruby
@message.images.attach(params[:images])
```

あるメッセージに何らかの画像がアタッチされているかどうかを調べるには、`image.attached?`を呼び出します。

```ruby
@message.images.attached?
```

### File/IO Objectsをアタッチする

HTTPリクエスト経由では配信されないファイルをアタッチする必要が生じる場合があります。たとえば、ディスク上で生成したファイルやユーザーが送信したURLからダウンロードしたファイルをアタッチしたい場合や、モデルのテストでfixtureファイルをアタッチしたい場合などが考えられます。これを行うには、オープンIOオブジェクトとファイル名を1つ以上含むハッシュを渡します。

```ruby
@message.image.attach(io: File.open('/path/to/file'), filename: 'file.pdf')
```

可能であれば、`content_type:`も指定しましょう。Active Storageは、渡されたデータからファイルのcontent_typeの判定を試みますが、判定できない場合はcontent_typeにフォールバックします。

```ruby
@message.image.attach(io: File.open('/path/to/file'), filename: 'file.pdf', content_type: 'application/pdf')
```

データを元にするcontent type推測をバイパスするには、`content_type`にcontent typeを渡し、`identify: false`を指定します。

```ruby
@message.image.attach(
  io: File.open('/path/to/file'),
  filename: 'file.pdf',
  content_type: 'application/pdf',
  identify: false
)
```

content typeを指定しないと、Active Storageでファイルのcontent typeを自動推測できなくなり、デフォルトのapplication/octet-streamが使われます。

ファイルを削除する
-----------------------------

添付ファイルをモデルから削除するには、添付ファイルに対して `purge`を呼び出します。
Active Jobを使用するようにアプリケーションが設定されている場合は、バックグラウンドで削除を実行できます。消去すると、BLOBとファイルがストレージサービスから削除されます。

```ruby
# avatarと実際のリソースファイルを同期的に破棄します。
user.avatar.purge

# Active Jobを介して、関連付けられているモデルと実際のリソースファイルを非同期で破棄します。
user.avatar.purge_later
```

ファイルにリンクする
-------------------

アプリケーションを指すblobのパーマネントURLを生成します。アクセス時には、実際のサービスエンドポイントへのリダイレクトが返されます。
このインダイレクションによってパブリックURLを実際のURLと切り離し、たとえば、高可用性のために添付ファイルを別サービスにミラーリングすることもできます。リダイレクトのHTTPの有効期限は5分です。

```ruby
url_for(user.avatar)
```

ダウンロードリンクを作成するには、`rails_blob_ {path | url}`ヘルパーを使います。このヘルパーで`disposition:`を設定できます。

```ruby
rails_blob_path(user.avatar, disposition: "attachment")
```

コントローラやビューのコンテキストの外(バックグラウンドジョブやcronジョブなど)からリンクを作成したい場合、`rails_blob_path`を用いて以下のようにアクセスできます。

```ruby
Rails.application.routes.url_helpers.rails_blob_path(user.avatar, only_path: true)
```

ファイルをダウンロードする
-----------------

アップロードしたblobに対して処理を行う（別フォーマットへの変換など）必要が生じることがあります。`ActiveStorage::Blob#download`を用いてblobのバイナリデータをメモリに読み込めます。

```ruby
binary = user.avatar.download
```

場合によっては、blobをディスク上のファイルとしてダウンロードし、外部プログラム（ウイルススキャナーやメディアコンバーターなど）で処理できるようにしたいことがあります。`ActiveStorage::Blob#open`でblobをディスク上のtempfileにダウンロードできます。

```ruby
message.video.open do |file|
  system '/path/to/virus/scanner', file.path
  # ...
end
```

画像を変換する
----------------

画像のバリエーションを作成するには、`Blob`で`variant`を呼び出します。このメソッドには、画像プロセッサでサポートされる任意の変換方法を渡せます。デフォルトの画像プロセッサは[MiniMagick](https://github.com/minimagick/minimagick)ですが、[Vips](https://www.rubydoc.info/gems/ruby-vips/Vips/Image)も使えます。

バリアントを有効にするには、`image_processing` gemを`Gemfile`に追加します。

``` ruby
gem 'image_processing', '~> 1.2'
```

ブラウザがバリアントURLにヒットすると、Active Storageは元のblobを指定のフォーマットに遅延変換し、新しいサービスのロケーションにリダイレクトします。

```erb
<%= image_tag user.avatar.variant(resize: "100x100") %>
```


画像プロセッサをVipsに切り替えるには、`config/application.rb`に以下を追加します。

```ruby
# 別の画像プロセッサとしてVipsを使う
config.active_storage.variant_processor = :vips
```


ファイルのプレビュー
-----------------------

画像でないファイルの中にはプレビューできるものもあります（画像として表示されます）。たとえば、動画ファイルの最初のフレームを抽出してプレビューできます。Active Storageでは、動画とPDFドキュメントについてすぐ使えるプレビュー機能をサポートしています。

```erb
<ul>
  <% @message.files.each do |file| %>
    <li>
      <%= image_tag file.preview(resize_to_limit: [100, 100]) %>
    </li>
  <% end %>
</ul>
```

WARNING: プレビュー画像の抽出にはサードパーティのアプリケーションが必要です（動画の場合は`ffmpeg`、PDFの場合は` mutool`）。これらのライブラリはRailsでは提供されていません。組み込みのプレビューソフトウェアを使う場合は、自分でインストールしなければなりません。サードパーティのソフトウェアをインストールして使う場合、そのソフトウェアがライセンスにどのように影響をするかを理解しておいてください。

ダイレクトアップロード
--------------------------

Active Storageは、付属のJavaScriptライブラリを用いて、クライアントからクラウドへのダイレクトアップロードをサポートします。

### ダイレクトアップロードのインストール

1. アプリケーションのJavaScriptバンドルに`activestorage.js`を追記します。

    アセットパイプラインを使う場合は以下のようにします。

    ```js
    //= require activestorage
    ```

    npmパッケージを使う場合は以下のようにします。

    ```js
    require("@rails/activestorage").start()
    ```

2. ファイル入力に以下を記述してダイレクトアップロードのURLを指定します。

    ```erb
    <%= form.file_field :attachments, multiple: true, direct_upload: true %>
    ```

3. 以上で完了です。アップロードはフォーム送信時に開始されます。

### ダイレクトアップロードのJavascriptイベント

| イベント名 | イベントの対象 | イベントデータ（`event.detail`） | 説明 |
| --- | --- | --- | --- |
| `direct-uploads:start` | `<form>` | None | ダイレクトアップロードフィールドのファイルを含むフォームが送信された。 |
| `direct-upload:initialize` | `<input>` | `{id, file}` | フォーム送信後のすべてのファイルにディスパッチされる。 |
| `direct-upload:start` | `<input>` | `{id, file}` | 直接アップロードが開始されている。 |
| `direct-upload:before-blob-request` | `<input>` | `{id, file, xhr}` | アプリケーションにダイレクトアップロードメタデータを要求する前。 |
| `direct-upload:before-storage-request` | `<input>` | `{id, file, xhr}` | ファイルを保存するリクエストを出す前。 |
| `direct-upload:progress` | `<input>` | `{id, file, progress}` | ファイルを保存する要求が進行中。 |
| `direct-upload:error` | `<input>` | `{id, file, error}` | エラーが発生した。 このイベントがキャンセルされない限り、`alert`が表示される。 |
| `direct-upload:end` | `<input>` | `{id, file}` | ダイレクトアップロードが終了した。 |
| `direct-uploads:end` | `<form>` | None | すべてのダイレクトアップロードが終了した。 |

### 例

上記のイベントを用いて、アップロードの進行状況をプログレスバー表示できます。

![direct-uploads](https://user-images.githubusercontent.com/5355/28694528-16e69d0c-72f8-11e7-91a7-c0b8cfc90391.gif)

以下は、アップロードされたファイルをフォームに表示するコードです。

```js
// direct_uploads.js

addEventListener("direct-upload:initialize", event => {
  const { target, detail } = event
  const { id, file } = detail
  target.insertAdjacentHTML("beforebegin", `
    <div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
      <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
      <span class="direct-upload__filename">${file.name}</span>
    </div>
  `)
})

addEventListener("direct-upload:start", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.remove("direct-upload--pending")
})

addEventListener("direct-upload:progress", event => {
  const { id, progress } = event.detail
  const progressElement = document.getElementById(`direct-upload-progress-${id}`)
  progressElement.style.width = `${progress}%`
})

addEventListener("direct-upload:error", event => {
  event.preventDefault()
  const { id, error } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--error")
  element.setAttribute("title", error)
})

addEventListener("direct-upload:end", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--complete")
})
```

以下のスタイルを追加します。

```css
/* direct_uploads.css */

.direct-upload {
  display: inline-block;
  position: relative;
  padding: 2px 4px;
  margin: 0 3px 3px 0;
  border: 1px solid rgba(0, 0, 0, 0.3);
  border-radius: 3px;
  font-size: 11px;
  line-height: 13px;
}

.direct-upload--pending {
  opacity: 0.6;
}

.direct-upload__progress {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  opacity: 0.2;
  background: #0076ff;
  transition: width 120ms ease-out, opacity 60ms 60ms ease-in;
  transform: translate3d(0, 0, 0);
}

.direct-upload--complete .direct-upload__progress {
  opacity: 0.4;
}

.direct-upload--error {
  border-color: red;
}

input[type=file][data-direct-upload-url][disabled] {
  display: none;
}
```

### ライブラリやフレームワークとの統合

ダイレクトアップロード機能をJavaScriptフレームワークから利用したい場合や、ドラッグアンドドロップをカスタマイズしたい場合は、`DirectUpload`クラスを利用して行えます。選択したライブラリからファイルを1件受信したら、`DirectUpload`をインスタンス化してそのインスタンスの`create`メソッドを呼び出します。`create`には、アップロード完了時に呼び出すコールバックを1つ渡せます。

```js
import { DirectUpload } from "@rails/activestorage"

const input = document.querySelector('input[type=file]')

// ファイルドロップへのバインド: 親要素のondropか、
// Dropzoneなどのライブラリを使う
const onDrop = (event) => {
  event.preventDefault()
  const files = event.dataTransfer.files;
  Array.from(files).forEach(file => uploadFile(file))
}

// 通常のファイル選択へのバインド
input.addEventListener('change', (event) => {
  Array.from(input.files).forEach(file => uploadFile(file))
  // 選択されたファイルを入力からクリアしておく
  input.value = null
})

const uploadFile = (file) => {
  // フォームではfile_field direct_upload: trueが必要
  // （これでdata-direct-upload-urlを提供する）
  const url = input.dataset.directUploadUrl
  const upload = new DirectUpload(file, url)

  upload.create((error, blob) => {
    if (error) {
      // エラーハンドリングをここに書く
    } else {
      // 名前が似ているhidden inputをblob.signed_idの値とともにフォームに追加する
      // これによりblob idが通常のアップロードフローで転送される
      const hiddenField = document.createElement('input')
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("value", blob.signed_id);
      hiddenField.name = input.name
      document.querySelector('form').appendChild(hiddenField)
    }
  })
}
```

ファイルアップロードの進行状況をトラッキングする必要がある場合は、`DirectUpload`コンストラクタに3番目のパラメータを渡せます。`DirectUpload`はアップロード中にオブジェクトの`directUploadWillStoreFileWithXHR`メソッドを呼び出すので、以後XHRの独自のプログレスハンドラをバインドできるようになります。

```js
import { DirectUpload } from "@rails/activestorage"

class Uploader {
  constructor(file, url) {
    this.upload = new DirectUpload(this.file, this.url, this)
  }

  upload(file) {
    this.upload.create((error, blob) => {
      if (error) {
        // エラーハンドリングをここに書く
      } else {
        // 名前が似ているhidden inputをblob.signed_idの値とともにフォームに追加する
      }
    })
  }

  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress",
      event => this.directUploadDidProgress(event))
  }

  directUploadDidProgress(event) {
    // event.loadedとevent.totalでプログレスバーを更新する
  }
}
```

システムテスト中に保存したファイルを破棄する
-----------------------------------------------

システムテストでは、トランザクションをロールバックすることでテストデータをクリーンアップしますが、`destroy`はオブジェクトに対して呼び出されないため、添付ファイルはそのままでは決してクリーンアップされません。
添付ファイルを破棄したい場合は、`after_teardown`コールバックで行えます。このコールバックを実行すると、テスト中に作成されたすべての接続を確実に完了するので、Active Storageでファイルが見つからないというエラーは表示されなくなります。

```ruby
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  def remove_uploaded_files
    FileUtils.rm_rf("#{Rails.root}/storage_test")
  end

  def after_teardown
    super
    remove_uploaded_files
  end
end
```

システムテストで添付ファイルを含むモデルの削除を検証し、かつActive Jobを使っている場合は、test環境でインラインキューアダプタを使うよう設定します。これにより、purgeジョブが（未来の不確定の時刻ではなく）ただちに実行するようになります。

また、test環境向けに別のサービス定義を使えば、開発中に作成したファイルがテスト中に削除されないようにできます。

``` ruby
# インラインジョブ処理でただちにジョブを実行する
config.active_job.queue_adapter = :inline

# test環境では別のファイルストレージを用いる
config.active_storage.service = :local_test
```

結合テスト中に保存したファイルを破棄する
-----------------------------------------------

システムテストの場合と同様、結合テスト（integration test）の場合もアップロードしたファイルの自動クリーンアップは行われません。アップロードしたファイルをクリーンアップしたい場合は、`after_teardown`コールバックで行えます。このコールバックを実行すると、テスト中に作成されたすべての接続を確実に完了するので、Active Storageでファイルが見つからないというエラーは表示されなくなります。

```ruby
module RemoveUploadedFiles
  def after_teardown
    super
    remove_uploaded_files
  end

  private

  def remove_uploaded_files
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end
end

module ActionDispatch
  class IntegrationTest
    prepend RemoveUploadedFiles
  end
end
```

その他のクラウドサービスのサポートを実装する
---------------------------------

これら以外のクラウドサービスをサポートする必要がある場合は、サービスを実装する必要があります。
各サービスは、ファイルをアップロードしてクラウドにダウンロードするのに必要なメソッドを実装することで、[ActiveStorage::Service](https://github.com/rails/rails/blob/master/activestorage/lib/active_storage/service.rb)を拡張します 。
