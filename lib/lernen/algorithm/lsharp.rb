# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # LSharp is an implementation of L# algorithm.
    #
    # L# is introduced by [Vaandrager et al. (2022) "A New Approach for Active
    # Automata Learning Based on Apartness"](https://link.springer.com/chapter/10.1007/978-3-030-99524-9_12).
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class LSharp
      # Runs the L# algoritghm and returns an inferred automaton.
      #
      # `max_learning_rounds` is a parameter for specifying the maximum number of iterations for learning.
      # When `max_learning_rounds: nil` is specified, it means the algorithm only stops if the equivalent
      # hypothesis is found.
      #
      #: [In] (
      #    Array[In] alphabet,
      #    System::SUL[In, bool] sul,
      #    Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn(alphabet, sul, oracle, automaton_type:, max_learning_rounds: nil) # steep:ignore
        learner = LSharp.new(alphabet, sul, oracle, automaton_type:, max_learning_rounds:)
        learner.learn
      end

      # @rbs @alphabet: Array[In]
      # @rbs @sul: System::SUL[In, Out]
      # @rbs @oracle: Equiv::Oracle[In, Out]
      # @rbs @automaton_type: :dfa | :mealy | :moore
      # @rbs @max_learning_rounds: Integer | nil
      # @rbs @tree: ObservationTree[In, Out]
      # @rbs @witness_cache: Hash[[Array[In], Array[In]], Array[In]]
      # @rbs @basis: Array[Array[In]]
      # @rbs @frontier: Hash[Array[In], Array[Array[In]]]
      # @rbs @incomplete_basis: Array[Array[In]]

      #: (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :dfa | :mealy | :moore,
      #    ?max_learning_rounds: Integer | nil
      #  ) -> void
      def initialize(alphabet, sul, oracle, automaton_type:, max_learning_rounds: nil)
        @alphabet = alphabet
        @sul = sul
        @oracle = oracle
        @automaton_type = automaton_type
        @max_learning_rounds = max_learning_rounds

        @tree = ObservationTree.new(sul, automaton_type:)
        @witness_cache = {}

        @basis = []
        @frontier = {}

        @incomplete_basis = []
      end

      # Runs the L# algoritghm and returns an inferred automaton.
      #
      #: () -> Automaton::TransitionSystem[Integer, In, Out]
      def learn
        add_basis([])
        learning_rounds = 0

        loop do
          next if promotion || completion || identification

          break if @max_learning_rounds && learning_rounds == @max_learning_rounds
          learning_rounds += 1

          hypothesis = check_hypothesis
          break if hypothesis
        end

        hypothesis, = build_hypothesis
        hypothesis
      end

      private

      # Checks apartness on the current observation tree between the given two nodes.
      # It returns the witness suffix if they are apart. If it is not, it returns `nil`.
      #
      #: (
      #    ObservationTree::Node[In, Out] node1,
      #    ObservationTree::Node[In, Out] node2
      #  ) -> (Array[In] | nil)
      def check_apartness(node1, node2)
        case @automaton_type
        in :dfa | :moore
          return [] if node1.output != node2.output
        in :mealy
          # nop
        end

        queue = []
        queue << [[], node1, node2]

        until queue.empty?
          suffix, node1, node2 = queue.shift
          node1.branch.each do |input, next_node1|
            next_node2 = node2.branch[input]
            next unless next_node2
            return suffix + [input] if next_node1.output != next_node2.output # steep:ignore
            queue << [suffix + [input], next_node1, next_node2]
          end
        end

        nil
      end

      # Computes the witness suffix of apartness between the given two basis prefixes.
      #
      #: (
      #    Array[In] prefix1,
      #    Array[In] prefix2
      #  ) -> Array[In]
      def compute_witness(prefix1, prefix2)
        cached = @witness_cache[[prefix1, prefix2]]
        return cached if cached

        node1 = @tree[prefix1]
        node2 = @tree[prefix2]
        raise "BUG: Nodes for the basis prefixes must exist" unless node1 && node2

        witness = check_apartness(node1, node2)
        raise "BUG: A witness prefix for two basis prefixes must exist" unless witness

        @witness_cache[[prefix1, prefix2]] = witness

        witness
      end

      #: (Array[In] prefix) -> void
      def add_basis(prefix)
        @basis << prefix
        @incomplete_basis << prefix
        prefix_node = @tree[prefix]
        raise "BUG: A node for the basis prefix must exist" unless prefix_node

        @frontier.each do |border, eq_prefixes|
          border_node = @tree[border]
          raise "BUG: A node for the frontier prefix must exist" unless border_node

          eq_prefixes << prefix unless check_apartness(prefix_node, border_node)
        end
      end

      #: (Array[In] border) -> void
      def add_frontier(border)
        border_node = @tree[border]
        raise "BUG: A node for the frontier prefix must exist" unless border_node

        @frontier[border] = @basis.filter do |prefix|
          prefix_node = @tree[prefix]
          raise "BUG: A node for the basis prefix must exist" unless prefix_node

          check_apartness(prefix_node, border_node).nil?
        end
      end

      #: () -> void
      def update_frontier
        @frontier.each do |border, eq_prefixes|
          border_node = @tree[border]
          raise "BUG: A node for the frontier prefix must exist" unless border_node

          eq_prefixes.filter! do |prefix|
            prefix_node = @tree[prefix]
            raise "BUG: A node for the basis prefix must exist" unless prefix_node

            check_apartness(prefix_node, border_node).nil?
          end
        end
      end

      #: () -> [Automaton::TransitionSystem[Integer, In, Out], Hash[Integer, Array[In]]]
      def build_hypothesis
        transitions = {}
        prefix_to_state = @basis.each_with_index.to_h

        @basis.each do |prefix|
          state = prefix_to_state[prefix]
          node = @tree[prefix]
          raise "BUG: A node for the basis prefix must exist" unless node

          @alphabet.each do |input|
            next_node = node.branch[input]
            next_prefix = prefix + [input]
            next_state =
              (
                if @frontier.include?(next_prefix)
                  prefix_to_state[@frontier[next_prefix].first]
                else
                  prefix_to_state[next_prefix]
                end
              )

            case @automaton_type
            in :dfa | :moore
              transitions[[state, input]] = next_state
            in :mealy
              transitions[[state, input]] = [next_node.output, next_state]
            end
          end
        end

        state_to_prefix = prefix_to_state.to_h { |q, i| [i, q] }
        automaton =
          case @automaton_type
          in :dfa
            accept_states =
              state_to_prefix
                .to_a
                .filter { |(_, prefix)| @tree.observed_query(prefix).last }
                .to_set { |(state, _)| state }
            Automaton::DFA.new(0, accept_states, transitions)
          in :moore
            outputs = state_to_prefix.transform_values { |state| @tree.observed_query(state).last }
            Automaton::Moore.new(0, outputs, transitions)
          in :mealy
            Automaton::Mealy.new(0, transitions)
          end

        [automaton, state_to_prefix]
      end

      #: (
      #    Automaton::TransitionSystem[Integer, In, Out] hypothesis,
      #    Hash[Integer, Array[In]] state_to_prefix
      #  ) -> (Array[In] | nil)
      def check_consistency(hypothesis, state_to_prefix)
        queue = []
        queue << [[], hypothesis.initial_conf, @tree.root]

        until queue.empty?
          prefix, state, node = queue.shift
          state_prefix = state_to_prefix[state]
          next unless state_prefix

          state_node = @tree[state_prefix]
          raise "BUG: A node for the basis prefix must exist" unless state_node
          return prefix if check_apartness(node, state_node)

          node.branch.each do |input, next_node|
            _, next_state = hypothesis.step(state, input)
            queue << [prefix + [input], next_state, next_node]
          end
        end

        nil
      end

      #: () -> bool
      def promotion
        @frontier.each do |new_prefix, eq_prefixes|
          next unless eq_prefixes.empty?

          @frontier.delete(new_prefix)
          add_basis(new_prefix)

          return true
        end

        false
      end

      #: () -> bool
      def completion
        updated = false

        while (prefix = @incomplete_basis.pop)
          prefix_node = @tree[prefix]
          raise "BUG: A node for the basis prefix must exist" unless prefix_node

          @alphabet.each do |input|
            border = prefix + [input]
            next if prefix_node.branch[input] && (@basis.include?(border) || @frontier.include?(border))

            @tree.query(border)
            add_frontier(border)

            updated = true
          end
        end

        updated
      end

      #: () -> bool
      def identification
        @frontier.each do |border, eq_prefixes|
          next unless eq_prefixes.size >= 2

          prefix1 = eq_prefixes[0]
          prefix2 = eq_prefixes[1]
          witness = compute_witness(prefix1, prefix2)
          @tree.query(border + witness)
          update_frontier

          return true
        end

        false
      end

      #: () -> (Automaton::TransitionSystem[Integer, In, Out] | nil)
      def check_hypothesis
        hypothesis, state_to_prefix = build_hypothesis

        cex = check_consistency(hypothesis, state_to_prefix)
        unless cex
          cex0 = @oracle.find_cex(hypothesis)
          if cex0
            @tree.query(cex0)
            node = @tree.root
            state = hypothesis.initial_conf
            cex0.size.times do |n|
              input = cex0[n]
              node = node.branch[input]

              _, state = hypothesis.step(state, input)
              state_node = @tree[state_to_prefix[state]]
              raise "BUG: A node for the basis prefix must exist" unless state_node

              if check_apartness(state_node, node)
                cex = cex0[0..n]
                break
              end
            end
          end
        end

        return hypothesis if cex.nil?

        process_cex(hypothesis, state_to_prefix, cex)
        update_frontier

        nil
      end

      #: (
      #    Automaton::TransitionSystem[Integer, In, Out] hypothesis,
      #    Hash[Integer, Array[In]] state_to_prefix,
      #    Array[In] cex,
      #  ) -> void
      def process_cex(hypothesis, state_to_prefix, cex)
        border = @frontier.keys.find { cex[0..._1.size] == _1 }
        raise ArgumentError, "A border must exist" unless border

        while border.size < cex.size
          _, state = hypothesis.run(cex)
          state_node = @tree[state_to_prefix[state]]
          node = @tree[cex]
          raise "BUG: Nodes for the basis prefix and `cex` must exist" unless state_node && node

          witness = check_apartness(state_node, node)
          raise ArgumentError, "A witness prefix for `cex` and its hypothesis state prefix must exist" unless witness

          mid = border.size + ((cex.size - border.size) / 2)
          cex1 = cex[0...mid]
          cex2 = cex[mid...]

          _, state1 = hypothesis.run(cex1) # steep:ignore
          state1_prefix = state_to_prefix[state1]
          @tree.query(state1_prefix + cex2 + witness) # steep:ignore

          state1_node = @tree[state1_prefix]
          node1 = @tree[cex1] # steep:ignore
          raise "BUG: Nodes for the basis prefix and the prefix of `cex` must exist" unless state1_node && node1

          if check_apartness(state1_node, node1)
            cex = cex1
          else
            cex = state1_prefix + cex2 # steep:ignore
            border = @frontier.keys.find { cex[0..._1.size] == _1 }
            raise ArgumentError, "A border must exist" unless border
          end
        end
      end
    end
  end
end
