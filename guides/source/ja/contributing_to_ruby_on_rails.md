Ruby on Rails に貢献する方法
=============================

本ガイドでは、Ruby on Railsの開発に**あなた**が参加する方法について説明します。

このガイドの内容:

* GitHubでissueをレポートする方法
* mainブランチをcloneしてテストスイートを実行する方法
* 既存のissueを解決する方法
* Ruby on Railsのドキュメントに貢献する方法
* Ruby on Railsのコードに貢献する方法

Ruby on Railsは、「どこかで誰かがうまくやってくれているフレームワーク」ではありません。Ruby on Railsには、長年に渡って数千人もの開発者が貴重な貢献を行っています。貢献の内容は、わずか1文字の修正から、大規模なアーキテクチャ変更、重要なドキュメント作成まで多岐に渡ります。これらの作業はいずれも、Ruby on Railsをすべての人々にとってよりよいものにするためです。コードを書いたりドキュメントを作成したりする以外にも、issueの作成やパッチのテストなど、さまざまな方法で貢献できます（訳注: サンプルのコミットメッセージも日本語に翻訳していますが、実際のissueやコミットメッセージは英語で書きます ）。

[RailsのREADME][README]にも記載されているように、Railsのコードベースやサブプロジェクトのコードベースについて、issueトラッカーやチャットルーム、discussionボード、メーリングリストでやり取りする方はすべて、Railsの[行動規範][CoC]に従うことが期待されます。

[README]: https://github.com/rails/rails/blob/main/README.md
[CoC]: https://rubyonrails.org/conduct/

--------------------------------------------------------------------------------


issueを作成する
------------------

Ruby on Railsでは[GitHubのIssueトラッキング][issues]機能でissueをトラッキングしています（issueは、主にバグや新しいコードの貢献に使われます）。Ruby on Railsでバグを見つけたら、そこから貢献を開始できます。GitHubへのissue送信、issueへのコメント、プルリクエストの作成を行うには、まずGitHubアカウント（無料）を作成する必要があります。

NOTE: Ruby on Railsの最新リリースで見つけたバグは最も注目を集める可能性があります。Railsコアチームは、**edge Rails**（開発中のRailsのコード）でのテストに時間を割いてくれる方からのフィードバックも常に歓迎しています。テスティング用にedge Railsを入手する方法については後述します。Railsのどのバージョンがサポートされているかについては、[メンテナンスポリシー][maintenance_policy]を参照してください。セキュリティ関連のissueは、GitHubのissue trackerには絶対に報告しないでください。

[maintenance_policy]: maintenance_policy.html

Railsのどのバージョンがサポートされているかについては、[メンテナンスポリシー](maintenance_policy.html)を参照してください。
セキュリティ問題は、GitHubのissue trackerには絶対に報告しないようご注意ください。

### バグレポートを作成する

Ruby on Railsで何らかの問題を発見し、それがセキュリティ上の問題でなければ、まず[GitHub Issues][issues]を検索して、既にレポートがあがっているかどうかを確認してみましょう。該当する問題がまだissuesにない場合は、[新しいissueを作成][new issue]します。セキュリティ上のissueをレポートする方法については次のセクションで説明します。

issueを作成する際に、フレームワークにバグがあるかどうかを判断するのに必要なすべての情報を含められるように、issueテンプレートを用意しています。各issueには、タイトルと問題の明確な説明を含める必要があります。issueの説明には、期待される動作を示すコードサンプル、失敗するテスト、システム構成など、できるだけ多くの関連情報を含めるようにしてください。他の人たちにとっても自分自身にとっても、バグの再現と修正点の把握がやりやすくなることを目指してください。

地球滅亡レベルの重大な問題でもない限り、issueへの対応はすぐに開始されることもあれば、そうでないこともあります。しかしこれは、私たちがあなたのバグに関心がないわけではなく、多くの問題やプルリクエストを処理しなければならないだけです。同じ問題を抱えている他の人が、あなたのissueを見つけてバグを確認し、あなたと協力して修正することもあります。バグを修正する方法が既にわかっている場合は、先にプルリクエストをオープンしてください。

[issues]: https://github.com/rails/rails/issues
[new issue]: https://github.com/rails/rails/issues/new

### 実行可能なテストケースを作成する

自分のissueを再現する手順を用意しておくと、他の開発者がissueを確認・調査・修正する上で大変役立ちます。そのための方法は、実行可能なテストケースを提供することです。この作業を少しでも楽にするために、Railsチームは以下のバグレポート用テンプレートを多数用意しているので、これを元に作業を開始できます。

* [Active Record（モデル、データベース）issue用テンプレート][main: AR models/db]
* [Active Record（マイグレーション）issue用テンプレート][main: AR migration]
* [Action Pack（コントローラ、ルーティング）issue用テンプレート][main: ActionPack]
* [Active Job issue用テンプレート][main: ActiveJob]
* [Active Storage issue用テンプレート][main: ActiveStorage]
* [Active Mailer issue用テンプレート][main: Action Mailer]
* [Action Mailbox issue用テンプレート][main: ActionMailbox]
* [その他のissue用一般テンプレート][main: generic]

これらのテンプレートには、テストケースをセットアップするための定型コードが含まれています。該当するテンプレートの内容を`.rb`ファイルにコピーして、issueを実証するのに必要な変更を加えてください。作成したテストケースは、ターミナルで`ruby the_file.rb`を実行すると実行できます。すべてがうまくいけば、テストケースが失敗することがわかります。

続いて、この実行可能テストケースをGitHubの[gist][]で共有するか、issueの説明に貼り付けてください。

[main: AR models/db]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/active_record.rb

[main: AR migration]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/active_record_migrations.rb

[main: ActionPack]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/action_controller.rb

[main: ActiveJob]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/active_job.rb

[main: ActiveStorage]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/active_storage.rb

[main: Action Mailer]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/action_mailer.rb

[main: ActionMailbox]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/action_mailbox.rb

[main: generic]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/generic.rb

[gist]: https://gist.github.com


### セキュリティissueの特殊な取り扱い方法について

WARNING: セキュリティ脆弱性に関する問題は、一般公開されているGitHubのissueレポート機能には「**絶対に掲載しないでください**」。セキュリティ関連のissueを扱う方法について詳しくは、[Railsセキュリティポリシーページ][security policy]（英語）を参照してください。

[security policy]: https://rubyonrails.org/security

### 機能リクエストについて

GitHub Issuesは「機能リクエスト」の場ではありません。Ruby on Railsで欲しい機能があれば、自分でコードを書くか、誰かにお願いしてコードを書いてもらってください（Ruby on Rails用のパッチを提案する方法については後述します）。GitHub Issuesにこのような「欲しい機能リスト」をコードも添えずに書き込んでも、Issueをチェックした人によって早晩「無効」とマーキングされて終わるでしょう。

その一方、「バグ」と「機能」は簡単に線引きできないこともあります。一般に、「機能」はアプリケーションに新しい振る舞いを追加するものであり、「バグ」は既存の振る舞いが期待どおりでないことを示します。場合によってはコアチームがバグか機能かを審査する必要もあるでしょう。とはいうものの、バグか機能かの違いは、送られたパッチをどのリリースに反映するかという扱いの違いでしかないことがほとんどです（バグ修正は早めにリリースされ、機能追加はメジャーリリースで反映されるなど）。私たちは、修正パッチと同様に機能追加も大歓迎しています。送っていただいた機能追加をメンテナンス用ブランチに押し込めておしまいにすることはしません。

機能追加用のパッチを送信する前に自分のアイデアに意見を募りたい場合は、最初にdiscuss.rubyonrails.orgというSNSの[rubyonrails-core][]に投稿してみてください。もし反応がなければ自分のアイデアに誰も関心を持っていないことがわかりますし、自分のアイデアに興味を示した人が反応する可能性もあります。場合によっては「残念ながら採用できません」という返信があるかもしれません。しかしこのSNSこそ、そうしたアイデアについて議論するための場所なのです。逆にGitHubのissueは、こうした新しいアイデアで必要な議論（ときには長期かつ複雑になることもあるでしょう）を行う場としては不向きです。

[rubyonrails-core]: https://discuss.rubyonrails.org/c/rubyonrails-core

既存のissueの解決を手伝う
----------------------------------

issueをレポートする以外に、既存のissueにコメントすることも、コアチームによるissue解決の助けになります。Railsのコア開発経験が初めての方にとっては、コメント追加はRailsのコードベースや問題解決の手順に慣れる良い機会にもなるでしょう。

GitHub Issuesにあがっている[issueリスト][issues]を見てみると、注目を集めているissueがたくさん見つかります。自分も何かissueに貢献できる方法はあるでしょうか。もちろんあります。しかもさまざまな方法があります。

### バグレポートの確認

貢献の第一歩として、バグレポートを検証する作業も非常に有用です。issueを自分のコンピュータで再現できるかどうかを試し、問題をうまく再現できたら、そのことをissueのコメントに追加しましょう。

issueにあいまいな点があるなら、どこがわかりにくいかをコメントで伝えましょう。バグを再現するうえで有用な情報を追加したり、不要な手順を削減したりするのも重要な貢献です。

テストが添えられていないバグレポートを見かけたら貢献のチャンスです。「失敗する」テストを作成して貢献できますし、既存のテストファイルを詳しく読むことでテストの書き方も学べるので、Railsのソースコードを深く調べる絶好の機会となります。作成するテストは「パッチ」の形式で投稿するのがベストです。詳しくは[Railsのコードに貢献する](/contributing_to_ruby_on_rails.html#railsのコードに貢献する)で後述します。

バグレポートをより簡潔でわかりやすく、現象をなるべく楽に再現できる形にする作業は、バグを修正する開発者にとって大きな助けになります。たとえあなたが最終的にコードを書かなくても、バグレポートが改善されればそれだけで大きな貢献になります。

### パッチをテストする

GitHubからRuby on Railsに送信されたプルリクエスト（pull request、PR、プルリクとも）を検査することも大きな助けになります。寄せられた修正を適用するには、まず以下のように専用のブランチを作成します。

```bash
$ git checkout -b testing_branch
```

続いて、このリモートブランチを使ってコードベースを更新します。たとえばJohnSmithという名前のGitHubユーザーが、Railsをforkして`https://github.com/JohnSmith/rails`の"orange"というトピックブランチにpushする場合は、以下を実行します。

```bash
$ git remote add JohnSmith https://github.com/JohnSmith/rails.git
$ git pull JohnSmith orange
```

あるいは、相手のリモートを自分のチェックアウトに追加する代わりに、[GitHub CLI tool][GitHubCLI]で相手のプルリクエストをチェックアウトすることも可能です。

ブランチを適用したらテストしてみます。次のような点に注意しながら進めましょう。

* 修正は本当に有効か。
* このテストでみんなが幸せになれるか。テストの内容を自分で理解できているか。足りないテストはないか。
* ドキュメントの記載は適切か。ドキュメントも更新する必要があるか。
* 自分の実装がよいと思えるか。同じ変更をより高速な方法やよい良い方法で実装できないか。

プルリクエストの変更内容がよさそうだと思えたら、気づいた点をGitHubのissueに何らかの形でコメントしましょう。コメントを追加するときは、「この変更はよい」と、どの変更点がよいと思うかをなるべく具体的に述べておきましょう。たとえば次のようにコメントします。

>I like the way you've restructured that code in generate_finder_sql - much nicer.（generate_finder_sqlのコードが非常によい形で再構築されている点がよいと思います）The tests look good too.（テストもよく書けているようです）

単に「+1」だけのコメントを書く人を見かけますが、これでは他のレビュアーにほとんど注目されないでしょう。あなたが十分時間をかけてプルリクエストを読んだことが伝わるようにコメントを書きましょう。

[GitHubCLI]: https://cli.github.com/

Railsのドキュメントに貢献する
---------------------------------------

Ruby on Railsには2種類のドキュメントがあります。1つはこの「Railsガイド」であり、Ruby on Railsを学ぶためのドキュメントです。もう1つはAPIドキュメントであり、こちらはリファレンス用です。

RailsガイドやAPIリファレンスは以下のような形で改善できます。

- 内容の整合性を高め、矛盾を解消する
- 読みやすく書き直す
- 不足している情報を追加する
- 事実と異なる内容を修正する
- タイポを修正する
- 最新のedge Railsに対応する

英語ドキュメントに貢献したい方は、Railsガイドの[英語ソースファイル][guides source]を変更してから、プルリクエストでmainブランチに変更の反映を依頼してください。
ドキュメント変更のプルリクエストでは、CIビルドの実行を避けるため、プルリクエストのタイトルに`[ci skip]`を含めてください。

プルリクエストをオープンすると、ドキュメントのプレビューがデプロイされ、レビューやコラボレーションを手軽に行えるようになります。プルリクエストページの下部にステータスチェックのリストが表示されるので、`buildkite/docs-preview`を探して[details]をクリックします。

![GitHub rails/railsのプルリクエストのステータスチェック画面](images/docs_preview/status_checks.png)

これで、Buildkiteのビルドページが表示されます。ジョブが成功した場合は、ジョブリストの上に生成されたAPIとガイドへのリンクを含む注釈が表示されます。

![Buildkiteのrails/docs-preview注釈APIとガイドへのリンク](images/docs_preview/annotation.png)

ドキュメント関連で貢献するときは、[API ドキュメント作成のガイドライン](api_documentation_guidelines.html)と[Rails ガイドのガイドライン](ruby_on_rails_guides_guidelines.html)に十分目を通しておいてください。

[guides source]: https://github.com/rails/rails/tree/main/guides/source

Railsガイドの翻訳に貢献する
------------------------

Railsガイドを翻訳するボランティアも歓迎いたします。次の手順に沿って進めます。

* `https://github.com/rails/rails`を自分のGitHubアカウントにforkする。
* 翻訳先の言語名に対応するフォルダをsourceフォルダの下に追加する。たとえばイタリア語の場合は`guides/source/it-IT`フォルダを追加します。
* *guides/source*に置かれているコンテンツファイルをそのフォルダ内にコピーして翻訳する。
* HTMLファイルは**翻訳しないでください**（HTMLファイルは自動生成されます）。

翻訳はRailsリポジトリに送信しないようご注意ください。上述したように、翻訳はforkしたリポジトリで行ってください。ドキュメントのパッチベースによるメンテナンスは、英語でないと継続が難しいためです。

ガイドをHTML形式で生成するには、guidesディレクトリに`cd`して以下を実行します（言語がit-ITの場合）。

```bash
$ BUNDLE_ONLY=default:doc bundle install
$ cd guides/
$ BUNDLE_ONLY=default:doc bundle exec rake guides:generate:html GUIDES_LANGUAGE=it-IT
```

これで、outputディレクトリにガイドが生成されます。

NOTE: redcarpet gemはJRubyでは動きません。

Railsのコードに貢献する
------------------------------

### development環境を構築する

バグレポートを送信して既存の問題解決を手伝ったり、コードを書いてRuby on Railsに貢献したりするためには、ぜひともテストスイートを自分の環境で実行できるようにしておく必要があります。このセクションでは、自分のパソコン上でテスト用の環境を構築する方法について解説します。

#### GitHub Codespacesを使う

GitHub Codespacesを有効にしているOrganization（組織）に属していれば、そのOrganizationにRailsをforkする形でGitHub Codespacesを利用できます。GitHub Codespacesは必要なすべての依存関係で初期化され、すべてのテストを実行可能です。

#### VS Codeリモートコンテナを使う

[Visual Studio Code](https://code.visualstudio.com)と[Docker](https://www.docker.com)がインストールされている場合、[VS Codeのリモートコンテナプラグイン](https://code.visualstudio.com/docs/remote/containers-tutorial)を利用できます。このプラグインは、リポジトリの[`.devcontainer`](https://github.com/rails/rails/tree/main/.devcontainer)設定を読み込んで、Dockerコンテナをローカルでビルドします。

#### Dev Container CLIを使う

または、[Docker](https://www.docker.com)と[npm](https://github.com/npm/cli)がインストールされている場合、[Dev Container CLI](https://github.com/devcontainers/cli)を実行して、コマンドラインから[`.devcontainer`](https://github.com/rails/rails/tree/main/.devcontainer)の設定を利用することも可能です。

```bash
$ npm install -g @devcontainers/cli
$ cd rails
$ devcontainer up --workspace-folder .
$ devcontainer exec --workspace-folder . bash
```

[Organization]: https://docs.github.com/ja/organizations/collaborating-with-groups-in-organizations/about-organizations
[GitHub Codespaces]: https://docs.github.com/ja/codespaces/getting-started/quickstart

[remote_containers_plugin]: https://code.visualstudio.com/docs/remote/containers-tutorial

#### rails-dev-boxを使う

[rails-dev-box][]を用いて作成済みのdevelopment環境を取得することも可能です。ただし、rails-dev-boxで使っているVagrantとVirtual BoxはM1プロセッサでは動きません。

[rails-dev-box]: https://github.com/rails/rails-dev-box

#### ローカルで開発環境を構築する

GitHub Codespacesを利用できない場合は、Railsガイドの[Railsコア開発環境の構築方法](development_dependencies_install.html)を参照してください。依存関係のインストール方法がOSによって異なる可能性があるため、その分手間がかかります。

### Railsリポジトリをクローンする

コードに貢献するには、最初にRailsリポジトリをクローンする必要があります。

```bash
$ git clone https://github.com/rails/rails.git
```

続いて、専用のブランチを作成します。

```bash
$ cd rails
$ git checkout -b my_new_branch
```

このブランチ名はローカルコンピュータの自分のリポジトリ上でしか使われないので、どんなブランチ名でも構いません。このブランチ名がRails Gitリポジトリにそのまま取り込まれることはありません。

### Bundle install

必要なgemをインストールします。

```bash
$ bundle install
```

### ローカルブランチでアプリケーションを実行する

ダミーのRailsアプリケーションで変更をテストする必要がある場合は、`rails new`に`--dev`フラグを追加すると、ローカルブランチを使うアプリケーションが生成されます。

```bash
$ cd rails
$ bundle exec rails new ~/my-test-app --dev
```

`~/my-test-app`で生成されたアプリケーションはローカルブランチのコードを実行します。サーバーを再起動すると、設定の変更をアプリケーションで確認できます。

JavaScriptパッケージについては、以下のように[`yarn link`][]を用いることで、生成されたアプリケーションでローカルブランチをソースにできます。

```bash
$ cd rails/activestorage
$ yarn link
$ cd ~/my-test-app
$ yarn link "@rails/activestorage"
```

[`yarn link`]: https://yarnpkg.com/cli/link

### コードを書く

準備が整ったら、早速コードを書きましょう。自分が書いたコードをRailsに追加するときは、以下の点を心がけてください。

* Railsのスタイルや規約に従うこと。
* Railsで広く使われている規約やヘルパーメソッドを用いること。
* 自分が書いたコードがないと失敗し、あると成功するテストを書くこと。
* 関連するドキュメント、実行例、ガイドなど、コードが影響する部分もすべて更新すること。
* 変更内容が機能の追加・削除・変更の場合は、必ずCHANGELOGにエントリを追加すること（変更がバグフィックスの場合、CHANGELOGエントリは不要です）。

TIP: スタイルなどの表面的な変更や、Railsの安定性・機能・テストのしやすさについて根本部分が改善されない変更は原則として受け付けられません。詳しくは[#13771のコメント][#13771]（英語）を参照してください。

[#13771]: https://github.com/rails/rails/pull/13771#issuecomment-32746700

#### Railsコーディングルールに従う

Railsのコーディングを行う場合は、以下のシンプルなスタイルガイドに従います。

* インデントはスペース2個（Tab文字は使わない）。
* 行末にスペースを置かないこと。空行に不要なスペースを置かないこと。
* `private`や`protected`の直後の行は空行にせず、以降の行はインデントすること。
* ハッシュの記法はRuby 1.9以降の書式を使うこと（`{ :a => :b }`より`{ a: :b }`が望ましい）。
* `and`と`or`よりも`&&`と`||`が望ましい。
* クラスメソッドは`self.method`よりも`class << self`が望ましい。
* 引数はスペースなしの丸かっこ`my_method(my_arg)`で記述すること（丸かっこ+スペース`my_method( my_arg )`や丸かっこなし`my_method my_arg`は使わない）。
* `=`の前後にはスペースを置くこと（`a=b`ではなく`a = b`）。
* テストでは`refute`ではなく`assert_not`を使うこと。
* 単一行ブロックはスペースなし`method{do_stuff}`よりもスペースあり`method { do_stuff }`が望ましい。
* その他、Railsのコードにある既存の書式に従うこと。

上はあくまでガイドラインであり、最適な方法については各自でご判断ください。

その他に、私たちのコーディング規約の一部をコード化するために定義された[RuboCop][]ルールも用いています。プルリクエストを送信する前に、ローカルで変更したファイルで以下のようにRuboCopを実行してください。

```bash
$ bundle exec rubocop actionpack/lib/action_controller/metal/strong_parameters.rb
Inspecting 1 file
.

1 file inspected, no offenses detected
```

[RuboCop]: https://www.rubocop.org/

### ベンチマークを実行する

パフォーマンスに影響する可能性のある変更では、コードのベンチマークを実施して影響の大きさを測定してください。その際、使ったベンチマークスクリプトも結果に添えてください。コミットメッセージにもその旨を明記し、今後別のコントリビューターが必要に応じてその結果をすぐ見つけて検証や決定を行えるようにしましょう（たとえば、今後Ruby VMの最適化が行われれば、現在の最適化の一部が不要になることも考えられます）。

特定のケースに限ってパフォーマンスを最適化すると、他の一般的なケースでパフォーマンスが低下することがよくあります。したがって、productionアプリケーションで実際に得られた代表的なケースをひととおり網羅したリストに対して変更をテストすべきです。

[ベンチマーク用のテンプレート][benchmark template]を元にベンチマークを作るとよいでしょう。このテンプレートには、[benchmark-ips][] gemを用いてベンチマークを設定するコードテンプレートが含まれており、スクリプト内にインライン記述可能な、比較的自己完結的なテストを念頭に設計されています。

[benchmark template]: https://github.com/rails/rails/blob/main/guides/bug_report_templates/benchmark.rb
[benchmark-ips]: https://github.com/evanphx/benchmark-ips

### テストを実行する

Railsには、変更をプッシュするときにテストスイートをフル実行する規約はありません。特に、[rails-dev-box][]で推奨されているワークフローを用いてソースコードを`/vagrant`にマウントすると、railtiesのテストに時間がかかります。

現実的な妥協案として、作成したコードによって影響が生じるかどうかをテストしましょう。railtiesで変更が発生していない場合は、影響を受けるコンポーネントのすべてのテストスイートを実行しましょう。すべてのテストがパスすれば、それだけで貢献を提案できます。Railsでは、他の箇所で生じた予想外のエラーを検出するために[Buildkite][]を利用しています。

[Buildkite]: https://buildkite.com/rails/rails

#### Rails全体のテストを実行する

すべてのテストを実行するには以下のようにします。

```bash
$ cd rails
$ bundle exec rake test
```

#### 特定のコンポーネントのテストを実行する

Action Packなど、特定のコンポーネントのテストのみを実行することも可能です。たとえば、Action Mailerの場合は以下を実行します。

```bash
$ cd actionmailer
$ bin/test
```

#### 特定のディレクトリのテストを実行する

特定のコンポーネントの特定のディレクトリ（例: Active Storageのmodelsディレクトリ）に対してのみテストを実行できます。たとえば、`/activestorage/test/models`ディレクトリでテストを実行するには以下のようにします。

```bash
$ cd activestorage
$ bin/test models
```

#### 特定ファイルのテストを実行する

以下のように特定のファイルを指定してテストを実行できます。

```bash
$ cd actionview
$ bin/test test/template/form_helper_test.rb
```

#### テストを1件だけ実行する

以下のように`-n`オプションでテスト名を指定すると、テストファイル内にある単一のテストを実行できます。

```bash
$ cd actionmailer
$ bin/test test/mail_layout_test.rb -n test_explicit_class_layout
```

#### 特定行のテストを実行する

テスト名がすぐわかるとは限りません。テストの開始行がわかっている場合は以下のオプションで指定できます。

```bash
$ cd railties
$ bin/test test/application/asset_debugging_test.rb:69
```

#### 特定の行範囲を指定してテストを実行する

似たようなテストが互いに近くで定義されていることはよくあります。以下のように行範囲を指定してテストを実行できます。

```bash
$ cd railties
$ bin/test test/application/asset_debugging_test.rb:69-100
```

#### seedを指定してテストを実行する

テストはseedによってランダムな順序で実行されます。ランダム化したテストが失敗する場合、seedを指定することで、失敗するテストをより正確に再現できます。

seedを指定して特定のコンポーネントのテストをすべて実行するには、以下のようにします。

```bash
$ cd actionmailer
$ SEED=15002 bin/test
```

seedを指定して特定のテストファイルを実行する場合は、以下のようにします。

```bash
$ cd actionmailer
$ SEED=15002 bin/test test/mail_layout_test.rb
```

#### テストの並列実行を止める

Action PackとAction Viewの単体テストは、デフォルトでは並列実行されます。ランダム化したテストが失敗する場合は、seedを指定したうえで`PARALLEL_WORKERS=1`を設定すると、単体テストが順に実行されるようになります。

```bash
$ cd actionview
$ PARALLEL_WORKERS=1 SEED=53708 bin/test test/template/test_case_test.rb
```

#### Active Recordをテストする

最初に、必要なデータベースを作成します。作成に必要なテーブル名、ユーザー名、パスワードは`activerecord/test/config.example.yml`にあります。

MySQLとPostgreSQLの場合は、以下のいずれかを実行するだけでデータベース作成が完了します。

```bash
$ cd activerecord
$ bundle exec rake db:mysql:build
```

または

```bash
$ cd activerecord
$ bundle exec rake db:postgresql:build
```

なおSQLite3ではデータベース作成は不要です。

SQLite3のみを対象にActive Recordのテストを実行する場合は、以下を行います。

```bash
$ cd activerecord
$ bundle exec rake test:sqlite3
```

MySQLやPostgreSQLを対象にテストを実行する場合は、`sqlite3`のときと同様に、それぞれ以下の手順でできます。

```bash
$ bundle exec rake test:mysql2
$ bundle exec rake test:trilogy
$ bundle exec rake test:postgresql
```

最後に以下を実行します。

```bash
$ bundle exec rake test
```

これで3つのデータベースについてテストが順に実行されます。

以下のように、単一のテストを個別に実行することもできます。

```bash
$ ARCONN=mysql2 bundle exec ruby -Itest test/cases/associations/has_many_associations_test.rb
```

1つのテストをすべてのデータベースアダプタに対して実行するには以下のようにします。

```bash
$ bundle exec rake TEST=test/cases/associations/has_many_associations_test.rb
```

これで`test_jdbcmysql`、`test_jdbcsqlite3`、`test_jdbcpostgresql`が順に呼び出されます。特定のデータベースを対象にテストを実行する方法について詳しくは、Railsリポジトリ内の`activerecord/RUNNING_UNIT_TESTS.rdoc`を参照してください。

#### テストでデバッガを使う

外部デバッガ（pry、byebugなど）を利用する場合は、デバッガをインストールして通常どおりに使います。デバッガの問題が発生した場合は、`PARALLEL_WORKERS=1`を設定してテストをシリアル実行するか、`n test_long_test_name`で単一のテストを実行してください。

ジェネレータに対してテストを実行する場合、デバッグツールが機能するために`RAILS_LOG_TO_STDOUT=true`を設定する必要があります。

```sh
RAILS_LOG_TO_STDOUT=true ./bin/test test/generators/actions_test.rb
```

### 警告の扱いについて

テストスイートの実行では、警告表示がオンになります。Ruby on Railsのテストで警告が1つも表示されないのが理想ですが、サードパーティのものも含めて若干の警告が表示される可能性があります。これらの警告は無視してください（でなければ修正しましょう）。可能であれば、新しい警告を表示しないようにするパッチの送信もお願いします。

Rails CIは、警告が発生すると警告を表示します。ローカル環境で同じ動作をさせるには、テストスイートを実行するときに`RAILS_STRICT_WARNINGS=1`を設定します。

### ドキュメントの更新

[Railsガイド][guides]はRailsの機能を大まかに解説するドキュメントであり、[APIドキュメント][api doc]は機能を具体的に解説するドキュメントです。

プルリクで新機能を追加する場合や、既存機能の振る舞いを変更する場合は、関連するドキュメントもチェックして適宜追加または更新してください。

たとえば、Active Storageの画像アナライザに新しいメタデータフィールドを追加する場合は、対応するActive Storageガイドの「[ファイルを解析する](active_storage_overview.html#%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%82%92%E8%A7%A3%E6%9E%90%E3%81%99%E3%82%8B)」セクションにも反映します。

[guides]: https://railsguides.jp/
[api doc]: https://api.rubyonrails.org/

### CHANGELOGの更新

CHANGELOGファイルはすべてのリリースで重要な位置を占めます。Railsの各バージョンの変更内容はここに記録します。

機能の追加や削除、非推奨通知の追加を行ったら、必ず修正したフレームワークでCHANGELOGファイルのその時点の**冒頭に**エントリを追加してください。リファクタリングやドキュメント変更はCHANGELOGに記載しないでください。

CHANGELOGのエントリには変更内容の適切な要約を記入し、最後に作者の名前を書きます。必要であれば複数行にわたってエントリを記入することも、スペース4つのインデントを置いたコード例を記入することもできます。変更が特定のissueに関連する場合は、issue番号も記入してください。CHANGELOGエントリの例を以下に示します（訳注: 実際は英語で書きます）。

```markdown
*  （変更内容の要約をここに記入）

   （複数行のエントリを記入する場合は80文字目で折り返す）

   （必要に応じてコード例をスペースインデント4個で追加してもよい）
        class Foo
          def bar
            puts 'baz'
          end
        end

    （コード例の後にエントリの続きを書いてもよい）（issue番号は「Fixes #1234」などと書く）

    *自分の名前*
```

### 破壊的変更

既存のアプリケーションを壊す可能性のある変更は、常に破壊的変更（breaking change）とみなされます。Railsアプリケーションのアップグレード作業を容易にするために、破壊的変更を行う場合は「非推奨期間」が必要です。

#### 振る舞いを削除する場合

破壊的変更によって既存の振る舞いが削除される場合は、最初に既存の振る舞いを維持したまま、非推奨の警告表示を追加する必要があります。

たとえば、`ActiveRecord::Base`のパブリックメソッドを削除したいとします。mainブランチがリリース前の7.0バージョンを指している場合、Rails 7.0で非推奨の警告を表示する必要があります。これにより、Rails 7.0のどのバージョンにアップグレードしても非推奨の警告が表示されるようになり、Rails 7.1でこのメソッドを削除可能になります。

非推奨の警告は次のような方法で追加できます。

```ruby
def deprecated_method
  ActiveRecord.deprecator.warn(<<-MSG.squish)
    `ActiveRecord::Base.deprecated_method` is deprecated and will be removed in Rails 7.1.
  MSG
  # 既存の振る舞い
end
```

#### 振る舞いを変更する場合

破壊的変更で既存の振る舞いが変更される場合は、フレームワークのデフォルトを追加する必要があります。フレームワークのデフォルトは、アプリを1つずつ新しいデフォルトに切り替え可能にすることで、Railsのアップグレードを容易にします。

フレームワークの新しいデフォルトを実装するには、最初に対象となるフレームワークにアクセサを追加して設定を作成します。アップグレード中に何も壊れないよう、デフォルト値は既存の振る舞いのままにしておきます。

```ruby
module ActiveJob
  mattr_accessor :existing_behavior, default: true
end
```

この新しい設定を使って、以下のように新しい振る舞いを条件付きで実装します。

```ruby
def changed_method
  if ActiveJob.existing_behavior
    # 既存の振る舞い
  else
    # 新しい振る舞い
  end
end
```

この新しいフレームワークのデフォルトを設定するには、`Rails::Application::Configuration#load_defaults`で新しい値を設定します。


```ruby
def load_defaults(target_version)
  case target_version.to_s
  when "7.1"
    # ...
    if respond_to?(:active_job)
      active_job.existing_behavior = false
    end
    # ...
  end
end
```

アップグレードを容易にするために、`new_framework_defaults`テンプレートにも新しいデフォルトを追加する必要があります。コメントアウト済みのセクションを追加して、以下のように新しい値を設定します。

```ruby
# new_framework_defaults_8_0.rb.tt

# Rails.application.config.active_job.existing_behavior = false
```

最後に、新しい設定の情報を[設定ガイド][]の`configuration.md`にも追加します：

```markdown
#### `config.active_job.existing_behavior

| Starting with version | The default value is |
| --------------------- | -------------------- |
| (original)            | `true`               |
| 7.1                   | `false`              |
```

[設定ガイド]: configuring.html

### エディタやIDEが作成するファイルをコミットに含めないようにする

エディタやIDEによっては、`rails`フォルダ内に独自の隠しファイルや隠しディレクトリを作成するものもあります。これらはコミットに含めないようにする必要がありますが、その場合は、コミットのたびに手動で取り除いたりRailsの`.gitignore`に追加したりするのではなく、自分の環境の[グローバルなgitignoreファイル][global gitignore]に追加してください。

[global gitignore]: https://docs.github.com/ja/get-started/getting-started-with-git/ignoring-files#configuring-ignored-files-for-all-repositories-on-your-computer

### Gemfile.lockを更新する

変更内容によっては、gem依存関係のアップグレードも必要になることがあります。そのような場合は、`bundle update`を実行して正しい依存関係バージョンを反映し、変更の`Gemfile.lock`ファイルにコミットしてください。

### 変更をコミットする

自分のコードが問題なく動くようになったら、変更をローカルのGitにコミットします。

```bash
$ git commit -a
```

上を実行すると、コミットメッセージ作成用のエディタが開きます。メッセージの作成が終わったら、保存して次に進みます。

コミットメッセージを書くときは、書式を整えてわかりやすく記述すると、他の開発者が変更内容を理解するうえで大変助かります。十分時間をかけてコミットメッセージを書きましょう。

よいコミットメッセージは以下のような感じになります。

```markdown
短い要約文（理想は50文字以下）

もちろん必要に応じて詳しく書いても構いません。
メッセージは72文字目で改行すること。
メッセージはできるだけ詳しく書くこと。
コミット内容が自明に思えても、他の人にとってそうとは限りません。
関連するissueで言及されている記述もすべて引用して、
履歴を探さなくても済むようにしましょう。

パラグラフを複数にすることも可能です。

コード例を記述に埋め込むときは、以下のようにスペース4個でインデントします。

    class ArticlesController
      def index
        render json: Article.limit(10)
      end
    end

箇条書きも追加できます。

- 箇条書きはダッシュ`-`かアスタリスク`*`で始めること

- 箇条書きの行は72文字目で折り返し、読みやすさのために
  追加行の冒頭にスペース2つを置いてインデントします
```

TIP: コミットが複数ある場合は、スカッシュ（squash）を実行して1個のコミットにまとめてください。そうすることで今後のcherry pickがやりやすくなり、Gitのログもシンプルになります。

### ブランチを更新する

ローカルで作業している間に、リポジトリのmainブランチが更新されていることがよくあります。リポジトリのmainブランチの更新をローカルに取り込むには以下を実行します。

```bash
$ git checkout main
$ git pull --rebase
```

続いて、最新の変更のトップにパッチを再度適用します。

```bash
$ git checkout my_new_branch
$ git rebase main
```

「コンフリクトが生じていないか」「テストにパスしたか」「変更内容を十分吟味したか」を確認したら、rebaseした変更をGitHubにプッシュします。

```bash
$ git push --force-with-lease
```

rails/railsリポジトリベースへの強制プッシュは禁止していますが、自分のforkへの強制プッシュは可能です。rebaseの際には履歴が変更されているため、これが必要です。

### fork

Railsの[GitHubリポジトリ][Rails repo]をブラウザで開いて、右上隅の「Fork」をクリックします。

以下を実行して、ローカルPC上にあるローカルリポジトリに新しい"fork"リモートを追加します。

```bash
$ git remote add fork https://github.com/<自分のユーザー名>/rails.git
```

ローカルリポジトリは、オリジナルのrails/railsリポジトリからローカルリポジトリに`clone`して作ることも、自分のリポジトリにforkしたものをローカルリポジトリに`clone`して作ることも可能です。なお、以下のgitコマンドはオリジナルのrails/railsを指す`rails`リモートを作成した場合を前提としています。

```bash
$ git remote add rails https://github.com/rails/rails.git
```

以下を実行して、Railsの公式リポジトリから新しいコミットとブランチをダウンロードします。

```bash
$ git fetch rails
```

以下を実行して、ダウンロードした新しいコンテンツを自分のブランチにマージします。

```bash
$ git checkout main
$ git rebase rails/main
$ git checkout my_new_branch
$ git rebase rails/main
```

以下を実行して、"fork"リモートを更新します。

```bash
$ git push fork main
$ git push fork my_new_branch
```

[Rails repo]: https://github.com/rails/rails

### プルリクエストをオープンする

プッシュしたRailsアプリケーションのリポジトリをブラウザで開いて（ここでは`https://github.com/自分のユーザー名/rails`にリポジトリがあるとします）、画面上部の「Pull Requests」タブをクリックします。次のページで右上隅の「New pull request」ボタンをクリックします。

プルリクのベースリポジトリ（プルリク送信先）には、`rails/rails`とその`main`ブランチを指定してください。
プルリクのヘッドリポジトリ（プルリク送信元）には、自分のリポジトリ（`自分のユーザー名/rails`など）と、自分が作成したブランチ名を指定してください。
十分確認したら、「create pull request」ボタンをクリックします。

プルリクメッセージ画面が開いたら、まず自分が行った変更が過不足なく含まれていることを確認します。Rails用のプルリクメッセージテンプレートに沿って、送信したいパッチの詳細をプルリクメッセージに記入し、内容がひと目でわかるタイトルを付けます。以上の作業が終わったら「Send pull request」をクリックします。

### フィードバックを受け取る

ほとんどの場合、送信したプルリクエストがマージされるまでに何回か再挑戦することになるでしょう。あなたのプルリクエストに対して別の意見を持つコントリビュータがいるかもしれません。多くの場合、プルリクエストがマージされるまでにパッチを何度か更新する必要もあるでしょう。

GitHubのメール通知機能をオンにしているRailsコントリビュータもいますが、そうとは限りません。Railsに携わっている人のほとんどはボランティアなので、プルリクエストに返信をもらうまでに数日かかることもざらにあります。どうかめげずにプルリクエストをどしどし送信してください。おどろくほど早く反応がもらえることもあれば、そうでないこともあります。それがオープンソースというものです。

一週間経っても何の音沙汰もないようなら、[Ruby on Rails Discord server][discord]の*contribution*チャンネルやdiscuss.rubyonrails.orgの[rubyonrails-core][]で少しつっついてみてもよいでしょう。プルリクエストに自分でコメントを追加してみてもよいでしょう。なお、メンテナーは多忙のためプルリクエストのチェックまで手が回らない可能性がありますので、個別のメンテナーに直接問い合わせることはご遠慮ください。

よい機会なので、自分のプルリクエストへの反応を待っている間に、他の人のプルリクエストを開いてコメントを追加してみましょう。きっとその人たちも、あなたが自分のパッチに返信をもらったときと同じぐらい喜んでくれるでしょう。

あなたのプルリクを承認（approved）できる権限を持っているのはコアチームとコミッターチームだけです。あなたのプルリクにapprovedとコメントした人が実際にRailsへのマージ権限や決定権を持っているとは限りません。

[discord]: https://discord.gg/d8N68BCw49

### 必要なら何度でもトライする

「そのプルリクエストはここを変えた方がよいのではないか」といったフィードバックを受けることもあるでしょう。そういうことがあっても、どうかがっかりしないでください。オープンソースプロジェクトに貢献するうえで肝心なのは、遠慮せずにコミュニティの知恵を借りることです。コミュニティのメンバーがあなたのコードに変更を勧めているなら、そのとおりに変更して再送信する価値は十分あります。仮に「そのコードはマージできない」というフィードバックを受けたとしても、gemの形でリリースすることを検討する手もあります。

#### コミットをスカッシュする

あなたのコミットに対してスカッシュ（squash: 複数のコミットを1つにまとめること）を求められることもあります。プルリクエストは、1つのコミットにまとめておくことが望まれます。コミットを1つにまとめることで、新しい変更を安定版ブランチにバックポートしやすくなり、よくないコミットを取り消しやすくなり、Gitの履歴も多少追いやすくなります。Railsは巨大プロジェクトであり、不要なコミットが増えすぎると膨大なノイズが生じる可能性があります。

```bash
$ git fetch rails
$ git checkout my_new_branch
$ git rebase -i rails/main

< Choose 'squash' for all of your commits except the first one. >
< Edit the commit message to make sense, and describe all your changes. >

$ git push fork my_new_branch --force-with-lease
```

スカッシュしたコミットを用いてGitHub上のプルリクエストをリフレッシュすると、実際に更新されたことを確認できるようになります。

#### プルリクエストを更新する

あなたがコミットしたコードに対して後追いで変更を求められたり、場合によっては既存のコミットそのものの修正を求められることもあります。ただし、Gitでは既存のコミットをさかのぼって変更したものをプッシュすることは許されていません（既にプッシュされたブランチとローカルのブランチが一致しなくなるため）。このような場合は、新しいプルリクエストを作成する代わりに、上で説明したコミットのスカッシュを利用して、GitHub上の自分のブランチに強制的にプッシュする方法も考えられます。

```bash
$ git commit --amend
$ git push fork my_new_branch --force-with-lease
```

これにより、GitHub上のブランチとプルリクエストが新しいコードで更新されます。強制プッシュするときに`--force-with-lease`オプションを指定すると、通常の`-f`による強制プッシュよりも安全にリモートを更新できまます。

### 旧バージョンのRuby on Rails

次回リリースより前のバージョンのRuby on Railsに修正パッチを当てたい場合は、設定を行ってローカルのトラッキングブランチに切り替える必要があります。たとえば7-0-stableブランチに切り替える場合は以下のようにします。

```bash
$ git branch --track 7-0-stable rails/7-0-stable
$ git checkout 7-0-stable
```

NOTE: 旧バージョンのRailsで作業する前に、[メンテナンスポリシー](maintenance_policy.html)でサポート期限を確認してください。サポート期限が終了したバージョンへの変更は受け付けられません。

[show branch]: http://qugstart.com/blog/git-and-svn/add-colored-git-branch-name-to-your-shell-prompt/

#### バックポート

mainブランチにマージされた変更は、Railsの次期メジャーリリースに取り入れられます。場合によっては、メンテナンスのために安定版にも変更をバックポートするのがよいこともあります。一般に、セキュリティ修正とバグ修正は、バックポートの候補になります。新機能や動作変更用パッチはバックポートの候補になりません。自分の変更がどちらに該当するかわからない場合は、不要な作業を避けるためにも、変更をバックポートする前にRailsチームのメンバーに相談しましょう。

最初に、mainブランチを最新の状態にします。

```bash
$ git checkout main
$ git pull --rebase
```

バックポート先のブランチ（`7-0-stable`ブランチなど）をチェックアウトして、そのブランチを最新の状態にします。

```bash
$ git checkout 7-0-stable
$ git reset --hard origin/7-0-stable
$ git checkout -b my-backport-branch
```

マージ済みのプルリクエストをバックポートする場合は、該当するコミットを見つけて、そのコミットをチェリーピックします。

```bash
$ git cherry-pick -m1 MERGE_SHA
```

チェリーピックで発生したコンフリクトを修正したら、変更をプッシュし、バックポート先の安定版ブランチを指すプルリクをオープンしてください。変更内容が複雑な場合は、[cherry-pick][]ドキュメントが役に立ちます。

[cherry-pick]: https://git-scm.com/docs/git-cherry-pick

Railsコントリビュータ
------------------

Railsに貢献したすべての開発者は[Railsコントリビュータ][contributors]にクレジットが掲載されます。

[contributors]: https://contributors.rubyonrails.org