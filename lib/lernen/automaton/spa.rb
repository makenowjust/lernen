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

      # @rbs override
      def to_graph
        subgraphs =
          proc_to_dfa.map do |proc, dfa|
            Graph::SubGraph[proc.inspect, dfa.to_graph] # steep:ignore
          end

        Graph.new({}, [], subgraphs)
      end

      # Returns the mapping from procedure names to access/terminating/return sequences.
      #
      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet
      #  ) -> [
      #    Hash[Call, Array[In | Call | Return]],
      #    Hash[Call, Array[In | Call | Return]],
      #    Hash[Call, Array[In | Call | Return]]
      #  ]
      def proc_to_atr_sequence(alphabet, call_alphabet)
        proc_to_terminating_sequence = compute_proc_to_terminating_sequence(alphabet, call_alphabet)
        proc_to_access_sequence, proc_to_return_sequence =
          compute_proc_to_access_and_return_sequences(alphabet, call_alphabet, proc_to_terminating_sequence)
        [proc_to_terminating_sequence, proc_to_access_sequence, proc_to_return_sequence]
      end

      private

      # Returns the mapping from procedure names to terminating sequences.
      #
      #: (Array[In] alphabet, Array[Call] call_alphabet) -> Hash[Call, Array[In | Call | Return]]
      def compute_proc_to_terminating_sequence(alphabet, call_alphabet)
        proc_to_terminating_sequence = {}

        call_alphabet.each do |proc|
          dfa = proc_to_dfa[proc]
          next unless dfa
          terminating_sequence = dfa.shortest_accept_word(alphabet)
          next unless terminating_sequence
          proc_to_terminating_sequence[proc] = terminating_sequence
        end

        remaining_proc_set = call_alphabet.to_set
        remaining_proc_set.subtract(proc_to_terminating_sequence.keys)

        eligible_alphabet = alphabet.dup
        eligible_alphabet.concat(proc_to_terminating_sequence.keys)

        stable = false
        until stable
          stable = true

          remaining_proc_set.each do |proc|
            dfa = proc_to_dfa[proc]

            unless dfa
              remaining_proc_set.delete(proc)
              next
            end

            terminating_sequence = dfa.shortest_accept_word(eligible_alphabet)
            next unless terminating_sequence

            proc_to_terminating_sequence[proc] = ProcUtil.expand(
              return_input,
              terminating_sequence,
              proc_to_terminating_sequence
            )
            remaining_proc_set.delete(proc)
            eligible_alphabet << proc # steep:ignore

            stable = false
          end
        end

        proc_to_terminating_sequence
      end

      # Returns the mapping from procedure names to access and return sequences.
      #
      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Hash[Call, Array[In | Call | Return]] proc_to_terminating_sequence
      #  ) -> [Hash[Call, Array[In | Call | Return]], Hash[Call, Array[In | Call | Return]]]
      def compute_proc_to_access_and_return_sequences(alphabet, call_alphabet, proc_to_terminating_sequence)
        proc_to_access_sequence = {}
        proc_to_return_sequence = {}

        return proc_to_access_sequence, proc_to_return_sequence unless proc_to_dfa[initial_proc]

        proc_to_access_sequence[initial_proc] = [initial_proc]
        proc_to_return_sequence[initial_proc] = [return_input]

        found_call_alphabet = [initial_proc]
        unfound_call_alphabet_set = call_alphabet.to_set
        unfound_call_alphabet_set.delete(initial_proc)

        stable = false
        until stable
          stable = true

          found_call_alphabet.each do |found_proc|
            dfa = proc_to_dfa[found_proc]

            proc_to_access_and_return_word =
              explore_proc_to_access_and_return_word(dfa, alphabet, found_call_alphabet, unfound_call_alphabet_set)
            proc_to_access_and_return_word.each do |proc, (i2s, n2a)|
              access_sequence = []
              access_sequence.concat(proc_to_access_sequence[found_proc])
              access_sequence.concat(ProcUtil.expand(return_input, i2s, proc_to_terminating_sequence))
              access_sequence << proc
              proc_to_access_sequence[proc] = access_sequence

              return_sequence = []
              return_sequence << return_input
              return_sequence.concat(ProcUtil.expand(return_input, n2a, proc_to_terminating_sequence))
              return_sequence.concat(proc_to_return_sequence[found_proc])
              proc_to_return_sequence[proc] = return_sequence

              found_call_alphabet << proc
              unfound_call_alphabet_set.delete(proc)

              stable = false
            end
          end
        end

        [proc_to_access_sequence, proc_to_return_sequence]
      end

      #: (
      #    DFA[In | Call] dfa,
      #    Array[In] alphabet,
      #    Array[Call] found_call_alphabet,
      #    Set[Call] unfound_call_alphabet_set
      #  ) -> Hash[Call, [Array[In | Call], Array[In | Call]]]
      def explore_proc_to_access_and_return_word(dfa, alphabet, found_call_alphabet, unfound_call_alphabet_set)
        states = dfa.states
        shortest_words = dfa.compute_shortest_words(alphabet + found_call_alphabet)

        proc_to_access_and_return_word = {}
        unfound_call_alphabet_set.each do |proc|
          found = false
          states.each do |state|
            next_state = dfa.transition_function[[state, proc]]
            i2s = shortest_words[[dfa.initial_state, state]]
            next unless i2s

            dfa.accept_state_set.each do |accept_state|
              n2a = shortest_words[[next_state, accept_state]]
              next unless n2a

              proc_to_access_and_return_word[proc] = [i2s, n2a]
              found = true
              break
            end
            break if found
          end
        end

        proc_to_access_and_return_word
      end
    end
  end
end
