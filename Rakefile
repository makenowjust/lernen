# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "syntax_tree/rake_tasks"

Rake::TestTask.new(:test) do |t|
  t.verbose = false
  t.pattern = "test/**/*_test.rb"
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

namespace :rbs_inline do
  desc "Generate RBS signatures for `lib` files"
  task :lib do
    sh "bin/rbs-inline", "lib", "--output=sig/generated"
  end

  desc "Generate RBS signatures for `test` files"
  task :test do
    sh "bin/rbs-inline", "test", "--output=sig-test/generated"
  end

  task default: %i[lib test]
end

task rbs_inline: %i[rbs_inline:lib rbs_inline:test]

namespace :steep do
  desc "Run `steep check`"
  task :check do
    sh "bin/steep", "check"
  end
end

task steep: %i[rbs_inline steep:check]
