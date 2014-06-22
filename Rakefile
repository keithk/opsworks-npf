require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'foodcritic'
require 'kitchen'

# Style tests. Rubocop and Foodcritic
namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:rubocop)

  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:foodcritic) do |t|
    t.options = {
      :fail_tags => ['any'],
      :tags => ['~FC015', '~FC022']
    }
  end
end

# Rspec and ChefSpec
namespace :spec do
  desc 'Run ChefSpec examples'
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.rspec_opts = '--color --format documentation'
    t.ruby_opts = '-W0'
    t.verbose = false
  end
end

# Integration tests. Kitchen.ci
namespace :integration do
  desc 'Run Test Kitchen with Vagrant'
  task :vagrant do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen.logger.level = Kitchen::Util.to_logger_level(:warn)
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end
end

desc 'Run all style checks'
task :style => ['style:foodcritic', 'style:rubocop']

desc 'Run all specs'
task :spec => ['spec:rspec']

# Default
task :default => %w(style spec)
