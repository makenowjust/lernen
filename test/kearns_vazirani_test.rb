# frozen_string_literal: true

require_relative "test_helper"

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
end
