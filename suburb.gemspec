# frozen_string_literal: true

require_relative 'lib/suburb/version'

Gem::Specification.new do |spec|
  spec.name = 'suburb'
  spec.version = Suburb::VERSION
  spec.authors = ['Søren Skovsbøll']
  spec.email = ['sorens@hey.com']

  spec.summary = 'Suburb - the developer friendly build graph'
  spec.description = <<~EOS
    A build tool that connects other build tools with a complete and acyclic graph.
    Unline many other build tools, Suburb does not try to take over the world but lets you work,
    directly in your code repo, using the tools that you love.
  EOS
  spec.homepage = 'https://github.com/skovsboll/suburb'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.3'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/skovsboll/suburb'
  spec.metadata['changelog_uri'] = 'https://github.com/skovsboll/suburb/'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .ruby-lsp .circleci
                                                             appveyor scenarios .rtx.toml .gitignore])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'tty-command', '~> 0.10'
  spec.add_dependency 'tty-link', '~> 0.1'
  spec.add_dependency 'tty-logger', '~> 0.6'
  spec.add_dependency 'tty-option', '~> 0.3'
  spec.add_dependency 'tty-progressbar', '~> 0.18'
  spec.add_dependency 'filewatcher', '~> 2.0'
end
