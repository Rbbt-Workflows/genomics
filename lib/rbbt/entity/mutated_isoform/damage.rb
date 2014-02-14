require 'rbbt/workflow'
require 'rbbt/entity/mutated_isoform/domains'
require 'rbbt/mutation/mutation_assessor'
require 'rbbt/mutation/sift'

Workflow.require_workflow 'MutEval'

module MutatedIsoform
  DEFAULT_DAMAGE_PREDICTORS = [:sift, :mutation_assessor]

  property :truncated => :array2single do
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
        when position < sequence_length.to_f * 0.7
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

  property :damaged? => :array2single do |*args|
    begin
      methods, threshold = args
      threshold, methods = methods, nil if threshold.nil? and not Array === methods
      threshold     = 0.8 if threshold.nil?
      threshold = threshold.to_f
      damage_scores = self.damage_scores(methods)
      truncated     = self.truncated

      damage_scores.zip(truncated).collect{|damage, truncated| truncated or (not damage.nil? and damage > threshold) }
    end
  end

  property :snps_and_go_scores => :array2single do
    begin
      missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
      res = MutEval.job(:snps_and_go, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run
      res.chunked_values_at(self).collect{|v| (v.nil? or v["SNPSandGO Score"].nil? or v["SNPSandGO Score"].empty?) ? 
        nil : 
        (v["SNPSandGO Prediction"] == "Disease" ? 1.0 - (10.0 - v["SNPSandGO Score"].to_f) / 20 : 0 + (10.0 - v["SNPSandGO Score"].to_f) / 20)
      }
    rescue
      Log.warn $!.message
      [nil] * self.length
    end
  end

  property :polyphen_scores => :array2single do
    begin
      missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
      res = MutEval.job(:polyphen, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run
      res.chunked_values_at(self).collect{|v| (v.nil? or v["Polyphen Score"].nil? or v["Polyphen Score"].empty?) ? nil : v["Polyphen Score"].to_f / 10}
    rescue
      Log.warn $!.message
      [nil] * self.length
    end
  end

  #property :sift_scores => :array2single do
  #  begin
  #    missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
  #    res = MutEval.job(:sift, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run
  #    res.chunked_values_at(self).collect{|v| (v.nil? or v["SIFT Score"].nil? or v["SIFT Score"].empty?) ? nil : 1.0 - v["SIFT Score"].to_f}
  #  rescue
  #    Log.warn $!.message
  #    [nil] * self.length
  #  end
  #end

  #property :mutation_assessor_scores => :array2single do
  #  range = {nil => nil,
  #    ""  => nil,
  #    "neutral" => 0,
  #    "low" => 0.5,
  #    "medium" => 0.7,
  #    "high" => 1.0}

  #  begin
  #    missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
  #    MutEval.job(:mutation_assessor, "MutatedIsoforms (#{self.length})", :mutations => missense.sort, :organism => organism).run.chunked_values_at(self).collect{|v| (v.nil? or v["Mutation Assessor Prediction"].nil? or v["Mutation Assessor Prediction"].empty?) ? nil : range[v["Mutation Assessor Prediction"]]}
  #  rescue
  #    Log.warn $!.message
  #    [nil] * self.length
  #  end
  #end

  property :dbNSFP => :array2single do |*args|
    method = args.first || "all"
    missense = self.select{|mutation| mutation.consequence == "MISS-SENSE"}
    MutEval.job(:dbNSFP, "MutatedIsoforms (#{self.length})", :method => method, :mutations => missense.sort, :organism => organism).run.chunked_values_at(self).collect{|v| (v.nil? or v.first.nil?) ? nil : v.first.to_f }.collect{|v| v == -999 ? nil : v}
  end

  property :sift_scores => :array2single do
    dbNSFP :sift
  end

  property :mutation_assessor_scores => :array2single do
    dbNSFP :mutation_assessor
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
