require 'net/http'
require 'net/https'

require 'stringio'
require 'zlib'

require 'rubygems'
require 'nokogiri'

class Oh
  VERSION = '1.0.2'

  HOST = "www2.optionshouse.com"

  HEADERS = {
    "Host" => HOST,
    "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12 (.NET CLR 3.5.30729)",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" => "en-us,en;q=0.5",
    "Accept-Encoding" => "gzip,deflate",
    "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "Connection" => "keep-alive",
    "Content-Type" => "text/xml; charset=UTF-8",
    "Referer" => "https://www.optionshouse.com/securehost/tool/login/",
    "Cookie" => "blackbird={pos:1,size:0,load:null,info:true,debug:true,warn:true,error:true,profile:true}",
    "Pragma" => "no-cache",
    "Cache-Control" => "no-cache",
  }

  attr_accessor :username, :password
  attr_writer :account_id

  def initialize(username, password)
    self.username = username
    self.password = password
  end

  def account_id
    @account_id or raise "Account not set; call Oh#accounts() to get a list, then set using Oh#account_id=(id)."
  end

  def token
    @token ||= login
  end

  def login
    response = request_without_callbacks(message("auth.login",
                    :userName => username,
                    :password => password,
                    :organization => "OPHOUSE,KERSHNER",
                    :authToken => nil,
                    :validationText => ""))

    access = response.search("//access").text
    raise AuthError, "Access was #{access}" unless access == "granted"

    ready = response.search("//requiresAccountCreation").text == "false"
    raise AccountError, "Account is not active" unless ready

    token = response.search("//authToken").text
    raise AuthError, "No auth token was returned" if token.strip.empty? or token == "null"

    token
  end

  def accounts
    request(message_with_token("account.info"))
  end

  def quote(symbol)
    request(messages(quote_messages(symbol)))
  end

  def option_chain(symbol)
    request(chain_message(symbol))
  end

  def quote_with_chain(symbol)
    request(messages(quote_messages(symbol), chain_message(symbol)))
  end

  # TODO: send this every 120 seconds?
  def keep_alive
    request(message_with_account("auth.keepAlive"))
  end

  def quote_messages(symbol)
    [
      message_with_account("view.quote",
                           :symbol => symbol,
                           :description => true,
                           :fundamentals => true),
      message_with_token("echo", :symbol => symbol)
    ]
  end

  def chain_message(symbol)
    message_with_account("view.chain",
                         :symbol => symbol,
                         :greeks => true,
                         :weeklies => true,
                         :quarterlies => true,
                         :quotesAfter => 0,
                         :ntm => 10, # near the money
                         :bs => true) # black-scholes?
  end

  def message_with_token(action, data = {})
    message(action, {:authToken => token}.merge(data))
  end

  def message_with_account(action, data = {})
    message_with_token(action, {:account => account_id}.merge(data))
  end

  def message(action, data = {})
    chunks = []

    chunks << "<EZMessage action='#{action}'>"
    chunks << "<data>"

    data.each do |key, value|
      chunks << "<#{key}>#{value || "null"}</#{key}>"
    end

    chunks << "</data>"
    chunks << "</EZMessage>"

    chunks.join
  end

  def messages(*messages)
    "<EZList>#{messages.flatten.join}</EZList>"
  end

  def request_without_callbacks(body)
    request(body, false)
  end

  def request(body, with_callbacks = true)
    path = "/m"

    response = connection.post(path, body, HEADERS)
    data = response.body

    out = case response["content-encoding"]
      when /gzip/    then Zlib::GzipReader.new(StringIO.new(data)).read
      when /deflate/ then Zlib::Inflate.inflate(data)
      else data
    end

    if $DEBUG
      puts "Sent:"
      puts body
      puts "-" * 80
      puts "Got"
      p response.code
      p response.message

      response.each {|key, val| puts key + ' = ' + val}

      puts out
      puts "=" * 80
      puts
    end

    result = begin
      Nokogiri.parse(out, nil, nil, Nokogiri::XML::ParseOptions::STRICT)
    rescue
      warn "Unable to parse: #{out.inspect}"
      raise
    end

    check_connection_status(result)

    with_callbacks && respond_to?(:post_process_request) ? 
      post_process_request(result) : 
      result
  end

  def check_connection_status(doc)
    if doc.at("//errors/access[text()='denied']")
      raise AuthError, "Access denied, token has expired?"
    end
  end

  def connection
    return @client if defined? @client

    client = Net::HTTP.new(HOST, 443)
    client.use_ssl = true

    if ENV["SSL_PATH"] && File.exist?(ENV["SSL_PATH"])
      client.ca_path = ENV["SSL_PATH"]
      client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    @client = client
  end

  AuthError = Class.new(StandardError)
  AccountError = Class.new(StandardError)

end
