#!/usr/bin/env ruby

require_relative 'lib/config'
require_relative 'lib/wrapped_tweet'
require_relative 'lib/kiosk_interaction'
require 'emoji_data'
require 'oj'
require 'colored'
require 'eventmachine'


# my options
puts "...starting in verbose mode!" if VERBOSE
$stdout.sync = true

# in production, load newrelic
if is_production?
  require 'newrelic_rpm'
  GC::Profiler.enable
end

# check for development mode with remote redis server, if so refuse to run
if (REDIS_URI.to_s.match(/redis(?:togo|cloud)/) && !is_production?)
  Kernel::abort "You shouldn't be using the production redis server with a local version of feeder! Quitting..."
end

# SETUP
# 400 terms is the max twitter will allow with a normal dev account
# set that if you are on a normal key otherwise the stream will not return anything to you
MAX_TERMS = ENV["MAX_TERMS"] || nil
if MAX_TERMS
  TERMS = EmojiData.chars.first(MAX_TERMS.to_i)
else
  TERMS = EmojiData.chars({include_variants: true})
end

#track references to us too
TERMS << '@emojitracker'

# if we are actively profiling for performance, load and start the profiler
if is_development? && PROFILE
  puts "Starting profiling run, profile will be logged upon termination."
  require 'stackprof'
  StackProf.start()
end

EventMachine.run do
  # load Lua scripts to Redis server
  # save the SHA so we can refer to them later in EVALSHA
  sha = REDIS.script(:load, IO.read("./scripts/update.lua"))

  puts "Setting up a stream to track #{TERMS.size} terms '#{TERMS}'..."
  @tracked,@skipped,@tracked_last,@skipped_last = 0,0,0,0

  @client = TweetStream::Client.new
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
  @client.track(TERMS) do |status|
    @tracked += 1

    # extend the tweet object with our convenience mixins
    status.extend(WrappedTweet)

    # disregard retweets
    next if status.retweet?

    # for interactive kiosk mode at #emojishow, allow users to request a specific character for display
    # send the interaction notice but DONT LOG THE TWEET since its artificial
    if KioskInteraction.enabled?
      is_interaction = status.text.start_with?("@emojitracker")
      if is_interaction
        KioskInteraction::InteractionRequest.new(status).handle() if status.emojis.length > 0
        next # halt further tweet processing
      end
    end

    # update redis for each matched char
    status.emojis.each do |matched_emoji|
      cp = matched_emoji.unified
      REDIS.evalsha(sha, [], [cp, status.tiny_json])
    end
  end

  @stats_refresh_rate = 10
  EM::PeriodicTimer.new(@stats_refresh_rate) do
    tracked_period = @tracked-@tracked_last
    tracked_period_rate = tracked_period / @stats_refresh_rate

    puts "Terms tracked: #{@tracked} (\u2191#{tracked_period}, +#{tracked_period_rate}/sec.), rate limited: #{@skipped} (+#{@skipped-@skipped_last})"
    graphite_log('feeder.updates.rate_per_second', tracked_period_rate)

    @tracked_last = @tracked
    @skipped_last = @skipped
  end

  @redis_check_refresh_rate = 60
  EM::PeriodicTimer.new(@redis_check_refresh_rate) do
    info = REDIS.info
    puts "REDIS - used memory: #{info['used_memory_human']}, iops: #{info['instantaneous_ops_per_sec']}"
    graphite_log('feeder.redis.used_memory_kb', info['used_memory'].to_i / 1024)
    graphite_log('feeder.redis.iops', info['instantaneous_ops_per_sec'])
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
