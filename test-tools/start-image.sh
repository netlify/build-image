#!/bin/bash

BASE_PATH=$(PWD)
REPO_PATH=$(cd $1 &&  pwd)

docker run --rm -t -i \
	-v ${REPO_PATH}:/opt/repo \
	-v ${BASE_PATH}/run-build-function.sh:/usr/local/bin/ \
	netlify/build /bin/bash
