# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken, Lint/MissingCopEnableDirective

require "fileutils"
require "json"
require "lernen"
require "optparse"

algorithm = :lstar
params = { cex_processing: :binary }
name = "lstar_bin"

output_dir = "experiments/results/lernen-#{Lernen::VERSION}"

OptionParser.new do |opt|
  opt.on("--algorithm ALGORITHM", "algorithm name to use") do |value|
    algorithm = value.intern
  end

  opt.on("--params PARAMS_JSON", "parameters to algorithm") do |value|
    params = eval(value) # rubocop:disable Security/Eval
  end

  opt.on("--name NAME", "name of output file") do |value|
    name = value
  end

  opt.on("--output-dir DIR", "output directory") do |value|
    output_dir = value
  end

  opt.parse!(ARGV)
end

puts "Options:"
puts "  algorithm = #{algorithm.inspect}"
puts "     params = #{params.inspect}"
puts "       name = #{name.inspect}"
puts " output_dir = #{output_dir.inspect}"
puts

FileUtils.makedirs(output_dir)

alphabet = %w[A B C]
min_state_size = 100
max_state_size = 200
accept_state_size = 10

oracle_params = {
  max_words: 1000,
  min_word_size: 5,
  max_word_size: 150,
}

seed = 41
random = Random.new(seed)

random_automaton_array = []
100.times do
  random_automaton = Lernen::Automaton::DFA.random(
    alphabet:,
    min_state_size:,
    max_state_size:,
    accept_state_size:,
    random:,
  )
  random_automaton_array << random_automaton
end

File.open("#{output_dir}/#{name}.jsonl", "w") do |output_file|
  random_automaton_array.each_with_index do |target_automaton, i|
    printf "\r[%3d] %-10s %-10s", i + 1, "#" * ((i % 10) + 1), "learn"
    sul = Lernen::System.from_automaton(target_automaton)
    oracle = Lernen::Equiv::RandomWordOracle.new(alphabet, sul, random:, **oracle_params)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result_automaton = Lernen.learn(alphabet:, sul:, oracle:, algorithm:, params:, random:)
    runtime_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    printf "\r[%3d] %-10s %-10s", i + 1, "#" * ((i % 10) + 1), "validation"
    sep_word = Lernen::Automaton::DFA.find_separating_word(alphabet, target_automaton, result_automaton)

    printf "\r[%3d] %-10s %-10s", i + 1, "#" * ((i % 10) + 1), "write"
    sul_stats = sul.stats
    oracle_stats = oracle.stats
    output_file.puts JSON.dump({ i:, runtime_time:, ok: sep_word.nil?, sul_stats:, oracle_stats: })
    output_file.flush
  end
  puts " done"
end
