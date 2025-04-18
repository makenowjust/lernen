# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module Procedural
      # ProceduralLearner is an implementation of the learning algorithm for SPA.
      #
      # This algorithm is described in [Frohme & Seffen (2021) "Compositional
      # Learning of Mutually Recursive Procedural Systems"](https://link.springer.com/article/10.1007/s10009-021-00634-y).
      #
      # @rbs generic In     -- Type for input alphabet
      # @rbs generic Call   -- Type for call alphabet
      # @rbs generic Return -- Type for return alphabet
      class ProceduralLearner < Learner #[In | Call | Return, bool]
        # @rbs @alphabet: Array[In]
        # @rbs @call_alphabet: Array[Call]
        # @rbs @return_input: Return
        # @rbs @sul: System::SUL[In | Call | Return, bool]
        # @rbs @algorithm: :lstar | :kearns_vazirani | :dhc | :lsharp
        # @rbs @algorithm_params: Hash[Symbol, untyped]
        # @rbs @cex_processing: cex_processing_method

        # @rbs @initial_proc: Call | nil
        # @rbs @proc_to_learner: Hash[Call, Learner[In | Call, bool]]
        # @rbs @manager: ATRManager[In, Call, Return]
        # @rbs @active_call_alphabet_set: Set[Call]

        #: (
        #    Array[In] alphabet,
        #    Array[Call] call_alphabet,
        #    Return return_input,
        #    System::SUL[In | Call | Return, bool] sul,
        #    ?algorithm: :lstar | :kearns_vazirani | :lsharp,
        #    ?algorithm_params: Hash[Symbol, untyped],
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
          @active_call_alphabet_set = Set.new
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

          @initial_proc = cex[0]

          new_procs = @manager.scan_positive_cex(cex)
          return if new_procs.empty?

          new_procs.each do |new_proc|
            proc_sul = ProceduralSUL.new(new_proc, @sul, @manager)
            new_learner =
              case @algorithm
              in :lstar
                LStar::LStarLearner.new(@alphabet, proc_sul, automaton_type: :dfa, **@algorithm_params)
              in :kearns_vazirani
                KearnsVazirani::KearnsVaziraniLearner.new(
                  @alphabet,
                  proc_sul,
                  automaton_type: :dfa,
                  **@algorithm_params
                )
              in :dhc
                DHC::DHCLearner.new(@alphabet, proc_sul, automaton_type: :dfa, **@algorithm_params)
              in :lsharp
                LSharp::LSharpLearner.new(@alphabet, proc_sul, automaton_type: :dfa, **@algorithm_params)
              end

            @proc_to_learner.each_key { |proc| new_learner.add_alphabet(proc) }
            @proc_to_learner[new_proc] = new_learner
            @proc_to_learner.each_value { |learner| learner.add_alphabet(new_proc) }
            @active_call_alphabet_set << new_proc
          end

          hypothesis, proc_to_state_to_prefix = build_hypothesis
          @manager.scan_procs(hypothesis.proc_to_dfa, proc_to_state_to_prefix)
        end

        #: (Array[In | Call | Return] cex) -> bool
        def refine_hypothesis_internal(cex)
          sul_out = @sul.query_last(cex)

          hypothesis = build_hypothesis[0]
          return false if hypothesis.run_last(cex) == sul_out

          update_atr_and_check_ts_conformance
          hypothesis, proc_to_state_to_prefix = build_hypothesis
          return false if hypothesis.run_last(cex) == sul_out

          return_indices = (0...cex.size).filter { |index| cex[index] == @return_input } # steep:ignore
          global_query =
            if sul_out
              ->(word) { hypothesis.run_last(word) }
            else
              ->(word) { @sul.query_last(word) }
            end
          global_acex = ReturnIndicesAcex.new(cex, return_indices, global_query, @manager) # steep:ignore
          idx = CexProcessor.process(global_acex, cex_processing: @cex_processing)

          return_index = return_indices[idx]
          call_index = @manager.find_call_index(cex, return_index)
          proc = cex[call_index]

          local_cex = @manager.project(cex[call_index + 1...return_index]) # steep:ignore
          dfa = hypothesis.proc_to_dfa[proc] # steep:ignore
          state_to_prefix = proc_to_state_to_prefix[proc] # steep:ignore
          @proc_to_learner[proc].refine_hypothesis(local_cex, dfa, state_to_prefix) # steep:ignore

          true
        end

        #: () -> bool
        def update_atr_and_check_ts_conformance
          updated = false

          hypothesis, proc_to_state_to_prefix = build_hypothesis
          while check_and_ensure_ts_conformance(hypothesis, proc_to_state_to_prefix)
            updated = true
            hypothesis, proc_to_state_to_prefix = build_hypothesis
            @manager.scan_procs(hypothesis.proc_to_dfa, proc_to_state_to_prefix)
          end

          updated
        end

        #: (
        #    Automaton::SPA[In, Call, Return] hypothesis,
        #    Hash[Call, Hash[Integer, Array[In | Call]]] proc_to_state_to_prefix
        #  ) -> bool
        def check_and_ensure_ts_conformance(hypothesis, proc_to_state_to_prefix)
          updated = false

          hypothesis.proc_to_dfa.each_key do |proc|
            ts = []
            ts << proc
            ts.concat(@manager.proc_to_terminating_sequence[proc])
            ts << @return_input
            if check_and_ensure_single_ts_conformance(ts, hypothesis, proc_to_state_to_prefix)
              updated = true
              break
            end
          end

          updated
        end

        #: (
        #    Array[In | Call | Return] ts,
        #    Automaton::SPA[In, Call, Return] hypothesis,
        #    Hash[Call, Hash[Integer, Array[In | Call]]] proc_to_state_to_prefix
        #  ) -> bool
        def check_and_ensure_single_ts_conformance(ts, hypothesis, proc_to_state_to_prefix) # rubocop:disable Naming/MethodParameterName
          updated = false

          ts.each_with_index do |input, index|
            next unless @active_call_alphabet_set.include?(input) # steep:ignore

            return_index = @manager.find_return_index(ts, index + 1)
            local_word = @manager.project(ts[index + 1...return_index]) # steep:ignore

            dfa = hypothesis.proc_to_dfa[input] # steep:ignore
            next if dfa.run_last(local_word)

            state_to_prefix = proc_to_state_to_prefix[input] # steep:ignore
            @proc_to_learner[input].refine_hypothesis(local_word, dfa, state_to_prefix) # steep:ignore

            updated = true
          end

          updated
        end
      end
    end
  end
end
