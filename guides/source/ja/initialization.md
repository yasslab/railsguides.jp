
Rails の初期化プロセス
================================

本章は、Rails 4におけるRails初期化プロセスの内部について解説します。上級Rails開発者向けに推奨される、きわめて高度な内容を扱っています。

このガイドの内容:

* `rails server`の使用法
* Rails初期化シーケンスのタイムライン
* ブートシーケンスで通常と異なるファイルが必要となる箇所
* Rails::Serverインターフェイスの定義方法と使用法

--------------------------------------------------------------------------------

本章では、デフォルトのRails 4アプリケーション向けにRuby on Railsスタックの起動時に必要となるすべてのメソッド呼び出しについて、詳細な解説を行います。具体的には、`rails server`を実行してアプリケーションを起動したときにどのようなことが行われているかに注目して解説します。

NOTE: 文中に記載されるRuby on Railsアプリケーションへのパスは、特に記載のない限り相対パスを使用します。

TIP: Railsの[ソースコード](https://github.com/rails/rails)を参照しながら読み進めるのであれば、Githubページ上で`t`キーバインドを使用してfile finderを起動し、ファイルを素早く見つけることをお勧めします。

起動!
-------

それではアプリケーションを起動して初期化を開始しましょう。Railsアプリケーションの起動は`rails console`または`rails server`を実行して行うのが普通です。

### `railties/bin/rails`

`rails server`のうち、`rails`コマンドの部分はRubyで記述された実行ファイルであり、読み込みパス上に置かれています。この実行ファイルには以下の行が含まれています。

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

このコマンドをRailsコンソールで実行すると、`railties/bin/rails`が読み込まれるのがわかります。`railties/bin/rails.rb`ファイルには以下のコードが含まれています。

```ruby
require "rails/cli"
```

今度は`railties/lib/rails/cli`ファイルが`Rails::AppRailsLoader.exec_app_rails`を呼び出します。

### `railties/lib/rails/app_rails_loader.rb`

`exec_app_rails`の主要な目的な、Railsアプリケーションにある`bin/rails`を実行することです。カレントディレクトリに`bin/rails`がない場合、`bin/rails`が見つかるまでディレクトリを上に向って探索します。これにより、Railsアプリケーション内のどのディレクトリからでも`rails`コマンドを実行できるようになります。

`rails server`については、以下の同等のコマンドが実行されます。

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

このファイルの内容は次のとおりです。

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

`APP_PATH`定数は後で`rails/commands`で使用されます。この行で参照されている`config/boot`ファイルは、Railsアプリケーションの`config/boot.rb`ファイルであり、Bundlerの読み込みと設定を担当します。

### `config/boot.rb`

`config/boot.rb`には以下の行が含まれています。

```ruby
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
```

標準的なRailsアプリケーションにはGemfileというファイルがあり、アプリケーション内のすべての依存関係がそのファイル内で宣言されています。`config/boot.rb`はGemfileの位置を`ENV['BUNDLE_GEMFILE']`に設定します。Gemfileが存在する場合、`bundler/setup`をrequireします。このrequireは、Gemfileの依存ファイルが置かれている読み込みパスをBundlerで設定する際に使用されます。

標準的なRailsアプリケーションは多くのgemに依存しますが、特に以下のgemに依存しています。

* actionmailer
* actionpack
* actionview
* activemodel
* activerecord
* activesupport
* arel
* builder
* bundler
* erubis
* i18n
* mail
* mime-types
* rack
* rack-cache
* rack-mount
* rack-test
* rails
* railties
rake
* sqlite3
* thor
* tzinfo

### `rails/commands.rb`

`config/boot.rb`の設定が完了すると、次にrequireするのはコマンドの別名を拡張する`rails/commands`です。この状況で`ARGV`配列には`server`だけが含まれており、以下のように受け渡しされます。

```ruby
ARGV << '--help' if ARGV.empty?

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console"
  "s"  => "server",
  "db" => "dbconsole"
  "r"  => "runner"
}

command = ARGV.shift
command = aliases[command] || command

require 'rails/commands/commands_tasks'

Rails::CommandsTasks.new(ARGV).run_command!(command)
```

TIP: 実際にやってみるとわかるとおり、空のARGVリストが渡されると、使用法のスニペットが表示されます。

`server`の代わりに`s`が渡されると、ここで定義されている`aliases`の中からマッチするコマンドを探します。

### `rails/commands/command_tasks.rb`

`run_command`は、間違ったRailsコマンドが入力された時にエラーメッセージを表示する役割も担います。正しいコマンドの場合は同じ名前のメソッドが呼び出されます。

```ruby
COMMAND_WHITELIST = %(plugin generate destroy console server dbconsole application runner new version help)

def run_command!(command)
  command = parse_command(command)
  if COMMAND_WHITELIST.include?(command)
    send(command)
  else
    write_error_message(command)
  end
end
```

`server`コマンドが指定されると、Railsはさらに以下のコードを実行します。

```ruby
def set_application_directory!
  Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
end

def server
  set_application_directory!
  require_command!("server")

  Rails::Server.new.tap do |server|
    # サーバーが環境を設定してからアプリケーションをrequireする必要がある
    # そうしないとサーバーに与えられた環境オプションを展開できない
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end

def require_command!(command)
  require "rails/commands/#{command}"
end
```

上のファイルは、`config.ru`ファイルが見つからない場合に限り、Railsのルートディレクトリ (`config/application.rb`を指す`APP_PATH`から2階層上のディレクトリ) に置かれます。このコードは続いて`rails/commands/server`を実行します。これは`Rails::Server`クラスを設定するものです。

```ruby
require 'fileutils'
require 'optparse'
require 'action_dispatch'
require 'rails'

module Rails
  class Server < ::Rack::Server
```

`fileutils`および`optparse`は標準のRubyライブラリであり、それぞれファイル操作や解析オプションを使用できるヘルパー関数を提供します。

### `actionpack/lib/action_dispatch.rb`

Action DispatchはRailsフレームワークのルーティングを司るコンポーネントです。ルーティング、セッションおよび共通のミドルウェアなどの機能を提供します。

### `rails/commands/server.rb`

`Rails::Server`クラスはこのファイル内で定義されており、`Rack::Server`を継承しています。`Rails::Server.new`を呼び出すと、`rails/commands/server.rb`の`initialize`メソッドが呼び出されます。

```ruby
def initialize(*)
  super
  set_environment
end
```

最初に`super`が呼び出され、そこから`Rack::Server`の`initialize`メソッドを呼び出します。

### Rack: `lib/rack/server.rb`

`Rack::Server`は、あらゆるRackベースのアプリケーション (Railsもその中に含まれます) のための共通のサーバーインターフェイスを提供する役割を担います。

`Rack::Server`の`initialize`は、いくつかの変数を設定しているだけの簡単なメソッドです。

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

この場合`options`の値は`nil`になるので、このメソッドでは何も実行されません。

`super`が`Rack::Server`の中で完了すると、`rails/commands/server.rb`に制御が戻ります。この時点で、`set_environment`が`Rails::Server`オブジェクトのコンテキスト内で呼び出されますが、一見したところ大した処理を行なっていないように見えます。

```ruby
def set_environment
  ENV["RAILS_ENV"] ||= options[:environment]
end
```

実際にはこの`options`メソッドではきわめて多くの処理を実行しています。このメソッド定義は`Rack::Server`にあり、以下のようになっています。

```ruby
def options
  @options ||= parse_options(ARGV)
end
```

そして`parse_options`は以下のように定義されています。

```ruby
def parse_options(args)
  options = default_options

  # CGI ISINDEXパラメータをevaluateしないこと
  # http://www.meb.uni-bonn.de/docs/cgi/cl.html
  args.clear if ENV.include?("REQUEST_METHOD")

  options.merge! opt_parser.parse!(args)
  options[:config] = ::File.expand_path(options[:config])
  ENV["RACK_ENV"] = options[:environment]
  options
end
```

`default_options`では以下を設定します。

```ruby
def default_options
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

  {
    :environment => environment,
    :pid         => nil,
    :Port        => 9292,
    :Host        => default_host,
    :AccessLog   => [],
    :config      => "config.ru"
  }
end
```

`ENV`に`REQUEST_METHOD`キーがないので、その行はスキップできます。次の行では`opt_parser`からのオプションをマージします。`opt_parser`は`Rack::Server`で明確に定義されています。

```ruby
def opt_parser
  Options.new
end
```

このクラスは`Rack::Server`で定義されていますが、異なる引数を扱うために`Rails::Server`で上書きされます。`Rails::Server`の`parse!`の冒頭部分は以下のようになっています。

```ruby
def parse!(args)
  args, options = args.dup, {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rails server [mongrel, thin, etc] [options]"
    opts.on("-p", "--port=port", Integer,
            "Runs Rails on the specified port.", "Default: 3000") { |v| options[:Port] = v }
  ...
```

このメソッドは`options`のキーを設定します。Railsはこれを使用して、どのようにサーバーを実行するかを決定します。`initialize`が完了すると、`rails/server`に戻ります。ここでは先ほど設定された`APP_PATH`がrequireされます。

### `config/application`

`require APP_PATH`が実行されると、続いて`config/application.rb`が読み込まれます (`APP_PATH`が`bin/rails`で定義されていることを思い出しましょう)。この設定ファイルはRailsアプリケーションの中にあり、必要に応じて自由に変更することができます。

### `Rails::Server#start`

`config/application`が読み込まれると、続いて`server.start`が呼び出されます。このメソッド定義は以下のようになっています。

```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  log_to_stdout if options[:log_stdout]

  super
  ...
end

private

  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
    ...
    puts "=> Ctrl-C to shutdown server" unless options[:daemonize]
  end

  def create_tmp_directories
    %w(cache pids sessions sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
    end
  end

  def log_to_stdout
    wrapped_app # アプリにタッチしてロガーを設定

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
  end
```

Rails初期化の最初の出力が行われるのがこの箇所です。このメソッドでは`INT`シグナルのトラップが作成され、`CTRL-C`キーを押すことでサーバープロセスが終了するようになります。コードに示されているように、ここでは`tmp/cache`、`tmp/pids`、`tmp/sessions`および`tmp/sockets`ディレクトリが作成されます。続いて`wrapped_app`が呼び出されます。このメソッドは、`ActiveSupport::Logger`のインスタンスの作成とアサインが行われる前に、Rackアプリを作成する役割を担います。

`super`メソッドは`Rack::Server.start`を呼び出します。このメソッド定義の冒頭は以下のようになっています。

```ruby
def start &blk
  if options[:warn]
    $-w = true
  end

  if includes = options[:include]
    $LOAD_PATH.unshift(*includes)
  end

  if library = options[:require]
    require library
  end

  if options[:debug]
    $DEBUG = true
    require 'pp'
    p options[:server]
    pp wrapped_app
    pp app
  end

  check_pid! if options[:pid]

  # ラップされたアプリにタッチすることで、config.ruが読み込まれてから
  # デーモン化されるようにする (chdirなど).
  wrapped_app

  daemonize_app if options[:daemonize]

  write_pid if options[:pid]

  trap(:INT) do
    if server.respond_to?(:shutdown)
      server.shutdown
    else
      exit
    end
  end

  server.run wrapped_app, options, &blk
end
```

Railsアプリケーションとして興味深いのは、最終行にある`server.run`でしょう。ここでも`wrapped_app`メソッドが再び使用されています。今度はこのメソッドをもう少し詳しく調べてみましょう (既に一度実行され、メモ化されてはいますが)。

```ruby
@wrapped_app ||= build_app app
```

この`app`メソッドの定義は以下のようになっています。

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end
...
private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

`options[:config]`の値はデフォルトでは`config.ru`です。`config.ru`には以下が含まれています。

```ruby
# このファイルはRackベースのサーバーでアプリケーションの起動に使用される

require ::File.expand_path('../config/environment', __FILE__)
run <%= app_const %>
```


上のコードの`Rack::Builder.parse_file`メソッドは、この`config.ru`ファイルの内容を取り出し、以下のコードを使用して解析 (parse) します。

```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
end
```

`Rack::Builder`の`initialize`メソッドはこのブロックを受け取り、`Rack::Builder`のインスタンスの中で実行します。Railsの初期化プロセスの大半がこの場所で実行されます。`config.ru`の`config/environment.rb`の`require`行が最初に実行されます。

```ruby
require ::File.expand_path('../config/environment', __FILE__)
```

### `config/environment.rb`

このファイルは`config.ru` (`rails server`)とPassengerの両方で必要となるファイルです。サーバーを実行するためのこれら2種類の方法はここで出会います。ここより前の部分はすべてRackとRailsの設定です。

このファイルの冒頭部分では`config/application.rb`がrequireされます。

```ruby
require File.expand_path('../application', __FILE__)
```

### `config/application.rb`

このファイルでは`config/boot.rb`がrequireされます。

```ruby
require File.expand_path('../boot', __FILE__)
```

それまでにboot.rbがrequireされていなかった場合に限り、`rails server`の場合にはboot.rbがrequireされます。ただしPassengerを使用する場合にはboot.rbがrequire**されません**。

ここからいよいよ面白くなってきます。

Railsを読み込む
-------------

`config/application.rb`の次の行は以下のようになっています。

```ruby
require 'rails/all'
```

### `railties/lib/rails/all.rb`

このファイルはRailsのすべてのフレームワークをrequireする役目を担当します。

```ruby
require "rails"

%w(
  active_record
  action_controller
  action_view
  action_mailer
  rails/test_unit
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end
```

ここでRailsのすべてのフレームワークが読み込まれ、アプリケーションから利用できるようになります。本章ではこれらのフレームワークの詳細については触れませんが、皆様にはぜひ自分でこれらのフレームワークを探索してみることをお勧めいたします。

現時点では、Railsエンジン、I18n、Rails設定などの共通機能がここで定義されていることを押さえておいてください。

### `config/environment.rb`に戻る

`config/application.rb`の残りの行では`Rails::Application`の設定を行います。この設定はアプリケーションの初期化が完全に完了してから使用されます。`config/application.rb`がRailsの読み込みを完了し、アプリケーションの名前空間が定義されると、制御はふたたび`config/environment.rb`に戻ります。ここではアプリケーションの初期化が行われます。たとえばアプリケーションの名前が`Blog`であれば、environment.rbに`Rails.application.initialize!`という行があります。これは`rails/application.rb`で定義されています。

### `railties/lib/rails/application.rb`

その`initialize!`メソッドは以下のようなコードです。

```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

見てのとおり、アプリケーションの初期化は一度だけ行うことができます。`railties/lib/rails/initializable.rb`で定義されている`run_initializers`メソッドによって各種イニシャライザが実行されます。

```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

この`run_initializers`のコードはややトリッキーな作りになっています。Railsはここで、あらゆるクラス先祖をくまなく調べ、あるひとつの`initializers`メソッドに応答するものを探しだしています。続いてそれらを名前でソートし、その順序で実行します。たとえば、`Engine`クラスは`initializers`メソッドを提供しているので、あらゆるエンジンが利用できるようになります。

`Rails::Application`クラスは`railties/lib/rails/application.rb`ファイルで定義されており、その中で`bootstrap`、`railtie`、`finisher`イニシャライザをそれぞれ定義しています。`bootstrap`イニシャライザは、ロガーの初期化などアプリケーションの準備を行います。一方、最後に実行される`finisher`イニシャライザはミドルウェアスタックのビルドなどを行います。`railtie`イニシャライザは`Rails::Application`自身で定義されており、`bootstrap`と`finishers`の間に実行されます。

これが完了したら、制御は`Rack::Server`に移ります。

### Rack: lib/rack/server.rb

`app`メソッドが定義されている箇所は、最後に見た時は以下のようになっていました。

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end
...
private
  def build_app_and_options_from_config
    if !::File.exist?options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

このコードにおける`app`とは、Railsアプリケーション自身 (ミドルウェア) であり、
その後では、提供されているすべてのミドルウェアをRackが呼び出します。

```ruby
def build_app(app)
  middleware[options[:environment]].reverse_each do |middleware|
    middleware = middleware.call(self) if middleware.respond_to?(:call)
    next unless middleware
    klass = middleware.shift
    app = klass.new(app, *middleware)
  end
  app
end
```

ここで、`Server#start`の最終行で`build_app`が (`wrapped_app`によって) 呼び出されていたことを思い出してください。最後に見かけたときのコードは以下のようになっていました。

```ruby
server.run wrapped_app, options, &blk
```

ここで使用している`server.run`の実装は、アプリケーションで使用しているサーバーに依存します。たとえばPumaを使用している場合、`run`メソッドは以下のようになります。

```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options  = DEFAULT_OPTIONS.merge(options)

  if options[:Verbose]
    app = Rack::CommonLogger.new(app, STDOUT)
  end

  if options[:environment]
    ENV['RACK_ENV'] = options[:environment].to_s
  end

  server   = ::Puma::Server.new(app)
  min, max = options[:Threads].split(':', 2)

  puts "Puma #{::Puma::Const::PUMA_VERSION} starting..."
  puts "* Min threads: #{min}, max threads: #{max}"
  puts "* Environment: #{ENV['RACK_ENV']}"
  puts "* Listening on tcp://#{options[:Host]}:#{options[:Port]}"

  server.add_tcp_listener options[:Host], options[:Port]
  server.min_threads = min
  server.max_threads = max
  yield server if block_given?

  begin
    server.run.join
  rescue Interrupt
    puts "* Gracefully stopping, waiting for requests to finish"
    server.stop(true)
    puts "* Goodbye!"
  end

end
```

本章ではサーバーの設定自体については深く立ち入ることはしませんが、この箇所はRailsの初期化プロセスという長い旅の最後のピースです。

本章で解説した高度な概要は、自分が開発したコードがいつどのように実行されるかを理解するためにも、そしてより優れたRails開発者になるためにも役に立つことでしょう。もっと詳しく知りたいのであれば、次のステップとしてRailsのソースコード自身を追うのがおそらく最適でしょう。