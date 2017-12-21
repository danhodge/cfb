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

  erb :scores, locals: { results: results }
end

post '/scores' do
  data = S3.get_object(bucket: "danhodge-cfb", key: "2017/results_2017.json").body.read
  results = JSON.parse(data, symbolize_names: true)

  request[:visitor].each do |index, value|
    res = results.find { |result| result[:id] == index.to_i }
    res[:visitor][:score] = value unless value.length == 0
  end

  request[:home].each do |index, value|
    res = results.find { |result| result[:id] == index.to_i }
    res[:home][:score] = value unless value.length == 0
  end

  S3.put_object(
    acl: "public-read",
    bucket: "danhodge-cfb",
    key: "2017/results_2017.json",
    body: JSON.pretty_generate(results)
  )

  redirect "/scores"
end
