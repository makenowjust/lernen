# frozen_string_literal: true
# rbs_inline: enabled

require_relative "../../test_helper"

require "ripper/sexp"
require "prism"

module Lernen
  module Algorithm
    class KearnsVaziraniVPATest < Minitest::Test
      #: () -> void
      def test_learn
        alphabet = %w[1 +]
        call_alphabet = %w[(]
        return_alphabet = %w[)]
        merged_alphabet = alphabet + call_alphabet + return_alphabet

        prism_sul = System.from_block { |word| Prism.parse(word.join).success? }
        prism_oracle = Equiv::ExhaustiveSearchOracle.new(merged_alphabet, prism_sul)
        prism_vpa = KearnsVaziraniVPA.learn(alphabet, call_alphabet, return_alphabet, prism_sul, prism_oracle)

        ripper_sul = System.from_block { |word| !Ripper.sexp(word.join).nil? }
        ripper_oracle = Equiv::ExhaustiveSearchOracle.new(merged_alphabet, ripper_sul)
        ripper_vpa = KearnsVaziraniVPA.learn(alphabet, call_alphabet, return_alphabet, ripper_sul, ripper_oracle)

        cex = Automaton::VPA.find_separating_word(alphabet, call_alphabet, return_alphabet, prism_vpa, ripper_vpa)

        assert_nil cex
      end
    end
  end
end
