# frozen_string_literal: true

module Lernen
  # CexProcessor is a collection of implementations of couterexample processing procesudres.
  module CexProcessor
    # Processes a given `cex`. It returns a new prefix and suffix to advance a learning.
    def self.process(sul, hypothesis, cex, state_to_prefix, cex_processing: :binary)
      case cex_processing
      in :linear
        process_linear(sul, hypothesis, cex, state_to_prefix)
      in :binary
        process_binary(sul, hypothesis, cex, state_to_prefix)
      in :exponential
        process_exponential(sul, hypothesis, cex, state_to_prefix)
      end
    end

    # Processes a given `cex` by linear search.
    def self.process_linear(sul, hypothesis, cex, state_to_prefix)
      expected_output = sul.query(cex).last

      current_state = hypothesis.initial_state
      cex.each_with_index do |a, i|
        _, next_state = hypothesis.step(current_state, a)

        prefix = state_to_prefix[next_state]
        suffix = cex[i + 1...]
        return state_to_prefix[current_state], a, suffix if expected_output != sul.query(prefix + suffix).last

        current_state = next_state
      end
    end

    # Processes a given `cex` by binary search.
    #
    # It is known as the Rivest-Schapire (RS) technique.
    def self.process_binary(sul, hypothesis, cex, state_to_prefix, low: 0)
      expected_output = sul.query(cex).last

      high = cex.size - 1

      while high - low > 1
        mid = (low + high) / 2
        prefix = cex[0...mid]
        suffix = cex[mid...]

        _, prefix_state = hypothesis.run(prefix)
        if expected_output == sul.query(state_to_prefix[prefix_state] + suffix).last
          low = mid
        else
          high = mid
        end
      end

      prefix = cex[0...low]
      suffix = cex[high...]

      _, prefix_state = hypothesis.run(prefix)
      [state_to_prefix[prefix_state], cex[low], suffix]
    end

    # Processes a given `cex` by exponential seatch.
    #
    # This idea is described in this paper.
    #
    # Isberner, Malte, and Bernhard Steffen. "An abstract framework for counterexample
    # analysis in active automata learning." International Conference on Grammatical
    # Inference. PMLR, 2014.
    def self.process_exponential(sul, hypothesis, cex, state_to_prefix)
      expected_output = sul.query(cex).last

      prev_bp = 0
      bp = 1

      loop do
        if bp >= cex.size
          bp = cex.size
          break
        end

        prefix = cex[0...bp]
        suffix = cex[bp...]

        _, prefix_state = hypothesis.run(prefix)
        break if expected_output != sul.query(state_to_prefix[prefix_state] + suffix).last

        prev_bp = bp
        bp *= 2
      end

      process_binary(sul, hypothesis, cex, state_to_prefix, low: prev_bp)
    end
  end
end
