require 'rbbt/sources/organism'
require 'rbbt/sources/entrez'
require 'rbbt/entity/protein'
require 'rbbt/entity/transcript'

module Gene

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

  #property :to => :array2single do |new_format|
  #  return self if format == new_format
  #  if format.nil?
  #    genes = Translation.job(:tsv_translate, "", :organism => organism, :genes => self, :format => new_format).exec.chunked_values_at(self)
  #  else
  #    genes = Translation.job(:tsv_translate_from, "", :organism => organism, :genes => self, :source_format => format, :target_format => new_format).exec.chunked_values_at(self)
  #  end
  #  Gene.setup(genes, new_format, organism)
  #  genes.extend AnnotatedArray if AnnotatedArray === self
  #  genes
  #end

  #property :ensembl => :array2single do
  #  to "Ensembl Gene ID"
  #end

  #property :entrez => :array2single do
  #  to "Entrez Gene ID"
  #end

  #property :uniprot => :array2single do
  #  to "UniProt/SwissProt Accession"
  #end

  #property :name => :array2single do
  #  return self if self.format == "Associated Gene Name"
  #  to "Associated Gene Name"
  #end

  #property :long_name => :array2single do
  #  entre = self.entrez
  #  gene = Entrez.get_gene(entrez).chunked_values_at(entrez).collect{|gene| gene.nil? ? nil : (gene.description || []).flatten.first}
  #end

  #property :description => :single2array do
  #  gene = Entrez.get_gene(to("Entrez Gene ID"))
  #  gene.nil? ? nil : (gene.summary || [nil]).flatten.first
  #end

  property :max_transcript_length => :array2single do
    transcripts.collect{|list| list.sequence_length.compact.max}
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

end
