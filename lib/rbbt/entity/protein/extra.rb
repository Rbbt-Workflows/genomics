module Protein

  property :ensembl_protein_image_url => :single2array do
    organism = self.organism || "Hsa"
    ensembl_url = if organism == "Hsa" then "www.ensembl.org" else "#{organism.sub(/.*\//,'')}.archive.ensembl.org" end

    if Organism.compare_archives(organism, "may2017") == -1
      "http://#{ensembl_url}/Homo_sapiens/Component/Transcript/Web/TranslationImage?db=core;p=#{ensembl};_rmd=d2a8;export=svg"
    else
      "http://#{ensembl_url}/Homo_sapiens/ImageExport/ImageOutput?filename=Human_Transcript.svg&format=custom&image_format=svg&resize=&scale=&db=core&t=#{transcript}&data_action=ProteinSummary&data_type=Transcript&decodeURL=1&strain=0&extra=%7B%22highlightedTracks%22%3A%5B%5D%7D&component=TranslationImage"
    end
  end

  property :svg => :single2array do
    begin
      svg = Open.read(ensembl_protein_image_url)
    rescue Exception
      raise RemoteServerError, "The Ensembl server seems to be down for maintenance. Could not retrieve: #{ensembl_protein_image_url}"
    end

    doc = Nokogiri::XML(svg)
    rect_positions = []
    doc.css('rect').each do |rect|
      x = rect.attr('x').to_f
      next if x < 100
      y = rect.attr('x').to_f
      rect_positions << [x,y]
    end

    start = rect_positions.sort do |a,b|
      case a[1] <=> b[1]
      when -1
        -1
      when 1
        1
      when 0
        a[0] <=> b[0]
      end
    end.first

    svg = svg.sub(/<svg /,"<svg attr-rbbt-entity='protein' attr-rbbt-xstart='#{start[0]}' attr-rbbt-ystart='#{start[1]}' style='background-color:white;' ")

    svg
  end

  property :pfam => :array2single do
    index = Organism.gene_pfam(organism).tsv :flat, :persist => true, :unnamed => true
    pfam = index.chunked_values_at(self).flatten
    Pfam.setup pfam
  end

  property :marked_svg => :single2array do |*positions|
    positions = positions.first if Array === positions.first

    svg = self.svg
    
    seq_len = sequence_length

    doc = Nokogiri::XML(svg)
    start = doc.css('svg').first.attr('attr-rbbt-xstart').to_f
    width = doc.css('svg').first.attr('width').to_f
    height = doc.css('svg').first.attr('height').to_f

    positions.each do |position|
      if width and height and start and seq_len and position
        offset = (width - start)/seq_len * (position - 1) + start + rand * 10
        svg = svg.sub(/<\/svg>/,"<line class='rbbt-vline' x1='#{offset}' x2='#{offset}' y1='5' y2='#{height - 5}' style='stroke:rgb(255,0,0);opacity:0.7'></svg>")
      end
    end

    svg
  end

  property :pdbs => :single do
    next if uniprot.nil?
    UniProt.pdbs(uniprot)
  end

end
