require 'date'
require 'json'
require 'cfb/game'
require 'cfb/participant'
require 'cfb/team'
require 'cfb/pick'

module CFB
  def self.year(today: Date.today)
    if today.month < 8
      today.year - 1
    else
      today.year
    end
  end
end
