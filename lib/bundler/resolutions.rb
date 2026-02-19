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
        @instance ||= new # rubocop:disable ThreadSafety/ClassInstanceVariable
      end

      # You can debug with BUNDLER_RESOLUTIONS_DEBUG=gem_name or BUNDLER_RESOLUTIONS_DEBUG=true
      # to see all messages.
      def log(message, gem = nil)
        return if ENV["BUNDLER_RESOLUTIONS_DEBUG"].nil?
        unless ENV["BUNDLER_RESOLUTIONS_DEBUG"] == "true" ||
               ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem)
          return
        end

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
        invalids = @locked_specs.to_a.select { |s| spec_invalid?(s) }
        return if invalids.empty?

        # Ensure @locked_specs is a separate object from @originally_locked_specs before mutating.
        # Bundler initialises both to the same SpecSet object (definition.rb:
        # `@locked_specs = @originally_locked_specs`). If we delete from the shared object,
        # @originally_locked_specs loses the platform-specific entries too, causing
        # remove_invalid_platforms! to incorrectly strip non-local platforms from @platforms,
        # which in turn drops those platforms from the regenerated lockfile.
        if @locked_specs.equal?(@originally_locked_specs)
          @locked_specs = SpecSet.new(@originally_locked_specs.to_a)
        end
        @locked_specs.delete(invalids)
        # Signal to Bundler that re-resolution is needed due to invalid transitive dependencies.
        # This prevents confusing "Could not find gems valid for all resolution platforms" errors.
        @locked_spec_with_invalid_deps = invalids.first.name if @locked_spec_with_invalid_deps.nil?
      end

      private def spec_invalid?(lazy_specification)
        reqs = Bundler::Resolutions.instance.resolutions_for(lazy_specification.name)
        return false if reqs.nil?

        # rubocop:disable Layout/LineLength
        if reqs.all? { |req| req.satisfied_by?(lazy_specification.version) }
          Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is satisfied by the current lockfile version."
          false
        else
          Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is NOT satisfied by the current lockfile version."
          true
        end
        # rubocop:enable Layout/LineLength
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
  next if klass.method_defined?(method) || klass.private_method_defined?(method)

  raise <<~ERR
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
