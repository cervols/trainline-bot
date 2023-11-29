module ComThetrainline
  module Carrier
    module_function

    def parse(carrier_id, carriers)
      carrier = carriers[carrier_id]

      carrier[:name]
    end
  end
end
