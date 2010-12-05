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


  OPTION_QUOTE = <<-XML
    <optionQuote id="201012180000090000AA"
      series="Dec 10 9.0" strikeString="9.0" optionRoot="AA"
      expYear="40" expMonth="12" expDay="18" strikePrice="90000"
      dte="14" expDate="Dec 18, 2010" callKey="AA:20101218:90000:C"
      callBid="5.10" callAsk="5.20" callChange="0.07" callVolume="0"
      callOpenInterest="38" putKey="AA:20101218:90000:P" putBid="0.00"
      putAsk="0.01" putChange="0.00" putVolume="0" putOpenInterest="86"
      callIv="29.1" callDelta="1" callGamma="0" callTheta="0"
      callVega="0" putIv="32.2" putDelta="0" putGamma="0" putTheta="0"
      putVega="0" callBidSize="821" callAskSize="1085" putBidSize="0"
      putAskSize="245" trimSet="2"/>
  XML
end
