# frozen_string_literal: true

require "yaml"

module Bundler
  class Resolutions
    CONFIG_FILE_NAME = ".bundler-resolutions.yml"

    attr_reader :resolutions

    def initialize(config = nil)
      load_config(config)
    end

    class << self
      def instance
        @instance ||= new
      end
    end

    # A module we prepend to Bundler::Resolutions::Resolver
    module Resolver
      # This overrides the default behaviour of the resolver to filter out versions that don't
      # satisfy the requirements specified in .bundler-resolutions.yml.
      def filtered_versions_for(package)
        Bundler::Resolutions.instance.constrain_versions_for(super, package)
      end
    end

    def constrain_versions_for(results, package)
      results.select do |pkg|
        req = resolutions[package.name]
        if req
          if ENV["BUNDLER_RESOLUTIONS_DEBUG"] == "true"
            puts "bundler-resolutions making sure #{package} is satisfied by #{req}"
          end
          req.satisfied_by?(pkg.version)
        else
          true
        end
      end
    end

    private def load_config(config = nil)
      # Safe load yaml file whose location is given by an argument, an ENV, and if no
      # env given then work up dir hierarchy until found.
      # The file should be called .bundler-resolutions.yml
      raw_hash = if config.is_a?(Hash)
                   config
                 else
                   YAML.safe_load_file(find_config(config))
                 end
      gems = raw_hash.fetch("gems")
      @resolutions = gems.transform_values { |version| Gem::Requirement.new(version.split(",")) }
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

Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)
