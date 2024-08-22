# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "yard"
require "rubocop/rake_task"
require "syntax_tree/rake_tasks"

Minitest::TestTask.create

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.stats_options = ["--list-undoc"]
end

RuboCop::RakeTask.new { |t| t.options = %w[--fail-level W] }

[SyntaxTree::Rake::WriteTask, SyntaxTree::Rake::CheckTask].each do |task|
  task.new do |t|
    t.source_files =
      FileList[
        %w[Gemfile Rakefile *.gemspec bin/**/{console,rake} lib/**/*.rb test/**/*.rb example/**/*.rb tool/**/*.rb]
      ]
    t.print_width = 120
  end
end

task format: %w[rubocop:autocorrect_all stree:write]
task lint: %w[rubocop stree:check]
