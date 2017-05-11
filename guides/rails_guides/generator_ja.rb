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
  end
end
