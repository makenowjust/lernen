# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # @rbs!
    #   type cex_processing_method = :linear | :binary | :exponential
    #
    #   interface _ConfToPrefix[Conf, In]
    #     def []: (Conf conf) -> Array[In]
    #   end

    # CexProcessor contains implementations of counterexample processing functions.
    #
    # A counterexample is a word that leads to the different result between
    # a hypothesis automaton and a SUL (i.e., `hypothesis.run(cex)[0].last != sul.query(cex).last`).
    # Where `h[n] = conf_to_prefix[hypothesis.run(cex[0...n])[1]]`, there
    # are some `n` (where `0 <= n < cex.size`) such that
    # `sul.query(h[n] + cex[n...]).last != sul.query(h[n + 1] + cex[n + 1...]).last`
    # because `sul.query(cex).last == sul.query(h[0] + cex[n...]).last` and
    # `sul.query(h[cex.size] + cex[cex.size...]).last == hypothesis.run(cex)[0].last`.
    # Finding such a position `n` from `cex` is called "counterexample processing".
    #
    # The result `n` of counterexample processing has a good property for automata
    # learning. Because `sul.query(h[n] + cex[n...]).last != sul.query(h[n + 1] + cex[n + 1...]).last`,
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
      # It returns a triple `[cex[0...n], cex[n], cex[n...]]` instead of `n` such that
      # `sul.query(h[n] + cex[n...]).last != sul.query(h[n + 1] + cex[n + 1...]).last`.
      #
      #: [Conf, In, Out] (
      #    System::SUL[In, Out] sul,
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    Array[In] cex,
      #    _ConfToPrefix[Conf, In] conf_to_prefix,
      #    ?cex_processing: cex_processing_method
      #  ) -> [Array[In], In, Array[In]]
      def self.process(sul, hypothesis, cex, conf_to_prefix, cex_processing: :binary)
        case cex_processing
        in :linear
          process_linear(sul, hypothesis, cex, conf_to_prefix)
        in :binary
          process_binary(sul, hypothesis, cex, conf_to_prefix)
        in :exponential
          process_exponential(sul, hypothesis, cex, conf_to_prefix)
        end
      end

      private

      # Processes a given counterexample by linear search.
      #
      #: [Conf, In, Out] (
      #    System::SUL[In, Out] sul,
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    Array[In] cex,
      #    _ConfToPrefix[Conf, In] conf_to_prefix,
      #  ) -> [Array[In], In, Array[In]]
      def self.process_linear(sul, hypothesis, cex, conf_to_prefix)
        expected_output = sul.query(cex).last

        current_conf = hypothesis.initial_conf
        cex.each_with_index do |input, i|
          _, next_conf = hypothesis.step(current_conf, input)

          prefix = conf_to_prefix[next_conf]
          suffix = cex[i + 1...]
          return cex[0...i], input, suffix if expected_output != sul.query(prefix + suffix).last # steep:ignore

          current_conf = next_conf
        end

        raise ArgumentError, "A counterexample processing failed: is `cex` really a counterexample?"
      end

      # Processes a given counterexample by binary search.
      #
      # It is known as the Rivest-Schapire (RS) optimization.
      #
      #: [Conf, In, Out] (
      #    System::SUL[In, Out] sul,
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    Array[In] cex,
      #    _ConfToPrefix[Conf, In] conf_to_prefix,
      #    ?low: Integer
      #  ) -> [Array[In], In, Array[In]]
      def self.process_binary(sul, hypothesis, cex, conf_to_prefix, low: 0) # steep:ignore
        expected_output = sul.query(cex).last

        high = cex.size - 1

        while high - low > 1
          mid = (low + high) / 2
          prefix = cex[0...mid]
          suffix = cex[mid...]

          _, prefix_conf = hypothesis.run(prefix) # steep:ignore
          if expected_output == sul.query(conf_to_prefix[prefix_conf] + suffix).last # steep:ignore
            low = mid
          else
            high = mid
          end
        end

        prefix = cex[0...low]
        suffix = cex[high...]
        [prefix, cex[low], suffix]
      end

      # Processes a given counterexample by exponential seatch.
      #
      #: [Conf, In, Out] (
      #    System::SUL[In, Out] sul,
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    Array[In] cex,
      #    _ConfToPrefix[Conf, In] conf_to_prefix,
      #  ) -> [Array[In], In, Array[In]]
      def self.process_exponential(sul, hypothesis, cex, conf_to_prefix)
        expected_output = sul.query(cex).last

        prev_bp = 0
        bp = 1

        loop do
          if bp >= cex.size
            bp = cex.size
            break
          end

          prefix = cex[0...bp]
          suffix = cex[bp...]

          _, prefix_state = hypothesis.run(prefix) # steep:ignore
          break if expected_output != sul.query(conf_to_prefix[prefix_state] + suffix).last # steep:ignore

          prev_bp = bp
          bp *= 2
        end

        process_binary(sul, hypothesis, cex, conf_to_prefix, low: prev_bp)
      end

      private_class_method :process_linear, :process_binary, :process_exponential
    end
  end
end
