# frozen_string_literal: true

module ComThetrainline
  module Api
    class FindSegments
      SEARCH_URL = 'https://www.thetrainline.com/api/journey-search/'
      DEFAULT_DATE_OF_BIRTH = '01/01/2000'
      DEFAULT_CURRENCY = 'USD'
      NOT_FOUND_MESSAGE = 'Result is not found'

      def initialize(from, to, departure_at)
        @from = from
        @to = to
        @departure_at = departure_at
      end

      def segments
        send_request
        parse_response
      end

      private

        attr_reader :from, :to, :departure_at, :client, :response, :response_body,
          :journeys, :sections, :alternatives, :legs, :fares, :carriers, :locations,
          :transport_modes

        def send_request
          @response = client.send_request
        end

        def client
          ComThetrainline::Api::Client.new(body: body, url: SEARCH_URL)
        end

        def body
          {
            passengers: [
              {
                date_of_birth: DEFAULT_DATE_OF_BIRTH
              }
            ],
            transitDefinitions: [
              {
                origin: from,
                destination: to,
                direction: 'outward',
                journeyDate: {
                  time: departure_at,
                  type: 'departAfter'
                }
              },
            ],
            type: 'single',
            requestedCurrencyCode: DEFAULT_CURRENCY
          }.to_json
        end

        def parse_response
          return not_found_response if missing_data?

          correct_response
        end

        def missing_data?
          response.code == 200 && journeys.blank?
        end

        def not_found_response
          Net::HTTPNotFound.new('', 404, NOT_FOUND_MESSAGE)
        end

        def response_body
          @response_body ||= Oj.load(response.body)['data'].with_indifferent_access
        end

        def correct_response
          journeys.map do |journey|
            result = {}

            journey_data = journey[1]
            journey_leg_ids = journey_data[:legs]

            result[:changeovers] = journey_leg_ids.count

            first_journey_leg_id = journey_leg_ids.first
            departure_station_id = legs[first_journey_leg_id][:departureLocation]
            result[:departure_station] = locations[departure_station_id][:name]

            last_journey_leg_id = journey_leg_ids.last
            arrival_station_id = legs[last_journey_leg_id][:arrivalLocation]
            result[:arrival_station] = locations[arrival_station_id][:name]

            departure_at = journey_data[:departAt].to_datetime
            arrival_at = journey_data[:arriveAt].to_datetime

            result[:departure_at] = departure_at
            result[:arrival_at] = arrival_at
            result[:duration_in_minutes] = ((arrival_at - departure_at) * 24 * 60).to_i

            result[:service_agencies] = []
            result[:products] = []

            journey_leg_ids.map do |leg_id|
              carrier_id = legs[leg_id][:carrier]
              result[:service_agencies] << carriers[carrier_id][:name]
              transport_mode_id = legs[leg_id][:transportMode]
              result[:products] << transport_modes[transport_mode_id][:mode]
            end

            journey_section_ids = journey_data[:sections]

            cheapest_section_fares =
              journey_section_ids.map do |section_id|
                cheapest_section_alternative_id = sections[section_id][:alternatives].first
                cheapest_section_alternative = alternatives[cheapest_section_alternative_id]

                price = cheapest_section_alternative[:fullPrice][:amount]
                currency = cheapest_section_alternative[:fullPrice][:currencyCode]
                fare_id = cheapest_section_alternative[:fares].first
                fare = fares[fare_id]
                fare_leg = fare[:fareLegs].first

                cheapest_section_fare = {
                  price_in_cents: price_in_cents(price, currency),
                  currency: currency,
                  name: fare_leg[:travelClass][:name],
                  comfort_class: fare_leg[:comfort][:name]
                }
              end

            cheapest_price = cheapest_section_fares.sum { |fare| fare[:price_in_cents] }
            result[:fares] = [cheapest_section_fares.last.merge(price_in_cents: cheapest_price)]

            result
          end
        end

        def journeys
          @journeys ||= response_body.dig(:journeySearch, :journeys)
        end

        def sections
          @sections ||= response_body.dig(:journeySearch, :sections)
        end

        def alternatives
          @alternatives ||= response_body.dig(:journeySearch, :alternatives)
        end

        def legs
          @legs ||= response_body.dig(:journeySearch, :legs)
        end

        def fares
          @fares ||= response_body.dig(:journeySearch, :fares)
        end

        def carriers
          @carriers ||= response_body[:carriers]
        end

        def locations
          @locations ||= response_body[:locations]
        end

        def transport_modes
          @transport_modes ||= response_body[:transportModes]
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
end
