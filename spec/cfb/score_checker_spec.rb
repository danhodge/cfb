require 'spec_helper'

require 'cfb/score_checker'

RSpec.describe CFB::ScoreChecker do
  describe '#peform' do
    let(:scraper) { instance_double(CFB::ScrapeScores, scrape: scrape_results) }
    let(:s3) { Aws::S3::Client.new(stub_responses: true) }
    let(:in_progress) { [game] }
    let(:postgame) { [game, game, game, game] }
    let(:scrape_results) do
      [in_progress, postgame]
    end
    let(:results) do
      {
        "0" => {
          name: postgame[0][:game],
          visitor: {
            name: postgame[0][:visitor][:name],
            score: 10
          },
          home: {
            name: postgame[0][:home][:name],
            score: 21
          }
        },
        "1" => {
          name: postgame[1][:game],
          visitor: {
            name: postgame[1][:visitor][:name],
            score: nil
          },
          home: {
            name: postgame[1][:home][:name],
            score: nil
          }
        },
        "2" => {
          name: postgame[2][:game],
          visitor: {
            name: postgame[2][:home][:name],
            score: nil
          },
          home: {
            name: postgame[2][:visitor][:name],
            score: nil
          }
        },
        "3" => {
          name: "#{postgame[3][:game]} Championship",
          visitor: {
            name: postgame[3][:visitor][:name],
            score: nil
          },
          home: {
            name: postgame[3][:home][:name],
            score: nil
          }
        }
      }
    end
    let(:get_object_stub) do
      proc do |context|
        if context.params[:key].end_with?("/in_progress_scores.ldjson")
          { body: "[]" }
        else
          { body: results.to_json }
        end
      end
    end

    it 'updates results' do
      s3.stub_responses(:get_object, get_object_stub)

      checker = described_class.new(scraper: scraper, s3: s3)
      checker.perform
    end

    def game
      @game_index ||= 0
      @game_index += 1

      {
        game: "Game #{@game_index}",
        visitor: {
          name: "Visitor #{@game_index}",
          score: (@game_index * 3) + 7
        },
        home: {
          name: "Home #{@game_index}",
          score: ((@game_index + 2) * 3) - 5
        }
      }
    end
  end
end
