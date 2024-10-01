# frozen_string_literal: true
# rbs_inline: enabled

require "lernen/algorithm/lsharp/observation_tree"
require "lernen/algorithm/lsharp/lsharp_learner"

module Lernen
  module Algorithm
    # LSharp provides an implementation of L# algorithm.
    #
    # L# is introduced by [Vaandrager et al. (2022) "A New Approach for Active
    # Automata Learning Based on Apartness"](https://link.springer.com/chapter/10.1007/978-3-030-99524-9_12).
    module LSharp
      # Runs the L# algorithm and returns an inferred automaton.
      #
      #: [In] (
      #    Array[In] alphabet,
      #    System::SUL[In, bool] sul,
      #    Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn(alphabet, sul, oracle, automaton_type:, max_learning_rounds: nil) # steep:ignore
        learner = LSharpLearner.new(alphabet, sul, automaton_type:)
        learner.learn(oracle, max_learning_rounds:)
      end
    end
  end
end
