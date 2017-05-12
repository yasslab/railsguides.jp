require_relative 'helpers'

module RailsGuides
  module HelpersJa
    include Helpers

    def documents_by_section
      @documents_by_section ||= YAML.load_file(File.expand_path("../../source/#@lang/documents.yaml", __FILE__))
    end

    def finished_documents(documents)
      # Enable this line when not like to display WIP documents
      #documents.reject { |document| document['work_in_progress'] }
      documents
    end
  end
end
