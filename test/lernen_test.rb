# frozen_string_literal: true

require_relative "test_helper"

class TestLernen < Minitest::Test
  N = 30

  ORACLE = :random_walk
  ORACLE_PARAMS = { step_limit: 1500 }.freeze

  TEST_CASES = [
    [:lstar, { cex_processing: :binary }],
    [:lstar, { cex_processing: :linear }],
    [:lstar, { cex_processing: :exponential }],
    [:lstar, { cex_processing: nil }],
    [:kearns_vazirani, { cex_processing: :binary }],
    [:kearns_vazirani, { cex_processing: :linear }],
    [:kearns_vazirani, { cex_processing: :exponential }],
    [:lsharp, {}]
  ].freeze

  TEST_CASES.each do |(algorithm, params)|
    define_method(:"test_learn_dfa_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::DFA.random(alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            oracle: ORACLE,
            oracle_params: ORACLE_PARAMS,
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    define_method(:"test_learn_moore_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::Moore.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            automaton_type: :moore,
            oracle: ORACLE,
            oracle_params: ORACLE_PARAMS,
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    define_method(:"test_learn_mealy_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::Mealy.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            automaton_type: :mealy,
            oracle: ORACLE,
            oracle_params: ORACLE_PARAMS,
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end
  end
end
