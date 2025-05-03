# frozen_string_literal: true

ENV["BUNDLER_RESOLUTIONS_DEBUG"] ||= "true"
ENV["BUNDLER_RESOLUTIONS_SPECS_RUNNING"] ||= "true"

require "bundler"
Bundler.setup

Bundler.require(:development, :test)

Dir["./spec/support/**/*.rb"].each { |f| require f }

puts "Starting bundler_resolutions specs" if ENV["BUNDLER_RESOLUTIONS_DEBUG"] == "true"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.include(Bundler::Resolutions::Test)
end
