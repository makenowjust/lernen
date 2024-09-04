# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Automaton
    # MooreLike represents a Moore-like transition system.
    #
    # This transition system has an output value for each configuration (or state).
    # Therefore, the following invariant is required for all `conf` and `input`.
    #
    # ```ruby
    # step_output, next_conf = self.step(conf, input)
    # step_output == self.output(next_conf)
    # ```
    #
    # Note that in this class, the initial output of the `#run` method is lost.
    # If it is needed, we can use `#run_empty` instead.
    #
    # Note that this class is *abstract*. We should implement the following method:
    #
    # - `#type`
    # - `#initial_conf`
    # - `#step_conf(conf, input)`
    # - `#output(conf)`
    #
    # @rbs generic Conf -- Type for a configuration of this automaton
    # @rbs generic In   -- Type for input alphabet
    # @rbs generic Out  -- Type for output values
    class MooreLike < TransitionSystem #[Conf, In, Out]
      # rubocop:disable Lint/UnusedMethodArgument

      # Runs a transition from the given configuration with the given input.
      # It looks like `#step`, but it does not return an output value because
      # it can be computed by `#output` in this class.
      #
      # This is an abstract method.
      #
      #: (Conf conf, In innput) -> Conf
      def step_conf(conf, input)
        raise TypeError, "abstract method: `step_conf`"
      end

      # Returns the output value for the given configuration.
      #
      # This is an abstract method.
      #
      #: (Conf conf) -> Out
      def output(conf)
        raise TypeError, "abstract method: `output`"
      end

      # rubocop:enable Lint/UnusedMethodArgument

      # @rbs override
      def step(conf, input)
        next_conf = step_conf(conf, input)
        [output(next_conf), next_conf]
      end

      # Runs and returns the output value of the transitions for the empty string.
      #
      #: () -> Out
      def run_empty = output(initial_conf)

      # Finds a separating word between `automaton1` and `automaton2`.
      #
      #: [Conf, In, Out] (
      #    Array[In] alphabet,
      #    MooreLike[Conf, In, Out] automaton1,
      #    MooreLike[Conf, In, Out] automaton2
      #  ) -> (Array[In] | nil)
      def self.find_separating_word(alphabet, automaton1, automaton2)
        unless automaton2.is_a?(automaton1.class)
          raise ArgumentError, "Cannot find a separating word for different type automata"
        end

        return [] if automaton1.run_empty != automaton2.run_empty # steep:ignore

        super
      end
    end
  end
end
