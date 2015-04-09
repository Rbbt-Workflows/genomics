
module GenomicMutation

  def self.exon_rank_index(organism)
    @@exon_rank_indices ||= {}
    @@exon_rank_indices[organism] ||= Organism.transcript_exons(organism).tsv :persist => true, :type => :double, :unnamed => true
  end

  def self.exon_position_index(organism)
    @@exon_position_indices ||= {}
    @@exon_position_indices[organism] ||= Organism.exons(organism).tsv :persist => true, :type => :list, :cast => :to_i, :fields => ["Exon Strand", "Exon Chr Start", "Exon Chr End"], :unnamed => true
  end

  def self.transcripts_for_exon_index(organism)
    @@transcript_for_exon_indices ||= {}
    @@transcript_for_exon_indices[organism] ||= Organism.transcript_exons(organism).tsv :persist => true, :key_field => "Ensembl Exon ID", :fields => ["Ensembl Transcript ID"], :unnamed => true, :merge => true
  end

  def self.genomes_1000_index(organism)
    build = Organism.hg_build(organism)
    @@genomes_1000_index ||= {}
    @@genomes_1000_index[build] ||= Genomes1000[build == "hg19" ? "mutations" : "mutations_hg18"].tsv :key_field => "Genomic Mutation", :unnamed => true, :fields => ["Variant ID"], :type => :single, :persist => true
  end

  def self.COSMIC_index(organism)
    build = Organism.hg_build(organism)
    field = {
      "hg19" => "Mutation GRCh37 genome position",
      "hg18" => "Mutation NCBI36 genome position",
    
    }[build]
    @@COSMIC_index ||= {}
    @@COSMIC_index[build] ||= COSMIC.mutations.tsv :key_field => field, :unnamed => true, :fields => ["Mutation ID"], :type => :single, :persist => true
  end

  def self.dbSNP_index(organism)
    build = Organism.hg_build(organism)
    @@dbSNP_index ||= {}
    @@dbSNP_index[build] ||= DbSNP[build == "hg19" ? "mutations" : "mutations_hg18"].tsv :key_field => "Genomic Mutation", :unnamed => true,  :type => :single, :persist => true
  end

  def self.dbSNP_position_index(organism)
    build = Organism.hg_build(organism)

    @@dbSNP_position_index ||= {}

    @@dbSNP_position_index[build] ||= TSV.open(
      CMD::cmd('sed "s/\([[:alnum:]]\+\):\([[:digit:]]\+\):\([ACTG+-]\+\)/\1:\2/" ', :in => DbSNP[build == "hg19" ? "mutations" : "mutations_hg18"].open, :pipe => true), 
      :key_field => "Genomic Mutation", :unnamed => true,  :type => :single, :persist => true)
  end
end
