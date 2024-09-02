# frozen_string_literal: true

require "set"

module Lernen
  # Error is an error class for this library.
  class Error < StandardError
  end
end

require_relative "lernen/automaton"
require_relative "lernen/cex_processor"
require_relative "lernen/oracle"
require_relative "lernen/sul"
require_relative "lernen/version"

require_relative "lernen/lstar"
require_relative "lernen/kearns_vazirani"
require_relative "lernen/lsharp"

# Lernen is a simple automata learning library.
module Lernen
  # Learn an automaton.
  def self.learn(
    alphabet:,
    call_alphabet: nil,
    return_alphabet: nil,
    sul: nil,
    oracle: :random_word,
    oracle_params: {},
    algorithm: :kearns_vazirani,
    automaton_type: nil,
    params: {},
    random: Random,
    &sul_block
  )
    automaton_type ||= call_alphabet ? :vpa : :dfa

    case sul
    when SUL
      # Do nothing
    when Automaton
      automaton_type = sul.type
      sul = SUL.from_automaton(sul)
    when nil
      sul = SUL.from_block(&sul_block)
    else
      raise ArgumentError, "Unsupported SUL: #{sul}"
    end

    full_alphabet =
      case automaton_type
      in :dfa | :moore | :mealy
        alphabet
      in :vpa
        alphabet + call_alphabet + return_alphabet
      end

    case oracle
    when Oracle
      # Do nothing
    when :breadth_first_exploration
      oracle = BreadthFirstExplorationOracle.new(full_alphabet, sul, **oracle_params)
    when :random_walk
      oracle = RandomWalkOracle.new(full_alphabet, sul, random:, **oracle_params)
    when :random_word
      oracle = RandomWordOracle.new(full_alphabet, sul, random:, **oracle_params)
    else
      raise ArgumentError, "Unsupported oracle: #{oracle}"
    end

    case algorithm
    in :lstar
      LStar.learn(alphabet, sul, oracle, automaton_type:, **params)
    in :kearns_vazirani
      KearnsVazirani.learn(alphabet, sul, oracle, automaton_type:, call_alphabet:, return_alphabet:, **params)
    in :lsharp
      LSharp.learn(alphabet, sul, oracle, automaton_type:, **params)
    end
  end
end
