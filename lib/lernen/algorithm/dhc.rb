# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/dhc/dhc_learner"

module Lernen
  module Algorithm
    # DHC provides an implementation of DHC.
    #
    # DHC (Dynamic Hypothesis Construction) is introduced by [Merten et al. (2011)
    # "Automata Learning with On-the-Fly Direct Hypothesis Construction"](https://link.springer.com/chapter/10.1007/978-3-642-34781-8_19).
    module DHC
      # Runs DHC algorithm and returns an inferred automaton.
      #
      #: [In] (
      #    Array[In] alphabet, System::SUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?cex_processing: cex_processing_method, ?repeats_cex_evaluation: bool, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?cex_processing: cex_processing_method, ?repeats_cex_evaluation: bool, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?cex_processing: cex_processing_method, ?repeats_cex_evaluation: bool, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn( # steep:ignore
        alphabet,
        sul,
        oracle,
        automaton_type:,
        cex_processing: :binary,
        repeats_cex_evaluation: true,
        max_learning_rounds: nil
      )
        learner = DHCLearner.new(alphabet, sul, automaton_type:, cex_processing:)
        learner.learn(oracle, repeats_cex_evaluation:, max_learning_rounds:)
      end
    end
  end
end
