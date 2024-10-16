# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../test_helper"

require_relative "automaton/dfa_test"
require_relative "automaton/mealy_test"
require_relative "automaton/moore_test"
require_relative "automaton/spa_test"
require_relative "automaton/vpa_test"

module Lernen
  class SystemTest < Minitest::Test
    #: () -> void
    def test_from_block
      sul = System.from_block { _1.count("1") % 4 == 3 }

      refute sul.query_last(%w[1 1 1 1])
    end

    #: () -> void
    def test_from_automaton
      dfa_sul = System.from_automaton(Automaton::DFATest.mod4_dfa)
      mealy_sul = System.from_automaton(Automaton::MealyTest.mod4_mealy)
      moore_sul = System.from_automaton(Automaton::MooreTest.mod4_moore)
      spa_sul = System.from_automaton(Automaton::SPATest.palindrome_spa)
      vpa_sul = System.from_automaton(Automaton::VPATest.dyck_vpa)

      refute dfa_sul.query_last(%w[1 1 1 1])
      assert_equal 0, mealy_sul.query_last(%w[1 1 1 1])
      assert_equal 0, moore_sul.query_last(%w[1 1 1 1])
      assert spa_sul.query_last(%i[F ↵])
      assert vpa_sul.query_last(%w[( 1 )])
    end
  end
end
