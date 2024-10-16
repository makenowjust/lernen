# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require_relative "../automaton/mealy_test"

module Lernen
  module System
    class TransitionSystemSimulatorTest < Minitest::Test
      #: () -> void
      def test_step
        sul = TransitionSystemSimulator.new(Automaton::MealyTest.mod4_mealy)

        sul.setup

        assert_equal 0, sul.step("0")
        assert_equal 1, sul.step("1")
        assert_equal 2, sul.step("1")
        assert_equal 3, sul.step("1")

        sul.shutdown
      end

      #: () -> void
      def test_query_and_stats
        sul = TransitionSystemSimulator.new(Automaton::MealyTest.mod4_mealy)

        assert_equal 0, sul.query_last(%w[0])
        assert_equal 3, sul.query_last(%w[1 1 1])
        assert_equal 0, sul.query_last(%w[1 1 1 1])

        # This assertion is for cache testing.
        assert_equal 0, sul.query_last(%w[1 1 1 1])

        expected_stats = { num_cache: 3, num_cached_queries: 1, num_queries: 3, num_steps: 8 }

        assert_equal expected_stats, sul.stats

        sul_no_cache = TransitionSystemSimulator.new(Automaton::MealyTest.mod4_mealy, cache: false)

        assert_equal 0, sul_no_cache.query_last(%w[0])
        assert_equal 3, sul_no_cache.query_last(%w[1 1 1])
        assert_equal 0, sul_no_cache.query_last(%w[1 1 1 1])

        # This assertion is for cache testing.
        assert_equal 0, sul_no_cache.query_last(%w[1 1 1 1])

        expected_stats = { num_cache: 0, num_cached_queries: 0, num_queries: 4, num_steps: 12 }

        assert_equal expected_stats, sul_no_cache.stats
      end
    end
  end
end
