# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud-formation/custom-resource/version'

Gem::Specification.new do |spec|
  spec.name          = "cfn-custom-resource"
  spec.version       = CloudFormation::CustomResource::VERSION
  spec.authors       = ["Chris Howe"]
  spec.email         = ["howech@infochimps.com"]
  spec.summary       = %q{Cloudformation custom resource handler}
  spec.description   = %q{This gem provides much of what you will need to handle requests for custom resources for AWS Cloudformation.}
  spec.license       = "UNKNOWN"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '>= 1.6.5'
  spec.add_development_dependency 'rake', '~> 10.3.2'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
end
