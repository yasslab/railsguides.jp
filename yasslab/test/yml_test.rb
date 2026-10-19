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

  def test_documents_have_no_duplicate_keys
    # Check before loading, since duplicate keys are silently overwritten.
    Psych.parse_file(YAML_DOCUMENTS).each do |node|
      next unless node.is_a?(Psych::Nodes::Mapping)

      keys = []
      node.children.each_slice(2) do |key, _value|
        assert_not_include keys, key.value,
          "#{YAML_DOCUMENTS}:#{key.start_line + 1}: duplicate key #{key.value.inspect}"
        keys << key.value
      end
    end
  end
end
