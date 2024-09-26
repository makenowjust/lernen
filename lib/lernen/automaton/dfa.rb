# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # DFA represents a [deterministic finite-state automaton](https://en.wikipedia.org/wiki/Deterministic_finite_automaton).
    #
    # @rbs generic In -- Type for input alphabet
    class DFA < MooreLike #[Integer, In, bool]
      # @rbs @initial_state: Integer
      # @rbs @accept_state_set: Set[Integer]
      # @rbs @transition_function: Hash[[Integer, In], Integer]

      #: (
      #    Integer initial_state,
      #    Set[Integer] accept_state_set,
      #    Hash[[Integer, In], Integer] transition_function
      #  ) -> void
      def initialize(initial_state, accept_state_set, transition_function)
        super()

        @initial_state = initial_state
        @accept_state_set = accept_state_set
        @transition_function = transition_function
      end

      attr_reader :initial_state #: Integer
      attr_reader :accept_state_set #: Set[Integer]
      attr_reader :transition_function #: Hash[[Integer, In], Integer]

      #: () -> :dfa
      def type = :dfa

      # @rbs override
      def initial_conf = initial_state

      # @rbs override
      def step_conf(conf, input) = transition_function[[conf, input]]

      # @rbs override
      def output(conf) = accept_state_set.include?(conf)

      # Checks the structural equality between `self` and `other`.
      #
      #: (untyped other) -> bool
      def ==(other)
        other.is_a?(DFA) && initial_state == other.initial_state && accept_state_set == other.accept_state_set &&
          transition_function == other.transition_function
      end

      # Returns the array of states of this DFA.
      #
      # The result array is sorted.
      #
      #: () -> Array[Integer]
      def states
        state_set = Set.new
        state_set << initial_state
        accept_state_set.each { |state| state_set << state }
        transition_function.each do |(state, _), next_state|
          state_set << state
          state_set << next_state
        end
        state_set.to_a.sort!
      end

      # Returns the error state of this DFA.
      #
      # An error state is:
      #
      # - neither a initial state nor accepting states, and
      # - only having self-loops for all `input`.
      #
      # If an error state is not found, it returns `nil`.
      #
      #: () -> (Integer | nil)
      def error_state
        transition_function
          .group_by { |(state, _), _| state }
          .transform_values { _1.to_h { |(_, input), next_state| [input, next_state] } }
          .each do |state, transition_hash|
            # The initial state and accepting states are not an error state.
            next if state == initial_state || accept_state_set.include?(state)

            # An error state should only have self-loops.
            next unless transition_hash.all? { |_, next_state| state == next_state }

            return state
          end

        nil
      end

      # Returns a graph of this DFA.
      #
      # (?shows_error_state: bool) -> Graph
      def to_graph(shows_error_state: false)
        error_state = error_state() unless shows_error_state

        nodes =
          states
            .filter_map do |state|
              next if state == error_state
              shape = accept_state_set.include?(state) ? :doublecircle : :circle #: Graph::node_shape
              [state, Graph::Node[state.to_s, shape]]
            end
            .to_h

        edges =
          transition_function.filter_map do |(state, input), next_state|
            next if state == error_state || next_state == error_state
            Graph::Edge[state, input.inspect, next_state] # steep:ignore
          end

        Graph.new(nodes, edges)
      end

      # Generates a DFA randomly.
      #
      #: [In] (
      #    alphabet: Array[In],
      #    ?min_state_size: Integer,
      #    ?max_state_size: Integer,
      #    ?accept_state_size: Integer,
      #    ?random: Random,
      #  ) -> DFA[In]
      def self.random(alphabet:, min_state_size: 5, max_state_size: 10, accept_state_size: 2, random: Random)
        transition_function, reachable_paths =
          TransitionSystem.random_transition_function(
            alphabet:,
            min_state_size:,
            max_state_size:,
            num_reachable_paths: accept_state_size,
            random:
          )
        accept_state_set = reachable_paths.to_set(&:last) #: Set[Integer]

        new(0, accept_state_set, transition_function)
      end
    end
  end
end
