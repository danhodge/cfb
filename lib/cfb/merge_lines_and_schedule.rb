require 'cfb'
require 'csv'
require 'json'
require 'time'

module CFB
  class MergeLinesAndSchedule
    def self.run(**kwargs)
      File.open(kwargs[:lines], 'r') do |lines|
        File.open(kwargs[:schedule], 'r') do |schedule|
          CSV.open("picks_#{CFB.year}.csv", 'w') do |csv|
            csv << ["ID", "Date", "Bowl", "Visitor", "Home", "Favorite", "Spread", "Choice", "Adjustment"]

            new(lines, schedule).each do |row|
              csv << row
            end
          end
        end
      end
    end

    def initialize(lines, schedule)
      @lines = JSON.load(lines).map { |data| Game.from_json(data) }
      @schedule = JSON.load(schedule).values.map do |data|
        Game.from_json(data)
      end
    end

    def each
      schedule.each_with_index do |game, i|
        if line = line_for(game)
          merged = game.merge(line)
          yield [
            i + 1,
            Time.parse(merged.time).to_date,
            merged.name,
            merged.visitor.name,
            merged.home.name,
            merged.favorite,
            merged.point_spread,
            '',
            ''
          ]
        else
          puts "Unable to find a line for game: #{game.name}"
          yield [
            i + 1,
            Time.parse(game.time).to_date,
            game.name,
            game.visitor.name,
            game.home.name,
            'UNKNOWN',
            'UNKNOWN',
            '',
            ''
          ]
        end
      end
    end

    private

    attr_reader :lines, :schedule

    def line_for(game)
      line = line_for_name(game.name) || line_for_name("#{game.name} bowl") || line_for_time(game.time)
      lines.delete(line)
    end

    def line_for_name(name)
      lines.find { |line| line.name.upcase == name.upcase }
    end

    def line_for_time(time)
      candidates = lines.select { |line| line.time == time }
      candidates.first if candidates.length == 1
    end
  end
end
