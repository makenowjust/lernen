# frozen_string_literal: true

module Lernen
  # ClassificationTree is a classification tree implementation.
  class ClassificationTree
    Node = Data.define(:suffix, :edges)
    Leaf = Data.define(:prefix)

    private_constant :Node, :Leaf

    def initialize(alphabet, sul, cex:, automaton_type:, cex_processing:, call_alphabet:, return_alphabet:)
      @alphabet = alphabet
      @sul = sul
      @automaton_type = automaton_type
      @cex_processing = cex_processing
      @call_alphabet = call_alphabet
      @return_alphabet = return_alphabet

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
      in :vpa
        @root = Node[[[], []], {}]

        empty_out = sul.query_empty
        @root.edges[empty_out] = Leaf[[]]
        @paths[[]] = [empty_out]

        cex_out = sul.query(cex).last
        @root.edges[cex_out] = Leaf[cex]
        @paths[cex] = [cex_out]
      end
    end

    # Returns a prefix classified by `word`.
    def sift(word)
      node = @root
      path = []

      until node.is_a?(Leaf)
        inputs =
          case @automaton_type
          in :vpa
            access, suffix = node.suffix
            access + word + suffix
          in :dfa | :moore | :mealy
            word + node.suffix
          end

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
      returns = {}

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
          in :dfa | :moore | :vpa
            transitions[[state, input]] = next_state
          in :mealy
            output = @sul.query(word).last
            transitions[[state, input]] = [output, next_state]
          end
        end

        next unless @automaton_type == :vpa

        found_states = prefix_to_state.values

        returns.each do |(return_state, return_input), return_transitions|
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
            return_transitions[[state, call_input]] = next_state
          end
        end

        @return_alphabet.each do |return_input|
          return_transitions = returns[[state, return_input]] = {}
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
              return_transitions[[call_state, call_input]] = next_state
            end
          end
        end
      end

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
        in :vpa
          accept_states = state_to_prefix.to_a.filter { |(_, q)| @paths[q][0] }.to_set { |(i, _)| i }
          state_to_prefix[nil] = [@return_alphabet.first] unless @return_alphabet.empty?
          state_to_prefix = VPA::StateToPrefixMapping.new(state_to_prefix)
          VPA.new(0, accept_states, transitions, returns)
        end

      [automaton, state_to_prefix]
    end

    # Update this classification tree by the given `cex`.
    def process_cex(hypothesis, cex, state_to_prefix)
      old_prefix, new_input, new_suffix =
        CexProcessor.process(@sul, hypothesis, cex, state_to_prefix, cex_processing: @cex_processing)

      _, old_state = hypothesis.run(old_prefix)
      _, replace_state = hypothesis.step(old_state, new_input)

      case @automaton_type
      in :dfa | :moore | :mealy
        new_prefix = state_to_prefix[old_state] + [new_input]
        new_out = @sul.query(new_prefix + new_suffix).last

        replace_prefix = state_to_prefix[replace_state]
        replace_out = @sul.query(replace_prefix + new_suffix).last
      in :vpa
        new_suffix = [state_to_prefix[VPA::Conf[hypothesis.initial_state, replace_state.stack]], new_suffix]

        old_state_prefix = state_to_prefix.state_prefix(old_state.state)
        if @alphabet.include?(new_input)
          new_prefix = old_state_prefix + [new_input]
        else
          call_state, call_input = old_state.stack[-1]
          call_prefix = state_to_prefix.state_prefix(call_state)
          new_prefix = call_prefix + [call_input] + old_state_prefix + [new_input]
        end
        # new_out = @sul.query(cex).last
        new_out = @sul.query(new_suffix[0] + new_prefix + new_suffix[1]).last

        replace_prefix = state_to_prefix.state_prefix(replace_state.state)
        replace_out = @sul.query(new_suffix[0] + replace_prefix + new_suffix[1]).last
      end

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
    def self.learn(
      alphabet,
      sul,
      oracle,
      automaton_type:,
      cex_processing: :binary,
      max_learning_rounds: nil,
      call_alphabet: nil,
      return_alphabet: nil
    )
      hypothesis = construct_first_hypothesis(alphabet, sul, automaton_type, call_alphabet:, return_alphabet:)
      cex = oracle.find_cex(hypothesis)
      return hypothesis if cex.nil?

      classification_tree =
        ClassificationTree.new(alphabet, sul, cex:, automaton_type:, cex_processing:, call_alphabet:, return_alphabet:)
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
    def self.construct_first_hypothesis(alphabet, sul, automaton_type, call_alphabet:, return_alphabet:)
      transitions = {}
      alphabet.each do |input|
        case automaton_type
        in :dfa | :moore | :vpa
          transitions[[0, input]] = 0
        in :mealy
          out = sul.query([input]).last
          transitions[[0, input]] = [out, 0]
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
      in :vpa
        raise ArgumentError, "Learning 1-SEVPA needs call and return alphabet." unless call_alphabet && return_alphabet

        returns = {}
        return_alphabet.each do |return_input|
          return_transitions = returns[[0, return_input]] = {}
          call_alphabet.each { |call_input| return_transitions[[0, call_input]] = 0 }
        end

        accept_states = sul.query_empty ? Set[0] : Set.new
        VPA.new(0, accept_states, transitions, returns)
      end
    end

    private_class_method :construct_first_hypothesis
  end
end
