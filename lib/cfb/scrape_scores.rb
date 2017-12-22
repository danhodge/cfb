require 'cfb'
require 'logger'
require 'mechanize'
require 'pry'

module CFB
  class ScrapeScores
    def initialize(url: "https://www.cbssports.com/college-football/scoreboard/FBS/2017/postseason/16/")
      @url = url
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
    end

    def scrape
      page = agent.get(url)
      [extract_in_progress_scores(page), extract_postgame_scores(page)]
    end

    def extract_postgame_scores(games_page)
      games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
      groups = classify_games(games)
      groups[:postgame].map { |game| extract_score(game, no_status: true) }
    end

    def extract_in_progress_scores(games_page)
      games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
      groups = classify_games(games)
      groups[:in_progress].map { |game| extract_score(game) }
    end

    private

    attr_reader :agent, :url

    def classify_games(games_page)
      groups = {
        in_progress: [],
        pregame: [],
        postgame: []
      }

      games_page.each do |game|
        id = game.attributes["id"]
        next unless id && id.value =~ /game-\d+/

        if !game.xpath("div/div/div[contains(@class, 'pregame')]").empty?
          groups[:pregame] << game
        elsif !game.xpath("div/div/div[contains(@class, 'postgame')]").empty?
          groups[:postgame] << game
        else
          groups[:in_progress] << game
        end
      end

      groups
    end

    def extract_score(game, no_status: false)
      rows = game.xpath("div/div[contains(@class, 'in-progress-table')]/table/tbody/tr")
      raise "Expected 2 rows, found: #{rows.size}" unless rows.size == 2

      game_name = game.xpath("div/div[contains(@class, 'series-statement')]")[0].text.strip

      visitor = extract_team(rows[0])
      home = extract_team(rows[1])
      status = parse_game_status(game)

      result = { game: game_name, visitor: visitor, home: home }
      result[:status] = status unless no_status

      result
    end

    def extract_team(row)
      cells = row.xpath("td")
      final_score = cells[-1].text.to_i
      intermediate_scores = cells.drop(1).take(cells.size - 2).map { |cell| cell.text.to_i }
      name = cells[0].text.split("\n").map(&:strip).reject(&:empty?).first

      { name: name, score: final_score, intermediate_scores: intermediate_scores }
    end

    def parse_game_status(game)
      status = game.xpath("div/div/div[contains(@class, 'game-status')]")[0].text.strip
      raise "No status found for game: #{game}" unless status

      if status.downcase == "final"
        { quarter: "final" }
      elsif status.downcase == "halftime"
        { quarter: "halftime" }
      elsif (match = /(\d)\w{2}\s+(\d{1,2}:\d{2})/.match(status))
        { quarter: match[1], remaining: match[2] }
      else
        { quarter: status }
      end
    end
  end
end
