require 'test/unit'
require 'tmpdir'
require 'html-proofer'
require_relative 'custom_checks'

class TestReferenceLinks < Test::Unit::TestCase
  def failures_for(body)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'index.html')
      File.write(path, "<html><body>#{body}</body></html>")

      proofer = HTMLProofer.check_file(path, checks: ['ReferenceLinks'], log_level: :fatal)
      proofer.process_files.flat_map { |result| result[:failures] }.map(&:description)
    end
  end

  def test_detect_unresolved_reference_links
    assert_equal 1, failures_for('<p>[PostgreSQLのベストプラクティス][]を参照</p>').size
    assert_equal 1, failures_for('<p>[RSSコンテンツ][RSS contents]を解析</p>').size
    assert_equal 1, failures_for('<p>以下のように[<code>extended_queries</code>][]も有効にする</p>').size
    assert_equal 1, failures_for('<p>[<em>強調</em>][]を参照</p>').size
  end

  def test_ignore_brackets_around_elements
    assert_empty failures_for('<p>[a]<a href="https://example.com">x</a>[b]</p>')
  end

  def test_ignore_resolved_links_and_code
    assert_empty failures_for('<p><a href="https://example.com">Changelog</a></p>')
    assert_empty failures_for('<p><code>params[:user][:address]</code></p>')
    assert_empty failures_for('<pre>form[address][city]</pre>')
  end
end
