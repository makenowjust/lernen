# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Learner
    # Acex represents an abstract counterexample.
    #
    # Note that this class is *abstract*. We should implement the following method:
    #
    # - `#compute_effect(index)`
    class Acex
      # @rbs @cache: Array[bool | nil]

      #: (Integer size) -> void
      def initialize(size)
        @cache = Array.new(size)
      end

      #: () -> Integer
      def size = @cache.size

      #: (Integer index) -> bool
      def effect(index)
        eff = @cache[index]
        eff = @cache[index] = compute_effect(index) if eff.nil?
        eff
      end

      private

      # rubocop:disable Lint/UnusedMethodArgument

      #: (Integer index) -> bool
      def compute_effect(index)
        raise TypeError, "abstract method: `compute_effect`"
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
