
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

Active Storage とは何か?
-----------------------

Active StorageとはAmazon S3、Google Cloud Storage、Microsoft Azure Storageのような
クラウドストレージサービスへのファイルのアップロードとそれらのファイルをActive Recordオブジェクトに添付することを容易にします。
開発およびテスト用のローカルディスクベースのサービスが付属しており、ファイルをバックアップおよび移行用の従属サービスにミラーリングすることができます。

Active Storageを使用すると、アプリケーションは[ImageMagick](https://www.imagemagick.org)で画像のアップロードを変換し、
PDFやビデオなどの非画像アップロードの画像表現を生成し、任意のファイルからメタデータを抽出することができます。

## セットアップ

Active Storageは、アプリケーションのデータベースで `active_storage_blobs`と`active_storage_attachments`という名前の2つのテーブルを使用します。
アプリケーションをRails 5.2にアップグレードした後、`rails active_storage:install`を実行して、これらのテーブルを作成する移行を生成します。 
移行を実行するには`rails db:migrate`を使用してください。

新しいRails 5.2アプリケーションで`rails active_storage:install`を実行する必要はありません。マイグレーションは自動的に生成されます。

Active Storageのサービスを`config/storage.yml`で宣言してください。 アプリケーションが使用するサービスごとに、名前と必要な構成を指定します。 
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
```

`Rails.application.config.active_storage.service`を設定することによって、どのサービスを使うべきかをActive Storageに教えてください。
それぞれの環境では異なるサービスが使用される可能性が高いため、これを環境ごとに行うことをお勧めします。 開発環境の前の例のディスクサービスを使用するには、`config/environments/development.rb`に以下を追加します。

```ruby
# Store files locally.
config.active_storage.service = :local
```

本番環境でAmazon S3を利用するには`config/environments/production.rb`に以下を追加します。

```ruby
# Store files on Amazon S3.
config.active_storage.service = :amazon
```

内蔵のサービスアダプタ(`Disk`や`S3`など)とそれに必要な設定の詳細については、引き続きお読みください。

### Disk Service

`config/storage.yml`にDiskサービスを宣言してください。

``` yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

### Amazon S3 Service

`config/storage.yml`にS3サービスを宣言してください。

``` yaml
amazon:
  service: S3
  access_key_id: ""
  secret_access_key: ""
  region: ""
  bucket: ""
```
また、`Gemfile`にS3クライアントのgemを追加してください。

``` ruby
gem "aws-sdk-s3", require: false
```

### Microsoft Azure Storage Service

`config/storage.yml`にAzure Storageサービスを宣言してください。

``` yaml
azure:
  service: AzureStorage
  path: ""
  storage_account_name: ""
  storage_access_key: ""
  container: ""
```

また、`Gemfile`にMicrosoft Azure Storageクライアントのgemを追加してください。

``` ruby
gem "azure-storage", require: false
```

### Google Cloud Storage Service

`config/storage.yml`にGoogle Cloud Storageサービスを宣言してください。

``` yaml
google:
  service: GCS
  keyfile: {
    type: "service_account",
    project_id: "",
    private_key_id: "",
    private_key: "",
    client_email: "",
    client_id: "",
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://accounts.google.com/o/oauth2/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url: ""
  }
  project: ""
  bucket: ""
```

また、`Gemfile`にGoogle Cloud Storageクライアントのgemを追加してください。

``` ruby
gem "google-cloud-storage", "~> 1.3", require: false
```

### Mirror Service
ミラーサービスを定義することで、複数のサービスを同期させることができます。ファイルがアップロードまたは削除されると、
ミラー化されたすべてのサービスで実行されます。ミラーリングされたサービスを使用して、プロダクション内のサービス間の移行を容易にすることができます。 新しいサービスへのミラーリングを開始したり、既存のファイルを古いサービスから新しいものにコピーしたり、新しいサービスにオールインすることができます。
上記のように使用する各サービスを定義し、ミラー化されたサービスから参照します。

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

NOTE: ファイルはプライマリサービスから提供されます。

ファイルをモデルに添付する
-----------------------

### `has_one_attached`

`has_one_attached`マクロは、レコードとファイルの間に1対1のマッピングを設定します。各レコードには1つのファイルを添付できます。

たとえば、アプリケーションに`User`モデルがあるとします。各userにavatarを持たせたい場合は、以下のように`User`モデルを定義してください。

``` ruby
class User < ApplicationRecord
  has_one_attached :avatar
end
```

avatarと一緒にuserを作成することができます。

``` ruby
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
Current.user.avatar.attach(params[:avatar])
```

`avatar.attached?`で特定のuserがavatarを持っているかどうかを判断します。

```ruby
Current.user.avatar.attached?
```

### `has_many_attached`

`has_many_attached`マクロは、レコードとファイルの間に1対多の関係を設定します。各レコードには、多数のファイルを添付することができます。

たとえば、アプリケーションに`Message`モデルがあるとします。それぞれのメッセージに多くのイメージを含めるには、次のように`Message`モデルを定義します.

```ruby
class Message < ApplicationRecord
  has_many_attached :images
end
```

imagesと一緒にmessageを作成することができます。

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

`images.attach`を呼び出して、新しいimageを既存のmessageに追加します。

```ruby
@message.images.attach(params[:images])
```

`image.attached?`で特定のmessageがimageを持っているかどうかを判断します。

```ruby
@message.images.attached?
```

モデルに添付されたファイルを削除する
-----------------------------

モデルから添付ファイルを削除するには、添付ファイルに対して `purge`を呼び出します。
Active Jobを使用するようにアプリケーションが設定されている場合は、バックグラウンドで削除を実行できます。消去すると、BLOBとファイルがストレージサービスから削除されます。

```ruby
# avatarと実際のリソースファイルを同期的に破棄します。
user.avatar.purge

# Active Jobを介して、関連付けられているモデルと実際のリソースファイルを非同期で破棄します。
user.avatar.purge_later
```

添付ファイルへのリンク
-------------------

アプリケーションを指すblobの永続URLを生成します。アクセス時には、実際のサービスエンドポイントへのリダイレクトが返されます。
このインダイレクションはパブリックURLを実際のURLと切り離し、たとえば、高可用性のために異なるサービスの添付ファイルをミラーリングすることを可能にします。
リダイレクトのHTTPの有効期限は5分です。

```ruby
url_for(user.avatar)
```

ダウンロードリンクを作成するには、`rails_blob_ {path | url}`ヘルパーを使用してください。このヘルパーを使用すると、処理を設定できます。

```ruby
rails_blob_path(user.avatar, disposition: "attachment")
```

画像を変換する
----------------

画像のバリエーションを作成するには、Blobで`variant`を呼び出します。
[MiniMagick](https://github.com/minimagick/minimagick) でサポートされている変換をメソッドに渡すことができます。

バリアントを有効にするには、`mini_magick`を`Gemfile`に追加してください：

``` ruby
gem 'mini_magick'
```

ブラウザがバリアントURLにヒットすると、Active Storageは元のBLOBを指定したフォーマットに遅延変換し、新しいサービスロケーションにリダイレクトします。

```erb
<%= image_tag user.avatar.variant(resize: "100x100") %>
```


非画像ファイルのプレビュー
-----------------------

非画像ファイルの一部はプレビューすることができます。つまり、画像として表示することができます。 
たとえば、最初のフレームを抽出してビデオファイルをプレビューすることができます。アウトオブボックスで、Active StorageはビデオとPDFドキュメントのプレビューをサポートしています。

```erb
<ul>
  <% @message.files.each do |file| %>
    <li>
      <%= image_tag file.preview(resize: "100x100>") %>
    </li>
  <% end %>
</ul>
```

WARNING: プレビューを抽出するにはサードパーティのアプリケーション、ビデオの場合は`ffmpeg`、PDFの場合は` mutool`が必要です。
これらのライブラリはRailsでは提供されていません。組み込みのプレビューアを使用するには、それらを自分でインストールする必要があります。
サードパーティのソフトウェアをインストールして使用する前に、ライセンスの影響を理解していることを確認してください。


サービスに直接アップロードする
--------------------------

Active Storageは、付属のJavaScriptライブラリを使用して、クライアントからクラウドへの直接アップロードをサポートします。

### ダイレクトアップロードのインストール

1. アプリケーションのJavaScriptバンドルに`activestorage.js`を含めます。

    アセットパイプラインを使います。
    
    ```js
    //= require activestorage

    ```
    
    npmパッケージを使います。
    
    ```js
    import * as ActiveStorage from "activestorage"
    ActiveStorage.start()
    ```
    
2. ダイレクトアップロードURLでファイル入力に注釈を付けます。

     ```ruby
     <%= form.file_field :attachments, multiple: true, direct_upload: true %>
     ```
     
3. それだけです！ アップロードはフォーム提出時に開始されます。

### ダイレクトアップロードのJavascriptイベント

| Event name | Event target | Event data (`event.detail`) | Description |
| --- | --- | --- | --- |
| `direct-uploads:start` | `<form>` | None | ダイレクトアップロードフィールドのファイルを含むフォームが送信された。 |
| `direct-upload:initialize` | `<input>` | `{id, file}` | フォーム提出後のすべてのファイルにディスパッチされる。 |
| `direct-upload:start` | `<input>` | `{id, file}` | 直接アップロードが開始されている。 |
| `direct-upload:before-blob-request` | `<input>` | `{id, file, xhr}` | アプリケーションにダイレクトアップロードメタデータを要求する前。 |
| `direct-upload:before-storage-request` | `<input>` | `{id, file, xhr}` | ファイルを保存するリクエストを出す前。 |
| `direct-upload:progress` | `<input>` | `{id, file, progress}` | ファイルを保存する要求が進行中。 |
| `direct-upload:error` | `<input>` | `{id, file, error}` | エラーが発生した。 このイベントがキャンセルされない限り、`alert`が表示される。 |
| `direct-upload:end` | `<input>` | `{id, file}` | ダイレクトアップロードが終了した。 |
| `direct-uploads:end` | `<form>` | None | すべてのダイレクトアップロードが終了した。 |

### 例


これらのイベントを使用して、アップロードの進行状況を表示できます。

![direct-uploads](https://user-images.githubusercontent.com/5355/28694528-16e69d0c-72f8-11e7-91a7-c0b8cfc90391.gif)

アップロードされたファイルをフォームに表示するには


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

スタイルを追加

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

システムテスト中にストアドファイルストアをクリーンアップする
-----------------------------------------------

システムテストでは、トランザクションをロールバックしてテストデータをクリーンアップします。
destroyはオブジェクトに対して呼び出されないため、添付ファイルは決してクリーンアップされません。
ファイルを消去したい場合は、`after_teardown`コールバックで行うことができます。
ここでは、テスト中に作成されたすべての接続が確実に行われ、アクティブストレージからファイルを見つけることができないというエラーは表示されません。

``` ruby
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

システムが添付ファイルを含むモデルの削除を検証し、アクティブジョブを使用している場合は、インラインキューアダプタを使用するようにテスト環境を設定して、未知の時間ではなく即時にパージジョブを実行します。

また、テスト環境で別のサービス定義を使用して、開発中に作成したファイルをテストで削除しないようにすることもできます。

``` ruby
# Use inline job processing to make things happen immediately
config.active_job.queue_adapter = :inline

# Separate file storage in the test environment
config.active_storage.service = :local_test
```

追加のクラウドサービスをサポート
---------------------------------

これら以外のクラウドサービスをサポートする必要がある場合は、サービスを実装する必要があります。
各サービスは、ファイルをアップロードしてクラウドにダウンロードするのに必要なメソッドを実装することで、[ActiveStorage::Service](https://github.com/rails/rails/blob/master/activestorage/lib/active_storage/service.rb)を拡張します 。
