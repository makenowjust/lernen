# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module Automaton
    class ProcUtilTest < Minitest::Test
      #: () -> void
      def test_expand
        assert_equal ["1", :C, "(", ")", :R, "1"], ProcUtil.expand(:R, ["1", :C, "1"], { C: %w[( )] })
      end

      #: () -> void
      def test_project
        assert_equal ["1", :C, "1"], ProcUtil.project(Set[:C], :R, ["1", :C, "(", ")", :R, "1"])
      end

      #: () -> void
      def test_find_call_index
        call_alphabet_set = Set[:C]
        return_input = :R
        find_call_index = ->(word, index) { ProcUtil.find_call_index(call_alphabet_set, return_input, word, index) }

        assert_equal 0, find_call_index.call([:C, "(", "1", ")", :R], 4)
        assert_equal 0, find_call_index.call([:C, "(", :C, "1", :R, ")", :R], 6)
        assert_nil find_call_index.call([:C, "(", "1", ")", :R], 5)
      end

      #: () -> void
      def test_find_return_index
        call_alphabet_set = Set[:C]
        return_input = :R
        find_return_index = ->(word, index) { ProcUtil.find_return_index(call_alphabet_set, return_input, word, index) }

        assert_equal 4, find_return_index.call([:C, "(", "1", ")", :R], 1)
        assert_equal 6, find_return_index.call([:C, "(", :C, "1", :R, ")", :R], 1)
        assert_nil find_return_index.call([:C, "(", "1", ")", :R], 0)
      end
    end
  end
end
