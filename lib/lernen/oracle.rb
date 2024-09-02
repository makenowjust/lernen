# frozen_string_literal: true

module Lernen
  # Oracle is an equivalence oracle.
  #
  # Note that this class is *abstract*. You should implement the following method:
  #
  # - `#find_cex(hypothesis)`
  class Oracle
    def initialize(alphabet, sul)
      @alphabet = alphabet
      @sul = sul

      @num_calls = 0
      @num_queries = 0
      @num_steps = 0
      @current_state = nil
    end

    # Returns statistics information as a `Hash` object.
    def stats
      { num_calls: @num_calls, num_queries: @num_queries, num_steps: @num_steps }
    end

    # Finds a conterexample against the given `hypothesis` automaton.
    # If it is found, it returns the counterexample inputs, or it returns `nil` otherwise.
    #
    # This is *abstract*.
    def find_cex(_hypothesis)
      raise TypeError, "abstract method: `step`"
    end

    # Resets the internal states of this oracle.
    def reset_internal(hypothesis)
      @current_state = hypothesis.initial

      @sul.shutdown
      @sul.setup

      @num_queries += 1
    end
  end

  # This equivalence oracles uses bradth-first exploration of all possible input
  # combinations up to a specified depth for equivalence checking.
  class BreadthFirstExplorationOracle < Oracle
    def initialize(alphabet, sul, depth: 5)
      super(alphabet, sul)

      @depth = depth
    end

    # Finds a conterexample against the given `hypothesis` automaton.
    def find_cex(hypothesis)
      @num_calls += 1

      @alphabet.product(*[@alphabet] * (@depth - 1)) do |inputs|
        reset_internal(hypothesis)

        inputs.each_with_index do |input, i|
          @num_steps += 1
          h_out, @current_state = hypothesis.step(@current_state, input)
          s_out = @sul.step(input)

          if h_out != s_out
            @sul.shutdown
            return inputs[0..i]
          end
        end
      end

      @sul.shutdown
      nil
    end
  end

  # This equivalence oracles uses random-walk exploration for equivalence checking.
  class RandomWalkOracle < Oracle
    def initialize(alphabet, sul, step_limit: 3000, reset_prob: 0.09, random: Random)
      super(alphabet, sul)

      @step_limit = step_limit
      @reset_prob = reset_prob
      @random = random
    end

    # Finds a conterexample against the given `hypothesis` automaton.
    def find_cex(hypothesis)
      @num_calls += 1

      random_steps_done = 0
      inputs = []
      reset_internal(hypothesis)

      while random_steps_done < @step_limit
        random_steps_done += 1

        if @random.rand < @reset_prob
          inputs = []
          reset_internal(hypothesis)
        end

        inputs << @alphabet.sample(random: @random)

        @num_steps += 1
        h_out, @current_state = hypothesis.step(@current_state, inputs.last)
        s_out = @sul.step(inputs.last)

        if h_out != s_out
          @sul.shutdown
          return inputs
        end
      end

      @sul.shutdown
      nil
    end
  end

  # This equivalence oracles uses randomly generated words for equivalence checking.
  class RandomWordOracle < Oracle
    def initialize(alphabet, sul, num_words: 100, min_word_size: 10, max_word_size: 30, random: Random)
      super(alphabet, sul)

      @num_words = num_words
      @min_word_size = min_word_size
      @max_word_size = max_word_size
      @random = random
    end

    # Finds a conterexample against the given `hypothesis` automaton.
    def find_cex(hypothesis)
      @num_calls += 1

      num_done_words = 0
      while num_done_words < @num_words
        num_done_words += 1
        reset_internal(hypothesis)

        inputs = []
        word_size = @random.rand(@min_word_size..@max_word_size)
        word_size.times do
          inputs << @alphabet.sample(random: @random)

          @num_steps += 1
          h_out, @current_state = hypothesis.step(@current_state, inputs.last)
          s_out = @sul.step(inputs.last)

          if h_out != s_out
            @sul.shutdown
            return inputs
          end
        end
      end

      @sul.shutdown
      nil
    end
  end
end
