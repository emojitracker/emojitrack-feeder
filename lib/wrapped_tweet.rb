################################################
# tweet object mixin
#
# handles common methods for dealing with tweet status we get from tweetstream
################################################
require 'emoji_data'
require 'time'

module WrappedTweet

  # return a hash for tweet with absolutely everything we dont need ripped out
  # (what? it's a perfectly cromulent word.)
  def ensmallen
    {
      'id'                  => self.attrs[:id_str],
      'text'                => self.text,
      'screen_name'         => self.user.screen_name,
      'name'                => self.safe_user_name(),
      'links'               => self.ensmallen_links(),
      'profile_image_url'   => self.user.attrs[:profile_image_url],
      'created_at'          => self.created_at.iso8601
    }
  end

  # combines the Twitter URL and Media entities, and return only minimum we need
  # this means we pass none of the media object junk beyond the url stuff
  def ensmallen_links
    links = (self.urls + self.media).map do |link|
      {
        'url'          => link.attrs[:url],
        'display_url'  => link.attrs[:display_url],
        'expanded_url' => link.attrs[:expanded_url],
        'indices'      => link.indices
      }
    end

    #always sort results, so clients can easily reverse to loop and s//
    links.sort { |x,y| x['indices'][0] <=> y['indices'][0] }
  end

  # memoized cache of ensmallenified json
  def tiny_json
    JSON.fast_generate(self.ensmallen)
  end

  # return all the emoji chars contained in the tweet, as EmojiData::EmojiChar
  # dedupe since we only want to count each emoji once per tweet
  def emojis
    EmojiData.find_by_str(self.text).uniq { |e| e.unified }
  end

  protected
  # twitter seems to have a bug where usernames can get null bytes set in string
  # this strips them out so we dont cause string parse errors
  def safe_user_name
    self.user.name.gsub(/\0/, '')
  end

  def html_link(text, url)
    "<a href='#{url}' target='_blank'>#{text}</a>"
  end

end
