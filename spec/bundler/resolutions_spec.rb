# frozen_string_literal: true

require "spec_helper"
require "climate_control"
require "tempfile"
require "fileutils"
require "tmpdir"

describe Bundler::Resolutions do
  let(:valid_config_hash) { { "gems" => { "thor" => "1.3.1" } } }
  let(:valid_yaml) { "gems:\n  thor: \"1.3.1\"\n" }

  describe "#initialize" do
    context "with a hash config" do
      it "loads configuration from a hash" do
        resolutions = Bundler::Resolutions.new(valid_config_hash)
        expect(resolutions.resolutions["thor"]).to be_a(Gem::Requirement)
        expect(resolutions.resolutions["thor"].to_s).to eq("= 1.3.1")
      end
    end

    context "with a file path" do
      it "loads configuration from a file path" do
        Tempfile.create(["resolutions", ".yml"]) do |file|
          file.write(valid_yaml)
          file.flush

          resolutions = Bundler::Resolutions.new(file.path)
          expect(resolutions.resolutions["thor"]).to be_a(Gem::Requirement)
          expect(resolutions.resolutions["thor"].to_s).to eq("= 1.3.1")
        end
      end
    end

    context "with ENV variable" do
      it "loads configuration from ENV path" do
        Tempfile.create(%w[resolutions .yml]) do |file|
          file.write(valid_yaml)
          file.flush

          ClimateControl.modify BUNDLER_RESOLUTIONS_CONFIG: file.path do
            resolutions = Bundler::Resolutions.new
            expect(resolutions.resolutions["thor"]).to be_a(Gem::Requirement)
            expect(resolutions.resolutions["thor"].to_s).to eq("= 1.3.1")
          end
        end
      end
    end

    context "finding in directory tree" do
      it "finds configuration by traversing up directories" do
        Dir.mktmpdir do |dir|
          # Create a nested directory structure
          nested_dir = File.join(dir, "level1", "level2")
          FileUtils.mkdir_p(nested_dir)

          # Create config file in the root dir
          config_path = File.join(dir, ".bundler-resolutions.yml")
          File.write(config_path, valid_yaml)

          # Change to the nested directory and initialize without config
          Dir.chdir(nested_dir) do
            resolutions = Bundler::Resolutions.new
            expect(resolutions.resolutions["thor"]).to be_a(Gem::Requirement)
            expect(resolutions.resolutions["thor"].to_s).to eq("= 1.3.1")
          end
        end
      end

      it "raises an error if no config file is found" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            expect { Bundler::Resolutions.new }
              .to raise_error(/Could not find .bundler-resolutions.yml/)
          end
        end
      end
    end
  end

  describe "#constrain_versions_for" do
    let(:resolutions) { Bundler::Resolutions.new(valid_config_hash) }
    let(:package) { double("package", name: "thor") }
    let(:version_1_3_1) { double("version", version: Gem::Version.new("1.3.1")) }
    let(:version_1_2_0) { double("version", version: Gem::Version.new("1.2.0")) }

    it "filters versions according to requirements" do
      packages = [version_1_3_1, version_1_2_0]

      result = resolutions.constrain_versions_for(packages, package)
      expect(result).to contain_exactly(version_1_3_1)
    end

    it "returns all versions when no requirement exists for package" do
      unknown_package = double("package", name: "unknown")
      packages = [version_1_3_1, version_1_2_0]

      result = resolutions.constrain_versions_for(packages, unknown_package)
      expect(result).to contain_exactly(version_1_3_1, version_1_2_0)
    end
  end
end
