# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # This is a namespace for equivalence query oracles.
  #
  # A equivalence query check the given hypothesis automaton is equivalence
  # to a SUL. If that is not, it returns a counterexample, which leads
  # different output values between the hypothesis and the SUL.
  module Equiv
  end
end

require "lernen/equiv/oracle"

require "lernen/equiv/exhaustive_search_oracle"
require "lernen/equiv/random_walk_oracle"
require "lernen/equiv/random_word_oracle"
require "lernen/equiv/random_well_matched_word_oracle"
