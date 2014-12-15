-- Updates the server whenever a new emoji is seen in a tweet
--
-- Putting this in a script enables us to save some bandwidth by not
-- transmitting any redundant data to the server, as we can calculate the
-- appropriate key names there and re-use data that goes to multiple
-- destinations.

local uid      = ARGV[1]   -- unified codepoint ID
local tinyjson = ARGV[2]   -- json blob representing the ensmallened tweet

-- increment the score in a sorted set
redis.call('ZINCRBY', 'emojitrack_score', 1, uid)

-- stream the fact that the score was updated
redis.call('PUBLISH', 'stream.score_updates', uid)

-- for each emoji char, store the most recent 10 tweets in a list
local tweet_details_key = "emojitrack_tweets_" .. uid
redis.call('LPUSH', tweet_details_key, tinyjson)
redis.call('LTRIM', tweet_details_key, 0, 9)

-- also stream all tweet updates to named streams by char
local stream_details_key = "stream.tweet_updates." .. uid
redis.call('PUBLISH', stream_details_key, tinyjson)

-- return ok status
return 1
