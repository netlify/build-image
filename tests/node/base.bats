#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'


NODE_VERSION=12.18.0

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
