# frozen_string_literal: true
# rbs_inline: enabled

require_relative "test_helper"

require "open3"

class ExampleTest < Minitest::Test
  EXAMPLES_DIR = File.expand_path("../examples", __dir__ || ".") #: String

  #: (*String cmd) -> String
  def capture(*cmd)
    # Currently, a RBS signature for `open3` is missing.
    stdout, exit_code = Open3.capture2(*cmd) # steep:ignore

    assert_equal 0, exit_code

    stdout
  end

  #: () -> void
  def test_text_example_uri_parse_regexp
    assert_equal <<~STDOUT, capture("bundle", "exec", "ruby", File.join(EXAMPLES_DIR, "uri_parse_regexp.rb"))
      Infer `URI.parse` DFA...
      Infer `URI` regexp DFA...
      Check equivalence between `URI.parse` and `URI` regexp DFAs...
      "http:?%" is the separating word between `URI.parse` and `URI` regexp DFAs.
          valid_and_http_url?("http:?%") = true
      new_valid_and_http_url?("http:?%") = false
    STDOUT
  end

  #: () -> void
  def test_text_example_ripper_prism
    assert_equal <<~'STDOUT', capture("bundle", "exec", "ruby", File.join(EXAMPLES_DIR, "ripper_prism.rb"))
      Infer Ripper VPA...
      Infer Prism VPA...
      Check equivalence between Prism and Ripper VPAs...
      "(\"a\":)" is the separating word between Prism and Ripper VPAs.
        !Ripper.parse("(\"a\":)").nil? = false
      Prism.parse("(\"a\":)").success? = true
    STDOUT
  end
end
