Log.deprecated "do not require #{__FILE__}, require 'rbbt/knowledge_base/Genomics' instead. In: #{caller.reject{|l| l =~ /core_ext/}.first}"

require 'rbbt/knowledge_base/Genomics'
