# frozen_string_literal: true

module Lernen
  # Automaton is an abstract class for automata.
  #
  # Note that this class is *abstract*. You should implement the following method:
  #
  # - `#type`
  # - `#initial`
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
      state = initial
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
      queue << [[], initial, other.initial]
      visited << [initial, other.initial]
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
    alias initial initial_state

    # Returns the type of this automaton.
    def type
      :dfa
    end

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

      transitions.each { |(q1, i), q2| mmd << "  #{q1} -- \"'#{i}'\" --> #{q2}\n" }

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
    alias initial initial_state

    # Returns the type of this automaton.
    def type
      :moore
    end

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

      states.sort.each { |q| mmd << "  #{q}((\"#{q}|'#{outputs[q]}'\"))\n" }
      mmd << "\n"

      transitions.each { |(q1, i), q2| mmd << "  #{q1} -- \"'#{i}'\" --> #{q2}\n" }

      mmd.dup
    end

    # Returns a random Moore machine.
    def self.random(
      alphabet:,
      output_alphabet:,
      max_state_size:,
      max_arc_ratio: 0.5,
      min_state_size: 1,
      sink_state_prob: 0.4,
      random: Random
    )
      state_size = random.rand(min_state_size..max_state_size)
      arc_ratio = [max_arc_ratio * random.rand, 0.01].max
      arc_state_size = [state_size, (state_size * arc_ratio).ceil].min

      initial_state = 0
      non_arc_states = (0...state_size).to_a
      non_arc_states.shuffle!(random:)
      arc_states = non_arc_states.pop(arc_state_size).to_set

      sink_state = random.rand < sink_state_prob ? non_arc_states.pop : nil

      transitions = {}
      arc_states.each_with_index do |arc_state, i|
        next if arc_state == initial_state
        n = i + 1 == arc_state_size ? non_arc_states.size : random.rand(non_arc_states.size)
        state = initial_state
        non_arc_states
          .pop(n)
          .each do |next_state|
            next if next_state == initial_state
            input = alphabet.sample(random:)
            transitions[[state, input]] = next_state
            state = next_state
          end
        input = alphabet.sample(random:)
        transitions[[state, input]] = arc_state
      end

      outputs = {}
      state_size.times do |state|
        outputs[state] = output_alphabet.sample(random:)
        alphabet.each do |input|
          next if transitions[[state, input]]
          next_state = state == sink_state ? sink_state : random.rand(state_size)
          transitions[[state, input]] = next_state
        end
      end

      new(initial_state, outputs, transitions)
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
    alias initial initial_state

    # Returns the type of this automaton.
    def type
      :mealy
    end

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

      transitions.each { |(q1, i), (o, q2)| mmd << "  #{q1} -- \"'#{i}'|'#{o}'\" --> #{q2}\n" }

      mmd.dup
    end

    # Returns a random Mealy machine.
    def self.random(
      alphabet:,
      output_alphabet:,
      max_state_size:,
      max_arc_ratio: 0.5,
      min_state_size: 1,
      sink_state_prob: 0.4,
      random: Random
    )
      state_size = random.rand(min_state_size..max_state_size)
      arc_ratio = [max_arc_ratio * random.rand, 0.01].max
      arc_state_size = [state_size, (state_size * arc_ratio).ceil].min

      initial_state = 0
      non_arc_states = (0...state_size).to_a
      non_arc_states.shuffle!(random:)
      arc_states = non_arc_states.pop(arc_state_size).to_set

      sink_state = random.rand < sink_state_prob ? non_arc_states.pop : nil

      transitions = {}
      arc_states.each_with_index do |arc_state, i|
        next if arc_state == initial_state
        n = i + 1 == arc_state_size ? non_arc_states.size : random.rand(non_arc_states.size)
        state = initial_state
        non_arc_states
          .pop(n)
          .each do |next_state|
            next if next_state == initial_state
            input = alphabet.sample(random:)
            output = output_alphabet.sample(random:)
            transitions[[state, input]] = [output, next_state]
            state = next_state
          end
        input = alphabet.sample(random:)
        output = output_alphabet.sample(random:)
        transitions[[state, input]] = [output, arc_state]
      end

      state_size.times do |state|
        alphabet.each do |input|
          next if transitions[[state, input]]
          output = output_alphabet.sample(random:)
          next_state = state == sink_state ? sink_state : random.rand(state_size)
          transitions[[state, input]] = [output, next_state]
        end
      end

      new(initial_state, transitions)
    end
  end

  # VPA is a 1-module single-entry visibly pushdown automaton (1-SEVPA).
  class VPA < Automaton
    # Conf is a configuration on VPAs.
    Conf = Data.define(:state, :stack)

    # StateToPrefixMapping is a mapping from states to prefix strings.
    #
    # It can transform a configuration to an access string.
    class StateToPrefixMapping
      def initialize(mapping)
        @mapping = mapping
      end

      # Transforms a configuration to an access string.
      def [](conf)
        return @mapping[nil] unless conf
        result = []

        conf.stack.each do |state, call_input|
          result.concat(@mapping[state])
          result << call_input
        end
        result.concat(@mapping[conf.state])

        result
      end

      # Returns a prefix string of `state`.
      def state_prefix(state)
        @mapping[state]
      end
    end

    def initialize(initial_state, accept_states, transitions, returns)
      super()

      @initial_state = initial_state
      @accept_states = accept_states
      @transitions = transitions
      @returns = returns
    end

    attr_reader :initial_state, :accept_states, :transitions, :returns

    # Returns the type of this automaton.
    def type
      :vpa
    end

    # Returns the initial configuration.
    def initial
      Conf[initial_state, []]
    end

    # Computes a transition for the given `input` from the current `state`.
    def step(conf, input)
      next_conf = step_conf(conf, input)
      output = !next_conf.nil? && accept_states.include?(next_conf.state) && next_conf.stack.empty?
      [output, next_conf]
    end

    # Returns a mermaid diagram.
    def to_mermaid(remove_error_state: true)
      error_state = error_state() if remove_error_state
      mmd = +""

      mmd << "flowchart TD\n"

      states =
        [initial_state] + transitions.keys.map { |(q, _)| q } + transitions.values + returns.keys.map { |(q, _)| q } +
          returns.values.flat_map { |rt| rt.flat_map { |(q1, _), q2| [q1, q2] } }
      states.uniq!
      states.delete(error_state)

      states.sort.each { |q| mmd << (accept_states.include?(q) ? "  #{q}(((#{q})))\n" : "  #{q}((#{q}))\n") }
      mmd << "\n"

      transitions.each do |(q1, i), q2|
        next if q1 == error_state || q2 == error_state
        mmd << "  #{q1} -- \"'#{i}'\" --> #{q2}\n"
      end
      mmd << "\n"

      returns.each do |(q1, r), rt|
        next if q1 == error_state
        rt.each do |(q2, c), q3|
          next if q2 == error_state || q3 == error_state
          mmd << "  #{q1} -- \"'#{r}'/(#{q2},'#{c}')\" --> #{q3}\n"
        end
      end

      mmd.dup
    end

    # Returns an error state in this VPA.
    def error_state
      t =
        transitions
          .group_by { |(state, _), _| state }
          .transform_values { _1.to_h { |(_, input), next_state| [input, next_state] } }

      t.each do |state, d|
        # The initial state and accepting states are not an error state.
        next if state == initial_state || accept_states.include?(state)

        # An error state should only have self-loops.
        next unless d.all? { |_, next_state| state == next_state }
        all_returns_are_self_loops =
          returns.all? do |_, rt|
            rt.filter { |(call_state, _), _| call_state == state }.all? { |_, next_state| state == next_state }
          end
        next unless all_returns_are_self_loops

        return state
      end

      nil
    end

    private

    def step_conf(conf, input)
      # `nil` means the error state.
      return nil unless conf

      next_state = @transitions[[conf.state, input]]
      return Conf[next_state, conf.stack] if next_state

      return_transitions = @returns[[conf.state, input]]
      if return_transitions
        return nil if conf.stack.empty?
        next_state = return_transitions[conf.stack.last]
        return Conf[next_state, conf.stack[0...-1]]
      end

      # When there is no usual transition and no return tansition for `input`,
      # then we assume that `input` is a call alphabet.
      Conf[initial_state, conf.stack + [[conf.state, input]]]
    end
  end
end
