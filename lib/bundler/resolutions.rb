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

    # You can debug with BUNDLER_RESOLUTIONS_DEBUG=gem_name or BUNDLER_RESOLUTIONS_DEBUG=true
    # to see all messages.
    private def log(message, gem = nil)
      return unless ENV["BUNDLER_RESOLUTIONS_DEBUG"]
      return if gem && !ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem)

      puts "bundler-resolutions: #{message}"
    end

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
  end
end

require "pry-byebug" if ENV["BUNDLER_RESOLUTIONS_DEBUG"]

Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)
Bundler::Dsl.prepend(Bundler::Resolutions::GemDeclarationWrapper)
