# frozen_string_literal: true

require_relative "test_helper"

class TestOracle < Minitest::Test
  def test_breadth_first_exploration_oracle
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }

    oracle = Lernen::BreadthFirstExplorationOracle.new(alphabet, sul)
    hypothesis =
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
          [3, "1"] => 3
        }
      )

    assert_equal %w[0 1 1 1 1], oracle.find_cex(hypothesis)
  end

  def test_random_walk_racle
    alphabet = %w[0 1]
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }

    oracle = Lernen::RandomWalkOracle.new(alphabet, sul)
    hypothesis =
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
          [3, "1"] => 3
        }
      )

    refute_nil oracle.find_cex(hypothesis)
  end
end
