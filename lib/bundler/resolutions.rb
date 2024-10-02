# frozen_string_literal: true

module Bundler
  class Resolutions
    GROUP_NAME = :resolutions

    attr_reader :resolutions

    def initialize
      @resolutions = {}
    end

    # This method is called by the DSL to set the resolution for a given gem. It is effectively
    # an override of the normal gem method.
    def gem(name, requirements)
      resolutions[name.to_sym] = requirements
    end

    class << self
      def instance = @instance ||= new
    end

    # A module we prepend to Bundler::Resolutions::Resolver
    module Resolver
      # This overrides the default behaviour of the resolver to filter out versions that don't
      # satisfy the requirements specified in RESOLVER_RESOLUTIONS.
      def filtered_versions_for(package)
        super.select do |pkg|
          req = Bundler::Resolutions.instance.resolutions[package.name.to_sym]
          req ? Gem::Requirement.new(*req.split(",")).satisfied_by?(pkg.version) : true
        end
      end
    end

    # A module we prepend to Bundler::Dsl
    module Dsl
      # Here we override the normal group function to capture the resolutions, and ensure any
      # gem calls are effectively a no-op as regards to adding them to dependencies.
      def group(*args, &blk)
        args.first == GROUP_NAME ? Bundler::Resolutions.instance.instance_eval(&blk) : super
      end
    end
  end
end

Bundler::Resolver.prepend(Bundler::Resolutions::Resolver)
Bundler::Dsl.prepend(Bundler::Resolutions::Dsl)
