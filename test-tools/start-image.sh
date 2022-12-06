#!/bin/bash

BASE_PATH=$(pwd)
REPO_PATH=$(cd $1 && pwd)
: "${NETLIFY_IMAGE="netlify/build:focal"}"

docker run --rm -t -i \
  -e NODE_VERSION \
  -e NPM_VERSION \
  -e RUBY_VERSION \
  -e YARN_VERSION \
  -e PNPM_VERSION \
  -e HUGO_VERSION \
  -e PHP_VERSION \
  -e GO_VERSION \
  -e SWIFT_VERSION \
  -e PYTHON_VERSION \
  -v "${REPO_PATH}:/opt/buildhome/repo" \
  -v "${BASE_PATH}/run-build.sh:/opt/build-bin/build" \
  -v "${BASE_PATH}/tests/get-build-info.mjs:/opt/buildhome/get-build-info.mjs" \
  -v "${BASE_PATH}/package.json:/opt/buildhome/package.json" \
  -v "${BASE_PATH}/package-lock.json:/opt/buildhome/package-lock.json" \
  -v ${BASE_PATH}/run-build-functions.sh:/opt/build-bin/run-build-functions.sh \
  "$NETLIFY_IMAGE" /bin/bash
