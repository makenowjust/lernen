# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module LStar
      # LStarLearner is an implementation of Angluin's L* algorithm.
      #
      # Angluin's L* is introduced by [Angluin (1987) "Learning Regular Sets from
      # Queries and Counterexamples"](https://dl.acm.org/doi/10.1016/0890-5401%2887%2990052-6).
      #
      # @rbs generic In  -- Type for input alphabet
      # @rbs generic Out -- Type for output values
      class LStarLearner < Learner #[In, Out]
        # @rbs @alphabet: Array[In]
        # @rbs @oracle: Equiv::Oracle[In, Out]
        # @rbs @table: ObservationTable[In, Out]

        #: (
        #    Array[In] alphabet, System::SUL[In, Out] sul,
        #    automaton_type: :dfa | :moore | :mealy,
        #    ?cex_processing: cex_processing_method | nil
        #  ) -> void
        def initialize(alphabet, sul, automaton_type:, cex_processing: :binary)
          super()

          @alphabet = alphabet.dup

          @table = ObservationTable.new(@alphabet, sul, automaton_type:, cex_processing:)
        end

        # @rbs override
        def build_hypothesis
          @table.build_hypothesis
        end

        # @rbs override
        def refine_hypothesis(cex, hypothesis, state_to_prefix)
          @table.refine_hypothesis(cex, hypothesis, state_to_prefix)
        end

        # @rbs override
        def add_alphabet(input)
          @alphabet << input
        end
      end
    end
  end
end
