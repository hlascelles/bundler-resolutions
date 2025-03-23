# frozen_string_literal: true

require "spec_helper"

describe "prevents Gemfile.lock presence" do
  # No thor, as it is only mentioned in resolutions
  let(:expected_gem_specs_versions) {
    {
      "bundler-resolutions" => Bundler::Resolutions::VERSION,
      "dememoize" => "0.1.0",
    }
  }
  # No thor, as it is only mentioned in resolutions
  let(:expected_dependencies) { %w[bundler-resolutions dememoize] }

  it_behaves_like "a lockfile test", __dir__
end
