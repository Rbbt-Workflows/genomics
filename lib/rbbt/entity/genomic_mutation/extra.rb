
module GenomicMutation
  property :ensembl_browser => :single2array do
    "http://#{Misc.ensembl_server(self.organism)}/#{Organism.scientific_name(organism).sub(" ", "_")}/Location/View?db=core&r=#{chromosome}:#{position - 100}-#{position + 100}"
  end

  property :ucsc_browser => :single2array do
    "http://genome.ucsc.edu/cgi-bin/hgTracks?db=#{Organism.hg_build(organism)}&position=chr#{chromosome}:#{position - 100}-#{position + 100}"
  end
end
