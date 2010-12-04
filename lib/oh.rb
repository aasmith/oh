require 'net/http'
require 'net/https'

require 'stringio'
require 'zlib'

require 'rubygems'
require 'nokogiri'

class Oh
  VERSION = '1.0.0'

  HEADERS = {
    "Host" => "www.optionshouse.com",
    "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12 (.NET CLR 3.5.30729)",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" => "en-us,en;q=0.5",
    "Accept-Encoding" => "gzip,deflate",
    "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "Connection" => "keep-alive",
    "Content-Type" => "text/xml; charset=UTF-8",
    "Referer" => "https://www.optionshouse.com/tool/login/",
    "Cookie" => "blackbird={pos:1,size:0,load:null,info:true,debug:true,warn:true,error:true,profile:true}",
    "Pragma" => "no-cache",
    "Cache-Control" => "no-cache",
  }

  attr_accessor :username, :password
  attr_writer :account

  def initialize(username, password)
    self.username = username
    self.password = password
  end

  def account
    @account or raise "Account not set; call Oh#account_info() to get a list, then set using Oh#account=(id)."
  end

  def token
    @token ||= login
  end

  def login
    response = request(message("auth.login",
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

  def account_info
    # TODO: process response doc
    # Return list of accounts and ids
    request(message_with_token("account.info"))
  end

  def quote(symbol)
    request(message_with_account("view.quote",
                                 :symbol => symbol,
                                 :description => true,
                                 :fundamentals => true))
  end

  def option_chain(symbol)
    request(message_with_account("view.chain",
                                 :symbol => symbol,
                                 :greeks => true,
                                 :weeklies => true,
                                 :quarterlies => true,
                                 :quotesAfter => 0,
                                 :ntm => 10, # ?
                                 :bs => true)) # ?
  end

  def message_with_token(action, data = {})
    message(action, {:authToken => token}.merge(data))
  end

  def message_with_account(action, data = {})
    message_with_token(action, {:account => account}.merge(data))
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

  def messages(messages)
    "<EZList>#{messages.join}</EZList>"
  end

  def request(body)
    path = "/m"

    response = connection.post(path, body, HEADERS)
    data = response.body

    out = response["content-encoding"] =~ /gzip/ ? Zlib::GzipReader.new(StringIO.new(data)).read : data

    if $VERBOSE
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

    begin
      Nokogiri.parse(out, nil, nil, Nokogiri::XML::ParseOptions::STRICT)
    rescue
      warn "Unable to parse: #{out.inspect}"
      raise
    end
  end

  def connection
    return @client if @client

    client = Net::HTTP.new("www.optionshouse.com", 443)
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
