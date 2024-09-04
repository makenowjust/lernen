# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module System
    # TransitionSystemSimulator is a system under learning (SUL) using a transition system simulation.
    #
    # @rbs generic Conf -- Type for a configuration of this automaton
    # @rbs generic In   -- Type for input alphabet
    # @rbs generic Out  -- Type for output values
    class TransitionSystemSimulator < SUL #[In, Out]
      # @rbs @automaton: Automaton::TransitionSystem[Conf, In, Out]
      # @rbs @current_conf: Conf | nil

      #: (Automaton::TransitionSystem[Conf, In, Out] automaton, ?cache: bool) -> void
      def initialize(automaton, cache: true)
        super(cache:)

        @automaton = automaton
        @current_conf = nil
      end

      # @rbs override
      def setup
        @current_conf = @automaton.initial_conf
      end

      # @rbs override
      def shutdown
        @current_conf = nil
      end

      # @rbs override
      def step(input)
        output, @current_conf = @automaton.step(@current_conf, input) # steep:ignore
        output
      end
    end
  end
end
