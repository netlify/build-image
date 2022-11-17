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

: ${NETLIFY_IMAGE="netlify/build:focal"}
: ${NODE_VERSION="10"}
: ${RUBY_VERSION="2.6.2"}
: ${YARN_VERSION="1.13.0"}
: ${PNPM_VERSION="7.13.4"}
: ${NPM_VERSION=""}
: ${HUGO_VERSION="0.54.0"}
: ${PHP_VERSION="5.6"}
: ${GO_VERSION="1.12"}
: ${SWIFT_VERSION="5.2"}
: ${PYTHON_VERSION="2.7"}

# used in monorepos to specify in which path it should build like `packages/my-website`
NETLIFY_PACKAGE_DIR=""
# the build command of the user
CMD="$2"

if [ -n "$3" ]; then
  NETLIFY_PACKAGE_DIR="$2"
  CMD="$3"
fi

SCRIPT="/opt/build-bin/build $CMD"
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


docker run --rm \
       -e NODE_VERSION \
       -e RUBY_VERSION \
       -e YARN_VERSION \
       -e PNPM_VERSION \
       -e NPM_VERSION \
       -e HUGO_VERSION \
       -e PHP_VERSION \
       -e NETLIFY_VERBOSE \
       -e GO_VERSION \
       -e GO_IMPORT_PATH \
       -e SWIFT_VERSION \
       -e NETLIFY_PACKAGE_DIR="$NETLIFY_PACKAGE_DIR" \
       -v "${REPO_PATH}:/opt/buildhome/repo" \
       -v "${BASE_PATH}/run-build.sh:/opt/build-bin/build" \
       -v "${BASE_PATH}/tests/get-build-info.mjs:/opt/buildhome/get-build-info.mjs" \
       -v "${BASE_PATH}/package.json:/opt/buildhome/package.json" \
       -v "${BASE_PATH}/package-lock.json:/opt/buildhome/package-lock.json" \
       -v "${BASE_PATH}/run-build-functions.sh:/opt/build-bin/run-build-functions.sh" \
       -v $PWD/$T/cache:/opt/buildhome/cache \
       -w /opt/build \
       -it \
       $NETLIFY_IMAGE $SCRIPT
