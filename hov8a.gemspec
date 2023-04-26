# frozen_string_literal: true

require_relative "lib/hov8a/version"

Gem::Specification.new do |spec|
  spec.name = "hov8a"
  spec.version = Hov8a::VERSION
  spec.authors = ["Hov8a"]
  spec.email = ["hov8a@gmail.com"]

  spec.summary = "Daily Attendance Processor."
  spec.description = "Daily Attendance Processor with relevant analytics"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_development_dependency 'rspec', ['~> 3.11']
  spec.add_development_dependency 'rubocop', ['~> 1.35.0']

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
