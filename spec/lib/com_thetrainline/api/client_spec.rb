require 'rails_helper'

RSpec.describe ComThetrainline::Api::Client do
  subject { described_class.new(body: {}, url: url) }

  describe '#send_request' do
    let(:url) { ComThetrainline::Api::FindSegments::SEARCH_URL }

    context 'success' do
      it "sends successful request to Trainline" do
        stub_request(:post, "https://www.thetrainline.com/api/journey-search/")
          .to_return(status: 200, body: '', headers: {})

        response = subject.send_request

        expect(response.code).to eq(200)
      end
    end

    context 'failure' do
      it "sends request to Trainline and raises correct exception" do
        stub_request(:post, "https://www.thetrainline.com/api/journey-search/")
          .to_return(status: 401, body: '', headers: {})

        expect do
          subject.send_request
        end.to raise_error(ComThetrainline::Api::Client::BadResponse)
      end
    end
  end
end
