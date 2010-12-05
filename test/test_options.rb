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
  end
end
