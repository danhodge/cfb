require 'cfb'
require 'date'
require 'json'
require 'logger'
require 'mechanize'

module CFB
  class ScrapePicks
    Result = Struct.new(:games, :participants) do
      def add_participant(participant)
        self.participants << participant
      end
    end

    def self.run(*args)
      year_indicator = (args[0] || 'current').to_sym

      scraper = new(year_indicator: year_indicator)
      result = scraper.scrape

      results = result.games.sort_by { |game| game.time }.each_with_index.map do |game, i|
        [
          i,
          {
            name: game.name,
            location: game.location,
            time: game.time,
            visitor: { name: game.visitor.name, score: nil },
            home: { name: game.home.name, score: nil }
          }
        ]
      end.to_h

      File.open("results_#{scraper.year}.json", "w") { |file| file << JSON.pretty_generate(results) }

      unless result.participants.empty?
        File.open("participants_#{scraper.year}.json", 'w') do |file|
          file << result.participants.map { |p| p.as_json }.to_json
        end
      end
    end

    def initialize(url: 'http://broadjumper.com/family_fun.html', year_indicator:)
      @base_url = url
      @year_indicator = year_indicator
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
    end

    def year
      @year ||= begin
                  if year_indicator == :current
                    CFB.year
                  elsif year_indicator == :previous
                    CFB.year - 1
                  end
                end
    end

    def scrape
      extract_picks(load_page_for_year_indicator)
    end

    def extract_picks(page)
      table = page.search('//table').first

      result = Result.new([], [])

      table.search('//tr').each_with_index do |row, i|
        case i
        when 0
          # 0 = games
          result.games = row.search('td').drop(1).map { |cell| Game.new(cell.text) }
        when 1
          # 1 = locations
          row.search('td').drop(1).each_with_index { |cell, j| result.games[j].location = cell.text }
        when 2
          # 2 = date/time
          row.search('td').drop(1).each_with_index do |cell, j|
            date_time = cell.children[0].children.map(&:text).values_at(0, 2).join(' ')
            game_year = date_time.start_with?('Dec') ? year : year + 1
            result.games[j].time = DateTime.strptime("#{game_year} #{date_time} -0500", '%Y %b. %d %I:%M %p %z').iso8601
          end
        # 3 = TV
        # 4 = Result
        when 5
          # 5 = teams
          row.search('td').drop(1).each_slice(2).each_with_index do |(visitor, home), j|
            result.games[j].visitor = Team.new(visitor.text)
            result.games[j].home = Team.new(home.text)
          end
        when 6
          # 6 = records
          row.search('td').drop(1).each_slice(2).take(result.games.size).each_with_index do |(visitor, home), j|
            result.games[j].visitor.wins, result.games[j].visitor.losses = visitor.text.gsub(/\(/, '').gsub(/\)/, '').split('-')
            result.games[j].home.wins, result.games[j].home.losses = home.text.gsub(/\(/, '').gsub(/\)/, '').split('-')
          end
        when -> (n) { n >= 8 }
          # rows 8 - end are participants
          cells = row.search('td')
          handle_participant(result, cells)
        end
      end

      result
    end

    private

    attr_reader :base_url, :year_indicator, :logger, :agent

    def load_page_for_year_indicator
      page = agent.get("#{base_url}")

      if year_indicator == :current && page.search('//h3').map(&:text).include?("No results for this Year")
        raise 'No results are available for the current year'
      elsif year_indicator == :previous
        if link = page.link_with(text: "View Previous Year's Results.")
          link.click
        else
          raise 'No results available for the previous year'
        end
      end

      page
    end

    def handle_participant(result, cells)
      picks = cells.drop(1).take(result.games.count * 2).each_slice(2).each_with_index.map do |(visitor, home), i|
        visitor_points = visitor.text
        home_points = home.text

        if visitor_points.length > 0
          Pick.new(result.games[i], result.games[i].visitor, visitor_points.to_i)
        elsif home_points.length > 0
          Pick.new(result.games[i], result.games[i].home, home_points.to_i)
        end
      end

      name = cells[0].text
      if picks.length == result.games.length && picks.compact.length == picks.length
        tie_breaker = cells.drop(3 + (result.games.count * 2)).first.text
        result.add_participant(Participant.new(name, tie_breaker, picks))
      else
        logger.error "Ignoring participant: #{name} due to missing picks"
      end
    end
  end
end
