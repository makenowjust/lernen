# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require_relative "../automaton/dfa_test"

module Lernen
  module Equiv
    class ExhaustiveSearchOracleTest < Minitest::Test
      #: () -> void
      def test_find_cex_and_stats
        sul = System.from_block { _1.count("1") % 4 == 3 }
        dfa = Automaton::DFA.new(0, Set.new, { [0, "0"] => 0, [0, "1"] => 0 })

        oracle = ExhaustiveSearchOracle.new(%w[0 1], sul, depth: 4)

        assert_equal %w[0 1 1 1], oracle.find_cex(dfa)
        assert_nil oracle.find_cex(Automaton::DFATest.mod4_dfa)

        expected_stats = { num_calls: 2, num_queries: 24, num_steps: 96 }

        assert_equal expected_stats, oracle.stats
      end
    end
  end
end
