# frozen_string_literal: true

module ComThetrainline
  module Api
    class Client
      INTERNAL_SERVER_ERROR = 'Internal Server Error'

      BadResponse = Class.new(StandardError)

      attr_reader :body, :url, :response

      def initialize(body:, url:)
        @body = body
        @url = url
      end

      def send_request
        @response = HTTParty.post(
          url,
          body: body,
          headers: headers
        )

        raise BadResponse.new, "Bad response:\n#{response.inspect}" if error_response?

        response
      end

      private

        def error_response?
          response.code != 200
        end

        def headers
          { 'Content-Type' => 'application/json' }
        end
    end
  end
end

