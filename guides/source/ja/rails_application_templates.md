


Rails のアプリケーションテンプレート
===========================

Railsのアプリケーションテンプレートは単純なRubyファイルであり、新規または既存のRailsプロジェクトにgemやイニシャライザを追加するためのDSL (ドメイン固有言語) を含んでいます。

このガイドの内容:

* テンプレートを使用してRailsアプリケーションの生成/カスタマイズを行う方法
* RailsテンプレートAPIを使用して再利用可能なアプリケーションテンプレートを開発する方法

--------------------------------------------------------------------------------

### 使用法
-----

アプリケーションテンプレートを適用するためには、-mオプションを使用してテンプレートの場所を指定する必要があります。ファイルパスまたはURLのどちらでも使用できます。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

rakeタスク`app:template`を使用して、既存のRailsアプリケーションにテンプレートを適用することもできます。テンプレートの場所はLOCATION環境変数を使用して渡す必要があります。ここでも、ファイルパスまたはURLのどちらを使用してもかまいません。

```bash
$ bin/rails app:template LOCATION=~/template.rb
$ bin/rails app:template LOCATION=http://example.com/template.rb
```

テンプレートAPI
------------

RailsのテンプレートAPIはわかりやすく設計されています。以下は代表的なRailsアプリケーションテンプレートです。

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

以下のセクションで、APIで提供される主なメソッドの概要を解説します。

### gem(*args)

生成された`Gemfile`ファイルに、指定された`gem`のエントリを追加します。

たとえば、Railsアプリケーションが`bj`と`nokogiri` gemに依存しているとします。

```ruby
gem "bj"
gem "nokogiri"
```

Gemfileでgemを指定しただけではインストールされないのでご注意ください。指定したgemをインストールするためには`bundle install`を実行する必要があります。

```bash
bundle install
```

### gem_group(*names, &block)

gemのエントリを指定のグループに含めます。

たとえば、`rspec-rails` gemを`development`グループと`test`グループだけで読み込みたい場合は以下のようにします。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### add_source(source, options = {})

生成された`Gemfile`ファイルに、指定されたソースを追加します。

たとえば、`"http://code.whytheluckystiff.net"`にあるgemをソースとして使用したい場合は以下のようにします。

```ruby
add_source "http://code.whytheluckystiff.net"
```

### environment/application(data=nil, options={}, &block)

`config/application.rb`ファイルの`Application`クラスの内側に指定の行を追加します。

`options[:env]`が指定されている場合は、`config/environments`ディレクトリに置かれている同等のファイルに追加します。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

`data`引数の代わりにブロックをひとつ渡すこともできます。

### vendor/lib/file/initializer(filename, data = nil, &block)

生成されたRailsアプリケーションの`config/initializers`ディレクトリにイニシャライザをひとつ追加します。

たとえば、`Object#not_nil?`と`Object#not_blank?`というメソッドを使用したい場合は以下のようにします。

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

同様に、`lib()`は`lib/`ディレクトリに、`vendor()`は`vendor/`ディレクトリにそれぞれファイルをひとつ作成します。

`file()`メソッドを使用すれば、`Rails.root`からの相対パスを渡してディレクトリやファイルを自在に作成することもできます。

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

上のコードは`app/components`ディレクトリを作成し、その中に`foo.rb`ファイルを置きます。

### rakefile(filename, data = nil, &block)

指定されたタスクを含むrakeファイルを`lib/tasks`の下に作成します。

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

### generate(what, *args)

引数を渡してRailsジェネレータを実行します。

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### run(command)

任意のコマンドを実行します。いわゆるバッククォートと同等です。たとえば`README.rdoc`ファイルを削除する場合は以下のようにします。

```ruby
run "rm README.rdoc"
```

### rake(command, options = {})

Railsアプリケーション内にあるrakeタスクを指定して実行します。たとえばデータベースのマイグレーションを行うには以下のように書きます。

```ruby
rake "db:migrate"
```

Railsの環境を指定してrakeタスクを実行することもできます。

```ruby
rake "db:migrate", env: 'production'
```

### route(routing_code)

ルーティングエントリを`config/routes.rb`ファイルにひとつ追加します。上の手順では、scaffoldでpersonを生成し、続けて`README.rdoc`を削除しました。今度は以下のようにして`PeopleController#index`をアプリケーションのデフォルトページにします。

```ruby
route "root to: 'person#index'"
```

### inside(dir)

ディレクトリを指定してコマンドをひとつ実行します。たとえば、edge railsのコピーがあり、アプリケーションからそこにシンボリックリンクを張るには以下のようにします。

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

### ask(question)

`ask()`はユーザーからのフィードバックを受け取ってテンプレートで利用するのに使用します。たとえば、追加される新品のライブラリに付ける名前をユーザーに入力してもらうには、以下のようにします。

```ruby
lib_name = ask("ライブラリに付ける名前を入力してください")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### yes?(question) or no?(question)

テンプレートでユーザーからの入力に基いて処理の流れを変えたい場合に使用します。たとえば、指定があった場合にのみrailsをfreezeしたい場合は以下のようにします。

```ruby
rake("rails:freeze:gems") if yes?("Freeze rails gems?")
# no?(question) はyes?と逆の動作
```

### git(:command)

Railsテンプレートで任意のgitコマンドを実行します。

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

### after_bundle(&block)

gemのバンドルとbinstub生成の完了後に実行したいコールバックを登録します。生成したファイルをバージョン管理するところまで自動化したい場合に便利です。

```ruby
after_bundle do
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end
```

これらのコールバックは`--skip-bundle`や`--skip-spring`を指定した場合でもスキップされずに実行されます。

高度な利用法
--------------

アプリケーションテンプレートは、`Rails::Generators::AppGenerator`インスタンスのコンテキストで評価されます。ここで使用される`apply`アクションは[Thor](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L207)が提供しています。
これにより、このインスタンスを必要に応じて拡張したり変更したりできます。

たとえば、`source_paths`メソッドを上書きしてテンプレートの位置を指定することができます。これにより、`copy_file`などのメソッドでテンプレートの位置からの相対パスを指定できるようになります。

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end
```