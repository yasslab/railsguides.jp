
Rails ガイドのガイドライン
===============================

本ガイドは、Ruby on Railsガイドを書くためのガイドラインです。本ガイド自身が本ガイドに従って書かれており、望ましいガイドラインの例であると同時に優美なループを形成しています。

このガイドの内容:

* Railsドキュメントの記法
* ガイドをローカルで生成する方法

--------------------------------------------------------------------------------


Markdown
-------

ガイドは[GitHub Flavored Markdown][] で書かれています。まとまった[Markdownドキュメント][Markdown doc]と[チートシート][cheatsheet]があります。

[GitHub Flavored Markdown]: https://docs.github.com/ja/get-started/writing-on-github
[Markdown doc]: https://daringfireball.net/projects/markdown/syntax
[cheatsheet]: https://daringfireball.net/projects/markdown/basics

プロローグ
--------

ガイドの冒頭には、読者の開発意欲を高めるような文を置いてください。ガイドの青い部分がこれに該当します。プロローグでは、そのガイドの概要と、ガイドで学ぶ項目について記載してください。例については[ルーティングガイド](routing.html)を参照してください。

見出し
------

ガイドのタイトルには`h1`、ガイドのセクション見出しには`h2`、ガイドのサブセクション見出しには`h3`をそれぞれ使ってください。なお、実際に生成されるHTMLの見出しは`<h2>`から始まります。

```markdown
ガイドのタイトル
===========

セクション
-------

### サブセクション
```

冠詞、前置詞、接続詞、be動詞以外の単語は冒頭を大文字にします。

```markdown
#### Middlewareスタックは配列
#### オブジェクトが保存されるタイミング
```

通常のテキストと同じタイポグラフィをお使いください。

```markdown
##### `:content_type`オプション
```

`NOTE`、`TIP`、`WARNING`の運用方法
------------------------

場合によっては、パラグラフでもう少し読者の注意を促す必要が生じることがあります（例: よくある誤解を解消する、アプリケーションを壊す可能性のある書き方などについて警告する）。

パラグラフを強調するには、以下のように`NOTE:`、`TIP:`、`WARNING:`をパラグラフの冒頭に追加します。

```markdown
NOTE: パラグラフの強調には、`NOTE:`、`TIP:`、`WARNING:`を使うこと。
```

これにより、パラグラフは以下のように専用のコンテナで囲まれるようになります。

NOTE: パラグラフの強調には、`NOTE:`、`TIP:`、`WARNING:`を使うこと。

### `NOTE`の運用

`NOTE`は、主題や文脈に関連する内容を強調するのに使います。これを読むと、主題や文脈の理解や、重要な項目を明確にしたりうえで役立つようになります。

たとえば、ロケールファイルについて解説するセクションには、以下の`NOTE`を追加するとよいでしょう。

NOTE: ロケールファイルを追加した場合は、サーバーを再起動する必要があります。

### `TIP`の運用

`TIP`は、主題に関する補足情報であり、必ずしも理解に関係するとは限りません。たとえば別のガイドやWebサイトを示すのに使えます。

TIP: ルーティングについて詳しくは、[ルーティングガイド](routing.html)を参照してください。

あるいは、便利なコマンドをさらに深く掘り下げるのにも使えます。

TIP: ジェネレータのヘルプをさらに表示するには、`bin/rails generate --help`を実行します。

### `WARNING`の運用

`WARNING`は、アプリケーションを壊す可能性を避けるのに使います。

WARNING: コールバックメソッド内では、`update`や`save`などのメソッドや、オブジェクトに副作用を引き起こすメソッドの利用は避けること。

あるいは、アプリケーションのセキュリティを脅かす可能性のあることについて警告するのにも使えます。

WARNING: アプリのマスターキーは安全に保管すること。マスターキーをリポジトリにコミットしてはいけません。

リンクの書き方
-----

リンクの文字列には、"here"や"more"といった書き方を避け、具体的な内容のわかる文字列を使うこと。

``markdown
# BAD
See the Rails Internationalization (I18n) API documentation for [more
details](i18n.html).

# GOOD
See the [Rails Internationalization (I18n) API documentation](i18n.html) for
more details.
```

Railsガイド内の内部リンクについても同様。

```markdown
# BAD
We will cover this [below](#multiple-callback-conditions).

# GOOD
We will cover this in the [multiple callback conditions
section](#multiple-callback-conditions) shown below.
```

APIにリンクする
------------------

APIサイト（`api.rubyonrails.org`）へのリンクは、以下の方法を用いてガイドのジェネレータで処理されます。

リリース番号（`v5.0.1`など）タグを含むリンクに対しては何も処理を行いません（例↓）。

```
http://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Attributes/ClassMethods.html
```

上は変更されません。

リリースノートではこの書式でリンクを書いてください。今後どんな対象が生成されても、リリースノートに対応したバージョンを指すようにすべきです。

リンクにリリース番号タグが含まれていない場合やedgeガイドが生成される場合は、ドメイン名の部分が`edgeapi.rubyonrails.org`に置き換えられます（例↓）。


```
http://api.rubyonrails.org/classes/ActionDispatch/Response.html
```

上は以下に置き換えられます。

```
http://edgeapi.rubyonrails.org/classes/ActionDispatch/Response.html
```

リンクにリリース番号タグが含まれていない場合や、正規版のガイドが生成される場合は、Railsのバージョン番号が挿入されます。たとえば、Rails 5.1.0向けのガイドを生成すると以下のようなリンクになります。

```
http://api.rubyonrails.org/classes/ActionDispatch/Response.html
```

上は以下に置き換えられます。

```
http://api.rubyonrails.org/v5.1.0/classes/ActionDispatch/Response.html
```

`edgeapi.rubyonrails.org`には手動でリンクしないでください。

行の折返しについて
---------------

古いガイドの行を折り返すためだけの目的で再フォーマットしないでください。ただし、新しいセクションとガイドは80文字目で折り返す必要があります。

APIドキュメントの書き方
----------------------------

ガイドとAPIは、必要な箇所が互いに首尾一貫している必要があります。[APIドキュメント作成ガイドライン](api_documentation_guidelines.html)の以下のセクションを参照してください

* [語調](api_documentation_guidelines.html#語調)
* [アメリカ英語](api_documentation_guidelines.html#英語はアメリカ英語で)
* [サンプルコード](api_documentation_guidelines.html#サンプルコード)
* [ファイル名](api_documentation_guidelines.html#ファイル名)
* [フォント](api_documentation_guidelines.html#フォント)

上記のガイドラインは、ガイドについても適用されます。

HTMLガイド
-----------

ガイドを生成する前に、システムに最新のBundlerがインストールされていることを確認してください。最新のBundlerをインストールするには`gem install bundler`コマンドを実行してください。

Bundlerを既にインストールしている場合は、`gem update bundler`で最新のBundlerに更新できます。

### 生成

すべてのガイドを生成するには、`cd`コマンドで`guides`ディレクトリに移動し、`bundle install`を実行してから以下のいずれかを実行します。

```bash
$ bundle exec rake guides:generate
```

または

```bash
$ bundle exec rake guides:generate:html
```

生成されたHTMLファイルは、`./output`ディレクトリに配置されます。

`my_guide.md`ファイルだけを生成したい場合は環境変数`ONLY`に設定します。

```bash
$ touch my_guide.md
$ bundle exec rake guides:generate ONLY=my_guide
```

デフォルトでは、変更のないガイドは生成がスキップされるので、`ONLY`を使う機会はあまりないと思われます。

すべてのガイドを強制的に生成するには`ALL=1`を指定します。

英語以外の言語向けに生成を行いたい場合は、`source`ディレクトリの下にたとえば`source/es`のようにその言語用のディレクトリを作成し、`GUIDES_LANGUAGE`環境変数を設定します。

```bash
$ bundle exec rake guides:generate GUIDES_LANGUAGE=es
```

生成スクリプトの設定に使える環境変数をすべて知りたい場合は、単に以下を実行してください。

```bash
$ rake
```

### バリデーション

生成されたHTMLをバリデーション（検証）するには以下を実行します。

```bash
$ bundle exec rake guides:validate
```

特に、タイトルを元にIDが生成される関係上、タイトルでの重複が生じやすくなっています。

Kindleガイド
-------------

### 生成

Kindle向けにガイドを生成するには、以下のrakeタスクを実行します。

```bash
$ bundle exec rake guides:generate:kindle
```
