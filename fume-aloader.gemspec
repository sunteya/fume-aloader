# frozen_string_literal: true

require_relative "lib/fume/aloader/version"

Gem::Specification.new do |spec|
  spec.name = "fume-aloader"
  spec.version = Fume::Aloader::VERSION
  spec.authors = ["sunteya"]
  spec.email = ["sunteya@gmail.com"]

  spec.summary = "a configurable eager loading plugin for rails"
  spec.homepage = "https://github.com/sunteya/fume-aloader"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rails', '~> 6.1'
  spec.add_development_dependency 'combustion', '~> 1.3'
  spec.add_development_dependency 'sqlite3', ">= 1.4.2"
  spec.add_development_dependency "rspec-do_action", "~> 0.0.7"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency 'simplecov', "~> 0.21.2"
  spec.add_development_dependency 'factory_bot', "~> 6.2.1"
  spec.add_development_dependency 'faker', '~> 2.20.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
