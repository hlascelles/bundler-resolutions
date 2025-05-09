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
    end

    # A module we prepend to Bundler::Resolutions::Resolver
    # :reek:ModuleInitialize
    module Resolver
      # Override the initializer in the resolver
      def initialize(*args)
        debugger
        Bundler::Resolutions.instance.add_concrete_resolutions_for(args.first)
        super
      end

      # This overrides the default behaviour of the resolver to filter out versions that don't
      # satisfy the requirements specified in .bundler-resolutions.yml.
      def filtered_versions_for(package)
        Bundler::Resolutions.instance.constrain_versions_for(super, package)
      end
    end

    def constrain_versions_for(results, package)
      results.select do |pkg|
        req = resolutions_for(package.name)
        if req
          log("making sure #{package} / #{pkg} is satisfied by #{req}")
          req.satisfied_by?(pkg.version)
        else
          true
        end
      end
    end

    def add_concrete_resolutions_for(base)
      base.requirements.each do |bundler_dependency|
        requirement_name = bundler_dependency.name
        resolutions = resolutions_for(requirement_name)

        if resolutions
          log(<<~MSG, requirement_name)
            has resolutions for concrete dependency '#{requirement_name}': #{resolutions}
          MSG
        else
          log("has no resolutions for concrete dependency '#{requirement_name}'", requirement_name)
          next
        end

        bundler_resolutions_reqs = resolutions.requirements
        apply_resolutions_for_concrete_gem(bundler_dependency, bundler_resolutions_reqs)
      end
    end

    private def resolutions_for(package_name)
      config[package_name]
    end

    # You can debug with BUNDLER_RESOLUTIONS_DEBUG=gem_name or BUNDLER_RESOLUTIONS_DEBUG=true
    # to see all messages.
    private def log(message, gem = nil)
      return unless ENV["BUNDLER_RESOLUTIONS_DEBUG"]
      return if gem && !ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem)

      puts "bundler-resolutions: #{message}"
    end

    private def apply_resolutions_for_concrete_gem(bundler_dependency, bundler_resolutions_reqs)
      requirement_name = bundler_dependency.name
      bundler_resolutions_reqs.each do |r|
        # If the concrete requirement is already in the Gemfile, skip it
        requirements = bundler_dependency.requirement.requirements
        if requirements.include?(r)
          # We don't want to double up / dupe the same requirements
          log(<<~MSG, requirement_name)
            Skipping adding requirements to gem concretely specified in Gemfile as it
            was already present: #{requirement_name}: #{bundler_dependency}
          MSG
          next
        end

        # Otherwise add the additional requirement
        before_req = bundler_dependency.to_s
        # If there were no requirements before, there is a default one for ">= 0". We need to
        # remove that so when we add the new one the implicit ">= 0" is not present, as it normally
        # isn't written out to lockfiles.
        if bundler_dependency.requirement == DEFAULT_GEM_REQUIREMENT
          log("Removing default requirement for #{requirement_name}", requirement_name)
          requirements.clear
        end
        # Add the new requirement
        requirements << r
        after_req = bundler_dependency.to_s

        log(<<~MSG, requirement_name)
          Adding concrete constraints for #{requirement_name}. Before: #{before_req}. After: #{after_req}.
        MSG
      end
    end

    module GemDeclarationWrapper
      def gem(name, *args)
        # If the gem is already in the Gemfile, skip it
        return if Bundler::Resolutions.instance.resolutions_for(name)

        # Otherwise call the original method
        super
      end
    end
  end
end

require "pry-byebug" if ENV["BUNDLER_RESOLUTIONS_DEBUG"]

Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)
Bundler::Dsl.prepend(Bundler::Resolutions::GemDeclarationWrapper)
