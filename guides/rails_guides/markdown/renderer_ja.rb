require "rails_guides/markdown/renderer"

module RailsGuides
  class Markdown
    class RendererJa < Renderer
      def paragraph(text)
        begin
          if text =~ %r{^NOTE:\s+定義ファイルの場所は<code>(.*?)</code>です。?$}
            %(<div class="note"><p>定義ファイルの場所は <code><a href="#{github_file_url($1)}">#{$1}</a></code> です。</p></div>)
          elsif text =~ /^(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:]/
            convert_notes(text)
          elsif text.include?("DO NOT READ THIS FILE ON GITHUB")
          elsif text =~ /^\[<sup>(\d+)\]:<\/sup> (.+)$/
            linkback = %(<a href="#footnote-#{$1}-ref"><sup>#{$1}</sup></a>)
            %(<p class="footnote" id="footnote-#{$1}">#{linkback} #{$2}</p>)
          else
            text = convert_footnotes(text)
            "<p>#{text}</p>"
          end
        rescue => e
          puts
          puts "=== Hint: Check this pagraph ======"
          puts text
          puts "==================================="
          puts
          raise e
        end
      end
    end
  end
end
