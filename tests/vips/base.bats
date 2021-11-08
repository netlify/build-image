#!/usr/bin/env bats

load "../helpers.sh"

load '../../node_modules/bats-support/load'
load '../../node_modules/bats-assert/load'

@test 'vips is installed and CLI tools are available' {
  run vips
  assert_success
}
