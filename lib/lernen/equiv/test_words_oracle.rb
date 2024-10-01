# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # TestWordsOracle provides an implementation of equivalence query
    # that find a counterexample from the given words.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class TestWordsOracle < Oracle #[In, Out]
      # @rbs @words: Array[Array[In]]

      #: (Array[Array[In]] words, System::SUL[In, Out] sul) -> void
      def initialize(words, sul)
        super(sul)

        @words = words
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        @words.each do |word|
          reset_internal(hypothesis)

          word.each_with_index do |input, index|
            hypothesis_output, sul_output = step_internal(hypothesis, input)

            if hypothesis_output != sul_output # steep:ignore
              @sul.shutdown
              return word[0..index]
            end
          end
        end

        nil
      end
    end
  end
end
