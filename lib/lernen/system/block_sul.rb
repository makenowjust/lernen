# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module System
    # BlockSUL is a system under learning (SUL) constructed from a block.
    #
    # A block is expected to behave like a membership query.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class BlockSUL < MooreLikeSUL #[In, Out]
      # @rbs @block: ^(Array[In]) -> Out
      # @rbs @word: Array[In]

      #: (?cache: bool) { (Array[In]) -> Out } -> void
      def initialize(cache: true, &block)
        super(cache:)

        @block = block
        @word = []
      end

      # @rbs override
      def setup
        @word = []
      end

      # @rbs override
      def step(input)
        @word << input
        @block.call(@word)
      end

      # @rbs override
      def query_empty
        @block.call([])
      end
    end
  end
end
