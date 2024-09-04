# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # ExhaustiveSearchOracle provides an implementation of equivalence query
    # that finds a counterexample by using exhaustive search to `depth` products
    # of input alphabet characters.
    #
    # For example, with `alphabet = %w[0 1]` and `depth = 3`, this oracle queries
    # the following 14 words for finding a counterexample.
    #
    # ```ruby
    # 0, 1,
    # 00, 01, 10, 11,
    # 000, 001, 010, 011, 100, 101, 110, 111
    # ```
    #
    # As the strategy, this oracle is extremingly slow and we do not recommend to use
    # this oracle for non-testing purposes.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class ExhaustiveSearchOracle < Oracle #[In, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @depth: Integer

      # @rbs alphabet: Array[In]
      # @rbs sul: System::SUL[In, Out]
      # @rbs depth: Integer
      # @rbs return: void
      def initialize(alphabet, sul, depth: 5)
        super(sul)

        @alphabet = alphabet
        @depth = depth
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        @alphabet.product(*[@alphabet] * (@depth - 1)) do |word| # steep:ignore
          reset_internal(hypothesis)

          word.each_with_index do |input, n|
            hypothesis_output, sul_output = step_internal(hypothesis, input)

            if hypothesis_output != sul_output # steep:ignore
              @sul.shutdown
              return word[0..n]
            end
          end
        end

        nil
      end
    end
  end
end
