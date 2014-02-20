require 'rbbt'
require 'rbbt/workflow'
require 'rbbt/entity'
require 'rbbt/sources/organism'

require 'genomics_kb'

module Genomics
  extend Workflow

  input :tsv, :tsv, "TSV file to name", nil
  task :names => :tsv do |tsv|

    named_fields = tsv.fields.select{|f| Entity.formats.include? f }
    named_field_pos = named_fields.collect{|f| tsv.identify_field f}

    if named_fields and named_fields.any?
      tsv.unnamed = false
      new = {}
      tsv.each do |k, values|
        key = k.respond_to?(:name) ? k.name : k
        case values
        when Array
          named_field_pos.each do |pos|
            values[pos].replace(values[pos].name || values[pos])
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
