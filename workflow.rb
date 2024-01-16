require 'rbbt'
require 'rbbt/workflow'
require 'rbbt/entity'
require 'rbbt/sources/organism'

require 'rbbt/entity/gene'
require 'rbbt/entity/genomic_mutation'

require 'rbbt/knowledge_base/Genomics'

require 'Genomics/tasks/sample.rb' if defined?(Sample) && Workflow === Sample
require 'Genomics/entity/sample.rb' if defined?(Sample) && Entity === Sample

require 'Genomics/tasks/study.rb' if defined?(Study) && Workflow === Study
require 'Genomics/entity/study.rb' if defined?(Study) && Entity === Study

module Genomics
  extend Workflow

  input :tsv, :tsv, "TSV file to name", nil, :stream => true
  input :field, :string, "Field name for lists", nil
  input :organism, :string, "Organism code", nil
  desc <<-EOF
Takes a TSV files and, guided by the column headers, changes identifiers of different entities to
their human-friendly names.
  EOF
  def self.names(tsv, field = nil, organism = nil)
    tsv = TSV::Parser.new tsv if IO === tsv
    tsv.namespace = organism if organism
    tsv.namespace = Organism.default_code("Hsa") if tsv.namespace.nil?

    named = TSV::Dumper.new tsv.options, tsv.filename
    named.init

    if (tsv.fields.nil? or tsv.fields.empty?) and field
      keys = []
      TSV.traverse tsv, :type => :keys do |k|
        keys << k
      end
      keys = Misc.prepare_entity(keys, field)
      keys.extend AnnotatedArray
      TSV.setup(keys.name, :key_field => field, :namespace => organism)
    else

      case tsv.type
      when :single
        TSV.traverse tsv, :into => named do |k,value|
          k = k.first if Array === k
          k = Misc.prepare_entity(k, tsv.key_field, :organism => tsv.namespace) if tsv.key_field
          k = k.name if k.respond_to? :name

          value = Misc.prepare_entity(value, tsv.fields.first, :organism => tsv.namespace) if tsv.fields
          value = value.name if value.respond_to? :name

          [k,value]
        end
      when :list
        TSV.traverse tsv, :into => named do |k,list|
          k = k.first if Array === k
          k = Misc.prepare_entity(k, tsv.key_field, :organism => tsv.namespace) if tsv.key_field
          k = k.name if k.respond_to? :name

          i = 0
          values = list.collect do |value|
            begin
              value = Misc.prepare_entity(value, tsv.fields[i], :organism => tsv.namespace) if tsv.fields
              value = value.name if value.respond_to? :name
              value
            ensure
              i += 1
            end
          end
          [k,values]
        end
      when :flat
        TSV.traverse tsv, :into => named do |k,values|
          k = k.first if Array === k
          k = Misc.prepare_entity(k, tsv.key_field, :organism => tsv.namespace) if tsv.key_field
          k = k.name if k.respond_to? :name

          values = Misc.prepare_entity(values, tsv.fields.first, :organism => tsv.namespace) if tsv.fields
          begin
            values = values.name if values.respond_to? :name
          rescue
            Log.exception $!
          end

          [k,values]
        end
      when :double
        fields = tsv.fields.dup if tsv.fields
        TSV.traverse tsv, :into => named do |k,values_list|
          k = k.first if Array === k
          k = Misc.prepare_entity(k, tsv.key_field, :organism => tsv.namespace) if tsv.key_field
          k = k.name if k.respond_to? :name

          if fields
            i = 0
            new_value_list = values_list.collect do |values|
              begin
                values = Misc.prepare_entity(values, fields[i], :organism => tsv.namespace) 
                if values.respond_to? :name
                  values.name
                else
                  values
                end
              ensure
                i += 1
              end
            end
            [k,new_value_list]
          else
            [k,values_list]
          end
        end
      end.stream
    end
  end
  task :names => :tsv 
  export_synchronous :names
end

