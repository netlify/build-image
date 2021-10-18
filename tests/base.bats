#!/usr/bin/env bats

load "./helpers.sh"

load '../node_modules/bats-support/load'
load '../node_modules/bats-assert/load'

@test '/opt/buildhome folder owner and group is buildbot' {
  local owner=$(stat -c '%U:%G' /opt/buildhome)
  assert_equal $owner "buildbot:buildbot"
}
