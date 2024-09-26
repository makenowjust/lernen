# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # VPA represents a [visily pushdown automaton](https://en.wikipedia.org/wiki/Nested_word#Visibly_pushdown_automaton).
    #
    # Especially, this definition represents 1-SEVPA (1-module single-entry visibly pushdown automaton).
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class VPA < MooreLike #[VPA::Conf[Call] | nil, In | Call | Return, bool]
      # Conf is a configuration of VPA run.
      #
      # @rbs skip
      Conf = Data.define(:state, :stack)

      # @rbs!
      #   class Conf[Call] < Data
      #     attr_reader state: Integer
      #     attr_reader stack: Array[[Integer, Call]]
      #     def self.[]: [Call] (Integer state, Array[[Integer, Call]] stack) -> Conf[Call]
      #   end

      # @rbs @initial_state: Integer
      # @rbs @accept_state_set: Set[Integer]
      # @rbs @transition_function: Hash[[Integer, In], Integer]
      # @rbs @return_transition_function: Hash[[Integer, Return], Hash[[Integer, Call], Integer]]

      #: (
      #    Integer initial_state,
      #    Set[Integer] accept_state_set,
      #    Hash[[Integer, In], Integer] transition_function.
      #    Hash[[Integer, Return], Hash[[Integer, Call], Integer]] return_transition_function
      #  ) -> void
      def initialize(initial_state, accept_state_set, transition_function, return_transition_function)
        super()

        @initial_state = initial_state
        @accept_state_set = accept_state_set
        @transition_function = transition_function
        @return_transition_function = return_transition_function
      end

      attr_reader :initial_state #: Integer
      attr_reader :accept_state_set #: Set[Integer]
      attr_reader :transition_function #: Hash[[Integer, In], Integer]
      attr_reader :return_transition_function #: Hash[[Integer, Return], Hash[[Integer, Call], Integer]]

      # @rbs return: :vpa
      def type = :vpa

      # @rbs override
      def initial_conf = Conf[initial_state, []]

      # @rbs override
      def step_conf(conf, input)
        return nil if conf.nil?

        next_state = transition_function[[conf.state, input]] # steep:ignore
        return Conf[next_state, conf.stack] if next_state

        return_transition_guard = return_transition_function[[conf.state, input]] # steep:ignore
        if return_transition_guard
          *next_stack, last_call = conf.stack
          return nil unless last_call
          next_state = return_transition_guard[last_call]
          return Conf[next_state, next_stack]
        end

        # When there is no usual transition and no return tansition for `input`,
        # then we assume that `input` is a call alphabet.
        Conf[initial_state, conf.stack + [[conf.state, input]]] # steep:ignore
      end

      # @rbs override
      def output(conf)
        !conf.nil? && accept_state_set.include?(conf.state) && conf.stack.empty?
      end

      # Checks the structural equality between `self` and `other`.
      #
      #: (untyped other) -> bool
      def ==(other)
        other.is_a?(VPA) && initial_state == other.initial_state && accept_state_set == other.accept_state_set &&
          transition_function == other.transition_function &&
          return_transition_function == other.return_transition_function
      end

      # Returns the array of states of this VPA.
      #
      # The result array is sorted.
      #
      #: () -> Array[Integer]
      def states
        state_set = Set.new
        state_set << initial_state
        accept_state_set.each { |state| state_set << state }
        transition_function.each do |(state, _), next_state|
          state_set << state
          state_set << next_state
        end
        return_transition_function.each do |(state, _), return_transition_guard|
          state_set << state
          return_transition_guard.each do |(call_state, _), next_state|
            state_set << call_state
            state_set << next_state
          end
        end
        state_set.to_a.sort!
      end

      # Returns the error state of this VPA.
      #
      # An error state is:
      #
      # - neither a initial state nor accepting states, and
      # - only having self-loops for all `input`.
      #
      # If an error state is not found, it returns `nil`.
      #
      #: () -> (Integer | nil)
      def error_state
        transition_function
          .group_by { |(state, _), _| state }
          .transform_values { _1.to_h { |(_, input), next_state| [input, next_state] } }
          .each do |state, transition_hash|
            # The initial state and accepting states are not an error state.
            next if state == initial_state || accept_state_set.include?(state)

            # An error state should only have self-loops.
            next unless transition_hash.all? { |_, next_state| state == next_state }
            all_returns_are_self_loops =
              return_transition_function.all? do |_, return_transition_guard|
                return_transition_guard
                  .filter { |(call_state, _), _| call_state == state }
                  .all? { |_, next_state| state == next_state }
              end
            next unless all_returns_are_self_loops

            return state
          end

        nil
      end

      # Returns a graph of this VPA.
      #
      # (?shows_error_state: bool) -> Graph
      def to_graph(shows_error_state: false)
        error_state = error_state() unless shows_error_state

        nodes =
          states
            .filter_map do |state|
              next if state == error_state
              shape = accept_state_set.include?(state) ? :doublecircle : :circle #: Graph::node_shape
              [state, Graph::Node[state.to_s, shape]]
            end
            .to_h

        edges =
          transition_function.filter_map do |(state, input), next_state|
            next if state == error_state || next_state == error_state
            Graph::Edge[state, input.inspect, next_state] # steep:ignore
          end

        edges +=
          return_transition_function.flat_map do |(state, return_input), return_transition_guard|
            next [] if state == error_state
            return_transition_guard.filter_map do |(call_state, call_input), next_state|
              next if call_state == error_state || next_state == error_state
              label = "#{return_input.inspect} / (#{call_state}, #{call_input.inspect})" # steep:ignore
              Graph::Edge[state, label, next_state]
            end
          end

        Graph.new(nodes, edges)
      end

      # Finds a separating word between `vpa1` and `vpa2`.
      #
      #: [In, Call, Return] (
      #    Array[In] alphabet,
      #    Array[Call] call_alphabet,
      #    Array[Return] return_alphabet,
      #    VPA[In, Call, Return] vpa1,
      #    VPA[In, Call, Return] vpa2
      #  ) -> (Array[In | Call | Return] | nil)
      def self.find_separating_word(alphabet, call_alphabet, return_alphabet, vpa1, vpa2)
        raise ArgumentError, "Cannot find a separating word for different type automata" unless vpa2.is_a?(vpa1.class)

        queue = []
        prefix_hash = {}

        initial_pair = [vpa1.initial_conf&.state, vpa2.initial_conf&.state]
        queue << initial_pair
        prefix_hash[initial_pair] = []

        until queue.empty?
          state1, state2 = queue.shift
          prefix = prefix_hash[[state1, state2]]

          alphabet.each do |input|
            output1, next_conf1 = vpa1.step(state1 && Conf[state1, []], input)
            output2, next_conf2 = vpa2.step(state2 && Conf[state2, []], input)

            word = prefix + [input]
            return word if output1 != output2

            next_pair = [next_conf1&.state, next_conf2&.state]
            unless prefix_hash.include?(next_pair)
              queue << next_pair
              prefix_hash[next_pair] = word
            end
          end

          found_state_pairs = prefix_hash.keys
          call_alphabet.each do |call_input|
            return_alphabet.each do |return_input|
              found_state_pairs.each do |(call_state1, call_state2)|
                return_conf1 = state1 && Conf[state1, [[call_state1, call_input]]] # steep:ignore
                return_conf2 = state2 && Conf[state2, [[call_state2, call_input]]] # steep:ignore

                output1, next_conf1 = vpa1.step(return_conf1, return_input)
                output2, next_conf2 = vpa2.step(return_conf2, return_input)

                word = prefix_hash[[call_state1, call_state2]] + [call_input] + prefix + [return_input]
                return word if output1 != output2

                next_pair = [next_conf1&.state, next_conf2&.state]
                unless prefix_hash.include?(next_pair)
                  queue << next_pair
                  prefix_hash[next_pair] = word
                end
              end
            end
          end
        end

        nil
      end

      # Generates a VPA randomly.
      #
      #: [In, Call, Return] (
      #    alphabet: Array[In],
      #    call_alphabet: Array[Call],
      #    return_alphabet: Array[Return],
      #    ?min_state_size: Integer,
      #    ?max_state_size: Integer,
      #    ?accept_state_size: Integer,
      #    ?random: Random,
      #  ) -> VPA[In, Call, Return]
      def self.random(
        alphabet:,
        call_alphabet:,
        return_alphabet:,
        min_state_size: 5,
        max_state_size: 10,
        accept_state_size: 2,
        random: Random
      )
        transition_function, reachable_paths =
          TransitionSystem.random_transition_function(
            alphabet:,
            min_state_size:,
            max_state_size:,
            num_reachable_paths: accept_state_size,
            random:
          )
        accept_state_set = reachable_paths.to_set(&:last) #: Set[Integer]

        state_set = Set.new
        transition_function.each do |(state, _), next_state|
          state_set << state
          state_set << next_state
        end
        states = state_set.to_a
        states.sort!

        return_transition_function = {}
        states.each do |return_state|
          return_alphabet.each do |return_input|
            return_transition_guard = return_transition_function[[return_state, return_input]] = {}
            states.each do |call_state|
              call_alphabet.each do |call_input|
                next_state = states.sample(random:)
                return_transition_guard[[call_state, call_input]] = next_state
              end
            end
          end
        end

        new(0, accept_state_set, transition_function, return_transition_function)
      end
    end
  end
end
