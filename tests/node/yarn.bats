#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

YARN_CACHE_DIR=/opt/buildhome/.yarn_cache

# So that we can speed up the `run_yarn` function and not require new yarn installs for tests
YARN_DEFAULT_VERSION=1.22.10

# So that we can backup the default installation of yarn
YARN_DEFAULT_INSTALLATION_DIR=/opt/buildhome/.yarn
YARN_DEFAULT_INSTALLATION_BACKUP=/opt/buildhome/yarn-default-installation

setup_file() {
  # We have to backup the default installation of yarn, because some of
  # the tests in this file execute the `run_yarn` function, which
  # removes the default installation.
  mkdir $YARN_DEFAULT_INSTALLATION_BACKUP
  cp -r $YARN_DEFAULT_INSTALLATION_DIR/*  $YARN_DEFAULT_INSTALLATION_BACKUP
}

teardown_file() {
  # Restore the default yarn installation
  assert_dir_not_exist $YARN_DEFAULT_INSTALLATION_DIR
  assert_dir_exist $YARN_DEFAULT_INSTALLATION_BACKUP
  mv $YARN_DEFAULT_INSTALLATION_BACKUP $YARN_DEFAULT_INSTALLATION_DIR
}

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

@test 'yarn 1.22.10 is installed and available by default' {
  run yarn --version
  assert_output $YARN_DEFAULT_VERSION
}

@test 'run_yarn with a new yarn version correctly sets the new yarn binary in PATH' {
  local newYarnVersion=1.21.0
  # We can't use bats `run` because environmental changes aren't persisted
  # We also need to ignore the exit code as the test env is set to return on any non-zero exit code, which we use for
  # our workspaces checks
  run_yarn $newYarnVersion || true > /dev/null 2>&1

  # New yarn binary is set in PATH
  run yarn --version
  assert_output $newYarnVersion
}

@test 'run_yarn installs a new yarn version if different from the one installed, installs deps and creates cache dir' {
  local newYarnVersion=1.21.0
  run run_yarn $newYarnVersion
  assert_success
  assert_output --partial "Installing yarn at version $newYarnVersion"
  assert_dir_exist $YARN_CACHE_DIR

  # The cache dir is actually being used
  assert_dir_exist "$YARN_CACHE_DIR/v6"
}

@test 'run_yarn allows passing multiple yarn flags via YARN_FLAGS env var to yarn install' {
  YARN_FLAGS="--no-default-rc --verbose"
  run run_yarn $YARN_DEFAULT_VERSION

  assert_success
  # The flags we pass on both produce verbose output and omit any reference to checking for configuration files
  assert_output --partial "verbose"
  refute_output --partial "Checking for configuration file"
}

@test 'run_yarn does not allow setting --cache-folder via YARN_FLAGS' {
  local tmpCacheDir="./local-cache"

  YARN_FLAGS="--no-default-rc --verbose --cache-folder $tmpCacheDir"
  run run_yarn $YARN_DEFAULT_VERSION

  assert_success

  # The cache dir is actually being used
  assert_dir_exist "$YARN_CACHE_DIR/v6"
  assert_dir_not_exist "$tmpCacheDir"
}
