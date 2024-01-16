Workflow.require_workflow "Sequence"

require_relative 'snv/vcf'
require_relative 'snv/genomic_mutations'
require_relative 'snv/common'
require_relative 'snv/maf'

Sample.instance_eval &SNVTasks

require_relative 'snv/zygosity'
require_relative 'snv/genes'

require 'rbbt/entity/sample'
Sample.update_task_properties
