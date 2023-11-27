require 'rails_helper'

RSpec.describe ComThetrainline::Api::FindSegments do
  describe '#segments' do
    let(:from) { 'urn:trainline:eurostar:loc:8727100' }
    let(:to) { 'urn:trainline:eurostar:loc:7015400' }
    let(:departure_at) { DateTime.now }
    let(:url) { ComThetrainline::Api::FindSegments::SEARCH_URL }
    let(:birth_date) { ComThetrainline::Api::FindSegments::DEFAULT_DATE_OF_BIRTH }
    let(:currency) { ComThetrainline::Api::FindSegments::DEFAULT_CURRENCY }

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
          },
        ],
        type: 'single',
        requestedCurrencyCode: currency
      }.to_json
    end

    before do
      allow_any_instance_of(ComThetrainline::Api::Client).to receive(:send_request)
        .and_return(ComThetrainline::DummyResponse::Client)
    end

    describe '#segments' do
      it 'calls client' do
        expect(ComThetrainline::Api::Client).to receive(:new).with(body: expected_body, url: url).and_call_original
        expect_any_instance_of(ComThetrainline::Api::Client).to receive(:send_request)

        described_class.new(from, to, departure_at).segments
      end
    end
  end
end
