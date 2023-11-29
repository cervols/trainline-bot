module ComThetrainline
  module TransportMode
    module_function

    def parse(transport_mode_id, transport_modes)
      transport_mode = transport_modes[transport_mode_id]

      transport_mode[:mode]
    end
  end
end
