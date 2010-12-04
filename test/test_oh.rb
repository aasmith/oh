require "test/unit"
require "flexmock/test_unit"
require "oh"

class TestOh < Test::Unit::TestCase
  def setup
    @oh = Oh.new("bob", "secret")
  end

  def mocked_response(data, headers = {})
    response = headers.dup

    class << response
      attr_accessor :body
    end

    response.body = data
    response
  end

  def test_request_handles_gzip
    io = StringIO.new

    z = Zlib::GzipWriter.new(io)
    z.write "<response></response>"
    z.close

    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response(
        io.string, 
        "content-encoding" => "gzip"
    ))

    doc = @oh.request("<request></request>")

    assert_equal "response", doc.root.name,
      "should have document with a root node of response"
  end

  def test_request_handles_deflate
    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response(
        Zlib::Deflate.deflate("<response></response>"),
        "content-encoding" => "deflate"
    ))

    doc = @oh.request("<request></request>")

    assert_equal "response", doc.root.name,
      "should have document with a root node of response"
  end

  def test_request_handles_plaintext
    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response("<response></response>")
    )

    doc = @oh.request("<request></request>")

    assert_equal "response", doc.root.name,
      "should have document with a root node of response"
  end

  def test_request_raises_with_malformed_xml
    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response("<invalid></xml>")
    )

    assert_raises Nokogiri::XML::SyntaxError do
      doc = @oh.request("<request></request>")
    end

  end

  def test_request_sends_consistent_header_and_path
  end

  def test_request_parses_output
  end

  def test_connection_reuses_single_client
    assert_same @oh.connection, @oh.connection,
      "Should be the same instance"
  end
end
