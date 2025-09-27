# frozen_string_literal: true

require "spec_helper"

context "with bundler #{TEST_WITH_BUNDLER_VERSION} when preventing DEPENDENCY presence" do
  # Expect the right thor version, even though a higher one is available and otherwise valid
  let(:expected_gem_specs_versions) {
    {
      "dememoize" => "0.1.0",
      "figjam" => "1.6.2",
      "thor" => "1.3.1", # Brought in by figjam, but pinned by bundler-resolutions
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize figjam] }

  it "runs the lockfile test" do
    expect_lockfile_test_to_succeed(__dir__)
  end
end
