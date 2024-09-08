# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../test_helper"

require_relative "automaton/dfa_test"
require_relative "automaton/mealy_test"
require_relative "automaton/moore_test"
require_relative "automaton/vpa_test"

module Lernen
  class SystemTest < Minitest::Test
    #: () -> void
    def test_from_block
      sul = System.from_block { _1.count("1") % 4 == 3 }

      assert_equal [false, false, true, false], sul.query(%w[1 1 1 1])
    end

    #: () -> void
    def test_from_automaton
      dfa_sul = System.from_automaton(Automaton::DFATest.mod4_dfa)
      mealy_sul = System.from_automaton(Automaton::MealyTest.mod4_mealy)
      moore_sul = System.from_automaton(Automaton::MooreTest.mod4_moore)
      vpa_sul = System.from_automaton(Automaton::VPATest.dyck_vpa)

      assert_equal [false, false, true, false], dfa_sul.query(%w[1 1 1 1])
      assert_equal [1, 2, 3, 0], mealy_sul.query(%w[1 1 1 1])
      assert_equal [1, 2, 3, 0], moore_sul.query(%w[1 1 1 1])
      assert_equal [false, false, true], vpa_sul.query(%w[( 1 )])
    end
  end
end
