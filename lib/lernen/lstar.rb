# frozen_string_literal: true

module Lernen
  # ObservationTable is an observation table implementation.
  class ObservationTable
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

    attr_reader :prefixes, :suffixes

    # Finds new prefixes to close.
    def find_prefixes_to_close
      prefixes_to_close = []
      unclosed_rows = Set.new

      prefix_rows = @prefixes.to_set { @table[_1] }

      extended_prefixes = @prefixes.flat_map { |q| @alphabet.map { |a| q + [a] } }
      extended_prefixes.each do |qa|
        row = @table[qa]
        unless prefix_rows.include?(row) || unclosed_rows.include?(row)
          prefixes_to_close << qa
          unclosed_rows << row
        end
      end

      return if prefixes_to_close.empty?

      prefixes_to_close.sort_by!(&:size).reverse!
    end

    # Checks consistency and returns a new suffix to add if this observation table
    # is inconsistent.
    def check_consistency
      @prefixes.combination(2) do |(q1, q2)|
        next unless @table[q1] == @table[q2]

        @alphabet.each do |a|
          q1a = q1 + [a]
          q2a = q2 + [a]
          next if @table[q1a] == @table[q2a]

          @suffixes.each_with_index do |e, i|
            next if @table[q1a][i] == @table[q2a][i]

            return [a] + e
          end
        end
      end

      nil
    end

    # Update observation table entries.
    def update_table
      extended_prefixes = @prefixes.flat_map { |q| [q] + @alphabet.map { |a| q + [a] } }

      extended_prefixes.each do |qa|
        @table[qa] ||= []
        next if @table[qa].size == @suffixes.size
        @suffixes.each_with_index do |e, i|
          next if i < @table[qa].size
          inputs = qa + e
          outputs = inputs.empty? ? [@sul.query_empty] : @sul.query(inputs)
          @table[qa] += [outputs.last]
        end
      end
    end

    # Constructs a hypothesis automaton from this observation table.
    def to_hypothesis
      state_to_prefix = @prefixes.each_with_index.to_h { |q, i| [i, q] }
      row_to_state = @prefixes.each_with_index.to_h { |q, i| [@table[q], i] }

      transitions = {}
      @prefixes.each_with_index do |q, i|
        @alphabet.each_with_index do |a, j|
          case @automaton_type
          in :moore | :dfa
            transitions[[i, a]] = row_to_state[@table[q + [a]]]
          in :mealy
            transitions[[i, a]] = [@table[q][j], row_to_state[@table[q + [a]]]]
          end
        end
      end

      automaton =
        case @automaton_type
        in :dfa
          accept_states = state_to_prefix.to_a.filter { |(_i, q)| @table[q][0] }.to_set { |(i, _q)| i }
          DFA.new(0, accept_states, transitions)
        in :moore
          outputs = state_to_prefix.transform_values { |q| @table[q][0] }
          Moore.new(0, outputs, transitions)
        in :mealy
          Mealy.new(0, transitions)
        end

      [automaton, state_to_prefix]
    end
  end

  # LStar is an implementation of Angluin's L* algorithm.
  module LStar
    # Runs Angluin's L* algoritghm and returns an inferred automaton.
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

        hypothesis, state_to_prefix = observation_table.to_hypothesis
        cex = oracle.find_cex(hypothesis)
        break if cex.nil?

        if cex_processing.nil?
          all_prefixes = (0..cex.size).map { |n| cex[0...n] }
          all_prefixes.each do |prefix|
            observation_table.prefixes << prefix unless observation_table.prefixes.include?(prefix)
          end
        else
          new_prefix, new_suffix = CexProcessor.process(sul, hypothesis, cex, state_to_prefix, cex_processing:)
          observation_table.prefixes << new_prefix unless observation_table.prefixes.include?(new_prefix)
          observation_table.suffixes << new_suffix unless observation_table.suffixes.include?(new_suffix)
        end
        observation_table.update_table
      end

      hypothesis, = observation_table.to_hypothesis
      hypothesis
    end
  end
end
