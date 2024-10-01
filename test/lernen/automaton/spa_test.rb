# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class SPATest < Minitest::Test
      #: () -> Lernen::Automaton::SPA[String, Symbol, Symbol]
      def self.palindrome_spa # steep:ignore
        SPA.new(
          :F,
          :↵,
          {
            F:
              DFA.new(
                0,
                Set[0, 1, 3, 5],
                {
                  [0, "a"] => 1,
                  [0, "b"] => 3,
                  [0, "c"] => 6,
                  [0, :F] => 6,
                  [0, :G] => 5,
                  [1, "a"] => 6,
                  [1, "b"] => 6,
                  [1, "c"] => 6,
                  [1, :F] => 2,
                  [1, :G] => 6,
                  [2, "a"] => 5,
                  [2, "b"] => 6,
                  [2, "c"] => 6,
                  [2, :F] => 6,
                  [2, :G] => 6,
                  [3, "a"] => 6,
                  [3, "b"] => 6,
                  [3, "c"] => 6,
                  [3, :F] => 4,
                  [3, :G] => 6,
                  [4, "a"] => 6,
                  [4, "b"] => 5,
                  [4, "c"] => 6,
                  [4, :F] => 6,
                  [4, :G] => 6,
                  [5, "a"] => 6,
                  [5, "b"] => 6,
                  [5, "c"] => 6,
                  [5, :F] => 6,
                  [5, :G] => 6,
                  [6, "a"] => 6,
                  [6, "b"] => 6,
                  [6, "c"] => 6,
                  [6, :F] => 6,
                  [6, :G] => 6
                }
              ),
            G:
              DFA.new(
                0,
                Set[1, 3],
                {
                  [0, "a"] => 4,
                  [0, "b"] => 4,
                  [0, "c"] => 1,
                  [0, :F] => 3,
                  [0, :G] => 4,
                  [1, "a"] => 4,
                  [1, "b"] => 4,
                  [1, "c"] => 4,
                  [1, :F] => 4,
                  [1, :G] => 2,
                  [2, "a"] => 4,
                  [2, "b"] => 4,
                  [2, "c"] => 3,
                  [2, :F] => 4,
                  [2, :G] => 4,
                  [3, "a"] => 4,
                  [3, "b"] => 4,
                  [3, "c"] => 4,
                  [3, :F] => 4,
                  [3, :G] => 4,
                  [4, "a"] => 4,
                  [4, "b"] => 4,
                  [4, "c"] => 4,
                  [4, :F] => 4,
                  [4, :G] => 4
                }
              )
          }
        )
      end

      #: () -> void
      def test_run
        spa = SPATest.palindrome_spa

        assert_equal [[], :init], spa.run([])
        assert_equal [[false, true], :term], spa.run(%i[F ↵])
      end

      #: () -> void
      def test_to_mermaid
        spa = SPATest.palindrome_spa

        expected = <<~MERMAID
          flowchart TD
            subgraph g0[":F"]
              g0_0((("0")))
              g0_1((("1")))
              g0_2(("2"))
              g0_3((("3")))
              g0_4(("4"))
              g0_5((("5")))

              g0_0 -- "#quot;a#quot;" --> g0_1
              g0_0 -- "#quot;b#quot;" --> g0_3
              g0_0 -- ":G" --> g0_5
              g0_1 -- ":F" --> g0_2
              g0_2 -- "#quot;a#quot;" --> g0_5
              g0_3 -- ":F" --> g0_4
              g0_4 -- "#quot;b#quot;" --> g0_5
            end

            subgraph g1[":G"]
              g1_0(("0"))
              g1_1((("1")))
              g1_2(("2"))
              g1_3((("3")))

              g1_0 -- "#quot;c#quot;" --> g1_1
              g1_0 -- ":F" --> g1_3
              g1_1 -- ":G" --> g1_2
              g1_2 -- "#quot;c#quot;" --> g1_3
            end
          MERMAID
        assert_equal expected, spa.to_mermaid
        assert_predicate spa.to_mermaid, :frozen?
      end

      #: () -> void
      def test_to_dot
        spa = SPATest.palindrome_spa

        expected = <<~'DOT'
          digraph {
            subgraph cluster_g0 {
              label=":F";
              g0_0 [label="0", shape=doublecircle];
              g0_1 [label="1", shape=doublecircle];
              g0_2 [label="2", shape=circle];
              g0_3 [label="3", shape=doublecircle];
              g0_4 [label="4", shape=circle];
              g0_5 [label="5", shape=doublecircle];
          
              g0_0 -> g0_1 [label="\"a\""];
              g0_0 -> g0_3 [label="\"b\""];
              g0_0 -> g0_5 [label=":G"];
              g0_1 -> g0_2 [label=":F"];
              g0_2 -> g0_5 [label="\"a\""];
              g0_3 -> g0_4 [label=":F"];
              g0_4 -> g0_5 [label="\"b\""];
            }
          
            subgraph cluster_g1 {
              label=":G";
              g1_0 [label="0", shape=circle];
              g1_1 [label="1", shape=doublecircle];
              g1_2 [label="2", shape=circle];
              g1_3 [label="3", shape=doublecircle];
          
              g1_0 -> g1_1 [label="\"c\""];
              g1_0 -> g1_3 [label=":F"];
              g1_1 -> g1_2 [label=":G"];
              g1_2 -> g1_3 [label="\"c\""];
            }
          }
        DOT
        assert_equal expected, spa.to_dot
        assert_predicate spa.to_dot, :frozen?
      end
    end
  end
end
