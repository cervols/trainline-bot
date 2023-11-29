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

        attr_reader :from, :to, :departure_at, :response

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
              }
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
          journeys.map do |journey_data|
            journey_node = journey_data[1]

            segment = Segment.parse(journey_node, legs, locations)

            segment[:service_agencies] =
              journey_node[:legs].map do |leg_id|
                carrier_id = legs[leg_id][:carrier]

                Carrier.parse(carrier_id, carriers)
              end

            segment[:products] =
              journey_node[:legs].map do |leg_id|
                transport_mode_id = legs[leg_id][:transportMode]

                TransportMode.parse(transport_mode_id, transport_modes)
              end

            journey_section_ids = journey_node[:sections]

            cheapest_section_fares =
              journey_section_ids.map do |section_id|
                Fare.parse(fares, sections[section_id], alternatives)
              end

            cheapest_price = cheapest_section_fares.sum { |fare| fare[:price_in_cents] }

            segment[:fares] = [
              cheapest_section_fares.last.merge(
                price_in_cents: cheapest_price
              )
            ]

            segment
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
    end
  end
end
