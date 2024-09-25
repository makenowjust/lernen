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
      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet: Array[Call]
      # @rbs @return_input: Return
      # @rbs @sul: System::SUL[In | Call | Return, bool]
      # @rbs @algorithm: :lstar | :kearns_vazirani | :lsharp
      # @rbs @algorithm_params: Hash[untyped, untyped]
      # @rbs @cex_processing: cex_processing_method

      # @rbs @initial_proc: Call | nil
      # @rbs @proc_to_learner: Hash[Call, Learner[In | Call, bool]]
      # @rbs @manager: ATRManager[In, Call, Return]

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

        @initial_proc = nil
        @proc_to_learner = {}
        @manager = ATRManager.new(alphabet, call_alphabet, return_input, scan_procs:)
      end

      #: () -> [Automaton::SPA[In, Call, Return], Hash[Call, Hash[Integer, Array[In | Call]]]]
      def build_hypothesis
        initial_proc = @initial_proc
        return build_first_hypothesis, {} unless initial_proc

        proc_to_dfa = {}
        proc_to_state_to_prefix = {}
        @proc_to_learner.each do |proc, learner|
          dfa, state_to_prefix = learner.build_hypothesis
          proc_to_dfa[proc] = dfa
          proc_to_state_to_prefix[proc] = state_to_prefix
        end

        hypothesis = Automaton::SPA.new(initial_proc, @return_input, proc_to_dfa)
        [hypothesis, proc_to_state_to_prefix]
      end

      #: (
      #    Array[In | Call | Return] cex,
      #    Automaton::SPA[In, Call, Return] _hypothesis,
      #    Hash[Call, Hash[Integer, Array[In | Call]]] _proc_to_state_to_prefix
      #  ) -> void
      def refine_hypothesis(cex, _hypothesis, _proc_to_state_to_prefix)
        extract_useful_information_from_cex(cex)

        loop { break unless refine_hypothesis_internal(cex) }
      end

      private

      #: () -> Automaton::SPA[In, Call, Return]
      def build_first_hypothesis # steep:ignore
        Automaton::SPA.new(nil, @return_input, {})
      end

      #: (Array[In | Call | Return] cex) -> void
      def extract_useful_information_from_cex(cex)
        return unless @sul.query_last(cex)

        new_procs = @manager.scan_positive_cex(cex)
        return if new_procs.empty?

        new_procs.each do |new_proc|
          # TODO: implement
        end
      end

      #: (Array[In | Call | Return] cex) -> bool
      def refine_hypothesis_internal(_cex)
        # TODO: implement
        false
      end
    end
  end
end
