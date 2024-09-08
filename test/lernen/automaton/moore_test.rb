# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class MooreTest < Minitest::Test
      #: () -> Lernen::Automaton::Moore[String, Integer]
      def self.mod4_moore
        Lernen::Automaton::Moore.new(
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
      end

      #: () -> void
      def test_run
        moore = MooreTest.mod4_moore

        assert_equal [[], 0], moore.run([])
        assert_equal [[0], 0], moore.run(%w[0])
        assert_equal [[1], 1], moore.run(%w[1])
        assert_equal [[1, 2, 3], 3], moore.run(%w[1 1 1])
        assert_equal [[1, 2, 3, 0], 0], moore.run(%w[1 1 1 1])
      end

      #: () -> void
      def test_to_mermaid
        moore = MooreTest.mod4_moore

        expected = <<~MERMAID
          flowchart TD
            0(("0 | 0"))
            1(("1 | 1"))
            2(("2 | 2"))
            3(("3 | 3"))

            0 -- "#quot;0#quot;" --> 0
            0 -- "#quot;1#quot;" --> 1
            1 -- "#quot;0#quot;" --> 1
            1 -- "#quot;1#quot;" --> 2
            2 -- "#quot;0#quot;" --> 2
            2 -- "#quot;1#quot;" --> 3
            3 -- "#quot;0#quot;" --> 3
            3 -- "#quot;1#quot;" --> 0
        MERMAID
        assert_equal expected, moore.to_mermaid
        assert_predicate moore.to_mermaid, :frozen?
      end

      #: () -> void
      def test_to_dot
        moore = MooreTest.mod4_moore

        expected = <<~'DOT'
          digraph {
            0 [label="0 | 0", shape=circle];
            1 [label="1 | 1", shape=circle];
            2 [label="2 | 2", shape=circle];
            3 [label="3 | 3", shape=circle];

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
        assert_equal expected, moore.to_dot
        assert_predicate moore.to_dot, :frozen?
      end
    end
  end
end
