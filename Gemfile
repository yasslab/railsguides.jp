source "https://rubygems.org"

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gemspec

gem "arel", github: "rails/arel"

# We need a newish Rake since Active Job sets its test tasks' descriptions.
gem "rake", ">= 11.1"
gem "thor", github: "erikhuda/thor"

# This needs to be with require false to ensure correct loading order, as it has to
# be loaded after loading the test library.
gem "mocha", "~> 0.14", require: false

gem "capybara", "~> 2.13"

gem "rack-cache", "~> 1.2"
gem "jquery-rails"
gem "coffee-rails"
gem "sass-rails", github: "rails/sass-rails", branch: "5-0-stable"
gem "turbolinks", "~> 5"

# require: false so bcrypt is loaded only when has_secure_password is used.
# This is to avoid Active Model (and by extension the entire framework)
# being dependent on a binary library.
gem "bcrypt", "~> 3.1.11", require: false

# This needs to be with require false to avoid it being automatically loaded by
# sprockets.
gem "uglifier", ">= 1.3.0", require: false

# Explicitly avoid 1.x that doesn't support Ruby 2.4+
gem "json", ">= 2.0.0"

gem "rubocop", ">= 0.47", require: false

gem "rb-inotify", github: "matthewd/rb-inotify", branch: "close-handling", require: false

group :doc do
  gem "sdoc", "> 1.0.0.rc1", "< 2.0"
  gem "redcarpet", "~> 3.2.3", platforms: :ruby
  gem "w3c_validators"
  gem "kindlerb", "~> 1.2.0"
end

# Active Support.
gem "dalli", ">= 2.2.1"
gem "listen", ">= 3.0.5", "< 3.2", require: false
gem "libxml-ruby", platforms: :ruby

# Action View. For testing Erubis handler deprecation.
gem "erubis", "~> 2.7.0", require: false

# for railties app_generator_test
gem "bootsnap", ">= 1.1.0", require: false

# Active Job.
group :job do
  gem "resque", require: false
  gem "resque-scheduler", require: false
  gem "sidekiq", require: false
  gem "sucker_punch", require: false
  gem "delayed_job", require: false
  gem "queue_classic", github: "QueueClassic/queue_classic", branch: "master", require: false, platforms: :ruby
  gem "sneakers", require: false
  gem "que", require: false
  gem "backburner", require: false
  #TODO: add qu after it support Rails 5.1
  # gem 'qu-rails', github: "bkeepers/qu", branch: "master", require: false
  gem "qu-redis", require: false
  gem "delayed_job_active_record", require: false
  gem "sequel", require: false
end

# Action Cable
group :cable do
  gem "puma", require: false

  gem "em-hiredis", require: false
  gem "hiredis", require: false
  gem "redis", require: false

  gem "websocket-client-simple", github: "matthewd/websocket-client-simple", branch: "close-race", require: false

  gem "blade", require: false, platforms: [:ruby]
  gem "blade-sauce_labs_plugin", require: false, platforms: [:ruby]
  gem "sprockets-export", require: false
end

# Add your own local bundler stuff.
local_gemfile = File.dirname(__FILE__) + "/.Gemfile"
instance_eval File.read local_gemfile if File.exist? local_gemfile

group :test do
  # FIX: Our test suite isn't ready to run in random order yet.
  gem "minitest", "< 5.3.4"

  platforms :mri do
    gem "stackprof"
    gem "byebug"
  end

  gem "benchmark-ips"

  # railsguides.jp test gems
  gem "rspec"
  gem "pry-byebug"
  gem "turnip"
  gem "wraith"
end

platforms :ruby, :mswin, :mswin64, :mingw, :x64_mingw do
  gem "nokogiri", ">= 1.6.8"

  # Needed for compiling the ActionDispatch::Journey parser.
  gem "racc", ">=1.4.6", require: false

  # FIXME: Remove this comment after Heroku support sqlite3 gem.
  # Active Record.
  # gem "sqlite3", "~> 1.3.6"

  group :db do
    gem "pg", ">= 0.18.0"
    gem "mysql2", ">= 0.4.4"
  end
end

platforms :jruby do
  if ENV["AR_JDBC"]
    gem "activerecord-jdbcsqlite3-adapter", github: "jruby/activerecord-jdbc-adapter", branch: "master"
    group :db do
      gem "activerecord-jdbcmysql-adapter", github: "jruby/activerecord-jdbc-adapter", branch: "master"
      gem "activerecord-jdbcpostgresql-adapter", github: "jruby/activerecord-jdbc-adapter", branch: "master"
    end
  else
    gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0"
    group :db do
      gem "activerecord-jdbcmysql-adapter", ">= 1.3.0"
      gem "activerecord-jdbcpostgresql-adapter", ">= 1.3.0"
    end
  end
end

platforms :rbx do
  # The rubysl-yaml gem doesn't ship with Psych by default as it needs
  # libyaml that isn't always available.
  gem "psych", "~> 2.0"
end

# Gems that are necessary for Active Record tests with Oracle.
if ENV["ORACLE_ENHANCED"]
  platforms :ruby do
    gem "ruby-oci8", "~> 2.2"
  end
  gem "activerecord-oracle_enhanced-adapter", github: "rsim/oracle-enhanced", branch: "master"
end

# A gem necessary for Active Record tests with IBM DB.
gem "ibm_db" if ENV["IBM_DB"]
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "wdm", ">= 0.1.0", platforms: [:mingw, :mswin, :x64_mingw, :mswin64]

# FIXME: Remove this comment after Heroku support ruby_25 platforms.
# platforms :ruby_25 do
#   gem "mathn"
# end

# Monitoring tools
gem "newrelic_rpm"

# SSL in Production
gem "acme_challenge"
gem "rack-rewrite", "~> 1.5.0"
# FIXME: Remove this fork after https://github.com/rack/rack-contrib/pull/129 is merged.
gem "rack-contrib", github: "bigcartel/rack-contrib", branch: "master"


# Set up Jekyll on Heroku
gem "jekyll"
gem "kramdown"
gem "rack-jekyll"
gem "puma"

# Testing links by hand
gem "html-proofer"

group :development do
  # Generate docset
  gem 'docset'
end
