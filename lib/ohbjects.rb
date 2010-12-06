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

Dir[File.join(File.dirname(__FILE__), 'ohbjects', '*.rb')].each do |fn|
  require fn
end

