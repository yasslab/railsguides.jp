require 'html-proofer'

# Detect reference links (e.g. [text][] or [text][ref]) left unconverted
# because the reference name does not match any link definition.
# cf. https://github.com/yasslab/railsguides.jp/issues/1547
class ReferenceLinks < ::HTMLProofer::Check
  # The link text can be empty since <code> in [`foo`][] is removed
  UNRESOLVED_REFERENCE_LINK = /\[[^\[\]\n]*\]\[[^\[\]\n]*\]/

  def run
    # <code>, <pre> and <tt> are removed by HTML-Proofer before this check,
    # so join the text nodes split by them, e.g. "[" and "][]" in [`foo`][]
    @html.css('body *').each do |element|
      next if %w[script style].include?(element.name)

      text = element.children.select(&:text?).map(&:text).join
      text.scan(UNRESOLVED_REFERENCE_LINK) do |link|
        add_failure("Unresolved reference link: #{link} in \"#{element.text.strip[0, 80]}\"", line: element.line)
      end
    end
  end
end
