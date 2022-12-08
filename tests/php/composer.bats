#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  TMP_DIR=$(setup_tmp_dir)
  set_fixture_as_repo 'simple-php' "$TMP_DIR"

  # Load functions
  load '../../run-build-functions.sh'
}

teardown() {
  rm -rf "$TMP_DIR"
  # Return to original dir
  cd - || return
}

@test 'composer install' {
  run run_composer
  assert_success
  assert_output --partial "(including require-dev)"
}

@test 'composer install with flags' {
  COMPOSER_FLAGS="--no-dev"

  run run_composer
  assert_success
  refute_output --partial "(including require-dev)"
}