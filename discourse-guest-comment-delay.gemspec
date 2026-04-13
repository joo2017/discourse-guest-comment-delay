# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "discourse-guest-comment-delay"
  spec.version       = "0.1.0"
  spec.summary       = "Discourse plugin for delaying guest visibility of recent replies"
  spec.description   = "Hides recent topic replies from anonymous users while leaving the first post visible and logged-in behavior unchanged."
  spec.authors       = ["OpenAI"]
  spec.files         = Dir[
    "plugin.rb",
    "config/**/*",
    "lib/**/*",
    "spec/**/*",
    "assets/**/*",
    "README.md"
  ]
  spec.require_paths = ["lib"]
  spec.license       = "MIT"

  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
