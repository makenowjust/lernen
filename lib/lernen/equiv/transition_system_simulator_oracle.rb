# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # TransitionSystemSimulatorOracle provides an implementation of equivalence query
    # that finds a counterexample by simulating the transition system.
    #
    # @rbs generic Conf -- Type for a configuration of this automaton
    # @rbs generic In   -- Type for input alphabet
    # @rbs generic Out  -- Type for output values
    class TransitionSystemSimulatorOracle < Oracle #[In, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @automaton: Automaton::TransitionSystem[Conf, In, Out]

      #: (
      #    Array[In] alphabet,
      #    Automaton::TransitionSystem[Conf, In, Out] spa,
      #    System::SUL[In, Out] sul
      #  ) -> void
      def initialize(alphabet, automaton, sul)
        super(sul)

        @alphabet = alphabet
        @automaton = automaton
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        Automaton::TransitionSystem.find_separating_word(@alphabet, @automaton, hypothesis)
      end
    end
  end
end
