module GenomicMutation

  property :chromosome => :array2single do
    self.clean_annotations.collect{|mut| mut.split(":")[0]}
  end

  property :position => :array2single do
    self.clean_annotations.collect{|mut| mut.split(":")[1].to_i}
  end

  property :base => :array2single do
    self.clean_annotations.collect{|mut| mut.split(":")[2]}
  end

  property :score => :array2single do
    self.clean_annotations.collect{|mut| mut.split(":")[3].to_f}
  end

  property :remove_score => :array2single do
    self.annotate(self.collect{|mut| mut.split(":")[0..2] * ":"})
  end

  property :noscore => :single2array do
    self.annotate self.clean_annotations.collect{|mut| mut.split(":")[0..2]}
  end

  property :reference => :array2single do
    job = Sequence.job(:reference, jobname, :organism => organism, :positions => self.clean_annotations.sort)
    job.clean if job.error?
    tsv = job.run
    tsv.chunked_values_at self
  end

  property :gene_strand_reference => :array2single do
    genes = self.genes
    gene_strand = Misc.process_to_hash(genes.compact.flatten){|list| list.any? ? list.strand : []}
    reverse = genes.collect{|list| not list.nil? and list.clean_annotations.select{|gene| gene_strand[gene].to_s == "-1" }.any? }
    forward = genes.collect{|list| not list.nil? and list.clean_annotations.select{|gene| gene_strand[gene].to_s == "1" }.any? }
    reference.zip(reverse, forward, base).collect{|reference,reverse, forward, base|
      case
      when (reverse and not forward)
        Misc::BASE2COMPLEMENT[reference]
      when (forward and not reverse)
        reference
      else
        base == reference ? Misc::BASE2COMPLEMENT[reference] : reference
      end
    }
  end

  property :bases_in_range => :single2array do |range|
    start = range.begin+position-1
    length = range.end - range.begin + 1
    File.open(Organism[organism]["chromosome_#{chromosome}"].find) do |f|
      f.seek start
      f.read length
    end
  end
end
