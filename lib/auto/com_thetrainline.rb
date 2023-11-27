module ComThetrainline
  module_function

  def find(from, to, departure_at)
    ComThetrainline::Api::FindSegments.new(from, to, departure_at).segments
  end
end
