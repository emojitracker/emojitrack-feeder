require './lib/wrapped_tweet'
require_relative 'fixture_helper'

require 'benchmark/ips'

@t0x0x = load_fixture 453190911166394368
@t3x2x = load_fixture 543520739971055616

Benchmark.ips do |x|
  x.config(:time => 1, :warmup => 1)

  x.report("ensmallen/0") { @t0x0x.ensmallen }
  x.report("ensmallen/3") { @t3x2x.ensmallen }

  x.report("ensmallen_links/0") { @t0x0x.ensmallen_links }
  x.report("ensmallen_links/3") { @t3x2x.ensmallen_links }

end
