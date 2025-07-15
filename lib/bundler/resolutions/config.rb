# frozen_string_literal: true

require "yaml"

module Bundler
  class Resolutions
    class Config
      CONFIG_FILE_NAME = ".bundler-resolutions.yml"

      class << self
        def load_config(config = nil)
          location = "config hash"
          raw_hash = if config.is_a?(Hash)
                       config
                     else
                       location = find_config(config)
                       YAML.safe_load_file(location)
                     end
          gems = raw_hash.fetch("gems") {
            raise <<~ERR
              No 'gems' key found in #{location}. Please ensure the file is formatted correctly.

              Data was:
              #{raw_hash.inspect}
            ERR
          }
          gems.transform_values { |reqs|
            Array(reqs).flat_map { |v| v.split(",") }.map { |req| Gem::Requirement.new(req) }
          }
        end

        private def find_config(config = nil)
          return config if config # If present, assume it is a location

          # Use the ENV if present
          env_file = ENV["BUNDLER_RESOLUTIONS_CONFIG"]
          return env_file if env_file

          # Otherwise find it above where `BUNDLE_GEMFILE` is located, or pwd if not set
          dir = ENV["BUNDLE_GEMFILE"] ? File.dirname(ENV["BUNDLE_GEMFILE"]) : Dir.pwd
          until File.exist?(File.join(dir, CONFIG_FILE_NAME))
            dir = File.dirname(dir)
            raise "Could not find #{CONFIG_FILE_NAME}" if dir == "/"
          end
          File.join(dir, CONFIG_FILE_NAME)
        end
      end
    end
  end
end
