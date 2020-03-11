#!/bin/bash

# Usage: test-tools/test-build.sh PATH_TO_GIT_REPO BUILD_COMMAND
#
# Example with clean git clone:
#   test-tools/test-build.sh ../netlify-cms 'npm run build'
#
# Example with previous cached build:
#   T=/tmp/cache script/test-build.sh ../netlify-cms 'npm run build'

set -e

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

: ${NETLIFY_IMAGE="netlify/build"}
: ${NODE_VERSION="10"}
: ${RUBY_VERSION="2.6.2"}
: ${YARN_VERSION="1.13.0"}
: ${NPM_VERSION=""}
: ${HUGO_VERSION="0.54.0"}
: ${PHP_VERSION="5.6"}
: ${GO_VERSION="1.12"}

BASE_PATH=$(pwd)
REPO_PATH="$(cd $1 && pwd)"

mkdir -p tmp
if [ $(uname -s) == "Darwin" ]; then
  : ${T=`mktemp -d tmp/tmp.XXXXXXXXXX`}
else
  : ${T=`mktemp -d -p tmp`}
fi

echo "Using temp cache dir: $T/cache"
chmod +w $T
mkdir -p $T/cache
chmod a+w $T/cache

SCRIPT="/usr/local/bin/build $2"

docker run --rm \
       -e NODE_VERSION \
       -e RUBY_VERSION \
       -e YARN_VERSION \
       -e NPM_VERSION \
       -e HUGO_VERSION \
       -e PHP_VERSION \
       -e NETLIFY_VERBOSE \
       -e GO_VERSION \
       -e GO_IMPORT_PATH \
       -v "${REPO_PATH}:/opt/repo" \
       -v "${BASE_PATH}/run-build.sh:/usr/local/bin/build" \
       -v "${BASE_PATH}/run-build-functions.sh:/usr/local/bin/run-build-functions.sh" \
       -v $PWD/$T/cache:/opt/buildhome/cache \
       -w /opt/build \
       -it \
       $NETLIFY_IMAGE $SCRIPT
