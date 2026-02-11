Active Record と暗号化
========================

このガイドでは、Active Recordを用いてデータベース内のデータを暗号化する方法について説明します。

このガイドの内容:

* Active Recordでデータベース暗号化をセットアップする方法
* 暗号化されていないデータを移行する方法
* 複数の暗号化スキームを共存させる方法
* 暗号化コンテキストとキープロバイダに関する高度な概念

--------------------------------------------------------------------------------

Active Record暗号化は、ユーザー個人を識別可能な情報（PII: personally identifiable information）のようなアプリケーション内の機密情報を保護するために存在します。Active Recordでは、どの属性を暗号化すべきかを宣言することで、アプリケーションレベルでの暗号化をサポートし、データの保存や取得時に属性を透過的に暗号化および復号できるようにします。

## データをアプリケーションレベルで暗号化する理由

特定の属性をアプリケーションレベルで暗号化することで、セキュリティ層を追加できます。たとえば、誰かがアプリケーションのログやデータベースバックアップにアクセスした場合でも、暗号化されたデータは読み取れません。また、アプリケーションコンソールやログで機密情報が誤って露出するのを防ぐのにも役立ちます。

最も重要なのは、この暗号化機能を用いることで、コード内でどの部分が機密情報であるかを明示的に定義できることです。これにより、アプリケーション全体および接続されるサービスにわたって精密なアクセス制御が可能になります。たとえば、[console1984][]ツールを使えば、Railsコンソール内で復号データへのアクセスを制限できるので、開発者が安心して作業できます。また、暗号化されたフィールドに対して自動的に[コントローラのparamsをログからフィルタで除外する](#暗号化属性で命名されたparamsをログでフィルタする)ことも可能です。

[console1984]: https://github.com/basecamp/console1984

## セットアップ

Active Record暗号化を開始するには、まずキーを生成してから、暗号化したい属性をモデルで宣言する必要があります。

### 暗号化キーを生成する

`bin/rails db:encryption:init`を実行して、ランダムなキーセットを生成します。

```bash
$ bin/rails db:encryption:init
Add this entry to the credentials of the target environment:

active_record_encryption:
  primary_key: YehXdfzxVKpoLvKseJMJIEGs2JxerkB8
  deterministic_key: uhtk2DYS80OweAPnMLtrV2FhYIXaceAy
  key_derivation_salt: g7Q66StqUQDQk9SJ81sWbYZXgiRogBwS
```

これらの値は、既存の[Rails credentials](/security.html#独自のcredential)ファイルを`bin/rails credentials:edit`コマンドで開き、生成した値をコピーして貼り付けることで保存できます。

また、環境変数など他のソースを用いてこれらの値を設定することも可能です。

```ruby
# config/application.rb
config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
```

WARNING: キーを保存するときは、Rails組み込みのcredentialサポートを用いることが推奨されます。設定プロパティを用いて手動で設定したい場合は、キーを誤ってコードと一緒にリポジトリにコミットしないよう十分ご注意ください（環境変数などを用いること）。

NOTE: 生成される値の長さは32バイトです。これらを自分で生成する場合、推奨される最小限のキー長は、主キーが12バイト、[ソルト（salt）][salt]が20バイトです。

キーの生成と保存が完了したら、モデルで暗号化する属性を宣言してActive Record暗号化の利用を開始できるようになります。

[salt]: https://ja.wikipedia.org/wiki/ソルト_(暗号)

### 暗号化属性の宣言

[`encrypts`][]メソッドを用いて、暗号化したい属性をモデルレベルで定義します。これらの属性は、同名のカラムを用いる通常のActive Record属性です。

```ruby
class Article < ApplicationRecord
  encrypts :title
end
```

このライブラリは、属性をデータベースに保存する前に透過的に暗号化し、取得時に復号するようになります。

`encrypts`で指定した属性は、以下のようにActive Record暗号化機能によって透過的に暗号化されてからデータベースに保存され、取得時に復号されます。

```ruby
article = Article.create title: "すべて暗号化せよ！"
article.title # => "すべて暗号化せよ！"
```

しかし背後で実行されるSQLをRailsコンソールで観察すると、以下のようになります。

```sql
INSERT INTO "articles" ("title", "created_at", "updated_at")
VALUES ('{"p":"oq+RFYW8CucALxnJ6ccx","h":{"iv":"3nrJAIYcN1+YcGMQ","at":"JBsw7uB90yAyWbQ8E3krjg=="}}', ...) RETURNING "id"
```

ここで`INSERT`される値は、`title`属性の暗号化済み値を含むJSONオブジェクトです。具体的には、このJSONオブジェクトは2つのキーを保存します。`p`はペイロード、`h`はヘッダです。
圧縮されBase64エンコードされた暗号文が、ペイロードとして保存されます。`h`キーは、値を復号するために必要なメタデータを保存します。`iv`値は初期化ベクトル（initialization vector）で、`at`は認証タグ（authentication tag）です（暗号文が改ざんされていないことを保証するのに使われます）。

`Article`モデルをRailsコンソールで調べると、暗号化済み`title`属性が`"[FILTERED]"`のようにフィルタで除外されていることもわかります。

```irb
my-app(dev)> Article.first
  Article Load (0.1ms)  SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT ?  [["LIMIT", 1]]
=> #<Article:0x00007f83fd9533b8
    id: 1,
    title: "[FILTERED]",
    created_at: Fri, 12 Sep 2025 16:57:45.753372000 UTC +00:00,
    updated_at: Fri, 12 Sep 2025 16:57:45.753372000 UTC +00:00>
```

[`encrypts`]: https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EncryptableRecord.html#method-i-encrypts

#### 重要: ストレージで考慮すべき点

暗号化を行うと、その分必要なストレージ容量が増加します。これは、Active Record暗号化によって、暗号化ペイロードの他に追加のメタデータも保存されるためです。なお、ペイロード自体はBase64エンコードされるので、テキストベースのカラムに安全に収まるようになります。

Rails組み込みの「[エンベロープ暗号化][enveloping]キープロバイダ」を使う場合、このオーバーヘッドは最悪でも約255バイトと見積もれます。このオーバーヘッドは、サイズが大きくなれば無視できるほど小さくなります。さらに、暗号化ではデフォルトで圧縮が使われるため、ペイロードが大きい場合、非暗号化バージョンと比較して最大30%のストレージ削減が可能です。

`string`カラムを暗号化する場合は、現代のデータベースがカラムのサイズを**バイト数**ではなく、**文字数**（number of characters）で定義していることを理解しておくことが重要です。UTF-8のようなエンコーディングでは、1文字あたり最大4バイトに達することがあります。つまり、N文字を保存するように定義されたカラムは、実際には最大で4 × Nバイトを消費する可能性があります。

暗号化されたペイロードは、Base64としてシリアライズされたバイナリデータなので、通常の`string`カラムに保存可能です。これはASCIIバイトのシーケンスであるため、暗号化カラムのサイズは最大で平文カラムの4倍になる可能性があります。

これは、実際には以下のようになります。

* 欧米のアルファベット（ほぼASCII文字）で書かれた短い文章を暗号化する場合は、カラムサイズを定義する際に255バイトのオーバーヘッド追加分を考慮しておく必要があります。

* キリル文字のような非西洋アルファベットで書かれた短いテキストを暗号化する場合、カラムサイズを4倍にしておく必要があります。ストレージのオーバーヘッドは最大255バイトである点にご注意ください。

* 長い文章を暗号化する場合、カラムサイズに関する懸念は無視できます。

以下に例を示します。

| 暗号化するコンテンツ               | 元のカラムサイズ | 暗号化カラムの推奨サイズ | ストレージのオーバーヘッド（最大）|
| ------------------------------- | ------------ | -------------------- | --------------------------- |
| メールアドレス                    | string(255)   | string(510)         | 255 bytes                   |
| 絵文字の短いシーケンス              | string(255)  | string(1020)         | 255 bytes                   |
| 非西洋アルファベットのサマリーテキスト | string(500)  | string(2000)         | 255 bytes                   |
| 任意の巨大テキスト                 | text         | text                 | 無視可能                     |

## 基本的な利用方法

### 暗号化データへのクエリにおける決定論的暗号化と非決定論的暗号化の違い

ActiveRecord暗号化では、デフォルトで**非決定論的な**（non-deterministic）暗号化を用います。ここで言う非決定論的とは、同じコンテンツを同じパスワードで暗号化しても、暗号化のたびに**異なる暗号文**が生成されるという意味です。

非決定論的な暗号化手法では、暗号文の解読が困難になるため、セキュリティが強化されます。しかしその代わり、暗号化された値に対するクエリ（例: `WHERE title = "すべて暗号化せよ！"`）を実行不可能になるという短所もあります。これは、平文の値が同じであっても異なる暗号文が生成されるため、以前保存した暗号文と一致しない可能性があるからです。

`deterministic:`オプションを指定することで、[決定論的][]な暗号化手法を利用可能になります。たとえば、`Author`モデルの`email`フィールドにクエリを実行する必要がある場合は、以下のようにします。

```ruby
class Author < ApplicationRecord
  encrypts :email, deterministic: true
end

# emailカラムへのクエリは、暗号化が非決定論的な場合にのみ可能
Author.find_by_email("tolkien@email.com")
```

`:deterministic`オプションを指定すると、初期化ベクトルが決定論的な手法で生成されるようになり、同じ平文入力値に対して常に同じ暗号化出力が生成されるようになります。これにより、文字列の等価比較による暗号化属性へのクエリが実行可能になります。
たとえば、以下のJSONドキュメント内の`p`キーと`iv`キーの値は暗号化されていますが、Authorのemailを作成するときもクエリを実行するときも同じであることにご注目ください。

```irb
my-app(dev)> author = Author.create(name: "J.R.R. Tolkien", email: "tolkien@email.com")
  TRANSACTION (0.1ms)  begin transaction
  Author Create (0.4ms)  INSERT INTO "authors" ("name", "email", "created_at", "updated_at") VALUES (?, ?, ?, ?) RETURNING "id"  [["name", "J.R.R. Tolkien"], ["email", "{\"p\":\"8BAc8dGXqxksThLNmKmbWG8=\",\"h\":{\"iv\":\"NgqthINGlvoN+fhP\",\"at\":\"1uVTEDmQmPfpi1ULT9Nznw==\"}}"], ["created_at", "2025-09-19 18:08:40.104634"], ["updated_at", "2025-09-19 18:08:40.104634"]]
  TRANSACTION (0.1ms)  commit transaction

my-app(dev)> Author.find_by_email("tolkien@email.com")
  Author Load (0.1ms)  SELECT "authors".* FROM "authors" WHERE "authors"."email" = ? LIMIT ?  [["email", "{\"p\":\"8BAc8dGXqxksThLNmKmbWG8=\",\"h\":{\"iv\":\"NgqthINGlvoN+fhP\",\"at\":\"1uVTEDmQmPfpi1ULT9Nznw==\"}}"], ["LIMIT", 1]]
=> #<Author:0x00007f8a396289d0
    id: 3,
    name: "J.R.R. Tolkien",
    email: "[FILTERED]",
    created_at: Fri, 19 Sep 2025 18:08:40.104634000 UTC +00:00,
    updated_at: Fri, 19 Sep 2025 18:08:40.104634000 UTC +00:00>
```

上の例では、初期化ベクトル`iv`の値も、同じ文字列に対して同じ`"NgqthINGlvoN+fhP"`という値になっていることにご注目ください。決定論的暗号化を用いると、同じメール文字列を異なるモデルインスタンス間（または決定論的暗号化を用いた異なる属性間）で使ったときも、同じ`p`および`iv`値に対応付けられるようになります。

```irb
my-app(dev)> author2 = Author.create(name: "Different Author", email: "tolkien@email.com")
  TRANSACTION (0.1ms)  begin transaction
  Author Create (0.4ms)  INSERT INTO "authors" ("name", "email", "created_at", "updated_at") VALUES (?, ?, ?, ?) RETURNING "id"  [["name", "Different Author"], ["email", "{\"p\":\"8BAc8dGXqxksThLNmKmbWG8=\",\"h\":{\"iv\":\"NgqthINGlvoN+fhP\",\"at\":\"1uVTEDmQmPfpi1ULT9Nznw==\"}}"], ["created_at", "2025-09-19 18:20:11.291969"], ["updated_at", "2025-09-19 18:20:11.291969"]]
  TRANSACTION (0.1ms)  commit transaction
```

`:deterministic`オプションは、セキュリティの強度が下がるというトレードオフと引き換えに、データをクエリ可能にできます。データが暗号化される点は代わりませんが、決定論的暗号化では暗号解読の難易度が下がります。この理由から、暗号化属性でクエリを実行する必要が生じない限り、非決定論的暗号化を利用することが推奨されます。

NOTE: 非決定論的モードのActive Recordでは、256ビットキーとランダムな初期化ベクトルを用いる[AES][]-[GCM][]が使われます。決定論的モードも同様にAES-GCMを用いますが、その初期化ベクトルはランダムではなく、キーと平文コンテンツの関数（キーと平文コンテンツの[HMAC][]-SHA-256ダイジェスト）として生成されます。

NOTE: `deterministic_key`を定義しなければ、決定論的暗号化を無効にできます。

[決定論的]:https://ja.wikipedia.org/wiki/決定的アルゴリズム
[AES]: https://ja.wikipedia.org/wiki/Advanced_Encryption_Standard
[GCM]: https://ja.wikipedia.org/wiki/Galois/Counter_Mode
[HMAC]: https://ja.wikipedia.org/wiki/HMAC

### 大文字小文字を区別しない場合

決定論的に暗号化されたデータへのクエリで大文字小文字を区別しないようにする必要が生じることがあります。これを行うために、`:downcase`オプションと`:ignore_case`オプションの2通りがあります。

暗号化属性の宣言で`:downcase`オプションを指定すると、データを小文字に変換してから暗号化されます。これにより、クエリで大文字小文字を効果的に区別しなくなるようになります。

```ruby
class Person
  encrypts :email_address, deterministic: true, downcase: true
end
```

その代わり、`downcase:`オプションを指定すると元の大文字小文字の区別が失われます。

大文字小文字の区別を失わずに、クエリでのみ大文字小文字を区別しないようにしたい場合は、`:ignore_case`オプションを指定できます。

```ruby
class Label
  encrypts :name, deterministic: true, ignore_case: true # 大文字小文字を維持したコンテンツは`original_name`カラムに保存される
end
```

`:ignore_case`オプションを利用する場合は、大文字小文字の区別を維持したコンテンツを保存するための`original_<カラム名>`というカラムを別途追加しておく必要があります。上の`name`属性を読み取るとき、Railsは元の大文字小文字を維持したバージョンを返しますが、`name`に対するクエリを実行するときは大文字小文字が無視されます。

### シリアライズ化属性

Active Record暗号化は、値が文字列としてシリアライズ可能である限り、暗号化の前にデフォルトで背後の型を用いて値をシリアライズします。
背後の型が文字列としてシリアライズ不可能な場合は、`message_serializer`オプションでカスタムの[`MessageSerializer`][]を指定できます。

```ruby
class Article < ApplicationRecord
  encrypts :metadata, message_serializer: SomeCustomMessageSerializer.new
end
```

構造化された型を持つ属性も、[`serialized`][]メソッドで同様に暗号化できます。
`serialized`メソッドは、属性を（`YAML`や`JSON`などで）シリアライズされたオブジェクトとしてデータベースに保存し、同じオブジェクトにデシリアライズして取得する必要がある場合に使います。

WARNING: カスタム型でシリアライズ化属性を利用する場合は、以下のようにシリアライズ化属性の行を必ず暗号化宣言の行より**上の行**に置く必要があります。

```ruby
# 正しい
class Article < ApplicationRecord
  serialize :title, type: Title
  encrypts :title
end

# 誤り
class Article < ApplicationRecord
  encrypts :title
  serialize :title, type: Title
end
```

[`MessageSerializer`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/MessageSerializer.html
[`serialized`]:
  https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html#method-i-serialize

### 暗号化データの一意性を担保する

一意性制約は、決定論的に暗号化されたデータでのみサポートされます。

#### 一意性バリデーション

属性が決定論的手法で暗号化されている場合は、以下のように通常通り一意性バリデーションを指定できます。

```ruby
class Person
  validates :email_address, uniqueness: true
  encrypts :email_address, deterministic: true, downcase: true
end
```

一意性バリデーションで大文字小文字を区別しないようにしたい場合は、必ず`encrypts`宣言で`:downcase`または`:ignore_case`オプションを指定する必要があります。[バリデーション](active_record_validations.html#uniqueness)で`:case_sensitive`オプションを指定しても無効です。

NOTE: 同一属性内に暗号化データと非暗号化データが混在している場合や、同一属性内に複数のキーやスキームで暗号化されたデータが混在している場合は、一意性バリデーションをサポートするために[`config.active_record.encryption.extend_queries = true`][`config.active_record.encryption.extend_queries`]を設定して拡張クエリを有効にする必要があります。

#### 一意インデックス

決定論的に暗号化されたカラムで一意インデックスをサポートするには、同じ平文から常に同じ暗号文が生成されるようにすることが重要です。これが一貫することで、インデックス作成やクエリが可能になります。

```ruby
class Person
  encrypts :email_address, deterministic: true
end
```

一意インデックスが正常に機能するには、インデックス化する属性の暗号化プロパティを後から変更しないようにする必要があります。

### 暗号化属性で命名されたparamsをログでフィルタする

暗号化済みカラムは、デフォルトでRailsのログから[自動的にフィルタで除外される][`config.filter_parameters`]ため、暗号化されたメールアドレスやクレジットカード番号などの機密情報はログに保存されません。たとえば、`email`フィールドをフィルタで設定している場合、ログには`Parameters: {"email"=>"[FILTERED]", ...}`のように出力されます。

暗号化パラメータのフィルタを無効にする必要がある場合は、以下のように[`config.active_record.encryption.add_to_filter_parameters`][]で無効にできます。

```ruby
# config/application.rb
config.active_record.encryption.add_to_filter_parameters = false
```

フィルタを有効にした状態で、特定のカラムをフィルタから除外したい場合は、以下のように[`config.active_record.encryption.excluded_from_filter_parameters`][]でカラムを追加します。

```ruby
config.active_record.encryption.excluded_from_filter_parameters = [:catchphrase]
```

NOTE: フィルタパラメータを生成するとき、Railsはモデル名をプレフィックスとして使います。たとえば、`User#name`の場合、フィルタパラメータは`user.name`になります。

[`config.active_record.encryption.extend_queries`]:
  configuring.html#config-active-record-encryption-extend-queries
[`config.filter_parameters`]:
  configuring.html#config-filter-parameters
[`config.active_record.encryption.add_to_filter_parameters`]:
  configuring.html#config-active-record-encryption-add-to-filter-parameters
[`config.active_record.encryption.excluded_from_filter_parameters`]:
  configuring.html#config-active-record-encryption-excluded-from-filter-parameters

### Action Text

Action Textの属性宣言に`encrypted: true`を指定することで、属性を暗号化できます。

```ruby
class Message < ApplicationRecord
  has_rich_text :content, encrypted: true
end
```

NOTE: Action Text属性に個別の暗号化オプションを渡す方法はサポートされていません。グローバルな暗号化オプションに設定されている非決定的暗号化が用いられます。

### フィクスチャ

暗号化属性をテストのYAMLフィクスチャファイル内で平文で記述可能にするには、`config/environments/test.rb`ファイルに以下の[`config.active_record.encryption.encrypt_fixtures`][]設定を追加することで、フィクスチャが自動的に暗号化されるようになります。

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.active_record.encryption.encrypt_fixtures = true
  # ...
end
```

この設定を行わないと、Railsはフィクスチャ値を暗号化せずにそのまま読み込みます。この場合、Active Record暗号化はそのカラムにJSON値を期待するため、暗号化属性は正しく動作しません。
`encrypt_fixtures`設定を有効にすることで、すべての暗号化可能な属性はモデルで定義された暗号化設定に従って自動的に暗号化され、シームレスに復号も行われます。

[`config.active_record.encryption.encrypt_fixtures`]: configuring.html#config-active-record-encryption-encrypt-fixtures

#### Action Textのフィクスチャ

Action Textのフィクスチャを暗号化するには、`fixtures/action_text/encrypted_rich_texts.yml`ファイルにフィクスチャを配置します。

### エンコード

文字列を非決定論的に暗号化すると、文字列の元のエンコーディングは自動的に維持されます。

決定論的暗号化の場合、Railsは暗号文とともに文字列エンコーディングも保存しますが、特にクエリや一意性の強制で暗号化出力を一貫させるために、デフォルトでUTF-8エンコーディングを強制します。これにより、エンコーディングが異なる同一の文字列から異なる暗号文が生成されるのを防ぎます。

この振る舞いは設定でカスタマイズ可能です。
デフォルトで強制するエンコーディングの種類は、以下のように[`config.active_record.encryption.forced_encoding_for_deterministic_encryption`][]で変更できます。

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = Encoding::US_ASCII
```

この振る舞いを無効にして常にエンコードを維持するには、以下のように`nil`を設定します。

```ruby
config.active_record.encryption.forced_encoding_for_deterministic_encryption = nil
```

[`config.active_record.encryption.forced_encoding_for_deterministic_encryption`]:
  configuring.html#config-active-record-encryption-forced-encoding-for-deterministic-encryption

### 圧縮

Active Record暗号化は、暗号化されたペイロードをデフォルトで圧縮します。これにより、ペイロードが大きい場合のストレージ容量を最大30%節約できます。

NOTE: 圧縮はデフォルトで有効ですが、常にすべてのペイロードに適用されるとは**限らない**点にご注意ください。圧縮するかどうかはサイズの閾値（たとえば140バイト）に基づいており、圧縮する「価値がある」かどうかを判断するためのヒューリスティックとして使われます。

圧縮を無効にするには、属性を暗号化する際に`compress`オプションを`false`に設定します。

```ruby
class Article < ApplicationRecord
  encrypts :content, compress: false
end
```

```ruby
class Article < ApplicationRecord
  encrypts :content, compress: false
end
```

圧縮アルゴリズムは設定で変更可能です。デフォルトの圧縮ライブラリは[`Zlib`][]です。
以下のように`deflate`メソッドと`inflate`メソッドに応答するクラスまたはモジュールを作成することで、独自の圧縮を実装できます。

```ruby
require "zstd-ruby"

module ZstdCompressor
  def self.deflate(data)
    Zstd.compress(data)
  end

  def self.inflate(data)
    Zstd.decompress(data)
  end
end

class User
  encrypts :name, compressor: ZstdCompressor
end
```

以下のように、[`config.active_record.encryption.compressor`][]で圧縮プログラムをグローバルに設定することも可能です。

```ruby
config.active_record.encryption.compressor = ZstdCompressor
```

[`Zlib`]: https://ja.wikipedia.org/wiki/Zlib
[`config.active_record.encryption.compressor`]: configuring.html#config-active-record-encryption-compressor

### APIで暗号化を利用する

Active Record暗号化は宣言的に利用することを念頭に置いていますが、より高度なシナリオで使えるAPIも提供しています。

`article`モデルで関連する全属性を暗号化または復号するには、以下のように[`encrypt`][]や[`decrypt`][]メソッドを使います。

```ruby
article.encrypt # 暗号化可能なすべての属性を暗号化または再暗号化する
article.decrypt # 暗号化可能なすべての属性を復号する
```

指定の属性が暗号化されているかどうかを確認するには、以下のように[`encrypted_attribute?`][]を使います。

```ruby
article.encrypted_attribute?(:title)
```

属性の暗号文をそのまま読み出すには、以下のように[`ciphertext_for`][]を使います。

```ruby
article.ciphertext_for(:title)
```

[`encrypt`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EncryptableRecord.html#method-i-encrypt
[`decrypt`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EncryptableRecord.html#method-i-decrypt
[`encrypted_attribute?`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EncryptableRecord.html#method-i-encrypted_attribute-3F
[`ciphertext_for`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EncryptableRecord.html#method-i-ciphertext_for

## 既存データを移行する

### 暗号化されていないデータのサポート

Railsアプリケーションで暗号化されていない属性を暗号化属性に移行しやすくするため、以下の[`config.active_record.encryption.support_unencrypted_data`][]設定で非暗号化データのサポートを有効にできます。

```ruby
config.active_record.encryption.support_unencrypted_data = true
```

この設定を有効にすると、以下が行われます。

* まだ暗号化されていない属性を読み出してもエラーを`raise`しなくなる

* 以下のように[`extended_queries`][]も有効にすると、決定論的に暗号化された属性へのクエリが暗号化済みの値と平文の値の両方にマッチするようになる。

```ruby
config.active_record.encryption.extend_queries = true
```

このセットアップは、暗号化済みデータと非暗号化データの両方がアプリケーション内で共存する必要がある移行期間中のみを対象としていることにご注意ください。2つのオプションはどちらもデフォルトで`false`になっています。これは、データが完全に強制的に暗号化される、長期的に推奨される設定です。

[`config.active_record.encryption.support_unencrypted_data`]:
  configuring.html#config-active-record-encryption-support-unencrypted-data
[`extend_queries`]:
  configuring.html#config-active-record-encryption-extend-queries

### 移行前の暗号化スキームのサポート

属性の暗号化プロパティを変更すると、既存のデータが破損する可能性があります。たとえば、決定論的な暗号化属性を非決定論的に変更したい場合を考えてみましょう。モデルで宣言を変更すると、暗号化手法が一致しなくなるため、既存の暗号文の読み取りに失敗します。

このような状況をサポートするために、移行前の古い暗号化スキームをグローバルまたは属性ごとに指定できます。

移行前のスキームを設定すると、以下がサポートされます。

* 暗号化データを現在の暗号化スキームで読み出せない場合は、移行前の暗号化スキームで読み取りを試みるようになる。

* 決定論的に暗号化されたデータに対するクエリを実行するときは、移行前の暗号化スキームで暗号化したテキストを追加するようになる。これにより、異なるスキームで暗号化されたデータに対してもクエリがシームレスに動作するようになる。

この機能を利用するには、`extended_queries`設定を有効にする必要があります。

```ruby
config.active_record.encryption.extend_queries = true
```

次は、以前の暗号化スキームを設定する方法を見てみましょう。

#### 移行前の暗号化スキームをグローバルに設定する

移行前の暗号化スキームは、`config/application.rb`で以下のように`previous`設定でプロパティのリストとして追加可能です。

```ruby
config.active_record.encryption.previous = [ { key_provider: MyOldKeyProvider.new } ]
```

#### 移行前の暗号化スキームを属性ごとに設定する

属性を宣言するときに以下のように`:previous`オプションを個別に指定します。

```ruby
class Article
  encrypts :title, deterministic: true, previous: { deterministic: false }
end
```

#### 暗号化スキームと決定論的な属性

決定的暗号化をあえて利用する場合は、暗号文を変えたくないのが普通です。そのため、暗号化スキームを変更するときに非決定論的暗号化と決定論的暗号化の振る舞いには以下の違いがあります。

* **非決定論的暗号化**の場合: 新しい情報は常に**最新の**（現在の）暗号化スキームで暗号化される

* **決定論的暗号化**の場合: 新しい情報は常にデフォルトで**最も古い**暗号化スキームによって暗号化される

以下のように決定論的暗号化のこの振る舞いを変更して、新しいデータを暗号化するために**最新の**暗号化スキームを使うようにすることも可能です。

```ruby
class Article
  encrypts :title, deterministic: { fixed: false }
end
```

### 暗号化コンテキスト

暗号化コンテキストとは、ある時点に使われる暗号化コンポーネントを定義するものです。デフォルトではグローバルな設定に基づいた暗号化コンテキストが使われますが、特定の属性で用いるカスタムコンテキストや、コードの特定のブロックを実行するときのカスタムコンテキストを定義可能です。

NOTE: 暗号化コンテキストの設定メカニズムは柔軟ですが高度です。ほとんどのユーザーは気にする必要はないはずです。

暗号化コンテキストに登場する主なコンポーネントは以下のとおりです。

* `encryptor`: データの暗号化や復号に用いる内部APIを公開します。暗号化メッセージの作成とシリアライズのために`key_provider`とやりとりします。暗号化や復号そのものは`cypher`で行われ、シリアライズは`message_serializer`で行われます。
* `cipher`: 暗号化アルゴリズムそのもの（AES 256 GCM）
* `key_provider`: 暗号化と復号のキーを提供する
* `message_serializer`: 暗号化されたペイロードをシリアライズおよびデシリアライズする（`Message`）

WARNING: 独自の`message_serializer`を構築する場合は、任意のオブジェクトをデシリアライズすることのない安全なメカニズムを採用することが重要です。一般にサポートされているシナリオは、既存の非暗号化データを暗号化するときです。任意のオブジェクトがデシリアライズ可能だと、攻撃者がこれを利用して、暗号化が行われる前に改ざんしたペイロードを入力してリモートコード実行（RCE）を実行する可能性があります。つまり、独自のシリアライザでは`Marshal`、`YAML.load`（`YAML.safe_load`にすること）、`JSON.load`（`JSON.parse`にすること）の利用を避けるべきです。

### Rails組み込みの暗号化コンテキスト

グローバルな暗号化コンテキストはデフォルトで利用されます。他の設定プロパティと同様、`config/application.rb`や環境ごとの設定ファイルで以下のように設定可能です。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
config.active_record.encryption.encryptor = MyEncryptor.new
```

[`with_encryption_context`][]メソッドを使えば、暗号化コンテキストの任意のプロパティを上書きできます。

[`with_encryption_context`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Contexts.html#method-i-with_encryption_context


#### 特定のコードブロックを実行中の暗号化コンテキスト

[`with_encryption_context`][]を使うと、指定のコードブロックで暗号化コンテキストを設定できます。

```ruby
ActiveRecord::Encryption.with_encryption_context(encryptor: ActiveRecord::Encryption::NullEncryptor.new) do
  # ...
end
```

[`with_encryption_context`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Contexts.html#method-i-with_encryption_context

#### 属性ごとの暗号化コンテキスト

以下のように属性の宣言で`encryptor`オプションを渡すことで、暗号化コンテキストを上書きできます。

```ruby
class Attribute
  encrypts :title, encryptor: MyAttributeEncryptor.new
end
```

### 暗号化コンテキストの暗号化を無効にする

以下のように[`without_encryption`][]を使うことで、暗号化を無効にしてコードを実行できます。

```ruby
ActiveRecord::Encryption.without_encryption do
  # ...
end
```

この場合、暗号化テキストを読み出すと暗号文のまま読み出され、保存したコンテンツは暗号化なしで保存されます。

[`without_encryption`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Contexts.html#method-i-without_encryption

### 暗号化コンテキストの暗号化済みデータを保護する

以下のように[`protecting_encrypted_data`][]を使うことで、暗号化を無効にすると同時に、暗号化済みコンテンツが上書きされないようにコードを実行できます。

```ruby
ActiveRecord::Encryption.protecting_encrypted_data do
  # ...
end
```

これは、暗号化データを保護しつつ、任意のコードを実行したい場合に便利です（Railsコンソールなど）。

[`protecting_encrypted_data`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Contexts.html#method-i-protecting_encrypted_data

## キーの管理

キープロバイダは、キー管理戦略を実装します。キープロバイダはグローバルに設定することも、属性ごとに指定することも可能です。

### 組み込みのキープロバイダ

#### `DerivedSecretKeyProvider`

[`DerivedSecretKeyProvider`][]は、指定のパスワードから[PBKDF2][]を用いて導出されるキーを提供するキープロバイダです。このキープロバイダはデフォルトで設定されます。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::DerivedSecretKeyProvider.new(["some passwords", "to derive keys from. ", "These should be in", "credentials"])
```

NOTE: `active_record.encryption`はデフォルトで、`active_record.encryption.primary_key`で定義されているキーを用いる`DerivedSecretKeyProvider`を設定します。

[`DerivedSecretKeyProvider`]:
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/DerivedSecretKeyProvider.html
[PBKDF2]:
  https://ja.wikipedia.org/wiki/PBKDF2

#### `EnvelopeEncryptionKeyProvider`

[`EnvelopeEncryptionKeyProvider`][]は、データをキーでシンプルに暗号化する[エンベロープ暗号化][enveloping]戦略を実装します。この戦略では、データがキーで暗号化され、そのキーも暗号化されます。

- データ暗号化操作のたびにランダムなキーを生成する
- データ自身のほかにデータキーも保存する
- `active_record.encryption.primary_key` credentialで定義されている主キーによる暗号化も行う

以下を`config/application.rb`に追加することで、Active Recordでこのキープロバイダを使うよう設定できます。

```ruby
config.active_record.encryption.key_provider = ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider.new
```

他の組み込みのキープロバイダと同様に、`active_record.encryption.primary_key`に主キーのリストを渡すことでキーローテーションスキームを実装できます。

[enveloping]:
  https://docs.aws.amazon.com/ja_jp/kms/latest/developerguide/kms-cryptography.html#enveloping

[`EnvelopeEncryptionKeyProvider`]: 
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/EnvelopeEncryptionKeyProvider.html

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
- `decryption_keys`: 指定のメッセージを復号するのに使う可能性のあるキーのリストを返す

1つのキーには、メッセージと一緒に暗号化なしで保存される任意のタグを含められます。[`ActiveRecord::Encryption::Message#headers`][]を使って、復号時にこれらの値を調べられます。

[`ActiveRecord::Encryption::Message#headers`]: 
  https://api.rubyonrails.org/classes/ActiveRecord/Encryption/Message.html

### キープロバイダを属性ごとに指定する

`key_provider:`オプションで、キープロバイダを属性ごとに設定できます。
たとえば、`ArticleKeyProvider`というカスタムキープロバイダが定義されていれば、以下のように指定できます。

```ruby
class Article < ApplicationRecord
  encrypts :summary, key_provider: ArticleKeyProvider.new
end
```

### キーを属性ごとに指定する

`key:`オプションで、指定のキーを属性ごとに設定できます。

```ruby
class Article < ApplicationRecord
  encrypts :summary, key: ENV["SOME_SECRET_KEY_FOR_ARTICLE_SUMMARIES"]
end
```

`encrypts`の`key`オプションに渡されたキーを使って、上の`summary`属性の暗号化と復号が行われます。

### キーのローテーション

`active_record_encryption`には、キーローテーションスキームの実装をサポートするためにキーのリストを渡せます。
キーをローテーションする理由は、組織のセキュリティポリシーの一環として、またはキーが侵害された疑いがある場合などです。

以下の例では、新しいコンテンツの暗号化には常にリストの**最下部のキー**が使われます。
復号では、成功するまですべてのキーを試行します。

```yml
active_record_encryption:
  primary_key:
    - a1cc4d7b9f420e40a337b9e68c5ecec6 # 以前のキーは引き続き既存コンテンツを復号する
    - bc17e7b413fd4720716a7633027f8cc4 # 新しいコンテンツを暗号化するアクティブなキー
  key_derivation_salt: a3226b97b3b2f8372d1fc6d497a0c0d3
```

これにより、「新しいキーの追加」「コンテンツの再暗号化」「古いキーの削除」を行ってキーのリストを短く保てるようになります。

NOTE: キーローテーションは、決定論的暗号化では現在サポートされていません。

### キー参照の保存

以下のように[`active_record.encryption.store_key_references`][]を設定することで、`active_record.encryption`が暗号化済みメッセージそのものに暗号化キーへの参照を保存するようになります。これにより、復号の際にキーのリストを探索する必要がなくなり、パフォーマンスが向上します。ただし、その分暗号化データのサイズがやや大きくなります。

キー参照を保存するには、以下の設定を有効にする必要があります。

```ruby
config.active_record.encryption.store_key_references = true
```

[`active_record.encryption.store_key_references`]:
  configuring.html#config-active-record-encryption-store-key-references
