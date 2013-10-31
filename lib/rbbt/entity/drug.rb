require 'rbbt'
require 'rbbt/entity'
require 'rbbt/sources/matador'

module Drug
  extend Entity

  self.format = ["Chemical", "Compound"]
end
