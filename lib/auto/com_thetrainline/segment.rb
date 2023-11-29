module ComThetrainline
  module Segment
    module_function

    def parse(node, legs, locations)
      departure_at = departure_at(node)
      arrival_at = arrival_at(node)

      {
        changeovers: calculate_changeovers(node),
        departure_station: parse_departure_station(node, legs, locations),
        arrival_station: parse_arrival_station(node, legs, locations),
        departure_at: departure_at(node),
        arrival_at: arrival_at(node),
        duration_in_minutes: calculate_duration(departure_at, arrival_at)
      }
    end

    def calculate_changeovers(node)
      node[:legs].count - 1
    end

    def parse_departure_station(node, legs, locations)
      first_leg_id = node[:legs].first
      departure_station_id = legs[first_leg_id][:departureLocation]
      locations[departure_station_id][:name]
    end

    def parse_arrival_station(node, legs, locations)
      last_leg_id = node[:legs].last
      arrival_station_id = legs[last_leg_id][:arrivalLocation]
      locations[arrival_station_id][:name]
    end

    def departure_at(node)
      node[:departAt].to_datetime
    end

    def arrival_at(node)
      node[:arriveAt].to_datetime
    end

    def calculate_duration(departure_at, arrival_at)
      ((arrival_at - departure_at) * 24 * 60).to_i
    end
  end
end
