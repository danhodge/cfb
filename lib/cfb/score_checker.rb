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
      in_progress, _ = scraper.scrape
      if in_progress.empty?
        puts "No games in progress, exiting"
      end

      scores_log = get_scores_log
      time = Time.now.iso8601
      in_progress.each do |game|
        scores_log << game.merge(time: time).to_json
      end

      write_scores_log(scores_log)
    end

    private

    attr_reader :scraper, :s3

    def get_scores_log
      log_data = s3.get_object(bucket: "danhodge-cfb", key: "2017/in_progress_scores.ldjson").body.read
      log_data.split("\n").map { |line| JSON.parse(line) }
    rescue => ex
      []
    end

    def write_scores_log(log)
      s3.put_object(
        bucket: "danhodge-cfb",
        key: "2017/in_progress_scores.ldjson",
        body: log.join("\n")
      )
    end
  end
end
