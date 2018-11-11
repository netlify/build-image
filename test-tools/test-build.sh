#!/bin/bash

# Usage: script/test-build.sh PATH_TO_GIT_REPO BUILD_COMMAND
#
# Example with clean git clone:
# 	./test-build.sh ../netlify-cms 'npm run build'
#
# Example with previous cached build:
#	T=/tmp/cache script/test-build.sh ../netlify-cms 'npm run build'

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

set -e

: ${NETLIFY_IMAGE="netlify/build"}
: ${NODE_VERSION="8"}
: ${RUBY_VERSION="2.3.6"}
: ${YARN_VERSION="1.3.2"}
: ${NPM_VERSION=""}
: ${HUGO_VERSION="0.20"}
: ${PHP_VERSION="5.6"}
: ${GO_VERSION="1.10"}

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
chmod a+w $T/cache

cp run-build* $T/scripts
chmod +x $T/scripts/*

rm -rf $T/repo
git clone $REPO_URL $T/repo

SCRIPT="/opt/buildhome/scripts/run-build.sh $2"

docker run --rm \
	-e "NODE_VERSION=$NODE_VERSION" \
	-e "RUBY_VERSION=$RUBY_VERSION" \
	-e "YARN_VERSION=$YARN_VERSION" \
	-e "NPM_VERSION=$NPM_VERSION" \
	-e "HUGO_VERSION=$HUGO_VERSION" \
	-e "PHP_VERSION=$PHP_VERSION" \
	-e "NETLIFY_VERBOSE=$NETLIFY_VERBOSE" \
	-e "GO_VERSION=$GO_VERSION" \
	-e "GO_IMPORT_PATH=$GO_IMPORT_PATH" \
	-v $PWD/$T/scripts:/opt/buildhome/scripts \
	-v $PWD/$T/repo:/opt/buildhome/repo \
	-v $PWD/$T/cache:/opt/buildhome/cache \
	-w /opt/build \
	-it \
	$NETLIFY_IMAGE $SCRIPT
