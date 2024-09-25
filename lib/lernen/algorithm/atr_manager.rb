# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # ATRManager is a collection to manage access, terminating, and return sequences.
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class ATRManager
      # @rbs @alphabet: Array[In]
      # @rbs @call_alphabet_set: Set[Call]
      # @rbs @return_input: Return
      # @rbs @scan_procs: bool

      # @rbs @proc_to_access_sequence: Hash[Call, Array[In | Call | Return]]
      # @rbs @proc_to_terminating_sequence: Hash[Call, Array[In | Call | Return]]
      # @rbs @proc_to_return_sequence: Hash[Call, Array[In | Call | Return]]

      #: (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Return return_input,
      #    ?scan_procs: bool
      #  ) -> void
      def initialize(alphabet, call_alphabet, return_input, scan_procs: true)
        @alphabet = alphabet
        @call_alphabet_set = call_alphabet.to_set
        @return_input = return_input
        @scan_procs = scan_procs

        @proc_to_access_sequence = {}
        @proc_to_terminating_sequence = {}
        @proc_to_return_sequence = {}
      end

      #: (Array[In | Call | Return] cex) -> Array[Call]
      def scan_positive_cex(cex)
        new_procs = extract_potential_terminating_sequences(cex)
        extract_potential_access_and_return_sequences(cex)
        new_procs
      end

      #: (
      #    Hash[Call, Automaton::DFA[In | Call]] procs,
      #    Hash[Call, Hash[Integer, Array[In | Call]]] proc_to_state_to_prefix
      #  ) -> void
      def scan_procs(procs, proc_to_state_to_prefix)
        return unless @scan_procs

        updated = false
        stable = true
        while stable
          stable = true
          procs.each do |proc, dfa|
            current_terminating_sequence = @proc_to_terminating_sequence[proc]
            state_to_prefix = proc_to_state_to_prefix[proc]
            hypothesis_terminating_sequence =
              dfa.accept_state_set.to_a.map { |accept_state| expand(state_to_prefix[accept_state]) }.min_by(&:size)

            next unless hypothesis_terminating_sequence
            next if current_terminating_sequence.size <= hypothesis_terminating_sequence.size

            updated = true
            stable = false
            @proc_to_terminating_sequence[proc] = hypothesis_terminating_sequence
          end
        end

        return unless updated

        optimize_sequences(@proc_to_terminating_sequence)
        optimize_sequences(@proc_to_access_sequence)
        optimize_sequences(@proc_to_return_sequence)
      end

      private

      #: (Array[In | Call | Return] cex) -> Array[Call]
      def extract_potential_terminating_sequences(cex)
        new_procs = []
        cex.each_with_index do |input, index|
          next unless @call_alphabet_set.include?(input) # steep:ignore

          return_index = find_return_index(cex, index + 1)
          potential_terminating_sequence = cex[index + 1...return_index]
          current_terminating_sequence = @proc_to_terminating_sequence[input] # steep:ignore

          if current_terminating_sequence.nil?
            new_procs << input
            @proc_to_terminating_sequence[input] = potential_terminating_sequence # steep:ignore
          elsif potential_terminating_sequence.size < current_terminating_sequence.size # steep:ignore
            @proc_to_terminating_sequence[input] = potential_terminating_sequence # steep:ignore
          end
        end
        new_procs
      end

      #: (Array[In | Call | Return] cex) -> void
      def extract_potential_access_and_return_sequences(cex)
        access_sequence = []
        return_sequence = minify_well_matched(cex)

        cex.each_with_index do |input, index|
          access_sequence << input

          if @call_alphabet_set.include?(input) # steep:ignore
            return_index = find_return_index(return_sequence, 1)
            potential_return_sequence = return_sequence[return_index...]
            current_access_sequence = @proc_to_access_sequence[input] # steep:ignore
            current_return_sequence = @proc_to_return_sequence[input] # steep:ignore
            if current_access_sequence.nil? || current_return_sequence.nil? ||
                 (access_sequence.size + potential_return_sequence.size) < # steep:ignore
                   (current_access_sequence.size + current_return_sequence.size) # steep:ignore
              @proc_to_access_sequence[input] = access_sequence.dup # steep:ignore
              @proc_to_return_sequence[input] = potential_return_sequence # steep:ignore
            end
          elsif input == @return_input # steep:ignore
            call_index = find_call_index(access_sequence, access_sequence.size - 1)
            proc = access_sequence[call_index]
            access_sequence.slice!(call_index + 1...access_sequence.size - 1)
            access_sequence.unshift(*@proc_to_terminating_sequence[proc])
          end

          return_sequence.shift

          next unless @call_alphabet_set.include?(input) # steep:ignore

          rs_return_index = find_return_index(return_sequence, 0)
          cex_return_index = find_return_index(cex, index + 1)
          return_sequence.slice!(0...rs_return_index)
          return_sequence.unshift(*minify_well_matched(cex[index + 1...cex_return_index])) # steep:ignore
        end
      end

      #: (Array[In | Call | Return] word) -> Array[In | Call | Return]
      def minify_well_matched(word)
        minified_word = []
        index = 0
        while index < word.size
          input = word[index]
          minified_word << input
          if @call_alphabet_set.include?(input) # steep:ignore
            index = find_return_index(word, index + 1)
            minified_word.concat(@proc_to_terminating_sequence[input]) # steep:ignore
            minified_word << @return_input
          end
          index += 1
        end
        minified_word
      end

      #: (Hash[Call, Array[In | Call | Return]]) -> void
      def optimize_sequences(proc_to_sequence)
        proc_to_sequence.each do |proc, sequence|
          minified_sequence = minify_well_matched(sequence)
          proc_to_sequence[proc] = minified_sequence if minified_sequence.size < sequence.size
        end
      end

      #: [In, Call, Return] (Array[In | Call] word) -> Array[In | Call | Return]
      def expand(word)
        Automaton::ProcUtil.expand(@return_input, word, @proc_to_terminating_sequence)
      end

      #: (Array[In | Call | Return] word, Integer index) -> Integer
      def find_call_index(word, index) # steep:ignore
        Automaton::ProcUtil.find_call_index(@call_alphabet_set, @return_input, word, index)
      end

      #: (Array[In | Call | Return] word, Integer index) -> Integer
      def find_return_index(word, index) # steep:ignore
        Automaton::ProcUtil.find_return_index(@call_alphabet_set, @return_input, word, index)
      end
    end
  end
end
