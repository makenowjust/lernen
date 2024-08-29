# frozen_string_literal: true

require_relative "test_helper"

require "prism"

class TestKearnsVazirani < Minitest::Test
  def test_learn_dfa
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }
    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis = Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :dfa)

    expected =
      Lernen::DFA.new(
        0,
        Set[3],
        {
          [0, "0"] => 0,
          [0, "1"] => 1,
          [1, "0"] => 1,
          [1, "1"] => 2,
          [2, "0"] => 2,
          [2, "1"] => 3,
          [3, "0"] => 3,
          [3, "1"] => 0
        }
      )

    assert_equal expected, hypothesis
  end

  def test_learn_moore1
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 }
    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis = Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :moore)

    expected =
      Lernen::Moore.new(
        0,
        { 0 => 0, 1 => 1, 2 => 2, 3 => 3 },
        {
          [0, "0"] => 0,
          [0, "1"] => 1,
          [1, "0"] => 1,
          [1, "1"] => 2,
          [2, "0"] => 2,
          [2, "1"] => 3,
          [3, "0"] => 3,
          [3, "1"] => 0
        }
      )

    assert_equal expected, hypothesis
  end

  def test_learn_moore2
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }
    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis = Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :moore)

    expected =
      Lernen::Moore.new(
        0,
        { 0 => false, 1 => false, 2 => false, 3 => true },
        {
          [0, "0"] => 0,
          [0, "1"] => 1,
          [1, "0"] => 1,
          [1, "1"] => 2,
          [2, "0"] => 2,
          [2, "1"] => 3,
          [3, "0"] => 3,
          [3, "1"] => 0
        }
      )

    assert_equal expected, hypothesis
  end

  def test_learn_mealy1
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 }
    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis = Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :mealy)

    expected =
      Lernen::Mealy.new(
        0,
        {
          [0, "0"] => [0, 0],
          [0, "1"] => [1, 1],
          [1, "0"] => [1, 1],
          [1, "1"] => [2, 2],
          [2, "0"] => [2, 2],
          [2, "1"] => [3, 3],
          [3, "0"] => [3, 3],
          [3, "1"] => [0, 0]
        }
      )

    assert_equal expected, hypothesis
  end

  def test_learn_mealy2
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }
    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis = Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :mealy)

    expected =
      Lernen::Mealy.new(
        0,
        {
          [0, "0"] => [false, 0],
          [0, "1"] => [false, 1],
          [1, "0"] => [false, 1],
          [1, "1"] => [false, 2],
          [2, "0"] => [false, 2],
          [2, "1"] => [true, 3],
          [3, "0"] => [true, 3],
          [3, "1"] => [false, 0]
        }
      )

    assert_equal expected, hypothesis
  end

  def test_learn_vpa
    alphabet = %w[1 +]
    call_alphabet = %w[(]
    return_alphabet = %w[)]
    merged_alphabet = alphabet + call_alphabet + return_alphabet

    sul = Lernen::SUL.from_block { |inputs| Prism.parse(inputs.join).success? }
    oracle = Lernen::BreadthFirstExplorationOracle.new(merged_alphabet, sul)

    hypothesis =
      Lernen::KearnsVazirani.learn(alphabet, sul, oracle, automaton_type: :vpa, call_alphabet:, return_alphabet:)
    run = ->(str) do
      return hypothesis.accept_states.include?(hypothesis.initial_state) if str.empty?
      hypothesis.run(str.chars).first.last
    end

    assert run.call("")
    assert run.call("1")
    assert run.call("1+1")
    assert run.call("((1)+(1))")
    assert run.call("1++1")
    refute run.call("(")
    refute run.call("+")
  end
end
