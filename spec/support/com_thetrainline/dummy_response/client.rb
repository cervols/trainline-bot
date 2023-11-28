module ComThetrainline
  module DummyResponse
    class Client
      def self.code
        200
      end

      def self.body
        {
          data: {
            journeySearch: {
              journeys: {},
              alternatives: {},
              fares: {},
              legs: {},
              sections: {}
            },
            carriers: {},
            locations: {},
            transportModes: {}
          }
        }.deep_stringify_keys.to_json
      end
    end
  end
end
