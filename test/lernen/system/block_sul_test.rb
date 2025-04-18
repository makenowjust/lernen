# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

module Lernen
  module System
    class BlockSULTest < Minitest::Test
      #: () -> void
      def test_step
        sul = BlockSUL.new { _1.count("1") % 4 == 3 }

        sul.setup

        refute sul.step("1")
        refute sul.step("1")
        assert sul.step("1")

        sul.shutdown
      end

      #: () -> void
      def test_query_last_and_stats
        sul = BlockSUL.new { _1.count("1") % 4 == 3 }

        refute sul.query_last(%w[0])
        assert sul.query_last(%w[1 1 1])
        refute sul.query_last(%w[1 1 1 1])

        # This assertion is for cache testing.
        refute sul.query_last(%w[1 1 1 1])

        expected_stats = { num_cache: 3, num_cached_queries: 1, num_queries: 3, num_steps: 8 }

        assert_equal expected_stats, sul.stats

        sul_no_cache = BlockSUL.new(cache: false) { _1.count("1") % 4 == 3 }

        refute sul_no_cache.query_last(%w[0])
        assert sul_no_cache.query_last(%w[1 1 1])
        refute sul_no_cache.query_last(%w[1 1 1 1])

        # This assertion is for cache testing.
        refute sul_no_cache.query_last(%w[1 1 1 1])

        expected_stats = { num_cache: 0, num_cached_queries: 0, num_queries: 4, num_steps: 12 }

        assert_equal expected_stats, sul_no_cache.stats
      end

      #: () -> void
      def test_query_empty
        sul1 = BlockSUL.new { _1.count("1") % 4 == 3 }
        sul2 = BlockSUL.new { _1.count("1") % 4 == 0 }

        refute sul1.query_empty
        assert sul2.query_empty
      end
    end
  end
end
