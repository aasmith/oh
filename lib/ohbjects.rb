# Adds an object representation to Oh responses:
#
#  require "ohbjects"
#  Ohbjects.activate
#
# Then, any further calls to Oh methods that used to
# return an XML doc will now return objects such as
# Ohbjects::Call, Ohbjects::Put, etc.
#
module Ohbjects
  REGISTRY = []

  module Buildable
    attr_reader :spec

    def builds(css_or_xpath)
      @spec = css_or_xpath
    end

    def build?(doc)
      !doc.search(@spec).empty?
    end

    def self.extended(extender)
      REGISTRY << extender
    end
  end

  class OptionBuilder
    extend Buildable

    builds "optionQuote"

    METHOD_LOOKUP = {
      :optionRoot  => :root,
      :strikePrice => :strike,
      :expDate     => :expires,
      :bidSize     => :bids,
      :askSize     => :asks
    }

    class << self
      def build(fragment)
        put, call = Put.new, Call.new

        fragment.attributes.each do |key, attr|
          match = key.match(/^(call|put)?(.*)$/)

          option_type, method = match.captures

          method = METHOD_LOOKUP[method.to_sym] || underscore(method)
          setter = "#{method}="

          value  = attr.value

          if option_type
            option = option_type == "call" ? call : put
            option.send(setter, value) if option.respond_to?(setter)
          else
            [put, call].each do |option|
              option.send(setter, value) if option.respond_to?(setter)
            end
          end
        end

        [put, call]
      end

      # Taken from active support.
      def underscore(camel_cased_word)
        camel_cased_word.to_s.
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end
  end

  class Option
    attr_accessor :id, :key, 
      :expires, :strike, :root,
      :bid, :ask, :change, :volume, :open_interest,
      :iv, :delta, :gamma, :theta, :vega,
      :bids, :asks

    def initialize
      if instance_of? Option
        raise ArgumentError, "An option cannot be instantiated"
      end
    end

    def expires=(date_string)
      # Intentionally explict pattern to force 
      # parse errors should the format change.
      Date.strptime(date_string, "%b %e, %Y")
    end

    def call?
      Call === self
    end

    def put?
      Put === self
    end
  end

  class Put < Option
  end

  class Call < Option
  end

  def objectify(doc)
    qualified_builders = 
      REGISTRY.select { |builder| builder.build?(doc) }

    objects = []

    qualified_builders.each do |builder|
      doc.search(builder.spec).each do |fragment|
        objects.push(*builder.build(fragment))
      end
    end

    objects
  end

  def post_process_request(result)
    objectify(result)
  end

  class << self
    def activate
      Oh.send :include, self
    end
  end
end
