# frozen_string_literal: true

# rubocop:disable Style/FormatStringToken, Lint/MissingCopEnableDirective

require "fileutils"
require "json"
require "optparse"

names = %w[
  lstar_orig
  lstar_bin
  lstar_lin
  lstar_exp
  kv_bin
  kv_lin
  kv_exp
  dhc_bin
  dhc_lin
  dhc_exp
  lsharp
]

output_dir = "experiments/results/lernen-#{Lernen::VERSION}"

OptionParser.new do |opt|
  opt.on("--names NAMES", "names to aggregate") do |value|
    names = value.split ","
  end

  opt.on("--output-dir DIR", "output directory") do |value|
    output_dir = value
  end

  opt.parse!(ARGV)
end

def stat(nums)
  {
    min: nums.min,
    max: nums.max,
    mid: nums.size.even? ? nums[nums.size / 2] : (nums[(nums.size - 1) / 2] + nums[(nums.size + 1) / 2]) / 2,
    avg: nums.sum.to_f / nums.size,
  }
end

result = {}

names.each do |name|
  data = []
  File.read("#{output_dir}/#{name}.jsonl").each_line do |line|
    data << JSON.parse(line, symbolize_names: true)
  end

  num_ok = data.count { _1[:ok] }
  runtime_time = stat(data.map { _1[:runtime_time] })
  query = stat(data.map { _1[:sul_stats][:num_queries] })
  equiv = stat(data.map { _1[:oracle_stats][:num_calls]})

  result[name] = { num_ok:, runtime_time:, query:, equiv: }
end

def stat_line(stat)
  "#{stat[:avg].round(2)}/#{stat[:min].round(2)}/#{stat[:mid].round(2)}/#{stat[:max].round(2)}"
end

puts "Table:"
puts

puts "|            | #OK |Runtime time [s] (avg/min/mid/max) | #MQ (avg/min/mid/max)         | #EQ (avg/min/mid/max)  |"
puts "|:----------:|----:|:----------------------------------|:------------------------------|:-----------------------|"
names.each do |name|
  r = result[name]
  printf "| %-10s | %3d | %33s | %29s | %22s |\n",
    name,
    r[:num_ok],
    stat_line(r[:runtime_time]),
    stat_line(r[:query]),
    stat_line(r[:equiv])
end

puts
puts "Chart (Runtime time):"
puts
puts "```mermaid"
puts "xychart-beta"
puts '  title "Runtime time (Average)"'
puts "  x-axis [#{names.map(&:inspect).join(", ")}]"
puts '  y-axis "time [s]"'
puts "  bar [#{names.map { result[_1][:runtime_time][:avg].round(2) }.join(", ")}]"
puts "```"
puts
puts "Chart (#MQ):"
puts
puts "```mermaid"
puts "xychart-beta"
puts '  title "#MQ (Average)"'
puts "  x-axis [#{names.map(&:inspect).join(", ")}]"
puts '  y-axis "#MQ"'
puts "  bar [#{names.map { result[_1][:query][:avg].round(2) }.join(", ")}]"
puts "```"
puts
puts "Chart (#EQ):"
puts
puts "```mermaid"
puts "xychart-beta"
puts '  title "#EQ (Average)"'
puts "  x-axis [#{names.map(&:inspect).join(", ")}]"
puts '  y-axis "#EQ"'
puts "  bar [#{names.map { result[_1][:equiv][:avg].round(2) }.join(", ")}]"
puts "```"
