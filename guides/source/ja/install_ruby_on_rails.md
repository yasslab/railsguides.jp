Ruby on Rails インストールガイド
===========================

本ガイドでは、Rubyプログラミング言語とRailsフレームワークをOS（オペレーティングシステム）にインストールする手順を説明します。

OSにはRubyがプリインストールされている場合もありますが、最新でないことが多いうえに、アップグレードできないようになっています。[Mise](https://mise.jdx.dev/getting-started.html)などのバージョン管理ソフトウェアを使うことで、最新バージョンのRubyをインストールできるようになり、アプリごとに異なるバージョンのRubyを使い分けることも、新しいバージョンがリリースされたときのアップグレードも手軽に行えるようになります。

Dockerが使える環境であれば、自分のコンピュータにRubyやRailsを直接インストールせずに、Dev Container環境内でRailsを実行することも可能です。詳しくは[Dev Containerでの開発ガイド](getting_started_with_devcontainer.html)を参照してください。

--------------------------------------------------------------------------------

## OSごとのRubyインストール方法

今使っているOSに応じて、以下のセクションを参照してください。

* [macOS](#macosにrubyをインストールする)
* [Ubuntu](#ubuntuにrubyをインストールする)
* [Windows](#windowsにrubyをインストールする)

TIP: `$`で始まるコマンドはターミナルで実行する必要があります。

TIP: 訳注: ブラウザ上で動かせるクラウドIDE「GitHub Codespaces」を使った環境構築については、本ガイド下部にある「[参考資料 (日本語)](#参考資料（日本語）) をご参照ください。

### macOSにRubyをインストールする

これらの手順を実行するには、macOS Catalina 10.15以降が必要です。

macOSでRubyをコンパイルするために必要な依存関係をインストールするには、Xcode Command Line ToolsとHomebrewが必要です。

ターミナルを開いて、次のコマンドを実行します。

```shell
# Xcode Command Line Toolsをインストールする
$ xcode-select --install

# Homebrewと依存関係をインストールする
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
$ echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
$ source ~/.zshrc
$ brew install openssl@3 libyaml gmp rust

# Miseバージョンマネージャをインストールする
$ curl https://mise.run | sh
$ echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.zshrc
$ source ~/.zshrc

# MiseでRubyをグローバルにインストールする
$ mise use -g ruby@3
```

### UbuntuにRubyをインストールする

これらの手順を実行するには、Ubuntu Jammy 22.04以降が必要です。

ターミナルを開き、次のコマンドを実行します。

```bash
# aptで依存関係をインストールする
$ sudo apt update
$ sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev

# Miseバージョンマネージャをインストールする
$ curl https://mise.run | sh
$ echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.bashrc
$ source ~/.bashrc

# MiseでRubyをグローバルにインストールする
$ mise use -g ruby@3
```

### WindowsにRubyをインストールする

[Windows Subsystem for Linux（WSL）][WSL]は、WindowsでのRuby on Rails開発に最適なエクスペリエンスを提供します。WSLではWindows内でUbuntuを実行するため、production（本番）環境でサーバーが実行される環境に近い環境で作業できます。

Windows 11、またはWindows 10バージョン 2004 以降（ビルド 19041 以降）が必要です。

PowerShell（またはWindowsコマンドプロンプト）を開いて、以下を実行します。

```bash
$ wsl --install --distribution Ubuntu-24.04
```

インストールプロセス中に再起動を求められる場合があります。

インストールが終わると、スタートメニューからWSLのUbuntuを開けるようになります。プロンプトが表示されたら、Ubuntuユーザーのユーザー名とパスワードを入力します。

続いて、以下のコマンドを実行します。

```bash
# aptで依存関係をインストールする
$ sudo apt update
$ sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev

# Miseバージョンマネージャをインストールする
$ curl https://mise.run | sh
$ echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
$ source ~/.bashrc

# MiseでRubyをグローバルにインストールする
$ mise use -g ruby@3
```

[WSL]:
  https://ja.wikipedia.org/wiki/Windows_Subsystem_for_Linux

Rubyがインストールされたことを確認する
---------------------------

Rubyがインストールされたら、以下のコマンドを実行して動作を確認できます。

```bash
$ ruby --version
ruby 3.3.6
```

Railsをインストールする
----------------

Rubyの「gem」とは、RubyのライブラリであるRubyプログラムの自己完結型パッケージです。Rubyの`gem`コマンドを使うことで、[RubyGems.org](https://rubygems.org)から最新バージョンのRailsと依存関係をインストールできます。

以下のコマンドを実行して最新のRailsをインストールし、ターミナルで使えるようにします。

```bash
$ gem install rails
```

Railsが正しくインストールされていることを確認するには、以下のコマンドを実行するとバージョン番号が表示されます。

```bash
$ rails --version
Rails 8.0.0
```

NOTE: `rails`コマンドが見つからない場合は、ターミナルを再起動してみてください。

以上で、RubyとRailsのインストールは完了です。[Railsをはじめよう](getting_started.html)に進みましょう！
