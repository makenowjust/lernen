# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module KearnsVaziraniVPA
      # KearnzVaziraniVPALearner is an implementation of Kearnz-Vazirani algorithm for VPA.
      #
      # The idea behind this implementation is described by [Isberner (2015) "Foundations
      # of Active Automata Learning: An Algorithmic Overview"](https://eldorado.tu-dortmund.de/handle/2003/34282).
      #
      # @rbs generic In     -- Type for input alphabet
      # @rbs generic Call   -- Type for call alphabet
      # @rbs generic Return -- Type for return alphabet
      class KearnsVaziraniVPALearner < Learner #[In | Call | Return, bool]
        # @rbs @alphabet: Array[In]
        # @rbs @call_alphabet: Array[Call]
        # @rbs @return_alphabet: Array[Return]
        # @rbs @sul: System::MooreLikeSUL[In | Call | Return, bool]
        # @rbs @oracle: Equiv::Oracle[In | Call | Return, bool]
        # @rbs @cex_processing: cex_processing_method
        # @rbs @tree: DiscriminationTreeVPA[In, Call, Return] | nil

        #: (
        #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
        #    System::MooreLikeSUL[In | Call | Return, bool] sul,
        #    ?cex_processing: cex_processing_method
        #  ) -> void
        def initialize(alphabet, call_alphabet, return_alphabet, sul, cex_processing: :binary)
          super()

          @alphabet = alphabet.dup
          @call_alphabet = call_alphabet.dup
          @return_alphabet = return_alphabet.dup
          @sul = sul
          @cex_processing = cex_processing

          @tree = nil
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
            tree.refine_hypothesis(cex, hypothesis, state_to_prefix) # steep:ignore
            return
          end

          @tree =
            DiscriminationTreeVPA.new(
              @alphabet,
              @call_alphabet,
              @return_alphabet,
              @sul,
              cex:,
              cex_processing: @cex_processing
            )
        end

        private

        # Constructs the first hypothesis VPA.
        #
        #: () -> Automaton::VPA[In, Call, Return]
        def build_first_hypothesis
          transition_function = {}
          @alphabet.each { |input| transition_function[[0, input]] = 0 }

          return_transition_function = {}
          @return_alphabet.each do |return_input|
            return_transition_guard = return_transition_function[[0, return_input]] = {}
            @call_alphabet.each { |call_input| return_transition_guard[[0, call_input]] = 0 }
          end

          accept_state_set = @sul.query_empty ? Set[0] : Set.new
          Automaton::VPA.new(0, accept_state_set, transition_function, return_transition_function)
        end
      end
    end
  end
end
