# frozen_string_literal: true

require "spec_helper"

describe "Rails example" do
  it "should make sure resolutions work for a large lockfile which includes Rails" do
    Dir.chdir(__dir__) do
      FileUtils.rm_f("Gemfile.lock")
      `BUNDLE_GEMFILE=#{__dir__}/Gemfile bundle install`
      lockfile = Bundler::LockfileParser.new(File.read("Gemfile.lock"))
      # See that psych is locked
      expect(lockfile.specs.find { _1.name == "psych" }.version.to_s).to eq("5.2.2")
      nokogiri_version = lockfile.specs.find { _1.name == "nokogiri" }.version
      expect(nokogiri_version).to be > Gem::Version.new("1.16.5")
      expect(nokogiri_version).to be < Gem::Version.new("1.18")
    end
  end
end
