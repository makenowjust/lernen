# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # RandomWalkOracle provides an implementation of equivalence query
    # that finds a counterexample by using random walk.
    #
    # This takes two important parameters:
    #
    # - `max_steps` (default: `1500`): It is a limit of steps of a random walk.
    #     If a random walk is tried up to this value and no counterexample is found,
    #     it returns `nil` finally.
    # - `reset_prob` (default: `0.09`): It is a probability to reset a random walk.
    #     On resetting a random walk, it resets a word, but it does not reset
    #     a step counter.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class RandomWalkOracle < Oracle #[In, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @max_steps: Integer
      # @rbs @reset_prob: Float
      # @rbs @random: Random

      #: (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    ?max_steps: Integer,
      #    ?reset_prob: Float,
      #    ?random: Random
      #  ) -> void
      def initialize(alphabet, sul, max_steps: 3000, reset_prob: 0.09, random: Random)
        super(sul)

        @alphabet = alphabet
        @max_steps = max_steps
        @reset_prob = reset_prob
        @random = random
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        reset_internal(hypothesis)
        word = []

        @max_steps.times do
          if @random.rand < @reset_prob
            reset_internal(hypothesis)
            word = []
          end

          word << @alphabet.sample(random: @random)

          hypothesis_output, sul_output = step_internal(hypothesis, word.last)

          if hypothesis_output != sul_output # steep:ignore
            @sul.shutdown
            return word
          end
        end

        nil
      end
    end
  end
end
