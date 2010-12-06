module Ohbjects
  class QuoteBuilder
    extend Buildable

    builds "//data/quote"

    class << self
      def build(fragment)
        quote = Quote.new

        fragment.attributes.each do |key, attr|
          method = "#{underscore(key)}="

          next unless quote.respond_to?(method)

          quote.send(method, attr.value)
        end

        quote.description = 
          fragment.attributes["shortDescription"].value

        quote
      end
    end
  end

  class Quote
    attr_accessor :symbol, :bid, :ask, :volume, :prev_close, :last, 
      :open, :high, :low, :today_close, :description
  end

  # TODO: today_close will be 0 until today has actually closed.
  # TODO: many more attributes
  # TODO: field conversion
end
