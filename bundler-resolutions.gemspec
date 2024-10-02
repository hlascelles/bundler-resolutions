# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bundler/resolutions/version"

Gem::Specification.new do |spec|
  spec.name = "bundler-resolutions"
  spec.version = Bundler::Resolutions::VERSION
  spec.authors = ["Harry Lascelles"]
  spec.email = ["harry@harrylascelles.com"]
  spec.summary = "A bundler plugin to enforce resolutions without specifying a concrete dependency"
  spec.description =
    "A bundler plugin to enforce resolutions without specifying a concrete dependency"
  spec.homepage = "https://github.com/hlascelles/bundler-resolutions"
  spec.license = "MIT"
  spec.metadata = {
    "homepage_uri" => "https://github.com/hlascelles/bundler-resolutions",
    "documentation_uri" => "https://github.com/hlascelles/bundler-resolutions",
    "changelog_uri" => "https://github.com/hlascelles/bundler-resolutions/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/hlascelles/bundler-resolutions/",
    "bug_tracker_uri" => "https://github.com/hlascelles/bundler-resolutions/issues",
    "rubygems_mfa_required" => "true",
  }
  spec.files = Dir["{lib}/**/*"] + %w[README.md plugins.rb]
  spec.require_paths = ["lib"]
end
