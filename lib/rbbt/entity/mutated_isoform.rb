require 'rbbt/entity'
require 'rbbt/entity/protein'
require 'rbbt/entity/gene'

module MutatedIsoform
  extend Entity

  self.annotation :organism

  self.format = "Mutated Isoform"

end

require 'rbbt/entity/mutated_isoform/basic'
require 'rbbt/entity/mutated_isoform/consequence'
require 'rbbt/entity/mutated_isoform/domains'
require 'rbbt/entity/mutated_isoform/damage'
require 'rbbt/entity/mutated_isoform/extra'
