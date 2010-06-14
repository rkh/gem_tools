require 'lib/gem_tools'

Gem::Specification.new do |s|
  # Get the facts.
  s.name             = "gem_tools"
  s.version          = GemTools::VERSION
  s.description      = "Extends Gem::Specification"

  # Dependencies
  s.add_development_dependency "rspec", ">= 1.3.0"

  # Those should be about the same in any BigBand extension.
  s.authors          = ["Konstantin Haase"]
  s.email            = "konstantin.mailinglists@googlemail.com"
  s.files            = Dir["**/*.{rb,md}"]
  s.homepage         = "http://github.com/rkh/#{s.name}"
  s.require_paths    = ["lib"]
  s.summary          = s.description
end
