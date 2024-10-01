# frozen_string_literal: true

require "lernen"
require "prism"
require "ripper"

shows_mermaid_diagram = false

# For reproducibility, we use a PRNG with a fixed seed.
seed = 41
random = Random.new(seed)

# `alphabet`, `call_alphabet`, and `return_alphabet` are arrays of pieces of words.
# The `alphabet` characters cause neither push nor pop,
# the `call_alphabet` characters cause push onto a stack, and
# the `return_alphabet` characters cause pop onto a stack.
alphabet = %w["a" :] # rubocop:disable Lint/PercentStringArray
call_alphabet = %w[(]
return_alphabet = %w[)]

# `oracle` specifies a kind of an equivalence oracle using on learning,
# and `oracle_params` is a paremeter object to it.
oracle = :random_well_matched_word
oracle_params = { max_words: 2000 }.freeze

# When `call_alphabet` and `return_alphabet` are specified to `Lernen.learn`,
# it infers a VPA instead of a automaton.

# Ripper VPA:
puts "Infer Ripper VPA..."
ripper_vpa = Lernen.learn(alphabet:, call_alphabet:, return_alphabet:, oracle:, oracle_params:, random:) do |word|
  !Ripper.sexp(word.join).nil?
end

# Prism VPA:
puts "Infer Prism VPA..."
prism_vpa = Lernen.learn(alphabet:, call_alphabet:, return_alphabet:, oracle:, oracle_params:, random:) do |word|
  Prism.parse(word.join).success?
end

if shows_mermaid_diagram
  puts
  puts "=== Ripper VPA... ==="
  puts ripper_vpa.to_mermaid
  puts "====================="
  puts
  puts "=== Prism VPA... ===="
  puts prism_vpa.to_mermaid
  puts "======================"
  puts
end

puts "Check equivalence between Prism and Ripper VPAs..."
sep_word = Lernen::Automaton::VPA.find_separating_word(alphabet, call_alphabet, return_alphabet, ripper_vpa, prism_vpa)

if sep_word
  sep_str = sep_word.join
  puts "#{sep_str.inspect} is the separating word between Prism and Ripper VPAs."
  puts "  !Ripper.parse(#{sep_str.inspect}).nil? = #{!Ripper.parse(sep_str).nil?}"
  puts "Prism.parse(#{sep_str.inspect}).success? = #{Prism.parse(sep_str).success?}"
else
  puts "No separating word is found, so two VPAs are equivalent."
end
