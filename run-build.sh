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

# In production, these default versions are pinned on site creation and set by buildbot/bitballoon
DEFAULT_NODE_VERSION="16"
DEFAULT_RUBY_VERSION="2.7.2"
DEFAULT_YARN_VERSION="1.22.10"

echo "Installing dependencies"
install_dependencies $DEFAULT_NODE_VERSION $DEFAULT_RUBY_VERSION $DEFAULT_YARN_VERSION

echo "Installing missing commands"
install_missing_commands

echo "Verify run directory"
set_go_import_path

echo "Executing user command: $cmd"
eval "$cmd"
CODE=$?

cache_artifacts

exit $CODE
