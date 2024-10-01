# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # CombinedOracle provides an implementation of equivalence query
    # that find a counterexample by combining multiple oracles.
    #
    # This takes two oracle. If the first oracle finds a counterexample, then
    # this oracle returns it. Otherwise, it tries the second and other oracles.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class CombinedOracle < Oracle #[In, Out]
      # @rbs @oracles: Array[Oracle[In, Out]]

      def initialize(oracles)
        first_oracle = oracles.first
        raise ArgumentError, "CombinedOracle nedds at least one oracle" unless first_oracle

        sul = oracles.first.sul
        oracles.each { |oracle| raise ArgumentError, "SUL of oracles must be the same" unless sul == oracle.sul }

        super(sul)

        @oracles = oracles
      end

      attr_reader :oracles #: Array[Oracle[In, Out]]

      # @rbs override
      def find_cex(hypothesis)
        super

        oracles.each do |oracle|
          cex = oracle.find_cex(hypothesis)
          return cex if cex
        end

        nil
      end

      # @rbs override
      def stats
        num_queries = 0
        num_steps = 0
        oracles.each do |oracle|
          stats = oracle.stats
          num_queries += stats[:num_queries]
          num_steps += stats[:num_steps]
        end

        { num_calls: @num_calls, num_queries:, num_steps: }
      end
    end
  end
end
