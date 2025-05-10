#! /usr/bin/env bash
set -euo pipefail

cd "${0%/*}"
BUNDLER_VERSION=2.6.7 bin/rspec
BUNDLER_VERSION=2.5.14 bin/rspec
