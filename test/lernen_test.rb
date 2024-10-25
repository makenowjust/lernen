# frozen_string_literal: true
# rbs_inline: enabled

require_relative "test_helper"

class LernenTest < Minitest::Test
  N = 30

  ORACLE = :random_word #: :random_word
  ORACLE_PARAMS = { max_words: 100 }.freeze #: Hash[Symbol, Integer]
  VPA_ORACLE_PARAMS = { max_words: 800 }.freeze #: Hash[Symbol, Integer]

  TEST_CASES = [
    [:lstar, { cex_processing: :binary }],
    [:lstar, { cex_processing: :linear }],
    [:lstar, { cex_processing: :exponential }],
    [:lstar, { cex_processing: nil }],
    [:kearns_vazirani, { cex_processing: :binary }],
    [:kearns_vazirani, { cex_processing: :linear }],
    [:kearns_vazirani, { cex_processing: :exponential }],
    [:dhc, { cex_processing: :binary }],
    [:dhc, { cex_processing: :linear }],
    [:dhc, { cex_processing: :exponential }],
    [:lsharp, {}]
  ].freeze #: Array[[Lernen::algorithm_name, Hash[Symbol, Symbol]]]

  TEST_CASES.each do |(algorithm, params)|
    define_method(:"test_learn_dfa_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected = Lernen::Automaton::DFA.random(alphabet:, random:, min_state_size: 8, max_state_size: 10)

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
        cex = Lernen::Automaton::DFA.find_separating_word(alphabet, expected, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    define_method(:"test_learn_moore_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected =
          Lernen::Automaton::Moore.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

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
        cex = Lernen::Automaton::Moore.find_separating_word(alphabet, expected, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    define_method(:"test_learn_mealy_#{algorithm}_#{params}") do
      alphabet = %w[0 1 2]
      output_alphabet = %w[a b c d]
      N.times do |seed|
        random = Random.new(seed * 41)
        expected =
          Lernen::Automaton::Mealy.random(alphabet:, output_alphabet:, random:, min_state_size: 8, max_state_size: 10)

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
        cex = Lernen::Automaton::Mealy.find_separating_word(alphabet, expected, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    define_method(:"test_learn_spa_#{algorithm}_#{params}") do
      alphabet = %w[a b c d]
      call_alphabet = %i[F G H]
      return_input = :↵

      N.times do |seed|
        random = Random.new(seed * 41)
        expected =
          Lernen::Automaton::SPA.random(
            alphabet:,
            call_alphabet:,
            return_input:,
            random:,
            min_proc_size: 1,
            max_proc_size: 3,
            dfa_min_state_size: 2,
            dfa_max_state_size: 5,
            dfa_accept_state_size: 1
          )

        result =
          Lernen.learn(
            alphabet:,
            call_alphabet:,
            return_input:,
            sul: expected,
            oracle: :simulator,
            params: {
              algorithm:,
              algorithm_params: params
            },
            random:
          )
        cex = Lernen::Automaton::SPA.find_separating_word(alphabet, call_alphabet, expected, result)

        assert_nil cex, "Equivalence check failed (seed: #{seed})"
      end
    end

    if algorithm == :lstar && !params[:cex_processing].nil?
      define_method(:"test_learn_vpa_#{algorithm}_#{params}") do
        alphabet = %w[0 1 2]
        call_alphabet = %w[(]
        return_alphabet = %w[)]
        N.times do |seed|
          random = Random.new(seed * 41)
          expected =
            Lernen::Automaton::VPA.random(
              alphabet:,
              call_alphabet:,
              return_alphabet:,
              random:,
              min_state_size: 8,
              max_state_size: 10
            )

          result =
            Lernen.learn(
              alphabet:,
              call_alphabet:,
              return_alphabet:,
              sul: expected,
              automaton_type: :vpa,
              oracle: ORACLE,
              oracle_params: VPA_ORACLE_PARAMS,
              algorithm: :lstar_vpa,
              params:,
              random:
            )
          cex = Lernen::Automaton::VPA.find_separating_word(alphabet, call_alphabet, return_alphabet, expected, result)

          assert_nil cex, "Equivalence check failed (seed: #{seed})"
        end
      end
    elsif algorithm == :kearns_vazirani
      define_method(:"test_learn_vpa_#{algorithm}_#{params}") do
        alphabet = %w[0 1 2]
        call_alphabet = %w[(]
        return_alphabet = %w[)]
        N.times do |seed|
          random = Random.new(seed * 41)
          expected =
            Lernen::Automaton::VPA.random(
              alphabet:,
              call_alphabet:,
              return_alphabet:,
              random:,
              min_state_size: 8,
              max_state_size: 10
            )

          result =
            Lernen.learn(
              alphabet:,
              call_alphabet:,
              return_alphabet:,
              sul: expected,
              automaton_type: :vpa,
              oracle: ORACLE,
              oracle_params: VPA_ORACLE_PARAMS,
              algorithm: :kearns_vazirani_vpa,
              params:,
              random:
            )
          cex = Lernen::Automaton::VPA.find_separating_word(alphabet, call_alphabet, return_alphabet, expected, result)

          assert_nil cex, "Equivalence check failed (seed: #{seed})"
        end
      end
    end
  end
end
