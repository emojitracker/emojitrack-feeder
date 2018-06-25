# emojitrack-feeder
This consumes the Twitter streaming API, processing and feeding the Redis instance for the rest of Emojitracker.

## Development Setup
 1. Make sure you have Ruby 2.1.x installed.
 2. Get the repository and basic dependencies going:

        git clone mroth/emojitrack-feeder
        cd emojitrack-feeder
        bundle install --without=production

 3. Copy `.env-sample` to `.env` and configure required variables.
 4. Make sure you have Redis installed and running.  The rules in `lib/config.rb` currently dictate the order a redis server instance is looked for.
 5. Run all processes via `foreman start` or `forego start` (depending on which you have installed).

Be sure to note that while the processing power is fairly managable, the feeder component of emojitrack requires on it's own about 1MB/s of downstream bandwith, and ~250KB/s of upstream.  You can use the `MAX_TERMS` environment variable to process less emoji chars if you don't have the bandwidth where you are.

Note, **DO NOT** run the feeder process with REDIS_URL configured to the production server, ever.
