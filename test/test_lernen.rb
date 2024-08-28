# frozen_string_literal: true

require "test_helper"

class TestLernen < Minitest::Test
  table = [
    [:lstar, { cex_processing: :binary }],
    [:lstar, { cex_processing: :linear }],
    [:lstar, { cex_processing: :exponential }],
    [:lstar, { cex_processing: nil }],
    [:kearns_vazirani, { cex_processing: :binary }],
    [:kearns_vazirani, { cex_processing: :linear }],
    [:kearns_vazirani, { cex_processing: :exponential }],
    [:lsharp, {}]
  ]

  table.each do |(algorithm, params)|
    define_method(:"test_learn_dfa_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      50.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::DFA.random(alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            oracle: :random_walk,
            oracle_params: {
              step_limit: 1500
            },
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed}, cex: #{cex})"
      end
    end

    define_method(:"test_learn_moore_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      50.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::Moore.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            automaton_type: :moore,
            oracle: :random_walk,
            oracle_params: {
              step_limit: 1500
            },
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed}, cex: #{cex})"
      end
    end

    define_method(:"test_learn_mealy_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      50.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::Mealy.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

        result =
          Lernen.learn(
            alphabet:,
            sul: expected,
            automaton_type: :mealy,
            oracle: :random_walk,
            oracle_params: {
              step_limit: 1500
            },
            algorithm:,
            params:,
            random:
          )
        cex = expected.check_equivalence(alphabet, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed}, cex: #{cex})"
      end
    end
  end
end
