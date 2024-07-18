Rails アプリケーションのテンプレート
===========================

RailsのテンプレートはシンプルなRubyファイルであり、新規または既存のRailsプロジェクトにgemやイニシャライザを追加するためのDSL（ドメイン固有言語）を含んでいます。

このガイドの内容:

* テンプレートを使ってRailsアプリケーションの生成/カスタマイズを行う方法
* RailsテンプレートAPIを使って再利用可能なテンプレートを開発する方法

--------------------------------------------------------------------------------


利用法
-----

テンプレートを適用するには、`-m`オプションを使ってテンプレートの場所を指定する必要があります。ファイルパスまたはURLのどちらでも指定可能です。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

railsコマンド`app:template`を使って、既存のRailsアプリケーションにテンプレートを適用することもできます。テンプレートの場所は`LOCATION`環境変数で渡す必要があります。ここでも、ファイルパスまたはURLのどちらでも指定可能です。

```bash
$ bin/rails app:template LOCATION=~/template.rb
$ bin/rails app:template LOCATION=http://example.com/template.rb
```

テンプレートAPI
------------

RailsのテンプレートAPIはわかりやすく設計されています。以下はRailsアプリケーションの典型的なテンプレートです。

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

以下のセクションで、APIで提供される主なメソッドの概要を解説します。

### `gem(*args)`

生成された`Gemfile`ファイルに、指定された`gem`のエントリを追加します。

たとえば、Railsアプリケーションが`bj`と`nokogiri` gemに依存しているとします。

```ruby
gem "bj"
gem "nokogiri"
```

このメソッドは`Gemfile`にgemを追加するだけです。gemのインストールは行いません。

以下のようにバージョンを正確に指定することも可能です。

```ruby
gem "nokogiri", "~> 1.16.4"
```

以下のように`Gemfile`に追加するコメントも指定できます。

```ruby
gem "nokogiri", "~> 1.16.4", comment: "Add the nokogiri gem for XML parsing"
```

### `gem_group(*names, &block)`

gemのエントリを指定のグループに含めます。

たとえば、`rspec-rails` gemを`development`グループと`test`グループだけで読み込みたい場合は以下のようにします。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source(source, options={}, &block)`

生成された`Gemfile`ファイルに、gemの取得元を追加します。

たとえば、gemを`"http://gems.github.com"`から取得したい場合は以下のようにします。

```ruby
add_source "http://gems.github.com"
```

ブロックを1つ渡すと、取得元のグループにブロック内のgemエントリがラップされます。

```ruby
add_source "http://gems.github.com/" do
  gem "rspec-rails"
end
```

### `environment/application(data=nil, options={}, &block)`

`config/application.rb`ファイルの`Application`クラスの内側に指定の行を追加します。

`options[:env]`を指定すると、`config/environments`ディレクトリに置かれている同等のファイルに追加します。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

`data`引数の代わりにブロックを１つ渡すこともできます。

### `vendor/lib/file/initializer(filename, data = nil, &block)`

生成されたRailsアプリケーションの`config/initializers`ディレクトリにイニシャライザを追加します。

たとえば、`Object#not_nil?`と`Object#not_blank?`というメソッドを使いたい場合は以下のようにします。

```ruby
initializer 'bloatlol.rb', <<-CODE
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

同様に、`lib()`メソッドは`lib/`ディレクトリにファイルを作成し、`vendor()`メソッドは`vendor/`ディレクトリにファイルを作成します。

`file()`メソッドを使えば、`Rails.root`からの相対パスを渡してディレクトリやファイルを自由に作成することもできます。

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

上のコードは`app/components`ディレクトリを作成し、その中に`foo.rb`ファイルを置きます。

### `rakefile(filename, data = nil, &block)`

指定されたタスクを含むrakeファイルを`lib/tasks`ディレクトリの下に作成します。

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "i like boots!"
      end
    end
  TASK
end
```

上のコードは`lib/tasks/bootstrap.rake`ファイルを作成し、その中に`boot:strap` rakeタスクを置きます。

### `generate(what, *args)`

指定の引数を渡してRailsジェネレータを実行します。

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### `run(command)`

任意のコマンドを実行します（Rubyのバッククォート記法と同等です）。たとえば`README.rdoc`ファイルを削除する場合は以下のようにします。

```ruby
run "rm README.rdoc"
```

### `rails_command(command, options = {})`

指定のrailsコマンドをRailsアプリケーションで実行します。たとえばデータベースのマイグレーションを行いたい場合は次のようにします。

```ruby
rails_command "db:migrate"
```

Railsの環境を指定してrailsコマンドを実行することもできます。

```ruby
rails_command "db:migrate", env: 'production'
```

スーパーユーザーとしてコマンドを実行することもできます。

```ruby
rails_command "log:clear", sudo: true
```

### `route(routing_code)`

ルーティングエントリを`config/routes.rb`ファイルに追加します。上の手順では、scaffoldでpersonを生成し、続けて`README.rdoc`を削除しました。今度は以下のようにして`PeopleController#index`をアプリケーションのデフォルトページにします。

```ruby
route "root to: 'person#index'"
```

### `inside(dir)`

指定のディレクトリでコマンドを実行します。たとえば、自分のコンピュータにedge railsリポジトリのコピーがあり、自分の新しいアプリケーションからそこにシンボリックリンクを張るには以下のようにします。

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

### `ask(question)`

`ask()`を使うと、ユーザー入力を受け取ってテンプレートで利用できます。たとえば、新しく追加するライブラリ名をユーザーに入力させるには以下のようにします。

```ruby
lib_name = ask("ライブラリに付ける名前を入力してください")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### `yes?(question)`または`no?(question)`

テンプレートでのユーザー入力に応じて処理の流れを決めたい場合に使います。たとえば、ユーザーにマイグレーションを実行するようプロンプトを以下のように表示できます。

```ruby
rails_command("db:migrate") if yes?("データベースマイグレーションを実行しますか？")
# no?(question)はyes?と逆の動作
```

### `git(:command)`

Railsテンプレートで任意のgitコマンドを実行します。

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

### `after_bundle(&block)`

gemのバンドルとbinstub生成の完了後に実行したいコールバックを登録します。生成したすべてのファイルをバージョン管理に追加したい場合に便利です。

```ruby
after_bundle do
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end
```

これらのコールバックは`--skip-bundle`を指定した場合でもスキップされずに実行されます。

高度な利用法
--------------

アプリケーションテンプレートは、`Rails::Generators::AppGenerator`インスタンスのコンテキストで評価されます。ここで使われる[`apply`](https://www.rubydoc.info/gems/thor/Thor/Actions#apply-instance_method)アクションはThorが提供しています。
これにより、このインスタンスを必要に応じて拡張および変更できます。

たとえば、`source_paths`メソッドを上書きしてテンプレートの位置を指定できます。これにより、`copy_file`などのメソッドでテンプレートの位置からの相対パスを指定できるようになります。

```ruby
def source_paths
  [__dir__]
end
```
