Active Record と暗号化
========================

このガイドでは、Active Recordを用いてデータベースの情報を暗号化する方法について説明します。

このガイドの内容:

* Active Recordでデータベース暗号化をセットアップする方法
* 暗号化されていないデータを移行する方法
* 複数の暗号化スキームを共存させる方法
* APIの利用法
* このライブラリの利用法および拡張方法

--------------------------------------------------------------------------------

Active Recordはアプリケーションレベルの暗号化をサポートします。これは、暗号化する属性を宣言し、必要に応じて暗号化と復号をシームレスに行うしくみです。暗号化の層は、データベース層とアプリケーション層の間に置かれます。アプリケーションがアクセスするのは暗号化されていないデータですが、データベースには暗号化されたデータが保存されます。

## データをアプリケーションレベルで暗号化する理由

Active Record暗号化は、アプリケーション内の機密情報を保護するために存在します。典型的な機密情報の例は、個人を識別可能な情報です。既にデータベースを暗号化していてもアプリケーションレベルで暗号化したくなる理由は何でしょうか？

機密性の高い属性を暗号化することでただちに得られる実用的なメリットの１つは、セキュリティ層が追加されることです。たとえば、攻撃者がデータベースやデータベースのスナップショット、アプリケーションログにアクセスできたとしても、暗号化された情報は読めません。また、暗号化することで、開発者がうっかりユーザーの機密情報をアプリケーションログに出力してしまうことを防止できます。

しかしもっと重要なのは、Active Record暗号化を用いることで、アプリケーション内にある機密情報の構成要素をコードレベルで定義できることです。Active Record暗号化を利用すれば、アプリケーション内のデータアクセスやデータを実際に消費するサービスを細かく制御できるようになります。暗号化されたデータを保護する監査機能付きのRailsコンソールや、[コントローラのparamsを自動フィルタする](#)組み込みシステムなども検討できます。

## 基本的な利用法

### セットアップ

最初に、[Rails credentials](/security.html#独自のcredential)にキーをいくつか追加しておく必要があります。以下のように`bin/rails db:encryption:init`を実行して、ランダムなキーセットを生成します。

```bash
$ bin/rails db:encryption:init
Add this entry to the credentials of the target environment:

active_record_encryption:
  primary_key: EGY8WhulUOXixybod7ZWwMIL68R9o5kC
  deterministic_key: aPA5XyALhf75NNnMzaspW7akTfZp0lPY
  key_derivation_salt: xEY0dt6TZcAMg52K7O84wYzkjvbA62Hz
```

NOTE: 生成される値は32バイト長です。これらを自分で生成する場合は、最低でも主キー用に12バイト（これは[AES](https://ja.wikipedia.org/wiki/Advanced_Encryption_Standard)の32バイトのキー導出に用いられます）、ソルト（salt）用に20バイトが必要です。

### 暗号化属性の宣言

暗号化可能な属性はモデルレベルで定義します。これらの属性は、同名のカラムを用いる通常のActive Record属性です。

```ruby
class Article < ApplicationRecord
  encrypts :title
end
````

このライブラリは、属性をデータベースに保存する前に透過的に暗号化し、取得時に復号するようになります。

```ruby
article = Article.create title: "すべて暗号化せよ！"
article.title # => "すべて暗号化せよ！"
```

しかし背後で実行されるSQLは以下のようになります。

```sql
INSERT INTO `articles` (`title`) VALUES ('{\"p\":\"n7J0/ol+a7DRMeaE\",\"h\":{\"iv\":\"DXZMDWUKfp3bg/Yu\",\"at\":\"X1/YjMHbHD4talgF9dt61A==\"}}')
```

値のほかにBase64エンコーディングとメタデータも保存されるので、暗号化を利用する場合はカラムの容量を余分に必要とします。組み込みのエンベロープ暗号化キープロバイダが使われる場合、最悪で250バイトほど余分に必要になると見積もれます。これは中大規模の`text`カラムでは無視できる量ですが、255バイトの`string`カラムではこれに応じて上限を増やしておく必要があります（推奨は510バイト）。

### 決定論的暗号化と非決定論的暗号化について

ActiveRecord暗号化では、デフォルトで非決定論的な（non-deterministic）暗号化を用います。ここで言う非決定論的とは、同じコンテンツを同じパスワードで暗号化しても、暗号化のたびに異なる暗号文が生成されるという意味です。非決定論的な暗号化手法によって、暗号解析の難易度を高めてデータベースへのクエリを不可能にすることで、セキュリティを向上させます。

`deterministic:`オプションを指定することで、初期化ベクトルを[決定論的な手法](https://ja.wikipedia.org/wiki/%E6%B1%BA%E5%AE%9A%E7%9A%84%E3%82%A2%E3%83%AB%E3%82%B4%E3%83%AA%E3%82%BA%E3%83%A0)で生成できるようになり、暗号化データへのクエリを効率よく行えるようになります。

```ruby
class Author < ApplicationRecord
  encrypts :email, deterministic: true
end

Author.find_by_email("some@email.com") # You can query the model normally
```

データをクエリする必要が生じない限り、非決定論的な手法が推奨されます。

NOTE: 非決定論的モードのActive Recordでは、256ビットキーとランダムな初期化ベクトルを用いる[AES](https://ja.wikipedia.org/wiki/Advanced_Encryption_Standard)-[GCM](https://ja.wikipedia.org/wiki/Galois/Counter_Mode)が使われます。決定論的モードも同様にAES-GCMを用いますが、その初期化ベクトルは、キーと暗号化対象コンテンツのHMAC-SHA-256ダイジェストとして生成されます。

NOTE: `deterministic_key`を省略すると、決定論的暗号化を無効にできます。

## 機能

### Action Text

Action Textの属性宣言に`encrypted: true`を渡すことで、属性を暗号化できます。

```ruby
class Message < ApplicationRecord
  has_rich_text :content, encrypted: true
end
```

NOTE: Action Text属性に個別の暗号化オプションを渡すことについてはまだサポートされていません。グローバルな暗号化オプションに設定されている非決定的暗号化が用いられます。

### フィクスチャ

config/environmentsの`test.rb`に以下のオプションを追加すると、Railsのフィクスチャが自動的に暗号化されるようになります。

```ruby
config.active_record.encryption.encrypt_fixtures = true
```

この機能を有効にすると、暗号化済み属性はモデルで定義されている暗号化設定に沿って暗号化されるようになります。

#### Action Textのフィクスチャ

Action Textのフィクスチャを暗号化するには、`fixtures/action_text/encrypted_rich_texts.yml`に置く必要があります。

### サポートされる型

`active_record.encryption`は、暗号化の前に背後の型を用いて値をシリアライズしますが、**型は文字列としてシリアライズ可能でなければなりません**。`serialized`などの構造化された型はそのまま利用可能です。

カスタム型をサポートする必要がある場合は、[シリアライズ化属性](https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html)の利用が推奨されます。シリアライズ化属性の宣言は、以下のように暗号化宣言より**上の行に**置いてください。

```ruby
# 正しい
class Article < ApplicationRecord
  serialize :title, Title
  encrypts :title
end

# 誤り
class Article < ApplicationRecord
  encrypts :title
  serialize :title, Title
end
```

### 大文字小文字を区別しない場合

決定論的に暗号化されたデータへのクエリで大文字小文字を区別しないようにする必要が生じることがあります。この場合、大文字小文字を区別しないクエリをやりやすくするには2とおりの方法が考えられます。

１つは、以下のように暗号化属性を宣言するときに`downcase:`オプションを指定することでコンテンツ暗号化の前に小文字に揃えておくことです。

```ruby
class Person
  encrypts :email_address, deterministic: true, downcase: true
end
```

`downcase:`オプションを指定する場合は、元の大文字小文字の区別が失われます。大文字小文字の区別を失わずに、クエリでのみ大文字小文字を区別しないようにしたいこともあるでしょう。そのような場合は`:ignore_case`オプションを指定できます。このオプションを利用する場合は、大文字小文字の区別を維持したコンテンツを保存するための`original_<カラム名>`というカラムを追加する必要があります。

```ruby
class Label
  encrypts :name, deterministic: true, ignore_case: true # 大文字小文字を維持したコンテンツは`original_name`カラムに保存される
end
```

### 暗号化されていないデータのサポート

暗号化されていないデータを移行しやすくするため、このライブラリには`config.active_record.encryption.support_unencrypted_data`オプションも用意されています。このオプションを`true`にすると以下のようになります。

* 実際には暗号化されていない暗号化済み属性を読み出してもエラーをraiseしなくなる
* 決定論的に暗号化された属性を含むクエリに「クリアテキスト」バージョンの属性も含まれるようになり、暗号化の有無にかかわらずコンテンツを検索できるようになる。これを有効にするには`config.active_record.encryption.extend_queries = true`を設定する必要があります。

このオプションは、非暗号化データと暗号化済みデータの共存が避けられないので、**あくまで過渡期の利用が目的です**。デフォルトでは上記2つのオプションはどちらも`false`に設定されます。そしてこの設定は、あらゆるアプリケーションで推奨される目標でもあります。

### 以前の暗号化スキームのサポート

属性の暗号化プロパティを変更すれば既存のデータが破損します。たとえば、決定論的な属性を非決定的に変える場合、単にモデル内の宣言を変更すると、暗号化手法が異なるため、既存の暗号文を読み取れなくなってしまいます。

このような状況をサポートするため、以前の暗号化スキームを以下の2つのシナリオで利用される形で宣言できます。

* ActiveRecord暗号化は、暗号化済みデータを読み取るときに現在の暗号化スキームが効かない場合は、以前の暗号化スキームで読み取りを試みる。
* 決定論的に暗号化されたデータへのクエリでは、以前の暗号化スキームを用いた暗号化テキストも追加して、複数の暗号化スキームで暗号化されたデータのクエリをシームレスに行えるようにする。これを有効にするには、`config.active_record.encryption.extend_queries = true`を設定しておかなければなりません。

以前の暗号化スキームは、以下のいずれかの方法で設定可能です。

* グローバルに設定
* 属性ごとに設定

#### 以前の暗号化スキームをグローバルに設定する

以前の暗号化スキームは、`config/application.rb`で以下のように`previous`設定を用いてプロパティのリストとして追加可能です。

```ruby
config.active_record.encryption.previous = [ { key_provider: MyOldKeyProvider.new } ]
```

#### 以前の暗号化スキームを属性ごとに設定する

属性を宣言するときに以下のように`:previous`で指定します。

```ruby
class Article
  encrypts :title, deterministic: true, previous: { deterministic: false }
end
```

#### 暗号化スキームと決定論的な属性

以前の暗号化スキームを追加する場合、以下のように非決定論的/決定論的によって違いが生じます。

* **非決定論的暗号化**: 新しい情報は、常に**最新の**（すなわち現在の）暗号化スキームによって暗号化される
* **決定論的暗号化**: 新しい情報は、常にデフォルトで**最も古い**暗号化スキームによって暗号化される

決定的暗号化をあえて利用する場合は、暗号文を変えたくないのが普通です。この振る舞いは`deterministic: { fixed: false }`で変更可能です。これにより、新しいデータを暗号化するときに**最新の**暗号化スキームが用いられるようになります。

### 一意性制約

NOTE: 一意性制約は、決定論的に暗号化されたデータでしか利用できません。

#### 一意性バリデーション

一意性バリデーションは、`config.active_record.encryption.extend_queries = true`によって拡張クエリが有効になっている限り、通常どおりサポートされます。

```ruby
class Person
  validates :email_address, uniqueness: true
  encrypts :email_address, deterministic: true, downcase: true
end
```

これは、暗号化済みデータと非暗号化データを組み合わせた場合や、以前の暗号化スキームを設定した場合にも利用できます。

NOTE: 大文字小文字を区別しないようにしたい場合は、`encrypts`宣言で `downcase:`または`ignore_case:`を必ず指定すること。また、バリデーション内では`case_sensitive:`は機能しません。

#### 一意インデックス

決定論的に暗号化されたカラムで一意インデックスをサポートするには、その暗号文が絶対に変更されないようにしておく必要があります。

決定論的な属性ではそのために、複数の暗号化スキームが設定されている場合はデフォルトでは常に最も古い暗号化スキームを利用するようになっています。そうでないと、属性の暗号化プロパティの変更を別の方法で防止しない限り、一意インデックスが効かなくなってしまいます。

```ruby
class Person
  encrypts :email_address, deterministic: true
end
```

### 暗号化カラムをparamsでフィルタする

デフォルトでは、暗号化済みカラムは[Railsのログで自動的にフィルタされます](https://railsguides.jp/action_controller_overview.html#%E3%83%AD%E3%82%B0%E3%82%92%E3%83%95%E3%82%A3%E3%83%AB%E3%82%BF%E3%81%99%E3%82%8B)。`config/application.rb`に以下を追加することで、この振る舞いを無効にできます。

このフィルタパラメータを生成すると、モデル名がプレフィックスとして使われます。例: `Person#name`のフィルタパラメータは`person.name`になる。

```ruby
config.active_record.encryption.add_to_filter_parameters = false
```

特定のカラムだけを自動フィルタの対象から外したい場合は、外したいカラムを`config.active_record.encryption.excluded_from_filter_parameters`に追加します。

### エンコード

このライブラリは、非決定論的に暗号化された文字列値のエンコードを維持します。

エンコーディングは、暗号化済みペイロードとともに保存されるので、デフォルトでは強制的にUTF-8エンコーディングが使われます。すなわち、値が同じでもエンコードが異なれば暗号文も異なるものになります。これは、クエリや一意性制約を機能させるうえでは避けたいものなので、ライブラリが代わりに自動的に変換します。

決定論的暗号化でデフォルトのエンコードを指定するには、以下の設定を使います。

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = Encoding::US_ASCII
```

この振る舞いを無効にして常にエンコードを維持するには、以下の設定を使います。

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = nil
```

## キーの管理

キープロバイダは、キー管理戦略を実装します。キープロバイダはグローバルに設定することも、属性ごとに指定することも可能です。

### 組み込みのキープロバイダ

#### `DerivedSecretKeyProvider`

`DerivedSecretKeyProvider`は、指定のパスワードからPBKDF2を用いて導出されるキーを提供するキープロバイダです。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::DerivedSecretKeyProvider.new(["some passwords", "to derive keys from. ", "These should be in", "credentials"])
```

NOTE: `active_record.encryption`はデフォルトで、`active_record.encryption.primary_key`で定義されているキーを用いる`DerivedSecretKeyProvider`を設定します。

#### `EnvelopeEncryptionKeyProvider`

`EnvelopeEncryptionKeyProvider`は、シンプルな[エンベロープ暗号化](https://docs.aws.amazon.com/ja_jp/kms/latest/developerguide/concepts.html#enveloping)戦略を実装します。

- データ暗号化操作のたびにランダムなキーを生成する
- データ自身のほかにデータキーも保存し、`active_record.encryption.primary_key` credentialで定義されている主キーを用いて暗号化される

以下を`config/application.rb`に追加することで、Active Recordでこのキープロバイダを使うよう設定できます。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
```

他の組み込みのキープロバイダと同様に、`active_record.encryption.primary_key`に主キーのリストを渡すことでキーローテーションスキームを実装できます。

### カスタムのキープロバイダ

より高度なキー管理スキームを利用したい場合は、イニシャライザで以下のようにカスタムのキープロバイダを設定できます。

```ruby
ActiveRecord::Encryption.key_provider = MyKeyProvider.new
```

キープロバイダは以下のインターフェイスを実装しなければなりません。

```ruby
class MyKeyProvider
  def encryption_key
  end

  def decryption_keys(encrypted_message)
  end
end
```

２つのメソッドは、いずれも`ActiveRecord::Encryption::Key`オブジェクトを返します。

- `encryption_key`: コンテンツの暗号化に使われたキーを返す
- `decryption keys`: 指定のメッセージを復号するのに使う可能性のあるキーのリストを返す

１つのキーには、メッセージと一緒に暗号化なしで保存される任意のタグを含められます。`ActiveRecord::Encryption::Message#headers`を使って、復号時にこれらの値を調べられます。

### キープロバイダをモデルごとに指定する

`key_provider:`オプションで、キープロバイダをクラスごとに設定できます。

```ruby
class Article < ApplicationRecord
  encrypts :summary, key_provider: ArticleKeyProvider.new
end
```

### キーをモデルごとに指定する

`key:`オプションで、指定のキーをクラスごとに設定できます。

```ruby
class Article < ApplicationRecord
  encrypts :summary, key: "some secret key for article summaries"
end
```

Active Recordは、データの暗号化や復号に使うキーをこのキーで導出します。

### キーのローテーション

`active_record.encryption`では、キーローテーションスキームの実装をサポートするキーのリストを利用できます。

- 新しいコンテンツの暗号化には**最下行のキー**が用いられる
- 復号では、成功するまですべてのキーを試行する

```yml
active_record_encryption:
  primary_key:
    - a1cc4d7b9f420e40a337b9e68c5ecec6 # 以前のキーは引き続き既存コンテンツを復号する
    - bc17e7b413fd4720716a7633027f8cc4 # 新しいコンテンツを暗号化するアクティブなキー
  key_derivation_salt: a3226b97b3b2f8372d1fc6d497a0c0d3
```

これにより、「新しいキーの追加」「コンテンツの再暗号化」「古いキーの削除」を行ってキーのリストを短く保てるようになります。

NOTE: キーローテーションは、決定論的暗号化では現在サポートされていません。

NOTE: Active Record暗号化は、キーローテーション処理の自動管理機能をまだ提供していません（実装は可能ですが未実装の状態です）。

### キー参照の保存

以下のように`active_record.encryption.store_key_references`を設定することで、`active_record.encryption`が暗号化済みメッセージそのものに暗号化キーへの参照を保存するようになります。

```ruby
config.active_record.encryption.store_key_references = true
```

この設定を有効にすると、システムがキーのリストを探索せずにキーを直接見つけられるようになり、復号のパフォーマンスが向上します。その代わり、暗号化データのサイズがやや肥大化します。

## API

### 基本的なAPI

Active Record暗号化は宣言的に利用することを念頭に置いていますが、より高度なシナリオで使えるAPIも提供しています。

#### 暗号化と復号

```ruby
article.encrypt # encrypt or re-encrypt all the encryptable attributes
article.decrypt # decrypt all the encryptable attributes
```

#### 暗号文の読み出し

```ruby
article.ciphertext_for(:title)
```

#### 属性が暗号化されているかどうかのチェック

```ruby
article.encrypted_attribute?(:title)
```

## 設定

### 設定オプション

Active Record暗号化のオプションは、`config/application.rb`で行うことも（ほとんどの場合このファイルに書きます）、`config/environments/<環境名>.rb`で特定の環境設定ファイルに設定することも可能です。

WARNING: キーの保存場所には、Rails組み込みのcredentialサポートを用いることが推奨されます。設定プロパティを用いて手動で設定したい場合は、キーを誤ってコードと一緒にリポジトリにコミットしないようご注意ください（環境変数などを用いること）。

#### `config.active_record.encryption.support_unencrypted_data`

`true`にすると、非暗号化データを通常通り読み出せるようになります。
`false`にすると、非暗号化データを読み出したときにエラーになります。デフォルトは`false`です。

#### `config.active_record.encryption.extend_queries`

`true`に設定すると、決定論的に暗号化された属性を参照するクエリが、必要に応じて追加の値を含むように変更されます。追加される値は暗号化されない（`config.active_record.encryption.support_unencrypted_data`が`true`の場合）か、または以前の暗号化スキームで暗号化されます（`previous:`で指定された場合）。デフォルトは`false`です。

#### `config.active_record.encryption.encrypt_fixtures`

`true`の場合、フィクスチャ内の暗号化可能な属性が読み込み時に自動的に暗号化されます。デフォルトは`false`です。

#### `config.active_record.encryption.store_key_references`

`true`にすると、暗号化キーへの参照が暗号化済みメッセージのヘッダ内に保存され、キーが複数使われている場合の暗号化が高速になります。デフォルトは`false`です。

#### `config.active_record.encryption.add_to_filter_parameters`

`true`にすると、暗号化された属性名が自動的に[`config.filter_parameters`][]に追加され、ログに出力されなくなります。デフォルトは`true`です。

[`config.filter_parameters`]: configuring.html#config-filter-parameters

#### `config.active_record.encryption.excluded_from_filter_parameters`

フィルタから除外するparamsのリストを設定します（`add_to_filter_parameters`が`true`の場合）。デフォルトは`[]`です。

#### `config.active_record.encryption.validate_column_size`

カラムのサイズに応じたバリデーションを追加します。巨大な値を圧縮率の高いペイロードを用いて保存しないために推奨されている設定です。デフォルトは`true`です。

#### `config.active_record.encryption.primary_key`

rootデータ暗号化キーの導出に用いるキーまたはキーのリストを設定します。キーの利用法はキープロバイダの設定によって異なります。`active_record_encryption.primary_key` credentialで設定するのが望ましい方法です。

#### `config.active_record.encryption.deterministic_key`

決定論的暗号化で用いるキーまたはキーのリストを設定します。`active_record_encryption.deterministic_key` credentialで設定するのが望ましい方法です。

#### `config.active_record.encryption.key_derivation_salt`

キー導出時に用いるソルト（salt）を設定します。`active_record_encryption.key_derivation_salt` credentialで設定するのが望ましい方法です。

#### `config.active_record.encryption.forced_encoding_for_deterministic_encryption`

決定論的に暗号化された属性のデフォルトエンコーディングを設定します。このオプションを`nil`にするとエンコードの強制を無効化できます。デフォルトは`Encoding::UTF_8`です。

### 暗号化コンテキスト

暗号化コンテキストとは、ある時点に使われる暗号化コンポーネントを定義するものです。デフォルトではグローバルな設定に基づいた暗号化コンテキストが使われますが、特定の属性で用いるカスタムコンテキストや、コードの特定のブロックを実行するときのカスタムコンテキストを定義可能です。

NOTE: 暗号化コンテキストの設定メカニズムは柔軟ですが高度です。ほとんどのユーザーは気にする必要はないはずです。

暗号化コンテキストに登場する主なコンポーネントは以下のとおりです。

* `encryptor`: データの暗号化や復号に用いる内部APIを公開します。暗号化メッセージの作成とシリアライズのために`key_provider`とやりとりします。暗号化や復号そのものは`cypher`で行われ、シリアライズは`message_serializer`で行われます。
* `cipher`: 暗号化アルゴリズムそのもの（AES 256 GCM）
* `key_provider`: 暗号化と復号のキーを提供する
* `message_serializer`: 暗号化されたペイロードをシリアライズおよびデシリアライズする（`Message`）

NOTE: 独自の`message_serializer`を構築する場合は、任意のオブジェクトをデシリアライズすることのない安全なメカニズムを採用することが重要です。一般にサポートされているシナリオは、既存の非暗号化データを暗号化するときです。任意のオブジェクトがデシリアライズ可能だと、攻撃者がこれを利用して、暗号化が行われる前に改ざんしたペイロードを入力してリモートコード実行（RCE）を実行する可能性があります。つまり、独自のシリアライザでは `Marshal`、`YAML.load`（`YAML.safe_load`にすること）、`JSON.load`（`JSON.parse`にすること）の利用を避けるべきです。

#### グローバルな暗号化コンテキスト

グローバルな暗号化コンテキストはデフォルトで利用されます。他の設定プロパティと同様、`config/application.rb`や環境ごとの設定ファイルで以下のように設定可能です。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
config.active_record.encryption.encryptor = MyEncryptor.new
```

#### 属性ごとの暗号化コンテキスト

以下のように属性の宣言で暗号化コンテキストを渡すことで、暗号化コンテキストを上書きできます。

```ruby
class Attribute
  encrypts :title, encryptor: MyAttributeEncryptor.new
end
```

#### 特定のコードブロックを実行中の暗号化コンテキスト

`ActiveRecord::Encryption.with_encryption_context`を使うと、指定のコードブロックで暗号化コンテキストを設定できます。

```ruby
ActiveRecord::Encryption.with_encryption_context(encryptor: ActiveRecord::Encryption::NullEncryptor.new) do
  ...
end
```

#### Rails組み込みの暗号化コンテキスト

##### 暗号化を無効にする

以下を用いると、暗号化を無効にしてコードを実行できます。

```ruby
ActiveRecord::Encryption.without_encryption do
   ...
end
```

この場合、暗号化テキストを読み出すと暗号文のまま返され、`save`したコンテンツは暗号化なしで保存されることになります。

##### 暗号化済みデータを保護する

以下を用いると、暗号化を無効にすると同時に、暗号化済みコンテンツが上書きされないようにコードを実行できます。

```ruby
ActiveRecord::Encryption.protecting_encrypted_data do
   ...
end
```

これは、暗号化データを保護しつつ、任意のコードを実行したい場合に便利です（Railsコンソールなど）。
