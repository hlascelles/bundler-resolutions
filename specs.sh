#! /usr/bin/env bash
set -euo pipefail

cd "${0%/*}"
TEST_WITH_BUNDLER_VERSION=2.5.14 bin/rspec
TEST_WITH_BUNDLER_VERSION=2.6.7 bin/rspec
