# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # LStar is an implementation of Angluin's L* algorithm.
    #
    # Angluin's L* is introduced by [Angluin (1987) "Learning Regular Sets from
    # Queries and Counterexamples"](https://dl.acm.org/doi/10.1016/0890-5401%2887%2990052-6).
    module LStar
      # Runs Angluin's L* algoritghm and returns an inferred automaton.
      #
      # `cex_processing` is used for determining a method of counterexample processing.
      # In additional to predefined `cex_processing_method`, we can specify `nil` as `cex_processing`.
      # When `cex_processing: nil` is specified, it uses the original counterexample processing
      # described in the Angluin paper.
      #
      # `max_learning_rounds` is a parameter for specifying the maximum number of iterations for learning.
      # When `max_learning_rounds: nil` is specified, it means the algorithm only stops if the equivalent
      # hypothesis is found.
      #
      #: [In] (
      #    Array[In] alphabet, System::SUL[In, bool] sul, Equiv::Oracle[In, bool] oracle,
      #    automaton_type: :dfa,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::DFA[In]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :mealy,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Mealy[In, Out]
      #: [In, Out] (
      #    Array[In] alphabet, System::SUL[In, Out] sul, Equiv::Oracle[In, Out] oracle,
      #    automaton_type: :moore,
      #    ?cex_processing: cex_processing_method | nil, ?max_learning_rounds: Integer | nil
      #  ) -> Automaton::Moore[In, Out]
      def self.learn(alphabet, sul, oracle, automaton_type:, cex_processing: :binary, max_learning_rounds: nil)
        observation_table = ObservationTable.new(alphabet, sul, automaton_type:)
        learning_rounds = 0

        loop do
          break if max_learning_rounds && learning_rounds == max_learning_rounds
          learning_rounds += 1

          if cex_processing.nil?
            new_suffix = observation_table.check_consistency
            until new_suffix.nil?
              observation_table.suffixes << new_suffix
              observation_table.update_table
              new_suffix = observation_table.check_consistency
            end
          end

          new_prefixes = observation_table.find_prefixes_to_close
          until new_prefixes.nil?
            observation_table.prefixes.push(*new_prefixes)
            observation_table.update_table
            new_prefixes = observation_table.find_prefixes_to_close
          end

          hypothesis, state_to_prefix = observation_table.build_hypothesis
          cex = oracle.find_cex(hypothesis) # steep:ignore
          break if cex.nil?

          if cex_processing.nil?
            cex_prefixes = (0..cex.size).map { |n| cex[0...n] }
            cex_prefixes.each do |prefix|
              observation_table.prefixes << prefix unless observation_table.prefixes.include?(prefix) # steep:ignore
            end
          else
            old_prefix, new_input, new_suffix =
              CexProcessor.process(sul, hypothesis, cex, state_to_prefix, cex_processing:)
            _, old_state = hypothesis.run(old_prefix)
            new_prefix = state_to_prefix[old_state] + [new_input]
            observation_table.prefixes << new_prefix unless observation_table.prefixes.include?(new_prefix)
            observation_table.suffixes << new_suffix unless observation_table.suffixes.include?(new_suffix)
          end
          observation_table.update_table
        end

        hypothesis, = observation_table.build_hypothesis
        hypothesis
      end
    end
  end
end
