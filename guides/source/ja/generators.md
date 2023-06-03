Rails ジェネレータとテンプレート入門
=====================================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[Creating and Customizing Rails Generators & Templates](https://guides.rubyonrails.org/generators.html)を日本語に翻訳した文書です。

Railsの各種ジェネレータは、ワークフローの改善に欠かせないツールです。本ガイドは、Railsジェネレータの作成方法および既存のジェネレータのカスタマイズ方法について解説します。

このガイドの内容:

* アプリケーションで利用できるジェネレータを確認する方法
* テンプレートでジェネレータを作成する方法
* Railsがジェネレータを起動前に探索する方法
* RailsがテンプレートからRailsコードを内部的に生成する方法
* ジェネレータを自作してscaffoldをカスタマイズする方法
* ジェネレータのテンプレートを変更してscaffoldをカスタマイズする方法
* 多数のジェネレータを誤って上書きしないためのフォールバック方法
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

NOTE: Railsアプリケーションを新しく作成するときは、`gem install rails`でインストールしたrails gemのグローバルな`rails`コマンドを使いますが、作成したアプリケーションのディレクトリ内では、そのアプリケーション内にバンドルされている`bin/rails`コマンドを使う点が異なります。

Railsで利用可能なすべてのジェネレータのリストを表示できます。たとえばヘルパージェネレータの詳細な説明を表示するには以下のように入力します。

```bash
$ bin/rails generate helper --help
```

最初のジェネレータを作成する
-----------------------------

Rails 3.0以降のジェネレータは[Thor][] gemの上に構築されています。Thorは強力な解析オプションと優れたファイル操作APIを提供しています。具体例として、`config/initializers`ディレクトリの下に`initializer.rb`という名前のイニシャライザファイルを1つ作成するジェネレータを構成してみましょう。

最初の手順として、以下の内容の`lib/generators/initializer_generator.rb`というファイルを1つ作成します。

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# （イニシャライザの内容をここに記述する）"
  end
end
```

NOTE: `create_file`メソッドは`Thor::Actions`によって提供されています。`create_file`およびその他のThorのメソッドのドキュメントについては[Thorのドキュメント][Thor Actions]を参照してください。

新しいジェネレータはきわめてシンプルです。`Rails::Generators::Base`を継承しており、メソッド定義は1つだけです。ジェネレータが起動されると、ジェネレータ内で定義されているパブリックメソッドが定義順に実行されます。最終的に`create_file`メソッドが呼び出され、指定の内容を持つファイルが指定のディレクトリに1つ作成されます。RailsのアプリケーションテンプレートAPIを使い慣れている開発者であれば、すぐにも新しいジェネレータAPIに熟達できることでしょう。

以下を実行するだけで、新しいジェネレータを呼び出せます。

```bash
$ bin/rails generate initializer
```

次に進む前に、今作成したばかりのジェネレータの説明を表示してみましょう。

```bash
$ bin/rails generate initializer --help
```

Railsでは、ジェネレータが`ActiveRecord::Generators::ModelGenerator`のように名前空間化されていれば実用的な説明文を生成できますが、今作成したジェネレータはそうなっていません。この問題は2とおりの方法で解決できます。1つ目の方法は、ジェネレータ内で`desc`メソッドを呼び出すことです。

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "このジェネレータはconfig/initializersにイニシャライザファイルを作成する"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# （イニシャライザの内容をここに記述する）"
  end
end
```

これで、`--help`を付けて新しいジェネレータを呼び出すと新しい説明文が表示されるようになりました。
説明文を追加する2つ目の方法は、ジェネレータと同じディレクトリに`USAGE`という名前のファイルを作成することです。次に、この方法で実際に説明文を追加してみましょう。

[Thor]: https://github.com/erikhuda/thor
[Thor Actions]: https://www.rubydoc.info/gems/thor/Thor/Actions

ジェネレータでジェネレータを生成する
-----------------------------------

Railsには、ジェネレータを生成するためのジェネレータもあります。

```bash
$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
      invoke  test_unit
      create    test/lib/generators/initializer_generator_test.rb
```

上で作成したジェネレータの内容は以下のとおりです。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
end
```

上のジェネレータを見て最初に気付く点は、`Rails::Generators::Base`ではなく`Rails::Generators::NamedBase`を継承していることです。これは、このジェネレータを生成するには少なくとも1つの引数が必要であることを意味します。この引数はイニシャライザ名で、コードはこのイニシャライザ名を`name`という変数で参照できます。

新しいジェネレータを呼び出せば説明文が表示されます（古いジェネレータファイルを削除しておくのをお忘れなく）。

```bash
$ bin/rails generate initializer --help
Usage:
  bin/rails generate initializer NAME [options]
```

新しいジェネレータには`source_root`という名前のクラスメソッドも含まれています。このメソッドは、ジェネレータのテンプレートの置き場所を指定する場合に使います。デフォルトでは、作成された`lib/generators/initializer/templates`ディレクトリを指します。

ジェネレータのテンプレートの機能を理解するために、`lib/generators/initializer/templates/initializer.rb`を作成して以下の内容を追加してみましょう。

```ruby
# （初期化内容をここに追記する）
```

続いてジェネレータを変更し、呼び出されたときにこのテンプレートをコピーするようにします。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

それではこのジェネレータを実行してみましょう。

```bash
$ bin/rails generate initializer core_extensions
```

`config/initializers/core_extensions.rb`にcore_extensionsという名前のイニシャライザが作成され、そこにさっきのテンプレートが反映されていることが確認できます。`copy_file`メソッドはコピー元のルートディレクトリから、指定のパスにファイルを1つコピーしています。`file_name`メソッドは`Rails::Generators::NamedBase`を継承したことで自動的に作成されます。

ジェネレータ関連で利用できるメソッドについては、本章の[最終セクション](#ジェネレータメソッド)で扱っています。

ジェネレータが参照するファイル
-----------------

`rails generate initializer core_extensions`を実行すると、Railsは以下のファイルを上から順に探索して、見つけたものを`require`します。

```
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

どのファイルも見つからない場合はエラーメッセージが表示されます。

INFO: 上の例でアプリケーションの`lib`ディレクトリの下にファイルを置いているのは、このディレクトリが`$LOAD_PATH`に属しているからです。

ワークフローをカスタマイズする
-------------------------

Rails自身が持つscaffold（足場）ジェネレータは、柔軟にカスタマイズできます。設定は`config/application.rb`で行います。デフォルトのコードを以下にいくつか示します。

```ruby
config.generators do |g|
  g.orm             :active_record
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
      invoke    test_unit
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
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  test_unit
      create    test/application_system_test_case.rb
      create    test/system/users_test.rb
```

この出力結果から、Rails 3.0以降のジェネレータの動作を容易に理解できます。実はscaffoldジェネレータ自身は何も生成しておらず、生成に必要なメソッドを順に呼び出しているだけです。このような仕組みになっているので、呼び出しを自由に追加・置換・削除できます。たとえば、scaffoldジェネレータは`scaffold_controller`というジェネレータを呼び出しています。これは`erb`のジェネレータ、`test_unit`のジェネレータ、そして`helper`のジェネレータを呼び出します。ジェネレータごとに役割が1つずつ割り当てられているので、コードを再利用しやすく、コードの重複も防げます。

次に、scaffoldをカスタマイズしてテストのfixtureファイルの生成を止めてみましょう。設定ファイルを以下のように変更することで無効にできます。

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
end
```

scaffoldジェネレータでもう1つリソースを生成してみると、今度はフィクスチャが生成されなくなります。ジェネレータをさらにカスタマイズしたい場合（Active RecordとTestUnitをそれぞれDataMapperとRSpecに置き換えるなど）は、必要なgemをアプリケーションに追加してジェネレータを設定するだけでできます。

ジェネレータのカスタマイズ例を説明するために、ここで新しくヘルパージェネレータを1つ作成してみましょう。このジェネレータはインスタンス変数を読み出すメソッドをいくつか追加するだけのシンプルなものです。最初に、Railsの名前空間の内側でジェネレータを1つ作成します。名前空間の内側にする理由は、Railsはフックとして使われるジェネレータを名前空間内で探索するからです。

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
      invoke  test_unit
      create    test/lib/generators/rails/my_helper_generator_test.rb
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
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
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

出力結果がRailsのデフォルトではなくなり、新しいヘルパーに従っていることがわかります。しかしここでもう1つやっておかなければならないのは、新しいジェネレータでテストを生成することです。そのために、元のヘルパーのテストジェネレータを再利用することにします。

Rails 3.0以降では「フック」という概念が利用できるので、このような再利用が簡単に行えます。今作ったヘルパーは特定のテストフレームワークのみに限定する必要はないため、ヘルパーがフックを1つ提供し、テストフレームワークでそのフックを実装して互換性を得れば十分です。

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

上でご紹介した手順では、生成されたヘルパーに1行追加しただけで、それ以外に何の機能も追加されていませんでした。同じことをもっと簡単に行う方法があります。それには、既存のジェネレータ (ここでは`Rails::Generators::HelperGenerator`) のテンプレートを置き換えます。

Rails 3.0以降では、ジェネレータはテンプレートをソースのrootディレクトリで探索するだけでなく、他のパスでもテンプレートを探索します。`lib/templates`ディレクトリもこの探索対象に含まれています。`Rails::Generators::HelperGenerator`をカスタマイズするには、`lib/templates/rails/helper`ディレクトリの中に`helper.rb`というテンプレートのコピーを作成します。このファイルを作成後、以下のコードを追加します。

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

次に、`config/application.rb`の直前の変更を元に戻します。

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
end
```

これで、別のリソースを生成すると同様の結果が得られるようになります。

カスタムテンプレートの一般的な別の使い方は、[デフォルトのscaffoldビューテンプレート][scaffold templates]をオーバーライドすることです。これらのビューテンプレートファイルは、`lib/templates/erb/scaffold`に適切なファイル(例: `index.html.erb`、`show.html.erb`)を作成すればオーバーライドできます。

RailsのscaffoldテンプレートではERBタグが多用されますが、これらが正常に生成されるためにはERBタグをエスケープしておく必要があります。

たとえば、テンプレートで以下のようなエスケープ済みERBタグが必要になることがあります (`%`文字が1つ多い点にご注目ください)。

```erb
<%%= stylesheet_link_tag :application %>
```

上のコードから以下の出力が生成されます。

```erb
<%= stylesheet_link_tag :application %>
```

[scaffold templates]: https://github.com/rails/rails/tree/main/railties/lib/rails/generators/erb/scaffold/templates

ジェネレータにフォールバックを追加する
---------------------------

最後に紹介するジェネレータの機能はフォールバックです。これはプラグインのジェネレータを使う場合に便利です。たとえば、TestUnitに[shoulda][]のような機能を追加したいとします。TestUnitはRailsで要求されるすべてのジェネレータを既に実装しており、shouldaはその一部を上書きするだけでよいはずです。このように、shouldaで実装する必要のないジェネレータの機能がいくつもあるので、Railsでは`Shoulda`の名前空間で見つからないものについてはすべて`TestUnit`ジェネレータのものを使うように指定するだけでフォールバックを実現できます。

先に変更を加えた`config/application.rb`にふたたび変更を加えることで、この動作を簡単にシミュレートできます。

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false

  # フォールバックを追加する
  g.fallbacks[:shoulda] = :test_unit
end
```

これで、scaffoldで`Comment`を生成するとshouldaジェネレータが呼び出され、最終的にTestUnitジェネレータにフォールバックするようになります。

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
      invoke  test_unit
      create    test/application_system_test_case.rb
      create    test/system/comments_test.rb
```

フォールバックを利用するとジェネレータの責務が1つで済み、コードの重複を防いで再利用性を高められます。

[shoulda]: https://github.com/thoughtbot/shoulda

アプリケーションテンプレート
---------------------

ここまではRailsアプリケーション「内部」でのジェネレータの動作を解説しましたが、ジェネレータで独自のRailsアプリケーションも生成できることをご存じでしょうか。このような目的に使うジェネレータは「アプリケーションテンプレート」と呼ばれます。ここではTemplates APIを簡単に紹介します。詳しくは[Railsアプリケーションのテンプレート](rails_application_templates.html)を参照してください。

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

本章の最後のセクションでは、人類にとって最強のテンプレートを生成する方法まではカバーしていませんが、テンプレートで自由に使えるメソッドを多数紹介していますので、これを用いて自分好みのテンプレートを開発できます。これらのメソッドはジェネレータでも同じように利用できます。

コマンドライン引数を追加する
-----------------------------
Railsのジェネレータは、カスタムのコマンドライン引数を与えることで簡単に挙動を変更できます。この機能は[Thor][Thor class_options]を利用しています。

```ruby
class_option :scope, type: :string, default: 'read_products'
```

これで、ジェネレータを以下のように呼び出せます。

```bash
$ bin/rails generate initializer --scope write_products
```

このコマンドライン引数は、ジェネレータクラス内では`options`メソッドでアクセスできます。

```ruby
@scope = options['scope']
```

[Thor class_options]: https://www.rubydoc.info/gems/thor/Thor/Base/ClassMethods#class_options-instance_method

ジェネレータメソッド
-----------------

以下のメソッドはRailsのジェネレータとテンプレートのどちらでも同じように使えます。

NOTE: Thorが提供するメソッドについては本ガイドでは扱いません。[Thorのドキュメント][Thor Actions]を参照してください。

### `gem`

Railsのgem依存を指定します。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

以下のオプションを利用できます。

* `:group`: gemを追加する`Gemfile`内のグループを指定します。
* `:version`: 利用するgemのバージョンを指定します。`version`オプションを明記せずに、メソッドの第2引数としてバージョンを指定することもできます。
* `:git`: gemが置かれているgitリポジトリを指すURLを指定します。

メソッドでこれら以外のオプションも使う場合は、以下のように行の最後に記述します。

```ruby
gem "devise", git: "https://github.com/plataformatec/devise.git", branch: "master"
```

上のコードが実行されると、`Gemfile`に以下の行が追加されます。

```ruby
gem "devise", git: "https://github.com/plataformatec/devise.git", branch: "master"
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

このメソッドもブロックを1つ取ります。

```ruby
add_source "http://gems.github.com" do
  gem "rspec-rails"
end
```

### `inject_into_file`

ファイル内の指定の場所にコードブロックを1つ挿入します。

```ruby
inject_into_file 'name_of_file.rb', after: "#挿入したいコードを次の行に置く。末尾のend\nの後ろには必ず改行を入れること。" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

ファイル内のテキストを置き換えます。

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

正規表現で置き換え方法を精密に指定できます。`append_file`でコードをファイルの末尾に追加することも、`prepend_file`でコードをファイルの冒頭に挿入することもできます。

### `application`

`config/application.rb`ファイル内でアプリケーションクラス定義の直後に指定の行を追加します。

```ruby
application "config.asset_host = 'http://example.com'"
```

このメソッドにはブロックも渡せます。

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

以下のオプションを利用できます。

* `:env` - 設定オプションの環境を指定します。ブロック構文を使う場合は以下のようにすることが推奨されます。

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

引数またはオプションとなるハッシュの値は、指定のgitコマンドに渡されます。上の最後の行で示しているように、一行に複数のgitコマンドを記述できますが、この場合コマンドの実行順序は記載順になるとは限らないので注意が必要です。

### `vendor`

指定のコードを含むファイルを`vendor`ディレクトリに置きます。

```ruby
vendor "sekrit.rb", '#極秘
```

このメソッドにはブロックも渡せます。

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

このメソッドにはブロックも渡せます。

```ruby
lib "super_special.rb" do
  "puts 'Super special!'"
end
```

### `rakefile`

Railsの`lib/tasks`ディレクトリにRakeファイルを1つ作成します。

```ruby
rakefile "test.rake", 'task(:hello) { puts "Hello, there" }'
```

このメソッドにはブロックも渡せます。

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

Railsの`lib/initializers`ディレクトリにイニシャライザファイルを1つ作成します。

```ruby
initializer "begin.rb", "puts 'ここが最初の部分'"
```

このメソッドにはブロックを1つ渡すこともでき、文字列が返されます。

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

* `:env`: rakeタスクを実行するときの環境を指定します。
* `:sudo`: rakeタスクで`sudo`を使うかどうかを指定します。デフォルトは`false`です。

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
