#! /usr/bin/env bash
set -euo pipefail

cd "${0%/*}"
export BUNDLER_VERSION=2.6.7
echo "Running specs with Bundler version $BUNDLER_VERSION"
bundle check || bundle install
bin/rspec
export BUNDLER_VERSION=2.7.1
echo "Running specs with Bundler version $BUNDLER_VERSION"
bundle check || bundle install
bin/rspec
