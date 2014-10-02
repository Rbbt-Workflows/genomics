Log.deprecated "do not require #{__FILE__}, require 'rbbt/knowledge_base/Genomics' instead. In: #{caller.select{|l| l =~ /rbbt|workflow/}.first}"

require 'rbbt/knowledge_base/Genomics'
