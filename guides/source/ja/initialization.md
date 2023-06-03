Rails の初期化プロセス
================================

本ガイドは、Ruby on Rails本体のソースコードに含まれているRails Guidesの[The Rails Initialization Process](https://guides.rubyonrails.org/initialization.html)を日本語に翻訳した文書です。

本章は、Rails初期化プロセスの内部について解説します。上級Rails開発者向けに推奨される、きわめて高度な内容を扱っています。

このガイドの内容:

* `bin/rails server`の利用法
* Rails初期化シーケンスのタイムライン
* 起動シーケンスで通常以外のファイルが必要な場所
* `Rails::Server`インターフェイスの定義方法と利用法

--------------------------------------------------------------------------------

本ガイドでは、デフォルトのRailsアプリケーションでRuby on Railsスタックの起動時に必要なすべてのメソッド呼び出しについて詳しく解説します。具体的には、`bin/rails server`を実行してアプリケーションを起動するとどのようなことが行われているかに注目して解説します。

NOTE: 特に記載のない限り、文中に記載されるRuby on Railsアプリケーションへのパスは相対パスです。

TIP: Railsの[ソースコード](https://github.com/rails/rails)を参照しながら読み進めるのであれば、GitHubページの`t`キーバインドでfile finderを起動するとその場でファイルを素早く検索できます。

起動!
-------

それではアプリケーションを起動して初期化を開始しましょう。Railsアプリケーションの起動は、`bin/rails console`または`bin/rails server`を実行して行うのが普通です。

### `bin/rails`

このファイルの内容は次のとおりです。

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative "../config/boot"
require "rails/commands"
```

`APP_PATH`定数は、後で`rails/commands`で使われます。この行で参照されている`config/boot`ファイルは、Railsアプリケーションの`config/boot.rb`ファイルであり、Bundlerの読み込みと設定を担当します。

### `config/boot.rb`

`config/boot.rb`には以下の行が含まれています。

```ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
```

標準的なRailsアプリケーションにはGemfileというファイルがあり、アプリケーション内のすべての依存関係がそのファイル内で宣言されています。`config/boot.rb`はGemfileの位置を`ENV['BUNDLE_GEMFILE']`に設定します。Gemfileが存在する場合、`bundler/setup`を`require`します。この`require`は、Gemfileの依存ファイルが置かれている読み込みパスをBundlerで設定するときに使われます。

### `rails/commands.rb`

`config/boot.rb`の実行が完了すると、次にコマンドのエイリアスを拡張する`rails/commands`を`require`します。この状況では`ARGV`配列に`server`だけが含まれており、以下のように渡されます。

```ruby
require "rails/command"

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner",
  "t"  => "test"
}

command = ARGV.shift
command = aliases[command] || command

Rails::Command.invoke command, ARGV
```

`server`の代わりに`s`が渡されると、ここで定義されている`aliases`の中からマッチするコマンドを探します。

### `rails/command.rb`

Railsコマンドを入力すると、`invoke`が指定の名前空間内でコマンドを探索し、見つかった場合はそのコマンドを実行します。

コマンドがRailsによって認識されない場合は、Rakeが引き継いで同じ名前でタスクを実行します。

以下のソースコードでわかるように、`namespace`が空の場合、`Rails::Command`は自動的にヘルプを出力します。

```ruby
module Rails
  module Command
    class << self
      def invoke(full_namespace, args = [], **config)
        namespace = full_namespace = full_namespace.to_s

        if char = namespace =~ /:(\w+)$/
          command_name, namespace = $1, namespace.slice(0, char)
        else
          command_name = namespace
        end

        command_name, namespace = "help", "help" if command_name.blank? || HELP_MAPPINGS.include?(command_name)
        command_name, namespace = "version", "version" if %w( -v --version ).include?(command_name)

        command = find_by_namespace(namespace, command_name)
        if command && command.all_commands[command_name]
          command.perform(command_name, args, config)
        else
          find_by_namespace("rake").perform(full_namespace, args, config)
        end
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
        extract_environment_option_from_argument
        set_application_directory!
        prepare_restart

        Rails::Server.new(server_options).tap do |server|
          # Require application after server sets environment to propagate
          # the --environment option.
          require APP_PATH
          Dir.chdir(Rails.application.root)

          if server.serveable?
            print_boot_information(server.server, server.served_url)
            after_stop_callback = -> { say "Exiting" unless options[:daemon] }
            server.start(after_stop_callback)
          else
            say rack_server_suggestion(using)
          end
        end
      end
    end
  end
end
```

上のファイルは、`config.ru`ファイルが見つからない場合に限り、Railsのルートディレクトリ（`config/application.rb`を指す`APP_PATH`から2階層上のディレクトリ）に移動します。これによって、次は`Rails::Server`クラスが起動されます。

### `actionpack/lib/action_dispatch.rb`

Action Dispatchは、Railsフレームワークのルーティングコンポーネントです。ルーティング、セッション、共通のミドルウェアなどの機能を提供します。

### `rails/commands/server_command.rb`

`Rails::Server`クラスは、`Rack::Server`を継承することでこのファイル内で定義されます。`Rails::Server.new`を呼び出すと、`rails/commands/server/server_command.rb`の`initialize`メソッドが呼び出されます。

```ruby
module Rails
  class Server < ::Rack::Server
    def initialize(options = nil)
      @default_options = options || {}
      super(@default_options)
      set_environment
    end
  end
end
```

最初に`super`が呼び出され、そこから`Rack::Server`の`initialize`メソッドを呼び出します。

### Rack: `lib/rack/server.rb`

`Rack::Server`は、あらゆるRackベースのアプリケーション向けに共通のサーバーインターフェイスを提供する役割を担います（RailsもRackアプリケーションの一種です）。

`Rack::Server`の`initialize`は、いくつかの変数を設定するだけの簡単なメソッドです。

```ruby
module Rack
  class Server
    def initialize(options = nil)
      @ignore_options = []

      if options
        @use_default_options = false
        @options = options
        @app = options[:app] if options[:app]
      else
        argv = defined?(SPEC_ARGV) ? SPEC_ARGV : ARGV
        @use_default_options = true
        @options = parse_options(argv)
      end
    end
  end
end
```

ここでは、`Rails::Command::ServerCommand#server_options`が返す値が`options`に代入されます。
`if`文の内側の行が評価されると、いくつかのインスタンス変数が設定されます。

`Rails::Command::ServerCommand`の`server_options`メソッド定義は以下のとおりです。

```ruby
module Rails
  module Command
    class ServerCommand
      no_commands do
        def server_options
          {
            user_supplied_options: user_supplied_options,
            server:                using,
            log_stdout:            log_to_stdout?,
            Port:                  port,
            Host:                  host,
            DoNotReverseLookup:    true,
            config:                options[:config],
            environment:           environment,
            daemonize:             options[:daemon],
            pid:                   pid,
            caching:               options[:dev_caching],
            restart_cmd:           restart_command,
            early_hints:           early_hints
          }
        end
      end
    end
  end
end
```

この値が`@options`インスタンス変数に代入されます。

`super`が`Rack::Server`の中で完了すると、`rails/commands/server_command.rb`に制御が戻ります。この時点で、`set_environment`が`Rails::Server`オブジェクトのコンテキスト内で呼び出されます。

```ruby
module Rails
  module Server
    def set_environment
      ENV["RAILS_ENV"] ||= options[:environment]
    end
  end
end
```

`initialize`が完了すると、サーバーコマンドに制御が戻り、そこで`APP_PATH`（先ほど設定済み）が`require`されます。

### `config/application`

`require APP_PATH`が実行されると、続いて`config/application.rb`が読み込まれます（`APP_PATH`は`bin/rails`で定義されていることを思い出しましょう）。この設定ファイルはRailsアプリケーションの中にあり、必要に応じて自由に変更できます。

### `Rails::Server#start`

`config/application`の読み込みが完了すると、`server.start`が呼び出されます。このメソッド定義は以下のようになっています。

```ruby
module Rails
  class Server < ::Rack::Server
    def start(after_stop_callback = nil)
      trap(:INT) { exit }
      create_tmp_directories
      setup_dev_caching
      log_to_stdout if options[:log_stdout]

      super()
      # ...
    end

    private
      def setup_dev_caching
        if options[:environment] == "development"
          Rails::DevCaching.enable_by_argument(options[:caching])
        end
      end

      def create_tmp_directories
        %w(cache pids sockets).each do |dir_to_make|
          FileUtils.mkdir_p(File.join(Rails.root, "tmp", dir_to_make))
        end
      end

      def log_to_stdout
        wrapped_app # touch the app so the logger is set up

        console = ActiveSupport::Logger.new(STDOUT)
        console.formatter = Rails.logger.formatter
        console.level = Rails.logger.level

        unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
          Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
        end
      end
  end
end
```

このメソッドは`INT`シグナルのトラップを作成するので、`CTRL-C`キーを押したときにサーバープロセスが終了するようになります。
コードに示されているように、ここでは`tmp/cache`、`tmp/pids`、`tmp/sockets`ディレクトリが作成されます。`bin/rails server`に`--dev-caching`オプションを指定して呼び出した場合は、development環境でのキャッシュをオンにします。最後に`wrapped_app`が呼び出されます。このメソッドは、`ActiveSupport::Logger`のインスタンスの作成と代入の前に、Rackアプリケーションを作成する役割を担います。

`super`メソッドは`Rack::Server.start`を呼び出します。このメソッド定義の冒頭は以下のようになっています。

```ruby
module Rack
  class Server
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
        require "pp"
        p options[:server]
        pp wrapped_app
        pp app
      end

      check_pid! if options[:pid]

      # Touch the wrapped app, so that the config.ru is loaded before
      # daemonization (i.e. before chdir, etc).
      handle_profiling(options[:heapfile], options[:profile_mode], options[:profile_file]) do
        wrapped_app
      end

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
  end
end
```

Railsアプリケーションとして興味深い部分は、最終行の`server.run`でしょう。ここでも`wrapped_app`メソッドが再び使われています。今度はこのメソッドをもう少し詳しく調べてみましょう（既に一度実行されてメモ化済みですが）。

```ruby
module Rack
  class Server
    def wrapped_app
      @wrapped_app ||= build_app app
    end
  end
end
```

この`app`メソッドの定義は以下のようになっています。

```ruby
module Rack
  class Server
    def app
      @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
    end

    # ...

    private
      def build_app_and_options_from_config
        if !::File.exist? options[:config]
          abort "configuration #{options[:config]} not found"
        end

        app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
        @options.merge!(options) { |key, old, new| old }
        app
      end

      def build_app_from_string
        Rack::Builder.new_from_string(self.options[:builder])
      end

  end
end
```

`options[:config]`の値はデフォルトでは`config.ru`です。`config.ru`の内容は以下のようになっています。

```ruby
# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
```

上のコードの`Rack::Builder.parse_file`メソッドは、この`config.ru`ファイルの内容を受け取って、以下のコードで解析（parse）します。

```ruby
module Rack
  class Builder
    def self.load_file(path, opts = Server::Options.new)
      # ...
      app = new_from_string cfgfile, config
      # ...
    end

    # ...

    def self.new_from_string(builder_script, file="(rackup)")
      eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
        TOPLEVEL_BINDING, file, 0
    end
  end
end
```

`Rack::Builder`の`initialize`メソッドはこのブロックを受け取り、`Rack::Builder`のインスタンスの中で実行します。Railsの初期化プロセスの大半がこの場所で実行されます。
最初に実行されるのは、`config.ru`の`config/environment.rb`の`require`行です。

```ruby
require_relative "config/environment"
```

### `config/environment.rb`

このファイルは、`config.ru`（`rails server`）とPassengerの両方で`require`されるコマンドファイルです。サーバーを実行するためのこれら2種類の方法はここで合流します。ここより前の部分はすべてRackとRailsの設定です。

このファイルの冒頭部分では`config/application.rb`を`require`します。

```ruby
require_relative "application"
```

### `config/application.rb`

このファイルは`config/boot.rb`を`require`します。

```ruby
require_relative "boot"
```

ただし、それまで`require`されていなかった場合に限り、`bin/rails server`の場合にboot.rbが`require`されます。ただしPassengerを使う場合はboot.rbを`require`**しません**。

ここからいよいよ面白くなってきます。

Railsを読み込む
-------------

`config/application.rb`の次の行は以下のようになっています。

```ruby
require "rails/all"
```

### `railties/lib/rails/all.rb`

このファイルはRailsのすべてのフレームワークを`require`する役目を担当します。

```ruby
require "rails"

%w(
  active_record/railtie
  active_storage/engine
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  action_mailbox/engine
  action_text/engine
  rails/test_unit/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end
```

ここでRailsのすべてのフレームワークが読み込まれ、アプリケーションで利用できるようになります。本ガイドではこれらのフレームワークの詳細については触れませんが、ぜひこれらのフレームワークを自分で調べてみることをおすすめします。

現時点では、Railsエンジン、I18n、Rails設定などの共通機能がここで定義されていることを押さえておいてください。

### `config/environment.rb`に戻る

`config/application.rb`の残りの行では`Rails::Application`を設定します。この設定が使われるのは、アプリケーションの初期化が完全に終わった後です。
`config/application.rb`がRailsの読み込みを完了し、アプリケーションの名前空間が定義されると、`config/environment.rb`に制御が戻ります。
ここでは`Rails.application.initialize!`でアプリケーションが初期化されます。これは`rails/application.rb`で定義されています。

### `railties/lib/rails/application.rb`

`initialize!`メソッドは以下のようなコードです。

```ruby
def initialize!(group = :default) # :nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

アプリケーションは一度だけ初期化できます。`railties/lib/rails/initializable.rb`で定義されている`run_initializers`メソッドによって、Railtieのさまざまな[イニシャライザ](configuring.html#イニシャライザ)が実行されます。

```ruby
def run_initializers(group = :default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

`run_initializers`のコード自身はトリッキーです。Railsはここで、あらゆる先祖クラスの中から`initializers`メソッドに応答するものを探索します。次にそれらを名前順でソートして実行します。たとえば、`Engine`クラスは`initializers`メソッドを提供しているので、あらゆるエンジンを利用できるようになります。

`Rails::Application`クラスは`railties/lib/rails/application.rb`ファイルで定義されており、その中で`bootstrap`、`railtie`、`finisher`イニシャライザをそれぞれ定義しています。
`bootstrap`イニシャライザは、ロガーの初期化などアプリケーションの準備を行います
最後に実行される`finisher`イニシャライザは、ミドルウェアスタックのビルドなどを行います。
`railtie`イニシャライザは`Rails::Application`自身で定義されており、`bootstrap`と`finishers`の間に実行されます。

NOTE: Railtieイニシャライザ全体と、[load_config_initializers](configuring.html#イニシャライザファイルを使う)イニシャライザのインスタンスやそれに関連する`config/initializers`以下のイニシャライザ設定ファイルを混同しないようにしましょう。

以上の処理が完了すると、制御は`Rack::Server`に移ります。

### Rack: lib/rack/server.rb

これまで進んだのは、以下の`app`メソッドが定義されている部分まででした。

```ruby
module Rack
  class Server
    def app
      @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
    end

    # ...

    private
      def build_app_and_options_from_config
        if !::File.exist? options[:config]
          abort "configuration #{options[:config]} not found"
        end

        app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
        @options.merge!(options) { |key, old, new| old }
        app
      end

      def build_app_from_string
        Rack::Builder.new_from_string(self.options[:builder])
      end

  end
end
```

このコードの`app`とは、Railsアプリケーション自身（ミドルウェアの一種）であり、ここから先は、提供されているすべてのミドルウェアをRackが呼び出します。

```ruby
module Rack
  class Server
    private
      def build_app(app)
        middleware[options[:environment]].reverse_each do |middleware|
          middleware = middleware.call(self) if middleware.respond_to?(:call)
          next unless middleware
          klass, *args = middleware
          app = klass.new(app, *args)
        end
        app
      end
  end
end
```

`Server#start`の最終行で、`build_app`が（`wrapped_app`によって）呼び出されていたことを思い出しましょう。最後に見たときのコードは以下のようになっていました。

```ruby
server.run wrapped_app, options, &blk
```

この`server.run`の実装は、アプリケーションで使うWebサーバーによって異なります。たとえばPumaを使う場合の`run`メソッドは以下のようになります。

```ruby
module Rack
  module Handler
    module Puma
      # ...
      def self.run(app, options = {})
        conf   = self.config(app, options)

        events = options.delete(:Silent) ? ::Puma::Events.strings : ::Puma::Events.stdio

        launcher = ::Puma::Launcher.new(conf, :events => events)

        yield launcher if block_given?
        begin
          launcher.run
        rescue Interrupt
          puts "* Gracefully stopping, waiting for requests to finish"
          launcher.stop
          puts "* Goodbye!"
        end
      end
      # ...
    end
  end
end
```

本ガイドではサーバーの設定自体については詳しく解説しませんが、Railsの初期化プロセスという長い旅はここで終点になります。

本ガイドで解説した高度な概要は、自分が開発したコードがいつどのように実行されるかを理解するためにも、そしてより優れたRails開発者になるためにも役に立つことでしょう。もっと詳しく知りたいのであれば、次のステップとしてRailsのソースコードそのものを読むのがおそらくベストです。
