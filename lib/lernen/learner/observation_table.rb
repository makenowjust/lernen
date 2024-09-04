# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # ObservationTable is an implementation of observation tabel data structure.
    #
    # This data structure is used for Angluin's L* algorithm.
    #
    # @rbs generic In  -- Type for input alphabet
    # @rbs generic Out -- Type for output values
    class ObservationTable
      # @rbs @alphabet: Array[In]
      # @rbs @sul: System::SUL[In, Out]
      # @rbs @automaton_type: Automaton::transition_system_type
      # @rbs @prefixes: Array[Array[In]]
      # @rbs @suffixes: Array[Array[In]]
      # @rbs @table: Hash[Array[In], Array[Out]]

      #: (
      #    Array[In] alphabet,
      #    System::SUL[In, Out] sul,
      #    automaton_type: :dfa | :moore | :mealy
      #  ) -> void
      def initialize(alphabet, sul, automaton_type:)
        @alphabet = alphabet
        @sul = sul
        @automaton_type = automaton_type

        @prefixes = [[]]
        @suffixes = []
        @table = {}

        case @automaton_type
        in :dfa | :moore
          @suffixes << []
        in :mealy
          @alphabet.each { |a| @suffixes << [a] }
        end

        update_table
      end

      attr_reader :prefixes #: Array[Array[In]]
      attr_reader :suffixes #: Array[Array[In]]

      # Finds new prefixes to close.
      #
      #: () -> (Array[Array[In]] | nil)
      def find_prefixes_to_close
        prefixes_to_close = []
        unclosed_row_set = Set.new

        prefix_row_set = @prefixes.to_set { |prefix| @table[prefix] }

        @prefixes.each do |prefix|
          @alphabet.each do |input|
            new_prefix = prefix + [input]
            row = @table[new_prefix]
            unless prefix_row_set.include?(row) || unclosed_row_set.include?(row)
              prefixes_to_close << new_prefix
              unclosed_row_set << row
            end
          end
        end

        return if prefixes_to_close.empty?

        prefixes_to_close.sort_by!(&:size).reverse!
      end

      # Checks consistency and returns a new suffix to add if this observation table
      # is inconsistent.
      #
      #: () -> (Array[In] | nil)
      def check_consistency
        @prefixes.combination(2) do |(prefix1, prefix2)|
          next unless @table[prefix1] == @table[prefix2] # steep:ignore

          @alphabet.each do |input|
            new_prefix1 = prefix1 + [input] # steep:ignore
            new_prefix2 = prefix2 + [input] # steep:ignore
            next if @table[new_prefix1] == @table[new_prefix2]

            @suffixes.each_with_index do |suffix, index|
              next if @table[new_prefix1][index] == @table[new_prefix2][index] # steep:ignore

              return [input] + suffix
            end
          end
        end

        nil
      end

      # Update rows of this observation table.
      #
      #: () -> void
      def update_table
        @prefixes.each do |prefix|
          update_table_row(prefix)

          @alphabet.each { |input| update_table_row(prefix + [input]) }
        end
      end

      # Update the row for the given `prefix` of this observation table.
      #
      #: (Array[In] prefix) -> void
      def update_table_row(prefix)
        @table[prefix] ||= []
        return if @table[prefix].size == @suffixes.size

        @suffixes[@table[prefix].size..].each do |suffix| # steep:ignore
          word = prefix + suffix
          output = word.empty? && (sul = @sul).is_a?(System::MooreLikeSUL) ? sul.query_empty : @sul.query(word).last
          @table[prefix] << output # steep:ignore
        end
      end

      # Constructs a hypothesis automaton from this observation table.
      #
      #: () -> [Automaton::TransitionSystem[Integer, In, Out], Hash[Integer, Array[In]]]
      def build_hypothesis
        state_to_prefix = @prefixes.each_with_index.to_h { |prefix, state| [state, prefix] }
        row_to_state = @prefixes.each_with_index.to_h { |prefix, state| [@table[prefix], state] }

        transition_function = {}
        @prefixes.each_with_index do |prefix, state|
          @alphabet.each_with_index do |input, index|
            case @automaton_type
            in :moore | :dfa
              transition_function[[state, input]] = row_to_state[@table[prefix + [input]]]
            in :mealy
              transition_function[[state, input]] = [@table[prefix][index], row_to_state[@table[prefix + [input]]]]
            end
          end
        end

        automaton =
          case @automaton_type
          in :dfa
            accept_state_set =
              state_to_prefix.to_a.filter { |(_, prefix)| @table[prefix][0] }.to_set { |(state, _)| state }
            Automaton::DFA.new(0, accept_state_set, transition_function)
          in :moore
            outputs = state_to_prefix.transform_values { |prefix| @table[prefix][0] }
            Automaton::Moore.new(0, outputs, transition_function)
          in :mealy
            Automaton::Mealy.new(0, transition_function)
          end

        [automaton, state_to_prefix]
      end
    end
  end
end
