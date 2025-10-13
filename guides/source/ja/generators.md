Rails ジェネレータとテンプレート入門
=====================================================

Railsの各種ジェネレータとアプリケーションテンプレートは、定型コードを自動的に生成してワークフローを改善するツールとして非常に有用です。

このガイドの内容:

* アプリケーションで利用できるジェネレータを確認する方法
* テンプレートでジェネレータを作成する方法
* Railsがジェネレータを起動前に探索する方法
* ジェネレータとテンプレートをオーバーライドしてscaffoldをカスタマイズする方法
* 多数のジェネレータを誤って上書きしないためのフォールバック方法
* Railsアプリケーションをテンプレートで作成・カスタマイズする方法
* RailsテンプレートAPIを使って独自の再利用可能なアプリケーションテンプレートを書く方法

--------------------------------------------------------------------------------


ジェネレータとの最初の出会い
-------------

`rails`コマンドでRailsアプリケーションを作成すると、実はRailsのジェネレータを利用したことになります。以後は、`bin/rails generate`を実行すれば、その時点でアプリケーションから利用可能なすべてのジェネレータのリストが表示されます。

```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

NOTE: Railsアプリケーションを新しく作成するときは、`gem install rails`でインストールしたrails gemのグローバルな`rails`コマンドを使いますが、作成したアプリケーションのディレクトリ内では、そのアプリケーション内にバンドルされている`bin/rails`コマンドを使う点が異なります。

Railsで利用可能なすべてのジェネレータのリストを表示できます。特定のジェネレータのヘルプを表示するには、そのジェネレータ名に続けて以下のように`--help`オプションを指定します。

```bash
$ bin/rails generate scaffold --help
```

最初のジェネレータを作成する
-----------------------------

ジェネレータは[Thor][] gemの上に構築されています。Thorは強力な解析オプションと優れたファイル操作APIを提供しています。

具体例として、`config/initializers`ディレクトリの下に`initializer.rb`という名前のイニシャライザファイルを作成するジェネレータを構築してみましょう。

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", <<~RUBY
      # 初期化時のコンテンツをここに追加する
    RUBY
  end
end
```

新しいジェネレータはきわめてシンプルです。[`Rails::Generators::Base`][]を継承しており、定義されているメソッドは1つだけです。ジェネレータが起動されると、ジェネレータ内で定義されているパブリックメソッドが定義順に実行されます。作成したメソッドから[`create_file`][]が呼び出され、指定の内容を含むファイルが指定のディレクトリに作成されます。

新しいジェネレータを呼び出すには、以下を実行します。

```bash
$ bin/rails generate initializer
```

次に進む前に、今作成したばかりのジェネレータの説明を表示してみましょう。

```bash
$ bin/rails generate initializer --help
```

Railsでは、ジェネレータが`ActiveRecord::Generators::ModelGenerator`のように名前空間化されていれば実用的な説明文を生成できますが、今作成したジェネレータはそうなっていません。この問題は2通りの方法で解決できます。1つ目の方法は、ジェネレータ内で[`desc`][]メソッドを呼び出すことです。

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "このジェネレータはconfig/initializersにイニシャライザファイルを作成します"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", <<~RUBY
      # 初期化時のコンテンツをここに追加する
    RUBY
  end
end
```

これで、`--help`を付けて新しいジェネレータを呼び出すと新しい説明文が表示されるようになりました。

説明文を追加する2つ目の方法は、ジェネレータと同じディレクトリに`USAGE`という名前のファイルを作成することです。次に、この方法で実際に説明文を追加してみましょう。

[Thor]: https://github.com/erikhuda/thor
[`Rails::Generators::Base`]: https://api.rubyonrails.org/classes/Rails/Generators/Base.html
[`Thor::Actions`]: https://www.rubydoc.info/gems/thor/Thor/Actions
[`create_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#create_file-instance_method
[`desc`]: https://www.rubydoc.info/gems/thor/Thor#desc-class_method

ジェネレータでジェネレータを生成する
-----------------------------------

Railsには、ジェネレータを生成するためのジェネレータもあります。`InitializerGenerator`を削除してから、`bin/rails generate generator`を実行して新しいジェネレータを生成してみましょう。

```bash
$ rm lib/generators/initializer_generator.rb

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
  source_root File.expand_path("templates", __dir__)
end
```

上のジェネレータを見て最初に気付く点は、`Rails::Generators::Base`ではなく[`Rails::Generators::NamedBase`][]を継承していることです。これは、このジェネレータを生成するには引数が1つ以上必要であることを意味します。この引数はイニシャライザ名で、コードはこのイニシャライザ名を`name`という変数で参照できます。

新しいジェネレータを呼び出すと、以下のように説明文が表示されます。

```bash
$ bin/rails generate initializer --help
Usage:
  bin/rails generate initializer NAME [options]
```

次に、新しいジェネレータには[`source_root`][]という名前のクラスメソッドが含まれている点にもご注目ください。このメソッドは、ジェネレータのテンプレートの置き場所を指定する場合に使います。デフォルトでは、作成された`lib/generators/initializer/templates`ディレクトリを指します。

ジェネレータのテンプレートの機能を理解するために、`lib/generators/initializer/templates/initializer.rb`を作成して以下のコンテンツを追加してみましょう。

```ruby
# 初期化用のコンテンツをここに追加する
```

続いてジェネレータを変更し、呼び出されたときにこのテンプレートをコピーするようにします。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

それではこのジェネレータを実行してみましょう。

```bash
$ bin/rails generate initializer core_extensions
      create  config/initializers/core_extensions.rb

$ cat config/initializers/core_extensions.rb
# 初期化用のコンテンツをここに追加する
```

[`copy_file`][]が作成した`config/initializers/core_extensions.rb`ファイルにテンプレートのコンテンツが反映されていることがわかります（コピー先パスで使われる`file_name`メソッドは`Rails::Generators::NamedBase`から継承されます）。

[`Rails::Generators::NamedBase`]: https://api.rubyonrails.org/classes/Rails/Generators/NamedBase.html
[`copy_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#copy_file-instance_method
[`source_root`]: https://api.rubyonrails.org/classes/Rails/Generators/Base.html#method-c-source_root

ジェネレータのコマンドラインオプション
------------------------------

ジェネレータでは、以下のように[`class_option`][]でコマンドラインオプションをサポートできます。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  class_option :scope, type: :string, default: "app"
end
```

これで、`--scope`オプションを指定してジェネレータを呼び出せるようになります。

```bash
$ bin/rails generate initializer theme --scope dashboard
```

ジェネレータ内では、[`options`][]でオプションの値を参照できます。

```ruby
def copy_initializer_file
  @scope = options["scope"]
end
```

[`class_option`]: https://www.rubydoc.info/gems/thor/Thor/Base/ClassMethods#class_option-instance_method
[`options`]: https://www.rubydoc.info/gems/thor/Thor/Base#options-instance_method

ジェネレータ名の解決
-----------------

Railsがジェネレータ名を解決するときは、複数のファイル名を使ってジェネレータを探索します。たとえば、`bin/rails generate initializer core_extensions`を実行すると、Railsはジェネレータが見つかるまで以下の順にファイルを探索します。

* `rails/generators/initializer/initializer_generator.rb`
* `generators/initializer/initializer_generator.rb`
* `rails/generators/initializer_generator.rb`
* `generators/initializer_generator.rb`

ジェネレータがどのファイルにも見つからない場合は、エラーメッセージが表示されます。

上の例でアプリケーションの`lib/`ディレクトリの下にファイルを置いているのは、このディレクトリが`$LOAD_PATH`に含まれているからです。これにより、Railsがこのファイルを検索して読み込めるようになります。

Railsジェネレータのテンプレートをオーバーライドする
------------------------------------

Railsは、ジェネレータのテンプレートファイルを解決するときにも複数の場所を探索します。アプリケーションの`lib/templates/`ディレクトリも探索場所の1つです。この振る舞いのおかげで、Railsの組み込みジェネレータで使われるテンプレートをオーバーライドできます。たとえば、[コントローラのscaffoldテンプレート][scaffold controller template]や[ビューのscaffoldテンプレート][scaffold view templates]をオーバーライドできます。

これを実際に行うために、`lib/templates/erb/scaffold/index.html.erb.tt`ファイルを作成して以下のコンテンツを追加してみましょう。

```erb
<%% @<%= plural_table_name %>.count %> <%= human_name.pluralize %>
```

ここで作成するERBテンプレートは、**別の**ERBテンプレートをレンダリングします。そのため、**生成される**テンプレートに出力する`<%`は、**ジェネレータ**のテンプレートで`<%%`のようにすべてエスケープしておく必要がある点にご注意ください。

それでは、Rails組み込みのscaffoldジェネレータを実行してみましょう。

```bash
$ bin/rails generate scaffold Post title:string
      ...
      create      app/views/posts/index.html.erb
      ...
```

`app/views/posts/index.html.erb`ファイルを開くと、以下のようになっているはずです。

```erb
<% @posts.count %> Posts
```

[scaffold controller template]: https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/scaffold_controller/templates/controller.rb.tt
[scaffold view templates]: https://github.com/rails/rails/tree/main/railties/lib/rails/generators/erb/scaffold/templates

Railsジェネレータをオーバーライドする
---------------------------

Rails組み込みのジェネレータは、[`config.generators`][]で設定できます。一部のジェネレータについては完全にオーバーライドすることも可能です。

まず、scaffoldジェネレータの動作をじっくり見てみましょう。

```bash
$ bin/rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20230518000000_create_users.rb
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
      create      app/views/users/_user.html.erb
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      create      test/system/users_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke      test_unit
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
```

この出力結果を見ると、scaffoldジェネレータが別のジェネレータ（`scaffold_controller`など）を実行していることがわかります。また、一部のジェネレータはさらに別のジェネレータを実行しています。特に、`scaffold_controller`ジェネレータは`helper`ジェネレータなど多くのジェネレータを実行しています。

組み込みの`helper`ジェネレータを新しいジェネレータでオーバーライドしてみましょう。新しいジェネレータの名前は`my_helper`にします。

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
      invoke  test_unit
      create    test/lib/generators/rails/my_helper_generator_test.rb
```

次に、`lib/generators/rails/my_helper/my_helper_generator.rb`ファイルで以下のジェネレータを定義します。

```ruby
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<~RUBY
      module #{class_name}Helper
        # 私はヘルパー
      end
    RUBY
  end
end
```

最後に、組み込みの`helper`ジェネレータではなく`my_helper`ジェネレータを使うようRailsに指示する必要があります。これには`config.generators`設定を使います。`config/application.rb`ファイルに以下を追加しましょう。

```ruby
config.generators do |g|
  g.helper :my_helper
end
```

これで、scaffoldジェネレータをもう一度実行すると、`my_helper`ジェネレータが動作していることがわかります。

```bash
$ bin/rails generate scaffold Article body:text
      ...
      invoke  scaffold_controller
      ...
      invoke    my_helper
      create      app/helpers/articles_helper.rb
      ...
```

NOTE: 組み込みの`helper`ジェネレータには`invoke test_unit`という行がありますが、今作った`my_helper`ジェネレータにはありません。`helper`ジェネレータはデフォルトではテストを生成しませんが、[`hook_for`][]でテストを生成するためのフックを提供しています。`MyHelperGenerator`クラスに`hook_for :test_framework, as: :helper`を追加すれば、これと同じことを実現できます。詳しくは`hook_for`のドキュメントを参照してください。

[`config.generators`]: configuring.html#ジェネレータを設定する
[`hook_for`]: https://api.rubyonrails.org/classes/Rails/Generators/Base.html#method-c-hook_for

### ジェネレータのフォールバック

特定のジェネレータをオーバーライドする別の方法は、**フォールバック**を使う方法です。フォールバックを使うと、あるジェネレータの名前空間を別のジェネレータの名前空間に委譲できます。

たとえば、`my_test_unit:model`ジェネレータを作成して`test_unit:model`ジェネレータをオーバーライドしたいとします。しかし、`test_unit:controller`ジェネレータなどの他の`test_unit:*`ジェネレータはオーバーライドしたくないとします。

最初に、`my_test_unit:model`ジェネレータを`lib/generators/my_test_unit/model/model_generator.rb`ファイルに作成します。

```ruby
module MyTestUnit
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def do_different_stuff
      say "別の作業を実行中..."
    end
  end
end
```

次に、`config.generators`設定を変更して`test_framework`ジェネレータを`my_test_unit`に設定します。さらに、`my_test_unit:*`ジェネレータが見つからない場合は`test_unit:*`ジェネレータに解決するフォールバックも設定します。

```ruby
config.generators do |g|
  g.test_framework :my_test_unit, fixture: false
  g.fallbacks[:my_test_unit] = :test_unit
end
```

これで、scaffoldジェネレータを実行すると、`my_test_unit`ジェネレータが`test_unit`ジェネレータに置き換わり、モデルのテスト以外は影響を受けていないことがわかります。

```bash
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20230518000000_create_comments.rb
      create    app/models/comment.rb
      invoke    my_test_unit
    Doing different stuff...
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
      create      app/views/comments/_comment.html.erb
      invoke    resource_route
      invoke    my_test_unit
      create      test/controllers/comments_controller_test.rb
      create      test/system/comments_test.rb
      invoke    helper
      create      app/helpers/comments_helper.rb
      invoke      my_test_unit
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
```

アプリケーションテンプレート
---------------------

アプリケーションテンプレートは、ジェネレータと若干異なる点があります。ジェネレータは、既存のRailsアプリケーションにモデルやビューなどのファイルを追加しますが、テンプレートは新しいRailsアプリケーションのセットアップを自動化するのに使われます。アプリケーションテンプレートは、新しいRailsアプリケーションを生成した直後にカスタマイズするRubyスクリプトであり、通常は`template.rb`という名前です。

Railsアプリケーションを作成するときにアプリケーションテンプレートを使う方法を見てみましょう。

### テンプレートを作成して利用する

最初は、サンプルのRubyスクリプトテンプレートを作成してみましょう。
以下のテンプレートは、ユーザーに確認した後、`Gemfile`にDeviseを追加し、Deviseユーザーモデル名を入力できるようにします。`bundle install`の実行後、テンプレートはDeviseジェネレータとマイグレーションを実行します。最後に、`git add`と`git commit`を実行します。

```ruby
# template.rb
if yes?("Deviseをインストールしますか?")
  gem "devise"
  devise_model = ask("ユーザモデル名は何にしますか?", default: "User")
end

after_bundle do
  if devise_model
    generate "devise:install"
    generate "devise", devise_model
    rails_command "db:migrate"
  end

  git add: ".", commit: %(-m 'Initial commit')
end
```

このテンプレートを使って新しいRailsアプリケーションを作成するには、`-m`オプションでテンプレートの場所を指定します。

```bash
$ rails new blog -m ~/template.rb
```

これで、新規Railsアプリケーションが`blog`という名前で作成されるときに、Devise gemも設定されます。

`app:template`コマンドを使えば、既存のRailsアプリケーションにテンプレートを適用することも可能です。
この場合、テンプレートファイルの場所は`LOCATION`環境変数で指定する必要があります。

```bash
$ bin/rails app:template LOCATION=~/template.rb
```

テンプレートは必ずしもローカルに保存する必要はありません。ファイルパスの代わりにURLも指定できます。

```bash
$ rails new blog -m https://example.com/template.rb
$ bin/rails app:template LOCATION=https://example.com/template.rb
```

WARNING: 第三者が提供するリモートスクリプトを実行するときは注意が必要です。テンプレートは単なるRubyスクリプトなので、ローカルマシンを危険にさらすコード（ウイルスのダウンロード、ファイルの削除、個人ファイルのサーバーへのアップロードなど）が仕込まれやすくなる可能性があります。

上述の`template.rb`ファイルでは、`after_bundle`や`rails_command`などのヘルパーメソッドを使い、`yes?`のようなユーザーインタラクティビティも追加しています。これらのメソッドはすべて[Rails Template API](https://edgeapi.rubyonrails.org/classes/Rails/Generators/Actions.html)の一部です。これらのメソッドの利用例を次のセクションで示します。

RailsジェネレータAPI
--------------------

ジェネレータと、テンプレートのRubyスクリプトは、[DSL](https://en.wikipedia.org/wiki/Domain-specific_language)（ドメイン固有言語）を使っていくつかのヘルパーメソッドにアクセスできます。これらのメソッドはRailsジェネレータAPIの一部であり、詳しくは[`Thor::Actions`][]や[`Rails::Generators::Actions`][]のAPIドキュメントで確認できます。

もう一つの典型的なRailsテンプレートの例を見てみましょう。このテンプレートはモデルをscaffoldで生成してからマイグレーションを実行し、変更をgitでコミットします。

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rails_command("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

NOTE: 以下の例で使われているコードスニペットは、すべて上記の`template.rb`ファイルなどのテンプレートファイルで利用可能です。

### `add_source`

[`add_source`][]メソッドは、指定したソース（gemの取得元）を、生成されるアプリケーションの`Gemfile`に追加します。

```ruby
add_source "https://rubygems.org"
```

このメソッドにブロックを渡すと、ブロック内のgemエントリがソースグループにラップされます。たとえば、gemを`"http://gems.github.com"`から取得する必要がある場合は以下のようにします。

```ruby
add_source "http://gems.github.com/" do
  gem "rspec-rails"
end
```

### `after_bundle`

[`after_bundle`][]メソッドは、gemのバンドルが完了した後に実行されるコールバックを登録します。
たとえば、`tailwindcss-rails`と`devise`のインストールコマンドは、それらのgemがバンドルされた後に実行するのが合理的です。

```ruby
# gemをインストールする
after_bundle do
  # TailwindCSSをインストールする
  rails_command "tailwindcss:install"

  # Deviseをインストールする
  generate "devise:install"
end
```

このコールバックは、`rails new`コマンドで`--skip-bundle`オプションを指定した場合でも実行される点にご注意ください。

### `environment`

[`environment`][]メソッドは、`config/application.rb`の`Application`クラス内に行を追加します。`options[:env]`が指定されている場合、その行は`config/environments/`ディレクトリ内の対応するファイルに追加されます。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: "production"
```

上のコードは、`config/environments/production.rb`に設定行を追加します。

### `gem`

[`gem`][]メソッドは、指定のgemエントリを、生成されたアプリケーションの`Gemfile`に追加します。

たとえば、アプリケーションが`devise` gemと`tailwindcss-rails` gemに依存している場合は、以下のようにします。

```ruby
gem "devise"
gem "tailwindcss-rails"
```

このメソッドは、gemを`Gemfile`に追加するだけで、gemのインストールは行わない点にご注意ください。

gemのバージョンも指定できます。

```ruby
gem "devise", "~> 4.9.4"
```

`Gemfile`にコメント付きでgemを追加することも可能です。

```ruby
gem "devise", comment: "Add devise for authentication."
```

### `gem_group`

[`gem_group`][]メソッドは、gemエントリをグループにラップします。たとえば、`rspec-rails`を`development`グループと`test`グループでのみ読み込むには、以下のようにします。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `generate`

[`generate`][]メソッドを使うと、`template.rb`ファイル内でRailsジェネレータを呼び出せます。
たとえば、`scaffold`ジェネレータを呼び出して`Person`モデルを生成するには、以下のようにします。

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### `git`

[`git`][]ヘルパーメソッドを使うと、Railsテンプレート内で任意のgitコマンドを実行できます。

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

### `initializer`、`vendor`、`lib`、`file`

[`initializer`][]ヘルパーメソッドは、生成されたアプリケーションの`config/initializers/`ディレクトリにイニシャライザファイルを追加します。

`template.rb`ファイルに以下のコードを追加すると、アプリケーションで`Object#not_nil?`と`Object#not_blank?`を使えるようになります。

```ruby
initializer "not_methods.rb", <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

同様に、[`lib`][]メソッドは`lib/`ディレクトリにファイルを作成し、
[`vendor`][]メソッドは`vendor/`ディレクトリにファイルを作成します。

`file`メソッドは[`create_file`][]のエイリアスです。`Rails.root`からの相対パスを受け取って、必要なディレクトリとファイルをすべて作成します。

```ruby
file "app/components/foo.rb", <<-CODE
  class Foo
  end
CODE
```

上のコードは`app/components/`ディレクトリを作成し、その中に`foo.rb`を配置します。

### `rakefile`

[`rakefile`][]メソッドは、指定のタスクを含む新しいRakeファイルを`lib/tasks/`ディレクトリに作成します。

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "I like boots!"
      end
    end
  TASK
end
```

上のコードは、`lib/tasks/bootstrap.rake`ファイルを作成し、`boot:strap` rakeタスクを定義します。

### `run`

[`run`][]メソッドは、任意のコマンドを実行します。たとえば、`README.rdoc`ファイルを削除したい場合は、以下のようにします。

```ruby
run "rm README.rdoc"
```

### `rails_command`

[`rails_command`][]メソッドを使うと、生成されたアプリケーションでRailsコマンドを実行できます。

たとえば、テンプレートのRubyスクリプト内でデータベースをマイグレーションしたい場合は、以下のようにします。

```ruby
rails_command "db:migrate"
```

Railsの環境を指定してコマンドを実行することも可能です。

```ruby
rails_command "db:migrate", env: "production"
```

`abort_on_failure`オプションを指定することで、コマンド実行に失敗した場合はアプリケーションの生成を中止することも可能です。

```ruby
rails_command "db:migrate", abort_on_failure: true
```

### `route`

[`route`][]メソッドは、`config/routes.rb`ファイルにエントリを追加します。

アプリケーションのデフォルトページを`PeopleController#index`にするには、以下を追加します。

```ruby
route "root to: 'person#index'"
```

この他にも、[`copy_file`][]、[`create_file`][]、[`insert_into_file`][]、[`inside`][]などのローカルファイルシステムを操作するヘルパーメソッドが多数用意されています。詳しくは[ThorのAPIドキュメント](https://www.rubydoc.info/gems/thor/Thor/Actions)を参照してください。以下にそのようなメソッドの例を示します。

### `inside`

[`inside`][]メソッドは、指定したディレクトリからコマンドを実行できるようにします.
たとえば、新しいアプリケーションからedge railsのコピーへのシンボリックリンクを作成したい場合は、以下のようにします。

```ruby
inside("vendor") do
  run "ln -s ~/my-forks/rails rails"
end
```

この他に、[`ask`][]、[`yes?`][], [`no?`][]など、Rubyテンプレートからユーザーと対話できるメソッドもあります。すべてのユーザー対話メソッドについては、[Thorのシェルドキュメント](https://www.rubydoc.info/gems/thor/Thor/Shell/Basic)で確認できます。以下に`ask`、`yes?`、`no?`の例を示します。

### `ask`

[`ask`][]メソッドを使うと、ユーザーからの指示を受け付けてテンプレートで利用できます。

たとえば、新しいライブラリの名前をユーザーに尋ねたい場合は、以下のようにします。

```ruby
lib_name = ask("What do you want to call the shiny library?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### `yes?`と`no?`

[`yes?`][]メソッドや[`no?`][]メソッドを使って、yes/noで答えられる質問を手軽にユーザーに表示して、その答えに基づいて処理の流れを決められます。

たとえば、ユーザーにマイグレーションを実行するかどうか尋ねたい場合は、以下のようにします。

```ruby
rails_command("db:migrate") if yes?("Run database migrations?")
# no? questions acts the opposite of yes?
```

ジェネレータをテストする
------------------

Railsは、[`Rails::Generators::Testing::Behaviour`][]で以下のようなテストヘルパーメソッドを提供しています。

* [`run_generator`][]

ジェネレータに対してテストを実行する場合、デバッグツールが機能するために以下のようにコマンドで`RAILS_LOG_TO_STDOUT=true`を指定する必要があります。

```sh
RAILS_LOG_TO_STDOUT=true ./bin/test test/generators/actions_test.rb
```

Railsではその他にも、[`Rails::Generators::Testing::Assertions`][]で追加のアサーションを提供しています。

[`Rails::Generators::Actions`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html
[`environment`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-environment
[`gem`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-gem
[`generate`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-generate
[`git`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-git
[`gsub_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#gsub_file-instance_method
[`initializer`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-initializer
[`insert_into_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#insert_into_file-instance_method
[`inside`]: https://www.rubydoc.info/gems/thor/Thor/Actions#inside-instance_method
[`lib`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-lib
[`rails_command`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rails_command
[`rake`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rake
[`route`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-route
[`Rails::Generators::Testing::Behaviour`]: https://api.rubyonrails.org/classes/Rails/Generators/Testing/Behavior.html
[`run_generator`]: https://api.rubyonrails.org/classes/Rails/Generators/Testing/Behavior.html#method-i-run_generator
[`Rails::Generators::Testing::Assertions`]: https://api.rubyonrails.org/classes/Rails/Generators/Testing/Assertions.htm
[`add_source`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-add_source
[`after_bundle`]: https://api.rubyonrails.org/classes/Rails/Generators/AppGenerator.html#method-i-after_bundle
[`gem_group`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-gem_group
[`vendor`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-vendor
[`rakefile`]: https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rakefile
[`run`]: https://www.rubydoc.info/gems/thor/Thor/Actions#run-instance_method
[`copy_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#copy_file-instance_method
[`create_file`]: https://www.rubydoc.info/gems/thor/Thor/Actions#create_file-instance_method
[`ask`]: https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#ask-instance_method
[`yes`]: https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#yes%3F-instance_method
[`no`]: https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#no%3F-instance_method
