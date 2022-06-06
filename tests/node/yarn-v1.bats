#!/usr/bin/env bats

load '../helpers.sh'

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  TMP_DIR=$(setup_tmp_dir)
  REPO_DIR="${TMP_DIR}/repo"
  DEPENDENCY_NAME="some-dependency"
  set_fixture_as_repo 'simple-node' "$TMP_DIR"


  # Load functions
  load '../../run-build-functions.sh'

  # Create a fake dependency that should be restored
  # from cache
  mkdir $TMP_DIR/cache/node_modules/$DEPENDENCY_NAME

  source_nvm
}

teardown() {
  rm -rf "$TMP_DIR"

  # Return to original dir
  cd - || return
}

@test 'project uses yarn 1.x' {
  run yarn --version
  assert_output '1.22.10'
}

@test 'restore_node_modules correctly restores dependencies' {
  # Make sure that that directory we'll restore from the cache
  # does not exist
  assert_dir_not_exist $REPO_DIR/node_modules/$DEPENDENCY_NAME

  # I couldn't find a way to use multiline string assertions
  # in bats, that's why I can't use `assert_output` here
  logs=$(restore_node_modules 'yarn' | paste -s -d ',')
  assert_equal "$logs" "No yarn workspaces detected,Started restoring cached node modules,Finished restoring cached node modules"

  assert_dir_exist $REPO_DIR/node_modules/$DEPENDENCY_NAME
}
