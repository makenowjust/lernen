# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # KearnzVaziraniVPA is an implementation of Kearnz-Vazirani algorithm for VPA.
    #
    # The idea behind this implementation is described by [Isberner (2015) "Foundations
    # of Active Automata Learning: An Algorithmic Overview"](https://eldorado.tu-dortmund.de/handle/2003/34282).
    module KearnsVaziraniVPA
      # Runs Kearns-Vazirani algoritghm for VPA and returns an inferred VPA.
      #
      # `max_learning_rounds` is a parameter for specifying the maximum number of iterations for learning.
      # When `max_learning_rounds: nil` is specified, it means the algorithm only stops if the equivalent
      # hypothesis is found.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
      #    System::MooreLikeSUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    ?cex_processing: cex_processing_method, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::VPA[In, Call, Return]
      def self.learn(
        alphabet,
        call_alphabet,
        return_alphabet,
        sul,
        oracle,
        cex_processing: :binary,
        max_learning_rounds: nil
      )
        hypothesis = construct_first_hypothesis(alphabet, call_alphabet, return_alphabet, sul)
        cex = oracle.find_cex(hypothesis) # steep:ignore
        return hypothesis if cex.nil? # steep:ignore

        tree = DiscriminationTreeVPA.new(alphabet, call_alphabet, return_alphabet, sul, cex:, cex_processing:)
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

      # Constructs the first hypothesis VPA.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
      #    System::MooreLikeSUL[In, bool] sul,
      #  ) -> Automaton::VPA[In, Call, Return]
      def self.construct_first_hypothesis(alphabet, call_alphabet, return_alphabet, sul)
        transition_function = {}
        alphabet.each { |input| transition_function[[0, input]] = 0 }

        return_transition_function = {}
        return_alphabet.each do |return_input|
          return_transition_guard = return_transition_function[[0, return_input]] = {}
          call_alphabet.each { |call_input| return_transition_guard[[0, call_input]] = 0 }
        end

        accept_state_set = sul.query_empty ? Set[0] : Set.new
        Automaton::VPA.new(0, accept_state_set, transition_function, return_transition_function)
      end

      private_class_method :construct_first_hypothesis
    end
  end
end
