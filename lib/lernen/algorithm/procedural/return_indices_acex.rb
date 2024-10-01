# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module Procedural
      # ReturnIndicesAcex is an acex implementation for finding the return index in procedural learning.
      #
      # @rbs generic In     -- Type for input alphabet
      # @rbs generic Call   -- Type for call alphabet
      # @rbs generic Return -- Type for return alphabet
      class ReturnIndicesAcex < CexProcessor::Acex
        # @rbs @cex: Array[In | Call | Return]
        # @rbs @return_indices: Array[Integer]
        # @rbs @query: ^(Array[In | Call | Return]) -> bool
        # @rbs @manager: ATRManager[In, Call, Return]

        #: (
        #    Array[In | Call | Return] cex,
        #    Array[Integer] return_indices,
        #    ^(Array[In | Call | Return]) -> bool query,
        #    ATRManager[In, Call, Return] manager
        #  ) -> void
        def initialize(cex, return_indices, query, manager)
          super(return_indices.size + 1)

          @cex = cex
          @return_indices = return_indices
          @query = query
          @manager = manager

          @cache[0] = false
          @cache[return_indices.size] = true
        end

        # @rbs override
        def compute_effect(idx)
          word_stack = []
          index = @return_indices[idx]

          while index > 0
            call_index = @manager.find_call_index(@cex, index)
            proc = @cex[call_index]
            normalized_word = @manager.expand(@manager.project(@cex[call_index + 1...index])) # steep:ignore
            word_stack << [proc, *normalized_word]
            index = call_index
          end

          word = []
          word_stack.reverse_each { word.concat(_1) }
          word.concat(@cex[@return_indices[idx]...]) # steep:ignore

          @query.call(word)
        end
      end
    end
  end
end
