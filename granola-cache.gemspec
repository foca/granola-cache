# frozen_string_literal: true

require "./lib/granola/cache/version"

Gem::Specification.new do |s|
  s.name        = "granola-cache"
  s.licenses    = ["MIT"]
  s.version     = Granola::Cache::VERSION
  s.summary     = "Cache the output of your Granola serializers."
  s.description = <<-TEXT.gsub(/^\s+/, "")
    Granola::Cache provides an interface to wrap your serialization in a cache
    so that you don't needlessly generate the same bit of JSON over and over
    again.
  TEXT
  s.authors     = ["Nicolas Sanguinetti"]
  s.email       = ["contacto@nicolassanguinetti.info"]
  s.homepage    = "http://github.com/foca/granola"

  s.files = Dir[
    "LICENSE",
    "README.md",
    "lib/granola/cache.rb",
    "lib/granola/cache/version.rb",
  ]

  # FIXME: Once Granola 1.0 launches, change this to depend on "~> 1.0"
  s.add_dependency "granola", ">= 0.13", "~> 0"
  s.add_development_dependency "cutest", "~> 1.2"
end
