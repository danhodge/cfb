require 'json'
require 'sinatra'
require 'aws-sdk'

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
    res[:visitor][:score] = value unless value.length.zero?
  end

  request[:home].each do |index, value|
    res = results.fetch(index.to_sym)
    res[:home][:score] = value unless value.length.zero?
  end

  S3.put_object(
    acl: "public-read",
    bucket: "danhodge-cfb",
    key: "2017/results_2017.json",
    body: JSON.pretty_generate(results)
  )

  redirect "/scores"
end
