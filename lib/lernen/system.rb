# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # This is a namespace for systems under learning (SULs).
  #
  # `SUL` is an implementation of membership (or output) query.
  #
  # There are two base abstract classes of SULs: `SUL` and `MooreLikeSUL`
  # `SUL` is the most base abstract class of SULs and it cannot answer a query
  # with the empty string. `MooreLikeSUL` is subclass of `SUL` and it can answer
  # the empty string query.
  #
  # In this library, we provide two easy ways to create a SUL. The first way is
  # `System.from_block`. This method takes a block, and the block is used as
  # a membership query implementation.
  #
  # ```ruby
  # sul = Lernen::System.from_block do |word|
  #   word.count("1") % 4 == 3
  # end
  # ```
  #
  # The another way is `System.from_automaton`. This method takes an automaton
  # (a transition system), and the result SUL simulates this automaton.
  #
  # ```ruby
  # dfa = Lernen::Automaton::DFA.new(
  #   0,
  #   Set[1],
  #   {
  #     [0, '0'] => 0,
  #     [0, '1'] => 1,
  #     [1, '0'] => 1,
  #     [1, '1'] => 1,
  #   }
  # )
  #
  # sul = Lernen::System.from_automaton(dfa)
  # ```
  module System
    # Creates a SUL from the given block as an implementation of a membership query.
    #
    #: [In, Out] (?cache: bool) { (Array[In]) -> Out } -> MooreLikeSUL[In, Out]
    def self.from_block(cache: true, &) = BlockSUL.new(cache:, &)

    # Creates a SUL from the given automaton as an implementation.
    #
    # This method chooses a suitable SUL implementation, which is one of `TransitionSystemSimulator`
    # or `MooreLikeSimulator`, for the given automaton.
    #
    #: [In] (Automaton::DFA[In] automaton, ?cache: bool) -> SUL[In, bool]
    #: [In, Out] (Automaton::Mealy[In, Out] automaton, ?cache: bool) -> SUL[In, Out]
    #: [In, Out] (Automaton::Moore[In, Out] automaton, ?cache: bool) -> SUL[In, Out]
    #: [In, Call, Return] (Automaton::VPA[In, Call, Return] automaton, ?cache: bool) -> SUL[In | Call | Return, bool]
    #: [In, Call, Return] (Automaton::SPA[In, Call, Return] automaton, ?cache: bool) -> SUL[In | Call | Return, bool]
    def self.from_automaton(automaton, cache: true) =
      case automaton.type
      in :dfa | :moore | :vpa | :spa
        MooreLikeSimulator.new(automaton, cache:)
      in :mealy
        TransitionSystemSimulator.new(automaton, cache:)
      end
  end
end

require "lernen/system/sul"
require "lernen/system/moore_like_sul"

require "lernen/system/block_sul"
require "lernen/system/transition_system_simulator"
require "lernen/system/moore_like_simulator"
