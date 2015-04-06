# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_formation/custom_resource/version'

Gem::Specification.new do |spec|
  spec.name          = 'cfn-custom-resource'
  spec.version       = CloudFormation::CustomResource::VERSION
  spec.authors       = ['Chris Howe', 'Travis Dempsey']
  spec.email         = ['howech@infochimps.com', 'travis@infochimps.com']
  spec.summary       = 'Cloudformation custom resource handler'
  spec.description   = <<-DESC.gsub(/^ {4}/, '')
    This gem provides much of what you will need to handle requests for AWS Cloudformation Custom Resources
  DESC
  spec.license       = 'UNKNOWN'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}){ |f| File.basename f }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency('bundler',   '>= 1.6.5')
  spec.add_development_dependency('rake',      '~> 10.3.2')
  spec.add_development_dependency('rspec',     '~> 3.0.0')
  spec.add_development_dependency('rubocop',   '~> 0.30.0')
  spec.add_development_dependency('simplecov', '~> 0.9.0')
end
