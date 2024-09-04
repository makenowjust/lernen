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
