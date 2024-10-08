# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/lstar/observation_table"
require "lernen/algorithm/lstar/lstar_learner"

module Lernen
  module Algorithm
    # LStar provides an implementation of Angluin's L* algorithm.
    #
    # Angluin's L* is introduced by [Angluin (1987) "Learning Regular Sets from
    # Queries and Counterexamples"](https://dl.acm.org/doi/10.1016/0890-5401%2887%2990052-6).
    module LStar
      # Runs Angluin's L* algorithm and returns an inferred automaton.
      #
      # `cex_processing` is used for determining a method of counterexample processing.
      # In additional to predefined `cex_processing_method`, we can specify `nil` as `cex_processing`.
      # When `cex_processing: nil` is specified, it uses the original counterexample processing
      # described in the Angluin paper.
      #
      #: [In] (
      #    Array[In] alphabet, System::SUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?cex_processing: cex_processing_method | nil, ?repeats_cex_evaluation: bool,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?cex_processing: cex_processing_method | nil, ?repeats_cex_evaluation: bool,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?cex_processing: cex_processing_method | nil, ?repeats_cex_evaluation: bool,
      #    ?max_learning_rounds: Integer | nil
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
        learner = LStarLearner.new(alphabet, sul, automaton_type:, cex_processing:)
        learner.learn(oracle, repeats_cex_evaluation:, max_learning_rounds:)
      end
    end
  end
end
