# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ic/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-ic"
  spec.version       = Ic::VERSION
  spec.authors       = ['Gildas Cherruel']
  spec.email         = ['gildas@breizh.org']
  spec.summary       = %q{Interactive Intelligence's Interaction Center API for Ruby}
  spec.description   = %q{Implements the Interactive Intelligence's Interaction Center API as of 4.0 SU6 for Ruby}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler', '~> 1.6'
  spec.add_dependency 'httpclient'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
