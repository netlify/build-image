#!/bin/bash

# Sets a given fixture as the project to be used as the target repository for our build-image scripts.
# It expects a fixture name which should be present in a relative dir named `./fixtures` from the bats test executing it.
# It sets the global `NETLIFY_BUILD_BASE`, `NETLIFY_CACHE_DIR` and `NETLIFY_REPO_DIR` variables based on the provided directory.

# Arguments:
#   $1 - fixture name
#   $2 - path to use as the repo base (ideally a temporary dir)
set_fixture_as_repo() {
  local fixture="$1"
  local tmp_dir="$2"
  NETLIFY_BUILD_BASE=$tmp_dir
  NETLIFY_CACHE_DIR="$NETLIFY_BUILD_BASE/cache"
  NETLIFY_REPO_DIR="$NETLIFY_BUILD_BASE/repo"
  rm -rf "$NETLIFY_REPO_DIR"
  cp -r "$BATS_TEST_DIRNAME/fixtures/$fixture" "$NETLIFY_REPO_DIR"

  # Change to the repo dir
  cd "$NETLIFY_REPO_DIR" || exit 1
}

# Setups a tmp dir to be used for test purposes.
setup_tmp_dir() {
  mktemp -d
}

# Sources nvm.sh, in order for node and npm binaries to be accessible
source_nvm() {
  # Disable shellcheck's source file check
  # shellcheck source=/dev/null
  source ~/.nvm/nvm.sh
}
