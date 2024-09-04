# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class DFATest < Minitest::Test
      #: () -> Lernen::Automaton::DFA[String]
      def self.mod4_dfa
        Lernen::Automaton::DFA.new(
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
      end

      #: () -> void
      def test_run
        dfa = DFATest.mod4_dfa

        assert_equal [[], 0], dfa.run([])
        assert_equal [[false], 0], dfa.run(%w[0])
        assert_equal [[false], 1], dfa.run(%w[1])
        assert_equal [[false, false, true], 3], dfa.run(%w[1 1 1])
        assert_equal [[false, false, true, false], 0], dfa.run(%w[1 1 1 1])
      end

      #: () -> void
      def test_to_mermaid
        dfa = DFATest.mod4_dfa

        expected = <<~MERMAID
          flowchart TD
            0((0))
            1((1))
            2((2))
            3(((3)))

            0 -- "'0'" --> 0
            0 -- "'1'" --> 1
            1 -- "'0'" --> 1
            1 -- "'1'" --> 2
            2 -- "'0'" --> 2
            2 -- "'1'" --> 3
            3 -- "'0'" --> 3
            3 -- "'1'" --> 0
        MERMAID
        assert_equal expected, dfa.to_mermaid
        assert_predicate dfa.to_mermaid, :frozen?
      end
    end
  end
end
