# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shampoohat/version'

Gem::Specification.new do |spec|
  spec.name          = "shampoohat"
  spec.version       = Shampoohat::ApiConfig::CLIENT_LIB_VERSION
  spec.authors       = ["Junya Wako"]
  spec.email         = ["junwako@gmail.com"]

  spec.summary       = %q{Common code for SOAP based APIs}
  spec.description   = %q{Essential utilities shared by all Ads Ruby client libraries}
  spec.homepage      = "https://github.com/f-scratch/shampoohat"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = Dir.glob('test/test_*.rb')

  spec.add_runtime_dependency('google-ads-savon', '~> 1.0.0')
  spec.add_runtime_dependency('httpi', '~> 2.3')
  spec.add_runtime_dependency('signet', '~> 0.6.0')

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", ">= 10.4.2"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "minitest"
end
