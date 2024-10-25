# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    module LStarVPA
      # ObservationTableVPA is an implementation of observation tabel data structure for VPA.
      #
      # @rbs generic In     -- Type for input alphabet
      # @rbs generic Call   -- Type for call alphabet
      # @rbs generic Return -- Type for return alphabet
      class ObservationTableVPA
        # @rbs @alphabet: Array[In]
        # @rbs @call_alphabet: Array[Call]
        # @rbs @return_alphabet: Array[Return]
        # @rbs @sul: System::SUL[In | Call | Return, bool]
        # @rbs @cex_processing: cex_processing_method
        # @rbs @prefixes: Array[Array[In | Call | Return]]
        # @rbs @separators: Array[[Array[In | Call | Return], Array[In | Call | Return]]]
        # @rbs @table: Hash[Array[In | Call | Return], Array[bool]]

        #: (
        #    Array[In] alphabet, Array[Call] call_alphabet, Array[Return] return_alphabet,
        #    System::SUL[In | Call | Return, bool] sul,
        #    cex_processing: cex_processing_method
        #  ) -> void
        def initialize(alphabet, call_alphabet, return_alphabet, sul, cex_processing:)
          @alphabet = alphabet
          @call_alphabet = call_alphabet
          @return_alphabet = return_alphabet
          @sul = sul
          @cex_processing = cex_processing

          @prefixes = [[]]
          @separators = [[[], []]]
          @table = {}
        end

        # Constructs a hypothesis automaton from this observation table.
        #
        #: () -> [Automaton::VPA[In, Call, Return], Hash[Integer, Array[In | Call | Return]]]
        def build_hypothesis
          make_consistent_and_closed

          state_to_prefix = @prefixes.each_with_index.to_h { |prefix, state| [state, prefix] }
          row_to_state = @prefixes.each_with_index.to_h { |prefix, state| [@table[prefix], state] }

          transition_function = {}
          @prefixes.each_with_index do |prefix, state|
            @alphabet.each { |input| transition_function[[state, input]] = row_to_state[@table[prefix + [input]]] }
          end

          return_transition_function = {}
          @prefixes.each_with_index do |prefix, state|
            @return_alphabet.each do |return_input|
              return_transition_guard = return_transition_function[[state, return_input]] = {}
              @prefixes.each_with_index do |call_prefix, call_state|
                @call_alphabet.each do |call_input|
                  word = call_prefix + [call_input] + prefix + [return_input]
                  return_transition_guard[[call_state, call_input]] = row_to_state[@table[word]]
                end
              end
            end
          end

          accept_state_set =
            state_to_prefix.to_a.filter { |(_, prefix)| @table[prefix][0] }.to_set { |(state, _)| state }
          automaton = Automaton::VPA.new(0, accept_state_set, transition_function, return_transition_function)

          [automaton, state_to_prefix]
        end

        # Updates this observation table by the given `cex`.
        #
        #: (
        #    Array[In | Call | Return] cex,
        #    Automaton::VPA[In, Call, Return] hypothesis,
        #    Hash[Integer, Array[In | Call | Return]] state_to_prefix
        #  ) -> void
        def refine_hypothesis(cex, hypothesis, state_to_prefix)
          conf_to_prefix = ->(conf) do
            prefix = []

            conf.stack.each do |state, call_input|
              prefix.concat(state_to_prefix[state])
              prefix << call_input
            end
            prefix.concat(state_to_prefix[conf.state])

            prefix
          end

          acex = CexProcessor::PrefixTransformerAcex.new(cex, @sul, hypothesis, conf_to_prefix)
          n = CexProcessor.process(acex, cex_processing: @cex_processing)
          old_prefix = cex[0...n]
          new_input = cex[n]
          new_suffix = cex[n + 1...]

          old_conf = hypothesis.run_conf(old_prefix) # steep:ignore
          _, replace_conf = hypothesis.step(old_conf, new_input)

          new_access_conf = Automaton::VPA::Conf[hypothesis.initial_state, replace_conf.stack] # steep:ignore
          new_access = conf_to_prefix.call(new_access_conf)

          old_state_prefix = state_to_prefix[old_conf.state] # steep:ignore
          if @alphabet.include?(new_input) # steep:ignore
            new_prefix = old_state_prefix + [new_input]
          else
            call_state, call_input = old_conf.stack.last # steep:ignore
            call_prefix = state_to_prefix[call_state]
            new_prefix = call_prefix + [call_input] + old_state_prefix + [new_input]
          end

          @prefixes << new_prefix unless @prefixes.include?(new_prefix)
          @separators << [new_access, new_suffix] unless @separators.include?([new_access, new_suffix]) # steep:ignore
        end

        private

        # Finds new prefixes to close.
        #
        #: () -> (Array[Array[In | Call | Return]] | nil)
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

            @prefixes.each do |call_prefix|
              @call_alphabet.each do |call_input|
                @return_alphabet.each do |return_input|
                  new_prefix = call_prefix + [call_input] + prefix + [return_input]
                  row = @table[new_prefix]
                  unless prefix_row_set.include?(row) || unclosed_row_set.include?(row)
                    prefixes_to_close << new_prefix
                    unclosed_row_set << row
                  end
                end
              end
            end
          end

          return if prefixes_to_close.empty?

          prefixes_to_close.sort_by!(&:size).reverse!
        end

        # Updates rows of this observation table.
        #
        #: () -> void
        def update_table
          @prefixes.each do |prefix|
            update_table_row(prefix)

            @alphabet.each { |input| update_table_row(prefix + [input]) }

            @prefixes.each do |call_prefix|
              @call_alphabet.each do |call_input|
                @return_alphabet.each do |return_input|
                  update_table_row(call_prefix + [call_input] + prefix + [return_input])
                end
              end
            end
          end
        end

        # Updates the row for the given `prefix` of this observation table.
        #
        #: (Array[In | Call | Return] prefix) -> void
        def update_table_row(prefix)
          @table[prefix] ||= []
          return if @table[prefix].size == @separators.size

          @separators[@table[prefix].size..].each do |(access, suffix)| # steep:ignore
            word = access + prefix + suffix
            output = @sul.query_last(word)
            @table[prefix] << output
          end
        end

        # Update this table to be consistent and closed.
        #
        #: () -> void
        def make_consistent_and_closed
          update_table

          new_prefixes = find_prefixes_to_close
          until new_prefixes.nil?
            @prefixes.push(*new_prefixes)
            update_table
            new_prefixes = find_prefixes_to_close
          end
        end
      end
    end
  end
end
