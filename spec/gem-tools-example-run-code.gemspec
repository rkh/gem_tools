require 'gem_tools'

Gem::Specification.new do |s|
  s.name = 'gem-tools-example-run-code'
  s.version = '1.0'
  s.summary = 'foo'
  s.run_code { puts 'w00t' }
end
