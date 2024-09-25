# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # ProceduralSPA is an implementation of the learning algorithm for SPA.
    #
    # This algorithm is described in [Frohme & Seffen (2021) "Compositional
    # Learning of Mutually Recursive Procedural Systems"](https://link.springer.com/article/10.1007/s10009-021-00634-y).
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class Procedural < Learner #[In | Call | Return, bool]
      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Return return_input,
      #    System::SUL[In | Call | Return, bool] sul,
      #    ?algorithm: :lstar | :kearns_vazirani | :lsharp,
      #    ?algorithm_params: Hash[untyped, untyped],
      #    ?cex_processing: cex_processing_method,
      #    ?scan_procs: bool
      #  ) -> void
      def initialize(
        alphabet,
        call_alphabet,
        return_input,
        sul,
        algorithm: :kearns_vazirani,
        algorithm_params: {},
        cex_processing: :binary,
        scan_procs: true
      )
        super()

        @alphabet = alphabet.dup
        @call_alphabet = call_alphabet.dup
        @return_input = return_input
        @sul = sul
        @algorithm = algorithm
        @algorithm_params = algorithm_params
        @cex_processing = cex_processing

        @manager = ATRManager.new(alphabet, call_alphabet, return_input, scan_procs:)
      end
    end
  end
end
