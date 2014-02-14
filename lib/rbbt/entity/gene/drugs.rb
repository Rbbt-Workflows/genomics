require 'rbbt/entity/transcript'
require 'rbbt/sources/matador'

module Gene
  property :matador_drugs => :array2single do
    require 'rbbt/sources/matador'
    @@matador ||= Matador.protein_drug.tsv(:persist => false, :unnamed => true)

    ensg = self.to("Ensembl Gene ID")

    transcripts = Gene.ensg2enst(organism, ensg)

    t2ps = Misc.process_to_hash(transcripts.compact.flatten.uniq){|l| Transcript.enst2ensp(organism, l).flatten.compact.uniq}

    all_proteins = t2ps.values.flatten.compact

    chemical_pos = @@matador.identify_field "Chemical"

    p2ds = Misc.process_to_hash(all_proteins){|proteins| 
      @@matador.chunked_values_at(proteins).collect{|values| 
        next if values.nil?
        values[chemical_pos]
      }
    }

    res = transcripts.collect do |ts|
      ps = t2ps.chunked_values_at(ts).compact.flatten
      p2ds.chunked_values_at(ps).flatten.compact.uniq
    end

    res
  end

  property :drugs => :array2single do
    @matador_drugs = matador_drugs
  end

  property :kegg_pathway_drugs => :array2single do
    self.collect{|gene|
      pathway_genes = gene.kegg_pathways
      next if pathway_genes.nil?
      pathway_genes = pathway_genes.compact.flatten.genes.flatten
      Gene.setup(pathway_genes, "KEGG Gene ID", organism)

      pathway_genes.compact.drugs.compact.flatten.uniq
    }
  end

  property :pathway_drugs => :array2single do
    kegg_pathway_drugs
  end

end
