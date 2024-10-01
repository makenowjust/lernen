# frozen_string_literal: true
# rbs_inline: enabled

require "set"

require "lernen/version"
require "lernen/graph"
require "lernen/automaton"
require "lernen/system"
require "lernen/equiv"
require "lernen/algorithm"

# Lernen is an automata learning library written in Ruby.
#
# **Automata learning** (active automata learning) is a known technique to infer an automaton
# from a teacher program; here, a teacher is an abstraction of a system (or a program) that
# can answer two kinds of queries. One kind of queries is **membership** query, which takes
# an input word and returns a boolean value whether the word is accepted or rejected by the system.
# Another kind of queries is **equivalence** query, which takes a hypothesis (under-learning) automaton
# and returns `true` if the hypothesis is equivalent to the system, or returns a counterexample
# word if it is not equivalent. Automata learning algorithms use these queries to gather
# information about the black-box system and infer an automaton which is equivalent to the system.
#
# This library implements some automata learning algorithms.
#
# - L* (also known as Angluin's L*) is a common and classic algorithm for automata learning, introduced
#   by [Angluin (1987) "Learning Regular Sets from Queries and Counterexamples"](https://dl.acm.org/doi/10.1016/0890-5401%2887%2990052-6).
#   This algorithm uses an observation table for collecting query results and inferring an automaton.
#   Our implementation also accepts the Rivest-Schapire counterexample processing optimization described by
#   [Rivest & Schapire (1993) "Inference of Finite Automata Using Homing Sequences"](https://www.sciencedirect.com/science/article/pii/S0890540183710217).
# - Kearns-Vazirani is also a common and classic algorithm, introduced by
#   [Kearns & Vazirani (1994) "An Introduction to Computational Learning Theory"](https://direct.mit.edu/books/monograph/2604/An-Introduction-to-Computational-Learning-Theory).
#   This algorithm uses a discrimination tree for learning an automaton instead of an observation
#   tree. Also, our implementation is extended to infer a VPA (visibly pushdown automaton) that is
#   an extension of DFA which can recognize some non-regular languages (nested words).
#   It is the default algorithm in this library.
# - L# is a modern algorithm for automata learning, introduced by
#   [Vaandrager et al. (2022) "A New Approach for Active Automata Learning Based on Apartness"](https://link.springer.com/chapter/10.1007/978-3-030-99524-9_12).
#   This algorithm uses apartness relation and an observation tree for learning an automaton.
#   In many cases, it reduces the numbers of queries, but the data structure and algorithm have
#   some overheads. If a query is slow (e.g., forking a process), this algorithm may be a good option.
#
# ## Example
#
# This library provides `Lernen.learn` method as a good frontend for learning an automaton.
#
# In the most simple way to use it, we need to give `alphabet` and a block to infer a program
# to `Lernen.learn`. See the below example. This example is a program to learn a prediction on
# the binary language as a DFA and print it as a [mermaid](https://mermaid.js.org) diagram.
#
# ```ruby
# dfa = Lernen.learn(alphabet: %w[0 1]) do |word|
#   word.count("1") % 4 == 3
# end
# puts dfa.to_mermaid
#
# # Output:
# # flowchart TD
# #   0((0))
# #   1((1))
# #   2((2))
# #   3(((3)))
# #
# #   0 -- "'0'" --> 0
# #   0 -- "'1'" --> 1
# #   1 -- "'0'" --> 1
# #   1 -- "'1'" --> 2
# #   2 -- "'0'" --> 2
# #   2 -- "'1'" --> 3
# #   3 -- "'0'" --> 3
# #   3 -- "'1'" --> 0
# ```
#
# Of course, we can specify more parameters to `Lernen.learn` for learning other kinds of automata
# such as Moore or Mealy machines. Please refer the `Lernen.learn` doc.
module Lernen
  # @rbs!
  #   type oracle_type = :exhaustive_search
  #                    | :random_walk
  #                    | :random_word
  #                    | :random_well_matched_word
  #                    | :simulator
  #
  #   type algorithm_name = :lstar
  #                       | :kearns_vazirani
  #                       | :lsharp

  # Learn an automaton by using the given parameters.
  #
  # This method is a frontend of the learning algorithms. Actual implementations are placed under
  # the `Lernen::Algorithm` namespace.
  #
  # ## Parameters
  #
  # This method takes a lot of parameters, but almost of parameters are optional. To start learning,
  # we need to give `alphabet` and a block of a program to infer an automaton.
  #
  # - `alphabet`: An input alphabet. This must be given as an `Array` object.
  # - `call_alphabet`: A call input alphabet of VPA. If this is specified, `automaton_type` is specified
  #   as `:vpa` automatically.
  # - `return_alphabet`: A return input alphabet of VPA.
  # - `sul`: A system under learning. If an automaton instance is given, it is converted it to a simulator
  #   and use it as a SUL. Or, if it is not specified, we use a block as a SUL.
  # - `oracle`: An equivalence oracle. It is one of `:exhaustive_search`, `:random_walk`, `:random_word`, or
  #   an actual instance of `Equiv::Oracle`. If the value is a symbol, an `Equiv::Oracle` instance of the specified
  #   kind is created with `oracle_params`. The default value is `:random_word` if `automaton_type` is one of `:dfa`,
  #   `:moore`, and `:mealy`, or the default value is `:random_well_matched_word` if `automaton_type` is either `:spa`
  #   or `:vpa`.
  # - `oracle_params`: A hash of parameters for equivalence oracle. The default value is `{}`.
  # - `algorithm`: An algorithm name to use. It is one of `:lstar`, `:kearns_vazirani`, or `:lsharp`. The default value
  #   is `:kearns_vazirani` (if `automaton_type` is one of `:dfa`, `:moore`, and `:mealy`), or `:kearns_vazirani_vpa`
  #   (if `automaton_type` is `vpa`), or `:procedural` (if `automaton_type` is `spa`).
  # - `automaton_type`: A type of automaton to infer. It is one of `:dfa`, `:mealy`, `:moore`, `:vpa`, and `:spa`.
  #   The default value is `:dfa`, but it becomes `:vpa` or `:spa` if `call_alphabet` or `return_input` is specified.
  # - `params`: A hash of parameter to pass a learning algorithm. The default value is `{}`.
  # - `random`: A PRNG instance. It is used by an equivalence oracle.
  #
  #: [In] (
  #    alphabet: Array[In],
  #    sul: Automaton::DFA[In] | System::MooreLikeSUL[In, bool],
  #    ?oracle: oracle_type | Equiv::Oracle[In, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    ?automaton_type: :dfa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) -> Automaton::DFA[In]
  #: [In] (
  #    alphabet: Array[In],
  #    ?oracle: oracle_type | Equiv::Oracle[In, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    ?automaton_type: :dfa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) { (Array[In]) -> bool } -> Automaton::DFA[In]
  #: [In, Out] (
  #    alphabet: Array[In],
  #    sul: Automaton::Mealy[In, Out] | System::SUL[In, Out],
  #    ?oracle: oracle_type | Equiv::Oracle[In, Out],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    automaton_type: :mealy,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) -> Automaton::Mealy[In, Out]
  #: [In, Out] (
  #    alphabet: Array[In],
  #    ?oracle: oracle_type | Equiv::Oracle[In, Out],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    automaton_type: :mealy,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) { (Array[In]) -> Out } -> Automaton::Mealy[In, Out]
  #: [In, Out] (
  #    alphabet: Array[In],
  #    sul: Automaton::Moore[In, Out] | System::MooreLikeSUL[In, Out],
  #    ?oracle: oracle_type | Equiv::Oracle[In, Out],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    automaton_type: :moore,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) -> Automaton::Moore[In, Out]
  #: [In, Out] (
  #    alphabet: Array[In],
  #    ?oracle: oracle_type | Equiv::Oracle[In, Out],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: algorithm_name,
  #    automaton_type: :moore,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) { (Array[In]) -> Out } -> Automaton::Moore[In, Out]
  #: [In, Call, Return] (
  #    alphabet: Array[In],
  #    call_alphabet: Array[Call],
  #    return_alphabet: Array[Return],
  #    sul: Automaton::VPA[In, Call, Return] | System::MooreLikeSUL[In | Call | Return, bool],
  #    ?oracle: oracle_type | Equiv::Oracle[In | Call | Return, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: :kearns_vazirani_vpa,
  #    ?automaton_type: :vpa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) -> Automaton::VPA[In, Call, Return]
  #: [In, Call, Return] (
  #    alphabet: Array[In],
  #    call_alphabet: Array[Call],
  #    return_alphabet: Array[Return],
  #    ?oracle: oracle_type | Equiv::Oracle[In | Call | Return, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: :kearns_vazirani_vpa,
  #    ?automaton_type: :vpa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) { (Array[In | Call | Return]) -> bool } -> Automaton::VPA[In, Call, Return]
  #: [In, Call, Return] (
  #    alphabet: Array[In],
  #    call_alphabet: Array[Call],
  #    return_input: Return,
  #    sul: Automaton::SPA[In, Call, Return] | System::MooreLikeSUL[In | Call | Return, bool],
  #    ?oracle: oracle_type | Equiv::Oracle[In | Call | Return, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: :procedural,
  #    ?automaton_type: :spa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) -> Automaton::SPA[In, Call, Return]
  #: [In, Call, Return] (
  #    alphabet: Array[In],
  #    call_alphabet: Array[Call],
  #    return_input: Return,
  #    ?oracle: oracle_type | Equiv::Oracle[In | Call | Return, bool],
  #    ?oracle_params: Hash[Symbol, untyped],
  #    ?algorithm: :procedural,
  #    ?automaton_type: :spa,
  #    ?params: Hash[Symbol, untyped],
  #    ?random: Random
  #  ) { (Array[In | Call | Return]) -> bool } -> Automaton::SPA[In, Call, Return]
  def self.learn(
    alphabet:,
    call_alphabet: nil,
    return_alphabet: nil,
    return_input: nil,
    sul: nil,
    oracle: nil,
    oracle_params: {},
    algorithm: nil,
    automaton_type: nil,
    params: {},
    random: Random,
    &sul_block
  )
    automaton = nil

    case sul
    when System::SUL
      # Do nothing
    when Automaton::TransitionSystem
      automaton = sul
      oracle ||= :simulator
      automaton_type ||= sul.type
      sul = System.from_automaton(sul) # steep:ignore
    when nil
      sul = System.from_block(&sul_block) # steep:ignore
    else
      raise ArgumentError, "Unsupported SUL: #{sul}"
    end

    automaton_type ||=
      if call_alphabet
        return_input ? :spa : :vpa
      else
        :dfa
      end

    merged_alphabet =
      case automaton_type
      in :dfa | :moore | :mealy
        alphabet
      in :vpa | :spa
        return_alphabet ||= [return_input]
        alphabet + call_alphabet + return_alphabet
      end

    oracle ||= %i[vpa spa].include?(automaton_type) ? :random_well_matched_word : :random_word

    case oracle
    when Equiv::Oracle
      # Do nothing
    when :exhaustive_search
      oracle = Equiv::ExhaustiveSearchOracle.new(merged_alphabet, sul, **oracle_params)
    when :random_walk
      oracle = Equiv::RandomWalkOracle.new(merged_alphabet, sul, random:, **oracle_params)
    when :random_word
      oracle = Equiv::RandomWordOracle.new(merged_alphabet, sul, random:, **oracle_params)
    when :random_well_matched_word
      oracle =
        Equiv::RandomWellMatchedWordOracle.new(
          alphabet,
          call_alphabet, # steep:ignore
          return_alphabet, # steep:ignore
          sul,
          random:,
          **oracle_params
        )
    when :simulator
      oracle =
        case automaton
        when Automaton::Mealy
          Equiv::TransitionSystemSimulatorOracle.new(alphabet, automaton, sul)
        when Automaton::DFA, Automaton::Moore
          Equiv::MooreLikeSimulatorOracle.new(alphabet, automaton, sul)
        when Automaton::VPA
          Equiv::VPASimulatorOracle.new(alphabet, call_alphabet, return_alphabet, automaton, sul) # steep:ignore
        when Automaton::SPA
          Equiv::SPASimulatorOracle.new(alphabet, call_alphabet, automaton, sul) # steep:ignore
        else
          raise ArgumentError, "Cannot simulate automaton: #{automaton}"
        end
    else
      raise ArgumentError, "Unsupported oracle: #{oracle}"
    end

    algorithm ||=
      case automaton_type
      in :dfa | :moore | :mealy
        :kearns_vazirani
      in :vpa
        :kearns_vazirani_vpa
      in :spa
        :procedural
      end

    case algorithm
    in :lstar
      Algorithm::LStar.learn(alphabet, sul, oracle, automaton_type:, **params)
    in :kearns_vazirani
      Algorithm::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type:, **params)
    in :kearns_vazirani_vpa
      Algorithm::KearnsVaziraniVPA.learn(alphabet, call_alphabet, return_alphabet, sul, oracle, **params)
    in :lsharp
      Algorithm::LSharp.learn(alphabet, sul, oracle, automaton_type:, **params)
    in :procedural
      Algorithm::Procedural.learn(alphabet, call_alphabet, return_input, sul, oracle, **params)
    end
  end
end
