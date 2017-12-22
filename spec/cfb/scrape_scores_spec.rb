require 'cfb/scrape_scores'

RSpec.describe CFB::ScrapeScores do
  let(:fixture) { File.read("spec/fixtures/cbs_scoreboard1.html") }
  let(:page) { Nokogiri::HTML(fixture) }

  describe '#extract_postgame_scores' do
    let(:scores) { described_class.new.extract_postgame_scores(page) }
    let(:expected) do
      [
        {
          :game=>"Frisco Bowl",
          :visitor=>{:name=>"Louisiana Tech", :score=>51, :intermediate_scores=>[21, 21, 6, 3]},
          :home=>{:name=>"SMU", :score=>10, :intermediate_scores=>[3, 7, 0, 0]}},
        {
          :game=>"Boca Raton Bowl",
          :visitor=>{:name=>"Akron", :score=>3, :intermediate_scores=>[0, 3, 0, 0]},
          :home=>{:name=>"FAU", :score=>50, :intermediate_scores=>[7, 14, 15, 14]}
        },
        {
          :game=>"New Orleans Bowl",
          :visitor=>{:name=>"Troy", :score=>50, :intermediate_scores=>[15, 7, 21, 7]},
          :home=>{:name=>"North Texas", :score=>30, :intermediate_scores=>[7, 13, 3, 7]}
        },
        {
          :game=>"Cure Bowl",
          :visitor=>{:name=>"W. Kentucky", :score=>17, :intermediate_scores=>[7, 3, 0, 7]},
          :home=>{:name=>"Georgia State", :score=>27, :intermediate_scores=>[10, 3, 7, 7]}
        },
        {
          :game=>"Las Vegas Bowl",
          :visitor=>{:name=>"25", :score=>38, :intermediate_scores=>[14, 10, 7, 7]},
          :home=>{:name=>"Oregon", :score=>28, :intermediate_scores=>[0, 14, 0, 14]}
        },
        {
          :game=>"New Mexico Bowl",
          :visitor=>{:name=>"Marshall", :score=>31, :intermediate_scores=>[0, 21, 10, 0]},
          :home=>{:name=>"Colorado State", :score=>28, :intermediate_scores=>[0, 14, 0, 14]}},
        {
          :game=>"Camellia Bowl",
          :visitor=>{:name=>"M. Tenn. St.", :score=>35, :intermediate_scores=>[7, 14, 7, 7]},
          :home=>{:name=>"Arkansas St.", :score=>30, :intermediate_scores=>[3, 7, 7, 13]}
        }
      ]
    end

    it "finds the scores for all completed games" do
      expect(scores).to eq(expected)
    end
  end

  describe '#extract_in_progress_scores' do
    let(:scores) { described_class.new.extract_in_progress_scores(page) }

    let(:expected) do
      [
        {
          :game => "Gasparilla Bowl",
          :status => { :quarter=>"2", :remaining=>"0:59" },
          :visitor => { :name=>"Temple", :score=>7, :intermediate_scores=>[0, 7, 0, 0] },
          :home => { :name=>"FIU", :score=>0, :intermediate_scores=>[0, 0, 0, 0] }
        }
      ]
    end

    it "finds the scores for all in-progress games" do
      expect(scores).to eq(expected)
    end
  end
end
