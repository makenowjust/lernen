# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/kearns_vazirani/discrimination_tree"
require "lernen/algorithm/kearns_vazirani/kearns_vazirani_learner"

module Lernen
  module Algorithm
    # KearnzVazirani provides an implementation of Kearnz-Vazirani algorithm.
    #
    # Kearns-Vazirani is introduced by [Kearns & Vazirani (1994) "An Introduction to
    # Computational Learning Theory"](https://direct.mit.edu/books/monograph/2604/An-Introduction-to-Computational-Learning-Theory).
    module KearnsVazirani
      # Runs Kearns-Vazirani algorithm and returns an inferred automaton.
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
        learner = KearnsVaziraniLearner.new(alphabet, sul, automaton_type:, cex_processing:)
        learner.learn(oracle, repeats_cex_evaluation:, max_learning_rounds:)
      end
    end
  end
end
