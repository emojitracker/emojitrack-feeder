require 'thread'
require 'redis'
# require_relative './config'
require_relative './wrapped_tweet'

class TweetProcessor

  def initialize(queue, worker_num=nil)
    @queue = queue
    @worker_num = worker_num

    # ...each worker should have it's own redis connection, so more workers is
    # effectively similar to having a redis connection pool.
    @redis_client = Redis.new
    # ^^^ uses REDIS_URL by default, so below is no longer required...
    #@redis_client = Redis.new(
    #   :host     => REDIS_URI.host,
    #   :port     => REDIS_URI.port,
    #   :password => REDIS_URI.password,
    #   # :driver   => :hiredis
    # )
  end


  def main
    loop do
      # block until can pop tweet off queue
      status = @queue.pop

      # disregard if retweet
      next if status.retweet?

      # extend and parse
      # extend the tweet object with our convenience mixins
      status.extend(WrappedTweet)

      # update redis for each matched char
      status.emojis.each do |matched_emoji|
        @redis_client.evalsha(
          redis_update_script,
          [], [matched_emoji.unified, status.tiny_json()]
        )
      end
    end
  end

  def status
    #TODO: we should track individual TP status as well
  end

  def self.start!(queue, worker_num)
    Thread.new { self.new(queue, worker_num).main }
  end

  protected

  # load scripts to Redis server
  # We push most of the logic of updating Redis into a Lua script.
  # For details of the why see the script itself.
  # Don't forget to save the SHA so we can refer to them later via EVALSHA.
  def redis_update_script
    @sha ||= @redis_client.script(:load, IO.read("./scripts/update.lua"))
  end

end
