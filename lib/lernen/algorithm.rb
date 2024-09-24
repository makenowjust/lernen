# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # This is a namespace for learning algorithm implementations.
  #
  # This namespace also contains data structures and utilities for
  # learning algorithms.
  module Algorithm
  end
end

require "lernen/algorithm/acex"
require "lernen/algorithm/prefix_transformer_acex"
require "lernen/algorithm/cex_processor"

require "lernen/algorithm/learner"

require "lernen/algorithm/observation_table"
require "lernen/algorithm/lstar"

require "lernen/algorithm/discrimination_tree"
require "lernen/algorithm/kearns_vazirani"

require "lernen/algorithm/discrimination_tree_vpa"
require "lernen/algorithm/kearns_vazirani_vpa"

require "lernen/algorithm/observation_tree"
require "lernen/algorithm/lsharp"

require "lernen/algorithm/atr_manager"
