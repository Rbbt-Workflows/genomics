require 'rbbt/entity'
require 'rbbt/workflow'

Workflow.require_workflow "Translation"

module Gene
  extend Entity

  self.annotation :format
  self.annotation :organism

  self.format = Organism.identifiers("Hsa/feb2014").all_fields - ["Ensembl Protein ID", "Ensembl Transcript ID"]
end

require 'rbbt/entity/gene/indices'
require 'rbbt/entity/gene/basic'
require 'rbbt/entity/gene/identifiers'
require 'rbbt/entity/gene/extra'
require 'rbbt/entity/gene/drugs'
require 'rbbt/entity/gene/literature'
