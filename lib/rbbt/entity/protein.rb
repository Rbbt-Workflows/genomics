require 'rbbt/entity'
require 'rbbt/workflow'
require 'rbbt/sources/organism'
#require 'rbbt/statistics/hypergeometric'
#require 'rbbt/network/paths'
require 'rbbt/entity/gene'

Workflow.require_workflow "Translation"

module Protein
  extend Entity

  self.annotation :format
  self.annotation :organism

  self.format = "Ensembl Protein ID"

end

require 'rbbt/entity/protein/indices'
require 'rbbt/entity/protein/basic'
require 'rbbt/entity/protein/extra'
