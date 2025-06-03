# frozen_string_literal: true

require "yaml"
require_relative "resolutions/config"
require_relative "resolutions/version"

module Bundler
  class Resolutions
    DEFAULT_GEM_REQUIREMENT = Gem::Requirement.default

    attr_reader :config

    def initialize(config = nil)
      @config = Bundler::Resolutions::Config.load_config(config)
    end

    class << self
      def instance
        @instance ||= new
      end

      # You can debug with BUNDLER_RESOLUTIONS_DEBUG=gem_name or BUNDLER_RESOLUTIONS_DEBUG=true
      # to see all messages.
      def log(message, gem = nil)
        return if ENV["BUNDLER_RESOLUTIONS_DEBUG"].nil?
        return unless ENV["BUNDLER_RESOLUTIONS_DEBUG"] == "true" || ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem)

        puts "bundler-resolutions: #{message}"
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
      log("Constraining versions for #{package} with results: #{results.map(&:to_s)}")
      results.select do |pkg|
        reqs = resolutions_for(package.name)
        if reqs.nil?
          true
        else
          log("making sure #{package} / #{pkg} is satisfied by #{reqs.map(&:to_s)}")
          reqs.all? { |req| req.satisfied_by?(pkg.version) }
        end
      end
    end

    def resolutions_for(package_name)
      config[package_name]
    end

    def log(message, gem = nil) = self.class.log(message, gem)

    module Definition
      def check_lockfile
        super
        invalids =@locked_specs.to_a.select { |lazy_specification|
          reqs = Bundler::Resolutions.instance.resolutions_for(lazy_specification.name)
          next if reqs.nil?

          if reqs.all? { |req| req.satisfied_by?(lazy_specification.version) }
            Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is satisfied by the current lockfile version."
            nil
          else
            Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is NOT satisfied by the current lockfile version."
            lazy_specification
          end
        }
        @locked_specs.delete(invalids)
      end
    end
  end
end

# Check if the methods exists before we prepend them, to avoid issues with Bundler versions
# that do not have this method.
{
  Bundler::Resolver => :filtered_versions_for,
  Bundler::Definition => :nothing_changed?,
}.each do |klass, method|
  raise <<~ERR unless klass.instance_methods.include?(method) || klass.private_instance_methods.include?(method)
    Bundler version #{Bundler::VERSION} is not compatible with bundler-resolutions #{Bundler::Resolutions::VERSION}
    The method '#{method}' is not defined in '#{klass}'. This is likely due to a refactoring of a new
    Bundler version. Please check the bundler-resolutions changelog and the Bundler changelog
    to see if this is a known issue, or submit a bug report to bundler-resolutions.
  ERR
end

# This is needed so we can trigger a rebuild of the lock file if just the yaml has changed.
Bundler::Definition.prepend(Bundler::Resolutions::Definition)
# This removes the transitive dependency versions that do not satisfy the yaml config.
Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)

Bundler::Resolutions.log("bundler-resolutions #{Bundler::Resolutions::VERSION} loaded")
