# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # Moore represents a [Moore machine](https://en.wikipedia.org/wiki/Moore_machine).
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class Moore < MooreLike #[Integer, In, Out]
      # @rbs @initial_state: Integer
      # @rbs @output_function: Hash[Integer, Out]
      # @rbs @transition_function: Hash[[Integer, In], Integer]

      #: (
      #    Integer initial_state,
      #    Hash[Integer, Out] output_function,
      #    Hash[[Integer, In], Integer] transition_function,
      #  ) -> void
      def initialize(initial_state, output_function, transition_function)
        super()

        @initial_state = initial_state
        @output_function = output_function
        @transition_function = transition_function
      end

      attr_reader :initial_state #: Integer
      attr_reader :output_function #: Hash[Integer, Out]
      attr_reader :transition_function #: Hash[[Integer, In], Integer]

      #: () -> :moore
      def type = :moore

      # @rbs override
      def initial_conf = initial_state

      # @rbs override
      def step_conf(conf, input) = transition_function[[conf, input]]

      # @rbs override
      def output(conf) = output_function[conf]

      # Checks the structural equality between `self` and `other`.
      #
      #: (untyped other) -> bool
      def ==(other)
        other.is_a?(Moore) && initial_state == other.initial_state && output_function == other.output_function &&
          transition_function == other.transition_function
      end

      # Returns the array of states of this Moore machine.
      #
      # The result array is sorted.
      #
      #: () -> Array[Integer]
      def states
        state_set = Set.new
        state_set << initial_state
        output_function.each_key { |state| state_set << state }
        transition_function.each do |(state, _), next_state|
          state_set << state
          state_set << next_state
        end
        state_set.to_a.sort!
      end

      # @rbs override
      def to_graph
        nodes =
          states.to_h do |state|
            [state, Graph::Node["#{state} | #{output_function[state].inspect}", :record]] # steep:ignore
          end

        edges =
          transition_function.map do |(state, input), next_state|
            Graph::Edge[state, input.inspect, next_state] # steep:ignore
          end

        Graph.new(nodes, edges)
      end

      # Generates a Moore machine randomly.
      #
      #: [In, Out] (
      #    alphabet: Array[In],
      #    output_alphabet: Array[Out],
      #    ?min_state_size: Integer,
      #    ?max_state_size: Integer,
      #    ?num_reachable_paths: Integer,
      #    ?random: Random,
      #  ) -> Moore[In, Out]
      def self.random(
        alphabet:,
        output_alphabet:,
        min_state_size: 5,
        max_state_size: 10,
        num_reachable_paths: 2,
        random: Random
      )
        transition_function, =
          TransitionSystem.random_transition_function(
            alphabet:,
            min_state_size:,
            max_state_size:,
            num_reachable_paths:,
            random:
          )

        output_function = {}
        transition_function.each do |(state, _), next_state|
          [state, next_state].each do |state|
            next if output_function[state]
            output_function[state] = output_alphabet.sample(random:)
          end
        end

        new(0, output_function, transition_function)
      end

      RE_MOORE_LABEL = /\A\{\s*(?<state_name>[^\s|]+)\s*\|\s*(?<output_value>[^\s|]+)\s*\}\z/

      # Constructs a Moore machine from [Automata Wiki](https://automata.cs.ru.nl)'s DOT source.
      # See https://automata.cs.ru.nl/Syntax/Moore.
      #
      # It returns a tuple with two elements:
      #
      # 1. A `Moore` from the DOT source.
      # 2. A `Hash` mapping from state IDs to names.
      #
      #: (String source) -> [Moore[String, String], Hash[Integer, String]]
      def self.from_automata_wiki_dot(source)
        name_to_state, initial_state, state_nodes, transitions = TransitionSystem.parse_automata_wiki_dot(source)

        output_function = {}
        state_nodes.each do |(state, label, _)|
          match = label.match(RE_MOORE_LABEL)
          raise ArgumentError, "Invalid DOT" unless match
          output_function[state] = match[:output_value]
        end

        transition_function = {}
        transitions.each { |(from, to, label)| transition_function[[from, label]] = to }

        state_to_name = name_to_state.to_h { |name, state| [state, name] }

        [new(initial_state, output_function, transition_function), state_to_name]
      end

      # Returns [Automata Wiki](https://automata.cs.ru.nl)'s DOT representation of this Moore machine.
      #
      #: (?Hash[Integer, String] state_to_name) -> String
      def to_automata_wiki_dot(state_to_name = {})
        nodes = {}
        nodes["__start0"] = Graph::Node["", :none]
        states.each do |state|
          name = state_to_name[state] || state
          nodes[name] = Graph::Node["#{name} | #{output_function[state]}", :record]
        end

        edges =
          [Graph::Edge["__start0", nil, state_to_name[initial_state] || initial_state]] +
            transition_function.map do |(state, input), next_state|
              name = state_to_name[state] || state
              next_name = state_to_name[next_state] || next_state
              Graph::Edge[name, input.to_s, next_name] # steep:ignore
            end

        Graph.new(nodes, edges).to_dot
      end
    end
  end
end
