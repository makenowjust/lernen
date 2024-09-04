# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require_relative "../automaton/dfa_test"

module Lernen
  module Equiv
    class RandomWalkOracleTest < Minitest::Test
      #: () -> void
      def test_find_cex
        sul = System.from_block { _1.count("1") % 4 == 3 }
        dfa = Automaton::DFA.new(0, Set.new, { [0, "0"] => 0, [0, "1"] => 0 })

        random = Random.new(0)
        oracle = RandomWalkOracle.new(%w[0 1], sul, random:)

        refute_nil oracle.find_cex(dfa)
        assert_nil oracle.find_cex(Automaton::DFATest.mod4_dfa)
      end
    end
  end
end
