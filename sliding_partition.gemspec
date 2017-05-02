$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "sliding_partition/identity"

Gem::Specification.new do |spec|
  spec.name = SlidingPartition::Identity.name
  spec.version = SlidingPartition::Identity.version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Paul Sadauskas"]
  spec.email = ["psadauskas@gmail.com"]
  spec.homepage = "https://github.com/paul/sliding_partition"
  spec.summary = ""
  spec.description = ""
  spec.license = "MIT"

  if ENV["RUBY_GEM_SECURITY"] == "enabled"
    spec.signing_key = File.expand_path("~/.ssh/gem-private.pem")
    spec.cert_chain = [File.expand_path("~/.ssh/gem-public.pem")]
  end

  spec.add_dependency "activerecord", ">= 4.2.0", "<= 6.0.0"
  spec.add_dependency "pg"
  spec.add_dependency "rounding"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 11.0"
  spec.add_development_dependency "gemsmith", "~> 9.4"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-state"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rb-fsevent" # Guard file events for OSX.
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "terminal-notifier"
  spec.add_development_dependency "rubocop", "~> 0.41"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "awesome_print"

  spec.files = Dir["lib/**/*", "vendor/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]
end
