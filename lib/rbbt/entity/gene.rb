require 'rbbt/entity'
require 'rbbt/entity/identifiers'
require 'rbbt/workflow'

Workflow.require_workflow "Translation"

module Gene
  extend Entity

  self.annotation :format
  self.annotation :organism

  self.add_identifiers Organism.identifiers("NAMESPACE"), "Ensembl Gene ID", "Associated Gene Name"
end

require 'rbbt/entity/gene/indices'
require 'rbbt/entity/gene/basic'
require 'rbbt/entity/gene/identifiers'
require 'rbbt/entity/gene/extra'
require 'rbbt/entity/gene/drugs'
require 'rbbt/entity/gene/literature'
