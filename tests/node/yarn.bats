#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

YARN_CACHE_DIR=/opt/buildhome/.yarn_cache

setup() {
  TMP_DIR=$(setup_tmp_dir)
  set_fixture_as_repo 'simple-node' "$TMP_DIR"

  # Load functions
  load '../../run-build-functions.sh'
}

teardown() {
  rm -rf "$TMP_DIR"
  # Return to original dir
  cd - || return
}

@test 'run_yarn sets up new yarn version if different from the one installed, installs deps and creates cache dir' {
  local newYarnVersion=1.21.0
  run run_yarn $newYarnVersion
  assert_success
  assert_output --partial "Installing yarn at version $newYarnVersion"
  assert_dir_exist $YARN_CACHE_DIR

  # The cache dir is actually being used
  assert_dir_exist "$YARN_CACHE_DIR/v6"
}
