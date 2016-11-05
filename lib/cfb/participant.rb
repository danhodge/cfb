module CFB
  Participant = Struct.new(:name, :tie_breaker, :picks) do
    def as_json
      json = { name: name, tie_breaker: tie_breaker }
      json[:picks] = picks.map { |pick| pick.as_json }

      json
    end
  end
end
