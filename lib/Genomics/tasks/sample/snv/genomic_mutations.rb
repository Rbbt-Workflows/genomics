module Sample
  input :file, :file, "Input file"
  input :vcf, :boolean, "Input file is a VCF", false
  returns "Genomic Mutation"
  task :genomic_mutations => :array do |file, vcf|
    stream = if file
               if vcf
                 file = file.dumper_stream if TSV === file
                 job = Sequence.job(:genomic_mutations, sample, :vcf_file => file)
                 job.produce
                 TSV.get_stream job
               else
                 TSV.get_stream file
               end
             else
               TSV.get_stream Sample.mutations(sample)
             end
    sorted = Misc.sort_mutation_stream(stream)
    mappable_regions = Sample.mappable_regions(sample)
    Path.setup(mappable_regions)
    if mappable_regions
      mappable_regions_io = Open.open(mappable_regions.find)
      mappable = Misc.select_ranges(sorted, mappable_regions_io, ":")
      Misc.sensiblewrite(path, CMD.cmd('cut -f1', :in => mappable, :pipe => true, :no_fail => true))
    else
      Misc.sensiblewrite(path, sorted)
    end
    nil
  end

  #dep :genomic_mutations
  #dep :organism
  #dep :watson
  #dep Sequence, :type, :mutations => :genomic_mutations, :organism => :organism, :watson => :watson
  #dep MutationSignatures, :mutation_context, :mutations => :genomic_mutations, :organism => :organism
  #dep :expanded_vcf
  #task :mutation_details => :tsv do
  #  if Sample.vcf_files(sample).any?
  #    exteded_vcf_step = step(:expanded_vcf)
  #    exteded_vcf = TSV.open(exteded_vcf_step.file(exteded_vcf_step.run))
  #    code = sample.split(":").last
  #    good_fields = exteded_vcf.fields.select{|f| f =~ /#{code}:/ or f == "Quality"}
  #    exteded_vcf = exteded_vcf.slice(good_fields)
  #    exteded_vcf.key_field = "Genomic Position"
  #    pasted = TSV.paste_streams([step(:reference), step(:type), step(:mutation_context), exteded_vcf.dumper_stream], :sort => true)
  #  else
  #    good_fields = []
  #    pasted = TSV.paste_streams([step(:reference), step(:type), step(:mutation_context)], :sort => true)
  #  end

  #  dumper = TSV::Dumper.new :key_field => "Genomic Mutation",
  #    :fields => ["Chromosome Name", "Position", "Reference", "Change", "Context change", "Type"] + good_fields.collect{|f| f.split(":").last},
  #    :type => :list, :namespace => organism

  #  dumper.init
  #  TSV.traverse pasted, :into => dumper do |mutation,values,fields|
  #    reference,type, context, *vcf = values.flatten
  #    mutation = mutation.first if Array === mutation
  #    chromosome, position, change, *rest = mutation.split":"
  #    [mutation, [chromosome, position, reference, change, context, type] + vcf]
  #  end
  #end

end
