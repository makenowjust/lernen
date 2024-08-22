# frozen_string_literal: true

module Lernen
  # SUL is a System Under Learning.
  #
  # It is an abtraction of a system under learning (SUL) which accepts an operation
  # called "membership query"; it takes an input string (word) and returns a sequence
  # of outputs corresponding to the input string.
  #
  # This SUL assumes the system is much like Mealy machine; that is, a transition puts
  # an output, and query does not accept the empty string due to no outputs.
  #
  # Note that this class is *abstract*. You should implement the following method:
  #
  # - `#step(input)`
  class SUL
    # Creates a SUL from the given block as an implementation of a membership query.
    def self.from_block(&) = BlockSUL.new(&)

    def initialize
      @num_queries = 0
      @num_steps = 0
    end

    # Returns statistics information as a `Hash` object.
    def stats
      { num_queries: @num_queries, num_steps: @num_steps }
    end

    # Runs a membership query with the given inputs.
    #
    # Note that this method does not accept the empty string due to no outpus.
    # If you need to call `query` with the empty string, you should use `MooreSUL#query_empty` instead.
    def query(inputs)
      if inputs.empty?
        raise ArgumentError, "`query` does not accept the empty string. Please use `query_empty` instead."
      end

      setup

      outputs = inputs.map { |input| step(input) }

      shutdown

      @num_queries += 1
      @num_steps += inputs.size

      outputs
    end

    # It is a setup procedure of this SUL.
    #
    # Note that it does nothing by default.
    def setup
    end

    # It is a shutdown procedure of this SUL.
    #
    # Note that it does nothing by default.
    def shutdown
    end

    # Consumes the given `input` and returns the correspoding output.
    #
    # This is *abstract*.
    def step(_input)
      raise TypeError, "abstract method: `step`"
    end
  end

  # MooreSUL is a System Under Learning (SUL) for a system much like Moore machine.
  #
  # By contrast to `SUL`, this accepts a query with the empty string additionally.
  #
  # Note that this class is *abstract*. You should implement the following method:
  #
  # - `#step(input)`
  # - `#query_empty`
  class MooreSUL < SUL
    # Runs a membership query with the given inputs.
    #
    # This is *abstract*.
    def query_empty
      raise TypeError, "abstract method: `query_empty`"
    end
  end

  # BlockSUL is a System Under Learning (SUL) constructed from a block.
  #
  # A block is expected to behave like a membership query.
  class BlockSUL < MooreSUL
    def initialize(&block)
      super

      @block = block
      @inputs = []
    end

    # It is a setup procedure of this SUL.
    def setup
      @inputs = []
    end

    # Runs a membership query with the given inputs.
    def step(input)
      @inputs << input
      @block.call(@inputs)
    end

    # Runs a membership query with the given inputs.
    def query_empty
      @block.call([])
    end
  end
end
