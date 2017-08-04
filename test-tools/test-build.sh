#!/bin/bash

# Usage: script/test-build.sh PATH_TO_GIT_REPO BUILD_COMMAND
#
# Example with clean git clone:
# 	./test-build.sh ../netlify-cms 'npm run build'
#
# Example with previous cached build:
#	T=/tmp/cache script/test-build.sh ../netlify-cms 'npm run build'

set -e

: ${NODE_VERSION="6"}
: ${RUBY_VERSION="2.3"}
: ${YARN_VERSION="0.18.0"}
: ${NPM_VERSION=""}

REPO_URL=$1

mkdir -p tmp
if [ $(uname -s) == "Darwin" ]; then
  : ${T=`mktemp -d tmp/tmp.XXXXXXXXXX`}
else
  : ${T=`mktemp -d -p tmp`}
fi

echo "Using temp dir: $T"
chmod +w $T
mkdir -p $T/scripts
mkdir -p $T/cache

cp run-build* $T/scripts
chmod +x $T/scripts/*

rm -rf $T/repo
git clone $REPO_URL $T/repo

SCRIPT="/opt/buildhome/scripts/run-build.sh $2"

docker run --rm \
	-e "NETLIFY_VERBOSE=1" \
	-e "NODE_VERSION=\"$NODE_VERSION\"" \
	-e "RUBY_VERSION=\"$RUBY_VERSION\"" \
	-e "YARN_VERSION=\"$YARN_VERSION\"" \
	-e "NPM_VERSION=\"$NPM_VERSION\"" \
	-v $PWD/$T/scripts:/opt/buildhome/scripts \
	-v $PWD/$T/repo:/opt/buildhome/repo \
	-v $PWD/$T/cache:/opt/buildhome/cache \
	-w /opt/build \
	-it \
	netlify/build $SCRIPT
