# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # KearnzVazirani is an implementation of Kearnz-Vazirani algorithm.
    #
    # Kearns-Vazirani is introduced by [Kearns & Vazirani (1994) "An Introduction to
    # Computational Learning Theory"](https://direct.mit.edu/books/monograph/2604/An-Introduction-to-Computational-Learning-Theory).
    module KearnsVazirani
      # Runs Kearns-Vazirani algoritghm and returns an inferred automaton.
      #
      # `max_learning_rounds` is a parameter for specifying the maximum number of iterations for learning.
      # When `max_learning_rounds: nil` is specified, it means the algorithm only stops if the equivalent
      # hypothesis is found.
      #
      #: [In] (
      #    Array[In] alphabet, System::SUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?cex_processing: cex_processing_method, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?cex_processing: cex_processing_method, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?cex_processing: cex_processing_method, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn(alphabet, sul, oracle, automaton_type:, cex_processing: :binary, max_learning_rounds: nil)
        hypothesis = construct_first_hypothesis(alphabet, sul, automaton_type:)
        cex = oracle.find_cex(hypothesis) # steep:ignore
        return hypothesis if cex.nil? # steep:ignore

        tree = DiscriminationTree.new(alphabet, sul, cex:, automaton_type:, cex_processing:)
        learning_rounds = 0

        loop do
          break if max_learning_rounds && learning_rounds == max_learning_rounds
          learning_rounds += 1

          hypothesis, state_to_prefix = tree.build_hypothesis
          cex = oracle.find_cex(hypothesis) # steep:ignore
          break if cex.nil?

          tree.process_cex(hypothesis, cex, state_to_prefix)
        end

        hypothesis, = tree.build_hypothesis
        hypothesis
      end

      private

      # Constructs the first hypothesis automaton.
      #
      #: [In, Out] (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    automaton_type: :dfa | :mealy | :moore
      #  ) -> Automaton::TransitionSystem[Integer, In, Out]
      def self.construct_first_hypothesis(alphabet, sul, automaton_type:)
        transition_function = {}
        alphabet.each do |input|
          case automaton_type
          in :dfa | :moore
            transition_function[[0, input]] = 0
          in :mealy
            out = sul.query_last([input])
            transition_function[[0, input]] = [out, 0]
          end
        end

        case automaton_type
        in :dfa
          accept_state_set = sul.query_empty ? Set[0] : Set.new
          Automaton::DFA.new(0, accept_state_set, transition_function)
        in :moore
          output_function = { 0 => sul.query_empty }
          Automaton::Moore.new(0, output_function, transition_function)
        in :mealy
          Automaton::Mealy.new(0, transition_function)
        end
      end

      private_class_method :construct_first_hypothesis
    end
  end
end
