require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.rspec_opts = ["--color", "--format", "doc"]
  end
  task :default => :spec
  task :test    => :spec
rescue LoadError
  # no rspec available
end

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |task|
    task.files   = ["lib/**/*.rb"]
  end
rescue LoadError
  # no yard available
end
