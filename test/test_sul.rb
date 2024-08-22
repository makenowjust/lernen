# frozen_string_literal: true

class TestSUL < Minitest::Test
  def test_block_sul
    sul = Lernen::SUL.from_block { |inputs| inputs.count { _1 == "1" } % 4 == 3 }

    assert_equal [false, false, true, false], sul.query(%w[1 1 1 1])
    assert_equal [false, false, false, true], sul.query(%w[0 1 1 1])

    sul.setup

    refute sul.step("1")
    refute sul.step("1")
    assert sul.step("1")
    sul.shutdown
  end
end
