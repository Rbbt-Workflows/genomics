require 'rbbt/workflow'

require 'rbbt/entity'
require 'rbbt/entity/protein'
require 'rbbt/entity/gene'
require 'rbbt/entity/mutated_isoform'

require 'rbbt/sources/organism'

#require 'rbbt/mutation/mutation_assessor'

Workflow.require_workflow "Sequence"

module GenomicMutation
  extend Entity

  self.annotation :jobname
  self.annotation :organism
  self.annotation :watson

  self.format = "Genomic Mutation"

end


require 'rbbt/entity/genomic_mutation/vcf'
require 'rbbt/entity/genomic_mutation/indices'

require 'rbbt/entity/genomic_mutation/basic'
require 'rbbt/entity/genomic_mutation/watson'
require 'rbbt/entity/genomic_mutation/types'
require 'rbbt/entity/genomic_mutation/features'
require 'rbbt/entity/genomic_mutation/consequences'
#require 'rbbt/entity/genomic_mutation/snps'
require 'rbbt/entity/genomic_mutation/extra'
