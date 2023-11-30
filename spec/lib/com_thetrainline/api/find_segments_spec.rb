require 'rails_helper'

RSpec.describe ComThetrainline::Api::FindSegments do
  subject(:segments) { described_class.new(from, to, departure_at).segments }

  describe '#segments' do
    let(:from) { 'urn:trainline:eurostar:loc:8727100' }
    let(:to) { 'urn:trainline:eurostar:loc:7015400' }
    let(:departure_at) { DateTime.now }
    let(:url) { ComThetrainline::Api::FindSegments::SEARCH_URL }
    let(:birth_date) { ComThetrainline::Api::FindSegments::DEFAULT_DATE_OF_BIRTH }

    let(:expected_body) do
      {
        passengers: [
          {
            date_of_birth: birth_date
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
        type: 'single'
      }.to_json
    end

    context 'when there are no journeys in response' do
      before do
        allow_any_instance_of(ComThetrainline::Api::Client).to receive(:send_request)
          .and_return(ComThetrainline::DummyResponse::Client)
      end

      it 'calls client' do
        expect(ComThetrainline::Api::Client).to receive(:new).with(body: expected_body, url: url).and_call_original
        expect_any_instance_of(ComThetrainline::Api::Client).to receive(:send_request)

        segments
      end

      it 'returns not_found response' do
        response = segments

        expect(response.code).to eq(404)
        expect(response.message).to eq(ComThetrainline::Api::FindSegments::NOT_FOUND_MESSAGE)
      end
    end

    context 'when there are journeys in response' do
      let(:departure_at) { '2023-12-01T07:01:00+00:00'.to_datetime }
      let(:arrival_at) { '2023-12-01T10:21:00+01:00'.to_datetime }
      let(:base_price) { 16_177 }
      let(:expected_segment_data) do
        {
          departure_station: 'London St-Pancras',
          departure_at: departure_at,
          arrival_station: 'Paris Gare du Nord',
          arrival_at: arrival_at,
          service_agencies: ['Eurostar'],
          duration_in_minutes: 140,
          changeovers: 0,
          products: ['train'],
          fares: [
            {
              price_in_cents: expected_price,
              currency: 'USD',
              name: 'Standard',
              comfort_class: 'Standard'
            }
          ]
        }
      end

      before do
        allow_any_instance_of(EuCentralBank).to receive(:update_rates)
      end

      context 'and prices are in the default currency' do
        let(:expected_price) { base_price }
        let(:trainline_response) do
          File.read(Rails.root.join('spec', 'support', 'files', 'journeys_with_prices_in_usd.json'))
        end

        it 'returns array with segments data' do
          stub_request(:post, 'https://www.thetrainline.com/api/journey-search/')
            .to_return(status: 200, body: trainline_response, headers: {})

          expect(segments).to be_a(Array)
          expect(segments.count).to eq(15)
          expect(segments.first).to eq(expected_segment_data)
        end
      end

      context 'and prices are not in the default currency (EUR)' do
        let(:eur_to_usd_rate) { 1.1 }
        let(:expected_price) { (base_price * eur_to_usd_rate).round }
        let(:trainline_response) do
          File.read(Rails.root.join('spec', 'support', 'files', 'journeys_with_prices_in_eur.json'))
        end

        before do
          allow_any_instance_of(EuCentralBank).to receive(:get_rate)
            .and_return(eur_to_usd_rate)
        end

        it 'returns segments data with prices converted to default currency' do
          stub_request(:post, 'https://www.thetrainline.com/api/journey-search/')
            .to_return(status: 200, body: trainline_response, headers: {})

          expect(segments).to be_a(Array)
          expect(segments.count).to eq(1)
          expect(segments.first).to eq(expected_segment_data)
        end
      end
    end
  end
end
