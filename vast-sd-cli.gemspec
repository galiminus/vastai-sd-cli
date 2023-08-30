require_relative 'lib/vast-sd/version'

Gem::Specification.new do |spec|
  spec.name    = 'vast-sd-cli'
  spec.version = VastSd::VERSION

  spec.authors = ['Anonymous']
  spec.email   = ['anonymous@unknown.com']

  spec.summary     = 'Little CLI tool to run and provision Stable Diffusion on Vast.ai (WIP)'
  spec.license     = 'MIT'

  spec.bindir      = 'bin'
  spec.executables = ['vast-sd']
  spec.files       = Dir['lib/**/*']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'dry-cli', '~> 1.0.0'
  spec.add_dependency 'tty-logger', '~> 0.6.0'
  spec.add_dependency 'tty-spinner', '~> 0.9.3'
  spec.add_dependency 'tty-prompt', '~> 0.23.1'
  spec.add_dependency 'tty-command', '~> 0.10.1'
end
