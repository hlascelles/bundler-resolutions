# frozen_string_literal: true

require "spec_helper"

describe Bundler::Resolutions do
  Dir["spec/examples/**/Gemfile"].each do |gemfile|
    it "should generate the right lock file for #{gemfile}" do
      Dir.chdir(File.dirname(gemfile)) do
        `bundle install`
        expect(File.read("Gemfile.lock")).to eq(File.read("Gemfile.lock.expected"))
      end
    end
  end
end
