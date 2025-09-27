# frozen_string_literal: true

require "spec_helper"

context "with bundler #{TEST_WITH_BUNDLER_VERSION} when the yaml gems are not needed" do
  # No thor, as it is only mentioned in resolutions
  let(:expected_gem_specs_versions) {
    {
      "dememoize" => "0.1.0",
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize] }

  it "prevents Gemfile.lock presence" do
    expect_lockfile_test_to_succeed(__dir__)
  end
end
