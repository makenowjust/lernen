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

        assert_equal [[], VPA::Conf[0, []]], vpa.run([])
      end

      #: () -> void
      def test_to_mermaid
        vpa = VPATest.dyck_vpa

        expected = <<~MERMAID
          flowchart TD
            0((0))
            1(((1)))

            0 -- "'0'" --> 0
            0 -- "'1'" --> 1
            1 -- "'0'" --> 1
            1 -- "'1'" --> 1

            0 -- "')'/(0,'(')" --> 0
            0 -- "')'/(1,'(')" --> 1
            1 -- "')'/(0,'(')" --> 1
            1 -- "')'/(1,'(')" --> 1
        MERMAID
        assert_equal expected, vpa.to_mermaid
        assert_predicate vpa.to_mermaid, :frozen?
      end
    end
  end
end
