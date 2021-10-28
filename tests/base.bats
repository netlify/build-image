#!/usr/bin/env bats

load "./helpers.sh"

load '../node_modules/bats-support/load'
load '../node_modules/bats-assert/load'

@test '/opt/buildhome folder owner and group is buildbot' {
  local owner=$(stat -c '%U:%G' /opt/buildhome)
  assert_equal $owner "buildbot:buildbot"
}

@test 'NF_IMAGE_VERSION is set and exists' {
  assert [ -n $NF_IMAGE_VERSION ]
}

@test 'NF_IMAGE_TAG is set and exists' {
  assert [ -n $NF_IMAGE_TAG ]
}

@test 'NF_IMAGE_NAME is set to focal' {
  assert_equal $NF_IMAGE_NAME "focal"
}
