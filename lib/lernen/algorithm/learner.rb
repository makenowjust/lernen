# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # Learner is an abstraction of implementations of learning algorithms.
    #
    # Note that this class is *abstract*. We should implement the following method:
    #
    # - `#oracle`
    # - `#refine(cex, hypothesis, state_to_prefix)`
    # - `#build_hypothesis`
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class Learner
      # Runs the learning algorithm and returns an inferred automaton.
      #
      # `max_learning_rounds` is a parameter for specifying the maximum number of iterations for learning.
      # When `max_learning_rounds: nil` is specified, it means the algorithm only stops if the equivalent
      # hypothesis is found.
      #
      #: (?max_learning_rounds: Integer | nil) -> Automaton::TransitionSystem[untyped, In, Out]
      def learn(max_learning_rounds: nil)
        hypothesis, state_to_prefix = build_hypothesis
        cex = oracle.find_cex(hypothesis)
        return hypothesis if cex.nil?

        learning_rounds = 0
        loop do
          break if max_learning_rounds && learning_rounds == max_learning_rounds
          learning_rounds += 1

          refine_hypothesis(cex, hypothesis, state_to_prefix)

          hypothesis, state_to_prefix = build_hypothesis
          cex = oracle.find_cex(hypothesis)
          break if cex.nil?
        end

        hypothesis
      end

      # rubocop:disable Lint/UnusedMethodArgument

      # Adds the given `input` to the alphabet.
      #
      # In the default, this method raises `TypeError` as the learner does not support
      # adding an input character to the alphabet.
      #
      #: (In input) -> void
      def add_alphabet(input)
        raise TypeError, "This learner does not support adding an input character to the alphabet"
      end

      private

      # Returns the equivlence oracle for the SUL.
      #
      # This is an abstract method.
      #
      #: () -> Equiv::Oracle[In, Out]
      def oracle
        raise TypeError, "abstract method: `oracle`"
      end

      # Refine the learning hypothesis by the given counterexample.
      #
      # This is an abstract method.
      #
      #: (
      #    Array[In] cex,
      #    Automaton::TransitionSystem[untyped, In, Out] hypothesis,
      #    Hash[Integer, Array[In]] state_to_prefix
      #  ) -> void
      def refine_hypothesis(cex, hypothesis, state_to_prefix)
        raise TypeError, "abstract method: `refine_hypothesis`"
      end

      # This is an abstract method.
      #r
      #: () -> [Automaton::TransitionSystem[untyped, In, Out], Hash[Integer, Array[In]]]
      def build_hypothesis
        raise TypeError, "abstract method: `build_hypothesis`"
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
