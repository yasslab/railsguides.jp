# -*- coding: utf-8 -*-
require 'redcarpet'
require 'coderay'
require 'nokogiri'
require "cgi"

module Dash
  extend self

  def generate(source_dir, output_dir, out_dir, logfile, debug: false)
    puts "Output Dir: #{output_dir}"
    @debug = debug
    @stylesheets = []
    html_body = ''

    docset_path = "#{output_dir}/#{out_dir}"
    FileUtils.rm_r(docset_path) if Dir.exists? docset_path
    @contents_dir = "#{docset_path}/Contents"
    @resources_dir = "#{@contents_dir}/Resources"
    @documents_dir = "#{@resources_dir}/Documents"

    FileUtils.mkdir_p @documents_dir
    build_info_plist
    initialize_sqlite
    copy_assets output_dir, @documents_dir

    output_dir = File.absolute_path(output_dir)
    Dir.chdir output_dir do
      Dir.glob("#{output_dir}/*.html").each do|file_path|
        next if file_path =~ /release_notes.html\z/
        next if File.basename(file_path) =~ /\A_/
        doc_name = File.basename(file_path).sub(".md", "")

        File.open(file_path) do |file|
          html = create_html_and_register_index(file, doc_name)
          File.write("#{@documents_dir}/#{doc_name}", html)
        end
      end
    end
  end

  def create_html_and_register_index(file, doc_name)
    title = ''
    html_body = file.read
    html_body.scan(/(<h[1-5]( [^>]+)?>\n?[[:space:]]*(.*?)<\/h([1-5])>)/m).each do |match|
      tag = match[0]
      name = ActionView::Base.full_sanitizer.sanitize(match[2]).delete("\n")
      puts "Index: #{name}"
      hash = Digest::MD5.hexdigest name

      # Add Anchor to Header Tag
      html_body.sub!(tag, %{<a name="#{hash}"></a>#{tag}})

      # Add Search Index
      title = index_name = CGI.unescapeHTML(name).gsub("'"){ "''" }
      sqlite %{INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{index_name}', 'Guide', '#{doc_name}##{hash}');}
    end
    # relative
    html_body.gsub!('src="/images/', 'src="./images/')
    html_body.gsub!('href="/"', 'src="./index.html"')
    html_body
    # Rremove Navigation and Header
    doc = Nokogiri::HTML.parse(html_body, nil, 'utf-8')
    doc.search("#topNav").remove
    doc.search("#header").remove
    html_body = doc.to_html
  end

  def copy_assets(source_dir, destination_dir)
    %w{images stylesheets}.each do |dir|
      src = "#{source_dir}/#{dir}"
      dst = "#{destination_dir}/#{dir}"
      FileUtils.rm_r dst if Dir.exists? dst
      FileUtils.cp_r src, dst

      if dir == 'stylesheets'
        Dir.glob("#{dst}/*").each do |stylesheet|
          next if stylesheet =~ /kindle.css\z/
          @stylesheets << File.basename(stylesheet)
        end
      end
    end
  end

  def initialize_sqlite
    @sqlite_db = "#{@resources_dir}/docSet.dsidx"
    sqlite "DROP TABLE IF EXISTS searchIndex;"
    sqlite "CREATE TABLE IF NOT EXISTS searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
    sqlite "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"
  end

  def sqlite(query)
    puts "[SQLite] #{query}" if @debug
    `sqlite3  #{@sqlite_db} "#{query}"`
  end

  def build_info_plist
    file = "#{@contents_dir}/Info.plist"
    File.delete if File.exists? file
    File.write(file, <<-HTML)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleIdentifier</key>
    <string>railsguidesjp</string>
    <key>CFBundleName</key>
    <string>Railsガイド</string>
    <key>DocSetPlatformFamily</key>
    <string>rails</string>
    <key>isDashDocset</key>
    <true/>
  </dict>
</plist>
    HTML
  end
end

