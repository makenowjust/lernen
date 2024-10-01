# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # RandomWellMatchedWordOracle provides an implementation of equivalence query
    # that finds a counterexample by using random well-matched word generation.
    #
    # This takes three important parameters:
    #
    # - `max_words` (default: `100`): It is a limit of number of random words.
    #     If random words is generated and tried up to this value and no counterexample
    #     is found, it returns `nil` finally.
    # - `min_word_size` (default: `2`): It is the minimal size of randomly generated word.
    #     It should be greater than `0`.
    # - `max_word_size` (default: `30`): It is the maximal size of randomly generated word.
    #     It should be greater than or equal to `min_word_size`.
    # - `call_prob` (default: `0.1`): It is a probability to generate call and return subwords.
    # - `initial_proc` (default `nil`): It is the initial proc character.
    #     If it is specified, the generated words must be started with it.
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    # @rbs generic Out    -- Type for output values
    class RandomWellMatchedWordOracle < Oracle #[In | Call | Return, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet: Array[Call]
      # @rbs @return_alphabet: Array[Return]
      # @rbs @max_words: Integer
      # @rbs @min_word_size: Integer
      # @rbs @max_word_size: Integer
      # @rbs @call_prob: Float
      # @rbs @initial_proc: Call | nil
      # @rbs @random: Random

      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Array[Return] return_alphabet,
      #    System::SUL[In | Call | Return, Out] sul,
      #    ?max_words: Integer,
      #    ?min_word_size: Integer,
      #    ?max_word_size: Integer,
      #    ?call_prob: Float,
      #    ?initial_proc: Call | nil,
      #    ?random: Random
      #  ) -> void
      def initialize(
        alphabet,
        call_alphabet,
        return_alphabet,
        sul,
        max_words: 100,
        min_word_size: 2,
        max_word_size: 30,
        call_prob: 0.5,
        initial_proc: nil,
        random: Random
      )
        super(sul)

        @alphabet = alphabet
        @call_alphabet = call_alphabet
        @return_alphabet = return_alphabet
        @max_words = max_words
        @min_word_size = min_word_size
        @max_word_size = max_word_size
        @call_prob = call_prob
        @initial_proc = initial_proc
        @random = random
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        @max_words.times do
          reset_internal(hypothesis)

          word = generate_word
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

      private

      #: () -> Array[In | Call | Return]
      def generate_word
        word_size = @random.rand(@min_word_size..@max_word_size)

        word = []
        initial_proc = @initial_proc
        if initial_proc
          word << initial_proc
          generate_word_internal(word, word_size - 2)
          word << @return_alphabet.sample(random: @random)
          return word
        end

        generate_word_internal(word, word_size)
        word
      end

      #: (Array[In | Call | Return] word, Integer word_size) -> void
      def generate_word_internal(word, word_size)
        return if word_size <= 0

        if word_size == 1
          word << @alphabet.sample(random: @random) # steep:ignore
          return
        end

        if @random.rand < @call_prob
          call_index = @random.rand(0...word_size - 1)
          generate_word_internal(word, call_index)
          word << @call_alphabet.sample(random: @random) # steep:ignore
          return_index = call_index + 1 + @random.rand(0...word_size - call_index - 1)
          generate_word_internal(word, return_index - call_index - 1)
          word << @return_alphabet.sample(random: @random) # steep:ignore
          generate_word_internal(word, word_size - return_index - 1)
        else
          split_size = @random.rand(1...word_size)
          generate_word_internal(word, split_size)
          generate_word_internal(word, word_size - split_size)
        end
      end
    end
  end
end
