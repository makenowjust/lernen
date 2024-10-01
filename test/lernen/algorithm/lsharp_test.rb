# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Algorithm
    class LSharpTest < Minitest::Test
      #: () -> void
      def test_learn_dfa
        alphabet = %w[0 1]
        sul = System.from_block { |word| word.count("1") % 4 == 3 }
        oracle = Equiv::ExhaustiveSearchOracle.new(alphabet, sul)
        hypothesis = LSharp.learn(alphabet, sul, oracle, automaton_type: :dfa)

        expected =
          Automaton::DFA.new(
            0,
            Set[3],
            {
              [0, "0"] => 0,
              [0, "1"] => 1,
              [1, "0"] => 1,
              [1, "1"] => 2,
              [2, "0"] => 2,
              [2, "1"] => 3,
              [3, "0"] => 3,
              [3, "1"] => 0
            }
          )

        assert_equal expected, hypothesis
      end

      #: () -> void
      def test_learn_moore
        alphabet = %w[0 1]
        sul = System.from_block { |word| word.count("1") % 4 }
        oracle = Equiv::ExhaustiveSearchOracle.new(alphabet, sul)
        hypothesis = LSharp.learn(alphabet, sul, oracle, automaton_type: :moore)

        expected =
          Automaton::Moore.new(
            0,
            { 0 => 0, 1 => 1, 2 => 2, 3 => 3 },
            {
              [0, "0"] => 0,
              [0, "1"] => 1,
              [1, "0"] => 1,
              [1, "1"] => 2,
              [2, "0"] => 2,
              [2, "1"] => 3,
              [3, "0"] => 3,
              [3, "1"] => 0
            }
          )

        assert_equal expected, hypothesis
      end

      #: () -> void
      def test_learn_mealy
        alphabet = %w[0 1]
        sul = System.from_block { |word| word.count("1") % 4 }
        oracle = Equiv::ExhaustiveSearchOracle.new(alphabet, sul)
        hypothesis = LSharp.learn(alphabet, sul, oracle, automaton_type: :mealy)

        expected =
          Automaton::Mealy.new(
            0,
            {
              [0, "0"] => [0, 0],
              [0, "1"] => [1, 1],
              [1, "0"] => [1, 1],
              [1, "1"] => [2, 2],
              [2, "0"] => [2, 2],
              [2, "1"] => [3, 3],
              [3, "0"] => [3, 3],
              [3, "1"] => [0, 0]
            }
          )

        assert_equal expected, hypothesis
      end
    end
  end
end
