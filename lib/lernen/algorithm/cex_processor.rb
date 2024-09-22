# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # @rbs!
    #   type cex_processing_method = :linear | :binary | :exponential

    # CexProcessor contains implementations of counterexample processing functions.
    #
    # A counterexample is a word that leads to the different result between
    # a hypothesis automaton and a SUL (i.e., `hypothesis.run(cex)[0].last != sul.query_last(cex)`).
    # Where `h[n] = conf_to_prefix[hypothesis.run(cex[0...n])[1]]`, there
    # are some `n` (where `0 <= n < cex.size`) such that
    # `sul.query_last(h[n] + cex[n...]) != sul.query_last(h[n + 1] + cex[n + 1...])`
    # because `sul.query_last(cex) == sul.query_last(h[0] + cex[n...])` and
    # `sul.query_last(h[cex.size] + cex[cex.size...]) == hypothesis.run(cex)[0].last`.
    # Finding such a position `n` from `cex` is called "counterexample processing".
    #
    # The result `n` of counterexample processing has a good property for automata
    # learning. Because `sul.query_last(h[n] + cex[n...]) != sul.query_last(h[n + 1] + cex[n + 1...])`,
    # a prefix `h[n] + cex[n]` leads a different state than a state of `h[n + 1]`
    # with a suffix `cex[n + 1...]`.
    #
    # For counterexample processing, we can use some searching approach such like
    # linear or binrary search. Using binary search for counterexample processing,
    # it is known as the Rivest-Schapire (RS) optimization typically. For the more
    # detailed information, please refer [Isberner and Steffen (2014) "An Abstract
    # Framework for Counterexample Analysis in Active Automata Learning"](https://proceedings.mlr.press/v34/isberner14a).
    module CexProcessor
      # Processes a given counterexample in the `cex_processing` way.
      #
      # It returns `n` such that `acex.effect(n) != acex.effect(n + 1)`.
      #
      #: (
      #    Acex acex,
      #    ?cex_processing: cex_processing_method
      #  ) -> Integer
      def self.process(acex, cex_processing: :binary)
        low = 0
        high = acex.size - 1
        case cex_processing
        in :linear
          process_linear(acex, low:, high:)
        in :binary
          process_binary(acex, low:, high:)
        in :exponential
          process_exponential(acex, low:, high:)
        end
      end

      private

      # Processes a given counterexample by linear search.
      #
      #: (Acex acex, low: Integer, high: Integer) -> Integer
      def self.process_linear(acex, low:, high:)
        prev_eff = acex.effect(low)
        index = low + 1
        while index <= high
          eff = acex.effect(index)
          return index - 1 if prev_eff != eff
          index += 1
          prev_eff = eff
        end

        raise ArgumentError
      end

      # Processes a given counterexample by binary search.
      #
      # It is known as the Rivest-Schapire (RS) optimization.
      #
      #: (Acex acex, low: Integer, high: Integer) -> Integer
      def self.process_binary(acex, low:, high:)
        low_eff = acex.effect(low)

        while high - low > 1
          mid = low + ((high - low) / 2)
          mid_eff = acex.effect(mid)
          if low_eff == mid_eff
            low = mid
          else
            high = mid
          end
        end

        low
      end

      # Processes a given counterexample by exponential seatch.
      #
      #: (Acex acex, low: Integer, high: Integer) -> Integer
      def self.process_exponential(acex, low:, high:)
        ofs = 1
        low_eff = acex.effect(low)

        while low + ofs < high
          index = low + ofs
          eff = acex.effect(index)
          break if low_eff != eff
          low = index
          ofs *= 2
        end

        process_binary(acex, low:, high:)
      end

      private_class_method :process_linear, :process_binary, :process_exponential
    end
  end
end
