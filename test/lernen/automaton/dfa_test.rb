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
            0(("0"))
            1(("1"))
            2(("2"))
            3((("3")))

            0 -- "#quot;0#quot;" --> 0
            0 -- "#quot;1#quot;" --> 1
            1 -- "#quot;0#quot;" --> 1
            1 -- "#quot;1#quot;" --> 2
            2 -- "#quot;0#quot;" --> 2
            2 -- "#quot;1#quot;" --> 3
            3 -- "#quot;0#quot;" --> 3
            3 -- "#quot;1#quot;" --> 0
        MERMAID
        assert_equal expected, dfa.to_mermaid
        assert_predicate dfa.to_mermaid, :frozen?
      end

      #: () -> void
      def test_to_dot
        dfa = DFATest.mod4_dfa

        expected = <<~'DOT'
          digraph {
            0 [label="0", shape=circle];
            1 [label="1", shape=circle];
            2 [label="2", shape=circle];
            3 [label="3", shape=doublecircle];

            0 -> 0 [label="\"0\""];
            0 -> 1 [label="\"1\""];
            1 -> 1 [label="\"0\""];
            1 -> 2 [label="\"1\""];
            2 -> 2 [label="\"0\""];
            2 -> 3 [label="\"1\""];
            3 -> 3 [label="\"0\""];
            3 -> 0 [label="\"1\""];
          }
        DOT
        assert_equal expected, dfa.to_dot
        assert_predicate dfa.to_dot, :frozen?
      end
    end
  end
end
