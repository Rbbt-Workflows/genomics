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
          value = Misc.prepare_entity(value, tsv.fields[i]) if tsv.fields
          value = value.name if value.respond_to? :name
          value
          i += 1
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

        i = 0
        values = values_list.collect do |values|
          values = Misc.prepare_entity(values, tsv.fields[i]) if tsv.fields
          i += 1
          values
        end
        values = values.name if values.respond_to? :name
        [k,values]
      end
    end
  end
end
