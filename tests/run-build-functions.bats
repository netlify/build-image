rm -rf tmp/tests_home

export NETLIFY_BUILD_BASE=tmp/tests_build_base
export HOME=tmp/tests_home

mkdir -p $HOME

. "run-build-functions.sh"

@test "should run yarn successfully" {
  run run_yarn "1.22.4"
  [ "${lines[0]}" = "Started restoring cached yarn cache" ]
  [ "${lines[1]}" = "Finished restoring cached yarn cache" ]
  [ "${lines[2]}" = "Installing NPM modules using Yarn version 1.22.4" ]
  [ "${lines[8]}" = "NPM modules installed using Yarn" ]
}

