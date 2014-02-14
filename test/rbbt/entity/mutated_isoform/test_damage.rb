require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/mutated_isoform/consequence'

class TestMutatedIsoformConsequence < Test::Unit::TestCase
  
  def test_40_percent_truncated
    protein = Protein.setup("ENSP00000354718", "Ensembl Protein ID", "Hsa")


    sequence = protein.sequence
    position = sequence.length * 0.6
    ref = sequence[position]
    mutated_isoform = MutatedIsoform.setup([protein, ":", ref, position, "*"] * "", "Hsa")
    assert mutated_isoform.truncated
  end

  def test_20_percent_not_truncated
    protein = Protein.setup("ENSP00000354718", "Ensembl Protein ID", "Hsa")

    sequence = protein.sequence
    position = sequence.length * 0.9
    ref = sequence[position]
    mutated_isoform = MutatedIsoform.setup([protein, ":", ref, position, "*"] * "", "Hsa")
    assert ! mutated_isoform.truncated
  end
  
  def test_20_percent_but_domain_ablated
    protein = Protein.setup("ENSP00000419361", "Ensembl Protein ID", "Hsa")

    sequence = protein.sequence
    position = sequence.length * 0.9
    ref = sequence[position]
    mutated_isoform = MutatedIsoform.setup([protein, ":", ref, position, "*"] * "", "Hsa")
    assert mutated_isoform.ablated_domains
    assert mutated_isoform.truncated
  end
end

