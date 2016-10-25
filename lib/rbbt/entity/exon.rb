module Exon
  extend Entity

  self.annotation :organism

  def self.exon_positions(exon, organism)
    @@exon_positions ||= {}
    @@exon_positions[organism] ||= Organism.exons(organism).tsv :key_field => "Ensembl Exon ID", :fields => ["Chromosome Name", "Exon Chr Start", "Exon Chr End"], :type => :list, :persist => true, :unnamed => true
    chr, start, eend = @@exon_positions[organism][exon]
    [chr, start.to_i, eend.to_i]
  end

  property :position => :array do
    self.collect{|exon|
      Exon.exon_positions exon, organism
    }
  end
end
