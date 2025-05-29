# frozen_string_literal: true

require "spec_helper"

context "with bundler #{TEST_WITH_BUNDLER_VERSION} when handling concrete dependencies" do
  # Expect the right thor version, even though a higher one is available and otherwise valid
  let(:expected_gem_specs_versions) {
    {
      "colorize" => "1.1.0",
      "dememoize" => "0.1.0",
      "figjam" => "1.6.1",
      "thor" => "1.3.1", # Brought in by figjam, but pinned by bundler-resolutions
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions colorize dememoize figjam] }
  let(:expected_dependency_versions) {
    {
      # Does not have ">=0" simply as it was in the Gemfile with no version
      "colorize" => "= 1.1.0",
      "figjam" => "> 1.5.0, < 1.6.2", # One from the Gemfile, one from the resolutions file
    }
  }

  it "runs the lockfile test" do
    expect(run_lockfile_test(__dir__)).to be true
  end
end
