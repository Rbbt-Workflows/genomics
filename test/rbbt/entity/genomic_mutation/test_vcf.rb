require File.join(File.expand_path(File.dirname(__FILE__)), '../../..', 'test_helper.rb')
require 'rbbt/entity/genomic_mutation'
require 'rbbt/entity/genomic_mutation/vcf'

class TestGenomicMutationVCF < Test::Unit::TestCase

  def vcf_test_file
    Rbbt.root.test.data["test.vcf"].find(:lib)
  end
  
  def test_vcf_headers
    header_lines = GenomicMutation::VCF.header_lines vcf_test_file.open
    assert_equal "#CHROM", header_lines.last.split("\t").first

    info, line = GenomicMutation::VCF.header vcf_test_file.open
    assert_equal "#CHROM", line.split("\t").first
    assert info.include? "INFO"
    assert info.include? "FORMAT"
  end

  def test_vcf_open
    tsv = GenomicMutation::VCF.open(vcf_test_file)
    assert tsv.fields.include? "188011011B:GT"
    assert_equal "1/1", tsv["10:5865947:+AAAAA"]["188011011B:GT"] 
  end

  def test_vcf_open_stream
    stream = GenomicMutation::VCF.open_stream(vcf_test_file)
    tsv = TSV.open(stream)
    assert tsv.fields.include? "188011011B:GL"
    assert_equal "1/1", tsv["10:5865947:+AAAAA"]["188011011B:GT"] 
  end


end

