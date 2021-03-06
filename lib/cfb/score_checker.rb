require 'cfb'
require 'cfb/scrape_scores'
require 'aws-sdk'
require 'json'
require 'fileutils'
require 'logger'

module CFB
  class ScoreChecker
    def self.perform
      instance.perform
    end

    def self.instance
      @instance ||= new(s3: Aws::S3::Client.new(
                          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
                          region: 'us-east-1'))
    end

    def initialize(scraper: CFB::ScrapeScores.new, s3:)
      @scraper = scraper
      @s3 = s3
      FileUtils.mkdir_p('log/')
      @logger = Logger.new('log/scrape_scores.log')
    end

    def perform
      in_progress, postgame = scraper.scrape
      logger.debug("in_progress: #{in_progress}, postgame: #{postgame}")

      handle_in_progress_games(in_progress) unless in_progress.empty?
      handle_completed_games(postgame) unless postgame.empty?
    end

    private

    attr_reader :scraper, :s3, :logger

    def handle_in_progress_games(in_progress)
      in_progress_scores_log = get_in_progress_scores_log
      time = Time.now.iso8601
      in_progress.each do |game|
        in_progress_scores_log << game.merge(time: time)
      end

      write_in_progress_scores_log(in_progress_scores_log)
    end

    def handle_completed_games(postgame)
      results = load_results
      updates = postgame.reduce(0) do |count, game|
        if value = find_result_for_game(results.values, game[:game])
          count + (update_result(value, game) ? 1 : 0)
        else
          logger.info("Could not find a match for completed game: #{game[:game]}")
          count
        end
      end

      save_results(results) if updates > 0
    end

    def find_result_for_game(values, game_name)
      values.find { |game| normalized_game_name(game[:name]) == normalized_game_name(game_name) }
    end

    def update_result(value, game)
      unless value[:visitor][:score].nil? && value[:home][:score].nil?
        logger.info("Not updating final score for game #{value[:name]} because it is already set")
        return false
      end

      if match_team_names(value[:visitor][:name], game[:visitor][:name]) || match_team_names(value[:home][:name], game[:home][:name])
        value[:visitor][:score] = game[:visitor][:score].to_s
        value[:home][:score] = game[:home][:score].to_s
        logger.info("Updated matching final score for game: #{value}")

        return true
      elsif match_team_names(value[:visitor][:name], game[:home][:name]) || match_team_names(value[:home][:name], game[:visitor][:name])
        value[:visitor][:score] = game[:home][:score].to_s
        value[:home][:score] = game[:visitor][:score].to_s
        logger.info("Updated mismatched final score for game: #{value}")

        return true
      else
        logger.error("Not updating final score because unable to match team names for game: #{value[:name]}")
        return false
      end
    end

    def match_team_names(expected_name, actual_name)
      expected_name && actual_name && expected_name.downcase == actual_name.downcase
    end

    def normalized_game_name(name)
      name.downcase.gsub(/bowl/, '').strip
    end

    def get_in_progress_scores_log
      log_data = s3.get_object(bucket: "danhodge-cfb", key: "#{CFB.year}/in_progress_scores.ldjson").body.read
      log_data.split("\n").map { |line| JSON.parse(line) }
    end

    def write_in_progress_scores_log(log)
      s3.put_object(
        bucket: "danhodge-cfb",
        key: "#{CFB.year}/in_progress_scores.ldjson",
        body: log.map(&:to_json).join("\n")
      )
    end

    def load_results
      data = s3.get_object(bucket: "danhodge-cfb", key: "#{CFB.year}/results_#{CFB.year}.json").body.read
      JSON.parse(data, symbolize_names: true)
    end

    def save_results(results)
      s3.put_object(
        acl: "public-read",
        bucket: "danhodge-cfb",
        key: "#{CFB.year}/results_#{CFB.year}.json",
        body: JSON.pretty_generate(results)
      )
    end
  end
end
