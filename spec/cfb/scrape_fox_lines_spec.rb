require 'cfb/scrape_fox_lines'

RSpec.describe CFB::ScrapeFoxLines do
  let(:year) { 2016 }
  let(:fixture) { File.read("spec/fixtures/fox_#{year}.html") }
  let(:page) { Nokogiri::HTML(fixture) }

  describe '#extract_games' do
    let(:games) { described_class.new.extract_games(page) }

    it 'finds a name for each game' do
      games.each do |game|
        expect(game.name).to be
      end
    end

    it 'finds a time for each game' do
      games.each do |game|
        expect(game.time).to be

        time = Time.parse(game.time)
        expect([[year, 12], [year + 1, 1]].include?([time.year, time.month])).to be true
      end
    end

    it 'finds a home team for each game' do
      games.each do |game|
        home = game.home
        expect(home.name).to be
        expect(home.point_spreads).to_not be_empty
      end
    end

    it 'finds a visiting team for each game' do
      games.each do |game|
        visitor = game.visitor
        expect(visitor.name).to be
        expect(visitor.point_spreads).to_not be_empty
      end
    end
  end
end
