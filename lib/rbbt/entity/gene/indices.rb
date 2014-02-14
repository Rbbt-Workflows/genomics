require 'rbbt/sources/organism'
require 'rbbt/sources/entrez'

module Gene

  def self.ensg2enst(organism, gene)
    @@ensg2enst ||= {}
    @@ensg2enst[organism] ||= Organism.gene_transcripts(organism).tsv(:type => :flat, :key_field => "Ensembl Gene ID", :fields => ["Ensembl Transcript ID"], :persist => true, :unnamed => true)

    if Array === gene
      @@ensg2enst[organism].chunked_values_at gene
    else
      @@ensg2enst[organism][gene]
    end
  end

  def self.filter(query, field = nil, options = nil, entity = nil)
    return true if query == entity

    return true if query == Gene.setup(entity.dup, options.merge(:format => field)).name

    false
  end

  def self.gene_list_bases(genes, organism = nil)
    if genes.respond_to? :orgnanism
      organism = genes.organism if organism.nil?
      genes = genes.clean_annotations
    end

    organism ||= "Hsa"

    @@gene_start_end ||= {}
    gene_start_end = @@gene_start_end[organism] ||= Organism.gene_positions(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["Gene Start", "Gene End"], :type => :list, :cast => :to_i, :unmamed => true)

    ranges = genes.collect{|gene| start, eend = gene_start_end[gene]; (start..eend) }
    Misc.total_length(ranges)
  end

  def self.gene_list_exon_bases(genes, organism = nil)
    if genes.respond_to? :orgnanism
      organism = genes.organism if organism.nil?
      genes = genes.clean_annotations
    end

    organism ||= "Hsa"

    @@gene_exons_tsv ||= {}
    gene_exons = @@gene_exons_tsv[organism] ||= Organism.exons(organism).tsv(:persist => true, :key_field => "Ensembl Gene ID", :fields => ["Ensembl Exon ID"], :type => :flat, :merge => true, :unnamed => true)

    @@exon_range_tsv ||= {}
    exon_ranges = @@exon_range_tsv[organism] ||= Organism.exons(organism).tsv(:persist => true, :fields => ["Exon Chr Start", "Exon Chr End"], :type => :list, :cast => :to_i, :unnamed => true)

    exons = gene_exons.values_at(*genes).compact.flatten.uniq

    exon_ranges = exons.collect{|exon|
      Log.low "Exon #{ exon } does not have range" and next if not exon_ranges.include? exon
      pos = exon_ranges[exon]
      (pos.first..pos.last)
    }.compact
    
    Misc.total_length(exon_ranges)
  end
end
