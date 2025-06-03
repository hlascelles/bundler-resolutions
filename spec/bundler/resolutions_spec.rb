# frozen_string_literal: true

require "spec_helper"

describe Bundler::Resolutions do
  let(:valid_config_hash) { { "gems" => { "thor" => "1.3.1" } } }

  describe "#constrain_versions_for" do
    let(:resolutions) { described_class.new(valid_config_hash) }
    let(:package) { instance_double(Bundler::Resolver::Package, name: "thor") }
    let(:version_1_3_1) {
      instance_double(Bundler::Resolver::Candidate, version: Gem::Version.new("1.3.1"))
    }
    let(:version_1_2_0) {
      instance_double(Bundler::Resolver::Candidate, version: Gem::Version.new("1.2.0"))
    }

    it "filters versions according to requirements" do
      packages = [version_1_3_1, version_1_2_0]

      result = resolutions.constrain_versions_for(packages, package)
      expect(result).to contain_exactly(version_1_3_1)
    end

    it "returns all versions when no requirement exists for package" do
      unknown_package = instance_double(Bundler::Resolver::Package, name: "unknown")
      packages = [version_1_3_1, version_1_2_0]

      result = resolutions.constrain_versions_for(packages, unknown_package)
      expect(result).to contain_exactly(version_1_3_1, version_1_2_0)
    end
  end
end
