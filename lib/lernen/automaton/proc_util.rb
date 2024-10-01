# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # ProcUtil provides utility functions for words in `SPA`.
    module ProcUtil
      #: [In, Call, Return] (
      #    Return return_input,
      #    Array[In | Call] word,
      #    Hash[Call, Array[In | Call | Return]] proc_to_terminating_sequence,
      #  ) -> Array[In | Call | Return]
      def self.expand(return_input, word, proc_to_terminating_sequence)
        expanded_word = []
        word.each do |input|
          terminating_sequence = proc_to_terminating_sequence[input] # steep:ignore
          if terminating_sequence
            expanded_word << input
            expanded_word.concat(terminating_sequence)
            expanded_word << return_input
          else
            expanded_word << input
          end
        end
        expanded_word
      end

      #: [In, Call, Return] (
      #    Set[Call] call_alphabet_set,
      #    Return return_input,
      #    Array[In | Call | Return] word
      #  ) -> Array[In | Call]
      def self.project(call_alphabet_set, return_input, word)
        projected_word = []
        index = 0
        while index < word.size
          input = word[index]
          projected_word << input
          if call_alphabet_set.include?(input) # steep:ignore
            return_index = find_return_index(call_alphabet_set, return_input, word, index + 1)
            index = return_index if return_index
          end
          index += 1
        end
        projected_word
      end

      #: [In, Call, Return] (
      #    Set[Call] call_alphabet_set,
      #    Return return_input,
      #    Array[In | Call | Return] word,
      #    Integer index
      #  ) -> (Integer | nil)
      def self.find_call_index(call_alphabet_set, return_input, word, index)
        balance = 0

        (index - 1).downto(0) do |i|
          input = word[i]
          if input == return_input # steep:ignore
            balance += 1
          elsif call_alphabet_set.include?(input) # steep:ignore
            return i if balance == 0
            balance -= 1
          end
        end

        nil
      end

      #: [In, Call, Return] (
      #    Set[Call] call_alphabet_set,
      #    Return return_input,
      #    Array[In | Call | Return] word,
      #    Integer index
      #  ) -> (Integer | nil)
      def self.find_return_index(call_alphabet_set, return_input, word, index)
        balance = 0

        (index...word.size).each do |i|
          input = word[i]
          if call_alphabet_set.include?(input) # steep:ignore
            balance += 1
          elsif input == return_input # steep:ignore
            return i if balance == 0
            balance -= 1
          end
        end

        nil
      end
    end
  end
end
