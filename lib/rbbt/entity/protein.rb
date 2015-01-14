require 'rbbt/entity'
require 'rbbt/entity/identifiers'
require 'rbbt/workflow'
require 'rbbt/sources/organism'
require 'rbbt/entity/gene'

Workflow.require_workflow "Translation"

module Protein
  extend Entity

  self.annotation :format
  self.annotation :organism

  self.add_identifiers Organism.protein_identifiers("NAMESPACE"), "Ensembl Protein ID"
end

Entity.formats["Ensembl Protein ID"] = Protein

require 'rbbt/entity/protein/indices'
require 'rbbt/entity/protein/basic'
require 'rbbt/entity/protein/extra'
