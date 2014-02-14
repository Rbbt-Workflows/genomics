module GenomicMutation

  property :type => :array2single do
    reference = watson ? self.reference : self.gene_strand_reference

    self.base.zip(reference, self).collect do |base,reference, mutation|

      type = case
             when (base.nil? or reference.nil? or base == "?" or reference == "?")
               "unknown"
             when base.index(',')
               "multiple"
             when base == reference
               "none"
             when (base.length > 1 or base == '-')
               "indel"
             when (not %w(A G T C).include? base and not %w(A G T C).include? reference) 
               "unknown"
             when (((Misc::IUPAC2BASE[base] || []) & ["A", "G"]).any? and     ((Misc::IUPAC2BASE[reference] || []) & ["T", "C"]).any?)
               "transversion"
             when (((Misc::IUPAC2BASE[base] || []) & ["T", "C"]).any? and     ((Misc::IUPAC2BASE[reference] || []) & ["A", "G"]).any?)
               "transversion"
             when (((Misc::IUPAC2BASE[base] || []) & ["A", "G"]).any? and     ((Misc::IUPAC2BASE[reference] || [nil]) & ["T", "C", nil]).empty?)
               "transition"
             when (((Misc::IUPAC2BASE[base] || []) & ["T", "C"]).any? and     ((Misc::IUPAC2BASE[reference] || [nil]) & ["A", "G", nil]).empty?)
               "transition"
             else
               "unknown"
             end
      type
    end

  end

end
