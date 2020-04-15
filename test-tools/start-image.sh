#!/bin/bash

BASE_PATH=$(pwd)
REPO_PATH=$(cd $1 && pwd)

docker run --rm -t -i \
	-e NODE_VERSION \
	-e NPM_VERSION \
	-e RUBY_VERSION \
	-e YARN_VERSION \
	-e HUGO_VERSION \
	-e PHP_VERSION \
	-e GO_VERSION \
	-v ${REPO_PATH}:/opt/buildhome/repo \
	-v ${BASE_PATH}/run-build.sh:/usr/local/bin/build \
	-v ${BASE_PATH}/run-build-functions.sh:/usr/local/bin/run-build-functions.sh \
	netlify/build:xenial /bin/bash
