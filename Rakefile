# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

namespace :rubocop do
  basic_style_cops = %w[Layout/TrailingWhitespace Layout/SpaceInsideBlockBraces Style/StringLiterals]

  desc "Auto-Format code for #{basic_style_cops.join(', ')} using safe autocorrect"
  task :autocorrect_basic_style_issues do
    sh("bundle exec rubocop -a --only #{basic_style_cops.join(',')}")
  end
end

RSpec::Core::RakeTask.new(:spec)

desc 'Run rubocop cleanup only, spec then full rubocop'
task default: %w[rubocop:autocorrect_basic_style_issues spec rubocop]
