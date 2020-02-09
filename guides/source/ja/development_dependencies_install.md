**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://guides.rubyonrails.org.**

Rails コア開発環境の構築方法
================================

本ガイドでは、Ruby on Rails自体の開発環境を構築する方法について解説します。

このガイドの内容:

* 自分のPCをRails開発用にセットアップする方法

--------------------------------------------------------------------------------

簡単な方法
------------

[Rails development box](https://github.com/rails/rails-dev-box)にあるできあいのdevelopment環境を入手するのがおすすめです。

面倒な方法
------------

Rails development boxを利用できない事情がある場合は、この先をお読みください。Ruby on Railsコア開発で必要なdevelopment boxを手動でビルドする手順を解説します。

### Gitをインストールする

Ruby on Railsではソースコード管理にGitを使用しています。インストール方法については[Gitホームページ](https://git-scm.com/)に記載されています。Gitを学ぶための資料はネット上に山ほどあります (特記ないものは英語)。

* [Try Git course](https://try.github.io/)は、対話的な操作のできるコースで基礎を学べます。
* [Git公式ドキュメント](https://git-scm.com/documentation)には多くの情報がまとめられており、Gitの基礎を学べる動画もあります。
* [Everyday Git](https://schacon.github.io/git/everyday.html)は最小限必要なGitの知識を学ぶのに向いています。
* [GitHub](https://help.github.com)にはさまざまなGit関連リソースへのリンクがあります。
* [Pro Git日本語版](https://progit-ja.github.io/)ではGitについてすべてをカバーした書籍がさまざまな形式で翻訳されており、クリエイティブ・コモンズ・ライセンスで公開されています。

### Ruby on Railsリポジトリをクローンする

Ruby on Railsのソースコードを置きたいディレクトリ (そこに`rails`ディレクトリが作成されます) で以下を実行します。

```bash
$ git clone https://github.com/rails/rails.git
$ cd rails
```

### 追加のツールやサービスをインストールする

Railsのテストの中には、特定のテストを実行する前にツールをインストールしておく必要が生じるものもあります。

以下は、gemごとの追加の依存関係のリストです。

* Action CableはRedisに依存します。
* Active RecordはSQLite3、MySQL、PostgreSQLに依存します。
* Active StorageはYarn（Yarnはさらに[Node.js](https://nodejs.org/)）、ImageMagick、FFmpeg、muPDFに依存します。macOSの場合はXQuartzとPopplerにも依存します。
* Active SupportはmemcachedとRedisに依存します。
* RailtiesはJavaScriptランタイム環境に依存します（[Node.js](https://nodejs.org/)などのインストールが必要）。

変更するすべてのgemを正しくテストするのに必要なサービスをすべてインストールします。

NOTE: Redisのドキュメントでは、パッケージマネージャによるインストールは、Redisが古くなっていることが多いため行わないよう指示されています。ソースからインストールしてサーバーを立ち上げるのが素直な方法であり、[Redisのドキュメント](https://redis.io/download#installation)にも手順が詳しく記載されています。

NOTE: Active Recordのテストは、少なくともMySQL、PostgreSQL、SQLite3で**パスしなければなりません**。Railsではこれまで多くのパッチが、1つのデータベースアダプタでテストした限りでは問題ないように見えても、さまざまなアダプタごとのわずかな挙動の違いによって却下されてきました。

OSごとの追加ツールのインストール方法については以下の手順をご覧ください。

#### macOSの場合

macOSでは[Homebrew](https://brew.sh/)ですべての追加ツールをインストールできます。

すべてをインストールするには以下を実行します。

```bash
$ brew bundle
```

インストールした各サービスを起動する必要もあります。利用可能なサービスのリストは以下で表示できます。

```bash
$ brew services list
```

続いて、各サービスを以下のように1つずつ起動します。

```bash
$ brew services start mysql
```

上の`mysql`の部分は、起動するサービス名に置き換えてください。

#### Ubuntuの場合

すべてをインストールするには以下を実行します。

```bash
$ sudo apt-get update
$ sudo apt-get install sqlite3 libsqlite3-dev
    mysql-server libmysqlclient-dev
    postgresql postgresql-client postgresql-contrib libpq-dev
    redis-server memcached imagemagick ffmpeg mupdf mupdf-tools

# Yarnのインストール
$ curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
$ echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
$ sudo apt-get install yarn
```

#### FedoraまたはCentOSの場合

すべてをインストールするには以下を実行します。

```bash
$ sudo dnf install sqlite-devel sqlite-libs
    mysql-server mysql-devel
    postgresql-server postgresql-devel
    redis memcached imagemagick ffmpeg mupdf

# Yarnのインストール
# Node.jsがインストールされていない場合はこのコマンドを使う
$ curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
# Node.jsがインストール済みの場合は代わりに以下を実行する
$ curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
$ sudo dnf install yarn
```

#### Arch Linuxの場合

すべてをインストールするには以下を実行します。

```bash
$ sudo pacman -S sqlite
    mariadb libmariadbclient mariadb-clients
    postgresql postgresql-libs
    redis memcached imagemagick ffmpeg mupdf mupdf-tools poppler
    yarn
$ sudo systemctl start redis
```

NOTE: MySQLはArch Linuxでのサポートが終了したため、代わりにMariaDBをインストールする必要があります（[お知らせ](https://www.archlinux.org/news/mariadb-replaces-mysql-in-repositories/)を参照）。

#### FreeBSDの場合

すべてをインストールするには以下を実行します。

```bash
# pkg install sqlite3
    mysql80-client mysql80-server
    postgresql11-client postgresql11-server
    memcached imagemagick ffmpeg mupdf
    yarn
# portmaster databases/redis
```

あるいはportsですべてをインストールします（これらのパッケージは`database`フォルダの下に置かれます）。

NOTE: MySQLのインストール中に問題が発生した場合は、[このMySQLドキュメント](https://dev.mysql.com/doc/refman/8.0/en/freebsd-installation.html)を参照してください。

### データベースを設定する

Active Recordをテストするのに必要なデータベースエンジンを設定するにはさらにいくつかの手順が必要です。

MySQLでテストスイートを実行できる状態にするには、testデータベースで`rails`という名前の特権付きユーザーを作成する必要があります。

```bash
$ mysql -uroot -p

mysql> CREATE USER 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest2.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON inexistent_activerecord_unittest.*
       to 'rails'@'localhost';
```

PostgreSQLの認証方法は異なります。LinuxやBSDのdevelopment環境で開発用アカウントをセットアップするには、以下を実行する必要があります。

```bash
$ sudo -u postgres createuser --superuser $USER
```

macOSの場合は以下を実行します。

```bash
$ createuser --superuser $USER
```

続いて、MySQLとPostgreSQLでtestデータベースを作成するために以下を実行します。

```bash
$ cd activerecord
$ bundle exec rake db:create
```

NOTE: PostgreSQL 9.1.x以前では、HStore拡張を有効にする途中で"WARNING: => is deprecated as an operator"という警告が表示されます。

データベースエンジンごとにtestデータベースを作成することもできます。

```bash
$ cd activerecord
$ bundle exec rake db:mysql:build
$ bundle exec rake db:postgresql:build
```

以下を実行すればデータベースを削除できます。

```bash
$ cd activerecord
$ bundle exec rake db:drop
```

NOTE: rakeタスクでデータベースを作成する前に、文字セットやコレーション（collation: 照合順序）が正しく設定されていることを確認してください。

別のデータベースを使う場合は、`activerecord/test/config.yml`ファイルか`activerecord/test/config.example.yml`ファイルでデフォルトの接続情報をチェックします。必要であれば`activerecord/test/config.yml`を編集して別のcredentialを設定することもできますが、当然ながらそうした変更をRailsリポジトリにpushすべきではありません。

### JavaScriptの依存関係をインストールする

Yarnがインストール済みの場合は、以下の方法でJavaScriptの依存関係をインストールする必要があります。

```bash
$ yarn install
```

### Bundler gemをインストールする

以下の手順で[Bundler](https://bundler.io/)の最新バージョンを入手します。

```bash
$ gem install bundler
$ gem update bundler
```

続いて以下を実行します。

```bash
$ bundle install
```

あるいは以下を実行します。

```bash
$ bundle install --without db
```

（Active Recordのテストを実行する必要がない場合）

### Railsに貢献する

セットアップが完了したら、[Ruby on Rails に貢献する方法](contributing_to_ruby_on_rails.html#ローカルブランチでアプリケーションを実行する)ガイドをお読みください。
