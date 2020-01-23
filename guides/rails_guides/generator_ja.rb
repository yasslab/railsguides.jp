require 'rails_guides/generator'
require 'rails_guides/helpers_ja'

require 'rails_guides/markdown_ja'

module RailsGuides
  class GeneratorJa < Generator
    def initialize(edge:, version:, all:, only:, kindle:, dash:, language:)
      @dash = dash

      super(
        edge:     edge,
        version:  version,
        all:      all,
        only:     only,
        kindle:   kindle,
        language: language
      )
    end

    def generate
      super
      generate_docset if dash?
    end

    private

    def dash?
      @dash
    end

    def generate_docset
      require 'rails_guides/dash'
      docset_name = ["ruby_on_rails_guides", @language, @version].compact.join(?_) + ".docset"
      Dash.generate(@output_dir, docset_name)
    end

    def initialize_dirs
      super
      @output_dir = "#@guides_dir/output/dash/#@language".sub(%r</$>, '') if dash?
    end

    def generate_guide(guide, output_file)
      output_path = output_path_for(output_file)
      puts "Generating #{guide} as #{output_file}"
      layout = @kindle ? 'kindle/layout' : 'layout'

      File.open(output_path, 'w') do |f|
        view = ActionView::Base.new(
          @source_dir,
          edge:     @edge,
          version:  @version,
          mobi:     "kindle/#{mobi}",
          language: @language
        )
        view.extend(HelpersJa)

        if guide =~ /\.(\w+)\.erb$/
          # Generate the special pages like the home.
          # Passing a template handler in the template name is deprecated. So pass the file name without the extension.
          result = view.render(layout: layout, formats: [$1], file: $`)
        else
          body = File.read(File.join(@source_dir, guide))
          body = body << references_md(guide) if references?(guide)
          result = RailsGuides::MarkdownJa.new(
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
      @yml ||= YAML.load_file(File.join(@source_dir, "references.yml"))
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
  end
end
