require 'rbbt/sources/organism'
require 'rbbt/sources/entrez'
require 'rbbt/entity/protein'
require 'rbbt/entity/transcript'

module Gene

  def self.exons(gene, organism)
    @@gene_exons ||= {}
    @@gene_exons[organism] ||= Organism.exons(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["Ensembl Exon ID"], :type => :flat, :persist => true, :unnamed => true
    @@gene_exons[organism][gene]
  end

  property :strand => :array2single do 
    @@strand_tsv ||= {}
    @@strand_tsv[organism] ||= Organism.gene_positions(organism).tsv(:fields => ["Strand"], :type => :single, :persist => true, :unnamed => true)
    to("Ensembl Gene ID").collect do |gene|
      @@strand_tsv[organism][gene]
    end
  end

  property :chr_start => :array2single do
    Organism.gene_positions(organism).tsv(:persist => true, :type => :single, :cast => :to_i, :fields => ["Gene Start"]).chunked_values_at self
  end

  property :chromosome => :array2single do
    @@chromosome_tsv ||= {}
    @@chromosome_tsv[organism] ||= Organism.gene_positions(organism).tsv :fields => ["Chromosome Name"], :type => :single, :persist => true, :unnamed => true
    if Array === self
      to("Ensembl Gene ID").collect do |gene|
        @@chromosome_tsv[organism][gene]
      end
    else
      @@chromosome_tsv[organism][to("Ensembl Gene ID")]
    end
  end

  property :chr_range => :array2single do
    @@chr_range_index ||= Organism.gene_positions(organism).tsv :fields => ["Gene Start", "Gene End"], :type => :list, :persist => true, :cast => :to_i, :unnamed => true
    to("Ensembl Gene ID").collect do |gene|
      next if not @@chr_range_index.include? gene
      Range.new *@@chr_range_index[gene]
    end
  end
  property :transcripts => :array2single do
    res = Gene.ensg2enst(organism, self.ensembl)
    Transcript.setup(res, "Ensembl Transcript ID", organism)
    res
  end

  property :proteins  => :array2single do
    transcripts = Gene.ensg2enst(organism, self.ensembl)

    all_transcripts = Transcript.setup(transcripts.flatten.compact.uniq, "Ensembl Transcript ID", organism)

    transcript2protein = Misc.process_to_hash(all_transcripts){|list|
      list.protein
    }

    res = transcripts.collect{|list|
      Protein.setup(transcript2protein.chunked_values_at(list || []).compact.uniq.reject{|p| p.empty?}, "Ensembl Protein ID", organism)
    }

    Protein.setup(res, "Ensembl Protein ID", organism)
  end

  property :biotype => :array2single do
    Organism.gene_biotype(organism).tsv(:persist => true, :type => :single, :unnamed => true).chunked_values_at self.ensembl
  end

  property :sequence => :array2single do
    @@sequence_tsv ||= {}
    @@sequence_tsv[organism] ||= Organism.gene_sequence(organism).tsv :persist => true, :unnamed => true
    @@sequence_tsv[organism].chunked_values_at self.ensembl
  end

  property :max_transcript_length => :array2single do
    transcripts.collect{|list| list.nil? ? 0 : list.sequence_length.compact.max}
  end

  property :max_protein_length => :array2single do
    proteins = self.proteins
    all_proteins = Protein.setup(proteins.flatten, "Ensembl Protein ID", organism)
    lengths = Misc.process_to_hash(all_proteins){|list| list.sequence_length}
    proteins.collect{|list| lengths.chunked_values_at(list).compact.max}
  end

  property :ortholog => :array2single do |other|
    return self if organism =~ /^#{ other }(?!\w)/
    new_organism = organism.split("/")
    new_organism[0] = other
    new_organism = new_organism * "/"
    Gene.setup(Organism[organism]["ortholog_#{other}"].tsv(:persist => true, :unnamed => true).chunked_values_at(self.ensembl).collect{|l| l.first}, "Ensembl Gene ID", new_organism)
  end

  property :principal_transcripts => :single do
    pi = Appris.principal_transcript_list
    Transcript.setup((transcripts & pi.to_a), "Ensembl Transcript ID", organism)
  end

  property :exons => :single do
    Exon.setup(Gene.exons(self, organism), organism)
  end
end
