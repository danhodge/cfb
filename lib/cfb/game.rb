module CFB
  Game = Struct.new(:name, :location, :time, :visitor, :home) do
    def self.from_json(json)
      new(
        json["name"],
        json["location"],
        json["time"],
        Team.from_json(json["visitor"]),
        Team.from_json(json["home"])
      )
    end

    def merge(game)
      merged = attributes.merge(game.attributes) do |key, old_val, new_val|
        if [:visitor, :home].include?(key)
          old_val.merge(new_val)
        else
          new_val || old_val
        end
      end

      self.class.new(*merged.values_at(:name, :location, :time, :visitor, :home))
    end

    def favorite
      if visitor.point_spread == home.point_spread
        'NONE'
      elsif visitor.point_spread < home.point_spread
        visitor.name
      else
        home.name
      end
    end

    def point_spread
      if visitor.point_spread == home.point_spread
        0
      elsif visitor.point_spread < home.point_spread
        visitor.point_spread.abs
      else
        home.point_spread.abs
      end
    end

    def attributes
      to_h.merge(visitor: visitor, home: home)
    end

    def to_h
      super.merge(visitor: visitor.to_h, home: home.to_h)
    end
  end
end
