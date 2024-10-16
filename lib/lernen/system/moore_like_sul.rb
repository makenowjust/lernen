# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module System
    # MooreLikeSUL is a system under learning (SUL) for a system much like Moore machine.
    #
    # By contrast to `SUL`, this accepts a query with the empty string additionally.
    #
    # Note that this class is *abstract*. You should implement the following method:
    #
    # - `#step(input)`
    # - `#query_empty`
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class MooreLikeSUL < SUL #[In, Out]
      #: (?cache: bool) -> void
      def initialize(cache: true)
        super
      end

      # @rbs override
      def query_last(word)
        if word.empty?
          cached = (cache = @cache) && cache[word]
          unless cached.nil? # steep:ignore
            @num_cached_queries += 1
            return cached
          end

          output = query_empty
          cache[word.dup] = output if cache
          @num_queries += 1

          output
        end

        super
      end

      # Runs a membership query with the empty input.
      #
      # This is an abstract method.
      #
      #: () -> Out
      def query_empty
        raise TypeError, "abstract method: `query_empty`"
      end
    end
  end
end
