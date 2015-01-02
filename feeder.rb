#!/usr/bin/env ruby
require_relative 'lib/config'
require_relative 'lib/wrapped_tweet'
require 'emoji_data'
require 'oj'
require 'colored'
require 'em-hiredis'

# preamble
puts "...starting in verbose mode!" if VERBOSE
$stdout.sync = true

# NewRelic for server monitoring in production
if is_production?
  require 'newrelic_rpm'
  GC::Profiler.enable
end

# SAFETY CHECK
# check for development mode with remote production redis server,
# if so refuse to run to avoid data corruption.
if (REDIS_URI.to_s.match(/redis(?:togo|cloud)/) && !is_production?)
  puts  "Don't use the production redis server with a local version of feeder!"
  abort "Quitting..."
end

# SETUP TERMS
# Grabbed from our EmojiData gem.
# Allow for a MAX_TERMS override from environment variable.
#
# Note to devs: if you request more terms than your account is flagged for, then
# Twitter will silently fail without an error but send you zero data, looking
# like nothing matched. 400 terms is the default max for a dev account with
# streaming API access, so set this if you are not on our special production
# keys with elevated access.
MAX_TERMS = ENV["MAX_TERMS"] || nil
if MAX_TERMS
  TERMS = EmojiData.chars.first(MAX_TERMS.to_i)
else
  TERMS = EmojiData.chars({include_variants: true})
end

# if we are actively profiling for performance, load and start the profiler
if is_development? && PROFILE
  puts "Starting profiling run, profile will be logged upon termination."
  require 'stackprof'
  StackProf.start()
end

EM.run do
  db = EM::Hiredis.connect(REDIS_URI.to_s)

  # load scripts to Redis server
  # We push most of the logic of updating Redis into a Lua script.
  # For details of the why see the script itself.
  #
  # Don't forget to save the SHA so we can refer to them later via EVALSHA.
  # sha = db.script(:load, IO.read("./scripts/update.lua"))

  # hiredis method loads all scripts and binds them to a method with same name
  EM::Hiredis::Client.load_scripts_from('./scripts')

  # initialize streaming counts
  puts "Setting up a stream to track #{TERMS.size} terms '#{TERMS}'..."
  @tracked,@skipped,@tracked_last,@skipped_last = 0,0,0,0
  @client = TweetStream::Client.new

  # main event loops for matched tweets
  @client.track(TERMS) do |status|
    @tracked += 1

    # extend the tweet object with our convenience mixins
    status.extend(WrappedTweet)

    # disregard retweets
    next if status.retweet?

    # update redis for each matched char
    status.emojis().each do |matched_emoji|
      cp = matched_emoji.unified
      # db.evalsha(sha, [], [cp, status.tiny_json])
      db.update([], [cp, status.tiny_json()])
    end
  end

  # Error handling for Twitter streams.
  @client.on_error do |message|
    puts "ERROR: #{message}"
  end
  @client.on_enhance_your_calm do
    puts "TWITTER SAYZ ENHANCE UR CALM"
  end
  @client.on_limit do |skip_count|
    @skipped = skip_count
    puts "RATE LIMITED LOL"
  end
  @client.on_stall_warning do |warning|
    puts "STALL FALLBEHIND WARNING - NOT KEEPING UP WITH STREAM"
    puts warning
  end

  # Periodic logging to console/graphite - stream track status.
  @stats_refresh_rate = 10
  EM::PeriodicTimer.new(@stats_refresh_rate) do
    period = @tracked-@tracked_last
    period_rate = period / @stats_refresh_rate

    puts "Terms tracked: #{@tracked} (\u2191#{period}" +
         ", +#{period_rate}/sec.), rate limited: #{@skipped}" +
         " (+#{@skipped - @skipped_last})"
    graphite_log('feeder.updates.rate_per_second', period_rate)
    @tracked_last = @tracked
    @skipped_last = @skipped
  end

  # Periodic logging to console/graphite - redis DB status.
  @redis_check_refresh_rate = 60
  EM::PeriodicTimer.new(@redis_check_refresh_rate) do
    db.info do |info|
      puts "REDIS - used memory: #{info[:used_memory_human]}" +
           ", iops: #{info[:instantaneous_ops_per_sec]}"
      graphite_log('feeder.redis.used_memory_kb', info[:used_memory].to_i / 1024)
      graphite_log('feeder.redis.iops', info[:instantaneous_ops_per_sec])
    end
  end

  # Trap TERM signals sent to PID, for anything we want to do upon shutdown.
  #
  # For now, this is just used to stop the profiler if running, but could be
  # for anything clever to make things more graceful ala:
  # http://robares.com/2010/09/26/safe-shutdown-of-eventmachine-reactors/
  trap("TERM") do
    if is_development? && PROFILE
      StackProf.stop()
      File.open('stackprof-feeder-cpu.dump', 'wb') do |f|
        f.write Marshal.dump(StackProf.results)
      end
    end
    EM.stop
  end

end
