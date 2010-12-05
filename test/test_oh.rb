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

  def test_request_doesnt_delegate_when_not_present
    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response("<response></response>")
    )

    flexmock(@oh) do |m|
      m.should_receive(:post_process_request).never
      m.should_receive(:respond_to?).
        with(:post_process_request).and_return(false)
    end

    @oh.request("<request></request>")
  end

  def test_request_delegates
    flexmock(Net::HTTP).new_instances.should_receive(
      :post => mocked_response("<response></response>")
    )

    flexmock(@oh) do |m|
      m.should_receive(:post_process_request).once
      m.should_receive(:respond_to?).
        with(:post_process_request).and_return(true)
    end

    @oh.request("<request></request>")
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

    old_stderr = $stderr
    $stderr = StringIO.new

    assert_raises Nokogiri::XML::SyntaxError do
      doc = @oh.request("<request></request>")
    end

    assert_match /Unable to parse/, $stderr.string

    $stderr = old_stderr
  end

  def test_request_sends_consistent_header_and_path
    m = flexmock("Net::HTTP instance")
    m.should_ignore_missing
    m.should_receive(:post).
      with("/m", "<request></request>", Oh::HEADERS).
      and_return(mocked_response("<response></response>")).
      once

    flexmock(Net::HTTP).should_receive(:new).once.and_return(m)

    @oh.request("<request></request>")
  end

  def test_connection_reuses_single_client
    assert_same @oh.connection, @oh.connection, "Should be cached"
  end

  def test_message
    msg = @oh.message("test.action", :foo => nil, :bar => 2)

    assert_match %r{<foo>null</foo>}, msg, "should convert nils to null"
    assert_match %r{<bar>2</bar>}, msg, "should to_s all other objects"
  end

  def test_messages
  end

  def test_account_raises_when_not_set
  end
end
