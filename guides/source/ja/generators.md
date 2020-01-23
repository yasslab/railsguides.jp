
Rails ジェネレータとテンプレート入門
=====================================================

Railsの各種ジェネレータは、ワークフローを改善するために欠かせないツールです。本ガイドは、Railsジェネレータの作成方法および既存のジェネレータのカスタマイズ方法について解説します。

このガイドの内容:

* アプリケーションで利用できるジェネレータを確認する方法
* テンプレートを使用してジェネレータを作成する方法
* Railsがジェネレータの起動前に探索するときの方法
* RailsがテンプレートからRailsコードを内部的に生成する方法
* ジェネレータを自作することでscaffoldをカスタマイズする方法
* ジェネレータのテンプレートを変更することでscaffoldをカスタマイズする方法
* 多数のジェネレータをうっかり上書きしないためのフォールバック使用法
* アプリケーションテンプレートの作成方法

--------------------------------------------------------------------------------

ジェネレータとの最初の出会い
-------------

`rails`コマンドでRailsアプリケーションを作成すると、実はRailsのジェネレータを利用したことになります。続いて、単に`rails generate`と入力して実行すると、その時点でアプリケーションから利用可能なすべてのジェネレータのリストが表示されます。

```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

Railsで利用可能なすべてのジェネレータのリストが表示されます。たとえばヘルパージェネレータの詳細な説明が知りたい場合は以下のように入力します。

```bash
$ bin/rails generate helper --help
```

初めてジェネレータを作成する
-----------------------------

Railsのジェネレータは、Rails 3.0以降は[Thor](https://github.com/erikhuda/thor)の上に構築されています。Thorは強力な解析オプションと優れたファイル操作APIを提供しています。具体例として、`config/initializers`ディレクトリの下に`initializer.rb`という名前のイニシャライザファイルを1つ作成するジェネレータを構成してみましょう。

最初の手順として、以下の内容を持つ`lib/generators/initializer_generator.rb`というファイルを1つ作成します。

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

NOTE: `create_file`メソッドは`Thor::Actions`によって提供されています。`create_file`およびその他のThorのメソッドのドキュメントについては[Thorドキュメント](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)を参照してください。

今作成した新しいジェネレータはきわめてシンプルです。`Rails::Generators::Base`を継承しており、メソッド定義はひとつだけです。ジェネレータが起動されると、ジェネレータ内で定義されているパブリックメソッドが定義順に実行されます。最終的に`create_file`メソッドが呼び出され、指定の内容を持つファイルが指定のディレクトリに1つ作成されます。RailsのアプリケーションテンプレートAPIを使い慣れている開発者であれば、すぐにも新しいジェネレータAPIに熟達できることでしょう。

以下を実行するだけで、この新しいジェネレータを呼び出すことができます。

```bash
$ bin/rails generate initializer
```

次に進む前に、今作成したばかりのジェネレータの説明を表示してみましょう。

```bash
$ bin/rails generate initializer --help
```

Railsでは、ジェネレータが`ActiveRecord::Generators::ModelGenerator`のように名前空間化されていれば実用的な説明文を生成できますが、この場合は残念ながらそのようになっていません。この問題は2とおりの方法で解決することができます。1つ目の方法は、ジェネレータ内で`desc`メソッドを呼び出すというものです。

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "このジェネレータはconfig/initializersにイニシャライザファイルを作成する"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# イニシャライザの内容をここに記述"
  end
end
```

これで、`--help`を付けて新しいジェネレータを呼び出すと新しい説明文が表示されるようになりました。説明文を追加する2番目の方法は、ジェネレータと同じディレクトリに`USAGE`という名前のファイルを作成することです。次に、この方法で実際に説明文を追加してみましょう。

ジェネレータを使用してジェネレータを生成する
-----------------------------------

Railsには、ジェネレータを生成するためのジェネレータもあります。

```bash
$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

上で作成したジェネレータの内容は以下のとおりです。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

上のジェネレータを見て最初に気付く点は、`Rails::Generators::Base`ではなく`Rails::Generators::NamedBase`を継承していることでしょう。これは、このジェネレータを生成するためには少なくとも1つの引数が必要であることを意味します。この引数はイニシャライザの名前であり、コードではこのイニシャライザ名を`name`という変数で参照できます。

新しいジェネレータを呼び出せば説明文が表示されます。なお、古いジェネレータファイルは必ず削除しておいてください。

```bash
$ bin/rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

新しいジェネレータには`source_root`という名前のクラスメソッドも含まれています。このメソッドは、ジェネレータのテンプレートの置き場所を指定する場合に使用します。デフォルトでは、作成された`lib/generators/initializer/templates`ディレクトリを指します。

ジェネレータのテンプレートの機能を理解するために、`lib/generators/initializer/templates/initializer.rb`を作成して以下の内容を追加してみましょう。

```ruby
# 初期化内容をここに追記する
```

続いてジェネレータを変更し、呼び出されたときにこのテンプレートをコピーするようにします。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

それではこのジェネレータを実行してみましょう。

```bash
$ bin/rails generate initializer core_extensions
```

`config/initializers/core_extensions.rb`にcore_extensionsという名前のイニシャライザが作成され、そこにさっきのテンプレートが反映されていることが確認できます。`copy_file`メソッドはコピー元のルートディレクトリから、指定のパスにファイルをひとつコピーしています。`file_name`メソッドは`Rails::Generators::NamedBase`を継承したことで自動的に作成されます。

ジェネレータ関連で利用できるメソッドについては、本章の[最終セクション](#ジェネレータメソッド)で扱っています。

ジェネレータが参照するファイル
-----------------

`rails generate initializer core_extensions`を実行するとき、Railsは以下のファイルを上から順に見つかるまでrequireします。

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

どのファイルも見つからない場合はエラーメッセージが表示されます。

INFO: 上の例ではアプリケーションの`lib`ディレクトリの下にファイルを置いていますが、これらのディレクトリは`$LOAD_PATH`に属していることがその理由です。

ワークフローをカスタマイズする
-------------------------

Rails自身が持つジェネレータはscaffoldを柔軟にカスタマイズできます。設定は`config/application.rb`で行います。デフォルトのコードを以下にいくつか示します。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

ワークフローをカスタマイズする前のscaffoldは以下のように動作します。

```bash
$ bin/rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20130924151154_create_users.rb
      create    app/models/user.rb
      invoke  test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb 
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      invoke  test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.js.coffee
      invoke    scss
      create      app/assets/stylesheets/users.css.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.css.scss
```

この出力結果から、Rails 3.0以降のジェネレータの動作を容易に理解できます。実はscaffoldジェネレータ自身は何も生成していません。生成に必要なメソッドを順に呼び出しているだけです。このような仕組みになっているので、呼び出しを自由に追加/置換/削除できます。たとえば、scaffoldジェネレータはscaffold_controllerというジェネレータを呼び出しています。これはerbのジェネレータ、test_unitのジェネレータ、そしてヘルパーのジェネレータを呼び出します。ジェネレータごとに役割がひとつずつ割り当てられているので、コードを再利用しやすく、コードの重複も防げます。

最初のカスタマイズとして、ワークフローでスタイルシートとJavaScriptとテストフィクスチャファイルをscaffoldで生成しないようにしてみましょう。これは、以下のように設定を変更することで行うことができます。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

scaffoldジェネレータでふたたびリソースを生成してみると、今度はスタイルシートとJavaScriptファイルとフィクスチャが生成されなくなります。ジェネレータをさらにカスタマイズしたい場合 (Active RecordとTestUnitをDataMapperとRSpecに置き換えるなど) は、必要なgemをアプリケーションに追加してジェネレータを設定するだけで済みます。

ジェネレータのカスタマイズ例を説明するために、ここで新しくヘルパージェネレータをひとつ作成してみましょう。このジェネレータはインスタンス変数を読み出すメソッドをいくつか追加するだけのシンプルなものです。最初に、Railsの名前空間の内側でジェネレータをひとつ作成します。名前空間の内側にする理由は、Railsはフックとして使用されるジェネレータを名前空間内で探索するからです。

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
```

続いて、`templates`ディレクトリと`source_root`クラスメソッド呼び出しは使う予定がないのでジェネレータから削除します。ジェネレータにメソッドを追加して以下のようにしましょう。

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end
end
```

新しく作ったジェネレータでproductsのヘルパーを実際に作成してみましょう。

```bash
$ bin/rails generate my_helper products
      create  app/helpers/products_helper.rb
```

上を実行すると`app/helpers`に以下の内容を持つヘルパーが作成されます。

```ruby
module ProductsHelper
  attr_reader :products, :product
end
```

期待どおりの結果が得られました。上で生成したヘルパージェネレータをscaffoldで実際に使ってみるために、今度は`config/application.rb`を編集して以下のように変更してみましょう。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
  g.helper          :my_helper
end
```

scaffoldを実行すると、ジェネレータの呼び出し時に以下のようになることが確認できます。

```bash
$ bin/rails generate scaffold Article body:text
      [...]
      invoke    my_helper
      create      app/helpers/articles_helper.rb
```

出力結果がRailsのデフォルトではなくなり、新しいヘルパーに従っていることがわかります。しかしここでもうひとつやっておかなければならないことがあります。新しいジェネレータにもテストを作成しておかなければなりません。そのために、元のヘルパーのテストジェネレータを再利用することにします。

Rails 3.0以降では「フック」という概念が利用できるので、このような再利用が簡単に行えます。今作ったヘルパーは特定のテストフレームワークのみに限定する必要はないため、ヘルパーがフックをひとつ提供し、テストフレームワークでそのフックを実装して互換性を得れば十分です。

これを実現するために、ジェネレータを以下のように変更しましょう。

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end

  hook_for :test_framework
end
```

これで、ヘルパージェネレータが呼び出されてTestUnitがテストフレームワークとして設定されると、`Rails::TestUnitGenerator`と`TestUnit::MyHelperGenerator`を両方とも呼びだそうとします。しかしどちらも未定義なので、Railsのジェネレータとして実際に定義されている`TestUnit::Generators::HelperGenerator`を代わりに呼び出すようジェネレータに指定することができます。具体的には、以下を追加するだけで済みます。

```ruby
# :my_helperではなく:helperを探索する
hook_for :test_framework, as: :helper
```

これでscaffoldを再実行すれば、作成されたリソースにテストも含まれているはずです。

ジェネレータのテンプレートを変更してワークフローをカスタマイズする
----------------------------------------------------------

上でご紹介した手順では、生成されたヘルパーに一行追加しただけで、それ以外に何の機能も追加されていませんでした。同じことをもっと簡単に行う方法があります。それには、既存のジェネレータ (ここでは`Rails::Generators::HelperGenerator`) のテンプレートを置き換えます。

Rails 3.0以降では、ジェネレータはソースルート・ディレクトリでテンプレートがあるかどうかを単に探すだけではなく、他のパスでもテンプレートを探します。`lib/templates`ディレクトリもこの探索対象に含まれています。`Rails::Generators::HelperGenerator`をカスタマイズするには、`lib/templates/rails/helper`ディレクトリの中に`helper.rb`というテンプレートのコピーを作成します。このファイルを作成後、以下のコードを追加します。

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

次に、`config/application.rb`の変更を元に戻します。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

リソースをもう一度作成してみると、最初の手順のときとまったく同じ結果が得られます。この方法は、`lib/templates/erb/scaffold`ディレクトリの下に`edit.html.erb`や`index.html.erb`を作成することでscaffoldテンプレートやレイアウトをカスタマイズしたい場合に便利です。

RailsのscaffoldテンプレートではERBタグが多用されますが、これらが正常に生成されるためにはERBタグをエスケープしておく必要があります。

たとえば、テンプレートで以下のようなエスケープ済みERBタグが必要になることがあります (`%`文字が1つ多い点にご注目ください)。

```ruby
<%%= stylesheet_include_tag :application %>
```

上のコードから以下の出力が生成されます。

```ruby
<%= stylesheet_include_tag :application %>
```

ジェネレータにフォールバックを追加する
---------------------------

最後にご紹介するジェネレータの機能はフォールバックです。これはプラグインのジェネレータを使用する場合に便利です。たとえば、TestUnitに[shoulda](https://github.com/thoughtbot/shoulda)のような機能を追加したいとします。TestUnitはRailsでrequireされるすべてのジェネレータで実装済みであり、shouldaではその一部を上書きするだけでよいはずです。このように、shouldaで実装する必要のないジェネレータの機能がいくつもあるので、Railsでは`Shoulda`の名前空間で見つからないものについてはすべて`TestUnit`ジェネレータのものを使用するように指定するだけでフォールバックを実現できます。

先に変更を加えた`config/application.rb`にふたたび変更を加えることで、この動作を簡単にシミュレートできます。

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # フォールバックを追加する
  g.fallbacks[:shoulda] = :test_unit
end
```

これで、scaffoldでCommentを生成するとshouldaジェネレータが呼び出され、最終的にTestUnitジェネレータにフォールバックされるようになります。

```bash
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20130924143118_create_comments.rb
      create    app/models/comment.rb
      invoke    shoulda
      create      test/models/comment_test.rb
      create      test/fixtures/comments.yml
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      invoke    shoulda
      create      test/controllers/comments_controller_test.rb
      invoke    my_helper
      create      app/helpers/comments_helper.rb
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/comments.js.coffee
      invoke    scss
```

フォールバックを利用するとジェネレータの役割がひとつで済み、コードの重複を防いで再利用性を高めることができます。

アプリケーションテンプレート
---------------------

ここまでで、Railsアプリケーション _内部_ でのジェネレータの動作を解説しましたが、ジェネレータを使用して独自のRailsアプリケーション自身を生成することもできることをご存じでしょうか。このような目的で使用されるジェネレータは「アプリケーションテンプレート」と呼ばれます。ここではTemplates APIを簡単にご紹介します。詳細については[Railsアプリケーションテンプレート入門](rails_application_templates.html)を参照してください。

```ruby
gem "rspec-rails", group: "test"
gem "cucumber-rails", group: "test"

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
end
```

上のテンプレートでは、Railsアプリケーションが`rspec-rails`と`cucumber-rails` gemに依存するように指定しています。この指定により、これらのgemは`Gemfile`の`test`グループに追加されます。続いて、Devise gemをインストールするかどうかをユーザーに問い合わせます。ユーザーが "y" または "yes" を入力すると`Gemfile`にDevise gemが追加され (特定のgemグループには含まれません)、`devise:install`ジェネレータが実行されます。さらに続いてユーザー入力を受け付け、`devise`のジェネレータにその入力結果を渡してジェネレータを実行します。

このテンプレートが`template.rb`という名前のファイルの中に含まれているとします。`-m`オプションでテンプレートのファイル名を渡すことにより、`rails new`コマンドの実行結果を変更することができます。

```bash
$ rails new thud -m template.rb
```

上のコマンドを実行すると`Thud`というアプリケーションが生成され、その結果にテンプレートが適用されます。

テンプレートの保存先はローカルでなくてもかまいません。`-m`で指定するテンプレートの保存先としてオンライン上もサポートされています。

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

本章の最後のセクションでは、テンプレートで自由に使えるメソッドを多数紹介していますので、これを使用して自分好みのテンプレートを開発することができます。よく知られた素晴らしいアプリケーションテンプレートの数々を実際に生成する方法までは紹介しきれませんでしたが、何とぞご了承ください。これらのメソッドはジェネレータでも同じように使用できます。

ジェネレータメソッド
-----------------

以下のメソッドはRailsのジェネレータとテンプレートのどちらでも同じように使用できます。

NOTE: Thorが提供するメソッドについては本章では扱いません。[Thorのドキュメント](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)を参照してください。

### `gem`

Railsアプリケーションのgem依存を指定します。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

以下のオプションを利用できます。

* `:group` - gemを追加する`Gemfile`内のグループを指定します。
* `:version` - 使用するgemのバージョンを指定します。`version`オプションを明記せずに、メソッドの第2引数としてバージョンを指定することもできます。
* `:git` - gemが置かれているgitリポジトリを指すURLを指定します。

メソッドでこれら以外のオプションも使用する場合は、以下のように行の最後に記述します。

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

上のコードが実行されると、`Gemfile`に以下の行が追加されます。

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

gemのエントリを指定のグループに含めます。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

指定のソースを`Gemfile`に追加します。

```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

ファイル内の指定の場所にコードブロックをひとつ挿入します。

```ruby
inject_into_file 'name_of_file.rb', after: "#挿入したいコードを次の行に置く。最後のend\nの後ろには必ず改行を入れること。" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

ファイル内のテキストを置き換えます。

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

正規表現を使用して置き換え方法を精密に指定できます。`append_file`を使用してコードをファイルの末尾に追加したり、`prepend_file`を使用してコードをファイルの冒頭に挿入したりすることもできます。

### `application`

`config/application.rb`ファイル内でアプリケーションクラス定義の直後に指定の行を追加します。

```ruby
application "config.asset_host = 'http://example.com'"
```

このメソッドにはブロックを渡すこともできます。

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

以下のオプションを利用できます。

* `:env` - 設定オプションの環境を指定します。ブロック構文を使用する場合は以下のようにすることが推奨されます。

```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
end
```

### `git`

gitコマンドを実行します。

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

引数またはオプションとなるハッシュの値は、指定のgitコマンドに渡されます。上の最後の行で示しているように、一行に複数のgitコマンドを記述することができますが、この場合コマンドの実行順序は記載順になるとは限らないので注意が必要です。

### `vendor`

指定のコードを含むファイルを`vendor`ディレクトリに置きます。

```ruby
vendor "sekrit.rb", '#極秘
```

このメソッドにはブロックをひとつ渡すこともできます。

```ruby
vendor "seeds.rb" do
  "puts 'in your app, seeding your database'"
end
```

### `lib`

指定のコードを含むファイルを`lib`ディレクトリに置きます。

```ruby
lib "special.rb", "p Rails.root"
```

このメソッドにはブロックをひとつ渡すこともできます。

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

Railsアプリケーションの`lib/tasks`ディレクトリにRakeファイルをひとつ作成します。

```ruby
rakefile "test.rake", "hello there"
```

このメソッドにはブロックをひとつ渡すこともできます。

```ruby
rakefile "test.rake" do
  %Q{
    task rock: :environment do
      puts "Rockin'"
    end
  }
end
```

### `initializer`

Railsアプリケーションの`lib/initializers`ディレクトリにイニシャライザファイルをひとつ作成します。

```ruby
initializer "begin.rb", "puts 'ここが最初の部分'"
```

このメソッドにはブロックをひとつ渡すこともでき、文字列が返されます。

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

指定のジェネレータを実行します。第1引数は実行するジェネレータ名で、残りの引数はジェネレータにそのまま渡されます。

```ruby
generate "scaffold", "forums title:string description:text"
```


### `rake`

Rakeタスクを実行します。

```ruby
rake "db:migrate"
```

以下のオプションを利用できます。

* `:env` - rakeタスクを実行するときの環境を指定します。
* `:sudo` - rakeタスクで`sudo`を使用するかどうかを指定します。デフォルトは`false`です。

### `capify!`

Capistranoの`capify`コマンドをアプリケーションのルートディレクトリで実行し、Capistranoの設定を生成します。

```ruby
capify!
```

### `route`

`config/routes.rb`ファイルにテキストを追加します。

```ruby
route "resources :people"
```

### `readme`

テンプレートの`source_path`にあるファイルの内容を出力します。通常このファイルはREADMEです。

```ruby
readme "README"
```