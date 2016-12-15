require 'cfb/scrape_picks'

RSpec.describe CFB::ScrapePicks do
  describe '#extract_picks' do
    context 'during registration' do
      before do
        allow(CFB).to receive(:year).and_return(year)
      end

      let(:year) { 2016 }
      let(:fixture) { File.read("spec/fixtures/pre_games_picks_#{year}.html") }
      let(:page) { Nokogiri::HTML(fixture) }

      let(:result) { described_class.new(year_indicator: :current).extract_picks(page) }

      it 'finds no participants' do
        expect(result.participants).to be_empty
      end

      it 'finds games' do
        expect(result.games).to_not be_empty
      end

      it 'finds a name for each game' do
        result.games.each do |game|
          expect(game.name).to be
        end
      end

      it 'finds a time for each game' do
        result.games.each do |game|
          expect(game.time).to be

          time = Time.parse(game.time)
          expect([[year, 12], [year + 1, 1]].include?([time.year, time.month])).to be true
        end
      end

      it 'finds a home team for each game' do
        result.games.each do |game|
          home = game.home
          expect(home.name).to be
        end
      end

      it 'finds a visiting team for each game' do
        result.games.each do |game|
          visitor = game.visitor
          expect(visitor.name).to be
        end
      end
    end

    context 'after registration' do
      before do
        allow(CFB).to receive(:year).and_return(year)
      end

      let(:year) { 2014 }
      let(:fixture) { File.read("spec/fixtures/participants_#{year}.html") }
      let(:page) { Nokogiri::HTML(fixture) }

      let(:result) { described_class.new(year_indicator: :current).extract_picks(page) }

      it 'finds participants' do
        expect(result.participants).to_not be_empty
      end

      it 'finds games' do
        expect(result.games).to_not be_empty
      end

      it 'finds a name for each game' do
        result.games.each do |game|
          expect(game.name).to be
        end
      end

      it 'finds a time for each game' do
        result.games.each do |game|
          expect(game.time).to be

          time = Time.parse(game.time)
          expect([[year, 12], [year + 1, 1]].include?([time.year, time.month])).to be true
        end
      end

      it 'finds a home team for each game' do
        result.games.each do |game|
          home = game.home
          expect(home.name).to be
        end
      end

      it 'finds a visiting team for each game' do
        result.games.each do |game|
          visitor = game.visitor
          expect(visitor.name).to be
        end
      end
    end
  end
end
