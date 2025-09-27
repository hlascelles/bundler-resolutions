# frozen_string_literal: true

require "spec_helper"

ctx = "with bundler #{TEST_WITH_BUNDLER_VERSION} when bundle install on an existing " \
      "lockfile but the yaml has changed"
context ctx do
  # This tackles the scenario when the lockfile is self-consistent, but the yaml has changed.
  let(:expected_gem_specs_versions) {
    {
      "dememoize" => "0.1.0",
      "figjam" => "1.6.2",
      "thor" => "1.3.0", # Should be lowered from 1.3.1 to 1.3.0
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions figjam dememoize] }

  it "runs the lockfile test" do
    expect_lockfile_test_to_succeed(__dir__)
  end
end
