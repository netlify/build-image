#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

YARN_CACHE_DIR=/opt/buildhome/.yarn_cache
NEW_YARN_VERSION=1.21.0

setup() {
  # Make sure the cache dir is clear
  rm -rf '/opt/buildhome/.yarn_cache'

  TMP_DIR=$(setup_tmp_dir)
  REPO_DIR="$TMP_DIR/netlify-cms"
  clone_repo https://github.com/netlify/netlify-cms.git $REPO_DIR

  # Load functions
  load '../../run-build-functions.sh'

  # Change to the repo dir
  cd $REPO_DIR
}

teardown() {
  rm -rf $TMP_DIR
  # Return to original dir
  cd -
}

@test 'run_yarn setups new yarn version, installs deps and creates cache dir' {
  run run_yarn $NEW_YARN_VERSION
  assert_success
  assert_output --partial "doesn't match expected ($NEW_YARN_VERSION)"
  assert_dir_exist $YARN_CACHE_DIR
}
