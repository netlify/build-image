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

NODE_VERSION=16

@test 'node version ${NODE_VERSION} is installed and available at startup' {
  run node --version
  assert_success
  assert_output --partial $NODE_VERSION
}

@test 'grunt-cli is installed and available at startup' {
  run grunt --version
  assert_success
}

@test 'bower is installed and available at startup' {
  run bower --version
  assert_success
}

@test 'install_node should create an npmrc file' {
  local npm_rc="//npm.pkg.github.com/:_authToken=${GITHUB_PACKAGES_SECRET}\n@netlify:registry=https://npm.pkg.github.com/"
  NPM_RC=$npm_rc

  install_node "16"

  assert_success
  assert_file_exist ".npmrc"
}
