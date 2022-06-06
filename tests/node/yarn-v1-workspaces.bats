#!/usr/bin/env bats

load '../helpers.sh'

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  TMP_DIR=$(setup_tmp_dir)
  REPO_DIR="${TMP_DIR}/repo"
  DEPENDENCY_NAME="some-dependency"
  set_fixture_as_repo 'yarn-v1-workspaces' "$TMP_DIR"


  # Load functions
  load '../../run-build-functions.sh'

  local js_workspaces=$TMP_DIR/cache/js-workspaces

  # Create the directories that should be restored
  # from cache
  mkdir -p $js_workspaces/node_modules/$DEPENDENCY_NAME
  mkdir -p $js_workspaces/workspace-a/node_modules/$DEPENDENCY_NAME
  mkdir -p $js_workspaces/workspace-b/node_modules/$DEPENDENCY_NAME

  source_nvm
}

teardown() {
  rm -rf "$TMP_DIR"

  # Return to original dir
  cd - || return
}

@test 'project uses yarn v1' {
 run yarn --version
 assert_output '1.22.10'
}

@test 'restore_node_modules correctly restores workspace dependencies' {
  # Make sure that the directories we'll restore from the cache
  # do not exist yet
  assert_dir_not_exist $REPO_DIR/node_modules/$DEPENDENCY_NAME
  assert_dir_not_exist $REPO_DIR/workspace-a/node_modules/$DEPENDENCY_NAME
  assert_dir_not_exist $REPO_DIR/workspace-b/node_modules/$DEPENDENCY_NAME

  # I couldn't find a way to use multiline string assertions
  # in bats, that's why I can't use `assert_output` here
  logs=$(restore_node_modules 'yarn' | paste -s -d ',')
  assert_equal "$logs" "yarn workspaces detected,Started restoring workspace workspace-a node modules,Finished restoring workspace workspace-a node modules,Started restoring workspace workspace-b node modules,Finished restoring workspace workspace-b node modules,Started restoring workspace root node modules,Finished restoring workspace root node modules"

  # Check if the all the dependencies have been restored
  assert_dir_exist $REPO_DIR/node_modules/$DEPENDENCY_NAME
  assert_dir_exist $REPO_DIR/workspace-a/node_modules/$DEPENDENCY_NAME
  assert_dir_exist $REPO_DIR/workspace-b/node_modules/$DEPENDENCY_NAME
}
