# frozen_string_literal: true

require "set"

# Lernen is a simple automata learning library.
module Lernen
  # Error is an error class for this library.
  class Error < StandardError
  end
end

require_relative "lernen/automaton"
require_relative "lernen/cex_processor"
require_relative "lernen/oracle"
require_relative "lernen/sul"
require_relative "lernen/version"

require_relative "lernen/lstar"
