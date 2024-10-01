# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module KearnsVazirani
      # KearnzVaziraniLearner is an implementation of Kearnz-Vazirani algorithm.
      #
      # Kearns-Vazirani is introduced by [Kearns & Vazirani (1994) "An Introduction to
      # Computational Learning Theory"](https://direct.mit.edu/books/monograph/2604/An-Introduction-to-Computational-Learning-Theory).
      #
      # @rbs generic In  -- Type for input alphabet
      # @rbs generic Out -- Type for output values
      class KearnsVaziraniLearner < Learner #[In, Out]
        # @rbs @alphabet: Array[In]
        # @rbs @sul: System::SUL[In, Out]
        # @rbs @oracle: Equiv::Oracle[In, Out]
        # @rbs @automaton_type: :dfa | :moore | :mealy
        # @rbs @cex_processing: cex_processing_method
        # @rbs @tree: DiscriminationTree[In, Out] | nil

        #: (
        #    Array[In] alphabet, System::SUL[In, Out] sul,
        #    automaton_type: :dfa | :moore | :mealy,
        #    ?cex_processing: cex_processing_method
        #  ) -> void
        def initialize(alphabet, sul, automaton_type:, cex_processing: :binary)
          super()

          @alphabet = alphabet.dup
          @sul = sul
          @automaton_type = automaton_type
          @cex_processing = cex_processing

          @tree = nil
        end

        # @rbs override
        def add_alphabet(input)
          @alphabet << input
        end

        # @rbs override
        def build_hypothesis
          tree = @tree
          return tree.build_hypothesis if tree

          [build_first_hypothesis, { 0 => [] }]
        end

        # @rbs override
        def refine_hypothesis(cex, hypothesis, state_to_prefix)
          tree = @tree
          if tree
            tree.refine_hypothesis(cex, hypothesis, state_to_prefix)
            return
          end

          @tree =
            DiscriminationTree.new(
              @alphabet,
              @sul,
              cex:,
              automaton_type: @automaton_type,
              cex_processing: @cex_processing
            )
        end

        private

        # Constructs the first hypothesis automaton.
        #
        #: () -> Automaton::TransitionSystem[Integer, In, Out]
        def build_first_hypothesis
          transition_function = {}
          @alphabet.each do |input|
            case @automaton_type
            in :dfa | :moore
              transition_function[[0, input]] = 0
            in :mealy
              out = @sul.query_last([input])
              transition_function[[0, input]] = [out, 0]
            end
          end

          case @automaton_type
          in :dfa
            accept_state_set = @sul.query_empty ? Set[0] : Set.new
            Automaton::DFA.new(0, accept_state_set, transition_function)
          in :moore
            output_function = { 0 => @sul.query_empty }
            Automaton::Moore.new(0, output_function, transition_function)
          in :mealy
            Automaton::Mealy.new(0, transition_function)
          end
        end
      end
    end
  end
end
