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
            0("0 | 0")
            1("1 | 1")
            2("2 | 2")
            3("3 | 3")

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
            0 [label="{ 0 | 0 }", shape=record, style=rounded];
            1 [label="{ 1 | 1 }", shape=record, style=rounded];
            2 [label="{ 2 | 2 }", shape=record, style=rounded];
            3 [label="{ 3 | 3 }", shape=record, style=rounded];

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

      #: () -> void
      def test_from_and_to_automata_wiki_dot
        # From https://automata.cs.ru.nl/Syntax/Moore.
        moore, state_to_name = Moore.from_automata_wiki_dot(<<~DOT)
          digraph g {
            __start0 [label="" shape="none"];
            __start0 -> A;

    	      A [shape="record", style="rounded", label="{ A | 0 }"];
    	      B [shape="record", style="rounded", label="{ B | 0 }"];
    	      C [shape="record", style="rounded", label="{ C | 0 }"];
    	      D [shape="record", style="rounded", label="{ D | 0 }"];
    	      E [shape="record", style="rounded", label="{ E | 0 }"];
    	      F [shape="record", style="rounded", label="{ F | 0 }"];
    	      G [shape="record", style="rounded", label="{ G | 0 }"];
    	      H [shape="record", style="rounded", label="{ H | 0 }"];
    	      I [shape="record", style="rounded", label="{ I | 1 }"];

            A -> D [label="0"];
            A -> B [label="1"];
            B -> E [label="0"];
            B -> C [label="1"];
            C -> F [label="0"];
            C -> C [label="1"];
            D -> G [label="0"];
            D -> E [label="1"];
            E -> H [label="0"];
            E -> F [label="1"];
            F -> I [label="0"];
            F -> F [label="1"];
            G -> G [label="0"];
            G -> H [label="1"];
            H -> H [label="0"];
            H -> I [label="1"];
            I -> I [label="0"];
            I -> I [label="1"];
          }
        DOT
        source = moore.to_automata_wiki_dot(state_to_name)

        assert_equal <<~DOT, source
          digraph {
            __start0 [label="", shape=none];
            A [label="{ A | 0 }", shape=record, style=rounded];
            B [label="{ B | 0 }", shape=record, style=rounded];
            C [label="{ C | 0 }", shape=record, style=rounded];
            D [label="{ D | 0 }", shape=record, style=rounded];
            E [label="{ E | 0 }", shape=record, style=rounded];
            F [label="{ F | 0 }", shape=record, style=rounded];
            G [label="{ G | 0 }", shape=record, style=rounded];
            H [label="{ H | 0 }", shape=record, style=rounded];
            I [label="{ I | 1 }", shape=record, style=rounded];

            __start0 -> A;
            A -> D [label="0"];
            A -> B [label="1"];
            B -> E [label="0"];
            B -> C [label="1"];
            C -> F [label="0"];
            C -> C [label="1"];
            D -> G [label="0"];
            D -> E [label="1"];
            E -> H [label="0"];
            E -> F [label="1"];
            F -> I [label="0"];
            F -> F [label="1"];
            G -> G [label="0"];
            G -> H [label="1"];
            H -> H [label="0"];
            H -> I [label="1"];
            I -> I [label="0"];
            I -> I [label="1"];
          }
        DOT
      end
    end
  end
end
