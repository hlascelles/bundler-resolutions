# frozen_string_literal: true

require "spec_helper"

context "with bundler #{TEST_WITH_BUNDLER_VERSION} when bundle install on an existing lockfile but the yaml has changed" do
  # This tackles the scenario when the lockfile is self-consistent, but the yaml has changed.
  let(:expected_gem_specs_versions) {
    {
      "dememoize" => "0.1.0",
      "figjam" => "1.6.2",
      "thor" => "1.3.0", # Should be lowered from 1.3.1 to 1.3.0
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize] }

  it "runs the lockfile test" do
    expect(run_lockfile_test(__dir__)).to be true
  end
end
