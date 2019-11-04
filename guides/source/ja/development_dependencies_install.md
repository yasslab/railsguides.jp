**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Rails コア開発環境の構築方法
================================

本ガイドでは、Ruby on Rails自体の開発環境を構築する方法について解説します。

このガイドの内容:

* 自分のPCをRails開発用にセットアップする方法
* Railsのテストスイートの中から特定のグループを実行する方法
* RailsテストスイートのうちActive Recordに関する部分の動作

--------------------------------------------------------------------------------

おすすめの方法
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

### セットアップとテストを行う

リポジトリに送信されるコードは、テストスイートにパスしなければなりません。自分でパッチを書いた場合や、他の人が書いたパッチを詳しく評価する場合にも、テストを実行できるようにしておく必要があります。

最初にSQLite3をインストールし、`sqlite3` gem用のSQLite3開発ファイルもインストールします。macOSの場合は以下を実行します。

```bash
$ brew install sqlite3
```

Ubuntuなら以下で行えます。

```bash
$ sudo apt-get install libsqlite3x libsqlite3x-devel
```

FedoraやCentOSの場合は以下を実行します。

```bash
$ sudo yum install sqlite3 sqlite3-devel
```

Arch Linuxなら以下を実行する必要があります。

```bash
$ sudo pacman -S sqlite
```

FreeBSDの場合は以下を実行します。

```bash
# pkg install sqlite3
```

あるいは`databases/sqlite3`のportsをコンパイルします。

[Bundler](https://bundler.io/)の最新バージョンを入手します。

```bash
$ gem install bundler
$ gem update bundler
```

続いて以下を実行します。

```bash
$ bundle install --without db
```

このコマンドによって、MySQLとPostgreSQL用のRubyドライバを除いて必要なファイルがすべてインストールされます。続きは後ほど行います。

NOTE: memcachedを使用するテストを実行したい場合は、memcachedがインストールされ、実行可能であることを確認する必要があります。

macOSの場合、[Homebrew](https://brew.sh/)を使ってmemcachedをインストールできます。

```bash
$ brew install memcached
```

Ubuntuの場合はapt-getを使用できます。

```bash
$ sudo apt-get install memcached
```

FedoraやCentOSの場合はyumを使用します。

```bash
$ sudo yum install memcached
```

Arch Linuxの場合は以下のようにします。

```bash
$ sudo pacman -S memcached
```

FreeBSDの場合は以下のようにします。

```bash
# pkg install memcached
```

あるいは`databases/memocached`のportsをコンパイルすることもできます。

依存ファイルのインストールがこれで終わったので、以下のコマンドでテストスイートを実行します。

```bash
$ bundle exec rake test
```

Action Packなど、特定のコンポーネントのテストだけを実行することもできます。該当のディレクトリに移動して同じコマンドを実行します。

```bash
$ cd actionpack
$ bundle exec rake test
```

特定のディレクトリにあるテストを実行したい場合、`TEST_DIR`環境変数を指定できます。たとえば、`railties/test/generators`ディレクトリのテストだけを実行したい場合は以下のようにします。

```bash
$ cd railties
$ TEST_DIR=generators bundle exec rake test
```

以下の方法で特定のテストだけを実行することもできます。

```bash
$ cd actionpack
$ bundle exec ruby -Itest test/template/form_helper_test.rb
```

特定のファイルに含まれるひとつのテストだけを実行するには以下のようにします。

```bash
$ cd actionpack
$ bundle exec ruby -Itest path/to/test.rb -n test_name
```

### Railtiesをセットアップする

Railtiesテストの一部はJavaScriptランタイム環境に依存しています（[Node.js](https://nodejs.org/)をインストールする前提など）。

### Active Recordをセットアップする

Active Recordのテストスイートの実行は3回試みられます。SQLite3で1回、MySQLで1回、PostgreSQLで1回です。それぞれについて環境構築方法を解説します。

WARNING: Active Recordのコードに手を付ける場合、最低でもMySQL、PostgreSQL、SQLite3のテストにはすべてパスしなければなりません。MySQLでしかテストを行なっていないようなパッチは、一見問題なさそうに見えても、さまざまなアダプタごとの微妙な違いに対応しきれていないことが非常に多く、ほとんどの場合受理されません。

#### データベースの設定

Active Recordテストスイートでは、`activerecord/test/config.yml`というカスタム設定ファイルが必要です。設定例は`activerecord/test/config.example.yml`に記載されているので、これをコピーして各環境で使用できます。

#### MySQLとPostgreSQL

MySQLとPostgreSQLに対してテストスイートを実行できるようにするには、そのためのgemも必要です。最初にサーバーをインストールし、次にクライアントライブラリをインストール、そして開発用ファイルをインストールします。

macOSの場合、以下を実行できます。

```bash
$ brew install mysql
$ brew install postgresql
```

詳しくはHomebrewのヘルプを参照してください。

Ubuntuの場合は以下を実行します。

```bash
$ sudo apt-get install mysql-server libmysqlclient-dev
$ sudo apt-get install postgresql postgresql-client postgresql-contrib libpq-dev
```

FedoraやCentOSの場合は以下を実行します。

```bash
$ sudo yum install mysql-server mysql-devel
$ sudo yum install postgresql94-server postgresql94-devel
```

Arch LinuxではMySQLがサポート対象外になったため、MariaDBを代わりに使用します (詳細は[MariaDB replaces MySQL in repositories](https://www.archlinux.org/news/mariadb-replaces-mysql-in-repositories/)を参照)。

```bash
$ sudo pacman -S mariadb libmariadbclient mariadb-clients
$ sudo pacman -S postgresql postgresql-libs
```

FreeBSDの場合は以下を実行する必要があります。

```bash
# pkg install mysql56-client mysql56-server
# pkg install postgresql93-client postgresql93-server
```

Portsを使用してインストールすることもできます (`databases`フォルダの下に置かれます)。
MySQLのインストール中に問題が生じた場合は、[MySQLドキュメント](http://dev.mysql.com/doc/refman/5.1/en/freebsd-installation.html) (英語) を参照してください。

以上の設定が終わったら、以下を実行します。

```bash
$ rm .bundle/config
$ bundle install
```

最初に、`.bundle/config`を削除します。これは、インストールしたくない"db"グループのファイルをBundlerが覚えてしまっているのを消去するためです。ファイルを削除する代わりに編集しても構いません。

MySQLでテストスイートを実行できるようにするには、データベースに`rails`というユーザーアカウントを作成し、このアカウントにtestデータベースへのアクセス権を与える必要があります。

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

続いてtestデータベースを作成します。

```bash
$ cd activerecord
$ bundle exec rake db:mysql:build
```

PostgreSQLでは認証方法が異なります。LinuxやBSDでdevelop環境にdevelopmentアカウントを設定するには、以下を実行します。

```bash
$ sudo -u postgres createuser --superuser $USER
```

macOSの場合は以下を実行します。

```bash
$ createuser --superuser $USER
```

続いて以下を実行してtestデータベースを作成します。

```bash
$ cd activerecord
$ bundle exec rake db:postgresql:build
```

PostgreSQLとMySQLの両方を使用するデータベースをビルドすることもできます。

```bash
$ cd activerecord
$ bundle exec rake db:create
```

データベースを消去(drop)するには以下を実行します。

```bash
$ cd activerecord
$ bundle exec rake db:drop
```

NOTE: testデータベースの作成にはRakeタスクを使用してください。これにより、文字セットと照合順序が正しく設定されます。

NOTE: PostgreSQL 9.1.x 以前のHStore拡張機能を有効にしようとすると次のような警告 (メッセージはローカライズされることもあります) が表示されます: 「WARNING: => is deprecated as an operator」

他のデータベースを採用する場合は、`activerecord/test/config.yml`や`activerecord/test/config.example.yml`にデフォルトの接続情報があることをチェックしてください。必要であれば`activerecord/test/config.yml`を編集して、認証情報を別のものに変更することもできます。ただし、この臨時の認証情報をRailsのリポジトリに反映しないよう気を付けてください。

### Action Cableのセットアップ

Action CableではデフォルトのサブスクリプションアダプタとしてRedisを用います（[詳細](action_cable_overview.html#ブロードキャスト)）。このため、Action CableのテストがパスするにはRedisをインストールして実行中にしておく必要があります。

#### Redisをソースからインストールする

Redisのドキュメントに記載されている、パッケージマネージャによるインストール方法は古いものが多い点が残念です。ソースからインストールしてサーバーを立ち上げる方式の方が単純明快であり、[Redisのドキュメント](https://redis.io/download#installation)にも詳しく記載されています。

#### Redisをパッケージマネージャでインストールする

macOSの場合は以下を実行できます。

```bash
$ brew install redis
```

後はHomebrewが表示する指示に従って進めます。

Ubuntuの場合は以下を実行するだけで完了します。

```bash
$ sudo apt-get install redis-server
```

FedoraまたはCentOSの場合は以下を実行します（EPELを有効にする必要があります）。

```bash
$ sudo yum install redis
```

Arch Linuxを実行している場合は、以下を実行します。

```bash
$ sudo pacman -S redis
$ sudo systemctl start redis
```

FreeBSDユーザーは以下を実行しなければなりません。

```bash
# portmaster databases/redis
```

### Active Storageのセットアップ

Active Storageを使う場合、コードベースのセクションで使われているJavaScript依存関係のインストールが必要である点を押さえておくことが重要です。依存関係をインストールするには、YarnというNode.jsパッケージマネージャをシステムで使えるようにしておく必要があります。このパッケージをインストールするには、あらかじめ[Node.js](https://nodejs.org)をインストールしておく必要があります。

macOSでは以下を実行できます。

```bash
brew install yarn
```

Ubuntuでは以下を実行できます。

```bash
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update && sudo apt-get install yarn
```

FedoraまたはCentOSの場合は以下を実行します。

```bash
sudo wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo

sudo yum install yarn
```

Yarnのインストールが終わったら、最後に`activestorage`ディレクトリの下で以下のコマンドを実行して、依存関係をインストールする必要があります。

```bash
yarn install
```
