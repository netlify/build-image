#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  TMP_DIR=$(setup_tmp_dir)
  set_fixture_as_repo 'simple-node' "$TMP_DIR"

  # Load functions
  load '../../run-build-functions.sh'

  source_nvm
}

teardown() {
  rm -rf "$TMP_DIR"
  # Return to original dir
  cd - || return
}

@test 'run_pnpm with a new pnpm version' {
  local newPnpmVersion=6.32.20
  # We can't use bats `run` because environmental changes aren't persisted
  # We also need to ignore the exit code as the test env is set to return on any non-zero exit code, which we use for
  # our workspaces checks
  run_pnpm $newPnpmVersion || true > /dev/null 2>&1

  # New pnpm binary is set in PATH
  run pnpm --version
  assert_output $newPnpmVersion
}

@test 'run_pnpm installs a new pnpm version if different from the one installed, installs deps and creates cache dir' {
  local newPnpmVersion=6.32.20
  run run_pnpm $newPnpmVersion
  assert_success
  assert_output --partial "Installing npm packages using pnpm version $newPnpmVersion"
  assert_dir_exist '/opt/buildhome/.pnpm-store'

  # The cache dir is actually being used
  assert_dir_exist "/opt/buildhome/.pnpm-store/v3"
}

@test 'run_pnpm should exit and fail when trying to be used on a to old node version' {
  local newPnpmVersion=6.32.20

  run bash -c ". '/opt/build-bin/run-build-functions.sh' && install_node 12 && run_pnpm $newPnpmVersion"
  assert_failure
  assert_output --partial "Error while installing pnpm $newPnpmVersion"
}
