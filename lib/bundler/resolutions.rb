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

      def log(message, gem_name_obj = nil)
        gem_name_str = gem_name_obj.to_s
        return if ENV["BUNDLER_RESOLUTIONS_DEBUG"].nil?
        unless ENV["BUNDLER_RESOLUTIONS_DEBUG"] == "true" ||
               ENV["BUNDLER_RESOLUTIONS_DEBUG"].split(",").include?(gem_name_str)
          return
        end
        puts "bundler-resolutions: #{message}"
      end
    end

    module ResolverExtension
      def filtered_versions_for(package)
        versions = super(package)
        Bundler::Resolutions.instance.constrain_versions_for(versions, package)
      end
    end

    def constrain_versions_for(results, package)
      self.class.log("Constraining versions for #{package} with results: #{results.map(&:to_s)}", package.name)
      results.select do |pkg|
        version_to_check = pkg.is_a?(String) ? Gem::Version.new(pkg) : pkg.version
        reqs = resolutions_for(package.name)
        if reqs.nil?
          true
        else
          self.class.log("making sure #{package} / #{version_to_check} is satisfied by #{reqs.map(&:to_s)}", package.name)
          reqs.all? { |req| req.satisfied_by?(version_to_check) }
        end
      end
    end

    def resolutions_for(package_name)
      config[package_name]
    end

    module DefinitionExtension
      def check_lockfile
        super
        resolutions_instance = Bundler::Resolutions.instance
        return unless resolutions_instance&.config&.any? && @locked_specs
        invalids = @locked_specs.to_a.select do |lazy_specification|
          reqs = resolutions_instance.resolutions_for(lazy_specification.name)
          next false if reqs.nil?
          if reqs.all? { |req| req.satisfied_by?(lazy_specification.version) }
            Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is satisfied (resolutions).", lazy_specification.name
            false
          else
            Bundler::Resolutions.log "#{lazy_specification.name} (#{lazy_specification.version}) is NOT satisfied by resolutions.", lazy_specification.name
            true
          end
        end
        invalids.each { |invalid_spec| @locked_specs.delete(invalid_spec) }
      end
    end

    module DependencyExtension
      def to_lock
        original_gemfile_requirement = self.requirement
        final_requirement_to_use = original_gemfile_requirement
        modified = false

        resolutions_instance = Bundler::Resolutions.instance
        if resolutions_instance&.config&.any?
          resolution_gem_requirements = resolutions_instance.resolutions_for(self.name) # Array of Gem::Requirement

          if resolution_gem_requirements && !resolution_gem_requirements.empty?
            exact_resolution = resolution_gem_requirements.find do |r|
              r.requirements.length == 1 && r.requirements.first&.first == '='
            end

            if exact_resolution
              Bundler::Resolutions.log("Found exact resolution '#{exact_resolution}' for '#{self.name}'. This will replace Gemfile requirement '#{original_gemfile_requirement}'.", self.name)
              final_requirement_to_use = exact_resolution
            else
              # No exact resolution, combine Gemfile req with all (ranged) resolution reqs
              all_req_pairs = original_gemfile_requirement.requirements +
                              resolution_gem_requirements.flat_map(&:requirements)
              unique_req_strings = all_req_pairs.map { |op, ver| "#{op} #{ver.to_s}" }.uniq
              combined_req = Gem::Requirement.new(unique_req_strings)

              Bundler::Resolutions.log("No exact resolution for '#{self.name}'. Combined Gemfile req '#{original_gemfile_requirement}' with resolutions '#{resolution_gem_requirements.map(&:to_s).join(", ")}' into '#{combined_req}'.", self.name)
              final_requirement_to_use = combined_req
            end

            if original_gemfile_requirement != final_requirement_to_use
              modified = true
            end
          end
        end

        if modified
          Bundler::Resolutions.log("Overriding requirement for '#{self.name}' from '#{original_gemfile_requirement}' to '#{final_requirement_to_use}' for to_lock.", self.name)
          begin
            self.instance_variable_set(:@requirement, final_requirement_to_use)
            return super()
          ensure
            self.instance_variable_set(:@requirement, original_gemfile_requirement)
          end
        else
          super()
        end
      end
    end
  end
end

{
  Bundler::Resolver => :filtered_versions_for,
  Bundler::Definition => :check_lockfile,
  Bundler::Dependency => :to_lock
}.each do |klass, method|
  unless klass.instance_methods.include?(method) || klass.private_instance_methods.include?(method)
    raise "Compatibility error: #{klass}##{method} not found for Bundler::Resolutions."
  end
end

Bundler::Definition.prepend(Bundler::Resolutions::DefinitionExtension)
Bundler::Resolver.prepend(Bundler::Resolutions::ResolverExtension)
Bundler::Dependency.prepend(Bundler::Resolutions::DependencyExtension)

Bundler::Resolutions.log("bundler-resolutions #{Bundler::Resolutions::VERSION} loaded with all patches for concrete dependency requirement overrides.")
