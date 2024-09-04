# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require_relative "../automaton/moore_test"

module Lernen
  module System
    class MooreLikeSimulatorTest < Minitest::Test
      #: () -> void
      def test_step
        sul = MooreLikeSimulator.new(Automaton::MooreTest.mod4_moore)

        sul.setup

        assert_equal 0, sul.step("0")
        assert_equal 1, sul.step("1")
        assert_equal 2, sul.step("1")
        assert_equal 3, sul.step("1")

        sul.shutdown
      end

      #: () -> void
      def test_query_and_stats
        sul = MooreLikeSimulator.new(Automaton::MooreTest.mod4_moore)

        assert_equal [0], sul.query(%w[0])
        assert_equal [1, 2, 3], sul.query(%w[1 1 1])
        assert_equal [1, 2, 3, 0], sul.query(%w[1 1 1 1])

        # This assertion is for cache testing.
        assert_equal [1, 2, 3, 0], sul.query(%w[1 1 1 1])

        expected_stats = { num_cache: 3, num_cached_queries: 1, num_queries: 3, num_steps: 8 }

        assert_equal expected_stats, sul.stats

        sul_no_cache = MooreLikeSimulator.new(Automaton::MooreTest.mod4_moore, cache: false)

        assert_equal [0], sul_no_cache.query(%w[0])
        assert_equal [1, 2, 3], sul_no_cache.query(%w[1 1 1])
        assert_equal [1, 2, 3, 0], sul_no_cache.query(%w[1 1 1 1])

        # This assertion is for cache testing.
        assert_equal [1, 2, 3, 0], sul_no_cache.query(%w[1 1 1 1])

        expected_stats = { num_cache: 0, num_cached_queries: 0, num_queries: 4, num_steps: 12 }

        assert_equal expected_stats, sul_no_cache.stats
      end

      #: () -> void
      def test_query_empty
        sul = MooreLikeSimulator.new(Automaton::MooreTest.mod4_moore)

        assert_equal 0, sul.query_empty
      end
    end
  end
end
