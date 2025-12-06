require 'test/unit'
require 'psych'

class TestYaml < Test::Unit::TestCase
  YAML_DOCUMENTS  = './guides/source/ja/documents.yaml'
  YAML_REFERENCES = './guides/source/ja/references.yml'

  def test_yaml_files
    assert_equal File.exist?(YAML_DOCUMENTS),  true
    assert_equal File.exist?(YAML_REFERENCES), true
  end

  def test_load_yaml
    assert_nothing_raised do
      Psych.load_file YAML_DOCUMENTS
      Psych.load_file YAML_REFERENCES
    end
  end
end
