# frozen_string_literal: true

puts caller
puts "versioning bundler-resolutions"
require_relative "../resolutions"

module Bundler
  class Resolutions
    VERSION = "0.3.0"
  end
end
