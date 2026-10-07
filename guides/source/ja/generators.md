Rails ジェネレータとテンプレート入門
============================

Railsの各種ジェネレータとアプリケーションテンプレートは、定型コードを自動的に生成してワークフローを改善するツールとして非常に有用です。

このガイドの内容:

* アプリケーションで利用可能なジェネレータを確認する方法
* テンプレートを利用してカスタムジェネレータを作成する方法
* Railsがジェネレータを呼び出すときにジェネレータを探索するしくみ
* ジェネレータやテンプレートをオーバーライドしてRailsのscaffoldをカスタマイズする方法
* 特定のジェネレータをオーバーライドするフォールバックの設定方法
* テンプレートでRailsアプリケーションを作成・カスタマイズする方法
* RailsテンプレートAPIを利用して再利用可能なアプリケーションテンプレートを作成する方法

--------------------------------------------------------------------------------

ジェネレータとは
--------------------

`rails new`コマンドでアプリケーションを作成すると、Railsのジェネレータが使われます。**ジェネレータ**（generator）は、アプリケーションの特定のファイルを作成し、定型コードの自動化を可能にします。

Railsアプリケーション内で以下のように`bin/rails generate`コマンドを呼び出すと、利用可能なすべてのジェネレータのリストを取得できます。

```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
Usage:
  bin/rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  -p, [--pretend]  # Run but do not make any changes
  -f, [--force]    # Overwrite files that already exist
  -s, [--skip]     # Skip files that already exist
  -q, [--quiet]    # Suppress status output

Please choose a generator below.

Rails:
  application_record
  authentication
  benchmark
  channel
  controller
  generator
  ...
SolidQueue:
  solid_queue:install

Stimulus:
  stimulus

TestUnit:
  test_unit:authentication
  test_unit:channel
  ...
```

NOTE: Railsアプリケーションを新しく作成するときは、`gem install rails`でインストールしたバージョンのRailsを使うグローバルな`rails`コマンドが使われますが、作成したアプリケーションのディレクトリ内では、アプリケーションにバンドルされているバージョンのRailsを使う`bin/rails`コマンドが使われる点が異なります。

上のコマンドによって、Railsで利用可能なすべてのジェネレータのリストと利用方法を表示できます。

ジェネレータを実行するときに、以下のように`--pretend`（または`-p`）オプションを付けて実行すると、ジェネレータがどのような処理を行うかを、ファイルを変更せずに確認できます。

```bash
$ bin/rails generate model product name:string --pretend
      invoke  active_record
      create    db/migrate/20260407190300_create_products.rb
      create    app/models/product.rb
      invoke    test_unit
      create      test/models/product_test.rb
      create      test/fixtures/products.yml
```

上記のファイルは、`--pretend`オプションを付けて実行した場合、実際には作成されません。

TIP: `--pretend`オプションは、関連するジェネレータが生成するファイルの差分を、実際に実行する前に確認するのに便利です。たとえば、`model`と`resource`ジェネレータの違いを確認できます。

特定のジェネレータの詳しい説明を表示するには、以下のように`--help`オプションを付けてジェネレータを呼び出します。

```bash
$ bin/rails generate scaffold --help
Usage:
  bin/rails generate scaffold NAME [field[:type][:index] field[:type][:index]] [options]
...
Description:
    Scaffolds an entire resource, from model and migration to controller and
    views, along with a full test suite. The resource is ready to use as a
    starting point for your RESTful, resource-oriented application.
...
Examples:
    `bin/rails generate scaffold post`
    `bin/rails generate scaffold post title:string body:text published:boolean`
    `bin/rails generate scaffold purchase amount:decimal tracking_id:integer:uniq`
    `bin/rails generate scaffold user email:uniq password:digest`
...
```

`--help`オプションを付けると詳しい利用方法や実行例が出力されるので、特定のジェネレータについて詳しく知るための良い情報源となります。

最初のジェネレータを作成する
-----------------------------

Railsでは、ジェネレータに加えて、カスタムジェネレータを構築する機能も提供されています。ここでは、`config/initializers/`フォルダ内に`hello_generator.rb`という名前のイニシャライザファイルを作成するジェネレータを作成してみましょう。最初は手動でジェネレータを作成し、次に`generator`コマンドでジェネレータを作成する方法も見ていきます。

NOTE: ジェネレータは[Thor][]をベースとして構築されています。Thorは解析機能などの便利なオプションやファイル操作用のAPIを提供するライブラリです。

ジェネレータを手書きするときの最初のステップとして、`lib/generators/`ディレクトリの下に`initializer_generator.rb`という名前のファイルを以下の内容で作成します。

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/hello_generator.rb", <<~RUBY
      # hello_generator.rbファイルの内容をここに追加する
    RUBY
  end
end
```

このジェネレータの名前は、ファイル名とRubyクラス名に基づいて`initializer`とし、[`Rails::Generators::Base`][]クラスを継承しています。ジェネレータが呼び出されると、ジェネレータ内の各パブリックメソッドが定義された順序で順番に実行されます。

この新しいジェネレータは意図的にシンプルなものにしてあり、メソッド定義は1個しかありません。このメソッドは[`create_file`][]を呼び出し、指定された場所に指定の内容でファイルを作成します。

新しいジェネレータを呼び出すには、以下を実行します。

```bash
$ bin/rails generate initializer
```

これで、`config/initializers`フォルダ内に`hello_generator.rb`という空のファイルが作成されます。

次に進む前に、今作成したばかりのジェネレータの説明を表示してみましょう。

```bash
$ bin/rails generate initializer --help
```

通常は、ジェネレータが`ActiveRecord::Generators::ModelGenerator`のように名前空間化されていれば、実用的な説明文を生成できますが、今作成したジェネレータはそうなっていません。

この問題は2通りの方法で解決できます。1つ目の方法は、ジェネレータ内で[`desc`][]メソッドを呼び出すことです。

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "このジェネレータはconfig/initializersにイニシャライザファイルを作成します"
  def create_initializer_file
    create_file "config/initializers/hello_generator.rb", <<~RUBY
      # hello_generator.rbファイルの内容をここに追加する
    RUBY
  end
end
```

これで、`--help`を付けて新しいジェネレータを呼び出すと新しい説明文が表示されるようになりました。

説明文を追加する2つ目の方法は、ジェネレータと同じディレクトリに`USAGE`という名前のファイルを作成することです。次に、この方法で実際に説明文を追加してみましょう。

[Thor]:
  https://github.com/rails/thor
[`Rails::Generators::Base`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Base.html
[`Thor::Actions`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions
[`create_file`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#create_file-instance_method
[`desc`]:
  https://www.rubydoc.info/gems/thor/Thor#desc-class_method

### ジェネレータでジェネレータを生成する

Railsには、ジェネレータを生成するためのジェネレータもあります。

今作った`InitializerGenerator`を削除してから、`bin/rails generate generator`を実行し、あらためてジェネレータを生成してみましょう。

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

これで、以下のようなジェネレータが作成されます。

```ruby
# lib/generators/initializer/initializer_generator.rb
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)
end
```

上のジェネレータを見て最初に気付く点は、`Rails::Generators::Base`ではなく[`Rails::Generators::NamedBase`][]を継承していることです。これは、このジェネレータを実行するには引数が1つ以上必要であることを意味します。この引数はイニシャライザ名で、コードはこのイニシャライザ名を`name`で参照できます。

このことは、新しいジェネレータの説明文を表示してみると確認できます。

```bash
$ bin/rails generate initializer --help
Usage:
  bin/rails generate initializer NAME [options]
```

次に、生成されたジェネレータに[`source_root`][]という名前のクラスメソッドが含まれている点にもご注目ください。このメソッドは、ジェネレータのテンプレートの置き場所を指定するのに使われます。テンプレートファイルとは、ジェネレータがアプリケーション内に新しいファイルを作成するときの設計図として使うファイルのことです。テンプレートファイルは、デフォルトでは、作成された`lib/generators/initializer/templates`ディレクトリに置かれます。

ジェネレータのテンプレートの機能を理解するために、`lib/generators/initializer/templates/initializer.rb`ファイルを以下の内容で作成しましょう。

```ruby
# 初期化用のコンテンツをここに追加する
```

次に、ジェネレータを以下のように変更して、ジェネレータが呼び出されたときにこのテンプレートをコピーするようにします。

```ruby
# lib/generators/initializer/initializer_generator.rb
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

それでは、このジェネレータを実行してみましょう。

```bash
$ bin/rails generate initializer core_extensions
      create  config/initializers/core_extensions.rb

$ cat config/initializers/core_extensions.rb
# 初期化用のコンテンツをここに追加する
```

[`copy_file`][]によって`config/initializers/core_extensions.rb`が作成され、テンプレートの内容がコピーされたことがわかります（宛先パスで使われている`file_name`メソッドは[`Rails::Generators::NamedBase`][]から継承されています）。

[`Rails::Generators::NamedBase`]:
    https://api.rubyonrails.org/classes/Rails/Generators/NamedBase.html
[`copy_file`]:
    https://www.rubydoc.info/gems/thor/Thor/Actions#copy_file-instance_method
[`source_root`]:
    https://api.rubyonrails.org/classes/Rails/Generators/Base.html#method-c-source_root

### ジェネレータのコマンドラインオプション

ジェネレータでコマンドラインオプションをサポートするには、以下のように[`class_option`][]メソッドを使います。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  class_option :scope, type: :string, default: "app"
end
```

これで、`--scope`オプションを指定してジェネレータを呼び出せるようになります。

```bash
$ bin/rails generate initializer theme --scope dashboard
```

これにより、デフォルト値の"app"が"dashboard"で上書きされます。

オプションの値は、ジェネレータ内のメソッドから[`options`][]でアクセスできます。

```ruby
def copy_initializer_file
  @scope = options["scope"]
  copy_file "initializer.rb", "config/initializers/#{@scope}/#{file_name}.rb"
end
```

これで、ジェネレータで`--scope`オプションを設定すると、`theme.rb`ファイルが`config/initializers/dashboard/`に生成されるようになりました。

[`class_option`]:
    https://www.rubydoc.info/gems/thor/Thor/Base/ClassMethods#class_option-instance_method
[`options`]:
    https://www.rubydoc.info/gems/thor/Thor/Base#options-instance_method

ジェネレータ名の解決
--------------------

Railsがジェネレータ名を解決するときは、複数のファイル名を使ってジェネレータを探索します。
たとえば、`bin/rails generate initializer core_extensions`を実行すると、Railsはジェネレータが見つかるまで以下の順にファイルを探索します。

* `rails/generators/initializer/initializer_generator.rb`
* `generators/initializer/initializer_generator.rb`
* `rails/generators/initializer_generator.rb`
* `generators/initializer_generator.rb`

ジェネレータがどのファイルにも見つからない場合は、エラーがraiseされます。

上の例でジェネレータのファイルをアプリケーションの`lib/`ディレクトリの下に置いた理由は、このディレクトリが`$LOAD_PATH`（Rubyがファイルを読み込むときに探索するディレクトリのリスト）に含まれているからです。これにより、Railsがこのファイルを検索して読み込めるようになります。

NOTE: `$LOAD_PATH`はRubyによって初期化され、起動時にBundlerとRailsによって拡張されます。Bundlerは各gemに含まれている`lib/`ディレクトリを追加し、Railsはアプリケーションの`lib/`ディレクトリを追加します。これにより、そこに配置されたジェネレータが見つかるようになります。`bin/rails runner 'puts $LOAD_PATH'`を実行すると、完全な読み込みパスを確認できます。読み込みパスは、`application.rb`ファイルの`config.autoload_paths`で変更することも可能です。

Railsジェネレータとテンプレートをオーバーライドする
-----------------------------------------

[`config.generators`][]を設定することで、Rails組み込みのジェネレータをオーバーライドできます。Railsアプリケーションの成長に応じて、生成されるコントローラに独自のメソッドを追加したり、生成されるビューのフォーマットを変更したりしたくなることもあるでしょう。

組み込みジェネレータをオーバーライドする方法の例として、scaffoldジェネレータの動作を詳しく見てみましょう。

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

この出力結果を見ると、scaffoldジェネレータが別のジェネレータ（`scaffold_controller`など）を実行していることがわかります。また、一部のジェネレータはさらに別のジェネレータを実行しています。特に、`scaffold_controller`ジェネレータは`helper`ジェネレータを実行しています。

組み込みの`helper`ジェネレータを新しいジェネレータでオーバーライドしてみましょう。新しいジェネレータの名前は`my_helper`にします。

`generator`コマンドを使って、ジェネレータを`lib/generators/rails`ディレクトリの下に作成します。

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
      invoke  test_unit
      create    test/lib/generators/rails/my_helper_generator_test.rb
```

次に、`lib/generators/rails/my_helper/my_helper_generator.rb`ファイルを開いて以下のジェネレータを定義します。

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
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

NOTE: 組み込みの`helper`ジェネレータの出力には`invoke test_unit`という行がありますが、今作った`my_helper`ジェネレータにはありません。`helper`ジェネレータはデフォルトではテストを生成しませんが、[`hook_for`][]でテストを生成するためのフックを提供しています。`MyHelperGenerator`クラスに`hook_for :test_framework, as: :helper`を追加すれば、これと同じことを実現できます。詳しくは[`hook_for`][]のドキュメントを参照してください。

[`config.generators`]:
  configuring.html#configuring-generators
[`hook_for`]:
    https://api.rubyonrails.org/classes/Rails/Generators/Base.html#method-c-hook_for

### ジェネレータをフォールバックでオーバーライドする

特定のジェネレータをオーバーライドする別の方法は、**フォールバック**を使う方法です。フォールバックを使うと、マッチするジェネレータが見つからない場合に、ジェネレータの名前空間を別のジェネレータの名前空間に委譲できます。

たとえば、`my_test_unit:model`ジェネレータを作成して`test_unit:model`ジェネレータをオーバーライドしたいとします。しかし、`test_unit:controller`ジェネレータなどの他の`test_unit:*`ジェネレータはオーバーライドしたくないとします。

このような場合、すべてのジェネレータを`my_test_unit`名前空間に実装する代わりに、明示的に定義していないジェネレータについては`test_unit`にフォールバックするように`my_test_unit`を設定できます。

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

NOTE: `my_test_unit`は、Rails組み込みのジェネレータをオーバーライドするのではなく、カスタム名前空間であるため、ここでは`lib/generators/rails/`ディレクトリではなく`lib/generators/my_test_unit/`ディレクトリに配置しています。Railsは通常の読み込みパスの探索でこのジェネレータを見つけます。次のステップで、`config.generators`を使って`test_framework`として登録する必要があります。

次に、`config.generators`設定を以下のように変更して、`test_framework`ジェネレータを`my_test_unit`に設定します。さらに、`my_test_unit:*`ジェネレータが見つからない場合は`test_unit:*`ジェネレータに解決するフォールバックも設定します。

```ruby
config.generators do |g|
  g.test_framework :my_test_unit, fixture: false
  g.fallbacks[:my_test_unit] = :test_unit
end
```

これで、scaffoldジェネレータを実行すると、`test_unit`が`my_test_unit`に置き換えられているものの、影響を受けたのはモデルのテストだけであることがわかります。

```bash
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20230518000000_create_comments.rb
      create    app/models/comment.rb
      invoke    my_test_unit
    別の作業を実行中...
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

NOTE: モデルでの`my_test_unit`ジェネレータの呼び出しは、"別の作業を実行中..."と表示されるだけで、テストファイルは作成されません。これは、カスタムジェネレータがテストを作成していないためです。コントローラとヘルパーでの`my_test_unit`の呼び出しは`test_unit`にフォールバックするため、`test/controllers/comments_controller_test.rb`は通常通り生成されます。

### ジェネレータのテンプレートをオーバーライドする

Railsは、ジェネレータのテンプレートファイルを解決するときに、最初にアプリケーションの`lib/templates/`ディレクトリを探索し、それからジェネレータ自身の`source_root`ディレクトリを探索します。つまり、`lib/templates/`ディレクトリに自分のバージョンのテンプレートを置くことで、Rails組み込みのジェネレータで使われるテンプレートをオーバーライドできるということです。

たとえば、[コントローラのscaffoldテンプレート][scaffold_controller_template]や[ビューのscaffoldテンプレート][scaffold_view_templates]をオーバーライドできます。

これを実際に見るために、`lib/templates/erb/scaffold/index.html.erb.tt`ファイルを作成して以下のコンテンツを追加してみましょう。なお、`.tt`という拡張子が追加されているのは、このファイルがThorによって最初に処理される必要があるジェネレータテンプレートであることをRailsに伝えるためです（`.tt`は"thor template"の略です）。

```erb
<%%= @<%= plural_table_name %>.count %> <%= human_name.pluralize %>
```

ここで作成するERBテンプレートは、そこからさらに**別の**ERBテンプレートをレンダリングします。そのため、**生成される**テンプレートに出力する`<%`は、**ジェネレータ**のテンプレートで`<%%`のようにすべてエスケープしておく必要がある点にご注意ください。

それでは、Rails組み込みのscaffoldジェネレータを実行してみましょう。

```bash
$ bin/rails generate scaffold Post title:string
      ...
      create      app/views/posts/index.html.erb
      ...
```

`app/views/posts/index.html.erb`ファイルを開くと、以下のようになっているはずです。

```erb
<%= @posts.count %> Posts
```

[scaffold_controller_template]:
  https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/scaffold_controller/templates/controller.rb.tt
[scaffold_view_templates]:
  https://github.com/rails/rails/tree/main/railties/lib/rails/generators/erb/scaffold/templates

アプリケーションテンプレート
---------------------

アプリケーションテンプレートは、ジェネレータと若干異なる点があります。

ジェネレータは、既存のRailsアプリケーションにモデルやビューなどのファイルを追加しますが、アプリケーションテンプレートは、`rails new`コマンドで生成する新規Railsアプリケーションをその場で自動セットアップするのに使われます。アプリケーションテンプレートは、新しいRailsアプリケーションを生成した直後にカスタマイズを実行するRubyスクリプトであり、通常は`template.rb`という名前です。

Railsアプリケーションをアプリケーションテンプレートで作成する方法を見てみましょう。

### テンプレートを作成して利用する

最初は、サンプルのRubyスクリプトテンプレートを作成してみましょう。
以下のテンプレートは、ユーザーに確認した後、`Gemfile`にDeviseを追加し、Deviseユーザーモデル名を入力できるようにします。`bundle install`の実行後、テンプレートはDeviseジェネレータとマイグレーションを実行します。最後に、`git add`と`git commit`を実行します。

```ruby
# template.rb
if yes?("Deviseをインストールしますか?")
  gem "devise"
  devise_model = ask("ユーザーモデル名は何にしますか?", default: "User")
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

`rails new`コマンドでこのテンプレートを使って新しいRailsアプリケーションを作成するには、以下のように`-m`オプションでテンプレートの場所を指定します。

```bash
$ rails new blog -m ~/template.rb
```

これで、新規Railsアプリケーションを`blog`という名前で作成するときに、Devise gemも設定されるようになります。

`app:template`コマンドを使えば、既存のRailsアプリケーションにテンプレートを適用することも可能です。
この場合、テンプレートファイルの場所を`LOCATION`環境変数で指定する必要があります。

```bash
$ bin/rails app:template LOCATION=~/template.rb
```

テンプレートは必ずしもローカルに保存する必要はありません。ファイルパスの代わりに外部URLも指定できます。

```bash
$ rails new blog -m https://example.com/template.rb
$ bin/rails app:template LOCATION=https://example.com/template.rb
```

WARNING: 第三者が提供するリモートスクリプトを実行するときは注意が必要です。テンプレートは単なるRubyスクリプトなので、ローカルコンピュータを危険にさらすコード（ウイルスのダウンロード、ファイルの削除、個人ファイルのサーバーへのアップロードなど）を簡単に仕込めてしまいます。

上述の`template.rb`ファイルでは、`after_bundle`や`rails_command`などのヘルパーメソッドを使い、`yes?`のようなユーザーインタラクティビティも追加しています。これらのメソッドはすべて[RailsテンプレートAPI][Rails Template API]の一部です。これらのメソッドの利用例を以後のセクションで示します。

[Rails Template API]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html

RailsジェネレータAPI
--------------------

ジェネレータやテンプレートのRubyスクリプトは、[DSL][]（ドメイン固有言語）を使ってさまざまなヘルパーメソッドにアクセスできます。これらのメソッドはRailsジェネレータAPIの一部であり、詳しくは[`Thor::Actions`][]や[`Rails::Generators::Actions`][]のAPIドキュメントで確認できます。

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

[DSL]:
  https://en.wikipedia.org/wiki/Domain-specific_language

### `add_source`

[`add_source`][]メソッドは、指定したソース（gemの取得元）を、生成されるアプリケーションの`Gemfile`に追加します。

```ruby
add_source "https://rubygems.org"
```

このメソッドにブロックを渡すと、ブロック内のgemエントリがソースグループにラップされます。
たとえば、gemを`"http://gems.github.com"`から取得する必要がある場合は以下のようにします。

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

[`gem`][]メソッドは、指定のgemエントリを、生成されるアプリケーションの`Gemfile`に追加します。

たとえば、アプリケーションを`devise` gemと`tailwindcss-rails` gemに依存させる場合は、以下のようにします。

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

[`gem_group`][]メソッドは、gemエントリをグループにラップします。
たとえば、`rspec-rails`を`development`グループと`test`グループでのみ読み込むには、以下のようにします。

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

[`initializer`][]ヘルパーメソッドは、生成されるアプリケーションの`config/initializers/`ディレクトリにイニシャライザファイルを追加します。

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

同様に、[`lib`][]メソッドはファイルを`lib/`ディレクトリに作成し、[`vendor`][]メソッドはファイルを`vendor/`ディレクトリに作成します。

`file`メソッドは[`create_file`][]のエイリアスです。これは`Rails.root`からの相対パスを受け取って、必要なディレクトリとファイルをすべて作成します。

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

[`run`][]メソッドは、任意のコマンドを実行します。
たとえば、`README.rdoc`ファイルを削除したい場合は、以下のようにします。

```ruby
run "rm README.rdoc"
```

### `rails_command`

[`rails_command`][]メソッドを使うと、生成されるアプリケーションでRailsコマンドを実行できます。
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

<!-- 原文エラー修正 https://github.com/rails/rails/pull/58973 を先行反映 -->

```ruby
route "root to: 'people#index'"
```

この他にも、[`copy_file`][]、[`create_file`][]、[`insert_into_file`][]、[`inside`][]などのローカルファイルシステムを操作するヘルパーメソッドが多数用意されています。詳しくは[ThorのAPIドキュメント][thor_api]を参照してください。

以下にそのようなメソッドの例を示します。

[thor_api]:
  https://www.rubydoc.info/gems/thor/Thor/Actions

### `inside`

[`inside`][]メソッドは、コマンドを指定のディレクトリ内から実行できるようにします。
たとえば、新しいアプリケーションからedge railsのコピーへのシンボリックリンクを作成したい場合は、以下のようにします。

```ruby
inside("vendor") do
  run "ln -s ~/my-forks/rails rails"
end
```

この他に、[`ask`][]、[`yes?`][`yes`]、[`no?`][`no`]など、Rubyテンプレートからユーザーと対話できるメソッドも利用できます。すべてのユーザー対話メソッドについては、[Thorのシェルドキュメント][thor_shell]で確認できます。
以下に`ask`、`yes?`、`no?`の例を示します。

[thor_shell]:
  https://www.rubydoc.info/gems/thor/Thor/Shell/Basic

### `ask`

[`ask`][]メソッドを使うと、ユーザーからの入力を受け取ってテンプレートで利用できます。
たとえば、新しいライブラリの名前をユーザーに尋ねたい場合は、以下のようにします。

```ruby
lib_name = ask("新しいライブラリの名前を入力してください:")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### `yes?`と`no?`

[`yes?`][`yes`]メソッドや[`no?`][`no`]メソッドを使って、yes/noで答えられる質問を手軽にユーザーに表示して、ユーザーの回答に応じて処理の流れを決められます。
たとえば、ユーザーにマイグレーションを実行するかどうか尋ねたい場合は、以下のようにします。

```ruby
rails_command("db:migrate") if yes?("マイグレーションを実行しますか?")
# no?メソッドはyes?メソッドの逆の動作
```

ジェネレータをテストする
------------------

Railsは、[`Rails::Generators::Testing::Behavior`][]で以下のようなテストヘルパーメソッドを提供しています。

* [`run_generator`][]

ジェネレータをテストする場合、デバッグツールが機能するために以下のようにコマンドで`RAILS_LOG_TO_STDOUT=true`を指定する必要があります。

```sh
RAILS_LOG_TO_STDOUT=true ./bin/test test/generators/actions_test.rb
```

Railsではその他にも、[`Rails::Generators::Testing::Assertions`][]で追加のアサーションを提供しています。

[`Rails::Generators::Actions`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html
[`environment`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-environment
[`gem`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-gem
[`generate`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-generate
[`git`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-git
[`gsub_file`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#gsub_file-instance_method
[`initializer`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-initializer
[`insert_into_file`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#insert_into_file-instance_method
[`inside`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#inside-instance_method
[`lib`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-lib
[`rails_command`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rails_command
[`rake`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rake
[`route`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-route
[`Rails::Generators::Testing::Behavior`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Testing/Behavior.html
[`run_generator`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Testing/Behavior.html#method-i-run_generator
[`Rails::Generators::Testing::Assertions`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Testing/Assertions.html
[`add_source`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-add_source
[`after_bundle`]:
  https://api.rubyonrails.org/classes/Rails/Generators/AppGenerator.html#method-i-after_bundle
[`gem_group`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-gem_group
[`vendor`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-vendor
[`rakefile`]:
  https://api.rubyonrails.org/classes/Rails/Generators/Actions.html#method-i-rakefile
[`run`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#run-instance_method
[`copy_file`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#copy_file-instance_method
[`create_file`]:
  https://www.rubydoc.info/gems/thor/Thor/Actions#create_file-instance_method
[`ask`]:
  https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#ask-instance_method
[`yes`]:
  https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#yes%3F-instance_method
[`no`]:
  https://www.rubydoc.info/gems/thor/Thor/Shell/Basic#no%3F-instance_method
