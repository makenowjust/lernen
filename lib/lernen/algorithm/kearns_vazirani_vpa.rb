# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/kearns_vazirani_vpa/discrimination_tree_vpa"
require "lernen/algorithm/kearns_vazirani_vpa/kearns_vazirani_vpa_learner"

module Lernen
  module Algorithm
    # KearnzVaziraniVPA provides an implementation of Kearnz-Vazirani algorithm for VPA.
    #
    # The idea behind this implementation is described by [Isberner (2015) "Foundations
    # of Active Automata Learning: An Algorithmic Overview"](https://eldorado.tu-dortmund.de/handle/2003/34282).
    module KearnsVaziraniVPA
      # Runs Kearns-Vazirani algorithm for VPA and returns an inferred VPA.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
      #    System::MooreLikeSUL[In | Call | Return, bool] sul, Equiv::Oracle[In | Call | Return, bool] oracle,
      #    ?cex_processing: cex_processing_method, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::VPA[In, Call, Return]
      def self.learn( # steep:ignore
        alphabet,
        call_alphabet,
        return_alphabet,
        sul,
        oracle,
        cex_processing: :binary,
        max_learning_rounds: nil
      )
        learner = KearnsVaziraniVPALearner.new(alphabet, call_alphabet, return_alphabet, sul, cex_processing:)
        learner.learn(oracle, max_learning_rounds:)
      end
    end
  end
end
