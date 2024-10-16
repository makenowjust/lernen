# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module System
    # SUL represents a system under learning.
    #
    # It is an abtraction of a system under learning (SUL) which accepts an operation
    # called "membership query"; it takes an input string (word) and returns a sequence
    # of outputs corresponding to the input string.
    #
    # This SUL assumes the system is much like Mealy machine; that is, a transition puts
    # an output, and query does not accept the empty string due to no outputs.
    #
    # This SUL also implements cache mechanism. The cache mechanism is enabled by the default,
    # and it can be disabled by specifying `cache: false`.
    #
    # On running a SUL, this SUL records the statistics information. We can obtain this
    # information by `SUL#stats`.
    #
    # Note that this class is *abstract*. You should implement the following method:
    #
    # - `#step(input)`
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class SUL
      # @rbs @cache: Hash[Array[In], Out] | nil
      # @rbs @num_cached_queries: Integer
      # @rbs @num_queries: Integer
      # @rbs @num_steps: Integer

      #: (?cache: bool) -> void
      def initialize(cache: true)
        @cache = cache ? {} : nil
        @num_cached_queries = 0
        @num_queries = 0
        @num_steps = 0
      end

      # Returns the statistics information as a `Hash` object.
      #
      # The result hash contains the following values.
      #
      # - `num_cache`: The number of cached queries.
      # - `num_cached_queries`: The number of queries uses the cache.
      # - `num_queries`: The number of (non-cached) queries.
      # - `num_steps`: The total number of steps.
      #
      #: () -> Hash[Symbol, Integer]
      def stats
        {
          num_cache: @cache&.size || 0,
          num_cached_queries: @num_cached_queries,
          num_queries: @num_queries,
          num_steps: @num_steps
        }
      end

      # Runs a membership query with the given word.
      #
      #: (Array[In] word) -> Out
      def query_last(word)
        cached = (cache = @cache) && cache[word]
        unless cached.nil? # steep:ignore
          @num_cached_queries += 1
          return cached
        end

        if word.empty?
          raise ArgumentError, "`query` does not accept the empty string. Please use `query_empty` instead."
        end

        setup
        output = step(word[0])
        word[1..]&.each { |input| output = step(input) }
        shutdown

        @num_queries += 1
        @num_steps += word.size

        cache[word.dup] = output if cache

        output
      end

      # rubocop:disable Lint/UnusedMethodArgument

      # It is a setup procedure of this SUL.
      #
      # Note that it does nothing by default.
      #
      #: () -> void
      def setup
      end

      # It is a shutdown procedure of this SUL.
      #
      # Note that it does nothing by default.
      #
      #: () -> void
      def shutdown
      end

      # Consumes the given `input` and returns the correspoding output.
      #
      # This is an abstract method.
      #
      #: (In input) -> Out
      def step(input)
        raise TypeError, "abstract method: `step`"
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
