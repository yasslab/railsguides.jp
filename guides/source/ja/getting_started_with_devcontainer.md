Dev Containerでの開発ガイド
===================================

このガイドの内容:

* `rails-new`ツールでRailsアプリケーションを新規作成する方法
* development containerでアプリケーションを扱う方法

--------------------------------------------------------------------------------

本ガイドは、途中を飛ばさずにステップごとに読み進めるのがベストです。サンプルアプリケーションを実行するにはすべての手順をもれなく実行する必要がありますが、その他のコードや手順は必要ありません。

本ガイドは、[dev container（development container）](https://containers.dev/)を用いた完全な開発環境のセットアップを支援するためのものです。dev containerは、RubyやRailsやそれらの依存関係をローカルコンピュータに直接インストールせずに、RailsアプリケーションをDockerコンテナ内で実行するために使われます。これは、Railsアプリケーションを立ち上げて実行する最短の方法です。

これは、[Railsをはじめよう](getting_started.html#railsアプリを新規作成する)で説明されている、RubyやRailsを自分のコンピュータに直接インストールする方法とは別の方法です。本ガイドを完了したら、[Railsをはじめよう - Railsアプリを新規作成する](getting_started.html#railsアプリを新規作成する)から読み進められます。

セットアップとインストール
----------------------

セットアップを開始するには、必要な関連ツール（Docker、VS Code、`rails-new`）をインストールしておく必要があります。詳しくは以下で説明します。

### Dockerをインストールする

dev containerはDockerを使って実行されます。Dockerは、アプリケーションを開発・デプロイ・実行を行うオープンなプラットフォームです。Dockerをインストールするには、[Dockerドキュメント](https://docs.docker.com/desktop/)に記載されている各OS向けのインストール手順に従ってください。

Dockerのインストールが完了したら、Dockerアプリケーションを起動して、マシン上でDockerエンジンの実行を開始します。

### VS Codeをインストールする

Visual Studio Code（VS Code）は、Microsoftによって開発されたオープンソースのコードエディタです。VS Codeのdev container拡張機能を利用することで、コンテナ内の（またはコンテナにマウントされた）フォルダを開けばVisual Studio Codeの機能をすべて利用できるようになります。

プロジェクトフォルダ内の[devcontainer.json](https://code.visualstudio.com/docs/devcontainers/containers#_create-a-devcontainerjson-file)ファイルは、明確に定義されたツールや、ランタイムスタックを用いてdev containerにアクセス（または作成）する方法をVS Codeに指示します。
これにより、コンテナを直ちに起動して、ターミナルコマンドへのアクセスやコードのデバッグを行うことも、拡張機能の利用も可能になります。

VS Codeは、[公式Webサイト](https://code.visualstudio.com/)からダウンロードしてインストールできます。

dev container拡張機能は、[マーケットプレイス](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)からダウンロードしてインストールできます。

### rails-newツールをインストールする

`rails-new`ツールを使うと、自分のコンピュータにRubyがインストールされていなくても新規Railsアプリケーションを生成できるようになります。Dockerを利用してRailsアプリケーションを生成するため、適切なバージョンのRubyやRailsをDockerでインストールできるようになります。

`rails-new`ツールをインストールするには、[README](https://github.com/rails/rails-new?tab=readme-ov-file#installation)のインストール手順に従ってください。

storeアプリケーションを作成する
-----------------------------

Railsにはジェネレータと呼ばれる多数のスクリプトが付属しており、特定のタスクの作業を開始するのに必要なものをすべて生成することで開発作業を容易にするように設計されています。

新規アプリケーションを作成するジェネレーターもその1つで、新しいRailsアプリケーションの基本部分はこのジェネレータが提供するので、自分でアプリケーションを作成する必要はありません。

`rails-new`ツールは、新しいRailsアプリケーションを作成するときにこのジェネレータを利用します。

NOTE: 以下の例では、UNIX系OSのターミナルプロンプトを`$`で表していますが、環境によっては他のプロンプトが表示されるようにカスタマイズされている可能性もあります。

`rails-new`でアプリを生成するには、ターミナルを開き、ファイルを作成する権限があるディレクトリに移動して、以下のコマンドを実行します。

```bash
$ rails-new store --devcontainer
```

これによって`store`ディレクトリが作成され、その中にStoreという名前のRailsアプリケーションが作成されます。

TIP: `rails-new --help`を実行すると、Railsのアプリケーションジェネレータに渡せるのと同じコマンドラインオプションが表示されていることがわかります。

storeアプリケーションを作成したら、以下のコマンドを実行してそのディレクトリに移動します。

```bash
$ cd store
```

この`store`ディレクトリには、Railsアプリケーションの構造を構成するために生成されたファイルとフォルダが多数含まれています。このチュートリアルの作業のほとんどは`app`フォルダで行います。

このstoreアプリケーションの全概要については、[Rails をはじめよう](getting_started.html#railsアプリを新規作成する)ガイドを参照してください。

storeアプリケーションをdev containerで開く
-----------------------------------------------

新しいRailsアプリケーションには、すぐ利用できる形で構成済みのdev containerが付属しています。dev containerの起動と操作にVS Codeを使うことにします。最初に、VS Codeを起動してアプリケーションを開きます。

アプリケーションが開くと、VS Codeは、dev containerのファイルが見つかったことを示すプロンプトを表示し、dev containerでフォルダを再度開けるようになります。緑色の「Reopen in Container（コンテナで再度開く）」ボタンをクリックしてdev containerを作成します。

dev containerのセットアップが完了すると、RubyとRails、そしてすべての依存関係がインストール済みの開発環境が利用可能になります。

VS Code内でターミナルを開いて以下のコマンドを実行すると、Railsがインストールされていることを確認できます。

```bash
$ rails --version
Rails 8.0.0
```

これで、["Rails をはじめよう"ガイドの「最初のRailsアプリケーションを作成する」セクション](getting_started.html#最初のrailsアプリケーションを作成する)からstoreアプリケーションの構築を開始できます。
構築作業はVS Code内で行うことになります。VS Codeはアプリケーションのdev containerへのエントリポイントの役割を果たすことになるので、コードの実行、テストの実行、アプリケーションの実行はVS Codeから行えるようになります。
