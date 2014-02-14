module Protein

  property :uniprot => :array2single do
    to "UniProt/SwissProt Accession"
  end

  property :ensembl => :array2single do
    to "Ensembl Protein ID"
  end

  property :transcript => :array2single do
    res = ensembl.collect{|ensp|
      Protein.ensp2enst(organism, ensp)
    }
    Transcript.setup(res, "Ensembl Transcript ID", self.organism) if defined? Transcript
    res
  end

  property :to => :array2single do |new_format|
    return self if format == new_format
    Protein.setup(Translation.job(:tsv_translate_protein, "", :organism => organism, :proteins => self, :format => new_format).exec.chunked_values_at(self), new_format, organism)
  end

  property :__to => :array2single do |new_format|
    return self if format == new_format
    to!(new_format).collect!{|v| v.nil? ? nil : v.first}
  end

  property :ortholog => :array2single do |other|
    return self if organism =~ /^#{ other }(?!\w)/
    self.zip(self.gene.ortholog(other)).collect do |this_protein,other_gene|
      next if other_gene.nil? or other_gene.empty?
      this_protein_length = this_protein.sequence.length
      proteins = Gene.setup(other_gene, "Ensembl Gene ID", other).proteins.flatten.reject{|p| p.sequence.nil?}
      best = proteins.sort_by{|other_protein| (other_protein.sequence.length - this_protein_length).abs }.first
      best
    end
  end

  property :gene => :array do
    Gene.setup(to("Ensembl Protein ID").clean_annotations.collect{|e| e.nil? ? e : e.dup}, "Ensembl Protein ID", organism).ensembl
  end

  property :sequence => :array2single do
    Protein.ensp2sequence(organism, self.ensembl)
  end

  property :sequence_length => :array2single do
    sequence.collect{|seq| seq.nil? ? nil : seq.length}
  end

end
