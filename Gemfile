source 'https://rubygems.org'
ruby '2.2.0'
# ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.16'

gem 'twitter',    '~> 5.13.0'
gem 'redis',      '~> 3.2.0'
#TODO: jrjackson for fast json in jruby?? twitter gem wont like it...
gem 'emoji_data', '~> 0.2.0'
gem 'colored',    '~> 1.2'

group :development do
  gem 'rspec', '~> 3.1.0'
  gem 'benchmark-ips', '~> 2.1.0'
  gem 'stackprof', :platforms => :mri
end

group :production do
  gem 'newrelic_rpm'
end
