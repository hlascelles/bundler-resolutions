# frozen_string_literal: true

require "spec_helper"
require "climate_control"
require "tempfile"
require "fileutils"
require "tmpdir"

describe Bundler::Resolutions::Config do
  let(:valid_config_hash) { { "gems" => { "thor" => "1.3.1" } } }
  let(:valid_yaml) { "gems:\n  thor: \"1.3.1\"\n" }

  context "with a hash config" do
    it "loads configuration from a hash" do
      resolutions = described_class.load_config(valid_config_hash)
      thor_requirement = resolutions["thor"].first
      expect(thor_requirement).to be_a(Gem::Requirement)
      expect(thor_requirement.to_s).to eq("= 1.3.1")
    end
  end

  context "with a file path" do
    it "loads configuration from a file path" do
      Tempfile.create(["resolutions", ".yml"]) do |file|
        file.write(valid_yaml)
        file.flush

        resolutions = described_class.load_config(file.path)
        thor_requirement = resolutions["thor"].first
        expect(thor_requirement).to be_a(Gem::Requirement)
        expect(thor_requirement.to_s).to eq("= 1.3.1")
      end
    end
  end

  context "with ENV variable" do
    it "loads configuration from ENV path" do
      Tempfile.create(%w[resolutions .yml]) do |file|
        file.write(valid_yaml)
        file.flush

        ClimateControl.modify BUNDLER_RESOLUTIONS_CONFIG: file.path do
          resolutions = described_class.load_config
          thor_requirement = resolutions["thor"].first
          expect(thor_requirement).to be_a(Gem::Requirement)
          expect(thor_requirement.to_s).to eq("= 1.3.1")
        end
      end
    end
  end

  context "when finding in directory tree" do
    it "finds configuration by traversing up directories from the Gemfile" do
      Dir.mktmpdir do |dir|
        # Create a nested directory structure
        nested_dir = File.join(dir, "level1", "level2")
        FileUtils.mkdir_p(nested_dir)

        # Create config file in the root dir
        config_path = File.join(dir, ".bundler-resolutions.yml")
        File.write(config_path, valid_yaml)

        # Change to the nested directory and initialize without config
        ClimateControl.modify BUNDLE_GEMFILE: File.join(nested_dir, "Gemfile") do
          Dir.chdir(nested_dir) do
            resolutions = described_class.load_config
            expect(resolutions["thor"]).to be_a(Array)
            expect(resolutions["thor"].first).to be_a(Gem::Requirement)
            expect(resolutions["thor"].first.to_s).to eq("= 1.3.1")
          end
        end
      end
    end

    # These tests are to make sure calling commands like:
    #
    # cd /foo/baz
    # BUNDLE_GEMFILE=/foo/bar/Gemfile bundle install
    #
    # will look for the config file in /foo/bar (ie above the Gemfile, not above the pwd)
    context "when using different pwds" do
      it "does not use a configuration file which is above pwd, but not above the Gemfile" do
        Dir.mktmpdir do |dir|
          # Tree structure:
          # dir
          # ├── level1
          # │   ├── level2
          # │   │   └── .bundler-resolutions.yml
          # │   ├── other
          # │   │   └── Gemfile
          # │   │   └── PWD location
          nested_dir = File.join(dir, "level1", "level2")
          FileUtils.mkdir_p(nested_dir)
          other_dir = File.join(dir, "level1", "other")
          FileUtils.mkdir_p(other_dir)

          # Create config file in the nested_dir dir
          config_path = File.join(nested_dir, ".bundler-resolutions.yml")
          File.write(config_path, valid_yaml)

          Dir.chdir(other_dir) do
            expect { described_class.load_config }
              .to raise_error(/Could not find .bundler-resolutions.yml/)
          end
        end
      end

      it "does use a configuration file which is above BUNDLE_GEMFILE, but not above pwd" do
        Dir.mktmpdir do |dir|
          # Tree structure:
          # dir
          # ├── level1
          # │   ├── level2
          # │   │   └── .bundler-resolutions.yml
          # │   │   └── BUNDLE_GEMFILE location
          # │   ├── other
          # │   │   └── PWD location
          nested_dir = File.join(dir, "level1", "level2")
          FileUtils.mkdir_p(nested_dir)
          other_dir = File.join(dir, "level1", "other")
          FileUtils.mkdir_p(other_dir)

          # Create config file in the nested_dir dir
          config_path = File.join(nested_dir, ".bundler-resolutions.yml")
          File.write(config_path, valid_yaml)

          Dir.chdir(other_dir) do
            ClimateControl.modify BUNDLE_GEMFILE: File.join(nested_dir, "Gemfile") do
              # This should find the config file in the nested_dir dir
              described_class.load_config
            end
          end
        end
      end
    end

    it "raises an error if no config file is found" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          expect { described_class.load_config }
            .to raise_error(/Could not find .bundler-resolutions.yml/)
        end
      end
    end
  end
end
