module CFB
  Team = Struct.new(:name, :wins, :losses, :ranking, :point_spreads) do
    def attributes
      to_h
    end

    def point_spread
      return 'UNKNOWN' if point_spreads.nil? || point_spreads.empty?

      sum = point_spreads.reduce(0, :+)
      (sum / point_spreads.count).round(1)
    end

    def merge(team)
      merged = attributes.merge(team.attributes) { |_, old_val, new_val| new_val || old_val }

      self.class.new(
        *merged.values_at(:name, :wins, :losses, :ranking, :point_spreads)
      )
    end
  end
end
