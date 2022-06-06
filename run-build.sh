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
cd $NETLIFY_REPO_DIR

: ${NODE_VERSION="16"}
: ${RUBY_VERSION="2.7.2"}
: ${YARN_VERSION="1.22.10"}
: ${GO_VERSION="1.17.5"}
: ${PYTHON_VERSION="3.8"}

echo "Installing dependencies"
install_dependencies $NODE_VERSION $RUBY_VERSION $YARN_VERSION $GO_VERSION $PYTHON_VERSION

echo "Installing missing commands"
install_missing_commands

echo "Verify run directory"
set_go_import_path

echo "Executing user command: $cmd"
eval "$cmd"
CODE=$?

cache_artifacts

exit $CODE
