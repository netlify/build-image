#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  
  NETLIFY_CACHE_DIR="/opt/buildhome/cache"
  TMP_DIR=$(setup_tmp_dir)
  NODE_VERSION=14

  set_fixture_as_repo 'simple-node' "$TMP_DIR"
  source_nvm
  load '../../run-build-functions.sh'
}

teardown() {
  rm -rf $NETLIFY_CACHE_DIR/package-sha
}

@test 'bypass_cache run pre and post install scripts' {
  run run_npm "buildbot_bypass_module_cache"
  assert_output --partial "NPM modules installed"
  refute_output --partial "Creating package sha"
}

@test 'bypass_cache avoid running pre and post install scripts' {
  run run_npm "buildbot_other_flags"
  assert_output --partial "Creating package sha"
}
