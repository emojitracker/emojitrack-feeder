require 'twitter'
require 'oj'

def load_fixture(id)
  Oj.default_options={symbol_keys: true}
  f = Twitter::Tweet.new( Oj.load_file "./spec/fixtures/#{id}.json" )
  f.extend(WrappedTweet)
end
