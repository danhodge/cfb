require 'logger'
require 'mechanize'
require 'cfb/auto_pick'
require 'cfb/game'
require 'cfb/team'

module CFB
  class EnterPicks
    def initialize(username:, password:, url: 'http://broadjumper.com/add_participant.html')
      @url = url
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
      @enter_picks_page = login(username, password)
    end

    def submit_picks(choices_file, tie_breaker)
      choices_by_game = CSV.new(File.read(choices_file), headers: true).map do |row|
        choice = CFB::Choice.new(*row.values_at("ID", "Date", "Bowl", "Choice", "Points"))
        [normalize_game_name(choice.game), choice]
      end.to_h

      games = parse_table
      form = enter_picks_page.forms.first

      games.each_with_index do |game, i|
        # TODO: resolve game by name & time to deal with naming discrepancies
        # or make sure the picks file uses the scraped names
        choice = choices_by_game.fetch(normalize_game_name(game.name))
        buttons = form.radiobuttons.select { |btn| btn.name == "win[#{i}]" }
        visitor_button = buttons.find { |btn| btn.value == "1" }
        home_button = buttons.find { |btn| btn.value == "2" }

        if choice.team == game.visitor.name
          visitor_button.check
          home_button.uncheck
        else
          visitor_button.uncheck
          home_button.check
        end
        form["conf[#{i}]"] = choice.confidence
      end
      form.tie = tie_breaker

      result = form.submit
      File.open("#{self.class}-#{Time.now.iso8601}-picks_saved.html", 'w') { |file| file << result.content }
      errors = result.xpath("//span[text()='CHANGES NOT SAVED!']")

      raise RuntimeError(errors.map(&:text).join) unless errors.empty?
    end

    private

    attr_reader :url, :agent, :enter_picks_page

    def login(username, password)
      page = agent.get(url)
      File.open("#{self.class}-#{Time.now.iso8601}-login_page.html", 'w') { |file| file << page.content }
      login_form = page.forms.find do |form|
        form.fields.find { |field| field.name == "pl" && field.value == username }
      end
      login_form.pswd = password

      result = login_form.submit
      File.open("#{self.class}-#{Time.now.iso8601}-login_result.html", 'w') { |file| file << result.content }
      # errors = result.xpath("//p[text()='bad password/username combination.']")
      # raise RuntimeError(errors.map(&:text).join) unless errors.empty?

      result
    end

    def parse_table
      all_rows = enter_picks_page.xpath("//table/tr").take_while do |row|
        row.text && !row.text.strip.start_with?("Tie Breaker")
      end

      all_rows.each_slice(9).flat_map do |rows|
        break if rows[0].text.strip.start_with?("Tie Breaker")
        parse_rows(rows)
      end
    end

    def parse_rows(rows)
      games = rows[0].xpath("td").drop(1).map { |td| Game.new(td.text) }
      rows[1].xpath("td").drop(1).zip(games).each { |td, game| game.location = td.text }
      rows[4].xpath("td").drop(1).each_slice(2).zip(games).each do |(visit, home), game|
        game.visitor = Team.new(visit.text)
        game.home = Team.new(home.text)
      end

      games
    end

    def normalize_game_name(name)
      name.downcase.gsub(/bowl/, '').strip
    end
  end
end
