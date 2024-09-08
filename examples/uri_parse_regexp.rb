# frozen_string_literal: true

require "lernen"
require "uri"

shows_mermaid_diagram = false

# Define validations using `URI.parse` and `URI` regexp.

def valid_and_http_url?(string)
  uri = URI.parse(string)
  uri.scheme == "http" || uri.scheme == "https"
rescue URI::Error
  false
end

VALID_AND_HTTP_URL_REGEXP = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
def new_valid_and_http_url?(string)
  string.match?(VALID_AND_HTTP_URL_REGEXP)
end

# For reproducibility, we use a PRNG with a fixed seed.
seed = 41
random = Random.new(seed)

# `alphabet` is an array of pieces of words.
# Learning algorithm infers an automaton on this alphabet, so in this case,
# we specify some possible subwords in URLs to `alphabet`.
alphabet = %w[http https ftp example com foo 80 12 : / . ? = & # @ %]

# `oracle` specifies a kind of an equivalence oracle using on learning,
# and `oracle_params` is a paremeter object to it.
oracle = :random_word
oracle_params = { max_words: 2000 }.freeze

# Infer a automaton by calling the `Lernen.learn` method with the target program.

# `URI.parse` DFA:
puts "Infer `URI.parse` DFA..."
uri_parse_dfa = Lernen.learn(alphabet:, oracle:, oracle_params:, random:) do |word|
  # `word.join` is necessary because `word` is an array of `alphabet` elements.
  valid_and_http_url?(word.join)
end

# `URI` regexp DFA:
puts "Infer `URI` regexp DFA..."
uri_regexp_dfa = Lernen.learn(alphabet:, oracle:, oracle_params:, random:) do |word|
  new_valid_and_http_url?(word.join)
end

if shows_mermaid_diagram
  puts
  puts "=== `URI.parse` DFA... ===="
  puts uri_parse_dfa.to_mermaid
  puts "==========================="
  puts
  puts "=== `URI` regexp DFA... ==="
  puts uri_regexp_dfa.to_mermaid
  puts "=========================="
  puts
end

puts "Check equivalence between `URI.parse` and `URI` regexp DFAs..."
sep_word = Lernen::Automaton::DFA.find_separating_word(alphabet, uri_parse_dfa, uri_regexp_dfa)

if sep_word
  sep_str = sep_word.join
  puts "#{sep_str.inspect} is the separating word between `URI.parse` and `URI` regexp DFAs."
  puts "    valid_and_http_url?(#{sep_str.inspect}) = #{valid_and_http_url?(sep_str)}"
  puts "new_valid_and_http_url?(#{sep_str.inspect}) = #{new_valid_and_http_url?(sep_str)}"
else
  puts "No separating word is found, so two DFAs are equivalent."
end
