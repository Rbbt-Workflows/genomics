require 'rbbt/sources/InterPro'

module MutatedIsoform

  property :affected_interpro_domains => :single do
    if protein.nil?
      []
    else
      InterProDomain.setup(Misc.zip_fields(protein.interpro_domain_positions || []).select{|d,s,e|
        e.to_i > position and s.to_i < position
      }.collect{|d,s,e| d }, organism)
    end
  end

  property :affected_interpro_domain_positions => :single do
    if protein.nil?
      []
    else
      Misc.zip_fields(protein.interpro_domain_positions || []).select{|d,s,e|
        e.to_i > position and s.to_i < position
      }.collect{|d,s,e| [d, position - s.to_i, s.to_i, e.to_i]}
    end
  end

  property :affected_domain_positions => :single do
    affected_interpro_domain_positions
  end

  property :affected_domains => :single do
    affected_interpro_domains
  end

  property :ablated_interpro_domains => :single do
    if protein.nil?
      []
    else
      InterProDomain.setup(Misc.zip_fields(protein.interpro_domain_positions || []).select{|d,s,e|
        e.to_i > position
      }.collect{|d,s,e| d }, organism)
    end
  end

  property :ablated_interpro_domain_positions => :single do
    if protein.nil?
      []
    else
      Misc.zip_fields(protein.interpro_domain_positions || []).select{|d,s,e|
        e.to_i > position
      }.collect{|d,s,e| [d, s.to_i, e.to_i]}
    end
  end

  property :ablated_domain_positions => :single do
    ablated_interpro_domain_positions
  end

  property :ablated_domains => :single do
    ablated_interpro_domains
  end

end
