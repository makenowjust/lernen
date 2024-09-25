# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # SPA represents a system of procedural automata.
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class SPA < MooreLike #[SPA::conf[Call], In | Call | Return, bool]
      # Conf is a configuration of SPA run.
      #
      # @rbs skip
      Conf = Data.define(:prev, :proc, :state)

      # @rbs!
      #   class Conf[Call] < Data
      #     attr_reader prev: conf[Call]
      #     attr_reader proc: Call
      #     attr_reader state: Integer
      #     def self.[]: [Call] (
      #       conf[Call] prev,
      #       Call proc,
      #       Integer state
      #     ) -> Conf[Call]
      #   end
      #
      #   type conf[Call] = Conf[Call] | :init | :term | :sink

      # @rbs @initial_proc: Call
      # @rbs @proc_to_dfa: Hash[Call, DFA[In | Call]]

      #: (
      #    Call initial_proc,
      #    Return return_input,
      #    Hash[Call, DFA[In | Call]] proc_to_dfa
      #  ) -> void
      def initialize(initial_proc, return_input, proc_to_dfa)
        super()

        @initial_proc = initial_proc
        @return_input = return_input
        @proc_to_dfa = proc_to_dfa
      end

      attr_reader :initial_proc #: Call
      attr_reader :return_input #: Return
      attr_reader :proc_to_dfa #: Hash[Call, DFA[In | Call]]

      #: () -> :spa
      def type = :spa

      # @rbs override
      def initial_conf = :init

      # @rbs override
      def step_conf(conf, input)
        case conf
        in :init
          if input == initial_proc
            dfa = proc_to_dfa[initial_proc]
            Conf[:term, initial_proc, dfa.initial_state]
          else
            :sink
          end
        in :term | :sink
          :sink
        in Conf[prev, proc, state]
          dfa = proc_to_dfa[proc]

          next_state = dfa.transition_function[[state, input]]
          if next_state
            next_dfa = proc_to_dfa[input]
            if next_dfa
              return_conf = Conf[prev, proc, next_state]
              return Conf[return_conf, input, next_dfa.initial_state]
            end

            return Conf[prev, proc, next_state]
          end

          input == return_input && dfa.accept_state_set.include?(state) ? prev : :sink
        end
      end

      # @rbs override
      def output(conf) = conf == :term

      # Checks the structural equality between `self` and `other`.
      #
      #: (untyped other) -> bool
      def ==(other)
        other.is_a?(SPA) && initial_proc == other.initial_proc && return_input == other.return_input && # steep:ignore
          proc_to_dfa == other.proc_to_dfa
      end
    end
  end
end
