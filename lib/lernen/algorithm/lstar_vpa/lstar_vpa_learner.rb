# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module LStarVPA
      # LStarLearner is an implementation of Angluin's L* algorithm extended for VPA.
      #
      # @rbs generic In     -- Type for input alphabet
      # @rbs generic Call   -- Type for call alphabet
      # @rbs generic Return -- Type for return alphabet
      class LStarVPALearner < Learner #[In | Call | Return, bool]
        # @rbs @table: ObservationTableVPA[In, Call, Return]

        #: (
        #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
        #    System::SUL[In | Call | Return, bool] sul,
        #    ?cex_processing: cex_processing_method
        #  ) -> void
        def initialize(alphabet, call_alphabet, return_alphabet, sul, cex_processing: :binary)
          super()

          @table = ObservationTableVPA.new(alphabet.dup, call_alphabet.dup, return_alphabet.dup, sul, cex_processing:)
        end

        # @rbs override
        def build_hypothesis
          @table.build_hypothesis
        end

        # @rbs override
        def refine_hypothesis(cex, hypothesis, state_to_prefix)
          @table.refine_hypothesis(cex, hypothesis, state_to_prefix) # steep:ignore
        end
      end
    end
  end
end
