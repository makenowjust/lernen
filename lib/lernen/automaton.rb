# frozen_string_literal: true

module Lernen
  # DFA is a deterministic finite-state automaton.
  class DFA
    def initialize(initial_state, accept_states, transitions)
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
  class Moore
    def initialize(initial_state, outputs, transitions)
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
  class Mealy
    def initialize(initial_state, transitions)
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
