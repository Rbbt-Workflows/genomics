require 'rbbt/entity/pmid'

module Gene

  property :articles => :array2single do
    PMID.setup(Organism.gene_pmids(organism).tsv(:persist => true, :fields => ["PMID"], :type => :flat, :unnamed => true).chunked_values_at self.entrez)
  end

  property :literature_score do |terms|
    terms = terms.collect{|t| t.stem}
    articles = self.articles
    if articles.nil? or articles.empty?
      0
    else
      articles.inject(0){|acc,article| acc += article.text.words.select{|word| terms.include? word}.length }.to_f / articles.length
    end
  end


  property :ihop_interactions => :single do
    uniprot = self.uniprot
    if uniprot.nil?
      nil
    else
      sentences = []

      begin
        url = "http://ws.bioinfo.cnio.es/iHOP/cgi-bin/getSymbolInteractions?ncbiTaxId=9606&reference=#{uniprot}&namespace=UNIPROT__AC" 
        doc = Nokogiri::XML(Open.read(url))
        sentences = doc.css("iHOPsentence")
      rescue
      end

      sentences
    end
  end

  property :tagged_ihop_interactions => :single do
    interactors = []
    ihop_interactions = self.ihop_interactions
    if ihop_interactions.nil?
      nil
    else
      ihop_interactions.each do |sentence|
        sentence.css('iHOPatom').collect{|atom|
          atom.css('evidence');
        }.compact.flatten.each do |evidence|
          symbol =  evidence.attr('symbol')
          taxid  =  evidence.attr('ncbiTaxId')

          if Organism.entrez_taxids(self.organism).list.include? taxid
            interactors << symbol
          end
        end
      end

      interactors = Gene.setup(interactors.uniq, "Associated Gene Name", self.organism)
      

      interactors2ensembl = {}
      interactors.each do |interactor|
        interactors2ensembl[interactor] = interactor.ensembl
      end

      ihop_interactions.collect do |sentence|
        sentence.css('iHOPatom').each{|atom|
          literal = atom.content()
          evidences = atom.css('evidence')
          symbol = evidences.collect do |evidence|
            symbol =  evidence.attr('symbol')
            taxid  =  evidence.attr('ncbiTaxId')

            if Organism.entrez_taxids(self.organism).list.include? taxid
              symbol
            else
              nil
            end
          end.compact.first

          evidences.remove

          if interactors2ensembl.include? symbol and not interactors2ensembl[symbol].nil?
            atom.children.remove
            interactor = Gene.setup(interactors2ensembl[symbol].clean_annotations, "Ensembl Gene ID", self.organism)
            atom.replace interactor.respond_to?(:link)? interactor.link(nil, :title => literal) : interactor.name
          end
        }
        sentence.to_s
      end
    end
  end
end
