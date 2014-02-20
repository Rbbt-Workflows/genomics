require 'rbbt/sources/genomes1000'
require 'rbbt/sources/COSMIC'
require 'rbbt/sources/dbSNP'

module GenomicMutation

  property :dbSNP_position => :array2single do
    index ||= GenomicMutation.dbSNP_position_index(organism)
    index.chunked_values_at self.collect{|m| m.split(":")[0..1] * ":" }
  end


  property :dbSNP => :array2single do
    index ||= GenomicMutation.dbSNP_index(organism)
    index.chunked_values_at self.clean_annotations.collect{|m| m.split(":")[0..2] * ":" }
  end

  property :genomes_1000 => :array2single do
    index ||= GenomicMutation.genomes_1000_index(organism)
    index.chunked_values_at self.clean_annotations.collect{|m| m.split(":")[0..2] * ":" }
  end

  property :COSMIC => :array2single do
    index ||= GenomicMutation.COSMIC_index(organism)
    index.chunked_values_at self.collect{|m| m.split(":").values_at(0,1,1) * ":" }
  end

end
