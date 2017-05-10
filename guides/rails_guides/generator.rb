require "set"
require "fileutils"

require "active_support/core_ext/string/output_safety"
require "active_support/core_ext/object/blank"
require "action_controller"
require "action_view"

require "rails_guides/markdown"
require "rails_guides/indexer"
require "rails_guides/helpers"
require "rails_guides/levenshtein"

module RailsGuides
  class Generator
    GUIDES_RE = /\.(?:erb|md)\z/

    def initialize(edge:, version:, all:, only:, kindle:, language:)
      set_flags_from_environment

      @edge     = edge
      @version  = version || 'local'
      @all      = all
      @only     = only
      @kindle   = kindle
      @language = language

      if @kindle
        check_for_kindlegen
        register_kindle_mime_types
      end

      initialize_dirs
      create_output_dir_if_needed
      initialize_markdown_renderer
    end

    def set_flags_from_environment
      @warnings = ENV['WARNINGS'] == '1'
      @dash     = ENV['DASH']     == '1'
    end

    def generate
      generate_guides
      copy_assets
      generate_mobi if @kindle
      generate_docset if @dash
    end

    private

      def register_kindle_mime_types
        Mime::Type.register_alias("application/xml", :opf, %w(opf))
        Mime::Type.register_alias("application/xml", :ncx, %w(ncx))
      end

      def check_for_kindlegen
        if `which kindlegen`.blank?
          raise "Can't create a kindle version without `kindlegen`."
        end
      end

      def generate_mobi
        require "rails_guides/kindle"
        out = "#{@output_dir}/kindlegen.out"
        Kindle.generate(@output_dir, mobi, out)
        puts "(kindlegen log at #{out})."
      end

      def generate_docset
        require 'rails_guides/dash'
        out = "#{@output_dir}/docset.out"
        Dash.generate @source_dir, @output_dir,
          "ruby_on_rails_guides_#@version%s.docset" % (@language.present? ? ".#@language" : ''),
          out
        puts "(docset generate log at #{out})."
      end

      def mobi
        mobi  = "ruby_on_rails_guides_#{@version || @edge[0, 7]}"
        mobi += ".#{@language}" if @language
        mobi += ".mobi"
      end

      def initialize_dirs
        @guides_dir = File.expand_path("..", __dir__)
        @source_dir = "#@guides_dir/source/#@language"

        @output_dir = if @kindle
          "#@guides_dir/output/kindle/#@language"
        elsif @dash
          "#@guides_dir/output/dash/#@language"
        else
          "#@guides_dir/output/#@language"
        end.sub(%r</$>, '')
      end

      def create_output_dir_if_needed
        FileUtils.mkdir_p(@output_dir)
      end

      def initialize_markdown_renderer
        Markdown::Renderer.edge    = @edge
        Markdown::Renderer.version = @version
      end

      def generate_guides
        guides_to_generate.each do |guide|
          output_file = output_file_for(guide)
          generate_guide(guide, output_file) if generate?(guide, output_file)
        end
      end

      def guides_to_generate
        guides = Dir.entries(@source_dir).grep(GUIDES_RE)

        if @kindle
          Dir.entries("#{@source_dir}/kindle").grep(GUIDES_RE).map do |entry|
            next if entry == "KINDLE.md"
            guides << "kindle/#{entry}"
          end
        end

        @only ? select_only(guides) : guides
      end

      def select_only(guides)
        prefixes = @only.split(",").map(&:strip)
        guides.select do |guide|
          guide.start_with?("kindle", *prefixes)
        end
      end

      def copy_assets
        FileUtils.cp_r(Dir.glob("#{@guides_dir}/assets/*"), @output_dir)
      end

      def output_file_for(guide)
        if guide.end_with?(".md")
          guide.sub(/md\z/, "html")
        else
          guide.sub(/\.erb\z/, "")
        end
      end

      def output_path_for(output_file)
        File.join(@output_dir, File.basename(output_file))
      end

      def generate?(source_file, output_file)
        fin  = File.join(@source_dir, source_file)
        fout = output_path_for(output_file)
        @all || !File.exist?(fout) || File.mtime(fout) < File.mtime(fin)
      end

      def generate_guide(guide, output_file)
        output_path = output_path_for(output_file)
        puts "Generating #{guide} as #{output_file}"
        layout = @kindle ? "kindle/layout" : "layout"

        File.open(output_path, "w") do |f|
          view = ActionView::Base.new(
            @source_dir,
            edge:     @edge,
            version:  @version,
            mobi:     "kindle/#{mobi}",
            language: @language
          )
          view.extend(Helpers)

          if guide =~ /\.(\w+)\.erb$/
            # Generate the special pages like the home.
            # Passing a template handler in the template name is deprecated. So pass the file name without the extension.
            result = view.render(layout: layout, formats: [$1], file: $`)
          else
            body = File.read("#{@source_dir}/#{guide}")
            body = body << references_md(guide) if references?(guide)
            result = RailsGuides::Markdown.new(
              view:    view,
              layout:  layout,
              edge:    @edge,
              version: @version
            ).render(body)

            warn_about_broken_links(result) if @warnings
          end

          f.write(result)
        end
      end

      def yml
        @yml ||= YAML.load(File.read(File.join(@source_dir, "references.yml")))
      end

      def references?(guide)
        yml[guide.sub(".md", "")]
      end

      def references_md(guide)
        md = <<-MD


参考資料
---------

references#{"-" * 80}
        MD
        yml[guide.sub(".md", "")].each_with_object(md) do |link, str|
          str << "* [#{link['title']}](#{link['url']})\n"
        end
      end

      def warn_about_broken_links(html)
        anchors = extract_anchors(html)
        check_fragment_identifiers(html, anchors)
      end

      def extract_anchors(html)
        # Markdown generates headers with IDs computed from titles.
        anchors = Set.new
        html.scan(/<h\d\s+id="([^"]+)/).flatten.each do |anchor|
          if anchors.member?(anchor)
            puts "*** DUPLICATE ID: #{anchor}, please make sure that there're no headings with the same name at the same level."
          else
            anchors << anchor
          end
        end

        # Footnotes.
        anchors += Set.new(html.scan(/<p\s+class="footnote"\s+id="([^"]+)/).flatten)
        anchors += Set.new(html.scan(/<sup\s+class="footnote"\s+id="([^"]+)/).flatten)
        anchors
      end

      def check_fragment_identifiers(html, anchors)
        html.scan(/<a\s+href="#([^"]+)/).flatten.each do |fragment_identifier|
          next if fragment_identifier == "mainCol" # in layout, jumps to some DIV
          unless anchors.member?(fragment_identifier)
            guess = anchors.min { |a, b|
              Levenshtein.distance(fragment_identifier, a) <=> Levenshtein.distance(fragment_identifier, b)
            }
            puts "*** BROKEN LINK: ##{fragment_identifier}, perhaps you meant ##{guess}."
          end
        end
      end
  end
end
