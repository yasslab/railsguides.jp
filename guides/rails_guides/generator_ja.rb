require_relative "generator"

module RailsGuides
  class GeneratorJa < Generator
    def set_flags_from_environment
      super
      @dash = ENV['DASH'] == '1'
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
      out = "#{output_dir}/docset.out"
      Dash.generate @source_dir, output_dir,
                    "ruby_on_rails_guides_#@version%s.docset" % (@lang.present? ? ".#@lang" : ''),
                    out
      puts "(docset generate log at #{out})."
    end

    def initialize_dirs(output)
      super
      @output_dir = "#@guides_dir/output/dash/#@lang".sub(%r</$>, '') if dash?
    end

    def generate_guide(guide, output_file)
      output_path = output_path_for(output_file)
      puts "Generating #{guide} as #{output_file}"
      layout = kindle? ? 'kindle/layout' : 'layout'

      File.open(output_path, 'w') do |f|
        view = ActionView::Base.new(source_dir, :edge => @edge, :version => @version, :mobi => "kindle/#{mobi}", :lang => @lang)
        view.extend(Helpers)

        if guide =~ /\.(\w+)\.erb$/
          # Generate the special pages like the home.
          # Passing a template handler in the template name is deprecated. So pass the file name without the extension.
          result = view.render(:layout => layout, :formats => [$1], :file => $`)
        else
          body = File.read(File.join(source_dir, guide))
          body = body << references_md(guide) if references?(guide)
          result = RailsGuides::Markdown.new(view, layout).render(body)

          warn_about_broken_links(result) if @warnings
        end

        f.write(result)
      end
    end

    def yml
      @yml ||= YAML.load_file(File.join(source_dir, "references.yml"))
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
