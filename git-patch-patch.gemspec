# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'git-patch-patch/version'

Gem::Specification.new do |s|
  s.name          = "git-patch-patch"
  s.version       = Git::Trifle::PatchPatcher::VERSION
  s.authors       = ["lacravate"]
  s.email         = ["lacravate@lacravate.fr"]
  s.homepage      = "https://github.com/lacravate/git-patch-patch"
  s.summary       = "A script to rewrite git patches/commits, while keeping commits history"
  s.description   = "A script to rewrite git patches/commits, while keeping commits history"

  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'

  # Di reaaly need to specify that one ?
  s.add_dependency "getopt"
  s.add_dependency "git-trifle" # git handle
  s.add_dependency "path-accessor" # file accessor

  s.add_development_dependency "rspec"
end
