require 'rbbt'
require 'rbbt/workflow'
require 'rbbt/entity'
require 'rbbt/sources/organism'

require 'rbbt/entity/gene'
require 'rbbt/entity/genomic_mutation'

require 'genomics_kb'

module Genomics
  extend Workflow

  input :tsv, :tsv, "TSV file to name", nil, :stream => true
  task :names => :tsv do |tsv|
    tsv = TSV::Parser.new tsv if IO === tsv

    named = TSV::Dumper.new tsv.options, path
    named.init

    case tsv.type
    when :single
      TSV.traverse tsv, :into => named do |k,value|
        k = k.first if Array === k
        k = Misc.prepare_entity(k, tsv.key_field) if tsv.key_field
        k = k.name if k.respond_to? :name

        value = Misc.prepare_entity(value, tsv.fields.first) if tsv.fields
        value = value.name if value.respond_to? :name

        [k,value]
      end
    when :list
      TSV.traverse tsv, :into => named do |k,list|
        k = k.first if Array === k
        k = Misc.prepare_entity(k, tsv.key_field) if tsv.key_field
        k = k.name if k.respond_to? :name

        i = 0
        values = list.collect do |value|
          begin
            value = Misc.prepare_entity(value, tsv.fields[i]) if tsv.fields
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
        k = Misc.prepare_entity(k, tsv.key_field) if tsv.key_field
        k = k.name if k.respond_to? :name

        values = Misc.prepare_entity(values, tsv.fields.first) if tsv.fields
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
        k = Misc.prepare_entity(k, tsv.key_field) if tsv.key_field
        k = k.name if k.respond_to? :name

        if fields
          i = 0
          new_value_list = values_list.collect do |values|
            begin
              values = Misc.prepare_entity(values, fields[i]) 
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
    end
  end
  export_synchronous :names
end
