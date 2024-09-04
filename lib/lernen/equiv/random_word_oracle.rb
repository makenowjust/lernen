# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # RandomWordOracle provides an implementation of equivalence query
    # that finds a counterexample by using random word generation.
    #
    # This takes three important parameters:
    #
    # - `max_words` (default: `100`): It is a limit of number of random words.
    #     If random words is generated and tried up to this value and no counterexample
    #     is found, it returns `nil` finally.
    # - `min_word_size` (default: `1`): It is the minimal size of randomly generated word.
    #     It should be greater than `0`.
    # - `max_word_size` (default: `30`): It is the maximal size of randomly generated word.
    #     It should be greater than or equal to `min_word_size`.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class RandomWordOracle < Oracle #[In, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @max_word: Integer
      # @rbs @min_word_size: Integer
      # @rbs @max_word_size: Integer
      # @rbs @random: Random

      #: (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    ?max_words: Integer,
      #    ?min_word_size: Integer,
      #    ?max_word_size: Integer,
      #    ?random: Random,
      #  ) -> void
      def initialize(alphabet, sul, max_words: 100, min_word_size: 1, max_word_size: 30, random: Random)
        super(sul)

        @alphabet = alphabet
        @max_words = max_words
        @min_word_size = min_word_size
        @max_word_size = max_word_size
        @random = random
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        @max_words.times do
          reset_internal(hypothesis)
          word = []

          word_size = @random.rand(@min_word_size..@max_word_size)
          word_size.times do
            word << @alphabet.sample(random: @random)

            hypothesis_output, sul_output = step_internal(hypothesis, word.last)

            if hypothesis_output != sul_output # steep:ignore
              @sul.shutdown
              return word
            end
          end
        end

        nil
      end
    end
  end
end
