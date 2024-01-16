Workflow.require_workflow "Sequence"
Workflow.require_workflow "MutationSignatures"
Workflow.require_workflow "EVS"
Workflow.require_workflow "Genomes1000"
Workflow.require_workflow "GERP"
Workflow.require_workflow "DbSNP"
Workflow.require_workflow "Proteomics"
Workflow.require_workflow "DbNSFP"



require_relative 'sample/cnv'
require_relative 'sample/genes'
require_relative 'sample/snv'
require_relative 'sample/genomic_mutations'
require_relative 'sample/mutated_isoforms'
