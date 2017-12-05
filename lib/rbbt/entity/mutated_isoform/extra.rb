require 'rbbt/sources/uniprot'

module MutatedIsoform

  property :pdbs => :single do
    uniprot = self.transcript.protein.uniprot
    next if uniprot.nil?
    UniProt.pdbs_covering_aa_position(uniprot, self.position)
  end

  property :marked_svg => :single2array do
    iii :HEY
    iii self
    iii self.change
    iii self.position
    protein.marked_svg(self.position)
  end
end
