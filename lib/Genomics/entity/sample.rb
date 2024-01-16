module Sample

  property :mutations => :single do
    mutations = self.genomic_mutations
    GenomicMutation.setup(mutations, self, organism, watson)
    mutations.extend AnnotatedArray
    mutations
  end

  property :overlapping_genes do
    self.gene_mutation_status.select(:overlapping).keys
  end

  property :get_genes => :single do |type|
    genes = case type.to_sym
            when :mutated
              self.gene_mutation_status.select(:overlapping => "true").keys
            when :altered, :affected
              self.gene_mutation_status.select(:affected => "true").keys
            when :damaged
              self.gene_mutation_status.select(:damaged_mutated_isoform => "true").keys
            when :broken
              self.gene_mutation_status.select(:broken => "true").keys
            when :lost
              if self.has_cnv?
                tsv = self.gene_cnv_status
                lost = tsv.select("CNV status" => "loss").keys
                lost.concat tsv.select("CNV status" => "complete_loss").keys
                lost
              else
                []
              end
            when :completly_lost
                if self.has_cnv?
                  self.gene_cnv_status.select("CNV status" => "complete_loss").keys
                else
                  []
                end
              when :gained
                if self.has_cnv?
                  tsv = self.gene_cnv_status
                  gained = tsv.select("CNV status" => "gain").keys
                  gained.concat tsv.select("CNV status" => "big_gain").keys
                  gained
                else
                  []
                end
              when :big_gain
                if self.has_cnv?
                  self.gene_cnv_status.select("CNV status" => "big_gain").keys
                else
                  []
                end
              when :LOH
                if self.has_cnv?
                  self.gene_cnv_status.select("CNV status" => "LOH").keys
                else
                  []
                end
              else
                begin
                  self.gene_mutation_status.select(type.to_s => "true").keys
                rescue
                  raise "Cannot understand #{ type }"
                end
              end
      Gene.setup(genes.dup, "Ensembl Gene ID", organism).extend AnnotatedArray
    end
  end
