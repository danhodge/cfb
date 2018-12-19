app_dir = File.expand_path('../app', __FILE__)
lib_dir = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(app_dir) unless $LOAD_PATH.include?(app_dir)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'admin'

run Sinatra::Application
