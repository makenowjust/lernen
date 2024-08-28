# frozen_string_literal: true

module Lernen
  # Automaton is an abstract class for automata.
  #
  # Note that this class is *abstract*. You should implement the following method:
  #
  # - `#step(state, input)`
  class Automaton
    # Computes a transition for the given `input` from the current `state`.
    #
    # This is *abstract*.
    def step(_state, _input)
      raise TypeError, "abstract method: `step`"
    end

    # Runs this automaton with the given input string and returns an output sequence
    # and a state after running.
    def run(inputs)
      state = @initial_state
      outputs = []
      inputs.each do |input|
        output, state = step(state, input)
        outputs << output
      end
      [outputs, state]
    end

    # Checks equivalence between `self` and `other` on the given `alphabet`.
    #
    # It returns `nil` if they are equivalence, or it returns a counterexample string.
    def check_equivalence(alphabet, other)
      raise ArgumentError, "Cannot check equivalence between different automata" unless instance_of?(other.class)

      case self
      when DFA
        return [] unless accept_states.include?(initial_state) == other.accept_states.include?(other.initial_state)
      when Moore
        return [] unless outputs[initial_state] == other.outputs[other.initial_state]
      end

      queue = []
      visited = Set.new
      queue << [[], initial_state, other.initial_state]
      visited << [initial_state, other.initial_state]
      until queue.empty?
        path, self_state, other_state = queue.shift
        alphabet.each do |input|
          self_output, self_next_state = step(self_state, input)
          other_output, other_next_state = other.step(other_state, input)
          return path + [input] if self_output != other_output
          next_pair = [self_next_state, other_next_state]
          unless visited.include?(next_pair)
            queue << [path + [input], *next_pair]
            visited << next_pair
          end
        end
      end

      nil
    end
  end

  # DFA is a deterministic finite-state automaton.
  class DFA < Automaton
    def initialize(initial_state, accept_states, transitions)
      super()

      @initial_state = initial_state
      @accept_states = accept_states
      @transitions = transitions
    end

    attr_reader :initial_state, :accept_states, :transitions

    # Computes a transition for the given `input` from the current `state`.
    def step(state, input)
      next_state = @transitions[[state, input]]
      output = @accept_states.include?(next_state)
      [output, next_state]
    end

    # Checks equality.
    def ==(other)
      initial_state == other.initial_state && accept_states == other.accept_states && transitions == other.transitions
    end

    # Returns a mermaid diagram.
    def to_mermaid
      mmd = +""

      mmd << "flowchart TD\n"

      states = [initial_state] + accept_states.to_a + transitions.keys.map { |(q, _)| q } + transitions.values
      states.uniq!

      states.sort.each { |q| mmd << (accept_states.include?(q) ? "  #{q}(((#{q})))\n" : "  #{q}((#{q}))\n") }
      mmd << "\n"

      transitions.each { |(q1, i), q2| mmd << "  #{q1} -- #{i} --> #{q2}\n" }

      mmd.dup
    end

    # Returns a random DFA.
    #
    # The result DFA is complete, and all states in the result DFA are reachable
    # to some accepting states or the sink state. However, the result DFA may be
    # non-minimal.
    def self.random(
      alphabet:,
      max_state_size:,
      max_accept_state_ratio: 0.5,
      min_state_size: 1,
      sink_state_prob: 0.4,
      random: Random
    )
      state_size = random.rand(min_state_size..max_state_size)
      accept_state_ratio = [max_accept_state_ratio * random.rand, 0.01].max
      accept_state_size = [state_size, (state_size * accept_state_ratio).ceil].min

      initial_state = 0
      non_accepting_states = (0...state_size).to_a
      non_accepting_states.shuffle!(random:)
      accept_states = non_accepting_states.pop(accept_state_size).to_set

      sink_state = random.rand < sink_state_prob ? non_accepting_states.pop : nil

      transitions = {}
      accept_states.each_with_index do |accept_state, i|
        next if accept_state == initial_state
        n = i + 1 == accept_state_size ? non_accepting_states.size : random.rand(non_accepting_states.size)
        state = initial_state
        non_accepting_states
          .pop(n)
          .each do |next_state|
            next if next_state == initial_state
            input = alphabet.sample(random:)
            transitions[[state, input]] = next_state
            state = next_state
          end
        input = alphabet.sample(random:)
        transitions[[state, input]] = accept_state
      end

      state_size.times do |state|
        alphabet.each do |input|
          next if transitions[[state, input]]
          next_state = state == sink_state ? sink_state : random.rand(state_size)
          transitions[[state, input]] = next_state
        end
      end

      new(initial_state, accept_states, transitions)
    end
  end

  # Moore is a deterministic Moore machine.
  class Moore < Automaton
    def initialize(initial_state, outputs, transitions)
      super()

      @initial_state = initial_state
      @outputs = outputs
      @transitions = transitions
    end

    attr_reader :initial_state, :outputs, :transitions

    # Computes a transition for the given `input` from the current `state`.
    def step(state, input)
      next_state = @transitions[[state, input]]
      output = @outputs[next_state]
      [output, next_state]
    end

    # Checks equality.
    def ==(other)
      initial_state == other.initial_state && outputs == other.outputs && transitions == other.transitions
    end

    # Returns a mermaid diagram.
    def to_mermaid
      mmd = +""

      mmd << "flowchart TD\n"

      states = [initial_state] + transitions.keys.map { |(q, _)| q } + transitions.values
      states.uniq!

      states.sort.each { |q| mmd << "  #{q}((\"#{q}|#{outputs[q]}\"))\n" }
      mmd << "\n"

      transitions.each { |(q1, i), q2| mmd << "  #{q1} -- #{i} --> #{q2}\n" }

      mmd.dup
    end
  end

  # Mealy is a deterministic Mealy machine.
  class Mealy < Automaton
    def initialize(initial_state, transitions)
      super()

      @initial_state = initial_state
      @transitions = transitions
    end

    attr_reader :initial_state, :transitions

    # Computes a transition for the given `input` from the current `state`.
    def step(state, input)
      @transitions[[state, input]]
    end

    # Checks equality.
    def ==(other)
      initial_state == other.initial_state && transitions == other.transitions
    end

    # Returns a mermaid diagram.
    def to_mermaid
      mmd = +""

      mmd << "flowchart TD\n"

      states = [initial_state] + transitions.keys.map { |(q, _)| q } + transitions.values.map { |(_, q)| q }
      states.uniq!

      states.sort.each { |q| mmd << "  #{q}((#{q}))\n" }
      mmd << "\n"

      transitions.each { |(q1, i), (o, q2)| mmd << "  #{q1} -- \"#{i}|#{o}\" --> #{q2}\n" }

      mmd.dup
    end
  end
end
