# frozen_string_literal: true

require_relative "lib/lernen/version"

Gem::Specification.new do |spec|
  spec.name = "lernen"
  spec.version = Lernen::VERSION
  spec.authors = ["TSUYUSATO Kitsune"]
  spec.email = ["make.just.on@gmail.com"]

  spec.summary = "a simple automata leraning library"
  spec.description = ""
  spec.homepage = "https://github.com/makenowjust/lernen"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/makenowjust/lernen"

  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0")
        .reject do |f|
          (File.expand_path(f) == __FILE__) ||
            f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
        end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency("set", ">= 1.0.3")
end
