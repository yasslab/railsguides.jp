
Rails エンジン入門
============================

本ガイドでは、Railsのエンジンについて解説します。また、簡潔で使いやすいインターフェイスを使った、ホストアプリケーション向け追加機能についても解説します。

このガイドの内容:

* エンジンの役割
* エンジンの生成方法
* エンジンのビルド機能
* エンジンをアプリケーションにフックする
* アプリケーションのエンジン機能を上書きする

--------------------------------------------------------------------------------

Railsにおけるエンジンの役割
-----------------

エンジン (engine) とは、アプリケーションのミニチュアのようなものであり、ホストアプリケーションに機能を提供します。Railsアプリケーションは実際にはエンジンに「ターボをかけた」ようなものにすぎず、`Rails::Application`クラスは`Rails::Engine`から多くの振る舞いを継承しています。

従って、エンジンとアプリケーションは、細かな違いを除けばほぼ同じものであると考えていただいてよいでしょう。本ガイドでもこの点をたびたび確認します。エンジンとアプリケーションは、同じ構造を共有しています。

エンジンは、プラグインとも密接に関連します。エンジンもプラグインも、共通の`lib`ディレクトリ構造を共有し、どちらも`rails plugin new`ジェネレータを使用して生成されます。両者に違いがあるとすれば、Railsはエンジンを一種の「完全なプラグイン」とみなしている点です。これは、エンジンを生成するにはジェネレータコマンドで`--full`を与えることからもわかります。実際にはこのガイドでは`--mountable`オプションを使用します。これは`--full`のオプション以外にもいくつかの機能を追加してくれます。以後本ガイドでは「完全なプラグイン (full plugin)」を単に「エンジン」と呼びます。エンジンはプラグインになることもでき、プラグインがエンジンになることもできます。

本ガイドで説明のために作成するエンジンに "blorgh" (blogのもじり) という名前を付けます。このエンジンはブログ機能をホストアプリケーションに追加し、記事とコメントを作成できます。本ガイドでは、最初にこのエンジンを単体で動作するようにし、後にこのエンジンをアプリケーションにフックします。

エンジンはホストアプリケーションと混じらないよう分離しておくこともできます。これは、あるアプリケーションが`articles_path`のようなルーティングヘルパーによってパスを提供できるとすると、そのアプリケーションのエンジンも同じく`articles_path`というヘルパーによってパスを提供でき、しかも両者が衝突しないということを意味します。これにともない、コントローラ名、モデル名、テーブル名はいずれも名前空間化されます。これについては本ガイドで後述します。

ここが重要です。アプリケーションは **いかなる場合も** エンジンよりも優先されます。ある環境において、最終的な決定権を持つのはアプリケーション自身です。エンジンはアプリケーションの動作を大幅に変更するものではなく、アプリケーションを単に拡張するものです。

その他のエンジンに関するドキュメントについては、[Devise](https://github.com/plataformatec/devise) (親アプリケーションに認証機能を提供するエンジン) や [Forem](https://github.com/radar/forem) (フォーラム機能を提供するエンジン) を参照してください。この他に、[Spree](https://github.com/spree/spree) (eコマースプラットフォーム) や[RefineryCMS](https://github.com/refinery/refinerycms) (CMSエンジン) などもあります。

追伸。エンジン機能はJames Adam、Piotr Sarnacki、Railsコアチーム、そして多くの人々の助けなしではできあがらなかったでしょう。彼らに会うことがあったら、ぜひお礼を述べてやってください。

エンジンを生成する
--------------------

エンジンを生成するには、プラグインジェネレータを実行し、必要に応じてオプションをジェネレータに渡します。"blorgh"の場合はマウント可能なエンジンとして生成するので、ターミナルで以下のコマンドを実行します。

```bash
$ bin/rails plugin new blorgh --mountable
```

プラグインジェネレータで利用できるオプションの一覧をすべて表示するには、以下を入力します。

```bash
$ bin/rails plugin --help
```

`--mountable`オプションは、マウント可能かつ名前空間で分離されたエンジンを生成する場合に使用します。このジェネレータで生成したプラグインは、`--full`オプションを使用した場合と同じスケルトン構造を持ちます。`--full`オプションは、以下を提供するスケルトン構造を含むエンジンを作成します。

  * `app`ディレクトリツリー
  * `config/routes.rb`ファイル

    ```ruby
    Rails.application.routes.draw do
    end
    ```

  * `lib/blorgh/engine.rb`ファイルは、Railsアプリケーションが標準で持つ`config/application.rb`ファイルと同一の機能を持ちます。

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```

`--mountable`オプションを使用すると、`--full`オプションに以下が追加されます。

  * アセットマニフェストファイル (`application.js`および`application.css`)
  * 名前空間化された`ApplicationController`スタブ
  * 名前空間化された`ApplicationHelper`スタブ
  * エンジンで使用するレイアウトビューテンプレート
  * `config/routes.rb`での名前空間分離

    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```

  * `lib/blorgh/engine.rb`での名前空間分離

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```

さらに、`--mountable`オプションはダミーのテスト用アプリケーションを `test/dummy`に配置するようジェネレータに指示します。これは、以下のダミーアプリケーションのルーティングファイルを`test/dummy/config/routes.rb`に追加することによって行います。

```ruby
mount Blorgh::Engine => "/blorgh"
```

### エンジンの内部

#### 重要なファイル

新しく作成したエンジンのルートディレクトリには、`blorgh.gemspec`というファイルが置かれます。アプリケーションにこのエンジンを後からインクルードするには、`Gemfile`に以下の行を追加します。

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

Gemfileを更新したら、いつものように`bundle install`を実行するのを忘れずに。エンジンを通常のgemと同様に`Gemfile`に記述すると、Bundlerはgemと同様にエンジンを読み込み、`blorgh.gemspec`ファイルを解析し、`lib`以下に置かれているファイル (この場合`lib/blorgh.rb`) をrequireします。このファイルは、(`lib/blorgh/engine.rb`に置かれている) `blorgh/engine.rb`ファイルをrequireし、`Blorgh`という基本モジュールを定義します。

```ruby
require "blorgh/engine"

module Blorgh
end
```

TIP: エンジンによっては、このファイルをエンジンのためのグローバル設定オプションとして配置したいこともあるでしょう。これは比較的よいアイディアです。設定オプションを提供したい場合は、エンジンで`module`と呼ばれているファイルを、まさにこれを行なうのにふさわしい場所として定義します。そのモジュールの中にメソッドを置くことで準備は完了します。

エンジンの基本クラスは`lib/blorgh/engine.rb`の中にあります。

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

`Rails::Engine`クラスを継承することによって、指定されたパスにエンジンがあることがgemからRailsに通知され、アプリケーションの内部にエンジンが正しくマウントされます。そして、エンジンの`app`ディレクトリをモデル/メイラー/コントローラ/ビューの読み込みパスに追加します。

ここで、`isolate_namespace`メソッドについて特別な注意が必要です。このメソッドの呼び出しは、エンジンのコントローラ/モデル/ルーティングなどが持つ固有の名前空間を、アプリケーション内部のコンポーネントが持つ類似の名前空間から分離する役目を担います。この呼び出しが行われないと、エンジンのコンポーネントがアプリケーション側に「漏れ出す」リスクが生じ、思わぬ動作が発生したり、エンジンの重要なコンポーネントが同じような名前のアプリケーション側コンポーネントによって上書きされてしまったりする可能性があります。名前の衝突の例として、ヘルパーを取り上げましょう。`isolate_namespace`が呼び出されないと、エンジンのヘルパーがアプリケーションのコントローラにインクルードされてしまう可能性があります。

NOTE: `Engine`クラスの定義に含まれる`isolate_namespace`の行を変更/削除しないことを **強く** 推奨します。この行が変更されると、生成されたエンジン内のクラスがアプリケーションと衝突する **可能性があります** 。

名前空間を分離するということは、`bin/rails g model`の実行によって生成されたモデル (ここでは `bin/rails g model article`を実行したとします) は`Article`にならず、名前空間化されて`Blorgh::Article`になるということです。さらにモデルのテーブルも名前空間化され、単なる`articles`ではなく`blorgh_articles`になります。コントローラもモデルと同様に名前空間化されます。`ArticlesController`というコントローラは`Blorgh::ArticlesController`になり、このコントローラのビューは`app/views/articles`ではなく`app/views/blorgh/articles`に置かれます。メイラーも同様に名前空間化されます。

最後に、ルーティングもエンジン内で分離されます。これは名前空間化の最も肝心な部分であり、これについては本ガイドの[ルーティング](#ルーティング)セクションで後述します。

#### `app`ディレクトリ

エンジンの`app`ディレクトリの中には、通常のアプリケーションでおなじみの標準の`assets`、`controllers`、`helpers`、`mailers`、`models`、`views`ディレクトリが置かれます。このうち`helpers`、`mailers`、`models`ディレクトリにはデフォルトでは何も置かれないので、本セクションでは解説しません。モデルについては、エンジンの作成について解説するセクションで後述します。

エンジンの`app/assets`ディレクトリの下にも、通常のアプリケーションと同様に`images`、`javascripts`、`stylesheets`ディレクトリがそれぞれあります。通常のアプリケーションと異なる点は、これらのディレクトリの下にはさらにエンジン名を持つサブディレクトリがあることです。これは、エンジンが名前空間化されるのと同様、エンジンのアセットも同様に名前空間化される必要があるからです。

`app/controllers`ディレクトリの下には`blorgh`ディレクトリが置かれます。この中には`application_controller.rb`というファイルが1つ置かれます。このファイルはエンジンのコントローラ共通の機能を提供するためのものです。この`blorgh`ディレクトリには、エンジンで使用するその他のコントローラを置きます。これらのファイルを名前空間化されたディレクトリに配置することで、他のエンジンやアプリケーションに同じ名前のコントローラがあっても名前の衝突を避ける事ができます。

NOTE: あるエンジンに含まれる`ApplicationController`というクラスの名前は、アプリケーションそのものが持つクラスと同じ名前になっています。これは、アプリケーションをエンジンに変換しやすくするためです。

最後に、`app/views`ディレクトリの下には`layouts`フォルダがあります。ここには`blorgh/application.html.erb`というファイルが置かれます。このファイルは、エンジンで使用するレイアウトを指定するためのものです。エンジンが単体のエンジンとして使用されるのであれば、このファイルを使用していくらでも好きなようにレイアウトをカスタマイズできます。そのためにアプリケーション自身の`app/views/layouts/application.html.erb`ファイルを変更する必要はありません。

エンジンのレイアウトをユーザーに強制したくない場合は、このファイルを削除し、エンジンのコントローラでは別のレイアウトを参照するように変更してください。

#### `bin`ディレクトリ

このディレクトリには`bin/rails`というファイルが1つだけ置かれます。これはアプリケーション内で使用しているのと似た`rails`サブコマンドであり、ジェネレータです。このような構成になっていることで、このエンジンで利用するための独自のコントローラやモデルを以下のように簡単に生成することができます。

```bash
$ bin/rails g model
```

言うまでもなく、`Engine`クラスに`isolate_namespace`を持つエンジンでこのbin/railsを使用して生成したものはすべて名前空間化されることにご注意ください。

#### `test`ディレクトリ

`test`ディレクトリは、エンジンがテストを行なうための場所です。エンジンをテストするために、`test/dummy`ディレクトリに埋め込まれた縮小版のRailsアプリケーションが用意されます。このアプリケーションはエンジンを`test/dummy/config/routes.rb`ファイル内で以下のようにマウントします。

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

上の行によって、`/blorgh`パスにあるエンジンがマウントされ、アプリケーションのこのパスを通じてのみアクセス可能になります。

testディレクトリの下には`test/integration`ディレクトリがあります。ここにはエンジンの結合テストが置かれます。`test`ディレクトリに他のディレクトリを作成することもできます。たとえば、モデルのテスト用に`test/models`ディレクトリを作成しても構いません。

エンジンの機能を提供する
------------------------------

本ガイドで説明のために作成するエンジンには、記事とコメントの送信機能があります。基本的には[Railsをはじめよう](getting_started.html)とよく似たスレッドに従いますが、多少の新味も加えられています。

### Articleリソースを生成する

ブログエンジンで最初に生成すべきは`Article`モデルとそれに関連するコントローラです。これらを手軽に生成するために、Railsのscaffoldジェネレータを使用します。

```bash
$ bin/rails generate scaffold article title:string text:text
```

上のコマンドを実行すると以下の情報が出力されます。

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_articles.rb
create    app/models/blorgh/article.rb
invoke  test_unit
create      test/models/blorgh/article_test.rb
create      test/fixtures/blorgh/articles.yml
invoke  resource_route
route    resources :articles
invoke  scaffold_controller
create    app/controllers/blorgh/articles_controller.rb
invoke    erb 
create      app/views/blorgh/articles
create      app/views/blorgh/articles/index.html.erb
create      app/views/blorgh/articles/edit.html.erb
create      app/views/blorgh/articles/show.html.erb
create      app/views/blorgh/articles/new.html.erb
create      app/views/blorgh/articles/_form.html.erb
invoke  test_unit
create      test/controllers/blorgh/articles_controller_test.rb
invoke    helper
create      app/helpers/blorgh/articles_helper.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/articles.js
invoke    css
create      app/assets/stylesheets/blorgh/articles.css
invoke  css
create    app/assets/stylesheets/scaffold.css
```

scaffoldジェネレータが最初に行なうのは`active_record`ジェネレータの呼び出しです。これはマイグレーションの生成とそのリソースのモデルを生成します。ここでご注目いただきたいのは、マイグレーションは通常の`create_articles`ではなく`create_blorgh_articles`という名前で呼ばれるという点です。これは`Blorgh::Engine`クラスの定義で呼び出される`isolate_namespace`メソッドによるものです。このモデルも名前空間化されるので、`Engine`クラス内のisolate_namespace`呼び出しによって、`app/models/article.rb`ではなく`app/models/blorgh/article.rb`に置かれます。

続いて、そのモデルに対応する`test_unit`ジェネレータが呼び出され、(`test/models/article_test.rb`ではなく) `test/models/blorgh/article_test.rb` にモデルのテストが置かれます (rather than )。フィクスチャも同様に (`test/fixtures/articles.yml`ではなく) `test/fixtures/blorgh/articles.yml`に置かれます。

その後、そのリソースに対応する行が`config/routes.rb`ファイルに挿入され、エンジンで使用されます。ここで挿入される行は単に`resources :articles`となっています。これにより、そのエンジンで使用する`config/routes.rb`ファイルが以下のように変更されます。

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

このルーティングは、`YourApp::Application`クラスではなく`Blorgh::Engine`オブジェクトにもとづいていることにご注目ください。これにより、エンジンのルーティングがエンジン自身に制限され、[testディレクトリ](#testディレクトリ)セクションで説明したように特定の位置にマウントできるようになります。ここでは、エンジンのルーティングがアプリケーション内のルーティングから分離されていることにもご注目ください。詳細については本ガイドの[ルーティング](#ルーティング)セクションで解説します。

続いて`scaffold_controller`ジェネレータが呼ばれ、`Blorgh::ArticlesController`という名前のコントローラを生成します (生成場所は`app/controllers/blorgh/articles_controller.rb`です)。このコントローラに関連するビューは`app/views/blorgh/articles`となります。このジェネレータは、コントローラ用のテスト (`test/controllers/blorgh/articles_controller_test.rb`) とヘルパー (`app/helpers/blorgh/articles_controller.rb`) も同時に生成します。

このジェネレータによって生成されるものはすべて正しく名前空間化されます。このコントローラのクラスは、以下のように`Blorgh`モジュール内で定義されます。

```ruby
module Blorgh
  class ArticlesController < ApplicationController
    ...
  end
end
```

NOTE: このクラスで継承されている`ApplicationController`クラスは、実際には`ApplicationController`ではなく、`Blorgh::ApplicationController`です。

`app/helpers/blorgh/articles_helper.rb`のヘルパーも同様に名前空間化されます。

```ruby
module Blorgh
  module ArticlesHelper
    ...
  end
end
```

これにより、たとえ他のエンジンやアプリケーションにarticleリソースがあっても衝突を回避できます。

最後に、以下の2つのファイルがこのリソースのアセットとして生成されます。
`app/assets/javascripts/blorgh/articles.js`と
`app/assets/stylesheets/blorgh/articles.css`です。これらの使用法についてはこのすぐ後で解説します。

デフォルトでは、scaffoldで生成されたスタイルはエンジンに適用されません。これは、エンジンのレイアウトファイル`app/views/layouts/blorgh/application.html.erb`がscaffoldのスタイルを読み込んでいないためです。scaffoldで生成されたスタイルを適用するには、このレイアウトの`<head>`タグに以下の行を挿入します。

```erb
<%= stylesheet_link_tag "scaffold" %>
```

エンジンのルートディレクトリで`bin/rails db:migrate`を実行すると、scaffoldジェネレータによって生成されたマイグレーションが実行されます。続いて`test/dummy`ディレクトリで`rails server`を実行してみましょう。`http://localhost:3000/blorgh/articles`をブラウザで表示すると、生成されたデフォルトのscaffoldが表示されます。表示されたものをいろいろクリックしてみてください。これで、最初の機能を備えたエンジンの生成に成功しました。

コンソールで遊んでみたいのであれば、`rails console`でRailsアプリケーションをコンソールで動かせます。先ほどから申し上げているように、`Article`モデルは名前空間化されていますので、このモデルを参照する際には`Blorgh::Article`と指定する必要があります。

```ruby
>> Blorgh::Article.find(1)
=> #<Blorgh::Article id: 1 ...>
```

最後の作業です。このエンジンの`articles`リソースはエンジンのルート (root) パスに置くのがふさわしいでしょう。エンジンがマウントされているルートパスに移動したら、記事の一覧が表示されるようにしたいものです。エンジンにある`config/routes.rb`ファイルに以下の記述を追加することでこれを実現できます。

```ruby
root to: "articles#index"
```

これで、ユーザーが (`/articles`ではなく) エンジンのルートパスに移動すると記事の一覧が表示されるようになりました。つまり、`http://localhost:3000/blorgh/articles`に移動しなくても`http://localhost:3000/blorgh`に移動すれば済むということです。

### commentsリソースを生成する

エンジンで記事を新規作成できるようになりましたので、今度は記事にコメントを追加する機能も付けてみましょう。これを行なうには、commentモデルとcommentsコントローラを生成し、articles scaffoldを変更してコメントを表示できるようにし、それから新規コメントを作成できるようにします。

アプリケーションのルート・ディレクトリで、モデルのジェネレータを実行します。このとき、`Comment`モデルを生成すること、integer型の`article_id`カラムとtext型の`text`カラムを持つテーブルと関連付けることを指示します。

```bash
$ bin/rails generate model Comment article_id:integer text:text
```

上によって以下が出力されます。

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

このジェネレータ呼び出しでは必要なモデルファイルだけが生成されます。さらに`blorgh`ディレクトリの下で名前空間化され、`Blorgh::Comment`というモデルクラスも作成されます。それではマイグレーションを実行してblorgh_commentsテーブルを生成してみましょう。

```bash
$ bin/rails db:migrate
```

記事のコメントを表示できるようにするために、`app/views/blorgh/articles/show.html.erb`を編集して以下の行を"Edit"リンクの直前に追加します。

```html+erb
<h3>Comments</h3>
<%= render @article.comments %>
```

上の行では、`Blorgh::Article`モデルとコメントが`has_many`関連付けとして定義されている必要がありますが、現時点ではまだありません。この定義を行なうために、`app/models/blorgh/article.rb`を開いてモデルに以下の行を追加します。

```ruby
has_many :comments
```

これにより、モデルは以下のようになります。

```ruby
module Blorgh
  class Article < ActiveRecord::Base
    has_many :comments
  end
end
```

NOTE: この`has_many`は`Blorgh`モジュールの中にあるクラスの中で定義されています。これだけで、これらのオブジェクトに対して`Blorgh::Comment`モデルを使用したいという意図がRailsに自動的に認識されます。従って、ここで`:class_name`オプションを使用してクラス名を指定する必要はありません。

続いて、記事を作成するためのフォームを作成する必要があります。フォームを追加するには、`app/views/blorgh/articles/show.html.erb`の`render @article.comments`呼び出しの直後に以下の行を追加します。

```erb
<%= render "blorgh/comments/form" %>
```

続いて、この行を出力に含めるためのパーシャル (部分テンプレート) も必要です。`app/views/blorgh/comments`にディレクトリを作成し、`_form.html.erb`というファイルを作成します。このファイルの中に以下のパーシャルを記述します。

```html+erb
<h3>New comment</h3>
<%= form_for [@article, @article.comments.build] do |f| %>
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
  <%= f.submit %>
<% end %>
```

このフォームが送信されると、エンジン内の`/articles/:article_id/comments`というルーティングに対して`POST`リクエストを送信しようとします。このルーティングはまだ存在していませんので、`config/routes.rb`の`resources :articles`行を以下のように変更します。

```ruby
resources :articles do
  resources :comments
end
```

これでcomments用のネストしたルーティングが作成されました。これが上のフォームで必要となります。

ルーティングは作成しましたが、ルーティング先のコントローラがまだありません。これを作成するには、アプリケーションのルート・ディレクトリで以下のコマンドを実行します。

```bash
$ bin/rails g controller comments
```

上によって以下が生成されます。

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/comments.js
invoke    css
create      app/assets/stylesheets/blorgh/comments.css
```

このフォームは`POST`リクエストを`/articles/:article_id/comments`に送信します。これに対応するのは`Blorgh::CommentsController`の`create`アクションです。このアクションを作成する必要があります。`app/controllers/blorgh/comments_controller.rb`のクラス定義の中に以下の行を追加します。

```ruby
def create
  @article = Article.find(params[:article_id])
  @comment = @article.comments.create(comment_params)
  flash[:notice] = "Comment has been created!"
  redirect_to articles_path
end

private
  def comment_params
    params.require(:comment).permit(:text)
  end
```

いよいよ、コメントフォームが動作するのに必要な最後の手順を行いましょう。コメントはまだ正常に表示できません。この時点でコメントを作成しようとすると、以下のようなエラーが生じるでしょう。

```
Missing partial blorgh/comments/comment with {:handlers=>[:erb, :builder],
:formats=>[:html], :locale=>[:en, :en]}. Searched in:   *
"/Users/ryan/Sites/side_projects/blorgh/test/dummy/app/views"   *
"/Users/ryan/Sites/side_projects/blorgh/app/views"
```

このエラーは、コメントの表示に必要なパーシャルが見つからないためです。Railsはアプリケーションの (`test/dummy`) `app/views`を最初に検索し、続いてエンジンの`app/views`ディレクトリを検索します。見つからない場合はエラーになります。エンジン自身は`blorgh/comments/comment`を検索すべきであることを認識しています。これは、エンジンが受け取るモデルオブジェクトが`Blorgh::Comment`クラスに属しているためです。

さしあたって、コメントテキストを出力する役目をこのパーシャルに担ってもらわなければなりません。`app/views/blorgh/comments/_comment.html.erb`ファイルを作成し、以下の記述を追加します。

```erb
<%= comment_counter + 1 %>. <%= comment.text %>
```

`<%= render @article.comments %>`呼び出しによって`comment_counter`ローカル変数が返されます。この変数は自動的に定義され、コメントをiterateするたびにカウントアップします。この例では、作成されたコメントの横に小さな数字を表示するのに使用しています。

これでブログエンジンのコメント機能ができました。今度はこの機能をアプリケーションの中で使用してみましょう。

アプリケーションにフックする
---------------------------

エンジンをアプリケーションで利用するのはきわめて簡単です。本セクションでは、エンジンをアプリケーションにマウントして必要な初期設定を行い、アプリケーションが提供する`User`クラスにエンジンをリンクして、エンジン内の記事とコメントに所有者を与えるところまでをカバーします。

### エンジンをマウントする

最初に、使用するエンジンをアプリケーションの`Gemfile`に記述する必要があります。テストに使用できる手頃なアプリケーションが見当たらない場合は、エンジンのディレクトリの外で以下の`rails new`コマンドを実行してアプリケーションを作成してください。

```bash
$ rails new unicorn
```

基本的には、Gemfileでエンジンを指定する方法は他のgemの指定方法と変わりません。

```ruby
gem 'devise'
```

ただし、この`blorgh`エンジンはローカルPCで開発中でgemリポジトリには存在しないので、`Gemfile`でエンジンgemへのパスを`:path`オプションで指定する必要があります。

```ruby
gem 'blorgh', path: "/path/to/blorgh"
```

続いて`bundle`コマンドを実行し、gemをインストールします。

前述したように、`Gemfile`に記述したgemはRailsの読み込み時に読み込まれます。このgemは最初にエンジンの`lib/blorgh.rb`をrequireし、続いて`lib/blorgh/engine.rb`をrequireします。後者はこのエンジンの機能を担う主要な部品が定義されている場所です。

アプリケーションからエンジンの機能にアクセスできるようにするには、エンジンをアプリケーションの`config/routes.rb`ファイルでマウントする必要があります。

```ruby
mount Blorgh::Engine, at: "/blog"
```

この行を記述することで、エンジンがアプリケーションの`/blog`パスにマウントされます。`rails server`を実行してRailsを起動すること、`http://localhost:3000/blog`にアクセスできるようになります。

NOTE: Deviseなどの他のエンジンではこの点が若干異なり、ルーティングで (`devise_for`などの) カスタムヘルパーを指定するものがあります。これらのヘルパーの動作は完全に同じです。事前に定義されたカスタマイズ可能なパスにエンジンの機能の一部をマウントします。

### エンジンの設定

作成したエンジンには`blorgh_articles`テーブルと`blorgh_comments`テーブル用のマイグレーションが含まれます。これらのテーブルをアプリケーションのデータベースに作成し、エンジンのモデルからこれらのテーブルにアクセスできるようにする必要があります。これらのマイグレーションをアプリケーションにコピーするには、以下のコマンドを実行します。

```bash
$ bin/rails blorgh:install:migrations
```

マイグレーションをコピーする必要のあるエンジンがいくつもある場合は、代りに`railties:install:migrations`を使用します。

```bash
$ bin/rails railties:install:migrations
```

このコマンドは、初回実行時にエンジンからすべてのマイグレーションをコピーします。次回以降の実行時には、コピーされていないマイグレーションのみがコピーされます。このコマンドの初回実行時の出力結果は以下のようになります。

```bash
Copied migration [timestamp_1]_create_blorgh_articles.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.rb from blorgh
```

最初のタイムスタンプ (`[timestamp_1]`) が現在時刻、次のタイムスタンプ (`[timestamp_2]`) が現在時刻に1秒追加した値になります。このようになっているのは、エンジンのマイグレーションはアプリケーションの既存のマイグレーションがすべて終わってから実行する必要があるためです。

アプリケーションのコンテキストでマイグレーションを実行するには、単に`bin/rails db:migirate`を実行します。`http://localhost:3000/blog`でエンジンにアクセスすると、記事は空の状態です。これは、アプリケーションの内部で作成されたテーブルはエンジンの内部で作成されたテーブルとは異なるためです。新しくマウントしたエンジンでもっといろいろやってみましょう。アプリケーションの動作は、エンジンを単体で動かしているときと同じであることに気付くことでしょう。

エンジンを1つだけマイグレーションしたい場合、以下のように`SCOPE`を指定します。

```bash
bin/rails db:migrate SCOPE=blorgh
```

このオプションは、エンジンを削除する前にマイグレーションを元に戻したい場合などに便利です。blorghエンジンによるすべてのマイグレーションを元に戻したい場合は以下のようなコマンドを実行します。

```bash
bin/rails db:migrate SCOPE=blorgh VERSION=0
```

### アプリケーションが提供するクラスを使用する

#### アプリケーションが提供するモデルを使用する

エンジンをひとつ作成すると、やがてエンジンの部品とアプリケーションの部品を連携させるために、アプリケーションの特定のクラスをエンジンから利用したくなるでしょう。この`blorgh`エンジンであれば、記事とコメントの作者の情報がある方がずっとわかりやすくなります。

普通のアプリケーションであれば、記事やコメントの作者を表すための`User`クラスが備わっているでしょう。しかしクラス名がUserとは限りません。アプリケーションによっては`Person`というクラスであるかもしれません。このような状況に対応するために、このエンジンでは`User`クラスとの関連付けをハードコードしないようにすべきです。

ここでは話を簡単にするため、アプリケーションがユーザーを表すために持つクラスは`User`であるとします (この後でもっとカスタマイズしやすくします)。このクラスは、アプリケーションで以下のコマンドを実行して生成できます。

```bash
rails g model user name:string
```

今後`users`テーブルをアプリケーションで使用できるようにするために、ここで`bin/rails db:migrate`を実行する必要があります。

話を簡単にするため、記事のフォームのテキストフィールドは`author_name`とすることにします。記事を書くユーザーがここに自分の名前を入れられるようにします。エンジンはこの名前を使用して`User`オブジェクトを新規作成するか、その名前が既にあるかどうかを調べます。続いて、エンジンは作成または見つけた`User`オブジェクトを記事と関連付けます。

最初に、`author_name`テキストフィールドをエンジンのパーシャル`app/views/blorgh/articles/_form.html.erb`に追加する必要があります。そこで、以下のコードを`title`フィールドのすぐ上に追加します。

```html+erb
<div class="field">
  <%= f.label :author_name %><br>
  <%= f.text_field :author_name %>
</div>
```

続いて、エンジンの`Blorgh::ArticleController#article_params`メソッドを更新して、新しいフォームパラメータを受け付けるようにする必要もあります。

```ruby
def article_params
  params.require(:article).permit(:title, :text, :author_name)
end
```

次に、`Blorgh::Article`モデルにも`author_name`フィールドを実際の`User`オブジェクトに変換し、`User`オブジェクトを記事の`author`と関連付けてから記事を保存するコードが必要です。このフィールド用の`attr_accessor`も設定する必要があります。これにより、このフィールド用のゲッターとセッターが定義されます。

これらをすべて行なうには、`author_name`用の`attr_accessor`と、authorとの関連付け、および`before_save`呼び出しを`app/models/blorgh/article.rb`に追加する必要があります。`author`関連付けは、この時点ではあえて`User`クラスとハードコードしておきます。

```ruby
attr_accessor :author_name
belongs_to :author, class_name: "User"

before_save :set_author

private
  def set_author
    self.author = User.find_or_create_by(name: author_name)
  end
```

`author`オブジェクトと`User`クラスの関連付けを示すことにより、エンジンとアプリケーションの間にリンクが確立されます。`blorgh_articles`テーブルのレコードと、`users`テーブルのレコードを関連付けるための方法が必要です。この関連付けは`author`という名前なので、`blorgh_articles`テーブルには`author_id`というカラムが追加される必要があります。

この新しいカラムを追加するには、エンジンのディレクトリで以下のコマンドを実行する必要があります。

```bash
$ bin/rails g migration add_author_id_to_blorgh_articles author_id:integer
```

NOTE: 上のようにコマンドオプションでマイグレーション名とカラムの仕様を指定することで、特定のテーブルに追加しようとしているカラムがRailsによって自動的に認識され、そのためのマイグレーションが作成されます。この他にオプションを指定する必要はありません。

このマイグレーションはアプリケーションに対して実行する必要があります。これを行なうには、最初に以下のコマンドを実行してマイグレーションをエンジンからコピーする必要があります。

```bash
$ bin/rails blorgh:install:migrations
```

上のコマンドでコピーされるマイグレーションは _1つ_ だけである点にご注意ください。これは、最初の2つのマイグレーションはこのコマンドが初めて実行されたときにコピー済みであるためです。

```
NOTE Migration [timestamp]_create_blorgh_articles.rb from blorgh has been skipped. Migration with the same name already exists. NOTE Migration [timestamp]_create_blorgh_comments.rb from blorgh has been skipped. Migration with the same name already exists. Copied migration [timestamp]_add_author_id_to_blorgh_articles.rb from blorgh
```

このマイグレーションを実行するコマンドは以下のとおりです。

```bash
$ bin/rails db:migrate
```

これですべての部品が定位置に置かれ、ある記事 (article) を、`users`テーブルのレコードで表される作者 (author) に関連付けるアクションが実行されるようになりました。この記事は`blorgh_articles`テーブルで表されます。

最後に、作者名を記事のページに表示しましょう。以下のコードを`app/views/blorgh/articles/show.html.erb`の"Title"出力の上に追加します。

```html+erb
<p>
  <b>Author:</b>
  <%= @article.author %>
</p>
```

`<%=`タグを使用して`@article.author`を出力すると、`to_s`メソッドがこのオブジェクトに対して呼び出されます。この出力はデフォルトのままでは整形されていません。

```
#<User:0x00000100ccb3b0>
```

これは期待していた結果ではありません。ここにユーザー名が表示される方がずっとよいでしょう。そのためには、`to_s`メソッドをアプリケーションの`User`クラスに追加します。

```ruby
def to_s
  name
end
```

これでRubyの生のオブジェクト出力が整形され、作者名が表示されるようになります。

#### アプリケーションのコントローラを使用する

Railsのコントローラでは、認証やセッション変数へのアクセスに関するコードをアプリケーション全体で共有するのが一般的です。従って、このようなコードはデフォルトで`ApplicationController`から継承します。しかし、Railsのエンジンは基本的にメインとなるアプリケーションから独立しているので、エンジンが利用できる`ApplicationController`はスコープで制限されています。名前空間が導入されていることでコードの衝突は回避されますが、エンジンのコントローラからメインアプリケーションの`ApplicationController`のメソッドにアクセスする必要も頻繁に発生します。エンジンのコントローラからメインアプリケーションの`ApplicationController`へのアクセスを提供するには、エンジンが所有するスコープ付きの`ApplicationController`に変更を加え、メインアプリケーションの`ApplicationController`を継承するのが簡単な方法です。Blorghエンジンの場合、`app/controllers/blorgh/application_controller.rb`を以下のように変更します。

```ruby
class Blorgh::ApplicationController < ApplicationController
end
```

エンジンのコントローラはデフォルトで`Blorgh::ApplicationController`を継承します。上の変更を行なうことで、あたかもエンジンがアプリケーションの一部であるかのように、エンジンのコントローラで`ApplicationController`にアクセスできるようになります。

この変更を行なうには、エンジンをホストするRailsアプリケーションに`ApplicationController`という名前のコントローラが存在する必要があります。

### エンジンを設定する

このセクションでは、`User`クラスをカスタマイズ可能にする方法を解説し、続いてエンジンの一般的な設定方法について解説します。

#### アプリケーションの設定を行なう

これより、アプリケーションで`User`を表すクラスをエンジンからカスタマイズ可能にする方法について説明します。カスタマイズしたいクラスは、前述の`User`のようなクラスばかりとは限りません。このクラスの設定をカスタマイズ可能にするには、エンジン内部に`author_class`という名前の設定が必要です。この設定は、親アプリケーション内部でユーザーを表すクラスがどれであるかを指定するためのものです。

この設定を定義するには、エンジンで使用する`Blorgh`モジュール内部に`mattr_accessor`というアクセッサを置く必要があります。エンジンにある`lib/blorgh.rb`に以下の行を追加します。

```ruby
mattr_accessor :author_class
```

このメソッドの動作は`attr_accessor`や`cattr_accessor`などの兄弟メソッドと似ていますが、モジュールのゲッター名とセッター名に指定された名前を使用します。これらを使用する場合は`Blorgh.author_class`という名前で参照する必要があります。

続いて、`Blorgh::Article`モデルの設定をこの新しい設定に切り替えます。`app/models/blorgh/article.rb`モデル内の`belongs_to`関連付けを以下のように変更します。

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

`Blorgh::Article`モデルの`set_author`メソッドは以下のクラスも使用する必要があります。

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

`author_class`で保存時に`constantize`が必ず呼び出されるようにしたい場合は、`lib/blorgh.rb`の`Blorgh`モジュール内部の`author_class`ゲッターメソッドをオーバーライドするだけでできます。これにより、値の保存時に必ず`constantize`を呼び出してから結果が返されます。

```ruby
def self.author_class
  @@author_class.constantize
end
```

これにより、`set_author`用の上のコードは以下のようになります。

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

これにより、記述がやや短くなり、動作がやや明示的でなくなります。この`author_class`メソッドは常に`Class`オブジェクトを返す必要があります。

`author_class`メソッドが`String`ではなく`Class`を返すように変更したので、`Blorgh::Article`の`belongs_to`定義もそれに合わせて変更する必要があります。


```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

この設定をアプリケーション内で行なうには、イニシャライザを使用する必要があります。イニシャライザを使用することで、アプリケーションの設定はアプリケーションが起動してエンジンのモデルを呼び出すまでに完了します。この動作は既存のこの設定に依存する場合があります。

`blorgh`がインストールされているアプリケーションの`config/initializers/blorgh.rb`にイニシャライザを作成して、以下の記述を追加します。

```ruby
Blorgh.author_class = "User"
```

WARNING: このクラス名は必ず`String`で (=引用符で囲んで) 表してください。クラス自身を使用しないでください。クラス自身が使用されていると、Railsはそのクラスを読み込んで関連するテーブルを参照しようとします。このとき参照先のテーブルが存在しないと問題が発生する可能性があります。このため、クラス名は`String`で表し、後にエンジンが`constantize`でクラスに変換する必要があります。

続いて、新しい記事を1つ作成してみることにしましょう。記事の作成はこれまでとまったく同様に行えます。1つだけ異なるのは、今回はクラスの動作を学ぶために`config/initializers/blorgh.rb`の設定をエンジンで使用する点です。

使用するクラスがそのためのAPIさえ備えていれば、使用するクラスに厳密に依存することはありません。エンジンで使用するクラスで必須となるメソッドは`find_or_create_by`のみです。このメソッドはそのクラスのオブジェクトを1つ返します。もちろん、このオブジェクトは何らかの形で参照可能な識別子 (id) を持つ必要があります。

#### 一般的なエンジンの設定

エンジンを使ううちに、その中でイニシャライザや国際化などの機能オプションを使用したくなることでしょう。うれしいことに、RailsエンジンはRailsアプリケーションと大半の機能を共有しているので、これらは完全に実現可能です。実際、Railsアプリケーションが持つ機能はエンジンが持つ機能のスーパーセットなのです。

たとえばイニシャライザ (エンジンが読み込まれる前に実行されるコード) を使用したいのであれば、そのための場所である`config/initializers`フォルダに置きます。このディレクトリの機能については『Railsアプリケーションを設定する』ガイドの[イニシャライザファイルを使用する](configuring.html#イニシャライザ)を参照してください。エンジンのイニシャライザは、アプリケーションの`config/initializers`ディレクトリに置かれているイニシャライザとまったく同様に動作します。標準のイニシャライザを使用したい場合も同様です。

ロケールファイルも、アプリケーションの場合と同様`config/locales`ディレクトリに置けばよいようになっています。

エンジンをテストする
-----------------

エンジンが生成されると、`test/dummy`ディレクトリの下に小規模なダミーアプリケーションが自動的に配置されます。このダミーアプリケーションはエンジンのマウント場所として使用されるので、エンジンのテストがきわめてシンプルになります。このディレクトリ内でコントローラやモデル、ビューを生成してアプリケーションを拡張し、続いてこれらを使用してエンジンをテストできます。

`test`ディレクトリは、通常のRailsにおけるtesting環境と同様に扱う必要があります。Railsのtesting環境では単体テスト、機能テスト、結合テストを行なうことができます。

### 機能テスト

特に機能テストを作成する際には、テストが実行されるのはエンジンではなく`test/dummy`に置かれるダミーアプリケーション上であるという点に留意する必要があります。このようになっているのは、testing環境がそのように設定されているためです。エンジンの主要な機能、特にコントローラをテストするには、エンジンをホストするアプリケーションが必要です。コントローラの機能は、通常であればたとえば以下のように`GET`をコントローラに送信することでテストするでしょう。

```ruby
get :index
```

しかしこれは正常に機能しないでしょう。アプリケーションは、このようなリクエストをエンジンにルーティングする方法を知らないので、明示的にエンジンにルーティングする必要があります。これを行なうには、以下のようにリクエストのパラメータとして`:use_route`オプションを渡す必要があります。

```ruby
get :index, use_route: :blorgh
```

上のようにすることで、このコントローラの`index`アクションに対して`GET`リクエストを送信しようとしていることがアプリケーションによって認識され、かつそのためにアプリケーションのルーティングではなくエンジンのルーティングが使用されるようになります。

別の方法として、テスティング設定で`@routes`インスタンス変数に`Engine.routes`を割り当てることもできます。

```ruby
setup do
  @routes = Engine.routes
end
```

こうすることで、エンジン用のURLヘルパーもテストで期待どおりに動作します。

エンジンの機能を改良する
------------------------------

このセクションでは、エンジンのMVC機能をメインのRailsアプリケーションに追加またはオーバーライドする方法について解説します。

### モデルとコントローラをオーバーライドする

エンジンのモデルクラスとコントローラクラスは、オープンクラスとしてメインのRailsアプリケーションで拡張可能です。Railsのモデルクラスとコントローラクラスは、Rails特有の機能を継承しているほかは通常のRubyクラスと変わりありません。エンジンのクラスをオープンクラス化 (open classing) することで、メインのアプリケーションで使用できるように再定義されます。これは、デザインパターンで言うdecoratorパターンとして実装するのが普通です。

クラスの変更内容が単純であれば、`Class#class_eval`を使用します。クラスの変更が複雑な場合は、`ActiveSupport::Concern`の使用をご検討ください。

#### デコレータとコードの読み込みに関するメモ

Railsアプリケーション自身はこれらのデコレータを参照することはないので、Railsの自動読み込み機能ではこれらのデコレータを読み込んだり起動したりできません。つまり、デコレータは手動でrequireする必要があるということです。

これを行なうためのサンプルコードをいくつか掲載します。

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh

    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
```

上のコードは、デコレータだけではなく、メインのアプリケーションから参照されないすべてのエンジンのコードを読み込みます。

#### Class#class_evalを使用してdecoratorパターンを実装する

`Article#time_since_created`を**追加する**場合:

```ruby
# MyApp/app/decorators/models/blorgh/article_decorator.rb

Blorgh::Article.class_eval do
  def time_since_created
    Time.current - created_at
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ActiveRecord::Base
  has_many :comments
end
```


`Article#summary`を**オーバーライド**する場合:

```ruby
# MyApp/app/decorators/models/blorgh/article_decorator.rb

Blorgh::Article.class_eval do
  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ActiveRecord::Base
  has_many :comments
  def summary
    "#{title}"
  end
end
```

#### ActiveSupport::Concernを使用してdecoratorパターンを実装する

`Class#class_eval`は単純な調整には大変便利ですが、クラスの変更が複雑になるのであれば[`ActiveSupport::Concern`] (http://edgeapi.rubyonrails.org/classes/ActiveSupport/Concern.html)をご検討ください。ActiveSupport::Concernは、相互にリンクしている依存モジュールおよび依存クラスの実行時読み込み順序を管理し、コードのモジュール化を高めます。

`Article#time_since_created`を**追加**して`Article#summary`を**オーバーライド**する場合:

```ruby
# MyApp/app/models/blorgh/article.rb

class Blorgh::Article < ActiveRecord::Base
  include Blorgh::Concerns::Models::Article

  def time_since_created
    Time.current - created_at
  end

  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ActiveRecord::Base
  include Blorgh::Concerns::Models::Article
end
```

```ruby
# Blorgh/lib/concerns/models/article

module Blorgh::Concerns::Models::Article
  extend ActiveSupport::Concern

  # 'included do'は、インクルードされたコードを
  # それがインクルードされている (article.rb) コンテキストで評価する
  # そのモジュールのコンテキストで実行されている (blorgh/concerns/models/article) は評価しない
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_save :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end

  def summary
    "#{title}"
  end

  module ClassMethods
    def some_class_method
      'some class method string'
    end
  end
end
```

### ビューをオーバーライドする

Railsは出力すべきビューを探索する際に、アプリケーションの`app/views`ディレクトリを最初に探索します。探しているビューがそこにない場合、続いてそのディレクトリを持つすべてのエンジンの`app/views`ディレクトリを探索します。

たとえば、アプリケーションが`Blorgh::ArticlesController`のindexアクションの結果を出力するためのビューを探索する際には、最初にアプリケーション自身の`app/views/blorgh/articles/index.html.erb`を探索します。そこに見つからない場合は、続いてエンジンの中を探索します。

`app/views/blorgh/articles/index.html.erb`というファイルを作成することで、上の動作を上書きすることができます。こうすることで、通常のビューでの出力結果を完全に変えることができます。

`app/views/blorgh/articles/index.html.erb`というファイルを作成して以下のコードを追加するとします。

```html+erb
<h1>Articles</h1>
<%= link_to "New Article", new_article_path %>
<% @articles.each do |article| %>
  <h2><%= article.title %></h2>
  <small>By <%= article.author %></small>
  <%= simple_format(article.text) %>
  <hr>
<% end %>
```

### ルーティング

デフォルトでは、エンジン内部のルーティングはアプリケーションのルーティングから分離されています。これは、`Engine`クラス内の`isolate_namespace`呼び出しによって実現されます。これは本質的に、アプリケーションとエンジンが完全に同一の名前のルーティングを持つことができ、しかも衝突しないということを意味します。

エンジン内部のルーティングは、以下のように`config/routes.rb`の`Engine`クラスによって構成されます。

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

エンジンとアプリケーションのルーティングがこのように分離されているので、アプリケーションの特定の部分をエンジンの特定の部分にリンクしたい場合は、エンジンのルーティングプロキシメソッドを使用する必要があります。`articles_path`のような通常のルーティングメソッドの呼び出しは、アプリケーションとエンジンの両方でそのようなヘルパーが定義されている場合には期待と異なる場所にリンクされる可能性があります。

たとえば以下のコード例では、そのテンプレートがアプリケーションでレンダリングされる場合の行き先はアプリケーションの`articles_path`になり、エンジンでレンダリングされる場合の行き先はエンジンの`articles_path`になります。

```erb
<%= link_to "Blog articles", articles_path %>
```

このルーティングを常にエンジンの`articles_path`ルーティングヘルパーメソッドで取り扱うようにしたい場合、以下のようにエンジンと同じ名前を共有するルーティングプロキシメソッドを呼び出す必要があります。

```erb
<%= link_to "Blog articles", blorgh.articles_path %>
```

逆にエンジン内部からアプリケーションを参照する場合は、同じ要領で`main_app`を使用します。

```erb
<%= link_to "Home", main_app.root_path %>
```

上のコードをエンジン内で使用すると、行き先は**常に**アプリケーションのルートになります。この`main_app`ルーティングプロキシメソッドを呼び出しを省略すると、行き先は呼び出された場所によってアプリケーションまたはエンジンのいずれかとなって確定しません。

ルーティングプロキシメソッド呼び出しを省略したこのようなアプリケーションルーティングヘルパーメソッドを、エンジン内でレンダリングされるテンプレートから呼び出そうとすると、未定義メソッド呼び出しエラーが発生することがあります。このような問題が発生した場合は、アプリケーションのルーティングメソッドを、`main_app`というプレフィックスを付けずにエンジンから呼びだそうとしていないかどうかを確認してください。

### アセット

エンジンのアセットは、通常のアプリケーションで使用されるアセットとまったく同じように機能します。エンジンのクラスは`Rails::Engine`を継承しているので、アプリケーションはエンジンの'app/assets'ディレクトリと'lib/assets'ディレクトリを探索対象として認識します。

エンジン内の他のコンポーネントと同様、アセットも名前空間化される必要があります。たとえば、`style.css`というアセットは、`app/assets/stylesheets/style.css`ではなく`app/assets/stylesheets/[エンジン名]/style.css`に置かれる必要があります。アセットが名前空間化されないと、ホストアプリケーションに同じ名前のアセットが存在する場合にアプリケーションのアセットが使用されてエンジンのアセットが使用されないということが発生する可能性があります。

`app/assets/stylesheets/blorgh/style.css`というアセットを例にとって説明します。このアセットをアプリケーションに含めるには、`stylesheet_link_tag`を使用してアセットがあたかもエンジン内部にあるかのように参照します。

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

処理されるファイルでアセットパイプラインのrequireステートメントを使用して、これらのアセットが他のアセットに依存することを指定することもできます。

```
/*
*= require blorgh/style
*/
```

INFO: SassやCoffeeScriptなどの言語を使用する場合は、必要なライブラリを`.gemspec`に追加する必要があります。

### アセットとプリコンパイルを分離する

エンジンが持つアセットは、ホスト側のアプリケーションでは必ずしも必要ではないことがあります。たとえば、エンジンでしか使用しない管理機能を作成したとしましょう。この場合、ホストアプリケーションでは`admin.css`や`admin.js`は不要です。これらのアセットを必要とするのは、gemのadminレイアウトしかないからです。ホストアプリケーションから見れば、自分が持つスタイルシートに`"blorgh/admin.css"`を追加する意味はありません。このような場合、これらのアセットを明示的にプリコンパイルする必要があります。それにより、`bin/rails assets:precompile`が実行されたときにエンジンのアセットを追加するようsprocketsに指示されます。

プリコンパイルの対象となるアセットは`engine.rb`で定義できます。

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w(admin.css admin.js)
end
```

詳細については、[アセットパイプライン](asset_pipeline.html)ガイドを参照してください。

### 他のgemとの依存関係

エンジンが依存するgemについては、エンジンのルートディレクトリの`.gemspec`に記述する必要があります。エンジンはgemとしてインストールされるので、このようにする必要があります。依存関係を`Gemfile`に指定したのでは伝統的なgemインストールで依存関係が認識されないので、必要なgemが自動的にインストールされず、エンジンが正常に機能しなくなります。

伝統的な`gem install`コマンド実行時に同時にインストールされる必要のあるgemを指定するには、以下のようにエンジンの`.gemspec`ファイルにある`Gem::Specification`ブロックの内側に記述します。

```ruby
s.add_dependency "moo"
```

アプリケーションの開発時にのみ必要となるgemのインストールを指定するには、以下のように記述します。

```ruby
s.add_development_dependency "moo"
```

どちらの依存gemも、アプリケーションで`bundle install`を実行するときにインストールされます。開発時にのみ必要となるgemは、エンジンのテスト実行中にのみ使用されます。

エンジンがrequireされるときに依存gemもすぐにrequireしたい場合は、以下のようエンジンが初期化されるより前にrequireする必要があることにご注意ください。たとえば次のようになります。

```ruby
require 'other_engine/engine'
require 'yet_another_engine/engine'

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```