require 'set'

class Module
  def def_method_missing(matcher = nil, &generator)
    self.def_method_missing_matcher case matcher
      when Regexp   then ->(name) { matcher.match(name, &generator) }
      when NilClass then generator
      else raise ArgumentError, %{Can't accept #{matcher.class} matchers}
    end
  end

  def def_method_missing_implementation_for(name)
    self.def_method_missing_matchers.keys.detect do |matcher|
      implementation = matcher.call(name)
      break implementation if implementation
    end
  end

  protected

  def def_method_missing_matchers
    @def_method_missing_matchers ||= Hash.new
  end

  def def_method_missing_matcher(matcher)
    self.def_method_missing_matchers[matcher] = 1
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

  def method_missing_with_def_method_missing(name, *args, &block)
    implementation =
      self.class.def_method_missing_implementation_for(name)

    if implementation
      self.class.class_eval { define_method(name, &implementation) }
      self.send(name, *args, &block)
    else
      method_missing_without_def_method_missing(name, *args, &block)
    end
  end

  alias method_missing_without_def_method_missing method_missing
  alias method_missing method_missing_with_def_method_missing
end
