# frozen_string_literal: true

require "spec_helper"

context "when preventing DEPENDENCY presence" do
  # Expect the right thor version, even though a higher one is available and otherwise valid
  let(:expected_gem_specs_versions) {
    {
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
      "dememoize" => "0.1.0",
      "figjam" => "1.6.2",
      "thor" => "1.3.1", # Brought in by figjam, but pinned by bundler-resolutions
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize figjam] }

  it "runs the lockfile test" do
    expect(run_lockfile_test(__dir__)).to be true
  end
end
