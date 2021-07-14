#!/usr/bin/env bash

set -eu -o pipefail

repo="${1-}"
if [[ -z "$repo" ]]; then
	>&2 echo "Usage: $0 <YOUR SITE REPO>"
	exit 1
fi

BASE_PATH="$(pwd)"
REPO_PATH="$(cd "$repo" && pwd)"
: ${NETLIFY_IMAGE="netlify/build:xenial"}

exec docker run --rm -t -i \
	-e NODE_VERSION \
	-e NPM_VERSION \
	-e RUBY_VERSION \
	-e YARN_VERSION \
	-e HUGO_VERSION \
	-e PHP_VERSION \
	-e GO_VERSION \
	-e SWIFT_VERSION \
	-e PYTHON_VERSION \
	-v "${REPO_PATH}":/opt/repo \
	-v "${BASE_PATH}"/run-build.sh:/opt/build-bin/build \
	-v "${BASE_PATH}"/run-build-functions.sh:/opt/build-bin/run-build-functions.sh \
	"$NETLIFY_IMAGE" /bin/bash
