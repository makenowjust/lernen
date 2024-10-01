# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # Oracle is an oracle for answering a equivalence query.
    #
    # On running equivalence queries, this records the statistics information.
    # We can obtain this information by `Oracle#stats`.
    #
    # Note that this class is *abstract*. You should implement the following method:
    #
    # - `#find_cex(hypothesis)`
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class Oracle
      # @rbs @sul: System::SUL[In, Out]
      # @rbs @num_calls: Integer
      # @rbs @num_queries: Integer
      # @rbs @num_steps: Integer
      # @rbs @current_conf: untyped

      #: (System::SUL[In, Out] sul) -> void
      def initialize(sul)
        @sul = sul

        @num_calls = 0
        @num_queries = 0
        @num_steps = 0
        @current_conf = nil
      end

      attr_reader :sul #: System::SUL[In, Out]

      # rubocop:disable Lint/UnusedMethodArgument

      # Finds a conterexample against the given `hypothesis` automaton.
      # If it is found, it returns the counterexample word, or it returns `nil` otherwise.
      #
      # A counterexample means that it separates a sul and a hypothesis automaton on an output
      # value, i.e., `hypothesis.run(cex)[0].last != sul.query_last(cex)`. We also assume
      # a counterexample is minimal; that is, there is no `n` (where `0 <= n < cex.size`)
      # such that `hypothesis.run(cex[0...n])[0].last != sul.query_last(cex[0...n])`.
      #
      #: [Conf] (Automaton::TransitionSystem[Conf, In, Out] hypothesis) -> (Array[In] | nil)
      def find_cex(hypothesis)
        @num_calls += 1
        nil
      end

      # rubocop:enable Lint/UnusedMethodArgument

      # Returns the statistics information as a `Hash` object.
      #
      # The result hash contains the following values.
      #
      # - `num_calls`: The number of calls of `find_cex`.
      # - `num_queries`: The number of queries.
      # - `num_steps`: The total number of steps.
      #
      #: () -> Hash[Symbol, Integer]
      def stats
        { num_calls: @num_calls, num_queries: @num_queries, num_steps: @num_steps }
      end

      # Combines two oracles.
      #
      #: (Oracle[In, Out] other) -> CombinedOracle[In, Out]
      def +(other)
        oracles = []

        is_a?(CombinedOracle) ? oracles.concat(oracles) : oracles << self
        other.is_a?(CombinedOracle) ? oracles.concat(other.oracles) : oracles << other

        CombinedOracle.new(oracles)
      end

      private

      # Resets the internal states of this oracle.
      #
      #: [Conf] (Automaton::TransitionSystem[Conf, In, Out] hypothesis) -> void
      def reset_internal(hypothesis)
        @num_queries += 1

        @current_conf = hypothesis.initial_conf

        @sul.shutdown
        @sul.setup
      end

      # Runs a transition of both a hypothesis and a SUL.
      #
      #: [Conf] (
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    In input
      #  ) -> [Out, Out]
      def step_internal(hypothesis, input)
        @num_steps += 1

        hypothesis_output, @current_conf = hypothesis.step(@current_conf, input)
        sul_output = @sul.step(input)

        [hypothesis_output, sul_output]
      end
    end
  end
end
