# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qunited/version"

Gem::Specification.new do |s|
  s.name        = "qunited"
  s.version     = QUnited::VERSION
  s.authors     = ["Aaron Royer"]
  s.email       = ["aaronroyer@gmail.com", "thomsbg@gmail.com"]
  s.homepage    = "https://github.com/aaronroyer/qunited"
  s.summary     = %q{QUnit tests in your build}
  s.description = %q{QUnited runs headless QUnit tests as part of your normal build}

  s.rubyforge_project = "qunited"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
