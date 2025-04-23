# frozen_string_literal: true

# require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

# require "rubocop/rake_task"

# RuboCop::RakeTask.new

# task default: %i[test rubocop]

require "rake/extensiontask"

task build: :compile

GEMSPEC = Gem::Specification.load("racer.gemspec")

Rake::ExtensionTask.new("racer", GEMSPEC) do |ext|
  ext.lib_dir = "lib/racer"
end
