require "rails_guides/markdown"
require "rails_guides/markdown/renderer_ja"

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

      def engine
        @engine ||= Redcarpet::Markdown.new(RendererJa,
          no_intra_emphasis: true,
          fenced_code_blocks: true,
          autolink: true,
          strikethrough: true,
          superscript: true,
          tables: true
        )
      end

      def extract_raw_body_and_references
        if @raw_body =~ /^references\-{40,}$/
          @raw_body, _, @raw_references = @raw_body.partition(/^references\-{40,}$/).map(&:strip)
        end
      end

      def generate_references
        @references = engine.render(@raw_references).html_safe if @raw_references
      end

      def generate_index
        if @headings_for_index.present?
          raw_index = ""
          @headings_for_index.each do |level, node, label|
            if level == 1
              raw_index += "1. [#{label}](##{node[:id]})\n"
            elsif level == 2
              raw_index += "    * [#{label}](##{node[:id]})\n"
            end
          end

          @index = Nokogiri::HTML.fragment(engine.render(raw_index)).tap do |doc|
            doc.at("ol")[:class] = "chapters"
          end.to_html

          @index = <<-INDEX.html_safe
          <div id="subCol">
            <h3 class="chapter">目次</h3>
            #{@index}
            <aside id="toppage">
              <div>
                <a href="https://railsguides.jp/ebook"><img src="/images/bnr-sidebar-ebook.png" alt="Railsガイド電子書籍版" class="bnr-proplan" /></a>
                <!--<a href="https://railsguides.jp/ebook"><img src="images/bnr-pro-plan.jpg" alt="RailsガイドProプラン" class="bnr-proplan" /></a>-->
              </div>

              <div style="margin-bottom: 10px;">
                <a href="https://twitter.com/search?f=tweets&q=%20%23Rails%E3%82%AC%E3%82%A4%E3%83%89&src=typd&lang=ja" target="_blank" title="twitterへのリンク" rel="noopener"><img src="images/btn-twitter.png" alt="みんなのつぶやき Railsガイド" /></a>
              </div>
              <ol class="snsb" style="margin-left: 0; margin-right: 0;">
                <li><a class="twitter-share-button" href="https://twitter.com/intent/tweet" data-hashtags="Railsガイド" data-via="RailsGuidesJP" data-related="RailsGuidesJP,YassLab" data-size="large" lang="ja"></a></li>
                <li style="margin-left: 6px;"><a class="github-button" href="https://github.com/yasslab/railsguides.jp" data-size="large" data-show-count="true" aria-label="Star yasslab/railsguides.jp on GitHub">Star</a></li>
              </ol>
            </aside>
          </div>
          INDEX
        end
      end

      def generate_title
        if heading = Nokogiri::HTML.fragment(@header).at(:h2)
          @title = "#{heading.text} - Railsガイド".html_safe
        else
          @title = "Ruby on Rails ガイド：体系的に Rails を学ぼう"
        end
      end

      def render_page
        @view.content_for(:references) { @references }
        super
      end
  end
end
