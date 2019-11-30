**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Rails ガイドのガイドライン
===============================

本ガイドは、Ruby on Railsガイドを書くためのガイドラインです。本ガイド自身が本ガイドに従って書かれており、望ましいガイドラインの例であると同時に優美なループを形成しています。

このガイドの内容:

* Railsドキュメントの記法
* ガイドをローカルで生成する方法

--------------------------------------------------------------------------------

マークダウン (Markdown)
-------

ガイドは [GitHub Flavored Markdown](http://github.github.com/github-flavored-markdown/) で書かれています。まとまった[Markdownドキュメント](http://daringfireball.net/projects/markdown/syntax)、[チートシート](http://daringfireball.net/projects/markdown/basics)、通常のMarkdownとの違いに関する[追加ドキュメント](http://github.github.com/github-flavored-markdown/) がそれぞれあります。

プロローグ
--------

ガイドの冒頭には、読者の開発意欲を高めるような文を置いてください。ガイドの青い部分がこれに該当します。プロローグでは、そのガイドの概要と、ガイドで学ぶ項目について記載してください。例については[ルーティングガイド](routing.html)を参照してください。

見出し
------

ガイドのタイトルには`h1`、ガイドのセクション見出しには`h2`、ガイドのサブセクション見出しには`h3`をそれぞれ使ってください。なお、実際に生成されるHTMLの見出しは`<h2>`から始まります。

```
ガイドのタイトル
===========

セクション
-------

### サブセクション
```

冠詞、前置詞、接続詞、be動詞以外の単語は冒頭を大文字にします。

```
#### Middlewareスタックは配列
#### オブジェクトが保存されるタイミング
```

通常のテキストと同じタイポグラフィをお使いください。

```
##### `:content_type`オプション
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


APIドキュメントの書き方
----------------------------

ガイドとAPIは、必要な箇所が互いに首尾一貫している必要があります。[APIドキュメント作成ガイドライン](api_documentation_guidelines.html)の以下のセクションを参照してください

* [言葉遣い](api_documentation_guidelines.html#語調)
* [サンプルコード](api_documentation_guidelines.html#サンプルコード)
* [ファイル名](api_documentation_guidelines.html#ファイル名)
* [フォント](api_documentation_guidelines.html#フォント)

上記のガイドラインは、ガイドについても適用されます。

HTMLガイド
-----------

ガイドを生成する前に、システムに最新のBundlerがインストールされていることを確認してください。現時点であれば、Bundler 1.3.5以降がインストールされている必要があります。

最新のBundlerをインストールするには`gem install bundler`コマンドを実行してください。

### 生成

すべてのガイドを生成するには、`cd`コマンドで`guides`ディレクトリに移動し、`bundle install`を実行してから以下のいずれかを実行します。

```
bundle exec rake guides:generate
```

または

```
bundle exec rake guides:generate:html
```

生成されたHTMLファイルは、`./output`ディレクトリに配置されます。

`my_guide.md`ファイルだけを生成したい場合は環境変数`ONLY`に設定します。

```
touch my_guide.md
bundle exec rake guides:generate ONLY=my_guide
```

デフォルトでは、変更のないガイドは生成がスキップされるので、`ONLY`を使う機会はあまりないと思われます。

すべてのガイドを強制的に生成するには`ALL=1`を指定します。

英語以外の言語向けに生成を行いたい場合は、`source`ディレクトリの下にたとえば`source/es`のようにその言語用のディレクトリを作成し、`GUIDES_LANGUAGE`環境変数を設定します。

```
bundle exec rake guides:generate GUIDES_LANGUAGE=es
```

生成スクリプトの設定に使える環境変数をすべて知りたい場合は、単に以下を実行してください。

```
rake
```

### バリデーション

生成されたHTMLをバリデーション（検証）するには以下を実行します。

```
bundle exec rake guides:validate
```

特に、タイトルを元にIDが生成される関係上、タイトルでの重複が生じやすくなっています。重複を検出するには、ガイド生成時に`WARNINGS=1`を指定してください。警告に解決方法が出力されます。

Kindleガイド
-------------

### 生成

Kindle向けにガイドを生成するには、以下のrakeタスクを実行します。

```
bundle exec rake guides:generate:kindle
```
