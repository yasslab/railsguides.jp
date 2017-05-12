require_relative 'markdown'

module RailsGuides
  class MarkdownJa < Markdown
    def render(body)
      @raw_body = body
      extract_raw_header_and_body
      extract_raw_body_and_references
      generate_header
      generate_title
      generate_body
      generate_references
      generate_structure
      generate_index
      render_page
    end
  end
end
