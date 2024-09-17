# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # This is a namespace for learning algorithm implementations.
  #
  # This namespace also contains data structures and utilities for
  # learning algorithms.
  module Learner
  end
end

require "lernen/learner/cex_processor"

require "lernen/learner/observation_table"
require "lernen/learner/lstar"

require "lernen/learner/discrimination_tree"
require "lernen/learner/kearns_vazirani"

require "lernen/learner/discrimination_tree_vpa"
require "lernen/learner/kearns_vazirani_vpa"

require "lernen/learner/observation_tree"
require "lernen/learner/lsharp"

require "lernen/learner/atr_manager"
