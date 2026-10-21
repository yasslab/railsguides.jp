require 'html-proofer'

# Detect reference links (e.g. [text][] or [text][ref]) left unconverted
# because the reference name does not match any link definition.
# cf. https://github.com/yasslab/railsguides.jp/issues/1547
class ReferenceLinks < ::HTMLProofer::Check
  # Placeholder for child elements such as <a> and <em>, so that the link text
  # can contain them as in [*foo*][] while "[a]<a>x</a>[b]" is not detected
  ELEMENT = "\u0000"

  # The link text can be empty since <code> in [`foo`][] is removed
  UNRESOLVED_REFERENCE_LINK = /\[[^\[\]\n]*\]\[[^\[\]\n]*\]/

  def run
    # <code>, <pre> and <tt> are removed by HTML-Proofer before this check,
    # so join the text nodes split by them, e.g. "[" and "][]" in [`foo`][]
    @html.css('body *').each do |element|
      next if %w[script style].include?(element.name)

      text = element.children.map { |child| child.text? ? child.text : ELEMENT }.join
      text.scan(UNRESOLVED_REFERENCE_LINK) do |link|
        add_failure("Unresolved reference link: #{link.delete(ELEMENT)} in \"#{element.text.gsub(/\s+/, ' ').strip[0, 80]}\"", line: element.line)
      end
    end
  end
end
