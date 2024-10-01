# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # This is a namespace for types of automata (transition systems).
  #
  # In this library, the following transition systems are supported.
  #
  # - `DFA` (deterministic finite-state automaton) ([Wikipedia](https://en.wikipedia.org/wiki/Deterministic_finite_automaton))
  # - `Mealy` machine ([Wikipedia](https://en.wikipedia.org/wiki/Mealy_machine))
  # - `Moore` machine ([Wikipedia](https://en.wikipedia.org/wiki/Moore_machine))
  # - `VPA` (visibly pushdown automaton) ([Wikipedia](https://en.wikipedia.org/wiki/Nested_word#Visibly_pushdown_automaton))
  module Automaton
    # @rbs!
    #   type transition_system_type = :dfa | :moore | :mealy | :vpa | :spa
  end
end

require "lernen/automaton/transition_system"
require "lernen/automaton/moore_like"

require "lernen/automaton/mealy"
require "lernen/automaton/moore"
require "lernen/automaton/dfa"
require "lernen/automaton/vpa"
require "lernen/automaton/spa"

require "lernen/automaton/proc_util"
