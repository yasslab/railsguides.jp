#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

Dir.glob(["./source/ja/*.md", "./source/ja/*.yaml"]) do |filename|
  text = File.read(filename)
  puts "\tReplace: #{filename} ..."

  # Global replacement
  unless %w(release_notes upgrading_ruby_on_rails).any? { |s| filename.include? s }
    text.gsub! "bin/rake", "bin/rails"
  end

  # Chapter-specific replacement
  case filename.split('/').last
  when 'active_record_basics.md'
    text.gsub! "rake", "bin/rails"
  when 'active_record_migrations.md'
    text.gsub! "rake", "bin/rails"
  when 'asset_pipeline.md'
    text.gsub! "rakeタスク", "タスク"
    text.gsub! "rake", "bin/rails"
  when 'configuring.md'
    text.gsub! "rakeタスク", "タスク"
    text.gsub! "rake", "bin/rails"
  when 'engines.md'
    text.gsub! "rake", "bin/rails"
  when 'getting_started.md'
    text.gsub! "rakeコマンド", "コマンド"
    text.gsub! "rake", "bin/rails"
  when 'rails_application_templates.md'
    text.gsub! "rails:template", "app:template"
  when 'testing.md'
    text.gsub! "rakeタスク", "タスク"
  end

  File.write(filename, text)
end

