#!/bin/bash

dir="$(dirname "$0")"

: ${NETLIFY_REPO_URL="/opt/repo"}

NETLIFY_BUILD_BASE="/opt/buildhome"
NETLIFY_CACHE_DIR="$NETLIFY_BUILD_BASE/cache"
NETLIFY_REPO_DIR="$NETLIFY_BUILD_BASE/repo"

cmd=$*

BUILD_COMMAND_PARSER=$(cat <<EOF
$cmd
EOF
)

mkdir -p $NETLIFY_CACHE_DIR
rm -rf $NETLIFY_BUILD_BASE/.yarn

cd $NETLIFY_BUILD_BASE
if [[ ! -d $NETLIFY_REPO_DIR ]]; then
  git clone $NETLIFY_REPO_URL $NETLIFY_REPO_DIR
fi
cd $NETLIFY_REPO_DIR

. "$dir/run-build-functions.sh"

: ${NODE_VERSION="6.10.2"}
: ${RUBY_VERSION="2.1.2"}
: ${YARN_VERSION="0.18.1"}

echo "Installing dependencies: node=$NODE_VERSION ruby=$RUBY_VERSION yarn=$YARN_VERSION"
install_dependencies $NODE_VERSION $RUBY_VERSION $YARN_VERSION

echo "Installing missing commands"
install_missing_commands

echo "Executing user command: $cmd"
$cmd
CODE=$?

echo "Caching artifacts"
cache_artifacts

exit $CODE
