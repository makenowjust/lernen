# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # LStar is an implementation of Angluin's L* algorithm.
    #
    # Angluin's L* is introduced by [Angluin (1987) "Learning Regular Sets from
    # Queries and Counterexamples"](https://dl.acm.org/doi/10.1016/0890-5401%2887%2990052-6).
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class LStar < Learner #[In, Out]
      # Runs Angluin's L* algoritghm and returns an inferred automaton.
      #
      # `cex_processing` is used for determining a method of counterexample processing.
      # In additional to predefined `cex_processing_method`, we can specify `nil` as `cex_processing`.
      # When `cex_processing: nil` is specified, it uses the original counterexample processing
      # described in the Angluin paper.
      #
      #: [In] (
      #    Array[In] alphabet, System::SUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn( # steep:ignore
        alphabet,
        sul,
        oracle,
        automaton_type:,
        cex_processing: :binary,
        max_learning_rounds: nil
      )
        learner = new(alphabet, sul, oracle, automaton_type:, cex_processing:)
        learner.learn(max_learning_rounds:)
      end

      # @rbs @alphabet: Array[In]
      # @rbs @oracle: Equiv::Oracle[In, Out]
      # @rbs @table: ObservationTable[In, Out]

      #: (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :dfa | :moore | :mealy,
      #    ?cex_processing: cex_processing_method | nil
      #  ) -> void
      def initialize(alphabet, sul, oracle, automaton_type:, cex_processing: :binary)
        super()

        @alphabet = alphabet.dup
        @oracle = oracle

        @table = ObservationTable.new(@alphabet, sul, automaton_type:, cex_processing:)
      end

      # @rbs override
      def add_alphabet(input)
        @alphabet << input
      end

      private

      # @rbs override
      attr_reader :oracle

      # @rbs override
      def build_hypothesis
        @table.build_hypothesis
      end

      # @rbs override
      def refine_hypothesis(cex, hypothesis, state_to_prefix)
        @table.refine_hypothesis(cex, hypothesis, state_to_prefix)
      end
    end
  end
end
