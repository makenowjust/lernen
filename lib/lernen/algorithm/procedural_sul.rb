# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  module Algorithm
    # ProceduralSUL is
    #
    # @rbs generic In     -- Type for input alphabet
    # @rbs generic Call   -- Type for call alphabet
    # @rbs generic Return -- Type for return alphabet
    class ProceduralSUL < System::MooreLikeSUL #[In | Call, bool]
      # @rbs @proc: Call
      # @rbs @sul: System::SUL[In | Call | Return, bool]
      # @rbs @manager: ATRManager[In, Call, Return]

      #: (
      #    Call proc,
      #    System::SUL[In | Call | Return, bool] sul,
      #    ATRManager[In, Call, Return] manager
      #  ) -> void
      def initialize(proc, sul, manager)
        super(cache: false)

        @proc = proc
        @sul = sul
        @manager = manager
      end

      # @rbs override
      def query_empty
        @sul.query_last(@manager.embed(@proc, []))
      end

      # @rbs override
      def query(word)
        @sul.query(@manager.embed(@proc, word))
      end

      # @rbs override
      def step(_input)
        raise TypeError, "ProceduralSUL does not support `step`"
      end
    end
  end
end
