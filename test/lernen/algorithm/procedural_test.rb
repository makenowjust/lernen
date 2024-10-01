# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require_relative "../automaton/spa_test"

module Lernen
  module Algorithm
    class ProceduralTest < Minitest::Test
      #: () -> void
      def test_learn
        alphabet = %w[a b c]
        call_alphabet = %i[F G]
        return_input = :↵

        spa = Automaton::SPATest.palindrome_spa
        sul = System.from_automaton(spa)
        oracle = Equiv::SPASimulatorOracle.new(alphabet, call_alphabet, spa, sul)

        hypothesis = Procedural.learn(alphabet, call_alphabet, return_input, sul, oracle)
        cex = Automaton::SPA.find_separating_word(alphabet, call_alphabet, spa, hypothesis)

        assert_nil cex
      end
    end
  end
end
