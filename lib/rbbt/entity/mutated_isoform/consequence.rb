module MutatedIsoform

  ASTERISK = "*"[0]
  CONSECUENCES = %w(UTR SYNONYMOUS NOSTOP MISS-SENSE INDEL FRAMESHIFT NONSENSE)
  property :consequence => :single2array do
    return nil if self.nil?

    prot, change = self.split(":")

    case
    when change.nil?
      nil
    when change =~ /^UTR\d$/
      "UTR"
    when (change[0] == ASTERISK and not change[0] == change[-1])
      "NOSTOP"
    when (change[-1] == ASTERISK and not change[0] == change[-1])
      "NONSENSE"
    when change =~ /Indel/
      "INDEL"
    when change =~ /FrameShift/
      "FRAMESHIFT"
    when change[0] == change[-1]
      "SYNONYMOUS"
    else
      "MISS-SENSE"
    end
  end

  property :in_utr => :array2single do
    consequence.collect{|c|
      c == "UTR"
    }
  end

  property :synonymous => :array2single do
    consequence.collect{|c|
      c == "SYNONYMOUS" or c == "UTR"
    }
  end

  property :non_synonymous => :array2single do
    consequence.collect{|c|
      not c.nil? and c != "SYNONYMOUS" and c != "UTR"
    }
  end

end
