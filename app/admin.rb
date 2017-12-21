require 'json'
require 'sinatra'
require 'aws-sdk'

use Rack::Auth::Basic, "Protected Area" do |username, password|
  username == ENV['USERNAME'] && password == ENV['PASSWORD']
end

S3 = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: 'us-east-1'
)

get '/scores' do
  data = S3.get_object(bucket: "danhodge-cfb", key: "2017/results_2017.json").body.read
  results = JSON.parse(data, symbolize_names: true)
  display_results = if request.params["all"] == "1"
                      results
                    else
                      results.reject { |_k, v| v[:visitor][:score] && v[:home][:score] }
                    end

  erb :scores, locals: { results: display_results }
end

post '/scores' do
  data = S3.get_object(bucket: "danhodge-cfb", key: "2017/results_2017.json").body.read
  results = JSON.parse(data, symbolize_names: true)

  request[:visitor].each do |index, value|
    res = results.fetch(index.to_sym)
    res[:visitor][:score] = if value.length.zero?
                              nil
                            else
                              value
                            end
  end

  request[:home].each do |index, value|
    res = results.fetch(index.to_sym)
    res[:home][:score] = if value.length.zero?
                           nil
                         else
                           value
                         end
  end

  S3.put_object(
    acl: "public-read",
    bucket: "danhodge-cfb",
    key: "2017/results_2017.json",
    body: JSON.pretty_generate(results)
  )

  redirect "/scores"
end

get '/*' do
  ""
end
