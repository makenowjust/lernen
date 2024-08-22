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
  end
end
