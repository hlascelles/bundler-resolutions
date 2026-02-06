# frozen_string_literal: true

require "spec_helper"

# This test reproduces GitHub issue #46:
# When changing a resolution version requirement with multiple platforms in the lockfile,
# it should properly trigger re-resolution instead of causing a confusing
# "Could not find gems valid for all resolution platforms" error.
ctx = "with bundler #{TEST_WITH_BUNDLER_VERSION} when resolution changes with multiple platforms"
context ctx do
  let(:expected_gem_specs_versions) {
    {
      "figjam" => "1.6.2",
      "thor" => "1.5.0", # Should be upgraded from 1.3.0 to satisfy ">= 1.3.1"
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions figjam] }

  it "runs the lockfile test" do
    expect_lockfile_test_to_succeed(__dir__)
  end
end
