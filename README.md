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


## Other parts of emojitracker
This is but a small part of emojitracker's infrastructure.  Major components of the project include:

- **[emojitrack-web](//github.com/mroth/emojitrack)** _the web frontend and application server (you are here!)_
- **[emojitrack-feeder](//github.com/mroth/emojitrack-feeder)** _consumes the Twitter Streaming API and feeds our data pipeline_
- **emojitrack-streamer** _handles streaming updates to clients via SSE_
  * [ruby version](//github.com/mroth/emojitrack-streamer) (deprecated)
  * [nodejs version](//github.com/mroth/emojitrack-nodestreamer)
  * [go version](//github.com/mroth/emojitrack-gostreamer) (currently used in production)
  * [streamer API spec](//github.com/mroth/emojitrack-streamer-spec) _defines the streamer spec, tests servers in staging_


Additionally, many of the libraries emojitrack uses have also been carved out into independent emoji-related open-source projects, see the following:

- **[emoji_data.rb](//github.com/mroth/emoji_data.rb)** _utility library for handling the Emoji vs Unicode nightmare (Ruby)_
- **[emoji-data-js](//github.com/mroth/emoji-data-js)** _utility library for handling the Emoji vs Unicode nightmare (Nodejs port)_
- **[exmoji](//github.com/mroth/exmoji)** _utility library for handling the Emoji vs Unicode nightmare (Elixir/Erlang port)_
- **[emojistatic](//github.com/mroth/emojistatic)** _generates static emoji assets for a public CDN_

As well as some general purpose libraries:

- **[cssquirt](//github.com/mroth/cssquirt)** _Embeds images (or directories of images) directly into CSS via the Data URI scheme_
- **[sse-bench](//github.com/mroth/sse-bench)** _benchmarks Server-Sent Events endpoints_
