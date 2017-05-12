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

    private

      def dom_id(nodes)
        dom_id = dom_id_text(nodes.last.text)

        # Fix duplicate node by prefix with its parent node
        if @node_ids[dom_id]
          if @node_ids[dom_id].size > 1
            duplicate_nodes = @node_ids.delete(dom_id)
            new_node_id = "#{duplicate_nodes[-2][:id]}-#{duplicate_nodes.last[:id]}"
            duplicate_nodes.last[:id] = new_node_id

            # Update <a> tag href for self
            duplicate_nodes.last.children.each do |child|
              duplicate_nodes.last.children.first[:href] = "##{new_node_id}" if child.name == "a"
            end

            @node_ids[new_node_id] = duplicate_nodes
          end

          dom_id = "#{nodes[-2][:id]}-#{dom_id}"
        end

        @node_ids[dom_id] = nodes
        dom_id
      end

      def extract_raw_body_and_references
        if @raw_body =~ /^references\-{40,}$/
          @raw_body, _, @raw_references = @raw_body.partition(/^references\-{40,}$/).map(&:strip)
        end
      end

      def generate_references
        @references = engine.render(@raw_references).html_safe if @raw_references
      end

      def generate_structure
        @headings_for_index = []
        if @body.present?
          @body = Nokogiri::HTML.fragment(@body).tap do |doc|
            hierarchy = []

            doc.children.each do |node|
              if node.name =~ /^h[3-6]$/
                case node.name
                  when 'h3'
                    hierarchy = [node]
                    @headings_for_index << [1, node, node.inner_html]
                  when 'h4'
                    hierarchy = hierarchy[0, 1] + [node]
                    @headings_for_index << [2, node, node.inner_html]
                  when 'h5'
                    hierarchy = hierarchy[0, 2] + [node]
                  when 'h6'
                    hierarchy = hierarchy[0, 3] + [node]
                end

                node[:id] = dom_id(hierarchy)
                node.inner_html = "<a>#{node_index(hierarchy)} #{node.inner_html}</a>"
                node.children.first[:href] = "##{node[:id]}"
              end
            end
          end.to_html
        end
      end
  end
end
