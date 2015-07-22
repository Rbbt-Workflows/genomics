$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'test/unit'
require 'rbbt/workflow'

Workflow.require_workflow "Genomics"

class TestClass < Test::Unit::TestCase
  def test_knowledge_base_gene_ages
    require 'rbbt/knowledge_base/Genomics'
    iii Genomics.knowledge_base.get_index(:gene_ages)
  end
end

