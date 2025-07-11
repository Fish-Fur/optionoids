# frozen_string_literal: true

require_relative 'lib/optionoids/version'

Gem::Specification.new do |spec|
  spec.name = 'optionoids'
  spec.version = Optionoids::VERSION
  spec.authors = ['drewthorp']
  spec.email = ['gems@fishfur.com']

  spec.summary = 'A Ruby gem for checking content of option hashes.'
  spec.description = 'Optionoids is a Ruby gem designed to provide a simple and flexible way to ' \
                     'validate and check the content of option hashes. It allows developers to ' \
                     'define checks for required keys, unexpected keys, and value conditions, ' \
                     'making it easier to work with configuration options in Ruby applications.'
  spec.homepage = 'https://github.com/Fish-Fur/optionoids'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ features/ .git appveyor Gemfile]) ||
        f.end_with?('.gem')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'activesupport', '>= 7.1.0', '< 9.0'
  # spec.add_dependency 'class_store', '>= 0.2.0', '< 1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
