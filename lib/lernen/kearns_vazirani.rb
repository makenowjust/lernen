# frozen_string_literal: true

module Lernen
  # ClassificationTree is a classification tree implementation.
  class ClassificationTree
    Node = Data.define(:suffix, :edges)
    Leaf = Data.define(:prefix)

    private_constant :Node, :Leaf

    def initialize(alphabet, sul, cex:, automaton_type:, cex_processing:)
      @alphabet = alphabet
      @sul = sul
      @automaton_type = automaton_type
      @cex_processing = cex_processing

      @paths = {}

      case @automaton_type
      in :dfa | :moore
        @root = Node[[], {}]

        empty_out = sul.query_empty
        @root.edges[empty_out] = Leaf[[]]
        @paths[[]] = [empty_out]

        cex_out = sul.query(cex).last
        @root.edges[cex_out] = Leaf[cex]
        @paths[cex] = [cex_out]
      in :mealy
        prefix = cex[0...-1]
        suffix = [cex.last]
        @root = Node[suffix, {}]

        suffix_out = sul.query(suffix).last
        @root.edges[suffix_out] = Leaf[[]]
        @paths[[]] = [suffix_out]

        cex_out = sul.query(cex).last
        @root.edges[cex_out] = Leaf[prefix]
        @paths[prefix] = [cex_out]
      end
    end

    # Returns a prefix classified by `word`.
    def sift(word)
      node = @root
      path = []

      until node.is_a?(Leaf)
        inputs = word + node.suffix
        out = @sul.query(inputs).last
        path << out

        unless node.edges.include?(out)
          node.edges[out] = Leaf[word]
          @paths[word] = path
        end

        node = node.edges[out]
      end

      node.prefix
    end

    # Constructs a hypothesis automaton from this classification tree.
    def to_hypothesis
      transitions = {}

      queue = []
      prefix_to_state = {}

      queue << []
      prefix_to_state[[]] = prefix_to_state.size

      until queue.empty?
        prefix = queue.shift
        state = prefix_to_state[prefix]
        @alphabet.each do |input|
          word = prefix + [input]
          next_prefix = sift(word)

          unless prefix_to_state.include?(next_prefix)
            prefix_to_state[next_prefix] = prefix_to_state.size
            queue << next_prefix
          end

          next_state = prefix_to_state[next_prefix]
          case @automaton_type
          in :dfa | :moore
            transitions[[state, input]] = next_state
          in :mealy
            output = @sul.query(word).last
            transitions[[state, input]] = [output, next_state]
          end
        end
      end

      state_to_prefix = prefix_to_state.to_h { |q, i| [i, q] }
      automaton =
        case @automaton_type
        in :dfa
          accept_states = state_to_prefix.to_a.filter { |(_, q)| @paths[q][0] }.to_set { |(i, _)| i }
          DFA.new(0, accept_states, transitions)
        in :moore
          outputs = state_to_prefix.transform_values { |q| @paths[q][0] }
          Moore.new(0, outputs, transitions)
        in :mealy
          Mealy.new(0, transitions)
        end

      [automaton, state_to_prefix]
    end

    # Update this classification tree by the given `cex`.
    def process_cex(hypothesis, cex, state_to_prefix)
      old_prefix, new_input, new_suffix =
        CexProcessor.process(@sul, hypothesis, cex, state_to_prefix, cex_processing: @cex_processing)

      new_prefix = old_prefix + [new_input]
      new_out = @sul.query(new_prefix + new_suffix).last

      replace_prefix = sift(old_prefix + [new_input])
      replace_out = @sul.query(replace_prefix + new_suffix).last

      replace_node_path = @paths[replace_prefix]
      replace_node_parent = @root
      replace_node = @root.edges[replace_node_path.first]
      replace_node_path[1..].each do |out|
        replace_node_parent = replace_node
        replace_node = replace_node.edges[out]
      end

      new_node = Node[new_suffix, {}]
      replace_node_parent.edges[replace_node_path.last] = new_node

      new_node.edges[new_out] = Leaf[new_prefix]
      @paths[new_prefix] = replace_node_path + [new_out]

      new_node.edges[replace_out] = Leaf[replace_prefix]
      @paths[replace_prefix] = replace_node_path + [replace_out]
    end
  end

  # KearnsVazirani is an implementation of the Kearns-Vazirani automata learning algorithm.
  module KearnsVazirani
    # Runs the Kearns-Vazirani algoritghm and returns an inferred automaton.
    def self.learn(alphabet, sul, oracle, automaton_type:, cex_processing: :binary, max_learning_rounds: nil)
      hypothesis = construct_first_hypothesis(alphabet, sul, automaton_type)
      cex = oracle.find_cex(hypothesis)
      return hypothesis if cex.nil?

      classification_tree = ClassificationTree.new(alphabet, sul, cex:, automaton_type:, cex_processing:)
      learning_rounds = 0

      loop do
        break if max_learning_rounds && learning_rounds == max_learning_rounds
        learning_rounds += 1

        hypothesis, state_to_prefix = classification_tree.to_hypothesis
        cex = oracle.find_cex(hypothesis)
        break if cex.nil?

        classification_tree.process_cex(hypothesis, cex, state_to_prefix)
      end

      hypothesis, = classification_tree.to_hypothesis
      hypothesis
    end

    # Constructs the first hypothesis automaton.
    def self.construct_first_hypothesis(alphabet, sul, automaton_type)
      transitions = {}
      alphabet.each do |a|
        case automaton_type
        in :dfa | :moore
          transitions[[0, a]] = 0
        in :mealy
          out = sul.query([a]).last
          transitions[[0, a]] = [out, 0]
        end
      end

      case automaton_type
      in :dfa
        accept_states = sul.query_empty ? Set[0] : Set.new
        DFA.new(0, accept_states, transitions)
      in :moore
        outputs = { 0 => sul.query_empty }
        Moore.new(0, outputs, transitions)
      in :mealy
        Mealy.new(0, transitions)
      end
    end

    private_class_method :construct_first_hypothesis
  end
end
