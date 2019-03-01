
Railsの初期化プロセス
================================

本章は、Rails初期化プロセスの内部について解説します。上級Rails開発者向けに推奨される、きわめて高度な内容を扱っています。

このガイドの内容:

* `rails server`の使用法
* Rails初期化シーケンスのタイムライン
* ブートシーケンスで通常と異なるファイルが必要となる箇所
* `Rails::Server`インターフェイスの定義方法と利用法

--------------------------------------------------------------------------------

本章では、デフォルトのRailsアプリケーション向けにRuby on Railsスタックの起動時に必要となるすべてのメソッド呼び出しについて詳細に解説します。具体的には、`rails server`を実行してアプリケーションを起動したときにどのようなことが行われているかに注目して解説します。

NOTE: 文中に記載されるRuby on Railsアプリケーションへのパスは、特に記載のない限り相対パスを使用します。

TIP: Railsの[ソースコード](https://github.com/rails/rails)を参照しながら読み進めるのであれば、GitHubページ上で`t`キーバインドを使用してfile finderを起動し、ファイルを素早く見つけることをお勧めします。

起動!
-------

それではアプリケーションを起動して初期化を開始しましょう。Railsアプリケーションの起動は`rails console`または`rails server`を実行して行うのが普通です。

### `railties/exe/rails`

`rails server`のうち、`rails`コマンドの部分はRubyで記述された実行ファイルであり、読み込みパス上に置かれています。この実行ファイルには以下の行が含まれています。

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

このコマンドをRailsコンソールで実行すると、`railties/exe/rails`が読み込まれるのがわかります。`railties/exe/rails.rb`ファイルには以下のコードが含まれています。

```ruby
require "rails/cli"
```

今度は`railties/lib/rails/cli`ファイルが`Rails::AppLoader.exec_app`を呼び出します。

### `railties/lib/rails/app_loader.rb`

`exec_app`の主な目的は、Railsアプリケーションにある`bin/rails`を実行することです。カレントディレクトリに`bin/rails`がない場合、`bin/rails`が見つかるまでディレクトリを上に向って探索します。これにより、Railsアプリケーション内のどのディレクトリからでも`rails`コマンドを実行できるようになります。

`rails server`については、以下の同等のコマンドが実行されます。

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

このファイルの内容は次のとおりです。

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/boot'
require 'rails/commands'
```

`APP_PATH`定数は後で`rails/commands`で使用されます。この行で参照されている`config/boot`ファイルは、Railsアプリケーションの`config/boot.rb`ファイルであり、Bundlerの読み込みと設定を担当します。

### `config/boot.rb`

`config/boot.rb`には以下の行が含まれています。

```ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
```

標準的なRailsアプリケーションにはGemfileというファイルがあり、アプリケーション内のすべての依存関係がそのファイル内で宣言されています。`config/boot.rb`はGemfileの位置を`ENV['BUNDLE_GEMFILE']`に設定します。Gemfileが存在する場合、`bundler/setup`をrequireします。このrequireは、Gemfileの依存ファイルが置かれている読み込みパスをBundlerで設定する際に使用されます。

標準的なRailsアプリケーションは多くのgemに依存しますが、特に以下のgemに依存しています。

* actioncable
* actionmailer
* actionpack
* actionview
* activejob
* activemodel
* activerecord
* activestorage
* activesupport
* arel
* builder
* bundler
* erubi
* i18n
* mail
* mime-types
* rack
* rack-test
* rails
* railties
* rake
* sqlite3
* thor
* tzinfo

### `rails/commands.rb`

`config/boot.rb`の設定が完了すると、次にrequireするのはコマンドの別名を拡張する`rails/commands`です。この状況では`ARGV`配列に`server`だけが含まれており、以下のように受け渡しされます。

```ruby
require_relative "command"

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console"
  "s"  => "server",
  "db" => "dbconsole"
  "r"  => "runner",
  "t"  => "test"
}

command = ARGV.shift
command = aliases[command] || command

Rails::Command.invoke command, ARGV
```

`server`の代わりに`s`が渡されると、ここで定義されている`aliases`の中からマッチするコマンドを探します。

### `rails/command.rb`

何らかのRailsコマンドを1つ入力すると、指定の名前空間内にコマンドがあるかどうか`invoke`が探索を試み、見つかった場合はそのコマンドを実行します。

コマンドがRailsによって認識されない場合はRakeに引き継いで同じ名前で実行します。

以下のソースにあるように、`Rails::Command`は`args`が空の場合に自動的にヘルプを出力します。

```ruby
module Rails::Command
  class << self
    def invoke(namespace, args = [], **config)
      namespace = namespace.to_s
      namespace = "help" if namespace.blank? || HELP_MAPPINGS.include?(namespace)
      namespace = "version" if %w( -v --version ).include? namespace

      if command = find_by_namespace(namespace)
        command.perform(namespace, args, config)
      else
        find_by_namespace("rake").perform(namespace, args, config)
      end
    end
  end
end
```

`server`コマンドが指定されると、Railsはさらに以下のコードを実行します。

```ruby
module Rails
  module Command
    class ServerCommand < Base # :nodoc:
      def perform
        set_application_directory!

        Rails::Server.new.tap do |server|
          # Require application after server sets environment to propagate
          # the --environment option.
          require APP_PATH
          Dir.chdir(Rails.application.root)
          server.start
        end
      end
    end
  end
end
```

上のファイルは、`config.ru`ファイルが見つからない場合に限り、Railsのルートディレクトリ (`config/application.rb`を指す`APP_PATH`から2階層上のディレクトリ) に置かれます。このコードは続いて`rails/commands/server`を実行します。これは`Rails::Server`クラスを設定するものです。

### `actionpack/lib/action_dispatch.rb`

Action DispatchはRailsフレームワークのルーティングを司るコンポーネントです。ルーティング、セッションおよび共通のミドルウェアなどの機能を提供します。

### `rails/commands/server_command.rb`

`Rails::Server`クラスはこのファイル内で定義されており、`Rack::Server`を継承しています。`Rails::Server.new`を呼び出すと、`rails/commands/server.rb`の`initialize`メソッドが呼び出されます。

```ruby
def initialize(*)
  super
  set_environment
end
```

最初に`super`が呼び出され、そこから`Rack::Server`の`initialize`メソッドを呼び出します。

### Rack: `lib/rack/server.rb`

`Rack::Server`は、あらゆるRackベースのアプリケーション (Railsもその1つです) のための共通のサーバーインターフェイスを提供する役割を担います。

`Rack::Server`の`initialize`は、いくつかの変数を設定しているだけの簡単なメソッドです。

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

この場合`options`の値は`nil`になるので、このメソッドでは何も実行されません。

`super`が`Rack::Server`の中で完了すると、`rails/commands/server_command.rb`に制御が戻ります。この時点で、`set_environment`が`Rails::Server`オブジェクトのコンテキスト内で呼び出されますが、一見したところ大した処理を行なっていないように見えます。

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

  # Don't evaluate CGI ISINDEX parameters.
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
  super.merge(
    Port:               ENV.fetch("PORT", 3000).to_i,
    Host:               ENV.fetch("HOST", "localhost").dup,
    DoNotReverseLookup: true,
    environment:        (ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development").dup,
    daemonize:          false,
    caching:            nil,
    pid:                Options::DEFAULT_PID_PATH,
    restart_cmd:        restart_command)
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

  option_parser(options).parse! args

  options[:log_stdout] = options[:daemonize].blank? && (options[:environment] || Rails.env) == "development"
  options[:server]     = args.shift
  options
end
```

このメソッドは`options`のキーを設定します。Railsはこれを使用して、どのようにサーバーを実行するかを決定します。`initialize`が完了すると、先ほど設定した`APP_PATH`がrequireされたサーバーコマンドに制御が戻ります。

### `config/application`

`require APP_PATH`が実行されると、続いて`config/application.rb`が読み込まれます (`APP_PATH`が`bin/rails`で定義されていることを思い出しましょう)。この設定ファイルはRailsアプリケーションの中にあり、必要に応じて自由に変更できます。

### `Rails::Server#start`

`config/application`が読み込まれると、続いて`server.start`が呼び出されます。このメソッド定義は以下のようになっています。

```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  setup_dev_caching
  log_to_stdout if options[:log_stdout]

  super
  ...
end

private
  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
  end

  def create_tmp_directories
    %w(cache pids sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
    end
  end

  def setup_dev_caching
    if options[:environment] == "development"
      Rails::DevCaching.enable_by_argument(options[:caching])
    end
  end

  def log_to_stdout
    wrapped_app # アプリケーションにタッチしてロガーを設定

    console = ActiveSupport::Logger.new(STDOUT)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

   unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
      Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
    end
  end
```


Rails初期化の最初の出力はここで行われます。このメソッドでは`INT`シグナルのトラップが作成され、`CTRL-C`キーを押すことでサーバープロセスが終了するようになります。コードに示されているように、ここでは`tmp/cache`、`tmp/pids`、`tmp/sessions`および`tmp/sockets`ディレクトリが作成されます。`rails server`に`--dev-caching`オプションを指定して呼び出した場合は、development環境でのキャッシュをオンにします。最後に`wrapped_app`が呼び出されます。このメソッドは、`ActiveSupport::Logger`のインスタンスの作成とアサインが行われる前に、Rackアプリケーションを作成する役割を担います。

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

  # ラップされたアプリケーションにタッチすることで、config.ruが読み込まれてから
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

Railsアプリケーションとして興味深いのは、最終行にある`server.run`でしょう。ここでも`wrapped_app`メソッドが再び使われています。今度はこのメソッドをもう少し詳しく調べてみましょう (既に一度実行され、メモ化されてはいますが)。

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

require_relative 'config/environment'
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
require_relative 'config/environment'
```

### `config/environment.rb`

このファイルは`config.ru` (`rails server`)とPassengerの両方で必要となるファイルです。サーバーを実行するためのこれら2種類の方法はここで合流します。ここより前の部分はすべてRackとRailsの設定です。

このファイルの冒頭部分では`config/application.rb`がrequireされます。

```ruby
require_relative 'application'
```

### `config/application.rb`

このファイルでは`config/boot.rb`がrequireされます。

```ruby
require_relative 'boot'
```

それまでにboot.rbが`require`されていなかった場合に限り、`rails server`の場合にはboot.rbが`require`されます。ただしPassengerを使う場合にはboot.rbが`require`**されません**。

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
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  active_storage/engine
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end
```

ここでRailsのすべてのフレームワークが読み込まれ、アプリケーションから利用できるようになります。本章ではこれらのフレームワークの詳細については触れませんが、皆様にはぜひ自分でこれらのフレームワークを探索してみることをお勧めいたします。

現時点では、Railsエンジン、I18n、Rails設定などの共通機能がここで定義されていることを押さえておいてください。

### `config/environment.rb`に戻る


`config/application.rb`の残りの行では`Rails::Application`の設定を行います。この設定はアプリケーションの初期化が完全に完了してから使用されます。`config/application.rb`がRailsの読み込みを完了し、アプリケーションの名前空間が定義されると、制御はふたたび`config/environment.rb`に戻ります。ここでは`Rails.application.initialize!`によるアプリケーションの初期化が行われます。これは`rails/application.rb`で定義されています。

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

この`run_initializers`はややトリッキーなコードになっています。Railsはここで、あらゆる先祖クラスをくまなく調べ、あるひとつの`initializers`メソッドに応答するものを探しだしています。続いてそれらを名前でソートし、その順序で実行します。たとえば、`Engine`クラスは`initializers`メソッドを提供しているので、あらゆるエンジンが利用できるようになります。

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

ここで、`Server#start`の最終行で`build_app`が (`wrapped_app`によって) 呼び出されていたことを思い出しましょう。最後に見かけたときのコードは以下のようになっていました。

```ruby
server.run wrapped_app, options, &blk
```

ここで使われている`server.run`の実装は、アプリケーションで使うWebサーバーに依存します。たとえばPumaを使用している場合、`run`メソッドは以下のようになります。

```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options = DEFAULT_OPTIONS.merge(options)

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

本章ではサーバーの設定自体については深入りしませんが、この箇所はRailsの初期化プロセスという長い旅の最後のひとかけらです。

本章で解説した高度な概要は、自分が開発したコードがいつどのように実行されるかを理解するためにも、そしてより優れたRails開発者になるためにも役に立つことでしょう。もっと詳しく知りたいのであれば、次のステップとしてRailsのソースコードそのものを追うのがおそらく最適です。
