require 'sinatra'
require 'redis'
require 'securerandom'
require 'json'

redis = Redis.new
file = open 'config.json'
json = file.read
config = JSON.parse json

post '/' do
	key = SecureRandom::urlsafe_base64(4)
	json = JSON.parse request.body.read
	value = json['original']
	expires = if json.has_key? 'expires' and json['expires'] < 2592000 then json['expires'] else 2592000 end
	if value =~ /^https?:\/\/([a-z0-9-]+\.)+[a-z]{2,}(\/([a-zA-Z0-9-_]+(\.[a-z]+)?)?)*\??([a-z0-9_]+(=[a-z0-9_]*)?&?)*$/i
	  while redis.get("url:#{key}") do key = SecureRandom::urlsafe_base64(4) end
	  redis.set("url:#{key}", value, :ex => expires)
	  {:id => key, :url => "#{request.scheme}://#{request.host_with_port}/#{key}", :expires => expires}.to_json
	else
		puts "Invalid URL: \"#{value}\""
		halt 422, 'Invalid URL'
  end
end

get '/:key' do
  key = 'url:' + params['key']
  value = redis.get(key)
  if value
    redirect value, 302
  else
    "Sorry, that URL doesn't exist or has expired."
  end
end

get '/' do
	case config['root_behavior']
	  when 'redirect' then redirect config['root_location'], 301
	  else 'Houston, we have a problem!'
  end
end