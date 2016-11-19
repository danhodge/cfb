require 'cfb'
require 'logger'
require 'mechanize'

module CFB
  class ScrapeEspnLines
    def self.run(**kwargs)
      new(**kwargs).scrape.tap { |x| require 'pry'; binding.pry }
    end

    def initialize(url: 'http://espn.go.com/college-football/lines')
      @url = url
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
    end

    def scrape
      page = agent.get(url)

      container = page.search("//div[@class='mod-container mod-table mod-no-header']").first
      table = container.search('div/table').first

      table.children.select { |child| child.name == 'tr' }.each_with_object([]) do |row, results|
        next unless row.attributes['class']

        if row.attributes['class'].value == 'stathead'
          tokens = row.text.split(' - ')
          matchup, game, raw_time, remainder = if tokens.length == 2
                                                 [tokens[0], nil, tokens[1], nil]
                                               else
                                                 tokens
                                               end
          visitor, home = matchup.split(' at ')

          if raw_time == 'Cfp Semifinal'
            raw_time = remainder
          end
          time_str = raw_time.gsub(/ET/, '-0500').gsub(/\(\d+\)/, '')
          time_str = append_year(time_str)
          time = DateTime.strptime(time_str, '%a, %b %e, %l:%M %p %z %Y').iso8601

          results << Game.new(game, nil, time, team(*extract_ranking(visitor)), team(*extract_ranking(home)))
        elsif %w[oddrow evenrow].include?(row.attributes['class'].value)
          cells = row.children.select { |child| child.name == 'td' }
          next unless cells.length == 4

          cell = cells[1]
          if cell.text == 'EVEN'
            results.last.visitor.point_spreads << 0
            results.last.home.point_spreads << 0
          else
            point_spreads = cell.search('table/tr/td').first
            next if point_spreads.nil?

            results.last.visitor.point_spreads << point_spreads.children[0].text.to_f
            results.last.home.point_spreads << point_spreads.children[2].text.to_f
          end
        end
      end
    end

    private

    attr_reader :logger, :agent, :url

    def append_year(time_str)
      now = DateTime.now
      jan_time = time_str.include?('Jan')

      if (now.month == 1 && jan_time) || (now.month != 1 && !jan_time)
         [time_str, now.year].join(' ')
      elsif now.month == 1 && !jan_time
        [time_str, now.year - 1].join(' ')
      elsif now.month != 1 && jan_time
        [time_str, now.year + 1].join(' ')
      end
    end

    def extract_ranking(team_name)
      if team_name =~ /\A#(\d+) (.+)\z/
        [Regexp.last_match[2], Regexp.last_match[1].to_i]
      else
        [team_name, nil]
      end
    end

    def team(name, ranking)
      Team.new(name, nil, nil, ranking, [])
    end
  end
end
