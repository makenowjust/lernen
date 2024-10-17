# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class VPATest < Minitest::Test
      #: () -> Lernen::Automaton::VPA[String, String, String]
      def self.dyck_vpa
        VPA.new(
          0,
          Set[1],
          { [0, "0"] => 0, [0, "1"] => 1, [1, "0"] => 1, [1, "1"] => 1 },
          { [0, ")"] => { [0, "("] => 0, [1, "("] => 1 }, [1, ")"] => { [0, "("] => 1, [1, "("] => 1 } }
        )
      end

      #: () -> void
      def test_run
        vpa = VPATest.dyck_vpa

        assert_equal [false, VPA::Conf[0, []]], vpa.run([])
      end

      #: () -> void
      def test_to_mermaid
        vpa = VPATest.dyck_vpa

        expected = <<~MERMAID
          flowchart TD
            0(("0"))
            1((("1")))

            0 -- "#quot;0#quot;" --> 0
            0 -- "#quot;1#quot;" --> 1
            1 -- "#quot;0#quot;" --> 1
            1 -- "#quot;1#quot;" --> 1
            0 -- "#quot;)#quot; / (0, #quot;(#quot;)" --> 0
            0 -- "#quot;)#quot; / (1, #quot;(#quot;)" --> 1
            1 -- "#quot;)#quot; / (0, #quot;(#quot;)" --> 1
            1 -- "#quot;)#quot; / (1, #quot;(#quot;)" --> 1
        MERMAID
        assert_equal expected, vpa.to_mermaid
        assert_predicate vpa.to_mermaid, :frozen?
      end

      #: () -> void
      def test_to_dot
        vpa = VPATest.dyck_vpa

        expected = <<~'DOT'
          digraph {
            0 [label="0", shape=circle];
            1 [label="1", shape=doublecircle];

            0 -> 0 [label="\"0\""];
            0 -> 1 [label="\"1\""];
            1 -> 1 [label="\"0\""];
            1 -> 1 [label="\"1\""];
            0 -> 0 [label="\")\" / (0, \"(\")"];
            0 -> 1 [label="\")\" / (1, \"(\")"];
            1 -> 1 [label="\")\" / (0, \"(\")"];
            1 -> 1 [label="\")\" / (1, \"(\")"];
          }
        DOT
        assert_equal expected, vpa.to_dot
        assert_predicate vpa.to_dot, :frozen?
      end

      #: () -> void
      def test_from_and_to_automata_wiki_dot
        vpa, state_to_name = VPA.from_automata_wiki_dot(<<~DOT)
          digraph g {
            __start0 [label="" shape="none"]
            __start0 -> s0

            s0 [shape="circle" label="s0"]
            s1 [shape="doublecircle" label="s1"]

            s0 -> s0 [label="0"]
            s0 -> s1 [label="1"]
            s1 -> s1 [label="0"]
            s1 -> s1 [label="1"]
            s0 -> s0 [label=") / (s0, ()"]
            s0 -> s1 [label=") / (s1, ()"]
            s1 -> s1 [label=") / (s0, ()"]
            s1 -> s1 [label=") / (s1, ()"]
          }
        DOT
        source = vpa.to_automata_wiki_dot(state_to_name)

        assert_equal <<~DOT, source
          digraph {
            __start0 [label="", shape=none];
            s0 [label="s0", shape=circle];
            s1 [label="s1", shape=doublecircle];

            __start0 -> s0;
            s0 -> s0 [label="0"];
            s0 -> s1 [label="1"];
            s1 -> s1 [label="0"];
            s1 -> s1 [label="1"];
            s0 -> s0 [label=") / (s0, ()"];
            s0 -> s1 [label=") / (s1, ()"];
            s1 -> s1 [label=") / (s0, ()"];
            s1 -> s1 [label=") / (s1, ()"];
          }
        DOT
      end
    end
  end
end
