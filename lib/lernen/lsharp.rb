# frozen_string_literal: true

module Lernen
  # ObservationTree is an observation tree implementation.
  class ObservationTree
    Node = Data.define(:output, :edges)

    private_constant :Node

    def initialize(sul, automaton_type:)
      @sul = sul
      @automaton_type = automaton_type

      case automaton_type
      in :dfa | :moore
        @root = Node[@sul.query_empty, {}]
      in :mealy
        @root = Node[nil, {}]
      end
    end

    attr_reader :root

    # Returns a node for `inputs`.
    def [](inputs)
      node = @root
      inputs.each do |input|
        return nil unless node.edges[input]
        node = node.edges[input]
      end
      node
    end

    # Returns an output sequence for `inputs` if it is observed.
    # If it is not, it returns `nil` instead.
    def observed_query(inputs)
      return [@root.output] if inputs.empty?

      node = @root
      outputs = []
      inputs.each do |input|
        node = node.edges[input]
        return nil unless node

        outputs << node.output
      end

      outputs
    end

    # Returns an output sequence for `inputs`.
    # If it is not, it runs actual query over `sul`.
    def query(inputs)
      outputs = observed_query(inputs)
      return outputs unless outputs.nil?

      outputs = @sul.query(inputs)
      node = @root
      inputs.zip(outputs) do |input, output|
        node.edges[input] ||= Node[output, {}]
        node = node.edges[input]
      end

      outputs
    end
  end

  # LSharp is an implementation of the L# algorithm.
  class LSharp
    # Runs the L# algoritghm and returns an inferred automaton.
    def self.learn(alphabet, sul, oracle, automaton_type:, max_learning_rounds: nil)
      lsharp = new(alphabet, sul, oracle, automaton_type:, max_learning_rounds:)
      lsharp.learn
    end

    def initialize(alphabet, sul, oracle, automaton_type:, max_learning_rounds: nil)
      @alphabet = alphabet
      @sul = sul
      @oracle = oracle
      @automaton_type = automaton_type
      @max_learning_rounds = max_learning_rounds

      @observation_tree = ObservationTree.new(sul, automaton_type:)
      @witness_cache = {}

      @basis = []
      @frontier = {}
    end

    # Runs the L# algoritghm and returns an inferred automaton.
    def learn
      @basis << []

      loop do
        update_frontier

        next if promotion || completion || identification

        hypothesis = check_hypothesis
        return hypothesis if hypothesis
      end
    end

    private

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
        node1.edges.each do |input, next_node1|
          next_node2 = node2.edges[input]
          next unless next_node2
          return suffix + [input] if next_node1.output != next_node2.output
          queue << [suffix + [input], next_node1, next_node2]
        end
      end

      nil
    end

    def compute_witness(prefix1, prefix2)
      return @witness_cache[[prefix1, prefix2]] if @witness_cache[[prefix1, prefix2]]

      node1 = @observation_tree[prefix1]
      node2 = @observation_tree[prefix2]
      witness = check_apartness(node1, node2)
      @witness_cache[[prefix1, prefix2]] = witness

      witness
    end

    def add_basis(prefix)
      @basis << prefix
      prefix_node = @observation_tree[prefix]
      @frontier.each do |border, eq_prefixes|
        border_node = @observation_tree[border]
        eq_prefixes << prefix unless check_apartness(prefix_node, border_node)
      end
    end

    def add_frontier(border)
      border_node = @observation_tree[border]
      @frontier[border] = @basis.filter do |prefix|
        prefix_node = @observation_tree[prefix]
        check_apartness(prefix_node, border_node).nil?
      end
    end

    def update_frontier
      @frontier.each do |border, eq_prefixes|
        border_node = @observation_tree[border]
        @frontier[border] = eq_prefixes.filter do |prefix|
          prefix_node = @observation_tree[prefix]
          check_apartness(prefix_node, border_node).nil?
        end
      end
    end

    def construct_hypothesis
      transitions = {}
      prefix_to_state = @basis.each_with_index.to_h

      @basis.each do |prefix|
        state = prefix_to_state[prefix]
        node = @observation_tree[prefix]
        @alphabet.each do |input|
          next_node = node.edges[input]
          next_prefix = prefix + [input]
          next_state =
            if @frontier.include?(next_prefix)
              prefix_to_state[@frontier[next_prefix].first]
            else
              prefix_to_state[next_prefix]
            end

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
              .filter { |(_, prefix)| @observation_tree.observed_query(prefix).last }
              .to_set { |(state, _)| state }
          DFA.new(0, accept_states, transitions)
        in :moore
          outputs = state_to_prefix.transform_values { |state| @observation_tree.observed_query(state).last }
          Moore.new(0, outputs, transitions)
        in :mealy
          Mealy.new(0, transitions)
        end

      [automaton, state_to_prefix]
    end

    def check_consistency(hypothesis, state_to_prefix)
      queue = []
      queue << [[], hypothesis.initial_state, @observation_tree.root]

      until queue.empty?
        prefix, state, node = queue.shift
        state_prefix = state_to_prefix[state]
        next unless state_prefix
        state_node = @observation_tree[state_prefix]
        return prefix if check_apartness(node, state_node)

        node.edges.each do |input, next_node|
          _, next_state = hypothesis.step(state, input)
          queue << [prefix + [input], next_state, next_node]
        end
      end

      nil
    end

    def promotion
      isolated_borders = @frontier.to_a.filter { |(_, eq_prefixes)| eq_prefixes.empty? }.map { |(border, _)| border }

      return false if isolated_borders.empty?

      new_prefix = isolated_borders.first
      @frontier.delete(new_prefix)
      add_basis(new_prefix)

      true
    end

    def completion
      incomplete_borders =
        @basis
          .flat_map { |prefix| @alphabet.map { |a| prefix + [a] } }
          .filter do |border|
            @observation_tree[border].nil? || (!@basis.include?(border) && !@frontier.include?(border))
          end

      return false if incomplete_borders.empty?

      incomplete_borders.each do |border|
        @observation_tree.query(border)
        add_frontier(border)
      end

      true
    end

    def identification
      unidentified_borders = @frontier.keys.filter { @frontier[_1].size >= 2 }

      return false if unidentified_borders.empty?

      border = unidentified_borders.first
      prefix1, prefix2 = @frontier[border][0...2]
      witness = compute_witness(prefix1, prefix2)
      @observation_tree.query(border + witness)

      true
    end

    def check_hypothesis
      hypothesis, state_to_prefix = construct_hypothesis

      cex = check_consistency(hypothesis, state_to_prefix)
      unless cex
        cex0 = @oracle.find_cex(hypothesis)
        if cex0
          @observation_tree.query(cex0)
          node = @observation_tree.root
          state = hypothesis.initial_state
          cex0.size.times do |n|
            input = cex0[n]
            node = node.edges[input]
            _, state = hypothesis.step(state, input)
            state_node = @observation_tree[state_to_prefix[state]]
            if check_apartness(state_node, node)
              cex = cex0[0..n]
              break
            end
          end
        end
      end

      return hypothesis if cex.nil?

      process_cex(hypothesis, state_to_prefix, cex)

      nil
    end

    def process_cex(hypothesis, state_to_prefix, cex)
      border = @frontier.keys.find { cex[0..._1.size] == _1 }

      while border.size < cex.size
        _, state = hypothesis.run(cex)
        state_node = @observation_tree[state_to_prefix[state]]
        node = @observation_tree[cex]
        witness = check_apartness(state_node, node)

        mid = border.size + ((cex.size - border.size) / 2)
        cex1 = cex[0...mid]
        cex2 = cex[mid...]

        _, state1 = hypothesis.run(cex1)
        state1_prefix = state_to_prefix[state1]
        @observation_tree.query(state1_prefix + cex2 + witness)

        state1_node = @observation_tree[state1_prefix]
        node1 = @observation_tree[cex1]
        if check_apartness(state1_node, node1)
          cex = cex1
        else
          cex = state1_prefix + cex2
          border = @frontier.keys.find { cex[0..._1.size] == _1 }
        end
      end
    end
  end
end
