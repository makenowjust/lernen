# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/lstar_vpa/observation_table_vpa"
require "lernen/algorithm/lstar_vpa/lstar_vpa_learner"

module Lernen
  module Algorithm
    # LStarVPA provides an implementation of L* algorithm for VPA.
    #
    # The idea behind this implementation is described by [Isberner (2015) "Foundations
    # of Active Automata Learning: An Algorithmic Overview"](https://eldorado.tu-dortmund.de/handle/2003/34282).
    module LStarVPA
      # Runs L* algorithm for VPA and returns an inferred VPA.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
      #    System::MooreLikeSUL[In | Call | Return, bool] sul, Equiv::Oracle[In | Call | Return, bool] oracle,
      #    ?cex_processing: cex_processing_method, ?repeats_cex_evaluation: bool, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::VPA[In, Call, Return]
      def self.learn( # steep:ignore
        alphabet,
        call_alphabet,
        return_alphabet,
        sul,
        oracle,
        cex_processing: :binary,
        repeats_cex_evaluation: true,
        max_learning_rounds: nil
      )
        learner = LStarVPALearner.new(alphabet, call_alphabet, return_alphabet, sul, cex_processing:)
        learner.learn(oracle, repeats_cex_evaluation:, max_learning_rounds:)
      end
    end
  end
end
