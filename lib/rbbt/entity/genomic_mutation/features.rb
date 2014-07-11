module GenomicMutation

  property :genes => :array2single do
    genes_tsv = Sequence.job(:genes, jobname, :organism => organism, :positions => self.clean_annotations).run
    genes_tsv.unnamed = true
    genes = nil
    genes = genes_tsv.chunked_values_at self
    Gene.setup(genes, "Ensembl Gene ID", organism)
    genes
  end

  property :affected_exons  => :array2single do
    Sequence.job(:exons_at_genomic_positions, jobname, :organism => organism, :positions => self.clean_annotations).run.chunked_values_at self
  end

  property :coding? => :array2single do
    Sequence.job(:exons_at_genomic_positions, jobname, :organism => organism, :positions => self.clean_annotations).run.
      chunked_values_at(self).
      collect{|exons| 
        GenomicMutation.transcripts_for_exon_index(organism).chunked_values_at(exons).compact.flatten.any?
      }
  end

  property :affected_transcripts  => :array2single do
    exon2transcript_index = GenomicMutation.transcripts_for_exon_index(organism)
    transcripts = affected_exons.collect{|exons|
      exons = [] if exons.nil?
      exons.empty? ? 
        [] : exon2transcript_index.chunked_values_at(exons).flatten
    }
    Transcript.setup(transcripts, "Ensembl Transcript ID", organism)
  end

  property :mutated_isoforms => :array2single do
    res = Sequence.job(:mutated_isoforms_fast, jobname, :watson => watson, :organism => organism, :mutations => Annotated.purge(self)).run.chunked_values_at(self)
    MutatedIsoform.setup(res, organism)
    res.extend AnnotatedArray
    res
  end

  property :exon_junctions => :array do
    Sequence.job(:exon_junctions, jobname, :organism => organism, :positions => self.clean_annotations).run.
      tap{|t| t.unnamed = true}.
      chunked_values_at(self)
  end

  property :offset_in_genes => :array2single do
    gene2chr_start = Misc.process_to_hash(genes.flatten){|list| list.chr_start}
    position.zip(genes).collect{|position, list|
      list.collect{|gene|
        next if not gene2chr_start.include? gene
        [gene, position.to_i - gene2chr_start[gene]] * ":"
      }.compact
    }
  end

  property :over_range? => :array2single do |range_chr,range|
    chromosome.zip(position).collect{|chr,pos| chr == range_chr and range.include? pos}
  end

  property :over_chromosome_range? => :array2single do |chr_range|
    range_chr, start, eend = chr_range.split(":")
    range = (start.to_i..eend.to_i)
    chromosome.zip(position).collect{|chr,pos| chr == range_chr and range.include? pos}
  end

  property :over_gene? => :array2single do |gene|
    gene = Gene.setup(gene.dup, "Ensembl Gene ID", organism) unless Gene === gene

    gene_range = gene.chr_range
    gene_chromosome = gene.chromosome

    if gene_range.nil?
      [false] * self.length
    else
      chromosome.zip(position).collect{|chr,pos| chr == gene_chromosome and gene_range.include? pos}
    end
  end
end
