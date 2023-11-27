require 'rails_helper'

RSpec.describe ComThetrainline do
  let(:from) { 'urn:trainline:eurostar:loc:8727100' }
  let(:to) { 'urn:trainline:eurostar:loc:7015400' }
  let(:departure_at) { DateTime.now }

  subject { described_class.find(from, to, departure_at) }

  describe ".find" do
    it 'calls ComThetrainline::Api::FindSegments ' do
      expect(ComThetrainline::Api::FindSegments).to receive(:new).with(from, to, departure_at).and_call_original
      expect_any_instance_of(ComThetrainline::Api::FindSegments).to receive(:segments)

      subject
    end
  end
end
