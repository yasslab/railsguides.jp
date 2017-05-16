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

      def generate_index
        if @headings_for_index.present?
          raw_index = ''
          @headings_for_index.each do |level, node, label|
            if level == 1
              raw_index += "1. [#{label}](##{node[:id]})\n"
            elsif level == 2
              raw_index += "    * [#{label}](##{node[:id]})\n"
            end
          end

          @index = Nokogiri::HTML.fragment(engine.render(raw_index)).tap do |doc|
            doc.at('ol')[:class] = 'chapters'
          end.to_html

          @index = <<-INDEX.html_safe
            <div id="subCol">
              <h3 class="chapter"><img src="images/chapters_icon.gif" alt="" />目次</h3>
              #{@index}
            </div>
          INDEX
        end
      end

      def generate_title
        if heading = Nokogiri::HTML.fragment(@header).at(:h2)
          @title = "#{heading.text} | Rails ガイド".html_safe
        else
          @title = "Ruby on Rails ガイド：体系的に Rails を学ぼう"
        end
      end

      def render_page
        @view.content_for(:header_section) { @header }
        @view.content_for(:page_title) { @title }
        @view.content_for(:index_section) { @index }
        @view.content_for(:references) { @references }
        @view.render(:layout => @layout, :text => @body)
      end
  end
end
