require_relative "generator"

module RailsGuides
  class GeneratorJa < Generator
    def set_flags_from_environment
      super
      @dash = ENV['DASH'] == '1'
    end
  end
end
