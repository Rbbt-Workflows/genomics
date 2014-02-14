module Gene
  property :related_cancers => :array2single do
    Cancer["cancer_genes.tsv"].tsv(:persist => true, :type => :list).chunked_values_at(self.name).collect{|v| v.nil? ? nil : (v["Tumour Types (Somatic Mutations)"].split(", ") + v["Tumour Types (Germline Mutations)"].split(", ")).uniq}
  end

  property :somatic_snvs => :array2single do
    names = self.name
    raise "No organism defined" if self.organism.nil?
    clean_organism = self.organism.sub(/\/.*/,'') + '/jun2011'
    names.organism = clean_organism
    ranges = names.chromosome.zip(name.chr_range).collect do |chromosome, range|
      next if range.nil?
      [chromosome, range.begin, range.end] * ":"
    end
    Sequence.job(:somatic_snvs_at_genomic_ranges, File.join("Gene", (names.compact.sort * ", ")[0..80]), :organism => clean_organism, :ranges  => ranges).fork.join.load.chunked_values_at ranges
  end

end
