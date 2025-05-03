# frozen_string_literal: true

require "spec_helper"

context "when bundle install on an otherwise valid lockfile" do
  # This tackles the scenario when the lockfile is self-consistent, but a gem has been removed.
  let(:expected_gem_specs_versions) {
    {
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
      "dememoize" => "0.1.0",
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize] }

  it "runs the lockfile test" do
    expect(run_lockfile_test(__dir__)).to be true
  end
end
