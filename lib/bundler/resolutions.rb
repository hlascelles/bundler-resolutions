# frozen_string_literal: true

require "yaml"
require_relative "resolutions/config"

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
        return unless ENV["BUNDLER_RESOLUTIONS_DEBUG"]
        return if gem && ENV["BUNDLER_RESOLUTIONS_DEBUG"] != "true" && !ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem)

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

    module GemDeclarationWrapper
      def gem(name, *args)
        resolutions = Bundler::Resolutions.instance.resolutions_for(name)
        if resolutions
          super(name, args + resolutions.map(&:to_s))
        else
          super
        end
      end
    end

    module Definition
      # This checks if the bundler-resolutions yaml file now no longer is satisfied by the
      # current Gemfile.lock. This may be because the yaml file was changed.
      def something_changed?
        @resolutions_satisfied ||= @locked_specs.to_a.map { |lazy_specification|
          name = lazy_specification.name
          lock_version = lazy_specification.version
          resolutions = Bundler::Resolutions.instance.resolutions_for(name) || []
          Bundler::Resolutions.log("checking if #{name} is satisfied by the current lockfile version of #{lock_version}", name)
          resolutions.all? { |req| req.satisfied_by?(lock_version) }
        }.all?
        require "pry-byebug"
        debugger

        super || !@resolutions_satisfied
      end
    end
  end
end

# This is needed so we can trigger a rebuild of the lock file if just the yaml has changed.
Bundler::Definition.prepend(Bundler::Resolutions::Definition)
# This removes the transitive dependency versions that do not satisfy the yaml config.
Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)
# This wraps the main Gemfile gem method to add requirements to concrete dependencies.
Bundler::Dsl.prepend(Bundler::Resolutions::GemDeclarationWrapper)
