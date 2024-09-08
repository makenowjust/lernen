# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # Mealy represents a [Mealy machine](https://en.wikipedia.org/wiki/Mealy_machine).
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class Mealy < TransitionSystem #[Integer, In, Out]
      # @rbs @initial_state: Integer
      # @rbs @transition_function: Hash[[Integer, In], [Out, Integer]]

      #: (
      #    Integer initial_state,
      #    Hash[[Integer, In], [Out, Integer]] transition_function
      #  ) -> void
      def initialize(initial_state, transition_function)
        super()

        @initial_state = initial_state
        @transition_function = transition_function
      end

      attr_reader :initial_state #: Integer
      attr_reader :transition_function #: Hash[[Integer, In], [Out, Integer]]

      #: () -> :mealy
      def type = :mealy

      # @rbs override
      def initial_conf = initial_state

      # @rbs override
      def step(conf, input) = transition_function[[conf, input]]

      # Checks the structural equality between `self` and `other`.
      #
      #: (untyped other) -> bool
      def ==(other)
        other.is_a?(Mealy) && initial_state == other.initial_state && transition_function == other.transition_function
      end

      # Returns the array of states of this Mealy machine.
      #
      # The result array is sorted.
      #
      #: () -> Array[Integer]
      def states
        state_set = Set.new
        state_set << initial_state
        transition_function.each do |(state, _), (_, next_state)|
          state_set << state
          state_set << next_state
        end
        state_set.to_a.sort!
      end

      # @rbs override
      def to_graph
        nodes = states.to_h { |state| [state, Graph::Node[state.to_s, :circle]] }

        edges =
          transition_function.map do |(state, input), (output, next_state)|
            Graph::Edge[state, "#{input.inspect} | #{output.inspect}", next_state] # steep:ignore
          end

        Graph.new(nodes, edges)
      end

      # Generates a Mealy machine randomly.
      #
      #: [In, Out] (
      #    alphabet: Array[In],
      #    output_alphabet: Array[Out],
      #    ?min_state_size: Integer,
      #    ?max_state_size: Integer,
      #    ?num_reachable_paths: Integer,
      #    ?random: Random,
      #  ) -> Mealy[In, Out]
      def self.random(
        alphabet:,
        output_alphabet:,
        min_state_size: 5,
        max_state_size: 10,
        num_reachable_paths: 2,
        random: Random
      )
        raw_transition_function, =
          TransitionSystem.random_transition_function(
            alphabet:,
            min_state_size:,
            max_state_size:,
            num_reachable_paths:,
            random:
          )

        transition_function = {}
        raw_transition_function.each do |(state, input), next_state|
          output = output_alphabet.sample(random:)
          transition_function[[state, input]] = [output, next_state]
        end

        new(0, transition_function)
      end
    end
  end
end
