# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # ObservationTree is an implementation of observation tree data structure.
    #
    # This data structure is used for L# algorithm.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class ObservationTree
      # Node is a node of an observation tree.
      #
      # `output` can take `nil` for the root node on learning Mealy machine.
      #
      # @rbs skip
      Node = Data.define(:output, :branch)

      # @rbs!
      #   class Node[In, Out] < Data
      #     attr_reader output: Out | nil
      #     attr_reader branch: Hash[In, Node[In, Out]]
      #     def self.[]: [In, Out] (
      #       Out output,
      #       Hash[In, Node[In, Out]] branch
      #     ) -> Node[In, Out]
      #   end

      # @rbs @sul: System::SUL[In, Out]
      # @rbs @automaton_type: :dfa | :mealy | :moore
      # @rbs @root: Node[In, Out]

      #: (
      #    System::SUL[In, Out] sul,
      #    automaton_type: :dfa | :mealy | :moore
      #  ) -> void
      def initialize(sul, automaton_type:)
        @sul = sul
        @automaton_type = automaton_type

        case automaton_type
        in :dfa | :moore
          raise "MooreLikeSUL is required to learn DFA or Moore" unless sul.is_a?(System::MooreLikeSUL)
          @root = Node[sul.query_empty, {}]
        in :mealy
          @root = Node[nil, {}]
        end
      end

      attr_reader :root #: Node[In, Out]

      # Returns a node for the given word.
      # When the word (or its subword) is not observed, it returns `nil` instead.
      #
      #: (Array[In] word) -> (Node[In, Out] | nil)
      def [](word)
        node = @root
        word.each do |input|
          return nil unless node.branch[input]
          node = node.branch[input]
        end
        node
      end

      # Returns an output sequence for the given word if it is observed.
      # If it is not, it returns `nil` instead.
      #
      #: (Array[In] word) -> (Array[Out] | nil)
      def observed_query(word)
        return [@root.output] if word.empty? # steep:ignore

        node = @root
        outputs = []
        word.each do |input|
          node = node.branch[input]
          return nil unless node

          outputs << node.output
        end

        outputs
      end

      # Returns an output sequence for the given word.
      # When the word is observed, it runs actual query over `sul`.
      #
      #: (Array[In] word) -> Array[Out]
      def query(word)
        outputs = observed_query(word)
        return outputs if outputs

        node = @root
        inprogress_word = []
        outputs = []
        word.each do |input|
          inprogress_word << input
          output = @sul.query_last(inprogress_word)
          outputs << output
          node.branch[input] ||= Node[output, {}] # steep:ignore
          node = node.branch[input]
        end

        outputs
      end
    end
  end
end
