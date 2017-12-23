require 'cfb/scrape_scores'
require 'aws-sdk'
require 'json'

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
    end

    def perform
      in_progress, postgame = scraper.scrape

      # handle_in_progress_games(in_progress) unless in_progress.empty?
      handle_completed_games(postgame) unless postgame.empty?
    end

    private

    attr_reader :scraper, :s3

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
          puts "Could not find a match for completed game: #{game[:game]}"
          count
        end
      end

      save_results(results) if updates > 0
    end

    def find_result_for_game(values, game_name)
      values.find { |game| game[:game] == game_name }
    end

    def update_result(value, game)
      unless value[:visitor][:score].nil? && value[:home][:score].nil?
        puts "Not updating final score for game #{value[:game]} because it is already set"
        return false
      end

      value[:visitor][:score] = game[:visitor][:score].to_s
      value[:home][:score] = game[:home][:score].to_s

      puts "Updated final score for game: #{value}"
      true
    end

    def get_in_progress_scores_log
      log_data = s3.get_object(bucket: "danhodge-cfb", key: "2017/in_progress_scores.ldjson").body.read
      log_data.split("\n").map { |line| JSON.parse(line) }
    rescue => ex
      []
    end

    def write_in_progress_scores_log(log)
      s3.put_object(
        bucket: "danhodge-cfb",
        key: "2017/in_progress_scores.ldjson",
        body: log.map(&:to_json).join("\n")
      )
    end

    def load_results
      data = s3.get_object(bucket: "danhodge-cfb", key: "2017/results_2017.json").body.read
      JSON.parse(data, symbolize_names: true)
    end

    def save_results(results)
      s3.put_object(
        acl: "public-read",
        bucket: "danhodge-cfb",
        key: "2017/results_2017.json",
        body: JSON.pretty_generate(results)
      )
    end

    def write_in_progress_scores_log(log)
      s3.put_object(
        bucket: "danhodge-cfb",
        key: "2017/in_progress_scores.ldjson",
        body: log.map(&:to_json).join("\n")
      )
    end
  end
end
