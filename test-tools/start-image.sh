#!/bin/bash

BASE_PATH=$(readlink -f $(dirname $(dirname $0)))
REPO_PATH=$(readlink -f $1)

docker run --rm -t -i \
	-v ${REPO_PATH}:/opt/repo \
	-v ${BASE_PATH}/run-build-function.sh:/usr/local/bin/ \
	netlify/build /bin/bash
