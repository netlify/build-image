#!/bin/bash

BASE_PATH=$(pwd)
REPO_PATH=$(cd $1 && pwd)
: ${NETLIFY_IMAGE="netlify/build:xenial"}

docker run --rm -t -i \
	-e NODE_VERSION \
	-e NPM_VERSION \
	-e RUBY_VERSION \
	-e YARN_VERSION \
	-e HUGO_VERSION \
	-e PHP_VERSION \
	-e GO_VERSION \
	-e SWIFT_VERSION \
	-v ${REPO_PATH}:/opt/repo \
	-v ${BASE_PATH}/run-build.sh:/usr/local/bin/build \
	-v ${BASE_PATH}/run-build-functions.sh:/usr/local/bin/run-build-functions.sh \
	$NETLIFY_IMAGE /bin/bash
