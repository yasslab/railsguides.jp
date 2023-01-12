require 'test/unit'
require 'psych'

class TestYaml < Test::Unit::TestCase
  def test_exists_documents_yaml
    assert_equal(File.exists?('./guides/source/ja/documents.yaml'), true)
  end

  def test_load_yaml
    assert_nothing_raised do
      Psych.load_file('./guides/source/ja/documents.yaml')
    end
  end
end
