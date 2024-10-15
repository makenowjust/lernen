# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/procedural/atr_manager"
require "lernen/algorithm/procedural/procedural_sul"
require "lernen/algorithm/procedural/return_indices_acex"
require "lernen/algorithm/procedural/procedural_learner"

module Lernen
  module Algorithm
    # Procedural provides an implementation of the learning algorithm for SPA.
    #
    # This algorithm is described in [Frohme & Seffen (2021) "Compositional
    # Learning of Mutually Recursive Procedural Systems"](https://link.springer.com/article/10.1007/s10009-021-00634-y).
    module Procedural
      # Runs the procedural algorithm and returns an inferred SPA.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Return return_input,
      #    System::SUL[In | Call | Return, bool] sul,
      #    Equiv::Oracle[In | Call | Return, bool] oracle,
      #    ?algorithm: :lstar | :kearns_vazirani | :dhc | :lsharp,
      #    ?algorithm_params: Hash[Symbol, untyped],
      #    ?cex_processing: cex_processing_method,
      #    ?scan_procs: bool,
      #    ?repeats_cex_evaluation: bool
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::SPA[In, Call, Return]
      def self.learn( # steep:ignore
        alphabet,
        call_alphabet,
        return_input,
        sul,
        oracle,
        algorithm: :kearns_vazirani,
        algorithm_params: {},
        cex_processing: :binary,
        scan_procs: true,
        repeats_cex_evaluation: true,
        max_learning_rounds: nil
      )
        learner =
          ProceduralLearner.new(
            alphabet,
            call_alphabet,
            return_input,
            sul,
            algorithm:,
            algorithm_params:,
            cex_processing:,
            scan_procs:
          )
        learner.learn(oracle, repeats_cex_evaluation:, max_learning_rounds:)
      end
    end
  end
end
