require "test/unit"
require "flexmock/test_unit"

require "oh"
require "ohbjects"

class TestOhbjects < Test::Unit::TestCase

  def test_objectify
    o = Object.new
    class << o
      include Ohbjects
    end

    klass = Class.new

    klass.instance_eval do
      extend Ohbjects::Buildable
      builds "foo"
    end

    flexmock(klass).should_receive(:build => "built-foo").once

    Ohbjects::REGISTRY.clear
    Ohbjects::REGISTRY << klass

    output = o.objectify(Nokogiri("<doc><foo /></doc>"))

    assert_equal %w(built-foo), output
  end

  def test_activate_includes_ohbjects_into_oh
    flexmock(Oh).should_receive(:include).with(Ohbjects).once

    Ohbjects.activate
  end

  def test_buildable_build?
    klass = Class.new

    klass.instance_eval do
      extend Ohbjects::Buildable
      builds "foo"
    end

    assert klass.build?(Nokogiri("<doc><foo></foo></doc>"))
    assert !klass.build?(Nokogiri("<doc><bar></bar></doc>"))
  end

  def test_buildable_adds_to_registry
    before = Ohbjects::REGISTRY.size

    klass = Class.new

    klass.instance_eval do
      extend Ohbjects::Buildable
      builds "foo"
    end

    assert_equal before + 1, Ohbjects::REGISTRY.size
    assert_equal klass, Ohbjects::REGISTRY.pop
  end
end
