source 'https://rubygems.org'
ruby '2.1.3'

group :web, :feeder, :streamer do
  gem 'redis', '~> 3.0.7'
  gem 'hiredis', '~> 0.5.2'
  gem 'oj', '~> 2.9.9'
end

group :web, :feeder do
  gem 'emoji_data', '~> 0.2.0'
end

group :feeder do
  gem 'tweetstream', '~> 2.6.1'
  gem 'twitter', '5.8.0' #manually set!
  gem 'colored', '~> 1.2'
end

group :development do
  gem 'foreman', '~> 0.75.0'
  gem 'rspec', '~> 2.14.1'
end

group :production do
  gem 'newrelic_rpm'
end
