require 'cfb'
require 'logger'
require 'mechanize'

module CFB
  class ScrapeFoxLines
    def self.run(**kwargs)
      point_spreads = new(**kwargs).scrape

      File.open("point_spreads_#{CFB.year}.json", 'w') do |file|
        file << JSON.pretty_generate(point_spreads.sort_by(&:time).map(&:to_h))
      end
    end

    def initialize(url: 'http://www.foxsports.com/college-football/odds')
      @url = url
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
    end

    def scrape
      extract_games(agent.get(url))
    end

    def extract_games(page)
      container = page.search("//section[@class='wisbb_body']").first
      children = container.search("//div[@class='wisbb_gameWrapper']")

      children.map do |child|
        visitor, home = child.search('span[@class="wisbb_teamCity"]').map(&:text)

        raw_date, raw_time, name = child.search('span[@class="wisbb_oddsGameDate"]').first.text.split(' - ').map(&:strip)
        modified_time = raw_time.gsub(/a/, 'am').gsub(/p/, 'pm').gsub('ET', '-05:00')

        time = DateTime.strptime("#{raw_date} #{modified_time}", '%a, %b %d, %Y %l:%M%P %z').iso8601

        game = Game.new(name, nil, time, team(visitor), team(home))

        odds = child.search('table[@class="wisbb_standardTable wisbb_oddsTable wisbb_altRowColors"]').first
        odds.search('tr').drop(1).each do |row|
          cell = row.search("td[@class='wisbb_runLinePtsCol']").first
          game.visitor.point_spreads << cell.children.first.text.to_f
          game.home.point_spreads << cell.children.last.text.to_f
        end

        game
      end
    end

    private

    attr_reader :logger, :agent, :url

    def team(name)
      Team.new(name, nil, nil, nil, [])
    end
  end
end
