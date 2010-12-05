require "test/unit"
require "flexmock/test_unit"

require "oh"
require "ohbjects"

class TestOhbjects < Test::Unit::TestCase

  def test_option_builder_claims_to_build_option_quote
    assert Oh::OptionBuilder.build?(Nokogiri(OPTION_QUOTE))
  end

  def test_option_builder_build
    fragment = Nokogiri(OPTION_QUOTE).search(Oh::OptionBuilder.spec).first

    options = Oh::OptionBuilder.build(fragment)

    assert_equal 2, options.size, "Should have built two options"

    assert_equal [Oh::Put, Oh::Call], options.map{|x|x.class},
      "Should be a put and a call"

    put = options.shift
    call = options.shift

    # ...

  end

  def test_objectify
    oh = Oh.new("bob", "password")

    klass = Class.new

    klass.instance_eval do
      extend Oh::Buildable
      builds "foo"
    end

    flexmock(klass).should_receive(:build => "build-output").once

    Oh::REGISTRY.clear
    Oh::REGISTRY << klass

    output = oh.objectify(Nokogiri("<doc><foo /></doc>"))

    assert_equal %w(build-output), output
  end

  def test_buildable_build?
    klass = Class.new

    klass.instance_eval do
      extend Oh::Buildable
      builds "foo"
    end

    assert klass.build?(Nokogiri("<doc><foo></foo></doc>"))
    assert !klass.build?(Nokogiri("<doc><bar></bar></doc>"))
  end

  def test_buildable_adds_to_registry
    before = Oh::REGISTRY.size

    klass = Class.new

    klass.instance_eval do
      extend Oh::Buildable
      builds "foo"
    end

    assert_equal before + 1, Oh::REGISTRY.size
    assert_equal klass, Oh::REGISTRY.pop
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
