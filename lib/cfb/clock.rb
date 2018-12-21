lib_dir = File.expand_path('../..', __FILE__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'cfb/score_checker'
require 'clockwork'
require 'fileutils'

module Clockwork
  handler do |job|
    puts "Running job: #{job}"
  end

  every(1.minute, 'heartbeat') do
    heartbeat_file = File.expand_path('../../../heartbeat', __FILE__)
    FileUtils.touch(heartbeat_file)
  end

  every(10.minutes, 'check_scores') do
    CFB::ScoreChecker.perform
  end
end
