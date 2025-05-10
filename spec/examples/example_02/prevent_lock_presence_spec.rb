# frozen_string_literal: true

require "spec_helper"

context "with bundler #{TEST_WITH_BUNDLER_VERSION} when the yaml gems are not needed" do
  # No thor, as it is only mentioned in resolutions
  let(:expected_gem_specs_versions) {
    {
      "dememoize" => "0.1.0",
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize] }

  it "prevents Gemfile.lock presence" do
    expect(run_lockfile_test(__dir__)).to be true
  end
end
