#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  # Load functions
  load '../../run-build-functions.sh'
}

@test 'go version 1.17 at the latest patch is installed and available at startup by default' {
  run install_go
  assert_success
  # we can't specify which patch version because it will change
  assert_output --partial "Installing Go version 1.17."
  assert_output --partial "go version go1.17."
}

@test 'install custom go version' {
  local customGoVersion=1.16.4
  run install_go $customGoVersion
  assert_success
  assert_output --partial "Installing Go version 1.16.4"
  assert_output --partial "go version go1.16.4 linux/amd64"
}