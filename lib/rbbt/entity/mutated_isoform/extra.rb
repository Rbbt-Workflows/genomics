require 'rbbt/sources/uniprot'

module MutatedIsoform

  property :pdbs => :single do
    uniprot = self.transcript.protein.uniprot
    next if uniprot.nil?
    UniProt.pdbs_covering_aa_position(uniprot, self.position)
  end

  property :ensembl_protein_image_url => :single2array do
    ensembl_url = if organism == "Hsa" then "www.ensembl.org" else "#{organism.sub(/.*\//,'')}.archive.ensembl.org" end
    "http://#{ensembl_url}/Homo_sapiens/Component/Transcript/Web/TranslationImage?db=core;p=#{protein};_rmd=d2a8;export=svg"
  end

  property :marked_svg => :single2array do
    svg = Open.read(protein.ensembl_protein_image_url)
    
    seq_len = protein.sequence_length
    position = self.position

    doc = Nokogiri::XML(svg)
    return nil unless doc.css('svg') and doc.css('svg').any?
    width = doc.css('svg').first.attr('width').to_f
    height = doc.css('svg').first.attr('height').to_f
    start = doc.css('rect.ac').first.attr('x').to_f

    if width and height and start and seq_len and position
      offset = (width - start)/seq_len * position + start
      svg.sub(/<\/svg>/,"<rect x='#{offset}' y='1' width='1' height='#{height}' style='fill:rgb(255,0,0);opacity:0.5;stroke:none;'></svg>")
    else
      svg
    end
  end

end
