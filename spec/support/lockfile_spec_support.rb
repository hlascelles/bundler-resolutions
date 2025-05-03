module Bundler
  class Resolutions
    module Test
      # :reek:ManualDispatch
      def run_lockfile_test(dir)
        Dir.chdir(dir) do
          FileUtils.rm_f("Gemfile.lock")
          if File.exist?("Gemfile.lock.original")
            FileUtils.cp("Gemfile.lock.original",
                         "Gemfile.lock")
          end

          lockfile = Bundler::Resolutions::Test.perform_test_install(dir)
          expect(lockfile.specs.map { |spec|
            [spec.name, spec.version.to_s]
          }).to match_array(expected_gem_specs_versions)
          expect(lockfile.dependencies.keys).to match_array(expected_dependencies)

          if respond_to?(:expected_dependency_versions)
            expected_dependency_versions.each do |dep_name, version|
              dep = lockfile.dependencies[dep_name]
              raise "Dependency #{dep_name} not found in lockfile" unless dep

              expect(dep.requirement.to_s).to eq(version)
            end
          end
        end
        true
      end

      class << self
        def perform_test_install(dir)
          puts `BUNDLE_GEMFILE=#{dir}/Gemfile bundle install`
          raise "Bundle install failed" unless File.exist?("Gemfile.lock")

          Bundler::LockfileParser.new(File.read("Gemfile.lock"))
        end
      end
    end
  end
end
