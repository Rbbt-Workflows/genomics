require 'rbbt/sources/organism'
require 'rbbt/sources/entrez'
require 'rbbt/entity/protein'
require 'rbbt/entity/transcript'

module Gene

  add_identifiers Organism.identifiers("NAMESPACE"), "Ensembl Gene ID", "Associated Gene Name"

  property :entrez => :array2single do
    to "Entrez Gene ID"
  end

  property :uniprot => :array2single do
    to "UniProt/SwissProt Accession"
  end

  property :long_name => :array2single do
    entre = self.entrez
    gene = Entrez.get_gene(entrez).chunked_values_at(entrez).collect{|gene| gene.nil? ? nil : (gene.description || []).flatten.first}
  end

  property :description => :single2array do
    gene = Entrez.get_gene(to("Entrez Gene ID"))
    gene.nil? ? nil : (gene.summary || [nil]).flatten.first
  end
end
