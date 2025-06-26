module Bundler
  class Resolutions
    module Test
      # :reek:ManualDispatch
      def run_lockfile_test(dir)
        Dir.chdir(dir) do
          FileUtils.rm_f("Gemfile.lock")
          if File.exist?("Gemfile.lock.original")
            original = File.read("Gemfile.lock.original")
            File.write(
              "Gemfile.lock", original.sub("$TEST_WITH_BUNDLER_VERSION", TEST_WITH_BUNDLER_VERSION)
            )
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
          setup_cmd = "bundle config --local path ./.gems"

          env_vars = "BUNDLE_GEMFILE=#{dir}/Gemfile BUNDLER_RESOLUTIONS_CONFIG=#{dir}/.bundler-resolutions.yml"
          # Propagate BUNDLER_RESOLUTIONS_DEBUG if set in the parent environment
          if ENV["BUNDLER_RESOLUTIONS_DEBUG"]
            env_vars += " BUNDLER_RESOLUTIONS_DEBUG=#{ENV['BUNDLER_RESOLUTIONS_DEBUG']}"
          end

          install_cmd = "#{env_vars} bundle install"
          cmd = "#{setup_cmd} && #{install_cmd}"

          puts "Running: #{cmd}" # Log the command that will be run
          output = ""
          Bundler.with_original_env do
            output = `#{cmd}` # Capture stdout and stderr
          end
          puts output # Print the captured output to see logs from bundler-resolutions

          raise "Bundle install failed (Gemfile.lock not found)" unless File.exist?("Gemfile.lock")

          Bundler::LockfileParser.new(File.read("Gemfile.lock")).tap do |lockfile|
            unless lockfile.bundler_version.to_s == TEST_WITH_BUNDLER_VERSION
              puts "ENV:"
              puts ENV.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
              raise <<~ERR
                Wrong bundler version in produced lockfile. Expected #{TEST_WITH_BUNDLER_VERSION}, got #{lockfile.bundler_version}
              ERR
            end
          end
        end
      end
    end
  end
end
