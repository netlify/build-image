#!/bin/bash

BASE_PATH=$(PWD)
REPO_PATH=$(cd $1 &&  pwd)

docker run --rm -t -i \
	-v ${REPO_PATH}:/opt/repo \
	-v ${BASE_PATH}/run-build.sh:/usr/local/bin/build \
	-v ${BASE_PATH}/run-build-functions.sh:/usr/local/bin/run-build-functions.sh \
	netlify/build /bin/bash
