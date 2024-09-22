# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # DiscriminationTree is an implementation of discrimination tree data structure.
    #
    # This data structure is used for Kearns-Vazirani algorithm.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class DiscriminationTree
      # @rbs skip
      Node = Data.define(:suffix, :branch)
      # @rbs skip
      Leaf = Data.define(:prefix)

      # @rbs!
      #   type tree[In, Out] = Node[In, Out] | Leaf[In]
      #
      #   class Node[In, Out] < Data
      #     attr_reader suffix: Array[In]
      #     attr_reader branch: Hash[Out, tree[In, Out]]
      #     def self.[]: [In, Out] (
      #       Array[In] suffix,
      #       Hash[Out, tree[In, Out]] branch
      #     ) -> Node[In, Out]
      #   end
      #
      #   class Leaf[In] < Data
      #     attr_reader prefix: Array[In]
      #     def self.[]: [In] (Array[In] prefix) -> Leaf[In]
      #   end

      # @rbs @alphabet: Array[In]
      # @rbs @sul: System::SUL[In, Out]
      # @rbs @automaton_type: :dfa | :mealy | :moore
      # @rbs @cex_processing: cex_processing_method
      # @rbs @path_hash: Hash[Array[In], Array[Out]]
      # @rbs @root: Node[In, Out]

      #: (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    cex: Array[In],
      #    automaton_type: :dfa | :mealy | :moore,
      #    cex_processing: cex_processing_method
      #  ) -> void
      def initialize(alphabet, sul, cex:, automaton_type:, cex_processing:)
        @alphabet = alphabet
        @sul = sul
        @automaton_type = automaton_type
        @cex_processing = cex_processing

        @path_hash = {}

        case @automaton_type
        in :dfa | :moore
          @root = Node[[], {}]

          empty_out = sul.query_empty
          @root.branch[empty_out] = Leaf[[]]
          @path_hash[[]] = [empty_out]

          cex_out = sul.query_last(cex)
          @root.branch[cex_out] = Leaf[cex]
          @path_hash[cex] = [cex_out]
        in :mealy
          prefix = cex[0...-1]
          suffix = [cex.last]
          @root = Node[suffix, {}]

          suffix_out = sul.query_last(suffix)
          @root.branch[suffix_out] = Leaf[[]]
          @path_hash[[]] = [suffix_out]

          cex_out = sul.query_last(cex)
          @root.branch[cex_out] = Leaf[prefix]
          @path_hash[prefix] = [cex_out]
        end
      end

      # Returns a prefix discriminated by `word`.
      #
      #: (Array[In] word) -> Array[In]
      def sift(word)
        node = @root
        path = []

        until node.is_a?(Leaf)
          full_word = word + node.suffix

          out = @sul.query_last(full_word)
          path << out

          unless node.branch.include?(out)
            node.branch[out] = Leaf[word]
            @path_hash[word] = path
          end

          node = node.branch[out] # steep:ignore
        end

        node.prefix # steep:ignore
      end

      # Constructs a hypothesis automaton from this discrimination tree.
      #
      #: () -> [Automaton::TransitionSystem[Integer, In, Out], Hash[Integer, Array[In]]]
      def build_hypothesis
        transition_function = {}

        queue = []
        prefix_to_state = {}
        state_to_prefix = {}

        queue << []
        prefix_to_state[[]] = prefix_to_state.size
        state_to_prefix[state_to_prefix.size] = []

        until queue.empty?
          prefix = queue.shift
          state = prefix_to_state[prefix]
          @alphabet.each do |input|
            word = prefix + [input]
            next_prefix = sift(word)

            unless prefix_to_state.include?(next_prefix)
              queue << next_prefix
              prefix_to_state[next_prefix] = prefix_to_state.size
              state_to_prefix[state_to_prefix.size] = next_prefix
            end

            next_state = prefix_to_state[next_prefix]
            case @automaton_type
            in :dfa | :moore
              transition_function[[state, input]] = next_state
            in :mealy
              output = @sul.query_last(word)
              transition_function[[state, input]] = [output, next_state]
            end
          end
        end

        automaton =
          case @automaton_type
          in :dfa
            accept_states =
              state_to_prefix.to_a.filter { |(_, prefix)| @path_hash[prefix][0] }.to_set { |(state, _)| state }
            Automaton::DFA.new(0, accept_states, transition_function)
          in :moore
            outputs = state_to_prefix.transform_values { |prefix| @path_hash[prefix][0] }
            Automaton::Moore.new(0, outputs, transition_function)
          in :mealy
            Automaton::Mealy.new(0, transition_function)
          end

        [automaton, state_to_prefix]
      end

      # Update this classification tree by the given `cex`.
      #
      #: (
      #    Automaton::TransitionSystem[Integer, In, Out] hypothesis,
      #    Array[In] cex,
      #    Hash[Integer, Array[In]] state_to_prefix
      #  ) -> void
      def process_cex(hypothesis, cex, state_to_prefix)
        state_to_prefix_lambda = ->(state) { state_to_prefix[state] }
        acex = PrefixTransformerAcex.new(cex, @sul, hypothesis, state_to_prefix_lambda)

        n = CexProcessor.process(acex, cex_processing: @cex_processing)
        old_prefix = cex[0...n]
        new_input = cex[n]
        new_suffix = cex[n + 1...]

        _, old_state = hypothesis.run(old_prefix) # steep:ignore
        _, replace_state = hypothesis.step(old_state, new_input)

        new_prefix = state_to_prefix[old_state] + [new_input]
        new_out = @sul.query_last(new_prefix + new_suffix) # steep:ignore

        replace_prefix = state_to_prefix[replace_state]
        replace_out = @sul.query_last(replace_prefix + new_suffix) # steep:ignore

        replace_node_path = @path_hash[replace_prefix]
        replace_node_parent = @root
        replace_node = @root.branch[replace_node_path.first] # steep:ignore
        replace_node_path[1..].each do |out| # steep:ignore
          replace_node_parent = replace_node
          replace_node = replace_node.branch[out] # steep:ignore
        end

        new_node = Node[new_suffix, {}] # steep:ignore
        replace_node_parent.branch[replace_node_path.last] = new_node # steep:ignore

        new_node.branch[new_out] = Leaf[new_prefix]
        @path_hash[new_prefix] = replace_node_path + [new_out] # steep:ignore

        new_node.branch[replace_out] = Leaf[replace_prefix]
        @path_hash[replace_prefix] = replace_node_path + [replace_out] # steep:ignore
      end
    end
  end
end
