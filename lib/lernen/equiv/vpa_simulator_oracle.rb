# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Equiv
    # VPASimulatorOracle provides an implementation of equivalence query
    # that finds a counterexample by simulating the VPA.
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class VPASimulatorOracle < Oracle #[In | Call | Return, bool]
      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet: Array[Call]
      # @rbs @return_alphabet: Array[Return]
      # @rbs @spa: Automaton::VPA[In, Call, Return]

      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Array[Return] return_alphabet,
      #    Automaton::VPA[In, Call, Return] vpa,
      #    System::SUL[In | Call | Return, bool] sul
      #  ) -> void
      def initialize(alphabet, call_alphabet, return_alphabet, vpa, sul)
        super(sul)

        @alphabet = alphabet
        @call_alphabet = call_alphabet
        @return_alphabet = return_alphabet
        @vpa = vpa
      end

      # @rbs override
      def find_cex(hypothesis)
        super

        Automaton::VPA.find_separating_word(
          @alphabet,
          @call_alphabet,
          @return_alphabet,
          @vpa,
          hypothesis # steep:ignore
        )
      end
    end
  end
end
