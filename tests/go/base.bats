#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'
load '../../node_modules/bats-file/load'

setup() {
  # Load functions
  load '../../run-build-functions.sh'
}

@test 'go version 1.19 at the latest patch is installed and available at startup by default' {
  run install_go
  assert_success
  # we can't specify which patch version because it will change
  # Also no message about installation will be shown because it is the default already installed version
  refute_output --partial "Installing Go version 1.19."
  assert_output --partial "go version go1.19."
}

@test 'go version 1.19 at the latest patch is installed and available at startup by default when specifying default version' {
  run install_go $GIMME_GO_VERSION
  assert_success
  # we can't specify which patch version because it will change
  # Also no message about installation will be shown because it is the default already installed version
  refute_output --partial "Installing Go version 1.19."
  assert_output --partial "go version go1.19."
}

@test 'an unresolvable go version fails script' {
  run install_go "notaversion"
  assert_failure
  assert_output --partial "Failed to resolve Go version 'notaversion'"
  refute_output --partial "Installing Go version"
  refute_output --partial "go version go"
}

@test 'install custom go version' {
  local customGoVersion=1.16.4
  run install_go $customGoVersion
  assert_success
  assert_output --partial "Installing Go version 1.16.4"
  assert_output --partial "go version go1.16.4"
}
