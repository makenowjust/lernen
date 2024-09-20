# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # PrefixTransformerAcex is an implementation of `Acex` for classic prefix transformers.
    #
    # @rbs generic Conf
    # @rbs generic In
    # @rbs generic Out
    class PrefixTransformerAcex < Acex
      #: (
      #    Array[In] cex,
      #    System::SUL[In, Out] sul,
      #    Automaton::TransitionSystem[Conf, In, Out] hypothesis,
      #    ^(Conf) -> Array[In] conf_to_prefix
      #  ) -> void
      def initialize(cex, sul, hypothesis, conf_to_prefix)
        super(cex.size)

        @cex = cex
        @sul = sul
        @hypothesis = hypothesis
        @conf_to_prefix = conf_to_prefix

        @hypothesis_output = @hypothesis.run(cex)[0].last
      end

      private

      # @rbs override
      def compute_effect(index)
        prefix = @cex[0...index]
        suffix = @cex[index...]

        _, prefix_conf = @hypothesis.run(prefix)
        @sul.query_last(@conf_to_prefix.call(prefix_conf) + suffix) == @hypothesis_output
      end
    end
  end
end
