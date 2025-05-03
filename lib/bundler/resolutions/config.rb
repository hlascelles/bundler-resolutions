# frozen_string_literal: true

require "yaml"

module Bundler
  class Resolutions
    class Config
      CONFIG_FILE_NAME = ".bundler-resolutions.yml"

      class << self
        def load_config(config = nil)
          raw_hash = if config.is_a?(Hash)
                       config
                     else
                       YAML.safe_load_file(find_config(config))
                     end
          gems = raw_hash.fetch("gems")
          gems.transform_values { |version| Gem::Requirement.new(version.split(",")) }
        end

        private def find_config(config = nil)
          return config if config # If present, assume it is a location

          # Use the ENV if present
          env_file = ENV["BUNDLER_RESOLUTIONS_CONFIG"]
          return env_file if env_file

          # Otherwise find it in the file tree
          dir = Dir.pwd
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
