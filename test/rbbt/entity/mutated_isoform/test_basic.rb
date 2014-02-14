require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/entity/mutated_isoform'
require 'rbbt/entity/mutated_isoform/basic'

class TestMutatedIsoformBasic < Test::Unit::TestCase
  
  def test_transcript
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert_equal nil, template.annotate("ENST000000001:UTR3").protein
    assert_equal nil, template.annotate("ENST000000001:UTR5").protein
  end
  def test_protein
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:A1A").protein
    assert_equal nil, template.annotate("ENST000000001:UTR3").protein
    assert_equal nil, template.annotate("ENST000000001:UTR5").protein
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:A1V").protein
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:A1*").protein
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:*100V").protein
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:A1FrameShift").protein
    assert_equal "ENSP000000001", template.annotate("ENSP000000001:A1Indel").protein
  end

  def test_position
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert_equal 1, template.annotate("ENSP000000001:A1A").position
    assert_equal nil, template.annotate("ENST000000001:UTR3").position
    assert_equal nil, template.annotate("ENST000000001:UTR5").position
    assert_equal 1, template.annotate("ENSP000000001:A1V").position
    assert_equal 1, template.annotate("ENSP000000001:A1*").position
    assert_equal 100, template.annotate("ENSP000000001:*100V").position
    assert_equal 1, template.annotate("ENSP000000001:A1FrameShift").position
    assert_equal 1, template.annotate("ENSP000000001:A1Indel").position
  end

  def test_change
    template = MutatedIsoform.setup("TEMPLATE", "Hsa")
    assert_equal "A1A", template.annotate("ENSP000000001:A1A").change
    assert_equal "UTR3", template.annotate("ENST000000001:UTR3").change
    assert_equal "UTR5", template.annotate("ENST000000001:UTR5").change
    assert_equal "A1V", template.annotate("ENSP000000001:A1V").change
    assert_equal "A1*", template.annotate("ENSP000000001:A1*").change
    assert_equal "*100V", template.annotate("ENSP000000001:*100V").change
    assert_equal "A1FrameShift", template.annotate("ENSP000000001:A1FrameShift").change
    assert_equal "A1Indel", template.annotate("ENSP000000001:A1Indel").change
  end
end

