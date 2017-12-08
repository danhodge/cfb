require 'cfb'
require 'date'
require 'logger'
require 'mechanize'

module CFB
  class AddParticipant
    def initialize(url: 'http://broadjumper.com/add_participant.html')
      @base_url = url
      @logger = Logger.new(STDOUT)
      @agent = Mechanize.new do |mechanize|
        mechanize.user_agent = 'Mac Safari'
        mechanize.log = @logger
      end
    end

    def add(nickname:, password:, name:, email:, phone:)
      page = agent.get(base_url)
      form = page.forms.find { |form| form.action == base_url }
      form.nick = nickname
      form.password = password
      form.uname = name
      form.email = email
      form.phone = phone

      result = form.submit
    end

    private

    attr_reader :agent, :base_url
  end
end
