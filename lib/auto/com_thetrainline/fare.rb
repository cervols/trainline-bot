module ComThetrainline
  module Fare
    module_function

    def parse(fares, section, alternatives)
      cheapest_section_fare_data(fares, section, alternatives)
    end

    def cheapest_section_fare_data(fares, section, alternatives)
      cheapest_alternative = cheapest_alternative(section, alternatives)

      price = cheapest_alternative.dig(:fullPrice, :amount)
      currency = cheapest_alternative.dig(:fullPrice, :currencyCode)
      fare_id = cheapest_alternative[:fares].first
      fare = fares[fare_id]
      fare_leg = fare[:fareLegs].first

      {
        price_in_cents: price_in_cents(price, currency),
        currency: currency,
        name: fare_leg.dig(:travelClass, :name),
        comfort_class: fare_leg.dig(:comfort, :name)
      }
    end

    def cheapest_alternative(section, alternatives)
      cheapest_alternative_id = section[:alternatives].first

      alternatives[cheapest_alternative_id]
    end

    def price_in_cents(price, currency)
      case currency
      when 'USD'
        price * 100
      else
        0
      end.to_i
    end
  end
end
