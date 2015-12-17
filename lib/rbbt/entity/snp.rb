require 'rbbt/entity'

module SNP
  extend Entity

  self.format = ["SNP", "SNP ID", "RSID"]

  def self.dbSNP_info
    @@dbSNP_info ||= DbSNP.rsid_database.tap{|o| o.unnamed = false}
  end

  property :dbSNP_info => :array2single do
    db = SNP.dbSNP_info
    self.collect{|e|
      db[e]
    }
  end
end
