#!/bin/bash

# Clones a repo.
#
# Arguments:
#   $1 - repo url
#   $2 - path to clone into
clone_repo() {
  local url="$1"
  local path="$2"
  git clone --depth 1 ${url} ${path} >&3
}


# Setups a tmp dir to be used for test purposes.
setup_tmp_dir() {
  echo $(mktemp -d)
}
