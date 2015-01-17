class Monitor

  def refresh_rate
    60
  end

  def report
    nil
  end

  def main
    loop do
      sleep refresh_rate
      report
    end
  end

  def self.start!
    Thread.new { self.new.main }
  end

end

class StreamMonitor < Monitor
  def refresh_rate
    10
  end

  def initialize
    @tracked_last,@skipped_last = 0,0
  end

  def report
    period = $tracked-@tracked_last
    period_rate = period / refresh_rate

    puts "Terms tracked: #{$tracked} (\u2191#{period}" +
         ", +#{period_rate}/sec.), rate limited: #{$skipped}" +
         " (+#{$skipped - @skipped_last})"

    # graphite_log('feeder.updates.rate_per_second', period_rate)

    @tracked_last = $tracked
    @skipped_last = $skipped
  end
end

# TODO: no longer needed, newrelic handles this quite fine!
# class RedisMonitor < Monitor
#   PERIOD = 60
#
#   def report
#     info = REDIS.info
#
#     puts "REDIS - used memory: #{info['used_memory_human']}" +
#          ", iops: #{info['instantaneous_ops_per_sec']}"
#
#     # graphite_log('feeder.redis.used_memory_kb', info['used_memory'].to_i / 1024)
#     # graphite_log('feeder.redis.iops', info['instantaneous_ops_per_sec'])
#   end
# end
