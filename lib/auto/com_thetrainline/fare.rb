module ComThetrainline
  module Fare
    DEFAULT_CURRENCY = 'USD'

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
        currency: DEFAULT_CURRENCY,
        name: fare_leg.dig(:travelClass, :name),
        comfort_class: fare_leg.dig(:comfort, :name)
      }
    end

    def cheapest_alternative(section, alternatives)
      cheapest_alternative_id = section[:alternatives].first

      alternatives[cheapest_alternative_id]
    end

    def price_in_cents(price, currency)
      return (price * 100).to_i if default_currency?(currency)

      setup_money_exchange_rates

      convert_to_default_currency(price, currency)
    end

    def default_currency?(currency)
      currency == DEFAULT_CURRENCY
    end

    def setup_money_exchange_rates
      return if Money.default_bank.is_a?(EuCentralBank)

      eu_bank = EuCentralBank.new
      eu_bank.update_rates

      Money.default_bank = eu_bank
    end

    def convert_to_default_currency(price, currency)
      Money.from_amount(price, currency).exchange_to(DEFAULT_CURRENCY).cents
    rescue Money::Currency::UnknownCurrency, Money::Bank::UnknownRate
      0
    end
  end
end
