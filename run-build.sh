#!/bin/bash

dir="$(dirname "$0")"
: ${NETLIFY_REPO_URL="/opt/repo"}
NETLIFY_BUILD_BASE="/opt/buildhome"

cmd=$*

BUILD_COMMAND_PARSER=$(cat <<EOF
$cmd
EOF
)

. "$dir/run-build-functions.sh"

if [[ ! -d $NETLIFY_REPO_DIR ]]; then
  git clone $NETLIFY_REPO_URL $NETLIFY_REPO_DIR
fi

# Installing build-info to mimic the behaviour of buildbot on retrieving the build information
# this is needed to collect packageManager + js workspace info
cd "$NETLIFY_BUILD_BASE" || exit
source ~/.nvm/nvm.sh
# We need to install with `--legacy-peer-deps` because of:
# https://github.com/bats-core/bats-assert/issues/27
npm install --legacy-peer-deps
defaultBuildInfo=$(node "$NETLIFY_BUILD_BASE/get-build-info.mjs" "$NETLIFY_REPO_DIR" "$NETLIFY_PACKAGE_DIR")

# cd into the repo + the base directory
cd "$NETLIFY_REPO_DIR/$NETLIFY_PACKAGE_DIR" || exit

: "${NODE_VERSION="16"}"
: "${RUBY_VERSION="2.7.2"}"
: "${YARN_VERSION="1.22.19"}"
: "${PNPM_VERSION="7.13.4"}"
: "${GO_VERSION="1.19.x"}"
: "${PYTHON_VERSION="3.8"}"
: "${BUILD_INFO="$defaultBuildInfo"}"
: "${FEATURE_FLAGS="build-image_use_new_package_manager_detection"}"

echo "Installing dependencies"
install_dependencies "$NODE_VERSION" "$RUBY_VERSION" "$YARN_VERSION" "$PNPM_VERSION" "$GO_VERSION" "$PYTHON_VERSION" "$BUILD_INFO" "$FEATURE_FLAGS"

echo "Installing missing commands"
install_missing_commands

echo "Verify run directory"
set_go_import_path

echo "Executing user command: $cmd"
eval "$cmd"
CODE=$?

cache_artifacts

exit $CODE
