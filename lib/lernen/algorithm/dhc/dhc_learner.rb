# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module DHC
      # DHCLearner is an implementation of DHC.
      #
      # DHC (Dynamic Hypothesis Construction) is introduced by [Merten et al. (2011)
      # "Automata Learning with On-the-Fly Direct Hypothesis Construction"](https://link.springer.com/chapter/10.1007/978-3-642-34781-8_19).
      #
      # @rbs generic In
      # @rbs generic Out
      class DHCLearner < Learner #[In, Out]
        # @rbs @alphabet: Array[In]
        # @rbs @sul: System::SUL[In, Out]
        # @rbs @automaton_type: :dfa | :moore | :mealy
        # @rbs @cex_processing: cex_processing_method

        # @rbs @build_hypothesis_cache: [Automaton::TransitionSystem[Integer, In, Out], Hash[Integer, Array[In]]] | nil
        # @rbs @splitters: Array[Array[In]]

        #: (
        #    Array[In] alphabet, System::SUL[In, Out] sul,
        #    automaton_type: :dfa | :moore | :mealy,
        #    ?cex_processing: cex_processing_method
        #  ) -> void
        def initialize(alphabet, sul, automaton_type:, cex_processing: :binary)
          super()

          @alphabet = alphabet
          @sul = sul
          @automaton_type = automaton_type
          @cex_processing = cex_processing

          @build_hypothesis_cache = nil
          @splitters = []

          @splitters << [] if @automaton_type == :dfa || @automaton_type == :moore
        end

        # @rbs override
        def add_alphabet(input)
          @alphabet << input
          @build_hypothesis_cache = nil
        end

        # @rbs override
        def build_hypothesis
          cache = @build_hypothesis_cache
          return cache if cache

          transition_function = {}
          state_to_prefix = {}

          sig_to_state = {}
          queue = []

          queue << [nil, nil, []]

          until queue.empty?
            parent_state, parent_output, prefix = queue.shift

            sig = []
            @alphabet.each do |input|
              word = prefix + [input]
              sig << @sul.query_last(word)
            end
            @splitters.each do |splitter|
              word = prefix + splitter
              sig << @sul.query_last(word) # steep:ignore
            end

            next_state = sig_to_state[sig]
            unless next_state
              next_state = sig_to_state.size
              sig_to_state[sig] = next_state
              state_to_prefix[next_state] = prefix

              @alphabet.each_with_index { |input, index| queue << [next_state, sig[index], prefix + [input]] }
            end

            next unless parent_state

            case @automaton_type
            in :dfa | :moore
              transition_function[[parent_state, prefix.last]] = next_state
            in :mealy
              transition_function[[parent_state, prefix.last]] = [parent_output, next_state]
            end
          end

          automaton =
            case @automaton_type
            in :dfa
              accept_state_set =
                sig_to_state.to_a.filter { |(sig, _)| sig[@alphabet.size] }.to_set { |(_, state)| state }
              Automaton::DFA.new(0, accept_state_set, transition_function)
            in :moore
              output_function = sig_to_state.invert.transform_values { |sig| sig[@alphabet.size] }
              Automaton::Moore.new(0, output_function, transition_function)
            in :mealy
              Automaton::Mealy.new(0, transition_function)
            end

          @build_hypothesis_cache = [automaton, state_to_prefix]
        end

        # @rbs override
        def refine_hypothesis(cex, hypothesis, state_to_prefix)
          state_to_prefix_lambda = ->(state) { state_to_prefix[state] }
          acex = CexProcessor::PrefixTransformerAcex.new(cex, @sul, hypothesis, state_to_prefix_lambda)

          n = CexProcessor.process(acex, cex_processing: @cex_processing)
          new_suffix = cex[n + 1...]

          @build_hypothesis_cache = nil
          @splitters << new_suffix # steep:ignore
        end
      end
    end
  end
end
