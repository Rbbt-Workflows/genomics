require 'rbbt'
require 'rbbt/workflow'
require 'rbbt/entity'
require 'rbbt/sources/organism'

require 'rbbt/entity/gene'

require 'genomics_kb'

module Genomics
  extend Workflow

  input :tsv, :tsv, "TSV file to name", nil
  task :names => :tsv do |tsv|

    named_fields = tsv.all_fields.select{|f| Entity.formats.include? f }
    named_field_pos = named_fields.collect{|f| tsv.identify_field f }

    if named_fields and named_fields.any?
      named_field_pos.delete :key
      tsv.unnamed = false
      new = {}
      tsv.through do |k, values|
        key = k.respond_to?(:name) ? k.name : k
        case values
        when Array
          named_field_pos.each do |pos|
            values[pos].replace(values[pos].name || values[pos]) if values[pos].respond_to? :name
          end
          new[key] = values
        else
          new[key] = values.name
        end
      end

      tsv = tsv.annotate new
    end

    tsv
  end
  export_asynchronous :names
end
