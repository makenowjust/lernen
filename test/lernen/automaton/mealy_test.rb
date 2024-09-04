# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class MealyTest < Minitest::Test
      #: () -> Lernen::Automaton::Mealy[String, Integer]
      def self.mod4_mealy
        Lernen::Automaton::Mealy.new(
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
      end

      #: () -> void
      def test_run
        mealy = MealyTest.mod4_mealy

        assert_equal [[], 0], mealy.run([])
        assert_equal [[0], 0], mealy.run(%w[0])
        assert_equal [[1], 1], mealy.run(%w[1])
        assert_equal [[1, 2, 3], 3], mealy.run(%w[1 1 1])
        assert_equal [[1, 2, 3, 0], 0], mealy.run(%w[1 1 1 1])
      end

      #: () -> void
      def test_to_mermaid
        mealy = MealyTest.mod4_mealy

        expected = <<~MERMAID
          flowchart TD
            0((0))
            1((1))
            2((2))
            3((3))

            0 -- "'0'|'0'" --> 0
            0 -- "'1'|'1'" --> 1
            1 -- "'0'|'1'" --> 1
            1 -- "'1'|'2'" --> 2
            2 -- "'0'|'2'" --> 2
            2 -- "'1'|'3'" --> 3
            3 -- "'0'|'3'" --> 3
            3 -- "'1'|'0'" --> 0
        MERMAID
        assert_equal expected, mealy.to_mermaid
        assert_predicate mealy.to_mermaid, :frozen?
      end
    end
  end
end
