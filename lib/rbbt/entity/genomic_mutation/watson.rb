module GenomicMutation

  property :guess_watson => :array do
    if Array === self
      @watson = Sequence.job(:is_watson, jobname, :mutations => self.clean_annotations, :organism => organism).run
    else
      @watson = Sequence.job(:is_watson, jobname, :mutations => [self.clean_annotations], :organism => organism).run
    end
  end

  def watson
    if @current_watson.nil?
      current = annotation_values[:watson]
      if current.nil? and Array === self
        watson = current = guess_watson
      else
        current
      end
      current = false if current == "false"
      @current_watson = current
    end
    @current_watson
  end

  def orig_watson
    @watson
  end

  property :to_watson => :array2single do
    if watson
      self
    else
      result = Sequence.job(:to_watson, jobname, :mutations => self.clean_annotations, :organism => organism).run 
      self.annotate(result)
      result
    end
  end

end
