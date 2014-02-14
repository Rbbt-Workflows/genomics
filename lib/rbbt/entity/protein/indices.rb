module Protein

  def self.ensp2sequence(organism, protein)
    @@ensp2sequence ||= {}
    @@ensp2sequence[organism] ||= Organism.protein_sequence(organism).tsv :persist => true, :unnamed => true
    if Array === protein
      @@ensp2sequence[organism].chunked_values_at protein
    else
      @@ensp2sequence[organism][protein]
    end
  end

  def self.ensp2enst(organism, protein)
    @@ensp2enst ||= {}
    @@ensp2enst[organism] ||= Organism.transcripts(organism).tsv(:type => :single, :key_field => "Ensembl Protein ID", :fields => ["Ensembl Transcript ID"], :persist => true, :unnamed => true)
    @@ensp2enst[organism][protein]
  end
end
