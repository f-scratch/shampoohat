# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shampoohat/version'

Gem::Specification.new do |spec|
  spec.name          = "shampoohat"
  spec.version       = Shampoohat::ApiConfig::VERSION
  spec.authors       = ["Junya Wako"]
  spec.email         = ["junwako@gmail.com"]

  spec.summary       = %q{Common code for Google Ads APIs}
  spec.description   = %q{Essential utilities shared by all Ads Ruby client libraries}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  s.add_dependency('savon', '~> 1.2.0')
  s.add_dependency('httpi', '~> 1.1.0')
  s.add_dependency('signet', '~> 0.6.0')

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end