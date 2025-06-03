# frozen_string_literal: true

debug_on = ENV["BUNDLER_RESOLUTIONS_DEBUG"]
specs_running = ENV["BUNDLER_RESOLUTIONS_SPECS_RUNNING"]
ENV["BUNDLER_RESOLUTIONS_DEBUG"] = nil
ENV["BUNDLER_RESOLUTIONS_SPECS_RUNNING"] = nil

# Force the tester to choose a specific version of Bundler, since this matters a lot.
TEST_WITH_BUNDLER_VERSION = ENV.fetch("BUNDLER_VERSION").freeze

require "bundler"
Bundler.setup
Bundler.require(:default, :development, :test)

Dir["./spec/support/**/*.rb"].each { |f| require f }

ENV["BUNDLER_RESOLUTIONS_DEBUG"] = debug_on
ENV["BUNDLER_RESOLUTIONS_SPECS_RUNNING"] = specs_running
puts "Starting bundler_resolutions specs" unless ENV["BUNDLER_RESOLUTIONS_DEBUG"].nil?

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.include(Bundler::Resolutions::Test)
end

require_relative "../lib/bundler/resolutions"
