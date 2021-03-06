require 'spec_helper'
require 'def_method_missing'

describe Object do
  subject do
    Object.new
  end

  it 'must continue to use method_missing' do
    def subject.method_missing(method, *args, &block)
      [ method, *args ]
    end

    subject.foo(1).must_equal [ :foo, 1 ]
  end
end

describe 'Object with method missing patterns' do
  subject do
    Class.new do
      def_method_missing(/foo/)  {|match| -> { match[0] } }
      def_method_missing(/bar/)  {|match| -> { match[0] } }
      def_method_missing(/baz$/) {|match| -> { match[0] } }
    end.new
  end

  it 'must respond to matching method names' do
    subject.must_respond_to('foo')
    subject.must_respond_to('foobar')
    subject.must_respond_to('barfoo')
    subject.must_respond_to('fofoofo')
    subject.must_respond_to('bar')
    subject.must_respond_to('abbarra')
    subject.must_respond_to('babaz')
  end

  it 'must not respond to non-matching method names' do
    subject.wont_respond_to('fo')
    subject.wont_respond_to('ba')
    subject.wont_respond_to('baaar')
    subject.wont_respond_to('bazaz')
    subject.wont_respond_to('test')
  end

  it 'must implement matching method names' do
    subject.foo   .must_equal 'foo'
    subject.barfoo.must_equal 'foo'
    subject.bar   .must_equal 'bar'
    subject.abbbaz.must_equal 'baz'
  end

  it 'must match in the defined order' do
    subject.foobar.must_equal 'foo'
    subject.foobaz.must_equal 'foo'
    subject.barbaz.must_equal 'bar'
  end

  it 'must bypass method_missing after the first call' do
    -> { subject.method(:foo) }.must_raise NameError
    subject.foo
    subject.method(:foo).must_be_kind_of Method
  end
end