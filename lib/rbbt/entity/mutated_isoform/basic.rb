module MutatedIsoform

  property :change => :array2single do
    self.collect{|mi| mi.split(":").last}
  end

  property :position => :array2single do
    change.collect{|c|
      if c.match(/[^\d](\d+)[^\d]/)
        $1.to_i
      else
        nil
      end
    }
  end

  property :protein => :array2single do
    proteins = self.collect{|mutation| 
      mutation.split(":").first if mutation =~ /^ENS[A-Z]*P/
    }
    Protein.setup(proteins, "Ensembl Protein ID", organism)
  end

  property :transcript => :array2single do
    begin
      protein = self.protein
      Transcript.setup(protein.transcript.zip(self.collect{|mutation| mutation.split(":").first}).collect{|p| p.compact.first}, "Ensembl Transcript ID", organism)
    end
  end

  property :name => :array2single do
    self.zip(protein.gene.name).collect do |mi,n|
      n.nil? ? mi : "(#{ n }) #{ mi }"
    end
  end
end
