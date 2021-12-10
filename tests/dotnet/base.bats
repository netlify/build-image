#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'


setup() {
  source_nvm
}

@test 'dotnet version 6.0 is installed and available at startup' {

  run dotnet --version
  assert_output --partial "6.0"

