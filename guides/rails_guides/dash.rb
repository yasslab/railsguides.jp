# -*- coding: utf-8 -*-
require 'nokogiri'
require 'cgi'
require 'docset'
require 'digest/md5'

class Dash < Struct.new(:output_dir, :docset_filename)
  class << self
    def generate(output_dir, docset_filename)
      new(output_dir, docset_filename).generate
    end
  end

  def initialize(*)
    super
    self.output_dir = File.absolute_path(output_dir)
  end

  def generate
    puts "Output Dir: #{output_dir}"

    clean_docset

    docset = Docset::Base.new(docset_path)
    docset.add_plist(plist)
    %w(images stylesheets).each do |dir|
      docset.add_document(File.join(output_dir, dir))
    end

    each_file_paths do |file_path|
      create_html_and_register_index(docset, file_path)
    end
  end

  private

  def create_html_and_register_index(docset, html_path)
    doc_name = File.basename(html_path)
    html_body = File.read(html_path)
    html_body.scan(/(<h[1-5]( [^>]+)?>(.*?)<\/h([1-5])>)/).each do |match|
      tag = match[0]
      name = ActionView::Base.full_sanitizer.sanitize(match[2])
      puts "Index: #{name}"
      hash = Digest::MD5.hexdigest name

      # Add Anchor to Header Tag
      html_body.sub!(tag, %{<a name="#{hash}"></a>#{tag}})

      # Add Search Index
      docset.add_index(CGI.unescapeHTML(name), 'Guide', "#{doc_name}##{hash}")
    end
    # relative
    html_body.gsub!('src="/images/', 'src="./images/')
    html_body.gsub!('href="/"', 'src="./index.html"')

    # Remove Navigation and Header
    doc = Nokogiri::HTML.parse(html_body, nil, 'utf-8')
    doc.search("#topNav").remove
    doc.search("#header").remove

    docset.write_document(doc_name, doc.to_html)
  end

  def clean_docset
    return unless Dir.exist?(docset_path)
    FileUtils.rm_r(docset_path)
  end

  def docset_path
    File.join(output_dir, docset_filename)
  end

  def each_file_paths
    pattern = File.join(output_dir, '*.html')
    Dir.glob(pattern).each do|file_path|
      next if file_path =~ /release_notes.html\z/
      next if File.basename(file_path) =~ /\A_/
      yield file_path
    end
  end

  def plist
    Docset::Plist.new(
      id: 'railsguidesjp',
      name: 'Railsガイド',
      family: 'rails',
      js: false
    )
  end
end
