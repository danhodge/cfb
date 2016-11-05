module CFB
  Pick = Struct.new(:game, :team, :points) do
    def as_json
      { game_name: game.name, team_name: team.name, points: points }
    end
  end
end
