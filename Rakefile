# As per RSpec official recommendations, wrap loading rspec rake task
# so that Rakefile can be used in production environments where test deps
# are not present.
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

desc "Run perf benchmarks"
task :bench do
  FileList.new("spec/*_bench.rb").each do |benchmark_file|
    ruby benchmark_file
  end
end

task :default => :spec
