require 'rbbt/entity'
require 'rbbt/entity/exon'

module Transcript
  extend Entity

  self.annotation :format
  self.annotation :organism

  add_identifiers Organism.probe_transcripts("NAMESPACE"), "Ensembl Transcript ID"

  def self.enst2ensg(organism, transcript)
    @@enst2ensg ||= {}
    @@enst2ensg[organism] ||= Organism.gene_transcripts(organism).tsv(:type => :single, :key_field => "Ensembl Transcript ID", :fields => ["Ensembl Gene ID"], :persist => true, :unnamed => true)
    res = if Array === transcript
            @@enst2ensg[organism].chunked_values_at transcript
          else
            @@enst2ensg[organism][transcript]
          end

    if defined? Gene
      Gene.fast_setup(res, {:format => "Ensembl Gene ID", :organism => organism})
    end

    res
  end

  def self.enst2ensp(organism, transcript)
    @@enst2ensp ||= {}
    @@enst2ensp[organism] ||= Organism.transcripts(organism).tsv(:type => :single, :key_field => "Ensembl Transcript ID", :fields => ["Ensembl Protein ID"], :persist => true, :unnamed => true)
    res = if Array === transcript
            @@enst2ensp[organism].chunked_values_at transcript
          else
            @@enst2ensp[organism][transcript]
          end
    Protein.setup(res, "Ensembl Protein ID", organism)
  end

  def self.enst2ense(organism, transcript)
    @@enst2ense ||= {}
    @@enst2ense[organism] ||= Organism.transcript_exons(organism).tsv(:persist => true, :fields => ["Ensembl Exon ID"], :type => :flat, :unnamed => true)
    res = if Array === transcript
            @@enst2ense[organism].chunked_values_at transcript
          else
            @@enst2ense[organism][transcript]
          end
    res
  end

  property :exons => :array2single do 
    Exon.setup(Transcript.enst2ense(organism, self), organism)
  end

  property :ensembl => :array2single do
    to "Ensembl Transcript ID"
  end

  property :sequence => :array2single do
    transcript_sequence = Organism.transcript_sequence(organism).tsv :persist => true, :unnamed => true
    transcript_sequence.chunked_values_at self.ensembl
  end

  property :sequence_length => :array2single do
    sequence.collect{|s|
      s.nil? ? nil : s.length
    }
  end

  property :gene => :array2single do
    Transcript.enst2ensg(organism, self)
  end

  property :protein => :array2single do
    Transcript.enst2ensp(organism, self)
  end
end

