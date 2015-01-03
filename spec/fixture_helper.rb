require 'twitter'

def load_fixture(id)
  j = JSON.parse(File.read("./spec/fixtures/#{id}.json"), symbolize_names: true)
  f = Twitter::Tweet.new( j )
  f.extend(WrappedTweet)
end
