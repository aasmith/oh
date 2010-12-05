require "test/unit"
require "flexmock/test_unit"

require "oh"
require "ohbjects"

class TestOhbjects < Test::Unit::TestCase

  def test_option_builder_claims_to_build_option_quote
    assert Ohbjects::OptionBuilder.build?(Nokogiri(OPTION_QUOTE))
  end

  def test_option_builder_build
    fragment = Nokogiri(OPTION_QUOTE).search(Ohbjects::OptionBuilder.spec).first

    options = Ohbjects::OptionBuilder.build(fragment)

    assert_equal 2, options.size, "Should have built two options"

    assert_equal [Ohbjects::Put, Ohbjects::Call], options.map{|x|x.class},
      "Should be a put and a call"

    put = options.shift
    call = options.shift

    # TODO: assert individual fields

  end

  def test_expires_date_conversion
    call = Ohbjects::Call.new
    call.expires = "Jan 12, 2011"

    assert_equal 12, call.expires.day
    assert_equal 1, call.expires.month
    assert_equal 2011, call.expires.year

    assert_raise ArgumentError, "other formats should be invalid" do
      call.expires = "2011-01-11"
    end
  end

  def test_cannont_instantiate_options_directly
    assert_nothing_raised "subclasses should be instantiable" do
      assert_kind_of Ohbjects::Option, Ohbjects::Call.new
      assert_kind_of Ohbjects::Option, Ohbjects::Put.new
    end

    ex = assert_raise ArgumentError do
      Ohbjects::Option.new
    end

    assert_match /cannot be instantiated/, ex.message
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
