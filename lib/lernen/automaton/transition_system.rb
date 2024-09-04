# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # TransitionSystem represents a labelled transition system.
    #
    # We assume that this transition system is *deterministic* and *complete*;
    # thus, the transition function should be defined for all states and input
    # characters, and the destination configuration of a transition should be one.
    #
    # Also, this transition system has an output value for each transition. From
    # this point of view, this definition is much like Mealy machines. However,
    # this class is more generic. Actually, this is a superclass of Moore machines,
    # DFA, etc.
    #
    # Note that this class is *abstract*. We should implement the following method:
    #
    # - `#type`
    # - `#initial_conf`
    # - `#step(conf, input)`
    #
    # @rbs generic Conf -- Type for a configuration of this automaton
    # @rbs generic In   -- Type for input alphabet
    # @rbs generic Out  -- Type for output values
    class TransitionSystem
      # rubocop:disable Lint/UnusedMethodArgument

      # Returns the automaton type.
      #
      # This is an abstract method.
      #
      #: () -> transition_system_type
      def type
        raise TypeError, "abstract method: `type`"
      end

      # Returns the initial configuration.
      #
      # This is an abstract method.
      #
      #: () -> Conf
      def initial_conf
        raise TypeError, "abstract method: `initial_conf`"
      end

      # Runs a transition from the given configuration with the given input.
      #
      # It returns a pair of the output value and the next configuration of
      # this transition.
      #
      # This is an abstract method.
      #
      #: (Conf conf, In input) -> [Out, Conf]
      def step(conf, input)
        raise TypeError, "abstract method: `step`"
      end

      # rubocop:enable Lint/UnusedMethodArgument

      # Runs transitions from the initial configuration with the given word.
      #
      # It returns a pair of the output values and the final configuration of
      # the transitions.
      #
      #: (Array[In] word) -> [Array[Out], Conf]
      def run(word)
        conf = initial_conf
        outputs = []
        word.each do |input|
          output, conf = step(conf, input)
          outputs << output
        end
        [outputs, conf]
      end

      # Finds a separating word between `automaton1` and `automaton2`.
      #
      #: [Conf, In, Out] (
      #    Array[In] alphabet,
      #    TransitionSystem[Conf, In, Out] automaton1,
      #    TransitionSystem[Conf, In, Out] automaton2
      #  ) -> (Array[In] | nil)
      def self.find_separating_word(alphabet, automaton1, automaton2)
        unless automaton2.is_a?(automaton1.class)
          raise ArgumentError, "Cannot find a separating word for different type automata"
        end
        queue = []
        prefix_hash = {}

        initial_pair = [automaton1.initial_conf, automaton2.initial_conf]
        queue << initial_pair
        prefix_hash[initial_pair] = []

        until queue.empty?
          conf1, conf2 = queue.shift
          prefix = prefix_hash[[conf1, conf2]]

          alphabet.each do |input|
            word = prefix + [input]

            output1, next_conf1 = automaton1.step(conf1, input)
            output2, next_conf2 = automaton2.step(conf2, input)

            return word if output1 != output2 # steep:ignore

            next_pair = [next_conf1, next_conf2]
            unless prefix_hash.include?(next_pair)
              queue << next_pair
              prefix_hash[next_pair] = word
            end
          end
        end

        nil
      end

      # Generates a transition function randomly.
      #
      # To make a transition function connected, this method generates
      # a transition function in the following mannar.
      #
      # 1. Decide a number of states within `min_state_size..max_state_size` randomly.
      # 2. Divides the states into `num_reachable_paths` partitions.
      # 3. Generate a path from the initial state for each paratition.
      # 4. Generate transition for all `state` and `input`.
      #
      # This method returns a pair of a transition function and an array of reachable paths.
      # The initial state of the result transition function is `0`.
      #
      #: [In] (
      #    alphabet: Array[In],
      #    ?min_state_size: Integer,
      #    ?max_state_size: Integer,
      #    ?num_reachable_paths: Integer,
      #    ?random: Random,
      #  ) -> [Hash[[Integer, In], Integer], Array[Array[Integer]]]
      def self.random_transition_function(
        alphabet:,
        min_state_size: 5,
        max_state_size: 10,
        num_reachable_paths: 2,
        random: Random
      )
        state_size = random.rand(min_state_size..max_state_size)
        num_reachable_paths = [num_reachable_paths, alphabet.size, state_size].min #: Integer

        initial_state = 0
        reachable_paths = []
        transition_function = {}

        partitions = (0...state_size).to_a + ([nil] * (num_reachable_paths - 1))
        partitions.shuffle!(random:)
        partitions.push(nil)

        initial_alphabet = alphabet.dup
        initial_alphabet.shuffle!(random:)

        until partitions.empty?
          reachable_path = [initial_state]
          state = initial_state
          input = initial_alphabet.shift
          loop do
            next_state = partitions.shift
            break if next_state.nil?
            next if next_state == initial_state

            reachable_path << next_state

            transition_function[[state, input]] = next_state

            input = alphabet.sample(random:)
          end
          reachable_paths << reachable_path
        end

        state_size.times do |state|
          alphabet.each do |input|
            next if transition_function[[state, input]]
            next_state = random.rand(state_size)
            transition_function[[state, input]] = next_state
          end
        end

        [transition_function, reachable_paths]
      end
    end
  end
end