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
            0(("0"))
            1(("1"))
            2(("2"))
            3(("3"))

            0 -- "#quot;0#quot; | 0" --> 0
            0 -- "#quot;1#quot; | 1" --> 1
            1 -- "#quot;0#quot; | 1" --> 1
            1 -- "#quot;1#quot; | 2" --> 2
            2 -- "#quot;0#quot; | 2" --> 2
            2 -- "#quot;1#quot; | 3" --> 3
            3 -- "#quot;0#quot; | 3" --> 3
            3 -- "#quot;1#quot; | 0" --> 0
        MERMAID
        assert_equal expected, mealy.to_mermaid
        assert_predicate mealy.to_mermaid, :frozen?
      end

      #: () -> void
      def test_to_dot
        mealy = MealyTest.mod4_mealy

        expected = <<~'DOT'
          digraph {
            0 [label="0", shape=circle];
            1 [label="1", shape=circle];
            2 [label="2", shape=circle];
            3 [label="3", shape=circle];

            0 -> 0 [label="\"0\" | 0"];
            0 -> 1 [label="\"1\" | 1"];
            1 -> 1 [label="\"0\" | 1"];
            1 -> 2 [label="\"1\" | 2"];
            2 -> 2 [label="\"0\" | 2"];
            2 -> 3 [label="\"1\" | 3"];
            3 -> 3 [label="\"0\" | 3"];
            3 -> 0 [label="\"1\" | 0"];
          }
        DOT
        assert_equal expected, mealy.to_dot
        assert_predicate mealy.to_dot, :frozen?
      end

      #: () -> void
      def test_from_and_to_automata_wiki_dot
        # From https://automata.cs.ru.nl/Syntax/Mealy.
        mealy, state_to_name = Mealy.from_automata_wiki_dot(<<~DOT)
          digraph g {
            __start0 [label="" shape="none"];
            __start0 -> s0;

            s0 [shape="circle" label="s0"];
            s1 [shape="circle" label="s1"];
            s2 [shape="circle" label="s2"];
            s3 [shape="circle" label="s3"];
            s4 [shape="circle" label="s4"];
            s5 [shape="circle" label="s5"];

            s0 -> s4 [label="WATER / ok"];
            s0 -> s2 [label="POD / ok"];
            s0 -> s1 [label="BUTTON / error"];
            s0 -> s0 [label="CLEAN / ok"];
            s1 -> s1 [label="WATER / error"];
            s1 -> s1 [label="POD / error"];
            s1 -> s1 [label="BUTTON / error"];
            s1 -> s1 [label="CLEAN / error"];
            s2 -> s3 [label="WATER / ok"];
            s2 -> s2 [label="POD / ok"];
            s2 -> s1 [label="BUTTON / error"];
            s2 -> s0 [label="CLEAN / ok"];
            s3 -> s3 [label="WATER / ok"];
            s3 -> s3 [label="POD / ok"];
            s3 -> s5 [label="BUTTON / coffee!"];
            s3 -> s0 [label="CLEAN / ok"];
            s4 -> s4 [label="WATER / ok"];
            s4 -> s3 [label="POD / ok"];
            s4 -> s1 [label="BUTTON / error"];
            s4 -> s0 [label="CLEAN / ok"];
            s5 -> s1 [label="WATER / error"];
            s5 -> s1 [label="POD / error"];
            s5 -> s1 [label="BUTTON / error"];
            s5 -> s0 [label="CLEAN / ok"];
          }
        DOT
        source = mealy.to_automata_wiki_dot(state_to_name)

        assert_equal <<~DOT, source
          digraph {
            __start0 [label="", shape=none];
            s0 [label="s0", shape=circle];
            s1 [label="s1", shape=circle];
            s2 [label="s2", shape=circle];
            s3 [label="s3", shape=circle];
            s4 [label="s4", shape=circle];
            s5 [label="s5", shape=circle];

            __start0 -> s0;
            s0 -> s4 [label="WATER / ok"];
            s0 -> s2 [label="POD / ok"];
            s0 -> s1 [label="BUTTON / error"];
            s0 -> s0 [label="CLEAN / ok"];
            s1 -> s1 [label="WATER / error"];
            s1 -> s1 [label="POD / error"];
            s1 -> s1 [label="BUTTON / error"];
            s1 -> s1 [label="CLEAN / error"];
            s2 -> s3 [label="WATER / ok"];
            s2 -> s2 [label="POD / ok"];
            s2 -> s1 [label="BUTTON / error"];
            s2 -> s0 [label="CLEAN / ok"];
            s3 -> s3 [label="WATER / ok"];
            s3 -> s3 [label="POD / ok"];
            s3 -> s5 [label="BUTTON / coffee!"];
            s3 -> s0 [label="CLEAN / ok"];
            s4 -> s4 [label="WATER / ok"];
            s4 -> s3 [label="POD / ok"];
            s4 -> s1 [label="BUTTON / error"];
            s4 -> s0 [label="CLEAN / ok"];
            s5 -> s1 [label="WATER / error"];
            s5 -> s1 [label="POD / error"];
            s5 -> s1 [label="BUTTON / error"];
            s5 -> s0 [label="CLEAN / ok"];
          }
        DOT
      end
    end
  end
end
