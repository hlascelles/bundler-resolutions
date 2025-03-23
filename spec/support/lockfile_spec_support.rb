shared_examples "a lockfile test" do |dir|
  it "should make sure specs and dependencies are correct" do
    Dir.chdir(dir) do
      FileUtils.rm_f("Gemfile.lock")
      FileUtils.cp("Gemfile.lock.original", "Gemfile.lock") if File.exist?("Gemfile.lock.original")
      puts `BUNDLE_GEMFILE=#{dir}/Gemfile bundle install`
      lockfile = Bundler::LockfileParser.new(File.read("Gemfile.lock"))
      expect(lockfile.specs.map { |spec|
        [spec.name, spec.version.to_s]
      }).to match_array(expected_gem_specs_versions)
      expect(lockfile.dependencies.keys).to match_array(expected_dependencies)
    end
  end
end
