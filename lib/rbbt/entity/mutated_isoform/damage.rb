require 'rbbt/workflow'
#require 'rbbt/entity/mutated_isoform/domains'
#require 'rbbt/mutation/mutation_assessor'
#require 'rbbt/mutation/sift'

Workflow.require_workflow 'DbNSFP'

module MutatedIsoform
  DEFAULT_DAMAGE_PREDICTORS = [:sift, :mutation_assessor]

  property :truncated => :array2single do
    length_threshold = 1
    begin
      proteins = self.protein.compact.flatten
      protein2sequence_length = Misc.process_to_hash(proteins){|list| proteins.any? ? proteins.sequence_length : []}

      self.collect do |isoform_mutation|

        next if isoform_mutation.consequence != "FRAMESHIFT" and isoform_mutation.consequence != "NONSENSE"
        protein  = isoform_mutation.protein
        position = isoform_mutation.position
        sequence_length = protein2sequence_length[protein]

        case
        when (sequence_length.nil? or position.nil?)
          nil
        when position <= sequence_length.to_f * length_threshold
          true
        when (isoform_mutation.ablated_domains.any?)
          true
        else
          false
        end
      end
    end
  end

  property :damage_scores => :array2single do |*args|
    begin
      methods = args.first
      methods = MutatedIsoform::DEFAULT_DAMAGE_PREDICTORS if methods.nil?
      methods = [methods] unless Array === methods
      values = methods.collect{|method|
        case method.to_sym
        when :sift
          sift_scores
        when :mutation_assessor
          mutation_assessor_scores
        when :polyphen
          polyphen_scores
        when :snps_and_go
          snps_and_go_scores
        when :transFIC
          transFIC_scores(:mutation_assessor)
        else
          raise "Unknown predictive method: #{ method }"
        end
      }
      if values.compact.empty?
        return [nil] * self.length
      else
        scores = values.shift
        scores = scores.zip(*values)

        scores.collect{|p|
          p = p.compact
          if p.empty?
            nil
          else
            p.inject(0.0){|acc, e| acc += e} / p.length
          end
        }
      end
    end
  end

  property :dbNSFP => :array2single do 
    missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
    DbNSFP.job(:score, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run
  end

  property :dbNSFP_field => :array2single do |field|
    if dbNSFP.size == 0
      [nil] * self.length
    else
      begin
        [nil] * self.length
        dbNSFP.slice(field).chunked_values_at(self).collect{|list| v = list ? list.first : nil;  (v.nil? or v == -999 or v == "-999") ? nil : v.to_f }
      rescue
        Log.warn "Error getting dbNSFP field #{field}"
        [nil] * self.length
      end
    end
  end

  property :dbnsfp_radialSVM_score => :array2single do |*args|
    field = "RadialSVM_score"
    dbNSFP_field(field)
  end

  property :dbnsfp_MetaSVM_score => :array2single do |*args|
    field = "MetaSVM_score"
    dbNSFP_field(field)
  end

  property :damaged? => :array2single do 
    truncated.zip(dbnsfp_MetaSVM_score.collect{|v| v and v > 0 }).collect{|t,d| t or d}
  end

  property :sift_scores => :array2single do
    dbNSFP_field "SIFT_score"
  end

  property :mutation_assessor_scores => :array2single do
    dbNSFP_field "MutationAssessor_score"
  end

  property :transFIC_scores => :array2single do |*args|
    method = args.first || :mutation_assessor
    range = {nil => nil,
      ""  => nil,
      "low_impact" => 0,
      "medium_impact" => 0.7,
      "high_impact" => 1.0}
    field_names = {
    }
    begin
      missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}

      field_name = {
        :mutation_assessor => "maTransfic",
      }[method.to_sym]

      MutEval.job(:transFIC, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run.chunked_values_at(self).collect{|v| (v.nil? or v[field_name].nil? or v[field_name].empty?) ? nil : v[field_name].to_f}
    rescue
      Log.warn $!.message
      [nil] * self.length
    end
  end
end
