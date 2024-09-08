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
            [state, Graph::Node["#{state} | #{output_function[state].inspect}", :circle]] # steep:ignore
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
    end
  end
end
