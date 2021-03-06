# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gun_dog/version"

Gem::Specification.new do |spec|
  spec.name          = "gun_dog"
  spec.version       = GunDog::VERSION
  spec.authors       = ["Stephen Prater"]
  spec.email         = ["me@stephenprater.com"]

  spec.summary       = %q{Log callsite information for a given class.}
  spec.description   = %q{Log callsite information for a given class.}
  spec.homepage      = "http://github.com/stephenprater/gun_dog"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "multi_json", "~> 1.12"
  spec.add_dependency "activesupport", ">= 4.2.9"
  spec.add_dependency "method_source"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "activerecord", ">= 4.2.9"
  spec.add_development_dependency "sqlite3"
end
