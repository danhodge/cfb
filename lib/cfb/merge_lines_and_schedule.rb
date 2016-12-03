require 'cfb'
require 'csv'
require 'json'
require 'time'

module CFB
  class MergeLinesAndSchedule
    def self.run(**kwargs)
      File.open(kwargs[:lines], 'r') do |lines|
        File.open(kwargs[:schedule], 'r') do |schedule|
          CSV.open('picks.csv', 'w') do |csv|
            csv << ["Date", "Bowl", "Visitor", "Home", "Favorite", "Spread", "Choice", "Adjustment"]

            new(lines, schedule).each do |row|
              csv << row
            end
          end
        end
      end
    end

    def initialize(lines, schedule)
      @lines = JSON.load(lines).map { |data| Game.from_json(data) }
      @schedule = JSON.load(schedule).map { |data| Game.from_json(data) }
    end

    def each
      schedule.each do |game|
        if line = line_for(game)
          merged = game.merge(line)
          yield [
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
