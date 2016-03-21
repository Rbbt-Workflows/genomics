module Protein

  property :ensembl_protein_image_url => :single2array do
    organism = self.organism || "Hsa"
    ensembl_url = if organism == "Hsa" then "www.ensembl.org" else "#{organism.sub(/.*\//,'')}.archive.ensembl.org" end
    "http://#{ensembl_url}/Homo_sapiens/Component/Transcript/Web/TranslationImage?db=core;p=#{ensembl};_rmd=d2a8;export=svg"
  end

  property :pfam => :array2single do
    index = Organism.gene_pfam(organism).tsv :flat, :persist => true, :unnamed => true
    pfam = index.chunked_values_at(self).flatten
    Pfam.setup pfam
  end

  property :marked_svg => :single2array do |*args|
    positions = args.first
    begin
      svg = Open.read(ensembl_protein_image_url)
    rescue Exception
      raise RemoteServerError, "The Ensembl server seems to be down for maintenance. Could not retrieve: #{ensembl_protein_image_url}"
    end
    
    seq_len = sequence_length

    doc = Nokogiri::XML(svg)
    return nil unless doc.css('svg').any?
    width = doc.css('svg').first.attr('width').to_f
    height = doc.css('svg').first.attr('height').to_f
    start = doc.css('rect.ac').first.attr('x').to_f

    positions.each do |position|
      if width and height and start and seq_len and position
        offset = (width - start)/seq_len * position + start + rand * 10
        svg = svg.sub(/<\/svg>/,"<rect x='#{offset}' y='1' width='1' height='#{height}' style='fill:rgb(255,0,0);opacity:0.5;stroke:none;'></svg>")
      end
    end

    svg = svg.sub(/<svg /,"<svg attr-rbbt-entity='protein' style='background-color:white;'")
    svg
  end

  property :pdbs => :single do
    next if uniprot.nil?
    UniProt.pdbs(uniprot)
  end

end
