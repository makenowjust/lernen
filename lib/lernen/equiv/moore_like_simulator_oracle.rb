# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # MooreLikeSimulatorOracle provides an implementation of equivalence query
    # that finds a counterexample by simulating the moore-like transition system.
    #
    # @rbs generic Conf -- Type for a configuration of this automaton
    # @rbs generic In   -- Type for input alphabet
    # @rbs generic Out  -- Type for output values
    class MooreLikeSimulatorOracle < Oracle #[In, Out]
      # @rbs @alphabet: Array[In]
      # @rbs @automaton: Automaton::MooreLike[Conf, In, Out]

      #: (
      #    Array[In] alphabet,
      #    Automaton::MooreLike[Conf, In, Out] spa,
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

        Automaton::MooreLike.find_separating_word(@alphabet, @automaton, hypothesis) # steep:ignore
      end
    end
  end
end
