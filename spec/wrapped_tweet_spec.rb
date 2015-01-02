require './lib/wrapped_tweet'
require_relative 'fixture_helper'

describe WrappedTweet do

  before :all do
    @tweets = [
      (@tweet_0xurl_0xmedia = load_fixture 453190911166394368), # naked tweet
      (@tweet_1xurl_0xmedia = load_fixture 452633348599320579), # a normal url
      (@tweet_1xurl_1xmedia = load_fixture 538503971485138944), # a single twitter pic
      (@tweet_3xurl_2xmedia = load_fixture 543520739971055616)  # complex ordering of urls/media, with emoji interspersed
    ]
  end

  it "extends a Twitter tweet object"

  describe "#ensmallen" do
    it "only has expected fields" do
      @tweets.each do |t|
        expect(t.ensmallen.keys).to eq(["id",
                                        "text",
                                        "screen_name",
                                        "name",
                                        "links",
                                        "profile_image_url",
                                        "created_at" ])
      end
    end

    it "results hash contains the proper id as a string" do
      expect(@tweet_0xurl_0xmedia.ensmallen['id']).to eq('453190911166394368')
      expect(@tweet_1xurl_0xmedia.ensmallen['id']).to eq('452633348599320579')
      expect(@tweet_1xurl_1xmedia.ensmallen['id']).to eq('538503971485138944')
      expect(@tweet_3xurl_2xmedia.ensmallen['id']).to eq('543520739971055616')
    end

    it "results hash contains the full text of the tweet" do
      expect(@tweet_0xurl_0xmedia.ensmallen['text']).to eq('Still can’t work out what angle Mike Judge is trying for with “Silicon Valley”. The result was sad, overly-stereotyped and very dull.')
      expect(@tweet_1xurl_0xmedia.ensmallen['text']).to eq('I just published “What It’s Like to be a Girl Who Codes” https://t.co/gC3J3Ia2De')
      expect(@tweet_1xurl_1xmedia.ensmallen['text']).to eq('SoCal holiday tip: pan-fry dark meat turkey into carnitas, &amp; make thanksgiving leftover nachos. http://t.co/agcqdbVaeP')
    end

    it "results hash contains the user screen name" do
      expect(@tweet_0xurl_0xmedia.ensmallen['screen_name']).to eq('hitherto')
      expect(@tweet_1xurl_0xmedia.ensmallen['screen_name']).to eq('SyncCindy')
      expect(@tweet_1xurl_1xmedia.ensmallen['screen_name']).to eq('mroth')
      expect(@tweet_3xurl_2xmedia.ensmallen['screen_name']).to eq('mroth')
    end

    it "results hash contains a SAFE user full name"

    it "results hash contains links array equal to ensmallen_links" do
      @tweets.each { |t| expect(t.ensmallen['links']).to eq(t.ensmallen_links) }
    end

    it "results hash contains the proper url for the user profile image"

    it "results hash has a properly formatted iso8601 timestamp" do
      expect(@tweet_0xurl_0xmedia.ensmallen['created_at']).to eq('2014-04-07T15:21:47+00:00')
      expect(@tweet_1xurl_0xmedia.ensmallen['created_at']).to eq('2014-04-06T02:26:14+00:00')
      expect(@tweet_1xurl_1xmedia.ensmallen['created_at']).to eq('2014-11-29T01:25:26+00:00')
      expect(@tweet_3xurl_2xmedia.ensmallen['created_at']).to eq('2014-12-12T21:40:17+00:00')
    end

  end

  describe "#ensmallen_links" do
    it "contains the proper number of links" do
      expect(@tweet_0xurl_0xmedia.ensmallen_links.count).to eq(0)
      expect(@tweet_1xurl_0xmedia.ensmallen_links.count).to eq(1)
      expect(@tweet_1xurl_1xmedia.ensmallen_links.count).to eq(1)
      expect(@tweet_3xurl_2xmedia.ensmallen_links.count).to eq(3)
    end

    it "preserves the order of the links as appear in the tweet" do
      expect(@tweet_3xurl_2xmedia.ensmallen_links[0]['url']).to eq('http://t.co/RFT2AmECM9')
      expect(@tweet_3xurl_2xmedia.ensmallen_links[1]['url']).to eq('http://t.co/TufStqyZKn')
      expect(@tweet_3xurl_2xmedia.ensmallen_links[2]['url']).to eq('http://t.co/agcqdbVaeP')
    end
  end

  describe "#tiny_json" do
    it "produces proper JSON of the ensmallen hash, parseable by anyone" do
      expect(JSON.parse(@tweet_3xurl_2xmedia.tiny_json)["id"]).to eq(@tweet_3xurl_2xmedia.id.to_s)
    end
  end

  describe "#emojis" do
    it "returns an array EmojiData::EmojiChar objects"

    it "returns the distinct count number of *unique* emojis in a tweet" do
      expect(@tweet_0xurl_0xmedia.emojis.count).to equal(0)
      expect(@tweet_3xurl_2xmedia.emojis.count).to equal(4)
    end

    it "returns emoji in proper order, removing duplicates" do
      results = @tweet_3xurl_2xmedia.emojis
      expect(results[0].name).to eq('SKULL')
      expect(results[1].name).to eq('SLICE OF PIZZA')
      expect(results[2].name).to eq('HONEYBEE')
      expect(results[3].name).to eq('MONEY BAG')
    end
  end

end
