module GenomicMutation

  property :affected_genes => :array2single do
    _mutated_isoforms = mutated_isoforms

    _all_mis = _mutated_isoforms.compact.flatten.uniq
    non_synonymous_mutated_isoforms = MutatedIsoform.setup(_all_mis, organism).reject{|mi| mi.consequence == "SYNONYMOUS" or mi.consequence == "UTR"}

    mi_gene = Misc.process_to_hash(non_synonymous_mutated_isoforms.clean_annotations){|mis| non_synonymous_mutated_isoforms.protein.gene.clean_annotations}

    _mutated_isoforms = _mutated_isoforms.clean_annotations if _mutated_isoforms.respond_to? :clean_annotations

    from_protein = _mutated_isoforms.collect{|mis|
      genes = mis.nil? ? [] : mi_gene.chunked_values_at(mis).compact.uniq
      #Gene.setup(genes, "Ensembl Gene ID", organism)
      genes
    }

    _transcripts_with_affected_splicing = self.transcripts_with_affected_splicing.clean_annotations
    transcript2gene = Organism.gene_transcripts(organism).index :target => "Ensembl Gene ID", :fields => ["Ensembl Transcript ID"], 
      :unamed => true, :persist => true

    genes_with_altered_splicing = _transcripts_with_affected_splicing.collect{|transcripts| 
      (transcripts and transcripts.any?) ? transcript2gene.values_at(*transcripts) : nil
    }

    from_protein.each_with_index do |list, i|
      if spliced_genes = genes_with_altered_splicing[i] and spliced_genes
        list.concat spliced_genes
        list.uniq!
      end
    end

    Gene.setup(from_protein, "Ensembl Gene ID", organism)
  end

  property :relevant? => :array2single do
    affected_genes.clean_annotations.collect{|g| g.any?  }
  end

  property :damaged_genes => :array2single do |*args|
    _mutated_isoforms = mutated_isoforms
    mi_damaged = Misc.process_to_hash(MutatedIsoform.setup(_mutated_isoforms.compact.flatten.uniq, organism)){|mis| mis.damaged?(*args)}
    mi_gene = Misc.process_to_hash(MutatedIsoform.setup(_mutated_isoforms.compact.flatten.uniq, organism)){|mis| mis.protein.gene}
    from_protein = _mutated_isoforms.collect{|mis|
      genes = mis.nil? ? [] : mi_gene.chunked_values_at(mis.clean_annotations.select{|mi| mi_damaged[mi]}).compact
      Gene.setup(genes.uniq, "Ensembl Gene ID", organism)
    }

    ej_transcripts =  transcripts_with_affected_splicing
    _type = self.type

    from_protein.each_with_index do |list, i|
      if ej_transcripts[i] and ej_transcripts[i].any? and _type[i] != 'none'
        list.concat ej_transcripts[i].gene
        list.uniq!
      end
    end

    Gene.setup(from_protein, "Ensembl Gene ID", organism)
  end

  property :transcripts_with_affected_splicing  => :array2single do
    return Transcript.setup([], "Ensembl Transcript ID", organism) if self.empty?
    exon2transcript_index = GenomicMutation.transcripts_for_exon_index(organism)
    transcript_exon_rank  = GenomicMutation.exon_rank_index(organism)

    _exon_junctions = self.exon_junctions
    transcripts = _exon_junctions.zip(self.type).collect{|junctions, type|
      if %w(unknown none).include?(type) or junctions.nil? or junctions.empty? 
        []
      else
        junctions.collect{|junction|
          exon, junction_type = junction.split(":")
          transcripts = exon2transcript_index[exon].first
          transcripts.select do |transcript|
            transcript_info = transcript_exon_rank[transcript]

            total_exons = transcript_info[0].length
            rank = transcript_info[1][transcript_info[0].index(exon)].to_i

            case
            when (rank == 1 and junction_type =~ /acceptor/)
              false
            when (rank == total_exons and junction_type =~ /donor/)
              false
            else
              true
            end
          end
        }.flatten
      end
    }
    Transcript.setup(transcripts, "Ensembl Transcript ID", organism)
  end

  property :in_exon_junction? => :array2single do |*args|
    gene = args.first
    if gene
      transcripts_with_affected_splicing.collect{|list| list.nil? ? false : list.gene.include?(gene)}
    else
      transcripts_with_affected_splicing.clean_annotations.collect{|list| list.nil? ? false : list.any?}
    end
  end

  property :damaging? => :array2single do |*args|
    all_mutated_isoforms = mutated_isoforms.compact.flatten
    damaged_mutated_isoforms = all_mutated_isoforms.any? ? all_mutated_isoforms.select_by(:damaged?, *args) : []
    transcripts_with_affected_splicing.zip(mutated_isoforms, self.type).collect do |exs, mis, type|
      (Array === exs and exs.any? and not type == "none") or
      (Array === mis and (damaged_mutated_isoforms & mis).any?)
    end
  end

  property :worst_consequence => :array2single do |*args|
    gene = args.first

    all_mutated_isoforms = mutated_isoforms.compact.flatten
    all_mutated_isoforms.extend AnnotatedArray

    all_mutated_isoforms = all_mutated_isoforms.select_by(:transcript){|trans| transcript.gene == gene} if gene and all_mutated_isoforms.any? and Entity === all_mutated_isoforms

    non_synonymous_mutated_isoforms = all_mutated_isoforms.select_by(:non_synonymous)
    truncated_mutated_isoforms = all_mutated_isoforms.select_by(:truncated)
    damage_scores = Misc.process_to_hash(non_synonymous_mutated_isoforms){|mis| mis.any? ? mis.damage_scores : []}
    damaged = all_mutated_isoforms.select_by(:damaged?, *args)

    in_exon_junction?(gene).zip(mutated_isoforms, type).collect{|ej,mis,type|
      case
      when (mis.nil? or mis.subset(non_synonymous_mutated_isoforms).empty? and ej and not type == 'none')
        "In Exon Junction"
      when (Array === mis and mis.subset(truncated_mutated_isoforms).any?)
        mis.subset(truncated_mutated_isoforms).first
      when (Array === mis and mis.subset(non_synonymous_mutated_isoforms).any?)
        mis.subset(non_synonymous_mutated_isoforms).sort{|mi1, mi2| 
          ds1 = damage_scores[mi1] || 0
          ds2 = damage_scores[mi2] || 0
          case
          when (damaged.include?(mi1) == damaged.include?(mi2))
            0
            #d1 = mi1.protein.interpro_domains || []
            #d2 = mi2.protein.interpro_domains || []
            #d1.length <=> d2.length
          else
            ds1 <=> ds2
          end
        }.last
      else
        nil
      end
    }
  end
end
