# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # DiscriminationTreeVPA is a extended version of discrimination tree for VPA.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Call - Type for call alphabet
    # @rbs generic Return - Type for return alphabet
    class DiscriminationTreeVPA
      # @rbs skip
      Node = Data.define(:access, :suffix, :branch)
      # @rbs skip
      Leaf = Data.define(:prefix)

      # @rbs!
      #   type tree[In, Call, Return] = Node[In, Call, Return]
      #                               | Leaf[In, Call, Return]
      #
      #   class Node[In, Call, Return] < Data
      #     attr_reader access: Array[In | Call | Return]
      #     attr_reader suffix: Array[In | Call | Return]
      #     attr_reader branch: Hash[bool, tree[In, Call, Return]]
      #     def self.[]: [In, Call, Return] (
      #       Array[In | Call | Return] access,
      #       Array[In | Call | Return] suffix,
      #       Hash[bool, tree[In, Call, Return]] branch
      #     ) -> Node[In, Call, Return]
      #   end
      #
      #   class Leaf[In, Call, Return] < Data
      #     attr_reader prefix: Array[In | Call | Return]
      #     def self.[]: [In, Call, Return] (
      #       Array[In | Call | Return] prefix
      #     ) -> Leaf[In, Call, Return]
      #   end

      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet: Array[Call]
      # @rbs @return_alphabet: Array[Return]
      # @rbs @sul: System::MooreLikeSUL[In | Call | Return, bool]
      # @rbs @cex_processing: cex_processing_method
      # @rbs @path_hash: Hash[Array[In | Call | Return], Array[bool]]
      # @rbs @root: Node[In, Call, Return]

      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Array[Return] return_alphabet,
      #    System::MooreLikeSUL[In, bool] sul,
      #    cex: Array[In],
      #    cex_processing: cex_processing_method
      #  ) -> void
      def initialize(alphabet, call_alphabet, return_alphabet, sul, cex:, cex_processing:)
        @alphabet = alphabet
        @call_alphabet = call_alphabet
        @return_alphabet = return_alphabet
        @sul = sul
        @cex_processing = cex_processing

        @path_hash = {}

        @root = Node[[], [], {}]

        empty_out = sul.query_empty
        @root.branch[empty_out] = Leaf[[]]
        @path_hash[[]] = [empty_out]

        cex_out = sul.query_last(cex)
        @root.branch[cex_out] = Leaf[cex] # steep:ignore
        @path_hash[cex] = [cex_out] # steep:ignore
      end

      # Returns a prefix discriminated by `word`.
      #
      #: (Array[In | Call | Return] word) -> Array[In | Call | Return]
      def sift(word)
        node = @root
        path = []

        until node.is_a?(Leaf)
          full_word = node.access + word + node.suffix

          out = @sul.query_last(full_word)
          path << out

          unless node.branch.include?(out) # steep:ignore
            node.branch[out] = Leaf[word] # steep:ignore
            @path_hash[word] = path
          end

          node = node.branch[out] # steep:ignore
        end

        node.prefix # steep:ignore
      end

      # Constructs a hypothesis automaton from this discrimination tree.
      #
      #: () -> [Automaton::VPA[In, Call, Return], Hash[Integer, Array[In | Call | Return]]]
      def build_hypothesis
        transition_function = {}
        return_transition_function = {}

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
            transition_function[[state, input]] = next_state

            found_states = prefix_to_state.values

            return_transition_function.each do |(return_state, return_input), return_transition_guard|
              return_prefix = state_to_prefix[return_state]
              @call_alphabet.each do |call_input|
                word = prefix + [call_input] + return_prefix + [return_input]
                next_prefix = sift(word)

                unless prefix_to_state.include?(next_prefix)
                  queue << next_prefix
                  prefix_to_state[next_prefix] = prefix_to_state.size
                  state_to_prefix[state_to_prefix.size] = next_prefix
                end

                next_state = prefix_to_state[next_prefix]
                return_transition_guard[[state, call_input]] = next_state
              end
            end

            @return_alphabet.each do |return_input|
              return_transition_guard = return_transition_function[[state, return_input]] = {}
              found_states.each do |call_state|
                call_prefix = state_to_prefix[call_state]
                @call_alphabet.each do |call_input|
                  word = call_prefix + [call_input] + prefix + [return_input]
                  next_prefix = sift(word)

                  unless prefix_to_state.include?(next_prefix)
                    queue << next_prefix
                    prefix_to_state[next_prefix] = prefix_to_state.size
                    state_to_prefix[state_to_prefix.size] = next_prefix
                  end

                  next_state = prefix_to_state[next_prefix]
                  return_transition_guard[[call_state, call_input]] = next_state
                end
              end
            end
          end
        end

        accept_state_set =
          state_to_prefix.to_a.filter { |(_, prefix)| @path_hash[prefix][0] }.to_set { |(state, _)| state }
        automaton = Automaton::VPA.new(0, accept_state_set, transition_function, return_transition_function)

        [automaton, state_to_prefix]
      end

      # Update this classification tree by the given `cex`.
      #
      #: (
      #    Automaton::VPA[In, Call, Return] hypothesis,
      #    Array[In | Call | Return] cex,
      #    Hash[Integer, Array[In | Call | Return]] state_to_prefix
      #  ) -> void
      def process_cex(hypothesis, cex, state_to_prefix)
        conf_to_prefix = ->(conf) do
          prefix = []

          conf.stack.each do |state, call_input|
            prefix.concat(state_to_prefix[state])
            prefix << call_input
          end
          prefix.concat(state_to_prefix[conf.state])

          prefix
        end

        acex = PrefixTransformerAcex.new(cex, @sul, hypothesis, conf_to_prefix)
        n = CexProcessor.process(acex, cex_processing: @cex_processing)
        old_prefix = cex[0...n]
        new_input = cex[n]
        new_suffix = cex[n + 1...]

        _, old_conf = hypothesis.run(old_prefix) # steep:ignore
        _, replace_conf = hypothesis.step(old_conf, new_input)

        new_access_conf = Automaton::VPA::Conf[hypothesis.initial_state, replace_conf.stack] # steep:ignore
        new_access = conf_to_prefix.call(new_access_conf)

        old_state_prefix = state_to_prefix[old_conf.state] # steep:ignore
        if @alphabet.include?(new_input) # steep:ignore
          new_prefix = old_state_prefix + [new_input]
        else
          call_state, call_input = old_conf.stack.last # steep:ignore
          call_prefix = state_to_prefix[call_state]
          new_prefix = call_prefix + [call_input] + old_state_prefix + [new_input]
        end
        new_out = @sul.query_last(new_access + new_prefix + new_suffix) # steep:ignore

        replace_prefix = state_to_prefix[replace_conf.state] # steep:ignore
        replace_out = @sul.query_last(new_access + replace_prefix + new_suffix) # steep:ignore

        replace_node_path = @path_hash[replace_prefix]
        replace_node_parent = @root
        replace_node = @root.branch[replace_node_path.first] # steep:ignore
        replace_node_path[1..].each do |out| # steep:ignore
          replace_node_parent = replace_node
          replace_node = replace_node.branch[out] # steep:ignore
        end

        new_node = Node[new_access, new_suffix, {}] # steep:ignore
        replace_node_parent.branch[replace_node_path.last] = new_node # steep:ignore

        new_node.branch[new_out] = Leaf[new_prefix] # steep:ignore
        @path_hash[new_prefix] = replace_node_path + [new_out]

        new_node.branch[replace_out] = Leaf[replace_prefix] # steep:ignore
        @path_hash[replace_prefix] = replace_node_path + [replace_out]
      end
    end
  end
end
