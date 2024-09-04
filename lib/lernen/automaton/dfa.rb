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

      # Returns a [mermaid](https://mermaid.js.org) diagram of this DFA.
      #
      #: (?direction: "TD" | "LR") -> String
      def to_mermaid(direction: "TD")
        mmd = +""

        mmd << "flowchart #{direction}\n"

        states.each do |state|
          mmd << (accept_state_set.include?(state) ? "  #{state}(((#{state})))\n" : "  #{state}((#{state}))\n")
        end
        mmd << "\n"

        transition_function.each do |(state, input), next_state|
          mmd << "  #{state} -- \"'#{input}'\" --> #{next_state}\n"
        end

        mmd.freeze
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
