Rails コア開発環境の構築方法
================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Development Dependencies Install](https://guides.rubyonrails.org/development_dependencies_install.html)を日本語に翻訳した文書です。

本ガイドでは、Ruby on Rails自体の開発環境を構築する方法について解説します。

このガイドの内容:

* 自分のPCをRails開発用にセットアップする方法
* Railsのテストスイートの中から特定のグループを実行する方法
* RailsテストスイートのうちActive Recordに関する部分の動作

--------------------------------------------------------------------------------

すぐできる方法
------------

[Rails development box][dev-box]にある準備済みのdevelopment環境を入手するのがおすすめです。

[dev-box]: https://github.com/rails/rails-dev-box

個別にインストールする方法
------------

Rails development boxを利用できない事情がある場合は、この先をお読みください。Ruby on Railsコア開発で必要なdevelopment boxを手動でビルドする手順を解説します。

### Gitをインストールする

Ruby on Railsではソースコード管理にGitを使っています。インストール方法については[Gitホームページ][git-scm]に記載されています。Gitを学べる以下のような多数の資料があります（特記ないものは英語）。

* [Try Git course][]は、対話的な操作のできるコースで基礎を学べます。
* [Git公式ドキュメント][Git docs]には多くの情報がまとめられており、Gitの基礎を学べる動画もあります。
* [Everyday Git][]は最小限必要なGitの知識を学ぶのに向いています。
* [GitHub][GItHub support]にはさまざまなGit関連リソースへのリンクがあります。
* [Pro Git日本語版][Pro Git]ではGitについてすべてをカバーした書籍がさまざまな形式で翻訳されており、クリエイティブ・コモンズ・ライセンスで公開されています。

[git-scm]: https://git-scm.com/
[Try Git course]: https://docs.github.com/ja/get-started/quickstart/set-up-git
[Git docs]: https://git-scm.com/book/ja/
[Everyday Git]: https://schacon.github.io/git/everyday.html
[GitHub support]: https://support.github.com/
[Pro Git]: https://progit-ja.github.io/

### Ruby on Railsリポジトリをクローンする

Ruby on Railsのソースコードを置きたいディレクトリ（`rails`ディレクトリが作成される場所）で以下を実行します。

```bash
$ git clone https://github.com/rails/rails.git
$ cd rails
```

### 追加のツールやサービスをインストールする

Railsのテストの中には追加のツールに依存しているものもあります。そうしたテストを実行するには、これらのツールを手動でインストールしておく必要があります。

以下のリストは、Railsのgemごとに必要な追加の依存関係です。

* Action Cable: Redisに依存
* Active Record: SQLite3、MySQL、PostgreSQLに依存
* Active Storage: Yarn（Yarnは[Node.js][]に依存）、ImageMagick、FFmpeg、muPDF、またmacOSではXQuartzとPopplerにも依存
* Active Support: memcached、Redisに依存
* Railties: JavaScriptランタイム環境（[Node.js][]など）に依存

機能を変更したいgemを正しくテストするには、そのgemが依存するサービスをすべてインストールする必要があります。

NOTE: Redisのドキュメントでは、パッケージマネージャによるRedisインストールは推奨されていません（パッケージマネージャーが古いため）。Redisをソースからインストールしてサーバーを立ち上げる方法については、[Redisドキュメント][Redis install]に詳しく記載されています。

NOTE: Active Recordのテストは、少なくともMySQLとPostgreSQLとSQLite3で**必ず**パスしなければなりません。アダプタごとに微妙な違いがあるので、特定のアダプタではテストがパスしたパッチの多くが却下されています。

以下は、OSごとの追加ツールのインストール方法です。

[Node.js]: https://nodejs.org/
[Redis install]: https://redis.io/download#installation

#### macOS

macOSの場合は、必要な追加ツールを[Homebrew][]ですべてインストールできます。

ツールをすべてインストールするには、クローンしたRailsディレクトリで以下を実行します。

```bash
$ brew bundle
```

インストールしたサービスを起動する必要もあります。サービスをすべて起動するには以下を実行します。

```bash
$ brew services list
```

サービスを個別に起動するには、以下のように実行します。

```bash
$ brew services start mysql
```

上のコマンドの`mysql`は、起動したいサービス名に置き換えます。

[Homebrew]: https://brew.sh/

#### Ubuntu

以下を実行すると、すべてのツールをインストールできます。

```bash
$ sudo apt-get update
$ sudo apt-get install sqlite3 libsqlite3-dev mysql-server libmysqlclient-dev postgresql postgresql-client postgresql-contrib libpq-dev redis-server memcached imagemagick ffmpeg mupdf mupdf-tools libxml2-dev libvips42

# Yarnをインストールする
$ curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
$ echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
$ sudo apt-get install yarn
```

#### FedoraまたはCentOS

以下を実行すると、すべてのツールをインストールできます。

```bash
$ sudo dnf install sqlite-devel sqlite-libs mysql-server mysql-devel postgresql-server postgresql-devel redis memcached imagemagick ffmpeg mupdf libxml2-devel

# Yarnをインストールする
# Node.jsをインストールしていない場合はこのコマンドを使う
$ curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
# Node.jsをインストール済みの場合は代わりにこのコマンドを使う
$ curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
$ sudo dnf install yarn
```

#### Arch Linux

以下を実行すると、すべてのツールをインストールできます。

```bash
$ sudo pacman -S sqlite mariadb libmariadbclient mariadb-clients postgresql postgresql-libs redis memcached imagemagick ffmpeg mupdf mupdf-tools poppler yarn libxml2
$ sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
$ sudo systemctl start redis mariadb memcached
```

NOTE: MySQLはArch Linuxではサポートされなくなったので、代わりにMariaDBをインストールする必要があります（[Arch Linuxのお知らせ][announcement]を参照）。

[announcement]: https://www.archlinux.org/news/mariadb-replaces-mysql-in-repositories/

#### FreeBSD

以下を実行すると、すべてのツールをインストールできます。

```bash
$ pkg install sqlite3 mysql80-client mysql80-server postgresql11-client postgresql11-server memcached imagemagick ffmpeg mupdf yarn libxml2
# portmaster databases/redis
```

`ports`ですべてのツールをインストールすることも可能です（パッケージは`databases`フォルダに保存されます）。

NOTE: MySQLのインストールで発生する問題については、[MySQLドキュメント][MySQL doc]を参照してください。

[MySQL doc]: https://dev.mysql.com/doc/refman/8.0/ja/freebsd-installation.html

### データベースを設定する

Active Recordのテストを実行するのに必要なデータベースエンジンごとに、追加の設定手順がいくつか必要になります。

MySQLでテストスイートを実行可能にするには、testデータベースに`rails`という名前の特権ユーザーを追加する必要があります。

```sql
$ mysql -uroot -p

mysql> CREATE USER 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest2.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON inexistent_activerecord_unittest.*
       to 'rails'@'localhost';
```

PostgreSQLの認証方法は異なります。LinuxまたはBSDで、開発用アカウントをdevelopment環境にセットアップするには、以下を実行するだけで済みます。

```bash
$ sudo -u postgres createuser --superuser $USER
```

macOSの場合は以下です。

```bash
$ createuser --superuser $USER
```

続いて、MySQLとPostgreSQLそれぞれについて以下を実行し、testデータベースを追加する必要があります。

```bash
$ cd activerecord
$ bundle exec rake db:create
```

NOTE: PostgreSQL 9.1.x以前でHStore拡張を有効にすると、"WARNING: => is deprecated as an operator"という警告が表示されます（メッセージはローカライズされる可能性もあります）。

以下を実行すると、データベースエンジンごとにtestデータベースを作成できます。

```bash
$ cd activerecord
$ bundle exec rake db:mysql:build
$ bundle exec rake db:postgresql:build
```

データベースを削除するには以下を実行します。

```bash
$ cd activerecord
$ bundle exec rake db:drop
```

NOTE: 上のrakeタスクでtestデータベースを作成すると、文字セットとコレーション（照合順序）が正しく設定されます。

他のデータベースを使っている場合は、`activerecord/test/config.yml`または`activerecord/test/config.example.yml`でデフォルトの接続情報があるかどうかをチェックしてください。別のcredential（認証情報）が必要な場合は`activerecord/test/config.yml`を変更することでできますが、この変更はRailsの更新に含めるべきではありません。

### JavaScriptの依存関係をインストールする

Yarnをインストールした場合は、以下を実行してJavaScriptの依存関係をインストールする必要があります。

```bash
$ yarn install
```

### Bundler gemをインストールする

[Bundler][]の最新バージョンをインストールします。

```bash
$ gem install bundler
$ gem update bundler
```

次に以下を実行します。

```bash
$ bundle install
```

または、Active Recordのテストを実行する必要がない場合は、以下を実行します。

```bash
$ bundle install --without db
```

### Railsに貢献する

設定がすべて完了したら、ガイドの[Ruby on Rails に貢献する](contributing_to_ruby_on_rails.html#ローカルブランチでアプリケーションを実行する)をお読みください。

[Bundler]: https://bundler.io/