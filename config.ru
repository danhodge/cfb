app_dir = File.expand_path('../app', __FILE__)
$LOAD_PATH.unshift(app_dir) unless $LOAD_PATH.include?(app_dir)
require 'admin'

run Sinatra::Application
