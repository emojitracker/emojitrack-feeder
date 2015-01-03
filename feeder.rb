#!/usr/bin/env ruby
require_relative 'lib/config'
require_relative 'lib/monitor'
require_relative 'lib/tweet_processor'

require 'emoji_data'
require 'colored'

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
# TODO: replace me with something that works in jruby
if is_development? && PROFILE
  puts "Starting profiling run, profile will be logged upon termination."
  require 'stackprof'
  StackProf.start()
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
  # EM.stop
end

#Periodic logging to console/graphite - stream track status.
StreamMonitor.start!

# set up a queue and workers to process it
require 'thread'
Thread.abort_on_exception=true # we want to see all errors for now

queue = Queue.new
numworkers = 4 #TODO: set dynamically
workers = []
(1..numworkers).each do |n|
  workers << TweetProcessor.start!(queue, n)
end

# initialize streaming counts
puts "Setting up a stream to track #{TERMS.size} terms '#{TERMS}'..."
$tracked,$skipped = 0,0
# main event loops for matched tweets
@client.filter(track: TERMS.join(",")) do |status|
  case status
  when Twitter::Tweet
    $tracked += 1
    queue << status
  when Twitter::Streaming::Message
    warn "GOT A STREAMING MSG: #{status}"
  when Twitter::Streaming::StallWarning
    warn "STALL WARNING - FALLING BEHIND STREAM"
  end
end

# Error handling for Twitter streams.
# TODO: need to figure out how to get enhance your calm and skip limits from
# twitter gem...

# @client.on_error do |message|
#   puts "ERROR: #{message}"
# end
# @client.on_enhance_your_calm do
#   puts "TWITTER SAYZ ENHANCE UR CALM"
# end
# @client.on_limit do |skip_count|
#   @skipped = skip_count
#   puts "RATE LIMITED LOL"
# end
# @client.on_stall_warning do |warning|
#   puts "STALL FALLBEHIND WARNING - NOT KEEPING UP WITH STREAM"
#   puts warning
# end
