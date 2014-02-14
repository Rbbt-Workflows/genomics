require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/mutated_isoform/consequence'

class TestMutatedIsoformConsequence < Test::Unit::TestCase
  
  def test_consequences
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert_equal "SYNONYMOUS", template.annotate("ENSP000000001:A1A").consequence
    assert_equal "UTR", template.annotate("ENST000000001:UTR3").consequence
    assert_equal "UTR", template.annotate("ENST000000001:UTR5").consequence
    assert_equal "MISS-SENSE", template.annotate("ENSP000000001:A1V").consequence
    assert_equal "NONSENSE", template.annotate("ENSP000000001:A1*").consequence
    assert_equal "NOSTOP", template.annotate("ENSP000000001:*100V").consequence
    assert_equal "FRAMESHIFT", template.annotate("ENSP000000001:A1FrameShift").consequence
    assert_equal "INDEL", template.annotate("ENSP000000001:A1Indel").consequence
  end

  def test_synonymous
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert template.annotate("ENSP000000001:A1A").synonymous
    assert template.annotate("ENST000000001:UTR3").synonymous
    assert template.annotate("ENST000000001:UTR5").synonymous
    assert ! template.annotate("ENSP000000001:A1V").synonymous
    assert ! template.annotate("ENSP000000001:A1*").synonymous
    assert ! template.annotate("ENSP000000001:*100V").synonymous
    assert ! template.annotate("ENSP000000001:A1FrameShift").synonymous
    assert ! template.annotate("ENSP000000001:A1Indel").synonymous
  end

  def test_in_utr
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert ! template.annotate("ENSP000000001:A1A").in_utr
    assert  template.annotate("ENST000000001:UTR3").in_utr
    assert  template.annotate("ENST000000001:UTR5").in_utr
    assert ! template.annotate("ENSP000000001:A1V").in_utr
    assert ! template.annotate("ENSP000000001:A1*").in_utr
    assert ! template.annotate("ENSP000000001:*100V").in_utr
    assert ! template.annotate("ENSP000000001:A1FrameShift").in_utr
    assert ! template.annotate("ENSP000000001:A1Indel").in_utr
  end
  def test_nonsynonymous
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert ! template.annotate("ENSP000000001:A1A").non_synonymous
    assert ! template.annotate("ENST000000001:UTR3").non_synonymous
    assert ! template.annotate("ENST000000001:UTR5").non_synonymous
    assert template.annotate("ENSP000000001:A1V").non_synonymous
    assert template.annotate("ENSP000000001:A1*").non_synonymous
    assert template.annotate("ENSP000000001:*100V").non_synonymous
    assert template.annotate("ENSP000000001:A1FrameShift").non_synonymous
    assert template.annotate("ENSP000000001:A1Indel").non_synonymous
  end
end

