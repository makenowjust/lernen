# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # SPASimulatorOracle provides an implementation of equivalence query
    # that finds a counterexample by simulating the SPA.
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class SPASimulatorOracle < Oracle #[In | Call | Return, bool]
      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet: Array[Call]
      # @rbs @spa: Automaton::SPA[In, Call, Return]

      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Automaton::SPA[In, Call, Return] spa,
      #    System::SUL[In | Call | Return, bool] sul
      #  ) -> void
      def initialize(alphabet, call_alphabet, spa, sul)
        super(sul)

        @alphabet = alphabet
        @call_alphabet = call_alphabet
        @spa = spa
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        Automaton::SPA.find_separating_word(@alphabet, @call_alphabet, @spa, hypothesis) # steep:ignore
      end
    end
  end
end
