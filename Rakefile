#!/usr/bin/env rake

require 'bundler/setup'

# chefspec task against spec/*_spec.rb
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:chefspec)

# foodcritic rake task
require 'foodcritic'
desc 'Foodcritic linter'
FoodCritic::Rake::LintTask.new(:foodcritic) do |t|
  t.options = {
    fail_tags: ['correctness'],
    progress: true,
    context: true
  }
end

# rubocop rake task
require 'rubocop/rake_task'
desc 'Ruby style guide linter'
RuboCop::RakeTask.new(:rubocop)

# creates metadata.json
desc 'Create metadata.json from metadata.rb'
task :metadata do
  sh 'knife cookbook metadata from file metadata.rb'
end

# share cookbook to Chef community site
desc 'Share cookbook to community site'
task :share do
  sh 'knife cookbook site share cdap databases'
end

# test-kitchen
begin
  require 'kitchen/rake_tasks'
  desc 'Run Test Kitchen integration tests'
  task :integration do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end

# default tasks are quick, commit tests
task default: %w(foodcritic rubocop chefspec)
