class Module
  def def_method_missing(pattern_or_lambda, &implementation)
    def_method_missing_matchers[pattern_or_lambda] = implementation
  end

  def def_method_missing_matchers
    @def_method_missing_matchers ||= {}
  end

  def def_method_missing_implementation_for(method)
    self.def_method_missing_matchers.detect do |matcher, implementation|
      case matcher
        when Proc then matcher.call(method)
        else           Regexp.new(matcher) =~ method
      end
    end.to_a.last
  end
end

class Object
  def respond_to_with_def_method_missing?(method)
    respond_to_without_def_method_missing?(method) or
      not self.class.def_method_missing_implementation_for(method).nil?
  end

  alias respond_to_without_def_method_missing? respond_to?
  alias respond_to? respond_to_with_def_method_missing?

  private

  def method_missing_with_def_method_missing(method, *args, &block)
    implementation =
      self.class.def_method_missing_implementation_for(method)

    if implementation
      self.class.class_eval { define_method(method, &implementation) }
      self.send(method, *args, &block)
    else
      method_missing_without_def_method_missing(method, *args, &block)
    end
  end

  alias method_missing_without_def_method_missing method_missing
  alias method_missing method_missing_with_def_method_missing
end
