require 'twitter'
require 'uri'
require 'socket'

#convenience method for reading booleans from env vars
def to_boolean(s)
  s and !!s.match(/^(true|t|yes|y|1)$/i)
end

# verbose mode or no
VERBOSE = to_boolean(ENV["VERBOSE"]) || false

# profile mode or no
PROFILE = to_boolean(ENV["PROFILE"]) || false

@client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV['CONSUMER_KEY']
  config.consumer_secret     = ENV['CONSUMER_SECRET']
  config.access_token        = ENV['OAUTH_TOKEN']
  config.access_token_secret = ENV['OAUTH_TOKEN_SECRET']
end

# db setup
REDIS_URI = URI.parse(ENV["REDIS_URL"] || ENV["REDISCLOUD_URL"] || ENV["REDISTOGO_URL"] || ENV["BOXEN_REDIS_URL"] || "redis://localhost:6379")

# environment checks
def is_production?
  ENV["RACK_ENV"] == 'production'
end

def is_development?
  ENV["RACK_ENV"] == 'development'
end

# configure logging to graphite in production
def graphite_log(metric, count)
  @hostedgraphite_apikey = ENV['HOSTEDGRAPHITE_APIKEY']
  # puts "Graphite log - #{metric}: #{count}" if VERBOSE
  if is_production?
    sock = UDPSocket.new
    sock.send @hostedgraphite_apikey + ".#{metric} #{count}\n", 0, "carbon.hostedgraphite.com", 2003
  end
end

# same as above but include heroku dyno hostname
def graphite_dyno_log(metric,count)
  dyno = ENV['DYNO'] || 'unknown-host'
  metric_name = "#{dyno}.#{metric}"
  graphite_log metric_name, count
end
