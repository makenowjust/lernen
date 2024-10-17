# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # SPA represents a system of procedural automata.
    #
    # Note that this class takes `return_input` as the return symbol because
    # this value is necessary to run this kind of automata correctly.
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
        [proc_to_access_sequence, proc_to_terminating_sequence, proc_to_return_sequence]
      end

      # Finds a separating word between `spa1` and `spa2`.
      #
      # This method assume return symbols for two SPAs are the same.
      # If they are not, this raises `ArgumentError`.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    SPA[In, Call, Return] spa1,
      #    SPA[In, Call, Return] spa2
      #  ) -> (Array[In | Call | Return] | nil)
      def self.find_separating_word(alphabet, call_alphabet, spa1, spa2)
        raise ArgumentError, "Cannot find a separating word for different type automata" unless spa2.is_a?(spa1.class)
        unless spa1.return_input == spa2.return_input # steep:ignore
          raise ArgumentError, "Return symbols for two SPAs are different"
        end

        as1, ts1, rs1 = spa1.proc_to_atr_sequence(alphabet, call_alphabet)
        as2, ts2, rs2 = spa2.proc_to_atr_sequence(alphabet, call_alphabet)

        local_alphabet = alphabet.dup
        local_alphabet.concat((ts1.keys.to_set & ts2.keys.to_set).to_a) # steep:ignore

        call_alphabet.each do |proc|
          dfa1 = spa1.proc_to_dfa[proc]
          dfa2 = spa2.proc_to_dfa[proc]
          next if !dfa1 && !dfa2

          a1 = as1[proc]
          t1 = ts1[proc]
          r1 = rs1[proc]

          a2 = as2[proc]
          t2 = ts2[proc]
          r2 = rs2[proc]

          case
          when dfa1 && !dfa2
            return a1 + t1 + r1 if a1 && t1 && r1
            next
          when !dfa1 && dfa2
            return a2 + t2 + r2 if a2 && t2 && r2
            next
          end

          # Then, `dfa1 && dfa2` holds.
          next unless a1 && t1 && r1 && a2 && t2 && r2

          sep_word = DFA.find_separating_word(local_alphabet, dfa1, dfa2)
          next unless sep_word

          as, ts, rs = dfa1.run_last(sep_word) ? [as1, ts1, rs1] : [as2, ts2, rs2]
          sep_word = ProcUtil.expand(spa1.return_input, sep_word, ts)
          return as[proc] + sep_word + rs[proc]
        end

        nil
      end

      # Generates a SPA randomly.
      #
      #: [In, Call, Return] (
      #    alphabet: Array[In],
      #    call_alphabet: Array[Call],
      #    return_input: Return,
      #    ?min_proc_size: Integer,
      #    ?max_proc_size: Integer,
      #    ?dfa_min_state_size: Integer,
      #    ?dfa_max_state_size: Integer,
      #    ?dfa_accept_state_size: Integer,
      #    ?random: Random,
      #  ) -> SPA[In, Call, Return]
      def self.random(
        alphabet:,
        call_alphabet:,
        return_input:,
        min_proc_size: 1,
        max_proc_size: call_alphabet.size,
        dfa_min_state_size: 5,
        dfa_max_state_size: 10,
        dfa_accept_state_size: 2,
        random: Random
      )
        proc_size = random.rand(min_proc_size..max_proc_size)
        procs = call_alphabet.dup.shuffle!(random:)[0...proc_size]

        initial_proc = procs[0] # steep:ignore
        proc_to_dfa = {}
        procs.each do |proc| # steep:ignore
          proc_to_dfa[proc] = DFA.random(
            alphabet: alphabet + procs, # steep:ignore
            random:,
            min_state_size: dfa_min_state_size,
            max_state_size: dfa_max_state_size,
            accept_state_size: dfa_accept_state_size
          )
        end

        new(initial_proc, return_input, proc_to_dfa)
      end

      RE_INITIAL_PROC = /\b__start0\s*->\s*__start0_(?<initial_proc>\w+)/
      RE_RETURN_INPUT = /\A\s*__return\s*\[(?<params>(?:"[^"]*"|[^\]]+)*)\]/
      RE_SUBGRAPH_BEGIN = /\A\s*subgraph\s+cluster_(\w+)\s*\{\s*/
      RE_SUBGRAPH_LABEL = /\A\s*label=(?<content>"[^"]*"|[^\s\],]*)/
      RE_SUBGRAPH_END = /\A\s*\}\s*\z/

      # Constructs an SPA from [Automata Wiki](https://automata.cs.ru.nl)'s DOT source.
      #
      # It returns a tuple with two elements:
      #
      # 1. A `SPA` from the DOT source.
      # 2. A `Hash` mapping from procedure names to state-to-name mappings.
      #
      #: (String source) -> [SPA[String, Symbol, Symbol], Hash[Symbol, Hash[Integer, String]]]
      def self.from_automata_wiki_dot(source) # steep:ignore
        proc_to_dfa = {}
        proc_to_state_to_name = {}
        index_to_proc = {}

        subgraph_source = nil
        subgraph_label = nil
        return_input = nil
        initial_proc = nil

        strip = ->(label) { label[0] == "\"" && label[-1] == "\"" ? label[1...-1] : label }

        source.lines.each do |line|
          line = line.gsub(TransitionSystem::RE_COMMENT, "")

          unless subgraph_source
            match = line.match(RE_INITIAL_PROC)
            if match
              initial_proc = match[:initial_proc]&.to_sym
              next
            end

            match = line.match(RE_RETURN_INPUT)
            if match
              label_match = match[:params]&.match(TransitionSystem::RE_LABEL)
              return_input = strip.call(label_match&.[](:content) || "").to_sym
              next
            end

            match = line.match(RE_SUBGRAPH_BEGIN)
            if match
              subgraph_source = []
              subgraph_label = nil
              next
            end
            next
          end

          match = line.match(RE_SUBGRAPH_LABEL)
          if match
            subgraph_label = strip.call(match[:content]).to_sym
            next
          end

          match = line.match(RE_SUBGRAPH_END)
          if match
            dfa, state_to_name = DFA.from_automata_wiki_dot("digraph{\n#{subgraph_source.join}\n}") # steep:ignore
            proc_to_dfa[subgraph_label] = dfa
            proc_to_state_to_name[subgraph_label] = state_to_name
            index_to_proc[index_to_proc.size] = subgraph_label

            subgraph_source = nil
            subgraph_label = nil
            next
          end

          subgraph_source << line # steep:ignore
        end

        call_alphabet_set = proc_to_dfa.keys.to_set.map(&:to_s)
        proc_to_dfa.transform_values! do |dfa|
          transition_function =
            dfa.transition_function.transform_keys do |(state, input)|
              input = input.to_sym if call_alphabet_set.include?(input)
              [state, input]
            end
          DFA.new(dfa.initial_state, dfa.accept_state_set, transition_function)
        end

        [new(initial_proc, return_input, proc_to_dfa), proc_to_state_to_name]
      end

      # Returns [Automata Wiki](https://automata.cs.ru.nl)'s DOT representation of this DFA.
      #
      #: (?Hash[Call, Hash[Integer, String]] proc_to_state_to_name) -> String
      def to_automata_wiki_dot(proc_to_state_to_name = {})
        nodes = {
          "__start0" => Graph::Node["", :none],
          "__return" => Graph::Node[return_input.to_s, :circle] # steep:ignore
        }

        edges = [Graph::Edge["__start0", nil, "__start0_#{initial_proc}"]]

        subgraphs =
          proc_to_dfa.map do |proc, dfa|
            graph = dfa.to_automata_wiki_dot_graph(proc_to_state_to_name[proc], "_#{proc}")
            Graph::SubGraph[proc.to_s, graph] # steep:ignore
          end

        Graph.new(nodes, edges, subgraphs).to_dot
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
        return {}, {} unless proc_to_dfa[initial_proc]

        proc_to_access_sequence = {}
        proc_to_return_sequence = {}

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
